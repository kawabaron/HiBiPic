import Foundation
import SQLite3

// MARK: - DatabaseError

/// Errors thrown by the database layer.
enum DatabaseError: LocalizedError {
    case openFailed(String)
    case prepareFailed(String)
    case executeFailed(String)
    case bindFailed(String)
    case stepFailed(String)
    case notFound

    var errorDescription: String? {
        switch self {
        case .openFailed(let msg):   return "Database open failed: \(msg)"
        case .prepareFailed(let msg): return "SQL prepare failed: \(msg)"
        case .executeFailed(let msg): return "SQL execute failed: \(msg)"
        case .bindFailed(let msg):    return "Parameter bind failed: \(msg)"
        case .stepFailed(let msg):    return "SQL step failed: \(msg)"
        case .notFound:               return "Record not found"
        }
    }
}

// MARK: - AppDatabase

/// Thread-safe SQLite database manager.
///
/// All operations are dispatched onto a private serial queue to guarantee
/// single-writer / single-reader consistency. Callers may invoke any public
/// method from any thread.
final class AppDatabase {

    // MARK: - Singleton

    static let shared = AppDatabase()

    // MARK: - Private Properties

    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "com.hibipic.database", qos: .userInitiated)
    private let dbName = "hibipic.sqlite"

    // MARK: - Lifecycle

    private init() {
        queue.sync {
            openDatabase()
            guard let db = db else { return }
            DatabaseInitializer.initialize(db: db)
        }
    }

    deinit {
        close()
    }

    // MARK: - Open / Close

    /// Opens (or creates) the SQLite database file inside the app Documents directory.
    private func openDatabase() {
        let fileURL = documentsDatabaseURL()

        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        let result = sqlite3_open_v2(fileURL.path, &db, flags, nil)

        if result != SQLITE_OK {
            let msg = errorMessage()
            assertionFailure("Failed to open database: \(msg)")
            return
        }

        // Enable WAL mode for better concurrent read performance.
        sqlite3_exec(db, "PRAGMA journal_mode=WAL;", nil, nil, nil)
        // Enable foreign keys.
        sqlite3_exec(db, "PRAGMA foreign_keys=ON;", nil, nil, nil)
    }

    /// Closes the database connection. Safe to call multiple times.
    func close() {
        queue.sync {
            guard let db = db else { return }
            sqlite3_close_v2(db)
            self.db = nil
        }
    }

    // MARK: - Execute (no results)

    /// Executes a SQL statement that does not return rows (CREATE, INSERT, UPDATE, DELETE).
    /// - Parameters:
    ///   - sql: The SQL string.
    ///   - params: Ordered bind parameters.
    func execute(sql: String, params: [Any?] = []) throws {
        try queue.sync {
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }

            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw DatabaseError.prepareFailed(errorMessage())
            }

            try bindParameters(stmt: stmt!, params: params)

            let result = sqlite3_step(stmt)
            guard result == SQLITE_DONE else {
                throw DatabaseError.executeFailed(errorMessage())
            }
        }
    }

    // MARK: - Query (returns rows)

    /// Executes a SQL query and returns the result rows as an array of dictionaries.
    /// - Parameters:
    ///   - sql: The SELECT statement.
    ///   - params: Ordered bind parameters.
    /// - Returns: An array where each element is a `[String: Any]` mapping column names to values.
    func query(sql: String, params: [Any?] = []) throws -> [[String: Any]] {
        try queue.sync {
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }

            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw DatabaseError.prepareFailed(errorMessage())
            }

            try bindParameters(stmt: stmt!, params: params)

            var rows: [[String: Any]] = []
            while sqlite3_step(stmt) == SQLITE_ROW {
                rows.append(extractRow(stmt: stmt!))
            }
            return rows
        }
    }

    // MARK: - Insert (returns last row id)

    /// Inserts a row and returns `sqlite3_last_insert_rowid`.
    /// - Parameters:
    ///   - table: The target table name.
    ///   - values: A dictionary of column names to values.
    /// - Returns: The rowid of the newly inserted row.
    @discardableResult
    func insert(table: String, values: [String: Any?]) throws -> Int64 {
        let columns = values.keys.sorted()
        let placeholders = columns.map { _ in "?" }.joined(separator: ", ")
        let columnList = columns.joined(separator: ", ")
        let sql = "INSERT INTO \(table) (\(columnList)) VALUES (\(placeholders))"
        let params = columns.map { values[$0] ?? nil }

        return try queue.sync {
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }

            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw DatabaseError.prepareFailed(errorMessage())
            }

            try bindParameters(stmt: stmt!, params: params)

            let result = sqlite3_step(stmt)
            guard result == SQLITE_DONE else {
                throw DatabaseError.executeFailed(errorMessage())
            }
            return sqlite3_last_insert_rowid(db)
        }
    }

    // MARK: - Update

    /// Updates rows in the specified table.
    /// - Parameters:
    ///   - table: The target table name.
    ///   - values: A dictionary of column names to new values.
    ///   - whereClause: The WHERE clause (without the keyword WHERE).
    ///   - whereArgs: Bind parameters for the WHERE clause.
    /// - Returns: The number of rows affected.
    @discardableResult
    func update(
        table: String,
        values: [String: Any?],
        where whereClause: String,
        whereArgs: [Any?] = []
    ) throws -> Int {
        let columns = values.keys.sorted()
        let setClause = columns.map { "\($0) = ?" }.joined(separator: ", ")
        let sql = "UPDATE \(table) SET \(setClause) WHERE \(whereClause)"
        let params: [Any?] = columns.map { values[$0] ?? nil } + whereArgs

        return try queue.sync {
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }

            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw DatabaseError.prepareFailed(errorMessage())
            }

            try bindParameters(stmt: stmt!, params: params)

            let result = sqlite3_step(stmt)
            guard result == SQLITE_DONE else {
                throw DatabaseError.executeFailed(errorMessage())
            }
            return Int(sqlite3_changes(db))
        }
    }

    // MARK: - Helpers

    /// Returns the URL for the database file inside the app Documents directory.
    private func documentsDatabaseURL() -> URL {
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        return documentsURL.appendingPathComponent(dbName)
    }

    /// Returns the last SQLite error message, or a fallback string.
    private func errorMessage() -> String {
        if let msg = sqlite3_errmsg(db) {
            return String(cString: msg)
        }
        return "Unknown database error"
    }

    /// Binds an ordered array of parameters to a prepared statement.
    /// Supports String, Int, Int64, Double, Bool, Data, and nil (NSNull).
    private func bindParameters(stmt: OpaquePointer, params: [Any?]) throws {
        for (index, param) in params.enumerated() {
            let position = Int32(index + 1)
            let result: Int32

            switch param {
            case nil, is NSNull:
                result = sqlite3_bind_null(stmt, position)

            case let value as String:
                result = sqlite3_bind_text(
                    stmt, position,
                    (value as NSString).utf8String,
                    -1,
                    unsafeBitCast(-1, to: sqlite3_destructor_type.self)
                )

            case let value as Int:
                result = sqlite3_bind_int64(stmt, position, Int64(value))

            case let value as Int64:
                result = sqlite3_bind_int64(stmt, position, value)

            case let value as Double:
                result = sqlite3_bind_double(stmt, position, value)

            case let value as Bool:
                result = sqlite3_bind_int(stmt, position, value ? 1 : 0)

            case let value as Data:
                result = value.withUnsafeBytes { rawBuffer in
                    sqlite3_bind_blob(
                        stmt, position,
                        rawBuffer.baseAddress,
                        Int32(value.count),
                        unsafeBitCast(-1, to: sqlite3_destructor_type.self)
                    )
                }

            default:
                let str = String(describing: param!)
                result = sqlite3_bind_text(
                    stmt, position,
                    (str as NSString).utf8String,
                    -1,
                    unsafeBitCast(-1, to: sqlite3_destructor_type.self)
                )
            }

            guard result == SQLITE_OK else {
                throw DatabaseError.bindFailed(
                    "Failed to bind parameter at index \(index): \(errorMessage())"
                )
            }
        }
    }

    /// Extracts all columns from the current row of a stepped statement into a dictionary.
    private func extractRow(stmt: OpaquePointer) -> [String: Any] {
        let columnCount = sqlite3_column_count(stmt)
        var row: [String: Any] = [:]

        for i in 0..<columnCount {
            let name = String(cString: sqlite3_column_name(stmt, i))
            let type = sqlite3_column_type(stmt, i)

            switch type {
            case SQLITE_INTEGER:
                row[name] = Int(sqlite3_column_int64(stmt, i))
            case SQLITE_FLOAT:
                row[name] = sqlite3_column_double(stmt, i)
            case SQLITE_TEXT:
                if let cString = sqlite3_column_text(stmt, i) {
                    row[name] = String(cString: cString)
                }
            case SQLITE_BLOB:
                if let bytes = sqlite3_column_blob(stmt, i) {
                    let count = Int(sqlite3_column_bytes(stmt, i))
                    row[name] = Data(bytes: bytes, count: count)
                }
            case SQLITE_NULL:
                // Omit NULL values; callers check for key presence.
                break
            default:
                break
            }
        }

        return row
    }
}
