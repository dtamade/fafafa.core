unit Test_fafafa_core_time_timer_catchup_limit;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time, fafafa.core.time.timer;

type
  TTestCase_TimerCatchupLimit = class(TTestCase)
  published
    procedure Test_FixedRate_MaxCatchup_Limits_Fires;
  end;

var
  GCountCatch: Integer = 0;

procedure OnTickCatch;

implementation
procedure OnTickCatch; begin Inc(GCountCatch); SleepFor(TDuration.FromMs(12)); end;


procedure TTestCase_TimerCatchupLimit.Test_FixedRate_MaxCatchup_Limits_Fires;
var S: ITimerScheduler; t: ITimer;
begin
  S := CreateTimerScheduler;
  GCountCatch := 0;
  SetTimerFixedRateMaxCatchupSteps(1);
  // 周期 10ms，回调每次 sleep 12ms，会持续落后，但最多追赶 1 次
  t := S.ScheduleAtFixedRate(TDuration.FromMs(0), TDuration.FromMs(10), @OnTickCatch);
  SleepFor(TDuration.FromMs(120));
  t.Cancel;
  // 理想情况下，大量落后但限制追赶为 1，触发次数不会过高（宽松断言）
  CheckTrue(GCountCatch <= 14);
  S.Shutdown;
  SetTimerFixedRateMaxCatchupSteps(0); // 还原默认
end;

initialization
  RegisterTest(TTestCase_TimerCatchupLimit);
end.

