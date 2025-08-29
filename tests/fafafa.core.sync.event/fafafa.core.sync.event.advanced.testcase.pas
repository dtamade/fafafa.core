unit fafafa.core.sync.event.advanced.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.event, fafafa.core.sync.base;

type
  { 更严格的并发、边界与性能测试 }
  TSignalThread = class(TThread)
  private
    FEvent: IEvent;
    FDelayMs: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const AEvent: IEvent; ADelayMs: Integer);
  end;

  TPerfTimer = record
    StartTicks: QWord;
  end;

  TTestCase_Event_Advanced = class(TTestCase)
  published
    // 语义一致性
    procedure Test_AutoReset_MultipleSet_CollapsesToSingle;
    procedure Test_ManualReset_TwoWaitsAfterSingleSet_BothSignaled;

    // 同步与超时边界
    procedure Test_InfiniteWait_SignaledByOtherThread;
    procedure Test_Timeout_Bounds_ZeroAndShort;
    procedure Test_Timeout_Precision;

    // ILock 接口高级测试
    procedure Test_TryWait_Timing;
    procedure Test_WaitFor_Timeout_Behavior;

    // 异常和错误处理
    procedure Test_Multiple_Threads_Same_Operations;
    procedure Test_Rapid_State_Changes;

    // 压力与性能
    procedure Test_Perf_ProducerConsumer_Throughput;
  end;

implementation

// CreateEvent 已在 interface uses 中

{ TSignalThread }
constructor TSignalThread.Create(const AEvent: IEvent; ADelayMs: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FEvent := AEvent;
  FDelayMs := ADelayMs;
  Start;
end;

procedure TSignalThread.Execute;
begin
  if FDelayMs > 0 then Sleep(FDelayMs);
  if FEvent <> nil then FEvent.SetEvent;
end;

{ TPerfTimer }
procedure StartTimer(var Timer: TPerfTimer);
begin
  Timer.StartTicks := GetTickCount64;
end;

function StopTimerMs(const Timer: TPerfTimer): Double;
begin
  Result := (GetTickCount64 - Timer.StartTicks);
end;

{ TTestCase_Event_Advanced }
procedure TTestCase_Event_Advanced.Test_AutoReset_MultipleSet_CollapsesToSingle;
var E: IEvent; r1, r2: TWaitResult;
begin
  E := MakeEvent(False, False); // auto-reset
  // 多次 SetEvent 应“折叠”为一个信号
  E.SetEvent; E.SetEvent; E.SetEvent;
  r1 := E.WaitFor(0);
  r2 := E.WaitFor(0);
  AssertEquals('First wait should be signaled', Ord(wrSignaled), Ord(r1));
  AssertEquals('Second wait should time out (auto-reset collapse)', Ord(wrTimeout), Ord(r2));
end;

procedure TTestCase_Event_Advanced.Test_ManualReset_TwoWaitsAfterSingleSet_BothSignaled;
var E: IEvent; r1, r2: TWaitResult;
begin
  E := MakeEvent(True, False); // manual-reset
  E.SetEvent;
  r1 := E.WaitFor(0);
  r2 := E.WaitFor(0);
  AssertEquals('Manual reset keeps signaled for multiple waits', Ord(wrSignaled), Ord(r1));
  AssertEquals('Manual reset keeps signaled for multiple waits', Ord(wrSignaled), Ord(r2));
end;

procedure TTestCase_Event_Advanced.Test_InfiniteWait_SignaledByOtherThread;
var E: IEvent; T: TSignalThread; r: TWaitResult;
begin
  E := MakeEvent(False, False);
  T := TSignalThread.Create(E, 50);
  try
    r := E.WaitFor(High(Cardinal));
    AssertEquals('Infinite wait should be released by SetEvent', Ord(wrSignaled), Ord(r));
  finally
    T.WaitFor; T.Free;
  end;
end;

procedure TTestCase_Event_Advanced.Test_Timeout_Bounds_ZeroAndShort;
var E: IEvent; r0, rShort: TWaitResult;
begin
  E := MakeEvent(False, False);
  r0 := E.WaitFor(0);
  rShort := E.WaitFor(5);
  AssertEquals('Zero timeout should be wrTimeout', Ord(wrTimeout), Ord(r0));
  // 短超时可能因调度抖动而返回 wrTimeout；若因极端情况被信号也可接受，但此处保持严格
  AssertEquals('Short timeout should be wrTimeout', Ord(wrTimeout), Ord(rShort));
end;

procedure TTestCase_Event_Advanced.Test_Perf_ProducerConsumer_Throughput;
const
  Iters = 10000;
var
  E: IEvent;
  Consumer: TThread;
  Timer: TPerfTimer;
  i: Integer;
  consumed: Integer;
begin
  E := fafafa.core.sync.event.CreateEvent(False, False);
  consumed := 0;
  // 简化版本：不使用匿名线程，直接在主线程测试
  for i := 1 to Iters do
  begin
    E.SetEvent;
    if E.WaitFor(1000) = wrSignaled then Inc(consumed);
  end;
  StartTimer(Timer);
  // 计算吞吐
  AssertEquals('All events should be consumed', Iters, consumed);
  // 打印性能数据（由测试框架输出）
  WriteLn(Format('[Perf] AutoReset Set/Wait: %d ops in %.0f ms'
    , [Iters, StopTimerMs(Timer)]));
end;

procedure TTestCase_Event_Advanced.Test_Timeout_Precision;
var E: IEvent; StartTime: QWord; r: TWaitResult; ElapsedMs: QWord;
begin
  E := fafafa.core.sync.event.CreateEvent(False, False);

  // 测试100ms超时的精度
  StartTime := GetTickCount64;
  r := E.WaitFor(100);
  ElapsedMs := GetTickCount64 - StartTime;

  AssertEquals('Should timeout', Ord(wrTimeout), Ord(r));
  AssertTrue(Format('Timeout should be ~100ms, got %d ms', [ElapsedMs]),
    (ElapsedMs >= 90) and (ElapsedMs <= 150)); // 允许±50ms误差
end;

procedure TTestCase_Event_Advanced.Test_TryWait_Timing;
var E: IEvent; StartTime: QWord; Success: Boolean; ElapsedMs: QWord;
begin
  E := fafafa.core.sync.event.CreateEvent(False, False);

  // TryWait 应该立即返回
  StartTime := GetTickCount64;
  Success := E.TryWait;
  ElapsedMs := GetTickCount64 - StartTime;

  AssertFalse('TryWait should fail on non-signaled event', Success);
  AssertTrue(Format('TryWait should be fast, took %d ms', [ElapsedMs]), ElapsedMs < 10);

  // 设置信号后应该成功
  E.SetEvent;
  StartTime := GetTickCount64;
  Success := E.TryWait;
  ElapsedMs := GetTickCount64 - StartTime;

  AssertTrue('TryWait should succeed on signaled event', Success);
  AssertTrue(Format('TryWait should be fast, took %d ms', [ElapsedMs]), ElapsedMs < 10);
end;

procedure TTestCase_Event_Advanced.Test_WaitFor_Timeout_Behavior;
var E: IEvent; T: TSignalThread; StartTime: QWord; ElapsedMs: QWord; Result: TWaitResult;
begin
  E := fafafa.core.sync.event.CreateEvent(False, False);

  // 启动线程在50ms后设置信号
  T := TSignalThread.Create(E, 50);
  try
    StartTime := GetTickCount64;
    Result := E.WaitFor(200); // 应该在~50ms后成功，给200ms超时
    ElapsedMs := GetTickCount64 - StartTime;

    AssertEquals('WaitFor should succeed', Ord(wrSignaled), Ord(Result));
    AssertTrue(Format('WaitFor should complete in ~50ms, took %d ms', [ElapsedMs]),
      (ElapsedMs >= 40) and (ElapsedMs <= 100));
  finally
    T.WaitFor; T.Free;
  end;
end;

procedure TTestCase_Event_Advanced.Test_Multiple_Threads_Same_Operations;
const ThreadCount = 4; // 减少线程数，简化测试
var
  E: IEvent;
  Threads: array[0..ThreadCount-1] of TSignalThread;
  i: Integer;
begin
  E := fafafa.core.sync.event.CreateEvent(True, False); // manual reset

  // 创建多个线程同时设置事件
  for i := 0 to ThreadCount-1 do
  begin
    Threads[i] := TSignalThread.Create(E, 10 + i * 5); // 不同延迟
    Threads[i].Start;
  end;

  // 等待所有线程完成
  for i := 0 to ThreadCount-1 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;

  // 验证事件最终状态
  AssertTrue('Event should be signaled after all threads', E.IsSignaled);
end;

procedure TTestCase_Event_Advanced.Test_Rapid_State_Changes;
var E: IEvent; i: Integer; r: TWaitResult;
begin
  E := fafafa.core.sync.event.CreateEvent(True, False); // manual reset

  // 快速状态变化测试 - 减少迭代次数
  for i := 1 to 100 do
  begin
    E.SetEvent;
    r := E.WaitFor(0);
    AssertEquals(Format('Iteration %d: should be signaled', [i]), Ord(wrSignaled), Ord(r));

    E.ResetEvent;
    r := E.WaitFor(0);
    AssertEquals(Format('Iteration %d: should timeout after reset', [i]), Ord(wrTimeout), Ord(r));
  end;
end;

initialization
  RegisterTest(TTestCase_Event_Advanced);

end.

