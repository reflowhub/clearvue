import SwiftUI
import AVFoundation

struct SpeakerTestView: View {
    let test: TestDefinition
    let onComplete: (TestStatus, String?) -> Void

    @State private var isPlaying = false
    @State private var hasPlayed = false
    @State private var engine: AVAudioEngine?

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

                // Tone indicator circle
                Circle()
                    .fill(isPlaying ? Theme.pass : Theme.surface)
                    .frame(width: 96, height: 96)
                    .shadow(color: isPlaying ? Theme.pass.opacity(0.3) : .clear, radius: 20)
                    .overlay {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 32))
                            .foregroundColor(isPlaying ? Color(hex: 0x0A0A0A) : Theme.textMuted)
                    }
                    .animation(.easeInOut(duration: 0.2), value: isPlaying)

                if hasPlayed {
                    Text("Could you hear the test tone?")
                        .font(.body)
                        .foregroundColor(Theme.textSecondary)
                } else if !isPlaying {
                    Button(action: playTone) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Play Test Tone")
                        }
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color(hex: 0x0A0A0A))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Theme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            TestActionButtons(
                onPass: { onComplete(.pass, "Speaker tone audible") },
                onFail: { onComplete(.fail, nil) },
                onSkip: { onComplete(.skipped, nil) }
            )
        }
        .onDisappear {
            engine?.stop()
        }
    }

    private func playTone() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            let audioEngine = AVAudioEngine()
            let playerNode = AVAudioPlayerNode()
            audioEngine.attach(playerNode)

            let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
            audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)

            let sampleRate = format.sampleRate
            let duration = 2.0
            let frameCount = AVAudioFrameCount(sampleRate * duration)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
            buffer.frameLength = frameCount

            let frequency = 1000.0
            let data = buffer.floatChannelData![0]
            for i in 0..<Int(frameCount) {
                data[i] = Float(sin(2.0 * .pi * frequency * Double(i) / sampleRate)) * 0.5
            }

            try audioEngine.start()
            playerNode.play()
            playerNode.scheduleBuffer(buffer) { [self] in
                DispatchQueue.main.async {
                    self.isPlaying = false
                    self.hasPlayed = true
                }
            }

            engine = audioEngine
            isPlaying = true
        } catch {
            // Fallback: just mark as playable
            hasPlayed = true
        }
    }
}
