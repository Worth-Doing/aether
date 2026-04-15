import Foundation
import AetherCore

public final class BookmarkRepository: @unchecked Sendable {
    private let db: Database

    public init(database: Database) {
        self.db = database
    }

    // MARK: - Bookmarks

    public func insert(_ bookmark: Bookmark) throws {
        try db.insert(
            """
            INSERT OR REPLACE INTO bookmarks (id, url, title, folder_id, created_at)
            VALUES (?, ?, ?, ?, ?)
            """,
            params: [
                .text(bookmark.id.uuidString),
                .text(bookmark.url),
                .text(bookmark.title),
                bookmark.folderId.map { .text($0.uuidString) } ?? .null,
                .real(bookmark.createdAt.timeIntervalSince1970),
            ]
        )
    }

    public func allBookmarks() throws -> [Bookmark] {
        let rows = try db.query("SELECT * FROM bookmarks ORDER BY created_at DESC")
        return rows.compactMap(Self.rowToBookmark)
    }

    public func search(query: String, limit: Int = 50) throws -> [Bookmark] {
        let pattern = "%\(query)%"
        let rows = try db.query(
            """
            SELECT * FROM bookmarks
            WHERE url LIKE ? OR title LIKE ?
            ORDER BY created_at DESC
            LIMIT ?
            """,
            params: [.text(pattern), .text(pattern), .integer(limit)]
        )
        return rows.compactMap(Self.rowToBookmark)
    }

    public func delete(id: UUID) throws {
        try db.insert(
            "DELETE FROM bookmarks WHERE id = ?",
            params: [.text(id.uuidString)]
        )
    }

    // MARK: - Folders

    public func insertFolder(_ folder: BookmarkFolder) throws {
        try db.insert(
            """
            INSERT OR REPLACE INTO bookmark_folders (id, name, parent_id)
            VALUES (?, ?, ?)
            """,
            params: [
                .text(folder.id.uuidString),
                .text(folder.name),
                folder.parentId.map { .text($0.uuidString) } ?? .null,
            ]
        )
    }

    public func allFolders() throws -> [BookmarkFolder] {
        let rows = try db.query("SELECT * FROM bookmark_folders ORDER BY name")
        return rows.compactMap(Self.rowToFolder)
    }

    // MARK: - Row Mapping

    private static func rowToBookmark(_ row: [String: DatabaseValue]) -> Bookmark? {
        guard
            let idStr = row["id"]?.textValue,
            let id = UUID(uuidString: idStr),
            let url = row["url"]?.textValue,
            let title = row["title"]?.textValue,
            let createdAt = row["created_at"]?.realValue
        else { return nil }

        return Bookmark(
            id: id,
            url: url,
            title: title,
            folderId: row["folder_id"]?.textValue.flatMap(UUID.init),
            createdAt: Date(timeIntervalSince1970: createdAt)
        )
    }

    private static func rowToFolder(_ row: [String: DatabaseValue]) -> BookmarkFolder? {
        guard
            let idStr = row["id"]?.textValue,
            let id = UUID(uuidString: idStr),
            let name = row["name"]?.textValue
        else { return nil }

        return BookmarkFolder(
            id: id,
            name: name,
            parentId: row["parent_id"]?.textValue.flatMap(UUID.init)
        )
    }
}
