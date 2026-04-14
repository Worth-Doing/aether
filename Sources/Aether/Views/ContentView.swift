import SwiftUI
import AetherCore
import AetherUI
import TabManager
import PanelSystem
import HistoryEngine
import BookmarkEngine
import CommandBar
import AIService
import Settings

struct ContentView: View {
    @Bindable var tabStore: TabStore
    @Bindable var workspaceManager: WorkspaceManager
    @Bindable var historyManager: HistoryManager
    @Bindable var bookmarkManager: BookmarkManager
    @Bindable var commandBarState: CommandBarState
    let openRouterClient: OpenRouterClient
    @State private var showSidebar: Bool = true
    @State private var showSettings: Bool = false
    @State private var aiAssistState = AIAssistState()

    var body: some View {
        ZStack {
            // Main browser layout
            VStack(spacing: 0) {
                // Toolbar
                ToolbarView(
                    tabStore: tabStore,
                    onCommandBar: { commandBarState.show() },
                    onBookmark: { bookmarkCurrentPage() },
                    onAIAssist: { aiAssistState.isVisible.toggle() }
                )

                Divider()
                    .background(AetherTheme.Colors.border)

                // Main content area
                HStack(spacing: 0) {
                    // Left sidebar
                    if showSidebar {
                        SidebarView(
                            workspaceManager: workspaceManager,
                            historyManager: historyManager,
                            bookmarkManager: bookmarkManager,
                            onNavigate: { url in
                                tabStore.navigate(to: url)
                            }
                        )

                        Divider()
                            .background(AetherTheme.Colors.border)
                    }

                    // Panel layout (browser content)
                    PanelLayoutView(
                        tabStore: tabStore,
                        layout: workspaceManager.currentWorkspace.panelLayout
                    )

                    // Right sidebar — AI Assist
                    if aiAssistState.isVisible {
                        Divider()
                            .background(AetherTheme.Colors.border)

                        AIAssistView(
                            state: aiAssistState,
                            openRouterClient: openRouterClient,
                            tabStore: tabStore
                        )
                    }
                }
            }
            .background(AetherTheme.Colors.background)

            // Command bar overlay
            if commandBarState.isVisible {
                Color.black.opacity(0.3)
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
                        }
                    )

                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(openRouterClient: openRouterClient)
        }
        // Keyboard shortcuts
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
                onToggleSidebar: { showSidebar.toggle() },
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
                commandBarVisible: commandBarState.isVisible,
                onCommandBarUp: { commandBarState.moveUp() },
                onCommandBarDown: { commandBarState.moveDown() },
                onCommandBarDismiss: { commandBarState.hide() }
            )
        )
    }

    private func bookmarkCurrentPage() {
        guard let tab = tabStore.activeTab,
              let url = tab.url?.absoluteString else { return }
        if bookmarkManager.isBookmarked(url: url) {
            bookmarkManager.removeBookmark(
                bookmarkManager.bookmarks.first(where: { $0.url == url })!.id
            )
        } else {
            bookmarkManager.addBookmark(url: url, title: tab.title)
        }
    }
}
