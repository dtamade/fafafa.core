unit Test_fafafa_core_time_timer_instant_reset;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time, fafafa.core.time.timer;

type
  TTestCase_TimerReset = class(TTestCase)
  published
    procedure Test_TimerOnce_ResetBeforeFire;
    procedure Test_TimerOnce_ResetAfterFire_NoEffect;
  end;

implementation

procedure TTestCase_TimerReset.Test_TimerOnce_ResetBeforeFire;
var sch: ITimerScheduler; tm: ITimer; fired: Integer = 0; ok: Boolean;
begin
  sch := CreateTimerScheduler;
  tm := sch.ScheduleOnce(TDuration.FromMs(50), procedure begin Inc(fired); end);
  ok := (tm <> nil) and tm.ResetAfter(TDuration.FromMs(100));
  CheckTrue(ok);
  SleepFor(TDuration.FromMs(60)); // 早于 reset 后的新到期时间
  CheckEquals(0, fired);
  SleepFor(TDuration.FromMs(60)); // 过了 120ms 总时间
  CheckEquals(1, fired);
  sch.Shutdown;
end;

procedure TTestCase_TimerReset.Test_TimerOnce_ResetAfterFire_NoEffect;
var sch: ITimerScheduler; tm: ITimer; fired: Integer = 0; ok: Boolean;
begin
  sch := CreateTimerScheduler;
  tm := sch.ScheduleOnce(TDuration.FromMs(10), procedure begin Inc(fired); end);
  SleepFor(TDuration.FromMs(30));
  CheckEquals(1, fired);
  ok := tm.ResetAfter(TDuration.FromMs(10));
  CheckFalse(ok);
  sch.Shutdown;
end;

initialization
  RegisterTest(TTestCase_TimerReset);
end.

