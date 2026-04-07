import Foundation
import Observation
import Photos
import SwiftUI
import UIKit

// MARK: - EditorViewModel

/// Drives the editor screen: manages text overlay state, design template selection,
/// and final image rendering / saving.
@Observable
final class EditorViewModel {

    // MARK: - Edit Tool

    enum EditTool: String, CaseIterable, Identifiable {
        case none
        case template
        case layout
        case textSize
        case textColor
        case background

        var id: String { rawValue }

        var label: String {
            switch self {
            case .none:       return ""
            case .template:   return "テンプレート"
            case .layout:     return "レイアウト"
            case .textSize:   return "サイズ"
            case .textColor:  return "カラー"
            case .background: return "背景"
            }
        }

        var systemImage: String {
            switch self {
            case .none:       return ""
            case .template:   return "square.grid.2x2"
            case .layout:     return "text.alignleft"
            case .textSize:   return "textformat.size"
            case .textColor:  return "paintpalette"
            case .background: return "rectangle.on.rectangle"
            }
        }
    }

    // MARK: - Input

    var image: UIImage
    var event: Event

    // MARK: - Editor State

    var designTemplateType: DesignTemplateType
    var layoutMode: LayoutMode
    var phraseTemplateId: String
    var customPhraseMode: Bool
    var customSingleLine: String
    var customLine1: String
    var customLine2: String

    // MARK: - Overlay Adjustments

    /// Normalized 0-1 position of the text overlay center within the image bounds.
    var textPosition: CGPoint
    /// Font size multiplier (0.5 - 2.0).
    var textScale: CGFloat = 1.0
    /// Optional colour override for the text. `nil` uses the template default.
    var textColorOverride: Color?
    /// Whether to show a semi-transparent background band behind the text.
    var showBackgroundBand: Bool

    // MARK: - UI State

    var isSaving: Bool = false
    var showSaveSuccess: Bool = false
    var showShareSheet: Bool = false
    var activeEditTool: EditTool = .none
    var saveErrorMessage: String?

    // MARK: - Computed

    /// The current design template object.
    var currentDesignTemplate: DesignTemplate {
        DesignTemplateStore.template(for: designTemplateType)
    }

    /// Day count calculated from the event.
    var dayCount: Int {
        DateCalculator.calculateDays(baseDate: event.baseDate, countType: event.countType)
    }

    /// Generates the display text lines from the phrase template and day count.
    var displayText: (line1: String, line2: String, singleLine: String) {
        if customPhraseMode {
            return (
                line1: customLine1,
                line2: customLine2,
                singleLine: customSingleLine
            )
        }

        // Find the phrase template
        let phraseTemplate: PhraseTemplate
        if let found = PhraseTemplateStore.allTemplates.first(where: { $0.id == phraseTemplateId }) {
            phraseTemplate = found
        } else {
            phraseTemplate = PhraseTemplateStore.defaultTemplate(for: event.countType)
        }

        let store = PhraseTemplateStore()
        let result = store.generateText(
            template: phraseTemplate,
            label: event.name,
            count: dayCount,
            layoutMode: layoutMode
        )
        return result
    }

    /// The hex string of the effective text colour (override or template default).
    var effectiveTextColorHex: String? {
        guard let override = textColorOverride else { return nil }
        return override.toHex()
    }

    // MARK: - Rendered Image Cache

    /// The last rendered final image, kept for sharing after save.
    private var renderedImage: UIImage?

    // MARK: - Init

    init(image: UIImage, event: Event) {
        self.image = image
        self.event = event

        // Initialise editor state from the event's saved preferences
        self.designTemplateType = event.designTemplateId
        self.layoutMode = event.layoutMode
        self.phraseTemplateId = event.phraseTemplateId
        self.customPhraseMode = event.customPhraseMode
        self.customSingleLine = event.customSingleLine ?? ""
        self.customLine1 = event.customLine1 ?? ""
        self.customLine2 = event.customLine2 ?? ""

        // Default text position: lower-centre of the image
        self.textPosition = CGPoint(x: 0.5, y: 0.75)

        // Use the template's default for background band
        let template = DesignTemplateStore.template(for: event.designTemplateId)
        self.showBackgroundBand = template.showBackground
    }

    // MARK: - Actions

    /// Switches to a new design template and resets overlay defaults.
    func changeDesignTemplate(_ type: DesignTemplateType) {
        designTemplateType = type
        let template = DesignTemplateStore.template(for: type)
        showBackgroundBand = template.showBackground
        layoutMode = template.defaultLayoutMode

        // Clear colour override so the template's default applies
        textColorOverride = nil
    }

    /// Toggles between single-line and double-line layout.
    func toggleLayoutMode() {
        layoutMode = (layoutMode == .single) ? .double : .single
    }

    /// Selects an edit tool, or deselects it if it is already active.
    func selectTool(_ tool: EditTool) {
        if activeEditTool == tool {
            activeEditTool = .none
        } else {
            activeEditTool = tool
        }
    }

    // MARK: - Rendering & Saving

    /// Renders the final composited image at full resolution.
    private func renderFinalImage() -> UIImage? {
        let text = displayText
        return EditorImageRenderer.renderFinalImage(
            baseImage: image,
            designTemplate: currentDesignTemplate,
            layoutMode: layoutMode,
            line1: text.line1,
            line2: text.line2,
            singleLine: text.singleLine,
            textPosition: textPosition,
            textScale: textScale,
            textColorHex: effectiveTextColorHex,
            showBackground: showBackgroundBand
        )
    }

    /// Renders the final image and saves it to the user's photo library.
    /// Returns `true` on success.
    @MainActor
    func save() async -> Bool {
        isSaving = true
        saveErrorMessage = nil

        guard let finalImage = renderFinalImage() else {
            saveErrorMessage = "画像の生成に失敗しました"
            isSaving = false
            return false
        }

        renderedImage = finalImage

        let success = await saveToPhotoLibrary(finalImage)

        isSaving = false

        if success {
            showSaveSuccess = true
        } else {
            saveErrorMessage = "写真ライブラリへの保存に失敗しました"
        }

        return success
    }

    /// Returns the rendered image for sharing. If not yet rendered, renders on-demand.
    func shareImage() -> UIImage {
        if let cached = renderedImage {
            return cached
        }
        let final = renderFinalImage() ?? image
        renderedImage = final
        return final
    }

    // MARK: - Photo Library

    private func saveToPhotoLibrary(_ image: UIImage) async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            return false
        }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                request.creationDate = Date()
            } completionHandler: { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}

// MARK: - Color Hex Helpers

extension Color {

    /// Converts a SwiftUI `Color` to a hex string (e.g. "#FFFFFF").
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }

        let r = components.count > 0 ? components[0] : 0
        let g = components.count > 1 ? components[1] : 0
        let b = components.count > 2 ? components[2] : 0

        return String(
            format: "#%02X%02X%02X",
            Int(r * 255),
            Int(g * 255),
            Int(b * 255)
        )
    }
}
