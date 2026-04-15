import SwiftUI

/// A glass card component with frosted blur, subtle border, and shadow
public struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let padding: CGFloat
    let content: () -> Content

    @State private var isHovering = false

    public init(
        cornerRadius: CGFloat = AetherTheme.Radius.xl,
        padding: CGFloat = AetherTheme.Spacing.xl,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content
    }

    public var body: some View {
        content()
            .padding(padding)
            .background(
                ZStack {
                    VisualEffectBlur(material: .popover)
                    (isHovering ? AetherTheme.Colors.glassHover : AetherTheme.Colors.glassCard)
                        .opacity(0.5)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                AetherTheme.Colors.glassBorder,
                                AetherTheme.Colors.glassBorderSubtle
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: AetherTheme.Colors.shadowSubtle, radius: 8, x: 0, y: 2)
            .shadow(color: AetherTheme.Colors.shadowColor.opacity(0.3), radius: 1, x: 0, y: 0.5)
            .onHover { hovering in
                withAnimation(AetherTheme.Animation.fast) {
                    isHovering = hovering
                }
            }
    }
}

/// An icon button with glass hover effect
public struct GlassIconButton: View {
    let icon: String
    let size: CGFloat
    let color: Color
    let label: String?
    let action: () -> Void

    @State private var isHovering = false
    @State private var isPressed = false

    public init(
        icon: String,
        size: CGFloat = 13,
        color: Color = AetherTheme.Colors.textSecondary,
        label: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.color = color
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .medium))
                .foregroundColor(isHovering ? AetherTheme.Colors.textPrimary : color)
                .frame(width: AetherTheme.Sizes.iconButtonSize, height: AetherTheme.Sizes.iconButtonSize)
                .background(
                    RoundedRectangle(cornerRadius: AetherTheme.Radius.md, style: .continuous)
                        .fill(isHovering ? AetherTheme.Colors.glassHover : .clear)
                )
                .scaleEffect(isPressed ? 0.92 : 1.0)
                .accessibilityLabel(label ?? icon)
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
}

/// Modifier to detect press and release events
struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

public extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

/// A floating command bar card with glass effect and prominent shadow
public struct GlassCommandCard<Content: View>: View {
    let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        content()
            .background(
                ZStack {
                    VisualEffectBlur(material: .popover)
                    AetherTheme.Colors.glassBackground.opacity(0.5)
                }
                .clipShape(RoundedRectangle(cornerRadius: AetherTheme.Radius.xxl, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.xxl, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                AetherTheme.Colors.glassBorder,
                                AetherTheme.Colors.glassBorderSubtle
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: AetherTheme.Colors.shadowDeep, radius: 40, x: 0, y: 16)
            .shadow(color: AetherTheme.Colors.shadowColor, radius: 8, x: 0, y: 2)
    }
}
