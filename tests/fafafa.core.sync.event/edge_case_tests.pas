program edge_case_tests;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.event, fafafa.core.sync.base;

type
  { 边界条件和稳定性测试 }
  TEdgeCaseTests = class
  private
    FPassedTests: Integer;
    FTotalTests: Integer;
    
    procedure RunTest(const TestName: string; TestProc: TProcedure);
    procedure TestZeroTimeout;
    procedure TestMaxTimeout;
    procedure TestRapidCreateDestroy;
    procedure TestExtremelyLongWait;
    procedure TestMassiveInterrupts;
    procedure TestConcurrentSetReset;
    procedure TestGuardEdgeCases;
    procedure TestErrorStateConsistency;
    procedure TestResourceExhaustion;
    procedure TestThreadSafety;
    
  public
    constructor Create;
    procedure RunAllTests;
    procedure PrintSummary;
  end;

{ 快速创建销毁线程 }
type
  TRapidCreateThread = class(TThread)
  private
    FIterations: Integer;
    FCreatedCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AIterations: Integer);
    property CreatedCount: Integer read FCreatedCount;
  end;

{ 并发设置重置线程 }
type
  TConcurrentSetResetThread = class(TThread)
  private
    FEvent: IEvent;
    FIterations: Integer;
    FOperationType: Integer; // 0=Set, 1=Reset, 2=Mixed
    FOperationCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AEvent: IEvent; AIterations: Integer; AOperationType: Integer);
    property OperationCount: Integer read FOperationCount;
  end;

{ TEdgeCaseTests }

constructor TEdgeCaseTests.Create;
begin
  inherited Create;
  FPassedTests := 0;
  FTotalTests := 0;
end;

procedure TEdgeCaseTests.RunTest(const TestName: string; TestProc: TProcedure);
begin
  Inc(FTotalTests);
  Write(Format('%-40s ... ', [TestName]));
  try
    TestProc();
    Inc(FPassedTests);
    WriteLn('PASS');
  except
    on E: Exception do
    begin
      WriteLn('FAIL: ' + E.Message);
    end;
  end;
end;

procedure TEdgeCaseTests.TestZeroTimeout;
var
  Event: IEvent;
  Result: TWaitResult;
begin
  // 测试零超时行为
  Event := CreateEvent(False, False);
  
  // 未信号状态下的零超时应该立即返回超时
  Result := Event.WaitFor(0);
  if Result <> wrTimeout then
    raise Exception.Create('Zero timeout should return wrTimeout');
    
  // 信号状态下的零超时应该立即返回成功
  Event.SetEvent;
  Result := Event.WaitFor(0);
  if Result <> wrSignaled then
    raise Exception.Create('Zero timeout on signaled event should return wrSignaled');
end;

procedure TEdgeCaseTests.TestMaxTimeout;
var
  Event: IEvent;
  StartTime: QWord;
  Result: TWaitResult;
begin
  // 测试最大超时值（但不真的等那么久）
  Event := CreateEvent(False, False);
  
  StartTime := GetTickCount64;
  
  // 在另一个线程中快速设置事件
  TThread.CreateAnonymousThread(
    procedure
    begin
      Sleep(100);
      Event.SetEvent;
    end).Start;
    
  Result := Event.WaitFor(High(Cardinal));
  
  if Result <> wrSignaled then
    raise Exception.Create('Max timeout test failed');
    
  if GetTickCount64 - StartTime > 1000 then
    raise Exception.Create('Max timeout test took too long');
end;

procedure TEdgeCaseTests.TestRapidCreateDestroy;
var
  Threads: array[0..3] of TRapidCreateThread;
  i: Integer;
  TotalCreated: Integer;
begin
  // 测试快速创建销毁事件对象
  for i := 0 to 3 do
  begin
    Threads[i] := TRapidCreateThread.Create(1000);
    Threads[i].Start;
  end;
  
  TotalCreated := 0;
  for i := 0 to 3 do
  begin
    Threads[i].WaitFor;
    Inc(TotalCreated, Threads[i].CreatedCount);
    Threads[i].Free;
  end;
  
  if TotalCreated <> 4000 then
    raise Exception.CreateFmt('Expected 4000 events, got %d', [TotalCreated]);
end;

procedure TEdgeCaseTests.TestExtremelyLongWait;
var
  Event: IEvent;
  StartTime: QWord;
  Result: TWaitResult;
begin
  // 测试相对较长的等待（但仍然合理）
  Event := CreateEvent(False, False);
  
  StartTime := GetTickCount64;
  
  // 在另一个线程中延迟设置事件
  TThread.CreateAnonymousThread(
    procedure
    begin
      Sleep(500);
      Event.SetEvent;
    end).Start;
    
  Result := Event.WaitFor(2000);
  
  if Result <> wrSignaled then
    raise Exception.Create('Long wait test failed');
    
  if GetTickCount64 - StartTime > 1000 then
    raise Exception.Create('Long wait took longer than expected');
end;

procedure TEdgeCaseTests.TestMassiveInterrupts;
var
  Events: array[0..99] of IEvent;
  i: Integer;
begin
  // 创建大量事件并全部中断
  for i := 0 to 99 do
    Events[i] := CreateEvent(i mod 2 = 0, False);
    
  // 中断所有事件
  for i := 0 to 99 do
    Events[i].Interrupt;
    
  // 验证中断状态
  for i := 0 to 99 do
  begin
    if not Events[i].IsInterrupted then
      raise Exception.CreateFmt('Event %d should be interrupted', [i]);
  end;
  
  // 清理
  for i := 0 to 99 do
    Events[i] := nil;
end;

procedure TEdgeCaseTests.TestConcurrentSetReset;
var
  Event: IEvent;
  Threads: array[0..5] of TConcurrentSetResetThread;
  i: Integer;
  TotalOps: Integer;
begin
  Event := CreateEvent(True, False); // 手动重置事件
  
  // 创建不同类型的操作线程
  for i := 0 to 5 do
  begin
    Threads[i] := TConcurrentSetResetThread.Create(Event, 500, i mod 3);
    Threads[i].Start;
  end;
  
  TotalOps := 0;
  for i := 0 to 5 do
  begin
    Threads[i].WaitFor;
    Inc(TotalOps, Threads[i].OperationCount);
    Threads[i].Free;
  end;
  
  if TotalOps <> 3000 then
    raise Exception.CreateFmt('Expected 3000 operations, got %d', [TotalOps]);
end;

procedure TEdgeCaseTests.TestGuardEdgeCases;
var
  Event: IEvent;
  Guard1, Guard2: IEventGuard;
begin
  Event := CreateEvent(True, True); // 手动重置，初始信号状态
  
  // 测试多个守卫
  Guard1 := Event.TryWaitGuard;
  Guard2 := Event.TryWaitGuard;
  
  if not Guard1.IsValid then
    raise Exception.Create('First guard should be valid');
  if not Guard2.IsValid then
    raise Exception.Create('Second guard should be valid (manual reset)');
    
  // 测试守卫释放
  Guard1.Release;
  if Guard1.IsValid then
    raise Exception.Create('Released guard should not be valid');
    
  // 清理
  Guard1 := nil;
  Guard2 := nil;
end;

procedure TEdgeCaseTests.TestErrorStateConsistency;
var
  Event: IEvent;
  ErrorBefore, ErrorAfter: TWaitError;
begin
  Event := CreateEvent(False, False);
  
  // 测试错误状态的一致性
  Event.ClearLastError;
  ErrorBefore := Event.GetLastError;
  
  Event.TryWait; // 应该超时但不是错误
  ErrorAfter := Event.GetLastError;
  
  if ErrorBefore <> weNone then
    raise Exception.Create('Initial error should be weNone');
  if ErrorAfter <> weNone then
    raise Exception.Create('TryWait timeout should not set error');
    
  // 测试不支持的操作
  Event.GetWaitingThreadCount;
  {$IFDEF WINDOWS}
  if Event.GetLastError <> weNotSupported then
    raise Exception.Create('GetWaitingThreadCount should set weNotSupported on Windows');
  {$ELSE}
  if Event.GetLastError <> weNone then
    raise Exception.Create('GetWaitingThreadCount should not set error on Unix');
  {$ENDIF}
end;

procedure TEdgeCaseTests.TestResourceExhaustion;
var
  Events: array of IEvent;
  i: Integer;
  MaxEvents: Integer;
begin
  // 尝试创建大量事件直到资源耗尽（但有限制）
  MaxEvents := 1000; // 合理的限制
  SetLength(Events, MaxEvents);
  
  try
    for i := 0 to MaxEvents - 1 do
    begin
      Events[i] := CreateEvent(i mod 2 = 0, False);
      // 执行基本操作确保事件可用
      Events[i].SetEvent;
      Events[i].ResetEvent;
    end;
    
    // 如果能创建这么多，说明资源管理良好
  finally
    // 清理所有事件
    for i := 0 to MaxEvents - 1 do
      Events[i] := nil;
  end;
end;

procedure TEdgeCaseTests.TestThreadSafety;
var
  Event: IEvent;
  Threads: array[0..7] of TThread;
  i: Integer;
  SharedCounter: Integer;
begin
  Event := CreateEvent(False, False); // 自动重置事件
  SharedCounter := 0;
  
  // 创建多个线程竞争同一个事件
  for i := 0 to 7 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      var
        j: Integer;
      begin
        for j := 1 to 100 do
        begin
          if Event.WaitFor(10) = wrSignaled then
            InterlockedIncrement(SharedCounter);
        end;
      end);
    Threads[i].Start;
  end;
  
  // 发送信号
  for i := 1 to 200 do
  begin
    Event.SetEvent;
    if i mod 10 = 0 then
      Sleep(1);
  end;
  
  // 等待所有线程完成
  for i := 0 to 7 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
  
  // 验证线程安全性（不要求精确计数，因为有超时）
  if SharedCounter > 200 then
    raise Exception.CreateFmt('Thread safety violation: counter=%d', [SharedCounter]);
end;

procedure TEdgeCaseTests.RunAllTests;
begin
  WriteLn('=== fafafa.core.sync.event 边界条件测试 ===');
  WriteLn;
  
  RunTest('零超时测试', @TestZeroTimeout);
  RunTest('最大超时测试', @TestMaxTimeout);
  RunTest('快速创建销毁测试', @TestRapidCreateDestroy);
  RunTest('长时间等待测试', @TestExtremelyLongWait);
  RunTest('大量中断测试', @TestMassiveInterrupts);
  RunTest('并发设置重置测试', @TestConcurrentSetReset);
  RunTest('守卫边界条件测试', @TestGuardEdgeCases);
  RunTest('错误状态一致性测试', @TestErrorStateConsistency);
  RunTest('资源耗尽测试', @TestResourceExhaustion);
  RunTest('线程安全测试', @TestThreadSafety);
end;

procedure TEdgeCaseTests.PrintSummary;
begin
  WriteLn;
  WriteLn(Format('测试完成: %d/%d 通过', [FPassedTests, FTotalTests]));
  if FPassedTests = FTotalTests then
    WriteLn('所有边界条件测试通过！')
  else
    WriteLn(Format('有 %d 个测试失败', [FTotalTests - FPassedTests]));
end;

{ TRapidCreateThread }

constructor TRapidCreateThread.Create(AIterations: Integer);
begin
  inherited Create(False);
  FIterations := AIterations;
  FCreatedCount := 0;
end;

procedure TRapidCreateThread.Execute;
var
  i: Integer;
  Event: IEvent;
begin
  for i := 1 to FIterations do
  begin
    Event := CreateEvent(i mod 2 = 0, False);
    Event.SetEvent;
    Event.ResetEvent;
    Event := nil;
    Inc(FCreatedCount);
  end;
end;

{ TConcurrentSetResetThread }

constructor TConcurrentSetResetThread.Create(AEvent: IEvent; AIterations: Integer; AOperationType: Integer);
begin
  inherited Create(False);
  FEvent := AEvent;
  FIterations := AIterations;
  FOperationType := AOperationType;
  FOperationCount := 0;
end;

procedure TConcurrentSetResetThread.Execute;
var
  i: Integer;
begin
  for i := 1 to FIterations do
  begin
    case FOperationType of
      0: FEvent.SetEvent;
      1: FEvent.ResetEvent;
      2: begin
           if i mod 2 = 0 then
             FEvent.SetEvent
           else
             FEvent.ResetEvent;
         end;
    end;
    Inc(FOperationCount);
  end;
end;

{ 主程序 }
var
  Tests: TEdgeCaseTests;
begin
  try
    Tests := TEdgeCaseTests.Create;
    try
      Tests.RunAllTests;
      Tests.PrintSummary;
    finally
      Tests.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn('严重错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
