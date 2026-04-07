import SwiftUI
import UIKit

// MARK: - ShareSheetView

/// Wraps `UIActivityViewController` for sharing images from SwiftUI.
struct ShareSheetView: UIViewControllerRepresentable {

    // MARK: - Properties

    /// The image to share.
    let image: UIImage

    /// Optional completion callback.
    var onComplete: ((Bool) -> Void)?

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityItems: [Any] = [image]

        let activityVC = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )

        // Exclude activities that don't make sense for photos
        activityVC.excludedActivityTypes = [
            .addToReadingList,
            .openInIBooks
        ]

        activityVC.completionWithItemsHandler = { _, completed, _, _ in
            onComplete?(completed)
        }

        return activityVC
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview

#Preview {
    let size = CGSize(width: 200, height: 200)
    let renderer = UIGraphicsImageRenderer(size: size)
    let sampleImage = renderer.image { ctx in
        UIColor.systemBlue.setFill()
        ctx.fill(CGRect(origin: .zero, size: size))
    }

    ShareSheetView(image: sampleImage)
}
