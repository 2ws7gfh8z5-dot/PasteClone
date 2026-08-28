# PasteClone 🚀

一个优雅的 macOS 剪贴板管理工具，让复制粘贴变得简单丝滑。

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.0+](https://img.shields.io/badge/Swift-5.0%2B-orange)
![License MIT](https://img.shields.io/badge/License-MIT-green)

---

## ✨ 主要特性

- 📋 **完整剪贴板历史** - 保存最多 1000+ 条记录，支持文本、图片、文件
- ⌨️ **全局快捷键** - 3 个预设快捷键 + 完全自定义
- 🎯 **一键粘贴** - 点击历史项自动粘贴到任何应用
- 📌 **智能组织** - 收藏夹、置顶、搜索、按应用过滤
- 🎨 **Anthropic 手绘风格** - 暖色系 UI，舒适视觉体验
- 🔧 **系统集成** - 菜单栏驻留，开机启动支持

## 🌓 v1.2.0 外观模式

偏好设置支持三种外观：

- **跟随时间**：使用系统当前时区，07:00–18:59 为浅色，其余时间为深色；
- **始终浅色**；
- **始终深色**。

自动模式每分钟检查一次时间，不需要重启应用。

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

- **macOS 14.0** 或更新版本
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

## v1.3.1 发布说明（2026-08-28）
- 交互稳定性：历史行操作区始终预留宽度，悬停按钮出现时内容不再横向跳动。
- 操作反馈：固定、队列、删除按钮加入悬停与按压贝塞尔动效，并尊重 Reduce Motion。
- 防误触：移除列表行单击选择与双击粘贴的手势竞争；使用右侧常驻粘贴按钮可一键输入目标应用。
- macOS Universal：同一安装包支持 Apple Silicon 与 Intel，要求 macOS 14+。
- 跨平台基础：新增平台无关历史策略 Swift Package，并在 macOS、Windows、Linux CI runner 上验证共享规则。
- Windows/Linux：桌面客户端仍在开发，当前尚无可用安装包；请勿将 macOS 安装包用于其他系统。
- 安装包：GitHub Releases 提供 `.dmg` 与 `.zip`。
