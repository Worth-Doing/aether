import Foundation
import AetherCore

public final class WorkspaceRepository: @unchecked Sendable {
    private let db: Database

    public init(database: Database) {
        self.db = database
    }

    public func save(_ workspace: Workspace) throws {
        let encoder = JSONEncoder()
        let layoutData = try encoder.encode(workspace.panelLayout)
        let layoutJSON = String(data: layoutData, encoding: .utf8) ?? "null"

        try db.insert(
            """
            INSERT OR REPLACE INTO workspaces (id, name, panel_layout, tabs, created_at, last_accessed_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            params: [
                .text(workspace.id.uuidString),
                .text(workspace.name),
                .text(layoutJSON),
                .text("[]"),
                .real(workspace.createdAt.timeIntervalSince1970),
                .real(workspace.lastAccessedAt.timeIntervalSince1970),
            ]
        )
    }

    public func loadAll() throws -> [Workspace] {
        let rows = try db.query("SELECT * FROM workspaces ORDER BY last_accessed_at DESC")
        return rows.compactMap(Self.rowToWorkspace)
    }

    public func loadMostRecent() throws -> Workspace? {
        let rows = try db.query("SELECT * FROM workspaces ORDER BY last_accessed_at DESC LIMIT 1")
        return rows.first.flatMap(Self.rowToWorkspace)
    }

    public func delete(id: UUID) throws {
        try db.insert(
            "DELETE FROM workspaces WHERE id = ?",
            params: [.text(id.uuidString)]
        )
    }

    public func deleteAll() throws {
        try db.execute("DELETE FROM workspaces")
    }

    private static func rowToWorkspace(_ row: [String: DatabaseValue]) -> Workspace? {
        guard
            let idStr = row["id"]?.textValue,
            let id = UUID(uuidString: idStr),
            let name = row["name"]?.textValue,
            let layoutJSON = row["panel_layout"]?.textValue,
            let createdAt = row["created_at"]?.realValue,
            let lastAccessedAt = row["last_accessed_at"]?.realValue
        else { return nil }

        let decoder = JSONDecoder()
        guard let layoutData = layoutJSON.data(using: .utf8),
              let layout = try? decoder.decode(PanelNode.self, from: layoutData)
        else { return nil }

        return Workspace(
            id: id,
            name: name,
            panelLayout: layout,
            createdAt: Date(timeIntervalSince1970: createdAt),
            lastAccessedAt: Date(timeIntervalSince1970: lastAccessedAt)
        )
    }
}
