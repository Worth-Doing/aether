import SwiftUI
import AetherCore
import AetherUI
import AIService
import TabManager

/// Quick notes scratchpad and page intelligence panel
struct QuickNotesView: View {
    @Bindable var tabStore: TabStore
    let openRouterClient: OpenRouterClient

    @State private var selectedMode: NotesMode = .notes
    @State private var noteText: String = ""
    @State private var summaryText: String = ""
    @State private var keyPoints: [String] = []
    @State private var isProcessing = false
    @State private var processError: String?

    enum NotesMode: String, CaseIterable {
        case notes = "Notes"
        case summary = "Summary"
        case keyPoints = "Key Points"

        var icon: String {
            switch self {
            case .notes: return "note.text"
            case .summary: return "doc.plaintext"
            case .keyPoints: return "list.bullet.rectangle"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with mode switcher
            HStack(spacing: AetherTheme.Spacing.sm) {
                ForEach(NotesMode.allCases, id: \.self) { mode in
                    Button(action: { withAnimation(AetherTheme.Animation.spring) { selectedMode = mode } }) {
                        HStack(spacing: 4) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 10))
                            Text(mode.rawValue)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(selectedMode == mode ? AetherTheme.Colors.accent : AetherTheme.Colors.textTertiary)
                        .padding(.horizontal, AetherTheme.Spacing.md)
                        .padding(.vertical, AetherTheme.Spacing.sm)
                        .background(
                            Capsule()
                                .fill(selectedMode == mode ? AetherTheme.Colors.accentSubtle : .clear)
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.horizontal, AetherTheme.Spacing.lg)
            .padding(.vertical, AetherTheme.Spacing.md)

            Divider().background(AetherTheme.Colors.glassBorderSubtle)

            // Content
            switch selectedMode {
            case .notes:
                notesPanel
            case .summary:
                summaryPanel
            case .keyPoints:
                keyPointsPanel
            }
        }
        .frame(width: AetherTheme.Sizes.aiSidebarWidth)
        .background(
            ZStack {
                VisualEffectBlur(material: .sidebar)
                AetherTheme.Colors.glassBackground.opacity(0.3)
            }
        )
    }

    // MARK: - Notes Panel

    private var notesPanel: some View {
        VStack(spacing: 0) {
            // Scratchpad
            TextEditor(text: $noteText)
                .font(.system(size: 13, weight: .regular, design: .default))
                .foregroundColor(AetherTheme.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(AetherTheme.Spacing.lg)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom bar
            HStack {
                Text("\(noteText.count) characters")
                    .font(.system(size: 9))
                    .foregroundColor(AetherTheme.Colors.textTertiary)

                Spacer()

                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(noteText, forType: .string)
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AetherTheme.Colors.textSecondary)
                }
                .buttonStyle(.plain)
                .disabled(noteText.isEmpty)
            }
            .padding(.horizontal, AetherTheme.Spacing.lg)
            .padding(.vertical, AetherTheme.Spacing.md)
            .background(AetherTheme.Colors.surfaceElevated.opacity(0.5))
        }
    }

    // MARK: - Summary Panel

    private var summaryPanel: some View {
        VStack(spacing: AetherTheme.Spacing.lg) {
            if isProcessing {
                Spacer()
                VStack(spacing: AetherTheme.Spacing.lg) {
                    ProgressView()
                    Text("Summarizing page...")
                        .font(AetherTheme.Typography.caption)
                        .foregroundColor(AetherTheme.Colors.textSecondary)
                }
                Spacer()
            } else if !summaryText.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: AetherTheme.Spacing.lg) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11))
                                .foregroundColor(AetherTheme.Colors.accent)
                            Text("Page Summary")
                                .font(AetherTheme.Typography.captionMedium)
                                .foregroundColor(AetherTheme.Colors.textSecondary)
                            Spacer()
                            Button(action: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(summaryText, forType: .string)
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 10))
                                    .foregroundColor(AetherTheme.Colors.textTertiary)
                            }
                            .buttonStyle(.plain)
                        }

                        Text(summaryText)
                            .font(AetherTheme.Typography.body)
                            .foregroundColor(AetherTheme.Colors.textPrimary)
                            .lineSpacing(3)
                            .textSelection(.enabled)
                    }
                    .padding(AetherTheme.Spacing.xl)
                }
            } else {
                Spacer()
                generateButton(title: "Summarize Page", icon: "doc.plaintext") {
                    generateSummary()
                }
                if let error = processError {
                    Text(error)
                        .font(AetherTheme.Typography.caption)
                        .foregroundColor(AetherTheme.Colors.error)
                        .padding(.top, AetherTheme.Spacing.md)
                }
                Spacer()
            }
        }
    }

    // MARK: - Key Points Panel

    private var keyPointsPanel: some View {
        VStack(spacing: AetherTheme.Spacing.lg) {
            if isProcessing {
                Spacer()
                VStack(spacing: AetherTheme.Spacing.lg) {
                    ProgressView()
                    Text("Extracting key points...")
                        .font(AetherTheme.Typography.caption)
                        .foregroundColor(AetherTheme.Colors.textSecondary)
                }
                Spacer()
            } else if !keyPoints.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: AetherTheme.Spacing.lg) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11))
                                .foregroundColor(AetherTheme.Colors.accent)
                            Text("Key Points")
                                .font(AetherTheme.Typography.captionMedium)
                                .foregroundColor(AetherTheme.Colors.textSecondary)
                            Spacer()
                        }

                        ForEach(Array(keyPoints.enumerated()), id: \.offset) { index, point in
                            HStack(alignment: .top, spacing: AetherTheme.Spacing.lg) {
                                Text("\(index + 1)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(AetherTheme.Colors.accent)
                                    .frame(width: 20, height: 20)
                                    .background(Circle().fill(AetherTheme.Colors.accentSubtle))

                                Text(point)
                                    .font(AetherTheme.Typography.body)
                                    .foregroundColor(AetherTheme.Colors.textPrimary)
                                    .lineSpacing(2)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .padding(AetherTheme.Spacing.xl)
                }
            } else {
                Spacer()
                generateButton(title: "Extract Key Points", icon: "list.bullet.rectangle") {
                    generateKeyPoints()
                }
                if let error = processError {
                    Text(error)
                        .font(AetherTheme.Typography.caption)
                        .foregroundColor(AetherTheme.Colors.error)
                        .padding(.top, AetherTheme.Spacing.md)
                }
                Spacer()
            }
        }
    }

    // MARK: - Helpers

    private func generateButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: AetherTheme.Spacing.lg) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(AetherTheme.Colors.accent)

                Text(title)
                    .font(AetherTheme.Typography.captionMedium)
                    .foregroundColor(AetherTheme.Colors.textPrimary)

                Text("Uses AI to analyze current page")
                    .font(.system(size: 10))
                    .foregroundColor(AetherTheme.Colors.textTertiary)
            }
            .padding(AetherTheme.Spacing.xxl)
            .background(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous)
                    .fill(AetherTheme.Colors.glassSurface.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous)
                    .strokeBorder(AetherTheme.Colors.glassBorderSubtle, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(!openRouterClient.isConfigured)
    }

    // MARK: - AI Actions

    private func generateSummary() {
        guard let tabId = tabStore.activeTab?.id,
              let coordinator = tabStore.coordinator(for: tabId) else { return }

        isProcessing = true
        processError = nil

        coordinator.extractReadableContent { text in
            guard let text, !text.isEmpty else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.processError = "Could not extract page content."
                }
                return
            }

            let truncated = String(text.prefix(6000))
            Task {
                do {
                    let result = try await openRouterClient.complete(
                        prompt: "Summarize the following webpage content in 3-5 clear paragraphs. Be concise but thorough:\n\n\(truncated)",
                        model: nil,
                        system: "You are a helpful assistant that creates clear, well-structured page summaries."
                    )
                    await MainActor.run {
                        self.summaryText = result
                        self.isProcessing = false
                    }
                } catch {
                    await MainActor.run {
                        self.processError = error.localizedDescription
                        self.isProcessing = false
                    }
                }
            }
        }
    }

    private func generateKeyPoints() {
        guard let tabId = tabStore.activeTab?.id,
              let coordinator = tabStore.coordinator(for: tabId) else { return }

        isProcessing = true
        processError = nil

        coordinator.extractReadableContent { text in
            guard let text, !text.isEmpty else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.processError = "Could not extract page content."
                }
                return
            }

            let truncated = String(text.prefix(6000))
            Task {
                do {
                    let result = try await openRouterClient.complete(
                        prompt: "Extract the 5-8 most important key points from this content. Return each point on a new line, starting with a dash (-):\n\n\(truncated)",
                        model: nil,
                        system: "You are a helpful assistant that extracts key points. Return only the points, one per line, each starting with a dash (-)."
                    )
                    await MainActor.run {
                        self.keyPoints = result
                            .components(separatedBy: "\n")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }
                            .map { line in
                                var clean = line
                                if clean.hasPrefix("-") { clean = String(clean.dropFirst()).trimmingCharacters(in: .whitespaces) }
                                if clean.hasPrefix("•") { clean = String(clean.dropFirst()).trimmingCharacters(in: .whitespaces) }
                                return clean
                            }
                            .filter { !$0.isEmpty }
                        self.isProcessing = false
                    }
                } catch {
                    await MainActor.run {
                        self.processError = error.localizedDescription
                        self.isProcessing = false
                    }
                }
            }
        }
    }
}
