import AVFoundation
import Combine

enum AudioState {
    case idle
    case recording(TimeInterval)
    case playing
    case done
    case error(String)
}

class AudioService: NSObject, ObservableObject {
    @Published var state: AudioState = .idle

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var recordDuration: TimeInterval = 3.0

    private var recordingURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("clearvue_mic_test.m4a")
    }

    func startRecording() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self else { return }
                if granted {
                    self.beginRecording()
                } else {
                    self.state = .error("Microphone access denied")
                }
            }
        }
    }

    private func beginRecording() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            ]

            recorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            recorder?.record()

            var elapsed: TimeInterval = 0
            state = .recording(recordDuration)

            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] t in
                guard let self else { t.invalidate(); return }
                elapsed += 0.1
                let remaining = max(0, self.recordDuration - elapsed)
                self.state = .recording(remaining)
                if elapsed >= self.recordDuration {
                    t.invalidate()
                    self.stopRecording()
                }
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func stopRecording() {
        recorder?.stop()
        playBack()
    }

    private func playBack() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            player = try AVAudioPlayer(contentsOf: recordingURL)
            player?.delegate = self
            player?.play()
            state = .playing
        } catch {
            state = .error("Playback failed: \(error.localizedDescription)")
        }
    }

    func cleanup() {
        timer?.invalidate()
        recorder?.stop()
        player?.stop()
        try? FileManager.default.removeItem(at: recordingURL)
        state = .idle
    }
}

extension AudioService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.state = .done
        }
    }
}
