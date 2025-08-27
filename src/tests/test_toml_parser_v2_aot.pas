unit test_toml_parser_v2_aot;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml, fafafa.core.toml.parser.v2;

procedure RegisterTomlParserV2AotTests;

implementation

type
  TTomlParserV2AotCase = class(TTestCase)
  published
    procedure Test_AoT_Push_Two_Tables;
    procedure Test_AoT_Conflict_With_Normal_Table;
  end;

procedure TTomlParserV2AotCase.Test_AoT_Push_Two_Tables;
var
  Doc: ITomlDocument; Err: TTomlError; Inp: RawByteString; S: RawByteString;
begin
  Inp := RawByteString('[[db.servers]]' + LineEnding + 'name = "a"' + LineEnding +
                       '[[db.servers]]' + LineEnding + 'name = "b"');
  Err.Clear;
  AssertTrue(TomlParseV2(Inp, Doc, Err));
  S := ToToml(Doc, [twfSortKeys, twfSpacesAroundEquals]);
  AssertTrue(Pos('[[db.servers]]', String(S)) > 0);
  AssertTrue(Pos('name = "a"', String(S)) > 0);
  AssertTrue(Pos('name = "b"', String(S)) > 0);
end;

procedure TTomlParserV2AotCase.Test_AoT_Conflict_With_Normal_Table;
var
  Doc: ITomlDocument; Err: TTomlError; Inp: RawByteString;
begin
  Inp := RawByteString('[db.servers]' + LineEnding + 'x = 1' + LineEnding + '[[db.servers]]');
  Err.Clear;
  AssertFalse(TomlParseV2(Inp, Doc, Err));
  AssertTrue(Err.HasError);
  AssertTrue(Pos('type conflict', Err.Message) > 0);
end;

procedure RegisterTomlParserV2AotTests;
begin
  RegisterTest('toml-parser-v2-aot', TTomlParserV2AotCase);
end;

end.

