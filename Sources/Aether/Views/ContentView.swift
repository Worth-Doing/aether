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
import SecureStorage
import WebSearchService

struct ContentView: View {
    @Bindable var tabStore: TabStore
    @Bindable var workspaceManager: WorkspaceManager
    @Bindable var historyManager: HistoryManager
    @Bindable var bookmarkManager: BookmarkManager
    @Bindable var commandBarState: CommandBarState
    let openRouterClient: OpenRouterClient
    let semanticIndex: SemanticIndex?
    @Bindable var searchManager: SearchManager
    let keychain: KeychainManager

    @State private var showSidebar: Bool = true
    @State private var showSettings: Bool = false
    @State private var showWebSearch: Bool = false
    @State private var showDownloads: Bool = false
    @State private var showQuickNotes: Bool = false
    @State private var showReadingMode: Bool = false
    @State private var readingModeContent: String = ""
    @State private var readingModeTitle: String = ""
    @State private var readingModeURL: URL?
    @State private var aiAssistState = AIAssistState()
    @State private var showFindBar: Bool = false
    @State private var findQuery: String = ""
    @State private var toastManager = ToastManager()
    @State private var downloadManager = DownloadManager()
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
                    onAIAssist: {
                        withAnimation(AetherTheme.Animation.spring) {
                            aiAssistState.isVisible.toggle()
                            if aiAssistState.isVisible { showQuickNotes = false }
                        }
                    },
                    onWebSearch: {
                        withAnimation(AetherTheme.Animation.spring) {
                            showWebSearch.toggle()
                        }
                    }
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

                    // Main view switching
                    if showReadingMode {
                        ReadingModeView(
                            title: readingModeTitle,
                            url: readingModeURL,
                            content: readingModeContent,
                            onDismiss: {
                                withAnimation(AetherTheme.Animation.spring) {
                                    showReadingMode = false
                                }
                            }
                        )
                        .transition(.opacity)
                    } else if showWebSearch {
                        WebSearchView(
                            searchManager: searchManager,
                            tabStore: tabStore,
                            onNavigate: { url in
                                tabStore.navigate(to: url)
                                withAnimation(AetherTheme.Animation.spring) {
                                    showWebSearch = false
                                }
                            },
                            onDismiss: {
                                withAnimation(AetherTheme.Animation.spring) {
                                    showWebSearch = false
                                }
                            }
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    } else {
                        PanelLayoutView(
                            tabStore: tabStore,
                            layout: workspaceManager.currentWorkspace.panelLayout,
                            searchManager: searchManager,
                            historyManager: historyManager,
                            bookmarkManager: bookmarkManager,
                            onShowSettings: { showSettings = true },
                            onShowWebSearch: {
                                withAnimation(AetherTheme.Animation.spring) {
                                    showWebSearch = true
                                }
                            }
                        )
                    }

                    // Right sidebars
                    if aiAssistState.isVisible {
                        Divider().background(AetherTheme.Colors.glassBorderSubtle)

                        AIAssistView(
                            state: aiAssistState,
                            openRouterClient: openRouterClient,
                            tabStore: tabStore
                        )
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }

                    if showQuickNotes {
                        Divider().background(AetherTheme.Colors.glassBorderSubtle)

                        QuickNotesView(
                            tabStore: tabStore,
                            openRouterClient: openRouterClient
                        )
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }

                    if showDownloads {
                        Divider().background(AetherTheme.Colors.glassBorderSubtle)

                        DownloadManagerView(
                            downloadManager: downloadManager,
                            onDismiss: {
                                withAnimation(AetherTheme.Animation.spring) {
                                    showDownloads = false
                                }
                            }
                        )
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }

                // Status bar
                if showStatusBar {
                    StatusBarView(
                        tabStore: tabStore,
                        searchManager: searchManager,
                        downloadManager: downloadManager,
                        onToggleDownloads: {
                            withAnimation(AetherTheme.Animation.spring) {
                                showDownloads.toggle()
                            }
                        },
                        onToggleReadingMode: {
                            activateReadingMode()
                        },
                        onToggleNotes: {
                            withAnimation(AetherTheme.Animation.spring) {
                                showQuickNotes.toggle()
                                if showQuickNotes { aiAssistState.isVisible = false }
                            }
                        }
                    )
                }
            }
            .background(AetherTheme.Colors.background)
            .animation(AetherTheme.Animation.spring, value: showSidebar)
            .animation(AetherTheme.Animation.spring, value: aiAssistState.isVisible)
            .animation(AetherTheme.Animation.fast, value: showFindBar)
            .animation(AetherTheme.Animation.spring, value: showWebSearch)
            .animation(AetherTheme.Animation.spring, value: showDownloads)
            .animation(AetherTheme.Animation.spring, value: showQuickNotes)
            .animation(AetherTheme.Animation.spring, value: showReadingMode)

            // Command bar overlay
            if commandBarState.isVisible {
                AetherTheme.Colors.overlayBackground
                    .ignoresSafeArea()
                    .onTapGesture { commandBarState.hide() }
                    .transition(.opacity)

                VStack {
                    Spacer().frame(height: 80)

                    CommandBarView(
                        state: commandBarState,
                        tabStore: tabStore,
                        historyManager: historyManager,
                        bookmarkManager: bookmarkManager,
                        onNavigate: { url in tabStore.navigate(to: url) },
                        onSelectTab: { tabId, panelId in tabStore.selectTab(tabId, inPanel: panelId) },
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
                        onShowSettings: { showSettings = true },
                        onToggleFindBar: { showFindBar.toggle() },
                        workspaceManager: workspaceManager
                    )

                    Spacer()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        // Toast
        .overlay(alignment: .bottom) {
            if let toast = toastManager.currentToast {
                ToastOverlay(toast: toast)
                    .padding(.bottom, showStatusBar ? AetherTheme.Sizes.statusBarHeight + 12 : 16)
            }
        }
        .animation(AetherTheme.Animation.spring, value: toastManager.currentToast?.id)
        .animation(AetherTheme.Animation.spring, value: commandBarState.isVisible)
        .sheet(isPresented: $showSettings) {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Done") { showSettings = false }
                        .keyboardShortcut(.cancelAction)
                        .padding(AetherTheme.Spacing.lg)
                }
                SettingsView(
                    openRouterClient: openRouterClient,
                    searchManager: searchManager,
                    keychain: keychain,
                    historyManager: historyManager,
                    bookmarkManager: bookmarkManager
                )
            }
        }
        .background(
            KeyboardShortcutHandler(
                onNewTab: { _ = tabStore.createTab() },
                onCloseTab: {
                    if let tabId = tabStore.activeTab?.id { tabStore.closeTab(tabId) }
                },
                onReopenTab: { tabStore.reopenLastClosedTab() },
                onCommandBar: { commandBarState.show() },
                onToggleSidebar: {
                    withAnimation(AetherTheme.Animation.spring) { showSidebar.toggle() }
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
                       let coord = tabStore.coordinator(for: tabId) { coord.zoomIn() }
                },
                onZoomOut: {
                    if let tabId = tabStore.activeTab?.id,
                       let coord = tabStore.coordinator(for: tabId) { coord.zoomOut() }
                },
                onZoomReset: {
                    if let tabId = tabStore.activeTab?.id,
                       let coord = tabStore.coordinator(for: tabId) { coord.zoomReset() }
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

    // MARK: - Actions

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

    private func activateReadingMode() {
        guard let tabId = tabStore.activeTab?.id,
              let coordinator = tabStore.coordinator(for: tabId) else { return }

        readingModeTitle = tabStore.activeTab?.title ?? "Untitled"
        readingModeURL = tabStore.activeTab?.url

        coordinator.extractReadableContent { text in
            guard let text, !text.isEmpty else {
                toastManager.info("Could not extract readable content", icon: "doc.text")
                return
            }
            DispatchQueue.main.async {
                self.readingModeContent = text
                withAnimation(AetherTheme.Animation.spring) {
                    self.showReadingMode = true
                }
            }
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
                .font(.system(size: 11))

            TextField("Find in page...", text: $query)
                .textFieldStyle(.plain)
                .font(AetherTheme.Typography.body)
                .foregroundColor(AetherTheme.Colors.textPrimary)
                .focused($isFocused)
                .onSubmit { onFind(true) }

            HStack(spacing: AetherTheme.Spacing.xs) {
                GlassIconButton(icon: "chevron.up", size: 10) { onFind(false) }
                GlassIconButton(icon: "chevron.down", size: 10) { onFind(true) }
                Divider().frame(height: 14)
                GlassIconButton(icon: "xmark", size: 9, color: AetherTheme.Colors.textTertiary) { onDismiss() }
            }
        }
        .padding(.horizontal, AetherTheme.Spacing.xl)
        .padding(.vertical, AetherTheme.Spacing.sm)
        .frame(height: AetherTheme.Sizes.findBarHeight)
        .glassToolbar()
        .onAppear { isFocused = true }
    }
}

// MARK: - Enhanced Status Bar

struct StatusBarView: View {
    @Bindable var tabStore: TabStore
    var searchManager: SearchManager?
    @Bindable var downloadManager: DownloadManager
    let onToggleDownloads: () -> Void
    let onToggleReadingMode: () -> Void
    let onToggleNotes: () -> Void

    var body: some View {
        HStack(spacing: AetherTheme.Spacing.lg) {
            // Page info
            if let tab = tabStore.activeTab {
                if tab.isLoading {
                    ProgressView()
                        .scaleEffect(0.3)
                        .frame(width: 8, height: 8)
                    Text("Loading...")
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                } else if let url = tab.url {
                    Image(systemName: url.scheme == "https" ? "lock.fill" : "globe")
                        .font(.system(size: 7))
                        .foregroundColor(url.scheme == "https" ? AetherTheme.Colors.success : AetherTheme.Colors.textTertiary)
                    Text(url.host() ?? url.absoluteString)
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Action buttons
            HStack(spacing: AetherTheme.Spacing.md) {
                // Reading mode
                statusButton(icon: "doc.plaintext", tooltip: "Reading Mode") {
                    onToggleReadingMode()
                }

                // Quick notes
                statusButton(icon: "note.text", tooltip: "Quick Notes") {
                    onToggleNotes()
                }

                // Downloads
                ZStack(alignment: .topTrailing) {
                    statusButton(icon: "arrow.down.circle", tooltip: "Downloads") {
                        onToggleDownloads()
                    }

                    if downloadManager.hasActiveDownloads {
                        Circle()
                            .fill(AetherTheme.Colors.accent)
                            .frame(width: 6, height: 6)
                            .offset(x: 2, y: -1)
                    }
                }
            }

            // Provider indicator
            if let searchManager, !searchManager.configuredProviders.isEmpty {
                HStack(spacing: 3) {
                    Circle()
                        .fill(AetherTheme.Colors.success)
                        .frame(width: 4, height: 4)
                    Text("\(searchManager.configuredProviders.count) API\(searchManager.configuredProviders.count == 1 ? "" : "s")")
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                }
            }

            // Zoom
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

    private func statusButton(icon: String, tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AetherTheme.Colors.textTertiary)
                .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }
}
