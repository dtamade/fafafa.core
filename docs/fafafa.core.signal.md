# fafafa.core.signal 模块文档

更新时间：2025-08-20

> 建议先阅读《docs/partials/signal.best_practices.md》以了解推荐模式与注意事项。


- 设计目标：跨平台、最小可用、可替换的进程级信号分发中心
- 借鉴：Go os/signal（订阅/停止）、Rust signal-hook / tokio::signal（自管道 + 回调去抖）

## API 概览（扩展后）

- type TSignal = (sgInt, sgTerm, sgHup, sgUsr1, sgUsr2, sgWinch, sgCtrlBreak, sgCtrlClose, sgCtrlLogoff, sgCtrlShutdown)
- interface ISignalCenter
  - Start/Stop/IsRunning/TryStart(out ErrMsg)/TryStop(out ErrMsg)
  - Subscribe(Signals, Callback): Int64  // 返回 token
  - SubscribeOwned(Owner, Signals, Callback): Int64 // 订阅并绑定 Owner
  - Unsubscribe(Token)
  - UnsubscribeAll(Owner) // 通过 Owner 取消其全部订阅
  - Pause(Token) / Resume(Token)
  - ConfigureQueue(MaxCapacity, Policy) // 队列容量与丢弃策略（默认无限、丢最新）
  - WaitNext(out Sig, TimeoutMs): boolean
  - TryWaitNext(out Sig): boolean // 非阻塞取一条
  - SubscribeOnce(Signals, Callback): Int64 // 触发一次后自动取消
  - InjectForTest(Sig) // 测试注入
  - GetQueueStats(): TQueueStats // 观测：容量/长度/丢弃策略/丢弃计数
- function SignalCenter: ISignalCenter // 单例门面

### 队列统计（TQueueStats）
- Capacity: 整数。若配置了 MaxCapacity，返回该值；否则返回当前底层缓冲大小。
- Length: 当前队列长度。
- Policy: 丢弃策略（qdpDropOldest/qdpDropNewest）。
- DropCount: 启动以来被丢弃的事件总数。

## 工作模式与事件消费语义

- 模式选择（不要混用回调与队列）
  - 回调模式：通过 Subscribe/SubscribeOnce 订阅，在“派发线程”内串行执行所有回调；适合轻量处理与转发。回调异常被捕获并吞没，不会终止派发线程；请保持回调短小、无阻塞。
  - 队列模式：通过 WaitNext 或 Channel 接口“消费”事件；此模式下不应再使用回调，否则会与回调竞争同一事件，导致“谁先取到谁消费”。
- 重要语义（非广播、消费型）
  - WaitNext/Channel 都是“消费型”获取机制，与回调并列时不会广播同一事件给双方；请根据业务选择一种模式。
  - 不支持多线程并发调用 WaitNext（单消费者语义）。如需扇出/多消费者，请基于 Channel/Fan-out 自行实现。
- 平台差异与 WaitNext 的占用
  - Unix：派发线程通过 self-pipe 读取原生信号，并直接调用回调；同时“机会性”从内部队列取出 InjectForTest 等事件并派发。外部使用 WaitNext 仅建议在“纯队列模式”下使用。
  - Windows：派发线程内部使用 WaitNext 轮询内部队列并派发回调；因此外部线程若也调用 WaitNext，将与派发线程竞争事件源。建议：需要队列消费就不要注册回调，反之亦然。
- sgWinch 合并与去抖
  - 已实现：合并连续 sgWinch（若队尾已是 sgWinch，则跳过追加）。
  - 新增：ConfigureWinchDebounce(windowMs) 时间窗口去抖，若距离上次 sgWinch 入队时间小于 windowMs，则忽略当前入队。
- 队列容量与丢弃
  - 默认 MaxCapacity<=0 为无限容量；默认策略为 qdpDropNewest（丢最新，忽略当前入队）。可通过 ConfigureQueue(capacity, policy) 调整。
- 生命周期与线程
  - Start/Stop 幂等；Stop 会唤醒等待者并有序终止派发线程。
  - 回调在“派发线程”执行；建议仅做轻量标志/转发，将重逻辑交由业务线程或 Channel。

### 推荐使用实践
- 仅回调：需要快速响应、无需逐条配对处理；回调内只做轻量转发。
- 仅队列（WaitNext）：需要逐条处理且可阻塞等待；不要同时订阅回调。
- Channel：需要背压/配对语义或与其他 Channel 组合；容量=0 表示配对，非零表示有界缓冲。当前实现对发送使用 SendTimeout(…, 0) 非阻塞，缓冲满时会丢弃，必要时请增大容量或在回调中转发。
## 行为与平台说明

- Unix（Linux、macOS、BSD）：安装 SIGINT/SIGTERM/SIGHUP/SIGUSR1/SIGUSR2/SIGWINCH（若可用），采用 self-pipe 将信号写入管道，由派发线程在正常线程上下文中回调订阅者。
  - 实现细节：管道 FD 设为 O_NONBLOCK 与 FD_CLOEXEC，避免派发阻塞与子进程句柄泄漏；派发线程使用 select + 非阻塞读，降低无效系统调用；handler 仅写 1 字节。
  - macOS/BSD 兼容：SigAction/sa_flags=SA_RESTART；SIGWINCH 在伪终端有效；无效时不会触发回调。
- Windows：通过 SetConsoleCtrlHandler 捕捉 CTRL_C/CTRL_BREAK/CLOSE/LOGOFF/SHUTDOWN，映射到 TSignal 并派发。
  - 服务/非交互会话下，有些 Ctrl 事件可能不可达；模块保持静默降级。
  - 当且仅当存在该事件的订阅者时，SignalCenter 会向系统声明“已处理”（ConsoleCtrlHandler 返回 True），否则冒泡交由系统默认处理（返回 False）。该判定逻辑可在源码 ConsoleCtrlHandler 中看到。
- 回调在派发线程内执行，应短小、非阻塞；如需重逻辑，请排队到业务线程。
- 重要约束（强烈建议）：所有回调都在 SignalCenter 的派发线程内执行。
  - 请避免在回调中进行阻塞操作（Sleep/IO/锁争用等）或长耗时计算。
  - 推荐在回调中仅做“标志置位/轻量排队”，并将重逻辑转交业务线程或 Channel。
- 队列默认行为：ConfigureQueue 未调用或 MaxCapacity <= 0 时，表示无限容量；默认丢弃策略为“丢最新”（qdpDropNewest）。

- 生命周期：Start/Stop 为进程级中心的初始化与注销；Start/Stop 全流程互斥处理，Stop 在 Unix 下恢复旧的 sigaction。
- Windows Ctrl 事件：当且仅当存在该事件的订阅者时，SignalCenter 吞掉系统事件（返回 True）；否则冒泡（返回 False）按系统默认处理。

## 宏开关一览（settings.inc）

- FAFAFA_SIGNAL_ENABLE_SIGINT：安装/派发 SIGINT（或 CTRL_C 映射）
- FAFAFA_SIGNAL_ENABLE_SIGTERM：安装/派发 SIGTERM
- FAFAFA_SIGNAL_ENABLE_SIGHUP：安装/派发 SIGHUP（Unix）
- FAFAFA_SIGNAL_ENABLE_SIGUSR1：安装/派发 SIGUSR1（Unix）
- FAFAFA_SIGNAL_ENABLE_SIGUSR2：安装/派发 SIGUSR2（Unix）
- FAFAFA_SIGNAL_ENABLE_SIGWINCH：安装/派发 SIGWINCH（终端尺寸变更，Unix）
- FAFAFA_SIGNAL_ENABLE_WIN_CTRL：启用 Windows 控制台 Ctrl 事件处理（CTRL_C/BREAK/CLOSE/LOGOFF/SHUTDOWN）

默认均启用，可按需注释以裁剪。

## 使用示例

### 1) 直接订阅/回调
```
uses fafafa.core.signal;

var C: ISignalCenter; tok: Int64;

procedure OnInt(const S: TSignal);
begin
  // 设置标志、发事件等
end;

begin
  C := SignalCenter; C.Start;
  tok := C.Subscribe([sgInt, sgTerm], @OnInt);
  // ...
  C.Unsubscribe(tok);
  C.Stop;
end.
```

### 1.1) Owner 风格订阅（批量注销）
```
uses fafafa.core.signal;

type
  TWorker = class
  public
    Count: Integer;
    procedure OnSig(const S: TSignal);
  end;

procedure TWorker.OnSig(const S: TSignal);
begin
  Inc(Count);
end;

var C: ISignalCenter; W: TWorker; tok: Int64;
begin
  C := SignalCenter; C.Start;
  W := TWorker.Create;
  try
    tok := C.SubscribeOwned(W, [sgInt, sgTerm], @W.OnSig);
    // ... 运行时如需一次性注销该对象所有订阅：
    C.UnsubscribeAll(W);
  finally
    W.Free;
    C.Stop;
  end;
end.
```

### 3) SubscribeOnce / Pause / Queue 示例
```
uses fafafa.core.signal;

var tok: Int64; C: ISignalCenter; S: TSignal;
begin
  C := SignalCenter; C.Start;
  // 触发一次后自动取消
  tok := C.SubscribeOnce([sgInt],
    procedure (const Sig: TSignal) begin writeln('INT once'); end);

  // 暂停/恢复订阅
  C.Pause(tok);
  C.Resume(tok);

## 正确用法矩阵与反例

- 模式选择
  - 回调模式：仅 Subscribe/SubscribeOnce；不调用 WaitNext；无需 Channel。
  - 队列模式：仅 WaitNext；不注册回调；Channel 可选。
  - Channel 模式：使用 TSignalChannel；不注册回调；一般也不混用 WaitNext（除非做二次转发）。
- 反例
  - 已注册回调的同时，在其他线程里调用 WaitNext 读取事件：两者会竞争同一事件，使部分事件仅被其中一个处理方获取，造成不可预期的“漏回调”或“漏消费”。
  - 在回调中执行阻塞或长耗时逻辑：会阻塞整个派发线程，导致后续信号延迟甚至堆积。
- 推荐
  - 回调内只做轻量标志与转发，将重逻辑推到业务队列/线程。
  - 若需要背压/配对，优先使用 Channel 模式，并合理设置容量。

  // 队列容量与策略
  C.ConfigureQueue(256, qdpDropOldest);

  // 非阻塞取一条
  if C.TryWaitNext(S) then ;
end.
```

### 2) Channel 风格（推荐在需要背压/配对时）
```
uses fafafa.core.signal, fafafa.core.signal.channel;

var Ch: TSignalChannel; Sig: TSignal;
begin
  Ch := TSignalChannel.Create([sgInt, sgTerm], 8 {容量});
  try
    if Ch.RecvTimeout(Sig, 1000) then
      ; // 处理 Sig
  finally
    Ch.Free;
  end;
end.
```

## 与 term 模块的 SIGWINCH 接入方案（已默认启用，跨平台注意事项）

- 目标：用统一的 signal center 分发终端尺寸变化事件，替换 term_unix 内部的直接 fpSigAction 安装。
- 适配层设计：
  - 在 term 初始化（EnterRaw/Init）阶段：
    - SignalCenter.Start
    - Subscribe([sgWinch], 回调 -> 标记 G_SIGWINCH_OCCURRED := True 或直接触发 term 的 sizeChange 合并逻辑)
  - 在 term 清理（LeaveRaw/Finalize）阶段：
    - Unsubscribe(token)
  - 风险与注意：
    - term 当前已自带 SIGWINCH 标志与处理；迁移需分支宏控制，避免双重安装。
    - 高频 WINCH 建议合并：例如 N ms 内只派发一次，或在帧循环中合并。
## 常见问题（FAQ）

- Q: 我既想用回调，又想在另外一个线程用 WaitNext 拉取相同事件做日志，如何实现？
  - A: 当前版本的 WaitNext 是消费型，与回调竞争同一事件，不建议混用。请使用“回调 -> Channel/业务队列”方式转发到日志线程；或未来提供的“Tap/镜像订阅”能力。
- Q: Windows 下 Ctrl+C 会不会被吞掉，导致程序不退出？
  - A: 若存在对 sgInt（CTRL_C 映射）的订阅者，SignalCenter 会返回 True 告诉系统“已处理”，默认行为被抑制；请在回调中自行执行优雅退出；若希望保留系统默认退出，请不订阅或提供可配置策略（未来可加入策略枚举）。
- Q: 多线程并发 WaitNext 会怎样？
  - A: 不支持。WaitNext 语义为单消费者；并发调用会导致竞争与不可预期结果。


示例适配片段（伪代码）：
```
var GWinchTok: Int64 = 0;
procedure TermAttachSignals;
var C: ISignalCenter;
begin
  C := SignalCenter; C.Start;
  GWinchTok := C.Subscribe([sgWinch],
    procedure (const S: TSignal)
    begin
      // 标记挂起，由主循环在 pull 时生成 tek_sizeChange 事件
      G_SIGWINCH_OCCURRED := True;
    end);
end;

procedure TermDetachSignals;
begin
  if GWinchTok <> 0 then SignalCenter.Unsubscribe(GWinchTok);
  GWinchTok := 0;
end;
```

### 跨平台兼容性清单

- Linux
  - 支持 SIGWINCH（tty/pty 有效），SigAction + self-pipe；容器/守护进程中无 TTY 时，WINCH 不会触发。
- macOS
  - 支持 SIGWINCH 于终端/伪终端；SigAction 语义与 BSD 一致；tmux/screen 等复合层可能合并/延迟 WINCH。
- FreeBSD/其他 BSD
  - SigAction/self-pipe 均可；若缺失 SIG* 常量，本模块使用 {$IFDEF} 宏静态规避。
- Windows
  - SetConsoleCtrlHandler 仅在控制台会话有效；服务/GUI 进程可能不触达；模块静默降级。

注意：
- handler 仅写管道字节，避免不可重入 API；回调在派发线程执行。
- 非交互/无 TTY 环境下，sgWinch 可能永不触发，此为正常现象。


## 限制与后续计划

- 当前不暴露屏蔽/恢复（sigprocmask）与多实例；仅提供进程级中心。
- 未提供去抖/合并策略；对 sgWinch 等高频信号，调用方可自行去抖。
- 待办：
  - 支持 Once/Channel 风格接口（Waiter/Chan）
  - Windows 下服务会话与 GUI 进程的能力探测与文档化
  - SignalSet 序列化与日志辅助

