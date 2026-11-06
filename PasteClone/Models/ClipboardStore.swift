import Foundation
import AppKit
import Combine
import Vision
import os.log

fileprivate let logger = Logger(subsystem: "com.you.PasteClone", category: "ClipboardStore")

class ClipboardStore: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var searchText: String = ""
    @Published var selectedCollection: String? = nil
    @Published var typeFilter: ClipboardItemType? = nil
    @Published var pasteStack: [ClipboardItem] = []

    private let monitor = ClipboardMonitor()
    private let saveURL: URL
    private var suppressedChangeCount: Int?

    /// 看板排列顺序（创建顺序）；仅存名字，成员关系仍在 item.collectionName
    @Published private(set) var pinboardOrder: [String] = [] {
        didSet { UserDefaults.standard.set(pinboardOrder, forKey: "pinboardOrder") }
    }

    var collections: [String] {
        // 已登记的空看板也要显示，否则"新建"后会从条上消失
        Self.orderedCollections(present: Set(items.compactMap(\.collectionName)).union(pinboardOrder), order: pinboardOrder)
    }

    /// 已登记的看板按创建顺序在前，未登记的按字母序兜底
    static func orderedCollections(present: Set<String>, order: [String]) -> [String] {
        let ordered = order.filter { present.contains($0) }
        return ordered + present.subtracting(ordered).sorted()
    }

    var filteredItems: [ClipboardItem] {
        var list = items
        if let col = selectedCollection {
            list = list.filter { $0.collectionName == col }
        }
        if let tf = typeFilter {
            list = list.filter { $0.type == tf }
        }
        let pinned = list.filter(\.isPinned)
        let rest   = list.filter { !$0.isPinned }
        guard !searchText.isEmpty else { return pinned + rest }
        func ranked(_ group: [ClipboardItem]) -> [ClipboardItem] {
            group.compactMap { item -> (ClipboardItem, Int)? in
                let scores = [Self.fuzzyScore(searchText, item.displayText),
                          item.sourceAppName.flatMap { Self.fuzzyScore(searchText, $0) },
                          item.ocrText.flatMap { Self.fuzzyScore(searchText, $0) }]
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
        pinboardOrder = UserDefaults.standard.stringArray(forKey: "pinboardOrder") ?? []
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
        ProfileAnalyzer.shared.analyzeIfStale()
    }

    private func add(_ item: ClipboardItem) {
        ProfileAnalyzer.shared.record(item)
        if let pinnedIndex = items.firstIndex(where: { $0.contentHash == item.contentHash && $0.isPinned }) {
            let pinned = items.remove(at: pinnedIndex)
            items.removeAll { $0.contentHash == item.contentHash }
            items.insert(pinned, at: 0)
        } else {
            items.removeAll { $0.contentHash == item.contentHash }
            items.insert(item, at: 0)
        }
        let configuredLimit = UserDefaults.standard.object(forKey: "maxItems") as? Int ?? 1000
        if configuredLimit > 0 {
            items = Self.trimmed(Self.pruned(items, retentionDays: UserDefaults.standard.integer(forKey: "retentionDays")), limit: max(100, configuredLimit))
        } else {
            items = Self.pruned(items, retentionDays: UserDefaults.standard.integer(forKey: "retentionDays"))
        }
        save()
        if item.type == .image, let data = item.imageData {
            let id = item.id
            Task.detached(priority: .utility) { [weak self] in
                let text = Self.recognizeText(in: data)
                guard !text.isEmpty else { return }
                await MainActor.run {
                    guard let self, let i = self.items.firstIndex(where: { $0.id == id }) else { return }
                    self.items[i].ocrText = text
                    self.save()
                }
            }
        }
    }

    /// Vision 本地 OCR，供图片条目搜索用；失败返回空串
    private static func recognizeText(in data: Data) -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLanguages = ["zh-Hans", "en"]
        guard let handler = try? VNImageRequestHandler(data: data),
              (try? handler.perform([request])) != nil else { return "" }
        return (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: " ")
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
        if let name { registerCollection(name) }
        save()
    }

    /// 登记看板（保持创建顺序），重复名忽略
    func registerCollection(_ name: String) {
        let name = name.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !pinboardOrder.contains(name) else { return }
        pinboardOrder.append(name)
    }

    /// 重命名看板：成员关系、顺序、选中态一起带走
    func renameCollection(from old: String, to new: String) {
        let new = new.trimmingCharacters(in: .whitespaces)
        guard old != new, !new.isEmpty else { return }
        for i in items.indices where items[i].collectionName == old {
            items[i].collectionName = new
        }
        if let idx = pinboardOrder.firstIndex(of: old) {
            pinboardOrder[idx] = new
        } else {
            registerCollection(new)
        }
        if selectedCollection == old { selectedCollection = new }
        save()
    }

    /// 编辑文本条目内容
    func updateText(_ item: ClipboardItem, text: String) {
        guard let i = items.firstIndex(where: { $0.id == item.id }), items[i].type == .text else { return }
        items[i].textContent = text
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
        pinboardOrder.removeAll { $0 == name }
        if selectedCollection == name { selectedCollection = nil }
        save()
    }

    /// 预测下一条可能要粘贴的内容（对齐 Paste Intelligent Clipboard 的启发式版本）。
    /// ponytail: 纯启发式（置顶+来源 App+新近度）；Apple Intelligence 需要时再加 FoundationModels 通道
    static func suggest(items: [ClipboardItem], targetBundleID: String?) -> ClipboardItem? {
        var best: (ClipboardItem, Int)?
        for (index, item) in items.prefix(50).enumerated() {
            if index == 0 { continue }  // 最新一条已在剪贴板上，不建议
            var score = max(0, 50 - index)
            if item.isPinned { score += 40 }
            if let target = targetBundleID, item.sourceAppBundleID == target { score += 25 }
            if let b = best, b.1 >= score { continue }
            best = (item, score)
        }
        guard let b = best, b.1 >= 60 else { return nil }  // 至少需要一个强信号
        return b.0
    }

    /// 预测建议（无筛选/搜索时才有意义，由面板决定何时调用）
    func suggestion() -> ClipboardItem? {
        Self.suggest(items: items, targetBundleID: ActiveAppService.shared.targetBundleID)
    }

    func pushStack(_ item: ClipboardItem) { pasteStack.append(item) }
    func clearStack() { pasteStack.removeAll() }
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

    private let saveQueue = DispatchQueue(label: "com.you.justpaste.save", qos: .utility)
    private var saveWorkItem: DispatchWorkItem?

    /// 防抖落盘：0.5s 合并高频变更，主线程只取快照；退出前必须 flushSave()
    private func save() {
        let snapshot = items
        saveWorkItem?.cancel()
        let work = DispatchWorkItem { [saveURL] in
            do {
                let data = try JSONEncoder().encode(snapshot)
                try data.write(to: saveURL, options: .atomic)
            } catch {
                NSLog("PasteClone could not save history: %@", error.localizedDescription)
            }
        }
        saveWorkItem = work
        saveQueue.asyncAfter(deadline: .now() + 0.5, execute: work)
    }

    /// 立即落盘（应用退出前调用）
    func flushSave() {
        saveWorkItem?.cancel()
        saveWorkItem = nil
        saveQueue.sync {
            guard let data = try? JSONEncoder().encode(items) else { return }
            try? data.write(to: saveURL, options: .atomic)
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: saveURL.path),
              let data = try? Data(contentsOf: saveURL) else { return }
        if let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            items = decoded
            return
        }
        // 单条损坏不拖垮全量：逐条解码，坏记录跳过；原文件改名备份，绝不用空列表覆盖
        let recovered = Self.recover(from: data)
        let backup = saveURL.deletingLastPathComponent()
            .appendingPathComponent("history.corrupt-\(Int(Date().timeIntervalSince1970)).json")
        try? FileManager.default.moveItem(at: saveURL, to: backup)
        items = recovered
        logger.error("history.json 损坏，已恢复 \(recovered.count) 条，原文件备份为 \(backup.lastPathComponent, privacy: .public)")
    }

    /// 逐条容错解码：坏记录跳过，其余保留
    internal static func recover(from data: Data) -> [ClipboardItem] {
        guard let array = try? JSONSerialization.jsonObject(with: data) as? [Any] else { return [] }
        return array.compactMap { element in
            // 非对象元素（数字/字符串）会让 JSONSerialization 抛 NSException，必须先行排除
            guard let dict = element as? [String: Any],
                  let elementData = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
            return try? JSONDecoder().decode(ClipboardItem.self, from: elementData)
        }
    }
}
