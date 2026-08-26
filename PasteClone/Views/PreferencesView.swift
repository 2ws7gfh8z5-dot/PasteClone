import SwiftUI
import ServiceManagement
import AppKit

struct PreferencesView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("maxItems") private var maxItems = 1000
    @AppStorage("hotkeyEnabled") private var hotkeyEnabled = true

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
                .onChange(of: launchAtLogin) { v in
                    try? SMAppService.mainApp.register()
                }
            Toggle("全局热键 (⇧⌘V)", isOn: $hotkeyEnabled)
            Spacer()
        }
        .padding(20)
        .frame(width: 380, height: 220)
        .background(PCTheme.panel)
    }
}
