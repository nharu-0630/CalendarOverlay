//
//  OverlayWindow.swift
//  WebkitOverlay
//
//  Created by nharu on 2025/07/25.
//

import Cocoa
import SwiftUI

class OverlayWindow: NSWindow {
    // MARK: - Constants
    private enum WindowConstants {
        static let titleBarHeight: CGFloat = 60
    }
    
    // MARK: - Properties
    private var initialLocation: NSPoint = NSPoint()
    private var isDragging = false
    private var _canBecomeKey = false
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        // ウィンドウの基本設定
        self.isMovableByWindowBackground = false
        self.acceptsMouseMovedEvents = true
        
        print("🏗️ OverlayWindow initialized")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        print("🌅 OverlayWindow awoke from nib")
    }
    
    // マウスダウン処理
    override func mouseDown(with event: NSEvent) {
        let locationInWindow = event.locationInWindow
        
        // タイトルバー領域でのクリックかどうかを判定
        if locationInWindow.y > self.frame.height - WindowConstants.titleBarHeight {
            self.initialLocation = locationInWindow
            self.isDragging = true
            print("🖱️ Mouse down in title area - drag started")
        }
        
        super.mouseDown(with: event)
    }
    
    // マウスドラッグ処理
    override func mouseDragged(with event: NSEvent) {
        if isDragging {
            let currentLocation = event.locationInWindow
            let deltaX = currentLocation.x - initialLocation.x
            let deltaY = currentLocation.y - initialLocation.y
            
            let newOrigin = NSPoint(
                x: self.frame.origin.x + deltaX,
                y: self.frame.origin.y + deltaY
            )
            
            self.setFrameOrigin(newOrigin)
            print("🏃 Window dragged to: \(newOrigin)")
        }
        
        super.mouseDragged(with: event)
    }
    
    // マウスアップ処理
    override func mouseUp(with event: NSEvent) {
        if isDragging {
            self.isDragging = false
            print("🛑 Mouse up - drag ended")
        }
        
        super.mouseUp(with: event)
    }
    
    // ウィンドウのクローズボタンが押された時の処理
    override func performClose(_ sender: Any?) {
        print("❌ Window close requested")
        self.orderOut(nil)
    }
    
    // ウィンドウがキーウィンドウになった時
    override func becomeKey() {
        super.becomeKey()
        print("🔑 Window became key")
    }
    
    // ウィンドウがキーウィンドウでなくなった時
    override func resignKey() {
        super.resignKey()
        print("🚪 Window resigned key")
    }
    
    // キーウィンドウになれるかどうか
    override var canBecomeKey: Bool {
        return _canBecomeKey
    }
    
    // メインウィンドウになれるかどうか
    override var canBecomeMain: Bool {
        return _canBecomeKey
    }
    
    // インタラクティブモードの設定
    func setInteractiveMode(_ interactive: Bool) {
        _canBecomeKey = interactive
        print("🔧 OverlayWindow interactive mode set to: \(interactive)")
    }
}
