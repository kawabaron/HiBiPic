import Foundation

enum AppAppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .system:
            return L10n.t("システム")
        case .light:
            return L10n.t("ライト")
        case .dark:
            return L10n.t("ダーク")
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case japanese = "ja"
    case englishUS = "en-US"
    case korean = "ko"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .japanese:
            return L10n.t("日本語")
        case .englishUS:
            return L10n.t("英語（アメリカ）")
        case .korean:
            return L10n.t("韓国語")
        case .simplifiedChinese:
            return L10n.t("中国語（簡体字）")
        case .traditionalChinese:
            return L10n.t("中国語（繁体字）")
        }
    }

    var nativeLabel: String {
        switch self {
        case .japanese:
            return "日本語"
        case .englishUS:
            return "English (US)"
        case .korean:
            return "한국어"
        case .simplifiedChinese:
            return "简体中文"
        case .traditionalChinese:
            return "繁體中文"
        }
    }

    var badgeLabel: String {
        switch self {
        case .japanese:
            return "JA"
        case .englishUS:
            return "US"
        case .korean:
            return "KO"
        case .simplifiedChinese:
            return "SC"
        case .traditionalChinese:
            return "TC"
        }
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    init(storageValue: String) {
        switch storageValue {
        case Self.japanese.rawValue:
            self = .japanese
        case Self.englishUS.rawValue, "en":
            self = .englishUS
        case Self.korean.rawValue, "ko":
            self = .korean
        case Self.simplifiedChinese.rawValue, "zh-Hans", "zh-CN":
            self = .simplifiedChinese
        case Self.traditionalChinese.rawValue, "zh-Hant", "zh-TW", "zh-HK":
            self = .traditionalChinese
        case "en-GB", "de", "es", "es-MX", "pt", "pt-BR":
            self = .englishUS
        default:
            self = .japanese
        }
    }
}

struct AppSettings {
    var defaultDesignTemplateId: DesignTemplateType
    var defaultCountType: CountType
    var defaultLayoutMode: LayoutMode
    var showShareAfterSave: Bool
    var appearanceMode: AppAppearanceMode
    var languageMode: AppLanguage
    var updatedAt: String

    static let defaults = AppSettings(
        defaultDesignTemplateId: .minimal,
        defaultCountType: .elapsed,
        defaultLayoutMode: .single,
        showShareAfterSave: true,
        appearanceMode: .system,
        languageMode: .japanese,
        updatedAt: ISO8601DateFormatter().string(from: Date())
    )
}
