import Foundation
import AppKit

class ClipboardMonitor {
    private var timer: Timer?
    private var lastChangeCount: Int = -1
    var onChange: ((Int, ClipboardItem?) -> Void)?

    func start() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() { timer?.invalidate(); timer = nil }

    private func poll() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount
        let sourceApp = NSWorkspace.shared.frontmostApplication
        guard !PrivacyRules.excludes(bundleIdentifier: sourceApp?.bundleIdentifier) else { return }
        onChange?(lastChangeCount, read(pb, sourceApp: sourceApp))
    }

    private func makeItem(type: ClipboardItemType, sourceApp: NSRunningApplication?, textContent: String? = nil, rtfData: Data? = nil, richTextType: String? = nil, imageData: Data? = nil, fileURLs: [URL]? = nil, colorData: Data? = nil) -> ClipboardItem {
        ClipboardItem(type: type, textContent: textContent, rtfData: rtfData, richTextType: richTextType, imageData: imageData,
                      fileURLs: fileURLs, colorData: colorData, sourceAppName: sourceApp?.localizedName,
                      sourceAppBundleID: sourceApp?.bundleIdentifier)
    }

    private func read(_ pb: NSPasteboard, sourceApp: NSRunningApplication?) -> ClipboardItem? {
        // Image
        if pb.availableType(from: [.tiff, .png]) != nil,
           let img = NSImage(pasteboard: pb),
           let tiff = img.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            return makeItem(type: .image, sourceApp: sourceApp, imageData: png)
        }
        // File URLs
        if let items = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !items.isEmpty {
            return makeItem(type: .file, sourceApp: sourceApp, fileURLs: items)
        }
        // RTF
        if let d = pb.data(forType: .rtf) {
            let plain = try? NSAttributedString(data: d,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil)
            return makeItem(type: .rtf, sourceApp: sourceApp, textContent: plain?.string, rtfData: d, richTextType: NSPasteboard.PasteboardType.rtf.rawValue)
        }
        // RTFD
        if let d = pb.data(forType: .rtfd) {
            let plain = try? NSAttributedString(data: d,
                options: [.documentType: NSAttributedString.DocumentType.rtfd],
                documentAttributes: nil)
            return makeItem(type: .rtf, sourceApp: sourceApp, textContent: plain?.string, rtfData: d, richTextType: NSPasteboard.PasteboardType.rtfd.rawValue)
        }
        // Native macOS color objects
        if let color = (pb.readObjects(forClasses: [NSColor.self]) as? [NSColor])?.first,
           let data = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true) {
            return makeItem(type: .color, sourceApp: sourceApp, colorData: data)
        }
        // Plain text
        if let txt = pb.string(forType: .string), !txt.isEmpty {
            return makeItem(type: .text, sourceApp: sourceApp, textContent: txt)
        }
        return nil
    }
}
