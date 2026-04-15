import Foundation
import SwiftUI
import SecureStorage
import AetherCore

/// Central search orchestrator managing providers, caching, and state
@Observable
public final class SearchManager {
    public private(set) var providers: [SearchProviderType: any WebSearchProvider] = [:]
    public private(set) var isSearching = false
    public private(set) var currentResponse: WebSearchResponse?
    public private(set) var error: SearchProviderError?
    public private(set) var searchHistory: [SearchHistoryEntry] = []

    private let keychain: KeychainManager
    private let cache = SearchCache()

    public init(keychain: KeychainManager) {
        self.keychain = keychain
        setupProviders()
    }

    private func setupProviders() {
        providers[.serper] = SerperProvider(keychain: keychain)
        providers[.firecrawl] = FirecrawlProvider(keychain: keychain)
        providers[.exa] = ExaProvider(keychain: keychain)
        providers[.tavily] = TavilyProvider(keychain: keychain)
    }

    /// All configured (have API key) providers
    public var configuredProviders: [SearchProviderType] {
        providers.filter { $0.value.isConfigured }.map { $0.key }
    }

    /// The default provider to use, or first configured
    public var activeProvider: SearchProviderType? {
        let stored = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.defaultSearchProvider)
        if let stored, let type = SearchProviderType(rawValue: stored),
           providers[type]?.isConfigured == true {
            return type
        }
        return configuredProviders.first
    }

    public func isProviderConfigured(_ type: SearchProviderType) -> Bool {
        providers[type]?.isConfigured ?? false
    }

    // MARK: - API Key Management

    public func saveAPIKey(_ key: String, for provider: SearchProviderType) throws {
        try keychain.save(key: provider.keychainKey, string: key)
        UserDefaults.standard.set(true, forKey: provider.enabledKey)
        setupProviders()
    }

    public func removeAPIKey(for provider: SearchProviderType) throws {
        try keychain.delete(key: provider.keychainKey)
        UserDefaults.standard.set(false, forKey: provider.enabledKey)
        setupProviders()
    }

    public func validateAPIKey(_ key: String, for provider: SearchProviderType) async throws -> Bool {
        guard let p = providers[provider] else { return false }
        return try await p.validateAPIKey(key)
    }

    // MARK: - Search

    @MainActor
    public func search(
        query: String,
        provider: SearchProviderType? = nil,
        mode: SearchMode = .web,
        maxResults: Int = 10
    ) async {
        let targetProvider = provider ?? activeProvider
        guard let targetProvider,
              let searchProvider = providers[targetProvider] else {
            self.error = .notConfigured(provider ?? .tavily)
            return
        }

        // Check cache
        let cacheKey = SearchCache.Key(query: query, provider: targetProvider, mode: mode)
        if let cached = cache.get(cacheKey) {
            self.currentResponse = cached
            self.error = nil
            return
        }

        isSearching = true
        error = nil

        do {
            let response = try await searchProvider.search(
                query: query,
                mode: mode,
                maxResults: maxResults
            )

            self.currentResponse = response
            self.isSearching = false

            // Cache the response
            cache.set(cacheKey, response: response)

            // Record in search history
            searchHistory.insert(
                SearchHistoryEntry(query: query, provider: targetProvider, mode: mode, resultCount: response.results.count),
                at: 0
            )
            if searchHistory.count > 50 { searchHistory = Array(searchHistory.prefix(50)) }

        } catch let err as SearchProviderError {
            self.error = err
            self.isSearching = false
        } catch {
            self.error = .networkError(error.localizedDescription)
            self.isSearching = false
        }
    }

    @MainActor
    public func clearResults() {
        currentResponse = nil
        error = nil
        isSearching = false
    }
}

// MARK: - Search History Entry

public struct SearchHistoryEntry: Identifiable {
    public let id = UUID()
    public let query: String
    public let provider: SearchProviderType
    public let mode: SearchMode
    public let resultCount: Int
    public let timestamp: Date

    public init(query: String, provider: SearchProviderType, mode: SearchMode, resultCount: Int) {
        self.query = query
        self.provider = provider
        self.mode = mode
        self.resultCount = resultCount
        self.timestamp = Date()
    }
}

// MARK: - Search Cache

final class SearchCache {
    struct Key: Hashable {
        let query: String
        let provider: SearchProviderType
        let mode: SearchMode
    }

    private struct Entry {
        let response: WebSearchResponse
        let timestamp: Date
    }

    private var store: [Key: Entry] = [:]
    private let ttl: TimeInterval = 300 // 5 minutes

    func get(_ key: Key) -> WebSearchResponse? {
        guard let entry = store[key],
              Date().timeIntervalSince(entry.timestamp) < ttl else {
            store.removeValue(forKey: key)
            return nil
        }
        return entry.response
    }

    func set(_ key: Key, response: WebSearchResponse) {
        // Evict old entries
        let cutoff = Date().addingTimeInterval(-ttl)
        store = store.filter { $0.value.timestamp > cutoff }
        store[key] = Entry(response: response, timestamp: Date())
    }

    func clear() {
        store.removeAll()
    }
}
