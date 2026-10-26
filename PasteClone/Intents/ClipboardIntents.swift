import AppIntents
import AppKit

enum ClipboardIntentError: Error, CustomLocalizedStringResourceConvertible {
    case appNotRunning
    case indexOutOfRange

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .appNotRunning: return "Just Paste 未运行"
        case .indexOutOfRange: return "没有该位置的条目"
        }
    }
}

@MainActor
private func currentStore() throws -> ClipboardStore {
    guard let store = (NSApp.delegate as? AppDelegate)?.store else { throw ClipboardIntentError.appNotRunning }
    return store
}

@MainActor
private func orderedItems(_ store: ClipboardStore) -> [ClipboardItem] {
    store.items.filter(\.isPinned) + store.items.filter { !$0.isPinned }
}

private func plainText(of item: ClipboardItem) -> String {
    item.type == .text || item.type == .rtf ? item.displayText : ""
}

struct CreateItemIntent: AppIntent {
    static var title: LocalizedStringResource = "添加到剪贴板历史"
    static var description = IntentDescription("把一段文本加入 Just Paste 历史记录。")
    static var openAppWhenRun = false

    @Parameter(title: "文本")
    var text: String

    @MainActor
    func perform() async throws -> some IntentResult {
        try currentStore().addText(text)
        return .result()
    }
}

struct GetLatestItemIntent: AppIntent {
    static var title: LocalizedStringResource = "获取最近一条剪贴板文本"
    static var description = IntentDescription("返回 Just Paste 历史中最近一条的纯文本内容。")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let store = try currentStore()
        return .result(value: orderedItems(store).first.map(plainText(of:)) ?? "")
    }
}

struct GetItemAtIndexIntent: AppIntent {
    static var title: LocalizedStringResource = "获取指定位置的剪贴板文本"
    static var description = IntentDescription("按序号（从 1 开始，固定条目优先）返回一条历史的纯文本内容。")
    static var openAppWhenRun = false

    @Parameter(title: "序号", default: 1)
    var index: Int

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let items = orderedItems(try currentStore())
        guard items.indices.contains(index - 1) else { throw ClipboardIntentError.indexOutOfRange }
        return .result(value: plainText(of: items[index - 1]))
    }
}

struct JustPasteShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: CreateItemIntent(),
                    phrases: ["用 \(.applicationName) 添加文本"],
                    shortTitle: "添加文本",
                    systemImageName: "plus.square.on.square")
        AppShortcut(intent: GetLatestItemIntent(),
                    phrases: ["用 \(.applicationName) 获取最近一条"],
                    shortTitle: "最近一条",
                    systemImageName: "doc.on.clipboard")
    }
}
