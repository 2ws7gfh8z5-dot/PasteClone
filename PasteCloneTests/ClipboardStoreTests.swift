import XCTest
import Carbon.HIToolbox
@testable import PasteClone

final class ClipboardStoreTests: XCTestCase {
    func testHistoryLimitIncludesPinnedItems() {
        let pinned = (0..<2).map { _ in ClipboardItem(type: .text, textContent: UUID().uuidString, isPinned: true) }
        let regular = (0..<4).map { _ in ClipboardItem(type: .text, textContent: UUID().uuidString) }
        let result = ClipboardStore.trimmed(pinned + regular, limit: 3)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.filter(\.isPinned).count, 2)
    }

    func testHotkeyKeyCodeUsesPhysicalKeyNames() {
        XCTAssertEqual(keyCodeToString(UInt32(kVK_ANSI_V)), "V")
        XCTAssertEqual(keyCodeToString(UInt32(kVK_Space)), "Space")
    }

    func testPinnedItemsAreNeverDiscarded() {
        let pinned = (0..<3).map { _ in ClipboardItem(type: .text, textContent: UUID().uuidString, isPinned: true) }
        XCTAssertEqual(ClipboardStore.trimmed(pinned, limit: 2).count, 3)
    }

    func testCorruptHistoryRecoversValidItems() throws {
        let good = ClipboardItem(type: .text, textContent: "hello")
        let goodObj = try JSONSerialization.jsonObject(with: JSONEncoder().encode(good))
        let data = try JSONSerialization.data(withJSONObject: [goodObj, ["broken": true], 42] as [Any])
        let recovered = ClipboardStore.recover(from: data)
        XCTAssertEqual(recovered.map(\.textContent), ["hello"])
    }

    func testOrderedCollectionsKeepsRegisteredOrderThenAlphabetical() {
        let result = ClipboardStore.orderedCollections(
            present: ["工作", "代码", "临时"],
            order: ["代码", "工作"]
        )
        XCTAssertEqual(result, ["代码", "工作", "临时"])
    }

    func testSuggestPrefersPinnedAndTargetApp() {
        let fresh = ClipboardItem(type: .text, textContent: "fresh")
        let pinned = ClipboardItem(type: .text, textContent: "pinned", isPinned: true)
        let matched = ClipboardItem(type: .text, textContent: "matched", sourceAppBundleID: "com.x")
        // items[0] 是最新复制（已在剪贴板上），永不建议
        XCTAssertEqual(ClipboardStore.suggest(items: [fresh, matched], targetBundleID: "com.x")?.textContent, "matched")
        XCTAssertEqual(ClipboardStore.suggest(items: [fresh, pinned], targetBundleID: nil)?.textContent, "pinned")
        XCTAssertNil(ClipboardStore.suggest(items: [fresh, matched], targetBundleID: "com.other"))
        XCTAssertNil(ClipboardStore.suggest(items: [fresh], targetBundleID: nil))
    }
}
