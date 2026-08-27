import AppKit

/// User-managed capture exclusions. Bundle identifiers are stable across app updates.
enum PrivacyRules {
    static let defaultsKey = "excludedBundleIDs"

    static var excludedBundleIDs: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []) }
        set { UserDefaults.standard.set(newValue.sorted(), forKey: defaultsKey) }
    }

    static func excludes(bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier else { return false }
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
