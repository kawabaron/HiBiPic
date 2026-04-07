import Foundation

// MARK: - AppDependencies

/// Lightweight service-locator that owns the concrete repository instances.
///
/// Screens and view-models that accept protocol-typed dependencies can
/// pull defaults from here, while tests substitute their own mocks.
final class AppDependencies {

    // MARK: - Singleton

    static let shared = AppDependencies()

    // MARK: - Repositories

    lazy var eventRepository: EventRepositoryProtocol = EventRepositoryImpl()
    lazy var settingsRepository: SettingsRepositoryProtocol = SettingsRepositoryImpl()

    // MARK: - Init

    private init() {}
}
