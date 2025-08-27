{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_trailing_newline_empty_doc;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_TrailingNewline_Empty = class(TTestCase)
  published
    procedure Test_TrailingNewline_EmptyDoc_Behavior_A;
  end;

implementation

procedure TTestCase_TrailingNewline_Empty.Test_TrailingNewline_EmptyDoc_Behavior_A;
var Doc: IIniDocument; Err: TIniError; S: RawByteString;
begin
  Err.Clear;
  // 空文档：不包含任何节和键
  AssertTrue(Parse(RawByteString(''), Doc, Err));
  // 方案A：仅非空输出时追加尾换行，空文档保持空字符串
  S := ToIni(Doc, [iwfForceLF, iwfTrailingNewline]);
  AssertEquals(0, Length(S));
end;

initialization
  RegisterTest(TTestCase_TrailingNewline_Empty);
end.

