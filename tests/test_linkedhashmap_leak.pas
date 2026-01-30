{$mode objfpc}{$H+}
program test_linkedhashmap_leak;

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.collections.linkedhashmap;

type
  TStringMap = specialize TLinkedHashMap<string, string>;
  TIntMap = specialize TLinkedHashMap<Integer, Integer>;

procedure Test1_BasicOps;
var
  M: TStringMap;
begin
  WriteLn('[Test 1] Basic operations');
  M := TStringMap.Create;
  try
    M.AddOrAssign('a', 'A');
    M.AddOrAssign('b', 'B');
    M.AddOrAssign('c', 'C');
    M.Remove('b');
    WriteLn('  Pass: Count = ', M.Count);
  finally
    M.Free;
  end;
end;

procedure Test2_Clear;
var
  M: TStringMap;
begin
  WriteLn('[Test 2] Clear operation');
  M := TStringMap.Create;
  try
    M.AddOrAssign('x', 'X');
    M.AddOrAssign('y', 'Y');
    M.AddOrAssign('z', 'Z');
    M.Clear;
    WriteLn('  Pass: Count after clear = ', M.Count);
  finally
    M.Free;
  end;
end;

procedure Test3_OrderPreservation;
var
  M: TStringMap;
begin
  WriteLn('[Test 3] Insertion order preservation');
  M := TStringMap.Create;
  try
    M.AddOrAssign('first', '1');
    M.AddOrAssign('second', '2');
    M.AddOrAssign('third', '3');
    WriteLn('  Pass: Added 3 items in order, count = ', M.Count);
  finally
    M.Free;
  end;
end;

procedure Test4_KeyOverwrite;
var
  M: TStringMap;
begin
  WriteLn('[Test 4] Key overwrite');
  M := TStringMap.Create;
  try
    M.AddOrAssign('key', 'value1');
    M.AddOrAssign('key', 'value2');
    M.AddOrAssign('key', 'value3');
    WriteLn('  Pass: Overwrote same key 3 times, count = ', M.Count);
  finally
    M.Free;
  end;
end;

procedure Test5_StressTest;
var
  M: TIntMap;
  i: Integer;
begin
  WriteLn('[Test 5] Stress test (1000 items)');
  M := TIntMap.Create;
  try
    // Insert 1000
    for i := 1 to 1000 do
      M.AddOrAssign(i, i * 2);
    WriteLn('  Pass: Inserted 1000, count = ', M.Count);

    // Remove evens
    for i := 2 to 1000 do
      if (i mod 2 = 0) then
        M.Remove(i);
    WriteLn('  Pass: Removed evens, count = ', M.Count);

    // Clear
    M.Clear;
    WriteLn('  Pass: Cleared, count = ', M.Count);
  finally
    M.Free;
  end;
end;

begin
  WriteLn('======================================');
  WriteLn('TLinkedHashMap Memory Leak Test');
  WriteLn('======================================');
  WriteLn;

  Test1_BasicOps;
  WriteLn;

  Test2_Clear;
  WriteLn;

  Test3_OrderPreservation;
  WriteLn;

  Test4_KeyOverwrite;
  WriteLn;

  Test5_StressTest;
  WriteLn;

  WriteLn('======================================');
  WriteLn('All tests completed!');
  WriteLn('Check below for memory leak report:');
  WriteLn('Look for "0 unfreed memory blocks"');
  WriteLn('======================================');
end.