import SwiftUI

struct MicrophoneTestView: View {
    let test: TestDefinition
    let onComplete: (TestStatus, String?) -> Void

    @StateObject private var audioService = AudioService()
    @State private var hasStarted = false

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

                statusView
            }
            .padding(.horizontal, 24)

            Spacer()

            TestActionButtons(
                onPass: { onComplete(.pass, "Microphone recording and playback successful") },
                onFail: { onComplete(.fail, nil) },
                onSkip: { onComplete(.skipped, nil) }
            )
        }
        .onDisappear {
            audioService.cleanup()
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch audioService.state {
        case .idle:
            Button(action: {
                hasStarted = true
                audioService.startRecording()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill")
                    Text("Start Recording")
                }
                .font(.body.weight(.semibold))
                .foregroundColor(Color(hex: 0x0A0A0A))
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Theme.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
            }

        case .recording(let remaining):
            VStack(spacing: 8) {
                Text("Recording...")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(Theme.fail)
                Text(String(format: "%.1f", remaining))
                    .font(.system(size: 48, weight: .bold))
                    .monospacedDigit()
                    .foregroundColor(Theme.textPrimary)
            }

        case .playing:
            VStack(spacing: 8) {
                Text("Playing back...")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(Theme.pass)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Theme.pass)
            }

        case .done:
            Text("Playback complete. Could you hear the recording?")
                .font(.body)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)

        case .error(let msg):
            Text(msg)
                .font(.subheadline)
                .foregroundColor(Theme.fail)
                .multilineTextAlignment(.center)
        }
    }
}
