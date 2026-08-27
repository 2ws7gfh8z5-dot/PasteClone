import Carbon.HIToolbox

enum HotkeyPreset: String, CaseIterable, Identifiable {
    case shiftCommandV
    case optionSpace
    case controlOptionV
    case custom

    var id: String { rawValue }
    var title: String {
        switch self {
        case .shiftCommandV: return "⇧⌘V"
        case .optionSpace: return "⌥Space"
        case .controlOptionV: return "⌃⌥V"
        case .custom: return "自定义"
        }
    }
    var keyCode: UInt32 {
        switch self {
        case .shiftCommandV, .controlOptionV: return UInt32(kVK_ANSI_V)
        case .optionSpace: return UInt32(kVK_Space)
        case .custom:
            return UserDefaults.standard.integer(forKey: "customHotkeyKeyCode") > 0 ?
                UInt32(UserDefaults.standard.integer(forKey: "customHotkeyKeyCode")) : UInt32(kVK_ANSI_V)
        }
    }
    var modifiers: UInt32 {
        switch self {
        case .shiftCommandV: return UInt32(cmdKey | shiftKey)
        case .optionSpace: return UInt32(optionKey)
        case .controlOptionV: return UInt32(controlKey | optionKey)
        case .custom:
            return UserDefaults.standard.integer(forKey: "customHotkeyModifiers") > 0 ?
                UInt32(UserDefaults.standard.integer(forKey: "customHotkeyModifiers")) : UInt32(cmdKey | shiftKey)
        }
    }
    
    static var keyCode: UInt32 { current.keyCode }
    static var modifiers: UInt32 { current.modifiers }
    static var current: HotkeyPreset {
        HotkeyPreset(rawValue: UserDefaults.standard.string(forKey: "hotkeyPreset") ?? "") ?? .shiftCommandV
    }
    
    static func saveCustomHotkey(keyCode: UInt32, modifiers: UInt32) {
        UserDefaults.standard.set(Int(keyCode), forKey: "customHotkeyKeyCode")
        UserDefaults.standard.set(Int(modifiers), forKey: "customHotkeyModifiers")
        UserDefaults.standard.set(HotkeyPreset.custom.rawValue, forKey: "hotkeyPreset")
    }
}
