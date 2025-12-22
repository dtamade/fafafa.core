unit Test_fafafa_core_time_timer_reset_heap;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

{*
  Timer ResetAt/ResetAfter 堆更新测试

  验证修复：当调用 ResetAt/ResetAfter 修改定时器截止时间时，
  必须正确更新堆排序，确保定时器在正确的时间触发。

  测试用例：
  1. ResetAt 将截止时间提前 -> 定时器更早触发
  2. ResetAt 将截止时间推后 -> 定时器延迟触发
  3. 多定时器场景 -> 堆排序正确，触发顺序正确
  4. ResetAfter 零延迟 -> 几乎立即触发
*}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time, fafafa.core.time.clock, fafafa.core.time.timer;

type
  TTestCase_TimerResetHeap = class(TTestCase)
  published
    procedure Test_ResetAt_EarlierDeadline_TriggersEarly;
    procedure Test_ResetAt_LaterDeadline_DelaysExecution;
    procedure Test_ResetAt_MultipleTimers_HeapOrderCorrect;
    procedure Test_ResetAfter_Zero_TriggersImmediately;
    procedure Test_ResetAt_FromBackToFront_HeapReordered;
    procedure Test_ResetAfter_UsesSchedulerClock;
  end;

implementation

var
  G_Fired: Integer = 0;
  G_Order: string = '';

procedure OnFired; begin Inc(G_Fired); end;
procedure OnOrder1; begin G_Order := G_Order + '1'; end;
procedure OnOrder2; begin G_Order := G_Order + '2'; end;
procedure OnOrder3; begin G_Order := G_Order + '3'; end;
procedure OnOrder0; begin G_Order := G_Order + '0'; end;
procedure OnOrder4; begin G_Order := G_Order + '4'; end;

procedure TTestCase_TimerResetHeap.Test_ResetAt_EarlierDeadline_TriggersEarly;
var
  sch: ITimerScheduler;
  tm: ITimer;
  ok: Boolean;
begin
  G_Fired := 0;
  sch := CreateTimerScheduler;
  try
    // 创建一个 500ms 后触发的定时器
    tm := sch.ScheduleOnce(TDuration.FromMs(500), @OnFired);
    CheckTrue(tm <> nil, 'Timer should be created');

    // 将截止时间提前到 50ms 后
    ok := tm.ResetAfter(TDuration.FromMs(50));
    CheckTrue(ok, 'ResetAfter should succeed');

    // 等待 150ms，此时定时器应该已经触发
    SleepFor(TDuration.FromMs(150));
    CheckEquals(1, G_Fired, 'Timer should have fired after reset to earlier deadline');

    // 再等待 500ms，确认不会再次触发
    SleepFor(TDuration.FromMs(500));
    CheckEquals(1, G_Fired, 'Timer should not fire again');
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_TimerResetHeap.Test_ResetAt_LaterDeadline_DelaysExecution;
var
  sch: ITimerScheduler;
  tm: ITimer;
  ok: Boolean;
begin
  G_Fired := 0;
  sch := CreateTimerScheduler;
  try
    // 创建一个 50ms 后触发的定时器
    tm := sch.ScheduleOnce(TDuration.FromMs(50), @OnFired);
    CheckTrue(tm <> nil, 'Timer should be created');

    // 将截止时间推后到 300ms 后
    ok := tm.ResetAfter(TDuration.FromMs(300));
    CheckTrue(ok, 'ResetAfter should succeed');

    // 等待 150ms，此时定时器不应该触发（原来的 50ms 已过）
    SleepFor(TDuration.FromMs(150));
    CheckEquals(0, G_Fired, 'Timer should not fire yet (deadline was postponed)');

    // 再等待 250ms，此时定时器应该已经触发
    SleepFor(TDuration.FromMs(250));
    CheckEquals(1, G_Fired, 'Timer should have fired after postponed deadline');
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_TimerResetHeap.Test_ResetAt_MultipleTimers_HeapOrderCorrect;
var
  sch: ITimerScheduler;
  tm1, tm2, tm3: ITimer;
begin
  G_Order := '';
  sch := CreateTimerScheduler;
  try
    // 创建三个定时器：100ms, 200ms, 300ms
    tm1 := sch.ScheduleOnce(TDuration.FromMs(100), @OnOrder1);
    tm2 := sch.ScheduleOnce(TDuration.FromMs(200), @OnOrder2);
    tm3 := sch.ScheduleOnce(TDuration.FromMs(300), @OnOrder3);

    // 将 tm3 重置到最早（30ms），tm1 重置到最晚（400ms）
    tm3.ResetAfter(TDuration.FromMs(30));
    tm1.ResetAfter(TDuration.FromMs(400));

    // 等待足够时间让所有定时器触发
    SleepFor(TDuration.FromMs(550));

    // 预期顺序：tm3 (30ms) -> tm2 (200ms) -> tm1 (400ms) = "321"
    CheckEquals('321', G_Order, 'Timers should fire in order: tm3, tm2, tm1');
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_TimerResetHeap.Test_ResetAfter_Zero_TriggersImmediately;
var
  sch: ITimerScheduler;
  tm: ITimer;
  ok: Boolean;
begin
  G_Fired := 0;
  sch := CreateTimerScheduler;
  try
    // 创建一个 1000ms 后触发的定时器
    tm := sch.ScheduleOnce(TDuration.FromMs(1000), @OnFired);
    CheckTrue(tm <> nil, 'Timer should be created');

    // 重置为 0 延迟（应该几乎立即触发）
    ok := tm.ResetAfter(TDuration.Zero);
    CheckTrue(ok, 'ResetAfter(Zero) should succeed');

    // 等待短暂时间让调度线程处理
    SleepFor(TDuration.FromMs(100));
    CheckEquals(1, G_Fired, 'Timer should fire immediately after reset to zero delay');
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_TimerResetHeap.Test_ResetAt_FromBackToFront_HeapReordered;
var
  sch: ITimerScheduler;
  tm0, tm1, tm2, tm3, tm4: ITimer;
begin
  G_Order := '';
  sch := CreateTimerScheduler;
  try
    // 创建 5 个定时器：100ms, 200ms, 300ms, 400ms, 500ms
    tm0 := sch.ScheduleOnce(TDuration.FromMs(100), @OnOrder0);
    tm1 := sch.ScheduleOnce(TDuration.FromMs(200), @OnOrder1);
    tm2 := sch.ScheduleOnce(TDuration.FromMs(300), @OnOrder2);
    tm3 := sch.ScheduleOnce(TDuration.FromMs(400), @OnOrder3);
    tm4 := sch.ScheduleOnce(TDuration.FromMs(500), @OnOrder4);

    // 将最后一个定时器（500ms）重置到最前面（10ms）
    tm4.ResetAfter(TDuration.FromMs(10));

    // 等待所有定时器触发
    SleepFor(TDuration.FromMs(650));

    // 预期顺序：4 (10ms) -> 0 (100ms) -> 1 (200ms) -> 2 (300ms) -> 3 (400ms)
    CheckEquals('40123', G_Order, 'Timer 4 should fire first after reset to front');
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_TimerResetHeap.Test_ResetAfter_UsesSchedulerClock;
var
  clk: IFixedClock;
  sch: ITimerScheduler;
  tm: ITimer;
  expected: TInstant;
  ok: Boolean;
begin
  // 使用可控时钟：调度器必须基于该时钟计算 ResetAfter 的目标时间
  clk := CreateFixedClock(TInstant.FromNsSinceEpoch(123456));
  sch := CreateTimerScheduler(clk);
  try
    tm := sch.ScheduleOnce(TDuration.FromMs(1000), @OnFired);
    CheckTrue(tm <> nil, 'Timer should be created');

    expected := clk.NowInstant.Add(TDuration.FromMs(200));
    ok := tm.ResetAfter(TDuration.FromMs(200));
    CheckTrue(ok, 'ResetAfter should succeed');

    // 如果 ResetAfter 错误地使用 DefaultMonotonicClock，则 deadline 会与 expected 完全不一致
    CheckTrue(tm.GetNextDeadline = expected, 'ResetAfter should use scheduler clock, not default clock');

    tm.Cancel;
  finally
    sch.Shutdown;
  end;
end;

initialization
  RegisterTest(TTestCase_TimerResetHeap);
end.
