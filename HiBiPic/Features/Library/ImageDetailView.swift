import SwiftUI
import Photos

// MARK: - ImageDetailView

/// Full-screen image viewer with save-to-photos, share, and delete actions.
struct ImageDetailView: View {

    let image: SavedImage
    var onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var uiImage: UIImage?
    @State private var showDeleteConfirm = false
    @State private var showShareSheet = false
    @State private var savedToPhotos = false
    @State private var savingToPhotos = false

    var body: some View {
        ZStack {
            DSColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                imageContent
                actionButtons
            }
        }
        .onAppear {
            uiImage = ImageFileStorage.shared.loadImage(fileName: image.fileName)
        }
        .alert("この画像を削除しますか？", isPresented: $showDeleteConfirm) {
            Button("削除", role: .destructive) {
                onDelete()
                dismiss()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この操作は取り消せません")
        }
        .sheet(isPresented: $showShareSheet) {
            if let uiImage {
                ShareSheetView(image: uiImage)
            }
        }
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

            Button {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DSColors.error)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, DSSpacing.sm)
    }

    // MARK: - Image Content

    private var imageContent: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous))
                    .padding(.horizontal, DSSpacing.lg)
            } else {
                Rectangle()
                    .fill(DSColors.secondaryBackground)
                    .aspectRatio(3 / 4, contentMode: .fit)
                    .overlay {
                        ProgressView()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous))
                    .padding(.horizontal, DSSpacing.lg)
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: DSSpacing.md) {
            DSButton(
                savedToPhotos ? "保存しました" : "iPhoneの写真に保存",
                style: .primary,
                icon: Image(systemName: savedToPhotos ? "checkmark" : "square.and.arrow.down")
            ) {
                saveToPhotos()
            }
            .disabled(savedToPhotos || savingToPhotos)

            DSButton(
                "共有する",
                style: .secondary,
                icon: Image(systemName: "square.and.arrow.up")
            ) {
                showShareSheet = true
            }
        }
        .padding(.horizontal, DSSpacing.xl)
        .padding(.vertical, DSSpacing.lg)
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

