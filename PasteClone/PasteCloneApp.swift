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
            Image(systemName: "clipboard")
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
    }

    func applicationWillTerminate(_ notification: Notification) { HotkeyManager.shared.unregister() }

    func togglePanel() {
        if panel == nil { makePanel() }
        guard let panel else { return }
        if panel.isVisible { panel.orderOut(nil) } else {
            panel.center(); panel.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
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
}
