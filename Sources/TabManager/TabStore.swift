import Foundation
import AetherCore
import BrowserEngine

@Observable
public final class TabStore {
    public var panels: [Panel] = []
    public var activePanelId: UUID?
    private var coordinators: [UUID: WebViewCoordinator] = [:]
    private var recentlyClosedTabs: [(tab: Tab, panelId: UUID)] = []

    public var activePanel: Panel? {
        panels.first { $0.id == activePanelId }
    }

    public var activeTab: Tab? {
        activePanel?.activeTab
    }

    public init() {
        let panel = Panel()
        let tab = Tab()
        panel.addTab(tab)
        panels.append(panel)
        activePanelId = panel.id

        let coordinator = WebViewCoordinator(tabId: tab.id)
        coordinators[tab.id] = coordinator
        bindCoordinator(coordinator, to: tab)
    }

    // MARK: - Tab Operations

    public func createTab(in panelId: UUID? = nil, url: URL? = nil) -> Tab {
        let targetPanelId = panelId ?? activePanelId
        guard let panel = panels.first(where: { $0.id == targetPanelId }) else {
            let tab = Tab(url: url)
            let panel = Panel()
            panel.addTab(tab)
            panels.append(panel)
            activePanelId = panel.id
            let coordinator = WebViewCoordinator(tabId: tab.id)
            coordinators[tab.id] = coordinator
            bindCoordinator(coordinator, to: tab)
            if let url { coordinator.load(url: url) }
            return tab
        }

        let tab = Tab(url: url)
        panel.addTab(tab)
        let coordinator = WebViewCoordinator(tabId: tab.id)
        coordinators[tab.id] = coordinator
        bindCoordinator(coordinator, to: tab)
        if let url { coordinator.load(url: url) }
        return tab
    }

    public func closeTab(_ tabId: UUID) {
        for panel in panels {
            if let tab = panel.tabs.first(where: { $0.id == tabId }) {
                recentlyClosedTabs.append((tab: tab, panelId: panel.id))
                if recentlyClosedTabs.count > 20 {
                    recentlyClosedTabs.removeFirst()
                }
                panel.removeTab(tabId)
                coordinators.removeValue(forKey: tabId)

                if panel.tabs.isEmpty && panels.count > 1 {
                    panels.removeAll { $0.id == panel.id }
                    if activePanelId == panel.id {
                        activePanelId = panels.first?.id
                    }
                } else if panel.tabs.isEmpty {
                    let newTab = Tab()
                    panel.addTab(newTab)
                    let coordinator = WebViewCoordinator(tabId: newTab.id)
                    coordinators[newTab.id] = coordinator
                    bindCoordinator(coordinator, to: newTab)
                }
                return
            }
        }
    }

    public func reopenLastClosedTab() {
        guard let last = recentlyClosedTabs.popLast() else { return }
        let panel = panels.first(where: { $0.id == last.panelId }) ?? panels.first!
        panel.addTab(last.tab)
        let coordinator = WebViewCoordinator(tabId: last.tab.id)
        coordinators[last.tab.id] = coordinator
        bindCoordinator(coordinator, to: last.tab)
        if let url = last.tab.url {
            coordinator.load(url: url)
        }
    }

    public func selectTab(_ tabId: UUID, inPanel panelId: UUID) {
        if let panel = panels.first(where: { $0.id == panelId }) {
            panel.selectTab(tabId)
            activePanelId = panelId
        }
    }

    public func moveTab(_ tabId: UUID, from sourcePanelId: UUID, to targetPanelId: UUID) {
        guard
            let source = panels.first(where: { $0.id == sourcePanelId }),
            let target = panels.first(where: { $0.id == targetPanelId }),
            let tab = source.tabs.first(where: { $0.id == tabId })
        else { return }

        source.removeTab(tabId)
        target.addTab(tab)
    }

    // MARK: - Coordinator Access

    public func coordinator(for tabId: UUID) -> WebViewCoordinator? {
        coordinators[tabId]
    }

    // MARK: - Navigation

    public func navigate(to urlString: String) {
        guard let tab = activeTab, let coordinator = coordinators[tab.id] else { return }

        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            coordinator.load(urlString: trimmed)
        } else if trimmed.contains(".") && !trimmed.contains(" ") {
            coordinator.load(urlString: "https://\(trimmed)")
        } else {
            coordinator.loadSearch(query: trimmed)
        }
    }

    // MARK: - Panel Operations

    public func createPanel() -> Panel {
        let panel = Panel()
        let tab = Tab()
        panel.addTab(tab)
        panels.append(panel)

        let coordinator = WebViewCoordinator(tabId: tab.id)
        coordinators[tab.id] = coordinator
        bindCoordinator(coordinator, to: tab)

        return panel
    }

    public func removePanel(_ panelId: UUID) {
        guard panels.count > 1 else { return }
        if let panel = panels.first(where: { $0.id == panelId }) {
            for tab in panel.tabs {
                coordinators.removeValue(forKey: tab.id)
            }
        }
        panels.removeAll { $0.id == panelId }
        if activePanelId == panelId {
            activePanelId = panels.first?.id
        }
    }

    public func focusPanel(_ panelId: UUID) {
        activePanelId = panelId
    }

    // MARK: - All Tabs

    public var allTabs: [Tab] {
        panels.flatMap(\.tabs)
    }

    // MARK: - Private

    private func bindCoordinator(_ coordinator: WebViewCoordinator, to tab: Tab) {
        coordinator.onNavigationCommitted = { [weak tab] url, title in
            tab?.url = url
            if let title, !title.isEmpty {
                tab?.title = title
            }
            tab?.lastAccessed = Date()
        }
        coordinator.onNavigationFinished = { [weak tab] url, title in
            tab?.url = url
            if let title, !title.isEmpty {
                tab?.title = title
            }
            tab?.isLoading = false
        }
    }
}
