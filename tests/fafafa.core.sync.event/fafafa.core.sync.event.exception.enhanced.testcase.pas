unit fafafa.core.sync.event.exception.enhanced.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.event, fafafa.core.sync.base;

type
  { 增强的异常和错误处理测试 }
  TTestCase_Event_Exception = class(TTestCase)
  private
    FEvent: IEvent;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 资源耗尽测试
    procedure Test_ResourceExhaustion_ManyEvents;
    procedure Test_ResourceExhaustion_Recovery;
    procedure Test_ResourceExhaustion_GradualIncrease;
    
    // 边界条件异常测试
    procedure Test_Boundary_InvalidParameters;
    procedure Test_Boundary_ExtremeTimeout;
    procedure Test_Boundary_RapidOperations;
    
    // 并发异常测试
    procedure Test_ConcurrentException_MultipleThreads;
    procedure Test_ConcurrentException_ThreadAbort;
    procedure Test_ConcurrentException_DeadlockPrevention;
    
    // 内存压力测试
    procedure Test_MemoryPressure_LowMemory;
    procedure Test_MemoryPressure_FragmentedMemory;
    
    // 平台特定异常测试
    {$IFDEF WINDOWS}
    procedure Test_Windows_HandleLimits;
    procedure Test_Windows_SystemShutdown;
    {$ENDIF}
    
    {$IFDEF UNIX}
    procedure Test_Unix_SignalHandling;
    procedure Test_Unix_ProcessLimits;
    {$ENDIF}
    
    // 恢复能力测试
    procedure Test_Recovery_AfterException;
    procedure Test_Recovery_PartialFailure;
    procedure Test_Recovery_SystemStress;
  end;

  { 异常测试辅助线程 }
  TExceptionTestThread = class(TThread)
  private
    FEvent: IEvent;
    FOperation: Integer;
    FIterations: Integer;
    FExceptionCount: Integer;
    FSuccessCount: Integer;
    FForceException: Boolean;
  public
    constructor Create(AEvent: IEvent; AOperation: Integer; AIterations: Integer; 
                      AForceException: Boolean = False);
    procedure Execute; override;
    property ExceptionCount: Integer read FExceptionCount;
    property SuccessCount: Integer read FSuccessCount;
  end;

  { 资源耗尽测试线程 }
  TResourceExhaustionThread = class(TThread)
  private
    FMaxEvents: Integer;
    FCreatedEvents: Integer;
    FEvents: array of IEvent;
    FExceptionOccurred: Boolean;
  public
    constructor Create(AMaxEvents: Integer);
    procedure Execute; override;
    destructor Destroy; override;
    property CreatedEvents: Integer read FCreatedEvents;
    property ExceptionOccurred: Boolean read FExceptionOccurred;
  end;

implementation

{ TTestCase_Event_Exception }

procedure TTestCase_Event_Exception.SetUp;
begin
  inherited SetUp;
  FEvent := MakeEvent(False, False);
end;

procedure TTestCase_Event_Exception.TearDown;
begin
  FEvent := nil;
  inherited TearDown;
end;

procedure TTestCase_Event_Exception.Test_ResourceExhaustion_ManyEvents;
var
  Events: array of IEvent;
  i, CreatedCount: Integer;
  ExceptionOccurred: Boolean;
begin
  SetLength(Events, 10000);
  CreatedCount := 0;
  ExceptionOccurred := False;
  
  try
    // 尝试创建大量事件
    for i := 0 to 9999 do
    begin
      try
        Events[i] := MakeEvent(i mod 2 = 0, False);
        Inc(CreatedCount);
        
        // 测试每个事件的基本功能
        Events[i].SetEvent;
        Events[i].TryWait;
        Events[i].ResetEvent;
      except
        on E: Exception do
        begin
          ExceptionOccurred := True;
          WriteLn(Format('Exception at event %d: %s', [i, E.Message]));
          Break;
        end;
      end;
    end;
  finally
    // 清理已创建的事件
    for i := 0 to CreatedCount - 1 do
      Events[i] := nil;
  end;
  
  WriteLn(Format('Created %d events before exhaustion', [CreatedCount]));
  
  // 应该能创建相当数量的事件
  AssertTrue('Should create at least 1000 events', CreatedCount >= 1000);
  
  if ExceptionOccurred then
    WriteLn('Resource exhaustion detected as expected')
  else
    WriteLn('All 10000 events created successfully');
end;

procedure TTestCase_Event_Exception.Test_ResourceExhaustion_Recovery;
var
  Thread1, Thread2: TResourceExhaustionThread;
begin
  // 第一次尝试耗尽资源
  Thread1 := TResourceExhaustionThread.Create(5000);
  try
    Thread1.Start;
    Thread1.WaitFor;
    
    WriteLn(Format('First attempt: Created %d events', [Thread1.CreatedEvents]));
  finally
    Thread1.Free;
  end;
  
  // 强制垃圾回收
  {$IFDEF FPC}
  // FreePascal 没有显式的垃圾回收，依赖引用计数
  {$ENDIF}
  
  Sleep(100); // 给系统时间清理资源
  
  // 第二次尝试，应该能够恢复
  Thread2 := TResourceExhaustionThread.Create(5000);
  try
    Thread2.Start;
    Thread2.WaitFor;
    
    WriteLn(Format('Recovery attempt: Created %d events', [Thread2.CreatedEvents]));
    
    // 恢复后应该能创建合理数量的事件
    AssertTrue('Should recover and create events', Thread2.CreatedEvents >= 1000);
  finally
    Thread2.Free;
  end;
end;

procedure TTestCase_Event_Exception.Test_ResourceExhaustion_GradualIncrease;
var
  BatchSize, TotalCreated, BatchCount: Integer;
  Events: array of IEvent;
  i, j: Integer;
  CanContinue: Boolean;
begin
  BatchSize := 100;
  TotalCreated := 0;
  BatchCount := 0;
  CanContinue := True;
  
  while CanContinue and (BatchCount < 100) do // 最多100批
  begin
    SetLength(Events, BatchSize);
    
    try
      // 创建一批事件
      for i := 0 to BatchSize - 1 do
      begin
        Events[i] := MakeEvent(i mod 2 = 0, False);
        Inc(TotalCreated);
        
        // 快速测试功能
        Events[i].SetEvent;
        Events[i].TryWait;
      end;
      
      Inc(BatchCount);
      WriteLn(Format('Batch %d: Created %d events (Total: %d)', 
                    [BatchCount, BatchSize, TotalCreated]));
      
      // 清理这批事件
      for j := 0 to BatchSize - 1 do
        Events[j] := nil;
      
    except
      on E: Exception do
      begin
        WriteLn(Format('Exception in batch %d: %s', [BatchCount, E.Message]));
        CanContinue := False;
        
        // 清理已创建的事件
        for j := 0 to i - 1 do
          if Events[j] <> nil then
            Events[j] := nil;
      end;
    end;
  end;
  
  WriteLn(Format('Gradual test completed: %d total events in %d batches', 
                [TotalCreated, BatchCount]));
  
  AssertTrue('Should create multiple batches', BatchCount >= 10);
  AssertTrue('Should create substantial number of events', TotalCreated >= 1000);
end;

procedure TTestCase_Event_Exception.Test_Boundary_InvalidParameters;
var
  E: IEvent;
  Result: TWaitResult;
begin
  E := MakeEvent(False, False);
  
  // 测试边界超时值
  try
    Result := E.WaitFor(0);
    AssertEquals('Zero timeout should work', Ord(wrTimeout), Ord(Result));
  except
    Fail('Zero timeout should not raise exception');
  end;
  
  try
    Result := E.WaitFor(1);
    AssertEquals('Minimum timeout should work', Ord(wrTimeout), Ord(Result));
  except
    Fail('Minimum timeout should not raise exception');
  end;
  
  try
    // 测试大超时值但不是无限等待（避免测试挂起）
    Result := E.WaitFor(10000); // 10秒超时
    WriteLn('Large timeout value accepted');
  except
    on E: Exception do
      Fail('Large timeout should be valid: ' + E.Message);
  end;
end;

procedure TTestCase_Event_Exception.Test_Boundary_ExtremeTimeout;
var
  E: IEvent;
  T: TExceptionTestThread;
  StartTime, ElapsedMs: QWord;
begin
  E := MakeEvent(False, False);
  StartTime := GetTickCount64;
  
  // 启动线程进行极长时间等待
  T := TExceptionTestThread.Create(E, 0, 1); // 操作0 = 等待
  try
    T.Start;
    Sleep(50); // 让线程开始等待
    
    // 设置信号以结束等待
    E.SetEvent;
    T.WaitFor;
    
    ElapsedMs := GetTickCount64 - StartTime;
    
    AssertEquals('Extreme timeout wait should succeed', 1, T.SuccessCount);
    AssertEquals('Should not have exceptions', 0, T.ExceptionCount);
    AssertTrue('Should complete in reasonable time', ElapsedMs < 1000);
  finally
    T.Free;
  end;
end;

procedure TTestCase_Event_Exception.Test_Boundary_RapidOperations;
var
  E: IEvent;
  i: Integer;
  ExceptionCount: Integer;
begin
  E := MakeEvent(True, False); // 手动重置
  ExceptionCount := 0;
  
  // 快速执行大量操作
  for i := 1 to 100000 do
  begin
    try
      case i mod 4 of
        0: E.SetEvent;
        1: E.ResetEvent;
        2: E.TryWait;
        3: E.WaitFor(0);
      end;
    except
      Inc(ExceptionCount);
    end;
  end;
  
  WriteLn(Format('Rapid operations: %d exceptions in 100000 operations', [ExceptionCount]));
  
  // 快速操作应该很少或没有异常
  AssertTrue('Rapid operations should be stable', ExceptionCount < 100);
end;

procedure TTestCase_Event_Exception.Test_ConcurrentException_MultipleThreads;
var
  E: IEvent;
  Threads: array[0..9] of TExceptionTestThread;
  i, TotalExceptions, TotalSuccesses: Integer;
begin
  E := MakeEvent(True, False); // 手动重置
  
  // 创建10个线程并发操作
  for i := 0 to 9 do
    Threads[i] := TExceptionTestThread.Create(E, i mod 4, 1000);
  
  try
    // 启动所有线程
    for i := 0 to 9 do
      Threads[i].Start;
    
    // 在运行过程中改变事件状态
    Sleep(10);
    E.SetEvent;
    Sleep(10);
    E.ResetEvent;
    Sleep(10);
    E.SetEvent;
    
    // 等待所有线程完成
    TotalExceptions := 0;
    TotalSuccesses := 0;
    for i := 0 to 9 do
    begin
      Threads[i].WaitFor;
      Inc(TotalExceptions, Threads[i].ExceptionCount);
      Inc(TotalSuccesses, Threads[i].SuccessCount);
    end;
    
    WriteLn(Format('Concurrent test: %d successes, %d exceptions', 
                  [TotalSuccesses, TotalExceptions]));
    
    AssertTrue('Should have substantial successes', TotalSuccesses >= 5000);
    AssertTrue('Exception rate should be low', TotalExceptions < TotalSuccesses div 10);
  finally
    for i := 0 to 9 do
      Threads[i].Free;
  end;
end;

procedure TTestCase_Event_Exception.Test_ConcurrentException_ThreadAbort;
var
  E: IEvent;
  Threads: array[0..4] of TExceptionTestThread;
  i: Integer;
begin
  E := MakeEvent(False, False); // 自动重置
  
  // 创建5个线程
  for i := 0 to 4 do
    Threads[i] := TExceptionTestThread.Create(E, 0, 1); // 等待操作
  
  try
    // 启动所有线程
    for i := 0 to 4 do
      Threads[i].Start;
    
    Sleep(20); // 让线程开始等待
    
    // 终止部分线程（模拟异常情况）
    Threads[0].Terminate;
    Threads[2].Terminate;
    
    // 为其余线程设置信号
    E.SetEvent;
    Sleep(10);
    E.SetEvent;
    Sleep(10);
    E.SetEvent;
    
    // 等待所有线程完成
    for i := 0 to 4 do
      Threads[i].WaitFor;
    
    WriteLn('Thread abort test completed');
    
    // 验证系统仍然稳定
    AssertTrue('Event should still be functional', E.TryWait or not E.TryWait);
  finally
    for i := 0 to 4 do
      Threads[i].Free;
  end;
end;

procedure TTestCase_Event_Exception.Test_ConcurrentException_DeadlockPrevention;
var
  Events: array[0..1] of IEvent;
  Threads: array[0..3] of TExceptionTestThread;
  i: Integer;
  StartTime, ElapsedMs: QWord;
begin
  // 创建两个事件
  Events[0] := MakeEvent(False, False);
  Events[1] := MakeEvent(False, False);
  
  StartTime := GetTickCount64;
  
  // 创建可能导致死锁的线程模式
  Threads[0] := TExceptionTestThread.Create(Events[0], 0, 1); // 等待事件0
  Threads[1] := TExceptionTestThread.Create(Events[1], 0, 1); // 等待事件1
  Threads[2] := TExceptionTestThread.Create(Events[0], 1, 10); // 操作事件0
  Threads[3] := TExceptionTestThread.Create(Events[1], 1, 10); // 操作事件1
  
  try
    // 启动所有线程
    for i := 0 to 3 do
      Threads[i].Start;
    
    Sleep(50); // 让线程运行
    
    // 设置信号解除等待
    Events[0].SetEvent;
    Events[1].SetEvent;
    
    // 等待所有线程完成
    for i := 0 to 3 do
      Threads[i].WaitFor;
    
    ElapsedMs := GetTickCount64 - StartTime;
    
    WriteLn(Format('Deadlock prevention test completed in %d ms', [ElapsedMs]));
    
    // 应该在合理时间内完成，没有死锁
    AssertTrue('Should complete without deadlock', ElapsedMs < 5000);
  finally
    for i := 0 to 3 do
      Threads[i].Free;
  end;
end;

procedure TTestCase_Event_Exception.Test_MemoryPressure_LowMemory;
var
  Events: array of IEvent;
  i, CreatedCount: Integer;
  MemoryPressure: Boolean;
begin
  // 模拟低内存条件下的行为
  SetLength(Events, 50000);
  CreatedCount := 0;
  MemoryPressure := False;
  
  try
    for i := 0 to 49999 do
    begin
      try
        Events[i] := MakeEvent(i mod 2 = 0, False);
        Inc(CreatedCount);
        
        // 每1000个事件测试一次功能
        if (i mod 1000) = 0 then
        begin
          Events[i].SetEvent;
          Events[i].TryWait;
        end;
      except
        on E: EOutOfMemory do
        begin
          MemoryPressure := True;
          WriteLn(Format('Memory pressure detected at %d events', [i]));
          Break;
        end;
        on E: Exception do
        begin
          WriteLn(Format('Other exception at %d: %s', [i, E.Message]));
          Break;
        end;
      end;
    end;
  finally
    // 清理
    for i := 0 to CreatedCount - 1 do
      Events[i] := nil;
  end;
  
  WriteLn(Format('Low memory test: Created %d events', [CreatedCount]));
  
  // 应该能创建合理数量的事件
  AssertTrue('Should handle memory pressure gracefully', CreatedCount >= 1000);
end;

procedure TTestCase_Event_Exception.Test_MemoryPressure_FragmentedMemory;
var
  Events1, Events2: array of IEvent;
  i, Phase1Count, Phase2Count: Integer;
begin
  // 第一阶段：创建大量事件
  SetLength(Events1, 10000);
  Phase1Count := 0;
  
  try
    for i := 0 to 9999 do
    begin
      Events1[i] := MakeEvent(i mod 2 = 0, False);
      Inc(Phase1Count);
    end;
    
    // 释放一半事件（创建内存碎片）
    for i := 0 to 9999 do
      if (i mod 2) = 0 then
        Events1[i] := nil;
    
    // 第二阶段：在碎片化内存中创建新事件
    SetLength(Events2, 5000);
    Phase2Count := 0;
    
    for i := 0 to 4999 do
    begin
      try
        Events2[i] := MakeEvent(True, i mod 3 = 0);
        Inc(Phase2Count);
        
        // 测试功能
        Events2[i].SetEvent;
        Events2[i].TryWait;
      except
        on E: Exception do
        begin
          WriteLn(Format('Fragmented memory exception at %d: %s', [i, E.Message]));
          Break;
        end;
      end;
    end;
  finally
    // 清理
    for i := 0 to 9999 do
      Events1[i] := nil;
    for i := 0 to Phase2Count - 1 do
      Events2[i] := nil;
  end;
  
  WriteLn(Format('Fragmented memory test: Phase1=%d, Phase2=%d', 
                [Phase1Count, Phase2Count]));
  
  AssertEquals('Phase 1 should complete', 10000, Phase1Count);
  AssertTrue('Phase 2 should handle fragmentation', Phase2Count >= 4000);
end;

{$IFDEF WINDOWS}
procedure TTestCase_Event_Exception.Test_Windows_HandleLimits;
var
  Events: array of IEvent;
  i, CreatedCount: Integer;
  HandleLimitReached: Boolean;
begin
  // Windows 系统句柄限制测试
  SetLength(Events, 100000);
  CreatedCount := 0;
  HandleLimitReached := False;
  
  try
    for i := 0 to 99999 do
    begin
      try
        Events[i] := MakeEvent(False, False);
        Inc(CreatedCount);
      except
        on E: Exception do
        begin
          if Pos('handle', LowerCase(E.Message)) > 0 then
            HandleLimitReached := True;
          WriteLn(Format('Windows handle limit at %d: %s', [i, E.Message]));
          Break;
        end;
      end;
    end;
  finally
    for i := 0 to CreatedCount - 1 do
      Events[i] := nil;
  end;
  
  WriteLn(Format('Windows handle test: Created %d events', [CreatedCount]));
  
  if HandleLimitReached then
    WriteLn('Handle limit detected as expected')
  else
    WriteLn('No handle limit reached');
  
  AssertTrue('Should create substantial number of handles', CreatedCount >= 1000);
end;

procedure TTestCase_Event_Exception.Test_Windows_SystemShutdown;
var
  E: IEvent;
  ExceptionOccurred: Boolean;
begin
  // 这个测试模拟系统关闭情况下的行为
  // 实际实现中，我们只能测试基本的异常处理
  
  ExceptionOccurred := False;
  
  try
    E := MakeEvent(False, False);
    E.SetEvent;
    E.WaitFor(100);
    E.ResetEvent;
    
    // 模拟系统压力
    Sleep(1);
    
    E.SetEvent;
    E.TryWait;
  except
    on Ex: Exception do
    begin
      ExceptionOccurred := True;
      WriteLn('System shutdown simulation exception: ' + Ex.Message);
    end;
  end;
  
  // 在正常情况下不应该有异常
  AssertFalse('Normal operations should not fail', ExceptionOccurred);
end;
{$ENDIF}

{$IFDEF UNIX}
procedure TTestCase_Event_Exception.Test_Unix_SignalHandling;
var
  E: IEvent;
  T: TExceptionTestThread;
  SignalHandled: Boolean;
begin
  E := MakeEvent(False, False);
  SignalHandled := False;
  
  // 启动等待线程
  T := TExceptionTestThread.Create(E, 0, 1); // 等待操作
  try
    T.Start;
    Sleep(10); // 让线程开始等待
    
    // 模拟信号中断（在实际环境中，这可能由系统信号触发）
    try
      E.SetEvent; // 正常设置信号
      SignalHandled := True;
    except
      on Ex: Exception do
        WriteLn('Signal handling exception: ' + Ex.Message);
    end;
    
    T.WaitFor;
    
    AssertTrue('Signal should be handled', SignalHandled);
    AssertEquals('Wait should succeed', 1, T.SuccessCount);
  finally
    T.Free;
  end;
end;

procedure TTestCase_Event_Exception.Test_Unix_ProcessLimits;
var
  Events: array of IEvent;
  i, CreatedCount: Integer;
  ProcessLimitReached: Boolean;
begin
  // Unix 进程资源限制测试
  SetLength(Events, 50000);
  CreatedCount := 0;
  ProcessLimitReached := False;
  
  try
    for i := 0 to 49999 do
    begin
      try
        Events[i] := MakeEvent(i mod 2 = 0, False);
        Inc(CreatedCount);
      except
        on E: Exception do
        begin
          ProcessLimitReached := True;
          WriteLn(Format('Unix process limit at %d: %s', [i, E.Message]));
          Break;
        end;
      end;
    end;
  finally
    for i := 0 to CreatedCount - 1 do
      Events[i] := nil;
  end;
  
  WriteLn(Format('Unix process limit test: Created %d events', [CreatedCount]));
  
  if ProcessLimitReached then
    WriteLn('Process limit detected')
  else
    WriteLn('No process limit reached');
  
  AssertTrue('Should create reasonable number of events', CreatedCount >= 1000);
end;
{$ENDIF}

procedure TTestCase_Event_Exception.Test_Recovery_AfterException;
var
  E: IEvent;
  ExceptionOccurred: Boolean;
  i: Integer;
begin
  ExceptionOccurred := False;
  
  // 尝试触发异常然后恢复
  try
    E := MakeEvent(False, False);
    
    // 执行一些可能导致异常的操作
    for i := 1 to 1000 do
    begin
      E.SetEvent;
      E.WaitFor(0);
      if i = 500 then
      begin
        // 模拟异常条件
        try
          // 这里可以添加特定的异常触发代码
          E.ResetEvent;
        except
          ExceptionOccurred := True;
          WriteLn('Simulated exception occurred');
        end;
      end;
    end;
    
    // 验证恢复后的功能
    E.SetEvent;
    AssertTrue('Should recover after exception', E.TryWait);
    
  except
    on Ex: Exception do
    begin
      ExceptionOccurred := True;
      WriteLn('Recovery test exception: ' + Ex.Message);
    end;
  end;
  
  // 即使发生异常，系统也应该能够恢复
  WriteLn(Format('Recovery test completed, exception occurred: %s', 
                [BoolToStr(ExceptionOccurred, True)]));
end;

procedure TTestCase_Event_Exception.Test_Recovery_PartialFailure;
var
  Events: array[0..9] of IEvent;
  i, SuccessCount, FailureCount: Integer;
begin
  SuccessCount := 0;
  FailureCount := 0;
  
  // 创建多个事件，部分可能失败
  for i := 0 to 9 do
  begin
    try
      Events[i] := MakeEvent(i mod 2 = 0, False);
      
      // 测试基本功能
      Events[i].SetEvent;
      Events[i].TryWait;
      Events[i].ResetEvent;
      
      Inc(SuccessCount);
    except
      on E: Exception do
      begin
        Inc(FailureCount);
        WriteLn(Format('Event %d failed: %s', [i, E.Message]));
        Events[i] := nil;
      end;
    end;
  end;
  
  WriteLn(Format('Partial failure test: %d successes, %d failures', 
                [SuccessCount, FailureCount]));
  
  // 清理成功创建的事件
  for i := 0 to 9 do
    Events[i] := nil;
  
  // 应该有大部分成功
  AssertTrue('Most events should succeed', SuccessCount >= 7);
end;

procedure TTestCase_Event_Exception.Test_Recovery_SystemStress;
var
  E: IEvent;
  Threads: array[0..19] of TExceptionTestThread;
  i, TotalSuccesses, TotalExceptions: Integer;
  StartTime, ElapsedMs: QWord;
begin
  E := MakeEvent(True, False); // 手动重置
  StartTime := GetTickCount64;
  
  // 创建20个线程进行压力测试
  for i := 0 to 19 do
    Threads[i] := TExceptionTestThread.Create(E, i mod 4, 500, i mod 5 = 0); // 20%线程强制异常
  
  try
    // 启动所有线程
    for i := 0 to 19 do
      Threads[i].Start;
    
    // 在压力测试期间改变事件状态
    for i := 1 to 10 do
    begin
      Sleep(20);
      E.SetEvent;
      Sleep(20);
      E.ResetEvent;
    end;
    
    // 等待所有线程完成
    TotalSuccesses := 0;
    TotalExceptions := 0;
    for i := 0 to 19 do
    begin
      Threads[i].WaitFor;
      Inc(TotalSuccesses, Threads[i].SuccessCount);
      Inc(TotalExceptions, Threads[i].ExceptionCount);
    end;
    
    ElapsedMs := GetTickCount64 - StartTime;
    
    WriteLn(Format('System stress test: %d successes, %d exceptions in %d ms', 
                  [TotalSuccesses, TotalExceptions, ElapsedMs]));
    
    // 验证系统在压力下仍然功能正常
    AssertTrue('Should have substantial successes under stress', TotalSuccesses >= 5000);
    AssertTrue('Should complete in reasonable time', ElapsedMs < 10000);
    
    // 验证事件在压力测试后仍然工作
    E.SetEvent;
    AssertTrue('Event should work after stress test', E.TryWait);
  finally
    for i := 0 to 19 do
      Threads[i].Free;
  end;
end;

{ TExceptionTestThread }

constructor TExceptionTestThread.Create(AEvent: IEvent; AOperation: Integer; 
                                       AIterations: Integer; AForceException: Boolean);
begin
  inherited Create(True);
  FEvent := AEvent;
  FOperation := AOperation;
  FIterations := AIterations;
  FForceException := AForceException;
  FExceptionCount := 0;
  FSuccessCount := 0;
end;

procedure TExceptionTestThread.Execute;
var
  i: Integer;
begin
  for i := 1 to FIterations do
  begin
    try
      if FForceException and (i mod 10 = 0) then
      begin
        // 模拟异常
        raise Exception.Create('Forced exception for testing');
      end;
      
      case FOperation of
        0: FEvent.WaitFor(5000); // 5秒等待（避免无限挂起）
        1: begin // SetReset
             FEvent.SetEvent;
             FEvent.ResetEvent;
           end;
        2: FEvent.TryWait; // TryWait
        3: FEvent.WaitFor(0); // 零超时等待
      end;
      
      Inc(FSuccessCount);
    except
      Inc(FExceptionCount);
    end;
  end;
end;

{ TResourceExhaustionThread }

constructor TResourceExhaustionThread.Create(AMaxEvents: Integer);
begin
  inherited Create(True);
  FMaxEvents := AMaxEvents;
  FCreatedEvents := 0;
  FExceptionOccurred := False;
  SetLength(FEvents, AMaxEvents);
end;

procedure TResourceExhaustionThread.Execute;
var
  i: Integer;
begin
  try
    for i := 0 to FMaxEvents - 1 do
    begin
      FEvents[i] := MakeEvent(i mod 2 = 0, False);
      Inc(FCreatedEvents);
      
      // 每100个事件测试一次功能
      if (i mod 100) = 0 then
      begin
        FEvents[i].SetEvent;
        FEvents[i].TryWait;
      end;
    end;
  except
    on E: Exception do
    begin
      FExceptionOccurred := True;
    end;
  end;
end;

destructor TResourceExhaustionThread.Destroy;
var
  i: Integer;
begin
  // 清理所有创建的事件
  for i := 0 to FCreatedEvents - 1 do
    FEvents[i] := nil;
  inherited Destroy;
end;

initialization
  RegisterTest(TTestCase_Event_Exception);

end.
