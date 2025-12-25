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

## Sleep / Wait 策略（现状说明）
- 当前实现位于 `fafafa.core.time.clock`。
- `SleepFor` / `SleepUntil`：基础睡眠（直接调用 OS 睡眠；不受策略参数影响）。
- `WaitFor` / `WaitUntil`：可取消等待（`ICancellationToken`），并使用“切片睡眠 + 微睡眠 + 最终 yield”策略来平衡响应与 CPU 开销。
- 全局可配置项：
  - 取消检查间隔：`SetCancellationCheckInterval` / `GetCancellationCheckInterval`（默认 1ms）
  - 睡眠策略：`SetSleepStrategy` / `GetSleepStrategy`
    - `TSleepStrategy = (ssBalanced, ssLowLatency, ssLowPower, ssCustom)`
  - 自定义策略参数：`SetSleepStrategyParams` / `GetSleepStrategyParams`（单位：纳秒）
    - FinalSpinNs：最终自旋阈值
    - MicroSleepNs：微睡眠步长
    - SliceSleepNs：常规切片睡眠上限

示例（配置 WaitFor/WaitUntil 行为）：
```pascal
uses fafafa.core.time, fafafa.core.thread;

var
  cts: ICancellationTokenSource;
  ok: Boolean;

begin
  SetCancellationCheckInterval(TDuration.FromMs(1));
  SetSleepStrategy(ssBalanced);

  // 自定义：FinalSpin=20us, MicroSleep=25us, Slice=500us
  SetSleepStrategyParams(20000, 25000, 500000);

  cts := CreateCancellationTokenSource;
  ok := DefaultMonotonicClock.WaitFor(TDuration.FromSec(1), cts.Token);
  // ok=false 表示取消赢了
end.
```

## 定时器（TimerScheduler）
- 推荐入口：`uses fafafa.core.time;`（门面单元）
- 对象与接口
  - ITimerScheduler：ScheduleOnce/ScheduleAt/ScheduleAtFixedRate/ScheduleWithFixedDelay + Shutdown
  - ITimerSchedulerTry：TrySchedule*/TryScheduleAt*/TryScheduleAtCb（Result 风格，返回 `TTimerResult`）
  - ITimer：Cancel/IsCancelled + 状态查询/暂停恢复/执行次数限制等（v2.0）
- 回调执行与线程模型
  - 默认：回调在调度器线程执行（回调应短小、非阻塞）
  - 可选：通过 `TTimerSchedulerOptions.WithCallbackExecutor(pool)` 或 `SetCallbackExecutor` 开启异步回调（在线程池执行）
- 后端说明
  - 当前默认实现为二叉堆调度；`fafafa.core.time.timer.backend*` 为实验/设计草案（未作为可选后端接入调度器）
- 失败语义（约定）
  - ScheduleFixedRate/FixedDelay：Period/Delay<=0 返回 nil
  - Scheduler.Shutdown 后：Schedule* 返回 nil；Try* 返回 `Err(tekShutdown)`
- 用法示例（门面推荐）
```pascal
uses fafafa.core.time;

var
  sch: ITimerScheduler;
  tm: ITimer;
  fired: Integer = 0;

procedure OnTick;
begin
  Inc(fired);
end;

begin
  sch := CreateTimerScheduler;
  tm := sch.ScheduleAtFixedRate(TDuration.FromMs(100), TDuration.FromMs(300), @OnTick);
  SleepFor(TDuration.FromMs(1100));
  if tm <> nil then tm.Cancel;
  sch.Shutdown;
end.
```

### Result 风格（TrySchedule*）示例
```pascal
uses fafafa.core.time;

procedure Noop;
begin
end;

var
  r: TTimerResult;
  err: TTimeErrorKind;

begin
  // 参数非法：返回 Err(tekInvalidArgument)
  r := TryScheduleFixedRate(TDuration.Zero, TDuration.Zero, @Noop);
  if r.TryUnwrapErr(err) then
    WriteLn('TryScheduleFixedRate failed, err_kind=', Ord(err));
end.
```

### 异步回调（线程池执行器）示例
```pascal
uses fafafa.core.time, fafafa.core.thread;

procedure OnWork;
begin
  // 回调在线程池中执行（如果配置了 CallbackExecutor）
end;

var
  pool: IThreadPool;
  opt: TTimerSchedulerOptions;
  sch2: ITimerScheduler;

begin
  pool := CreateThreadPool(1, 1, 60000, -1, TRejectPolicy.rpAbort);
  try
    opt := TTimerSchedulerOptions.Default.WithCallbackExecutor(pool);
    sch2 := CreateTimerScheduler(opt);
    try
      sch2.ScheduleOnce(TDuration.FromMs(10), @OnWork);
      SleepFor(TDuration.FromMs(50));
    finally
      sch2.Shutdown;
    end;
  finally
    pool.Shutdown;
    pool.AwaitTermination(2000);
  end;
end.
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

备注：
- `FormatDurationHuman` 的可用配置项仅包含：
  - `SetDurationFormatUseAbbr(True|False)`
  - `SetDurationFormatSecPrecision(N)`
- 定时器（`ITimerScheduler`/`ITimer`）的行为说明与示例请参考上文“定时器（TimerScheduler）”章节。
## 后续计划
- 路线图与实现状态请参考：`docs/fafafa.core.time.spec.md`。
- 文档层面会逐步把“基准测试草案/调参经验”迁移到独立文档，避免与实际 API 混淆。

## 平台实现摘要
- 单调时钟（NowInstant）
  - Windows：QPC（失败回退到 GetTickCount64）
  - Linux：clock_gettime(CLOCK_MONOTONIC)（失败回退到 GetTickCount64）
  - macOS：mach_absolute_time
- 系统时钟（NowUTC/NowLocal/NowUnixMs/NowUnixNs）
  - Windows：FILETIME（ns 精度）
  - Unix：基于 UTC 快照计算（当前实现精度为 ms 级）

## 可取消等待（WaitFor/WaitUntil）
- 通过 `ICancellationToken` 支持协作式取消。
- 行为可通过以下全局配置调优：
  - `SetCancellationCheckInterval` / `GetCancellationCheckInterval`
  - `SetSleepStrategy` / `GetSleepStrategy`
  - `SetSleepStrategyParams` / `GetSleepStrategyParams`

## 已实现的关键 API（摘录）
- ParseDuration / TryParseDuration（Go 风格 duration 文本解析）
- TimerScheduler（ITimerScheduler / ITimerSchedulerTry / ITimer / ITicker）
- TDeadline（超时表达）

## 日期与时间类型

### TDate（日期）
```pascal
uses fafafa.core.time.date;

var d: TDate;
begin
  d := TDate.Create(2025, 12, 24);           // 构造
  d := TDate.Today;                          // 当前日期
  d := TDate.FromDateTime(Now);              // 从 TDateTime 转换

  // 组件访问
  WriteLn(d.GetYear, '-', d.GetMonth, '-', d.GetDay);
  WriteLn('星期', d.GetDayOfWeek);           // 1=Sunday
  WriteLn('年中第', d.GetDayOfYear, '天');

  // 算术
  d := d.AddDays(7);
  d := d.AddMonths(1);
  d := d.AddYears(1);

  // 格式化与解析
  WriteLn(d.ToString);                       // "2025-12-24"
  TDate.TryParse('2025-12-24', d);
end.
```

### TTimeOfDay（一天中的时间）
```pascal
uses fafafa.core.time.timeofday;

var t: TTimeOfDay;
begin
  t := TTimeOfDay.Create(14, 30, 45);        // 14:30:45
  t := TTimeOfDay.Create(14, 30, 45, 500);   // 带毫秒
  t := TTimeOfDay.Midnight;                  // 00:00:00
  t := TTimeOfDay.Noon;                      // 12:00:00

  // 组件访问
  WriteLn(t.GetHour, ':', t.GetMinute, ':', t.GetSecond);
  WriteLn('毫秒:', t.GetMillisecond);

  // 状态查询
  if t.IsAM then WriteLn('上午');
  if t.IsPM then WriteLn('下午');

  // 格式化
  WriteLn(t.ToString);                       // "14:30:45"
  WriteLn(t.ToLongString);                   // "14:30:45.500"
  WriteLn(t.To12HourString);                 // "2:30 PM"
end.
```

### TNaiveDateTime（本地日期时间，无时区）
```pascal
uses fafafa.core.time.naivedatetime;

var dt: TNaiveDateTime;
begin
  dt := TNaiveDateTime.Create(2025, 12, 24, 14, 30, 0);
  dt := TNaiveDateTime.Now;                  // 当前本地时间

  // 组件访问
  WriteLn(dt.GetDate.ToString);              // 日期部分
  WriteLn(dt.GetTime.ToString);              // 时间部分

  // With* 链式修改（返回新值）
  dt := dt.WithYear(2026).WithMonth(1).WithDay(1);
  dt := dt.WithHour(0).WithMinute(0);
end.
```

## CRON 表达式（任务调度）

```pascal
uses fafafa.core.time.scheduler;

var
  cron: ICronExpression;
  fromTime, nextTime, prevTime: TInstant;
begin
  // 创建 CRON 表达式
  cron := CreateCronExpression('0 9 * * 1-5');  // 工作日 9:00

  if cron.IsValid then
  begin
    fromTime := NowInstant;

    // 获取下一个执行时间
    nextTime := cron.GetNextTime(fromTime);

    // 获取上一个执行时间（反向查找）
    prevTime := cron.GetPreviousTime(fromTime);
  end;
end.
```

常用 CRON 表达式：
- `* * * * *` - 每分钟
- `0 * * * *` - 每小时整点
- `0 9 * * *` - 每天 9:00
- `0 0 1 * *` - 每月 1 号 0:00
- `0 9 * * 1-5` - 工作日 9:00
- `0 0 29 2 *` - 每年 2 月 29 日（闰年）

## ISO 8601 格式化与解析

```pascal
uses fafafa.core.time.iso8601;

var
  dt: TDateTime;
  opts: TISO8601Options;
  formatted: string;
  parsed: TDateTime;
  dur: TISO8601Duration;
begin
  dt := EncodeDate(2025, 12, 24) + EncodeTime(14, 30, 0, 0);

  // 格式化
  formatted := TISO8601Formatter.FormatDateTime(dt);  // "2025-12-24T14:30:00"

  // 带选项格式化
  opts := TISO8601Options.UTC;
  formatted := TISO8601Formatter.FormatDateTime(dt, opts);  // "2025-12-24T14:30:00Z"

  // 解析
  if TISO8601Parser.ParseDateTime('2025-12-24T14:30:00Z', parsed) then
    WriteLn('解析成功');

  // Duration 格式化与解析
  formatted := TISO8601Formatter.FormatDuration(TDuration.FromHours(2));  // "PT2H"
  dur := TISO8601Duration.FromString('PT1H30M');
  WriteLn('分钟数:', dur.ToTDuration.WholeMinutes);  // 90
end.
```

## 时区支持

```pascal
uses fafafa.core.time.tz;

var
  tz: ITimeZone;
  utcTime, localTime: TDateTime;
begin
  // 获取时区
  tz := GetTimeZone('Asia/Shanghai');
  // 或使用本地时区
  tz := GetLocalTimeZone;

  // UTC 转本地
  utcTime := NowUTC;
  localTime := tz.ToLocal(utcTime);

  // 本地转 UTC
  utcTime := tz.ToUTC(localTime);

  // 时区偏移（分钟）
  WriteLn('UTC+', tz.GetOffsetMinutes(utcTime) div 60);
end.
```

## 解析器安全特性

时间解析模块内置了多层安全防护：

1. **输入长度限制**：最大 4096 字符，防止 DoS 攻击
2. **格式字符串验证**：白名单校验，拒绝正则元字符
3. **正则复杂度估算**：防止回溯炸弹（ReDoS）

```pascal
uses fafafa.core.time.parse;

var
  result: TFormatValidationResult;
begin
  // 验证格式字符串安全性
  result := ValidateFormatString('yyyy-mm-dd');
  if result.IsValid then
    WriteLn('格式安全')
  else
    WriteLn('不安全: ', result.ErrorMessage);
end.
```

## 性能特征

基于 10 万次迭代的典型测量值（实际值因环境而异）：

| 操作 | 典型耗时 |
|------|----------|
| NowInstant | < 2μs |
| Duration 加法 | < 50ns |
| Duration 比较 | < 20ns |
| Instant 比较 | < 20ns |
| Stopwatch 周期 | < 1.5μs |

## 废弃方法

部分旧版本方法已标记为 `deprecated`，将在 v3.0 版本移除。

主要变更：
- **比较方法** (`Equal`、`LessThan` 等) → 使用运算符 (`=`、`<` 等)
- **TDuration.CheckedDivBy** → 使用 `CheckedDiv`
- **TStopwatch.LapDuration** → 使用 `Lap`

详细迁移指南请参考：[fafafa.core.time.DEPRECATIONS.md](fafafa.core.time.DEPRECATIONS.md)

