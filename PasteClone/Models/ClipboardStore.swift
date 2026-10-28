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
        guard !searchText.isEmpty else { return pinned + rest }
        func ranked(_ group: [ClipboardItem]) -> [ClipboardItem] {
            group.compactMap { item -> (ClipboardItem, Int)? in
                let scores = [Self.fuzzyScore(searchText, item.displayText),
                              item.sourceAppName.flatMap { Self.fuzzyScore(searchText, $0) }]
                guard let best = scores.compactMap({ $0 }).max() else { return nil }
                return (item, best)
            }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
        }
        return ranked(pinned) + ranked(rest)
    }

    /// 子序列模糊匹配；query 为空时返回 0（全部匹配），不匹配返回 nil。
    static func fuzzyScore(_ query: String, _ text: String) -> Int? {
        if query.isEmpty { return 0 }
        let q = Array(query.lowercased()), t = Array(text.lowercased())
        var score = 0, ti = 0
        for (qi, ch) in q.enumerated() {
            var gap = 0
            while ti < t.count && t[ti] != ch { gap += 1; ti += 1 }
            guard ti < t.count else { return nil }
            score += 1 - gap                                  // 命中 +1，相隔越远扣得越多
            if qi > 0 && ti > 0 && t[ti - 1] == q[qi - 1] { score += 3 }   // 连续命中
            if ti == 0 || (!t[ti - 1].isLetter && !t[ti - 1].isNumber) { score += 5 }  // 词首命中
            if qi == 0 { score += max(0, 5 - ti) }            // 首次命中越靠前越好
            ti += 1
        }
        return score
    }

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PasteClone", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        saveURL = dir.appendingPathComponent("history.json")
        load()
        items = Self.pruned(items, retentionDays: UserDefaults.standard.integer(forKey: "retentionDays"))

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
        items = Self.trimmed(Self.pruned(items, retentionDays: UserDefaults.standard.integer(forKey: "retentionDays")), limit: limit)
        save()
    }

    func addText(_ text: String) {
        add(ClipboardItem(type: .text, textContent: text))
    }

    func paste(_ item: ClipboardItem, plainText: Bool = false, synthesizeKeypress: Bool = true) {
        logger.debug("请求粘贴: \(item.displayText.prefix(50), privacy: .private) (类型: \(String(describing: item.type), privacy: .public))")
        writeToPasteboard(item, plainText: plainText)
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

    private func writeToPasteboard(_ item: ClipboardItem, plainText: Bool = false) {
        let pb = NSPasteboard.general
        pb.clearContents()
        if plainText, item.type == .text || item.type == .rtf {
            pb.setString(item.displayText, forType: .string)
            suppressedChangeCount = pb.changeCount
            return
        }
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
                pb.setString(item.displayText, forType: .string) // ponytail: plain fallback for apps that ignore RTF
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

    static func pruned(_ items: [ClipboardItem], retentionDays: Int, now: Date = Date()) -> [ClipboardItem] {
        guard retentionDays > 0 else { return items }
        let cutoff = now.addingTimeInterval(-Double(retentionDays) * 86_400)
        return items.filter { $0.isPinned || $0.timestamp >= cutoff }
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

    func exportHistory(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(items).write(to: url, options: .atomic)
    }

    /// 按 contentHash 合并，已存在的保留本地版本；返回实际新增条数。
    func importHistory(from url: URL) throws -> Int {
        let imported = try JSONDecoder().decode([ClipboardItem].self, from: Data(contentsOf: url))
        var existing = Set(items.map(\.contentHash))
        let added = imported.filter { existing.insert($0.contentHash).inserted }
        items += added
        save()
        return added.count
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
            // Move the unreadable file aside so the next save cannot overwrite it.
            let backup = saveURL.deletingLastPathComponent()
                .appendingPathComponent("history.corrupt-\(Int(Date().timeIntervalSince1970)).json")
            try? FileManager.default.moveItem(at: saveURL, to: backup)
        }
    }
}
