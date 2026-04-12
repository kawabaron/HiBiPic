import Foundation

// MARK: - SavedImageEditRecipe

struct SavedImageEditRecipe: Equatable, Codable {
    let eventName: String
    let eventBaseDate: String
    let eventCountType: CountType
    let designTemplateId: DesignTemplateType
    let fontPreset: FontPreset
    let layoutMode: LayoutMode
    let phraseTemplateId: String
    let wasCustomPhraseMode: Bool
    let customSingleLine: String
    let customLine1: String
    let customLine2: String
    let customLine3: String?
    let singleLineScale: Double?
    let line1Scale: Double?
    let line2Scale: Double?
    let line3Scale: Double?
    // Legacy restore values from the old checkbox-based size UI.
    let customSingleLineIsLarge: Bool?
    let customLine1IsLarge: Bool?
    let customLine2IsLarge: Bool?
    let customLine3IsLarge: Bool?
    let customNumbersOnlyLarge: Bool?
    let renderedSingleLine: String
    let renderedLine1: String
    let renderedLine2: String
    let renderedLine3: String?
    let textPositionX: Double
    let textPositionY: Double
    let textScale: Double
    let textColorHex: String
    let showBackgroundBand: Bool
    let backgroundBandColorHex: String?
    let textAlignment: TextAlignment?

    func makeSnapshotEvent(eventId: String) -> Event {
        Event(
            id: eventId,
            name: eventName,
            baseDate: eventBaseDate,
            countType: eventCountType,
            phraseTemplateId: phraseTemplateId,
            designTemplateId: designTemplateId,
            fontPreset: fontPreset,
            layoutMode: layoutMode,
            customPhraseMode: wasCustomPhraseMode,
            customSingleLine: wasCustomPhraseMode ? customSingleLine.nilIfBlank : nil,
            customLine1: wasCustomPhraseMode ? customLine1.nilIfBlank : nil,
            customLine2: wasCustomPhraseMode ? customLine2.nilIfBlank : nil,
            customLine3: wasCustomPhraseMode ? customLine3?.nilIfBlank : nil,
            editorPreferences: makeEditorPreferences()
        )
    }

    func makeEditorPreferences() -> EventEditorPreferences {
        EventEditorPreferences(
            textPositionX: textPositionX,
            textPositionY: textPositionY,
            textScale: textScale,
            textColorHex: textColorHex,
            showBackgroundBand: showBackgroundBand,
            backgroundBandColorHex: backgroundBandColorHex,
            textAlignment: textAlignment,
            singleLineScale: singleLineScale ?? ((customSingleLineIsLarge == true) ? 1.24 : 1.0),
            line1Scale: line1Scale ?? ((customLine1IsLarge == true) ? 1.24 : 1.0),
            line2Scale: line2Scale ?? ((customLine2IsLarge == true) ? 1.24 : 1.0),
            line3Scale: line3Scale ?? ((customLine3IsLarge == true) ? 1.24 : 1.0),
            numbersOnlyLarge: customNumbersOnlyLarge ?? false
        )
    }
}

// MARK: - SavedImage

struct SavedImage: Identifiable, Equatable {
    let id: String
    let eventId: String
    let fileName: String
    let originalFileName: String?
    let editRecipe: SavedImageEditRecipe?
    let createdAt: String // ISO8601

    var supportsFullReedit: Bool {
        originalFileName != nil && editRecipe != nil
    }

    init(
        id: String = UUID().uuidString,
        eventId: String,
        fileName: String,
        originalFileName: String? = nil,
        editRecipe: SavedImageEditRecipe? = nil,
        createdAt: String? = nil
    ) {
        self.id = id
        self.eventId = eventId
        self.fileName = fileName
        self.originalFileName = originalFileName
        self.editRecipe = editRecipe
        self.createdAt = createdAt ?? ISO8601DateFormatter().string(from: Date())
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : self
    }
}
