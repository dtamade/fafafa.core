program vec_bench_ext;

{$mode objfpc}{$H+}
{$I ../../fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.vec;

function ParseUIntDef(const S, Key: string; Def: QWord): QWord;
var p: SizeInt; v: string;
begin
  p := Pos(Key + '=', S);
  if p = 0 then Exit(Def);
  v := Copy(S, p + Length(Key) + 1, MaxInt);
  Result := StrToQWordDef(v, Def);
end;

function HasFlag(const Key: string): Boolean;
var i: Integer;
begin
  Result := False;
  for i := 1 to ParamCount do
    if (ParamStr(i) = Key) then Exit(True);
end;

function GetArgValueDef(const Key: string; Def: string): string;
var i, p: Integer; s: string;
begin
  for i := 1 to ParamCount do
  begin
    s := ParamStr(i);
    p := Pos(Key + '=', s);
    if p = 1 then Exit(Copy(s, Length(Key) + 2, MaxInt));
  end;
  Result := Def;
end;

procedure CSVPrint(const CaseName: string; Aligned: Boolean; AlignElem: QWord; N, Ms, FinalCap: QWord);
begin
  Writeln(Format('%s,%s,%d,%d,%d,%d',
    [CaseName, IfThen(Aligned, 'aligned', 'default'), AlignElem, N, Ms, FinalCap]));
end;

function BenchPushInt(const aName: string; aCount: SizeUInt; aAligned: Boolean; aAlignElems: SizeUInt; aCSV: Boolean): QWord;
var
  i: SizeUInt;
  t0, t1: QWord;
  v: specialize TVec<Integer>;
begin
  v := specialize TVec<Integer>.Create;
  try
    if aAligned then v.EnableAlignedGrowth(aAlignElems);
    t0 := GetTickCount64;
    for i := 0 to aCount - 1 do
      v.Push(Integer(i));
    t1 := GetTickCount64;
    Result := t1 - t0;
    if aCSV then CSVPrint(aName, aAligned, aAlignElems, aCount, Result, v.Capacity)
    else Writeln(Format('%s: count=%d capacity=%d elapsed_ms=%d',
      [aName, v.Count, v.Capacity, Result]));
  finally
    v.Free;
  end;
end;

function BenchInsertFrontInt(const aName: string; aCount: SizeUInt; aAligned: Boolean; aAlignElems: SizeUInt; aCSV: Boolean): QWord;
var
  i: SizeUInt;
  t0, t1: QWord;
  v: specialize TVec<Integer>;
begin
  v := specialize TVec<Integer>.Create;
  try
    if aAligned then v.EnableAlignedGrowth(aAlignElems);
    t0 := GetTickCount64;
    for i := 0 to aCount - 1 do
      v.Insert(0, @i, 1);
    t1 := GetTickCount64;
    Result := t1 - t0;
    if aCSV then CSVPrint(aName, aAligned, aAlignElems, aCount, Result, v.Capacity)
    else Writeln(Format('%s: count=%d capacity=%d elapsed_ms=%d',
      [aName, v.Count, v.Capacity, Result]));
  finally
    v.Free;
  end;
end;

function BenchInsertMidInt(const aName: string; aCount: SizeUInt; aAligned: Boolean; aAlignElems: SizeUInt; aCSV: Boolean): QWord;
var
  i: SizeUInt;
  t0, t1: QWord;
  v: specialize TVec<Integer>;
  idx: SizeUInt;
begin
  v := specialize TVec<Integer>.Create;
  try
    if aAligned then v.EnableAlignedGrowth(aAlignElems);
    t0 := GetTickCount64;
    for i := 0 to aCount - 1 do
    begin
      if v.Count = 0 then idx := 0 else idx := v.Count div 2;
      v.Insert(idx, @i, 1);
    end;
    t1 := GetTickCount64;
    Result := t1 - t0;
    if aCSV then CSVPrint(aName, aAligned, aAlignElems, aCount, Result, v.Capacity)
    else Writeln(Format('%s: count=%d capacity=%d elapsed_ms=%d',
      [aName, v.Count, v.Capacity, Result]));
  finally
    v.Free;
  end;
end;

var
  n, alignElems: QWord;
  csv: Boolean;
  cases: string;
begin
  n := 500000;
  alignElems := 64;
  csv := False;
  cases := 'all';

  // parse args
  if ParamCount > 0 then
  begin
    // allow forms: --n=, --aligned-elements=, --cases=push|insert_front|insert_mid|all, --csv
    n := StrToQWordDef(GetArgValueDef('--n', UIntToStr(n)), n);
    alignElems := StrToQWordDef(GetArgValueDef('--aligned-elements', UIntToStr(alignElems)), alignElems);
    cases := GetArgValueDef('--cases', cases);
    csv := HasFlag('--csv');
  end;

  if not csv then
  begin
    Writeln('==== TVec benchmarks (Integer) ====');
    Writeln(Format('n=%d, aligned-elements=%d', [n, alignElems]));
  end
  else
    Writeln('case,mode,align_elems,n,elapsed_ms,final_capacity');

  if (cases = 'push') or (cases = 'all') then
  begin
    BenchPushInt('push/default(1.5x)', n, False, alignElems, csv);
    BenchPushInt('push/aligned(1.5x+aligned)', n, True, alignElems, csv);
  end;

  if (cases = 'insert_front') or (cases = 'all') then
  begin
    BenchInsertFrontInt('insert_front/default(1.5x)', n div 10, False, alignElems, csv);
    BenchInsertFrontInt('insert_front/aligned(1.5x+aligned)', n div 10, True, alignElems, csv);
  end;

  if (cases = 'insert_mid') or (cases = 'all') then
  begin
    BenchInsertMidInt('insert_mid/default(1.5x)', n div 10, False, alignElems, csv);
    BenchInsertMidInt('insert_mid/aligned(1.5x+aligned)', n div 10, True, alignElems, csv);
  end;
end.

