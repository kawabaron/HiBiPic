import Foundation

/// Provides direct SQL access to the `settings` key-value table.
final class SettingsLocalDataSource {

    private let db: AppDatabase

    init(db: AppDatabase = .shared) {
        self.db = db
    }

    // MARK: - Get

    /// Retrieves the value for a given key, or `nil` if the key does not exist.
    func getValue(key: String) throws -> String? {
        let rows = try db.query(
            sql: "SELECT value FROM settings WHERE key = ?",
            params: [key]
        )
        return rows.first?["value"] as? String
    }

    // MARK: - Set (upsert)

    /// Inserts or replaces the value for the given key.
    func setValue(key: String, value: String) throws {
        let now = ISO8601DateFormatter().string(from: Date())
        try db.execute(
            sql: """
                INSERT INTO settings (key, value, updated_at)
                VALUES (?, ?, ?)
                ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at
                """,
            params: [key, value, now]
        )
    }

    // MARK: - Get All

    /// Returns all stored settings as a `[key: value]` dictionary.
    func getAll() throws -> [String: String] {
        let rows = try db.query(sql: "SELECT key, value FROM settings")
        var result: [String: String] = [:]
        for row in rows {
            if let key = row["key"] as? String,
               let value = row["value"] as? String {
                result[key] = value
            }
        }
        return result
    }
}
