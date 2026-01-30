unit Test_fafafa_core_time_facade_timer_phase1;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time,
  fafafa.core.thread,
  fafafa.core.thread.cancel;

type
  TFixedMonotonicClock = class(TInterfacedObject, IMonotonicClock)
  private
    FNow: TInstant;
  public
    constructor Create(const ANow: TInstant);

    function NowInstant: TInstant;

    procedure SleepFor(const D: TDuration);
    procedure SleepUntil(const T: TInstant);

    function WaitFor(const D: TDuration; const Token: ICancellationToken): Boolean;
    function WaitUntil(const T: TInstant; const Token: ICancellationToken): Boolean;

    function GetResolution: TDuration;
    function GetName: string;
  end;

  TTestCase_TimeFacadeTimer_Phase1 = class(TTestCase)
  published
    procedure Test_CreateTimerScheduler_Options_UsesClock;
    procedure Test_CreateTimerScheduler_Options_SetsCallbackExecutor;
    procedure Test_TryScheduleFixedRate_InvalidPeriod_ReturnsTekInvalidArgument;
    procedure Test_TryScheduleOnce_AfterShutdown_ReturnsTekShutdown;

    procedure Test_Time_TryScheduleOnce_UsesDefaultScheduler_ReturnsOk;
    procedure Test_Time_TryScheduleFixedRate_InvalidPeriod_ReturnsTekInvalidArgument;

    procedure Test_Time_ScheduleOnce_UsesDefaultScheduler_ReturnsTimer;
    procedure Test_Time_ScheduleFixedRate_InvalidPeriod_ReturnsNil;
    procedure Test_Time_ScheduleFixedDelay_InvalidDelay_ReturnsNil;

    procedure Test_Time_TryScheduleAt_UsesDefaultScheduler_ReturnsOk;
    procedure Test_Time_TryScheduleAtCb_UsesDefaultScheduler_ReturnsOk;
  end;

implementation

{ TFixedMonotonicClock }

constructor TFixedMonotonicClock.Create(const ANow: TInstant);
begin
  inherited Create;
  FNow := ANow;
end;

function TFixedMonotonicClock.NowInstant: TInstant;
begin
  Result := FNow;
end;

procedure TFixedMonotonicClock.SleepFor(const D: TDuration);
begin
  // no-op (test clock)
end;

procedure TFixedMonotonicClock.SleepUntil(const T: TInstant);
begin
  // no-op (test clock)
end;

function TFixedMonotonicClock.WaitFor(const D: TDuration; const Token: ICancellationToken): Boolean;
begin
  // deterministic: return False only if token already cancelled
  Result := (Token = nil) or (not Token.IsCancellationRequested);
end;

function TFixedMonotonicClock.WaitUntil(const T: TInstant; const Token: ICancellationToken): Boolean;
begin
  Result := (Token = nil) or (not Token.IsCancellationRequested);
end;

function TFixedMonotonicClock.GetResolution: TDuration;
begin
  Result := TDuration.FromMs(1);
end;

function TFixedMonotonicClock.GetName: string;
begin
  Result := 'TFixedMonotonicClock(test)';
end;

procedure NoopCallback;
begin
end;

{ TTestCase_TimeFacadeTimer_Phase1 }

procedure TTestCase_TimeFacadeTimer_Phase1.Test_CreateTimerScheduler_Options_UsesClock;
var
  clk: IMonotonicClock;
  opt: TTimerSchedulerOptions;
  sch: ITimerScheduler;
  tm: ITimer;
  expected: TInstant;
begin
  clk := TFixedMonotonicClock.Create(TInstant.FromNsSinceEpoch(42));

  opt := TTimerSchedulerOptions.Default.WithClock(clk);
  sch := CreateTimerScheduler(opt);
  try
    tm := sch.ScheduleOnce(TDuration.Zero, @NoopCallback);
    CheckNotNull(tm, 'timer should be created');

    expected := clk.NowInstant;
    CheckTrue(tm.GetNextDeadline = expected, 'scheduler should use injected clock');

    tm.Cancel;
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_TimeFacadeTimer_Phase1.Test_CreateTimerScheduler_Options_SetsCallbackExecutor;
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

procedure TTestCase_TimeFacadeTimer_Phase1.Test_TryScheduleFixedRate_InvalidPeriod_ReturnsTekInvalidArgument;
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

    CheckFalse(r.TryUnwrap(tmp), 'should not unwrap Ok');
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_TimeFacadeTimer_Phase1.Test_TryScheduleOnce_AfterShutdown_ReturnsTekShutdown;
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

procedure TTestCase_TimeFacadeTimer_Phase1.Test_Time_TryScheduleOnce_UsesDefaultScheduler_ReturnsOk;
var
  r: TTimerResult;
  tm: ITimer;
begin
  r := TryScheduleOnce(TDuration.FromMs(500), @NoopCallback);
  CheckTrue(r.IsOk, 'expected Ok');
  CheckTrue(r.TryUnwrap(tm), 'should unwrap Ok');
  CheckNotNull(tm, 'timer should be returned');
  tm.Cancel;
end;

procedure TTestCase_TimeFacadeTimer_Phase1.Test_Time_TryScheduleFixedRate_InvalidPeriod_ReturnsTekInvalidArgument;
var
  r: TTimerResult;
  err: TTimeErrorKind;
begin
  r := TryScheduleFixedRate(TDuration.Zero, TDuration.Zero, @NoopCallback);
  CheckTrue(r.IsErr, 'expected Err for invalid period');
  CheckTrue(r.TryUnwrapErr(err), 'should unwrap Err');
  CheckEquals(Ord(tekInvalidArgument), Ord(err), 'expected tekInvalidArgument');
end;

procedure TTestCase_TimeFacadeTimer_Phase1.Test_Time_ScheduleOnce_UsesDefaultScheduler_ReturnsTimer;
var
  tm: ITimer;
begin
  tm := ScheduleOnce(TDuration.FromMs(500), @NoopCallback);
  CheckNotNull(tm, 'timer should be created');
  tm.Cancel;
end;

procedure TTestCase_TimeFacadeTimer_Phase1.Test_Time_ScheduleFixedRate_InvalidPeriod_ReturnsNil;
var
  tm: ITimer;
begin
  tm := ScheduleFixedRate(TDuration.Zero, TDuration.Zero, @NoopCallback);
  CheckTrue(tm = nil, 'expected nil for invalid period');
end;

procedure TTestCase_TimeFacadeTimer_Phase1.Test_Time_ScheduleFixedDelay_InvalidDelay_ReturnsNil;
var
  tm: ITimer;
begin
  tm := ScheduleFixedDelay(TDuration.Zero, TDuration.Zero, @NoopCallback);
  CheckTrue(tm = nil, 'expected nil for invalid delay');
end;

procedure TTestCase_TimeFacadeTimer_Phase1.Test_Time_TryScheduleAt_UsesDefaultScheduler_ReturnsOk;
var
  r: TTimerResult;
  tm: ITimer;
begin
  r := TryScheduleAt(NowInstant.Add(TDuration.FromMs(500)), @NoopCallback);
  CheckTrue(r.IsOk, 'expected Ok');
  CheckTrue(r.TryUnwrap(tm), 'should unwrap Ok');
  tm.Cancel;
end;

procedure TTestCase_TimeFacadeTimer_Phase1.Test_Time_TryScheduleAtCb_UsesDefaultScheduler_ReturnsOk;
var
  r: TTimerResult;
  tm: ITimer;
  cb: TTimerCallback;
begin
  cb := TimerCallback(@NoopCallback);
  r := TryScheduleAtCb(NowInstant.Add(TDuration.FromMs(500)), cb);
  CheckTrue(r.IsOk, 'expected Ok');
  CheckTrue(r.TryUnwrap(tm), 'should unwrap Ok');
  tm.Cancel;
end;

initialization
  RegisterTest(TTestCase_TimeFacadeTimer_Phase1);
end.
