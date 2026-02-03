# fafafa.core.sync.guards

同步原语 Guard 基类 - RAII 风格资源管理的公共基础设施。

## 概述

`fafafa.core.sync.guards` 模块提供了同步原语 Guard 的公共基类和工具函数。它消除了各平台实现中的代码重复，为命名同步原语（Named Sync）提供统一的 RAII Guard 基础设施。

## 设计理念

RAII (Resource Acquisition Is Initialization) 是一种资源管理模式：
- **获取即初始化**: 在构造函数中获取资源
- **析构即释放**: 在析构函数中释放资源
- **异常安全**: 即使发生异常，资源也能正确释放

## 安装

```pascal
uses
  fafafa.core.sync.guards;
```

## 类层次结构

```
TNamedGuardBase
    ├── TTypedGuardBase<THandle>    (简单锁 Guard)
    ├── TRWLockGuardBase            (读写锁 Guard)
    └── TBarrierGuardBase           (屏障 Guard)
```

## API 参考

### TNamedGuardBase 基类

所有 Guard 的公共基类。

```pascal
type
  TNamedGuardBase = class(TInterfacedObject)
  protected
    // 执行实际的资源释放，派生类必须重写
    procedure DoRelease; virtual; abstract;

    // 检查 Guard 是否已释放
    procedure CheckNotReleased;

    // 标记为已释放状态
    procedure MarkReleased;

    // 获取释放状态
    function GetReleased: Boolean;
  public
    constructor Create(const AName: string);
    destructor Destroy; override;

    // 获取关联的资源名称
    function GetName: string;

    // 检查是否仍持有锁
    function IsLocked: Boolean;

    // 手动释放资源
    procedure Release;

    property Name: string read FName;
    property Released: Boolean read FReleased;
  end;
```

### TTypedGuardBase<THandle> 泛型基类

用于简单锁（Mutex、Semaphore 等）的 Guard 基类。

```pascal
type
  generic TTypedGuardBase<THandle> = class(TNamedGuardBase)
  protected
    property Handle: THandle read FHandle;
  public
    constructor Create(AHandle: THandle; const AName: string);
  end;
```

### TRWLockGuardBase 基类

用于读写锁的 Guard 基类。

```pascal
type
  TRWLockGuardBase = class(TNamedGuardBase)
  protected
    property Lock: Pointer read FLock;
  public
    constructor Create(ALock: Pointer; const AName: string);
  end;
```

### TBarrierGuardBase 基类

用于屏障（Barrier）等待结果的 Guard 基类。

```pascal
type
  TBarrierGuardBase = class(TNamedGuardBase)
  protected
    FBarrier: Pointer;
    FIsLastParticipant: Boolean;
    FGeneration: Cardinal;
    FWaitTime: Cardinal;
  public
    constructor Create(ABarrier: Pointer; const AName: string;
                       AIsLast: Boolean; AGen, AWaitTime: Cardinal);

    // 是否是最后到达的参与者
    function IsLastParticipant: Boolean;

    // 获取代数（generation）
    function GetGeneration: Cardinal;

    // 获取等待时间
    function GetWaitTime: Cardinal;
  end;
```

## 使用示例

### 派生自定义 Guard

```pascal
type
  // Unix 平台的 Mutex Guard
  TUnixMutexGuard = class(specialize TTypedGuardBase<pthread_mutex_t>)
  protected
    procedure DoRelease; override;
  end;

procedure TUnixMutexGuard.DoRelease;
begin
  pthread_mutex_unlock(@Handle);
end;
```

### 使用 Guard 的自动释放

```pascal
var
  Guard: INamedMutexGuard;
begin
  Guard := NamedMutex.Lock;
  // 临界区代码
  DoSomething();
  // Guard 离开作用域时自动释放锁
end;
```

### 手动释放

```pascal
var
  Guard: INamedMutexGuard;
begin
  Guard := NamedMutex.Lock;
  try
    DoSomething();
  finally
    Guard.Release;  // 显式释放
  end;
end;
```

### 检查 Guard 状态

```pascal
var
  Guard: INamedMutexGuard;
begin
  Guard := NamedMutex.Lock;

  WriteLn('资源名称: ', Guard.Name);
  WriteLn('是否持有锁: ', Guard.IsLocked);

  Guard.Release;

  WriteLn('释放后是否持有锁: ', Guard.IsLocked);  // False
end;
```

## 异常安全

Guard 基类确保即使发生异常，资源也能正确释放：

```pascal
procedure ProcessWithLock;
var
  Guard: INamedMutexGuard;
begin
  Guard := NamedMutex.Lock;

  DoSomethingThatMightFail();  // 即使抛出异常

  // Guard 的析构函数会自动调用 DoRelease
end;
```

## 双重释放保护

Guard 基类防止双重释放：

```pascal
var
  Guard: INamedMutexGuard;
begin
  Guard := NamedMutex.Lock;
  Guard.Release;   // 第一次释放
  Guard.Release;   // 安全：不会重复释放
end;
```

## 内部实现细节

### 释放流程

```
Release() 调用
    │
    ▼
CheckNotReleased() ─► 已释放? ─► 直接返回
    │
    ▼ 未释放
DoRelease()  ─► 派生类实现实际释放逻辑
    │
    ▼
MarkReleased()  ─► 标记为已释放状态
```

### 析构流程

```
Destroy() 调用
    │
    ▼
检查 FReleased
    │
    ├─► True: 什么都不做
    │
    └─► False: 调用 Release()
```

## 设计模式

Guard 基类实现了以下设计模式：

1. **模板方法模式**: `Release()` 定义算法骨架，`DoRelease()` 由派生类实现
2. **RAII 模式**: 资源在构造时获取，在析构时释放
3. **接口隔离**: 通过接口暴露公共 API，隐藏实现细节

## 相关模块

- `fafafa.core.sync.namedMutex` - 使用 Guard 的命名互斥锁
- `fafafa.core.sync.namedRWLock` - 使用 Guard 的命名读写锁
- `fafafa.core.sync.namedBarrier` - 使用 Guard 的命名屏障

## 版本历史

- v1.0.0 (2025-12): 初始版本，提供 Guard 基类层次结构
