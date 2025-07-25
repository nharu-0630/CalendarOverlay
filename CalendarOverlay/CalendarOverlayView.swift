import SwiftUI
import WebKit

struct CalendarOverlayView: View {
    @State private var isVisible = true
    @State private var useWebView = true
    @State private var opacity: Double = 0.8
    
    
    var body: some View {
        VStack(spacing: 0) {
            // コンテンツエリア
            contentArea
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundView)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
    }
    
    
    
    
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
        CalendarWebView(url: URL(string: "https://calendar.google.com/calendar/u/0/r/customday?tab=rc1")!)
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
        .frame(height: 60)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .clipShape(UnevenRoundedRectangle(
            cornerRadii: .init(
                topLeading: 8,
                bottomLeading: 8,
                bottomTrailing: 8,
                topTrailing: 8
            )
        ))
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(NSColor.windowBackgroundColor))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}


#Preview {
    CalendarOverlayView()
        .frame(width: 800, height: 600)
}
