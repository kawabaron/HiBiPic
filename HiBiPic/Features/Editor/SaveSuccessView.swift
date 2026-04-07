import SwiftUI

// MARK: - SaveSuccessView

/// Post-save overlay with a checkmark animation and navigation options.
struct SaveSuccessView: View {

    // MARK: - Callbacks

    /// Opens the share sheet to share the saved image.
    let onShare: () -> Void
    /// Navigates back to photo selection to edit another image.
    let onEditAnother: () -> Void
    /// Returns to the event list.
    let onBackToList: () -> Void

    // MARK: - State

    @State private var showCheckmark = false
    @State private var showButtons = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {} // Prevent taps from passing through

            VStack(spacing: DSSpacing.xxl) {
                Spacer()

                // Checkmark animation
                checkmarkCircle

                // Success message
                VStack(spacing: DSSpacing.sm) {
                    Text("保存しました")
                        .font(DSTypography.title)
                        .foregroundStyle(.white)

                    Text("写真ライブラリに保存されました")
                        .font(DSTypography.callout)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                // Action buttons
                if showButtons {
                    VStack(spacing: DSSpacing.md) {
                        // Share
                        actionButton(
                            title: "共有する",
                            icon: "square.and.arrow.up",
                            style: .primary
                        ) {
                            onShare()
                        }

                        // Edit another
                        actionButton(
                            title: "もう1枚編集",
                            icon: "photo.on.rectangle",
                            style: .secondary
                        ) {
                            onEditAnother()
                        }

                        // Back to list
                        actionButton(
                            title: "一覧へ戻る",
                            icon: "list.bullet",
                            style: .text
                        ) {
                            onBackToList()
                        }
                    }
                    .padding(.horizontal, DSSpacing.xxxl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()
                    .frame(height: DSSpacing.huge)
            }
        }
        .onAppear {
            // Animate checkmark in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                showCheckmark = true
            }
            // Animate buttons in after checkmark
            withAnimation(.easeOut(duration: 0.3).delay(0.5)) {
                showButtons = true
            }
        }
    }

    // MARK: - Checkmark Circle

    private var checkmarkCircle: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(DSColors.accent.opacity(0.3), lineWidth: 3)
                .frame(width: 88, height: 88)

            // Filled circle
            Circle()
                .fill(DSColors.accent)
                .frame(width: 80, height: 80)
                .scaleEffect(showCheckmark ? 1.0 : 0.3)
                .opacity(showCheckmark ? 1.0 : 0.0)

            // Checkmark icon
            Image(systemName: "checkmark")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.white)
                .scaleEffect(showCheckmark ? 1.0 : 0.0)
                .opacity(showCheckmark ? 1.0 : 0.0)
        }
    }

    // MARK: - Action Button

    private enum ButtonStyle {
        case primary
        case secondary
        case text
    }

    private func actionButton(
        title: String,
        icon: String,
        style: ButtonStyle,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: DSSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(DSTypography.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .foregroundStyle(buttonForeground(style))
            .background(buttonBackground(style))
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
            .overlay {
                if style == .secondary {
                    RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func buttonForeground(_ style: ButtonStyle) -> Color {
        switch style {
        case .primary:   return .white
        case .secondary: return .white
        case .text:      return .white.opacity(0.7)
        }
    }

    @ViewBuilder
    private func buttonBackground(_ style: ButtonStyle) -> some View {
        switch style {
        case .primary:
            DSColors.accent
        case .secondary:
            Color.white.opacity(0.1)
        case .text:
            Color.clear
        }
    }
}

// MARK: - Preview

#Preview {
    SaveSuccessView(
        onShare: {},
        onEditAnother: {},
        onBackToList: {}
    )
}
