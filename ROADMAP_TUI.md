# TUI Roadmap (Cross‑platform: Windows / Linux / macOS / Unix)

目标：打造一套跨平台、现代化的终端 UI 框架，最终观感与交互对标 Gemini CLI / Claude Code 等一线 CLI 产品；在体验上做到布局稳定、渲染丝滑、输入自然、组件丰富、主题统一，并具备良好的可扩展性与工程化质量。


## I. 顶层目标（What “Good” Looks Like）
- 跨平台一致性：Windows（含 ConPTY/VT）、Linux、macOS、Unix 终端一致体验
- 稳定布局：快速 resize / 拖动滚动条不乱版、不抛错、不残影
- 丝滑渲染：双缓冲 + 脏区/差量渲染，消除闪烁；长列表滚动流畅
- 组件齐备：列表/表格/树、输入框/TextArea、标签页、命令面板、对话框、菜单、日志视图等
- 现代交互：键盘可配置（Keymap）、焦点管理、粘贴（Bracketed Paste）、可选鼠标支持
- 主题与可定制：24bit 主题、语义化色板、状态样式（focus/active/hover/disabled）
- 强健文本：Unicode 宽度、Grapheme Cluster/Emoji、自动换行/截断/对齐
- 工程质量：完善单测/集成测试、跨平台 CI、文档与示例齐全


## II. 架构蓝图（Architecture Overview）
- Core/Term Abstraction（终端抽象层）
  - 功能探测（capabilities）、Alternate Screen、颜色深度、鼠标/粘贴模式
  - 统一键盘输入模型（修饰键、组合键、粘贴、IME 预留）
- Rendering Pipeline（渲染管线）
  - Model → Layout → Paint：双缓冲、脏区合成、裁剪、分层（overlay/popup）
  - 文本测量与换行：等宽优先，兼容 East Asian 宽度、Emoji、合字
- Layout Engine（布局引擎）
  - Flex/VBox/HBox、Grid、Min/Max、Padding/Margin、Overflow/Clip、ScrollContainer
- Components（组件层）
  - 核心：Panel、Label、StatusBar、Button、InputLine、TextArea、ListView（虚拟化）、Table、Tree、Tabs、Dialog、Menu、Command Palette、LogView
- Theming（主题层）
  - 语义化 Token（fg.primary/fg.muted/bg.surface/bg.elevated 等）+ 主题切换
- Platform Adapters（平台适配）
  - Windows（ConPTY/VT、QuickEdit、滚动缓冲策略）
  - Unix（termios、xterm/kitty/wezterm 等能力探测与降级）


## III. 里程碑（Milestones & Deliverables）

### M1 基础稳定（Week 1）
交付目标：不闪烁、不乱版、稳定可跑的基础 Demo（含 resize/滚动条场景）。
- 终端稳定性
  - [x] 窗口相对坐标（Windows）与清屏策略（仅清可视窗口）
  - [ ] 可选“无滚动条模式”：将缓冲区=窗口大小（进入/退出时还原）
  - [x] UI 光标/绘制全面 clamp 到当前窗口尺寸
- 渲染基线
  - [ ] 双缓冲（BackBuffer）与整屏 diff（第一版）
  - [ ] 简单脏区（按节点标记）
- 输入与事件
  - [x] Resize 触发重新布局与重绘
  - [ ] Bracketed Paste（Unix）与 Paste 兼容（Win）
  - [ ] 键位模型与 KeyMap（基础映射）
- 文档与工程
  - [x] Roadmap 文档（本文件）
  - [ ] 构建脚本与运行指南（doc/GettingStarted.md）

### M2 布局与滚动容器（Week 2）
交付目标：布局健壮、可滚动容器、长内容不卡顿。
- 布局增强
  - [x] VBox/HBox 分配 clamp 与末子项“吃剩余空间”修正
  - [ ] Min/Max/Preferred 尺寸约束，Overflow=Clip
  - [ ] ScrollContainer（垂直/水平）+ 裁剪
- 渲染增强
  - [ ] 脏区合成与分层裁剪（避免越界绘制）
  - [ ] 文本对齐（左/右/居中）、截断（…）与软换行
- 组件起步
  - [ ] ListView（虚拟化渲染）
  - [ ] StatusBar（多段信息/进度）
  - [ ] InputLine 升级（历史/导航）

### M3 组件库 v0.1（Week 3）
交付目标：做出“像 Gemini CLI / Claude Code”的典型界面 Demo。
- 组件扩展
  - [ ] Tabs、Dialog、Menu、Command Palette（命令面板）
  - [ ] LogView（自动滚动、追踪尾部）
  - [ ] TextArea（多行编辑、选区、简单撤销）
- 主题与观感
  - [ ] 主题 Token 与暗/亮主题
  - [ ] 状态样式（focus/active/hover/disabled）
  - [ ] 过渡/反馈（轻量，避免性能损耗）
- Demo 对标
  - [ ] 左侧导航 + 顶部标题 + 搜索/命令区 + 主内容 + 底部状态条（近似 Gemini/Claude 结构）

### M4 跨平台硬化与质量（Week 4）
交付目标：工程化质量、跨平台一致性、性能达标。
- 平台细节
  - [ ] Windows：ConPTY 首选；VT 降级路径；关闭 QuickEdit；缓冲锁定/还原
  - [ ] Unix：termios；xterm family 能力检测（颜色、鼠标、粘贴、真彩）
- 文本与国际化
  - [ ] 宽字符/Emoji/Grapheme 迭代（测量/截断/移动光标）
- 性能与测试
  - [ ] 大列表/连续输出性能压测（目标：60FPS 视觉流畅）
  - [ ] 单测（键盘解析、布局、渲染片段）、端到端用例、快照测试
  - [ ] CI：Windows/Linux/macOS 三平台矩阵

### 后续（M5+）
- Table/Tree 加强（列宽策略、固定列、增量渲染）
- 富交互：搜索/替换、选择/多选、抽屉/侧栏、通知/Toast
- 插件 API：命令注册、键位扩展、主题扩展
- 可视化调试：布局边界/脏区显示、渲染统计


## IV. 关键技术细节（Selected Design Notes）
- 双缓冲与差量渲染
  - 维护前后帧 buffer（二维字符 + 属性），对比差异，最小化 ANSI/WinAPI 输出
  - Windows 使用窗口相对坐标，Linux/macOS 使用 ANSI CSI 定位；都要避免“光标穿越裁剪边界”
- 脏区与裁剪
  - 每个节点维护脏标记；Layout 输出矩形树，Paint 只在可见且未被裁剪的区域绘制
- Unicode 宽度
  - 引入宽度计算（wcwidth 类似算法），对 East Asian 与 Emoji 做正确测量；对齐/截断基于显示宽度
- 输入模型
  - KeyEvent 统一为（type, rune, modifiers），粘贴事件单独建模；焦点管理决定事件路由
- 终端能力探测
  - 颜色：TrueColor/256/16 回退；鼠标：X10/URXVT/SGR；粘贴：Bracketed Paste；Alternate Screen


## V. Demo 与验收标准（Acceptance）
- Demo：
  - 布局：左栏导航 + 顶部标题 + 主内容卡片/日志 + 底部状态条 + 顶部搜索/命令输入
  - 交互：
    - 全局快捷键（如 Ctrl+K 打开命令面板）
    - 输入框支持历史/粘贴；列表支持键盘导航；日志支持自动滚动
  - 主题：暗/亮可切换；统一 Token 配色
- 验收标准：
  - 放大/缩小/拖动滚动条：无错位、无异常；帧闪烁不明显
  - 大列表滚动/日志持续输出：交互流畅（卡顿阈值与稳定帧率）
  - Windows/Linux/macOS 三平台跑通；差异在文档记录与自动测试覆盖


## VI. 风险与对策（Risks & Mitigations）
- Windows 终端兼容性差异（CMD/PowerShell/Windows Terminal）
  - 对策：ConPTY 优先，VT 降级；提供“无滚动条模式”，并在启动/退出自动还原
- Unicode 宽度/Emoji 差异
  - 对策：引入稳定的宽度库或实现；增加快照测试与视觉对齐准则
- 性能瓶颈（长列表/高频刷新）
  - 对策：虚拟化与脏区；批量输出；避免整屏重绘


## VII. 开发计划（分工/节奏）
- 当前进度（已做）
  - [x] Windows 窗口相对坐标与清屏策略调整
  - [x] UI 表面层的尺寸 clamp（防越界）
  - [x] VBox/HBox 分配修正与 clamp
  - [x] TextInput 修复（按键常量对齐）
- 下一步（本周内）
  - [ ] No‑Scrollbar 模式（Windows）
  - [ ] 双缓冲与整屏 diff（第一版）
  - [ ] ScrollContainer + 虚拟化 ListView（示例联动搜索）
  - [ ] 入门文档与对标示例结构
- 后续（2–3 周）
  - [ ] 主题系统、命令面板、菜单、LogView、TextArea
  - [ ] 键位/焦点管理、Bracketed Paste、粘贴优化
  - [ ] 跨平台 CI 与测试矩阵


## VIII. 路线图维护
- 本文件以周为单位迭代更新；每次里程碑完成产出：
  - Demo 动图/截图、关键代码路径说明
  - 主要差异与兼容性说明
  - 指标（帧率/CPU/内存）与下一阶段目标

