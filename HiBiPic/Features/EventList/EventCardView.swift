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
        case .classic: return Color(hex: "BFA889")
        case .diary: return Color(hex: "D69B6F")
        case .cleanLabel: return Color(hex: "8FA3B0")
        case .memory: return Color(hex: "C9B28A")
        case .milestone: return Color(hex: "6DA6B8")
        case .airy: return Color(hex: "9BCBB8")
        }
    }

    /// Human-readable day-count string based on count type.
    private var formattedCount: String {
        let days = DateCalculator.calculateDays(
            baseDate: event.baseDate,
            countType: event.countType
        )

        switch event.countType {
        case .countdown, .elapsed, .daycount:
            return LocalizedDayCountFormatter.string(days: days, countType: event.countType)
        }
    }

    /// Converts the stored "YYYY-MM-DD" string into a friendlier "YYYY年M月D日" label.
    private var formattedBaseDate: String {
        guard let date = DateCalculator.baseDateFromString(event.baseDate) else {
            return event.baseDate
        }

        let formatter = DateFormatter()
        formatter.locale = AppLocalizer.currentLanguage.locale
        formatter.setLocalizedDateFormatFromTemplate("yMMMd")
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
