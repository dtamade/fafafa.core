# fafafa.core.sync.namedWaitGroup

## 概述

namedWaitGroup 是一个跨进程的等待组同步原语，允许多个进程协调等待一组并发操作完成。它是 `WaitGroup` 的命名版本，支持跨进程同步。

## 核心概念

### 跨进程计数器

namedWaitGroup 通过命名的共享内存或内核对象实现跨进程同步：
- 多个进程可以通过相同的名称访问同一个 WaitGroup 实例
- 任何进程都可以调用 `Add` 增加计数
- 任何进程都可以调用 `Done` 减少计数
- 所有进程都可以调用 `Wait` 等待计数归零

### 与非命名 WaitGroup 的区别

| 特性 | WaitGroup | namedWaitGroup |
|------|-----------|----------------|
| 作用域 | 单进程 | 跨进程 |
| 命名 | 无 | 必须指定名称 |
| 资源 | 内存 | 共享内存/内核对象 |
| 清理 | 自动 | 需要显式清理 |

## API 参考

### 类型定义

```pascal
type
  TNamedWaitGroupConfig = record
    TimeoutMs: Cardinal;           // 等待超时时间（毫秒）
    UseGlobalNamespace: Boolean;   // 是否使用全局命名空间
  end;

  INamedWaitGroup = interface(ISynchronizable)
    procedure Add(ACount: Cardinal = 1);
    procedure Done;
    function Wait(ATimeoutMs: Cardinal = High(Cardinal)): Boolean;
    function GetCount: Cardinal;
    function IsZero: Boolean;
    function GetName: string;
  end;
```

### 创建 namedWaitGroup

```pascal
function MakeNamedWaitGroup(const AName: string): INamedWaitGroup;
function MakeNamedWaitGroupWithConfig(const AName: string; const AConfig: TNamedWaitGroupConfig): INamedWaitGroup;
```

创建或打开一个命名的 WaitGroup 实例。

**参数**：
- `AName` - WaitGroup 的名称（跨进程唯一标识）
- `AConfig` - 配置选项（可选）

**返回值**：
- `INamedWaitGroup` - WaitGroup 接口实例

### Add

```pascal
procedure Add(ACount: Cardinal = 1);
```

增加计数。

**参数**：
- `ACount` - 要增加的计数值，默认为 1

**行为**：
- 原子地将计数增加 `ACount`

### Done

```pascal
procedure Done;
```

减少计数 1，等同于 `Add(-1)`。

**行为**：
- 原子地将计数减 1
- 当计数降为 0 时，唤醒所有等待的进程

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

### GetCount

```pascal
function GetCount: Cardinal;
```

获取当前计数值。

**返回值**：
- 当前计数值

**注意**：
- 这是一个瞬时值，主要用于调试和监控

### IsZero

```pascal
function IsZero: Boolean;
```

检查计数是否为零。

**返回值**：
- `True` - 计数为 0
- `False` - 计数不为 0

## 使用示例

### 基本用法

```pascal
uses
  fafafa.core.sync.namedWaitGroup;

// 主进程
var
  LWG: INamedWaitGroup;
begin
  LWG := MakeNamedWaitGroup('MyApp.Tasks');
  LWG.Add(3);  // 3 个工作进程
  
  // 启动工作进程...
  
  // 等待所有完成
  LWG.Wait;
  WriteLn('所有任务完成');
end;

// 工作进程
var
  LWG: INamedWaitGroup;
begin
  LWG := MakeNamedWaitGroup('MyApp.Tasks');
  
  // 执行工作
  DoWork;
  
  // 完成
  LWG.Done;
end;
```

### 跨进程任务协调

```pascal
// 主进程：分配任务
var
  LWG: INamedWaitGroup;
  LTaskCount: Integer;
begin
  LWG := MakeNamedWaitGroup('BatchJob.Tasks');
  LTaskCount := 10;
  
  // 设置任务数量
  LWG.Add(LTaskCount);
  
  // 启动工作进程
  for var i := 1 to LTaskCount do
    StartWorkerProcess(i);
  
  // 等待所有任务完成
  WriteLn('等待任务完成...');
  LWG.Wait;
  WriteLn('批处理完成');
end;

// 工作进程
var
  LWG: INamedWaitGroup;
begin
  LWG := MakeNamedWaitGroup('BatchJob.Tasks');
  
  try
    // 处理任务
    ProcessTask;
  finally
    // 确保总是调用 Done
    LWG.Done;
  end;
end;
```

### 动态添加任务

```pascal
// 主进程
var
  LWG: INamedWaitGroup;
begin
  LWG := MakeNamedWaitGroup('DynamicTasks');
  
  // 动态添加任务
  for var i := 1 to 5 do
  begin
    LWG.Add(1);
    StartWorkerProcess(i);
  end;
  
  // 等待完成
  LWG.Wait;
end;

// 工作进程
var
  LWG: INamedWaitGroup;
begin
  LWG := MakeNamedWaitGroup('DynamicTasks');
  
  // 工作...
  
  LWG.Done;
end;
```

### 带超时的等待

```pascal
var
  LWG: INamedWaitGroup;
begin
  LWG := MakeNamedWaitGroup('SlowTasks');
  LWG.Add(5);
  
  // 启动任务...
  
  // 等待最多 30 秒
  if LWG.Wait(30000) then
    WriteLn('所有任务完成')
  else
  begin
    WriteLn('等待超时，剩余: ', LWG.GetCount);
    // 执行超时处理
  end;
end;
```

### 进度监控

```pascal
var
  LWG: INamedWaitGroup;
  LTotalTasks: Integer;
begin
  LTotalTasks := 100;
  LWG := MakeNamedWaitGroup('ProgressTasks');
  LWG.Add(LTotalTasks);
  
  // 启动任务...
  
  // 监控进度
  while not LWG.IsZero do
  begin
    var LRemaining := LWG.GetCount;
    var LCompleted := LTotalTasks - LRemaining;
    WriteLn(Format('进度: %d/%d (%.1f%%)', 
      [LCompleted, LTotalTasks, (LCompleted / LTotalTasks) * 100]));
    Sleep(1000);
  end;
  
  WriteLn('所有任务完成');
end;
```

### 可重用模式

```pascal
var
  LWG: INamedWaitGroup;
begin
  LWG := MakeNamedWaitGroup('ReusableTasks');
  
  // 第一轮
  LWG.Add(5);
  // 启动任务...
  LWG.Wait;
  WriteLn('第一轮完成');
  
  // 第二轮（重用）
  LWG.Add(3);
  // 启动任务...
  LWG.Wait;
  WriteLn('第二轮完成');
end;
```

## 平台实现

### Windows

- 使用命名 Semaphore + Event 实现
- 支持全局命名空间（`Global\` 前缀）
- 支持会话命名空间（`Local\` 前缀）

### Unix/Linux/macOS

- 使用 POSIX 命名信号量 + 共享内存实现
- 命名格式：`/fafafa.wg.<name>`
- 支持跨进程同步

## 使用场景

### 适合的场景

✅ **跨进程任务协调**
```pascal
// 主进程等待所有工作进程完成
LWG.Wait;
```

✅ **批量处理**
```pascal
// 分布式批处理任务
LWG.Add(BatchSize);
```

✅ **服务启动协调**
```pascal
// 等待所有服务启动完成
LWG.Wait;
```

✅ **可重用场景**
```pascal
// 多轮任务处理
for Round := 1 to N do
begin
  LWG.Add(TaskCount);
  // 处理...
  LWG.Wait;
end;
```

### 不适合的场景

❌ **单进程同步**
- 使用普通的 `WaitGroup`

❌ **一次性门控**
- 使用 `namedLatch`

❌ **需要返回值**
- WaitGroup 不支持返回值

## 注意事项

### 命名规范

⚠️ **使用有意义的名称**
```pascal
// ✅ 好：清晰的命名
MakeNamedWaitGroup('MyApp.BatchJob.Tasks')
MakeNamedWaitGroup('Services.StartupSync')

// ❌ 差：模糊的命名
MakeNamedWaitGroup('wg1')
MakeNamedWaitGroup('tasks')
```

### 计数管理

⚠️ **确保 Add 和 Done 配对**
```pascal
// ✅ 好：配对使用
LWG.Add(1);
try
  DoWork;
finally
  LWG.Done;
end;

// ❌ 差：可能遗漏 Done
LWG.Add(1);
DoWork;
LWG.Done;  // 如果 DoWork 抛异常，Done 不会被调用
```

### 资源清理

⚠️ **命名对象需要显式清理**
```pascal
// 创建者进程负责清理
var LWG := MakeNamedWaitGroup('MyWG');
try
  // 使用 WaitGroup
finally
  // 接口引用计数会自动清理
  LWG := nil;
end;
```

### 跨进程竞争

⚠️ **避免死锁**
```pascal
// ❌ 错误：在 Wait 期间 Add
TThread.CreateAnonymousThread(procedure
begin
  LWG.Wait;
  LWG.Add(1);  // 危险！可能死锁
end).Start;
```

## 最佳实践

### 1. 使用配置对象

```pascal
var
  LConfig: TNamedWaitGroupConfig;
begin
  LConfig := DefaultNamedWaitGroupConfig;
  LConfig.TimeoutMs := 10000;  // 10 秒超时
  
  LWG := MakeNamedWaitGroupWithConfig('MyWG', LConfig);
end;
```

### 2. 异常安全

```pascal
LWG.Add(1);
try
  DoWork;
finally
  LWG.Done;  // 确保总是调用
end;
```

### 3. 超时处理

```pascal
if not LWG.Wait(5000) then
begin
  WriteLn('等待超时，剩余任务: ', LWG.GetCount);
  // 执行超时恢复逻辑
end;
```

### 4. 进度监控

```pascal
while not LWG.IsZero do
begin
  WriteLn('剩余任务: ', LWG.GetCount);
  Sleep(1000);
end;
```

## 相关模块

- `fafafa.core.sync.waitgroup` - 单进程 WaitGroup
- `fafafa.core.sync.namedLatch` - 跨进程 Latch（一次性）
- `fafafa.core.sync.namedBarrier` - 跨进程屏障
- `fafafa.core.sync.base` - 同步原语基础接口

## 参考资料

- Go `sync.WaitGroup` 文档
- POSIX Named Semaphores 文档
- Windows Named Kernel Objects 文档

## 版本历史

- **v1.0** - 初始版本，支持跨进程等待组
- 支持超时等待
- 支持动态添加任务
- 支持全局命名空间
- 支持可重用设计
