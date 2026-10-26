import SwiftUI
import AppKit

struct HistoryRow: View {
    @ObservedObject var store: ClipboardStore
    let item: ClipboardItem
    var isSelected = false
    var onSelect: () -> Void = {}
    var onPaste: () -> Void = {}
    var onPastePlain: () -> Void = {}

    @State private var hovering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isFocused: Bool

    private var dark: Bool { PCTheme.isDark() }
    private var hoverAnimation: Animation {
        PCTokens.Motion.resolve(PCTokens.Motion.hover, reduced: reduceMotion)
    }
    private var reorderAnimation: Animation {
        PCTokens.Motion.resolve(PCTokens.Motion.reorder, reduced: reduceMotion)
    }
    private var exitAnimation: Animation {
        PCTokens.Motion.resolve(PCTokens.Motion.exit, reduced: reduceMotion)
    }

    var body: some View {
        HStack(spacing: PCTokens.Spacing.space4) {
            iconView
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: PCTokens.Spacing.space1) {
                Text(item.displayText)
                    .font(PCTokens.Font.bodyMedium)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .foregroundColor(PCTokens.Color.ink(dark))
                    .lineSpacing(PCTokens.Font.lineHeightNormal * 13 - 13)

                HStack(spacing: PCTokens.Spacing.space2) {
                    typeBadge
                    if let app = item.sourceAppName {
                        Text(app)
                            .font(PCTokens.Font.labelXSmall)
                            .foregroundColor(PCTokens.Color.inkMuted(dark))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    Spacer(minLength: PCTokens.Spacing.space4)
                    Text(item.timestamp, style: .relative)
                        .font(PCTokens.Font.monoXSmall)
                        .foregroundColor(PCTokens.Color.inkMuted(dark).opacity(0.7))
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: PCTokens.Spacing.space2)

            pasteActionButton

            hoverActionRail
        }
        .padding(.horizontal, PCTokens.Spacing.space4)
        .padding(.vertical, PCTokens.Spacing.space3)
        .background(backgroundForState)
        .clipShape(RoundedRectangle(cornerRadius: PCTokens.Radius.r4, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: PCTokens.Radius.r4, style: .continuous)
                .stroke(borderForState, lineWidth: borderWidthForState)
        )
        .shadow(isHoveringOrSelected ? PCTokens.Shadow.level2 : PCTokens.Shadow.level1)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
            onPaste()
        }
        .onHover { hovering = $0 }
        .focusable()
        .focused($isFocused)
        .animation(hoverAnimation, value: isHoveringOrSelected)
        .contextMenu { contextMenu }
    }

    private var isHoveringOrSelected: Bool { hovering || isSelected || isFocused }

    private var backgroundForState: some View {
        Group {
            if isSelected {
                PCTokens.Color.accentSoft(dark).opacity(0.48)
            } else if isFocused {
                PCTokens.Color.accentSoft(dark).opacity(0.28)
            } else if hovering {
                PCTokens.Color.card(dark).opacity(0.9)
            } else {
                PCTokens.Color.card(dark)
            }
        }
    }

    private var borderForState: Color {
        if isSelected || isFocused { return PCTokens.Color.accent }
        if hovering { return PCTokens.Color.divider(dark).opacity(0.7) }
        return PCTokens.Color.divider(dark)
    }

    private var borderWidthForState: CGFloat {
        (isSelected || isFocused) ? 2 : 1
    }

    @ViewBuilder
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous)
                .fill(PCTokens.Color.accentSoft(dark).opacity(0.35))
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous)
                        .stroke(PCTokens.Color.accent.opacity(hovering ? 0.5 : 0.2), lineWidth: 1)
                )

            switch item.type {
            case .image:
                if let img = item.previewImage {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: PCTokens.Radius.r1, style: .continuous))
                } else {
                    typeFallback(item.typeEmoji)
                }
            default:
                typeFallback(item.typeEmoji)
            }
        }
    }

    private func typeFallback(_ emoji: String) -> some View {
        Text(emoji)
            .font(.system(size: 18))
    }

    private var typeBadge: some View {
        Text(item.typeLabel)
            .font(PCTokens.Font.labelXSmall)
            .padding(.horizontal, PCTokens.Spacing.space2)
            .padding(.vertical, PCTokens.Spacing.space0)
            .background(
                Capsule()
                    .fill(PCTokens.Color.accentSoft(dark).opacity(0.55))
            )
            .foregroundColor(PCTokens.Color.inkSoft(dark))
    }

    private var pasteActionButton: some View {
        Button(action: { onPaste() }) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous)
                    .fill(PCTokens.Color.accentSoft(dark).opacity(0.8))
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous)
                            .stroke(PCTokens.Color.ink(dark).opacity(0.18), lineWidth: 1)
                    )

                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(PCTokens.Color.ink(dark))

                Image(systemName: "arrow.turn.down.left")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .padding(3)
                    .background(Circle().fill(PCTokens.Color.accent))
                    .offset(x: 4, y: 4)
            }
        }
        .buttonStyle(PCButtonStyle())
        .help("粘贴到当前输入框 (⌘V)")
        .accessibilityLabel("粘贴到当前输入框")
        .focusable()
    }

    @ViewBuilder
    private var hoverActionRail: some View {
        HStack(spacing: PCTokens.Spacing.space2) {
            IconActionButton(
                systemName: "arrow.forward.square",
                help: "加入粘贴队列",
                action: { store.pushStack(item) },
                color: PCTokens.Color.accent,
                isActive: false
            )
            IconActionButton(
                systemName: item.isPinned ? "pin.fill" : "pin",
                help: item.isPinned ? "取消固定" : "固定",
                action: { withAnimation(reorderAnimation) { store.togglePin(item) } },
                color: item.isPinned ? PCTokens.Color.accent : PCTokens.Color.inkSoft(dark),
                isActive: item.isPinned
            )
            IconActionButton(
                systemName: "trash",
                help: "删除",
                action: { withAnimation(exitAnimation) { store.delete(item) } },
                color: PCTokens.Color.error,
                isActive: false
            )
        }
        .frame(width: 100, alignment: .trailing)
        .opacity(hovering ? 1 : 0)
        .allowsHitTesting(hovering)
        .accessibilityHidden(!hovering)
        .animation(hoverAnimation, value: hovering)
    }

    @ViewBuilder
    private var contextMenu: some View {
        Button("粘贴") { onPaste() }
        Button("纯文本粘贴") { onPastePlain() }
        Button(item.isPinned ? "取消固定" : "固定") { withAnimation(reorderAnimation) { store.togglePin(item) } }
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
        Button("删除", role: .destructive) { withAnimation(exitAnimation) { store.delete(item) } }
    }
}

// MARK: - Reusable Icon Action Button

private struct IconActionButton: View {
    let systemName: String
    let help: String
    let action: () -> Void
    let color: Color
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 28, height: 28)
                .foregroundColor(isActive || hovering ? color : PCTokens.Color.inkSoft(PCTheme.isDark()))
        }
        .buttonStyle(PCButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous)
                .fill(hovering ? color.opacity(0.18) : .clear)
        )
        .contentShape(RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous))
        .onHover { hovering = $0 }
        .animation(PCTokens.Motion.resolve(PCTokens.Motion.hover, reduced: reduceMotion), value: hovering)
        .help(help)
    }
}

// MARK: - ClipboardItem Extensions (unchanged)

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
