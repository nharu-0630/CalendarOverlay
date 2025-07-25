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
    
    private var interactiveHotKeyRef: EventHotKeyRef?
    private var showHideHotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    var interactiveCallback: (() -> Void)?
    var showHideCallback: (() -> Void)?
    
    private init() {}
    
    func registerHotkey() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        // Cmd + Shift + C でインタラクティブモード切り替え
        let interactiveHotKeySignature = OSType(0x494E5452) // 'INTR'
        let interactiveHotKeyID = EventHotKeyID(signature: interactiveHotKeySignature, id: 1)
        
        let interactiveStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_C),
            UInt32(cmdKey + shiftKey),
            interactiveHotKeyID,
            GetApplicationEventTarget(),
            0,
            &interactiveHotKeyRef
        )
        
        // Cmd + Shift + X でshow/hide切り替え
        let showHideHotKeySignature = OSType(0x53484F57) // 'SHOW'
        let showHideHotKeyID = EventHotKeyID(signature: showHideHotKeySignature, id: 2)
        
        let showHideStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_X),
            UInt32(cmdKey + shiftKey),
            showHideHotKeyID,
            GetApplicationEventTarget(),
            0,
            &showHideHotKeyRef
        )
        
        if interactiveStatus == noErr && showHideStatus == noErr {
            print("✅ Hotkeys registered: Cmd+Shift+C (Interactive), Cmd+Shift+X (Show/Hide)")
            
            // イベントハンドラーを設定
            InstallEventHandler(
                GetApplicationEventTarget(),
                { (nextHandler, theEvent, userData) -> OSStatus in
                    HotkeyManager.shared.handleHotkey(theEvent)
                    return noErr
                },
                1,
                &eventType,
                nil,
                &eventHandler
            )
        } else {
            print("❌ Failed to register hotkeys - Interactive: \(interactiveStatus), Show/Hide: \(showHideStatus)")
        }
    }
    
    func handleHotkey(_ event: EventRef?) {
        guard let event = event else { return }
        
        var hotKeyID: EventHotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )
        
        if status == noErr {
            DispatchQueue.main.async {
                switch hotKeyID.id {
                case 1:
                    print("🔥 Interactive hotkey pressed!")
                    self.interactiveCallback?()
                case 2:
                    print("🔥 Show/Hide hotkey pressed!")
                    self.showHideCallback?()
                default:
                    print("🔥 Unknown hotkey pressed!")
                }
            }
        }
    }
    
    func unregisterHotkey() {
        if let interactiveHotKeyRef = interactiveHotKeyRef {
            UnregisterEventHotKey(interactiveHotKeyRef)
            self.interactiveHotKeyRef = nil
        }
        
        if let showHideHotKeyRef = showHideHotKeyRef {
            UnregisterEventHotKey(showHideHotKeyRef)
            self.showHideHotKeyRef = nil
        }
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
        
        print("🗑️ Hotkeys unregistered")
    }
}
