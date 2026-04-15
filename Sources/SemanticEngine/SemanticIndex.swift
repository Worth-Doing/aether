import Foundation
import AetherCore
import AIService
import Persistence
import Accelerate

public actor SemanticIndex: SemanticSearchable {
    private let embeddingService: EmbeddingService
    private let repository: EmbeddingRepository
    private let historyRepository: HistoryRepository
    private let bookmarkRepository: BookmarkRepository

    public init(
        embeddingService: EmbeddingService,
        embeddingRepository: EmbeddingRepository,
        historyRepository: HistoryRepository,
        bookmarkRepository: BookmarkRepository
    ) {
        self.embeddingService = embeddingService
        self.repository = embeddingRepository
        self.historyRepository = historyRepository
        self.bookmarkRepository = bookmarkRepository
    }

    // MARK: - Indexing

    public func indexHistoryEntry(_ entry: HistoryEntry) async throws {
        let text = [entry.title, entry.url].compactMap { $0 }.joined(separator: " — ")
        guard !text.isEmpty else { return }

        let vectors = try await embeddingService.embed(texts: [text], model: nil)
        guard let vector = vectors.first else { return }

        let record = EmbeddingRecord(
            sourceType: .history,
            sourceId: entry.id,
            vector: vector,
            textContent: text
        )
        try repository.insert(record)
    }

    public func indexBookmark(_ bookmark: Bookmark) async throws {
        let text = "\(bookmark.title) — \(bookmark.url)"
        let vectors = try await embeddingService.embed(texts: [text], model: nil)
        guard let vector = vectors.first else { return }

        let record = EmbeddingRecord(
            sourceType: .bookmark,
            sourceId: bookmark.id,
            vector: vector,
            textContent: text
        )
        try repository.insert(record)
    }

    // MARK: - Search

    public nonisolated func search(query: String, limit: Int) async throws -> [SemanticResult] {
        let queryVectors = try await embeddingService.embed(texts: [query], model: nil)
        guard let queryVector = queryVectors.first else { return [] }

        let allEmbeddings = try repository.allEmbeddings()
        guard !allEmbeddings.isEmpty else { return [] }

        var scored: [(record: EmbeddingRecord, score: Float)] = []
        for record in allEmbeddings {
            let similarity = cosineSimilarityAccelerate(queryVector, record.vector)
            scored.append((record, similarity))
        }

        scored.sort { $0.score > $1.score }
        let topResults = scored.prefix(limit)

        return topResults.map { item in
            let parts = item.record.textContent.components(separatedBy: " — ")
            let title = parts.first ?? ""
            let url = parts.count > 1 ? parts[1] : ""
            return SemanticResult(
                sourceType: item.record.sourceType,
                sourceId: item.record.sourceId,
                title: title,
                url: url,
                score: item.score
            )
        }
    }

    // MARK: - Vector Math (Accelerate-optimized)

    private nonisolated func cosineSimilarityAccelerate(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }

        var dot: Float = 0
        var normA: Float = 0
        var normB: Float = 0

        vDSP_dotpr(a, 1, b, 1, &dot, vDSP_Length(a.count))
        vDSP_dotpr(a, 1, a, 1, &normA, vDSP_Length(a.count))
        vDSP_dotpr(b, 1, b, 1, &normB, vDSP_Length(b.count))

        let denom = sqrt(normA) * sqrt(normB)
        guard denom > 0 else { return 0 }
        return dot / denom
    }
}
