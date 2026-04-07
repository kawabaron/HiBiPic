import AVFoundation
import SwiftUI
import UIKit

// MARK: - CameraPreviewView

/// A UIViewRepresentable that displays the live camera feed using `AVCaptureVideoPreviewLayer`.
struct CameraPreviewView: UIViewRepresentable {

    let session: AVCaptureSession

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.previewLayer.session = session
    }
}

// MARK: - CameraPreviewUIView

/// A plain `UIView` whose `layerClass` is `AVCaptureVideoPreviewLayer` so the
/// preview automatically fills the view's bounds without manual layout.
final class CameraPreviewUIView: UIView {

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        // swiftlint:disable:next force_cast
        layer as! AVCaptureVideoPreviewLayer
    }
}
