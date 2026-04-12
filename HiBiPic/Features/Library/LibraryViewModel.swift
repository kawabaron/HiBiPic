import Foundation
import UIKit

// MARK: - LibraryViewMode

enum LibraryViewMode: String, CaseIterable {
    case grid
    case calendar

    var displayLabel: String {
        switch self {
        case .grid:     return L10n.t("グリッド")
        case .calendar: return L10n.t("カレンダー")
        }
    }
}

enum SavedImageEditorPreparationResult {
    case ready(EditorViewModel)
    case failed(String)
}

// MARK: - LibraryViewModel

@Observable
final class LibraryViewModel {

    // MARK: - State

    var images: [SavedImage] = []
    var viewMode: LibraryViewMode = .calendar
    var selectedMonth: Date = Date()
    var errorMessage: String?

    // Filter
    var filteredEventId: String?
    var filteredEvent: Event?

    // MARK: - Dependencies

    private let savedImageRepo: SavedImageRepositoryProtocol
    private let eventRepo: EventRepositoryProtocol

    // MARK: - Init

    init(
        eventId: String? = nil,
        savedImageRepo: SavedImageRepositoryProtocol = AppDependencies.shared.savedImageRepository,
        eventRepo: EventRepositoryProtocol = AppDependencies.shared.eventRepository
    ) {
        self.filteredEventId = eventId
        self.savedImageRepo = savedImageRepo
        self.eventRepo = eventRepo
    }

    // MARK: - Load

    func loadImages() {
        do {
            if let eventId = filteredEventId {
                images = try savedImageRepo.fetchByEventId(eventId)
                filteredEvent = try eventRepo.fetchById(eventId)
            } else {
                images = try savedImageRepo.fetchAll()
            }
            errorMessage = nil
        } catch {
            errorMessage = L10n.t("画像の読み込みに失敗しました")
        }
    }

    // MARK: - Delete

    func deleteImage(_ image: SavedImage) {
        do {
            try savedImageRepo.delete(id: image.id)
            ImageFileStorage.shared.deleteImage(fileName: image.fileName)
            if let originalFileName = image.originalFileName {
                ImageFileStorage.shared.deleteOriginalImage(fileName: originalFileName)
            }
            images.removeAll { $0.id == image.id }
        } catch {
            errorMessage = L10n.t("画像の削除に失敗しました")
        }
    }

    func prepareEditor(for image: SavedImage) -> SavedImageEditorPreparationResult {
        if let recipe = image.editRecipe,
           let originalFileName = image.originalFileName,
           let originalImage = ImageFileStorage.shared.loadOriginalImage(fileName: originalFileName) {
            let snapshotEvent = recipe.makeSnapshotEvent(eventId: image.eventId)
            return .ready(
                EditorViewModel(
                    image: originalImage,
                    event: snapshotEvent,
                    restoredRecipe: recipe
                )
            )
        }

        guard let renderedImage = ImageFileStorage.shared.loadImage(fileName: image.fileName) else {
            return .failed(L10n.t("画像ファイルの読み込みに失敗しました"))
        }

        if let event = resolveEvent(for: image) {
            return .ready(EditorViewModel(image: renderedImage, event: event))
        }

        if let recipe = image.editRecipe {
            return .ready(
                EditorViewModel(
                    image: renderedImage,
                    event: recipe.makeSnapshotEvent(eventId: image.eventId)
                )
            )
        }

        return .failed(L10n.t("関連するイベント情報の読み込みに失敗しました"))
    }

    // MARK: - Calendar Helpers

    /// Returns all events (non-archived) that have base dates in the given month.
    func eventsInMonth(_ month: Date) -> [Event] {
        let calendar = Calendar(identifier: .gregorian)
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else { return [] }

        do {
            let allEvents = try eventRepo.fetchAll(isArchived: false, sort: "base_date")
            return allEvents.filter { event in
                guard let eventDate = DateCalculator.baseDateFromString(event.baseDate) else { return false }
                let eventDay = calendar.startOfDay(for: eventDate)
                let monthStart = calendar.startOfDay(for: firstDay)
                guard let monthEnd = calendar.date(byAdding: .day, value: range.count, to: monthStart) else { return false }
                return eventDay >= monthStart && eventDay < monthEnd
            }
        } catch {
            return []
        }
    }

    /// Returns images created on a specific date (YYYY-MM-DD).
    func imagesForDate(_ dateString: String) -> [SavedImage] {
        images.filter { image in
            localCreatedDateString(for: image) == dateString
        }
    }

    /// Returns images created in the given month.
    func imagesInMonth(_ month: Date) -> [SavedImage] {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month], from: month)
        let prefix = String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
        return images.filter { image in
            localCreatedDateString(for: image)?.hasPrefix(prefix) == true
        }
    }

    // MARK: - Month Navigation

    func previousMonth() {
        if let prev = Calendar(identifier: .gregorian).date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = prev
        }
    }

    func nextMonth() {
        if let next = Calendar(identifier: .gregorian).date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = next
        }
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = AppLocalizer.currentLanguage.locale
        formatter.setLocalizedDateFormatFromTemplate("yMMMM")
        return formatter.string(from: selectedMonth)
    }

    private func resolveEvent(for image: SavedImage) -> Event? {
        if filteredEvent?.id == image.eventId {
            return filteredEvent
        }

        do {
            return try eventRepo.fetchById(image.eventId)
        } catch {
            return nil
        }
    }

    private func localCreatedDateString(for image: SavedImage) -> String? {
        if let dateString = DateCalculator.localDateString(fromISO8601: image.createdAt) {
            return dateString
        }

        let prefix = String(image.createdAt.prefix(10))
        return DateCalculator.baseDateFromString(prefix) == nil ? nil : prefix
    }
}
