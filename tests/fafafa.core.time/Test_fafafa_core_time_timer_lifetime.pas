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
    procedure Test_PeriodicTimer_LocalScopeCleanup_NoCrash;
  end;

implementation

procedure Noop;
begin
end;

var
  GPeriodicTickCount: Integer = 0;

procedure PeriodicNoop;
begin
  Inc(GPeriodicTickCount);
end;

procedure RunPeriodicScopeCase;
var
  LScheduler: ITimerScheduler;
  LTimer: ITimer;
begin
  LScheduler := CreateTimerScheduler;
  SetTimerFixedRateMaxCatchupSteps(0);
  GPeriodicTickCount := 0;

  LTimer := LScheduler.ScheduleAtFixedRate(TDuration.FromMs(5), TDuration.FromMs(10), @PeriodicNoop);
  if LTimer = nil then
    raise Exception.Create('schedule should succeed');

  SleepFor(TDuration.FromMs(65));
  LTimer.Cancel;
  LScheduler.Shutdown;
  // 故意不显式释放 LTimer/LScheduler，验证局部作用域析构顺序下不会崩溃。
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

procedure TTestCase_TimerLifetime.Test_PeriodicTimer_LocalScopeCleanup_NoCrash;
begin
  RunPeriodicScopeCase;
  CheckTrue(True, 'Periodic scope cleanup should complete without AV');
end;

initialization
  RegisterTest(TTestCase_TimerLifetime);
end.
