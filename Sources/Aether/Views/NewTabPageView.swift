import SwiftUI
import AetherCore
import AetherUI
import WebSearchService
import HistoryEngine
import BookmarkEngine

/// Premium new tab page with recent sites, bookmarks, and search
struct NewTabPageView: View {
    let searchManager: SearchManager?
    let historyManager: HistoryManager?
    let bookmarkManager: BookmarkManager?
    let onNavigate: (String) -> Void
    let onWebSearch: () -> Void
    let onSettings: () -> Void

    @State private var searchQuery: String = ""
    @State private var currentTime = Date()
    @FocusState private var focused: Bool

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    AetherTheme.Colors.newTabGradient1,
                    AetherTheme.Colors.newTabGradient2
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [AetherTheme.Colors.accent.opacity(0.03), .clear],
                center: .center,
                startRadius: 50,
                endRadius: 500
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)

                    // Clock
                    VStack(spacing: AetherTheme.Spacing.md) {
                        Text(timeString)
                            .font(.system(size: 56, weight: .ultraLight, design: .rounded))
                            .foregroundColor(AetherTheme.Colors.textPrimary)
                            .monospacedDigit()

                        Text(dateString)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AetherTheme.Colors.textTertiary)
                    }
                    .onReceive(timer) { _ in currentTime = Date() }

                    Spacer().frame(height: 40)

                    // Search bar
                    HStack(spacing: AetherTheme.Spacing.lg) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AetherTheme.Colors.textTertiary)

                        TextField("Search the web or enter a URL...", text: $searchQuery)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(AetherTheme.Colors.textPrimary)
                            .focused($focused)
                            .onSubmit {
                                if !searchQuery.isEmpty { onNavigate(searchQuery) }
                            }

                        if !searchQuery.isEmpty {
                            Button(action: { searchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(AetherTheme.Colors.textTertiary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AetherTheme.Spacing.xxl)
                    .padding(.vertical, AetherTheme.Spacing.xl)
                    .frame(maxWidth: 580)
                    .background(
                        ZStack {
                            VisualEffectBlur(material: .popover)
                            AetherTheme.Colors.glassSurface.opacity(0.35)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: AetherTheme.Radius.xxl, style: .continuous))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AetherTheme.Radius.xxl, style: .continuous)
                            .strokeBorder(
                                focused ? AetherTheme.Colors.accent.opacity(0.4) : AetherTheme.Colors.glassBorder,
                                lineWidth: focused ? 1.5 : 0.5
                            )
                    )
                    .shadow(color: AetherTheme.Colors.shadowColor, radius: 20, x: 0, y: 8)

                    Spacer().frame(height: 36)

                    // Quick actions
                    HStack(spacing: AetherTheme.Spacing.xl) {
                        if let searchManager, !searchManager.configuredProviders.isEmpty {
                            QuickAction(icon: "sparkle.magnifyingglass", label: "AI Search", color: AetherTheme.Colors.accent, action: onWebSearch)
                        }
                        QuickAction(icon: "gear", label: "Settings", color: AetherTheme.Colors.textSecondary, action: onSettings)
                    }

                    // Recent sites
                    if let historyManager, !historyManager.recentHistory.isEmpty {
                        VStack(alignment: .leading, spacing: AetherTheme.Spacing.lg) {
                            Text("RECENT")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(AetherTheme.Colors.textTertiary)
                                .tracking(0.8)

                            let uniqueSites = recentUniqueSites(historyManager.recentHistory)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90, maximum: 110), spacing: AetherTheme.Spacing.lg)], spacing: AetherTheme.Spacing.lg) {
                                ForEach(uniqueSites, id: \.url) { site in
                                    SiteCard(title: site.title, domain: site.domain, action: { onNavigate(site.url) })
                                }
                            }
                        }
                        .frame(maxWidth: 580)
                        .padding(.top, AetherTheme.Spacing.xxxl)
                    }

                    // Quick bookmarks
                    if let bookmarkManager, !bookmarkManager.bookmarks.isEmpty {
                        VStack(alignment: .leading, spacing: AetherTheme.Spacing.lg) {
                            Text("BOOKMARKS")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(AetherTheme.Colors.textTertiary)
                                .tracking(0.8)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90, maximum: 110), spacing: AetherTheme.Spacing.lg)], spacing: AetherTheme.Spacing.lg) {
                                ForEach(bookmarkManager.bookmarks.prefix(8)) { bookmark in
                                    SiteCard(
                                        title: bookmark.title,
                                        domain: URL(string: bookmark.url)?.host() ?? bookmark.url,
                                        action: { onNavigate(bookmark.url) }
                                    )
                                }
                            }
                        }
                        .frame(maxWidth: 580)
                        .padding(.top, AetherTheme.Spacing.xxl)
                    }

                    Spacer().frame(height: 60)

                    // Branding
                    HStack(spacing: AetherTheme.Spacing.md) {
                        Image(systemName: "globe.desk")
                            .font(.system(size: 11, weight: .light))
                            .foregroundColor(AetherTheme.Colors.textTertiary.opacity(0.4))
                        Text("Aether")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(AetherTheme.Colors.textTertiary.opacity(0.4))
                    }
                    .padding(.bottom, AetherTheme.Spacing.xxl)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: currentTime)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: currentTime)
    }

    /// Deduplicate history to show unique recent sites
    private func recentUniqueSites(_ entries: [HistoryEntry]) -> [(title: String, domain: String, url: String)] {
        var seen = Set<String>()
        var result: [(title: String, domain: String, url: String)] = []
        for entry in entries {
            let domain = URL(string: entry.url)?.host() ?? entry.url
            if !seen.contains(domain) {
                seen.insert(domain)
                result.append((title: entry.title ?? domain, domain: domain, url: entry.url))
            }
            if result.count >= 8 { break }
        }
        return result
    }
}

// MARK: - Quick Action

private struct QuickAction: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: AetherTheme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AetherTheme.Radius.lg, style: .continuous)
                        .fill(isHovering ? AetherTheme.Colors.glassHover : AetherTheme.Colors.glassSurface.opacity(0.4))
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: AetherTheme.Radius.lg, style: .continuous)
                                .strokeBorder(AetherTheme.Colors.glassBorder, lineWidth: 0.5)
                        )
                        .shadow(color: AetherTheme.Colors.shadowSubtle, radius: isHovering ? 8 : 4, y: 2)

                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .light))
                        .foregroundColor(isHovering ? AetherTheme.Colors.accent : color)
                }

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AetherTheme.Colors.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovering ? 1.05 : 1.0)
        .onHover { hovering in
            withAnimation(AetherTheme.Animation.spring) { isHovering = hovering }
        }
    }
}

// MARK: - Site Card

private struct SiteCard: View {
    let title: String
    let domain: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: AetherTheme.Spacing.md) {
                // Favicon placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: AetherTheme.Radius.md, style: .continuous)
                        .fill(isHovering ? AetherTheme.Colors.glassHover : AetherTheme.Colors.glassSurface.opacity(0.5))
                        .frame(width: 44, height: 44)

                    Text(String(domain.prefix(1)).uppercased())
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AetherTheme.Colors.accent.opacity(0.7))
                }

                Text(domain)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AetherTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
            .frame(width: 90)
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovering ? 1.04 : 1.0)
        .onHover { hovering in
            withAnimation(AetherTheme.Animation.spring) { isHovering = hovering }
        }
    }
}
