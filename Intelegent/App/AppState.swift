import SwiftUI

/// Тема: как на сайте — по умолчанию системная, переключатель запоминает выбор.
enum ThemeChoice: String {
    case system, dark, light

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .dark: .dark
        case .light: .light
        }
    }
}

/// Маршруты внутри вкладок
enum Route: Hashable {
    case section(Section)
    case product(slug: String)
    case search(String)
}

/// Общее состояние приложения: корзина (счётчик + добавление), разделы, уведомления.
@MainActor
@Observable
final class AppState {
    var cartQuantity = 0
    var sections: [Section] = []

    /// Последний добавленный товар — показываем плашку «Товар добавлен в корзину»
    var addedToCart: AddedItem?

    struct AddedItem: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let options: String
        let price: Double
        let imageURL: URL?
    }

    func bootstrap() async {
        async let sectionsTask: () = loadSections()
        async let cartTask: () = syncCart()
        _ = await (sectionsTask, cartTask)
    }

    func loadSections() async {
        guard sections.isEmpty else { return }
        sections = (try? await ShopAPI.sections()) ?? []
    }

    func syncCart() async {
        cartQuantity = (try? await ShopAPI.cartQuantity()) ?? 0
    }

    /// Добавить вариант в корзину. Счётчик растёт сразу, как на сайте; при ошибке откатываем.
    @discardableResult
    func addToCart(product: Product, variant: Variant) async -> Bool {
        cartQuantity += 1

        do {
            try await ShopAPI.addToCart(variantId: variant.id)

            let options = (variant.values ?? [])
                .map { value in
                    let optionName = value.option?.label?.ru ?? value.option?.name?.ru ?? value.option?.handle ?? ""
                    return "\(optionName): \(value.name?.text ?? "")"
                }
                .joined(separator: ", ")

            let image = variant.images?.first?.originalUrl.flatMap(URL.init(string:))
                ?? product.galleryURLs.first
                ?? product.thumbnailURLs.first

            addedToCart = AddedItem(
                name: product.name,
                options: options,
                price: Discount.apply(variant.price ?? product.basePrice, percent: product.discountPercent),
                imageURL: image
            )

            return true
        } catch {
            cartQuantity = max(0, cartQuantity - 1)
            return false
        }
    }
}
