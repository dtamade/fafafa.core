unit Test_fafafa_core_time_parse_timeout_manual;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time;

type
  TTestCase_ParseTimeoutManual = class(TTestCase)
  published
    procedure Test_ParseDuration_GoStyle;
    procedure Test_ParseDuration_Signed;
    procedure Test_TimeoutFor_Expires;
    procedure Test_ManualClock_Advance_TimerOnce;
  end;

implementation

procedure TTestCase_ParseTimeoutManual.Test_ParseDuration_GoStyle;
var d: TDuration;
begin
  CheckTrue(TryParseDuration('150ms', d));
  CheckEquals(150, d.AsMs);
  CheckTrue(TryParseDuration('2s', d));
  CheckEquals(2, d.AsSec);
  CheckTrue(TryParseDuration('1m2s', d));
  CheckEquals(62, d.AsSec);
  CheckTrue(TryParseDuration('3h', d));
  CheckEquals(3*3600, d.AsSec);
  // 微秒与纳秒
  CheckTrue(TryParseDuration('250us', d));
  CheckEquals(250000, d.AsNs);
  CheckTrue(TryParseDuration('100ns', d));
  CheckEquals(100, d.AsNs);
end;

procedure TTestCase_ParseTimeoutManual.Test_ParseDuration_Signed;
var d: TDuration;
begin
  CheckTrue(TryParseDuration('-1s', d));
  CheckEquals(-1000, d.AsMs);
  CheckFalse(TryParseDuration('1x', d));
end;

procedure TTestCase_ParseTimeoutManual.Test_TimeoutFor_Expires;
var ok: Boolean; t0: TInstant; d: TDuration;
begin
  t0 := NowInstant;
  ok := TimeoutFor(TDuration.FromMs(5),
    procedure begin SleepFor(TDuration.FromMs(20)); end);
  // 应该超时返回 False
  CheckFalse(ok);
  d := NowInstant.Diff(t0);
  CheckTrue(d.AsMs >= 4);
end;

procedure TTestCase_ParseTimeoutManual.Test_ManualClock_Advance_TimerOnce;
var clk: IMonotonicClock; sch: ITimerScheduler; fired: Integer = 0; tm: ITimer;
begin
  clk := CreateManualMonotonicClock(TInstant.FromNsSinceEpoch(0));
  sch := CreateTimerScheduler(clk);
  tm := sch.ScheduleOnce(TDuration.FromMs(10),
    procedure begin Inc(fired); end);
  // 手动推进 9ms：不应触发
  (clk as TFixedMonotonicClock).SetNow(TInstant.FromNsSinceEpoch(9*1000*1000));
  // 推进 1ms：应触发一次
  (clk as TFixedMonotonicClock).SetNow(TInstant.FromNsSinceEpoch(10*1000*1000));
  // 调度线程需要机会运行：睡一个极短真实时间
  Sleep(1);
  CheckEquals(1, fired);
  sch.Shutdown;
end;

initialization
  RegisterTest(TTestCase_ParseTimeoutManual);
end.

