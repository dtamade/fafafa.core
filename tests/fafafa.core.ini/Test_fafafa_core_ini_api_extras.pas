{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_api_extras;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_ApiExtras = class(TTestCase)
  published
    procedure Test_HasKey_Positive_Negative;
    procedure Test_RemoveKey_AffectsOnlySection;
    procedure Test_RemoveSection_Removes_Section;
  end;

implementation

procedure TTestCase_ApiExtras.Test_HasKey_Positive_Negative;
const
  SRC = '[s]'+LineEnding+'a=1'+LineEnding;
var Doc: IIniDocument; Err: TIniError; S: String;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(SRC), Doc, Err));
  AssertTrue(Doc.HasSection('s'));
  AssertTrue(Doc.HasKey('s','a'));
  AssertFalse(Doc.HasKey('s','b'));
  // sanity
  AssertTrue(Doc.TryGetString('s','a', S));
  AssertEquals('1', S);
end;

procedure TTestCase_ApiExtras.Test_RemoveKey_AffectsOnlySection;
const
  SRC = '[s1]'+LineEnding+'a=1'+LineEnding+'b=2'+LineEnding+
        '[s2]'+LineEnding+'a=9'+LineEnding;
var Doc: IIniDocument; Err: TIniError; Out1: RawByteString; S: String;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(SRC), Doc, Err));
  AssertTrue(Doc.HasKey('s1','b'));
  AssertTrue(Doc.RemoveKey('s1','b'));
  AssertFalse(Doc.HasKey('s1','b'));
  // 其他节不受影响
  AssertTrue(Doc.TryGetString('s2','a', S));
  AssertEquals('9', S);
  Out1 := ToIni(Doc, []);
  AssertTrue(Pos('[s1]', String(Out1))>0);
  AssertTrue(Pos('[s2]', String(Out1))>0);
  AssertTrue(Pos('a=1', String(Out1))>0);
  AssertTrue(Pos('a=9', String(Out1))>0);
  AssertTrue(Pos('b=2', String(Out1))=0);
end;

procedure TTestCase_ApiExtras.Test_RemoveSection_Removes_Section;
const
  SRC = '[s1]'+LineEnding+'a=1'+LineEnding+
        '[s2]'+LineEnding+'b=2'+LineEnding;
var Doc: IIniDocument; Err: TIniError; Out1: RawByteString;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(SRC), Doc, Err));
  AssertTrue(Doc.RemoveSection('s1'));
  AssertFalse(Doc.HasSection('s1'));
  Out1 := ToIni(Doc, []);
  AssertTrue(Pos('[s2]', String(Out1))>0);
  AssertTrue(Pos('[s1]', String(Out1))=0);
end;

initialization
  RegisterTest(TTestCase_ApiExtras);
end.

