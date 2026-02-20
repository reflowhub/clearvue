import AVFoundation
import Combine

class CameraService: ObservableObject {
    let session = AVCaptureSession()
    @Published var isRunning = false
    @Published var error: String?

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

        // Remove existing inputs
        session.inputs.forEach { session.removeInput($0) }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device) else {
            error = "Camera not available"
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        session.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async {
                self?.isRunning = true
            }
        }
    }

    func stop() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }
        session.inputs.forEach { session.removeInput($0) }
        isRunning = false
    }
}
