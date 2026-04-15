import Foundation
import AetherCore
import Persistence

@Observable
public final class BookmarkManager {
    private let repository: BookmarkRepository
    public var bookmarks: [Bookmark] = []
    public var folders: [BookmarkFolder] = []
    public var lastError: String?

    public init(repository: BookmarkRepository) {
        self.repository = repository
        loadAll()
    }

    public func addBookmark(url: String, title: String, folderId: UUID? = nil) {
        let bookmark = Bookmark(url: url, title: title, folderId: folderId)
        do {
            try repository.insert(bookmark)
            lastError = nil
        } catch {
            lastError = "Failed to add bookmark: \(error.localizedDescription)"
        }
        loadAll()
    }

    public func removeBookmark(_ id: UUID) {
        do {
            try repository.delete(id: id)
            lastError = nil
        } catch {
            lastError = "Failed to remove bookmark: \(error.localizedDescription)"
        }
        loadAll()
    }

    public func isBookmarked(url: String) -> Bool {
        bookmarks.contains { $0.url == url }
    }

    public func search(query: String) -> [Bookmark] {
        do {
            return try repository.search(query: query)
        } catch {
            lastError = "Bookmark search failed: \(error.localizedDescription)"
            return []
        }
    }

    public func createFolder(name: String, parentId: UUID? = nil) {
        let folder = BookmarkFolder(name: name, parentId: parentId)
        do {
            try repository.insertFolder(folder)
            lastError = nil
        } catch {
            lastError = "Failed to create folder: \(error.localizedDescription)"
        }
        loadAll()
    }

    public func clearAll() {
        for bookmark in bookmarks {
            do {
                try repository.delete(id: bookmark.id)
            } catch {
                lastError = "Failed to clear bookmarks: \(error.localizedDescription)"
            }
        }
        loadAll()
    }

    private func loadAll() {
        do {
            bookmarks = try repository.allBookmarks()
            folders = try repository.allFolders()
        } catch {
            lastError = "Failed to load bookmarks: \(error.localizedDescription)"
            bookmarks = []
            folders = []
        }
    }
}
