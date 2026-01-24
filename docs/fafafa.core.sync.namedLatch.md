# fafafa.core.sync.namedLatch

## 概述

namedLatch 是一个跨进程的倒计数门闩同步原语，允许多个进程协调等待一组事件完成。它是 `Latch` 的命名版本，支持跨进程同步。

## 核心概念

### 跨进程倒计数

namedLatch 通过命名的共享内存或内核对象实现跨进程同步：
- 多个进程可以通过相同的名称访问同一个 Latch 实例
- 任何进程都可以调用 `CountDown` 减少计数
- 所有进程都可以调用 `Wait` 等待计数归零
- 计数到达 0 后，所有等待的进程被唤醒

### 与非命名 Latch 的区别

| 特性 | Latch | namedLatch |
|------|-------|------------|
| 作用域 | 单进程 | 跨进程 |
| 命名 | 无 | 必须指定名称 |
| 资源 | 内存 | 共享内存/内核对象 |
| 清理 | 自动 | 需要显式清理 |

## API 参考

### 类型定义

```pascal
type
  TNamedLatchConfig = record
    TimeoutMs: Cardinal;           // 等待超时时间（毫秒）
    UseGlobalNamespace: Boolean;   // 是否使用全局命名空间
  end;

  INamedLatch = interface(ISynchronizable)
    procedure CountDown;
    procedure CountDownBy(ACount: Cardinal);
    function Wait(ATimeoutMs: Cardinal = High(Cardinal)): Boolean;
    function TryWait: Boolean;
    function GetCount: Cardinal;
    function IsOpen: Boolean;
    function GetName: string;
  end;
```

### 创建 namedLatch

```pascal
function MakeNamedLatch(const AName: string; AInitialCount: Cardinal): INamedLatch;
function MakeNamedLatchWithConfig(const AName: string; AInitialCount: Cardinal; const AConfig: TNamedLatchConfig): INamedLatch;
```

创建或打开一个命名的 Latch 实例。

**参数**：
- `AName` - Latch 的名称（跨进程唯一标识）
- `AInitialCount` - 初始计数值
- `AConfig` - 配置选项（可选）

**返回值**：
- `INamedLatch` - Latch 接口实例

### CountDown

```pascal
procedure CountDown;
```

减少计数 1。

**行为**：
- 原子地将计数减 1
- 如果计数已经为 0，则什么都不做
- 当计数降为 0 时，唤醒所有等待的进程

### CountDownBy

```pascal
procedure CountDownBy(ACount: Cardinal);
```

减少计数指定值。

**参数**：
- `ACount` - 要减少的计数值

**行为**：
- 原子地将计数减少 `ACount`
- 如果计数已经为 0，则什么都不做

### Wait

```pascal
function Wait(ATimeoutMs: Cardinal = High(Cardinal)): Boolean;
```

等待计数归零。

**参数**：
- `ATimeoutMs` - 超时时间（毫秒），默认无限等待

**返回值**：
- `True` - 计数已归零
- `False` - 超时

### TryWait

```pascal
function TryWait: Boolean;
```

尝试等待（非阻塞）。

**返回值**：
- `True` - 计数已归零
- `False` - 计数尚未归零

### GetCount

```pascal
function GetCount: Cardinal;
```

获取当前计数值。

**返回值**：
- 当前计数值

**注意**：
- 这是一个瞬时值，主要用于调试和监控

### IsOpen

```pascal
function IsOpen: Boolean;
```

检查门闩是否已打开（计数为 0）。

**返回值**：
- `True` - 门闩已打开
- `False` - 门闩未打开

## 使用示例

### 基本用法

```pascal
uses
  fafafa.core.sync.namedLatch;

// 进程 A（主进程）
var
  LLatch: INamedLatch;
begin
  LLatch := MakeNamedLatch('MyApp.StartGate', 3);
  
  // 等待 3 个工作进程准备就绪
  LLatch.Wait;
  WriteLn('所有进程已准备就绪，开始工作');
end;

// 进程 B、C、D（工作进程）
var
  LLatch: INamedLatch;
begin
  LLatch := MakeNamedLatch('MyApp.StartGate', 3);
  
  // 准备工作...
  WriteLn('进程准备完成');
  
  // 通知主进程
  LLatch.CountDown;
end;
```

### 跨进程启动协调

```pascal
// 主进程：等待所有服务启动
var
  LLatch: INamedLatch;
begin
  LLatch := MakeNamedLatch('Services.StartupLatch', 5);
  
  WriteLn('等待 5 个服务启动...');
  if LLatch.Wait(30000) then
    WriteLn('所有服务已启动')
  else
    WriteLn('启动超时');
end;

// 各个服务进程
var
  LLatch: INamedLatch;
begin
  LLatch := MakeNamedLatch('Services.StartupLatch', 5);
  
  // 初始化服务
  InitializeService;
  
  // 通知启动完成
  LLatch.CountDown;
  WriteLn('服务已启动');
end;
```

### 批量任务完成等待

```pascal
// 主进程：分配任务并等待完成
var
  LLatch: INamedLatch;
  LTaskCount: Integer;
begin
  LTaskCount := 10;
  LLatch := MakeNamedLatch('Tasks.CompletionLatch', LTaskCount);
  
  // 分配任务给工作进程...
  DistributeTasks(LTaskCount);
  
  // 等待所有任务完成
  WriteLn('等待任务完成...');
  LLatch.Wait;
  WriteLn('所有任务已完成');
end;

// 工作进程：处理任务
var
  LLatch: INamedLatch;
begin
  LLatch := MakeNamedLatch('Tasks.CompletionLatch', 10);
  
  // 处理任务
  ProcessTask;
  
  // 通知完成
  LLatch.CountDown;
end;
```

### 带超时的等待

```pascal
var
  LLatch: INamedLatch;
begin
  LLatch := MakeNamedLatch('SlowTasks', 5);
  
  // 等待最多 10 秒
  if LLatch.Wait(10000) then
    WriteLn('任务完成')
  else
  begin
    WriteLn('等待超时，剩余: ', LLatch.GetCount);
    // 执行超时处理
  end;
end;
```

### 非阻塞检查

```pascal
var
  LLatch: INamedLatch;
begin
  LLatch := MakeNamedLatch('BackgroundTasks', 3);
  
  // 非阻塞检查
  while not LLatch.TryWait do
  begin
    WriteLn('任务进行中，剩余: ', LLatch.GetCount);
    Sleep(1000);
    
    // 执行其他工作
    DoOtherWork;
  end;
  
  WriteLn('所有任务完成');
end;
```

### 批量倒计数

```pascal
var
  LLatch: INamedLatch;
begin
  LLatch := MakeNamedLatch('BatchTasks', 100);
  
  // 批量完成 10 个任务
  ProcessBatch(10);
  LLatch.CountDownBy(10);
  
  WriteLn('批次完成，剩余: ', LLatch.GetCount);
end;
```

## 平台实现

### Windows

- 使用命名 Semaphore 实现
- 支持全局命名空间（`Global\` 前缀）
- 支持会话命名空间（`Local\` 前缀）

### Unix/Linux/macOS

- 使用 POSIX 命名信号量 + 共享内存实现
- 命名格式：`/fafafa.latch.<name>`
- 支持跨进程同步

## 使用场景

### 适合的场景

✅ **跨进程启动协调**
```pascal
// 等待所有服务启动
LLatch.Wait;
```

✅ **批量任务完成等待**
```pascal
// 等待所有工作进程完成
LLatch.Wait;
```

✅ **分阶段执行**
```pascal
// 每个阶段使用一个 Latch
Phase1Latch.Wait;
Phase2Latch.Wait;
```

### 不适合的场景

❌ **需要重复使用**
- Latch 是一次性的，使用 namedWaitGroup

❌ **需要增加计数**
- Latch 只能减少计数，使用 namedWaitGroup

❌ **单进程同步**
- 使用普通的 `Latch`

## 注意事项

### 命名规范

⚠️ **使用有意义的名称**
```pascal
// ✅ 好：清晰的命名
MakeNamedLatch('MyApp.Services.StartupGate', 5)
MakeNamedLatch('BatchJob.CompletionLatch', 100)

// ❌ 差：模糊的命名
MakeNamedLatch('latch1', 5)
MakeNamedLatch('gate', 100)
```

### 一次性使用

⚠️ **Latch 不可重置**
```pascal
var LLatch := MakeNamedLatch('OnceOnly', 3);
LLatch.CountDown;
LLatch.CountDown;
LLatch.CountDown;
// 计数已为 0，无法重置

// 需要重新创建
LLatch := MakeNamedLatch('OnceOnly2', 3);
```

### 资源清理

⚠️ **命名对象需要显式清理**
```pascal
// 创建者进程负责清理
var LLatch := MakeNamedLatch('MyLatch', 5);
try
  // 使用 Latch
finally
  // 接口引用计数会自动清理
  LLatch := nil;
end;
```

### 计数管理

⚠️ **避免过度 CountDown**
```pascal
var LLatch := MakeNamedLatch('Tasks', 2);
LLatch.CountDown;
LLatch.CountDown;
LLatch.CountDown;  // 计数已为 0，无效但不报错
```

## 最佳实践

### 1. 使用配置对象

```pascal
var
  LConfig: TNamedLatchConfig;
begin
  LConfig := DefaultNamedLatchConfig;
  LConfig.TimeoutMs := 10000;  // 10 秒超时
  
  LLatch := MakeNamedLatchWithConfig('MyLatch', 5, LConfig);
end;
```

### 2. 超时处理

```pascal
if not LLatch.Wait(5000) then
begin
  WriteLn('等待超时，剩余任务: ', LLatch.GetCount);
  // 执行超时恢复逻辑
end;
```

### 3. 进度监控

```pascal
while not LLatch.IsOpen do
begin
  WriteLn(Format('进度: %d/%d', [InitialCount - LLatch.GetCount, InitialCount]));
  Sleep(1000);
end;
```

### 4. 批量操作

```pascal
// 批量完成多个任务
const BATCH_SIZE = 10;
ProcessBatch(BATCH_SIZE);
LLatch.CountDownBy(BATCH_SIZE);
```

## 相关模块

- `fafafa.core.sync.latch` - 单进程 Latch
- `fafafa.core.sync.namedWaitGroup` - 跨进程 WaitGroup（可重用）
- `fafafa.core.sync.namedBarrier` - 跨进程屏障
- `fafafa.core.sync.base` - 同步原语基础接口

## 参考资料

- Java `java.util.concurrent.CountDownLatch` 文档
- POSIX Named Semaphores 文档
- Windows Named Kernel Objects 文档

## 版本历史

- **v1.0** - 初始版本，支持跨进程倒计数门闩
- 支持超时等待
- 支持批量倒计数
- 支持全局命名空间
- 支持非阻塞检查
