import SwiftUI
import AppKit
import os.log

fileprivate let logger = Logger(subsystem: "com.you.PasteClone", category: "HistoryPanel")

struct HistoryPanelView: View {
    @ObservedObject var store: ClipboardStore
    var onHide: () -> Void
    
    @State private var selectedID: ClipboardItem.ID?
    @FocusState private var panelFocused: Bool
    @FocusState private var searchFocused: Bool
    @AppStorage(PCTheme.modeKey) private var appearanceMode = PCTheme.Mode.automatic.rawValue
    @State private var clock = Date()
    @State private var panelVisible = false
    @State private var searchTextLocal = ""
    @State private var showPasteQueueHint = false
    
    private var dark: Bool { PCTheme.isDark() }
    private var visibleItems: [ClipboardItem] { store.filteredItems }
    
    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, PCTokens.Spacing.space4)
                .padding(.top, PCTokens.Spacing.space4)
                .padding(.bottom, PCTokens.Spacing.space3)
            
            Divider()
                .background(PCTokens.Color.divider(dark))
                .padding(.horizontal, PCTokens.Spacing.space4)
                .opacity(panelVisible ? 1 : 0)
                .animation(PCTokens.Motion.easeOutExpo(reduceMotion: AccessibilitySettings.reduceMotion).delay(0.08), value: panelVisible)
            
            if visibleItems.isEmpty {
                emptyState
            } else {
                historyList
            }
            
            footer
        }
        .frame(width: 380, height: 480)
        .background(
            ZStack {
                PCTokens.Color.glass(dark)
                if !AccessibilitySettings.reduceTransparency {
                    Color.clear.background(.ultraThinMaterial).opacity(dark ? 0.65 : 0.55)
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: PCTokens.Radius.r6, style: .continuous)
                .stroke(PCTokens.Color.glassBorder(dark), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: PCTokens.Radius.r6, style: .continuous))
        .shadow(PCTokens.Shadow.level3)
        .scaleEffect(panelVisible ? 1 : 0.94)
        .opacity(panelVisible ? 1 : 0)
        .offset(y: panelVisible ? 0 : 8)
        .animation(
            AccessibilitySettings.reduceMotion
                ? .linear(duration: 0.001)
                : PCTokens.Motion.springGentle(reduceMotion: false),
            value: panelVisible
        )
        .preferredColorScheme(dark ? .dark : .light)
        .focusable()
        .focused($panelFocused)
        .onAppear {
            selectFirst()
            panelFocused = true
            withAnimation(PCTokens.Motion.springGentle(reduceMotion: AccessibilitySettings.reduceMotion).delay(0.04)) {
                panelVisible = true
            }
        }
        .onDisappear { panelVisible = false }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { clock = $0 }
        .onChange(of: store.filteredItems.map(\.id)) { _, _ in normalizeSelection() }
        .onChange(of: store.searchText) { _, new in searchTextLocal = new }
        // Keyboard shortcuts
        .onKeyPress(.upArrow) { moveSelection(-1); return .handled }
        .onKeyPress(.downArrow) { moveSelection(1); return .handled }
        .onKeyPress(.return) { pasteSelected(); return .handled }
        .onKeyPress(.escape) { closeWithAnimation(); return .handled }
        .onKeyPress(characters: CharacterSet(charactersIn: "c"), phases: .down) { press in
            command(press) { if let item = selectedItem { store.copy(item) } }
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "v"), phases: .down) { press in
            command(press) { pasteSelected() }
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "f"), phases: .down) { press in
            command(press) { searchFocused = true }
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "p"), phases: .down) { press in
            command(press) { if let item = selectedItem { store.togglePin(item) } }
        }
        .onKeyPress(.delete, phases: .down) { press in
            command(press) { if let item = selectedItem { store.delete(item) } }
        }
        .onKeyPress(characters: CharacterSet(charactersIn: ","), phases: .down) { press in
            command(press) { openSettings() }
        }
        .onKeyPress(characters: .decimalDigits) { press in
            guard press.modifiers.contains(.command),
                  !press.modifiers.contains(.shift),
                  !press.modifiers.contains(.option),
                  !press.modifiers.contains(.control),
                  let number = Int(press.characters) else { return .ignored }
            select(number - 1)
            return .handled
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(spacing: PCTokens.Spacing.space3) {
            // Logo / Title
            HStack(spacing: PCTokens.Spacing.space2) {
                Image(systemName: "doc.on.clipboard.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PCTokens.Color.accent)
                    .symbolRenderingMode(.hierarchical)
                    .symbolEffect(.bounce, value: panelVisible)
                
                Text("PasteClone")
                    .font(PCTokens.Font.headingMedium)
                    .foregroundColor(PCTokens.Color.ink(dark))
            }
            
            // Search Field
            HStack(spacing: PCTokens.Spacing.space2) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(searchFocused ? PCTokens.Color.accent : PCTokens.Color.inkMuted(dark))
                    .animation(PCTokens.Motion.springSwift(reduceMotion: AccessibilitySettings.reduceMotion), value: searchFocused)
                
                TextField("搜索剪贴板…", text: Binding(
                    get: { store.searchText },
                    set: { store.searchText = $0; searchTextLocal = $0 }
                ))
                .textFieldStyle(.plain)
                .focused($searchFocused)
                .font(PCTokens.Font.bodyMedium)
                .padding(.horizontal, PCTokens.Spacing.space3)
                .padding(.vertical, PCTokens.Spacing.space2)
                .background(
                    RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous)
                        .fill(PCTokens.Color.card(dark))
                        .overlay(
                            RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous)
                                .stroke(searchFocused ? PCTokens.Color.accent : PCTokens.Color.divider(dark), lineWidth: searchFocused ? 2 : 1)
                        )
                        .shadow(searchFocused ? PCTokens.Shadow.glow : PCTokens.Shadow.level1)
                )
                .animation(PCTokens.Motion.springSwift(reduceMotion: AccessibilitySettings.reduceMotion), value: searchFocused)
                .onSubmit { pasteSelected() }
                .frame(maxWidth: .infinity)
            }
            
            // Close Button
            Button(action: closeWithAnimation) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(PCTokens.Color.inkMuted(dark))
                    .rotationEffect(.degrees(panelVisible ? 90 : 0))
                    .scaleEffect(panelVisible ? 1.0 : 0.8)
            }
            .buttonStyle(.plain)
            .frame(width: 28, height: 28)
            .contentShape(RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous)
                    .fill(PCTokens.Color.inkMuted(dark).opacity(0.12))
                    .opacity(0)
            )
            .onHover { hovering in
                // hover feedback via background opacity
            }
            .help("关闭面板 (Esc)")
            .animation(PCTokens.Motion.springSwift(reduceMotion: AccessibilitySettings.reduceMotion), value: panelVisible)
        }
    }
    
    // MARK: - History List
    
    private var historyList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: PCTokens.Spacing.space2) {
                    ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                        HistoryRow(
                            store: store,
                            item: item,
                            isSelected: selectedItem?.id == item.id,
                            onSelect: { selectedID = item.id },
                            onPaste: { paste(item) },
                            index: index,
                            totalCount: visibleItems.count
                        )
                        .id(item.id)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.92).combined(with: .opacity).combined(with: .offset(y: -8)),
                                removal: .scale(scale: 0.92).combined(with: .opacity).combined(with: .offset(x: 30))
                            )
                        )
                    }
                }
                .padding(.horizontal, PCTokens.Spacing.space3)
                .padding(.vertical, PCTokens.Spacing.space3)
                .animation(PCTokens.Motion.springSmooth(reduceMotion: AccessibilitySettings.reduceMotion), value: visibleItems.count)
            }
            .onChange(of: selectedID) { _, id in
                if let id {
                    let animation = AccessibilitySettings.reduceMotion ? nil : PCTokens.Motion.springSmooth(reduceMotion: false)
                    withAnimation(animation) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: PCTokens.Spacing.space5) {
            // Animated clipboard illustration
            ZStack {
                Circle()
                    .fill(PCTokens.Color.accentSoft(dark).opacity(0.2))
                    .frame(width: 80, height: 80)
                    .scaleEffect(panelVisible ? 1 : 0.7)
                    .opacity(panelVisible ? 1 : 0)
                    .animation(PCTokens.Motion.springGentle(reduceMotion: AccessibilitySettings.reduceMotion).delay(0.15), value: panelVisible)
                
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(PCTokens.Color.accent)
                    .symbolRenderingMode(.hierarchical)
                    .symbolEffect(.pulse, options: .repeating, value: panelVisible)
            }
            
            VStack(spacing: PCTokens.Spacing.space2) {
                Text("暂无剪贴板内容")
                    .font(PCTokens.Font.headingSmall)
                    .foregroundColor(PCTokens.Color.ink(dark))
                
                Text("复制任意内容后将显示在这里")
                    .font(PCTokens.Font.bodySmall)
                    .foregroundColor(PCTokens.Color.inkMuted(dark))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(panelVisible ? 1 : 0)
            .offset(y: panelVisible ? 0 : 12)
            .animation(PCTokens.Motion.easeOutExpo(reduceMotion: AccessibilitySettings.reduceMotion).delay(0.2), value: panelVisible)
            
            // Keyboard hint
            HStack(spacing: PCTokens.Spacing.space2) {
                KeyCap("⇧⌘V")
                Text("打开面板")
                    .font(PCTokens.Font.labelSmall)
                    .foregroundColor(PCTokens.Color.inkMuted(dark))
            }
            .padding(.horizontal, PCTokens.Spacing.space3)
            .padding(.vertical, PCTokens.Spacing.space1)
            .background(
                Capsule()
                    .fill(PCTokens.Color.card(dark))
                    .stroke(PCTokens.Color.divider(dark), lineWidth: 1)
            )
            .opacity(panelVisible ? 0.7 : 0)
            .animation(PCTokens.Motion.easeOutExpo(reduceMotion: AccessibilitySettings.reduceMotion).delay(0.3), value: panelVisible)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(PCTokens.Spacing.space6)
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack(spacing: PCTokens.Spacing.space4) {
            // Paste Queue Button
            Button(action: {
                closeWithAnimation()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { _ = store.popStack() }
            }) {
                HStack(spacing: PCTokens.Spacing.space2) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 13, weight: .semibold))
                    Text("粘贴队列")
                        .font(PCTokens.Font.labelMedium)
                    if !store.pasteStack.isEmpty {
                        Text("\(store.pasteStack.count)")
                            .font(PCTokens.Font.monoSmall)
                            .padding(.horizontal, PCTokens.Spacing.space2)
                            .padding(.vertical, PCTokens.Spacing.space0)
                            .background(Capsule().fill(PCTokens.Color.accent))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .foregroundColor(PCTokens.Color.accent)
                .padding(.horizontal, PCTokens.Spacing.space4)
                .padding(.vertical, PCTokens.Spacing.space2)
                .background(
                    RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous)
                        .fill(PCTokens.Color.accentSoft(dark).opacity(0.2))
                )
            }
            .buttonStyle(.plain)
            .help("粘贴队列 (空时自动创建)")
            
            // Clear History
            Button(action: { store.clearHistory() }) {
                HStack(spacing: PCTokens.Spacing.space2) {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .medium))
                    Text("清除历史")
                        .font(PCTokens.Font.labelMedium)
                }
                .foregroundColor(PCTokens.Color.inkSoft(dark))
                .padding(.horizontal, PCTokens.Spacing.space4)
                .padding(.vertical, PCTokens.Spacing.space2)
                .background(
                    RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous)
                        .fill(PCTokens.Color.card(dark))
                        .stroke(PCTokens.Color.divider(dark), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .help("清除所有历史记录")
            
            Spacer()
            
            // Collection Menu
            Menu {
                ForEach(store.collections, id: \.self) { c in
                    Button(action: { 
                        store.selectedCollection = (store.selectedCollection == c) ? nil : c 
                    }) {
                        HStack {
                            Text(c)
                            if store.selectedCollection == c {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                if store.selectedCollection != nil {
                    Divider()
                    Button("显示全部") { store.selectedCollection = nil }
                }
                if !store.collections.isEmpty {
                    Divider()
                    ForEach(store.collections, id: \.self) { c in
                        Button("移除收藏 \"\(c)\"", role: .destructive) { store.removeCollection(c) }
                    }
                }
            } label: {
                Image(systemName: store.selectedCollection == nil ? "folder" : "folder.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(store.selectedCollection == nil ? PCTokens.Color.inkSoft(dark) : PCTokens.Color.accent)
                    .symbolEffect(.bounce, value: store.selectedCollection != nil)
                    .frame(width: 28, height: 28)
                    .contentShape(RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous))
                    .background(
                        RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous)
                            .fill(PCTokens.Color.accentSoft(dark).opacity(store.selectedCollection == nil ? 0 : 0.18))
                    )
            }
            .menuStyle(.borderlessButton)
            .help("收藏分组")
        }
        .padding(.horizontal, PCTokens.Spacing.space4)
        .padding(.vertical, PCTokens.Spacing.space3)
        .background(
            ZStack {
                PCTokens.Color.glass(dark)
                if !AccessibilitySettings.reduceTransparency {
                    Color.clear.background(.ultraThinMaterial).opacity(dark ? 0.6 : 0.5)
                }
            }
        )
        .overlay(
            Rectangle()
                .fill(PCTokens.Color.divider(dark))
                .frame(height: 1),
            alignment: .top
        )
        .opacity(panelVisible ? 1 : 0)
        .offset(y: panelVisible ? 0 : 8)
        .animation(PCTokens.Motion.easeOutExpo(reduceMotion: AccessibilitySettings.reduceMotion).delay(0.12), value: panelVisible)
    }
    
    // MARK: - Helpers
    
    private var selectedItem: ClipboardItem? {
        visibleItems.first(where: { $0.id == selectedID }) ?? visibleItems.first
    }
    
    private func command(_ press: KeyPress, action: () -> Void) -> KeyPress.Result {
        guard !searchFocused,
              press.modifiers.contains(.command),
              !press.modifiers.contains(.shift),
              !press.modifiers.contains(.option),
              !press.modifiers.contains(.control) else { return .ignored }
        action()
        return .handled
    }
    
    private func selectFirst() { selectedID = visibleItems.first?.id }
    private func normalizeSelection() {
        if selectedItem == nil || !visibleItems.contains(where: { $0.id == selectedID }) { selectFirst() }
    }
    private func select(_ index: Int) {
        guard visibleItems.indices.contains(index) else { return }
        selectedID = visibleItems[index].id
    }
    private func moveSelection(_ offset: Int) {
        let items = visibleItems
        guard !items.isEmpty else { return }
        let current = items.firstIndex(where: { $0.id == selectedItem?.id }) ?? 0
        select(min(max(current + offset, 0), items.count - 1))
        panelFocused = true
    }
    private func pasteSelected() { if let item = selectedItem { paste(item) } }
    
    private func paste(_ item: ClipboardItem) {
        logger.debug("面板粘贴操作: \(item.displayText.prefix(50), privacy: .public) (ID: \(item.id.uuidString.prefix(8), privacy: .public))")
        closeWithAnimation()
        let restored = ActiveAppService.shared.restoreTargetApp()
        logger.debug("恢复目标应用: \(restored ? "成功" : "失败(应用可能已终止)", privacy: .public)")
        store.paste(item, synthesizeKeypress: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            logger.debug("延迟后发送 ⌘V")
            ClipboardStore.synthesizePaste()
        }
    }
    
    private func closeWithAnimation() {
        withAnimation(AccessibilitySettings.reduceMotion ? .linear(duration: 0.001) : PCTokens.Motion.springSwift(reduceMotion: false)) {
            panelVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (AccessibilitySettings.reduceMotion ? 0 : 0.18)) {
            onHide()
        }
    }
    
    private func openSettings() {
        if !NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
}

// MARK: - KeyCap Helper

private struct KeyCap: View {
    let text: String
    @Environment(\.colorScheme) private var colorScheme
    private var dark: Bool { colorScheme == .dark }
    
    init(_ text: String) { self.text = text }
    
    var body: some View {
        Text(text)
            .font(PCTokens.Font.monoXSmall)
            .foregroundColor(PCTokens.Color.ink(dark))
            .padding(.horizontal, PCTokens.Spacing.space2)
            .padding(.vertical, PCTokens.Spacing.space0)
            .background(
                RoundedRectangle(cornerRadius: PCTokens.Radius.r1, style: .continuous)
                    .fill(PCTokens.Color.card(dark))
                    .stroke(PCTokens.Color.divider(dark), lineWidth: 1)
                    .shadow(PCTokens.Shadow.level1)
            )
    }
}