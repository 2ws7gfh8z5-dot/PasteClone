import AppKit
import Carbon.HIToolbox

/// 修复直接粘贴到前台应用的核心逻辑
class PasteHelper {
    static func pasteToFrontmostApp(_ content: String) {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }
        
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(content, forType: .string)
        
        // 短延迟确保粘贴板已写入
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            // 使用 CGEventCreateKeyboardEvent 合成 Cmd+V
            guard let source = CGEventSource(stateID: .hidSystemState) else { return }
            
            let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: UInt16(kVK_ANSI_V), keyDown: true)
            let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: UInt16(kVK_ANSI_V), keyDown: false)
            
            keyDownEvent?.flags = .maskCommand
            keyUpEvent?.flags = .maskCommand
            
            keyDownEvent?.post(tap: .cghidEventTap)
            usleep(50000)
            keyUpEvent?.post(tap: .cghidEventTap)
        }
    }
    
    static func pasteImageToFrontmostApp(_ image: NSImage) {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }
        
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([image])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            synthesizePaste()
        }
    }
    
    static func pasteFilesToFrontmostApp(_ urls: [URL]) {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }
        
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects(urls as [NSURL])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            synthesizePaste()
        }
    }
    
    private static func synthesizePaste() {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: UInt16(kVK_ANSI_V), keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: UInt16(kVK_ANSI_V), keyDown: false)
        
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        
        keyDown?.post(tap: .cghidEventTap)
        usleep(50000)
        keyUp?.post(tap: .cghidEventTap)
    }
}
