import AppKit
import Foundation

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
              !(Self.ignoredBundleIDs.contains(app.bundleIdentifier ?? "")) else { return }
        targetApp = app
        NSLog("[PasteClone] captureTargetApp → %@ (%@)", app.localizedName ?? "?", app.bundleIdentifier ?? "?")
    }

    /// Restore the app that owned focus before the history panel appeared.
    @discardableResult
    func restoreTargetApp() -> Bool {
        guard let app = targetApp, !app.isTerminated else { return false }
        return app.activate(options: [.activateIgnoringOtherApps])
    }
}
