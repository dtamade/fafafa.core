{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_edge_cases;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_EdgeCases = class(TTestCase)
  published
    procedure Test_EmptyFile_Roundtrip;
    procedure Test_OnlyComments_Roundtrip;
    procedure Test_LongLine_Smoke;
  end;

function NormalizeLF(const S: String): String;

implementation

function NormalizeLF(const S: String): String;
var i: Integer;
    R: String;
begin
  R := '';
  i := 1;
  while i <= Length(S) do
  begin
    if (S[i] = #13) then
    begin
      if (i < Length(S)) and (S[i+1] = #10) then Inc(i);
      R := R + #10;
    end
    else
      R := R + S[i];
    Inc(i);
  end;
  Result := R;
end;

procedure TTestCase_EdgeCases.Test_EmptyFile_Roundtrip;
var Doc: IIniDocument; Err: TIniError; Out1, Out2: RawByteString; Doc2: IIniDocument; Err2: TIniError;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(''), Doc, Err));
  Out1 := ToIni(Doc, []);
  Err2.Clear;
  AssertTrue(Parse(Out1, Doc2, Err2));
  Out2 := ToIni(Doc2, []);
  AssertEquals(NormalizeLF(String(Out1)), NormalizeLF(String(Out2)));
end;

procedure TTestCase_EdgeCases.Test_OnlyComments_Roundtrip;
const
  SRC = '; c1'+LineEnding+
        '; c2'+LineEnding+
        ''+LineEnding+
        '; c3'+LineEnding;
var Doc: IIniDocument; Err: TIniError; Out1, Out2: RawByteString; Doc2: IIniDocument; Err2: TIniError;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(SRC), Doc, Err));
  Out1 := ToIni(Doc, []);
  Err2.Clear;
  AssertTrue(Parse(Out1, Doc2, Err2));
  Out2 := ToIni(Doc2, []);
  AssertEquals(NormalizeLF(String(Out1)), NormalizeLF(String(Out2)));
end;

procedure TTestCase_EdgeCases.Test_LongLine_Smoke;
var Doc: IIniDocument; Err: TIniError; S: String; LongVal: String; Out1: RawByteString;
begin
  // Generate a long value (~64KB)
  SetLength(LongVal, 65536);
  FillChar(LongVal[1], Length(LongVal), Ord('A'));
  Err.Clear;
  AssertTrue(Parse(RawByteString('[a]'+LineEnding), Doc, Err));
  SetString(Doc, 'a', 'long', LongVal);
  Out1 := ToIni(Doc, [iwfSpacesAroundEquals]);
  AssertTrue(Pos('long = ', String(Out1)) > 0);
  AssertTrue(Length(Out1) > 60000);
end;

initialization
  RegisterTest(TTestCase_EdgeCases);
end.

