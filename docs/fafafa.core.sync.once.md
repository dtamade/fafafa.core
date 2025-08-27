# fafafa.core.sync.once - 一次性执行模块

## 📋 概述

`fafafa.core.sync.once` 模块提供了线程安全的一次性执行功能，确保某个操作在多线程环境中只被执行一次。该模块遵循与其他同步原语相同的架构模式，继承自 `ILock` 基础接口，提供跨平台的统一接口。

## 🎯 设计理念

Once 模块借鉴了现代编程语言的设计：
- **C++**: `std::once_flag` + `std::call_once`
- **Go**: `sync.Once`
- **Rust**: `std::sync::Once`
- **Java**: 双重检查锁定模式

## 🏗️ 架构设计

### 模块结构
```
fafafa.core.sync.once/
├── fafafa.core.sync.once.pas          # 主模块，平台无关接口
├── fafafa.core.sync.once.base.pas     # 基础接口定义
├── fafafa.core.sync.once.windows.pas  # Windows 平台实现
└── fafafa.core.sync.once.unix.pas     # Unix/Linux 平台实现
```

### 接口层次
```
ILock (基础锁接口)
  └── IOnce (一次性执行接口)
        └── TOnce (平台特定实现)
```

## 🔧 平台实现策略

### Windows 平台
- **底层技术**: InterlockedCompareExchange + CRITICAL_SECTION
- **实现方式**: 
  - 使用原子操作进行状态管理
  - 双重检查锁定模式确保线程安全
  - 支持异常恢复和重试机制
- **优势**: 高性能，支持异常恢复

### Unix/Linux 平台
- **底层技术**: pthread_once_t
- **API 使用**: 
  - `pthread_once()` - 确保回调只执行一次
  - `pthread_mutex_t` - 状态同步
- **优势**: 系统级保证，硬件优化

## 📚 API 参考

### 接口定义

```pascal
IOnce = interface(ILock)
  // 继承自 ILock 的方法
  procedure Acquire;           // 执行一次性操作（等同于 Execute）
  procedure Release;           // 对于 once 语义，此方法为空操作
  function TryAcquire: Boolean; // 尝试执行一次性操作，如果已执行则立即返回 True

  // 核心方法：执行构造时传入的回调
  procedure Execute;

  // 扩展方法：动态设置并执行回调（向后兼容）
  procedure CallOnce(const AProc: TOnceProc); overload;
  procedure CallOnce(const AMethod: TOnceMethod); overload;
  procedure CallOnce(const AAnonymousProc: TOnceAnonymousProc); overload;

  // 状态查询
  function GetState: TOnceState;
  function IsCompleted: Boolean;
  function IsInProgress: Boolean;

  // 重置功能（主要用于测试）
  procedure Reset;
end;
```

### 类型定义

```pascal
TOnceState = (osNotStarted, osInProgress, osCompleted);
TOnceProc = procedure;
TOnceMethod = procedure of object;
TOnceAnonymousProc = reference to procedure;
```

### 工厂函数

```pascal
function MakeOnce: IOnce; overload;
function MakeOnce(const AProc: TOnceProc): IOnce; overload;
function MakeOnce(const AMethod: TOnceMethod): IOnce; overload;
function MakeOnce(const AAnonymousProc: TOnceAnonymousProc): IOnce; overload;
```

## 💡 使用示例

### 基本用法

```pascal
uses
  fafafa.core.sync.once;

var
  Once: IOnce;
  InitCount: Integer = 0;

procedure InitializeResource;
begin
  Inc(InitCount);
  WriteLn('资源初始化，计数: ', InitCount);
end;

begin
  // 方式1：构造时传入过程，使用 Execute
  Once := MakeOnce(@InitializeResource);
  Once.Execute; // 执行回调
  Once.Execute; // 不会重复执行

  // 方式2：使用匿名过程
  Once := MakeOnce(
    procedure
    begin
      WriteLn('匿名过程执行');
    end
  );
  Once.Execute;

  // 方式3：使用 ILock 接口
  Once := MakeOnce(@InitializeResource);
  Once.Acquire; // 等同于 Execute
  Once.Acquire; // 不会重复执行
end;
```

### 单例模式实现

```pascal
type
  TSingleton = class
  private
    class var FInstance: TSingleton;
    class var FOnce: IOnce;
  public
    class constructor Create;
    class function GetInstance: TSingleton;
  end;

class constructor TSingleton.Create;
begin
  // 构造时传入创建实例的匿名过程
  FOnce := MakeOnce(
    procedure
    begin
      FInstance := TSingleton.Create;
    end
  );
end;

class function TSingleton.GetInstance: TSingleton;
begin
  FOnce.Execute; // 执行一次性初始化
  Result := FInstance;
end;
```

### 多线程初始化

```pascal
var
  GlobalOnce: IOnce;
  GlobalResource: TObject;

procedure InitGlobalResource;
begin
  GlobalResource := TStringList.Create;
  WriteLn('全局资源已初始化');
end;

// 在多个线程中调用
procedure ThreadProc;
begin
  GlobalOnce.Execute; // 执行一次性初始化
  // 使用 GlobalResource...
end;

// 初始化代码
begin
  GlobalOnce := MakeOnce(@InitGlobalResource);
end;
```

### 使用 ILock 接口

```pascal
var
  Once: IOnce;

procedure Setup;
begin
  WriteLn('执行设置操作');
end;

begin
  Once := MakeOnce(@Setup); // 构造时设置回调

  // 在需要的时候执行
  if Once.TryAcquire then
    WriteLn('设置已完成')
  else
    WriteLn('设置失败');
end;
```

## ⚡ 性能特征

### 适用场景
- **单例初始化**: 确保单例对象只创建一次
- **资源初始化**: 昂贵资源的延迟初始化
- **配置加载**: 配置文件只读取一次
- **库初始化**: 第三方库的一次性初始化

### 性能对比

| 场景 | Once | Mutex | 说明 |
|------|------|-------|------|
| 已完成状态检查 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | Once 快速路径无锁 |
| 首次执行 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 性能相当 |
| 并发访问 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | Once 优化了已完成状态 |

## 🚨 注意事项

### 重要限制
1. **不支持重复执行**: 一旦执行完成，无法再次执行（除非 Reset）
2. **异常处理**: Windows 实现支持异常恢复，Unix 实现不支持
3. **Reset 谨慎使用**: Reset 主要用于测试，生产环境需谨慎
4. **回调存储**: 回调函数会被存储，注意对象生命周期

### 最佳实践

```pascal
// ✅ 推荐：构造时传入回调，使用 Execute
Once := MakeOnce(@SimpleInit);
Once.Execute;

// ✅ 推荐：使用 ILock 接口
if Once.TryAcquire then
  WriteLn('操作已完成');

// ❌ 不推荐：在回调中抛出异常（Unix 平台）
Once := MakeOnce(
  procedure
  begin
    raise Exception.Create('错误'); // Unix 平台可能无法恢复
  end
);

// ❌ 不推荐：生产环境使用 Reset
Once.Reset; // 仅用于测试
```

## 🧪 测试覆盖

### 基础功能测试
- ✅ 创建和销毁
- ✅ CallOnce 过程调用
- ✅ CallOnce 方法调用
- ✅ ILock 接口兼容性
- ✅ 状态查询
- ✅ 异常处理

### 并发测试
- ✅ 多线程 CallOnce
- ✅ 高并发压力测试
- ✅ 混合接口调用

### 平台测试
- ✅ Windows (原子操作 + 临界区)
- ✅ Unix/Linux (pthread_once)

## 🔄 与其他模块的关系

### 依赖关系
```
fafafa.core.sync.once
├── fafafa.core.sync.base (基础接口)
├── fafafa.core.atomic (Windows 平台)
└── pthreads (Unix 平台)
```

### 集成使用
```pascal
uses
  fafafa.core.sync.once,
  fafafa.core.sync.mutex;

// 根据场景选择合适的同步原语
function CreateInitializer(IsOneTime: Boolean): ILock;
begin
  if IsOneTime then
    Result := MakeOnce
  else
    Result := CreateMutex;
end;
```

## 📈 未来扩展

### 计划功能
- [ ] 超时支持
- [ ] 异步执行支持
- [ ] 统计信息收集
- [ ] 性能监控集成

### 性能优化
- [ ] 内存屏障优化
- [ ] 缓存行对齐
- [ ] 分支预测优化
