# fafafa.core.sync.namedSemaphore

## 概述

`fafafa.core.sync.namedSemaphore` 模块提供了高性能、跨平台的命名信号量实现，支持进程间同步和资源计数管理。该模块采用现代化的 RAII 模式设计，完全遵循 `fafafa.core.sync.namedMutex` 的架构模式，符合 Rust、Java、Go 等主流开发语言的最佳实践。

## 核心特性

### ✨ 现代化设计
- **RAII 模式**：自动资源管理，无需手动释放信号量
- **类型安全**：强类型接口，编译时错误检查
- **零成本抽象**：高性能实现，无运行时开销

### 🚀 高性能实现
- **Windows**：原生 Win32 Semaphore API (`CreateSemaphore`/`ReleaseSemaphore`)
- **Unix/Linux**：POSIX named semaphore API (`sem_open`/`sem_post`/`sem_wait`)
- **优化的超时机制**：无轮询，真正的阻塞式超时

### 🌍 跨平台支持
- **完全隐藏平台差异**：统一的 API 接口
- **自动平台检测**：编译时选择最优实现
- **一致的行为**：跨平台相同的语义

### 📊 丰富的信号量类型
- **二进制信号量**：类似互斥锁，但支持多次释放
- **计数信号量**：经典的资源池管理
- **自定义配置**：灵活的初始计数和最大计数设置

## 架构设计

### 模块结构

```
fafafa.core.sync.namedSemaphore/
├── fafafa.core.sync.namedSemaphore.base.pas      # 基础接口定义
├── fafafa.core.sync.namedSemaphore.windows.pas   # Windows 平台实现
├── fafafa.core.sync.namedSemaphore.unix.pas      # Unix/Linux 平台实现
└── fafafa.core.sync.namedSemaphore.pas           # 工厂门面层
```

### 设计模式

本模块完全遵循 `fafafa.core.sync.namedMutex` 的设计模式：

1. **分层架构**：接口层 → 实现层 → 门面层
2. **RAII 守卫**：自动资源管理
3. **工厂模式**：隐藏实现细节
4. **配置驱动**：灵活的参数调整

## 快速开始

### 基本使用

```pascal
uses fafafa.core.sync.namedSemaphore;

var
  LSemaphore: INamedSemaphore;
  LGuard: INamedSemaphoreGuard;
begin
  // 创建命名信号量
  LSemaphore := CreateNamedSemaphore('MyAppSemaphore');

  // RAII 模式：自动管理信号量生命周期
  LGuard := LSemaphore.Wait;
  try
    // 临界区代码
    WriteLn('在信号量保护下执行');
  finally
    LGuard := nil; // 自动释放信号量
  end;
end;
```

### 计数信号量（资源池）

```pascal
var
  LSemaphore: INamedSemaphore;
  LGuards: array[1..3] of INamedSemaphoreGuard;
  I: Integer;
begin
  // 创建资源池：最多3个并发访问
  LSemaphore := CreateCountingSemaphore('ResourcePool', 3);

  // 获取多个资源
  for I := 1 to 3 do
  begin
    LGuards[I] := LSemaphore.TryWait;
    if Assigned(LGuards[I]) then
      WriteLn('获取资源 ', I);
  end;

  // 自动释放所有资源
  for I := 1 to 3 do
    LGuards[I] := nil;
end;
```

### 二进制信号量（事件通知）

```pascal
var
  LSemaphore: INamedSemaphore;
  LGuard: INamedSemaphoreGuard;
begin
  // 创建二进制信号量（初始无信号）
  LSemaphore := CreateBinarySemaphore('EventSignal', False);

  // 在另一个线程/进程中释放信号
  LSemaphore.Release;

  // 等待信号
  LGuard := LSemaphore.Wait;
  WriteLn('收到信号！');
  LGuard := nil;
end;
```

## API 参考

### 工厂函数

#### 主要工厂函数

```pascal
// 基础创建函数
function CreateNamedSemaphore(const AName: string): INamedSemaphore;
function CreateNamedSemaphore(const AName: string; AInitialCount, AMaxCount: Integer): INamedSemaphore;
function CreateNamedSemaphore(const AName: string; const AConfig: TNamedSemaphoreConfig): INamedSemaphore;

// 全局信号量
function CreateGlobalNamedSemaphore(const AName: string): INamedSemaphore;
function CreateGlobalNamedSemaphore(const AName: string; AInitialCount, AMaxCount: Integer): INamedSemaphore;
```

#### 便利函数

```pascal
// 二进制信号量
function CreateBinarySemaphore(const AName: string): INamedSemaphore;
function CreateBinarySemaphore(const AName: string; AInitiallySignaled: Boolean): INamedSemaphore;

// 计数信号量
function CreateCountingSemaphore(const AName: string; AMaxCount: Integer): INamedSemaphore;
function CreateCountingSemaphore(const AName: string; AInitialCount, AMaxCount: Integer): INamedSemaphore;
```

#### 兼容性函数

```pascal
// 向后兼容（推荐使用 CreateNamedSemaphore）
function MakeNamedSemaphore(const AName: string): INamedSemaphore;
function MakeNamedSemaphore(const AName: string; AInitialCount, AMaxCount: Integer): INamedSemaphore;
function TryOpenNamedSemaphore(const AName: string): INamedSemaphore;
```

### 接口定义

#### INamedSemaphore

```pascal
INamedSemaphore = interface
  // 核心信号量操作 - 返回 RAII 守卫
  function Wait: INamedSemaphoreGuard;                              // 阻塞等待
  function TryWait: INamedSemaphoreGuard;                          // 非阻塞尝试
  function TryWaitFor(ATimeoutMs: Cardinal): INamedSemaphoreGuard; // 带超时等待
  
  // 释放操作
  procedure Release; overload;                                      // 释放一个计数
  procedure Release(ACount: Integer); overload;                    // 释放多个计数

  // 查询操作
  function GetName: string;           // 获取信号量名称
  function GetCurrentCount: Integer;  // 获取当前可用计数（如果支持）
  function GetMaxCount: Integer;      // 获取最大计数值
end;
```

#### INamedSemaphoreGuard

```pascal
INamedSemaphoreGuard = interface
  function GetName: string;           // 获取信号量名称
  function GetCount: Integer;         // 获取当前计数值（如果支持）
  // 析构时自动释放信号量，无需手动调用 Release
end;
```

### 配置结构

```pascal
TNamedSemaphoreConfig = record
  TimeoutMs: Cardinal;           // 默认超时时间（毫秒）
  RetryIntervalMs: Cardinal;     // 重试间隔（毫秒）
  MaxRetries: Integer;           // 最大重试次数
  UseGlobalNamespace: Boolean;   // 是否使用全局命名空间
  InitialCount: Integer;         // 初始计数值
  MaxCount: Integer;             // 最大计数值
end;
```

## 使用场景

### 1. 资源池管理

```pascal
// 数据库连接池
var
  LConnectionPool: INamedSemaphore;
  LConnection: INamedSemaphoreGuard;
begin
  LConnectionPool := CreateCountingSemaphore('DBConnectionPool', 10);
  
  LConnection := LConnectionPool.Wait; // 获取连接
  try
    // 使用数据库连接
    ExecuteQuery('SELECT * FROM users');
  finally
    LConnection := nil; // 自动归还连接
  end;
end;
```

### 2. 并发控制

```pascal
// 限制同时下载的文件数
var
  LDownloadSemaphore: INamedSemaphore;
  LGuard: INamedSemaphoreGuard;
begin
  LDownloadSemaphore := CreateCountingSemaphore('DownloadLimit', 3);
  
  LGuard := LDownloadSemaphore.Wait;
  try
    DownloadFile('http://example.com/file.zip');
  finally
    LGuard := nil;
  end;
end;
```

### 3. 事件通知

```pascal
// 进程间事件通知
var
  LEventSemaphore: INamedSemaphore;
  LGuard: INamedSemaphoreGuard;
begin
  LEventSemaphore := CreateBinarySemaphore('ProcessEvent', False);
  
  // 等待事件
  LGuard := LEventSemaphore.Wait;
  WriteLn('事件已触发！');
  LGuard := nil;
end;

// 在另一个进程中触发事件
procedure TriggerEvent;
var
  LEventSemaphore: INamedSemaphore;
begin
  LEventSemaphore := CreateBinarySemaphore('ProcessEvent', False);
  LEventSemaphore.Release; // 触发事件
end;
```

### 4. 生产者-消费者模式

```pascal
// 生产者
procedure Producer;
var
  LBufferSemaphore: INamedSemaphore;
begin
  LBufferSemaphore := CreateCountingSemaphore('Buffer', 0, 100);
  
  // 生产数据
  ProduceData;
  LBufferSemaphore.Release; // 通知有新数据
end;

// 消费者
procedure Consumer;
var
  LBufferSemaphore: INamedSemaphore;
  LGuard: INamedSemaphoreGuard;
begin
  LBufferSemaphore := CreateCountingSemaphore('Buffer', 0, 100);
  
  LGuard := LBufferSemaphore.Wait; // 等待数据
  try
    ConsumeData;
  finally
    LGuard := nil;
  end;
end;
```

## 平台差异

### Windows 平台

- **API**：使用 `CreateSemaphore`/`ReleaseSemaphore`
- **命名规则**：支持 `Global\` 和 `Local\` 前缀
- **最大长度**：260 字符 (MAX_PATH)
- **计数查询**：不支持查询当前计数（返回 -1）
- **超时支持**：完整支持毫秒级超时

### Unix/Linux 平台

- **API**：使用 POSIX named semaphore (`sem_open`/`sem_post`/`sem_wait`)
- **命名规则**：自动添加 `/` 前缀，符合 POSIX 规范
- **最大长度**：255 字符 (NAME_MAX)
- **计数查询**：支持查询当前计数（`sem_getvalue`）
- **超时支持**：支持 `sem_timedwait`

## 命名规则

### Windows 平台

- 名称长度限制：260 字符 (MAX_PATH)
- 支持 `Global\` 前缀：跨会话共享
- 支持 `Local\` 前缀：当前会话内共享
- 不能包含反斜杠（除前缀外）

### Unix/Linux 平台

- 名称长度限制：255 字符 (NAME_MAX)
- 自动添加 `/` 前缀符合 POSIX 规范
- 不能包含额外的 `/` 字符
- 区分大小写

## 错误处理

### 异常类型

- `EInvalidArgument`: 无效的信号量名称或计数参数
- `ELockError`: 信号量操作失败
- `ETimeoutError`: 获取超时

### 常见错误

```pascal
// 无效名称
try
  CreateNamedSemaphore('');
except
  on E: EInvalidArgument do
    WriteLn('错误：', E.Message);
end;

// 无效计数
try
  CreateNamedSemaphore('test', -1, 5);
except
  on E: EInvalidArgument do
    WriteLn('错误：', E.Message);
end;

// 超时处理
var
  LGuard: INamedSemaphoreGuard;
begin
  LGuard := LSemaphore.TryWaitFor(1000);
  if not Assigned(LGuard) then
    WriteLn('获取信号量超时');
end;
```

## 最佳实践

### 1. 使用 RAII 模式

```pascal
// ✅ 推荐：使用 RAII 守卫
var LGuard := LSemaphore.Wait;
try
  // 临界区代码
finally
  LGuard := nil; // 自动释放
end;

// ❌ 不推荐：手动管理（已弃用）
LSemaphore.Acquire;
try
  // 临界区代码
finally
  LSemaphore.Release;
end;
```

### 2. 合理设置计数

```pascal
// ✅ 根据实际资源数设置
var LConnectionPool := CreateCountingSemaphore('DBPool', 10, 10);

// ❌ 避免过大的计数值
var LBadPool := CreateCountingSemaphore('BadPool', 1000000, 1000000);
```

### 3. 处理超时

```pascal
// ✅ 合理的超时处理
var LGuard := LSemaphore.TryWaitFor(5000); // 5秒超时
if Assigned(LGuard) then
begin
  // 处理资源
  LGuard := nil;
end
else
  WriteLn('资源繁忙，请稍后重试');
```

### 4. 命名约定

```pascal
// ✅ 清晰的命名
var LDatabasePool := CreateCountingSemaphore('MyApp.Database.ConnectionPool', 10);
var LFileAccess := CreateBinarySemaphore('MyApp.FileAccess.ConfigFile');

// ❌ 模糊的命名
var LSem1 := CreateNamedSemaphore('sem1');
```

### 5. 错误处理

```pascal
// ✅ 完整的错误处理
try
  var LSemaphore := CreateNamedSemaphore('MyResource', 5, 10);
  var LGuard := LSemaphore.TryWaitFor(1000);
  if Assigned(LGuard) then
  begin
    // 使用资源
    LGuard := nil;
  end
  else
    WriteLn('获取资源超时');
except
  on E: EInvalidArgument do
    WriteLn('参数错误：', E.Message);
  on E: ELockError do
    WriteLn('信号量错误：', E.Message);
end;
```

## 性能考虑

### 1. 平台选择
- **Windows**：使用内核对象，性能优异
- **Unix/Linux**：使用 POSIX 信号量，跨平台兼容性好

### 2. 计数管理
- 避免频繁的大量释放操作
- 合理设置初始计数和最大计数

### 3. 超时设置
- 根据应用场景设置合理的超时值
- 避免无限等待（除非确实需要）

## 示例程序

模块提供了完整的示例程序：

- `example_namedSemaphore_basic.lpr` - 基础功能演示
- `example_namedSemaphore_crossprocess.lpr` - 跨进程演示

运行示例：
```bash
# 编译并运行基础示例
lazbuild examples/fafafa.core.sync.namedSemaphore/example_namedSemaphore_basic.lpr
./examples/fafafa.core.sync.namedSemaphore/bin/example_namedSemaphore_basic

# 跨进程演示
./examples/fafafa.core.sync.namedSemaphore/bin/example_namedSemaphore_crossprocess server
./examples/fafafa.core.sync.namedSemaphore/bin/example_namedSemaphore_crossprocess client 1
```

## 版本历史

- **v1.0.0** - 初始版本
  - 完整的跨平台信号量实现
  - RAII 模式支持
  - 丰富的工厂函数
  - 完整的测试套件和文档
