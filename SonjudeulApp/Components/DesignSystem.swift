import SwiftUI

// MARK: — Color Palette
extension Color {
    static let sonjuPrimary    = Color(hex: "#F5A623")
    static let sonjuDeep       = Color(hex: "#E8891A")
    static let sonjuBackground = Color(hex: "#FFF8ED")
    static let sonjuCard       = Color.white
    static let sonjuText       = Color(hex: "#1A1A1A")
    static let sonjuSecondary  = Color(hex: "#6B6B6B")
    static let sonjuSuccess    = Color(hex: "#4CAF50")
    static let sonjuDivider    = Color(hex: "#F0F0F0")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: — Typography
extension Font {
    static let sonjuLargeTitle  = Font.system(size: 28, weight: .bold)
    static let sonjuTitle       = Font.system(size: 22, weight: .bold)
    static let sonjuHeadline    = Font.system(size: 17, weight: .semibold)
    static let sonjuBody        = Font.system(size: 15, weight: .regular)
    static let sonjuCaption     = Font.system(size: 13, weight: .regular)
}

// MARK: — Press Button Style
struct PressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
