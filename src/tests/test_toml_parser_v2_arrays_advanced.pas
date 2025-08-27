unit test_toml_parser_v2_arrays_advanced;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml, fafafa.core.toml.parser.v2;

procedure RegisterTomlParserV2ArrayAdvancedTests;

implementation

type
  TTomlParserV2ArrayAdvancedCase = class(TTestCase)
  published
    procedure Test_Inline_Array_Of_Tables;
    procedure Test_Nested_Array_Of_Ints;
  end;

procedure TTomlParserV2ArrayAdvancedCase.Test_Inline_Array_Of_Tables;
var Doc: ITomlDocument; Err: TTomlError; Inp: RawByteString; S: RawByteString;
begin
  Inp := RawByteString('a = [{k = 1}, {k = 2}]');
  if not TomlParseV2(Inp, Doc, Err) then Fail('Parse failed: ' + String(Err.Message));
  S := ToToml(Doc, [twfSpacesAroundEquals]);
  // Writer 当前会以 [[a]] 形式写出 AoT
  AssertTrue(Pos('[[a]]', String(S)) > 0);
  AssertTrue(Pos('k = 1', String(S)) > 0);
  AssertTrue(Pos('k = 2', String(S)) > 0);
end;

procedure TTomlParserV2ArrayAdvancedCase.Test_Nested_Array_Of_Ints;
var Doc: ITomlDocument; Err: TTomlError; Inp: RawByteString; S: RawByteString;
begin
  Inp := RawByteString('a = [[1,2],[3,4]]');
  if not TomlParseV2(Inp, Doc, Err) then Fail('Parse failed: ' + String(Err.Message));
  S := ToToml(Doc, [twfSpacesAroundEquals]);
  // Writer 输出为 a = [[1, 2], [3, 4]]（取决于 ScalarToText 实现，至少应包含 [[1, 2]）
  AssertTrue(Pos('a = [[1, 2]', String(S)) > 0);
  AssertTrue(Pos('[3, 4]]', String(S)) > 0);
end;

procedure RegisterTomlParserV2ArrayAdvancedTests;
begin
  RegisterTest('toml-parser-v2-arrays-advanced', TTomlParserV2ArrayAdvancedCase);
end;

end.

