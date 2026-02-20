import SwiftUI

struct NFCTestView: View {
    let test: TestDefinition
    let onComplete: (TestStatus, String?) -> Void

    @StateObject private var service = NFCService()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text(test.name)
                    .font(.title2.weight(.bold))
                    .foregroundColor(Theme.textPrimary)

                nfcStatusView
            }
            .padding(.horizontal, 24)

            Spacer()

            if !service.isAvailable {
                TestActionButtons(
                    onPass: { onComplete(.pass, nil) },
                    onFail: { onComplete(.fail, nil) },
                    onNotSupported: { onComplete(.notTestable, "NFC not available on this device") }
                )
            } else {
                TestActionButtons(
                    onPass: { onComplete(.pass, nfcDetail) },
                    onFail: { onComplete(.fail, nil) },
                    onSkip: { onComplete(.skipped, nil) }
                )
            }
        }
    }

    @ViewBuilder
    private var nfcStatusView: some View {
        switch service.state {
        case .idle:
            VStack(spacing: 16) {
                Text(test.description)
                    .font(.body)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)

                if service.isAvailable {
                    Button(action: { service.startScan() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "wave.3.right")
                            Text("Scan NFC Tag")
                        }
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color(hex: 0x0A0A0A))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Theme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.textDim)
                        Text("NFC is not available on this device")
                            .font(.body)
                            .foregroundColor(Theme.textMuted)
                    }
                }
            }

        case .scanning:
            VStack(spacing: 8) {
                Image(systemName: "wave.3.right")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.textMuted)
                Text("Scanning...")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(Theme.textMuted)
                Text("Hold your iPhone near an NFC tag")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }

        case .found(let message):
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.pass)
                Text(message)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(Theme.pass)
            }

        case .failed(let message):
            VStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.fail)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(Theme.fail)
                    .multilineTextAlignment(.center)

                Button(action: { service.startScan() }) {
                    Text("Try Again")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Theme.surface)
                        .foregroundColor(Theme.textMuted)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
                }
            }

        case .unsupported:
            VStack(spacing: 8) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.textDim)
                Text("NFC is not available on this device")
                    .font(.body)
                    .foregroundColor(Theme.textMuted)
            }
        }
    }

    private var nfcDetail: String {
        if case .found(let msg) = service.state {
            return msg
        }
        return "NFC scan completed"
    }
}
