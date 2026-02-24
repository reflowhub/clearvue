import SwiftUI
import CoreBluetooth

struct BluetoothTestView: View {
    let test: TestDefinition
    let onComplete: (TestStatus, String?) -> Void

    @StateObject private var service = BluetoothService()
    @State private var autoCompleted = false
    @State private var verified = false

    private var statusColor: Color {
        switch service.state {
        case .poweredOn: return Theme.pass
        case .poweredOff: return Theme.fail
        case .unauthorized: return Theme.fail
        case .unsupported: return Theme.textDim
        default: return Theme.textMuted
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text(test.name)
                    .font(.title2.weight(.bold))
                    .foregroundColor(Theme.textPrimary)

                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 48))
                    .foregroundColor(statusColor)

                Text(service.stateDescription)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(statusColor)

                if verified {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Verified")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.pass)
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            if service.state == .unsupported {
                TestActionButtons(
                    onPass: { onComplete(.pass, nil) },
                    onFail: { onComplete(.fail, nil) },
                    onNotSupported: { onComplete(.notTestable, "Bluetooth not supported") }
                )
            } else {
                TestActionButtons(
                    onPass: { onComplete(.pass, "Bluetooth state: \(service.stateDescription)") },
                    onFail: { onComplete(.fail, service.stateDescription) },
                    onSkip: { onComplete(.skipped, nil) }
                )
            }
        }
        .onAppear {
            service.check()
        }
        .onDisappear {
            service.stop()
        }
        .onChange(of: service.state) { newState in
            if newState == .poweredOn && !autoCompleted {
                autoCompleted = true
                withAnimation { verified = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    onComplete(.pass, "Bluetooth state: \(service.stateDescription)")
                }
            }
        }
    }
}
