import Foundation

/// Concrete implementation of `SavedImageRepositoryProtocol` backed by SQLite.
final class SavedImageRepositoryImpl: SavedImageRepositoryProtocol {

    private let dataSource: SavedImageLocalDataSource

    init(dataSource: SavedImageLocalDataSource = SavedImageLocalDataSource()) {
        self.dataSource = dataSource
    }

    // MARK: - Fetch All

    func fetchAll() throws -> [SavedImage] {
        let rows = try dataSource.selectAll()
        return rows.map { SavedImageMapper.toDomain($0) }
    }

    // MARK: - Fetch by Event ID

    func fetchByEventId(_ eventId: String) throws -> [SavedImage] {
        let rows = try dataSource.selectByEventId(eventId: eventId)
        return rows.map { SavedImageMapper.toDomain($0) }
    }

    // MARK: - Fetch by Date Range

    func fetchByDateRange(from: String, to: String) throws -> [SavedImage] {
        let rows = try dataSource.selectByDateRange(from: from, to: to)
        return rows.map { SavedImageMapper.toDomain($0) }
    }

    // MARK: - Create

    func create(_ image: SavedImage) throws {
        let row = SavedImageMapper.toRow(image)
        try dataSource.insert(row: row)
    }

    // MARK: - Delete

    func delete(id: String) throws {
        try dataSource.deleteById(id: id)
    }

    // MARK: - Delete by Event ID

    func deleteByEventId(_ eventId: String) throws {
        try dataSource.deleteByEventId(eventId: eventId)
    }

    // MARK: - Count

    func count() throws -> Int {
        try dataSource.count()
    }

    // MARK: - Count by Event ID

    func countByEventId(_ eventId: String) throws -> Int {
        try dataSource.countByEventId(eventId: eventId)
    }
}
