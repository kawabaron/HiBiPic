import SwiftUI
import Photos

// MARK: - ImageDetailView

/// Full-screen gallery viewer with paging, zoom, and a compact top-right action menu.
struct ImageDetailView: View {

    let onDelete: (SavedImage) -> Void
    let onPrepareReedit: (SavedImage) -> SavedImageEditorPreparationResult

    @Environment(\.dismiss) private var dismiss

    @State private var galleryImages: [SavedImage]
    @State private var currentImageID: String
    @State private var uiImage: UIImage?
    @State private var showDeleteConfirm = false
    @State private var showShareSheet = false
    @State private var savedToPhotos = false
    @State private var savingToPhotos = false
    @State private var dismissDragOffset: CGFloat = 0
    @State private var reeditViewModel: EditorViewModel?
    @State private var reeditErrorMessage: String?

    init(
        images: [SavedImage],
        initialImageID: String,
        onPrepareReedit: @escaping (SavedImage) -> SavedImageEditorPreparationResult,
        onDelete: @escaping (SavedImage) -> Void
    ) {
        self.onDelete = onDelete
        self.onPrepareReedit = onPrepareReedit
        _galleryImages = State(initialValue: images)
        _currentImageID = State(initialValue: initialImageID)
    }

    var body: some View {
        ZStack {
            DSColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                imageContent
            }
            .offset(y: dismissDragOffset)
        }
        .task {
            refreshCurrentImageState()
        }
        .alert(L10n.t("この画像を削除しますか？"), isPresented: $showDeleteConfirm) {
            Button(L10n.t("削除"), role: .destructive) {
                deleteCurrentImage()
            }
            Button(L10n.t("キャンセル"), role: .cancel) {}
        } message: {
            Text(L10n.t("この操作は取り消せません"))
        }
        .alert(
            L10n.t("再編集できません"),
            isPresented: Binding(
                get: { reeditErrorMessage != nil },
                set: { if !$0 { reeditErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            if let reeditErrorMessage {
                Text(reeditErrorMessage)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let uiImage {
                ShareSheetView(image: uiImage)
            }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { reeditViewModel != nil },
                set: { if !$0 { reeditViewModel = nil } }
            ),
            onDismiss: {
                NotificationCenter.default.post(name: .libraryDidChange, object: nil)
            }
        ) {
            if let reeditViewModel {
                EditorScreen(viewModel: reeditViewModel)
            }
        }
        .onChange(of: currentImageID) { _, _ in
            refreshCurrentImageState()
        }
        .simultaneousGesture(dismissGesture)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DSColors.textPrimary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            if !galleryImages.isEmpty {
                Text("\(currentIndex + 1) / \(galleryImages.count)")
                    .font(DSTypography.callout)
                    .foregroundStyle(DSColors.textSecondary)
            }

            Spacer()

            Menu {
                Button {
                    startReedit()
                } label: {
                    Label(reeditButtonTitle, systemImage: "slider.horizontal.3")
                }
                .disabled(currentImage == nil)

                Divider()

                Button {
                    saveToPhotos()
                } label: {
                    Label(
                        savedToPhotos ? L10n.t("保存しました") : L10n.t("iPhoneの写真に保存"),
                        systemImage: savedToPhotos ? "checkmark" : "square.and.arrow.down"
                    )
                }
                .disabled(uiImage == nil || savedToPhotos || savingToPhotos)

                Button {
                    showShareSheet = true
                } label: {
                    Label(L10n.t("共有する"), systemImage: "square.and.arrow.up")
                }
                .disabled(uiImage == nil)

                Divider()

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label(L10n.t("削除"), systemImage: "trash")
                }
                .disabled(currentImage == nil)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(DSColors.textPrimary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, DSSpacing.sm)
        .padding(.top, DSSpacing.xs)
    }

    // MARK: - Image Content

    private var imageContent: some View {
        Group {
            if galleryImages.isEmpty {
                Rectangle()
                    .fill(DSColors.secondaryBackground)
                    .overlay {
                        Text(L10n.t("画像がありません"))
                            .font(DSTypography.body)
                            .foregroundStyle(DSColors.textSecondary)
                    }
            } else {
                TabView(selection: $currentImageID) {
                    ForEach(galleryImages) { image in
                        ZoomableLibraryImageView(image: image)
                            .tag(image.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Derived State

    private var currentImage: SavedImage? {
        galleryImages.first { $0.id == currentImageID } ?? galleryImages.first
    }

    private var currentIndex: Int {
        galleryImages.firstIndex { $0.id == currentImageID } ?? 0
    }

    private var reeditButtonTitle: String {
        currentImage?.supportsFullReedit == true ? L10n.t("再編集") : L10n.t("再編集（簡易）")
    }

    // MARK: - State Sync

    private func refreshCurrentImageState() {
        if !galleryImages.contains(where: { $0.id == currentImageID }),
           let firstImage = galleryImages.first {
            currentImageID = firstImage.id
            return
        }

        guard let currentImage else {
            uiImage = nil
            savedToPhotos = false
            savingToPhotos = false
            return
        }

        uiImage = ImageFileStorage.shared.loadImage(fileName: currentImage.fileName)
        savedToPhotos = false
        savingToPhotos = false
    }

    private func startReedit() {
        guard let currentImage else { return }

        switch onPrepareReedit(currentImage) {
        case .ready(let viewModel):
            reeditViewModel = viewModel
        case .failed(let message):
            reeditErrorMessage = message
        }
    }

    private func deleteCurrentImage() {
        guard let currentImage else { return }

        let currentIndex = currentIndex
        onDelete(currentImage)

        galleryImages.removeAll { $0.id == currentImage.id }

        guard !galleryImages.isEmpty else {
            dismiss()
            return
        }

        let nextIndex = min(currentIndex, galleryImages.count - 1)
        currentImageID = galleryImages[nextIndex].id
    }

    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 16)
            .onChanged { value in
                guard value.translation.height > 0,
                      abs(value.translation.height) > abs(value.translation.width)
                else { return }

                dismissDragOffset = value.translation.height
            }
            .onEnded { value in
                let shouldDismiss = value.translation.height > 120
                    && abs(value.translation.height) > abs(value.translation.width)

                if shouldDismiss {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        dismissDragOffset = 0
                    }
                }
            }
    }

    // MARK: - Save to Photos

    private func saveToPhotos() {
        guard let uiImage else { return }
        savingToPhotos = true

        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized || status == .limited else {
                savingToPhotos = false
                return
            }

            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetChangeRequest.creationRequestForAsset(from: uiImage)
                    request.creationDate = Date()
                } completionHandler: { success, _ in
                    DispatchQueue.main.async {
                        savingToPhotos = false
                        if success {
                            savedToPhotos = true
                        }
                        continuation.resume()
                    }
                }
            }
        }
    }
}

// MARK: - ZoomableLibraryImageView

private struct ZoomableLibraryImageView: View {

    let image: SavedImage

    @State private var uiImage: UIImage?
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geo in
            Group {
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(zoomScale)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .contentShape(Rectangle())
                        .gesture(doubleTapGesture)
                        .simultaneousGesture(magnificationGesture)
                } else {
                    Rectangle()
                        .fill(DSColors.secondaryBackground)
                        .overlay {
                            ProgressView()
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous))
            .padding(.horizontal, DSSpacing.lg)
            .padding(.vertical, DSSpacing.md)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            if uiImage == nil {
                uiImage = ImageFileStorage.shared.loadImage(fileName: image.fileName)
            }
        }
        .onChange(of: image.id) { _, _ in
            zoomScale = 1.0
            lastZoomScale = 1.0
            uiImage = ImageFileStorage.shared.loadImage(fileName: image.fileName)
        }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                zoomScale = min(max(lastZoomScale * value, 1.0), 4.0)
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                    zoomScale = min(max(zoomScale, 1.0), 4.0)
                    lastZoomScale = zoomScale
                }
            }
    }

    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                    zoomScale = zoomScale > 1.0 ? 1.0 : 2.5
                    lastZoomScale = zoomScale
                }
            }
    }
}
