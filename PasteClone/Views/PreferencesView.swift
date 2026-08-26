import SwiftUI
import ServiceManagement
import AppKit

struct PreferencesView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("maxItems") private var maxItems = 1000
    @AppStorage("hotkeyEnabled") private var hotkeyEnabled = true
    @AppStorage("hotkeyPreset") private var hotkeyPreset = HotkeyPreset.shiftCommandV.rawValue
    @AppStorage("donationURL") private var donationURL = "https://github.com/2ws7gfh8z5-dot/PasteClone#支持开发"

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("偏好设置").font(.system(size: 18, weight: .bold)).foregroundColor(PCTheme.ink)
            Picker("保留条目", selection: $maxItems) {
                Text("100").tag(100)
                Text("500").tag(500)
                Text("1000").tag(1000)
                Text("2000").tag(2000)
            }.pickerStyle(.segmented)
            Toggle("开机启动", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { enabled in
                    do {
                        if enabled { try SMAppService.mainApp.register() }
                        else { try SMAppService.mainApp.unregister() }
                    } catch { launchAtLogin = SMAppService.mainApp.status == .enabled }
                }
            Toggle("全局热键 (⇧⌘V)", isOn: $hotkeyEnabled)
                .onChange(of: hotkeyEnabled) { enabled in
                    if enabled { HotkeyManager.shared.register() }
                    else { HotkeyManager.shared.unregister() }
                }
            Picker("呼出快捷键", selection: $hotkeyPreset) {
                ForEach(HotkeyPreset.allCases) { preset in Text(preset.title).tag(preset.rawValue) }
            }
            .onChange(of: hotkeyPreset) { _ in
                if hotkeyEnabled { HotkeyManager.shared.register() }
            }
            Divider()
            HStack {
                Text("捐款链接")
                TextField("https://…", text: $donationURL)
            }
            Button { NSWorkspace.shared.open(URL(string: donationURL) ?? URL(string: "https://github.com/2ws7gfh8z5-dot/PasteClone")!) } label: {
                Label("支持 PasteClone 开发", systemImage: "heart")
            }
            Spacer()
        }
        .padding(20)
        .frame(width: 420, height: 300)
        .background(PCTheme.panel)
    }
}
