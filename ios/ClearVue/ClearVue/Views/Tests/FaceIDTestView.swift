import SwiftUI

struct FaceIDTestView: View {
    let test: TestDefinition
    let onComplete: (TestStatus, String?) -> Void

    @State private var status: String = ""
    @State private var hasAttempted = false
    @State private var biometricFailed = false

    private let service = FaceIDService()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "faceid")
                    .font(.system(size: 64))
                    .foregroundColor(biometricFailed ? Theme.fail : Theme.textPrimary)

                Text(test.name)
                    .font(.title2.weight(.bold))
                    .foregroundColor(Theme.textPrimary)

                Text(test.description)
                    .font(.body)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)

                if !status.isEmpty {
                    Text(status)
                        .font(.subheadline)
                        .foregroundColor(biometricFailed ? Theme.fail : Theme.pass)
                        .padding(.top, 8)
                }

                if !hasAttempted {
                    Button(action: attemptAuth) {
                        Text("Test Face ID")
                            .font(.body.weight(.semibold))
                            .foregroundColor(Color(hex: 0x0A0A0A))
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(Theme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            if hasAttempted {
                TestActionButtons(
                    onPass: { onComplete(.pass, "Biometric auth successful") },
                    onFail: { onComplete(.fail, status) },
                    onSkip: { onComplete(.skipped, nil) }
                )
            } else {
                TestActionButtons(
                    onPass: { onComplete(.pass, nil) },
                    onFail: { onComplete(.fail, nil) },
                    onSkip: { onComplete(.skipped, nil) },
                    passDisabled: true
                )
            }
        }
    }

    private func attemptAuth() {
        Task {
            let result = await service.authenticate()
            hasAttempted = true
            switch result {
            case .success:
                status = "Face ID authenticated successfully"
                biometricFailed = false
                onComplete(.pass, "Biometric auth successful")
            case .failed(let msg):
                status = msg
                biometricFailed = true
            case .unavailable(let msg):
                status = msg
                biometricFailed = true
            }
        }
    }
}
