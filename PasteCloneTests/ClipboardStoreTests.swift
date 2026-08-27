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
}
