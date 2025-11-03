program test_circularbuffer;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.collections.circularbuffer;

type
  TIntBuffer = specialize TCircularBuffer<Integer>;
  TStringBuffer = specialize TCircularBuffer<String>;

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

procedure AssertException(const aMessage: String; aExpectedException: TClass);
begin
  // 简化版本：只打印消息，实际测试时会在调用处手动try-except
  WriteLn('  ⊙ ', aMessage, ' (manual exception test)');
  Inc(TestsPassed);
end;

{=== 基本功能测试 ===}

procedure TestBasicOperations;
var
  Buf: TIntBuffer;
  Val: Integer;
begin
  WriteLn('[Test] Basic Operations');
  Buf := TIntBuffer.Create(5, True);
  try
    // 初始状态
    Assert(Buf.IsEmpty, 'New buffer should be empty');
    Assert(Buf.Count = 0, 'New buffer count should be 0');
    Assert(Buf.Capacity = 5, 'Capacity should be 5');
    Assert(not Buf.IsFull, 'New buffer should not be full');

    // Push操作
    Assert(Buf.Push(1), 'First push should succeed');
    Assert(Buf.Count = 1, 'Count should be 1 after push');
    Assert(not Buf.IsEmpty, 'Buffer should not be empty after push');

    Buf.Push(2);
    Buf.Push(3);
    Assert(Buf.Count = 3, 'Count should be 3 after 3 pushes');

    // Peek操作
    Val := Buf.Peek;
    Assert(Val = 1, 'Peek should return first element (1)');
    Assert(Buf.Count = 3, 'Peek should not change count');

    // Pop操作
    Val := Buf.Pop;
    Assert(Val = 1, 'Pop should return 1');
    Assert(Buf.Count = 2, 'Count should be 2 after pop');

    Val := Buf.Pop;
    Assert(Val = 2, 'Pop should return 2');

    Val := Buf.Pop;
    Assert(Val = 3, 'Pop should return 3');
    Assert(Buf.IsEmpty, 'Buffer should be empty after all pops');

  finally
    Buf.Free;
  end;
end;

{=== 满缓冲区测试 ===}

procedure TestFullBuffer;
var
  Buf: TIntBuffer;
  i: Integer;
begin
  WriteLn('[Test] Full Buffer Handling');

  // 测试覆盖模式
  Buf := TIntBuffer.Create(3, True);  // OverwriteOldest = True
  try
    Buf.Push(1);
    Buf.Push(2);
    Buf.Push(3);
    Assert(Buf.IsFull, 'Buffer should be full');

    // 再push应该覆盖最旧的
    Assert(Buf.Push(4), 'Push on full buffer should succeed (overwrite mode)');
    Assert(Buf.Count = 3, 'Count should still be 3');
    Assert(Buf.Peek = 2, 'Oldest should now be 2 (1 was overwritten)');

    Buf.Push(5);  // 覆盖2
    Assert(Buf.Peek = 3, 'Oldest should now be 3');

    Assert(Buf.Pop = 3, 'Pop should return 3');
    Assert(Buf.Pop = 4, 'Pop should return 4');
    Assert(Buf.Pop = 5, 'Pop should return 5');
    Assert(Buf.IsEmpty, 'Buffer should be empty');

  finally
    Buf.Free;
  end;

  // 测试拒绝模式
  Buf := TIntBuffer.Create(3, False);  // OverwriteOldest = False
  try
    Buf.Push(1);
    Buf.Push(2);
    Buf.Push(3);

    Assert(not Buf.Push(4), 'Push on full buffer should fail (reject mode)');
    Assert(Buf.Count = 3, 'Count should still be 3');
    Assert(Buf.Peek = 1, 'Oldest should still be 1');

  finally
    Buf.Free;
  end;
end;

{=== PeekAt测试 ===}

procedure TestPeekAt;
var
  Buf: TIntBuffer;
  ExceptionRaised: Boolean;
begin
  WriteLn('[Test] PeekAt Operations');
  Buf := TIntBuffer.Create(5, True);
  try
    Buf.Push(10);
    Buf.Push(20);
    Buf.Push(30);

    Assert(Buf.PeekAt(0) = 10, 'PeekAt(0) should return first element');
    Assert(Buf.PeekAt(1) = 20, 'PeekAt(1) should return second element');
    Assert(Buf.PeekAt(2) = 30, 'PeekAt(2) should return third element');

    // 测试越界
    ExceptionRaised := False;
    try
      Buf.PeekAt(3);
    except
      ExceptionRaised := True;
    end;
    Assert(ExceptionRaised, 'PeekAt beyond count should raise exception');

  finally
    Buf.Free;
  end;
end;

{=== 环形索引测试 ===}

procedure TestWrapping;
var
  Buf: TIntBuffer;
  i: Integer;
begin
  WriteLn('[Test] Circular Wrapping');
  Buf := TIntBuffer.Create(3, True);
  try
    // 填满
    Buf.Push(1);
    Buf.Push(2);
    Buf.Push(3);

    // Pop两个
    Buf.Pop;
    Buf.Pop;
    Assert(Buf.Count = 1, 'Count should be 1');

    // 再push两个（会触发索引环绕）
    Buf.Push(4);
    Buf.Push(5);
    Assert(Buf.Count = 3, 'Count should be 3 after refill');

    // 验证顺序
    Assert(Buf.Pop = 3, 'First pop should be 3');
    Assert(Buf.Pop = 4, 'Second pop should be 4');
    Assert(Buf.Pop = 5, 'Third pop should be 5');

  finally
    Buf.Free;
  end;
end;

{=== 批量操作测试 ===}

procedure TestBatchOperations;
var
  Buf: TIntBuffer;
  Arr: array of Integer;
  i: Integer;
begin
  WriteLn('[Test] Batch Operations');
  Buf := TIntBuffer.Create(10, True);
  try
    // Push多个元素
    for i := 1 to 5 do
      Buf.Push(i * 10);

    // PopBatch
    Arr := Buf.PopBatch(3);
    Assert(Length(Arr) = 3, 'PopBatch should return 3 elements');
    Assert(Arr[0] = 10, 'First batched element should be 10');
    Assert(Arr[1] = 20, 'Second batched element should be 20');
    Assert(Arr[2] = 30, 'Third batched element should be 30');
    Assert(Buf.Count = 2, 'Count should be 2 after PopBatch(3)');

    // ToArray
    Arr := Buf.ToArray;
    Assert(Length(Arr) = 2, 'ToArray should return 2 elements');
    Assert(Arr[0] = 40, 'First array element should be 40');
    Assert(Arr[1] = 50, 'Second array element should be 50');
    Assert(Buf.Count = 2, 'ToArray should not change count');

  finally
    Buf.Free;
  end;
end;

{=== 边界测试 ===}

procedure TestBoundaries;
var
  Buf: TIntBuffer;
  Val: Integer;
  Success, ExceptionRaised: Boolean;
begin
  WriteLn('[Test] Boundary Conditions');
  Buf := TIntBuffer.Create(2, True);
  try
    // 空缓冲区操作
    ExceptionRaised := False;
    try
      Buf.Pop;
    except
      ExceptionRaised := True;
    end;
    Assert(ExceptionRaised, 'Pop on empty should raise exception');

    ExceptionRaised := False;
    try
      Buf.Peek;
    except
      ExceptionRaised := True;
    end;
    Assert(ExceptionRaised, 'Peek on empty should raise exception');

    Success := Buf.TryPop(Val);
    Assert(not Success, 'TryPop on empty should return False');

    Success := Buf.TryPeek(Val);
    Assert(not Success, 'TryPeek on empty should return False');

    // Clear操作
    Buf.Push(1);
    Buf.Push(2);
    Buf.Clear;
    Assert(Buf.IsEmpty, 'Buffer should be empty after Clear');
    Assert(Buf.Count = 0, 'Count should be 0 after Clear');

  finally
    Buf.Free;
  end;
end;

{=== 字符串类型测试 ===}

procedure TestStringBuffer;
var
  Buf: TStringBuffer;
  Str: String;
begin
  WriteLn('[Test] String Buffer (Managed Type)');
  Buf := TStringBuffer.Create(3, True);
  try
    Buf.Push('Hello');
    Buf.Push('World');
    Buf.Push('Test');

    Assert(Buf.Peek = 'Hello', 'Peek should return Hello');
    Assert(Buf.Pop = 'Hello', 'Pop should return Hello');
    Assert(Buf.Pop = 'World', 'Pop should return World');

    // 测试覆盖（托管类型需要正确finalize）
    Buf.Push('A');
    Buf.Push('B');
    Buf.Push('C');  // 满了：[A, B, C]
    Buf.Push('D');  // 应覆盖 A，现在是 [D, B, C]，head指向B

    Assert(Buf.Count = 3, 'Count should be 3');
    Assert(Buf.Peek = 'B', 'First should be B (A was overwritten by D)');

    Buf.Clear;
    Assert(Buf.IsEmpty, 'Buffer should be empty after clear');

  finally
    Buf.Free;
  end;
end;

{=== 容量边界测试 ===}

procedure TestCapacityBoundaries;
var
  Buf: TIntBuffer;
  i: Integer;
begin
  WriteLn('[Test] Capacity Boundaries');

  // 单元素缓冲区
  Buf := TIntBuffer.Create(1, True);
  try
    Buf.Push(42);
    Assert(Buf.IsFull, 'Single-element buffer should be full');
    Buf.Push(99);  // 应覆盖42
    Assert(Buf.Pop = 99, 'Pop should return 99 (42 was overwritten)');
  finally
    Buf.Free;
  end;

  // 大容量缓冲区
  Buf := TIntBuffer.Create(1000, True);
  try
    for i := 1 to 1000 do
      Buf.Push(i);
    Assert(Buf.IsFull, 'Buffer should be full after 1000 pushes');
    Assert(Buf.Count = 1000, 'Count should be 1000');
  finally
    Buf.Free;
  end;
end;

{=== RemainingCapacity测试 ===}

procedure TestRemainingCapacity;
var
  Buf: TIntBuffer;
begin
  WriteLn('[Test] RemainingCapacity');
  Buf := TIntBuffer.Create(5, True);
  try
    Assert(Buf.RemainingCapacity = 5, 'Initial remaining should be 5');

    Buf.Push(1);
    Assert(Buf.RemainingCapacity = 4, 'Remaining should be 4 after 1 push');

    Buf.Push(2);
    Buf.Push(3);
    Assert(Buf.RemainingCapacity = 2, 'Remaining should be 2 after 3 pushes');

    Buf.Pop;
    Assert(Buf.RemainingCapacity = 3, 'Remaining should be 3 after 1 pop');

  finally
    Buf.Free;
  end;
end;

{=== 主程序 ===}

begin
  WriteLn('========================================');
  WriteLn('TCircularBuffer Tests');
  WriteLn('========================================');
  WriteLn;

  try
    TestBasicOperations;
    WriteLn;

    TestFullBuffer;
    WriteLn;

    TestPeekAt;
    WriteLn;

    TestWrapping;
    WriteLn;

    TestBatchOperations;
    WriteLn;

    TestBoundaries;
    WriteLn;

    TestStringBuffer;
    WriteLn;

    TestCapacityBoundaries;
    WriteLn;

    TestRemainingCapacity;
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