# fafafa.core.sync API 参考手册

**版本**: 1.0  
**更新日期**: 2025-12-03

## 目录

- [模块概览](#模块概览)
- [快速开始](#快速开始)
- [Guard 体系说明](#guard-体系说明)
- [基础同步原语](#基础同步原语)
- [高级同步原语](#高级同步原语)
- [命名同步原语](#命名同步原语)
- [工厂函数索引](#工厂函数索引)
- [性能参考](#性能参考)
- [最佳实践](#最佳实践)

---

## 模块概览

`fafafa.core.sync` 提供完整的同步原语支持，包括：

### 进程内同步
- `IMutex` - 互斥锁
- `IRecMutex` - 可重入互斥锁
- `IRWLock` - 读写锁（支持 Poisoning）
- `ISpin` - 自旋锁
- `ISem` - 信号量
- `IEvent` - 事件
- `ICondVar` - 条件变量
- `IBarrier` - 屏障
- `IWaitGroup` - Go 风格等待组
- `ILatch` - 倒计时门闩
- `IParker` - Rust 风格 Parker
- `IOnce` - 一次性初始化

### 跨进程同步
- `INamedMutex` - 命名互斥锁
- `INamedEvent` - 命名事件
- `INamedSemaphore` - 命名信号量
- `INamedBarrier` - 命名屏障
- `INamedRWLock` - 命名读写锁
- `INamedCondVar` - 命名条件变量

---

## 快速开始

### 导入模块

```pascal
uses
  fafafa.core.sync;  // 门面模块，导出所有接口
```

### 基本用法

```pascal
var
  M: IMutex;
begin
  M := MakeMutex;
  M.Acquire;
  try
    // 临界区代码
  finally
    M.Release;
  end;
end;
```

### RAII Guard 模式（推荐）

```pascal
var
  M: IMutex;
  G: ILockGuard;
begin
  M := MakeMutex;
  G := MakeLockGuard(M);  // 自动 Acquire
  // 临界区代码
  // 超出作用域时自动 Release
end;
```

---

## Guard 体系说明

`fafafa.core.sync` 提供三类 Guard，各有不同的职责和适用场景：

### 1. 基础锁守卫（ILockGuard / TLockGuard）

**职责**: RAII 风格的锁管理，构造时加锁，析构时解锁。

**适用场景**: 任何实现了 `ILock` 接口的锁（IMutex, IRecMutex, ISpin 等）。

```pascal
var
  M: IMutex;
  G: ILockGuard;
begin
  M := MakeMutex;
  G := MakeLockGuard(M);  // 自动 Acquire
  // 临界区代码
  // G 超出作用域时自动 Release
end;
```

### 2. 读写锁守卫（IRWLockReadGuard / IRWLockWriteGuard）

**职责**: IRWLock 的专用守卫，区分读锁和写锁。

**适用场景**: 使用 IRWLock 时，通过 `Read()` 或 `Write()` 方法获取。

```pascal
var
  RW: IRWLock;
  RG: IRWLockReadGuard;
  WG: IRWLockWriteGuard;
begin
  RW := MakeRWLock;
  
  // 读锁（多个读者可并发）
  RG := RW.Read;
  // 读取共享数据
  RG := nil;  // 释放读锁
  
  // 写锁（独占）
  WG := RW.Write;
  // 修改共享数据
  WG := nil;  // 释放写锁
end;
```

### 3. 泛型数据容器（TMutexGuard<T> / TRwLockGuard<T>）

**职责**: **锁 + 数据**的容器，确保只能在持有锁时访问数据。类似 Rust 的 `Mutex<T>` / `RwLock<T>`。

**适用场景**: 将数据与锁绑定，类型安全地保护访问。

```pascal
var
  Guard: specialize TMutexGuard<Integer>;
  Ptr: PInteger;
begin
  Guard := specialize TMutexGuard<Integer>.Create(42);
  try
    // 获取锁并访问数据
    Ptr := Guard.LockPtr;
    Ptr^ := Ptr^ + 1;
    Guard.Unlock;
    
    // 或使用便捷方法（内部自动加解锁）
    Guard.Update(procedure(var V: Integer) begin V := V * 2; end);
  finally
    Guard.Free;
  end;
end;
```

### Guard 类型对比

| 特性 | ILockGuard | IRWLock*Guard | TMutexGuard<T> |
|------|------------|---------------|----------------|
| **用途** | 通用锁守卫 | 读写锁守卫 | 数据+锁容器 |
| **类型安全** | ✘ 不绑定数据 | ✘ 不绑定数据 | ✔ 绑定数据 |
| **Rust 等价** | MutexGuard<'a> | RwLock*Guard | Mutex<T>/RwLock<T> |
| **用法** | 外部锁+Guard | RW.Read/Write | Guard.Lock/Update |

---

## 基础同步原语

### IMutex - 互斥锁

**工厂函数**:
```pascal
function MakeMutex: IMutex;
```

**接口方法**:
```pascal
IMutex = interface(ILock)
  procedure Acquire;              // 阻塞获取锁
  procedure Release;              // 释放锁
  function TryAcquire: Boolean;   // 非阻塞尝试获取
  function TryAcquire(ATimeoutMs: Cardinal): Boolean;  // 带超时获取
end;
```

**示例**:
```pascal
var
  M: IMutex;
begin
  M := MakeMutex;
  if M.TryAcquire(1000) then  // 1秒超时
  try
    // 操作共享资源
  finally
    M.Release;
  end;
end;
```

### IRecMutex - 可重入互斥锁

**工厂函数**:
```pascal
function MakeRecMutex: IRecMutex;
```

**特性**: 同一线程可多次获取，需要相同次数释放。

### IRWLock - 读写锁

**工厂函数**:
```pascal
function MakeRWLock: IRWLock;
function TRWLock.Create(const AOptions: TRWLockOptions): IRWLock;
```

**接口方法**:
```pascal
IRWLock = interface
  procedure AcquireRead;          // 获取读锁
  procedure ReleaseRead;          // 释放读锁
  procedure AcquireWrite;         // 获取写锁
  procedure ReleaseWrite;         // 释放写锁
  function Read: IRWLockReadGuard;    // RAII 读锁守卫
  function Write: IRWLockWriteGuard;  // RAII 写锁守卫
end;
```

**配置选项**:
```pascal
TRWLockOptions = record
  AllowReentrancy: Boolean;     // 允许重入（默认 True）
  FairMode: Boolean;            // 公平模式
  WriterPriority: Boolean;      // 写者优先
  MaxReaders: Integer;          // 最大读者数
  SpinCount: Integer;           // 自旋次数
  EnablePoisoning: Boolean;     // 启用 Poisoning（默认 True）
  ReaderBiasEnabled: Boolean;   // 读偏向优化
end;
```

**Poisoning 支持**:
```pascal
// 当 Panic 发生在持有锁期间，锁会被标记为 Poisoned
var
  RW: IRWLock;
  G: IRWLockWriteGuard;
begin
  RW := TRWLock.Create;
  G := RW.Write;
  // 如果此处发生异常，锁会被 poison
  
  // 检查 Poisoning
  if RW.IsPoisoned then
    WriteLn('Lock was poisoned!');
    
  // 恢复 Poisoned 锁
  RW.ClearPoison;
end;
```

### ISem - 信号量

**工厂函数**:
```pascal
function MakeSem(AInitialCount: Integer = 1; AMaxCount: Integer = 1): ISem;
```

**接口方法**:
```pascal
ISem = interface
  procedure Acquire;              // 减少计数（阻塞）
  procedure Release;              // 增加计数
  function TryAcquire: Boolean;   // 非阻塞尝试
  function GetCount: Integer;     // 当前计数
end;
```

### IEvent - 事件

**工厂函数**:
```pascal
function MakeEvent(AManualReset: Boolean = False; AInitialState: Boolean = False): IEvent;
```

**接口方法**:
```pascal
IEvent = interface
  procedure Signal;               // 设置事件
  procedure Reset;                // 重置事件
  procedure Wait;                 // 等待事件
  function Wait(ATimeoutMs: Cardinal): Boolean;  // 带超时等待
end;
```

### ICondVar - 条件变量

**工厂函数**:
```pascal
function MakeCondVar: ICondVar;
```

**接口方法**:
```pascal
ICondVar = interface
  procedure Wait(const ALock: ILock);      // 等待并释放锁
  function Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean;
  procedure Signal;                         // 唤醒一个等待者
  procedure Broadcast;                      // 唤醒所有等待者
end;
```

---

## 高级同步原语

### IWaitGroup - Go 风格等待组

**工厂函数**:
```pascal
function MakeWaitGroup: IWaitGroup;
```

**接口方法**:
```pascal
IWaitGroup = interface
  procedure Add(ADelta: Integer = 1);  // 增加计数
  procedure Done;                       // 减少计数（等同于 Add(-1)）
  procedure Wait;                       // 等待计数归零
  function Wait(ATimeout: TDuration): TWaitResult;  // 带超时等待
end;
```

**示例**:
```pascal
var
  WG: IWaitGroup;
begin
  WG := MakeWaitGroup;
  WG.Add(3);  // 3 个任务
  
  // 启动 3 个工作线程
  for I := 1 to 3 do
    TThread.CreateAnonymousThread(
      procedure
      begin
        try
          // 执行任务
        finally
          WG.Done;  // 完成后通知
        end;
      end
    ).Start;
    
  WG.Wait;  // 等待所有任务完成
end;
```

### ILatch - 倒计时门闩

**工厂函数**:
```pascal
function MakeLatch(ACount: Integer): ILatch;
```

**接口方法**:
```pascal
ILatch = interface
  procedure CountDown;                  // 减少计数
  procedure Wait;                       // 等待计数归零
  function Wait(ATimeout: TDuration): TWaitResult;
  function GetCount: Integer;           // 获取当前计数
end;
```

### IParker - Rust 风格 Parker

**工厂函数**:
```pascal
function MakeParker: IParker;
```

**接口方法**:
```pascal
IParker = interface
  procedure Park;                       // 阻塞当前线程
  function Park(ATimeout: TDuration): TWaitResult;  // 带超时阻塞
  procedure Unpark;                     // 唤醒被阻塞的线程
end;
```

### IBarrier - 屏障

**工厂函数**:
```pascal
function MakeBarrier(AParticipantCount: Integer): IBarrier;
```

### IOnce - 一次性初始化

**工厂函数**:
```pascal
function MakeOnce: IOnce;
function MakeOnce(const AProc: TOnceProc): IOnce;
```

**接口方法**:
```pascal
IOnce = interface
  procedure Do_(const AProc: TOnceProc);  // 确保只执行一次
  function IsDone: Boolean;               // 是否已执行
end;
```

---

## 命名同步原语

命名同步原语支持跨进程同步。

### INamedMutex - 命名互斥锁

**工厂函数**:
```pascal
function MakeNamedMutex(const AName: string): INamedMutex;
function MakeNamedMutex(const AName: string; AInitialOwner: Boolean): INamedMutex;
```

**示例**:
```pascal
var
  M: INamedMutex;
begin
  M := MakeNamedMutex('MyApp_Mutex');
  M.Acquire;
  try
    // 跨进程临界区
  finally
    M.Release;
  end;
end;
```

### INamedEvent - 命名事件

**工厂函数**:
```pascal
function MakeNamedEvent(const AName: string): INamedEvent;
function MakeNamedEvent(const AName: string; AManualReset: Boolean; AInitialState: Boolean): INamedEvent;
// 或使用新 API
function CreateNamedEvent(const AName: string; AManualReset: Boolean = False; AInitialState: Boolean = False): INamedEvent;
```

**接口方法**:
```pascal
INamedEvent = interface
  procedure Signal;                   // 触发事件
  procedure Reset;                    // 重置事件
  function Wait: INamedEventGuard;    // RAII 等待
  function TryWaitFor(ATimeoutMs: Cardinal): INamedEventGuard;
end;
```

### INamedSemaphore - 命名信号量

**工厂函数**:
```pascal
function MakeNamedSemaphore(const AName: string): INamedSemaphore;
function MakeNamedSemaphore(const AName: string; AInitialCount: Integer; AMaxCount: Integer): INamedSemaphore;
```

### INamedBarrier - 命名屏障

**工厂函数**:
```pascal
function MakeNamedBarrier(const AName: string; AParticipantCount: Integer): INamedBarrier;
```

### INamedRWLock - 命名读写锁

**工厂函数**:
```pascal
function MakeNamedRWLock(const AName: string): INamedRWLock;
```

---

## 工厂函数索引

### 进程内同步

| 函数 | 返回类型 | 描述 |
|------|----------|------|
| `MakeMutex` | `IMutex` | 创建互斥锁 |
| `MakeRecMutex` | `IRecMutex` | 创建可重入互斥锁 |
| `MakeRWLock` | `IRWLock` | 创建读写锁 |
| `MakeSpin` | `ISpin` | 创建自旋锁 |
| `MakeSem` | `ISem` | 创建信号量 |
| `MakeEvent` | `IEvent` | 创建事件 |
| `MakeCondVar` | `ICondVar` | 创建条件变量 |
| `MakeBarrier` | `IBarrier` | 创建屏障 |
| `MakeWaitGroup` | `IWaitGroup` | 创建等待组 |
| `MakeLatch` | `ILatch` | 创建门闩 |
| `MakeParker` | `IParker` | 创建 Parker |
| `MakeOnce` | `IOnce` | 创建一次性初始化 |

### 跨进程同步

| 函数 | 返回类型 | 描述 |
|------|----------|------|
| `MakeNamedMutex` | `INamedMutex` | 创建命名互斥锁 |
| `MakeNamedEvent` | `INamedEvent` | 创建命名事件 |
| `MakeNamedSemaphore` | `INamedSemaphore` | 创建命名信号量 |
| `MakeNamedBarrier` | `INamedBarrier` | 创建命名屏障 |
| `MakeNamedRWLock` | `INamedRWLock` | 创建命名读写锁 |

### Guard 工厂

| 函数 | 返回类型 | 描述 |
|------|----------|------|
| `MakeLockGuard` | `ILockGuard` | 创建锁守卫（自动获取锁） |
| `MakeLockGuardFromAcquired` | `ILockGuard` | 从已获取的锁创建守卫 |

---

## 性能参考

### 基准测试结果 (2025-12-03)

| 操作 | 延迟 (ns/op) | 吞吐量 |
|------|-------------|--------|
| **Mutex: Acquire/Release** | 23 | 43.2M ops/s |
| **RWLock Read (NoReentry)** | 106 | 9.4M ops/s |
| **RWLock Read (Reentrant)** | 1,942 | 515K ops/s |
| **RWLock Write** | 296 | 3.4M ops/s |
| **NamedMutex: Acquire/Release** | 78 | 12.7M ops/s |
| **NamedEvent: Signal/Reset** | 136 | 7.4M ops/s |
| **NamedMutex: Create/Destroy** | 34,146 | 29K ops/s |

### 性能建议

1. **热路径使用非重入 RWLock**: 设置 `AllowReentrancy := False` 可获得 12.5x 性能提升
2. **避免频繁创建 Named 原语**: 创建开销较大，应复用实例
3. **读多写少场景使用 RWLock**: 允许并发读取
4. **短临界区使用 Spin**: 避免上下文切换开销

---

## 最佳实践

### 1. 总是使用 RAII Guard

```pascal
// 推荐
var
  G: ILockGuard;
begin
  G := MakeLockGuard(Mutex);
  // 异常安全
end;

// 不推荐
begin
  Mutex.Acquire;
  try
    // 需要手动管理
  finally
    Mutex.Release;  // 容易遗忘
  end;
end;
```

### 2. 避免死锁

```pascal
// 总是按固定顺序获取多个锁
procedure SafeOperation;
begin
  Lock1.Acquire;
  try
    Lock2.Acquire;
    try
      // 操作
    finally
      Lock2.Release;
    end;
  finally
    Lock1.Release;
  end;
end;
```

### 3. 使用适当的同步原语

| 场景 | 推荐原语 |
|------|----------|
| 互斥访问 | `IMutex` |
| 读多写少 | `IRWLock` |
| 等待条件 | `ICondVar` |
| 等待多任务 | `IWaitGroup` |
| 一次性初始化 | `IOnce` |
| 跨进程同步 | `INamedMutex` 等 |

### 4. 命名原语命名约定

```pascal
// 建议格式: <应用名>_<模块名>_<用途>
MakeNamedMutex('MyApp_Database_Write');
MakeNamedEvent('MyApp_Cache_Invalidate');
```

---

## 错误处理

### 异常类型

```pascal
ESyncError          // 基础同步错误
ELockError          // 锁操作错误
ETimeoutError       // 超时错误
EDeadlockError      // 死锁检测
```

### 等待结果

```pascal
TWaitResult = (
  wrSignaled,       // 成功获取
  wrTimeout,        // 超时
  wrAbandoned,      // 被放弃（拥有者异常终止）
  wrError,          // 错误
  wrInterrupted     // 被中断
);
```

---

## 参考链接

- [生产就绪性报告](SYNC_PRODUCTION_READINESS_REPORT.md)
- [RWLock 实现总结](fafafa.core.sync.rwlock.IMPLEMENTATION_SUMMARY.md)
- [自旋锁设计](fafafa.core.sync.spin.md)
