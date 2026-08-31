import SwiftUI
import AppKit

struct HistoryRow: View {
    @ObservedObject var store: ClipboardStore
    let item: ClipboardItem
    var isSelected = false
    var onSelect: () -> Void = {}
    var onPaste: () -> Void = {}
    let index: Int
    let totalCount: Int
    
    @State private var hovering = false
    @State private var isPressed = false
    @State private var appear = false
    @State private var iconScale: CGFloat = 0.8
    @State private var iconRotation: Double = -8
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isFocused: Bool
    
    private var dark: Bool { PCTheme.isDark() }
    private var staggerDelay: Double {
        PCTokens.Motion.staggerDelay(index: index)
    }
    
    var body: some View {
        HStack(spacing: PCTokens.Spacing.space4) {
            iconView
                .frame(width: 40, height: 40)
                .scaleEffect(iconScale)
                .rotationEffect(.degrees(iconRotation))
            
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
        .onAppear { animateEntrance() }
        .onChange(of: isSelected) { _, new in
            if new {
                withAnimation(PCTokens.Motion.springSwift(reduceMotion: reduceMotion)) {
                    // selection flash handled by background/border
                }
            }
        }
        .animation(reduceMotion ? nil : PCTokens.Motion.springSmooth(reduceMotion: reduceMotion), value: hovering)
        .animation(reduceMotion ? nil : PCTokens.Motion.springStiff(reduceMotion: reduceMotion), value: isPressed)
        .animation(reduceMotion ? nil : PCTokens.Motion.springGentle(reduceMotion: reduceMotion), value: isFocused)
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
                        .transition(.scale.combined(with: .opacity))
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
            .symbolEffect(.bounce, value: hovering && !reduceMotion)
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
            .scaleEffect(hovering && !reduceMotion ? 1.04 : 1)
            .animation(reduceMotion ? nil : PCTokens.Motion.springSwift(reduceMotion: reduceMotion), value: hovering)
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
                    .symbolEffect(.bounce, value: isPressed)
                
                Image(systemName: "arrow.turn.down.left")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .padding(3)
                    .background(Circle().fill(PCTokens.Color.accent))
                    .offset(x: 4, y: 4)
            }
        }
        .buttonStyle(PCButtonStyle())
        .scaleEffect(isPressed ? 0.92 : (hovering && !reduceMotion ? 1.06 : 1))
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
                action: { store.togglePin(item) },
                color: item.isPinned ? PCTokens.Color.accent : PCTokens.Color.inkSoft(dark),
                isActive: item.isPinned
            )
            IconActionButton(
                systemName: "trash",
                help: "删除",
                action: { store.delete(item) },
                color: PCTokens.Color.error,
                isActive: false
            )
        }
        .frame(width: 100, alignment: .trailing)
        .offset(x: hovering ? 0 : 24)
        .opacity(hovering ? 1 : 0)
        .allowsHitTesting(hovering)
        .accessibilityHidden(!hovering)
        .animation(reduceMotion ? nil : PCTokens.Motion.springSmooth(reduceMotion: reduceMotion), value: hovering)
    }
    
    @ViewBuilder
    private var contextMenu: some View {
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
    
    private func animateEntrance() {
        guard !reduceMotion else { 
            appear = true
            iconScale = 1
            iconRotation = 0
            return 
        }
        
        // Staggered entrance
        withAnimation(
            PCTokens.Motion.springGentle(reduceMotion: reduceMotion)
            .delay(staggerDelay)
        ) {
            appear = true
            iconScale = 1
            iconRotation = 0
        }
        
        // Subtle icon bounce after entrance
        DispatchQueue.main.asyncAfter(deadline: .now() + staggerDelay + 0.25) {
            withAnimation(PCTokens.Motion.springBouncy(reduceMotion: reduceMotion)) {
                iconScale = 1.06
                iconRotation = 2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(PCTokens.Motion.springSwift(reduceMotion: reduceMotion)) {
                    iconScale = 1
                    iconRotation = 0
                }
            }
        }
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
    @State private var pressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 28, height: 28)
                .foregroundColor(isActive ? color : (hovering ? color : PCTokens.Color.inkSoft(PCTheme.isDark())))
                .symbolEffect(.bounce, value: pressed)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous)
                .fill(hovering ? color.opacity(0.18) : .clear)
        )
        .contentShape(RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous))
        .scaleEffect(pressed ? 0.85 : (hovering && !reduceMotion ? 1.1 : 1))
        .onHover { hovering = $0 }
        .onChange(of: hovering) { _, new in
            if new { pressed = false }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
        .animation(reduceMotion ? nil : PCTokens.Motion.springSwift(reduceMotion: reduceMotion), value: hovering)
        .animation(reduceMotion ? nil : PCTokens.Motion.springStiff(reduceMotion: reduceMotion), value: pressed)
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
