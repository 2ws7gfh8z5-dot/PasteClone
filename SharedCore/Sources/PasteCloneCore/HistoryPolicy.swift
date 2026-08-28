import Foundation

/// Platform-neutral metadata shared by the macOS, Windows, and Linux clients.
public struct HistoryRecord: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let contentHash: String
    public var isPinned: Bool

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        contentHash: String,
        isPinned: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.contentHash = contentHash
        self.isPinned = isPinned
    }
}

/// Deterministic history rules that do not depend on AppKit, Win32, X11, or Wayland.
public enum HistoryPolicy {
    public static func inserting(_ item: HistoryRecord, into items: [HistoryRecord], limit: Int) -> [HistoryRecord] {
        var result = items
        if let pinned = result.first(where: { $0.contentHash == item.contentHash && $0.isPinned }) {
            result.removeAll { $0.contentHash == item.contentHash }
            result.insert(pinned, at: 0)
        } else {
            result.removeAll { $0.contentHash == item.contentHash }
            result.insert(item, at: 0)
        }
        return trimmed(result, limit: limit)
    }

    public static func trimmed(_ items: [HistoryRecord], limit: Int) -> [HistoryRecord] {
        let pinned = items.filter(\.isPinned)
        let available = max(0, limit - pinned.count)
        return pinned + items.filter { !$0.isPinned }.prefix(available)
    }
}
