import Cocoa
import SwiftUI

class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    @Published var overlayWindows: [NSWindow] = []
    @Published var isOverlayVisible = true
    
    private let userDefaults = UserDefaults.standard
    private let windowPositionsKey = "overlayWindowPositions"
    
    private init() {}
    
    func createOverlayWindow(at position: CGPoint? = nil) -> NSWindow? {
        guard let screen = NSScreen.main else {
            print("❌ Failed to get main screen")
            return nil
        }
        
        let screenRect = screen.frame
        let windowWidth: CGFloat = 800
        let windowHeight: CGFloat = 600
        
        let windowX = position?.x ?? 100
        let windowY = position?.y ?? (screenRect.height - windowHeight - 100)
        
        let window = OverlayWindow(
            contentRect: NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        setupOverlayWindow(window)
        overlayWindows.append(window)
        
        return window
    }
    
    private func setupOverlayWindow(_ window: NSWindow) {
        // デスクトップ背景の上、他のウィンドウの下に表示
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.hidesOnDeactivate = false
        window.hasShadow = true
        
        // コンテンツビューの設定
        let contentView = NSHostingView(rootView: WebKitOverlayView())
        window.contentView = contentView
        
        // ウィンドウを表示
        window.makeKeyAndOrderFront(nil)
        
        print("✅ Overlay window created and configured")
    }
    
    func hideAllOverlays() {
        overlayWindows.forEach { window in
            window.orderOut(nil)
        }
        isOverlayVisible = false
        print("👻 All overlays hidden")
    }
    
    func showAllOverlays() {
        overlayWindows.forEach { window in
            window.makeKeyAndOrderFront(nil)
        }
        isOverlayVisible = true
        print("👁️ All overlays shown")
    }
    
    func toggleOverlays() {
        if isOverlayVisible {
            hideAllOverlays()
        } else {
            showAllOverlays()
        }
    }
    
    func closeAllOverlays() {
        overlayWindows.forEach { window in
            window.close()
        }
        overlayWindows.removeAll()
        print("🗂️ All overlay windows closed")
    }
    
    func removeWindow(_ window: NSWindow) {
        if let index = overlayWindows.firstIndex(of: window) {
            overlayWindows.remove(at: index)
            print("🗑️ Window removed from manager")
        }
    }
    
    // 全てのスクリーンにオーバーレイを作成
    func createOverlayForAllScreens() {
        NSScreen.screens.enumerated().forEach { (index, screen) in
            let screenRect = screen.frame
            let windowWidth: CGFloat = 600
            let windowHeight: CGFloat = 400
            
            let windowX = screenRect.midX - windowWidth / 2
            let windowY = screenRect.midY - windowHeight / 2
            
            _ = createOverlayWindow(at: CGPoint(x: windowX, y: windowY))
            print("🖥️ Created overlay for screen \(index + 1)")
        }
    }
    
    // ウィンドウの位置を保存
    func saveWindowPositions() {
        var positions: [[String: Double]] = []
        
        for window in overlayWindows {
            let frame = window.frame
            let position = [
                "x": Double(frame.origin.x),
                "y": Double(frame.origin.y),
                "width": Double(frame.size.width),
                "height": Double(frame.size.height)
            ]
            positions.append(position)
        }
        
        userDefaults.set(positions, forKey: windowPositionsKey)
        print("💾 Window positions saved")
    }
    
    // ウィンドウの位置を復元
    func restoreWindowPositions() {
        guard let positions = userDefaults.array(forKey: windowPositionsKey) as? [[String: Double]] else {
            print("📂 No saved window positions found")
            return
        }
        
        // 既存のウィンドウを閉じる
        closeAllOverlays()
        
        // 保存された位置でウィンドウを作成
        for position in positions {
            if let x = position["x"], let y = position["y"] {
                _ = createOverlayWindow(at: CGPoint(x: x, y: y))
            }
        }
        
        print("📋 Window positions restored")
    }
    
    // アプリ終了時の処理
    func applicationWillTerminate() {
        saveWindowPositions()
    }
}
