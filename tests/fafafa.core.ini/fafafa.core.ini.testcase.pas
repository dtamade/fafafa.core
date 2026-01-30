{$CODEPAGE UTF8}
unit fafafa.core.ini.testcase;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  // 全局函数用例
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_Parse_Smoke;
    procedure Test_Parse_Section_And_Key;
    procedure Test_ParseFile_NotFound;
    procedure Test_ToIni_Smoke;
  end;

implementation

procedure TTestCase_Global.Test_Parse_Smoke;
var Doc: IIniDocument; Err: TIniError; Ok: Boolean;
begin
  Err.Clear;
  Ok := Parse(RawByteString('[core]' + LineEnding + 'name = fafafa'), Doc, Err);
  AssertTrue('parse should succeed', Ok);
  AssertFalse('no error expected', Err.HasError);
  AssertTrue('doc not nil', Doc <> nil);
end;

procedure TTestCase_Global.Test_Parse_Section_And_Key;
var Doc: IIniDocument; Err: TIniError; S: IIniSection; V: String;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('[core]'+LineEnding+'name = fafafa'+LineEnding+LineEnding+'[ui]'+LineEnding+'theme=dark'), Doc, Err));
  AssertTrue(Doc.HasSection('core'));
  AssertTrue(Doc.TryGetString('core', 'name', V));
  AssertEquals('fafafa', V);
  AssertFalse(Doc.HasSection('not-exists'));
end;

procedure TTestCase_Global.Test_ParseFile_NotFound;
var Doc: IIniDocument; Err: TIniError;
begin
  Err.Clear;
  AssertFalse(ParseFile('__file_not_found__.ini', Doc, Err));
  AssertTrue(Err.HasError);
  AssertEquals(Ord(iecFileIO), Ord(Err.Code));
end;

procedure TTestCase_Global.Test_ToIni_Smoke;
var Doc: IIniDocument; Err: TIniError; OutText: RawByteString;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('[core]'+LineEnding+'name=fafafa'), Doc, Err));
  OutText := ToIni(Doc, [iwfSpacesAroundEquals]);
  AssertTrue('output not empty', Length(OutText) > 0);
end;

initialization
  RegisterTest(TTestCase_Global);
end.

