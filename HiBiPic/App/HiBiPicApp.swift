import SwiftUI

// MARK: - HiBiPicApp

@main
struct HiBiPicApp: App {

    // MARK: - Lifecycle

    init() {
        // Initialize the database on first access so tables are ready
        // before any screen tries to read data.
        _ = AppDatabase.shared
        configureAppearance()
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            RootNavigationView()
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
}
