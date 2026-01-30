program example_timer_quickstart;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.time;

var
  Fired: Integer = 0;

procedure OnTick;
begin
  Inc(Fired);
end;

var
  Sch: ITimerScheduler;
  Tm: ITimer;
  R: TTimerResult;
  Err: TTimeErrorKind;
begin
  WriteLn('=== fafafa.core.time timer quickstart ===');

  // 1) Explicit scheduler lifecycle
  Sch := CreateTimerScheduler;
  try
    Tm := Sch.ScheduleOnce(TDuration.FromMs(10), @OnTick);
    if Tm = nil then
      WriteLn('ScheduleOnce: nil (unexpected)')
    else
      WriteLn('ScheduleOnce: ok');

    SleepFor(TDuration.FromMs(50));
    if Tm <> nil then
      Tm.Cancel;
  finally
    Sch.Shutdown;
  end;

  // 2) Result-style facade helper (uses default scheduler)
  R := TryScheduleFixedRate(TDuration.Zero, TDuration.Zero, @OnTick);
  if R.TryUnwrapErr(Err) then
    WriteLn('TryScheduleFixedRate invalid period -> err_kind=', Ord(Err));

  WriteLn('Fired=', Fired);
end.
