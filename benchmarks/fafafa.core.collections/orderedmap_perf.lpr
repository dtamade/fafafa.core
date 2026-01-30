{$CODEPAGE UTF8}
program orderedmap_perf;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$UNITPATH ../../src}

uses
  SysUtils,
  fafafa.core.collections.orderedmap.rb,
  fafafa.core.collections.base;

type
  TStrIntMap = specialize TRBTreeMap<string,Integer>;

function CaseInsensitiveCompare(const L, R: string; aData: Pointer): SizeInt;
begin
  Result := CompareText(L, R);
  if Result < 0 then Exit(-1) else if Result > 0 then Exit(1) else Exit(0);
end;

const N = 20000;
var M: TStrIntMap; i: Integer; t1, t2: QWord;
begin
  M := TStrIntMap.Create(@CaseInsensitiveCompare);
  try
    for i := 1 to N do M.TryAdd(IntToStr(i), i);
    t1 := GetTickCount64; for i := 1 to N do M.TryAdd(IntToStr(i), i); t1 := GetTickCount64 - t1;
    t2 := GetTickCount64; for i := 1 to N do M.InsertOrAssign(IntToStr(i), i); t2 := GetTickCount64 - t2;
    WriteLn('[orderedmap] TryAdd-hit(ms)=', t1, ' InsertOrAssign-update(ms)=', t2);
  finally
    M.Free;
  end;
end.

