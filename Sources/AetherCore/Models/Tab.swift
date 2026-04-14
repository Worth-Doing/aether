import Foundation
import AppKit

@Observable
public final class Tab: Identifiable {
    public let id: UUID
    public var url: URL?
    public var title: String
    public var favicon: NSImage?
    public var isLoading: Bool
    public var canGoBack: Bool
    public var canGoForward: Bool
    public var estimatedProgress: Double
    public var lastAccessed: Date
    public var workspaceId: UUID?

    public init(
        id: UUID = UUID(),
        url: URL? = nil,
        title: String = "New Tab",
        isLoading: Bool = false,
        workspaceId: UUID? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.favicon = nil
        self.isLoading = isLoading
        self.canGoBack = false
        self.canGoForward = false
        self.estimatedProgress = 0.0
        self.lastAccessed = Date()
        self.workspaceId = workspaceId
    }
}

extension Tab: Hashable {
    public static func == (lhs: Tab, rhs: Tab) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
