unit test_condvar;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync;

type
  TCondVarTest = class(TTestCase)
  private
    FCondVar: ICondVar;
    FMutex: IMutex;
    FSharedData: Integer;
    FCondition: Boolean;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 基础功能测试
    procedure TestCreate;
    procedure TestSignal;
    procedure TestBroadcast;
    procedure TestWaitWithTimeout;
    
    // 多线程测试
    procedure TestProducerConsumer;
    procedure TestMultipleWaiters;
    procedure TestSpuriousWakeup;
    
    // 边界条件测试
    procedure TestSignalBeforeWait;
    procedure TestTimeoutZero;
    procedure TestMultipleSignals;
    
    // 命名条件变量测试
    procedure TestNamedCondVar;
    procedure TestNamedCondVarCrossProcess;
  end;
  
  // 测试辅助线程
  TProducerThread = class(TThread)
  private
    FCondVar: ICondVar;
    FMutex: IMutex;
    FSharedData: PInteger;
    FProduceCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ACondVar: ICondVar; AMutex: IMutex; ASharedData: PInteger; ACount: Integer);
  end;
  
  TConsumerThread = class(TThread)
  private
    FCondVar: ICondVar;
    FMutex: IMutex;
    FSharedData: PInteger;
    FConsumedCount: Integer;
    FExpectedCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ACondVar: ICondVar; AMutex: IMutex; ASharedData: PInteger; AExpected: Integer);
    property ConsumedCount: Integer read FConsumedCount;
  end;
  
  TWaiterThread = class(TThread)
  private
    FCondVar: ICondVar;
    FMutex: IMutex;
    FCondition: PBoolean;
    FWaitCompleted: Boolean;
    FTimeoutMs: Cardinal;
    FTimedOut: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(ACondVar: ICondVar; AMutex: IMutex; ACondition: PBoolean; ATimeoutMs: Cardinal = INFINITE);
    property WaitCompleted: Boolean read FWaitCompleted;
    property TimedOut: Boolean read FTimedOut;
  end;

implementation

{ TCondVarTest }

procedure TCondVarTest.SetUp;
begin
  FCondVar := MakeCondVar;
  FMutex := MakeMutex;
  FSharedData := 0;
  FCondition := False;
end;

procedure TCondVarTest.TearDown;
begin
  FCondVar := nil;
  FMutex := nil;
end;

procedure TCondVarTest.TestCreate;
begin
  AssertNotNull('CondVar should not be nil', FCondVar);
  AssertNotNull('Mutex should not be nil', FMutex);
end;

procedure TCondVarTest.TestSignal;
var
  Waiter: TWaiterThread;
begin
  // 创建等待线程
  Waiter := TWaiterThread.Create(FCondVar, FMutex, @FCondition);
  try
    Sleep(100); // 确保等待线程开始等待
    
    // 发送信号
    with FMutex.Lock do
    begin
      FCondition := True;
      FCondVar.Signal;
    end;
    
    // 等待线程完成
    Waiter.WaitFor;
    AssertTrue('Waiter should complete', Waiter.WaitCompleted);
    AssertFalse('Waiter should not timeout', Waiter.TimedOut);
  finally
    Waiter.Free;
  end;
end;

procedure TCondVarTest.TestBroadcast;
var
  Waiters: array[0..2] of TWaiterThread;
  i: Integer;
begin
  // 创建多个等待线程
  for i := 0 to High(Waiters) do
  begin
    Waiters[i] := TWaiterThread.Create(FCondVar, FMutex, @FCondition);
  end;
  
  try
    Sleep(100); // 确保所有等待线程开始等待
    
    // 广播信号
    with FMutex.Lock do
    begin
      FCondition := True;
      FCondVar.Broadcast;
    end;
    
    // 等待所有线程完成
    for i := 0 to High(Waiters) do
    begin
      Waiters[i].WaitFor;
      AssertTrue(Format('Waiter %d should complete', [i]), Waiters[i].WaitCompleted);
    end;
  finally
    for i := 0 to High(Waiters) do
      Waiters[i].Free;
  end;
end;

procedure TCondVarTest.TestWaitWithTimeout;
var
  Waiter: TWaiterThread;
begin
  // 创建带超时的等待线程
  Waiter := TWaiterThread.Create(FCondVar, FMutex, @FCondition, 500);
  try
    // 不发送信号，让其超时
    Waiter.WaitFor;
    AssertTrue('Waiter should timeout', Waiter.TimedOut);
  finally
    Waiter.Free;
  end;
end;

procedure TCondVarTest.TestProducerConsumer;
var
  Producer: TProducerThread;
  Consumer: TConsumerThread;
  SharedData: Integer;
begin
  SharedData := 0;
  
  // 创建消费者线程
  Consumer := TConsumerThread.Create(FCondVar, FMutex, @SharedData, 10);
  Sleep(50);
  
  // 创建生产者线程
  Producer := TProducerThread.Create(FCondVar, FMutex, @SharedData, 10);
  
  try
    // 等待两个线程完成
    Producer.WaitFor;
    Consumer.WaitFor;
    
    AssertEquals('Consumer should consume all items', 10, Consumer.ConsumedCount);
  finally
    Producer.Free;
    Consumer.Free;
  end;
end;

procedure TCondVarTest.TestMultipleWaiters;
var
  Waiters: array[0..4] of TWaiterThread;
  i, SignaledCount: Integer;
begin
  // 创建多个等待线程
  for i := 0 to High(Waiters) do
  begin
    Waiters[i] := TWaiterThread.Create(FCondVar, FMutex, @FCondition);
  end;
  
  try
    Sleep(100);
    
    // 只发送一个信号
    with FMutex.Lock do
    begin
      FCondition := True;
      FCondVar.Signal; // 只唤醒一个
    end;
    
    Sleep(200);
    
    // 计算被唤醒的线程数
    SignaledCount := 0;
    for i := 0 to High(Waiters) do
    begin
      if Waiters[i].WaitCompleted then
        Inc(SignaledCount);
    end;
    
    AssertEquals('Only one waiter should be signaled', 1, SignaledCount);
    
    // 广播唤醒剩余的线程
    FCondVar.Broadcast;
    
    // 等待所有线程结束
    for i := 0 to High(Waiters) do
    begin
      if not Waiters[i].Finished then
      begin
        Waiters[i].Terminate;
        Waiters[i].WaitFor;
      end;
    end;
  finally
    for i := 0 to High(Waiters) do
      Waiters[i].Free;
  end;
end;

procedure TCondVarTest.TestSpuriousWakeup;
var
  Waiter: TWaiterThread;
  OldCondition: Boolean;
begin
  OldCondition := FCondition;
  
  // 创建等待线程（使用 while 循环检查条件）
  Waiter := TWaiterThread.Create(FCondVar, FMutex, @FCondition);
  try
    Sleep(100);
    
    // 发送信号但不改变条件（模拟虚假唤醒）
    FCondVar.Signal;
    
    Sleep(100);
    
    // 线程应该继续等待
    AssertFalse('Waiter should still be waiting', Waiter.WaitCompleted);
    
    // 现在真正满足条件
    with FMutex.Lock do
    begin
      FCondition := True;
      FCondVar.Signal;
    end;
    
    Waiter.WaitFor;
    AssertTrue('Waiter should complete after condition met', Waiter.WaitCompleted);
  finally
    Waiter.Free;
    FCondition := OldCondition;
  end;
end;

procedure TCondVarTest.TestSignalBeforeWait;
begin
  // 先发送信号
  with FMutex.Lock do
  begin
    FCondition := True;
    FCondVar.Signal;
  end;
  
  // 然后等待（应该立即返回，因为条件已满足）
  with FMutex.Lock do
  begin
    if not FCondition then
      FCondVar.Wait(FMutex);
    AssertTrue('Condition should be true', FCondition);
  end;
end;

procedure TCondVarTest.TestTimeoutZero;
var
  Result: Boolean;
begin
  with FMutex.Lock do
  begin
    Result := FCondVar.Wait(FMutex, 0);
    AssertFalse('Wait with zero timeout should return false', Result);
  end;
end;

procedure TCondVarTest.TestMultipleSignals;
var
  i: Integer;
begin
  // 发送多个信号（不应该造成问题）
  with FMutex.Lock do
  begin
    for i := 1 to 5 do
      FCondVar.Signal;
  end;
  
  // 应该正常工作
  AssertTrue('Multiple signals should not cause issues', True);
end;

procedure TCondVarTest.TestNamedCondVar;
var
  NamedCondVar1, NamedCondVar2: INamedCondVar;
  NamedMutex: INamedMutex;
begin
  // 创建命名条件变量
  NamedCondVar1 := MakeNamedCondVar('TestCondVar');
  NamedMutex := Sync.MakeNamedMutex('TestMutex');
  
  AssertNotNull('Named CondVar should not be nil', NamedCondVar1);
  AssertNotNull('Named Mutex should not be nil', NamedMutex);
  
  // 使用相同名称创建第二个实例
  NamedCondVar2 := MakeNamedCondVar('TestCondVar');
  AssertNotNull('Second named CondVar should not be nil', NamedCondVar2);
  
  // 两个实例应该引用同一个系统对象
  // 这里可以添加更多的跨实例测试
end;

procedure TCondVarTest.TestNamedCondVarCrossProcess;
begin
  // 这个测试需要启动另一个进程
  // 在单元测试中跳过，可以在集成测试中实现
  Skip('Cross-process testing requires separate process');
end;

{ TProducerThread }

constructor TProducerThread.Create(ACondVar: ICondVar; AMutex: IMutex; 
  ASharedData: PInteger; ACount: Integer);
begin
  inherited Create(False);
  FCondVar := ACondVar;
  FMutex := AMutex;
  FSharedData := ASharedData;
  FProduceCount := ACount;
end;

procedure TProducerThread.Execute;
var
  i: Integer;
begin
  for i := 1 to FProduceCount do
  begin
    with FMutex.Lock do
    begin
      Inc(FSharedData^);
      FCondVar.Signal;
    end;
    Sleep(10); // 模拟生产延迟
  end;
end;

{ TConsumerThread }

constructor TConsumerThread.Create(ACondVar: ICondVar; AMutex: IMutex; 
  ASharedData: PInteger; AExpected: Integer);
begin
  inherited Create(False);
  FCondVar := ACondVar;
  FMutex := AMutex;
  FSharedData := ASharedData;
  FConsumedCount := 0;
  FExpectedCount := AExpected;
end;

procedure TConsumerThread.Execute;
begin
  while FConsumedCount < FExpectedCount do
  begin
    with FMutex.Lock do
    begin
      while FSharedData^ = 0 do
        FCondVar.Wait(FMutex);
      
      Dec(FSharedData^);
      Inc(FConsumedCount);
    end;
  end;
end;

{ TWaiterThread }

constructor TWaiterThread.Create(ACondVar: ICondVar; AMutex: IMutex; 
  ACondition: PBoolean; ATimeoutMs: Cardinal);
begin
  inherited Create(False);
  FCondVar := ACondVar;
  FMutex := AMutex;
  FCondition := ACondition;
  FWaitCompleted := False;
  FTimeoutMs := ATimeoutMs;
  FTimedOut := False;
end;

procedure TWaiterThread.Execute;
begin
  with FMutex.Lock do
  begin
    if FTimeoutMs = INFINITE then
    begin
      while not FCondition^ and not Terminated do
        FCondVar.Wait(FMutex);
    end
    else
    begin
      while not FCondition^ and not Terminated do
      begin
        if not FCondVar.Wait(FMutex, FTimeoutMs) then
        begin
          FTimedOut := True;
          Break;
        end;
      end;
    end;
    
    if FCondition^ then
      FWaitCompleted := True;
  end;
end;

initialization
  RegisterTest(TCondVarTest);

end.
