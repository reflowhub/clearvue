import SwiftUI
import AVFoundation

struct SpeakerTestView: View {
    let test: TestDefinition
    let onComplete: (TestStatus, String?) -> Void

    @State private var phase: SpeakerPhase = .idle
    @State private var engine: AVAudioEngine?
    @State private var recorder: AVAudioRecorder?
    @State private var peakLevel: Float = -160

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

                Circle()
                    .fill(phase == .playing ? Theme.pass : Theme.surface)
                    .frame(width: 96, height: 96)
                    .shadow(color: phase == .playing ? Theme.pass.opacity(0.3) : .clear, radius: 20)
                    .overlay {
                        resultOverlay
                    }
                    .animation(.easeInOut(duration: 0.2), value: phase)

                if case .idle = phase {
                    Button(action: playAndRecord) {
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

            if case .error = phase {
                TestActionButtons(
                    onPass: { onComplete(.pass, "Speaker tone audible") },
                    onFail: { onComplete(.fail, nil) },
                    onSkip: { onComplete(.skipped, nil) }
                )
            }
        }
        .onDisappear {
            engine?.stop()
            recorder?.stop()
        }
    }

    private var statusDescription: String {
        switch phase {
        case .idle:
            return test.description
        case .playing:
            return "Playing tone and listening..."
        case .pass:
            return String(format: "Speaker verified — tone detected (peak: %.1f dB).", peakLevel)
        case .fail:
            return String(format: "No tone detected by microphone (peak: %.1f dB).", peakLevel)
        case .error(let msg):
            return msg
        }
    }

    @ViewBuilder
    private var resultOverlay: some View {
        switch phase {
        case .pass:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(Theme.pass)
        case .fail:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(Theme.fail)
        default:
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 32))
                .foregroundColor(phase == .playing ? Color(hex: 0x0A0A0A) : Theme.textMuted)
        }
    }

    private var recordingURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("clearvue_speaker_test.m4a")
    }

    private func playAndRecord() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    startPlayAndRecord()
                } else {
                    phase = .error("Microphone access denied. Cannot auto-verify speaker.")
                }
            }
        }
    }

    private func startPlayAndRecord() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, options: .defaultToSpeaker)
            try session.setActive(true)

            // Start recording
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            ]
            let rec = try AVAudioRecorder(url: recordingURL, settings: settings)
            rec.isMeteringEnabled = true
            rec.record()
            recorder = rec

            // Play tone
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
            playerNode.scheduleBuffer(buffer) {
                DispatchQueue.main.async {
                    finishTest()
                }
            }

            engine = audioEngine
            phase = .playing

            // Poll meter during playback
            peakLevel = -160
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { t in
                guard case .playing = phase else { t.invalidate(); return }
                rec.updateMeters()
                let level = rec.peakPower(forChannel: 0)
                peakLevel = max(peakLevel, level)
            }
        } catch {
            phase = .error("Audio error: \(error.localizedDescription)")
        }
    }

    private func finishTest() {
        recorder?.stop()
        engine?.stop()
        try? FileManager.default.removeItem(at: recordingURL)

        let passed = peakLevel > -40
        phase = passed ? .pass : .fail
        let detail = String(format: passed ? "Speaker tone detected (peak: %.1f dB)" : "No speaker tone detected (peak: %.1f dB)", peakLevel)
        onComplete(passed ? .pass : .fail, detail)
    }
}

private enum SpeakerPhase: Equatable {
    case idle
    case playing
    case pass
    case fail
    case error(String)
}
