import Foundation
import SecureStorage
import AetherCore

public final class SerperProvider: WebSearchProvider, @unchecked Sendable {
    public let providerType: SearchProviderType = .serper
    private let keychain: KeychainManager
    private let session: URLSession

    private static let baseURL = "https://google.serper.dev"

    public init(keychain: KeychainManager) {
        self.keychain = keychain
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.httpMaximumConnectionsPerHost = 6
        self.session = URLSession(configuration: config)
    }

    public var isConfigured: Bool {
        keychain.exists(key: AppConstants.Keychain.serperApiKey)
    }

    private var apiKey: String? {
        try? keychain.loadString(key: AppConstants.Keychain.serperApiKey)
    }

    // MARK: - Main search (dispatches by mode)

    public func search(query: String, mode: SearchMode, maxResults: Int) async throws -> WebSearchResponse {
        guard let key = apiKey else {
            throw SearchProviderError.notConfigured(.serper)
        }

        let start = Date()

        switch mode {
        case .images:
            return try await searchImages(query: query, key: key, num: maxResults, start: start)
        case .videos:
            return try await searchVideos(query: query, key: key, num: maxResults, start: start)
        case .news:
            return try await searchNews(query: query, key: key, num: maxResults, start: start)
        case .web, .fast, .research, .deep:
            return try await searchWeb(query: query, key: key, num: maxResults, mode: mode, start: start)
        }
    }

    // MARK: - Web Search (/search)

    private func searchWeb(query: String, key: String, num: Int, mode: SearchMode, start: Date) async throws -> WebSearchResponse {
        let data = try await post(endpoint: "/search", key: key, body: [
            "q": query,
            "num": num
        ] as [String: Any])

        let decoded = try JSONDecoder().decode(SerperSearchResponse.self, from: data)
        let elapsed = Date().timeIntervalSince(start)

        let organic = (decoded.organic ?? []).map { item in
            WebSearchResult(
                title: item.title ?? "",
                url: item.link ?? "",
                snippet: item.snippet ?? "",
                provider: .serper,
                score: item.position.map { 1.0 - (Double($0) / 20.0) },
                contentType: .webpage
            )
        }

        var knowledgeGraph: KnowledgeGraphResult?
        if let kg = decoded.knowledgeGraph {
            var attrs: [String: String] = [:]
            if let dict = kg.attributes {
                for (k, v) in dict { attrs[k] = v }
            }
            knowledgeGraph = KnowledgeGraphResult(
                title: kg.title ?? "",
                type: kg.type,
                description: kg.description,
                imageUrl: kg.imageUrl,
                website: kg.website,
                attributes: attrs
            )
        }

        // For research/deep mode, also fetch images and news in parallel
        if mode == .research || mode == .deep {
            async let imageTask = fetchImages(query: query, key: key, num: 8)
            async let newsTask = fetchNews(query: query, key: key, num: 5)
            async let videoTask = fetchVideos(query: query, key: key, num: 4)
            let images = (try? await imageTask) ?? []
            let news = (try? await newsTask) ?? []
            let videos = (try? await videoTask) ?? []

            return WebSearchResponse(
                query: query,
                results: organic,
                imageResults: images,
                videoResults: videos,
                newsResults: news,
                answer: decoded.answerBox?.answer ?? decoded.answerBox?.snippet,
                knowledgeGraph: knowledgeGraph,
                provider: .serper,
                searchMode: mode,
                responseTime: Date().timeIntervalSince(start),
                totalResults: organic.count
            )
        }

        return WebSearchResponse(
            query: query,
            results: organic,
            answer: decoded.answerBox?.answer ?? decoded.answerBox?.snippet,
            knowledgeGraph: knowledgeGraph,
            provider: .serper,
            searchMode: mode,
            responseTime: elapsed,
            totalResults: organic.count
        )
    }

    // MARK: - Image Search (/images)

    private func searchImages(query: String, key: String, num: Int, start: Date) async throws -> WebSearchResponse {
        let images = try await fetchImages(query: query, key: key, num: num)
        let elapsed = Date().timeIntervalSince(start)

        return WebSearchResponse(
            query: query,
            imageResults: images,
            provider: .serper,
            searchMode: .images,
            responseTime: elapsed,
            totalResults: images.count
        )
    }

    private func fetchImages(query: String, key: String, num: Int) async throws -> [ImageSearchResult] {
        let data = try await post(endpoint: "/images", key: key, body: [
            "q": query,
            "num": num
        ] as [String: Any])

        let decoded = try JSONDecoder().decode(SerperImagesResponse.self, from: data)
        return (decoded.images ?? []).map { item in
            ImageSearchResult(
                title: item.title ?? "",
                imageUrl: item.imageUrl ?? "",
                thumbnailUrl: item.thumbnailUrl,
                sourceUrl: item.link ?? "",
                source: item.source ?? "",
                width: item.imageWidth,
                height: item.imageHeight,
                provider: .serper
            )
        }
    }

    // MARK: - Video Search (/videos)

    private func searchVideos(query: String, key: String, num: Int, start: Date) async throws -> WebSearchResponse {
        let videos = try await fetchVideos(query: query, key: key, num: num)
        let elapsed = Date().timeIntervalSince(start)

        return WebSearchResponse(
            query: query,
            videoResults: videos,
            provider: .serper,
            searchMode: .videos,
            responseTime: elapsed,
            totalResults: videos.count
        )
    }

    private func fetchVideos(query: String, key: String, num: Int) async throws -> [VideoSearchResult] {
        let data = try await post(endpoint: "/videos", key: key, body: [
            "q": query,
            "num": num
        ] as [String: Any])

        let decoded = try JSONDecoder().decode(SerperVideosResponse.self, from: data)
        return (decoded.videos ?? []).map { item in
            VideoSearchResult(
                title: item.title ?? "",
                url: item.link ?? "",
                thumbnailUrl: item.imageUrl,
                snippet: item.snippet ?? "",
                duration: item.duration,
                source: item.source ?? "",
                channel: item.channel,
                date: item.date,
                provider: .serper
            )
        }
    }

    // MARK: - News Search (/news)

    private func searchNews(query: String, key: String, num: Int, start: Date) async throws -> WebSearchResponse {
        let news = try await fetchNews(query: query, key: key, num: num)
        let elapsed = Date().timeIntervalSince(start)

        return WebSearchResponse(
            query: query,
            newsResults: news,
            provider: .serper,
            searchMode: .news,
            responseTime: elapsed,
            totalResults: news.count
        )
    }

    private func fetchNews(query: String, key: String, num: Int) async throws -> [NewsSearchResult] {
        let data = try await post(endpoint: "/news", key: key, body: [
            "q": query,
            "num": num
        ] as [String: Any])

        let decoded = try JSONDecoder().decode(SerperNewsResponse.self, from: data)
        return (decoded.news ?? []).map { item in
            NewsSearchResult(
                title: item.title ?? "",
                url: item.link ?? "",
                snippet: item.snippet ?? "",
                source: item.source ?? "",
                date: item.date,
                imageUrl: item.imageUrl,
                provider: .serper
            )
        }
    }

    // MARK: - Validate

    public func validateAPIKey(_ key: String) async throws -> Bool {
        do {
            _ = try await post(endpoint: "/search", key: key, body: [
                "q": "test",
                "num": 1
            ] as [String: Any])
            return true
        } catch SearchProviderError.invalidAPIKey {
            return false
        } catch {
            return false
        }
    }

    // MARK: - HTTP

    private func post(endpoint: String, key: String, body: [String: Any]) async throws -> Data {
        let url = URL(string: "\(Self.baseURL)\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "X-API-KEY")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SearchProviderError.networkError("Invalid response")
        }

        switch httpResponse.statusCode {
        case 200: return data
        case 401, 403: throw SearchProviderError.invalidAPIKey
        case 429: throw SearchProviderError.rateLimited
        default:
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SearchProviderError.serverError(httpResponse.statusCode, msg)
        }
    }
}

// MARK: - Response Models

private struct SerperSearchResponse: Decodable {
    let organic: [SerperOrganicResult]?
    let answerBox: SerperAnswerBox?
    let knowledgeGraph: SerperKnowledgeGraph?
    let peopleAlsoAsk: [SerperPeopleAlsoAsk]?
    let relatedSearches: [SerperRelatedSearch]?
}

private struct SerperOrganicResult: Decodable {
    let title: String?
    let link: String?
    let snippet: String?
    let position: Int?
    let date: String?
    let sitelinks: [SerperSitelink]?
}

private struct SerperSitelink: Decodable {
    let title: String?
    let link: String?
}

private struct SerperAnswerBox: Decodable {
    let answer: String?
    let snippet: String?
    let title: String?
    let link: String?
}

private struct SerperKnowledgeGraph: Decodable {
    let title: String?
    let type: String?
    let description: String?
    let imageUrl: String?
    let website: String?
    let attributes: [String: String]?
}

private struct SerperPeopleAlsoAsk: Decodable {
    let question: String?
    let snippet: String?
    let link: String?
}

private struct SerperRelatedSearch: Decodable {
    let query: String?
}

// Images
private struct SerperImagesResponse: Decodable {
    let images: [SerperImageResult]?
}

private struct SerperImageResult: Decodable {
    let title: String?
    let imageUrl: String?
    let imageWidth: Int?
    let imageHeight: Int?
    let thumbnailUrl: String?
    let link: String?
    let source: String?
    let domain: String?
}

// Videos
private struct SerperVideosResponse: Decodable {
    let videos: [SerperVideoResult]?
}

private struct SerperVideoResult: Decodable {
    let title: String?
    let link: String?
    let snippet: String?
    let imageUrl: String?
    let duration: String?
    let source: String?
    let channel: String?
    let date: String?
}

// News
private struct SerperNewsResponse: Decodable {
    let news: [SerperNewsResult]?
}

private struct SerperNewsResult: Decodable {
    let title: String?
    let link: String?
    let snippet: String?
    let date: String?
    let source: String?
    let imageUrl: String?
}
