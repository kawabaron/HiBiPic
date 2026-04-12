import SwiftUI

// MARK: - PhraseTemplatePicker

/// Horizontal scrolling phrase template selector with favorites and a custom-input option.
struct PhraseTemplatePicker: View {

    // MARK: - Properties

    let templates: [PhraseTemplate]
    let selectedTemplateId: String
    let isCustomMode: Bool
    let countType: CountType
    let designTemplateType: DesignTemplateType
    let eventName: String
    let dayCount: Int
    let favoriteTemplateIds: Set<String>
    let showsTitle: Bool
    let showsFavoriteControls: Bool
    let onSelect: (PhraseTemplate) -> Void
    let onToggleFavorite: (PhraseTemplate) -> Void
    let onCustomTap: () -> Void

    init(
        templates: [PhraseTemplate],
        selectedTemplateId: String,
        isCustomMode: Bool,
        countType: CountType,
        designTemplateType: DesignTemplateType,
        eventName: String,
        dayCount: Int,
        favoriteTemplateIds: Set<String>,
        showsTitle: Bool,
        showsFavoriteControls: Bool = true,
        onSelect: @escaping (PhraseTemplate) -> Void,
        onToggleFavorite: @escaping (PhraseTemplate) -> Void,
        onCustomTap: @escaping () -> Void
    ) {
        self.templates = templates
        self.selectedTemplateId = selectedTemplateId
        self.isCustomMode = isCustomMode
        self.countType = countType
        self.designTemplateType = designTemplateType
        self.eventName = eventName
        self.dayCount = dayCount
        self.favoriteTemplateIds = favoriteTemplateIds
        self.showsTitle = showsTitle
        self.showsFavoriteControls = showsFavoriteControls
        self.onSelect = onSelect
        self.onToggleFavorite = onToggleFavorite
        self.onCustomTap = onCustomTap
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            if showsTitle {
                Text(L10n.t("文言デザイン"))
                    .font(DSTypography.headline)
                    .foregroundStyle(DSColors.textPrimary)
            }

            if showsFavoriteControls {
                favoriteHint
            }
            templateScroller
        }
    }

    private var favoriteTemplates: [PhraseTemplate] {
        guard showsFavoriteControls else { return [] }
        return templates.filter { favoriteTemplateIds.contains($0.id) }
    }

    private var builtInTemplates: [PhraseTemplate] {
        templates.filter {
            (!showsFavoriteControls || !favoriteTemplateIds.contains($0.id)) && !$0.isUserSaved
        }
    }

    private var savedTemplates: [PhraseTemplate] {
        templates.filter {
            (!showsFavoriteControls || !favoriteTemplateIds.contains($0.id)) && $0.isUserSaved
        }
    }

    private var isSavedCustomTemplateSelected: Bool {
        isCustomMode && templates.contains { $0.isUserSaved && $0.id == selectedTemplateId }
    }

    private var favoriteHint: some View {
        HStack(spacing: DSSpacing.xxs) {
            Image(systemName: favoriteTemplates.isEmpty ? "star" : "star.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(favoriteTemplates.isEmpty ? DSColors.textTertiary : DSColors.warning)

            Text(
                favoriteTemplates.isEmpty
                    ? L10n.t("よく使うテンプレートは星でお気に入り")
                    : L10n.t("お気に入りを先頭に表示中")
            )
            .font(DSTypography.caption)
            .foregroundStyle(favoriteTemplates.isEmpty ? DSColors.textTertiary : DSColors.textSecondary)
        }
    }

    // MARK: - Template Scroller

    private var templateScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DSSpacing.md) {
                ForEach(favoriteTemplates) { template in
                    templateCard(template)
                }

                if !favoriteTemplates.isEmpty && (!builtInTemplates.isEmpty || !savedTemplates.isEmpty) {
                    favoritesDivider
                }

                ForEach(builtInTemplates) { template in
                    templateCard(template)
                }

                if !savedTemplates.isEmpty && (!favoriteTemplates.isEmpty || !builtInTemplates.isEmpty) {
                    favoritesDivider
                }

                ForEach(savedTemplates) { template in
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
        let isSelected = template.id == selectedTemplateId && (!isCustomMode || template.isUserSaved)
        let isFavorite = favoriteTemplateIds.contains(template.id)
        let previewLabel = eventName.isEmpty ? L10n.t("fallback.preview.name") : eventName

        let previewLines = resolvedPreviewLines(
            template: template,
            previewLabel: previewLabel,
            dayCount: dayCount
        )
        let previewText = previewLines.joined(separator: "\n")
        let lineCountLabel = L10n.f("%d行", previewLines.count)

        return ZStack(alignment: .topTrailing) {
            Button {
                onSelect(template)
            } label: {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text(previewText)
                        .font(DSTypography.subheadline)
                        .foregroundStyle(DSColors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.trailing, DSSpacing.xl)

                    Spacer(minLength: 0)

                    HStack(spacing: DSSpacing.xs) {
                        if template.isUserSaved {
                            Text(L10n.t("保存済み"))
                                .font(DSTypography.caption)
                                .foregroundStyle(DSColors.accentDark)
                                .padding(.horizontal, DSSpacing.xs)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(DSColors.accentLight.opacity(0.38))
                                )
                        }

                        Spacer(minLength: 0)

                        HStack(spacing: DSSpacing.xs) {
                            Image(systemName: template.layoutMode == .single ? "text.alignleft" : "text.justify.leading")
                                .font(.system(size: 10))
                            Text(lineCountLabel)
                                .font(DSTypography.caption)
                        }
                        .foregroundStyle(isSelected ? DSColors.accent : DSColors.textTertiary)
                    }
                }
                .padding(DSSpacing.md)
                .frame(width: 160, height: 112, alignment: .topLeading)
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

            Button {
                onToggleFavorite(template)
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isFavorite ? DSColors.warning : DSColors.textTertiary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(DSColors.cardBackground.opacity(0.96))
                    )
                    .overlay {
                        Circle()
                            .strokeBorder(DSColors.border, lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.top, DSSpacing.xs)
            .padding(.trailing, DSSpacing.xs)
            .accessibilityLabel(
                isFavorite
                    ? L10n.f("%@ をお気に入り解除", template.label)
                    : L10n.f("%@ をお気に入り登録", template.label)
            )
            .opacity(showsFavoriteControls ? 1 : 0)
            .allowsHitTesting(showsFavoriteControls)
        }
    }

    private var favoritesDivider: some View {
        RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous)
            .fill(DSColors.border)
            .frame(width: 1, height: 72)
            .padding(.horizontal, DSSpacing.xxs)
    }

    private func resolvedPreviewLines(
        template: PhraseTemplate,
        previewLabel: String,
        dayCount: Int
    ) -> [String] {
        let resolved = PhraseDisplayAdjuster.adjust(
            lines: (
                singleLine: PlaceholderTextResolver.resolve(
                    template: template.singleLineTemplate,
                    label: previewLabel,
                    count: dayCount
                ),
                line1: PlaceholderTextResolver.resolve(
                    template: template.line1Template,
                    label: previewLabel,
                    count: dayCount
                ),
                line2: PlaceholderTextResolver.resolve(
                    template: template.line2Template,
                    label: previewLabel,
                    count: dayCount
                ),
                line3: PlaceholderTextResolver.resolve(
                    template: template.line3Template,
                    label: previewLabel,
                    count: dayCount
                )
            ),
            label: previewLabel,
            count: dayCount,
            countType: countType,
            designTemplateId: designTemplateType,
            phraseTemplateId: template.id
        )

        if template.layoutMode == .single {
            return [resolved.singleLine]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }

        return [resolved.line1, resolved.line2, resolved.line3]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
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

                Text(L10n.t("自分で入力"))
                    .font(DSTypography.footnote)
                    .foregroundStyle(isCustomMode ? DSColors.accent : DSColors.textSecondary)
            }
            .frame(width: 100, height: 100)
            .background(DSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous)
                    .strokeBorder(
                        (isCustomMode && !isSavedCustomTemplateSelected) ? DSColors.accent : DSColors.border,
                        lineWidth: (isCustomMode && !isSavedCustomTemplateSelected) ? 2 : 1
                    )
            }
            .dsShadow((isCustomMode && !isSavedCustomTemplateSelected) ? .card : .soft)
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
            countType: .elapsed,
            designTemplateType: .minimal,
            eventName: "入社",
            dayCount: 100,
            favoriteTemplateIds: ["elapsed_double_1"],
            showsTitle: true,
            onSelect: { _ in },
            onToggleFavorite: { _ in },
            onCustomTap: {}
        )
        .padding(DSSpacing.xl)
    }
    .background(DSColors.background)
}
