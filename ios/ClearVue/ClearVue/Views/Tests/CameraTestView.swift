import SwiftUI
import AVFoundation

struct CameraTestView: View {
    let test: TestDefinition
    let position: CameraPosition
    let onComplete: (TestStatus, String?) -> Void

    @StateObject private var cameraService = CameraService()

    private var avPosition: AVCaptureDevice.Position {
        position == .front ? .front : .back
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text(test.name)
                    .font(.title2.weight(.bold))
                    .foregroundColor(Theme.textPrimary)

                Text(test.description)
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
                    } else {
                        CameraPreviewView(session: cameraService.session)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Camera label
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
                        }
                        Spacer()
                    }
                    .padding(12)
                }
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .frame(maxWidth: 320)
            }
            .padding(.horizontal, 24)

            Spacer()

            TestActionButtons(
                onPass: { onComplete(.pass, "\(position == .front ? "Front" : "Rear") camera functional") },
                onFail: { onComplete(.fail, nil) },
                onSkip: { onComplete(.skipped, nil) }
            )
        }
        .onAppear {
            cameraService.start(position: avPosition)
        }
        .onDisappear {
            cameraService.stop()
        }
    }
}
