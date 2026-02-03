# fafafa.core.sync.namedCondvar

跨进程命名条件变量（实验性 API）。

## ⚠️ 实验性 API 警告

`INamedCondVar` 是跨进程条件变量实现，当前状态：
- **Unix/Linux**: 基于 POSIX shm + pthread_cond，功能完善，可用于生产环境
- **Windows**: Broadcast 语义在极端竞争场景下有理论风险，建议仅用于开发/测试

**替代方案**: 跨进程同步推荐使用 `INamedMutex` + `INamedEvent` 组合。

## 概述

`fafafa.core.sync.namedCondvar` 模块提供了跨进程的命名条件变量实现。条件变量允许线程/进程在某个条件成立之前等待，并在条件改变时被唤醒。

## 安装

```pascal
uses
  fafafa.core.sync.namedCondvar;
```

## API 参考

### INamedCondVar 接口

```pascal
type
  INamedCondVar = interface
    // 等待条件（必须在持有关联 mutex 时调用）
    procedure Wait(AMutex: INamedMutex);

    // 带超时等待
    function WaitFor(AMutex: INamedMutex; ATimeoutMs: Cardinal): Boolean;

    // 唤醒一个等待者
    procedure Signal;

    // 唤醒所有等待者
    procedure Broadcast;

    // 获取名称
    function GetName: string;

    // 获取统计信息
    function GetStats: TNamedCondVarStats;

    property Name: string read GetName;
  end;
```

### TNamedCondVarConfig 配置

```pascal
type
  TNamedCondVarConfig = record
    UseGlobalNamespace: Boolean;   // 使用全局命名空间（Windows）
    DefaultTimeoutMs: Cardinal;     // 默认超时
    EnableStats: Boolean;           // 启用统计
  end;
```

### 工厂函数

```pascal
// 创建命名条件变量
function MakeNamedCondVar(const AName: string): INamedCondVar;
function MakeNamedCondVar(const AName: string; const AConfig: TNamedCondVarConfig): INamedCondVar;

// 便利工厂函数
function MakeGlobalNamedCondVar(const AName: string): INamedCondVar;
function MakeNamedCondVarWithTimeout(const AName: string; ATimeoutMs: Cardinal): INamedCondVar;
function MakeNamedCondVarWithStats(const AName: string): INamedCondVar;

// 尝试打开已存在的
function TryOpenNamedCondVar(const AName: string): INamedCondVar;
```

## 使用示例

### 基本生产者-消费者模式

**共享模块**:
```pascal
const
  QUEUE_NAME = 'SharedQueue';
  QUEUE_MUTEX = 'QueueMutex';
  QUEUE_CONDVAR = 'QueueCondVar';
```

**生产者进程**:
```pascal
var
  Mutex: INamedMutex;
  CondVar: INamedCondVar;
  Queue: INamedSharedQueue;  // 假设存在
begin
  Mutex := CreateNamedMutex(QUEUE_MUTEX);
  CondVar := MakeNamedCondVar(QUEUE_CONDVAR);
  Queue := OpenNamedSharedQueue(QUEUE_NAME);

  while True do
  begin
    Mutex.Acquire;
    try
      Queue.Push(ProduceItem());
      CondVar.Signal;  // 通知一个消费者
    finally
      Mutex.Release;
    end;
  end;
end;
```

**消费者进程**:
```pascal
var
  Mutex: INamedMutex;
  CondVar: INamedCondVar;
  Queue: INamedSharedQueue;
  Item: TItem;
begin
  Mutex := CreateNamedMutex(QUEUE_MUTEX);
  CondVar := MakeNamedCondVar(QUEUE_CONDVAR);
  Queue := OpenNamedSharedQueue(QUEUE_NAME);

  while True do
  begin
    Mutex.Acquire;
    try
      while Queue.IsEmpty do
        CondVar.Wait(Mutex);  // 等待数据

      Item := Queue.Pop;
    finally
      Mutex.Release;
    end;

    ConsumeItem(Item);
  end;
end;
```

### 带超时的等待

```pascal
var
  Mutex: INamedMutex;
  CondVar: INamedCondVar;
  GotSignal: Boolean;
begin
  Mutex := CreateNamedMutex('MyMutex');
  CondVar := MakeNamedCondVar('MyCondVar');

  Mutex.Acquire;
  try
    GotSignal := CondVar.WaitFor(Mutex, 5000);  // 5秒超时

    if GotSignal then
      WriteLn('收到信号')
    else
      WriteLn('等待超时');
  finally
    Mutex.Release;
  end;
end;
```

### 广播唤醒

```pascal
// 控制进程：通知所有工作进程开始
CondVar.Broadcast;

// 工作进程：等待开始信号
Mutex.Acquire;
try
  CondVar.Wait(Mutex);
  // 所有工作进程同时被唤醒
finally
  Mutex.Release;
end;
```

## 正确使用条件变量

### 必须使用循环检查条件

```pascal
// ✅ 正确：使用 while 循环
Mutex.Acquire;
try
  while not ConditionMet do
    CondVar.Wait(Mutex);
  // 条件成立，处理...
finally
  Mutex.Release;
end;

// ❌ 错误：使用 if（可能有虚假唤醒）
Mutex.Acquire;
try
  if not ConditionMet then
    CondVar.Wait(Mutex);
  // 危险！条件可能仍未成立
finally
  Mutex.Release;
end;
```

### 必须在持有 mutex 时调用 Wait

```pascal
// ✅ 正确
Mutex.Acquire;
try
  CondVar.Wait(Mutex);
finally
  Mutex.Release;
end;

// ❌ 错误：未持有 mutex
CondVar.Wait(Mutex);  // 未定义行为！
```

## 平台实现细节

### Unix/Linux

- 使用 POSIX 共享内存 (`shm_open`)
- 使用 `pthread_cond_t` 和 `PTHREAD_PROCESS_SHARED` 属性
- 使用 `CLOCK_MONOTONIC` 进行超时（不受时钟调整影响）

### Windows

- 使用命名 Event 对象模拟
- `Broadcast` 使用多次 `SetEvent` + `ResetEvent`
- 在高竞争场景下可能有竞态条件风险

## 统计信息

```pascal
var
  Stats: TNamedCondVarStats;
begin
  Stats := CondVar.GetStats;
  WriteLn('等待次数: ', Stats.WaitCount);
  WriteLn('Signal 次数: ', Stats.SignalCount);
  WriteLn('Broadcast 次数: ', Stats.BroadcastCount);
  WriteLn('超时次数: ', Stats.TimeoutCount);
end;
```

## 注意事项

1. **虚假唤醒**: Wait 可能在没有 Signal/Broadcast 的情况下返回
2. **条件检查**: 始终在循环中检查条件
3. **Mutex 要求**: Wait 必须在持有 mutex 时调用
4. **Windows 限制**: 高竞争场景下 Broadcast 可能不可靠

## 相关模块

- `fafafa.core.sync.condvar` - 进程内条件变量
- `fafafa.core.sync.namedMutex` - 命名互斥锁
- `fafafa.core.sync.namedEvent` - 命名事件

## 版本历史

- v1.0.0 (2025-12): 初始实验性版本
