#!/bin/bash

# PasteClone GitHub Release 脚本
# 用途：上传构建产物到 GitHub Releases

set -e

REPO="2ws7gfh8z5-dot/PasteClone"
VERSION="1.2.3"
BUILD_DIR="./build"
RELEASE_NOTES="## 🎉 PasteClone v${VERSION}

一款原生 macOS 剪贴板历史管理器，支持快速搜索、固定收藏、按应用筛选和粘贴队列。

### ✨ 功能
- 自动记录文本、图片、文件、富文本内容
- 全局快捷键快速呼出历史面板
- 实时模糊搜索与按应用筛选
- 收藏固定重要内容
- 粘贴队列连续粘贴多项
- 本地 JSON 存储，无数据上传

### 🔧 快捷键
- \`⇧⌘V\` - 呼出历史面板
- \`⌘C\` - 复制选中项
- \`⌘V\` - 粘贴选中项
- \`⌘P\` - 固定/取消固定
- \`⌘1-9\` - 快速选择 1-9 位置

### 📋 系统要求
- macOS 14 Sonoma 或更高
- Apple Silicon / Intel Mac

### 📚 文档
- [使用说明书](MANUAL.md)
- [快捷键列表](SHORTCUTS.md)
- [功能速览](QUICK_OVERVIEW.md)

### 📧 反馈
邮件：15665874885@163.com
GitHub Issues：https://github.com/${REPO}/issues
"

echo "✓ GitHub Release 脚本已准备"
echo "版本：${VERSION}"
echo "仓库：${REPO}"
echo ""
echo "待上传文件："
ls -lh ${BUILD_DIR}/PasteClone*.zip 2>/dev/null || echo "  未找到 ZIP 文件"
echo ""
echo "使用方式："
echo "  gh release create v${VERSION} -t 'PasteClone v${VERSION}' -n '<notes>' ./build/PasteClone*.zip"
echo ""
echo "或使用 GitHub Web 界面手动上传 Releases"
