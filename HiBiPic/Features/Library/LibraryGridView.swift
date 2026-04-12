import SwiftUI

// MARK: - LibraryGridView

/// Displays saved images in a 3-column grid of thumbnails.
struct LibraryGridView: View {

    let images: [SavedImage]
    var onImageTapped: (SavedImage) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        if images.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(images) { image in
                        thumbnailCell(image)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    // MARK: - Thumbnail Cell

    private func thumbnailCell(_ image: SavedImage) -> some View {
        Button {
            onImageTapped(image)
        } label: {
            GeometryReader { geo in
                if let thumb = ImageFileStorage.shared.loadThumbnail(fileName: image.fileName) {
                    Image(uiImage: thumb)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.width)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(DSColors.secondaryBackground)
                        .frame(width: geo.size.width, height: geo.size.width)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(DSColors.textTertiary)
                        }
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DSSpacing.xxl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(DSColors.accentLight.opacity(0.25))
                    .frame(width: 100, height: 100)

                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(DSColors.accent)
            }

            VStack(spacing: DSSpacing.sm) {
                Text(L10n.t("まだ画像がありません"))
                    .font(DSTypography.title)
                    .foregroundStyle(DSColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(L10n.t("写真を撮って日数を印字しましょう"))
                    .font(DSTypography.subheadline)
                    .foregroundStyle(DSColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, DSSpacing.xxxl)
    }
}
