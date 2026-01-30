{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_values;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.math,
  fafafa.core.ini;

type
  TTestCase_Values = class(TTestCase)
  published
    procedure Test_TryGetFloat_LocaleInvariant;
    procedure Test_TryGetInt_Bool_Float;
  end;

implementation

procedure TTestCase_Values.Test_TryGetFloat_LocaleInvariant;
var Doc: IIniDocument; Err: TIniError; F: Double;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('[a]'+LineEnding+'x=1.5'+LineEnding), Doc, Err));
  AssertTrue(Doc.TryGetFloat('a', 'x', F));
  AssertTrue(Abs(F - 1.5) < 1e-9);
end;

procedure TTestCase_Values.Test_TryGetInt_Bool_Float;
var Doc: IIniDocument; Err: TIniError;
    I: Int64; B: Boolean; F: Double;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('[core]'+LineEnding+
    'a=1'+LineEnding+
    'b=true'+LineEnding+
    'c=3.14'), Doc, Err));
  AssertTrue(Doc.TryGetInt('core', 'a', I));
  AssertEquals(1, I);
  AssertTrue(Doc.TryGetBool('core', 'b', B));
  AssertTrue(B);
  AssertTrue(Doc.TryGetFloat('core', 'c', F));
  AssertTrue(Abs(F-3.14) < 1e-9);
end;

initialization
  RegisterTest(TTestCase_Values);
end.
