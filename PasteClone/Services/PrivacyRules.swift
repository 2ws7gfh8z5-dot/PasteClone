import AppKit

/// User-managed capture exclusions. Bundle identifiers are stable across app updates.
class PrivacyRules {
    /// Bundle identifier of the PasteClone app — used to exclude self from clipboard monitoring
    static let ownBundleID = "com.you.justpaste"
    
    static let defaultsKey = "excludedBundleIDs"

    static var excludedBundleIDs: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []) }
        set { UserDefaults.standard.set(newValue.sorted(), forKey: defaultsKey) }
    }

    static func excludes(bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier else { return false }
        // Always exclude self
        if bundleIdentifier == ownBundleID { return true }
        return excludedBundleIDs.contains(bundleIdentifier)
    }

    static func add(_ bundleIdentifier: String) {
        var rules = excludedBundleIDs
        rules.insert(bundleIdentifier)
        excludedBundleIDs = rules
    }

    static func remove(_ bundleIdentifier: String) {
        var rules = excludedBundleIDs
        rules.remove(bundleIdentifier)
        excludedBundleIDs = rules
    }
}
