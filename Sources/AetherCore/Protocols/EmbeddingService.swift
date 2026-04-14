import Foundation

public protocol EmbeddingService: Sendable {
    func embed(texts: [String], model: String?) async throws -> [[Float]]
}

extension EmbeddingService {
    public func embed(text: String) async throws -> [Float] {
        let results = try await embed(texts: [text], model: nil)
        guard let first = results.first else {
            throw EmbeddingError.emptyResponse
        }
        return first
    }
}

public enum EmbeddingError: Error, LocalizedError {
    case emptyResponse
    case invalidDimensions

    public var errorDescription: String? {
        switch self {
        case .emptyResponse: return "Embedding service returned no vectors"
        case .invalidDimensions: return "Embedding dimensions mismatch"
        }
    }
}
