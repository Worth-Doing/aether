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
    let onCommandBar: () -> Void
    let onBookmark: () -> Void
    let onAIAssist: () -> Void

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

            // Navigation buttons
            HStack(spacing: AetherTheme.Spacing.xs) {
                GlassIconButton(
                    icon: "chevron.left",
                    color: coordinator?.canGoBack == true
                        ? AetherTheme.Colors.textSecondary
                        : AetherTheme.Colors.textTertiary
                ) {
                    coordinator?.goBack()
                }
                .disabled(!(coordinator?.canGoBack ?? false))

                GlassIconButton(
                    icon: "chevron.right",
                    color: coordinator?.canGoForward == true
                        ? AetherTheme.Colors.textSecondary
                        : AetherTheme.Colors.textTertiary
                ) {
                    coordinator?.goForward()
                }
                .disabled(!(coordinator?.canGoForward ?? false))

                GlassIconButton(
                    icon: coordinator?.isLoading == true ? "xmark" : "arrow.clockwise"
                ) {
                    if coordinator?.isLoading == true {
                        coordinator?.stopLoading()
                    } else {
                        coordinator?.reload()
                    }
                }
            }

            // Address bar — glass style
            HStack(spacing: AetherTheme.Spacing.md) {
                if coordinator?.isLoading == true {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 14, height: 14)
                } else if let url = tabStore.activeTab?.url {
                    Image(systemName: url.scheme == "https" ? "lock.fill" : "globe")
                        .foregroundColor(url.scheme == "https"
                            ? AetherTheme.Colors.success
                            : AetherTheme.Colors.textTertiary
                        )
                        .font(.system(size: 11))
                } else {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                        .font(.system(size: 12))
                }

                TextField("Search or enter URL", text: $addressText)
                    .textFieldStyle(.plain)
                    .font(AetherTheme.Typography.body)
                    .foregroundColor(AetherTheme.Colors.textPrimary)
                    .onSubmit {
                        tabStore.navigate(to: addressText)
                    }
            }
            .padding(.horizontal, AetherTheme.Spacing.lg)
            .padding(.vertical, AetherTheme.Spacing.md - 1)
            .background(
                ZStack {
                    VisualEffectBlur(material: .popover)
                    AetherTheme.Colors.glassSurface.opacity(0.4)
                }
                .clipShape(RoundedRectangle(cornerRadius: AetherTheme.Radius.lg, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.lg, style: .continuous)
                    .strokeBorder(
                        isAddressFocused
                            ? AetherTheme.Colors.accent.opacity(0.5)
                            : AetherTheme.Colors.glassBorderSubtle,
                        lineWidth: isAddressFocused ? 1.5 : 0.5
                    )
            )
            .shadow(color: AetherTheme.Colors.shadowSubtle, radius: 4, x: 0, y: 1)

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
                            .font(AetherTheme.Typography.shortcut)
                            .foregroundColor(AetherTheme.Colors.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AetherTheme.Colors.glassSurface)
                            .cornerRadius(AetherTheme.Radius.sm)
                    }
                    .buttonStyle(.plain)
                }

                GlassIconButton(
                    icon: isCurrentPageBookmarked ? "bookmark.fill" : "bookmark",
                    color: isCurrentPageBookmarked ? AetherTheme.Colors.accent : AetherTheme.Colors.textSecondary
                ) {
                    onBookmark()
                }

                GlassIconButton(icon: "sparkles") {
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
        .glassToolbar()
        .overlay(alignment: .bottom) {
            if let coord = coordinator, coord.isLoading {
                GeometryReader { geo in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AetherTheme.Colors.accent, AetherTheme.Colors.accent.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * coord.estimatedProgress, height: 2.5)
                        .shadow(color: AetherTheme.Colors.accentGlow, radius: 4, y: 0)
                        .animation(AetherTheme.Animation.spring, value: coord.estimatedProgress)
                }
                .frame(height: 2.5)
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

    private var isCurrentPageBookmarked: Bool {
        guard tabStore.activeTab?.url != nil else { return false }
        return false
    }
}
