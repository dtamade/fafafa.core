unit Test_Collections_Boundary;

{**
 * @desc 边界测试：验证集合在边界条件下的行为
 * @purpose Phase 4 - 边界测试增强
 * 
 * 覆盖场景：
 *   - 空集合操作
 *   - 单元素集合
 *   - 容量边界
 *   - 零值/默认值
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.collections.vec,
  fafafa.core.collections.hashmap,
  fafafa.core.collections.treemap,
  fafafa.core.collections.bitset,
  fafafa.core.collections.vecdeque,
  fafafa.core.mem.allocator;

type
  { TTestCase_Boundary_Vec }
  TTestCase_Boundary_Vec = class(TTestCase)
  private
    type
      TIntVec = specialize TVec<Integer>;
  published
    // 空集合边界
    procedure Test_Vec_Empty_Count_IsZero;
    procedure Test_Vec_Empty_IsEmpty_ReturnsTrue;
    procedure Test_Vec_Empty_Clear_NoEffect;
    
    // 单元素边界
    procedure Test_Vec_SingleElement_Add_Remove;
    procedure Test_Vec_SingleElement_Get;
    
    // 容量边界
    procedure Test_Vec_Reserve_Zero_NoEffect;
    procedure Test_Vec_Reserve_Large_Succeeds;
    procedure Test_Vec_ShrinkToFit_EmptyVec;
  end;

  { TTestCase_Boundary_HashMap }
  TTestCase_Boundary_HashMap = class(TTestCase)
  private
    type
      TIntIntMap = specialize THashMap<Integer, Integer>;
  published
    // 空 Map 边界
    procedure Test_HashMap_Empty_Count_IsZero;
    procedure Test_HashMap_Empty_ContainsKey_ReturnsFalse;
    procedure Test_HashMap_Empty_Remove_ReturnsFalse;
    procedure Test_HashMap_Empty_Clear_NoEffect;
    
    // 单元素边界
    procedure Test_HashMap_SingleElement_AddRemove;
    procedure Test_HashMap_SingleElement_GetValue;
    
    // 容量边界
    procedure Test_HashMap_Reserve_Zero_NoEffect;
    procedure Test_HashMap_Rehash_AfterManyInserts;
  end;

  { TTestCase_Boundary_BitSet }
  TTestCase_Boundary_BitSet = class(TTestCase)
  published
    // 位边界 (0, 63, 64, 65 - 跨 UInt64 边界)
    procedure Test_BitSet_Bit0_SetClearTest;
    procedure Test_BitSet_Bit63_SetClearTest;
    procedure Test_BitSet_Bit64_CrossWordBoundary;
    procedure Test_BitSet_Bit65_CrossWordBoundary;
    
    // 空 BitSet 边界
    procedure Test_BitSet_Empty_Cardinality_IsZero;
    procedure Test_BitSet_Empty_Test_ReturnsFalse;
    
    // 容量边界
    procedure Test_BitSet_AutoExpand_OnSetBit;
  end;

  { TTestCase_Boundary_VecDeque }
  TTestCase_Boundary_VecDeque = class(TTestCase)
  private
    type
      TIntDeque = specialize TVecDeque<Integer>;
  published
    // 空 Deque 边界
    procedure Test_VecDeque_Empty_Count_IsZero;
    procedure Test_VecDeque_Empty_IsEmpty_ReturnsTrue;
    
    // 环形缓冲区边界
    procedure Test_VecDeque_WrapAround_PushPopFront;
    procedure Test_VecDeque_WrapAround_PushPopBack;
  end;

implementation

{ TTestCase_Boundary_Vec }

procedure TTestCase_Boundary_Vec.Test_Vec_Empty_Count_IsZero;
var
  V: TIntVec;
begin
  V := TIntVec.Create;
  try
    AssertEquals('Empty vec count should be 0', 0, V.Count);
  finally
    V.Free;
  end;
end;

procedure TTestCase_Boundary_Vec.Test_Vec_Empty_IsEmpty_ReturnsTrue;
var
  V: TIntVec;
begin
  V := TIntVec.Create;
  try
    AssertTrue('Empty vec IsEmpty should be True', V.IsEmpty);
  finally
    V.Free;
  end;
end;

procedure TTestCase_Boundary_Vec.Test_Vec_Empty_Clear_NoEffect;
var
  V: TIntVec;
begin
  V := TIntVec.Create;
  try
    V.Clear;  // 对空 Vec 调用 Clear 不应崩溃
    AssertEquals('Count after Clear on empty should be 0', 0, V.Count);
  finally
    V.Free;
  end;
end;

procedure TTestCase_Boundary_Vec.Test_Vec_SingleElement_Add_Remove;
var
  V: TIntVec;
begin
  V := TIntVec.Create;
  try
    V.Push(42);
    AssertEquals('Count after PushBack should be 1', 1, V.Count);
    AssertFalse('IsEmpty after PushBack should be False', V.IsEmpty);
    
    V.Clear;
    AssertEquals('Count after Clear should be 0', 0, V.Count);
    AssertTrue('IsEmpty after Clear should be True', V.IsEmpty);
  finally
    V.Free;
  end;
end;

procedure TTestCase_Boundary_Vec.Test_Vec_SingleElement_Get;
var
  V: TIntVec;
begin
  V := TIntVec.Create;
  try
    V.Push(123);
    AssertEquals('Get(0) should return 123', 123, V.Get(0));
  finally
    V.Free;
  end;
end;

procedure TTestCase_Boundary_Vec.Test_Vec_Reserve_Zero_NoEffect;
var
  V: TIntVec;
begin
  V := TIntVec.Create;
  try
    V.Reserve(0);  // Reserve(0) 不应崩溃
    AssertEquals('Count should remain 0', 0, V.Count);
  finally
    V.Free;
  end;
end;

procedure TTestCase_Boundary_Vec.Test_Vec_Reserve_Large_Succeeds;
var
  V: TIntVec;
begin
  V := TIntVec.Create;
  try
    V.Reserve(10000);
    AssertTrue('Capacity should be >= 10000', V.Capacity >= 10000);
    AssertEquals('Count should remain 0', 0, V.Count);
  finally
    V.Free;
  end;
end;

procedure TTestCase_Boundary_Vec.Test_Vec_ShrinkToFit_EmptyVec;
var
  V: TIntVec;
begin
  V := TIntVec.Create;
  try
    V.Reserve(1000);
    V.ShrinkToFit;  // 空 Vec 的 ShrinkToFit 不应崩溃
    // 不检查具体容量，因为滞回策略可能保留一些空间
    AssertEquals('Count should remain 0', 0, V.Count);
  finally
    V.Free;
  end;
end;

{ TTestCase_Boundary_HashMap }

procedure TTestCase_Boundary_HashMap.Test_HashMap_Empty_Count_IsZero;
var
  M: TIntIntMap;
begin
  M := TIntIntMap.Create;
  try
    AssertEquals('Empty map count should be 0', 0, M.GetCount);
  finally
    M.Free;
  end;
end;

procedure TTestCase_Boundary_HashMap.Test_HashMap_Empty_ContainsKey_ReturnsFalse;
var
  M: TIntIntMap;
begin
  M := TIntIntMap.Create;
  try
    AssertFalse('ContainsKey on empty map should return False', M.ContainsKey(42));
  finally
    M.Free;
  end;
end;

procedure TTestCase_Boundary_HashMap.Test_HashMap_Empty_Remove_ReturnsFalse;
var
  M: TIntIntMap;
begin
  M := TIntIntMap.Create;
  try
    AssertFalse('Remove on empty map should return False', M.Remove(42));
  finally
    M.Free;
  end;
end;

procedure TTestCase_Boundary_HashMap.Test_HashMap_Empty_Clear_NoEffect;
var
  M: TIntIntMap;
begin
  M := TIntIntMap.Create;
  try
    M.Clear;  // 对空 Map 调用 Clear 不应崩溃
    AssertEquals('Count after Clear on empty should be 0', 0, M.GetCount);
  finally
    M.Free;
  end;
end;

procedure TTestCase_Boundary_HashMap.Test_HashMap_SingleElement_AddRemove;
var
  M: TIntIntMap;
begin
  M := TIntIntMap.Create;
  try
    AssertTrue('Add should return True for new key', M.Add(1, 100));
    AssertEquals('Count should be 1', 1, M.GetCount);
    
    AssertTrue('Remove should return True for existing key', M.Remove(1));
    AssertEquals('Count should be 0', 0, M.GetCount);
  finally
    M.Free;
  end;
end;

procedure TTestCase_Boundary_HashMap.Test_HashMap_SingleElement_GetValue;
var
  M: TIntIntMap;
  V: Integer;
begin
  M := TIntIntMap.Create;
  try
    M.Put(42, 999);
    AssertTrue('Get should return True', M.Get(42, V));
    AssertEquals('Value should be 999', 999, V);
  finally
    M.Free;
  end;
end;

procedure TTestCase_Boundary_HashMap.Test_HashMap_Reserve_Zero_NoEffect;
var
  M: TIntIntMap;
begin
  M := TIntIntMap.Create;
  try
    M.Reserve(0);  // Reserve(0) 不应崩溃
    AssertEquals('Count should remain 0', 0, M.GetCount);
  finally
    M.Free;
  end;
end;

procedure TTestCase_Boundary_HashMap.Test_HashMap_Rehash_AfterManyInserts;
var
  M: TIntIntMap;
  I: Integer;
  V: Integer;
begin
  M := TIntIntMap.Create;
  try
    // 插入足够多的元素触发多次 rehash
    for I := 0 to 999 do
      M.Put(I, I * 10);
    
    AssertEquals('Count should be 1000', 1000, M.GetCount);
    
    // 验证所有元素仍可访问
    for I := 0 to 999 do
    begin
      AssertTrue(Format('Key %d should exist', [I]), M.Get(I, V));
      AssertEquals(Format('Value for key %d', [I]), I * 10, V);
    end;
  finally
    M.Free;
  end;
end;

{ TTestCase_Boundary_BitSet }

procedure TTestCase_Boundary_BitSet.Test_BitSet_Bit0_SetClearTest;
var
  B: TBitSet;
begin
  B := TBitSet.Create;
  try
    B.SetBit(0);
    AssertTrue('Bit 0 should be set', B.Test(0));
    
    B.ClearBit(0);
    AssertFalse('Bit 0 should be cleared', B.Test(0));
  finally
    B.Free;
  end;
end;

procedure TTestCase_Boundary_BitSet.Test_BitSet_Bit63_SetClearTest;
var
  B: TBitSet;
begin
  B := TBitSet.Create;
  try
    B.SetBit(63);  // 第一个 UInt64 的最后一位
    AssertTrue('Bit 63 should be set', B.Test(63));
    
    B.ClearBit(63);
    AssertFalse('Bit 63 should be cleared', B.Test(63));
  finally
    B.Free;
  end;
end;

procedure TTestCase_Boundary_BitSet.Test_BitSet_Bit64_CrossWordBoundary;
var
  B: TBitSet;
begin
  B := TBitSet.Create;
  try
    B.SetBit(64);  // 第二个 UInt64 的第一位
    AssertTrue('Bit 64 should be set', B.Test(64));
    AssertFalse('Bit 63 should not be affected', B.Test(63));
    AssertFalse('Bit 65 should not be affected', B.Test(65));
  finally
    B.Free;
  end;
end;

procedure TTestCase_Boundary_BitSet.Test_BitSet_Bit65_CrossWordBoundary;
var
  B: TBitSet;
begin
  B := TBitSet.Create;
  try
    B.SetBit(63);  // 边界两侧
    B.SetBit(64);
    B.SetBit(65);
    
    AssertTrue('Bit 63 should be set', B.Test(63));
    AssertTrue('Bit 64 should be set', B.Test(64));
    AssertTrue('Bit 65 should be set', B.Test(65));
    AssertEquals('Cardinality should be 3', 3, B.Cardinality);
  finally
    B.Free;
  end;
end;

procedure TTestCase_Boundary_BitSet.Test_BitSet_Empty_Cardinality_IsZero;
var
  B: TBitSet;
begin
  B := TBitSet.Create;
  try
    AssertEquals('Empty BitSet cardinality should be 0', 0, B.Cardinality);
  finally
    B.Free;
  end;
end;

procedure TTestCase_Boundary_BitSet.Test_BitSet_Empty_Test_ReturnsFalse;
var
  B: TBitSet;
begin
  B := TBitSet.Create;
  try
    AssertFalse('Test(0) on empty should return False', B.Test(0));
    AssertFalse('Test(1000) on empty should return False', B.Test(1000));
  finally
    B.Free;
  end;
end;

procedure TTestCase_Boundary_BitSet.Test_BitSet_AutoExpand_OnSetBit;
var
  B: TBitSet;
begin
  B := TBitSet.Create(64);  // 初始容量 64 位
  try
    B.SetBit(1000);  // 远超初始容量
    AssertTrue('Bit 1000 should be set after auto-expand', B.Test(1000));
    AssertTrue('BitCapacity should be >= 1001', B.BitCapacity >= 1001);
  finally
    B.Free;
  end;
end;

{ TTestCase_Boundary_VecDeque }

procedure TTestCase_Boundary_VecDeque.Test_VecDeque_Empty_Count_IsZero;
var
  D: TIntDeque;
begin
  D := TIntDeque.Create;
  try
    AssertEquals('Empty deque count should be 0', 0, D.Count);
  finally
    D.Free;
  end;
end;

procedure TTestCase_Boundary_VecDeque.Test_VecDeque_Empty_IsEmpty_ReturnsTrue;
var
  D: TIntDeque;
begin
  D := TIntDeque.Create;
  try
    AssertTrue('Empty deque IsEmpty should be True', D.IsEmpty);
  finally
    D.Free;
  end;
end;

procedure TTestCase_Boundary_VecDeque.Test_VecDeque_WrapAround_PushPopFront;
var
  D: TIntDeque;
  I: Integer;
begin
  D := TIntDeque.Create;
  try
    // 通过反复 PushFront/PopBack 使 head 绕回
    for I := 1 to 100 do
    begin
      D.PushFront(I);
      D.PushFront(I + 100);
      D.PopBack;
    end;
    
    // 验证最后状态一致
    AssertEquals('Count should be 100', 100, D.Count);
  finally
    D.Free;
  end;
end;

procedure TTestCase_Boundary_VecDeque.Test_VecDeque_WrapAround_PushPopBack;
var
  D: TIntDeque;
  I: Integer;
begin
  D := TIntDeque.Create;
  try
    // 通过反复 PushBack/PopFront 使 tail 绕回
    for I := 1 to 100 do
    begin
      D.PushBack(I);
      D.PushBack(I + 100);
      D.PopFront;
    end;
    
    // 验证最后状态一致
    AssertEquals('Count should be 100', 100, D.Count);
  finally
    D.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Boundary_Vec);
  RegisterTest(TTestCase_Boundary_HashMap);
  RegisterTest(TTestCase_Boundary_BitSet);
  RegisterTest(TTestCase_Boundary_VecDeque);

end.
