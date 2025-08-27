{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_entries_dirty_behavior;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_EntriesDirty = class(TTestCase)
  published
    procedure Test_ToIni_UsesEntries_When_NotDirty;
    procedure Test_ToIni_IgnoresEntries_When_Dirty;
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

procedure TTestCase_EntriesDirty.Test_ToIni_UsesEntries_When_NotDirty;
const
  SRC = ';prelude'+LineEnding+
        ''+LineEnding+
        '[sec]'+LineEnding+
        '; hdr'+LineEnding+
        'k=v'+LineEnding+
        ''+LineEnding;
var Doc: IIniDocument; Err: TIniError; Out1, Out2: RawByteString; Doc2: IIniDocument; Err2: TIniError;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(SRC), Doc, Err));
  // not dirty
  Out1 := ToIni(Doc, []);
  Err2.Clear;
  AssertTrue(Parse(Out1, Doc2, Err2));
  Out2 := ToIni(Doc2, []);
  AssertEquals(NormalizeLF(String(Out1)), NormalizeLF(String(Out2)));
end;

procedure TTestCase_EntriesDirty.Test_ToIni_IgnoresEntries_When_Dirty;
const
  SRC = '[sec]'+LineEnding+
        'k=v'+LineEnding;
var Doc: IIniDocument; Err: TIniError; Out1, Out2: RawByteString;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(SRC), Doc, Err));
  // dirty by modifying a key
  SetString(Doc, 'sec', 'k', 'changed');
  Out1 := ToIni(Doc, [iwfSpacesAroundEquals]);
  // should reflect modification (spaces around equals), not original entries
  AssertTrue(Pos('k = changed', String(Out1)) > 0);
end;

initialization
  RegisterTest(TTestCase_EntriesDirty);
end.

