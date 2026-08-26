import SwiftUI
import AppKit

struct HistoryPanelView: View {
    @ObservedObject var store: ClipboardStore
    var onHide: () -> Void

    @State private var collectionMenuOpen = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(PCTheme.divider)
            if store.filteredItems.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(store.filteredItems) { item in
                            HistoryRow(store: store, item: item)
                        }
                    }
                    .padding(10)
                }
            }
            footer
        }
        .frame(width: 380, height: 480)
        .background(PCTheme.panel)
        .preferredColorScheme(.light)
    }

    var header: some View {
        HStack(spacing: 8) {
            Text("PasteClone").font(.system(size: 15, weight: .bold)).foregroundColor(PCTheme.ink)
            TextField("搜索剪贴板…", text: $store.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(PCTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(PCTheme.divider, lineWidth: 1))
            Button { onHide() } label: {
                Image(systemName: "xmark.circle.fill").foregroundColor(PCTheme.inkSoft)
            }.buttonStyle(.plain)
        }
        .padding(10)
    }

    @ViewBuilder var footer: some View {
        HStack(spacing: 12) {
            Button("粘贴队列\(store.pasteStack.isEmpty ? "" : " (\(store.pasteStack.count))")") {
                _ = store.popStack()
            }.buttonStyle(.plain).foregroundColor(PCTheme.accent)
            Button("清除历史") { store.clearHistory() }
                .buttonStyle(.plain).foregroundColor(PCTheme.inkSoft)
            Spacer()
            Menu {
                ForEach(store.collections, id: \.self) { c in
                    Button(c) { store.selectedCollection = (store.selectedCollection == c) ? nil : c }
                }
                if store.selectedCollection != nil {
                    Button("显示全部") { store.selectedCollection = nil }
                }
                Divider()
                ForEach(store.collections, id: \.self) { c in
                    Button("移除收藏 \(c)") {
                        for i in store.items.indices where store.items[i].collectionName == c {
                            store.items[i].collectionName = nil
                        }
                    }
                }
            } label: {
                Image(systemName: store.selectedCollection == nil ? "folder" : "folder.fill")
                    .foregroundColor(store.selectedCollection == nil ? PCTheme.inkSoft : PCTheme.accent)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24)
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
}
