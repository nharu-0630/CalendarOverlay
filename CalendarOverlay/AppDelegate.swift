import SwiftUI
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: NSWindow?
    var statusBarItem: NSStatusItem?
    
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
        menu.addItem(NSMenuItem(title: "Bring to Front (5s)", action: #selector(bringToFront), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Send to Back", action: #selector(sendToBack), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusBarItem?.menu = menu
    }
    
    @objc func bringToFront() {
        if let window = overlayWindow {
            window.level = .floating
            window.makeKeyAndOrderFront(nil)
            
            // 5秒後に元のレベルに戻す
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
                print("⬇️ Window sent back to overlay level")
            }
            print("⬆️ Window brought to front for 5 seconds")
        }
    }
    
    @objc func sendToBack() {
        if let window = overlayWindow {
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
            print("⬇️ Window sent to overlay level")
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
                // ウィンドウを一時的に前面に表示して操作可能にする
                window.level = .floating
                
                // 5秒後に元のレベルに戻す
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
                }
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
        
        // ウィンドウの位置とサイズ
        let windowWidth: CGFloat = 800
        let windowHeight: CGFloat = 600
        let windowX: CGFloat = 100
        let windowY = screenRect.height - windowHeight - 100
        
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
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.hidesOnDeactivate = false
        window.hasShadow = true
        
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
