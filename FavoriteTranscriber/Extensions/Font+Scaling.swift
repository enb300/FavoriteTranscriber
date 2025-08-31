import SwiftUI

extension Font {
    func scaled(_ multiplier: Double) -> Font {
        switch self {
        case .largeTitle:
            return .system(size: 34 * multiplier, weight: .regular, design: .default)
        case .title:
            return .system(size: 28 * multiplier, weight: .regular, design: .default)
        case .title2:
            return .system(size: 22 * multiplier, weight: .regular, design: .default)
        case .title3:
            return .system(size: 20 * multiplier, weight: .regular, design: .default)
        case .headline:
            return .system(size: 17 * multiplier, weight: .semibold, design: .default)
        case .body:
            return .system(size: 17 * multiplier, weight: .regular, design: .default)
        case .callout:
            return .system(size: 16 * multiplier, weight: .regular, design: .default)
        case .subheadline:
            return .system(size: 15 * multiplier, weight: .regular, design: .default)
        case .footnote:
            return .system(size: 13 * multiplier, weight: .regular, design: .default)
        case .caption:
            return .system(size: 12 * multiplier, weight: .regular, design: .default)
        case .caption2:
            return .system(size: 11 * multiplier, weight: .regular, design: .default)
        default:
            return .system(size: 17 * multiplier, weight: .regular, design: .default)
        }
    }
}

// Environment key for text size multiplier
struct TextSizeMultiplierKey: EnvironmentKey {
    static let defaultValue: Double = 1.0
}

extension EnvironmentValues {
    var textSizeMultiplier: Double {
        get { self[TextSizeMultiplierKey.self] }
        set { self[TextSizeMultiplierKey.self] = newValue }
    }
}

// View modifier to apply scaled fonts
struct ScaledFont: ViewModifier {
    let font: Font
    @Environment(\.textSizeMultiplier) var multiplier
    
    func body(content: Content) -> some View {
        content
            .font(font.scaled(multiplier))
    }
}

extension View {
    func scaledFont(_ font: Font) -> some View {
        self.modifier(ScaledFont(font: font))
    }
}
