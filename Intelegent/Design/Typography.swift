import SwiftUI

/// Montserrat — основной шрифт сайта. Если файла шрифта нет, SwiftUI тихо
/// подставит системный, поэтому вёрстка не ломается.
enum AppFont {
    enum Weight: String {
        case regular = "Montserrat-Regular"
        case medium = "Montserrat-Medium"
        case semibold = "Montserrat-SemiBold"
        case bold = "Montserrat-Bold"
    }

    static func montserrat(_ size: CGFloat, _ weight: Weight = .regular) -> Font {
        .custom(weight.rawValue, fixedSize: size)
    }
}

extension View {
    /// Шрифт проекта: `.appFont(13, .medium)`
    func appFont(_ size: CGFloat, _ weight: AppFont.Weight = .regular) -> some View {
        font(AppFont.montserrat(size, weight))
    }

    /// Капс с разрядкой, как `uppercase tracking-[…]` на сайте. tracking — в em.
    func caps(_ tracking: CGFloat = 0.04, size: CGFloat) -> some View {
        textCase(.uppercase).tracking(tracking * size)
    }
}
