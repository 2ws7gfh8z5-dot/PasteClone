import Foundation
import Carbon.HIToolbox
import AppKit

/// Global hotkey via Carbon RegisterEventHotKey — the only API that works
/// without Accessibility permission for a plain hotkey.
final class HotkeyManager {
    static let shared = HotkeyManager()
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    var onTrigger: (() -> Void)?

    private init() {}

    /// keyCode: virtual key. modifiers: Carbon flags (cmdKey/shiftKey/optionKey/controlKey)
    func register(keyCode: UInt32 = HotkeyPreset.keyCode,
                  modifiers: UInt32 = HotkeyPreset.modifiers) {
        unregister()

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ -> OSStatus in
            var hkID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &hkID)
            if hkID.id == 1 {
                DispatchQueue.main.async { HotkeyManager.shared.onTrigger?() }
            }
            return noErr
        }, 1, &eventType, nil, &handlerRef)

        let hkID = EventHotKeyID(signature: OSType(0x5043_5043), id: 1)
        RegisterEventHotKey(keyCode, modifiers, hkID,
                            GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregister() {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref); hotKeyRef = nil }
        if let h = handlerRef { RemoveEventHandler(h); handlerRef = nil }
    }
}
