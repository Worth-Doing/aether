import Foundation
import SecureStorage
import AetherCore

public final class TavilyProvider: WebSearchProvider, @unchecked Sendable {
    public let providerType: SearchProviderType = .tavily
    private let keychain: KeychainManager
    private let session: URLSession

    private static let baseURL = "https://api.tavily.com"

    public init(keychain: KeychainManager) {
        self.keychain = keychain
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.httpMaximumConnectionsPerHost = 4
        self.session = URLSession(configuration: config)
    }

    public var isConfigured: Bool {
        keychain.exists(key: AppConstants.Keychain.tavilyApiKey)
    }

    private var apiKey: String? {
        try? keychain.loadString(key: AppConstants.Keychain.tavilyApiKey)
    }

    public func search(query: String, mode: SearchMode, maxResults: Int) async throws -> WebSearchResponse {
        guard let key = apiKey else {
            throw SearchProviderError.notConfigured(.tavily)
        }

        let start = Date()
        let url = URL(string: "\(Self.baseURL)/search")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

        let searchDepth: String
        let includeAnswer: Any
        switch mode {
        case .fast: searchDepth = "fast"; includeAnswer = false
        case .web, .images, .videos, .news: searchDepth = "basic"; includeAnswer = "basic"
        case .research: searchDepth = "advanced"; includeAnswer = "advanced"
        case .deep: searchDepth = "advanced"; includeAnswer = "advanced"
        }

        let body: [String: Any] = [
            "query": query,
            "search_depth": searchDepth,
            "max_results": min(maxResults, 20),
            "include_answer": includeAnswer,
            "include_images": false,
            "include_favicon": true
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SearchProviderError.networkError("Invalid response")
        }

        switch httpResponse.statusCode {
        case 200: break
        case 401: throw SearchProviderError.invalidAPIKey
        case 429: throw SearchProviderError.rateLimited
        default:
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SearchProviderError.serverError(httpResponse.statusCode, msg)
        }

        let decoded = try JSONDecoder().decode(TavilySearchResponse.self, from: data)
        let elapsed = Date().timeIntervalSince(start)

        let results = decoded.results.map { item in
            WebSearchResult(
                title: item.title,
                url: item.url,
                snippet: item.content,
                provider: .tavily,
                score: item.score,
                favicon: item.favicon,
                contentType: .webpage,
                rawContent: item.rawContent
            )
        }

        return WebSearchResponse(
            query: query,
            results: results,
            answer: decoded.answer,
            provider: .tavily,
            searchMode: mode,
            responseTime: decoded.responseTime ?? elapsed,
            totalResults: results.count
        )
    }

    public func validateAPIKey(_ key: String) async throws -> Bool {
        let url = URL(string: "\(Self.baseURL)/search")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "query": "test",
            "search_depth": "fast",
            "max_results": 1
        ])

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { return false }
        return httpResponse.statusCode == 200
    }
}

// MARK: - Response Models

private struct TavilySearchResponse: Decodable {
    let query: String?
    let answer: String?
    let results: [TavilyResult]
    let responseTime: TimeInterval?

    enum CodingKeys: String, CodingKey {
        case query, answer, results
        case responseTime = "response_time"
    }
}

private struct TavilyResult: Decodable {
    let title: String
    let url: String
    let content: String
    let score: Double?
    let rawContent: String?
    let favicon: String?

    enum CodingKeys: String, CodingKey {
        case title, url, content, score, favicon
        case rawContent = "raw_content"
    }
}
