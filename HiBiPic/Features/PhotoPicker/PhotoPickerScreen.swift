import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

// MARK: - PhotoPickerScreen

/// Wraps the native photo picker so the first presentation is reliable and
/// returns the chosen image directly to the editor flow.
struct PhotoPickerScreen: UIViewControllerRepresentable {

    @Binding var isPresented: Bool
    var onImageSelected: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        picker.view.backgroundColor = .black
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    // MARK: - Coordinator

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: PhotoPickerScreen

        init(_ parent: PhotoPickerScreen) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider else {
                DispatchQueue.main.async {
                    self.parent.isPresented = false
                }
                return
            }

            loadPickedImage(from: provider)
        }

        private func loadPickedImage(from provider: NSItemProvider) {
            if let imageTypeIdentifier = provider.registeredTypeIdentifiers.first(where: {
                UTType($0)?.conforms(to: .image) == true
            }) {
                provider.loadDataRepresentation(forTypeIdentifier: imageTypeIdentifier) { data, _ in
                    if let data,
                       let image = UIImage(data: data)
                    {
                        DispatchQueue.main.async {
                            self.finishPicking(with: image)
                        }
                        return
                    }

                    self.loadUIImageObject(from: provider)
                }
                return
            }

            loadUIImageObject(from: provider)
        }

        private func loadUIImageObject(from provider: NSItemProvider) {
            guard provider.canLoadObject(ofClass: UIImage.self) else {
                DispatchQueue.main.async {
                    self.parent.isPresented = false
                }
                return
            }

            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    guard let image = image as? UIImage else {
                        self.parent.isPresented = false
                        return
                    }

                    self.finishPicking(with: image)
                }
            }
        }

        private func finishPicking(with image: UIImage) {
            parent.onImageSelected(image)
            parent.isPresented = false
        }
    }
}
