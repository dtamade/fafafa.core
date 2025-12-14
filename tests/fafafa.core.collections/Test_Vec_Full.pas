unit Test_Vec_Full;

{**
 * @desc TDD 测试：TVec<T> 完整测试套件
 * @purpose 验证动态向量的所有公共 API
 *
 * 测试覆盖:
 *   - Push/Pop: 尾部操作
 *   - Get/Put: 随机访问
 *   - Insert/Remove: 中间操作
 *   - Reserve/Resize/ShrinkToFit: 容量管理
 *   - Find/Contains: 搜索操作
 *   - Sort/Reverse: 算法操作
 *   - 边界条件: 空向量、单元素、大数据集
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections,
  fafafa.core.collections.vec,
  fafafa.core.collections.base,
  fafafa.core.mem.allocator;

type
  { TTestCase_Vec_Full }
  TTestCase_Vec_Full = class(TTestCase)
  private
    type
      TIntVec = specialize TVec<Integer>;
      TStrVec = specialize TVec<String>;
  published
    // === 基本操作测试 ===
    procedure Test_Vec_Push_SingleElement;
    procedure Test_Vec_Push_MultipleElements;
    
    // === Pop 操作测试 ===
    procedure Test_Vec_Pop_ReturnsLast;
    procedure Test_Vec_Pop_LIFO_Order;
    procedure Test_Vec_TryPop_Empty_ReturnsFalse;
    procedure Test_Vec_TryPop_NonEmpty_ReturnsTrue;
    
    // === 随机访问测试 ===
    procedure Test_Vec_Get_ValidIndex;
    procedure Test_Vec_Put_ValidIndex;
    procedure Test_Vec_GetPtr_ReturnsCorrectPointer;
    
    // === Insert/Remove 测试 ===
    procedure Test_Vec_Insert_AtBeginning;
    procedure Test_Vec_Insert_AtMiddle;
    procedure Test_Vec_Insert_AtEnd;
    procedure Test_Vec_Remove_FromBeginning;
    procedure Test_Vec_Remove_FromMiddle;
    procedure Test_Vec_Remove_FromEnd;
    procedure Test_Vec_RemoveSwap_PreservesOtherElements;
    
    // === 容量管理测试 ===
    procedure Test_Vec_Reserve_IncreasesCapacity;
    procedure Test_Vec_Resize_Grow;
    procedure Test_Vec_Resize_Shrink;
    procedure Test_Vec_ShrinkToFit_ReducesCapacity;
    procedure Test_Vec_Clear_ResetsCount;
    
    // === 搜索操作测试 ===
    procedure Test_Vec_Find_ExistingElement;
    procedure Test_Vec_Find_NonExistingElement;
    procedure Test_Vec_Contains_True;
    procedure Test_Vec_Contains_False;
    
    // === 算法操作测试 ===
    procedure Test_Vec_Reverse_EvenCount;
    procedure Test_Vec_Reverse_OddCount;
    procedure Test_Vec_Sort_Ascending;
    
    // === 边界条件测试 ===
    procedure Test_Vec_IsEmpty_InitiallyTrue;
    procedure Test_Vec_Count_AfterOperations;
    procedure Test_Vec_First_Last_SingleElement;
    
    // === 字符串类型测试 ===
    procedure Test_Vec_String_BasicOperations;
    
    // === 大数据集测试 ===
    procedure Test_Vec_LargeDataSet;
  end;

implementation

{ TTestCase_Vec_Full }

// === 基本操作测试 ===

procedure TTestCase_Vec_Full.Test_Vec_Push_SingleElement;
var
  Vec: TIntVec;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(42);
    
    AssertEquals('Count should be 1', 1, Vec.Count);
    AssertEquals('Element should be 42', 42, Vec.Get(0));
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_Push_MultipleElements;
var
  Vec: TIntVec;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(1);
    Vec.Push(2);
    Vec.Push(3);
    
    AssertEquals('Count should be 3', 3, Vec.Count);
    AssertEquals('First element', 1, Vec.Get(0));
    AssertEquals('Second element', 2, Vec.Get(1));
    AssertEquals('Third element', 3, Vec.Get(2));
  finally
    Vec.Free;
  end;
end;

// === Pop 操作测试 ===

procedure TTestCase_Vec_Full.Test_Vec_Pop_ReturnsLast;
var
  Vec: TIntVec;
  V: Integer;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(10);
    Vec.Push(20);
    Vec.Push(30);
    
    V := Vec.Pop;
    
    AssertEquals('Pop should return 30', 30, V);
    AssertEquals('Count should be 2', 2, Vec.Count);
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_Pop_LIFO_Order;
var
  Vec: TIntVec;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(1);
    Vec.Push(2);
    Vec.Push(3);
    
    AssertEquals('First pop', 3, Vec.Pop);
    AssertEquals('Second pop', 2, Vec.Pop);
    AssertEquals('Third pop', 1, Vec.Pop);
    AssertTrue('Vec should be empty', Vec.IsEmpty);
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_TryPop_Empty_ReturnsFalse;
var
  Vec: TIntVec;
  V: Integer;
begin
  Vec := TIntVec.Create;
  try
    V := 0; // Initialize to suppress warning
    AssertFalse('TryPop on empty should return False', Vec.TryPop(V));
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_TryPop_NonEmpty_ReturnsTrue;
var
  Vec: TIntVec;
  V: Integer;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(42);
    V := 0; // Initialize
    
    AssertTrue('TryPop on non-empty should return True', Vec.TryPop(V));
    AssertEquals('Value should be 42', 42, V);
  finally
    Vec.Free;
  end;
end;

// === 随机访问测试 ===

procedure TTestCase_Vec_Full.Test_Vec_Get_ValidIndex;
var
  Vec: TIntVec;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(100);
    Vec.Push(200);
    Vec.Push(300);
    
    AssertEquals('Get(0)', 100, Vec.Get(0));
    AssertEquals('Get(1)', 200, Vec.Get(1));
    AssertEquals('Get(2)', 300, Vec.Get(2));
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_Put_ValidIndex;
var
  Vec: TIntVec;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(1);
    Vec.Push(2);
    Vec.Push(3);
    
    Vec.Put(1, 999);
    
    AssertEquals('Element at index 1 should be 999', 999, Vec.Get(1));
    AssertEquals('Element at index 0 unchanged', 1, Vec.Get(0));
    AssertEquals('Element at index 2 unchanged', 3, Vec.Get(2));
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_GetPtr_ReturnsCorrectPointer;
var
  Vec: TIntVec;
  P: ^Integer;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(42);
    
    P := Vec.GetPtr(0);
    
    AssertEquals('Pointer should point to correct value', 42, P^);
    
    // 修改通过指针
    P^ := 100;
    AssertEquals('Value should be modified', 100, Vec.Get(0));
  finally
    Vec.Free;
  end;
end;

// === Insert/Remove 测试 ===

procedure TTestCase_Vec_Full.Test_Vec_Insert_AtBeginning;
var
  Vec: TIntVec;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(2);
    Vec.Push(3);
    
    Vec.Insert(0, 1);
    
    AssertEquals('Count should be 3', 3, Vec.Count);
    AssertEquals('First element', 1, Vec.Get(0));
    AssertEquals('Second element', 2, Vec.Get(1));
    AssertEquals('Third element', 3, Vec.Get(2));
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_Insert_AtMiddle;
var
  Vec: TIntVec;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(1);
    Vec.Push(3);
    
    Vec.Insert(1, 2);
    
    AssertEquals('Count should be 3', 3, Vec.Count);
    AssertEquals('Element at 0', 1, Vec.Get(0));
    AssertEquals('Element at 1', 2, Vec.Get(1));
    AssertEquals('Element at 2', 3, Vec.Get(2));
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_Insert_AtEnd;
var
  Vec: TIntVec;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(1);
    Vec.Push(2);
    
    Vec.Insert(2, 3);
    
    AssertEquals('Count should be 3', 3, Vec.Count);
    AssertEquals('Last element', 3, Vec.Get(2));
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_Remove_FromBeginning;
var
  Vec: TIntVec;
  Removed: Integer;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(1);
    Vec.Push(2);
    Vec.Push(3);
    
    Removed := Vec.Remove(0);
    
    AssertEquals('Removed value', 1, Removed);
    AssertEquals('Count should be 2', 2, Vec.Count);
    AssertEquals('New first element', 2, Vec.Get(0));
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_Remove_FromMiddle;
var
  Vec: TIntVec;
  Removed: Integer;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(1);
    Vec.Push(2);
    Vec.Push(3);
    
    Removed := Vec.Remove(1);
    
    AssertEquals('Removed value', 2, Removed);
    AssertEquals('Count should be 2', 2, Vec.Count);
    AssertEquals('First element', 1, Vec.Get(0));
    AssertEquals('Second element', 3, Vec.Get(1));
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_Remove_FromEnd;
var
  Vec: TIntVec;
  Removed: Integer;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(1);
    Vec.Push(2);
    Vec.Push(3);
    
    Removed := Vec.Remove(2);
    
    AssertEquals('Removed value', 3, Removed);
    AssertEquals('Count should be 2', 2, Vec.Count);
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_RemoveSwap_PreservesOtherElements;
var
  Vec: TIntVec;
  Removed: Integer;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(1);
    Vec.Push(2);
    Vec.Push(3);
    Vec.Push(4);
    // [1, 2, 3, 4]
    
    Removed := Vec.RemoveSwap(1);
    // 移除 index 1, 用最后一个元素替换 -> [1, 4, 3]
    
    AssertEquals('Removed value', 2, Removed);
    AssertEquals('Count should be 3', 3, Vec.Count);
    AssertEquals('First element unchanged', 1, Vec.Get(0));
    AssertEquals('Swapped element', 4, Vec.Get(1));
    AssertEquals('Third element', 3, Vec.Get(2));
  finally
    Vec.Free;
  end;
end;

// === 容量管理测试 ===

procedure TTestCase_Vec_Full.Test_Vec_Reserve_IncreasesCapacity;
var
  Vec: TIntVec;
  OldCapacity: SizeUInt;
begin
  Vec := TIntVec.Create;
  try
    OldCapacity := Vec.Capacity;
    
    Vec.Reserve(100);
    
    AssertTrue('Capacity should increase', Vec.Capacity >= OldCapacity + 100);
    AssertEquals('Count should still be 0', 0, Vec.Count);
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_Resize_Grow;
var
  Vec: TIntVec;
begin
  Vec := TIntVec.Create;
  try
    Vec.Resize(5);
    
    AssertEquals('Count should be 5', 5, Vec.Count);
    // 注意: TVec.Resize 不保证初始化新元素为默认值
    // 只验证 Count 正确增加
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_Resize_Shrink;
var
  Vec: TIntVec;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(1);
    Vec.Push(2);
    Vec.Push(3);
    Vec.Push(4);
    Vec.Push(5);
    
    Vec.Resize(2);
    
    AssertEquals('Count should be 2', 2, Vec.Count);
    AssertEquals('First element preserved', 1, Vec.Get(0));
    AssertEquals('Second element preserved', 2, Vec.Get(1));
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_ShrinkToFit_ReducesCapacity;
var
  Vec: TIntVec;
begin
  Vec := TIntVec.Create;
  try
    Vec.Reserve(1000);
    Vec.Push(1);
    Vec.Push(2);
    Vec.Push(3);
    
    Vec.ShrinkToFit;
    
    AssertEquals('Count should still be 3', 3, Vec.Count);
    // 容量应该减少到接近 Count
    AssertTrue('Capacity should be reduced', Vec.Capacity < 1000);
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_Clear_ResetsCount;
var
  Vec: TIntVec;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(1);
    Vec.Push(2);
    Vec.Push(3);
    
    Vec.Clear;
    
    AssertEquals('Count should be 0', 0, Vec.Count);
    AssertTrue('Vec should be empty', Vec.IsEmpty);
  finally
    Vec.Free;
  end;
end;

// === 搜索操作测试 ===

procedure TTestCase_Vec_Full.Test_Vec_Find_ExistingElement;
var
  Vec: TIntVec;
  Index: SizeInt;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(10);
    Vec.Push(20);
    Vec.Push(30);
    
    Index := Vec.Find(20);
    
    AssertEquals('Index should be 1', 1, Index);
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_Find_NonExistingElement;
var
  Vec: TIntVec;
  Index: SizeInt;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(10);
    Vec.Push(20);
    Vec.Push(30);
    
    Index := Vec.Find(999);
    
    AssertEquals('Index should be -1', -1, Index);
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_Contains_True;
var
  Vec: TIntVec;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(10);
    Vec.Push(20);
    Vec.Push(30);
    
    AssertTrue('Should contain 20', Vec.Contains(20, 0));
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_Contains_False;
var
  Vec: TIntVec;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(10);
    Vec.Push(20);
    Vec.Push(30);
    
    AssertFalse('Should not contain 999', Vec.Contains(999, 0));
  finally
    Vec.Free;
  end;
end;

// === 算法操作测试 ===

procedure TTestCase_Vec_Full.Test_Vec_Reverse_EvenCount;
var
  Vec: TIntVec;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(1);
    Vec.Push(2);
    Vec.Push(3);
    Vec.Push(4);
    
    Vec.Reverse;
    
    AssertEquals('First element', 4, Vec.Get(0));
    AssertEquals('Second element', 3, Vec.Get(1));
    AssertEquals('Third element', 2, Vec.Get(2));
    AssertEquals('Fourth element', 1, Vec.Get(3));
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_Reverse_OddCount;
var
  Vec: TIntVec;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(1);
    Vec.Push(2);
    Vec.Push(3);
    
    Vec.Reverse;
    
    AssertEquals('First element', 3, Vec.Get(0));
    AssertEquals('Middle element', 2, Vec.Get(1));
    AssertEquals('Last element', 1, Vec.Get(2));
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_Sort_Ascending;
var
  Vec: TIntVec;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(30);
    Vec.Push(10);
    Vec.Push(50);
    Vec.Push(20);
    Vec.Push(40);
    
    Vec.Sort;
    
    AssertEquals('Element 0', 10, Vec.Get(0));
    AssertEquals('Element 1', 20, Vec.Get(1));
    AssertEquals('Element 2', 30, Vec.Get(2));
    AssertEquals('Element 3', 40, Vec.Get(3));
    AssertEquals('Element 4', 50, Vec.Get(4));
  finally
    Vec.Free;
  end;
end;

// === 边界条件测试 ===

procedure TTestCase_Vec_Full.Test_Vec_IsEmpty_InitiallyTrue;
var
  Vec: TIntVec;
begin
  Vec := TIntVec.Create;
  try
    AssertTrue('New Vec should be empty', Vec.IsEmpty);
    AssertEquals('Count should be 0', 0, Vec.Count);
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_Count_AfterOperations;
var
  Vec: TIntVec;
begin
  Vec := TIntVec.Create;
  try
    AssertEquals('Initial count', 0, Vec.Count);
    
    Vec.Push(1);
    AssertEquals('After push', 1, Vec.Count);
    
    Vec.Push(2);
    AssertEquals('After second push', 2, Vec.Count);
    
    Vec.Pop;
    AssertEquals('After pop', 1, Vec.Count);
    
    Vec.Clear;
    AssertEquals('After clear', 0, Vec.Count);
  finally
    Vec.Free;
  end;
end;

procedure TTestCase_Vec_Full.Test_Vec_First_Last_SingleElement;
var
  Vec: TIntVec;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(42);
    
    AssertEquals('First', 42, Vec.First);
    AssertEquals('Last', 42, Vec.Last);
  finally
    Vec.Free;
  end;
end;

// === 字符串类型测试 ===

procedure TTestCase_Vec_Full.Test_Vec_String_BasicOperations;
var
  Vec: TStrVec;
begin
  Vec := TStrVec.Create;
  try
    Vec.Push('Hello');
    Vec.Push('World');
    Vec.Push('!');
    
    AssertEquals('Count', 3, Vec.Count);
    AssertEquals('First string', 'Hello', Vec.Get(0));
    AssertEquals('Second string', 'World', Vec.Get(1));
    AssertEquals('Third string', '!', Vec.Get(2));
    
    AssertEquals('Pop', '!', Vec.Pop);
    AssertEquals('Count after pop', 2, Vec.Count);
  finally
    Vec.Free;
  end;
end;

// === 大数据集测试 ===

procedure TTestCase_Vec_Full.Test_Vec_LargeDataSet;
var
  Vec: TIntVec;
  i: Integer;
begin
  Vec := TIntVec.Create;
  try
    // 添加 10000 个元素
    for i := 0 to 9999 do
      Vec.Push(i);
    
    AssertEquals('Count should be 10000', 10000, Vec.Count);
    AssertEquals('First element', 0, Vec.Get(0));
    AssertEquals('Last element', 9999, Vec.Get(9999));
    AssertEquals('Middle element', 5000, Vec.Get(5000));
    
    // 测试 Find
    AssertEquals('Find 5000', 5000, Vec.Find(5000));
    
    // 测试 Pop
    AssertEquals('Pop last', 9999, Vec.Pop);
    AssertEquals('Count after pop', 9999, Vec.Count);
  finally
    Vec.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Vec_Full);

end.
