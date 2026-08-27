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

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        HotkeyManager.shared.onTrigger = { [weak self] in self?.togglePanel() }
        HotkeyManager.shared.register()
        
        // 首次启动提示（仅一次）
        if !UserDefaults.standard.bool(forKey: "hasShownDonationPrompt") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showDonationPrompt()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.unregister()
    }

    func togglePanel() {
        if panel == nil { makePanel() }
        guard let panel else { return }
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            ActiveAppService.shared.captureTargetApp()
            panel.center()
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func makePanel() {
        let view = HistoryPanelView(store: store) { [weak self] in self?.panel?.orderOut(nil) }
        let host = NSHostingView(rootView: view)
        hosting = host
        let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 380, height: 480),
                        styleMask: [.titled, .fullSizeContentView, .borderless], backing: .buffered, defer: false)
        p.isFloatingPanel = true; p.level = .floating; p.backgroundColor = .clear; p.isOpaque = false; p.hasShadow = true
        p.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        p.contentView = host
        panel = p
    }
    
    private func showDonationPrompt() {
        let alert = NSAlert()
        alert.messageText = "支持 PasteClone"
        alert.informativeText = "PasteClone 是免费开源项目。如果您觉得有帮助，考虑通过 GitHub Sponsors 支持开发？"
        alert.addButton(withTitle: "支持开发")
        alert.addButton(withTitle: "下次再说")
        
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "https://github.com/2ws7gfh8z5-dot/PasteClone#support-development")!)
        }
        
        UserDefaults.standard.set(true, forKey: "hasShownDonationPrompt")
    }
}
