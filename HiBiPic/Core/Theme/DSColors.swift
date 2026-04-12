import SwiftUI
import UIKit

// MARK: - HiBiPic Color Palette
/// "Warm Minimal" theme - refined, quiet, generous whitespace, photos are the hero.
enum DSColors {

    // MARK: - Backgrounds
    /// Primary background - warm off-white
    static let background = dynamicColor(light: "FAF9F7", dark: "111311")
    /// Card / elevated surface background - pure white
    static let cardBackground = dynamicColor(light: "FFFFFF", dark: "1B1C1A")
    /// Secondary background - slightly darker warm gray
    static let secondaryBackground = dynamicColor(light: "F5F3F0", dark: "242521")

    // MARK: - Text
    /// Primary text - dark charcoal for maximum readability
    static let textPrimary = dynamicColor(light: "2C2C2E", dark: "F5F1EA")
    /// Secondary text - medium gray for supporting copy
    static let textSecondary = dynamicColor(light: "8E8E93", dark: "B4AFA8")
    /// Tertiary text - light gray for placeholders / captions
    static let textTertiary = dynamicColor(light: "AEAEB2", dark: "7E7B74")

    // MARK: - Accent
    /// Primary accent - sage green
    static let accent = dynamicColor(light: "7C9A8E", dark: "97B7AA")
    /// Light accent variant - for tinted backgrounds
    static let accentLight = dynamicColor(light: "B8CFC4", dark: "42544B")
    /// Dark accent variant - for pressed states
    static let accentDark = dynamicColor(light: "5B7A6E", dark: "CCE0D7")

    // MARK: - Semantic
    /// Error / destructive - muted red
    static let error = dynamicColor(light: "C44E4E", dark: "E08282")
    /// Success - muted green
    static let success = dynamicColor(light: "6B9B7D", dark: "8AC19B")
    /// Warning - warm amber
    static let warning = dynamicColor(light: "D4A054", dark: "E2B56B")

    // MARK: - Borders & Dividers
    /// Subtle border for cards and inputs
    static let border = dynamicColor(light: "E8E6E3", dark: "31332E")
    /// Barely visible divider for lists
    static let divider = dynamicColor(light: "F0EEEB", dark: "262823")

    // MARK: - Overlays
    /// Light overlay - for bottom-sheet scrims
    static let overlayLight = dynamicColor(light: "FFFFFFD9", dark: "1B1C1AD9")
    /// Dark overlay - for modal backdrops / photo overlays
    static let overlayDark = dynamicColor(light: "00000066", dark: "00000099")

    // MARK: - Buttons
    static let buttonPrimaryBg = accent
    static let buttonPrimaryText = Color.white
    static let buttonSecondaryBg = Color.clear
    static let buttonSecondaryText = accent
    static let buttonDestructiveBg = error
    static let buttonDestructiveText = Color.white
    static let buttonDisabledBg = dynamicColor(light: "E8E6E3", dark: "31332E")
    static let buttonDisabledText = dynamicColor(light: "AEAEB2", dark: "7E7B74")

    private static func dynamicColor(light: String, dark: String) -> Color {
        Color(uiColor: dynamicUIColor(light: light, dark: dark))
    }

    private static func dynamicUIColor(light: String, dark: String) -> UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(hex: dark)
            default:
                return UIColor(hex: light)
            }
        }
    }
}

// MARK: - Color + Hex Initialiser
extension Color {

    /// Create a ``Color`` from a hex string (3, 4, 6, or 8 characters, optional `#` prefix).
    init(hex: String) {
        self.init(uiColor: UIColor(hex: hex))
    }
}
