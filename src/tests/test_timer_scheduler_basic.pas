unit test_timer_scheduler_basic;

{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.time, fafafa.core.time.timer;

type
  TTimerSchedulerBasicCase = class(TTestCase)
  published
    procedure Test_ScheduleOnce_Basic_Cancel;
    procedure Test_FixedDelay_Basic_Stop;
  end;

procedure RegisterTimerSchedulerBasicTests;

implementation

procedure RegisterTimerSchedulerBasicTests;
begin
  RegisterTest(TTimerSchedulerBasicCase);
end;

procedure TTimerSchedulerBasicCase.Test_ScheduleOnce_Basic_Cancel;
var sch: ITimerScheduler; tm: ITimer; fired: boolean;
begin
  fired := False;
  sch := CreateTimerScheduler;
  tm := sch.ScheduleOnce(TDuration.FromMs(10), procedure begin fired := True; end);
  Sleep(1);
  tm.Cancel;
  Sleep(20);
  AssertFalse('once timer cancelled should not fire', fired);
  sch.Shutdown;
end;

procedure TTimerSchedulerBasicCase.Test_FixedDelay_Basic_Stop;
var sch: ITimerScheduler; ticker: ITicker; count: Integer;
begin
  count := 0;
  sch := CreateTimerScheduler;
  ticker := CreateTickerFixedDelayOn(sch, TDuration.FromMs(1), TDuration.FromMs(5), procedure begin Inc(count); end);
  Sleep(20);
  ticker.Stop;
  // 20ms / 5ms ~ 4 次，考虑调度抖动，至少 2 次
  AssertTrue('fixed delay fired at least twice', count >= 2);
  sch.Shutdown;
end;

end.

