# PasteClone

PasteClone 是一款原生 macOS 剪贴板历史管理器：它在后台记录复制过的文本、图片、文件和富文本，并通过菜单栏或全局快捷键快速搜索、预览、固定和粘贴历史内容。

> 当前版本：1.0.0 · macOS 14 Sonoma 或更高版本 · Apple Silicon / Intel Mac

## 快速开始

1. 用 Xcode 打开 `PasteClone.xcodeproj`。
2. 选择 `PasteClone` scheme，运行到本机 Mac。
3. 应用启动后会出现在菜单栏，不会占用 Dock 位置。
4. 复制一段文字，再按 `⇧⌘V` 打开历史面板，选择内容并按 `Enter` 粘贴。

完整使用说明见：[用户使用说明书](USER_GUIDE.md)。

## 主要功能

- 自动记录文本、图片、文件、RTF/RTFD 富文本和颜色剪贴板内容
- 历史搜索、按来源应用搜索、固定重要内容
- 收藏分类与筛选
- 双击、回车或右键粘贴
- 粘贴队列（按顺序逐项粘贴）
- 全局 `⇧⌘V` 快捷键呼出历史面板
- 可设置历史保留数量、开机启动和全局热键
- 本地 JSON 持久化，不需要账号，不上传剪贴板数据

## 开发与构建

项目使用原生 SwiftUI/AppKit 和 XcodeGen，不依赖第三方库。已有 `.xcodeproj` 可直接持续开发：

```bash
xcodebuild -project PasteClone.xcodeproj \
  -scheme PasteClone \
  -configuration Debug \
  -sdk macosx build \
  CODE_SIGNING_ALLOWED=NO
```

源代码按 `Models`、`Services`、`Views` 分组。剪贴板历史默认保存在：

`~/Library/Application Support/PasteClone/history.json`

## 注意

- PasteClone 只能记录应用启动之后发生的新复制操作；不会读取启动前的系统历史。
- 自动粘贴依赖 macOS 向前台应用发送 `⌘V`。如果目标应用不接受模拟键盘事件，请使用面板中的复制/粘贴流程或在目标应用手动按 `⌘V`。
- 请只在可信的本机环境运行剪贴板管理器，因为剪贴板可能包含密码、验证码和隐私信息。
