# fafafa.core.sync.lazylock

## 概述

LazyLock 是一个 Rust 风格的线程安全懒加载容器，在创建时接受一个初始化器函数，在首次访问时自动执行初始化。它提供了延迟初始化和线程安全保证，适合昂贵资源的懒加载场景。

## 核心概念

### 自动懒初始化

LazyLock 维护一个内部状态机：
- **Uninit**（未初始化）：初始状态，尚未执行初始化器
- **Initializing**（正在初始化）：某个线程正在执行初始化器
- **Initialized**（已初始化）：初始化完成，值可用
- **Poisoned**（毒化）：初始化失败，容器不可用

### 与 OnceLock 的区别

| 特性 | LazyLock | OnceLock |
|------|----------|----------|
| 初始化时机 | 首次访问自动初始化 | 手动调用 Set/GetOrInit |
| 初始化器 | 必须，创建时提供 | 可选，按需提供 |
| 使用便利性 | 高（自动化） | 中（需手动管理） |
| 灵活性 | 低（固定初始化器） | 高（可多次尝试） |
| 适用场景 | 固定初始化逻辑 | 动态初始化 |

### 线程安全保证

- 多个线程同时首次访问时，只有一个会执行初始化器
- 其他线程会等待初始化完成
- 初始化后的读取操作无需加锁（无锁快路径）

## API 参考

### 类型定义

```pascal
type
  TLazyState = (
    lsUninit,       // 未初始化
    lsInitializing, // 正在初始化
    lsInitialized,  // 已初始化
    lsPoisoned      // 毒化状态
  );

  generic TLazyLock<T> = class
  public type
    PT = ^T;
    TInit = specialize TInitializer<T>;
  private
    FState: TLazyState;
    FValue: T;
    FInitializer: TInit;
  public
    constructor Create(AInitializer: TInit);
    destructor Destroy; override;
    
    function GetValue: T;
    procedure Force;
    function TryGet: PT;
    function IsInitialized: Boolean;
    function IsPoisoned: Boolean;
    function ForceInit: Boolean;
    function TryGetValue(out AValue: T): Boolean;
    function GetOrElse(const ADefault: T): T;
  end;
```

### 创建 LazyLock

```pascal
constructor Create(AInitializer: TInit);
```

创建一个新的 LazyLock 实例，指定初始化器函数。

**参数**：
- `AInitializer` - 初始化函数，首次访问时调用

### GetValue

```pascal
function GetValue: T;
```

获取值，如果未初始化则执行初始化。这是最常用的方法。

**返回值**：
- 存储的值

**行为**：
- 如果已初始化，直接返回值（无锁快路径）
- 如果未初始化，执行初始化器并返回值
- 如果已毒化，抛出 `ELazyLockPoisoned` 异常

### Force

```pascal
procedure Force;
```

强制初始化（如果尚未初始化）。用于预热或确保初始化在特定时机完成。

### TryGet

```pascal
function TryGet: PT;
```

尝试获取值的指针，不触发初始化。

**返回值**：
- 值的指针（如果已初始化）
- `nil`（如果未初始化）

### IsInitialized

```pascal
function IsInitialized: Boolean;
```

检查是否已初始化。

**返回值**：
- `True` - 已初始化
- `False` - 未初始化

### IsPoisoned

```pascal
function IsPoisoned: Boolean;
```

检查是否处于毒化状态（初始化失败）。

**返回值**：
- `True` - 容器已毒化
- `False` - 容器正常

### ForceInit

```pascal
function ForceInit: Boolean;
```

强制初始化，返回是否首次初始化。

**返回值**：
- `True` - 是首次初始化
- `False` - 已经初始化

### TryGetValue

```pascal
function TryGetValue(out AValue: T): Boolean;
```

尝试获取值（不触发初始化）。

**参数**：
- `AValue` - 输出参数，如果已初始化则返回值

**返回值**：
- `True` - 已初始化，`AValue` 包含值
- `False` - 未初始化

### GetOrElse

```pascal
function GetOrElse(const ADefault: T): T;
```

获取值或返回默认值（不触发初始化）。

**参数**：
- `ADefault` - 未初始化时返回的默认值

**返回值**：
- 如果已初始化返回实际值，否则返回默认值

## 使用示例

### 基本用法

```pascal
uses
  fafafa.core.sync.lazylock;

type
  TIntLazy = specialize TLazyLock<Integer>;

function ExpensiveComputation: Integer;
begin
  WriteLn('执行昂贵的计算...');
  Sleep(1000);
  Result := 42;
end;

var
  LLazy: TIntLazy;
begin
  LLazy := TIntLazy.Create(@ExpensiveComputation);
  try
    // 首次访问会执行初始化器
    WriteLn('第一次获取: ', LLazy.GetValue);
    
    // 后续访问直接返回缓存值
    WriteLn('第二次获取: ', LLazy.GetValue);
  finally
    LLazy.Free;
  end;
end;
```

### 全局配置懒加载

```pascal
type
  TConfig = record
    DatabaseUrl: string;
    ApiKey: string;
    MaxConnections: Integer;
  end;
  TConfigLazy = specialize TLazyLock<TConfig>;

function LoadConfig: TConfig;
begin
  WriteLn('加载配置文件...');
  Result.DatabaseUrl := 'postgresql://localhost/mydb';
  Result.ApiKey := 'secret-key-123';
  Result.MaxConnections := 100;
end;

var
  GConfig: TConfigLazy;

function GetConfig: TConfig;
begin
  Result := GConfig.GetValue;
end;

initialization
  GConfig := TConfigLazy.Create(@LoadConfig);

finalization
  GConfig.Free;
```

### 数据库连接池

```pascal
type
  TConnectionPool = class
  private
    FConnections: array of TConnection;
  public
    constructor Create(ASize: Integer);
    destructor Destroy; override;
    function Acquire: TConnection;
    procedure Release(AConn: TConnection);
  end;
  
  TPoolLazy = specialize TLazyLock<TConnectionPool>;

function CreatePool: TConnectionPool;
begin
  WriteLn('初始化连接池...');
  Result := TConnectionPool.Create(10);
end;

var
  GPool: TPoolLazy;

function GetPool: TConnectionPool;
begin
  Result := GPool.GetValue;
end;

initialization
  GPool := TPoolLazy.Create(@CreatePool);

finalization
  GPool.GetValue.Free;  // 清理连接池
  GPool.Free;
```

### 预热初始化

```pascal
var
  LLazy: TIntLazy;
begin
  LLazy := TIntLazy.Create(@ExpensiveComputation);
  try
    // 在应用启动时预热
    WriteLn('预热初始化...');
    LLazy.Force;
    
    // 后续访问无延迟
    WriteLn('快速访问: ', LLazy.GetValue);
  finally
    LLazy.Free;
  end;
end;
```

### 条件访问

```pascal
var
  LLazy: TIntLazy;
  LValue: Integer;
begin
  LLazy := TIntLazy.Create(@ExpensiveComputation);
  try
    // 检查是否已初始化
    if LLazy.IsInitialized then
      WriteLn('已初始化')
    else
      WriteLn('未初始化');
    
    // 尝试获取值（不触发初始化）
    if LLazy.TryGetValue(LValue) then
      WriteLn('值: ', LValue)
    else
      WriteLn('尚未初始化');
    
    // 获取值或使用默认值
    LValue := LLazy.GetOrElse(0);
    WriteLn('值或默认: ', LValue);
  finally
    LLazy.Free;
  end;
end;
```

### 多线程安全访问

```pascal
var
  LLazy: TIntLazy;
  LThreads: array[1..10] of TThread;
begin
  LLazy := TIntLazy.Create(@ExpensiveComputation);
  try
    // 启动 10 个线程同时访问
    for var i := 1 to 10 do
    begin
      LThreads[i] := TThread.CreateAnonymousThread(procedure
      var
        LValue: Integer;
      begin
        LValue := LLazy.GetValue;
        WriteLn(Format('线程 %d 获取值: %d', [TThread.CurrentThread.ThreadID, LValue]));
      end);
      LThreads[i].Start;
    end;
    
    // 等待所有线程完成
    for var i := 1 to 10 do
      LThreads[i].WaitFor;
    
    WriteLn('初始化器只执行了一次');
  finally
    LLazy.Free;
  end;
end;
```

### 错误处理

```pascal
function RiskyInit: Integer;
begin
  if Random(2) = 0 then
    raise Exception.Create('初始化失败');
  Result := 42;
end;

var
  LLazy: TIntLazy;
begin
  LLazy := TIntLazy.Create(@RiskyInit);
  try
    try
      WriteLn('尝试获取值...');
      WriteLn('值: ', LLazy.GetValue);
    except
      on E: Exception do
      begin
        WriteLn('初始化失败: ', E.Message);
        
        // 检查毒化状态
        if LLazy.IsPoisoned then
          WriteLn('容器已毒化，无法再次初始化');
      end;
    end;
  finally
    LLazy.Free;
  end;
end;
```

## 使用场景

### 适合的场景

✅ **昂贵资源的懒加载**
```pascal
// 数据库连接、大型数据结构等
var GConnection: TConnectionLazy;
```

✅ **全局配置**
```pascal
// 配置文件只在需要时加载
var GConfig: TConfigLazy;
```

✅ **单例模式**
```pascal
// 线程安全的懒加载单例
function GetInstance: TMyClass;
begin
  Result := GInstanceLazy.GetValue;
end;
```

✅ **可选功能模块**
```pascal
// 只在使用时才加载的功能
var GOptionalFeature: TFeatureLazy;
```

### 不适合的场景

❌ **需要动态初始化逻辑**
- 使用 OnceLock 的 GetOrInit

❌ **需要重新初始化**
- LazyLock 是一次性的

❌ **初始化器有副作用**
- 确保初始化器是幂等的

## 注意事项

### 初始化器要求

⚠️ **初始化器应该是纯函数**
```pascal
// ✅ 好：无副作用
function GoodInit: Integer;
begin
  Result := ComputeValue;
end;

// ❌ 差：有副作用
function BadInit: Integer;
begin
  GlobalCounter := GlobalCounter + 1;  // 副作用！
  Result := GlobalCounter;
end;
```

### 毒化状态

⚠️ **初始化失败会导致毒化**
```pascal
function FailingInit: Integer;
begin
  raise Exception.Create('失败');
end;

var LLazy := TIntLazy.Create(@FailingInit);
try
  LLazy.GetValue;  // 抛出异常，容器毒化
except
  // 处理异常
end;

// 后续访问会抛出 ELazyLockPoisoned
```

### 内存管理

⚠️ **存储对象时注意所有权**
```pascal
type
  TObjectLazy = specialize TLazyLock<TObject>;

function CreateObject: TObject;
begin
  Result := TMyClass.Create;
end;

var
  LLazy: TObjectLazy;
begin
  LLazy := TObjectLazy.Create(@CreateObject);
  try
    // 使用对象...
    LLazy.GetValue.DoSomething;
  finally
    // 清理：需要手动释放对象
    if LLazy.IsInitialized then
      LLazy.GetValue.Free;
    LLazy.Free;
  end;
end;
```

### 循环依赖

⚠️ **避免初始化器中的循环依赖**
```pascal
var
  GLazy1: TIntLazy;
  GLazy2: TIntLazy;

function Init1: Integer;
begin
  Result := GLazy2.GetValue + 1;  // 危险！
end;

function Init2: Integer;
begin
  Result := GLazy1.GetValue + 1;  // 死锁！
end;
```

## 最佳实践

### 1. 全局懒加载单例

```pascal
type
  TLogger = class
    // ...
  end;
  TLoggerLazy = specialize TLazyLock<TLogger>;

function CreateLogger: TLogger;
begin
  Result := TLogger.Create;
end;

var
  GLogger: TLoggerLazy;

function GetLogger: TLogger;
begin
  Result := GLogger.GetValue;
end;

initialization
  GLogger := TLoggerLazy.Create(@CreateLogger);

finalization
  if GLogger.IsInitialized then
    GLogger.GetValue.Free;
  GLogger.Free;
```

### 2. 配置懒加载

```pascal
type
  TAppConfig = record
    DatabaseUrl: string;
    ApiKey: string;
  end;
  TConfigLazy = specialize TLazyLock<TAppConfig>;

function LoadConfig: TAppConfig;
begin
  // 从文件加载配置
  Result.DatabaseUrl := ReadConfigValue('db_url');
  Result.ApiKey := ReadConfigValue('api_key');
end;

var
  GConfig: TConfigLazy;

function GetConfig: TAppConfig;
begin
  Result := GConfig.GetValue;
end;

initialization
  GConfig := TConfigLazy.Create(@LoadConfig);

finalization
  GConfig.Free;
```

### 3. 预热策略

```pascal
// 应用启动时预热关键资源
procedure WarmupCriticalResources;
begin
  WriteLn('预热关键资源...');
  GConnectionPool.Force;
  GConfig.Force;
  GLogger.Force;
  WriteLn('预热完成');
end;
```

### 4. 条件初始化

```pascal
// 只在需要时才初始化
function GetOptionalFeature: TFeature;
begin
  if FeatureEnabled then
    Result := GFeatureLazy.GetValue
  else
    Result := nil;
end;
```

## 性能特性

### 开销分析

| 操作 | 开销 | 说明 |
|------|------|------|
| `Create` | 低 | 仅存储初始化器指针 |
| `IsInitialized` | 极低 | 状态检查 |
| `GetValue`（已初始化） | 极低 | 无锁读取 |
| `GetValue`（首次） | 中 | 执行初始化器 |
| `Force` | 中 | 执行初始化器 |

### 性能建议

1. **无锁快路径**：初始化后的访问无需加锁
2. **预热策略**：关键资源可在启动时预热
3. **避免昂贵初始化器**：初始化器应尽可能快

## 相关模块

- `fafafa.core.sync.oncelock` - 手动懒初始化容器
- `fafafa.core.sync.once` - 一次性执行原语
- `fafafa.core.sync.mutex` - 互斥锁
- `fafafa.core.sync.base` - 同步原语基础接口

## 参考资料

- Rust `std::sync::LazyLock` 文档
- Java `Lazy<T>` 文档
- C++ `std::call_once` 文档

## 版本历史

- **v1.0** - 初始版本，支持自动懒加载功能
- 支持毒化机制（Poisoned state）
- 支持条件访问（TryGet, TryGetValue, GetOrElse）
- 支持强制初始化（Force, ForceInit）
