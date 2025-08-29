unit fafafa.core.sync.event.stress.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.event, fafafa.core.sync.base;

type
  { 压力测试和边界测试 }
  TStressWorkerThread = class(TThread)
  private
    FEvent: IEvent;
    FOperations: Integer;
    FSuccessCount: Integer;
    FErrorCount: Integer;
    FMode: Integer; // 0=wait, 1=set, 2=mixed
    FDelay: Integer; // 操作间延迟(ms)
  protected
    procedure Execute; override;
  public
    constructor Create(const AEvent: IEvent; AOperations, AMode: Integer; ADelay: Integer = 0);
    property SuccessCount: Integer read FSuccessCount;
    property ErrorCount: Integer read FErrorCount;
  end;

  TTestCase_Event_Stress = class(TTestCase)
  published
    // 边界值测试
    procedure Test_Boundary_MaxTimeout;
    procedure Test_Boundary_ZeroTimeout_Repeated;
    procedure Test_Boundary_RapidSetReset;

    // 高并发压力测试
    procedure Test_Stress_ManyWaiters_ManualReset;
    procedure Test_Stress_ManyWaiters_AutoReset;
    procedure Test_Stress_ProducerConsumer_HighVolume;

    // 长时间稳定性测试
    procedure Test_Stability_LongRunning;
    procedure Test_Stability_ContinuousOperations;

    // 内存压力测试
    procedure Test_Memory_CreateDestroy_Cycle;
    procedure Test_Memory_ManyEvents_Concurrent;

    // 异常条件测试
    procedure Test_Exception_ThreadTermination;
    procedure Test_Exception_ResourceStress;
  end;

implementation

{ TStressWorkerThread }
constructor TStressWorkerThread.Create(const AEvent: IEvent; AOperations, AMode: Integer; ADelay: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FEvent := AEvent;
  FOperations := AOperations;
  FMode := AMode;
  FDelay := ADelay;
  FSuccessCount := 0;
  FErrorCount := 0;
  Start;
end;

procedure TStressWorkerThread.Execute;
var i: Integer; r: TWaitResult;
begin
  for i := 1 to FOperations do
  begin
    if Terminated then Break;

    try
      case FMode of
        0: begin // wait mode
          r := FEvent.WaitFor(100);
          if r = wrSignaled then
            Inc(FSuccessCount)
          else if r = wrError then
            Inc(FErrorCount);
        end;
        1: begin // set mode
          FEvent.SetEvent;
          Inc(FSuccessCount);
        end;
        2: begin // mixed mode
          if i mod 2 = 0 then
          begin
            FEvent.SetEvent;
            Inc(FSuccessCount);
          end
          else
          begin
            r := FEvent.WaitFor(10);
            if r = wrSignaled then
              Inc(FSuccessCount)
            else if r = wrError then
              Inc(FErrorCount);
          end;
        end;
      end;

      // 可选延迟
      if FDelay > 0 then Sleep(FDelay);

      // 每1000次操作检查一次终止标志
      if (i mod 1000 = 0) and Terminated then Break;

    except
      Inc(FErrorCount);
    end;
    
    // 小延迟避免完全占用CPU
    if i mod 100 = 0 then Sleep(1);
  end;
end;

{ TTestCase_Event_Stress }
procedure TTestCase_Event_Stress.Test_Boundary_MaxTimeout;
var E: IEvent; r: TWaitResult; StartTime: QWord;
begin
  E := fafafa.core.sync.event.CreateEvent(False, False);
  StartTime := GetTickCount64;
  
  // 测试接近最大超时值（但不会真的等那么久）
  r := E.WaitFor(1000); // 1秒超时
  
  AssertEquals('Should timeout', Ord(wrTimeout), Ord(r));
  AssertTrue('Should timeout in reasonable time', GetTickCount64 - StartTime < 1500);
end;

procedure TTestCase_Event_Stress.Test_Boundary_ZeroTimeout_Repeated;
var E: IEvent; i: Integer; r: TWaitResult;
begin
  E := fafafa.core.sync.event.CreateEvent(False, False);

  // 重复零超时测试，验证稳定性
  for i := 1 to 10000 do
  begin
    r := E.WaitFor(0);
    AssertEquals(Format('Iteration %d should timeout', [i]), Ord(wrTimeout), Ord(r));
  end;
end;

procedure TTestCase_Event_Stress.Test_Boundary_RapidSetReset;
var E: IEvent; i: Integer;
begin
  E := fafafa.core.sync.event.CreateEvent(True, False); // manual reset

  // 快速设置/重置循环
  for i := 1 to 10000 do
  begin
    E.SetEvent;
    AssertTrue(Format('Should be signaled after set %d', [i]), E.IsSignaled);
    E.ResetEvent;
    AssertFalse(Format('Should be reset after reset %d', [i]), E.IsSignaled);
  end;
end;

procedure TTestCase_Event_Stress.Test_Stress_ManyWaiters_ManualReset;
const ThreadCount = 64; OpCount = 100;
var
  E: IEvent;
  Threads: array[0..ThreadCount-1] of TStressWorkerThread;
  i, TotalSuccess: Integer;
begin
  E := fafafa.core.sync.event.CreateEvent(True, False); // manual reset

  // 创建大量等待线程
  for i := 0 to ThreadCount-1 do
    Threads[i] := TStressWorkerThread.Create(E, OpCount, 0, 0); // wait mode
  
  Sleep(100); // 让线程进入等待状态
  
  // 触发事件多次
  for i := 1 to 10 do
  begin
    E.SetEvent;
    Sleep(10);
    E.ResetEvent;
    Sleep(10);
  end;
  
  // 最终设置为信号状态
  E.SetEvent;
  
  // 等待所有线程完成并统计
  TotalSuccess := 0;
  for i := 0 to ThreadCount-1 do
  begin
    Threads[i].WaitFor;
    TotalSuccess += Threads[i].SuccessCount;
    Threads[i].Free;
  end;
  
  // 手动重置应该让多个线程成功
  AssertTrue(Format('Should have many successes, got %d', [TotalSuccess]), TotalSuccess > ThreadCount);
end;

procedure TTestCase_Event_Stress.Test_Stress_ManyWaiters_AutoReset;
const ThreadCount = 32; OpCount = 50;
var
  E: IEvent;
  Threads: array[0..ThreadCount-1] of TStressWorkerThread;
  i, TotalSuccess: Integer;
begin
  E := fafafa.core.sync.event.CreateEvent(False, False); // auto reset

  // 创建等待线程
  for i := 0 to ThreadCount-1 do
    Threads[i] := TStressWorkerThread.Create(E, OpCount, 0, 0); // wait mode
  
  Sleep(50);
  
  // 设置事件多次，每次应该只唤醒一个线程
  for i := 1 to ThreadCount * OpCount do
  begin
    E.SetEvent;
    if i mod 100 = 0 then Sleep(1); // 偶尔暂停
  end;
  
  // 等待所有线程完成
  TotalSuccess := 0;
  for i := 0 to ThreadCount-1 do
  begin
    Threads[i].WaitFor;
    TotalSuccess += Threads[i].SuccessCount;
    Threads[i].Free;
  end;
  
  // 自动重置的总成功次数应该接近设置次数
  AssertTrue(Format('Auto-reset success count %d should be reasonable', [TotalSuccess]), 
    TotalSuccess > ThreadCount * OpCount div 2);
end;

procedure TTestCase_Event_Stress.Test_Stress_ProducerConsumer_HighVolume;
const ProducerCount = 4; ConsumerCount = 8; ItemsPerProducer = 1000;
var
  E: IEvent;
  Producers: array[0..ProducerCount-1] of TStressWorkerThread;
  Consumers: array[0..ConsumerCount-1] of TStressWorkerThread;
  i, TotalProduced, TotalConsumed: Integer;
begin
  E := fafafa.core.sync.event.CreateEvent(False, False); // auto reset

  // 创建生产者（设置事件）
  for i := 0 to ProducerCount-1 do
    Producers[i] := TStressWorkerThread.Create(E, ItemsPerProducer, 1, 0); // set mode
  
  // 创建消费者（等待事件）
  for i := 0 to ConsumerCount-1 do
    Consumers[i] := TStressWorkerThread.Create(E, ItemsPerProducer, 0, 0); // wait mode
  
  // 等待所有线程完成
  TotalProduced := 0;
  for i := 0 to ProducerCount-1 do
  begin
    Producers[i].WaitFor;
    TotalProduced += Producers[i].SuccessCount;
    Producers[i].Free;
  end;
  
  TotalConsumed := 0;
  for i := 0 to ConsumerCount-1 do
  begin
    Consumers[i].WaitFor;
    TotalConsumed += Consumers[i].SuccessCount;
    Consumers[i].Free;
  end;
  
  AssertEquals('All items should be produced', ProducerCount * ItemsPerProducer, TotalProduced);
  AssertTrue(Format('Consumed %d should be reasonable vs produced %d', [TotalConsumed, TotalProduced]),
    TotalConsumed > TotalProduced div 2);
end;

procedure TTestCase_Event_Stress.Test_Stability_LongRunning;
const Duration = 2000; // 2 seconds - 缩短测试时间
var
  E: IEvent;
  StartTime: QWord;
  Operations: Integer;
  r: TWaitResult;
begin
  E := fafafa.core.sync.event.CreateEvent(True, False); // 使用手动重置事件
  StartTime := GetTickCount64;
  Operations := 0;

  WriteLn('Starting long-running stability test (2 seconds)...');

  // 长时间运行测试
  while GetTickCount64 - StartTime < Duration do
  begin
    E.SetEvent;
    r := E.WaitFor(1);
    AssertEquals('Should be signaled', Ord(wrSignaled), Ord(r));
    E.ResetEvent; // 手动重置
    Inc(Operations);

    if Operations mod 5000 = 0 then
      WriteLn(Format('Long-running test: %d operations completed', [Operations]));

    // 每1000次操作检查一次时间，避免无限循环
    if Operations mod 1000 = 0 then
      if GetTickCount64 - StartTime >= Duration then Break;
  end;

  WriteLn(Format('Long-running test completed: %d operations in %d ms',
    [Operations, GetTickCount64 - StartTime]));
  AssertTrue(Format('Should complete many operations in %d ms, got %d', [Duration, Operations]),
    Operations > 500);
end;

procedure TTestCase_Event_Stress.Test_Memory_CreateDestroy_Cycle;
const CycleCount = 10000;
var i: Integer; E: IEvent;
begin
  // 大量创建/销毁循环，测试内存管理
  for i := 1 to CycleCount do
  begin
    E := fafafa.core.sync.event.CreateEvent(i mod 2 = 0, i mod 3 = 0);
    E.SetEvent;
    E.WaitFor(0);
    E.ResetEvent;
    E := nil; // 显式释放引用
    
    if i mod 1000 = 0 then
      WriteLn(Format('Memory cycle test: %d/%d completed', [i, CycleCount]));
  end;
end;

procedure TTestCase_Event_Stress.Test_Stability_ContinuousOperations;
const Duration = 3000; // 3 seconds - 缩短测试时间
var
  E: IEvent;
  StartTime: QWord;
  Operations: Integer;
  r: TWaitResult;
  i: Integer;
begin
  E := fafafa.core.sync.event.CreateEvent(True, False); // manual reset
  StartTime := GetTickCount64;
  Operations := 0;

  WriteLn('Starting continuous operations test (3 seconds)...');

  // 连续操作测试 - 混合各种操作
  while GetTickCount64 - StartTime < Duration do
  begin
    // 循环执行各种操作
    for i := 1 to 100 do
    begin
      case i mod 4 of
        0: E.SetEvent;
        1: E.ResetEvent;
        2: begin
          r := E.WaitFor(1);
          // 不检查结果，只要不崩溃即可
        end;
        3: E.IsSignaled;
      end;
      Inc(Operations);
    end;

    if Operations mod 10000 = 0 then
      WriteLn(Format('Continuous operations: %d completed', [Operations]));

    if GetTickCount64 - StartTime > Duration then Break;
  end;

  WriteLn(Format('Continuous operations completed: %d operations in %d ms',
    [Operations, GetTickCount64 - StartTime]));
  AssertTrue('Should complete many operations', Operations > 100000);
end;

procedure TTestCase_Event_Stress.Test_Memory_ManyEvents_Concurrent;
const EventCount = 1000; ThreadCount = 10;
var
  Events: array[0..EventCount-1] of IEvent;
  Threads: array[0..ThreadCount-1] of TStressWorkerThread;
  i: Integer;
begin
  WriteLn('Creating many events concurrently...');

  // 创建大量事件
  for i := 0 to EventCount-1 do
  begin
    Events[i] := fafafa.core.sync.event.CreateEvent(i mod 2 = 0, i mod 3 = 0);
    if i mod 100 = 0 then
      WriteLn(Format('Created %d/%d events', [i+1, EventCount]));
  end;

  // 创建线程操作这些事件
  for i := 0 to ThreadCount-1 do
  begin
    Threads[i] := TStressWorkerThread.Create(Events[i mod EventCount], 1000, 2, 1); // mixed mode
    Threads[i].Start;
  end;

  // 等待线程完成
  for i := 0 to ThreadCount-1 do
  begin
    Threads[i].WaitFor;
    WriteLn(Format('Thread %d: %d successes, %d errors',
      [i, Threads[i].SuccessCount, Threads[i].ErrorCount]));
    Threads[i].Free;
  end;

  // 清理事件
  for i := 0 to EventCount-1 do
    Events[i] := nil;

  WriteLn('Many events concurrent test completed');
end;

procedure TTestCase_Event_Stress.Test_Exception_ThreadTermination;
const ThreadCount = 20;
var
  E: IEvent;
  Threads: array[0..ThreadCount-1] of TStressWorkerThread;
  i: Integer;
begin
  WriteLn('Testing thread termination handling...');

  E := fafafa.core.sync.event.CreateEvent(False, False);

  // 创建线程
  for i := 0 to ThreadCount-1 do
  begin
    Threads[i] := TStressWorkerThread.Create(E, 10000, 0, 1); // wait mode with delay
    Threads[i].Start;
  end;

  Sleep(100); // 让线程开始运行

  // 强制终止一半线程
  for i := 0 to ThreadCount div 2 - 1 do
  begin
    Threads[i].Terminate;
    WriteLn(Format('Terminated thread %d', [i]));
  end;

  // 设置事件唤醒其他线程
  E.SetEvent;

  // 等待所有线程完成
  for i := 0 to ThreadCount-1 do
  begin
    Threads[i].WaitFor;
    WriteLn(Format('Thread %d: %d successes, %d errors',
      [i, Threads[i].SuccessCount, Threads[i].ErrorCount]));
    Threads[i].Free;
  end;

  WriteLn('Thread termination test completed');
end;

procedure TTestCase_Event_Stress.Test_Exception_ResourceStress;
const CycleCount = 5000;
var
  Events: array[0..9] of IEvent;
  i, j: Integer;
  r: TWaitResult;
begin
  WriteLn('Testing resource stress...');

  // 快速创建/销毁/操作循环
  for i := 1 to CycleCount do
  begin
    // 创建多个事件
    for j := 0 to 9 do
      Events[j] := fafafa.core.sync.event.CreateEvent(j mod 2 = 0, j mod 3 = 0);

    // 快速操作
    for j := 0 to 9 do
    begin
      Events[j].SetEvent;
      r := Events[j].WaitFor(0);
      Events[j].ResetEvent;
      Events[j].IsSignaled;
    end;

    // 销毁事件
    for j := 0 to 9 do
      Events[j] := nil;

    if i mod 1000 = 0 then
      WriteLn(Format('Resource stress: %d/%d cycles completed', [i, CycleCount]));
  end;

  WriteLn('Resource stress test completed');
end;

initialization
  RegisterTest(TTestCase_Event_Stress);

end.
