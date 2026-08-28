# PasteClone 🚀

一个跨平台的剪贴板管理工具（macOS 原生版 + Windows/Linux 客户端），让复制粘贴变得简单丝滑。

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.0+](https://img.shields.io/badge/Swift-5.0%2B-orange)
![License MIT](https://img.shields.io/badge/License-MIT-green)

---

## ✨ 主要特性

- 📋 **剪贴板历史** - macOS 原生客户端保存文本、富文本、图片、文件和颜色；Windows/Linux 客户端当前保存纯文本
- ⌨️ **全局快捷键** - macOS 支持自定义；Windows/Linux 提供基础快捷键
- 🎯 **一键粘贴** - 点击历史项自动粘贴到前台应用（需平台允许输入注入）
- 📌 **智能组织** - macOS 支持收藏夹、置顶、搜索和按应用过滤；跨平台客户端支持置顶与搜索
- 🎨 **Anthropic 手绘风格** - 暖色系 UI，舒适视觉体验
- 🔧 **系统集成** - 菜单栏驻留，开机启动支持

## 🌓 v1.2.0 外观模式

偏好设置支持三种外观：

- **跟随时间**：使用系统当前时区，07:00–18:59 为浅色，其余时间为深色；
- **始终浅色**；
- **始终深色**。

自动模式每分钟检查一次时间，不需要重启应用。

## 🖥️ 平台能力边界

### macOS 原生客户端（完整功能）

支持图片、RTF/RTFD、文件、颜色、菜单栏、开机启动、隐私排除、收藏夹、粘贴队列、自定义快捷键和自动/浅色/深色主题。提供 Apple Silicon + Intel Universal 安装包，最低 macOS 14。

### Windows/Linux 客户端（v1.4.0 MVP）

Rust + egui 客户端目前支持纯文本历史、持久化、搜索、置顶、删除、清理未置顶、基础全局热键、键盘导航和一键粘贴。暂不包含 macOS 客户端的图片、富文本、文件、托盘、隐私排除、收藏夹、粘贴队列和设置页面；Linux Wayland 的热键与输入注入取决于桌面权限。请以 GitHub Actions 成功构建的 Release 资产为准。

---

## 🆕 v1.1.0 一键粘贴

每条历史记录右侧都有常驻的粘贴图标。打开面板后点击它，PasteClone 会关闭面板、恢复你呼出面板前正在使用的应用，并通过系统标准 `⌘V` 将内容插入当前光标或替换选区。

![PasteClone 一键粘贴面板](docs/screenshots/paste-action-v1.1.0.png)

## 🚀 快速开始

### 安装

1. 从 [Release 页面](https://github.com/2ws7gfh8z5-dot/PasteClone/releases) 下载 `PasteClone.dmg`
2. 将 `PasteClone.app` 拖入 Applications 文件夹
3. 启动应用，根据提示授予 Accessibility 权限

### 首次使用

1. 打开 PasteClone，应用会进入菜单栏
2. 按 `⇧⌘V` 打开剪贴板历史
3. 复制任意内容，自动记录到历史
4. 点击历史项右侧的粘贴图标，将内容直接输入前台应用

---

## ⌨️ 快捷键

| 操作 | 默认快捷键 |
|------|-----------|
| 打开历史 | `⇧⌘V` |
| 粘贴 | `↩` |
| 复制 | `⌘C` |
| 删除 | `⌫` |
| 置顶 | `⌘P` |
| 搜索 | `⌘F` |
| 快速选择 | `⌘1`~`⌘9` |

👉 [完整快捷键指南](./KEYBOARD_SHORTCUTS.md)

---

## 📚 功能详解

### 剪贴板历史
- 自动监控和保存所有复制内容
- 支持文本、RTF、图片、文件、颜色
- 去重：自动识别重复内容
- 按应用名称搜索

### 收藏夹与置顶
- 创建自定义收藏夹分类
- 置顶重要项目（不会被清除）
- 独立管理收藏夹

### 快捷键系统
- 3 个预设快捷键随意切换
- 完全自定义任意按键组合
- 在偏好设置中实时编辑

### 粘贴队列
- 堆栈式粘贴多个项目
- 按顺序依次应用到前台应用

👉 [详细功能列表](./FEATURES.md)

---

## 💰 支持开发

PasteClone 是免费开源项目。如果您觉得有帮助，考虑支持开发：

- 🌟 GitHub 上点个 Star
- 💬 反馈建议和 Bug 报告
- 📧 邮箱联系：[15665874885@163.com](mailto:15665874885@163.com)
- 🎁 通过 GitHub Sponsors 捐赠

---

## 🔧 系统需求

- **macOS 14.0** 或更新版本（Universal：Apple Silicon + Intel）
- **Windows 10/11 x86_64**：portable ZIP
- **Linux x86_64**：tar.gz；Wayland 能力取决于桌面权限
- **Accessibility 权限** - 用于全局快捷键监听

---

## 📝 许可证

MIT License - 详见 [LICENSE](./LICENSE)

---

## 🔗 链接

- [GitHub 仓库](https://github.com/2ws7gfh8z5-dot/PasteClone)
- [Release 下载](https://github.com/2ws7gfh8z5-dot/PasteClone/releases)
- [问题反馈](https://github.com/2ws7gfh8z5-dot/PasteClone/issues)

---

**PasteClone** - 让剪贴板管理变得优雅 ✨

## v1.4.0 发布说明（2026-08-28）

- **四平台发布**：提供 macOS Universal（Apple Silicon + Intel）、Windows 10/11 x86_64 和 Linux x86_64 安装包。
- **Windows/Linux 文本客户端**：支持文本历史、搜索、置顶、删除、清理、一键粘贴、键盘导航和 `Ctrl+Shift+V` 全局呼出。
- **原生平台验证**：Windows 与 Linux 安装包均由 GitHub Actions 对应系统 runner 测试和构建。
- **平台边界**：macOS 是完整客户端；Windows/Linux 当前为纯文本 MVP，暂不支持图片、富文本、文件、Collections、粘贴队列、隐私规则、托盘和完整设置页。
- **Linux 提示**：Wayland 下全局快捷键和输入注入受桌面环境及权限限制，X11 通常更稳定。

## v1.3.3 发布说明（2026-08-28）

- **交互更顺滑**：面板和列表滚动采用贝塞尔曲线；遵循 macOS“减少动态效果”。
- **输入不冲突**：搜索框聚焦后，`⌘C`、`⌘V`、`⌘F` 等交给系统文本编辑器处理。
- **跨平台推进**：新增可编译的 Windows/Linux 实验性 Rust 客户端，当前覆盖纯文本历史、搜索、固定、清除和一键粘贴。
- **平台边界**：macOS 仍是唯一完整正式客户端；Windows/Linux 尚未覆盖富文本、图片、文件、隐私规则、托盘和正式安装包。

## v1.3.2 发布说明（2026-08-28）
- 快捷键防误触：仅单独的 Command 组合会触发面板命令，带其他修饰键的组合不再误操作。
- 窄窗口布局：长文本与时间信息会安全截断，右侧一键粘贴和操作按钮不被挤压。
- 跨平台 CI：Windows runner 已配置 Swift 工具链并验证共享核心；Windows/Linux 完整桌面客户端仍在开发中。

## v1.3.1 发布说明（2026-08-28）
- 交互稳定性：历史行操作区始终预留宽度，悬停按钮出现时内容不再横向跳动。
- 操作反馈：固定、队列、删除按钮加入悬停与按压贝塞尔动效，并尊重 Reduce Motion。
- 防误触：移除列表行单击选择与双击粘贴的手势竞争；使用右侧常驻粘贴按钮可一键输入目标应用。
- macOS Universal：同一安装包支持 Apple Silicon 与 Intel，要求 macOS 14+。
- 跨平台基础：新增平台无关历史策略 Swift Package，并在 macOS、Windows、Linux CI runner 上验证共享规则。
- Windows/Linux：桌面客户端仍在开发，当前尚无可用安装包；请勿将 macOS 安装包用于其他系统。
- 安装包：GitHub Releases 提供 `.dmg` 与 `.zip`。
