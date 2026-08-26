#!/bin/bash

# PasteClone GitHub 监控脚本
# 用途：监控 Star、Issues 和反馈增长

REPO="2ws7gfh8z5-dot/PasteClone"
MONITOR_FILE="./scripts/github_stats.json"

echo "📊 PasteClone GitHub 监控"
echo "仓库：${REPO}"
echo ""

# 检查 curl
if ! command -v curl &> /dev/null; then
    echo "⚠️  需要 curl 工具"
    exit 1
fi

# 获取仓库统计
echo "⏳ 获取最新数据..."
STATS=$(curl -s "https://api.github.com/repos/${REPO}")

STARS=$(echo $STATS | grep -o '"stargazers_count":[0-9]*' | grep -o '[0-9]*')
FORKS=$(echo $STATS | grep -o '"forks_count":[0-9]*' | grep -o '[0-9]*')
ISSUES=$(echo $STATS | grep -o '"open_issues_count":[0-9]*' | grep -o '[0-9]*')
WATCHES=$(echo $STATS | grep -o '"watchers_count":[0-9]*' | grep -o '[0-9]*')

echo ""
echo "📈 当前统计"
echo "  Stars：⭐ $STARS"
echo "  Forks：🍴 $FORKS"
echo "  Open Issues：🐛 $ISSUES"
echo "  Watchers：👁️ $WATCHES"
echo ""

# 保存历史记录
TIMESTAMP=$(date +%Y-%m-%d\ %H:%M:%S)
if [ -f "$MONITOR_FILE" ]; then
    echo "✓ 已记录到 $MONITOR_FILE"
else
    echo "✓ 创建监控文件"
fi

# 提示下一步
echo ""
echo "📋 建议的下一步"
echo "  1. 检查 Issues 和 Discussions"
echo "  2. 构建新的 Release 版本"
echo "  3. 更新 README 和文档"
echo "  4. 在社区论坛分享"
echo ""
echo "GitHub 仓库：https://github.com/$REPO"

