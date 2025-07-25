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
    
    // MARK: - Constants
    private enum HotkeyConstants {
        static let interactiveSignature = OSType(0x494E5452) // 'INTR'
        static let showHideSignature = OSType(0x53484F57) // 'SHOW'
        static let interactiveKeyCode = UInt32(kVK_ANSI_C)
        static let showHideKeyCode = UInt32(kVK_ANSI_X)
        static let modifierKeys = UInt32(cmdKey + shiftKey)
    }
    
    private enum HotkeyID: UInt32 {
        case interactive = 1
        case showHide = 2
    }
    
    // MARK: - Properties
    private var interactiveHotKeyRef: EventHotKeyRef?
    private var showHideHotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    
    var interactiveCallback: (() -> Void)?
    var showHideCallback: (() -> Void)?
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    func registerHotkeys() {
        let interactiveStatus = registerInteractiveHotkey()
        let showHideStatus = registerShowHideHotkey()
        
        if interactiveStatus == noErr && showHideStatus == noErr {
            installEventHandler()
            print("✅ Hotkeys registered: Cmd+Shift+C (Interactive), Cmd+Shift+X (Show/Hide)")
        } else {
            print("❌ Failed to register hotkeys - Interactive: \(interactiveStatus), Show/Hide: \(showHideStatus)")
        }
    }
    
    func unregisterHotkeys() {
        unregisterInteractiveHotkey()
        unregisterShowHideHotkey()
        removeEventHandler()
        print("🗑️ Hotkeys unregistered")
    }
    
    // MARK: - Private Methods
    private func registerInteractiveHotkey() -> OSStatus {
        let hotKeyID = EventHotKeyID(
            signature: HotkeyConstants.interactiveSignature,
            id: HotkeyID.interactive.rawValue
        )
        
        return RegisterEventHotKey(
            HotkeyConstants.interactiveKeyCode,
            HotkeyConstants.modifierKeys,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &interactiveHotKeyRef
        )
    }
    
    private func registerShowHideHotkey() -> OSStatus {
        let hotKeyID = EventHotKeyID(
            signature: HotkeyConstants.showHideSignature,
            id: HotkeyID.showHide.rawValue
        )
        
        return RegisterEventHotKey(
            HotkeyConstants.showHideKeyCode,
            HotkeyConstants.modifierKeys,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &showHideHotKeyRef
        )
    }
    
    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        
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
    }
    
    private func unregisterInteractiveHotkey() {
        if let hotKeyRef = interactiveHotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            interactiveHotKeyRef = nil
        }
    }
    
    private func unregisterShowHideHotkey() {
        if let hotKeyRef = showHideHotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            showHideHotKeyRef = nil
        }
    }
    
    private func removeEventHandler() {
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
    
    private func handleHotkey(_ event: EventRef?) {
        guard let event = event else { return }
        
        guard let hotkeyID = extractHotkeyID(from: event) else { return }
        
        DispatchQueue.main.async {
            switch HotkeyID(rawValue: hotkeyID.id) {
            case .interactive:
                print("🔥 Interactive hotkey pressed!")
                self.interactiveCallback?()
            case .showHide:
                print("🔥 Show/Hide hotkey pressed!")
                self.showHideCallback?()
            case .none:
                print("🔥 Unknown hotkey pressed!")
            }
        }
    }
    
    private func extractHotkeyID(from event: EventRef) -> EventHotKeyID? {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )
        
        return status == noErr ? hotKeyID : nil
    }
}
