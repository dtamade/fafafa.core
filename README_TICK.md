# fafafa.core.time.tick - 高精度时间测量模块

## 📖 概述

`fafafa.core.time.tick` 是一个跨平台的高精度时间测量模块，提供纳秒级精度的时间测量能力。支持多种时钟源，包括硬件 TSC (Time Stamp Counter)、操作系统高精度计时器等。

## 🔧 特性

### 跨平台支持
- **Windows**: QueryPerformanceCounter, TSC
- **macOS**: mach_absolute_time, TSC  
- **Linux**: clock_gettime(CLOCK_MONOTONIC), TSC
- **其他 Unix**: gettimeofday, TSC

### 多种时钟源
- **ttBest**: 自动选择最佳可用时钟源
- **ttHighPrecision**: 平台高精度时钟
- **ttTSC**: 硬件 TSC 计时器（如果可用）
- **ttStandard**: 标准精度时钟
- **ttSystem**: 系统默认时钟

### 硬件 TSC 支持
- **x86/x64**: RDTSC/RDTSCP 指令
- **ARM64**: CNTVCT_EL0 系统寄存器
- **自动检测**: Invariant TSC 支持
- **频率校准**: 自动校准 TSC 频率

## 🚀 快速开始

### 基本使用

```pascal
program demo_tick_basic;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.time.tick,
  fafafa.core.time.duration;

var
  tick: ITick;
  start, elapsed: QWord;
  duration: TDuration;
begin
  // 创建最佳时钟源
  tick := CreateTick(ttBest);

  // 测量代码执行时间
  start := tick.GetCurrentTick;
  // ... 执行代码 ...
  elapsed := tick.GetElapsedTicks(start);
  duration := tick.TicksToDuration(elapsed);

  WriteLn('执行时间: ', duration.AsMs, ' 毫秒');
end.
```

### 便捷函数

```pascal
var
  tick: ITick;
  duration: TDuration;
begin
  // 使用便捷的全局函数
  tick := DefaultTick;        // 等同于 CreateTick(ttBest)
  tick := HighPrecisionTick;  // 等同于 CreateTick(ttHighPrecision)
  tick := SystemTick;         // 等同于 CreateTick(ttSystem)

  // 快速测量函数
  duration := QuickMeasure(
    procedure
    begin
      // 要测量的代码
    end
  );
end;
```

### 检测可用性

```pascal
var
  types: TTickTypeArray;
  i: Integer;
begin
  // 检测特定时钟源是否可用
  if IsTickTypeAvailable(ttTSC) then
    WriteLn('TSC 硬件计时器可用');

  // 获取所有可用的时钟源
  types := GetAvailableTickTypes;
  for i := 0 to High(types) do
    WriteLn(GetTickTypeName(types[i]));
end;
```

## 📊 性能特性

### 精度对比

| 时钟源 | 精度 | 单调性 | 开销 | 平台 |
|--------|------|--------|------|------|
| TSC | 纳秒级 | ✓ | 极低 | x86/ARM64 |
| QueryPerformanceCounter | 纳秒级 | ✓ | 低 | Windows |
| mach_absolute_time | 纳秒级 | ✓ | 低 | macOS |
| clock_gettime | 纳秒级 | ✓ | 中 | Linux |
| gettimeofday | 微秒级 | ✗ | 中 | Unix |

### 选择策略

`ttBest` 的选择优先级：
1. **TSC** (如果可用且稳定)
2. **平台高精度时钟**
3. **标准时钟**

## 🏗️ 架构设计

### 模块结构

```
fafafa.core.time.tick.pas           # 门面模块
├── fafafa.core.time.tick.base.pas  # 基础定义
├── fafafa.core.time.tick.windows.pas # Windows 实现
├── fafafa.core.time.tick.unix.pas    # Unix 实现
└── fafafa.core.time.tick.tsc.*      # TSC 硬件实现
    ├── base.pas                     # TSC 基础
    ├── x86.pas                      # x86/x64 TSC
    └── aarch64.pas                  # ARM64 TSC
```

### 设计原则

- **模块化**: 清晰的职责分离
- **跨平台**: 统一的接口，平台特定实现
- **高性能**: 最小化测量开销
- **易用性**: 简洁的 API 设计

## 🧪 测试

### 运行测试

```bash
# Windows (使用 Lazarus 的 lazbuild)
cd tests/fafafa.core.time.tick
buildOrTest.bat

# 也可以在 IDE 中打开 tests/fafafa.core.time.tick/fafafa.core.time.tick.test.lpi 并运行
```

### 测试内容

- 各种时钟源可用性检测
- 时间测量精度验证
- TSC 硬件计时器测试
- 跨平台兼容性验证

## 📝 API 参考

### 主要类型

```pascal
type
  TTickType = (ttBest, ttStandard, ttHighPrecision, ttTSC, ttSystem);
  ITick = interface
    function GetCurrentTick: UInt64;
    function GetElapsedTicks(const AStartTick: UInt64): UInt64;
    function TicksToDuration(const ATicks: UInt64): TDuration;
    function DurationToTicks(const D: TDuration): UInt64;
    // ... 其他方法
  end;
```

### 主要函数

```pascal
// 工厂函数
function CreateTick(const AType: TTickType = ttBest): ITick;

// 检测函数
function IsTickTypeAvailable(const AType: TTickType): Boolean;
function GetTickTypeName(const AType: TTickType): string;
function GetAvailableTickTypes: TTickTypeArray;

// 便捷函数
function DefaultTick: ITick;
function HighPrecisionTick: ITick;
function SystemTick: ITick;
function QuickMeasure(const AProc: TProc): TDuration;
```

## ⚠️ 注意事项

### TSC 使用注意

- TSC 需要 Invariant TSC 支持才能保证准确性
- 在虚拟化环境中可能不稳定
- 需要校准 TSC 频率

### 平台差异

- Windows: 推荐使用 QueryPerformanceCounter
- macOS: 推荐使用 mach_absolute_time
- Linux: 推荐使用 clock_gettime(CLOCK_MONOTONIC)

### 性能考虑

- TSC 开销最低，但可用性有限
- 高精度时钟开销较低，兼容性好
- 避免在紧密循环中频繁调用

## 📜 许可证

转发或用于个人/商业项目时，请保留本项目的版权声明。

## 👤 作者

- **author**: fafafaStudio
- **Email**: dtamade@gmail.com
- **QQGroup**: 685403987
- **QQ**: 179033731
