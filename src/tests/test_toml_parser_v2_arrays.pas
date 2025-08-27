unit test_toml_parser_v2_arrays;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml, fafafa.core.toml.parser.v2;

procedure RegisterTomlParserV2ArrayTests;

implementation

type
  TTomlParserV2ArrayCase = class(TTestCase)
  published
    procedure Test_Array_Int;
    procedure Test_Array_Float;
    procedure Test_Array_Bool;
    procedure Test_Array_Str;
    procedure Test_Array_Empty;
    procedure Test_Array_Mixed_Negative;
  end;

procedure TTomlParserV2ArrayCase.Test_Array_Int;
var Doc: ITomlDocument; Err: TTomlError; Inp: RawByteString; S: RawByteString;
begin
  Inp := RawByteString('a = [1, 2, 3]');
  if not TomlParseV2(Inp, Doc, Err) then Fail('Parse failed: ' + String(Err.Message));
  S := ToToml(Doc, [twfSpacesAroundEquals]);
  AssertTrue(Pos('a = [1, 2, 3]', String(S)) > 0);
end;

procedure TTomlParserV2ArrayCase.Test_Array_Float;
var Doc: ITomlDocument; Err: TTomlError; Inp: RawByteString; S: RawByteString;
begin
  Inp := RawByteString('a = [1.0, 2.5, 3e2]');
  if not TomlParseV2(Inp, Doc, Err) then Fail('Parse failed: ' + String(Err.Message));
  S := ToToml(Doc, [twfSpacesAroundEquals]);
  AssertTrue(Pos('a = [1.0, 2.5, 300]', String(S)) > 0);
end;

procedure TTomlParserV2ArrayCase.Test_Array_Bool;
var Doc: ITomlDocument; Err: TTomlError; Inp: RawByteString; S: RawByteString;
begin
  Inp := RawByteString('a = [true, false, true]');
  if not TomlParseV2(Inp, Doc, Err) then Fail('Parse failed: ' + String(Err.Message));
  S := ToToml(Doc, [twfSpacesAroundEquals]);
  AssertTrue(Pos('a = [true, false, true]', String(S)) > 0);
end;

procedure TTomlParserV2ArrayCase.Test_Array_Str;
var Doc: ITomlDocument; Err: TTomlError; Inp: RawByteString; S: RawByteString;
begin
  Inp := RawByteString('a = ["x", "y", "z"]');
  if not TomlParseV2(Inp, Doc, Err) then Fail('Parse failed: ' + String(Err.Message));
  S := ToToml(Doc, [twfSpacesAroundEquals]);
  AssertTrue(Pos('a = ["x", "y", "z"]', String(S)) > 0);
end;

procedure TTomlParserV2ArrayCase.Test_Array_Empty;
var Doc: ITomlDocument; Err: TTomlError; Inp: RawByteString; S: RawByteString;
begin
  Inp := RawByteString('a = []');
  if not TomlParseV2(Inp, Doc, Err) then Fail('Parse failed: ' + String(Err.Message));
  S := ToToml(Doc, [twfSpacesAroundEquals]);
  AssertTrue(Pos('a = []', String(S)) > 0);
end;

procedure TTomlParserV2ArrayCase.Test_Array_Mixed_Negative;
var Doc: ITomlDocument; Err: TTomlError; Inp: RawByteString;
begin
  Inp := RawByteString('a = [1, 2.0]');
  AssertFalse(TomlParseV2(Inp, Doc, Err));
end;

procedure RegisterTomlParserV2ArrayTests;
begin
  RegisterTest('toml-parser-v2-arrays', TTomlParserV2ArrayCase);
end;

end.

