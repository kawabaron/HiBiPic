import Foundation

// MARK: - CountType

enum CountType: String, CaseIterable, Identifiable, Codable {
    case countdown
    case elapsed
    case daycount

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .countdown:
            return "countdown"
        case .elapsed:
            return "elapsed"
        case .daycount:
            return "daycount"
        }
    }

    var japaneseName: String {
        switch self {
        case .countdown:
            return L10n.t("カウントダウン")
        case .elapsed:
            return L10n.t("経過日数")
        case .daycount:
            return L10n.t("日数カウント")
        }
    }
}

// MARK: - DesignTemplateType

enum DesignTemplateType: String, CaseIterable, Identifiable, Codable {
    case minimal
    case soft
    case film
    case poster
    case classic
    case diary
    case cleanLabel
    case memory
    case milestone
    case airy

    static let allCases: [DesignTemplateType] = [
        .minimal,
        .soft,
        .milestone,
        .classic,
        .diary,
        .cleanLabel,
        .memory,
        .airy,
    ]

    var id: String { rawValue }
}

// MARK: - LayoutMode

enum LayoutMode: String, CaseIterable, Identifiable, Codable {
    case single
    case double

    var id: String { rawValue }
}

// MARK: - FontPreset

enum FontPreset: String, CaseIterable, Identifiable, Codable {
    case standard
    case clean
    case editorialSerif
    case signature

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard:
            return "Standard"
        case .clean:
            return "Clean"
        case .editorialSerif:
            return "Serif"
        case .signature:
            return "Signature"
        }
    }

    var japaneseDescription: String {
        switch self {
        case .standard:
            return L10n.t("今の雰囲気をそのまま使う標準")
        case .clean:
            return L10n.t("静かでミニマルな見え方")
        case .editorialSerif:
            return L10n.t("作品感のある上品なセリフ")
        case .signature:
            return L10n.t("筆記体と手書きの特別フォント")
        }
    }

    init(storageValue: String) {
        switch storageValue {
        case Self.standard.rawValue:
            self = .standard
        case Self.clean.rawValue:
            self = .clean
        case Self.editorialSerif.rawValue:
            self = .editorialSerif
        case Self.signature.rawValue:
            self = .signature
        case "softRounded":
            self = .standard
        default:
            self = .standard
        }
    }
}

// MARK: - EventEditorPreferences

struct EventEditorPreferences: Equatable, Codable {
    var textPositionX: Double
    var textPositionY: Double
    var textScale: Double
    var textColorHex: String
    var showBackgroundBand: Bool
    var backgroundBandColorHex: String?
    var textAlignment: TextAlignment?
    var singleLineScale: Double
    var line1Scale: Double
    var line2Scale: Double
    var line3Scale: Double
    var numbersOnlyLarge: Bool
}

// MARK: - Event

struct Event: Identifiable, Equatable {
    let id: String
    var name: String
    var baseDate: String // YYYY-MM-DD
    var countType: CountType
    var phraseTemplateId: String
    var designTemplateId: DesignTemplateType
    var fontPreset: FontPreset
    var layoutMode: LayoutMode
    var customPhraseMode: Bool
    var customSingleLine: String?
    var customLine1: String?
    var customLine2: String?
    var customLine3: String?
    var editorPreferences: EventEditorPreferences?
    var isPinned: Bool
    var sortOrder: Int?
    var lastUsedAt: String?
    var createdAt: String
    var updatedAt: String
    var isArchived: Bool

    init(
        id: String = UUID().uuidString,
        name: String,
        baseDate: String,
        countType: CountType = .elapsed,
        phraseTemplateId: String = "",
        designTemplateId: DesignTemplateType = .minimal,
        fontPreset: FontPreset = .standard,
        layoutMode: LayoutMode = .single,
        customPhraseMode: Bool = false,
        customSingleLine: String? = nil,
        customLine1: String? = nil,
        customLine2: String? = nil,
        customLine3: String? = nil,
        editorPreferences: EventEditorPreferences? = nil,
        isPinned: Bool = false,
        sortOrder: Int? = nil,
        lastUsedAt: String? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.baseDate = baseDate
        self.countType = countType
        self.phraseTemplateId = phraseTemplateId
        self.designTemplateId = designTemplateId
        self.fontPreset = fontPreset
        self.layoutMode = layoutMode
        self.customPhraseMode = customPhraseMode
        self.customSingleLine = customSingleLine
        self.customLine1 = customLine1
        self.customLine2 = customLine2
        self.customLine3 = customLine3
        self.editorPreferences = editorPreferences
        self.isPinned = isPinned
        self.sortOrder = sortOrder
        self.lastUsedAt = lastUsedAt

        let now = ISO8601DateFormatter().string(from: Date())
        self.createdAt = createdAt ?? now
        self.updatedAt = updatedAt ?? now
        self.isArchived = isArchived
    }

    static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }
}
