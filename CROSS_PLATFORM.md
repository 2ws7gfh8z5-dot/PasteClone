# 跨平台客户端

PasteClone 现在包含一个 Rust + egui 客户端，目标是让 Windows 10/11 与主流 Linux 桌面保持一致的剪贴板体验。

## 已实现的跨平台 MVP

- 纯文本剪贴板自动记录、SHA-256 去重与 JSON 持久化
- 搜索、固定、删除、清除未固定记录
- `Ctrl+Shift+V` 全局呼出并聚焦窗口
- 每条记录的“粘贴”按钮：隐藏窗口、恢复此前编辑器焦点、写入剪贴板并模拟平台粘贴键
- 键盘导航：`↑/↓` 选择、`Enter` 粘贴、`Esc` 隐藏、`Ctrl/⌘+F` 搜索、`Ctrl/⌘+P` 固定、`Ctrl/⌘+1…9` 快速粘贴、`Delete` 删除
- Windows portable ZIP 与 Linux x86_64 tar.gz 由 GitHub Actions 构建

## 平台边界

macOS 原生 SwiftUI/AppKit 客户端仍提供最完整能力（图片、富文本、文件、菜单栏与权限设置）。Rust 客户端当前聚焦纯文本 MVP；Linux Wayland 的全局热键和输入注入可能受桌面环境与权限限制，遇到限制时请使用窗口内按钮。Windows/Linux 包只有在对应 GitHub Actions 构建成功后才视为可下载版本。

## 构建

```bash
cargo test --manifest-path CrossPlatformClient/Cargo.toml
cargo build --release --manifest-path CrossPlatformClient/Cargo.toml
```
