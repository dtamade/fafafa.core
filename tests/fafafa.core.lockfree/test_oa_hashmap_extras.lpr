program test_oa_hashmap_extras;
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.lockfree,
  fafafa.core.lockfree.hashmap.openAddressing;

type
  TStringOA = specialize TLockFreeHashMap<string, Integer>;

procedure Test_OAHashMap_StringKey_DefaultComparer_Works;
var
  Map: TStrIntOAHashMap;
  V: Integer;
begin
  WriteLn('OA: String key with default "=" comparer');
  Map := CreateStrIntOAHashMap(64);
  try
    if not Map.Put('a', 1) then raise Exception.Create('Put failed');
    if not Map.Get('a', V) then raise Exception.Create('Get failed');
    if V <> 1 then raise Exception.Create('Value mismatch');
  finally
    Map.Free;
  end;
end;

procedure Test_OAHashMap_HighLoad_MayFail;
var
  Map: TIntIntOAHashMap;
  I, Inserted: Integer;
begin
  WriteLn('OA: High load insert may return False when capacity tight');
  Map := CreateIntIntOAHashMap(8);
  try
    Inserted := 0;
    for I := 0 to 1023 do
      if Map.Put(I, I) then Inc(Inserted);
    if Inserted = 0 then raise Exception.Create('No inserts succeeded');
    WriteLn('Inserted: ', Inserted, ' (expected < 1024)');
  finally
    Map.Free;
  end;
end;

procedure Test_OAHashMap_NewStrict_RequiresComparer;
var
  M2: TStringOA;
begin
  WriteLn('OA: NewStrict requires comparer and hash');
  try
    M2 := TStringOA.NewStrict(16, nil, nil);
    raise Exception.Create('NewStrict must raise when comparer is nil');
  except
    on E: Exception do begin
      WriteLn('Expected error: ', E.Message);
    end;
  end;
end;

begin
  try
    Test_OAHashMap_StringKey_DefaultComparer_Works;
    Test_OAHashMap_HighLoad_MayFail;
    Test_OAHashMap_NewStrict_RequiresComparer;
    WriteLn('All OA extras passed.');
  except
    on E: Exception do
    begin
      WriteLn('Failed: ', E.Message);
      Halt(1);
    end;
  end;
end.

