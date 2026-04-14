import SwiftUI
import AetherCore
import AetherUI
import TabManager
import BrowserEngine

struct ToolbarView: View {
    @Bindable var tabStore: TabStore
    @State private var addressText: String = ""
    let onCommandBar: () -> Void
    let onBookmark: () -> Void
    let onAIAssist: () -> Void

    var body: some View {
        HStack(spacing: AetherTheme.Spacing.md) {
            // Navigation buttons
            HStack(spacing: AetherTheme.Spacing.xs) {
                toolbarButton("chevron.left", enabled: coordinator?.canGoBack ?? false) {
                    coordinator?.goBack()
                }
                toolbarButton("chevron.right", enabled: coordinator?.canGoForward ?? false) {
                    coordinator?.goForward()
                }
                toolbarButton(
                    coordinator?.isLoading == true ? "xmark" : "arrow.clockwise",
                    enabled: true
                ) {
                    if coordinator?.isLoading == true {
                        coordinator?.stopLoading()
                    } else {
                        coordinator?.reload()
                    }
                }
            }

            // Address bar
            HStack(spacing: AetherTheme.Spacing.md) {
                if coordinator?.isLoading == true {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 14, height: 14)
                } else {
                    Image(systemName: "globe")
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                        .font(.system(size: 12))
                }

                TextField("Search or enter URL — Cmd+L", text: $addressText)
                    .textFieldStyle(.plain)
                    .font(AetherTheme.Typography.body)
                    .foregroundColor(AetherTheme.Colors.textPrimary)
                    .onSubmit {
                        tabStore.navigate(to: addressText)
                    }
            }
            .padding(.horizontal, AetherTheme.Spacing.lg)
            .padding(.vertical, AetherTheme.Spacing.sm + 2)
            .background(AetherTheme.Colors.surface)
            .cornerRadius(AetherTheme.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.md)
                    .strokeBorder(AetherTheme.Colors.border, lineWidth: 1)
            )

            // Right-side buttons
            HStack(spacing: AetherTheme.Spacing.xs) {
                toolbarButton("bookmark", enabled: true) {
                    onBookmark()
                }

                toolbarButton("sparkles", enabled: true) {
                    onAIAssist()
                }

                toolbarButton("command", enabled: true) {
                    onCommandBar()
                }
            }
        }
        .padding(.horizontal, AetherTheme.Spacing.lg)
        .padding(.vertical, AetherTheme.Spacing.sm)
        .frame(height: AetherTheme.Sizes.toolbarHeight)
        .background(AetherTheme.Colors.background)
        .overlay(alignment: .bottom) {
            if let coord = coordinator, coord.isLoading {
                GeometryReader { geo in
                    Rectangle()
                        .fill(AetherTheme.Colors.accent)
                        .frame(width: geo.size.width * coord.estimatedProgress, height: 2)
                        .animation(AetherTheme.Animation.fast, value: coord.estimatedProgress)
                }
                .frame(height: 2)
            }
        }
        .onChange(of: tabStore.activeTab?.url) { _, newURL in
            addressText = newURL?.absoluteString ?? ""
        }
    }

    private var coordinator: WebViewCoordinator? {
        guard let tabId = tabStore.activeTab?.id else { return nil }
        return tabStore.coordinator(for: tabId)
    }

    private func toolbarButton(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(enabled ? AetherTheme.Colors.textSecondary : AetherTheme.Colors.textTertiary)
                .frame(width: 28, height: 28)
                .background(AetherTheme.Colors.surface.opacity(0.01))
                .cornerRadius(AetherTheme.Radius.sm)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}
