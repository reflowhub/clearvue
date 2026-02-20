import SwiftUI
import AVFoundation
import MediaPlayer

struct ButtonsTestView: View {
    let test: TestDefinition
    let onComplete: (TestStatus, String?) -> Void

    @State private var currentStep = 0
    @State private var stepResults: [Bool?] = [nil, nil, nil, nil]
    @State private var volumeObservation: NSKeyValueObservation?
    @State private var initialVolume: Float = 0
    @State private var volumeDetected = false
    @State private var showingSummary = false

    private let steps = [
        ("Volume Up", "Press the Volume Up button"),
        ("Volume Down", "Press the Volume Down button"),
        ("Side Button", "Press and release the Side button (power)"),
        ("Mute Switch", "Toggle the Mute switch on the side"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text(test.name)
                    .font(.title2.weight(.bold))
                    .foregroundColor(Theme.textPrimary)

                if showingSummary {
                    summaryView
                } else {
                    stepView
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Hidden MPVolumeView to suppress system HUD
            VolumeHider()
                .frame(width: 0, height: 0)
                .opacity(0)

            if showingSummary {
                TestActionButtons(
                    onPass: { onComplete(.pass, summaryDetail) },
                    onFail: { onComplete(.fail, summaryDetail) },
                    onSkip: { onComplete(.skipped, nil) }
                )
            }
        }
        .onAppear {
            setupVolumeObservation()
        }
        .onDisappear {
            volumeObservation?.invalidate()
        }
    }

    @ViewBuilder
    private var stepView: some View {
        VStack(spacing: 12) {
            Text("Step \(currentStep + 1) of \(steps.count)")
                .font(.caption)
                .foregroundColor(Theme.textMuted)
                .textCase(.uppercase)
                .tracking(1)

            Text(steps[currentStep].0)
                .font(.title3.weight(.bold))
                .foregroundColor(Theme.textPrimary)

            Text(steps[currentStep].1)
                .font(.body)
                .foregroundColor(Theme.textSecondary)

            if volumeDetected && currentStep < 2 {
                Text("Detected!")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.pass)
            }

            // For volume steps (0, 1): auto-detect; for side/mute (2, 3): manual
            if currentStep >= 2 || (currentStep < 2 && !volumeDetected) {
                HStack(spacing: 12) {
                    Button(action: { recordStep(passed: false) }) {
                        Text("Didn't Work")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.surface)
                            .foregroundColor(Theme.textMuted)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
                    }

                    Button(action: { recordStep(passed: true) }) {
                        Text("Confirm Pressed")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.pass)
                            .foregroundColor(Color(hex: 0x0A0A0A))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    @ViewBuilder
    private var summaryView: some View {
        VStack(spacing: 0) {
            ForEach(0..<steps.count, id: \.self) { i in
                HStack {
                    Text(steps[i].0)
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text(stepResults[i] == true ? "Pass" : "Fail")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(stepResults[i] == true ? Theme.pass : Theme.fail)
                }
                .padding(.vertical, 10)
                .overlay(alignment: .bottom) {
                    if i < steps.count - 1 {
                        Theme.separator.frame(height: 1)
                    }
                }
            }
        }
        .frame(maxWidth: 320)
    }

    private func setupVolumeObservation() {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(true)
        initialVolume = session.outputVolume

        volumeObservation = session.observe(\.outputVolume, options: [.new]) { [self] session, change in
            DispatchQueue.main.async {
                if self.currentStep < 2 && !self.volumeDetected {
                    let newVolume = session.outputVolume
                    if self.currentStep == 0 && newVolume > self.initialVolume {
                        // Volume up detected
                        self.volumeDetected = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.recordStep(passed: true)
                        }
                    } else if self.currentStep == 1 && newVolume < self.initialVolume {
                        // Volume down detected
                        self.volumeDetected = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.recordStep(passed: true)
                        }
                    }
                    self.initialVolume = newVolume
                }
            }
        }
    }

    private func recordStep(passed: Bool) {
        stepResults[currentStep] = passed
        volumeDetected = false

        if currentStep < steps.count - 1 {
            currentStep += 1
            initialVolume = AVAudioSession.sharedInstance().outputVolume
        } else {
            showingSummary = true
        }
    }

    private var summaryDetail: String {
        steps.enumerated().map { i, step in
            "\(step.0): \(stepResults[i] == true ? "pass" : "fail")"
        }.joined(separator: ", ")
    }
}

struct VolumeHider: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView(frame: .zero)
        view.clipsToBounds = true
        return view
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
