import SwiftUI
import AppKit

struct DonationPromptView: View {
    @State private var showDonation = false
    @State private var hasShownDonation = UserDefaults.standard.bool(forKey: "hasShownDonationPrompt")
    
    var body: some View {
        EmptyView()
            .onAppear {
                if !hasShownDonation {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showDonation = true
                        UserDefaults.standard.set(true, forKey: "hasShownDonationPrompt")
                    }
                }
            }
            .alert("支持 PasteClone 开发", isPresented: $showDonation) {
                Button("取消", role: .cancel) { }
                Button("打开捐款页面") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/2ws7gfh8z5-dot/PasteClone#support-development")!)
                }
            } message: {
                Text("PasteClone 是一个免费开源项目。如果您喜欢，考虑通过 GitHub Sponsors 或其他方式支持开发？")
            }
    }
}
