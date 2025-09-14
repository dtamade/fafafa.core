# fafafa.core.time

## 概述
- 提供现代化、跨平台的时间语义层：TDuration、TInstant（单调）、TDeadline，以及 IMonotonicClock/ISystemClock/IClock。
- 目标：统一使用 Duration/Instant 表达时间差和时点，避免直接使用 GetTickCount64/自制换算。

## 设计原则
- 单调时钟与墙钟分离：测量/超时用 Instant；日志/持久化用 NowUTC。
- 高层 API 稳定：SleepFor/SleepUntil/NowInstant/NowUTC/NowLocal。
- 跨平台：Windows 使用 QPC，Linux 使用 CLOCK_MONOTONIC，macOS 使用 mach_absolute_time（已支持）。

## 核心类型
- Duration：FromNs/Us/Ms/Sec，AsNs/Us/Ms/Sec，Add/Sub/Clamp。
- Instant：Add(Duration)、Diff(Instant):Duration、HasPassed(Now)。
- Deadline：FromNow/FromInstant、Remaining/Expired。

## 接口
- IMonotonicClock：NowInstant、SleepFor、SleepUntil。
- ISystemClock：NowUTC（真实 UTC）/NowLocal（本地）。
- IClock：综合视图，聚合前两者。

## 便捷函数
- DefaultMonotonicClock/DefaultSystemClock/DefaultClock
- SleepFor/SleepUntil/NowInstant/NowUTC/NowLocal
- TimeIt(proc)、FormatDurationHuman(D)

## 与 fafafa.core.tick 的关系
- 本模块独立实现高精度单调时钟，不再依赖 fafafa.core.tick。
- 计划：稳定后逐步迁移调用点，最终废弃 fafafa.core.tick。

### 迁移与适配（与 time.tick 的关系补充）
- 迁移策略：新代码优先使用 core.time（Duration/Instant/Deadline），渐进迁移旧有直接使用 GetTickCount64 的路径。
- 与 time.tick 共存：迁移期允许 coexist；记录式 TTick 的 ttTSC 目前在稳定版中回退为可用实现，以避免跨模块类型冲突。
- 测试注意：匿名函数需启用 `{$modeswitch anonymousfunctions}`，传入匿名过程时直接 `procedure ... end`，无需 `@`。
- Windows 说明：HighPrecision 通常基于 QPC；System 为 GetTickCount64（ms 粒度）。测试断言遵循“下限 + 宽容差”原则，避免不同平台调度器下的误报。


### Stopwatch 与 ITick（推荐用法）

- 基本测量
```
uses fafafa.core.time.stopwatch;
var sw: TStopwatch; d: TDuration;
begin
  sw := TStopwatch.StartNew;
  // ... workload ...
  sw.Stop;
  d := sw.ElapsedDuration;
  Writeln('耗时(ms)=', d.AsMs:0:3);
end.
```

- 注入指定时钟（WithClock）
```
uses fafafa.core.time.tick, fafafa.core.time.stopwatch;
var clk: ITick; sw: TStopwatch;
begin
  clk := MakeHDTick; // 或 MakeBestTick/MakeStdTick/MakeHWTick（若可用）
  sw := TStopwatch.StartNewWithClock(clk);
  // ... workload ...
  sw.Stop;
  Writeln('ns=', sw.ElapsedDuration.AsNs);
end.
```

- 直接测量过程
```
var d: TDuration;
begin
  d := TStopwatch.Measure(procedure begin
    // ... workload ...
  end);
end.
```

## ITick（core.time.tick）

- 统一计时入口：`ITick` 接口；工厂：`MakeStdTick`、`MakeHDTick`、`MakeHWTick`、`MakeBestTick`
- 接口摘要：`Resolution`、`IsMonotonic`、`TickType`、`Tick()`

快速开始：
```
uses fafafa.core.time.tick;
var c: ITick; t0, t1, dt: QWord;
begin
  c := MakeBestTick;
  t0 := c.Tick;
  // ... workload ...
  t1 := c.Tick;
  dt := t1 - t0; // 时间差（单位见 c.Resolution）
end.
```

平台说明：
- Windows：HighPrecision 使用 QPC；不可用时回退到 GetTickCount64
- Unix：HighPrecision 使用 CLOCK_MONOTONIC；失败时回退到 gettimeofday（换算 ns）
- x86/x86_64 硬件计时器：TSC（RDTSCP/LFENCE;RDTSC/CPUID;RDTSC），10ms 对称校准；仅在 invariant TSC 时宣称单调
- AArch64/ARMv7‑A 硬件计时器：架构通用计时器 CNTVCT/CNTPCT + CNTFRQ，按平台权限决定可用性
- RISC‑V 硬件计时器：time/timeh 或 cycle/cycleh（优先 time；cycle 可能受 DVFS 影响）

硬件计时器编译开关：
- AArch64/ARMv7‑A：`FAFAFA_USE_ARCH_TIMER`
- RISC‑V：`FAFAFA_CORE_USE_RISCV_TIME_CSR`、`FAFAFA_CORE_USE_RISCV_CYCLE_CSR`

最佳实践：
- 性能测量/超时：优先 HighPrecision/Best；输出用 TDuration.As*
- 测试断言用“下限 + 容差”（如 Sleep(1) 期望 >=0.5ms）
- 将固定时长转 tick：DurationToTicks(TDuration.FromMs(1))

迁移指引（从 ITick 到 TTick）：
- CreateDefaultTick → BestTick
- CreateTickProvider/GetAvailableProviders → TTick.From/GetAvailableTickTypes
- GetCurrentTick/GetElapsedTicks/GetResolution → Now/Elapsed/FrequencyHz
- TicksTo*Seconds/MeasureElapsed → TicksToDuration(...).AsNs/AsUs/AsMs



## 示例
```pascal
var c: IMonotonicClock; t0, t1: TInstant; d: TDuration;
begin
  c := DefaultMonotonicClock;
  t0 := c.NowInstant;
  c.SleepFor(TDuration.FromMs(10));
  t1 := c.NowInstant;
  Writeln('elapsed(ms)=', t1.Diff(t0).AsMs);
  Writeln('utc=', DateTimeToStr(NowUTC), ' local=', DateTimeToStr(NowLocal));
end;
```

## 最佳实践（UTC vs Local）
- 采集/日志/持久化：使用 NowUTC，避免本地时区/夏令时跳变带来的排序与对账问题。
- UI/提示/人机交互：使用 NowLocal，符合用户习惯。
- 不要混用：用 TInstant/TDuration 处理相对时间与超时；仅在需要绝对日历时间时才使用系统时钟。


## 测试
- tests/fafafa.core.time 下提供最小单测覆盖：
  - Duration 算术

## Sleep 策略与阈值（跨平台指南）
- 策略枚举：TSleepStrategy = (EnergySaving, Balanced, LowLatency)
- 默认：EnergySaving（推荐通用场景；功耗更低）
- 阈值：最终自旋阈值（纳秒），用于 Balanced/LowLatency 的“收尾”阶段，减少调度抖动；可通过 SetFinalSpinThresholdNs 或 SetFinalSpinThresholdNsFor(平台) 调整。

### 示例：切换策略与阈值
```pascal
// 1) 默认节能
SetSleepStrategy(EnergySaving);

// 2) 对短时延敏感，降低抖动
SetSleepStrategy(Balanced);
SetFinalSpinThresholdNs(2 * NANOSECONDS_PER_MILLI); // 约 2ms

// 3) 极端低延迟（更高功耗）
SetSleepStrategy(LowLatency);
SetFinalSpinThresholdNs(1 * NANOSECONDS_PER_MILLI);

// 4) 针对不同平台单独设置阈值（纳秒）
SetFinalSpinThresholdNsFor(PlatWindows, 1 * NANOSECONDS_PER_MILLI);
SetFinalSpinThresholdNsFor(PlatLinux,   2 * NANOSECONDS_PER_MILLI);
SetFinalSpinThresholdNsFor(PlatDarwin,  3 * NANOSECONDS_PER_MILLI);
```
- 权衡：阈值越小忙等越少（抖动略增、功耗低），阈值越大忙等越多（抖动更低、功耗高）。建议基于实际 workload 做对比测试。

## 实用片段（Sleep 最佳实践）
- 软截止时间（Slack 策略，减少抢占/调度抖动影响）：
```pascal
var deadline: TInstant;
begin
  deadline := NowInstant.Add(TDuration.FromMs(100));
  SleepUntilWithSlack(deadline, TDuration.FromMs(2));
end;
```
- 可取消睡眠（协作式取消 Token）：
```pascal
var cts: ICancellationTokenSource; ok: Boolean;
begin
  cts := CreateCancellationTokenSource;
  ok := SleepForCancelable(TDuration.FromSec(1), cts.Token);
  // ok=false 表示取消赢了
end;
```
- Linux 绝对睡眠与 EINTR 处理（减少漂移）：
```pascal
var dl: TInstant;
begin
  dl := NowInstant.Add(TDuration.FromMs(20));
  SleepUntil(dl); // 在 Linux 下使用 clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME)
end;
```
- Windows 低延迟（可选，默认关闭，功耗更高）：
```pascal
begin
  SetLowLatencySleepEnabled(True);
  try
    SleepFor(TDuration.FromMs(2)); // 混合策略：Sleep(1)+QPC 忙等收尾
  finally
    SetLowLatencySleepEnabled(False);
  end;
end;
```
- Windows 睡眠策略（TSleepStrategy）与阈值
```pascal
// 策略：EnergySaving(默认) / Balanced / LowLatency
SetSleepStrategy(EnergySaving);
// 最终自旋阈值（纳秒），默认 ~2ms（仅 Windows 有效）
SetFinalSpinThresholdNs(2 * NANOSECONDS_PER_MILLI);
```
注意：Balanced/LowLatency 会在最后阈值内采用忙等收尾，降低抖动但增加 CPU 占用与能耗；建议仅在对延迟敏感的短睡眠场景开启。

  - Instant Add/Diff
## 跨平台睡眠策略对照表
- 策略与默认
  - 默认策略：EnergySaving（三平台）
  - 默认阈值：约 2ms（SetFinalSpinThresholdNs 可调，仅影响 Balanced/LowLatency）
- 行为概览
  - Windows
    - EnergySaving：Sleep(rounded ms)
    - Balanced/LowLatency：Sleep(1) + 最后阈值内自旋
  - Linux
    - EnergySaving：SleepFor 相对睡眠（EINTR 重试）；SleepUntil 绝对睡眠（clock_nanosleep TIMER_ABSTIME）
    - Balanced/LowLatency：SleepFor 采用“1ms 片段 + 阈值内短自旋”；SleepUntil 仍绝对睡眠
  - macOS
    - EnergySaving：SleepFor 相对睡眠（EINTR 重试）；SleepUntil 绝对睡眠（mach_wait_until）
    - Balanced/LowLatency：SleepFor 采用“1ms 片段 + 阈值内短自旋”；SleepUntil 仍绝对睡眠


## UltraLowLatency 策略（新增）
- 定位：进一步降低短睡眠的调度抖动，代价是更高的 CPU 活跃与能耗
- 平台行为
  - Windows：阈值外采用更短让权 Sleep(0)，阈值内忙等（QPC 收尾）
  - Linux/macOS：阈值外采用更短让权 nanosleep(≈200µs)，阈值内忙等或绝对等待（macOS 使用 mach_wait_until）
- 适用：对 1–3ms 以内的低抖动场景（音频回放/游戏/高频刷新）；不建议电池设备或大量并发等待
- 搭配：结合 SetFinalSpinThresholdNs(平台) 调小阈值可进一步降低忙等时间

### 示例
```pascal
SetSleepStrategy(UltraLowLatency);
SetFinalSpinThresholdNs(1 * NANOSECONDS_PER_MILLI);
// 对 2ms 以内更敏感的等待
SleepFor(TDuration.FromMs(2));
```
- Balanced 最终自旋的让权（可配置）：
  - Windows：每 N 次自旋调用 Sleep(0)，默认 N=2048
  - Linux：每 N 次自旋调用 sched_yield，默认 N=2048
  - macOS：当前阈值内主要使用 mach_wait_until，基本不进入忙等；保留 N 以便未来需要

## 定时器（TimerScheduler）
- 接口与能力
  - ITimerScheduler：ScheduleOnce / ScheduleAt / ScheduleAtFixedRate / ScheduleWithFixedDelay / Shutdown
  - ITimer：Cancel / IsCancelled
  - 异常处理：SetTimerExceptionHandler(proc)
  - 指标：TimerGetMetrics / TimerResetMetrics；字段包括 ScheduledTotal/FiredTotal/CancelledTotal/ExceptionTotal
  - 追赶上限：SetTimerFixedRateMaxCatchupSteps(N)，0 表示不限制
- 行为说明
  - FixedRate：按固定步长与起始时间对齐，可能发生追赶；通过上限控制最差情况下的连续触发次数
  - FixedDelay：每次回调结束后延迟 Delay 再安排下一次（不追赶）
  - 一次性：ScheduleOnce(Delay) 或 ScheduleAt(Deadline)
  - 线程模型：独立调度线程驱动；回调在该线程内执行，需短小非阻塞
- 用法示例
```pascal
uses fafafa.core.time, fafafa.core.time.timer;
var S: ITimerScheduler; T: ITimer; fired: Integer = 0;
procedure OnTick; begin Inc(fired); end;
begin
  S := CreateTimerScheduler;
  T := S.ScheduleAtFixedRate(TDuration.FromMs(100), TDuration.FromMs(300), @OnTick);
  SleepFor(TDuration.FromMs(1100));
  T.Cancel; S.Shutdown;
end;
```

## 格式化配置（FormatDurationHuman）
- 默认输出：使用缩写单位（ns/us/ms/s），秒为整数位
- 可配置项（全局）：
  - SetDurationFormatUseAbbr(True|False)：切换缩写或全称（nanoseconds/microseconds/milliseconds/seconds）
  - SetDurationFormatSecPrecision(N)：秒的小数位（默认 0，最大 9）
- 示例：
```pascal
SetDurationFormatUseAbbr(False);
Writeln(FormatDurationHuman(TDuration.FromMs(3)));   // "3 milliseconds"
SetDurationFormatUseAbbr(True);
SetDurationFormatSecPrecision(3);
Writeln(FormatDurationHuman(TDuration.FromNs(1500000000))); // "1.500s"
```

  - 配置接口：SetSpinYieldEvery(N)、SetSpinYieldEveryFor(Plat, N)、GetSpinYieldEveryFor(Plat)


- 自旋提示：在最终自旋阶段使用 CpuRelax（x86_64 上为 PAUSE 指令；其他平台为 no-op），降低忙等时的功耗与总线压力；必要时配合 Sleep(0)/SwitchToThread 做短让权。


- 示例
```pascal
// 默认节能
### 策略 × 平台 × 行为（速览表）


## 定时器/调度器（Timer/Scheduler）行为与策略（补充）

- 固定频率（FixedRate）：按期望节奏对齐周期；落后时允许“追赶”（可配置最大追赶步数）
- 固定延迟（FixedDelay）：每次回调结束后再延迟一段时间开始下一次
- 建议：
  - 周期性采样、渲染动画：FixedRate（对齐节奏）
  - 任务队列、轮询：FixedDelay（避免积压）
- 线程安全：回调在调度器线程上执行，请注意共享数据同步
- 取消：ITimer/ITicker.Stop；Scheduler.Shutdown 有序停止
- 典型用例
```
var sch: ITimerScheduler; t: ITimer;
begin
  sch := CreateTimerScheduler;
  t := sch.ScheduleAtFixedRate(TDuration.FromMs(10), TDuration.FromMs(16), procedure begin
    // 渲染帧/刷新
  end);
  // ...
  t.Cancel;
end.
```
- 基准建议：
  - 报告：平均回调间隔、抖动（p50/p90/p99）、丢帧（FixedRate 追赶步数统计）
  - 场景：1ms/5ms/16ms 周期，空回调与轻载回调对比
  - 平台：Windows（QPC）/Linux（CLOCK_MONOTONIC）

推荐默认参数（可按 workload 调整）：
- Windows
  - 默认策略：EnergySaving
  - 最终自旋阈值：~2ms（SetFinalSpinThresholdNsFor(PlatWindows, 2ms)）
  - Balanced 让权节奏：Sleep(0) 每 2048 次（SetSpinYieldEveryFor(PlatWindows, 2048)）
- Linux
  - 默认策略：EnergySaving
  - 最终自旋阈值：~2ms
  - Balanced 让权节奏：sched_yield 每 2048 次
  - Balanced/LowLatency 片段睡眠：1ms（SetSliceSleepMsFor(PlatLinux, 1)）
- macOS
  - 默认策略：EnergySaving
  - 最终自旋阈值：~2–3ms（根据实测）
  - SleepUntil 使用 mach_wait_until（建议保持绝对等待以减少漂移）


| 策略 \ 平台 | Windows | Linux | macOS |
|---|---|---|---|
| EnergySaving | Sleep(rounded ms) | SleepFor: 相对睡眠+EINTR；SleepUntil: 绝对睡眠 | SleepFor: 相对睡眠+EINTR；SleepUntil: 绝对睡眠 |
| Balanced | Sleep(1)+阈值内自旋 | SleepFor: 1ms片段+阈值内短自旋；SleepUntil: 绝对睡眠 | SleepFor: 1ms片段+阈值内短自旋；SleepUntil: 绝对睡眠 |
| LowLatency | Sleep(1)+阈值内自旋 | SleepFor: 1ms片段+阈值内短自旋；SleepUntil: 绝对睡眠 | SleepFor: 1ms片段+阈值内短自旋；SleepUntil: 绝对睡眠 |

SetSleepStrategy(EnergySaving);

// 对短时延敏感，降低抖动
SetSleepStrategy(Balanced);
SetFinalSpinThresholdNs(2 * NANOSECONDS_PER_MILLI);

// 极端低延迟
SetSleepStrategy(LowLatency);
SetFinalSpinThresholdNs(1 * NANOSECONDS_PER_MILLI);
```

- 权衡
  - Balanced/LowLatency 通过自旋降低抖动，但会增加 CPU 占用和功耗
  - 在电池设备或大量并发等待场景建议使用 EnergySaving

  - SleepFor 基本正确性（容忍调度误差）
  - FixedMonotonicClock 确定性行为
- per-OS 阈值（仅影响 Balanced/LowLatency）
```pascal
// 全局设置三平台阈值（纳秒）
## 短睡眠（1–10ms）基准测试草案
- 目的：比较不同策略/阈值下短睡眠的误差与抖动
- 指标：
  - 平均绝对误差（MAE）
  - p50/p95/p99 误差（纳秒/毫秒）
  - 超过阈值的比率（例如 > 2ms 的次数占比）
- 环境控制：
  - 固定 CPU 频率、关闭节能/高性能切换；尽量独占核心或绑定亲和性
  - 关闭不必要的后台任务；使用 Release 构建
  - Windows：默认 EnergySaving，对比 Balanced/LowLatency；Linux/macOS 同样
- 方法：
  - 目标步长 {1,2,5,10}ms；每个步长重复 N=500~2000 次
  - 两种模式：
    1) 相对睡眠：重复 SleepFor(step)
    2) 绝对睡眠：用 t0+step*i 作为目标，SleepUntil(target)
  - 记录每次实际耗时与理想耗时之差，汇总指标

- 最小代码片段（示意）：
```pascal
procedure RunShortSleepBench(const stepMs: Integer; const N: Integer);
var i: Integer; t0, t1, target: TInstant; actual, ideal, err: Int64;
begin
  // 相对睡眠
  t0 := NowInstant;
  for i := 1 to N do SleepFor(TDuration.FromMs(stepMs));
  t1 := NowInstant;
  actual := t1.Diff(t0).AsNs;
  ideal := N * stepMs * NANOSECONDS_PER_MILLI;
  Writeln('REL step=', stepMs, 'ms err_ns=', actual - ideal);

  // 绝对睡眠
  t0 := NowInstant;
  for i := 1 to N do begin
    target := t0.Add(TDuration.FromMs(i * stepMs));
    SleepUntil(target);
  end;
  t1 := NowInstant;
  actual := t1.Diff(t0).AsNs;
  ideal := N * stepMs * NANOSECONDS_PER_MILLI;
  Writeln('ABS step=', stepMs, 'ms err_ns=', actual - ideal);
end;
```
- 建议：将结果导出到 CSV，再以脚本计算 MAE、p95/p99，并绘图对比

SetFinalSpinThresholdNs(2 * NANOSECONDS_PER_MILLI);

// 单独设置某平台阈值（纳秒）
SetFinalSpinThresholdNsFor(PlatWindows, 1 * NANOSECONDS_PER_MILLI);
SetFinalSpinThresholdNsFor(PlatLinux,   2 * NANOSECONDS_PER_MILLI);
SetFinalSpinThresholdNsFor(PlatDarwin,  3 * NANOSECONDS_PER_MILLI);
```
权衡：阈值越小，忙等时间越短，抖动可能稍增加但功耗更低；阈值越大，忙等时间变长，抖动更低但 CPU/能耗更高。建议在测试环境基于实际 workload 做对比与调优。


## 后续计划

## 平台精度与退化策略
- Windows
  - 单调时钟优先使用 QPC；若不可用，初始化时退化为 GetTickCount64（毫秒精度），避免运行期路径切换导致的非连续性。
  - SleepFor 以毫秒粒度；默认不启用 timeBeginPeriod 以避免功耗上升，如需更高分辨率请在调用方按需启用并承担代价。
  - 可选低延迟策略：SetLowLatencySleepEnabled(True) 后，短延时会以 Sleep(1) 降能耗，最后 ~2ms 使用 QPC 忙等，改善抖动但增加 CPU 占用。
- Linux
  - 使用 CLOCK_MONOTONIC + clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME) 做绝对睡眠，减少累计误差；被信号中断（EINTR）时自动重试。
- macOS
  - 使用 mach_absolute_time 取时；SleepUntil 使用 mach_wait_until 进行绝对睡眠，减少漂移；SleepFor 仍基于 nanosleep 并处理 EINTR，注意调度抖动。

- 取消睡眠（Cancelable）
  - 当前采用协作式轮询策略（动态步长夹在 1..50ms），避免 busy-loop 与过度唤醒；对特别短的截止可结合 Slack/低延迟策略。
  - 对极低延迟场景，优先考虑事件/条件变量等阻塞原语实现的取消。

- 增加 ITimer/ITimerScheduler（一次性/周期）。
- 推动 async/poller/benchmark 使用 Deadline/Duration 表达超时（待 time 完成后再迁移）。



## 变更记录（v0.1.x）
- Windows：QPC → ns 换算改用纯整数算法，避免浮点舍入误差在长时间运行中的累积。
- Linux/macOS：对 nanosleep/clock_nanosleep 仅在 EINTR 时重试，遇到非 EINTR 错误将不再无限循环。
- 兼容说明：SetLowLatencySleepEnabled 仅作兼容入口，等价于 SetSleepStrategy(LowLatency)，建议优先使用策略枚举接口。


## 新 API 补充（v0.1.x+）
- Duration
  - Abs(): TDuration — 绝对值
  - Neg(): TDuration — 取反（Low(Int64) 饱和为 High(Int64)）
  - TryFromMs(A: Int64; out D: TDuration): Boolean — 毫秒构造（带溢出检测）
  - TryFromSec(A: Int64; out D: TDuration): Boolean — 秒构造（带溢出检测）
- Instant
  - Since(Older): TDuration — Diff 的可读别名
  - NonNegativeDiff(Older): TDuration — max(Diff, 0)
  - CheckedAdd(Dur, out R): Boolean — 安全相加（检测 U64 上/下溢）
  - CheckedSub(Dur, out R): Boolean — 安全相减（基于 CheckedAdd）
- 策略与片段睡眠粒度（Linux/macOS）
  - GetSleepStrategy: TSleepStrategy — 获取当前策略
  - SetSliceSleepMs(ms: Integer) — 同时设置 Linux/macOS 的片段睡眠粒度（ms）

### 系统时间（Unix 时间）
- 新增便捷函数：NowUnixMs/NowUnixNs（均基于 UTC）
- 说明：基于 NowUTC 计算，避免本地时区/DST 跳变影响
- 示例：
```pascal
Writeln('unix_ms=', NowUnixMs, ' unix_ns=', NowUnixNs);

// Balanced 最终自旋的让权节奏（默认 2048）
SetSpinYieldEvery(2048);
SetSpinYieldEveryFor(PlatLinux, 1024);
var nWin := GetSpinYieldEveryFor(PlatWindows);

```

  - SetSliceSleepMsFor(plat: TPlatformKind; ms: Integer) — 针对平台单独设置
  - GetSliceSleepMsFor(plat: TPlatformKind): Integer — 读取当前设置

### 使用示例
```pascal
// Duration 安全构造与取绝对值
var d: TDuration; ok: Boolean;
ok := TDuration.TryFromSec(2, d); // True: d=2s
writeln('abs(ns)=', d.Neg.Abs.AsNs);

// Instant 安全算术
var t0, t1: TInstant; outI: TInstant;
t0 := NowInstant; t1 := t0.Since(t0).Add(TDuration.FromMs(1));
if not t0.CheckedAdd(TDuration.FromNs(High(Int64)), outI) then
  writeln('CheckedAdd overflow prevented');

// 片段睡眠粒度（仅 Balanced/LowLatency 下影响 SleepFor）

## 实践指南（Best Practices）

### 总则
- 相对时间一律使用单调时钟（TInstant/TDuration），日志/人类时间用 NowUTC/NowLocal。
- API 对超时优先使用 TDeadline，而非裸毫秒整数。
- 睡眠/等待优先使用 SleepFor/SleepUntil，可取消路径使用 SleepForCancelable/SleepUntilCancelable。
- 短等待可用 SleepUntilWithSlack 预留“让权余量”以降低抖动。

### 类型与时间来源
- TDuration：区间/退避/节流/限流窗口
- TInstant：单调时刻戳；比较先后/判断到期
- TDeadline：表达“截止某时刻”；API 入参/出参的首选

示例：将毫秒转为 Deadline
```pascal
var dl: TDeadline;
dl := TDeadline.After(TDuration.FromMs(250));
if dl.HasExpired then ...
```

### 睡眠与等待
- 首选 SleepFor/SleepUntil；需要协作式取消时使用可取消版本
- 策略选择：默认 Balanced；对极短延迟敏感时才考虑 LowLatency/UltraLowLatency
- 运行时调参（必要时）：SetSleepStrategy / SetFinalSpinThresholdNs / SetFinalSpinThresholdNsFor

示例：Slack 等待
```pascal
var deadline: TInstant;
deadline := NowInstant.Add(TDuration.FromMs(100));
SleepUntilWithSlack(deadline, TDuration.FromMs(2));
```

### 定时器（选择与使用）
- 一次性：ScheduleOnce / ScheduleAt
- 周期：
  - FixedRate：按节拍对齐，可能“追赶”；用 SetTimerFixedRateMaxCatchupSteps 上限保护
  - FixedDelay：次次执行后再延迟，不追赶（更稳）
- 回调短小，避免阻塞调度线程；异常统一通过 SetTimerExceptionHandler 捕获记录
- 指标：TimerGetMetrics / TimerResetMetrics 做健康度采样
- 生命周期：Cancel 定时器；合适时机调用 Scheduler.Shutdown

### 格式化
- 默认：FormatDurationHuman 输出 ns/us/ms/s
- 配置：
  - SetDurationFormatUseAbbr(True|False)
  - SetDurationFormatSecPrecision(N)

### 跨模块迁移清单
- 输入参数：ms → TDuration/Deadline
- 内部时间：GetTickCount64/Now → NowInstant；差值 → TDuration
- 睡眠：Sleep(ms) → SleepFor(TDuration.FromMs(ms))
- 测试：用范围断言；覆盖可取消/周期定时器次数与顺序
- 文档：说明 Deadline 语义、FixedRate vs FixedDelay 选择

### 反模式（避免）
- 用 TDateTime 计算间隔或判定到期
- 传裸毫秒整数在多层流转
- 直接调用 Sleep(ms) 而非策略化 Sleep
- 周期回调里做重阻塞操作
- 忽略 Cancel/Shutdown，导致泄漏或退出卡顿

SetSliceSleepMsFor(PlatLinux, 2);
SetSliceSleepMsFor(PlatDarwin, 3);
```


## 新增 API（P0 强化）

### ParseDuration / TryParseDuration
- 语义：解析 Go 风格文本（如 "150ms", "2s", "1m2s", "3h", "250us", "100ns"），支持正负号
- 示例：
```pascal
var d: TDuration;
CheckTrue(TryParseDuration('1m2s', d));
CheckEquals(62, d.AsSec);
```

### TimeoutFor / TimeoutUntil（同步）
- 语义：为同步过程提供超时保护；超时返回 False；过程内异常向外传播
- 示例：
```pascal
var ok: Boolean;
ok := TimeoutFor(TDuration.FromMs(5),
  procedure begin SleepFor(TDuration.FromMs(20)); end);
// ok = False 表示超时
```

### ManualClock（测试）
- CreateManualMonotonicClock(StartAt)
- 用于虚拟时间驱动定时器测试，配合 CreateTimerScheduler(clock)

### ITimer.Reset（一次性定时器）
- ResetAt(Instant) / ResetAfter(Duration)
- 仅 tkOnce 有效；已触发/已取消返回 False

### ITicker 简装
- 接口：Stop/IsStopped
- 工厂：
  - CreateTickerFixedRate/FixedDelay（可注入 Clock）
  - CreateTickerFixedRateOn/FixedDelayOn（复用外部 Scheduler）
- 用法：周期执行回调，Stop 后通过 Cancel 停止
