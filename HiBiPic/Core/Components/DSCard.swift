import SwiftUI

// MARK: - DSCard
/// A themed card container with white background, rounded corners, and a
/// soft shadow. Used for event list items, template selections, and any
/// elevated surface.
///
/// Usage:
/// ```swift
/// DSCard {
///     Text("Hello")
/// }
///
/// DSCard(padding: .lg, shadow: .soft) {
///     HStack { ... }
/// }
/// ```
struct DSCard<Content: View>: View {

    // MARK: - Properties

    private let padding: CGFloat
    private let shadow: DSShadow.Style
    private let content: Content

    // MARK: - Init

    /// Creates a new ``DSCard``.
    /// - Parameters:
    ///   - padding: Inner content padding. Defaults to ``DSSpacing/lg`` (16 pt).
    ///   - shadow: Shadow style. Defaults to `.card`.
    ///   - content: The card's content.
    init(
        padding: CGFloat = DSSpacing.lg,
        shadow: DSShadow.Style = .card,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.shadow = shadow
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        content
            .padding(padding)
            .background(DSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerLg, style: .continuous))
            .dsShadow(shadow)
    }
}

// MARK: - Tappable Card Variant
/// A card that responds to taps with a subtle press animation.
struct DSTappableCard<Content: View>: View {

    // MARK: - Properties

    private let padding: CGFloat
    private let shadow: DSShadow.Style
    private let action: () -> Void
    private let content: Content

    @State private var isPressed = false

    // MARK: - Init

    init(
        padding: CGFloat = DSSpacing.lg,
        shadow: DSShadow.Style = .card,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.shadow = shadow
        self.action = action
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            content
                .padding(padding)
                .background(DSColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerLg, style: .continuous))
                .dsShadow(shadow)
        }
        .buttonStyle(CardPressStyle())
    }
}

// MARK: - Card Press Button Style
/// Subtle scale-down animation on press.
private struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Cards") {
    ScrollView {
        VStack(spacing: DSSpacing.lg) {
            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Event Title")
                        .font(DSTypography.headline)
                        .foregroundStyle(DSColors.textPrimary)
                    Text("Supporting text goes here")
                        .font(DSTypography.subheadline)
                        .foregroundStyle(DSColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            DSTappableCard(action: {}) {
                HStack {
                    Text("Tappable Card")
                        .font(DSTypography.headline)
                        .foregroundStyle(DSColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(DSColors.textTertiary)
                }
            }
        }
        .padding(DSSpacing.xl)
    }
    .background(DSColors.background)
}
