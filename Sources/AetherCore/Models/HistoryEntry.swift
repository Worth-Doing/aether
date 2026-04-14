import Foundation

public struct HistoryEntry: Identifiable, Codable {
    public let id: UUID
    public var url: String
    public var title: String?
    public var visitedAt: Date
    public var sessionId: UUID
    public var workspaceId: UUID?
    public var duration: TimeInterval?

    public init(
        id: UUID = UUID(),
        url: String,
        title: String? = nil,
        visitedAt: Date = Date(),
        sessionId: UUID,
        workspaceId: UUID? = nil,
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.visitedAt = visitedAt
        self.sessionId = sessionId
        self.workspaceId = workspaceId
        self.duration = duration
    }
}
