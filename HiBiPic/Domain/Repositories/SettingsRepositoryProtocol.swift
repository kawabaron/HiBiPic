import Foundation

/// Protocol defining the contract for application settings persistence.
protocol SettingsRepositoryProtocol {
    /// Loads all persisted settings, merged with defaults for any missing keys.
    /// - Returns: A fully populated `AppSettings` value.
    func load() throws -> AppSettings

    /// Persists the given settings, writing each field as a key-value pair.
    /// - Parameter settings: The `AppSettings` to save.
    func save(_ settings: AppSettings) throws

    /// Reads a single setting value by key.
    /// - Parameter key: The setting key.
    /// - Returns: The raw string value, or `nil` if the key has never been set.
    func getValue(forKey key: String) throws -> String?

    /// Writes a single setting value by key.
    /// - Parameters:
    ///   - value: The string value to persist.
    ///   - key: The setting key.
    func setValue(_ value: String, forKey key: String) throws
}
