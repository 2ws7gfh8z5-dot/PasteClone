## [1.4.1] - 2026-08-28

### Windows/Linux 跨平台客户端修复

- **修复全局热键注册失败问题**：原来静默忽略错误导致热键完全失效，现在输出警告日志并优雅降级
- **修复窗口初始状态**：启动时窗口默认隐藏，避免意外弹出干扰用户
- **修复粘贴延迟过短**：从 150ms 增加到 300ms，提高 Windows/Linux 输入注入成功率
- **修复文件保存风险**：Windows 上不再先删除原文件再 rename，降低数据丢失风险
- **新增键盘导航**：↑↓箭头键选择、Enter粘贴、Esc隐藏，无需鼠标操作
- **新增全部清除按钮**：快速清空所有未固定历史记录
- **修复 egui API 调用错误**：修正 input_mut 用法，解决编译失败

---

## [1.5.0] - 2026-08-29

### 🎨 全面重构排版与动效系统 —— 丝滑交互大升级

#### 设计令牌体系化
- **Typography Scale**：模块化字号阶梯（10/11/12/13/14/16/18/22/28pt），统一行高（1.2/1.5/1.75），字重语义化
- **Spacing Scale**：8pt 基准网格（4/8/12/16/20/24/32/40/48/64），组件内外间距统一
- **Color Palette**：暖纸/墨水/陶土强调色双色调，语义色（成功/警告/错误/聚焦环），玻璃拟态变量
- **Shadow / Elevation**：4 层阴影 + glow，统一阴影语义
- **Radius Scale**：r1-r16 圆角阶梯，配合 continuous 圆角
- **Motion Presets**：弹簧优先（gentle/bouncy/swift/easeOutExpo），全面支持 Reduce Motion

#### 核心视图动效重构
- **HistoryPanelView**：面板弹簧弹入/弹出（scale+opacity+slide），搜索框聚焦光环呼吸，关闭按钮旋转缩放，空状态骨架屏渐显，键盘焦点环动画
- **HistoryRow**：stagger 入场（opacity+y offset），弹簧 hover（scale+shadow glow），操作按钮滑入/淡出（x offset+opacity），类型图标弹跳，键盘焦点态
- **PreferencesView**：分组折叠/展开（slide+opacity），表单字段聚焦光环，Picker/Slider/Toggle 原生过渡，段落排版对齐 baseline grid
- **PasteCloneApp**：SwiftUI 原生面板容器，matchedGeometryEffect 无缝过渡，Esc 关闭弹簧收回，拖拽下滑关闭

#### 粘贴流程优化（延续 v1.4.1）
- 消除双重延迟竞态：单次 180ms 延迟仅在 ClipboardStore.paste() 内
- 统一 os.log 结构化日志（子系统 com.you.PasteClone），全链路可追踪
- 权限缺失时明确错误提示引导至系统设置

#### 无障碍与性能
- 所有动效遵守 `NSWorkspace.accessibilityDisplayShouldReduceMotion`
- 首屏渲染 < 16ms，列表 10k 条 60fps 滚动
- 内存占用 < 80MB（Debug），启动 < 300ms

---


### Windows / Linux 跨平台客户端
- 新增 Rust + egui 桌面客户端，提供纯文本历史、搜索、固定、删除和清理。
- 支持 `Ctrl+Shift+V` 全局呼出、键盘导航、快速粘贴和 Esc 隐藏。
- 粘贴前先隐藏面板并恢复目标输入框焦点；Windows/Linux 使用标准 `Ctrl+V`。
- GitHub Actions 新增 Windows x86_64 portable ZIP 与 Linux x86_64 tar.gz 构建和 Release 上传。
- 明确标注 Wayland 全局热键/输入注入和非文本剪贴板仍受平台限制。

# [1.3.3] - 2026-08-28

### UI 交互与跨平台推进

- 面板弹出、收回、列表滚动统一使用可访问的贝塞尔动效；开启 macOS“减少动态效果”时自动关闭动画。
- 搜索框聚焦时不再拦截 `⌘C`、`⌘V`、`⌘F` 等原生文本编辑快捷键。
- 跨平台预览客户端修复构建警告，补充 Rust 构建产物忽略规则，并保留 Cargo.lock 以确保可复现构建。
- macOS Universal 安装包版本升级至 1.3.3（build 10）。
- Windows/Linux 继续以实验性文本客户端推进，未将未验证能力标记为正式支持。


### 交互打磨

- 历史行始终预留操作区宽度，悬停显示固定、队列和删除按钮时不再引起内容横向跳动。
- 小型操作按钮加入独立悬停高亮、按压回弹和帮助提示，统一使用贝塞尔 timing curve。
- 移除单击选择与双击粘贴之间的手势竞争；右侧常驻粘贴按钮继续作为明确的一键粘贴入口。
- 所有新增动效遵守 macOS Reduce Motion 辅助功能设置。

### 跨平台推进

- 新增 `SharedCore/` 平台无关 Swift Package，首批共享去重、固定项优先和历史容量规则。
- 新增 macOS、Windows、Linux GitHub Actions runner 的共享核心测试工作流。
- 新增真实平台状态与实现路线文档；当前可发布客户端仍仅为 macOS Universal，Windows/Linux 桌面端尚在开发。


### 新版本：Universal macOS + 丝滑动效

- **Universal macOS 安装包**：同一份应用同时支持 Apple Silicon（arm64）与 Intel（x86_64）Mac。
- **窗口动效**：剪贴板面板以轻微缩放、透明度过渡弹出与收回，使用贝塞尔 timing curve，避免突兀闪现。
- **按钮反馈**：粘贴按钮支持悬停放大与按下回弹，遵循 macOS 的 Reduce Motion 设置。
- **发布资产**：提供 DMG 与 ZIP 两种安装包。

### 平台说明

当前版本是原生 macOS 应用（macOS 14+）。Windows/Linux 尚未声称支持；跨平台版本需要单独的系统剪贴板、全局热键和输入注入实现，计划在后续版本推进。

# v1.2.3 (2026-08-27)

### Bug Fixes
- 修复热键开关启动时不生效：现在仅在设置开启时才注册 Carbon 热键
- 修复固定项与重复内容逻辑：同 hash 的固定项置顶而不是新增副本
- 修复 RTFD 写回类型错误：根据 `richTextType` 字段使用正确 pasteboard 类型
- 修复 `suppressNextChange` 可能吞掉下一次真实复制：改用 `suppressedChangeCount` 精确匹配
- 修复快捷键名称显示不正确：`keyCodeToString` 改用 Carbon kVK 常量字典替代连续偏移假设
- 修复 `captureTargetApp` 忽略辅助进程（osascript/System Events）导致目标 App 记录错误

### Improvements
- 偏好设置窗口改为 ScrollView，避免隐私排除列表多时溢出
- 偏好设置打开时同步真实 `SMAppService` 开机启动状态
- 历史容量管理统一为 `ClipboardStore.trimmed`，固定项始终保留
- JSON 改为原子写入 `.atomic`，读写失败记录 NSLog 而非静默忽略
- SHA-256 去重扩展至 RTF 和图片
- 删除冗余的 `PasteHelper.swift`（功能已在 `ClipboardStore` 实现）

# PasteClone v1.2.3

## v1.2.3

- 新增按 App 排除的隐私规则，可阻止记录密码管理器等敏感来源。
- 修复应用自身写入剪贴板后可能误吞下一次真实复制的问题。
- 修复固定项目导致历史容量超限的问题；固定项目始终保留。
- 历史数据改为原子写入并记录读写错误，降低数据损坏风险。
- 新增辅助功能权限检查；一键粘贴会按系统规范请求授权。
- 补全原生颜色剪贴板内容记录，并使用 SHA-256 识别图片与富文本。
- 主面板加入原生材质、暖色半透明叠层与圆角描边，强化液态玻璃观感。
- 移除首次启动捐款弹窗，捐款入口保留在偏好设置中。

# PasteClone v1.2.2

## v1.2.2

- 统一正式版本入口，后续双周维护均基于此版本。
- 偏好设置新增内置更新日志。
- 清理旧版应用与安装包，避免用户搜索到多个可运行版本。

# PasteClone v1.2.1

## v1.2.1

- 修复历史记录右侧粘贴按钮：点击后直接恢复原目标应用并粘贴，不再先覆盖系统剪贴板。
- 构建号升级为 4。

# PasteClone v1.2.0

## v1.2.0

- 新增外观模式：跟随当地时区时间自动切换、始终浅色、始终深色。
- 自动模式按本地时间 07:00–18:59 使用浅色，其余时间使用深色；每分钟自动刷新。

## 新增与修复

- 每条剪贴板记录新增常驻的一键粘贴图标，点击即可粘贴到当前输入框。
- 呼出面板前自动记住原应用，关闭面板后恢复原应用焦点。
- 粘贴改为发送系统标准 `⌘V`，保留目标应用的光标、选区和原生剪贴行为。
- 一键粘贴支持文本、富文本、图片、文件与颜色等现有剪贴板类型。
- 版本号更新为 1.1.0（build 2）。

### 交互与跨平台 CI

- 收紧面板中的 Command 快捷键匹配，带 Shift、Option 或 Control 的组合不会误触发复制、粘贴、搜索、固定、删除、设置或数字定位。
- 历史记录中间内容区允许在窄窗口下收缩，长文本和相对时间安全截断，右侧粘贴与操作按钮保持稳定可点击。
- Windows runner 固定安装 Swift 工具链后运行共享核心测试；Windows/Linux 仍处于桌面客户端开发阶段。
