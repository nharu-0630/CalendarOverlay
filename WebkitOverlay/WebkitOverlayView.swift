import SwiftUI
import WebKit

struct WebkitOverlayView: View {
    // MARK: - Constants
    private enum ViewConstants {
        static let defaultOpacity: Double = 0.8
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 10
        static let shadowOpacity: Double = 0.3
        static let hiddenContentHeight: CGFloat = 60
        static let calendarURL = "https://calendar.google.com/calendar/u/0/r/customday?tab=rc1"
    }
    
    // MARK: - State Properties
    @State private var isVisible = true
    @State private var useWebView = true
    @State private var opacity: Double = ViewConstants.defaultOpacity
    
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            contentArea
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundView)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
    }
    
    // MARK: - View Components
    private var contentArea: some View {
        Group {
            if isVisible {
                webViewContent
            } else {
                hiddenContent
            }
        }
    }
    
    private var webViewContent: some View {
        WebView(url: URL(string: ViewConstants.calendarURL)!)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(opacity)
    }
    
    private var hiddenContent: some View {
        VStack {
            Text("Content Hidden")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        }
        .frame(height: ViewConstants.hiddenContentHeight)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: ViewConstants.cornerRadius))
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: ViewConstants.cornerRadius)
            .fill(Color(NSColor.windowBackgroundColor))
            .shadow(
                color: .black.opacity(ViewConstants.shadowOpacity),
                radius: ViewConstants.shadowRadius,
                x: 0,
                y: 5
            )
    }
}


#Preview {
    WebkitOverlayView()
        .frame(width: 800, height: 600)
}
