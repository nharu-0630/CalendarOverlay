//
//  HotkeyManager.swift
//  CalendarOverlay
//
//  Created by nharu on 2025/07/25.
//


import Cocoa
import Carbon

class HotkeyManager {
    static let shared = HotkeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    
    private init() {}
    
    func registerHotkey() {
        // Cmd + Shift + C でオーバーレイを前面に表示
        let hotKeySignature = OSType(0x4F564C59) // 'OVLY'
        let hotKeyID = EventHotKeyID(signature: hotKeySignature, id: 1)
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        // ホットキーを登録
        let status = RegisterEventHotKey(
            UInt32(kVK_ANSI_C),
            UInt32(cmdKey + shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr {
            print("✅ Hotkey registered: Cmd+Shift+C")
            
            // イベントハンドラーを設定
            InstallEventHandler(
                GetApplicationEventTarget(),
                { (nextHandler, theEvent, userData) -> OSStatus in
                    HotkeyManager.shared.handleHotkey()
                    return noErr
                },
                1,
                &eventType,
                nil,
                &eventHandler
            )
        } else {
            print("❌ Failed to register hotkey: \(status)")
        }
    }
    
    func handleHotkey() {
        print("🔥 Hotkey pressed!")
        
        // AppDelegateを取得してオーバーレイを前面に表示
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.bringToFront()
        }
    }
    
    func unregisterHotkey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
            print("🗑️ Hotkey unregistered")
        }
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
}