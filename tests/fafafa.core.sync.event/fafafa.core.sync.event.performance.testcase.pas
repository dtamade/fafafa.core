unit fafafa.core.sync.event.performance.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.event, fafafa.core.sync.base;

type
  // 性能基准测试
  TTestCase_Event_Performance = class(TTestCase)
  private
    function GetCurrentTimeMs: Int64;
    procedure LogPerformanceResult(const TestName: string; Operations: Integer; ElapsedMs: Int64);
    function MeasureOperationsPerSecond(const TestName: string; 
                                       const Operation: TProc; 
                                       TargetDurationMs: Integer = 1000): Double;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 基础操作性能测试
    procedure Test_Performance_SetEvent_ManualReset;
    procedure Test_Performance_SetEvent_AutoReset;
    procedure Test_Performance_ResetEvent_ManualReset;
    procedure Test_Performance_TryWait_Signaled_ManualReset;
    procedure Test_Performance_TryWait_NotSignaled_ManualReset;
    procedure Test_Performance_IsSignaled_ManualReset;
    
    // 快速路径优化验证
    procedure Test_FastPath_SetEvent_AlreadySignaled;
    procedure Test_FastPath_ResetEvent_AlreadyReset;
    procedure Test_FastPath_TryWait_ManualReset;
    
    // 批量操作性能测试
    procedure Test_Performance_WaitForMultiple_Any;
    procedure Test_Performance_WaitForMultiple_All;
    
    // 并发性能测试
    procedure Test_Performance_ConcurrentSetReset;
    procedure Test_Performance_ConcurrentTryWait;
    
    // 内存使用测试
    procedure Test_Performance_MemoryUsage;
  end;

  // 性能测试辅助线程
  TPerformanceThread = class(TThread)
  private
    FEvent: IEvent;
    FOperation: string;
    FIterations: Integer;
    FElapsedMs: Int64;
  protected
    procedure Execute; override;
  public
    constructor Create(const AEvent: IEvent; const AOperation: string; AIterations: Integer);
    property ElapsedMs: Int64 read FElapsedMs;
  end;

implementation

{ TTestCase_Event_Performance }

procedure TTestCase_Event_Performance.SetUp;
begin
  inherited SetUp;
  WriteLn('=== Event Performance Tests ===');
end;

procedure TTestCase_Event_Performance.TearDown;
begin
  WriteLn('=== Performance Tests Complete ===');
  inherited TearDown;
end;

function TTestCase_Event_Performance.GetCurrentTimeMs: Int64;
begin
  Result := GetTickCount64;
end;

procedure TTestCase_Event_Performance.LogPerformanceResult(const TestName: string; 
                                                          Operations: Integer; 
                                                          ElapsedMs: Int64);
var
  OpsPerSecond: Double;
begin
  if ElapsedMs > 0 then
    OpsPerSecond := (Operations * 1000.0) / ElapsedMs
  else
    OpsPerSecond := 0;
    
  WriteLn(Format('%s: %d ops in %d ms = %.0f ops/sec', 
                [TestName, Operations, ElapsedMs, OpsPerSecond]));
end;

function TTestCase_Event_Performance.MeasureOperationsPerSecond(const TestName: string; 
                                                               const Operation: TProc; 
                                                               TargetDurationMs: Integer): Double;
var
  StartTime, EndTime: Int64;
  Operations: Integer;
begin
  Operations := 0;
  StartTime := GetCurrentTimeMs;
  
  repeat
    Operation();
    Inc(Operations);
    
    if Operations mod 1000 = 0 then // 每1000次操作检查一次时间
    begin
      EndTime := GetCurrentTimeMs;
      if EndTime - StartTime >= TargetDurationMs then
        Break;
    end;
  until False;
  
  EndTime := GetCurrentTimeMs;
  LogPerformanceResult(TestName, Operations, EndTime - StartTime);
  
  if EndTime - StartTime > 0 then
    Result := (Operations * 1000.0) / (EndTime - StartTime)
  else
    Result := 0;
end;

procedure TTestCase_Event_Performance.Test_Performance_SetEvent_ManualReset;
var
  Event: IEvent;
  OpsPerSec: Double;
begin
  Event := CreateEvent(True, False); // 手动重置事件
  
  OpsPerSec := MeasureOperationsPerSecond('SetEvent (Manual Reset)', 
    procedure
    begin
      Event.SetEvent;
      Event.ResetEvent; // 重置以便下次测试
    end);
    
  // 期望性能：> 100K ops/sec
  AssertTrue('SetEvent performance should be > 100K ops/sec', OpsPerSec > 100000);
end;

procedure TTestCase_Event_Performance.Test_Performance_SetEvent_AutoReset;
var
  Event: IEvent;
  OpsPerSec: Double;
begin
  Event := CreateEvent(False, False); // 自动重置事件
  
  OpsPerSec := MeasureOperationsPerSecond('SetEvent (Auto Reset)', 
    procedure
    begin
      Event.SetEvent;
    end);
    
  // 期望性能：> 50K ops/sec
  AssertTrue('SetEvent (auto) performance should be > 50K ops/sec', OpsPerSec > 50000);
end;

procedure TTestCase_Event_Performance.Test_Performance_ResetEvent_ManualReset;
var
  Event: IEvent;
  OpsPerSec: Double;
begin
  Event := CreateEvent(True, True); // 手动重置事件，初始为信号状态
  
  OpsPerSec := MeasureOperationsPerSecond('ResetEvent (Manual Reset)', 
    procedure
    begin
      Event.ResetEvent;
      Event.SetEvent; // 设置以便下次测试
    end);
    
  // 期望性能：> 100K ops/sec
  AssertTrue('ResetEvent performance should be > 100K ops/sec', OpsPerSec > 100000);
end;

procedure TTestCase_Event_Performance.Test_Performance_TryWait_Signaled_ManualReset;
var
  Event: IEvent;
  OpsPerSec: Double;
begin
  Event := CreateEvent(True, True); // 手动重置事件，初始为信号状态
  
  OpsPerSec := MeasureOperationsPerSecond('TryWait (Signaled, Manual Reset)', 
    procedure
    begin
      Event.TryWait; // 对于手动重置事件，这不会消费信号
    end);
    
  // 期望性能：> 1M ops/sec（无锁快速路径）
  AssertTrue('TryWait (signaled) performance should be > 1M ops/sec', OpsPerSec > 1000000);
end;

procedure TTestCase_Event_Performance.Test_Performance_TryWait_NotSignaled_ManualReset;
var
  Event: IEvent;
  OpsPerSec: Double;
begin
  Event := CreateEvent(True, False); // 手动重置事件，初始为非信号状态
  
  OpsPerSec := MeasureOperationsPerSecond('TryWait (Not Signaled, Manual Reset)', 
    procedure
    begin
      Event.TryWait; // 应该快速返回 False
    end);
    
  // 期望性能：> 500K ops/sec
  AssertTrue('TryWait (not signaled) performance should be > 500K ops/sec', OpsPerSec > 500000);
end;

procedure TTestCase_Event_Performance.Test_Performance_IsSignaled_ManualReset;
var
  Event: IEvent;
  OpsPerSec: Double;
begin
  Event := CreateEvent(True, True); // 手动重置事件，初始为信号状态
  
  OpsPerSec := MeasureOperationsPerSecond('IsSignaled (Manual Reset)', 
    procedure
    begin
      Event.IsSignaled; // 无锁操作
    end);
    
  // 期望性能：> 5M ops/sec（纯原子操作）
  AssertTrue('IsSignaled performance should be > 5M ops/sec', OpsPerSec > 5000000);
end;

procedure TTestCase_Event_Performance.Test_FastPath_SetEvent_AlreadySignaled;
var
  Event: IEvent;
  OpsPerSec: Double;
begin
  Event := CreateEvent(True, True); // 手动重置事件，初始为信号状态
  
  OpsPerSec := MeasureOperationsPerSecond('SetEvent Fast Path (Already Signaled)', 
    procedure
    begin
      Event.SetEvent; // 应该使用快速路径，直接返回
    end);
    
  // 期望性能：> 2M ops/sec（快速路径优化）
  AssertTrue('SetEvent fast path should be > 2M ops/sec', OpsPerSec > 2000000);
end;

procedure TTestCase_Event_Performance.Test_FastPath_ResetEvent_AlreadyReset;
var
  Event: IEvent;
  OpsPerSec: Double;
begin
  Event := CreateEvent(True, False); // 手动重置事件，初始为非信号状态
  
  OpsPerSec := MeasureOperationsPerSecond('ResetEvent Fast Path (Already Reset)', 
    procedure
    begin
      Event.ResetEvent; // 应该使用快速路径，直接返回
    end);
    
  // 期望性能：> 2M ops/sec（快速路径优化）
  AssertTrue('ResetEvent fast path should be > 2M ops/sec', OpsPerSec > 2000000);
end;

procedure TTestCase_Event_Performance.Test_FastPath_TryWait_ManualReset;
var
  Event: IEvent;
  OpsPerSec: Double;
begin
  Event := CreateEvent(True, True); // 手动重置事件，初始为信号状态
  
  OpsPerSec := MeasureOperationsPerSecond('TryWait Fast Path (Manual Reset)', 
    procedure
    begin
      Event.TryWait; // 应该使用无锁快速路径
    end);
    
  // 期望性能：> 3M ops/sec（完全无锁）
  AssertTrue('TryWait fast path should be > 3M ops/sec', OpsPerSec > 3000000);
end;

procedure TTestCase_Event_Performance.Test_Performance_WaitForMultiple_Any;
var
  Events: array[0..4] of IEvent;
  i: Integer;
  StartTime, EndTime: Int64;
  Result: TWaitMultipleResult;
  Operations: Integer;
begin
  // 创建5个事件，第3个设置为信号状态
  for i := 0 to High(Events) do
  begin
    Events[i] := CreateEvent(True, i = 2); // 只有索引2的事件是信号状态
  end;
  
  Operations := 0;
  StartTime := GetCurrentTimeMs;
  
  repeat
    Result := WaitForAny(Events, 0); // 非阻塞等待
    Inc(Operations);
    
    if Operations mod 100 = 0 then
    begin
      EndTime := GetCurrentTimeMs;
      if EndTime - StartTime >= 1000 then
        Break;
    end;
  until False;
  
  EndTime := GetCurrentTimeMs;
  LogPerformanceResult('WaitForAny (5 events)', Operations, EndTime - StartTime);
  
  AssertEquals('Should find event at index 2', 2, Result.Index);
  AssertEquals('Should return signaled', Ord(wrSignaled), Ord(Result.Result));
end;

procedure TTestCase_Event_Performance.Test_Performance_WaitForMultiple_All;
var
  Events: array[0..2] of IEvent;
  i: Integer;
  StartTime, EndTime: Int64;
  Result: TWaitResult;
  Operations: Integer;
begin
  // 创建3个事件，全部设置为信号状态
  for i := 0 to High(Events) do
  begin
    Events[i] := CreateEvent(True, True); // 全部为信号状态
  end;
  
  Operations := 0;
  StartTime := GetCurrentTimeMs;
  
  repeat
    Result := WaitForAll(Events, 0); // 非阻塞等待
    Inc(Operations);
    
    if Operations mod 100 = 0 then
    begin
      EndTime := GetCurrentTimeMs;
      if EndTime - StartTime >= 1000 then
        Break;
    end;
  until False;
  
  EndTime := GetCurrentTimeMs;
  LogPerformanceResult('WaitForAll (3 events)', Operations, EndTime - StartTime);
  
  AssertEquals('Should return signaled', Ord(wrSignaled), Ord(Result));
end;

procedure TTestCase_Event_Performance.Test_Performance_ConcurrentSetReset;
var
  Event: IEvent;
  Threads: array[0..3] of TPerformanceThread;
  i: Integer;
  TotalOps: Integer;
  TotalTime: Int64;
begin
  Event := CreateEvent(True, False); // 手动重置事件
  
  // 创建4个线程，2个设置，2个重置
  for i := 0 to 1 do
    Threads[i] := TPerformanceThread.Create(Event, 'set', 10000);
  for i := 2 to 3 do
    Threads[i] := TPerformanceThread.Create(Event, 'reset', 10000);
  
  // 启动所有线程
  for i := 0 to High(Threads) do
    Threads[i].Start;
  
  // 等待所有线程完成
  TotalOps := 0;
  TotalTime := 0;
  for i := 0 to High(Threads) do
  begin
    Threads[i].WaitFor;
    TotalOps := TotalOps + 10000;
    TotalTime := TotalTime + Threads[i].ElapsedMs;
    Threads[i].Free;
  end;
  
  LogPerformanceResult('Concurrent SetEvent/ResetEvent', TotalOps, TotalTime div 4);
end;

procedure TTestCase_Event_Performance.Test_Performance_ConcurrentTryWait;
var
  Event: IEvent;
  Threads: array[0..3] of TPerformanceThread;
  i: Integer;
  TotalOps: Integer;
  TotalTime: Int64;
begin
  Event := CreateEvent(True, True); // 手动重置事件，信号状态
  
  // 创建4个线程，全部执行 TryWait
  for i := 0 to High(Threads) do
    Threads[i] := TPerformanceThread.Create(Event, 'trywait', 50000);
  
  // 启动所有线程
  for i := 0 to High(Threads) do
    Threads[i].Start;
  
  // 等待所有线程完成
  TotalOps := 0;
  TotalTime := 0;
  for i := 0 to High(Threads) do
  begin
    Threads[i].WaitFor;
    TotalOps := TotalOps + 50000;
    TotalTime := TotalTime + Threads[i].ElapsedMs;
    Threads[i].Free;
  end;
  
  LogPerformanceResult('Concurrent TryWait', TotalOps, TotalTime div 4);
end;

procedure TTestCase_Event_Performance.Test_Performance_MemoryUsage;
var
  Events: array[0..999] of IEvent;
  i: Integer;
  StartTime, EndTime: Int64;
begin
  StartTime := GetCurrentTimeMs;
  
  // 创建1000个事件对象
  for i := 0 to High(Events) do
  begin
    Events[i] := CreateEvent(True, False);
  end;
  
  // 执行一些操作
  for i := 0 to High(Events) do
  begin
    Events[i].SetEvent;
    Events[i].IsSignaled;
    Events[i].ResetEvent;
  end;
  
  // 释放所有事件
  for i := 0 to High(Events) do
  begin
    Events[i] := nil;
  end;
  
  EndTime := GetCurrentTimeMs;
  LogPerformanceResult('Memory Usage Test (1000 events)', 3000, EndTime - StartTime);
  
  AssertTrue('Memory test should complete quickly', EndTime - StartTime < 1000);
end;

{ TPerformanceThread }

constructor TPerformanceThread.Create(const AEvent: IEvent; const AOperation: string; AIterations: Integer);
begin
  inherited Create(True);
  FEvent := AEvent;
  FOperation := AOperation;
  FIterations := AIterations;
  FreeOnTerminate := False;
end;

procedure TPerformanceThread.Execute;
var
  i: Integer;
  StartTime, EndTime: Int64;
begin
  StartTime := GetTickCount64;
  
  for i := 1 to FIterations do
  begin
    if FOperation = 'set' then
      FEvent.SetEvent
    else if FOperation = 'reset' then
      FEvent.ResetEvent
    else if FOperation = 'trywait' then
      FEvent.TryWait;
  end;
  
  EndTime := GetTickCount64;
  FElapsedMs := EndTime - StartTime;
end;

initialization
  RegisterTest(TTestCase_Event_Performance);

end.
