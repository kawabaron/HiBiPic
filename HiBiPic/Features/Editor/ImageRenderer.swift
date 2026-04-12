import CoreGraphics
import Foundation
import UIKit

struct EditorImageGeometry {
    let canvasSize: CGSize

    init(image: UIImage) {
        canvasSize = Self.canvasSize(for: image)
    }

    func previewLayout(in containerSize: CGSize) -> EditorPreviewLayout {
        EditorPreviewLayout(containerSize: containerSize, imageSize: canvasSize)
    }

    private static func canvasSize(for image: UIImage) -> CGSize {
        let logicalSize = image.size

        guard let cgImage = image.cgImage else {
            return logicalSize
        }

        let rawPixelSize = CGSize(
            width: CGFloat(cgImage.width) / max(image.scale, 1),
            height: CGFloat(cgImage.height) / max(image.scale, 1)
        )
        let orientedPixelSize = orientedSize(for: rawPixelSize, orientation: image.imageOrientation)

        if approximatelyEqual(logicalSize, orientedPixelSize) {
            return logicalSize
        }

        if approximatelyEqual(logicalSize, rawPixelSize) {
            return orientedPixelSize
        }

        return logicalSize
    }

    private static func orientedSize(for size: CGSize, orientation: UIImage.Orientation) -> CGSize {
        switch orientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            return CGSize(width: size.height, height: size.width)
        default:
            return size
        }
    }

    private static func approximatelyEqual(
        _ lhs: CGSize,
        _ rhs: CGSize,
        tolerance: CGFloat = 0.5
    ) -> Bool {
        abs(lhs.width - rhs.width) <= tolerance &&
            abs(lhs.height - rhs.height) <= tolerance
    }
}

struct EditorPreviewLayout {
    let displaySize: CGSize
    let displayRect: CGRect

    init(containerSize: CGSize, imageSize: CGSize) {
        let safeImageWidth = max(imageSize.width, 1)
        let safeImageHeight = max(imageSize.height, 1)
        let imageAspect = safeImageWidth / safeImageHeight
        let areaAspect = containerSize.width / max(containerSize.height, 1)

        if imageAspect > areaAspect {
            let width = containerSize.width
            let height = width / imageAspect
            displaySize = CGSize(width: width, height: height)
        } else {
            let height = containerSize.height
            let width = height * imageAspect
            displaySize = CGSize(width: width, height: height)
        }

        displayRect = CGRect(
            x: (containerSize.width - displaySize.width) / 2,
            y: (containerSize.height - displaySize.height) / 2,
            width: displaySize.width,
            height: displaySize.height
        )
    }
}

// MARK: - EditorTextLayout

struct EditorTextLayoutMetrics {
    let singleFontSize: CGFloat
    let multiLineBaseFontSize: CGFloat
    let multiLineSecondaryFontSize: CGFloat
    let multiLineEmphasizedFontSize: CGFloat
    let lineSpacing: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let cornerRadius: CGFloat
    let maxTextWidth: CGFloat
    let baseWeight: UIFont.Weight
    let emphasisedWeight: UIFont.Weight
}

enum EditorTextLayout {

    static let legacyLargeLineScale: CGFloat = 1.24
    private static let digitEmphasisScale: CGFloat = 1.32

    static func metrics(
        designTemplate: DesignTemplate,
        layoutMode: LayoutMode,
        textScale: CGFloat,
        canvasSize: CGSize
    ) -> EditorTextLayoutMetrics {
        let referenceDimension: CGFloat = 1080
        let sizeRatio = min(canvasSize.width, canvasSize.height) / referenceDimension
        let baseFontSize = 48 * sizeRatio * designTemplate.fontSizeScale * textScale
        let numberFontSize = 84 * sizeRatio * designTemplate.fontSizeScale * textScale
        let smallFontSize = 42 * sizeRatio * designTemplate.fontSizeScale * textScale
        let baseWeight = uiKitWeight(from: designTemplate.fontWeight)

        return EditorTextLayoutMetrics(
            singleFontSize: baseFontSize,
            multiLineBaseFontSize: baseFontSize,
            multiLineSecondaryFontSize: smallFontSize,
            multiLineEmphasizedFontSize: numberFontSize,
            lineSpacing: 8 * sizeRatio * textScale,
            horizontalPadding: 20 * sizeRatio * max(textScale, 0.9),
            verticalPadding: 18 * sizeRatio * max(textScale, 0.9),
            cornerRadius: 8 * sizeRatio * textScale,
            maxTextWidth: canvasSize.width * 0.85,
            baseWeight: baseWeight,
            emphasisedWeight: designTemplate.numberEmphasis
                ? heavierWeight(than: baseWeight)
                : baseWeight
        )
    }

    static func singleLineFontSize(
        metrics: EditorTextLayoutMetrics,
        scaleMultiplier: CGFloat
    ) -> CGFloat {
        metrics.singleFontSize * scaleMultiplier
    }

    static func multiLineFontSize(
        metrics: EditorTextLayoutMetrics,
        designTemplate: DesignTemplate,
        lineIndex: Int,
        lineCount: Int,
        scaleMultiplier: CGFloat
    ) -> CGFloat {
        let baseSize: CGFloat

        if let emphasizedIndex = emphasizedMultiLineIndex(for: designTemplate, lineCount: lineCount) {
            baseSize = lineIndex == emphasizedIndex
                ? metrics.multiLineEmphasizedFontSize
                : metrics.multiLineSecondaryFontSize
        } else {
            baseSize = metrics.multiLineBaseFontSize
        }

        return baseSize * scaleMultiplier
    }

    static func emphasizedDigitFontSize(baseFontSize: CGFloat) -> CGFloat {
        baseFontSize * digitEmphasisScale
    }

    static func emphasizedMultiLineIndex(for designTemplate: DesignTemplate, lineCount: Int) -> Int? {
        guard designTemplate.numberEmphasis, lineCount > 1 else { return nil }
        return min(1, lineCount - 1)
    }

    static func lineUsesEmphasizedResolver(
        designTemplate: DesignTemplate,
        lineIndex: Int,
        lineCount: Int
    ) -> Bool {
        emphasizedMultiLineIndex(for: designTemplate, lineCount: lineCount) == lineIndex
    }

    static func multiLineWeight(
        designTemplate: DesignTemplate,
        metrics: EditorTextLayoutMetrics,
        lineIndex: Int,
        lineCount: Int
    ) -> UIFont.Weight {
        switch designTemplate.id {
        case .minimal, .film, .classic, .memory, .airy:
            return metrics.baseWeight
        case .soft, .diary, .cleanLabel:
            return lineUsesEmphasizedResolver(
                designTemplate: designTemplate,
                lineIndex: lineIndex,
                lineCount: lineCount
            ) ? .semibold : metrics.baseWeight
        case .poster, .milestone:
            return lineUsesEmphasizedResolver(
                designTemplate: designTemplate,
                lineIndex: lineIndex,
                lineCount: lineCount
            ) ? .heavy : .medium
        }
    }

    static func overlaySize(
        designTemplate: DesignTemplate,
        fontPreset: FontPreset,
        layoutMode: LayoutMode,
        displayText: EditorDisplayText,
        textScale: CGFloat,
        textAlignment: TextAlignment,
        canvasSize: CGSize
    ) -> CGSize {
        let metrics = metrics(
            designTemplate: designTemplate,
            layoutMode: layoutMode,
            textScale: textScale,
            canvasSize: canvasSize
        )
        let measureColor = UIColor.white

        if layoutMode == .single {
            let fontSize = singleLineFontSize(
                metrics: metrics,
                scaleMultiplier: displayText.singleLineScaleMultiplier
            )
            let attributed = attributedString(
                text: displayText.singleLine,
                fontSize: fontSize,
                weight: metrics.baseWeight,
                color: measureColor,
                alignment: textAlignment,
                fontPreset: fontPreset,
                designTemplate: designTemplate,
                numbersOnlyLarge: displayText.singleLineNumbersOnlyLarge,
                emphasizedFontSize: emphasizedDigitFontSize(baseFontSize: fontSize),
                emphasizedWeight: heavierWeight(than: metrics.baseWeight)
            )
            let textSize = attributed.boundingSize(maxWidth: metrics.maxTextWidth)
            return CGSize(
                width: textSize.width + metrics.horizontalPadding * 2,
                height: textSize.height + metrics.verticalPadding * 2
            )
        }

        let attributedLines = displayText.multiLines.enumerated().map { index, line in
            let fontSize = multiLineFontSize(
                metrics: metrics,
                designTemplate: designTemplate,
                lineIndex: index,
                lineCount: displayText.multiLines.count,
                scaleMultiplier: line.scaleMultiplier
            )
            let weight = multiLineWeight(
                designTemplate: designTemplate,
                metrics: metrics,
                lineIndex: index,
                lineCount: displayText.multiLines.count
            )
            let isEmphasized = lineUsesEmphasizedResolver(
                designTemplate: designTemplate,
                lineIndex: index,
                lineCount: displayText.multiLines.count
            )

            return attributedString(
                text: line.text,
                fontSize: fontSize,
                weight: weight,
                color: measureColor,
                alignment: textAlignment,
                fontPreset: fontPreset,
                designTemplate: designTemplate,
                isEmphasized: isEmphasized,
                numbersOnlyLarge: line.numbersOnlyLarge,
                emphasizedFontSize: emphasizedDigitFontSize(baseFontSize: fontSize),
                emphasizedWeight: heavierWeight(than: weight)
            )
        }

        let sizes = attributedLines.map { $0.boundingSize(maxWidth: metrics.maxTextWidth) }
        let totalTextWidth = sizes.map(\.width).max() ?? 0
        let lineSpacing = displayText.multiLines.count > 1
            ? lineSpacing(designTemplate: designTemplate, metrics: metrics)
            : 0
        let totalTextHeight = sizes.map(\.height).reduce(0, +)
            + lineSpacing * CGFloat(max(displayText.multiLines.count - 1, 0))

        return CGSize(
            width: totalTextWidth + metrics.horizontalPadding * 2,
            height: totalTextHeight + metrics.verticalPadding * 2
        )
    }

    static func attributedString(
        text: String,
        fontSize: CGFloat,
        weight: UIFont.Weight,
        color: UIColor,
        alignment: TextAlignment,
        fontPreset: FontPreset,
        designTemplate: DesignTemplate,
        isEmphasized: Bool = false,
        numbersOnlyLarge: Bool = false,
        emphasizedFontSize: CGFloat? = nil,
        emphasizedWeight: UIFont.Weight? = nil
    ) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        switch alignment {
        case .left:
            paragraphStyle.alignment = .left
        case .center:
            paragraphStyle.alignment = .center
        case .right:
            paragraphStyle.alignment = .right
        }

        let font = OverlayFontResolver.uiFont(
            preset: fontPreset,
            size: fontSize,
            weight: weight,
            designTemplate: designTemplate,
            text: text,
            isEmphasized: isEmphasized
        )
        let tracking = OverlayFontResolver.tracking(
            preset: fontPreset,
            size: fontSize,
            designTemplate: designTemplate,
            text: text,
            isEmphasized: isEmphasized
        )

        let attributed = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle,
                .kern: tracking,
            ]
        )

        guard numbersOnlyLarge,
              let regex = try? NSRegularExpression(pattern: "[0-9０-９]+")
        else {
            return attributed
        }

        let emphasizedSize = emphasizedFontSize ?? emphasizedDigitFontSize(baseFontSize: fontSize)
        let emphasizedFont = OverlayFontResolver.uiFont(
            preset: fontPreset,
            size: emphasizedSize,
            weight: emphasizedWeight ?? heavierWeight(than: weight),
            designTemplate: designTemplate,
            text: text,
            isEmphasized: true
        )
        let emphasizedTracking = OverlayFontResolver.tracking(
            preset: fontPreset,
            size: emphasizedSize,
            designTemplate: designTemplate,
            text: text,
            isEmphasized: true
        )
        let matches = regex.matches(
            in: text,
            range: NSRange(text.startIndex..<text.endIndex, in: text)
        )

        for match in matches {
            attributed.addAttributes(
                [
                    .font: emphasizedFont,
                    .kern: emphasizedTracking,
                ],
                range: match.range
            )
        }

        return attributed
    }

    static func uiKitWeight(from weight: DesignTemplate.FontWeight) -> UIFont.Weight {
        switch weight {
        case .thin:
            return .thin
        case .light:
            return .light
        case .regular:
            return .regular
        case .medium:
            return .medium
        case .semibold:
            return .semibold
        case .bold:
            return .bold
        case .heavy:
            return .heavy
        }
    }

    static func heavierWeight(than weight: UIFont.Weight) -> UIFont.Weight {
        switch weight {
        case .thin:
            return .light
        case .light:
            return .regular
        case .regular:
            return .semibold
        case .medium:
            return .semibold
        case .semibold:
            return .bold
        case .bold:
            return .heavy
        case .heavy:
            return .heavy
        default:
            return .bold
        }
    }

    static func lineSpacing(
        designTemplate: DesignTemplate,
        metrics: EditorTextLayoutMetrics
    ) -> CGFloat {
        (designTemplate.id == .poster || designTemplate.id == .milestone)
            ? metrics.lineSpacing * 0.6
            : metrics.lineSpacing
    }
}

// MARK: - EditorImageRenderer

/// Burns the text overlay into a photo at full resolution, producing
/// the final sharable / saveable image.
final class EditorImageRenderer {

    // MARK: - Public API

    static func renderFinalImage(
        baseImage: UIImage,
        designTemplate: DesignTemplate,
        fontPreset: FontPreset,
        layoutMode: LayoutMode,
        displayText: EditorDisplayText,
        textPosition: CGPoint,
        textScale: CGFloat,
        textAlignment: TextAlignment,
        textColorHex: String?,
        showBackground: Bool,
        backgroundColorHex: String
    ) -> UIImage? {

        let imageSize = EditorImageGeometry(image: baseImage).canvasSize
        guard imageSize.width > 0, imageSize.height > 0 else { return nil }

        let renderer = UIGraphicsImageRenderer(size: imageSize)

        return renderer.image { context in
            let ctx = context.cgContext

            baseImage.draw(in: CGRect(origin: .zero, size: imageSize))

            let metrics = EditorTextLayout.metrics(
                designTemplate: designTemplate,
                layoutMode: layoutMode,
                textScale: textScale,
                canvasSize: imageSize
            )
            let sizeRatio = min(imageSize.width, imageSize.height) / 1080

            let textColor = textColorHex.map(UIColor.init(hex:)) ?? UIColor(hex: designTemplate.textColor)
            let bandColor = UIColor(hex: backgroundColorHex)

            if layoutMode == .single {
                renderSingleLine(
                    displayText: displayText,
                    imageSize: imageSize,
                    position: textPosition,
                    designTemplate: designTemplate,
                    fontPreset: fontPreset,
                    metrics: metrics,
                    textAlignment: textAlignment,
                    textColor: textColor,
                    bandColor: bandColor,
                    showBackground: showBackground,
                    context: ctx,
                    sizeRatio: sizeRatio
                )
            } else {
                renderMultiLine(
                    displayText: displayText,
                    imageSize: imageSize,
                    position: textPosition,
                    designTemplate: designTemplate,
                    fontPreset: fontPreset,
                    metrics: metrics,
                    textAlignment: textAlignment,
                    textColor: textColor,
                    bandColor: bandColor,
                    showBackground: showBackground,
                    context: ctx,
                    sizeRatio: sizeRatio
                )
            }
        }
    }

    // MARK: - Rendering Helpers

    private static func renderSingleLine(
        displayText: EditorDisplayText,
        imageSize: CGSize,
        position: CGPoint,
        designTemplate: DesignTemplate,
        fontPreset: FontPreset,
        metrics: EditorTextLayoutMetrics,
        textAlignment: TextAlignment,
        textColor: UIColor,
        bandColor: UIColor,
        showBackground: Bool,
        context: CGContext,
        sizeRatio: CGFloat
    ) {
        let fontSize = EditorTextLayout.singleLineFontSize(
            metrics: metrics,
            scaleMultiplier: displayText.singleLineScaleMultiplier
        )
        let attrString = EditorTextLayout.attributedString(
            text: displayText.singleLine,
            fontSize: fontSize,
            weight: metrics.baseWeight,
            color: textColor,
            alignment: textAlignment,
            fontPreset: fontPreset,
            designTemplate: designTemplate,
            numbersOnlyLarge: displayText.singleLineNumbersOnlyLarge,
            emphasizedFontSize: EditorTextLayout.emphasizedDigitFontSize(baseFontSize: fontSize),
            emphasizedWeight: EditorTextLayout.heavierWeight(than: metrics.baseWeight)
        )
        let textRect = calculateTextRect(
            for: attrString,
            imageSize: imageSize,
            position: position,
            alignment: textAlignment,
            metrics: metrics
        )
        let contentRect = insetContentRect(
            from: textRect,
            metrics: metrics
        )

        if showBackground {
            drawBackgroundBand(
                in: context,
                rect: textRect,
                color: bandColor,
                cornerRadius: metrics.cornerRadius
            )
        }

        drawTextWithShadow(
            attrString,
            in: contentRect,
            showBackground: showBackground,
            sizeRatio: sizeRatio
        )
    }

    private static func renderMultiLine(
        displayText: EditorDisplayText,
        imageSize: CGSize,
        position: CGPoint,
        designTemplate: DesignTemplate,
        fontPreset: FontPreset,
        metrics: EditorTextLayoutMetrics,
        textAlignment: TextAlignment,
        textColor: UIColor,
        bandColor: UIColor,
        showBackground: Bool,
        context: CGContext,
        sizeRatio: CGFloat
    ) {
        let lineCount = displayText.multiLines.count
        guard lineCount > 0 else { return }

        let lineSpacing = EditorTextLayout.lineSpacing(
            designTemplate: designTemplate,
            metrics: metrics
        )

        let attributedLines = displayText.multiLines.enumerated().map { index, line in
            let fontSize = EditorTextLayout.multiLineFontSize(
                metrics: metrics,
                designTemplate: designTemplate,
                lineIndex: index,
                lineCount: lineCount,
                scaleMultiplier: line.scaleMultiplier
            )
            let weight = EditorTextLayout.multiLineWeight(
                designTemplate: designTemplate,
                metrics: metrics,
                lineIndex: index,
                lineCount: lineCount
            )
            let isEmphasized = EditorTextLayout.lineUsesEmphasizedResolver(
                designTemplate: designTemplate,
                lineIndex: index,
                lineCount: lineCount
            )
            let lineColor = multiLineColor(
                baseColor: textColor,
                designTemplate: designTemplate,
                lineIndex: index,
                lineCount: lineCount
            )

            return EditorTextLayout.attributedString(
                text: line.text,
                fontSize: fontSize,
                weight: weight,
                color: lineColor,
                alignment: textAlignment,
                fontPreset: fontPreset,
                designTemplate: designTemplate,
                isEmphasized: isEmphasized,
                numbersOnlyLarge: line.numbersOnlyLarge,
                emphasizedFontSize: EditorTextLayout.emphasizedDigitFontSize(baseFontSize: fontSize),
                emphasizedWeight: EditorTextLayout.heavierWeight(than: weight)
            )
        }

        let combinedRect = calculateMultilineRect(
            lines: attributedLines,
            spacing: lineSpacing,
            imageSize: imageSize,
            position: position,
            metrics: metrics
        )

        if showBackground {
            drawBackgroundBand(
                in: context,
                rect: combinedRect,
                color: bandColor,
                cornerRadius: metrics.cornerRadius
            )
        }

        let contentRect = insetContentRect(
            from: combinedRect,
            metrics: metrics
        )
        let sizes = attributedLines.map { $0.boundingSize(maxWidth: metrics.maxTextWidth) }
        let totalTextHeight = sizes.map(\.height).reduce(0, +)
            + lineSpacing * CGFloat(max(lineCount - 1, 0))
        var currentY = contentRect.minY + (contentRect.height - totalTextHeight) / 2

        for (index, attrLine) in attributedLines.enumerated() {
            let lineRect = alignedRect(
                textSize: sizes[index],
                centerX: contentRect.midX,
                y: currentY,
                alignment: textAlignment,
                containerWidth: contentRect.width
            )

            drawTextWithShadow(
                attrLine,
                in: lineRect,
                showBackground: showBackground,
                sizeRatio: sizeRatio
            )

            currentY += sizes[index].height + lineSpacing
        }
    }

    private static func multiLineColor(
        baseColor: UIColor,
        designTemplate: DesignTemplate,
        lineIndex: Int,
        lineCount: Int
    ) -> UIColor {
        switch designTemplate.id {
        case .minimal, .classic, .airy:
            return baseColor
        case .soft, .diary, .cleanLabel:
            let emphasizedIndex = EditorTextLayout.emphasizedMultiLineIndex(
                for: designTemplate,
                lineCount: lineCount
            )
            return lineIndex == emphasizedIndex ? baseColor : baseColor.withAlphaComponent(0.9)
        case .film, .memory:
            return lineIndex == lineCount - 1 ? baseColor : baseColor.withAlphaComponent(0.85)
        case .poster, .milestone:
            let emphasizedIndex = EditorTextLayout.emphasizedMultiLineIndex(
                for: designTemplate,
                lineCount: lineCount
            )
            return lineIndex == emphasizedIndex ? baseColor : baseColor.withAlphaComponent(0.9)
        }
    }

    // MARK: - Text Rect Calculation

    private static func calculateTextRect(
        for attrString: NSAttributedString,
        imageSize: CGSize,
        position: CGPoint,
        alignment: TextAlignment,
        metrics: EditorTextLayoutMetrics
    ) -> CGRect {
        let textSize = attrString.boundingSize(maxWidth: metrics.maxTextWidth)

        let centerX = imageSize.width * position.x
        let centerY = imageSize.height * position.y

        let totalWidth = textSize.width + metrics.horizontalPadding * 2
        let totalHeight = textSize.height + metrics.verticalPadding * 2

        let originX: CGFloat
        switch alignment {
        case .left:
            originX = max(metrics.horizontalPadding, centerX - totalWidth / 2)
        case .center:
            originX = centerX - totalWidth / 2
        case .right:
            originX = min(
                imageSize.width - totalWidth - metrics.horizontalPadding,
                centerX - totalWidth / 2
            )
        }

        let originY = centerY - totalHeight / 2

        return CGRect(
            x: originX,
            y: originY,
            width: totalWidth,
            height: totalHeight
        )
    }

    private static func calculateMultilineRect(
        lines: [NSAttributedString],
        spacing: CGFloat,
        imageSize: CGSize,
        position: CGPoint,
        metrics: EditorTextLayoutMetrics
    ) -> CGRect {
        let sizes = lines.map { $0.boundingSize(maxWidth: metrics.maxTextWidth) }
        let totalTextWidth = sizes.map(\.width).max() ?? 0
        let totalTextHeight = sizes.map(\.height).reduce(0, +)
            + spacing * CGFloat(max(lines.count - 1, 0))

        let totalWidth = totalTextWidth + metrics.horizontalPadding * 2
        let totalHeight = totalTextHeight + metrics.verticalPadding * 2

        let centerX = imageSize.width * position.x
        let centerY = imageSize.height * position.y

        return CGRect(
            x: centerX - totalWidth / 2,
            y: centerY - totalHeight / 2,
            width: totalWidth,
            height: totalHeight
        )
    }

    private static func insetContentRect(
        from rect: CGRect,
        metrics: EditorTextLayoutMetrics
    ) -> CGRect {
        rect.insetBy(dx: metrics.horizontalPadding, dy: metrics.verticalPadding)
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
        showBackground: Bool,
        sizeRatio: CGFloat
    ) {
        if !showBackground {
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
