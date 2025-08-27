# fafafa.core.term 模块 TODO（迭代式维护清单）

更新时间：2025-08-19
负责人：Augment Agent（fafafa.core.term 模块）

## 现状速览
- 模块主单元：src/fafafa.core.term.pas（平台抽象 + ANSI 生成 + Windows/Unix 后端对接）
- 测试工程：tests/fafafa.core.term/（已能成功编译；运行时未传递 fpcunit 运行参数，未实际执行用例）
- 示例与文档：docs/fafafa.core.term.md、examples/fafafa.core.term/ 存在

## 本轮工作（2025-08-10）
- 对齐接口与测试：
  - 在 ITerminalInfo/TTerminalInfo 中补齐以下方法，满足测试期望：
    - GetEnvironmentVariable(const aName: string): string
    - IsInsideTerminalMultiplexer: Boolean
  - 为 ITerminalOutput 增加 ExecuteCommands 的强类型重载：
    - ExecuteCommands(const aCommands: array of ITerminalCommand)
  - 在实现区补齐上述方法与重载。
- 基线验证：
  - 使用 tests/fafafa.core.term/BuildOrTest.bat 成功编译；
  - 运行阶段可执行文件输出了 fpcunit runner 使用帮助，退出码非 0，说明尚未传入 --all 等参数执行用例。

## 当前问题与风险
- 测试脚本未正确传参，导致未实际运行单元测试（退出码=1）。
- 若未来扩展 ITerminalInfo 能力集合/属性，需同步更新测试覆盖以反映真实终端环境差异（Windows/Unix）。

## 下一步计划（迭代 1）
1) 修复测试运行脚本（优先级：高）
   - 修改 tests/fafafa.core.term/BuildOrTest.bat/.sh：在运行阶段追加参数：`--all --format=plain --progress`；
   - 统一将测试输出至 tests/fafafa.core.term/bin/ 目录下的 results.xml 或 plain 文本；
   - 将 runner 非 0 退出码传递回批处理（保留）。
2) 文档/接口补档（优先级：中）
   - docs/fafafa.core.term.md：补充“环境/多路复用器检测 API”一节与简单示例；
3) 清理和质量提升（优先级：中）
   - 降噪：处理编译 Hint/Note（局部变量初始化/未使用变量等）；
   - 统一中文注释并补齐关键逻辑说明；

## Done/完成定义
- 所有测试脚本一键执行可实际跑通用例并返回 0；
- ITerminalInfo/ITerminalOutput 的新增接口在文档中有明确描述与示例；
- 无新增 Warning/Hint（或已在 TODO 中注明原因与暂缓策略）。



## 本轮工作（2025-08-11）
- 现状核查：完成 triage 与基线验证
  - 测试工程 tests/fafafa.core.term 构建与运行验证通过（83 项用例全绿）。
  - BuildOrTest.bat 已正确传递 fpcunit 运行参数（-a -p --format=plain），此前“未执行用例”的问题已不存在。
- 编译告警盘点（Windows 平台构建日志）
  - Hint: 局部变量/返回值可能未初始化（fafafa.core.term.windows.pas 若干处；fafafa.core.term.ansi.pas:365）。
  - Note: 若干 inline 未被内联（无需处理）。
  - Test 项有 1 条 UnicodeString -> AnsiString 的隐式转换 Warning（仅限测试代码，可保留或后续消除）。

## 下一步计划（迭代 2 提案）
1) 消除核心库告警（优先级：高）
   - 为 term.windows 中的 CONSOLE_SCREEN_BUFFER_INFO、INPUT_RECORD 等局部/结果使用 FillChar(...,0,...) 或显式初始化；
   - 校正 fafafa.core.term.ansi 中相关函数的 Result 初始化；
   - 原则：仅在库代码中清洁告警，测试代码的告警可延后处理。
2) 能力降级与颜色映射（优先级：中）
   - 在 term 层提供 24bit→256/16 的降级映射辅助（保持 API 不变，内部根据 term_support_* 决策）；
   - 新增覆盖测试：在“禁用真彩”的模拟环境下仍正确输出近似颜色。
3) 事件队列与输入路径的 TDD 补齐（优先级：中）
   - 为 term_event_queue_* 增加 fpcunit 覆盖：push/pop/peek/clear/迭代边界；
   - 增加简单的事件轮询集成测试（超时路径、SizeChange 事件）。
4) 文档与示例（优先级：中）
   - docs/fafafa.core.term.md 增补“颜色降级策略”“Windows VT 启用注意事项”；
   - examples/fafafa.core.term 中新增一个“事件队列与重绘节流”示例。

## 风险与对策
- Windows Console 能力差异：优先通过 ENABLE_VIRTUAL_TERMINAL_PROCESSING 启用 VT，失败时退回老路径；
- 颜色一致性：在不同终端比对快照时，使用 ANSI 码而非实际像素颜色作为断言依据；
- 跨平台差异：将不可用能力关口前移到 term_support_*，调用侧保持幂等。

## 完成定义（更新）
- 库代码无 Warning/Hints（或以 Suppress/注释解释的例外）；
- 新增测试全部通过，覆盖新增降级逻辑与事件队列边界；
- 文档更新并与示例一致，能指导用户在 Windows/Linux 下正确启用 VT/降级。



## 本轮工作（2025-08-12）
- 协同 term.ui：明确 UI 层 BackBuffer/裁剪策略与 term 层能力边界，避免 API 误用。
- 计划：为 ansi/color 与 cursor 路径补一组最小 smoke tests（覆盖 24bit/16色降级开关）。
- 文档：在 docs/fafafa.core.term.md 中追加“与 term.ui 的协作约定（0基坐标与帧输出）”。


## 本轮工作（2025-08-15）
- 事件模型对齐（参考 crossterm::event）：
  - 提示 read/poll 语义区分：read 阻塞、poll 仅检查；键盘事件需 Raw 模式；Mouse/Focus/BracketedPaste 需显式启用/禁用。
  - 线程模型：禁止跨线程混用不同读取接口；统一通过 term_events_collect 聚合并写入环形队列。
  - 队列策略：保持固定容量、满载覆盖最旧；MouseMove 尾合并策略保持。
- Windows Quick Edit 守卫：鼠标启用期临时关闭，退出恢复（已实现，补充测试计划）。

## 下一步计划（迭代 3 提案）
1) 文档增强
   - docs/fafafa.core.term.md 新增“事件模型与能力开关（read/poll、Raw、Mouse/Focus/BracketedPaste）”。
2) 单测增强
   - 队列溢出覆盖最旧用例；MouseMove 尾合并用例；poll 超时无事件不崩溃；Quick Edit 守卫的启停幂等。
3) 渐进能力
   - Focus/BracketedPaste：先文档说明与内部开关预留，Unix/xterm 侧再实现。


## 本轮实际执行（2025-08-16 晚）
- 修复测试断言类型冲突：Test_term_windows_modifiers 改为 CheckEquals 显式比较，解除编译错误。
- 本地验证：tests/fafafa.core.term/BuildOrTest.bat 编译通过并链接成功，生成 bin/fafafa.core.term.test.exe。
- 建议：将 plays/ 增补交互式验证入口（emoji/组合键/鼠标移动速率）。


## 本轮实际执行（2025-08-19）
- 文档微调：docs/fafafa.core.term.md 增补“Windows 与 Unix 差异概览（快速导航）”“模式守卫范式（最小示例）”，强调启停成对与幂等性；不改动代码路径。
- 测试复核：确认 tests/fafafa.core.term/Test_term_windows_quickedit_guard.pas 已包含幂等/嵌套/异常路径恢复的断言，无需新增用例，仅补文档指引。
- 建议：下一步按计划补一个“无事件帧不崩溃”的极简烟测注释说明，避免重复实现（现有 CoreSmoke 覆盖）。
