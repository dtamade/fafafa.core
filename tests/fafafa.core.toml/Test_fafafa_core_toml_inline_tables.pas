{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_inline_tables;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Inline_Tables = class(TTestCase)
  published
    procedure Test_Inline_Table_Parse_Smoke;
  end;

implementation

procedure TTestCase_Inline_Tables.Test_Inline_Table_Parse_Smoke;
var
  D: ITomlDocument;
  E: TTomlError;
  S: RawByteString;
  T: ITomlTable;
  V: ITomlValue;
  Sval: String;
  Ival: Int64;
begin
  E.Clear;
  // RFC 风格示例：单行内联表
  AssertTrue(Parse(RawByteString('server = { ip = "127.0.0.1", port = 8080 }'), D, E));
  AssertFalse(E.HasError);
  // 读取并断言（通过表 API，而非路径便捷 API）
  T := D.Root.GetValue('server') as ITomlTable;
  AssertTrue(T <> nil);
  V := T.GetValue('ip');
  AssertTrue((V <> nil) and V.TryGetString(Sval));
  AssertEquals('127.0.0.1', Sval);
  V := T.GetValue('port');
  AssertTrue((V <> nil) and V.TryGetInteger(Ival));
  AssertEquals(Int64(8080), Ival);
  // 写出目前不强求内联格式，仅确保能写并包含值
  S := ToToml(D, []);
  AssertTrue(Pos('127.0.0.1', String(S)) > 0);
  AssertTrue(Pos('8080', String(S)) > 0);
end;

initialization
  RegisterTest(TTestCase_Inline_Tables);
end.

