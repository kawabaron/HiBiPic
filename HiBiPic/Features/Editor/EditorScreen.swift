import SwiftUI

// MARK: - EditorScreen

/// The main photo editor screen where users adjust the text overlay
/// (position, template, size, colour) before saving.
struct EditorScreen: View {

    // MARK: - Properties

    @Bindable var viewModel: EditorViewModel

    /// Dismiss action for the close button.
    @Environment(\.dismiss) private var dismiss

    /// Tracks the photo area size for normalising drag coordinates.
    @State private var photoAreaSize: CGSize = .zero

    /// Accumulated drag offset for smoother gesture handling.
    @State private var dragOffset: CGSize = .zero

    // MARK: - Body

    var body: some View {
        ZStack {
            // Full-screen dark background
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top navigation bar
                topBar

                // Photo area with text overlay
                photoArea
                    .layoutPriority(1)

                // Bottom toolbar
                bottomToolbar

                // Expandable tool panel
                EditorToolPanel(viewModel: viewModel)
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.activeEditTool)
            }
        }
        .overlay {
            if viewModel.showSaveSuccess {
                SaveSuccessView(
                    onSaveToPhotos: {
                        Task {
                            await viewModel.saveRenderedToPhotoLibrary()
                        }
                    },
                    onShare: {
                        viewModel.showSaveSuccess = false
                        viewModel.showShareSheet = true
                    },
                    onBackToLibrary: {
                        viewModel.showSaveSuccess = false
                        dismiss()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .animation(.easeOut(duration: 0.3), value: viewModel.showSaveSuccess)
            }
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            ShareSheetView(image: viewModel.shareImage())
        }
        .alert(
            "エラー",
            isPresented: Binding(
                get: { viewModel.saveErrorMessage != nil },
                set: { if !$0 { viewModel.saveErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            if let msg = viewModel.saveErrorMessage {
                Text(msg)
            }
        }
        .statusBarHidden()
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Close button
            Button {
                dismiss()
            } label: {
                Text("閉じる")
                    .font(DSTypography.callout)
                    .foregroundStyle(.white)
            }

            Spacer()

            // Event name
            Text(viewModel.event.name)
                .font(DSTypography.headline)
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            // Save button
            Button {
                Task {
                    await viewModel.save()
                }
            } label: {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(.white)
                        .controlSize(.small)
                        .frame(width: 60)
                } else {
                    Text("保存")
                        .font(DSTypography.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, DSSpacing.md)
                        .padding(.vertical, DSSpacing.xs)
                        .background(
                            Capsule()
                                .fill(DSColors.accent)
                        )
                }
            }
            .disabled(viewModel.isSaving)
        }
        .padding(.horizontal, DSSpacing.lg)
        .padding(.vertical, DSSpacing.md)
        .background(
            Color.black.opacity(0.3)
                .background(.ultraThinMaterial.opacity(0.5))
        )
    }

    // MARK: - Photo Area

    private var photoArea: some View {
        GeometryReader { geo in
            let imageAspect = viewModel.image.size.width / max(viewModel.image.size.height, 1)
            let areaAspect = geo.size.width / max(geo.size.height, 1)

            let displaySize: CGSize = {
                if imageAspect > areaAspect {
                    // Image is wider - fit to width
                    let w = geo.size.width
                    let h = w / imageAspect
                    return CGSize(width: w, height: h)
                } else {
                    // Image is taller - fit to height
                    let h = geo.size.height
                    let w = h * imageAspect
                    return CGSize(width: w, height: h)
                }
            }()

            let imageOrigin = CGPoint(
                x: (geo.size.width - displaySize.width) / 2,
                y: (geo.size.height - displaySize.height) / 2
            )

            ZStack {
                // Photo
                Image(uiImage: viewModel.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: displaySize.width, height: displaySize.height)
                    .clipped()

                // Draggable text overlay
                textOverlay(imageSize: displaySize)
                    .position(
                        x: viewModel.textPosition.x * displaySize.width,
                        y: viewModel.textPosition.y * displaySize.height
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newX = value.location.x / displaySize.width
                                let newY = value.location.y / displaySize.height
                                viewModel.textPosition = CGPoint(
                                    x: clamp(newX, min: 0.05, max: 0.95),
                                    y: clamp(newY, min: 0.05, max: 0.95)
                                )
                            }
                    )
            }
            .frame(width: displaySize.width, height: displaySize.height)
            .position(
                x: imageOrigin.x + displaySize.width / 2,
                y: imageOrigin.y + displaySize.height / 2
            )
            .onAppear {
                photoAreaSize = displaySize
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Dismiss tool panel when tapping the photo area
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.activeEditTool = .none
            }
        }
    }

    // MARK: - Text Overlay

    private func textOverlay(imageSize: CGSize) -> some View {
        let text = viewModel.displayText

        return TextOverlayView(
            designTemplate: viewModel.currentDesignTemplate,
            layoutMode: viewModel.layoutMode,
            line1: text.line1,
            line2: text.line2,
            singleLine: text.singleLine,
            scale: viewModel.textScale,
            colorOverride: viewModel.textColorOverride,
            showBackground: viewModel.showBackgroundBand
        )
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack(spacing: 0) {
            ForEach(EditorViewModel.EditTool.allCases.filter { $0 != .none }) { tool in
                toolButton(tool)
            }
        }
        .padding(.horizontal, DSSpacing.sm)
        .padding(.vertical, DSSpacing.sm)
        .background(
            Color.black.opacity(0.3)
                .background(.ultraThinMaterial.opacity(0.5))
        )
    }

    private func toolButton(_ tool: EditorViewModel.EditTool) -> some View {
        let isActive = viewModel.activeEditTool == tool

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectTool(tool)
            }
        } label: {
            VStack(spacing: DSSpacing.xxs) {
                Image(systemName: tool.systemImage)
                    .font(.system(size: 20))
                    .foregroundStyle(isActive ? DSColors.accent : Color.white.opacity(0.7))

                Text(tool.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isActive ? DSColors.accent : Color.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func clamp(_ value: CGFloat, min minVal: CGFloat, max maxVal: CGFloat) -> CGFloat {
        Swift.min(maxVal, Swift.max(minVal, value))
    }
}

// MARK: - Preview

#Preview {
    // Create a sample 1:1 magenta image for previewing
    let size = CGSize(width: 400, height: 600)
    let renderer = UIGraphicsImageRenderer(size: size)
    let sampleImage = renderer.image { ctx in
        UIColor.darkGray.setFill()
        ctx.fill(CGRect(origin: .zero, size: size))
    }

    EditorScreen(
        viewModel: EditorViewModel(
            image: sampleImage,
            event: Event(
                name: "誕生日",
                baseDate: "2025-12-25",
                countType: .countdown,
                phraseTemplateId: "countdown_single_1"
            )
        )
    )
}
