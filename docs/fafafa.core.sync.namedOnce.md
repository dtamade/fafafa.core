# fafafa.core.sync.namedOnce

## 概述

namedOnce 是一个跨进程的一次性执行原语，允许多个进程协调执行某个初始化操作，确保该操作在所有进程中只执行一次。它是 `Once` 的命名版本，支持跨进程同步。

## 核心概念

### 跨进程一次性执行

namedOnce 通过命名的共享内存或内核对象实现跨进程同步：
- 多个进程可以通过相同的名称访问同一个 Once 实例
- 只有一个进程会执行初始化回调
- 其他进程会等待初始化完成
- 支持毒化机制（初始化失败时）

### 状态机

```
NotStarted → InProgress → Completed
     ↓
  Poisoned (初始化失败)
```

### 与非命名 Once 的区别

| 特性 | Once | namedOnce |
|------|------|-----------|
| 作用域 | 单进程 | 跨进程 |
| 命名 | 无 | 必须指定名称 |
| 资源 | 内存 | 共享内存/内核对象 |
| 清理 | 自动 | 需要显式清理 |

## API 参考

### 类型定义

```pascal
type
  TNamedOnceState = (
    nosNotStarted = 0,   // 未开始
    nosInProgress = 1,   // 执行中
    nosCompleted = 2,    // 已完成
    nosPoisoned = 3      // 异常中毒
  );

  TNamedOnceConfig = record
    TimeoutMs: Cardinal;           // 等待超时时间（毫秒）
    UseGlobalNamespace: Boolean;   // 是否使用全局命名空间
    EnablePoisoning: Boolean;      // 是否启用中毒检测
  end;

  TOnceCallback = procedure;
  TOnceCallbackMethod = procedure of object;
  TOnceCallbackNested = procedure is nested;

  INamedOnce = interface(ISynchronizable)
    procedure Execute(ACallback: TOnceCallback);
    procedure ExecuteMethod(ACallback: TOnceCallbackMethod);
    procedure ExecuteForce(ACallback: TOnceCallback);
    function Wait(ATimeoutMs: Cardinal = High(Cardinal)): Boolean;
    function GetState: TNamedOnceState;
    function IsDone: Boolean;
    function IsPoisoned: Boolean;
    function GetName: string;
    procedure Reset;
  end;
```

### 创建 namedOnce

```pascal
function MakeNamedOnce(const AName: string): INamedOnce;
function MakeNamedOnceWithConfig(const AName: string; const AConfig: TNamedOnceConfig): INamedOnce;
```

创建或打开一个命名的 Once 实例。

**参数**：
- `AName` - Once 的名称（跨进程唯一标识）
- `AConfig` - 配置选项（可选）

**返回值**：
- `INamedOnce` - Once 接口实例

### Execute

```pascal
procedure Execute(ACallback: TOnceCallback);
procedure ExecuteMethod(ACallback: TOnceCallbackMethod);
```

执行一次性初始化。

**参数**：
- `ACallback` - 初始化回调函数

**行为**：
- 如果已完成，立即返回
- 如果未开始，执行回调并标记为完成
- 如果正在执行，等待完成
- 如果已毒化，抛出异常

### ExecuteForce

```pascal
procedure ExecuteForce(ACallback: TOnceCallback);
```

强制重新执行（即使已完成或中毒）。

**参数**：
- `ACallback` - 初始化回调函数

**注意**：
- 会重置状态并重新执行
- 仅限创建者进程调用

### Wait

```pascal
function Wait(ATimeoutMs: Cardinal = High(Cardinal)): Boolean;
```

等待执行完成。

**参数**：
- `ATimeoutMs` - 超时时间（毫秒），默认无限等待

**返回值**：
- `True` - 执行完成
- `False` - 超时

### GetState

```pascal
function GetState: TNamedOnceState;
```

获取当前状态。

**返回值**：
- `nosNotStarted` - 未开始
- `nosInProgress` - 执行中
- `nosCompleted` - 已完成
- `nosPoisoned` - 已毒化

### IsDone

```pascal
function IsDone: Boolean;
```

检查是否已完成。

**返回值**：
- `True` - 已完成
- `False` - 未完成

### IsPoisoned

```pascal
function IsPoisoned: Boolean;
```

检查是否处于毒化状态。

**返回值**：
- `True` - 已毒化
- `False` - 正常

### Reset

```pascal
procedure Reset;
```

重置状态（仅限创建者）。

**注意**：
- 只有创建 Once 的进程可以重置
- 其他进程调用会抛出异常

## 使用示例

### 基本用法

```pascal
uses
  fafafa.core.sync.namedOnce;

procedure InitializeGlobalResource;
begin
  WriteLn('初始化全局资源...');
  // 执行昂贵的初始化操作
  Sleep(1000);
  WriteLn('初始化完成');
end;

var
  LOnce: INamedOnce;
begin
  LOnce := MakeNamedOnce('MyApp.GlobalInit');
  try
    // 多个进程调用，只有一个会执行
    LOnce.Execute(@InitializeGlobalResource);
    WriteLn('可以使用全局资源了');
  finally
    LOnce := nil;
  end;
end;
```

### 跨进程初始化

```pascal
// 进程 A
var
  LOnce: INamedOnce;
begin
  LOnce := MakeNamedOnce('SharedDB.Init');
  LOnce.Execute(
    procedure
    begin
      WriteLn('进程 A 正在初始化数据库...');
      InitializeDatabase;
    end
  );
end;

// 进程 B（同时运行）
var
  LOnce: INamedOnce;
begin
  LOnce := MakeNamedOnce('SharedDB.Init');
  LOnce.Execute(
    procedure
    begin
      WriteLn('进程 B 正在初始化数据库...');
      InitializeDatabase;
    end
  );
  // 进程 B 会等待进程 A 完成初始化
end;
```

### 带超时的等待

```pascal
var
  LOnce: INamedOnce;
begin
  LOnce := MakeNamedOnce('SlowInit');
  
  // 另一个进程正在执行初始化
  if LOnce.Wait(5000) then
    WriteLn('初始化完成')
  else
    WriteLn('等待超时');
end;
```

### 错误处理与毒化

```pascal
procedure RiskyInit;
begin
  if Random(2) = 0 then
    raise Exception.Create('初始化失败');
  WriteLn('初始化成功');
end;

var
  LOnce: INamedOnce;
  LConfig: TNamedOnceConfig;
begin
  LConfig := DefaultNamedOnceConfig;
  LConfig.EnablePoisoning := True;
  
  LOnce := MakeNamedOnceWithConfig('RiskyInit', LConfig);
  try
    LOnce.Execute(@RiskyInit);
  except
    on E: Exception do
    begin
      WriteLn('初始化失败: ', E.Message);
      
      if LOnce.IsPoisoned then
        WriteLn('Once 已毒化，需要重置');
    end;
  end;
end;
```

### 强制重新执行

```pascal
var
  LOnce: INamedOnce;
begin
  LOnce := MakeNamedOnce('ConfigReload');
  
  // 首次执行
  LOnce.Execute(@LoadConfig);
  
  // 配置文件更新，需要重新加载
  LOnce.ExecuteForce(@LoadConfig);
end;
```

### 全局命名空间

```pascal
var
  LOnce: INamedOnce;
  LConfig: TNamedOnceConfig;
begin
  LConfig := GlobalNamedOnceConfig;  // 使用全局命名空间
  
  LOnce := MakeNamedOnceWithConfig('Global\SystemInit', LConfig);
  LOnce.Execute(@InitializeSystem);
end;
```

## 平台实现

### Windows

- 使用命名 Mutex + Event 实现
- 支持全局命名空间（`Global\` 前缀）
- 支持会话命名空间（`Local\` 前缀）

### Unix/Linux/macOS

- 使用 POSIX 命名信号量 + 共享内存实现
- 命名格式：`/fafafa.once.<name>`
- 支持跨进程同步

## 使用场景

### 适合的场景

✅ **跨进程全局初始化**
```pascal
// 多个进程共享的资源初始化
LOnce.Execute(@InitializeSharedMemory);
```

✅ **服务启动协调**
```pascal
// 多个服务实例，只有一个执行初始化
LOnce.Execute(@StartBackgroundService);
```

✅ **配置文件加载**
```pascal
// 多进程应用，只加载一次配置
LOnce.Execute(@LoadGlobalConfig);
```

### 不适合的场景

❌ **单进程初始化**
- 使用普通的 `Once`

❌ **需要频繁重置**
- Once 是一次性的，不适合频繁重置

❌ **需要返回值**
- 回调函数不支持返回值

## 注意事项

### 命名规范

⚠️ **使用有意义的名称**
```pascal
// ✅ 好：清晰的命名
MakeNamedOnce('MyApp.Database.Init')
MakeNamedOnce('SharedCache.Warmup')

// ❌ 差：模糊的命名
MakeNamedOnce('init')
MakeNamedOnce('once1')
```

### 资源清理

⚠️ **命名对象需要显式清理**
```pascal
// 创建者进程负责清理
var LOnce := MakeNamedOnce('MyInit');
try
  LOnce.Execute(@Init);
finally
  // 接口引用计数会自动清理
  LOnce := nil;
end;
```

### 毒化状态

⚠️ **初始化失败会导致毒化**
```pascal
// 如果初始化失败，所有进程都会看到毒化状态
try
  LOnce.Execute(@FailingInit);
except
  // 需要重置才能重试
  LOnce.Reset;
end;
```

### 跨进程竞争

⚠️ **避免死锁**
```pascal
// ❌ 错误：在回调中等待其他 Once
LOnce1.Execute(
  procedure
  begin
    LOnce2.Execute(@Init2);  // 可能死锁！
  end
);
```

## 最佳实践

### 1. 使用配置对象

```pascal
var
  LConfig: TNamedOnceConfig;
begin
  LConfig := DefaultNamedOnceConfig;
  LConfig.TimeoutMs := 10000;  // 10 秒超时
  LConfig.EnablePoisoning := True;
  
  LOnce := MakeNamedOnceWithConfig('MyInit', LConfig);
end;
```

### 2. 错误处理

```pascal
try
  LOnce.Execute(@Init);
except
  on E: Exception do
  begin
    LogError('初始化失败: ' + E.Message);
    
    if LOnce.IsPoisoned then
    begin
      // 尝试重置并重试
      LOnce.Reset;
      LOnce.Execute(@Init);
    end;
  end;
end;
```

### 3. 状态检查

```pascal
case LOnce.GetState of
  nosNotStarted: WriteLn('尚未开始');
  nosInProgress: WriteLn('正在执行');
  nosCompleted: WriteLn('已完成');
  nosPoisoned: WriteLn('已毒化');
end;
```

### 4. 超时处理

```pascal
if not LOnce.Wait(5000) then
begin
  WriteLn('等待超时，可能发生死锁');
  // 执行恢复逻辑
end;
```

## 相关模块

- `fafafa.core.sync.once` - 单进程 Once
- `fafafa.core.sync.namedMutex` - 跨进程互斥锁
- `fafafa.core.sync.namedEvent` - 跨进程事件
- `fafafa.core.sync.base` - 同步原语基础接口

## 参考资料

- POSIX Named Semaphores 文档
- Windows Named Kernel Objects 文档
- pthread_once 规范

## 版本历史

- **v1.0** - 初始版本，支持跨进程一次性执行
- 支持毒化机制
- 支持超时等待
- 支持全局命名空间
- 支持强制重新执行
