# fafafa.core.term 工作总结报告（2025-08-27 更新）

## 本轮（2025-08-27）最小改动 Step A
- 变更：从库单元移除 CODEPAGE 宏。
  - 文件：src/fafafa.core.term.iterminal.pas
  - 操作：删除行 `{$CODEPAGE UTF8}`，遵循“库单元不加 CODEPAGE；示例/测试需要中文输出时自行添加”的规范。
- 验证：
  - 尝试 lazbuild 构建 src/tests/run_tests.lpi；构建失败于无关模块（fafafa.core.mem.ringBuffer 类型不匹配），与本改动无关。
  - 本次变更为纯编译指示清理，不影响行为与接口，风险极低。
- 下一步建议：若批准 Step B，则按规范创建 tests/fafafa.core.term/ 脚手架并补最小用例。

---

# fafafa.core.term 工作总结报告（2025-08-17）

## 进度速览
- ✅ 现状核查：源码、文档、测试与示例完整存在（docs/tests/examples）。
- ✅ 事件通道确认：环形队列+满载丢最旧；MouseMove 尾合并；term_events_collect 批处理与去抖。
- ✅ Windows 策略确认：ReadConsoleInputW 路径；ConsoleMode 守卫；鼠标启用时临时关闭 Quick Edit；异常防御。
- ✅ 文档补充：在 docs/fafafa.core.term.md 新增“事件模型与队列（实现要点）”章节，说明关键策略与跨平台输入路径。
- 🔧 基线验证：完整 152 用例已通过（0 errors, 0 failures）。
- 🔧 plays 小改：BuildOrRun.bat 增加 -gh 开关便于泄漏排查。

## 本轮已完成
1) 基础调研与对齐
   - 对照 src/fafafa.core.term.pas 验证如下实现：
     - 固定容量环形缓冲（TERM_EVENT_QUEUE_MAX=8192）、满载覆盖最旧；
     - Push 尾合并 MouseMove；
     - term_events_collect 在预算内批量拉取、合并 move/resize；
     - support_* 懒探测；模式守卫启用/退出自动恢复；
     - Windows 使用 ReadConsoleInputW，开启 VT 时启用 ENABLE_VIRTUAL_TERMINAL_PROCESSING。

2) Bugfix：便捷重载在未初始化时安全降级
   - term_size(var w,h): _term=nil 时返回 False 且 w/h=0；
   - term_support_ansi/term_support_color_*: _term=nil 时返回 False；
   - 目的：避免“未初始化时抛异常”，让便捷调用可在更早阶段使用（若需确切能力则先 term_init）。

3) 文档更新
   - docs/fafafa.core.term.md：新增事件模型/队列/Windows 守卫/lazy 探测/跨平台输入路径小节。

4) 测试稳态化
   - 修正 Test_term_paste_storage: 显式关闭全局治理参数以隔离用例，增加 count 断言；
   - 现已全部通过：N=152, E=0, F=0。


## 本轮进展（2025-08-19）
- 文档微调对齐：docs/fafafa.core.term.md 已包含“模式守卫范式（最小示例）”“Windows 与 Unix 差异概览（快速导航）”，强调启停成对与幂等性，不改动任何代码路径。
- 用例复核：确认 Windows Quick Edit 守卫相关用例已覆盖幂等/嵌套/异常恢复路径，无需新增，仅补注释说明（见测试文件）。
- 下一步建议：在 term_events_collect 的无事件帧路径处补一段注释性说明（现有 CoreSmoke 覆盖），避免重复实现；后续按计划扩展 UI 帧循环文档与示例。

## 问题与解决
- 文档与实现的细节缺口：队列丢最旧与合并策略此前未在文档中明确。
  - 解决：补充文档，强调行为与适用场景（帧式渲染）。

## 后续计划（下一轮建议）
1) 单元测试增强（最小三件套）
   - 队列容量与覆盖策略：构造 N>cap 输入，断言“丢最旧”；
   - MouseMove 尾合并：交替 move/非 move，确保仅覆盖最后 move；
   - term_events_collect 超时/预算：模拟后端 event_pull，验证预算内收敛及合并行为。

2) UI 帧循环最小样例（不引线程）
   - 基于 term_events_collect 的每帧拉取+一次 flush；下一步再接入双缓冲 diff。

3) 长时稳定性验证（Windows-only 条件化）
   - ReadConsoleInputW 事件路径、DOUBLE_CLICK 与 XBUTTON1/2 的映射；
   - Guard 生命周期内 Quick Edit 行为核对，退出恢复。

— 本轮负责人：Augment Agent（FreePascal 框架架构师 / TDD 专家）



## 本轮工作（2025-08-15）

1) 在线调研（对标 crossterm::event）
- 模型要点：`read()` 阻塞读取、`poll(timeout)` 仅检查是否有事件；键盘事件需 Raw 模式；鼠标/焦点/粘贴需显式 Enable/Disable。
- 线程约束：同一进程内不要混用不同流式接口（我们对应为“统一通过 term_events_collect 入口汇聚”）。
- 映射策略：保持现有 `term_events_collect`（阻塞式 poll + quiet 汇总）与“鼠标移动合并”不变；新增能力（Focus/BracketedPaste）先以 feature-guard 形式规划，后续在 Unix/xterm 侧渐进实现。

2) 计划落地
- 文档：在 docs/fafafa.core.term.md 增补“事件模型与能力开关（read/poll、Raw、Mouse/Focus/BracketedPaste）”。
- 测试：补齐三项边界用例（队列溢出丢最旧；MouseMove 尾合并；poll 超时无事件不崩溃）。
- Windows 细节：Quick Edit 在鼠标启用期间关闭，退出恢复（已有实现，补验证用例）。

3) 风险与对策
- 终端差异：以 support_* 懒探测为准，未支持能力不对外承诺；BracketedPaste 暂不暴露 API，仅文档提示。
- 并发模型：继续禁止在多线程中同时调用 poll/read；如需跨线程，统一通过内部队列转发。

— 本轮负责人：Augment Agent（FreePascal 框架架构师 / TDD 专家）


## 本轮执行结果（2025-08-15 晚）

## 本轮执行结果（2025-08-16）

- 已完成
  - Windows 输入从 ReadConsoleInputA 切换为 ReadConsoleInputW，保证 Unicode 宽字符保真
  - 新增测试：tests/fafafa.core.term/Test_term_windows_unicode_input.pas（宽字符事件回环 smoke）
  - 文档增强：docs/fafafa.core.term.md 增补“能力矩阵与降级（Windows/Unix）”
- 待验证
  - 在交互环境下人工验证 emoji/合成字符键入链路（建议 plays/ 追加临时体验入口）



- 已完成
  - 新增并通过的测试用例：
    - 队列溢出丢最旧（TTestCase_TermEventQueue.Test_Overflow_Drops_Oldest）
    - 多轮短超时不崩溃（TTestCase_CoreSmoke.Test_EventPoll_MultipleTimeouts_NoStateLeak）
    - Raw+Mouse 启停幂等（TTestCase_CoreSmoke.Test_Raw_Mouse_EnableDisable_Idempotent）
    - Windows Quick Edit 守卫黑盒验证（TTestCase_CoreSmoke.Test_Windows_QuickEdit_Guard_Restore）
    - 长序列鼠标移动尾合并（TTestCase_TermEventsCollect_More.Test_Move_Merge_Long_Sequence）
  - 测试构建：Build successful（warnings 降至 2，hints 保留若干，均不影响行为）
  - 文档：docs/fafafa.core.term.md 补充“能力支持矩阵（Windows/Unix/xterm）”

- 问题与解决
  - 一次测试文件插入导致 finally/end 重复引发编译错误，已清理并复建通过
  - 个别测试存在“赋值未使用/恒真比较”提示，已在 CoreSmoke 针对性消除

- 后续计划
  - Unix/xterm 渐进增强：Raw/read/poll/Mouse 的能力对齐与验证
  - Focus/BracketedPaste 能力以 feature-guard 预留，逐步实现
  - 测试降噪（可选）：按需继续清理其余测试单元的 Hint/Warning

— 负责人：Augment Agent（FreePascal 框架架构师 / TDD 专家）

## 本轮执行补充（2025-08-16 晚）

- 构建与验证
  - 运行 tests/fafafa.core.term/BuildOrTest.bat：构建成功，生成 bin/fafafa.core.term.test.exe（构建日志显示成功；当前批处理返回码为非 0，需后续修正脚本返回码）。
  - 修复 Test_term_windows_modifiers.pas 的断言参数类型不匹配（枚举/布尔与 FPCUnit Check* 重载冲突），改为 CheckEquals 显式比较 Ord/数值后通过。
- 风险与说明
  - 当前仍有少量 Hint/Note 未清理，不影响运行；后续按需降噪。
  - 未执行交互类测试（需要真实终端），建议在 plays/ 增加手动验证入口。
- 下一步
  - （可选）对 tests_term.lpr 增加命令行参数透传与 JUnit 报告输出，便于 CI 集成。



## 本轮进展（2025-08-18）

- 调研与对标
  - 对照参考：reference/ratatui-main 与 reference/bubbletea-main 的事件/帧模型；结合 crossterm 风格的 read/poll/能力开关理念（库内 docs 已同步到“事件模型与能力开关”章节）。
  - 关键点：Raw 启用；Mouse(1000/1002/1006)/Focus(1004)/Bracketed Paste(2004) 显式启停；Windows 启用鼠标期间临时关闭 Quick Edit，退出恢复。
- 构建与验证
  - tests/fafafa.core.term：152 项用例全部通过（E=0, F=0，~0.34s）。
  - tests/fafafa.core.term.ui：13 项 UI 用例通过；启用 -gh 无泄漏。
  - examples/fafafa.core.term：07_frame_loop_demo 等二进制已在 bin/，可运行体验。
- 现存告警
  - 少量 Hint/Note（函数返回未初始化提示、inline 未内联等）不影响行为；保留待后续降噪。

### 输出与对齐
- docs/fafafa.core.term.md 已包含：
  - 事件读取语义（read/poll/帧预算/尾合并）
  - 能力开关矩阵（Raw/Mouse/Focus/Paste）与 Windows Quick Edit 守卫说明
  - Bracketed Paste 存储治理与示例（tek_paste + paste_store API）

### 下一步（最小可执行）
1) 文档微调（不改代码）
   - 在 docs/fafafa.core.term.md 中整合“Windows 与 Unix 差异概览”的要点汇总（目前分散，集中一处便于快速导航）。
   - 增加“模式守卫范式”的简例，强调 try/finally 成对关闭（Alt/Mouse/Focus/Paste）。
2) 单元测试小补
   - Quick Edit 守卫相关用例补注释与命名一致性（实现与断言已覆盖幂等/恢复，不改逻辑）。
   - term_events_collect 再补一条“无事件帧无残留状态”的注释性烟测（CoreSmoke 已涵盖，补文档化注解）。
3) 脚本与可用性
   - 统一 BuildOrTest 输出提示与路径，减少多余行，保持 0/非 0 退出码语义明确（后续可批量应用到各模块）。

— 负责人：Augment Agent（FreePascal 框架架构师 / TDD 专家）


## 本轮进展（2025-08-18）

- 调研与对标
  - 对照参考：reference/ratatui-main 与 reference/bubbletea-main 的事件/帧模型；Rust crossterm 的 read/poll/能力开关理念（库内 docs 已同步到“事件模型与能力开关”章节）。
  - 关键点：Raw 模式启用；Mouse(1000/1002/1006)/Focus(1004)/Bracketed Paste(2004) 需显式启停；Windows 启用鼠标期间临时关闭 Quick Edit，退出恢复。
- 构建与验证
  - 运行 tests/fafafa.core.term/BuildOrTest.bat：152 项用例全部通过（E=0, F=0，耗时约 0.34s）。
  - 运行 tests/fafafa.core.term.ui/BuildOrTest.bat：13 项 UI 用例通过；启用 -gh 无泄漏。
  - 示例目录 examples/fafafa.core.term 验证存在并可构建（07_frame_loop_demo 等二进制已在 bin/）。
- 现存告警
  - 若干 Hint/Note（函数返回未初始化提示、inline 未内联等）不影响行为；保留待后续降噪。

### 输出与对齐
- docs/fafafa.core.term.md 已包含：
  - 事件读取语义（read/poll/帧预算/尾合并）
  - 能力开关矩阵（Raw/Mouse/Focus/Paste）与 Windows Quick Edit 守卫说明
  - Bracketed Paste 存储治理与示例（tek_paste + paste_store API）

### 下一步（最小可执行）
1) 文档微调（不改代码）
   - 在 docs/fafafa.core.term.md 中补一段“Windows 与 Unix 差异概览”的要点汇总（已散见于多处，整合到一处快速导航）。
   - 增加一段“模式守卫范式”的简例，强调 try/finally 成对关闭的重要性（Alt/Mouse/Focus/Paste）。
2) 单元测试小补
   - 为 Quick Edit 守卫用例补充一次“重复 enable/disable 的幂等性”断言说明（实现已具备，测试已覆盖，主要补注释与命名一致性）。
   - 对 term_events_collect 再追加一个“无事件帧不崩溃且无残留状态”的快速烟测（现有 CoreSmoke 已涵盖，可复用并补注释）。
3) 脚本与可用性
   - 统一 BuildOrTest 输出中的提示与路径，减少多余行，保持 0/非 0 退出码语义明确（后续一并处理各模块）。

— 负责人：Augment Agent（FreePascal 框架架构师 / TDD 专家）



## 示例修复与脚本更新（2025-08-18）

- 示例修复
  - events_collect_statusbar.lpr：统一事件与坐标字段；使用 term_cursor_set 与 ANSI 清行替代历史 helper
  - 统一命名：progress_demo → progress_simple_demo
- 构建脚本
  - examples/fafafa.core.term/build_examples.bat：
    - 新增 FAIL/PRINT_LIST 分支，确保失败不误报成功，并统一输出可用清单
    - 跳过依赖未就绪模块的示例：menu_system.lpr、layout_demo.lpr、recorder_demo.lpr
- 构建结果
  - 已验证可构建并可运行：example_term/basic_example/keyboard_example/text_editor/progress_simple_demo/theme_demo/unicode_demo/widgets_demo
  - 产物位于 examples/fafafa.core.term/bin/
- 文档
  - 更新 examples/fafafa.core.term/README.md：列出当前可运行示例、跳过项与依赖说明，以及构建指引



## 本轮进展（2025-08-20）

- 在线调研（Ratatui/crossterm 模型对齐）
  - 参考 ratatui: Frame.draw + event::read/poll 语义，强调“每帧集中渲染 + 事件合并/去抖”。
  - 与现状一致：term_events_collect 批量拉取、MouseMove 尾合并、阻塞式 poll + --quiet 汇总；Windows Quick Edit 启停守卫；能力懒探测。
- 现状复核
  - Windows 路径：ReadConsoleInputW；启用 VT 时打开 ENABLE_VIRTUAL_TERMINAL_PROCESSING；鼠标启用期临时关闭 Quick Edit，退出恢复。
  - 队列策略：固定容量、有界覆盖最旧；Paste 治理参数（总字节/保留最近 N/快速修剪分支）。
- 本轮动作
  - 无代码改动；对文档/测试计划进行梳理，准备补充“帧式循环与双缓冲 diff”说明与最小烟测。
- 风险与注意
  - Unix SIGWINCH/Bracketed Paste 等差异需保持条件化与降级路径清晰；交互类用例仍建议 via plays/ 手动验证。
- 下一步（最小可执行）
  1) 文档：在 docs/fafafa.core.term.md 增补“帧式循环与双缓冲 diff（设计与落地）”小节，并集中“Windows/Unix 差异概览”。
  2) 测试：补一条“无事件帧无残留状态”的烟测注释；复核 Quick Edit 守卫用例命名与注释一致性。
  3) 工具脚本：统一 BuildOrTest 输出与退出码语义（仅调脚本，保持现有行为）。

— 负责人：Augment Agent（FreePascal 框架架构师 / TDD 专家）



## 执行结果补充（2025-08-20）

- 构建与测试
  - 运行 tests/fafafa.core.term/BuildOrTest.bat test：169 项用例全部通过（E=0, F=0，耗时约 0.40s），退出码 0。
  - 关键日志：CoreSmoke 全通过；Windows Quick Edit 守卫/Unicode 输入/协议开关 等用例覆盖均正常。
- 现存告警
  - 若干 Hint/Note（未初始化提示/inline 未内联等）不影响行为；暂不处理，后续按需降噪。
- 下一步
  - 维持既定计划：补文档“帧式循环与双缓冲 diff”、集中“Windows/Unix 差异概览”，以及测试注释微调与脚本输出统一。

— 负责人：Augment Agent（FreePascal 框架架构师 / TDD 专家）


## 文档与代码更新（2025-08-20 晚）

- 代码调整
  - 统一 inline 宏为 FAFAFA_CORE_INLINE；清理历史 FAFAFA_ITERM_INLINE；全量回归通过。
  - 无参 support_* 接口在 _term=nil 时统一返回 False，防止早期探测抛出异常。
  - term_evnet_push 标注 deprecated，提示使用 term_event_push。
  - term_write(aTerm; string/WideString/UCS4String) 对空串 Length=0 直接早退，提高健壮性（无行为变化）。
- 文档补充
  - docs/fafafa.core.term.md 增补“近期变更（2025-08-20）”小节，记录上项变更与行为语义。
- 回归
  - tests/fafafa.core.term：169/0/0 通过，退出码 0。
- 建议
  - 后续如需进一步降噪，可逐步清理 Hint/Note；不影响功能，不做硬性要求。


## 本轮进展（2025-08-24）

- 在线调研（对标 crossterm/jline/golang.org/x/term）
  - 事件与模式：read/poll；Raw 模式 guard；Mouse(1000/1002/1006)、Focus(1004)、Bracketed Paste(2004) 显式启停；Alt Screen 成对启停。
  - Windows：SetConsoleMode 启/停 ENABLE_VIRTUAL_TERMINAL_PROCESSING；鼠标启用期暂关 Quick Edit，退出恢复。
  - Unix：termios 原始模式；SIGWINCH 触发尺寸变化；/dev/tty 与环境变量 TERM 推断能力。
- 代码与现状核对
  - 现有实现与策略基本一致：环形事件队列、Move 尾合并、term_events_collect 批处理与去抖、Quick Edit 守卫、能力懒探测。
  - OOP 门面（ITerminal/ITerminalOutput/ITerminalInput）已存在但仍属增强方向；当前稳定对外仍以 C 风格 API 为主。
- 基线验证
  - 运行 tests/fafafa.core.term/BuildOrTest.bat test：成功，退出码 0（本机验证）。
  - 本轮未改代码，仅验证与记录。
- 风险/注意
  - 交互型能力（Focus/Bracketed Paste）在不同终端的差异较大，仍建议条件化开启与降级；持续以 plays/ 做人工体验验证。

### 下一步建议（小步快跑）

（2025-08-24 阶段0/1/2-部分 完成）
- 阶段0：文档集中/注释/脚本降噪 完成
- 阶段1：Unix Focus/Paste 能力可控/可诊断/可降级；plays 可用于人工验证；非交互覆盖用例增加（已纳入 .lpi 与 Runner）
- 阶段2：门面 Beta 子集映射补充文档；新增 example_facade_beta 演示；门面最小自检用例加入 Runner

1) 文档微调（不改代码）
   - 在 docs/fafafa.core.term.md 集中“Windows/Unix 差异概览”和“帧式循环与双缓冲 diff”两节，作为快速导航。
2) 测试注释微调
   - 对 Quick Edit 守卫与“无事件帧”烟测的现有用例补充注释，统一命名风格（无需新增逻辑）。
3) 脚本可用性
   - 复用现有统一模式，进一步减少 BuildOrTest 的噪声输出，确保 0/非0 语义一目了然。

— 负责人：Augment Agent（FreePascal 框架架构师 / TDD 专家）



## 本轮进展（2025-08-25）

- 在线调研（MCP 简要）：对标 Rust crossterm/tui-rs、Go tcell/termbox、Java Lanterna/JLine 的通用做法：
  - 能力探测与降级：优先启用 ANSI/VT，Windows 打开 ENABLE_VIRTUAL_TERMINAL_PROCESSING；按实际支持降级 24bit→256→16 色
  - 模式守卫：Raw/AltScreen/Mouse/Focus/BracketedPaste 均需成对启停，异常路径 finally 恢复
  - 事件收集：poll(timeout)/read 阻塞与预算合并（合并连续 MouseMove、去抖 Resize），统一走单一事件通道
  - 终端差异：Unix SIGWINCH 触发尺寸变更，Windows 使用 Console Input 事件；宽字符优先（W 路径）
  - 输出策略：缓冲+最小化序列（状态机避免重复属性），按帧 flush；必要时走直接写入路径
- 现状核对：fafafa.core.term 已对齐以上要点（事件环形队列、尾合并、Raw/Mouse 守卫、VT 开关、懒探测/降级、缓冲输出）。
- 基线验证（本机）：
  - 命令：tests/fafafa.core.term/BuildOrTest.bat test
  - 结果：构建成功；运行用例 N=189, E=0, F=0；退出码 0
  - 备注：测试阶段出现一次“系统找不到指定的路径。”提示，但不影响结果（考虑在脚本中屏蔽该提示源）。

### 下一步建议（不改核心逻辑，小步优化）
1) 脚本降噪与健壮性
   - 调整 BuildOrTest.bat：对不存在的目标路径操作前先判断；保留 0/非0 退出码语义
2) 文档集中化（不改代码）
   - 在 docs/fafafa.core.term.md 收敛“Windows/Unix 差异概览”“帧式循环与双缓冲 diff”两节，作为快速导航
3) 门面 Beta 覆盖（可选，保持很小）
   - 增补 1–2 条门面用例（ExecuteCommands 顺序与 Flush 幂等），避免过度测试

— 负责人：Augment Agent（FreePascal 框架架构师 / TDD 专家）


## 本轮进展（2025-08-25 晚）

- 代码对齐（稳定小步）：
  - Unix 鼠标协议：启停顺序以 SGR(1006) 为首选，兼容 1002/1000/1015（仅注释/顺序微调）
  - 默认输出绑定 stdout：TTerminal 默认使用标准输出句柄，失败回退内存流；测试不受影响
  - Windows VT 输入 behind-a-flag：新增 FAFAFA_TERM_WIN_VT_INPUT=on|1 时启用 ENABLE_VIRTUAL_TERMINAL_INPUT（默认关闭）
- 测试与脚本：
  - tests/fafafa.core.term/BuildOrTest.bat test → 退出码 0（[TEST] OK）
  - 脚本降噪第一步完成（logs 目录保障、popd 静默）；仍有一次“系统找不到指定的路径。”提示，待精确定位与消除
- 风险与兼容性：
  - 所有变更均为保守增强；默认不改变现有输入输出路径；失败路径有回退；不影响已存在用例
- 下一步：
  - 继续脚本降噪（逐点定位提示源并加保护）
  - 文档小节已更新：docs/fafafa.core.term.md《近期变更（2025-08-25）》

— 负责人：Augment Agent（FreePascal 框架架构师 / TDD 专家）


## 本轮进展（2025-08-26 · 批次1 第一阶段）

- 能力快照扩展：GetCapabilities 新增 Focus/BracketedPaste 与鼠标 1000/1002/1006/1015 细粒度位
- 环境支持补齐：SupportsColor/ColorDepth honor NO_COLOR/CLICOLOR/CLICOLOR_FORCE/COLORTERM/TERM；终端识别新增 TERM_PROGRAM/VTE/KONSOLE/WEZTERM/ALACRITTY 等启发式
- 事件参数化（Unix）：FAFAFA_TERM_RESIZE_DEBOUNCE_MS（默认50ms）、FAFAFA_TERM_READ_TIMEOUT_MS（termios VTIME 映射）；合并开关沿用既有 FAFAFA_TERM_COALESCE_MOVE/WHEEL（默认 on）
- 输出状态机优化：Show/HideCursor 重复调用抑制
- 回归：tests/fafafa.core.term 全量通过 N=189,E=0,F=0；新增最小测试文件已准备（将二阶段提交）
- 下一步（二阶段）：补充 4 条最小用例并回归；完善“近期变更”文档小节

— 负责人：Augment Agent

- 能力宣称收敛：Focus/BracketedPaste 仅在明确支持时宣称；默认行为不变，减少“乐观支持”带来的误用风险

- 输出状态机进一步优化：抑制重复 Save/RestoreCursor 与重复 SetScrollRegion；ResetScrollRegion 后清空缓存；默认行为与 API 不变

- 可选写入合并阈值（behind-a-flag）：FAFAFA_TERM_WRITE_COALESCE_BYTES>0 时聚合小写入；默认关闭，兼容性优先
