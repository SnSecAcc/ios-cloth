import SwiftUI

/// Страница товара: галерея, цена, выбор варианта, «В корзину», описание, характеристики.
struct ProductDetailView: View {
    let slug: String

    @Environment(AppState.self) private var state
    @State private var product: Product?
    @State private var selection = VariantSelection(variants: [])
    @State private var error: String?
    @State private var adding = false
    @State private var photoIndex = 0

    var body: some View {
        Group {
            if let product {
                content(product)
            } else if let error {
                EmptyStateView(systemImage: "exclamationmark.triangle", title: "Не удалось загрузить товар", text: error)
                    .frame(maxHeight: .infinity)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .screen()
        .task(id: slug) { await load() }
    }

    private func load() async {
        do {
            let loaded = try await ShopAPI.product(slug: slug)
            product = loaded
            selection = VariantSelection(variants: loaded.variants ?? [])
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func content(_ product: Product) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                gallery(product)

                VStack(alignment: .leading, spacing: 24) {
                    header(product)

                    if !selection.groups.isEmpty {
                        VariantPicker(selection: $selection)
                    }

                    addButton(product)

                    if let description = product.attributeData?.description?.text, !description.isEmpty {
                        DetailBlock(title: "Описание") {
                            Text(HTMLText.plain(description))
                                .appFont(14)
                                .lineSpacing(6)
                                .foregroundStyle(Palette.muted)
                        }
                    }

                    if let chars = product.chars, !chars.isEmpty {
                        DetailBlock(title: "Характеристики") {
                            VStack(spacing: 0) {
                                ForEach(chars, id: \.name) { item in
                                    HStack(alignment: .top) {
                                        Text(item.name).foregroundStyle(Palette.subtle)
                                        Spacer(minLength: 16)
                                        Text(item.value).foregroundStyle(Palette.fg).multilineTextAlignment(.trailing)
                                    }
                                    .appFont(13)
                                    .padding(.vertical, 10)
                                    .overlay(alignment: .bottom) { Rectangle().fill(Palette.line).frame(height: 1) }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
    }

    private func gallery(_ product: Product) -> some View {
        let urls = product.galleryURLs

        return TabView(selection: $photoIndex) {
            if urls.isEmpty {
                ImagePlaceholder().tag(0)
            }
            ForEach(urls.indices, id: \.self) { index in
                RemoteImage(url: urls[index]).tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .aspectRatio(3 / 4, contentMode: .fit)
        .background(Palette.surfaceRaised)
        .overlay(alignment: .bottom) {
            if urls.count > 1 {
                HStack(spacing: 4) {
                    ForEach(urls.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == photoIndex ? Color.white : Color.white.opacity(0.4))
                            .frame(width: index == photoIndex ? 20 : 8, height: 4)
                    }
                }
                .animation(.easeOut(duration: 0.2), value: photoIndex)
                .padding(.bottom, 12)
            }
        }
    }

    private func header(_ product: Product) -> some View {
        let base = selection.selectedVariant?.price ?? product.basePrice
        let percent = product.discountPercent
        let price = Discount.apply(base, percent: percent)

        return VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "INTELEGENTOFF")

            Text(product.name)
                .appFont(22, .bold)
                .textCase(.uppercase)
                .foregroundStyle(Palette.fg)

            PriceView(value: price, oldValue: percent > 0 ? base : nil, discount: percent, size: .xl)

            if let variant = selection.selectedVariant {
                if variant.stock <= 0 {
                    AppBadge(text: "Нет в наличии", tone: .danger, small: true)
                } else if variant.stock <= 3 {
                    AppBadge(text: "Осталось мало", tone: .warning, small: true)
                }
            }
        }
    }

    private func addButton(_ product: Product) -> some View {
        let variant = selection.selectedVariant
        let available = (variant?.stock ?? 0) > 0

        return Button {
            guard let variant else { return }
            adding = true
            Task {
                await state.addToCart(product: product, variant: variant)
                adding = false
            }
        } label: {
            HStack(spacing: 8) {
                if adding { ProgressView().tint(Palette.onAccent) }
                Text(available ? "В корзину" : "Нет в наличии")
            }
        }
        .buttonStyle(.app(available ? .primary : .muted, size: .lg, block: true))
        .disabled(!available || adding)
    }
}

private struct DetailBlock<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .appFont(11, .medium)
                .caps(0.16, size: 11)
                .foregroundStyle(Palette.gold)

            content
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { Rectangle().fill(Palette.line).frame(height: 1) }
    }
}

/// Описание товара приходит HTML-ом: <p>, <br>. Превращаем в обычный текст с абзацами.
enum HTMLText {
    static func plain(_ html: String) -> String {
        var text = html
            .replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "</p>", with: "\n\n", options: .caseInsensitive)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        let entities = ["&nbsp;": " ", "&amp;": "&", "&quot;": "\"", "&#39;": "'", "&lt;": "<", "&gt;": ">", "&laquo;": "«", "&raquo;": "»", "&mdash;": "—", "&ndash;": "–"]
        for (entity, value) in entities {
            text = text.replacingOccurrences(of: entity, with: value)
        }

        return text
            .replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
