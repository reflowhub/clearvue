import AVFoundation
import Combine
import UIKit

class CameraService: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    @Published var isRunning = false
    @Published var error: String?
    @Published var cameraValid: Bool?

    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private let outputQueue = DispatchQueue(label: "clearvue.camera.output")
    private var analyzeTimer: Timer?
    private var latestBuffer: CMSampleBuffer?
    private var photoContinuation: CheckedContinuation<Data?, Never>?

    func start(position: AVCaptureDevice.Position) {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self else { return }
            DispatchQueue.main.async {
                if granted {
                    self.configureSession(position: position)
                } else {
                    self.error = "Camera access denied"
                }
            }
        }
    }

    private func configureSession(position: AVCaptureDevice.Position) {
        session.beginConfiguration()
        session.sessionPreset = .high

        // Remove existing inputs/outputs
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device) else {
            error = "Camera not available"
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        videoOutput.setSampleBufferDelegate(self, queue: outputQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        session.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async {
                self?.isRunning = true
                // Analyze after 1.5s to let camera warm up
                self?.analyzeTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
                    self?.analyzeLatestFrame()
                }
            }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        latestBuffer = sampleBuffer
    }

    private func analyzeLatestFrame() {
        guard let buffer = latestBuffer,
              let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else {
            DispatchQueue.main.async { self.cameraValid = false }
            return
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            DispatchQueue.main.async { self.cameraValid = false }
            return
        }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let ptr = baseAddress.assumingMemoryBound(to: UInt8.self)

        // Sample ~100 pixels across the image
        var values: [Double] = []
        let sampleCount = 100
        for i in 0..<sampleCount {
            let x = (i * 7 + 13) % width
            let y = (i * 11 + 17) % height
            let offset = y * bytesPerRow + x * 4
            let r = Double(ptr[offset + 2])
            let g = Double(ptr[offset + 1])
            let b = Double(ptr[offset])
            values.append((r + g + b) / 3.0)
        }

        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count)
        let stddev = variance.squareRoot()

        // stddev > 5 means the image has real content (not uniform black/white)
        DispatchQueue.main.async {
            self.cameraValid = stddev > 5
        }
    }

    func capturePhoto() async -> Data? {
        return await withCheckedContinuation { continuation in
            self.photoContinuation = continuation
            let settings = AVCapturePhotoSettings(format: [
                AVVideoCodecKey: AVVideoCodecType.jpeg
            ])
            settings.flashMode = .off
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil {
            photoContinuation?.resume(returning: nil)
            photoContinuation = nil
            return
        }
        guard let data = photo.fileDataRepresentation() else {
            photoContinuation?.resume(returning: nil)
            photoContinuation = nil
            return
        }
        let compressed = UIImage(data: data)?.jpegData(compressionQuality: 0.7)
        photoContinuation?.resume(returning: compressed)
        photoContinuation = nil
    }

    func stop() {
        analyzeTimer?.invalidate()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        isRunning = false
    }
}
