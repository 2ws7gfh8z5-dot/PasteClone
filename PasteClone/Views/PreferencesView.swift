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
    @State private var showDonationPrompt = false

    var body: some View {
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

            // 更新日志
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("更新日志").font(.caption).foregroundColor(PCTheme.inkSoft)
                    Spacer()
                    Text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")")
                        .font(.caption2.monospaced())
                        .foregroundColor(PCTheme.inkSoft)
                }
                Text("• 统一为单一正式版本，后续更新以此版本为准\n• 修复历史记录按钮粘贴时的目标应用焦点与时序\n• 支持自动、浅色、深色外观模式\n• 增加一键构建、验证与发布流程")
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
            
            Spacer()
        }
        .padding(20)
        .frame(width: 480, height: 500)
        .background(PCTheme.panel)
        .preferredColorScheme(PCTheme.isDark(PCTheme.Mode(rawValue: appearanceMode) ?? .automatic, date: clock) ? .dark : .light)
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { clock = $0 }
    }
}
