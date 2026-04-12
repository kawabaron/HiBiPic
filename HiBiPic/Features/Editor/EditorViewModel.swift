import Foundation
import Observation
import Photos
import SwiftUI
import UIKit

struct EditorOverlayLine: Identifiable, Equatable {
    let id: Int
    let text: String
    let scaleMultiplier: CGFloat
    let numbersOnlyLarge: Bool
}

struct EditorDisplayText: Equatable {
    let singleLine: String
    let singleLineScaleMultiplier: CGFloat
    let singleLineNumbersOnlyLarge: Bool
    let multiLines: [EditorOverlayLine]
}

// MARK: - EditorViewModel

/// Drives the editor screen: manages text overlay state, design template selection,
/// and final image rendering / saving.
@Observable
final class EditorViewModel {

    private static let favoritePhraseTemplatesSettingsKey = "favorite_phrase_template_ids"
    private static let savedCustomPhraseTemplatesSettingsKey = "saved_custom_phrase_templates"
    private static let favoriteEditorTemplateIdsSettingsKey = "favorite_editor_template_ids"
    private static let savedEditorTemplatesSettingsKey = "saved_editor_templates"

    // MARK: - Edit Tool

    enum EditTool: String, CaseIterable, Identifiable {
        case none
        case phrase
        case template
        case font
        case position
        case textSize
        case textColor
        case background

        var id: String { rawValue }

        var label: String {
            switch self {
            case .none:       return ""
            case .phrase:     return L10n.t("文言")
            case .template:   return L10n.t("テンプレート")
            case .font:       return L10n.t("フォント")
            case .position:   return L10n.t("位置")
            case .textSize:   return L10n.t("サイズ")
            case .textColor:  return L10n.t("カラー")
            case .background: return L10n.t("背景")
            }
        }

        var systemImage: String {
            switch self {
            case .none:       return ""
            case .phrase:     return "text.quote"
            case .template:   return "square.grid.2x2"
            case .font:       return "textformat"
            case .position:   return "plus.rectangle.on.rectangle"
            case .textSize:   return "textformat.size"
            case .textColor:  return "paintpalette"
            case .background: return "rectangle.on.rectangle"
            }
        }
    }

    // MARK: - Input

    var image: UIImage
    var event: Event

    // MARK: - Editor State

    var designTemplateType: DesignTemplateType {
        didSet {
            invalidateRenderedImage()
            refreshPresetPositionIfNeeded()
        }
    }
    var fontPreset: FontPreset {
        didSet {
            invalidateRenderedImage()
            refreshPresetPositionIfNeeded()
        }
    }
    var layoutMode: LayoutMode {
        didSet {
            syncSelectedSavedCustomTemplateIfNeeded()
            invalidateRenderedImage()
            refreshPresetPositionIfNeeded()
        }
    }
    var phraseTemplateId: String {
        didSet {
            invalidateRenderedImage()
            refreshPresetPositionIfNeeded()
        }
    }
    var customPhraseMode: Bool {
        didSet {
            invalidateRenderedImage()
            refreshPresetPositionIfNeeded()
        }
    }
    var customSingleLine: String {
        didSet {
            syncSelectedSavedCustomTemplateIfNeeded()
            invalidateRenderedImage()
            refreshPresetPositionIfNeeded()
        }
    }
    var customLine1: String {
        didSet {
            syncSelectedSavedCustomTemplateIfNeeded()
            invalidateRenderedImage()
            refreshPresetPositionIfNeeded()
        }
    }
    var customLine2: String {
        didSet {
            syncSelectedSavedCustomTemplateIfNeeded()
            invalidateRenderedImage()
            refreshPresetPositionIfNeeded()
        }
    }
    var customLine3: String {
        didSet {
            syncSelectedSavedCustomTemplateIfNeeded()
            invalidateRenderedImage()
            refreshPresetPositionIfNeeded()
        }
    }
    var singleLineScaleMultiplier: CGFloat {
        didSet {
            invalidateRenderedImage()
            refreshPresetPositionIfNeeded()
        }
    }
    var line1ScaleMultiplier: CGFloat {
        didSet {
            invalidateRenderedImage()
            refreshPresetPositionIfNeeded()
        }
    }
    var line2ScaleMultiplier: CGFloat {
        didSet {
            invalidateRenderedImage()
            refreshPresetPositionIfNeeded()
        }
    }
    var line3ScaleMultiplier: CGFloat {
        didSet {
            invalidateRenderedImage()
            refreshPresetPositionIfNeeded()
        }
    }
    var numbersOnlyLarge: Bool {
        didSet {
            invalidateRenderedImage()
            refreshPresetPositionIfNeeded()
        }
    }

    // MARK: - Overlay Adjustments

    /// Normalized 0-1 position of the text overlay center within the image bounds.
    var textPosition: CGPoint {
        didSet { invalidateRenderedImage() }
    }
    var selectedTextPositionPreset: TextPositionPreset?
    /// Font size multiplier (0.5 - 2.0).
    var textScale: CGFloat = 1.0 {
        didSet {
            invalidateRenderedImage()
            refreshPresetPositionIfNeeded()
        }
    }
    /// Optional colour override for the text. `nil` uses the template default.
    var textColorOverride: Color? {
        didSet { invalidateRenderedImage() }
    }
    /// Whether to show a semi-transparent background band behind the text.
    var showBackgroundBand: Bool {
        didSet { invalidateRenderedImage() }
    }
    /// Optional background band colour override as a hex string.
    var backgroundBandColorHexOverride: String? {
        didSet { invalidateRenderedImage() }
    }
    var multiLineTextAlignmentOverride: TextAlignment? {
        didSet {
            invalidateRenderedImage()
            refreshPresetPositionIfNeeded()
        }
    }

    // MARK: - UI State

    var isSaving: Bool = false
    var showSaveSuccess: Bool = false
    var showShareSheet: Bool = false
    var activeEditTool: EditTool = .none
    var saveErrorMessage: String?
    var favoritePhraseTemplateIds: Set<String>
    var savedCustomPhraseTemplates: [SavedCustomPhraseTemplate]
    var favoriteEditorTemplateIds: Set<String>
    var savedEditorTemplates: [SavedEditorTemplate]

    // MARK: - Computed

    /// The current design template object.
    var currentDesignTemplate: DesignTemplate {
        DesignTemplateStore.template(for: designTemplateType)
    }

    /// Day count calculated from the event.
    var dayCount: Int {
        DateCalculator.calculateDays(baseDate: event.baseDate, countType: event.countType)
    }

    var availablePhraseTemplates: [PhraseTemplate] {
        PhraseTemplateStore.templates(
            for: event.countType,
            userTemplates: savedCustomPhraseTemplates
        )
    }

    var availableSavedEditorTemplates: [SavedEditorTemplate] {
        savedEditorTemplates.filter { $0.countType == event.countType }
    }

    var effectiveTextAlignment: TextAlignment {
        layoutMode == .double
            ? (multiLineTextAlignmentOverride ?? currentDesignTemplate.alignment)
            : currentDesignTemplate.alignment
    }

    var isCurrentCustomPhraseRegistered: Bool {
        currentMatchingSavedCustomPhraseTemplate != nil
    }

    var canSaveCurrentCustomPhraseTemplate: Bool {
        currentCustomPhraseTemplateRecord != nil && !isCurrentCustomPhraseRegistered
    }

    var canToggleCurrentCustomPhraseTemplateRegistration: Bool {
        currentCustomPhraseTemplateRecord != nil
    }

    var isCurrentEditorTemplateRegistered: Bool {
        currentMatchingSavedEditorTemplate != nil
    }

    var canSaveCurrentEditorTemplate: Bool {
        currentEditorTemplateRecord != nil && !isCurrentEditorTemplateRegistered
    }

    var canToggleCurrentEditorTemplateRegistration: Bool {
        currentEditorTemplateRecord != nil
    }

    /// Generates the display text lines from the phrase template and day count.
    var displayText: EditorDisplayText {
        if customPhraseMode {
            let resolvedSingleLine = resolvedCustomTemplateText(customSingleLine)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let joinedCustomLines = [customLine1, customLine2, customLine3]
                .map(resolvedCustomTemplateText)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")

            return EditorDisplayText(
                singleLine: resolvedSingleLine.isEmpty
                    ? joinedCustomLines
                    : resolvedSingleLine,
                singleLineScaleMultiplier: singleLineScaleMultiplier,
                singleLineNumbersOnlyLarge: numbersOnlyLarge,
                multiLines: customOverlayLines()
            )
        }

        let store = PhraseTemplateStore()
        let template = resolvedPhraseTemplate(for: layoutMode)
        let result = adjustedGeneratedLines(
            store.generateLines(
                template: template,
                label: event.name,
                count: dayCount,
                layoutMode: layoutMode
            ),
            phraseTemplateId: template.id
        )

        if hasVisibleText(result, for: layoutMode) {
            return displayText(from: result)
        }

        let fallbackTemplate = fallbackPhraseTemplate(for: layoutMode)
        let fallback = adjustedGeneratedLines(
            store.generateLines(
                template: fallbackTemplate,
                label: event.name,
                count: dayCount,
                layoutMode: layoutMode
            ),
            phraseTemplateId: fallbackTemplate.id
        )
        return displayText(from: fallback)
    }

    private func adjustedGeneratedLines(
        _ lines: PhraseDisplayAdjuster.ResolvedLines,
        phraseTemplateId: String,
        designTemplateId: DesignTemplateType? = nil
    ) -> PhraseDisplayAdjuster.ResolvedLines {
        PhraseDisplayAdjuster.adjust(
            lines: lines,
            label: event.name,
            count: dayCount,
            countType: event.countType,
            designTemplateId: designTemplateId ?? designTemplateType,
            phraseTemplateId: phraseTemplateId
        )
    }

    /// The hex string of the effective text colour (override or template default).
    var effectiveTextColorHex: String? {
        guard let override = textColorOverride else { return nil }
        return override.toHex()
    }

    var resolvedTextColorHex: String {
        effectiveTextColorHex ?? currentDesignTemplate.textColor
    }

    var defaultBackgroundBandColorHex: String {
        let templateColor = currentDesignTemplate.backgroundColor
        if templateColor.replacingOccurrences(of: "#", with: "").uppercased() != "00000000" {
            return templateColor
        }

        return "#2C2C2ECC"
    }

    var effectiveBackgroundBandColorHex: String {
        backgroundBandColorHexOverride ?? defaultBackgroundBandColorHex
    }

    // MARK: - Rendered Image Cache

    /// The last rendered final image, kept for sharing after save.
    private var renderedImage: UIImage?
    private let eventRepository: EventRepositoryProtocol
    private let settingsRepository: SettingsRepositoryProtocol

    // MARK: - Init

    init(
        image: UIImage,
        event: Event,
        eventRepository: EventRepositoryProtocol = AppDependencies.shared.eventRepository,
        settingsRepository: SettingsRepositoryProtocol = AppDependencies.shared.settingsRepository
    ) {
        self.eventRepository = eventRepository
        self.settingsRepository = settingsRepository
        self.favoritePhraseTemplateIds = Self.loadFavoriteTemplateIds(from: settingsRepository)
        self.savedCustomPhraseTemplates = Self.loadSavedCustomPhraseTemplates(from: settingsRepository)
        self.favoriteEditorTemplateIds = Self.loadFavoriteEditorTemplateIds(from: settingsRepository)
        self.savedEditorTemplates = Self.loadSavedEditorTemplates(from: settingsRepository)
        self.image = image
        self.event = event

        let template = DesignTemplateStore.template(for: event.designTemplateId)

        // Initialise editor state from the event's saved preferences
        self.designTemplateType = event.designTemplateId
        self.fontPreset = event.fontPreset
        self.layoutMode = event.layoutMode
        self.phraseTemplateId = event.phraseTemplateId
        self.customPhraseMode = event.customPhraseMode
        self.customSingleLine = event.customSingleLine ?? ""
        self.customLine1 = event.customLine1 ?? ""
        self.customLine2 = event.customLine2 ?? ""
        self.customLine3 = event.customLine3 ?? ""
        self.singleLineScaleMultiplier = CGFloat(
            event.editorPreferences?.singleLineScale ?? Double(template.defaultSingleLineScaleMultiplier)
        )
        self.line1ScaleMultiplier = CGFloat(
            event.editorPreferences?.line1Scale ?? Double(template.defaultLine1ScaleMultiplier)
        )
        self.line2ScaleMultiplier = CGFloat(
            event.editorPreferences?.line2Scale ?? Double(template.defaultLine2ScaleMultiplier)
        )
        self.line3ScaleMultiplier = CGFloat(
            event.editorPreferences?.line3Scale ?? Double(template.defaultLine3ScaleMultiplier)
        )
        self.numbersOnlyLarge = event.editorPreferences?.numbersOnlyLarge ?? template.defaultNumbersOnlyLarge

        // Default text position is recalculated from the selected template preset below.
        self.textPosition = CGPoint(
            x: event.editorPreferences?.textPositionX ?? 0.5,
            y: event.editorPreferences?.textPositionY ?? 0.75
        )
        self.selectedTextPositionPreset = event.editorPreferences == nil ? template.defaultTextPositionPreset : nil
        self.textScale = CGFloat(event.editorPreferences?.textScale ?? Double(template.defaultTextScale))
        self.textColorOverride = event.editorPreferences.map { Color(hex: $0.textColorHex) }

        // Use the template's default for background band
        self.showBackgroundBand = event.editorPreferences?.showBackgroundBand ?? template.showBackground
        self.backgroundBandColorHexOverride = event.editorPreferences?.backgroundBandColorHex
        self.multiLineTextAlignmentOverride = event.editorPreferences?.textAlignment
        if event.editorPreferences == nil {
            refreshPresetPositionIfNeeded()
        }
        syncSelectedSavedCustomTemplateIfNeeded()
    }

    init(
        image: UIImage,
        event: Event,
        restoredRecipe: SavedImageEditRecipe,
        eventRepository: EventRepositoryProtocol = AppDependencies.shared.eventRepository,
        settingsRepository: SettingsRepositoryProtocol = AppDependencies.shared.settingsRepository
    ) {
        self.eventRepository = eventRepository
        self.settingsRepository = settingsRepository
        self.favoritePhraseTemplateIds = Self.loadFavoriteTemplateIds(from: settingsRepository)
        self.savedCustomPhraseTemplates = Self.loadSavedCustomPhraseTemplates(from: settingsRepository)
        self.favoriteEditorTemplateIds = Self.loadFavoriteEditorTemplateIds(from: settingsRepository)
        self.savedEditorTemplates = Self.loadSavedEditorTemplates(from: settingsRepository)
        self.image = image
        self.event = event
        self.designTemplateType = restoredRecipe.designTemplateId
        self.fontPreset = restoredRecipe.fontPreset
        self.layoutMode = restoredRecipe.layoutMode
        self.phraseTemplateId = restoredRecipe.phraseTemplateId
        self.customPhraseMode = true

        if restoredRecipe.wasCustomPhraseMode {
            self.customSingleLine = restoredRecipe.customSingleLine
            self.customLine1 = restoredRecipe.customLine1
            self.customLine2 = restoredRecipe.customLine2
            self.customLine3 = restoredRecipe.customLine3 ?? ""
        } else {
            self.customSingleLine = restoredRecipe.renderedSingleLine
            self.customLine1 = restoredRecipe.renderedLine1
            self.customLine2 = restoredRecipe.renderedLine2
            self.customLine3 = restoredRecipe.renderedLine3 ?? ""
        }
        self.singleLineScaleMultiplier = Self.resolvedLineScale(
            savedScale: restoredRecipe.singleLineScale,
            legacyIsLarge: restoredRecipe.customSingleLineIsLarge
        )
        self.line1ScaleMultiplier = Self.resolvedLineScale(
            savedScale: restoredRecipe.line1Scale,
            legacyIsLarge: restoredRecipe.customLine1IsLarge
        )
        self.line2ScaleMultiplier = Self.resolvedLineScale(
            savedScale: restoredRecipe.line2Scale,
            legacyIsLarge: restoredRecipe.customLine2IsLarge
        )
        self.line3ScaleMultiplier = Self.resolvedLineScale(
            savedScale: restoredRecipe.line3Scale,
            legacyIsLarge: restoredRecipe.customLine3IsLarge
        )
        self.numbersOnlyLarge = restoredRecipe.customNumbersOnlyLarge ?? false

        self.textPosition = CGPoint(
            x: restoredRecipe.textPositionX,
            y: restoredRecipe.textPositionY
        )
        self.selectedTextPositionPreset = nil
        self.textScale = CGFloat(restoredRecipe.textScale)
        self.textColorOverride = Color(hex: restoredRecipe.textColorHex)
        self.showBackgroundBand = restoredRecipe.showBackgroundBand
        self.backgroundBandColorHexOverride = restoredRecipe.backgroundBandColorHex
        self.multiLineTextAlignmentOverride = restoredRecipe.textAlignment
        syncSelectedSavedCustomTemplateIfNeeded()
    }

    // MARK: - Actions

    /// Switches to a new design template and resets overlay defaults.
    func changeDesignTemplate(_ type: DesignTemplateType) {
        let template = DesignTemplateStore.template(for: type)
        let phraseTemplate = template.defaultPhraseTemplate(for: event.countType)

        designTemplateType = type
        fontPreset = template.defaultFontPreset
        customPhraseMode = false
        phraseTemplateId = phraseTemplate.id
        layoutMode = phraseTemplate.layoutMode
        singleLineScaleMultiplier = template.defaultSingleLineScaleMultiplier
        line1ScaleMultiplier = template.defaultLine1ScaleMultiplier
        line2ScaleMultiplier = template.defaultLine2ScaleMultiplier
        line3ScaleMultiplier = template.defaultLine3ScaleMultiplier
        numbersOnlyLarge = template.defaultNumbersOnlyLarge
        textScale = template.defaultTextScale
        multiLineTextAlignmentOverride = nil
        showBackgroundBand = template.showBackground
        backgroundBandColorHexOverride = nil
        selectedTextPositionPreset = template.defaultTextPositionPreset

        // Clear overrides so the selected template's colour and alignment apply.
        textColorOverride = nil

        refreshPresetPositionIfNeeded()
    }

    /// Toggles between single-line and double-line layout.
    func toggleLayoutMode() {
        setLayoutMode((layoutMode == .single) ? .double : .single)
    }

    /// Applies a new layout mode and keeps the phrase template in sync.
    func setLayoutMode(_ mode: LayoutMode) {
        layoutMode = mode

        guard !customPhraseMode else { return }

        let template = resolvedPhraseTemplate(for: mode)
        if phraseTemplateId != template.id {
            phraseTemplateId = template.id
        }
    }

    func selectPhraseTemplate(_ template: PhraseTemplate) {
        if template.isUserSaved {
            applySavedCustomPhraseTemplate(template)
            return
        }

        customPhraseMode = false
        phraseTemplateId = template.id
        setLayoutMode(template.layoutMode)
    }

    func enableCustomPhraseMode() {
        if savedCustomPhraseTemplates.contains(where: { $0.id == phraseTemplateId }) {
            phraseTemplateId = ""
        }

        let current = displayText

        if customSingleLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           customLine1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           customLine2.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           customLine3.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            customSingleLine = current.singleLine
            customLine1 = current.multiLines[safe: 0]?.text ?? ""
            customLine2 = current.multiLines[safe: 1]?.text ?? ""
            customLine3 = current.multiLines[safe: 2]?.text ?? ""
        }

        customPhraseMode = true
    }

    func setTextPosition(_ preset: TextPositionPreset) {
        selectedTextPositionPreset = preset
        refreshPresetPositionIfNeeded()
    }

    func updateTextPositionManually(_ position: CGPoint) {
        selectedTextPositionPreset = nil
        textPosition = position
    }

    func isFavoritePhraseTemplate(_ template: PhraseTemplate) -> Bool {
        favoritePhraseTemplateIds.contains(template.id)
    }

    func toggleFavoritePhraseTemplate(_ template: PhraseTemplate) {
        if favoritePhraseTemplateIds.contains(template.id) {
            favoritePhraseTemplateIds.remove(template.id)
        } else {
            favoritePhraseTemplateIds.insert(template.id)
        }

        persistFavoriteTemplateIds()
    }

    func isFavoriteEditorTemplate(_ template: DesignTemplate) -> Bool {
        favoriteEditorTemplateIds.contains(Self.favoriteEditorTemplateID(for: template.id))
    }

    func isFavoriteEditorTemplate(_ template: SavedEditorTemplate) -> Bool {
        favoriteEditorTemplateIds.contains(template.favoriteId)
    }

    func isSelectedEditorTemplate(_ template: DesignTemplate) -> Bool {
        currentMatchingSavedEditorTemplate == nil && designTemplateType == template.id
    }

    func isSelectedEditorTemplate(_ template: SavedEditorTemplate) -> Bool {
        currentMatchingSavedEditorTemplate?.id == template.id
    }

    func toggleFavoriteEditorTemplate(_ template: DesignTemplate) {
        toggleFavoriteEditorTemplate(withID: Self.favoriteEditorTemplateID(for: template.id))
    }

    func toggleFavoriteEditorTemplate(_ template: SavedEditorTemplate) {
        toggleFavoriteEditorTemplate(withID: template.favoriteId)
    }

    func toggleCurrentCustomPhraseTemplateRegistration() {
        guard let currentTemplate = currentCustomPhraseTemplateRecord else { return }

        if let existing = matchingSavedCustomPhraseTemplate(for: currentTemplate) {
            savedCustomPhraseTemplates.removeAll { $0.id == existing.id }
            favoritePhraseTemplateIds.remove(existing.id)
            if phraseTemplateId == existing.id {
                phraseTemplateId = ""
            }
            persistSavedCustomPhraseTemplates()
            persistFavoriteTemplateIds()
            return
        }

        savedCustomPhraseTemplates.insert(currentTemplate, at: 0)
        phraseTemplateId = currentTemplate.id
        persistSavedCustomPhraseTemplates()
    }

    func toggleCurrentEditorTemplateRegistration() {
        guard let currentTemplate = currentEditorTemplateRecord else { return }

        if let existing = matchingSavedEditorTemplate(for: currentTemplate) {
            savedEditorTemplates.removeAll { $0.id == existing.id }
            favoriteEditorTemplateIds.remove(existing.favoriteId)
            persistSavedEditorTemplates()
            persistFavoriteEditorTemplateIds()
            return
        }

        savedEditorTemplates.insert(currentTemplate, at: 0)
        persistSavedEditorTemplates()
    }

    func selectSavedEditorTemplate(_ template: SavedEditorTemplate) {
        let preferences = template.editorPreferences

        designTemplateType = template.designTemplateId
        fontPreset = template.fontPreset
        layoutMode = template.layoutMode
        customPhraseMode = template.customPhraseMode

        if template.customPhraseMode {
            phraseTemplateId = ""
            customSingleLine = template.customSingleLine
            customLine1 = template.customLine1
            customLine2 = template.customLine2
            customLine3 = template.customLine3
        } else {
            phraseTemplateId = template.phraseTemplateId
            customSingleLine = ""
            customLine1 = ""
            customLine2 = ""
            customLine3 = ""
        }

        singleLineScaleMultiplier = CGFloat(preferences.singleLineScale)
        line1ScaleMultiplier = CGFloat(preferences.line1Scale)
        line2ScaleMultiplier = CGFloat(preferences.line2Scale)
        line3ScaleMultiplier = CGFloat(preferences.line3Scale)
        numbersOnlyLarge = preferences.numbersOnlyLarge
        selectedTextPositionPreset = nil
        textPosition = CGPoint(x: preferences.textPositionX, y: preferences.textPositionY)
        textScale = CGFloat(preferences.textScale)
        textColorOverride = Color(hex: preferences.textColorHex)
        showBackgroundBand = preferences.showBackgroundBand
        backgroundBandColorHexOverride = preferences.backgroundBandColorHex
        multiLineTextAlignmentOverride = preferences.textAlignment
        syncSelectedSavedCustomTemplateIfNeeded()
    }

    func previewLines(for designTemplate: DesignTemplate) -> [String] {
        let phraseTemplate = designTemplate.defaultPhraseTemplate(for: event.countType)
        return previewLines(
            designTemplateId: designTemplate.id,
            layoutMode: phraseTemplate.layoutMode,
            phraseTemplateId: phraseTemplate.id,
            customPhraseMode: false,
            customSingleLine: "",
            customLine1: "",
            customLine2: "",
            customLine3: ""
        )
    }

    func previewLines(for template: SavedEditorTemplate) -> [String] {
        previewLines(
            designTemplateId: template.designTemplateId,
            layoutMode: template.layoutMode,
            phraseTemplateId: template.phraseTemplateId,
            customPhraseMode: template.customPhraseMode,
            customSingleLine: template.customSingleLine,
            customLine1: template.customLine1,
            customLine2: template.customLine2,
            customLine3: template.customLine3
        )
    }

    /// Selects an edit tool, or deselects it if it is already active.
    func selectTool(_ tool: EditTool) {
        if activeEditTool == tool {
            activeEditTool = .none
        } else {
            activeEditTool = tool
        }
    }

    // MARK: - Rendering & Saving

    /// Renders the final composited image at full resolution.
    private func renderFinalImage() -> UIImage? {
        let text = displayText
        return EditorImageRenderer.renderFinalImage(
            baseImage: image,
            designTemplate: currentDesignTemplate,
            fontPreset: fontPreset,
            layoutMode: layoutMode,
            displayText: text,
            textPosition: textPosition,
            textScale: textScale,
            textAlignment: effectiveTextAlignment,
            textColorHex: effectiveTextColorHex,
            showBackground: showBackgroundBand,
            backgroundColorHex: effectiveBackgroundBandColorHex
        )
    }

    /// Renders the final image and saves it to the app's internal library.
    /// Returns `true` on success.
    @MainActor
    func save() async -> Bool {
        guard !isSaving else { return false }

        isSaving = true
        saveErrorMessage = nil
        showSaveSuccess = false

        // Let SwiftUI commit the saving overlay before the synchronous render/write work begins.
        try? await Task.sleep(for: .milliseconds(120))
        defer { isSaving = false }

        guard let finalImage = renderFinalImage() else {
            saveErrorMessage = L10n.t("画像の生成に失敗しました")
            return false
        }

        renderedImage = finalImage

        // Save to app's internal library
        let fileName = "\(UUID().uuidString).jpg"
        let originalFileName = "\(UUID().uuidString)-original.jpg"
        let fileSaved = ImageFileStorage.shared.saveImage(finalImage, fileName: fileName)
        guard fileSaved else {
            saveErrorMessage = L10n.t("画像の保存に失敗しました")
            return false
        }

        ImageFileStorage.shared.saveThumbnail(finalImage, fileName: fileName)

        let originalSaved = ImageFileStorage.shared.saveOriginalImage(image, fileName: originalFileName)
        guard originalSaved else {
            ImageFileStorage.shared.deleteImage(fileName: fileName)
            saveErrorMessage = L10n.t("編集用データの保存に失敗しました")
            return false
        }

        let savedImage = SavedImage(
            eventId: event.id,
            fileName: fileName,
            originalFileName: originalFileName,
            editRecipe: currentEditRecipe()
        )
        do {
            try AppDependencies.shared.savedImageRepository.create(savedImage)
        } catch {
            ImageFileStorage.shared.deleteImage(fileName: fileName)
            ImageFileStorage.shared.deleteOriginalImage(fileName: originalFileName)
            saveErrorMessage = L10n.t("画像データの保存に失敗しました")
            return false
        }

        persistCurrentEditorDefaultsToEvent()

        showSaveSuccess = true
        return true
    }

    /// Saves the rendered image to the iPhone's photo library.
    /// Called from SaveSuccessView.
    @MainActor
    func saveRenderedToPhotoLibrary() async -> Bool {
        guard let image = renderedImage else { return false }
        return await saveToPhotoLibrary(image)
    }

    /// Returns the rendered image for sharing. If not yet rendered, renders on-demand.
    func shareImage() -> UIImage {
        if let cached = renderedImage {
            return cached
        }
        let final = renderFinalImage() ?? image
        renderedImage = final
        return final
    }

    // MARK: - Photo Library

    private func saveToPhotoLibrary(_ image: UIImage) async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            return false
        }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                request.creationDate = Date()
            } completionHandler: { success, _ in
                continuation.resume(returning: success)
            }
        }
    }

    private func invalidateRenderedImage() {
        renderedImage = nil
    }

    private func currentEditRecipe() -> SavedImageEditRecipe {
        let text = displayText

        return SavedImageEditRecipe(
            eventName: event.name,
            eventBaseDate: event.baseDate,
            eventCountType: event.countType,
            designTemplateId: designTemplateType,
            fontPreset: fontPreset,
            layoutMode: layoutMode,
            phraseTemplateId: phraseTemplateId,
            wasCustomPhraseMode: customPhraseMode,
            customSingleLine: customSingleLine,
            customLine1: customLine1,
            customLine2: customLine2,
            customLine3: customLine3,
            singleLineScale: Double(singleLineScaleMultiplier),
            line1Scale: Double(line1ScaleMultiplier),
            line2Scale: Double(line2ScaleMultiplier),
            line3Scale: Double(line3ScaleMultiplier),
            customSingleLineIsLarge: nil,
            customLine1IsLarge: nil,
            customLine2IsLarge: nil,
            customLine3IsLarge: nil,
            customNumbersOnlyLarge: numbersOnlyLarge,
            renderedSingleLine: text.singleLine,
            renderedLine1: text.multiLines[safe: 0]?.text ?? "",
            renderedLine2: text.multiLines[safe: 1]?.text ?? "",
            renderedLine3: text.multiLines[safe: 2]?.text,
            textPositionX: Double(textPosition.x),
            textPositionY: Double(textPosition.y),
            textScale: Double(textScale),
            textColorHex: resolvedTextColorHex,
            showBackgroundBand: showBackgroundBand,
            backgroundBandColorHex: showBackgroundBand ? effectiveBackgroundBandColorHex : nil,
            textAlignment: multiLineTextAlignmentOverride
        )
    }

    private func refreshPresetPositionIfNeeded() {
        guard let preset = selectedTextPositionPreset else { return }
        textPosition = normalizedTextPosition(for: preset)
    }

    private func normalizedTextPosition(for preset: TextPositionPreset) -> CGPoint {
        let canvasSize = effectiveCanvasSize()
        let text = displayText
        let overlaySize = EditorTextLayout.overlaySize(
            designTemplate: currentDesignTemplate,
            fontPreset: fontPreset,
            layoutMode: layoutMode,
            displayText: text,
            textScale: textScale,
            textAlignment: effectiveTextAlignment,
            canvasSize: canvasSize
        )

        let horizontalMargin = max(canvasSize.width * 0.05, 16)
        let topMargin = max(canvasSize.height * 0.035, 18)
        let bottomMargin = max(canvasSize.height * 0.045, 22)
        let availableHalfWidth = max((canvasSize.width - horizontalMargin * 2) / 2, 0)
        let availableHalfHeight = max((canvasSize.height - topMargin - bottomMargin) / 2, 0)
        let halfWidth = min(overlaySize.width / 2, availableHalfWidth)
        let halfHeight = min(overlaySize.height / 2, availableHalfHeight)

        let leadingX = clamp((horizontalMargin + halfWidth) / canvasSize.width, min: 0.05, max: 0.95)
        let trailingX = clamp(
            1 - ((horizontalMargin + halfWidth) / canvasSize.width),
            min: 0.05,
            max: 0.95
        )
        let topY = clamp((topMargin + halfHeight) / canvasSize.height, min: 0.08, max: 0.92)
        let bottomY = clamp(
            1 - ((bottomMargin + halfHeight) / canvasSize.height),
            min: 0.08,
            max: 0.92
        )

        switch preset {
        case .topLeading:
            return CGPoint(x: leadingX, y: topY)
        case .topCenter:
            return CGPoint(x: 0.5, y: topY)
        case .topTrailing:
            return CGPoint(x: trailingX, y: topY)
        case .centerLeading:
            return CGPoint(x: leadingX, y: 0.5)
        case .center:
            return CGPoint(x: 0.5, y: 0.5)
        case .centerTrailing:
            return CGPoint(x: trailingX, y: 0.5)
        case .bottomLeading:
            return CGPoint(x: leadingX, y: bottomY)
        case .bottomCenter:
            return CGPoint(x: 0.5, y: bottomY)
        case .bottomTrailing:
            return CGPoint(x: trailingX, y: bottomY)
        }
    }

    private func effectiveCanvasSize() -> CGSize {
        let canvasSize = EditorImageGeometry(image: image).canvasSize
        guard canvasSize.width > 0, canvasSize.height > 0 else {
            return CGSize(width: 1080, height: 1080)
        }
        return canvasSize
    }

    private func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.min(maxValue, Swift.max(minValue, value))
    }

    private func resolvedPhraseTemplate(for layoutMode: LayoutMode) -> PhraseTemplate {
        if let current = PhraseTemplateStore.allTemplates.first(where: {
            $0.id == phraseTemplateId && $0.layoutMode == layoutMode
        }) {
            return current
        }

        return fallbackPhraseTemplate(for: layoutMode)
    }

    private func fallbackPhraseTemplate(for layoutMode: LayoutMode) -> PhraseTemplate {
        let candidates = PhraseTemplateStore.templates(for: event.countType)
            .filter { $0.layoutMode == layoutMode }

        if let recommended = candidates.first(where: { $0.isRecommended }) {
            return recommended
        }

        if let first = candidates.first {
            return first
        }

        return PhraseTemplateStore.defaultTemplate(for: event.countType)
    }

    private func hasVisibleText(
        _ text: (singleLine: String, line1: String, line2: String, line3: String),
        for layoutMode: LayoutMode
    ) -> Bool {
        switch layoutMode {
        case .single:
            return !text.singleLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .double:
            let line1 = text.line1.trimmingCharacters(in: .whitespacesAndNewlines)
            let line2 = text.line2.trimmingCharacters(in: .whitespacesAndNewlines)
            let line3 = text.line3.trimmingCharacters(in: .whitespacesAndNewlines)
            return !line1.isEmpty || !line2.isEmpty || !line3.isEmpty
        }
    }

    private func displayText(
        from text: (singleLine: String, line1: String, line2: String, line3: String)
    ) -> EditorDisplayText {
        EditorDisplayText(
            singleLine: text.singleLine,
            singleLineScaleMultiplier: singleLineScaleMultiplier,
            singleLineNumbersOnlyLarge: numbersOnlyLarge,
            multiLines: [
                EditorOverlayLine(
                    id: 0,
                    text: text.line1,
                    scaleMultiplier: line1ScaleMultiplier,
                    numbersOnlyLarge: numbersOnlyLarge
                ),
                EditorOverlayLine(
                    id: 1,
                    text: text.line2,
                    scaleMultiplier: line2ScaleMultiplier,
                    numbersOnlyLarge: numbersOnlyLarge
                ),
                EditorOverlayLine(
                    id: 2,
                    text: text.line3,
                    scaleMultiplier: line3ScaleMultiplier,
                    numbersOnlyLarge: numbersOnlyLarge
                ),
            ].filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        )
    }

    private func customOverlayLines() -> [EditorOverlayLine] {
        [
            makeCustomOverlayLine(id: 0, text: customLine1, scaleMultiplier: line1ScaleMultiplier),
            makeCustomOverlayLine(id: 1, text: customLine2, scaleMultiplier: line2ScaleMultiplier),
            makeCustomOverlayLine(id: 2, text: customLine3, scaleMultiplier: line3ScaleMultiplier),
        ].compactMap { $0 }
    }

    private func makeCustomOverlayLine(
        id: Int,
        text: String,
        scaleMultiplier: CGFloat
    ) -> EditorOverlayLine? {
        let resolvedText = resolvedCustomTemplateText(text)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !resolvedText.isEmpty else { return nil }
        return EditorOverlayLine(
            id: id,
            text: resolvedText,
            scaleMultiplier: scaleMultiplier,
            numbersOnlyLarge: numbersOnlyLarge
        )
    }

    private func resolvedCustomTemplateText(_ template: String) -> String {
        PlaceholderTextResolver.resolve(
            template: template,
            label: event.name,
            count: dayCount
        )
    }

    private func currentEventEditorPreferences() -> EventEditorPreferences {
        EventEditorPreferences(
            textPositionX: Double(textPosition.x),
            textPositionY: Double(textPosition.y),
            textScale: Double(textScale),
            textColorHex: resolvedTextColorHex,
            showBackgroundBand: showBackgroundBand,
            backgroundBandColorHex: showBackgroundBand ? effectiveBackgroundBandColorHex : nil,
            textAlignment: multiLineTextAlignmentOverride,
            singleLineScale: Double(singleLineScaleMultiplier),
            line1Scale: Double(line1ScaleMultiplier),
            line2Scale: Double(line2ScaleMultiplier),
            line3Scale: Double(line3ScaleMultiplier),
            numbersOnlyLarge: numbersOnlyLarge
        )
    }

    private var currentMatchingSavedCustomPhraseTemplate: SavedCustomPhraseTemplate? {
        guard let currentTemplate = currentCustomPhraseTemplateRecord else { return nil }
        return matchingSavedCustomPhraseTemplate(for: currentTemplate)
    }

    private var currentMatchingSavedEditorTemplate: SavedEditorTemplate? {
        guard let currentTemplate = currentEditorTemplateRecord else { return nil }
        return matchingSavedEditorTemplate(for: currentTemplate)
    }

    private var currentCustomPhraseTemplateRecord: SavedCustomPhraseTemplate? {
        guard customPhraseMode else { return nil }

        let singleLineTemplate = layoutMode == .single ? customSingleLine.trimmedForPhraseStorage : ""
        let line1Template = layoutMode == .double ? customLine1.trimmedForPhraseStorage : ""
        let line2Template = layoutMode == .double ? customLine2.trimmedForPhraseStorage : ""
        let line3Template = layoutMode == .double ? customLine3.trimmedForPhraseStorage : ""

        let hasVisibleText: Bool
        if layoutMode == .single {
            hasVisibleText = !singleLineTemplate.isEmpty
        } else {
            hasVisibleText = !line1Template.isEmpty || !line2Template.isEmpty || !line3Template.isEmpty
        }

        guard hasVisibleText else { return nil }

        return SavedCustomPhraseTemplate(
            id: "custom_\(UUID().uuidString)",
            countType: event.countType,
            layoutMode: layoutMode,
            singleLineTemplate: singleLineTemplate,
            line1Template: line1Template,
            line2Template: line2Template,
            line3Template: line3Template,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
    }

    private var currentEditorTemplateRecord: SavedEditorTemplate? {
        SavedEditorTemplate(
            id: "editor_template_\(UUID().uuidString)",
            countType: event.countType,
            designTemplateId: designTemplateType,
            fontPreset: fontPreset,
            layoutMode: layoutMode,
            phraseTemplateId: customPhraseMode ? "" : resolvedPhraseTemplate(for: layoutMode).id,
            customPhraseMode: customPhraseMode,
            customSingleLine: customPhraseMode ? customSingleLine.trimmedForPhraseStorage : "",
            customLine1: customPhraseMode ? customLine1.trimmedForPhraseStorage : "",
            customLine2: customPhraseMode ? customLine2.trimmedForPhraseStorage : "",
            customLine3: customPhraseMode ? customLine3.trimmedForPhraseStorage : "",
            editorPreferences: currentEventEditorPreferences(),
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
    }

    private func matchingSavedCustomPhraseTemplate(
        for template: SavedCustomPhraseTemplate
    ) -> SavedCustomPhraseTemplate? {
        savedCustomPhraseTemplates.first {
            $0.matches(
                countType: template.countType,
                layoutMode: template.layoutMode,
                singleLineTemplate: template.singleLineTemplate,
                line1Template: template.line1Template,
                line2Template: template.line2Template,
                line3Template: template.line3Template
            )
        }
    }

    private func matchingSavedEditorTemplate(
        for template: SavedEditorTemplate
    ) -> SavedEditorTemplate? {
        savedEditorTemplates.first { $0.matches(template) }
    }

    private func syncSelectedSavedCustomTemplateIfNeeded() {
        guard customPhraseMode else { return }

        if let matchingTemplate = currentMatchingSavedCustomPhraseTemplate {
            if phraseTemplateId != matchingTemplate.id {
                phraseTemplateId = matchingTemplate.id
            }
            return
        }

        if savedCustomPhraseTemplates.contains(where: { $0.id == phraseTemplateId }) {
            phraseTemplateId = ""
        }
    }

    private func applySavedCustomPhraseTemplate(_ template: PhraseTemplate) {
        customPhraseMode = true
        layoutMode = template.layoutMode
        customSingleLine = template.layoutMode == .single ? template.singleLineTemplate : ""
        customLine1 = template.layoutMode == .double ? template.line1Template : ""
        customLine2 = template.layoutMode == .double ? template.line2Template : ""
        customLine3 = template.layoutMode == .double ? template.line3Template : ""
        phraseTemplateId = template.id
    }

    private func previewLines(
        designTemplateId: DesignTemplateType,
        layoutMode: LayoutMode,
        phraseTemplateId: String,
        customPhraseMode: Bool,
        customSingleLine: String,
        customLine1: String,
        customLine2: String,
        customLine3: String
    ) -> [String] {
        if customPhraseMode {
            if layoutMode == .single {
                let singleLine = resolvedCustomTemplateText(customSingleLine)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return singleLine.isEmpty ? [] : [singleLine]
            }

            return [customLine1, customLine2, customLine3]
                .map(resolvedCustomTemplateText)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }

        let phraseTemplate = PhraseTemplateStore.allTemplates.first(where: {
            $0.id == phraseTemplateId && $0.layoutMode == layoutMode
        }) ?? fallbackPhraseTemplate(for: layoutMode)

        let generated = adjustedGeneratedLines(
            PhraseTemplateStore().generateLines(
                template: phraseTemplate,
                label: event.name,
                count: dayCount,
                layoutMode: layoutMode
            ),
            phraseTemplateId: phraseTemplate.id,
            designTemplateId: designTemplateId
        )

        if layoutMode == .single {
            let singleLine = generated.singleLine.trimmingCharacters(in: .whitespacesAndNewlines)
            return singleLine.isEmpty ? [] : [singleLine]
        }

        return [generated.line1, generated.line2, generated.line3]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func persistCurrentEditorDefaultsToEvent() {
        var updatedEvent = event
        updatedEvent.designTemplateId = designTemplateType
        updatedEvent.fontPreset = fontPreset
        updatedEvent.layoutMode = layoutMode
        updatedEvent.phraseTemplateId = phraseTemplateId
        updatedEvent.customPhraseMode = customPhraseMode
        updatedEvent.customSingleLine = customPhraseMode ? customSingleLine.nilIfBlank : nil
        updatedEvent.customLine1 = customPhraseMode ? customLine1.nilIfBlank : nil
        updatedEvent.customLine2 = customPhraseMode ? customLine2.nilIfBlank : nil
        updatedEvent.customLine3 = customPhraseMode ? customLine3.nilIfBlank : nil
        updatedEvent.editorPreferences = currentEventEditorPreferences()
        updatedEvent.updatedAt = ISO8601DateFormatter().string(from: Date())

        do {
            try eventRepository.update(updatedEvent)
            event = updatedEvent
        } catch {
            // The image itself is already saved; keep this as a non-fatal failure.
        }
    }

    private func persistFavoriteTemplateIds() {
        let favoriteIds = favoritePhraseTemplateIds.sorted()
        guard let data = try? JSONEncoder().encode(favoriteIds),
              let json = String(data: data, encoding: .utf8)
        else {
            return
        }

        try? settingsRepository.setValue(
            json,
            forKey: Self.favoritePhraseTemplatesSettingsKey
        )
    }

    private func persistSavedCustomPhraseTemplates() {
        guard let data = try? JSONEncoder().encode(savedCustomPhraseTemplates),
              let json = String(data: data, encoding: .utf8)
        else {
            return
        }

        try? settingsRepository.setValue(
            json,
            forKey: Self.savedCustomPhraseTemplatesSettingsKey
        )
    }

    private func toggleFavoriteEditorTemplate(withID id: String) {
        if favoriteEditorTemplateIds.contains(id) {
            favoriteEditorTemplateIds.remove(id)
        } else {
            favoriteEditorTemplateIds.insert(id)
        }

        persistFavoriteEditorTemplateIds()
    }

    private func persistFavoriteEditorTemplateIds() {
        let favoriteIds = favoriteEditorTemplateIds.sorted()
        guard let data = try? JSONEncoder().encode(favoriteIds),
              let json = String(data: data, encoding: .utf8)
        else {
            return
        }

        try? settingsRepository.setValue(
            json,
            forKey: Self.favoriteEditorTemplateIdsSettingsKey
        )
    }

    private func persistSavedEditorTemplates() {
        guard let data = try? JSONEncoder().encode(savedEditorTemplates),
              let json = String(data: data, encoding: .utf8)
        else {
            return
        }

        try? settingsRepository.setValue(
            json,
            forKey: Self.savedEditorTemplatesSettingsKey
        )
    }

    private static func resolvedLineScale(
        savedScale: Double?,
        legacyIsLarge: Bool?
    ) -> CGFloat {
        if let savedScale {
            return CGFloat(savedScale)
        }

        if legacyIsLarge == true {
            return EditorTextLayout.legacyLargeLineScale
        }

        return 1.0
    }

    private static func loadFavoriteTemplateIds(
        from settingsRepository: SettingsRepositoryProtocol
    ) -> Set<String> {
        guard let rawValue = try? settingsRepository.getValue(
            forKey: favoritePhraseTemplatesSettingsKey
        ),
        let data = rawValue.data(using: .utf8),
        let ids = try? JSONDecoder().decode([String].self, from: data)
        else {
            return []
        }

        return Set(ids)
    }

    private static func favoriteEditorTemplateID(for type: DesignTemplateType) -> String {
        "design_template_\(type.rawValue)"
    }

    private static func loadSavedCustomPhraseTemplates(
        from settingsRepository: SettingsRepositoryProtocol
    ) -> [SavedCustomPhraseTemplate] {
        guard let rawValue = try? settingsRepository.getValue(
            forKey: savedCustomPhraseTemplatesSettingsKey
        ),
        let data = rawValue.data(using: .utf8),
        let templates = try? JSONDecoder().decode([SavedCustomPhraseTemplate].self, from: data)
        else {
            return []
        }

        return templates
    }

    private static func loadFavoriteEditorTemplateIds(
        from settingsRepository: SettingsRepositoryProtocol
    ) -> Set<String> {
        guard let rawValue = try? settingsRepository.getValue(
            forKey: favoriteEditorTemplateIdsSettingsKey
        ),
        let data = rawValue.data(using: .utf8),
        let ids = try? JSONDecoder().decode([String].self, from: data)
        else {
            return []
        }

        return Set(ids)
    }

    private static func loadSavedEditorTemplates(
        from settingsRepository: SettingsRepositoryProtocol
    ) -> [SavedEditorTemplate] {
        guard let rawValue = try? settingsRepository.getValue(
            forKey: savedEditorTemplatesSettingsKey
        ),
        let data = rawValue.data(using: .utf8),
        let templates = try? JSONDecoder().decode([SavedEditorTemplate].self, from: data)
        else {
            return []
        }

        return templates
    }
}

// MARK: - Color Hex Helpers

extension Color {

    /// Converts a SwiftUI `Color` to a hex string (e.g. "#FFFFFF").
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }

        let r = components.count > 0 ? components[0] : 0
        let g = components.count > 1 ? components[1] : 0
        let b = components.count > 2 ? components[2] : 0

        return String(
            format: "#%02X%02X%02X",
            Int(r * 255),
            Int(g * 255),
            Int(b * 255)
        )
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : self
    }

    var trimmedForPhraseStorage: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
