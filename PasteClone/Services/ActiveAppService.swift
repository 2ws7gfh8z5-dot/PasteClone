import AppKit
import Foundation
import os.log

fileprivate let logger = Logger(subsystem: "com.you.PasteClone", category: "ActiveAppService")

final class ActiveAppService {
    static let shared = ActiveAppService()

    private var targetApp: NSRunningApplication?

    // ponytail: ignoring transient helper processes keeps the target correct when hotkey is
    //   triggered via AppleScript/automation. Ceiling: process name list; upgrade if new helpers appear.
    private static let ignoredBundleIDs: Set<String> = [
        Bundle.main.bundleIdentifier ?? "",
        "com.apple.ScriptEditor2",
        "com.apple.osascript",
        "com.apple.systemevents",
        "com.apple.Terminal",
        "org.gnu.Emacs",
    ]

    /// Call immediately before showing PasteClone so we remember the editor the user came from.
    func captureTargetApp() {
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier,
              !(Self.ignoredBundleIDs.contains(app.bundleIdentifier ?? "")) else { 
            logger.debug("captureTargetApp: 跳过 - 无有效前台应用或被忽略")
            return 
        }
        targetApp = app
        logger.debug("captureTargetApp → \(app.localizedName ?? "?", privacy: .public) (\(app.bundleIdentifier ?? "?", privacy: .public), PID: \(app.processIdentifier, privacy: .public))")
    }

    /// Restore the app that owned focus before the history panel appeared.
    @discardableResult
    func restoreTargetApp() -> Bool {
        guard let app = targetApp, !app.isTerminated else { 
            logger.debug("restoreTargetApp: 目标应用为空或已终止")
            return false 
        }
        let result = app.activate(options: [.activateIgnoringOtherApps])
        logger.debug("restoreTargetApp → \(app.localizedName ?? "?", privacy: .public) (\(app.bundleIdentifier ?? "?", privacy: .public)): \(result ? "成功" : "失败", privacy: .public)")
        return result
    }
}
