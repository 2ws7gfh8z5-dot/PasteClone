import SwiftUI
import AppKit

/// Anthropic 手绘风格主题 + 液态玻璃效果
enum PCTheme {
    static let modeKey = "appearanceMode"

    enum Mode: String, CaseIterable, Identifiable {
        case automatic, light, dark
        var id: String { rawValue }
        var title: String {
            switch self { case .automatic: return "跟随时间"; case .light: return "浅色"; case .dark: return "深色" }
        }
    }

    static func isDark(_ mode: Mode, date: Date = Date()) -> Bool {
        if mode == .dark { return true }
        if mode == .light { return false }
        let hour = Calendar.current.component(.hour, from: date)
        return !(7..<19).contains(hour)
    }

    static func isDark(date: Date = Date()) -> Bool {
        let mode = Mode(rawValue: UserDefaults.standard.string(forKey: modeKey) ?? "automatic") ?? .automatic
        return isDark(mode, date: date)
    }

    // 暖纸张背景，墨水轮廓，陶土/橙色重音 — Anthropic 手绘风格
    static var bg: Color { isDark() ? Color(red: 0.10, green: 0.09, blue: 0.08) : Color(red: 0.98, green: 0.96, blue: 0.92) }
    static var panel: Color { isDark() ? Color(red: 0.15, green: 0.14, blue: 0.13) : Color(red: 0.99, green: 0.98, blue: 0.95) }
    static var ink: Color { isDark() ? Color(red: 0.96, green: 0.93, blue: 0.88) : Color(red: 0.16, green: 0.14, blue: 0.12) }
    static var inkSoft: Color { isDark() ? Color(red: 0.72, green: 0.69, blue: 0.64) : Color(red: 0.32, green: 0.30, blue: 0.27) }
    static let accent = Color(red: 0.80, green: 0.41, blue: 0.20)
    static var accentSoft: Color { isDark() ? Color(red: 0.38, green: 0.22, blue: 0.14) : Color(red: 0.93, green: 0.76, blue: 0.58) }
    static var card: Color { isDark() ? Color(red: 0.20, green: 0.19, blue: 0.18) : Color(red: 1.0, green: 1.0, blue: 0.99) }
    static var divider: Color { isDark() ? Color(red: 0.30, green: 0.28, blue: 0.25) : Color(red: 0.88, green: 0.85, blue: 0.79) }
    
    // 液态玻璃效果（macOS 14+）
    static func glassmorphism() -> some View {
        ZStack {
            Color.clear
                .background(.ultraThinMaterial)
                .opacity(0.6)
        }
    }
}

/// Icon 生成工具 - 支持多尺寸导出
struct IconGenerator {
    static func generateAppIcon() -> NSImage? {
        let size = CGSize(width: 512, height: 512)
        return NSImage(size: size, flipped: false) { rect in
            // 背景：暖纸张色
            NSColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1).setFill()
            rect.fill()
            
            // 剪贴板主体：陶土色圆角矩形
            let clipboardRect = CGRect(x: 80, y: 100, width: 350, height: 320)
            let path = NSBezierPath(roundedRect: clipboardRect, xRadius: 30, yRadius: 30)
            NSColor(red: 0.93, green: 0.76, blue: 0.58, alpha: 1).setFill()
            path.fill()
            
            // 边框：深墨色
            NSColor(red: 0.16, green: 0.14, blue: 0.12, alpha: 1).setStroke()
            path.lineWidth = 6
            path.stroke()
            
            // 剪贴板夹：橙色
            let clipRect = CGRect(x: 200, y: 40, width: 110, height: 90)
            let clipPath = NSBezierPath(roundedRect: clipRect, xRadius: 12, yRadius: 12)
            NSColor(red: 0.80, green: 0.41, blue: 0.20, alpha: 1).setFill()
            clipPath.fill()
            NSColor(red: 0.16, green: 0.14, blue: 0.12, alpha: 1).setStroke()
            clipPath.lineWidth = 4
            clipPath.stroke()
            
            // 内部内容模拟：3条线
            let lineColor = NSColor(red: 0.16, green: 0.14, blue: 0.12, alpha: 0.6)
            lineColor.setStroke()
            
            var linePath = NSBezierPath()
            linePath.move(to: CGPoint(x: 110, y: 180))
            linePath.line(to: CGPoint(x: 400, y: 180))
            linePath.lineWidth = 8
            linePath.stroke()
            
            linePath = NSBezierPath()
            linePath.move(to: CGPoint(x: 110, y: 240))
            linePath.line(to: CGPoint(x: 400, y: 240))
            linePath.lineWidth = 8
            linePath.stroke()
            
            linePath = NSBezierPath()
            linePath.move(to: CGPoint(x: 110, y: 300))
            linePath.line(to: CGPoint(x: 380, y: 300))
            linePath.lineWidth = 8
            linePath.stroke()
            
            return true
        }
    }
    
    static func generateMenuBarIcon() -> NSImage? {
        let size = CGSize(width: 22, height: 22)
        return NSImage(size: size, flipped: false) { rect in
            // 简化剪贴板图标用于菜单栏
            let path = NSBezierPath(roundedRect: CGRect(x: 3, y: 2, width: 14, height: 16), xRadius: 2, yRadius: 2)
            NSColor(red: 0.80, green: 0.41, blue: 0.20, alpha: 1).setFill()
            path.fill()
            NSColor(red: 0.16, green: 0.14, blue: 0.12, alpha: 1).setStroke()
            path.lineWidth = 1
            path.stroke()
            return true
        }
    }
}


struct PCButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.94 : 1)
            .animation(reduceMotion ? nil : PCTheme.bezier(duration: 0.18), value: configuration.isPressed)
    }
}

extension PCTheme {
    static func bezier(duration: Double) -> Animation {
        .timingCurve(0.16, 1.0, 0.3, 1.0, duration: duration)
    }
}
