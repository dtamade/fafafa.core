unit Test_CircularBuffer_Full;

{**
 * @desc TDD 测试：TCircularBuffer 完整测试套件
 * @purpose 验证环形缓冲区的所有功能
 *
 * 测试内容:
 *   - 基本 Push/Pop/Peek 操作
 *   - 溢出策略（覆盖/拒绝）
 *   - 边界条件
 *   - 状态查询
 *   - 批量操作
 *   - 托管类型内存安全
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections.circularbuffer;

type
  TIntBuffer = specialize TCircularBuffer<Integer>;
  TStrBuffer = specialize TCircularBuffer<string>;

  { TTestCase_CircularBuffer_Full }
  TTestCase_CircularBuffer_Full = class(TTestCase)
  published
    // 创建测试
    procedure Test_Create_ValidCapacity_Succeeds;
    procedure Test_Create_ZeroCapacity_RaisesException;
    procedure Test_Create_DefaultOverwriteOldest_True;
    
    // 基本操作测试
    procedure Test_Push_SingleElement_Works;
    procedure Test_Push_Pop_FIFO_Order;
    procedure Test_Peek_DoesNotRemove;
    procedure Test_PeekAt_ValidOffset_Works;
    procedure Test_PeekAt_InvalidOffset_RaisesException;
    
    // 状态查询测试
    procedure Test_IsEmpty_InitiallyTrue;
    procedure Test_IsEmpty_AfterPush_False;
    procedure Test_IsFull_WhenFull_True;
    procedure Test_Count_TracksCorrectly;
    procedure Test_Capacity_ReturnsCorrectValue;
    procedure Test_RemainingCapacity_Correct;
    
    // 溢出策略测试 - 覆盖模式
    procedure Test_Push_Overwrite_EvictsOldest;
    procedure Test_Push_Overwrite_AlwaysReturnsTrue;
    
    // 溢出策略测试 - 拒绝模式
    procedure Test_Push_Reject_WhenFull_ReturnsFalse;
    procedure Test_Push_Reject_PreservesExisting;
    
    // 安全方法测试
    procedure Test_TryPop_Empty_ReturnsFalse;
    procedure Test_TryPop_NonEmpty_ReturnsTrue;
    procedure Test_TryPeek_Empty_ReturnsFalse;
    procedure Test_TryPeek_NonEmpty_ReturnsTrue;
    
    // 边界条件测试
    procedure Test_Pop_Empty_RaisesException;
    procedure Test_Peek_Empty_RaisesException;
    procedure Test_WrapAround_Works;
    
    // 批量操作测试
    procedure Test_PopBatch_Works;
    procedure Test_PopBatch_ExceedsCount_RaisesException;
    procedure Test_ToArray_ReturnsInOrder;
    procedure Test_Clear_RemovesAll;
    
    // 属性修改测试
    procedure Test_OverwriteOldest_CanChange;
    
    // 托管类型测试
    procedure Test_String_PushPop_NoLeak;
    procedure Test_String_Overwrite_NoLeak;
    procedure Test_String_Clear_NoLeak;
  end;

implementation

{ TTestCase_CircularBuffer_Full }

// ========== 创建测试 ==========

procedure TTestCase_CircularBuffer_Full.Test_Create_ValidCapacity_Succeeds;
var
  Buffer: TIntBuffer;
begin
  Buffer := TIntBuffer.Create(10);
  try
    AssertEquals('Capacity 应为 10', 10, Buffer.Capacity);
    AssertTrue('应为空', Buffer.IsEmpty);
  finally
    Buffer.Free;
  end;
end;

procedure TTestCase_CircularBuffer_Full.Test_Create_ZeroCapacity_RaisesException;
var
  Buffer: TIntBuffer;
  ExceptionRaised: Boolean;
begin
  ExceptionRaised := False;
  try
    Buffer := TIntBuffer.Create(0);
    Buffer.Free;
  except
    on E: Exception do
      ExceptionRaised := True;
  end;
  AssertTrue('容量 0 应抛异常', ExceptionRaised);
end;

procedure TTestCase_CircularBuffer_Full.Test_Create_DefaultOverwriteOldest_True;
var
  Buffer: TIntBuffer;
begin
  Buffer := TIntBuffer.Create(5);
  try
    AssertTrue('默认 OverwriteOldest 应为 True', Buffer.OverwriteOldest);
  finally
    Buffer.Free;
  end;
end;

// ========== 基本操作测试 ==========

procedure TTestCase_CircularBuffer_Full.Test_Push_SingleElement_Works;
var
  Buffer: TIntBuffer;
begin
  Buffer := TIntBuffer.Create(5);
  try
    AssertTrue('Push 应成功', Buffer.Push(42));
    AssertEquals('Count 应为 1', 1, Buffer.GetCount);
  finally
    Buffer.Free;
  end;
end;

procedure TTestCase_CircularBuffer_Full.Test_Push_Pop_FIFO_Order;
var
  Buffer: TIntBuffer;
begin
  Buffer := TIntBuffer.Create(5);
  try
    Buffer.Push(1);
    Buffer.Push(2);
    Buffer.Push(3);
    
    AssertEquals('第一个 Pop 应为 1', 1, Buffer.Pop);
    AssertEquals('第二个 Pop 应为 2', 2, Buffer.Pop);
    AssertEquals('第三个 Pop 应为 3', 3, Buffer.Pop);
  finally
    Buffer.Free;
  end;
end;

procedure TTestCase_CircularBuffer_Full.Test_Peek_DoesNotRemove;
var
  Buffer: TIntBuffer;
begin
  Buffer := TIntBuffer.Create(5);
  try
    Buffer.Push(100);
    
    AssertEquals('Peek 应返回 100', 100, Buffer.Peek);
    AssertEquals('Peek 后 Count 应仍为 1', 1, Buffer.GetCount);
    AssertEquals('再次 Peek 应返回 100', 100, Buffer.Peek);
  finally
    Buffer.Free;
  end;
end;

procedure TTestCase_CircularBuffer_Full.Test_PeekAt_ValidOffset_Works;
var
  Buffer: TIntBuffer;
begin
  Buffer := TIntBuffer.Create(5);
  try
    Buffer.Push(10);
    Buffer.Push(20);
    Buffer.Push(30);
    
    AssertEquals('PeekAt(0) 应为 10', 10, Buffer.PeekAt(0));
    AssertEquals('PeekAt(1) 应为 20', 20, Buffer.PeekAt(1));
    AssertEquals('PeekAt(2) 应为 30', 30, Buffer.PeekAt(2));
  finally
    Buffer.Free;
  end;
end;

procedure TTestCase_CircularBuffer_Full.Test_PeekAt_InvalidOffset_RaisesException;
var
  Buffer: TIntBuffer;
  ExceptionRaised: Boolean;
begin
  Buffer := TIntBuffer.Create(5);
  try
    Buffer.Push(1);
    Buffer.Push(2);
    
    ExceptionRaised := False;
    try
      Buffer.PeekAt(5);  // 无效偏移
    except
      on E: Exception do
        ExceptionRaised := True;
    end;
    AssertTrue('无效偏移应抛异常', ExceptionRaised);
  finally
    Buffer.Free;
  end;
end;

// ========== 状态查询测试 ==========

procedure TTestCase_CircularBuffer_Full.Test_IsEmpty_InitiallyTrue;
var
  Buffer: TIntBuffer;
begin
  Buffer := TIntBuffer.Create(5);
  try
    AssertTrue('新建应为空', Buffer.IsEmpty);
  finally
    Buffer.Free;
  end;
end;

procedure TTestCase_CircularBuffer_Full.Test_IsEmpty_AfterPush_False;
var
  Buffer: TIntBuffer;
begin
  Buffer := TIntBuffer.Create(5);
  try
    Buffer.Push(1);
    AssertFalse('Push 后不应为空', Buffer.IsEmpty);
  finally
    Buffer.Free;
  end;
end;

procedure TTestCase_CircularBuffer_Full.Test_IsFull_WhenFull_True;
var
  Buffer: TIntBuffer;
begin
  Buffer := TIntBuffer.Create(3, False);  // 拒绝模式
  try
    Buffer.Push(1);
    Buffer.Push(2);
    Buffer.Push(3);
    
    AssertTrue('容量满后 IsFull 应为 True', Buffer.IsFull);
  finally
    Buffer.Free;
  end;
end;

procedure TTestCase_CircularBuffer_Full.Test_Count_TracksCorrectly;
var
  Buffer: TIntBuffer;
begin
  Buffer := TIntBuffer.Create(5);
  try
    AssertEquals('初始 Count', 0, Buffer.GetCount);
    
    Buffer.Push(1);
    AssertEquals('Push 1 后 Count', 1, Buffer.GetCount);
    
    Buffer.Push(2);
    AssertEquals('Push 2 后 Count', 2, Buffer.GetCount);
    
    Buffer.Pop;
    AssertEquals('Pop 后 Count', 1, Buffer.GetCount);
  finally
    Buffer.Free;
  end;
end;

procedure TTestCase_CircularBuffer_Full.Test_Capacity_ReturnsCorrectValue;
var
  Buffer: TIntBuffer;
begin
  Buffer := TIntBuffer.Create(42);
  try
    AssertEquals('Capacity 应为 42', 42, Buffer.Capacity);
  finally
    Buffer.Free;
  end;
end;

procedure TTestCase_CircularBuffer_Full.Test_RemainingCapacity_Correct;
var
  Buffer: TIntBuffer;
begin
  Buffer := TIntBuffer.Create(5);
  try
    AssertEquals('初始剩余容量', 5, Buffer.RemainingCapacity);
    
    Buffer.Push(1);
    Buffer.Push(2);
    AssertEquals('Push 2 后剩余容量', 3, Buffer.RemainingCapacity);
  finally
    Buffer.Free;
  end;
end;

// ========== 溢出策略测试 - 覆盖模式 ==========

procedure TTestCase_CircularBuffer_Full.Test_Push_Overwrite_EvictsOldest;
var
  Buffer: TIntBuffer;
begin
  Buffer := TIntBuffer.Create(3, True);  // 覆盖模式
  try
    Buffer.Push(1);
    Buffer.Push(2);
    Buffer.Push(3);
    
    // 满了，再 Push 应覆盖 1
    Buffer.Push(4);
    
    AssertEquals('Count 应保持 3', 3, Buffer.GetCount);
    AssertEquals('最旧的应是 2', 2, Buffer.Pop);
    AssertEquals('然后是 3', 3, Buffer.Pop);
    AssertEquals('最新的是 4', 4, Buffer.Pop);
  finally
    Buffer.Free;
  end;
end;

procedure TTestCase_CircularBuffer_Full.Test_Push_Overwrite_AlwaysReturnsTrue;
var
  Buffer: TIntBuffer;
  i: Integer;
begin
  Buffer := TIntBuffer.Create(3, True);
  try
    for i := 1 to 10 do
      AssertTrue('覆盖模式 Push 应总是返回 True', Buffer.Push(i));
  finally
    Buffer.Free;
  end;
end;

// ========== 溢出策略测试 - 拒绝模式 ==========

procedure TTestCase_CircularBuffer_Full.Test_Push_Reject_WhenFull_ReturnsFalse;
var
  Buffer: TIntBuffer;
begin
  Buffer := TIntBuffer.Create(3, False);  // 拒绝模式
  try
    AssertTrue(Buffer.Push(1));
    AssertTrue(Buffer.Push(2));
    AssertTrue(Buffer.Push(3));
    
    // 满了
    AssertFalse('满时 Push 应返回 False', Buffer.Push(4));
  finally
    Buffer.Free;
  end;
end;

procedure TTestCase_CircularBuffer_Full.Test_Push_Reject_PreservesExisting;
var
  Buffer: TIntBuffer;
begin
  Buffer := TIntBuffer.Create(3, False);
  try
    Buffer.Push(1);
    Buffer.Push(2);
    Buffer.Push(3);
    Buffer.Push(4);  // 被拒绝
    
    // 原有数据不变
    AssertEquals('第一个应仍是 1', 1, Buffer.Pop);
    AssertEquals('第二个应仍是 2', 2, Buffer.Pop);
    AssertEquals('第三个应仍是 3', 3, Buffer.Pop);
  finally
    Buffer.Free;
  end;
end;

// ========== 安全方法测试 ==========

procedure TTestCase_CircularBuffer_Full.Test_TryPop_Empty_ReturnsFalse;
var
  Buffer: TIntBuffer;
  Value: Integer;
begin
  Buffer := TIntBuffer.Create(5);
  try
    AssertFalse('空时 TryPop 应返回 False', Buffer.TryPop(Value));
  finally
    Buffer.Free;
  end;
end;

procedure TTestCase_CircularBuffer_Full.Test_TryPop_NonEmpty_ReturnsTrue;
var
  Buffer: TIntBuffer;
  Value: Integer;
begin
  Buffer := TIntBuffer.Create(5);
  try
    Buffer.Push(42);
    
    AssertTrue('非空时 TryPop 应返回 True', Buffer.TryPop(Value));
    AssertEquals('值应为 42', 42, Value);
  finally
    Buffer.Free;
  end;
end;

procedure TTestCase_CircularBuffer_Full.Test_TryPeek_Empty_ReturnsFalse;
var
  Buffer: TIntBuffer;
  Value: Integer;
begin
  Buffer := TIntBuffer.Create(5);
  try
    AssertFalse('空时 TryPeek 应返回 False', Buffer.TryPeek(Value));
  finally
    Buffer.Free;
  end;
end;

procedure TTestCase_CircularBuffer_Full.Test_TryPeek_NonEmpty_ReturnsTrue;
var
  Buffer: TIntBuffer;
  Value: Integer;
begin
  Buffer := TIntBuffer.Create(5);
  try
    Buffer.Push(99);
    
    AssertTrue('非空时 TryPeek 应返回 True', Buffer.TryPeek(Value));
    AssertEquals('值应为 99', 99, Value);
    AssertEquals('Count 应不变', 1, Buffer.GetCount);
  finally
    Buffer.Free;
  end;
end;

// ========== 边界条件测试 ==========

procedure TTestCase_CircularBuffer_Full.Test_Pop_Empty_RaisesException;
var
  Buffer: TIntBuffer;
  ExceptionRaised: Boolean;
begin
  Buffer := TIntBuffer.Create(5);
  try
    ExceptionRaised := False;
    try
      Buffer.Pop;
    except
      on E: Exception do
        ExceptionRaised := True;
    end;
    AssertTrue('空时 Pop 应抛异常', ExceptionRaised);
  finally
    Buffer.Free;
  end;
end;

procedure TTestCase_CircularBuffer_Full.Test_Peek_Empty_RaisesException;
var
  Buffer: TIntBuffer;
  ExceptionRaised: Boolean;
begin
  Buffer := TIntBuffer.Create(5);
  try
    ExceptionRaised := False;
    try
      Buffer.Peek;
    except
      on E: Exception do
        ExceptionRaised := True;
    end;
    AssertTrue('空时 Peek 应抛异常', ExceptionRaised);
  finally
    Buffer.Free;
  end;
end;

procedure TTestCase_CircularBuffer_Full.Test_WrapAround_Works;
var
  Buffer: TIntBuffer;
  i: Integer;
begin
  Buffer := TIntBuffer.Create(3);
  try
    // 多次环绕测试
    for i := 1 to 10 do
    begin
      Buffer.Push(i);
      if i > 3 then
        AssertEquals('环绕后 Pop', i - 3 + 1, Buffer.Pop);
    end;
  finally
    Buffer.Free;
  end;
end;

// ========== 批量操作测试 ==========

procedure TTestCase_CircularBuffer_Full.Test_PopBatch_Works;
var
  Buffer: TIntBuffer;
  Batch: array of Integer;
begin
  Buffer := TIntBuffer.Create(5);
  try
    Buffer.Push(1);
    Buffer.Push(2);
    Buffer.Push(3);
    Buffer.Push(4);
    Buffer.Push(5);
    
    Batch := Buffer.PopBatch(3);
    
    AssertEquals('批量弹出数量', 3, Length(Batch));
    AssertEquals('第一个', 1, Batch[0]);
    AssertEquals('第二个', 2, Batch[1]);
    AssertEquals('第三个', 3, Batch[2]);
    AssertEquals('剩余 Count', 2, Buffer.GetCount);
  finally
    Buffer.Free;
  end;
end;

procedure TTestCase_CircularBuffer_Full.Test_PopBatch_ExceedsCount_RaisesException;
var
  Buffer: TIntBuffer;
  ExceptionRaised: Boolean;
begin
  Buffer := TIntBuffer.Create(5);
  try
    Buffer.Push(1);
    Buffer.Push(2);
    
    ExceptionRaised := False;
    try
      Buffer.PopBatch(5);  // 只有 2 个
    except
      on E: Exception do
        ExceptionRaised := True;
    end;
    AssertTrue('超出数量应抛异常', ExceptionRaised);
  finally
    Buffer.Free;
  end;
end;

procedure TTestCase_CircularBuffer_Full.Test_ToArray_ReturnsInOrder;
var
  Buffer: TIntBuffer;
  Arr: array of Integer;
begin
  Buffer := TIntBuffer.Create(5);
  try
    Buffer.Push(10);
    Buffer.Push(20);
    Buffer.Push(30);
    
    Arr := Buffer.ToArray;
    
    AssertEquals('数组长度', 3, Length(Arr));
    AssertEquals('第一个', 10, Arr[0]);
    AssertEquals('第二个', 20, Arr[1]);
    AssertEquals('第三个', 30, Arr[2]);
    AssertEquals('ToArray 不应改变 Count', 3, Buffer.GetCount);
  finally
    Buffer.Free;
  end;
end;

procedure TTestCase_CircularBuffer_Full.Test_Clear_RemovesAll;
var
  Buffer: TIntBuffer;
begin
  Buffer := TIntBuffer.Create(5);
  try
    Buffer.Push(1);
    Buffer.Push(2);
    Buffer.Push(3);
    
    Buffer.Clear;
    
    AssertTrue('Clear 后应为空', Buffer.IsEmpty);
    AssertEquals('Clear 后 Count 为 0', 0, Buffer.GetCount);
  finally
    Buffer.Free;
  end;
end;

// ========== 属性修改测试 ==========

procedure TTestCase_CircularBuffer_Full.Test_OverwriteOldest_CanChange;
var
  Buffer: TIntBuffer;
begin
  Buffer := TIntBuffer.Create(3, True);
  try
    Buffer.Push(1);
    Buffer.Push(2);
    Buffer.Push(3);
    
    // 改为拒绝模式
    Buffer.OverwriteOldest := False;
    
    AssertFalse('改为拒绝模式后应返回 False', Buffer.Push(4));
    AssertEquals('数据应保持不变', 1, Buffer.Peek);
  finally
    Buffer.Free;
  end;
end;

// ========== 托管类型测试 ==========

procedure TTestCase_CircularBuffer_Full.Test_String_PushPop_NoLeak;
var
  Buffer: TStrBuffer;
begin
  Buffer := TStrBuffer.Create(5);
  try
    Buffer.Push('Hello');
    Buffer.Push('World');
    Buffer.Push('Test');
    
    AssertEquals('第一个字符串', 'Hello', Buffer.Pop);
    AssertEquals('第二个字符串', 'World', Buffer.Pop);
    AssertEquals('第三个字符串', 'Test', Buffer.Pop);
  finally
    Buffer.Free;
  end;
end;

procedure TTestCase_CircularBuffer_Full.Test_String_Overwrite_NoLeak;
var
  Buffer: TStrBuffer;
begin
  Buffer := TStrBuffer.Create(3, True);
  try
    Buffer.Push('One');
    Buffer.Push('Two');
    Buffer.Push('Three');
    Buffer.Push('Four');  // 覆盖 'One'
    Buffer.Push('Five');  // 覆盖 'Two'
    
    AssertEquals('最旧的应是 Three', 'Three', Buffer.Pop);
    AssertEquals('Count', 2, Buffer.GetCount);
  finally
    Buffer.Free;
  end;
end;

procedure TTestCase_CircularBuffer_Full.Test_String_Clear_NoLeak;
var
  Buffer: TStrBuffer;
begin
  Buffer := TStrBuffer.Create(5);
  try
    Buffer.Push('Alpha');
    Buffer.Push('Beta');
    Buffer.Push('Gamma');
    
    Buffer.Clear;
    
    AssertTrue('Clear 后应为空', Buffer.IsEmpty);
  finally
    Buffer.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_CircularBuffer_Full);

end.
