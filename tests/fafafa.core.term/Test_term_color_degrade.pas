{$CODEPAGE UTF8}
unit Test_term_color_degrade;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTestCase_ColorDegrade = class(TTestCase)
  published
    procedure Test_RGB_To_256_Cube_Bounds;
    procedure Test_RGB_To_256_Gray_Ramp;
    procedure Test_RGB_To_16_Basic;
  end;

implementation

procedure TTestCase_ColorDegrade.Test_RGB_To_256_Cube_Bounds;
var
  c: term_color_256_t;
begin
  c := term_rgb_to_256(0,0,0);
  CheckTrue((Ord(c) = 16) or (Ord(c) = 232), 'black -> base(16) or grayscale(232)');
  c := term_rgb_to_256(255,255,255);
  CheckTrue((Ord(c) = 231) or (Ord(c) >= 232), 'white -> cube(231) or grayscale band');
end;

procedure TTestCase_ColorDegrade.Test_RGB_To_256_Gray_Ramp;
var
  c1, c2: term_color_256_t;
begin
  c1 := term_rgb_to_256(120,120,120);
  c2 := term_rgb_to_256(130,130,130);
  CheckTrue(Ord(c2) >= Ord(c1), 'monotonic gray approx');
  CheckTrue(Ord(c1) >= 232, 'gray in grayscale band');
end;

procedure TTestCase_ColorDegrade.Test_RGB_To_16_Basic;
var
  c: term_color_16_t;
begin
  c := term_rgb_to_16(255,0,0);
  CheckEquals(9, Ord(c), 'red bright -> 9');
  c := term_rgb_to_16(0,255,0);
  CheckEquals(10, Ord(c), 'green bright -> 10');
  c := term_rgb_to_16(0,0,255);
  CheckEquals(12, Ord(c), 'blue bright -> 12');
end;

initialization
  RegisterTest(TTestCase_ColorDegrade);
end.

