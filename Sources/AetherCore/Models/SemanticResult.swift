import Foundation

public struct SemanticResult: Identifiable {
    public let id: UUID
    public let sourceType: EmbeddingSourceType
    public let sourceId: UUID
    public let title: String
    public let url: String
    public let score: Float

    public init(
        id: UUID = UUID(),
        sourceType: EmbeddingSourceType,
        sourceId: UUID,
        title: String,
        url: String,
        score: Float
    ) {
        self.id = id
        self.sourceType = sourceType
        self.sourceId = sourceId
        self.title = title
        self.url = url
        self.score = score
    }
}
