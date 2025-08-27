{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_header_and_whitespace;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_HeaderAndWhitespace = class(TTestCase)
  published
    procedure Test_Unclosed_Section_Header_Error_Column_With_Leading_Spaces;
    procedure Test_LeadingWhitespace_Comment_Is_Recognized;
    procedure Test_KeyValue_With_Colon_Separator;
  end;

implementation

procedure TTestCase_HeaderAndWhitespace.Test_Unclosed_Section_Header_Error_Column_With_Leading_Spaces;
const
  SRC = '   [abc' + LineEnding + 'k=v' + LineEnding; // missing closing bracket
var Doc: IIniDocument; Err: TIniError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString(SRC), Doc, Err));
  AssertTrue(Err.HasError);
  // Expect Column = first non-space + '[' position = 4
  AssertEquals(4, Integer(Err.Column));
  AssertEquals(1, Integer(Err.Line));
end;

procedure TTestCase_HeaderAndWhitespace.Test_LeadingWhitespace_Comment_Is_Recognized;
const
  SRC = '  ; prelude cmt' + LineEnding +
        '' + LineEnding +
        '  [s]' + LineEnding +
        '  ; hdr cmt' + LineEnding +
        '  a = 1' + LineEnding;
var Doc: IIniDocument; Err: TIniError; S: String;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(SRC), Doc, Err, [irfInlineComment]));
  AssertTrue(Doc.HasSection('s'));
  AssertTrue(Doc.TryGetString('s', 'a', S));
  AssertEquals('1', S);
end;

procedure TTestCase_HeaderAndWhitespace.Test_KeyValue_With_Colon_Separator;
const
  SRC = '[x]' + LineEnding + 'a: 1' + LineEnding;
var Doc: IIniDocument; Err: TIniError; V: String;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(SRC), Doc, Err, [irfInlineComment]));
  AssertTrue(Doc.TryGetString('x', 'a', V));
  AssertEquals('1', V);
end;

initialization
  RegisterTest(TTestCase_HeaderAndWhitespace);
end.

