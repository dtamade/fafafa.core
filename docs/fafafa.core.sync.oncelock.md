# fafafa.core.sync.oncelock

## 概述

OnceLock 是一个 Rust 风格的线程安全懒初始化容器，用于存储一个值并保证只能被初始化一次。它提供了线程安全的单次初始化机制，适合全局配置、单例模式等场景。

## 核心概念

### 单次初始化

OnceLock 维护一个内部状态机：
- **Unset**（未设置）：初始状态，尚未存储值
- **Setting**（正在设置）：某个线程正在写入值
- **Set**（已设置）：值已成功设置，可以读取
- **Poisoned**（毒化）：初始化失败，容器不可用

### 线程安全保证

- 多个线程可以同时尝试设置值，但只有一个会成功
- 其他线程会等待设置完成或立即返回失败
- 初始化后的读取操作无需加锁（无锁快路径）

### 与 LazyLock 的区别

| 特性 | OnceLock | LazyLock |
|------|----------|----------|
| 初始化时机 | 手动调用 Set/GetOrInit | 首次访问自动初始化 |
| 初始化器 | 可选，按需提供 | 必须，创建时提供 |
| 灵活性 | 高（可多次尝试设置） | 低（固定初始化器） |
| 使用场景 | 动态初始化 | 固定初始化逻辑 |

## API 参考

### 类型定义

```pascal
type
  TOnceLockState = (
    olsUnset,      // 未设置
    olsSetting,    // 正在设置
    olsSet,        // 已设置
    olsPoisoned    // 毒化状态
  );

  generic TOnceLock<T> = class
  public type
    PT = ^T;
    TInitFunc = function: T;
  private
    FValue: T;
    FState: LongInt;
  public
    constructor Create;
    destructor Destroy; override;
    
    function IsSet: Boolean;
    function IsPoisoned: Boolean;
    procedure SetValue(const AValue: T);
    function TrySet(const AValue: T): Boolean;
    function GetValue: T;
    function TryGet: PT;
    function GetOrInit(AInitializer: TInitFunc): T;
    function GetOrTryInit(AInitializer: TInitFunc; out AError: Exception): T;
    function Take: T;
    function IntoInner: T;
    procedure Wait;
    function WaitTimeout(ATimeoutMs: Cardinal): Boolean;
  end;
```

### 创建 OnceLock

```pascal
constructor Create;
```

创建一个新的 OnceLock 实例，初始状态为 Unset。

### IsSet

```pascal
function IsSet: Boolean;
```

检查是否已设置值。

**返回值**：
- `True` - 值已设置
- `False` - 值未设置

### IsPoisoned

```pascal
function IsPoisoned: Boolean;
```

检查是否处于毒化状态（初始化失败）。

**返回值**：
- `True` - 容器已毒化
- `False` - 容器正常

### SetValue

```pascal
procedure SetValue(const AValue: T);
```

设置值（如果已设置则抛出异常）。

**参数**：
- `AValue` - 要设置的值

**异常**：
- `EOnceLockAlreadySet` - 如果值已经被设置

### TrySet

```pascal
function TrySet(const AValue: T): Boolean;
```

尝试设置值。

**参数**：
- `AValue` - 要设置的值

**返回值**：
- `True` - 成功设置
- `False` - 已有值，设置失败

### GetValue

```pascal
function GetValue: T;
```

获取值（如果未设置则抛出异常）。

**返回值**：
- 存储的值

**异常**：
- `EOnceLockEmpty` - 如果值未设置

### TryGet

```pascal
function TryGet: PT;
```

尝试获取值的指针。

**返回值**：
- 值的指针（如果已设置）
- `nil`（如果未设置）

### GetOrInit

```pascal
function GetOrInit(AInitializer: TInitFunc): T;
```

获取值或使用初始化器初始化。

**参数**：
- `AInitializer` - 初始化函数（仅在未设置时调用）

**返回值**：
- 存储的值

**线程安全性**：
- 多线程竞争时只有一个初始化器会被执行

### GetOrTryInit

```pascal
function GetOrTryInit(AInitializer: TInitFunc; out AError: Exception): T;
```

获取值或尝试初始化（带错误处理）。

**参数**：
- `AInitializer` - 初始化函数
- `AError` - 输出参数，初始化失败时返回异常对象

**返回值**：
- 存储的值（失败时返回默认值）

### Take

```pascal
function Take: T;
```

获取并清空值（转移所有权）。

**返回值**：
- 存储的值

**异常**：
- `EOnceLockEmpty` - 如果值未设置

### IntoInner

```pascal
function IntoInner: T;
```

获取内部值（不清空）。

**返回值**：
- 存储的值

**异常**：
- `EOnceLockEmpty` - 如果值未设置

### Wait

```pascal
procedure Wait;
```

等待初始化完成。阻塞当前线程直到值被设置。

### WaitTimeout

```pascal
function WaitTimeout(ATimeoutMs: Cardinal): Boolean;
```

带超时的等待。

**参数**：
- `ATimeoutMs` - 超时时间（毫秒）

**返回值**：
- `True` - 值已设置
- `False` - 超时

## 使用示例

### 基本用法

```pascal
uses
  fafafa.core.sync.oncelock;

type
  TIntLock = specialize TOnceLock<Integer>;

var
  LLock: TIntLock;
begin
  LLock := TIntLock.Create;
  try
    // 设置值
    LLock.SetValue(42);
    
    // 获取值
    WriteLn('Value: ', LLock.GetValue);  // 输出: Value: 42
  finally
    LLock.Free;
  end;
end;
```

### 尝试设置

```pascal
var
  LLock: TIntLock;
begin
  LLock := TIntLock.Create;
  try
    // 第一次设置成功
    if LLock.TrySet(100) then
      WriteLn('设置成功');
    
    // 第二次设置失败
    if not LLock.TrySet(200) then
      WriteLn('已有值，设置失败');
    
    WriteLn('当前值: ', LLock.GetValue);  // 输出: 100
  finally
    LLock.Free;
  end;
end;
```

### 懒初始化

```pascal
function ExpensiveComputation: Integer;
begin
  WriteLn('执行昂贵的计算...');
  Sleep(1000);
  Result := 42;
end;

var
  LLock: TIntLock;
begin
  LLock := TIntLock.Create;
  try
    // 第一次调用会执行初始化器
    WriteLn('第一次获取: ', LLock.GetOrInit(@ExpensiveComputation));
    
    // 第二次调用直接返回缓存值
    WriteLn('第二次获取: ', LLock.GetOrInit(@ExpensiveComputation));
  finally
    LLock.Free;
  end;
end;
```

### 全局配置单例

```pascal
type
  TConfig = record
    Host: string;
    Port: Integer;
    Timeout: Integer;
  end;
  TConfigLock = specialize TOnceLock<TConfig>;

var
  GConfig: TConfigLock;

function LoadConfig: TConfig;
begin
  Result.Host := 'localhost';
  Result.Port := 8080;
  Result.Timeout := 30;
end;

function GetConfig: TConfig;
begin
  Result := GConfig.GetOrInit(@LoadConfig);
end;

begin
  GConfig := TConfigLock.Create;
  try
    // 多个线程可以安全地调用 GetConfig
    WriteLn('Host: ', GetConfig.Host);
    WriteLn('Port: ', GetConfig.Port);
  finally
    GConfig.Free;
  end;
end;
```

### 多线程竞争

```pascal
var
  LLock: TIntLock;
  LThreads: array[1..10] of TThread;
begin
  LLock := TIntLock.Create;
  try
    // 启动 10 个线程同时尝试设置
    for var i := 1 to 10 do
    begin
      LThreads[i] := TThread.CreateAnonymousThread(procedure
      var
        LValue: Integer;
      begin
        LValue := i * 10;
        if LLock.TrySet(LValue) then
          WriteLn(Format('线程 %d 设置成功: %d', [i, LValue]))
        else
          WriteLn(Format('线程 %d 设置失败', [i]));
      end);
      LThreads[i].Start;
    end;
    
    // 等待所有线程完成
    for var i := 1 to 10 do
      LThreads[i].WaitFor;
    
    WriteLn('最终值: ', LLock.GetValue);
  finally
    LLock.Free;
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
  LLock: TIntLock;
  LError: Exception;
  LValue: Integer;
begin
  LLock := TIntLock.Create;
  try
    LValue := LLock.GetOrTryInit(@RiskyInit, LError);
    
    if LError <> nil then
    begin
      WriteLn('初始化失败: ', LError.Message);
      LError.Free;
    end
    else
      WriteLn('值: ', LValue);
  finally
    LLock.Free;
  end;
end;
```

## 使用场景

### 适合的场景

✅ **全局配置**
```pascal
// 线程安全的全局配置加载
var GConfig: TConfigLock;
```

✅ **单例模式**
```pascal
// 线程安全的单例实现
function GetInstance: TMyClass;
begin
  Result := GInstanceLock.GetOrInit(@CreateInstance);
end;
```

✅ **昂贵资源的懒加载**
```pascal
// 数据库连接、大型数据结构等
var GConnection: TConnectionLock;
```

✅ **一次性初始化**
```pascal
// 只需初始化一次的资源
var GLogger: TLoggerLock;
```

### 不适合的场景

❌ **需要重置的值**
- OnceLock 是一次性的，使用普通变量 + 锁

❌ **频繁变化的数据**
- 使用 Mutex 或 RWLock 保护

❌ **需要多个值**
- 使用多个 OnceLock 或其他数据结构

## 注意事项

### 一次性使用

⚠️ **OnceLock 只能设置一次**
```pascal
var LLock := TIntLock.Create;
LLock.SetValue(42);
// LLock.SetValue(100);  // 抛出异常！
```

### 毒化状态

⚠️ **初始化失败会导致毒化**
```pascal
function FailingInit: Integer;
begin
  raise Exception.Create('失败');
end;

try
  LLock.GetOrInit(@FailingInit);
except
  // 容器现在处于毒化状态
end;

// 后续访问会抛出 EOnceLockPoisoned
```

### 内存管理

⚠️ **存储对象时注意所有权**
```pascal
type
  TObjectLock = specialize TOnceLock<TObject>;

var
  LLock: TObjectLock;
  LObj: TObject;
begin
  LLock := TObjectLock.Create;
  try
    LObj := TMyClass.Create;
    LLock.SetValue(LObj);
    
    // 使用对象...
    
    // 清理：需要手动释放对象
    LObj := LLock.Take;
    LObj.Free;
  finally
    LLock.Free;
  end;
end;
```

## 最佳实践

### 1. 全局单例模式

```pascal
type
  TLogger = class
    // ...
  end;
  TLoggerLock = specialize TOnceLock<TLogger>;

var
  GLoggerLock: TLoggerLock;

function GetLogger: TLogger;
begin
  Result := GLoggerLock.GetOrInit(
    function: TLogger
    begin
      Result := TLogger.Create;
    end
  );
end;

initialization
  GLoggerLock := TLoggerLock.Create;

finalization
  if GLoggerLock.IsSet then
    GLoggerLock.Take.Free;
  GLoggerLock.Free;
```

### 2. 配置加载

```pascal
type
  TAppConfig = record
    DatabaseUrl: string;
    ApiKey: string;
  end;
  TConfigLock = specialize TOnceLock<TAppConfig>;

var
  GConfigLock: TConfigLock;

function LoadConfigFromFile: TAppConfig;
begin
  // 从文件加载配置
  Result.DatabaseUrl := ReadConfigValue('db_url');
  Result.ApiKey := ReadConfigValue('api_key');
end;

function GetConfig: TAppConfig;
begin
  Result := GConfigLock.GetOrInit(@LoadConfigFromFile);
end;
```

### 3. 资源池初始化

```pascal
type
  TConnectionPool = class
    // ...
  end;
  TPoolLock = specialize TOnceLock<TConnectionPool>;

var
  GPoolLock: TPoolLock;

function GetConnectionPool: TConnectionPool;
begin
  Result := GPoolLock.GetOrInit(
    function: TConnectionPool
    begin
      WriteLn('初始化连接池...');
      Result := TConnectionPool.Create(10);  // 10 个连接
    end
  );
end;
```

## 性能特性

### 开销分析

| 操作 | 开销 | 说明 |
|------|------|------|
| `Create` | 低 | 仅分配内存 |
| `IsSet` | 极低 | 原子读取 |
| `GetValue`（已设置） | 极低 | 无锁读取 |
| `SetValue`（首次） | 低 | 原子CAS操作 |
| `GetOrInit`（已初始化） | 极低 | 无锁读取 |
| `GetOrInit`（首次） | 中 | 执行初始化器 |

### 性能建议

1. **无锁快路径**：初始化后的读取无需加锁
2. **避免昂贵初始化器**：初始化器应尽可能快
3. **重用实例**：OnceLock 实例可以长期存在

## 相关模块

- `fafafa.core.sync.lazylock` - 自动懒加载容器
- `fafafa.core.sync.once` - 一次性执行原语
- `fafafa.core.sync.mutex` - 互斥锁
- `fafafa.core.sync.base` - 同步原语基础接口

## 参考资料

- Rust `std::sync::OnceLock` 文档
- Java `AtomicReference` 文档
- C++ `std::call_once` 文档

## 版本历史

- **v1.0** - 初始版本，支持基本的单次初始化功能
- 支持毒化机制（Poisoned state）
- 支持等待和超时（Wait, WaitTimeout）
- 支持所有权转移（Take, IntoInner）
