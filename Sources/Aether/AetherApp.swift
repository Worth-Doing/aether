import SwiftUI
import AetherCore
import AetherUI
import TabManager
import PanelSystem
import HistoryEngine
import BookmarkEngine
import CommandBar
import AIService
import SemanticEngine
import Onboarding
import Settings
import SecureStorage
import Persistence
import WebSearchService

@main
struct AetherApp: App {
    @State private var hasCompletedOnboarding: Bool = false
    @State private var appState: AppState?
    @AppStorage("themeMode") private var themeModeRaw: String = ThemeMode.light.rawValue

    private var themeMode: ThemeMode {
        ThemeMode(rawValue: themeModeRaw) ?? .light
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let state = appState {
                    if hasCompletedOnboarding {
                        ContentView(
                            tabStore: state.tabStore,
                            workspaceManager: state.workspaceManager,
                            historyManager: state.historyManager,
                            bookmarkManager: state.bookmarkManager,
                            commandBarState: state.commandBarState,
                            openRouterClient: state.openRouterClient,
                            semanticIndex: state.semanticIndex,
                            searchManager: state.searchManager,
                            keychain: state.keychain
                        )
                    } else {
                        OnboardingView(
                            openRouterClient: state.openRouterClient
                        ) {
                            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                            withAnimation(AetherTheme.Animation.standard) {
                                hasCompletedOnboarding = true
                            }
                        }
                    }
                } else {
                    ProgressView("Starting Aether...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AetherTheme.Colors.background)
                }
            }
            .preferredColorScheme(themeMode.colorScheme)
            .onAppear {
                initializeApp()
            }
            .onDisappear {
                appState?.saveSession()
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1400, height: 900)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    _ = appState?.tabStore.createTab()
                }
                .keyboardShortcut("t", modifiers: .command)

                Button("Close Tab") {
                    if let tabId = appState?.tabStore.activeTab?.id {
                        appState?.tabStore.closeTab(tabId)
                    }
                }
                .keyboardShortcut("w", modifiers: .command)

                Button("Reopen Closed Tab") {
                    appState?.tabStore.reopenLastClosedTab()
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])

                Divider()

                Button("New Workspace") {
                    appState?.workspaceManager.createNewWorkspace()
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }

            CommandMenu("View") {
                Button("Split Panel Horizontally") {
                    if let panelId = appState?.tabStore.activePanelId {
                        appState?.workspaceManager.splitPanel(panelId, axis: .horizontal)
                    }
                }
                .keyboardShortcut("\\", modifiers: .command)

                Button("Split Panel Vertically") {
                    if let panelId = appState?.tabStore.activePanelId {
                        appState?.workspaceManager.splitPanel(panelId, axis: .vertical)
                    }
                }
                .keyboardShortcut("\\", modifiers: [.command, .shift])

                Divider()

                Button("Zoom In") {
                    if let tabId = appState?.tabStore.activeTab?.id,
                       let coord = appState?.tabStore.coordinator(for: tabId) {
                        coord.zoomIn()
                    }
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Zoom Out") {
                    if let tabId = appState?.tabStore.activeTab?.id,
                       let coord = appState?.tabStore.coordinator(for: tabId) {
                        coord.zoomOut()
                    }
                }
                .keyboardShortcut("-", modifiers: .command)

                Button("Reset Zoom") {
                    if let tabId = appState?.tabStore.activeTab?.id,
                       let coord = appState?.tabStore.coordinator(for: tabId) {
                        coord.zoomReset()
                    }
                }
                .keyboardShortcut("0", modifiers: .command)
            }

            CommandMenu("Navigate") {
                Button("Focus Address Bar") {
                    appState?.commandBarState.show()
                }
                .keyboardShortcut("l", modifiers: .command)

                Button("Command Palette") {
                    appState?.commandBarState.show()
                }
                .keyboardShortcut("k", modifiers: .command)

                Divider()

                Button("Back") {
                    if let tabId = appState?.tabStore.activeTab?.id,
                       let coord = appState?.tabStore.coordinator(for: tabId) {
                        coord.goBack()
                    }
                }
                .keyboardShortcut("[", modifiers: .command)

                Button("Forward") {
                    if let tabId = appState?.tabStore.activeTab?.id,
                       let coord = appState?.tabStore.coordinator(for: tabId) {
                        coord.goForward()
                    }
                }
                .keyboardShortcut("]", modifiers: .command)

                Button("Reload") {
                    if let tabId = appState?.tabStore.activeTab?.id,
                       let coord = appState?.tabStore.coordinator(for: tabId) {
                        coord.reload()
                    }
                }
                .keyboardShortcut("r", modifiers: .command)
            }

            CommandMenu("Edit") {
                Button("Find in Page") {
                    NotificationCenter.default.post(name: .toggleFindBar, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
            }
        }

        Settings {
            if let state = appState {
                SettingsView(
                    openRouterClient: state.openRouterClient,
                    searchManager: state.searchManager,
                    keychain: state.keychain,
                    historyManager: state.historyManager,
                    bookmarkManager: state.bookmarkManager
                )
                .preferredColorScheme(themeMode.colorScheme)
            } else {
                ProgressView()
                    .frame(width: 500, height: 400)
            }
        }
    }

    private func initializeApp() {
        guard appState == nil else { return }

        do {
            let state = try AppState()
            self.appState = state
            self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        } catch {
            print("Failed to initialize Aether: \(error)")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let toggleFindBar = Notification.Name("aether.toggleFindBar")
    static let toggleSidebar = Notification.Name("aether.toggleSidebar")
}
