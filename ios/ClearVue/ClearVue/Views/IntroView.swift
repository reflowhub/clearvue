import SwiftUI

struct IntroView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text("CLEARVUE")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .tracking(2)
                    .foregroundColor(Theme.textMuted)

                Text("iPhone Diagnostic")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.textPrimary, Theme.textSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Run a comprehensive diagnostic on your iPhone. Get a shareable report with verified test results.")
                    .font(.body)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
                    .padding(.bottom, 8)

                Button(action: onStart) {
                    Text("Start Diagnostic")
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color(hex: 0x0A0A0A))
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(Theme.textPrimary)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 16) {
                FeatureRow(icon: "17", title: "Functional Tests", subtitle: "Camera, touch, audio, sensors, connectivity and more")
                FeatureRow(icon: "PDF", title: "Downloadable Report", subtitle: "Timestamped results you can share with buyers")
                FeatureRow(icon: "0", title: "Data Sent Nowhere", subtitle: "All tests run locally on your device")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            Text("\u{00A9} 2026 ClearVue")
                .font(.caption2)
                .foregroundColor(Theme.textDim)
                .padding(.bottom, 16)
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.title2)
                .frame(width: 32, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Theme.textMuted)
            }

            Spacer()
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
    }
}
