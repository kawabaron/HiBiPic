import SwiftUI

// MARK: - Toast Model

/// Describes a single toast notification.
struct DSToastItem: Equatable, Identifiable {
    let id = UUID()
    let message: String
    let style: DSToastStyle
    let duration: TimeInterval

    static func == (lhs: DSToastItem, rhs: DSToastItem) -> Bool {
        lhs.id == rhs.id
    }

    /// Convenience factory for a success toast.
    static func success(_ message: String, duration: TimeInterval = 2.5) -> DSToastItem {
        DSToastItem(message: message, style: .success, duration: duration)
    }

    /// Convenience factory for an error toast.
    static func error(_ message: String, duration: TimeInterval = 3.0) -> DSToastItem {
        DSToastItem(message: message, style: .error, duration: duration)
    }
}

/// Visual variant of the toast.
enum DSToastStyle {
    case success
    case error

    var icon: String {
        switch self {
        case .success: "checkmark.circle.fill"
        case .error:   "xmark.circle.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .success: DSColors.success
        case .error:   DSColors.error
        }
    }
}

// MARK: - Toast View

/// The rendered toast banner. Slides in from the top and auto-dismisses.
private struct DSToastBanner: View {

    let item: DSToastItem

    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: item.style.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(item.style.tintColor)

            Text(item.message)
                .font(DSTypography.subheadline)
                .foregroundStyle(DSColors.textPrimary)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, DSSpacing.lg)
        .padding(.vertical, DSSpacing.md)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
        .dsShadow(.soft)
        .padding(.horizontal, DSSpacing.lg)
    }
}

// MARK: - Toast Modifier

/// View modifier that listens to a binding and shows toasts at the top of the
/// screen. Toasts auto-dismiss after the configured duration.
struct DSToastModifier: ViewModifier {

    @Binding var toast: DSToastItem?

    @State private var task: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) {
                if let toast {
                    DSToastBanner(item: toast)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            )
                        )
                        .onTapGesture { dismiss() }
                        .padding(.top, DSSpacing.sm)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: toast)
            .onChange(of: toast) { _, newValue in
                task?.cancel()
                guard let newValue else { return }
                task = Task {
                    try? await Task.sleep(for: .seconds(newValue.duration))
                    if !Task.isCancelled {
                        dismiss()
                    }
                }
            }
    }

    private func dismiss() {
        withAnimation {
            toast = nil
        }
    }
}

// MARK: - View Extension

extension View {

    /// Attach a toast overlay that appears at the top of the view.
    ///
    /// Set `toast` to a ``DSToastItem`` to show it; it auto-clears after the
    /// configured duration.
    ///
    /// ```swift
    /// @State private var toast: DSToastItem?
    ///
    /// var body: some View {
    ///     ContentView()
    ///         .dsToast($toast)
    ///         .onAppear {
    ///             toast = .success("Saved!")
    ///         }
    /// }
    /// ```
    func dsToast(_ toast: Binding<DSToastItem?>) -> some View {
        modifier(DSToastModifier(toast: toast))
    }
}

// MARK: - Previews

private struct ToastPreviewContainer: View {
    @State private var toast: DSToastItem?

    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            Spacer()

            DSButton("Show Success", style: .primary) {
                toast = .success("Event saved successfully!")
            }

            DSButton("Show Error", style: .destructive) {
                toast = .error("Something went wrong. Please try again.")
            }

            Spacer()
        }
        .padding(DSSpacing.xl)
        .background(DSColors.background)
        .dsToast($toast)
    }
}

#Preview("Toasts") {
    ToastPreviewContainer()
}
