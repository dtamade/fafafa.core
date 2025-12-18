unit fafafa.core.color.palette.strategy.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.math,
  fafafa.core.color;

type
  TTestCase_PaletteStrategy = class(TTestCase)
  published
    procedure Test_Strategy_Even_Sample_Endpoints;
    procedure Test_Strategy_Positions_Serialize_Deserialize;
  end;

implementation

procedure TTestCase_PaletteStrategy.Test_Strategy_Even_Sample_Endpoints;
var S: IPaletteStrategy; arr: array[0..1] of color_rgba_t; c0,c1: color_rgba_t;
begin
  arr[0] := COLOR_RED; arr[1] := COLOR_BLUE;
  S := TPaletteStrategy.CreateEven(PIM_SRGB, arr, True);
  c0 := S.Sample(0.0);
  c1 := S.Sample(1.0);
  AssertEquals(arr[0].r, c0.r);
  AssertEquals(arr[1].b, c1.b);
end;

procedure TTestCase_PaletteStrategy.Test_Strategy_Positions_Serialize_Deserialize;
var S, D: IPaletteStrategy; arr: array[0..2] of color_rgba_t; pos: array[0..2] of Single; t: Single; jsonStr: string; cs, cd: color_rgba_t;
begin
  arr[0] := COLOR_RED; arr[1] := COLOR_GREEN; arr[2] := COLOR_BLUE;
  pos[0] := 10; pos[1] := 20; pos[2] := 70;
  S := TPaletteStrategy.CreateWithPositions(PIM_OKLCH, arr, pos, True, True);
  jsonStr := S.Serialize;
  AssertTrue(palette_strategy_deserialize(jsonStr, D));
  t := 15.0;
  cs := S.Sample(t);
  cd := D.Sample(t);
  AssertTrue(Abs(Integer(cs.r)-Integer(cd.r))<=1);
  AssertTrue(Abs(Integer(cs.g)-Integer(cd.g))<=1);
  AssertTrue(Abs(Integer(cs.b)-Integer(cd.b))<=1);
end;

initialization
  RegisterTest(TTestCase_PaletteStrategy);

end.

