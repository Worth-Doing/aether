import SwiftUI
import AetherCore
import AetherUI
import AIService
import SecureStorage

public struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var llmModel: String = AppConstants.Defaults.llmModel
    @State private var embeddingModel: String = AppConstants.Defaults.embeddingModel
    @State private var isValidating: Bool = false
    @State private var validationMessage: String?
    @State private var hasKey: Bool = false

    let openRouterClient: OpenRouterClient
    private let keychain = KeychainManager()

    public init(openRouterClient: OpenRouterClient) {
        self.openRouterClient = openRouterClient
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AetherTheme.Spacing.xxl) {
                // Header
                Text("Settings")
                    .font(AetherTheme.Typography.title)
                    .foregroundColor(AetherTheme.Colors.textPrimary)

                // AI Configuration
                settingsSection("AI Configuration") {
                    VStack(alignment: .leading, spacing: AetherTheme.Spacing.lg) {
                        VStack(alignment: .leading, spacing: AetherTheme.Spacing.sm) {
                            Text("OpenRouter API Key")
                                .font(AetherTheme.Typography.captionMedium)
                                .foregroundColor(AetherTheme.Colors.textSecondary)

                            HStack(spacing: AetherTheme.Spacing.md) {
                                AetherTextField(
                                    hasKey ? "Key is configured (enter new to replace)" : "sk-or-...",
                                    text: $apiKey,
                                    isSecure: true
                                )

                                if !apiKey.isEmpty {
                                    AetherButton("Save", style: .primary) {
                                        saveAPIKey()
                                    }
                                }

                                if hasKey {
                                    AetherButton("Remove", style: .ghost) {
                                        removeAPIKey()
                                    }
                                }
                            }
                        }

                        if let message = validationMessage {
                            Text(message)
                                .font(AetherTheme.Typography.caption)
                                .foregroundColor(
                                    message.contains("success") || message.contains("saved")
                                        ? AetherTheme.Colors.success
                                        : AetherTheme.Colors.error
                                )
                        }

                        VStack(alignment: .leading, spacing: AetherTheme.Spacing.sm) {
                            Text("Default LLM Model")
                                .font(AetherTheme.Typography.captionMedium)
                                .foregroundColor(AetherTheme.Colors.textSecondary)

                            AetherTextField("e.g. anthropic/claude-sonnet-4", text: $llmModel)
                        }

                        VStack(alignment: .leading, spacing: AetherTheme.Spacing.sm) {
                            Text("Default Embedding Model")
                                .font(AetherTheme.Typography.captionMedium)
                                .foregroundColor(AetherTheme.Colors.textSecondary)

                            AetherTextField("e.g. openai/text-embedding-3-small", text: $embeddingModel)
                        }
                    }
                }

                // About
                settingsSection("About") {
                    VStack(alignment: .leading, spacing: AetherTheme.Spacing.md) {
                        HStack {
                            Text("Aether Browser")
                                .font(AetherTheme.Typography.bodyMedium)
                                .foregroundColor(AetherTheme.Colors.textPrimary)
                            Spacer()
                            Text("v0.1.0")
                                .font(AetherTheme.Typography.caption)
                                .foregroundColor(AetherTheme.Colors.textTertiary)
                        }

                        Text("A cognitive browser for macOS. Built with Swift and SwiftUI.")
                            .font(AetherTheme.Typography.caption)
                            .foregroundColor(AetherTheme.Colors.textSecondary)
                    }
                }
            }
            .padding(AetherTheme.Spacing.xxl)
        }
        .background(AetherTheme.Colors.background)
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            hasKey = openRouterClient.isConfigured
            loadSettings()
        }
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AetherTheme.Spacing.lg) {
            Text(title)
                .font(AetherTheme.Typography.heading)
                .foregroundColor(AetherTheme.Colors.textPrimary)

            content()
                .padding(AetherTheme.Spacing.xl)
                .background(AetherTheme.Colors.surface)
                .cornerRadius(AetherTheme.Radius.lg)
        }
    }

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

    private func loadSettings() {
        if let saved = UserDefaults.standard.string(forKey: "llmModel"), !saved.isEmpty {
            llmModel = saved
        }
        if let saved = UserDefaults.standard.string(forKey: "embeddingModel"), !saved.isEmpty {
            embeddingModel = saved
        }
    }
}
