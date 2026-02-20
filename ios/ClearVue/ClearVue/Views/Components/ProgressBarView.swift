import SwiftUI

struct ProgressBarView: View {
    let current: Int
    let total: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.surface)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.textPrimary)
                        .frame(width: geo.size.width * progress, height: 4)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)

            Text("Test \(current + 1) of \(total)")
                .font(.caption)
                .foregroundColor(Theme.textMuted)
        }
    }
}
