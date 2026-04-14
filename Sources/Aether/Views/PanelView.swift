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
            // Tab bar for this panel
            TabBarView(tabStore: tabStore, panelId: panelId)

            Divider()
                .background(AetherTheme.Colors.border)

            // Web view content
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
        VStack(spacing: AetherTheme.Spacing.xl) {
            Image(systemName: "globe")
                .font(.system(size: 40))
                .foregroundColor(AetherTheme.Colors.textTertiary)

            Text("New Tab")
                .font(AetherTheme.Typography.heading)
                .foregroundColor(AetherTheme.Colors.textSecondary)

            Text("Type a URL or search query in the address bar")
                .font(AetherTheme.Typography.caption)
                .foregroundColor(AetherTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AetherTheme.Colors.background)
    }
}
