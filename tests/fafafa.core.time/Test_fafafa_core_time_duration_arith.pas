unit Test_fafafa_core_time_duration_arith;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time;

type
  TTestCase_DurationArith = class(TTestCase)
  published
    procedure Test_Mul_Div_Mod_Basic;
    procedure Test_CheckedMulDivMod;
    procedure Test_SaturatingMulDiv;
  end;

implementation

procedure TTestCase_DurationArith.Test_Mul_Div_Mod_Basic;
var d, r: TDuration;
begin
  d := TDuration.FromMs(10);
  r := d.Mul(3);
  CheckEquals(30, r.AsMs);
  r := d.Divi(4);
  CheckEquals(2, r.AsMs);
  r := TDuration.FromMs(25).Modulo(TDuration.FromMs(10));
  CheckEquals(5, r.AsMs);
end;

procedure TTestCase_DurationArith.Test_CheckedMulDivMod;
var d, r: TDuration; ok: Boolean; zero, two, m: Int64;
begin
  d := TDuration.FromNs(100);
  zero := 0; two := 2; m := 3;
  ok := d.CheckedMul(m, r);  // 正常路径：不会溢出
  CheckTrue(ok);
  ok := d.CheckedDivBy(zero, r);
  CheckFalse(ok);
  ok := d.CheckedDivBy(two, r);
  CheckTrue(ok);
  ok := d.CheckedModulo(TDuration.Zero, r);
  CheckFalse(ok);
  ok := d.CheckedModulo(TDuration.FromNs(7), r);
  CheckTrue(ok);
end;

procedure TTestCase_DurationArith.Test_SaturatingMulDiv;
var d, r: TDuration;
begin
  d := TDuration.FromNs(High(Int64) div 2);
  r := d.SaturatingMul(3);
  CheckTrue(r.AsNs = High(Int64));
  r := TDuration.FromNs(Low(Int64)).SaturatingDiv(-1);
  CheckTrue(r.AsNs = High(Int64));
end;

initialization
  RegisterTest(TTestCase_DurationArith);
end.

