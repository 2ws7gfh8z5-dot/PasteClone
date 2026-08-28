# PasteClone 跨平台状态与路线

## 当前可用

| 平台 | 状态 | 安装包 |
| --- | --- | --- |
| macOS Apple Silicon | 可用（macOS 14+） | DMG / ZIP |
| macOS Intel | 可用（macOS 14+） | 同一 Universal DMG / ZIP |
| Windows | 开发中，尚无可用客户端 | 暂无 |
| Linux | 开发中，尚无可用客户端 | 暂无 |

macOS 客户端依赖 AppKit、`NSPasteboard`、Carbon 全局快捷键、Accessibility 与 `CGEvent`，不能直接在 Windows/Linux 上编译运行。本项目不会把 macOS 安装包标成其他平台版本。

## 已建立的全线推进基础

- `SharedCore/`：不依赖 AppKit 的 Swift Package，用于承载去重、历史限制、固定项、搜索/排序、数据迁移等共享规则。
- `.github/workflows/cross-platform-core.yml`：在 macOS、Ubuntu、Windows 三种 runner 上测试共享核心，防止后续重新引入平台耦合。
- macOS 原生客户端保留现有成熟系统集成，不为跨平台重写已经工作的功能。

## 后续平台外壳

### Windows

1. Windows Clipboard API：文本、HTML/RTF、图片、文件。
2. `RegisterHotKey` 全局快捷键与前台窗口恢复。
3. `SendInput` 粘贴注入；首次使用明确解释权限与隐私。
4. Windows App SDK 界面、托盘图标、开机启动和 MSIX 安装包。

### Linux

1. 优先分别实现 Wayland 与 X11 剪贴板适配，不能假设二者行为相同。
2. 桌面环境支持时注册 Global Shortcuts portal；X11 使用对应热键实现。
3. Wayland 输入注入遵循桌面 portal/权限模型；不通过绕过安全边界实现。
4. 提供 Flatpak；之后按需求补 AppImage/deb/rpm。

## 完成标准

平台只有在真实系统 runner 或设备完成以下流程后才能标记“支持”：复制监控、历史恢复、全局呼出、搜索选择、粘贴到原应用、重启持久化、权限失败提示、安装/卸载和自动更新检查。
