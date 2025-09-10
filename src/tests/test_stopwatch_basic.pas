unit test_stopwatch_basic;

{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.time.tick,
  fafafa.core.time.stopwatch;

type
  TStopwatchBasicCase = class(TTestCase)
  published
    procedure Test_Start_Stop_Elapsed;
    procedure Test_WithClock_Injection;
  end;

procedure RegisterStopwatchTests;

implementation

procedure RegisterStopwatchTests;
begin
  RegisterTest(TStopwatchBasicCase);
end;

procedure TStopwatchBasicCase.Test_Start_Stop_Elapsed;
var sw: TStopwatch; d: TDuration;
begin
  sw := TStopwatch.StartNew;
  // 做一点点工作
  Sleep(1);
  sw.Stop;
  d := sw.ElapsedDuration;
  AssertTrue('elapsed should be >= 0.5ms', d.AsMs >= 0.5);
end;

procedure TStopwatchBasicCase.Test_WithClock_Injection;
var clk: TTick; sw: TStopwatch; t0: QWord; d: TDuration;
begin
  clk := BestTick;
  sw := TStopwatch.StartNewWithClock(clk);
  t0 := clk.Now;
  // 小工作
  Sleep(1);
  sw.Stop;
  d := sw.ElapsedDuration;
  // 合理范围：至少 0.5ms
  AssertTrue('injected clock elapsed should be >= 0.5ms', d.AsMs >= 0.5);
  // 一致性：独立测量不小于代码段真实耗时（粗略比较）
  AssertTrue('independent now() elapsed should be <= stopwatch elapsed', clk.TicksToDuration(clk.Elapsed(t0)).AsMs <= d.AsMs + 2.0);
end;

end.

