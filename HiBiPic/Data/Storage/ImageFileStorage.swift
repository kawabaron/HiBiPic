import UIKit

/// Manages reading and writing image files to the app's local storage.
///
/// Full-resolution images are stored in `Documents/HiBiPicLibrary/`,
/// and thumbnails in `Documents/HiBiPicLibrary/thumbnails/`.
final class ImageFileStorage {

    // MARK: - Singleton

    static let shared = ImageFileStorage()

    // MARK: - Directories

    private let libraryDir: URL
    private let thumbnailDir: URL

    private init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        libraryDir = documents.appendingPathComponent("HiBiPicLibrary", isDirectory: true)
        thumbnailDir = libraryDir.appendingPathComponent("thumbnails", isDirectory: true)
        ensureDirectoriesExist()
    }

    // MARK: - Save

    /// Saves a full-resolution image as JPEG.
    /// - Returns: `true` if the write succeeded.
    @discardableResult
    func saveImage(_ image: UIImage, fileName: String) -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return false }
        let url = libraryDir.appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    /// Generates and saves a thumbnail for the given image.
    /// - Returns: `true` if the write succeeded.
    @discardableResult
    func saveThumbnail(_ image: UIImage, fileName: String) -> Bool {
        let thumb = generateThumbnail(from: image)
        guard let data = thumb.jpegData(compressionQuality: 0.7) else { return false }
        let url = thumbnailDir.appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Load

    func loadImage(fileName: String) -> UIImage? {
        let url = libraryDir.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func loadThumbnail(fileName: String) -> UIImage? {
        let url = thumbnailDir.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Delete

    func deleteImage(fileName: String) {
        let fullURL = libraryDir.appendingPathComponent(fileName)
        let thumbURL = thumbnailDir.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fullURL)
        try? FileManager.default.removeItem(at: thumbURL)
    }

    // MARK: - Thumbnail Generation

    func generateThumbnail(from image: UIImage, maxSize: CGFloat = 300) -> UIImage {
        let size = image.size
        let scale: CGFloat
        if size.width > size.height {
            scale = maxSize / size.width
        } else {
            scale = maxSize / size.height
        }

        if scale >= 1.0 { return image }

        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Private

    private func ensureDirectoriesExist() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: libraryDir.path) {
            try? fm.createDirectory(at: libraryDir, withIntermediateDirectories: true)
        }
        if !fm.fileExists(atPath: thumbnailDir.path) {
            try? fm.createDirectory(at: thumbnailDir, withIntermediateDirectories: true)
        }
    }
}
