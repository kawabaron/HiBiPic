import SwiftUI

// MARK: - EventPreviewSection

/// Live preview showing how the text overlay will appear on a photo.
/// Updates immediately as the user changes any setting.
struct EventPreviewSection: View {

    // MARK: - Properties

    let previewText: (singleLine: String, line1: String, line2: String)
    let designTemplateType: DesignTemplateType
    let layoutMode: LayoutMode

    // MARK: - Private

    private var design: DesignTemplate {
        DesignTemplateStore.template(for: designTemplateType)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text("仕上がりイメージ")
                .font(DSTypography.headline)
                .foregroundStyle(DSColors.textPrimary)

            previewCard
        }
    }

    // MARK: - Preview Card

    private var previewCard: some View {
        ZStack {
            // Simulated photo background
            RoundedRectangle(cornerRadius: DSSpacing.cornerLg, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "4A4A4A"),
                            Color(hex: "3A3A3A"),
                            Color(hex: "2E2E2E")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Subtle grain texture overlay
            RoundedRectangle(cornerRadius: DSSpacing.cornerLg, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.05))

            // Text overlay positioned per design template
            textOverlay
        }
        .aspectRatio(4.0 / 3.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerLg, style: .continuous))
        .dsShadow(.card)
    }

    // MARK: - Text Overlay

    @ViewBuilder
    private var textOverlay: some View {
        let alignment = overlayAlignment
        let textAlign = textMultilineAlignment

        VStack(spacing: 0) {
            if alignment != .top { Spacer() }

            if design.showBackground {
                overlayTextContent(textAlign: textAlign)
                    .padding(.horizontal, DSSpacing.lg)
                    .padding(.vertical, DSSpacing.md)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: design.backgroundColor))
            } else {
                overlayTextContent(textAlign: textAlign)
                    .padding(.horizontal, DSSpacing.xl)
                    .padding(.bottom, DSSpacing.xl)
            }

            if alignment == .top { Spacer() }
        }
    }

    @ViewBuilder
    private func overlayTextContent(textAlign: SwiftUI.TextAlignment) -> some View {
        let textColor = Color(hex: design.textColor)

        if layoutMode == .double {
            // Double line layout
            VStack(spacing: DSSpacing.xs) {
                Text(displayLine1)
                    .font(line1Font)
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(textAlign)

                Text(displayLine2)
                    .font(line2Font)
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(textAlign)
            }
            .frame(maxWidth: .infinity, alignment: frameAlignment)
        } else {
            // Single line layout
            Text(displaySingleLine)
                .font(singleLineFont)
                .foregroundStyle(textColor)
                .multilineTextAlignment(textAlign)
                .frame(maxWidth: .infinity, alignment: frameAlignment)
        }
    }

    // MARK: - Display Text Helpers

    private var displaySingleLine: String {
        let text = previewText.singleLine
        return text.isEmpty ? "プレビュー" : text
    }

    private var displayLine1: String {
        let text = previewText.line1
        return text.isEmpty ? "ライン1" : text
    }

    private var displayLine2: String {
        let text = previewText.line2
        return text.isEmpty ? "ライン2" : text
    }

    // MARK: - Font Helpers

    private var singleLineFont: Font {
        let baseSize: CGFloat = 16 * design.fontSizeScale
        return Font.system(size: baseSize, weight: swiftUIWeight, design: .rounded)
    }

    private var line1Font: Font {
        let baseSize: CGFloat = design.numberEmphasis ? 13 : 15
        let scaled = baseSize * design.fontSizeScale
        return Font.system(size: scaled, weight: swiftUIWeight, design: .rounded)
    }

    private var line2Font: Font {
        let baseSize: CGFloat = design.numberEmphasis ? 22 : 15
        let scaled = baseSize * design.fontSizeScale
        let weight: Font.Weight = design.numberEmphasis ? .bold : swiftUIWeight
        return Font.system(size: scaled, weight: weight, design: .rounded)
    }

    private var swiftUIWeight: Font.Weight {
        switch design.fontWeight {
        case .thin:     return .thin
        case .light:    return .light
        case .regular:  return .regular
        case .medium:   return .medium
        case .semibold: return .semibold
        case .bold:     return .bold
        case .heavy:    return .heavy
        }
    }

    // MARK: - Alignment Helpers

    private var overlayAlignment: VerticalAlignment {
        .bottom
    }

    private var textMultilineAlignment: SwiftUI.TextAlignment {
        switch design.alignment {
        case .left:   return .leading
        case .center: return .center
        case .right:  return .trailing
        }
    }

    private var frameAlignment: Alignment {
        switch design.alignment {
        case .left:   return .leading
        case .center: return .center
        case .right:  return .trailing
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: DSSpacing.xxl) {
            EventPreviewSection(
                previewText: (singleLine: "入社から 100日経過", line1: "", line2: ""),
                designTemplateType: .minimal,
                layoutMode: .single
            )

            EventPreviewSection(
                previewText: (singleLine: "", line1: "入社", line2: "100日"),
                designTemplateType: .soft,
                layoutMode: .double
            )

            EventPreviewSection(
                previewText: (singleLine: "入社から 100日経過", line1: "", line2: ""),
                designTemplateType: .film,
                layoutMode: .single
            )

            EventPreviewSection(
                previewText: (singleLine: "", line1: "禁煙", line2: "30日目"),
                designTemplateType: .poster,
                layoutMode: .double
            )
        }
        .padding(DSSpacing.xl)
    }
    .background(DSColors.background)
}
