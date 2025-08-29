unit fafafa.core.sync.event.enhanced.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.event, fafafa.core.sync.base;

type
  // 增强的错误处理和边界情况测试
  TTestCase_Event_Enhanced = class(TTestCase)
  private
    FEvent: IEvent;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 错误处理测试
    procedure Test_ErrorHandling_DetailedMessages;
    procedure Test_ErrorHandling_ClearError;
    procedure Test_ErrorHandling_ErrorPersistence;
    
    // 边界情况测试
    procedure Test_BoundaryConditions_ZeroTimeout;
    procedure Test_BoundaryConditions_MaxTimeout;
    procedure Test_BoundaryConditions_RapidSetReset;
    procedure Test_BoundaryConditions_MultipleWaiters;
    
    // 竞态条件测试
    procedure Test_RaceConditions_SetResetConcurrent;
    procedure Test_RaceConditions_IsSignaledConsistency;
    procedure Test_RaceConditions_AtomicStateConsistency;
    
    // 内存屏障测试
    procedure Test_MemoryBarrier_StateVisibility;
    procedure Test_MemoryBarrier_OrderingGuarantees;
    
    // 新的 IsSignaled 语义测试
    procedure Test_IsSignaled_AutoResetNonDestructive;
    procedure Test_IsSignaled_ManualResetConsistency;
    procedure Test_IsSignaled_ConcurrentAccess;
  end;

  // 并发测试辅助线程
  TTestThread = class(TThread)
  private
    FEvent: IEvent;
    FOperation: string;
    FResult: Boolean;
    FException: Exception;
  protected
    procedure Execute; override;
  public
    constructor Create(const AEvent: IEvent; const AOperation: string);
    destructor Destroy; override;
    property TestResult: Boolean read FResult;
    property TestException: Exception read FException;
  end;

implementation

{ TTestCase_Event_Enhanced }

procedure TTestCase_Event_Enhanced.SetUp;
begin
  inherited SetUp;
  FEvent := CreateEvent(False, False); // 默认自动重置事件
end;

procedure TTestCase_Event_Enhanced.TearDown;
begin
  FEvent := nil;
  inherited TearDown;
end;

procedure TTestCase_Event_Enhanced.Test_ErrorHandling_DetailedMessages;
var
  ManualEvent: IEvent;
  ErrorMsg: string;
begin
  // 测试详细的错误消息
  ManualEvent := CreateEvent(True, False);
  
  // 清除任何现有错误
  ManualEvent.ClearLastError;
  AssertEquals('Initial error should be weNone', Ord(weNone), Ord(ManualEvent.GetLastError));
  
  // 测试错误消息格式
  ErrorMsg := ManualEvent.GetLastErrorMessage;
  AssertTrue('Error message should not be empty', Length(ErrorMsg) > 0);
  AssertTrue('Error message should indicate no error', Pos('No error', ErrorMsg) > 0);
end;

procedure TTestCase_Event_Enhanced.Test_ErrorHandling_ClearError;
begin
  // 设置一个错误状态（通过触发超时）
  FEvent.WaitFor(1); // 很短的超时，应该超时
  
  // 验证错误状态
  AssertTrue('Should have timeout error', FEvent.GetLastError <> weNone);
  
  // 清除错误
  FEvent.ClearLastError;
  AssertEquals('Error should be cleared', Ord(weNone), Ord(FEvent.GetLastError));
end;

procedure TTestCase_Event_Enhanced.Test_ErrorHandling_ErrorPersistence;
var
  InitialError: TWaitError;
begin
  // 触发一个错误
  FEvent.WaitFor(1); // 超时
  InitialError := FEvent.GetLastError;
  
  // 执行成功的操作
  FEvent.SetEvent;
  AssertTrue('SetEvent should succeed', FEvent.TryWait);
  
  // 验证错误状态在成功操作后被清除
  AssertEquals('Error should be cleared after successful operation', 
               Ord(weNone), Ord(FEvent.GetLastError));
end;

procedure TTestCase_Event_Enhanced.Test_BoundaryConditions_ZeroTimeout;
var
  Result: TWaitResult;
begin
  // 测试零超时的行为
  Result := FEvent.WaitFor(0);
  AssertEquals('Zero timeout should return wrTimeout', Ord(wrTimeout), Ord(Result));
  
  // 设置事件后再测试
  FEvent.SetEvent;
  Result := FEvent.WaitFor(0);
  AssertEquals('Zero timeout with signaled event should return wrSignaled', 
               Ord(wrSignaled), Ord(Result));
end;

procedure TTestCase_Event_Enhanced.Test_BoundaryConditions_MaxTimeout;
var
  StartTime, EndTime: QWord;
  Result: TWaitResult;
begin
  // 测试最大超时值（应该表现为无限等待）
  FEvent.SetEvent; // 立即设置信号
  
  StartTime := GetTickCount64;
  Result := FEvent.WaitFor(High(Cardinal));
  EndTime := GetTickCount64;
  
  AssertEquals('Max timeout should return wrSignaled', Ord(wrSignaled), Ord(Result));
  AssertTrue('Max timeout should return quickly when signaled', (EndTime - StartTime) < 100);
end;

procedure TTestCase_Event_Enhanced.Test_BoundaryConditions_RapidSetReset;
var
  i: Integer;
  ManualEvent: IEvent;
begin
  ManualEvent := CreateEvent(True, False); // 手动重置事件
  
  // 快速设置和重置循环
  for i := 1 to 1000 do
  begin
    ManualEvent.SetEvent;
    AssertTrue(Format('Event should be signaled at iteration %d', [i]), 
               ManualEvent.IsSignaled);
    ManualEvent.ResetEvent;
    AssertFalse(Format('Event should not be signaled after reset at iteration %d', [i]), 
                ManualEvent.IsSignaled);
  end;
end;

procedure TTestCase_Event_Enhanced.Test_BoundaryConditions_MultipleWaiters;
var
  Threads: array[0..9] of TTestThread;
  i: Integer;
  SuccessCount: Integer;
begin
  // 创建多个等待线程
  for i := 0 to High(Threads) do
  begin
    Threads[i] := TTestThread.Create(FEvent, 'wait');
    Threads[i].Start;
  end;
  
  // 等待一小段时间确保所有线程都在等待
  Sleep(50);
  
  // 设置事件（自动重置，只应该唤醒一个线程）
  FEvent.SetEvent;
  
  // 等待所有线程完成
  SuccessCount := 0;
  for i := 0 to High(Threads) do
  begin
    Threads[i].WaitFor;
    if Threads[i].TestResult then
      Inc(SuccessCount);
    Threads[i].Free;
  end;
  
  // 自动重置事件应该只唤醒一个线程
  AssertEquals('Auto-reset event should wake exactly one thread', 1, SuccessCount);
end;

procedure TTestCase_Event_Enhanced.Test_RaceConditions_SetResetConcurrent;
var
  SetThread, ResetThread: TTestThread;
  ManualEvent: IEvent;
begin
  ManualEvent := CreateEvent(True, False); // 手动重置事件
  
  // 创建并发设置和重置线程
  SetThread := TTestThread.Create(ManualEvent, 'set_loop');
  ResetThread := TTestThread.Create(ManualEvent, 'reset_loop');
  
  SetThread.Start;
  ResetThread.Start;
  
  // 让它们运行一段时间
  Sleep(100);
  
  SetThread.Terminate;
  ResetThread.Terminate;
  
  SetThread.WaitFor;
  ResetThread.WaitFor;
  
  // 验证没有异常发生
  AssertTrue('Set thread should not have exceptions', SetThread.TestException = nil);
  AssertTrue('Reset thread should not have exceptions', ResetThread.TestException = nil);
  
  SetThread.Free;
  ResetThread.Free;
end;

procedure TTestCase_Event_Enhanced.Test_RaceConditions_IsSignaledConsistency;
var
  CheckThread: TTestThread;
  ManualEvent: IEvent;
  i: Integer;
begin
  ManualEvent := CreateEvent(True, True); // 手动重置事件，初始为信号状态
  
  // 创建持续检查 IsSignaled 的线程
  CheckThread := TTestThread.Create(ManualEvent, 'check_signaled');
  CheckThread.Start;
  
  // 主线程进行设置和重置操作
  for i := 1 to 100 do
  begin
    ManualEvent.ResetEvent;
    Sleep(1);
    ManualEvent.SetEvent;
    Sleep(1);
  end;
  
  CheckThread.Terminate;
  CheckThread.WaitFor;
  
  AssertTrue('IsSignaled check thread should not have exceptions', 
             CheckThread.TestException = nil);
  
  CheckThread.Free;
end;

procedure TTestCase_Event_Enhanced.Test_RaceConditions_AtomicStateConsistency;
var
  ManualEvent: IEvent;
  i: Integer;
  IsSignaledResult: Boolean;
  TryWaitResult: Boolean;
begin
  ManualEvent := CreateEvent(True, False); // 手动重置事件
  
  // 测试原子状态和实际状态的一致性
  for i := 1 to 1000 do
  begin
    ManualEvent.SetEvent;
    
    // IsSignaled 和 TryWait 应该给出一致的结果
    IsSignaledResult := ManualEvent.IsSignaled;
    TryWaitResult := ManualEvent.TryWait;
    
    AssertEquals(Format('IsSignaled and TryWait should be consistent at iteration %d', [i]),
                 IsSignaledResult, TryWaitResult);
    
    ManualEvent.ResetEvent;
  end;
end;

procedure TTestCase_Event_Enhanced.Test_MemoryBarrier_StateVisibility;
var
  ManualEvent: IEvent;
  CheckThread: TTestThread;
begin
  ManualEvent := CreateEvent(True, False); // 手动重置事件
  
  // 创建检查线程
  CheckThread := TTestThread.Create(ManualEvent, 'visibility_check');
  CheckThread.Start;
  
  // 主线程设置事件
  Sleep(10); // 确保检查线程开始运行
  ManualEvent.SetEvent;
  
  // 等待检查线程完成
  CheckThread.WaitFor;
  
  // 检查线程应该能看到状态变化
  AssertTrue('Check thread should see state change', CheckThread.TestResult);
  AssertTrue('Check thread should not have exceptions', CheckThread.TestException = nil);
  
  CheckThread.Free;
end;

procedure TTestCase_Event_Enhanced.Test_MemoryBarrier_OrderingGuarantees;
var
  ManualEvent: IEvent;
begin
  ManualEvent := CreateEvent(True, False);
  
  // 这个测试验证内存屏障确保操作顺序
  // 在实际应用中，这需要更复杂的多线程场景来验证
  ManualEvent.SetEvent;
  AssertTrue('Event should be signaled after SetEvent', ManualEvent.IsSignaled);
  
  ManualEvent.ResetEvent;
  AssertFalse('Event should not be signaled after ResetEvent', ManualEvent.IsSignaled);
end;

procedure TTestCase_Event_Enhanced.Test_IsSignaled_AutoResetNonDestructive;
var
  AutoEvent: IEvent;
  IsSignaledBefore, IsSignaledAfter: Boolean;
  TryWaitResult: Boolean;
begin
  AutoEvent := CreateEvent(False, False); // 自动重置事件
  AutoEvent.SetEvent;
  
  // 对于自动重置事件，IsSignaled 应该是非破坏性的
  IsSignaledBefore := AutoEvent.IsSignaled;
  TryWaitResult := AutoEvent.TryWait; // 这会消费信号
  IsSignaledAfter := AutoEvent.IsSignaled;
  
  // 验证 IsSignaled 不会消费信号
  AssertTrue('TryWait should succeed', TryWaitResult);
  AssertFalse('IsSignaled after TryWait should be false', IsSignaledAfter);
end;

procedure TTestCase_Event_Enhanced.Test_IsSignaled_ManualResetConsistency;
var
  ManualEvent: IEvent;
  i: Integer;
begin
  ManualEvent := CreateEvent(True, False); // 手动重置事件
  
  // 测试手动重置事件的 IsSignaled 一致性
  for i := 1 to 100 do
  begin
    ManualEvent.SetEvent;
    AssertTrue(Format('IsSignaled should be true after SetEvent (iteration %d)', [i]),
               ManualEvent.IsSignaled);
    
    ManualEvent.ResetEvent;
    AssertFalse(Format('IsSignaled should be false after ResetEvent (iteration %d)', [i]),
                ManualEvent.IsSignaled);
  end;
end;

procedure TTestCase_Event_Enhanced.Test_IsSignaled_ConcurrentAccess;
var
  CheckThreads: array[0..4] of TTestThread;
  ManualEvent: IEvent;
  i: Integer;
begin
  ManualEvent := CreateEvent(True, True); // 手动重置事件，初始为信号状态
  
  // 创建多个并发检查线程
  for i := 0 to High(CheckThreads) do
  begin
    CheckThreads[i] := TTestThread.Create(ManualEvent, 'concurrent_check');
    CheckThreads[i].Start;
  end;
  
  // 让线程运行一段时间
  Sleep(100);
  
  // 终止所有线程
  for i := 0 to High(CheckThreads) do
  begin
    CheckThreads[i].Terminate;
    CheckThreads[i].WaitFor;
    
    AssertTrue(Format('Check thread %d should not have exceptions', [i]),
               CheckThreads[i].TestException = nil);
    
    CheckThreads[i].Free;
  end;
end;

{ TTestThread }

constructor TTestThread.Create(const AEvent: IEvent; const AOperation: string);
begin
  inherited Create(True); // 创建为挂起状态
  FEvent := AEvent;
  FOperation := AOperation;
  FResult := False;
  FException := nil;
  FreeOnTerminate := False;
end;

destructor TTestThread.Destroy;
begin
  FException.Free;
  inherited Destroy;
end;

procedure TTestThread.Execute;
var
  i: Integer;
begin
  try
    if FOperation = 'wait' then
    begin
      FResult := FEvent.WaitFor(1000) = wrSignaled;
    end
    else if FOperation = 'set_loop' then
    begin
      while not Terminated do
      begin
        FEvent.SetEvent;
        Sleep(1);
      end;
      FResult := True;
    end
    else if FOperation = 'reset_loop' then
    begin
      while not Terminated do
      begin
        FEvent.ResetEvent;
        Sleep(1);
      end;
      FResult := True;
    end
    else if FOperation = 'check_signaled' then
    begin
      while not Terminated do
      begin
        FEvent.IsSignaled; // 只是检查，不关心结果
        Sleep(1);
      end;
      FResult := True;
    end
    else if FOperation = 'visibility_check' then
    begin
      // 等待事件被设置
      for i := 1 to 1000 do
      begin
        if FEvent.IsSignaled then
        begin
          FResult := True;
          Exit;
        end;
        Sleep(1);
      end;
      FResult := False; // 超时未看到状态变化
    end
    else if FOperation = 'concurrent_check' then
    begin
      while not Terminated do
      begin
        FEvent.IsSignaled;
        FEvent.TryWait;
        Sleep(1);
      end;
      FResult := True;
    end;
  except
    on E: Exception do
    begin
      FException := Exception.Create(E.Message);
      FResult := False;
    end;
  end;
end;

initialization
  RegisterTest(TTestCase_Event_Enhanced);

end.
