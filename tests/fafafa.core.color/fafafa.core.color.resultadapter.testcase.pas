unit fafafa.core.color.resultadapter.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.color, fafafa.core.color.resultadapter, fafafa.core.result;

type
  TTestCase_ColorResultAdapter = class(TTestCase)
  published
    procedure Test_ParseHex_Result_Success_And_Error;
    procedure Test_ParseHexRGBA_Result_Success_And_Error;
  end;

implementation

procedure TTestCase_ColorResultAdapter.Test_ParseHex_Result_Success_And_Error;
var ok: TResultColor; err: color_error_t;
begin
  ok := color_parse_hex_result_s('#00FF00');
  AssertTrue(ok.IsOk);
  AssertEquals(255, ok.Unwrap.g);
  ok := color_parse_hex_result_s('bad');
  AssertTrue(ok.IsErr);
  err := ok.UnwrapErr;
  AssertTrue(Pos('invalid hex', err) > 0);
end;

procedure TTestCase_ColorResultAdapter.Test_ParseHexRGBA_Result_Success_And_Error;
var ok: TResultColor;
begin
  ok := color_parse_hex_rgba_result_s('#11223344');
  AssertTrue(ok.IsOk);
  AssertEquals($44, ok.Unwrap.a);
  ok := color_parse_hex_rgba_result_s('#xyz');
  AssertTrue(ok.IsErr);
end;

initialization
  RegisterTest(TTestCase_ColorResultAdapter);

end.

