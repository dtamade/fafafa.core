{$mode objfpc}{$H+}
program test_hashset_leak;

uses
  SysUtils,
  fafafa.core.collections.hashmap;

type
  TStringSet = specialize THashSet<string>;
  TIntSet = specialize THashSet<Integer>;

procedure Test1_BasicOps;
var
  S: TStringSet;
begin
  WriteLn('[Test 1] Basic operations');
  S := TStringSet.Create;
  try
    S.Add('apple');
    S.Add('banana');
    S.Add('cherry');
    S.Remove('banana');
    WriteLn('  Pass: Count = ', S.Count);
  finally
    S.Free;
  end;
end;

procedure Test2_Clear;
var
  S: TStringSet;
begin
  WriteLn('[Test 2] Clear operation');
  S := TStringSet.Create;
  try
    S.Add('x');
    S.Add('y');
    S.Add('z');
    S.Clear;
    WriteLn('  Pass: Count after clear = ', S.Count);
  finally
    S.Free;
  end;
end;

procedure Test3_Contains;
var
  S: TIntSet;
  i: Integer;
begin
  WriteLn('[Test 3] Contains check');
  S := TIntSet.Create;
  try
    for i := 1 to 50 do
      S.Add(i * 2);  // even numbers

    WriteLn('  Contains 10: ', S.Contains(10));
    WriteLn('  Contains 15: ', S.Contains(15));
    WriteLn('  Pass: Count = ', S.Count);
  finally
    S.Free;
  end;
end;

procedure Test4_DuplicateAdd;
var
  S: TStringSet;
begin
  WriteLn('[Test 4] Duplicate add');
  S := TStringSet.Create;
  try
    S.Add('key');
    S.Add('key');
    S.Add('key');
    WriteLn('  Pass: Count after duplicates = ', S.Count, ' (should be 1)');
  finally
    S.Free;
  end;
end;

procedure Test5_StressTest;
var
  S: TIntSet;
  i: Integer;
begin
  WriteLn('[Test 5] Stress test (1000 items)');
  S := TIntSet.Create;
  try
    for i := 1 to 1000 do
      S.Add(i);

    WriteLn('  Pass: Inserted 1000, count = ', S.Count);

    for i := 2 to 1000 do
      if (i mod 2) = 0 then
        S.Remove(i);

    WriteLn('  Pass: Removed evens, count = ', S.Count);

    S.Clear;
    WriteLn('  Pass: Cleared, count = ', S.Count);
  finally
    S.Free;
  end;
end;

begin
  WriteLn('======================================');
  WriteLn('HashSet Memory Leak Detection Test');
  WriteLn('======================================');
  WriteLn;

  try
    Test1_BasicOps;
    WriteLn;
    Test2_Clear;
    WriteLn;
    Test3_Contains;
    WriteLn;
    Test4_DuplicateAdd;
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
