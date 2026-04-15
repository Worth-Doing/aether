import SwiftUI

// MARK: - Toast Model

public struct ToastItem: Identifiable {
    public let id = UUID()
    public let message: String
    public let icon: String
    public let style: ToastStyle

    public enum ToastStyle {
        case success
        case error
        case info

        var color: Color {
            switch self {
            case .success: return AetherTheme.Colors.success
            case .error: return AetherTheme.Colors.error
            case .info: return AetherTheme.Colors.accent
            }
        }
    }

    public init(message: String, icon: String, style: ToastStyle = .info) {
        self.message = message
        self.icon = icon
        self.style = style
    }
}

// MARK: - Toast Manager

@Observable
public final class ToastManager {
    public var currentToast: ToastItem?
    private var dismissTask: Task<Void, Never>?

    public init() {}

    public func show(_ message: String, icon: String = "checkmark.circle", style: ToastItem.ToastStyle = .info) {
        dismissTask?.cancel()
        withAnimation(AetherTheme.Animation.spring) {
            currentToast = ToastItem(message: message, icon: icon, style: style)
        }
        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            if !Task.isCancelled {
                withAnimation(AetherTheme.Animation.spring) {
                    currentToast = nil
                }
            }
        }
    }

    public func success(_ message: String, icon: String = "checkmark.circle.fill") {
        show(message, icon: icon, style: .success)
    }

    public func error(_ message: String, icon: String = "exclamationmark.circle.fill") {
        show(message, icon: icon, style: .error)
    }

    public func info(_ message: String, icon: String = "info.circle.fill") {
        show(message, icon: icon, style: .info)
    }
}

// MARK: - Toast View

public struct ToastOverlay: View {
    let toast: ToastItem

    public init(toast: ToastItem) {
        self.toast = toast
    }

    public var body: some View {
        HStack(spacing: AetherTheme.Spacing.lg) {
            Image(systemName: toast.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(toast.style.color)

            Text(toast.message)
                .font(AetherTheme.Typography.bodyMedium)
                .foregroundColor(AetherTheme.Colors.textPrimary)
                .lineLimit(2)
        }
        .padding(.horizontal, AetherTheme.Spacing.xl)
        .padding(.vertical, AetherTheme.Spacing.lg)
        .background(
            ZStack {
                VisualEffectBlur(material: .popover)
                AetherTheme.Colors.glassBackground.opacity(0.6)
            }
            .clipShape(Capsule())
        )
        .overlay(
            Capsule()
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
        .shadow(color: AetherTheme.Colors.shadowColor, radius: 16, y: 6)
        .shadow(color: toast.style.color.opacity(0.15), radius: 8, y: 2)
        .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.9)))
    }
}
