import Foundation

/// Normalized search result from any provider
public struct WebSearchResult: Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public let url: String
    public let snippet: String
    public let provider: SearchProviderType
    public let score: Double?
    public let publishedDate: Date?
    public let favicon: String?
    public let domain: String
    public let contentType: ContentType?
    public let highlights: [String]
    public let rawContent: String?

    public init(
        id: UUID = UUID(),
        title: String,
        url: String,
        snippet: String,
        provider: SearchProviderType,
        score: Double? = nil,
        publishedDate: Date? = nil,
        favicon: String? = nil,
        contentType: ContentType? = nil,
        highlights: [String] = [],
        rawContent: String? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.snippet = snippet
        self.provider = provider
        self.score = score
        self.publishedDate = publishedDate
        self.favicon = favicon
        self.domain = URL(string: url)?.host() ?? url
        self.contentType = contentType
        self.highlights = highlights
        self.rawContent = rawContent
    }

    public enum ContentType: String, Hashable {
        case webpage
        case article
        case news
        case research
        case video
        case document
        case image
    }
}

/// Image search result
public struct ImageSearchResult: Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public let imageUrl: String
    public let thumbnailUrl: String?
    public let sourceUrl: String
    public let source: String
    public let domain: String
    public let width: Int?
    public let height: Int?
    public let provider: SearchProviderType

    public init(
        id: UUID = UUID(),
        title: String,
        imageUrl: String,
        thumbnailUrl: String? = nil,
        sourceUrl: String,
        source: String = "",
        width: Int? = nil,
        height: Int? = nil,
        provider: SearchProviderType
    ) {
        self.id = id
        self.title = title
        self.imageUrl = imageUrl
        self.thumbnailUrl = thumbnailUrl
        self.sourceUrl = sourceUrl
        self.source = source
        self.domain = URL(string: sourceUrl)?.host() ?? sourceUrl
        self.width = width
        self.height = height
        self.provider = provider
    }
}

/// Video search result
public struct VideoSearchResult: Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public let url: String
    public let thumbnailUrl: String?
    public let snippet: String
    public let duration: String?
    public let source: String
    public let channel: String?
    public let date: String?
    public let domain: String
    public let provider: SearchProviderType

    public init(
        id: UUID = UUID(),
        title: String,
        url: String,
        thumbnailUrl: String? = nil,
        snippet: String = "",
        duration: String? = nil,
        source: String = "",
        channel: String? = nil,
        date: String? = nil,
        provider: SearchProviderType
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.thumbnailUrl = thumbnailUrl
        self.snippet = snippet
        self.duration = duration
        self.source = source
        self.channel = channel
        self.date = date
        self.domain = URL(string: url)?.host() ?? url
        self.provider = provider
    }
}

/// News search result
public struct NewsSearchResult: Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public let url: String
    public let snippet: String
    public let source: String
    public let date: String?
    public let imageUrl: String?
    public let domain: String
    public let provider: SearchProviderType

    public init(
        id: UUID = UUID(),
        title: String,
        url: String,
        snippet: String = "",
        source: String = "",
        date: String? = nil,
        imageUrl: String? = nil,
        provider: SearchProviderType
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.snippet = snippet
        self.source = source
        self.date = date
        self.imageUrl = imageUrl
        self.domain = URL(string: url)?.host() ?? url
        self.provider = provider
    }
}

/// Represents a provider type
public enum SearchProviderType: String, CaseIterable, Identifiable, Codable, Hashable {
    case serper = "Serper"
    case firecrawl = "Firecrawl"
    case exa = "Exa"
    case tavily = "Tavily"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .serper: return "magnifyingglass.circle.fill"
        case .firecrawl: return "flame"
        case .exa: return "sparkle.magnifyingglass"
        case .tavily: return "brain.head.profile"
        }
    }

    public var color: String {
        switch self {
        case .serper: return "green"
        case .firecrawl: return "orange"
        case .exa: return "purple"
        case .tavily: return "blue"
        }
    }

    public var tagline: String {
        switch self {
        case .serper: return "Google Search API — Web, Images, Videos, News"
        case .firecrawl: return "Web Scraping & Extraction"
        case .exa: return "Neural Web Search"
        case .tavily: return "Research-Grade Search"
        }
    }

    public var description: String {
        switch self {
        case .serper:
            return "Fast Google Search API delivering rich results across web, images, videos, and news. Returns structured JSON with organic results, knowledge graphs, and related searches. The most comprehensive multi-format search provider."
        case .firecrawl:
            return "Powerful web scraping and crawling API. Extracts clean content from any webpage, supports full-site crawling, and returns LLM-ready data. Ideal for content extraction and data gathering workflows."
        case .exa:
            return "AI-native search engine using neural embeddings for relevance. Supports keyword, neural, and deep search modes with content highlights and summaries. Best for discovering semantically relevant content."
        case .tavily:
            return "Research-oriented search API with built-in answer generation. Offers multiple search depths from ultra-fast to advanced, with domain filtering and time-range controls. Optimized for research and fact-finding."
        }
    }

    public var keychainKey: String {
        switch self {
        case .serper: return "serper-api-key"
        case .firecrawl: return "firecrawl-api-key"
        case .exa: return "exa-api-key"
        case .tavily: return "tavily-api-key"
        }
    }

    public var enabledKey: String {
        switch self {
        case .serper: return "serperEnabled"
        case .firecrawl: return "firecrawlEnabled"
        case .exa: return "exaEnabled"
        case .tavily: return "tavilyEnabled"
        }
    }

    /// Whether this provider supports image/video/news results natively
    public var supportsRichMedia: Bool {
        switch self {
        case .serper: return true
        case .firecrawl, .exa, .tavily: return false
        }
    }
}

/// Search mode determines how search is performed
public enum SearchMode: String, CaseIterable, Identifiable, Codable {
    case web = "Web"
    case images = "Images"
    case videos = "Videos"
    case news = "News"
    case research = "Research"
    case fast = "Fast"
    case deep = "Deep"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .web: return "globe"
        case .images: return "photo"
        case .videos: return "play.rectangle"
        case .news: return "newspaper"
        case .research: return "book"
        case .fast: return "bolt"
        case .deep: return "magnifyingglass.circle"
        }
    }

    public var subtitle: String {
        switch self {
        case .web: return "Standard web search"
        case .images: return "Find images"
        case .videos: return "Find videos"
        case .news: return "Latest news"
        case .research: return "Thorough with answers"
        case .fast: return "Quick results"
        case .deep: return "Comprehensive analysis"
        }
    }
}

/// Aggregated search response with rich media
public struct WebSearchResponse {
    public let query: String
    public let results: [WebSearchResult]
    public let imageResults: [ImageSearchResult]
    public let videoResults: [VideoSearchResult]
    public let newsResults: [NewsSearchResult]
    public let answer: String?
    public let knowledgeGraph: KnowledgeGraphResult?
    public let provider: SearchProviderType
    public let searchMode: SearchMode
    public let responseTime: TimeInterval
    public let totalResults: Int

    public init(
        query: String,
        results: [WebSearchResult] = [],
        imageResults: [ImageSearchResult] = [],
        videoResults: [VideoSearchResult] = [],
        newsResults: [NewsSearchResult] = [],
        answer: String? = nil,
        knowledgeGraph: KnowledgeGraphResult? = nil,
        provider: SearchProviderType,
        searchMode: SearchMode,
        responseTime: TimeInterval,
        totalResults: Int? = nil
    ) {
        self.query = query
        self.results = results
        self.imageResults = imageResults
        self.videoResults = videoResults
        self.newsResults = newsResults
        self.answer = answer
        self.knowledgeGraph = knowledgeGraph
        self.provider = provider
        self.searchMode = searchMode
        self.responseTime = responseTime
        self.totalResults = totalResults ?? results.count
    }

    /// Whether this response has any rich media results
    public var hasRichMedia: Bool {
        !imageResults.isEmpty || !videoResults.isEmpty || !newsResults.isEmpty
    }
}

/// Knowledge graph data from Google
public struct KnowledgeGraphResult: Hashable {
    public let title: String
    public let type: String?
    public let description: String?
    public let imageUrl: String?
    public let website: String?
    public let attributes: [String: String]

    public init(
        title: String,
        type: String? = nil,
        description: String? = nil,
        imageUrl: String? = nil,
        website: String? = nil,
        attributes: [String: String] = [:]
    ) {
        self.title = title
        self.type = type
        self.description = description
        self.imageUrl = imageUrl
        self.website = website
        self.attributes = attributes
    }
}
