import Foundation
import SecureStorage
import AetherCore

public final class ExaProvider: WebSearchProvider, @unchecked Sendable {
    public let providerType: SearchProviderType = .exa
    private let keychain: KeychainManager
    private let session: URLSession

    private static let baseURL = "https://api.exa.ai"

    public init(keychain: KeychainManager) {
        self.keychain = keychain
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.httpMaximumConnectionsPerHost = 4
        self.session = URLSession(configuration: config)
    }

    public var isConfigured: Bool {
        keychain.exists(key: AppConstants.Keychain.exaApiKey)
    }

    private var apiKey: String? {
        try? keychain.loadString(key: AppConstants.Keychain.exaApiKey)
    }

    public func search(query: String, mode: SearchMode, maxResults: Int) async throws -> WebSearchResponse {
        guard let key = apiKey else {
            throw SearchProviderError.notConfigured(.exa)
        }

        let start = Date()
        let url = URL(string: "\(Self.baseURL)/search")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "x-api-key")

        let searchType: String
        switch mode {
        case .fast: searchType = "fast"
        case .deep: searchType = "deep"
        case .research: searchType = "auto"
        case .web, .images, .videos, .news: searchType = "auto"
        }

        var body: [String: Any] = [
            "query": query,
            "numResults": maxResults,
            "type": searchType,
            "contents": [
                "text": ["maxCharacters": 1200],
                "highlights": ["maxCharacters": 300, "numSentences": 3]
            ] as [String: Any]
        ]

        if mode == .research {
            body["contents"] = [
                "text": ["maxCharacters": 2000],
                "highlights": ["maxCharacters": 500, "numSentences": 5],
                "summary": ["query": query]
            ] as [String: Any]
        }

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

        let decoded = try JSONDecoder().decode(ExaSearchResponse.self, from: data)
        let elapsed = Date().timeIntervalSince(start)

        let results = decoded.results.map { item in
            WebSearchResult(
                title: item.title ?? item.url,
                url: item.url,
                snippet: item.summary ?? item.text?.prefix(300).description ?? item.highlights?.first ?? "",
                provider: .exa,
                score: item.score,
                publishedDate: parseDate(item.publishedDate),
                favicon: item.favicon,
                contentType: .webpage,
                highlights: item.highlights ?? [],
                rawContent: item.text
            )
        }

        return WebSearchResponse(
            query: query,
            results: results,
            answer: decoded.output?.content,
            provider: .exa,
            searchMode: mode,
            responseTime: elapsed
        )
    }

    public func validateAPIKey(_ key: String) async throws -> Bool {
        let url = URL(string: "\(Self.baseURL)/search")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "query": "test",
            "numResults": 1,
            "type": "instant"
        ])

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { return false }
        return httpResponse.statusCode == 200
    }

    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString)
    }
}

// MARK: - Response Models

private struct ExaSearchResponse: Decodable {
    let results: [ExaResult]
    let output: ExaOutput?
}

private struct ExaResult: Decodable {
    let url: String
    let title: String?
    let text: String?
    let highlights: [String]?
    let summary: String?
    let publishedDate: String?
    let favicon: String?
    let score: Double?
    let image: String?
}

private struct ExaOutput: Decodable {
    let content: String?
}
