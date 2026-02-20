import SwiftUI

struct StatusBadgeView: View {
    let status: TestStatus

    private var label: String {
        switch status {
        case .pass: return "Pass"
        case .fail: return "Fail"
        case .skipped: return "Skipped"
        case .notTestable: return "N/A"
        }
    }

    private var background: Color {
        switch status {
        case .pass: return Theme.passBadgeBG
        case .fail: return Theme.failBadgeBG
        case .skipped: return Theme.skippedBadgeBG
        case .notTestable: return Theme.notTestableBadgeBG
        }
    }

    private var foreground: Color {
        switch status {
        case .pass: return Theme.pass
        case .fail: return Theme.fail
        case .skipped: return Theme.textMuted
        case .notTestable: return Theme.textDim
        }
    }

    var body: some View {
        Text(label)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(background)
            .foregroundColor(foreground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
