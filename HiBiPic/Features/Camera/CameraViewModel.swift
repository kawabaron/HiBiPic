import AVFoundation
import UIKit

// MARK: - CameraViewModel

@Observable
final class CameraViewModel: NSObject {

    // MARK: - Published State

    var capturedImage: UIImage?
    var isCapturing = false
    var isCameraReady = false
    var cameraError: String?
    var currentEvent: Event?

    // MARK: - Session

    let session = AVCaptureSession()

    // MARK: - Private

    private let photoOutput = AVCapturePhotoOutput()
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    private var photoContinuation: CheckedContinuation<UIImage?, Never>?

    // MARK: - Permission

    /// Checks and requests camera authorization. Returns `true` if granted.
    func requestCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Setup

    /// Configures the capture session with the specified camera position.
    /// Call from a background task -- session configuration blocks the calling thread.
    func setupCamera() {
        guard !isCameraReady else { return }

        session.beginConfiguration()
        session.sessionPreset = .photo

        // Remove existing inputs
        for input in session.inputs {
            session.removeInput(input)
        }

        // Discover the camera device
        guard let device = cameraDevice(for: currentCameraPosition) else {
            session.commitConfiguration()
            cameraError = "カメラデバイスが見つかりません"
            return
        }

        // Create and add input
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                session.commitConfiguration()
                cameraError = "カメラ入力を追加できません"
                return
            }
        } catch {
            session.commitConfiguration()
            cameraError = "カメラの初期化に失敗しました: \(error.localizedDescription)"
            return
        }

        // Add photo output (only once)
        if session.outputs.isEmpty {
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
                photoOutput.isHighResolutionCaptureEnabled = true
                photoOutput.maxPhotoQualityPrioritization = .quality
            } else {
                session.commitConfiguration()
                cameraError = "写真出力を追加できません"
                return
            }
        }

        session.commitConfiguration()
        session.startRunning()

        isCameraReady = true
        cameraError = nil
    }

    // MARK: - Capture

    /// Captures a high-quality photo and delivers the result as a `UIImage`.
    func capturePhoto() async -> UIImage? {
        guard isCameraReady, !isCapturing else { return nil }

        isCapturing = true

        let settings = AVCapturePhotoSettings()
        settings.photoQualityPrioritization = .quality

        // Use the HEVC codec when available for better quality at smaller size
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            let hevcSettings = AVCapturePhotoSettings(
                format: [AVVideoCodecKey: AVVideoCodecType.hevc]
            )
            hevcSettings.photoQualityPrioritization = .quality
            return await withCheckedContinuation { continuation in
                self.photoContinuation = continuation
                self.photoOutput.capturePhoto(with: hevcSettings, delegate: self)
            }
        }

        return await withCheckedContinuation { continuation in
            self.photoContinuation = continuation
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    // MARK: - Camera Switching

    /// Toggles between the front and back cameras.
    func switchCamera() {
        currentCameraPosition = (currentCameraPosition == .back) ? .front : .back

        session.beginConfiguration()

        // Remove existing inputs
        for input in session.inputs {
            session.removeInput(input)
        }

        guard let device = cameraDevice(for: currentCameraPosition) else {
            session.commitConfiguration()
            cameraError = "カメラの切り替えに失敗しました"
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            cameraError = "カメラの切り替えに失敗しました: \(error.localizedDescription)"
        }

        session.commitConfiguration()
    }

    // MARK: - Cleanup

    /// Stops the capture session and releases resources.
    func cleanup() {
        if session.isRunning {
            session.stopRunning()
        }
        isCameraReady = false
    }

    // MARK: - Private Helpers

    private func cameraDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        // Prefer a triple/dual camera on the back, wide-angle as fallback
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInTripleCamera,
                .builtInDualWideCamera,
                .builtInDualCamera,
                .builtInWideAngleCamera,
            ],
            mediaType: .video,
            position: position
        )
        return discoverySession.devices.first
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewModel: AVCapturePhotoCaptureDelegate {

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        defer {
            isCapturing = false
        }

        if let error {
            cameraError = "写真の撮影に失敗しました: \(error.localizedDescription)"
            photoContinuation?.resume(returning: nil)
            photoContinuation = nil
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data)
        else {
            cameraError = "写真データの変換に失敗しました"
            photoContinuation?.resume(returning: nil)
            photoContinuation = nil
            return
        }

        // Mirror the image when taken with the front camera so it matches the preview
        let finalImage: UIImage
        if currentCameraPosition == .front,
           let cgImage = image.cgImage
        {
            finalImage = UIImage(
                cgImage: cgImage,
                scale: image.scale,
                orientation: .leftMirrored
            )
        } else {
            finalImage = image
        }

        capturedImage = finalImage
        photoContinuation?.resume(returning: finalImage)
        photoContinuation = nil
    }
}
