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
        
        // ユーザーエージェントを設定（Googleのセキュリティチェックを回避するため最新のChromeを使用）
        configuration.applicationNameForUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        
        // セキュリティ設定
        configuration.preferences.javaScriptEnabled = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        // Googleのセキュリティチェック回避のための追加設定
        // 基本的なWebKit設定のみ使用
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        
        // その他の設定
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        
        // デリゲートを設定
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // 初期ロード
        print("🌐 Loading URL: \(url)")
        let request = URLRequest(url: url)
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
            
            // Google Calendarの場合、埋め込み用のJavaScriptを実行
            let script = """
                // ページの余白を調整
                document.body.style.margin = '0';
                document.body.style.padding = '0';
                
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
    CalendarWebView(url: URL(string: "https://calendar.google.com/calendar/embed")!)
        .frame(width: 800, height: 600)
}
