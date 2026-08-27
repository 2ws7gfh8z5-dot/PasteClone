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

    var body: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 18) {
            Text("偏好设置").font(.system(size: 18, weight: .bold)).foregroundColor(PCTheme.ink)

            Picker("外观", selection: $appearanceMode) {
                ForEach(PCTheme.Mode.allCases) { mode in Text(mode.title).tag(mode.rawValue) }
            }
            .pickerStyle(.segmented)
            .help("跟随当前时区时间：07:00–18:59 浅色，其余时间深色")
            
            // 保留条目数
            Picker("保留条目", selection: $maxItems) {
                Text("100").tag(100)
                Text("500").tag(500)
                Text("1000").tag(1000)
                Text("2000").tag(2000)
            }.pickerStyle(.segmented)
            
            // 开机启动
            Toggle("开机启动", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { enabled in
                    do {
                        if enabled { try SMAppService.mainApp.register() }
                        else { try SMAppService.mainApp.unregister() }
                    } catch { launchAtLogin = SMAppService.mainApp.status == .enabled }
                }
            
            // 全局快捷键开关
            Toggle("全局热键", isOn: $hotkeyEnabled)
                .onChange(of: hotkeyEnabled) { enabled in
                    if enabled { HotkeyManager.shared.register() }
                    else { HotkeyManager.shared.unregister() }
                }
            
            // 快捷键选择
            if hotkeyEnabled {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("快捷键预设", selection: $hotkeyPreset) {
                        ForEach(HotkeyPreset.allCases.filter { $0 != .custom }) { preset in
                            Text(preset.title).tag(preset.rawValue)
                        }
                        Divider()
                        Text("自定义").tag(HotkeyPreset.custom.rawValue)
                    }
                    .onChange(of: hotkeyPreset) { _ in
                        HotkeyManager.shared.register()
                    }
                    
                    // 自定义快捷键编辑器
                    if hotkeyPreset == HotkeyPreset.custom.rawValue {
                        HotkeyDisplay(keyCode: UInt32(customKeyCode), modifiers: UInt32(customModifiers)) { code, mods in
                            customKeyCode = Int(code)
                            customModifiers = Int(mods)
                            HotkeyPreset.saveCustomHotkey(keyCode: code, modifiers: mods)
                            HotkeyManager.shared.register()
                        }
                        .padding(8)
                        .background(PCTheme.accentSoft.opacity(0.15))
                        .cornerRadius(8)
                    }
                }
                .padding(10)
                .background(PCTheme.card)
                .cornerRadius(8)
            }
            
            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("隐私规则").font(.caption).foregroundColor(PCTheme.inkSoft)
                    Spacer()
                    Menu("选择要忽略的 App") {
                        ForEach(runningApps, id: \.bundleIdentifier) { app in
                            Button(app.localizedName ?? app.bundleIdentifier ?? "未知 App") {
                                if let bundleID = app.bundleIdentifier {
                                    PrivacyRules.add(bundleID)
                                    excludedBundleIDs = PrivacyRules.excludedBundleIDs
                                    privacyStatus = "已忽略 \(app.localizedName ?? bundleID)"
                                }
                            }
                        }
                    }
                    .menuStyle(.borderlessButton)
                    .foregroundColor(PCTheme.accent)
                }
                if excludedBundleIDs.isEmpty {
                    Text("尚未排除 App。可在密码管理器等敏感应用位于前台时点击上方按钮。")
                        .font(.caption).foregroundColor(PCTheme.inkSoft)
                } else {
                    ForEach(excludedBundleIDs.sorted(), id: \.self) { bundleID in
                        HStack {
                            Text(bundleID).font(.caption.monospaced()).lineLimit(1)
                            Spacer()
                            Button { PrivacyRules.remove(bundleID); excludedBundleIDs = PrivacyRules.excludedBundleIDs } label: {
                                Image(systemName: "minus.circle")
                            }.buttonStyle(.plain).accessibilityLabel("停止忽略 \(bundleID)")
                        }
                    }
                }
                HStack {
                    Button("检查粘贴权限") { checkAccessibility() }.buttonStyle(.plain).foregroundColor(PCTheme.accent)
                    if !privacyStatus.isEmpty { Text(privacyStatus).font(.caption).foregroundColor(PCTheme.inkSoft) }
                }
            }
            .padding(10)
            .background(PCTheme.card)
            .cornerRadius(8)

            // 更新日志
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("更新日志").font(.caption).foregroundColor(PCTheme.inkSoft)
                    Spacer()
                    Text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")")
                        .font(.caption2.monospaced())
                        .foregroundColor(PCTheme.inkSoft)
                }
                Text("• 新增按 App 排除的隐私规则\n• 修复内部写入剪贴板可能吞掉下一次复制的问题\n• 修复历史容量限制并增强本地数据安全\n• 增加辅助功能权限检查与颜色内容记录")
                    .font(.caption)
                    .foregroundColor(PCTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(PCTheme.card)
            .cornerRadius(8)

            // 捐款
            VStack(alignment: .leading, spacing: 10) {
                Text("支持开发").font(.caption).foregroundColor(PCTheme.inkSoft)
                HStack {
                    TextField("捐款链接", text: $donationURL)
                    Button(action: { NSWorkspace.shared.open(URL(string: donationURL) ?? URL(string: "https://github.com/2ws7gfh8z5-dot/PasteClone")!) }) {
                        Label("打开", systemImage: "arrow.up.right")
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Spacer(minLength: 4)
        }
        }
        .padding(20)
        .frame(width: 500, height: 650)
        .background(.ultraThinMaterial)
        .background(PCTheme.panel.opacity(0.72))
        .preferredColorScheme(PCTheme.isDark(PCTheme.Mode(rawValue: appearanceMode) ?? .automatic, date: clock) ? .dark : .light)
        .onAppear { launchAtLogin = SMAppService.mainApp.status == .enabled }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { clock = $0 }
    }

    private var runningApps: [NSRunningApplication] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != Bundle.main.bundleIdentifier }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }

    private func checkAccessibility() {
        let prompt = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        privacyStatus = AXIsProcessTrustedWithOptions(prompt) ? "已授权，可一键粘贴" : "请在系统设置中允许辅助功能权限"
    }

}
