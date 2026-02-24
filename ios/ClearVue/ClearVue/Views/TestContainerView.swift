import SwiftUI

struct TestContainerView: View {
    @ObservedObject var runner: TestRunner
    @State private var showExitConfirmation = false

    var body: some View {
        if let test = runner.currentTest {
            VStack(spacing: 0) {
                // Navigation header
                HStack {
                    Button(action: { runner.goBack() }) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundColor(runner.canGoBack ? Theme.textSecondary : Theme.textDim)
                            .frame(width: 44, height: 44)
                    }
                    .disabled(!runner.canGoBack)

                    Spacer()

                    Text("CLEARVUE")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .tracking(2)
                        .foregroundColor(Theme.textDim)

                    Spacer()

                    HStack(spacing: 4) {
                        Button(action: { runner.repeatTest() }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.body.weight(.medium))
                                .foregroundColor(Theme.textSecondary)
                                .frame(width: 44, height: 44)
                        }

                        Button(action: { showExitConfirmation = true }) {
                            Image(systemName: "xmark")
                                .font(.body.weight(.semibold))
                                .foregroundColor(Theme.textSecondary)
                                .frame(width: 44, height: 44)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                ProgressBarView(current: runner.currentIndex, total: runner.tests.count)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)

                Divider()
                    .overlay(Theme.separator)

                // Test content — keyed to force recreation on back/repeat
                testView(for: test)
                    .id(runner.testKey)
            }
            .alert("Exit Diagnostic?", isPresented: $showExitConfirmation) {
                Button("Continue Testing", role: .cancel) { }
                Button("Exit", role: .destructive) {
                    runner.exitTests()
                }
            } message: {
                Text("Your test progress will be lost.")
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
        case .buttons:
            ButtonsTestView(test: test, onComplete: onComplete)
        }
    }
}
