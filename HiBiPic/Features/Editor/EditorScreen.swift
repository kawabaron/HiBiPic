import SwiftUI
import UIKit

// MARK: - EditorScreen

/// The main photo editor screen where users adjust the text overlay
/// (position, template, size, colour) before saving.
struct EditorScreen: View {

    // MARK: - Properties

    @State private var viewModel: EditorViewModel

    /// Dismiss action for the close button.
    @Environment(\.dismiss) private var dismiss

    init(viewModel: EditorViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        ZStack {
            editorBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                photoArea
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                bottomControls
            }
        }
        .overlay {
            ZStack {
                if viewModel.isSaving {
                    savingOverlay
                }

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
        }
        .sheet(isPresented: $bindableViewModel.showShareSheet) {
            ShareSheetView(image: viewModel.shareImage())
        }
        .alert(
            L10n.t("エラー"),
            isPresented: Binding(
                get: { viewModel.saveErrorMessage != nil },
                set: { if !$0 { viewModel.saveErrorMessage = nil } }
            )
        ) {
            Button(L10n.t("OK"), role: .cancel) {}
        } message: {
            if let msg = viewModel.saveErrorMessage {
                Text(msg)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Close button
            Button {
                dismiss()
            } label: {
                Text(L10n.t("キャンセル"))
                    .font(.system(size: 17))
                    .foregroundStyle(DSColors.accent)
                    .frame(minWidth: 44, alignment: .leading)
            }
            .buttonStyle(.plain)

            Spacer()

            // Save button
            Button {
                Task {
                    await viewModel.save()
                }
            } label: {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(DSColors.accent)
                        .controlSize(.small)
                        .frame(minWidth: 44, alignment: .trailing)
                } else {
                    Text(L10n.t("保存"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(DSColors.accent)
                        .frame(minWidth: 44, alignment: .trailing)
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSaving)
        }
        .padding(.horizontal, DSSpacing.lg)
        .frame(height: 48)
        .background(editorChromeFill)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DSColors.divider)
                .frame(height: 1)
        }
    }

    // MARK: - Photo Area

    private var photoArea: some View {
        GeometryReader { geo in
            let previewLayout = EditorImageGeometry(image: viewModel.image)
                .previewLayout(in: geo.size)

            ZStack {
                // Photo
                Image(uiImage: viewModel.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: previewLayout.displaySize.width, height: previewLayout.displaySize.height)
                    .clipped()

                // Draggable text overlay
                textOverlay(imageSize: previewLayout.displaySize)
                    .position(
                        x: viewModel.textPosition.x * previewLayout.displaySize.width,
                        y: viewModel.textPosition.y * previewLayout.displaySize.height
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newX = value.location.x / previewLayout.displaySize.width
                                let newY = value.location.y / previewLayout.displaySize.height
                                viewModel.updateTextPositionManually(
                                    CGPoint(
                                        x: clamp(newX, min: 0.05, max: 0.95),
                                        y: clamp(newY, min: 0.05, max: 0.95)
                                    )
                                )
                            }
                    )
            }
            .frame(width: previewLayout.displaySize.width, height: previewLayout.displaySize.height)
            .position(x: previewLayout.displayRect.midX, y: previewLayout.displayRect.midY)
        }
        .background(editorBackground)
        .contentShape(Rectangle())
    }

    // MARK: - Text Overlay

    private func textOverlay(imageSize: CGSize) -> some View {
        let text = viewModel.displayText

        return TextOverlayView(
            designTemplate: viewModel.currentDesignTemplate,
            fontPreset: viewModel.fontPreset,
            layoutMode: viewModel.layoutMode,
            displayText: text,
            canvasSize: imageSize,
            scale: viewModel.textScale,
            textAlignment: viewModel.effectiveTextAlignment,
            colorOverride: viewModel.textColorOverride,
            showBackground: viewModel.showBackgroundBand,
            backgroundColorHex: viewModel.effectiveBackgroundBandColorHex
        )
    }

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()

            VStack(spacing: DSSpacing.md) {
                ProgressView()
                    .controlSize(.large)
                    .tint(DSColors.accent)

                Text(L10n.t("保存中..."))
                    .font(DSTypography.headline)
                    .foregroundStyle(DSColors.textPrimary)

                Text(L10n.t("画像を書き出しています"))
                    .font(DSTypography.caption)
                    .foregroundStyle(DSColors.textSecondary)
            }
            .padding(.horizontal, DSSpacing.xxl)
            .padding(.vertical, DSSpacing.xl)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerLg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DSSpacing.cornerLg, style: .continuous)
                    .strokeBorder(DSColors.border, lineWidth: 1)
            }
            .dsShadow(.card)
        }
        .transition(.opacity)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: DSSpacing.sm) {
            EditorToolPanel(viewModel: viewModel)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.activeEditTool)

            bottomToolbar
        }
        .padding(.horizontal, DSSpacing.sm)
        .padding(.top, DSSpacing.sm)
        .padding(.bottom, DSSpacing.sm)
        .background(editorChromeFill)
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack(spacing: 0) {
            ForEach(toolbarTools) { tool in
                toolButton(tool)
            }
        }
        .frame(height: 52)
        .padding(.horizontal, DSSpacing.xs)
        .padding(.vertical, DSSpacing.sm)
        .background(DSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerLg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DSSpacing.cornerLg, style: .continuous)
                .strokeBorder(DSColors.border, lineWidth: 1)
        }
        .dsShadow(.soft)
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
                    .foregroundStyle(isActive ? DSColors.accent : DSColors.textSecondary)

                Text(tool.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isActive ? DSColors.accent : DSColors.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous)
                    .fill(isActive ? DSColors.accentLight.opacity(0.22) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var toolbarTools: [EditorViewModel.EditTool] {
        [.template, .font, .phrase, .position, .textSize, .textColor, .background]
    }

    private func clamp(_ value: CGFloat, min minVal: CGFloat, max maxVal: CGFloat) -> CGFloat {
        Swift.min(maxVal, Swift.max(minVal, value))
    }

    private var editorChromeFill: Color {
        DSColors.background
    }

    private var editorBackground: LinearGradient {
        LinearGradient(
            colors: [DSColors.background, DSColors.secondaryBackground],
            startPoint: .top,
            endPoint: .bottom
        )
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
