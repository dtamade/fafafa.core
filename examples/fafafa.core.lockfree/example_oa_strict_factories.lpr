program example_oa_strict_factories;
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.lockfree,
  fafafa.core.lockfree.hashmap.openAddressing;

type
  TKey = record A, B: Integer; end;

function HashCI(const S: string): Cardinal; inline;
begin
  Result := fafafa.core.lockfree.SimpleHash(UpperCase(S)[1], Length(S));
end;

function EqCI(const L, R: string): Boolean; inline;
begin
  Result := SameText(L, R);
end;

function HashKey(const K: TKey): Cardinal; inline;
begin
  Result := fafafa.core.lockfree.SimpleHash(K, SizeOf(TKey));
end;

function EqKey(const L, R: TKey): Boolean; inline;
begin
  Result := (L.A = R.A) and (L.B = R.B);
end;

var
  M1: TStrIntOAHashMap;
  M2: specialize TLockFreeHashMap<TKey, Integer>;
  V: Integer; K: TKey;
begin
  WriteLn('OA Strict factories demo...');

  // 严格工厂（门面层）：字符串键大小写不敏感
  M1 := CreateStrIntOAHashMapStrict(128, @HashCI, @EqCI);
  try
    M1.Put('Abc', 1);
    if M1.Get('abc', V) then
      WriteLn('M1[abc] = ', V);
  finally
    M1 := nil;
  end;

  // 严格工厂（类型方法）：记录键
  M2 := specialize TLockFreeHashMap<TKey, Integer>.NewStrict(128, @HashKey, @EqKey);
  try
    K.A := 7; K.B := 9;
    M2.Put(K, 42);
    if M2.Get(K, V) then
      WriteLn('M2[{7,9}] = ', V);
  finally
    M2 := nil;
  end;

  WriteLn('Done.');
end.

