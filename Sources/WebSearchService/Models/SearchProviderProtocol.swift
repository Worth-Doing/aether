import Foundation

/// Protocol for web search providers
public protocol WebSearchProvider: Sendable {
    var providerType: SearchProviderType { get }
    var isConfigured: Bool { get }

    func search(
        query: String,
        mode: SearchMode,
        maxResults: Int
    ) async throws -> WebSearchResponse

    func validateAPIKey(_ key: String) async throws -> Bool
}

/// Errors from search providers
public enum SearchProviderError: Error, LocalizedError {
    case notConfigured(SearchProviderType)
    case invalidAPIKey
    case rateLimited
    case networkError(String)
    case decodingError(String)
    case serverError(Int, String)
    case noResults

    public var errorDescription: String? {
        switch self {
        case .notConfigured(let provider):
            return "\(provider.rawValue) is not configured. Add your API key in Settings."
        case .invalidAPIKey:
            return "The API key is invalid. Please check and try again."
        case .rateLimited:
            return "Rate limit exceeded. Please wait a moment before trying again."
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .decodingError(let msg):
            return "Failed to parse response: \(msg)"
        case .serverError(let code, let msg):
            return "Server error (\(code)): \(msg)"
        case .noResults:
            return "No results found for your query."
        }
    }
}
