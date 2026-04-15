import SwiftUI
import AppKit

// MARK: - Theme Mode

public enum ThemeMode: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"

    public var id: String { rawValue }

    public var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    public var icon: String {
        switch self {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .system: return "circle.lefthalf.filled"
        }
    }
}

// MARK: - Search Engine

public enum SearchEngine: String, CaseIterable, Identifiable {
    case duckDuckGo = "DuckDuckGo"
    case google = "Google"
    case bing = "Bing"
    case brave = "Brave"

    public var id: String { rawValue }

    public func searchURL(for query: String) -> URL? {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        switch self {
        case .duckDuckGo: return URL(string: "https://duckduckgo.com/?q=\(encoded)")
        case .google: return URL(string: "https://www.google.com/search?q=\(encoded)")
        case .bing: return URL(string: "https://www.bing.com/search?q=\(encoded)")
        case .brave: return URL(string: "https://search.brave.com/search?q=\(encoded)")
        }
    }

    public var icon: String {
        switch self {
        case .duckDuckGo: return "shield"
        case .google: return "magnifyingglass"
        case .bing: return "globe"
        case .brave: return "bolt.shield"
        }
    }
}

// MARK: - Aether Theme

public enum AetherTheme {
    // MARK: - Colors (Adaptive Light / Dark)
    public enum Colors {
        // Backgrounds
        public static let background = adaptive(
            light: NSColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0),
            dark: NSColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1.0)
        )

        public static let surface = adaptive(
            light: NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            dark: NSColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1.0)
        )

        public static let surfaceElevated = adaptive(
            light: NSColor(red: 0.94, green: 0.94, blue: 0.95, alpha: 1.0),
            dark: NSColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0)
        )

        public static let surfaceHover = adaptive(
            light: NSColor(red: 0.91, green: 0.91, blue: 0.92, alpha: 1.0),
            dark: NSColor(red: 0.17, green: 0.17, blue: 0.19, alpha: 1.0)
        )

        // Glass surfaces
        public static let glassBackground = adaptive(
            light: NSColor(white: 1.0, alpha: 0.72),
            dark: NSColor(white: 0.12, alpha: 0.68)
        )

        public static let glassSurface = adaptive(
            light: NSColor(white: 1.0, alpha: 0.55),
            dark: NSColor(white: 0.15, alpha: 0.45)
        )

        public static let glassToolbar = adaptive(
            light: NSColor(white: 0.98, alpha: 0.82),
            dark: NSColor(white: 0.10, alpha: 0.78)
        )

        public static let glassSidebar = adaptive(
            light: NSColor(white: 0.96, alpha: 0.75),
            dark: NSColor(white: 0.08, alpha: 0.72)
        )

        public static let glassCard = adaptive(
            light: NSColor(white: 1.0, alpha: 0.65),
            dark: NSColor(white: 0.14, alpha: 0.55)
        )

        public static let glassHover = adaptive(
            light: NSColor(white: 1.0, alpha: 0.85),
            dark: NSColor(white: 0.18, alpha: 0.65)
        )

        public static let glassActive = adaptive(
            light: NSColor(white: 1.0, alpha: 0.92),
            dark: NSColor(white: 0.20, alpha: 0.75)
        )

        // Glass borders
        public static let glassBorder = adaptive(
            light: NSColor(white: 1.0, alpha: 0.60),
            dark: NSColor(white: 1.0, alpha: 0.08)
        )

        public static let glassBorderSubtle = adaptive(
            light: NSColor(white: 0.0, alpha: 0.06),
            dark: NSColor(white: 1.0, alpha: 0.05)
        )

        // Borders
        public static let border = adaptive(
            light: NSColor.black.withAlphaComponent(0.10),
            dark: NSColor.white.withAlphaComponent(0.08)
        )

        public static let borderFocused = adaptive(
            light: NSColor.black.withAlphaComponent(0.20),
            dark: NSColor.white.withAlphaComponent(0.18)
        )

        // Text
        public static let textPrimary = adaptive(
            light: NSColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 0.88),
            dark: NSColor(white: 1.0, alpha: 0.92)
        )

        public static let textSecondary = adaptive(
            light: NSColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 0.50),
            dark: NSColor(white: 1.0, alpha: 0.55)
        )

        public static let textTertiary = adaptive(
            light: NSColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 0.30),
            dark: NSColor(white: 1.0, alpha: 0.32)
        )

        // Accent
        public static let accent = adaptive(
            light: NSColor(red: 0.20, green: 0.48, blue: 1.0, alpha: 1.0),
            dark: NSColor(red: 0.38, green: 0.60, blue: 1.0, alpha: 1.0)
        )

        public static let accentSubtle = adaptive(
            light: NSColor(red: 0.20, green: 0.48, blue: 1.0, alpha: 0.10),
            dark: NSColor(red: 0.38, green: 0.60, blue: 1.0, alpha: 0.14)
        )

        public static let accentGlow = adaptive(
            light: NSColor(red: 0.20, green: 0.48, blue: 1.0, alpha: 0.20),
            dark: NSColor(red: 0.38, green: 0.60, blue: 1.0, alpha: 0.25)
        )

        // Status
        public static let success = adaptive(
            light: NSColor(red: 0.15, green: 0.72, blue: 0.40, alpha: 1.0),
            dark: NSColor(red: 0.25, green: 0.82, blue: 0.50, alpha: 1.0)
        )

        public static let warning = adaptive(
            light: NSColor(red: 0.95, green: 0.62, blue: 0.07, alpha: 1.0),
            dark: NSColor(red: 1.0, green: 0.72, blue: 0.20, alpha: 1.0)
        )

        public static let error = adaptive(
            light: NSColor(red: 0.92, green: 0.28, blue: 0.28, alpha: 1.0),
            dark: NSColor(red: 1.0, green: 0.40, blue: 0.40, alpha: 1.0)
        )

        // Semantic
        public static let tabActive = adaptive(
            light: NSColor(white: 1.0, alpha: 0.90),
            dark: NSColor(white: 0.16, alpha: 0.85)
        )

        public static let tabInactive = Color.clear

        public static let sidebarBackground = adaptive(
            light: NSColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 0.80),
            dark: NSColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 0.80)
        )

        // Overlay & Shadow
        public static let overlayBackground = adaptive(
            light: NSColor.black.withAlphaComponent(0.25),
            dark: NSColor.black.withAlphaComponent(0.45)
        )

        public static let shadowColor = adaptive(
            light: NSColor.black.withAlphaComponent(0.08),
            dark: NSColor.black.withAlphaComponent(0.50)
        )

        public static let shadowSubtle = adaptive(
            light: NSColor.black.withAlphaComponent(0.04),
            dark: NSColor.black.withAlphaComponent(0.30)
        )

        public static let shadowDeep = adaptive(
            light: NSColor.black.withAlphaComponent(0.15),
            dark: NSColor.black.withAlphaComponent(0.60)
        )

        // Find bar
        public static let findHighlight = Color(nsColor: NSColor(
            red: 1.0, green: 0.84, blue: 0.0, alpha: 0.4
        ))

        // Provider colors
        public static let firecrawlColor = Color.orange
        public static let exaColor = Color.purple
        public static let tavilyColor = adaptive(
            light: NSColor(red: 0.20, green: 0.48, blue: 1.0, alpha: 1.0),
            dark: NSColor(red: 0.38, green: 0.60, blue: 1.0, alpha: 1.0)
        )

        // Gradient surfaces
        public static let toolbarGradientStart = adaptive(
            light: NSColor(white: 0.99, alpha: 0.95),
            dark: NSColor(white: 0.09, alpha: 0.92)
        )

        public static let toolbarGradientEnd = adaptive(
            light: NSColor(white: 0.96, alpha: 0.88),
            dark: NSColor(white: 0.07, alpha: 0.85)
        )

        public static let newTabGradient1 = adaptive(
            light: NSColor(red: 0.95, green: 0.96, blue: 0.99, alpha: 1.0),
            dark: NSColor(red: 0.06, green: 0.06, blue: 0.10, alpha: 1.0)
        )

        public static let newTabGradient2 = adaptive(
            light: NSColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1.0),
            dark: NSColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0)
        )

        // Helper
        private static func adaptive(light: NSColor, dark: NSColor) -> Color {
            Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
                if appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
                    return dark
                } else {
                    return light
                }
            }))
        }
    }

    // MARK: - Typography
    public enum Typography {
        public static let largeTitle = Font.system(size: 28, weight: .bold, design: .rounded)
        public static let title = Font.system(size: 20, weight: .semibold, design: .rounded)
        public static let heading = Font.system(size: 15, weight: .semibold, design: .default)
        public static let body = Font.system(size: 13, weight: .regular, design: .default)
        public static let bodyMedium = Font.system(size: 13, weight: .medium, design: .default)
        public static let caption = Font.system(size: 11, weight: .regular, design: .default)
        public static let captionMedium = Font.system(size: 11, weight: .medium, design: .default)
        public static let mono = Font.system(size: 12, weight: .regular, design: .monospaced)
        public static let commandBar = Font.system(size: 16, weight: .regular, design: .default)
        public static let tabTitle = Font.system(size: 12, weight: .medium, design: .default)
        public static let shortcut = Font.system(size: 10, weight: .medium, design: .rounded)
        public static let statusBar = Font.system(size: 10.5, weight: .medium, design: .default)
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
        public static let xxxxl: CGFloat = 48
    }

    // MARK: - Corner Radius
    public enum Radius {
        public static let sm: CGFloat = 4
        public static let md: CGFloat = 6
        public static let lg: CGFloat = 8
        public static let xl: CGFloat = 12
        public static let xxl: CGFloat = 16
        public static let full: CGFloat = 100
    }

    // MARK: - Sizes
    public enum Sizes {
        public static let toolbarHeight: CGFloat = 48
        public static let tabBarHeight: CGFloat = 38
        public static let sidebarWidth: CGFloat = 260
        public static let sidebarCollapsedWidth: CGFloat = 0
        public static let commandBarHeight: CGFloat = 52
        public static let commandBarWidth: CGFloat = 640
        public static let minPanelWidth: CGFloat = 300
        public static let minPanelHeight: CGFloat = 200
        public static let findBarHeight: CGFloat = 42
        public static let statusBarHeight: CGFloat = 26
        public static let aiSidebarWidth: CGFloat = 360
        public static let toastWidth: CGFloat = 320
        public static let iconButtonSize: CGFloat = 32
    }

    // MARK: - Animation
    public enum Animation {
        public static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        public static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        public static let slow = SwiftUI.Animation.easeInOut(duration: 0.4)
        public static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.82)
        public static let bouncy = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.68)
        public static let gentle = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.85)
        public static let snappy = SwiftUI.Animation.spring(response: 0.22, dampingFraction: 0.78)
    }

    // MARK: - Shadows
    public enum Shadows {
        public static func subtle(radius: CGFloat = 4) -> some View {
            Color.clear
                .shadow(color: AetherTheme.Colors.shadowSubtle, radius: radius, x: 0, y: 1)
        }

        public static func medium(radius: CGFloat = 12) -> some View {
            Color.clear
                .shadow(color: AetherTheme.Colors.shadowColor, radius: radius, x: 0, y: 4)
        }

        public static func elevated(radius: CGFloat = 24) -> some View {
            Color.clear
                .shadow(color: AetherTheme.Colors.shadowDeep, radius: radius, x: 0, y: 8)
        }
    }
}
