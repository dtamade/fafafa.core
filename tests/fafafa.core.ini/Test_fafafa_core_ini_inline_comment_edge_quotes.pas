{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_inline_comment_edge_quotes;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_InlineCommentEdges = class(TTestCase)
  published
    procedure Test_InlineComment_Quoted_SemiHash_Preserved_When_Allowed;
    procedure Test_InlineComment_Quoted_SemiHash_Stripped_When_NotAllowed;
    procedure Test_InlineComment_Whitespace_Around_Value;
  end;

implementation

procedure TTestCase_InlineCommentEdges.Test_InlineComment_Quoted_SemiHash_Preserved_When_Allowed;
var Doc: IIniDocument; Err: TIniError; S: String;
begin
  AssertTrue(Parse(RawByteString('[s]'#10'a="v;#"'#10), Doc, Err, [irfInlineComment, irfAllowQuotedValue]));
  AssertTrue(Doc.TryGetString('s','a', S));
  AssertEquals('"v;#"', S);
end;

procedure TTestCase_InlineCommentEdges.Test_InlineComment_Quoted_SemiHash_Stripped_When_NotAllowed;
var Doc: IIniDocument; Err: TIniError; S: String;
begin
  AssertTrue(Parse(RawByteString('[s]'#10'a="v;#"'#10), Doc, Err, [irfInlineComment]));
  AssertTrue(Doc.TryGetString('s','a', S));
  AssertEquals('v;#', S);
end;

procedure TTestCase_InlineCommentEdges.Test_InlineComment_Whitespace_Around_Value;
var Doc: IIniDocument; Err: TIniError; S: String;
begin
  AssertTrue(Parse(RawByteString('[s]'#10'a=  "x"  ; cmt'#10), Doc, Err, [irfInlineComment]));
  AssertTrue(Doc.TryGetString('s','a', S));
  AssertEquals('x', Trim(S));
end;

initialization
  RegisterTest(TTestCase_InlineCommentEdges);
end.

