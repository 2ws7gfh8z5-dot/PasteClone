import Foundation

// 与 ClipboardStore.fuzzyScore 保持一致（脚本无法 import app target）
func fuzzyScore(_ query: String, _ text: String) -> Int? {
    if query.isEmpty { return 0 }
    let q = Array(query.lowercased()), t = Array(text.lowercased())
    var score = 0, ti = 0
    for (qi, ch) in q.enumerated() {
        var gap = 0
        while ti < t.count && t[ti] != ch { gap += 1; ti += 1 }
        guard ti < t.count else { return nil }
        score += 1 - gap
        if qi > 0 && ti > 0 && t[ti - 1] == q[qi - 1] { score += 3 }
        if ti == 0 || (!t[ti - 1].isLetter && !t[ti - 1].isNumber) { score += 5 }
        if qi == 0 { score += max(0, 5 - ti) }
        ti += 1
    }
    return score
}

func check(_ cond: Bool, _ msg: String) {
    guard cond else { print("fuzzy check: FAIL - \(msg)"); exit(1) }
}

check(fuzzyScore("gth", "github") != nil, "gth 应匹配 github")
check(fuzzyScore("htbg", "github") == nil, "htbg 不应匹配 github（顺序）")
check(fuzzyScore("", "anything") != nil, "空 query 应匹配一切")
check(fuzzyScore("剪贴", "剪贴板工具") != nil, "CJK 逐字符匹配")
check(fuzzyScore("GH", "github") != nil, "大小写不敏感")
check(fuzzyScore("gh", "GitHub") == fuzzyScore("GH", "github"), "大小写得分应一致")
check(fuzzyScore("git", "github")! > fuzzyScore("git", "gist")!, "连续/词首得分更高")
check(fuzzyScore("zzz", "github") == nil, "无匹配返回 nil")

print("fuzzy check: PASS")
