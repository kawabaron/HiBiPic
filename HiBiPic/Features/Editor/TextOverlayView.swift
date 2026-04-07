import SwiftUI

// MARK: - TextOverlayView

/// The SwiftUI text overlay rendered on top of the photo preview.
/// Styled differently depending on the active `DesignTemplate`.
struct TextOverlayView: View {

    // MARK: - Properties

    let designTemplate: DesignTemplate
    let layoutMode: LayoutMode
    let line1: String
    let line2: String
    let singleLine: String
    let scale: CGFloat
    let colorOverride: Color?
    let showBackground: Bool

    // MARK: - Derived

    /// The effective text colour: override, or template default.
    private var textColor: Color {
        colorOverride ?? Color(hex: designTemplate.textColor)
    }

    /// The template's background band colour.
    private var bandColor: Color {
        Color(hex: designTemplate.backgroundColor)
    }

    /// The SwiftUI font weight mapped from the template's weight enum.
    private var fontWeight: Font.Weight {
        switch designTemplate.fontWeight {
        case .thin:     return .thin
        case .light:    return .light
        case .regular:  return .regular
        case .medium:   return .medium
        case .semibold: return .semibold
        case .bold:     return .bold
        case .heavy:    return .heavy
        }
    }

    /// The base font size before scaling, adjusted per template.
    private var baseFontSize: CGFloat {
        18 * designTemplate.fontSizeScale
    }

    /// The large number font size for double-line layouts with number emphasis.
    private var numberFontSize: CGFloat {
        32 * designTemplate.fontSizeScale
    }

    /// Text alignment from the template.
    private var horizontalAlignment: HorizontalAlignment {
        switch designTemplate.alignment {
        case .left:   return .leading
        case .center: return .center
        case .right:  return .trailing
        }
    }

    /// Multiline text alignment.
    private var multilineAlignment: SwiftUI.TextAlignment {
        switch designTemplate.alignment {
        case .left:   return .leading
        case .center: return .center
        case .right:  return .trailing
        }
    }

    // MARK: - Body

    var body: some View {
        templateContent
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if showBackground {
                    backgroundBand
                }
            }
            .scaleEffect(scale)
    }

    // MARK: - Template Content

    @ViewBuilder
    private var templateContent: some View {
        switch designTemplate.id {
        case .minimal:
            minimalLayout
        case .soft:
            softLayout
        case .film:
            filmLayout
        case .poster:
            posterLayout
        }
    }

    // MARK: - Minimal Template

    /// Clean white text, no band, thin weight, centred.
    @ViewBuilder
    private var minimalLayout: some View {
        if layoutMode == .single {
            Text(singleLine)
                .font(.system(size: baseFontSize * scale, weight: fontWeight, design: .default))
                .foregroundStyle(textColor)
                .multilineTextAlignment(multilineAlignment)
                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 1)
        } else {
            VStack(alignment: horizontalAlignment, spacing: 4 * scale) {
                Text(line1)
                    .font(.system(size: baseFontSize * scale, weight: fontWeight, design: .default))
                    .foregroundStyle(textColor)
                Text(line2)
                    .font(.system(size: baseFontSize * scale, weight: fontWeight, design: .default))
                    .foregroundStyle(textColor)
            }
            .multilineTextAlignment(multilineAlignment)
            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 1)
        }
    }

    // MARK: - Soft Template

    /// Warm cream text, semi-transparent band, rounded feel, number emphasis.
    @ViewBuilder
    private var softLayout: some View {
        if layoutMode == .single {
            Text(singleLine)
                .font(.system(size: baseFontSize * scale, weight: fontWeight, design: .rounded))
                .foregroundStyle(textColor)
                .multilineTextAlignment(multilineAlignment)
        } else {
            VStack(alignment: horizontalAlignment, spacing: 4 * scale) {
                Text(line1)
                    .font(.system(size: (baseFontSize - 2) * scale, weight: fontWeight, design: .rounded))
                    .foregroundStyle(textColor.opacity(0.9))
                Text(line2)
                    .font(.system(
                        size: (designTemplate.numberEmphasis ? numberFontSize : baseFontSize) * scale,
                        weight: designTemplate.numberEmphasis ? .semibold : fontWeight,
                        design: .rounded
                    ))
                    .foregroundStyle(textColor)
            }
            .multilineTextAlignment(multilineAlignment)
        }
    }

    // MARK: - Film Template

    /// Off-white text, left-aligned, no band, light weight, retro feel.
    @ViewBuilder
    private var filmLayout: some View {
        if layoutMode == .single {
            Text(singleLine)
                .font(.system(size: baseFontSize * scale, weight: fontWeight, design: .default))
                .foregroundStyle(textColor)
                .multilineTextAlignment(multilineAlignment)
                .tracking(0.5)
                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 1)
        } else {
            VStack(alignment: horizontalAlignment, spacing: 6 * scale) {
                Text(line1)
                    .font(.system(size: (baseFontSize - 2) * scale, weight: fontWeight, design: .default))
                    .foregroundStyle(textColor.opacity(0.85))
                    .tracking(0.5)
                Text(line2)
                    .font(.system(size: baseFontSize * scale, weight: fontWeight, design: .default))
                    .foregroundStyle(textColor)
                    .tracking(0.5)
            }
            .multilineTextAlignment(multilineAlignment)
            .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 1)
        }
    }

    // MARK: - Poster Template

    /// Large bold numbers, strong text, high contrast band.
    @ViewBuilder
    private var posterLayout: some View {
        if layoutMode == .single {
            Text(singleLine)
                .font(.system(size: baseFontSize * scale, weight: fontWeight, design: .rounded))
                .foregroundStyle(textColor)
                .multilineTextAlignment(multilineAlignment)
        } else {
            VStack(alignment: horizontalAlignment, spacing: 2 * scale) {
                Text(line1)
                    .font(.system(size: (baseFontSize - 4) * scale, weight: .medium, design: .rounded))
                    .foregroundStyle(textColor.opacity(0.9))
                    .textCase(.uppercase)
                Text(line2)
                    .font(.system(
                        size: (designTemplate.numberEmphasis ? (numberFontSize + 8) : baseFontSize) * scale,
                        weight: .heavy,
                        design: .rounded
                    ))
                    .foregroundStyle(textColor)
            }
            .multilineTextAlignment(multilineAlignment)
        }
    }

    // MARK: - Background Band

    private var backgroundBand: some View {
        RoundedRectangle(cornerRadius: 6 * scale, style: .continuous)
            .fill(bandColor)
    }
}

// MARK: - Preview

#Preview("Minimal Single") {
    ZStack {
        Color.gray
        TextOverlayView(
            designTemplate: DesignTemplateStore.template(for: .minimal),
            layoutMode: .single,
            line1: "",
            line2: "",
            singleLine: "誕生日まで あと30日",
            scale: 1.0,
            colorOverride: nil,
            showBackground: false
        )
    }
}

#Preview("Poster Double") {
    ZStack {
        Color.gray
        TextOverlayView(
            designTemplate: DesignTemplateStore.template(for: .poster),
            layoutMode: .double,
            line1: "誕生日",
            line2: "あと30日",
            singleLine: "",
            scale: 1.0,
            colorOverride: nil,
            showBackground: true
        )
    }
}
