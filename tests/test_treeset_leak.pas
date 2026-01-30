{$mode objfpc}{$H+}
program test_treeset_leak;

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.collections.treeSet;

type
  TStringSet = specialize TTreeSet<string>;
  TIntSet = specialize TTreeSet<Integer>;

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
    WriteLn('  Pass: Count = ', S.GetCount);
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
    WriteLn('  Pass: Count after clear = ', S.GetCount);
  finally
    S.Free;
  end;
end;

procedure Test3_SetOperations;
var
  S1, S2: TStringSet;
  SUnion, SIntersect, SDiff: specialize ITreeSet<string>;  // 使用接口类型
begin
  WriteLn('[Test 3] Set operations (Union/Intersect/Difference)');
  S1 := TStringSet.Create;
  S2 := TStringSet.Create;
  try
    S1.Add('a');
    S1.Add('b');
    S1.Add('c');

    S2.Add('b');
    S2.Add('c');
    S2.Add('d');

    SUnion := S1.Union(S2);
    WriteLn('  Pass: Union count = ', SUnion.GetCount);

    SIntersect := S1.Intersect(S2);
    WriteLn('  Pass: Intersect count = ', SIntersect.GetCount);

    SDiff := S1.Difference(S2);
    WriteLn('  Pass: Difference count = ', SDiff.GetCount);
  finally
    S2.Free;
    S1.Free;
  end;
end;

procedure Test4_DuplicateHandling;
var
  S: TIntSet;
begin
  WriteLn('[Test 4] Duplicate handling');
  S := TIntSet.Create;
  try
    S.Add(1);
    S.Add(2);
    S.Add(1);  // Duplicate
    S.Add(2);  // Duplicate
    S.Add(3);
    WriteLn('  Pass: Count (should be 3) = ', S.GetCount);
  finally
    S.Free;
  end;
end;

procedure Test5_StressTest;
var
  S: TIntSet;
  I: Integer;
begin
  WriteLn('[Test 5] Stress test (1000 items)');
  S := TIntSet.Create;
  try
    // Insert 1000 items
    for I := 1 to 1000 do
      S.Add(I);
    WriteLn('  Pass: Inserted 1000, count = ', S.GetCount);

    // Remove even numbers
    for I := 2 to 1000 do
      if (I mod 2 = 0) then
        S.Remove(I);
    WriteLn('  Pass: Removed evens, count = ', S.GetCount);

    // Clear all
    S.Clear;
    WriteLn('  Pass: Cleared, count = ', S.GetCount);
  finally
    S.Free;
  end;
end;

begin
  WriteLn('======================================');
  WriteLn('TTreeSet Memory Leak Test');
  WriteLn('======================================');
  WriteLn;

  Test1_BasicOps;
  WriteLn;

  Test2_Clear;
  WriteLn;

  Test3_SetOperations;
  WriteLn;

  Test4_DuplicateHandling;
  WriteLn;

  Test5_StressTest;
  WriteLn;

  WriteLn('======================================');
  WriteLn('All tests completed!');
  WriteLn('Check below for memory leak report:');
  WriteLn('Look for "0 unfreed memory blocks"');
  WriteLn('======================================');
end.