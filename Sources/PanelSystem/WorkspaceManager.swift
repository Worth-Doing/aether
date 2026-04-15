import Foundation
import AetherCore
import TabManager

@Observable
public final class WorkspaceManager {
    public var currentWorkspace: Workspace
    public var savedWorkspaces: [Workspace] = []
    public let tabStore: TabStore

    public init(tabStore: TabStore) {
        self.tabStore = tabStore

        let initialPanelId = tabStore.panels.first?.id ?? UUID()
        self.currentWorkspace = Workspace(
            name: AppConstants.Defaults.defaultWorkspaceName,
            panelLayout: .leaf(panelId: initialPanelId)
        )
    }

    // MARK: - Split Operations

    public func splitPanel(_ panelId: UUID, axis: SplitAxis) {
        let newPanel = tabStore.createPanel()
        let newNode = PanelNode.split(
            axis: axis,
            ratio: 0.5,
            first: .leaf(panelId: panelId),
            second: .leaf(panelId: newPanel.id)
        )
        currentWorkspace.panelLayout = currentWorkspace.panelLayout.replacingPanel(panelId, with: newNode)
        tabStore.focusPanel(newPanel.id)
    }

    public func closePanel(_ panelId: UUID) {
        guard currentWorkspace.panelLayout.allPanelIds.count > 1 else { return }
        tabStore.removePanel(panelId)
        if let newLayout = currentWorkspace.panelLayout.removingPanel(panelId) {
            currentWorkspace.panelLayout = newLayout
        }
    }

    // MARK: - Workspace Management

    public func saveCurrentWorkspace(name: String? = nil) {
        var snapshot = currentWorkspace
        if let name {
            snapshot.name = name
        }
        snapshot.lastAccessedAt = Date()

        if let index = savedWorkspaces.firstIndex(where: { $0.id == snapshot.id }) {
            savedWorkspaces[index] = snapshot
        } else {
            savedWorkspaces.append(snapshot)
        }
    }

    public func restoreWorkspace(_ workspace: Workspace) {
        currentWorkspace = workspace
        currentWorkspace.lastAccessedAt = Date()
    }

    public func createNewWorkspace(name: String = "New Workspace") {
        saveCurrentWorkspace()

        let panel = tabStore.createPanel()
        let oldPanelIds = tabStore.panels.filter { $0.id != panel.id }.map(\.id)
        for id in oldPanelIds {
            tabStore.removePanel(id)
        }

        currentWorkspace = Workspace(
            name: name,
            panelLayout: .leaf(panelId: panel.id)
        )
    }

    public func deleteWorkspace(_ id: UUID) {
        savedWorkspaces.removeAll { $0.id == id }
    }

    // MARK: - Session State (for restore)

    public func getSessionState() -> Workspace {
        var session = currentWorkspace
        session.lastAccessedAt = Date()
        return session
    }

    public func restoreSession(from workspace: Workspace) {
        currentWorkspace = workspace
    }

    // MARK: - Layout

    public func updateSplitRatio(at panelId: UUID, ratio: Double) {
        func updateNode(_ node: PanelNode) -> PanelNode {
            switch node {
            case .leaf:
                return node
            case .split(let axis, _, let first, let second):
                if case .leaf(let id) = first, id == panelId {
                    return .split(axis: axis, ratio: ratio, first: first, second: second)
                }
                if case .leaf(let id) = second, id == panelId {
                    return .split(axis: axis, ratio: ratio, first: first, second: second)
                }
                return .split(
                    axis: axis,
                    ratio: ratio,
                    first: updateNode(first),
                    second: updateNode(second)
                )
            }
        }
        currentWorkspace.panelLayout = updateNode(currentWorkspace.panelLayout)
    }
}
