unit fafafa.core.color.hex.try.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_HexTry = class(TTestCase)
  published
    procedure Test_TryFromHex_Success_And_Trim;
    procedure Test_TryFromHex_Fail_Invalid;
  end;

implementation

procedure TTestCase_HexTry.Test_TryFromHex_Success_And_Trim;
var c: color_rgba_t; ok: Boolean;
begin
  ok := color_try_from_hex('  #00FF00  ', c);
  AssertTrue(ok);
  AssertEquals(0, c.r);
  AssertEquals(255, c.g);
  AssertEquals(0, c.b);
end;

procedure TTestCase_HexTry.Test_TryFromHex_Fail_Invalid;
var c: color_rgba_t; ok: Boolean;
begin
  ok := color_try_from_hex('#ZZZZZZ', c);
  AssertFalse(ok);
  AssertEquals(0, c.r);
  AssertEquals(0, c.g);
  AssertEquals(0, c.b);
end;

initialization
  RegisterTest(TTestCase_HexTry);

end.

