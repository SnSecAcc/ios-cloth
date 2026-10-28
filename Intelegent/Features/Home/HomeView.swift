import SwiftUI

/// Главная: баннер, преимущества, акция, разделы («Коллекция»), новинки.
struct HomeView: View {
    @Environment(AppState.self) private var state
    @State private var promotion: Promotion?
    @State private var products: [Product] = []
    @State private var loadingProducts = true
    @State private var cartSlug: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HeroBanner()

                FeaturesStrip()

                if let promotion {
                    PromotionCard(promotion: promotion)
                        .padding(.horizontal, 8)
                        .padding(.top, 40)
                }

                VStack(spacing: 0) {
                    SectionTitle(title: "Коллекция", eyebrow: "INTELEGENTOFF")
                    SectionTiles(sections: state.sections)
                }
                .padding(.horizontal, 8)
                .padding(.top, 48)

                VStack(spacing: 0) {
                    SectionTitle(title: "Новинки")
                    ProductGrid(products: products, loading: loadingProducts) { cartSlug = $0.slug }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 48)
            }
        }
        .background(Palette.canvas.ignoresSafeArea())
        .appHeader()
        .addToCartSheet(slug: $cartSlug)
        .refreshable { await load() }
        .task { await load() }
    }

    private func load() async {
        async let promo = try? ShopAPI.activePromotion()
        async let items = try? ShopAPI.homeProducts(limit: 10)
        async let sections: () = state.loadSections()

        promotion = await promo
        products = await items ?? []
        loadingProducts = false
        _ = await sections
    }
}

// MARK: - Баннер

private struct HeroBanner: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .leading) {
            if let image = BundleImage.load(colorScheme == .dark ? "hero_dark" : "hero_light") {
                // Как object-position на сайте: 78% / 62% по горизонтали
                FocusedImage(image: image, focusX: colorScheme == .dark ? 0.78 : 0.62)
            }

            LinearGradient(colors: [Palette.canvas, Palette.canvas.opacity(0.7), .clear], startPoint: .leading, endPoint: .trailing)
            LinearGradient(colors: [Palette.canvas.opacity(0.4), .clear], startPoint: .bottom, endPoint: .center)

            if colorScheme == .light {
                Palette.canvas.opacity(0.3)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("INTELEGENTOFF")
                    .appFont(42, .bold)
                    .tracking(-0.055 * 42)
                    .foregroundStyle(Palette.fg)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text("СТИЛЬ. КАЧЕСТВО. УВЕРЕННОСТЬ.")
                    .appFont(17, .semibold)
                    .tracking(0.025 * 17)
                    .foregroundStyle(colorScheme == .dark ? Palette.gold : Palette.goldDark)
                    .padding(.top, 24)

                Text("Премиальная одежда для тех, кто ценит детали и выбирает лучшее.")
                    .appFont(14)
                    .lineSpacing(6)
                    .foregroundStyle(Palette.muted)
                    .frame(maxWidth: 300, alignment: .leading)
                    .padding(.top, 16)

                CatalogLinkButton()
                    .padding(.top, 40)
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 440)
        .clipped()
    }
}

/// «Смотреть коллекцию» — переключает на вкладку каталога
private struct CatalogLinkButton: View {
    var body: some View {
        NavigationLink {
            CatalogView()
        } label: {
            HStack {
                Text("Смотреть коллекцию")
                Spacer()
                Image(systemName: "arrow.right").font(.system(size: 14))
            }
            .frame(width: 212)
        }
        .buttonStyle(.app(.secondary))
    }
}

/// Картинка «cover» с точкой фокуса по горизонтали (object-position: X% center)
private struct FocusedImage: View {
    let image: UIImage
    let focusX: CGFloat

    var body: some View {
        GeometryReader { geo in
            let aspect = image.size.width / max(image.size.height, 1)
            let scale = max(geo.size.width / max(aspect * geo.size.height, 1), 1)
            let height = geo.size.height * scale
            let width = height * aspect
            let overflow = max(width - geo.size.width, 0)

            Image(uiImage: image)
                .resizable()
                .frame(width: width, height: height)
                .offset(x: -overflow * focusX, y: -(height - geo.size.height) / 2)
        }
        .clipped()
    }
}

enum BundleImage {
    /// Картинки из Resources/Images. WebP iOS открывает сам.
    static func load(_ name: String) -> UIImage? {
        guard let path = Bundle.main.path(forResource: name, ofType: "webp") else { return nil }
        return UIImage(contentsOfFile: path)
    }
}

// MARK: - Преимущества

private struct FeaturesStrip: View {
    private let features: [(icon: String, title: String, text: String)] = [
        ("shippingbox", "Ткани напрямую", "из Турции под заказ"),
        ("star", "Премиальные", "материалы"),
        ("doc.text", "Пошив в России", "по международным технологиям"),
        ("truck.box", "Быстрая", "доставка по всей России"),
        ("checkmark.seal", "Качество", "на которое можно положиться"),
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    HStack(spacing: 12) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(Palette.fg.opacity(0.6))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.title)
                                .appFont(11, .medium)
                                .caps(0.025, size: 11)
                                .foregroundStyle(Palette.fg.opacity(0.9))
                            Text(feature.text)
                                .appFont(10)
                                .textCase(.uppercase)
                                .foregroundStyle(Palette.subtle)
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .overlay(alignment: .trailing) {
                        if index < features.count - 1 {
                            Rectangle().fill(Palette.line).frame(width: 1)
                        }
                    }
                }
            }
        }
        .background(Palette.surface)
        .overlay(alignment: .top) { Rectangle().fill(Palette.line).frame(height: 1) }
        .overlay(alignment: .bottom) { Rectangle().fill(Palette.line).frame(height: 1) }
    }
}

// MARK: - Акция

private struct PromotionCard: View {
    let promotion: Promotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RemoteImage(url: promotion.imageURL)
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipped()

            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: "Специальное предложение")

                Text(promotion.name)
                    .appFont(16, .bold)
                    .textCase(.uppercase)
                    .foregroundStyle(Palette.fg)

                if let description = promotion.description, !description.isEmpty {
                    Text(description)
                        .appFont(12)
                        .lineSpacing(4)
                        .foregroundStyle(Palette.muted)
                }

                HStack(spacing: 8) {
                    Text("Подробнее об акции")
                        .appFont(10, .medium)
                        .caps(0.16, size: 10)
                    Image(systemName: "arrow.right").font(.system(size: 11))
                }
                .foregroundStyle(Palette.gold)
                .padding(.top, 8)
            }
            .padding(16)
        }
        .background(Palette.surface)
        .overlay(RoundedRectangle(cornerRadius: Palette.radius).stroke(Palette.accent.opacity(0.3)))
        .clipShape(RoundedRectangle(cornerRadius: Palette.radius))
    }
}

// MARK: - Плитки разделов

struct SectionTiles: View {
    let sections: [Section]

    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            if sections.isEmpty {
                ForEach(0..<4, id: \.self) { _ in Skeleton().frame(height: 150) }
            } else {
                ForEach(sections) { section in
                    NavigationLink(value: Route.section(section)) {
                        SectionTile(section: section)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct SectionTile: View {
    let section: Section

    var body: some View {
        Color.clear
            .frame(height: 150)
            .overlay { RemoteImage(url: section.imageURL) }
            .overlay {
                if section.imageURL != nil {
                    LinearGradient(colors: [.black.opacity(0.45), .clear], startPoint: .bottom, endPoint: .center)
                }
            }
            .overlay(alignment: .bottomLeading) {
                Text(section.name)
                    .appFont(16, .medium)
                    .caps(0.02, size: 16)
                    .foregroundStyle(section.imageURL != nil ? Color.white : Palette.fg)
                    .padding(16)
            }
            .clipShape(RoundedRectangle(cornerRadius: Palette.radius))
            .overlay(RoundedRectangle(cornerRadius: Palette.radius).stroke(Palette.line))
    }
}

// MARK: - Лист «В корзину»

private struct SlugItem: Identifiable {
    let id: String
}

extension View {
    /// Лист выбора варианта, открывается, когда slug не nil
    func addToCartSheet(slug: Binding<String?>) -> some View {
        sheet(item: Binding(
            get: { slug.wrappedValue.map(SlugItem.init(id:)) },
            set: { slug.wrappedValue = $0?.id }
        )) { item in
            AddToCartSheet(slug: item.id)
        }
    }
}
