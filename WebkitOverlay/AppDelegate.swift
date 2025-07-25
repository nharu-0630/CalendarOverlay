import SwiftUI
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties
    private var overlayWindow: NSWindow?
    private var statusBarItem: NSStatusItem?
    private var isInteractiveMode = false
    
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
    
    // MARK: - UI Setup
    private func hideMainWindows() {
        NSApp.windows.forEach { window in
            window.setIsVisible(false)
        }
    }
    
    private func createStatusBarItem() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        configureStatusBarButton()
        createStatusBarMenu()
    }
    
    private func configureStatusBarButton() {
        guard let button = statusBarItem?.button else { return }
        
        button.image = NSImage(systemSymbolName: "link.circle", accessibilityDescription: "Webkit Overlay")
        button.action = #selector(statusBarButtonClicked)
        button.target = self
    }
    
    private func createStatusBarMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show/Hide Overlay", action: #selector(toggleOverlay), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Toggle Interactive Mode", action: #selector(toggleInteractiveMode), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Toggle Transparency", action: #selector(toggleTransparency), keyEquivalent: ""))
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
    
    @objc private func toggleTransparency() {
        guard let window = overlayWindow else { return }
        
        let currentAlpha = window.alphaValue
        window.alphaValue = currentAlpha > 0.5 ? 0.3 : 1.0
        print("🔍 Window transparency set to: \(window.alphaValue)")
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
}
