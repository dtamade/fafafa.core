unit Test_fafafa_core_time_short_sleep;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time;

type
  TTestCase_ShortSleep = class(TTestCase)
  published
    procedure Test_ShortSleeps_MonotonicGrowth_UltraLowLatency;
  end;

implementation

procedure TTestCase_ShortSleep.Test_ShortSleeps_MonotonicGrowth_UltraLowLatency;
var
  t0, t1: TInstant;
  d0, d1, d2, d3: Int64; // ns
  old: TSleepStrategy;
begin
  old := GetSleepStrategy;
  try
    SetSleepStrategy(UltraLowLatency);
    // 0.5ms, 1ms, 2ms, 5ms
    t0 := NowInstant; SleepFor(TDuration.FromUs(500)); t1 := NowInstant; d0 := t1.Diff(t0).AsNs;
    t0 := NowInstant; SleepFor(TDuration.FromMs(1));   t1 := NowInstant; d1 := t1.Diff(t0).AsNs;
    t0 := NowInstant; SleepFor(TDuration.FromMs(2));   t1 := NowInstant; d2 := t1.Diff(t0).AsNs;
    t0 := NowInstant; SleepFor(TDuration.FromMs(5));   t1 := NowInstant; d3 := t1.Diff(t0).AsNs;

    // 单调性（容错：允许偶发相等）
    CheckTrue(d1 >= d0);
    CheckTrue(d2 >= d1);
    CheckTrue(d3 >= d2);

    // 基本合理性：最大值不超过 50ms（宽松上界，避免平台差异导致脆弱）
    CheckTrue(d3 <= 50 * 1000 * 1000);
  finally
    SetSleepStrategy(old);
  end;
end;

initialization
  RegisterTest(TTestCase_ShortSleep);
end.

