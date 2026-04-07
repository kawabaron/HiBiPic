import Foundation

// MARK: - CountType

enum CountType: String, CaseIterable, Identifiable {
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
            return "カウントダウン"
        case .elapsed:
            return "経過日数"
        case .daycount:
            return "日数カウント"
        }
    }
}

// MARK: - DesignTemplateType

enum DesignTemplateType: String, CaseIterable, Identifiable {
    case minimal
    case soft
    case film
    case poster

    var id: String { rawValue }
}

// MARK: - LayoutMode

enum LayoutMode: String, CaseIterable, Identifiable {
    case single
    case double

    var id: String { rawValue }
}

// MARK: - Event

struct Event: Identifiable, Equatable {
    let id: String
    var name: String
    var baseDate: String // YYYY-MM-DD
    var countType: CountType
    var phraseTemplateId: String
    var designTemplateId: DesignTemplateType
    var layoutMode: LayoutMode
    var customPhraseMode: Bool
    var customSingleLine: String?
    var customLine1: String?
    var customLine2: String?
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
        layoutMode: LayoutMode = .single,
        customPhraseMode: Bool = false,
        customSingleLine: String? = nil,
        customLine1: String? = nil,
        customLine2: String? = nil,
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
        self.layoutMode = layoutMode
        self.customPhraseMode = customPhraseMode
        self.customSingleLine = customSingleLine
        self.customLine1 = customLine1
        self.customLine2 = customLine2
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
