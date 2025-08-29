# fafafa.core.sync.namedEvent

## 概述

`fafafa.core.sync.namedEvent` 模块提供了高性能、跨平台的命名事件实现，支持进程间同步。该模块采用现代化的 RAII 模式设计，符合 Rust、Java、Go 等主流开发语言的最佳实践。

## 核心特性

### ✨ 现代化设计
- **RAII 模式**：自动资源管理，无需手动释放事件
- **类型安全**：强类型接口，编译时错误检查
- **零成本抽象**：高性能实现，无运行时开销

### 🚀 高性能实现
- **Windows**：原生 Win32 Event API
- **Unix/Linux**：pthread_mutex + pthread_cond + 共享内存，支持跨进程同步
- **优化的超时机制**：无轮询，真正的阻塞式超时

### 🌍 跨平台支持
- **完全隐藏平台差异**：统一的 API 接口
- **自动平台检测**：编译时选择最优实现
- **一致的行为**：跨平台相同的语义

## 架构设计

### 模块结构

```
fafafa.core.sync.namedEvent/
├── fafafa.core.sync.namedEvent.base.pas      # 基础接口定义
├── fafafa.core.sync.namedEvent.windows.pas   # Windows 平台实现
├── fafafa.core.sync.namedEvent.unix.pas      # Unix/Linux 平台实现
└── fafafa.core.sync.namedEvent.pas           # 工厂门面层
```

## 快速开始

### 基本使用

```pascal
uses fafafa.core.sync.namedEvent;

var
  LEvent: INamedEvent;
  LGuard: INamedEventGuard;
begin
  // 创建命名事件（简化的工厂函数）
  LEvent := CreateNamedEvent('MyAppEvent');

  // RAII 模式：自动管理事件生命周期
  LGuard := LEvent.Wait;
  try
    // 事件已触发，执行相关代码
    WriteLn('事件已触发');
  finally
    LGuard := nil; // 自动清理资源
  end;
end;
```

### 非阻塞尝试

```pascal
var
  LEvent: INamedEvent;
  LGuard: INamedEventGuard;
begin
  LEvent := CreateNamedEvent('MyAppEvent');

  // 非阻塞尝试等待事件
  LGuard := LEvent.TryWait;
  if Assigned(LGuard) then
  begin
    // 事件已触发
    WriteLn('事件已触发，执行相关代码');
    LGuard := nil; // 释放资源
  end
  else
    WriteLn('事件未触发');
end;
```

### 带超时的等待

```pascal
var
  LEvent: INamedEvent;
  LGuard: INamedEventGuard;
begin
  LEvent := CreateNamedEvent('MyAppEvent');

  // 等待最多 5 秒
  LGuard := LEvent.TryWaitFor(5000);
  if Assigned(LGuard) then
  begin
    WriteLn('在超时内事件被触发');
    LGuard := nil;
  end
  else
    WriteLn('超时，事件未被触发');
end;
```

### 手动重置事件

```pascal
var
  LEvent: INamedEvent;
  LGuard, LGuard2: INamedEventGuard;
begin
  // 创建手动重置事件
  LEvent := CreateNamedEvent('MyManualEvent', True, False); // 手动重置，初始未触发

  // 设置事件
  LEvent.Signal;

  // 多个等待者都能成功获取
  LGuard := LEvent.TryWait;
  if Assigned(LGuard) then
    WriteLn('第一个等待者成功');

  LGuard2 := LEvent.TryWait;
  if Assigned(LGuard2) then
    WriteLn('第二个等待者也成功');

  // 手动重置事件
  LEvent.Reset;
end;
```

### 自动重置事件

```pascal
var
  LEvent: INamedEvent;
  LGuard: INamedEventGuard;
begin
  // 创建自动重置事件
  LEvent := MakeAutoResetNamedEvent('MyAutoEvent', False);

  // 设置事件
  LEvent.SetEvent;

  // 只有第一个等待者能成功获取
  LGuard := LEvent.TryWait;
  if Assigned(LGuard) then
    WriteLn('第一个等待者成功');

  LGuard := LEvent.TryWait;
  if not Assigned(LGuard) then
    WriteLn('第二个等待者失败（自动重置）');
end;
```

## API 参考

### 核心接口

#### INamedEvent

主要的命名事件接口。

```pascal
INamedEvent = interface
  // 现代化事件操作（推荐使用）
  function Wait: INamedEventGuard;                              // 阻塞等待
  function TryWait: INamedEventGuard;                          // 非阻塞尝试
  function TryWaitFor(ATimeoutMs: Cardinal): INamedEventGuard; // 带超时等待

  // 事件控制操作
  procedure SetEvent;                 // 触发事件
  procedure ResetEvent;               // 重置事件（仅手动重置事件有效）
  procedure PulseEvent;               // 脉冲事件（触发后立即重置）

  // 查询操作
  function GetName: string;           // 获取事件名称
  function IsManualReset: Boolean;    // 是否手动重置事件
  function IsSignaled: Boolean;       // 当前是否已触发
end;
```

#### INamedEventGuard

RAII 模式的事件等待守卫，析构时自动清理资源。

```pascal
INamedEventGuard = interface
  function GetName: string;           // 获取事件名称
  function IsSignaled: Boolean;       // 检查是否已触发
  // 析构时自动清理资源，无需手动调用
end;
```

### 工厂函数

#### 工厂函数

```pascal
// 创建命名事件 - 完整配置版本
function MakeNamedEvent(const AName: string; const AConfig: TNamedEventConfig): INamedEvent;

// 创建命名事件 - 简化版本（使用默认配置）
function MakeNamedEvent(const AName: string): INamedEvent;

// 创建手动重置命名事件
function MakeManualResetNamedEvent(const AName: string; AInitialState: Boolean = False): INamedEvent;

// 创建自动重置命名事件
function MakeAutoResetNamedEvent(const AName: string; AInitialState: Boolean = False): INamedEvent;

// 创建全局命名事件（跨会话共享）
function MakeGlobalNamedEvent(const AName: string; AManualReset: Boolean = False; AInitialState: Boolean = False): INamedEvent;
```

#### 便利函数

```pascal
// 便利函数：创建命名事件（推荐使用）
function MakeNamedEvent(const AName: string): INamedEvent;
function MakeNamedEvent(const AName: string; AManualReset: Boolean): INamedEvent; overload;
function MakeNamedEvent(const AName: string; AManualReset: Boolean; AInitialState: Boolean): INamedEvent; overload;

// 便利函数：创建全局命名事件
function MakeGlobalNamedEvent(const AName: string): INamedEvent;
function MakeGlobalNamedEvent(const AName: string; AManualReset: Boolean): INamedEvent; overload;
function MakeGlobalNamedEvent(const AName: string; AManualReset: Boolean; AInitialState: Boolean): INamedEvent; overload;
```

### 配置结构

```pascal
TNamedEventConfig = record
  TimeoutMs: Cardinal;           // 默认超时时间（毫秒）
  RetryIntervalMs: Cardinal;     // 重试间隔（毫秒）
  MaxRetries: Integer;           // 最大重试次数
  UseGlobalNamespace: Boolean;   // 是否使用全局命名空间
  ManualReset: Boolean;          // 是否手动重置（true=手动，false=自动）
  InitialState: Boolean;         // 初始状态（true=已触发，false=未触发）
end;
```

### 配置辅助函数

```pascal
function DefaultNamedEventConfig: TNamedEventConfig;
function NamedEventConfigWithTimeout(ATimeoutMs: Cardinal): TNamedEventConfig;
function GlobalNamedEventConfig: TNamedEventConfig;
function ManualResetNamedEventConfig: TNamedEventConfig;
function AutoResetNamedEventConfig: TNamedEventConfig;
```

## 使用场景

### 进程间通信

```pascal
// 进程 A (生产者)
var
  LEvent: INamedEvent;
begin
  LEvent := MakeNamedEvent('DataReady');
  
  // 处理数据
  ProcessData;
  
  // 通知其他进程数据已准备好
  LEvent.SetEvent;
  WriteLn('数据处理完成，已通知其他进程');
end;

// 进程 B (消费者)
var
  LEvent: INamedEvent;
  LGuard: INamedEventGuard;
begin
  LEvent := MakeNamedEvent('DataReady'); // 同名

  LGuard := LEvent.Wait; // 等待数据准备好
  try
    // 处理数据
    ConsumeData;
    WriteLn('数据消费完成');
  finally
    LGuard := nil;
  end;
end;
```

### 全局事件

```pascal
var
  LEvent: INamedEvent;
begin
  // 创建跨会话的全局事件
  LEvent := CreateGlobalNamedEvent('GlobalAppEvent');

  LEvent.Signal;
  WriteLn('全局事件已触发');
end;
```

## 命名规则

### Windows 平台

- 名称长度限制：260 字符 (MAX_PATH)
- 支持 `Global\` 前缀：跨会话共享
- 支持 `Local\` 前缀：当前会话内共享
- 不能包含反斜杠（除前缀外）

### Unix/Linux 平台

- 名称长度限制：255 字符 (NAME_MAX)
- 自动添加 `/fafafa_event_` 前缀符合 POSIX 规范
- 不能包含额外的 `/` 字符
- 区分大小写

## 错误处理

### 异常类型

- `EInvalidArgument`: 无效的事件名称
- `ELockError`: 事件操作失败
- `ETimeoutError`: 获取超时（某些平台）

### 常见错误

```pascal
try
  LEvent := MakeNamedEvent('');
except
  on E: EInvalidArgument do
    WriteLn('错误：事件名称不能为空');
end;

try
  LEvent := MakeNamedEvent('Test/Event'); // Unix 平台不允许
except
  on E: EInvalidArgument do
    WriteLn('错误：事件名称包含无效字符');
end;
```

## 最佳实践

### 1. 使用 RAII 模式

**推荐：**
```pascal
var
  LGuard: INamedEventGuard;
begin
  LGuard := LEvent.Wait;
  try
    // 处理事件
  finally
    LGuard := nil; // 自动清理
  end;
end;
```

**不推荐：**
```pascal
begin
  LEvent.Acquire; // 已弃用
  try
    // 处理事件
  finally
    LEvent.Release; // 已弃用
  end;
end;
```

### 2. 选择合适的事件类型

- **手动重置事件**：适用于状态通知，多个等待者需要同时响应
- **自动重置事件**：适用于任务分发，只有一个等待者应该响应

### 3. 合理设置超时

```pascal
// 短超时用于快速检查
LWaiter := LEvent.TryWaitFor(100);

// 长超时用于正常等待
LWaiter := LEvent.TryWaitFor(30000);

// 无限等待（谨慎使用）
LWaiter := LEvent.Wait;
```

### 4. 错误处理

```pascal
try
  LWaiter := LEvent.TryWaitFor(5000);
  if Assigned(LWaiter) then
  begin
    // 处理事件
  end
  else
  begin
    // 处理超时
    WriteLn('等待超时');
  end;
except
  on E: ELockError do
    WriteLn('事件操作失败: ' + E.Message);
end;
```

## 性能考虑

### 1. 避免频繁创建/销毁

**推荐：**
```pascal
var
  LEvent: INamedEvent;
begin
  LEvent := MakeNamedEvent('MyEvent'); // 创建一次

  // 多次使用
  for I := 1 to 100 do
  begin
    LWaiter := LEvent.TryWait;
    // 处理...
  end;
end;
```

### 2. 选择合适的超时值

- 避免过短的超时导致 CPU 浪费
- 避免过长的超时影响响应性

### 3. 平台特定优化

- **Windows**：使用原生 Event API，性能最优
- **Unix**：使用共享内存 + pthread，跨进程开销较小

## 线程安全

所有 `INamedEvent` 接口方法都是线程安全的，可以在多线程环境中安全使用：

```pascal
// 线程 1
procedure Thread1;
begin
  LEvent.SetEvent;
end;

// 线程 2
procedure Thread2;
var
  LGuard: INamedEventGuard;
begin
  LGuard := LEvent.Wait;
  // 安全地处理事件
end;
```

## 跨平台注意事项

### 1. 命名约定

使用简单的字母数字命名，避免特殊字符：

```pascal
// 推荐
LEvent := MakeNamedEvent('MyApp_DataReady');

// 避免
LEvent := MakeNamedEvent('My/App\\Data:Ready'); // 可能在某些平台失败
```

### 2. 全局命名空间

```pascal
// Windows: 使用 Global\ 前缀
LEvent := MakeGlobalNamedEvent('MyEvent');

// Unix: 自动处理全局命名空间
LEvent := MakeNamedEvent('MyEvent'); // 默认就是全局的
```

### 3. 权限考虑

- **Windows**：可能需要适当的权限访问全局命名空间
- **Unix**：共享内存权限由文件系统权限控制

## 调试技巧

### 1. 启用详细日志

```pascal
{$IFDEF DEBUG}
WriteLn('创建事件: ' + LEvent.GetName);
WriteLn('事件类型: ' + IfThen(LEvent.IsManualReset, '手动重置', '自动重置'));
{$ENDIF}
```

### 2. 检查事件状态

```pascal
WriteLn('事件已触发: ' + BoolToStr(LEvent.IsSignaled, True));
WriteLn('是否创建者: ' + BoolToStr(LEvent.IsCreator, True));
```

### 3. 超时调试

```pascal
var
  LStartTime: TDateTime;
begin
  LStartTime := Now;
  LWaiter := LEvent.TryWaitFor(5000);
  WriteLn('等待时间: ' + FormatFloat('0.000', (Now - LStartTime) * 24 * 60 * 60) + ' 秒');
end;
```

## 示例项目

完整的示例项目可以在 `examples/fafafa.core.sync.namedEvent/` 目录中找到，包括：

- 基本使用示例
- 进程间通信示例
- 多线程同步示例
- 错误处理示例

## 相关模块

- `fafafa.core.sync.namedMutex` - 命名互斥锁
- `fafafa.core.sync.event` - 本地事件
- `fafafa.core.sync.semaphore` - 信号量
- `fafafa.core.sync.barrier` - 屏障同步

## 版本历史

- **v1.0.0** - 初始版本，支持基本的命名事件功能
- 基于 `fafafa.core.sync.namedMutex` 的成熟架构设计
- 完整的跨平台支持和 RAII 模式
