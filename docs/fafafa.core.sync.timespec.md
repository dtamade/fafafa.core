# fafafa.core.sync.timespec

Unix 时间规范工具 - TTimeSpec 超时转换函数。

## 概述

`fafafa.core.sync.timespec` 模块提供了 Unix 平台上 TTimeSpec 相关的工具函数，用于处理同步原语的超时逻辑。它消除了各命名同步原语中重复的时间转换代码。

> **注意**: 此模块仅在 Unix/Linux/macOS 平台上可用。

## 安装

```pascal
uses
  fafafa.core.sync.timespec;
```

## API 参考

### 常量

```pascal
const
  CLOCK_REALTIME  = 0;   // 系统实时时钟（可被调整）
  CLOCK_MONOTONIC = 1;   // 单调时钟（不可被调整）
```

### 函数

```pascal
// 将毫秒超时转换为绝对 TTimeSpec（基于 CLOCK_REALTIME）
function TimeoutToTimespec(ATimeoutMs: Cardinal): TTimeSpec;

// 将毫秒超时转换为绝对 TTimeSpec（基于 CLOCK_MONOTONIC）
function TimeoutToMonotonicTimespec(ATimeoutMs: Cardinal): TTimeSpec;

// 将毫秒转换为相对 TTimeSpec（不获取当前时间）
function MillisecondsToTimespec(ATimeoutMs: Cardinal): TTimeSpec;

// 规范化 TTimeSpec（处理纳秒溢出）
procedure NormalizeTimespec(var ATimespec: TTimeSpec);
```

## 使用示例

### 绝对超时（条件变量等待）

```pascal
var
  Timeout: TTimeSpec;
  Result: Integer;
begin
  // 基于 CLOCK_MONOTONIC 的 1000ms 超时
  Timeout := TimeoutToMonotonicTimespec(1000);

  // 用于 pthread_cond_timedwait
  Result := pthread_cond_timedwait(@Cond, @Mutex, @Timeout);

  if Result = ETIMEDOUT then
    WriteLn('条件变量等待超时');
end;
```

### 相对超时（信号量等待）

```pascal
var
  Timeout: TTimeSpec;
begin
  // 500ms 相对超时
  Timeout := MillisecondsToTimespec(500);

  // 用于 sem_timedwait（某些平台需要绝对时间）
end;
```

### CLOCK_REALTIME vs CLOCK_MONOTONIC

```pascal
// CLOCK_REALTIME - 可能受系统时间调整影响
// 适用于：需要与挂钟时间对齐的场景
Timeout := TimeoutToTimespec(5000);

// CLOCK_MONOTONIC - 不受系统时间调整影响（推荐）
// 适用于：超时等待、间隔测量
Timeout := TimeoutToMonotonicTimespec(5000);
```

### 规范化时间

```pascal
var
  Ts: TTimeSpec;
begin
  Ts.tv_sec := 10;
  Ts.tv_nsec := 2500000000;  // 2.5 秒（溢出！）

  NormalizeTimespec(Ts);

  // 现在: tv_sec = 12, tv_nsec = 500000000 (0.5 秒)
end;
```

## 时间转换公式

```
毫秒 -> 秒:       tv_sec  = ATimeoutMs div 1000
毫秒 -> 纳秒:     tv_nsec = (ATimeoutMs mod 1000) * 1_000_000

规范化:
  while tv_nsec >= 1_000_000_000 do begin
    Inc(tv_sec);
    Dec(tv_nsec, 1_000_000_000);
  end;
```

## 常见陷阱

### 1. 使用错误的时钟源

```pascal
// ❌ 错误：CLOCK_REALTIME 受系统时间调整影响
// 如果管理员调整系统时间，超时可能变得不准确
Timeout := TimeoutToTimespec(5000);

// ✅ 正确：使用 CLOCK_MONOTONIC
Timeout := TimeoutToMonotonicTimespec(5000);
```

### 2. 纳秒溢出

```pascal
// ❌ 错误：直接加纳秒可能溢出
Ts.tv_nsec := Ts.tv_nsec + 2_000_000_000;

// ✅ 正确：加后规范化
Ts.tv_nsec := Ts.tv_nsec + 2_000_000_000;
NormalizeTimespec(Ts);
```

### 3. 相对时间 vs 绝对时间

```pascal
// 某些 API（如 pthread_cond_timedwait）需要绝对时间
// 而其他 API 需要相对时间

// 检查 API 文档！
```

## 平台兼容性

| 平台 | 支持 | 备注 |
|------|------|------|
| Linux | ✅ | 完全支持 |
| macOS | ✅ | 完全支持 |
| FreeBSD | ✅ | 完全支持 |
| Windows | ❌ | 不可用（Windows 不使用 TTimeSpec）|

## 依赖

- `Unix` 单元
- `librt` 库（通过 `{$LINKLIB rt}` 链接）

## 相关模块

- `fafafa.core.sync.condvar.unix` - 使用此模块的条件变量
- `fafafa.core.sync.sem.unix` - 使用此模块的信号量
- `fafafa.core.sync.namedCondvar.unix` - 使用此模块的命名条件变量

## 版本历史

- v1.0.0 (2025-12): 初始版本，提供时间转换工具函数
