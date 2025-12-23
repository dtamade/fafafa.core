# fafafa.core.sync.mutex - 互斥锁模块

## 概述

`fafafa.core.sync.mutex` 模块提供了高性能、跨平台的互斥锁（Mutex）实现，用于线程间的资源同步和保护。

## 核心特性

- **跨平台支持**: Windows（CRITICAL_SECTION/SRWLOCK）、Unix/Linux（pthread/futex）
- **非重入设计**: 防止死锁和逻辑错误
- **异常安全**: RAII 风格的锁保护（通过 Guard 模式）
- **超时支持**: 可配置的获取超时（三段式等待策略）
- **Poison 机制**: Rust 风格的毒化检测
- **高性能**: 使用平台原生 API 优化

## 核心接口

### IMutex - 互斥锁接口

```pascal
IMutex = interface(ITryLock)
  ['{55391DAE-AC96-4911-B998-FC8D2675FA2A}']

  // 基础操作（继承自 ITryLock）
  procedure Acquire;                             // 获取锁（阻塞）
  procedure Release;                             // 释放锁
  function TryAcquire: Boolean;                  // 尝试获取锁（非阻塞）
  function TryAcquire(ATimeoutMs: Cardinal): Boolean;  // 带超时获取

  // 平台句柄
  function GetHandle: Pointer;                   // 返回平台特定句柄

  // Poisoning 支持 (Rust-style)
  function IsPoisoned: Boolean;                  // 检查是否被毒化
  procedure ClearPoison;                         // 清除毒化状态
  procedure MarkPoisoned(const AExceptionMessage: string);  // 标记为毒化
end;
```

### EMutexPoisonError - 毒化异常

```pascal
EMutexPoisonError = class(ELockError)
  property PoisoningThreadId: TThreadID;    // 导致毒化的线程 ID
  property PoisoningException: string;      // 导致毒化的异常信息
end;
```

## 工厂函数

### MakeMutex

```pascal
function MakeMutex: IMutex;
```

创建一个新的互斥锁实例，自动选择平台最优实现：
- **Windows**: 优先使用 SRWLOCK（Vista+），回退到 CRITICAL_SECTION
- **Unix/Linux**: 优先使用 futex（启用 `FAFAFA_CORE_USE_FUTEX`），回退到 pthread_mutex

### MakePthreadMutex（Unix 专用）

```pascal
function MakePthreadMutex: IMutex;  // 仅 Unix
```

创建与 `pthread_cond_*` 兼容的互斥锁。当与条件变量配合使用时，必须使用此函数。

### MakeFutexMutex（Unix 专用）

```pascal
function MakeFutexMutex: IMutex;  // 仅 Unix
```

创建 futex 版本的互斥锁，用于基准测试对比。

## 基础使用

### 手动管理模式

```pascal
uses fafafa.core.sync.mutex;

var
  Mutex: IMutex;
begin
  Mutex := MakeMutex;

  Mutex.Acquire;
  try
    // 临界区代码
  finally
    Mutex.Release;
  end;
end;
```

### 非阻塞尝试

```pascal
var
  Mutex: IMutex;
begin
  Mutex := MakeMutex;

  if Mutex.TryAcquire then
  begin
    try
      // 获取成功，执行临界区代码
    finally
      Mutex.Release;
    end;
  end
  else
    WriteLn('锁被占用');
end;
```

### 带超时获取

```pascal
var
  Mutex: IMutex;
begin
  Mutex := MakeMutex;

  if Mutex.TryAcquire(1000) then  // 最多等待 1 秒
  begin
    try
      // 在超时前获取成功
    finally
      Mutex.Release;
    end;
  end
  else
    WriteLn('获取超时');
end;
```

## 高级特性

### 三段式等待策略

`TryAcquire(ATimeoutMs)` 使用三段式等待策略优化性能：

```
┌─────────────────────────────────────────────────────────────┐
│  Stage 1: Tight Spin (紧密自旋)                              │
│  - 默认 2000 次迭代                                          │
│  - 使用 CpuRelax 指令，最低延迟                               │
├─────────────────────────────────────────────────────────────┤
│  Stage 2: Backoff Spin (退避自旋)                            │
│  - 默认 50 次迭代                                            │
│  - 每 8192 次调用 sched_yield                                │
├─────────────────────────────────────────────────────────────┤
│  Stage 3: Block Wait (阻塞等待)                              │
│  - 默认 1000 次迭代                                          │
│  - 睡眠间隔: 1ms → 2ms → 4ms → ... → 32ms（指数退避）        │
└─────────────────────────────────────────────────────────────┘
```

### ITryLockTuning - 自适应参数调优

```pascal
var
  Tuning: ITryLockTuning;
begin
  Tuning := Mutex as ITryLockTuning;

  // Phase 1: 紧密自旋参数
  Tuning.TightSpin := 2000;                    // 自旋次数
  Tuning.TightTimeCheckIntervalSpin := 1023;   // 超时检查间隔

  // Phase 2: 退避自旋参数
  Tuning.BackOffSpin := 50;                    // 自旋次数
  Tuning.BackOffYieldIntervalSpin := 8191;     // CPU yield 间隔

  // Phase 3: 阻塞等待参数
  Tuning.BlockSpin := 1000;                    // 迭代次数
  Tuning.BlockSleepIntervalMs := 1;            // 初始睡眠间隔
end;
```

### Poison 机制（Rust 风格）

当持有锁的线程异常退出时，锁会被标记为"毒化"：

```pascal
var
  Mutex: IMutex;
begin
  Mutex := MakeMutex;

  // 检查是否被毒化
  if Mutex.IsPoisoned then
  begin
    WriteLn('锁被毒化，之前的持有者异常退出');

    // 选项 1：清除毒化状态继续使用
    Mutex.ClearPoison;

    // 选项 2：抛出异常
    // raise Exception.Create('Lock is poisoned');
  end;

  Mutex.Acquire;  // 如果已毒化，会抛出 EMutexPoisonError
  try
    // 临界区代码
  finally
    Mutex.Release;
  end;
end;
```

## 与条件变量配合

在 Unix 平台使用条件变量时，必须使用 `MakePthreadMutex`：

```pascal
uses
  fafafa.core.sync.mutex,
  fafafa.core.sync.condvar;

var
  Mutex: IMutex;
  Cond: ICondVar;
begin
  // 必须使用 pthread 版本
  Mutex := MakePthreadMutex;
  Cond := MakeCondVar;

  Mutex.Acquire;
  try
    while not SomeCondition do
      Cond.Wait(Mutex);  // 需要 pthread_mutex_t 保证原子性

    // 条件满足，处理逻辑
  finally
    Mutex.Release;
  end;
end;
```

## 平台实现细节

### Windows

```
TMutex
├── CRITICAL_SECTION (默认)
│   └── 高效的用户态自旋 + 内核等待
└── SRWLOCK (Vista+, 可选)
    └── 更轻量，但功能受限
```

### Unix/Linux

```
TMutex (pthread_mutex_t)
├── pthread_mutex_init (PTHREAD_MUTEX_ERRORCHECK)
├── 检测同线程重复获取
└── 与 pthread_cond_* 兼容

TFutexMutex (futex syscall)
├── 快速路径: CAS 直接获取
├── 慢速路径: 短自旋 (40 次)
├── 等待路径: futex WAIT/WAKE
└── 不与 pthread_cond_* 兼容
```

## 性能基准

基于 1000 万次迭代测试（参见 `docs/fafafa.core.sync.benchmark.md`）：

| 场景 | pthread_mutex | futex | 备注 |
|------|--------------|-------|------|
| 单线程无竞争 | 23.18 ns/op | 27.42 ns/op | pthread 快 18% |
| 快速获取/释放 | 25.70 ns/op | 27.57 ns/op | pthread 快 7% |
| 4 线程低竞争 | 130 ns/op | 330 ns/op | pthread 快 154% |
| 4 线程高竞争 | 300 ns/op | 450 ns/op | pthread 快 50% |

**结论**: glibc 的 `pthread_mutex` 已高度优化，推荐使用 `MakeMutex()`。

## 最佳实践

### 1. 优先使用 try-finally

```pascal
// ✅ 推荐
Mutex.Acquire;
try
  // 临界区
finally
  Mutex.Release;
end;

// ❌ 不推荐（异常不安全）
Mutex.Acquire;
// 临界区
Mutex.Release;
```

### 2. 避免死锁

```pascal
// 始终以相同顺序获取多个锁
MutexA.Acquire;
try
  MutexB.Acquire;
  try
    // 临界区
  finally
    MutexB.Release;
  end;
finally
  MutexA.Release;
end;
```

### 3. 使用超时机制

```pascal
// 避免无限等待
if not Mutex.TryAcquire(5000) then  // 5 秒超时
  raise Exception.Create('Failed to acquire lock within timeout');
```

### 4. 缩短临界区

```pascal
// ✅ 推荐：只在必要时持有锁
var Data: TData;
Mutex.Acquire;
try
  Data := FSharedData;  // 快速复制
finally
  Mutex.Release;
end;
ProcessData(Data);  // 在锁外处理

// ❌ 不推荐：长时间持有锁
Mutex.Acquire;
try
  ProcessData(FSharedData);  // 长时间操作
finally
  Mutex.Release;
end;
```

### 5. 条件变量配合

```pascal
// Unix: 必须使用 MakePthreadMutex
{$IFDEF UNIX}
Mutex := MakePthreadMutex;
{$ELSE}
Mutex := MakeMutex;
{$ENDIF}
```

## 异常处理

| 异常类型 | 触发条件 |
|---------|---------|
| `EDeadlockError` | 同一线程重复获取非重入锁 |
| `ELockError` | 系统调用失败 |
| `EMutexPoisonError` | 获取已毒化的锁 |

## 相关文档

- [fafafa.core.sync](fafafa.core.sync.md) - 主同步模块
- [fafafa.core.sync.recMutex](fafafa.core.sync.recMutex.md) - 可重入互斥锁
- [fafafa.core.sync.condvar](fafafa.core.sync.condvar.md) - 条件变量
- [fafafa.core.sync.benchmark](fafafa.core.sync.benchmark.md) - 性能基准

## 版本历史

### v2.0.0 (2025-12)
- 添加 Poison 机制（Rust 风格）
- 添加 `MakeFutexMutex` 工厂函数
- 三段式等待策略优化
- pthread vs futex 基准测试

### v1.0.0
- 基础互斥锁实现
- 跨平台支持
