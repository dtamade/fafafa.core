unit fafafa.core.color.palette.strategy.props.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_PaletteStrategyProps = class(TTestCase)
  published
    procedure Test_Serialize_LocaleInvariant_Positions;
    procedure Test_Runtime_Setters_Keep_Endpoints;
  end;

implementation

procedure TTestCase_PaletteStrategyProps.Test_Serialize_LocaleInvariant_Positions;
var S,D: IPaletteStrategy; arr: array[0..1] of color_rgba_t; pos: array[0..1] of Single; jsonStr: string; c1,c2: color_rgba_t;
begin
  arr[0] := COLOR_RED; arr[1] := COLOR_BLUE; pos[0] := 0.1; pos[1] := 1.0;
  S := TPaletteStrategy.CreateWithPositions(PIM_SRGB, arr, pos, True, False);
  // 序列化后强制把小数点替换为逗号，模拟某些区域字符串
  jsonStr := S.Serialize;
  jsonStr := StringReplace(jsonStr, '.', ',', [rfReplaceAll]);
  // 反序列化应能恢复
  AssertTrue(palette_strategy_deserialize(jsonStr, D));
  c1 := S.Sample(0.1);
  c2 := D.Sample(0.1);
  AssertTrue(Abs(Integer(c1.r)-Integer(c2.r))<=1);
end;

procedure TTestCase_PaletteStrategyProps.Test_Runtime_Setters_Keep_Endpoints;
var S: IPaletteStrategy; arr: array[0..2] of color_rgba_t; c0,c1: color_rgba_t;
begin
  arr[0] := COLOR_RED; arr[1] := COLOR_GREEN; arr[2] := COLOR_BLUE;
  S := TPaletteStrategy.CreateEven(PIM_OKLCH, arr, True);
  c0 := S.Sample(0.0); c1 := S.Sample(1.0);
  S.SetMode(PIM_SRGB);
  S.SetShortestHuePath(False);
  S.SetColors(arr);
  S.SetPositions([], False);
  AssertEquals(c0.r, S.Sample(0.0).r);
  AssertEquals(c1.b, S.Sample(1.0).b);
end;

initialization
  RegisterTest(TTestCase_PaletteStrategyProps);

end.

