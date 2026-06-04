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

    // ── Existing design tokens ──
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

    // ── Notebook UI colors (from reference images) ──

    /// Warm cream notebook background
    static let notebookBg        = dynamic(light: "#F5EEDF", dark: "#1A1A1C")

    /// White paper card fill
    static let paperWhite        = dynamic(light: "#FFFEF9", dark: "#2A2A2E")

    /// Paper card border
    static let paperBorder       = dynamic(light: "#E8E2D6", dark: "#3A3A3C")

    /// Ruled line color on paper
    static let ruledLine         = dynamic(light: "#D9D3C6", dark: "#3A3A3C")

    /// Ink color for handwriting text
    static let inkColor          = dynamic(light: "#2C2820", dark: "#E8E4DD")

    /// Navigation pill background (cream-tinted)
    static let navPillBg         = dynamic(light: "#EDE8DC", dark: "#2C2C2E")

    /// Navigation text color
    static let navText           = dynamic(light: "#3A3530", dark: "#E0DCD5")

    /// Dark pill background (for "Choose Subject")
    static let navDarkPill       = dynamic(light: "#3A3832", dark: "#4A4A4E")

    /// AI button background (dark circle)
    static let aiButtonBg        = dynamic(light: "#3C3A36", dark: "#5A5A5E")

    /// AI Hint card background (light blue)
    static let hintCardBg        = dynamic(light: "#D6EBF5", dark: "#1A2A3A")

    /// AI Hint card border
    static let hintCardBorder    = dynamic(light: "#B8D8E8", dark: "#2A3A4A")

    /// Hint card title text color
    static let hintTitle         = dynamic(light: "#2C4A5E", dark: "#A0C0D8")

    /// Hint card body text color
    static let hintText          = dynamic(light: "#3A5268", dark: "#90B0C8")

    /// Solve button coral/salmon color
    static let solveBtnBg        = dynamic(light: "#E8736C", dark: "#D45A52")

    /// Bottom toolbar button text
    static let toolbarBtnText    = dynamic(light: "#5A4A42", dark: "#C0B8B0")

    /// Bottom toolbar button background (light pink)
    static let toolbarBtnBg      = dynamic(light: "#F8E8E4", dark: "#3A2A28")

    /// Bottom toolbar active button background
    static let toolbarBtnActiveBg = dynamic(light: "#F2D4CE", dark: "#4A3230")

    /// Toolbar button group background
    static let toolbarGroupBg    = dynamic(light: "#FAF0EC", dark: "#2A2220")

    /// Toolbar divider
    static let toolbarDivider    = dynamic(light: "#E0D0CA", dark: "#4A3A38")

    // ── Welcome / Onboarding colors ──

    /// Welcome page cream background
    static let welcomeBg         = dynamic(light: "#F8F4EA", dark: "#1A1A1C")

    /// Welcome "Get Started" / Continue dark button
    static let welcomeButtonBg   = dynamic(light: "#3A3832", dark: "#4A4A4E")

    /// Face circle: Red
    static let faceRed           = Color(red: 0.93, green: 0.18, blue: 0.15)
    /// Face circle: Blue (indigo-blue)
    static let faceBlue          = Color(red: 0.16, green: 0.14, blue: 0.75)
    /// Face circle: Yellow
    static let faceYellow        = Color(red: 1.0,  green: 0.85, blue: 0.0)
    /// Face circle: Pink / Hot pink
    static let facePink          = Color(red: 1.0,  green: 0.33, blue: 0.62)
    /// Face circle: Teal / Mint green
    static let faceTeal          = Color(red: 0.24, green: 0.80, blue: 0.68)

    // ── Home Dashboard colors ──

    /// Independence ring track (faint gray)
    static let ringTrack         = dynamic(light: "#EEEBE4", dark: "#2A2A2E")

    /// Ring segment: Yellow
    static let ringYellow        = Color(red: 0.95, green: 0.82, blue: 0.25)
    /// Ring segment: Blue / Lavender
    static let ringBlue          = Color(red: 0.60, green: 0.62, blue: 0.85)
    /// Ring segment: Green
    static let ringGreen         = Color(red: 0.35, green: 0.68, blue: 0.32)
    /// Ring segment: Olive / Dark
    static let ringOlive         = Color(red: 0.48, green: 0.55, blue: 0.28)

    /// Streak stat orange text
    static let streakOrange      = Color(red: 0.90, green: 0.55, blue: 0.15)
    /// Time stat green text
    static let timeGreen         = Color(red: 0.25, green: 0.65, blue: 0.45)

    /// Tab bar dark background
    static let tabBarDark        = dynamic(light: "#2A2826", dark: "#1A1A1C")
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
