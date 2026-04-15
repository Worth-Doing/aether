import SwiftUI
import AetherCore
import AetherUI
import TabManager
import BrowserEngine

struct ToolbarView: View {
    @Bindable var tabStore: TabStore
    @Binding var showSidebar: Bool
    @State private var addressText: String = ""
    @State private var isAddressFocused: Bool = false
    @State private var isAddressHovering: Bool = false
    let onCommandBar: () -> Void
    let onBookmark: () -> Void
    let onAIAssist: () -> Void
    let onWebSearch: () -> Void

    var body: some View {
        HStack(spacing: AetherTheme.Spacing.md) {
            // Sidebar toggle
            GlassIconButton(
                icon: "sidebar.left",
                color: showSidebar ? AetherTheme.Colors.accent : AetherTheme.Colors.textSecondary
            ) {
                withAnimation(AetherTheme.Animation.spring) {
                    showSidebar.toggle()
                }
            }

            // Navigation cluster
            HStack(spacing: 1) {
                navButton(
                    icon: "chevron.left",
                    enabled: coordinator?.canGoBack == true
                ) {
                    coordinator?.goBack()
                }

                navButton(
                    icon: "chevron.right",
                    enabled: coordinator?.canGoForward == true
                ) {
                    coordinator?.goForward()
                }

                navButton(
                    icon: coordinator?.isLoading == true ? "xmark" : "arrow.clockwise",
                    enabled: true
                ) {
                    if coordinator?.isLoading == true {
                        coordinator?.stopLoading()
                    } else {
                        coordinator?.reload()
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.lg, style: .continuous)
                    .fill(AetherTheme.Colors.surfaceElevated.opacity(0.4))
            )

            // Address bar — premium glass style
            HStack(spacing: AetherTheme.Spacing.md) {
                if coordinator?.isLoading == true {
                    ProgressView()
                        .scaleEffect(0.45)
                        .frame(width: 14, height: 14)
                } else if let url = tabStore.activeTab?.url {
                    Image(systemName: url.scheme == "https" ? "lock.fill" : "globe")
                        .foregroundColor(url.scheme == "https"
                            ? AetherTheme.Colors.success
                            : AetherTheme.Colors.textTertiary
                        )
                        .font(.system(size: 10, weight: .medium))
                } else {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                        .font(.system(size: 11))
                }

                TextField("Search or enter URL", text: $addressText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AetherTheme.Colors.textPrimary)
                    .onSubmit {
                        tabStore.navigate(to: addressText)
                    }

                // Web search button (visible when providers configured)
                Button(action: onWebSearch) {
                    Image(systemName: "sparkle.magnifyingglass")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AetherTheme.Colors.accent)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle().fill(AetherTheme.Colors.accentSubtle.opacity(0.6))
                        )
                }
                .buttonStyle(.plain)
                .help("AI-Powered Web Search")
            }
            .padding(.horizontal, AetherTheme.Spacing.lg)
            .padding(.vertical, AetherTheme.Spacing.md - 1)
            .background(
                ZStack {
                    VisualEffectBlur(material: .popover)
                    (isAddressHovering ? AetherTheme.Colors.glassSurface.opacity(0.55) : AetherTheme.Colors.glassSurface.opacity(0.35))
                }
                .clipShape(RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous)
                    .strokeBorder(
                        isAddressFocused
                            ? AetherTheme.Colors.accent.opacity(0.5)
                            : (isAddressHovering ? AetherTheme.Colors.glassBorder : AetherTheme.Colors.glassBorderSubtle),
                        lineWidth: isAddressFocused ? 1.5 : 0.5
                    )
            )
            .shadow(color: AetherTheme.Colors.shadowSubtle, radius: isAddressFocused ? 8 : 4, x: 0, y: 1)
            .onHover { hovering in
                withAnimation(AetherTheme.Animation.fast) { isAddressHovering = hovering }
            }

            // Right-side buttons
            HStack(spacing: AetherTheme.Spacing.xs) {
                // Zoom indicator
                if let tabId = tabStore.activeTab?.id,
                   let coord = tabStore.coordinator(for: tabId),
                   coord.currentZoom != 1.0 {
                    Button {
                        coord.zoomReset()
                    } label: {
                        Text("\(Int(coord.currentZoom * 100))%")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(AetherTheme.Colors.textSecondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(AetherTheme.Colors.surfaceElevated)
                            )
                    }
                    .buttonStyle(.plain)
                }

                GlassIconButton(
                    icon: isCurrentPageBookmarked ? "bookmark.fill" : "bookmark",
                    color: isCurrentPageBookmarked ? AetherTheme.Colors.accent : AetherTheme.Colors.textSecondary
                ) {
                    onBookmark()
                }

                GlassIconButton(icon: "sparkles", color: AetherTheme.Colors.accent) {
                    onAIAssist()
                }

                GlassIconButton(icon: "command") {
                    onCommandBar()
                }
            }
        }
        .padding(.horizontal, AetherTheme.Spacing.lg)
        .padding(.vertical, AetherTheme.Spacing.md)
        .frame(height: AetherTheme.Sizes.toolbarHeight)
        .background(
            ZStack {
                VisualEffectBlur(material: .headerView)
                LinearGradient(
                    colors: [
                        AetherTheme.Colors.toolbarGradientStart,
                        AetherTheme.Colors.toolbarGradientEnd
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.5)
            }
        )
        .overlay(alignment: .bottom) {
            if let coord = coordinator, coord.isLoading {
                GeometryReader { geo in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AetherTheme.Colors.accent,
                                    AetherTheme.Colors.accent.opacity(0.6)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * coord.estimatedProgress, height: 2)
                        .shadow(color: AetherTheme.Colors.accentGlow, radius: 6, y: 0)
                        .animation(AetherTheme.Animation.spring, value: coord.estimatedProgress)
                }
                .frame(height: 2)
            }
        }
        .onChange(of: tabStore.activeTab?.url) { _, newURL in
            addressText = newURL?.absoluteString ?? ""
        }
    }

    // MARK: - Nav Button

    private func navButton(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(enabled ? AetherTheme.Colors.textSecondary : AetherTheme.Colors.textTertiary.opacity(0.5))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private var coordinator: WebViewCoordinator? {
        guard let tabId = tabStore.activeTab?.id else { return nil }
        return tabStore.coordinator(for: tabId)
    }

    private var isCurrentPageBookmarked: Bool {
        guard tabStore.activeTab?.url != nil else { return false }
        return false
    }
}
