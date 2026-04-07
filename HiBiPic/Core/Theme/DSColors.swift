import SwiftUI

// MARK: - HiBiPic Color Palette
/// "Warm Minimal" theme - refined, quiet, generous whitespace, photos are the hero.
enum DSColors {

    // MARK: - Backgrounds
    /// Primary background - warm off-white
    static let background = Color(hex: "FAF9F7")
    /// Card / elevated surface background - pure white
    static let cardBackground = Color(hex: "FFFFFF")
    /// Secondary background - slightly darker warm gray
    static let secondaryBackground = Color(hex: "F5F3F0")

    // MARK: - Text
    /// Primary text - dark charcoal for maximum readability
    static let textPrimary = Color(hex: "2C2C2E")
    /// Secondary text - medium gray for supporting copy
    static let textSecondary = Color(hex: "8E8E93")
    /// Tertiary text - light gray for placeholders / captions
    static let textTertiary = Color(hex: "AEAEB2")

    // MARK: - Accent
    /// Primary accent - sage green
    static let accent = Color(hex: "7C9A8E")
    /// Light accent variant - for tinted backgrounds
    static let accentLight = Color(hex: "B8CFC4")
    /// Dark accent variant - for pressed states
    static let accentDark = Color(hex: "5B7A6E")

    // MARK: - Semantic
    /// Error / destructive - muted red
    static let error = Color(hex: "C44E4E")
    /// Success - muted green
    static let success = Color(hex: "6B9B7D")
    /// Warning - warm amber
    static let warning = Color(hex: "D4A054")

    // MARK: - Borders & Dividers
    /// Subtle border for cards and inputs
    static let border = Color(hex: "E8E6E3")
    /// Barely visible divider for lists
    static let divider = Color(hex: "F0EEEB")

    // MARK: - Overlays
    /// Light overlay - for bottom-sheet scrims
    static let overlayLight = Color.white.opacity(0.85)
    /// Dark overlay - for modal backdrops / photo overlays
    static let overlayDark = Color.black.opacity(0.4)

    // MARK: - Buttons
    static let buttonPrimaryBg = accent
    static let buttonPrimaryText = Color.white
    static let buttonSecondaryBg = Color.clear
    static let buttonSecondaryText = accent
    static let buttonDestructiveBg = error
    static let buttonDestructiveText = Color.white
    static let buttonDisabledBg = Color(hex: "E8E6E3")
    static let buttonDisabledText = Color(hex: "AEAEB2")
}

// MARK: - Color + Hex Initialiser
extension Color {

    /// Create a ``Color`` from a hex string (3, 4, 6, or 8 characters, optional `#` prefix).
    init(hex: String) {
        let sanitised = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: sanitised).scanHexInt64(&rgb)

        let r, g, b, a: Double

        switch sanitised.count {
        case 3: // RGB (12-bit)
            r = Double((rgb >> 8) & 0xF) / 15.0
            g = Double((rgb >> 4) & 0xF) / 15.0
            b = Double(rgb & 0xF) / 15.0
            a = 1.0

        case 4: // RGBA (16-bit)
            r = Double((rgb >> 12) & 0xF) / 15.0
            g = Double((rgb >> 8) & 0xF) / 15.0
            b = Double((rgb >> 4) & 0xF) / 15.0
            a = Double(rgb & 0xF) / 15.0

        case 6: // RRGGBB (24-bit)
            r = Double((rgb >> 16) & 0xFF) / 255.0
            g = Double((rgb >> 8) & 0xFF) / 255.0
            b = Double(rgb & 0xFF) / 255.0
            a = 1.0

        case 8: // RRGGBBAA (32-bit)
            r = Double((rgb >> 24) & 0xFF) / 255.0
            g = Double((rgb >> 16) & 0xFF) / 255.0
            b = Double((rgb >> 8) & 0xFF) / 255.0
            a = Double(rgb & 0xFF) / 255.0

        default:
            r = 0; g = 0; b = 0; a = 1.0
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
