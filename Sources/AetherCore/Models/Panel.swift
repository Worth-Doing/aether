import Foundation

@Observable
public final class Panel: Identifiable {
    public let id: UUID
    public var tabs: [Tab]
    public var activeTabId: UUID?

    public var activeTab: Tab? {
        tabs.first { $0.id == activeTabId }
    }

    public init(
        id: UUID = UUID(),
        tabs: [Tab] = [],
        activeTabId: UUID? = nil
    ) {
        self.id = id
        self.tabs = tabs
        self.activeTabId = activeTabId
    }

    public func addTab(_ tab: Tab) {
        tabs.append(tab)
        activeTabId = tab.id
    }

    public func removeTab(_ tabId: UUID) {
        tabs.removeAll { $0.id == tabId }
        if activeTabId == tabId {
            activeTabId = tabs.last?.id
        }
    }

    public func selectTab(_ tabId: UUID) {
        if tabs.contains(where: { $0.id == tabId }) {
            activeTabId = tabId
        }
    }
}
