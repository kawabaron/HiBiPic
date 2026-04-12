import SwiftUI

// MARK: - EmptyStateView

/// Friendly empty-state placeholder shown when the user has no events yet.
/// Uses SF Symbols for a camera-and-calendar visual concept,
/// with an inviting CTA to create the first event.
struct EmptyStateView: View {

    // MARK: - Actions

    /// Called when the user taps the "create" button.
    var onCreateTapped: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: DSSpacing.xxl) {
            Spacer()

            iconCluster

            textGroup

            createButton

            Spacer()
            Spacer()
        }
        .padding(.horizontal, DSSpacing.xxxl)
    }

    // MARK: - Icon Cluster

    /// Layered SF Symbols to suggest "camera + calendar".
    private var iconCluster: some View {
        ZStack {
            // Soft tinted circle behind the icons
            Circle()
                .fill(DSColors.accentLight.opacity(0.25))
                .frame(width: 100, height: 100)

            HStack(spacing: DSSpacing.xs) {
                Image(systemName: "camera")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(DSColors.accent)

                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DSColors.textTertiary)

                Image(systemName: "calendar")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(DSColors.accent)
            }
        }
    }

    // MARK: - Text Group

    private var textGroup: some View {
        VStack(spacing: DSSpacing.sm) {
            Text(L10n.t("まだイベントがありません"))
                .font(DSTypography.title)
                .foregroundStyle(DSColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(L10n.t("大切な日を登録して、写真に残しましょう"))
                .font(DSTypography.subheadline)
                .foregroundStyle(DSColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - CTA Button

    private var createButton: some View {
        DSButton(
            L10n.t("最初のイベントを作成"),
            style: .primary,
            fullWidth: false,
            icon: Image(systemName: "plus")
        ) {
            onCreateTapped()
        }
    }
}

// MARK: - Preview

#Preview("Empty State") {
    EmptyStateView {
        // preview action
    }
    .background(DSColors.background)
}
