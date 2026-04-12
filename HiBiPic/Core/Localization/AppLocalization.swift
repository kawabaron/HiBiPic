import Foundation
import ObjectiveC

enum AppLocalizer {
    private static let languageDefaultsKey = "HiBiPic.selectedAppLanguage"

    static func setLanguage(_ language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: languageDefaultsKey)
        Bundle.setAppLanguage(language.rawValue)
    }

    static var currentLanguage: AppLanguage {
        let storedValue = UserDefaults.standard.string(forKey: languageDefaultsKey)
            ?? AppSettings.defaults.languageMode.rawValue
        return AppLanguage(storageValue: storedValue)
    }

    static func text(_ key: String) -> String {
        NSLocalizedString(key, bundle: .main, value: key, comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        format(key, arguments)
    }

    static func format(_ key: String, _ arguments: [CVarArg]) -> String {
        String(
            format: text(key),
            locale: currentLanguage.locale,
            arguments: arguments
        )
    }
}

enum L10n {
    static func t(_ key: String) -> String {
        AppLocalizer.text(key)
    }

    static func f(_ key: String, _ arguments: CVarArg...) -> String {
        AppLocalizer.format(key, arguments)
    }
}

enum LocalizedDayCountFormatter {
    static func string(days: Int, countType: CountType, showsTodayForZeroCountdown: Bool = true) -> String {
        switch countType {
        case .countdown:
            if showsTodayForZeroCountdown && days == 0 {
                return L10n.t("当日")
            }
            return L10n.f("あと%d日", days)
        case .elapsed:
            return L10n.f("%d日経過", days)
        case .daycount:
            return L10n.f("%d日目", days)
        }
    }
}

private var appLanguageBundleKey: UInt8 = 0

private final class AppLanguageBundle: Bundle, @unchecked Sendable {
    override func localizedString(
        forKey key: String,
        value: String?,
        table tableName: String?
    ) -> String {
        guard
            let path = objc_getAssociatedObject(self, &appLanguageBundleKey) as? String,
            let bundle = Bundle(path: path)
        else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }

        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

private extension Bundle {
    static func setAppLanguage(_ languageIdentifier: String) {
        object_setClass(Bundle.main, AppLanguageBundle.self)

        let resourceIdentifier: String
        switch languageIdentifier {
        case AppLanguage.englishGB.rawValue:
            resourceIdentifier = AppLanguage.englishUS.rawValue
        default:
            resourceIdentifier = languageIdentifier
        }

        let preferredPath = Bundle.main.path(forResource: resourceIdentifier, ofType: "lproj")
        let languageCode = Locale(identifier: resourceIdentifier).language.languageCode?.identifier
        let fallbackPath = languageCode.flatMap {
            Bundle.main.path(forResource: $0, ofType: "lproj")
        }
        let defaultPath = Bundle.main.path(forResource: AppLanguage.japanese.rawValue, ofType: "lproj")

        objc_setAssociatedObject(
            Bundle.main,
            &appLanguageBundleKey,
            preferredPath ?? fallbackPath ?? defaultPath,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
}
