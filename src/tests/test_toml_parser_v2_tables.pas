unit test_toml_parser_v2_tables;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml, fafafa.core.toml.parser.v2;

procedure RegisterTomlParserV2TableTests;

implementation

type
  TTomlParserV2TableCase = class(TTestCase)
  published
    procedure Test_Duplicate_Key;
    procedure Test_Type_Conflict_Table_vs_Scalar;
  end;

procedure TTomlParserV2TableCase.Test_Duplicate_Key;
var
  Doc: ITomlDocument; Err: TTomlError; Inp: RawByteString;
begin
  Inp := RawByteString('app.name = "a"' + LineEnding + 'app.name = "b"');
  Err.Clear;
  AssertFalse(TomlParseV2(Inp, Doc, Err));
  AssertTrue(Err.HasError);
  AssertTrue(Pos('duplicate key: app.name', Err.Message) > 0);
end;

procedure TTomlParserV2TableCase.Test_Type_Conflict_Table_vs_Scalar;
var
  Doc: ITomlDocument; Err: TTomlError; Inp: RawByteString;
begin
  // 先标量，再声明同路径为表
  Inp := RawByteString('app.name = "a"' + LineEnding + '[app.name]');
  Err.Clear;
  AssertFalse(TomlParseV2(Inp, Doc, Err));
  AssertTrue(Err.HasError);
  AssertTrue(Pos('type conflict at app.name', Err.Message) > 0);
end;

procedure RegisterTomlParserV2TableTests;
begin
  RegisterTest('toml-parser-v2-tables', TTomlParserV2TableCase);
end;

end.

