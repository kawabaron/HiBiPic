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
    case englishGB = "en-GB"
    case german = "de"
    case spanishMX = "es-MX"
    case portugueseBR = "pt-BR"

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .japanese:
            return L10n.t("日本語")
        case .englishUS:
            return L10n.t("英語（アメリカ）")
        case .englishGB:
            return L10n.t("英語（イギリス）")
        case .german:
            return L10n.t("ドイツ語")
        case .spanishMX:
            return L10n.t("スペイン語（メキシコ）")
        case .portugueseBR:
            return L10n.t("ポルトガル語（ブラジル）")
        }
    }

    var nativeLabel: String {
        switch self {
        case .japanese:
            return "日本語"
        case .englishUS:
            return "English (US)"
        case .englishGB:
            return "English (UK)"
        case .german:
            return "Deutsch"
        case .spanishMX:
            return "Español (México)"
        case .portugueseBR:
            return "Português (Brasil)"
        }
    }

    var badgeLabel: String {
        switch self {
        case .japanese:
            return "JA"
        case .englishUS:
            return "US"
        case .englishGB:
            return "UK"
        case .german:
            return "DE"
        case .spanishMX:
            return "MX"
        case .portugueseBR:
            return "BR"
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
        case Self.englishGB.rawValue:
            self = .englishGB
        case Self.german.rawValue:
            self = .german
        case Self.spanishMX.rawValue, "es":
            self = .spanishMX
        case Self.portugueseBR.rawValue, "pt":
            self = .portugueseBR
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
