unit fafafa.core.color.gamma.roundtrip.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fafafa.core.math, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_GammaRoundtrip = class(TTestCase)
  published
    procedure Test_u8_Roundtrip_Approx;
    procedure Test_float_Roundtrip_Approx;
  end;

implementation

procedure TTestCase_GammaRoundtrip.Test_u8_Roundtrip_Approx;
var n: Integer; x: Single; n2: Integer;
begin
  for n := 0 to 255 do begin
    x := srgb_u8_to_linear(n);
    n2 := linear_to_srgb_u8(x);
    AssertTrue(Abs(n2 - n) <= 1);
  end;
end;

procedure TTestCase_GammaRoundtrip.Test_float_Roundtrip_Approx;
var i: Integer; x,y,z: Single;
begin
  for i := 0 to 100 do begin
    x := i / 100.0;
    y := linear_to_srgb(x);
    z := srgb_to_linear(y);
    AssertTrue(Abs(z - x) <= 1e-5);
  end;
end;

initialization
  RegisterTest(TTestCase_GammaRoundtrip);

end.

