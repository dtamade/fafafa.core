program example_timer_periodic;

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
  GT: ITimer = nil;

procedure OnTick;
begin
  Inc(Fired);
  WriteLn('tick at ', NowInstant.AsNsSinceEpoch, ' ns, fired=', Fired);
  if Fired = 5 then
  begin
    WriteLn('done.');
    if GT <> nil then
      GT.Cancel;
  end;
end;

var
  S: ITimerScheduler;
begin
  WriteLn('Example: periodic timer (5 times)');

  S := CreateTimerScheduler;
  // Start after 200ms, then tick every 300ms
  GT := S.ScheduleFixedRate(TDuration.FromMs(200), TDuration.FromMs(300), TimerCallback(@OnTick));

  // Simple wait (demo only)
  SleepFor(TDuration.FromMs(2000));

  if GT <> nil then
    GT.Cancel;
  S.Shutdown;
end.
