import SwiftUI

// MARK: - SaveSuccessView

/// Post-save overlay with a checkmark animation and navigation options.
struct SaveSuccessView: View {

    // MARK: - Callbacks

    /// Saves the image to iPhone's photo library.
    let onSaveToPhotos: () -> Void
    /// Opens the share sheet to share the saved image.
    let onShare: () -> Void
    /// Returns to the library screen.
    let onBackToLibrary: () -> Void

    // MARK: - State

    @State private var showCheckmark = false
    @State private var showButtons = false
    @State private var savedToPhotos = false

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
                    Text(L10n.t("保存しました"))
                        .font(DSTypography.title)
                        .foregroundStyle(.white)

                    Text(L10n.t("ライブラリに保存しました"))
                        .font(DSTypography.callout)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                // Action buttons
                if showButtons {
                    VStack(spacing: DSSpacing.md) {
                        // Save to iPhone Photos
                        actionButton(
                            title: savedToPhotos ? L10n.t("保存しました") : L10n.t("iPhoneの写真に保存"),
                            icon: savedToPhotos ? "checkmark" : "square.and.arrow.down",
                            style: .primary,
                            disabled: savedToPhotos
                        ) {
                            onSaveToPhotos()
                            savedToPhotos = true
                        }

                        // Share
                        actionButton(
                            title: L10n.t("共有する"),
                            icon: "square.and.arrow.up",
                            style: .secondary
                        ) {
                            onShare()
                        }

                        // Back to library
                        actionButton(
                            title: L10n.t("ライブラリへ戻る"),
                            icon: "photo.on.rectangle",
                            style: .text
                        ) {
                            onBackToLibrary()
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
        disabled: Bool = false,
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
            .foregroundStyle(buttonForeground(style, disabled: disabled))
            .background(buttonBackground(style, disabled: disabled))
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
            .overlay {
                if style == .secondary {
                    RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private func buttonForeground(_ style: ButtonStyle, disabled: Bool = false) -> Color {
        if disabled { return .white.opacity(0.5) }
        switch style {
        case .primary:   return .white
        case .secondary: return .white
        case .text:      return .white.opacity(0.7)
        }
    }

    @ViewBuilder
    private func buttonBackground(_ style: ButtonStyle, disabled: Bool = false) -> some View {
        switch style {
        case .primary:
            disabled ? DSColors.accent.opacity(0.5) : DSColors.accent
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
        onSaveToPhotos: {},
        onShare: {},
        onBackToLibrary: {}
    )
}
