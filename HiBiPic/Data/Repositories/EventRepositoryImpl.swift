import Foundation

/// Concrete implementation of `EventRepositoryProtocol` backed by SQLite.
final class EventRepositoryImpl: EventRepositoryProtocol {

    private let dataSource: EventLocalDataSource

    init(dataSource: EventLocalDataSource = EventLocalDataSource()) {
        self.dataSource = dataSource
    }

    // MARK: - Fetch All

    func fetchAll(isArchived: Bool, sort: String) throws -> [Event] {
        let rows = try dataSource.selectAll(isArchived: isArchived, sort: sort)
        return rows.map { EventMapper.toDomain($0) }
    }

    // MARK: - Fetch by ID

    func fetchById(_ id: String) throws -> Event? {
        guard let row = try dataSource.selectById(id: id) else { return nil }
        return EventMapper.toDomain(row)
    }

    // MARK: - Create

    func create(_ event: Event) throws {
        let row = EventMapper.toRow(event)
        try dataSource.insert(row: row)
    }

    // MARK: - Update

    func update(_ event: Event) throws {
        let row = EventMapper.toRow(event)
        try dataSource.update(row: row)
    }

    // MARK: - Delete

    func delete(id: String) throws {
        try dataSource.deleteById(id: id)
    }

    // MARK: - Archive / Unarchive

    func setArchived(id: String, isArchived: Bool) throws {
        try dataSource.updateField(id: id, field: "is_archived", value: isArchived ? 1 : 0)
    }

    // MARK: - Pin / Unpin

    func setPinned(id: String, isPinned: Bool) throws {
        try dataSource.updateField(id: id, field: "is_pinned", value: isPinned ? 1 : 0)
    }

    // MARK: - Mark Used

    func markUsed(id: String) throws {
        let now = ISO8601DateFormatter().string(from: Date())
        try dataSource.updateField(id: id, field: "last_used_at", value: now)
    }
}
