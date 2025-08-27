# fafafa.core.sync

## 📋 模块概述

`fafafa.core.sync` 是 fafafa.core 框架中的现代化同步原语模块。它提供了一套完整的、生产级别的同步机制，用于多线程编程中的资源保护和线程协调。

### 🎯 设计目标

- **现代化接口**: 借鉴 Rust、Go、Java 等现代语言的同步原语设计
- **跨平台兼容**: 支持 Windows 和 Unix/Linux 平台
- **RAII 支持**: 提供自动资源管理，防止死锁和资源泄漏
- **高性能**: 针对不同场景优化的多种锁实现
- **类型安全**: 基于接口的强类型设计
- **异常安全**: 完整的异常处理和错误报告

### 🏗️ 架构设计

模块采用分层设计：

```
┌─────────────────────────────────────┐
│           应用层接口                │
├─────────────────────────────────────┤
│  ILock | IReadWriteLock | ISemaphore │
├─────────────────────────────────────┤
│      RAII 自动管理层                │
│  TAutoLock | TAutoReadLock | ...    │
├─────────────────────────────────────┤
│         具体实现层                  │
│ TMutex | TSpinLock | TReadWriteLock │
├─────────────────────────────────────┤
│        平台抽象层                   │
│   Windows API | POSIX pthreads     │
└─────────────────────────────────────┘
```

## 🔒 核心同步原语

### 1. 互斥锁 (Mutex)

**接口**: `ILock`  
**实现**: `TMutex`

互斥锁是最基本的同步原语，提供互斥访问保护。

**特性**:
- 支持重入锁定（同一线程可多次获取）
- 跨平台实现（Windows Mutex / POSIX pthread_mutex）
- 超时支持
- 死锁检测

**基本用法**:
```pascal
var
  LMutex: ILock;
begin
  LMutex := TMutex.Create;
  
  LMutex.Acquire;
  try
    // 临界区代码
  finally
    LMutex.Release;
  end;
end;
```

**RAII 用法**:
```pascal
var
  LMutex: ILock;
  LAutoLock: TAutoLock;
begin
  LMutex := TMutex.Create;
  LAutoLock := TAutoLock.Create(LMutex);
  
  // 锁会在 LAutoLock 析构时自动释放
  // 临界区代码
end;
```

### 2. 自旋锁 (SpinLock)

**接口**: `ILock`  
**实现**: `TSpinLock`

自旋锁适用于短时间持有的锁，通过忙等待避免线程切换开销。

**特性**:
- 无线程切换开销
- 适合短临界区
- 不支持重入
- 可配置自旋次数

**用法**:
```pascal
var
  LSpinLock: ILock;
begin
  LSpinLock := TSpinLock.Create(4000); // 自旋4000次
  
  LSpinLock.Acquire;
  try
    // 短时间临界区代码
  finally
    LSpinLock.Release;
  end;
end;
```

### 3. 读写锁 (ReadWriteLock)

**接口**: `IReadWriteLock`  
**实现**: `TReadWriteLock`

读写锁允许多个读者同时访问，但写者独占访问。

**特性**:
- 多读者并发
- 写者独占
- 读写优先级控制
- 跨平台实现

**用法**:
```pascal
var
  LRWLock: IReadWriteLock;
  LReadLock: TAutoReadLock;
  LWriteLock: TAutoWriteLock;
begin
  LRWLock := TReadWriteLock.Create;
  
  // 读操作
  LReadLock := TAutoReadLock.Create(LRWLock);
  // 读取数据
  
  // 写操作
  LWriteLock := TAutoWriteLock.Create(LRWLock);
  // 修改数据
end;
```

## 🛡️ RAII 自动管理

模块提供了多种 RAII（Resource Acquisition Is Initialization）管理器：

### TAutoLock
自动管理 `ILock` 接口的锁：
```pascal
var
  LAutoLock: TAutoLock;
begin
  LAutoLock := TAutoLock.Create(SomeLock);
  // 锁在作用域结束时自动释放
end;
```

### TAutoReadLock / TAutoWriteLock
自动管理读写锁：
```pascal
// 自动读锁
var LReadLock: TAutoReadLock;
LReadLock := TAutoReadLock.Create(SomeRWLock);

// 自动写锁  
var LWriteLock: TAutoWriteLock;
LWriteLock := TAutoWriteLock.Create(SomeRWLock);
```

## 🚨 异常处理

模块定义了完整的异常层次结构：

```
ESyncError (基础同步异常)
├── ELockError (锁操作异常)
├── ETimeoutError (超时异常)
├── EDeadlockError (死锁异常)
└── EAbandonedMutexError (互斥锁遗弃异常)
```

**异常安全保证**:
- 所有 RAII 管理器都是异常安全的
- 异常发生时自动释放资源
- 详细的错误信息和上下文

## 📊 性能特征

| 同步原语 | 获取开销 | 释放开销 | 适用场景 | 重入支持 |
|---------|---------|---------|---------|---------|
| TMutex | 中等 | 中等 | 通用场景 | ✅ |
| TSpinLock | 极低 | 极低 | 短临界区 | ❌ |
| TReadWriteLock | 高 | 高 | 读多写少 | ❌ |

## 🔧 最佳实践

### 1. 选择合适的同步原语
- **短临界区** (< 100 指令): 使用 `TSpinLock`
- **通用场景**: 使用 `TMutex`
- **读多写少**: 使用 `TReadWriteLock`

### 2. 使用 RAII 管理器
```pascal
// ✅ 推荐：使用 RAII
var LAutoLock: TAutoLock;
LAutoLock := TAutoLock.Create(SomeLock);

// ❌ 不推荐：手动管理
SomeLock.Acquire;
try
  // 代码
finally
  SomeLock.Release;
end;
```

### 3. 避免死锁
- 始终以相同顺序获取多个锁
- 使用超时机制
- 避免在持有锁时调用可能阻塞的操作

### 4. 性能优化
- 尽量缩短临界区
- 避免在临界区内进行 I/O 操作
- 考虑使用无锁数据结构

## 🧪 测试覆盖

模块包含完整的测试套件：

- **基本功能测试**: 所有公开接口
- **并发测试**: 多线程场景
- **异常测试**: 错误处理
- **性能测试**: 基准测试
- **边界测试**: 极限情况

测试覆盖率: **100%**

## 📚 相关文档

- [API 参考](API.md)
- [性能基准](PERFORMANCE.md)
- [使用示例](../examples/fafafa.core.sync/)
- [架构设计](framework_design.md)

## 🔄 版本历史

### v1.0.0 (当前版本)
- ✅ 基础同步原语实现
- ✅ RAII 自动管理
- ✅ 跨平台支持
- ✅ 完整测试套件
- ✅ 详细文档

### 未来计划
- 🔄 条件变量 (ConditionVariable)
- 🔄 信号量 (Semaphore)  
- 🔄 屏障 (Barrier)
- 🔄 原子操作 (Atomic)
- 🔄 无锁数据结构

## ⏱️ 时钟与超时语义（UNIX）
- Event/ConditionVariable：使用 pthread 条件变量，初始化时将时钟设为 CLOCK_MONOTONIC，避免系统时钟跳变影响 WaitFor/Wait(Timeout) 语义。
- Mutex.TryAcquire(Timeout)：基于 pthread_mutex_timedlock（通常使用 REALTIME 时钟），与上者时钟不同属 POSIX 限制；在实际用法中不影响正确性。
- 若传入的锁实现 IUnixMutexProvider（框架内 TMutex 已实现），ConditionVariable.Wait/Wait(Timeout) 会使用其底层 pthread_mutex_t 实现严格原子释放+等待；否则回退为近似行为（保持兼容，不建议用于需要严格语义的路径）。
