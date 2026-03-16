import SwiftUI

enum Theme {
    // Brand gradient: indigo → violet
    static let gradient = LinearGradient(
        colors: [Color(hex: 0x6C3AED), Color(hex: 0xA855F7)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let subtleGradient = LinearGradient(
        colors: [Color(hex: 0x6C3AED).opacity(0.15), Color(hex: 0xA855F7).opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accent = Color(hex: 0x8B5CF6)
    static let accentDim = Color(hex: 0x8B5CF6).opacity(0.5)
    static let surface = Color(nsColor: .windowBackgroundColor).opacity(0.95)
    static let codeBg = Color(nsColor: .textBackgroundColor).opacity(0.6)
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
