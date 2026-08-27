import SwiftUI
import Carbon

/// 捕获用户按下的键盘组合，显示为可读的修饰符 + 按键
struct HotkeyRecorder: NSViewRepresentable {
    @Binding var keyCode: UInt32
    @Binding var modifiers: UInt32
    @Binding var isRecording: Bool
    
    var onSaved: (() -> Void)?
    
    func makeNSView(context: Context) -> NSView {
        let view = HotkeyRecorderView()
        view.onKeyCapture = { code, mods in
            keyCode = code
            modifiers = mods
            isRecording = false
            onSaved?()
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let v = nsView as? HotkeyRecorderView {
            v.isActive = isRecording
        }
    }
}

/// AppKit wrapper：全局键盘事件监听（仅在录制时激活）
class HotkeyRecorderView: NSView {
    private var localMonitor: Any?
    var isActive = false {
        didSet {
            if isActive {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }
    }
    var onKeyCapture: ((UInt32, UInt32) -> Void)?
    
    private func startMonitoring() {
        stopMonitoring()
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let keyCode = UInt32(event.keyCode)
            var modifiers: UInt32 = 0
            
            let cocoaMods = event.modifierFlags
            if cocoaMods.contains(.command) { modifiers |= UInt32(cmdKey) }
            if cocoaMods.contains(.shift) { modifiers |= UInt32(shiftKey) }
            if cocoaMods.contains(.option) { modifiers |= UInt32(optionKey) }
            if cocoaMods.contains(.control) { modifiers |= UInt32(controlKey) }
            
            self.onKeyCapture?(keyCode, modifiers)
            return nil  // 消费事件，不传递给应用
        }
    }
    
    private func stopMonitoring() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
    
    deinit {
        stopMonitoring()
    }
}

/// 快捷键显示 + 编辑按钮
struct HotkeyDisplay: View {
    let keyCode: UInt32
    let modifiers: UInt32
    @State private var isRecording = false
    @State private var tempKeyCode: UInt32 = 0
    @State private var tempModifiers: UInt32 = 0
    var onSave: ((UInt32, UInt32) -> Void)?
    
    var body: some View {
        HStack(spacing: 8) {
            if isRecording {
                Text("按任意快捷键...")
                    .foregroundColor(.red)
                    .italic()
            } else {
                Text(formatHotkey(keyCode, modifiers))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Button(action: { isRecording = true }) {
                    Text("编辑")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
            
            HotkeyRecorder(
                keyCode: $tempKeyCode,
                modifiers: $tempModifiers,
                isRecording: $isRecording
            ) {
                onSave?(tempKeyCode, tempModifiers)
            }
            .frame(height: 0)
            .hidden()
        }
    }
    
    private func formatHotkey(_ keyCode: UInt32, _ modifiers: UInt32) -> String {
        var parts: [String] = []
        if (modifiers & UInt32(cmdKey)) != 0 { parts.append("⌘") }
        if (modifiers & UInt32(shiftKey)) != 0 { parts.append("⇧") }
        if (modifiers & UInt32(optionKey)) != 0 { parts.append("⌥") }
        if (modifiers & UInt32(controlKey)) != 0 { parts.append("⌃") }
        parts.append(keyCodeToString(keyCode))
        return parts.joined(separator: " ")
    }
}

/// 虚拟键码转可读按键名
func keyCodeToString(_ keyCode: UInt32) -> String {
    switch keyCode {
    case UInt32(kVK_ANSI_V): return "V"
    case UInt32(kVK_Space): return "Space"
    case UInt32(kVK_Return): return "↩"
    case UInt32(kVK_Tab): return "⇥"
    case UInt32(kVK_Escape): return "⎋"
    case UInt32(kVK_ANSI_A)...UInt32(kVK_ANSI_Z):
        let offset = UInt8(keyCode - UInt32(kVK_ANSI_A))
        let charCode = offset + UInt8(ascii: "A")
        return String(UnicodeScalar(charCode))
    default:
        return String(format: "Key(%d)", keyCode)
    }
}

#Preview {
    HotkeyDisplay(keyCode: 9, modifiers: UInt32(cmdKey)) { code, mods in
        print("Saved: \(code), \(mods)")
    }
}
