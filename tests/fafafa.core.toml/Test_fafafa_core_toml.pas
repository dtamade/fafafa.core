{$CODEPAGE UTF8}
unit Test_fafafa_core_toml;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.toml;

type
  { 最小烟雾测试：关注编译与最简单用法，不做过度覆盖 }
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_Smoke_Parse_EmptyDoc_ReturnsOk;
    procedure Test_Smoke_Parse_SimpleKeyValue;
  end;

implementation

procedure TTestCase_Global.Test_Smoke_Parse_EmptyDoc_ReturnsOk;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString(''), LDoc, LErr));
  AssertFalse(LErr.HasError);
  AssertTrue(LDoc <> nil);
end;

procedure TTestCase_Global.Test_Smoke_Parse_SimpleKeyValue;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
begin
  LErr.Clear;
  // 仅测试调用路径，真实语义稍后按 TDD 实现
  AssertTrue(Parse(RawByteString('key = "value"' + LineEnding + '# comment'), LDoc, LErr));
  AssertFalse(LErr.HasError);
end;

initialization
  RegisterTest(TTestCase_Global);
end.

