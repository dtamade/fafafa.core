unit Test_fafafa_core_time_ticker;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time, fafafa.core.time.timer;

type
  TTestCase_Ticker = class(TTestCase)
  published
    procedure Test_Ticker_FixedRate_Stop;
    procedure Test_Ticker_FixedDelay_Stop;
  end;

implementation

procedure TTestCase_Ticker.Test_Ticker_FixedRate_Stop;
var sch: ITimerScheduler; tick: ITicker; cnt: Integer = 0;
begin
  sch := CreateTimerScheduler;
  tick := CreateTickerFixedRateOn(sch, TDuration.FromMs(1), TDuration.FromMs(5),
    procedure begin Inc(cnt); end);
  SleepFor(TDuration.FromMs(20));
  tick.Stop;
  CheckTrue(tick.IsStopped);
  // 再等一会，计数不应再大幅增长
  SleepFor(TDuration.FromMs(20));
  CheckTrue(cnt >= 3);
  sch.Shutdown;
end;

procedure TTestCase_Ticker.Test_Ticker_FixedDelay_Stop;
var sch: ITimerScheduler; tick: ITicker; cnt: Integer = 0;
begin
  sch := CreateTimerScheduler;
  tick := CreateTickerFixedDelayOn(sch, TDuration.FromMs(1), TDuration.FromMs(5),
    procedure begin Inc(cnt); end);
  SleepFor(TDuration.FromMs(20));
  tick.Stop;
  CheckTrue(tick.IsStopped);
  SleepFor(TDuration.FromMs(20));
  CheckTrue(cnt >= 3);
  sch.Shutdown;
end;

initialization
  RegisterTest(TTestCase_Ticker);
end.

