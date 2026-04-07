import Foundation

/// Bidirectional mapper between the persistence layer (`EventRow`) and
/// the domain layer (`Event`).
enum EventMapper {

    // MARK: - Row -> Domain

    /// Converts a database row to a domain model.
    static func toDomain(_ row: EventRow) -> Event {
        Event(
            id: row.id,
            name: row.name,
            baseDate: row.baseDate,
            countType: CountType(rawValue: row.countType) ?? .elapsed,
            phraseTemplateId: row.phraseTemplateId,
            designTemplateId: DesignTemplateType(rawValue: row.designTemplateId) ?? .minimal,
            layoutMode: LayoutMode(rawValue: row.layoutMode) ?? .single,
            customPhraseMode: row.customPhraseMode != 0,
            customSingleLine: row.customSingleLine,
            customLine1: row.customLine1,
            customLine2: row.customLine2,
            isPinned: row.isPinned != 0,
            sortOrder: row.sortOrder,
            lastUsedAt: row.lastUsedAt,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
            isArchived: row.isArchived != 0
        )
    }

    // MARK: - Domain -> Row

    /// Converts a domain model to a database row.
    static func toRow(_ event: Event) -> EventRow {
        EventRow(
            id: event.id,
            name: event.name,
            baseDate: event.baseDate,
            countType: event.countType.rawValue,
            phraseTemplateId: event.phraseTemplateId,
            designTemplateId: event.designTemplateId.rawValue,
            layoutMode: event.layoutMode.rawValue,
            customPhraseMode: event.customPhraseMode ? 1 : 0,
            customSingleLine: event.customSingleLine,
            customLine1: event.customLine1,
            customLine2: event.customLine2,
            isPinned: event.isPinned ? 1 : 0,
            sortOrder: event.sortOrder,
            lastUsedAt: event.lastUsedAt,
            createdAt: event.createdAt,
            updatedAt: event.updatedAt,
            isArchived: event.isArchived ? 1 : 0
        )
    }
}
