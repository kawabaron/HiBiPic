import Foundation
import SwiftUI

// MARK: - TextOverlayView

/// The SwiftUI text overlay rendered on top of the photo preview.
/// Styled differently depending on the active `DesignTemplate`.
struct TextOverlayView: View {

    // MARK: - Properties

    let designTemplate: DesignTemplate
    let fontPreset: FontPreset
    let layoutMode: LayoutMode
    let displayText: EditorDisplayText
    let canvasSize: CGSize
    let scale: CGFloat
    let textAlignment: TextAlignment
    let colorOverride: Color?
    let showBackground: Bool
    let backgroundColorHex: String

    // MARK: - Derived

    private var textColor: Color {
        colorOverride ?? Color(hex: designTemplate.textColor)
    }

    private var bandColor: Color {
        Color(hex: backgroundColorHex)
    }

    private var fontWeight: Font.Weight {
        switch designTemplate.fontWeight {
        case .thin:     return .thin
        case .light:    return .light
        case .regular:  return .regular
        case .medium:   return .medium
        case .semibold: return .semibold
        case .bold:     return .bold
        case .heavy:    return .heavy
        }
    }

    private var metrics: EditorTextLayoutMetrics {
        EditorTextLayout.metrics(
            designTemplate: designTemplate,
            layoutMode: layoutMode,
            textScale: scale,
            canvasSize: canvasSize
        )
    }

    private var renderedLines: [EditorOverlayLine] {
        layoutMode == .single ? [] : displayText.multiLines
    }

    private var horizontalAlignment: HorizontalAlignment {
        switch textAlignment {
        case .left:   return .leading
        case .center: return .center
        case .right:  return .trailing
        }
    }

    private var multilineAlignment: SwiftUI.TextAlignment {
        switch textAlignment {
        case .left:   return .leading
        case .center: return .center
        case .right:  return .trailing
        }
    }

    private func overlayFont(
        size: CGFloat,
        weight: Font.Weight,
        text: String,
        isEmphasized: Bool = false
    ) -> Font {
        OverlayFontResolver.swiftUIFont(
            preset: fontPreset,
            size: size,
            weight: weight,
            designTemplate: designTemplate,
            text: text,
            isEmphasized: isEmphasized
        )
    }

    private func overlayTracking(
        size: CGFloat,
        text: String,
        isEmphasized: Bool = false
    ) -> CGFloat {
        OverlayFontResolver.tracking(
            preset: fontPreset,
            size: size,
            designTemplate: designTemplate,
            text: text,
            isEmphasized: isEmphasized
        )
    }

    // MARK: - Body

    var body: some View {
        templateContent
            .padding(.horizontal, metrics.horizontalPadding)
            .padding(.vertical, metrics.verticalPadding)
            .background {
                if showBackground {
                    backgroundBand
                }
            }
    }

    // MARK: - Template Content

    @ViewBuilder
    private var templateContent: some View {
        switch designTemplate.id {
        case .minimal:
            minimalLayout
        case .soft, .diary, .cleanLabel, .airy:
            softLayout
        case .film, .classic, .memory:
            filmLayout
        case .poster, .milestone:
            posterLayout
        }
    }

    // MARK: - Minimal Template

    @ViewBuilder
    private var minimalLayout: some View {
        if layoutMode == .single {
            styledText(
                text: displayText.singleLine,
                fontSize: EditorTextLayout.singleLineFontSize(
                    metrics: metrics,
                    scaleMultiplier: displayText.singleLineScaleMultiplier
                ),
                weight: fontWeight,
                numbersOnlyLarge: displayText.singleLineNumbersOnlyLarge
            )
            .foregroundStyle(textColor)
            .multilineTextAlignment(multilineAlignment)
            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 1)
        } else {
            multilineStack(
                lineSpacing: metrics.lineSpacing,
                shadowColor: .black.opacity(0.5),
                shadowRadius: 4
            ) { index, line, lineCount in
                lineView(
                    line: line,
                    index: index,
                    lineCount: lineCount,
                    weight: fontWeight
                )
                .foregroundStyle(textColor)
            }
        }
    }

    // MARK: - Soft Template

    @ViewBuilder
    private var softLayout: some View {
        if layoutMode == .single {
            styledText(
                text: displayText.singleLine,
                fontSize: EditorTextLayout.singleLineFontSize(
                    metrics: metrics,
                    scaleMultiplier: displayText.singleLineScaleMultiplier
                ),
                weight: fontWeight,
                numbersOnlyLarge: displayText.singleLineNumbersOnlyLarge
            )
            .foregroundStyle(textColor)
            .multilineTextAlignment(multilineAlignment)
        } else {
            let highlightedIndex = highlightedMultiLineIndex(lineCount: renderedLines.count)

            multilineStack(lineSpacing: metrics.lineSpacing) { index, line, lineCount in
                lineView(
                    line: line,
                    index: index,
                    lineCount: lineCount,
                    weight: index == highlightedIndex ? .semibold : fontWeight,
                    useEmphasizedResolver: index == highlightedIndex
                )
                .foregroundStyle(index == highlightedIndex ? textColor : textColor.opacity(0.9))
            }
        }
    }

    // MARK: - Film Template

    @ViewBuilder
    private var filmLayout: some View {
        if layoutMode == .single {
            styledText(
                text: displayText.singleLine,
                fontSize: EditorTextLayout.singleLineFontSize(
                    metrics: metrics,
                    scaleMultiplier: displayText.singleLineScaleMultiplier
                ),
                weight: fontWeight,
                numbersOnlyLarge: displayText.singleLineNumbersOnlyLarge
            )
            .foregroundStyle(textColor)
            .multilineTextAlignment(multilineAlignment)
            .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 1)
        } else {
            multilineStack(
                lineSpacing: metrics.lineSpacing,
                shadowColor: .black.opacity(0.4),
                shadowRadius: 3
            ) { index, line, lineCount in
                lineView(
                    line: line,
                    index: index,
                    lineCount: lineCount,
                    weight: fontWeight
                )
                .foregroundStyle(index == lineCount - 1 ? textColor : textColor.opacity(0.85))
            }
        }
    }

    // MARK: - Poster Template

    @ViewBuilder
    private var posterLayout: some View {
        if layoutMode == .single {
            styledText(
                text: displayText.singleLine,
                fontSize: EditorTextLayout.singleLineFontSize(
                    metrics: metrics,
                    scaleMultiplier: displayText.singleLineScaleMultiplier
                ),
                weight: fontWeight,
                numbersOnlyLarge: displayText.singleLineNumbersOnlyLarge
            )
            .foregroundStyle(textColor)
            .multilineTextAlignment(multilineAlignment)
        } else {
            let highlightedIndex = highlightedMultiLineIndex(lineCount: renderedLines.count)

            multilineStack(lineSpacing: metrics.lineSpacing * 0.6) { index, line, lineCount in
                lineView(
                    line: line,
                    index: index,
                    lineCount: lineCount,
                    weight: index == highlightedIndex ? .heavy : .medium,
                    useEmphasizedResolver: index == highlightedIndex,
                    uppercase: index == 0
                )
                .foregroundStyle(index == highlightedIndex ? textColor : textColor.opacity(0.9))
            }
        }
    }

    // MARK: - Shared Builders

    private func multilineStack<LineContent: View>(
        lineSpacing: CGFloat,
        shadowColor: Color? = nil,
        shadowRadius: CGFloat = 0,
        @ViewBuilder lineContent: @escaping (_ index: Int, _ line: EditorOverlayLine, _ lineCount: Int) -> LineContent
    ) -> some View {
        let lineCount = renderedLines.count

        return VStack(alignment: horizontalAlignment, spacing: lineSpacing) {
            ForEach(Array(renderedLines.enumerated()), id: \.element.id) { index, line in
                lineContent(index, line, lineCount)
            }
        }
        .multilineTextAlignment(multilineAlignment)
        .shadow(
            color: shadowColor?.opacity(1) ?? .clear,
            radius: shadowRadius,
            x: 0,
            y: shadowColor == nil ? 0 : 1
        )
    }

    private func lineView(
        line: EditorOverlayLine,
        index: Int,
        lineCount: Int,
        weight: Font.Weight,
        useEmphasizedResolver: Bool = false,
        uppercase: Bool = false
    ) -> some View {
        let fontSize = EditorTextLayout.multiLineFontSize(
            metrics: metrics,
            designTemplate: designTemplate,
            lineIndex: index,
            lineCount: lineCount,
            scaleMultiplier: line.scaleMultiplier
        )

        return styledText(
            text: line.text,
            fontSize: fontSize,
            weight: weight,
            isEmphasized: useEmphasizedResolver,
            numbersOnlyLarge: line.numbersOnlyLarge
        )
        .textCase(uppercase ? .uppercase : nil)
    }

    private func styledText(
        text: String,
        fontSize: CGFloat,
        weight: Font.Weight,
        isEmphasized: Bool = false,
        numbersOnlyLarge: Bool = false
    ) -> Text {
        let baseFont = overlayFont(size: fontSize, weight: weight, text: text, isEmphasized: isEmphasized)
        let baseTracking = overlayTracking(size: fontSize, text: text, isEmphasized: isEmphasized)

        guard numbersOnlyLarge else {
            return Text(text)
                .font(baseFont)
                .tracking(baseTracking)
        }

        let emphasizedSize = EditorTextLayout.emphasizedDigitFontSize(baseFontSize: fontSize)
        let emphasizedWeight = heavierWeight(than: weight)
        let emphasizedFont = overlayFont(
            size: emphasizedSize,
            weight: emphasizedWeight,
            text: text,
            isEmphasized: true
        )
        let emphasizedTracking = overlayTracking(size: emphasizedSize, text: text, isEmphasized: true)
        let segments = textSegments(for: text)

        return segments.reduce(Text("")) { partial, segment in
            partial + Text(segment.text)
                .font(segment.isNumber ? emphasizedFont : baseFont)
                .tracking(segment.isNumber ? emphasizedTracking : baseTracking)
        }
    }

    private func highlightedMultiLineIndex(lineCount: Int) -> Int? {
        guard designTemplate.numberEmphasis, lineCount > 1 else { return nil }
        return min(1, lineCount - 1)
    }

    private func textSegments(for text: String) -> [(text: String, isNumber: Bool)] {
        guard let regex = try? NSRegularExpression(pattern: "[0-9０-９]+") else {
            return [(text, false)]
        }

        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: nsRange)
        guard !matches.isEmpty else { return [(text, false)] }

        var segments: [(text: String, isNumber: Bool)] = []
        var currentIndex = text.startIndex

        for match in matches {
            guard let range = Range(match.range, in: text) else { continue }

            if currentIndex < range.lowerBound {
                segments.append((String(text[currentIndex..<range.lowerBound]), false))
            }

            segments.append((String(text[range]), true))
            currentIndex = range.upperBound
        }

        if currentIndex < text.endIndex {
            segments.append((String(text[currentIndex..<text.endIndex]), false))
        }

        return segments
    }

    private func heavierWeight(than weight: Font.Weight) -> Font.Weight {
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

    // MARK: - Background Band

    private var backgroundBand: some View {
        RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
            .fill(bandColor)
    }
}

// MARK: - Preview

#Preview("Minimal Single") {
    ZStack {
        Color.gray
        TextOverlayView(
            designTemplate: DesignTemplateStore.template(for: .minimal),
            fontPreset: .standard,
            layoutMode: .single,
            displayText: EditorDisplayText(
                singleLine: "誕生日まで あと30日",
                singleLineScaleMultiplier: 1.0,
                singleLineNumbersOnlyLarge: true,
                multiLines: []
            ),
            canvasSize: CGSize(width: 400, height: 600),
            scale: 1.0,
            textAlignment: .center,
            colorOverride: nil,
            showBackground: false,
            backgroundColorHex: "#2C2C2ECC"
        )
    }
}

#Preview("Milestone Multi") {
    ZStack {
        Color.gray
        TextOverlayView(
            designTemplate: DesignTemplateStore.template(for: .milestone),
            fontPreset: .editorialSerif,
            layoutMode: .double,
            displayText: EditorDisplayText(
                singleLine: "",
                singleLineScaleMultiplier: 1.0,
                singleLineNumbersOnlyLarge: false,
                multiLines: [
                    EditorOverlayLine(id: 0, text: "禁煙", scaleMultiplier: 1.0, numbersOnlyLarge: false),
                    EditorOverlayLine(id: 1, text: "30日", scaleMultiplier: 1.24, numbersOnlyLarge: true),
                    EditorOverlayLine(id: 2, text: "継続中", scaleMultiplier: 1.0, numbersOnlyLarge: false),
                ]
            ),
            canvasSize: CGSize(width: 400, height: 600),
            scale: 1.0,
            textAlignment: .center,
            colorOverride: nil,
            showBackground: true,
            backgroundColorHex: "#000000AA"
        )
    }
}
