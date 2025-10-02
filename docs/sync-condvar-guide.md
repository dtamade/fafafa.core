# CondVar (条件变量) 使用指南

## 概述

`ICondVar` 是 fafafa.core.sync 库中的条件变量接口，用于线程间的高级同步。条件变量允许线程等待某个条件成立，并在条件满足时被其他线程唤醒。

## 接口重命名说明

从 v2.0 开始，原 `IConditionVariable` 接口已重命名为 `ICondVar`，以保持命名的简洁性和一致性：
- `IConditionVariable` → `ICondVar`
- `MakeConditionVariable` → `MakeCondVar`
- `INamedConditionVariable` → `INamedCondVar`

## 基础用法

### 创建条件变量

```pascal
uses
  fafafa.core.sync;

var
  CondVar: ICondVar;
  Mutex: IMutex;
begin
  CondVar := MakeCondVar;
  Mutex := MakeMutex;
end;
```

### 等待条件

```pascal
// 基本等待模式
Mutex.Acquire;
try
  while not SomeCondition do
    CondVar.Wait(Mutex);  // 自动释放锁并等待，被唤醒后重新获取锁
  // 条件已满足，执行相关操作
finally
  Mutex.Release;
end;
```

### 带超时的等待

```pascal
Mutex.Acquire;
try
  if not CondVar.Wait(Mutex, 5000) then  // 等待最多5秒
  begin
    // 超时处理
    WriteLn('Wait timed out');
  end;
finally
  Mutex.Release;
end;
```

### 发送信号

```pascal
// 唤醒一个等待的线程
Mutex.Acquire;
try
  // 修改条件
  SomeCondition := True;
  CondVar.Signal;  // 唤醒一个等待的线程
finally
  Mutex.Release;
end;

// 唤醒所有等待的线程
Mutex.Acquire;
try
  // 修改条件
  AllConditionsMet := True;
  CondVar.Broadcast;  // 唤醒所有等待的线程
finally
  Mutex.Release;
end;
```

## 典型应用场景

### 1. 生产者-消费者模式

```pascal
type
  TProducerConsumer = class
  private
    FQueue: TQueue<Integer>;
    FMutex: IMutex;
    FNotEmpty: ICondVar;
    FNotFull: ICondVar;
    FMaxSize: Integer;
  public
    constructor Create(AMaxSize: Integer);
    procedure Produce(AItem: Integer);
    function Consume: Integer;
  end;

constructor TProducerConsumer.Create(AMaxSize: Integer);
begin
  FQueue := TQueue<Integer>.Create;
  FMutex := MakeMutex;
  FNotEmpty := MakeCondVar;
  FNotFull := MakeCondVar;
  FMaxSize := AMaxSize;
end;

procedure TProducerConsumer.Produce(AItem: Integer);
begin
  FMutex.Acquire;
  try
    // 等待队列有空间
    while FQueue.Count >= FMaxSize do
      FNotFull.Wait(FMutex);
    
    // 添加项目
    FQueue.Enqueue(AItem);
    
    // 通知消费者
    FNotEmpty.Signal;
  finally
    FMutex.Release;
  end;
end;

function TProducerConsumer.Consume: Integer;
begin
  FMutex.Acquire;
  try
    // 等待队列非空
    while FQueue.Count = 0 do
      FNotEmpty.Wait(FMutex);
    
    // 获取项目
    Result := FQueue.Dequeue;
    
    // 通知生产者
    FNotFull.Signal;
  finally
    FMutex.Release;
  end;
end;
```

### 2. 工作池模式

```pascal
type
  TWorkPool = class
  private
    FWorkers: array of TThread;
    FTasks: TQueue<TProc>;
    FMutex: IMutex;
    FWorkAvailable: ICondVar;
    FShutdown: Boolean;
  public
    constructor Create(AWorkerCount: Integer);
    procedure AddTask(ATask: TProc);
    procedure Shutdown;
  end;

type
  TWorker = class(TThread)
  private
    FPool: TWorkPool;
  protected
    procedure Execute; override;
  public
    constructor Create(APool: TWorkPool);
  end;

procedure TWorker.Execute;
var
  Task: TProc;
begin
  while not Terminated do
  begin
    FPool.FMutex.Acquire;
    try
      // 等待工作或关闭信号
      while (FPool.FTasks.Count = 0) and not FPool.FShutdown do
        FPool.FWorkAvailable.Wait(FPool.FMutex);
      
      if FPool.FShutdown then
        Break;
      
      if FPool.FTasks.Count > 0 then
        Task := FPool.FTasks.Dequeue;
    finally
      FPool.FMutex.Release;
    end;
    
    // 执行任务
    if Assigned(Task) then
      Task();
  end;
end;

procedure TWorkPool.AddTask(ATask: TProc);
begin
  FMutex.Acquire;
  try
    FTasks.Enqueue(ATask);
    FWorkAvailable.Signal;  // 唤醒一个工作线程
  finally
    FMutex.Release;
  end;
end;

procedure TWorkPool.Shutdown;
begin
  FMutex.Acquire;
  try
    FShutdown := True;
    FWorkAvailable.Broadcast;  // 唤醒所有工作线程
  finally
    FMutex.Release;
  end;
  
  // 等待所有工作线程结束
  for var Worker in FWorkers do
    Worker.WaitFor;
end;
```

### 3. 事件通知机制

```pascal
type
  TEventNotifier = class
  private
    FEventOccurred: Boolean;
    FMutex: IMutex;
    FCondVar: ICondVar;
  public
    constructor Create;
    procedure WaitForEvent(ATimeoutMs: Cardinal = INFINITE);
    procedure NotifyEvent;
    procedure Reset;
  end;

procedure TEventNotifier.WaitForEvent(ATimeoutMs: Cardinal);
begin
  FMutex.Acquire;
  try
    if ATimeoutMs = INFINITE then
    begin
      while not FEventOccurred do
        FCondVar.Wait(FMutex);
    end
    else
    begin
      if not FEventOccurred then
        FCondVar.Wait(FMutex, ATimeoutMs);
    end;
  finally
    FMutex.Release;
  end;
end;

procedure TEventNotifier.NotifyEvent;
begin
  FMutex.Acquire;
  try
    FEventOccurred := True;
    FCondVar.Broadcast;  // 通知所有等待者
  finally
    FMutex.Release;
  end;
end;
```

## 命名条件变量

命名条件变量用于跨进程同步：

```pascal
var
  NamedCondVar: INamedCondVar;
  NamedMutex: INamedMutex;
begin
  // 创建或打开命名条件变量
  NamedCondVar := MakeNamedCondVar('Global\MyAppCondVar');
  NamedMutex := MakeNamedMutex('Global\MyAppMutex');
  
  // 使用方式与普通条件变量相同
  NamedMutex.Acquire;
  try
    while not SharedCondition do
      NamedCondVar.Wait(NamedMutex);
  finally
    NamedMutex.Release;
  end;
end;
```

## 最佳实践

### 1. 始终在锁保护下访问共享状态

```pascal
// 正确
Mutex.Acquire;
try
  SharedData := NewValue;
  CondVar.Signal;
finally
  Mutex.Release;
end;

// 错误 - 未保护的访问
SharedData := NewValue;  // 危险！
CondVar.Signal;
```

### 2. 使用 while 循环而非 if 检查条件

```pascal
// 正确 - 防止虚假唤醒
while not Condition do
  CondVar.Wait(Mutex);

// 错误 - 可能因虚假唤醒而继续
if not Condition then
  CondVar.Wait(Mutex);
```

### 3. 避免忘记发送信号

```pascal
// 使用 RAII 模式确保信号发送
type
  TConditionSetter = class
  private
    FMutex: IMutex;
    FCondVar: ICondVar;
    FCondition: PBoolean;
  public
    constructor Create(AMutex: IMutex; ACondVar: ICondVar; ACondition: PBoolean);
    destructor Destroy; override;
  end;

destructor TConditionSetter.Destroy;
begin
  FMutex.Acquire;
  try
    FCondition^ := True;
    FCondVar.Signal;
  finally
    FMutex.Release;
  end;
  inherited;
end;
```

### 4. 合理选择 Signal vs Broadcast

- 使用 `Signal` 当只需要唤醒一个等待线程时（如队列中有新项目）
- 使用 `Broadcast` 当条件改变影响所有等待线程时（如关闭信号）

### 5. 处理超时

```pascal
function WaitWithRetry(CondVar: ICondVar; Mutex: IMutex; 
                       MaxRetries: Integer; TimeoutMs: Cardinal): Boolean;
var
  Retries: Integer;
begin
  Result := False;
  Retries := 0;
  
  while (Retries < MaxRetries) and not Result do
  begin
    if CondVar.Wait(Mutex, TimeoutMs) then
    begin
      Result := True;
      Break;
    end;
    Inc(Retries);
    WriteLn(Format('Retry %d/%d', [Retries, MaxRetries]));
  end;
end;
```

## 性能考虑

1. **避免过度使用 Broadcast**：如果只需要唤醒一个线程，使用 Signal 更高效
2. **批量处理**：在可能的情况下，批量处理多个项目后再发送信号
3. **超时设置**：合理设置超时时间，避免无限等待
4. **锁的粒度**：保持临界区尽可能小，快速释放锁

## 常见问题

### Q: 为什么需要在 while 循环中检查条件？
A: 防止虚假唤醒（spurious wakeup）。操作系统可能在没有信号的情况下唤醒等待线程。

### Q: Signal 和 Broadcast 的区别？
A: Signal 唤醒一个等待线程，Broadcast 唤醒所有等待线程。

### Q: 条件变量与事件（Event）的区别？
A: 条件变量总是与互斥锁配合使用，提供原子的"释放锁并等待"操作。事件是独立的同步原语。

### Q: 如何避免死锁？
A: 确保获取多个锁时使用相同的顺序，使用超时机制，考虑使用 try-finally 确保锁释放。

## 平台差异

- **Windows**: 使用 Windows Vista+ 的 ConditionVariable API 或兼容实现
- **Unix/Linux**: 使用 pthread_cond_t
- **跨平台**: 接口统一，行为一致

## 相关接口

- `IMutex`: 互斥锁，与条件变量配合使用
- `IEvent`: 事件同步原语，适合简单的信号场景
- `ISem`: 信号量，用于资源计数
- `IBarrier`: 屏障，用于多线程同步点
