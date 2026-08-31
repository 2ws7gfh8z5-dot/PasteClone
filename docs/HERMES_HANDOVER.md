# PasteClone / Just Paste — Hermes 双周维护任务交接书

> 生效日期：2026-08-29 · 交接自 Codex 定时任务 `pasteclone`（已取消）
> 唯一正式源工程：`/Users/huaziyi/Desktop/pasteclone`（main 分支）
> 本机唯一正式安装：`/Applications/Just Paste.app`（已更名为 Just Paste，v1.6.0）
> GitHub 仓库：https://github.com/2ws7gfh8z5-dot/PasteClone

## 调度

- **每两周一次，周六 20:00（Asia/Shanghai）**
- 建议 cron 表达式：`0 20 * * 6` + 双周间隔（若不支持双周间隔，用 `0 20 1,15 * *` 每月 1 号/15 号 20:00 近似）
- 建议 hermes cron 命令（一次性创建）：
  ```bash
  hermes cron create "0 20 * * 6" --name "pasteclone-biweekly-maintenance" \
    --workdir /Users/huaziyi/Desktop/pasteclone \
    --skill ponytail --skill computer-use \
    "读取 /Users/huaziyi/Desktop/pasteclone/docs/HERMES_HANDOVER.md 并按其中清单执行双周维护"
  ```
  （把本文档作为单次权威 prompt；每次运行先读它，避免 prompt 漂移。）

## 每次执行清单（按顺序，缺一不可）

1. **读档**：读本文件 + `CHANGELOG.md` 最新版本 + `docs/biweekly-report/` 上一份报告（若有）
2. **检查邮件**：打开 https://mail.163.com（已登录会话），搜关键词 `pasteclone` / `paste` / `clipboard`，提取反馈（类型/平台/优先级/描述）；需重新登录则跳过并记录原因
3. **代码自检与修复**：
   - `git status` 确认在 main 最新提交
   - macOS：`xcodebuild -project PasteClone.xcodeproj -scheme PasteClone build`（Debug 快速验证）
   - 跨平台 Rust 客户端：`cd CrossPlatformClient && cargo check && cargo test --release`
   - 按邮件反馈逐项修复；无反馈则做基础自检（剪贴板监听、持久化、快捷键、粘贴队列、目标应用粘贴）
4. **GitHub 巡检**：仓库 Issues / PR / Discussions / 评论；记录 star 数变化；更新 README（如有新特性）
5. **构建与安装**：`xcodebuild -configuration Release` 后用 `ditto` 覆盖 `/Applications/Just Paste.app`，`codesign --force --deep --sign -` 重签名；确保 Spotlight 只搜到这一个正式版本
6. **发布**：递增 Patch 版本号 → 更新 `CHANGELOG.md` → 打 tag `vX.Y.Z` → `gh release create` 上传 macOS zip（Windows/Linux 以 GitHub Actions 构建为准）
7. **邮件回复**：对每封反馈邮件写简洁中文回复发送；无法登录邮箱则草稿存 `/tmp/pasteclone_email_replies/YYYY-MM-DD.md`
8. **写报告**：`/Users/huaziyi/Desktop/pasteclone/docs/biweekly-report/YYYY-MM-DD.md` —— 邮件摘要、修复列表、GitHub 处理情况、star 变化、版本号与变更、待办

## 红线（不做）

- 不从未知副本合并/构建；只认 `/Users/huaziyi/Desktop/pasteclone` 的 main
- 不进行未经授权的自动发帖、营销、评论
- 需要人工授权/登录/验证码/付费的步骤：记录原因并跳过，不硬闯
- 不把密码、令牌、密钥写入任何文件或 Obsidian 记忆库

## 相关文件索引

| 内容 | 路径 |
|---|---|
| 源工程 | `/Users/huaziyi/Desktop/pasteclone` |
| Xcode 工程 | `PasteClone.xcodeproj`（scheme: PasteClone） |
| 跨平台客户端 | `CrossPlatformClient/`（Rust + egui） |
| 更新日志 | `CHANGELOG.md` |
| 双周报告目录 | `docs/biweekly-report/` |
| 用户手册 | `MANUAL.md` / `USER_GUIDE.md` |
| 快捷键清单 | `KEYBOARD_SHORTCUTS.md` / `SHORTCUTS.md` |
| 图标源图 | `/Users/huaziyi/Desktop/download.png` |
| 本机安装 | `/Applications/Just Paste.app` |

## 上下文要点（2026-08-29 快照）

- 当前版本 **v1.6.0**：更名 Just Paste、Anthropic 手绘风图标、面板不透明度 0.92 修复可读性
- 设计系统：`PasteClone/Views/Theme.swift` 的 `PCTokens`（v1.5.0 引入，替代旧 PCTheme）
- 面板快捷键：⇧⌘V 呼出；⌘C/⌘V 系统默认；所有快捷键用户可在偏好设置中自定义
- 已知待办：Windows/Linux 全局热键暂时降级为窗口内 Ctrl+Shift+V（依赖兼容问题），下个双周版本恢复
- GitHub 已发布 Release v1.6.0（含 macOS zip）
