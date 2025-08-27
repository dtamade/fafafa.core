unit test_toml_parser_v2_minimal;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml, fafafa.core.toml.parser.v2;

procedure RegisterTomlParserV2MinimalTests;

implementation

type
  TTomlParserV2MinimalCase = class(TTestCase)
  published
    procedure Test_KeyValue_And_Table;
    procedure Test_Dotted_Keys_Assignment;
  end;

procedure TTomlParserV2MinimalCase.Test_KeyValue_And_Table;
var
  Doc: ITomlDocument; Err: TTomlError; S: RawByteString;
  Inp: RawByteString;
begin
  Inp := RawByteString('[app]' + LineEnding + 'name = "core"' + LineEnding + 'ver = 1');
  Err.Clear;
  AssertTrue(TomlParseV2(Inp, Doc, Err));
  S := ToToml(Doc, [twfSortKeys, twfSpacesAroundEquals]);
  AssertTrue(Pos('[app]', String(S)) > 0);
  AssertTrue(Pos('name = "core"', String(S)) > 0);
  AssertTrue(Pos('ver = 1', String(S)) > 0);
end;

procedure TTomlParserV2MinimalCase.Test_Dotted_Keys_Assignment;
var
  Doc: ITomlDocument; Err: TTomlError; S: RawByteString;
  Inp: RawByteString;
begin
  Inp := RawByteString('app.name = "core"' + LineEnding + 'app.ver = 1');
  Err.Clear;
  AssertTrue(TomlParseV2(Inp, Doc, Err));
  S := ToToml(Doc, [twfSortKeys, twfSpacesAroundEquals]);
  AssertTrue(Pos('[app]', String(S)) > 0);
  AssertTrue(Pos('name = "core"', String(S)) > 0);
  AssertTrue(Pos('ver = 1', String(S)) > 0);
end;

procedure RegisterTomlParserV2MinimalTests;
begin
  RegisterTest('toml-parser-v2-minimal', TTomlParserV2MinimalCase);
end;

end.

