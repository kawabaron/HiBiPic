import Foundation

// MARK: - EventSortType

/// Defines the available sorting strategies for event lists.
enum EventSortType: CaseIterable {

    /// Pinned events first, then by most-recently-used.
    case pinnedThenRecent

    /// Newest first by creation date.
    case createdDesc

    /// Most-recently-updated first.
    case updatedDesc

    /// Alphabetical by name (A-Z / あ-ん).
    case nameAsc

    // MARK: - Display

    /// Localised label shown in the sort picker.
    var displayName: String {
        switch self {
        case .pinnedThenRecent: return L10n.t("ピン留め優先")
        case .createdDesc:     return L10n.t("作成日（新しい順）")
        case .updatedDesc:     return L10n.t("更新日（新しい順）")
        case .nameAsc:         return L10n.t("名前順")
        }
    }

    /// The SF Symbol name used next to the label.
    var iconName: String {
        switch self {
        case .pinnedThenRecent: return "pin.fill"
        case .createdDesc:     return "calendar.badge.plus"
        case .updatedDesc:     return "clock.arrow.circlepath"
        case .nameAsc:         return "textformat.abc"
        }
    }

    // MARK: - Repository Mapping

    /// The raw sort column string expected by the repository layer.
    var sortColumn: String {
        switch self {
        case .pinnedThenRecent: return "is_pinned DESC, last_used_at DESC, updated_at DESC"
        case .createdDesc:     return "created_at DESC"
        case .updatedDesc:     return "updated_at DESC"
        case .nameAsc:         return "name ASC"
        }
    }
}
