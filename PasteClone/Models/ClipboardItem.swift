import Foundation
import AppKit

enum ClipboardItemType: String, Codable {
    case text, image, file, rtf, color, unknown
}

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let type: ClipboardItemType
    var isPinned: Bool
    var collectionName: String?
    var textContent: String?
    var rtfData: Data?
    var imageData: Data?
    var fileURLs: [URL]?
    var colorData: Data?
    var sourceAppName: String?
    var sourceAppBundleID: String?

    init(id: UUID = UUID(), timestamp: Date = Date(), type: ClipboardItemType,
         textContent: String? = nil, rtfData: Data? = nil, imageData: Data? = nil,
         fileURLs: [URL]? = nil, colorData: Data? = nil,
         sourceAppName: String? = nil, sourceAppBundleID: String? = nil,
         isPinned: Bool = false, collectionName: String? = nil) {
        self.id = id; self.timestamp = timestamp; self.type = type
        self.textContent = textContent; self.rtfData = rtfData
        self.imageData = imageData; self.fileURLs = fileURLs
        self.colorData = colorData; self.sourceAppName = sourceAppName
        self.sourceAppBundleID = sourceAppBundleID
        self.isPinned = isPinned; self.collectionName = collectionName
    }

    var displayText: String {
        switch type {
        case .text: return textContent ?? ""
        case .image: return "[图片]"
        case .file: return fileURLs?.map(\.lastPathComponent).joined(separator: ", ") ?? "[文件]"
        case .rtf:
            if let d = rtfData,
               let s = try? NSAttributedString(data: d,
                   options: [.documentType: NSAttributedString.DocumentType.rtf],
                   documentAttributes: nil) { return s.string }
            return "[富文本]"
        case .color: return "[颜色]"
        case .unknown: return "[未知]"
        }
    }

    var previewImage: NSImage? {
        guard type == .image, let d = imageData else { return nil }
        return NSImage(data: d)
    }

    var contentHash: String {
        switch type {
        case .text: return textContent ?? ""
        case .rtf: return rtfData?.base64EncodedString() ?? ""
        case .image: return imageData?.prefix(64).base64EncodedString() ?? ""
        case .file: return fileURLs?.map(\.absoluteString).joined() ?? ""
        default: return id.uuidString
        }
    }
}
