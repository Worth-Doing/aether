import SwiftUI
import AetherCore
import AetherUI
import TabManager
import BrowserEngine

struct PanelView: View {
    @Bindable var tabStore: TabStore
    let panelId: UUID

    var panel: Panel? {
        tabStore.panels.first { $0.id == panelId }
    }

    var body: some View {
        VStack(spacing: 0) {
            TabBarView(tabStore: tabStore, panelId: panelId)

            Divider()
                .background(AetherTheme.Colors.glassBorderSubtle)

            if let tab = panel?.activeTab,
               let coordinator = tabStore.coordinator(for: tab.id) {
                WebViewRepresentable(coordinator: coordinator)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                emptyState
            }
        }
        .background(AetherTheme.Colors.background)
        .overlay(
            RoundedRectangle(cornerRadius: AetherTheme.Radius.sm, style: .continuous)
                .strokeBorder(
                    panelId == tabStore.activePanelId
                        ? AetherTheme.Colors.accent.opacity(0.25)
                        : AetherTheme.Colors.glassBorderSubtle,
                    lineWidth: panelId == tabStore.activePanelId ? 1.5 : 0.5
                )
        )
        .onTapGesture {
            tabStore.focusPanel(panelId)
        }
    }

    private var emptyState: some View {
        VStack(spacing: AetherTheme.Spacing.xxl) {
            Spacer()

            // Glowing icon
            ZStack {
                Circle()
                    .fill(AetherTheme.Colors.accentGlow)
                    .frame(width: 80, height: 80)
                    .blur(radius: 20)

                Image(systemName: "globe.desk")
                    .font(.system(size: 42, weight: .thin))
                    .foregroundColor(AetherTheme.Colors.accent.opacity(0.6))
            }

            Text("Aether")
                .font(AetherTheme.Typography.largeTitle)
                .foregroundColor(AetherTheme.Colors.textTertiary)

            Text("Search or enter a URL to get started")
                .font(AetherTheme.Typography.body)
                .foregroundColor(AetherTheme.Colors.textTertiary)

            // Quick shortcuts — glass cards
            VStack(spacing: AetherTheme.Spacing.md) {
                shortcutRow("New Tab", key: "T")
                shortcutRow("Command Palette", key: "K")
                shortcutRow("Toggle Sidebar", key: "S")
                shortcutRow("Split Panel", key: "\\")
                shortcutRow("Find in Page", key: "F")
                shortcutRow("Bookmark Page", key: "D")
            }
            .padding(.top, AetherTheme.Spacing.lg)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AetherTheme.Colors.background)
    }

    private func shortcutRow(_ label: String, key: String) -> some View {
        HStack(spacing: AetherTheme.Spacing.lg) {
            Text(label)
                .font(AetherTheme.Typography.caption)
                .foregroundColor(AetherTheme.Colors.textTertiary)
                .frame(width: 140, alignment: .trailing)

            HStack(spacing: 2) {
                shortcutKey("Cmd")
                shortcutKey(key)
            }
        }
    }

    private func shortcutKey(_ key: String) -> some View {
        Text(key)
            .font(AetherTheme.Typography.shortcut)
            .foregroundColor(AetherTheme.Colors.textSecondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.sm, style: .continuous)
                    .fill(AetherTheme.Colors.glassSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.sm, style: .continuous)
                    .strokeBorder(AetherTheme.Colors.glassBorderSubtle, lineWidth: 0.5)
            )
    }
}
