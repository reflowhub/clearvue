import SwiftUI
import AVFoundation

enum LensCheckPhase {
    case validating
    case readyToCapture
    case analyzing
    case result(LensAnalysisResult)
    case error(String)
}

struct CameraTestView: View {
    let test: TestDefinition
    let position: CameraPosition
    let onComplete: (TestStatus, String?) -> Void

    @StateObject private var cameraService = CameraService()
    @State private var lensPhase: LensCheckPhase = .validating
    @State private var capturedImage: UIImage?

    private let analysisService = LensAnalysisService()

    private var avPosition: AVCaptureDevice.Position {
        position == .front ? .front : .back
    }

    private var cameraLabel: String {
        position == .front ? "Front" : "Rear"
    }

    private var positionString: String {
        position == .front ? "front" : "rear"
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text(test.name)
                    .font(.title2.weight(.bold))
                    .foregroundColor(Theme.textPrimary)

                Text(statusDescription)
                    .font(.body)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)

                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.surface)

                    if let error = cameraService.error {
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(Theme.fail)
                            .padding()
                    } else if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        CameraPreviewView(session: cameraService.session)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    VStack {
                        HStack {
                            Text(position == .front ? "FRONT" : "REAR")
                                .font(.caption2.weight(.semibold))
                                .tracking(1)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            Spacer()
                            if let valid = cameraService.cameraValid {
                                Image(systemName: valid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(valid ? Theme.pass : Theme.fail)
                            }
                        }
                        Spacer()

                        if case .result(let result) = lensPhase {
                            HStack(spacing: 8) {
                                Image(systemName: result.pass ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                    .font(.title3)
                                    .foregroundColor(result.pass ? Theme.pass : Theme.fail)
                                Text(result.pass ? "Lens OK" : "Defect Detected")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(12)

                    if case .analyzing = lensPhase {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.black.opacity(0.5))
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            Text("Analyzing lens quality...")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white)
                        }
                    }
                }
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .frame(maxWidth: 320)
            }
            .padding(.horizontal, 24)

            Spacer()

            bottomButtons
        }
        .onAppear {
            cameraService.start(position: avPosition)
        }
        .onDisappear {
            cameraService.stop()
        }
        .onChange(of: cameraService.cameraValid) { valid in
            guard let valid else { return }
            if !valid {
                onComplete(.fail, "\(cameraLabel) camera: no image detected")
            } else {
                lensPhase = .readyToCapture
            }
        }
    }

    private var statusDescription: String {
        switch lensPhase {
        case .validating:
            return test.description
        case .readyToCapture:
            return "Camera hardware verified. Tap Capture to analyze lens quality with AI."
        case .analyzing:
            return "Analyzing photo for scratches, haze, cracks, and other defects..."
        case .result(let r):
            return r.explanation
        case .error(let msg):
            return msg + " Check the image manually for scratches, haze, or cracks."
        }
    }

    @ViewBuilder
    private var bottomButtons: some View {
        switch lensPhase {
        case .validating, .analyzing:
            EmptyView()

        case .readyToCapture:
            VStack(spacing: 12) {
                Button(action: captureAndAnalyze) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                        Text("Capture")
                    }
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
                }
                .padding(.horizontal)

                TestActionButtons(
                    onPass: { onComplete(.pass, "\(cameraLabel) camera functional") },
                    onFail: { onComplete(.fail, "\(cameraLabel) camera: lens damage reported") },
                    onSkip: { onComplete(.skipped, nil) }
                )
            }

        case .result(let result):
            TestActionButtons(
                onPass: {
                    let detail = result.pass
                        ? "\(cameraLabel) camera: AI lens check passed"
                        : "\(cameraLabel) camera: user overrode AI fail"
                    onComplete(.pass, detail)
                },
                onFail: {
                    let detail = result.pass
                        ? "\(cameraLabel) camera: user overrode AI pass"
                        : "\(cameraLabel) camera: AI detected lens defect"
                    onComplete(.fail, detail)
                },
                onSkip: { onComplete(.skipped, nil) }
            )

        case .error:
            TestActionButtons(
                onPass: { onComplete(.pass, "\(cameraLabel) camera functional (manual, AI unavailable)") },
                onFail: { onComplete(.fail, "\(cameraLabel) camera: lens damage reported (manual, AI unavailable)") },
                onSkip: { onComplete(.skipped, nil) }
            )
        }
    }

    private func captureAndAnalyze() {
        lensPhase = .analyzing

        Task {
            guard let photoData = await cameraService.capturePhoto() else {
                lensPhase = .error("Failed to capture photo.")
                return
            }

            capturedImage = UIImage(data: photoData)

            do {
                let result = try await analysisService.analyze(
                    imageData: photoData,
                    cameraPosition: positionString
                )
                lensPhase = .result(result)
            } catch {
                lensPhase = .error(error.localizedDescription)
            }
        }
    }
}
