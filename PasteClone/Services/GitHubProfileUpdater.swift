import Foundation
import AppKit

/// 提示用户在 GitHub 个人资料中公开邮箱
class GitHubProfileUpdater {
    static func suggestPublishEmail() {
        let alert = NSAlert()
        alert.messageText = "分享您的邮箱"
        alert.informativeText = "为了方便用户通过邮箱与您联系，建议在 GitHub 个人资料中公开您的邮箱：15665874885@163.com"
        alert.addButton(withTitle: "打开 GitHub 设置")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "https://github.com/settings/profile")!)
        }
    }
}
