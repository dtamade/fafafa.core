program test_oa_tombstone_stress;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.lockfree.hashmap.openAddressing;

procedure AssertTrue(Cond: Boolean; const Msg: string);
begin
  if not Cond then raise Exception.Create('AssertTrue failed: ' + Msg);
end;

procedure AssertFalse(Cond: Boolean; const Msg: string);
begin
  if Cond then raise Exception.Create('AssertFalse failed: ' + Msg);
end;

var
  M: specialize TLockFreeHashMap<Integer, Integer>;
  I, outV: Integer;
  ok: Boolean;
  expectedFree, success: Integer;
begin
  try
    WriteLn('== OA tombstone stress (small capacity) ==');
    M := specialize TLockFreeHashMap<Integer, Integer>.Create(8);
    try
      // 1) Insert a batch
      for I := 0 to 5 do begin
        ok := M.insert(I, I);
        AssertTrue(ok, 'insert I='+IntToStr(I));
      end;
      // 2) Remove even keys -> leave tombstones
      for I := 0 to 5 do if (I and 1)=0 then begin
        ok := M.erase(I);
        AssertTrue(ok, 'erase I='+IntToStr(I));
      end;
      // 3) Ensure deleted keys are not found
      for I := 0 to 5 do if (I and 1)=0 then begin
        AssertFalse(M.find(I, outV), 'find deleted I='+IntToStr(I));
      end;
      // 4) Insert more keys which will have to probe across Deleted slots
      //    Expect up to (capacity - current size) successes, then failures without resize
      //    (FPC no inline var here)
      I := 0;
      // compute expected free slots
      // Note: M.GetSize may change only by our thread here
      success := 0;
      expectedFree := M.GetCapacity - M.GetSize;
      for I := 100 to 105 do begin
        ok := M.insert(I, I);
        if ok then Inc(success);
      end;
      AssertTrue(success = expectedFree, 'insert successes should equal available slots');
      // 5) Capacity pressure: Put upsert and insert until failure appears
      ok := True; I := 200;
      while ok do begin
        ok := M.Put(I, I);
        Inc(I);
        if I>10000 then Break; // safety bound
      end;
      WriteLn('  Final size: ', M.GetSize, ', capacity: ', M.GetCapacity);
      AssertTrue(M.GetSize <= M.GetCapacity, 'size should not exceed capacity');
    finally
      M.Free;
    end;
    WriteLn('.. OK');
  except
    on E: Exception do begin
      WriteLn('FAILED: ', E.Message);
      Halt(1);
    end;
  end;
end.

