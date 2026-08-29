import SwiftUI
import ServiceManagement
import AppKit

struct PreferencesView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("maxItems") private var maxItems = 1000
    @AppStorage("hotkeyEnabled") private var hotkeyEnabled = true
    @AppStorage("hotkeyPreset") private var hotkeyPreset = HotkeyPreset.shiftCommandV.rawValue
    @AppStorage("customHotkeyKeyCode") private var customKeyCode = 0
    @AppStorage("customHotkeyModifiers") private var customModifiers = 0
    @AppStorage("donationURL") private var donationURL = "https://github.com/2ws7gfh8z5-dot/PasteClone#支持开发"
    @AppStorage(PCTheme.modeKey) private var appearanceMode = PCTheme.Mode.automatic.rawValue
    @State private var clock = Date()
    @State private var excludedBundleIDs = PrivacyRules.excludedBundleIDs
    @State private var privacyStatus = ""
    @State private var showPrivacyDetail = false
    @State private var activeSection: SectionID? = .general
    @Namespace private var sectionNamespace
    
    private var dark: Bool { PCTheme.isDark() }
    
    enum SectionID: String, CaseIterable, Identifiable {
        case general = "通用"
        case hotkeys = "快捷键"
        case appearance = "外观"
        case privacy = "隐私"
        case about = "关于"
        
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .hotkeys: return "command"
            case .appearance: return "paintbrush"
            case .privacy: return "lock.shield"
            case .about: return "info.circle"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PCTokens.Spacing.space6) {
                // Header
                header
                
                // Sections
                VStack(spacing: PCTokens.Spacing.space4) {
                    ForEach(SectionID.allCases) { section in
                        SectionCard(
                            id: section,
                            isActive: activeSection == section,
                            namespace: sectionNamespace,
                            dark: dark
                        ) { sectionContent(for: section) }
                        .onTapGesture {
                            withAnimation(PCTokens.Motion.springSmooth(reduceMotion: AccessibilitySettings.reduceMotion)) {
                                activeSection = activeSection == section ? nil : section
                            }
                        }
                    }
                }
                .padding(.horizontal, PCTokens.Spacing.space5)
                
                Spacer(minLength: PCTokens.Spacing.space8)
            }
            .padding(.vertical, PCTokens.Spacing.space6)
        }
        .frame(width: 560, height: 700)
        .background(
            ZStack {
                PCTokens.Color.glass(dark)
                if !AccessibilitySettings.reduceTransparency {
                    Color.clear.background(.ultraThinMaterial).opacity(dark ? 0.65 : 0.55)
                }
            }
        )
        .preferredColorScheme(dark ? .dark : .light)
        .onAppear { launchAtLogin = SMAppService.mainApp.status == .enabled }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { clock = $0 }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(alignment: .leading, spacing: PCTokens.Spacing.space3) {
            HStack(spacing: PCTokens.Spacing.space3) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(PCTokens.Color.accent)
                    .symbolRenderingMode(.hierarchical)
                
                VStack(alignment: .leading, spacing: PCTokens.Spacing.space0) {
                    Text("偏好设置")
                        .font(PCTokens.Font.displaySmall)
                        .foregroundColor(PCTokens.Color.ink(dark))
                    
                    Text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")")
                        .font(PCTokens.Font.monoSmall)
                        .foregroundColor(PCTokens.Color.inkMuted(dark))
                }
                
                Spacer()
            }
            .padding(.horizontal, PCTokens.Spacing.space5)
            .padding(.top, PCTokens.Spacing.space2)
        }
    }
    
    // MARK: - Section Content
    
    @ViewBuilder
    private func sectionContent(for section: SectionID) -> some View {
        switch section {
        case .general:
            generalSection
        case .hotkeys:
            hotkeysSection
        case .appearance:
            appearanceSection
        case .privacy:
            privacySection
        case .about:
            aboutSection
        }
    }
    
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: PCTokens.Spacing.space5) {
            // Launch at Login
            SettingsRow(
                icon: "power",
                title: "开机启动",
                subtitle: "登录时自动在菜单栏运行",
                dark: dark
            ) {
                Toggle("", isOn: $launchAtLogin)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .onChange(of: launchAtLogin) { _, enabled in
                        do {
                            if enabled { try SMAppService.mainApp.register() }
                            else { try SMAppService.mainApp.unregister() }
                        } catch {
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
            }
            
            Divider().background(PCTokens.Color.divider(dark))
            
            // Max Items
            SettingsRow(
                icon: "tray.full",
                title: "保留条目数",
                subtitle: "超出后自动移除最旧的非固定条目",
                dark: dark
            ) {
                Picker("", selection: $maxItems) {
                    Text("100").tag(100)
                    Text("500").tag(500)
                    Text("1000").tag(1000)
                    Text("2000").tag(2000)
                }
                .pickerStyle(.segmented)
                .frame(width: 260)
                .labelsHidden()
            }
        }
    }
    
    private var hotkeysSection: some View {
        VStack(alignment: .leading, spacing: PCTokens.Spacing.space5) {
            // Hotkey Enabled
            SettingsRow(
                icon: "bolt",
                title: "全局热键",
                subtitle: "启用后可在任意应用中唤起面板",
                dark: dark
            ) {
                Toggle("", isOn: $hotkeyEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .onChange(of: hotkeyEnabled) { _, enabled in
                        if enabled { HotkeyManager.shared.register() }
                        else { HotkeyManager.shared.unregister() }
                    }
            }
            
            if hotkeyEnabled {
                Divider().background(PCTokens.Color.divider(dark))
                
                // Preset Picker
                SettingsRow(
                    icon: "keyboard",
                    title: "快捷键预设",
                    subtitle: "选择常用组合或自定义",
                    dark: dark
                ) {
                    Picker("", selection: $hotkeyPreset) {
                        Text("⇧⌘V").tag(HotkeyPreset.shiftCommandV.rawValue)
                        Text("⌥Space").tag(HotkeyPreset.optionSpace.rawValue)
                        Text("⌃⌥V").tag(HotkeyPreset.controlOptionV.rawValue)
                        Divider()
                        Text("自定义…").tag(HotkeyPreset.custom.rawValue)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 260)
                    .labelsHidden()
                    .onChange(of: hotkeyPreset) { _ in
                        HotkeyManager.shared.register()
                    }
                }
                
                // Custom Hotkey Editor
                if hotkeyPreset == HotkeyPreset.custom.rawValue {
                    VStack(alignment: .leading, spacing: PCTokens.Spacing.space3) {
                        HStack {
                            Image(systemName: "pencil.and.outline")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(PCTokens.Color.accent)
                                .frame(width: 24)
                            
                            HotkeyDisplay(
                                keyCode: UInt32(customKeyCode),
                                modifiers: UInt32(customModifiers)
                            ) { code, mods in
                                customKeyCode = Int(code)
                                customModifiers = Int(mods)
                                HotkeyPreset.saveCustomHotkey(keyCode: code, modifiers: mods)
                                HotkeyManager.shared.register()
                            }
                            .frame(height: 44)
                        }
                        .padding(PCTokens.Spacing.space4)
                        .background(
                            RoundedRectangle(cornerRadius: PCTokens.Radius.r3, style: .continuous)
                                .fill(PCTokens.Color.accentSoft(dark).opacity(0.15))
                                .stroke(PCTokens.Color.accent.opacity(0.3), lineWidth: 1)
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        
                        Text("点击输入框后按下想要的组合键")
                            .font(PCTokens.Font.bodyXSmall)
                            .foregroundColor(PCTokens.Color.inkMuted(dark))
                            .padding(.leading, PCTokens.Spacing.space7)
                    }
                    .animation(PCTokens.Motion.springSmooth(reduceMotion: AccessibilitySettings.reduceMotion), value: hotkeyPreset)
                }
            }
        }
    }
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: PCTokens.Spacing.space5) {
            SettingsRow(
                icon: "circle.lefthalf.filled",
                title: "外观模式",
                subtitle: "跟随系统时间：07:00–18:59 浅色，其余深色",
                dark: dark
            ) {
                Picker("", selection: $appearanceMode) {
                    ForEach(PCTheme.Mode.allCases) { mode in
                        Label(mode.title, systemImage: modeIcon(mode))
                            .tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 320)
                .labelsHidden()
            }
            
            Divider().background(PCTokens.Color.divider(dark))
            
            // Color preview cards
            VStack(alignment: .leading, spacing: PCTokens.Spacing.space3) {
                Text("配色预览")
                    .font(PCTokens.Font.labelSmall)
                    .foregroundColor(PCTokens.Color.inkMuted(dark))
                    .padding(.leading, PCTokens.Spacing.space7)
                
                HStack(spacing: PCTokens.Spacing.space3) {
                    ColorSwatch(name: "背景", color: PCTokens.Color.bg(dark))
                    ColorSwatch(name: "面板", color: PCTokens.Color.panel(dark))
                    ColorSwatch(name: "卡片", color: PCTokens.Color.card(dark))
                    ColorSwatch(name: "主色", color: PCTokens.Color.accent)
                    ColorSwatch(name: "重点", color: PCTokens.Color.ink(dark))
                }
                .padding(.leading, PCTokens.Spacing.space7)
            }
        }
    }
    
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: PCTokens.Spacing.space5) {
            SettingsRow(
                icon: "hand.raised",
                title: "隐私规则",
                subtitle: "排除的 App 复制内容不会被记录（如密码管理器）",
                dark: dark
            ) {
                EmptyView()
            }
            
            VStack(alignment: .leading, spacing: PCTokens.Spacing.space3) {
                if excludedBundleIDs.isEmpty {
                    Text("尚未排除任何 App。可在密码管理器等敏感应用位于前台时点击下方按钮添加。")
                        .font(PCTokens.Font.bodySmall)
                        .foregroundColor(PCTokens.Color.inkMuted(dark))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, PCTokens.Spacing.space7)
                } else {
                    ForEach(excludedBundleIDs.sorted(), id: \.self) { bundleID in
                        HStack(spacing: PCTokens.Spacing.space3) {
                            Image(systemName: "app.badge.checkmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(PCTokens.Color.success)
                                .frame(width: 24)
                            
                            Text(bundleID)
                                .font(PCTokens.Font.monoSmall)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Spacer()
                            
                            Button {
                                PrivacyRules.remove(bundleID)
                                excludedBundleIDs = PrivacyRules.excludedBundleIDs
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(PCTokens.Color.inkMuted(dark))
                            }
                            .buttonStyle(.plain)
                            .help("停止忽略 \(bundleID)")
                        }
                        .padding(.horizontal, PCTokens.Spacing.space4)
                        .padding(.vertical, PCTokens.Spacing.space2)
                        .background(
                            RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous)
                                .fill(PCTokens.Color.card(dark))
                                .stroke(PCTokens.Color.divider(dark), lineWidth: 1)
                        )
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                }
                
                // Add excluded app button
                Menu {
                    ForEach(runningApps, id: \.bundleIdentifier) { app in
                        Button(app.localizedName ?? app.bundleIdentifier ?? "未知 App") {
                            if let bundleID = app.bundleIdentifier {
                                PrivacyRules.add(bundleID)
                                excludedBundleIDs = PrivacyRules.excludedBundleIDs
                            }
                        }
                    }
                } label: {
                    Label("添加前台 App 到排除列表", systemImage: "plus.circle")
                        .font(PCTokens.Font.labelMedium)
                        .foregroundColor(PCTokens.Color.accent)
                        .padding(.horizontal, PCTokens.Spacing.space4)
                        .padding(.vertical, PCTokens.Spacing.space2)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous)
                                .fill(PCTokens.Color.accentSoft(dark).opacity(0.15))
                                .stroke(PCTokens.Color.accent.opacity(0.3), lineWidth: 1)
                        )
                }
                .menuStyle(.borderlessButton)
                .padding(.leading, PCTokens.Spacing.space7)
                
                // Accessibility check
                HStack(spacing: PCTokens.Spacing.space3) {
                    Button("检查粘贴权限") { checkAccessibility() }
                        .buttonStyle(.plain)
                        .foregroundColor(PCTokens.Color.accent)
                        .font(PCTokens.Font.labelMedium)
                        .padding(.horizontal, PCTokens.Spacing.space4)
                        .padding(.vertical, PCTokens.Spacing.space2)
                        .background(
                            RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous)
                                .fill(PCTokens.Color.accentSoft(dark).opacity(0.15))
                        )
                    
                    if !privacyStatus.isEmpty {
                        HStack(spacing: PCTokens.Spacing.space1) {
                            Image(systemName: privacyStatus.contains("已授权") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(privacyStatus.contains("已授权") ? PCTokens.Color.success : PCTokens.Color.warning)
                            Text(privacyStatus)
                                .font(PCTokens.Font.bodySmall)
                                .foregroundColor(PCTokens.Color.inkMuted(dark))
                        }
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                }
                .padding(.leading, PCTokens.Spacing.space7)
            }
            .animation(PCTokens.Motion.springSmooth(reduceMotion: AccessibilitySettings.reduceMotion), value: excludedBundleIDs)
            .animation(PCTokens.Motion.springSmooth(reduceMotion: AccessibilitySettings.reduceMotion), value: privacyStatus)
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: PCTokens.Spacing.space5) {
            // Changelog
            VStack(alignment: .leading, spacing: PCTokens.Spacing.space3) {
                HStack {
                    Text("更新日志")
                        .font(PCTokens.Font.headingSmall)
                        .foregroundColor(PCTokens.Color.ink(dark))
                    
                    Spacer()
                    
                    Text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")")
                        .font(PCTokens.Font.monoSmall)
                        .foregroundColor(PCTokens.Color.inkMuted(dark))
                }
                
                VStack(alignment: .leading, spacing: PCTokens.Spacing.space2) {
                    ChangelogItem(version: "1.5.0", title: "丝滑动效与排版系统重构", items: [
                        "全新设计令牌体系：Typography/Spacing/Motion/Color/Shadow/Radius 统一规范",
                        "弹簧动画体系：springSwift/smooth/gentle/bouncy/stiff 五档预设",
                        "列表 Stagger 入场、弹簧 Hover/Press/Focus、按钮滑入/缩放微交互",
                        "面板弹簧弹入/出、搜索聚焦光环、空状态脉冲插画、键盘焦点环",
                        "排版升级：模块化字号阶梯、行高系统、语义色彩、8pt 间距网格",
                        "偏好设置：分组折叠动画、表单聚焦态、模式切换淡变、配色预览卡",
                        "无障碍完善：reduceMotion/reduceTransparency/increaseContrast 全链路支持"
                    ], dark: dark)
                }
            }
            
            Divider().background(PCTokens.Color.divider(dark))
            
            // Donation
            VStack(alignment: .leading, spacing: PCTokens.Spacing.space3) {
                Text("支持开发")
                    .font(PCTokens.Font.headingSmall)
                    .foregroundColor(PCTokens.Color.ink(dark))
                
                HStack(spacing: PCTokens.Spacing.space3) {
                    TextField("捐款链接", text: $donationURL)
                        .textFieldStyle(.plain)
                        .font(PCTokens.Font.bodySmall)
                        .padding(.horizontal, PCTokens.Spacing.space3)
                        .padding(.vertical, PCTokens.Spacing.space2)
                        .background(
                            RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous)
                                .fill(PCTokens.Color.card(dark))
                                .stroke(PCTokens.Color.divider(dark), lineWidth: 1)
                        )
                    
                    Button(action: {
                        NSWorkspace.shared.open(URL(string: donationURL) ?? URL(string: "https://github.com/2ws7gfh8z5-dot/PasteClone")!)
                    }) {
                        Label("打开", systemImage: "arrow.up.right")
                            .font(PCTokens.Font.labelMedium)
                    }
                    .buttonStyle(PCProminentButtonStyle())
                }
            }
            
            // Links
            HStack(spacing: PCTokens.Spacing.space4) {
                LinkButton(title: "GitHub", url: "https://github.com/2ws7gfh8z5-dot/PasteClone", dark: dark)
                LinkButton(title: "问题反馈", url: "https://github.com/2ws7gfh8z5-dot/PasteClone/issues", dark: dark)
                LinkButton(title: "隐私政策", url: "https://github.com/2ws7gfh8z5-dot/PasteClone#隐私政策", dark: dark)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var runningApps: [NSRunningApplication] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != Bundle.main.bundleIdentifier }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }
    
    private func modeIcon(_ mode: PCTheme.Mode) -> String {
        switch mode {
        case .automatic: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
    
    private func checkAccessibility() {
        let prompt = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        privacyStatus = AXIsProcessTrustedWithOptions(prompt) ? "已授权，可一键粘贴" : "请在系统设置中允许辅助功能权限"
    }
}

// MARK: - Reusable Components

private struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let dark: Bool
    let content: Content
    
    init(icon: String, title: String, subtitle: String, dark: Bool, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.dark = dark
        self.content = content()
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: PCTokens.Spacing.space4) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(PCTokens.Color.accent)
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: PCTokens.Spacing.space1) {
                Text(title)
                    .font(PCTokens.Font.headingSmall)
                    .foregroundColor(PCTokens.Color.ink(dark))
                
                Text(subtitle)
                    .font(PCTokens.Font.bodyXSmall)
                    .foregroundColor(PCTokens.Color.inkMuted(dark))
                    .fixedSize(horizontal: false, vertical: true)
                
                content
                    .padding(.top, PCTokens.Spacing.space1)
            }
            
            Spacer(minLength: PCTokens.Spacing.space4)
        }
    }
}

private struct SectionCard<Content: View>: View {
    let id: PreferencesView.SectionID
    let isActive: Bool
    let namespace: Namespace.ID
    let dark: Bool
    let content: Content
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hover = false
    
    init(id: PreferencesView.SectionID, isActive: Bool, namespace: Namespace.ID, dark: Bool, @ViewBuilder content: () -> Content) {
        self.id = id
        self.isActive = isActive
        self.namespace = namespace
        self.dark = dark
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: PCTokens.Spacing.space3) {
                Image(systemName: id.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isActive ? PCTokens.Color.accent : PCTokens.Color.inkSoft(dark))
                    .symbolRenderingMode(.hierarchical)
                    .matchedGeometryEffect(id: "icon_\(id.rawValue)", in: namespace, properties: .position)
                
                Text(id.rawValue)
                    .font(PCTokens.Font.headingMedium)
                    .foregroundColor(PCTokens.Color.ink(dark))
                    .matchedGeometryEffect(id: "title_\(id.rawValue)", in: namespace, properties: .position)
                
                Spacer()
                
                Image(systemName: isActive ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(PCTokens.Color.inkMuted(dark))
                    .rotationEffect(.degrees(isActive ? 0 : 0))
                    .animation(PCTokens.Motion.springSwift(reduceMotion: reduceMotion), value: isActive)
            }
            .padding(.horizontal, PCTokens.Spacing.space4)
            .padding(.vertical, PCTokens.Spacing.space3)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: PCTokens.Radius.r3, style: .continuous)
                    .fill(hover ? PCTokens.Color.card(dark).opacity(0.6) : .clear)
            )
            .onHover { hover = $0 }
            .animation(PCTokens.Motion.springSwift(reduceMotion: reduceMotion), value: hover)
            
            // Content
            if isActive {
                VStack(alignment: .leading, spacing: PCTokens.Spacing.space4) {
                    content
                }
                .padding(.horizontal, PCTokens.Spacing.space4)
                .padding(.bottom, PCTokens.Spacing.space4)
                .padding(.top, PCTokens.Spacing.space2)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.98, anchor: .top)),
                        removal: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.98, anchor: .top))
                    )
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: PCTokens.Radius.r4, style: .continuous)
                .fill(PCTokens.Color.card(dark).opacity(isActive ? 1 : 0.5))
                .stroke(PCTokens.Color.divider(dark).opacity(isActive ? 0.5 : 0.3), lineWidth: isActive ? 1.5 : 1)
                .matchedGeometryEffect(id: "bg_\(id.rawValue)", in: namespace, properties: .frame)
        )
        .shadow(isActive ? PCTokens.Shadow.level2 : PCTokens.Shadow.level1)
        .animation(PCTokens.Motion.springSmooth(reduceMotion: reduceMotion), value: isActive)
    }
}

private struct ColorSwatch: View {
    let name: String
    let color: Color
    let dark: Bool = PCTheme.isDark()
    
    var body: some View {
        VStack(spacing: PCTokens.Spacing.space1) {
            RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous)
                .fill(color)
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous)
                        .stroke(PCTokens.Color.divider(dark), lineWidth: 1)
                )
            
            Text(name)
                .font(PCTokens.Font.labelXSmall)
                .foregroundColor(PCTokens.Color.inkMuted(dark))
        }
    }
}

private struct ChangelogItem: View {
    let version: String
    let title: String
    let items: [String]
    let dark: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: PCTokens.Spacing.space3) {
            HStack(spacing: PCTokens.Spacing.space2) {
                Text("v\(version)")
                    .font(PCTokens.Font.monoMedium)
                    .foregroundColor(PCTokens.Color.accent)
                    .padding(.horizontal, PCTokens.Spacing.space2)
                    .padding(.vertical, PCTokens.Spacing.space0)
                    .background(
                        Capsule().fill(PCTokens.Color.accentSoft(dark).opacity(0.3))
                    )
                
                Text(title)
                    .font(PCTokens.Font.headingSmall)
                    .foregroundColor(PCTokens.Color.ink(dark))
            }
            
            VStack(alignment: .leading, spacing: PCTokens.Spacing.space1) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: PCTokens.Spacing.space2) {
                        Circle()
                            .fill(PCTokens.Color.accent)
                            .frame(width: 4, height: 4)
                            .padding(.top, 6)
                        
                        Text(item)
                            .font(PCTokens.Font.bodySmall)
                            .foregroundColor(PCTokens.Color.inkSoft(dark))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.leading, PCTokens.Spacing.space1)
        }
        .padding(PCTokens.Spacing.space4)
        .background(
            RoundedRectangle(cornerRadius: PCTokens.Radius.r3, style: .continuous)
                .fill(PCTokens.Color.card(dark))
                .stroke(PCTokens.Color.divider(dark), lineWidth: 1)
        )
    }
}

private struct LinkButton: View {
    let title: String
    let url: String
    let dark: Bool
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hover = false
    
    var body: some View {
        Button(action: { NSWorkspace.shared.open(URL(string: url)!) }) {
            Text(title)
                .font(PCTokens.Font.labelMedium)
                .foregroundColor(hover ? PCTokens.Color.accent : PCTokens.Color.inkSoft(dark))
                .padding(.horizontal, PCTokens.Spacing.space4)
                .padding(.vertical, PCTokens.Spacing.space2)
                .background(
                    RoundedRectangle(cornerRadius: PCTokens.Radius.r2, style: .continuous)
                        .fill(hover ? PCTokens.Color.accentSoft(dark).opacity(0.2) : PCTokens.Color.card(dark))
                        .stroke(PCTokens.Color.divider(dark), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .animation(PCTokens.Motion.springSwift(reduceMotion: reduceMotion), value: hover)
    }
}