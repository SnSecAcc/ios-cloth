import Foundation

/// Форматтеры — повторяют app/utils/format.ts сайта.
enum Format {
    private static let priceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }()

    /// 12500 → «12 500 ₽», 99.5 → «99,5 ₽»
    static func price(_ value: Double) -> String {
        let number = priceFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
        // Неразрывные пробелы, чтобы цена не переносилась
        return number.replacingOccurrences(of: " ", with: "\u{00A0}")
            .replacingOccurrences(of: "\u{202F}", with: "\u{00A0}") + "\u{00A0}₽"
    }

    /// 182.0 → «182», 10.5 → «10.5»
    static func number(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(value)
    }

    /// pluralize(5, "товар", "товара", "товаров") → «товаров»
    static func pluralize(_ value: Int, _ one: String, _ few: String, _ many: String) -> String {
        let n = abs(value) % 100
        let n1 = n % 10

        if n > 10 && n < 20 { return many }
        if n1 > 1 && n1 < 5 { return few }
        if n1 == 1 { return one }

        return many
    }
}

/// Процентная скидка (AmountOff) — app/utils/discount.ts сайта.
/// Фиксированные скидки (fixed_value) пока не отображаются.
enum Discount {
    static func percent(_ discounts: [Promotion.Discount]?) -> Int {
        guard let discount = discounts?.first(where: { isAmountOff($0.type) }) else {
            return 0
        }

        if discount.fixedValue ?? discount.data?.fixedValue ?? false {
            return 0
        }

        let percentage = discount.percentage ?? discount.data?.percentage ?? 0

        return percentage > 0 ? Int(percentage) : 0
    }

    static func apply(_ price: Double, percent: Int) -> Double {
        guard percent > 0 else { return price }
        return (price * (1 - Double(percent) / 100)).rounded()
    }

    private static func isAmountOff(_ type: String?) -> Bool {
        type == "AmountOff" || type == "Lunar\\DiscountTypes\\AmountOff"
    }
}
