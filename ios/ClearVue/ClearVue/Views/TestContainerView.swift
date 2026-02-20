import SwiftUI

struct TestContainerView: View {
    @ObservedObject var runner: TestRunner

    var body: some View {
        if let test = runner.currentTest {
            VStack(spacing: 0) {
                // Header with progress
                VStack(alignment: .leading, spacing: 8) {
                    Text("CLEARVUE")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .tracking(2)
                        .foregroundColor(Theme.textDim)

                    ProgressBarView(current: runner.currentIndex, total: runner.tests.count)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)

                Divider()
                    .overlay(Theme.separator)

                // Test content
                testView(for: test)
            }
        }
    }

    @ViewBuilder
    private func testView(for test: TestDefinition) -> some View {
        let onComplete: (TestStatus, String?) -> Void = { status, detail in
            runner.record(test.id, status: status, detail: detail)
        }

        switch test.type {
        case .biometric:
            FaceIDTestView(test: test, onComplete: onComplete)
        case .display:
            DisplayTestView(test: test, onComplete: onComplete)
        case .manual:
            ManualTestView(test: test, onComplete: onComplete)
        case .camera(let position):
            CameraTestView(test: test, position: position, onComplete: onComplete)
        case .touch:
            TouchTestView(test: test, onComplete: onComplete)
        case .microphone:
            MicrophoneTestView(test: test, onComplete: onComplete)
        case .speaker:
            SpeakerTestView(test: test, onComplete: onComplete)
        case .connectivity(let subtype):
            ConnectivityTestView(test: test, subtype: subtype, onComplete: onComplete)
        case .bluetooth:
            BluetoothTestView(test: test, onComplete: onComplete)
        case .geolocation:
            LocationTestView(test: test, onComplete: onComplete)
        case .motion:
            MotionTestView(test: test, onComplete: onComplete)
        case .vibration:
            VibrationTestView(test: test, onComplete: onComplete)
        case .buttons:
            ButtonsTestView(test: test, onComplete: onComplete)
        case .nfc:
            NFCTestView(test: test, onComplete: onComplete)
        }
    }
}
