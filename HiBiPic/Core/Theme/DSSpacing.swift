import Foundation

// MARK: - HiBiPic Spacing Tokens
/// A single source of truth for spacing, corner radii, and shadow geometry
/// used throughout the HiBiPic design system.
enum DSSpacing {

    // MARK: - Spacing Scale
    /// 2 pt - hairline gaps
    static let xxs: CGFloat = 2
    /// 4 pt - icon-to-label gaps
    static let xs: CGFloat = 4
    /// 8 pt - compact padding
    static let sm: CGFloat = 8
    /// 12 pt - default inner padding
    static let md: CGFloat = 12
    /// 16 pt - standard content padding
    static let lg: CGFloat = 16
    /// 20 pt - generous section padding
    static let xl: CGFloat = 20
    /// 24 pt - large section gaps
    static let xxl: CGFloat = 24
    /// 32 pt - major section separation
    static let xxxl: CGFloat = 32
    /// 40 pt - hero spacing
    static let huge: CGFloat = 40
    /// 56 pt - oversized hero spacing
    static let massive: CGFloat = 56

    // MARK: - Corner Radii
    /// 8 pt - buttons, small chips
    static let cornerSm: CGFloat = 8
    /// 12 pt - text fields, cards
    static let cornerMd: CGFloat = 12
    /// 16 pt - larger cards, sheets
    static let cornerLg: CGFloat = 16
    /// 20 pt - modal corners
    static let cornerXl: CGFloat = 20
    /// 999 pt - pill / capsule shapes
    static let cornerFull: CGFloat = 999

    // MARK: - Shadow Geometry
    /// Default shadow blur radius
    static let shadowRadius: CGFloat = 8
    /// Default shadow vertical offset
    static let shadowY: CGFloat = 2
}
