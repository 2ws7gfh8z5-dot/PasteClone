// 独立自检：swift Tests/profile_check.swift
// 复刻 ProfileAnalyzer 的纯函数逻辑（脚本无法 import app target），断言关键行为。

import Foundation

func isCode(_ text: String) -> Bool {
    let markers = ["{", "}", "=>", "func ", "def ", "const ", "let ", "</", "();", "!==", "import ", "class "]
    return markers.contains { text.contains($0) }
}

func hasURL(_ text: String) -> Bool {
    text.contains("://") || text.hasPrefix("www.")
}

func topWords(_ counts: [String: Int], limit: Int) -> [String] {
    counts.sorted { $0.value > $1.value }.prefix(limit).map(\.key)
}

let appRoles: [(String, String)] = [
    ("com.apple.dt.Xcode", "软件工程师"),
    ("com.apple.Terminal", "软件工程师"),
    ("com.figma.Desktop", "设计师"),
    ("com.microsoft.Excel", "财务 / 运营"),
]

func occupation(from apps: [String: Int], codeRatio: Double) -> (String, Double) {
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

var failures = 0
func check(_ cond: Bool, _ msg: String) {
    if !cond { print("FAIL: \(msg)"); failures += 1 }
}

// 代码识别
check(isCode("func main() { print(1) }"), "Swift 代码应被识别")
check(isCode("const x = () => 1"), "箭头函数应被识别")
check(!isCode("今天天气不错，出去走走"), "普通中文不应被当成代码")

// URL
check(hasURL("https://example.com"), "https 应识别为 URL")
check(!hasURL("example.com"), "无协议头的裸域名不算")

// 职业推断：App 分布主导
let devApps = ["com.apple.dt.Xcode": 40, "com.apple.Safari": 10]
let (devRole, devConf) = occupation(from: devApps, codeRatio: 0.5)
check(devRole == "软件工程师", "Xcode 为主应推断软件工程师，实际 \(devRole)")
check(devConf > 0.7, "置信度应高于 0.7，实际 \(devConf)")

let designApps = ["com.figma.Desktop": 30, "com.apple.Safari": 5]
check(occupation(from: designApps, codeRatio: 0).0 == "设计师", "Figma 为主应推断设计师")

// 无信号时不乱猜
let (unknown, conf) = occupation(from: [:], codeRatio: 0)
check(unknown == "暂时无法判断", "空数据应返回暂时无法判断")
check(conf == 0, "空数据置信度应为 0")

// 代码比例高时也给开发者加权
let mixed = ["com.apple.Safari": 20]
let (codeRole, _) = occupation(from: mixed, codeRatio: 0.8)
check(codeRole == "软件工程师", "代码占比高应推断软件工程师，实际 \(codeRole)")

// 高频词排序
check(topWords(["a": 1, "b": 5, "c": 3], limit: 2) == ["b", "c"], "高频词应按次数降序取前 N")

if failures == 0 {
    print("profile check: PASS")
} else {
    print("profile check: \(failures) 项失败")
    exit(1)
}
