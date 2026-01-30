unit Test_fafafa_core_time_timer_once;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time, fafafa.core.time.timer;


type
  TTestCase_TimerOnce = class(TTestCase)
  published
    procedure Test_ScheduleOnce_Basic;
    procedure Test_ScheduleAt_Past_FiresSoon;
    procedure Test_Cancel_Before_Fire;
  end;

implementation

var
  G_Fired: Integer = 0;

procedure OnFired; begin Inc(G_Fired); end;


procedure TTestCase_TimerOnce.Test_ScheduleOnce_Basic;
var S: ITimerScheduler; t: ITimer; t0, t1: TInstant;
begin

  S := CreateTimerScheduler;
  G_Fired := 0;
  t0 := NowInstant;
  t := S.ScheduleOnce(TDuration.FromMs(20), @OnFired);
  SleepFor(TDuration.FromMs(50));
  t1 := NowInstant;
  CheckTrue(G_Fired >= 1);
  CheckTrue(t1.Diff(t0).AsMs >= 15);
  S.Shutdown;
end;

procedure TTestCase_TimerOnce.Test_ScheduleAt_Past_FiresSoon;
var S: ITimerScheduler;
begin
  S := CreateTimerScheduler;
  G_Fired := 0;
  // 设定过去的时间，期望尽快触发
  S.ScheduleAt(NowInstant.Add(TDuration.FromMs(-1)), @OnFired);
  SleepFor(TDuration.FromMs(10));
  CheckTrue(G_Fired >= 1);
  S.Shutdown;
end;

procedure TTestCase_TimerOnce.Test_Cancel_Before_Fire;
var S: ITimerScheduler; t: ITimer;
begin
  S := CreateTimerScheduler;
  G_Fired := 0;
  t := S.ScheduleOnce(TDuration.FromMs(50), @OnFired);
  // 立即取消
  t.Cancel;
  SleepFor(TDuration.FromMs(80));
  CheckEquals(0, G_Fired);
  S.Shutdown;
end;

initialization
  RegisterTest(TTestCase_TimerOnce);
end.

