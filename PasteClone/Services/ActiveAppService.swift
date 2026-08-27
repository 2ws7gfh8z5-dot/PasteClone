import AppKit
import Foundation

final class ActiveAppService {
    static let shared = ActiveAppService()

    private var targetApp: NSRunningApplication?

    /// Call immediately before showing PasteClone so we remember the editor the user came from.
    func captureTargetApp() {
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return }
        targetApp = app
    }

    /// Restore the app that owned focus before the history panel appeared.
    @discardableResult
    func restoreTargetApp() -> Bool {
        guard let app = targetApp, !app.isTerminated else { return false }
        return app.activate(options: [.activateIgnoringOtherApps])
    }
}
