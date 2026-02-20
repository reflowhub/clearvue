import SwiftUI

struct TestActionButtons: View {
    let onPass: () -> Void
    let onFail: () -> Void
    var onSkip: (() -> Void)? = nil
    var onNotSupported: (() -> Void)? = nil
    var passDisabled: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if let onSkip {
                Button(action: onSkip) {
                    Text("Skip")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TestButtonStyle(background: Theme.surface, foreground: Theme.textMuted))
            }

            if let onNotSupported {
                Button(action: onNotSupported) {
                    Text("Not Supported")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TestButtonStyle(background: Color(hex: 0x48484A), foreground: Theme.textSecondary))
            }

            Button(action: onFail) {
                Text("Fail")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(TestButtonStyle(background: Theme.fail, foreground: Theme.textPrimary))

            Button(action: onPass) {
                Text("Pass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(TestButtonStyle(background: Theme.pass, foreground: Color(hex: 0x0A0A0A)))
            .disabled(passDisabled)
            .opacity(passDisabled ? 0.3 : 1)
        }
        .padding(.horizontal)
        .padding(.bottom, 32)
    }
}

struct TestButtonStyle: ButtonStyle {
    let background: Color
    let foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .padding(.vertical, 16)
            .background(background)
            .foregroundColor(foreground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
