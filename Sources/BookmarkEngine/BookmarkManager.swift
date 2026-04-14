import Foundation
import AetherCore
import Persistence

@Observable
public final class BookmarkManager {
    private let repository: BookmarkRepository
    public var bookmarks: [Bookmark] = []
    public var folders: [BookmarkFolder] = []

    public init(repository: BookmarkRepository) {
        self.repository = repository
        loadAll()
    }

    public func addBookmark(url: String, title: String, folderId: UUID? = nil) {
        let bookmark = Bookmark(url: url, title: title, folderId: folderId)
        try? repository.insert(bookmark)
        loadAll()
    }

    public func removeBookmark(_ id: UUID) {
        try? repository.delete(id: id)
        loadAll()
    }

    public func isBookmarked(url: String) -> Bool {
        bookmarks.contains { $0.url == url }
    }

    public func search(query: String) -> [Bookmark] {
        (try? repository.search(query: query)) ?? []
    }

    public func createFolder(name: String, parentId: UUID? = nil) {
        let folder = BookmarkFolder(name: name, parentId: parentId)
        try? repository.insertFolder(folder)
        loadAll()
    }

    private func loadAll() {
        bookmarks = (try? repository.allBookmarks()) ?? []
        folders = (try? repository.allFolders()) ?? []
    }
}
