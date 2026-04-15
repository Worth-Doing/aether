import SwiftUI
import AetherCore
import AetherUI
import PanelSystem
import HistoryEngine
import BookmarkEngine

struct SidebarView: View {
    @Bindable var workspaceManager: WorkspaceManager
    @Bindable var historyManager: HistoryManager
    @Bindable var bookmarkManager: BookmarkManager
    @State private var selectedSection: SidebarSection = .workspaces
    @State private var workspaceName: String = ""
    @State private var showRenameSheet: Bool = false
    let onNavigate: (String) -> Void

    enum SidebarSection: String, CaseIterable {
        case workspaces = "Workspaces"
        case bookmarks = "Bookmarks"
        case history = "History"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Section picker — glass pills
            HStack(spacing: 2) {
                ForEach(SidebarSection.allCases, id: \.self) { section in
                    Button {
                        withAnimation(AetherTheme.Animation.spring) {
                            selectedSection = section
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: iconForSection(section))
                                .font(.system(size: 11))
                            Text(section.rawValue)
                                .font(.system(size: 9, weight: .medium))
                        }
                        .foregroundColor(
                            selectedSection == section
                                ? AetherTheme.Colors.accent
                                : AetherTheme.Colors.textTertiary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AetherTheme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AetherTheme.Radius.md, style: .continuous)
                                .fill(
                                    selectedSection == section
                                        ? AetherTheme.Colors.accentSubtle
                                        : Color.clear
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AetherTheme.Spacing.md)
            .padding(.vertical, AetherTheme.Spacing.md)

            Divider()
                .background(AetherTheme.Colors.glassBorderSubtle)

            // Content
            ScrollView {
                LazyVStack(spacing: 0) {
                    switch selectedSection {
                    case .workspaces:
                        workspacesSection
                    case .bookmarks:
                        bookmarksSection
                    case .history:
                        historySection
                    }
                }
                .padding(.vertical, AetherTheme.Spacing.sm)
            }
        }
        .frame(width: AetherTheme.Sizes.sidebarWidth)
        .glassPanel()
    }

    private func iconForSection(_ section: SidebarSection) -> String {
        switch section {
        case .workspaces: return "square.grid.2x2"
        case .bookmarks: return "bookmark"
        case .history: return "clock"
        }
    }

    // MARK: - Workspaces

    private var workspacesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Current workspace — glass card
            HStack(spacing: AetherTheme.Spacing.md) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AetherTheme.Colors.accent)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 1) {
                    Text(workspaceManager.currentWorkspace.name)
                        .font(AetherTheme.Typography.captionMedium)
                        .foregroundColor(AetherTheme.Colors.textPrimary)
                        .lineLimit(1)
                    Text("Active workspace")
                        .font(.system(size: 10))
                        .foregroundColor(AetherTheme.Colors.accent)
                }

                Spacer()
            }
            .padding(.horizontal, AetherTheme.Spacing.xl)
            .padding(.vertical, AetherTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.lg, style: .continuous)
                    .fill(AetherTheme.Colors.accentSubtle)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.lg, style: .continuous)
                    .strokeBorder(AetherTheme.Colors.accent.opacity(0.15), lineWidth: 0.5)
            )
            .padding(.horizontal, AetherTheme.Spacing.md)
            .padding(.bottom, AetherTheme.Spacing.sm)

            if !workspaceManager.savedWorkspaces.isEmpty {
                sidebarSectionHeader("Saved Workspaces")

                ForEach(workspaceManager.savedWorkspaces) { workspace in
                    sidebarRow(icon: "tray.2", title: workspace.name) {
                        workspaceManager.restoreWorkspace(workspace)
                    }
                    .contextMenu {
                        Button("Restore") {
                            workspaceManager.restoreWorkspace(workspace)
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            workspaceManager.deleteWorkspace(workspace.id)
                        }
                    }
                }
            }

            Divider()
                .background(AetherTheme.Colors.glassBorderSubtle)
                .padding(.vertical, AetherTheme.Spacing.md)

            // Actions
            HStack(spacing: AetherTheme.Spacing.md) {
                sidebarActionButton(icon: "plus", title: "New") {
                    workspaceManager.createNewWorkspace()
                }

                sidebarActionButton(icon: "square.and.arrow.down", title: "Save") {
                    workspaceManager.saveCurrentWorkspace()
                }
            }
            .padding(.horizontal, AetherTheme.Spacing.xl)
        }
    }

    // MARK: - Bookmarks

    private var bookmarksSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if bookmarkManager.bookmarks.isEmpty {
                emptyStateView(
                    icon: "bookmark",
                    title: "No bookmarks yet",
                    subtitle: "Press Cmd+D to bookmark a page"
                )
            } else {
                if !bookmarkManager.folders.isEmpty {
                    ForEach(bookmarkManager.folders) { folder in
                        DisclosureGroup {
                            let folderBookmarks = bookmarkManager.bookmarks.filter { $0.folderId == folder.id }
                            ForEach(folderBookmarks) { bookmark in
                                bookmarkRow(bookmark)
                            }
                        } label: {
                            HStack(spacing: AetherTheme.Spacing.md) {
                                Image(systemName: "folder")
                                    .font(.system(size: 12))
                                    .foregroundColor(AetherTheme.Colors.textTertiary)
                                    .frame(width: 18)
                                Text(folder.name)
                                    .font(AetherTheme.Typography.caption)
                                    .foregroundColor(AetherTheme.Colors.textPrimary)
                            }
                        }
                        .padding(.horizontal, AetherTheme.Spacing.xl)
                        .padding(.vertical, AetherTheme.Spacing.xs)
                    }

                    let uncategorized = bookmarkManager.bookmarks.filter { $0.folderId == nil }
                    if !uncategorized.isEmpty {
                        sidebarSectionHeader("Uncategorized")
                    }
                }

                let displayBookmarks = bookmarkManager.folders.isEmpty
                    ? bookmarkManager.bookmarks
                    : bookmarkManager.bookmarks.filter { $0.folderId == nil }

                ForEach(displayBookmarks) { bookmark in
                    bookmarkRow(bookmark)
                }
            }
        }
    }

    private func bookmarkRow(_ bookmark: Bookmark) -> some View {
        sidebarRow(icon: "bookmark.fill", title: bookmark.title, subtitle: bookmark.url) {
            onNavigate(bookmark.url)
        }
        .contextMenu {
            Button("Open") { onNavigate(bookmark.url) }
            Button("Copy URL") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(bookmark.url, forType: .string)
            }
            Divider()
            Button("Delete", role: .destructive) {
                bookmarkManager.removeBookmark(bookmark.id)
            }
        }
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if historyManager.recentHistory.isEmpty {
                emptyStateView(
                    icon: "clock",
                    title: "No history yet",
                    subtitle: "Pages you visit will appear here"
                )
            } else {
                let grouped = groupHistoryByDate(historyManager.recentHistory)

                ForEach(grouped.keys.sorted(), id: \.self) { dateKey in
                    sidebarSectionHeader(dateKey)

                    if let entries = grouped[dateKey] {
                        ForEach(entries) { entry in
                            sidebarRow(
                                icon: "clock",
                                title: entry.title ?? extractDomain(from: entry.url),
                                subtitle: extractDomain(from: entry.url)
                            ) {
                                onNavigate(entry.url)
                            }
                            .contextMenu {
                                Button("Open") { onNavigate(entry.url) }
                                Button("Copy URL") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(entry.url, forType: .string)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - History Grouping

    private func groupHistoryByDate(_ entries: [HistoryEntry]) -> [String: [HistoryEntry]] {
        let calendar = Calendar.current
        var groups: [String: [HistoryEntry]] = [:]

        for entry in entries {
            let key: String
            if calendar.isDateInToday(entry.visitedAt) {
                key = "Today"
            } else if calendar.isDateInYesterday(entry.visitedAt) {
                key = "Yesterday"
            } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()),
                      entry.visitedAt > weekAgo {
                key = "This Week"
            } else {
                key = "Earlier"
            }

            groups[key, default: []].append(entry)
        }

        return groups
    }

    private func extractDomain(from url: String) -> String {
        URL(string: url)?.host() ?? url
    }

    // MARK: - Helpers

    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: AetherTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AetherTheme.Colors.textTertiary.opacity(0.6))
            Text(title)
                .font(AetherTheme.Typography.caption)
                .foregroundColor(AetherTheme.Colors.textTertiary)
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(AetherTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(AetherTheme.Spacing.xxl)
    }

    private func sidebarActionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AetherTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(AetherTheme.Typography.caption)
            }
            .foregroundColor(AetherTheme.Colors.textSecondary)
            .padding(.horizontal, AetherTheme.Spacing.md)
            .padding(.vertical, AetherTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.md, style: .continuous)
                    .fill(AetherTheme.Colors.glassSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.md, style: .continuous)
                    .strokeBorder(AetherTheme.Colors.glassBorderSubtle, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func sidebarSectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(AetherTheme.Colors.textTertiary)
            .padding(.horizontal, AetherTheme.Spacing.xl)
            .padding(.top, AetherTheme.Spacing.lg)
            .padding(.bottom, AetherTheme.Spacing.sm)
    }

    private func sidebarRow(
        icon: String,
        title: String,
        subtitle: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        SidebarRowView(icon: icon, title: title, subtitle: subtitle, action: action)
    }
}

// MARK: - Sidebar Row with Hover

private struct SidebarRowView: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: (() -> Void)?

    @State private var isHovering = false

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: AetherTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(
                        isHovering ? AetherTheme.Colors.accent : AetherTheme.Colors.textTertiary
                    )
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(AetherTheme.Typography.caption)
                        .foregroundColor(AetherTheme.Colors.textPrimary)
                        .lineLimit(1)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 10))
                            .foregroundColor(AetherTheme.Colors.textTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, AetherTheme.Spacing.xl)
            .padding(.vertical, AetherTheme.Spacing.sm + 1)
            .background(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.md, style: .continuous)
                    .fill(isHovering ? AetherTheme.Colors.glassHover : .clear)
                    .padding(.horizontal, AetherTheme.Spacing.sm)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(AetherTheme.Animation.fast) {
                isHovering = hovering
            }
        }
    }
}
