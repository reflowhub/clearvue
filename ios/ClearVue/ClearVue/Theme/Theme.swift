import SwiftUI

enum Theme {
    static let background = Color(hex: 0x0A0A0A)
    static let surface = Color(hex: 0x1D1D1F)
    static let textPrimary = Color(hex: 0xF5F5F7)
    static let textSecondary = Color(hex: 0xA1A1A6)
    static let textMuted = Color(hex: 0x86868B)
    static let textDim = Color(hex: 0x48484A)
    static let separator = Color(hex: 0x1D1D1F)

    static let pass = Color(hex: 0x30D158)
    static let fail = Color(hex: 0xFF453A)

    static let passBadgeBG = Color(hex: 0x30D158).opacity(0.15)
    static let failBadgeBG = Color(hex: 0xFF453A).opacity(0.15)
    static let skippedBadgeBG = Color(hex: 0x86868B).opacity(0.15)
    static let notTestableBadgeBG = Color(hex: 0x48484A).opacity(0.2)

    static let buttonRadius: CGFloat = 14
    static let cardRadius: CGFloat = 12
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
