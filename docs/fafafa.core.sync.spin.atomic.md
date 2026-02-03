# fafafa.core.sync.spin.atomic

原子操作自旋锁实现 - 基于 CAS 的高性能跨平台自旋锁。

## 概述

`fafafa.core.sync.spin.atomic` 模块提供了基于原子操作的自旋锁实现。它是一个通用的跨平台解决方案，使用 Compare-And-Swap (CAS) 原子指令实现锁定机制。

## 特性

- **跨平台**: Windows、Linux、macOS、FreeBSD 等均支持
- **原子操作优化**: 使用 InterlockedXxx/GCC Builtin 原子指令
- **自适应退避**: 智能退避策略减少 CPU 占用
- **超时支持**: 可配置的获取超时机制
- **RAII 支持**: 自动锁管理和异常安全
- **无锁设计**: 基于 CAS (Compare-And-Swap) 操作

## 安装

```pascal
uses
  fafafa.core.sync.spin.atomic;
```

## API 参考

### TSpin 类

```pascal
type
  TSpin = class(TTryLock, ISpin)
  public
    constructor Create;

    // 获取锁（阻塞）
    procedure Acquire; override;

    // 释放锁
    procedure Release; override;

    // 非阻塞尝试获取锁
    function TryAcquire: Boolean; override;

    // 带超时尝试获取锁
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; override;

    // 检查锁是否被持有
    function IsLocked: Boolean;

  protected
    // 可重写的自旋参数
    function GetDefaultTightSpin: UInt32; override;
    function GetDefaultBackOffSpin: UInt32; override;
    function GetDefaultBlockSleepIntervalMs: UInt32; override;
  end;
```

## 使用示例

### 基本用法

```pascal
var
  Lock: TSpin;
begin
  Lock := TSpin.Create;
  try
    Lock.Acquire;
    try
      // 临界区代码
      DoSomething();
    finally
      Lock.Release;
    end;
  finally
    Lock.Free;
  end;
end;
```

### 非阻塞尝试

```pascal
var
  Lock: TSpin;
begin
  Lock := TSpin.Create;
  try
    if Lock.TryAcquire then
    try
      ProcessItem();
    finally
      Lock.Release;
    end
    else
      HandleBusy();
  finally
    Lock.Free;
  end;
end;
```

### 带超时的获取

```pascal
var
  Lock: TSpin;
begin
  Lock := TSpin.Create;
  try
    if Lock.TryAcquire(100) then  // 100ms 超时
    try
      CriticalOperation();
    finally
      Lock.Release;
    end
    else
      WriteLn('获取锁超时');
  finally
    Lock.Free;
  end;
end;
```

## 自旋策略

自旋锁使用三阶段退避策略：

1. **紧密自旋 (Tight Spin)**: 纯 CPU 循环，无任何系统调用
2. **退避自旋 (Back-off Spin)**: 使用 `PAUSE` 指令或 `sched_yield`
3. **睡眠等待 (Block Sleep)**: 短暂睡眠后重试

```
+-------------------+     +------------------+     +---------------+
|   Tight Spin      | --> |  Back-off Spin   | --> |  Block Sleep  |
| (CPU spinning)    |     | (yield/pause)    |     | (Sleep(1ms))  |
+-------------------+     +------------------+     +---------------+
```

## 性能特点

| 场景 | 性能 | 适用性 |
|------|------|--------|
| 极短临界区 | ★★★★★ | 最佳选择 |
| 短临界区 | ★★★★☆ | 适用 |
| 中等临界区 | ★★☆☆☆ | 不推荐 |
| 长临界区 | ★☆☆☆☆ | 请使用 Mutex |

## 注意事项

1. **短时间持锁**: 自旋锁只适合非常短的临界区（< 100 CPU 周期）
2. **CPU 占用**: 长时间自旋会消耗大量 CPU 资源
3. **不可重入**: 同一线程重复获取会导致死锁
4. **不要在自旋区内调用可能阻塞的操作**

## 何时使用自旋锁

✅ **适用场景**:
- 临界区极短（几条指令）
- 锁竞争较低
- 对延迟要求极高
- 实时系统

❌ **不适用场景**:
- 临界区包含 I/O 操作
- 临界区包含内存分配
- 高竞争场景
- 需要公平性保证

## 与其他锁对比

| 特性 | TSpin | IMutex | IParkingLotMutex |
|------|-------|--------|------------------|
| 低竞争延迟 | ★★★★★ | ★★★☆☆ | ★★★★☆ |
| 高竞争延迟 | ★☆☆☆☆ | ★★★★☆ | ★★★★☆ |
| CPU 效率 | ★★☆☆☆ | ★★★★★ | ★★★★☆ |
| 内存占用 | ★★★★★ | ★★★☆☆ | ★★★★☆ |

## 相关模块

- `fafafa.core.sync.spin` - 平台特定自旋锁
- `fafafa.core.sync.mutex` - 操作系统互斥锁
- `fafafa.core.sync.mutex.parkinglot` - 混合策略锁

## 版本历史

- v1.0.0 (2025-12): 初始版本
