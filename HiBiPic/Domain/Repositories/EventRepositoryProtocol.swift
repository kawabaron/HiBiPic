import Foundation

/// Protocol defining the contract for event persistence operations.
protocol EventRepositoryProtocol {
    /// Fetches all events matching the given criteria.
    /// - Parameters:
    ///   - isArchived: When `true`, returns archived events; when `false`, returns active events.
    ///   - sort: The column name to sort by (e.g. "updated_at", "sort_order", "last_used_at").
    /// - Returns: An array of `Event` domain models.
    func fetchAll(isArchived: Bool, sort: String) throws -> [Event]

    /// Fetches a single event by its unique identifier.
    /// - Parameter id: The event's unique ID.
    /// - Returns: The matching `Event`, or `nil` if not found.
    func fetchById(_ id: String) throws -> Event?

    /// Persists a new event.
    /// - Parameter event: The `Event` to create.
    func create(_ event: Event) throws

    /// Updates an existing event.
    /// - Parameter event: The `Event` with updated values.
    func update(_ event: Event) throws

    /// Permanently deletes an event.
    /// - Parameter id: The ID of the event to delete.
    func delete(id: String) throws

    /// Archives or unarchives an event.
    /// - Parameters:
    ///   - id: The event's unique ID.
    ///   - isArchived: `true` to archive, `false` to unarchive.
    func setArchived(id: String, isArchived: Bool) throws

    /// Pins or unpins an event.
    /// - Parameters:
    ///   - id: The event's unique ID.
    ///   - isPinned: `true` to pin, `false` to unpin.
    func setPinned(id: String, isPinned: Bool) throws

    /// Records that an event was used (updates `last_used_at` to now).
    /// - Parameter id: The event's unique ID.
    func markUsed(id: String) throws
}
