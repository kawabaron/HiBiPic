import Foundation

/// Bidirectional mapper between the persistence layer (`SavedImageRow`) and
/// the domain layer (`SavedImage`).
enum SavedImageMapper {

    // MARK: - Row -> Domain

    static func toDomain(_ row: SavedImageRow) -> SavedImage {
        SavedImage(
            id: row.id,
            eventId: row.eventId,
            fileName: row.fileName,
            createdAt: row.createdAt
        )
    }

    // MARK: - Domain -> Row

    static func toRow(_ image: SavedImage) -> SavedImageRow {
        SavedImageRow(
            id: image.id,
            eventId: image.eventId,
            fileName: image.fileName,
            createdAt: image.createdAt
        )
    }
}
