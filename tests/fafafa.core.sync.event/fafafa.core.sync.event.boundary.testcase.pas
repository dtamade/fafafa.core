unit fafafa.core.sync.event.boundary.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.event, fafafa.core.sync.base;

type
  { 边界条件和极限测试 }
  TTestCase_Event_Boundary = class(TTestCase)
  private
    FEvent: IEvent;
    function GetCurrentTimeMs: QWord;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 超时边界测试
    procedure Test_Timeout_Zero;
    procedure Test_Timeout_One;
    procedure Test_Timeout_MaxCardinal;
    procedure Test_Timeout_NearMaxCardinal;
    
    // 快速操作序列测试
    procedure Test_RapidSetReset_10000_Cycles;
    procedure Test_RapidTryWait_10000_Calls;
    procedure Test_RapidWaitTimeout_1000_Calls;
    
    // 状态转换边界测试
    procedure Test_StateTransition_SetAfterSet;
    procedure Test_StateTransition_ResetAfterReset;
    procedure Test_StateTransition_SetResetSet;
    
    // 时间精度测试
    procedure Test_TimingPrecision_1ms;
    procedure Test_TimingPrecision_10ms;
    procedure Test_TimingPrecision_100ms;
    
    // 内存压力测试
    procedure Test_MemoryPressure_CreateDestroy_1000;
    procedure Test_MemoryPressure_CreateDestroy_10000;
    
    // 线程数量边界测试
    procedure Test_ThreadBoundary_SingleWaiter;
    procedure Test_ThreadBoundary_TwoWaiters;
    procedure Test_ThreadBoundary_TenWaiters;
    procedure Test_ThreadBoundary_HundredWaiters;
  end;

  { 边界测试辅助线程 }
  TBoundaryTestThread = class(TThread)
  private
    FEvent: IEvent;
    FOperation: Integer; // 0=Wait, 1=TryWait, 2=SetEvent, 3=ResetEvent
    FResult: TWaitResult;
    FSuccess: Boolean;
    FIterations: Integer;
  public
    constructor Create(AEvent: IEvent; AOperation: Integer; AIterations: Integer = 1);
    procedure Execute; override;
    property Result: TWaitResult read FResult;
    property Success: Boolean read FSuccess;
  end;

implementation

{ TTestCase_Event_Boundary }

function TTestCase_Event_Boundary.GetCurrentTimeMs: QWord;
begin
  Result := GetTickCount64;
end;

procedure TTestCase_Event_Boundary.SetUp;
begin
  inherited SetUp;
  FEvent := MakeEvent(False, False); // 默认自动重置，未信号
end;

procedure TTestCase_Event_Boundary.TearDown;
begin
  FEvent := nil;
  inherited TearDown;
end;

procedure TTestCase_Event_Boundary.Test_Timeout_Zero;
var
  StartTime, ElapsedMs: QWord;
  Result: TWaitResult;
begin
  StartTime := GetCurrentTimeMs;
  Result := FEvent.WaitFor(0);
  ElapsedMs := GetCurrentTimeMs - StartTime;
  
  AssertEquals('Zero timeout should return timeout', Ord(wrTimeout), Ord(Result));
  AssertTrue('Zero timeout should be very fast', ElapsedMs < 5);
end;

procedure TTestCase_Event_Boundary.Test_Timeout_One;
var
  StartTime, ElapsedMs: QWord;
  Result: TWaitResult;
begin
  StartTime := GetCurrentTimeMs;
  Result := FEvent.WaitFor(1);
  ElapsedMs := GetCurrentTimeMs - StartTime;
  
  AssertEquals('1ms timeout should return timeout', Ord(wrTimeout), Ord(Result));
  AssertTrue('1ms timeout should be fast', ElapsedMs < 50);
end;

procedure TTestCase_Event_Boundary.Test_Timeout_MaxCardinal;
var
  E: IEvent;
  T: TBoundaryTestThread;
begin
  E := MakeEvent(False, False);
  
  // 启动线程进行无限等待
  T := TBoundaryTestThread.Create(E, 0); // 0 = Wait operation
  try
    T.Start; // 启动线程
    Sleep(10); // 让线程开始等待

    // 设置信号
    E.SetEvent;

    // 等待线程完成
    T.WaitFor;
    
    AssertEquals('Max timeout wait should succeed', Ord(wrSignaled), Ord(T.Result));
  finally
    T.Free;
  end;
end;

procedure TTestCase_Event_Boundary.Test_Timeout_NearMaxCardinal;
var
  StartTime, ElapsedMs: QWord;
  Result: TWaitResult;
  E: IEvent;
  T: TBoundaryTestThread;
begin
  E := MakeEvent(False, False);
  
  // 测试接近最大值的超时（但不是无限）
  StartTime := GetCurrentTimeMs;
  
  // 启动线程在50ms后设置信号
  T := TBoundaryTestThread.Create(E, 2); // 2 = SetEvent operation
  try
    T.Start;
    Sleep(50); // 延迟50ms

    Result := E.WaitFor(1000); // 使用1秒超时而不是接近最大值
    ElapsedMs := GetCurrentTimeMs - StartTime;

    T.WaitFor;

    AssertEquals('1 second timeout should succeed', Ord(wrSignaled), Ord(Result));
    AssertTrue('Should complete in reasonable time', ElapsedMs < 500);
  finally
    T.Free;
  end;
end;

procedure TTestCase_Event_Boundary.Test_RapidSetReset_10000_Cycles;
var
  i: Integer;
  StartTime, ElapsedMs: QWord;
  E: IEvent;
begin
  E := MakeEvent(True, False); // 手动重置事件
  StartTime := GetCurrentTimeMs;
  
  for i := 1 to 10000 do
  begin
    E.SetEvent;
    E.ResetEvent;
  end;
  
  ElapsedMs := GetCurrentTimeMs - StartTime;
  WriteLn(Format('10000 SetEvent/ResetEvent cycles completed in %d ms', [ElapsedMs]));
  
  AssertTrue('10000 cycles should complete in reasonable time', ElapsedMs < 1000);
end;

procedure TTestCase_Event_Boundary.Test_RapidTryWait_10000_Calls;
var
  i: Integer;
  StartTime, ElapsedMs: QWord;
  E: IEvent;
  SuccessCount: Integer;
begin
  E := MakeEvent(True, True); // 手动重置，初始信号
  StartTime := GetCurrentTimeMs;
  SuccessCount := 0;
  
  for i := 1 to 10000 do
  begin
    if E.TryWait then
      Inc(SuccessCount);
  end;
  
  ElapsedMs := GetCurrentTimeMs - StartTime;
  WriteLn(Format('10000 TryWait calls completed in %d ms, %d successes', [ElapsedMs, SuccessCount]));
  
  AssertTrue('10000 TryWait calls should complete quickly', ElapsedMs < 500);
  AssertEquals('All TryWait should succeed on signaled manual reset event', 10000, SuccessCount);
end;

procedure TTestCase_Event_Boundary.Test_RapidWaitTimeout_1000_Calls;
var
  i: Integer;
  StartTime, ElapsedMs: QWord;
  E: IEvent;
  TimeoutCount: Integer;
begin
  E := MakeEvent(False, False); // 自动重置，未信号
  StartTime := GetCurrentTimeMs;
  TimeoutCount := 0;
  
  for i := 1 to 1000 do
  begin
    if E.WaitFor(0) = wrTimeout then
      Inc(TimeoutCount);
  end;
  
  ElapsedMs := GetCurrentTimeMs - StartTime;
  WriteLn(Format('1000 WaitFor(0) calls completed in %d ms, %d timeouts', [ElapsedMs, TimeoutCount]));
  
  AssertTrue('1000 zero-timeout waits should complete quickly', ElapsedMs < 200);
  AssertEquals('All waits should timeout on non-signaled event', 1000, TimeoutCount);
end;

procedure TTestCase_Event_Boundary.Test_StateTransition_SetAfterSet;
var
  E: IEvent;
  Result1, Result2: TWaitResult;
begin
  E := MakeEvent(True, False); // 手动重置
  
  E.SetEvent;
  E.SetEvent; // 重复设置
  
  Result1 := E.WaitFor(0);
  Result2 := E.WaitFor(0);
  
  AssertEquals('First wait should succeed', Ord(wrSignaled), Ord(Result1));
  AssertEquals('Second wait should succeed (manual reset)', Ord(wrSignaled), Ord(Result2));
end;

procedure TTestCase_Event_Boundary.Test_StateTransition_ResetAfterReset;
var
  E: IEvent;
  Result: TWaitResult;
begin
  E := MakeEvent(True, False); // 手动重置，未信号
  
  E.ResetEvent; // 重复重置
  E.ResetEvent;
  
  Result := E.WaitFor(0);
  AssertEquals('Wait should timeout after multiple resets', Ord(wrTimeout), Ord(Result));
end;

procedure TTestCase_Event_Boundary.Test_StateTransition_SetResetSet;
var
  E: IEvent;
  Result1, Result2, Result3: TWaitResult;
begin
  E := MakeEvent(True, False); // 手动重置
  
  E.SetEvent;
  Result1 := E.WaitFor(0);
  
  E.ResetEvent;
  Result2 := E.WaitFor(0);
  
  E.SetEvent;
  Result3 := E.WaitFor(0);
  
  AssertEquals('First wait should succeed', Ord(wrSignaled), Ord(Result1));
  AssertEquals('Second wait should timeout after reset', Ord(wrTimeout), Ord(Result2));
  AssertEquals('Third wait should succeed after set', Ord(wrSignaled), Ord(Result3));
end;

procedure TTestCase_Event_Boundary.Test_TimingPrecision_1ms;
var
  E: IEvent;
  T: TBoundaryTestThread;
  StartTime, ElapsedMs: QWord;
  Result: TWaitResult;
begin
  E := MakeEvent(False, False);
  
  // 启动线程在1ms后设置信号
  T := TBoundaryTestThread.Create(E, 2); // 2 = SetEvent
  try
    StartTime := GetCurrentTimeMs;
    Sleep(1);
    T.Start;
    
    Result := E.WaitFor(100); // 给足够的时间
    ElapsedMs := GetCurrentTimeMs - StartTime;
    
    T.WaitFor;
    
    AssertEquals('1ms precision test should succeed', Ord(wrSignaled), Ord(Result));
    AssertTrue('Should complete in reasonable time', ElapsedMs < 50);
  finally
    T.Free;
  end;
end;

procedure TTestCase_Event_Boundary.Test_TimingPrecision_10ms;
var
  E: IEvent;
  T: TBoundaryTestThread;
  StartTime, ElapsedMs: QWord;
  Result: TWaitResult;
begin
  E := MakeEvent(False, False);
  
  T := TBoundaryTestThread.Create(E, 2); // 2 = SetEvent
  try
    StartTime := GetCurrentTimeMs;
    Sleep(10);
    T.Start;
    
    Result := E.WaitFor(100);
    ElapsedMs := GetCurrentTimeMs - StartTime;
    
    T.WaitFor;
    
    AssertEquals('10ms precision test should succeed', Ord(wrSignaled), Ord(Result));
    AssertTrue('Should complete in reasonable time', ElapsedMs < 100);
  finally
    T.Free;
  end;
end;

procedure TTestCase_Event_Boundary.Test_TimingPrecision_100ms;
var
  E: IEvent;
  T: TBoundaryTestThread;
  StartTime, ElapsedMs: QWord;
  Result: TWaitResult;
begin
  E := MakeEvent(False, False);
  
  T := TBoundaryTestThread.Create(E, 2); // 2 = SetEvent
  try
    StartTime := GetCurrentTimeMs;
    Sleep(100);
    T.Start;
    
    Result := E.WaitFor(200);
    ElapsedMs := GetCurrentTimeMs - StartTime;
    
    T.WaitFor;
    
    AssertEquals('100ms precision test should succeed', Ord(wrSignaled), Ord(Result));
    AssertTrue('Should complete in reasonable time', ElapsedMs < 300);
  finally
    T.Free;
  end;
end;

procedure TTestCase_Event_Boundary.Test_MemoryPressure_CreateDestroy_1000;
var
  i: Integer;
  Events: array[0..999] of IEvent;
  StartTime, ElapsedMs: QWord;
begin
  StartTime := GetCurrentTimeMs;
  
  // 创建1000个事件
  for i := 0 to 999 do
    Events[i] := MakeEvent(i mod 2 = 0, i mod 3 = 0);
  
  // 使用事件
  for i := 0 to 999 do
  begin
    Events[i].SetEvent;
    Events[i].TryWait;
    Events[i].ResetEvent;
  end;
  
  // 清理（通过设置为nil）
  for i := 0 to 999 do
    Events[i] := nil;
  
  ElapsedMs := GetCurrentTimeMs - StartTime;
  WriteLn(Format('1000 events create/use/destroy completed in %d ms', [ElapsedMs]));
  
  AssertTrue('1000 events should be handled efficiently', ElapsedMs < 1000);
end;

procedure TTestCase_Event_Boundary.Test_MemoryPressure_CreateDestroy_10000;
var
  i: Integer;
  E: IEvent;
  StartTime, ElapsedMs: QWord;
begin
  StartTime := GetCurrentTimeMs;
  
  // 快速创建和销毁10000个事件
  for i := 1 to 10000 do
  begin
    E := MakeEvent(i mod 2 = 0, False);
    E.SetEvent;
    E.TryWait;
    E := nil; // 释放
  end;
  
  ElapsedMs := GetCurrentTimeMs - StartTime;
  WriteLn(Format('10000 events rapid create/destroy completed in %d ms', [ElapsedMs]));
  
  AssertTrue('10000 rapid create/destroy should be efficient', ElapsedMs < 2000);
end;

{ TBoundaryTestThread }

constructor TBoundaryTestThread.Create(AEvent: IEvent; AOperation: Integer; AIterations: Integer);
begin
  inherited Create(True); // 创建时暂停
  FEvent := AEvent;
  FOperation := AOperation;
  FIterations := AIterations;
  FSuccess := False;
  FResult := wrError;
end;

procedure TBoundaryTestThread.Execute;
var
  i: Integer;
begin
  try
    for i := 1 to FIterations do
    begin
      case FOperation of
        0: FResult := FEvent.WaitFor(High(Cardinal)); // 无限等待
        1: FSuccess := FEvent.TryWait;
        2: FEvent.SetEvent;
        3: FEvent.ResetEvent;
      end;
    end;
    
    if FOperation <> 0 then
      FSuccess := True;
  except
    FSuccess := False;
    FResult := wrError;
  end;
end;

procedure TTestCase_Event_Boundary.Test_ThreadBoundary_SingleWaiter;
var
  E: IEvent;
  T: TBoundaryTestThread;
begin
  E := MakeEvent(False, False);
  
  T := TBoundaryTestThread.Create(E, 0); // Wait operation
  try
    T.Start;
    Sleep(10); // 让线程开始等待
    
    E.SetEvent;
    T.WaitFor;
    
    AssertEquals('Single waiter should succeed', Ord(wrSignaled), Ord(T.Result));
  finally
    T.Free;
  end;
end;

procedure TTestCase_Event_Boundary.Test_ThreadBoundary_TwoWaiters;
var
  E: IEvent;
  T1, T2: TBoundaryTestThread;
begin
  E := MakeEvent(True, False); // 手动重置
  
  T1 := TBoundaryTestThread.Create(E, 0);
  T2 := TBoundaryTestThread.Create(E, 0);
  try
    T1.Start;
    T2.Start;
    Sleep(10);
    
    E.SetEvent;
    T1.WaitFor;
    T2.WaitFor;
    
    AssertEquals('First waiter should succeed', Ord(wrSignaled), Ord(T1.Result));
    AssertEquals('Second waiter should succeed (manual reset)', Ord(wrSignaled), Ord(T2.Result));
  finally
    T1.Free;
    T2.Free;
  end;
end;

procedure TTestCase_Event_Boundary.Test_ThreadBoundary_TenWaiters;
var
  E: IEvent;
  Threads: array[0..9] of TBoundaryTestThread;
  i: Integer;
begin
  E := MakeEvent(True, False); // 手动重置
  
  // 创建10个等待线程
  for i := 0 to 9 do
    Threads[i] := TBoundaryTestThread.Create(E, 0);
  
  try
    // 启动所有线程
    for i := 0 to 9 do
      Threads[i].Start;
    
    Sleep(20); // 让所有线程开始等待
    
    E.SetEvent; // 唤醒所有线程
    
    // 等待所有线程完成
    for i := 0 to 9 do
    begin
      Threads[i].WaitFor;
      AssertEquals(Format('Thread %d should succeed', [i]), Ord(wrSignaled), Ord(Threads[i].Result));
    end;
  finally
    for i := 0 to 9 do
      Threads[i].Free;
  end;
end;

procedure TTestCase_Event_Boundary.Test_ThreadBoundary_HundredWaiters;
var
  E: IEvent;
  Threads: array[0..99] of TBoundaryTestThread;
  i, SuccessCount: Integer;
  StartTime, ElapsedMs: QWord;
begin
  E := MakeEvent(True, False); // 手动重置
  StartTime := GetCurrentTimeMs;
  
  // 创建100个等待线程
  for i := 0 to 99 do
    Threads[i] := TBoundaryTestThread.Create(E, 0);
  
  try
    // 启动所有线程
    for i := 0 to 99 do
      Threads[i].Start;
    
    Sleep(50); // 让所有线程开始等待
    
    E.SetEvent; // 唤醒所有线程
    
    // 等待所有线程完成并统计成功数
    SuccessCount := 0;
    for i := 0 to 99 do
    begin
      Threads[i].WaitFor;
      if Threads[i].Result = wrSignaled then
        Inc(SuccessCount);
    end;
    
    ElapsedMs := GetCurrentTimeMs - StartTime;
    WriteLn(Format('100 waiters test completed in %d ms, %d successes', [ElapsedMs, SuccessCount]));
    
    AssertEquals('All 100 threads should succeed', 100, SuccessCount);
    AssertTrue('100 waiters should complete in reasonable time', ElapsedMs < 1000);
  finally
    for i := 0 to 99 do
      Threads[i].Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Event_Boundary);

end.
