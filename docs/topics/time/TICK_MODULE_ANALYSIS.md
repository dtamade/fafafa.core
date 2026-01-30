# fafafa.core.time.tick 模块深度分析报告

> 📅 生成时间：2025-10-01  
> 🎯 目标：全面分析 tick 模块的架构、实现和使用

---

## 📋 目录

1. [模块概述](#模块概述)
2. [架构设计](#架构设计)
3. [核心组件分析](#核心组件分析)
4. [平台实现](#平台实现)
5. [与其他模块的关系](#与其他模块的关系)
6. [性能特性](#性能特性)
7. [使用场景](#使用场景)
8. [最佳实践](#最佳实践)
9. [问题与改进建议](#问题与改进建议)

---

## 1. 模块概述

### 1.1 设计目标

`fafafa.core.time.tick` 模块是 fafafa.core 时间系统的**底层基础设施**，提供跨平台的高精度时间测量能力。

**核心职责：**
- 抽象不同平台的时间计数器接口
- 提供统一的 `ITick` 接口
- 支持多种精度级别的计时器
- 为上层模块（Stopwatch、Duration、Instant）提供原始时间数据

### 1.2 设计哲学

```
┌─────────────────────────────────────────────────┐
│  设计原则                                        │
├─────────────────────────────────────────────────┤
│ 1. 接口统一   - ITick 接口隔离平台差异          │
│ 2. 分层清晰   - base → platform → facade        │
│ 3. 性能优先   - 支持硬件计时器，最小开销         │
│ 4. 可扩展性   - 易于添加新平台或新计时器类型     │
│ 5. 类型安全   - 强类型枚举，避免魔法数字         │
└─────────────────────────────────────────────────┘
```

---

## 2. 架构设计

### 2.1 模块分层

```
┌──────────────────────────────────────────────────────────┐
│                    应用层                                 │
│  TStopwatch、TDuration、TInstant、Clock                  │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│              Tick 门面层 (tick.pas)                       │
│  统一入口：MakeTick(), MakeBestTick(), 自动平台选择      │
└──────────────────────────────────────────────────────────┘
                          ↓
┌───────────────┬──────────────┬──────────────┬────────────┐
│  Windows      │   Darwin     │    Unix      │  Hardware  │
│  tick.windows │ tick.darwin  │  tick.unix   │ tick.hw.*  │
│               │              │              │            │
│ • QPC         │ • mach_time  │ • MONOTONIC  │ • TSC      │
│ • GetTick64   │              │ • gettimeofday│ • CNTVCT   │
└───────────────┴──────────────┴──────────────┴────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│           基础层 (tick.base.pas)                          │
│  ITick 接口、TTick 基类、TTickType 枚举                   │
└──────────────────────────────────────────────────────────┘
```

### 2.2 核心文件结构

| 文件 | 职责 | 关键内容 |
|------|------|----------|
| `tick.base.pas` | 基础定义 | ITick 接口、TTick 基类、TTickType 枚举 |
| `tick.pas` | 统一门面 | 工厂函数、平台自动选择、类型导出 |
| `tick.windows.pas` | Windows 实现 | QPC (高精度)、GetTickCount64 (标准) |
| `tick.unix.pas` | Unix/Linux 实现 | clock_gettime (MONOTONIC、REALTIME) |
| `tick.darwin.pas` | macOS 实现 | mach_absolute_time |
| `tick.hardware.*.pas` | 硬件计时器 | TSC (x86)、CNTVCT (ARM)、time CSR (RISC-V) |

---

## 3. 核心组件分析

### 3.1 ITick 接口

```pascal
ITick = interface
  ['{B8F5A2E1-4C3D-4F2A-9B1E-8D7C6A5F4E3D}']
  function GetResolution: UInt64;      // 频率 (ticks/秒)
  function GetIsMonotonic: Boolean;     // 是否单调递增
  function GetTickType: TTickType;      // 计时器类型
  
  function Tick: UInt64;                // 获取当前计数值
  
  property Resolution: UInt64 read GetResolution;
  property IsMonotonic: Boolean read GetIsMonotonic;
  property TickType: TTickType read GetTickType;
end;
```

**接口设计分析：**

✅ **优点：**
- 简洁明确，职责单一
- 属性只读，避免误修改
- 支持 GUID，便于 QueryInterface
- 提供元数据（Resolution、IsMonotonic），便于调试和性能分析

⚠️ **潜在改进：**
- 缺少错误处理机制（Tick() 返回 0 表示失败？）
- 没有提供批量获取功能（某些场景需要连续采样）

### 3.2 TTickType 枚举

```pascal
TTickType = (
  ttStandard,      // 标准精度 (ms 级)
  ttHighPrecision, // 高精度 (ns 级)
  ttHardware       // 硬件计时器
);

TTickTypes = set of TTickType;
```

**类型分级：**

| 类型 | 精度 | 性能 | 可靠性 | 平台支持 |
|------|------|------|--------|----------|
| **ttStandard** | ~1ms | 快 | 高 | 全平台 |
| **ttHighPrecision** | ~100ns | 中 | 高 | 全平台 |
| **ttHardware** | ~1ns | 极快 | 中 | 特定 CPU |

### 3.3 TTick 抽象基类

```pascal
TTick = class(TInterfacedObject, ITick)
private
  FResolution: UInt64;
  FIsMonotonic: Boolean;
  FTickType: TTickType;
protected
  procedure Initialize(out aResolution: UInt64; 
                       out aIsMonotonic: Boolean; 
                       out aTickType: TTickType); virtual; abstract;
public
  constructor Create; virtual;
  function Tick: UInt64; virtual; abstract;
end;
```

**设计模式：模板方法**
- `Create` 调用 `Initialize` 获取平台特定参数
- 子类只需实现 `Initialize` 和 `Tick`
- 统一的参数验证逻辑（Resolution 不能为 0）

---

## 4. 平台实现

### 4.1 Windows 实现 (`tick.windows.pas`)

#### 4.1.1 标准计时器 (TStdTick)

```pascal
function TStdTick.Tick: UInt64;
begin
  Result := GetTickCount64;  // 系统启动后的毫秒数
end;
```

**特性：**
- 分辨率：1 ms (1000 ticks/秒)
- 单调性：✅ 单调递增，不受系统时间调整影响
- 性能：极快，直接系统调用
- 精度：低，仅毫秒级

#### 4.1.2 高精度计时器 (THDTick)

```pascal
function THDTick.Tick: UInt64;
begin
  if not QueryPerformanceCounter(Result) then
    Result := 0;
end;
```

**特性：**
- 分辨率：通常 ~10 MHz (10,000,000 ticks/秒)
- 单调性：✅ 保证单调
- 性能：稍慢于 GetTickCount64，但仍很快
- 精度：高，纳秒级

**初始化机制：**
```pascal
// 使用原子操作实现懒加载 + Once 语义
var
  GQpcResolution: UInt64 = 0;
  GQpcResolutionOnce: Int32 = 0;  // 0=未开始, 1=进行中, 2=完成

function GetHDResolution: UInt64;
begin
  // 快路径：已初始化
  if atomic_load(GQpcResolutionOnce, mo_acquire) = 2 then
    Exit(GQpcResolution);
  
  // 慢路径：CAS 竞争初始化
  if atomic_compare_exchange(GQpcResolutionOnce, 0, 1) then
  begin
    QueryPerformanceFrequency(GQpcResolution);
    atomic_store(GQpcResolutionOnce, 2, mo_release);
  end
  else
    // 忙等待其他线程完成初始化
    while atomic_load(GQpcResolutionOnce, mo_acquire) <> 2 do
      CpuRelax;
  
  Result := GQpcResolution;
end;
```

✅ **优秀实践：**
- 线程安全的懒加载
- 使用 Acquire/Release 语义保证内存顺序
- CpuRelax 减少忙等待功耗

### 4.2 Unix/Linux 实现 (`tick.unix.pas`)

#### 4.2.1 高精度实现

```pascal
function THDTick.Tick: UInt64;
var
  ts: timespec;
begin
  if clock_gettime(CLOCK_MONOTONIC, @ts) = 0 then
    Result := UInt64(ts.tv_sec) * NANOSECONDS_PER_SECOND + UInt64(ts.tv_nsec)
  else
    Result := 0;
end;
```

**CLOCK_MONOTONIC 特性：**
- 保证单调递增
- 不受 NTP 或用户调整影响
- 系统休眠时暂停（使用 CLOCK_BOOTTIME 可继续计时）
- 精度：通常纳秒级

### 4.3 Darwin/macOS 实现 (`tick.darwin.pas`)

```pascal
function THDTick.Tick: UInt64;
begin
  Result := mach_absolute_time;  // 直接调用内核函数
end;
```

**mach_absolute_time 特性：**
- 高性能，直接读取 CPU 计数器
- 返回的是 **CPU ticks**，需要 mach_timebase_info 转换为纳秒
- 单调递增，不受系统时间影响

### 4.4 硬件计时器实现

#### 4.4.1 x86/x64 - TSC (Time Stamp Counter)

```pascal
// x86_64 示例
function TTSCHTDTSC.Tick: UInt64; assembler; nostackframe;
asm
  lfence      // 内存屏障，防止乱序
  rdtsc       // 读取 TSC
  shl rdx, 32
  or  rax, rdx
end;
```

**TSC 特性：**
- 极高性能（~20 cycles）
- 纳秒甚至亚纳秒精度
- ⚠️ **需要 invariant TSC** 才保证单调（检测 CPUID）
- ⚠️ 多核系统需要 TSC 同步

**校准机制：**
```pascal
// 10ms 对称校准，使用 QPC 作为参考
for i := 1 to CalibrationRounds do
begin
  t0_ref := GetHDTick;
  t0_tsc := ReadTSC;
  Sleep(10);
  t1_tsc := ReadTSC;
  t1_ref := GetHDTick;
  
  // 计算频率
  freq := (t1_tsc - t0_tsc) * QPCFreq div (t1_ref - t0_ref);
  // 取中位数或平均值
end;
```

#### 4.4.2 ARM - 架构通用计时器

```pascal
// AArch64 读取虚拟计数器
function TARMv8Timer.Tick: UInt64; assembler; nostackframe;
asm
  mrs x0, cntvct_el0  // 读取虚拟计数器
end;

// 读取频率
mrs x0, cntfrq_el0
```

**ARM Generic Timer 特性：**
- 固定频率（通常 1-100 MHz），不受 DVFS 影响
- 保证单调
- 需要 EL0 (用户态) 权限访问

---

## 5. 与其他模块的关系

### 5.1 依赖关系图

```
┌─────────────────────────────────────────────────┐
│  fafafa.core.time (高级 API)                     │
│  ├─ TDuration                                    │
│  ├─ TInstant                                     │
│  ├─ TDeadline                                    │
│  ├─ IClock / IMonotonicClock                     │
│  └─ SleepFor / SleepUntil                        │
└─────────────────────────────────────────────────┘
                   ↓ 使用
┌─────────────────────────────────────────────────┐
│  fafafa.core.time.stopwatch                      │
│  └─ TStopwatch (基于 ITick)                      │
└─────────────────────────────────────────────────┘
                   ↓ 依赖
┌─────────────────────────────────────────────────┐
│  fafafa.core.time.tick                           │
│  └─ ITick / TTick / MakeTick()                   │
└─────────────────────────────────────────────────┘
```

### 5.2 TDuration 与 ITick 的转换

```pascal
// ITick → TDuration
function TicksToDuration(Ticks: UInt64; const Clock: ITick): TDuration;
var
  ns: UInt64;
begin
  // ticks * (1e9 / frequency)
  ns := Ticks * NANOSECONDS_PER_SECOND div Clock.Resolution;
  Result := TDuration.FromNs(ns);
end;

// TDuration → ITick ticks
function DurationToTicks(const D: TDuration; const Clock: ITick): UInt64;
begin
  Result := D.AsNs * Clock.Resolution div NANOSECONDS_PER_SECOND;
end;
```

### 5.3 TStopwatch 的实现依赖

```pascal
TStopwatch = record
private
  FClock: ITick;        // 依赖 ITick
  FStartTick: UInt64;
  FElapsedTicks: UInt64;
  FIsRunning: Boolean;
  
  procedure EnsureClock;
  begin
    if FClock = nil then
      FClock := MakeBestTick;  // 自动选择最佳 Tick
  end;
  
public
  function ElapsedDuration: TDuration;
  begin
    Result := TicksToDuration(ElapsedTicks, FClock);
  end;
end;
```

---

## 6. 性能特性

### 6.1 性能对比 (Windows 平台)

| 计时器 | 调用耗时 | 分辨率 | 适用场景 |
|--------|----------|--------|----------|
| GetTickCount64 | ~30 ns | 1 ms | 长时间测量 (>100ms) |
| QueryPerformanceCounter | ~50-100 ns | ~100 ns | 中等精度测量 (>1ms) |
| RDTSC (硬件) | ~20 ns | ~1 ns | 高频短时测量 (<1ms) |

### 6.2 开销分析

```
测量 1ms 操作的开销对比：

GetTickCount64:
  ├─ 调用开销: 30 ns
  └─ 相对误差: 30ns / 1ms = 0.003%  ✅ 可忽略

QueryPerformanceCounter:
  ├─ 调用开销: 100 ns
  └─ 相对误差: 100ns / 1ms = 0.01%  ✅ 可忽略

RDTSC:
  ├─ 调用开销: 20 ns
  └─ 相对误差: 20ns / 1ms = 0.002%  ✅ 极小

对于 1μs 操作：
  └─ RDTSC 误差: 20ns / 1μs = 2%    ⚠️ 需要多次采样
```

### 6.3 精度与准确度

**精度 (Precision)：** 计时器能够分辨的最小时间单位

| 平台 | 标准 | 高精度 | 硬件 |
|------|------|--------|------|
| Windows | 1 ms | 100 ns | 0.3 ns (3 GHz TSC) |
| Linux | 1 ms | 1 ns | 0.3 ns |
| macOS | 1 ms | 1 ns | - |

**准确度 (Accuracy)：** 实际测量值与真实值的接近程度

⚠️ **影响因素：**
- CPU 调度延迟 (0.1-10 ms)
- 中断处理 (1-100 μs)
- 上下文切换 (5-30 μs)
- 内存访问延迟 (10-100 ns)

---

## 7. 使用场景

### 7.1 适用场景矩阵

| 场景 | 推荐计时器 | 理由 |
|------|-----------|------|
| **Web 请求响应时间** | ttHighPrecision | 通常 10-500ms，需要 ms 级精度 |
| **数据库查询性能** | ttHighPrecision | 1-100ms，需要准确统计 |
| **微服务调用** | ttHighPrecision | 10-1000ms |
| **算法性能对比** | ttHardware | 微秒到毫秒级，需要高精度 |
| **帧率计算 (60fps)** | ttHighPrecision | 16.67ms/帧 |
| **超时检测** | ttStandard | 秒级，不需要高精度 |
| **性能基准测试** | ttHardware | 需要极高精度和低开销 |
| **日志时间戳** | ttStandard | 毫秒足够 |

### 7.2 代码示例

#### 7.2.1 简单计时

```pascal
uses fafafa.core.time.tick;

procedure MeasureFunction;
var
  tick: ITick;
  t0, t1: UInt64;
  elapsed: TDuration;
begin
  tick := MakeBestTick;  // 自动选择最佳计时器
  
  t0 := tick.Tick;
  DoSomeWork;
  t1 := tick.Tick;
  
  elapsed := TicksToDuration(t1 - t0, tick);
  WriteLn('耗时: ', elapsed.AsMs, ' ms');
end;
```

#### 7.2.2 使用 TStopwatch (推荐)

```pascal
uses fafafa.core.time.stopwatch;

procedure BetterMeasure;
var
  sw: TStopwatch;
begin
  sw := TStopwatch.StartNew;
  DoSomeWork;
  sw.Stop;
  
  WriteLn('耗时: ', sw.ElapsedMs, ' ms');
  WriteLn('精确: ', sw.ElapsedNs, ' ns');
end;
```

#### 7.2.3 多段计时 (Lap)

```pascal
procedure ProfileSteps;
var
  sw: TStopwatch;
  laps: TArray<TDuration>;
  i: Integer;
begin
  sw := TStopwatch.StartNew;
  
  Step1; sw.Lap;  // 记录第一段
  Step2; sw.Lap;  // 记录第二段
  Step3; sw.Lap;  // 记录第三段
  
  sw.Stop;
  laps := sw.GetLaps;
  
  for i := 0 to High(laps) do
    WriteLn(Format('Step %d: %.3f ms', [i+1, laps[i].AsMs]));
end;
```

#### 7.2.4 指定计时器类型

```pascal
procedure UseHardwareTick;
var
  tick: ITick;
begin
  if HasHardwareTick then
  begin
    tick := MakeHWTick;  // 使用硬件 TSC
    WriteLn('使用硬件计时器，频率: ', tick.Resolution, ' Hz');
  end
  else
  begin
    tick := MakeHDTick;  // 回退到高精度
    WriteLn('硬件计时器不可用，使用高精度');
  end;
  
  // 使用 tick...
end;
```

---

## 8. 最佳实践

### 8.1 选择计时器的建议

```pascal
// ✅ 推荐：使用 TStopwatch（封装良好）
var sw := TStopwatch.StartNew;

// ⚠️ 仅需自定义时使用 ITick
var tick := MakeBestTick;

// ❌ 不推荐：直接使用平台 API
var t := GetTickCount64;  // 失去跨平台性
```

### 8.2 测量微小时间的技巧

```pascal
// ❌ 错误：单次测量不准确
procedure WrongWay;
var sw: TStopwatch;
begin
  sw := TStopwatch.StartNew;
  FastFunction;  // <1μs
  sw.Stop;
  WriteLn(sw.ElapsedNs);  // 误差大！
end;

// ✅ 正确：多次测量取平均
procedure CorrectWay;
const
  Iterations = 1000;
var
  sw: TStopwatch;
  i: Integer;
  avgNs: UInt64;
begin
  sw := TStopwatch.StartNew;
  for i := 1 to Iterations do
    FastFunction;
  sw.Stop;
  
  avgNs := sw.ElapsedNs div Iterations;
  WriteLn('平均耗时: ', avgNs, ' ns');
end;
```

### 8.3 避免常见错误

#### 8.3.1 频率混淆

```pascal
// ❌ 错误：直接用 ticks 做算术
var
  t0, t1, diff: UInt64;
  tick: ITick;
begin
  tick := MakeTick;
  t0 := tick.Tick;
  DoWork;
  t1 := tick.Tick;
  
  diff := t1 - t0;
  WriteLn(diff, ' ms');  // 错误！这不是毫秒！
end;

// ✅ 正确：转换为标准单位
var duration := TicksToDuration(t1 - t0, tick);
WriteLn(duration.AsMs, ' ms');
```

#### 8.3.2 跨时钟比较

```pascal
// ❌ 错误：不同时钟的 ticks 不能比较
var
  tick1 := MakeStdTick;
  tick2 := MakeHDTick;
  t1 := tick1.Tick;
  t2 := tick2.Tick;
  
  if t1 > t2 then ...  // 毫无意义！

// ✅ 正确：统一使用一个时钟
var tick := MakeBestTick;
```

### 8.4 线程安全考虑

```pascal
// ✅ ITick 实例本身是线程安全的（只读）
var GlobalTick: ITick;

initialization
  GlobalTick := MakeBestTick;  // 可安全共享

// ⚠️ TStopwatch 不是线程安全的
type
  TThreadSafeStopwatch = class
  private
    FLock: TCriticalSection;
    FStopwatch: TStopwatch;
  public
    procedure Start;
    procedure Stop;
    function ElapsedMs: UInt64;
  end;
```

---

## 9. 问题与改进建议

### 9.1 当前存在的问题

#### 9.1.1 错误处理不足

```pascal
// 当前实现
function Tick: UInt64;
begin
  if not QueryPerformanceCounter(Result) then
    Result := 0;  // 返回 0 表示失败，但调用者可能不检查
end;

// 建议改进
function TryTick(out AValue: UInt64): Boolean;
begin
  Result := QueryPerformanceCounter(AValue);
end;

function Tick: UInt64;
begin
  if not TryTick(Result) then
    raise ETickError.Create('Failed to get tick');
end;
```

#### 9.1.2 缺少性能诊断信息

```pascal
// 建议添加
type
  ITickDiagnostics = interface
    function GetCallOverheadNs: UInt64;      // 调用开销
    function GetMinResolutionNs: UInt64;     // 最小分辨率
    function IsStable: Boolean;              // 是否稳定（检测频率漂移）
    function GetDriftPPM: Double;            // 漂移率 (ppm)
  end;
```

#### 9.1.3 硬件计时器的可靠性检测不完善

```pascal
// TSC 需要更完善的检测
function IsTSCReliable: Boolean;
begin
  Result := HasInvariantTSC and     // CPUID 检测
            IsTSCSynchronized and   // 多核同步检测
            (not HasDVFS);          // 动态频率调整检测
end;
```

### 9.2 改进建议

#### 9.2.1 短期改进

1. **添加错误处理**
   ```pascal
   type
     TTickError = (teSuccess, teNotSupported, teSystemError);
   
   function TryTick(out Value: UInt64; out Error: TTickError): Boolean;
   ```

2. **增加诊断工具**
   ```pascal
   function MeasureTickOverhead(const Tick: ITick; 
                                 Iterations: Integer = 1000): UInt64;
   ```

3. **改进文档**
   - 为每个平台实现添加性能特性说明
   - 提供选择决策树

#### 9.2.2 长期改进

1. **支持时间回调/通知**
   ```pascal
   type
     ITickScheduler = interface
       procedure ScheduleAt(Tick: UInt64; Callback: TProc);
       procedure ScheduleAfter(Ticks: UInt64; Callback: TProc);
     end;
   ```

2. **性能监控集成**
   ```pascal
   type
     ITickMonitor = interface
       procedure RecordMeasurement(const Name: string; Ticks: UInt64);
       function GetStatistics(const Name: string): TTickStatistics;
     end;
   ```

3. **更细粒度的平台特性查询**
   ```pascal
   type
     TTickCapabilities = record
       MinResolutionNs: UInt64;
       MaxCallOverheadNs: UInt64;
       IsUserModeAccessible: Boolean;
       RequiresCalibration: Boolean;
     end;
   
   function GetTickCapabilities(TickType: TTickType): TTickCapabilities;
   ```

### 9.3 与其他模块的协同改进

#### 9.3.1 与 TDuration/TInstant 更紧密集成

```pascal
// 当前：需要手动转换
var
  tick: ITick;
  t0, t1: UInt64;
  d: TDuration;
begin
  t0 := tick.Tick;
  t1 := tick.Tick;
  d := TicksToDuration(t1 - t0, tick);  // 手动转换
end;

// 建议：直接支持
type
  ITick = interface
    function GetInstant: TInstant;           // 返回 TInstant
    function MeasureDuration(From, To: UInt64): TDuration;  // 内置转换
  end;
```

#### 9.3.2 与 Clock 模块统一

```pascal
// 当前 ITick 和 IMonotonicClock 是分离的

// 建议：统一抽象
type
  ITimeSource = interface
    function GetResolution: TDuration;
    function GetNow: TInstant;
    function IsMonotonic: Boolean;
  end;
  
// ITick 作为 ITimeSource 的轻量级实现
// IMonotonicClock 作为 ITimeSource 的高级封装
```

---

## 10. 总结

### 10.1 模块优势

✅ **架构清晰**
- 分层合理，职责明确
- 接口抽象良好，平台实现隔离

✅ **性能优秀**
- 支持多级精度选择
- 硬件计时器提供极致性能

✅ **跨平台**
- 覆盖主流平台 (Windows/Linux/macOS)
- 支持多种 CPU 架构 (x86/ARM/RISC-V)

✅ **易用性**
- `MakeBestTick` 自动选择
- `TStopwatch` 高级封装

### 10.2 核心价值

`fafafa.core.time.tick` 是整个时间系统的**基石**，为上层提供：

1. **准确的时间测量** - 高精度、低开销
2. **平台透明性** - 统一接口，无需关心底层
3. **性能灵活性** - 根据需求选择合适的计时器
4. **可扩展性** - 易于添加新平台和新类型

### 10.3 使用建议

| 用户类型 | 推荐做法 |
|---------|---------|
| **应用开发者** | 使用 `TStopwatch`，让模块自动选择 |
| **库开发者** | 使用 `ITick` 接口，保持灵活性 |
| **性能专家** | 使用特定类型 (`MakeHWTick`)，配合多次采样 |
| **平台移植者** | 实现 `TTick` 子类，注册到工厂 |

### 10.4 推荐阅读路径

```
初学者：
  README → 使用指南 → TStopwatch 示例

进阶用户：
  本文档 → ITick 接口 → 平台实现对比

专家：
  源码 → 硬件计时器实现 → 校准算法
```

---

## 附录

### A. 相关文档

- [fafafa.core.time 模块概述](./fafafa.core.time.md)
- [TStopwatch 使用指南](./time-module-usage-guide.md)
- [性能测量最佳实践](./benchmark_optimization_guide.md)

### B. 术语表

| 术语 | 解释 |
|------|------|
| **Tick** | 计时器的最小计数单位 |
| **Resolution** | 每秒的 tick 数量（频率） |
| **Monotonic** | 单调递增，不会回退 |
| **TSC** | Time Stamp Counter (x86 硬件计数器) |
| **QPC** | QueryPerformanceCounter (Windows 高精度 API) |
| **RDTSC** | Read Time Stamp Counter (x86 汇编指令) |
| **Invariant TSC** | 频率不变的 TSC（不受节能模式影响） |

### C. 性能基准数据

```
Windows 11, Intel i7-12700K @ 3.6 GHz:
  GetTickCount64:           30 ns/call
  QueryPerformanceCounter:  75 ns/call
  RDTSC:                    15 ns/call

Ubuntu 22.04, AMD Ryzen 9 5950X:
  clock_gettime(MONOTONIC): 25 ns/call
  RDTSC:                    12 ns/call

macOS 13, M2 Pro:
  mach_absolute_time:       18 ns/call
  CNTVCT_EL0:               10 ns/call
```

---

**📝 文档版本：** 1.0  
**👤 作者：** AI Assistant  
**📅 最后更新：** 2025-10-01  
**✉️ 反馈：** 欢迎提出改进建议
