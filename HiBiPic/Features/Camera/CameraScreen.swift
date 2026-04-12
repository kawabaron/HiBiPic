import SwiftUI

// MARK: - CameraScreen

/// Full-screen camera view with a live preview and minimal chrome.
/// Captured photos continue into the editor for text styling there.
struct CameraScreen: View {

    // MARK: - Properties

    let event: Event
    let onImageCaptured: (UIImage) -> Void
    let onPickerRequested: () -> Void
    let onDismiss: () -> Void

    @State private var viewModel = CameraViewModel()
    @State private var shutterPressed = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Camera preview -- full screen
            cameraPreview

            closeButton
                .padding(.top, safeAreaTop + DSSpacing.sm)
                .padding(.leading, DSSpacing.lg)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            bottomBar
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
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

                    if viewModel.cameraAccessDenied {
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text(L10n.t("設定を開く"))
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
            viewModel.cameraAccessDenied = true
            viewModel.cameraError = L10n.t("カメラへのアクセスが許可されていません。設定からカメラへのアクセスを許可してください。")
            return
        }

        viewModel.cameraAccessDenied = false

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
