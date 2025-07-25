import SwiftUI
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    // MARK: - Properties
    private var overlayWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var statusBarItem: NSStatusItem?
    private var isInteractiveMode = false
    private var wasInteractiveModeEnabled = false
    
    // MARK: - Constants
    private enum WindowConstants {
        static let titleBarHeight: CGFloat = 60
        static let defaultDelayTime: TimeInterval = 0.5
    }
    
    // MARK: - Application Lifecycle
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 App did finish launching")
        
        setupApplication()
        setupHotkeys()
        setupUI()
        setupSettingsObserver()
        
        // 少し遅延を入れてからウィンドウを作成
        DispatchQueue.main.asyncAfter(deadline: .now() + WindowConstants.defaultDelayTime) {
            self.createOverlayWindow()
        }
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
        HotkeyManager.shared.unregisterHotkeys()
    }
    
    // MARK: - Setup Methods
    private func setupApplication() {
        hideMainWindows()
        NSApp.setActivationPolicy(.accessory)
    }
    
    private func setupHotkeys() {
        HotkeyManager.shared.interactiveCallback = { [weak self] in
            self?.toggleInteractiveMode()
        }
        
        HotkeyManager.shared.showHideCallback = { [weak self] in
            self?.toggleOverlay()
        }
        
        HotkeyManager.shared.registerHotkeys()
    }
    
    private func setupUI() {
        createStatusBarItem()
    }
    
    private func setupSettingsObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: .settingsChanged,
            object: nil
        )
    }
    
    // MARK: - UI Setup
    private func hideMainWindows() {
        NSApp.windows.forEach { window in
            window.setIsVisible(false)
        }
    }
    
    private func createStatusBarItem() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        guard statusBarItem != nil else {
            print("❌ Failed to create status bar item")
            return
        }
        
        configureStatusBarButton()
        createStatusBarMenu()
        
        print("✅ Status bar item created successfully")
    }
    
    private func configureStatusBarButton() {
        guard let button = statusBarItem?.button else {
            print("❌ Failed to get status bar button")
            return
        }
        
        // システムシンボルを設定
        if let image = NSImage(systemSymbolName: "calendar.circle.fill", accessibilityDescription: "WebKit Overlay") {
            button.image = image
            print("✅ Status bar icon set to calendar.circle.fill")
        } else {
            // フォールバック：代替アイコン
            button.title = "📅"
            print("✅ Status bar icon set to emoji fallback")
        }
        
        button.action = #selector(statusBarButtonClicked)
        button.target = self
        button.toolTip = "WebKitOverlay - カレンダーオーバーレイ"
    }
    
    private func createStatusBarMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show/Hide Overlay", action: #selector(toggleOverlay), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Toggle Interactive Mode", action: #selector(toggleInteractiveMode), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusBarItem?.menu = menu
    }
    
    // MARK: - Action Methods
    @objc private func toggleInteractiveMode() {
        print("🎯 toggleInteractiveMode called")
        
        guard let window = overlayWindow as? OverlayWindow else {
            print("❌ Failed to get overlay window as OverlayWindow")
            return
        }
        
        isInteractiveMode.toggle()
        print("📱 Interactive mode state changed to: \(isInteractiveMode)")
        
        configureInteractiveMode(for: window)
    }
    
    @objc private func settingsChanged() {
        print("⚙️ Settings changed - updating overlay transparency")
        updateOverlayTransparency()
    }
    
    @objc private func statusBarButtonClicked() {
        toggleOverlay()
    }
    
    @objc private func toggleOverlay() {
        guard let window = overlayWindow else { return }
        
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc private func openSettings() {
        // 既存の設定ウィンドウがある場合は前面に表示
        if let existingWindow = settingsWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // インタラクティブモードの状態を保存して無効化
        wasInteractiveModeEnabled = isInteractiveMode
        if isInteractiveMode {
            toggleInteractiveMode()
        }
        
        // 設定ウィンドウを新規作成
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let windowRect = NSRect(
            x: screenFrame.midX - 225,
            y: screenFrame.midY - 260,
            width: 450,
            height: 520
        )
        
        settingsWindow = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        guard let window = settingsWindow else { return }
        
        window.title = "WebKitOverlay 設定"
        window.minSize = NSSize(width: 400, height: 480)
        window.maxSize = NSSize(width: 600, height: 650)
        window.isReleasedWhenClosed = false
        window.level = .normal
        
        // SwiftUIビューをホストするビューを作成
        let settingsView = SettingsView()
        let hostingView = NSHostingView(rootView: settingsView)
        hostingView.frame = window.contentView?.bounds ?? NSRect.zero
        hostingView.autoresizingMask = [.width, .height]
        
        window.contentView = hostingView
        
        // ウィンドウが閉じられた時の処理
        window.delegate = self
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        print("✅ Settings window opened")
    }
    
    // MARK: - Helper Methods
    private func configureInteractiveMode(for window: OverlayWindow) {
        window.setInteractiveMode(isInteractiveMode)
        
        if isInteractiveMode {
            enableInteractiveMode(for: window)
        } else {
            disableInteractiveMode(for: window)
        }
    }
    
    private func enableInteractiveMode(for window: OverlayWindow) {
        window.level = .floating
        window.ignoresMouseEvents = false
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(window.contentView)
        print("🖱️ Interactive mode ON - Window brought to front and can receive key input")
    }
    
    private func disableInteractiveMode(for window: OverlayWindow) {
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        window.ignoresMouseEvents = true
        window.resignKey()
        print("🖼️ Interactive mode OFF - Window sent to overlay level")
    }
    
    private func updateOverlayTransparency() {
        guard let window = overlayWindow else { return }
        
        let opacity = UserDefaults.standard.double(forKey: "opacity")
        let targetOpacity = opacity > 0 ? opacity : 0.8 // デフォルト値
        
        window.alphaValue = targetOpacity
        print("🔍 Window transparency updated to: \(targetOpacity)")
    }
    
    // MARK: - Window Management
    private func createOverlayWindow() {
        print("📱 Creating overlay window...")
        
        guard let screen = NSScreen.main else {
            print("❌ Failed to get main screen")
            return
        }
        
        let screenRect = screen.frame
        print("📏 Screen size: \(screenRect)")
        
        createWindow(with: screenRect)
        configureWindow()
        setupWindowContent()
        showWindow()
    }
    
    private func createWindow(with screenRect: NSRect) {
        let windowRect = NSRect(x: 0, y: 0, width: screenRect.width, height: screenRect.height)
        
        overlayWindow = OverlayWindow(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
    }
    
    private func configureWindow() {
        guard let window = overlayWindow else {
            print("❌ Failed to create window")
            return
        }
        
        window.title = "Webkit Overlay"
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        window.ignoresMouseEvents = !isInteractiveMode
        window.acceptsMouseMovedEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.hidesOnDeactivate = false
        window.hasShadow = true
        
        if let overlayWindow = window as? OverlayWindow {
            overlayWindow.setInteractiveMode(isInteractiveMode)
        }
        
        // 設定から透過度を読み込み
        updateOverlayTransparency()
    }
    
    private func setupWindowContent() {
        guard let window = overlayWindow else { return }
        
        let contentView = NSHostingView(rootView: WebkitOverlayView())
        window.contentView = contentView
    }
    
    private func showWindow() {
        guard let window = overlayWindow else { return }
        
        window.makeKeyAndOrderFront(nil)
        
        print("✅ Overlay window created successfully")
        print("👁️ Window is visible: \(window.isVisible)")
        print("📍 Window frame: \(window.frame)")
    }
    
    // MARK: - NSWindowDelegate
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window == settingsWindow {
            settingsWindow = nil
            print("🗑️ Settings window closed and released")
            
            // インタラクティブモードを復元
            if wasInteractiveModeEnabled && !isInteractiveMode {
                toggleInteractiveMode()
            }
            wasInteractiveModeEnabled = false
        }
    }
}
