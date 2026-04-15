import SwiftUI
import AetherCore
import AetherUI

/// Download item model
@Observable
final class DownloadItem: Identifiable {
    let id = UUID()
    let fileName: String
    let url: URL
    let startedAt: Date
    var progress: Double = 0.0
    var totalBytes: Int64 = 0
    var downloadedBytes: Int64 = 0
    var status: DownloadStatus = .downloading
    var localPath: URL?

    enum DownloadStatus {
        case downloading
        case completed
        case failed(String)
        case paused
        case cancelled
    }

    init(fileName: String, url: URL) {
        self.fileName = fileName
        self.url = url
        self.startedAt = Date()
    }

    var isActive: Bool {
        if case .downloading = status { return true }
        return false
    }

    var statusText: String {
        switch status {
        case .downloading: return "\(formattedProgress) — \(formattedBytes)"
        case .completed: return "Completed — \(formattedTotalBytes)"
        case .failed(let msg): return "Failed: \(msg)"
        case .paused: return "Paused — \(formattedProgress)"
        case .cancelled: return "Cancelled"
        }
    }

    var formattedProgress: String {
        String(format: "%.0f%%", progress * 100)
    }

    var formattedBytes: String {
        ByteCountFormatter.string(fromByteCount: downloadedBytes, countStyle: .file)
    }

    var formattedTotalBytes: String {
        ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }

    var fileIcon: String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.text"
        case "zip", "tar", "gz", "rar": return "archivebox"
        case "dmg", "pkg": return "shippingbox"
        case "jpg", "jpeg", "png", "gif", "webp", "svg": return "photo"
        case "mp4", "mov", "avi", "mkv": return "film"
        case "mp3", "wav", "flac", "aac": return "music.note"
        case "html", "css", "js", "json", "xml": return "doc.plaintext"
        default: return "doc"
        }
    }
}

/// Download manager state
@Observable
final class DownloadManager {
    var downloads: [DownloadItem] = []

    var activeDownloads: [DownloadItem] {
        downloads.filter { $0.isActive }
    }

    var completedDownloads: [DownloadItem] {
        downloads.filter {
            if case .completed = $0.status { return true }
            return false
        }
    }

    func addDownload(fileName: String, url: URL) -> DownloadItem {
        let item = DownloadItem(fileName: fileName, url: url)
        downloads.insert(item, at: 0)
        return item
    }

    func removeDownload(_ id: UUID) {
        downloads.removeAll { $0.id == id }
    }

    func clearCompleted() {
        downloads.removeAll {
            if case .completed = $0.status { return true }
            return false
        }
    }

    var hasActiveDownloads: Bool {
        !activeDownloads.isEmpty
    }
}

/// Modern download manager panel
struct DownloadManagerView: View {
    @Bindable var downloadManager: DownloadManager
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AetherTheme.Colors.accent)

                Text("Downloads")
                    .font(AetherTheme.Typography.heading)
                    .foregroundColor(AetherTheme.Colors.textPrimary)

                Spacer()

                if !downloadManager.completedDownloads.isEmpty {
                    Button("Clear Completed") {
                        downloadManager.clearCompleted()
                    }
                    .font(AetherTheme.Typography.caption)
                    .foregroundColor(AetherTheme.Colors.accent)
                    .buttonStyle(.plain)
                }

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(AetherTheme.Colors.surfaceElevated))
                }
                .buttonStyle(.plain)
            }
            .padding(AetherTheme.Spacing.xl)

            Divider().background(AetherTheme.Colors.glassBorderSubtle)

            if downloadManager.downloads.isEmpty {
                // Empty state
                VStack(spacing: AetherTheme.Spacing.lg) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundColor(AetherTheme.Colors.textTertiary.opacity(0.5))

                    Text("No downloads yet")
                        .font(AetherTheme.Typography.caption)
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(AetherTheme.Spacing.xxxxl)
            } else {
                ScrollView {
                    LazyVStack(spacing: AetherTheme.Spacing.sm) {
                        // Active downloads
                        if !downloadManager.activeDownloads.isEmpty {
                            sectionHeader("Active")
                            ForEach(downloadManager.activeDownloads) { item in
                                DownloadItemRow(item: item, onRemove: {
                                    downloadManager.removeDownload(item.id)
                                })
                            }
                        }

                        // Completed
                        if !downloadManager.completedDownloads.isEmpty {
                            sectionHeader("Completed")
                            ForEach(downloadManager.completedDownloads) { item in
                                DownloadItemRow(item: item, onRemove: {
                                    downloadManager.removeDownload(item.id)
                                })
                            }
                        }
                    }
                    .padding(AetherTheme.Spacing.md)
                }
            }
        }
        .frame(width: 340)
        .background(
            ZStack {
                VisualEffectBlur(material: .sidebar)
                AetherTheme.Colors.glassBackground.opacity(0.3)
            }
        )
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundColor(AetherTheme.Colors.textTertiary)
            .tracking(0.5)
            .padding(.horizontal, AetherTheme.Spacing.md)
            .padding(.top, AetherTheme.Spacing.md)
    }
}

// MARK: - Download Item Row

private struct DownloadItemRow: View {
    @Bindable var item: DownloadItem
    let onRemove: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: AetherTheme.Spacing.lg) {
            // File icon
            ZStack {
                RoundedRectangle(cornerRadius: AetherTheme.Radius.md, style: .continuous)
                    .fill(AetherTheme.Colors.surfaceElevated)
                    .frame(width: 36, height: 36)

                Image(systemName: item.fileIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AetherTheme.Colors.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.fileName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AetherTheme.Colors.textPrimary)
                    .lineLimit(1)

                Text(item.statusText)
                    .font(.system(size: 10))
                    .foregroundColor(statusColor)

                // Progress bar
                if item.isActive {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(AetherTheme.Colors.surfaceElevated)

                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(AetherTheme.Colors.accent)
                                .frame(width: geo.size.width * item.progress)
                                .animation(AetherTheme.Animation.spring, value: item.progress)
                        }
                    }
                    .frame(height: 3)
                }
            }

            Spacer()

            // Actions
            if isHovering {
                HStack(spacing: AetherTheme.Spacing.sm) {
                    if case .completed = item.status, let path = item.localPath {
                        Button(action: { NSWorkspace.shared.open(path) }) {
                            Image(systemName: "folder")
                                .font(.system(size: 10))
                                .foregroundColor(AetherTheme.Colors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: onRemove) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(AetherTheme.Colors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, AetherTheme.Spacing.lg)
        .padding(.vertical, AetherTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AetherTheme.Radius.lg, style: .continuous)
                .fill(isHovering ? AetherTheme.Colors.glassHover : .clear)
        )
        .onHover { hovering in
            withAnimation(AetherTheme.Animation.fast) { isHovering = hovering }
        }
    }

    private var statusColor: Color {
        switch item.status {
        case .downloading: return AetherTheme.Colors.accent
        case .completed: return AetherTheme.Colors.success
        case .failed: return AetherTheme.Colors.error
        case .paused: return AetherTheme.Colors.warning
        case .cancelled: return AetherTheme.Colors.textTertiary
        }
    }
}
