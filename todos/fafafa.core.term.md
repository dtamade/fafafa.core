# fafafa.core.term 开发计划日志（2025-08-17）

## 已完成（本轮）
- 便捷重载在 _term=nil 时安全降级（term_size、term_support_*）
- plays BuildOrRun.bat 增加 -gh（泄漏检查开关）
- 修复 Test_term_paste_storage 用例隔离（关闭全局治理参数，补 count 断言）
- 全量测试通过：152/0/0

## 下一步可执行计划（短期）
1) 文档与脚本
   - [ ] 清洁测试脚本输出：完成第一步（去多余空行与提示），继续统一 bin 路径提示
   - [ ] docs 增补：事件读取语义、能力开关矩阵（Raw/Mouse/Focus/Paste）、term_events_collect 帧语义

2) 单元测试增强
   - [ ] Quick Edit 守卫幂等/恢复的条件化断言（Windows）
   - [ ] term_events_collect 长序列 + 跨 burst 的移动合并测试

3) 示例/plays
   - [ ] 帧式循环最小 Demo（每帧 collect->render->flush）

## 决策与约束
- 同步优先，帧内聚合；避免逐事件输出
- 模式守卫变更（鼠标、Quick Edit、VT）退出后必须恢复；异常路径做好 finally 保护

## 备注
- profile（cli/tui/daemon）与环境变量默认治理已可用，文档将补齐落地说明


---

# 追加（2025-08-18）

## 可执行的小步计划（本轮）
1) 文档
   - [ ] 在 docs/fafafa.core.term.md 新增“Windows/Unix 差异概览（快速导航）”节，集中关键信息
   - [ ] 增补“模式守卫范式”最简示例（Alt/Mouse/Focus/Paste 成对启停）
2) 单元测试
   - [ ] tests/fafafa.core.term/Test_term_windows_quickedit_guard：补注释与命名一致性（幂等/恢复）
   - [ ] tests/fafafa.core.term/Test_term_core_smoke：对“无事件帧不残留状态”的场景补注释说明（不新增逻辑）
3) 脚本
   - [ ] 统一 BuildOrTest 输出提示与路径，减少多余行，确保 0/非 0 退出码语义明确（逐步推广到各模块）

## 说明
- 本轮不修改核心实现，聚焦文档/测试注释/脚本可用性。
- 若优先推进 Unix/xterm 的 Focus/Bracketed Paste 实装，可在下轮开启专题（需要交互/仿真用例与条件化测试）。



## 示例恢复计划（新增）

1) Recorder（优先）
- [ ] 设计 ITerminalRecorder 接口（Start/Stop/Record(Event)/Play/State）
- [ ] 提供最小内存实现（基于现有 term_event_t 队列）与时间戳回放
- [ ] 让 examples/recorder_demo.lpr 可编译运行（基础录制/回放 UI）

2) Menu
- [ ] 定义轻量菜单抽象（IMenu/IMenuItem），或复用 widgets，保证菜单可渲染/导航
- [ ] 恢复 examples/menu_system.lpr 构建

3) Layout
- [ ] 定义 ITerminalLayout（方向、分配、边距/间距）；提供 MakeRect、ldVertical/ldHorizontal 枚举
- [ ] 恢复 examples/layout_demo.lpr 构建

备注：以上恢复均保持最小实现，优先保证示例可运行，其后再做性能与 API 打磨。



---

# 追加（2025-08-20）

## 本轮计划（不改核心实现）
1) 文档
   - [ ] docs/fafafa.core.term.md：新增“帧式循环与双缓冲 diff”小节；集中“Windows/Unix 差异概览”。
2) 单元测试
   - [ ] Test_term_core_smoke：补“无事件帧无残留状态”的注释性烟测说明（已有覆盖，仅补注释）。
   - [ ] Test_term_windows_quickedit_guard：复核命名与注释一致性（幂等/恢复路径）。
3) 脚本
   - [ ] 统一 tests/fafafa.core.term/BuildOrTest.bat 输出与退出码语义（0=通过；非0=失败），减少多余行。

## 备注
- 继续保持“懒探测 + 条件化降级”策略；交互型特性通过 plays/ 进行人工验证，不纳入自动化用例。



## 进展记录（2025-08-20）

- [x] 本地基线验证：tests/fafafa.core.term/BuildOrTest.bat test 全量通过（169/0/0），退出码 0。
- [x] 记录日志与报告：已更新 report/fafafa.core.term.md 与本文件。
- [ ] 文档：补“帧式循环与双缓冲 diff”与“Windows/Unix 差异概览”集中小节。
- [ ] 测试注释：CoreSmoke/QuickEditGuard 的注释一致性修订。
- [ ] 脚本：统一 BuildOrTest 输出（减少噪声，明确 0/非0 语义）。



## 进展记录（2025-08-20 晚）

- [x] 宏统一：使用 FAFAFA_CORE_INLINE，清理历史 FAFAFA_ITERM_INLINE（接口声明 IFDEF 全替换）。
- [x] 能力探测守卫：无参 support_* 在 _term=nil 返回 False（不抛异常）。
- [x] 弃用标注：term_evnet_push 标记 deprecated，提示使用 term_event_push。
- [x] 写入健壮性：term_write(aTerm; string/WideString/UCS4String) 对空串 Length=0 早退。
- [x] 文档：docs/fafafa.core.term.md 增加“近期变更（2025-08-20）”。


## 进展记录（2025-08-24）

- 在线调研：对比 Rust crossterm、Go golang.org/x/term、Java jline
  - Raw 模式/Alt Screen/Mouse/Focus/Bracketed Paste 能力开关与守卫范式确认
  - Windows ConsoleMode 与 Unix termios 行为差异复核；我们实现与其一致
- 基线验证：
  - 运行 tests/fafafa.core.term/BuildOrTest.bat test：成功，退出码 0（不改代码，仅验证）
- 风险与注意：
  - 交互能力在不同终端差异较大，继续条件化开启与降级；使用 plays/ 做人工体验

## 下一步计划（短期、可执行）

- 已完成（2025-08-24）：阶段0、阶段1（A+B+C），阶段2（部分：映射文档/示例/用例纳入）

- 待办（阶段2余项）
  1) 文档
     - [ ] 将“门面 Beta 子集映射”整理成完整对标表（方法→C API），置于 docs 顶部第二屏速查
  2) 示例
     - [ ] 增加一个无交互帧式循环示例（仅缓冲与 flush，执行一帧/两帧渲染）
  3) 测试
     - [ ] 评估是否需要极少量门面特有用例（保持不超过 2 个），专测 ExecuteCommands 的顺序一致性与 Flush 幂等；避免沉迷测试
  4) 生态
     - [ ] 考察 ratatui 帧节奏映射样例，准备阶段3的端到端验证脚本

1) 文档
   - [ ] docs/fafafa.core.term.md：集中“Windows/Unix 差异概览”，新增“帧式循环与双缓冲 diff”小节
2) 单元测试
   - [ ] 为 Quick Edit 守卫与“无事件帧”相关的现有用例补注释与命名一致性（不改逻辑）
3) 脚本
   - [ ] 细化 tests/fafafa.core.term/BuildOrTest.bat 输出降噪，明确 0/非0 语义（保持现有行为）


## 对齐 Rust(crossterm) / Go(tcell) 审查输出（2025-08-25）

- 必做（Must）
  1) Windows 终端识别增强：检测 WT_SESSION/ConEmuPID/ANSICON/MSYSTEM/TERM 等，区分 Windows Terminal/ConEmu/MSYS/MinTTY/Legacy Console；按能力决定是否尝试启用 VT 和 SGR 鼠标
  2) 颜色能力探测完善：读取 COLORTERM(=truecolor/24bit)/TERM 值；支持 NO_COLOR 关闭彩色；根据 terminfo/环境降级 24bit→256→16
  3) IsATTY 快速检测：Unix 用 isatty(fd)；Windows 用 GetConsoleMode/FILE_TYPE_CHAR，避免 term_init 副作用
  4) 鼠标协议收敛到 SGR(1006)：默认启用 1006 并按终端能力降级；确保 1000/1002/1003 的选择策略与 crossterm/tcell 一致

- 应做（Should）
  5) Focus(1004)/Paste(2004) 启停：仅在支持 ANSI/VT 条件下启用；在 Windows 上 VT 不可用时禁用
  6) 同步输出（?2026）behind-a-flag：仅在支持的终端启用；默认关闭
  7) Windows VT 模式细节：同时设置输入/输出句柄的 VT 位；评估 DISABLE_NEWLINE_AUTO_RETURN 的必要性
  8) CreateTerminal 绑定 StdOut：默认输出流改为绑定系统 stdout（当前为 TMemoryStream），保留注入自定义流的构造重载

- 可做（Nice）
  9) Unicode 宽度与组合字符：引入 wcwidth 表或简化实现，用于 UI 层计算列宽（不改变 term 写出）；测试覆盖 emoji/全角/合成序列
  10) 颜色/能力环境变量回退：容忍错误配置并给出日志提示（可 behind-a-flag）

- 测试计划（最小）
  A) 颜色探测：模拟 COLORTERM/NO_COLOR/TERM 不同组合，断言 color depth 与开关结果
  B) IsATTY：在非 TTY 环境下快速返回 False，不触发 term_init
  C) Windows：当无法启用 VT 时，Focus/Mouse/Paste 自动禁用，不输出 ANSI；能启用 VT 时输出正确序列
  D) 门面：ExecuteCommands 顺序与 Flush 幂等（仅 1–2 条）
