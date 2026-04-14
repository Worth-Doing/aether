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
                        ForEach(panel.tabs) { tab in
                            TabItemView(
                                tab: tab,
                                isActive: tab.id == panel.activeTabId,
                                isFocusedPanel: panelId == tabStore.activePanelId
                            ) {
                                tabStore.selectTab(tab.id, inPanel: panelId)
                            } onClose: {
                                tabStore.closeTab(tab.id)
                            }
                        }
                    }
                }
            }

            Spacer()

            // New tab button
            Button {
                _ = tabStore.createTab(in: panelId)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AetherTheme.Colors.textTertiary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .padding(.trailing, AetherTheme.Spacing.md)
        }
        .frame(height: AetherTheme.Sizes.tabBarHeight)
        .background(AetherTheme.Colors.background)
    }
}

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

            Text(tab.title)
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
                ? (isFocusedPanel ? AetherTheme.Colors.surfaceElevated : AetherTheme.Colors.surface)
                : Color.clear
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
