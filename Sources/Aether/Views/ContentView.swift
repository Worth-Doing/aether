import SwiftUI
import AetherCore
import AetherUI
import TabManager
import PanelSystem
import HistoryEngine
import BookmarkEngine
import CommandBar
import AIService
import SemanticEngine
import Settings

struct ContentView: View {
    @Bindable var tabStore: TabStore
    @Bindable var workspaceManager: WorkspaceManager
    @Bindable var historyManager: HistoryManager
    @Bindable var bookmarkManager: BookmarkManager
    @Bindable var commandBarState: CommandBarState
    let openRouterClient: OpenRouterClient
    let semanticIndex: SemanticIndex?

    @State private var showSidebar: Bool = true
    @State private var showSettings: Bool = false
    @State private var aiAssistState = AIAssistState()
    @State private var showFindBar: Bool = false
    @State private var findQuery: String = ""
    @AppStorage(AppConstants.UserDefaultsKeys.showStatusBar) private var showStatusBar = true

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Toolbar
                ToolbarView(
                    tabStore: tabStore,
                    showSidebar: $showSidebar,
                    onCommandBar: { commandBarState.show() },
                    onBookmark: { bookmarkCurrentPage() },
                    onAIAssist: { aiAssistState.isVisible.toggle() }
                )

                Divider()
                    .background(AetherTheme.Colors.border)

                // Find bar
                if showFindBar {
                    FindBarView(
                        query: $findQuery,
                        onFind: { forward in
                            if let tabId = tabStore.activeTab?.id,
                               let coord = tabStore.coordinator(for: tabId) {
                                coord.findInPage(findQuery, forward: forward)
                            }
                        },
                        onDismiss: {
                            showFindBar = false
                            findQuery = ""
                            if let tabId = tabStore.activeTab?.id,
                               let coord = tabStore.coordinator(for: tabId) {
                                coord.clearFindHighlights()
                            }
                        }
                    )

                    Divider()
                        .background(AetherTheme.Colors.border)
                }

                // Main content area
                HStack(spacing: 0) {
                    if showSidebar {
                        SidebarView(
                            workspaceManager: workspaceManager,
                            historyManager: historyManager,
                            bookmarkManager: bookmarkManager,
                            onNavigate: { url in
                                tabStore.navigate(to: url)
                            }
                        )
                        .transition(.move(edge: .leading).combined(with: .opacity))

                        Divider()
                            .background(AetherTheme.Colors.border)
                    }

                    // Panel layout
                    PanelLayoutView(
                        tabStore: tabStore,
                        layout: workspaceManager.currentWorkspace.panelLayout
                    )

                    // AI Assist sidebar
                    if aiAssistState.isVisible {
                        Divider()
                            .background(AetherTheme.Colors.border)

                        AIAssistView(
                            state: aiAssistState,
                            openRouterClient: openRouterClient,
                            tabStore: tabStore
                        )
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }

                // Status bar
                if showStatusBar {
                    StatusBarView(tabStore: tabStore)
                }
            }
            .background(AetherTheme.Colors.background)
            .animation(AetherTheme.Animation.fast, value: showSidebar)
            .animation(AetherTheme.Animation.fast, value: aiAssistState.isVisible)
            .animation(AetherTheme.Animation.fast, value: showFindBar)

            // Command bar overlay
            if commandBarState.isVisible {
                AetherTheme.Colors.overlayBackground
                    .ignoresSafeArea()
                    .onTapGesture {
                        commandBarState.hide()
                    }

                VStack {
                    Spacer()
                        .frame(height: 100)

                    CommandBarView(
                        state: commandBarState,
                        tabStore: tabStore,
                        historyManager: historyManager,
                        bookmarkManager: bookmarkManager,
                        onNavigate: { url in
                            tabStore.navigate(to: url)
                        },
                        onSelectTab: { tabId, panelId in
                            tabStore.selectTab(tabId, inPanel: panelId)
                        },
                        onSplitH: {
                            if let panelId = tabStore.activePanelId {
                                workspaceManager.splitPanel(panelId, axis: .horizontal)
                            }
                        },
                        onSplitV: {
                            if let panelId = tabStore.activePanelId {
                                workspaceManager.splitPanel(panelId, axis: .vertical)
                            }
                        },
                        onShowSettings: {
                            showSettings = true
                        },
                        onToggleFindBar: {
                            showFindBar.toggle()
                        },
                        workspaceManager: workspaceManager
                    )

                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                openRouterClient: openRouterClient,
                historyManager: historyManager,
                bookmarkManager: bookmarkManager
            )
        }
        .background(
            KeyboardShortcutHandler(
                onNewTab: { _ = tabStore.createTab() },
                onCloseTab: {
                    if let tabId = tabStore.activeTab?.id {
                        tabStore.closeTab(tabId)
                    }
                },
                onReopenTab: { tabStore.reopenLastClosedTab() },
                onCommandBar: { commandBarState.show() },
                onToggleSidebar: {
                    withAnimation(AetherTheme.Animation.fast) {
                        showSidebar.toggle()
                    }
                },
                onSplitH: {
                    if let panelId = tabStore.activePanelId {
                        workspaceManager.splitPanel(panelId, axis: .horizontal)
                    }
                },
                onSplitV: {
                    if let panelId = tabStore.activePanelId {
                        workspaceManager.splitPanel(panelId, axis: .vertical)
                    }
                },
                onSettings: { showSettings = true },
                onBookmark: { bookmarkCurrentPage() },
                onFind: { showFindBar.toggle() },
                onZoomIn: {
                    if let tabId = tabStore.activeTab?.id,
                       let coord = tabStore.coordinator(for: tabId) {
                        coord.zoomIn()
                    }
                },
                onZoomOut: {
                    if let tabId = tabStore.activeTab?.id,
                       let coord = tabStore.coordinator(for: tabId) {
                        coord.zoomOut()
                    }
                },
                onZoomReset: {
                    if let tabId = tabStore.activeTab?.id,
                       let coord = tabStore.coordinator(for: tabId) {
                        coord.zoomReset()
                    }
                },
                commandBarVisible: commandBarState.isVisible,
                onCommandBarUp: { commandBarState.moveUp() },
                onCommandBarDown: { commandBarState.moveDown() },
                onCommandBarDismiss: { commandBarState.hide() }
            )
        )
        .onReceive(NotificationCenter.default.publisher(for: .toggleFindBar)) { _ in
            showFindBar.toggle()
        }
    }

    private func bookmarkCurrentPage() {
        guard let tab = tabStore.activeTab,
              let url = tab.url?.absoluteString else { return }
        if bookmarkManager.isBookmarked(url: url) {
            if let existing = bookmarkManager.bookmarks.first(where: { $0.url == url }) {
                bookmarkManager.removeBookmark(existing.id)
            }
        } else {
            bookmarkManager.addBookmark(url: url, title: tab.title)
        }
    }
}

// MARK: - Find Bar

struct FindBarView: View {
    @Binding var query: String
    let onFind: (Bool) -> Void
    let onDismiss: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: AetherTheme.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AetherTheme.Colors.textTertiary)
                .font(.system(size: 12))

            TextField("Find in page...", text: $query)
                .textFieldStyle(.plain)
                .font(AetherTheme.Typography.body)
                .foregroundColor(AetherTheme.Colors.textPrimary)
                .focused($isFocused)
                .onSubmit { onFind(true) }

            HStack(spacing: AetherTheme.Spacing.xs) {
                Button { onFind(false) } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AetherTheme.Colors.textSecondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)

                Button { onFind(true) } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AetherTheme.Colors.textSecondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)

                Divider()
                    .frame(height: 16)

                Button { onDismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AetherTheme.Spacing.xl)
        .padding(.vertical, AetherTheme.Spacing.sm)
        .frame(height: AetherTheme.Sizes.findBarHeight)
        .background(AetherTheme.Colors.surface)
        .onAppear { isFocused = true }
    }
}

// MARK: - Status Bar

struct StatusBarView: View {
    @Bindable var tabStore: TabStore

    var body: some View {
        HStack(spacing: AetherTheme.Spacing.lg) {
            if let tab = tabStore.activeTab {
                if tab.isLoading {
                    Text("Loading...")
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                } else if let url = tab.url {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9))
                        .foregroundColor(url.scheme == "https"
                            ? AetherTheme.Colors.success
                            : AetherTheme.Colors.textTertiary
                        )
                    Text(url.host() ?? url.absoluteString)
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                }
            }

            Spacer()

            if let tabId = tabStore.activeTab?.id,
               let coord = tabStore.coordinator(for: tabId),
               coord.currentZoom != 1.0 {
                Text("\(Int(coord.currentZoom * 100))%")
                    .foregroundColor(AetherTheme.Colors.textTertiary)
            }

            Text("\(tabStore.allTabs.count) tab\(tabStore.allTabs.count == 1 ? "" : "s")")
                .foregroundColor(AetherTheme.Colors.textTertiary)
        }
        .font(AetherTheme.Typography.caption)
        .padding(.horizontal, AetherTheme.Spacing.xl)
        .frame(height: AetherTheme.Sizes.statusBarHeight)
        .background(AetherTheme.Colors.surface)
        .overlay(alignment: .top) {
            Divider().background(AetherTheme.Colors.border)
        }
    }
}
