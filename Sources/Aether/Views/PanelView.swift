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
                .background(AetherTheme.Colors.border)

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
            RoundedRectangle(cornerRadius: 0)
                .strokeBorder(
                    panelId == tabStore.activePanelId
                        ? AetherTheme.Colors.accent.opacity(0.3)
                        : AetherTheme.Colors.border,
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

            Image(systemName: "globe.desk")
                .font(.system(size: 48))
                .foregroundColor(AetherTheme.Colors.accent.opacity(0.4))

            Text("Aether")
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundColor(AetherTheme.Colors.textTertiary)

            Text("Search or enter a URL to get started")
                .font(AetherTheme.Typography.body)
                .foregroundColor(AetherTheme.Colors.textTertiary)

            // Quick shortcuts
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
            .background(AetherTheme.Colors.surfaceElevated)
            .cornerRadius(AetherTheme.Radius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.sm)
                    .strokeBorder(AetherTheme.Colors.border, lineWidth: 0.5)
            )
    }
}
