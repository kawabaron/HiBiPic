import SwiftUI

// MARK: - DesignTemplatePicker

/// A 2x2 grid of design template preview cards with single selection.
struct DesignTemplatePicker: View {

    // MARK: - Properties

    let selectedType: DesignTemplateType
    let onSelect: (DesignTemplateType) -> Void

    // MARK: - Layout

    private let columns = [
        GridItem(.flexible(), spacing: DSSpacing.md),
        GridItem(.flexible(), spacing: DSSpacing.md)
    ]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text("写真の雰囲気")
                .font(DSTypography.headline)
                .foregroundStyle(DSColors.textPrimary)

            LazyVGrid(columns: columns, spacing: DSSpacing.md) {
                ForEach(DesignTemplateStore.allTemplates) { template in
                    designCard(template)
                }
            }
        }
    }

    // MARK: - Design Card

    private func designCard(_ template: DesignTemplate) -> some View {
        let isSelected = template.id == selectedType

        return Button {
            onSelect(template.id)
        } label: {
            VStack(spacing: DSSpacing.sm) {
                // Visual preview
                templatePreview(template)

                // Template name
                Text(template.name)
                    .font(DSTypography.footnote)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? DSColors.accent : DSColors.textSecondary)
            }
            .padding(DSSpacing.sm)
            .background(DSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerLg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DSSpacing.cornerLg, style: .continuous)
                    .strokeBorder(
                        isSelected ? DSColors.accent : DSColors.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .dsShadow(isSelected ? .card : .soft)
        }
        .buttonStyle(DesignCardPressStyle())
    }

    // MARK: - Template Preview

    private func templatePreview(_ template: DesignTemplate) -> some View {
        let textColor = Color(hex: template.textColor)
        let bgColor = Color(hex: template.backgroundColor)

        return ZStack {
            // Dark photo-like background
            RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous)
                .fill(previewGradient(for: template.id))

            // Text overlay mimicking each style
            VStack {
                Spacer()

                if template.showBackground {
                    sampleOverlay(template: template, textColor: textColor)
                        .padding(.horizontal, DSSpacing.sm)
                        .padding(.vertical, DSSpacing.xs)
                        .frame(maxWidth: .infinity)
                        .background(bgColor)
                } else {
                    sampleOverlay(template: template, textColor: textColor)
                        .padding(.horizontal, DSSpacing.md)
                        .padding(.bottom, DSSpacing.sm)
                }
            }
        }
        .aspectRatio(4.0 / 3.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
    }

    @ViewBuilder
    private func sampleOverlay(template: DesignTemplate, textColor: Color) -> some View {
        let align: Alignment = {
            switch template.alignment {
            case .left:   return .leading
            case .center: return .center
            case .right:  return .trailing
            }
        }()

        let textAlign: SwiftUI.TextAlignment = {
            switch template.alignment {
            case .left:   return .leading
            case .center: return .center
            case .right:  return .trailing
            }
        }()

        if template.numberEmphasis && template.defaultLayoutMode == .double {
            VStack(spacing: 1) {
                Text("イベント")
                    .font(.system(size: 8, weight: fontWeight(template.fontWeight)))
                    .foregroundStyle(textColor)

                Text("30日")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor)
            }
            .frame(maxWidth: .infinity, alignment: align)
            .multilineTextAlignment(textAlign)
        } else {
            Text("イベント 30日")
                .font(.system(size: 10, weight: fontWeight(template.fontWeight)))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity, alignment: align)
                .multilineTextAlignment(textAlign)
        }
    }

    // MARK: - Helpers

    private func previewGradient(for type: DesignTemplateType) -> LinearGradient {
        switch type {
        case .minimal:
            return LinearGradient(
                colors: [Color(hex: "5A5A5A"), Color(hex: "3A3A3A")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .soft:
            return LinearGradient(
                colors: [Color(hex: "6B5B4F"), Color(hex: "4A3F38")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .film:
            return LinearGradient(
                colors: [Color(hex: "4A5A4F"), Color(hex: "2E3A32")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .poster:
            return LinearGradient(
                colors: [Color(hex: "3A3A50"), Color(hex: "1E1E2E")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    private func fontWeight(_ weight: DesignTemplate.FontWeight) -> Font.Weight {
        switch weight {
        case .thin:     return .thin
        case .light:    return .light
        case .regular:  return .regular
        case .medium:   return .medium
        case .semibold: return .semibold
        case .bold:     return .bold
        case .heavy:    return .heavy
        }
    }
}

// MARK: - Button Style

private struct DesignCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        DesignTemplatePicker(
            selectedType: .minimal,
            onSelect: { _ in }
        )
        .padding(DSSpacing.xl)
    }
    .background(DSColors.background)
}
