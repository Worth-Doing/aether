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
                                .frame(height: 18)
                                .padding(.horizontal, 3)
                                .opacity(0.5)
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
                .padding(.leading, AetherTheme.Spacing.sm)
                .padding(.vertical, AetherTheme.Spacing.xs)
            }

            Spacer()

            // New tab button
            Button {
                _ = tabStore.createTab(in: panelId)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AetherTheme.Colors.textTertiary)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: AetherTheme.Radius.sm, style: .continuous)
                            .fill(AetherTheme.Colors.glassSurface.opacity(0.01))
                    )
            }
            .buttonStyle(.plain)
            .padding(.trailing, AetherTheme.Spacing.md)
        }
        .frame(height: AetherTheme.Sizes.tabBarHeight)
        .background(
            ZStack {
                AetherTheme.Colors.background.opacity(0.5)
                AetherTheme.Colors.surfaceElevated.opacity(0.15)
            }
        )
    }

    @ViewBuilder
    private func tabContextMenu(for tab: AetherCore.Tab) -> some View {
        if tab.isPinned {
            Button("Unpin Tab") { tab.isPinned = false }
        } else {
            Button("Pin Tab") { tab.isPinned = true }
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

    @State private var isHovering = false

    var body: some View {
        Button(action: onSelect) {
            Group {
                if tab.isLoading {
                    ProgressView()
                        .scaleEffect(0.35)
                        .frame(width: 14, height: 14)
                } else if let favicon = tab.favicon {
                    Image(nsImage: favicon)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 14, height: 14)
                } else {
                    Image(systemName: "globe")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                }
            }
            .frame(width: 32, height: 26)
            .background(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.md, style: .continuous)
                    .fill(
                        isActive
                            ? AetherTheme.Colors.glassActive
                            : (isHovering ? AetherTheme.Colors.glassHover : Color.clear)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.md, style: .continuous)
                    .strokeBorder(
                        isActive ? AetherTheme.Colors.glassBorder : .clear,
                        lineWidth: 0.5
                    )
            )
            .shadow(color: isActive ? AetherTheme.Colors.shadowSubtle : .clear, radius: 3, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .help(tab.displayTitle)
        .onHover { hovering in
            withAnimation(AetherTheme.Animation.fast) {
                isHovering = hovering
            }
        }
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
    @State private var isCloseHovering = false

    var body: some View {
        HStack(spacing: AetherTheme.Spacing.sm) {
            // Favicon / loading
            Group {
                if tab.isLoading {
                    ProgressView()
                        .scaleEffect(0.35)
                        .frame(width: 13, height: 13)
                } else if let favicon = tab.favicon {
                    Image(nsImage: favicon)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 13, height: 13)
                } else {
                    Image(systemName: "globe")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                        .frame(width: 13, height: 13)
                }
            }

            // Title
            Text(tab.displayTitle)
                .font(.system(size: 11.5, weight: isActive ? .semibold : .medium))
                .foregroundColor(
                    isActive && isFocusedPanel
                        ? AetherTheme.Colors.textPrimary
                        : AetherTheme.Colors.textSecondary
                )
                .lineLimit(1)

            // Close button
            if isHovering || isActive {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(isCloseHovering ? AetherTheme.Colors.textPrimary : AetherTheme.Colors.textTertiary)
                        .frame(width: 14, height: 14)
                        .background(
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(isCloseHovering ? AetherTheme.Colors.error.opacity(0.15) : .clear)
                        )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(AetherTheme.Animation.fast) { isCloseHovering = hovering }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.horizontal, AetherTheme.Spacing.lg)
        .padding(.vertical, AetherTheme.Spacing.sm)
        .frame(maxWidth: 180)
        .background(
            RoundedRectangle(cornerRadius: AetherTheme.Radius.md, style: .continuous)
                .fill(
                    isActive
                        ? AetherTheme.Colors.glassActive
                        : (isHovering ? AetherTheme.Colors.glassHover : Color.clear)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AetherTheme.Radius.md, style: .continuous)
                .strokeBorder(
                    isActive ? AetherTheme.Colors.glassBorder : .clear,
                    lineWidth: 0.5
                )
        )
        .shadow(color: isActive ? AetherTheme.Colors.shadowSubtle : .clear, radius: 3, x: 0, y: 1)
        .onHover { hovering in
            withAnimation(AetherTheme.Animation.fast) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            onSelect()
        }
        .animation(AetherTheme.Animation.fast, value: isHovering)
    }
}
