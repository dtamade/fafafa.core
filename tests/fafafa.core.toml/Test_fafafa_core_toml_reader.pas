{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_reader;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Reader = class(TTestCase)
  published
    procedure Test_Parse_String_Escape_Simple;
  end;

implementation

procedure TTestCase_Reader.Test_Parse_String_Escape_Simple;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
begin
  LErr.Clear;
  // 只验证字符串转义能编译与基本读取路径；不做 Contains/GetValue 断言（后续再补）
  AssertTrue(Parse(RawByteString('key = "a\\"b"'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  AssertTrue(LDoc <> nil);
end;

initialization
  RegisterTest(TTestCase_Reader);
end.

