import SwiftUI
import WebKit

struct HvpInAppWebView: UIViewRepresentable {
    let url: URL
    var bundledFile: String?

    func makeCoordinator() -> HvpWebNav {
        HvpWebNav(bundledFile: bundledFile)
    }

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true
        view.scrollView.alwaysBounceVertical = true
        let blush = UIColor(red: 0.965, green: 0.933, blue: 0.945, alpha: 1)
        view.backgroundColor = blush
        view.scrollView.backgroundColor = blush
        view.isOpaque = true
        context.coordinator.attach(view)
        view.load(URLRequest(url: url))
        return view
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}

final class HvpWebNav: NSObject, WKNavigationDelegate, WKUIDelegate {
    let bundledFile: String?
    private var usedFallback = false

    init(bundledFile: String?) {
        self.bundledFile = bundledFile
    }

    func attach(_ webView: WKWebView) {
        if bundledFile != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self, weak webView] in
                guard let self, let webView else { return }
                self.loadBundleIfRemoteFailed(webView)
            }
        }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        let scheme = (url.scheme ?? "").lowercased()
        if scheme.isEmpty || scheme == "http" || scheme == "https" || scheme == "about" || scheme == "file" {
            decisionHandler(.allow)
            return
        }
        decisionHandler(.cancel)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        if let http = navigationResponse.response as? HTTPURLResponse, http.statusCode >= 400 {
            decisionHandler(.cancel)
            loadBundle(into: webView)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        loadBundle(into: webView)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadBundle(into: webView)
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil,
           let url = navigationAction.request.url,
           let scheme = url.scheme?.lowercased(),
           scheme == "http" || scheme == "https" {
            webView.load(URLRequest(url: url))
        }
        return nil
    }

    private func loadBundleIfRemoteFailed(_ webView: WKWebView) {
        let href = webView.url?.absoluteString ?? ""
        if href.isEmpty || href.contains("surge.sh") {
            webView.evaluateJavaScript("document.body ? document.body.innerText : ''") { result, _ in
                let text = (result as? String) ?? ""
                if text.count < 40 || text.lowercased().contains("forbidden") {
                    self.loadBundle(into: webView)
                }
            }
        }
    }

    private func loadBundle(into webView: WKWebView) {
        guard !usedFallback, let name = bundledFile,
              let file = Bundle.main.url(forResource: name, withExtension: "html") else { return }
        usedFallback = true
        webView.loadFileURL(file, allowingReadAccessTo: file.deletingLastPathComponent())
    }
}