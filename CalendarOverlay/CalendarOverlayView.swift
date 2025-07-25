import SwiftUI
import WebKit

struct CalendarOverlayView: View {
    @State private var isVisible = true
    @State private var useWebView = false
    @State private var isMinimized = false
    @State private var opacity: Double = 0.95
    @State private var currentTime = Date()
    @State private var isInteractiveMode = false
    
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            // タイトルバー
            titleBar
            
            // コンテンツエリア
            if !isMinimized {
                contentArea
            }
        }
        .frame(minWidth: 600, minHeight: isMinimized ? 60 : 500)
        .background(backgroundView)
        .opacity(opacity)
        .animation(.easeInOut(duration: 0.3), value: isMinimized)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    private var titleBar: some View {
        HStack {
            // タイトル
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.white)
                Text("Google Calendar Overlay")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // 時刻表示
            Text(currentTime.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            // コントロールボタン
            controlButtons
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(UnevenRoundedRectangle(
            cornerRadii: .init(
                topLeading: 8,
                bottomLeading: isMinimized ? 8 : 0,
                bottomTrailing: isMinimized ? 8 : 0,
                topTrailing: 8
            )
        ))
    }
    
    private var controlButtons: some View {
        HStack(spacing: 8) {
            // インタラクティブモード切り替え
            Button(action: {
                isInteractiveMode.toggle()
                toggleWindowLevel()
            }) {
                Image(systemName: isInteractiveMode ? "hand.tap.fill" : "hand.tap")
                    .foregroundColor(isInteractiveMode ? .yellow : .white)
            }
            .help("Toggle Interactive Mode")
            
            // 透明度調整
            Button(action: {
                opacity = opacity > 0.5 ? 0.5 : 0.95
            }) {
                Image(systemName: opacity > 0.5 ? "circle.fill" : "circle")
                    .foregroundColor(.white)
            }
            .help("Toggle Transparency")
            
            // WebViewトグル
            Button(action: {
                useWebView.toggle()
            }) {
                Image(systemName: useWebView ? "globe" : "rectangle.grid.3x2")
                    .foregroundColor(.white)
            }
            .help("Toggle WebView/Demo")
            
            // 最小化
            Button(action: {
                isMinimized.toggle()
            }) {
                Image(systemName: isMinimized ? "chevron.down" : "minus")
                    .foregroundColor(.white)
            }
            .help("Minimize/Restore")
            
            // 表示/非表示
            Button(action: {
                isVisible.toggle()
            }) {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .foregroundColor(.white)
            }
            .help("Hide/Show Content")
            
            // 閉じる
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
            }
            .help("Quit Application")
        }
    }
    
    private func toggleWindowLevel() {
        if let window = NSApplication.shared.windows.first(where: { $0.contentView is NSHostingView<CalendarOverlayView> }) {
            if isInteractiveMode {
                window.level = .floating
                print("🖱️ Interactive mode ON - Window brought to front")
            } else {
                window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
                print("🖼️ Interactive mode OFF - Window sent to overlay level")
            }
        }
    }
    
    private var contentArea: some View {
        Group {
            if isVisible {
                if useWebView {
                    webViewContent
                } else {
                    demoContent
                }
            } else {
                hiddenContent
            }
        }
    }
    
    private var webViewContent: some View {
        CalendarWebView(url: URL(string: "https://calendar.google.com/calendar/embed")!)
            .clipShape(UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: 0,
                    bottomLeading: 8,
                    bottomTrailing: 8,
                    topTrailing: 0
                )
            ))
    }
    
    private var demoContent: some View {
        VStack(spacing: 20) {
            Text("📅 Calendar Overlay Demo")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.top)
            
            Text("Current Time: \(currentTime.formatted())")
                .font(.headline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(1...30, id: \.self) { day in
                    Text("\(day)")
                        .frame(width: 30, height: 30)
                        .background(day == Calendar.current.component(.day, from: Date()) ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(day == Calendar.current.component(.day, from: Date()) ? .white : .primary)
                        .cornerRadius(8)
                }
            }
            .padding()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Today's Schedule")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ScheduleItem(time: "09:00", title: "Morning Meeting", color: .blue)
                        ScheduleItem(time: "14:00", title: "Project Review", color: .green)
                        ScheduleItem(time: "16:30", title: "Team Sync", color: .orange)
                    }
                }
                
                Spacer()
                
                VStack {
                    Button("Load Real Calendar") {
                        useWebView = true
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Text("Click to load Google Calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Spacer()
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
        .clipShape(UnevenRoundedRectangle(
            cornerRadii: .init(
                topLeading: 0,
                bottomLeading: 8,
                bottomTrailing: 8,
                topTrailing: 0
            )
        ))
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
                topLeading: 0,
                bottomLeading: 8,
                bottomTrailing: 8,
                topTrailing: 0
            )
        ))
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(NSColor.windowBackgroundColor))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct ScheduleItem: View {
    let time: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(color)
                .frame(width: 4, height: 20)
            
            VStack(alignment: .leading) {
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CalendarOverlayView()
        .frame(width: 800, height: 600)
}
