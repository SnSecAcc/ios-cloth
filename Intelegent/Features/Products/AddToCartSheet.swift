import SwiftUI

/// «В корзину» из сетки: подгружаем товар и даём выбрать вариант (ModalsAddToCartListing).
struct AddToCartSheet: View {
    let slug: String

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var product: Product?
    @State private var selection = VariantSelection(variants: [])
    @State private var adding = false
    @State private var failed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let product {
                HStack(alignment: .top, spacing: 12) {
                    RemoteImage(url: product.thumbnailURLs.first ?? product.galleryURLs.first)
                        .frame(width: 72, height: 96)
                        .clipped()

                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.name)
                            .appFont(13, .medium)
                            .textCase(.uppercase)
                            .foregroundStyle(Palette.fg)
                            .lineLimit(2)

                        let base = selection.selectedVariant?.price ?? product.basePrice
                        PriceView(
                            value: Discount.apply(base, percent: product.discountPercent),
                            oldValue: product.discountPercent > 0 ? base : nil,
                            size: .md
                        )
                    }
                }

                VariantPicker(selection: $selection)

                let available = (selection.selectedVariant?.stock ?? 0) > 0

                Button(available ? "В корзину" : "Нет в наличии") {
                    guard let variant = selection.selectedVariant else { return }
                    adding = true
                    Task {
                        let ok = await state.addToCart(product: product, variant: variant)
                        adding = false
                        if ok { dismiss() } else { failed = true }
                    }
                }
                .buttonStyle(.app(available ? .primary : .muted, size: .lg, block: true))
                .disabled(!available || adding)

                if failed {
                    Text("Не удалось добавить товар. Попробуйте ещё раз.")
                        .appFont(12)
                        .foregroundStyle(Palette.danger)
                }
            } else if failed {
                EmptyStateView(systemImage: "exclamationmark.triangle", title: "Не удалось загрузить товар")
            } else {
                ProgressView().frame(maxWidth: .infinity, minHeight: 200)
            }
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Palette.surface.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task {
            do {
                let loaded = try await ShopAPI.product(slug: slug)
                product = loaded
                selection = VariantSelection(variants: loaded.variants ?? [])
            } catch {
                failed = true
            }
        }
    }
}

/// Плашка «Товар добавлен в корзину» над таб-баром (ModalsAddedToCart)
struct AddedToCartToast: View {
    @Environment(AppState.self) private var state

    var body: some View {
        if let item = state.addedToCart {
            HStack(spacing: 12) {
                RemoteImage(url: item.imageURL)
                    .frame(width: 44, height: 58)
                    .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Товар добавлен в корзину")
                        .appFont(10, .medium)
                        .caps(0.16, size: 10)
                        .foregroundStyle(Palette.gold)

                    Text(item.name)
                        .appFont(12, .medium)
                        .foregroundStyle(Palette.fg)
                        .lineLimit(1)

                    if !item.options.isEmpty {
                        Text(item.options)
                            .appFont(11)
                            .foregroundStyle(Palette.subtle)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                Text(Format.price(item.price))
                    .appFont(13, .semibold)
                    .foregroundStyle(Palette.fg)
            }
            .padding(12)
            .background(Palette.surface)
            .overlay(RoundedRectangle(cornerRadius: Palette.radius).stroke(Palette.accent.opacity(0.4)))
            .clipShape(RoundedRectangle(cornerRadius: Palette.radius))
            .shadow(color: .black.opacity(0.25), radius: 16, y: 6)
            .padding(.horizontal, 12)
            .padding(.bottom, 60)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .id(item.id)
            .task(id: item.id) {
                try? await Task.sleep(for: .seconds(3))
                withAnimation { state.addedToCart = nil }
            }
            .onTapGesture { withAnimation { state.addedToCart = nil } }
        }
    }
}
