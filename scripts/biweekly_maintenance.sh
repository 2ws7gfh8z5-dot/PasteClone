#!/bin/bash
# PasteClone 双周维护脚本
# 执行时间: 每两周周六 20:00 (Asia/Shanghai)

set -e

REPO_DIR="/Users/huaziyi/Desktop/pasteclone"
REPORT_FILE="$REPO_DIR/MAINTENANCE_REPORTS/$(date +%Y-%m-%d_%H-%M-%S).md"
mkdir -p "$REPO_DIR/MAINTENANCE_REPORTS"

echo "=== PasteClone 双周维护开始 $(date) ===" | tee "$REPORT_FILE"

# 1. 监控指标
echo "" | tee -a "$REPORT_FILE"
echo "## 1. GitHub 监控指标" | tee -a "$REPORT_FILE"
STARS=$(gh repo view 2ws7gfh8z5-dot/PasteClone --json stargazerCount -q '.stargazerCount' 2>/dev/null || echo "N/A")
ISSUES=$(gh issue list -R 2ws7gfh8z5-dot/PasteClone --state all -q '.[].number' 2>/dev/null | wc -l)
echo "- Stars: $STARS" | tee -a "$REPORT_FILE"
echo "- Issues: $ISSUES" | tee -a "$REPORT_FILE"

# 2. 功能验证
echo "" | tee -a "$REPORT_FILE"
echo "## 2. 功能验证" | tee -a "$REPORT_FILE"
echo "- 应用编译状态: $(xcodebuild -scheme PasteClone -configuration Release -quiet 2>&1 && echo '✅ SUCCESS' || echo '❌ FAILED')" | tee -a "$REPORT_FILE"
echo "- 应用包大小: $(du -sh "$REPO_DIR/PasteClone.dmg" 2>/dev/null | cut -f1)" | tee -a "$REPORT_FILE"

# 3. 宣传清单
echo "" | tee -a "$REPORT_FILE"
echo "## 3. 宣传渠道检查清单" | tee -a "$REPORT_FILE"
echo "- [ ] Product Hunt (https://www.producthunt.com/)" | tee -a "$REPORT_FILE"
echo "- [ ] Reddit r/macapps (https://reddit.com/r/macapps)" | tee -a "$REPORT_FILE"
echo "- [ ] MacRumors (https://macrumors.com/)" | tee -a "$REPORT_FILE"
echo "- [ ] Twitter/X (@pasteclone_app)" | tee -a "$REPORT_FILE"
echo "- [ ] V2EX (https://v2ex.com/)" | tee -a "$REPORT_FILE"

# 4. 生成总结
echo "" | tee -a "$REPORT_FILE"
echo "## 4. 下次检查" | tee -a "$REPORT_FILE"
NEXT_DATE=$(date -v+14d +"%Y-%m-%d %H:%M")
echo "定时下次: $NEXT_DATE" | tee -a "$REPORT_FILE"

echo "" | tee -a "$REPORT_FILE"
echo "=== 维护完成 ===" | tee -a "$REPORT_FILE"

# 提交报告到 GitHub
cd "$REPO_DIR"
git add "MAINTENANCE_REPORTS/$(basename $REPORT_FILE)"
git commit -m "chore: biweekly maintenance report $(date +%Y-%m-%d)" || true
git push origin main 2>/dev/null || echo "Push failed - check network"

