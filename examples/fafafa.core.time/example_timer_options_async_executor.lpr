program example_timer_options_async_executor;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.time,
  fafafa.core.thread;

procedure OnWork;
begin
  WriteLn('OnWork executed');
end;

var
  Pool: IThreadPool;
  Opt: TTimerSchedulerOptions;
  Sch: ITimerScheduler;
  Tm: ITimer;
begin
  WriteLn('=== fafafa.core.time timer options + async executor ===');

  Pool := CreateThreadPool(1, 1, 60000, -1, TRejectPolicy.rpAbort);
  try
    Opt := TTimerSchedulerOptions.Default.WithCallbackExecutor(Pool);
    Sch := CreateTimerScheduler(Opt);
    try
      Tm := Sch.ScheduleOnce(TDuration.FromMs(10), @OnWork);
      if Tm = nil then
        WriteLn('ScheduleOnce: nil')
      else
        WriteLn('ScheduleOnce: ok');

      SleepFor(TDuration.FromMs(50));
      if Tm <> nil then
        Tm.Cancel;
    finally
      Sch.Shutdown;
    end;
  finally
    Pool.Shutdown;
    Pool.AwaitTermination(2000);
  end;
end.
