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
    var chatMessages: [ChatMessage] = []
    var chatInput: String = ""
    var mode: Mode = .actions

    enum Mode: String, CaseIterable {
        case actions = "Actions"
        case chat = "Chat"
    }

    struct ChatMessage: Identifiable {
        let id = UUID()
        let role: String
        let content: String
    }

    enum AIAction: String, CaseIterable {
        case summarize = "Summarize Page"
        case explain = "Explain Page"
        case extractActions = "Extract Action Items"
        case keyPoints = "Key Points"
        case simplify = "Simplify Language"
        case translate = "Translate to English"

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
            case .simplify:
                return "You are a helpful assistant. Rewrite the key content from this web page using simpler language and shorter sentences. Make it accessible to a general audience."
            case .translate:
                return "You are a helpful assistant. Translate the key content of this web page to English. Maintain the original structure and meaning."
            }
        }

        var icon: String {
            switch self {
            case .summarize: return "doc.text"
            case .explain: return "lightbulb"
            case .extractActions: return "checklist"
            case .keyPoints: return "list.bullet.rectangle"
            case .simplify: return "text.badge.minus"
            case .translate: return "globe"
            }
        }
    }

    func reset() {
        result = ""
        isLoading = false
        error = nil
        currentAction = nil
    }

    func resetChat() {
        chatMessages = []
        chatInput = ""
    }
}

struct AIAssistView: View {
    @Bindable var state: AIAssistState
    let openRouterClient: OpenRouterClient
    let tabStore: TabStore

    var body: some View {
        VStack(spacing: 0) {
            // Header — glass
            HStack {
                Text("AI Assist")
                    .font(AetherTheme.Typography.heading)
                    .foregroundColor(AetherTheme.Colors.textPrimary)

                Spacer()

                // Mode picker
                Picker("", selection: $state.mode) {
                    ForEach(AIAssistState.Mode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 140)

                GlassIconButton(icon: "xmark", size: 11, color: AetherTheme.Colors.textTertiary) {
                    state.isVisible = false
                    state.reset()
                }
            }
            .padding(AetherTheme.Spacing.xl)

            Divider()
                .background(AetherTheme.Colors.glassBorderSubtle)

            switch state.mode {
            case .actions:
                actionsMode
            case .chat:
                chatMode
            }
        }
        .frame(width: AetherTheme.Sizes.aiSidebarWidth)
        .glassPanel()
    }

    // MARK: - Actions Mode

    @ViewBuilder
    private var actionsMode: some View {
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

    private var actionPicker: some View {
        ScrollView {
            VStack(spacing: AetherTheme.Spacing.md) {
                ForEach(AIAssistState.AIAction.allCases, id: \.self) { action in
                    ActionCardButton(action: action) {
                        performAction(action)
                    }
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

    private var loadingView: some View {
        VStack(spacing: AetherTheme.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AetherTheme.Colors.accentGlow)
                    .frame(width: 60, height: 60)
                    .blur(radius: 15)

                ProgressView()
                    .scaleEffect(0.8)
            }

            Text(state.currentAction?.rawValue ?? "Processing...")
                .font(AetherTheme.Typography.caption)
                .foregroundColor(AetherTheme.Colors.textSecondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultView: some View {
        VStack(spacing: 0) {
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
                    .background(AetherTheme.Colors.glassBorderSubtle)
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
                .background(AetherTheme.Colors.glassBorderSubtle)

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

            AetherButton("Try Again", style: .glass) {
                state.reset()
            }
            Spacer()
        }
    }

    // MARK: - Chat Mode

    private var chatMode: some View {
        VStack(spacing: 0) {
            if state.chatMessages.isEmpty {
                VStack(spacing: AetherTheme.Spacing.xl) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(AetherTheme.Colors.accentGlow)
                            .frame(width: 50, height: 50)
                            .blur(radius: 12)

                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 28))
                            .foregroundColor(AetherTheme.Colors.textTertiary)
                    }

                    Text("Ask anything about the current page")
                        .font(AetherTheme.Typography.caption)
                        .foregroundColor(AetherTheme.Colors.textTertiary)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: AetherTheme.Spacing.md) {
                        ForEach(state.chatMessages) { msg in
                            chatBubble(msg)
                        }
                    }
                    .padding(AetherTheme.Spacing.xl)
                }
            }

            Divider().background(AetherTheme.Colors.glassBorderSubtle)

            // Chat input — glass
            HStack(spacing: AetherTheme.Spacing.md) {
                TextField("Ask about this page...", text: $state.chatInput)
                    .textFieldStyle(.plain)
                    .font(AetherTheme.Typography.body)
                    .foregroundColor(AetherTheme.Colors.textPrimary)
                    .onSubmit { sendChatMessage() }

                Button(action: sendChatMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(
                            state.chatInput.isEmpty || !openRouterClient.isConfigured
                                ? AetherTheme.Colors.textTertiary
                                : AetherTheme.Colors.accent
                        )
                }
                .buttonStyle(.plain)
                .disabled(state.chatInput.isEmpty || !openRouterClient.isConfigured)
            }
            .padding(AetherTheme.Spacing.lg)
        }
    }

    private func chatBubble(_ message: AIAssistState.ChatMessage) -> some View {
        HStack {
            if message.role == "user" { Spacer() }

            Text(message.content)
                .font(AetherTheme.Typography.body)
                .foregroundColor(AetherTheme.Colors.textPrimary)
                .padding(AetherTheme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous)
                        .fill(
                            message.role == "user"
                                ? AetherTheme.Colors.accentSubtle
                                : AetherTheme.Colors.glassSurface
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous)
                        .strokeBorder(AetherTheme.Colors.glassBorderSubtle, lineWidth: 0.5)
                )
                .textSelection(.enabled)

            if message.role != "user" { Spacer() }
        }
    }

    // MARK: - Actions

    private func sendChatMessage() {
        let input = state.chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty, openRouterClient.isConfigured else { return }

        state.chatMessages.append(.init(role: "user", content: input))
        state.chatInput = ""

        guard let tabId = tabStore.activeTab?.id,
              let coordinator = tabStore.coordinator(for: tabId) else {
            state.chatMessages.append(.init(role: "assistant", content: "No active page to analyze."))
            return
        }

        coordinator.extractPageText { pageText in
            let text = pageText ?? "No content available"
            let truncated = String(text.prefix(6000))

            let pageURL = coordinator.currentURL?.absoluteString ?? "Unknown"
            let pageTitle = coordinator.pageTitle

            let systemPrompt = """
            You are a helpful assistant analyzing a web page. Answer questions about the page content.
            Page Title: \(pageTitle)
            Page URL: \(pageURL)
            Page Content (truncated): \(truncated)
            """

            Task {
                do {
                    let result = try await openRouterClient.complete(
                        prompt: input,
                        model: nil,
                        system: systemPrompt
                    )
                    await MainActor.run {
                        state.chatMessages.append(.init(role: "assistant", content: result))
                    }
                } catch {
                    await MainActor.run {
                        state.chatMessages.append(.init(role: "assistant", content: "Error: \(error.localizedDescription)"))
                    }
                }
            }
        }
    }

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

// MARK: - Action Card Button

private struct ActionCardButton: View {
    let action: AIAssistState.AIAction
    let onTap: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AetherTheme.Spacing.lg) {
                Image(systemName: action.icon)
                    .font(.system(size: 14))
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
            .background(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.lg, style: .continuous)
                    .fill(isHovering ? AetherTheme.Colors.glassHover : AetherTheme.Colors.glassSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.lg, style: .continuous)
                    .strokeBorder(AetherTheme.Colors.glassBorderSubtle, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(AetherTheme.Animation.fast) {
                isHovering = hovering
            }
        }
    }
}
