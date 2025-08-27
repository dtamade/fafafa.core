# fafafa.core.term - 现代化终端控制模块


> See also: 示例总表（fafafa.core.term）：docs/EXAMPLES.md#终端模块示例总表（fafafa.core.term）



- [对标导航 · 快速映射（crossterm/tcell）](#对标导航--快速映射crosstermtcell)
- [门面 Beta 对标表（crossterm/tcell）](#门面-beta-对标表rust-crossterm--go-tcell)

- [帧式循环与双缓冲 diff（集中入口）](#帧式循环与双缓冲-diff设计与落地)

- [信号/尺寸变更（WINCH）最佳实践 · 强烈推荐](partials/signal.best_practices.md)

- [Windows 与 Unix 差异概览（快速导航）](#windows-与-unix-差异概览快速导航)
- [模式守卫范式（最小示例）](#模式守卫范式最小示例)
- [输出缓冲最佳实践（queue/flush）](#输出缓冲最佳实践queueflush)

## 概述

`fafafa.core.term` 是 fafafa.core 框架中的终端控制模块，提供了完整的、生产级别的终端控制功能。该模块借鉴了现代语言中优秀终端库的设计理念（如 Rust 的 crossterm、Go 的 bubbletea、Java 的 JLine），为 FreePascal 开发者提供了强大而易用的终端控制能力。

### 当前状态与接口选择（重要）

- 主接口：当前以 C 风格的 term_* API 为主（性能透明、语义清晰、测试齐备）
- 薄门面：提供 ITerminal/IModeGuard 作为“易用层”，位于 src/fafafa.core.term.iterminal.pas；所有方法仅直通 term_*，不改变语义
- 如何选择：
  - 底层/性能/跨语言：优先使用 term_*（或未来的 pterm_t 句柄化 API）
  - 应用/RAII/可读性：使用 ITerminal + IModeGuard（异常路径自动恢复）

最小 ITerminal 轮询示例：

```pascal
uses fafafa.core.term, fafafa.core.term.iterminal;
var T: ITerminal; E: term_event_t; running: Boolean;
begin
  T := CreateTerminal; running := True;
  while running do begin
    if T.Poll(E, 100) and (E.kind = tek_key) then
      if (E.key.key = KEY_Q) then running := False;
  end;
end;
```

### 事件边界与合并语义要点（速记）

- 合并/去抖仅在同一 term_events_collect 调用内生效；跨 collect 不合并
- Move：连续 tms_moved 尾合并保留“最后一次”，被 Key/Click/Wheel 打断即分段
- Wheel：同向聚合；方向反转或被非 Wheel 事件打断即分段
- Resize：段内去抖仅保留“最后一次”；若被非 Resize 事件打断，需分段并各保留最后一次
- 对应测试：
  - Test_term_events_collect_edgecases.pas（Move/Resize 分段）
  - Test_term_events_wheel_boundaries.pas（Wheel 边界/方向反转）
  - Test_term_resize_storm_debounce_interrupt.pas（Resize 风暴被按压打断）

### 错误与返回值语义

- 不支持或失败时：term_* API 返回 False 并优雅降级（no-op），不抛异常
- ITerminal 薄门面遵循相同语义（内部直接调用 term_*），析构时做幂等恢复
- 建议：通过 term_support_* 或返回值判断能力，避免把异常用于流程控制


### 配置优先级与运行时开关

- 生效顺序：编译期默认 < 环境变量（term_init 读取一次） < 运行时 Setter/Getter（随调随改）
- 建议/现状：
  - feature toggles（如 move 合并 / wheel 聚合 / resize 去抖）均可在运行时覆盖
  - 不支持的能力调用返回 False + no-op；不抛异常
- 推荐对外 API（已/将提供）：
  - term_set_coalesce_move / term_get_coalesce_move
  - term_set_coalesce_wheel / term_get_coalesce_wheel
  - term_set_debounce_resize / term_get_debounce_resize
  - term_get_effective_config（返回快照，便于诊断）

## 对标导航 · 快速映射（crossterm/tcell)

### 门面 Beta 子集映射
- CreateTerminal → ITerminal（信息/输出/输入三分）
- ITerminal.Initialize/Finalize → term_init/term_done（幂等）
- ITerminalOutput
  - Write/WriteLn/Flush：直通 term_write/term_writeln/term_flush（内含缓冲）
  - Enable/DisableBuffering/IsBufferingEnabled：帧式写入优化
  - ExecuteCommand(s)：批处理命令，与 crossterm 的 execute(queue) 类似
- ITerminalInput
  - ReadKey/TryReadKey/HasInput：对应事件层映射
  - PeekKey/FlushInput：便于帧循环“窥视后消费”


- 详细映射（稳定子集）：
  - ITerminal
    - GetInfo/GetOutput/GetInput → 访问 Info/Output/Input 门面实例
    - EnterRawMode/LeaveRawMode → term_raw_mode_enable(True/False)
    - Reset → term_reset（若不可用则 no-op）
  - ITerminalOutput
    - SetForegroundColor/SetBackgroundColor → term_attr_foreground/background_*（含 TrueColor 路径）
    - SetAttribute/ResetAttributes → term_attr_set/reset
    - MoveCursor/Up/Down/Left/Right → term_cursor_move/…
    - Save/RestoreCursorPosition → term_cursor_save/restore
    - Show/HideCursor → term_cursor_visible(True/False)
    - ClearScreen/ScrollUp/ScrollDown → term_clear/term_scroll_*
    - SetScrollRegion/ResetScrollRegion → term_scroll_region_set/reset
  - ITerminalInput
    - ReadLine → 组合 ReadKey/TryReadKey 直至换行（非交互场景下避免阻塞）
    - PeekKey/FlushInput → term_input_peek/term_input_flush（若底层不支持则返回 False/no-op）

说明：
- 门面 Beta 坚持“不破坏 C API 行为语义”的约束；所有能力均以 term_support_* / compatible 前置判断为准，失败/不支持时返回 False 或 no-op；不抛异常。


### 门面 Beta 对标表（Rust crossterm / Go tcell）
- ITerminal
  - Initialize/Finalize ↔ 初始化/清理（crossterm 无直对；tcell Screen.Init/Fini 概念上相近）

#### 门面 Beta 速查表（方法 → C API）
- ITerminal
  - Initialize → term_init
  - Finalize → term_done
  - EnterRawMode → term_raw_mode_enable(True)
  - LeaveRawMode → term_raw_mode_enable(False)
  - Reset → term_reset（若不可用则 no-op）
- ITerminalOutput
  - Write/WriteLn/Flush → term_write/term_writeln/term_flush
  - SetForegroundColor/SetBackgroundColor → term_attr_foreground/background_*（含 RGB）
  - SetAttribute/ResetAttributes → term_attr_set/reset
  - MoveCursor*(Up/Down/Left/Right) → term_cursor_*
  - Save/RestoreCursorPosition → term_cursor_save/restore
  - Show/HideCursor → term_cursor_visible(True/False)
  - ClearScreen/ScrollUp/ScrollDown → term_clear/term_scroll_*
  - SetScrollRegion/ResetScrollRegion → term_scroll_region_set/reset
  - ExecuteCommand(s) → aOutput.Write + 缓冲/Flush 策略（批处理）
- ITerminalInput
  - ReadKey/TryReadKey/HasInput → term_event_poll + 事件映射
  - PeekKey/FlushInput → term_input_peek/term_input_flush

  - EnterRawMode/LeaveRawMode ↔ crossterm::terminal::enable_raw_mode/disable_raw_mode；x/term.MakeRaw
  - EnableAltScreen（在门面守卫里）↔ crossterm::terminal::Enter/LeaveAlternateScreen；tcell AltScreen
- ITerminalOutput
  - Write/WriteLn/Flush ↔ crossterm::queue/execute + stdout.flush；tcell Screen.Show
  - SetForeground/Background/Attribute/Reset ↔ crossterm::style::*；termenv.Style
  - Cursor/Save/Restore/Visible ↔ crossterm::cursor::*；tcell ShowCursor
  - Clear/Scroll/Region ↔ crossterm::terminal::*；tcell 各种清屏与滚动 API
  - ExecuteCommands(批) ↔ crossterm::queue/execute 批命令；tcell 提交后统一 Show
- ITerminalInput
  - ReadKey/TryReadKey/HasInput ↔ crossterm::event::read/poll；tcell PollEvent
  - PeekKey/FlushInput ↔ 无强制对标，作为帧循环便利方法

说明：若底层能力不支持，门面 API 返回 False 或 no-op；不抛异常。


- 事件与输入
  - crossterm::event::poll/read ↔ term_events_poll/term_events_collect（支持超时/预算/合并）
  - tcell PollEvent ↔ term_events_collect（帧式收集 + Move/Resize 合并/去抖）
- 模式守卫
  - crossterm::terminal::enable_raw_mode/disable_raw_mode ↔ term_raw_mode_enable/disable + TTermModeGuard
  - enable/disable mouse/focus/paste/alt screen ↔ term_mouse_/term_focus_/term_paste_bracket_/term_alternate_screen_enable（成对）
- 输出/属性
  - crossterm::style::Color/Cursor ↔ term_attr_* / term_cursor_* / term_clear_*
  - term 支持 16/256/TrueColor 自动降级；Windows VT 失败自动回退
- 终端信息
  - size/tty/capabilities ↔ term_size/term_is_tty/term_support_*（懒探测）

说明：
- C 风格 API 为稳定外观；OOP 门面（ITerminal/Output/Input）作为易用层逐步收敛为 Beta 稳定子集
- 推荐帧模型：每帧先 collect（预算/合并）→ 更新状态 → 渲染缓冲 → 一次 flush

- 建议环境变量（规划，默认不影响现状）：
  - FAFAFA_TERM_POLL_IDLE_SLEEP_MS：空轮询时的极短 sleep（0 表示不 sleep）
  - FAFAFA_TERM_POLL_BACKOFF：是否启用指数退避（on/off）

> 注：上述“规划项”不会改变默认行为；仅作为可调开关以便在不同环境下微调空转 CPU 利用率。


## 输出缓冲最佳实践（queue/flush）

- 帧式模型建议：每帧“先收集事件（预算/合并）→ 渲染拼接字符串 → 一次 term_flush 写出”。
- 推荐在高频 write 的路径上使用 queue 聚合，避免碎片化 I/O 与光标闪动。
- 幂等性：空 flush 不产生输出，重复 flush 不重复输出（有测试覆盖）。
- 示例：

```pascal
term_queue('cursor to 1,1');
term_queue(ANSI_CURSOR_MOVE(1,1));
term_queue('Hello, ');
term_queue(['world ', 123]);
term_flush; // 一次性写出
```

## 核心功能

### 🎯 主要特性

### 近期变更（2025-08-20）

- 能力探测守卫一致化：所有“无参 support_*”在未初始化（_term=nil）时统一返回 False（不抛异常），与 support_ansi/color_* 行为一致；便于上层（logging/benchmark/test）在早期调用探测，而不阻塞流程。
- 空串写入健壮性：term_write(aTerm; string/WideString/UCS4String) 在 Length=0 时快速返回，避免取 @s[1]/@s[0] 指针；无行为变化。
- 宏统一：使用 FAFAFA_CORE_INLINE 作为唯一 inline 控制宏，清理历史 FAFAFA_ITERM_INLINE（接口声明处全部替换）。
- 废弃 API 标注：term_evnet_push(const aEvent: term_event_t) 标记为 deprecated，替代为 term_event_push。


## 快速开始（Quick Start）

- 构建与运行示例（Windows/Lazarus）：
  - 安装 lazbuild 并确保在 BuildDemo.bat 中配置了正确的路径
  - 运行 scripts\build_demo.bat，生成 demos\simple_ui\demo_simple_ui.exe
  - 运行 demo_simple_ui.exe，界面说明：
    - 顶部横幅（0-based 坐标 write_at 示例）
    - with_view 视口 + Origin 滚动（w/j 上滚，s/k 下滚）
    - q/Q 退出；终端尺寸变化会自动刷新

- 与 signal center 的集成（WINCH）：默认已启用；可在 settings.inc 注释 FAFAFA_TERM_USE_SIGNALCENTER_WINCH 回退。
  - Unix：通过 signal center 的 sgWinch 触发 tek_sizeChange；term_unix 初始化默认调用 SignalCenter.ConfigureWinchDebounce(16)，开箱即用的 16ms 去抖（可在上层覆盖）。
  - Windows：通过 ReadConsoleInputW 的 WINDOW_BUFFER_SIZE_EVENT 触发 tek_sizeChange（不经过 signal center）。可在 UI 帧循环内进行 16–33ms 合并以平滑重绘。
  - 背压建议：如使用 SignalCenter.WaitNext 轮询，建议 ConfigureQueue 设置容量与策略（窗口抖动时可 qdpDropOldest）。

  - 最佳实践速记（不跳转版）：
    - 只选一种消费模式：回调 或 WaitNext/Channel（不要混用，否则会竞争同一事件）。
    - 去抖与合并：UI 帧内再做 16–33ms 的 WINCH 合并；signal center 已对“连续 sgWinch”做尾部合并。
    - 队列策略：WINCH 容易抖动，推荐 ConfigureQueue(容量>=256, qdpDropOldest)。
    - 回调规范：回调在派发线程执行，务必短小、无阻塞；将重逻辑转发到 UI 线程或队列。
    - Windows 提示：仅当存在订阅者时 Ctrl 事件会“被处理并抑制默认行为”；退出请在回调中主动触发。

  - 跨平台差异：参考 signal 文档的“跨平台兼容性清单”（Linux/macOS/BSD/Windows 差异与注意事项）
    - 见：fafafa.core.signal.md#跨平台兼容性清单


#### WINCH 去抖实现示例（伪代码）
##### 回退宏操作步骤

- 全局回退（编辑 settings.inc）
  - 打开 src/fafafa.core.settings.inc，将如下定义注释掉：

    {$DEFINE FAFAFA_TERM_USE_SIGNALCENTER_WINCH}

    注释后：

    {.$DEFINE FAFAFA_TERM_USE_SIGNALCENTER_WINCH}

  - 回退效果：term_unix 将恢复原有 fpSigAction 安装/清理路径；Windows 不受影响。
  - 说明：settings.inc 为全局配置，回退会影响依赖该配置的所有模块；提交前请确认范围。


```pascal
uses fafafa.core.signal, fafafa.core.term;

const DEBOUNCE_MS = 16; // 16~33ms 之间均可
var
  WinchTok: Int64 = 0;
  WinchPending: Boolean = False;
  WinchLastTs: QWord = 0;

procedure OnWinch(const S: TSignal);
begin
  WinchPending := True;
  WinchLastTs := GetTickCount64;
end;

procedure InitWinch;
var C: ISignalCenter;
begin
  C := SignalCenter; C.Start;
  // 背压建议：WINCH 容易抖动，设置队列容量并采用丢最旧，减少堆积
  C.ConfigureQueue(256, qdpDropOldest);
  WinchTok := C.Subscribe([sgWinch], @OnWinch);
end;

procedure FrameLoop;
var nowTs: QWord; W,H: Integer;
begin
  // 帧起
  termui_frame_begin;
  try
    // 合并：仅在距离上次 WINCH 超过 DEBOUNCE_MS 或帧末检查时处理一次
    if WinchPending then
    begin
      nowTs := GetTickCount64;
      if (nowTs - WinchLastTs) >= DEBOUNCE_MS then
      begin
        WinchPending := False;
        if term_size(W,H) then
          ; // 根据新尺寸刷新布局/缓冲
      end;
    end;

    // ... 其他绘制 ...

  finally
    termui_frame_end;
  end;
end;

procedure FiniWinch;
begin
  if WinchTok <> 0 then SignalCenter.Unsubscribe(WinchTok);
  WinchTok := 0;
end;
```
  if WinchTok <> 0 then begin SignalCenter.Unsubscribe(WinchTok); WinchTok := 0; end;
end;

procedure UiFrameTick;
var W,H: term_size_t; nowTs: QWord;
begin
  // 其他输入与渲染...
  nowTs := GetTickCount64;
  if WinchPending and (nowTs - WinchLastTs >= DEBOUNCE_MS) then
  begin
    WinchPending := False;
    if term_size(W, H) then
    begin
      // 在此合并派发一次 Resize（示例：写入事件队列或直接触发重布局）
      // term_event_push(tek_sizeChange, W, H);
    end;
  end;
end;
```

- 代码摘录：

```pascal
if term_size(W,H) then
  termui_with_view(0, 2, W, H-2, 0, ScrollOffset, @RenderList);
```

- 小贴士：
  - Ui 层坐标统一为 0-based：(line=Y, col=X)
  - 推荐在 frame_begin/end（由 termui_run 内部封装）中进行所有写入与填充
  - 如果需要在测试中观测输出，用内存后端；不设置后端时，门面 API 为 no-op

- **终端信息查询** - 获取终端尺寸、颜色支持、类型识别等信息
- **ANSI转义序列支持** - 完整的颜色控制、光标控制、屏幕操作
- **键盘输入处理** - 支持非阻塞输入、特殊键检测、组合键处理
- **终端模式控制** - 原始模式、规范模式切换，回显控制
- **跨平台兼容** - 支持 Windows、Unix、macOS 等平台
- **命令模式** - 支持批量操作和延迟执行
- **资源自动管理** - 自动状态保存与恢复

### 🏗️ 架构特点

- **现代化接口设计** - 清晰的接口抽象，易于使用和扩展
- **分层实现** - 接口 → 实现 → 平台特定的清晰分层
- **强类型安全** - 完整的类型定义和异常处理
- **高性能** - 支持缓冲输出，优化性能表现

## 快速开始

### 基本使用

```pascal
uses fafafa.core.term;

var
  LTerminal: ITerminal;
  LOutput: ITerminalOutput;
begin
  // 创建终端对象
  LTerminal := CreateTerminal;
  LOutput := LTerminal.Output;

  // 设置颜色并输出
  LOutput.SetForegroundColor(tcRed);
  LOutput.WriteLn('这是红色文本');
  LOutput.ResetColors;
end;
```

### 键盘输入处理

```pascal
var
  LTerminal: ITerminal;
  LInput: ITerminalInput;
  LKeyEvent: TKeyEvent;
begin
  LTerminal := CreateTerminal;
  LInput := LTerminal.Input;

  // 进入原始模式
  LTerminal.EnterRawMode;
  try
    LKeyEvent := LInput.ReadKey;
    WriteLn('按键: ', KeyEventToString(LKeyEvent));
  finally
    LTerminal.LeaveRawMode;
  end;
end;
```

## API 参考

### 核心接口

#### ITerminal - 主终端接口

主要的终端控制接口，整合了所有子功能。

```pascal
ITerminal = interface(IInterface)
  function GetInfo: ITerminalInfo;        // 获取终端信息
  function GetOutput: ITerminalOutput;    // 获取输出控制
  function GetInput: ITerminalInput;      // 获取输入控制

  procedure Initialize;                   // 初始化终端
  procedure Finalize;                     // 清理终端
  procedure SaveState;                    // 保存状态
  procedure RestoreState;                 // 恢复状态
  procedure EnterRawMode;                 // 进入原始模式
  procedure LeaveRawMode;                 // 离开原始模式
  procedure Reset;                        // 重置终端
end;
```

#### ITerminalInfo - 终端信息接口

提供终端基本信息查询功能，并包含环境与上下文的便捷查询。

```pascal
ITerminalInfo = interface(IInterface)
  // 尺寸与能力
  function GetSize: TTerminalSize;                    // 获取终端尺寸
  function GetCapabilities: TTerminalCapabilities;    // 获取终端能力
  function GetTerminalType: string;                   // 获取终端类型
  function IsATTY: Boolean;                           // 是否为终端设备
  function SupportsColor: Boolean;                    // 是否支持颜色
  function SupportsTrueColor: Boolean;                // 是否支持真彩色
  function GetColorDepth: Integer;                    // 获取颜色深度
  // 环境与上下文
  function GetEnvironmentVariable(const aName: string): string;  // 读取环境变量
  function IsInsideTerminalMultiplexer: Boolean;                  // 是否处于 tmux/screen 等复用器内
  // 属性便捷（通过方法读）
  property Size: TTerminalSize read GetSize;
  property Capabilities: TTerminalCapabilities read GetCapabilities;
  property TerminalType: string read GetTerminalType;
end;
```

示例：

```pascal
var Info: ITerminalInfo;
begin
  Info := TTerminalInfo.Create;
  // 读取常见环境变量
  WriteLn('TERM=', Info.GetEnvironmentVariable('TERM'));
  // 复用器检测（tmux/screen/TERM_PROGRAM）
  if Info.IsInsideTerminalMultiplexer then
    WriteLn('Running inside a terminal multiplexer')
  else
    WriteLn('Not in a terminal multiplexer');
end;
```

#### ITerminalOutput - 输出控制接口

提供完整的终端输出控制功能。


### 运行时配置优先级（推荐约定）

#### 环境变量控制能力覆盖（Unix/xterm）
- 支持通过环境变量强制覆盖 Unix 能力探测结果（用于诊断/兼容）：
  - FAFAFA_TERM_FEATURE_FOCUS=on|off|1|0
  - FAFAFA_TERM_FEATURE_PASTE=on|off|1|0
- 行为：
  - 覆盖仅影响 supports_focus / supports_bracketed_paste 与 compatibles 中 tc_focus_1004/tc_paste_2004 的纳入
  - 不影响 Windows 路径；不改变 ANSI 能力检测与写入前置判断
- 推荐：仅在诊断或特定环境兼容时使用；默认遵循自动探测


- 生效优先级：编译期默认 < 环境变量 < 运行时 Getter/Setter
- 读取时机：
  - 编译期默认：由 {$I fafafa.core.settings.inc} 等宏与常量提供
  - 环境变量：建议在 term_init 时懒加载一次（必要时提供刷新入口）
  - 运行时：调用 term_set_* / term_get_* 立即生效
- 建议最小集（示例，按现有实现命名对齐）：
  - term_set_coalesce_move / term_get_coalesce_move
  - term_set_coalesce_wheel / term_get_coalesce_wheel
  - term_set_debounce_resize / term_get_debounce_resize
- 行为边界：运行时设置应覆盖环境变量与编译期默认；term_done 后再次 term_init 应恢复至“编译期默认 + 环境变量”的新快照。

### term_events_collect 与轮询语义

- 轮询模型：
  - 非阻塞/带超时的事件收集接口（poll 或 events_collect）应保证在超时到达时 O(1) 退出，并且不污染内部状态
  - 鼠标移动/滚轮事件建议合并（coalesce），减少事件风暴
  - 终端 resize 建议做抖动防抖（debounce），在高频变化下压缩为有限数量的事件
- 参数与返回：
  - 超时单位明确记录（毫秒/微秒）；当超时=0 时立即返回，当超时<0 可视为阻塞
  - 返回的事件序应满足“时间单调不逆序”的最小保证
- 不变量：
  - term_init/term_done 可重复调用且幂等；任何异常均应恢复 console 模式（Windows 下包含 Quick Edit 状态）
  - 启用鼠标时临时关闭 Quick Edit，退出/禁用时恢复
- 测试建议：
  - Test_EventPoll_Timeout_NoCrash：在短超时下多次调用不异常且无状态泄露
  - Test_Wheel_Bounds：滚轮事件边界与合并
  - Test_Resize_Debounce：resize 风暴下事件数量与最终尺寸一致

```pascal
ITerminalOutput = interface(IInterface)
  // 基本输出
  procedure Write(const aText: string);
  procedure WriteLn(const aText: string = '');
  procedure Flush;

  // 颜色控制
  procedure SetForegroundColor(aColor: TTerminalColor);
  procedure SetBackgroundColor(aColor: TTerminalColor);
  procedure SetForegroundColorRGB(aColor: TRGBColor);
  procedure SetBackgroundColorRGB(aColor: TRGBColor);
  procedure ResetColors;

  // 文本属性
  procedure SetAttribute(aAttribute: TTerminalAttribute);
  procedure ResetAttributes;

  // 光标控制
  procedure MoveCursor(aX, aY: Word);
  procedure MoveCursorUp(aLines: Word = 1);
  procedure MoveCursorDown(aLines: Word = 1);
  procedure MoveCursorLeft(aCols: Word = 1);
  procedure MoveCursorRight(aCols: Word = 1);
  procedure SaveCursorPosition;
  procedure RestoreCursorPosition;
  procedure ShowCursor;
  procedure HideCursor;

  // 屏幕控制
  procedure ClearScreen(aClearType: TTerminalClearType = tctAll);
  procedure ScrollUp(aLines: Word = 1);
  procedure ScrollDown(aLines: Word = 1);
  procedure EnterAlternateScreen;
  procedure LeaveAlternateScreen;
end;
```

#### ITerminalInput - 输入控制接口

提供键盘输入处理功能。

```pascal
ITerminalInput = interface(IInterface)
  // 基本输入
  function ReadKey: TKeyEvent;
  function TryReadKey(out aKeyEvent: TKeyEvent): Boolean;
  function ReadLine: string;
  function HasInput: Boolean;

  // 模式控制
  procedure SetMode(aMode: TTerminalMode);
  function GetMode: TTerminalMode;
  procedure EnableEcho;
  procedure DisableEcho;
  function IsEchoEnabled: Boolean;

  // 超时控制
  procedure SetReadTimeout(aTimeoutMs: Cardinal);
  function GetReadTimeout: Cardinal;
end;
```


## Windows VT 启用与颜色降级策略

- Windows控制台默认可能不启用 ANSI/VT 序列，需要调用 SetConsoleMode 启用 ENABLE_VIRTUAL_TERMINAL_PROCESSING；
- 当无法启用 VT 序列时，模块会自动采用退化路径（例如使用 Windows API 光标移动），并对颜色进行降级处理；
- 颜色降级：当终端不支持 24 位真彩色时，内部将 24bit 颜色降级到 256 色或 16 色近似：
  - 256 色：映射到 xterm 6x6x6 色立方（16..231）或灰度带（232..255）；
  - 16 色：根据亮度与主色分量映射到 0..7/8..15；

注意：某些边界颜色（如纯黑/纯白）在不同终端实现中可能既可落在 6x6x6 立方，也可被视为灰度带，本模块允许两者作为等价近似。


## UI 门面速览与最佳实践

- 门面入口（单元）：fafafa.core.term.ui
- 常用顺序
  - 可选帧缓冲：termui_frame_begin → 执行绘制 → termui_frame_end
  - 可选视口：termui_push_view(ViewX,ViewY,ViewW,ViewH, OriginX,OriginY) → 局部绘制 → termui_pop_view
  - 绘制原语：termui_write/termui_writeln、termui_write_at、termui_fill_line、termui_fill_rect
  - 样式设置：termui_fg24/termui_bg24、termui_set_attr/termui_attr_reset、预设 termui_attr_preset_info/warn/error
- 参数顺序小贴士：所有 write_at/writeln_at 族 API 的坐标顺序为 (line=Y, col=X)
- 字符串类型建议：优先使用 UnicodeString；传入 AnsiString 时优先调用提供的重载，避免隐式转换告警

  - 脏区：termui_invalidate_all/termui_invalidate_rect（frame 模式下用于限定刷新）
- 坐标与索引
  - UI 使用 0-based 行列；如未启用帧缓冲，底层会在必要时转换为 1-based 控制台坐标
  - push_view 的 Origin 会在局部坐标基础上叠加到屏幕坐标，便于实现滚动或相对布局
- Backend 判空
  - 若 UiBackendGetCurrent=nil，所有 termui_* 将安全返回而不抛异常，便于在无后端/测试环境中调用
- 测试与内存后端
  - 使用内存后端进行单测：CreateMemoryBackend(w,h) → UiBackendSetCurrent(B) → 绘制 → MemoryBackend_GetBuffer(B)
  - 建议在帧缓冲下进行涉及视口/原点的绘制测试，保证路径与生产一致

最小示例（Memory Backend）：

```pascal
var B: IUiBackend; Buf: TUnicodeStringArray;
begin
  B := CreateMemoryBackend(8,4);
  UiBackendSetCurrent(B);
  termui_frame_begin;
  termui_write_at(2,2,'XY');
  termui_frame_end;
  Buf := MemoryBackend_GetBuffer(B);
end;
```

### 数据类型

#### 枚举类型

```pascal
// 终端颜色
TTerminalColor = (
  tcBlack, tcRed, tcGreen, tcYellow, tcBlue, tcMagenta, tcCyan, tcWhite,
  tcBrightBlack, tcBrightRed, tcBrightGreen, tcBrightYellow,
  tcBrightBlue, tcBrightMagenta, tcBrightCyan, tcBrightWhite, tcDefault
);

// 文本属性
TTerminalAttribute = (
  taReset, taBold, taDim, taItalic, taUnderline,
  taBlink, taReverse, taStrikethrough, taDoubleUnderline
);

// 按键类型
TKeyType = (
  ktChar, ktEnter, ktBackspace, ktTab, ktEscape, ktSpace, ktDelete,
  ktInsert, ktHome, ktEnd, ktPageUp, ktPageDown,
  ktArrowUp, ktArrowDown, ktArrowLeft, ktArrowRight,
  ktF1, ktF2, ktF3, ktF4, ktF5, ktF6, ktF7, ktF8, ktF9, ktF10, ktF11, ktF12,
  ktUnknown
);

// 修饰键
TKeyModifier = (kmShift, kmCtrl, kmAlt, kmMeta);
TKeyModifiers = set of TKeyModifier;

// 终端模式
TTerminalMode = (tmCanonical, tmRaw, tmCbreak);
```

#### 记录类型

```pascal
// 按键事件
TKeyEvent = record
  KeyType: TKeyType;
  KeyChar: Char;
  Modifiers: TKeyModifiers;
  UnicodeChar: UnicodeChar;
end;

// 终端尺寸
TTerminalSize = record
  Width: Word;
  Height: Word;
end;

// RGB颜色
TRGBColor = record
  R, G, B: Byte;
end;
```

### 工厂函数

```pascal
// 创建终端实例
function CreateTerminal: ITerminal;

// 创建终端命令
function CreateTerminalCommand(const aCommandString: string;
  const aDescription: string = ''): ITerminalCommand;

// 便捷函数
function GetTerminalSize: TTerminalSize;
function IsTerminal: Boolean;
function SupportsColor: Boolean;

// 辅助函数
function MakeRGBColor(aR, aG, aB: Byte): TRGBColor;
function ColorToRGB(aColor: TTerminalColor): TRGBColor;
function MakeKeyEvent(aKeyType: TKeyType; aKeyChar: Char = #0;
  aModifiers: TKeyModifiers = []; aUnicodeChar: UnicodeChar = #0): TKeyEvent;
function KeyEventToString(const aKeyEvent: TKeyEvent): string;
```

## 使用示例

### 颜色控制示例

```pascal
var
  LOutput: ITerminalOutput;
  LRGBColor: TRGBColor;
begin
  LOutput := CreateTerminal.Output;

  // 标准颜色
  LOutput.SetForegroundColor(tcRed);
  LOutput.WriteLn('红色文本');

  // RGB颜色
  LRGBColor := MakeRGBColor(255, 128, 64);
  LOutput.SetForegroundColorRGB(LRGBColor);
  LOutput.WriteLn('自定义RGB颜色');

  // 重置颜色
  LOutput.ResetColors;
end;
```

### 光标控制示例

```pascal
var
  LOutput: ITerminalOutput;
begin
  LOutput := CreateTerminal.Output;

  // 保存当前位置
  LOutput.SaveCursorPosition;

  // 移动光标并绘制
  LOutput.MoveCursor(10, 5);
  LOutput.Write('这里是 (10, 5)');

  // 恢复位置
  LOutput.RestoreCursorPosition;
  LOutput.WriteLn('回到原位置');
end;
```

### 键盘输入示例

```pascal
var
  LTerminal: ITerminal;
  LInput: ITerminalInput;
  LKeyEvent: TKeyEvent;
begin
  LTerminal := CreateTerminal;
  LInput := LTerminal.Input;

  LTerminal.EnterRawMode;
  try
    repeat
      if LInput.TryReadKey(LKeyEvent) then
      begin
        WriteLn('按键: ', KeyEventToString(LKeyEvent));
        if LKeyEvent.KeyType = ktEscape then
          Break;
      end;
      Sleep(10);
    until False;
  finally
    LTerminal.LeaveRawMode;
  end;
end;
```

### 屏幕控制示例

```pascal
var
  LOutput: ITerminalOutput;
begin
  LOutput := CreateTerminal.Output;

  // 清除屏幕
  LOutput.ClearScreen(tctAll);
  LOutput.MoveCursor(0, 0);

  // 进入备用屏幕
  LOutput.EnterAlternateScreen;
  LOutput.WriteLn('现在在备用屏幕中');
  ReadLn;

  // 离开备用屏幕
  LOutput.LeaveAlternateScreen;
end;
```

### 缓冲输出示例

```pascal
var
  LOutput: ITerminalOutput;
  I: Integer;
begin
  LOutput := CreateTerminal.Output;

  // 启用缓冲以提高性能
  LOutput.EnableBuffering;

  for I := 1 to 1000 do
    LOutput.Write('*');

  // 一次性输出所有内容
  LOutput.Flush;
end;
```

## 异常处理

模块定义了完整的异常体系：

```pascal
ETerminalError = class(ECore);              // 基础异常
ETerminalNotSupported = class(ETerminalError);  // 功能不支持
ETerminalModeError = class(ETerminalError);     // 模式切换错误
ETerminalInputError = class(ETerminalError);    // 输入处理错误
ETerminalOutputError = class(ETerminalError);   // 输出处理错误
```

### 异常处理示例

```pascal
var
  LTerminal: ITerminal;
begin
  try
    LTerminal := CreateTerminal;
    LTerminal.EnterRawMode;
    // ... 进行操作
  except
    on E: ETerminalModeError do
      WriteLn('终端模式切换失败: ', E.Message);
    on E: ETerminalError do
      WriteLn('终端操作错误: ', E.Message);
## Windows 行为与建议

本模块在 Windows 下对控制台能力与编码做了鲁棒处理，确保中文/Emoji 以及重定向/管道场景稳定输出。

- VT 启用与降级
  - 优先尝试启用虚拟终端序列（VT）。若启用失败则自动降级：颜色/样式调用将弱化为基础输出。
  - 能力位会按实际环境回落：tc_ansi 仅在 VT 可用时启用；tc_color_24bit 仅在 VT 可用时启用；tc_color_256 在 VT 可用或后端具备时启用。
- 写入回退链
  - 首选 WriteFile（原始句柄有效时），失败则尝试 WriteConsoleA，仍失败再转 UTF-16 并调用 WriteConsoleW。
  - 所有路径都做了异常屏蔽与长度切分，避免 101 Disk full 等 I/O 异常导致进程中止。
- 编码约定
  - 含中文/多字节字面量的单元请在文件首行加入：{$CODEPAGE UTF8}
  - 运行时请优先使用 term_write/term_writeln 输出（内部已做编码与回退）。
- 典型宿主差异
  - Windows Terminal：VT 完整支持；颜色/样式最佳。
  - PowerShell/CMD：部分环境默认未启用 VT，本模块将自动降级；颜色效果可能弱化。
  - 重定向/管道：通常不可用 VT/Console API，模块退回最基础写入路径，保证不崩溃。

最佳实践：
- 文件顶部放置 {$CODEPAGE UTF8}
- 使用 term_write/term_writeln 输出；设置颜色用 term_attr_set（自动适配能力）
- 对必须使用 WriteLn 的场景，考虑 {$I-} 和 IOResult 守护以避免宿主异常传播

  end;
end;
```

## 平台兼容性

### 支持的平台

- **Windows** - Windows 7 及以上版本
- **Linux** - 所有主流发行版
- **macOS** - macOS 10.12 及以上版本
- **FreeBSD** - FreeBSD 11 及以上版本

### 平台特定功能

| 功能 | Windows | Unix/Linux | macOS |
|------|---------|------------|-------|
| 基本颜色 | ✅ | ✅ | ✅ |
| 真彩色 | ✅ | ✅ | ✅ |
| 光标控制 | ✅ | ✅ | ✅ |
| 原始模式 | ✅ | ✅ | ✅ |
| 备用屏幕 | ✅ | ✅ | ✅ |
| 鼠标支持 | 🚧 | 🚧 | 🚧 |


### 事件读取语义（read/poll/帧内 budget）

- 读写模型
  - read：阻塞直到有事件到来；适合简单 REPL 型程序
  - poll(timeout)：在 timeout 毫秒内检查是否有事件；结合帧循环使用，可在无事件时让出时间片
- 帧内事件收集（term_events_collect）
  - 建议在每一帧开头调用 term_events_collect(aBudget, aCompose)
  - aBudget 控制本帧处理的最大事件数量，避免长尾事件淹没渲染
  - aCompose=true 时，内部会合并 MouseMove 与 Resize 等高频、可合并事件，降低刷新成本
- 推荐帧循环骨架

- 重要语义补充（term_events_collect）
  - 预算 budget=0：仅消费队列中已有事件，不会触发底层 event_pull；适合纯渲染帧或严格限时消费。
  - Move 合并：连续的鼠标移动（tms_moved）在同一帧被尾合并为最后一个位置；跨 burst 同样合并。
  - Resize 去抖：多次 tek_sizeChange 在同一帧仅保留最后一次，避免抖动。
  - 容量裁剪：收集数组容量 aMaxN 为上限，不会越界；多余事件留在队列中等待下一帧。
  - 实践建议：在帧开头先 collect，再更新状态与渲染；对于互动密集场景，使用适中的 budget（如 5~16ms）。

  - 先 collect（带预算/合并）→ 更新状态 → 渲染缓冲 → 一次 flush 输出
  - 鼠标拖拽/移动量大时，事件尾合并能显著减少 UI 抖动

### 能力开关矩阵（Raw/Mouse/Focus/Paste）

- Raw：进入原始模式，拿到非规范化输入（方向键、组合键等）
- Mouse：开启鼠标追踪；Windows 下临时关闭 Quick Edit，退出恢复

### Windows Quick Edit 守卫语义

- 目标：在启用鼠标追踪时避免“选择冻结输入”的现象；启用期间临时关闭 Quick Edit，关闭后恢复原始模式
- 性质：
  - 幂等：重复 enable/disable 不会错误翻转无关位
  - 嵌套：多次启用后按相反顺序关闭，最终恢复至最初 ConsoleMode
  - 异常安全：建议放入 try/finally；异常路径也会恢复
- 守卫范式：
  - 手动启停：term_mouse_enable(True/False)
  - 守卫对象：TTermModeGuard + term_mode_guard_acquire_current([...]) → term_mode_guard_done(guard)
- 相关测试：tests/fafafa.core.term/Test_term_windows_quickedit_guard.pas
  - Test_MouseEnabled_Temporarily_Disables_QuickEdit（临时关闭 Quick Edit）
  - Test_MouseEnableDisable_Idempotent（幂等）
  - Test_MouseToggle_Restores_Original_Mode（启停恢复）
  - Test_MouseEnable_Nested_Restore_Order（嵌套启停顺序）
  - Test_MouseEnable_ExceptionPath_Restores（异常路径恢复）
  - Test_ModeGuard_Nested_Restore_Order（守卫嵌套恢复）
  - Test_ModeGuard_ExceptionPath_Restores（守卫异常路径恢复）
  - Test_ModeGuard_MultiFlags_Mouse_Focus_Paste（多 flag 组合，确认 ConsoleMode 位语义）


#### 模式守卫最小用法（示例）

```pascal
var g: TTermModeGuard;
term_init;
try
  // 统一启用：Mouse 基础 + SGR(1006) + Focus(1004) + Bracketed Paste(2004)
  g := term_mode_guard_acquire_current([tm_mouse_enable_base, tm_mouse_sgr_1006, tm_focus_1004, tm_paste_2004]);
  try
    // ... 事件循环/渲染 ...
  finally
    term_mode_guard_done(g); // 统一恢复
  end;
finally
  term_done;
end;

#### ModeGuard 语义说明（补充）

- 目标：以守卫对象统一启停控制台模式与协议（鼠标/焦点/Bracketed Paste 等），并在异常路径自动恢复
- 嵌套/引用计数：
  - 同一 flag 多次 acquire，需以 LIFO 顺序释放；内部以计数或栈实现，最终恢复为进入前的 ConsoleMode
  - 幂等：如果外层已启用，内层重复启用不会影响最终恢复
- 异常路径：
  - 建议 try/finally 配合 term_mode_guard_done；若 finally 未执行，ModeGuard 的析构也会尝试恢复（尽量保证安全）
- 与鼠标/焦点/粘贴：
  - tm_mouse_enable_base 仅切 ConsoleMode；tm_mouse_sgr_1006/tm_focus_1004/tm_paste_2004 通过 ANSI 协议开关，基于能力探测降级

最小示例：

```pascal
var g: TTermModeGuard;
term_init;
try
  g := term_mode_guard_acquire_current([tm_mouse_enable_base, tm_mouse_sgr_1006, tm_focus_1004, tm_paste_2004]);
  try
    // ... 事件循环/渲染 ...
  finally
    term_mode_guard_done(g);
  end;
finally
  term_done;
end;
```

```

- Focus：开启焦点变化报告；依赖终端支持
- Bracketed Paste：让粘贴被 ESC[200~...ESC[201~ 包裹，可靠识别粘贴
- 矩阵原则
  - 启用在 try/finally 内完成；退出时成对关闭，保证异常路径也能恢复
  - 不支持的终端上优雅降级（写入失败不会导致异常终止）


## 事件模型与能力开关（对标现代终端库）

- 读取模型
  - read：阻塞读取下一事件；poll(timeout)：在给定时间内检查是否有事件，true 则随后的 read 不会阻塞。
  - 键盘事件在多数终端需 Raw 模式才能获得非规范化按键（例如方向键、组合键）。
- 能力开关
  - 鼠标与焦点等事件通常需要显式启用/禁用（Enable/Disable）。Windows 路径下，在鼠标启用期间会临时关闭 Quick Edit，退出后自动恢复。
  - Bracketed Paste（粘贴事件）：在支持的终端上启用后会发出 ESC[200~...ESC[201~ 包裹序列；Unix/xterm 路径已具备解析，事件类型为 tek_paste。
- 并发/线程
  - 不建议在多个线程混用不同的事件获取方式。请统一通过 term_events_collect 进行汇聚与节流。
  - 内部采用固定容量环形队列；满载时丢弃最旧事件；鼠标移动事件采用“尾合并”策略以降低刷新成本。

> 注：上述策略已在 Windows 路径落地（含 ConsoleMode 守卫与异常防御），Unix 路径将按支持度逐步增强。

> 🚧 表示计划支持但尚未实现

## 能力支持矩阵（当前状态）

- 说明：✅ 已支持；🟡 部分支持/计划中；❌ 暂不支持。Unix/xterm 路径采用渐进增强策略。

| 能力 | Windows Console/WT | Unix (xterm/termios) |
|---|---|---|
| 原始模式 Raw | ✅ 已实现 | 🟡 进行中（按终端检测渐进） |
| 读/轮询 read/poll | ✅ 语义对齐 | 🟡 语义保持一致（实现中） |
| 鼠标事件 | ✅ 启停含 Quick Edit 守卫 | 🟡 进行中（xterm 鼠标协议） |
| 窗口尺寸/Resize | ✅ | ✅ |
| 焦点事件 Focus | 🟡 规划 | 🟡 解析与事件已落地（启用需终端支持） |
| Bracketed Paste | 🟡 规划 | 🟡 解析已落地（tek_paste，边界 ESC[200~/201~） |
| 标题/图标设置 | ✅ | ✅ |
| 颜色与样式 | ✅ VT 可用时最佳，自动降级 | ✅ ANSI 兼容 |


### 粘贴事件（Bracketed Paste）读取示例

- 启用与解析
  - 在支持的终端启用 Bracketed Paste 后，粘贴内容会被 ESC[200~ 与 ESC[201~ 包裹。
  - Unix/xterm 路径解析该序列并生成 tek_paste 事件。
- 读取文本
  - 先从事件队列获取 tek_paste；再用 term_paste_get_text(ev.paste.id) 取回完整文本。
- 示例：

```pascal
var ev: term_event_t; s: string;
if term_event_poll(ev, 0) and (ev.kind = tek_paste) then
begin
  s := term_paste_get_text(ev.paste.id);
  // TODO: 处理 s
end;
```

- 备注
  - 为避免在变体记录中直接存放管理型字符串，粘贴文本暂存于模块内部的全局表；后续可根据需要提供清理策略（如定长环形缓冲或显式清理 API）。

注：当终端不支持目标能力时模块会自动降级，不会崩溃；建议统一通过 term_events_collect 获取事件，以享受环形队列与尾合并带来的性能收益。


### 粘贴存储治理

- 背景
  - 为避免长时运行的内存增长，模块为粘贴文本缓存提供治理 API。
- API
  - term_paste_clear_all：清空所有已缓存的粘贴文本
  - term_paste_trim_keep_last(N)：仅保留最近 N 条（含尾部重建快速路径）
  - term_paste_set_auto_keep_last(N)：设置自动修剪（N>0 生效，0 关闭）
  - term_paste_set_max_bytes(B)：设置累计字节上限（B>0 生效，0 关闭）
  - term_paste_set_trim_fastpath_div(Div)：设置快速路径阈值分母（默认 8，>=1）
  - term_paste_get_count / term_paste_get_total_bytes：查询当前条数与累计字节
- 推荐用法
  - 长生命周期程序建议在启动时设置双限：term_paste_set_auto_keep_last(64..256) + term_paste_set_max_bytes(1 shl 20)
  - 或在合适时机手动调用 term_paste_trim_keep_last / term_paste_clear_all
- 注意
  - 复杂度说明
    - 条数裁剪（trim_keep_last）：
      - 快速路径重建：O(k)（k 为保留数）；常数项低
      - 逐项左移：O(n)；在大量前缀移除时可能退化为 O(n^2)（多次左移叠加）
    - 字节上限回收：
      - 批量删除 + 重建：O(k)
      - 循环单步左移：O(n^2) 风险，已避免

  - 组合语义（auto_keep_last + max_bytes）：
    - 当追加新文本导致累计字节超过上限，且已开启 auto_keep_last (>0) 且“新文本本身不超过上限”时，优先仅保留最新一条（清空旧项）。
    - 否则按“批量删除最旧若干条直至不超过上限”的策略执行。
  - 自动修剪仅在 Unix/xterm 解析路径生成 tek_paste 时触发；其他路径不受影响
  - 条数与字节数双限可以协同工作；当任一条件触发时均会进行回收
  - 若需要更精细（例如 LRU、按来源区分等），可在后续版本扩展

#### 性能与一致性说明

- 一致性
  - 清空会重置累计字节（G_PASTE_TOTAL_BYTES := 0）
  - 裁剪（trim_keep_last）会基于剩余内容重新累计总字节
  - 字节上限回收在弹出最旧条目时同步扣减累计字节
- 安全性
  - 为避免对托管类型（string）使用底层 Move，内部采用逐项赋值的安全拷贝策略
- 性能建议
  - 建议组合使用条数与字节双限（例如 keep_last=64..256，max_bytes=512k..2m）
- 快速路径阈值
  - 含义：当 StartIdx > L div Div 时走“尾部重建”，避免 O(n^2) 左移
  - 默认：Div=8；API/环境变量均可修改
  - 场景：数据规模大且经常“保留尾部”时，较小分母（如 4~8）能降低裁剪耗时

  - 在高频/大体量粘贴场景下，尽量选择较小的 keep_last 与合理的 max_bytes 以降低回收成本
- 后续可选优化
  - 对于“仅保留最后 N 条且 N 远小于当前条数”的场景，可引入尾部重建的快速路径（一次性构建新数组）



### 推荐初始化（应用启动）

- 目的
  - 在应用启动时一次性启用粘贴存储治理，避免后续遗漏
- 建议范式

```pascal
// 在程序启动时：
term_paste_defaults(128, 1 shl 20); // 条数上限 128，字节上限 ~1MB
```

```pascal
// 或者一次性应用 + 档位（仅在未显式设置时生效，档位附带防覆盖）
term_paste_defaults_ex(128, 1 shl 20, 'tui');
```


- 说明
  - term_paste_defaults(aKeepLast, aMaxBytes) 等价于：
    - term_paste_set_auto_keep_last(aKeepLast)
    - term_paste_set_max_bytes(aMaxBytes)
  - 可根据业务调整，例如 CLI 工具选择更小的上限，GUI TUI 应用选择更大的上限


- 通过环境变量配置（无需改代码）
  - 仅在未显式设置时生效；可通过 FAFAFA_TERM_PASTE_DEFAULTS=off 禁用
  - 支持二进制后缀：k/m/g（如 512k, 1m, 2g）

  Windows PowerShell:

  ```powershell
  $env:FAFAFA_TERM_PASTE_KEEP_LAST = 128
  $env:FAFAFA_TERM_PASTE_MAX_BYTES = '1m'
  $env:FAFAFA_TERM_PASTE_TRIM_FASTPATH_DIV = 8
  # 关闭自动应用（如需让应用自行调用 term_paste_defaults）
  $env:FAFAFA_TERM_PASTE_DEFAULTS = 'off'
  ```

  Linux/macOS (bash/zsh):


### 推荐配置矩阵（参考）

- CLI 工具（短时运行、低频粘贴）
  - keep_last=64
  - max_bytes=512k
  - trim_fastpath_div=8
- TUI 应用（交互为主、中等粘贴量）
  - keep_last=128
  - max_bytes=1m
  - trim_fastpath_div=8
- 长驻后台/日志工具（长时运行、可能出现粘贴高峰）
  - keep_last=256
  - max_bytes=2m
  - trim_fastpath_div=4（更积极触发尾部重建）
- 开发/调试模式
  - keep_last=64..128
  - max_bytes=512k..1m（视本地机器情况）
  - trim_fastpath_div=8

说明：
- 建议按“条数 + 字节数”双限组合配置；二者任一触发即可回收，控制上限更稳定
- trim_fastpath_div 越小越容易走“尾部重建”快速路径，适合经常大幅裁剪前缀的场景
- 环境变量名：FAFAFA_TERM_PASTE_KEEP_LAST / FAFAFA_TERM_PASTE_MAX_BYTES / FAFAFA_TERM_PASTE_TRIM_FASTPATH_DIV


### 档位（Profile）一键配置

- API
  - term_paste_apply_profile(Profile: 'cli'|'tui'|'daemon'|'dev')
  - 防覆盖策略：仅在以下条件下写入，避免改动应用已显式设置的值
    - keep_last == 0 才写入
    - max_bytes == 0 才写入
    - trim_fastpath_div 仍为默认 8 时才写入
- 环境变量
  - FAFAFA_TERM_PASTE_PROFILE=cli|tui|daemon|dev
  - 仅在 FAFAFA_TERM_PASTE_DEFAULTS != off 时应用（与其它治理变量一致）
- 档位映射（参考）
  - cli：keep_last=64，max_bytes=512k，trim_fastpath_div=8
  - tui：keep_last=128，max_bytes=1m，trim_fastpath_div=8
  - daemon：keep_last=256，max_bytes=2m，trim_fastpath_div=4
  - dev：keep_last=128，max_bytes=1m，trim_fastpath_div=8（建议按需调整）
- 示例

```pascal
// 代码中按场景一键应用（仅在未显式设置时生效）
term_paste_apply_profile('tui');
```

```bash
# 通过环境变量启用（默认开启，可用 DEFAULTS=off 禁用）
export FAFAFA_TERM_PASTE_PROFILE=tui
```

  ```bash
  export FAFAFA_TERM_PASTE_KEEP_LAST=128
  export FAFAFA_TERM_PASTE_MAX_BYTES=1m
  export FAFAFA_TERM_PASTE_TRIM_FASTPATH_DIV=8
  # 关闭自动应用
  export FAFAFA_TERM_PASTE_DEFAULTS=off
  ```



## 应用启动初始化模板

```pascal
// 1) 初始化终端（会读取环境变量：KEEP_LAST/MAX_BYTES/TRIM_FASTPATH_DIV/PROFILE 等）
if not term_init then
  Halt(1);

// 2) 若环境未提供或未显式设置，回退到推荐值 + 档位（防覆盖策略在内部）
if (term_paste_get_auto_keep_last = 0) or (term_paste_get_max_bytes = 0) then
  term_paste_defaults_ex(128, 1 shl 20, 'tui');
```

说明：
- term_init 会在 DEFAULTS ≠ off 时读取 FAFAFA_TERM_PASTE_* 环境变量
- defaults_ex 提供一次性设置与档位应用；若已显式设置则不会被覆盖
- 强烈建议在“长时运行”应用中启用条数+字节双限，确保上限可控


## 协议开关（Alt Screen / Focus / Bracketed Paste / Mouse）

- 备用屏（Alternate Screen）
  - term_alternate_screen_enable(True/False)
  - 建议 UI 启动时开启，退出恢复
- 焦点 FocusIn/Out（CSI ?1004 h/l）
  - term_focus_enable(True/False)
  - 需要终端支持；不支持时内部优雅降级
- 括号粘贴 Bracketed Paste（CSI ?2004 h/l）
  - term_paste_bracket_enable(True/False)
  - 配合粘贴存储治理（条数+字节双限），建议在交互输入场景开启
- 鼠标追踪（基础/拖拽/SGR）
  - term_mouse_enable(True/False) → ?1000 h/l
  - term_mouse_drag_enable(True/False) → ?1002 h/l
  - term_mouse_sgr_enable(True/False) → ?1006 h/l

示例（启用→退出恢复）：



### 模式守卫范式（最小示例）

- 启停必须成对：所有协议开关建议放入 try/finally，异常路径也能恢复
- 幂等设计：重复 enable/disable 不应翻转无关位（Windows Quick Edit 守卫已实现）
- 建议顺序：启用 AltScreen → Focus → Paste → Mouse（含 Drag/SGR）；关闭按相反顺序

- 实践提示：在 finally 里逐项关闭的同时，确保 term_done 总能被调用（即便前面出现异常），避免残留模式影响后续进程/终端会话

```pascal
term_init;
try
  // 启动期按需启用能力（不支持时内部优雅降级为 no-op）
  term_alternate_screen_enable(True);
  term_focus_enable(True);
  term_paste_bracket_enable(True);
  term_mouse_enable(True);
  term_mouse_drag_enable(True);
  term_mouse_sgr_enable(True);

  // ... 执行你的渲染/事件循环 ...

finally
  // 退出期逐项恢复
  term_mouse_sgr_enable(False);
  term_mouse_drag_enable(False);
  term_mouse_enable(False);
  term_paste_bracket_enable(False);
  term_focus_enable(False);
  term_alternate_screen_enable(False);
  term_done;
end;
```

## 帧循环最佳实践清单

- 推荐流程

- 重要提醒（No-Event 帧）：
  - 在大多数帧里，“无事件”是常态；term_events_collect 在预算内做有限次拉取与合并，若无事件应 O(1) 返回
  - 建议：根据渲染预算设置每帧拉取上限（如 N=64），并合并 MouseMove/Resize，避免输入洪峰导致卡顿


- 最小帧循环（含 collect 预算与合并示例）

```pascal
var evs: array[0..31] of term_event_t; n: SizeUInt; running: Boolean = True;
term_init;
try
  term_alternate_screen_enable(True);
  term_focus_enable(True);
  term_paste_bracket_enable(True);
  term_mouse_enable(True);
- 速查分片：docs/partials/term.paste.best_practices.md（建议直接采用该清单上线配置）

  while running do
  begin
    // 每帧 8ms 预算：合并 Move/Resize，避免输入洪峰拖垮渲染
    n := term_events_collect(evs, Length(evs), 8);
    // 处理事件并更新状态
    // for i := 0 to n-1 do HandleEvent(evs[i], running);

    // 渲染与输出（示意）
    // render_to_buffer(Model);
    // flush_diff();
  end;

- Windows 输出调试开关：
  - FAFAFA_TERM_WIN_FORCE_WRITEFILE=1 时，强制使用 WriteFile 原始字节输出（默认关闭）。
  - 默认使用 WriteConsoleW（UTF-16）输出以获得更好的 Unicode 与 VT 兼容性。


  - 参数：N 为追加次数（默认 200000），会对 legacy 与 ring 两种后端分别执行 append/trim 计时

- 失败注入（仅测试/排障）：
  - FAFAFA_TERM_FORCE_PLATFORM_FAIL=1 时，term_default_create_or_get 将返回失败，用于验证错误通路与 term_last_error()
  - 测试示例：tests/fafafa.core.term/Test_term_last_error_injection.pas

finally
  term_mouse_enable(False);
  term_paste_bracket_enable(False);
  term_focus_enable(False);
  term_alternate_screen_enable(False);
  term_done;
end;
```
  - 基线建议值：
    - 低/中等频率粘贴：keep_last=128，max_bytes=1m（tui 档位）
    - 高频/大体量粘贴：keep_last=64..128，max_bytes=1m..2m，trim_fastpath_div=4..8
  - 解释：ring 后端下 append/trim 耗时趋于线性与均摊 O(1)，但总字节越大、cache 压力越高；因此推荐选择更小的 keep_last 并合理设定 max_bytes



## Paste 后端选择与推荐配置

- 后端选择（behind-a-flag）：
  - 默认：legacy（数组存储 + 批量修剪）
  - 可选：ring（环形存储，append/trim 均摊 O(1)），通过环境变量启用
    - FAFAFA_TERM_PASTE_BACKEND=ring

- 推荐配置档位（可与 FAFAFA_TERM_PASTE_DEFAULTS/PROFILE 配合）：
  - CLI：keep_last=64，max_bytes=512k
  - TUI：keep_last=128，max_bytes=1m
  - Daemon/Service：keep_last=256，max_bytes=2m
  - Dev/Debug：keep_last=128，max_bytes=1m

- 如何开启 ring 并运行微基准：
  - 构建 benchmarks：tests/fafafa.core.term/benchmarks/build_benchmarks.bat
  - 运行：tests/fafafa.core.term/bin/benchmark_paste_backends.exe [N]
  - 输出将包含 legacy 与 ring 的 append 与 trim 耗时对比


> 小贴士：可在运行时动态切换后端（不建议在高并发场景频繁切换）
>
> ```pascal
> // 切换为环形后端（建议在初始化后、事件循环之前）
> if not term_paste_use_backend('ring') then
>   ; // 非法参数将返回 False

#### 微基准示例（Windows，本地一次跑样）

```
Benchmark paste backends with N=200000
: append x200000 in 10 ms; count=200000 total=1400000
: trim_keep_last(0) in 0 ms; count=200000 total=1400000
ring: append x200000 in 14 ms; count=200000 total=1400000
ring: trim_keep_last(0) in 0 ms; count=200000 total=1400000
ring: append x200000 in 10 ms; count=50204 total=3514428
ring: trim_keep_last(128) in 0 ms; count=128 total=8996
```

- 读取与解读
  - append：在当前小字符串与本机条件下 legacy 与 ring 差距较小；在更大 N / 混合长短 paste 场景，ring 复杂度更稳定
  - trim_keep_last：ring 为 O(1) 均摊，N 越大优势越明显；配合 auto_keep_last 与 max_bytes 可避免 O(n) 重建
- 运行
  - 构建：tests/fafafa.core.term/benchmarks/build_benchmarks.bat
  - 执行：bin/benchmark_paste_backends.exe [N]

> ```

### 行为语义补充

- 单条粘贴超过 max_bytes：
  - 若 max_bytes>0 且单条项长度本身已超过上限，当前实现将通过修剪使存储最终为空（以严格满足上限约束）。
  - 建议：对需要保留超长粘贴的场景，显式提高 max_bytes 或关闭上限（设为 0）。

- legacy vs ring 差异（实现层面）：
  - 修剪复杂度：legacy 为批量重建数组（最坏 O(n)），ring 为按 chunk/head 弹出（均摊 O(1)）。
  - 统计维护：两者均维护 total_bytes；ring 通过入/出队精确增减，避免全量重算。
  - auto_keep_last 语义：两者一致，若启用且最新项长度 <= max_bytes，可快速“仅保留最新项”。
  - 单条超限：两者一致，最终清空以满足上限约束。



  1) 每帧开始：term_events_collect(budget, compose=true)
  2) 基于事件更新 Model（应用状态）
  3) 渲染到内存缓冲（行/块）
  4) 对比前一帧缓冲，做极简 diff 输出（按行/按块）
  5) 需要时使用 term_sync_update_enable 控制刷新频率，最后一次性输出
  6) try/finally 中成对启停 AltScreen/Focus/Mouse/Paste 等协议

- 设计要点
  - 限制每帧事件处理上限（budget），避免输入洪峰拖垮渲染
  - 合并高频可叠代事件：MouseMove / Resize
  - 渲染输出分离：先构建缓冲，再一次性写出，降低闪烁
  - 示例参考：examples/fafafa.core.term/07_frame_loop_demo.lpr（含行级 diff 雏形）

- 退出策略
  - 键盘/信号触发退出；在 finally 中恢复模式与屏幕
  - 对于异常路径，确保 term_mode_guard_done 与 term_done 得到执行

```pascal
term_init;
try
  // 建议：进入备用屏 + 开启交互相关协议
  term_alternate_screen_enable(True);
  term_focus_enable(True);
  term_paste_bracket_enable(True);
  term_mouse_enable(True);
  term_mouse_drag_enable(True);
  term_mouse_sgr_enable(True);

  // ... 执行你的 UI 帧循环 ...

finally
  // 退出时恢复
  term_mouse_sgr_enable(False);
  term_mouse_drag_enable(False);
  term_mouse_enable(False);
  term_paste_bracket_enable(False);
  term_focus_enable(False);
  term_alternate_screen_enable(False);
  term_done;
end;
```

### 同步输出（Synchronized Updates，?2026）

- 作用：在支持的终端上减少刷新闪烁，适合帧式渲染阶段短暂启用
- API：term_sync_update_enable(True/False)
- 建议：
  - 在每帧绘制前开启，帧结束后关闭；或在进入 UI 循环时开启、退出时关闭
  - 未支持的终端会优雅降级（ANSI 能力检测不通过时返回 False，不报错）
- 示例：

```pascal
term_init;
try
  term_sync_update_enable(True);

## 帧式循环与双缓冲 diff（设计与落地）

- 目标
  - 降低闪烁、减少输出体量、稳定帧率
  - 与 term_events_collect 的帧预算协同：先收集事件，再渲染，再最小化 diff 输出

- 模型
  - 前缓冲 FrontBuffer：上一帧的屏幕快照（行数组/块数组）
  - 后缓冲 BackBuffer：本帧渲染产物
  - Diff：比较 Back vs Front，仅输出差异段；输出完成后将 Back 交换/复制为 Front

- 粒度
  - 行级（当前推荐）：逐行比较，输出第一个不同位置到行尾；对长行可再切分为小块
  - 块级（可选演进）：维护栅格块（如 8xN）以降低单次重绘跨度

- 同步输出配合
  - 在支持 ?2026 的终端：帧开始 term_sync_update_enable(True)，帧结束 False，减少中间绘制的可见性

- 伪代码（简化版）

```pascal
termui_frame_begin; // 清空 BackBuffer
try
  // 渲染阶段：写入 BackBuffer（坐标均为 0-based）
  // draw_model(Model, BackBuffer);
finally
  // Diff 输出阶段
  // for each line i: if Back[i] <> Front[i] then
  //   MoveCursor(0,i); Write(Back[i]); Front[i] := Back[i];
  termui_frame_end;
end;
```

- 无后端/不可用场景
  - UiBackend=nil：所有写入 no-op；仍可维持帧循环与事件处理，不崩溃

- 性能建议
  - 尽量按行或小块绘制，避免大范围覆盖
  - 将昂贵的计算提前/缓存；每帧仅做最少的 diff 与输出
  - 高刷新场景建议开启同步输出（若支持）并限制事件预算，避免输入洪峰拖垮渲染

- 行内阈值自适应（清行策略）
  - 依据每行差异占比决定“分段输出”或“清行+整行重绘”，默认阈值 0.35（35%）
  - 覆盖方式：环境变量 FAFAFA_TERM_DIFF_LINE_THRESHOLD=0..1
  - 清行：CSI 2K；重绘时采用该行起始单元的样式，输出整行文本后重置样式
  - 适用：当某行变更密集（>35%）时，该策略显著减少碎片化光标移动与多段写入


  // ... 帧渲染 ...
finally
  term_sync_update_enable(False);
  term_done;
end;
```



## Unix 等待策略（高级）

- 目的
  - 在 Unix 下按需启用“更省电/低 CPU”的等待策略，减少空闲轮询
- 默认行为（保持不变）
  - 原始模式：VMIN=0 / VTIME=0（非阻塞，无超时）
  - 事件拉取：非阻塞轮询 + 10ms usleep，直到超时
- 可选增强（Unix 专用 API）
  - term_unix_set_read_timeout_ms(ms)：便捷映射到 VTIME（100ms 粒度，0..255）
  - term_unix_set_tty_read_params(vmin, vtime_decisec)：直接设置 VMIN/VTIME
  - term_unix_set_blocking_pull(true)：term_event_poll/pull 将使用 select 按剩余超时阻塞等待
- 建议搭配
  - 仅在“长时等待、低交互”场景开启 blocking_pull
  - 结合小超时（如 100~500ms）与 UI 帧调度，避免交互延迟
- 示例

```pascal
{$IFDEF UNIX}
// 1) 启用阻塞等待（pull 将用 select 等待）
term_unix_set_blocking_pull(True);

// 2) 可选：让 TTY read 自带超时（100ms 粒度）
term_unix_set_read_timeout_ms(200); // VTIME=2，最长 200ms
{$ENDIF}
```

注意：以上 API 仅在 Unix 下生效；Windows 路径保持基于 Console API 的事件模型。

## 无后端时的 no-op 场景

- 设计目的
  - UiBackendGetCurrent=nil 时，termui_* API 会安全返回（no-op），方便在测试或控制台不可用的环境下运行通用逻辑。
- 常见用法
  - 业务逻辑统一调用 termui_*，在测试场景不设置 backend，保证逻辑路径仍可覆盖而不会触发 I/O。
  - 命令行工具在非交互模式（例如重定向输出）下，仍可执行，不因 UI 调用失败。
- 注意事项
  - 如果需要观测输出，请显式设置内存后端：CreateMemoryBackend/UiBackendSetCurrent。
  - no-op 仅保证“不会出错”，不会帮助你捕获渲染问题；必要时使用内存后端结合测试断言。

## 典型渲染循环模式

- 推荐使用帧缓冲（frame_begin/end）包装每帧绘制：
  - 开始帧：termui_frame_begin
  - 执行绘制：termui_write/termui_write_at/termui_fill_rect/…
  - 结束帧：termui_frame_end（内部比较 backbuffer 与 frontbuffer，仅输出差异段）
- 局部更新 vs 全局重绘：
  - 局部更新：调用 termui_invalidate_rect(x,y,w,h)，尽量缩小重绘范围
  - 全局重绘：调用 termui_invalidate_all（例如终端尺寸变更、主题切换等）
- 视口与原点：
  - 使用 termui_push_view(ViewX,ViewY,ViewW,ViewH, OriginX,OriginY) 推送视口与原点
  - 局部绘制完成后 termui_pop_view，或使用 termui_with_view 包装
- 建议：涉及视口/原点与脏区的路径，优先在帧模式下运行以获得最佳刷新性能与稳定性

示例：

```pascal
termui_frame_begin;
try
  termui_push_view(2,1,20,5,0,0);
  termui_fill_rect(0,0,20,1,'=');
  termui_write_at(0,1,'Title');
  termui_pop_view;
finally
  termui_frame_end;
end;
```

## 性能优化

### 缓冲输出

对于大量输出操作，建议使用缓冲模式：

```pascal
LOutput.EnableBuffering;
try
  // 大量输出操作
  for I := 1 to 10000 do
    LOutput.Write(SomeText);
finally
  LOutput.Flush;  // 一次性输出
end;
```


## Windows / Unix 差异概览（集中）

- 输入/事件路径
  - Windows：ReadConsoleInputW → 原生键盘/鼠标/焦点；无需 1004 也可获得 FOCUS_EVENT
  - Unix：termios 字节流解析；SIGWINCH 尺寸变化；鼠标/焦点/粘贴依赖 CSI/OSC 协议

- 协议开关能力
  - Windows：VT 成功后具备 ANSI/TrueColor/?1049/?2026（2004 通常不可用）
  - Unix：1000/1002/1006 鼠标、1004 焦点、2004 粘贴普遍可用（视终端/复用器）

- 模式守卫
  - Windows：启鼠标时临时关闭 Quick Edit，退出恢复；幂等、可嵌套、异常安全
  - Unix：try/finally 成对启停 CSI ?...h/l，异常路径确保恢复

- 降级策略
  - 能力检测不通过时 API 为 no-op 幂等，不抛异常；颜色自动降级至 256/16 色

- 建议
  - 统一通过 term_events_collect 读取事件，配合帧预算与尾合并
  - 输出建议使用缓冲 + 同步输出（若支持），最后一次性 flush

### 非阻塞输入

对于实时应用，使用非阻塞输入：

```pascal
while not ShouldExit do
begin
  if LInput.HasInput then
  begin
    LKeyEvent := LInput.ReadKey;
    ProcessKey(LKeyEvent);
  end;

  // 处理其他任务
  DoOtherWork;
  Sleep(1);
end;
```

## 最佳实践

### 1. 资源管理

始终确保正确的资源清理：

```pascal
var
  LTerminal: ITerminal;
begin
  LTerminal := CreateTerminal;
  LTerminal.SaveState;
  try
    // 进行终端操作
    LTerminal.EnterRawMode;
    // ... 操作代码
  finally
    LTerminal.RestoreState;
  end;
end;
```

### 2. 错误处理

对终端操作进行适当的错误处理：

```pascal
try
  LTerminal.EnterRawMode;
  // ... 操作
except
  on E: ETerminalError do

### Windows 与 Unix 差异概览（快速导航）

- 输入/事件
  - Windows：ReadConsoleInputW 提供键盘/鼠标/焦点事件；无需 1004 即可获得 FOCUS_EVENT
  - Unix：termios + 字节流解析；SIGWINCH 通知尺寸变化；鼠标/焦点/粘贴通过 CSI/OSC 协议
- 协议与能力
  - Windows：VT 成功后可用 ANSI/TrueColor/?1049/?2026；Bracketed Paste(2004) 通常不可用
  - Unix：1000/1002/1006 鼠标、1004 焦点、2004 粘贴较为通用（需终端/复用器支持）
- 模式守卫
  - Windows：启鼠标时临时关闭 Quick Edit，退出恢复（防止选择导致输入冻结）
  - Unix：以 try/finally 成对启停 CSI ?...h/l 开关，异常路径确保恢复
- 回退策略
  - 优先 SGR(1006) → 退回 1002 → 仅 1000；若 ANSI 不可用则退化到基本输出
  - 不支持粘贴/焦点时 API 保持 no-op 幂等，避免崩溃

  begin
    // 记录错误并优雅降级
    LogError(E.Message);
    UseAlternativeMethod;
  end;
end;
```

### 3. 跨平台兼容

检查终端能力后再使用高级功能：

```pascal
if LTerminal.Info.SupportsTrueColor then
  LOutput.SetForegroundColorRGB(MakeRGBColor(255, 128, 64))
else
  LOutput.SetForegroundColor(tcRed);
```

## 能力矩阵与降级（Windows/Unix）

- Windows Console（老式控制台）：
  - 若支持 VT（ENABLE_VIRTUAL_TERMINAL_PROCESSING 成功）：可启用 24bit 颜色、备用屏（?1049）、焦点（?1004）、粘贴（?2004）、同步输出（?2026）等；
  - 若不支持 VT：输出降级为基本颜色/属性（未来可选 SetConsoleTextAttribute 回退），焦点/粘贴/同步输出仅作为 no-op；鼠标事件通过 ReadConsoleInputW 提供；
  - 鼠标启用期间会临时关闭 Quick Edit，避免选择冻结输入；退出恢复。
- Windows Terminal/现代终端：同 VT 路径，能力齐全。
- Unix（xterm/gnome-terminal/konsole 等）：
  - 原始模式使用 termios；尺寸通过 ioctl(TIOCGWINSZ)；SIGWINCH 推送 sizeChange 事件；
  - 鼠标（?1000/?1002/?1006）、焦点（?1004）、粘贴（OSC 200~…201~）、备用屏（?1049）均可用；
  - 读取策略可通过 VMIN/VTIME 调整（非阻塞/半阻塞）。

提示：term_support_* 与 term_support_compatible(tc_ansi) 可用于调用前能力判定；API 在不支持场景下保证幂等 no-op，不抛异常。

- 帧式循环与双缓冲 diff：见 docs/fafafa.core.term.ui_loop.md（含伪代码与测试建议）

## 测试

模块包含完整的单元测试，确保 100% 测试覆盖率。

- 诊断：term_last_error()
  - 初始化前后：term_init 成功会将 last_error 清空；若初始化失败或内部创建抛错，last_error 将包含诊断信息
  - 测试示例：tests/fafafa.core.term/Test_term_last_error.pas

### 运行测试

```bash
# Windows
cd tests/fafafa.core.term
BuildOrTest.bat test

# Unix/Linux
cd tests/fafafa.core.term
- 提示：本地运行可用 PowerShell 脚本 tests/fafafa.core.term/run-tests.ps1
  - 支持 --summary 默认开启；设置环境变量 FAFAFA_TEST_QUIET=1 可附加 --quiet

./BuildOrTest.sh test
```


## 本地测试运行指引

- 构建：tests/fafafa.core.term/BuildOrTest.bat
- 运行测试：tests/fafafa.core.term/BuildOrTest.bat test
- 直接运行测试可执行文件（已构建后）：
  - tests/fafafa.core.term/bin/fafafa.core.term.test.exe -a -p --format=plain

注意：若只看到 FPCUnit 帮助，请确认传入了 -a（全部用例）等参数或使用上面的 BuildOrTest.bat test 脚本。

### 测试覆盖

- ✅ 终端信息查询
- ✅ ANSI序列生成
- ✅ 颜色控制
- ✅ 光标控制
- ✅ 键盘输入处理
- ✅ 异常处理
- ✅ 跨平台兼容性

## 示例程序

### 底层 API 示例（term_*)

以下示例直接使用 term_* 底层 API，覆盖核心能力，位于 examples/fafafa.core.term：

- events_collect_minimal.lpr：帧预算收集与事件合并（term_events_collect，ESC 退出）
- title_icon_demo.lpr：设置窗口标题与图标标题（term_title_set/term_icon_set，自动能力检测）
- scroll_region_demo.lpr：设置滚动区域并在区域内滚动输出（term_scroll_region_set/reset）
- protocol_toggles_guard_demo.lpr：使用 TTermModeGuard 统一启停 Mouse/Focus/Paste 等协议
- focus_paste_sync_demo.lpr：手动启用 Focus / Bracketed Paste / Synchronized Updates
- paste_storage_demo.lpr：粘贴存储治理 API（defaults/max_bytes/keep_last/get_text）
- cursor_shape_blink_demo.lpr：光标形状与闪烁控制（tcs_* 与 blink）

运行要点：
- 文件均已加 {$CODEPAGE UTF8}
- 若终端不支持目标能力，API 将优雅降级为 no-op
- Windows 鼠标启用期间临时关闭 Quick Edit，退出恢复（已在测试覆盖）

### 现有门面示例

模块还提供了基于门面/演示工程：

- advanced_test.lpi/example_term.lpi/unicode_demo.lpr 等
- 事件回显/帧循环：04_event_poll_echo.lpr、07_frame_loop_demo.lpr

### 构建与运行

```bash
# 构建所有示例
cd examples/fafafa.core.term
build_all.bat  # Windows（包含 lazbuild 调用与 fpc 批量编译）

# 运行示例（路径示例）
examples/fafafa.core.term/bin/title_icon_demo.exe
examples/fafafa.core.term/bin/scroll_region_demo.exe
examples/fafafa.core.term/bin/protocol_toggles_guard_demo.exe
examples/fafafa.core.term/bin/focus_paste_sync_demo.exe
examples/fafafa.core.term/bin/paste_storage_demo.exe
examples/fafafa.core.term/bin/cursor_shape_blink_demo.exe
```

## 架构设计

### 设计原则

1. **接口优先** - 所有功能通过接口暴露，便于测试和扩展
2. **分层架构** - 清晰的抽象层次，从高级接口到平台实现
3. **命令模式** - 支持命令的组合和批量执行
4. **资源管理** - 自动的状态保存和恢复机制

### 模块依赖

```
fafafa.core.term
├── fafafa.core.base (异常基类)
├── Classes (基础类支持)
├── SysUtils (系统工具)
└── 平台特定单元
    ├── Windows (Windows API)
    └── Unix (Unix 系统调用)
```

### 类图

```
ITerminal
├── ITerminalInfo
├── ITerminalOutput
└── ITerminalInput

TTerminal (实现 ITerminal)
├── TTerminalInfo (实现 ITerminalInfo)
├── TTerminalOutput (实现 ITerminalOutput)
└── TTerminalInput (实现 ITerminalInput)

TANSIGenerator (静态类)
└── ANSI 序列生成方法
```


> 重要更新：OO 接口已确立为推荐首选门面；C 风格全局函数接口继续保留作为兼容层（稳定可用）。


## 版本历史

### v1.0.0 (当前版本)

- ✅ 完整的终端信息查询
- ✅ ANSI 转义序列支持
- ✅ 键盘输入处理
- ✅ 终端模式控制
- ✅ 跨平台兼容
- ✅ 完整的测试覆盖
- ✅ 详细的文档和示例

### 计划功能与状态说明

- 鼠标事件支持：已实现基础启停与合并（Windows/Unix 路径）；持续增强 xterm 协议细节与边界用例
- 窗口大小变化事件：已实现（含去抖策略）；持续补充多终端兼容细节
- Bracketed Paste：已实现存储治理（上限/保留/快速路径）；持续优化数据结构与性能
- 更多终端特性检测：进行中（tmux/screen/wezterm/Windows Terminal 能力识别、真彩降级策略等）

## 贡献指南

欢迎贡献代码！请遵循以下原则：

1. **TDD 开发** - 先写测试，再写实现
2. **代码风格** - 遵循项目的代码风格规范
3. **文档更新** - 更新相关文档和示例
4. **跨平台测试** - 确保在多个平台上测试

## 许可证

MIT License - 详见项目根目录的 LICENSE 文件。

## 联系方式

- 项目主页：fafafa.core 框架
- 问题报告：请使用项目的 Issue 跟踪器
- 开发团队：fafafa.core 开发团队


## Unix 运行指引（Focus/Bracketed Paste/SGR 鼠标）

- 前置要求
  - 使用支持 1006/1004/2004 的终端或复用器（如 xterm, alacritty, kitty, wezterm, gnome-terminal；tmux 需 set -g focus-events on，screen 需启用 focus 透传）
  - 确认 $TERM 合理（xterm-256color 或支持真彩/鼠标的变体）
- 构建与测试
  - cd tests/fafafa.core.term && ./BuildOrTest.sh test
  - Unix-only 用例通过 {$IFDEF UNIX} 条件编译生效（Focus/Paste/SGR 解析链）
- 交互验证（推荐示例）
  - 运行 examples/fafafa.core.term/04_event_poll_echo（或 06_input_monitor）
  - 开头启用：term_focus_enable(True); term_paste_bracket_enable(True); term_mouse_sgr_enable(True)
  - 观察：窗口切换触发 ESC[I/O → tek_focus；粘贴触发 ESC[200~..ESC[201~ → tek_paste；鼠标移动/滚轮解析为 SGR 事件
- 复用器注意事项
  - tmux：~/.tmux.conf 增加 set -g focus-events on；确保 setw -g mouse on 以转发鼠标（SGR 默认转发）
  - screen：需启用 focus 透传，老版本可能不支持 paste 2004（行为降级为 no-op）
- 故障排查
  - 若无焦点事件：检查 focus-events；若无粘贴事件：检查是否被复用器吞掉；若坐标异常：确认终端未启用 application mouse 以外模式



## 近期变更（2025-08-25）

- 鼠标协议策略：对齐 crossterm/tcell，Unix 启停顺序以 SGR(1006) 为首选，兼容 1002/1000/1015（仅顺序与注释调整，不改变行为）
- 默认输出：ITerminal 默认绑定标准输出句柄（FPC 下 TTextRec(Output).Handle），构造失败回退内存流；测试仍可注入内存流
- Windows VT 输入（试验开关，默认关闭）：
  - 通过环境变量 FAFAFA_TERM_WIN_VT_INPUT=on|1 时，且 supports_vt=True，启用 ENABLE_VIRTUAL_TERMINAL_INPUT
  - 默认关闭，保持 ReadConsoleInputW 事件路径稳定；请仅在 Windows Terminal/现代终端环境下按需开启

- 能力位细化：新增 tcapFocus/tcapBracketedPaste 以及鼠标协议细粒度位 tcapMouseBasic/Drag/SGR/Urxvt；GetCapabilities 将按探测/环境生成细粒度集合
- 颜色/环境：支持 CLICOLOR/CLICOLOR_FORCE；NO_COLOR 优先禁彩；COLORTERM/TERM 继续决定位深（24/256/16）
- 事件参数化（Unix）：FAFAFA_TERM_RESIZE_DEBOUNCE_MS（默认50ms）、FAFAFA_TERM_READ_TIMEOUT_MS（termios VTIME 映射）；合并开关沿用 FAFAFA_TERM_COALESCE_MOVE/WHEEL（默认 on）
- 输出状态机：Show/HideCursor 重复调用抑制，减少冗余 ANSI 输出
- 能力宣称收敛：Focus(1004)/BracketedPaste(2004) 仅在明确支持时置位（不再因 ANSI/VT 乐观宣称）；避免上层误判

- 输出状态机（进一步优化）：抑制重复 Save/RestoreCursor 与重复 SetScrollRegion；ResetScrollRegion 后清空缓存；默认行为与 API 不变

- 可选写入合并阈值（behind-a-flag）：FAFAFA_TERM_WRITE_COALESCE_BYTES>0 时，在非缓冲模式下聚合小写入到阈值再写，默认关闭

