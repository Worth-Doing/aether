import SwiftUI
import AetherCore
import AetherUI
import TabManager
import HistoryEngine
import BookmarkEngine

public enum CommandResult: Identifiable {
    case tab(AetherCore.Tab)
    case historyEntry(HistoryEntry)
    case bookmark(Bookmark)
    case command(name: String, action: () -> Void)
    case url(String)

    public var id: String {
        switch self {
        case .tab(let t): return "tab-\(t.id)"
        case .historyEntry(let h): return "history-\(h.id)"
        case .bookmark(let b): return "bookmark-\(b.id)"
        case .command(let name, _): return "cmd-\(name)"
        case .url(let u): return "url-\(u)"
        }
    }

    public var title: String {
        switch self {
        case .tab(let t): return t.title
        case .historyEntry(let h): return h.title ?? h.url
        case .bookmark(let b): return b.title
        case .command(let name, _): return name
        case .url(let u): return u
        }
    }

    public var subtitle: String? {
        switch self {
        case .tab(let t): return t.url?.host()
        case .historyEntry(let h): return h.url
        case .bookmark(let b): return b.url
        case .command: return "Command"
        case .url: return "Navigate"
        }
    }

    public var iconName: String {
        switch self {
        case .tab: return "square.on.square"
        case .historyEntry: return "clock"
        case .bookmark: return "bookmark"
        case .command: return "command"
        case .url: return "globe"
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

    public init(
        state: CommandBarState,
        tabStore: TabStore,
        historyManager: HistoryManager,
        bookmarkManager: BookmarkManager,
        onNavigate: @escaping (String) -> Void,
        onSelectTab: @escaping (UUID, UUID) -> Void,
        onSplitH: @escaping () -> Void,
        onSplitV: @escaping () -> Void
    ) {
        self.state = state
        self.tabStore = tabStore
        self.historyManager = historyManager
        self.bookmarkManager = bookmarkManager
        self.onNavigate = onNavigate
        self.onSelectTab = onSelectTab
        self.onSplitH = onSplitH
        self.onSplitV = onSplitV
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: AetherTheme.Spacing.md) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AetherTheme.Colors.textTertiary)
                    .font(.system(size: 16))

                TextField("Search tabs, history, bookmarks, or enter URL...", text: $state.query)
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
            }
            .padding(.horizontal, AetherTheme.Spacing.xl)
            .padding(.vertical, AetherTheme.Spacing.lg)

            if !state.results.isEmpty {
                Divider()
                    .background(AetherTheme.Colors.border)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(state.results.enumerated()), id: \.element.id) { index, result in
                                CommandResultRow(
                                    result: result,
                                    isSelected: index == state.selectedIndex
                                )
                                .id(index)
                                .onTapGesture {
                                    state.selectedIndex = index
                                    executeSelected()
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
            }
        }
        .background(AetherTheme.Colors.surfaceElevated)
        .cornerRadius(AetherTheme.Radius.xl)
        .overlay(
            RoundedRectangle(cornerRadius: AetherTheme.Radius.xl)
                .strokeBorder(AetherTheme.Colors.borderFocused, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
        .frame(width: AetherTheme.Sizes.commandBarWidth)
    }

    private func updateResults(query: String) {
        guard !query.isEmpty else {
            state.results = []
            return
        }

        var results: [CommandResult] = []

        // Commands
        if query.hasPrefix("/") {
            let cmd = String(query.dropFirst()).lowercased()
            if "split horizontal".contains(cmd) || "splith".contains(cmd) {
                results.append(.command(name: "Split Panel Horizontally", action: onSplitH))
            }
            if "split vertical".contains(cmd) || "splitv".contains(cmd) {
                results.append(.command(name: "Split Panel Vertically", action: onSplitV))
            }
        }

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
        results.append(contentsOf: matchingHistory.prefix(10).map { .historyEntry($0) })

        // URL or search
        if !query.hasPrefix("/") {
            results.append(.url(query))
        }

        state.results = results
        state.selectedIndex = 0
    }

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
        case .command(_, let action):
            action()
        case .url(let urlStr):
            onNavigate(urlStr)
        }
        state.hide()
    }
}

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
                Text("Enter")
                    .font(AetherTheme.Typography.caption)
                    .foregroundColor(AetherTheme.Colors.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AetherTheme.Colors.surface)
                    .cornerRadius(AetherTheme.Radius.sm)
            }
        }
        .padding(.horizontal, AetherTheme.Spacing.xl)
        .padding(.vertical, AetherTheme.Spacing.md)
        .background(isSelected ? AetherTheme.Colors.accentSubtle : Color.clear)
    }
}
