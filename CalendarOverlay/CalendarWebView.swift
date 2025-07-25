//
//  CalendarWebView.swift
//  CalendarOverlay
//
//  Created by nharu on 2025/07/25.
//


import SwiftUI
import WebKit

struct CalendarWebView: NSViewRepresentable {
    let url: URL
    @State private var isLoading = true
    @State private var hasError = false
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // データストアを設定（永続化）
        // 固定IDでデータストアを作成してCookieなどを永続化
        let storeIdentifier = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
        let persistentDataStore = WKWebsiteDataStore(forIdentifier: storeIdentifier)
        configuration.websiteDataStore = persistentDataStore
        print("📁 Using persistent data store")
        
        // Safariと同じユーザーエージェントを設定
        let macOSVersion = ProcessInfo.processInfo.operatingSystemVersion
        let safariVersion = "17.2.1"
        let webKitVersion = "605.1.15"
        configuration.applicationNameForUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X \(macOSVersion.majorVersion)_\(macOSVersion.minorVersion)_\(macOSVersion.patchVersion)) AppleWebKit/\(webKitVersion) (KHTML, like Gecko) Version/\(safariVersion) Safari/\(webKitVersion)"
        
        // セキュリティ設定
        configuration.preferences.javaScriptEnabled = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        // Safariと同じ設定を適用
        configuration.processPool = WKProcessPool()
        configuration.suppressesIncrementalRendering = false
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        
        // 半透明設定
        webView.setValue(false, forKey: "drawsBackground")
        
        // ディスパッチキューを使って確実に背景を透明化
        DispatchQueue.main.async {
            if let scrollView = webView.subviews.first(where: { $0 is NSScrollView }) as? NSScrollView {
                scrollView.drawsBackground = false
                scrollView.backgroundColor = NSColor.clear
            }
            
            // WebViewの全てのサブビューを透明化
            webView.subviews.forEach { subview in
                if let scrollView = subview as? NSScrollView {
                    scrollView.drawsBackground = false
                    scrollView.backgroundColor = NSColor.clear
                }
            }
        }
        
        // Safariの動作を模倣
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsMagnification = true
        webView.allowsLinkPreview = true
        
        // SafariのUser Agentを再設定（customUserAgentで上書き）
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X \(macOSVersion.majorVersion)_\(macOSVersion.minorVersion)_\(macOSVersion.patchVersion)) AppleWebKit/\(webKitVersion) (KHTML, like Gecko) Version/\(safariVersion) Safari/\(webKitVersion)"
        
        // デリゲートを設定
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // 初期ロード（Safariと同じヘッダーを設定）
        print("🌐 Loading URL: \(url)")
        var request = URLRequest(url: url)
        
        // Safariと同じHTTPヘッダーを設定
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("1", forHTTPHeaderField: "DNT")
        request.setValue("same-origin", forHTTPHeaderField: "Sec-Fetch-Site")
        request.setValue("navigate", forHTTPHeaderField: "Sec-Fetch-Mode")
        request.setValue("document", forHTTPHeaderField: "Sec-Fetch-Dest")
        request.setValue("?1", forHTTPHeaderField: "Sec-CH-UA-Mobile")
        request.setValue("macOS", forHTTPHeaderField: "Sec-CH-UA-Platform")
        
        webView.load(request)
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // 必要に応じて更新処理
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let parent: CalendarWebView
        
        init(_ parent: CalendarWebView) {
            self.parent = parent
        }
        
        // ナビゲーション開始
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("🔄 WebView started loading")
            parent.isLoading = true
            parent.hasError = false
        }
        
        // ナビゲーション完了
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ WebView finished loading")
            parent.isLoading = false
            
            // Safariの偽装とページ調整のJavaScriptを実行
            let script = """
                // Safariの特徴を偽装
                Object.defineProperty(navigator, 'vendor', {
                    value: 'Apple Computer, Inc.',
                    writable: false
                });
                
                Object.defineProperty(navigator, 'webdriver', {
                    value: undefined,
                    writable: false
                });
                
                // Safari固有のプロパティを追加
                if (typeof navigator.standalone === 'undefined') {
                    Object.defineProperty(navigator, 'standalone', {
                        value: false,
                        writable: false
                    });
                }
                
                // WebKitの特徴を追加
                if (typeof window.safari === 'undefined') {
                    window.safari = {
                        pushNotification: {}
                    };
                }
                
                // ページの余白を調整と背景の透明化
                document.body.style.margin = '0';
                document.body.style.padding = '0';
                document.body.style.backgroundColor = 'transparent';
                document.documentElement.style.backgroundColor = 'transparent';
                
                // 不要な要素を隠す（必要に応じて）
                var elements = document.querySelectorAll('div[role="banner"], .gb_g, .gb_h');
                elements.forEach(function(element) {
                    element.style.display = 'none';
                });
            """
            
            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    print("⚠️ JavaScript execution error: \(error)")
                } else {
                    print("🎯 JavaScript executed successfully")
                }
            }
            
            // ページロード後に再度透明化処理を実行
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                webView.subviews.forEach { subview in
                    if let scrollView = subview as? NSScrollView {
                        scrollView.drawsBackground = false
                        scrollView.backgroundColor = NSColor.clear
                    }
                }
            }
        }
        
        // ナビゲーションエラー
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("❌ WebView failed to load: \(error.localizedDescription)")
            parent.isLoading = false
            parent.hasError = true
        }
        
        // コンテンツプロセスの終了
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            print("💥 WebView content process terminated")
            parent.hasError = true
        }
        
        // 新しいウィンドウの作成要求
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // 新しいウィンドウではなく、現在のウィンドウで開く
            webView.load(navigationAction.request)
            return nil
        }
        
        // 認証チャレンジ
        func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            // デフォルトの処理を使用
            completionHandler(.performDefaultHandling, nil)
        }
        
        // ナビゲーション判定（Googleのセキュリティチェック回避）
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // すべてのナビゲーションを許可
            decisionHandler(.allow)
        }
        
        // レスポンス判定
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            // すべてのレスポンスを許可
            decisionHandler(.allow)
        }
    }
}

// エラー表示用のビュー
struct WebViewErrorView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Failed to Load Calendar")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                onRetry()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// ローディング表示用のビュー
struct WebViewLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading Calendar...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#Preview {
    CalendarWebView(url: URL(string: "https://calendar.google.com/calendar/u/0/r/customday?tab=rc1")!)
        .frame(width: 800, height: 600)
}
