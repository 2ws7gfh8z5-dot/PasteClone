import Carbon.HIToolbox

enum HotkeyPreset: String, CaseIterable, Identifiable {
    case shiftCommandV
    case optionSpace
    case controlOptionV

    var id: String { rawValue }
    var title: String {
        switch self {
        case .shiftCommandV: return "⇧⌘V"
        case .optionSpace: return "⌥Space"
        case .controlOptionV: return "⌃⌥V"
        }
    }
    var keyCode: UInt32 {
        switch self {
        case .shiftCommandV, .controlOptionV: return UInt32(kVK_ANSI_V)
        case .optionSpace: return UInt32(kVK_Space)
        }
    }
    var modifiers: UInt32 {
        switch self {
        case .shiftCommandV: return UInt32(cmdKey | shiftKey)
        case .optionSpace: return UInt32(optionKey)
        case .controlOptionV: return UInt32(controlKey | optionKey)
        }
    }
    static var keyCode: UInt32 { current.keyCode }
    static var modifiers: UInt32 { current.modifiers }
    static var current: HotkeyPreset {
        HotkeyPreset(rawValue: UserDefaults.standard.string(forKey: "hotkeyPreset") ?? "") ?? .shiftCommandV
    }
}
