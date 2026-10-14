import SwiftUI
import AppKit
import os.log

fileprivate let logger = Logger(subsystem: "com.you.PasteClone", category: "AppDelegate")

@main
struct PasteCloneApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        Settings { PreferencesView() }
        MenuBarExtra {
            Button("打开剪贴板 (⇧⌘V)") { appDelegate.togglePanel() }
            Button("偏好设置") { NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil) }
            Divider()
            Button("退出 Just Paste") { NSApp.terminate(nil) }
        } label: {
            Image("MenuBarIcon")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.menu)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = ClipboardStore()
    private var panelWindow: NSWindow?
    private var isPanelPresented = false
    
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
        let wasVisible = panelWindow?.isVisible ?? false
        logger.debug("togglePanel 触发, wasVisible=\(wasVisible, privacy: .public)")
        
        if panelWindow == nil {
            makePanel()
        }
        guard let window = panelWindow else { return }
        
        if wasVisible {
            hidePanel(window)
        } else {
            ActiveAppService.shared.captureTargetApp()
            showPanel(window)
        }
    }
    
    private func makePanel() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 480),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        // statusBar keeps the panel above full-screen app content while the auxiliary
        // collection behavior lets it join the active full-screen Space.
        window.level = .statusBar
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary, .ignoresCycle]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false // We handle shadow in SwiftUI
        window.isReleasedWhenClosed = false
        window.center()

        // Disable window animations - we use SwiftUI
        window.animationBehavior = .none

        panelWindow = window
        installHostingView(in: window)
    }

    /// Recreated on every show so PanelContainer's enter state resets (onAppear fires again).
    private func installHostingView(in window: NSWindow) {
        let container = PanelContainer(store: store, onDismiss: { [weak self] in self?.hidePanelImmediate() })
        let hosting = NSHostingView(rootView: container)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = hosting
    }

    private func showPanel(_ window: NSWindow) {
        guard !isPanelPresented else { return }
        isPanelPresented = true
        installHostingView(in: window)
        
        // Position at mouse or screen center
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) ?? NSScreen.main {
            let mouseLocation = NSEvent.mouseLocation
            let windowFrame = window.frame
            let visibleFrame = screen.visibleFrame
            let x = mouseLocation.x - windowFrame.width / 2
            let y = mouseLocation.y - windowFrame.height / 2
            window.setFrameOrigin(NSPoint(x: max(visibleFrame.minX, min(x, visibleFrame.maxX - windowFrame.width)),
                                         y: max(visibleFrame.minY, min(y, visibleFrame.maxY - windowFrame.height))))
        }
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

    }
    
    private func hidePanel(_ window: NSWindow) {
        guard isPanelPresented else { return }
        hidePanelImmediate()
    }
    
    private func hidePanelImmediate() {
        guard isPanelPresented, let window = panelWindow else { return }
        isPanelPresented = false
        window.orderOut(nil)
    }
}

// MARK: - SwiftUI Panel Container with Full Animation Control

struct PanelContainer: View {
    @ObservedObject var store: ClipboardStore
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    @State private var dragOffset: CGSize = .zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var panelFocused: Bool
    
    private var dark: Bool { PCTheme.isDark() }
    
    var body: some View {
        ZStack {
            // Background dim
            Color.black.opacity(isVisible ? 0.15 : 0)
                .ignoresSafeArea()
                .animation(PCTokens.Motion.resolve(PCTokens.Motion.enter, reduced: reduceMotion), value: isVisible)
                .onTapGesture { dismissWithAnimation() }
            
            // Main Panel
            HistoryPanelView(store: store, panelVisible: isVisible, onHide: dismissWithAnimation)
                .offset(dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height > 20 {
                                dragOffset = CGSize(width: 0, height: value.translation.height)
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 100 {
                                dismissWithAnimation()
                            } else {
                                withAnimation(PCTokens.Motion.resolve(PCTokens.Motion.enter, reduced: reduceMotion)) {
                                    dragOffset = .zero
                                }
                            }
                        }
                )
        }
        .frame(width: 380, height: 480)
        .onAppear {
            panelFocused = true
            withAnimation(PCTokens.Motion.resolve(PCTokens.Motion.enter, reduced: reduceMotion)) {
                isVisible = true
            }
        }
        .onDisappear {
            isVisible = false
        }
        .focused($panelFocused)
    }
    
    private func dismissWithAnimation() {
        // Completion-based: orderOut runs only after the exit animation finishes (macOS 14+).
        withAnimation(
            PCTokens.Motion.resolve(PCTokens.Motion.exit, reduced: reduceMotion),
            completionCriteria: .logicallyComplete
        ) {
            isVisible = false
        } completion: {
            onDismiss()
        }
    }
}
