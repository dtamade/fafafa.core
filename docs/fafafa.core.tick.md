# fafafa.core.tick 模块文档（已切换到记录式 TTick）

本模块已统一切换为记录式 API（TTick）。历史上的 ITick/ITickProvider/ProviderType 等接口与工厂方法均已废弃并从代码中移除。请使用记录式 TTick 进行时间测量。

## 快速上手（推荐）

```pascal
uses
  fafafa.core.tick;

var
  C: TTick;
  T0, Elapsed: QWord;
begin
  C := BestTick;
  T0 := C.Now;
  // ... workload ...
  Elapsed := C.Elapsed(T0);
  WriteLn('耗时(µs)=', C.TicksToDuration(Elapsed).AsUs:0:2);
end.
```

## 常用 API
- BestTick: TTick
- TTick.From(ttHighPrecision/ttSystem/ttBest/ttStandard/ttTSC[回退])
- Now/Elapsed/TicksToDuration/DurationToTicks
- FrequencyHz/IsMonotonic/MinStep
- QuickMeasure/QuickMeasureClock（匿名过程直接 procedure…end，无需 @）

## 注意事项
- Windows：HighPrecision 使用 QPC；System 使用 GetTickCount64。测试断言采用“下限+裕量”策略，避免调度抖动导致误报。
- TSC：记录式 API 当前统一回退（ttTSC 标记不可用），后续再按方案评估开放。
- 代码页：示例/测试建议开启 {$CODEPAGE UTF8}

## 迁移指引（从 ITick 到 TTick）
- CreateDefaultTick -> BestTick
- CreateTickProvider/GetAvailableProviders -> TTick.From/GetAvailableTickTypes
- ITick.GetCurrentTick/GetResolution/GetElapsedTicks -> TTick.Now/FrequencyHz/Elapsed
- ITick.TicksTo*Seconds/MeasureElapsed -> TTick.TicksToDuration(...).AsNs/AsUs/AsMs

以上映射可直接替换，无需改外部接口文件，仅调整 uses 与调用点。

## 概述

`fafafa.core.tick` 是 fafafa.collections5 框架中的高精度时间测量模块，专为基准测试和性能分析设计。该模块提供纳秒级精度的时间测量能力，支持跨平台兼容，为 `fafafa.core.benchmark` 提供稳定可靠的时间测量基础。

## 模块职责

- **高精度时间测量**：提供纳秒级精度的时间戳获取和测量
- **跨平台兼容**：支持 Windows 和 Linux 平台的高精度计时器
- **多精度级别**：支持标准、高精度和 TSC 硬件计时器三种精度级别
- **基准测试支持**：为性能基准测试提供专业的时间测量工具
- **轻量级设计**：专注于时间测量，最小化测量开销

## 设计理念

### 接口抽象设计

模块采用现代语言框架的设计理念，借鉴了：
- **Rust Tokio**：高性能异步运行时的时间测量设计
- **Java Netty**：网络框架中的精确时间控制
- **Go net**：标准库中的时间处理模式

### 架构特点

1. **接口分离**：`ITick` 和 `ITickProvider` 清晰分离职责
2. **工厂模式**：支持动态选择最佳可用的时间提供者
3. **策略模式**：不同精度级别的时间提供者可互换
4. **内联优化**：关键路径使用内联函数最小化开销

## 接口设计

### 核心接口

#### ITick - 时间测量接口

```pascal
ITick = interface
  ['{B8F5A2E1-4C3D-4F2A-9B1E-8D7C6A5F4E3D}']

  // 基础时间操作
  function GetCurrentTick: UInt64;
  function GetResolution: UInt64;
  function GetElapsedTicks(const AStartTick: UInt64): UInt64;

  // 时间转换
  function TicksToNanoSeconds(const ATicks: UInt64): Double;
  function TicksToMicroSeconds(const ATicks: UInt64): Double;
  function TicksToMilliSeconds(const ATicks: UInt64): Double;

  // 便利方法
  function MeasureElapsed(const AStartTick: UInt64): Double;
end;
```

#### ITickProvider - 时间提供者接口

```pascal
ITickProvider = interface
  ['{C9A6B3F2-5D4E-4A1B-8E2F-7C8B9A6D5E4F}']

  function CreateTick: ITick;
  function GetProviderType: TTickProviderType;
  function GetProviderName: string;
  function IsAvailable: Boolean;
end;
```

### 类型定义

#### TTickProviderType - 提供者类型

```pascal
TTickProviderType = (
  tptStandard,      // 标准精度（毫秒级）
  tptHighPrecision, // 高精度（纳秒级）
  tptTSC            // TSC硬件计时器（纳秒级）
);
```

#### TTickProviderTypeArray - 提供者类型数组

```pascal
TTickProviderTypeArray = array of TTickProviderType;
```

## 公共 API 说明

### 工厂方法

#### CreateTickProvider

```pascal
function CreateTickProvider(const AProviderType: TTickProviderType): ITickProvider;
```

**用途**：创建指定类型的时间提供者
**参数**：
- `AProviderType`: 提供者类型（标准、高精度、TSC）

**返回值**：时间提供者接口实例
**异常**：
- `ETickProviderNotAvailable`: 指定类型的提供者不可用
- `ETickInvalidArgument`: 无效的提供者类型

#### CreateDefaultTick

```pascal
function CreateDefaultTick: ITick;
```

**用途**：创建默认的时间测量实例（自动选择最佳可用提供者）
**返回值**：时间测量接口实例
**异常**：`ETickError`: 没有可用的时间提供者

#### GetAvailableProviders

```pascal
function GetAvailableProviders: TTickProviderTypeArray;
```

**用途**：获取所有可用的时间提供者类型
**返回值**：可用提供者类型的数组

### 异常类型

#### ETickError

```pascal
ETickError = class(ECore) end;
```

时间测量相关错误的基类异常

#### ETickProviderNotAvailable

```pascal
ETickProviderNotAvailable = class(ETickError) end;
```

时间提供者不可用异常

#### ETickInvalidArgument

```pascal
ETickInvalidArgument = class(ETickError) end;
```

时间测量参数无效异常

## 使用示例

### 基本使用

```pascal
var
  LTick: ITick;
  LStartTick: UInt64;
  LElapsedNS: Double;
begin
  // 创建默认时间测量实例
  LTick := CreateDefaultTick;

  // 开始测量
  LStartTick := LTick.GetCurrentTick;

  // 执行需要测量的代码
  DoSomeWork();

  // 获取经过时间（纳秒）
  LElapsedNS := LTick.MeasureElapsed(LStartTick);

  WriteLn('耗时: ', Format('%.2f', [LElapsedNS / 1000]), ' 微秒');
end;
```

### 基准测试场景

```pascal
var
  LTick: ITick;
  LPhaseStart: UInt64;
  LPhase1, LPhase2, LPhase3: Double;
begin
  LTick := CreateDefaultTick;

  // 阶段1：初始化
  LPhaseStart := LTick.GetCurrentTick;
  InitializeData();
  LPhase1 := LTick.MeasureElapsed(LPhaseStart);

  // 阶段2：处理
  LPhaseStart := LTick.GetCurrentTick;
  ProcessData();
  LPhase2 := LTick.MeasureElapsed(LPhaseStart);

  // 阶段3：清理
  LPhaseStart := LTick.GetCurrentTick;
  CleanupData();
  LPhase3 := LTick.MeasureElapsed(LPhaseStart);

  WriteLn('初始化: ', Format('%.2f', [LPhase1 / 1000]), ' μs');
  WriteLn('处理: ', Format('%.2f', [LPhase2 / 1000]), ' μs');
  WriteLn('清理: ', Format('%.2f', [LPhase3 / 1000]), ' μs');
end;
```

### 提供者选择

```pascal
var
  LProviders: TTickProviderTypeArray;
  LProvider: ITickProvider;
  LTick: ITick;
  LI: Integer;
begin
  // 获取所有可用提供者
  LProviders := GetAvailableProviders;

  for LI := 0 to High(LProviders) do
  begin
    LProvider := CreateTickProvider(LProviders[LI]);
    WriteLn('提供者: ', LProvider.GetProviderName);
    WriteLn('分辨率: ', LProvider.CreateTick.GetResolution, ' ticks/秒');
  end;
end;
```

## 平台兼容性

### Windows 平台

- **标准提供者**：使用 `GetTickCount64()` 提供毫秒级精度
- **高精度提供者**：使用 `QueryPerformanceCounter()` 提供纳秒级精度
- **TSC提供者**：使用 RDTSC 指令访问硬件时间戳计数器

### Linux 平台

- **标准提供者**：使用 `GetTickCount64()` 提供毫秒级精度
- **高精度提供者**：使用 `clock_gettime(CLOCK_MONOTONIC)` 提供纳秒级精度
- **TSC提供者**：使用 RDTSC 指令访问硬件时间戳计数器

## 性能特性

### 测量开销

- **标准提供者**：~100 纳秒/次测量
- **高精度提供者**：~50 纳秒/次测量
- **TSC提供者**：~10 纳秒/次测量

### 精度级别

- **标准提供者**：毫秒级（1ms）
- **高精度提供者**：纳秒级（1ns）
- **TSC提供者**：CPU周期级（~0.3ns @ 3GHz）

### 单调性保证

所有提供者都保证时间戳的单调递增特性，适合性能测量和基准测试。

## 模块依赖关系

### 直接依赖

- `fafafa.core.base`: 基础类型和异常定义
- `Classes`: 标准类库
- `SysUtils`: 系统工具

### 平台依赖

- **Windows**: `Windows` 单元（QueryPerformanceCounter）
- **Linux**: `BaseUnix`, `Linux` 单元（clock_gettime）

### 被依赖模块

- `fafafa.core.benchmark`: 基准测试框架
- 其他需要高精度时间测量的模块

## 最佳实践

### 1. 提供者选择

```pascal
// 推荐：使用默认提供者（自动选择最佳）
LTick := CreateDefaultTick;

// 特殊需求：手动选择高精度提供者
try
  LProvider := CreateTickProvider(tptHighPrecision);
  LTick := LProvider.CreateTick;
except
  on ETickProviderNotAvailable do
    LTick := CreateDefaultTick; // 降级到默认提供者
end;
```

### 2. 测量模式

```pascal
// 推荐：使用 MeasureElapsed 简化测量
LStartTick := LTick.GetCurrentTick;
DoWork();
LElapsedNS := LTick.MeasureElapsed(LStartTick);

// 高级：手动计算获得更多控制
LStartTick := LTick.GetCurrentTick;
DoWork();
LElapsedTicks := LTick.GetElapsedTicks(LStartTick);
LElapsedNS := LTick.TicksToNanoSeconds(LElapsedTicks);
```

### 3. 错误处理

```pascal
try
  LTick := CreateDefaultTick;
  // 使用 LTick 进行测量
except
  on E: ETickError do
    WriteLn('时间测量错误: ', E.Message);
end;
```

## 注意事项

1. **TSC 校准**：TSC 提供者需要短暂的校准时间（约10ms）
2. **系统精度限制**：实际精度受操作系统时间调度影响
3. **溢出处理**：模块自动处理时间戳溢出情况
4. **线程安全**：基本读取操作是线程安全的
5. **内存管理**：接口使用引用计数自动管理内存

---

**版本**: 1.0
**最后更新**: 2025年8月6日
**维护者**: fafafaStudio
