import SwiftUI

// MARK: - Кнопка (UiButton)

struct AppButtonStyle: ButtonStyle {
    enum Variant { case primary, secondary, ghost, danger, muted }
    enum Size { case sm, md, lg }

    var variant: Variant = .primary
    var size: Size = .md
    var block = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed

        configuration.label
            .appFont(fontSize, .medium)
            .caps(0.04, size: fontSize)
            .lineLimit(1)
            .padding(.horizontal, horizontalPadding)
            .frame(height: height)
            .frame(maxWidth: block ? .infinity : nil)
            .foregroundStyle(foreground)
            .background(background(pressed: pressed))
            .overlay {
                if let border {
                    RoundedRectangle(cornerRadius: Palette.radius).stroke(border, lineWidth: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Palette.radius))
            .opacity(isEnabled ? 1 : 0.5)
            .contentShape(Rectangle())
            .animation(.easeOut(duration: 0.2), value: pressed)
    }

    private var height: CGFloat {
        switch size { case .sm: 36; case .md: 44; case .lg: 48 }
    }

    private var horizontalPadding: CGFloat {
        switch size { case .sm: 16; case .md: 24; case .lg: 32 }
    }

    private var fontSize: CGFloat {
        switch size { case .sm: 12; case .md: 13; case .lg: 14 }
    }

    private var foreground: Color {
        switch variant {
        case .primary: Palette.onAccent
        case .secondary: Palette.fg
        case .ghost: Palette.muted
        case .danger: Palette.danger
        case .muted: Palette.subtle
        }
    }

    private var border: Color? {
        switch variant {
        case .secondary: Palette.outline
        case .danger: Palette.danger.opacity(0.3)
        default: nil
        }
    }

    private func background(pressed: Bool) -> Color {
        switch variant {
        case .primary: pressed ? Palette.accentHover : Palette.accent
        case .secondary: pressed ? Palette.accent.opacity(0.1) : .clear
        case .ghost: pressed ? Palette.fg.opacity(0.05) : .clear
        case .danger: pressed ? Palette.danger.opacity(0.1) : .clear
        case .muted: Palette.surfaceOverlay
        }
    }
}

extension ButtonStyle where Self == AppButtonStyle {
    static func app(_ variant: AppButtonStyle.Variant = .primary, size: AppButtonStyle.Size = .md, block: Bool = false) -> AppButtonStyle {
        AppButtonStyle(variant: variant, size: size, block: block)
    }
}

// MARK: - Бейдж (UiBadge)

struct AppBadge: View {
    enum Tone { case neutral, gold, sale, success, danger, warning, info }

    let text: String
    var tone: Tone = .neutral
    var small = false
    /// Поверх фото: полупрозрачный тёмный фон
    var overlay = false

    var body: some View {
        let size: CGFloat = small ? 10 : 11

        Text(text)
            .appFont(size, .medium)
            .caps(0.08, size: size)
            .lineLimit(1)
            .padding(.horizontal, small ? 6 : 10)
            .padding(.vertical, small ? 2 : 4)
            .foregroundStyle(overlay ? Color.white.opacity(0.85) : color)
            .background(overlay ? AnyShapeStyle(Color.black.opacity(0.6)) : AnyShapeStyle(color.opacity(0.1)))
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(overlay ? Color.white.opacity(0.1) : color.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 2))
    }

    private var color: Color {
        switch tone {
        case .neutral: Palette.muted
        case .gold: Palette.gold
        case .sale: Palette.sale
        case .success: Palette.success
        case .danger: Palette.danger
        case .warning: Palette.warning
        case .info: Palette.info
        }
    }
}

// MARK: - Цена (UiPrice)

struct PriceView: View {
    enum Size { case sm, md, lg, xl }

    let value: Double
    var oldValue: Double?
    var discount: Int?
    var size: Size = .md

    private var hasDiscount: Bool {
        guard let oldValue else { return false }
        return oldValue > value
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(Format.price(value))
                .appFont(valueSize, .semibold)
                .monospacedDigit()
                .foregroundStyle(hasDiscount ? Palette.sale : Palette.fg)

            if hasDiscount, let oldValue {
                Text(Format.price(oldValue))
                    .appFont(oldSize)
                    .strikethrough()
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtle)

                if let discount, discount > 0 {
                    AppBadge(text: "−\(discount)%", tone: .sale, small: true)
                        .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 4 }
                }
            }
        }
    }

    private var valueSize: CGFloat {
        switch size { case .sm: 14; case .md: 18; case .lg: 20; case .xl: 30 }
    }

    private var oldSize: CGFloat {
        switch size { case .sm: 12; case .md, .lg: 14; case .xl: 18 }
    }
}

// MARK: - Типографика (UiTypoEyebrow / UiTypoSectionTitle)

struct Eyebrow: View {
    let text: String
    var line = false

    var body: some View {
        HStack(spacing: 12) {
            if line {
                Rectangle().fill(Palette.gold).frame(width: 32, height: 1)
            }

            Text(text)
                .appFont(10, .medium)
                .caps(0.16, size: 10)
                .foregroundStyle(Palette.gold)
        }
    }
}

struct SectionTitle: View {
    let title: String
    var eyebrow: String?
    var size: CGFloat = 34

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let eyebrow {
                Eyebrow(text: eyebrow, line: true).padding(.bottom, 12)
            }

            Text(title)
                .appFont(size, .bold)
                .caps(-0.04, size: size)
                .foregroundStyle(Palette.fg)
                .lineSpacing(0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.line).frame(height: 1)
        }
        .padding(.bottom, 28)
    }
}

// MARK: - Логотип (UiLogo)

struct Logo: View {
    var size: CGFloat = 20

    var body: some View {
        // На сайте — Gilroy ExtraBold. Шрифт коммерческий, в публичный репозиторий
        // его не кладём; пока Montserrat Bold с плотной разрядкой.
        Text("INTELEGENTOFF")
            .appFont(size, .bold)
            .tracking(-0.025 * size)
            .foregroundStyle(Palette.fg)
    }
}

// MARK: - Скелетон (UiSkeleton)

struct Skeleton: View {
    @State private var phase = false

    var body: some View {
        RoundedRectangle(cornerRadius: Palette.radius)
            .fill(Palette.surfaceOverlay)
            .opacity(phase ? 0.5 : 1)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: phase)
            .onAppear { phase = true }
    }
}

// MARK: - Картинка из сети

/// AsyncImage со скелетоном при загрузке и заглушкой при ошибке.
/// WebP iOS декодирует сам.
struct RemoteImage: View {
    let url: URL?
    var contentMode: ContentMode = .fill

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.25))) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: contentMode)
            case .failure:
                ImagePlaceholder()
            case .empty:
                if url == nil { ImagePlaceholder() } else { Skeleton() }
            @unknown default:
                ImagePlaceholder()
            }
        }
    }
}

struct ImagePlaceholder: View {
    var body: some View {
        ZStack {
            Palette.surfaceRaised
            Image(systemName: "photo")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Color.gray.opacity(0.35))
        }
    }
}

// MARK: - Пустое состояние (UiEmptyState)

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    var text: String?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Palette.subtle)

            Text(title)
                .appFont(15, .semibold)
                .foregroundStyle(Palette.fg)

            if let text {
                Text(text)
                    .appFont(13)
                    .foregroundStyle(Palette.muted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}
