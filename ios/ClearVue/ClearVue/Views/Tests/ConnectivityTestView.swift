import SwiftUI

struct ConnectivityTestView: View {
    let test: TestDefinition
    let subtype: ConnectivitySubtype
    let onComplete: (TestStatus, String?) -> Void

    @StateObject private var service = ConnectivityService()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text(test.name)
                    .font(.title2.weight(.bold))
                    .foregroundColor(Theme.textPrimary)

                Image(systemName: subtype == .wifi ? "wifi" : "antenna.radiowaves.left.and.right")
                    .font(.system(size: 48))
                    .foregroundColor(statusColor)

                statusText

                detailText
            }
            .padding(.horizontal, 24)

            Spacer()

            TestActionButtons(
                onPass: { onComplete(.pass, statusDetail) },
                onFail: { onComplete(.fail, nil) },
                onSkip: { onComplete(.skipped, nil) }
            )
        }
        .onAppear {
            if subtype == .wifi {
                service.checkWifi()
            } else {
                service.checkCellular()
            }
        }
        .onDisappear {
            service.stop()
        }
    }

    private var currentStatus: ConnectivityService.ConnectionStatus {
        subtype == .wifi ? service.wifiStatus : service.cellularStatus
    }

    private var statusColor: Color {
        switch currentStatus {
        case .connected: return Theme.pass
        case .disconnected: return Theme.fail
        case .checking: return Theme.textMuted
        case .error: return Theme.fail
        }
    }

    @ViewBuilder
    private var statusText: some View {
        switch currentStatus {
        case .connected:
            Text(subtype == .wifi ? "Wi-Fi Connected" : "Cellular Connected")
                .font(.title3.weight(.semibold))
                .foregroundColor(Theme.pass)
        case .disconnected:
            Text(subtype == .wifi ? "Wi-Fi Not Connected" : "No Cellular Signal")
                .font(.title3.weight(.semibold))
                .foregroundColor(Theme.fail)
        case .checking:
            Text("Checking...")
                .font(.title3.weight(.semibold))
                .foregroundColor(Theme.textMuted)
        case .error(let msg):
            Text(msg)
                .font(.subheadline)
                .foregroundColor(Theme.fail)
        }
    }

    @ViewBuilder
    private var detailText: some View {
        if subtype == .cellular {
            VStack(spacing: 4) {
                if !service.carrierName.isEmpty {
                    Text("Carrier: \(service.carrierName)")
                }
                if !service.radioTechnology.isEmpty {
                    Text("Network: \(service.radioTechnology)")
                }
            }
            .font(.subheadline)
            .foregroundColor(Theme.textMuted)
            .monospacedDigit()
        }
    }

    private var statusDetail: String {
        if subtype == .cellular {
            var parts: [String] = []
            if !service.carrierName.isEmpty { parts.append("Carrier: \(service.carrierName)") }
            if !service.radioTechnology.isEmpty { parts.append("Network: \(service.radioTechnology)") }
            return parts.joined(separator: ", ")
        }
        return "Wi-Fi connected"
    }
}
