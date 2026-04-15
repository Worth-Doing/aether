import SwiftUI
import AppKit

/// NSVisualEffectView wrapper for frosted glass blur effects
public struct VisualEffectBlur: NSViewRepresentable {
    public let material: NSVisualEffectView.Material
    public let blendingMode: NSVisualEffectView.BlendingMode
    public let isActive: Bool

    public init(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        isActive: Bool = true
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.isActive = isActive
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = isActive ? .active : .inactive
        view.isEmphasized = true
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = isActive ? .active : .inactive
    }
}

// MARK: - Glass Modifier

public struct GlassBackgroundModifier: ViewModifier {
    let material: NSVisualEffectView.Material
    let cornerRadius: CGFloat
    let borderColor: Color
    let borderWidth: CGFloat
    let shadowRadius: CGFloat

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    VisualEffectBlur(material: material)
                    AetherTheme.Colors.glassBackground.opacity(0.3)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
            .shadow(color: AetherTheme.Colors.shadowSubtle, radius: shadowRadius, x: 0, y: 2)
    }
}

public extension View {
    func glassBackground(
        material: NSVisualEffectView.Material = .hudWindow,
        cornerRadius: CGFloat = AetherTheme.Radius.lg,
        borderColor: Color = AetherTheme.Colors.glassBorder,
        borderWidth: CGFloat = 0.5,
        shadowRadius: CGFloat = 8
    ) -> some View {
        modifier(GlassBackgroundModifier(
            material: material,
            cornerRadius: cornerRadius,
            borderColor: borderColor,
            borderWidth: borderWidth,
            shadowRadius: shadowRadius
        ))
    }

    func glassCard(cornerRadius: CGFloat = AetherTheme.Radius.xl) -> some View {
        modifier(GlassBackgroundModifier(
            material: .popover,
            cornerRadius: cornerRadius,
            borderColor: AetherTheme.Colors.glassBorder,
            borderWidth: 0.5,
            shadowRadius: 12
        ))
    }

    func glassPanel() -> some View {
        modifier(GlassBackgroundModifier(
            material: .sidebar,
            cornerRadius: 0,
            borderColor: .clear,
            borderWidth: 0,
            shadowRadius: 0
        ))
    }

    func glassToolbar() -> some View {
        modifier(GlassBackgroundModifier(
            material: .headerView,
            cornerRadius: 0,
            borderColor: .clear,
            borderWidth: 0,
            shadowRadius: 0
        ))
    }
}
