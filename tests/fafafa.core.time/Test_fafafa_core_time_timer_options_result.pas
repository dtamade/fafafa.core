unit Test_fafafa_core_time_timer_options_result;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time,
  fafafa.core.time.base,
  fafafa.core.time.clock,
  fafafa.core.time.timer,
  fafafa.core.thread;

type
  TTestCase_TimerOptionsAndResult = class(TTestCase)
  published
    procedure Test_CreateTimerScheduler_Options_UsesClock;
    procedure Test_CreateTimerScheduler_Options_SetsCallbackExecutor;
    procedure Test_TryScheduleFixedRate_InvalidPeriod_ReturnsErrInvalidArgument;
    procedure Test_TryScheduleOnce_AfterShutdown_ReturnsErrShutdown;

    procedure Test_TryScheduleAt_AfterShutdown_ReturnsErrShutdown;
    procedure Test_TryScheduleAtCb_AfterShutdown_ReturnsErrShutdown;
  end;

implementation

procedure NoopCallback;
begin
end;

procedure TTestCase_TimerOptionsAndResult.Test_CreateTimerScheduler_Options_UsesClock;
var
  clk: IFixedClock;
  opt: TTimerSchedulerOptions;
  sch: ITimerScheduler;
  tm: ITimer;
  expected: TInstant;
begin
  clk := CreateFixedClock(TInstant.FromNsSinceEpoch(42));

  opt := TTimerSchedulerOptions.Default.WithClock(clk);
  sch := CreateTimerScheduler(opt);
  try
    // 0ms: deadline should be exactly NowInstant from injected clock.
    tm := sch.ScheduleOnce(TDuration.Zero, @NoopCallback);
    CheckNotNull(tm, 'timer should be created');

    expected := clk.NowInstant;
    CheckTrue(tm.GetNextDeadline = expected, 'scheduler should use injected clock');

    tm.Cancel;
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_TimerOptionsAndResult.Test_CreateTimerScheduler_Options_SetsCallbackExecutor;
var
  opt: TTimerSchedulerOptions;
  sch: ITimerScheduler;
  pool: IThreadPool;
begin
  pool := CreateThreadPool(1, 1, 60000, -1, TRejectPolicy.rpAbort);
  try
    opt := TTimerSchedulerOptions.Default.WithCallbackExecutor(pool);
    sch := CreateTimerScheduler(opt);
    try
      CheckTrue(sch.GetCallbackExecutor = pool, 'GetCallbackExecutor should reflect options');
    finally
      sch.Shutdown;
    end;
  finally
    pool.Shutdown;
    pool.AwaitTermination(2000);
  end;
end;

procedure TTestCase_TimerOptionsAndResult.Test_TryScheduleFixedRate_InvalidPeriod_ReturnsErrInvalidArgument;
var
  sch: ITimerScheduler;
  ex: ITimerSchedulerTry;
  r: TTimerResult;
  err: TTimeErrorKind;
  tmp: ITimer;
begin
  sch := CreateTimerScheduler;
  try
    CheckTrue(Supports(sch, ITimerSchedulerTry, ex), 'scheduler should support ITimerSchedulerTry');

    r := ex.TryScheduleFixedRate(TDuration.Zero, TDuration.Zero, @NoopCallback);
    CheckTrue(r.IsErr, 'should be Err for invalid period');
    CheckTrue(r.TryUnwrapErr(err), 'should unwrap Err');
    CheckEquals(Ord(tekInvalidArgument), Ord(err), 'expected tekInvalidArgument');

    // Ensure no timer is produced.
    CheckFalse(r.TryUnwrap(tmp), 'should not unwrap Ok');
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_TimerOptionsAndResult.Test_TryScheduleOnce_AfterShutdown_ReturnsErrShutdown;
var
  sch: ITimerScheduler;
  ex: ITimerSchedulerTry;
  r: TTimerResult;
  err: TTimeErrorKind;
  tmp: ITimer;
begin
  sch := CreateTimerScheduler;
  sch.Shutdown;

  CheckTrue(Supports(sch, ITimerSchedulerTry, ex), 'scheduler should support ITimerSchedulerTry');

  r := ex.TrySchedule(TDuration.Zero, @NoopCallback);
  CheckTrue(r.IsErr, 'should be Err after shutdown');
  CheckTrue(r.TryUnwrapErr(err), 'should unwrap Err');
  CheckEquals(Ord(tekShutdown), Ord(err), 'expected tekShutdown');
  CheckFalse(r.TryUnwrap(tmp), 'should not unwrap Ok');
end;

procedure TTestCase_TimerOptionsAndResult.Test_TryScheduleAt_AfterShutdown_ReturnsErrShutdown;
var
  sch: ITimerScheduler;
  ex: ITimerSchedulerTry;
  r: TTimerResult;
  err: TTimeErrorKind;
begin
  sch := CreateTimerScheduler;
  sch.Shutdown;

  CheckTrue(Supports(sch, ITimerSchedulerTry, ex), 'scheduler should support ITimerSchedulerTry');

  r := ex.TryScheduleAt(TInstant.Zero, @NoopCallback);
  CheckTrue(r.IsErr, 'should be Err after shutdown');
  CheckTrue(r.TryUnwrapErr(err), 'should unwrap Err');
  CheckEquals(Ord(tekShutdown), Ord(err), 'expected tekShutdown');
end;

procedure TTestCase_TimerOptionsAndResult.Test_TryScheduleAtCb_AfterShutdown_ReturnsErrShutdown;
var
  sch: ITimerScheduler;
  ex: ITimerSchedulerTry;
  r: TTimerResult;
  err: TTimeErrorKind;
begin
  sch := CreateTimerScheduler;
  sch.Shutdown;

  CheckTrue(Supports(sch, ITimerSchedulerTry, ex), 'scheduler should support ITimerSchedulerTry');

  r := ex.TryScheduleAtCb(TInstant.Zero, TimerCallback(@NoopCallback));
  CheckTrue(r.IsErr, 'should be Err after shutdown');
  CheckTrue(r.TryUnwrapErr(err), 'should unwrap Err');
  CheckEquals(Ord(tekShutdown), Ord(err), 'expected tekShutdown');
end;

initialization
  RegisterTest(TTestCase_TimerOptionsAndResult);
end.
