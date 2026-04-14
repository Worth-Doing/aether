import Foundation
import WebKit
import AetherCore

public final class WebViewCoordinator: NSObject, ObservableObject {
    public let webView: WKWebView
    private let tabId: UUID

    @Published public var currentURL: URL?
    @Published public var pageTitle: String = ""
    @Published public var isLoading: Bool = false
    @Published public var canGoBack: Bool = false
    @Published public var canGoForward: Bool = false
    @Published public var estimatedProgress: Double = 0

    public var onNavigationCommitted: ((URL, String?) -> Void)?
    public var onNavigationFinished: ((URL, String?) -> Void)?
    public var onNavigationFailed: ((Error) -> Void)?

    private var progressObservation: NSKeyValueObservation?
    private var titleObservation: NSKeyValueObservation?
    private var urlObservation: NSKeyValueObservation?
    private var canGoBackObservation: NSKeyValueObservation?
    private var canGoForwardObservation: NSKeyValueObservation?
    private var loadingObservation: NSKeyValueObservation?

    public init(tabId: UUID) {
        self.tabId = tabId

        let config = WKWebViewConfiguration()
        config.preferences.isElementFullscreenEnabled = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsMagnification = true
        self.webView = webView

        super.init()

        webView.navigationDelegate = self
        webView.uiDelegate = self
        setupObservations()
    }

    private func setupObservations() {
        progressObservation = webView.observe(\.estimatedProgress) { [weak self] wv, _ in
            DispatchQueue.main.async { self?.estimatedProgress = wv.estimatedProgress }
        }
        titleObservation = webView.observe(\.title) { [weak self] wv, _ in
            DispatchQueue.main.async { self?.pageTitle = wv.title ?? "" }
        }
        urlObservation = webView.observe(\.url) { [weak self] wv, _ in
            DispatchQueue.main.async { self?.currentURL = wv.url }
        }
        canGoBackObservation = webView.observe(\.canGoBack) { [weak self] wv, _ in
            DispatchQueue.main.async { self?.canGoBack = wv.canGoBack }
        }
        canGoForwardObservation = webView.observe(\.canGoForward) { [weak self] wv, _ in
            DispatchQueue.main.async { self?.canGoForward = wv.canGoForward }
        }
        loadingObservation = webView.observe(\.isLoading) { [weak self] wv, _ in
            DispatchQueue.main.async { self?.isLoading = wv.isLoading }
        }
    }

    // MARK: - Navigation Actions

    public func load(url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }

    public func load(urlString: String) {
        if let url = URL(string: urlString), url.scheme != nil {
            load(url: url)
        } else if let url = URL(string: "https://\(urlString)") {
            load(url: url)
        }
    }

    public func loadSearch(query: String) {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        if let url = URL(string: "https://duckduckgo.com/?q=\(encoded)") {
            load(url: url)
        }
    }

    public func goBack() {
        webView.goBack()
    }

    public func goForward() {
        webView.goForward()
    }

    public func reload() {
        webView.reload()
    }

    public func hardReload() {
        webView.reloadFromOrigin()
    }

    public func stopLoading() {
        webView.stopLoading()
    }

    // MARK: - Content Extraction

    public func extractPageText(completion: @escaping (String?) -> Void) {
        let js = "document.body.innerText"
        webView.evaluateJavaScript(js) { result, _ in
            completion(result as? String)
        }
    }

    public func extractPageHTML(completion: @escaping (String?) -> Void) {
        let js = "document.documentElement.outerHTML"
        webView.evaluateJavaScript(js) { result, _ in
            completion(result as? String)
        }
    }
}

// MARK: - WKNavigationDelegate

extension WebViewCoordinator: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let url = webView.url {
            onNavigationCommitted?(url, webView.title)
        }
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url {
            onNavigationFinished?(url, webView.title)
        }
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        onNavigationFailed?(error)
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        onNavigationFailed?(error)
    }

    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        decisionHandler(.allow)
    }
}

// MARK: - WKUIDelegate

extension WebViewCoordinator: WKUIDelegate {
    public func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        // Open target="_blank" links in the same view
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
