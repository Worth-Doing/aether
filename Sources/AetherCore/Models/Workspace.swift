import Foundation

public struct Workspace: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var panelLayout: PanelNode
    public var createdAt: Date
    public var lastAccessedAt: Date

    public init(
        id: UUID = UUID(),
        name: String = "Untitled Workspace",
        panelLayout: PanelNode = .leaf(panelId: UUID()),
        createdAt: Date = Date(),
        lastAccessedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.panelLayout = panelLayout
        self.createdAt = createdAt
        self.lastAccessedAt = lastAccessedAt
    }
}
