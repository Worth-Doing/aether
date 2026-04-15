import Foundation
import AetherCore

public final class HistoryRepository: @unchecked Sendable {
    private let db: Database

    public init(database: Database) {
        self.db = database
    }

    public func insert(_ entry: HistoryEntry) throws {
        try db.insert(
            """
            INSERT OR REPLACE INTO history (id, url, title, visited_at, session_id, workspace_id, duration)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            params: [
                .text(entry.id.uuidString),
                .text(entry.url),
                entry.title.map { .text($0) } ?? .null,
                .real(entry.visitedAt.timeIntervalSince1970),
                .text(entry.sessionId.uuidString),
                entry.workspaceId.map { .text($0.uuidString) } ?? .null,
                entry.duration.map { .real($0) } ?? .null,
            ]
        )
    }

    public func search(query: String, limit: Int = 50) throws -> [HistoryEntry] {
        let pattern = "%\(query)%"
        let rows = try db.query(
            """
            SELECT * FROM history
            WHERE url LIKE ? OR title LIKE ?
            ORDER BY visited_at DESC
            LIMIT ?
            """,
            params: [.text(pattern), .text(pattern), .integer(limit)]
        )
        return rows.compactMap(Self.rowToEntry)
    }

    public func recent(limit: Int = 100) throws -> [HistoryEntry] {
        let rows = try db.query(
            "SELECT * FROM history ORDER BY visited_at DESC LIMIT ?",
            params: [.integer(limit)]
        )
        return rows.compactMap(Self.rowToEntry)
    }

    public func bySession(_ sessionId: UUID) throws -> [HistoryEntry] {
        let rows = try db.query(
            "SELECT * FROM history WHERE session_id = ? ORDER BY visited_at DESC",
            params: [.text(sessionId.uuidString)]
        )
        return rows.compactMap(Self.rowToEntry)
    }

    public func byDomain(_ domain: String, limit: Int = 50) throws -> [HistoryEntry] {
        let pattern = "%\(domain)%"
        let rows = try db.query(
            "SELECT * FROM history WHERE url LIKE ? ORDER BY visited_at DESC LIMIT ?",
            params: [.text(pattern), .integer(limit)]
        )
        return rows.compactMap(Self.rowToEntry)
    }

    public func deleteAll() throws {
        try db.execute("DELETE FROM history")
    }

    public func delete(id: UUID) throws {
        try db.insert(
            "DELETE FROM history WHERE id = ?",
            params: [.text(id.uuidString)]
        )
    }

    private static func rowToEntry(_ row: [String: DatabaseValue]) -> HistoryEntry? {
        guard
            let idStr = row["id"]?.textValue,
            let id = UUID(uuidString: idStr),
            let url = row["url"]?.textValue,
            let visitedAt = row["visited_at"]?.realValue,
            let sessionIdStr = row["session_id"]?.textValue,
            let sessionId = UUID(uuidString: sessionIdStr)
        else { return nil }

        return HistoryEntry(
            id: id,
            url: url,
            title: row["title"]?.textValue,
            visitedAt: Date(timeIntervalSince1970: visitedAt),
            sessionId: sessionId,
            workspaceId: row["workspace_id"]?.textValue.flatMap(UUID.init),
            duration: row["duration"]?.realValue
        )
    }
}
