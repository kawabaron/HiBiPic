import SwiftUI

// MARK: - HiBiPicApp

@main
struct HiBiPicApp: App {

    // MARK: - Lifecycle

    @State private var appearanceMode: AppAppearanceMode = Self.loadInitialAppearanceMode()
    @State private var languageMode: AppLanguage = Self.loadInitialLanguageMode()

    init() {
        // Initialize the database on first access so tables are ready
        // before any screen tries to read data.
        _ = AppDatabase.shared
        configureAppearance()
        MainTabView.configureTabBarAppearance()
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            MainTabView(
                appearanceMode: $appearanceMode,
                languageMode: $languageMode
            )
                .preferredColorScheme(appearanceMode.preferredColorScheme)
                .environment(\.locale, languageMode.locale)
                .onAppear {
                    AppLocalizer.setLanguage(languageMode)
                }
                .onChange(of: languageMode) { _, newValue in
                    AppLocalizer.setLanguage(newValue)
                }
        }
    }

    // MARK: - Appearance

    /// Applies global UIKit appearance overrides for the "Warm Minimal" theme.
    private func configureAppearance() {
        // Navigation bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(DSColors.background)
        navAppearance.shadowColor = UIColor(DSColors.divider)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(DSColors.textPrimary),
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(DSColors.textPrimary),
            .font: UIFont.systemFont(ofSize: 28, weight: .bold)
        ]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(DSColors.accent)
    }

    private static func loadInitialAppearanceMode() -> AppAppearanceMode {
        (try? AppDependencies.shared.settingsRepository.load().appearanceMode) ?? .system
    }

    private static func loadInitialLanguageMode() -> AppLanguage {
        let language = (try? AppDependencies.shared.settingsRepository.load().languageMode) ?? .japanese
        AppLocalizer.setLanguage(language)
        return language
    }
}

private extension AppAppearanceMode {
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
