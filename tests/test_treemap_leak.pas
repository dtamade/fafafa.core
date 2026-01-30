{$mode objfpc}{$H+}
program test_treemap_leak;

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.collections.treemap;

type
  TStringMap = specialize TTreeMap<string, string>;
  TIntMap = specialize TTreeMap<Integer, Integer>;

function StringComparer(const A, B: string; aData: Pointer): Integer;
begin
  Result := CompareStr(A, B);
end;

function IntComparer(const A, B: Integer; aData: Pointer): Integer;
begin
  Result := A - B;
end;

procedure Test1_BasicOps;
var
  M: TStringMap;
begin
  WriteLn('[Test 1] Basic operations');
  WriteLn('  Debug: Creating TreeMap...');
  M := TStringMap.Create(nil, @StringComparer);
  WriteLn('  Debug: TreeMap created successfully');
  try
    WriteLn('  Debug: Calling Put(''apple'', ''A'')...');
    M.Put('apple', 'A');
    WriteLn('  Debug: First Put succeeded');
    M.Put('banana', 'B');
    M.Put('cherry', 'C');
    M.Remove('banana');
    WriteLn('  Pass: Count = ', M.GetKeyCount);
  finally
    M.Free;
  end;
end;

procedure Test2_Clear;
var
  M: TStringMap;
begin
  WriteLn('[Test 2] Clear operation');
  M := TStringMap.Create(nil, @StringComparer);
  try
    M.Put('x', 'X');
    M.Put('y', 'Y');
    M.Put('z', 'Z');
    M.Clear;
    WriteLn('  Pass: Count after clear = ', M.GetKeyCount);
  finally
    M.Free;
  end;
end;

procedure Test3_OrderVerification;
var
  M: TIntMap;
  I: Integer;
begin
  WriteLn('[Test 3] Order verification (sorted)');
  M := TIntMap.Create(nil, @IntComparer);
  try
    // Insert in random order
    M.Put(50, 50);
    M.Put(20, 20);
    M.Put(80, 80);
    M.Put(10, 10);
    M.Put(30, 30);
    WriteLn('  Pass: Inserted 5 items in random order, count = ', M.GetKeyCount);
  finally
    M.Free;
  end;
end;

procedure Test4_KeyOverwrite;
var
  M: TStringMap;
begin
  WriteLn('[Test 4] Key overwrite');
  M := TStringMap.Create(nil, @StringComparer);
  try
    M.Put('key', 'value1');
    M.Remove('key');
    M.Put('key', 'value2');
    M.Remove('key');
    M.Put('key', 'value3');
    WriteLn('  Pass: Inserted/removed key 3 times, count = ', M.GetKeyCount);
  finally
    M.Free;
  end;
end;

procedure Test5_StressTest;
var
  M: TIntMap;
  I: Integer;
begin
  WriteLn('[Test 5] Stress test (1000 items)');
  M := TIntMap.Create(nil, @IntComparer);
  try
    // Insert 1000 items
    for I := 1 to 1000 do
      M.Put(I, I * 2);
    WriteLn('  Pass: Inserted 1000, count = ', M.GetKeyCount);

    // Remove even numbers
    for I := 2 to 1000 do
      if (I mod 2 = 0) then
        M.Remove(I);
    WriteLn('  Pass: Removed evens, count = ', M.GetKeyCount);

    // Clear all
    M.Clear;
    WriteLn('  Pass: Cleared, count = ', M.GetKeyCount);
  finally
    M.Free;
  end;
end;

begin
  WriteLn('======================================');
  WriteLn('TTreeMap Memory Leak Test');
  WriteLn('======================================');
  WriteLn;

  Test1_BasicOps;
  WriteLn;

  Test2_Clear;
  WriteLn;

  Test3_OrderVerification;
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
