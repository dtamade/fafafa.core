unit Test_fafafa_core_time_timer_lifetime;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time, fafafa.core.time.timer;

type
  TTestCase_TimerLifetime = class(TTestCase)
  published
    procedure Test_TimerHandle_OutlivesScheduler_NoCrash;
  end;

implementation

procedure Noop;
begin
end;

procedure TTestCase_TimerLifetime.Test_TimerHandle_OutlivesScheduler_NoCrash;
var
  S: ITimerScheduler;
  Tm: ITimer;
begin
  S := CreateTimerScheduler;
  Tm := S.ScheduleOnce(TDuration.FromSec(5), @Noop);
  CheckNotNull(Tm, 'schedule should succeed');

  // Release the scheduler first. Releasing the timer afterwards must not crash.
  S.Shutdown;
  S := nil;

  // If scheduler destruction frees timer entries that are still referenced, this will AV.
  Tm := nil;
end;

initialization
  RegisterTest(TTestCase_TimerLifetime);
end.
