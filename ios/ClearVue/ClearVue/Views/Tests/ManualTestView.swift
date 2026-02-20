import SwiftUI

struct ManualTestView: View {
    let test: TestDefinition
    let onComplete: (TestStatus, String?) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                Text(test.name)
                    .font(.title2.weight(.bold))
                    .foregroundColor(Theme.textPrimary)

                Text(test.description)
                    .font(.body)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }
            .padding(.horizontal, 24)

            Spacer()

            TestActionButtons(
                onPass: { onComplete(.pass, nil) },
                onFail: { onComplete(.fail, nil) },
                onSkip: { onComplete(.skipped, nil) },
                onNotSupported: test.showNotSupported ? { onComplete(.notTestable, nil) } : nil
            )
        }
    }
}
