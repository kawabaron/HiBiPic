import SwiftUI

// MARK: - CameraScreen

/// Full-screen camera view with a live preview, overlay text showing the event's
/// day count (styled per the selected design template), and bottom controls for
/// shutter, photo-library, and camera-flip.
struct CameraScreen: View {

    // MARK: - Properties

    let event: Event
    let onImageCaptured: (UIImage) -> Void
    let onPickerRequested: () -> Void
    let onDismiss: () -> Void

    @State private var viewModel = CameraViewModel()
    @State private var shutterPressed = false

    // MARK: - Computed

    private var dayCount: Int {
        DateCalculator.calculateDays(baseDate: event.baseDate, countType: event.countType)
    }

    private var designTemplate: DesignTemplate {
        DesignTemplateStore.template(for: event.designTemplateId)
    }

    private var overlayText: String {
        resolvedOverlayText()
    }

    private var overlaySecondLine: String? {
        resolvedOverlaySecondLine()
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Camera preview -- full screen
            cameraPreview

            // Overlay controls
            VStack(spacing: 0) {
                topOverlay
                Spacer()
                bottomBar
            }
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .task {
            await startCamera()
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }

    // MARK: - Camera Preview

    @ViewBuilder
    private var cameraPreview: some View {
        if viewModel.isCameraReady {
            CameraPreviewView(session: viewModel.session)
                .ignoresSafeArea()
        } else if let error = viewModel.cameraError {
            cameraErrorView(message: error)
        } else {
            Color.black
                .overlay {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                }
        }
    }

    // MARK: - Top Overlay

    private var topOverlay: some View {
        ZStack(alignment: .topLeading) {
            // Gradient scrim for readability
            LinearGradient(
                colors: [.black.opacity(0.5), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 140)

            VStack(spacing: 0) {
                // Close button + event info row
                HStack(alignment: .top) {
                    closeButton
                    Spacer()
                }
                .padding(.top, safeAreaTop + DSSpacing.sm)
                .padding(.horizontal, DSSpacing.lg)

                // Overlay text preview
                overlayTextPreview
                    .padding(.top, DSSpacing.sm)
                    .padding(.horizontal, DSSpacing.xl)
            }
        }
    }

    // MARK: - Close Button

    private var closeButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: Circle())
        }
    }

    // MARK: - Overlay Text Preview

    /// Shows a preview of the stamp text styled according to the selected
    /// design template. This is NOT burned into the camera feed -- it is
    /// purely a positioning preview.
    @ViewBuilder
    private var overlayTextPreview: some View {
        let textColor = Color(hex: designTemplate.textColor)
        let alignment = swiftUIAlignment(from: designTemplate.alignment)
        let font = overlayFont()

        VStack(spacing: DSSpacing.xxs) {
            if let secondLine = overlaySecondLine {
                // Double-line layout
                Text(overlayText)
                    .font(font)
                    .foregroundStyle(textColor.opacity(0.85))
                    .multilineTextAlignment(textAlignment(from: designTemplate.alignment))

                if designTemplate.numberEmphasis {
                    Text(secondLine)
                        .font(overlayFontEmphasised())
                        .foregroundStyle(textColor.opacity(0.85))
                        .multilineTextAlignment(textAlignment(from: designTemplate.alignment))
                } else {
                    Text(secondLine)
                        .font(font)
                        .foregroundStyle(textColor.opacity(0.85))
                        .multilineTextAlignment(textAlignment(from: designTemplate.alignment))
                }
            } else {
                // Single-line layout
                Text(overlayText)
                    .font(font)
                    .foregroundStyle(textColor.opacity(0.85))
                    .multilineTextAlignment(textAlignment(from: designTemplate.alignment))
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment)
        .padding(.vertical, designTemplate.showBackground ? DSSpacing.sm : 0)
        .padding(.horizontal, designTemplate.showBackground ? DSSpacing.md : 0)
        .background {
            if designTemplate.showBackground {
                RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous)
                    .fill(Color(hex: designTemplate.backgroundColor))
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(alignment: .center) {
            // Photo library button
            photoLibraryButton
            Spacer()
            // Shutter button
            shutterButton
            Spacer()
            // Camera flip button
            cameraFlipButton
        }
        .padding(.horizontal, DSSpacing.xxxl)
        .padding(.bottom, safeAreaBottom + DSSpacing.xl)
        .padding(.top, DSSpacing.xl)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Photo Library Button

    private var photoLibraryButton: some View {
        Button(action: onPickerRequested) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .contentShape(Rectangle())
        }
    }

    // MARK: - Shutter Button

    private var shutterButton: some View {
        Button {
            performCapture()
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(.white, lineWidth: 4)
                    .frame(width: 72, height: 72)

                Circle()
                    .fill(.white)
                    .frame(width: 60, height: 60)
            }
            .scaleEffect(shutterPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: shutterPressed)
        }
        .disabled(viewModel.isCapturing || !viewModel.isCameraReady)
        .opacity(viewModel.isCapturing ? 0.5 : 1.0)
    }

    // MARK: - Camera Flip Button

    private var cameraFlipButton: some View {
        Button {
            viewModel.switchCamera()
        } label: {
            Image(systemName: "camera.rotate")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .contentShape(Rectangle())
        }
    }

    // MARK: - Error View

    private func cameraErrorView(message: String) -> some View {
        Color.black
            .overlay {
                VStack(spacing: DSSpacing.lg) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.gray)

                    Text(message)
                        .font(DSTypography.body)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DSSpacing.xxxl)

                    if message.contains("許可") || message.contains("アクセス") {
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("設定を開く")
                                .font(DSTypography.headline)
                                .foregroundStyle(DSColors.accent)
                        }
                    }
                }
            }
    }

    // MARK: - Actions

    private func startCamera() async {
        let granted = await viewModel.requestCameraPermission()
        guard granted else {
            viewModel.cameraError = "カメラへのアクセスが許可されていません。設定からカメラへのアクセスを許可してください。"
            return
        }

        // Configure the session on a background thread
        await Task.detached(priority: .userInitiated) {
            await MainActor.run {
                viewModel.setupCamera()
            }
        }.value
    }

    private func performCapture() {
        shutterPressed = true

        Task {
            if let image = await viewModel.capturePhoto() {
                onImageCaptured(image)
            }
            shutterPressed = false
        }
    }

    // MARK: - Text Helpers

    private func resolvedOverlayText() -> String {
        if event.customPhraseMode {
            if event.layoutMode == .single {
                return event.customSingleLine ?? event.name
            } else {
                return event.customLine1 ?? event.name
            }
        }

        let template = PhraseTemplateStore.allTemplates.first { $0.id == event.phraseTemplateId }
            ?? PhraseTemplateStore.defaultTemplate(for: event.countType)

        let store = PhraseTemplateStore()
        let generated = store.generateText(
            template: template,
            label: event.name,
            count: dayCount,
            layoutMode: event.layoutMode
        )

        if event.layoutMode == .single {
            return generated.singleLine
        } else {
            return generated.line1
        }
    }

    private func resolvedOverlaySecondLine() -> String? {
        guard event.layoutMode == .double else { return nil }

        if event.customPhraseMode {
            return event.customLine2
        }

        let template = PhraseTemplateStore.allTemplates.first { $0.id == event.phraseTemplateId }
            ?? PhraseTemplateStore.defaultTemplate(for: event.countType)

        let store = PhraseTemplateStore()
        let generated = store.generateText(
            template: template,
            label: event.name,
            count: dayCount,
            layoutMode: event.layoutMode
        )

        return generated.line2.isEmpty ? nil : generated.line2
    }

    private func overlayFont() -> Font {
        let scale = designTemplate.fontSizeScale
        let baseSize: CGFloat = 16 * scale
        return Font.system(size: baseSize, weight: uiFontWeight(designTemplate.fontWeight), design: .rounded)
    }

    private func overlayFontEmphasised() -> Font {
        let scale = designTemplate.fontSizeScale
        let baseSize: CGFloat = 24 * scale
        return Font.system(size: baseSize, weight: .bold, design: .rounded)
    }

    private func uiFontWeight(_ weight: DesignTemplate.FontWeight) -> Font.Weight {
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

    private func swiftUIAlignment(from alignment: TextAlignment) -> Alignment {
        switch alignment {
        case .left:   return .leading
        case .center: return .center
        case .right:  return .trailing
        }
    }

    private func textAlignment(from alignment: TextAlignment) -> SwiftUI.TextAlignment {
        switch alignment {
        case .left:   return .leading
        case .center: return .center
        case .right:  return .trailing
        }
    }

    // MARK: - Safe Area

    private var safeAreaTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first?
            .safeAreaInsets
            .top ?? 0
    }

    private var safeAreaBottom: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first?
            .safeAreaInsets
            .bottom ?? 0
    }
}
