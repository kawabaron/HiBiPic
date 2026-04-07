import SwiftUI

// MARK: - EventCardView

/// A single event card for the event list.
///
/// Layout:
/// ```
/// ┌─────────────────────────────────────────┐
/// │  ● Event Name                      📌   │
/// │    あと30日                              │
/// │    2025-01-15                            │
/// └─────────────────────────────────────────┘
/// ```
struct EventCardView: View {

    // MARK: - Properties

    let event: Event

    /// Called when the user taps the card.
    var onTap: () -> Void

    // MARK: - Body

    var body: some View {
        DSTappableCard(action: onTap) {
            HStack(alignment: .center, spacing: DSSpacing.md) {
                templateIndicator

                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    nameRow
                    countLabel
                    dateLabel
                }

                Spacer(minLength: 0)

                if event.isPinned {
                    pinBadge
                }
            }
        }
    }

    // MARK: - Template Indicator Dot

    /// A small coloured dot reflecting the event's design template.
    private var templateIndicator: some View {
        Circle()
            .fill(indicatorColor)
            .frame(width: 8, height: 8)
    }

    // MARK: - Name Row

    private var nameRow: some View {
        Text(event.name)
            .font(DSTypography.headline)
            .foregroundStyle(DSColors.textPrimary)
            .lineLimit(1)
    }

    // MARK: - Count Label

    /// Displays the day count with the appropriate suffix for the count type.
    private var countLabel: some View {
        Text(formattedCount)
            .font(DSTypography.title2)
            .foregroundStyle(DSColors.accent)
    }

    // MARK: - Date Label

    private var dateLabel: some View {
        Text(formattedBaseDate)
            .font(DSTypography.caption)
            .foregroundStyle(DSColors.textTertiary)
    }

    // MARK: - Pin Badge

    private var pinBadge: some View {
        Image(systemName: "pin.fill")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(DSColors.textTertiary)
    }

    // MARK: - Computed Helpers

    /// The colour for the leading indicator dot, derived from the design template.
    private var indicatorColor: Color {
        switch event.designTemplateId {
        case .minimal: return DSColors.textSecondary
        case .soft:    return Color(hex: "D4A054")   // warm amber
        case .film:    return Color(hex: "8B7355")   // film brown
        case .poster:  return DSColors.accent
        }
    }

    /// Human-readable day-count string based on count type.
    private var formattedCount: String {
        let days = DateCalculator.calculateDays(
            baseDate: event.baseDate,
            countType: event.countType
        )

        switch event.countType {
        case .countdown:
            return days == 0 ? "当日" : "あと\(days)日"
        case .elapsed:
            return "\(days)日経過"
        case .daycount:
            return "\(days)日目"
        }
    }

    /// Converts the stored "YYYY-MM-DD" string into a friendlier "YYYY年M月D日" label.
    private var formattedBaseDate: String {
        guard let date = DateCalculator.baseDateFromString(event.baseDate) else {
            return event.baseDate
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview("Event Card") {
    VStack(spacing: DSSpacing.lg) {
        EventCardView(
            event: Event(
                name: "誕生日",
                baseDate: "2025-06-15",
                countType: .countdown,
                designTemplateId: .soft,
                isPinned: true
            )
        ) {}

        EventCardView(
            event: Event(
                name: "付き合い始めた日",
                baseDate: "2023-03-01",
                countType: .daycount,
                designTemplateId: .film
            )
        ) {}

        EventCardView(
            event: Event(
                name: "卒業式",
                baseDate: "2024-03-20",
                countType: .elapsed,
                designTemplateId: .minimal
            )
        ) {}
    }
    .padding(DSSpacing.xl)
    .background(DSColors.background)
}
