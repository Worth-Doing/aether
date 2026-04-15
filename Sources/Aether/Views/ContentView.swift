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
    @State private var toastManager = ToastManager()
    @AppStorage(AppConstants.UserDefaultsKeys.showStatusBar) private var showStatusBar = true

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Glass toolbar
                ToolbarView(
                    tabStore: tabStore,
                    showSidebar: $showSidebar,
                    onCommandBar: { commandBarState.show() },
                    onBookmark: { bookmarkCurrentPage() },
                    onAIAssist: { aiAssistState.isVisible.toggle() }
                )

                Divider()
                    .background(AetherTheme.Colors.glassBorderSubtle)

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
                        .background(AetherTheme.Colors.glassBorderSubtle)
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
                            .background(AetherTheme.Colors.glassBorderSubtle)
                    }

                    // Panel layout
                    PanelLayoutView(
                        tabStore: tabStore,
                        layout: workspaceManager.currentWorkspace.panelLayout
                    )

                    // AI Assist sidebar
                    if aiAssistState.isVisible {
                        Divider()
                            .background(AetherTheme.Colors.glassBorderSubtle)

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
            .animation(AetherTheme.Animation.spring, value: showSidebar)
            .animation(AetherTheme.Animation.spring, value: aiAssistState.isVisible)
            .animation(AetherTheme.Animation.fast, value: showFindBar)

            // Command bar overlay — glass
            if commandBarState.isVisible {
                AetherTheme.Colors.overlayBackground
                    .ignoresSafeArea()
                    .onTapGesture {
                        commandBarState.hide()
                    }
                    .transition(.opacity)

                VStack {
                    Spacer()
                        .frame(height: 80)

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
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        // Toast overlay
        .overlay(alignment: .bottom) {
            if let toast = toastManager.currentToast {
                ToastOverlay(toast: toast)
                    .padding(.bottom, showStatusBar ? AetherTheme.Sizes.statusBarHeight + 12 : 16)
            }
        }
        .animation(AetherTheme.Animation.spring, value: toastManager.currentToast?.id)
        .animation(AetherTheme.Animation.spring, value: commandBarState.isVisible)
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
                    withAnimation(AetherTheme.Animation.spring) {
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
                toastManager.info("Bookmark removed", icon: "bookmark.slash")
            }
        } else {
            bookmarkManager.addBookmark(url: url, title: tab.title)
            toastManager.success("Bookmark added", icon: "bookmark.fill")
        }
    }
}

// MARK: - Find Bar (Glass)

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
                GlassIconButton(icon: "chevron.up", size: 11) {
                    onFind(false)
                }

                GlassIconButton(icon: "chevron.down", size: 11) {
                    onFind(true)
                }

                Divider()
                    .frame(height: 16)

                GlassIconButton(icon: "xmark", size: 10, color: AetherTheme.Colors.textTertiary) {
                    onDismiss()
                }
            }
        }
        .padding(.horizontal, AetherTheme.Spacing.xl)
        .padding(.vertical, AetherTheme.Spacing.sm)
        .frame(height: AetherTheme.Sizes.findBarHeight)
        .glassToolbar()
        .onAppear { isFocused = true }
    }
}

// MARK: - Status Bar (Glass)

struct StatusBarView: View {
    @Bindable var tabStore: TabStore

    var body: some View {
        HStack(spacing: AetherTheme.Spacing.lg) {
            if let tab = tabStore.activeTab {
                if tab.isLoading {
                    ProgressView()
                        .scaleEffect(0.35)
                        .frame(width: 10, height: 10)
                    Text("Loading...")
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                } else if let url = tab.url {
                    Image(systemName: url.scheme == "https" ? "lock.fill" : "globe")
                        .font(.system(size: 8))
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
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: AetherTheme.Radius.sm, style: .continuous)
                            .fill(AetherTheme.Colors.glassSurface)
                    )
            }

            Text("\(tabStore.allTabs.count) tab\(tabStore.allTabs.count == 1 ? "" : "s")")
                .foregroundColor(AetherTheme.Colors.textTertiary)
        }
        .font(AetherTheme.Typography.statusBar)
        .padding(.horizontal, AetherTheme.Spacing.xl)
        .frame(height: AetherTheme.Sizes.statusBarHeight)
        .background(AetherTheme.Colors.background.opacity(0.8))
        .overlay(alignment: .top) {
            Divider().background(AetherTheme.Colors.glassBorderSubtle)
        }
    }
}
