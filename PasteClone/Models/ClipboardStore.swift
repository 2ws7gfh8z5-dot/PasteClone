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
    private var suppressNextChange = false

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

        monitor.onChange = { [weak self] item in
            guard let self, let item else { return }
            if self.suppressNextChange { self.suppressNextChange = false; return }
            DispatchQueue.main.async { self.add(item) }
        }
        monitor.start()
    }

    private func add(_ item: ClipboardItem) {
        items.removeAll { $0.contentHash == item.contentHash && !$0.isPinned }
        items.insert(item, at: 0)
        let configuredLimit = UserDefaults.standard.object(forKey: "maxItems") as? Int ?? 1000
        let limit = max(100, configuredLimit)
        if items.count > limit {
            let pinned = items.filter(\.isPinned)
            let unpinned = Array(items.filter { !$0.isPinned }.prefix(limit))
            items = pinned + unpinned
        }
        save()
    }

    func paste(_ item: ClipboardItem, synthesizeKeypress: Bool = true) {
        suppressNextChange = true
        writeToPasteboard(item)
        if synthesizeKeypress {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                Self.synthesizePaste()
            }
        }
    }

    func copy(_ item: ClipboardItem) {
        suppressNextChange = true
        writeToPasteboard(item)
    }

    private func writeToPasteboard(_ item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.type {
        case .text:   pb.setString(item.textContent ?? "", forType: .string)
        case .rtf:    if let d = item.rtfData { pb.setData(d, forType: .rtf) }
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
    }

    private static func synthesizePaste() {
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
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: saveURL)
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let loaded = try? JSONDecoder().decode([ClipboardItem].self, from: data) else { return }
        items = loaded
    }
}
