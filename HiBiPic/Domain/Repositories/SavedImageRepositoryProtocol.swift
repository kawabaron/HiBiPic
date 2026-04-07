import Foundation

/// Protocol defining the contract for saved image persistence operations.
protocol SavedImageRepositoryProtocol {
    /// Fetches all saved images, newest first.
    func fetchAll() throws -> [SavedImage]

    /// Fetches saved images for a specific event, newest first.
    func fetchByEventId(_ eventId: String) throws -> [SavedImage]

    /// Fetches saved images created within a date range (ISO8601 strings).
    func fetchByDateRange(from: String, to: String) throws -> [SavedImage]

    /// Persists a new saved image record.
    func create(_ image: SavedImage) throws

    /// Deletes a saved image record by ID.
    func delete(id: String) throws

    /// Deletes all saved image records for a given event.
    func deleteByEventId(_ eventId: String) throws

    /// Returns the total number of saved images.
    func count() throws -> Int

    /// Returns the number of saved images for a given event.
    func countByEventId(_ eventId: String) throws -> Int
}
