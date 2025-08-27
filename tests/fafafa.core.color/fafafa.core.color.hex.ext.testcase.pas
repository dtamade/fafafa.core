unit fafafa.core.color.hex.ext.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_HexExt = class(TTestCase)
  published
    procedure Test_RGB_and_RGBA_Short;
    procedure Test_RRGGBBAA_and_0x;
  end;

implementation

procedure TTestCase_HexExt.Test_RGB_and_RGBA_Short;
var c: color_rgba_t; ok: Boolean;
begin
  ok := color_try_from_hex_rgba('#f0a', c);
  AssertTrue(ok);
  AssertEquals(255, c.r);
  AssertEquals(0, c.g);
  AssertEquals(170, c.b);
  AssertEquals(255, c.a);

  ok := color_try_from_hex_rgba('#1a2b', c);
  AssertTrue(ok);
  AssertEquals($11, c.r);
  AssertEquals($aa, c.g);
  AssertEquals($22, c.b);
  AssertEquals($bb, c.a);
end;

procedure TTestCase_HexExt.Test_RRGGBBAA_and_0x;
var c: color_rgba_t; ok: Boolean;
begin
  ok := color_try_from_hex_rgba('#01020304', c);
  AssertTrue(ok);
  AssertEquals(1, c.r);
  AssertEquals(2, c.g);
  AssertEquals(3, c.b);
  AssertEquals(4, c.a);

  ok := color_try_from_hex_rgba('0xFF00AA', c);
  AssertTrue(ok);
  AssertEquals($FF, c.r);
  AssertEquals($00, c.g);
  AssertEquals($AA, c.b);
  AssertEquals($FF, c.a);
end;

initialization
  RegisterTest(TTestCase_HexExt);

end.

