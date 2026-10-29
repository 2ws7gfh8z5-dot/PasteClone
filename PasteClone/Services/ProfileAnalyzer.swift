import Foundation
import NaturalLanguage

// MARK: - 信号与画像

/// 只保存聚合计数，不保存任何原文。原文在这里被丢弃，留下的只有统计量。
struct ProfileSignal: Codable {
    var apps: [String: Int] = [:]
    var languages: [String: Int] = [:]
    var hours: [String: Int] = [:]
    var codeCount = 0
    var urlCount = 0
    var textCount = 0
    var words: [String: Int] = [:]
    var seen: [String] = []          // contentHash，仅用于去重
}

struct UserProfile: Codable {
    var occupation: String
    var confidence: Double
    var interests: [String]
    var apps: [String: Int]
    var generatedAt: Date
}

// MARK: - ProfileAnalyzer

/// 纯本地画像分析。不发任何网络请求，不保存剪贴板原文。
/// 密码管理器内容与用户排除的 App 在 ClipboardMonitor 已被拦下，到不了这里。
final class ProfileAnalyzer: ObservableObject {
    static let shared = ProfileAnalyzer()

    /// 默认关闭。用户在偏好设置里显式打开才生效。
    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "profileAnalysisEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "profileAnalysisEnabled") }
    }

    @Published private(set) var profile: UserProfile?

    private let queue = DispatchQueue(label: "com.you.justpaste.profile", qos: .utility)
    private let dir: URL
    private var signalURL: URL { dir.appendingPathComponent("profile_signals.json") }
    private var profileURL: URL { dir.appendingPathComponent("profile.json") }

    private init() {
        dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PasteClone", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        profile = loadProfile()
    }

    // MARK: 采集

    /// 记录一条内容。只取统计特征，原文在处理后立即丢弃。
    func record(_ item: ClipboardItem) {
        guard Self.isEnabled else { return }
        guard item.type == .text || item.type == .rtf else { return }
        let text = item.displayText
        guard !text.isEmpty, text.count <= 20_000 else { return }
        let hash = item.contentHash
        let bundleID = item.sourceAppBundleID ?? "unknown"
        let hour = Calendar.current.component(.hour, from: item.timestamp)

        queue.async { [weak self] in
            guard let self else { return }
            var s = self.loadSignals()
            guard !s.seen.contains(hash) else { return }
            s.seen.append(hash)
            if s.seen.count > 2000 { s.seen.removeFirst(s.seen.count - 2000) }  // ponytail: 去重表有上限；超限后老条目可能被重复统计一次

            s.apps[bundleID, default: 0] += 1
            s.hours[String(hour), default: 0] += 1
            s.textCount += 1
            if Self.isCode(text) { s.codeCount += 1 }
            if Self.hasURL(text) { s.urlCount += 1 }
            if let lang = Self.dominantLanguage(text) {
                s.languages[lang, default: 0] += 1
            }
            for word in Self.extractWords(text) {
                s.words[word, default: 0] += 1
            }
            // 词表也有上限，防止无限增长
            if s.words.count > 3000 {
                let keep = s.words.sorted { $0.value > $1.value }.prefix(1500)
                s.words = Dictionary(uniqueKeysWithValues: keep.map { ($0.key, $0.value) })
            }
            self.saveSignals(s)
        }
    }

    // MARK: 分析

    /// 启动时调用：超过 24 小时才重新分析。
    func analyzeIfStale() {
        guard Self.isEnabled else { return }
        let last = UserDefaults.standard.object(forKey: "profileLastRun") as? Date
        if let last, Date().timeIntervalSince(last) < 86_400 { return }
        analyze()
    }

    /// 手动触发，或由 analyzeIfStale 调用。
    func analyze() {
        guard Self.isEnabled else { return }
        queue.async { [weak self] in
            guard let self else { return }
            let s = self.loadSignals()
            guard s.textCount >= 20 else { return }   // 样本太少，结论没有意义

            let (occupation, confidence) = Self.occupation(from: s.apps, codeRatio: s.codeRatio)
            let profile = UserProfile(
                occupation: occupation,
                confidence: confidence,
                interests: Self.topWords(s.words, limit: 8),
                apps: s.apps,
                generatedAt: Date()
            )
            self.saveProfile(profile)
            UserDefaults.standard.set(Date(), forKey: "profileLastRun")
            DispatchQueue.main.async { self.profile = profile }
        }
    }

    /// 删除画像与全部信号。用户要求时必须两样都清掉。
    func clear() {
        queue.sync {
            try? FileManager.default.removeItem(at: signalURL)
            try? FileManager.default.removeItem(at: profileURL)
            UserDefaults.standard.removeObject(forKey: "profileLastRun")
        }
        profile = nil
    }

    // MARK: 纯函数（可测试）

    /// 用符号特征判断是否代码片段，不做模型调用。
    static func isCode(_ text: String) -> Bool {
        let markers = ["{", "}", "=>", "func ", "def ", "const ", "let ", "</", "();", "!==", "import ", "class "]
        return markers.contains { text.contains($0) }
    }

    static func hasURL(_ text: String) -> Bool {
        text.contains("://") || text.hasPrefix("www.")
    }

    static func dominantLanguage(_ text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(String(text.prefix(400)))
        return recognizer.dominantLanguage?.rawValue
    }

    /// 取名词，去掉人名和纯数字，只保留有意义的偏好词。
    static func extractWords(_ text: String) -> [String] {
        var out: [String] = []
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
        tagger.string = String(text.prefix(2000))
        tagger.enumerateTags(in: tagger.string!.startIndex..<tagger.string!.endIndex,
                            unit: .word,
                            scheme: .lexicalClass,
                            options: [.omitPunctuation, .omitWhitespace]) { tag, range in
            guard tag == .noun else { return true }
            let word = String(tagger.string![range]).lowercased()
            guard word.count >= 2, word.count <= 20 else { return true }
            let nameType = tagger.tag(at: range.lowerBound, unit: .word, scheme: .nameType).0
            guard nameType != .personalName else { return true }
            guard !word.allSatisfy({ $0.isNumber }) else { return true }
            out.append(word)
            return true
        }
        return out
    }

    static func topWords(_ counts: [String: Int], limit: Int) -> [String] {
        counts.sorted { $0.value > $1.value }.prefix(limit).map(\.key)
    }

    /// 由来源 App 分布推断职业。App 分布是最强的信号，且不含任何内容。
    static func occupation(from apps: [String: Int], codeRatio: Double) -> (String, Double) {
        var score: [String: Int] = [:]
        for (bundle, count) in apps {
            for (prefix, role) in appRoles where bundle.hasPrefix(prefix) {
                score[role, default: 0] += count
            }
        }
        if codeRatio > 0.25 { score["软件工程师", default: 0] += 10 }

        let total = apps.values.reduce(0, +)
        guard total > 0, let best = score.max(by: { $0.value < $1.value }) else {
            return ("暂时无法判断", 0)
        }
        let confidence = min(1.0, Double(best.value) / Double(total))
        return (best.key, (confidence * 100).rounded() / 100)
    }

    private static let appRoles: [(String, String)] = [
        ("com.apple.dt.Xcode", "软件工程师"),
        ("com.microsoft.VSCode", "软件工程师"),
        ("com.jetbrains", "软件工程师"),
        ("com.googlecode.iterm2", "软件工程师"),
        ("com.apple.Terminal", "软件工程师"),
        ("com.figma.Desktop", "设计师"),
        ("com.adobe", "设计师"),
        ("com.bohemiancoding.sketch", "设计师"),
        ("com.microsoft.Excel", "财务 / 运营"),
        ("com.microsoft.Powerpoint", "财务 / 运营"),
        ("com.microsoft.Word", "文字工作者"),
        ("com.apple.iWork.Pages", "文字工作者"),
        ("com.apple.iWork.Keynote", "文字工作者"),
        ("com.tinyspeck.slackmacgap", "团队协作岗位"),
        ("com.microsoft.teams", "团队协作岗位"),
    ]

    // MARK: 存储

    private func loadSignals() -> ProfileSignal {
        guard let data = try? Data(contentsOf: signalURL),
              let s = try? JSONDecoder().decode(ProfileSignal.self, from: data) else {
            return ProfileSignal()
        }
        return s
    }

    private func saveSignals(_ s: ProfileSignal) {
        guard let data = try? JSONEncoder().encode(s) else { return }
        try? data.write(to: signalURL, options: .atomic)
    }

    private func loadProfile() -> UserProfile? {
        guard let data = try? Data(contentsOf: profileURL) else { return nil }
        return try? JSONDecoder().decode(UserProfile.self, from: data)
    }

    private func saveProfile(_ p: UserProfile) {
        guard let data = try? JSONEncoder().encode(p) else { return }
        try? data.write(to: profileURL, options: .atomic)
    }
}

private extension ProfileSignal {
    var codeRatio: Double {
        textCount > 0 ? Double(codeCount) / Double(textCount) : 0
    }
}
