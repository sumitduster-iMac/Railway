import AppKit
import SwiftUI
import WebKit

@MainActor
final class WebViewModel: NSObject, ObservableObject {
    // MARK: - Configuration

    /// When enabled, navigation to non-Railway hosts will be opened in the default browser.
    @Published var openExternalLinksInBrowser: Bool = false

    // MARK: - Web state

    @Published private(set) var title: String = "Railway"
    @Published private(set) var currentURL: URL?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var estimatedProgress: Double = 0
    @Published private(set) var canGoBack: Bool = false
    @Published private(set) var canGoForward: Bool = false
    @Published private(set) var lastErrorMessage: String?

    let webView: WKWebView

    private var observations: [NSKeyValueObservation] = []

    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        self.webView = webView

        super.init()

        webView.navigationDelegate = self
        webView.uiDelegate = self

        observations = [
            webView.observe(\.title, options: [.initial, .new]) { [weak self] _, _ in
                guard let self else { return }
                Task { @MainActor in self.title = self.webView.title ?? "Railway" }
            },
            webView.observe(\.url, options: [.initial, .new]) { [weak self] _, _ in
                guard let self else { return }
                Task { @MainActor in self.currentURL = self.webView.url }
            },
            webView.observe(\.isLoading, options: [.initial, .new]) { [weak self] _, _ in
                guard let self else { return }
                Task { @MainActor in self.isLoading = self.webView.isLoading }
            },
            webView.observe(\.estimatedProgress, options: [.initial, .new]) { [weak self] _, _ in
                guard let self else { return }
                Task { @MainActor in self.estimatedProgress = self.webView.estimatedProgress }
            },
            webView.observe(\.canGoBack, options: [.initial, .new]) { [weak self] _, _ in
                guard let self else { return }
                Task { @MainActor in self.canGoBack = self.webView.canGoBack }
            },
            webView.observe(\.canGoForward, options: [.initial, .new]) { [weak self] _, _ in
                guard let self else { return }
                Task { @MainActor in self.canGoForward = self.webView.canGoForward }
            },
        ]
    }

    // MARK: - Actions

    func load(_ url: URL) {
        lastErrorMessage = nil
        if currentURL?.absoluteString == url.absoluteString { return }
        webView.load(URLRequest(url: url))
    }

    func reload() {
        lastErrorMessage = nil
        webView.reload()
    }

    func stopLoading() {
        webView.stopLoading()
    }

    func goBack() {
        guard canGoBack else { return }
        lastErrorMessage = nil
        webView.goBack()
    }

    func goForward() {
        guard canGoForward else { return }
        lastErrorMessage = nil
        webView.goForward()
    }

    func openInBrowser() {
        guard let url = currentURL else { return }
        NSWorkspace.shared.open(url)
    }

    func clearWebsiteData() async {
        lastErrorMessage = nil
        let store = WKWebsiteDataStore.default()
        let all = WKWebsiteDataStore.allWebsiteDataTypes()
        let since = Date(timeIntervalSince1970: 0)
        await withCheckedContinuation { continuation in
            store.removeData(ofTypes: all, modifiedSince: since) {
                continuation.resume()
            }
        }
        reload()
    }

    // MARK: - Helpers

    private func isRailwayHost(_ host: String) -> Bool {
        let h = host.lowercased()
        return h == "railway.com" || h.hasSuffix(".railway.com") || h == "railway.app" || h.hasSuffix(".railway.app")
    }
}

extension WebViewModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard openExternalLinksInBrowser,
              let url = navigationAction.request.url,
              let host = url.host,
              !isRailwayHost(host)
        else {
            decisionHandler(.allow)
            return
        }

        NSWorkspace.shared.open(url)
        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        lastErrorMessage = error.localizedDescription
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        lastErrorMessage = error.localizedDescription
    }
}

extension WebViewModel: WKUIDelegate {
    /// Open `target="_blank"` links in the same webview.
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}

struct WebView: NSViewRepresentable {
    @ObservedObject var model: WebViewModel

    func makeNSView(context: Context) -> WKWebView {
        model.webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // All navigation is driven by the model.
    }
}
