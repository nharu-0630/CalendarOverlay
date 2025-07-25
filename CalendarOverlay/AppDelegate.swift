import SwiftUI
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: NSWindow?
    var statusBarItem: NSStatusItem?
    var isInteractiveMode = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 App did finish launching")
        
        // メインウィンドウを隠す
        hideMainWindows()
        
        // ステータスバーアイテムを作成
        createStatusBarItem()
        
        // ホットキーを登録
        HotkeyManager.shared.registerHotkey()
        
        // Dockアイコンを隠す
        NSApp.setActivationPolicy(.accessory)
        
        // 少し遅延を入れてからウィンドウを作成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.createOverlayWindow()
        }
    }
    
    func hideMainWindows() {
        NSApp.windows.forEach { window in
            window.setIsVisible(false)
        }
    }
    
    func createStatusBarItem() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Calendar Overlay")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show/Hide Overlay", action: #selector(toggleOverlay), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Toggle Interactive Mode", action: #selector(toggleInteractiveMode), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Toggle Transparency", action: #selector(toggleTransparency), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusBarItem?.menu = menu
    }
    
    @objc func toggleInteractiveMode() {
        if let window = overlayWindow as? OverlayWindow {
            isInteractiveMode.toggle()
            
            if isInteractiveMode {
                window.setInteractiveMode(true)
                window.level = .floating
                window.ignoresMouseEvents = false
                window.makeKeyAndOrderFront(nil)
                // WebViewがキー入力を受け取れるようにフォーカスを設定
                window.makeFirstResponder(window.contentView)
                print("🖱️ Interactive mode ON - Window brought to front and can receive key input")
            } else {
                window.setInteractiveMode(false)
                window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
                window.ignoresMouseEvents = true
                window.resignKey()
                print("🖼️ Interactive mode OFF - Window sent to overlay level")
            }
        }
    }
    
    @objc func toggleTransparency() {
        if let window = overlayWindow {
            let currentAlpha = window.alphaValue
            window.alphaValue = currentAlpha > 0.5 ? 0.3 : 1.0
            print("🔍 Window transparency set to: \(window.alphaValue)")
        }
    }
    
    @objc func statusBarButtonClicked() {
        toggleOverlay()
    }
    
    @objc func toggleOverlay() {
        if let window = overlayWindow {
            if window.isVisible {
                window.orderOut(nil)
            } else {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    func createOverlayWindow() {
        print("📱 Creating overlay window...")
        
        guard let screen = NSScreen.main else {
            print("❌ Failed to get main screen")
            return
        }
        
        let screenRect = screen.frame
        print("📏 Screen size: \(screenRect)")
        
        // ウィンドウの位置とサイズ（画面全体に最大化）
        let windowWidth: CGFloat = screenRect.width
        let windowHeight: CGFloat = screenRect.height
        let windowX: CGFloat = 0
        let windowY: CGFloat = 0
        
        // オーバーレイウィンドウの作成
        overlayWindow = OverlayWindow(
            contentRect: NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        guard let window = overlayWindow else {
            print("❌ Failed to create window")
            return
        }
        
        // ウィンドウの設定
        window.title = "Calendar Overlay"
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        window.ignoresMouseEvents = !isInteractiveMode
        window.acceptsMouseMovedEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.hidesOnDeactivate = false
        window.hasShadow = true
        
        // インタラクティブモードの初期設定
        if let overlayWindow = window as? OverlayWindow {
            overlayWindow.setInteractiveMode(isInteractiveMode)
        }
        
        // コンテンツビューの設定
        let contentView = NSHostingView(rootView: CalendarOverlayView())
        window.contentView = contentView
        
        // ウィンドウを表示
        window.makeKeyAndOrderFront(nil)
        
        print("✅ Overlay window created successfully")
        print("👁️ Window is visible: \(window.isVisible)")
        print("📍 Window frame: \(window.frame)")
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        print("🔄 Application should handle reopen")
        
        if overlayWindow == nil {
            createOverlayWindow()
        } else {
            overlayWindow?.makeKeyAndOrderFront(nil)
        }
        return true
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        print("🎯 Application did become active")
        overlayWindow?.makeKeyAndOrderFront(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("🛑 Application will terminate")
        HotkeyManager.shared.unregisterHotkey()
    }
}
