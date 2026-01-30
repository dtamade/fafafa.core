{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_entries_cases;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_EntriesCases = class(TTestCase)
  published
    procedure Test_InterSection_Comments_And_Blanks_Roundtrip;
    procedure Test_Empty_Sections_Preserved;
    procedure Test_Consecutive_Blanks_Roundtrip;
    procedure Test_Dirty_Overrides_BodyLines;
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

procedure TTestCase_EntriesCases.Test_InterSection_Comments_And_Blanks_Roundtrip;
const
  SRC = '; prelude a'+LineEnding+
        ''+LineEnding+
        '[a]'+LineEnding+
        'x=1'+LineEnding+
        ''+LineEnding+
        '; between sections'+LineEnding+
        ''+LineEnding+
        '[b]'+LineEnding+
        '; hdr b'+LineEnding+
        'y=2'+LineEnding;
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

procedure TTestCase_EntriesCases.Test_Empty_Sections_Preserved;
const
  SRC = '[a]'+LineEnding+
        ''+LineEnding+
        '[b]'+LineEnding+
        ''+LineEnding+
        '[c]'+LineEnding;
var Doc: IIniDocument; Err: TIniError; Out1: RawByteString;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(SRC), Doc, Err));
  Out1 := ToIni(Doc, []);
  // 保留三个节头与空行
  AssertTrue(Pos('[a]', String(Out1)) > 0);
  AssertTrue(Pos('[b]', String(Out1)) > 0);
  AssertTrue(Pos('[c]', String(Out1)) > 0);
end;

procedure TTestCase_EntriesCases.Test_Consecutive_Blanks_Roundtrip;
const
  SRC = '[a]'+LineEnding+
        ''+LineEnding+
        ''+LineEnding+
        'x=1'+LineEnding+
        ''+LineEnding+
        ''+LineEnding+
        '[b]'+LineEnding+
        ''+LineEnding+
        'y=2'+LineEnding+
        ''+LineEnding;
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

procedure TTestCase_EntriesCases.Test_Dirty_Overrides_BodyLines;
const
  SRC = '[a]'+LineEnding+
        'x=1'+LineEnding+
        '; cmt to create BodyLines'+LineEnding+
        ''+LineEnding+
        '[b]'+LineEnding+
        'y=2'+LineEnding;
var Doc: IIniDocument; Err: TIniError; Out1: RawByteString;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(SRC), Doc, Err));
  // 修改后应忽略 BodyLines，按键重组（应用写出策略）
  SetInt(Doc, 'a', 'x', 42);
  Out1 := ToIni(Doc, [iwfSpacesAroundEquals]);
  AssertTrue(Pos('x = 42', String(Out1)) > 0);
end;

initialization
  RegisterTest(TTestCase_EntriesCases);
end.

