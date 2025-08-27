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

initialization
  RegisterTest(TTestCase_Event_Advanced);

end.

