import SwiftUI

// MARK: - HiBiPic Typography Scale
/// Consistent type ramp for the "Warm Minimal" theme.
/// Titles use `.rounded` design for a friendly feel; body text uses `.default`.
enum DSTypography {

    // MARK: - Headings
    /// Hero headings (e.g. onboarding titles, large counters)
    static let largeTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    /// Screen titles
    static let title = Font.system(size: 22, weight: .semibold, design: .rounded)
    /// Section headers inside a screen
    static let title2 = Font.system(size: 20, weight: .semibold, design: .default)
    /// Card / row headlines
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)

    // MARK: - Body
    /// Default body copy
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    /// Slightly smaller body variant
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    /// Supporting copy beneath headlines
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    /// Meta information, timestamps
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    /// Smallest readable text
    static let caption = Font.system(size: 12, weight: .regular, design: .default)

    // MARK: - Stamp Overlay (photo counter badge)
    /// Large day number on the photo stamp
    static let stampNumber = Font.system(size: 48, weight: .bold, design: .rounded)
    /// Label beneath the day number (e.g. "days")
    static let stampLabel = Font.system(size: 18, weight: .medium, design: .rounded)
    /// Small detail on the stamp (e.g. date)
    static let stampSmall = Font.system(size: 14, weight: .regular, design: .rounded)
}
