import SwiftUI
import UIKit

struct VibrationTestView: View {
    let test: TestDefinition
    let onComplete: (TestStatus, String?) -> Void

    @State private var hasTriggered = false

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

                if hasTriggered {
                    Text("Did you feel a vibration?")
                        .font(.body)
                        .foregroundColor(Theme.textSecondary)
                } else {
                    Button(action: triggerHaptic) {
                        HStack(spacing: 8) {
                            Image(systemName: "iphone.radiowaves.left.and.right")
                            Text("Trigger Haptic")
                        }
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color(hex: 0x0A0A0A))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Theme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
                    }

                    Text("Your device will vibrate three times")
                        .font(.caption)
                        .foregroundColor(Theme.textMuted)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            TestActionButtons(
                onPass: { onComplete(.pass, "Haptic feedback confirmed") },
                onFail: { onComplete(.fail, nil) },
                onSkip: { onComplete(.skipped, nil) }
            )
        }
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()

        // Three pulses with short delays
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            generator.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            generator.impactOccurred()
        }

        hasTriggered = true
    }
}
