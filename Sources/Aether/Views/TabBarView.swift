import SwiftUI
import AetherCore
import AetherUI
import TabManager

struct TabBarView: View {
    @Bindable var tabStore: TabStore
    let panelId: UUID

    var panel: Panel? {
        tabStore.panels.first { $0.id == panelId }
    }

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 1) {
                    if let panel {
                        // Pinned tabs first
                        let pinned = panel.tabs.filter { $0.isPinned }
                        let unpinned = panel.tabs.filter { !$0.isPinned }

                        ForEach(pinned) { tab in
                            PinnedTabView(
                                tab: tab,
                                isActive: tab.id == panel.activeTabId,
                                isFocusedPanel: panelId == tabStore.activePanelId
                            ) {
                                tabStore.selectTab(tab.id, inPanel: panelId)
                            }
                            .contextMenu {
                                tabContextMenu(for: tab)
                            }
                        }

                        if !pinned.isEmpty && !unpinned.isEmpty {
                            Divider()
                                .frame(height: 20)
                                .padding(.horizontal, 2)
                        }

                        ForEach(unpinned) { tab in
                            TabItemView(
                                tab: tab,
                                isActive: tab.id == panel.activeTabId,
                                isFocusedPanel: panelId == tabStore.activePanelId
                            ) {
                                tabStore.selectTab(tab.id, inPanel: panelId)
                            } onClose: {
                                tabStore.closeTab(tab.id)
                            }
                            .contextMenu {
                                tabContextMenu(for: tab)
                            }
                        }
                    }
                }
            }

            Spacer()

            Button {
                _ = tabStore.createTab(in: panelId)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AetherTheme.Colors.textTertiary)
                    .frame(width: 26, height: 26)
                    .background(AetherTheme.Colors.surfaceHover.opacity(0.01))
                    .cornerRadius(AetherTheme.Radius.sm)
            }
            .buttonStyle(.plain)
            .padding(.trailing, AetherTheme.Spacing.md)
        }
        .frame(height: AetherTheme.Sizes.tabBarHeight)
        .background(AetherTheme.Colors.background)
    }

    @ViewBuilder
    private func tabContextMenu(for tab: AetherCore.Tab) -> some View {
        if tab.isPinned {
            Button("Unpin Tab") {
                tab.isPinned = false
            }
        } else {
            Button("Pin Tab") {
                tab.isPinned = true
            }
        }

        Divider()

        Button("Duplicate Tab") {
            let newTab = tabStore.createTab(in: panelId, url: tab.url)
            _ = newTab
        }

        Button("Reload") {
            if let coord = tabStore.coordinator(for: tab.id) {
                coord.reload()
            }
        }

        Divider()

        if let url = tab.url {
            Button("Copy URL") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(url.absoluteString, forType: .string)
            }
        }

        Divider()

        Button("Close Other Tabs") {
            if let panel = panel {
                let otherTabs = panel.tabs.filter { $0.id != tab.id && !$0.isPinned }
                for t in otherTabs {
                    tabStore.closeTab(t.id)
                }
            }
        }

        Button("Close Tab", role: .destructive) {
            tabStore.closeTab(tab.id)
        }
        .disabled(tab.isPinned)
    }
}

// MARK: - Pinned Tab

struct PinnedTabView: View {
    let tab: AetherCore.Tab
    let isActive: Bool
    let isFocusedPanel: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Group {
                if tab.isLoading {
                    ProgressView()
                        .scaleEffect(0.4)
                        .frame(width: 14, height: 14)
                } else if let favicon = tab.favicon {
                    Image(nsImage: favicon)
                        .resizable()
                        .frame(width: 14, height: 14)
                } else {
                    Image(systemName: "globe")
                        .font(.system(size: 11))
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                }
            }
            .frame(width: 32, height: 28)
            .background(
                isActive
                    ? (isFocusedPanel ? AetherTheme.Colors.tabActive : AetherTheme.Colors.surface)
                    : Color.clear
            )
            .cornerRadius(AetherTheme.Radius.sm)
        }
        .buttonStyle(.plain)
        .help(tab.displayTitle)
    }
}

// MARK: - Tab Item

struct TabItemView: View {
    let tab: AetherCore.Tab
    let isActive: Bool
    let isFocusedPanel: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: AetherTheme.Spacing.sm) {
            if tab.isLoading {
                ProgressView()
                    .scaleEffect(0.4)
                    .frame(width: 14, height: 14)
            } else if let favicon = tab.favicon {
                Image(nsImage: favicon)
                    .resizable()
                    .frame(width: 14, height: 14)
            } else {
                Image(systemName: "globe")
                    .font(.system(size: 10))
                    .foregroundColor(AetherTheme.Colors.textTertiary)
                    .frame(width: 14, height: 14)
            }

            Text(tab.displayTitle)
                .font(AetherTheme.Typography.tabTitle)
                .foregroundColor(
                    isActive && isFocusedPanel
                        ? AetherTheme.Colors.textPrimary
                        : AetherTheme.Colors.textSecondary
                )
                .lineLimit(1)

            if isHovering || isActive {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                        .frame(width: 16, height: 16)
                        .background(
                            isHovering
                                ? AetherTheme.Colors.surfaceHover
                                : Color.clear
                        )
                        .cornerRadius(AetherTheme.Radius.sm)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AetherTheme.Spacing.lg)
        .padding(.vertical, AetherTheme.Spacing.sm)
        .frame(maxWidth: 200)
        .background(
            isActive
                ? (isFocusedPanel ? AetherTheme.Colors.tabActive : AetherTheme.Colors.surface)
                : (isHovering ? AetherTheme.Colors.surfaceHover.opacity(0.5) : Color.clear)
        )
        .cornerRadius(AetherTheme.Radius.sm)
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            onSelect()
        }
    }
}
