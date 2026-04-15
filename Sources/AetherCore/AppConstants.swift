import Foundation

public enum AppConstants {
    public static let appName = "Aether"
    public static let bundleIdentifier = "com.aether.browser"
    public static let version = "1.0.0"

    public enum Defaults {
        public static let llmModel = "anthropic/claude-sonnet-4"
        public static let embeddingModel = "openai/text-embedding-3-small"
        public static let newTabTitle = "New Tab"
        public static let defaultWorkspaceName = "Default"
        public static let defaultSearchEngine = "DuckDuckGo"
        public static let defaultThemeMode = "Light"
    }

    public enum Keychain {
        public static let serviceName = "com.aether.browser"
        public static let apiKeyAccount = "openrouter-api-key"
        public static let serperApiKey = "serper-api-key"
        public static let firecrawlApiKey = "firecrawl-api-key"
        public static let exaApiKey = "exa-api-key"
        public static let tavilyApiKey = "tavily-api-key"
    }

    public enum Database {
        public static let fileName = "aether.db"
        public static var directoryURL: URL {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            return appSupport.appendingPathComponent("Aether")
        }
        public static var fileURL: URL {
            directoryURL.appendingPathComponent(fileName)
        }
    }

    public enum OpenRouter {
        public static let baseURL = "https://openrouter.ai/api/v1"
        public static let chatEndpoint = "/chat/completions"
        public static let embeddingsEndpoint = "/embeddings"
        public static let httpReferer = "https://aether-browser.app"
        public static let appTitle = "Aether Browser"
    }

    public enum UserDefaultsKeys {
        public static let hasCompletedOnboarding = "hasCompletedOnboarding"
        public static let themeMode = "themeMode"
        public static let searchEngine = "searchEngine"
        public static let llmModel = "llmModel"
        public static let embeddingModel = "embeddingModel"
        public static let homePage = "homePage"
        public static let restoreSession = "restoreSession"
        public static let showStatusBar = "showStatusBar"
        public static let serperEnabled = "serperEnabled"
        public static let firecrawlEnabled = "firecrawlEnabled"
        public static let exaEnabled = "exaEnabled"
        public static let tavilyEnabled = "tavilyEnabled"
        public static let defaultSearchProvider = "defaultSearchProvider"
        public static let searchMode = "searchMode"
    }
}
