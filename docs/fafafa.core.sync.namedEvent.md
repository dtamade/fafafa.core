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

## Unix 平台详解

### 权限管理

#### 创建权限

命名事件在 Unix 平台上使用 POSIX 命名信号量 + 共享内存实现，创建时需要指定权限：

```pascal
// 默认权限：0644 (rw-r--r--)
LEvent := MakeNamedEvent('MyEvent', False, False);

// 自定义权限
LConfig := DefaultNamedEventConfig;
LConfig.Permissions := &0666;  // rw-rw-rw-
LEvent := MakeNamedEventWithConfig('MyEvent', False, False, LConfig);
```

**权限说明**：
- **0644** (默认)：所有者可读写，组和其他用户只读
- **0666**：所有用户可读写
- **0600**：仅所有者可读写
- **0660**：所有者和组可读写

**权限影响**：
- 创建者进程的 umask 会影响最终权限
- 其他进程访问时需要有相应的读写权限
- 权限不足会导致 `sem_open` 或 `shm_open` 失败并返回 `EACCES` 错误

#### 所有权

- 命名事件对象的所有者是创建它的进程的有效用户ID (euid)
- 所有者可以修改权限（通过 `chmod` 或 `fchmod` 系统调用）
- 非所有者进程需要有相应权限才能访问

### 命名空间管理

#### 命名规则

Unix 平台的命名事件遵循 POSIX 命名规范：

```pascal
// 自动添加 /fafafa_event_ 前缀
LEvent := MakeNamedEvent('MyEvent', False, False);
// 实际名称：/fafafa_event_MyEvent

// 不能包含额外的 / 字符
LEvent := MakeNamedEvent('App/MyEvent', False, False);  // 错误！会抛出异常
```

**命名限制**：
- 名称长度：最多 255 字符 (NAME_MAX)
- 必须以字母或数字开头
- 只能包含字母、数字、下划线、点号
- 不能包含 `/` 字符（除了自动添加的前缀）
- 区分大小写：`MyEvent` 和 `myevent` 是不同的事件

#### 命名空间隔离

Unix 平台的命名事件是**全局的**，没有类似 Windows 的 `Global\` 和 `Local\` 命名空间：

```pascal
// Unix 平台：所有进程共享同一命名空间
// 进程 A
LEvent := MakeNamedEvent('SharedEvent', False, False);

// 进程 B（不同用户）
LEvent := MakeNamedEvent('SharedEvent', False, False);  // 访问同一个事件（如果权限允许）
```

**命名空间特点**：
- 所有进程共享同一命名空间
- 不同用户的进程可以访问同一命名对象（如果权限允许）
- 建议使用应用程序特定的前缀避免冲突：
  ```pascal
  LEvent := MakeNamedEvent('MyApp.Module.Event', False, False);
  ```

#### 命名冲突处理

```pascal
// 场景1：同名事件已存在
LEvent1 := MakeNamedEvent('SharedEvent', False, False);  // 创建
LEvent2 := MakeNamedEvent('SharedEvent', False, False);  // 打开现有的

// 场景2：避免冲突的命名策略
LEvent := MakeNamedEvent('com.mycompany.myapp.event', False, False);  // 使用反向域名
LEvent := MakeNamedEvent(Format('MyApp.%d.Event', [GetProcessID]), False, False);  // 包含进程ID
```

### 清理语义

#### 自动清理

Unix 平台的命名事件具有以下自动清理特性：

**进程退出时**：
- 进程持有的事件资源会自动释放
- 信号量和共享内存的引用计数减1
- 如果引用计数降为0，对象会被标记为删除

**系统重启时**：
- 所有命名事件会被清理
- 不会留下"僵尸"对象

#### 手动清理

```pascal
// 方式1：通过接口引用计数自动清理
var
  LEvent: INamedEvent;
begin
  LEvent := MakeNamedEvent('MyEvent', False, False);
  // 使用事件...
  LEvent := nil;  // 自动调用 sem_close 和 shm_unlink
end;

// 方式2：显式删除（仅创建者）
LEvent := MakeNamedEvent('MyEvent', False, False);
// 使用完毕后
sem_unlink('/fafafa_event_MyEvent');  // 从系统中删除（需要手动调用系统API）
shm_unlink('/fafafa_event_MyEvent');
```

**清理注意事项**：
- `sem_close` 和关闭共享内存只是关闭当前进程的引用，不会删除对象
- `sem_unlink` 和 `shm_unlink` 会从系统中删除对象，但已打开的引用仍然有效
- 建议由创建者进程负责调用 unlink 清理

#### 资源泄漏预防

```pascal
// 好的做法：使用 try-finally 确保清理
var
  LEvent: INamedEvent;
begin
  LEvent := MakeNamedEvent('MyEvent', False, False);
  try
    // 使用事件...
  finally
    LEvent := nil;  // 确保释放
  end;
end;
```

### 系统限制

#### 资源限制

Unix 系统对命名信号量和共享内存有以下限制：

```bash
# 查看信号量限制
cat /proc/sys/kernel/sem

# 查看共享内存限制
cat /proc/sys/kernel/shmmax
cat /proc/sys/kernel/shmmni
```

**常见限制**：
- **信号量数量**：系统范围内的信号量总数（通常为 32000）
- **共享内存段数量**：系统范围内的共享内存段数量（通常为 4096）

**超出限制时**：
- `sem_open` 或 `shm_open` 会失败并返回 `ENOSPC` 错误
- 需要清理未使用的对象或调整系统限制

#### 文件系统位置

命名事件对象在文件系统中的位置：

```bash
# Linux
/dev/shm/sem.fafafa_event_MyEvent
/dev/shm/fafafa_event_MyEvent

# macOS
/var/tmp/sem.fafafa_event_MyEvent
/var/tmp/fafafa_event_MyEvent

# 查看所有命名事件对象
ls -l /dev/shm/fafafa_event_* 2>/dev/null || ls -l /var/tmp/fafafa_event_* 2>/dev/null
```

### 事件特性

#### 手动/自动重置

Unix 平台的命名事件支持手动和自动重置模式：

```pascal
// 手动重置事件（需要显式调用 Reset）
LEvent := MakeNamedEvent('ManualEvent', False, False);
LEvent.Set;     // 设置为有信号状态
// 所有等待的线程被唤醒
LEvent.Reset;   // 需要手动重置

// 自动重置事件（唤醒一个线程后自动重置）
LEvent := MakeNamedEvent('AutoEvent', False, True);
LEvent.Set;     // 设置为有信号状态
// 只有一个等待的线程被唤醒，事件自动重置
```

**模式特点**：
- **手动重置**：适合广播场景，唤醒所有等待线程
- **自动重置**：适合单一通知场景，只唤醒一个线程

#### 初始状态

```pascal
// 创建时设置初始状态
LEvent := MakeNamedEvent('MyEvent', True, False);  // 初始为有信号状态
LEvent := MakeNamedEvent('MyEvent', False, False); // 初始为无信号状态
```

### 跨平台差异

#### Windows vs Unix

| 特性 | Windows | Unix/Linux |
|------|---------|------------|
| 实现机制 | 内核 Event 对象 | 信号量 + 共享内存 |
| 命名空间 | `Global\` / `Local\` | 全局（无隔离） |
| 权限模型 | ACL（访问控制列表） | Unix 权限（rwx） |
| Pulse 操作 | 支持 | 不支持（模拟实现） |
| 超时控制 | 支持 | 支持 |
| 自动清理 | 进程退出时自动 | 进程退出时自动 |
| 持久化 | 仅在进程存在时 | 仅在进程存在时 |
| 系统重启 | 自动清理 | 自动清理 |

#### 可移植性建议

```pascal
// 好的做法：使用统一的命名约定
{$IFDEF WINDOWS}
  LEvent := MakeNamedEvent('Global\MyApp.Event', False, False);
{$ELSE}
  LEvent := MakeNamedEvent('MyApp.Event', False, False);
{$ENDIF}

// 更好的做法：使用配置抽象平台差异
LConfig := DefaultNamedEventConfig;
{$IFDEF WINDOWS}
  LConfig.UseGlobalNamespace := True;
{$ELSE}
  LConfig.Permissions := &0666;
{$ENDIF}
LEvent := MakeNamedEventWithConfig('MyApp.Event', False, False, LConfig);
```

### 调试与诊断

#### 查看命名事件对象

```bash
# Linux：查看所有命名事件对象
ls -lh /dev/shm/fafafa_event_*
ls -lh /dev/shm/sem.fafafa_event_*

# macOS：查看所有命名事件对象
ls -lh /var/tmp/fafafa_event_*
ls -lh /var/tmp/sem.fafafa_event_*
```

#### 清理僵尸事件对象

```bash
# 手动删除未使用的事件对象
rm /dev/shm/fafafa_event_MyEvent
rm /dev/shm/sem.fafafa_event_MyEvent

# 清理所有事件对象（谨慎使用！）
rm /dev/shm/fafafa_event_*
rm /dev/shm/sem.fafafa_event_*
```

#### 常见问题诊断

**问题1：权限不足**
```
错误：sem_open 或 shm_open failed with EACCES
原因：当前用户没有访问权限
解决：
1. 检查对象文件权限：ls -l /dev/shm/fafafa_event_MyEvent
2. 修改权限：chmod 666 /dev/shm/fafafa_event_MyEvent
3. 或使用更宽松的创建权限：LConfig.Permissions := &0666
```

**问题2：资源耗尽**
```
错误：sem_open 或 shm_open failed with ENOSPC
原因：系统资源数量达到上限
解决：
1. 查看系统限制：cat /proc/sys/kernel/sem
2. 清理未使用的对象：rm /dev/shm/fafafa_event_*
3. 调整系统限制（需要 root）：sysctl -w kernel.sem="250 32000 32 256"
```

**问题3：名称冲突**
```
错误：不同应用使用相同名称
原因：命名空间全局共享
解决：使用应用程序特定的前缀
LEvent := MakeNamedEvent('com.mycompany.myapp.event', False, False);
```

**问题4：事件状态不一致**
```
错误：事件状态与预期不符
原因：多个进程同时操作或异常退出
解决：
1. 检查是否有进程异常退出未清理
2. 必要时重新创建事件对象
3. 使用手动重置模式避免自动重置带来的竞态
```

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
