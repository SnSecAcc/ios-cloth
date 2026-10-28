import Foundation

/// Запросы магазина — те же эндпоинты, что вызывает сайт.
enum ShopAPI {
    private static var api: APIClient { .shared }

    static func sections() async throws -> [Section] {
        try await api.get("sections/list")
    }

    static func activePromotion() async throws -> Promotion? {
        let response: StatusResponse<Promotion> = try await api.get("promotions/get/active")
        return response.status == "success" ? response.data : nil
    }

    static func homeProducts(limit: Int = 10) async throws -> [Product] {
        let response: HomeProductsResponse = try await api.get("products/home", query: [URLQueryItem(name: "limit", value: String(limit))])
        return response.products
    }

    static func collection(slug: String, page: Int, sort: CatalogSort?) async throws -> CatalogResponse {
        var query = [URLQueryItem(name: "page", value: String(page))]

        if let sort {
            query.append(URLQueryItem(name: "sort", value: sort.rawValue))
        }

        return try await api.get("collections/\(slug)/products", query: query)
    }

    static func search(_ text: String, page: Int, sort: CatalogSort?) async throws -> CatalogResponse {
        var query = [
            URLQueryItem(name: "query", value: text),
            URLQueryItem(name: "page", value: String(page)),
        ]

        if let sort {
            query.append(URLQueryItem(name: "sort", value: sort.rawValue))
        }

        return try await api.get("products/get", query: query)
    }

    static func product(slug: String) async throws -> Product {
        try await api.get("products/get/\(slug)")
    }

    static func cartQuantity() async throws -> Int {
        let response: CartQuantityResponse = try await api.get("cart/quantity")
        return Int(response.totalQuantity?.value ?? 0)
    }

    static func addToCart(variantId: Int, quantity: Int = 1) async throws {
        let _: EmptyResponse = try await api.post("cart/add", body: ["variant_id": variantId, "quantity": quantity])
    }
}

/// Сортировка каталога (CATALOG_SORT_OPTIONS сайта)
enum CatalogSort: String, CaseIterable, Identifiable {
    case createdAtDesc = "created_at_desc"
    case createdAtAsc = "created_at_asc"
    case priceAsc = "price_asc"
    case priceDesc = "price_desc"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .createdAtDesc: "Сначала новые"
        case .createdAtAsc: "Сначала старые"
        case .priceAsc: "Цена (сначала дешевые)"
        case .priceDesc: "Цена (сначала дорогие)"
        }
    }

    static let popularTitle = "По популярности"
}
