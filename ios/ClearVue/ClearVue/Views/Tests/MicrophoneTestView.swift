import SwiftUI

struct MicrophoneTestView: View {
    let test: TestDefinition
    let onComplete: (TestStatus, String?) -> Void

    @StateObject private var audioService = AudioService()

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

            if case .error = audioService.state {
                TestActionButtons(
                    onPass: { onComplete(.pass, nil) },
                    onFail: { onComplete(.fail, "Microphone error") },
                    onSkip: { onComplete(.skipped, nil) }
                )
            } else if case .idle = audioService.state {
                TestActionButtons(
                    onPass: { onComplete(.pass, nil) },
                    onFail: { onComplete(.fail, nil) },
                    onSkip: { onComplete(.skipped, nil) }
                )
            }
        }
        .onDisappear {
            audioService.cleanup()
        }
        .onChange(of: audioService.state.isDone) { done in
            guard done else { return }
            let passed = audioService.recordingDetected
            let peak = String(format: "%.1f", audioService.peakRecordingLevel)
            onComplete(
                passed ? .pass : .fail,
                passed ? "Audio detected (peak: \(peak) dB)" : "No audio detected (peak: \(peak) dB)"
            )
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch audioService.state {
        case .idle:
            Button(action: {
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
            VStack(spacing: 8) {
                Image(systemName: audioService.recordingDetected ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(audioService.recordingDetected ? Theme.pass : Theme.fail)
                Text(audioService.recordingDetected ? "Microphone working" : "No audio detected")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(audioService.recordingDetected ? Theme.pass : Theme.fail)
            }

        case .error(let msg):
            Text(msg)
                .font(.subheadline)
                .foregroundColor(Theme.fail)
                .multilineTextAlignment(.center)
        }
    }
}
