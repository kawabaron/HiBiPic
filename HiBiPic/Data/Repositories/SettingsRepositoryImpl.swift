import Foundation

/// Concrete implementation of `SettingsRepositoryProtocol` backed by SQLite.
///
/// Each `AppSettings` property is stored as a separate key-value row in
/// the `settings` table. Loading merges persisted values with hardcoded
/// defaults so the app always has a complete `AppSettings` value.
final class SettingsRepositoryImpl: SettingsRepositoryProtocol {

    // MARK: - Keys

    private enum Key {
        static let defaultDesignTemplateId = "default_design_template_id"
        static let defaultCountType = "default_count_type"
        static let defaultLayoutMode = "default_layout_mode"
        static let showShareAfterSave = "show_share_after_save"
        static let languageMode = "language_mode"
        static let updatedAt = "settings_updated_at"
    }

    // MARK: - Dependencies

    private let dataSource: SettingsLocalDataSource

    init(dataSource: SettingsLocalDataSource = SettingsLocalDataSource()) {
        self.dataSource = dataSource
    }

    // MARK: - Load

    func load() throws -> AppSettings {
        let all = try dataSource.getAll()
        let defaults = AppSettings.defaults

        let designTemplate = all[Key.defaultDesignTemplateId]
            .flatMap { DesignTemplateType(rawValue: $0) } ?? defaults.defaultDesignTemplateId

        let countType = all[Key.defaultCountType]
            .flatMap { CountType(rawValue: $0) } ?? defaults.defaultCountType

        let layoutMode = all[Key.defaultLayoutMode]
            .flatMap { LayoutMode(rawValue: $0) } ?? defaults.defaultLayoutMode

        let showShare: Bool
        if let raw = all[Key.showShareAfterSave] {
            showShare = (raw == "1" || raw.lowercased() == "true")
        } else {
            showShare = defaults.showShareAfterSave
        }

        let language = all[Key.languageMode] ?? defaults.languageMode

        let updatedAt = all[Key.updatedAt] ?? defaults.updatedAt

        return AppSettings(
            defaultDesignTemplateId: designTemplate,
            defaultCountType: countType,
            defaultLayoutMode: layoutMode,
            showShareAfterSave: showShare,
            languageMode: language,
            updatedAt: updatedAt
        )
    }

    // MARK: - Save

    func save(_ settings: AppSettings) throws {
        try dataSource.setValue(
            key: Key.defaultDesignTemplateId,
            value: settings.defaultDesignTemplateId.rawValue
        )
        try dataSource.setValue(
            key: Key.defaultCountType,
            value: settings.defaultCountType.rawValue
        )
        try dataSource.setValue(
            key: Key.defaultLayoutMode,
            value: settings.defaultLayoutMode.rawValue
        )
        try dataSource.setValue(
            key: Key.showShareAfterSave,
            value: settings.showShareAfterSave ? "1" : "0"
        )
        try dataSource.setValue(
            key: Key.languageMode,
            value: settings.languageMode
        )
        let now = ISO8601DateFormatter().string(from: Date())
        try dataSource.setValue(
            key: Key.updatedAt,
            value: now
        )
    }

    // MARK: - Single Value Access

    func getValue(forKey key: String) throws -> String? {
        try dataSource.getValue(key: key)
    }

    func setValue(_ value: String, forKey key: String) throws {
        try dataSource.setValue(key: key, value: value)
    }
}
