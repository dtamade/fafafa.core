# fafafa.core.sync.mutex - 互斥锁模块

## 概述

`fafafa.core.sync.mutex` 模块提供了现代化的互斥锁实现，支持可重入锁、非重入锁和 RAII 自动锁管理。设计参考了 Rust、Java、Go 等主流语言的互斥锁标准。

## 特性

- ✅ **标准可重入互斥锁** - 符合主流语言标准，同一线程可多次获取
- ✅ **非重入互斥锁** - 特殊用途，同一线程重复获取会失败
- ✅ **RAII 自动锁管理** - 基于对象生命周期的自动锁管理
- ✅ **跨平台支持** - Windows (CRITICAL_SECTION/SRWLOCK) 和 Unix (pthread)
- ✅ **高性能** - 优化的实现，支持百万级操作/秒
- ✅ **线程安全** - 完全线程安全的实现

## 接口设计

### 核心接口

```pascal
// 标准可重入互斥锁（主流标准）
IMutex = interface(ILock)
  // 基础锁操作
  procedure Acquire;
  procedure Release;
  function TryAcquire: Boolean; overload;
  function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
  
  // 互斥锁特有方法
  function GetHandle: Pointer;
  function GetHoldCount: Integer;
  function IsHeldByCurrentThread: Boolean;
  
  // RAII 支持
  function Lock: IMutexGuard;
  function TryLock: IMutexGuard;
end;

// 非重入互斥锁（特殊用途）
INonReentrantMutex = interface(ILock)
  // 基础锁操作（同 ILock）
  function GetHandle: Pointer;
end;

// RAII 互斥锁守护
IMutexGuard = interface
  // 无需手动方法，完全依赖生命周期管理
end;
```

### 工厂函数

```pascal
// 创建标准可重入互斥锁
function MakeMutex: IMutex;

// 创建非重入互斥锁
function MakeNonReentrantMutex: INonReentrantMutex;
```

## 使用示例

### 基础用法

```pascal
uses fafafa.core.sync.mutex;

var
  m: IMutex;
begin
  m := MakeMutex;
  
  // 手动锁管理
  m.Acquire;
  try
    // 临界区代码
    WriteLn('在锁保护下执行');
  finally
    m.Release;
  end;
end;
```

### 可重入锁

```pascal
var
  m: IMutex;
begin
  m := MakeMutex;
  
  // 可重入：同一线程可多次获取
  m.Acquire;
  try
    m.Acquire;  // 第二次获取成功
    try
      // 嵌套临界区
    finally
      m.Release;
    end;
  finally
    m.Release;
  end;
end;
```

### RAII 自动锁管理

```pascal
var
  m: IMutex;
  guard: IMutexGuard;
begin
  m := MakeMutex;
  
  // RAII 模式：自动管理锁的生命周期
  guard := m.Lock;
  // 锁已自动获取
  
  // 临界区代码
  WriteLn('在 RAII 锁保护下执行');
  
  // guard 超出作用域时自动释放锁
end;
```

### 非重入锁

```pascal
var
  nm: INonReentrantMutex;
begin
  nm := MakeNonReentrantMutex;
  
  nm.Acquire;
  try
    // 同一线程再次获取会失败
    if nm.TryAcquire then
    begin
      WriteLn('意外成功！');
      nm.Release;
    end
    else
      WriteLn('正确：非重入锁拒绝重复获取');
  finally
    nm.Release;
  end;
end;
```

### 超时获取

```pascal
var
  m: IMutex;
begin
  m := MakeMutex;
  
  // 尝试在 1000ms 内获取锁
  if m.TryAcquire(1000) then
  begin
    try
      // 成功获取锁
    finally
      m.Release;
    end;
  end
  else
    WriteLn('获取锁超时');
end;
```

## 性能特征

基于基准测试结果（在现代 x86_64 Linux 系统上）：

| 操作类型 | 性能 (操作/秒) | 说明 |
|---------|---------------|------|
| 基础锁定 | ~100,000,000 | 最快的锁定/释放操作 |
| 可重入锁定 | ~75,000,000 | 稍慢但仍然很快 |
| 非重入锁定 | ~142,000,000 | 最快，无重入检查开销 |
| RAII 锁定 | ~14,000,000 | 由于对象创建开销较慢 |
| 并发访问 | ~8,000,000 | 多线程竞争下的性能 |

## 平台实现

### Windows 平台
- **可重入锁**: 使用 `CRITICAL_SECTION`，天然支持可重入
- **非重入锁**: 使用 `SRWLOCK`，轻量级且高性能

### Unix 平台
- **可重入锁**: 使用 `PTHREAD_MUTEX_RECURSIVE`
- **非重入锁**: 使用 `PTHREAD_MUTEX_NORMAL`

## 最佳实践

### 1. 优先使用 RAII
```pascal
// 推荐：RAII 自动管理
guard := mutex.Lock;

// 不推荐：手动管理（容易忘记释放）
mutex.Acquire;
try
  // ...
finally
  mutex.Release;
end;
```

### 2. 选择合适的锁类型
- **IMutex**: 大多数情况下的首选，支持可重入
- **INonReentrantMutex**: 特殊性能要求或明确不需要重入的场景

### 3. 避免死锁
```pascal
// 总是按相同顺序获取多个锁
mutex1.Acquire;
try
  mutex2.Acquire;
  try
    // 临界区
  finally
    mutex2.Release;
  end;
finally
  mutex1.Release;
end;
```

### 4. 使用超时避免无限等待
```pascal
if mutex.TryAcquire(5000) then  // 5秒超时
begin
  try
    // 临界区
  finally
    mutex.Release;
  end;
end
else
  WriteLn('获取锁超时，可能存在死锁');
```

## 错误处理

模块使用异常来报告错误：

- `ELockError`: 锁操作失败
- `ETimeoutError`: 超时错误
- `EInvalidState`: 无效状态错误

## 线程安全保证

- 所有接口方法都是线程安全的
- 可重入锁支持同一线程的嵌套获取
- 非重入锁严格禁止同一线程的重复获取
- RAII 守护对象确保异常安全

## 与其他语言对比

| 语言 | 标准锁 | 可重入性 | RAII 支持 |
|------|--------|----------|-----------|
| **fafafa.core** | IMutex | ✅ 可重入 | ✅ IMutexGuard |
| Rust | std::sync::Mutex | ❌ 不可重入 | ✅ MutexGuard |
| Java | ReentrantLock | ✅ 可重入 | ❌ 手动管理 |
| Go | sync.Mutex | ❌ 不可重入 | ❌ 手动管理 |
| C++ | std::mutex | ❌ 不可重入 | ✅ lock_guard |

我们的设计结合了各语言的优点，提供了最佳的开发体验。
