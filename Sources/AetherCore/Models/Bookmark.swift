import Foundation

public struct Bookmark: Identifiable, Codable {
    public let id: UUID
    public var url: String
    public var title: String
    public var folderId: UUID?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        url: String,
        title: String,
        folderId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.folderId = folderId
        self.createdAt = createdAt
    }
}

public struct BookmarkFolder: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var parentId: UUID?

    public init(
        id: UUID = UUID(),
        name: String,
        parentId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.parentId = parentId
    }
}
