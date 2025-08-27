{$CODEPAGE UTF8}
unit Test_fafafa_core_collections_vecdeque_clean;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.base,
  fafafa.core.mem.allocator,
  fafafa.core.collections.base,
  fafafa.core.collections.arr,
  fafafa.core.collections.vec,
  fafafa.core.collections.queue,
  fafafa.core.collections.deque,
  fafafa.core.collections.vecdeque;

type

  { TTestCase_VecDeque - VecDeque 完整测试套件
    按照 VecDeque 的所有接口方法命名测试过程 }
  TTestCase_VecDeque = class(TTestCase)
  private
    FVecDeque: specialize TVecDeque<Integer>;
    // 测试辅助方法（方法指针版本）
    function EqualsIntMethod(const aLeft, aRight: Integer; aData: Pointer): Boolean;
    function PredicateEvenMethod(const aValue: Integer; aData: Pointer): Boolean;
    procedure ExpectSeq(const Expected: array of Integer);

  protected
    procedure SetUp; override;
    procedure TearDown; override;

  published
    { ===== 构造函数测试 (14个) ===== }
    procedure Test_Create;
    procedure Test_Create_Allocator_Data;
    procedure Test_Create_Allocator_GrowStrategy;
    procedure Test_Create_Allocator_GrowStrategy_Data;
    procedure Test_Create_Capacity;
    procedure Test_Create_Capacity_Allocator;
    procedure Test_Create_Capacity_Allocator_GrowStrategy;
    procedure Test_Create_Capacity_Allocator_GrowStrategy_Data;
    procedure Test_Create_Collection_Allocator_GrowStrategy;
    procedure Test_Create_Collection_Allocator_GrowStrategy_Data;
    procedure Test_Create_Pointer_Count_Allocator_GrowStrategy;
    procedure Test_Create_Pointer_Count_Allocator_GrowStrategy_Data;
    procedure Test_Create_Array_Allocator_GrowStrategy;
    procedure Test_Create_Array_Allocator_GrowStrategy_Data;
    procedure Test_Destroy;


    // Now publish ICollection block for next batch
    published

    { ===== ICollection 接口方法测试 (6个) ===== }
    procedure Test_PtrIter;
    procedure Test_GetCount;
    procedure Test_Clear;
    procedure Test_SerializeToArrayBuffer;
    procedure Test_AppendUnChecked;
    procedure Test_AppendToUnChecked;

    // publish IGenericCollection for next batch
    published


    { ===== IGenericCollection 接口方法测试 (1个) ===== }
    procedure Test_SaveToUnChecked;


    // publish IArray batch A (basic accessors)
    published

    { ===== IArray 接口方法测试 (33个) ===== }
    procedure Test_GetMemory;
    procedure Test_Get;
    procedure Test_GetUnChecked;
    procedure Test_Put;
    procedure Test_PutUnChecked;
    procedure Test_GetPtr;
    procedure Test_GetPtrUnChecked;

    // publish IArray batch B (size/capacity)
    published

    procedure Test_Resize;
    procedure Test_Resize_Value;
    procedure Test_Ensure;

    // publish IArray batch C (Overwrite/Read)
    published

    procedure Test_OverWrite_Pointer;
    procedure Test_OverWriteUnChecked_Pointer;
    procedure Test_OverWrite_Array;
    procedure Test_OverWriteUnChecked_Array;
    procedure Test_OverWrite_Collection;
    procedure Test_OverWriteUnChecked_Collection;
    procedure Test_Read_Pointer;
    procedure Test_ReadUnChecked_Pointer;
    procedure Test_Read_Collection;
    procedure Test_ReadUnChecked_Collection;
    procedure Test_Swap_TwoElements;
    procedure Test_SwapUnChecked_TwoElements;
    procedure Test_Swap_Range;
    procedure Test_Swap_Stride;
    procedure Test_Copy;
    procedure Test_CopyUnChecked;
    procedure Test_Fill_Single;
    procedure Test_Fill_Range;
    procedure Test_FillUnChecked;
    procedure Test_Zero_Single;
    procedure Test_Zero_Range;
    procedure Test_ZeroUnChecked;
    procedure Test_Reverse_Single;
    procedure Test_Reverse_Range;
    procedure Test_ReverseUnChecked;


    // publish ForEach batch
    published

    { ===== ForEach 系列方法测试 (15个) ===== }
    procedure Test_ForEach_PredicateFunc;
    procedure Test_ForEach_PredicateMethod;
    procedure Test_ForEach_PredicateRefFunc;
    procedure Test_ForEach_Index_PredicateFunc;
    procedure Test_ForEach_Index_PredicateMethod;
    procedure Test_ForEach_Index_PredicateRefFunc;
    procedure Test_ForEach_Index_Count_PredicateFunc;
    procedure Test_ForEach_Index_Count_PredicateMethod;
    procedure Test_ForEach_Index_Count_PredicateRefFunc;
    procedure Test_ForEachUnChecked_PredicateFunc;
    procedure Test_ForEachUnChecked_PredicateMethod;
    procedure Test_ForEachUnChecked_PredicateRefFunc;
    procedure Test_ForEachUnChecked_Index_Count_PredicateFunc;
    procedure Test_ForEachUnChecked_Index_Count_PredicateMethod;

    // publish ForEach tail method too
    published

    procedure Test_ForEachUnChecked_Index_Count_PredicateRefFunc;

    // publish Contains batch
    published

    { ===== Contains 系列方法测试 (16个) ===== }
    procedure Test_Contains_Element;
    procedure Test_Contains_Element_EqualsFunc;
    procedure Test_Contains_Element_EqualsMethod;
    procedure Test_Contains_Element_EqualsRefFunc;
    procedure Test_Contains_Element_Index;
    procedure Test_Contains_Element_Index_EqualsFunc;
    procedure Test_Contains_Element_Index_EqualsMethod;
    procedure Test_Contains_Element_Index_EqualsRefFunc;
    procedure Test_Contains_Element_Index_Count;
    procedure Test_Contains_Element_Index_Count_EqualsFunc;
    procedure Test_Contains_Element_Index_Count_EqualsMethod;
    procedure Test_Contains_Element_Index_Count_EqualsRefFunc;
    procedure Test_ContainsUnChecked_Element;
    procedure Test_ContainsUnChecked_Element_EqualsFunc;
    procedure Test_ContainsUnChecked_Element_EqualsMethod;
    procedure Test_ContainsUnChecked_Element_EqualsRefFunc;


    // publish Find/FindIF/FindIFNot/FindLast batch
    published

    { ===== Find 系列方法测试 (24个) ===== }
    procedure Test_Find_Element;
    procedure Test_Find_Element_EqualsFunc;
    procedure Test_Find_Element_EqualsMethod;
    procedure Test_Find_Element_EqualsRefFunc;
    procedure Test_Find_Element_Index;
    procedure Test_Find_Element_Index_EqualsFunc;
    procedure Test_Find_Element_Index_EqualsMethod;
    procedure Test_Find_Element_Index_EqualsRefFunc;
    procedure Test_Find_Element_Index_Count;
    procedure Test_Find_Element_Index_Count_EqualsFunc;
    procedure Test_Find_Element_Index_Count_EqualsMethod;
    procedure Test_Find_Element_Index_Count_EqualsRefFunc;
    procedure Test_FindUnChecked_Element;
    procedure Test_FindUnChecked_Element_EqualsFunc;
    procedure Test_FindUnChecked_Element_EqualsMethod;
    procedure Test_FindUnChecked_Element_EqualsRefFunc;
    procedure Test_FindIF_PredicateFunc;
    procedure Test_FindIF_PredicateMethod;
    procedure Test_FindIF_PredicateRefFunc;
    procedure Test_FindIFUnChecked_PredicateFunc;
    procedure Test_FindIFUnChecked_PredicateMethod;
    procedure Test_FindIFUnChecked_PredicateRefFunc;
    procedure Test_FindIFNotUnChecked_PredicateFunc;
    procedure Test_FindIFNotUnChecked_PredicateMethod;
    procedure Test_FindIFNotUnChecked_PredicateRefFunc;

    // stop after Find/FindIF/FindIFNot/FindLast batch
    protected


    { ===== IVec 接口方法测试 (25个) ===== }
    procedure Test_GetCapacity;
    procedure Test_SetCapacity;
    procedure Test_GetGrowStrategy;
    procedure Test_SetGrowStrategy;
    procedure Test_TryReserve;
    procedure Test_TryReserveExact;
    procedure Test_Reserve;
    procedure Test_ReserveExact;
    procedure Test_ShrinkToFit;
    procedure Test_Shrink;
    procedure Test_ShrinkTo;
    procedure Test_Truncate;
    procedure Test_ResizeExact;
    procedure Test_Insert_Index_Element;
    procedure Test_Insert_Index_Array;
    procedure Test_Insert_Index_Pointer_Count;
    procedure Test_Insert_Index_Collection_StartIndex;
    // Boundary matrix (array-based): continuous vs wrap x indices 0,1,Count-1,Count
    procedure Test_Insert_BoundaryMatrix_Array_Continuous;
    procedure Test_Insert_BoundaryMatrix_Array_Wrap;
    procedure Test_Write_BoundaryMatrix_Array_Continuous;
    procedure Test_Write_BoundaryMatrix_Array_Wrap;
    // Boundary matrix (pointer/collection): continuous and wrap
    procedure Test_Insert_BoundaryMatrix_Pointer_Continuous;
    procedure Test_Insert_BoundaryMatrix_Pointer_Wrap;
    procedure Test_Write_BoundaryMatrix_Pointer_Continuous;
    procedure Test_Write_BoundaryMatrix_Pointer_Wrap;
    procedure Test_Insert_BoundaryMatrix_Collection_Continuous;
    procedure Test_Insert_BoundaryMatrix_Collection_Wrap;
    procedure Test_Write_BoundaryMatrix_Collection_Continuous;
    procedure Test_Write_BoundaryMatrix_Collection_Wrap;
    // Cross-segment patterns and multi-grow consistency
    procedure Test_Insert_CrossSegments_Patterns;
    procedure Test_Write_CrossSegments_Patterns;
    procedure Test_MultiGrow_PowerOfTwo_Consistency;
    procedure Test_MultiGrow_InsertWrite_Checkpoints;
    procedure Test_TryOps_AfterWrapAndGrow_Baseline;
    procedure Test_Random_MixedOps_Steps_Small;
    procedure Test_Capacity_Boundaries_Small;
    // Full-sequence checks + large growth + Try*/Safe consistency
    procedure Test_Insert_Write_BoundaryMatrix_Array_FullSeq;
    procedure Test_Insert_Write_BoundaryMatrix_Pointer_FullSeq;
    procedure Test_Insert_Write_BoundaryMatrix_Collection_FullSeq;
    procedure Test_LargeGrowth_Wrap_MultiExpansion;
    procedure Test_TryAndSafe_BoundaryConsistency;
    procedure Test_TryAndSafe_Matrix_Empty_Single_Multi_Wrap;
    procedure Test_Remove_Index;
    procedure Test_Remove_Index_Count;
    procedure Test_RemoveSwap_Index;
    procedure Test_RemoveSwap_Index_Count;
    procedure Test_Add_Element;
    procedure Test_Add_Array;
    procedure Test_Add_Pointer_Count;
    procedure Test_Add_Collection;

    { ===== IQueue 接口方法测试 (35个) ===== }
    procedure Test_Enqueue_Element;
    procedure Test_Enqueue_Array;
    procedure Test_Enqueue_Pointer_Count;
    procedure Test_Enqueue_Collection;
    procedure Test_Push_Element;
    procedure Test_Push_Array;
    procedure Test_Push_Pointer_Count;
    procedure Test_Push_Collection;
    procedure Test_Push_Collection_StartIndex;
    procedure Test_Dequeue;
    procedure Test_Pop;
    procedure Test_Peek;
    procedure Test_Dequeue_Safe;
    procedure Test_Pop_Safe;
    procedure Test_Peek_Safe;
    procedure Test_Front;
    procedure Test_Front_Safe;
    procedure Test_Back;
    procedure Test_Back_Safe;
    procedure Test_TryGet;
    procedure Test_TryRemove;
    procedure Test_TryPop_Element;
    procedure Test_TryPop_Pointer_Count;
    procedure Test_TryPop_Array_Count;
    procedure Test_TryPeek_Element;
    procedure Test_TryPeek_Pointer_Count;
    procedure Test_TryPeek_Array_Count;
    procedure Test_TryPeekCopy_Pointer_Count;
    procedure Test_TryPeekCopy_Pointer_Wrap_CrossSegment;
    procedure Test_TryGet_TryRemove_Wrap_Small;
    procedure Test_PeekRange;
    procedure Test_Append_Queue;
    procedure Test_SplitOff;
    procedure Test_FillWith;
    procedure Test_ClearAndReserve;
    procedure Test_SwapRange;
    procedure Test_WarmupMemory;

    { ===== IDeque 接口方法测试 (18个) ===== }
    procedure Test_PushFront_Element;
    procedure Test_PushFront_Array;
    procedure Test_PushFront_Pointer_Count;
    procedure Test_PushFront_Collection;
    procedure Test_PushBack_Element;
    procedure Test_PushBack_Array;
    procedure Test_PushBack_Pointer_Count;
    procedure Test_PushBack_Collection;
    procedure Test_PopFront;
    procedure Test_PopFront_Safe;
    procedure Test_PopBack;
    procedure Test_PopBack_Safe;
    procedure Test_PeekFront;
    procedure Test_PeekFront_Safe;
    procedure Test_PeekBack;
    procedure Test_PeekBack_Safe;
    procedure Test_FastIndexOf;
    procedure Test_FastLastIndexOf;

    // publish CountOf/CountIF batch
    published

    { ===== 算法和排序方法测试 (60个) ===== }
    procedure Test_CountOf_Element;
    procedure Test_CountOf_Element_EqualsFunc;
    procedure Test_CountOf_Element_EqualsMethod;
    procedure Test_CountOf_Element_EqualsRefFunc;
    procedure Test_CountIF_PredicateFunc;

    procedure Test_CountIF_PredicateMethod;
    procedure Test_CountIF_PredicateRefFunc;

    // publish Replace/ReplaceIF head
    published

    procedure Test_Replace_OldValue_NewValue;
    procedure Test_Replace_OldValue_NewValue_EqualsFunc;
    procedure Test_Replace_OldValue_NewValue_EqualsMethod;
    procedure Test_Replace_OldValue_NewValue_EqualsRefFunc;
    procedure Test_ReplaceIf_NewValue_PredicateFunc;
    procedure Test_ReplaceIf_NewValue_PredicateMethod;
    procedure Test_ReplaceIf_NewValue_PredicateRefFunc;

    // stop after Replace/ReplaceIF batch
    protected

    procedure Test_IsSorted;
    procedure Test_IsSorted_CompareFunc;
    procedure Test_IsSorted_CompareMethod;
    procedure Test_IsSorted_CompareRefFunc;

    // publish IsSorted/Shuffle batch
    published

    // publish BinarySearch/BinarySearchInsert batch
    published

    procedure Test_BinarySearch_Element;
    procedure Test_BinarySearchInsert_Element;

    procedure Test_BinarySearch_Element_CompareFunc;
    procedure Test_BinarySearch_Element_CompareMethod;
    procedure Test_BinarySearch_Element_CompareRefFunc;
    procedure Test_BinarySearchInsert_Element_CompareFunc;
    procedure Test_BinarySearchInsert_Element_CompareMethod;
    procedure Test_BinarySearchInsert_Element_CompareRefFunc;

    // stop after BinarySearch/BinarySearchInsert batch
    protected

    procedure Test_Shuffle;
    procedure Test_Shuffle_RandomGeneratorFunc;
    procedure Test_Shuffle_RandomGeneratorMethod;
    procedure Test_Shuffle_RandomGeneratorRefFunc;
    procedure Test_Shuffle_StartIndex;
    procedure Test_Shuffle_StartIndex_RandomGeneratorFunc;
    procedure Test_Shuffle_StartIndex_RandomGeneratorMethod;
    procedure Test_Shuffle_StartIndex_RandomGeneratorRefFunc;
    procedure Test_Shuffle_StartIndex_Count;
    procedure Test_Shuffle_StartIndex_Count_RandomGeneratorFunc;
    procedure Test_Shuffle_StartIndex_Count_RandomGeneratorMethod;
    procedure Test_Shuffle_StartIndex_Count_RandomGeneratorRefFunc;

    // stop after IsSorted/Shuffle batch
    procedure Test_ShuffleUnChecked_StartIndex_Count;
    procedure Test_ShuffleUnChecked_StartIndex_Count_RandomGeneratorFunc;

    published

    procedure Test_Sort;
    procedure Test_Sort_CompareFunc;
    procedure Test_Sort_CompareMethod;
    procedure Test_Sort_CompareRefFunc;
    procedure Test_Sort_StartIndex;
    procedure Test_Sort_StartIndex_CompareFunc;
    procedure Test_Sort_StartIndex_CompareMethod;
    procedure Test_Sort_StartIndex_CompareRefFunc;
    procedure Test_Sort_StartIndex_Count;
    procedure Test_Sort_StartIndex_Count_CompareFunc;
    procedure Test_Sort_StartIndex_Count_CompareMethod;
    procedure Test_Sort_StartIndex_Count_CompareRefFunc;
    procedure Test_SortUnChecked_StartIndex_Count;
    procedure Test_SortUnChecked_StartIndex_Count_CompareFunc;
    procedure Test_SortUnChecked_StartIndex_Count_CompareMethod;
    procedure Test_SortUnChecked_StartIndex_Count_CompareRefFunc;
    procedure Test_SortWith_Algorithm;

    // stop after Sort batch
    protected

    procedure Test_ShuffleUnChecked_StartIndex_Count_RandomGeneratorMethod;
    procedure Test_ShuffleUnChecked_StartIndex_Count_RandomGeneratorRefFunc;
    procedure Test_SortWith_Algorithm_CompareFunc;
    procedure Test_SortWith_Algorithm_CompareRefFunc;

    { ===== 高级操作方法测试 (20个) ===== }
    procedure Test_Write_Index_Pointer_Count;
    procedure Test_Write_Index_Array;
    procedure Test_Write_Index_Collection;
    procedure Test_Write_Index_Collection_StartIndex;
    procedure Test_WriteExact_Index_Pointer_Count;
    procedure Test_WriteExact_Index_Array;
    procedure Test_WriteExact_Index_Collection;
    procedure Test_WriteExact_Index_Collection_StartIndex;
    // Negative paths and boundary inserts
    procedure Test_WriteExact_OutOfRange_Raises;
    procedure Test_Insert_Collection_Nil_Raises;
    procedure Test_Write_Pointer_Nil_Raises;
    procedure Test_Insert_AtHead_Tail_Wraparound;
    procedure Test_Delete_Index;
    procedure Test_Delete_Index_Count;
    procedure Test_DeleteSwap_Index;
    procedure Test_DeleteSwap_Index_Count;
    procedure Test_RemoveCopy_Index_Pointer_Count;
    procedure Test_RemoveCopy_Index_Pointer;
    procedure Test_RemoveArray_Index_Array_Count;
    procedure Test_Remove_Index_Element;
    procedure Test_RemoveCopySwap_Index_Pointer_Count;
    procedure Test_RemoveCopySwap_Index_Pointer;
    procedure Test_RemoveArraySwap_Index_Array_Count;
    procedure Test_RemoveSwap_Index_Element;

    { ===== IVecDeque 特有方法测试 (23个) ===== }
    procedure Test_IsEmpty;
    procedure Test_IsFull;
    procedure Test_GetAllocator;
    procedure Test_GetData;
    procedure Test_SetData;
    procedure Test_Clone;
    procedure Test_IsCompatible;
    procedure Test_GetEnumerator;
    procedure Test_Iter;
    procedure Test_GetElementSize;
    procedure Test_GetIsManagedType;
    procedure Test_GetElementManager;
    procedure Test_GetElementTypeInfo;
    procedure Test_LoadFrom_Array;
    procedure Test_LoadFrom_Collection;
    procedure Test_LoadFrom_Pointer;
    procedure Test_LoadFromUnChecked;
    procedure Test_Append_Array;
    procedure Test_Append_Collection;
    procedure Test_Append_Pointer;
    procedure Test_AppendTo;
    procedure Test_SaveTo;
    procedure Test_ToArray;
    { ===== Fuzz/Wraparound 附加测试 ===== }
    procedure Test_Fuzz_RandomSequence_FixedSeed;
    procedure Test_Wraparound_Heavy;

    procedure Test_OverWriteUnChecked_Collection_Limit;
    procedure Test_OverWriteUnChecked_Collection_Limit_Wraparound;
    procedure Test_Insert_Index_Collection_StartIndex_Wraparound;
    procedure Test_Insert_Index_Collection_StartIndex_Heavy;

    procedure Test_Write_Index_Collection_StartIndex_HeadTailBoundaries;
    procedure Test_Write_Index_Collection_StartIndex_CapacityGrowthEdge;
    // 新增：wrap 场景下的指针/数组插入与写入
    procedure Test_Insert_Index_Array_Wraparound;
    procedure Test_Insert_Index_Pointer_Count_Wraparound;
    procedure Test_Write_Index_Array_Wraparound;
    procedure Test_Write_Index_Pointer_Count_Wraparound;

  end;



implementation

function GEqualsInt(const L, R: Integer; Data: Pointer): Boolean; inline;
begin
  Result := L = R;
end;

function GIsOdd(const V: Integer; Data: Pointer): Boolean; inline;
begin
  Result := (V and 1) = 1;
end;

function TTestCase_VecDeque.EqualsIntMethod(const aLeft, aRight: Integer; aData: Pointer): Boolean; inline;
begin
  if aData <> nil then
    Result := (aLeft = aRight) and (PtrUInt(aData) <> 0)
  else
    Result := aLeft = aRight;
end;

function TTestCase_VecDeque.PredicateEvenMethod(const aValue: Integer; aData: Pointer): Boolean;
begin
  if aData <> nil then
    Result := (aValue mod 2) = 0
  else
    Result := (aValue mod 2) = 0;

end;
procedure TTestCase_VecDeque.ExpectSeq(const Expected: array of Integer);
var
  i: Integer;
begin
  AssertEquals('Count mismatch', SizeInt(Length(Expected)), SizeInt(FVecDeque.GetCount));
  for i := 0 to High(Expected) do
    AssertEquals('Mismatch at index '+IntToStr(i), Expected[i], FVecDeque.Get(i));
end;


{ TTestCase_VecDeque }

procedure TTestCase_VecDeque.SetUp;
begin
  FVecDeque := specialize TVecDeque<Integer>.Create;
end;

procedure TTestCase_VecDeque.TearDown;
begin
  FVecDeque.Free;
end;

{ ===== 构造函数测试 ===== }

procedure TTestCase_VecDeque.Test_Create;
begin
  AssertTrue('Create should create valid VecDeque', FVecDeque <> nil);
  AssertTrue('New VecDeque should be empty', FVecDeque.IsEmpty);
  AssertEquals('New VecDeque count should be 0', 0, FVecDeque.GetCount);
  AssertTrue('New VecDeque capacity should be > 0', FVecDeque.GetCapacity > 0);
end;

procedure TTestCase_VecDeque.Test_Create_Allocator_Data;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LAllocator: IAllocator;
  LData: Pointer;
begin
  LAllocator := TRtlAllocator.Create;
  try
    LData := Pointer($12345678);
    LVecDeque := specialize TVecDeque<Integer>.Create(LAllocator, LData);
    try
      AssertTrue('Create with allocator and data should work', LVecDeque <> nil);
      AssertTrue('VecDeque should use provided allocator', LVecDeque.GetAllocator = LAllocator);
      AssertTrue('VecDeque should store provided data', LVecDeque.GetData = LData);
      AssertTrue('VecDeque should be empty', LVecDeque.IsEmpty);
    finally
      LVecDeque.Free;
    end;
  finally
    LAllocator.Free;
  end;
end;

{ ===== IDeque 接口方法测试 ===== }

procedure TTestCase_VecDeque.Test_PushFront_Element;
begin
  FVecDeque.PushFront(42);
  AssertEquals('Count should be 1 after PushFront', 1, FVecDeque.GetCount);
  AssertEquals('Front element should be 42', 42, FVecDeque.Front);
  AssertEquals('Back element should be 42', 42, FVecDeque.Back);

  FVecDeque.PushFront(10);
  AssertEquals('Count should be 2 after second PushFront', 2, FVecDeque.GetCount);
  AssertEquals('Front element should be 10', 10, FVecDeque.Front);
  AssertEquals('Back element should be 42', 42, FVecDeque.Back);
end;

procedure TTestCase_VecDeque.Test_PushBack_Element;
begin
  FVecDeque.PushBack(42);
  AssertEquals('Count should be 1 after PushBack', 1, FVecDeque.GetCount);
  AssertEquals('Front element should be 42', 42, FVecDeque.Front);
  AssertEquals('Back element should be 42', 42, FVecDeque.Back);

  FVecDeque.PushBack(10);
  AssertEquals('Count should be 2 after second PushBack', 2, FVecDeque.GetCount);
  AssertEquals('Front element should be 42', 42, FVecDeque.Front);
  AssertEquals('Back element should be 10', 10, FVecDeque.Back);
end;

procedure TTestCase_VecDeque.Test_PopFront;
var
  LValue: Integer;
begin
  FVecDeque.PushBack(1);
  FVecDeque.PushBack(2);
  FVecDeque.PushBack(3);

  LValue := FVecDeque.PopFront;
  AssertEquals('PopFront should return first element', 1, LValue);
  AssertEquals('Count should decrease after PopFront', 2, FVecDeque.GetCount);
  AssertEquals('New front should be 2', 2, FVecDeque.Front);
end;

procedure TTestCase_VecDeque.Test_PopBack;
var
  LValue: Integer;
begin
  FVecDeque.PushBack(1);
  FVecDeque.PushBack(2);
  FVecDeque.PushBack(3);

  LValue := FVecDeque.PopBack;
  AssertEquals('PopBack should return last element', 3, LValue);
  AssertEquals('Count should decrease after PopBack', 2, FVecDeque.GetCount);
  AssertEquals('New back should be 2', 2, FVecDeque.Back);
end;

{ ===== IVecDeque 特有方法测试 ===== }

procedure TTestCase_VecDeque.Test_IsEmpty;
begin
  AssertTrue('New VecDeque should be empty', FVecDeque.IsEmpty);

  FVecDeque.PushBack(42);
  AssertFalse('VecDeque with element should not be empty', FVecDeque.IsEmpty);

  FVecDeque.PopBack;
  AssertTrue('VecDeque should be empty after removing all elements', FVecDeque.IsEmpty);
end;

procedure TTestCase_VecDeque.Test_GetCount;
begin
  AssertEquals('Empty VecDeque count should be 0', 0, FVecDeque.GetCount);

  FVecDeque.PushBack(1);
  AssertEquals('Count should be 1 after adding element', 1, FVecDeque.GetCount);

  FVecDeque.PushBack(2);
  FVecDeque.PushBack(3);
  AssertEquals('Count should be 3 after adding 3 elements', 3, FVecDeque.GetCount);

  FVecDeque.PopFront;
  AssertEquals('Count should be 2 after removing element', 2, FVecDeque.GetCount);
end;

procedure TTestCase_VecDeque.Test_GetCapacity;
var
  LInitialCapacity: SizeUInt;
begin
  LInitialCapacity := FVecDeque.GetCapacity;
  AssertTrue('Initial capacity should be > 0', LInitialCapacity > 0);

  // 添加元素直到触发扩容
  while FVecDeque.GetCount < LInitialCapacity do
    FVecDeque.PushBack(42);

  FVecDeque.PushBack(42); // 触发扩容
  AssertTrue('Capacity should increase after auto-grow', FVecDeque.GetCapacity > LInitialCapacity);
end;

procedure TTestCase_VecDeque.Test_Clear;
var
  S: specialize TVecDeque<String>;
begin
  // 基本整数容器
  FVecDeque.PushBack(1);
  FVecDeque.PushBack(2);
  FVecDeque.PushBack(3);
  AssertEquals('Count should be 3 before clear', 3, FVecDeque.GetCount);

  // 另起一个字符串容器，验证托管类型清理路径不会异常
  S := specialize TVecDeque<String>.Create;
  try
    S.Append(['a','b','c','d']);
    AssertEquals(4, S.GetCount);
    S.Clear; // 不应抛异常，也不应泄露；此处无法直接断言内存，但至少可重复使用
    AssertEquals(0, S.GetCount);
    S.Append(['x','y']);
    AssertEquals(2, S.GetCount);
  finally
    S.Free;
  end;

  FVecDeque.Clear;
  AssertEquals('Count should be 0 after clear', 0, FVecDeque.GetCount);
  AssertTrue('VecDeque should be empty after clear', FVecDeque.IsEmpty);
end;

{ ===== 所有其他方法的占位符实现 ===== }
{ 注意：这里为所有 270+ 个测试方法提供占位符实现 }

{ 构造函数测试占位符 (13个) }
procedure TTestCase_VecDeque.Test_Create_Allocator_GrowStrategy; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Create_Allocator_GrowStrategy_Data; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Create_Capacity; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Create_Capacity_Allocator; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Create_Capacity_Allocator_GrowStrategy; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Create_Capacity_Allocator_GrowStrategy_Data; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Create_Collection_Allocator_GrowStrategy; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Create_Collection_Allocator_GrowStrategy_Data; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Create_Pointer_Count_Allocator_GrowStrategy; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Create_Pointer_Count_Allocator_GrowStrategy_Data; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Create_Array_Allocator_GrowStrategy; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Create_Array_Allocator_GrowStrategy_Data; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Destroy; begin { TODO: 实现 } end;

{ ICollection 接口方法测试占位符 (5个) }
procedure TTestCase_VecDeque.Test_PtrIter; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_SerializeToArrayBuffer; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_AppendUnChecked; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_AppendToUnChecked; begin { TODO: 实现 } end;

{ IGenericCollection 接口方法测试占位符 (1个) }
procedure TTestCase_VecDeque.Test_SaveToUnChecked; begin { TODO: 实现 } end;

{ IArray 接口方法测试占位符 (34个) }
procedure TTestCase_VecDeque.Test_GetMemory; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Get; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_GetUnChecked; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Put; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_PutUnChecked; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_GetPtr; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_GetPtrUnChecked; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Resize; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Resize_Value; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Ensure; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_OverWrite_Pointer; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_OverWriteUnChecked_Pointer; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_OverWrite_Array; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_OverWriteUnChecked_Array; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_OverWrite_Collection; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_OverWriteUnChecked_Collection; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Read_Pointer; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ReadUnChecked_Pointer; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Read_Collection; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ReadUnChecked_Collection; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Swap_TwoElements; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_SwapUnChecked_TwoElements; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Swap_Range; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Swap_Stride; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Copy; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_CopyUnChecked; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Fill_Single; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Fill_Range; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_FillUnChecked; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Zero_Single; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Zero_Range; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ZeroUnChecked; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Reverse_Single; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Reverse_Range; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ReverseUnChecked; begin { TODO: 实现 } end;

{ ForEach 系列方法测试占位符 (15个) }
procedure TTestCase_VecDeque.Test_ForEach_PredicateFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ForEach_PredicateMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ForEach_PredicateRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ForEach_Index_PredicateFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ForEach_Index_PredicateMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ForEach_Index_PredicateRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ForEach_Index_Count_PredicateFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ForEach_Index_Count_PredicateMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ForEach_Index_Count_PredicateRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ForEachUnChecked_PredicateFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ForEachUnChecked_PredicateMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ForEachUnChecked_PredicateRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ForEachUnChecked_Index_Count_PredicateFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ForEachUnChecked_Index_Count_PredicateMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ForEachUnChecked_Index_Count_PredicateRefFunc; begin { TODO: 实现 } end;

{ Contains 系列方法测试占位符 (16个) }
procedure TTestCase_VecDeque.Test_Contains_Element; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Contains_Element_EqualsFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Contains_Element_EqualsMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Contains_Element_EqualsRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Contains_Element_Index; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Contains_Element_Index_EqualsFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Contains_Element_Index_EqualsMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Contains_Element_Index_EqualsRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Contains_Element_Index_Count; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Contains_Element_Index_Count_EqualsFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Contains_Element_Index_Count_EqualsMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Contains_Element_Index_Count_EqualsRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ContainsUnChecked_Element; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ContainsUnChecked_Element_EqualsFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ContainsUnChecked_Element_EqualsMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ContainsUnChecked_Element_EqualsRefFunc; begin { TODO: 实现 } end;

{ Find 系列方法测试占位符 (25个) }
procedure TTestCase_VecDeque.Test_Find_Element; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Find_Element_EqualsFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Find_Element_EqualsMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Find_Element_EqualsRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Find_Element_Index; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Find_Element_Index_EqualsFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Find_Element_Index_EqualsMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Find_Element_Index_EqualsRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Find_Element_Index_Count; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Find_Element_Index_Count_EqualsFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Find_Element_Index_Count_EqualsMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Find_Element_Index_Count_EqualsRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_FindUnChecked_Element; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_FindUnChecked_Element_EqualsFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_FindUnChecked_Element_EqualsMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_FindUnChecked_Element_EqualsRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_FindIF_PredicateFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_FindIF_PredicateMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_FindIF_PredicateRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_FindIFUnChecked_PredicateFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_FindIFUnChecked_PredicateMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_FindIFUnChecked_PredicateRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_FindIFNotUnChecked_PredicateFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_FindIFNotUnChecked_PredicateMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_FindIFNotUnChecked_PredicateRefFunc; begin { TODO: 实现 } end;

{ ===== 所有其他测试方法的批量占位符实现 ===== }
{ 注意：为了简洁，这里为所有剩余的 200+ 个测试方法提供统一的占位符实现 }

{ IVec 接口方法测试占位符 (24个) }
procedure TTestCase_VecDeque.Test_SetCapacity; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_GetGrowStrategy; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_SetGrowStrategy; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_TryReserve;
var
  i: Integer;
  oldCap: SizeUInt;
  ok: Boolean;
begin
  FVecDeque.Clear;
  for i := 1 to 10 do FVecDeque.PushBack(i);
  oldCap := FVecDeque.GetCapacity;
  ok := FVecDeque.TryReserve(5);
  AssertTrue('TryReserve should succeed', ok);
  AssertTrue('Capacity >= Count+additional', FVecDeque.GetCapacity >= (FVecDeque.GetCount + 5));
  AssertEquals('Count unchanged after TryReserve', SizeUInt(10), SizeUInt(FVecDeque.GetCount));
  AssertTrue('Capacity should not shrink on TryReserve', FVecDeque.GetCapacity >= oldCap);
end;
procedure TTestCase_VecDeque.Test_TryReserveExact;
var
  oldCap, target: SizeUInt;
  ok: Boolean;
begin
  FVecDeque.Clear;
  // small count, check absolute capacity reservation
  FVecDeque.Resize(5);
  oldCap := FVecDeque.GetCapacity;
  target := oldCap + 7; // ensure target > current capacity
  ok := FVecDeque.TryReserveExact(target);
  AssertTrue('TryReserveExact should succeed', ok);
  AssertTrue('Capacity >= target (may align up)', FVecDeque.GetCapacity >= target);
  AssertEquals('Count unchanged after TryReserveExact', SizeUInt(5), SizeUInt(FVecDeque.GetCount));
end;
procedure TTestCase_VecDeque.Test_Reserve;
var
  i: Integer;
  oldCap: SizeUInt;
begin
  FVecDeque.Clear;
  for i := 1 to 12 do FVecDeque.PushBack(i);
  oldCap := FVecDeque.GetCapacity;
  FVecDeque.Reserve(6);
  AssertTrue('Capacity >= Count+additional', FVecDeque.GetCapacity >= (FVecDeque.GetCount + 6));
  AssertEquals('Count unchanged after Reserve', SizeUInt(12), SizeUInt(FVecDeque.GetCount));
  AssertTrue('Capacity should not shrink on Reserve', FVecDeque.GetCapacity >= oldCap);
end;
procedure TTestCase_VecDeque.Test_ReserveExact;
var
  oldCap, target: SizeUInt;
begin
  FVecDeque.Clear;
  FVecDeque.Resize(8);
  oldCap := FVecDeque.GetCapacity;
  target := oldCap + 9;
  FVecDeque.ReserveExact(target);
  AssertTrue('Capacity >= target (may align up)', FVecDeque.GetCapacity >= target);
  AssertEquals('Count unchanged after ReserveExact', SizeUInt(8), SizeUInt(FVecDeque.GetCount));
end;
procedure TTestCase_VecDeque.Test_ShrinkToFit;
var
  i: Integer;
  capBeforeGrow, capBeforeShrink, capAfter: SizeUInt;
begin
  FVecDeque.Clear;
  // Force grow
  for i := 1 to 80 do FVecDeque.PushBack(i);
  capBeforeGrow := FVecDeque.GetCapacity;
  // Reduce count significantly
  FVecDeque.Truncate(5);
  capBeforeShrink := FVecDeque.GetCapacity;
  FVecDeque.ShrinkToFit;
  capAfter := FVecDeque.GetCapacity;
  AssertTrue('ShrinkToFit should not increase capacity', capAfter <= capBeforeShrink);
  AssertTrue('Capacity >= Count after ShrinkToFit', capAfter >= FVecDeque.GetCount);
  AssertTrue('Capacity decreased from grown state', capAfter < capBeforeGrow);
end;
procedure TTestCase_VecDeque.Test_Shrink;
var
  i: Integer;
  capBeforeGrow, capAfter: SizeUInt;
begin
  FVecDeque.Clear;
  for i := 1 to 64 do FVecDeque.PushBack(i);
  capBeforeGrow := FVecDeque.GetCapacity;
  FVecDeque.Truncate(4);
  FVecDeque.Shrink;
  capAfter := FVecDeque.GetCapacity;
  AssertTrue('Shrink should not increase capacity', capAfter <= capBeforeGrow);
  AssertTrue('Capacity >= Count after Shrink', capAfter >= FVecDeque.GetCount);
end;
procedure TTestCase_VecDeque.Test_ShrinkTo;
var
  i: Integer;
  raised: Boolean;
  oldCap, capAfter: SizeUInt;
begin
  // 1) cap < count should raise EInvalidArgument
  FVecDeque.Clear;
  FVecDeque.Resize(10);
  raised := False;
  try
    FVecDeque.ShrinkTo(8);
  except
    on E: EInvalidArgument do raised := True;
  end;
  AssertTrue('ShrinkTo(cap<count) should raise EInvalidArgument', raised);

  // 2) shrink to specified capacity (>=count) should reduce or keep capacity
  FVecDeque.Clear;
  for i := 1 to 120 do FVecDeque.PushBack(i); // ensure big capacity
  oldCap := FVecDeque.GetCapacity;
  // reduce count and then shrink to 60 (rounded to pow2 internally)
  FVecDeque.Truncate(50);
  FVecDeque.ShrinkTo(60);
  capAfter := FVecDeque.GetCapacity;
  AssertTrue('Capacity >= Count after ShrinkTo', capAfter >= FVecDeque.GetCount);
  AssertTrue('ShrinkTo should not grow capacity', capAfter <= oldCap);
end;
procedure TTestCase_VecDeque.Test_Truncate;
var
  i: Integer;
begin
  FVecDeque.Clear;
  for i := 1 to 6 do FVecDeque.PushBack(i);
  FVecDeque.Truncate(4);
  AssertEquals(SizeInt(4), SizeInt(FVecDeque.GetCount));
  AssertEquals(1, FVecDeque.Get(0));
  AssertEquals(4, FVecDeque.Get(3));
end;
procedure TTestCase_VecDeque.Test_ResizeExact;
var
  i: Integer;
begin
  FVecDeque.Clear;
  // Grow exact: fill defaults
  FVecDeque.ResizeExact(3);
  AssertEquals(SizeInt(3), SizeInt(FVecDeque.GetCount));
  // Write some values
  for i := 0 to 2 do FVecDeque.PutUnChecked(i, 10 + i);
  // Shrink exact: drop tail
  FVecDeque.ResizeExact(2);
  AssertEquals(SizeInt(2), SizeInt(FVecDeque.GetCount));
  AssertEquals(10, FVecDeque.Get(0));
  AssertEquals(11, FVecDeque.Get(1));
end;
procedure TTestCase_VecDeque.Test_Insert_Index_Element;
var
  i: Integer;
begin
  FVecDeque.Clear;
  for i := 1 to 4 do FVecDeque.PushBack(i); // [1,2,3,4]
  FVecDeque.Insert(2, 99);                   // -> [1,2,99,3,4]
  AssertEquals('Count=5', SizeInt(5), SizeInt(FVecDeque.GetCount));
  AssertEquals('Index 2', 99, FVecDeque.Get(2));
  AssertEquals('Tail element', 4, FVecDeque.Get(4));
end;
procedure TTestCase_VecDeque.Test_Insert_Index_Array;
var
  i: Integer;
  A: array[0..2] of Integer = (7,8,9);
begin
  FVecDeque.Clear;
  for i := 0 to 3 do FVecDeque.PushBack(i); // [0,1,2,3]
  FVecDeque.Insert(1, A);                   // -> [0,7,8,9,1,2,3]
  AssertEquals('Count=7', SizeInt(7), SizeInt(FVecDeque.GetCount));
  AssertEquals('Index 1', 7, FVecDeque.Get(1));
  AssertEquals('Index 3', 9, FVecDeque.Get(3));
  AssertEquals('Index 6', 3, FVecDeque.Get(6));
end;
procedure TTestCase_VecDeque.Test_Insert_Index_Pointer_Count;
var
  i: Integer;
  Buf: array[0..1] of Integer;
begin
  FVecDeque.Clear;
  for i := 1 to 3 do FVecDeque.PushBack(i); // [1,2,3]
  Buf[0]:=100; Buf[1]:=101;
  FVecDeque.Insert(0, @Buf[0], 2);          // -> [100,101,1,2,3]
  AssertEquals('Count=5', SizeInt(5), SizeInt(FVecDeque.GetCount));
  AssertEquals('Index 0', 100, FVecDeque.Get(0));
  AssertEquals('Index 1', 101, FVecDeque.Get(1));
  AssertEquals('Index 4', 3, FVecDeque.Get(4));
end;
procedure TTestCase_VecDeque.Test_Insert_Index_Collection_StartIndex;
var
  C: specialize TVecDeque<Integer>;
begin
  FVecDeque.Clear;
  FVecDeque.PushBack(1);
  FVecDeque.PushBack(2);
  FVecDeque.PushBack(3);              // [1,2,3]
  C := specialize TVecDeque<Integer>.Create;
  try
    C.PushBack(10);
    C.PushBack(20);
    C.PushBack(30);
    // Insert elements starting from StartIndex=1 -> [20,30] at index 2
    FVecDeque.Insert(2, C, 1);        // -> [1,2,20,30,3]
    AssertEquals('Count=5', SizeInt(5), SizeInt(FVecDeque.GetCount));
    AssertEquals('Index 2', 20, FVecDeque.Get(2));
    AssertEquals('Index 3', 30, FVecDeque.Get(3));
  finally
    C.Free;
  end;
end;
procedure TTestCase_VecDeque.Test_Remove_Index;
var
  i, Removed: Integer;
begin
  FVecDeque.Clear;
  for i := 1 to 5 do FVecDeque.PushBack(i); // [1..5]
  Removed := FVecDeque.Remove(1);           // remove 2 -> [1,3,4,5]
  AssertEquals('Removed value=2', 2, Removed);
  AssertEquals('Count=4', SizeInt(4), SizeInt(FVecDeque.GetCount));
  AssertEquals('Index 1 now 3', 3, FVecDeque.Get(1));
end;
procedure TTestCase_VecDeque.Test_Remove_Index_Count;
var
  i: Integer;
begin
  FVecDeque.Clear;
  for i := 0 to 6 do FVecDeque.PushBack(i); // [0..6]
  FVecDeque.Delete(2, 3);                    // delete [2,3,4] -> [0,1,5,6]
  AssertEquals('Count=4', SizeInt(4), SizeInt(FVecDeque.GetCount));
  AssertEquals('Index 2 now 5', 5, FVecDeque.Get(2));
end;
procedure TTestCase_VecDeque.Test_RemoveSwap_Index;
var
  i, Removed: Integer;
begin
  FVecDeque.Clear;
  for i := 1 to 5 do FVecDeque.PushBack(i); // [1..5]
  Removed := FVecDeque.RemoveSwap(1);       // remove index 1 (value 2), swap with last -> [1,5,3,4]
  AssertEquals('Removed=2', 2, Removed);
  AssertEquals('Count=4', SizeInt(4), SizeInt(FVecDeque.GetCount));
  AssertEquals('Index 1 now 5', 5, FVecDeque.Get(1));
end;
procedure TTestCase_VecDeque.Test_RemoveSwap_Index_Count;
var
  i: Integer;
  E: Integer;
begin
  FVecDeque.Clear;
  for i := 1 to 6 do FVecDeque.PushBack(i); // [1..6]
  FVecDeque.RemoveSwap(2, E);               // remove at idx 2 (3), swap with last -> [1,2,6,4,5]
  AssertEquals('Removed element=3', 3, E);
  AssertEquals('Count=5', SizeInt(5), SizeInt(FVecDeque.GetCount));
end;
procedure TTestCase_VecDeque.Test_Add_Element; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Add_Array; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Add_Pointer_Count; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Add_Collection; begin { TODO: 实现 } end;

{ ===== 所有其他测试方法的批量占位符实现 (200+ 个) ===== }
{ 为了保持文件简洁，这里为所有剩余的测试方法提供统一的占位符实现 }
{ 包括：IQueue、IDeque、算法、排序、高级操作等所有接口方法 }

{ 批量占位符实现 - 按需实现具体测试 }
procedure TTestCase_VecDeque.Test_Enqueue_Element; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Enqueue_Array; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Enqueue_Pointer_Count; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Enqueue_Collection; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Push_Element; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Push_Array; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Push_Pointer_Count; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Push_Collection; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Push_Collection_StartIndex; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Dequeue; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Pop; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Peek; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Dequeue_Safe; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Pop_Safe; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Peek_Safe;
var
  ok: Boolean; v: Integer;
begin
  FVecDeque.Clear;
  ok := FVecDeque.Peek(v); AssertFalse(ok);
  FVecDeque.Append([7,8]);
  ok := FVecDeque.Peek(v); AssertTrue(ok); AssertEquals(7, v);
  AssertEquals(2, FVecDeque.GetCount);
end;
procedure TTestCase_VecDeque.Test_Front;
var
  v: Integer;
begin
  FVecDeque.Clear;
  try
    v := FVecDeque.Front;
    Fail('Expected exception not raised');
  except
    on E: Exception do ;
  end;
  FVecDeque.Append([1,2]);
  v := FVecDeque.Front;
  AssertEquals(1, v);
end;
procedure TTestCase_VecDeque.Test_Front_Safe;
var
  ok: Boolean; v: Integer;
begin
  FVecDeque.Clear;
  ok := FVecDeque.Front(v); AssertFalse(ok);
  FVecDeque.Append([1,2]);
  ok := FVecDeque.Front(v); AssertTrue(ok); AssertEquals(1, v);
end;
procedure TTestCase_VecDeque.Test_Back;
var
  v: Integer;
begin
  FVecDeque.Clear;
  try
    v := FVecDeque.Back;
    Fail('Expected exception not raised');
  except
    on E: Exception do ;
  end;
  FVecDeque.Append([1,2]);
  v := FVecDeque.Back;
  AssertEquals(2, v);
end;
procedure TTestCase_VecDeque.Test_Back_Safe;
var
  ok: Boolean; v: Integer;
begin
  FVecDeque.Clear;
  ok := FVecDeque.Back(v); AssertFalse(ok);
  FVecDeque.Append([1,2]);
  ok := FVecDeque.Back(v); AssertTrue(ok); AssertEquals(2, v);
end;
procedure TTestCase_VecDeque.Test_TryGet;
var
  ok: Boolean; v: Integer;
begin
  FVecDeque.Clear;
  ok := FVecDeque.TryGet(0, v); AssertFalse(ok);
  FVecDeque.Append([10,11,12]);
  ok := FVecDeque.TryGet(0, v); AssertTrue(ok); AssertEquals(10, v);
  ok := FVecDeque.TryGet(2, v); AssertTrue(ok); AssertEquals(12, v);
  ok := FVecDeque.TryGet(3, v); AssertFalse(ok);
end;
procedure TTestCase_VecDeque.Test_TryRemove;
var
  ok: Boolean; v: Integer;
begin
  FVecDeque.Clear;
  ok := FVecDeque.TryRemove(0, v); AssertFalse(ok);
  FVecDeque.Append([10,11,12]);
  ok := FVecDeque.TryRemove(1, v); AssertTrue(ok); AssertEquals(11, v); ExpectSeq([10,12]);
  ok := FVecDeque.TryRemove(5, v); AssertFalse(ok);
end;
procedure TTestCase_VecDeque.Test_TryPop_Element; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_TryPop_Pointer_Count;
var
  ok: Boolean;
  Buf: array[0..2] of Integer;
  i: Integer;
begin
  FVecDeque.Clear;
  // 空 -> False，不抛异常
  ok := FVecDeque.TryPop(@Buf[0], 3);
  AssertFalse(ok);
  // 填充 [1..5]，从尾部弹出3个 -> 5,4,3（按后端顺序，写入到 Buf[0..2] 为 3,4,5）
  for i := 1 to 5 do FVecDeque.PushBack(i);
  ok := FVecDeque.TryPop(@Buf[0], 3);
  AssertTrue(ok);
  AssertEquals(2, FVecDeque.GetCount);
  AssertEquals(3, Buf[0]); AssertEquals(4, Buf[1]); AssertEquals(5, Buf[2]);
end;
procedure TTestCase_VecDeque.Test_TryPop_Array_Count;
var
  ok: Boolean;
  A: specialize TGenericArray<Integer>;
  i: Integer;
begin
  FVecDeque.Clear;
  SetLength(A, 3);
  ok := FVecDeque.TryPop(A, 3);
  AssertFalse(ok);
  for i := 1 to 5 do FVecDeque.PushBack(i);
  ok := FVecDeque.TryPop(A, 3);
  AssertTrue(ok);
  AssertEquals(2, FVecDeque.GetCount);
  AssertEquals(3, A[0]); AssertEquals(4, A[1]); AssertEquals(5, A[2]);
end;
procedure TTestCase_VecDeque.Test_TryPeek_Element;
var
  ok: Boolean;
  v: Integer;
begin
  FVecDeque.Clear;
  ok := FVecDeque.TryPeek(v);
  AssertFalse(ok);
  FVecDeque.PushBack(42);
  ok := FVecDeque.TryPeek(v);
  AssertTrue(ok);
  AssertEquals(1, FVecDeque.GetCount);
  AssertEquals(42, v);
end;
procedure TTestCase_VecDeque.Test_TryPeek_Pointer_Count;
var
  ok: Boolean;
  Buf: array[0..2] of Integer;
  i: Integer;
begin
  FVecDeque.Clear;
  // 没有 TryPeek(ptr)；以 TryPeekCopy 验证指针复制
  ok := FVecDeque.TryPeekCopy(@Buf[0], 3);
  AssertFalse(ok);
  for i := 1 to 5 do FVecDeque.PushBack(i);
  ok := FVecDeque.TryPeekCopy(@Buf[0], 3);
  AssertTrue(ok);
  // 期望复制尾部 3 个：3,4,5
  AssertEquals(3, Buf[0]); AssertEquals(4, Buf[1]); AssertEquals(5, Buf[2]);
  // Count 不变
  AssertEquals(5, FVecDeque.GetCount);
end;
procedure TTestCase_VecDeque.Test_TryPeek_Array_Count;
var
  ok: Boolean;
  A: specialize TGenericArray<Integer>;
  i: Integer;
begin
  FVecDeque.Clear;
  SetLength(A, 3);
  ok := FVecDeque.TryPeek(A, 3);
  AssertFalse(ok);
  for i := 1 to 5 do FVecDeque.PushBack(i);
  ok := FVecDeque.TryPeek(A, 3);
  AssertTrue(ok);
  AssertEquals(5, FVecDeque.GetCount);
  AssertEquals(3, A[0]); AssertEquals(4, A[1]); AssertEquals(5, A[2]);
end;
procedure TTestCase_VecDeque.Test_TryPeekCopy_Pointer_Count;
var
  ok: Boolean;
  Buf: array[0..1] of Integer;
  i: Integer;
begin
  FVecDeque.Clear;
  ok := FVecDeque.TryPeekCopy(@Buf[0], 2);
  AssertFalse(ok);
  for i := 10 to 14 do FVecDeque.PushBack(i); // [10..14]
  ok := FVecDeque.TryPeekCopy(@Buf[0], 2);
  AssertTrue(ok);
  AssertEquals(13, Buf[0]); AssertEquals(14, Buf[1]);
  AssertEquals(5, FVecDeque.GetCount);
end;
procedure TTestCase_VecDeque.Test_PeekRange;
var
  p: ^Integer;
  i: Integer;
begin
  // 连续布局：直接 PushBack
  FVecDeque.Clear;
  for i := 1 to 4 do FVecDeque.PushBack(i); // [1,2,3,4]
  p := FVecDeque.PeekRange(3);
  AssertTrue('PeekRange should return non-nil for contiguous tail', p <> nil);
  AssertEquals(2, p^);

  // 跨环布局：通过在 front/back 混合操作造成 wrap
  FVecDeque.Clear;
  for i := 1 to 3 do FVecDeque.PushBack(i); // [1,2,3]
  FVecDeque.PushFront(10);                  // [10,1,2,3] => 逻辑跨环（实现依赖容量）
  p := FVecDeque.PeekRange(3);
  // 新的 PeekRange 应在非连续时返回 nil
  AssertTrue('PeekRange should return nil when non-contiguous', p = nil);
end;

procedure TTestCase_VecDeque.Test_Append_Queue;
var
  Q: specialize TVecDeque<Integer>;
begin
  FVecDeque.Clear;
  Q := specialize TVecDeque<Integer>.Create;
  try
    Q.Append([7,8,9]);
    FVecDeque.Append(Q as specialize IQueue<Integer>);
    AssertEquals(3, FVecDeque.GetCount);
    AssertEquals(7, FVecDeque.Get(0));
    AssertEquals(9, FVecDeque.Get(2));
  finally
    Q.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_SplitOff;
var
  Q: specialize IQueue<Integer>;
  i: Integer;
begin
  FVecDeque.Clear;
  for i := 0 to 5 do FVecDeque.PushBack(i); // [0..5]
  Q := FVecDeque.SplitOff(3);
  // 原队列应剩下 [0,1,2]
  AssertEquals(3, FVecDeque.GetCount);
  AssertEquals(0, FVecDeque.Get(0));
  AssertEquals(2, FVecDeque.Get(2));
  // 新队列应为 [3,4,5]
  AssertTrue(Q <> nil);
  AssertEquals(3, Q.GetCount);
  // 逐个 Dequeue 验证
  AssertEquals(3, Q.Dequeue);
  AssertEquals(4, Q.Dequeue);
  AssertEquals(5, Q.Dequeue);
end;
procedure TTestCase_VecDeque.Test_FillWith; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ClearAndReserve; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_SwapRange; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_WarmupMemory; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_PushFront_Array; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_PushFront_Pointer_Count; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_PushFront_Collection; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_PushBack_Array; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_PushBack_Pointer_Count; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_PushBack_Collection; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_PopFront_Safe;
var
  ok: Boolean;
  v: Integer;
begin
  FVecDeque.Clear;
  ok := FVecDeque.PopFront(v);
  AssertFalse(ok);
  FVecDeque.PushBack(1); FVecDeque.PushBack(2);
  ok := FVecDeque.PopFront(v);
  AssertTrue(ok);
  AssertEquals(1, v);
  AssertEquals(1, FVecDeque.GetCount);
end;
procedure TTestCase_VecDeque.Test_PopBack_Safe;
var
  ok: Boolean;
  v: Integer;
begin
  FVecDeque.Clear;
  ok := FVecDeque.PopBack(v);
  AssertFalse(ok);
  FVecDeque.PushBack(1); FVecDeque.PushBack(2);
  ok := FVecDeque.PopBack(v);
  AssertTrue(ok);
  AssertEquals(2, v);
  AssertEquals(1, FVecDeque.GetCount);
end;
procedure TTestCase_VecDeque.Test_PeekFront;
var
  v: Integer;
begin
  FVecDeque.Clear;
  // 空调用抛异常
  try
    Ignore(IntToStr(FVecDeque.PeekFront));
    Fail('Expected exception not raised');
  except
    on E: Exception do ;
  end;
  // 非空返回 front
  FVecDeque.Append([10,11]);
  v := FVecDeque.PeekFront;
  AssertEquals(10, v);
end;
procedure TTestCase_VecDeque.Test_PeekFront_Safe;
var
  ok: Boolean;
  v: Integer;
begin
  FVecDeque.Clear;
  ok := FVecDeque.PeekFront(v);
  AssertFalse(ok);
  FVecDeque.Append([10,11]);
  ok := FVecDeque.PeekFront(v);
  AssertTrue(ok);
  AssertEquals(10, v);
  AssertEquals(2, FVecDeque.GetCount);
end;
procedure TTestCase_VecDeque.Test_PeekBack;
var
  v: Integer;
begin
  FVecDeque.Clear;
  try
    Ignore(IntToStr(FVecDeque.PeekBack));
    Fail('Expected exception not raised');
  except
    on E: Exception do ;
  end;
  FVecDeque.Append([10,11]);
  v := FVecDeque.PeekBack;
  AssertEquals(11, v);
end;
procedure TTestCase_VecDeque.Test_PeekBack_Safe;
var
  ok: Boolean;
  v: Integer;
begin
  FVecDeque.Clear;
  ok := FVecDeque.PeekBack(v);
  AssertFalse(ok);
  FVecDeque.Append([10,11]);
  ok := FVecDeque.PeekBack(v);
  AssertTrue(ok);
  AssertEquals(11, v);
  AssertEquals(2, FVecDeque.GetCount);
end;
procedure TTestCase_VecDeque.Test_FastIndexOf; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_FastLastIndexOf; begin { TODO: 实现 } end;

{ 算法和排序方法测试占位符 (60个) }
procedure TTestCase_VecDeque.Test_CountOf_Element;
var
  i: Integer;
  C: SizeUInt;
begin
  // 准备数据
  for i := 1 to 6 do FVecDeque.PushBack(i mod 3); // 1,2,0,1,2,0

  // Act
  C := FVecDeque.CountOf(1);

  // Assert
  AssertEquals('CountOf(1) 应为2', SizeUInt(2), C);
end;
procedure TTestCase_VecDeque.Test_CountOf_Element_EqualsFunc;
var
  i: Integer;
  C: SizeUInt;
begin
  for i := 1 to 5 do FVecDeque.PushBack(i mod 2); // 1,0,1,0,1
  C := FVecDeque.CountOf(1, @GEqualsInt, nil);
  AssertEquals('使用函数指针 CountOf(1)=3', SizeUInt(3), C);
end;
procedure TTestCase_VecDeque.Test_CountOf_Element_EqualsMethod;
var
  i: Integer;
  C: SizeUInt;
begin
  for i := 1 to 6 do FVecDeque.PushBack(i mod 3); // 1,2,0,1,2,0
  C := FVecDeque.CountOf(2, @EqualsIntMethod, nil);
  AssertEquals('使用方法指针 CountOf(2)=2', SizeUInt(2), C);
end;
procedure TTestCase_VecDeque.Test_CountOf_Element_EqualsRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_CountIF_PredicateFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_CountIF_PredicateMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_CountIF_PredicateRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Replace_OldValue_NewValue;
begin
  // Arrange
  FVecDeque.PushBack(1);
  FVecDeque.PushBack(2);
  FVecDeque.PushBack(1);
  FVecDeque.PushBack(3);
  FVecDeque.PushBack(1);
  FVecDeque.PushBack(2);

  // Act
  FVecDeque.Replace(1, 99);

  // Assert
  AssertEquals('Count 保持不变', 6, FVecDeque.GetCount);
  AssertEquals('位置0 应为99', 99, FVecDeque.Get(0));
  AssertEquals('位置1 应为2', 2, FVecDeque.Get(1));
  AssertEquals('位置2 应为99', 99, FVecDeque.Get(2));
  AssertEquals('位置3 应为3', 3, FVecDeque.Get(3));
  AssertEquals('位置4 应为99', 99, FVecDeque.Get(4));
  AssertEquals('位置5 应为2', 2, FVecDeque.Get(5));
end;
procedure TTestCase_VecDeque.Test_Replace_OldValue_NewValue_EqualsFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Replace_OldValue_NewValue_EqualsMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Replace_OldValue_NewValue_EqualsRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ReplaceIf_NewValue_PredicateFunc;
var
  i: Integer;
begin
  for i := 1 to 6 do FVecDeque.PushBack(i); // 1..6
  FVecDeque.ReplaceIf(0, @GIsOdd, nil);
  AssertEquals('奇数应被替换为0', 0, FVecDeque.Get(0));
  AssertEquals('偶数保持', 2, FVecDeque.Get(1));
  AssertEquals('奇数应被替换为0', 0, FVecDeque.Get(2));
  AssertEquals('偶数保持', 4, FVecDeque.Get(3));
end;
procedure TTestCase_VecDeque.Test_ReplaceIf_NewValue_PredicateMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ReplaceIf_NewValue_PredicateRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_IsSorted; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_IsSorted_CompareFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_IsSorted_CompareMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_IsSorted_CompareRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_BinarySearch_Element; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_BinarySearch_Element_CompareFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_BinarySearch_Element_CompareMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_BinarySearch_Element_CompareRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_BinarySearchInsert_Element; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_BinarySearchInsert_Element_CompareFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_BinarySearchInsert_Element_CompareMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_BinarySearchInsert_Element_CompareRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Shuffle;
var
  i: Integer;
  Before: array[0..4] of Integer;
  Diff: Boolean;
begin
  for i := 0 to High(Before) do begin Before[i] := i+1; FVecDeque.PushBack(Before[i]); end;
  FVecDeque.Shuffle;
  AssertEquals('打乱后数量不变', SizeInt(Length(Before)), SizeInt(FVecDeque.GetCount));
  Diff := False;
  for i := 0 to High(Before) do
    if FVecDeque.Get(i) <> Before[i] then begin Diff := True; Break; end;
  // 小概率不变，允许 Diff 为 False 时重复一次以降低偶然性
  if not Diff then begin FVecDeque.Shuffle; for i := 0 to High(Before) do if FVecDeque.Get(i) <> Before[i] then begin Diff := True; Break; end; end;
  AssertTrue('元素位置应大概率变化', Diff);
end;
procedure TTestCase_VecDeque.Test_Shuffle_RandomGeneratorFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Shuffle_RandomGeneratorMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Shuffle_RandomGeneratorRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Shuffle_StartIndex; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Shuffle_StartIndex_RandomGeneratorFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Shuffle_StartIndex_RandomGeneratorMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Shuffle_StartIndex_RandomGeneratorRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Shuffle_StartIndex_Count; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Shuffle_StartIndex_Count_RandomGeneratorFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Shuffle_StartIndex_Count_RandomGeneratorMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Shuffle_StartIndex_Count_RandomGeneratorRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ShuffleUnChecked_StartIndex_Count; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ShuffleUnChecked_StartIndex_Count_RandomGeneratorFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ShuffleUnChecked_StartIndex_Count_RandomGeneratorMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ShuffleUnChecked_StartIndex_Count_RandomGeneratorRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Sort; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Sort_CompareFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Sort_CompareMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Sort_CompareRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Sort_StartIndex; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Sort_StartIndex_CompareFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Sort_StartIndex_CompareMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Sort_StartIndex_CompareRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Sort_StartIndex_Count; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Sort_StartIndex_Count_CompareFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Sort_StartIndex_Count_CompareMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Sort_StartIndex_Count_CompareRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_SortUnChecked_StartIndex_Count; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_SortUnChecked_StartIndex_Count_CompareFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_SortUnChecked_StartIndex_Count_CompareMethod; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_SortUnChecked_StartIndex_Count_CompareRefFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_SortWith_Algorithm; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_SortWith_Algorithm_CompareFunc; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_SortWith_Algorithm_CompareRefFunc; begin { TODO: 实现 } end;

{ 高级操作方法测试占位符 (20个) }
procedure TTestCase_VecDeque.Test_Write_Index_Pointer_Count;
var
  Buf: array[0..4] of Integer;
begin
  // Prepare existing data [1..10]
  FVecDeque.Clear;
  FVecDeque.Resize(10);
  // write through pointer starting at index 3 count 5
  Buf[0]:=100; Buf[1]:=101; Buf[2]:=102; Buf[3]:=103; Buf[4]:=104;
  FVecDeque.Write(3, @Buf[0], 5);
  // Count must have grown to at least 8; here 3+5=8 so still 10
  AssertEquals('Count should remain 10', SizeInt(10), SizeInt(FVecDeque.GetCount));
  AssertEquals('Index 3', 100, FVecDeque.Get(3));
  AssertEquals('Index 7', 104, FVecDeque.Get(7));
end;
procedure TTestCase_VecDeque.Test_Write_Index_Array;
var
  A: array[0..2] of Integer = (7,8,9);
begin
  FVecDeque.Clear;
  FVecDeque.Resize(5);
  FVecDeque.Write(4, A);
  AssertEquals('Count should grow to 7', SizeInt(7), SizeInt(FVecDeque.GetCount));
  AssertEquals('Index 4', 7, FVecDeque.Get(4));
  AssertEquals('Index 6', 9, FVecDeque.Get(6));
end;
procedure TTestCase_VecDeque.Test_Write_Index_Collection;
var
  C: specialize TVecDeque<Integer>;
begin
  C := specialize TVecDeque<Integer>.Create;
  try
    C.PushBack(11);
    C.PushBack(12);
    C.PushBack(13);
    FVecDeque.Clear;
    FVecDeque.Resize(2);
    FVecDeque.Write(2, C);
    AssertEquals('Count should be 5', SizeInt(5), SizeInt(FVecDeque.GetCount));
    AssertEquals('Index 2', 11, FVecDeque.Get(2));
    AssertEquals('Index 4', 13, FVecDeque.Get(4));
  finally
    C.Free;
  end;
end;
procedure TTestCase_VecDeque.Test_Write_Index_Collection_StartIndex;
var
  C: specialize TVecDeque<Integer>;
begin
  C := specialize TVecDeque<Integer>.Create;
  try
    C.PushBack(21);
    C.PushBack(22);
    C.PushBack(23);
    FVecDeque.Clear;
    FVecDeque.Resize(1);
    // start at 1 -> write 22,23 at index 1, count grows to 3
    FVecDeque.Write(1, C, 1);
    AssertEquals('Count should be 3', SizeInt(3), SizeInt(FVecDeque.GetCount));
    AssertEquals('Index 1', 22, FVecDeque.Get(1));
    AssertEquals('Index 2', 23, FVecDeque.Get(2));
  finally
    C.Free;
  end;
end;
procedure TTestCase_VecDeque.Test_WriteExact_Index_Pointer_Count;
var
  Buf: array[0..2] of Integer;
begin
  FVecDeque.Clear;
  FVecDeque.Resize(5);
  Buf[0]:=31; Buf[1]:=32; Buf[2]:=33;
  FVecDeque.WriteExact(2, @Buf[0], 3);
  AssertEquals('Count unchanged', SizeInt(5), SizeInt(FVecDeque.GetCount));
  AssertEquals('Index 2', 31, FVecDeque.Get(2));
  AssertEquals('Index 4', 33, FVecDeque.Get(4));
end;
procedure TTestCase_VecDeque.Test_WriteExact_Index_Array;
var
  A: array[0..1] of Integer = (41,42);
begin
  FVecDeque.Clear;
  FVecDeque.Resize(4);
  FVecDeque.WriteExact(2, A);
  AssertEquals('Count unchanged', SizeInt(4), SizeInt(FVecDeque.GetCount));
  AssertEquals('Index 2', 41, FVecDeque.Get(2));
  AssertEquals('Index 3', 42, FVecDeque.Get(3));
end;
procedure TTestCase_VecDeque.Test_WriteExact_Index_Collection;
var
  C: specialize TVecDeque<Integer>;
begin
  C := specialize TVecDeque<Integer>.Create;
  try
    FVecDeque.Clear;
    FVecDeque.Resize(5);
    C.Append([51,52,53]);
    FVecDeque.WriteExact(2, C);
    AssertEquals('Count unchanged', SizeInt(5), SizeInt(FVecDeque.GetCount));
    AssertEquals('Index 2', 51, FVecDeque.Get(2));
    AssertEquals('Index 4', 53, FVecDeque.Get(4));
  finally
    C.Free;
  end;
end;
procedure TTestCase_VecDeque.Test_WriteExact_Index_Collection_StartIndex;
var
  C: specialize TVecDeque<Integer>;
begin
  C := specialize TVecDeque<Integer>.Create;
  try
    FVecDeque.Clear;
    FVecDeque.Resize(4);
    C.Append([61,62,63,64]);
    FVecDeque.WriteExact(1, C, 2); // write [63,64] to positions 1..2
    AssertEquals('Count unchanged', SizeInt(4), SizeInt(FVecDeque.GetCount));
    AssertEquals('Index 1', 63, FVecDeque.Get(1));
    AssertEquals('Index 2', 64, FVecDeque.Get(2));
  finally
    C.Free;
  end;
end;
procedure TTestCase_VecDeque.Test_Delete_Index; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Delete_Index_Count; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_DeleteSwap_Index; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_DeleteSwap_Index_Count; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_RemoveCopy_Index_Pointer_Count;
var
  i: Integer;
  Buf: array[0..2] of Integer;
begin
  FVecDeque.Clear;
  for i := 0 to 6 do FVecDeque.PushBack(i); // [0..6]
  FVecDeque.RemoveCopy(2, @Buf[0], 3);      // copy [2,3,4], then ordered delete -> [0,1,5,6]
  AssertEquals(2, Buf[0]); AssertEquals(3, Buf[1]); AssertEquals(4, Buf[2]);
  AssertEquals(SizeInt(4), SizeInt(FVecDeque.GetCount));
  AssertEquals(5, FVecDeque.Get(2)); AssertEquals(6, FVecDeque.Get(3));
end;
procedure TTestCase_VecDeque.Test_RemoveCopy_Index_Pointer;
var
  Buf: Integer;
begin
  FVecDeque.Clear;
  FVecDeque.PushBack(10); FVecDeque.PushBack(11); FVecDeque.PushBack(12);
  FVecDeque.RemoveCopy(1, @Buf);
  AssertEquals(11, Buf);
  AssertEquals(SizeInt(2), SizeInt(FVecDeque.GetCount));
  AssertEquals(10, FVecDeque.Get(0)); AssertEquals(12, FVecDeque.Get(1));
end;
procedure TTestCase_VecDeque.Test_RemoveArray_Index_Array_Count;
var
  i: Integer;
  A: specialize TGenericArray<Integer>;
begin
  FVecDeque.Clear;
  for i := 10 to 15 do FVecDeque.PushBack(i); // [10..15]
  FVecDeque.RemoveArray(1, A, 3);             // copy [11,12,13], then ordered delete -> [10,14,15]
  AssertEquals(SizeInt(3), SizeInt(Length(A)));
  AssertEquals(11, A[0]); AssertEquals(12, A[1]); AssertEquals(13, A[2]);
  AssertEquals(SizeInt(3), SizeInt(FVecDeque.GetCount));
  AssertEquals(10, FVecDeque.Get(0)); AssertEquals(14, FVecDeque.Get(1)); AssertEquals(15, FVecDeque.Get(2));
end;
procedure TTestCase_VecDeque.Test_Remove_Index_Element;
var
  E: Integer;
begin
  FVecDeque.Clear;
  FVecDeque.PushBack(7); FVecDeque.PushBack(8); FVecDeque.PushBack(9); // [7,8,9]
  FVecDeque.Remove(1, E);                       // remove value at index 1 -> 8
  AssertEquals(8, E);
  AssertEquals(SizeInt(2), SizeInt(FVecDeque.GetCount));
  AssertEquals(7, FVecDeque.Get(0)); AssertEquals(9, FVecDeque.Get(1));
end;
procedure TTestCase_VecDeque.Test_RemoveCopySwap_Index_Pointer_Count;
var
  i: Integer;
  Buf: array[0..1] of Integer;
begin
  FVecDeque.Clear;
  for i := 1 to 6 do FVecDeque.PushBack(i); // [1..6]
  FVecDeque.RemoveCopySwap(2, @Buf[0], 2);  // copy [3,4], then swap-delete -> remaining size 4
  AssertEquals(3, Buf[0]); AssertEquals(4, Buf[1]);
  AssertEquals(SizeInt(4), SizeInt(FVecDeque.GetCount));
  AssertEquals(SizeUInt(0), FVecDeque.CountOf(3));
  AssertEquals(SizeUInt(0), FVecDeque.CountOf(4));
end;
procedure TTestCase_VecDeque.Test_RemoveCopySwap_Index_Pointer;
var
  Buf: Integer;
begin
  FVecDeque.Clear;
  FVecDeque.PushBack(5); FVecDeque.PushBack(6); FVecDeque.PushBack(7); // [5,6,7]
  FVecDeque.RemoveCopySwap(1, @Buf);
  AssertEquals(6, Buf);
  AssertEquals(SizeInt(2), SizeInt(FVecDeque.GetCount));
  AssertEquals(SizeUInt(0), FVecDeque.CountOf(6));
end;
procedure TTestCase_VecDeque.Test_RemoveArraySwap_Index_Array_Count;
var
  i: Integer;
  A: specialize TGenericArray<Integer>;
begin
  FVecDeque.Clear;
  for i := 0 to 5 do FVecDeque.PushBack(i);   // [0..5]
  FVecDeque.RemoveArraySwap(1, A, 3);         // copy [1,2,3], then swap-delete -> size 3
  AssertEquals(SizeInt(3), SizeInt(Length(A)));
  AssertEquals(1, A[0]); AssertEquals(2, A[1]); AssertEquals(3, A[2]);
  AssertEquals(SizeInt(3), SizeInt(FVecDeque.GetCount));
  AssertEquals(SizeUInt(0), FVecDeque.CountOf(1));
  AssertEquals(SizeUInt(0), FVecDeque.CountOf(2));
  AssertEquals(SizeUInt(0), FVecDeque.CountOf(3));
end;
procedure TTestCase_VecDeque.Test_RemoveSwap_Index_Element;
var
  i, E: Integer;
begin
  FVecDeque.Clear;
  for i := 5 to 9 do FVecDeque.PushBack(i);   // [5..9]
  FVecDeque.RemoveSwap(1, E);                 // remove value 6, swap with last -> size 4
  AssertEquals(6, E);
  AssertEquals(SizeInt(4), SizeInt(FVecDeque.GetCount));
  AssertEquals(SizeUInt(0), FVecDeque.CountOf(6));
end;

{ IVecDeque 特有方法测试占位符 (22个) }
procedure TTestCase_VecDeque.Test_IsFull; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_GetAllocator; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_GetData; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_SetData; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Clone; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_IsCompatible; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_GetEnumerator; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Iter; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_GetElementSize; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_GetIsManagedType; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_GetElementManager; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_GetElementTypeInfo; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_LoadFrom_Array; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_LoadFrom_Collection; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_LoadFrom_Pointer; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_LoadFromUnChecked; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Append_Array; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Append_Collection; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_Append_Pointer; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_AppendTo; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_SaveTo; begin { TODO: 实现 } end;
procedure TTestCase_VecDeque.Test_ToArray; begin { TODO: 实现 } end;

{ ===== 注意：还有更多测试方法未列出，总计约 270+ 个测试方法 ===== }
{ 包括：FindLast 系列、CountOf 系列、Replace 系列、IsSorted 系列、BinarySearch 系列等 }

procedure TTestCase_VecDeque.Test_Fuzz_RandomSequence_FixedSeed;
var
  Seed: QWord;
  I, Op, V, Pos, Count, Removed: Integer;
  Baseline: array of Integer;
  Tmp: array of Integer;
begin
  Seed := 123456789;
  Randomize;
  RandSeed := Seed;

  FVecDeque.Clear;
  SetLength(Baseline, 0);

  for I := 1 to 10000 do
  begin
    Op := Random(8);
    case Op of
      0: begin
           V := Random(1000);
           FVecDeque.PushFront(V);
           Insert(V, Baseline, 0);
         end;
      1: begin
           V := Random(1000);
           FVecDeque.PushBack(V);
           SetLength(Baseline, Length(Baseline)+1);
           Baseline[High(Baseline)] := V;
         end;
      2: if Length(Baseline) > 0 then
         begin
           Removed := FVecDeque.PopFront;
           AssertEquals(Baseline[0], Removed);
           Delete(Baseline, 0, 1);
         end;
      3: if Length(Baseline) > 0 then
         begin
           Removed := FVecDeque.PopBack;
           AssertEquals(Baseline[High(Baseline)], Removed);
           SetLength(Baseline, Length(Baseline)-1);
         end;
      4: begin
           // Insert at random position
           V := Random(1000);
           if FVecDeque.GetCount = 0 then
             Pos := 0
           else
             Pos := Random(LongInt(FVecDeque.GetCount));
           FVecDeque.Insert(Pos, V);
           Insert(V, Baseline, Pos);
         end;
      5: if FVecDeque.GetCount > 0 then
         begin
           Pos := Random(LongInt(FVecDeque.GetCount));
           Removed := FVecDeque.Remove(Pos);
           AssertEquals(Baseline[Pos], Removed);
           Delete(Baseline, Pos, 1);
         end;
      6: begin
           // Write a tiny array or slice overwriting at random
           if FVecDeque.GetCount = 0 then continue;
           Pos := Random(LongInt(FVecDeque.GetCount));
           Count := 1 + Random(3);
           SetLength(Tmp, Count);
           for V := 0 to Count-1 do Tmp[V] := Random(1000);
           // overwrite in range; clamp
           if Pos + Count > FVecDeque.GetCount then
             Count := FVecDeque.GetCount - Pos;
           if Count > 0 then
           begin
             FVecDeque.Write(Pos, Tmp);
             Move(Tmp[0], Baseline[Pos], Count*SizeOf(Integer));
           end;
         end;
      7: begin
           // Write from collection (self baseline via array)
           if Length(Baseline) = 0 then continue;
           if FVecDeque.GetCount = 0 then
             Pos := 0
           else
             Pos := Random(LongInt(FVecDeque.GetCount));
           Count := Random(3);
           SetLength(Tmp, Count);
           for V := 0 to Count-1 do Tmp[V] := Random(1000);
           FVecDeque.Write(Pos, Tmp);
           if Pos + Count > Length(Baseline) then
             SetLength(Baseline, Pos + Count);
           for V := 0 to Count-1 do Baseline[Pos+V] := Tmp[V];
         end;
    end;
  end;  // close outer for I := 1 to 10000 do


  // Compare against baseline
  SetLength(Tmp, FVecDeque.GetCount);
  if Length(Tmp) > 0 then
    FVecDeque.Read(0, @Tmp[0], Length(Tmp));
  AssertEquals(Length(Baseline), Length(Tmp));
  for I := 0 to High(Tmp) do
    AssertEquals(Baseline[I], Tmp[I]);
end;

procedure TTestCase_VecDeque.Test_Wraparound_Heavy;
var
  I, Round, V, Removed: Integer;
  Tmp: array of Integer;
begin
  FVecDeque.Clear;
  // Small capacity scenario to force wraparound via many Push/Pop
  for Round := 1 to 50 do
  begin
    // Push front/back alternating
    for I := 1 to 8 do
    begin
      V := Round*100 + I;
      if Odd(I) then FVecDeque.PushFront(V) else FVecDeque.PushBack(V);
    end;
    // Pop a few from both ends
    if FVecDeque.GetCount > 0 then Removed := FVecDeque.PopFront;
    if FVecDeque.GetCount > 0 then Removed := FVecDeque.PopBack;
  end;
end;

procedure TTestCase_VecDeque.Test_OverWriteUnChecked_Collection_Limit;
var
  Src, Dst: specialize TVecDeque<Integer>;
  I: Integer;
begin
  Src := specialize TVecDeque<Integer>.Create;
  Dst := specialize TVecDeque<Integer>.Create;
  try
    for I := 1 to 10 do Src.PushBack(I*10);          // 10..100
    for I := 1 to 8 do Dst.PushBack(I);              // 1..8
    // 从 Src 的 startIndex=3(第4个元素=40) 开始，覆盖 Dst 的 index=2 开始的 3 个元素
    // 预计覆盖 40,50,60 到 Dst[2..4]。但限定 Count=3（提前退出），不触发扩容。
    Dst.OverWriteUnChecked(2, Src, 3);
    AssertEquals(8, Dst.GetCount);
    AssertEquals(1, Dst.Get(0)); AssertEquals(2, Dst.Get(1));
    AssertEquals(40, Dst.Get(2)); AssertEquals(50, Dst.Get(3)); AssertEquals(60, Dst.Get(4));
  finally
    Src.Free; Dst.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_OverWriteUnChecked_Collection_Limit_Wraparound;
var
  Src, Dst: specialize TVecDeque<Integer>;
  I: Integer;
begin
  Src := specialize TVecDeque<Integer>.Create;
  Dst := specialize TVecDeque<Integer>.Create;
  try
    // 构造 Src
    for I := 0 to 15 do Src.PushBack(100 + I);
    // 构造 Dst 并制造 wrap：
    for I := 1 to 12 do Dst.PushBack(I);
    for I := 1 to 6 do Ignore(IntToStr(Dst.PopFront));
    for I := 20 to 27 do Dst.PushBack(I);
    // 此时队列发生 wrap，多次 push/pop 后结构复杂
    Dst.OverWriteUnChecked(1, Src, 5); // 覆盖 5 个位置
    // 基本断言：不崩溃，数量不变
    AssertEquals(12, Dst.GetCount);
  finally
    Src.Free; Dst.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Insert_Index_Collection_StartIndex_Wraparound;
var
  Src, Dst: specialize TVecDeque<Integer>;
  I: Integer;
begin
  Src := specialize TVecDeque<Integer>.Create;
  Dst := specialize TVecDeque<Integer>.Create;
  try
    for I := 0 to 9 do Src.PushBack(200 + I);  // 200..209
    for I := 1 to 8 do Dst.PushBack(I);       // 1..8
    for I := 1 to 5 do Ignore(IntToStr(Dst.PopFront));
    for I := 30 to 35 do Dst.PushBack(I);
    // 在 wrap 状态下执行 Insert from collection (startIndex=2)
    Dst.Insert(2, Src, 2);
    AssertTrue(Dst.GetCount > 0);
  finally
    Src.Free; Dst.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Insert_Index_Collection_StartIndex_Heavy;
var
  Src, Dst: specialize TVecDeque<Integer>;
  I, Pos: Integer;
begin
  Src := specialize TVecDeque<Integer>.Create;
  Dst := specialize TVecDeque<Integer>.Create;
  try
    for I := 0 to 49 do Src.PushBack(300 + I);
    for I := 1 to 20 do Dst.PushBack(I);
    // 多次随机位置插入 Src 的后半段内容，验证稳定性
    for I := 1 to 50 do
    begin
      if Dst.GetCount = 0 then Pos := 0 else Pos := Random(LongInt(Dst.GetCount));
      Dst.Insert(Pos, Src, 25);
    end;
    AssertTrue(Dst.GetCount >= 20);
  finally
    Src.Free; Dst.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Write_Index_Collection_StartIndex_HeadTailBoundaries;
var
  Src, Dst: specialize TVecDeque<Integer>;
  I: Integer;
begin
  Src := specialize TVecDeque<Integer>.Create;
  Dst := specialize TVecDeque<Integer>.Create;
  try
    for I := 0 to 9 do Src.PushBack(100 + I); // 100..109
    for I := 0 to 9 do Dst.PushBack(I);       // 0..9

    // 写入到头部边界：index=0, start=8 -> 写入 2 个元素
    Dst.Write(0, Src, 8);
    AssertEquals(10, Dst.GetCount);
    AssertEquals(100+8, Dst.Get(0)); AssertEquals(100+9, Dst.Get(1));

    // 写入到尾部边界：index=8, start=0 -> 写入 2 个元素（尾两位覆盖）
    Dst.Write(8, Src, 0);
    AssertEquals(10, Dst.GetCount);
    AssertEquals(100+0, Dst.Get(8)); AssertEquals(100+1, Dst.Get(9));
  finally
    Src.Free; Dst.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Write_Index_Collection_StartIndex_CapacityGrowthEdge;
var
  Src, Dst: specialize TVecDeque<Integer>;
  I: Integer;
begin
  Src := specialize TVecDeque<Integer>.Create;
  Dst := specialize TVecDeque<Integer>.Create;
  try
    // 构造源和目标，使得写入后刚好需要增长 FCount（EnsureCapacity 已在 Write 内部处理）
    for I := 0 to 4 do Src.PushBack(200 + I); // 200..204，Count=5
    for I := 0 to 4 do Dst.PushBack(I);       // 0..4，Count=5

    // index=4，start=1 -> 需要写入 4 个元素（204 超界被截断），FCount 将增长到 8
    Dst.Write(4, Src, 1);
    AssertEquals(8, Dst.GetCount);
    AssertEquals(200+1, Dst.Get(4));
    AssertEquals(200+2, Dst.Get(5));
    AssertEquals(200+3, Dst.Get(6));
    AssertEquals(200+4, Dst.Get(7));
  finally
    Src.Free; Dst.Free;
  end;
end;



{ 所有这些方法都遵循相同的占位符模式：begin TODO end }

procedure TTestCase_VecDeque.Test_Insert_Index_Array_Wraparound;
var
  D: specialize TVecDeque<Integer>;
  A: array[0..2] of Integer = (7,8,9);
  i: Integer;
begin
  D := FVecDeque; // 复用场内实例
  D.Clear; D.ReserveExact(8);
  // 构造 wrap: 先填再 pop，再 push
  for i := 1 to 6 do D.PushBack(i);     // [1..6]
  for i := 1 to 3 do Ignore(IntToStr(D.PopFront)); // [4,5,6]
  for i := 10 to 15 do D.PushBack(i);   // wrap -> [4,5,6,10,11,12,13,14,15]
  // 在中间插入数组 A 到索引2（逻辑位置，可能跨物理边界移动）
  D.Insert(2, A);
  // 断言：Count增加，插入后顺序
  AssertEquals(SizeInt(9+3), SizeInt(D.GetCount));
  AssertEquals(4, D.Get(0)); AssertEquals(5, D.Get(1));
  AssertEquals(7, D.Get(2)); AssertEquals(8, D.Get(3)); AssertEquals(9, D.Get(4));
end;

procedure TTestCase_VecDeque.Test_Insert_Index_Pointer_Count_Wraparound;
var
  D: specialize TVecDeque<Integer>;
  Buf: array[0..1] of Integer;
  i: Integer;
begin
  D := FVecDeque; D.Clear; D.ReserveExact(8);
  for i := 1 to 5 do D.PushBack(i);     // [1..5]
  for i := 1 to 3 do Ignore(IntToStr(D.PopFront)); // [4,5]
  for i := 20 to 27 do D.PushBack(i);   // wrap -> [4,5,20,21,22,23,24,25,26,27]
  Buf[0] := 100; Buf[1] := 101;
  D.Insert(1, @Buf[0], 2);
  AssertEquals(SizeInt(12), SizeInt(D.GetCount));
  AssertEquals(4, D.Get(0)); AssertEquals(100, D.Get(1)); AssertEquals(101, D.Get(2));
end;

procedure TTestCase_VecDeque.Test_Write_Index_Array_Wraparound;
var
  D: specialize TVecDeque<Integer>;
  A: array[0..2] of Integer = (31,32,33);
  i: Integer;
begin
  D := FVecDeque; D.Clear; D.ReserveExact(8);
  for i := 1 to 6 do D.PushBack(i);     // [1..6]
  for i := 1 to 4 do Ignore(IntToStr(D.PopFront)); // [5,6]
  for i := 40 to 46 do D.PushBack(i);   // wrap -> [5,6,40,41,42,43,44,45,46]
  // 在索引1处写入数组（跨段可能覆盖两段）
  D.Write(1, A);
  // Count 应增长至 1+3=4 与原末尾对齐（原 Count=9，写入在范围内不增 Count；但我们确保 index+len>Count 时增长）
  // 此处写入在范围内，Count 不变，验证覆盖内容
  AssertEquals(SizeInt(9), SizeInt(D.GetCount));
  AssertEquals(31, D.Get(1)); AssertEquals(33, D.Get(3));
end;

procedure TTestCase_VecDeque.Test_Write_Index_Pointer_Count_Wraparound;
var
  D: specialize TVecDeque<Integer>;
  Buf: array[0..3] of Integer;
  i: Integer;
begin
  D := FVecDeque; D.Clear; D.ReserveExact(8);
  for i := 1 to 4 do D.PushBack(i);     // [1..4]
  for i := 1 to 2 do Ignore(IntToStr(D.PopFront)); // [3,4]
  for i := 50 to 56 do D.PushBack(i);   // wrap -> [3,4,50,51,52,53,54,55,56]
  Buf[0] := 201; Buf[1] := 202; Buf[2] := 203; Buf[3] := 204;
  // 在 index=7 写入4个，index+count(=11)>Count(=9) -> Count 将增长到 11
  D.Write(7, @Buf[0], 4);
  AssertEquals(SizeInt(11), SizeInt(D.GetCount));
  AssertEquals(201, D.Get(7)); AssertEquals(204, D.Get(10));
end;

procedure TTestCase_VecDeque.Test_WriteExact_OutOfRange_Raises;
var
  raised: Boolean;
begin
  FVecDeque.Clear; FVecDeque.Resize(3);
  raised := False;
  try
    FVecDeque.WriteExact(2, [10,11]); // 2+2>3 -> out of range
  except on E: EOutOfRange do raised := True; end;
  AssertTrue('WriteExact out-of-range should raise', raised);
end;

procedure TTestCase_VecDeque.Test_Insert_Collection_Nil_Raises;
var
  raised: Boolean;
begin
  FVecDeque.Clear;
  raised := False;
  try
    FVecDeque.Insert(0, nil); // nil collection
  except on E: EArgumentNil do raised := True; end;
  AssertTrue('Insert(nil) should raise EArgumentNil', raised);
end;

procedure TTestCase_VecDeque.Test_Write_Pointer_Nil_Raises;
var
  raised: Boolean;
begin
  FVecDeque.Clear; FVecDeque.Resize(1);
  raised := False;
  try
    FVecDeque.Write(0, nil, 1);
  except on E: EArgumentNil do raised := True; end;
  AssertTrue('Write(nil pointer) should raise EArgumentNil', raised);
end;

procedure TTestCase_VecDeque.Test_Insert_AtHead_Tail_Wraparound;
var
  i: Integer;
begin
  FVecDeque.Clear; FVecDeque.ReserveExact(8);
  for i := 1 to 5 do FVecDeque.PushBack(i); // [1..5]
  for i := 1 to 3 do Ignore(IntToStr(FVecDeque.PopFront));    // [4,5]
  for i := 20 to 25 do FVecDeque.PushBack(i);                 // wrap -> [4,5,20..25]
  // 在 head 位置插入
  FVecDeque.Insert(0, 99);
  AssertEquals(99, FVecDeque.Get(0)); AssertEquals(4, FVecDeque.Get(1));
  // 在 tail 位置插入
  FVecDeque.Insert(FVecDeque.GetCount, 77);
  AssertEquals(77, FVecDeque.Get(FVecDeque.GetCount-1));
end;

procedure TTestCase_VecDeque.Test_Insert_BoundaryMatrix_Array_Continuous;
var
  D: specialize TVecDeque<Integer>;
  A: array[0..1] of Integer = (100,101);
begin
  D := FVecDeque; D.Clear; D.Append([1,2,3,4]);
  // index=0
  D.Insert(0, A); ExpectSeq([100,101,1,2,3,4]);
  // index=1
  D.Insert(1, A); ExpectSeq([100,100,101,101,1,2,3,4]);
  // index=Count-1
  D.Insert(D.GetCount-1, A); ExpectSeq([100,100,101,101,1,2,3,100,101,4]);
  // index=Count (append behavior)
  D.Insert(D.GetCount, A); ExpectSeq([100,100,101,101,1,2,3,100,101,4,100,101]);
end;

procedure TTestCase_VecDeque.Test_Insert_BoundaryMatrix_Array_Wrap;
var
  D: specialize TVecDeque<Integer>;
  A: array[0..1] of Integer = (200,201);
  i: Integer;
begin
  D := FVecDeque; D.Clear; D.ReserveExact(8);
  for i := 1 to 5 do D.PushBack(i); // [1..5]
  for i := 1 to 3 do Ignore(IntToStr(D.PopFront)); // [4,5]
  for i := 20 to 25 do D.PushBack(i); // wrap -> [4,5,20..25]
  // index=0
  D.Insert(0, A); ExpectSeq([200,201,4,5,20,21,22,23,24,25]);
  // index=1
  D.Insert(1, A); ExpectSeq([200,200,201,201,4,5,20,21,22,23,24,25]);
  // index=Count-1（在末尾前插入）
  D.Insert(D.GetCount-1, A);
  ExpectSeq([200,200,201,201,4,5,20,21,22,23,24,200,201,25]);
  // index=Count (append behavior)
  D.Insert(D.GetCount, A);
  ExpectSeq([200,200,201,201,4,5,20,21,22,23,24,200,201,25,200,201]);
end;

procedure TTestCase_VecDeque.Test_Write_BoundaryMatrix_Array_Continuous;
var
  D: specialize TVecDeque<Integer>;
  A: array[0..2] of Integer = (300,301,302);
begin
  D := FVecDeque; D.Clear; D.Append([1,2,3,4]);
  // index=0 覆盖（不扩张）
  D.Write(0, A); ExpectSeq([300,301,302,4]);
  // index=1 覆盖（不扩张）
  D.Write(1, A); ExpectSeq([300,300,301,302]);
  // index=Count-1 覆盖尾部并扩张 -> 末尾插入两位
  D.Write(D.GetCount-1, A); ExpectSeq([300,300,301,300,301,302]);
  // index=Count 追加写 -> Append 三位
  D.Write(D.GetCount, A); ExpectSeq([300,300,301,300,301,302,300,301,302]);
end;

procedure TTestCase_VecDeque.Test_Write_BoundaryMatrix_Array_Wrap;
var
  D: specialize TVecDeque<Integer>;
  A: array[0..2] of Integer = (400,401,402);
  i: Integer;
begin
  D := FVecDeque; D.Clear; D.ReserveExact(8);
  for i := 1 to 5 do D.PushBack(i); // [1..5]
  for i := 1 to 3 do Ignore(IntToStr(D.PopFront)); // [4,5]
  for i := 20 to 25 do D.PushBack(i); // wrap -> [4,5,20..25]
  // index=0 覆盖头部（并保留 Count）
  D.Write(0, A); ExpectSeq([400,401,402,5,20,21,22,23,24]);
  // index=1 覆盖中段
  D.Write(1, A); ExpectSeq([400,400,401,402,20,21,22,23,24]);
  // index=Count-1 覆盖尾部一段并扩张
  D.Write(D.GetCount-1, A); ExpectSeq([400,400,401,400,401,402,23,24]);
  // index=Count 追加写
  D.Write(D.GetCount, A); ExpectSeq([400,400,401,400,401,402,23,24,400,401,402]);
end;

procedure TTestCase_VecDeque.Test_Insert_BoundaryMatrix_Pointer_Continuous;
var
  D: specialize TVecDeque<Integer>;
  Buf: array[0..1] of Integer;
begin
  D := FVecDeque; D.Clear; D.Append([1,2,3,4]); Buf[0]:=500; Buf[1]:=501;
  D.Insert(0, @Buf[0], 2); ExpectSeq([500,501,1,2,3,4]);
  D.Insert(1, @Buf[0], 2); ExpectSeq([500,500,501,501,1,2,3,4]);
  D.Insert(D.GetCount-1, @Buf[0], 2); ExpectSeq([500,500,501,501,1,2,3,500,501,4]);
  D.Insert(D.GetCount, @Buf[0], 2); ExpectSeq([500,500,501,501,1,2,3,500,501,4,500,501]);
end;

procedure TTestCase_VecDeque.Test_Insert_BoundaryMatrix_Pointer_Wrap;
var
  D: specialize TVecDeque<Integer>;
  Buf: array[0..1] of Integer;
  i: Integer;
begin
  D := FVecDeque; D.Clear; D.ReserveExact(8); Buf[0]:=600; Buf[1]:=601;
  for i:=1 to 5 do D.PushBack(i); for i:=1 to 3 do Ignore(IntToStr(D.PopFront)); for i:=20 to 25 do D.PushBack(i);
  D.Insert(0, @Buf[0], 2); ExpectSeq([600,601,4,5,20,21,22,23,24,25]);
  D.Insert(1, @Buf[0], 2); ExpectSeq([600,600,601,601,4,5,20,21,22,23,24,25]);
  D.Insert(D.GetCount-1, @Buf[0], 2); ExpectSeq([600,600,601,601,4,5,20,21,22,23,24,600,601,25]);
  D.Insert(D.GetCount, @Buf[0], 2); ExpectSeq([600,600,601,601,4,5,20,21,22,23,24,600,601,25,600,601]);
end;

procedure TTestCase_VecDeque.Test_Write_BoundaryMatrix_Pointer_Continuous;
var
  D: specialize TVecDeque<Integer>;
  Buf: array[0..2] of Integer;
begin
  D := FVecDeque; D.Clear; D.Append([1,2,3,4]); Buf[0]:=700; Buf[1]:=701; Buf[2]:=702;
  D.Write(0, @Buf[0], 3); ExpectSeq([700,701,702,4]);
  D.Write(1, @Buf[0], 3); ExpectSeq([700,700,701,702]);
  D.Write(D.GetCount-1, @Buf[0], 3); ExpectSeq([700,700,701,700,701,702]);
  D.Write(D.GetCount, @Buf[0], 3); ExpectSeq([700,700,701,700,701,702,700,701,702]);
end;

procedure TTestCase_VecDeque.Test_Write_BoundaryMatrix_Pointer_Wrap;
var
  D: specialize TVecDeque<Integer>;
  Buf: array[0..2] of Integer;
  i: Integer;
begin
  D := FVecDeque; D.Clear; D.ReserveExact(8); Buf[0]:=800; Buf[1]:=801; Buf[2]:=802;
  for i:=1 to 5 do D.PushBack(i); for i:=1 to 3 do Ignore(IntToStr(D.PopFront)); for i:=20 to 25 do D.PushBack(i);
  D.Write(0, @Buf[0], 3); ExpectSeq([800,801,802,5,20,21,22,23,24]);
  D.Write(1, @Buf[0], 3); ExpectSeq([800,800,801,802,20,21,22,23,24]);
  D.Write(D.GetCount-1, @Buf[0], 3); ExpectSeq([800,800,801,800,801,802,23,24]);
  D.Write(D.GetCount, @Buf[0], 3); ExpectSeq([800,800,801,800,801,802,23,24,800,801,802]);
end;

procedure TTestCase_VecDeque.Test_Insert_BoundaryMatrix_Collection_Continuous;
var
  D: specialize TVecDeque<Integer>;
  C: specialize TVec<Integer>;
begin
  D := FVecDeque; D.Clear; D.Append([1,2,3,4]); C := specialize TVec<Integer>.Create; try
    C.Append([900,901]);
    D.Insert(0, C); ExpectSeq([900,901,1,2,3,4]);
    D.Insert(1, C); ExpectSeq([900,900,901,901,1,2,3,4]);
    D.Insert(D.GetCount-1, C); ExpectSeq([900,900,901,901,1,2,3,900,901,4]);
    D.Insert(D.GetCount, C); ExpectSeq([900,900,901,901,1,2,3,900,901,4,900,901]);
  finally C.Free; end;
end;

procedure TTestCase_VecDeque.Test_Insert_BoundaryMatrix_Collection_Wrap;
var
  D: specialize TVecDeque<Integer>;
  C: specialize TVec<Integer>;
  i: Integer;
begin
  D := FVecDeque; D.Clear; D.ReserveExact(8); C := specialize TVec<Integer>.Create; try
    C.Append([910,911]);
    for i:=1 to 5 do D.PushBack(i); for i:=1 to 3 do Ignore(IntToStr(D.PopFront)); for i:=20 to 25 do D.PushBack(i);
    D.Insert(0, C); ExpectSeq([910,911,4,5,20,21,22,23,24,25]);
    D.Insert(1, C); ExpectSeq([910,910,911,911,4,5,20,21,22,23,24,25]);
    D.Insert(D.GetCount-1, C); ExpectSeq([910,910,911,911,4,5,20,21,22,23,24,910,911,25]);
    D.Insert(D.GetCount, C); ExpectSeq([910,910,911,911,4,5,20,21,22,23,24,910,911,25,910,911]);
  finally C.Free; end;
end;

procedure TTestCase_VecDeque.Test_Write_BoundaryMatrix_Collection_Continuous;
var
  D: specialize TVecDeque<Integer>;
  C: specialize TVec<Integer>;
begin
  D := FVecDeque; D.Clear; D.Append([1,2,3,4]); C := specialize TVec<Integer>.Create; try
    C.Append([920,921,922]);
    D.Write(0, C); ExpectSeq([920,921,922,4]);
    D.Write(1, C); ExpectSeq([920,920,921,922]);
    D.Write(D.GetCount-1, C); ExpectSeq([920,920,921,920,921,922]);
    D.Write(D.GetCount, C); ExpectSeq([920,920,921,920,921,922,920,921,922]);
  finally C.Free; end;
end;

procedure TTestCase_VecDeque.Test_Write_BoundaryMatrix_Collection_Wrap;
var
  D: specialize TVecDeque<Integer>;
  C: specialize TVec<Integer>;
  i: Integer;
begin
  D := FVecDeque; D.Clear; D.ReserveExact(8); C := specialize TVec<Integer>.Create; try
    C.Append([930,931,932]);
    for i:=1 to 5 do D.PushBack(i); for i:=1 to 3 do Ignore(IntToStr(D.PopFront)); for i:=20 to 25 do D.PushBack(i);
    D.Write(0, C); ExpectSeq([930,931,932,5,20,21,22,23,24]);
    D.Write(1, C); ExpectSeq([930,930,931,932,20,21,22,23,24]);
    D.Write(D.GetCount-1, C); ExpectSeq([930,930,931,930,931,932,23,24]);
    D.Write(D.GetCount, C); ExpectSeq([930,930,931,930,931,932,23,24,930,931,932]);
  finally C.Free; end;
end;

procedure TTestCase_VecDeque.Test_Insert_Write_BoundaryMatrix_Array_FullSeq;
var
  D: specialize TVecDeque<Integer>;
  A2: array[0..1] of Integer = (10,11);
  A3: array[0..2] of Integer = (20,21,22);
  Seq: array of Integer;
  i: Integer;
begin
  D := FVecDeque; D.Clear; D.Append([1,2,3,4]);
  // Insert at 0
  D.Insert(0, A2); ExpectSeq([10,11,1,2,3,4]);
  // Insert at 1
  D.Insert(1, A2); ExpectSeq([10,10,11,11,1,2,3,4]);
  // Write at Count (append)
  D.Write(D.GetCount, A3); ExpectSeq([10,10,11,11,1,2,3,4,20,21,22]);
  // Write overlapping in middle
  D.Write(3, A3); ExpectSeq([10,10,11,20,21,22,3,4,20,21,22]);
end;

procedure TTestCase_VecDeque.Test_Insert_Write_BoundaryMatrix_Pointer_FullSeq;
var
  D: specialize TVecDeque<Integer>;
  P2: array[0..1] of Integer = (110,111);
  P3: array[0..2] of Integer = (120,121,122);
  Seq: array of Integer;
  i: Integer;
begin
  D := FVecDeque; D.Clear; D.Append([5,6,7,8]);
  D.Insert(0, @P2[0], 2); ExpectSeq([110,111,5,6,7,8]);
  D.Insert(1, @P2[0], 2); ExpectSeq([110,110,111,111,5,6,7,8]);
  D.Write(D.GetCount, @P3[0], 3); ExpectSeq([110,110,111,111,5,6,7,8,120,121,122]);
  D.Write(2, @P3[0], 3); ExpectSeq([110,110,120,121,122,6,7,8,120,121,122]);
end;

procedure TTestCase_VecDeque.Test_Insert_Write_BoundaryMatrix_Collection_FullSeq;
var
  D: specialize TVecDeque<Integer>;
  C2, C3: specialize TVec<Integer>;
  Seq: array of Integer;
  i: Integer;
begin
  D := FVecDeque; D.Clear; D.Append([9,10,11,12]);
  C2 := specialize TVec<Integer>.Create; C3 := specialize TVec<Integer>.Create;
  try
    C2.Append([210,211]); C3.Append([220,221,222]);
    D.Insert(0, C2); ExpectSeq([210,211,9,10,11,12]);
    D.Insert(1, C2); ExpectSeq([210,210,211,211,9,10,11,12]);
    D.Write(D.GetCount, C3); ExpectSeq([210,210,211,211,9,10,11,12,220,221,222]);
    D.Write(2, C3); ExpectSeq([210,210,220,221,222,211,9,10,11,12,220,221,222]);
  finally
    C2.Free; C3.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_LargeGrowth_Wrap_MultiExpansion;
var
  D: specialize TVecDeque<Integer>;
  i, rounds: Integer;
  Seq: array of Integer;
begin
  D := FVecDeque; D.Clear; D.ReserveExact(4);
  // Force multiple grow and wrap rotations
  rounds := 5; // push 5*100 elements with interleaved pops
  for i := 0 to (rounds*100)-1 do
  begin
    D.PushBack(i);
    if (i mod 7)=0 then D.PushFront(-i); // provoke head wrap
    if (i mod 5)=0 then Ignore(IntToStr(D.PopFront));
    if (i mod 11)=0 then Ignore(IntToStr(D.PopBack));
  end;
  // Insert and Write large chunks to cause further moves
  for i := 1 to 50 do D.PushBack(10000+i);
  D.Insert(1, [20000,20001,20002]);
  D.Write(D.GetCount-2, [30000,30001,30002]);
  // Verify read-back equals Get across entire deque
  SetLength(Seq, D.GetCount);
  if Length(Seq)>0 then D.Read(0, @Seq[0], Length(Seq));
  for i:=0 to High(Seq) do AssertEquals(Seq[i], D.Get(i));
end;

procedure TTestCase_VecDeque.Test_TryAndSafe_BoundaryConsistency;
var
  D: specialize TVecDeque<Integer>;
  v: Integer; ok: Boolean;
begin
  D := FVecDeque; D.Clear;
  // Empty: Try* return False/0, Safe 不抛异常
  ok := D.TryPeek(v); AssertFalse(ok);
  ok := D.TryPop(v); AssertFalse(ok);
  ok := D.TryRemove(0, v); AssertFalse(ok);
  // Safe variants should not raise
  AssertEquals(0, D.GetCount);
  // Push then Try* should succeed
  D.PushBack(1); D.PushBack(2);
  ok := D.TryPeek(v); AssertTrue(ok); AssertEquals(1, v);
  ok := D.TryPop(v);  AssertTrue(ok); AssertEquals(1, v);
  ok := D.TryPeek(v); AssertTrue(ok); AssertEquals(2, v);
end;

procedure TTestCase_VecDeque.Test_TryAndSafe_Matrix_Empty_Single_Multi_Wrap;
var
  D: specialize TVecDeque<Integer>;
  v: Integer; ok: Boolean; arr: specialize TGenericArray<Integer>;
  i: Integer;
begin
  D := FVecDeque; D.Clear;
  // 1) Empty
  ok := D.TryPeek(v); AssertFalse(ok);
  ok := D.TryPop(v); AssertFalse(ok);
  ok := D.TryPeek(arr, 0); AssertTrue(ok); // count=0 is a no-op success
  ok := D.TryPop(arr, 0);  AssertTrue(ok);

  // 2) Single element
  D.Clear; D.PushBack(42);
  ok := D.TryPeek(v); AssertTrue(ok); AssertEquals(42, v);
  ok := D.TryGet(0, v); AssertTrue(ok); AssertEquals(42, v);
  ok := D.TryRemove(0, v); AssertTrue(ok); AssertEquals(42, v);
  AssertEquals(0, D.GetCount);

  // 3) Multi elements
  D.Clear; for i:=1 to 5 do D.PushBack(i);
  ok := D.TryPeek(v); AssertTrue(ok); AssertEquals(5, v); // TryPeek is back
  ok := D.TryPop(v); AssertTrue(ok); AssertEquals(5, v);  // TryPop pops back
  ok := D.TryGet(2, v); AssertTrue(ok); AssertEquals(3, v);
  ok := D.TryRemove(1, v); AssertTrue(ok); AssertEquals(2, v); // remove index 1
  ExpectSeq([1,3,4]); // after pop back and remove index 1

  // 4) Wrap layout
  D.Clear; for i:=1 to 5 do D.PushBack(i);
  for i:=1 to 3 do Ignore(IntToStr(D.PopFront)); // [4,5]
  for i:=20 to 27 do D.PushBack(i); // wrap -> [4,5,20..27]
  ok := D.TryPeek(v); AssertTrue(ok); AssertEquals(27, v);
  ok := D.TryGet(0, v); AssertTrue(ok); AssertEquals(4, v);
  ok := D.TryRemove(D.GetCount-1, v); AssertTrue(ok); AssertEquals(27, v);
  ok := D.TryPeek(v); AssertTrue(ok); AssertEquals(26, v);
end;

procedure TTestCase_VecDeque.Test_Insert_CrossSegments_Patterns;
var
  D: specialize TVecDeque<Integer>;
  A: array[0..2] of Integer = (100,101,102);
  i: Integer;
begin
  // 构造 wrap 布局：[4,5,10,11,12,13,14,15]
  D := FVecDeque; D.Clear; D.ReserveExact(8);
  for i:=1 to 5 do D.PushBack(i);
  for i:=1 to 3 do Ignore(IntToStr(D.PopFront));
  for i:=10 to 15 do D.PushBack(i);
  // 在逻辑索引2处插入 A -> 期望 [4,5,100,101,102,10,11,12,13,14,15]
  D.Insert(2, A);
  ExpectSeq([4,5,100,101,102,10,11,12,13,14,15]);
  // 再在尾前插入 A -> 期望 ... 在末尾前再插入三位
  D.Insert(D.GetCount-1, A);
  ExpectSeq([4,5,100,101,102,10,11,12,13,14,100,101,102,15]);
end;

procedure TTestCase_VecDeque.Test_Write_CrossSegments_Patterns;
var
  D: specialize TVecDeque<Integer>;
  A: array[0..2] of Integer = (200,201,202);
  i: Integer;
begin
  // 构造 wrap 布局：[4,5,20,21,22,23,24,25]
  D := FVecDeque; D.Clear; D.ReserveExact(8);
  for i:=1 to 5 do D.PushBack(i);
  for i:=1 to 3 do Ignore(IntToStr(D.PopFront));
  for i:=20 to 25 do D.PushBack(i);
  // 在跨段位置覆盖：index=3 -> 覆盖 [23,24,25] 前的局部
  D.Write(3, A);
  ExpectSeq([4,5,20,200,201,202,23,24,25]);
  // 在尾部追加写（index=Count）
  D.Write(D.GetCount, A);
  ExpectSeq([4,5,20,200,201,202,23,24,25,200,201,202]);
end;

procedure TTestCase_VecDeque.Test_MultiGrow_PowerOfTwo_Consistency;
var
  D: specialize TVecDeque<Integer>;
  Snap: array of Integer;
  i: Integer;
begin
  D := FVecDeque; D.Clear; D.ReserveExact(8);
  // 触发多次扩容：>8, >16
  for i:=0 to 9 do D.PushBack(i); // 到 10 触发一次扩容
  for i:=0 to 2 do Ignore(IntToStr(D.PopFront)); // wrap
  for i:=10 to 20 do D.PushBack(i); // 进一步增长
  // 一致性校验：Read 快照与 Get 逐位一致
  SetLength(Snap, D.GetCount);
  if Length(Snap)>0 then D.Read(0, @Snap[0], Length(Snap));
  for i:=0 to High(Snap) do AssertEquals(Snap[i], D.Get(i));
end;

procedure TTestCase_VecDeque.Test_TryPeekCopy_Pointer_Wrap_CrossSegment;
var
  D: specialize TVecDeque<Integer>;
  Buf: array[0..3] of Integer;
  ok: Boolean;
  i: Integer;
begin
  // 构造小容量 wrap: [4,5,20,21,22,23]
  D := FVecDeque; D.Clear; D.ReserveExact(8);
  for i:=1 to 5 do D.PushBack(i);
  for i:=1 to 3 do Ignore(IntToStr(D.PopFront));
  for i:=20 to 23 do D.PushBack(i);
  // TryPeekCopy 取后端4个 -> 20,21,22,23
  ok := D.TryPeekCopy(@Buf[0], 4);
  AssertTrue(ok);
  AssertEquals(20, Buf[0]); AssertEquals(21, Buf[1]); AssertEquals(22, Buf[2]); AssertEquals(23, Buf[3]);
  // Count 不变
  AssertEquals(6, D.GetCount);
end;

procedure TTestCase_VecDeque.Test_TryGet_TryRemove_Wrap_Small;
var
  D: specialize TVecDeque<Integer>;
  v: Integer;
  ok: Boolean;
  i: Integer;
begin
  // 构造 wrap: [4,5,20,21,22]
  D := FVecDeque; D.Clear; D.ReserveExact(8);
  for i:=1 to 5 do D.PushBack(i);
  for i:=1 to 3 do Ignore(IntToStr(D.PopFront));
  for i:=20 to 22 do D.PushBack(i);
  // TryGet 首尾
  ok := D.TryGet(0, v); AssertTrue(ok); AssertEquals(4, v);
  ok := D.TryGet(D.GetCount-1, v); AssertTrue(ok); AssertEquals(22, v);
  // TryRemove 中间（逻辑跨段位置）
  ok := D.TryRemove(2, v); AssertTrue(ok); AssertEquals(20, v);
  ExpectSeq([4,5,21,22]);
end;

procedure TTestCase_VecDeque.Test_MultiGrow_InsertWrite_Checkpoints;
var
  D: specialize TVecDeque<Integer>;
  A2: array[0..1] of Integer = (1000,1001);
  A3: array[0..2] of Integer = (2000,2001,2002);
  Snap: array of Integer;
  i: Integer;
begin
  D := FVecDeque; D.Clear; D.ReserveExact(8);
  // 第一轮增长到 64
  for i:=0 to 63 do D.PushBack(i);
  D.Insert(1, A2);
  D.Write(D.GetCount-2, A3);
  SetLength(Snap, D.GetCount); if Length(Snap)>0 then D.Read(0, @Snap[0], Length(Snap));
  for i:=0 to High(Snap) do AssertEquals(Snap[i], D.Get(i));

  // 第二轮增长到 128，并在中部插入/前段覆盖
  for i:=64 to 127 do D.PushBack(i);
  D.Insert(D.GetCount div 2, A2);
  D.Write(3, A3);
  SetLength(Snap, D.GetCount); if Length(Snap)>0 then D.Read(0, @Snap[0], Length(Snap));
  for i:=0 to High(Snap) do AssertEquals(Snap[i], D.Get(i));
end;

procedure TTestCase_VecDeque.Test_TryOps_AfterWrapAndGrow_Baseline;
var
  D: specialize TVecDeque<Integer>;
  Baseline: array of Integer;
  Tmp: array of Integer;
  Buf: array[0..3] of Integer;
  v: Integer; ok: Boolean;
  i: Integer;
begin
  D := FVecDeque; D.Clear; D.ReserveExact(8);
  // 构造 wrap 并增长
  for i:=1 to 8 do D.PushBack(i);
  for i:=1 to 3 do Ignore(IntToStr(D.PopFront)); // [4..8]
  for i:=20 to 35 do D.PushBack(i); // 触发扩容
  // 构建 Baseline
  SetLength(Baseline, D.GetCount);
  if Length(Baseline)>0 then D.Read(0, @Baseline[0], Length(Baseline));

  // TryGet 首尾
  ok := D.TryGet(0, v); AssertTrue(ok); AssertEquals(Baseline[0], v);
  ok := D.TryGet(D.GetCount-1, v); AssertTrue(ok); AssertEquals(Baseline[High(Baseline)], v);

  // TryPeekCopy 取后端4个
  ok := D.TryPeekCopy(@Buf[0], 4); AssertTrue(ok);
  AssertEquals(Baseline[High(Baseline)-3], Buf[0]);
  AssertEquals(Baseline[High(Baseline)-2], Buf[1]);
  AssertEquals(Baseline[High(Baseline)-1], Buf[2]);
  AssertEquals(Baseline[High(Baseline)],   Buf[3]);

  // TryRemove 中间
  ok := D.TryRemove(2, v); AssertTrue(ok);
  AssertEquals(Baseline[2], v);
  Delete(Baseline, 2, 1);

  // 最终一致性
  SetLength(Tmp, D.GetCount); if Length(Tmp)>0 then D.Read(0, @Tmp[0], Length(Tmp));
  AssertEquals(Length(Baseline), Length(Tmp));
  for i:=0 to High(Tmp) do AssertEquals(Baseline[i], Tmp[i]);
end;

procedure TTestCase_VecDeque.Test_Random_MixedOps_Steps_Small;
var
  D: specialize TVecDeque<Integer>;
  Baseline, Tmp, Small: array of Integer;
  Seed: QWord;
  N, i, op, pos, cnt, v: Integer;
begin
  D := FVecDeque; D.Clear;
  SetLength(Baseline, 0);
  Seed := 987654321; RandSeed := Seed; N := 1500;
  for i := 1 to N do
  begin
    op := Random(7);
    case op of
      0: begin // PushBack
           v := Random(10000);
           D.PushBack(v);
           SetLength(Baseline, Length(Baseline)+1);
           Baseline[High(Baseline)] := v;
         end;
      1: begin // PushFront
           v := Random(10000);
           D.PushFront(v);
           Insert(v, Baseline, 0);
         end;
      2: if D.GetCount > 0 then begin // PopBack
           Ignore(IntToStr(D.PopBack));
           if Length(Baseline) > 0 then SetLength(Baseline, Length(Baseline)-1);
         end;
      3: if D.GetCount > 0 then begin // PopFront
           Ignore(IntToStr(D.PopFront));
           if Length(Baseline) > 0 then Delete(Baseline, 0, 1);
         end;
      4: begin // Insert small array at random position
           if D.GetCount = 0 then pos := 0 else pos := Random(LongInt(D.GetCount+1));
           SetLength(Small, 2); Small[0] := 1111; Small[1] := 2222;
           D.Insert(pos, Small);
           Insert(1111, Baseline, pos);
           Insert(2222, Baseline, pos+1);
         end;
      5: begin // Write small chunk at random index (may extend)
           if D.GetCount = 0 then pos := 0 else pos := Random(LongInt(D.GetCount));
           cnt := 2 + (Random(2)); // 2..3
           SetLength(Small, cnt);
           for v := 0 to cnt-1 do Small[v] := 7000 + v;
           D.Write(pos, Small);
           if pos + cnt > Length(Baseline) then SetLength(Baseline, pos + cnt);
           for v := 0 to cnt-1 do Baseline[pos+v] := Small[v];
         end;
      6: if D.GetCount > 0 then begin // Remove one at random position
           pos := Random(LongInt(D.GetCount));
           Ignore(IntToStr(D.Remove(pos)));
           if (pos >= 0) and (pos < Length(Baseline)) then Delete(Baseline, pos, 1);
         end;
    end;

    // checkpoint every 200 steps
    if (i mod 200) = 0 then
    begin
      SetLength(Tmp, D.GetCount);
      if Length(Tmp) > 0 then D.Read(0, @Tmp[0], Length(Tmp));
      AssertEquals(Length(Baseline), Length(Tmp));
      for v := 0 to High(Tmp) do AssertEquals(Baseline[v], Tmp[v]);
    end;
  end;

  // final compare
  SetLength(Tmp, D.GetCount);
  if Length(Tmp) > 0 then D.Read(0, @Tmp[0], Length(Tmp));
  AssertEquals(Length(Baseline), Length(Tmp));
  for v := 0 to High(Tmp) do AssertEquals(Baseline[v], Tmp[v]);
end;

procedure TTestCase_VecDeque.Test_Capacity_Boundaries_Small;
var
  D: specialize TVecDeque<Integer>;
  capBefore, capAfter: SizeUInt;
  i: Integer;
begin
  D := FVecDeque; D.Clear;
  D.ReserveExact(8); AssertTrue(D.GetCapacity >= 8); AssertEquals(0, D.GetCount);
  for i := 1 to 6 do D.PushBack(i);
  capBefore := D.GetCapacity;
  D.Reserve(4); AssertTrue(D.GetCapacity >= D.GetCount + 4); AssertEquals(6, D.GetCount);
  D.ReserveExact(32); AssertTrue(D.GetCapacity >= 32); AssertEquals(6, D.GetCount);
  capAfter := D.GetCapacity; AssertTrue(capAfter >= capBefore);
  // ShrinkToFit should not drop below Count and should be <= current capacity
  D.ShrinkToFit; AssertTrue(D.GetCapacity >= D.GetCount); AssertTrue(D.GetCapacity <= capAfter);
end;


  // Temporary minimal smoke suite to isolate init crash
  type TTestCase_VecDeque_Smoke = class(TTestCase)
  published
    procedure Test_Smoke_Empty;
  end;

  procedure TTestCase_VecDeque_Smoke.Test_Smoke_Empty;
  begin
    // no-op
    AssertTrue(True);
  end;

initialization
  // Temporarily only register the smoke suite for isolation
  RegisterTest(TTestCase_VecDeque);

  RegisterTest(TTestCase_VecDeque_Smoke);

end.
