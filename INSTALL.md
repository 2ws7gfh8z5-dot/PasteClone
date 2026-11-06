# PasteClone 安装指南

## 系统要求
- macOS 14.0+ (Sonoma)
- Apple Silicon (M1/M2/M3) 或 Intel Mac

> Linux 版本自 1.8.0 起暂停更新，不再发布新的 Linux 构建，本指南只覆盖 macOS。

## 安装方法

### 方法 1: 直接下载应用 (推荐)

1. 打开 [最新 Release 页面](https://github.com/2ws7gfh8z5-dot/PasteClone/releases/latest)，在 Assets 里下载文件名以 `macos-universal.dmg` 结尾的安装包
2. 双击打开 DMG，把 `Just Paste.app` 拖进「应用程序」文件夹
3. 首次打开时右键点击应用 →「打开」→ 再点一次「打开」（应用未公证，直接双击会被系统拦下）
4. 按提示授予**辅助功能**权限，否则一键粘贴不生效

### 方法 2: 使用命令行编译

```bash
# 1. 克隆仓库到任意目录
git clone https://github.com/2ws7gfh8z5-dot/PasteClone.git
cd PasteClone

# 2. 生成 Xcode 项目
xcodegen generate

# 3. 编译并运行（脚本会自动编译 Debug 版并打开）
bash script/build_and_run.sh
```

### 方法 3: 从源码运行

```bash
# 在上一步克隆下来的仓库目录里执行
open PasteClone.xcodeproj
# 在 Xcode 中按 Cmd+R 运行
```

## 首次使用

1. **启动应用**: 双击 `Just Paste.app` 或通过命令行运行
2. **授予权限**: 首次一键粘贴时系统会提示**辅助功能**权限（用于模拟 `⌘V`）。全局热键用 Carbon 注册，不需要这个权限
3. **使用热键**: 默认热键 `⇧⌘V` (Shift+Cmd+V)
4. **搜索历史**: 在面板中输入关键词（子序列模糊匹配，不支持拼音）
5. **粘贴内容**: 按 `Enter` 或数字键 `1-9` 快速粘贴

## 设置

点击菜单栏图标 → 偏好设置，可以配置：
- 开机启动
- 保留条目数（默认 1000）与保留时长（默认永久）
- 快捷键预设与自定义组合
- 外观模式（跟随时间 / 浅色 / 深色）
- 按 App 排除的隐私规则
- 导入 / 导出历史

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `⇧⌘V` | 唤起/隐藏面板 |
| `↑` `↓` | 导航列表 |
| `Enter` | 粘贴选中项 |
| `1-9` | 快速粘贴前9项 |
| `Esc` | 关闭面板 |
| `Cmd+,` | 打开设置 |

## 故障排除

### 应用无法启动
- 检查是否授予了辅助功能权限
- 系统设置 → 隐私与安全性 → 辅助功能 → 添加 `Just Paste.app`

### 热键不响应
- 检查是否与系统快捷键冲突
- 在偏好设置 → 快捷键中重新绑定热键或在「全局热键」开关处确认已启用

### 剪贴板没有记录
- 检查是否在排除应用列表中
- 确认没有处于"暂停捕获"状态
- 查看菜单栏图标状态

### 搜索不到内容
- 复制后等约 0.4 秒让监听器捕获
- 检查搜索词是否正确
- 尝试清空搜索框查看完整列表

## 卸载

1. 退出应用（菜单栏 → 退出）
2. 删除应用: `rm -rf "/Applications/Just Paste.app"`
3. 删除数据: `rm -rf ~/Library/Application\ Support/PasteClone`
4. 删除偏好设置: `defaults delete com.you.justpaste`

## 反馈与支持

- 提交 Issue: https://github.com/2ws7gfh8z5-dot/PasteClone/issues
- 提交 PR: https://github.com/2ws7gfh8z5-dot/PasteClone/pulls

## License

MIT License
