unit test_toml_error_positions;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

procedure RegisterTomlErrorPositionTests;

implementation

type
  TTomlErrorPosCase = class(TTestCase)
  published
    procedure Test_InlineTable_MissingComma_LF;
    procedure Test_InlineTable_MissingComma_CRLF;
    procedure Test_Array_MissingComma_LF;
  end;

procedure TTomlErrorPosCase.Test_InlineTable_MissingComma_LF;
var
  Doc: ITomlDocument; Err: TTomlError; Txt: RawByteString;
begin
  // cfg inline table 缺少逗号，错误应定位到 'b' 的列
  Txt := 'cfg = { a = 1 b = 2 }';
  Err.Clear;
  AssertFalse(Parse(Txt, Doc, Err));
  AssertTrue(Err.HasError);
  AssertEquals('Expected comma in inline table', Err.Message);
  AssertEquals(SizeUInt(1), Err.Line);
  AssertEquals(SizeUInt(15), Err.Column);
end;

procedure TTomlErrorPosCase.Test_InlineTable_MissingComma_CRLF;
var
  Doc: ITomlDocument; Err: TTomlError; Txt: RawByteString;
begin
  // 第二行的 inline table 缺逗号
  Txt := 'ok = 1' + #13#10 + 'cfg = { a = 1 b = 2 }';
  Err.Clear;
  AssertFalse(Parse(Txt, Doc, Err));
  AssertTrue(Err.HasError);
  AssertEquals('Expected comma in inline table', Err.Message);
  AssertEquals(SizeUInt(2), Err.Line);
  AssertEquals(SizeUInt(15), Err.Column);
end;

procedure TTomlErrorPosCase.Test_Array_MissingComma_LF;
var
  Doc: ITomlDocument; Err: TTomlError; Txt: RawByteString;
begin
  // 数组缺逗号，错误应定位到 '2'
  Txt := 'xs = [1 2]';
  Err.Clear;
  AssertFalse(Parse(Txt, Doc, Err));
  AssertTrue(Err.HasError);
  AssertEquals('Expected comma', Err.Message);
  // 行=1，列在 '[' 后的元素2的开始处："xs = [1 2]" 中 '2' 的列是 10
  AssertEquals(SizeUInt(1), Err.Line);
  AssertEquals(SizeUInt(9), Err.Column);
end;

procedure RegisterTomlErrorPositionTests;
begin
  RegisterTest('toml-error-positions', TTomlErrorPosCase);
end;

end.

