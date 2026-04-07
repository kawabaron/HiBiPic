import SwiftUI

// MARK: - DSButton
/// A design-system button with primary, secondary, destructive, and text variants.
///
/// Supports a loading state that replaces the label with a spinner and
/// disables interaction. All variants meet the 44 pt minimum touch-target
/// guideline.
///
/// Usage:
/// ```swift
/// DSButton("Save", style: .primary) { await save() }
/// DSButton("Delete", style: .destructive, isLoading: $isDeleting) { await delete() }
/// ```
struct DSButton: View {

    // MARK: - Types

    enum Style {
        case primary
        case secondary
        case destructive
        case text
    }

    // MARK: - Properties

    private let title: String
    private let style: Style
    private let fullWidth: Bool
    private let icon: Image?
    private let action: () -> Void

    @Binding private var isLoading: Bool
    @Environment(\.isEnabled) private var isEnabled

    // MARK: - Init

    /// Creates a new ``DSButton``.
    /// - Parameters:
    ///   - title: The button label.
    ///   - style: Visual variant (default `.primary`).
    ///   - fullWidth: Whether the button stretches horizontally (default `true`).
    ///   - icon: An optional leading icon.
    ///   - isLoading: Binding that shows a spinner when `true`.
    ///   - action: Closure invoked on tap.
    init(
        _ title: String,
        style: Style = .primary,
        fullWidth: Bool = true,
        icon: Image? = nil,
        isLoading: Binding<Bool> = .constant(false),
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.fullWidth = fullWidth
        self.icon = icon
        self._isLoading = isLoading
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: buttonAction) {
            label
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var label: some View {
        HStack(spacing: DSSpacing.sm) {
            if isLoading {
                ProgressView()
                    .tint(foregroundColor)
                    .controlSize(.small)
            } else {
                if let icon {
                    icon
                        .font(.system(size: 16, weight: .medium))
                }
                Text(title)
                    .font(DSTypography.headline)
            }
        }
        .frame(maxWidth: fullWidth ? .infinity : nil)
        .frame(minHeight: 44)
        .padding(.horizontal, DSSpacing.xl)
        .foregroundStyle(foregroundColor)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
        .overlay {
            if style == .secondary {
                RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous)
                    .strokeBorder(isEnabled ? DSColors.accent : DSColors.buttonDisabledBg, lineWidth: 1.5)
            }
        }
        .opacity(isEnabled ? 1.0 : 0.6)
        .contentShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }

    // MARK: - Helpers

    private func buttonAction() {
        guard !isLoading else { return }
        action()
    }

    private var backgroundColor: Color {
        guard isEnabled else { return DSColors.buttonDisabledBg }
        switch style {
        case .primary:      return DSColors.buttonPrimaryBg
        case .secondary:    return DSColors.buttonSecondaryBg
        case .destructive:  return DSColors.buttonDestructiveBg
        case .text:         return .clear
        }
    }

    private var foregroundColor: Color {
        guard isEnabled else { return DSColors.buttonDisabledText }
        switch style {
        case .primary:      return DSColors.buttonPrimaryText
        case .secondary:    return DSColors.buttonSecondaryText
        case .destructive:  return DSColors.buttonDestructiveText
        case .text:         return DSColors.accent
        }
    }
}

// MARK: - Previews

#Preview("All Styles") {
    VStack(spacing: DSSpacing.lg) {
        DSButton("Primary Button", style: .primary) {}
        DSButton("Secondary Button", style: .secondary) {}
        DSButton("Destructive", style: .destructive) {}
        DSButton("Text Button", style: .text, fullWidth: false) {}
        DSButton("Loading", style: .primary, isLoading: .constant(true)) {}
        DSButton("Disabled", style: .primary) {}
            .disabled(true)
    }
    .padding(DSSpacing.xl)
    .background(DSColors.background)
}
