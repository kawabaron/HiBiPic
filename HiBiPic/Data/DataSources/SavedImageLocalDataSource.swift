import Foundation

// MARK: - SavedImageRow

/// A flat struct mirroring every column in the `saved_images` table.
struct SavedImageRow {
    let id: String
    let eventId: String
    let fileName: String
    let originalFileName: String?
    let editRecipeJSON: String?
    let createdAt: String
}

// MARK: - SavedImageLocalDataSource

/// Provides direct SQL access to the `saved_images` table.
final class SavedImageLocalDataSource {

    private let db: AppDatabase

    init(db: AppDatabase = .shared) {
        self.db = db
    }

    // MARK: - Insert

    func insert(row: SavedImageRow) throws {
        try db.insert(table: "saved_images", values: row.toDictionary())
    }

    // MARK: - Delete

    func deleteById(id: String) throws {
        try db.execute(sql: "DELETE FROM saved_images WHERE id = ?", params: [id])
    }

    func deleteByEventId(eventId: String) throws {
        try db.execute(sql: "DELETE FROM saved_images WHERE event_id = ?", params: [eventId])
    }

    // MARK: - Select All

    func selectAll() throws -> [SavedImageRow] {
        let rows = try db.query(
            sql: "SELECT * FROM saved_images ORDER BY created_at DESC"
        )
        return rows.compactMap { SavedImageRow(from: $0) }
    }

    // MARK: - Select by Event ID

    func selectByEventId(eventId: String) throws -> [SavedImageRow] {
        let rows = try db.query(
            sql: "SELECT * FROM saved_images WHERE event_id = ? ORDER BY created_at DESC",
            params: [eventId]
        )
        return rows.compactMap { SavedImageRow(from: $0) }
    }

    // MARK: - Select by Date Range

    func selectByDateRange(from: String, to: String) throws -> [SavedImageRow] {
        let rows = try db.query(
            sql: "SELECT * FROM saved_images WHERE created_at >= ? AND created_at <= ? ORDER BY created_at DESC",
            params: [from, to]
        )
        return rows.compactMap { SavedImageRow(from: $0) }
    }

    // MARK: - Count

    func count() throws -> Int {
        let rows = try db.query(sql: "SELECT COUNT(*) as cnt FROM saved_images")
        return (rows.first?["cnt"] as? Int) ?? 0
    }

    func countByEventId(eventId: String) throws -> Int {
        let rows = try db.query(
            sql: "SELECT COUNT(*) as cnt FROM saved_images WHERE event_id = ?",
            params: [eventId]
        )
        return (rows.first?["cnt"] as? Int) ?? 0
    }
}

// MARK: - SavedImageRow + Dictionary Conversion

private extension SavedImageRow {

    func toDictionary() -> [String: Any?] {
        [
            "id": id,
            "event_id": eventId,
            "file_name": fileName,
            "original_file_name": originalFileName,
            "edit_recipe_json": editRecipeJSON,
            "created_at": createdAt,
        ]
    }

    init?(from dict: [String: Any]) {
        guard
            let id = dict["id"] as? String,
            let eventId = dict["event_id"] as? String,
            let fileName = dict["file_name"] as? String,
            let createdAt = dict["created_at"] as? String
        else {
            return nil
        }

        self.id = id
        self.eventId = eventId
        self.fileName = fileName
        self.originalFileName = dict["original_file_name"] as? String
        self.editRecipeJSON = dict["edit_recipe_json"] as? String
        self.createdAt = createdAt
    }
}
