{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_writer_nested;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Writer_Nested = class(TTestCase)
  published
    procedure Test_ToToml_Nested_Tables_From_Dotted;
    procedure Test_ToToml_Root_Scalars_Then_Subtables;
  end;

implementation

procedure TTestCase_Writer_Nested.Test_ToToml_Nested_Tables_From_Dotted;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S: RawByteString;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString('a.b.c = "x"'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  S := ToToml(LDoc, []);
  // 基本包含关系检查，避免强绑定格式细节
  AssertTrue(Pos('[a]', String(S)) > 0);
  AssertTrue(Pos('[a.b]', String(S)) > 0);
  AssertTrue(Pos('c = "x"', String(S)) > 0);
end;

procedure TTestCase_Writer_Nested.Test_ToToml_Root_Scalars_Then_Subtables;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S: RawByteString;
  Pfoo, Pa, Pab: SizeInt;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString('foo = 1' + LineEnding + 'a.b.c = "x"'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  S := ToToml(LDoc, []);
  // 仅检查顺序大致正确：根级标量在前，随后是表头
  Pfoo := Pos('foo = 1', String(S));
  Pa := Pos('[a]', String(S));
  Pab := Pos('[a.b]', String(S));
  AssertTrue(Pfoo > 0);
  AssertTrue(Pa > 0);
  AssertTrue(Pab > 0);
  AssertTrue(Pfoo < Pa);
  AssertTrue(Pa < Pab);
end;

initialization
  RegisterTest(TTestCase_Writer_Nested);
end.

