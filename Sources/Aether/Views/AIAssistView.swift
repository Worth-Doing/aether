import SwiftUI
import AetherCore
import AetherUI
import AIService
import TabManager
import BrowserEngine

@Observable
final class AIAssistState {
    var isVisible: Bool = false
    var currentAction: AIAction?
    var result: String = ""
    var isLoading: Bool = false
    var error: String?

    enum AIAction: String, CaseIterable {
        case summarize = "Summarize Page"
        case explain = "Explain Page"
        case extractActions = "Extract Action Items"
        case keyPoints = "Key Points"

        var systemPrompt: String {
            switch self {
            case .summarize:
                return "You are a helpful assistant. Summarize the following web page content concisely. Focus on the main points and key information. Be brief and clear."
            case .explain:
                return "You are a helpful assistant. Explain the following web page content in simple, clear terms. Break down complex concepts. Be educational but concise."
            case .extractActions:
                return "You are a helpful assistant. Extract and list all action items, to-dos, or actionable steps from the following web page content. Format as a bulleted list."
            case .keyPoints:
                return "You are a helpful assistant. Extract the key points from the following web page content. Format as a concise bulleted list of the most important facts and insights."
            }
        }

        var icon: String {
            switch self {
            case .summarize: return "doc.text"
            case .explain: return "lightbulb"
            case .extractActions: return "checklist"
            case .keyPoints: return "list.bullet.rectangle"
            }
        }
    }

    func reset() {
        result = ""
        isLoading = false
        error = nil
        currentAction = nil
    }
}

struct AIAssistView: View {
    @Bindable var state: AIAssistState
    let openRouterClient: OpenRouterClient
    let tabStore: TabStore

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AI Assist")
                    .font(AetherTheme.Typography.heading)
                    .foregroundColor(AetherTheme.Colors.textPrimary)

                Spacer()

                Button {
                    state.isVisible = false
                    state.reset()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(AetherTheme.Spacing.xl)

            Divider()
                .background(AetherTheme.Colors.border)

            if state.isLoading {
                loadingView
            } else if !state.result.isEmpty {
                resultView
            } else if let error = state.error {
                errorView(error)
            } else {
                actionPicker
            }
        }
        .frame(width: 320)
        .background(AetherTheme.Colors.sidebarBackground)
    }

    // MARK: - Action Picker

    private var actionPicker: some View {
        ScrollView {
            VStack(spacing: AetherTheme.Spacing.md) {
                ForEach(AIAssistState.AIAction.allCases, id: \.self) { action in
                    Button {
                        performAction(action)
                    } label: {
                        HStack(spacing: AetherTheme.Spacing.lg) {
                            Image(systemName: action.icon)
                                .font(.system(size: 16))
                                .foregroundColor(AetherTheme.Colors.accent)
                                .frame(width: 24)

                            Text(action.rawValue)
                                .font(AetherTheme.Typography.body)
                                .foregroundColor(AetherTheme.Colors.textPrimary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundColor(AetherTheme.Colors.textTertiary)
                        }
                        .padding(AetherTheme.Spacing.lg)
                        .background(AetherTheme.Colors.surface)
                        .cornerRadius(AetherTheme.Radius.md)
                    }
                    .buttonStyle(.plain)
                }

                if !openRouterClient.isConfigured {
                    HStack(spacing: AetherTheme.Spacing.md) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(AetherTheme.Colors.warning)
                        Text("Configure OpenRouter API key in Settings to use AI features.")
                            .font(AetherTheme.Typography.caption)
                            .foregroundColor(AetherTheme.Colors.textSecondary)
                    }
                    .padding(AetherTheme.Spacing.lg)
                }
            }
            .padding(AetherTheme.Spacing.xl)
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: AetherTheme.Spacing.xl) {
            Spacer()
            ProgressView()
                .scaleEffect(0.8)
            Text(state.currentAction?.rawValue ?? "Processing...")
                .font(AetherTheme.Typography.caption)
                .foregroundColor(AetherTheme.Colors.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Result

    private var resultView: some View {
        VStack(spacing: 0) {
            // Action label
            if let action = state.currentAction {
                HStack {
                    Image(systemName: action.icon)
                        .foregroundColor(AetherTheme.Colors.accent)
                    Text(action.rawValue)
                        .font(AetherTheme.Typography.captionMedium)
                        .foregroundColor(AetherTheme.Colors.textSecondary)
                    Spacer()

                    Button {
                        state.reset()
                    } label: {
                        Text("New")
                            .font(AetherTheme.Typography.caption)
                            .foregroundColor(AetherTheme.Colors.accent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(AetherTheme.Spacing.xl)

                Divider()
                    .background(AetherTheme.Colors.border)
            }

            ScrollView {
                Text(state.result)
                    .font(AetherTheme.Typography.body)
                    .foregroundColor(AetherTheme.Colors.textPrimary)
                    .textSelection(.enabled)
                    .lineSpacing(4)
                    .padding(AetherTheme.Spacing.xl)
            }

            Divider()
                .background(AetherTheme.Colors.border)

            // Copy button
            HStack {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(state.result, forType: .string)
                } label: {
                    HStack(spacing: AetherTheme.Spacing.sm) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .font(AetherTheme.Typography.caption)
                    .foregroundColor(AetherTheme.Colors.textSecondary)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(AetherTheme.Spacing.lg)
        }
    }

    // MARK: - Error

    private func errorView(_ error: String) -> some View {
        VStack(spacing: AetherTheme.Spacing.xl) {
            Spacer()
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 32))
                .foregroundColor(AetherTheme.Colors.error)

            Text(error)
                .font(AetherTheme.Typography.caption)
                .foregroundColor(AetherTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            AetherButton("Try Again", style: .secondary) {
                state.reset()
            }
            Spacer()
        }
    }

    // MARK: - Actions

    private func performAction(_ action: AIAssistState.AIAction) {
        guard openRouterClient.isConfigured else {
            state.error = "No API key configured. Add your OpenRouter key in Settings."
            return
        }

        guard let tabId = tabStore.activeTab?.id,
              let coordinator = tabStore.coordinator(for: tabId) else {
            state.error = "No active page to analyze."
            return
        }

        state.currentAction = action
        state.isLoading = true
        state.error = nil

        coordinator.extractPageText { pageText in
            guard let text = pageText, !text.isEmpty else {
                DispatchQueue.main.async {
                    state.isLoading = false
                    state.error = "Could not extract page content."
                }
                return
            }

            let truncated = String(text.prefix(8000))
            let pageURL = coordinator.currentURL?.absoluteString ?? "Unknown URL"
            let pageTitle = coordinator.pageTitle

            let prompt = """
            Page Title: \(pageTitle)
            Page URL: \(pageURL)

            Page Content:
            \(truncated)
            """

            Task {
                do {
                    let result = try await openRouterClient.complete(
                        prompt: prompt,
                        model: nil,
                        system: action.systemPrompt
                    )
                    await MainActor.run {
                        state.result = result
                        state.isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        state.isLoading = false
                        state.error = error.localizedDescription
                    }
                }
            }
        }
    }
}
