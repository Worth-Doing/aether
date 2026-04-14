import Foundation
import AetherCore
import Persistence

@Observable
public final class HistoryManager {
    private let repository: HistoryRepository
    public let sessionId: UUID
    public var recentHistory: [HistoryEntry] = []

    public init(repository: HistoryRepository) {
        self.repository = repository
        self.sessionId = UUID()
        loadRecent()
    }

    public func recordVisit(url: URL, title: String?, workspaceId: UUID? = nil) {
        let entry = HistoryEntry(
            url: url.absoluteString,
            title: title,
            sessionId: sessionId,
            workspaceId: workspaceId
        )
        try? repository.insert(entry)
        loadRecent()
    }

    public func search(query: String) -> [HistoryEntry] {
        (try? repository.search(query: query)) ?? []
    }

    public func allRecent(limit: Int = 100) -> [HistoryEntry] {
        (try? repository.recent(limit: limit)) ?? []
    }

    public func clearAll() {
        try? repository.deleteAll()
        recentHistory = []
    }

    private func loadRecent() {
        recentHistory = (try? repository.recent(limit: 50)) ?? []
    }
}
