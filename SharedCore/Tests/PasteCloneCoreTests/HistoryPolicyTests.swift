import XCTest
@testable import PasteCloneCore

final class HistoryPolicyTests: XCTestCase {
    func testPinnedDuplicateIsPreservedAndMovedToFront() {
        let pinned = HistoryRecord(contentHash: "same", isPinned: true)
        let other = HistoryRecord(contentHash: "other")
        let replacement = HistoryRecord(contentHash: "same")

        let result = HistoryPolicy.inserting(replacement, into: [other, pinned], limit: 10)

        XCTAssertEqual(result.map(\.id), [pinned.id, other.id])
    }

    func testPinnedRecordsSurviveHistoryLimit() {
        let pinned = HistoryRecord(contentHash: "pinned", isPinned: true)
        let ordinary = (0..<4).map { HistoryRecord(contentHash: "\($0)") }

        let result = HistoryPolicy.trimmed([pinned] + ordinary, limit: 2)

        XCTAssertEqual(result.map(\.id), [pinned.id, ordinary[0].id])
    }
}
