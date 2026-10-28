import SwiftUI
import UIKit

/// Дизайн-токены INTELEGENTOFF — те же, что в tailwind.config.ts / tailwind.css сайта.
///
/// Правила (как на сайте):
///  - фон экрана `canvas`, основной текст `fg`;
///  - акцент только `gold`; заливка кнопок и контролов — `accent`
///    (в тёмной теме золото, в светлой — чёрный);
///  - поверхности: `surface` (карточка), `surfaceRaised` (поле / вложенный блок),
///    `surfaceOverlay` (плашки);
///  - текст: `fg` → `muted` → `subtle` → `faint`;
///  - скругление 4pt для всего.
enum Palette {
    static let canvas = dynamic(dark: (0, 0, 0), light: (250, 249, 247))
    static let fg = dynamic(dark: (255, 255, 255), light: (17, 17, 17))

    static let surface = dynamic(dark: (7, 7, 7), light: (255, 255, 255))
    static let surfaceRaised = dynamic(dark: (11, 11, 11), light: (245, 244, 241))
    static let surfaceOverlay = dynamic(dark: (18, 18, 18), light: (237, 235, 231))

    static let line = dynamic(dark: (38, 38, 38), light: (228, 225, 220))
    static let lineStrong = dynamic(dark: (58, 58, 58), light: (205, 201, 194))

    static let muted = dynamic(dark: (163, 163, 163), light: (87, 83, 78))
    static let subtle = dynamic(dark: (115, 115, 115), light: (120, 115, 108))
    static let faint = dynamic(dark: (82, 82, 82), light: (168, 162, 158))

    static let gold = dynamic(dark: (182, 150, 105), light: (154, 116, 52))
    static let goldLight = dynamic(dark: (208, 181, 140), light: (176, 136, 66))
    static let goldDark = dynamic(dark: (143, 114, 78), light: (122, 92, 42))

    static let accent = dynamic(dark: (182, 150, 105), light: (17, 17, 17))
    static let accentHover = dynamic(dark: (208, 181, 140), light: (54, 54, 54))
    static let onAccent = dynamic(dark: (0, 0, 0), light: (255, 255, 255))
    static let outline = dynamic(dark: (143, 114, 78), light: (17, 17, 17))

    /// Цена со скидкой: золото в тёмной теме, бордовый в светлой
    static let sale = dynamic(dark: (182, 150, 105), light: (155, 44, 44))
    static let danger = dynamic(dark: (248, 113, 113), light: (220, 38, 38))
    static let success = dynamic(dark: (52, 211, 153), light: (5, 150, 105))
    static let warning = dynamic(dark: (251, 191, 36), light: (217, 119, 6))
    static let info = dynamic(dark: (56, 189, 248), light: (2, 132, 199))

    static let radius: CGFloat = 4

    private typealias RGB = (Int, Int, Int)

    private static func dynamic(dark: RGB, light: RGB) -> Color {
        Color(UIColor { traits in
            let c = traits.userInterfaceStyle == .light ? light : dark
            return UIColor(red: CGFloat(c.0) / 255, green: CGFloat(c.1) / 255, blue: CGFloat(c.2) / 255, alpha: 1)
        })
    }
}
