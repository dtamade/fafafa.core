program bench_map_str_key;
{$mode objfpc}{$H+}

uses
  SysUtils, DateUtils,
  fafafa.core.lockfree,
  fafafa.core.lockfree.hashmap,
  fafafa.core.lockfree.hashmap.openAddressing;

function NowNs: Int64;
var ts: TSystemTime; begin DatetimeToSystemTime(Now, ts); Result := MilliSecondOf(Now) * 1000000; end;

function StrHash(const S: string): Cardinal;
const
  FNV_offset_basis = Cardinal($811C9DC5);
  FNV_prime = Cardinal(16777619);
var i: SizeInt; p: PAnsiChar;
begin
  Result := FNV_offset_basis;
  if Length(S) = 0 then Exit;
  p := PAnsiChar(S);
  for i := 1 to Length(S) do begin Result := Result xor Ord(p^); Result := Result * FNV_prime; Inc(p); end;
end;

function StrEqual(const L, R: string): Boolean; begin Exit(L = R); end;

procedure Bench(const Title, ModeLabel: string; const NKeys, Iter: Integer; UseOAWithStrHash, AsCSV: Boolean);
var
  Keys: array of string;
  i, j, v: Integer;
  t0, t1: QWord;
  MM: specialize TMichaelHashMap<string, Integer>;
  OA: specialize TLockFreeHashMap<string, Integer>;
begin
  SetLength(Keys, NKeys);
  for i := 0 to NKeys-1 do Keys[i] := 'key_' + IntToStr(i);

  if UseOAWithStrHash then OA := specialize TLockFreeHashMap<string,Integer>.Create(NKeys*2, @StrHash, @StrEqual)
  else MM := specialize TMichaelHashMap<string,Integer>.Create(NKeys*2, @DefaultStringHash, @DefaultStringComparer);

  t0 := GetTickCount64;
  for j := 1 to Iter do begin
    // 写入
    for i := 0 to NKeys-1 do begin
      if UseOAWithStrHash then OA.Put(Keys[i], i) else MM.insert(Keys[i], i);
    end;
    // 读取
    for i := 0 to NKeys-1 do begin
      if UseOAWithStrHash then OA.Get(Keys[i], v) else MM.find(Keys[i], v);
    end;
  end;
  t1 := GetTickCount64;

  if AsCSV then
    WriteLn(Format('%s,%d,%d,%d', [ModeLabel, NKeys, Iter, t1 - t0]))
  else
    WriteLn(Format('%s: NKeys=%d Iter=%d Time(ms)=%d', [Title, NKeys, Iter, t1 - t0]));
end;

function GetArgValue(const Prefix: string; const DefaultVal: string): string;
var i, L: Integer; s: string;
begin
  L := Length(Prefix);
  for i := 1 to ParamCount do begin
    s := ParamStr(i);
    if (Length(s) > L) and (Copy(s,1,L) = Prefix) then Exit(Copy(s, L+1, MaxInt));
  end;
  Exit(DefaultVal);
end;

function HasFlag(const Flag: string): Boolean;
var i: Integer;
begin
  for i := 1 to ParamCount do if SameText(ParamStr(i), Flag) then Exit(True);
  Exit(False);
end;

procedure Run;
var
  NKeys, Iter: Integer;
  Mode: string;
  AsCSV: Boolean;
begin
  Val(GetArgValue('--nkeys=', '20000'), NKeys);
  Val(GetArgValue('--iter=', '3'), Iter);
  Mode := LowerCase(GetArgValue('--mode=', 'both')); // both|mm|oa
  AsCSV := HasFlag('--csv');

  if AsCSV then WriteLn('mode,nkeys,iter,time_ms');

  if (Mode = 'mm') or (Mode = 'both') then
    Bench('MM(string) baseline','mm', NKeys, Iter, False, AsCSV);
  if (Mode = 'oa') or (Mode = 'both') then
    Bench('OA(string)+StrHash','oa', NKeys, Iter, True, AsCSV);
end;

begin
  Run;
end.

