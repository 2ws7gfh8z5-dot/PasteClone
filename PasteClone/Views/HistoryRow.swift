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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            pasteActionButton
            if hovering { hoverButtons }
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(isSelected ? PCTheme.accentSoft.opacity(0.42) : PCTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(isSelected ? PCTheme.accent : PCTheme.divider, lineWidth: isSelected ? 1.5 : 1))
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { hovering = $0 }
        .animation(reduceMotion ? nil : PCTheme.bezier(duration: 0.22), value: hovering)
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

    var pasteActionButton: some View {
        Button(action: onPaste) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(PCTheme.accentSoft.opacity(0.72))
                    .frame(width: 31, height: 31)
                    .overlay {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(PCTheme.ink.opacity(0.22), lineWidth: 1)
                    }
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(PCTheme.ink)
                    .frame(width: 31, height: 31)
                Image(systemName: "arrow.turn.down.left")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.white)
                    .padding(3)
                    .background(Circle().fill(PCTheme.accent))
                    .offset(x: 3, y: 3)
            }
        }
        .buttonStyle(PCButtonStyle())
        .scaleEffect(hovering && !reduceMotion ? 1.04 : 1)
        .help("粘贴到当前输入框")
        .accessibilityLabel("粘贴到当前输入框")
    }

    @ViewBuilder var hoverButtons: some View {
        Button { store.pushStack(item) } label: { Image(systemName: "arrow.forward.square") }
            .buttonStyle(.plain).foregroundColor(PCTheme.accent)
        Button { store.togglePin(item) } label: { Image(systemName: item.isPinned ? "pin.fill" : "pin") }
            .buttonStyle(.plain).foregroundColor(item.isPinned ? PCTheme.accent : PCTheme.inkSoft)
        Button { store.delete(item) } label: { Image(systemName: "trash") }
            .buttonStyle(.plain).foregroundColor(.red)
    }

    @ViewBuilder var contextMenu: some View {
        Button("粘贴") { onPaste() }
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
