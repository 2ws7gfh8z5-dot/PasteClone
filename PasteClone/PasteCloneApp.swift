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
            Button("退出 PasteClone") { NSApp.terminate(nil) }
        } label: {
            Image("MenuBarIcon")
        }
        .menuBarExtraStyle(.menu)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = ClipboardStore()
    private var panelWindow: NSWindow?
    private var panelHostingView: NSHostingView<PanelContainer>?
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
        let container = PanelContainer(store: store, onDismiss: { [weak self] in self?.hidePanelImmediate() })
        let hosting = NSHostingView(rootView: container)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        panelHostingView = hosting
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 480),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary, .ignoresCycle]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false // We handle shadow in SwiftUI
        window.contentView = hosting
        window.isReleasedWhenClosed = false
        window.center()
        
        // Disable window animations - we use SwiftUI
        window.animationBehavior = .none
        
        panelWindow = window
    }
    
    private func showPanel(_ window: NSWindow) {
        guard !isPanelPresented else { return }
        isPanelPresented = true
        
        // Position at mouse or screen center
        if let screen = NSScreen.main {
            let mouseLocation = NSEvent.mouseLocation
            let windowFrame = window.frame
            let x = mouseLocation.x - windowFrame.width / 2
            let y = mouseLocation.y - windowFrame.height / 2
            window.setFrameOrigin(NSPoint(x: max(0, min(x, screen.frame.width - windowFrame.width)),
                                         y: max(0, min(y, screen.frame.height - windowFrame.height))))
        }
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Trigger SwiftUI entrance animation via state change
        if let container = panelHostingView?.rootView {
            // The PanelContainer will animate on appear
        }
    }
    
    private func hidePanel(_ window: NSWindow) {
        guard isPanelPresented else { return }
        
        // The SwiftUI view will animate out, then we hide the window
        if let container = panelHostingView?.rootView as? PanelContainer {
            // We need to communicate with the SwiftUI view to trigger exit animation
            // This is handled by the onDismiss callback which calls hidePanelImmediate
        }
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
            // Background dim - subtle
            Color.black.opacity(isVisible ? 0.15 : 0)
                .ignoresSafeArea()
                .animation(reduceMotion ? .linear(duration: 0.001) : PCTokens.Motion.easeOutExpo(reduceMotion: false), value: isVisible)
                .onTapGesture { dismissWithAnimation() }
            
            // Main Panel
            HistoryPanelView(store: store, onHide: dismissWithAnimation)
                .offset(dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Allow slight drag to dismiss
                            if value.translation.height > 20 {
                                dragOffset = CGSize(width: 0, height: value.translation.height)
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 100 {
                                dismissWithAnimation()
                            } else {
                                withAnimation(PCTokens.Motion.springBouncy(reduceMotion: reduceMotion)) {
                                    dragOffset = .zero
                                }
                            }
                        }
                )
        }
        .frame(width: 380, height: 480)
        .onAppear {
            panelFocused = true
            withAnimation(reduceMotion ? .linear(duration: 0.001) : PCTokens.Motion.springGentle(reduceMotion: false)) {
                isVisible = true
            }
        }
        .onDisappear {
            isVisible = false
        }
        .focused($panelFocused)
    }
    
    private func dismissWithAnimation() {
        withAnimation(reduceMotion ? .linear(duration: 0.001) : PCTokens.Motion.springSwift(reduceMotion: false)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0 : 0.22)) {
            onDismiss()
        }
    }
}