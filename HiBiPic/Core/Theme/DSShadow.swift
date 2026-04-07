import SwiftUI

// MARK: - HiBiPic Shadow Modifier
/// Applies one of the design-system shadow styles.
struct DSShadow: ViewModifier {

    enum Style {
        /// Elevated card shadow (stronger)
        case card
        /// Subtle, soft shadow for floating elements
        case soft
        /// No shadow
        case none
    }

    let style: Style

    func body(content: Content) -> some View {
        switch style {
        case .card:
            content
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        case .soft:
            content
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
        case .none:
            content
        }
    }
}

// MARK: - View Extension
extension View {

    /// Apply a HiBiPic design-system shadow.
    /// - Parameter style: The shadow intensity. Defaults to `.card`.
    func dsShadow(_ style: DSShadow.Style = .card) -> some View {
        modifier(DSShadow(style: style))
    }
}
