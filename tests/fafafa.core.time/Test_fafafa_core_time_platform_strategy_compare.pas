unit Test_fafafa_core_time_platform_strategy_compare;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time;

type
  TTestCase_PlatformStrategyCompare = class(TTestCase)
  published
    procedure Test_Linux_Darwin_Balanced_vs_ULowLatency;
  end;

implementation

procedure TTestCase_PlatformStrategyCompare.Test_Linux_Darwin_Balanced_vs_ULowLatency;
var
  t0, t1: TInstant;
  dBal, dUL: Int64; // ms
  saved: TSleepStrategy;
begin
  saved := GetSleepStrategy;
  try
    {$IFDEF LINUX}
    SetSleepStrategy(Balanced);
    t0 := NowInstant; SleepFor(TDuration.FromMs(3)); t1 := NowInstant;
    dBal := t1.Diff(t0).AsMs;
    SetSleepStrategy(UltraLowLatency);
    t0 := NowInstant; SleepFor(TDuration.FromMs(3)); t1 := NowInstant;
    dUL := t1.Diff(t0).AsMs;
    // UltraLowLatency 期望不大于 Balanced（宽松）
    CheckTrue(dUL <= dBal + 5);
    // 宽松区间限制防止脆弱
    CheckTrue((dUL >= 1) and (dUL <= 40));
    {$ENDIF}

    {$IFDEF DARWIN}
    SetSleepStrategy(Balanced);
    t0 := NowInstant; SleepFor(TDuration.FromMs(3)); t1 := NowInstant;
    dBal := t1.Diff(t0).AsMs;
    SetSleepStrategy(UltraLowLatency);
    t0 := NowInstant; SleepFor(TDuration.FromMs(3)); t1 := NowInstant;
    dUL := t1.Diff(t0).AsMs;
    CheckTrue(dUL <= dBal + 5);
    CheckTrue((dUL >= 1) and (dUL <= 30));
    {$ENDIF}
  finally
    SetSleepStrategy(saved);
  end;
end;

initialization
  RegisterTest(TTestCase_PlatformStrategyCompare);
end.

