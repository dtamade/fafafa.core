# fafafa.core.sync.mutex API 参考

## 模块概述

`fafafa.core.sync.mutex` 模块提供了高性能、跨平台的互斥锁实现。

## 接口定义

### IMutex

非重入互斥锁接口，继承自 `ITryLock`。

```pascal
IMutex = interface(ITryLock)
  ['{55391DAE-AC96-4911-B998-FC8D2675FA2A}']
  function GetHandle: Pointer;
end;
```

#### 继承的方法

从 `ITryLock` 继承：

- `procedure Acquire`：获取锁（阻塞）
- `procedure Release`：释放锁
- `function TryAcquire: Boolean`：尝试获取锁（非阻塞）
- `function TryAcquire(ATimeoutMs: Cardinal): Boolean`：带超时的获取锁
- `function LockGuard: ILockGuard`：创建锁保护器

从 `ISynchronizable` 继承：

- `function GetData: Pointer`：获取用户数据
- `procedure SetData(aData: Pointer)`：设置用户数据

#### 特有方法

##### GetHandle

```pascal
function GetHandle: Pointer;
```

**描述**：获取平台特定的锁句柄

**返回值**：
- Windows：指向 `CRITICAL_SECTION` 或 `SRWLOCK` 的指针
- Unix：指向 `pthread_mutex_t` 或 futex 变量的指针

**用途**：用于与底层 API 交互或调试

**示例**：
```pascal
var
  Mutex: IMutex;
  Handle: Pointer;
begin
  Mutex := MakeMutex;
  Handle := Mutex.GetHandle;
  // 可以将 Handle 传递给底层 API
end;
```

## 类型定义

### TMutex

平台特定的互斥锁实现类型别名。

```pascal
{$IFDEF WINDOWS}
TMutex = fafafa.core.sync.mutex.windows.TMutex;
{$ENDIF}
{$IFDEF UNIX}
TMutex = fafafa.core.sync.mutex.unix.TMutex;
{$ENDIF}
```

**说明**：
- 在 Windows 平台，`TMutex` 是 `fafafa.core.sync.mutex.windows.TMutex`
- 在 Unix 平台，`TMutex` 是 `fafafa.core.sync.mutex.unix.TMutex`

## 全局函数

### MakeMutex

```pascal
function MakeMutex: IMutex;
```

**描述**：创建一个新的互斥锁实例

**参数**：无

**返回值**：`IMutex` 接口实例

**实现选择**：
- Windows：优先使用 SRWLOCK（Vista+），回退到 CRITICAL_SECTION
- Unix：优先使用 futex（Linux），回退到 pthread_mutex

**异常**：
- `ELockError`：锁初始化失败

**示例**：
```pascal
var
  Mutex: IMutex;
begin
  Mutex := MakeMutex;
  // 使用 Mutex...
end;
```

### MutexGuard

```pascal
function MutexGuard: ILockGuard;
```

**描述**：创建一个新的互斥锁并返回其锁保护器

**参数**：无

**返回值**：`ILockGuard` 接口实例，自动管理锁的生命周期

**行为**：
- 创建新的互斥锁
- 立即获取锁
- 返回锁保护器，在销毁时自动释放锁

**异常**：
- `ELockError`：锁初始化或获取失败

**示例**：
```pascal
procedure SafeOperation;
var
  Guard: ILockGuard;
begin
  Guard := MutexGuard;  // 自动获取锁
  // 临界区代码
  // Guard 超出作用域时自动释放锁
end;
```

## 继承的接口方法详解

### Acquire

```pascal
procedure Acquire;
```

**描述**：获取互斥锁（阻塞操作）

**行为**：
- 如果锁可用，立即获取并返回
- 如果锁被其他线程持有，阻塞等待直到锁可用
- 如果当前线程已持有锁，抛出异常（非重入）

**异常**：
- `ELockError`：重入检测或锁操作失败

**线程安全**：是

**示例**：
```pascal
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

### Release

```pascal
procedure Release;
```

**描述**：释放互斥锁

**前提条件**：当前线程必须持有锁

**行为**：
- 检查锁的所有权
- 释放锁，允许其他线程获取

**异常**：
- `ELockError`：当前线程未持有锁

**线程安全**：是（仅限锁的持有者）

**示例**：
```pascal
Mutex.Acquire;
try
  // 临界区代码
finally
  Mutex.Release;  // 确保锁被释放
end;
```

### TryAcquire (无参数版本)

```pascal
function TryAcquire: Boolean;
```

**描述**：尝试获取互斥锁（非阻塞操作）

**返回值**：
- `True`：成功获取锁
- `False`：锁被其他线程持有或检测到重入

**行为**：
- 如果锁可用，立即获取并返回 `True`
- 如果锁不可用，立即返回 `False`，不阻塞
- 如果检测到重入，返回 `False`

**线程安全**：是

**示例**：
```pascal
if Mutex.TryAcquire then
begin
  try
    // 临界区代码
  finally
    Mutex.Release;
  end;
end
else
begin
  // 无法获取锁，执行替代逻辑
end;
```

### TryAcquire (带超时版本)

```pascal
function TryAcquire(ATimeoutMs: Cardinal): Boolean;
```

**描述**：在指定时间内尝试获取互斥锁

**参数**：
- `ATimeoutMs`：超时时间（毫秒），0 表示立即返回

**返回值**：
- `True`：在超时前成功获取锁
- `False`：超时或检测到重入

**行为**：
- 在指定时间内重复尝试获取锁
- 如果在超时前获取成功，返回 `True`
- 如果超时，返回 `False`

**线程安全**：是

**示例**：
```pascal
if Mutex.TryAcquire(1000) then  // 等待最多 1 秒
begin
  try
    // 临界区代码
  finally
    Mutex.Release;
  end;
end
else
begin
  // 超时，执行替代逻辑
end;
```

### LockGuard

```pascal
function LockGuard: ILockGuard;
```

**描述**：创建锁保护器，自动管理锁的生命周期

**返回值**：`ILockGuard` 接口实例

**行为**：
- 立即获取锁
- 返回保护器对象
- 保护器销毁时自动释放锁

**异常**：
- `ELockError`：获取锁失败

**示例**：
```pascal
var
  Mutex: IMutex;
  Guard: ILockGuard;
begin
  Mutex := MakeMutex;
  Guard := Mutex.LockGuard;  // 自动获取锁
  // 临界区代码
  // Guard 超出作用域时自动释放锁
end;
```

## 异常类型

### ELockError

```pascal
ELockError = class(ESyncError);
```

**描述**：锁操作相关的异常

**常见情况**：
- 重入检测：同一线程重复获取非重入锁
- 所有权错误：线程尝试释放不属于它的锁
- 系统错误：底层锁操作失败

### ETimeoutError

```pascal
ETimeoutError = class(ESyncError);
```

**描述**：超时相关的异常

**使用场景**：某些实现可能在超时时抛出异常而不是返回 `False`

## 性能特性

### Windows 实现

#### CRITICAL_SECTION 版本
- **优点**：兼容 Windows XP+，成熟稳定
- **缺点**：相对较重，内存占用较大
- **适用场景**：需要兼容老版本 Windows

#### SRWLOCK 版本
- **优点**：轻量级，性能优异，内存占用小
- **缺点**：仅支持 Windows Vista+
- **适用场景**：现代 Windows 应用

### Unix 实现

#### pthread_mutex 版本
- **优点**：兼容所有 Unix 系统，标准化
- **缺点**：性能一般，系统调用开销
- **适用场景**：需要最大兼容性

#### futex 版本
- **优点**：高性能，用户态快速路径
- **缺点**：仅支持 Linux，实现复杂
- **适用场景**：Linux 高性能应用

## 编译配置

### Windows

```pascal
// 启用 SRWLOCK 实现（默认开启）
{$DEFINE FAFAFA_CORE_USE_SRWLOCK}
```

### Unix

```pascal
// 启用 futex 实现（默认开启）
{$DEFINE FAFAFA_CORE_USE_FUTEX}
```

## 内存模型

### 内存屏障

所有锁操作都包含适当的内存屏障：

- `Acquire`：获取屏障（acquire barrier）
- `Release`：释放屏障（release barrier）

### 可见性保证

- 在 `Release` 之前的所有内存操作对后续 `Acquire` 的线程可见
- 符合 C++11 内存模型的 acquire-release 语义

## 调试支持

### 调试宏

```pascal
{$IFDEF DEBUG}
  {$DEFINE FAFAFA_SYNC_DEBUG}
{$ENDIF}
```

### 调试信息

启用调试模式后，锁操作会记录额外信息：
- 锁的创建和销毁
- 获取和释放操作
- 线程 ID 和时间戳
- 重入检测详情

## 相关类型

### ILockGuard

```pascal
ILockGuard = interface
  ['{A8F5A2E1-4C3D-4F2A-9B1E-8D7C6A5F4E3D}']
  procedure Release;
end;
```

RAII 风格的锁保护器，自动管理锁的生命周期。

### ISynchronizable

```pascal
ISynchronizable = interface
  ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
  function GetData: Pointer;
  procedure SetData(aData: Pointer);
  property Data: Pointer read GetData write SetData;
end;
```

所有同步对象的基础接口，提供用户数据存储功能。
