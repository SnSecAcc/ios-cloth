import SwiftUI

/// Выбор варианта по опциям (размер, цвет…) — useVariantSelection.ts сайта.
struct VariantSelection {
    struct OptionGroup: Identifiable {
        let handle: String
        let name: String
        let values: [Value]

        var id: String { handle }
    }

    struct Value: Identifiable, Hashable {
        let id: Int
        let name: String
        let position: Int
    }

    let variants: [Variant]
    private(set) var selected: [String: Value] = [:]
    private(set) var selectedVariant: Variant?

    init(variants: [Variant]) {
        self.variants = variants
        // Сразу выбираем первый вариант в наличии
        select(variant: variants.first { $0.stock > 0 } ?? variants.first)
    }

    var groups: [OptionGroup] {
        var order: [String] = []
        var names: [String: String] = [:]
        var values: [String: [Int: Value]] = [:]

        for variant in variants {
            for value in variant.values ?? [] {
                guard let handle = value.option?.handle else { continue }

                if names[handle] == nil {
                    order.append(handle)
                    names[handle] = value.option?.name?.ru ?? handle
                }

                values[handle, default: [:]][value.id] = Self.value(value)
            }
        }

        return order.map { handle in
            OptionGroup(
                handle: handle,
                name: names[handle] ?? handle,
                values: (values[handle] ?? [:]).values.sorted { ($0.position, $0.id) < ($1.position, $1.id) }
            )
        }
    }

    /// Есть ли в наличии вариант с этим значением при остальных уже выбранных опциях
    func isAvailable(_ value: Value, in handle: String) -> Bool {
        var wanted = selected
        wanted[handle] = value
        let ids = Set(wanted.values.map(\.id))

        return variants.contains { variant in
            variant.stock > 0 && ids.isSubset(of: Set((variant.values ?? []).map(\.id)))
        }
    }

    mutating func choose(_ value: Value, in handle: String) {
        var wanted = selected
        wanted[handle] = value
        let ids = Set(wanted.values.map(\.id))

        let matching = variants.filter { ids.isSubset(of: Set(($0.values ?? []).map(\.id))) }

        // Полное совпадение → берём его; иначе — первый подходящий по новому значению (в наличии — приоритетнее)
        let fallback = variants.filter { ($0.values ?? []).contains { $0.id == value.id } }
        let next = matching.first { $0.stock > 0 } ?? matching.first ?? fallback.first { $0.stock > 0 } ?? fallback.first

        select(variant: next)
    }

    private mutating func select(variant: Variant?) {
        selectedVariant = variant
        selected = [:]

        for value in variant?.values ?? [] {
            if let handle = value.option?.handle {
                selected[handle] = Self.value(value)
            }
        }
    }

    private static func value(_ value: Variant.OptionValue) -> Value {
        Value(id: value.id, name: value.name?.ru ?? String(value.id), position: value.position ?? 0)
    }
}

/// Кнопки выбора опций (ProductsVariantPicker)
struct VariantPicker: View {
    @Binding var selection: VariantSelection

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(selection.groups) { group in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Text(group.name)
                            .appFont(11, .medium)
                            .caps(0.08, size: 11)
                            .foregroundStyle(Palette.muted)

                        if let current = selection.selected[group.handle] {
                            Text(current.name)
                                .appFont(11, .semibold)
                                .foregroundStyle(Palette.fg)
                        }
                    }

                    FlowLayout(spacing: 8) {
                        ForEach(group.values) { value in
                            optionButton(value, group: group)
                        }
                    }
                }
            }
        }
    }

    private func optionButton(_ value: VariantSelection.Value, group: VariantSelection.OptionGroup) -> some View {
        let isSelected = selection.selected[group.handle]?.id == value.id
        let available = selection.isAvailable(value, in: group.handle)

        return Button {
            selection.choose(value, in: group.handle)
        } label: {
            Text(value.name)
                .appFont(13, .medium)
                .strikethrough(!available)
                .foregroundStyle(isSelected ? Palette.fg : (available ? Palette.fg.opacity(0.85) : Palette.faint))
                .padding(.horizontal, 14)
                .frame(minWidth: 48, minHeight: 40)
                .background(isSelected ? Palette.accent.opacity(0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: Palette.radius)
                        .stroke(isSelected ? Palette.accent : Palette.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

/// Простая раскладка «в строку с переносом» для кнопок опций
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, width: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)

            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            width = max(width, x - spacing)
        }

        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)

            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }

            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
