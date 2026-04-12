import SwiftUI

// MARK: - EventSelectSheet

/// Bottom sheet for selecting an event to capture a photo for.
/// Shown when the "撮る" tab is tapped and there are multiple events.
struct EventSelectSheet: View {

    let events: [Event]
    let onEventSelected: (Event) -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(events) { event in
                    Button {
                        onEventSelected(event)
                    } label: {
                        eventRow(event)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(
                        top: DSSpacing.xs,
                        leading: DSSpacing.lg,
                        bottom: DSSpacing.xs,
                        trailing: DSSpacing.lg
                    ))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(DSColors.background)
            .navigationTitle(L10n.t("イベントを選択"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onDismiss()
                    } label: {
                        Text(L10n.t("閉じる"))
                            .font(DSTypography.callout)
                            .foregroundStyle(DSColors.accent)
                    }
                }
            }
        }
    }

    // MARK: - Event Row

    private func eventRow(_ event: Event) -> some View {
        HStack(spacing: DSSpacing.md) {
            // Template dot
            Circle()
                .fill(templateColor(for: event.designTemplateId))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text(event.name)
                    .font(DSTypography.headline)
                    .foregroundStyle(DSColors.textPrimary)

                Text(daySummary(event))
                    .font(DSTypography.footnote)
                    .foregroundStyle(DSColors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DSColors.textTertiary)
        }
        .padding(DSSpacing.lg)
        .background(DSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
    }

    // MARK: - Helpers

    private func templateColor(for type: DesignTemplateType) -> Color {
        switch type {
        case .minimal: return DSColors.textSecondary
        case .soft:    return DSColors.accentLight
        case .film:    return DSColors.warning
        case .poster:  return DSColors.accent
        case .classic: return Color(hex: "BFA889")
        case .diary: return Color(hex: "D69B6F")
        case .cleanLabel: return Color(hex: "8FA3B0")
        case .memory: return Color(hex: "C9B28A")
        case .milestone: return Color(hex: "6DA6B8")
        case .airy: return Color(hex: "9BCBB8")
        }
    }

    private func daySummary(_ event: Event) -> String {
        let days = DateCalculator.calculateDays(baseDate: event.baseDate, countType: event.countType)
        switch event.countType {
        case .countdown, .elapsed, .daycount:
            return LocalizedDayCountFormatter.string(days: days, countType: event.countType, showsTodayForZeroCountdown: false)
        }
    }
}
