unit Test_fafafa_core_time_timer_itimer_ext;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

{*
  ITimer v2.0 扩展功能测试

  验证新增功能：
  1. GetNextDeadline - 获取下次触发时间
  2. GetExecutionCount - 获取执行计数
  3. GetKind - 获取定时器类型
  4. IsFired - 是否已触发
  5. Pause/Resume/IsPaused - 周期定时器暂停/恢复
*}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time, fafafa.core.time.timer;

type
  TTestCase_ITimerExt = class(TTestCase)
  published
    // GetNextDeadline 测试
    procedure Test_GetNextDeadline_ReturnsScheduledTime;
    procedure Test_GetNextDeadline_ZeroAfterFired;
    procedure Test_GetNextDeadline_ZeroAfterCancelled;

    // GetExecutionCount 测试
    procedure Test_GetExecutionCount_ZeroInitially;
    procedure Test_GetExecutionCount_IncrementedAfterFire;
    procedure Test_GetExecutionCount_PeriodicMultipleFires;

    // GetKind 测试
    procedure Test_GetKind_Once;
    procedure Test_GetKind_FixedRate;
    procedure Test_GetKind_FixedDelay;

    // IsFired 测试
    procedure Test_IsFired_FalseInitially;
    procedure Test_IsFired_TrueAfterOnceFire;

    // Pause/Resume 测试
    procedure Test_Pause_PeriodicTimer_Succeeds;
    procedure Test_Pause_OnceTimer_Fails;
    procedure Test_Resume_PausedTimer_Succeeds;
    procedure Test_IsPaused_ReflectsState;
    procedure Test_PausedTimer_DoesNotFire;
  end;

implementation

var
  G_Fired: Integer = 0;

procedure OnFired;
begin
  Inc(G_Fired);
end;

{ GetNextDeadline 测试 }

procedure TTestCase_ITimerExt.Test_GetNextDeadline_ReturnsScheduledTime;
var
  sch: ITimerScheduler;
  tm: ITimer;
  dl: TInstant;
begin
  sch := CreateTimerScheduler;
  try
    tm := sch.ScheduleOnce(TDuration.FromMs(500), @OnFired);
    dl := tm.GetNextDeadline;
    // 应该在当前时间之后约 500ms
    CheckTrue(dl.GreaterThan(NowInstant), 'Deadline should be in the future');
    tm.Cancel;
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_ITimerExt.Test_GetNextDeadline_ZeroAfterFired;
var
  sch: ITimerScheduler;
  tm: ITimer;
  dl: TInstant;
begin
  G_Fired := 0;
  sch := CreateTimerScheduler;
  try
    tm := sch.ScheduleOnce(TDuration.FromMs(10), @OnFired);
    SleepFor(TDuration.FromMs(100));
    CheckEquals(1, G_Fired, 'Timer should have fired');
    dl := tm.GetNextDeadline;
    CheckTrue(dl = TInstant.Zero, 'Deadline should be zero after fired');
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_ITimerExt.Test_GetNextDeadline_ZeroAfterCancelled;
var
  sch: ITimerScheduler;
  tm: ITimer;
  dl: TInstant;
begin
  sch := CreateTimerScheduler;
  try
    tm := sch.ScheduleOnce(TDuration.FromMs(500), @OnFired);
    tm.Cancel;
    dl := tm.GetNextDeadline;
    CheckTrue(dl = TInstant.Zero, 'Deadline should be zero after cancelled');
  finally
    sch.Shutdown;
  end;
end;

{ GetExecutionCount 测试 }

procedure TTestCase_ITimerExt.Test_GetExecutionCount_ZeroInitially;
var
  sch: ITimerScheduler;
  tm: ITimer;
begin
  sch := CreateTimerScheduler;
  try
    tm := sch.ScheduleOnce(TDuration.FromMs(500), @OnFired);
    CheckEquals(0, tm.GetExecutionCount, 'ExecutionCount should be 0 initially');
    tm.Cancel;
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_ITimerExt.Test_GetExecutionCount_IncrementedAfterFire;
var
  sch: ITimerScheduler;
  tm: ITimer;
begin
  G_Fired := 0;
  sch := CreateTimerScheduler;
  try
    tm := sch.ScheduleOnce(TDuration.FromMs(10), @OnFired);
    SleepFor(TDuration.FromMs(100));
    CheckEquals(1, G_Fired, 'Timer should have fired');
    CheckEquals(1, tm.GetExecutionCount, 'ExecutionCount should be 1 after fire');
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_ITimerExt.Test_GetExecutionCount_PeriodicMultipleFires;
var
  sch: ITimerScheduler;
  tm: ITimer;
begin
  G_Fired := 0;
  sch := CreateTimerScheduler;
  try
    tm := sch.ScheduleAtFixedRate(TDuration.FromMs(10), TDuration.FromMs(20), @OnFired);
    SleepFor(TDuration.FromMs(150));
    tm.Cancel;
    // 应该触发了多次
    CheckTrue(tm.GetExecutionCount >= 3, 'ExecutionCount should be >= 3 for periodic timer');
    CheckEquals(QWord(G_Fired), tm.GetExecutionCount, 'ExecutionCount should match G_Fired');
  finally
    sch.Shutdown;
  end;
end;

{ GetKind 测试 }

procedure TTestCase_ITimerExt.Test_GetKind_Once;
var
  sch: ITimerScheduler;
  tm: ITimer;
begin
  sch := CreateTimerScheduler;
  try
    tm := sch.ScheduleOnce(TDuration.FromMs(500), @OnFired);
    CheckTrue(tm.GetKind = tkOnce, 'Kind should be tkOnce');
    tm.Cancel;
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_ITimerExt.Test_GetKind_FixedRate;
var
  sch: ITimerScheduler;
  tm: ITimer;
begin
  sch := CreateTimerScheduler;
  try
    tm := sch.ScheduleAtFixedRate(TDuration.FromMs(100), TDuration.FromMs(50), @OnFired);
    CheckTrue(tm.GetKind = tkFixedRate, 'Kind should be tkFixedRate');
    tm.Cancel;
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_ITimerExt.Test_GetKind_FixedDelay;
var
  sch: ITimerScheduler;
  tm: ITimer;
begin
  sch := CreateTimerScheduler;
  try
    tm := sch.ScheduleWithFixedDelay(TDuration.FromMs(100), TDuration.FromMs(50), @OnFired);
    CheckTrue(tm.GetKind = tkFixedDelay, 'Kind should be tkFixedDelay');
    tm.Cancel;
  finally
    sch.Shutdown;
  end;
end;

{ IsFired 测试 }

procedure TTestCase_ITimerExt.Test_IsFired_FalseInitially;
var
  sch: ITimerScheduler;
  tm: ITimer;
begin
  sch := CreateTimerScheduler;
  try
    tm := sch.ScheduleOnce(TDuration.FromMs(500), @OnFired);
    CheckFalse(tm.IsFired, 'IsFired should be false initially');
    tm.Cancel;
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_ITimerExt.Test_IsFired_TrueAfterOnceFire;
var
  sch: ITimerScheduler;
  tm: ITimer;
begin
  G_Fired := 0;
  sch := CreateTimerScheduler;
  try
    tm := sch.ScheduleOnce(TDuration.FromMs(10), @OnFired);
    SleepFor(TDuration.FromMs(100));
    CheckEquals(1, G_Fired, 'Timer should have fired');
    CheckTrue(tm.IsFired, 'IsFired should be true after fire');
  finally
    sch.Shutdown;
  end;
end;

{ Pause/Resume 测试 }

procedure TTestCase_ITimerExt.Test_Pause_PeriodicTimer_Succeeds;
var
  sch: ITimerScheduler;
  tm: ITimer;
  ok: Boolean;
begin
  sch := CreateTimerScheduler;
  try
    tm := sch.ScheduleAtFixedRate(TDuration.FromMs(100), TDuration.FromMs(50), @OnFired);
    ok := tm.Pause;
    CheckTrue(ok, 'Pause should succeed for periodic timer');
    tm.Cancel;
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_ITimerExt.Test_Pause_OnceTimer_Fails;
var
  sch: ITimerScheduler;
  tm: ITimer;
  ok: Boolean;
begin
  sch := CreateTimerScheduler;
  try
    tm := sch.ScheduleOnce(TDuration.FromMs(500), @OnFired);
    ok := tm.Pause;
    CheckFalse(ok, 'Pause should fail for once timer');
    tm.Cancel;
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_ITimerExt.Test_Resume_PausedTimer_Succeeds;
var
  sch: ITimerScheduler;
  tm: ITimer;
  ok: Boolean;
begin
  sch := CreateTimerScheduler;
  try
    tm := sch.ScheduleAtFixedRate(TDuration.FromMs(100), TDuration.FromMs(50), @OnFired);
    tm.Pause;
    ok := tm.Resume;
    CheckTrue(ok, 'Resume should succeed for paused timer');
    tm.Cancel;
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_ITimerExt.Test_IsPaused_ReflectsState;
var
  sch: ITimerScheduler;
  tm: ITimer;
begin
  sch := CreateTimerScheduler;
  try
    tm := sch.ScheduleAtFixedRate(TDuration.FromMs(100), TDuration.FromMs(50), @OnFired);
    CheckFalse(tm.IsPaused, 'IsPaused should be false initially');
    tm.Pause;
    CheckTrue(tm.IsPaused, 'IsPaused should be true after pause');
    tm.Resume;
    CheckFalse(tm.IsPaused, 'IsPaused should be false after resume');
    tm.Cancel;
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_ITimerExt.Test_PausedTimer_DoesNotFire;
var
  sch: ITimerScheduler;
  tm: ITimer;
begin
  G_Fired := 0;
  sch := CreateTimerScheduler;
  try
    // 创建一个快速触发的周期定时器
    tm := sch.ScheduleAtFixedRate(TDuration.FromMs(10), TDuration.FromMs(20), @OnFired);

    // 等待一些触发
    SleepFor(TDuration.FromMs(80));
    CheckTrue(G_Fired > 0, 'Timer should have fired before pause');

    // 暂停定时器
    tm.Pause;
    G_Fired := 0;

    // 等待足够时间，期间不应触发
    SleepFor(TDuration.FromMs(100));
    CheckEquals(0, G_Fired, 'Paused timer should not fire');

    tm.Cancel;
  finally
    sch.Shutdown;
  end;
end;

initialization
  RegisterTest(TTestCase_ITimerExt);
end.
