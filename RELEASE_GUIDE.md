# PasteClone 发布指南

## 1. 预发布检查清单

### 功能验证
- [ ] 剪贴板监听正常工作
- [ ] 全局快捷键 `⇧⌘V` 响应
- [ ] 历史项搜索、筛选正常
- [ ] 粘贴、复制、固定、删除功能正常
- [ ] 粘贴队列功能正常
- [ ] 自动粘贴到活跃应用正常
- [ ] 偏好设置页面响应正确
- [ ] 快捷键自定义保存生效

### UI/UX 检查
- [ ] 亮色模式界面清晰
- [ ] 暗色模式界面美观
- [ ] 图标在各尺寸显示正确
- [ ] 菜单栏图标清晰
- [ ] 文字大小合理，易读
- [ ] 按钮反馈灵敏
- [ ] 无卡顿或闪烁

### 构建验证
- [ ] Debug 构建成功
- [ ] Release 构建成功
- [ ] `scripts/build_dmg.sh` 正常产出 DMG 与 ZIP
- [ ] 应用能正常启动（未签名，首次打开需右键 →「打开」）
- [ ] 菜单栏正常显示

### 文档检查
- [ ] README 最新
- [ ] 下载链接指向 `releases/latest`，不写死版本号
- [ ] MANUAL.md 完整
- [ ] KEYBOARD_SHORTCUTS.md 准确
- [ ] FEATURES.md 详细
- [ ] QUICK_OVERVIEW.md 简洁
- [ ] CHANGELOG.md 顶部已加入本版本条目

## 2. 构建发布版本

macOS 安装包由 `scripts/build_dmg.sh` 一键产出（Universal：arm64 + x86_64）：

```bash
# 版本号从环境变量读取，省略时用脚本里的默认值
VERSION=1.8.1 bash scripts/build_dmg.sh
```

脚本会编译 Release 版本并输出两个文件到 `dist/`：

- `dist/JustPaste-1.8.1-macos-universal.dmg`
- `dist/JustPaste-1.8.1-macos-universal.zip`

Windows 包不本地构建，由 CI 产出（见第 3 节）。`.github/workflows/macos.yml` 只在 push 和 PR 时验证 macOS 能编译通过并跑模糊搜索自检，不产出发布资产。

## 3. 上传到 GitHub Releases

### 使用 GitHub CLI (gh)

`scripts/github_release.sh` 会自动从 `CHANGELOG.md` 摘出对应版本段落作为发布说明：

```bash
# 检查 gh 是否已认证
gh auth status

# 创建 Release（v1.8.1），上传 dist/ 下的 DMG 与 ZIP
bash scripts/github_release.sh 1.8.1
```

Windows 资产由 CI 上传：`.github/workflows/cross-platform.yml` 在推送 `v*` 标签时构建并附上 `PasteClone-Windows-x86_64.zip`。因此**先推标签，再让 CI 补上 Windows 包**，或先用 `gh` 建 Release 再推标签。

### 使用 GitHub Web 界面

1. 访问 https://github.com/2ws7gfh8z5-dot/PasteClone/releases
2. 点击"Draft a new release"
3. 填入 tag：`v1.8.1`
4. 填入标题：`PasteClone v1.8.1`
5. 粘贴发布说明（见下方）
6. 上传文件：`dist/JustPaste-1.8.1-macos-universal.dmg` 与 `.zip`
7. 点击"Publish release"

> Linux 自 1.8.0 起暂停发布，不要为 Linux 添加构建步骤或资产。

### 发布说明模板

```markdown
# 🎉 PasteClone v1.8.1

一款原生 macOS 剪贴板历史管理器，自动记录复制过的内容并通过全局快捷键快速搜索、预览和粘贴。

## 📦 下载

- **macOS**：`JustPaste-1.8.1-macos-universal.dmg`（Apple Silicon + Intel 通用）
- **Windows**：`PasteClone-Windows-x86_64.zip`（纯文本客户端，由 CI 构建）
- **Linux**：自 1.8.0 起暂停更新，不提供新构建

## ✨ 主要功能

- **自动记录**：后台记录文本、图片、文件、富文本、颜色内容
- **全局快捷键**：`⇧⌘V` 快速呼出历史面板（可自定义）
- **快速搜索**：子序列模糊搜索，数字键 `1`–`9` 直接粘贴对应行
- **收藏固定**：用 `⌘P` 标记重要内容
- **粘贴队列**：连续粘贴多个历史项
- **本地存储**：JSON 文件保存，完全离线，不上传数据

## 🔧 快捷键

| 快捷键 | 功能 |
|-------|------|
| `⇧⌘V` | 呼出历史面板 |
| `1`–`9` | 直接粘贴第 1–9 行 |
| `⌘C` | 复制选中项 |
| `⌘V` | 粘贴选中项 |
| `⌘P` | 固定/取消固定 |
| `⌘⌫` | 删除选中项 |
| `⌘1`–`⌘9` | 快速选择 1–9 位置 |
| `Esc` | 关闭面板 |

## 📋 系统要求

- macOS 14 Sonoma 或更高
- Apple Silicon / Intel Mac

## 📚 文档

- [详细使用说明](MANUAL.md)
- [快捷键完整列表](KEYBOARD_SHORTCUTS.md)
- [功能速览](QUICK_OVERVIEW.md)

## 📧 反馈

- 邮件：15665874885@163.com
- Issues：[GitHub Issues](../../issues)
- 支持开发：[GitHub Sponsors](https://github.com/sponsors/2ws7gfh8z5-dot)

## 🛠️ 开源

项目使用原生 Swift/SwiftUI/AppKit，无第三方依赖。
源代码：https://github.com/2ws7gfh8z5-dot/PasteClone
```

## 4. 同步更新

### 更新 GitHub 主页

1. 在仓库 Settings → About 更新
2. 添加标签：`clipboard`, `macos`, `swift`, `app`
3. 设置主页链接（可选）

### 更新 README

确保 README.md 包含：
- 功能总结
- 快速开始
- 快捷键列表
- 联系方式
- GitHub Releases 下载链接

### 提交 Git commit

```bash
git add -A
git commit -m "release: v1.8.1"
git push origin main
git tag v1.8.1
git push origin v1.8.1
```

推标签后 CI 会自动构建 Windows 包并附到该 Release 上。

## 5. 宣传渠道（可选）

> ⚠️ 注意：只在合规范围内宣传，不进行垃圾评论或虚假宣传

### 国内社区（可选）
- 小众软件论坛
- V2EX
- 少数派（sspai.com）
- MacTips（macsku.com）

### 国际社区（可选）
- Product Hunt
- Hacker News
- Reddit (r/macapps, r/swift)

### 社交媒体（可选）
- GitHub Discussions
- Twitter/X
- 微博
- 小红书

## 6. 监控与反馈

### 周期检查

**每周六 20:00 执行**：
1. 运行 `bash scripts/monitor_github.sh`
2. 检查 Star、Fork、Issues 增长
3. 阅读 Issues 和 Discussions 反馈
4. 记录用户建议
5. 优先处理 bug 报告

### 记录模板

```
# 2026-08-XX 反馈总结

## 数据
- Stars: 12 → 15 (+3)
- Issues: 0 → 1
- Forks: 2 → 2

## 新反馈
- [ ] Issue #1: 描述
- [ ] Discussion: 描述

## 计划修复
- [ ] 优先级高：...
- [ ] 优先级中：...
```

## 7. 下一版本规划

- [ ] 暗色模式图标优化
- [ ] 支持自定义捐款通道（支付宝、微信）
- [ ] 搜索性能优化
- [ ] 国际化（英文）
- [ ] iCloud 同步（可选）

---

**更新日期**：2026-10-29
**当前版本**：1.8.1
**维护者**：huaziyi
**联系方式**：15665874885@163.com
