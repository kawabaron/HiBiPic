import CoreGraphics
import Foundation
import UIKit

// MARK: - EditorImageRenderer

/// Burns the text overlay into a photo at full resolution, producing
/// the final sharable / saveable image.
///
/// All coordinates and sizes are computed proportionally to the base image
/// dimensions so that the output matches the SwiftUI preview regardless of
/// the device screen or photo resolution.
final class EditorImageRenderer {

    // MARK: - Public API

    /// Renders the text overlay on top of `baseImage` at its native resolution.
    ///
    /// - Parameters:
    ///   - baseImage:       The original photo.
    ///   - designTemplate:  The active design template (font, colour, alignment, etc.).
    ///   - layoutMode:      Single or double line layout.
    ///   - line1:           First line text (double-line mode label).
    ///   - line2:           Second line text (double-line mode number / detail).
    ///   - singleLine:      Full text for single-line mode.
    ///   - textPosition:    Normalised 0-1 centre position within the image.
    ///   - textScale:       User-chosen scale multiplier (0.5 - 2.0).
    ///   - textColorHex:    Optional colour override hex string (e.g. "#FFFFFF"). `nil` = template default.
    ///   - showBackground:  Whether to draw a semi-transparent background band.
    /// - Returns: The composited `UIImage`, or `nil` on failure.
    static func renderFinalImage(
        baseImage: UIImage,
        designTemplate: DesignTemplate,
        layoutMode: LayoutMode,
        line1: String,
        line2: String,
        singleLine: String,
        textPosition: CGPoint,
        textScale: CGFloat,
        textColorHex: String?,
        showBackground: Bool
    ) -> UIImage? {

        let imageSize = baseImage.size
        guard imageSize.width > 0, imageSize.height > 0 else { return nil }

        let renderer = UIGraphicsImageRenderer(size: imageSize)

        return renderer.image { context in
            let ctx = context.cgContext

            // 1. Draw the base photo
            baseImage.draw(in: CGRect(origin: .zero, size: imageSize))

            // 2. Calculate proportional font sizes
            //    Reference: on a 1080px wide image, base font = 48pt.
            let referenceDimension: CGFloat = 1080
            let sizeRatio = min(imageSize.width, imageSize.height) / referenceDimension
            let baseFontSize = 48 * sizeRatio * designTemplate.fontSizeScale * textScale
            let numberFontSize = 84 * sizeRatio * designTemplate.fontSizeScale * textScale
            let smallFontSize = 42 * sizeRatio * designTemplate.fontSizeScale * textScale

            // 3. Resolve colours
            let textColor: UIColor
            if let hex = textColorHex {
                textColor = UIColor(hex: hex)
            } else {
                textColor = UIColor(hex: designTemplate.textColor)
            }

            let bandColor = UIColor(hex: designTemplate.backgroundColor)

            // 4. Resolve font weight
            let uiFontWeight = uiKitWeight(from: designTemplate.fontWeight)

            // 5. Build attributed strings
            let paragraphStyle = NSMutableParagraphStyle()
            switch designTemplate.alignment {
            case .left:   paragraphStyle.alignment = .left
            case .center: paragraphStyle.alignment = .center
            case .right:  paragraphStyle.alignment = .right
            }

            if layoutMode == .single {
                // Single-line layout
                let attrs = textAttributes(
                    fontSize: baseFontSize,
                    weight: uiFontWeight,
                    color: textColor,
                    paragraphStyle: paragraphStyle,
                    design: fontDesign(for: designTemplate)
                )
                let attrString = NSAttributedString(string: singleLine, attributes: attrs)
                let textRect = calculateTextRect(
                    for: attrString,
                    imageSize: imageSize,
                    position: textPosition,
                    alignment: designTemplate.alignment
                )

                if showBackground {
                    drawBackgroundBand(
                        in: ctx,
                        rect: textRect,
                        color: bandColor,
                        cornerRadius: 8 * sizeRatio * textScale
                    )
                }

                drawTextWithShadow(
                    attrString,
                    in: textRect,
                    template: designTemplate,
                    sizeRatio: sizeRatio
                )

            } else {
                // Double-line layout
                let line1FontSize = designTemplate.numberEmphasis ? smallFontSize : baseFontSize
                let line2FontSize = designTemplate.numberEmphasis ? numberFontSize : baseFontSize
                let line2Weight: UIFont.Weight = designTemplate.numberEmphasis
                    ? heavierWeight(than: uiFontWeight)
                    : uiFontWeight

                let attrs1 = textAttributes(
                    fontSize: line1FontSize,
                    weight: uiFontWeight,
                    color: textColor.withAlphaComponent(0.9),
                    paragraphStyle: paragraphStyle,
                    design: fontDesign(for: designTemplate)
                )
                let attrs2 = textAttributes(
                    fontSize: line2FontSize,
                    weight: line2Weight,
                    color: textColor,
                    paragraphStyle: paragraphStyle,
                    design: fontDesign(for: designTemplate)
                )

                let attrLine1 = NSAttributedString(string: line1, attributes: attrs1)
                let attrLine2 = NSAttributedString(string: line2, attributes: attrs2)

                let lineSpacing: CGFloat = 8 * sizeRatio * textScale
                let combinedRect = calculateDoubleLineRect(
                    line1: attrLine1,
                    line2: attrLine2,
                    spacing: lineSpacing,
                    imageSize: imageSize,
                    position: textPosition,
                    alignment: designTemplate.alignment
                )

                if showBackground {
                    drawBackgroundBand(
                        in: ctx,
                        rect: combinedRect,
                        color: bandColor,
                        cornerRadius: 8 * sizeRatio * textScale
                    )
                }

                // Draw line 1
                let size1 = attrLine1.boundingSize(maxWidth: imageSize.width * 0.85)
                let line1Y = combinedRect.minY + (combinedRect.height - size1.height - lineSpacing - attrLine2.boundingSize(maxWidth: imageSize.width * 0.85).height) / 2
                let line1Rect = alignedRect(
                    textSize: size1,
                    centerX: combinedRect.midX,
                    y: line1Y,
                    alignment: designTemplate.alignment,
                    containerWidth: combinedRect.width
                )

                drawTextWithShadow(
                    attrLine1,
                    in: line1Rect,
                    template: designTemplate,
                    sizeRatio: sizeRatio
                )

                // Draw line 2
                let size2 = attrLine2.boundingSize(maxWidth: imageSize.width * 0.85)
                let line2Y = line1Y + size1.height + lineSpacing
                let line2Rect = alignedRect(
                    textSize: size2,
                    centerX: combinedRect.midX,
                    y: line2Y,
                    alignment: designTemplate.alignment,
                    containerWidth: combinedRect.width
                )

                drawTextWithShadow(
                    attrLine2,
                    in: line2Rect,
                    template: designTemplate,
                    sizeRatio: sizeRatio
                )
            }
        }
    }

    // MARK: - Text Attributes

    private static func textAttributes(
        fontSize: CGFloat,
        weight: UIFont.Weight,
        color: UIColor,
        paragraphStyle: NSParagraphStyle,
        design: UIFontDescriptor.SystemDesign
    ) -> [NSAttributedString.Key: Any] {
        let baseDescriptor = UIFont.systemFont(ofSize: fontSize, weight: weight).fontDescriptor
        let designDescriptor = baseDescriptor.withDesign(design) ?? baseDescriptor
        let font = UIFont(descriptor: designDescriptor, size: fontSize)

        return [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
    }

    // MARK: - Text Rect Calculation

    private static func calculateTextRect(
        for attrString: NSAttributedString,
        imageSize: CGSize,
        position: CGPoint,
        alignment: TextAlignment
    ) -> CGRect {
        let maxWidth = imageSize.width * 0.85
        let textSize = attrString.boundingSize(maxWidth: maxWidth)

        let centerX = imageSize.width * position.x
        let centerY = imageSize.height * position.y

        let padding: CGFloat = 16
        let totalWidth = textSize.width + padding * 2
        let totalHeight = textSize.height + padding * 2

        let originX: CGFloat
        switch alignment {
        case .left:
            originX = max(padding, centerX - totalWidth / 2)
        case .center:
            originX = centerX - totalWidth / 2
        case .right:
            originX = min(imageSize.width - totalWidth - padding, centerX - totalWidth / 2)
        }

        let originY = centerY - totalHeight / 2

        return CGRect(
            x: originX,
            y: originY,
            width: totalWidth,
            height: totalHeight
        )
    }

    private static func calculateDoubleLineRect(
        line1: NSAttributedString,
        line2: NSAttributedString,
        spacing: CGFloat,
        imageSize: CGSize,
        position: CGPoint,
        alignment: TextAlignment
    ) -> CGRect {
        let maxWidth = imageSize.width * 0.85
        let size1 = line1.boundingSize(maxWidth: maxWidth)
        let size2 = line2.boundingSize(maxWidth: maxWidth)

        let totalTextWidth = max(size1.width, size2.width)
        let totalTextHeight = size1.height + spacing + size2.height

        let padding: CGFloat = 20
        let totalWidth = totalTextWidth + padding * 2
        let totalHeight = totalTextHeight + padding * 2

        let centerX = imageSize.width * position.x
        let centerY = imageSize.height * position.y

        let originX = centerX - totalWidth / 2
        let originY = centerY - totalHeight / 2

        return CGRect(x: originX, y: originY, width: totalWidth, height: totalHeight)
    }

    private static func alignedRect(
        textSize: CGSize,
        centerX: CGFloat,
        y: CGFloat,
        alignment: TextAlignment,
        containerWidth: CGFloat
    ) -> CGRect {
        let x: CGFloat
        switch alignment {
        case .left:
            x = centerX - containerWidth / 2
        case .center:
            x = centerX - textSize.width / 2
        case .right:
            x = centerX + containerWidth / 2 - textSize.width
        }
        return CGRect(x: x, y: y, width: textSize.width, height: textSize.height)
    }

    // MARK: - Drawing Helpers

    private static func drawBackgroundBand(
        in ctx: CGContext,
        rect: CGRect,
        color: UIColor,
        cornerRadius: CGFloat
    ) {
        let bandPath = UIBezierPath(
            roundedRect: rect,
            cornerRadius: cornerRadius
        )
        ctx.saveGState()
        ctx.setFillColor(color.cgColor)
        ctx.addPath(bandPath.cgPath)
        ctx.fillPath()
        ctx.restoreGState()
    }

    private static func drawTextWithShadow(
        _ attrString: NSAttributedString,
        in rect: CGRect,
        template: DesignTemplate,
        sizeRatio: CGFloat
    ) {
        // Only add shadow when there is no background band (text needs visibility on photos)
        if !template.showBackground {
            let shadowColor = UIColor.black.withAlphaComponent(0.5)
            let shadowOffset = CGSize(width: 0, height: 1 * sizeRatio)
            let shadowBlurRadius = 4 * sizeRatio

            let ctx = UIGraphicsGetCurrentContext()
            ctx?.saveGState()
            ctx?.setShadow(offset: shadowOffset, blur: shadowBlurRadius, color: shadowColor.cgColor)
            attrString.draw(in: rect)
            ctx?.restoreGState()
        } else {
            attrString.draw(in: rect)
        }
    }

    // MARK: - Font Helpers

    private static func fontDesign(for template: DesignTemplate) -> UIFontDescriptor.SystemDesign {
        switch template.id {
        case .soft, .poster:
            return .rounded
        case .minimal, .film:
            return .default
        }
    }

    private static func uiKitWeight(from weight: DesignTemplate.FontWeight) -> UIFont.Weight {
        switch weight {
        case .thin:     return .thin
        case .light:    return .light
        case .regular:  return .regular
        case .medium:   return .medium
        case .semibold: return .semibold
        case .bold:     return .bold
        case .heavy:    return .heavy
        }
    }

    private static func heavierWeight(than weight: UIFont.Weight) -> UIFont.Weight {
        switch weight {
        case .thin:       return .light
        case .light:      return .regular
        case .regular:    return .semibold
        case .medium:     return .semibold
        case .semibold:   return .bold
        case .bold:       return .heavy
        case .heavy:      return .heavy
        default:          return .bold
        }
    }
}

// MARK: - UIColor Hex Init

extension UIColor {

    /// Creates a UIColor from a hex string (6 or 8 characters, optional `#`).
    convenience init(hex: String) {
        let sanitised = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: sanitised).scanHexInt64(&rgb)

        let r, g, b, a: CGFloat

        switch sanitised.count {
        case 6:
            r = CGFloat((rgb >> 16) & 0xFF) / 255.0
            g = CGFloat((rgb >> 8) & 0xFF) / 255.0
            b = CGFloat(rgb & 0xFF) / 255.0
            a = 1.0
        case 8:
            r = CGFloat((rgb >> 24) & 0xFF) / 255.0
            g = CGFloat((rgb >> 16) & 0xFF) / 255.0
            b = CGFloat((rgb >> 8) & 0xFF) / 255.0
            a = CGFloat(rgb & 0xFF) / 255.0
        default:
            r = 0; g = 0; b = 0; a = 1.0
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

// MARK: - NSAttributedString Size Helper

extension NSAttributedString {

    /// Computes the bounding size of the attributed string constrained to a maximum width.
    func boundingSize(maxWidth: CGFloat) -> CGSize {
        let constraintRect = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        let rect = boundingRect(
            with: constraintRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return CGSize(
            width: ceil(rect.width),
            height: ceil(rect.height)
        )
    }
}
