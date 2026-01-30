unit fafafa.core.color.hex.parse.strict.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_HexParseStrict = class(TTestCase)
  published
    procedure Test_ParseHex_Strict_OK;
    procedure Test_ParseHex_Strict_Invalid_Raises;
    procedure Test_ParseHexRGBA_Strict_OK;
    procedure Test_ParseHexRGBA_Strict_Invalid_Raises;
  end;

implementation

procedure TTestCase_HexParseStrict.Test_ParseHex_Strict_OK;
var c: color_rgba_t;
begin
  c := color_parse_hex('#00FF00');
  AssertEquals(0, c.r);
  AssertEquals(255, c.g);
  AssertEquals(0, c.b);
end;

procedure TTestCase_HexParseStrict.Test_ParseHex_Strict_Invalid_Raises;
var raised: Boolean; c: color_rgba_t;
begin
  raised := False;
  try
    c := color_parse_hex('#GGGGGG');
  except
    on E: Exception do raised := True;
  end;
  AssertTrue(raised);
end;

procedure TTestCase_HexParseStrict.Test_ParseHexRGBA_Strict_OK;
var c: color_rgba_t;
begin
  c := color_parse_hex_rgba('#11223344');
  AssertEquals($11, c.r);
  AssertEquals($22, c.g);
  AssertEquals($33, c.b);
  AssertEquals($44, c.a);
end;

procedure TTestCase_HexParseStrict.Test_ParseHexRGBA_Strict_Invalid_Raises;
var raised: Boolean; c: color_rgba_t;
begin
  raised := False;
  try
    c := color_parse_hex_rgba('#XYZ');
  except
    on E: Exception do raised := True;
  end;
  AssertTrue(raised);
end;

initialization
  RegisterTest(TTestCase_HexParseStrict);

end.

