import Foundation

public enum EmbeddingSourceType: String, Codable, Sendable {
    case history
    case bookmark
    case snippet
}

public struct EmbeddingRecord: Identifiable, Codable {
    public let id: UUID
    public var sourceType: EmbeddingSourceType
    public var sourceId: UUID
    public var vector: [Float]
    public var textContent: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        sourceType: EmbeddingSourceType,
        sourceId: UUID,
        vector: [Float],
        textContent: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sourceType = sourceType
        self.sourceId = sourceId
        self.vector = vector
        self.textContent = textContent
        self.createdAt = createdAt
    }
}
