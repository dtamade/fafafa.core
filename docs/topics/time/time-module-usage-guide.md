# fafafa.core.time 模块使用指南

## 📚 目录
- [概述](#概述)
- [核心概念](#核心概念)
- [快速开始](#快速开始)
- [安全特性](#安全特性)
- [最佳实践](#最佳实践)
- [常见问题](#常见问题)
- [API 参考](#api-参考)

## 概述

`fafafa.core.time` 模块提供了一套完整、安全、高性能的时间处理工具，受 Rust 时间库设计启发，但保持了 Pascal 的编程习惯。

### 主要特性
- ✅ **类型安全**：强类型的时间点（Instant）和持续时间（Duration）
- ✅ **错误处理**：提供 Try 模式和 Result 模式的错误处理
- ✅ **溢出保护**：安全的算术运算，防止整数溢出
- ✅ **高精度**：纳秒级精度的时间测量
- ✅ **跨平台**：支持 Windows、Linux、macOS
- ✅ **监控友好**：内置统计和错误追踪功能

## 核心概念

### 1. TInstant - 时间点
表示单调递增的时间点，不受系统时间调整影响。

```pascal
var
  start, finish: TInstant;
  elapsed: TDuration;
begin
  start := NowInstant;
  DoSomeWork;
  finish := NowInstant;
  elapsed := finish.Diff(start);
  WriteLn('耗时: ', elapsed.AsMs, ' ms');
end;
```

### 2. TDuration - 持续时间
表示两个时间点之间的时间间隔。

```pascal
var
  timeout: TDuration;
begin
  timeout := TDuration.FromSeconds(30);
  // 或者使用其他单位
  timeout := TDuration.FromMs(30000);
  timeout := TDuration.FromUs(30000000);
  timeout := TDuration.FromNs(30000000000);
end;
```

### 3. 时钟接口
- `IMonotonicClock`: 单调时钟，用于测量时间间隔
- `ISystemClock`: 系统时钟，提供真实世界时间
- `IClock`: 综合时钟，包含两者功能

## 快速开始

### 基本使用

```pascal
uses
  fafafa.core.time.base,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.time.clock;

procedure BasicTimeOperations;
var
  clock: IClock;
  start: TInstant;
  duration: TDuration;
begin
  // 创建默认时钟
  clock := DefaultClock;
  
  // 获取当前时间点
  start := clock.NowInstant;
  
  // 等待一段时间
  clock.SleepFor(TDuration.FromMs(100));
  
  // 计算耗时
  duration := clock.NowInstant.Diff(start);
  WriteLn('睡眠时间: ', duration.AsMs, ' ms');
  
  // 获取系统时间
  WriteLn('UTC时间: ', DateTimeToStr(clock.NowUTC));
  WriteLn('本地时间: ', DateTimeToStr(clock.NowLocal));
end;
```

### 使用安全接口

```pascal
uses
  fafafa.core.time.clock.safe,
  fafafa.core.time.result;

procedure SafeTimeOperations;
var
  safeClock: IMonotonicClockSafe;
  instant: TInstant;
  instantResult: TInstantResult;
begin
  safeClock := CreateMonotonicClockSafe(nil);
  
  // Try 模式 - 简单错误检查
  if safeClock.TryNowInstant(instant) then
    WriteLn('时间: ', instant.AsNsSinceEpoch)
  else
    WriteLn('获取时间失败');
  
  // Result 模式 - 详细错误信息
  instantResult := safeClock.NowInstantResult;
  if instantResult.IsOk then
    WriteLn('时间: ', instantResult.Value.AsNsSinceEpoch)
  else
    WriteLn('错误: ', instantResult.Error.Message);
end;
```

## 安全特性

### 1. 溢出保护的算术运算

```pascal
uses
  fafafa.core.time.duration.safe;

procedure SafeArithmetic;
var
  d1, d2: TDuration;
  result: TDurationResult;
begin
  d1 := TDuration.FromSeconds(1000);
  d2 := TDuration.FromSeconds(2000);
  
  // 检查加法
  result := d1.CheckedAdd(d2);
  if result.IsOk then
    WriteLn('和: ', result.Value.AsSeconds, ' 秒')
  else
    WriteLn('加法溢出！');
  
  // 饱和加法（不会溢出）
  var saturated := d1.SaturatingAdd(TDuration.MaxValue);
  WriteLn('饱和结果: ', saturated.AsSeconds, ' 秒');
  
  // 包装加法（溢出后环绕）
  var wrapped := d1.WrappingAdd(d2);
  WriteLn('包装结果: ', wrapped.AsSeconds, ' 秒');
end;
```

### 2. 错误统计和监控

```pascal
procedure MonitoringExample;
var
  safeClock: IMonotonicClockSafe;
  stats: TClockErrorStats;
  i: Integer;
  instant: TInstant;
begin
  safeClock := CreateMonotonicClockSafe(nil);
  
  // 执行一批操作
  for i := 1 to 1000 do
    safeClock.TryNowInstant(instant);
  
  // 获取统计信息
  stats := safeClock.GetErrorStats;
  WriteLn('总操作: ', stats.TotalOperations);
  WriteLn('成功: ', stats.SuccessfulOperations);
  WriteLn('失败: ', stats.FailedOperations);
  
  if stats.FailedOperations > 0 then
  begin
    WriteLn('成功率: ', 
      (stats.SuccessfulOperations / stats.TotalOperations) * 100:0:2, '%');
    WriteLn('最后错误: ', stats.LastError.Message);
  end;
end;
```

### 3. 重试机制

```pascal
function GetTimeWithRetry(Clock: IMonotonicClockSafe; 
  MaxRetries: Integer): TInstant;
var
  i: Integer;
  instant: TInstant;
begin
  for i := 1 to MaxRetries do
  begin
    if Clock.TryNowInstant(instant) then
      Exit(instant);
    
    if i < MaxRetries then
      Sleep(10 * i); // 指数退避
  end;
  
  raise Exception.Create('获取时间失败');
end;
```

## 最佳实践

### 1. 选择合适的时钟

```pascal
// ✅ 测量时间间隔 - 使用单调时钟
var monoClok := CreateMonotonicClock;
var start := monoClock.NowInstant;

// ✅ 记录日志时间戳 - 使用系统时钟
var sysClock := CreateSystemClock;
WriteLn('[', DateTimeToStr(sysClock.NowLocal), '] 事件发生');

// ✅ 同时需要两者 - 使用综合时钟
var clock := CreateClock;
```

### 2. 处理时间运算

```pascal
// ✅ 使用类型安全的方法
var timeout := TDuration.FromSeconds(30);
var deadline := NowInstant.Add(timeout);

// ❌ 避免直接操作纳秒值
var ns := NowInstant.AsNsSinceEpoch;
ns := ns + 30000000000; // 容易出错！
```

### 3. 错误处理策略

```pascal
// 关键操作 - 使用 Result 模式并记录详细错误
var result := safeClock.NowInstantResult;
if not result.IsOk then
begin
  LogError('时钟错误: ' + result.Error.Message);
  // 采取恢复措施
end;

// 非关键操作 - 使用 Try 模式快速检查
var instant: TInstant;
if not safeClock.TryNowInstant(instant) then
  instant := TInstant.Zero; // 使用默认值
```

### 4. 性能考虑

```pascal
// ✅ 缓存时钟实例
type
  TMyService = class
  private
    FClock: IMonotonicClock;
  public
    constructor Create;
  end;

constructor TMyService.Create;
begin
  FClock := CreateMonotonicClock; // 创建一次，多次使用
end;

// ❌ 避免频繁创建
procedure BadExample;
begin
  for i := 1 to 1000 do
  begin
    var clock := CreateMonotonicClock; // 每次都创建新实例！
    // ...
  end;
end;
```

## 常见问题

### Q1: 什么时候使用 MonotonicClock vs SystemClock？

**MonotonicClock 适用于：**
- 测量时间间隔
- 超时检测
- 性能测量
- 动画和游戏循环

**SystemClock 适用于：**
- 显示当前时间
- 日志时间戳
- 调度任务
- 与外部系统同步

### Q2: 如何处理时间溢出？

使用安全的算术运算方法：

```pascal
// 使用 Checked 方法检测溢出
var result := duration1.CheckedAdd(duration2);
if not result.IsOk then
  HandleOverflow;

// 使用 Saturating 方法避免溢出
var safe := duration1.SaturatingAdd(duration2);

// 使用 Wrapping 方法允许环绕
var wrapped := duration1.WrappingAdd(duration2);
```

### Q3: 如何实现超时机制？

```pascal
function DoWorkWithTimeout(Timeout: TDuration): Boolean;
var
  clock: IMonotonicClock;
  deadline: TInstant;
begin
  clock := CreateMonotonicClock;
  deadline := clock.NowInstant.Add(Timeout);
  
  while not WorkComplete do
  begin
    if clock.NowInstant.Compare(deadline) >= 0 then
      Exit(False); // 超时
    
    ProcessNextItem;
  end;
  
  Result := True;
end;
```

### Q4: 如何测量代码性能？

```pascal
uses
  fafafa.core.time.clock;

// 方法1：使用便捷函数
var duration := TimeIt(
  procedure
  begin
    // 要测量的代码
    DoComplexCalculation;
  end
);
WriteLn('耗时: ', duration.AsMs, ' ms');

// 方法2：手动测量
var
  start, finish: TInstant;
  elapsed: TDuration;
begin
  start := NowInstant;
  DoComplexCalculation;
  finish := NowInstant;
  elapsed := finish.Diff(start);
  WriteLn('耗时: ', elapsed.AsMs, ' ms');
end;
```

### Q5: 如何处理不同时区？

```pascal
var
  sysClock: ISystemClock;
  utcTime, localTime: TDateTime;
  offset: TDuration;
begin
  sysClock := CreateSystemClock;
  
  utcTime := sysClock.NowUTC;
  localTime := sysClock.NowLocal;
  offset := sysClock.GetTimeZoneOffset;
  
  WriteLn('UTC: ', DateTimeToStr(utcTime));
  WriteLn('Local: ', DateTimeToStr(localTime));
  WriteLn('时区偏移: ', offset.AsHours, ' 小时');
end;
```

## API 参考

### Duration 创建方法
- `TDuration.Zero`: 零持续时间
- `TDuration.FromNs(ns: Int64)`: 从纳秒创建
- `TDuration.FromUs(us: Int64)`: 从微秒创建
- `TDuration.FromMs(ms: Int64)`: 从毫秒创建
- `TDuration.FromSeconds(s: Int64)`: 从秒创建
- `TDuration.FromMinutes(m: Int64)`: 从分钟创建
- `TDuration.FromHours(h: Int64)`: 从小时创建

### Duration 转换方法
- `AsNs`: 转换为纳秒
- `AsUs`: 转换为微秒
- `AsMs`: 转换为毫秒
- `AsSeconds`: 转换为秒
- `AsMinutes`: 转换为分钟
- `AsHours`: 转换为小时

### Duration 安全运算
- `CheckedAdd/Sub/Mul/Div`: 检查溢出的运算
- `SaturatingAdd/Sub/Mul`: 饱和运算（达到极值时停止）
- `WrappingAdd/Sub/Mul`: 环绕运算（溢出后从另一端继续）

### Instant 方法
- `NowInstant`: 获取当前时间点
- `Add(d: TDuration)`: 添加持续时间
- `Sub(d: TDuration)`: 减去持续时间
- `Diff(other: TInstant)`: 计算两个时间点的差值
- `Compare(other: TInstant)`: 比较两个时间点

### 安全时钟接口
- `TryNowInstant`: Try 模式获取时间
- `NowInstantResult`: Result 模式获取时间
- `GetErrorStats`: 获取错误统计
- `ResetErrorStats`: 重置错误统计
- `HasError`: 检查是否有错误发生

## 迁移指南

### 从标准 Pascal 时间函数迁移

```pascal
// 旧代码
var
  startTick: QWord;
begin
  startTick := GetTickCount64;
  DoWork;
  WriteLn('耗时: ', GetTickCount64 - startTick, ' ms');
end;

// 新代码
var
  start: TInstant;
begin
  start := NowInstant;
  DoWork;
  WriteLn('耗时: ', NowInstant.Diff(start).AsMs, ' ms');
end;
```

### 从 Now/Date/Time 迁移

```pascal
// 旧代码
var
  startTime: TDateTime;
begin
  startTime := Now;
  DoWork;
  WriteLn('耗时: ', MilliSecondsBetween(Now, startTime), ' ms');
end;

// 新代码
var
  clock: IClock;
  start: TInstant;
begin
  clock := DefaultClock;
  start := clock.NowInstant;
  DoWork;
  WriteLn('耗时: ', clock.NowInstant.Diff(start).AsMs, ' ms');
end;
```

## 性能提示

1. **缓存时钟实例**：避免重复创建时钟对象
2. **使用合适的精度**：不是所有场景都需要纳秒精度
3. **批量操作**：减少系统调用次数
4. **避免频繁转换**：在同一单位内进行计算

## 故障排除

### 问题：时间测量不准确
- 确保使用 MonotonicClock 而不是 SystemClock
- 检查系统时钟分辨率（使用 `GetResolution`）
- 考虑系统负载和调度延迟

### 问题：算术运算溢出
- 使用 Checked 系列方法检测溢出
- 使用 Saturating 系列方法避免溢出
- 考虑使用更小的时间单位

### 问题：跨平台兼容性
- 使用抽象接口而不是平台特定实现
- 测试目标平台的时钟分辨率
- 处理平台特定的错误情况

## 总结

`fafafa.core.time` 模块提供了一套强大、安全、易用的时间处理工具。通过：

- ✅ 类型安全的 API 设计
- ✅ 完善的错误处理机制
- ✅ 丰富的安全运算方法
- ✅ 内置的监控和统计功能

您可以构建更可靠、更易维护的时间相关功能。遵循本指南中的最佳实践，可以避免常见的时间处理陷阱，提高代码质量。

## 相关资源

- [API 文档](./api-reference.md)
- [示例代码](../examples/)
- [单元测试](../tests/)
- [性能基准测试](../benchmarks/)