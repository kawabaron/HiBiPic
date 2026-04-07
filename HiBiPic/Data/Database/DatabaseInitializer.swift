import Foundation
import SQLite3

/// Manages SQLite schema creation, indexing, and versioned migrations.
///
/// The current schema version is tracked via SQLite's built-in `user_version` pragma.
/// Each migration is an idempotent closure keyed by its target version number.
final class DatabaseInitializer {

    /// Current schema version. Bump this and add a corresponding migration
    /// closure to `migrations` whenever the schema changes.
    private static let currentVersion: Int32 = 2

    // MARK: - Public Entry Point

    /// Initializes the database schema. Safe to call on every app launch.
    /// - Parameter db: An open SQLite database pointer.
    static func initialize(db: OpaquePointer) {
        createTables(db: db)
        createIndices(db: db)
        runMigrations(db: db)
    }

    // MARK: - Table Creation

    private static func createTables(db: OpaquePointer) {
        let createEventsSQL = """
            CREATE TABLE IF NOT EXISTS events (
                id                  TEXT PRIMARY KEY,
                name                TEXT NOT NULL,
                base_date           TEXT NOT NULL,
                count_type          TEXT NOT NULL,
                phrase_template_id  TEXT NOT NULL,
                design_template_id  TEXT NOT NULL,
                layout_mode         TEXT NOT NULL,
                custom_phrase_mode  INTEGER NOT NULL DEFAULT 0,
                custom_single_line  TEXT,
                custom_line1        TEXT,
                custom_line2        TEXT,
                is_pinned           INTEGER NOT NULL DEFAULT 0,
                sort_order          INTEGER,
                last_used_at        TEXT,
                created_at          TEXT NOT NULL,
                updated_at          TEXT NOT NULL,
                is_archived         INTEGER NOT NULL DEFAULT 0
            );
            """

        let createSettingsSQL = """
            CREATE TABLE IF NOT EXISTS settings (
                key         TEXT PRIMARY KEY,
                value       TEXT NOT NULL,
                updated_at  TEXT NOT NULL
            );
            """

        let createSavedImagesSQL = """
            CREATE TABLE IF NOT EXISTS saved_images (
                id          TEXT PRIMARY KEY,
                event_id    TEXT NOT NULL,
                file_name   TEXT NOT NULL,
                created_at  TEXT NOT NULL,
                FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
            );
            """

        executeRaw(db: db, sql: createEventsSQL)
        executeRaw(db: db, sql: createSettingsSQL)
        executeRaw(db: db, sql: createSavedImagesSQL)
    }

    // MARK: - Index Creation

    private static func createIndices(db: OpaquePointer) {
        let indices = [
            "CREATE INDEX IF NOT EXISTS idx_events_is_archived ON events (is_archived);",
            "CREATE INDEX IF NOT EXISTS idx_events_is_pinned   ON events (is_pinned);",
            "CREATE INDEX IF NOT EXISTS idx_events_last_used   ON events (last_used_at);",
            "CREATE INDEX IF NOT EXISTS idx_events_updated     ON events (updated_at);",
            "CREATE INDEX IF NOT EXISTS idx_saved_images_event_id   ON saved_images (event_id);",
            "CREATE INDEX IF NOT EXISTS idx_saved_images_created_at ON saved_images (created_at);",
        ]

        for sql in indices {
            executeRaw(db: db, sql: sql)
        }
    }

    // MARK: - Migrations

    /// Runs any pending migrations by comparing the stored `user_version`
    /// against `currentVersion`.
    private static func runMigrations(db: OpaquePointer) {
        let storedVersion = getUserVersion(db: db)

        if storedVersion < currentVersion {
            for version in (storedVersion + 1)...currentVersion {
                if let migration = migrations[version] {
                    migration(db)
                }
            }
            setUserVersion(db: db, version: currentVersion)
        }
    }

    /// A registry of migration closures keyed by the schema version they target.
    /// Add new entries here when the schema changes.
    private static let migrations: [Int32: (OpaquePointer) -> Void] = [
        // Version 1 is the initial schema; tables are created in createTables().
        1: { _ in
            // No-op: baseline schema already handled by CREATE TABLE IF NOT EXISTS.
        },
        2: { db in
            executeRaw(db: db, sql: """
                CREATE TABLE IF NOT EXISTS saved_images (
                    id          TEXT PRIMARY KEY,
                    event_id    TEXT NOT NULL,
                    file_name   TEXT NOT NULL,
                    created_at  TEXT NOT NULL,
                    FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
                );
                """)
            executeRaw(db: db, sql: "CREATE INDEX IF NOT EXISTS idx_saved_images_event_id   ON saved_images (event_id);")
            executeRaw(db: db, sql: "CREATE INDEX IF NOT EXISTS idx_saved_images_created_at ON saved_images (created_at);")
        },
    ]

    // MARK: - Pragma Helpers

    private static func getUserVersion(db: OpaquePointer) -> Int32 {
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, "PRAGMA user_version;", -1, &stmt, nil) == SQLITE_OK else {
            return 0
        }

        if sqlite3_step(stmt) == SQLITE_ROW {
            return sqlite3_column_int(stmt, 0)
        }
        return 0
    }

    private static func setUserVersion(db: OpaquePointer, version: Int32) {
        executeRaw(db: db, sql: "PRAGMA user_version = \(version);")
    }

    // MARK: - Raw Execution Helper

    /// Executes a SQL statement directly on the given database pointer,
    /// bypassing the `AppDatabase` queue (used only during initialization
    /// which is already on the queue).
    private static func executeRaw(db: OpaquePointer, sql: String) {
        var errorPointer: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(db, sql, nil, nil, &errorPointer)

        if result != SQLITE_OK {
            let message: String
            if let errorPointer = errorPointer {
                message = String(cString: errorPointer)
                sqlite3_free(errorPointer)
            } else {
                message = "Unknown error"
            }
            assertionFailure("DatabaseInitializer SQL error: \(message)")
        }
    }
}
