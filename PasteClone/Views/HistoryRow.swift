import SwiftUI
import AppKit

struct HistoryRow: View {
    @ObservedObject var store: ClipboardStore
    let item: ClipboardItem
    var isSelected = false
    var onSelect: () -> Void = {}
    var onPaste: () -> Void = {}
    @State private var hovering = false
    @State private var showCollectionMenu = false

    var body: some View {
        HStack(spacing: 10) {
            iconView
                .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.displayText)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .foregroundColor(PCTheme.ink)
                HStack(spacing: 6) {
                    Text(item.typeLabel)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(PCTheme.accentSoft.opacity(0.5))
                        .clipShape(Capsule())
                        .foregroundColor(PCTheme.inkSoft)
                    if let app = item.sourceAppName {
                        Text(app).font(.system(size: 10)).foregroundColor(PCTheme.inkSoft.opacity(0.7))
                    }
                    Spacer()
                    Text(item.timestamp, style: .relative)
                        .font(.system(size: 10)).foregroundColor(PCTheme.inkSoft.opacity(0.6))
                }
            }
            Spacer(minLength: 4)
            if hovering { hoverButtons }
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(isSelected ? PCTheme.accentSoft.opacity(0.42) : PCTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(isSelected ? PCTheme.accent : PCTheme.divider, lineWidth: isSelected ? 1.5 : 1))
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { hovering = $0 }
        .onTapGesture(count: 2) { onPaste() }
        .contextMenu { contextMenu }
    }

    @ViewBuilder var iconView: some View {
        switch item.type {
        case .image:
            if let img = item.previewImage {
                Image(nsImage: img).resizable().aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36).clipShape(RoundedRectangle(cornerRadius: 6))
            } else { typeFallback("🖼") }
        default:
            typeFallback(item.typeEmoji)
        }
    }

    func typeFallback(_ e: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6).fill(PCTheme.accentSoft.opacity(0.35))
                .frame(width: 36, height: 36)
            Text(e).font(.system(size: 17))
        }
    }

    @ViewBuilder var hoverButtons: some View {
        Button { applyToActiveApp() } label: { Image(systemName: "arrow.up.right.square") }
            .buttonStyle(.plain).foregroundColor(PCTheme.accent)
        Button { store.pushStack(item) } label: { Image(systemName: "arrow.forward.square") }
            .buttonStyle(.plain).foregroundColor(PCTheme.accent)
        Button { store.togglePin(item) } label: { Image(systemName: item.isPinned ? "pin.fill" : "pin") }
            .buttonStyle(.plain).foregroundColor(item.isPinned ? PCTheme.accent : PCTheme.inkSoft)
        Button { store.delete(item) } label: { Image(systemName: "trash") }
            .buttonStyle(.plain).foregroundColor(.red)
    }

    @ViewBuilder var contextMenu: some View {
        Button("粘贴") { onPaste() }
        Button("应用到活跃应用") { applyToActiveApp() }
        Button(item.isPinned ? "取消固定" : "固定") { store.togglePin(item) }
        Button("加入粘贴队列") { store.pushStack(item) }
        Menu("收藏到") {
            ForEach(store.collections, id: \.self) { c in
                Button(c) { store.setCollection(item, name: c) }
            }
            Button("新建收藏") { store.setCollection(item, name: "未命名") }
            if item.collectionName != nil {
                Button("移除收藏") { store.setCollection(item, name: nil) }
            }
        }
        Divider()
        Button("删除", role: .destructive) { store.delete(item) }
    }
    
    private func applyToActiveApp() {
        guard let app = ActiveAppService.shared.getActiveApp() else { return }
        if let content = item.textContent {
            ActiveAppService.shared.pasteToApp(app, content: content)
        } else if item.type == .file, let urls = item.fileURLs {
            // 对于文件，写入路径字符串
            let paths = urls.map { $0.path }.joined(separator: "\n")
            ActiveAppService.shared.pasteToApp(app, content: paths)
        } else if item.type == .image {
            // 图片通过粘贴板处理
            store.paste(item)
        }
    }
}

extension ClipboardItem {
    var typeLabel: String {
        switch type {
        case .text: return "文本"
        case .image: return "图片"
        case .file: return "文件"
        case .rtf: return "富文本"
        case .color: return "颜色"
        case .unknown: return "未知"
        }
    }
    var typeEmoji: String {
        switch type {
        case .text: return "T"
        case .image: return "🖼"
        case .file: return "📄"
        case .rtf: return "𝘙"
        case .color: return "🎨"
        case .unknown: return "?"
        }
    }
}
