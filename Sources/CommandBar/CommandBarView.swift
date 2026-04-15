import SwiftUI
import AetherCore
import AetherUI
import TabManager
import PanelSystem
import HistoryEngine
import BookmarkEngine

public enum CommandResult: Identifiable {
    case tab(AetherCore.Tab)
    case historyEntry(HistoryEntry)
    case bookmark(Bookmark)
    case command(name: String, icon: String, shortcut: String?, action: () -> Void)
    case url(String)

    public var id: String {
        switch self {
        case .tab(let t): return "tab-\(t.id)"
        case .historyEntry(let h): return "history-\(h.id)"
        case .bookmark(let b): return "bookmark-\(b.id)"
        case .command(let name, _, _, _): return "cmd-\(name)"
        case .url(let u): return "url-\(u)"
        }
    }

    public var title: String {
        switch self {
        case .tab(let t): return t.displayTitle
        case .historyEntry(let h): return h.title ?? h.url
        case .bookmark(let b): return b.title
        case .command(let name, _, _, _): return name
        case .url(let u): return u
        }
    }

    public var subtitle: String? {
        switch self {
        case .tab(let t): return t.url?.host()
        case .historyEntry(let h): return h.url
        case .bookmark(let b): return b.url
        case .command(_, _, let shortcut, _): return shortcut ?? "Command"
        case .url: return "Navigate or search"
        }
    }

    public var iconName: String {
        switch self {
        case .tab: return "square.on.square"
        case .historyEntry: return "clock"
        case .bookmark: return "bookmark"
        case .command(_, let icon, _, _): return icon
        case .url: return "globe"
        }
    }

    public var sectionName: String {
        switch self {
        case .tab: return "Tabs"
        case .historyEntry: return "History"
        case .bookmark: return "Bookmarks"
        case .command: return "Commands"
        case .url: return "Navigate"
        }
    }
}

@Observable
public final class CommandBarState {
    public var isVisible: Bool = false
    public var query: String = ""
    public var results: [CommandResult] = []
    public var selectedIndex: Int = 0

    public init() {}

    public func show() {
        isVisible = true
        query = ""
        results = []
        selectedIndex = 0
    }

    public func hide() {
        isVisible = false
        query = ""
        results = []
    }

    public func moveUp() {
        if selectedIndex > 0 { selectedIndex -= 1 }
    }

    public func moveDown() {
        if selectedIndex < results.count - 1 { selectedIndex += 1 }
    }
}

public struct CommandBarView: View {
    @Bindable var state: CommandBarState
    let tabStore: TabStore
    let historyManager: HistoryManager
    let bookmarkManager: BookmarkManager
    let onNavigate: (String) -> Void
    let onSelectTab: (UUID, UUID) -> Void
    let onSplitH: () -> Void
    let onSplitV: () -> Void
    var onShowSettings: (() -> Void)?
    var onToggleFindBar: (() -> Void)?
    weak var workspaceManager: WorkspaceManager?

    public init(
        state: CommandBarState,
        tabStore: TabStore,
        historyManager: HistoryManager,
        bookmarkManager: BookmarkManager,
        onNavigate: @escaping (String) -> Void,
        onSelectTab: @escaping (UUID, UUID) -> Void,
        onSplitH: @escaping () -> Void,
        onSplitV: @escaping () -> Void,
        onShowSettings: (() -> Void)? = nil,
        onToggleFindBar: (() -> Void)? = nil,
        workspaceManager: WorkspaceManager? = nil
    ) {
        self.state = state
        self.tabStore = tabStore
        self.historyManager = historyManager
        self.bookmarkManager = bookmarkManager
        self.onNavigate = onNavigate
        self.onSelectTab = onSelectTab
        self.onSplitH = onSplitH
        self.onSplitV = onSplitV
        self.onShowSettings = onShowSettings
        self.onToggleFindBar = onToggleFindBar
        self.workspaceManager = workspaceManager
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: AetherTheme.Spacing.md) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AetherTheme.Colors.textTertiary)
                    .font(.system(size: 16))

                TextField("Search tabs, history, bookmarks, or type a command...", text: $state.query)
                    .textFieldStyle(.plain)
                    .font(AetherTheme.Typography.commandBar)
                    .foregroundColor(AetherTheme.Colors.textPrimary)
                    .onSubmit { executeSelected() }
                    .onChange(of: state.query) { _, newValue in
                        updateResults(query: newValue)
                    }

                if !state.query.isEmpty {
                    Button {
                        state.query = ""
                        state.results = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AetherTheme.Colors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }

                // Escape hint
                Text("ESC")
                    .font(AetherTheme.Typography.shortcut)
                    .foregroundColor(AetherTheme.Colors.textTertiary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(AetherTheme.Colors.glassSurface)
                    .cornerRadius(AetherTheme.Radius.sm)
            }
            .padding(.horizontal, AetherTheme.Spacing.xl)
            .padding(.vertical, AetherTheme.Spacing.lg + 2)

            if !state.results.isEmpty {
                Divider()
                    .background(AetherTheme.Colors.glassBorderSubtle)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            let sections = groupResultsBySections(state.results)

                            ForEach(sections, id: \.0) { sectionName, sectionResults in
                                // Section header
                                HStack {
                                    Text(sectionName.uppercased())
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(AetherTheme.Colors.textTertiary)
                                    Spacer()
                                }
                                .padding(.horizontal, AetherTheme.Spacing.xl)
                                .padding(.top, AetherTheme.Spacing.md)
                                .padding(.bottom, AetherTheme.Spacing.xs)

                                ForEach(Array(sectionResults.enumerated()), id: \.element.id) { localIndex, result in
                                    let globalIndex = globalIndexFor(
                                        sectionName: sectionName,
                                        localIndex: localIndex,
                                        sections: sections
                                    )

                                    CommandResultRow(
                                        result: result,
                                        isSelected: globalIndex == state.selectedIndex
                                    )
                                    .id(globalIndex)
                                    .onTapGesture {
                                        state.selectedIndex = globalIndex
                                        executeSelected()
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 400)
                    .onChange(of: state.selectedIndex) { _, newIndex in
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            } else if state.query.isEmpty {
                // Quick commands when empty
                VStack(spacing: 0) {
                    Divider().background(AetherTheme.Colors.glassBorderSubtle)
                    quickCommandsView
                }
            }
        }
        .background(
            ZStack {
                VisualEffectBlur(material: .popover)
                AetherTheme.Colors.glassBackground.opacity(0.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: AetherTheme.Radius.xxl, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AetherTheme.Radius.xxl, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            AetherTheme.Colors.glassBorder,
                            AetherTheme.Colors.glassBorderSubtle
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: AetherTheme.Radius.xxl, style: .continuous))
        .shadow(color: AetherTheme.Colors.shadowDeep, radius: 40, y: 16)
        .shadow(color: AetherTheme.Colors.shadowColor, radius: 8, y: 2)
        .frame(width: AetherTheme.Sizes.commandBarWidth)
    }

    // MARK: - Quick Commands

    private var quickCommandsView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("QUICK ACTIONS")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AetherTheme.Colors.textTertiary)
                Spacer()
            }
            .padding(.horizontal, AetherTheme.Spacing.xl)
            .padding(.top, AetherTheme.Spacing.md)
            .padding(.bottom, AetherTheme.Spacing.xs)

            quickCommand("New Tab", icon: "plus.square", shortcut: "Cmd+T") {
                _ = tabStore.createTab()
                state.hide()
            }
            quickCommand("Split Horizontal", icon: "rectangle.split.1x2", shortcut: "Cmd+\\") {
                onSplitH()
                state.hide()
            }
            quickCommand("Settings", icon: "gear", shortcut: "Cmd+,") {
                onShowSettings?()
                state.hide()
            }
        }
        .padding(.bottom, AetherTheme.Spacing.md)
    }

    private func quickCommand(
        _ title: String,
        icon: String,
        shortcut: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AetherTheme.Spacing.lg) {
                Image(systemName: icon)
                    .foregroundColor(AetherTheme.Colors.textTertiary)
                    .frame(width: 20)
                Text(title)
                    .font(AetherTheme.Typography.body)
                    .foregroundColor(AetherTheme.Colors.textPrimary)
                Spacer()
                Text(shortcut)
                    .font(AetherTheme.Typography.shortcut)
                    .foregroundColor(AetherTheme.Colors.textTertiary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(AetherTheme.Colors.glassSurface)
                    .cornerRadius(AetherTheme.Radius.sm)
            }
            .padding(.horizontal, AetherTheme.Spacing.xl)
            .padding(.vertical, AetherTheme.Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Results Grouping

    private func groupResultsBySections(_ results: [CommandResult]) -> [(String, [CommandResult])] {
        var groups: [(String, [CommandResult])] = []
        var seen: Set<String> = []

        for result in results {
            let section = result.sectionName
            if !seen.contains(section) {
                seen.insert(section)
                let sectionResults = results.filter { $0.sectionName == section }
                groups.append((section, sectionResults))
            }
        }
        return groups
    }

    private func globalIndexFor(
        sectionName: String,
        localIndex: Int,
        sections: [(String, [CommandResult])]
    ) -> Int {
        var offset = 0
        for (name, results) in sections {
            if name == sectionName {
                return offset + localIndex
            }
            offset += results.count
        }
        return offset + localIndex
    }

    // MARK: - Search

    private func updateResults(query: String) {
        guard !query.isEmpty else {
            state.results = []
            return
        }

        var results: [CommandResult] = []

        // Commands (prefix /)
        if query.hasPrefix("/") || query.hasPrefix(">") {
            let cmd = String(query.dropFirst()).lowercased().trimmingCharacters(in: .whitespaces)
            results.append(contentsOf: matchingCommands(cmd))
        } else {
            // All commands that match (even without /)
            let lowered = query.lowercased()

            // Open tabs
            let matchingTabs = tabStore.allTabs.filter {
                $0.title.localizedCaseInsensitiveContains(query) ||
                ($0.url?.absoluteString.localizedCaseInsensitiveContains(query) ?? false)
            }
            results.append(contentsOf: matchingTabs.prefix(5).map { .tab($0) })

            // Bookmarks
            let matchingBookmarks = bookmarkManager.search(query: query)
            results.append(contentsOf: matchingBookmarks.prefix(5).map { .bookmark($0) })

            // History
            let matchingHistory = historyManager.search(query: query)
            results.append(contentsOf: matchingHistory.prefix(8).map { .historyEntry($0) })

            // Matching commands
            let commands = matchingCommands(lowered)
            results.append(contentsOf: commands.prefix(3))

            // URL or search fallback
            results.append(.url(query))
        }

        state.results = results
        state.selectedIndex = 0
    }

    private func matchingCommands(_ query: String) -> [CommandResult] {
        let allCommands: [CommandResult] = [
            .command(name: "Split Horizontal", icon: "rectangle.split.1x2", shortcut: "Cmd+\\") { onSplitH() },
            .command(name: "Split Vertical", icon: "rectangle.split.2x1", shortcut: "Cmd+Shift+\\") { onSplitV() },
            .command(name: "New Tab", icon: "plus.square", shortcut: "Cmd+T") { _ = tabStore.createTab() },
            .command(name: "New Workspace", icon: "square.grid.2x2", shortcut: "Cmd+Shift+N") {
                workspaceManager?.createNewWorkspace()
            },
            .command(name: "Save Workspace", icon: "square.and.arrow.down", shortcut: nil) {
                workspaceManager?.saveCurrentWorkspace()
            },
            .command(name: "Settings", icon: "gear", shortcut: "Cmd+,") {
                onShowSettings?()
            },
            .command(name: "Find in Page", icon: "magnifyingglass", shortcut: "Cmd+F") {
                onToggleFindBar?()
            },
            .command(name: "Zoom In", icon: "plus.magnifyingglass", shortcut: "Cmd++") {
                if let tabId = tabStore.activeTab?.id,
                   let coord = tabStore.coordinator(for: tabId) {
                    coord.zoomIn()
                }
            },
            .command(name: "Zoom Out", icon: "minus.magnifyingglass", shortcut: "Cmd+-") {
                if let tabId = tabStore.activeTab?.id,
                   let coord = tabStore.coordinator(for: tabId) {
                    coord.zoomOut()
                }
            },
            .command(name: "Reset Zoom", icon: "arrow.up.left.and.arrow.down.right", shortcut: "Cmd+0") {
                if let tabId = tabStore.activeTab?.id,
                   let coord = tabStore.coordinator(for: tabId) {
                    coord.zoomReset()
                }
            },
            .command(name: "Reload Page", icon: "arrow.clockwise", shortcut: "Cmd+R") {
                if let tabId = tabStore.activeTab?.id,
                   let coord = tabStore.coordinator(for: tabId) {
                    coord.reload()
                }
            },
        ]

        if query.isEmpty {
            return allCommands
        }

        return allCommands.filter {
            $0.title.localizedCaseInsensitiveContains(query)
        }
    }

    // MARK: - Execution

    private func executeSelected() {
        guard state.selectedIndex < state.results.count else {
            if !state.query.isEmpty {
                onNavigate(state.query)
            }
            state.hide()
            return
        }

        let result = state.results[state.selectedIndex]
        switch result {
        case .tab(let tab):
            for panel in tabStore.panels {
                if panel.tabs.contains(where: { $0.id == tab.id }) {
                    onSelectTab(tab.id, panel.id)
                    break
                }
            }
        case .historyEntry(let entry):
            onNavigate(entry.url)
        case .bookmark(let bookmark):
            onNavigate(bookmark.url)
        case .command(_, _, _, let action):
            action()
        case .url(let urlStr):
            onNavigate(urlStr)
        }
        state.hide()
    }
}

// MARK: - Result Row

struct CommandResultRow: View {
    let result: CommandResult
    let isSelected: Bool

    var body: some View {
        HStack(spacing: AetherTheme.Spacing.lg) {
            Image(systemName: result.iconName)
                .foregroundColor(isSelected ? AetherTheme.Colors.accent : AetherTheme.Colors.textTertiary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(AetherTheme.Typography.body)
                    .foregroundColor(AetherTheme.Colors.textPrimary)
                    .lineLimit(1)

                if let subtitle = result.subtitle {
                    Text(subtitle)
                        .font(AetherTheme.Typography.caption)
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if isSelected {
                HStack(spacing: 2) {
                    Text("Enter")
                        .font(AetherTheme.Typography.shortcut)
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(AetherTheme.Colors.surfaceElevated)
                        .cornerRadius(AetherTheme.Radius.sm)
                }
            }
        }
        .padding(.horizontal, AetherTheme.Spacing.xl)
        .padding(.vertical, AetherTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AetherTheme.Radius.md, style: .continuous)
                .fill(isSelected ? AetherTheme.Colors.accentSubtle : .clear)
                .padding(.horizontal, AetherTheme.Spacing.sm)
        )
    }
}
