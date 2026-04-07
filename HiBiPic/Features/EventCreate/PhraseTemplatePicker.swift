import SwiftUI

// MARK: - PhraseTemplatePicker

/// Horizontal scrolling phrase template selector with a custom-input option at the end.
struct PhraseTemplatePicker: View {

    // MARK: - Properties

    let templates: [PhraseTemplate]
    let selectedTemplateId: String
    let isCustomMode: Bool
    let eventName: String
    let dayCount: Int
    let onSelect: (PhraseTemplate) -> Void
    let onCustomTap: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text("文言デザイン")
                .font(DSTypography.headline)
                .foregroundStyle(DSColors.textPrimary)

            templateScroller
        }
    }

    // MARK: - Template Scroller

    private var templateScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DSSpacing.md) {
                ForEach(templates) { template in
                    templateCard(template)
                }

                // Custom input option at the end
                customCard
            }
            .padding(.horizontal, DSSpacing.xxs)
            .padding(.vertical, DSSpacing.xs)
        }
    }

    // MARK: - Template Card

    private func templateCard(_ template: PhraseTemplate) -> some View {
        let isSelected = !isCustomMode && template.id == selectedTemplateId
        let previewLabel = eventName.isEmpty ? "イベント" : eventName
        let n = String(dayCount)

        // Resolve preview text
        let previewText: String = {
            if template.layoutMode == .single {
                return template.singleLineTemplate
                    .replacingOccurrences(of: "{label}", with: previewLabel)
                    .replacingOccurrences(of: "{n}", with: n)
            } else {
                let l1 = template.line1Template
                    .replacingOccurrences(of: "{label}", with: previewLabel)
                    .replacingOccurrences(of: "{n}", with: n)
                let l2 = template.line2Template
                    .replacingOccurrences(of: "{label}", with: previewLabel)
                    .replacingOccurrences(of: "{n}", with: n)
                return "\(l1)\n\(l2)"
            }
        }()

        return Button {
            onSelect(template)
        } label: {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text(previewText)
                    .font(DSTypography.subheadline)
                    .foregroundStyle(DSColors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                // Layout mode badge
                HStack(spacing: DSSpacing.xs) {
                    Image(systemName: template.layoutMode == .single ? "text.alignleft" : "text.justify.leading")
                        .font(.system(size: 10))
                    Text(template.layoutMode == .single ? "1行" : "2行")
                        .font(DSTypography.caption)
                }
                .foregroundStyle(isSelected ? DSColors.accent : DSColors.textTertiary)
            }
            .padding(DSSpacing.md)
            .frame(width: 160, height: 100, alignment: .topLeading)
            .background(DSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous)
                    .strokeBorder(
                        isSelected ? DSColors.accent : DSColors.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .dsShadow(isSelected ? .card : .soft)
        }
        .buttonStyle(CardPressButtonStyle())
    }

    // MARK: - Custom Card

    private var customCard: some View {
        Button {
            onCustomTap()
        } label: {
            VStack(spacing: DSSpacing.sm) {
                Image(systemName: "pencil.line")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isCustomMode ? DSColors.accent : DSColors.textSecondary)

                Text("自分で入力")
                    .font(DSTypography.footnote)
                    .foregroundStyle(isCustomMode ? DSColors.accent : DSColors.textSecondary)
            }
            .frame(width: 100, height: 100)
            .background(DSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous)
                    .strokeBorder(
                        isCustomMode ? DSColors.accent : DSColors.border,
                        lineWidth: isCustomMode ? 2 : 1
                    )
            }
            .dsShadow(isCustomMode ? .card : .soft)
        }
        .buttonStyle(CardPressButtonStyle())
    }
}

// MARK: - Card Press Button Style

private struct CardPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        PhraseTemplatePicker(
            templates: PhraseTemplateStore.templates(for: .elapsed),
            selectedTemplateId: "elapsed_single_1",
            isCustomMode: false,
            eventName: "入社",
            dayCount: 100,
            onSelect: { _ in },
            onCustomTap: {}
        )
        .padding(DSSpacing.xl)
    }
    .background(DSColors.background)
}
