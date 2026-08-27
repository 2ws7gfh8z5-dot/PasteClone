import SwiftUI
import AppKit

struct HistoryPanelView: View {
    @ObservedObject var store: ClipboardStore
    var onHide: () -> Void

    @State private var selectedID: ClipboardItem.ID?
    @FocusState private var panelFocused: Bool
    @FocusState private var searchFocused: Bool
    @AppStorage(PCTheme.modeKey) private var appearanceMode = PCTheme.Mode.automatic.rawValue
    @State private var clock = Date()

    private var selectedItem: ClipboardItem? {
        let visible = store.filteredItems
        return visible.first(where: { $0.id == selectedID }) ?? visible.first
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(PCTheme.divider)
            if store.filteredItems.isEmpty { emptyState } else { history }
            footer
        }
        .frame(width: 380, height: 480)
        .background(PCTheme.panel)
        .preferredColorScheme(PCTheme.isDark(PCTheme.Mode(rawValue: appearanceMode) ?? .automatic, date: clock) ? .dark : .light)
        .focusable()
        .focused($panelFocused)
        .onAppear { selectFirst(); panelFocused = true }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { clock = $0 }
        .onChange(of: store.filteredItems.map(\.id)) { _ in normalizeSelection() }
        .onKeyPress(.upArrow) { moveSelection(-1); return .handled }
        .onKeyPress(.downArrow) { moveSelection(1); return .handled }
        .onKeyPress(.return) { pasteSelected(); return .handled }
        .onKeyPress(characters: CharacterSet(charactersIn: "c"), phases: .down) { press in
            command(press) { if let item = selectedItem { store.copy(item) } }
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "v"), phases: .down) { press in
            command(press) { pasteSelected() }
        }
        .onKeyPress(.escape) { onHide(); return .handled }
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
            guard press.modifiers == .command, let number = Int(press.characters) else { return .ignored }
            select(number - 1)
            return .handled
        }
    }

    private var history: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(store.filteredItems) { item in
                        HistoryRow(store: store, item: item, isSelected: selectedItem?.id == item.id) {
                            selectedID = item.id
                        } onPaste: {
                            paste(item)
                        }
                        .id(item.id)
                    }
                }
                .padding(10)
            }
            .onChange(of: selectedID) { id in
                if let id { withAnimation(.easeOut(duration: 0.12)) { proxy.scrollTo(id, anchor: .center) } }
            }
        }
    }

    var header: some View {
        HStack(spacing: 8) {
            Text("PasteClone").font(.system(size: 15, weight: .bold)).foregroundColor(PCTheme.ink)
            TextField("搜索剪贴板…", text: $store.searchText)
                .textFieldStyle(.plain).focused($searchFocused)
                .font(.system(size: 13))
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(PCTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(PCTheme.divider, lineWidth: 1))
                .onSubmit { pasteSelected() }
            Button { onHide() } label: {
                Image(systemName: "xmark.circle.fill").foregroundColor(PCTheme.inkSoft)
            }.buttonStyle(.plain)
        }
        .padding(10)
    }

    @ViewBuilder var footer: some View {
        HStack(spacing: 12) {
            Button("粘贴队列\(store.pasteStack.isEmpty ? "" : " (\(store.pasteStack.count))")") {
                onHide(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { _ = store.popStack() }
            }.buttonStyle(.plain).foregroundColor(PCTheme.accent)
            Button("清除历史") { store.clearHistory() }
                .buttonStyle(.plain).foregroundColor(PCTheme.inkSoft)
            Spacer()
            Menu {
                ForEach(store.collections, id: \.self) { c in
                    Button(c) { store.selectedCollection = (store.selectedCollection == c) ? nil : c }
                }
                if store.selectedCollection != nil { Button("显示全部") { store.selectedCollection = nil } }
                Divider()
                ForEach(store.collections, id: \.self) { c in
                    Button("移除收藏 \(c)") { store.removeCollection(c) }
                }
            } label: {
                Image(systemName: store.selectedCollection == nil ? "folder" : "folder.fill")
                    .foregroundColor(store.selectedCollection == nil ? PCTheme.inkSoft : PCTheme.accent)
            }
            .menuStyle(.borderlessButton).frame(width: 24)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(PCTheme.panel)
    }

    @ViewBuilder var emptyState: some View {
        VStack(spacing: 10) {
            Text("📋").font(.system(size: 40))
            Text("暂无剪贴板内容").font(.system(size: 13)).foregroundColor(PCTheme.inkSoft)
            Text("复制任意内容后将显示在这里").font(.system(size: 11)).foregroundColor(PCTheme.inkSoft.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func command(_ press: KeyPress, action: () -> Void) -> KeyPress.Result {
        guard press.modifiers == .command else { return .ignored }
        action(); return .handled
    }

    private func selectFirst() { selectedID = store.filteredItems.first?.id }
    private func normalizeSelection() {
        if selectedItem == nil || !store.filteredItems.contains(where: { $0.id == selectedID }) { selectFirst() }
    }
    private func select(_ index: Int) {
        guard store.filteredItems.indices.contains(index) else { return }
        selectedID = store.filteredItems[index].id
    }
    private func moveSelection(_ offset: Int) {
        let items = store.filteredItems
        guard !items.isEmpty else { return }
        let current = items.firstIndex(where: { $0.id == selectedItem?.id }) ?? 0
        select(min(max(current + offset, 0), items.count - 1))
        panelFocused = true
    }
    private func pasteSelected() { if let item = selectedItem { paste(item) } }
    private func paste(_ item: ClipboardItem) {
        onHide()
        _ = ActiveAppService.shared.restoreTargetApp()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { store.paste(item) }
    }
    private func openSettings() {
        if !NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
}
