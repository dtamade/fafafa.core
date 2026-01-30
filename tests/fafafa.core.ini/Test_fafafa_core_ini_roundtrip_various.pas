{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_roundtrip_various;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_RoundtripVarious = class(TTestCase)
  published
    procedure Test_Roundtrip_Various_Mixed;
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

procedure TTestCase_RoundtripVarious.Test_Roundtrip_Various_Mixed;
const
  SRC = '; prelude 1'+LineEnding+
        ''+LineEnding+
        '; prelude 2'+LineEnding+
        '[a]'+LineEnding+
        '; hdr a'+LineEnding+
        'x=1'+LineEnding+
        '; mid a'+LineEnding+
        ''+LineEnding+
        'y : 2'+LineEnding+
        ''+LineEnding+
        '[b]'+LineEnding+
        '; hdr b'+LineEnding+
        'name = z'+LineEnding+
        ''+LineEnding;
var Doc: IIniDocument; Err: TIniError; Out1, Out2: RawByteString; Doc2: IIniDocument; Err2: TIniError;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(SRC), Doc, Err));
  Out1 := ToIni(Doc, [iwfSpacesAroundEquals]);
  Err2.Clear;
  AssertTrue(Parse(Out1, Doc2, Err2));
  Out2 := ToIni(Doc2, [iwfSpacesAroundEquals]);
  AssertEquals(NormalizeLF(String(Out1)), NormalizeLF(String(Out2)));
end;

initialization
  RegisterTest(TTestCase_RoundtripVarious);
end.

