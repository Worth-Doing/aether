import SwiftUI

public struct AetherButton: View {
    let title: String
    let style: Style
    let action: () -> Void

    @State private var isHovering = false

    public enum Style {
        case primary
        case secondary
        case ghost
    }

    public init(_ title: String, style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(AetherTheme.Typography.bodyMedium)
                .foregroundColor(foregroundColor)
                .padding(.horizontal, AetherTheme.Spacing.xl)
                .padding(.vertical, AetherTheme.Spacing.md)
                .background(isHovering ? hoverBackgroundColor : backgroundColor)
                .cornerRadius(AetherTheme.Radius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AetherTheme.Radius.md)
                        .strokeBorder(borderColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return AetherTheme.Colors.textPrimary
        case .ghost: return AetherTheme.Colors.textSecondary
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return AetherTheme.Colors.accent
        case .secondary: return AetherTheme.Colors.surfaceElevated
        case .ghost: return .clear
        }
    }

    private var hoverBackgroundColor: Color {
        switch style {
        case .primary: return AetherTheme.Colors.accent.opacity(0.85)
        case .secondary: return AetherTheme.Colors.surfaceHover
        case .ghost: return AetherTheme.Colors.surfaceHover
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary: return .clear
        case .secondary: return AetherTheme.Colors.border
        case .ghost: return .clear
        }
    }
}
