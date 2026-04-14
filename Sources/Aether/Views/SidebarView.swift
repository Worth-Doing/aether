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
    let onNavigate: (String) -> Void

    enum SidebarSection: String, CaseIterable {
        case workspaces = "Workspaces"
        case bookmarks = "Bookmarks"
        case history = "History"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Section picker
            HStack(spacing: 0) {
                ForEach(SidebarSection.allCases, id: \.self) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        Text(section.rawValue)
                            .font(AetherTheme.Typography.captionMedium)
                            .foregroundColor(
                                selectedSection == section
                                    ? AetherTheme.Colors.accent
                                    : AetherTheme.Colors.textTertiary
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AetherTheme.Spacing.md)
                            .background(
                                selectedSection == section
                                    ? AetherTheme.Colors.accentSubtle
                                    : Color.clear
                            )
                            .cornerRadius(AetherTheme.Radius.sm)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AetherTheme.Spacing.md)
            .padding(.vertical, AetherTheme.Spacing.md)

            Divider()
                .background(AetherTheme.Colors.border)

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
        .background(AetherTheme.Colors.sidebarBackground)
    }

    // MARK: - Workspaces

    private var workspacesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sidebarRow(
                icon: "square.grid.2x2",
                title: workspaceManager.currentWorkspace.name,
                subtitle: "Active"
            )

            if !workspaceManager.savedWorkspaces.isEmpty {
                sidebarSectionHeader("Saved Workspaces")

                ForEach(workspaceManager.savedWorkspaces) { workspace in
                    sidebarRow(icon: "tray.2", title: workspace.name) {
                        workspaceManager.restoreWorkspace(workspace)
                    }
                }
            }

            Divider()
                .background(AetherTheme.Colors.border)
                .padding(.vertical, AetherTheme.Spacing.md)

            Button {
                workspaceManager.createNewWorkspace()
            } label: {
                HStack(spacing: AetherTheme.Spacing.md) {
                    Image(systemName: "plus")
                        .font(.system(size: 11))
                    Text("New Workspace")
                        .font(AetherTheme.Typography.caption)
                }
                .foregroundColor(AetherTheme.Colors.textTertiary)
                .padding(.horizontal, AetherTheme.Spacing.xl)
                .padding(.vertical, AetherTheme.Spacing.sm)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Bookmarks

    private var bookmarksSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if bookmarkManager.bookmarks.isEmpty {
                Text("No bookmarks yet")
                    .font(AetherTheme.Typography.caption)
                    .foregroundColor(AetherTheme.Colors.textTertiary)
                    .padding(AetherTheme.Spacing.xl)
            } else {
                ForEach(bookmarkManager.bookmarks) { bookmark in
                    sidebarRow(icon: "bookmark", title: bookmark.title, subtitle: bookmark.url) {
                        onNavigate(bookmark.url)
                    }
                }
            }
        }
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if historyManager.recentHistory.isEmpty {
                Text("No history yet")
                    .font(AetherTheme.Typography.caption)
                    .foregroundColor(AetherTheme.Colors.textTertiary)
                    .padding(AetherTheme.Spacing.xl)
            } else {
                ForEach(historyManager.recentHistory) { entry in
                    sidebarRow(
                        icon: "clock",
                        title: entry.title ?? entry.url,
                        subtitle: entry.url
                    ) {
                        onNavigate(entry.url)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

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
        Button {
            action?()
        } label: {
            HStack(spacing: AetherTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(AetherTheme.Colors.textTertiary)
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
