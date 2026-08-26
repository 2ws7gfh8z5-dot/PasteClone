import AppKit
import Foundation

class ActiveAppService {
    static let shared = ActiveAppService()
    
    private var lastActiveApp: NSRunningApplication?
    private var monitoringTimer: Timer?
    
    func startMonitoring() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateActiveApp()
        }
    }
    
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    private func updateActiveApp() {
        lastActiveApp = NSWorkspace.shared.frontmostApplication
    }
    
    /// 获取当前活跃应用（面板隐藏时的前置应用）
    func getActiveApp() -> NSRunningApplication? {
        // 优先返回上次记录的活跃应用
        if let app = lastActiveApp, app.isActive {
            return app
        }
        // 否则尝试获取当前前置应用
        return NSWorkspace.shared.frontmostApplication
    }
    
    /// 将内容粘贴到指定应用
    func pasteToApp(_ app: NSRunningApplication, content: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(content, forType: .string)
        
        // 获取应用的 AXUIElement
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        
        // 尝试找到聚焦的文本框
        if let focusedElement = getFocusedTextElement(axApp) {
            // 使用 Accessibility API 粘贴内容到文本框
            let _ = AXUIElementSetAttributeValue(focusedElement, kAXValueAttribute as CFString, content as CFTypeRef)
        } else {
            // 回退方案：使用快捷键粘贴
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                Self.synthesizePaste()
            }
        }
    }
    
    /// 获取应用中聚焦的文本元素
    private func getFocusedTextElement(_ axApp: AXUIElement) -> AXUIElement? {
        var focusedElement: AnyObject?
        let result = AXUIElementCopyAttributeValue(axApp, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        guard result == .success, let element = focusedElement as! AXUIElement? else { return nil }
        
        // 检查是否是文本框或可编辑的元素
        var role: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
        
        if let roleString = role as? String {
            if roleString == kAXTextFieldRole || roleString == kAXTextAreaRole {
                return element
            }
        }
        
        return nil
    }
    
    private static func synthesizePaste() {
        let src = CGEventSource(stateID: .hidSystemState)
        guard let down = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: true),
              let up = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: false) else { return }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}
