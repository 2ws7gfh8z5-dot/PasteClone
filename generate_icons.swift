import AppKit

func generateIcons() {
    let iconsDir = "/Users/huaziyi/Desktop/pasteclone/PasteClone/Resources/Assets.xcassets/AppIcon.appiconset"
    try? FileManager.default.createDirectory(atPath: iconsDir, withIntermediateDirectories: true, attributes: nil)
    
    let sizes: [(Int, String)] = [
        (16, "16x16"),
        (32, "32x32"),
        (64, "64x64"),
        (128, "128x128"),
        (256, "256x256"),
        (512, "512x512"),
        (1024, "1024x1024")
    ]
    
    for (size, label) in sizes {
        let cgSize = CGSize(width: size, height: size)
        guard let image = generateIconWithSize(cgSize) else { continue }
        
        let pngData = image.tiffRepresentation
            .flatMap { NSBitmapImageRep(data: $0) }
            .flatMap { $0.representation(using: .png, properties: [:]) }
        
        let fileName = "\(label)@1x.png"
        let filePath = URL(fileURLWithPath: "\(iconsDir)/\(fileName)")
        try? pngData?.write(to: filePath)
        print("✓ Generated: \(fileName)")
    }
}

func generateIconWithSize(_ size: CGSize) -> NSImage? {
    return NSImage(size: size, flipped: false) { rect in
        NSColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1).setFill()
        rect.fill()
        
        let inset = size.width * 0.15
        let clipboardRect = CGRect(x: inset, y: inset * 1.2, width: size.width - inset * 2, height: size.height * 0.62)
        
        let path = NSBezierPath(roundedRect: clipboardRect, xRadius: size.width * 0.06, yRadius: size.width * 0.06)
        NSColor(red: 0.93, green: 0.76, blue: 0.58, alpha: 1).setFill()
        path.fill()
        
        NSColor(red: 0.16, green: 0.14, blue: 0.12, alpha: 1).setStroke()
        path.lineWidth = size.width * 0.012
        path.stroke()
        
        let clipWidth = size.width * 0.2
        let clipHeight = size.width * 0.17
        let clipRect = CGRect(x: (size.width - clipWidth) / 2, y: size.width * 0.08, width: clipWidth, height: clipHeight)
        let clipPath = NSBezierPath(roundedRect: clipRect, xRadius: size.width * 0.024, yRadius: size.width * 0.024)
        NSColor(red: 0.80, green: 0.41, blue: 0.20, alpha: 1).setFill()
        clipPath.fill()
        NSColor(red: 0.16, green: 0.14, blue: 0.12, alpha: 1).setStroke()
        clipPath.lineWidth = size.width * 0.008
        clipPath.stroke()
        
        return true
    }
}

generateIcons()
