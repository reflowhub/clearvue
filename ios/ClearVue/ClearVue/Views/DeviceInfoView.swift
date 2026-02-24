import SwiftUI

struct DeviceInfoView: View {
    @ObservedObject var runner: TestRunner

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 40))
                    .foregroundColor(Theme.textMuted)

                Text("Device Information")
                    .font(.title2.weight(.bold))
                    .foregroundColor(Theme.textPrimary)

                Text("Auto-detected device details for your diagnostic report.")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }
            .padding(.bottom, 32)

            // Auto-detected info
            VStack(spacing: 12) {
                DeviceInfoRow(label: "Model", value: DiagnosticReport.currentDeviceModel)
                DeviceInfoRow(label: "iOS Version", value: DiagnosticReport.currentIOSVersion)

                if let storage = DiagnosticReport.currentStorageTotal {
                    let gb = Double(storage) / 1_000_000_000
                    let roundedGB: Int = gb > 400 ? 512 : gb > 200 ? 256 : gb > 100 ? 128 : gb > 50 ? 64 : 32
                    DeviceInfoRow(label: "Storage", value: "\(roundedGB) GB")
                }

                if let health = DiagnosticReport.currentBatteryHealth {
                    DeviceInfoRow(label: "Battery", value: "\(health)%")
                } else if let charge = DiagnosticReport.currentBatteryLevel {
                    DeviceInfoRow(label: "Charge", value: "\(charge)%")
                }
            }
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
            .padding(.horizontal, 24)

            Spacer()

            Button(action: { runner.start() }) {
                Text("Start Tests")
                    .font(.body.weight(.semibold))
                    .foregroundColor(Color(hex: 0x0A0A0A))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

private struct DeviceInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Theme.textMuted)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(Theme.textPrimary)
        }
    }
}
