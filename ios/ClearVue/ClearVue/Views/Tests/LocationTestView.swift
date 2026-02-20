import SwiftUI
import CoreLocation

struct LocationTestView: View {
    let test: TestDefinition
    let onComplete: (TestStatus, String?) -> Void

    @StateObject private var service = LocationService()
    @State private var hasStarted = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text(test.name)
                    .font(.title2.weight(.bold))
                    .foregroundColor(Theme.textPrimary)

                locationStatusView
            }
            .padding(.horizontal, 24)

            Spacer()

            TestActionButtons(
                onPass: { onComplete(.pass, locationDetail) },
                onFail: { onComplete(.fail, nil) },
                onSkip: { onComplete(.skipped, nil) }
            )
        }
        .onDisappear {
            service.stop()
        }
    }

    @ViewBuilder
    private var locationStatusView: some View {
        switch service.state {
        case .idle:
            VStack(spacing: 16) {
                Text(test.description)
                    .font(.body)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)

                Button(action: {
                    hasStarted = true
                    service.requestLocation()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                        Text("Request Location")
                    }
                    .font(.body.weight(.semibold))
                    .foregroundColor(Color(hex: 0x0A0A0A))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Theme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
                }
            }

        case .requesting:
            VStack(spacing: 12) {
                Text("\(service.countdown)")
                    .font(.system(size: 48, weight: .bold))
                    .monospacedDigit()
                    .foregroundColor(Theme.textPrimary)

                Text("Acquiring GPS fix...")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(Theme.textMuted)
            }

        case .acquired(let location):
            VStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Theme.pass)

                Text("Location Acquired")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(Theme.pass)

                VStack(spacing: 4) {
                    Text("Lat: \(String(format: "%.6f", location.coordinate.latitude))")
                    Text("Lon: \(String(format: "%.6f", location.coordinate.longitude))")
                    Text("Accuracy: \(String(format: "%.0f", location.horizontalAccuracy))m")
                }
                .font(.subheadline.monospaced())
                .foregroundColor(Theme.textMuted)
            }

        case .failed(let msg):
            VStack(spacing: 8) {
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Theme.fail)

                Text(msg)
                    .font(.subheadline)
                    .foregroundColor(Theme.fail)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var locationDetail: String {
        if case .acquired(let location) = service.state {
            return "Lat: \(String(format: "%.6f", location.coordinate.latitude)), Lon: \(String(format: "%.6f", location.coordinate.longitude)), Accuracy: \(String(format: "%.0f", location.horizontalAccuracy))m"
        }
        return ""
    }
}
