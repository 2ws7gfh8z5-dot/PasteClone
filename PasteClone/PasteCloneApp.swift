import SwiftUI
import AppKit

@main
struct PasteCloneApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { PreferencesView() }
        MenuBarExtra {
            Button("打开剪贴板 (⇧⌘V)") { appDelegate.togglePanel() }
            Button("偏好设置") { NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil) }
            Divider()
            Button("退出 PasteClone") { NSApp.terminate(nil) }
        } label: {
            Image("MenuBarIcon")
        }
        .menuBarExtraStyle(.menu)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = ClipboardStore()
    private var panel: NSPanel?
    private var hosting: NSHostingView<HistoryPanelView>?
    private var panelAnimating = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        HotkeyManager.shared.onTrigger = { [weak self] in self?.togglePanel() }
        if UserDefaults.standard.object(forKey: "hotkeyEnabled") as? Bool ?? true {
            HotkeyManager.shared.register()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.unregister()
    }

    func togglePanel() {
        if panel == nil { makePanel() }
        guard let panel else { return }
        if panel.isVisible {
            hidePanel()
        } else {
            ActiveAppService.shared.captureTargetApp()
            panel.center()
            showPanel(panel)
        }
    }

    private func makePanel() {
        let view = HistoryPanelView(store: store) { [weak self] in self?.hidePanel() }
        let host = NSHostingView(rootView: view)
        hosting = host
        let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 380, height: 480),
                        styleMask: [.titled, .fullSizeContentView, .borderless], backing: .buffered, defer: false)
        p.isFloatingPanel = true; p.level = .floating; p.backgroundColor = .clear; p.isOpaque = false; p.hasShadow = true
        p.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        p.contentView = host
        panel = p
    }

    private func showPanel(_ panel: NSPanel) {
        guard !panelAnimating else { return }
        panelAnimating = true
        let target = panel.frame
        let collapsed = NSRect(x: target.midX - target.width * 0.94 / 2,
                               y: target.midY - target.height * 0.94 / 2,
                               width: target.width * 0.94, height: target.height * 0.94)
        panel.setFrame(collapsed, display: false)
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = AccessibilitySettings.reduceMotion ? 0 : 0.24
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
            panel.animator().setFrame(target, display: true)
            panel.animator().alphaValue = 1
        } completionHandler: { [weak self] in self?.panelAnimating = false }
    }

    private func hidePanel() {
        guard let panel, panel.isVisible, !panelAnimating else { return }
        panelAnimating = true
        let target = panel.frame
        let collapsed = NSRect(x: target.midX - target.width * 0.94 / 2,
                               y: target.midY - target.height * 0.94 / 2,
                               width: target.width * 0.94, height: target.height * 0.94)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = AccessibilitySettings.reduceMotion ? 0 : 0.16
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 1.0, 1.0)
            panel.animator().setFrame(collapsed, display: true)
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self, weak panel] in
            panel?.orderOut(nil)
            panel?.alphaValue = 1
            if let panel { panel.setFrame(target, display: false) }
            self?.panelAnimating = false
        }
    }
    
}
