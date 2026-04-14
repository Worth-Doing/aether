import Foundation

public protocol SemanticSearchable {
    func search(query: String, limit: Int) async throws -> [SemanticResult]
}
