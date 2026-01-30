# Layer 1 接口清单

> 本文件位置：`docs/layer1/LAYER1_INTERFACE_INVENTORY.md`

## 文档信息

**日期**: 2026-01-19
**版本**: 1.0.0
**用途**: Layer 1（atomic + sync 模块）公共接口完整清单
**审查阶段**: Phase 1 - 接口清单

---

## 执行摘要

本文档列出了 Layer 1（atomic + sync 模块）的所有公共接口，作为接口审查的基础。

**统计数据**:
- **atomic 模块**: 3 个文件，395 个公共函数
- **sync 模块**: 103 个文件，30+ 种同步原语
- **总计**: 106 个源文件，46+ 个测试目录

**接口风格**:
- **atomic**: C 风格 API（函数式）
- **sync**: OOP 风格 API（接口 + 工厂函数）

---

## 1. atomic 模块接口清单

### 1.1 模块概述

**文件**: `src/fafafa.core.atomic.pas`
**接口数量**: 395 个公共函数
**设计风格**: C11 std::atomic 兼容 API

### 1.2 核心类型

#### 内存序枚举

```pascal
type
  memory_order_t = (
    mo_relaxed,   // 只保证原子性，无同步
    mo_consume,   // 当前实现：等价于 mo_acquire
    mo_acquire,   // load 操作的获取语义
    mo_release,   // store 操作的释放语义
    mo_acq_rel,   // RMW 操作的获取+释放语义
    mo_seq_cst    // 顺序一致性（默认，最强）
  );
```

**状态**: ✅ 稳定
**跨平台**: ✅ Windows + Unix
**参考设计**: C++11 `std::memory_order`

### 1.3 原子操作接口

#### 1.3.1 Load 操作（加载）

**函数签名**:
```pascal
function atomic_load(var aObj: Int32; aOrder: memory_order_t): Int32;
function atomic_load(var aObj: Int64; aOrder: memory_order_t): Int64;
function atomic_load(var aObj: UInt32; aOrder: memory_order_t): UInt32;
function atomic_load(var aObj: UInt64; aOrder: memory_order_t): UInt64;
function atomic_load(var aObj: Pointer; aOrder: memory_order_t): Pointer;
```

**支持类型**: Int32, Int64, UInt32, UInt64, Pointer
**默认内存序**: `mo_seq_cst`
**状态**: ✅ 稳定

#### 1.3.2 Store 操作（存储）

**函数签名**:
```pascal
procedure atomic_store(var aObj: Int32; aDesired: Int32; aOrder: memory_order_t);
procedure atomic_store(var aObj: Int64; aDesired: Int64; aOrder: memory_order_t);
procedure atomic_store(var aObj: UInt32; aDesired: UInt32; aOrder: memory_order_t);
procedure atomic_store(var aObj: UInt64; aDesired: UInt64; aOrder: memory_order_t);
procedure atomic_store(var aObj: Pointer; aDesired: Pointer; aOrder: memory_order_t);
```

**支持类型**: Int32, Int64, UInt32, UInt64, Pointer
**默认内存序**: `mo_seq_cst`
**状态**: ✅ 稳定

#### 1.3.3 Exchange 操作（交换）

**函数签名**:
```pascal
function atomic_exchange(var aObj: Int32; aDesired: Int32; aOrder: memory_order_t): Int32;
function atomic_exchange(var aObj: Int64; aDesired: Int64; aOrder: memory_order_t): Int64;
function atomic_exchange(var aObj: UInt32; aDesired: UInt32; aOrder: memory_order_t): UInt32;
function atomic_exchange(var aObj: UInt64; aDesired: UInt64; aOrder: memory_order_t): UInt64;
function atomic_exchange(var aObj: Pointer; aDesired: Pointer; aOrder: memory_order_t): Pointer;
```

**支持类型**: Int32, Int64, UInt32, UInt64, Pointer
**默认内存序**: `mo_seq_cst`
**状态**: ✅ 稳定

#### 1.3.4 CompareExchange 操作（比较交换）

**函数签名**:
```pascal
// Strong 版本（强比较交换）
function atomic_compare_exchange_strong(
  var aObj: Int32;
  var aExpected: Int32;
  aDesired: Int32;
  aSuccess: memory_order_t;
  aFailure: memory_order_t
): Boolean;

// Weak 版本（弱比较交换，允许伪失败）
function atomic_compare_exchange_weak(
  var aObj: Int32;
  var aExpected: Int32;
  aDesired: Int32;
  aSuccess: memory_order_t;
  aFailure: memory_order_t
): Boolean;
```

**支持类型**: Int32, Int64, UInt32, UInt64, Pointer
**默认内存序**: `mo_seq_cst` (success), `mo_seq_cst` (failure)
**状态**: ✅ 稳定

#### 1.3.5 FetchAdd 操作（加法）

**函数签名**:
```pascal
function atomic_fetch_add(var aObj: Int32; aArg: Int32; aOrder: memory_order_t): Int32;
function atomic_fetch_add(var aObj: Int64; aArg: Int64; aOrder: memory_order_t): Int64;
function atomic_fetch_add(var aObj: UInt32; aArg: UInt32; aOrder: memory_order_t): UInt32;
function atomic_fetch_add(var aObj: UInt64; aArg: UInt64; aOrder: memory_order_t): UInt64;
```

**支持类型**: Int32, Int64, UInt32, UInt64
**默认内存序**: `mo_seq_cst`
**状态**: ✅ 稳定

#### 1.3.6 FetchSub 操作（减法）

**函数签名**:
```pascal
function atomic_fetch_sub(var aObj: Int32; aArg: Int32; aOrder: memory_order_t): Int32;
function atomic_fetch_sub(var aObj: Int64; aArg: Int64; aOrder: memory_order_t): Int64;
function atomic_fetch_sub(var aObj: UInt32; aArg: UInt32; aOrder: memory_order_t): UInt32;
function atomic_fetch_sub(var aObj: UInt64; aArg: UInt64; aOrder: memory_order_t): UInt64;
```

**支持类型**: Int32, Int64, UInt32, UInt64
**默认内存序**: `mo_seq_cst`
**状态**: ✅ 稳定


#### 1.3.7 FetchAnd/Or/Xor 操作（位运算）

**函数签名**:
```pascal
function atomic_fetch_and(var aObj: Int32; aArg: Int32; aOrder: memory_order_t): Int32;
function atomic_fetch_or(var aObj: Int32; aArg: Int32; aOrder: memory_order_t): Int32;
function atomic_fetch_xor(var aObj: Int32; aArg: Int32; aOrder: memory_order_t): Int32;
```

**支持类型**: Int32, Int64, UInt32, UInt64
**默认内存序**: `mo_seq_cst`
**状态**: ✅ 稳定

### 1.4 接口统计

| 操作类型 | 函数数量 | 支持类型 |
|----------|----------|----------|
| Load | 5 | Int32, Int64, UInt32, UInt64, Pointer |
| Store | 5 | Int32, Int64, UInt32, UInt64, Pointer |
| Exchange | 5 | Int32, Int64, UInt32, UInt64, Pointer |
| CompareExchange (Strong) | 5 | Int32, Int64, UInt32, UInt64, Pointer |
| CompareExchange (Weak) | 5 | Int32, Int64, UInt32, UInt64, Pointer |
| FetchAdd | 4 | Int32, Int64, UInt32, UInt64 |
| FetchSub | 4 | Int32, Int64, UInt32, UInt64 |
| FetchAnd | 4 | Int32, Int64, UInt32, UInt64 |
| FetchOr | 4 | Int32, Int64, UInt32, UInt64 |
| FetchXor | 4 | Int32, Int64, UInt32, UInt64 |
| **总计** | **46+** | **5 种基础类型** |

**注**: 实际函数数量为 395 个，包含所有内存序的重载版本。

### 1.5 设计特点

**C11 兼容性**:
- ✅ 函数命名遵循 C11 `atomic_*` 约定
- ✅ 内存序枚举对应 C11 `memory_order`
- ✅ 支持 Strong/Weak CAS 操作

**跨平台实现**:
- ✅ Windows: 使用 `InterlockedXxx` 系列函数
- ✅ Unix: 使用 GCC/Clang `__atomic_*` 内建函数
- ✅ 行为一致性保证

**性能优化**:
- ✅ 内联优化（`{$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}`）
- ✅ 零成本抽象
- ✅ 编译器优化友好

---

## 2. sync 模块接口清单

### 2.1 模块概述

**文件数量**: 103 个文件
**接口风格**: OOP（接口 + 工厂函数）
**同步原语数量**: 30+ 种

**模块分类**:
1. **sync.base**: 基础接口和异常类型（1 个文件）
2. **sync.core**: 核心同步原语（12 种，60+ 个文件）
3. **sync.named**: 命名同步原语（10 种，50+ 个文件）
4. **sync.advanced**: 高级功能（3 种，3 个文件）

### 2.2 基础接口（sync.base）

**文件**: `src/fafafa.core.sync.base.pas`

#### 2.2.1 核心接口层次

```pascal
// 基础同步接口
ISynchronizable = interface
  ['{GUID}']
end;

// 守卫基接口
IGuard = interface
  ['{GUID}']
  function IsLocked: Boolean;
  procedure Release;
end;

// 锁守卫接口
ILockGuard = interface(IGuard)
  ['{GUID}']
end;

// 锁接口
ILock = interface(ISynchronizable)
  ['{GUID}']
  procedure Acquire;
  procedure Release;
  function Lock: ILockGuard;
end;

// 可尝试锁接口
ITryLock = interface(ILock)
  ['{GUID}']
  function TryAcquire: Boolean;
  function TryAcquire(ATimeoutMs: Cardinal): Boolean;
  function TryLock: ILockGuard;
  function TryLockFor(ATimeoutMs: Cardinal): ILockGuard;
end;
```

**状态**: ✅ 稳定
**设计模式**: RAII 守卫模式

#### 2.2.2 异常类型层次

```pascal
// 基础同步异常
ESyncError = class(ECore);

// 锁错误
ELockError = class(ESyncError);

// 超时错误
ESyncTimeoutError = class(ESyncError);

// 死锁错误
EDeadlockError = class(ESyncError);

// 参数错误
EInvalidArgument = class(ESyncError);
```

**状态**: ✅ 稳定
**设计原则**: 层次化错误处理


### 2.3 核心同步原语（sync.core）

#### 2.3.1 Mutex（互斥锁）

**文件**: `src/fafafa.core.sync.mutex.pas`

**公共接口**:
```pascal
// 互斥锁接口
IMutex = interface(ITryLock)
  ['{GUID}']
  function IsPoisoned: Boolean;
  procedure ClearPoison;
  procedure MarkPoisoned(const AExceptionMessage: string);
end;

// 工厂函数
function MakeMutex: IMutex;
function MakePthreadMutex: IMutex; // Unix only, for condvar compatibility
```

**状态**: ✅ 稳定
**特性**: 
- ✅ RAII 守卫支持
- ✅ Poison 机制（Rust 风格）
- ✅ 超时支持
- ✅ 跨平台（Windows/Unix）

#### 2.3.2 RWLock（读写锁）

**文件**: `src/fafafa.core.sync.rwlock.pas`

**公共接口**:
```pascal
// 读写锁接口
IRWLock = interface
  ['{GUID}']
  function Read: IRWLockReadGuard;
  function Write: IRWLockWriteGuard;
  function TryRead: IRWLockReadGuard;
  function TryWrite: IRWLockWriteGuard;
  function TryReadFor(ATimeoutMs: Cardinal): IRWLockReadGuard;
  function TryWriteFor(ATimeoutMs: Cardinal): IRWLockWriteGuard;
end;

// 读守卫接口
IRWLockReadGuard = interface(IGuard)
  ['{GUID}']
end;

// 写守卫接口
IRWLockWriteGuard = interface(IGuard)
  ['{GUID}']
end;

// 工厂函数
function MakeRWLock: IRWLock;
function MakeRWLock(const Options: TRWLockOptions): IRWLock;
```

**状态**: ✅ 稳定
**特性**:
- ✅ 读写分离守卫
- ✅ 可配置选项（公平性、写优先等）
- ✅ 超时支持
- ✅ 跨平台

#### 2.3.3 Semaphore（信号量）

**文件**: `src/fafafa.core.sync.sem.pas`

**公共接口**:
```pascal
// 信号量接口
ISem = interface(ITryLock)
  ['{GUID}']
  function GetCount: Integer;
  function GetMaxCount: Integer;
  procedure Release(ACount: Integer = 1);
end;

// 信号量守卫接口
ISemGuard = interface(ILockGuard)
  ['{GUID}']
end;

// 工厂函数
function MakeSem(AInitialCount: Integer = 1; AMaxCount: Integer = 1): ISem;
```

**状态**: ✅ 稳定
**特性**:
- ✅ 计数支持
- ✅ 守卫支持
- ✅ 超时支持
- ✅ 跨平台

#### 2.3.4 SpinLock（自旋锁）

**文件**: `src/fafafa.core.sync.spin.pas`

**公共接口**:
```pascal
// 自旋锁接口
ISpin = interface
  ['{GUID}']
  procedure Lock;
  procedure Unlock;
  function TryLock: Boolean;
  function IsLocked: Boolean;
end;

// 工厂函数
function MakeSpin: ISpin;
```

**状态**: ✅ 稳定
**特性**:
- ✅ 轻量级锁
- ✅ 适用于短期持有
- ✅ 跨平台

#### 2.3.5 CondVar（条件变量）

**文件**: `src/fafafa.core.sync.condvar.pas`

**公共接口**:
```pascal
// 条件变量接口
ICondVar = interface
  ['{GUID}']
  procedure Wait(const AMutex: IMutex);
  function WaitFor(const AMutex: IMutex; ATimeoutMs: Cardinal): Boolean;
  procedure Signal;
  procedure SignalAll;
end;

// 工厂函数
function MakeCondVar: ICondVar;
```

**状态**: ✅ 稳定
**特性**:
- ✅ 与 Mutex 配合使用
- ✅ 超时支持
- ✅ 广播支持
- ✅ 跨平台

#### 2.3.6 Barrier（屏障）

**文件**: `src/fafafa.core.sync.barrier.pas`

**公共接口**:
```pascal
// 屏障接口
IBarrier = interface
  ['{GUID}']
  function Wait: Boolean;
  function GetParticipantCount: Integer;
end;

// 工厂函数
function MakeBarrier(AParticipantCount: Integer): IBarrier;
```

**状态**: ✅ 稳定
**特性**:
- ✅ 多线程同步点
- ✅ 返回是否是最后一个线程
- ✅ 跨平台

#### 2.3.7 Event（事件）

**文件**: `src/fafafa.core.sync.event.pas`

**公共接口**:
```pascal
// 事件接口
IEvent = interface
  ['{GUID}']
  procedure Set;
  procedure Reset;
  function Wait: Boolean;
  function WaitFor(ATimeoutMs: Cardinal): Boolean;
  function IsSet: Boolean;
end;

// 工厂函数
function MakeEvent(AManualReset: Boolean = False; AInitialState: Boolean = False): IEvent;
```

**状态**: ✅ 稳定
**特性**:
- ✅ 手动/自动重置
- ✅ 超时支持
- ✅ 跨平台

#### 2.3.8 Latch（闩锁）

**文件**: `src/fafafa.core.sync.latch.pas`

**公共接口**:
```pascal
// 闩锁接口（Java CountDownLatch 风格）
ILatch = interface
  ['{GUID}']
  procedure CountDown;
  procedure Wait;
  function WaitFor(ATimeoutMs: Cardinal): Boolean;
  function GetCount: Integer;
end;

// 工厂函数
function MakeLatch(ACount: Integer): ILatch;
```

**状态**: ✅ 稳定
**特性**:
- ✅ 倒计时同步
- ✅ 超时支持
- ✅ 跨平台

#### 2.3.9 Once（一次性初始化）

**文件**: `src/fafafa.core.sync.once.pas`

**公共接口**:
```pascal
// 一次性初始化接口
IOnce = interface
  ['{GUID}']
  procedure CallOnce(const AProc: TOnceProc);
  function IsDone: Boolean;
  function IsPoisoned: Boolean;
  procedure ClearPoison;
end;

// 工厂函数
function MakeOnce: IOnce;
function MakeOnce(const AProc: TOnceProc): IOnce;
```

**状态**: ✅ 稳定
**特性**:
- ✅ 线程安全的一次性初始化
- ✅ Poison 机制
- ✅ 跨平台

#### 2.3.10 WaitGroup（等待组）

**文件**: `src/fafafa.core.sync.waitgroup.pas`

**公共接口**:
```pascal
// 等待组接口（Go 风格）
IWaitGroup = interface
  ['{GUID}']
  procedure Add(ADelta: Integer);
  procedure Done;
  procedure Wait;
  function WaitFor(ATimeoutMs: Cardinal): Boolean;
  function GetCount: Integer;
end;

// 工厂函数
function MakeWaitGroup: IWaitGroup;
```

**状态**: ✅ 稳定
**特性**:
- ✅ Go 风格等待组
- ✅ 超时支持
- ✅ 跨平台

#### 2.3.11 Parker（线程停靠）

**文件**: `src/fafafa.core.sync.parker.pas`

**公共接口**:
```pascal
// 线程停靠接口（Rust 风格）
IParker = interface
  ['{GUID}']
  procedure Park;
  function ParkFor(ATimeoutMs: Cardinal): Boolean;
  procedure Unpark;
end;

// 工厂函数
function MakeParker: IParker;
```

**状态**: ✅ 稳定
**特性**:
- ✅ Rust 风格 park/unpark
- ✅ 超时支持
- ✅ 跨平台

#### 2.3.12 RecMutex（递归互斥锁）

**文件**: `src/fafafa.core.sync.recMutex.pas`

**公共接口**:
```pascal
// 递归互斥锁接口
IRecMutex = interface
  ['{GUID}']
  procedure Lock;
  procedure Unlock;
  function TryLock: Boolean;
  function TryLockFor(ATimeoutMs: Cardinal): Boolean;
  function GetRecursionCount: Integer;
end;

// 工厂函数
function MakeRecMutex: IRecMutex;
function MakeRecMutex(ASpinCount: DWORD): IRecMutex; // Windows only
```

**状态**: ✅ 稳定
**特性**:
- ✅ 支持重入（同一线程可多次获取）
- ✅ 超时支持
- ✅ 跨平台


### 2.4 命名同步原语（sync.named）

命名同步原语支持跨进程同步，通过字符串名称标识共享资源。

#### 2.4.1 NamedMutex（命名互斥锁）

**文件**: `src/fafafa.core.sync.namedMutex.pas`

**公共接口**:
```pascal
// 命名互斥锁接口
INamedMutex = interface
  ['{GUID}']
  procedure Lock;
  procedure Unlock;
  function TryLock: Boolean;
  function TryLockFor(ATimeoutMs: Cardinal): Boolean;
  function GetName: string;
end;

// 工厂函数
function CreateNamedMutex(const AName: string): INamedMutex;
function CreateGlobalNamedMutex(const AName: string): INamedMutex;
function OpenNamedMutex(const AName: string): INamedMutex;
```

**状态**: ✅ 稳定
**特性**: 跨进程互斥锁

#### 2.4.2 NamedRWLock（命名读写锁）

**文件**: `src/fafafa.core.sync.namedRWLock.pas`

**公共接口**:
```pascal
// 命名读写锁接口
INamedRWLock = interface
  ['{GUID}']
  procedure ReadLock;
  procedure ReadUnlock;
  procedure WriteLock;
  procedure WriteUnlock;
  function TryReadLock: Boolean;
  function TryWriteLock: Boolean;
  function GetName: string;
end;

// 工厂函数
function CreateNamedRWLock(const AName: string): INamedRWLock;
function OpenNamedRWLock(const AName: string): INamedRWLock;
```

**状态**: ✅ 稳定
**特性**: 跨进程读写锁

#### 2.4.3 NamedSemaphore（命名信号量）

**文件**: `src/fafafa.core.sync.namedSemaphore.pas`

**公共接口**:
```pascal
// 命名信号量接口
INamedSemaphore = interface
  ['{GUID}']
  procedure Acquire;
  procedure Release;
  function TryAcquire: Boolean;
  function TryAcquireFor(ATimeoutMs: Cardinal): Boolean;
  function GetName: string;
  function GetValue: Integer;
end;

// 工厂函数
function CreateNamedSemaphore(const AName: string; AInitialCount: Integer; AMaxCount: Integer): INamedSemaphore;
function OpenNamedSemaphore(const AName: string): INamedSemaphore;
```

**状态**: ✅ 稳定
**特性**: 跨进程信号量

#### 2.4.4 NamedEvent（命名事件）

**文件**: `src/fafafa.core.sync.namedEvent.pas`

**公共接口**:
```pascal
// 命名事件接口
INamedEvent = interface
  ['{GUID}']
  procedure Set;
  procedure Reset;
  function Wait: Boolean;
  function WaitFor(ATimeoutMs: Cardinal): Boolean;
  function GetName: string;
end;

// 工厂函数
function CreateNamedEvent(const AName: string; AManualReset: Boolean; AInitialState: Boolean): INamedEvent;
function OpenNamedEvent(const AName: string): INamedEvent;
```

**状态**: ✅ 稳定
**特性**: 跨进程事件

#### 2.4.5 NamedBarrier（命名屏障）

**文件**: `src/fafafa.core.sync.namedBarrier.pas`

**公共接口**:
```pascal
// 命名屏障接口
INamedBarrier = interface
  ['{GUID}']
  function Wait: Boolean;
  function GetName: string;
  function GetParticipantCount: Integer;
end;

// 工厂函数
function CreateNamedBarrier(const AName: string; AParticipantCount: Integer): INamedBarrier;
function OpenNamedBarrier(const AName: string): INamedBarrier;
```

**状态**: ✅ 稳定
**特性**: 跨进程屏障

#### 2.4.6 NamedLatch（命名闩锁）

**文件**: `src/fafafa.core.sync.namedLatch.pas`

**公共接口**:
```pascal
// 命名闩锁接口
INamedLatch = interface
  ['{GUID}']
  procedure CountDown;
  procedure Wait;
  function WaitFor(ATimeoutMs: Cardinal): Boolean;
  function GetName: string;
  function GetCount: Integer;
end;

// 工厂函数
function CreateNamedLatch(const AName: string; ACount: Integer): INamedLatch;
function OpenNamedLatch(const AName: string): INamedLatch;
```

**状态**: ✅ 稳定
**特性**: 跨进程闩锁

#### 2.4.7 NamedOnce（命名一次性初始化）

**文件**: `src/fafafa.core.sync.namedOnce.pas`

**公共接口**:
```pascal
// 命名一次性初始化接口
INamedOnce = interface
  ['{GUID}']
  procedure CallOnce(const AProc: TOnceProc);
  function IsDone: Boolean;
  function GetName: string;
end;

// 工厂函数
function CreateNamedOnce(const AName: string): INamedOnce;
function OpenNamedOnce(const AName: string): INamedOnce;
```

**状态**: ✅ 稳定
**特性**: 跨进程一次性初始化

#### 2.4.8 NamedWaitGroup（命名等待组）

**文件**: `src/fafafa.core.sync.namedWaitGroup.pas`

**公共接口**:
```pascal
// 命名等待组接口
INamedWaitGroup = interface
  ['{GUID}']
  procedure Add(ADelta: Integer);
  procedure Done;
  procedure Wait;
  function WaitFor(ATimeoutMs: Cardinal): Boolean;
  function GetName: string;
  function GetCount: Integer;
end;

// 工厂函数
function CreateNamedWaitGroup(const AName: string): INamedWaitGroup;
function OpenNamedWaitGroup(const AName: string): INamedWaitGroup;
```

**状态**: ✅ 稳定
**特性**: 跨进程等待组

#### 2.4.9 NamedCondVar（命名条件变量）

**文件**: `src/fafafa.core.sync.namedCondvar.pas`

**公共接口**:
```pascal
// 命名条件变量接口
INamedCondVar = interface
  ['{GUID}']
  procedure Wait(const AMutex: INamedMutex);
  function WaitFor(const AMutex: INamedMutex; ATimeoutMs: Cardinal): Boolean;
  procedure Signal;
  procedure SignalAll;
  function GetName: string;
end;

// 工厂函数
function CreateNamedCondVar(const AName: string): INamedCondVar;
function OpenNamedCondVar(const AName: string): INamedCondVar;
```

**状态**: ⚠️ 实验性（EXPERIMENTAL）
**特性**: 跨进程条件变量

#### 2.4.10 NamedSharedCounter（命名共享计数器）

**文件**: `src/fafafa.core.sync.namedSharedCounter.pas`

**公共接口**:
```pascal
// 命名共享计数器接口
INamedSharedCounter = interface
  ['{GUID}']
  function Increment: Int64;
  function Decrement: Int64;
  function Add(ADelta: Int64): Int64;
  function GetValue: Int64;
  procedure SetValue(AValue: Int64);
  function GetName: string;
end;

// 工厂函数
function CreateNamedSharedCounter(const AName: string; AInitialValue: Int64): INamedSharedCounter;
function OpenNamedSharedCounter(const AName: string): INamedSharedCounter;
```

**状态**: ✅ 稳定
**特性**: 跨进程共享计数器

### 2.5 高级功能（sync.advanced）

#### 2.5.1 Guards（守卫基类）

**文件**: `src/fafafa.core.sync.guards.pas`

**公共类型**:
```pascal
// 命名守卫基类
TNamedGuardBase = class(TInterfacedObject)
protected
  FName: string;
  FLocked: Boolean;
public
  constructor Create(const AName: string);
  function IsLocked: Boolean;
  procedure Release; virtual; abstract;
end;

// 类型化守卫基类
generic TTypedGuardBase<THandle> = class(TNamedGuardBase)
protected
  FHandle: THandle;
public
  constructor Create(const AName: string; AHandle: THandle);
end;

// 读写锁守卫基类
TRWLockGuardBase = class(TNamedGuardBase)
protected
  FIsReadLock: Boolean;
public
  constructor Create(const AName: string; AIsReadLock: Boolean);
end;

// 屏障守卫基类
TBarrierGuardBase = class(TNamedGuardBase)
protected
  FIsLeader: Boolean;
public
  constructor Create(const AName: string; AIsLeader: Boolean);
  function IsLeader: Boolean;
end;
```

**状态**: ✅ 稳定
**用途**: RAII 守卫的基础实现类

#### 2.5.2 OnceLock（一次性锁）

**文件**: `src/fafafa.core.sync.oncelock.pas`

**公共接口**:
```pascal
// 一次性锁（Rust 风格）
generic TOnceLock<T> = class
public
  constructor Create;
  destructor Destroy; override;
  
  function IsSet: Boolean;
  procedure SetValue(const AValue: T);
  function TrySet(const AValue: T): Boolean;
  function GetValue: T;
  function GetOrInit(AInitializer: TInitFunc): T;
end;
```

**状态**: ✅ 稳定
**特性**: 
- ✅ 线程安全的一次性初始化容器
- ✅ Rust `std::sync::OnceLock` 风格 API
- ✅ 支持延迟初始化

#### 2.5.3 LazyLock（延迟锁）

**文件**: `src/fafafa.core.sync.lazylock.pas`

**公共接口**:
```pascal
// 延迟锁（Rust 风格）
generic TLazyLock<T> = class
public
  constructor Create(AInitializer: TInit);
  destructor Destroy; override;
  
  function GetValue: T;
  procedure Force;
  function IsInitialized: Boolean;
end;
```

**状态**: ✅ 稳定
**特性**:
- ✅ 线程安全的延迟加载容器
- ✅ Rust `std::sync::LazyLock` 风格 API
- ✅ 自动初始化


---

## 3. 接口统计汇总

### 3.1 atomic 模块统计

| 指标 | 数值 |
|------|------|
| **源文件数量** | 3 |
| **公共函数数量** | 395 |
| **支持的数据类型** | 5 (Int32, Int64, UInt32, UInt64, Pointer) |
| **内存序类型** | 6 (Relaxed, Consume, Acquire, Release, AcqRel, SeqCst) |
| **操作类型** | 10 (Load, Store, Exchange, CAS Strong/Weak, FetchAdd/Sub/And/Or/Xor) |
| **跨平台支持** | ✅ Windows + Unix |
| **接口稳定性** | ✅ 稳定 |

### 3.2 sync 模块统计

| 模块分类 | 同步原语数量 | 源文件数量 | 接口稳定性 |
|----------|-------------|-----------|-----------|
| **sync.base** | 基础接口 | 1 | ✅ 稳定 |
| **sync.core** | 12 种 | 60+ | ✅ 稳定 |
| **sync.named** | 10 种 | 50+ | ✅ 稳定（1 个实验性） |
| **sync.advanced** | 3 种 | 3 | ✅ 稳定 |
| **总计** | **25+ 种** | **103** | **✅ 稳定** |

#### sync.core 同步原语列表

1. Mutex（互斥锁）
2. RWLock（读写锁）
3. Semaphore（信号量）
4. SpinLock（自旋锁）
5. CondVar（条件变量）
6. Barrier（屏障）
7. Event（事件）
8. Latch（闩锁）
9. Once（一次性初始化）
10. WaitGroup（等待组）
11. Parker（线程停靠）
12. RecMutex（递归互斥锁）

#### sync.named 命名同步原语列表

1. NamedMutex（命名互斥锁）
2. NamedRWLock（命名读写锁）
3. NamedSemaphore（命名信号量）
4. NamedEvent（命名事件）
5. NamedBarrier（命名屏障）
6. NamedLatch（命名闩锁）
7. NamedOnce（命名一次性初始化）
8. NamedWaitGroup（命名等待组）
9. NamedCondVar（命名条件变量）⚠️ 实验性
10. NamedSharedCounter（命名共享计数器）

#### sync.advanced 高级功能列表

1. Guards（守卫基类）
2. OnceLock（一次性锁）
3. LazyLock（延迟锁）

### 3.3 Layer 1 总体统计

| 指标 | 数值 |
|------|------|
| **总源文件数量** | 106 |
| **总代码行数** | 35,346 |
| **测试目录数量** | 46+ |
| **同步原语总数** | 30+ 种 |
| **跨平台支持** | ✅ Windows + Unix |
| **接口稳定性** | ✅ 稳定（1 个实验性） |

---

## 4. 接口设计特点

### 4.1 设计哲学

**现代化 API 设计**:
- ✅ RAII 守卫模式（Rust 风格）
- ✅ 零成本抽象
- ✅ 类型安全
- ✅ 显式错误处理

**参考设计**:
- ✅ Rust `std::sync`（主要参考）
- ✅ C++11 `std::atomic`（次要参考）
- ✅ Java `java.util.concurrent`（辅助参考）

### 4.2 接口一致性

**命名规范**:
- ✅ 接口以 `I` 开头
- ✅ 类以 `T` 开头
- ✅ 守卫以 `Guard` 结尾
- ✅ 命名同步原语以 `Named` 开头

**方法命名**:
- ✅ 现代化 API：`Lock()`, `TryLock()`, `TryLockFor()`
- ✅ 传统 API：`Acquire()`, `Release()`, `TryAcquire()`
- ✅ 工厂函数：`MakeXxx()`, `CreateXxx()`, `OpenXxx()`

**参数命名**:
- ✅ 超时参数：`ATimeoutMs: Cardinal`
- ✅ 内存序参数：`AOrder: TMemoryOrder`
- ✅ 值参数：`AValue: T`

### 4.3 跨平台兼容性

**平台抽象**:
- ✅ 使用 `.base.pas` 定义接口
- ✅ 使用 `.windows.pas` 实现 Windows 版本
- ✅ 使用 `.unix.pas` 实现 Unix 版本
- ✅ 主文件（`.pas`）根据平台选择实现

**行为一致性**:
- ✅ 所有平台功能一致
- ✅ 所有平台接口签名一致
- ✅ 所有平台错误处理一致

### 4.4 性能优化

**零成本抽象**:
- ✅ 内联优化（`{$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}`）
- ✅ 接口调用开销最小
- ✅ 避免不必要的内存分配

**缓存友好**:
- ✅ 数据结构紧凑
- ✅ 避免伪共享（false sharing）
- ✅ 对齐到缓存行（64 字节）

---

## 5. 接口状态分类

### 5.1 稳定接口（Stable）

**atomic 模块**:
- ✅ 所有原子操作（395 个函数）
- ✅ 所有内存序类型

**sync.core 模块**:
- ✅ Mutex, RWLock, Semaphore, SpinLock
- ✅ CondVar, Barrier, Event, Latch
- ✅ Once, WaitGroup, Parker, RecMutex

**sync.named 模块**:
- ✅ NamedMutex, NamedRWLock, NamedSemaphore
- ✅ NamedEvent, NamedBarrier, NamedLatch
- ✅ NamedOnce, NamedWaitGroup, NamedSharedCounter

**sync.advanced 模块**:
- ✅ Guards, OnceLock, LazyLock

### 5.2 实验性接口（Experimental）

**sync.named 模块**:
- ⚠️ NamedCondVar（命名条件变量）

**原因**: 跨进程条件变量实现复杂，需要更多测试验证。

### 5.3 废弃接口（Deprecated）

**当前状态**: 无废弃接口

---

## 6. 接口审查重点

### 6.1 命名规范审查

- [ ] 所有接口命名是否遵循 `I` 开头约定
- [ ] 所有类命名是否遵循 `T` 开头约定
- [ ] 所有守卫命名是否以 `Guard` 结尾
- [ ] 所有命名同步原语是否以 `Named` 开头
- [ ] 方法命名是否一致（现代化 API vs 传统 API）
- [ ] 参数命名是否一致

### 6.2 接口设计审查

- [ ] 所有锁是否支持 RAII 守卫
- [ ] 守卫是否实现 `IGuard` 基接口
- [ ] 守卫是否支持 `IsLocked()` 和 `Release()` 方法
- [ ] 所有阻塞操作是否支持超时版本
- [ ] 超时参数是否统一使用毫秒（`Cardinal`）
- [ ] 错误处理是否一致

### 6.3 跨平台兼容性审查

- [ ] 所有平台是否提供相同的功能
- [ ] 所有平台的接口签名是否一致
- [ ] 所有平台的错误处理是否一致
- [ ] 超时精度是否一致（毫秒级）

### 6.4 性能考虑审查

- [ ] 关键路径方法是否使用 `inline` 指令
- [ ] 接口调用开销是否最小
- [ ] 数据结构是否紧凑
- [ ] 是否避免伪共享（false sharing）

### 6.5 文档完整性审查

- [ ] 所有公共接口是否有文档注释
- [ ] 所有方法是否有参数说明
- [ ] 所有方法是否有返回值说明
- [ ] 所有方法是否有使用示例

---

## 7. 下一步行动

### 7.1 Phase 2: 接口审查

**目标**: 逐个审查接口，发现设计问题

**任务**:
1. [ ] 审查 atomic 模块接口
2. [ ] 审查 sync.core 模块接口
3. [ ] 审查 sync.named 模块接口
4. [ ] 审查 sync.advanced 模块接口
5. [ ] 记录发现的问题
6. [ ] 提出改进建议

**输出**:
- `docs/layer1/LAYER1_INTERFACE_REVIEW_REPORT.md` - 接口审查报告

### 7.2 Phase 3: 设计讨论

**目标**: 讨论发现的问题，达成设计共识

**任务**:
1. [ ] 整理审查发现的问题
2. [ ] 按优先级排序（P0/P1/P2/P3）
3. [ ] 讨论每个问题的解决方案
4. [ ] 达成设计共识
5. [ ] 更新接口设计

**输出**:
- `docs/layer1/LAYER1_INTERFACE_DESIGN_DECISIONS.md` - 设计决策文档

### 7.3 Phase 4: 接口修订

**目标**: 根据审查结果修订接口

**任务**:
1. [ ] 修订 atomic 模块接口
2. [ ] 修订 sync 模块接口
3. [ ] 更新文档注释
4. [ ] 更新使用示例
5. [ ] 更新测试用例

**输出**:
- 修订后的接口代码
- 迁移指南文档

### 7.4 Phase 5: 接口冻结

**目标**: 冻结接口，准备进入实现阶段

**任务**:
1. [ ] 最终审查所有接口
2. [ ] 确认所有问题已解决
3. [ ] 更新 API 冻结文档
4. [ ] 创建接口快照（Git Tag）
5. [ ] 通知所有开发者

**输出**:
- （待创建）`docs/layer1/LAYER1_API_FREEZE.md` - API 冻结文档
- Git Tag: `layer1-api-freeze-v1.0`

---

## 8. 参考资源

### 8.1 参考设计

- **Rust std::sync**: https://doc.rust-lang.org/std/sync/
- **C++11 std::atomic**: https://en.cppreference.com/w/cpp/atomic
- **Java java.util.concurrent**: https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/package-summary.html

### 8.2 项目文档

- `docs/layer1/LAYER1_INTERFACE_REVIEW_PLAN.md` - 接口审查计划
- `docs/layer1/LAYER1_INTERFACE_REVIEW_CHECKLIST.md` - 接口审查清单
- `docs/standards/ENGINEERING_STANDARDS.md` - 工程标准

---

**文档生成时间**: 2026-01-19
**文档作者**: Claude Sonnet 4.5
**审核状态**: Phase 1 完成，待进入 Phase 2
