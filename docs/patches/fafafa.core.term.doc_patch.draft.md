# fafafa.core.term 文档修订草案（Draft）

本草案仅为改动建议，不代表最终提交。目标：澄清当前状态（以 C 风格 term_* API 为主）、补强事件边界语义、平台差异、错误返回约定，以及性能与配置优先级说明。

## 1. 当前接口形态澄清
- 现阶段主接口：C 风格 term_*
  - 示例：term_init/term_done、term_event_poll/term_events_collect、term_mouse_enable、term_focus_enable、term_paste_bracket_enable、term_alternate_screen_enable、term_raw_mode_enable 等。
- OOP 门面（ITerminal/ITerminalOutput/ITerminalInput）为规划方向，尚未对外稳定。
- 文档中 OOP 类图保留在“未来计划/实验性”章节，避免与现状冲突。

## 2. 配置优先级与运行时开关
- 优先级：编译期默认 < 环境变量（term_init 读取一次） < 运行时 Setter/Getter（随调随改）
- 建议补充 API
  - term_get_effective_config: 返回当前生效配置快照
  - term_set_coalesce_move/term_set_coalesce_wheel/term_set_debounce_resize 以及对应 getter 的行为与可用范围说明

## 3. 事件语义与边界
- 合并/去抖策略（collect 调用内生效，跨 collect 不合并）
  - Move：同一采样窗口保留最后一次；被 Key/Click/Wheel 打断则切段
  - Wheel：同向聚合（累计 delta）；方向变化或任意非 Wheel 事件打断
  - Resize：可去抖，仅输出最后尺寸；若被非 Resize 事件打断，需在打断前输出至少一次
- 建议附上可运行片段与图示（依据 examples/plays）
- 新增测试建议（已在 tests 草拟 3 个骨架）：
  - ModeGuard 嵌套/异常路径恢复
  - Wheel 聚合在 Key 打断与方向反转时的分段
  - Resize 风暴在鼠标按下打断时的分段与“至少一次”保证

## 4. 平台差异（Windows/Unix）
- Windows
  - VT 启用（ENABLE_VIRTUAL_TERMINAL_PROCESSING），老系统回退 WriteConsoleW
  - 鼠标启用期间临时关闭 Quick Edit；通过 Guard/Finally 保证恢复；允许嵌套
  - 代码页/Unicode 注意事项；重定向到文件时行为（尽量降级为 no-op + 返回 False）
- Unix
  - TTY 原始模式；SIGWINCH；Xterm/Kitty/WezTerm 的 1000/1002/1006（Mouse）、1004（Focus）、2004（Bracketed Paste）

## 5. 错误与返回值约定
- 原则：可失败的操作返回 False，不抛异常；提供 term_last_error/term_strerror（待实现/对齐）
- 不支持能力：返回 False + 不做副作用；文档明确
- 初始化失败：允许异常或返回 False；在示例与文档中展示可恢复路径

## 6. 性能与最佳实践
- 帧循环建议：预算（8–16ms）、compose=true、行内段级 diff、同步更新协议、一次性 flush
- 空转策略：无事件时保持 O(1)，必要时最小 sleep 或指数退避（可配置）
- ANSI 热路径：
  - 预生成常用序列（SGR/光标移动）
  - 批量写出减少 write 次数
- 基准建议：
  - 10^5 级合成事件（Move/Wheel/Resize）吞吐
  - 粘贴大文本（>10MB）裁剪与总内存上限为摊还 O(1)

## 7. 文档结构调整建议
- 在 docs/fafafa.core.term.md 顶部新增“当前状态”提示卡片
- 新增章节：
  - 平台差异（Windows/Unix 专章）
  - 错误与返回语义
  - 事件边界与示例
  - 性能与最佳实践（与 UI 帧循环结合）
- 计划功能清单调整：
  - 将已具备但“待完善”的功能从“计划”挪到“已支持（Beta）”

---
本草案用于对齐方向，确认后可拆分为具体 PR：
1) 文档修订 PR（结构/用语/示例统一）
2) 测试补齐 PR（3 个新增用例完善断言与注入方式）
3) 性能微优化 PR（ANSI 缓冲/flush 策略与空转策略）

