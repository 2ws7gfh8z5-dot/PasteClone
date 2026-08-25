# PasteClone 安装指南

## 系统要求
- macOS 14.0+ (Sonoma)
- Apple Silicon (M1/M2/M3) 或 Intel Mac

## 安装方法

### 方法 1: 直接下载应用 (推荐)

1. 访问 GitHub 仓库: https://github.com/2ws7gfh8z5-dot/PasteClone
2. 点击 "Code" → "Download ZIP"
3. 解压后打开 `PasteClone/PasteClone.xcodeproj`
4. 在 Xcode 中按 `Cmd+R` 编译运行

### 方法 2: 使用命令行编译

```bash
# 1. 克隆仓库
git clone https://github.com/2ws7gfh8z5-dot/PasteClone.git
cd PasteClone

# 2. 生成 Xcode 项目
xcodegen generate

# 3. 编译应用
xcodebuild -project PasteClone.xcodeproj -scheme PasteClone build CODE_SIGNING_ALLOWED=NO

# 4. 运行应用
open build/Debug/PasteClone.app
```

### 方法 3: 从源码运行

```bash
cd /Users/huaziyi/Desktop/PasteClone
open PasteClone.xcodeproj
# 在 Xcode 中按 Cmd+R 运行
```

## 首次使用

1. **启动应用**: 双击 `PasteClone.app` 或通过命令行运行
2. **授予权限**: 首次运行时，系统会提示需要：
   - 辅助功能权限（用于全局热键）
   - 剪贴板访问权限
3. **使用热键**: 默认热键 `⌃⌥⇧V` (Ctrl+Opt+Shift+V)
4. **搜索历史**: 在面板中输入文本、拼音或类型关键词
5. **粘贴内容**: 按 `Enter` 或数字键 `1-9` 快速粘贴

## 设置

点击菜单栏图标 → 设置，可以配置：
- 热键组合
- 历史保留条数（默认 1000）
- 历史保留天数（默认 140）
- 排除应用列表
- 显示/隐藏菜单栏图标
- 深色/浅色模式

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `⌃⌥⇧V` | 唤起/隐藏面板 |
| `↑` `↓` | 导航列表 |
| `Enter` | 粘贴选中项 |
| `1-9` | 快速粘贴前9项 |
| `Esc` | 关闭面板 |
| `Cmd+,` | 打开设置 |

## 故障排除

### 应用无法启动
- 检查是否授予了辅助功能权限
- 系统设置 → 隐私与安全性 → 辅助功能 → 添加 PasteClone

### 热键不响应
- 检查是否与系统快捷键冲突
- 在设置中重新绑定热键
- 确保应用在前台有权限监听全局热键

### 剪贴板没有记录
- 检查是否在排除应用列表中
- 确认没有处于"暂停捕获"状态
- 查看菜单栏图标状态

### 搜索不到内容
- 等待 1-2 秒让监控器捕获
- 检查搜索词是否正确
- 尝试清空搜索框查看完整列表

## 卸载

1. 退出应用（菜单栏 → 退出）
2. 删除应用: `rm -rf ~/Applications/PasteClone.app`
3. 删除数据: `rm -rf ~/Library/Application\ Support/PasteClone`
4. 删除偏好设置: `rm -rf ~/Library/Preferences/com.you.PasteClone.plist`

## 反馈与支持

- 提交 Issue: https://github.com/2ws7gfh8z5-dot/PasteClone/issues
- 提交 PR: https://github.com/2ws7gfh8z5-dot/PasteClone/pulls

## License

MIT License
