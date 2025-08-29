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

  // 扩展方法：动态设置并执行回调
  procedure Execute(const AProc: TOnceProc); overload;
  procedure Execute(const AMethod: TOnceMethod); overload;
  procedure Execute(const AAnonymousProc: TOnceAnonymousProc); overload;

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
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
TOnceAnonymousProc = reference to procedure;
{$ENDIF}
```

### 工厂函数

```pascal
function MakeOnce: IOnce; overload;
function MakeOnce(const AProc: TOnceProc): IOnce; overload;
function MakeOnce(const AMethod: TOnceMethod): IOnce; overload;
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function MakeOnce(const AAnonymousProc: TOnceAnonymousProc): IOnce; overload;
{$ENDIF}
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

  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  // 方式2：使用匿名过程
  Once := MakeOnce(
    procedure
    begin
      WriteLn('匿名过程执行');
    end
  );
  Once.Execute;
  {$ENDIF}

  // 方式3：使用 ILock 接口
  Once := MakeOnce(@InitializeResource);
  Once.Acquire; // 等同于 Execute
  Once.Acquire; // 不会重复执行
end;
```

### 实际应用场景

#### 1. 数据库连接池初始化

```pascal
type
  TConnectionPool = class
  private
    FConnections: TList;
    class var FInstance: TConnectionPool;
    class var FInitOnce: IOnce;
    class procedure InitializePool;
  public
    constructor Create;
    destructor Destroy; override;
    class function GetPool: TConnectionPool;
    function GetConnection: TObject;
    procedure ReturnConnection(AConnection: TObject);
  end;

class procedure TConnectionPool.InitializePool;
begin
  FInstance := TConnectionPool.Create;
  // 创建10个数据库连接
  for var i := 1 to 10 do
    FInstance.FConnections.Add(CreateDatabaseConnection);
  WriteLn('连接池已初始化，包含 ', FInstance.FConnections.Count, ' 个连接');
end;

class function TConnectionPool.GetPool: TConnectionPool;
begin
  if not Assigned(FInitOnce) then
    FInitOnce := MakeOnce(@InitializePool);
  FInitOnce.Execute; // 线程安全的初始化
  Result := FInstance;
end;
```

#### 2. 全局配置管理

```pascal
type
  TAppConfig = record
    DatabaseUrl: string;
    ApiKey: string;
    LogLevel: Integer;
    MaxConnections: Integer;
  end;

var
  AppConfig: TAppConfig;
  ConfigOnce: IOnce;

procedure LoadConfiguration;
var
  ConfigFile: TIniFile;
begin
  WriteLn('加载应用配置...');
  ConfigFile := TIniFile.Create('app.ini');
  try
    AppConfig.DatabaseUrl := ConfigFile.ReadString('Database', 'Url', 'localhost:5432');
    AppConfig.ApiKey := ConfigFile.ReadString('API', 'Key', '');
    AppConfig.LogLevel := ConfigFile.ReadInteger('Logging', 'Level', 2);
    AppConfig.MaxConnections := ConfigFile.ReadInteger('Database', 'MaxConnections', 10);
  finally
    ConfigFile.Free;
  end;
  WriteLn('配置加载完成');
end;

procedure EnsureConfigLoaded;
begin
  if not Assigned(ConfigOnce) then
    ConfigOnce := MakeOnce(@LoadConfiguration);
  ConfigOnce.Execute;
end;

// 在任何需要配置的地方调用
procedure DatabaseOperation;
begin
  EnsureConfigLoaded;
  WriteLn('连接数据库: ', AppConfig.DatabaseUrl);
  WriteLn('最大连接数: ', AppConfig.MaxConnections);
end;
```

#### 3. 日志系统初始化

```pascal
type
  TLogger = class
  private
    class var FLogFile: TextFile;
    class var FInitOnce: IOnce;
    class var FLogLevel: Integer;
    class procedure InitializeLogger;
  public
    class procedure Log(ALevel: Integer; const AMessage: string);
    class procedure Info(const AMessage: string);
    class procedure Warning(const AMessage: string);
    class procedure Error(const AMessage: string);
    class procedure Shutdown;
  end;

class procedure TLogger.InitializeLogger;
begin
  AssignFile(FLogFile, 'application.log');
  Rewrite(FLogFile);
  FLogLevel := 1; // 1=Info, 2=Warning, 3=Error
  WriteLn(FLogFile, '[', DateTimeToStr(Now), '] [INFO] Logger initialized');
  Flush(FLogFile);
  WriteLn('日志系统已初始化');
end;

class procedure TLogger.Log(ALevel: Integer; const AMessage: string);
const
  LevelNames: array[1..3] of string = ('INFO', 'WARN', 'ERROR');
begin
  if not Assigned(FInitOnce) then
    FInitOnce := MakeOnce(@InitializeLogger);
  FInitOnce.Execute;

  if ALevel >= FLogLevel then
  begin
    WriteLn(FLogFile, '[', DateTimeToStr(Now), '] [', LevelNames[ALevel], '] ', AMessage);
    Flush(FLogFile);
  end;
end;

class procedure TLogger.Info(const AMessage: string);
begin
  Log(1, AMessage);
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
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  // 构造时传入创建实例的匿名过程
  FOnce := MakeOnce(
    procedure
    begin
      FInstance := TSingleton.Create;
    end
  );
  {$ELSE}
  // 不支持匿名过程时使用普通过程
  FOnce := MakeOnce(@CreateInstanceProc);
  {$ENDIF}
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
- ✅ Execute 过程调用
- ✅ Execute 方法调用
- ✅ ILock 接口兼容性
- ✅ 状态查询
- ✅ 异常处理

### 并发测试
- ✅ 多线程 Execute
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

---

## 🎯 最佳实践指南

### 1. 选择合适的工厂函数

```pascal
// ✅ 推荐：构造时传入回调（更清晰，性能更好）
Once := MakeOnce(@InitializeResource);
Once.Execute;

// ✅ 也可以：运行时传入回调（更灵活）
Once := MakeOnce;
Once.Execute(@InitializeResource);

// ✅ 匿名过程：适合简单的初始化逻辑
Once := MakeOnce(
  procedure
  begin
    GlobalCounter := 42;
    WriteLn('计数器已初始化');
  end
);
```

### 2. 错误处理和毒化恢复

```pascal
var
  Once: IOnce;
  RetryOnce: IOnce;

procedure RiskyInitialization;
begin
  if Random(2) = 0 then
    raise Exception.Create('初始化失败');
  WriteLn('初始化成功');
end;

begin
  Once := MakeOnce(@RiskyInitialization);

  try
    Once.Execute;
  except
    on E: Exception do
    begin
      WriteLn('初始化失败: ', E.Message);
      WriteLn('Once 状态已毒化: ', Once.Poisoned);

      // 方案1：使用 ExecuteForce 强制重试
      Once.ExecuteForce(@SafeInitialization);

      // 方案2：使用新的 Once 实例
      RetryOnce := MakeOnce(@SafeInitialization);
      RetryOnce.Execute;
    end;
  end;
end;
```

### 3. 性能优化技巧

```pascal
// ✅ 推荐：将 Once 实例存储为类变量或全局变量
type
  TMyClass = class
  private
    class var FInitOnce: IOnce;
  public
    class procedure EnsureInitialized;
  end;

class procedure TMyClass.EnsureInitialized;
begin
  if not Assigned(FInitOnce) then
    FInitOnce := MakeOnce(@DoInitialization);
  FInitOnce.Execute; // 快速路径：已完成时仅需一次原子读取
end;

// ❌ 避免：每次都创建新的 Once 实例
procedure BadExample;
var
  Once: IOnce;
begin
  Once := MakeOnce(@DoInitialization); // 浪费资源
  Once.Execute;
end;
```

### 4. 线程安全使用

```pascal
// ✅ Once 本身是线程安全的，但要注意初始化的资源
var
  GlobalOnce: IOnce;
  GlobalResource: TThreadSafeResource;

procedure InitializeThreadSafeResource;
begin
  GlobalResource := TThreadSafeResource.Create;
  WriteLn('线程安全资源已创建');
end;

// 在多个线程中安全调用
procedure WorkerThread;
begin
  GlobalOnce.Execute; // 线程安全的初始化
  GlobalResource.DoWork; // 确保资源本身也是线程安全的
end;
```

### 5. 常见陷阱和解决方案

```pascal
// ❌ 陷阱：在回调中递归调用同一个 Once
var
  RecursiveOnce: IOnce;

procedure BadRecursiveCallback;
begin
  RecursiveOnce.Execute; // 这会导致递归调用异常
end;

// ✅ 解决方案：避免递归调用
procedure GoodCallback;
begin
  WriteLn('安全的初始化逻辑');
  // 不要在这里调用同一个 Once
end;
```
