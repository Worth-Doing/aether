import SwiftUI
import AetherCore
import AetherUI
import WebSearchService
import TabManager

/// Premium web search view with rich result cards and split-view preview
struct WebSearchView: View {
    @Bindable var searchManager: SearchManager
    @Bindable var tabStore: TabStore
    let onNavigate: (String) -> Void
    let onDismiss: () -> Void

    @State private var query: String = ""
    @State private var selectedMode: SearchMode = .web
    @State private var selectedProvider: SearchProviderType?
    @State private var selectedResult: WebSearchResult?
    @State private var showProviderPicker = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Search header
            searchHeader

            Divider()
                .background(AetherTheme.Colors.glassBorderSubtle)

            // Content
            if searchManager.isSearching {
                searchLoadingView
            } else if let response = searchManager.currentResponse {
                searchResultsView(response)
            } else if let error = searchManager.error {
                searchErrorView(error)
            } else {
                searchEmptyState
            }
        }
        .background(AetherTheme.Colors.background)
        .onAppear {
            isSearchFocused = true
            selectedProvider = searchManager.activeProvider
        }
        .onChange(of: selectedMode) { _, _ in
            if !query.trimmingCharacters(in: .whitespaces).isEmpty {
                performSearch()
            }
        }
    }

    // MARK: - Search Header

    private var searchHeader: some View {
        VStack(spacing: AetherTheme.Spacing.lg) {
            // Search input
            HStack(spacing: AetherTheme.Spacing.lg) {
                // Search icon with mode indicator
                ZStack {
                    Circle()
                        .fill(AetherTheme.Colors.accentSubtle)
                        .frame(width: 36, height: 36)

                    Image(systemName: selectedMode.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AetherTheme.Colors.accent)
                }

                // Search field
                TextField("Search the web with AI-powered providers...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AetherTheme.Colors.textPrimary)
                    .focused($isSearchFocused)
                    .onSubmit { performSearch() }

                // Provider badge
                if let provider = selectedProvider ?? searchManager.activeProvider {
                    Button(action: { showProviderPicker.toggle() }) {
                        HStack(spacing: AetherTheme.Spacing.sm) {
                            Image(systemName: provider.icon)
                                .font(.system(size: 10))
                            Text(provider.rawValue)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(providerColor(provider))
                        .padding(.horizontal, AetherTheme.Spacing.md)
                        .padding(.vertical, AetherTheme.Spacing.sm)
                        .background(
                            Capsule()
                                .fill(providerColor(provider).opacity(0.1))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(providerColor(provider).opacity(0.2), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showProviderPicker) {
                        providerPickerPopover
                    }
                }

                // Search button
                if !query.isEmpty {
                    Button(action: performSearch) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AetherTheme.Colors.accent)
                    }
                    .buttonStyle(.plain)
                }

                // Close button
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                        .frame(width: 26, height: 26)
                        .background(
                            Circle().fill(AetherTheme.Colors.surfaceElevated)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AetherTheme.Spacing.xl)
            .padding(.vertical, AetherTheme.Spacing.lg)
            .background(
                ZStack {
                    VisualEffectBlur(material: .popover)
                    AetherTheme.Colors.glassSurface.opacity(0.3)
                }
                .clipShape(RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous)
                    .strokeBorder(
                        isSearchFocused
                            ? AetherTheme.Colors.accent.opacity(0.3)
                            : AetherTheme.Colors.glassBorderSubtle,
                        lineWidth: isSearchFocused ? 1.5 : 0.5
                    )
            )
            .padding(.horizontal, AetherTheme.Spacing.xl)

            // Mode pills
            HStack(spacing: AetherTheme.Spacing.sm) {
                ForEach(SearchMode.allCases) { mode in
                    ModePill(mode: mode, isSelected: selectedMode == mode) {
                        withAnimation(AetherTheme.Animation.spring) {
                            selectedMode = mode
                        }
                    }
                }

                Spacer()

                // Recent searches
                if !searchManager.searchHistory.isEmpty {
                    Menu {
                        ForEach(searchManager.searchHistory.prefix(10)) { entry in
                            Button(action: {
                                query = entry.query
                                selectedMode = entry.mode
                                performSearch()
                            }) {
                                Label(entry.query, systemImage: "clock")
                            }
                        }
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 11))
                            .foregroundColor(AetherTheme.Colors.textTertiary)
                    }
                }
            }
            .padding(.horizontal, AetherTheme.Spacing.xl + AetherTheme.Spacing.sm)
        }
        .padding(.vertical, AetherTheme.Spacing.xl)
        .glassToolbar()
    }

    // MARK: - Results View

    private func searchResultsView(_ response: WebSearchResponse) -> some View {
        HStack(spacing: 0) {
            // Results list
            ScrollView {
                LazyVStack(spacing: AetherTheme.Spacing.md) {
                    // Response header
                    resultHeaderView(response)

                    // Knowledge Graph
                    if let kg = response.knowledgeGraph {
                        KnowledgeGraphCard(kg: kg, onNavigate: { url in
                            onNavigate(url)
                            onDismiss()
                        })
                    }

                    // AI Answer
                    if let answer = response.answer {
                        AIAnswerCard(answer: answer, provider: response.provider)
                    }

                    // Mode-prioritized content
                    switch selectedMode {
                    case .images:
                        if !response.imageResults.isEmpty {
                            ImageResultsGrid(images: response.imageResults, onNavigate: { url in onNavigate(url); onDismiss() })
                        } else {
                            noMediaResultsView(type: "images", icon: "photo")
                        }

                    case .videos:
                        if !response.videoResults.isEmpty {
                            VideoResultsList(videos: response.videoResults, onNavigate: { url in onNavigate(url); onDismiss() })
                        } else {
                            noMediaResultsView(type: "videos", icon: "play.rectangle")
                        }

                    case .news:
                        if !response.newsResults.isEmpty {
                            NewsResultsList(news: response.newsResults, onNavigate: { url in onNavigate(url); onDismiss() })
                        } else {
                            noMediaResultsView(type: "news", icon: "newspaper")
                        }

                    default:
                        // Web/Research/Fast/Deep — show all sections
                        if !response.imageResults.isEmpty {
                            richMediaSectionHeader(icon: "photo", title: "Images", count: response.imageResults.count)
                            ImageResultsGrid(images: response.imageResults, onNavigate: { url in onNavigate(url); onDismiss() })
                        }

                        if !response.videoResults.isEmpty {
                            richMediaSectionHeader(icon: "play.rectangle.fill", title: "Videos", count: response.videoResults.count)
                            VideoResultsList(videos: response.videoResults, onNavigate: { url in onNavigate(url); onDismiss() })
                        }

                        if !response.newsResults.isEmpty {
                            richMediaSectionHeader(icon: "newspaper.fill", title: "News", count: response.newsResults.count)
                            NewsResultsList(news: response.newsResults, onNavigate: { url in onNavigate(url); onDismiss() })
                        }

                        if !response.results.isEmpty {
                            if response.hasRichMedia {
                                richMediaSectionHeader(icon: "globe", title: "Web Results", count: response.results.count)
                            }

                            ForEach(response.results) { result in
                                SearchResultCard(
                                    result: result,
                                    isSelected: selectedResult?.id == result.id,
                                    onSelect: {
                                        withAnimation(AetherTheme.Animation.spring) {
                                            selectedResult = result
                                        }
                                    },
                                    onNavigate: {
                                        onNavigate(result.url)
                                        onDismiss()
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(AetherTheme.Spacing.xl)
            }

            // Preview pane
            if let result = selectedResult {
                Divider()
                    .background(AetherTheme.Colors.glassBorderSubtle)

                ResultPreviewPane(result: result, onNavigate: {
                    onNavigate(result.url)
                    onDismiss()
                })
                .frame(width: 360)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(AetherTheme.Animation.spring, value: selectedResult?.id)
    }

    private func noMediaResultsView(type: String, icon: String) -> some View {
        VStack(spacing: AetherTheme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .ultraLight))
                .foregroundColor(AetherTheme.Colors.textTertiary.opacity(0.5))

            Text("No \(type) results found")
                .font(AetherTheme.Typography.body)
                .foregroundColor(AetherTheme.Colors.textTertiary)

            if selectedProvider != .serper && searchManager.isProviderConfigured(.serper) {
                Text("Tip: Serper provides dedicated \(type) search. It will be used automatically.")
                    .font(AetherTheme.Typography.caption)
                    .foregroundColor(AetherTheme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
            } else if !searchManager.isProviderConfigured(.serper) {
                Text("Tip: Connect Serper in Settings for dedicated \(type) search results.")
                    .font(AetherTheme.Typography.caption)
                    .foregroundColor(AetherTheme.Colors.accent)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AetherTheme.Spacing.xxxxl)
    }

    private func richMediaSectionHeader(icon: String, title: String, count: Int) -> some View {
        HStack(spacing: AetherTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AetherTheme.Colors.accent)
            Text(title)
                .font(AetherTheme.Typography.heading)
                .foregroundColor(AetherTheme.Colors.textPrimary)
            Text("\(count)")
                .font(AetherTheme.Typography.caption)
                .foregroundColor(AetherTheme.Colors.textTertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(AetherTheme.Colors.surfaceElevated))
            Spacer()
        }
        .padding(.top, AetherTheme.Spacing.lg)
        .padding(.bottom, AetherTheme.Spacing.sm)
    }

    // MARK: - Result Header

    private func resultHeaderView(_ response: WebSearchResponse) -> some View {
        HStack(spacing: AetherTheme.Spacing.lg) {
            HStack(spacing: AetherTheme.Spacing.sm) {
                Image(systemName: response.provider.icon)
                    .font(.system(size: 10))
                    .foregroundColor(providerColor(response.provider))
                Text(response.provider.rawValue)
                    .font(AetherTheme.Typography.caption)
                    .foregroundColor(AetherTheme.Colors.textSecondary)
            }

            Text("\(response.totalResults) results")
                .font(AetherTheme.Typography.caption)
                .foregroundColor(AetherTheme.Colors.textTertiary)

            Text(String(format: "%.1fs", response.responseTime))
                .font(AetherTheme.Typography.caption)
                .foregroundColor(AetherTheme.Colors.textTertiary)

            Spacer()

            Text(response.searchMode.rawValue)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(AetherTheme.Colors.accent)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(AetherTheme.Colors.accentSubtle))
        }
        .padding(.bottom, AetherTheme.Spacing.sm)
    }

    // MARK: - Loading

    private var searchLoadingView: some View {
        VStack(spacing: AetherTheme.Spacing.xxl) {
            Spacer()

            // Animated search indicator
            ZStack {
                Circle()
                    .fill(AetherTheme.Colors.accentGlow)
                    .frame(width: 60, height: 60)
                    .blur(radius: 20)

                ProgressView()
                    .scaleEffect(1.2)
            }

            VStack(spacing: AetherTheme.Spacing.md) {
                Text("Searching...")
                    .font(AetherTheme.Typography.heading)
                    .foregroundColor(AetherTheme.Colors.textPrimary)

                Text("Querying \(selectedProvider?.rawValue ?? "provider") for results")
                    .font(AetherTheme.Typography.caption)
                    .foregroundColor(AetherTheme.Colors.textSecondary)
            }

            // Skeleton results
            VStack(spacing: AetherTheme.Spacing.md) {
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonResultCard()
                }
            }
            .padding(.horizontal, AetherTheme.Spacing.xxxxl)
            .padding(.top, AetherTheme.Spacing.xl)

            Spacer()
        }
    }

    // MARK: - Error

    private func searchErrorView(_ error: SearchProviderError) -> some View {
        VStack(spacing: AetherTheme.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AetherTheme.Colors.error.opacity(0.1))
                    .frame(width: 60, height: 60)

                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(AetherTheme.Colors.error)
            }

            Text("Search Failed")
                .font(AetherTheme.Typography.heading)
                .foregroundColor(AetherTheme.Colors.textPrimary)

            Text(error.localizedDescription)
                .font(AetherTheme.Typography.caption)
                .foregroundColor(AetherTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Button("Try Again") { performSearch() }
                .buttonStyle(.borderedProminent)

            Spacer()
        }
    }

    // MARK: - Empty State

    private var searchEmptyState: some View {
        VStack(spacing: AetherTheme.Spacing.xxl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AetherTheme.Colors.accentGlow)
                    .frame(width: 80, height: 80)
                    .blur(radius: 25)

                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 36, weight: .ultraLight))
                    .foregroundColor(AetherTheme.Colors.accent)
            }

            VStack(spacing: AetherTheme.Spacing.md) {
                Text("Intelligent Web Search")
                    .font(AetherTheme.Typography.title)
                    .foregroundColor(AetherTheme.Colors.textPrimary)

                Text("Search the web with AI-powered providers.\nConnect Firecrawl, Exa, or Tavily in Settings for deeper results.")
                    .font(AetherTheme.Typography.body)
                    .foregroundColor(AetherTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            if searchManager.configuredProviders.isEmpty {
                Button(action: {}) {
                    Label("Configure Search Providers", systemImage: "puzzlepiece.extension")
                        .font(AetherTheme.Typography.captionMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, AetherTheme.Spacing.xl)
                        .padding(.vertical, AetherTheme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AetherTheme.Radius.lg, style: .continuous)
                                .fill(AetherTheme.Colors.accent)
                        )
                }
                .buttonStyle(.plain)
            }

            // Recent searches
            if !searchManager.searchHistory.isEmpty {
                VStack(spacing: AetherTheme.Spacing.md) {
                    Text("Recent Searches")
                        .font(AetherTheme.Typography.captionMedium)
                        .foregroundColor(AetherTheme.Colors.textTertiary)

                    FlowLayout(spacing: AetherTheme.Spacing.md) {
                        ForEach(searchManager.searchHistory.prefix(8)) { entry in
                            Button(action: {
                                query = entry.query
                                selectedMode = entry.mode
                                performSearch()
                            }) {
                                Text(entry.query)
                                    .font(AetherTheme.Typography.caption)
                                    .foregroundColor(AetherTheme.Colors.textSecondary)
                                    .padding(.horizontal, AetherTheme.Spacing.lg)
                                    .padding(.vertical, AetherTheme.Spacing.sm)
                                    .background(
                                        Capsule().fill(AetherTheme.Colors.surfaceElevated)
                                    )
                                    .overlay(
                                        Capsule().strokeBorder(AetherTheme.Colors.glassBorderSubtle, lineWidth: 0.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.top, AetherTheme.Spacing.xl)
            }

            Spacer()
        }
        .padding(.horizontal, AetherTheme.Spacing.xxxxl)
    }

    // MARK: - Provider Picker

    private var providerPickerPopover: some View {
        VStack(spacing: AetherTheme.Spacing.sm) {
            ForEach(searchManager.configuredProviders) { provider in
                Button(action: {
                    selectedProvider = provider
                    showProviderPicker = false
                }) {
                    HStack(spacing: AetherTheme.Spacing.md) {
                        Image(systemName: provider.icon)
                            .font(.system(size: 12))
                            .foregroundColor(providerColor(provider))
                            .frame(width: 20)

                        Text(provider.rawValue)
                            .font(AetherTheme.Typography.body)
                            .foregroundColor(AetherTheme.Colors.textPrimary)

                        Spacer()

                        if selectedProvider == provider {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AetherTheme.Colors.accent)
                        }
                    }
                    .padding(.horizontal, AetherTheme.Spacing.lg)
                    .padding(.vertical, AetherTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AetherTheme.Radius.md, style: .continuous)
                            .fill(selectedProvider == provider ? AetherTheme.Colors.accentSubtle : .clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AetherTheme.Spacing.md)
        .frame(width: 200)
    }

    // MARK: - Actions

    private func performSearch() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        var provider = selectedProvider ?? searchManager.activeProvider

        // For media modes (Images/Videos/News), prefer Serper since it has dedicated endpoints
        let isMediaMode = selectedMode == .images || selectedMode == .videos || selectedMode == .news
        if isMediaMode, provider != .serper, searchManager.isProviderConfigured(.serper) {
            provider = .serper
        }

        Task {
            await searchManager.search(
                query: query,
                provider: provider,
                mode: selectedMode
            )
        }
    }

    private func providerColor(_ provider: SearchProviderType) -> Color {
        switch provider {
        case .serper: return .green
        case .firecrawl: return .orange
        case .exa: return .purple
        case .tavily: return AetherTheme.Colors.accent
        }
    }
}

// MARK: - Mode Pill

private struct ModePill: View {
    let mode: SearchMode
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: AetherTheme.Spacing.sm) {
                Image(systemName: mode.icon)
                    .font(.system(size: 10))
                Text(mode.rawValue)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(isSelected ? AetherTheme.Colors.accent : AetherTheme.Colors.textTertiary)
            .padding(.horizontal, AetherTheme.Spacing.lg)
            .padding(.vertical, AetherTheme.Spacing.sm + 1)
            .background(
                Capsule()
                    .fill(isSelected ? AetherTheme.Colors.accentSubtle :
                            (isHovering ? AetherTheme.Colors.glassHover : .clear))
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? AetherTheme.Colors.accent.opacity(0.2) : .clear,
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(AetherTheme.Animation.fast) { isHovering = hovering }
        }
    }
}

// MARK: - Search Result Card

private struct SearchResultCard: View {
    let result: WebSearchResult
    let isSelected: Bool
    let onSelect: () -> Void
    let onNavigate: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: AetherTheme.Spacing.md) {
                // Top row: domain + provider
                HStack(spacing: AetherTheme.Spacing.md) {
                    // Favicon placeholder
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(AetherTheme.Colors.surfaceElevated)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Text(String(result.domain.prefix(1)).uppercased())
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(AetherTheme.Colors.textTertiary)
                        )

                    Text(result.domain)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AetherTheme.Colors.textSecondary)

                    Spacer()

                    // Provider chip
                    HStack(spacing: 3) {
                        Image(systemName: result.provider.icon)
                            .font(.system(size: 7))
                        Text(result.provider.rawValue)
                            .font(.system(size: 8, weight: .semibold))
                    }
                    .foregroundColor(providerColor.opacity(0.8))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(providerColor.opacity(0.08))
                    )

                    if let score = result.score {
                        Text(String(format: "%.0f%%", score * 100))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(AetherTheme.Colors.textTertiary)
                    }
                }

                // Title
                Text(result.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? AetherTheme.Colors.accent : AetherTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Snippet
                Text(result.snippet)
                    .font(AetherTheme.Typography.caption)
                    .foregroundColor(AetherTheme.Colors.textSecondary)
                    .lineLimit(3)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)

                // Highlights
                if !result.highlights.isEmpty {
                    HStack(spacing: AetherTheme.Spacing.sm) {
                        ForEach(result.highlights.prefix(2), id: \.self) { highlight in
                            Text("\"" + highlight.prefix(60) + (highlight.count > 60 ? "..." : "") + "\"")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(AetherTheme.Colors.accent.opacity(0.8))
                                .padding(.horizontal, AetherTheme.Spacing.md)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: AetherTheme.Radius.sm, style: .continuous)
                                        .fill(AetherTheme.Colors.accentSubtle.opacity(0.5))
                                )
                                .lineLimit(1)
                        }
                    }
                }

                // Bottom actions (on hover)
                if isHovering {
                    HStack(spacing: AetherTheme.Spacing.lg) {
                        Button(action: onNavigate) {
                            Label("Open", systemImage: "arrow.up.right")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AetherTheme.Colors.accent)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(result.url, forType: .string)
                        }) {
                            Label("Copy URL", systemImage: "doc.on.doc")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AetherTheme.Colors.textTertiary)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        if let date = result.publishedDate {
                            Text(date, style: .date)
                                .font(.system(size: 9))
                                .foregroundColor(AetherTheme.Colors.textTertiary)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(AetherTheme.Spacing.xl)
            .background(
                ZStack {
                    VisualEffectBlur(material: .popover)
                    (isSelected ? AetherTheme.Colors.accentSubtle.opacity(0.3) :
                        (isHovering ? AetherTheme.Colors.glassHover : AetherTheme.Colors.glassCard))
                        .opacity(0.5)
                }
                .clipShape(RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous)
                    .strokeBorder(
                        isSelected ? AetherTheme.Colors.accent.opacity(0.3) :
                            AetherTheme.Colors.glassBorderSubtle,
                        lineWidth: isSelected ? 1 : 0.5
                    )
            )
            .shadow(color: AetherTheme.Colors.shadowSubtle, radius: isHovering ? 12 : 6, x: 0, y: isHovering ? 4 : 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(AetherTheme.Animation.fast) { isHovering = hovering }
        }
        .animation(AetherTheme.Animation.fast, value: isHovering)
    }

    private var providerColor: Color {
        switch result.provider {
        case .serper: return .green
        case .firecrawl: return .orange
        case .exa: return .purple
        case .tavily: return AetherTheme.Colors.accent
        }
    }
}

// MARK: - AI Answer Card

private struct AIAnswerCard: View {
    let answer: String
    let provider: SearchProviderType

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: AetherTheme.Spacing.lg) {
            Button(action: { withAnimation(AetherTheme.Animation.spring) { isExpanded.toggle() } }) {
                HStack(spacing: AetherTheme.Spacing.md) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AetherTheme.Colors.accent)

                    Text("AI Answer")
                        .font(AetherTheme.Typography.captionMedium)
                        .foregroundColor(AetherTheme.Colors.textPrimary)

                    Text("from \(provider.rawValue)")
                        .font(.system(size: 10))
                        .foregroundColor(AetherTheme.Colors.textTertiary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(answer)
                    .font(AetherTheme.Typography.body)
                    .foregroundColor(AetherTheme.Colors.textPrimary)
                    .lineSpacing(3)
                    .textSelection(.enabled)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(AetherTheme.Spacing.xl)
        .background(
            ZStack {
                VisualEffectBlur(material: .popover)
                LinearGradient(
                    colors: [
                        AetherTheme.Colors.accentSubtle.opacity(0.4),
                        AetherTheme.Colors.accentSubtle.opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous)
                .strokeBorder(AetherTheme.Colors.accent.opacity(0.15), lineWidth: 0.5)
        )
    }
}

// MARK: - Result Preview Pane

private struct ResultPreviewPane: View {
    let result: WebSearchResult
    let onNavigate: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AetherTheme.Spacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: AetherTheme.Spacing.md) {
                    HStack(spacing: AetherTheme.Spacing.md) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(AetherTheme.Colors.surfaceElevated)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text(String(result.domain.prefix(1)).uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(AetherTheme.Colors.textTertiary)
                            )

                        Text(result.domain)
                            .font(AetherTheme.Typography.captionMedium)
                            .foregroundColor(AetherTheme.Colors.textSecondary)

                        Spacer()
                    }

                    Text(result.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AetherTheme.Colors.textPrimary)
                        .lineSpacing(2)

                    Text(result.url)
                        .font(.system(size: 10))
                        .foregroundColor(AetherTheme.Colors.accent)
                        .lineLimit(2)
                }

                Divider()
                    .background(AetherTheme.Colors.glassBorderSubtle)

                // Content
                if let rawContent = result.rawContent, !rawContent.isEmpty {
                    Text(rawContent.prefix(2000))
                        .font(AetherTheme.Typography.body)
                        .foregroundColor(AetherTheme.Colors.textPrimary)
                        .lineSpacing(3)
                        .textSelection(.enabled)
                } else {
                    Text(result.snippet)
                        .font(AetherTheme.Typography.body)
                        .foregroundColor(AetherTheme.Colors.textPrimary)
                        .lineSpacing(3)
                        .textSelection(.enabled)
                }

                // Highlights
                if !result.highlights.isEmpty {
                    VStack(alignment: .leading, spacing: AetherTheme.Spacing.md) {
                        Text("Key Highlights")
                            .font(AetherTheme.Typography.captionMedium)
                            .foregroundColor(AetherTheme.Colors.textTertiary)

                        ForEach(result.highlights, id: \.self) { highlight in
                            HStack(alignment: .top, spacing: AetherTheme.Spacing.md) {
                                Rectangle()
                                    .fill(AetherTheme.Colors.accent)
                                    .frame(width: 2)

                                Text(highlight)
                                    .font(AetherTheme.Typography.caption)
                                    .foregroundColor(AetherTheme.Colors.textSecondary)
                                    .lineSpacing(2)
                            }
                            .padding(.vertical, AetherTheme.Spacing.sm)
                        }
                    }
                }

                // Metadata
                VStack(alignment: .leading, spacing: AetherTheme.Spacing.md) {
                    if let score = result.score {
                        metadataRow("Relevance", value: String(format: "%.0f%%", score * 100))
                    }
                    if let date = result.publishedDate {
                        metadataRow("Published", value: date.formatted(date: .abbreviated, time: .omitted))
                    }
                    metadataRow("Provider", value: result.provider.rawValue)
                }

                // Open button
                Button(action: onNavigate) {
                    HStack {
                        Spacer()
                        Label("Open in Browser", systemImage: "arrow.up.right")
                            .font(AetherTheme.Typography.captionMedium)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, AetherTheme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AetherTheme.Radius.lg, style: .continuous)
                            .fill(AetherTheme.Colors.accent)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(AetherTheme.Spacing.xl)
        }
        .background(AetherTheme.Colors.background.opacity(0.5))
    }

    private func metadataRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AetherTheme.Typography.caption)
                .foregroundColor(AetherTheme.Colors.textTertiary)
            Spacer()
            Text(value)
                .font(AetherTheme.Typography.captionMedium)
                .foregroundColor(AetherTheme.Colors.textSecondary)
        }
    }
}

// MARK: - Skeleton Result Card

private struct SkeletonResultCard: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: AetherTheme.Spacing.md) {
            HStack(spacing: AetherTheme.Spacing.md) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(shimmerGradient)
                    .frame(width: 16, height: 16)

                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(shimmerGradient)
                    .frame(width: 100, height: 12)

                Spacer()
            }

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(shimmerGradient)
                .frame(height: 16)
                .frame(maxWidth: 280)

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(shimmerGradient)
                .frame(height: 12)

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(shimmerGradient)
                .frame(height: 12)
                .frame(maxWidth: 240)
        }
        .padding(AetherTheme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous)
                .fill(AetherTheme.Colors.glassCard.opacity(0.3))
        )
        .onAppear { isAnimating = true }
    }

    private var shimmerGradient: some ShapeStyle {
        AetherTheme.Colors.surfaceElevated.opacity(isAnimating ? 0.6 : 0.3)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

// MARK: - Knowledge Graph Card

private struct KnowledgeGraphCard: View {
    let kg: KnowledgeGraphResult
    let onNavigate: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AetherTheme.Spacing.lg) {
            HStack(spacing: AetherTheme.Spacing.lg) {
                // Image placeholder
                if kg.imageUrl != nil {
                    AsyncImage(url: URL(string: kg.imageUrl!)) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: AetherTheme.Radius.md, style: .continuous)
                            .fill(AetherTheme.Colors.surfaceElevated)
                    }
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: AetherTheme.Radius.md, style: .continuous))
                }

                VStack(alignment: .leading, spacing: AetherTheme.Spacing.sm) {
                    Text(kg.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AetherTheme.Colors.textPrimary)

                    if let type = kg.type {
                        Text(type)
                            .font(AetherTheme.Typography.caption)
                            .foregroundColor(AetherTheme.Colors.accent)
                    }
                }
                Spacer()
            }

            if let desc = kg.description {
                Text(desc)
                    .font(AetherTheme.Typography.body)
                    .foregroundColor(AetherTheme.Colors.textSecondary)
                    .lineSpacing(2)
            }

            // Attributes
            if !kg.attributes.isEmpty {
                let sortedKeys = kg.attributes.keys.sorted()
                VStack(spacing: AetherTheme.Spacing.sm) {
                    ForEach(sortedKeys.prefix(6), id: \.self) { key in
                        HStack {
                            Text(key)
                                .font(AetherTheme.Typography.caption)
                                .foregroundColor(AetherTheme.Colors.textTertiary)
                            Spacer()
                            Text(kg.attributes[key] ?? "")
                                .font(AetherTheme.Typography.captionMedium)
                                .foregroundColor(AetherTheme.Colors.textPrimary)
                        }
                    }
                }
            }

            if let website = kg.website {
                Button(action: { onNavigate(website) }) {
                    Label("Visit Website", systemImage: "arrow.up.right")
                        .font(AetherTheme.Typography.captionMedium)
                        .foregroundColor(AetherTheme.Colors.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AetherTheme.Spacing.xl)
        .background(
            ZStack {
                VisualEffectBlur(material: .popover)
                LinearGradient(
                    colors: [
                        AetherTheme.Colors.accentSubtle.opacity(0.3),
                        AetherTheme.Colors.glassCard.opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous)
                .strokeBorder(AetherTheme.Colors.accent.opacity(0.12), lineWidth: 0.5)
        )
    }
}

// MARK: - Image Results Grid

private struct ImageResultsGrid: View {
    let images: [ImageSearchResult]
    let onNavigate: (String) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 140, maximum: 200), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(images) { image in
                ImageResultCell(image: image, onNavigate: onNavigate)
            }
        }
    }
}

private struct ImageResultCell: View {
    let image: ImageSearchResult
    let onNavigate: (String) -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: { onNavigate(image.sourceUrl) }) {
            VStack(spacing: 0) {
                // Image
                AsyncImage(url: URL(string: image.thumbnailUrl ?? image.imageUrl)) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        ZStack {
                            AetherTheme.Colors.surfaceElevated
                            Image(systemName: "photo")
                                .foregroundColor(AetherTheme.Colors.textTertiary)
                        }
                    case .empty:
                        ZStack {
                            AetherTheme.Colors.surfaceElevated
                            ProgressView().scaleEffect(0.5)
                        }
                    @unknown default:
                        AetherTheme.Colors.surfaceElevated
                    }
                }
                .frame(height: 120)
                .clipped()

                // Title + source
                VStack(alignment: .leading, spacing: 2) {
                    Text(image.title)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AetherTheme.Colors.textPrimary)
                        .lineLimit(2)

                    Text(image.domain)
                        .font(.system(size: 9))
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                        .lineLimit(1)
                }
                .padding(.horizontal, AetherTheme.Spacing.md)
                .padding(.vertical, AetherTheme.Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.lg, style: .continuous)
                    .fill(isHovering ? AetherTheme.Colors.glassHover : AetherTheme.Colors.glassCard.opacity(0.5))
            )
            .clipShape(RoundedRectangle(cornerRadius: AetherTheme.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.lg, style: .continuous)
                    .strokeBorder(AetherTheme.Colors.glassBorderSubtle, lineWidth: 0.5)
            )
            .shadow(color: AetherTheme.Colors.shadowSubtle, radius: isHovering ? 8 : 4, x: 0, y: 2)
            .scaleEffect(isHovering ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(AetherTheme.Animation.spring) { isHovering = hovering }
        }
    }
}

// MARK: - Video Results List

private struct VideoResultsList: View {
    let videos: [VideoSearchResult]
    let onNavigate: (String) -> Void

    var body: some View {
        LazyVStack(spacing: AetherTheme.Spacing.md) {
            ForEach(videos) { video in
                VideoResultCard(video: video, onNavigate: onNavigate)
            }
        }
    }
}

private struct VideoResultCard: View {
    let video: VideoSearchResult
    let onNavigate: (String) -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: { onNavigate(video.url) }) {
            HStack(spacing: AetherTheme.Spacing.xl) {
                // Thumbnail
                ZStack {
                    if let thumbUrl = video.thumbnailUrl, let url = URL(string: thumbUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().aspectRatio(contentMode: .fill)
                            default:
                                AetherTheme.Colors.surfaceElevated
                            }
                        }
                    } else {
                        AetherTheme.Colors.surfaceElevated
                    }

                    // Play button overlay
                    Circle()
                        .fill(.black.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .offset(x: 1)
                        )

                    // Duration badge
                    if let duration = video.duration {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text(duration)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                                            .fill(.black.opacity(0.7))
                                    )
                                    .padding(4)
                            }
                        }
                    }
                }
                .frame(width: 160, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: AetherTheme.Radius.md, style: .continuous))

                // Info
                VStack(alignment: .leading, spacing: AetherTheme.Spacing.sm) {
                    Text(video.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AetherTheme.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let channel = video.channel {
                        HStack(spacing: AetherTheme.Spacing.sm) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(AetherTheme.Colors.textTertiary)
                            Text(channel)
                                .font(AetherTheme.Typography.caption)
                                .foregroundColor(AetherTheme.Colors.textSecondary)
                        }
                    }

                    if !video.snippet.isEmpty {
                        Text(video.snippet)
                            .font(.system(size: 11))
                            .foregroundColor(AetherTheme.Colors.textTertiary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    HStack(spacing: AetherTheme.Spacing.lg) {
                        if !video.source.isEmpty {
                            Text(video.source)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AetherTheme.Colors.textTertiary)
                        }
                        if let date = video.date {
                            Text(date)
                                .font(.system(size: 10))
                                .foregroundColor(AetherTheme.Colors.textTertiary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AetherTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous)
                    .fill(isHovering ? AetherTheme.Colors.glassHover : AetherTheme.Colors.glassCard.opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous)
                    .strokeBorder(AetherTheme.Colors.glassBorderSubtle, lineWidth: 0.5)
            )
            .shadow(color: AetherTheme.Colors.shadowSubtle, radius: isHovering ? 8 : 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(AetherTheme.Animation.fast) { isHovering = hovering }
        }
    }
}

// MARK: - News Results List

private struct NewsResultsList: View {
    let news: [NewsSearchResult]
    let onNavigate: (String) -> Void

    var body: some View {
        LazyVStack(spacing: AetherTheme.Spacing.md) {
            ForEach(news) { item in
                NewsResultCard(news: item, onNavigate: onNavigate)
            }
        }
    }
}

private struct NewsResultCard: View {
    let news: NewsSearchResult
    let onNavigate: (String) -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: { onNavigate(news.url) }) {
            HStack(spacing: AetherTheme.Spacing.xl) {
                // News image
                if let imageUrl = news.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().aspectRatio(contentMode: .fill)
                        default:
                            ZStack {
                                AetherTheme.Colors.surfaceElevated
                                Image(systemName: "newspaper")
                                    .foregroundColor(AetherTheme.Colors.textTertiary)
                            }
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: AetherTheme.Radius.md, style: .continuous))
                }

                VStack(alignment: .leading, spacing: AetherTheme.Spacing.sm) {
                    // Source + date
                    HStack(spacing: AetherTheme.Spacing.md) {
                        if !news.source.isEmpty {
                            Text(news.source)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(AetherTheme.Colors.accent)
                        }
                        if let date = news.date {
                            Text(date)
                                .font(.system(size: 10))
                                .foregroundColor(AetherTheme.Colors.textTertiary)
                        }
                    }

                    Text(news.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AetherTheme.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if !news.snippet.isEmpty {
                        Text(news.snippet)
                            .font(AetherTheme.Typography.caption)
                            .foregroundColor(AetherTheme.Colors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Text(news.domain)
                        .font(.system(size: 9))
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AetherTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous)
                    .fill(isHovering ? AetherTheme.Colors.glassHover : AetherTheme.Colors.glassCard.opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous)
                    .strokeBorder(AetherTheme.Colors.glassBorderSubtle, lineWidth: 0.5)
            )
            .shadow(color: AetherTheme.Colors.shadowSubtle, radius: isHovering ? 8 : 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(AetherTheme.Animation.fast) { isHovering = hovering }
        }
    }
}
