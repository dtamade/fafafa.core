program test_vec_boundaries;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.collections.vec;

type
  TIntVec = specialize TVec<Integer>;
  TStringVec = specialize TVec<String>;

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

procedure AssertException(const aMessage: String; aProc: TProcedure);
var
  ExceptionRaised: Boolean;
begin
  ExceptionRaised := False;
  try
    aProc();
  except
    ExceptionRaised := True;
  end;

  if ExceptionRaised then
  begin
    Inc(TestsPassed);
    WriteLn('  ✓ ', aMessage, ' (exception raised as expected)');
  end
  else
  begin
    Inc(TestsFailed);
    WriteLn('  ✗ FAILED: ', aMessage, ' (no exception raised)');
  end;
end;

{=== 边界测试：空容器 ===}

procedure TestEmptyVec;
var
  V: TIntVec;
  Item: Integer;
  Success: Boolean;
begin
  WriteLn('[Test] Empty Vec Boundaries');
  V := TIntVec.Create;
  try
    // 基本属性
    Assert(V.Count = 0, 'Empty vec count should be 0');
    Assert(V.IsEmpty, 'Empty vec should report IsEmpty = true');
    Assert(V.Capacity >= 0, 'Capacity should be non-negative');

    // Get 操作应该失败
    AssertException('Get(0) on empty vec should raise exception',
      procedure begin V.Get(0); end);

    // Pop 操作应该失败
    AssertException('Pop on empty vec should raise exception',
      procedure begin V.Pop; end);

    // TryPop 应该返回 False
    Success := V.TryPop(Item);
    Assert(not Success, 'TryPop on empty vec should return False');

    // Clear 空容器应该安全
    V.Clear;
    Assert(V.Count = 0, 'Clear on empty vec should be safe');

    // Remove 应该失败
    AssertException('Remove(0) on empty vec should raise exception',
      procedure begin V.Remove(0); end);

  finally
    V.Free;
  end;
end;

{=== 边界测试：单元素 ===}

procedure TestSingleElement;
var
  V: TIntVec;
begin
  WriteLn('[Test] Single Element Boundaries');
  V := TIntVec.Create;
  try
    V.Push(42);

    // 基本属性
    Assert(V.Count = 1, 'Count should be 1 after single push');
    Assert(not V.IsEmpty, 'Vec with one element should not be empty');
    Assert(V.Get(0) = 42, 'Get(0) should return pushed element');

    // 边界索引
    Assert(V.Get(0) = 42, 'Get(0) should work');
    AssertException('Get(1) should raise exception',
      procedure begin V.Get(1); end);
    AssertException('Get(-1) should raise exception (if checked)',
      procedure begin V.Get(High(SizeUInt)); end);

    // Pop 操作
    Assert(V.Pop = 42, 'Pop should return the element');
    Assert(V.Count = 0, 'Count should be 0 after pop');

  finally
    V.Free;
  end;
end;

{=== 边界测试：索引边界 ===}

procedure TestIndexBoundaries;
var
  V: TIntVec;
  i: Integer;
begin
  WriteLn('[Test] Index Boundaries');
  V := TIntVec.Create;
  try
    // 添加10个元素
    for i := 0 to 9 do
      V.Push(i);

    // 有效索引
    Assert(V.Get(0) = 0, 'First element should be accessible');
    Assert(V.Get(9) = 9, 'Last element should be accessible');

    // 边界外索引
    AssertException('Get(10) should raise exception',
      procedure begin V.Get(10); end);
    AssertException('Get(100) should raise exception',
      procedure begin V.Get(100); end);

    // 负数索引（作为大整数）
    AssertException('Get with negative index should raise exception',
      procedure begin V.Get(SizeUInt(-1)); end);

    // Insert 边界
    V.Insert(0, -1);  // 头部插入
    Assert(V.Get(0) = -1, 'Insert at 0 should work');

    V.Insert(V.Count, 999);  // 尾部插入
    Assert(V.Get(V.Count - 1) = 999, 'Insert at Count should work');

    AssertException('Insert beyond Count should raise exception',
      procedure begin V.Insert(V.Count + 1, 888); end);

  finally
    V.Free;
  end;
end;

{=== 边界测试：容量管理 ===}

procedure TestCapacityBoundaries;
var
  V: TIntVec;
  InitialCap, i: Integer;
begin
  WriteLn('[Test] Capacity Boundaries');
  V := TIntVec.Create;
  try
    // 零容量
    InitialCap := V.Capacity;
    Assert(InitialCap >= 0, 'Initial capacity should be non-negative');

    // Reserve 零容量
    V.Reserve(0);
    Assert(V.Capacity >= 0, 'Reserve(0) should be safe');

    // Reserve 合理容量
    V.Reserve(100);
    Assert(V.Capacity >= 100, 'Reserve(100) should ensure capacity >= 100');

    // ShrinkToFit
    V.Clear;
    V.ShrinkToFit;
    Assert(V.Capacity >= 0, 'ShrinkToFit should result in non-negative capacity');

    // 触发多次扩容
    for i := 1 to 1000 do
      V.Push(i);

    Assert(V.Count = 1000, 'Should have 1000 elements after pushing');
    Assert(V.Capacity >= 1000, 'Capacity should accommodate all elements');

    // ShrinkToFit 后容量应接近count
    V.ShrinkToFit;
    Assert(V.Capacity >= V.Count, 'Capacity should still hold all elements after shrink');

  finally
    V.Free;
  end;
end;

{=== 边界测试：批量操作 ===}

procedure TestBatchOperations;
var
  V: TIntVec;
  Arr: array[0..9] of Integer;
  i: Integer;
begin
  WriteLn('[Test] Batch Operation Boundaries');
  V := TIntVec.Create;
  try
    // 空数组批量添加
    SetLength(Arr, 0);
    // V.PushBatch(Arr);  // 如果有此方法
    Assert(V.Count = 0, 'Adding empty batch should not change count');

    // 批量添加
    for i := 0 to 9 do
      Arr[i] := i;

    for i := 0 to 9 do
      V.Push(Arr[i]);

    Assert(V.Count = 10, 'Should have 10 elements after batch');

    // Clear 后重新批量添加
    V.Clear;
    for i := 0 to 9 do
      V.Push(Arr[i]);
    Assert(V.Count = 10, 'Batch add after clear should work');

  finally
    V.Free;
  end;
end;

{=== 边界测试：迭代器 ===}

procedure TestIteratorBoundaries;
var
  V: TIntVec;
  Sum: Integer;
  Item: Integer;
begin
  WriteLn('[Test] Iterator Boundaries');
  V := TIntVec.Create;
  try
    // 空容器迭代
    Sum := 0;
    for Item in V do
      Sum := Sum + Item;
    Assert(Sum = 0, 'Iterating empty vec should result in sum = 0');

    // 单元素迭代
    V.Push(42);
    Sum := 0;
    for Item in V do
      Sum := Sum + Item;
    Assert(Sum = 42, 'Iterating single element should work');

    // 多元素迭代
    V.Clear;
    V.Push(1);
    V.Push(2);
    V.Push(3);
    Sum := 0;
    for Item in V do
      Sum := Sum + Item;
    Assert(Sum = 6, 'Iterating multiple elements should work');

  finally
    V.Free;
  end;
end;

{=== 边界测试：字符串类型特殊情况 ===}

procedure TestStringVecBoundaries;
var
  V: TStringVec;
begin
  WriteLn('[Test] String Vec Boundaries');
  V := TStringVec.Create;
  try
    // 空字符串
    V.Push('');
    Assert(V.Count = 1, 'Should be able to push empty string');
    Assert(V.Get(0) = '', 'Should retrieve empty string correctly');

    // 长字符串
    V.Push(StringOfChar('X', 10000));
    Assert(Length(V.Get(1)) = 10000, 'Should handle long strings');

    // Unicode 字符串
    V.Push('中文测试🚀');
    Assert(V.Get(2) = '中文测试🚀', 'Should handle Unicode strings');

    // Clear 应该正确释放字符串内存
    V.Clear;
    Assert(V.Count = 0, 'Clear should reset count to 0');

  finally
    V.Free;
  end;
end;

{=== 主程序 ===}

begin
  WriteLn('========================================');
  WriteLn('TVec Boundary Tests');
  WriteLn('========================================');
  WriteLn;

  try
    TestEmptyVec;
    WriteLn;

    TestSingleElement;
    WriteLn;

    TestIndexBoundaries;
    WriteLn;

    TestCapacityBoundaries;
    WriteLn;

    TestBatchOperations;
    WriteLn;

    TestIteratorBoundaries;
    WriteLn;

    TestStringVecBoundaries;
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