import Foundation
import AppKit
import Combine

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
        writeToPasteboard(item)
        if synthesizeKeypress {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
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
        switch item.type {
        case .text:   pb.setString(item.textContent ?? "", forType: .string)
        case .rtf:    if let d = item.rtfData { pb.setData(d, forType: NSPasteboard.PasteboardType(item.richTextType ?? NSPasteboard.PasteboardType.rtf.rawValue)) }
        case .image:
            if let d = item.imageData, let img = NSImage(data: d) { pb.writeObjects([img]) }
        case .file:
            if let urls = item.fileURLs { pb.writeObjects(urls as [NSURL]) }
        case .color:
            if let d = item.colorData,
               let c = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: d) {
                pb.writeObjects([c])
            }
        case .unknown: break
        }
        suppressedChangeCount = pb.changeCount
    }

    static func trimmed(_ items: [ClipboardItem], limit: Int) -> [ClipboardItem] {
        let pinned = items.filter(\.isPinned)
        let available = max(0, limit - pinned.count)
        return pinned + Array(items.filter { !$0.isPinned }.prefix(available))
    }

    private static func synthesizePaste() {
        guard AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary) else { return }
        let src = CGEventSource(stateID: .hidSystemState)
        guard let down = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: true),
              let up   = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: false) else { return }
        down.flags = .maskCommand
        up.flags   = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
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
