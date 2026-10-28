import Foundation

// Модели ответов Laravel/Lunar API. Ключи в snake_case — JSONDecoder переводит их в camelCase.
// Почти всё опционально: API отдаёт много полей, а нам нужна их малая часть.

/// Поле вида {"ru": "...", "en": ""}
struct Localized: Decodable, Hashable {
    let ru: String?

    var text: String { ru ?? "" }
}

/// Число, которое API присылает то числом, то строкой ("126", "10.5")
struct FlexibleNumber: Decodable, Hashable {
    let value: Double

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()

        if let d = try? c.decode(Double.self) {
            value = d
        } else if let s = try? c.decode(String.self), let d = Double(s.replacingOccurrences(of: ",", with: ".")) {
            value = d
        } else if let b = try? c.decode(Bool.self) {
            value = b ? 1 : 0
        } else {
            value = 0
        }
    }
}

struct Slug: Decodable, Hashable {
    let slug: String
}

// MARK: - Разделы

struct Section: Decodable, Identifiable, Hashable {
    let id: Int
    let attributeData: Attributes
    let url: Slug?
    let image: String?

    struct Attributes: Decodable, Hashable {
        let name: Localized?
    }

    var name: String { attributeData.name?.text ?? "" }
    var slug: String { url?.slug ?? "" }
    var imageURL: URL? { image.flatMap(URL.init(string:)) }
}

// MARK: - Акции

struct Promotion: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let slug: String?
    let description: String?
    let desktopImage: String?
    let mobileImage: String?

    /// Скидка товара (`promotion_info.promotions[]`, `discounts[]`)
    struct Discount: Decodable, Hashable {
        let id: Int?
        let name: String?
        let type: String?
        let percentage: Double?
        let fixedValue: Bool?
        let data: DiscountData?

        enum CodingKeys: String, CodingKey { case id, name, type, percentage, fixedValue, data }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try? c.decode(Int.self, forKey: .id)
            name = try? c.decode(String.self, forKey: .name)
            type = try? c.decode(String.self, forKey: .type)
            percentage = (try? c.decode(FlexibleNumber.self, forKey: .percentage))?.value
            fixedValue = try? c.decode(Bool.self, forKey: .fixedValue)
            data = try? c.decode(DiscountData.self, forKey: .data)
        }
    }

    struct DiscountData: Decodable, Hashable {
        let percentage: Double?
        let fixedValue: Bool?

        enum CodingKeys: String, CodingKey { case percentage, fixedValue }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            percentage = (try? c.decode(FlexibleNumber.self, forKey: .percentage))?.value
            fixedValue = try? c.decode(Bool.self, forKey: .fixedValue)
        }
    }

    var imageURL: URL? { (mobileImage ?? desktopImage).flatMap(URL.init(string:)) }
}

struct StatusResponse<T: Decodable>: Decodable {
    let status: String?
    let data: T?
}

// MARK: - Товар

struct Product: Decodable, Identifiable, Hashable {
    let id: Int
    let attributeData: Attributes?
    let media: [Media]?
    let mediaSrc: [MediaSource]?
    let prices: [PriceEntry]?
    let defaultUrl: Slug?
    let promotionInfo: PromotionInfo?
    let inStock: Bool?
    let lowStock: Bool?

    // Только в карточке товара (products/get/{slug})
    let variants: [Variant]?
    let discounts: [Promotion.Discount]?
    let chars: [Characteristic]?

    struct Attributes: Decodable, Hashable {
        let name: Localized?
        let description: Localized?
    }

    struct PromotionInfo: Decodable, Hashable {
        let hasPromotions: Bool?
        let promotions: [Promotion.Discount]?
    }

    enum CodingKeys: String, CodingKey {
        case id, attributeData, media, mediaSrc, prices, defaultUrl, promotionInfo
        case inStock, lowStock, variants, discounts, chars
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        attributeData = try? c.decode(Attributes.self, forKey: .attributeData)
        media = try? c.decode([Media].self, forKey: .media)
        mediaSrc = try? c.decode([MediaSource].self, forKey: .mediaSrc)
        prices = try? c.decode([PriceEntry].self, forKey: .prices)
        defaultUrl = try? c.decode(Slug.self, forKey: .defaultUrl)
        promotionInfo = try? c.decode(PromotionInfo.self, forKey: .promotionInfo)
        inStock = try? c.decode(Bool.self, forKey: .inStock)
        lowStock = try? c.decode(Bool.self, forKey: .lowStock)
        variants = try? c.decode([Variant].self, forKey: .variants)
        discounts = try? c.decode([Promotion.Discount].self, forKey: .discounts)
        chars = (try? c.decode(Characteristics.self, forKey: .chars))?.items
    }

    var name: String {
        let n = attributeData?.name?.text ?? ""
        return n.isEmpty ? "Без названия" : n
    }

    var slug: String { defaultUrl?.slug ?? "" }

    /// Базовая цена (до скидки) — первая цена из списка, как на сайте
    var basePrice: Double { prices?.first?.price?.value ?? 0 }

    /// Скидка в карточке списка — из promotion_info, на странице товара — из discounts
    var discountPercent: Int {
        Discount.percent(discounts ?? promotionInfo?.promotions)
    }

    var price: Double { Discount.apply(basePrice, percent: discountPercent) }

    /// Фото для сетки (маленькие)
    var thumbnailURLs: [URL] {
        (media ?? []).compactMap { URL(string: $0.smallUrl ?? $0.originalUrl ?? "") }
    }

    /// Фото для страницы товара (крупные)
    var galleryURLs: [URL] {
        if let src = mediaSrc, !src.isEmpty {
            return src.filter { $0.type == nil || $0.type == "image" }
                .compactMap { URL(string: $0.large ?? $0.medium ?? $0.original ?? "") }
        }
        return (media ?? []).compactMap { URL(string: $0.originalUrl ?? "") }
    }
}

struct Media: Decodable, Hashable {
    let id: Int?
    let originalUrl: String?
    let smallUrl: String?
}

struct MediaSource: Decodable, Hashable {
    let type: String?
    let original: String?
    let large: String?
    let medium: String?
    let small: String?
}

struct PriceEntry: Decodable, Hashable {
    let price: Money?

    enum CodingKeys: String, CodingKey { case price }

    struct Money: Decodable, Hashable {
        let value: Double

        enum CodingKeys: String, CodingKey { case value }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            value = (try? c.decode(FlexibleNumber.self, forKey: .value))?.value ?? 0
        }
    }
}

struct Variant: Decodable, Identifiable, Hashable {
    let id: Int
    let sku: String?
    let stock: Int
    let values: [OptionValue]?
    let prices: [PriceEntry]?
    let images: [Media]?

    struct OptionValue: Decodable, Hashable {
        let id: Int
        let name: Localized?
        let position: Int?
        let option: Option?
    }

    struct Option: Decodable, Hashable {
        let id: Int?
        let handle: String?
        let name: Localized?
        let label: Localized?
    }

    enum CodingKeys: String, CodingKey { case id, sku, stock, values, prices, images }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        sku = try? c.decode(String.self, forKey: .sku)
        stock = Int((try? c.decode(FlexibleNumber.self, forKey: .stock))?.value ?? 0)
        values = try? c.decode([OptionValue].self, forKey: .values)
        prices = try? c.decode([PriceEntry].self, forKey: .prices)
        images = try? c.decode([Media].self, forKey: .images)
    }

    var price: Double? { prices?.first?.price?.value }
}

/// Характеристики товара: {"Пол": "Унисекс", ...} → [(название, значение)]
struct Characteristic: Hashable {
    let name: String
    let value: String
}

private struct Characteristics: Decodable {
    let items: [Characteristic]

    private struct Key: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        // Порядок ключей JSON-объекта декодер не сохраняет — сортируем, чтобы он был стабильным
        items = c.allKeys.compactMap { key in
            if let s = try? c.decode(String.self, forKey: key), !s.isEmpty {
                return Characteristic(name: key.stringValue, value: s)
            }
            if let n = try? c.decode(FlexibleNumber.self, forKey: key) {
                return Characteristic(name: key.stringValue, value: Format.number(n.value))
            }
            return nil
        }
        .sorted { $0.name < $1.name }
    }
}

// MARK: - Каталог

struct Paginated<T: Decodable>: Decodable {
    let currentPage: Int
    let lastPage: Int
    let total: Int?
    let data: [T]
}

struct CatalogResponse: Decodable {
    let products: Paginated<Product>
    let facets: [Facet]?
    let price: PriceBounds?
}

struct HomeProductsResponse: Decodable {
    let products: [Product]
}

struct Facet: Decodable, Hashable {
    let field: String
    let label: String
    let type: String
    let values: [Value]

    struct Value: Decodable, Hashable {
        let value: String
        let label: String
        let count: Int?
        let active: Bool?
        let hex: String?

        enum CodingKeys: String, CodingKey { case value, label, count, active, hex }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            // value бывает и числом, и строкой
            if let s = try? c.decode(String.self, forKey: .value) {
                value = s
            } else {
                value = Format.number((try? c.decode(FlexibleNumber.self, forKey: .value))?.value ?? 0)
            }
            label = (try? c.decode(String.self, forKey: .label)) ?? value
            count = try? c.decode(Int.self, forKey: .count)
            active = try? c.decode(Bool.self, forKey: .active)
            hex = try? c.decode(String.self, forKey: .hex)
        }
    }
}

struct PriceBounds: Decodable, Hashable {
    let min: Double
    let max: Double
}

// MARK: - Корзина

struct CartQuantityResponse: Decodable {
    let totalQuantity: FlexibleNumber?
}
