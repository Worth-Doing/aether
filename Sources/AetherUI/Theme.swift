import SwiftUI

public enum AetherTheme {
    // MARK: - Colors
    public enum Colors {
        public static let background = Color(nsColor: .init(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0))
        public static let surface = Color(nsColor: .init(red: 0.11, green: 0.11, blue: 0.13, alpha: 1.0))
        public static let surfaceElevated = Color(nsColor: .init(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0))
        public static let surfaceHover = Color(nsColor: .init(red: 0.17, green: 0.17, blue: 0.19, alpha: 1.0))

        public static let border = Color.white.opacity(0.08)
        public static let borderFocused = Color.white.opacity(0.2)

        public static let textPrimary = Color.white.opacity(0.92)
        public static let textSecondary = Color.white.opacity(0.55)
        public static let textTertiary = Color.white.opacity(0.35)

        public static let accent = Color(nsColor: .init(red: 0.35, green: 0.55, blue: 1.0, alpha: 1.0))
        public static let accentSubtle = Color(nsColor: .init(red: 0.35, green: 0.55, blue: 1.0, alpha: 0.15))

        public static let success = Color(nsColor: .init(red: 0.3, green: 0.8, blue: 0.5, alpha: 1.0))
        public static let warning = Color(nsColor: .init(red: 0.95, green: 0.75, blue: 0.3, alpha: 1.0))
        public static let error = Color(nsColor: .init(red: 0.95, green: 0.35, blue: 0.35, alpha: 1.0))

        public static let tabActive = surfaceElevated
        public static let tabInactive = Color.clear
        public static let sidebarBackground = Color(nsColor: .init(red: 0.06, green: 0.06, blue: 0.08, alpha: 1.0))
    }

    // MARK: - Typography
    public enum Typography {
        public static let title = Font.system(size: 20, weight: .semibold, design: .default)
        public static let heading = Font.system(size: 15, weight: .semibold, design: .default)
        public static let body = Font.system(size: 13, weight: .regular, design: .default)
        public static let bodyMedium = Font.system(size: 13, weight: .medium, design: .default)
        public static let caption = Font.system(size: 11, weight: .regular, design: .default)
        public static let captionMedium = Font.system(size: 11, weight: .medium, design: .default)
        public static let mono = Font.system(size: 12, weight: .regular, design: .monospaced)
        public static let commandBar = Font.system(size: 15, weight: .regular, design: .default)
        public static let tabTitle = Font.system(size: 12, weight: .medium, design: .default)
    }

    // MARK: - Spacing
    public enum Spacing {
        public static let xs: CGFloat = 2
        public static let sm: CGFloat = 4
        public static let md: CGFloat = 8
        public static let lg: CGFloat = 12
        public static let xl: CGFloat = 16
        public static let xxl: CGFloat = 24
        public static let xxxl: CGFloat = 32
    }

    // MARK: - Corner Radius
    public enum Radius {
        public static let sm: CGFloat = 4
        public static let md: CGFloat = 6
        public static let lg: CGFloat = 8
        public static let xl: CGFloat = 12
        public static let full: CGFloat = 100
    }

    // MARK: - Sizes
    public enum Sizes {
        public static let toolbarHeight: CGFloat = 40
        public static let tabBarHeight: CGFloat = 34
        public static let sidebarWidth: CGFloat = 240
        public static let commandBarHeight: CGFloat = 44
        public static let commandBarWidth: CGFloat = 600
        public static let minPanelWidth: CGFloat = 300
        public static let minPanelHeight: CGFloat = 200
    }

    // MARK: - Animation
    public enum Animation {
        public static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        public static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        public static let slow = SwiftUI.Animation.easeInOut(duration: 0.4)
        public static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
    }
}
