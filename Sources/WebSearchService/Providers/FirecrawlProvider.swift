import Foundation
import SecureStorage
import AetherCore

public final class FirecrawlProvider: WebSearchProvider, @unchecked Sendable {
    public let providerType: SearchProviderType = .firecrawl
    private let keychain: KeychainManager
    private let session: URLSession

    private static let baseURL = "https://api.firecrawl.dev/v1"

    public init(keychain: KeychainManager) {
        self.keychain = keychain
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.httpMaximumConnectionsPerHost = 4
        self.session = URLSession(configuration: config)
    }

    public var isConfigured: Bool {
        keychain.exists(key: AppConstants.Keychain.firecrawlApiKey)
    }

    private var apiKey: String? {
        try? keychain.loadString(key: AppConstants.Keychain.firecrawlApiKey)
    }

    public func search(query: String, mode: SearchMode, maxResults: Int) async throws -> WebSearchResponse {
        guard let key = apiKey else {
            throw SearchProviderError.notConfigured(.firecrawl)
        }

        let start = Date()
        let url = URL(string: "\(Self.baseURL)/search")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "query": query,
            "limit": maxResults,
            "scrapeOptions": ["formats": ["markdown"]]
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

        let decoded = try JSONDecoder().decode(FirecrawlSearchResponse.self, from: data)
        let elapsed = Date().timeIntervalSince(start)

        let results = decoded.data.compactMap { item -> WebSearchResult? in
            guard let urlStr = item.url else { return nil }
            return WebSearchResult(
                title: item.title ?? item.metadata?.title ?? urlStr,
                url: urlStr,
                snippet: item.description ?? item.metadata?.description ?? item.markdown?.prefix(300).description ?? "",
                provider: .firecrawl,
                score: item.metadata?.score,
                favicon: item.metadata?.favicon,
                contentType: .webpage,
                rawContent: item.markdown
            )
        }

        return WebSearchResponse(
            query: query,
            results: results,
            provider: .firecrawl,
            searchMode: mode,
            responseTime: elapsed
        )
    }

    public func validateAPIKey(_ key: String) async throws -> Bool {
        let url = URL(string: "\(Self.baseURL)/scrape")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "url": "https://example.com",
            "formats": ["markdown"]
        ])

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { return false }
        return httpResponse.statusCode == 200
    }
}

// MARK: - Response Models

private struct FirecrawlSearchResponse: Decodable {
    let success: Bool?
    let data: [FirecrawlResult]
}

private struct FirecrawlResult: Decodable {
    let url: String?
    let title: String?
    let description: String?
    let markdown: String?
    let metadata: FirecrawlMetadata?
}

private struct FirecrawlMetadata: Decodable {
    let title: String?
    let description: String?
    let favicon: String?
    let score: Double?
}
