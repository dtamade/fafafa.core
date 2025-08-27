unit test_toml_parser_v2_inline;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml, fafafa.core.toml.parser.v2;

procedure RegisterTomlParserV2InlineTests;

implementation

type
  TTomlParserV2InlineCase = class(TTestCase)
  published
    procedure Test_Inline_Table_Basic;
    procedure Test_Inline_Table_Duplicate_Key;
  end;

procedure TTomlParserV2InlineCase.Test_Inline_Table_Basic;
var
  Doc: ITomlDocument; Err: TTomlError; Inp: RawByteString; S: RawByteString;
begin
  Inp := RawByteString('user = { name = "a", age = 12 }');
  Err.Clear;
  AssertTrue(TomlParseV2(Inp, Doc, Err));
  S := ToToml(Doc, [twfSortKeys, twfSpacesAroundEquals]);
  AssertTrue(Pos('[user]', String(S)) > 0);
  AssertTrue(Pos('name = "a"', String(S)) > 0);
  AssertTrue(Pos('age = 12', String(S)) > 0);
end;

procedure TTomlParserV2InlineCase.Test_Inline_Table_Duplicate_Key;
var
  Doc: ITomlDocument; Err: TTomlError; Inp: RawByteString;
begin
  Inp := RawByteString('user = { name = "a", name = "b" }');
  Err.Clear;
  AssertFalse(TomlParseV2(Inp, Doc, Err));
  AssertTrue(Pos('duplicate key', Err.Message) > 0);
end;

procedure RegisterTomlParserV2InlineTests;
begin
  RegisterTest('toml-parser-v2-inline', TTomlParserV2InlineCase);
end;

end.

