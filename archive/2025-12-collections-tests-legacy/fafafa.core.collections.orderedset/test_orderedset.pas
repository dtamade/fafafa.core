program test_orderedset;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.collections.orderedset;

type
  TIntSet = specialize TOrderedSet<Integer>;
  TStringSet = specialize TOrderedSet<String>;

var
  TestsPassed: Integer = 0;
  TestsFailed: Integer = 0;

procedure Assert(aCondition: Boolean; const aMessage: String);
begin
  if aCondition then
  begin
    Inc(TestsPassed);
    WriteLn('  ✓ ', aMessage);
  end
  else
  begin
    Inc(TestsFailed);
    WriteLn('  ✗ FAILED: ', aMessage);
  end;
end;

{=== 基本操作测试 ===}

procedure TestBasicOperations;
var
  S: TIntSet;
begin
  WriteLn('[Test] Basic Operations');
  S := TIntSet.Create;
  try
    // 初始状态
    Assert(S.IsEmpty, 'New set should be empty');
    Assert(S.Count = 0, 'New set count should be 0');

    // Add操作
    Assert(S.Add(1), 'First add should return True');
    Assert(S.Count = 1, 'Count should be 1');
    Assert(not S.IsEmpty, 'Set should not be empty');

    // 重复添加
    Assert(not S.Add(1), 'Adding duplicate should return False');
    Assert(S.Count = 1, 'Count should still be 1');

    // Contains
    Assert(S.Contains(1), 'Set should contain 1');
    Assert(not S.Contains(99), 'Set should not contain 99');

    // 添加更多元素
    S.Add(2);
    S.Add(3);
    Assert(S.Count = 3, 'Count should be 3');

    // Remove
    Assert(S.Remove(2), 'Remove existing element should return True');
    Assert(S.Count = 2, 'Count should be 2 after remove');
    Assert(not S.Remove(99), 'Remove non-existent should return False');

    // Clear
    S.Clear;
    Assert(S.IsEmpty, 'Set should be empty after clear');
    Assert(S.Count = 0, 'Count should be 0 after clear');

  finally
    S.Free;
  end;
end;

{=== 插入顺序测试 ===}

procedure TestInsertionOrder;
var
  S: TIntSet;
  Arr: array of Integer;
begin
  WriteLn('[Test] Insertion Order');
  S := TIntSet.Create;
  try
    // 按特定顺序添加
    S.Add(5);
    S.Add(1);
    S.Add(9);
    S.Add(3);

    // 转换为数组检查顺序
    Arr := S.ToArray;
    Assert(Length(Arr) = 4, 'Array length should be 4');
    Assert(Arr[0] = 5, 'First element should be 5');
    Assert(Arr[1] = 1, 'Second element should be 1');
    Assert(Arr[2] = 9, 'Third element should be 9');
    Assert(Arr[3] = 3, 'Fourth element should be 3');

    // First/Last
    Assert(S.First = 5, 'First should return 5');
    Assert(S.Last = 3, 'Last should return 3');

    // GetAt
    Assert(S.GetAt(0) = 5, 'GetAt(0) should be 5');
    Assert(S.GetAt(1) = 1, 'GetAt(1) should be 1');
    Assert(S.GetAt(2) = 9, 'GetAt(2) should be 9');
    Assert(S.GetAt(3) = 3, 'GetAt(3) should be 3');

  finally
    S.Free;
  end;
end;

{=== 集合运算测试 ===}

procedure TestSetOperations;
var
  S1, S2: TIntSet;
  Arr: array of Integer;
begin
  WriteLn('[Test] Set Operations');

  // Union测试
  S1 := TIntSet.Create;
  S2 := TIntSet.Create;
  try
    S1.Add(1);
    S1.Add(2);
    S1.Add(3);

    S2.Add(3);
    S2.Add(4);
    S2.Add(5);

    S1.Union(S2);  // S1 = {1,2,3,4,5}
    Assert(S1.Count = 5, 'Union should have 5 elements');
    Assert(S1.Contains(1), 'Union should contain 1');
    Assert(S1.Contains(5), 'Union should contain 5');

    // 检查顺序：原有元素保持顺序，新元素追加
    Arr := S1.ToArray;
    Assert(Arr[0] = 1, 'First should still be 1');
    Assert(Arr[1] = 2, 'Second should still be 2');
    Assert(Arr[2] = 3, 'Third should still be 3');

  finally
    S1.Free;
    S2.Free;
  end;

  // Intersect测试
  S1 := TIntSet.Create;
  S2 := TIntSet.Create;
  try
    S1.Add(1);
    S1.Add(2);
    S1.Add(3);
    S1.Add(4);

    S2.Add(2);
    S2.Add(4);
    S2.Add(6);

    S1.Intersect(S2);  // S1 = {2,4}
    Assert(S1.Count = 2, 'Intersect should have 2 elements');
    Assert(S1.Contains(2), 'Intersect should contain 2');
    Assert(S1.Contains(4), 'Intersect should contain 4');
    Assert(not S1.Contains(1), 'Intersect should not contain 1');

  finally
    S1.Free;
    S2.Free;
  end;

  // Difference测试
  S1 := TIntSet.Create;
  S2 := TIntSet.Create;
  try
    S1.Add(1);
    S1.Add(2);
    S1.Add(3);
    S1.Add(4);

    S2.Add(2);
    S2.Add(4);

    S1.Difference(S2);  // S1 = {1,3}
    Assert(S1.Count = 2, 'Difference should have 2 elements');
    Assert(S1.Contains(1), 'Difference should contain 1');
    Assert(S1.Contains(3), 'Difference should contain 3');
    Assert(not S1.Contains(2), 'Difference should not contain 2');

  finally
    S1.Free;
    S2.Free;
  end;
end;

{=== 子集测试 ===}

procedure TestSubset;
var
  S1, S2: TIntSet;
begin
  WriteLn('[Test] Subset Operations');
  S1 := TIntSet.Create;
  S2 := TIntSet.Create;
  try
    S1.Add(1);
    S1.Add(2);

    S2.Add(1);
    S2.Add(2);
    S2.Add(3);

    Assert(S1.IsSubsetOf(S2), 'S1 should be subset of S2');
    Assert(not S2.IsSubsetOf(S1), 'S2 should not be subset of S1');

    S1.Add(4);
    Assert(not S1.IsSubsetOf(S2), 'S1 should not be subset after adding 4');

  finally
    S1.Free;
    S2.Free;
  end;
end;

{=== 边界测试 ===}

procedure TestBoundaries;
var
  S: TIntSet;
  Val: Integer;
  Success, ExceptionRaised: Boolean;
begin
  WriteLn('[Test] Boundary Conditions');
  S := TIntSet.Create;
  try
    // 空集合操作
    ExceptionRaised := False;
    try
      S.First;
    except
      ExceptionRaised := True;
    end;
    Assert(ExceptionRaised, 'First on empty should raise exception');

    ExceptionRaised := False;
    try
      S.Last;
    except
      ExceptionRaised := True;
    end;
    Assert(ExceptionRaised, 'Last on empty should raise exception');

    Success := S.TryGetFirst(Val);
    Assert(not Success, 'TryGetFirst on empty should return False');

    Success := S.TryGetLast(Val);
    Assert(not Success, 'TryGetLast on empty should return False');

    // GetAt越界
    S.Add(1);
    ExceptionRaised := False;
    try
      S.GetAt(1);
    except
      ExceptionRaised := True;
    end;
    Assert(ExceptionRaised, 'GetAt beyond count should raise exception');

  finally
    S.Free;
  end;
end;

{=== 字符串集合测试 ===}

procedure TestStringSet;
var
  S: TStringSet;
  Arr: array of String;
begin
  WriteLn('[Test] String Set (Managed Type)');
  S := TStringSet.Create;
  try
    S.Add('World');
    S.Add('Hello');
    S.Add('Test');

    Assert(S.Count = 3, 'Count should be 3');

    // 检查顺序
    Arr := S.ToArray;
    Assert(Arr[0] = 'World', 'First should be World');
    Assert(Arr[1] = 'Hello', 'Second should be Hello');
    Assert(Arr[2] = 'Test', 'Third should be Test');

    // Remove
    S.Remove('Hello');
    Assert(S.Count = 2, 'Count should be 2 after remove');
    Assert(not S.Contains('Hello'), 'Should not contain Hello');

    // 重复添加
    Assert(not S.Add('World'), 'Adding duplicate should return False');

    S.Clear;
    Assert(S.IsEmpty, 'Should be empty after clear');

  finally
    S.Free;
  end;
end;

{=== Reverse测试 ===}

procedure TestReverse;
var
  S: TIntSet;
  Arr: array of Integer;
begin
  WriteLn('[Test] Reverse Operation');
  S := TIntSet.Create;
  try
    S.Add(1);
    S.Add(2);
    S.Add(3);
    S.Add(4);

    S.DoReverse;

    Arr := S.ToArray;
    Assert(Arr[0] = 4, 'After reverse, first should be 4');
    Assert(Arr[1] = 3, 'After reverse, second should be 3');
    Assert(Arr[2] = 2, 'After reverse, third should be 2');
    Assert(Arr[3] = 1, 'After reverse, fourth should be 1');

  finally
    S.Free;
  end;
end;

{=== TryGet测试 ===}

procedure TestTryGetMethods;
var
  S: TIntSet;
  Val: Integer;
begin
  WriteLn('[Test] TryGet Methods');
  S := TIntSet.Create;
  try
    S.Add(10);
    S.Add(20);
    S.Add(30);

    Assert(S.TryGetFirst(Val), 'TryGetFirst should succeed');
    Assert(Val = 10, 'TryGetFirst should return 10');

    Assert(S.TryGetLast(Val), 'TryGetLast should succeed');
    Assert(Val = 30, 'TryGetLast should return 30');

  finally
    S.Free;
  end;
end;

{=== 大规模测试 ===}

procedure TestLargeSet;
var
  S: TIntSet;
  i: Integer;
begin
  WriteLn('[Test] Large Set Performance');
  S := TIntSet.Create;
  try
    // 添加10000个元素
    for i := 1 to 10000 do
      S.Add(i);

    Assert(S.Count = 10000, 'Should have 10000 elements');
    Assert(S.First = 1, 'First should be 1');
    Assert(S.Last = 10000, 'Last should be 10000');

    // 检查contains性能
    Assert(S.Contains(5000), 'Should contain 5000');
    Assert(not S.Contains(20000), 'Should not contain 20000');

    // 移除一半
    for i := 1 to 5000 do
      S.Remove(i);

    Assert(S.Count = 5000, 'Should have 5000 elements left');
    Assert(S.First = 5001, 'First should now be 5001');

  finally
    S.Free;
  end;
end;

{=== 主程序 ===}

begin
  WriteLn('========================================');
  WriteLn('TOrderedSet Tests');
  WriteLn('========================================');
  WriteLn;

  try
    TestBasicOperations;
    WriteLn;

    TestInsertionOrder;
    WriteLn;

    TestSetOperations;
    WriteLn;

    TestSubset;
    WriteLn;

    TestBoundaries;
    WriteLn;

    TestStringSet;
    WriteLn;

    TestReverse;
    WriteLn;

    TestTryGetMethods;
    WriteLn;

    TestLargeSet;
    WriteLn;

    WriteLn('========================================');
    WriteLn('Test Results:');
    WriteLn('  Passed: ', TestsPassed);
    WriteLn('  Failed: ', TestsFailed);
    WriteLn('  Total:  ', TestsPassed + TestsFailed);
    WriteLn('========================================');

    if TestsFailed > 0 then
    begin
      WriteLn('❌ SOME TESTS FAILED!');
      Halt(1);
    end
    else
    begin
      WriteLn('✅ ALL TESTS PASSED!');
      Halt(0);
    end;

  except
    on E: Exception do
    begin
      WriteLn;
      WriteLn('❌ EXCEPTION: ', E.ClassName, ': ', E.Message);
      Halt(2);
    end;
  end;
end.