{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_inline_comment_default_only;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_InlineComment_DefaultOnly = class(TTestCase)
  published
    procedure Test_DefaultSection_InlineComment_Off;
    procedure Test_DefaultSection_InlineComment_On;
  end;

implementation

const
  SAMPLE_PATH = '..\..\samples\ini\default_only.ini';

procedure TTestCase_InlineComment_DefaultOnly.Test_DefaultSection_InlineComment_Off;
var Doc: IIniDocument; Err: TIniError; S: String;
begin
  Err.Clear;
  AssertTrue(ParseFile(SAMPLE_PATH, Doc, Err));
  // default section is ''
  AssertTrue(Doc.TryGetString('', 'key1', S));
  AssertEquals('value1', S);
  AssertTrue(Doc.TryGetString('', 'key2', S));
  // default: no stripping
  AssertEquals('value2 ; with inline', S);
end;

procedure TTestCase_InlineComment_DefaultOnly.Test_DefaultSection_InlineComment_On;
var Doc: IIniDocument; Err: TIniError; S: String;
begin
  Err.Clear;
  AssertTrue(ParseFile(SAMPLE_PATH, Doc, Err, [irfInlineComment]));
  // default section is ''
  AssertTrue(Doc.TryGetString('', 'key1', S));
  AssertEquals('value1', S);
  AssertTrue(Doc.TryGetString('', 'key2', S));
  // with stripping enabled
  AssertEquals('value2', S);
end;

initialization
  RegisterTest(TTestCase_InlineComment_DefaultOnly);
end.

