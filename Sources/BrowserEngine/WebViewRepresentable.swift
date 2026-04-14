import SwiftUI
import WebKit

public struct WebViewRepresentable: NSViewRepresentable {
    let coordinator: WebViewCoordinator

    public init(coordinator: WebViewCoordinator) {
        self.coordinator = coordinator
    }

    public func makeNSView(context: Context) -> WKWebView {
        coordinator.webView
    }

    public func updateNSView(_ nsView: WKWebView, context: Context) {
        // Updates handled by coordinator KVO
    }
}
