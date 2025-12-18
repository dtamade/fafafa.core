unit fafafa.core.color.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.math,
  fafafa.core.color;

type
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_color_rgb_and_hex;
    procedure Test_hex_parse_variants;
    procedure Test_srgb_linear_roundtrip;
    procedure Test_hsv_hsl_roundtrip_basic;
    procedure Test_xterm256_mapping_bounds;
    procedure Test_ansi16_mapping_basic;
  end;

implementation

procedure TTestCase_Global.Test_color_rgb_and_hex;
var c: color_rgba_t;
begin
  c := color_rgb(255,128,64);
  AssertEquals(255, c.r);
  AssertEquals(128, c.g);
  AssertEquals(64,  c.b);
  AssertEquals(255, c.a);
  AssertEquals('#ff8040', LowerCase(color_to_hex(c)));
end;

procedure TTestCase_Global.Test_hex_parse_variants;
var c: color_rgba_t;
begin
  c := color_from_hex('#FF00AA');
  AssertEquals(255, c.r);
  AssertEquals(0,   c.g);
  AssertEquals(170, c.b);
  c := color_from_hex('00ff00');
  AssertEquals(0,   c.r);
  AssertEquals(255, c.g);
  AssertEquals(0,   c.b);
end;

procedure TTestCase_Global.Test_srgb_linear_roundtrip;
var i: Integer; u: UInt8; x: Single; u2: UInt8; diff: Integer;
begin
  for i := 0 to 255 do begin
    u := i;
    x := srgb_u8_to_linear(u);
    u2 := linear_to_srgb_u8(x);
    diff := Abs(Integer(u2) - Integer(u));
    AssertTrue('roundtrip diff <= 1', diff <= 1);
  end;
end;

procedure TTestCase_Global.Test_hsv_hsl_roundtrip_basic;
var c: color_rgba_t; h: color_hue_t; s,v,l: color_percent_t;
begin
  c := color_from_hsv(0, 100, 100); // red
  color_to_hsv(c, h, s, v);
  AssertTrue((h <= 5) or (h >= 355));
  AssertTrue(s >= 90);
  AssertTrue(v >= 90);

  c := color_from_hsl(120, 100, 50); // green center
  color_to_hsl(c, h, s, l);
  AssertTrue((h >= 115) and (h <= 125));
  AssertTrue(s >= 90);
  AssertTrue((l >= 48) and (l <= 52));
end;

procedure TTestCase_Global.Test_xterm256_mapping_bounds;
var idx: Byte;
begin
  idx := color_rgb_to_xterm256(0,0,0);
  AssertTrue((idx = 16) or (idx = 232));
  idx := color_rgb_to_xterm256(255,255,255);
  AssertTrue((idx = 231) or (idx >= 232));
end;

procedure TTestCase_Global.Test_ansi16_mapping_basic;
var idx: Byte;
begin
  idx := color_rgb_to_ansi16(255,0,0);
  AssertTrue((idx = 1) or (idx = 9));
  idx := color_rgb_to_ansi16(0,255,0);
  AssertTrue((idx = 2) or (idx = 10));
  idx := color_rgb_to_ansi16(0,0,255);
  AssertTrue((idx = 4) or (idx = 12));
end;

initialization
  RegisterTest(TTestCase_Global);

end.

