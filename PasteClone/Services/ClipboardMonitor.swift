import Foundation
import AppKit

class ClipboardMonitor {
    private var timer: Timer?
    private var lastChangeCount: Int = -1
    var onChange: ((ClipboardItem?) -> Void)?

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
        onChange?(read(pb))
    }

    private func makeItem(type: ClipboardItemType, textContent: String? = nil, rtfData: Data? = nil, imageData: Data? = nil, fileURLs: [URL]? = nil) -> ClipboardItem {
        let app = NSWorkspace.shared.frontmostApplication
        return ClipboardItem(type: type, textContent: textContent, rtfData: rtfData, imageData: imageData, fileURLs: fileURLs,
                             sourceAppName: app?.localizedName, sourceAppBundleID: app?.bundleIdentifier)
    }

    private func read(_ pb: NSPasteboard) -> ClipboardItem? {
        // Image
        if pb.availableType(from: [.tiff, .png]) != nil,
           let img = NSImage(pasteboard: pb),
           let tiff = img.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            return makeItem(type: .image, imageData: png)
        }
        // File URLs
        if let items = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !items.isEmpty {
            return makeItem(type: .file, fileURLs: items)
        }
        // RTF
        if let d = pb.data(forType: .rtf) {
            let plain = try? NSAttributedString(data: d,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil)
            return makeItem(type: .rtf, textContent: plain?.string, rtfData: d)
        }
        // RTFD
        if let d = pb.data(forType: .rtfd) {
            let plain = try? NSAttributedString(data: d,
                options: [.documentType: NSAttributedString.DocumentType.rtfd],
                documentAttributes: nil)
            return makeItem(type: .rtf, textContent: plain?.string, rtfData: d)
        }
        // Plain text
        if let txt = pb.string(forType: .string), !txt.isEmpty {
            return makeItem(type: .text, textContent: txt)
        }
        return nil
    }
}
