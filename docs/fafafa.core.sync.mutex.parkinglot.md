# fafafa.core.sync.mutex.parkinglot

高性能 Parking Lot 互斥锁 - 基于 Rust parking_lot 设计。

## 概述

`fafafa.core.sync.mutex.parkinglot` 模块提供了一个高性能的互斥锁实现，借鉴了 Rust `parking_lot` crate 的设计理念。通过结合原子操作、智能自旋和系统级等待的混合策略，在各种竞争场景下都能提供优秀的性能。

## 特性

- **低延迟**: 低竞争场景下接近自旋锁性能
- **智能自旋**: 中等竞争时通过智能自旋减少上下文切换
- **系统等待**: 高竞争时使用系统等待机制避免 CPU 浪费
- **公平性控制**: 支持公平和非公平两种释放模式
- **跨平台**: Windows 使用 WaitOnAddress，Unix 使用 futex

## 安装

```pascal
uses
  fafafa.core.sync.mutex.parkinglot;
```

## API 参考

### IParkingLotMutex 接口

```pascal
type
  IParkingLotMutex = interface
    // 获取锁（阻塞）
    procedure Acquire;

    // 尝试获取锁（非阻塞）
    function TryAcquire: Boolean;

    // 尝试获取锁（带超时）
    function TryAcquire(ATimeoutMs: Cardinal): Boolean;

    // 释放锁（非公平模式）
    procedure Release;

    // 释放锁（公平模式，唤醒等待最久的线程）
    procedure ReleaseFair;

    // 获取自旋等待次数
    function GetSpinCount: Cardinal;

    // 设置自旋等待次数
    procedure SetSpinCount(ACount: Cardinal);

    // 获取等待队列中的线程数
    function GetWaiterCount: Cardinal;

    // 检查锁是否被持有
    function IsLocked: Boolean;

    // 检查是否由当前线程持有
    function IsOwnedByCurrentThread: Boolean;
  end;
```

### 工厂函数

```pascal
function MakeParkingLotMutex: IParkingLotMutex;
```

## 使用示例

### 基本用法

```pascal
var
  Mutex: IParkingLotMutex;
begin
  Mutex := MakeParkingLotMutex;

  Mutex.Acquire;
  try
    // 临界区代码
    DoSomething();
  finally
    Mutex.Release;
  end;
end;
```

### 带超时的锁获取

```pascal
var
  Mutex: IParkingLotMutex;
begin
  Mutex := MakeParkingLotMutex;

  if Mutex.TryAcquire(1000) then  // 1秒超时
  try
    ProcessData();
  finally
    Mutex.Release;
  end
  else
    HandleTimeout();
end;
```

### 公平释放模式

```pascal
// 公平模式确保等待最久的线程优先获得锁
Mutex.Acquire;
try
  ProcessItem();
finally
  Mutex.ReleaseFair;  // 使用公平释放
end;
```

### 调整自旋参数

```pascal
Mutex := MakeParkingLotMutex;
Mutex.SetSpinCount(100);  // 设置自旋 100 次后进入等待

// 适用于竞争激烈但临界区很短的场景
```

## 性能特点

| 场景 | 行为 | 性能特点 |
|------|------|----------|
| 低竞争 | 原子 CAS 操作 | ~50ns 锁获取 |
| 中等竞争 | 智能自旋 | 减少 90% 上下文切换 |
| 高竞争 | 系统等待 | 接近 OS 原生 mutex |

## 平台实现

### Windows

- 使用 `WaitOnAddress` / `WakeByAddressSingle` API
- 要求 Windows 8 或更高版本

### Unix/Linux

- 优先使用 `futex` 系统调用
- 回退到智能自旋 + `sched_yield`

## 与标准 Mutex 对比

| 特性 | IParkingLotMutex | IMutex |
|------|------------------|--------|
| 低竞争性能 | ★★★★★ | ★★★☆☆ |
| 高竞争性能 | ★★★★☆ | ★★★★☆ |
| 内存占用 | 4-8 字节 | 40-64 字节 |
| 公平性控制 | ✅ | ❌ |
| 递归锁定 | ❌ | 可选 |

## 注意事项

1. **不可重入**: ParkingLot 锁不支持递归锁定，同一线程重复获取会导致死锁
2. **Release 匹配**: 确保每个 `Acquire` 都有对应的 `Release`
3. **超时精度**: 超时时间受系统调度影响，实际等待可能略长

## 已知问题

- 与 FPC 匿名线程 (`TThread.CreateAnonymousThread`) 结合使用时可能出现问题，建议使用继承式线程类

## 相关模块

- `fafafa.core.sync.mutex` - 标准互斥锁
- `fafafa.core.sync.spin` - 纯自旋锁
- `fafafa.core.sync.rwlock` - 读写锁

## 版本历史

- v1.0.0 (2025-12): 初始版本
