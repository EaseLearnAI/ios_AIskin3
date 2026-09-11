import SwiftUI
import WebKit

enum LegalDocument: String, Identifiable {
    case terms, privacy
    var id: Self { self }
    var title: String { self == .terms ? "使用条款" : "隐私政策" }
    var resourceURL: URL? { Bundle.main.url(forResource: rawValue, withExtension: "html") }
}

/// Reads the existing public-pages source packaged by Xcode's Resources phase.
/// Text selection, scrolling, and link activation remain native WebKit behavior.
struct LegalDocumentView: View {
    let document: LegalDocument
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var reloadID = UUID()

    var body: some View {
        AISkinScreenBackground {
            VStack(spacing: 0) {
                AISkinHeader {
                    AISkinIconButton(systemName: "chevron.left", accessibilityLabel: "返回", variant: .navigation) { dismiss() }
                        .accessibilityIdentifier("legal.back")
                } title: {
                    Text(document.title).font(AISkinTypography.screenTitle).foregroundStyle(AISkinColor.textPrimary)
                } trailing: { EmptyView() }
                if let url = document.resourceURL {
                    ZStack {
                        LegalHTMLReader(url: url, isLoading: $isLoading, loadError: $loadError)
                            .id(reloadID)
                        if isLoading {
                            ProgressView("正在加载文档…").tint(AISkinColor.accent)
                        }
                        if let loadError {
                            AISkinStateView(content: .error(title: "文档暂时无法打开", message: loadError), actionTitle: "重试", action: {
                                self.loadError = nil
                                isLoading = true
                                reloadID = UUID()
                            })
                            .padding(AISkinSpacing.screenEdge)
                        }
                    }
                } else {
                    AISkinStateView(content: .error(title: "文档资源缺失", message: "应用未包含这份文档，请更新应用后重试。"))
                        .padding(AISkinSpacing.screenEdge)
                        .frame(maxHeight: .infinity)
                }
            }
        }
    }
}

private struct LegalHTMLReader: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var loadError: String?

    func makeCoordinator() -> Coordinator { Coordinator(isLoading: $isLoading, loadError: $loadError) }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        // The source documents contain only HTML/CSS. Reading needs no script
        // execution or web account session.
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        configuration.websiteDataStore = .nonPersistent()
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.isOpaque = false
        view.backgroundColor = .clear
        view.scrollView.backgroundColor = .clear
        view.allowsLinkPreview = true
        do {
            let source = try String(contentsOf: url, encoding: .utf8)
            view.loadHTMLString(AISkinLegalDocumentStyle.applying(to: source), baseURL: url.deletingLastPathComponent())
        } catch {
            Task { @MainActor in
                isLoading = false
                loadError = "文档读取失败，请重试。"
            }
        }
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        @Binding var loadError: String?

        init(isLoading: Binding<Bool>, loadError: Binding<String?>) {
            _isLoading = isLoading
            _loadError = loadError
        }

        nonisolated deinit {}

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
            loadError = nil
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading = false
            loadError = "文档读取失败，请重试。"
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            isLoading = false
            loadError = "文档读取失败，请重试。"
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard let url = navigationAction.request.url else { return .cancel }
            // loadHTMLString begins with about:blank; in-document anchors may
            // also target it. Both remain local WebKit navigation.
            if url.isFileURL || (url.scheme == "about" && url.path == "blank") { return .allow }
            if navigationAction.navigationType == .linkActivated,
               ["mailto", "https", "http", "tel"].contains(url.scheme?.lowercased() ?? "") {
                await UIApplication.shared.open(url)
            }
            return .cancel
        }
    }
}
