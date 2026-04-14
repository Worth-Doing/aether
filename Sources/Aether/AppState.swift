import Foundation
import AetherCore
import TabManager
import PanelSystem
import HistoryEngine
import BookmarkEngine
import CommandBar
import AIService
import SemanticEngine
import SecureStorage
import Persistence

@Observable
final class AppState {
    let database: Database
    let keychain: KeychainManager
    let openRouterClient: OpenRouterClient

    let historyRepository: HistoryRepository
    let bookmarkRepository: BookmarkRepository
    let embeddingRepository: EmbeddingRepository

    let tabStore: TabStore
    let workspaceManager: WorkspaceManager
    let historyManager: HistoryManager
    let bookmarkManager: BookmarkManager
    let commandBarState: CommandBarState

    let semanticIndex: SemanticIndex?

    init() throws {
        // Initialize persistence
        let dbPath = AppConstants.Database.fileURL.path
        let database = try Database(path: dbPath)
        self.database = database

        // Run migrations
        let migrationRunner = MigrationRunner(database: database)
        try migrationRunner.runAll()

        // Repositories
        let historyRepo = HistoryRepository(database: database)
        let bookmarkRepo = BookmarkRepository(database: database)
        let embeddingRepo = EmbeddingRepository(database: database)
        self.historyRepository = historyRepo
        self.bookmarkRepository = bookmarkRepo
        self.embeddingRepository = embeddingRepo

        // Secure storage
        let keychain = KeychainManager(service: AppConstants.Keychain.serviceName)
        self.keychain = keychain

        // AI service
        let openRouter = OpenRouterClient(keychain: keychain)
        self.openRouterClient = openRouter

        // Tab & workspace
        let tabStore = TabStore()
        self.tabStore = tabStore
        self.workspaceManager = WorkspaceManager(tabStore: tabStore)

        // History & bookmarks
        let historyManager = HistoryManager(repository: historyRepo)
        self.historyManager = historyManager
        self.bookmarkManager = BookmarkManager(repository: bookmarkRepo)

        // Command bar
        self.commandBarState = CommandBarState()

        // Semantic index (only if AI is configured)
        if openRouter.isConfigured {
            self.semanticIndex = SemanticIndex(
                embeddingService: openRouter,
                embeddingRepository: embeddingRepo,
                historyRepository: historyRepo,
                bookmarkRepository: bookmarkRepo
            )
        } else {
            self.semanticIndex = nil
        }

        // Wire up history recording
        setupHistoryRecording(tabStore: tabStore, historyManager: historyManager)
    }

    private func setupHistoryRecording(tabStore: TabStore, historyManager: HistoryManager) {
        // We set up navigation callbacks on each tab's coordinator
        // This is called when the tab store creates tabs, through binding
        for panel in tabStore.panels {
            for tab in panel.tabs {
                if let coordinator = tabStore.coordinator(for: tab.id) {
                    let sessionId = historyManager.sessionId
                    coordinator.onNavigationFinished = { [weak tab, weak historyManager] url, title in
                        tab?.url = url
                        if let title, !title.isEmpty {
                            tab?.title = title
                        }
                        tab?.isLoading = false
                        historyManager?.recordVisit(url: url, title: title)
                    }
                }
            }
        }
    }
}
