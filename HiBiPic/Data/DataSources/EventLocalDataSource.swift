import Foundation

// MARK: - EventRow

/// A flat struct mirroring every column in the `events` table.
/// All types are raw SQL-compatible (String, Int, Optional variants).
struct EventRow {
    let id: String
    let name: String
    let baseDate: String
    let countType: String
    let phraseTemplateId: String
    let designTemplateId: String
    let fontPreset: String
    let layoutMode: String
    let customPhraseMode: Int
    let customSingleLine: String?
    let customLine1: String?
    let customLine2: String?
    let customLine3: String?
    let editorPreferencesJSON: String?
    let isPinned: Int
    let sortOrder: Int?
    let lastUsedAt: String?
    let createdAt: String
    let updatedAt: String
    let isArchived: Int
}

// MARK: - EventLocalDataSource

/// Provides direct SQL access to the `events` table.
final class EventLocalDataSource {

    private let db: AppDatabase

    init(db: AppDatabase = .shared) {
        self.db = db
    }

    // MARK: - Insert

    func insert(row: EventRow) throws {
        try db.insert(table: "events", values: row.toDictionary())
    }

    // MARK: - Update

    func update(row: EventRow) throws {
        try db.update(
            table: "events",
            values: row.toDictionary(),
            where: "id = ?",
            whereArgs: [row.id]
        )
    }

    // MARK: - Delete

    func deleteById(id: String) throws {
        try db.execute(sql: "DELETE FROM events WHERE id = ?", params: [id])
    }

    // MARK: - Select by ID

    func selectById(id: String) throws -> EventRow? {
        let rows = try db.query(
            sql: "SELECT * FROM events WHERE id = ?",
            params: [id]
        )
        return rows.first.flatMap { EventRow(from: $0) }
    }

    // MARK: - Select All

    /// Returns all events matching the archive state, sorted by the given column.
    /// - Parameters:
    ///   - isArchived: Filter by archived state.
    ///   - sort: Column name to sort by (e.g. "updated_at", "sort_order", "last_used_at").
    ///           Defaults to descending order.
    func selectAll(isArchived: Bool, sort: String = "updated_at") throws -> [EventRow] {
        // Whitelist sort columns to prevent SQL injection.
        let allowedSorts: Set<String> = [
            "updated_at", "created_at", "sort_order",
            "last_used_at", "name", "base_date",
        ]
        let safeSort = allowedSorts.contains(sort) ? sort : "updated_at"

        let sql = """
            SELECT * FROM events
            WHERE is_archived = ?
            ORDER BY is_pinned DESC, \(safeSort) DESC
            """

        let rows = try db.query(sql: sql, params: [isArchived ? 1 : 0])
        return rows.compactMap { EventRow(from: $0) }
    }

    // MARK: - Update Single Field

    /// Updates a single column for a given event.
    /// - Parameters:
    ///   - id: The event identifier.
    ///   - field: The column name to update (whitelisted).
    ///   - value: The new value.
    func updateField(id: String, field: String, value: Any?) throws {
        // Whitelist to prevent SQL injection via field name.
        let allowedFields: Set<String> = [
            "name", "base_date", "count_type", "phrase_template_id",
            "design_template_id", "font_preset", "layout_mode", "custom_phrase_mode",
            "custom_single_line", "custom_line1", "custom_line2", "custom_line3",
            "editor_preferences_json",
            "is_pinned", "sort_order", "last_used_at",
            "updated_at", "is_archived",
        ]
        guard allowedFields.contains(field) else {
            throw DatabaseError.executeFailed("Field '\(field)' is not allowed for update")
        }

        let now = ISO8601DateFormatter().string(from: Date())
        try db.execute(
            sql: "UPDATE events SET \(field) = ?, updated_at = ? WHERE id = ?",
            params: [value, now, id]
        )
    }
}

// MARK: - EventRow + Dictionary Conversion

private extension EventRow {

    /// Converts the row to a dictionary suitable for `AppDatabase.insert` / `update`.
    func toDictionary() -> [String: Any?] {
        [
            "id": id,
            "name": name,
            "base_date": baseDate,
            "count_type": countType,
            "phrase_template_id": phraseTemplateId,
            "design_template_id": designTemplateId,
            "font_preset": fontPreset,
            "layout_mode": layoutMode,
            "custom_phrase_mode": customPhraseMode,
            "custom_single_line": customSingleLine,
            "custom_line1": customLine1,
            "custom_line2": customLine2,
            "custom_line3": customLine3,
            "editor_preferences_json": editorPreferencesJSON,
            "is_pinned": isPinned,
            "sort_order": sortOrder,
            "last_used_at": lastUsedAt,
            "created_at": createdAt,
            "updated_at": updatedAt,
            "is_archived": isArchived,
        ]
    }

    /// Initializes an `EventRow` from a database result dictionary.
    init?(from dict: [String: Any]) {
        guard
            let id = dict["id"] as? String,
            let name = dict["name"] as? String,
            let baseDate = dict["base_date"] as? String,
            let countType = dict["count_type"] as? String,
            let phraseTemplateId = dict["phrase_template_id"] as? String,
            let designTemplateId = dict["design_template_id"] as? String,
            let fontPreset = dict["font_preset"] as? String,
            let layoutMode = dict["layout_mode"] as? String,
            let customPhraseMode = dict["custom_phrase_mode"] as? Int,
            let isPinned = dict["is_pinned"] as? Int,
            let createdAt = dict["created_at"] as? String,
            let updatedAt = dict["updated_at"] as? String,
            let isArchived = dict["is_archived"] as? Int
        else {
            return nil
        }

        self.id = id
        self.name = name
        self.baseDate = baseDate
        self.countType = countType
        self.phraseTemplateId = phraseTemplateId
        self.designTemplateId = designTemplateId
        self.fontPreset = fontPreset
        self.layoutMode = layoutMode
        self.customPhraseMode = customPhraseMode
        self.customSingleLine = dict["custom_single_line"] as? String
        self.customLine1 = dict["custom_line1"] as? String
        self.customLine2 = dict["custom_line2"] as? String
        self.customLine3 = dict["custom_line3"] as? String
        self.editorPreferencesJSON = dict["editor_preferences_json"] as? String
        self.isPinned = isPinned
        self.sortOrder = dict["sort_order"] as? Int
        self.lastUsedAt = dict["last_used_at"] as? String
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }
}
