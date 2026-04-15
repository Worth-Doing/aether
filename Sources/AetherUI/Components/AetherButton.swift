import SwiftUI

public struct AetherButton: View {
    let title: String
    let style: Style
    let icon: String?
    let action: () -> Void

    @State private var isHovering = false
    @State private var isPressed = false

    public enum Style {
        case primary
        case secondary
        case ghost
        case glass
    }

    public init(
        _ title: String,
        style: Style = .primary,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: AetherTheme.Spacing.md) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                }
                Text(title)
                    .font(AetherTheme.Typography.bodyMedium)
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, AetherTheme.Spacing.xl)
            .padding(.vertical, AetherTheme.Spacing.md)
            .background(
                Group {
                    if style == .glass {
                        ZStack {
                            VisualEffectBlur(material: .popover)
                            (isHovering ? AetherTheme.Colors.glassHover : AetherTheme.Colors.glassSurface)
                                .opacity(0.6)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: AetherTheme.Radius.lg, style: .continuous))
                    } else {
                        RoundedRectangle(cornerRadius: AetherTheme.Radius.lg, style: .continuous)
                            .fill(isHovering ? hoverBackgroundColor : backgroundColor)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.lg, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: style == .glass ? 0.5 : 1)
            )
            .shadow(
                color: style == .primary
                    ? AetherTheme.Colors.accentGlow
                    : .clear,
                radius: isHovering ? 8 : 0,
                y: isHovering ? 2 : 0
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(AetherTheme.Animation.fast) {
                isHovering = hovering
            }
        }
        .pressEvents {
            withAnimation(AetherTheme.Animation.snappy) { isPressed = true }
        } onRelease: {
            withAnimation(AetherTheme.Animation.snappy) { isPressed = false }
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return AetherTheme.Colors.textPrimary
        case .ghost: return AetherTheme.Colors.textSecondary
        case .glass: return AetherTheme.Colors.textPrimary
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return AetherTheme.Colors.accent
        case .secondary: return AetherTheme.Colors.surfaceElevated
        case .ghost: return .clear
        case .glass: return .clear
        }
    }

    private var hoverBackgroundColor: Color {
        switch style {
        case .primary: return AetherTheme.Colors.accent.opacity(0.85)
        case .secondary: return AetherTheme.Colors.surfaceHover
        case .ghost: return AetherTheme.Colors.surfaceHover
        case .glass: return .clear
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary: return .clear
        case .secondary: return AetherTheme.Colors.border
        case .ghost: return .clear
        case .glass: return AetherTheme.Colors.glassBorder
        }
    }
}
