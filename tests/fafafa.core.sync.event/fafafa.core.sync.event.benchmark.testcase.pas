unit fafafa.core.sync.event.benchmark.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.event, fafafa.core.sync.base;

type
  { 性能基准测试和压力测试 }
  TTestCase_Event_Benchmark = class(TTestCase)
  private
    function GetCurrentTimeMs: Int64;
    procedure LogPerformanceResult(const TestName: string; Operations: Integer; ElapsedMs: Int64);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 基础性能基准测试
    procedure Test_Benchmark_BasicOperations;
    procedure Test_Benchmark_SetResetCycle;
    procedure Test_Benchmark_WaitTimeout;
    
    // 并发性能测试
    procedure Test_Benchmark_ConcurrentWaiters;
    procedure Test_Benchmark_ProducerConsumer;
    procedure Test_Benchmark_HighFrequencySignaling;
    
    // 压力测试
    procedure Test_Stress_LongRunning;
    procedure Test_Stress_MassiveConcurrency;
    procedure Test_Stress_ResourceChurn;
    
    // 内存压力测试
    procedure Test_Stress_MemoryUsage;
    procedure Test_Stress_CreateDestroy;
    
    // 平台特定性能测试
    {$IFDEF WINDOWS}
    procedure Test_Benchmark_Windows_Specific;
    {$ENDIF}
    
    {$IFDEF UNIX}
    procedure Test_Benchmark_Unix_Specific;
    {$ENDIF}
  end;

implementation

{ TTestCase_Event_Benchmark }

function TTestCase_Event_Benchmark.GetCurrentTimeMs: Int64;
begin
  Result := GetTickCount64;
end;

procedure TTestCase_Event_Benchmark.LogPerformanceResult(const TestName: string; Operations: Integer; ElapsedMs: Int64);
var
  OpsPerSecond: Double;
begin
  if ElapsedMs > 0 then
    OpsPerSecond := (Operations * 1000.0) / ElapsedMs
  else
    OpsPerSecond := 0;
    
  WriteLn(Format('[BENCHMARK] %s: %d ops in %d ms (%.2f ops/sec)', 
    [TestName, Operations, ElapsedMs, OpsPerSecond]));
end;

procedure TTestCase_Event_Benchmark.SetUp;
begin
  inherited SetUp;
  WriteLn('开始性能基准测试...');
end;

procedure TTestCase_Event_Benchmark.TearDown;
begin
  WriteLn('性能基准测试完成。');
  inherited TearDown;
end;

procedure TTestCase_Event_Benchmark.Test_Benchmark_BasicOperations;
const
  ITERATIONS = 10000;
var
  Event: IEvent;
  StartTime, EndTime: Int64;
  i: Integer;
begin
  Event := CreateEvent(False, False);
  
  // 测试 SetEvent 性能
  StartTime := GetCurrentTimeMs;
  for i := 1 to ITERATIONS do
  begin
    Event.SetEvent;
  end;
  EndTime := GetCurrentTimeMs;
  LogPerformanceResult('SetEvent', ITERATIONS, EndTime - StartTime);
  
  // 测试 ResetEvent 性能（手动重置事件）
  Event := CreateEvent(True, True);
  StartTime := GetCurrentTimeMs;
  for i := 1 to ITERATIONS do
  begin
    Event.ResetEvent;
    Event.SetEvent;
  end;
  EndTime := GetCurrentTimeMs;
  LogPerformanceResult('ResetEvent', ITERATIONS, EndTime - StartTime);
  
  // 测试 IsSignaled 性能
  StartTime := GetCurrentTimeMs;
  for i := 1 to ITERATIONS do
  begin
    Event.IsSignaled;
  end;
  EndTime := GetCurrentTimeMs;
  LogPerformanceResult('IsSignaled', ITERATIONS, EndTime - StartTime);
end;

procedure TTestCase_Event_Benchmark.Test_Benchmark_SetResetCycle;
const
  CYCLES = 5000;
var
  Event: IEvent;
  StartTime, EndTime: Int64;
  i: Integer;
begin
  Event := CreateEvent(True, False); // 手动重置事件
  
  StartTime := GetCurrentTimeMs;
  for i := 1 to CYCLES do
  begin
    Event.SetEvent;
    Event.ResetEvent;
  end;
  EndTime := GetCurrentTimeMs;
  
  LogPerformanceResult('SetEvent+ResetEvent Cycle', CYCLES, EndTime - StartTime);
end;

procedure TTestCase_Event_Benchmark.Test_Benchmark_WaitTimeout;
const
  ITERATIONS = 1000;
var
  Event: IEvent;
  StartTime, EndTime: Int64;
  i: Integer;
begin
  Event := CreateEvent(False, False);
  
  // 测试零超时等待性能
  StartTime := GetCurrentTimeMs;
  for i := 1 to ITERATIONS do
  begin
    Event.WaitFor(0);
  end;
  EndTime := GetCurrentTimeMs;
  LogPerformanceResult('WaitFor(0)', ITERATIONS, EndTime - StartTime);
  
  // 测试短超时等待性能
  StartTime := GetCurrentTimeMs;
  for i := 1 to ITERATIONS do
  begin
    Event.WaitFor(1);
  end;
  EndTime := GetCurrentTimeMs;
  LogPerformanceResult('WaitFor(1ms)', ITERATIONS, EndTime - StartTime);
end;

procedure TTestCase_Event_Benchmark.Test_Benchmark_ConcurrentWaiters;
const
  THREAD_COUNT = 4;
  ITERATIONS_PER_THREAD = 1000;
var
  Event: IEvent;
  Threads: array[0..THREAD_COUNT-1] of TThread;
  StartTime, EndTime: Int64;
  i: Integer;
  TotalOperations: Integer;
begin
  Event := CreateEvent(True, False); // 手动重置事件
  TotalOperations := THREAD_COUNT * ITERATIONS_PER_THREAD;
  
  // 创建等待线程
  for i := 0 to THREAD_COUNT - 1 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      var
        j: Integer;
      begin
        for j := 1 to ITERATIONS_PER_THREAD do
        begin
          Event.WaitFor(10); // 短超时等待
        end;
      end);
  end;
  
  StartTime := GetCurrentTimeMs;
  
  // 启动所有线程
  for i := 0 to THREAD_COUNT - 1 do
    Threads[i].Start;
  
  // 定期触发事件
  Sleep(10);
  Event.SetEvent;
  Sleep(50);
  Event.ResetEvent;
  Sleep(10);
  Event.SetEvent;
  
  // 等待所有线程完成
  for i := 0 to THREAD_COUNT - 1 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
  
  EndTime := GetCurrentTimeMs;
  LogPerformanceResult('Concurrent Waiters', TotalOperations, EndTime - StartTime);
end;

procedure TTestCase_Event_Benchmark.Test_Benchmark_ProducerConsumer;
const
  PRODUCER_COUNT = 2;
  CONSUMER_COUNT = 2;
  ITEMS_PER_PRODUCER = 500;
var
  Event: IEvent;
  Producers, Consumers: array of TThread;
  StartTime, EndTime: Int64;
  i: Integer;
  ItemsProduced, ItemsConsumed: Integer;
begin
  Event := CreateEvent(False, False); // 自动重置事件
  ItemsProduced := 0;
  ItemsConsumed := 0;
  
  SetLength(Producers, PRODUCER_COUNT);
  SetLength(Consumers, CONSUMER_COUNT);
  
  // 创建生产者线程
  for i := 0 to PRODUCER_COUNT - 1 do
  begin
    Producers[i] := TThread.CreateAnonymousThread(
      procedure
      var
        j: Integer;
      begin
        for j := 1 to ITEMS_PER_PRODUCER do
        begin
          InterlockedIncrement(ItemsProduced);
          Event.SetEvent; // 通知消费者
          Sleep(1); // 模拟生产时间
        end;
      end);
  end;
  
  // 创建消费者线程
  for i := 0 to CONSUMER_COUNT - 1 do
  begin
    Consumers[i] := TThread.CreateAnonymousThread(
      procedure
      begin
        while ItemsConsumed < PRODUCER_COUNT * ITEMS_PER_PRODUCER do
        begin
          if Event.WaitFor(100) = wrSignaled then
          begin
            InterlockedIncrement(ItemsConsumed);
          end;
        end;
      end);
  end;
  
  StartTime := GetCurrentTimeMs;
  
  // 启动所有线程
  for i := 0 to PRODUCER_COUNT - 1 do
    Producers[i].Start;
  for i := 0 to CONSUMER_COUNT - 1 do
    Consumers[i].Start;
  
  // 等待所有线程完成
  for i := 0 to PRODUCER_COUNT - 1 do
  begin
    Producers[i].WaitFor;
    Producers[i].Free;
  end;
  for i := 0 to CONSUMER_COUNT - 1 do
  begin
    Consumers[i].WaitFor;
    Consumers[i].Free;
  end;
  
  EndTime := GetCurrentTimeMs;
  
  WriteLn(Format('Producer-Consumer: Produced=%d, Consumed=%d', [ItemsProduced, ItemsConsumed]));
  LogPerformanceResult('Producer-Consumer', ItemsProduced + ItemsConsumed, EndTime - StartTime);
  
  AssertEquals('所有项目都应该被消费', PRODUCER_COUNT * ITEMS_PER_PRODUCER, ItemsConsumed);
end;

procedure TTestCase_Event_Benchmark.Test_Benchmark_HighFrequencySignaling;
const
  SIGNAL_COUNT = 10000;
var
  Event: IEvent;
  StartTime, EndTime: Int64;
  i: Integer;
begin
  Event := CreateEvent(False, False); // 自动重置事件
  
  StartTime := GetCurrentTimeMs;
  for i := 1 to SIGNAL_COUNT do
  begin
    Event.SetEvent;
    // 立即尝试等待（应该成功）
    if Event.WaitFor(0) <> wrSignaled then
      Fail('高频信号测试失败');
  end;
  EndTime := GetCurrentTimeMs;
  
  LogPerformanceResult('High Frequency Signaling', SIGNAL_COUNT, EndTime - StartTime);
end;

procedure TTestCase_Event_Benchmark.Test_Stress_LongRunning;
const
  DURATION_SECONDS = 5; // 5秒压力测试
  CHECK_INTERVAL = 100;
var
  Event: IEvent;
  StartTime, CurrentTime: Int64;
  Operations: Integer;
  WorkerThread: TThread;
  ShouldStop: Boolean;
begin
  Event := CreateEvent(True, False); // 手动重置事件
  Operations := 0;
  ShouldStop := False;
  
  // 创建工作线程
  WorkerThread := TThread.CreateAnonymousThread(
    procedure
    begin
      while not ShouldStop do
      begin
        Event.WaitFor(10);
        InterlockedIncrement(Operations);
      end;
    end);
  
  StartTime := GetCurrentTimeMs;
  WorkerThread.Start;
  
  // 主线程定期触发事件
  repeat
    Event.SetEvent;
    Sleep(5);
    Event.ResetEvent;
    Sleep(5);
    CurrentTime := GetCurrentTimeMs;
  until (CurrentTime - StartTime) >= (DURATION_SECONDS * 1000);
  
  ShouldStop := True;
  Event.SetEvent; // 确保工作线程能够退出
  WorkerThread.WaitFor;
  WorkerThread.Free;
  
  LogPerformanceResult('Long Running Stress Test', Operations, CurrentTime - StartTime);
  AssertTrue('长时间运行应该执行大量操作', Operations > 100);
end;

procedure TTestCase_Event_Benchmark.Test_Stress_MassiveConcurrency;
const
  THREAD_COUNT = 20;
  OPERATIONS_PER_THREAD = 100;
var
  Event: IEvent;
  Threads: array of TThread;
  StartTime, EndTime: Int64;
  i: Integer;
  TotalOperations: Integer;
begin
  Event := CreateEvent(True, False); // 手动重置事件
  SetLength(Threads, THREAD_COUNT);
  TotalOperations := 0;
  
  // 创建大量并发线程
  for i := 0 to THREAD_COUNT - 1 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      var
        j: Integer;
        LocalOps: Integer;
      begin
        LocalOps := 0;
        for j := 1 to OPERATIONS_PER_THREAD do
        begin
          Event.WaitFor(Random(20) + 1); // 随机超时
          Inc(LocalOps);
        end;
        InterlockedExchangeAdd(TotalOperations, LocalOps);
      end);
  end;
  
  StartTime := GetCurrentTimeMs;
  
  // 启动所有线程
  for i := 0 to THREAD_COUNT - 1 do
    Threads[i].Start;
  
  // 主线程随机触发事件
  for i := 1 to 50 do
  begin
    Sleep(Random(10) + 1);
    Event.SetEvent;
    Sleep(Random(5) + 1);
    Event.ResetEvent;
  end;
  
  // 等待所有线程完成
  for i := 0 to THREAD_COUNT - 1 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
  
  EndTime := GetCurrentTimeMs;
  
  LogPerformanceResult('Massive Concurrency', TotalOperations, EndTime - StartTime);
  AssertTrue('大规模并发应该完成大部分操作', TotalOperations > THREAD_COUNT * OPERATIONS_PER_THREAD div 2);
end;

procedure TTestCase_Event_Benchmark.Test_Stress_ResourceChurn;
const
  CHURN_CYCLES = 1000;
var
  StartTime, EndTime: Int64;
  i: Integer;
  Event: IEvent;
begin
  StartTime := GetCurrentTimeMs;
  
  // 快速创建和销毁事件
  for i := 1 to CHURN_CYCLES do
  begin
    Event := CreateEvent(i mod 2 = 0, i mod 3 = 0);
    Event.SetEvent;
    Event.WaitFor(0);
    Event := nil; // 释放
  end;
  
  EndTime := GetCurrentTimeMs;
  
  LogPerformanceResult('Resource Churn', CHURN_CYCLES, EndTime - StartTime);
end;

procedure TTestCase_Event_Benchmark.Test_Stress_MemoryUsage;
const
  EVENT_COUNT = 100;
var
  Events: array of IEvent;
  StartTime, EndTime: Int64;
  i: Integer;
begin
  SetLength(Events, EVENT_COUNT);
  
  StartTime := GetCurrentTimeMs;
  
  // 创建大量事件并使用它们
  for i := 0 to EVENT_COUNT - 1 do
  begin
    Events[i] := CreateEvent(i mod 2 = 0, False);
    Events[i].SetEvent;
    Events[i].WaitFor(0);
  end;
  
  // 清理
  for i := 0 to EVENT_COUNT - 1 do
    Events[i] := nil;
  
  EndTime := GetCurrentTimeMs;
  
  LogPerformanceResult('Memory Usage Test', EVENT_COUNT, EndTime - StartTime);
end;

procedure TTestCase_Event_Benchmark.Test_Stress_CreateDestroy;
const
  ITERATIONS = 5000;
var
  StartTime, EndTime: Int64;
  i: Integer;
  Event: IEvent;
begin
  StartTime := GetCurrentTimeMs;
  
  for i := 1 to ITERATIONS do
  begin
    Event := CreateEvent(False, False);
    Event.SetEvent;
    Event := nil;
  end;
  
  EndTime := GetCurrentTimeMs;
  
  LogPerformanceResult('Create-Destroy Cycle', ITERATIONS, EndTime - StartTime);
end;

{$IFDEF WINDOWS}
procedure TTestCase_Event_Benchmark.Test_Benchmark_Windows_Specific;
var
  Event: IEvent;
  StartTime, EndTime: Int64;
  i: Integer;
const
  ITERATIONS = 1000;
begin
  Event := CreateEvent(False, False);
  
  // 测试 Windows 特定的 Pulse 操作性能
  StartTime := GetCurrentTimeMs;
  for i := 1 to ITERATIONS do
  begin
    Event.Pulse;
  end;
  EndTime := GetCurrentTimeMs;
  
  LogPerformanceResult('Windows Pulse Operation', ITERATIONS, EndTime - StartTime);
end;
{$ENDIF}

{$IFDEF UNIX}
procedure TTestCase_Event_Benchmark.Test_Benchmark_Unix_Specific;
var
  Event: IEvent;
  StartTime, EndTime: Int64;
  i: Integer;
const
  ITERATIONS = 1000;
begin
  Event := CreateEvent(False, False);
  
  // 测试 Unix 特定的等待线程计数性能
  StartTime := GetCurrentTimeMs;
  for i := 1 to ITERATIONS do
  begin
    Event.GetWaitingThreadCount;
  end;
  EndTime := GetCurrentTimeMs;
  
  LogPerformanceResult('Unix GetWaitingThreadCount', ITERATIONS, EndTime - StartTime);
end;
{$ENDIF}

initialization
  RegisterTest(TTestCase_Event_Benchmark);

end.
