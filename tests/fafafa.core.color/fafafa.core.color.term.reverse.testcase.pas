unit fafafa.core.color.term.reverse.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_TermReverse = class(TTestCase)
  published
    procedure Test_Xterm256_Cube_Endpoints;
    procedure Test_Xterm256_GrayBand_Endpoints;
    procedure Test_ANSI16_Basic_And_Bright;
  end;

implementation

procedure TTestCase_TermReverse.Test_Xterm256_Cube_Endpoints;
var idx: Byte; c: color_rgba_t;
begin
  // 16 + 36*r + 6*g + b ; using canonical centers (0,95,135,175,215,255)
  idx := 16 + 36*0 + 6*0 + 0; // black
  c := color_xterm256_to_rgb(idx);
  AssertEquals(0, c.r); AssertEquals(0, c.g); AssertEquals(0, c.b);

  idx := 16 + 36*5 + 6*0 + 0; // red 255
  c := color_xterm256_to_rgb(idx);
  AssertEquals(255, c.r); AssertEquals(0, c.g); AssertEquals(0, c.b);

  idx := 16 + 36*0 + 6*5 + 0; // green 255
  c := color_xterm256_to_rgb(idx);
  AssertEquals(0, c.r); AssertEquals(255, c.g); AssertEquals(0, c.b);

  idx := 16 + 36*0 + 6*0 + 5; // blue 255
  c := color_xterm256_to_rgb(idx);
  AssertEquals(0, c.r); AssertEquals(0, c.g); AssertEquals(255, c.b);

  idx := 16 + 36*5 + 6*5 + 5; // white 255,255,255
  c := color_xterm256_to_rgb(idx);
  AssertEquals(255, c.r); AssertEquals(255, c.g); AssertEquals(255, c.b);
end;

procedure TTestCase_TermReverse.Test_Xterm256_GrayBand_Endpoints;
var idx: Byte; c: color_rgba_t;
begin
  // Gray band: 232..255; our reverse maps to 8 + 10*(i-232)
  idx := 232;
  c := color_xterm256_to_rgb(idx);
  AssertTrue((c.r=c.g) and (c.g=c.b));
  AssertEquals(8, c.r);

  idx := 255;
  c := color_xterm256_to_rgb(idx);
  AssertTrue((c.r=c.g) and (c.g=c.b));
  AssertEquals(8 + (255-232)*10, c.r);
end;

procedure TTestCase_TermReverse.Test_ANSI16_Basic_And_Bright;
var c: color_rgba_t;
begin
  // basic
  c := color_ansi16_to_rgb(0); AssertEquals(0, c.r); AssertEquals(0, c.g); AssertEquals(0, c.b);
  c := color_ansi16_to_rgb(1); AssertTrue(c.r>0); AssertEquals(0, c.g); AssertEquals(0, c.b);
  c := color_ansi16_to_rgb(2); AssertEquals(0, c.r); AssertTrue(c.g>0); AssertEquals(0, c.b);
  c := color_ansi16_to_rgb(4); AssertEquals(0, c.r); AssertEquals(0, c.g); AssertTrue(c.b>0);
  // bright variants
  c := color_ansi16_to_rgb(9); AssertEquals(255, c.r);
  c := color_ansi16_to_rgb(10); AssertEquals(255, c.g);
  c := color_ansi16_to_rgb(12); AssertEquals(255, c.b);
end;

initialization
  RegisterTest(TTestCase_TermReverse);

end.

