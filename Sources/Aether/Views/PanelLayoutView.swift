import SwiftUI
import AetherCore
import AetherUI
import TabManager
import WebSearchService
import HistoryEngine
import BookmarkEngine

struct PanelLayoutView: View {
    @Bindable var tabStore: TabStore
    let layout: PanelNode
    var searchManager: SearchManager?
    var historyManager: HistoryManager?
    var bookmarkManager: BookmarkManager?
    var onShowSettings: (() -> Void)?
    var onShowWebSearch: (() -> Void)?

    var body: some View {
        renderNode(layout)
    }

    private func renderNode(_ node: PanelNode) -> AnyView {
        switch node {
        case .leaf(let panelId):
            return AnyView(
                PanelView(
                    tabStore: tabStore,
                    panelId: panelId,
                    searchManager: searchManager,
                    historyManager: historyManager,
                    bookmarkManager: bookmarkManager,
                    onShowSettings: onShowSettings,
                    onShowWebSearch: onShowWebSearch
                )
            )

        case .split(let axis, _, let first, let second):
            switch axis {
            case .horizontal:
                return AnyView(
                    HSplitView {
                        renderNode(first)
                            .frame(minWidth: AetherTheme.Sizes.minPanelWidth)
                        renderNode(second)
                            .frame(minWidth: AetherTheme.Sizes.minPanelWidth)
                    }
                )

            case .vertical:
                return AnyView(
                    VSplitView {
                        renderNode(first)
                            .frame(minHeight: AetherTheme.Sizes.minPanelHeight)
                        renderNode(second)
                            .frame(minHeight: AetherTheme.Sizes.minPanelHeight)
                    }
                )
            }
        }
    }
}
