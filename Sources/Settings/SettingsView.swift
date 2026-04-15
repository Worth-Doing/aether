import SwiftUI
import AetherCore
import AetherUI
import AIService
import SecureStorage
import HistoryEngine
import BookmarkEngine

public struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var isValidating: Bool = false
    @State private var validationMessage: String?
    @State private var hasKey: Bool = false
    @State private var selectedTab: SettingsTab = .general

    @AppStorage(AppConstants.UserDefaultsKeys.themeMode) private var themeMode = AppConstants.Defaults.defaultThemeMode
    @AppStorage(AppConstants.UserDefaultsKeys.searchEngine) private var searchEngine = AppConstants.Defaults.defaultSearchEngine
    @AppStorage(AppConstants.UserDefaultsKeys.llmModel) private var llmModel = AppConstants.Defaults.llmModel
    @AppStorage(AppConstants.UserDefaultsKeys.embeddingModel) private var embeddingModel = AppConstants.Defaults.embeddingModel
    @AppStorage(AppConstants.UserDefaultsKeys.homePage) private var homePage = ""
    @AppStorage(AppConstants.UserDefaultsKeys.restoreSession) private var restoreSession = true
    @AppStorage(AppConstants.UserDefaultsKeys.showStatusBar) private var showStatusBar = true

    @State private var showClearHistoryConfirm = false
    @State private var showClearBookmarksConfirm = false

    let openRouterClient: OpenRouterClient
    var historyManager: HistoryManager?
    var bookmarkManager: BookmarkManager?

    public init(
        openRouterClient: OpenRouterClient,
        historyManager: HistoryManager? = nil,
        bookmarkManager: BookmarkManager? = nil
    ) {
        self.openRouterClient = openRouterClient
        self.historyManager = historyManager
        self.bookmarkManager = bookmarkManager
    }

    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case appearance = "Appearance"
        case ai = "AI"
        case privacy = "Privacy & Data"
        case about = "About"

        var icon: String {
            switch self {
            case .general: return "gear"
            case .appearance: return "paintbrush"
            case .ai: return "sparkles"
            case .privacy: return "hand.raised"
            case .about: return "info.circle"
            }
        }
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            generalTab
                .tabItem {
                    Label(SettingsTab.general.rawValue, systemImage: SettingsTab.general.icon)
                }
                .tag(SettingsTab.general)

            appearanceTab
                .tabItem {
                    Label(SettingsTab.appearance.rawValue, systemImage: SettingsTab.appearance.icon)
                }
                .tag(SettingsTab.appearance)

            aiTab
                .tabItem {
                    Label(SettingsTab.ai.rawValue, systemImage: SettingsTab.ai.icon)
                }
                .tag(SettingsTab.ai)

            privacyTab
                .tabItem {
                    Label(SettingsTab.privacy.rawValue, systemImage: SettingsTab.privacy.icon)
                }
                .tag(SettingsTab.privacy)

            aboutTab
                .tabItem {
                    Label(SettingsTab.about.rawValue, systemImage: SettingsTab.about.icon)
                }
                .tag(SettingsTab.about)
        }
        .frame(width: 520, height: 420)
        .onAppear {
            hasKey = openRouterClient.isConfigured
        }
    }

    // MARK: - General

    private var generalTab: some View {
        Form {
            Section("Search") {
                Picker("Search Engine", selection: $searchEngine) {
                    ForEach(SearchEngine.allCases) { engine in
                        Label(engine.rawValue, systemImage: engine.icon)
                            .tag(engine.rawValue)
                    }
                }
                .pickerStyle(.menu)

                TextField("Home Page", text: $homePage, prompt: Text("Leave empty for new tab page"))
                    .textFieldStyle(.roundedBorder)
            }

            Section("Behavior") {
                Toggle("Restore previous session on launch", isOn: $restoreSession)
                Toggle("Show status bar", isOn: $showStatusBar)
            }
        }
        .formStyle(.grouped)
        .padding(.top, AetherTheme.Spacing.md)
    }

    // MARK: - Appearance

    private var appearanceTab: some View {
        Form {
            Section("Theme") {
                Picker("Appearance", selection: $themeMode) {
                    ForEach(ThemeMode.allCases) { mode in
                        Label(mode.rawValue, systemImage: mode.icon)
                            .tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                Text("Choose Light, Dark, or follow your System setting.")
                    .font(AetherTheme.Typography.caption)
                    .foregroundColor(AetherTheme.Colors.textTertiary)
            }

            Section("Window") {
                Text("Aether uses a hidden title bar for a clean, modern look.")
                    .font(AetherTheme.Typography.caption)
                    .foregroundColor(AetherTheme.Colors.textTertiary)
            }
        }
        .formStyle(.grouped)
        .padding(.top, AetherTheme.Spacing.md)
    }

    // MARK: - AI

    private var aiTab: some View {
        Form {
            Section("OpenRouter API Key") {
                HStack(spacing: AetherTheme.Spacing.md) {
                    SecureField(
                        hasKey ? "Key configured (enter new to replace)" : "sk-or-...",
                        text: $apiKey
                    )
                    .textFieldStyle(.roundedBorder)

                    if !apiKey.isEmpty {
                        Button("Save") { saveAPIKey() }
                            .buttonStyle(.borderedProminent)
                    }

                    if hasKey {
                        Button("Remove") { removeAPIKey() }
                            .buttonStyle(.bordered)
                            .foregroundColor(AetherTheme.Colors.error)
                    }
                }

                if let message = validationMessage {
                    Label(
                        message,
                        systemImage: message.contains("success") || message.contains("saved")
                            ? "checkmark.circle" : "exclamationmark.triangle"
                    )
                    .font(AetherTheme.Typography.caption)
                    .foregroundColor(
                        message.contains("success") || message.contains("saved")
                            ? AetherTheme.Colors.success
                            : AetherTheme.Colors.error
                    )
                }
            }

            Section("Models") {
                TextField("LLM Model", text: $llmModel, prompt: Text(AppConstants.Defaults.llmModel))
                    .textFieldStyle(.roundedBorder)

                TextField("Embedding Model", text: $embeddingModel, prompt: Text(AppConstants.Defaults.embeddingModel))
                    .textFieldStyle(.roundedBorder)

                Text("Models are served through OpenRouter. Visit openrouter.ai for available models.")
                    .font(AetherTheme.Typography.caption)
                    .foregroundColor(AetherTheme.Colors.textTertiary)
            }
        }
        .formStyle(.grouped)
        .padding(.top, AetherTheme.Spacing.md)
    }

    // MARK: - Privacy & Data

    private var privacyTab: some View {
        Form {
            Section("Browsing Data") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Browsing History")
                            .font(AetherTheme.Typography.body)
                        Text("\(historyManager?.recentHistory.count ?? 0) entries")
                            .font(AetherTheme.Typography.caption)
                            .foregroundColor(AetherTheme.Colors.textTertiary)
                    }
                    Spacer()
                    Button("Clear History") {
                        showClearHistoryConfirm = true
                    }
                    .buttonStyle(.bordered)
                }
                .alert("Clear All History?", isPresented: $showClearHistoryConfirm) {
                    Button("Cancel", role: .cancel) {}
                    Button("Clear", role: .destructive) {
                        historyManager?.clearAll()
                    }
                } message: {
                    Text("This action cannot be undone. All browsing history will be permanently deleted.")
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("Bookmarks")
                            .font(AetherTheme.Typography.body)
                        Text("\(bookmarkManager?.bookmarks.count ?? 0) bookmarks")
                            .font(AetherTheme.Typography.caption)
                            .foregroundColor(AetherTheme.Colors.textTertiary)
                    }
                    Spacer()
                    Button("Clear Bookmarks") {
                        showClearBookmarksConfirm = true
                    }
                    .buttonStyle(.bordered)
                }
                .alert("Clear All Bookmarks?", isPresented: $showClearBookmarksConfirm) {
                    Button("Cancel", role: .cancel) {}
                    Button("Clear", role: .destructive) {
                        clearAllBookmarks()
                    }
                } message: {
                    Text("This action cannot be undone. All bookmarks will be permanently deleted.")
                }
            }

            Section("Privacy") {
                Text("Aether stores all data locally on your Mac. No browsing data is sent to external servers unless you use AI features (which require OpenRouter).")
                    .font(AetherTheme.Typography.caption)
                    .foregroundColor(AetherTheme.Colors.textSecondary)
            }
        }
        .formStyle(.grouped)
        .padding(.top, AetherTheme.Spacing.md)
    }

    // MARK: - About

    private var aboutTab: some View {
        VStack(spacing: AetherTheme.Spacing.xxl) {
            Spacer()

            Image(systemName: "globe.desk")
                .font(.system(size: 48))
                .foregroundColor(AetherTheme.Colors.accent)

            Text("Aether Browser")
                .font(AetherTheme.Typography.title)

            Text("Version \(AppConstants.version)")
                .font(AetherTheme.Typography.caption)
                .foregroundColor(AetherTheme.Colors.textTertiary)

            Text("A cognitive browser for macOS.\nBuilt with Swift and SwiftUI.")
                .font(AetherTheme.Typography.body)
                .foregroundColor(AetherTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func saveAPIKey() {
        isValidating = true
        validationMessage = nil

        Task {
            do {
                let valid = try await openRouterClient.validateAPIKey(apiKey)
                await MainActor.run {
                    isValidating = false
                    if valid {
                        try? openRouterClient.setAPIKey(apiKey)
                        hasKey = true
                        apiKey = ""
                        validationMessage = "API key saved successfully."
                    } else {
                        validationMessage = "Invalid API key."
                    }
                }
            } catch {
                await MainActor.run {
                    isValidating = false
                    validationMessage = "Validation failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func removeAPIKey() {
        try? openRouterClient.clearAPIKey()
        hasKey = false
        validationMessage = "API key removed."
    }

    private func clearAllBookmarks() {
        if let manager = bookmarkManager {
            for bookmark in manager.bookmarks {
                manager.removeBookmark(bookmark.id)
            }
        }
    }
}
