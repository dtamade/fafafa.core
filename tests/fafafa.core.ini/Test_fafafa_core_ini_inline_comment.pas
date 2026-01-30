{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_inline_comment;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_InlineComment = class(TTestCase)
  published
    procedure Test_InlineComment_Off_Default;
    procedure Test_InlineComment_On_Parsing;
  end;

implementation

procedure TTestCase_InlineComment.Test_InlineComment_Off_Default;
const
  SRC = '[a]'+LineEnding+
        'x = 1 ; trailing comment'+LineEnding+
        'y = 2 # other comment'''+LineEnding;
var Doc: IIniDocument; Err: TIniError; S: String;
begin
  Err.Clear;
  // 默认关闭，不截断
  AssertTrue(Parse(RawByteString(SRC), Doc, Err));
  AssertTrue(Doc.TryGetString('a','x', S));
  AssertEquals('1 ; trailing comment', S);
  AssertTrue(Doc.TryGetString('a','y', S));
  AssertEquals('2 # other comment''', S);
end;

procedure TTestCase_InlineComment.Test_InlineComment_On_Parsing;
const
  SRC = '[a]'+LineEnding+
        'x = 1 ; trailing comment'+LineEnding+
        'y = 2 # other comment'''+LineEnding;
var Doc: IIniDocument; Err: TIniError; S: String;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(SRC), Doc, Err, [irfInlineComment]));
  AssertTrue(Doc.TryGetString('a','x', S));
  AssertEquals('1', S);
  AssertTrue(Doc.TryGetString('a','y', S));
  AssertEquals('2', S);
end;

initialization
  RegisterTest(TTestCase_InlineComment);
end.

