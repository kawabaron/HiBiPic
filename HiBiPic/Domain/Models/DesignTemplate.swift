import Foundation

// MARK: - TextAlignment

enum TextAlignment: String, CaseIterable, Identifiable, Codable {
    case left
    case center
    case right

    var id: String { rawValue }

    var label: String {
        switch self {
        case .left:
            return L10n.t("左揃え")
        case .center:
            return L10n.t("中央揃え")
        case .right:
            return L10n.t("右揃え")
        }
    }

    var systemImage: String {
        switch self {
        case .left:
            return "text.alignleft"
        case .center:
            return "text.aligncenter"
        case .right:
            return "text.alignright"
        }
    }
}

// MARK: - TextPositionPreset

enum TextPositionPreset: String, CaseIterable, Identifiable, Codable {
    case topLeading
    case topCenter
    case topTrailing
    case centerLeading
    case center
    case centerTrailing
    case bottomLeading
    case bottomCenter
    case bottomTrailing

    var id: String { rawValue }

    var label: String {
        switch self {
        case .topLeading: return L10n.t("左上")
        case .topCenter: return L10n.t("中央上")
        case .topTrailing: return L10n.t("右上")
        case .centerLeading: return L10n.t("左中央")
        case .center: return L10n.t("中央")
        case .centerTrailing: return L10n.t("右中央")
        case .bottomLeading: return L10n.t("左下")
        case .bottomCenter: return L10n.t("中央下")
        case .bottomTrailing: return L10n.t("右下")
        }
    }
}

// MARK: - DesignTemplate

struct DesignTemplate: Identifiable, Equatable {
    let id: DesignTemplateType
    let name: String
    let description: String
    let defaultLayoutMode: LayoutMode
    let defaultFontPreset: FontPreset
    let defaultTextPositionPreset: TextPositionPreset
    let defaultTextScale: CGFloat
    let defaultSingleLineScaleMultiplier: CGFloat
    let defaultLine1ScaleMultiplier: CGFloat
    let defaultLine2ScaleMultiplier: CGFloat
    let defaultLine3ScaleMultiplier: CGFloat
    let defaultNumbersOnlyLarge: Bool
    let textColor: String       // hex e.g. "#FFFFFF"
    let backgroundColor: String // hex e.g. "#000000"
    let fontWeight: FontWeight
    let fontSizeScale: CGFloat  // 1.0 = standard
    let alignment: TextAlignment
    let showBackground: Bool    // band behind text
    let numberEmphasis: Bool

    enum FontWeight: String {
        case thin
        case light
        case regular
        case medium
        case semibold
        case bold
        case heavy
    }

    func defaultPhraseTemplate(for countType: CountType) -> PhraseTemplate {
        let preferredId = defaultPhraseTemplateId(for: countType)

        if let preferred = PhraseTemplateStore.allTemplates.first(where: { $0.id == preferredId }) {
            return preferred
        }

        let candidates = PhraseTemplateStore.templates(for: countType)
            .filter { $0.layoutMode == defaultLayoutMode }
        if let recommended = candidates.first(where: { $0.isRecommended }) ?? candidates.first {
            return recommended
        }

        return PhraseTemplateStore.defaultTemplate(for: countType)
    }

    private func defaultPhraseTemplateId(for countType: CountType) -> String {
        switch id {
        case .minimal:
            switch countType {
            case .countdown:
                return "countdown_single_1"
            case .elapsed:
                return "elapsed_single_3"
            case .daycount:
                return "daycount_single_1"
            }
        case .soft:
            switch countType {
            case .countdown:
                return "countdown_double_1"
            case .elapsed:
                return "elapsed_double_2"
            case .daycount:
                return "daycount_double_1"
            }
        case .film:
            switch countType {
            case .countdown:
                return "countdown_single_2"
            case .elapsed:
                return "elapsed_single_3"
            case .daycount:
                return "daycount_single_2"
            }
        case .poster:
            switch countType {
            case .countdown:
                return "countdown_triple_1"
            case .elapsed:
                return "elapsed_triple_1"
            case .daycount:
                return "daycount_triple_1"
            }
        case .classic:
            switch countType {
            case .countdown:
                return "countdown_single_1"
            case .elapsed:
                return "elapsed_single_3"
            case .daycount:
                return "daycount_single_1"
            }
        case .diary:
            switch countType {
            case .countdown:
                return "countdown_double_1"
            case .elapsed:
                return "elapsed_double_2"
            case .daycount:
                return "daycount_double_1"
            }
        case .cleanLabel:
            switch countType {
            case .countdown:
                return "countdown_double_1"
            case .elapsed:
                return "elapsed_double_1"
            case .daycount:
                return "daycount_double_en_1"
            }
        case .memory:
            switch countType {
            case .countdown:
                return "countdown_single_en_2"
            case .elapsed:
                return "elapsed_single_en_2"
            case .daycount:
                return "daycount_single_en_2"
            }
        case .milestone:
            switch countType {
            case .countdown:
                return "countdown_triple_1"
            case .elapsed:
                return "elapsed_triple_1"
            case .daycount:
                return "daycount_triple_1"
            }
        case .airy:
            switch countType {
            case .countdown:
                return "countdown_single_2"
            case .elapsed:
                return "elapsed_single_3"
            case .daycount:
                return "daycount_single_1"
            }
        }
    }
}

// MARK: - DesignTemplateStore

final class DesignTemplateStore {

    static var allTemplates: [DesignTemplate] {
        [
        // ── Minimal ──
        DesignTemplate(
            id: .minimal,
            name: "Minimal",
            description: L10n.t("シンプルで洗練されたデザイン。小さめの白文字、背景バンドなし。"),
            defaultLayoutMode: .single,
            defaultFontPreset: .clean,
            defaultTextPositionPreset: .bottomCenter,
            defaultTextScale: 0.92,
            defaultSingleLineScaleMultiplier: 1.0,
            defaultLine1ScaleMultiplier: 1.0,
            defaultLine2ScaleMultiplier: 1.0,
            defaultLine3ScaleMultiplier: 1.0,
            defaultNumbersOnlyLarge: false,
            textColor: "#FFFFFF",
            backgroundColor: "#00000000",  // transparent
            fontWeight: .light,
            fontSizeScale: 0.96,
            alignment: .center,
            showBackground: false,
            numberEmphasis: false
        ),

        // ── Soft ──
        DesignTemplate(
            id: .soft,
            name: "Soft",
            description: L10n.t("暖かみのある柔らかなデザイン。手書き感のある文字、淡い背景バンド付き。"),
            defaultLayoutMode: .double,
            defaultFontPreset: .signature,
            defaultTextPositionPreset: .bottomCenter,
            defaultTextScale: 0.96,
            defaultSingleLineScaleMultiplier: 1.0,
            defaultLine1ScaleMultiplier: 0.9,
            defaultLine2ScaleMultiplier: 1.04,
            defaultLine3ScaleMultiplier: 0.9,
            defaultNumbersOnlyLarge: false,
            textColor: "#3C342F",
            backgroundColor: "#FFF2D8D9",  // warm translucent band
            fontWeight: .regular,
            fontSizeScale: 0.98,
            alignment: .center,
            showBackground: true,
            numberEmphasis: true
        ),

        // ── Milestone ──
        DesignTemplate(
            id: .milestone,
            name: "Milestone",
            description: L10n.t("達成日数を主役にする力強いデザイン。中央配置、数字を大きく表示。"),
            defaultLayoutMode: .double,
            defaultFontPreset: .standard,
            defaultTextPositionPreset: .center,
            defaultTextScale: 1.02,
            defaultSingleLineScaleMultiplier: 1.0,
            defaultLine1ScaleMultiplier: 0.76,
            defaultLine2ScaleMultiplier: 1.18,
            defaultLine3ScaleMultiplier: 0.72,
            defaultNumbersOnlyLarge: false,
            textColor: "#FFFFFF",
            backgroundColor: "#121212CC",
            fontWeight: .heavy,
            fontSizeScale: 1.18,
            alignment: .center,
            showBackground: true,
            numberEmphasis: true
        ),

        // ── Classic ──
        DesignTemplate(
            id: .classic,
            name: "Classic",
            description: L10n.t("記念日や旅行写真に合う上品なデザイン。セリフ体、背景バンドなし。"),
            defaultLayoutMode: .single,
            defaultFontPreset: .editorialSerif,
            defaultTextPositionPreset: .bottomCenter,
            defaultTextScale: 0.88,
            defaultSingleLineScaleMultiplier: 1.0,
            defaultLine1ScaleMultiplier: 1.0,
            defaultLine2ScaleMultiplier: 1.0,
            defaultLine3ScaleMultiplier: 1.0,
            defaultNumbersOnlyLarge: false,
            textColor: "#F7F1E8",
            backgroundColor: "#00000000",
            fontWeight: .regular,
            fontSizeScale: 0.92,
            alignment: .center,
            showBackground: false,
            numberEmphasis: false
        ),

        // ── Diary ──
        DesignTemplate(
            id: .diary,
            name: "Diary",
            description: L10n.t("手書き日記のような柔らかいデザイン。左下寄せ、淡いクリーム背景。"),
            defaultLayoutMode: .double,
            defaultFontPreset: .signature,
            defaultTextPositionPreset: .bottomLeading,
            defaultTextScale: 0.95,
            defaultSingleLineScaleMultiplier: 1.0,
            defaultLine1ScaleMultiplier: 0.92,
            defaultLine2ScaleMultiplier: 1.02,
            defaultLine3ScaleMultiplier: 0.9,
            defaultNumbersOnlyLarge: false,
            textColor: "#4A3830",
            backgroundColor: "#FFF1D6E6",
            fontWeight: .regular,
            fontSizeScale: 0.95,
            alignment: .left,
            showBackground: true,
            numberEmphasis: true
        ),

        // ── Clean Label ──
        DesignTemplate(
            id: .cleanLabel,
            name: "Clean Label",
            description: L10n.t("SNS写真に載せやすい小さなラベル風デザイン。右下寄せ、黒い薄背景。"),
            defaultLayoutMode: .double,
            defaultFontPreset: .clean,
            defaultTextPositionPreset: .bottomTrailing,
            defaultTextScale: 0.86,
            defaultSingleLineScaleMultiplier: 1.0,
            defaultLine1ScaleMultiplier: 0.82,
            defaultLine2ScaleMultiplier: 0.95,
            defaultLine3ScaleMultiplier: 0.82,
            defaultNumbersOnlyLarge: false,
            textColor: "#FFFDF8",
            backgroundColor: "#111111B3",
            fontWeight: .medium,
            fontSizeScale: 0.88,
            alignment: .right,
            showBackground: true,
            numberEmphasis: true
        ),

        // ── Memory ──
        DesignTemplate(
            id: .memory,
            name: "Memory",
            description: L10n.t("写真の余韻を残す映画字幕風デザイン。英字寄り、左下、背景なし。"),
            defaultLayoutMode: .single,
            defaultFontPreset: .editorialSerif,
            defaultTextPositionPreset: .bottomLeading,
            defaultTextScale: 0.84,
            defaultSingleLineScaleMultiplier: 1.0,
            defaultLine1ScaleMultiplier: 1.0,
            defaultLine2ScaleMultiplier: 1.0,
            defaultLine3ScaleMultiplier: 1.0,
            defaultNumbersOnlyLarge: false,
            textColor: "#F1E7D2",
            backgroundColor: "#00000000",
            fontWeight: .light,
            fontSizeScale: 0.9,
            alignment: .left,
            showBackground: false,
            numberEmphasis: false
        ),

        // ── Airy ──
        DesignTemplate(
            id: .airy,
            name: "Airy",
            description: L10n.t("空や明るい風景に合う軽いデザイン。上中央、白い半透明背景。"),
            defaultLayoutMode: .single,
            defaultFontPreset: .clean,
            defaultTextPositionPreset: .topCenter,
            defaultTextScale: 0.82,
            defaultSingleLineScaleMultiplier: 1.0,
            defaultLine1ScaleMultiplier: 1.0,
            defaultLine2ScaleMultiplier: 1.0,
            defaultLine3ScaleMultiplier: 1.0,
            defaultNumbersOnlyLarge: false,
            textColor: "#25302B",
            backgroundColor: "#FFFFFFC9",
            fontWeight: .regular,
            fontSizeScale: 0.88,
            alignment: .center,
            showBackground: true,
            numberEmphasis: false
        ),
        ]
    }

    // MARK: - Query Methods

    static func template(for type: DesignTemplateType) -> DesignTemplate {
        allTemplates.first { $0.id == type } ?? allTemplates[0]
    }

    static func defaultTemplate() -> DesignTemplate {
        template(for: .minimal)
    }
}

// MARK: - SavedEditorTemplate

struct SavedEditorTemplate: Identifiable, Codable, Equatable {
    let id: String
    let countType: CountType
    let designTemplateId: DesignTemplateType
    let fontPreset: FontPreset
    let layoutMode: LayoutMode
    let phraseTemplateId: String
    let customPhraseMode: Bool
    let customSingleLine: String
    let customLine1: String
    let customLine2: String
    let customLine3: String
    let editorPreferences: EventEditorPreferences
    let createdAt: String

    var favoriteId: String {
        "saved_editor_template_\(id)"
    }

    func matches(_ other: SavedEditorTemplate) -> Bool {
        countType == other.countType
            && designTemplateId == other.designTemplateId
            && fontPreset == other.fontPreset
            && layoutMode == other.layoutMode
            && phraseTemplateId == other.phraseTemplateId
            && customPhraseMode == other.customPhraseMode
            && customSingleLine.trimmedForTemplateStorage == other.customSingleLine.trimmedForTemplateStorage
            && customLine1.trimmedForTemplateStorage == other.customLine1.trimmedForTemplateStorage
            && customLine2.trimmedForTemplateStorage == other.customLine2.trimmedForTemplateStorage
            && customLine3.trimmedForTemplateStorage == other.customLine3.trimmedForTemplateStorage
            && editorPreferences.approximatelyMatches(other.editorPreferences)
    }
}

private extension EventEditorPreferences {
    func approximatelyMatches(_ other: EventEditorPreferences) -> Bool {
        approximatelyEqual(textPositionX, other.textPositionX)
            && approximatelyEqual(textPositionY, other.textPositionY)
            && approximatelyEqual(textScale, other.textScale)
            && textColorHex.normalizedTemplateHex == other.textColorHex.normalizedTemplateHex
            && showBackgroundBand == other.showBackgroundBand
            && backgroundBandColorHex.normalizedTemplateHex == other.backgroundBandColorHex.normalizedTemplateHex
            && textAlignment == other.textAlignment
            && approximatelyEqual(singleLineScale, other.singleLineScale)
            && approximatelyEqual(line1Scale, other.line1Scale)
            && approximatelyEqual(line2Scale, other.line2Scale)
            && approximatelyEqual(line3Scale, other.line3Scale)
            && numbersOnlyLarge == other.numbersOnlyLarge
    }

    private func approximatelyEqual(_ lhs: Double, _ rhs: Double, tolerance: Double = 0.0005) -> Bool {
        abs(lhs - rhs) <= tolerance
    }
}

private extension Optional where Wrapped == String {
    var normalizedTemplateHex: String? {
        self?.normalizedTemplateHex
    }
}

private extension String {
    var normalizedTemplateHex: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .uppercased()
    }

    var trimmedForTemplateStorage: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
