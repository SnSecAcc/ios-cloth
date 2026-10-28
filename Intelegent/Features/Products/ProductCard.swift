import SwiftUI

/// Карточка товара в сетке (ProductsSectionCard): фото со свайпом, бейджи, цена, «В корзину».
struct ProductCard: View {
    let product: Product
    var onAddToCart: () -> Void

    @State private var imageIndex = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink(value: Route.product(slug: product.slug)) {
                VStack(alignment: .leading, spacing: 0) {
                    photos

                    Text(product.name)
                        .appFont(12, .medium)
                        .textCase(.uppercase)
                        .foregroundStyle(Palette.fg.opacity(0.9))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(minHeight: 32, alignment: .topLeading)
                        .padding(.top, 20)
                        .padding(.bottom, 12)

                    PriceView(
                        value: product.price,
                        oldValue: product.discountPercent > 0 ? product.basePrice : nil,
                        size: .lg
                    )
                }
            }
            .buttonStyle(.plain)

            Group {
                if product.inStock ?? true {
                    Button("В корзину", action: onAddToCart)
                        .buttonStyle(.app(.primary, size: .sm, block: true))
                } else {
                    Button("Нет в наличии") {}
                        .buttonStyle(.app(.muted, size: .sm, block: true))
                        .disabled(true)
                }
            }
            .padding(.top, 16)
        }
        .padding(.bottom, 8)
    }

    private var photos: some View {
        let urls = product.thumbnailURLs

        return Color.clear
            .aspectRatio(3 / 4, contentMode: .fit)
            .overlay {
                if urls.count > 1 {
                    TabView(selection: $imageIndex) {
                        ForEach(urls.indices, id: \.self) { index in
                            RemoteImage(url: urls[index]).tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                } else {
                    RemoteImage(url: urls.first)
                }
            }
            .background(Palette.surfaceRaised)
            .clipped()
            .overlay(alignment: .topLeading) { badges }
            .overlay(alignment: .bottom) {
                if urls.count > 1 {
                    HStack(spacing: 4) {
                        ForEach(urls.indices, id: \.self) { index in
                            Capsule()
                                .fill(index == imageIndex ? Color.white : Color.white.opacity(0.4))
                                .frame(width: index == imageIndex ? 20 : 8, height: 4)
                        }
                    }
                    .animation(.easeOut(duration: 0.2), value: imageIndex)
                    .padding(.bottom, 8)
                }
            }
    }

    @ViewBuilder
    private var badges: some View {
        let promotions = product.promotionInfo?.promotions ?? []
        let lowStock = (product.inStock ?? false) && (product.lowStock ?? false)

        if !promotions.isEmpty || lowStock {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(promotions.enumerated()), id: \.offset) { _, promotion in
                    AppBadge(text: promotion.name ?? "Акция", overlay: true)
                }

                if lowStock {
                    AppBadge(text: "Осталось мало", overlay: true)
                }
            }
            .padding(8)
        }
    }
}

/// Сетка карточек со скелетоном и пустым состоянием (ProductsGrid)
struct ProductGrid: View {
    let products: [Product]
    var loading = false
    var emptyText = "Товары не найдены"
    var onAddToCart: (Product) -> Void

    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        if loading && products.isEmpty {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<4, id: \.self) { _ in SkeletonCard() }
            }
        } else if products.isEmpty {
            EmptyStateView(systemImage: "magnifyingglass", title: emptyText)
        } else {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(products) { product in
                    ProductCard(product: product) { onAddToCart(product) }
                }
            }
        }
    }
}

struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Skeleton().aspectRatio(3 / 4, contentMode: .fit)
            Skeleton().frame(height: 12)
            Skeleton().frame(width: 90, height: 18)
            Skeleton().frame(height: 36)
        }
    }
}
