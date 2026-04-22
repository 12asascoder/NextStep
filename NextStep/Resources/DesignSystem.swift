import SwiftUI
import UIKit

// MARK: - NSDesign tokens

extension Color {
    // Helper for dynamic colors
    static func dynamic(light: String, dark: String) -> Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }

    static let paperBackground   = dynamic(light: "#F7F3EB", dark: "#1C1C1E")
    static let paperCard         = dynamic(light: "#FFFDF8", dark: "#2C2C2E")
    static let accentGreen       = dynamic(light: "#4CAF82", dark: "#388E3C")
    static let accentBlue        = dynamic(light: "#4A90D9", dark: "#5B8AF5")
    static let accentAmber       = dynamic(light: "#F5A623", dark: "#FF8F00")
    static let textPrimary       = dynamic(light: "#1C1C1E", dark: "#F2F2F7")
    static let textSecondary     = dynamic(light: "#6E6E73", dark: "#AEAEB2")
    static let blockBorder       = dynamic(light: "#E2DDD4", dark: "#3A3A3C")
    static let aiPanelBg         = dynamic(light: "#EEF4FF", dark: "#1A233A")
    static let blockedStateBg    = dynamic(light: "#FFF3E0", dark: "#3E2723")
    static let blockedAccent     = dynamic(light: "#F5A623", dark: "#FF8F00")
    static let resultBg          = dynamic(light: "#F0FBF4", dark: "#1B3A22")
    static let resultAccent      = dynamic(light: "#34A85A", dark: "#4CAF50")
}

// MARK: - UIColor Hex Extension

extension UIColor {
    convenience init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch h.count {
        case 6:
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: CGFloat(a) / 255.0
        )
    }
}

// MARK: - Typography helpers

struct NSFont {
    static let title    = Font.system(size: 24, weight: .bold,   design: .rounded)
    static let heading  = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let body     = Font.system(size: 16, weight: .regular, design: .rounded)
    static let caption  = Font.system(size: 13, weight: .regular, design: .rounded)
    static let mono     = Font.system(size: 16, weight: .regular, design: .monospaced)
    static let math     = Font.system(size: 20, weight: .medium,  design: .rounded)
}

// MARK: - Shadow helpers

extension View {
    func cardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    func softShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Dot Grid Background

struct DotGridBackground: View {
    var spacing: CGFloat = 20
    var dotSize: CGFloat = 2
    var color: Color = Color.textSecondary.opacity(0.3)

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                for x in stride(from: 0, to: geometry.size.width, by: spacing) {
                    for y in stride(from: 0, to: geometry.size.height, by: spacing) {
                        path.addEllipse(in: CGRect(x: x, y: y, width: dotSize, height: dotSize))
                    }
                }
            }
            .fill(color)
        }
        .ignoresSafeArea()
    }
}
