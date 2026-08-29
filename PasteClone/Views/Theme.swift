import SwiftUI
import AppKit

// MARK: - Accessibility Helpers

enum AccessibilitySettings {
    static var reduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }
    static var reduceTransparency: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
    }
    static var increaseContrast: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
    }
}

// MARK: - Design Tokens Namespace

enum PCTokens {
    // Color Palette — Warm paper / Ink / Terracotta accent (Anthropic hand-drawn style)
    enum Color {
        // Base neutrals
        static let bgDark        = SwiftUI.Color(red: 0.10, green: 0.09, blue: 0.08)
        static let bgLight       = SwiftUI.Color(red: 0.98, green: 0.96, blue: 0.92)
        static let panelDark     = SwiftUI.Color(red: 0.15, green: 0.14, blue: 0.13)
        static let panelLight    = SwiftUI.Color(red: 0.99, green: 0.98, blue: 0.95)
        static let cardDark      = SwiftUI.Color(red: 0.20, green: 0.19, blue: 0.18)
        static let cardLight     = SwiftUI.Color(red: 1.00, green: 1.00, blue: 0.99)
        static let dividerDark   = SwiftUI.Color(red: 0.30, green: 0.28, blue: 0.25)
        static let dividerLight  = SwiftUI.Color(red: 0.88, green: 0.85, blue: 0.79)
        
        // Ink (text)
        static let inkDark       = SwiftUI.Color(red: 0.96, green: 0.93, blue: 0.88)
        static let inkLight      = SwiftUI.Color(red: 0.16, green: 0.14, blue: 0.12)
        static let inkSoftDark   = SwiftUI.Color(red: 0.72, green: 0.69, blue: 0.64)
        static let inkSoftLight  = SwiftUI.Color(red: 0.32, green: 0.30, blue: 0.27)
        static let inkMutedDark  = SwiftUI.Color(red: 0.55, green: 0.52, blue: 0.48)
        static let inkMutedLight = SwiftUI.Color(red: 0.45, green: 0.42, blue: 0.38)
        
        // Accent — Terracotta / Clay
        static let accent        = SwiftUI.Color(red: 0.80, green: 0.41, blue: 0.20)
        static let accentSoftDark = SwiftUI.Color(red: 0.38, green: 0.22, blue: 0.14)
        static let accentSoftLight = SwiftUI.Color(red: 0.93, green: 0.76, blue: 0.58)
        static let accentGlow    = SwiftUI.Color(red: 0.90, green: 0.50, blue: 0.25).opacity(0.4)
        
        // Semantic
        static let success       = SwiftUI.Color(red: 0.25, green: 0.65, blue: 0.35)
        static let warning       = SwiftUI.Color(red: 0.90, green: 0.60, blue: 0.15)
        static let error         = SwiftUI.Color(red: 0.85, green: 0.30, blue: 0.25)
        static let focusRing     = SwiftUI.Color(red: 0.80, green: 0.41, blue: 0.20).opacity(0.6)
        
        // Glassmorphism
        static let glassDark     = SwiftUI.Color.white.opacity(0.06)
        static let glassLight    = SwiftUI.Color.black.opacity(0.04)
        static let glassBorderDark  = SwiftUI.Color.white.opacity(0.12)
        static let glassBorderLight = SwiftUI.Color.black.opacity(0.08)
    }
    
    // Typography Scale — Modular scale (1.25 ratio), baseline 13pt
    enum Font {
        // Display
        static let displayLarge  = SwiftUI.Font.system(size: 28, weight: .bold, design: .rounded)
        static let displayMedium = SwiftUI.Font.system(size: 22, weight: .semibold, design: .rounded)
        static let displaySmall  = SwiftUI.Font.system(size: 18, weight: .semibold, design: .rounded)
        
        // Heading
        static let headingLarge  = SwiftUI.Font.system(size: 16, weight: .semibold)
        static let headingMedium = SwiftUI.Font.system(size: 14, weight: .semibold)
        static let headingSmall  = SwiftUI.Font.system(size: 13, weight: .semibold)
        
        // Body
        static let bodyLarge     = SwiftUI.Font.system(size: 14, weight: .regular)
        static let bodyMedium    = SwiftUI.Font.system(size: 13, weight: .regular)
        static let bodySmall     = SwiftUI.Font.system(size: 12, weight: .regular)
        static let bodyXSmall    = SwiftUI.Font.system(size: 11, weight: .regular)
        
        // Label / UI
        static let labelLarge    = SwiftUI.Font.system(size: 13, weight: .medium)
        static let labelMedium   = SwiftUI.Font.system(size: 12, weight: .medium)
        static let labelSmall    = SwiftUI.Font.system(size: 11, weight: .medium)
        static let labelXSmall   = SwiftUI.Font.system(size: 10, weight: .medium)
        
        // Monospace
        static let monoMedium    = SwiftUI.Font.system(size: 13, weight: .medium, design: .monospaced)
        static let monoSmall     = SwiftUI.Font.system(size: 11, weight: .regular, design: .monospaced)
        static let monoXSmall    = SwiftUI.Font.system(size: 10, weight: .regular, design: .monospaced)
        
        // Line heights (as multipliers of font size)
        static let lineHeightTight  = 1.2
        static let lineHeightNormal = 1.5
        static let lineHeightRelaxed = 1.75
    }
    
    // Spacing Scale — 4pt base unit
    enum Spacing {
        static let space0   : CGFloat = 0
        static let space1   : CGFloat = 2
        static let space2   : CGFloat = 4
        static let space3   : CGFloat = 6
        static let space4   : CGFloat = 8
        static let space5   : CGFloat = 10
        static let space6   : CGFloat = 12
        static let space7   : CGFloat = 14
        static let space8   : CGFloat = 16
        static let space10  : CGFloat = 20
        static let space12  : CGFloat = 24
        static let space16  : CGFloat = 32
        static let space20  : CGFloat = 40
        static let space24  : CGFloat = 48
        static let space32  : CGFloat = 64
    }
    
    // Corner Radius Scale
    enum Radius {
        static let r1  : CGFloat = 4   // 小控件、标签
        static let r2  : CGFloat = 6   // 按钮、输入框
        static let r3  : CGFloat = 8   // 卡片、面板内区块
        static let r4  : CGFloat = 10  // 列表行
        static let r5  : CGFloat = 12  // 浮层、弹窗
        static let r6  : CGFloat = 16  // 主面板
        static let r7  : CGFloat = 22  // 全屏模态
        static let rPill : CGFloat = 999 // 胶囊/标签
    }
    
    // Shadow / Elevation
    struct ShadowToken {
        let color: SwiftUI.Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    enum Shadow {
        static let level1 = ShadowToken(color: SwiftUI.Color.black.opacity(0.08), radius: 2,  x: 0, y: 1)  // 微微浮起
        static let level2 = ShadowToken(color: SwiftUI.Color.black.opacity(0.12), radius: 6,  x: 0, y: 3)  // 卡片
        static let level3 = ShadowToken(color: SwiftUI.Color.black.opacity(0.16), radius: 16, x: 0, y: 8)  // 面板/弹窗
        static let level4 = ShadowToken(color: SwiftUI.Color.black.opacity(0.20), radius: 32, x: 0, y: 16) // 模态
        static let glow   = ShadowToken(color: Color.accent.opacity(0.35), radius: 20, x: 0, y: 0) // 重点高亮
    }
    
    // Animation Presets — Spring-first, respect reduceMotion
    enum Motion {
        // Spring presets (response, dampingFraction, blendDuration)
        static let springSwift   = (response: 0.28, damping: 0.82, blend: 0.0)   // 快速、干脆
        static let springSmooth  = (response: 0.38, damping: 0.78, blend: 0.0)   // 标准、丝滑
        static let springGentle  = (response: 0.48, damping: 0.80, blend: 0.0)   // 柔和、入场
        static let springBouncy  = (response: 0.42, damping: 0.68, blend: 0.0)   // 玩味、强调
        static let springStiff   = (response: 0.22, damping: 0.90, blend: 0.0)   // 微交互、按钮
        
        // Easing curves (fallback for non-spring)
        static let easeOutExpo   = Animation.timingCurve(0.16, 1.0, 0.3, 1.0, duration: 0.24)
        static let easeOutCubic  = Animation.timingCurve(0.33, 1.0, 0.68, 1.0, duration: 0.2)
        static let easeInOutCubic = Animation.timingCurve(0.65, 0.0, 0.35, 1.0, duration: 0.22)
        static let easeInCubic   = Animation.timingCurve(0.55, 0.055, 0.675, 0.19, duration: 0.18)
        
        // Duration constants
        static let durationInstant : Double = 0.0
        static let durationMicro   : Double = 0.08  // press feedback
        static let durationFast    : Double = 0.14  // hover, focus
        static let durationNormal  : Double = 0.22  // standard transitions
        static let durationSlow    : Double = 0.32  // panel enter/exit
        static let durationLeisure : Double = 0.44  // complex choreography
        
        // Stagger
        static let staggerBase : Double = 0.04  // per-item delay
        static let staggerMax  : Double = 0.24  // cap total stagger
    }
    
    // Z-index layers
    enum ZIndex {
        static let base       : Double = 0
        static let raised     : Double = 10
        static let dropdown   : Double = 100
        static let overlay    : Double = 200
        static let modal      : Double = 500
        static let toast      : Double = 1000
        static let tooltip    : Double = 1100
    }
}

// MARK: - Semantic Color Accessors (auto light/dark)

extension PCTokens.Color {
    static func bg(_ dark: Bool) -> Color { dark ? bgDark : bgLight }
    static func panel(_ dark: Bool) -> Color { dark ? panelDark : panelLight }
    static func card(_ dark: Bool) -> Color { dark ? cardDark : cardLight }
    static func divider(_ dark: Bool) -> Color { dark ? dividerDark : dividerLight }
    static func ink(_ dark: Bool) -> Color { dark ? inkDark : inkLight }
    static func inkSoft(_ dark: Bool) -> Color { dark ? inkSoftDark : inkSoftLight }
    static func inkMuted(_ dark: Bool) -> Color { dark ? inkMutedDark : inkMutedLight }
    static func accentSoft(_ dark: Bool) -> Color { dark ? accentSoftDark : accentSoftLight }
    static func glass(_ dark: Bool) -> Color { dark ? glassDark : glassLight }
    static func glassBorder(_ dark: Bool) -> Color { dark ? glassBorderDark : glassBorderLight }
}

// MARK: - Animation Factory

extension PCTokens.Motion {
    /// 统一入口：根据 reduceMotion 返回对应动画
    static func animation(_ preset: (response: Double, damping: Double, blend: Double), reduceMotion: Bool = AccessibilitySettings.reduceMotion) -> Animation {
        reduceMotion ? .linear(duration: 0.001) : .spring(response: preset.response, dampingFraction: preset.damping, blendDuration: preset.blend)
    }
    
    static func animation(_ curve: Animation, reduceMotion: Bool = AccessibilitySettings.reduceMotion) -> Animation {
        reduceMotion ? .linear(duration: 0.001) : curve
    }
    
    static func springSwift(reduceMotion: Bool = AccessibilitySettings.reduceMotion) -> Animation {
        animation(springSwift, reduceMotion: reduceMotion)
    }
    static func springSmooth(reduceMotion: Bool = AccessibilitySettings.reduceMotion) -> Animation {
        animation(springSmooth, reduceMotion: reduceMotion)
    }
    static func springGentle(reduceMotion: Bool = AccessibilitySettings.reduceMotion) -> Animation {
        animation(springGentle, reduceMotion: reduceMotion)
    }
    static func springBouncy(reduceMotion: Bool = AccessibilitySettings.reduceMotion) -> Animation {
        animation(springBouncy, reduceMotion: reduceMotion)
    }
    static func springStiff(reduceMotion: Bool = AccessibilitySettings.reduceMotion) -> Animation {
        animation(springStiff, reduceMotion: reduceMotion)
    }
    
    static func easeOutExpo(reduceMotion: Bool = AccessibilitySettings.reduceMotion) -> Animation {
        animation(easeOutExpo, reduceMotion: reduceMotion)
    }
    static func easeOutCubic(reduceMotion: Bool = AccessibilitySettings.reduceMotion) -> Animation {
        animation(easeOutCubic, reduceMotion: reduceMotion)
    }
    
    // 交错延迟计算
    static func staggerDelay(index: Int, base: Double = staggerBase, max: Double = staggerMax) -> Double {
        min(Double(index) * base, max)
    }
}

// MARK: - View Extensions for Shadows & Glass

extension View {
    func shadow(_ level: PCTokens.ShadowToken) -> some View {
        self.shadow(color: level.color, radius: level.radius, x: level.x, y: level.y)
    }
    
    func glassPanel(dark: Bool, cornerRadius: CGFloat = PCTokens.Radius.r6) -> some View {
        self.background(
            ZStack {
                PCTokens.Color.glass(dark)
                if !AccessibilitySettings.reduceTransparency {
                    Color.clear.background(.ultraThinMaterial).opacity(dark ? 0.6 : 0.5)
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(PCTokens.Color.glassBorder(dark), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
    
    func glassCard(dark: Bool, cornerRadius: CGFloat = PCTokens.Radius.r3) -> some View {
        self.background(PCTokens.Color.card(dark))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(PCTokens.Color.divider(dark), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Button Styles (Spring-based)

struct PCButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var prominent = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.94 : 1)
            .opacity(configuration.isPressed && !reduceMotion ? 0.9 : 1)
            .animation(reduceMotion ? nil : PCTokens.Motion.springStiff(reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

struct PCIconButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovering = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous)
                    .fill(hovering ? PCTokens.Color.accentSoft(true).opacity(0.55) : .clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.88 : (hovering && !reduceMotion ? 1.06 : 1))
            .onHover { hovering = $0 }
            .animation(reduceMotion ? nil : PCTokens.Motion.springSwift(reduceMotion: reduceMotion), value: hovering)
            .animation(reduceMotion ? nil : PCTokens.Motion.springStiff(reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

struct PCProminentButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovering = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PCTokens.Font.labelMedium)
            .padding(.horizontal, PCTokens.Spacing.space5)
            .padding(.vertical, PCTokens.Spacing.space3)
            .background(
                RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous)
                    .fill(PCTokens.Color.accent)
                    .shadow(hovering && !reduceMotion ? PCTokens.Shadow.glow : PCTokens.Shadow.level1)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : (hovering && !reduceMotion ? 1.02 : 1))
            .onHover { hovering = $0 }
            .animation(reduceMotion ? nil : PCTokens.Motion.springSwift(reduceMotion: reduceMotion), value: hovering)
            .animation(reduceMotion ? nil : PCTokens.Motion.springStiff(reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

// MARK: - Legacy Compatibility (PCTheme -> PCTokens)

/// 保持旧代码兼容的最小桥接，逐步迁移后可移除
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
    
    // 语义色彩桥接
    static var bg: Color { PCTokens.Color.bg(isDark()) }
    static var panel: Color { PCTokens.Color.panel(isDark()) }
    static var ink: Color { PCTokens.Color.ink(isDark()) }
    static var inkSoft: Color { PCTokens.Color.inkSoft(isDark()) }
    static let accent = PCTokens.Color.accent
    static var accentSoft: Color { PCTokens.Color.accentSoft(isDark()) }
    static var card: Color { PCTokens.Color.card(isDark()) }
    static var divider: Color { PCTokens.Color.divider(isDark()) }
    
    // 旧贝塞尔曲线（保留兼容）
    static func bezier(duration: Double) -> Animation {
        .timingCurve(0.16, 1.0, 0.3, 1.0, duration: duration)
    }
}

// MARK: - Icon Generator (unchanged)

struct IconGenerator {
    static func generateAppIcon() -> NSImage? {
        let size = CGSize(width: 512, height: 512)
        return NSImage(size: size, flipped: false) { rect in
            NSColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1).setFill()
            rect.fill()
            let clipboardRect = CGRect(x: 80, y: 100, width: 350, height: 320)
            let path = NSBezierPath(roundedRect: clipboardRect, xRadius: 30, yRadius: 30)
            NSColor(red: 0.93, green: 0.76, blue: 0.58, alpha: 1).setFill()
            path.fill()
            NSColor(red: 0.16, green: 0.14, blue: 0.12, alpha: 1).setStroke()
            path.lineWidth = 6
            path.stroke()
            let clipRect = CGRect(x: 200, y: 40, width: 110, height: 90)
            let clipPath = NSBezierPath(roundedRect: clipRect, xRadius: 12, yRadius: 12)
            NSColor(red: 0.80, green: 0.41, blue: 0.20, alpha: 1).setFill()
            clipPath.fill()
            NSColor(red: 0.16, green: 0.14, blue: 0.12, alpha: 1).setStroke()
            clipPath.lineWidth = 4
            clipPath.stroke()
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