{$mode objfpc}{$H+}
program test_hashmap_leak;

uses
  SysUtils,
  fafafa.core.collections.hashmap;

type
  TStringMap = specialize THashMap<string, string>;
  TIntMap = specialize THashMap<Integer, Integer>;

procedure Test1_BasicOps;
var
  M: TStringMap;
begin
  WriteLn('[Test 1] Basic operations');
  M := TStringMap.Create;
  try
    M.AddOrAssign('a', 'A');
    M.AddOrAssign('b', 'B');
    M.Remove('a');
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

procedure Test3_Rehash;
var
  M: TIntMap;
  i: Integer;
begin
  WriteLn('[Test 3] Rehash (trigger resize)');
  M := TIntMap.Create;
  try
    for i := 1 to 100 do
      M.AddOrAssign(i, i * 2);
    WriteLn('  Pass: Added 100 items, count = ', M.Count);
    
    for i := 1 to 50 do
      M.Remove(i);
    WriteLn('  Pass: Removed 50 items, count = ', M.Count);
  finally
    M.Free;
  end;
end;

procedure Test4_Overwrite;
var
  M: TStringMap;
begin
  WriteLn('[Test 4] Overwrite keys');
  M := TStringMap.Create;
  try
    M.AddOrAssign('key', 'v1');
    M.AddOrAssign('key', 'v2');
    M.AddOrAssign('key', 'v3');
    WriteLn('  Pass: Count after overwrites = ', M.Count);
  finally
    M.Free;
  end;
end;

procedure Test5_StressTest;
var
  M: TStringMap;
  i: Integer;
begin
  WriteLn('[Test 5] Stress test (1000 items)');
  M := TStringMap.Create;
  try
    for i := 1 to 1000 do
      M.AddOrAssign('k' + IntToStr(i), 'v' + IntToStr(i));
    WriteLn('  Pass: Inserted 1000, count = ', M.Count);
    
    for i := 2 to 1000 do
      if (i mod 2) = 0 then
        M.Remove('k' + IntToStr(i));
    WriteLn('  Pass: Removed evens, count = ', M.Count);
    
    M.Clear;
    WriteLn('  Pass: Cleared, count = ', M.Count);
  finally
    M.Free;
  end;
end;

begin
  WriteLn('======================================');
  WriteLn('HashMap Memory Leak Detection Test');
  WriteLn('======================================');
  WriteLn;
  
  try
    Test1_BasicOps;
    WriteLn;
    Test2_Clear;
    WriteLn;
    Test3_Rehash;
    WriteLn;
    Test4_Overwrite;
    WriteLn;
    Test5_StressTest;
    WriteLn;
    
    WriteLn('======================================');
    WriteLn('All tests completed!');
    WriteLn('Check below for memory leak report:');
    WriteLn('Look for "0 unfreed memory blocks"');
    WriteLn('======================================');
  except
    on E: Exception do
    begin
      WriteLn('ERROR: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
