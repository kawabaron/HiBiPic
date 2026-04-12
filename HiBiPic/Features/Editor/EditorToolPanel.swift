import SwiftUI
import UIKit

// MARK: - EditorToolPanel

/// The expandable bottom panel that shows controls for the currently selected edit tool.
/// Slides up from the bottom with an animation when an edit tool is active.
struct EditorToolPanel: View {

    // MARK: - Properties

    @Bindable var viewModel: EditorViewModel
    @State private var panelDragOffset: CGFloat = 0

    // MARK: - Body

    var body: some View {
        if viewModel.activeEditTool != .none {
            VStack(spacing: 0) {
                dragHandle

                panelContainer
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DSSpacing.cornerLg, style: .continuous)
                    .fill(DSColors.cardBackground)
            )
            .overlay {
                RoundedRectangle(cornerRadius: DSSpacing.cornerLg, style: .continuous)
                    .strokeBorder(DSColors.border, lineWidth: 1)
            }
            .dsShadow(.card)
            .contentShape(RoundedRectangle(cornerRadius: DSSpacing.cornerLg, style: .continuous))
            .offset(y: panelDragOffset)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onChange(of: viewModel.activeEditTool) { _, _ in
                if panelDragOffset != 0 {
                    panelDragOffset = 0
                }
            }
        }
    }

    private var maximumPanelHeight: CGFloat {
        min(UIScreen.main.bounds.height * 0.5, 420)
    }

    @ViewBuilder
    private var panelContainer: some View {
        if usesScrollablePanel {
            ScrollView(.vertical, showsIndicators: true) {
                panelContent
                    .padding(.horizontal, DSSpacing.lg)
                    .padding(.bottom, DSSpacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)
            .frame(maxHeight: maximumPanelHeight)
        } else {
            panelContent
                .padding(.horizontal, DSSpacing.lg)
                .padding(.bottom, DSSpacing.lg)
        }
    }

    private var usesScrollablePanel: Bool {
        switch viewModel.activeEditTool {
        case .phrase, .template:
            return true
        case .none, .font, .position, .textSize, .textColor, .background:
            return false
        }
    }

    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(DSColors.textTertiary.opacity(0.7))
            .frame(width: 36, height: 5)
            .padding(.top, DSSpacing.sm)
            .padding(.bottom, DSSpacing.md)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(panelDismissGesture)
    }

    private var panelDismissGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                panelDragOffset = max(value.translation.height, 0)
            }
            .onEnded { value in
                let threshold = min(maximumPanelHeight * 0.22, 110)
                let dismissalTranslation = max(
                    value.translation.height,
                    value.predictedEndTranslation.height
                )

                if dismissalTranslation > threshold {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                        viewModel.activeEditTool = .none
                    }
                } else {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                        panelDragOffset = 0
                    }
                }
            }
    }

    // MARK: - Panel Content Router

    @ViewBuilder
    private var panelContent: some View {
        switch viewModel.activeEditTool {
        case .none:
            EmptyView()
        case .phrase:
            phrasePanel
        case .template:
            templatePanel
        case .font:
            fontPanel
        case .position:
            positionPanel
        case .textSize:
            textSizePanel
        case .textColor:
            textColorPanel
        case .background:
            backgroundPanel
        }
    }

    // MARK: - Phrase Panel

    private var phrasePanel: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            panelTitle("文言デザイン")

            PhraseTemplatePicker(
                templates: viewModel.availablePhraseTemplates,
                selectedTemplateId: viewModel.phraseTemplateId,
                isCustomMode: viewModel.customPhraseMode,
                countType: viewModel.event.countType,
                designTemplateType: viewModel.designTemplateType,
                eventName: viewModel.event.name,
                dayCount: viewModel.dayCount,
                favoriteTemplateIds: [],
                showsTitle: false,
                showsFavoriteControls: false,
                onSelect: { template in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.selectPhraseTemplate(template)
                    }
                },
                onToggleFavorite: { template in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.toggleFavoritePhraseTemplate(template)
                    }
                },
                onCustomTap: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.enableCustomPhraseMode()
                    }
                }
            )

            if viewModel.customPhraseMode {
                CustomPhraseEditor(
                    layoutMode: Binding(
                        get: { viewModel.layoutMode },
                        set: { viewModel.setLayoutMode($0) }
                    ),
                    customSingleLine: $viewModel.customSingleLine,
                    customLine1: $viewModel.customLine1,
                    customLine2: $viewModel.customLine2,
                    customLine3: $viewModel.customLine3,
                    eventName: viewModel.event.name,
                    dayCount: viewModel.dayCount
                )
                .transition(.opacity.combined(with: .move(edge: .top)))

                customPhraseTemplateActions
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if viewModel.layoutMode == .double {
                multiLineAlignmentPanel
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var customPhraseTemplateActions: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text(L10n.t("文言を登録"))
                .font(DSTypography.footnote)
                .foregroundStyle(DSColors.textSecondary)

            HStack(spacing: DSSpacing.md) {
                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    Text(
                        viewModel.isCurrentCustomPhraseRegistered
                            ? L10n.t("この文言は登録済みです")
                            : L10n.t("気に入った文言を一覧に追加")
                    )
                        .font(DSTypography.body)
                        .foregroundStyle(DSColors.textPrimary)

                    Text(
                        viewModel.isCurrentCustomPhraseRegistered
                            ? L10n.t("次回から文言デザイン一覧からすぐ選べます")
                            : L10n.t("登録すると次回からワンタップで呼び出せます")
                    )
                    .font(DSTypography.caption)
                    .foregroundStyle(DSColors.textTertiary)
                }

                Spacer(minLength: DSSpacing.sm)

                Button {
                    viewModel.toggleCurrentCustomPhraseTemplateRegistration()
                } label: {
                    HStack(spacing: DSSpacing.xs) {
                        Image(
                            systemName: viewModel.isCurrentCustomPhraseRegistered
                                ? "checkmark.circle.fill"
                                : "bookmark.fill"
                        )
                        .font(.system(size: 14, weight: .semibold))

                        Text(viewModel.isCurrentCustomPhraseRegistered ? L10n.t("登録済み") : L10n.t("登録する"))
                            .font(DSTypography.footnote)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(
                        viewModel.canSaveCurrentCustomPhraseTemplate || viewModel.isCurrentCustomPhraseRegistered
                            ? DSColors.accentDark
                            : DSColors.textTertiary
                    )
                    .padding(.horizontal, DSSpacing.md)
                    .padding(.vertical, DSSpacing.sm)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                viewModel.canSaveCurrentCustomPhraseTemplate || viewModel.isCurrentCustomPhraseRegistered
                                    ? DSColors.accentLight.opacity(0.45)
                                    : DSColors.secondaryBackground
                            )
                    )
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(
                                viewModel.canSaveCurrentCustomPhraseTemplate || viewModel.isCurrentCustomPhraseRegistered
                                    ? DSColors.accent.opacity(0.7)
                                    : DSColors.border,
                                lineWidth: 1
                            )
                    }
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canToggleCurrentCustomPhraseTemplateRegistration)
            }
            .padding(DSSpacing.md)
            .background(DSColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous)
                    .strokeBorder(DSColors.border, lineWidth: 1)
            }

            if viewModel.isCurrentCustomPhraseRegistered {
                Text(L10n.t("もう一度押すと登録を解除できます"))
                    .font(DSTypography.caption)
                    .foregroundStyle(DSColors.textTertiary)
            }
        }
    }

    private var multiLineAlignmentPanel: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text(L10n.t("文字揃え"))
                .font(DSTypography.footnote)
                .foregroundStyle(DSColors.textSecondary)

            HStack(spacing: DSSpacing.xs) {
                ForEach(TextAlignment.allCases) { alignment in
                    multiLineAlignmentButton(alignment)
                }
            }
        }
    }

    private func multiLineAlignmentButton(_ alignment: TextAlignment) -> some View {
        let isSelected = viewModel.effectiveTextAlignment == alignment

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.multiLineTextAlignmentOverride = alignment
            }
        } label: {
            VStack(spacing: DSSpacing.xxs) {
                Image(systemName: alignment.systemImage)
                    .font(.system(size: 16, weight: .semibold))

                Text(alignment.label)
                    .font(DSTypography.caption)
            }
            .foregroundStyle(isSelected ? DSColors.accentDark : DSColors.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous)
                    .fill(isSelected ? DSColors.accentLight.opacity(0.45) : DSColors.secondaryBackground)
            )
            .overlay {
                RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous)
                    .strokeBorder(
                        isSelected ? DSColors.accent : DSColors.border,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Template Panel

    private var templatePanel: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            panelTitle("テンプレート")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DSSpacing.md) {
                    ForEach(favoriteBuiltInTemplates) { template in
                        builtInTemplateCard(template)
                    }

                    ForEach(favoriteSavedEditorTemplates) { template in
                        savedTemplateCard(template)
                    }

                    if hasFavoriteTemplateSection && hasNonFavoriteTemplateSection {
                        favoritesDivider
                    }

                    ForEach(otherBuiltInTemplates) { template in
                        builtInTemplateCard(template)
                    }

                    if !otherBuiltInTemplates.isEmpty && !otherSavedEditorTemplates.isEmpty {
                        favoritesDivider
                    }

                    ForEach(otherSavedEditorTemplates) { template in
                        savedTemplateCard(template)
                    }
                }
                .padding(.horizontal, DSSpacing.xs)
                .padding(.vertical, DSSpacing.xs)
            }

            templateRegistrationBanner
        }
    }

    private var favoriteBuiltInTemplates: [DesignTemplate] {
        DesignTemplateStore.allTemplates.filter { viewModel.isFavoriteEditorTemplate($0) }
    }

    private var favoriteSavedEditorTemplates: [SavedEditorTemplate] {
        viewModel.availableSavedEditorTemplates.filter { viewModel.isFavoriteEditorTemplate($0) }
    }

    private var otherBuiltInTemplates: [DesignTemplate] {
        DesignTemplateStore.allTemplates.filter { !viewModel.isFavoriteEditorTemplate($0) }
    }

    private var otherSavedEditorTemplates: [SavedEditorTemplate] {
        viewModel.availableSavedEditorTemplates.filter { !viewModel.isFavoriteEditorTemplate($0) }
    }

    private var hasFavoriteTemplateSection: Bool {
        !favoriteBuiltInTemplates.isEmpty || !favoriteSavedEditorTemplates.isEmpty
    }

    private var hasNonFavoriteTemplateSection: Bool {
        !otherBuiltInTemplates.isEmpty || !otherSavedEditorTemplates.isEmpty
    }

    private var templateRegistrationBanner: some View {
        let isRegistered = viewModel.isCurrentEditorTemplateRegistered
        let canSave = viewModel.canSaveCurrentEditorTemplate
        let title = isRegistered
            ? L10n.t("現在の設定は登録済みです")
            : L10n.t("現在の設定をテンプレート登録")
        let message = isRegistered
            ? L10n.t("もう一度押すと登録を解除できます")
            : L10n.t("フォントや文言、位置、色までまとめて保存できます")
        let iconName = isRegistered
            ? "checkmark.circle.fill"
            : (canSave ? "square.and.arrow.down.fill" : "square.and.arrow.down")
        let iconForeground = isRegistered
            ? DSColors.success
            : (canSave ? DSColors.accentDark : DSColors.textTertiary)
        let iconBackground = isRegistered
            ? DSColors.success.opacity(0.14)
            : (canSave ? DSColors.accentLight.opacity(0.45) : DSColors.secondaryBackground)
        let iconBorder = isRegistered
            ? DSColors.success.opacity(0.35)
            : (canSave ? DSColors.accent.opacity(0.7) : DSColors.border)

        return HStack(spacing: DSSpacing.md) {
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DSColors.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

                Text(message)
                .font(.system(size: 10.5))
                .foregroundStyle(DSColors.textTertiary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)

            Spacer(minLength: DSSpacing.xxs)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.toggleCurrentEditorTemplateRegistration()
                }
            } label: {
                Label(title, systemImage: iconName)
                    .labelStyle(.iconOnly)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconForeground)
                    .frame(width: 44, height: 44)
                    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityHidden(true)
            }
            .accessibilityLabel(title)
            .accessibilityHint(message)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(iconBackground)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(iconBorder, lineWidth: 1)
            }
            .frame(width: 44, height: 44)
            .buttonStyle(.plain)
            .disabled(!viewModel.canToggleCurrentEditorTemplateRegistration)
        }
        .padding(.horizontal, DSSpacing.sm)
        .padding(.vertical, DSSpacing.sm)
        .background(DSColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous)
                .strokeBorder(DSColors.border, lineWidth: 1)
        }
    }

    private var favoritesDivider: some View {
        RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous)
            .fill(DSColors.border)
            .frame(width: 1, height: 72)
            .padding(.horizontal, DSSpacing.xxs)
    }

    private func builtInTemplateCard(_ template: DesignTemplate) -> some View {
        editorTemplateCard(
            title: template.name,
            badgeText: nil,
            designTemplate: template,
            fontPreset: template.defaultFontPreset,
            layoutMode: template.defaultPhraseTemplate(for: viewModel.event.countType).layoutMode,
            previewLines: viewModel.previewLines(for: template),
            previewPosition: previewNormalizedPosition(for: template.defaultTextPositionPreset),
            textAlignment: template.alignment,
            textColorHex: template.textColor,
            showBackgroundBand: template.showBackground,
            backgroundBandColorHex: template.showBackground ? template.backgroundColor : nil,
            isSelected: viewModel.isSelectedEditorTemplate(template),
            isFavorite: viewModel.isFavoriteEditorTemplate(template),
            favoriteAccessibilityLabel: viewModel.isFavoriteEditorTemplate(template)
                ? L10n.f("%@ をお気に入り解除", template.name)
                : L10n.f("%@ をお気に入り登録", template.name),
            onSelect: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.changeDesignTemplate(template.id)
                }
            },
            onToggleFavorite: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.toggleFavoriteEditorTemplate(template)
                }
            }
        )
    }

    private func savedTemplateCard(_ template: SavedEditorTemplate) -> some View {
        let designTemplate = DesignTemplateStore.template(for: template.designTemplateId)

        return editorTemplateCard(
            title: designTemplate.name,
            badgeText: L10n.t("保存済み"),
            designTemplate: designTemplate,
            fontPreset: template.fontPreset,
            layoutMode: template.layoutMode,
            previewLines: viewModel.previewLines(for: template),
            previewPosition: CGPoint(
                x: template.editorPreferences.textPositionX,
                y: template.editorPreferences.textPositionY
            ),
            textAlignment: template.editorPreferences.textAlignment ?? designTemplate.alignment,
            textColorHex: template.editorPreferences.textColorHex,
            showBackgroundBand: template.editorPreferences.showBackgroundBand,
            backgroundBandColorHex: template.editorPreferences.backgroundBandColorHex,
            isSelected: viewModel.isSelectedEditorTemplate(template),
            isFavorite: viewModel.isFavoriteEditorTemplate(template),
            favoriteAccessibilityLabel: viewModel.isFavoriteEditorTemplate(template)
                ? L10n.f("%@ をお気に入り解除", designTemplate.name)
                : L10n.f("%@ をお気に入り登録", designTemplate.name),
            onSelect: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.selectSavedEditorTemplate(template)
                }
            },
            onToggleFavorite: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.toggleFavoriteEditorTemplate(template)
                }
            }
        )
    }

    private func editorTemplateCard(
        title: String,
        badgeText: String?,
        designTemplate: DesignTemplate,
        fontPreset: FontPreset,
        layoutMode: LayoutMode,
        previewLines: [String],
        previewPosition: CGPoint,
        textAlignment: TextAlignment,
        textColorHex: String,
        showBackgroundBand: Bool,
        backgroundBandColorHex: String?,
        isSelected: Bool,
        isFavorite: Bool,
        favoriteAccessibilityLabel: String,
        onSelect: @escaping () -> Void,
        onToggleFavorite: @escaping () -> Void
    ) -> some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    templatePreviewSurface(
                        designTemplate: designTemplate,
                        fontPreset: fontPreset,
                        layoutMode: layoutMode,
                        previewLines: previewLines,
                        previewPosition: previewPosition,
                        textAlignment: textAlignment,
                        textColorHex: textColorHex,
                        showBackgroundBand: showBackgroundBand,
                        backgroundBandColorHex: backgroundBandColorHex
                    )

                    HStack(spacing: DSSpacing.xs) {
                        Text(title)
                            .font(DSTypography.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(DSColors.textPrimary)
                            .lineLimit(1)

                        Spacer(minLength: 0)

                        if let badgeText {
                            Text(badgeText)
                                .font(DSTypography.caption)
                                .foregroundStyle(DSColors.accentDark)
                                .padding(.horizontal, DSSpacing.xs)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(DSColors.accentLight.opacity(0.38))
                                )
                        }
                    }
                }
                .padding(DSSpacing.sm)
                .frame(width: 156, alignment: .leading)
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
            .buttonStyle(TemplateCardPressStyle())

            Button(action: onToggleFavorite) {
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
            .accessibilityLabel(favoriteAccessibilityLabel)
        }
    }

    private func templatePreviewSurface(
        designTemplate: DesignTemplate,
        fontPreset: FontPreset,
        layoutMode: LayoutMode,
        previewLines: [String],
        previewPosition: CGPoint,
        textAlignment: TextAlignment,
        textColorHex: String,
        showBackgroundBand: Bool,
        backgroundBandColorHex: String?
    ) -> some View {
        let lines = Array((previewLines.isEmpty ? [L10n.t("sample.preview.single")] : previewLines).prefix(3))
        let textColor = Color(hex: textColorHex)

        return GeometryReader { geo in
            let overlaySize = previewOverlaySize(
                lineCount: lines.count,
                layoutMode: layoutMode,
                showBackgroundBand: showBackgroundBand,
                containerSize: geo.size
            )
            let overlayPoint = previewOverlayPoint(
                normalizedPosition: previewPosition,
                overlaySize: overlaySize,
                containerSize: geo.size
            )

            ZStack {
                RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous)
                    .fill(previewGradient(for: designTemplate.id))

                previewOverlayContent(
                    lines: lines,
                    designTemplate: designTemplate,
                    fontPreset: fontPreset,
                    layoutMode: layoutMode,
                    textAlignment: textAlignment,
                    textColor: textColor,
                    showBackgroundBand: showBackgroundBand,
                    backgroundBandColorHex: backgroundBandColorHex
                )
                .frame(width: overlaySize.width, height: overlaySize.height)
                .position(x: overlayPoint.x, y: overlayPoint.y)
            }
        }
        .frame(height: 96)
        .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
    }

    @ViewBuilder
    private func previewOverlayContent(
        lines: [String],
        designTemplate: DesignTemplate,
        fontPreset: FontPreset,
        layoutMode: LayoutMode,
        textAlignment: TextAlignment,
        textColor: Color,
        showBackgroundBand: Bool,
        backgroundBandColorHex: String?
    ) -> some View {
        let content = previewTextStack(
            lines: lines,
            designTemplate: designTemplate,
            fontPreset: fontPreset,
            layoutMode: layoutMode,
            textAlignment: textAlignment,
            textColor: textColor
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: previewFrameAlignment(for: textAlignment))

        if showBackgroundBand {
            content
                .padding(.horizontal, DSSpacing.sm)
                .padding(.vertical, DSSpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous)
                        .fill(Color(hex: backgroundBandColorHex ?? designTemplate.backgroundColor))
                )
        } else {
            content
                .padding(.horizontal, DSSpacing.xs)
                .padding(.vertical, 4)
        }
    }

    private func previewTextStack(
        lines: [String],
        designTemplate: DesignTemplate,
        fontPreset: FontPreset,
        layoutMode: LayoutMode,
        textAlignment: TextAlignment,
        textColor: Color
    ) -> some View {
        let stackAlignment = previewStackAlignment(for: textAlignment)
        let frameAlignment = previewFrameAlignment(for: textAlignment)
        let textBlockAlignment = previewTextAlignment(for: textAlignment)

        return VStack(alignment: stackAlignment, spacing: 1) {
            ForEach(Array(lines.enumerated()), id: \.offset) { entry in
                let index = entry.offset
                let line = entry.element
                let isEmphasized = designTemplate.numberEmphasis && layoutMode == .double && index == 1
                let size = previewFontSize(
                    lineCount: lines.count,
                    index: index,
                    isEmphasized: isEmphasized
                )

                Text(line)
                    .font(
                        OverlayFontResolver.swiftUIFont(
                            preset: fontPreset,
                            size: size,
                            weight: isEmphasized ? .bold : fontWeight(designTemplate.fontWeight),
                            designTemplate: designTemplate,
                            text: line,
                            isEmphasized: isEmphasized
                        )
                    )
                    .tracking(
                        OverlayFontResolver.tracking(
                            preset: fontPreset,
                            size: size,
                            designTemplate: designTemplate,
                            text: line,
                            isEmphasized: isEmphasized
                        )
                    )
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
        .multilineTextAlignment(textBlockAlignment)
    }

    private func previewOverlaySize(
        lineCount: Int,
        layoutMode: LayoutMode,
        showBackgroundBand: Bool,
        containerSize: CGSize
    ) -> CGSize {
        let maxWidthRatio: CGFloat = showBackgroundBand ? 0.78 : 0.64
        let baseWidth: CGFloat = {
            switch layoutMode {
            case .single:
                return showBackgroundBand ? 108 : 92
            case .double:
                return showBackgroundBand ? 116 : 98
            }
        }()
        let width = min(baseWidth, containerSize.width * maxWidthRatio)
        let textHeight: CGFloat

        switch lineCount {
        case 0, 1:
            textHeight = 18
        case 2:
            textHeight = 28
        default:
            textHeight = 36
        }

        let paddingHeight: CGFloat = showBackgroundBand ? 18 : 10
        return CGSize(width: width, height: textHeight + paddingHeight)
    }

    private func previewOverlayPoint(
        normalizedPosition: CGPoint,
        overlaySize: CGSize,
        containerSize: CGSize
    ) -> CGPoint {
        let horizontalMargin = overlaySize.width / 2 + 6
        let verticalMargin = overlaySize.height / 2 + 6

        return CGPoint(
            x: clamp(
                CGFloat(normalizedPosition.x) * containerSize.width,
                min: horizontalMargin,
                max: containerSize.width - horizontalMargin
            ),
            y: clamp(
                CGFloat(normalizedPosition.y) * containerSize.height,
                min: verticalMargin,
                max: containerSize.height - verticalMargin
            )
        )
    }

    private func previewNormalizedPosition(for preset: TextPositionPreset) -> CGPoint {
        switch preset {
        case .topLeading:
            return CGPoint(x: 0.24, y: 0.18)
        case .topCenter:
            return CGPoint(x: 0.5, y: 0.18)
        case .topTrailing:
            return CGPoint(x: 0.76, y: 0.18)
        case .centerLeading:
            return CGPoint(x: 0.24, y: 0.5)
        case .center:
            return CGPoint(x: 0.5, y: 0.5)
        case .centerTrailing:
            return CGPoint(x: 0.76, y: 0.5)
        case .bottomLeading:
            return CGPoint(x: 0.24, y: 0.82)
        case .bottomCenter:
            return CGPoint(x: 0.5, y: 0.82)
        case .bottomTrailing:
            return CGPoint(x: 0.76, y: 0.82)
        }
    }

    private func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.min(maxValue, Swift.max(minValue, value))
    }

    private func previewFontSize(
        lineCount: Int,
        index: Int,
        isEmphasized: Bool
    ) -> CGFloat {
        switch lineCount {
        case 1:
            return 11.5
        case 2:
            if isEmphasized {
                return 13.5
            }
            return index == 0 ? 7.5 : 10.0
        default:
            if isEmphasized {
                return 11.0
            }
            return index == 1 ? 8.5 : 6.8
        }
    }

    private func previewGradient(for type: DesignTemplateType) -> LinearGradient {
        switch type {
        case .minimal:
            return LinearGradient(
                colors: [Color(hex: "5A5A5A"), Color(hex: "3A3A3A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .soft:
            return LinearGradient(
                colors: [Color(hex: "6B5B4F"), Color(hex: "4A3F38")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .film:
            return LinearGradient(
                colors: [Color(hex: "4A5A4F"), Color(hex: "2E3A32")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .poster:
            return LinearGradient(
                colors: [Color(hex: "3A3A50"), Color(hex: "1E1E2E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .classic:
            return LinearGradient(
                colors: [Color(hex: "56504A"), Color(hex: "2E2A27")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .diary:
            return LinearGradient(
                colors: [Color(hex: "A77D62"), Color(hex: "6B4F43")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .cleanLabel:
            return LinearGradient(
                colors: [Color(hex: "58626A"), Color(hex: "252A2F")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .memory:
            return LinearGradient(
                colors: [Color(hex: "5B4E42"), Color(hex: "29231F")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .milestone:
            return LinearGradient(
                colors: [Color(hex: "495A64"), Color(hex: "1D252B")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .airy:
            return LinearGradient(
                colors: [Color(hex: "DDE7DF"), Color(hex: "9DB7AA")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func previewStackAlignment(for alignment: TextAlignment) -> HorizontalAlignment {
        switch alignment {
        case .left:
            return .leading
        case .center:
            return .center
        case .right:
            return .trailing
        }
    }

    private func previewFrameAlignment(for alignment: TextAlignment) -> Alignment {
        switch alignment {
        case .left:
            return .leading
        case .center:
            return .center
        case .right:
            return .trailing
        }
    }

    private func previewTextAlignment(for alignment: TextAlignment) -> SwiftUI.TextAlignment {
        switch alignment {
        case .left:
            return .leading
        case .center:
            return .center
        case .right:
            return .trailing
        }
    }

    private struct TemplateCardPressStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
        }
    }

    // MARK: - Position Panel

    private var positionPanel: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            panelTitle("テキスト位置")

            LazyVGrid(columns: positionPanelColumns, spacing: DSSpacing.sm) {
                ForEach(TextPositionPreset.allCases) { preset in
                    positionButton(preset)
                }
            }
        }
    }

    private var positionPanelColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: DSSpacing.sm), count: 3)
    }

    private func positionButton(_ preset: TextPositionPreset) -> some View {
        let isSelected = viewModel.selectedTextPositionPreset == preset

        return Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.setTextPosition(preset)
            }
        } label: {
            Text(preset.label)
                .font(DSTypography.footnote)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? DSColors.accentDark : DSColors.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(
                    RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous)
                        .fill(isSelected ? DSColors.accentLight.opacity(0.5) : DSColors.secondaryBackground)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous)
                        .strokeBorder(
                            isSelected ? DSColors.accent : DSColors.border,
                            lineWidth: isSelected ? 1.5 : 1
                        )
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Font Panel

    private var fontPanel: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            panelTitle("フォント")

            LazyVGrid(columns: fontPanelColumns, alignment: .leading, spacing: DSSpacing.md) {
                ForEach(FontPreset.allCases) { preset in
                    fontCard(preset)
                }
            }
        }
    }

    private var fontPanelColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: DSSpacing.md, alignment: .top), count: 3)
    }

    private func fontCard(_ preset: FontPreset) -> some View {
        let isSelected = viewModel.fontPreset == preset

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.fontPreset = preset
            }
        } label: {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "565656"), Color(hex: "353535")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60)
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Anniv.")
                                .font(samplePreviewFont(for: preset, size: 9.5, weight: sampleFontWeight, text: "Anniv."))
                                .tracking(samplePreviewTracking(for: preset, size: 9.5, text: "Anniv."))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            Text(L10n.t("30日"))
                                .font(samplePreviewFont(for: preset, size: 16.5, weight: .bold, text: L10n.t("30日"), isEmphasized: true))
                                .tracking(samplePreviewTracking(for: preset, size: 16.5, text: L10n.t("30日"), isEmphasized: true))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .foregroundStyle(Color(hex: viewModel.currentDesignTemplate.textColor))
                        .padding(.horizontal, DSSpacing.sm)
                        .padding(.vertical, DSSpacing.xs)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous)
                            .strokeBorder(
                                isSelected ? DSColors.accent : DSColors.border,
                                lineWidth: isSelected ? 2.5 : 1
                            )
                    }

                Text(preset.displayName)
                    .font(DSTypography.caption)
                    .foregroundStyle(isSelected ? DSColors.textPrimary : DSColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DSSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous)
                    .fill(isSelected ? DSColors.secondaryBackground : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Text Size Panel

    private var textSizePanel: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            panelTitle("テキストサイズ")

            HStack(spacing: DSSpacing.md) {
                Image(systemName: "textformat.size.smaller")
                    .font(.system(size: 14))
                    .foregroundStyle(DSColors.textSecondary)

                Slider(
                    value: $viewModel.textScale,
                    in: 0.5...2.0,
                    step: 0.05
                )
                .tint(DSColors.accent)

                Image(systemName: "textformat.size.larger")
                    .font(.system(size: 18))
                    .foregroundStyle(DSColors.textSecondary)
            }

            // Display current scale
            Text("\(Int(viewModel.textScale * 100))%")
                .font(DSTypography.caption)
                .foregroundStyle(DSColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)

            Divider()

            if viewModel.layoutMode == .single {
                lineSizeSlider(
                    title: "1行目",
                    value: $viewModel.singleLineScaleMultiplier
                )
            } else {
                lineSizeSlider(title: "1行目", value: $viewModel.line1ScaleMultiplier)
                lineSizeSlider(title: "2行目", value: $viewModel.line2ScaleMultiplier)

                if viewModel.customPhraseMode || viewModel.displayText.multiLines.count >= 3 {
                    lineSizeSlider(title: "3行目", value: $viewModel.line3ScaleMultiplier)
                }
            }

            Toggle(L10n.t("数字のみ大きくする"), isOn: $viewModel.numbersOnlyLarge)
                .font(DSTypography.callout)
                .foregroundStyle(DSColors.textPrimary)
                .tint(DSColors.accent)
        }
    }

    private func lineSizeSlider(title: String, value: Binding<CGFloat>) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            HStack {
                Text(L10n.t(title))
                    .font(DSTypography.footnote)
                    .foregroundStyle(DSColors.textSecondary)

                Spacer()

                Text("\(Int(value.wrappedValue * 100))%")
                    .font(DSTypography.caption)
                    .foregroundStyle(DSColors.textTertiary)
            }

            Slider(value: value, in: 0.7...1.6, step: 0.05)
                .tint(DSColors.accent)
        }
    }

    // MARK: - Text Colour Panel

    private var textColorPanel: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            panelTitle("テキストカラー")

            HStack(spacing: DSSpacing.lg) {
                // Default (template colour)
                colorButton(
                    label: "デフォルト",
                    color: nil,
                    displayColor: Color(hex: viewModel.currentDesignTemplate.textColor)
                )

                colorButton(label: "白", color: .white, displayColor: .white)
                colorButton(label: "黒", color: .black, displayColor: .black)
                colorButton(label: "クリーム", color: Color(hex: "FFF8F0"), displayColor: Color(hex: "FFF8F0"))
                colorButton(label: "セージ", color: DSColors.accent, displayColor: DSColors.accent)
            }
        }
    }

    private func colorButton(label: String, color: Color?, displayColor: Color) -> some View {
        let isSelected = viewModel.textColorOverride == color
            && (color != nil || viewModel.textColorOverride == nil)

        // For the "default" option: selected when override is nil
        let isDefault = color == nil && viewModel.textColorOverride == nil

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.textColorOverride = color
            }
        } label: {
            VStack(spacing: DSSpacing.xs) {
                Circle()
                    .fill(displayColor)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                (isSelected || isDefault) ? DSColors.accent : DSColors.border,
                                lineWidth: (isSelected || isDefault) ? 2.5 : 1
                            )
                    }
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)

                Text(L10n.t(label))
                    .font(DSTypography.caption)
                    .foregroundStyle(DSColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Background Panel

    private var backgroundPanel: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            panelTitle("背景バンド")

            HStack {
                Text(L10n.t("テキスト背景を表示"))
                    .font(DSTypography.callout)
                    .foregroundStyle(DSColors.textPrimary)

                Spacer()

                Toggle("", isOn: $viewModel.showBackgroundBand)
                    .labelsHidden()
                    .tint(DSColors.accent)
            }
            .padding(.vertical, DSSpacing.xs)

            HStack(spacing: DSSpacing.lg) {
                backgroundColorButton(
                    label: "デフォルト",
                    hex: nil,
                    displayColor: Color(hex: viewModel.defaultBackgroundBandColorHex)
                )
                backgroundColorButton(label: "チャコール", hex: "#2C2C2ECC", displayColor: Color(hex: "#2C2C2ECC"))
                backgroundColorButton(label: "ホワイト", hex: "#FFFFFFCC", displayColor: Color(hex: "#FFFFFFCC"))
                backgroundColorButton(label: "セージ", hex: "#B8CFC4E6", displayColor: Color(hex: "#B8CFC4E6"))
                backgroundColorButton(label: "モカ", hex: "#8C7666D9", displayColor: Color(hex: "#8C7666D9"))
            }
            .opacity(viewModel.showBackgroundBand ? 1 : 0.45)
        }
    }

    private func backgroundColorButton(label: String, hex: String?, displayColor: Color) -> some View {
        let isSelected = viewModel.backgroundBandColorHexOverride == hex
            || (hex == nil && viewModel.backgroundBandColorHexOverride == nil)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.backgroundBandColorHexOverride = hex
                if !viewModel.showBackgroundBand {
                    viewModel.showBackgroundBand = true
                }
            }
        } label: {
            VStack(spacing: DSSpacing.xs) {
                RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous)
                    .fill(displayColor)
                    .frame(width: 34, height: 34)
                    .overlay {
                        RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous)
                            .strokeBorder(
                                isSelected ? DSColors.accent : DSColors.border,
                                lineWidth: isSelected ? 2.5 : 1
                            )
                    }

                Text(L10n.t(label))
                    .font(DSTypography.caption)
                    .foregroundStyle(DSColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func panelTitle(_ text: String) -> some View {
        Text(L10n.t(text))
            .font(DSTypography.headline)
            .foregroundStyle(DSColors.textPrimary)
    }

    private var sampleFontWeight: Font.Weight {
        fontWeight(viewModel.currentDesignTemplate.fontWeight)
    }

    private func samplePreviewFont(
        for preset: FontPreset,
        size: CGFloat,
        weight: Font.Weight,
        text: String,
        isEmphasized: Bool = false
    ) -> Font {
        OverlayFontResolver.swiftUIFont(
            preset: preset,
            size: size,
            weight: weight,
            designTemplate: viewModel.currentDesignTemplate,
            text: text,
            isEmphasized: isEmphasized
        )
    }

    private func samplePreviewTracking(
        for preset: FontPreset,
        size: CGFloat,
        text: String,
        isEmphasized: Bool = false
    ) -> CGFloat {
        OverlayFontResolver.tracking(
            preset: preset,
            size: size,
            designTemplate: viewModel.currentDesignTemplate,
            text: text,
            isEmphasized: isEmphasized
        )
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

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()
            EditorToolPanel(
                viewModel: EditorViewModel(
                    image: UIImage(),
                    event: Event(
                        name: "Preview",
                        baseDate: "2024-12-25"
                    )
                )
            )
        }
    }
}
