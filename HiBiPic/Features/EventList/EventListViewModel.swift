import Foundation
import Observation

// MARK: - EventListViewModel

/// Drives the event list screen: loading, sorting, pin/archive/delete operations.
@Observable
final class EventListViewModel {

    // MARK: - Published State

    /// The currently visible (non-archived) events.
    var events: [Event] = []

    /// Active sort strategy.
    var sortType: EventSortType = .pinnedThenRecent

    /// `true` while the initial load is in progress.
    var isLoading = false

    /// Non-nil when an error should be surfaced to the user.
    var errorMessage: String?

    /// Controls the delete-confirmation alert.
    var showDeleteConfirm = false

    /// The event that will be deleted when the user confirms.
    var eventToDelete: Event?

    // MARK: - Computed Helpers

    /// All pinned events in the current list.
    var pinnedEvents: [Event] {
        events.filter { $0.isPinned }
    }

    /// All non-pinned events in the current list.
    var unpinnedEvents: [Event] {
        events.filter { !$0.isPinned }
    }

    /// `true` when there are no events at all.
    var isEmpty: Bool {
        events.isEmpty && !isLoading
    }

    // MARK: - Dependencies

    private let repository: EventRepositoryProtocol

    // MARK: - Init

    init(repository: EventRepositoryProtocol = EventRepositoryImpl()) {
        self.repository = repository
    }

    // MARK: - Data Loading

    /// Fetches all active (non-archived) events from the repository.
    func loadEvents() {
        isLoading = true
        errorMessage = nil

        do {
            events = try repository.fetchAll(
                isArchived: false,
                sort: sortType.sortColumn
            )
        } catch {
            errorMessage = "イベントの読み込みに失敗しました"
        }

        isLoading = false
    }

    // MARK: - Pin / Unpin

    /// Toggles the pinned state of the given event and reloads.
    func togglePin(event: Event) {
        do {
            try repository.setPinned(id: event.id, isPinned: !event.isPinned)
            loadEvents()
        } catch {
            errorMessage = "ピン留めの変更に失敗しました"
        }
    }

    // MARK: - Archive

    /// Archives the given event (moves it out of the active list).
    func archiveEvent(event: Event) {
        do {
            try repository.setArchived(id: event.id, isArchived: true)
            loadEvents()
        } catch {
            errorMessage = "アーカイブに失敗しました"
        }
    }

    // MARK: - Delete

    /// Stages the event for deletion and shows the confirmation alert.
    func deleteEvent(event: Event) {
        eventToDelete = event
        showDeleteConfirm = true
    }

    /// Called when the user confirms deletion in the alert.
    func confirmDelete() {
        guard let event = eventToDelete else { return }

        do {
            try repository.delete(id: event.id)
            eventToDelete = nil
            loadEvents()
        } catch {
            errorMessage = "削除に失敗しました"
        }
    }

    // MARK: - Mark Used

    /// Records that an event was just used (updates `lastUsedAt`).
    func markUsed(event: Event) {
        do {
            try repository.markUsed(id: event.id)
            loadEvents()
        } catch {
            // Non-critical; silently ignore.
        }
    }

    // MARK: - Sort

    /// Changes the sort strategy and reloads.
    func changeSortType(_ type: EventSortType) {
        guard sortType != type else { return }
        sortType = type
        loadEvents()
    }
}
