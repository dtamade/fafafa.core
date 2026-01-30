# ⚠️ DEPRECATED（已归档）

此文档内容与当前实现存在偏差，仅作为历史参考保留。

- 当前模块文档：`docs/fafafa.core.sync.once.md`
- 代码实现：`src/fafafa.core.sync.once.pas`、`src/fafafa.core.sync.once.base.pas`

---

# fafafa.core.sync.once - 跨平台高性能一次性执行实现

## 📖 概述

`fafafa.core.sync.once` 是一个现代化、跨平台的 FreePascal 一次性执行实现，提供统一的 API 接口，确保某个操作在多线程环境中只被执行一次。

## 🔧 特性

- **跨平台支持**：Windows、Linux、macOS、FreeBSD 等
- **高性能实现**：使用平台原生 API 和优化算法
- **线程安全**：支持多线程并发访问
- **异常安全**：自动资源管理和毒化状态处理
- **现代语义**：借鉴 Go sync.Once、Rust std::sync::Once 设计

## 🏗️ 架构设计

### 平台实现

**Windows 平台**：
- 基于 InterlockedCompareExchange + CRITICAL_SECTION 实现
- 高性能原子快速路径 + 慢速路径设计
- 支持异常恢复和毒化状态管理

**Unix/Linux 平台**：
- 基于原子操作 + pthread_mutex_t 实现
- 跨 Unix 系统兼容性 (Linux, macOS, FreeBSD 等)
- 内存屏障和缓存行对齐优化

### 接口设计

```pascal
type
  TOnceState = (osNotStarted, osInProgress, osCompleted, osPoisoned);
  
  IOnce = interface
    ['{B8F7E2A1-4C3D-4E5F-9A8B-7C6D5E4F3A2B}']
    
    // 核心执行方法
    procedure Execute; overload;
    procedure Execute(ACallback: TOnceCallback); overload;
    procedure ExecuteForce; overload;
    procedure ExecuteForce(ACallback: TOnceCallback); overload;
    
    // 等待方法
    procedure Wait;
    procedure WaitForce;
    
    // 状态查询
    function State: TOnceState;
    function Completed: Boolean;
    function Poisoned: Boolean;
  end;
```

## 🚀 快速开始

### 基本使用

```pascal
uses
  fafafa.core.sync.once;

var
  Once: IOnce;
  InitCount: Integer = 0;

procedure InitializeResource;
begin
  Inc(InitCount);
  WriteLn('资源初始化完成');
end;

begin
  Once := MakeOnce(@InitializeResource);
  
  // 多次调用，但只执行一次
  Once.Execute;  // 输出: 资源初始化完成
  Once.Execute;  // 不执行
  Once.Execute;  // 不执行
  
  WriteLn('初始化次数: ', InitCount);  // 输出: 1
end.
```

### 多线程使用

```pascal
type
  TWorkerThread = class(TThread)
  private
    FOnce: IOnce;
    FThreadId: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AOnce: IOnce; AThreadId: Integer);
  end;

constructor TWorkerThread.Create(AOnce: IOnce; AThreadId: Integer);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FOnce := AOnce;
  FThreadId := AThreadId;
end;

procedure TWorkerThread.Execute;
begin
  WriteLn(Format('线程 %d: 开始工作', [FThreadId]));
  
  // 等待初始化完成
  FOnce.Wait;
  
  WriteLn(Format('线程 %d: 初始化完成，继续工作', [FThreadId]));
end;

var
  Once: IOnce;
  Threads: array[0..4] of TWorkerThread;
  i: Integer;

procedure GlobalInit;
begin
  Sleep(100); // 模拟初始化工作
  WriteLn('全局初始化完成');
end;

begin
  Once := MakeOnce(@GlobalInit);
  
  // 创建多个线程
  for i := 0 to High(Threads) do
    Threads[i] := TWorkerThread.Create(Once, i);
  
  // 在某个线程中触发初始化
  Once.Execute;
  
  // 等待所有线程完成
  for i := 0 to High(Threads) do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
end.
```

## 📚 API 参考

### 工厂函数

#### `MakeOnce(): IOnce`
创建一个新的一次性执行实例，不预设回调函数。

#### `MakeOnce(ACallback: TOnceCallback): IOnce`
创建一个新的一次性执行实例，预设回调函数。

### 核心方法

#### `Execute()`
执行预设的回调函数（如果有）。如果没有预设回调，则标记为已完成状态。

#### `Execute(ACallback: TOnceCallback)`
执行指定的回调函数。如果已经执行过，则忽略此次调用。

#### `ExecuteForce()`
强制执行预设的回调函数，忽略毒化状态。

#### `ExecuteForce(ACallback: TOnceCallback)`
强制执行指定的回调函数，忽略毒化状态。

### 等待方法

#### `Wait()`
等待一次性执行完成。如果处于毒化状态，抛出异常。

#### `WaitForce()`
等待一次性执行完成，忽略毒化状态。

### 状态查询

#### `State(): TOnceState`
返回当前状态：
- `osNotStarted`: 尚未开始
- `osInProgress`: 正在执行中
- `osCompleted`: 已完成
- `osPoisoned`: 已毒化（执行失败）

#### `Completed: Boolean`
返回是否已完成执行。

#### `Poisoned: Boolean`
返回是否处于毒化状态。

## ⚠️ 异常处理

### 毒化状态

当回调函数执行过程中抛出异常时，once 实例会进入毒化状态：

```pascal
var
  Once: IOnce;

procedure FailingCallback;
begin
  raise Exception.Create('初始化失败');
end;

begin
  Once := MakeOnce(@FailingCallback);
  
  try
    Once.Execute;
  except
    on E: Exception do
      WriteLn('捕获异常: ', E.Message);
  end;
  
  WriteLn('状态: ', Ord(Once.State));     // 输出: 3 (osPoisoned)
  WriteLn('已毒化: ', Once.Poisoned);    // 输出: True
  
  // 后续调用会抛出异常
  try
    Once.Execute(@SomeOtherCallback);
  except
    on E: Exception do
      WriteLn('毒化状态异常: ', E.Message);
  end;
  
  // 使用 ExecuteForce 可以恢复
  Once.ExecuteForce(@SomeOtherCallback);
  WriteLn('已恢复: ', Once.Completed);   // 输出: True
end.
```

## 🧵 线程安全性

所有一次性执行操作都是线程安全的：

- **并发执行**：多个线程同时调用 `Execute`，只有一个会成功执行回调
- **状态查询**：`State`、`Completed`、`Poisoned` 可以安全地从任何线程调用
- **等待机制**：`Wait` 和 `WaitForce` 支持多线程等待

## 🔧 配置选项

### 编译时配置

在 `fafafa.core.settings.inc` 中可以配置：

```pascal
// 启用匿名函数支持（如果编译器支持）
{$DEFINE FAFAFA_CORE_ANONYMOUS_REFERENCES}
```

## 📊 性能特性

### 快速路径优化

- **原子操作**：使用无锁原子操作进行快速状态检查
- **分支预测**：优化常见执行路径的分支预测
- **缓存行对齐**：关键数据结构按缓存行对齐

### 内存布局

```
第一个缓存行 (64字节)：热路径数据
├── FDone: LongBool (1字节)
├── FState: LongInt (4字节)  
├── FExecutingThreadId: TThreadID (8字节)
└── 填充到缓存行边界

第二个缓存行 (64字节)：同步数据
├── FMutex: pthread_mutex_t/CRITICAL_SECTION
└── 填充到缓存行边界

第三个缓存行 (64字节)：回调存储
├── FCallback: TOnceCallback
└── 填充到缓存行边界
```

## 🧪 测试覆盖

模块包含全面的单元测试：

- **基础功能测试**：验证基本执行逻辑
- **状态管理测试**：验证状态转换正确性
- **异常处理测试**：验证毒化和恢复机制
- **并发测试**：验证多线程安全性
- **性能测试**：验证高并发场景

运行测试：
```bash
cd tests/fafafa.core.sync.once
buildOrTest.bat
```

## 🔄 与其他语言对比

| 特性 | fafafa.core.sync.once | Go sync.Once | Rust std::sync::Once | Java AtomicReference |
|------|----------------------|--------------|---------------------|---------------------|
| 一次性执行 | ✅ | ✅ | ✅ | ❌ |
| 异常安全 | ✅ | ❌ | ✅ | ❌ |
| 毒化状态 | ✅ | ❌ | ✅ | ❌ |
| 强制重试 | ✅ | ❌ | ❌ | ❌ |
| 等待机制 | ✅ | ❌ | ✅ | ❌ |
| 状态查询 | ✅ | ❌ | ✅ | ❌ |

## 📝 注意事项

1. **回调函数要求**：回调函数应该是幂等的，避免副作用
2. **异常处理**：回调函数中的异常会导致毒化状态
3. **内存管理**：once 实例通过接口引用计数自动管理
4. **递归调用**：避免在回调函数中递归调用同一个 once 实例

## 🔗 相关模块

- `fafafa.core.sync.barrier` - 屏障同步
- `fafafa.core.sync.base` - 同步基础设施
- `fafafa.core.base` - 核心基础类型

---

**版权声明**: Copyright (c) 2024 fafafaStudio. All rights reserved.
