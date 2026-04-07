import Foundation

// MARK: - SavedImage

struct SavedImage: Identifiable, Equatable {
    let id: String
    let eventId: String
    let fileName: String
    let createdAt: String // ISO8601

    init(
        id: String = UUID().uuidString,
        eventId: String,
        fileName: String,
        createdAt: String? = nil
    ) {
        self.id = id
        self.eventId = eventId
        self.fileName = fileName
        self.createdAt = createdAt ?? ISO8601DateFormatter().string(from: Date())
    }
}
