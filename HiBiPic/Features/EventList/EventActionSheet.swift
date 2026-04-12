import SwiftUI

// MARK: - EventAction

/// The actions available when a user selects an event.
enum EventAction: Identifiable {
    case camera
    case photoPicker
    case edit

    var id: String {
        switch self {
        case .camera:      return "camera"
        case .photoPicker: return "photoPicker"
        case .edit:        return "edit"
        }
    }

    /// Localised label for the action row.
    var label: String {
        switch self {
        case .camera:      return L10n.t("このイベントで撮る")
        case .photoPicker: return L10n.t("写真を選ぶ")
        case .edit:        return L10n.t("イベントを編集")
        }
    }

    /// SF Symbol name for the action icon.
    var iconName: String {
        switch self {
        case .camera:      return "camera.fill"
        case .photoPicker: return "photo.fill"
        case .edit:        return "pencil"
        }
    }

    /// Tint colour for the action icon.
    var iconColor: Color {
        switch self {
        case .camera:      return DSColors.accent
        case .photoPicker: return Color(hex: "D4A054")
        case .edit:        return DSColors.textSecondary
        }
    }
}

// MARK: - EventActionSheet

/// A bottom-sheet presenting the available actions for a selected event.
/// Uses `.confirmationDialog` internally for native iOS feel while
/// maintaining the design system's visual language.
struct EventActionSheet: View {

    // MARK: - Properties

    /// The event the user selected.
    let event: Event

    /// Callback delivering the chosen action.
    var onAction: (EventAction) -> Void

    /// Dismiss callback (cancel).
    var onDismiss: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            handle

            headerSection

            Divider()
                .foregroundStyle(DSColors.divider)

            actionList

            cancelButton
        }
        .background(DSColors.cardBackground)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: DSSpacing.cornerXl,
                topTrailingRadius: DSSpacing.cornerXl
            )
        )
        .dsShadow(.card)
    }

    // MARK: - Handle

    private var handle: some View {
        RoundedRectangle(cornerRadius: DSSpacing.cornerFull)
            .fill(DSColors.border)
            .frame(width: 36, height: 4)
            .padding(.top, DSSpacing.sm)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: DSSpacing.xs) {
            Text(event.name)
                .font(DSTypography.headline)
                .foregroundStyle(DSColors.textPrimary)

            Text(countSummary)
                .font(DSTypography.footnote)
                .foregroundStyle(DSColors.textSecondary)
        }
        .padding(.vertical, DSSpacing.lg)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Action List

    private var actionList: some View {
        VStack(spacing: 0) {
            ForEach([EventAction.camera, .photoPicker, .edit]) { action in
                actionRow(action)

                if action.id != EventAction.edit.id {
                    Divider()
                        .foregroundStyle(DSColors.divider)
                        .padding(.leading, DSSpacing.massive)
                }
            }
        }
    }

    // MARK: - Single Action Row

    private func actionRow(_ action: EventAction) -> some View {
        Button {
            onAction(action)
        } label: {
            HStack(spacing: DSSpacing.md) {
                Image(systemName: action.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(action.iconColor)
                    .frame(width: 28, height: 28)

                Text(action.label)
                    .font(DSTypography.body)
                    .foregroundStyle(DSColors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DSColors.textTertiary)
            }
            .padding(.horizontal, DSSpacing.xl)
            .padding(.vertical, DSSpacing.lg)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Cancel

    private var cancelButton: some View {
        Button {
            onDismiss()
        } label: {
            Text(L10n.t("キャンセル"))
                .font(DSTypography.headline)
                .foregroundStyle(DSColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DSSpacing.lg)
        }
        .buttonStyle(.plain)
        .padding(.top, DSSpacing.sm)
        .padding(.bottom, DSSpacing.xxl)
    }

    // MARK: - Helpers

    private var countSummary: String {
        let days = DateCalculator.calculateDays(
            baseDate: event.baseDate,
            countType: event.countType
        )
        switch event.countType {
        case .countdown, .elapsed, .daycount:
            return LocalizedDayCountFormatter.string(days: days, countType: event.countType)
        }
    }
}

// MARK: - Preview

#Preview("Action Sheet") {
    ZStack {
        DSColors.overlayDark
            .ignoresSafeArea()

        VStack {
            Spacer()

            EventActionSheet(
                event: Event(
                    name: "結婚記念日",
                    baseDate: "2020-11-22",
                    countType: .daycount,
                    designTemplateId: .soft
                ),
                onAction: { _ in },
                onDismiss: {}
            )
        }
    }
}
