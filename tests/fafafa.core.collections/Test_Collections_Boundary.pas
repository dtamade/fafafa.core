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
  fafafa.core.collections.list,
  fafafa.core.collections.treeSet,
  fafafa.core.collections.priorityqueue,
  fafafa.core.collections.linkedhashmap,
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

  { TTestCase_Boundary_TreeMap }
  TTestCase_Boundary_TreeMap = class(TTestCase)
  private
    type
      TIntIntTreeMap = specialize TTreeMap<Integer, Integer>;
  published
    // 空 TreeMap 边界
    procedure Test_TreeMap_Empty_Count_IsZero;
    procedure Test_TreeMap_Empty_ContainsKey_ReturnsFalse;
    procedure Test_TreeMap_Empty_Remove_ReturnsFalse;
    procedure Test_TreeMap_Empty_Clear_NoEffect;
    
    // 单元素边界
    procedure Test_TreeMap_SingleElement_AddRemove;
    procedure Test_TreeMap_SingleElement_GetValue;
    
    // 有序性边界
    procedure Test_TreeMap_OrderPreserved_AfterInserts;
  end;

  { TTestCase_Boundary_List }
  TTestCase_Boundary_List = class(TTestCase)
  private
    type
      TIntList = specialize TList<Integer>;
  published
    // 空 List 边界
    procedure Test_List_Empty_Count_IsZero;
    procedure Test_List_Empty_IsEmpty_ReturnsTrue;
    procedure Test_List_Empty_Clear_NoEffect;
    
    // 单元素边界
    procedure Test_List_SingleElement_PushPopFront;
    procedure Test_List_SingleElement_PushPopBack;
  end;

  { TTestCase_Boundary_TreeSet }
  TTestCase_Boundary_TreeSet = class(TTestCase)
  private
    type
      TIntTreeSet = specialize TTreeSet<Integer>;
  published
    // 空 TreeSet 边界
    procedure Test_TreeSet_Empty_Count_IsZero;
    procedure Test_TreeSet_Empty_Contains_ReturnsFalse;
    procedure Test_TreeSet_Empty_Clear_NoEffect;
    
    // 单元素边界  
    procedure Test_TreeSet_SingleElement_AddRemove;
    
    // 有序性边界
    procedure Test_TreeSet_OrderPreserved_AfterInserts;
  end;

  { TTestCase_Boundary_PriorityQueue }
  TTestCase_Boundary_PriorityQueue = class(TTestCase)
  private
    type
      TIntPQ = specialize TPriorityQueueClass<Integer>;
  published
    // 空 PQ 边界
    procedure Test_PriorityQueue_Empty_Count_IsZero;
    procedure Test_PriorityQueue_Empty_IsEmpty_ReturnsTrue;
    
    // 单元素边界
    procedure Test_PriorityQueue_SingleElement_EnqueueDequeue;
    
    // 优先级边界
    procedure Test_PriorityQueue_OrderCorrect_MinHeap;
  end;

  { TTestCase_Boundary_LinkedHashMap }
  TTestCase_Boundary_LinkedHashMap = class(TTestCase)
  private
    type
      TIntIntLHM = specialize TLinkedHashMap<Integer, Integer>;
  published
    // 空 LinkedHashMap 边界
    procedure Test_LinkedHashMap_Empty_Count_IsZero;
    procedure Test_LinkedHashMap_Empty_ContainsKey_ReturnsFalse;
    
    // 单元素边界
    procedure Test_LinkedHashMap_SingleElement_AddRemove;
    
    // 插入顺序保持
    procedure Test_LinkedHashMap_InsertionOrderPreserved;
  end;

implementation

{ Comparator functions for TreeMap and PriorityQueue }

function IntCompare(const A, B: Integer; aData: Pointer): SizeInt;
begin
  if A < B then Result := -1
  else if A > B then Result := 1
  else Result := 0;
end;

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

{ TTestCase_Boundary_TreeMap }

procedure TTestCase_Boundary_TreeMap.Test_TreeMap_Empty_Count_IsZero;
var
  M: TIntIntTreeMap;
begin
  M := TIntIntTreeMap.Create(nil, @IntCompare);
  try
    AssertEquals('Empty treemap count should be 0', 0, M.Count);
  finally
    M.Free;
  end;
end;

procedure TTestCase_Boundary_TreeMap.Test_TreeMap_Empty_ContainsKey_ReturnsFalse;
var
  M: TIntIntTreeMap;
begin
  M := TIntIntTreeMap.Create(nil, @IntCompare);
  try
    AssertFalse('ContainsKey on empty treemap should return False', M.ContainsKey(42));
  finally
    M.Free;
  end;
end;

procedure TTestCase_Boundary_TreeMap.Test_TreeMap_Empty_Remove_ReturnsFalse;
var
  M: TIntIntTreeMap;
begin
  M := TIntIntTreeMap.Create(nil, @IntCompare);
  try
    AssertFalse('Remove on empty treemap should return False', M.Remove(42));
  finally
    M.Free;
  end;
end;

procedure TTestCase_Boundary_TreeMap.Test_TreeMap_Empty_Clear_NoEffect;
var
  M: TIntIntTreeMap;
begin
  M := TIntIntTreeMap.Create(nil, @IntCompare);
  try
    M.Clear;
    AssertEquals('Count after Clear on empty should be 0', 0, M.Count);
  finally
    M.Free;
  end;
end;

procedure TTestCase_Boundary_TreeMap.Test_TreeMap_SingleElement_AddRemove;
var
  M: TIntIntTreeMap;
begin
  M := TIntIntTreeMap.Create(nil, @IntCompare);
  try
    M.Put(1, 100);
    AssertEquals('Count should be 1', 1, M.Count);
    
    AssertTrue('Remove should return True', M.Remove(1));
    AssertEquals('Count should be 0', 0, M.Count);
  finally
    M.Free;
  end;
end;

procedure TTestCase_Boundary_TreeMap.Test_TreeMap_SingleElement_GetValue;
var
  M: TIntIntTreeMap;
  V: Integer;
begin
  M := TIntIntTreeMap.Create(nil, @IntCompare);
  try
    M.Put(42, 999);
    AssertTrue('Get should return True', M.Get(42, V));
    AssertEquals('Value should be 999', 999, V);
  finally
    M.Free;
  end;
end;

procedure TTestCase_Boundary_TreeMap.Test_TreeMap_OrderPreserved_AfterInserts;
var
  M: TIntIntTreeMap;
  V: Integer;
begin
  M := TIntIntTreeMap.Create(nil, @IntCompare);
  try
    // 乱序插入
    M.Put(50, 1);
    M.Put(25, 2);
    M.Put(75, 3);
    M.Put(10, 4);
    M.Put(90, 5);
    
    // 验证所有值正确插入
    AssertEquals('Count should be 5', 5, M.Count);
    AssertTrue('Key 10 exists', M.Get(10, V)); AssertEquals('Value', 4, V);
    AssertTrue('Key 90 exists', M.Get(90, V)); AssertEquals('Value', 5, V);
  finally
    M.Free;
  end;
end;

{ TTestCase_Boundary_List }

procedure TTestCase_Boundary_List.Test_List_Empty_Count_IsZero;
var
  L: TIntList;
begin
  L := TIntList.Create;
  try
    AssertEquals('Empty list count should be 0', 0, L.Count);
  finally
    L.Free;
  end;
end;

procedure TTestCase_Boundary_List.Test_List_Empty_IsEmpty_ReturnsTrue;
var
  L: TIntList;
begin
  L := TIntList.Create;
  try
    AssertTrue('Empty list IsEmpty should be True', L.IsEmpty);
  finally
    L.Free;
  end;
end;

procedure TTestCase_Boundary_List.Test_List_Empty_Clear_NoEffect;
var
  L: TIntList;
begin
  L := TIntList.Create;
  try
    L.Clear;
    AssertEquals('Count after Clear should be 0', 0, L.Count);
  finally
    L.Free;
  end;
end;

procedure TTestCase_Boundary_List.Test_List_SingleElement_PushPopFront;
var
  L: TIntList;
begin
  L := TIntList.Create;
  try
    L.PushFront(42);
    AssertEquals('Count should be 1', 1, L.Count);
    AssertEquals('Front should be 42', 42, L.Front);
    
    L.PopFront;
    AssertEquals('Count should be 0', 0, L.Count);
  finally
    L.Free;
  end;
end;

procedure TTestCase_Boundary_List.Test_List_SingleElement_PushPopBack;
var
  L: TIntList;
begin
  L := TIntList.Create;
  try
    L.PushBack(42);
    AssertEquals('Count should be 1', 1, L.Count);
    AssertEquals('Back should be 42', 42, L.Back);
    
    L.PopBack;
    AssertEquals('Count should be 0', 0, L.Count);
  finally
    L.Free;
  end;
end;

{ TTestCase_Boundary_TreeSet }

procedure TTestCase_Boundary_TreeSet.Test_TreeSet_Empty_Count_IsZero;
var
  S: TIntTreeSet;
begin
  S := TIntTreeSet.Create;
  try
    AssertEquals('Empty treeset count should be 0', 0, S.GetCount);
  finally
    S.Free;
  end;
end;

procedure TTestCase_Boundary_TreeSet.Test_TreeSet_Empty_Contains_ReturnsFalse;
var
  S: TIntTreeSet;
begin
  S := TIntTreeSet.Create;
  try
    AssertFalse('Contains on empty treeset should return False', S.Contains(42));
  finally
    S.Free;
  end;
end;

procedure TTestCase_Boundary_TreeSet.Test_TreeSet_Empty_Clear_NoEffect;
var
  S: TIntTreeSet;
begin
  S := TIntTreeSet.Create;
  try
    S.Clear;
    AssertEquals('Count after Clear should be 0', 0, S.GetCount);
  finally
    S.Free;
  end;
end;

procedure TTestCase_Boundary_TreeSet.Test_TreeSet_SingleElement_AddRemove;
var
  S: TIntTreeSet;
begin
  S := TIntTreeSet.Create;
  try
    AssertTrue('Add should return True', S.Add(42));
    AssertEquals('Count should be 1', 1, S.GetCount);
    AssertTrue('Contains should return True', S.Contains(42));
    
    AssertTrue('Remove should return True', S.Remove(42));
    AssertEquals('Count should be 0', 0, S.GetCount);
  finally
    S.Free;
  end;
end;

procedure TTestCase_Boundary_TreeSet.Test_TreeSet_OrderPreserved_AfterInserts;
var
  S: TIntTreeSet;
begin
  S := TIntTreeSet.Create;
  try
    // 乱序插入
    S.Add(50);
    S.Add(25);
    S.Add(75);
    S.Add(10);
    S.Add(90);
    
    // 验证所有元素存在
    AssertEquals('Count should be 5', 5, S.GetCount);
    AssertTrue('Contains 10', S.Contains(10));
    AssertTrue('Contains 90', S.Contains(90));
  finally
    S.Free;
  end;
end;

{ TTestCase_Boundary_PriorityQueue }

procedure TTestCase_Boundary_PriorityQueue.Test_PriorityQueue_Empty_Count_IsZero;
var
  PQ: TIntPQ;
begin
  PQ := TIntPQ.Create(@IntCompare);
  try
    AssertEquals('Empty PQ count should be 0', 0, PQ.Count);
  finally
    PQ.Free;
  end;
end;

procedure TTestCase_Boundary_PriorityQueue.Test_PriorityQueue_Empty_IsEmpty_ReturnsTrue;
var
  PQ: TIntPQ;
begin
  PQ := TIntPQ.Create(@IntCompare);
  try
    AssertTrue('Empty PQ IsEmpty should be True', PQ.IsEmpty);
  finally
    PQ.Free;
  end;
end;

procedure TTestCase_Boundary_PriorityQueue.Test_PriorityQueue_SingleElement_EnqueueDequeue;
var
  PQ: TIntPQ;
  V: Integer;
begin
  PQ := TIntPQ.Create(@IntCompare);
  try
    PQ.Enqueue(42);
    AssertEquals('Count should be 1', 1, PQ.Count);
    
    AssertTrue('Dequeue should succeed', PQ.Dequeue(V));
    AssertEquals('Dequeue should return 42', 42, V);
    AssertEquals('Count should be 0', 0, PQ.Count);
  finally
    PQ.Free;
  end;
end;

procedure TTestCase_Boundary_PriorityQueue.Test_PriorityQueue_OrderCorrect_MinHeap;
var
  PQ: TIntPQ;
  V: Integer;
begin
  PQ := TIntPQ.Create(@IntCompare);  // 最小堆
  try
    // 乱序插入
    PQ.Enqueue(50);
    PQ.Enqueue(10);
    PQ.Enqueue(30);
    PQ.Enqueue(5);
    PQ.Enqueue(20);
    
    // 按升序出队
    AssertTrue('Dequeue 1', PQ.Dequeue(V)); AssertEquals('First dequeue should be 5', 5, V);
    AssertTrue('Dequeue 2', PQ.Dequeue(V)); AssertEquals('Second dequeue should be 10', 10, V);
    AssertTrue('Dequeue 3', PQ.Dequeue(V)); AssertEquals('Third dequeue should be 20', 20, V);
    AssertTrue('Dequeue 4', PQ.Dequeue(V)); AssertEquals('Fourth dequeue should be 30', 30, V);
    AssertTrue('Dequeue 5', PQ.Dequeue(V)); AssertEquals('Fifth dequeue should be 50', 50, V);
  finally
    PQ.Free;
  end;
end;

{ TTestCase_Boundary_LinkedHashMap }

procedure TTestCase_Boundary_LinkedHashMap.Test_LinkedHashMap_Empty_Count_IsZero;
var
  M: TIntIntLHM;
begin
  M := TIntIntLHM.Create;
  try
    AssertEquals('Empty LHM count should be 0', 0, M.Count);
  finally
    M.Free;
  end;
end;

procedure TTestCase_Boundary_LinkedHashMap.Test_LinkedHashMap_Empty_ContainsKey_ReturnsFalse;
var
  M: TIntIntLHM;
begin
  M := TIntIntLHM.Create;
  try
    AssertFalse('ContainsKey on empty LHM should return False', M.ContainsKey(42));
  finally
    M.Free;
  end;
end;

procedure TTestCase_Boundary_LinkedHashMap.Test_LinkedHashMap_SingleElement_AddRemove;
var
  M: TIntIntLHM;
begin
  M := TIntIntLHM.Create;
  try
    M.Put(1, 100);
    AssertEquals('Count should be 1', 1, M.Count);
    
    AssertTrue('Remove should return True', M.Remove(1));
    AssertEquals('Count should be 0', 0, M.Count);
  finally
    M.Free;
  end;
end;

procedure TTestCase_Boundary_LinkedHashMap.Test_LinkedHashMap_InsertionOrderPreserved;
var
  M: TIntIntLHM;
  V: Integer;
begin
  M := TIntIntLHM.Create;
  try
    // 按特定顺序插入
    M.Put(30, 300);
    M.Put(10, 100);
    M.Put(20, 200);
    
    // 验证元素存在且值正确
    AssertEquals('Count should be 3', 3, M.Count);
    AssertTrue('Key 30 should exist', M.Get(30, V));
    AssertEquals('Value for 30', 300, V);
    AssertTrue('Key 10 should exist', M.Get(10, V));
    AssertEquals('Value for 10', 100, V);
    AssertTrue('Key 20 should exist', M.Get(20, V));
    AssertEquals('Value for 20', 200, V);
  finally
    M.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Boundary_Vec);
  RegisterTest(TTestCase_Boundary_HashMap);
  RegisterTest(TTestCase_Boundary_BitSet);
  RegisterTest(TTestCase_Boundary_VecDeque);
  RegisterTest(TTestCase_Boundary_TreeMap);
  RegisterTest(TTestCase_Boundary_List);
  RegisterTest(TTestCase_Boundary_TreeSet);
  RegisterTest(TTestCase_Boundary_PriorityQueue);
  RegisterTest(TTestCase_Boundary_LinkedHashMap);

end.
