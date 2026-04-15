import Foundation
import AetherCore
import Persistence

@Observable
public final class HistoryManager {
    private let repository: HistoryRepository
    public let sessionId: UUID
    public var recentHistory: [HistoryEntry] = []
    public var lastError: String?

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
        do {
            try repository.insert(entry)
            lastError = nil
        } catch {
            lastError = "Failed to record history: \(error.localizedDescription)"
        }
        loadRecent()
    }

    public func search(query: String) -> [HistoryEntry] {
        do {
            return try repository.search(query: query)
        } catch {
            lastError = "History search failed: \(error.localizedDescription)"
            return []
        }
    }

    public func allRecent(limit: Int = 100) -> [HistoryEntry] {
        do {
            return try repository.recent(limit: limit)
        } catch {
            lastError = "Failed to load history: \(error.localizedDescription)"
            return []
        }
    }

    public func clearAll() {
        do {
            try repository.deleteAll()
            lastError = nil
        } catch {
            lastError = "Failed to clear history: \(error.localizedDescription)"
        }
        recentHistory = []
    }

    public func deleteEntry(_ id: UUID) {
        do {
            try repository.delete(id: id)
            lastError = nil
        } catch {
            lastError = "Failed to delete history entry: \(error.localizedDescription)"
        }
        loadRecent()
    }

    private func loadRecent() {
        do {
            recentHistory = try repository.recent(limit: 50)
        } catch {
            lastError = "Failed to load recent history: \(error.localizedDescription)"
            recentHistory = []
        }
    }
}
