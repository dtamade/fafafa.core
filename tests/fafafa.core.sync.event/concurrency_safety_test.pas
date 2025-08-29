program concurrency_safety_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.event, fafafa.core.sync.base;

type
  { 并发安全测试套件 }
  TConcurrencySafetyTest = class
  private
    FTestResults: array[0..9] of Boolean;
    FTestCount: Integer;
    
    procedure RunTest(TestIndex: Integer; const TestName: string; TestProc: TProcedure);
    procedure TestAtomicOperations;
    procedure TestRaceConditions;
    procedure TestDeadlockPrevention;
    procedure TestMemoryOrdering;
    procedure TestInterruptSafety;
    procedure TestGuardThreadSafety;
    procedure TestMassiveConcurrency;
    procedure TestSignalConsistency;
    procedure TestErrorStateSafety;
    procedure TestResourceContention;
    
  public
    constructor Create;
    procedure RunAllTests;
    procedure PrintResults;
  end;

{ 原子操作测试线程 }
type
  TAtomicTestThread = class(TThread)
  private
    FEvent: IEvent;
    FIterations: Integer;
    FSuccessCount: Integer;
    FErrorCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AEvent: IEvent; AIterations: Integer);
    property SuccessCount: Integer read FSuccessCount;
    property ErrorCount: Integer read FErrorCount;
  end;

{ 竞态条件测试线程 }
type
  TRaceConditionThread = class(TThread)
  private
    FEvent: IEvent;
    FSharedCounter: PInteger;
    FOperationType: Integer; // 0=Reader, 1=Writer
    FIterations: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AEvent: IEvent; ASharedCounter: PInteger; AOperationType, AIterations: Integer);
  end;

{ 大规模并发测试线程 }
type
  TMassiveConcurrencyThread = class(TThread)
  private
    FEvents: array[0..9] of IEvent;
    FThreadId: Integer;
    FOperationCount: Integer;
    FInconsistencyCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const AEvents: array of IEvent; AThreadId: Integer);
    property OperationCount: Integer read FOperationCount;
    property InconsistencyCount: Integer read FInconsistencyCount;
  end;

{ TConcurrencySafetyTest }

constructor TConcurrencySafetyTest.Create;
begin
  inherited Create;
  FTestCount := 0;
  FillChar(FTestResults, SizeOf(FTestResults), 0);
end;

procedure TConcurrencySafetyTest.RunTest(TestIndex: Integer; const TestName: string; TestProc: TProcedure);
begin
  Write(Format('%-35s ... ', [TestName]));
  try
    TestProc();
    FTestResults[TestIndex] := True;
    WriteLn('PASS');
  except
    on E: Exception do
    begin
      FTestResults[TestIndex] := False;
      WriteLn('FAIL: ' + E.Message);
    end;
  end;
  Inc(FTestCount);
end;

procedure TConcurrencySafetyTest.TestAtomicOperations;
var
  Event: IEvent;
  Threads: array[0..7] of TAtomicTestThread;
  i: Integer;
  TotalSuccess, TotalErrors: Integer;
begin
  Event := CreateEvent(True, False);
  
  // 创建多个线程同时操作事件
  for i := 0 to 7 do
  begin
    Threads[i] := TAtomicTestThread.Create(Event, 1000);
    Threads[i].Start;
  end;
  
  // 在主线程中也进行操作
  for i := 1 to 1000 do
  begin
    Event.SetEvent;
    Event.ResetEvent;
    Event.Interrupt;
  end;
  
  // 等待所有线程完成
  TotalSuccess := 0;
  TotalErrors := 0;
  for i := 0 to 7 do
  begin
    Threads[i].WaitFor;
    Inc(TotalSuccess, Threads[i].SuccessCount);
    Inc(TotalErrors, Threads[i].ErrorCount);
    Threads[i].Free;
  end;
  
  if TotalErrors > 0 then
    raise Exception.CreateFmt('Atomic operations failed: %d errors', [TotalErrors]);
end;

procedure TConcurrencySafetyTest.TestRaceConditions;
var
  Event: IEvent;
  SharedCounter: Integer;
  Readers, Writers: array[0..3] of TRaceConditionThread;
  i: Integer;
begin
  Event := CreateEvent(True, True); // 手动重置，初始信号状态
  SharedCounter := 0;
  
  // 创建读者和写者线程
  for i := 0 to 3 do
  begin
    Readers[i] := TRaceConditionThread.Create(Event, @SharedCounter, 0, 500);
    Writers[i] := TRaceConditionThread.Create(Event, @SharedCounter, 1, 500);
    Readers[i].Start;
    Writers[i].Start;
  end;
  
  // 等待所有线程完成
  for i := 0 to 3 do
  begin
    Readers[i].WaitFor;
    Writers[i].WaitFor;
    Readers[i].Free;
    Writers[i].Free;
  end;
  
  // 验证没有发生数据竞争（这里只是基本检查）
  if SharedCounter < 0 then
    raise Exception.Create('Race condition detected: negative counter');
end;

procedure TConcurrencySafetyTest.TestDeadlockPrevention;
var
  Events: array[0..3] of IEvent;
  Threads: array[0..7] of TThread;
  i: Integer;
  DeadlockDetected: Boolean;
begin
  // 创建多个事件
  for i := 0 to 3 do
    Events[i] := CreateEvent(False, False);
  
  DeadlockDetected := False;
  
  // 创建可能导致死锁的线程模式
  for i := 0 to 7 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      var
        j: Integer;
        StartTime: QWord;
      begin
        StartTime := GetTickCount64;
        for j := 1 to 100 do
        begin
          // 尝试获取多个事件，但有超时防止死锁
          if Events[j mod 4].WaitFor(50) = wrSignaled then
          begin
            Events[(j + 1) mod 4].SetEvent;
            Sleep(1);
          end;
          
          // 检查是否运行时间过长（可能的死锁指示）
          if GetTickCount64 - StartTime > 10000 then
          begin
            DeadlockDetected := True;
            Break;
          end;
        end;
      end);
    Threads[i].Start;
  end;
  
  // 等待所有线程完成
  for i := 0 to 7 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
  
  if DeadlockDetected then
    raise Exception.Create('Potential deadlock detected');
    
  // 清理
  for i := 0 to 3 do
    Events[i] := nil;
end;

procedure TConcurrencySafetyTest.TestMemoryOrdering;
var
  Event: IEvent;
  Threads: array[0..3] of TThread;
  SharedData: array[0..99] of Integer;
  i: Integer;
  InconsistencyFound: Boolean;
begin
  Event := CreateEvent(True, False);
  FillChar(SharedData, SizeOf(SharedData), 0);
  InconsistencyFound := False;
  
  // 创建写者线程
  Threads[0] := TThread.CreateAnonymousThread(
    procedure
    var
      j: Integer;
    begin
      for j := 1 to 1000 do
      begin
        // 写入数据
        SharedData[j mod 100] := j;
        // 设置事件信号
        Event.SetEvent;
        Sleep(1);
        Event.ResetEvent;
      end;
    end);
  
  // 创建读者线程
  for i := 1 to 3 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      var
        j, Value, PrevValue: Integer;
      begin
        PrevValue := 0;
        for j := 1 to 500 do
        begin
          if Event.WaitFor(10) = wrSignaled then
          begin
            Value := SharedData[j mod 100];
            // 检查内存顺序一致性
            if Value < PrevValue then
              InconsistencyFound := True;
            PrevValue := Value;
          end;
        end;
      end);
  end;
  
  // 启动所有线程
  for i := 0 to 3 do
    Threads[i].Start;
    
  // 等待完成
  for i := 0 to 3 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
  
  if InconsistencyFound then
    raise Exception.Create('Memory ordering inconsistency detected');
end;

procedure TConcurrencySafetyTest.TestInterruptSafety;
var
  Event: IEvent;
  Threads: array[0..7] of TThread;
  i: Integer;
  InterruptCount: Integer;
begin
  Event := CreateEvent(False, False);
  InterruptCount := 0;
  
  // 创建等待线程
  for i := 0 to 7 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      begin
        if Event.WaitForInterruptible(5000) = wrAbandoned then
          InterlockedIncrement(InterruptCount);
      end);
    Threads[i].Start;
  end;
  
  // 等待线程启动
  Sleep(100);
  
  // 中断事件
  Event.Interrupt;
  
  // 等待所有线程完成
  for i := 0 to 7 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
  
  // 验证中断被正确处理
  if InterruptCount = 0 then
    raise Exception.Create('Interrupt was not processed by any thread');
end;

procedure TConcurrencySafetyTest.TestGuardThreadSafety;
var
  Event: IEvent;
  Threads: array[0..7] of TThread;
  i: Integer;
  ValidGuards: Integer;
begin
  Event := CreateEvent(True, True); // 手动重置，初始信号状态
  ValidGuards := 0;
  
  // 创建多个线程同时获取守卫
  for i := 0 to 7 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      var
        Guard: IEventGuard;
        j: Integer;
      begin
        for j := 1 to 100 do
        begin
          Guard := Event.TryWaitGuard;
          if Guard.IsValid then
            InterlockedIncrement(ValidGuards);
          Guard := nil;
        end;
      end);
    Threads[i].Start;
  end;
  
  // 等待所有线程完成
  for i := 0 to 7 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
  
  // 对于手动重置事件，所有守卫都应该有效
  if ValidGuards <> 800 then
    raise Exception.CreateFmt('Guard thread safety issue: expected 800, got %d', [ValidGuards]);
end;

procedure TConcurrencySafetyTest.TestMassiveConcurrency;
var
  Events: array[0..9] of IEvent;
  Threads: array[0..19] of TMassiveConcurrencyThread;
  i: Integer;
  TotalOps, TotalInconsistencies: Integer;
begin
  // 创建共享事件
  for i := 0 to 9 do
    Events[i] := CreateEvent(i mod 2 = 0, False);
  
  // 创建大量并发线程
  for i := 0 to 19 do
  begin
    Threads[i] := TMassiveConcurrencyThread.Create(Events, i);
    Threads[i].Start;
  end;
  
  // 等待所有线程完成
  TotalOps := 0;
  TotalInconsistencies := 0;
  for i := 0 to 19 do
  begin
    Threads[i].WaitFor;
    Inc(TotalOps, Threads[i].OperationCount);
    Inc(TotalInconsistencies, Threads[i].InconsistencyCount);
    Threads[i].Free;
  end;
  
  if TotalInconsistencies > 0 then
    raise Exception.CreateFmt('Concurrency inconsistencies: %d out of %d operations', 
      [TotalInconsistencies, TotalOps]);
      
  // 清理
  for i := 0 to 9 do
    Events[i] := nil;
end;

procedure TConcurrencySafetyTest.TestSignalConsistency;
var
  Event: IEvent;
  SignalCount, ReceiveCount: Integer;
  i: Integer;
begin
  Event := CreateEvent(False, False); // 自动重置事件
  SignalCount := 0;
  ReceiveCount := 0;
  
  // 信号发送线程
  TThread.CreateAnonymousThread(
    procedure
    var
      j: Integer;
    begin
      for j := 1 to 1000 do
      begin
        Event.SetEvent;
        InterlockedIncrement(SignalCount);
        Sleep(1);
      end;
    end).Start;
  
  // 信号接收线程
  for i := 0 to 3 do
  begin
    TThread.CreateAnonymousThread(
      procedure
      begin
        while ReceiveCount < 1000 do
        begin
          if Event.WaitFor(100) = wrSignaled then
            InterlockedIncrement(ReceiveCount);
        end;
      end).Start;
  end;
  
  // 等待完成
  while (SignalCount < 1000) or (ReceiveCount < 1000) do
    Sleep(10);
  
  // 对于自动重置事件，接收数不应超过发送数
  if ReceiveCount > SignalCount then
    raise Exception.CreateFmt('Signal inconsistency: sent %d, received %d', 
      [SignalCount, ReceiveCount]);
end;

procedure TConcurrencySafetyTest.TestErrorStateSafety;
var
  Event: IEvent;
  Threads: array[0..7] of TThread;
  i: Integer;
  ErrorStateCorruption: Boolean;
begin
  Event := CreateEvent(False, False);
  ErrorStateCorruption := False;
  
  // 创建多个线程同时操作和检查错误状态
  for i := 0 to 7 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      var
        j: Integer;
        LastError: TWaitError;
      begin
        for j := 1 to 500 do
        begin
          Event.ClearLastError;
          Event.TryWait;
          LastError := Event.GetLastError;
          
          // 错误状态应该是一致的
          if LastError <> weNone then
            ErrorStateCorruption := True;
            
          Event.GetWaitingThreadCount; // 可能设置错误状态
          Sleep(1);
        end;
      end);
    Threads[i].Start;
  end;
  
  // 等待所有线程完成
  for i := 0 to 7 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
  
  if ErrorStateCorruption then
    raise Exception.Create('Error state corruption detected');
end;

procedure TConcurrencySafetyTest.TestResourceContention;
var
  Events: array[0..4] of IEvent;
  Threads: array[0..19] of TThread;
  i: Integer;
  ContentionErrors: Integer;
begin
  // 创建有限的事件资源
  for i := 0 to 4 do
    Events[i] := CreateEvent(True, False);
  
  ContentionErrors := 0;
  
  // 创建大量线程竞争有限资源
  for i := 0 to 19 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      var
        j, EventIndex: Integer;
      begin
        for j := 1 to 100 do
        begin
          EventIndex := j mod 5;
          try
            Events[EventIndex].SetEvent;
            Events[EventIndex].WaitFor(10);
            Events[EventIndex].ResetEvent;
          except
            InterlockedIncrement(ContentionErrors);
          end;
        end;
      end);
    Threads[i].Start;
  end;
  
  // 等待所有线程完成
  for i := 0 to 19 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
  
  if ContentionErrors > 0 then
    raise Exception.CreateFmt('Resource contention errors: %d', [ContentionErrors]);
    
  // 清理
  for i := 0 to 4 do
    Events[i] := nil;
end;

procedure TConcurrencySafetyTest.RunAllTests;
begin
  WriteLn('=== fafafa.core.sync.event 并发安全测试 ===');
  WriteLn;
  
  RunTest(0, '原子操作安全测试', @TestAtomicOperations);
  RunTest(1, '竞态条件测试', @TestRaceConditions);
  RunTest(2, '死锁预防测试', @TestDeadlockPrevention);
  RunTest(3, '内存顺序测试', @TestMemoryOrdering);
  RunTest(4, '中断安全测试', @TestInterruptSafety);
  RunTest(5, '守卫线程安全测试', @TestGuardThreadSafety);
  RunTest(6, '大规模并发测试', @TestMassiveConcurrency);
  RunTest(7, '信号一致性测试', @TestSignalConsistency);
  RunTest(8, '错误状态安全测试', @TestErrorStateSafety);
  RunTest(9, '资源竞争测试', @TestResourceContention);
end;

procedure TConcurrencySafetyTest.PrintResults;
var
  i, PassedCount: Integer;
begin
  WriteLn;
  PassedCount := 0;
  for i := 0 to FTestCount - 1 do
    if FTestResults[i] then
      Inc(PassedCount);
      
  WriteLn(Format('并发安全测试完成: %d/%d 通过', [PassedCount, FTestCount]));
  if PassedCount = FTestCount then
    WriteLn('所有并发安全测试通过！')
  else
    WriteLn(Format('有 %d 个测试失败', [FTestCount - PassedCount]));
end;

{ TAtomicTestThread }

constructor TAtomicTestThread.Create(AEvent: IEvent; AIterations: Integer);
begin
  inherited Create(False);
  FEvent := AEvent;
  FIterations := AIterations;
  FSuccessCount := 0;
  FErrorCount := 0;
end;

procedure TAtomicTestThread.Execute;
var
  i: Integer;
begin
  for i := 1 to FIterations do
  begin
    try
      FEvent.SetEvent;
      FEvent.IsSignaled;
      FEvent.TryWait;
      FEvent.ResetEvent;
      Inc(FSuccessCount);
    except
      Inc(FErrorCount);
    end;
  end;
end;

{ TRaceConditionThread }

constructor TRaceConditionThread.Create(AEvent: IEvent; ASharedCounter: PInteger; AOperationType, AIterations: Integer);
begin
  inherited Create(False);
  FEvent := AEvent;
  FSharedCounter := ASharedCounter;
  FOperationType := AOperationType;
  FIterations := AIterations;
end;

procedure TRaceConditionThread.Execute;
var
  i: Integer;
begin
  for i := 1 to FIterations do
  begin
    if FEvent.WaitFor(10) = wrSignaled then
    begin
      if FOperationType = 0 then
      begin
        // 读者：只读取
        if FSharedCounter^ < 0 then
          Break; // 检测到异常
      end
      else
      begin
        // 写者：递增计数器
        InterlockedIncrement(FSharedCounter^);
      end;
    end;
  end;
end;

{ TMassiveConcurrencyThread }

constructor TMassiveConcurrencyThread.Create(const AEvents: array of IEvent; AThreadId: Integer);
var
  i: Integer;
begin
  inherited Create(False);
  FThreadId := AThreadId;
  FOperationCount := 0;
  FInconsistencyCount := 0;
  
  for i := 0 to 9 do
    FEvents[i] := AEvents[i];
end;

procedure TMassiveConcurrencyThread.Execute;
var
  i, j: Integer;
  PrevState, CurrentState: Boolean;
begin
  for i := 1 to 200 do
  begin
    for j := 0 to 9 do
    begin
      PrevState := FEvents[j].IsSignaled;
      FEvents[j].SetEvent;
      CurrentState := FEvents[j].IsSignaled;
      
      // 检查状态一致性
      if not CurrentState and PrevState then
        Inc(FInconsistencyCount);
        
      FEvents[j].ResetEvent;
      Inc(FOperationCount, 3);
    end;
  end;
end;

{ 主程序 }
var
  SafetyTest: TConcurrencySafetyTest;
begin
  try
    SafetyTest := TConcurrencySafetyTest.Create;
    try
      SafetyTest.RunAllTests;
      SafetyTest.PrintResults;
    finally
      SafetyTest.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn('严重错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
