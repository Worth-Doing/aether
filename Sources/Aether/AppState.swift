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
    let workspaceRepository: WorkspaceRepository

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
        let workspaceRepo = WorkspaceRepository(database: database)
        self.historyRepository = historyRepo
        self.bookmarkRepository = bookmarkRepo
        self.embeddingRepository = embeddingRepo
        self.workspaceRepository = workspaceRepo

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

        // Load saved workspaces
        if let saved = try? workspaceRepo.loadAll() {
            self.workspaceManager.savedWorkspaces = saved
        }

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

        // Wire up history recording with semantic indexing
        setupHistoryRecording(
            tabStore: tabStore,
            historyManager: historyManager,
            semanticIndex: self.semanticIndex
        )
    }

    // MARK: - Session Persistence

    func saveSession() {
        let session = workspaceManager.getSessionState()
        try? workspaceRepository.save(session)

        // Also save all saved workspaces
        for workspace in workspaceManager.savedWorkspaces {
            try? workspaceRepository.save(workspace)
        }
    }

    // MARK: - Private

    private func setupHistoryRecording(
        tabStore: TabStore,
        historyManager: HistoryManager,
        semanticIndex: SemanticIndex?
    ) {
        for panel in tabStore.panels {
            for tab in panel.tabs {
                if let coordinator = tabStore.coordinator(for: tab.id) {
                    coordinator.onNavigationFinished = { [weak tab, weak historyManager] url, title in
                        tab?.url = url
                        if let title, !title.isEmpty {
                            tab?.title = title
                        }
                        tab?.isLoading = false

                        // Record in history
                        historyManager?.recordVisit(url: url, title: title)

                        // Index for semantic search if available
                        if let semanticIndex, let historyManager {
                            let entry = HistoryEntry(
                                url: url.absoluteString,
                                title: title,
                                sessionId: historyManager.sessionId
                            )
                            Task {
                                try? await semanticIndex.indexHistoryEntry(entry)
                            }
                        }
                    }

                    // Handle new tab requests from target="_blank" links
                    coordinator.onNewTabRequested = { [weak tabStore] url in
                        _ = tabStore?.createTab(url: url)
                    }
                }
            }
        }
    }
}
