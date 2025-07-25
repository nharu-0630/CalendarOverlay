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
        
        // ユーザーエージェントを設定（一部のサイトでモバイル表示を避けるため）
        configuration.applicationNameForUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        
        // セキュリティ設定
        configuration.preferences.javaScriptEnabled = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        
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