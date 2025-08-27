{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_writer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Writer = class(TTestCase)
  published
    procedure Test_ToToml_Minimal_Smoke;
  end;

implementation

procedure TTestCase_Writer.Test_ToToml_Minimal_Smoke;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  LOut: RawByteString;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString('a = 1
b = "x"'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  LOut := ToToml(LDoc, []);
  // 仅烟雾检查：输出不为空
  AssertTrue(Length(LOut) > 0);
end;

initialization
  RegisterTest(TTestCase_Writer);
end.

