{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_tables_headers;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Tables_Headers = class(TTestCase)
  published
    procedure Test_Table_Header_Basic_And_Assignment;
    procedure Test_Table_Header_Nested_Subtables;
    procedure Test_Table_Header_Conflict_With_Value;
  end;

implementation

procedure TTestCase_Tables_Headers.Test_Table_Header_Basic_And_Assignment;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S: RawByteString;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString('[a]' + LineEnding + 'x = 1'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  // Writer 应输出段落 [a]，并在其下输出 x = 1
  S := ToToml(LDoc, []);
  AssertTrue(Pos('[a]' + LineEnding + 'x = 1', String(S)) > 0);
end;

procedure TTestCase_Tables_Headers.Test_Table_Header_Nested_Subtables;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S: RawByteString;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString('[a.b]' + LineEnding + 'y = 2'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  S := ToToml(LDoc, []);
  AssertTrue(Pos('[a.b]' + LineEnding + 'y = 2', String(S)) > 0);
end;

procedure TTestCase_Tables_Headers.Test_Table_Header_Conflict_With_Value;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  Ok: Boolean;
begin
  LErr.Clear;
  Ok := Parse(RawByteString('a = 1' + LineEnding + '[a]'), LDoc, LErr);
  // 冲突：先将 a 定义为值，再尝试重开 [a] 表，应失败
  AssertFalse(Ok);
  AssertTrue(LErr.HasError);
  AssertTrue(LErr.Code = tecTypeMismatch);
end;

initialization
  RegisterTest(TTestCase_Tables_Headers);
end.

