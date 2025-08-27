{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_inline_comment_quotes;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_InlineComment_Quotes = class(TTestCase)
  published
    procedure Test_InlineComment_QuotesAware_On;
    procedure Test_InlineComment_QuotesAware_Off;
  end;

implementation

procedure TTestCase_InlineComment_Quotes.Test_InlineComment_QuotesAware_On;
const
  SRC = '[a]'+LineEnding+
        'x = "1;keep" ; trailing'+LineEnding+
        'y = ''2 # keep'' # trailing'+LineEnding+
        'z = 3 ; comment only'+LineEnding+
        'w = ''semi;# in single'' # cmt'+LineEnding;
var Doc: IIniDocument; Err: TIniError; S: String;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(SRC), Doc, Err, [irfInlineComment]));
  AssertTrue(Doc.TryGetString('a','x', S));
  AssertEquals('1;keep', S);
  AssertTrue(Doc.TryGetString('a','y', S));
  AssertEquals('2 # keep', S);
  AssertTrue(Doc.TryGetString('a','z', S));
  AssertEquals('3', S);
  AssertTrue(Doc.TryGetString('a','w', S));
  AssertEquals('semi;# in single', S);
end;

procedure TTestCase_InlineComment_Quotes.Test_InlineComment_QuotesAware_Off;
const
  SRC = '[a]'+LineEnding+
        'x = "1;keep" ; trailing'+LineEnding+
        'y = ''2 # keep'' # trailing'+LineEnding;
var Doc: IIniDocument; Err: TIniError; S: String;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(SRC), Doc, Err));
  AssertTrue(Doc.TryGetString('a','x', S));
  AssertEquals('"1;keep" ; trailing', S);
  AssertTrue(Doc.TryGetString('a','y', S));
  AssertEquals('''2 # keep'' # trailing', S);
end;

initialization
  RegisterTest(TTestCase_InlineComment_Quotes);
end.

