import SwiftUI
import UIKit

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

// MARK: - Overlay Font Resolver

enum OverlayFontResolver {

    static func swiftUIFont(
        preset: FontPreset,
        size: CGFloat,
        weight: Font.Weight,
        designTemplate: DesignTemplate,
        text: String = "",
        isEmphasized: Bool = false
    ) -> Font {
        if preset == .signature {
            return signatureSwiftUIFont(
                size: size,
                weight: weight,
                text: text,
                isEmphasized: isEmphasized
            )
        }

        return Font.system(
            size: adjustedSize(size, preset: preset, isEmphasized: isEmphasized),
            weight: adjusted(weight, preset: preset, isEmphasized: isEmphasized),
            design: swiftUIDesign(preset: preset, designTemplate: designTemplate)
        )
    }

    static func uiFont(
        preset: FontPreset,
        size: CGFloat,
        weight: UIFont.Weight,
        designTemplate: DesignTemplate,
        text: String = "",
        isEmphasized: Bool = false
    ) -> UIFont {
        if preset == .signature {
            return signatureUIFont(
                size: size,
                weight: weight,
                text: text,
                isEmphasized: isEmphasized
            )
        }

        let resolvedSize = adjustedSize(size, preset: preset, isEmphasized: isEmphasized)
        let resolvedWeight = adjusted(weight, preset: preset, isEmphasized: isEmphasized)
        let baseDescriptor = UIFont.systemFont(ofSize: resolvedSize, weight: resolvedWeight).fontDescriptor
        let design = uiKitDesign(preset: preset, designTemplate: designTemplate)
        let designDescriptor = baseDescriptor.withDesign(design) ?? baseDescriptor
        return UIFont(descriptor: designDescriptor, size: resolvedSize)
    }

    static func tracking(
        preset: FontPreset,
        size: CGFloat,
        designTemplate: DesignTemplate,
        text: String = "",
        isEmphasized: Bool = false
    ) -> CGFloat {
        if preset == .signature {
            return signatureTracking(
                size: size,
                designTemplate: designTemplate,
                text: text,
                isEmphasized: isEmphasized
            )
        }

        let resolvedSize = adjustedSize(size, preset: preset, isEmphasized: isEmphasized)
        let templateTracking = templateBaseTracking(
            resolvedSize: resolvedSize,
            designTemplate: designTemplate,
            isEmphasized: isEmphasized
        )

        switch preset {
        case .standard:
            return templateTracking
        case .clean:
            return templateTracking + resolvedSize * (isEmphasized ? -0.028 : -0.022)
        case .editorialSerif:
            return templateTracking + resolvedSize * 0.02
        case .signature:
            return signatureTracking(
                size: size,
                designTemplate: designTemplate,
                text: text,
                isEmphasized: isEmphasized
            )
        }
    }

    static func swiftUIDesign(
        preset: FontPreset,
        designTemplate: DesignTemplate
    ) -> Font.Design {
        switch preset {
        case .standard:
            return templateSwiftUIDesign(for: designTemplate)
        case .clean:
            return .default
        case .editorialSerif:
            return .serif
        case .signature:
            return .default
        }
    }

    static func uiKitDesign(
        preset: FontPreset,
        designTemplate: DesignTemplate
    ) -> UIFontDescriptor.SystemDesign {
        switch preset {
        case .standard:
            return templateUIKitDesign(for: designTemplate)
        case .clean:
            return .default
        case .editorialSerif:
            return .serif
        case .signature:
            return .default
        }
    }

    static func templateSwiftUIDesign(for template: DesignTemplate) -> Font.Design {
        switch template.id {
        case .soft, .poster, .diary, .milestone:
            return .rounded
        case .minimal, .film, .classic, .cleanLabel, .memory, .airy:
            return .default
        }
    }

    static func templateUIKitDesign(for template: DesignTemplate) -> UIFontDescriptor.SystemDesign {
        switch template.id {
        case .soft, .poster, .diary, .milestone:
            return .rounded
        case .minimal, .film, .classic, .cleanLabel, .memory, .airy:
            return .default
        }
    }

    private static func adjustedSize(
        _ size: CGFloat,
        preset: FontPreset,
        isEmphasized: Bool
    ) -> CGFloat {
        switch preset {
        case .standard:
            return size
        case .clean:
            return size * (isEmphasized ? 0.96 : 0.93)
        case .editorialSerif:
            return size * (isEmphasized ? 1.05 : 1.02)
        case .signature:
            return signatureAdjustedSize(size, text: "", isEmphasized: isEmphasized)
        }
    }

    private static func adjusted(
        _ weight: Font.Weight,
        preset: FontPreset,
        isEmphasized: Bool
    ) -> Font.Weight {
        let steps: Int

        switch preset {
        case .standard:
            steps = 0
        case .clean:
            steps = isEmphasized ? 1 : 2
        case .editorialSerif:
            steps = isEmphasized ? 1 : 0
        case .signature:
            steps = 0
        }

        return shift(weight, by: steps)
    }

    private static func adjusted(
        _ weight: UIFont.Weight,
        preset: FontPreset,
        isEmphasized: Bool
    ) -> UIFont.Weight {
        let steps: Int

        switch preset {
        case .standard:
            steps = 0
        case .clean:
            steps = isEmphasized ? 1 : 2
        case .editorialSerif:
            steps = isEmphasized ? 1 : 0
        case .signature:
            steps = 0
        }

        return shift(weight, by: steps)
    }

    private static func shift(_ weight: Font.Weight, by steps: Int) -> Font.Weight {
        let ordered: [Font.Weight] = [.thin, .light, .regular, .medium, .semibold, .bold, .heavy]
        guard let index = ordered.firstIndex(of: weight) else { return weight }
        let shiftedIndex = min(max(index + steps, 0), ordered.count - 1)
        return ordered[shiftedIndex]
    }

    private static func shift(_ weight: UIFont.Weight, by steps: Int) -> UIFont.Weight {
        let ordered: [UIFont.Weight] = [.thin, .light, .regular, .medium, .semibold, .bold, .heavy]
        guard let index = ordered.firstIndex(of: weight) else { return weight }
        let shiftedIndex = min(max(index + steps, 0), ordered.count - 1)
        return ordered[shiftedIndex]
    }

    private static func templateBaseTracking(
        resolvedSize: CGFloat,
        designTemplate: DesignTemplate,
        isEmphasized: Bool
    ) -> CGFloat {
        switch designTemplate.id {
        case .minimal, .soft, .classic, .diary, .cleanLabel, .airy:
            return 0
        case .film, .memory:
            return max(0.5, resolvedSize * 0.01)
        case .poster, .milestone:
            return isEmphasized ? resolvedSize * 0.004 : 0
        }
    }

    private static func signatureFontName(
        text: String,
        weight: Font.Weight,
        isEmphasized: Bool
    ) -> String {
        switch signatureFontKind(for: text) {
        case .latin:
            return "GreatVibes-Regular"
        case .unifiedCJK:
            return "LXGWWenKaiLite-Regular"
        case .japanese:
            return isEmphasized || isKleeSemiBold(weight)
                ? "KleeOne-SemiBold"
                : "KleeOne-Regular"
        case .fallbackSystem:
            return "KleeOne-Regular"
        }
    }

    private static func signatureFontName(
        text: String,
        weight: UIFont.Weight,
        isEmphasized: Bool
    ) -> String {
        switch signatureFontKind(for: text) {
        case .latin:
            return "GreatVibes-Regular"
        case .unifiedCJK:
            return "LXGWWenKaiLite-Regular"
        case .japanese:
            return isEmphasized || weight.rawValue >= UIFont.Weight.semibold.rawValue
                ? "KleeOne-SemiBold"
                : "KleeOne-Regular"
        case .fallbackSystem:
            return "KleeOne-Regular"
        }
    }

    private static func signatureAdjustedSize(
        _ size: CGFloat,
        text: String,
        isEmphasized: Bool
    ) -> CGFloat {
        switch signatureFontKind(for: text) {
        case .latin:
            return size * (isEmphasized ? 1.32 : 1.24)
        case .unifiedCJK:
            return size * (isEmphasized ? 1.1 : 1.04)
        case .japanese:
            return size * (isEmphasized ? 1.08 : 1.02)
        case .fallbackSystem:
            return size * (isEmphasized ? 1.04 : 1.0)
        }
    }

    private static func signatureTracking(
        size: CGFloat,
        designTemplate: DesignTemplate,
        text: String,
        isEmphasized: Bool
    ) -> CGFloat {
        if signatureFontKind(for: text) == .latin {
            // Extra tracking breaks cursive connections in Great Vibes.
            return 0
        }

        let resolvedSize = signatureAdjustedSize(size, text: text, isEmphasized: isEmphasized)
        return templateBaseTracking(
            resolvedSize: resolvedSize,
            designTemplate: designTemplate,
            isEmphasized: isEmphasized
        ) + resolvedSize * (isEmphasized ? 0.008 : 0.004)
    }

    private static func signatureSwiftUIFont(
        size: CGFloat,
        weight: Font.Weight,
        text: String,
        isEmphasized: Bool
    ) -> Font {
        let resolvedSize = signatureAdjustedSize(size, text: text, isEmphasized: isEmphasized)

        switch signatureFontKind(for: text) {
        case .latin:
            return Font.custom("GreatVibes-Regular", size: resolvedSize)
        case .japanese:
            return Font.custom(
                signatureFontName(text: text, weight: weight, isEmphasized: isEmphasized),
                size: resolvedSize
            )
        case .unifiedCJK:
            let baseFont = Font.custom("LXGWWenKaiLite-Regular", size: resolvedSize)
            return baseFont.weight(signatureSyntheticWeight(weight, isEmphasized: isEmphasized))
        case .fallbackSystem:
            return Font.system(
                size: resolvedSize,
                weight: signatureSyntheticWeight(weight, isEmphasized: isEmphasized),
                design: .default
            )
        }
    }

    private static func signatureUIFont(
        size: CGFloat,
        weight: UIFont.Weight,
        text: String,
        isEmphasized: Bool
    ) -> UIFont {
        let resolvedSize = signatureAdjustedSize(size, text: text, isEmphasized: isEmphasized)

        switch signatureFontKind(for: text) {
        case .latin, .japanese:
            let fontName = signatureFontName(text: text, weight: weight, isEmphasized: isEmphasized)
            return UIFont(name: fontName, size: resolvedSize)
                ?? UIFont.systemFont(ofSize: resolvedSize, weight: weight)
        case .unifiedCJK:
            let baseFont = UIFont(name: "LXGWWenKaiLite-Regular", size: resolvedSize)
                ?? UIFont.systemFont(ofSize: resolvedSize, weight: .regular)
            return signatureSyntheticUIFont(baseFont, weight: weight, isEmphasized: isEmphasized)
        case .fallbackSystem:
            return UIFont.systemFont(
                ofSize: resolvedSize,
                weight: signatureSyntheticWeight(weight, isEmphasized: isEmphasized)
            )
        }
    }

    private static func signatureFontKind(for text: String) -> SignatureFontKind {
        let scalars = text.unicodeScalars.filter { !$0.properties.isWhitespace }
        guard !scalars.isEmpty else { return .japanese }

        if scalars.contains(where: isJapaneseKana) {
            return .japanese
        }
        if scalars.contains(where: isHangul) || scalars.contains(where: isHanIdeograph) {
            return .unifiedCJK
        }

        let hasNonLatinLetters = scalars.contains { scalar in
            CharacterSet.letters.contains(scalar) && !isSupportedLatin(scalar)
        }
        if hasNonLatinLetters {
            return .fallbackSystem
        }

        let hasLatinOrDigits = scalars.contains { scalar in
            isSupportedLatin(scalar) || CharacterSet.decimalDigits.contains(scalar)
        }
        return hasLatinOrDigits ? .latin : .japanese
    }

    private static func signatureSyntheticWeight(
        _ weight: Font.Weight,
        isEmphasized: Bool
    ) -> Font.Weight {
        switch weight {
        case .black, .heavy, .bold:
            return .bold
        case .semibold:
            return .semibold
        default:
            return isEmphasized ? .semibold : weight
        }
    }

    private static func signatureSyntheticWeight(
        _ weight: UIFont.Weight,
        isEmphasized: Bool
    ) -> UIFont.Weight {
        if weight.rawValue >= UIFont.Weight.bold.rawValue {
            return .bold
        }
        if isEmphasized || weight.rawValue >= UIFont.Weight.semibold.rawValue {
            return .semibold
        }
        return weight
    }

    private static func signatureSyntheticUIFont(
        _ font: UIFont,
        weight: UIFont.Weight,
        isEmphasized: Bool
    ) -> UIFont {
        let resolvedWeight = signatureSyntheticWeight(weight, isEmphasized: isEmphasized)
        guard resolvedWeight.rawValue >= UIFont.Weight.semibold.rawValue else {
            return font
        }

        let descriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) ?? font.fontDescriptor
        return UIFont(descriptor: descriptor, size: font.pointSize)
    }

    private static func isJapaneseKana(_ scalar: Unicode.Scalar) -> Bool {
        let value = scalar.value
        return (0x3040...0x30FF).contains(value)
            || (0x31F0...0x31FF).contains(value)
            || (0xFF66...0xFF9D).contains(value)
    }

    private static func isHangul(_ scalar: Unicode.Scalar) -> Bool {
        let value = scalar.value
        return (0x1100...0x11FF).contains(value)
            || (0x3130...0x318F).contains(value)
            || (0xA960...0xA97F).contains(value)
            || (0xAC00...0xD7AF).contains(value)
            || (0xD7B0...0xD7FF).contains(value)
    }

    private static func isHanIdeograph(_ scalar: Unicode.Scalar) -> Bool {
        let value = scalar.value
        return (0x3400...0x4DBF).contains(value)
            || (0x4E00...0x9FFF).contains(value)
            || (0xF900...0xFAFF).contains(value)
            || (0x20000...0x2A6DF).contains(value)
            || (0x2A700...0x2B73F).contains(value)
            || (0x2B740...0x2B81F).contains(value)
            || (0x2B820...0x2CEAF).contains(value)
            || (0x2CEB0...0x2EBEF).contains(value)
            || (0x30000...0x3134F).contains(value)
    }

    private static func isSupportedLatin(_ scalar: Unicode.Scalar) -> Bool {
        let value = scalar.value
        return (0x0041...0x005A).contains(value)
            || (0x0061...0x007A).contains(value)
            || (0x00C0...0x024F).contains(value)
            || (0x1E00...0x1EFF).contains(value)
    }

    private static func isKleeSemiBold(_ weight: Font.Weight) -> Bool {
        switch weight {
        case .semibold, .bold, .heavy, .black:
            return true
        default:
            return false
        }
    }

    private enum SignatureFontKind {
        case latin
        case japanese
        case unifiedCJK
        case fallbackSystem
    }
}
