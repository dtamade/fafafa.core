program test_resource_safety_basic;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.lockfree.hashmap.openAddressing,
  fafafa.core.lockfree.hashmap;

procedure AssertTrue(Cond: Boolean; const Msg: string);
begin
  if not Cond then raise Exception.Create('AssertTrue failed: ' + Msg);
end;
function HashStr(const s: string): Cardinal;
var i: SizeInt; res: Cardinal;
begin
  res := 2166136261;
  for i := 1 to Length(s) do begin
    res := res xor Ord(s[i]);
    res := res * 16777619;
  end;
  Result := res;
end;

function EqStr(const a, b: string): Boolean;
begin
  Result := a = b;
end;


var
  OA: specialize TLockFreeHashMap<string, string>;
  MM: specialize TMichaelHashMap<string, string>;
  i: Integer;
  s: string;
begin
  try
    WriteLn('== Resource safety basic (string keys/values) ==');

    // OA: strings upsert/remove/clear
    OA := specialize TLockFreeHashMap<string, string>.Create(64, @HashStr, @EqStr);
    try
      // Fill to capacity with distinct keys
      for i := 1 to OA.GetCapacity do begin
        s := 'k'+IntToStr(i);
        AssertTrue(OA.Put(s, s), 'OA.Put fill i='+IntToStr(i));
      end;
      // Stress upserts on existing keys
      for i := 1 to 2000 do begin
        s := 'k'+IntToStr(1 + (i mod OA.GetCapacity));
        AssertTrue(OA.Put(s, s+'x'+IntToStr(i)), 'OA.Put upsert i='+IntToStr(i));
      end;
      OA.Clear; // finalize managed fields
    finally
      OA.Free; // finalize remaining
    end;

    // MM: strings insert/update/erase
    MM := specialize TMichaelHashMap<string, string>.Create(64, @DefaultStringHash, @DefaultStringComparer);
    try
      for i := 1 to 2000 do begin
        s := 'k'+IntToStr(i);
        AssertTrue(MM.insert(s, s), 'MM.insert i='+IntToStr(i));
        AssertTrue(MM.update(s, s+'x'), 'MM.update i='+IntToStr(i));
      end;
      for i := 1 to 2000 do begin
        s := 'k'+IntToStr(i);
        AssertTrue(MM.erase(s), 'MM.erase i='+IntToStr(i));
      end;
      // clear should deallocate logically deleted entries
      MM.clear;
    finally
      MM.Free;
    end;

    WriteLn('.. OK');
  except
    on E: Exception do begin
      WriteLn('FAILED: ', E.Message);
      Halt(1);
    end;
  end;
end.

