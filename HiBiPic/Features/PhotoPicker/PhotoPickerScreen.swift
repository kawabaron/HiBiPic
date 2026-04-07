import PhotosUI
import SwiftUI

// MARK: - PhotoPickerScreen

/// A lightweight wrapper around the native `PhotosPicker` that loads the
/// selected image and forwards it to the caller.
struct PhotoPickerScreen: View {

    // MARK: - Properties

    let event: Event
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    var onImageSelected: (UIImage) -> Void

    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoading = false

    // MARK: - Body

    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            pickerLabel
        }
        .photosPickerStyle(.inline)
        .photosPickerDisabledCapabilities(.selectionActions)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .overlay(alignment: .top) {
            headerBar
        }
        .overlay {
            if isLoading {
                loadingOverlay
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            loadImage(from: newItem)
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }

            Spacer()

            Text(event.name)
                .font(DSTypography.headline)
                .foregroundStyle(.white)

            Spacer()

            // Invisible spacer to balance the close button
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, DSSpacing.lg)
        .padding(.top, DSSpacing.sm)
        .padding(.bottom, DSSpacing.sm)
        .background(
            LinearGradient(
                colors: [.black.opacity(0.6), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Picker Label

    private var pickerLabel: some View {
        VStack(spacing: DSSpacing.md) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.7))

            Text("写真を選択")
                .font(DSTypography.headline)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        Color.black.opacity(0.5)
            .ignoresSafeArea()
            .overlay {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
            }
    }

    // MARK: - Image Loading

    private func loadImage(from item: PhotosPickerItem) {
        isLoading = true

        Task {
            defer { isLoading = false }

            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data)
            else {
                return
            }

            selectedImage = image
            onImageSelected(image)
            isPresented = false
        }
    }
}
