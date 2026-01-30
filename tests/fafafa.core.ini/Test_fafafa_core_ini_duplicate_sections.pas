{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_duplicate_sections;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_DuplicateSections = class(TTestCase)
  published
    procedure Test_DuplicateSections_Roundtrip_NotDirty_Preserves_Headers;
    procedure Test_DuplicateSections_Reassemble_Dirty_Merges_Once;
  end;

implementation

function CountOccurrences(const S, Sub: String): Integer;
var p, cnt: Integer;
begin
  p := 1; cnt := 0;
  while p <= Length(S) do
  begin
    p := Pos(Sub, S, p);
    if p = 0 then Break;
    Inc(cnt);
    Inc(p, Length(Sub));
  end;
  Result := cnt;
end;

procedure TTestCase_DuplicateSections.Test_DuplicateSections_Roundtrip_NotDirty_Preserves_Headers;
var Doc: IIniDocument; Err: TIniError; Inp, Outp: RawByteString;
begin
  Inp := RawByteString('[s]'#10'; c1'#10'a=1'#10#10'[s]'#10'; c2'#10'b=2'#10);
  AssertTrue(Parse(Inp, Doc, Err));
  // 未修改：应回放原始文本，包含两个 [s] 节头
  Outp := ToIni(Doc, [iwfForceLF]);
  AssertEquals(String(Inp), String(Outp));
  AssertEquals(2, CountOccurrences(String(Outp), '[s]'));
end;

procedure TTestCase_DuplicateSections.Test_DuplicateSections_Reassemble_Dirty_Merges_Once;
var Doc: IIniDocument; Err: TIniError; Outp: RawByteString;
begin
  AssertTrue(Parse(RawByteString('[s]'#10'a=1'#10#10'[s]'#10'b=2'#10), Doc, Err));
  // 修改：触发 Dirty 路径，重组输出；应只出现一个 [s]，且键合并
  SetString(Doc, 's', 'c', '3');
  Outp := ToIni(Doc, [iwfForceLF, iwfStableKeyOrder]);
  AssertEquals(1, CountOccurrences(String(Outp), '[s]'));
  AssertTrue(Pos('a=1', String(Outp))>0);
  AssertTrue(Pos('b=2', String(Outp))>0);
  AssertTrue(Pos('c=3', String(Outp))>0);
end;

initialization
  RegisterTest(TTestCase_DuplicateSections);
end.

