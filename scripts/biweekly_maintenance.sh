#!/bin/bash
# PasteClone 双周维护脚本；每两周周六 20:00 (Asia/Shanghai) 运行。
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(sed -n 's/^version = "\([^"]*\)"/\1/p' "$REPO_DIR/CrossPlatformClient/Cargo.toml" | head -1)"
REPORT_DIR="$REPO_DIR/MAINTENANCE_REPORTS"
REPORT_FILE="$REPORT_DIR/$(date +%Y-%m-%d_%H-%M-%S).md"
mkdir -p "$REPORT_DIR"
cd "$REPO_DIR"

run_check() {
  local label="$1"
  shift
  if "$@"; then printf -- '- %s: PASS\n' "$label" | tee -a "$REPORT_FILE"; return 0; fi
  printf -- '- %s: FAIL\n' "$label" | tee -a "$REPORT_FILE"; return 1
}

printf '# PasteClone 双周维护报告\n\n- 时间: %s\n- 版本: %s\n\n## GitHub\n' "$(date)" "$VERSION" | tee "$REPORT_FILE"
printf -- '- Stars: %s\n' "$(gh repo view 2ws7gfh8z5-dot/PasteClone --json stargazerCount -q '.stargazerCount' 2>/dev/null || echo N/A)" | tee -a "$REPORT_FILE"
printf -- '- Open issues: %s\n' "$(gh issue list -R 2ws7gfh8z5-dot/PasteClone --state open --json number -q length 2>/dev/null || echo N/A)" | tee -a "$REPORT_FILE"
printf '\n## 本地验证\n' | tee -a "$REPORT_FILE"

failed=0
run_check '共享核心测试' swift test --package-path SharedCore || failed=1
run_check 'Windows/Linux 客户端测试' cargo test --manifest-path CrossPlatformClient/Cargo.toml || failed=1
run_check 'Windows/Linux 客户端 Release 构建' cargo build --release --manifest-path CrossPlatformClient/Cargo.toml || failed=1
run_check 'macOS Universal 构建与安装包' env VERSION="$VERSION" ./scripts/build_dmg.sh || failed=1

printf '\n## 四平台发布状态\n' | tee -a "$REPORT_FILE"
printf -- '- macOS Apple Silicon / Intel: `%s`, `%s`\n' "build/PasteClone-$VERSION.dmg" "build/PasteClone-$VERSION.zip" | tee -a "$REPORT_FILE"
printf -- '- Windows x86_64 / Linux x86_64: 由 GitHub Actions 在对应真实 runner 构建；发布前必须确认工作流成功。\n' | tee -a "$REPORT_FILE"
gh run list -R 2ws7gfh8z5-dot/PasteClone --workflow cross-platform.yml --limit 5 >>"$REPORT_FILE" 2>&1 || true

printf '\n## 发布清单\n- [ ] 根据 Issues/Discussions 修复可复现问题\n- [ ] 提升版本号并更新 CHANGELOG\n- [ ] 四平台工作流通过\n- [ ] GitHub Release 包含四平台安装包和源码\n- [ ] 经用户确认后发布第三方宣传内容\n' | tee -a "$REPORT_FILE"

exit "$failed"
