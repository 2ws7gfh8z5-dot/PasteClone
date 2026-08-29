import Foundation
import AppKit
import Combine
import os.log

fileprivate let logger = Logger(subsystem: "com.you.PasteClone", category: "ClipboardStore")

class ClipboardStore: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var searchText: String = ""
    @Published var selectedCollection: String? = nil
    @Published var pasteStack: [ClipboardItem] = []

    private let monitor = ClipboardMonitor()
    private let saveURL: URL
    private var suppressedChangeCount: Int?

    var collections: [String] {
        let names = items.compactMap(\.collectionName)
        return Array(Set(names)).sorted()
    }

    var filteredItems: [ClipboardItem] {
        var list = items
        if let col = selectedCollection {
            list = list.filter { $0.collectionName == col }
        }
        let pinned = list.filter(\.isPinned)
        let rest   = list.filter { !$0.isPinned }
        let ordered = pinned + rest
        guard !searchText.isEmpty else { return ordered }
        return ordered.filter { item in
            item.displayText.localizedCaseInsensitiveContains(searchText) ||
            (item.sourceAppName ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PasteClone", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        saveURL = dir.appendingPathComponent("history.json")
        load()

        monitor.onChange = { [weak self] changeCount, item in
            guard let self else { return }
            if self.suppressedChangeCount == changeCount {
                self.suppressedChangeCount = nil
                return
            }
            guard let item else { return }
            DispatchQueue.main.async { self.add(item) }
        }
        monitor.start()
    }

    private func add(_ item: ClipboardItem) {
        if let pinnedIndex = items.firstIndex(where: { $0.contentHash == item.contentHash && $0.isPinned }) {
            let pinned = items.remove(at: pinnedIndex)
            items.removeAll { $0.contentHash == item.contentHash }
            items.insert(pinned, at: 0)
        } else {
            items.removeAll { $0.contentHash == item.contentHash }
            items.insert(item, at: 0)
        }
        let configuredLimit = UserDefaults.standard.object(forKey: "maxItems") as? Int ?? 1000
        let limit = max(100, configuredLimit)
        items = Self.trimmed(items, limit: limit)
        save()
    }

    func paste(_ item: ClipboardItem, synthesizeKeypress: Bool = true) {
        logger.debug("请求粘贴: \(item.displayText.prefix(50), privacy: .public) (类型: \(String(describing: item.type), privacy: .public))")
        writeToPasteboard(item)
        if synthesizeKeypress {
            // 统一使用 0.18s 延迟，与 HistoryPanelView 保持一致
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                Self.synthesizePaste()
            }
        }
    }

    func copy(_ item: ClipboardItem) {
        writeToPasteboard(item)
    }

    private func writeToPasteboard(_ item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        logger.debug("写入剪贴板: 类型=\(String(describing: item.type), privacy: .public)")
        switch item.type {
        case .text:
            let text = item.textContent ?? ""
            pb.setString(text, forType: .string)
            logger.debug("写入文本: \(text.count, privacy: .public) 字符")
        case .rtf:
            if let d = item.rtfData {
                let typeStr = item.richTextType ?? NSPasteboard.PasteboardType.rtf.rawValue
                pb.setData(d, forType: NSPasteboard.PasteboardType(typeStr))
                logger.debug("写入 RTF: \(d.count, privacy: .public) 字节, 类型=\(typeStr, privacy: .public)")
            }
        case .image:
            if let d = item.imageData, let img = NSImage(data: d) {
                pb.writeObjects([img])
                logger.debug("写入图片: \(d.count, privacy: .public) 字节")
            }
        case .file:
            if let urls = item.fileURLs {
                pb.writeObjects(urls as [NSURL])
                logger.debug("写入文件: \(urls.count, privacy: .public) 个")
            }
        case .color:
            if let d = item.colorData,
               let c = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: d) {
                pb.writeObjects([c])
                logger.debug("写入颜色")
            }
        case .unknown:
            logger.debug("未知类型，跳过写入")
            break
        }
        suppressedChangeCount = pb.changeCount
        logger.debug("剪贴板写入完成, changeCount=\(pb.changeCount, privacy: .public)")
    }

    static func trimmed(_ items: [ClipboardItem], limit: Int) -> [ClipboardItem] {
        let pinned = items.filter(\.isPinned)
        let available = max(0, limit - pinned.count)
        return pinned + Array(items.filter { !$0.isPinned }.prefix(available))
    }

    internal static func synthesizePaste() {
        // 检查辅助功能权限，未授权时弹出系统提示并记录日志
        let prompt = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(prompt) else {
            logger.error("粘贴失败：缺少辅助功能权限，请在 系统设置 > 隐私与安全性 > 辅助功能 中授权 PasteClone")
            return
        }
        
        let src = CGEventSource(stateID: .hidSystemState)
        guard let down = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: true),
              let up   = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: false) else {
            logger.error("粘贴失败：无法创建 CGEvent")
            return
        }
        down.flags = .maskCommand
        up.flags   = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        logger.debug("合成 ⌘V 粘贴事件已发送")
    }

    func togglePin(_ item: ClipboardItem) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[i].isPinned.toggle()
        save()
    }

    func setCollection(_ item: ClipboardItem, name: String?) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[i].collectionName = name
        save()
    }

    func delete(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func clearHistory() {
        items.removeAll { !$0.isPinned }
        save()
    }

    func removeCollection(_ name: String) {
        for index in items.indices where items[index].collectionName == name {
            items[index].collectionName = nil
        }
        if selectedCollection == name { selectedCollection = nil }
        save()
    }

    func pushStack(_ item: ClipboardItem) { pasteStack.append(item) }
    func popStack() -> ClipboardItem? {
        guard !pasteStack.isEmpty else { return nil }
        let item = pasteStack.removeFirst()
        paste(item)
        return item
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: saveURL, options: .atomic)
        } catch {
            NSLog("PasteClone could not save history: %@", error.localizedDescription)
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
        do {
            items = try JSONDecoder().decode([ClipboardItem].self, from: Data(contentsOf: saveURL))
        } catch {
            NSLog("PasteClone could not load history: %@", error.localizedDescription)
        }
    }
}
