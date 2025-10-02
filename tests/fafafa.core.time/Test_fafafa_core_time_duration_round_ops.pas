unit Test_fafafa_core_time_duration_round_ops;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time, fafafa.core.time.consts;

type
  TTestCase_DurationRoundOps = class(TTestCase)
  published
    procedure Test_Round_Trunc_Floor_Ceil;
    procedure Test_Clamp_Between;
    procedure Test_Operator_Add_Sub_Mul;
  end;

implementation

procedure TTestCase_DurationRoundOps.Test_Round_Trunc_Floor_Ceil;
var d: TDuration;
begin
  d := TDuration.FromNs(1499);
  CheckEquals(1000, d.TruncToUs.AsNs);
  CheckEquals(2000, d.CeilToUs.AsNs);
  CheckEquals(1000, d.FloorToUs.AsNs);
  CheckEquals(1000, d.RoundToUs.AsNs);

  d := TDuration.FromNs(1500);
  CheckEquals(2000, d.RoundToUs.AsNs);

  d := TDuration.FromNs(-1499);
  CheckEquals(-1000, d.TruncToUs.AsNs); // towards zero
  CheckEquals(-2000, d.FloorToUs.AsNs);
  CheckEquals(-1000, d.CeilToUs.AsNs);
  CheckEquals(-1000, d.RoundToUs.AsNs);
end;

procedure TTestCase_DurationRoundOps.Test_Clamp_Between;
var d, mn, mx: TDuration;
begin
  mn := TDuration.FromMs(10);
  mx := TDuration.FromMs(12);
  
  // 测试值大于最大值
  d := TDuration.FromMs(15);
  CheckEquals(12, d.Clamp(mn, mx).AsMs, 'Clamp(15, 10, 12) should return 12');
  
  // 测试值小于最小值
  d := TDuration.FromMs(5);
  CheckEquals(10, d.Clamp(mn, mx).AsMs, 'Clamp(5, 10, 12) should return 10');
  
  // 测试值在范围内
  d := TDuration.FromMs(11);
  CheckEquals(11, d.Clamp(mn, mx).AsMs, 'Clamp(11, 10, 12) should return 11');
end;

procedure TTestCase_DurationRoundOps.Test_Operator_Add_Sub_Mul;
var a,b,c: TDuration;
begin
  a := TDuration.FromMs(5);
  b := TDuration.FromMs(7);
  c := a + b;
  CheckEquals(12, c.AsMs);
  c := b - a;
  CheckEquals(2, c.AsMs);
  c := a * 3;
  CheckEquals(15, c.AsMs);
  c := 4 * a;
  CheckEquals(20, c.AsMs);
end;

initialization
  RegisterTest(TTestCase_DurationRoundOps);
end.

