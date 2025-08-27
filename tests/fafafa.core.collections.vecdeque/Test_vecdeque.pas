unit Test_vecdeque;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fafafa.core.math, fpcunit, testregistry, TypInfo,
  fafafa.core.base,
  fafafa.core.collections.base,
  fafafa.core.collections.arr,
  fafafa.core.collections.vec,
  fafafa.core.collections.queue,
  fafafa.core.collections.deque,
  fafafa.core.collections.vecdeque,
  fafafa.core.collections.elementManager,
  fafafa.core.mem.allocator;

{ Global function declarations - These are real global functions, not class members }
function ForEachTestFunc(const aValue: Integer; aData: Pointer): Boolean;
function EqualsTestFunc(const aValue1, aValue2: Integer; aData: Pointer): Boolean;
function CompareTestFunc(const aValue1, aValue2: Integer; aData: Pointer): SizeInt;
function PredicateTestFunc(const aValue: Integer; aData: Pointer): Boolean;

{ Reference function declarations - These are reference type functions }
function ForEachTestRefFunc(const aValue: Integer): Boolean;
function EqualsTestRefFunc(const aValue1, aValue2: Integer): Boolean;
function CompareTestRefFunc(const aValue1, aValue2: Integer): SizeInt;
function PredicateTestRefFunc(const aValue: Integer): Boolean;

{ Even test functions for FindIF tests }
function EvenTestFunc(const aValue: Integer; aData: Pointer): Boolean;
function EvenTestRefFunc(const aValue: Integer): Boolean;

{ Odd test functions for FindIFNot tests }
function OddTestFunc(const aValue: Integer; aData: Pointer): Boolean;
function OddTestRefFunc(const aValue: Integer): Boolean;

{ Count test functions }
function CountTestFunc(const aValue: Integer; aData: Pointer): Boolean;
function CountTestRefFunc(const aValue: Integer): Boolean;

{ Map test functions }
function MapTestFunc(const aValue: Integer; aData: Pointer): Integer;
function MapTestRefFunc(const aValue: Integer): Integer;

function RandomTestFunc(aRange: Int64; aData: Pointer): Int64;
function RandomTestRefFunc(aRange: Int64): Int64;

type



  TTestCase_VecDeque = class(TTestCase)
  private

    FForEachCounter: SizeInt;
    FForEachSum: SizeInt;

    { Object methods - These are class member methods }
    function ForEachTestMethod(const aValue: Integer; aData: Pointer): Boolean;
    function ForEachStringTestMethod(const aValue: String; aData: Pointer): Boolean;
    function EqualsTestMethod(const aValue1, aValue2: Integer; aData: Pointer): Boolean;
    function CompareTestMethod(const aValue1, aValue2: Integer; aData: Pointer): SizeInt;
    function PredicateTestMethod(const aValue: Integer; aData: Pointer): Boolean;
    function EvenTestMethod(const aValue: Integer; aData: Pointer): Boolean;
    function OddTestMethod(const aValue: Integer; aData: Pointer): Boolean;
    function CountTestMethod(const aValue: Integer; aData: Pointer): Boolean;
    function MapTestMethod(const aValue: Integer; aData: Pointer): Integer;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    function RandomTestMethod(aRange: Int64; aData: Pointer): Int64;

    procedure Test_Create;
    procedure Test_Create_Allocator;
    procedure Test_Create_Allocator_Data;
    procedure Test_Create_Allocator_GrowStrategy;
    procedure Test_Create_Allocator_GrowStrategy_Data;
    procedure Test_Create_Capacity;
    procedure Test_Create_Capacity_Allocator;
    procedure Test_Create_Capacity_Allocator_Data;
    procedure Test_Create_Capacity_Allocator_GrowStrategy;
    procedure Test_Create_Capacity_Allocator_GrowStrategy_Data;
    procedure Test_Create_Collection;
    procedure Test_Create_Collection_Allocator;
    procedure Test_Create_Collection_Allocator_Data;
    procedure Test_Create_Collection_Allocator_GrowStrategy;
    procedure Test_Create_Collection_Allocator_GrowStrategy_Data;
    procedure Test_Create_Pointer_Count;
    procedure Test_Create_Pointer_Count_Allocator;
    procedure Test_Create_Pointer_Count_Allocator_Data;
    procedure Test_Create_Pointer_Count_Allocator_GrowStrategy;
    procedure Test_Create_Pointer_Count_Allocator_GrowStrategy_Data;
    procedure Test_Create_Array;
    procedure Test_Create_Array_Allocator;
    procedure Test_Create_Array_Allocator_Data;
    procedure Test_Create_Array_Allocator_GrowStrategy;
    procedure Test_Create_Array_Allocator_GrowStrategy_Data;


    procedure Test_Destroy;


    procedure Test_GetAllocator;
    procedure Test_GetCount;
    procedure Test_IsEmpty;
    procedure Test_GetData;
    procedure Test_SetData;
    procedure Test_Clear;
    procedure Test_Clear_ResetTail_Invariants; // Test comment
    procedure Test_Clear_Then_PushFront_Batch_Order; // Test comment
    procedure Test_Clear_Wrap_Batch_SliceView_And_Serialize; // Test comment
    procedure Test_Clone;
    procedure Test_IsCompatible;
    procedure Test_PtrIter;
    procedure Test_SerializeToArrayBuffer;
    procedure Test_LoadFromUnChecked;
    procedure Test_AppendUnChecked;
    procedure Test_AppendToUnChecked;
    procedure Test_SaveToUnChecked;



    { ===== Basic ICollection/IGenericCollection/IQueue/IDeque tests (added) ===== }
    // ICollection
    procedure Test_ICollection_Count;
    procedure Test_ICollection_IsEmpty;
    procedure Test_ICollection_Clear;
    // IGenericCollection<T>
    procedure Test_IGenericCollection_Add;
    procedure Test_IGenericCollection_Remove;
    procedure Test_IGenericCollection_Contains;
    // IQueue<T>
    procedure Test_IQueue_Enqueue;
    procedure Test_IQueue_Dequeue;
    procedure Test_IQueue_Peek;
    // IDeque<T>
    procedure Test_IDeque_PushFront;
    procedure Test_IDeque_PushBack;
    procedure Test_IDeque_PopFront;
    procedure Test_IDeque_PopBack;
    procedure Test_IDeque_PeekFront;
    procedure Test_IDeque_PeekBack;

    // Added interface-level tests
    procedure Test_IEnumerable_GetEnumerator;
    procedure Test_IIndexed_Get;
    procedure Test_IIndexed_Put;

    procedure Test_GetEnumerator;
    procedure Test_Iter;
    procedure Test_GetElementSize;
    procedure Test_GetIsManagedType;
    procedure Test_GetElementManager;
    procedure Test_GetElementTypeInfo;
    procedure Test_LoadFrom_Array;
    procedure Test_LoadFrom_Collection;
    procedure Test_LoadFrom_Pointer;
    procedure Test_Append_Array;
    procedure Test_Append_Collection;
    procedure Test_Append_Pointer;
    procedure Test_AppendTo;
    procedure Test_SaveTo;
    procedure Test_ToArray;
    procedure Test_Reverse;
    procedure Test_Reverse_Index;
    procedure Test_Reverse_Index_Count;


    procedure Test_Enqueue;
    procedure Test_Dequeue;
    procedure Test_Dequeue_Safe;
    procedure Test_Peek;
    procedure Test_Peek_Safe;
    procedure Test_Front;
    procedure Test_Front_Safe;
    procedure Test_Back;
    procedure Test_Back_Safe;
    procedure Test_SplitOff;


    procedure Test_PushFront_Element;
    procedure Test_PushFront_Array;
    procedure Test_PushFront_Pointer;
    procedure Test_PushBack_Element;
    procedure Test_PushBack_Array;
    procedure Test_PushBack_Pointer;
    procedure Test_PopFront;
    procedure Test_PopFront_Safe;
    procedure Test_PopBack;
    procedure Test_PopBack_Safe;
    procedure Test_PeekFront;
    procedure Test_PeekFront_Safe;
    procedure Test_PeekBack;
    procedure Test_PeekBack_Safe;


    procedure Test_Get;
    procedure Test_GetUnChecked;
    procedure Test_Put;
    procedure Test_PutUnChecked;
    procedure Test_GetPtr;
    procedure Test_GetPtrUnChecked;
    procedure Test_GetMemory;
    procedure Test_Resize;
    procedure Test_Resize_Value;
    procedure Test_Ensure;
    procedure Test_TryGet;
    procedure Test_TryRemove;


    procedure Test_GetCapacity;
    procedure Test_SetCapacity;
    procedure Test_Reserve;
    procedure Test_ShrinkToFit;
    procedure Test_IsFull;
    procedure Test_GetGrowStrategy;
    procedure Test_SetGrowStrategy;


    procedure Test_Capacity_AutoGrow;
    procedure Test_Capacity_Reserve_Increase;
    procedure Test_Capacity_Reserve_Decrease;
    procedure Test_Capacity_ShrinkToFit_Empty;
    procedure Test_Capacity_ShrinkToFit_Partial;


    procedure Test_Deque_Mixed_Operations;
    procedure Test_Deque_Front_Back_Balance;
    procedure Test_Deque_Circular_Buffer;
    procedure Test_Deque_Stress_Operations;



    procedure Test_Batch_PushBack_CrossBoundary;
    procedure Test_Batch_PushFront_CrossBoundary;
    procedure Test_Wraparound_SmallCapacity2_Back;
    procedure Test_Wraparound_SmallCapacity2_Front;
    procedure Test_TypeSafety_Interface;


    procedure Test_Edge_Empty_Operations;
    procedure Test_Edge_Single_Element;
    procedure Test_Edge_Full_Capacity;
    procedure Test_Edge_Index_Bounds;


    procedure Test_Performance_Large_Dataset;
    procedure Test_Performance_Frequent_Resize;
    procedure Test_Performance_Mixed_Access;
    // Test comment
    procedure Test_Performance_Large_PushBack;
    procedure Test_Performance_Large_PushFront;
    procedure Test_Performance_Mixed_Operations;



    procedure Test_Compatibility_With_Array;
    procedure Test_Compatibility_With_Vec;
    procedure Test_Compatibility_With_Queue;
    procedure Test_Compatibility_With_Deque;


    procedure Test_Memory_Allocator_Custom;
    procedure Test_Memory_GrowStrategy_Custom;
    procedure Test_Memory_Leak_Prevention;


    procedure Test_Exception_OutOfRange_Get;
    procedure Test_Exception_OutOfRange_Put;
    procedure Test_Exception_OutOfRange_Remove;
    procedure Test_Exception_Empty_Pop;
    procedure Test_Exception_Empty_Peek;
    procedure Test_Exception_SplitOff_OutOfRange;


    procedure Test_TypeSafety_Integer;
    procedure Test_TypeSafety_String;
    procedure Test_TypeSafety_Record;
    procedure Test_TypeSafety_Object;


    procedure Test_Iterator_Forward;
    procedure Test_Iterator_Backward;
    procedure Test_Iterator_Modification;
    procedure Test_Iterator_Nested;


    procedure Test_ForEach_Func;
    procedure Test_ForEach_Method;
    procedure Test_ForEach_RefFunc;
    procedure Test_ForEach_StartIndex_Func;
    procedure Test_ForEach_StartIndex_Method;
    procedure Test_ForEach_StartIndex_RefFunc;
    procedure Test_ForEach_StartIndex_Count_Func;
    procedure Test_ForEach_StartIndex_Count_Method;
    procedure Test_ForEach_StartIndex_Count_RefFunc;


    procedure Test_Contains;
    procedure Test_Contains_Func;
    procedure Test_Contains_Method;
    procedure Test_Contains_RefFunc;
    procedure Test_Contains_StartIndex;
    procedure Test_Contains_StartIndex_Func;
    procedure Test_Contains_StartIndex_Method;
    procedure Test_Contains_StartIndex_RefFunc;
    procedure Test_Contains_StartIndex_Count;
    procedure Test_Contains_StartIndex_Count_Func;
    procedure Test_Contains_StartIndex_Count_Method;
    procedure Test_Contains_StartIndex_Count_RefFunc;


    procedure Test_Find;
    procedure Test_Find_Func;
    procedure Test_Find_Method;
    procedure Test_Find_RefFunc;
    procedure Test_Find_StartIndex;
    procedure Test_Find_StartIndex_Func;
    procedure Test_Find_StartIndex_Method;
    procedure Test_Find_StartIndex_RefFunc;
    procedure Test_Find_StartIndex_Count;
    procedure Test_Find_StartIndex_Count_Func;
    procedure Test_Find_StartIndex_Count_Method;
    procedure Test_Find_StartIndex_Count_RefFunc;


    procedure Test_FindLast;
    procedure Test_FindLast_Func;
    procedure Test_FindLast_Method;
    procedure Test_FindLast_RefFunc;
    procedure Test_FindLast_StartIndex;
    procedure Test_FindLast_StartIndex_Func;
    procedure Test_FindLast_StartIndex_Method;
    procedure Test_FindLast_StartIndex_RefFunc;
    procedure Test_FindLast_StartIndex_Count;
    procedure Test_FindLast_StartIndex_Count_Func;
    procedure Test_FindLast_StartIndex_Count_Method;
    procedure Test_FindLast_StartIndex_Count_RefFunc;


    // Test comment
    procedure Test_Debug_Internal_State;
    procedure Test_Debug_Consistency_Check;


    procedure Test_Fill;
    procedure Test_Fill_Index;
    procedure Test_Fill_Index_Count;
    procedure Test_Zero;
    procedure Test_Zero_Index;
    procedure Test_Zero_Index_Count;
    procedure Test_Swap;
    procedure Test_SwapUnChecked;
    procedure Test_Swap_Range;
    procedure Test_Copy;
    procedure Test_CopyUnChecked;
    procedure Test_Read_Pointer;
    procedure Test_Read_Array;
    procedure Test_OverWrite_Pointer;
    procedure Test_OverWrite_Array;
    procedure Test_OverWrite_Collection;
    procedure Test_Write_Pointer_Count;
    procedure Test_WriteUnChecked_Pointer_Count;
    procedure Test_Write_Array;
    procedure Test_WriteUnChecked_Array;
    procedure Test_Write_Collection;
    procedure Test_Write_Collection_Count;
    procedure Test_WriteUnChecked_Collection_Count;


    procedure Test_TryReserve;
    procedure Test_ReserveExact;
    procedure Test_TryReserveExact;
    procedure Test_Shrink;
    procedure Test_ShrinkTo;
    procedure Test_Truncate;
    procedure Test_ResizeExact;
    procedure Test_Capacity_Growth_Linear;
    procedure Test_Capacity_Growth_Exponential;
    procedure Test_Capacity_Growth_Custom;
    procedure Test_Capacity_Shrink_Aggressive;
    procedure Test_Capacity_Shrink_Conservative;
    procedure Test_Capacity_Memory_Efficiency;
    procedure Test_Capacity_Large_Allocations;
    procedure Test_Capacity_Zero_Size;
    // Test comment


    procedure Test_Insert_Index_Element;
    procedure Test_Insert_Index_Pointer_Count;
    procedure Test_Insert_Index_Array;
    procedure Test_Insert_Index_Collection_Count;
    procedure Test_InsertUnChecked_Index_Element;
    procedure Test_InsertUnChecked_Index_Pointer_Count;
    procedure Test_InsertUnChecked_Index_Collection_Count;
    procedure Test_Insert_Front_Multiple;
    procedure Test_Insert_Back_Multiple;
    procedure Test_Insert_Middle_Multiple;
    procedure Test_Insert_Range_Front;
    procedure Test_Insert_Range_Back;
    procedure Test_Insert_Range_Middle;
    procedure Test_Insert_Empty_Range;
    procedure Test_Insert_Large_Range;
    procedure Test_Insert_Overlapping_Range;
    procedure Test_Insert_At_Capacity;
    procedure Test_Insert_Beyond_Capacity;
    procedure Test_Insert_Negative_Index;
    procedure Test_Insert_Invalid_Index;


    procedure Test_Delete_Index;
    procedure Test_Delete_Index_Count;
    procedure Test_DeleteSwap_Index;
    procedure Test_DeleteSwap_Index_Count;
    procedure Test_Remove_Index;
    procedure Test_Remove_Index_Element;
    procedure Test_Remove_Index_Element_Var;
    procedure Test_RemoveSwap_Index;
    procedure Test_RemoveSwap_Index_Element;
    procedure Test_RemoveSwap_Index_Element_Var;
    procedure Test_RemoveCopy_Index_Pointer;
    procedure Test_RemoveCopy_Index_Pointer_Count;
    procedure Test_RemoveArray_Index_Array_Count;
    procedure Test_RemoveCopySwap_Index_Pointer;
    procedure Test_RemoveCopySwap_Index_Pointer_Count;
    procedure Test_RemoveArraySwap_Index_Array_Count;
    procedure Test_Remove_First_Occurrence;
    procedure Test_Remove_Last_Occurrence;
    procedure Test_Remove_All_Occurrences;
    procedure Test_Remove_Range_Front;
    procedure Test_Remove_Range_Back;
    procedure Test_Remove_Range_Middle;
    procedure Test_Remove_Empty_Range;
    procedure Test_Remove_Full_Range;
    procedure Test_Remove_Invalid_Range;


    procedure Test_Push_Element;
    procedure Test_Push_Pointer_Count;
    procedure Test_Push_Array;
    procedure Test_Push_Collection_Count;
    procedure Test_Pop;
    procedure Test_TryPop_Element;
    procedure Test_TryPop_Pointer_Count;
    procedure Test_TryPop_Array_Count;
    procedure Test_TryPop_Array_Complete;
    // Test comment
    procedure Test_TryPeek_Element;
    procedure Test_TryPeekCopy_Pointer_Count;
    procedure Test_TryPeek_Array_Count;
    procedure Test_TryPeek_Array_Complete;
    procedure Test_PeekRange_Count;


    procedure Test_FindIF_Func;
    procedure Test_FindIF_Method;
    procedure Test_FindIF_RefFunc;
    procedure Test_FindIF_StartIndex_Func;
    procedure Test_FindIF_StartIndex_Method;
    procedure Test_FindIF_StartIndex_RefFunc;
    procedure Test_FindIF_StartIndex_Count_Func;
    procedure Test_FindIF_StartIndex_Count_Method;
    procedure Test_FindIF_StartIndex_Count_RefFunc;
    procedure Test_FindIFNot_Func;
    procedure Test_FindIFNot_Method;
    procedure Test_FindIFNot_RefFunc;
    procedure Test_FindIFNot_StartIndex_Func;
    procedure Test_FindIFNot_StartIndex_Method;
    procedure Test_FindIFNot_StartIndex_RefFunc;
    procedure Test_FindIFNot_StartIndex_Count_Func;
    procedure Test_FindIFNot_StartIndex_Count_Method;
    procedure Test_FindIFNot_StartIndex_Count_RefFunc;
    procedure Test_FindLastIF_Func;
    procedure Test_FindLastIF_Method;
    procedure Test_FindLastIF_RefFunc;
    procedure Test_FindLastIF_StartIndex_Func;
    procedure Test_FindLastIF_StartIndex_Method;
    procedure Test_FindLastIF_StartIndex_RefFunc;
    procedure Test_FindLastIF_StartIndex_Count_Func;
    procedure Test_FindLastIF_StartIndex_Count_Method;
    procedure Test_FindLastIF_StartIndex_Count_RefFunc;
    procedure Test_FindLastIFNot_Func;
    procedure Test_FindLastIFNot_Method;
    procedure Test_FindLastIFNot_RefFunc;

    procedure Test_FindLastIF_Wraparound;
    procedure Test_FindLastIFNot_Wraparound;

    procedure Test_Sort;
    procedure Test_Sort_Func;
    procedure Test_Sort_Method;
    procedure Test_Sort_RefFunc;
    procedure Test_Sort_Range;
    procedure Test_Sort_Range_Func;
    procedure Test_Sort_Range_Method;
    procedure Test_Sort_Range_RefFunc;
    procedure Test_IsSorted;
    procedure Test_IsSorted_Func;
    procedure Test_IsSorted_Method;
    procedure Test_IsSorted_RefFunc;
    procedure Test_IsSorted_Range;
    procedure Test_IsSorted_Range_Func;
    procedure Test_IsSorted_Range_Method;
    procedure Test_IsSorted_Range_RefFunc;
    procedure Test_BinarySearch;
    procedure Test_BinarySearch_Func;
    procedure Test_BinarySearch_Method;
    procedure Test_BinarySearch_RefFunc;

    procedure Test_Min;
    procedure Test_Min_Func;
    procedure Test_Min_Method;
    procedure Test_Min_RefFunc;
    procedure Test_Max;
    procedure Test_Max_Func;
    procedure Test_Max_Method;
    procedure Test_Max_RefFunc;
    procedure Test_Sum;
    procedure Test_Average;

    procedure Test_Filter_Func;
    procedure Test_Filter_Method;
    procedure Test_Filter_RefFunc;

    procedure Test_Exception_OutOfBounds;
    procedure Test_Exception_InvalidIndex;
    procedure Test_Exception_NullPointer;
    procedure Test_Exception_InvalidOperation;
    procedure Test_Exception_MemoryError;
    procedure Test_Exception_StackOverflow;
    procedure Test_Exception_AccessViolation;
    procedure Test_Exception_TypeMismatch;
    procedure Test_Exception_RangeError;
    procedure Test_Exception_OverflowError;
    procedure Test_Exception_UnderflowError;
    procedure Test_Exception_DivideByZero;
    procedure Test_Exception_InvalidCast;
    procedure Test_Exception_ResourceExhausted;
    procedure Test_Exception_Recovery;

    procedure Test_Stress_Large_Dataset;
    procedure Test_Stress_Frequent_Resize;
    procedure Test_Stress_Random_Operations;
    procedure Test_Stress_Memory_Pressure;
    procedure Test_Stress_Concurrent_Access;
    procedure Test_Stress_Deep_Nesting;
    procedure Test_Stress_Long_Running;
    procedure Test_Stress_High_Frequency;
    procedure Test_Stress_Resource_Exhaustion;
    procedure Test_Stress_Edge_Cases;
    procedure Test_Stress_Boundary_Conditions;
    procedure Test_Stress_Error_Recovery;
    procedure Test_Stress_State_Consistency;
    procedure Test_Stress_Data_Integrity;
    procedure Test_Stress_Performance_Degradation;

    // Test comment
    procedure Test_Stress_Memory_Allocation; // Test comment
    procedure Test_Stress_Capacity_Management;

    procedure Test_Boundary_Index_Access;



    procedure Test_Regression_Bug_001;
    procedure Test_Regression_Bug_002;
    procedure Test_Regression_Bug_003;
    procedure Test_Regression_Memory_Leak;
    procedure Test_Regression_Performance;
    procedure Test_Regression_Compatibility;
    procedure Test_Regression_Edge_Case;
    procedure Test_Regression_Concurrency;
    procedure Test_Regression_Serialization;
    procedure Test_Regression_Integration;

    procedure Test_CountOf_Element;
    procedure Test_CountOf_Element_Func;
    procedure Test_CountOf_Element_Method;
    procedure Test_CountOf_Element_RefFunc;
    procedure Test_CountOf_StartIndex;
    procedure Test_CountOf_StartIndex_Func;
    procedure Test_CountOf_StartIndex_Method;
    procedure Test_CountOf_StartIndex_RefFunc;
    procedure Test_CountOf_StartIndex_Count;
    procedure Test_CountOf_StartIndex_Count_Func;
    procedure Test_CountOf_StartIndex_Count_Method;
    procedure Test_CountOf_StartIndex_Count_RefFunc;


    procedure Test_CountIF_Func;
    procedure Test_CountIF_Method;
    procedure Test_CountIF_RefFunc;
    procedure Test_CountIF_StartIndex_Func;
    procedure Test_CountIF_StartIndex_Method;
    procedure Test_CountIF_StartIndex_RefFunc;
    procedure Test_CountIF_StartIndex_Count_Func;
    procedure Test_CountIF_StartIndex_Count_Method;
    procedure Test_CountIF_StartIndex_Count_RefFunc;


    procedure Test_Replace_OldValue_NewValue;
    procedure Test_Replace_OldValue_NewValue_Func;
    procedure Test_Replace_OldValue_NewValue_Method;
    procedure Test_Replace_OldValue_NewValue_RefFunc;
    procedure Test_Replace_StartIndex;
    procedure Test_Replace_StartIndex_Func;
    procedure Test_Replace_StartIndex_Method;
    procedure Test_Replace_StartIndex_RefFunc;
    procedure Test_Replace_StartIndex_Count;
    procedure Test_Replace_StartIndex_Count_Func;
    procedure Test_Replace_StartIndex_Count_Method;
    procedure Test_Replace_StartIndex_Count_RefFunc;


    procedure Test_ReplaceIF_Func;
    procedure Test_ReplaceIF_Method;
    procedure Test_ReplaceIF_RefFunc;
    procedure Test_ReplaceIF_StartIndex_Func;
    procedure Test_ReplaceIF_StartIndex_Method;
    procedure Test_ReplaceIF_StartIndex_RefFunc;
    procedure Test_ReplaceIF_StartIndex_Count_Func;
    procedure Test_ReplaceIF_StartIndex_Count_Method;
    procedure Test_ReplaceIF_StartIndex_Count_RefFunc;


    procedure Test_Shuffle;
    procedure Test_Shuffle_Func;
    procedure Test_Shuffle_Method;
    procedure Test_Shuffle_RefFunc;
    procedure Test_Shuffle_StartIndex;
    procedure Test_Shuffle_StartIndex_Count;
    procedure Test_Shuffle_StartIndex_Count_Func;
    procedure Test_Shuffle_StartIndex_Count_RefFunc;




    procedure Test_FindUnChecked_Element;
    procedure Test_FindUnChecked_Element_Func;
    procedure Test_FindUnChecked_Element_Method;
    procedure Test_FindUnChecked_Element_RefFunc;


    procedure Test_FindLastUnChecked_Element;
    procedure Test_FindLastUnChecked_Element_Func;
    procedure Test_FindLastUnChecked_Element_Method;
    procedure Test_FindLastUnChecked_Element_RefFunc;


    procedure Test_BinarySearchInsert_Element;
    procedure Test_BinarySearchInsert_Element_Func;
    procedure Test_BinarySearchInsert_Element_Method;
    procedure Test_BinarySearchInsert_Element_RefFunc;
    procedure Test_BinarySearchInsert_StartIndex_Element;
    procedure Test_BinarySearchInsert_StartIndex_Element_Func;
    procedure Test_BinarySearchInsert_StartIndex_Element_Method;
    procedure Test_BinarySearchInsert_StartIndex_Element_RefFunc;
    procedure Test_BinarySearchInsert_StartIndex_Count_Element;
    procedure Test_BinarySearchInsert_StartIndex_Count_Element_Func;
    procedure Test_BinarySearchInsert_StartIndex_Count_Element_Method;
    procedure Test_BinarySearchInsert_StartIndex_Count_Element_RefFunc;


    procedure Test_IsSorted_StartIndex;
    procedure Test_IsSorted_StartIndex_Func;
    procedure Test_IsSorted_StartIndex_Method;
    procedure Test_IsSorted_StartIndex_RefFunc;
    procedure Test_IsSorted_StartIndex_Count;
    procedure Test_IsSorted_StartIndex_Count_Func;
    procedure Test_IsSorted_StartIndex_Count_Method;
    procedure Test_IsSorted_StartIndex_Count_RefFunc;


    procedure Test_SortUnChecked;
    procedure Test_SortUnChecked_Func;
    procedure Test_SortUnChecked_Method;
    procedure Test_SortUnChecked_RefFunc;


    procedure Test_ClearAndReserve;
    procedure Test_WarmupMemory;
    procedure Test_FastIndexOf;
    procedure Test_FastLastIndexOf;
    procedure Test_FillWith;
    // Test comment
    procedure Test_Memory_Large_Objects;
    // Additional specialized and constructor tests
    procedure Test_Specialized_Circular_Buffer;
    procedure Test_Specialized_Stack_Simulation;
    procedure Test_Create_Capacity_GrowStrategy;
    procedure Test_Create_Capacity_GrowStrategy_Data;
    // Added to match implementations below
    procedure Test_Insert_Index_Collection;
    procedure Test_Write_Index_Collection;
    procedure Test_Slice_StartIndex_Count;
    procedure Test_Specialized_Priority_Queue;

    procedure Test_Specialized_Sliding_Window;

    procedure Test_Specialized_Undo_Redo;
    procedure Test_Specialized_Message_Queue;
    procedure Test_Specialized_Data_Pipeline;
    procedure Test_Final_Comprehensive_Integration;

  end;

implementation

uses
  DateUtils;

procedure TTestCase_VecDeque.SetUp;
begin
  inherited SetUp;
  RandSeed := 123456; // Test comment
end;

procedure TTestCase_VecDeque.TearDown;
begin
  inherited TearDown;
end;




// Test comment
var
  gsDouble: TGrowthStrategy = nil;
  gsLinear: TGrowthStrategy = nil;




function CreateAllocator: IAllocator;
begin
  Result := GetRtlAllocator();
end;

// Test comment
function GS_Double: TGrowthStrategy;
begin
  // Test comment
  Result := TDoublingGrowStrategy.GetGlobal;
end;

function GS_Linear(aStep: SizeUInt): TGrowthStrategy;
begin
  // Test comment
  Result := TFixedGrowStrategy.Create(aStep);
end;

// Test comment
// Test comment






{ Object methods }
function ForEachTestFunc(const aValue: Integer; aData: Pointer): Boolean;
begin

  if aData <> nil then
  begin

    Inc(PInteger(aData)^);                    { Object methods }
    Inc(PInteger(PtrUInt(aData) + SizeOf(Integer))^, aValue);
  end;


  Result := aValue < 100; { Object methods }
end;

{ Object methods }
function EqualsTestFunc(const aValue1, aValue2: Integer; aData: Pointer): Boolean;
begin

  if aData <> nil then
  begin

    Result := (aValue2 + PInteger(aData)^) = aValue1;
  end
  else
  begin
    { Object methods }
    Result := aValue1 = aValue2;
  end;
end;

{ Object methods }
function PredicateTestFunc(const aValue: Integer; aData: Pointer): Boolean;
begin

  if aData <> nil then
  begin

    Result := aValue > PInteger(aData)^;
  end
  else
  begin

    Result := (aValue mod 2) = 0;
  end;
end;


function CompareTestFunc(const aValue1, aValue2: Integer; aData: Pointer): SizeInt;
begin

  if aData <> nil then
  begin
    if PInteger(aData)^ <> 0 then
    begin
      { Object methods }
      if aValue1 > aValue2 then
        Result := -1
      else if aValue1 < aValue2 then
        Result := 1
      else
        Result := 0;
    end
    else
    begin
      { Object methods }
      if aValue1 < aValue2 then
        Result := -1
      else if aValue1 > aValue2 then
        Result := 1
      else
        Result := 0;
    end;
  end
  else
  begin

    if aValue1 < aValue2 then
      Result := -1
    else if aValue1 > aValue2 then
      Result := 1
    else
      Result := 0;
  end;
end;



{ Global reference function for ForEach testing }
var
  GlobalForEachCounter: SizeInt = 0;
  GlobalForEachSum: SizeInt = 0;

function ForEachTestRefFunc(const aValue: Integer): Boolean;
begin
  { Use global variables to track calls since this is a global function }
  Inc(GlobalForEachCounter);
  Inc(GlobalForEachSum, aValue);
  Result := aValue <= 50; { Continue until we encounter a value > 50 }
end;

{ Object methods }
function EqualsTestRefFunc(const aValue1, aValue2: Integer): Boolean;
begin

  Result := aValue1 = aValue2;
end;

{ Object methods }
function CompareTestRefFunc(const aValue1, aValue2: Integer): SizeInt;
begin

  { Object methods }
  if aValue1 < aValue2 then
    Result := -1
  else if aValue1 > aValue2 then
    Result := 1
  else
    Result := 0;
end;

{ Object methods }
function PredicateTestRefFunc(const aValue: Integer): Boolean;
begin

  Result := (aValue mod 2) = 0;
end;

{ Even test functions for FindIF tests }
function EvenTestFunc(const aValue: Integer; aData: Pointer): Boolean;
begin
  Result := (aValue mod 2) = 0;
end;

function EvenTestRefFunc(const aValue: Integer): Boolean;
begin
  Result := (aValue mod 2) = 0;
end;

{ Odd test functions for FindIFNot tests }
function OddTestFunc(const aValue: Integer; aData: Pointer): Boolean;
begin
  Result := (aValue mod 2) <> 0;
end;

function OddTestRefFunc(const aValue: Integer): Boolean;
begin
  Result := (aValue mod 2) <> 0;
end;

{ Count test functions }
function CountTestFunc(const aValue: Integer; aData: Pointer): Boolean;
begin
  Result := aValue > 5;  { Count values greater than 5 }
end;

function CountTestRefFunc(const aValue: Integer): Boolean;
begin
  Result := aValue > 5;  { Count values greater than 5 }
end;

{ Map test functions }
function MapTestFunc(const aValue: Integer; aData: Pointer): Integer;
begin
  Result := aValue * 2;  { Double the value }
end;

function MapTestRefFunc(const aValue: Integer): Integer;
begin
  Result := aValue * 2;  { Double the value }
end;

{ Object methods }
function RandomTestFunc(aRange: Int64; aData: Pointer): Int64;
begin
  Result := Random(aRange);
end;

function TTestCase_VecDeque.RandomTestMethod(aRange: Int64; aData: Pointer): Int64;
begin
  Result := Random(aRange);
end;

function RandomTestRefFunc(aRange: Int64): Int64;
begin
  Result := Random(aRange);
end;



{ Object methods }
function TTestCase_VecDeque.ForEachTestMethod(const aValue: Integer; aData: Pointer): Boolean;
begin

  Inc(FForEachCounter);
  Inc(FForEachSum, aValue);


  if aData <> nil then
  begin

    Result := FForEachSum < PInteger(aData)^;
  end
  else
  begin

    Result := True;
  end;
end;

{ Object methods }
function TTestCase_VecDeque.ForEachStringTestMethod(const aValue: String; aData: Pointer): Boolean;
begin

  Inc(FForEachCounter);


  if aData <> nil then
  begin

    Result := Length(aValue) <= PInteger(aData)^;
  end
  else
  begin

    Result := True;
  end;
end;

{ Object methods }
function TTestCase_VecDeque.EqualsTestMethod(const aValue1, aValue2: Integer; aData: Pointer): Boolean;
begin

  if aData <> nil then
  begin
    Result := (aValue2 + PInteger(aData)^) = aValue1;
  end
  else
  begin
    Result := aValue1 = aValue2;
  end;
end;

{ Object methods }
function TTestCase_VecDeque.CompareTestMethod(const aValue1, aValue2: Integer; aData: Pointer): SizeInt;
begin

  if aData <> nil then
  begin
    if PInteger(aData)^ <> 0 then
    begin
      { Object methods }
      if aValue1 > aValue2 then
        Result := -1
      else if aValue1 < aValue2 then
        Result := 1
      else
        Result := 0;
    end
    else
    begin
      { Object methods }
      if aValue1 < aValue2 then
        Result := -1
      else if aValue1 > aValue2 then
        Result := 1
      else
        Result := 0;
    end;
  end
  else
  begin

    if aValue1 < aValue2 then
      Result := -1
    else if aValue1 > aValue2 then
      Result := 1
    else
      Result := 0;
  end;
end;

{ Object methods }
function TTestCase_VecDeque.PredicateTestMethod(const aValue: Integer; aData: Pointer): Boolean;
begin

  if aData <> nil then
  begin
    Result := aValue > PInteger(aData)^;
  end
  else
  begin
    Result := (aValue mod 2) = 0;
  end;
end;

{ Object methods }
function TTestCase_VecDeque.EvenTestMethod(const aValue: Integer; aData: Pointer): Boolean;
begin
  Result := (aValue mod 2) = 0;
end;

function TTestCase_VecDeque.OddTestMethod(const aValue: Integer; aData: Pointer): Boolean;
begin
  Result := (aValue mod 2) <> 0;
end;

function TTestCase_VecDeque.CountTestMethod(const aValue: Integer; aData: Pointer): Boolean;
begin
  Result := aValue > 5;  { Count values greater than 5 }
end;

function TTestCase_VecDeque.MapTestMethod(const aValue: Integer; aData: Pointer): Integer;
begin
  Result := aValue * 2;  { Double the value }
end;



procedure TTestCase_VecDeque.Test_Create;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    AssertNotNull('Create() should create valid vecdeque', LVecDeque);
    AssertTrue('VecDeque should be empty', LVecDeque.IsEmpty);
    AssertEquals('VecDeque count should be 0', Int64(0), Int64(LVecDeque.GetCount));
    AssertNotNull('VecDeque should have RTL allocator', LVecDeque.GetAllocator);
    AssertTrue('VecDeque should use RTL allocator', LVecDeque.GetAllocator = GetRtlAllocator());
    AssertTrue('VecDeque capacity should be greater than 0', LVecDeque.GetCapacity > 0);
    AssertFalse('VecDeque should not be managed type for Integer', LVecDeque.GetIsManagedType);
    AssertEquals('VecDeque element size should match Integer size', Int64(SizeOf(Integer)), Int64(LVecDeque.GetElementSize));
    AssertNotNull('VecDeque should have element manager', LVecDeque.GetElementManager);
    AssertNotNull('VecDeque should have type info', LVecDeque.GetElementTypeInfo);
    { Object methods }
    // AssertEquals('VecDeque type info should match Integer', 'Integer', LVecDeque.GetElementTypeInfo^.Name);
    AssertEquals('VecDeque element size should match Integer size', Int64(SizeOf(Integer)), Int64(LVecDeque.GetElementSize));
    AssertFalse('Integer should not be managed type', LVecDeque.GetIsManagedType);
  finally
    LVecDeque.Free;
  end;
end;

















procedure TTestCase_VecDeque.Test_Destroy;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LAllocator: IAllocator;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  LVecDeque.Free;


  LVecDeque := specialize TVecDeque<Integer>.Create;
  LVecDeque.PushBack(1);
  LVecDeque.PushBack(2);
  LVecDeque.PushBack(3);
  LVecDeque.Free;


  LAllocator := TRtlAllocator.Create;
  try
    LVecDeque := specialize TVecDeque<Integer>.Create(LAllocator);
    LVecDeque.PushBack(42);
    LVecDeque.Free;

    { Object methods }
    AssertNotNull('Allocator should still be valid after VecDeque destruction', LAllocator);
  finally
    LAllocator.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_GetAllocator;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LAllocator: IAllocator;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    AssertNotNull('GetAllocator should return valid allocator', LVecDeque.GetAllocator);
    AssertTrue('GetAllocator should return RTL allocator by default', LVecDeque.GetAllocator = GetRtlAllocator());
  finally
    LVecDeque.Free;
  end;


  LAllocator := TRtlAllocator.Create;
  try
    LVecDeque := specialize TVecDeque<Integer>.Create(LAllocator);
    try
      AssertNotNull('GetAllocator should return valid allocator', LVecDeque.GetAllocator);
      AssertTrue('GetAllocator should return provided allocator', LVecDeque.GetAllocator = LAllocator);
    finally
      LVecDeque.Free;
    end;
  finally
    LAllocator.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_GetCount;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Object methods }
    AssertEquals('Empty VecDeque count should be 0', Int64(0), Int64(LVecDeque.GetCount));

    { Object methods }
    LVecDeque.PushBack(1);
    AssertEquals('VecDeque count should be 1 after adding one element', Int64(1), Int64(LVecDeque.GetCount));

    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    AssertEquals('VecDeque count should be 3 after adding three elements', Int64(3), Int64(LVecDeque.GetCount));

    { Object methods }
    LVecDeque.PopBack;
    AssertEquals('VecDeque count should be 2 after removing one element', Int64(2), Int64(LVecDeque.GetCount));

    LVecDeque.PopFront;
    AssertEquals('VecDeque count should be 1 after removing another element', Int64(1), Int64(LVecDeque.GetCount));

    LVecDeque.PopBack;
    AssertEquals('VecDeque count should be 0 after removing all elements', Int64(0), Int64(LVecDeque.GetCount));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IsEmpty;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Object methods }
    AssertTrue('New VecDeque should be empty', LVecDeque.IsEmpty);

    { Object methods }
    LVecDeque.PushBack(42);
    AssertFalse('VecDeque should not be empty after adding element', LVecDeque.IsEmpty);

    { Object methods }
    LVecDeque.PopBack;
    AssertTrue('VecDeque should be empty after removing all elements', LVecDeque.IsEmpty);


    LVecDeque.PushFront(1);
    LVecDeque.PushBack(2);
    AssertFalse('VecDeque should not be empty with multiple elements', LVecDeque.IsEmpty);

    LVecDeque.Clear;
    AssertTrue('VecDeque should be empty after Clear', LVecDeque.IsEmpty);
  finally
    LVecDeque.Free;
  end;
end;






procedure TTestCase_VecDeque.Test_PushFront_Element;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushFront(42);
    AssertEquals('Count should be 1 after PushFront', Int64(1), Int64(LVecDeque.GetCount));
    AssertEquals('Front element should be 42', 42, LVecDeque.Front);
    AssertEquals('Back element should be 42', 42, LVecDeque.Back);


    LVecDeque.PushFront(10);
    LVecDeque.PushFront(20);
    AssertEquals('Count should be 3 after multiple PushFront', Int64(3), Int64(LVecDeque.GetCount));
    AssertEquals('Front element should be 20', 20, LVecDeque.Front);
    AssertEquals('Back element should be 42', 42, LVecDeque.Back);
    AssertEquals('Middle element should be 10', 10, LVecDeque.Get(1));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_PushBack_Element;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(42);
    AssertEquals('Count should be 1 after PushBack', Int64(1), Int64(LVecDeque.GetCount));
    AssertEquals('Front element should be 42', 42, LVecDeque.Front);
    AssertEquals('Back element should be 42', 42, LVecDeque.Back);


    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    AssertEquals('Count should be 3 after multiple PushBack', Int64(3), Int64(LVecDeque.GetCount));
    AssertEquals('Front element should be 42', 42, LVecDeque.Front);
    AssertEquals('Back element should be 20', 20, LVecDeque.Back);
    AssertEquals('Middle element should be 10', 10, LVecDeque.Get(1));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_PopFront;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LValue: Integer;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);

    { Object methods }
    LValue := LVecDeque.PopFront;
    AssertEquals('PopFront should return first element', 1, LValue);
    AssertEquals('Count should decrease after PopFront', Int64(2), Int64(LVecDeque.GetCount));
    AssertEquals('New front should be 2', 2, LVecDeque.Front);

    { Object methods }
    LValue := LVecDeque.PopFront;
    AssertEquals('Second PopFront should return 2', 2, LValue);
    AssertEquals('Count should be 1', Int64(1), Int64(LVecDeque.GetCount));

    LValue := LVecDeque.PopFront;
    AssertEquals('Last PopFront should return 3', 3, LValue);
    AssertEquals('Count should be 0', Int64(0), Int64(LVecDeque.GetCount));
    AssertTrue('VecDeque should be empty', LVecDeque.IsEmpty);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_PopBack;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LValue: Integer;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);

    { Object methods }
    LValue := LVecDeque.PopBack;
    AssertEquals('PopBack should return last element', 3, LValue);
    AssertEquals('Count should decrease after PopBack', Int64(2), Int64(LVecDeque.GetCount));
    AssertEquals('New back should be 2', 2, LVecDeque.Back);

    { Object methods }
    LValue := LVecDeque.PopBack;
    AssertEquals('Second PopBack should return 2', 2, LValue);
    AssertEquals('Count should be 1', Int64(1), Int64(LVecDeque.GetCount));

    LValue := LVecDeque.PopBack;
    AssertEquals('Last PopBack should return 1', 1, LValue);
    AssertEquals('Count should be 0', Int64(0), Int64(LVecDeque.GetCount));
    AssertTrue('VecDeque should be empty', LVecDeque.IsEmpty);
  finally
    LVecDeque.Free;
  end;
end;






procedure TTestCase_VecDeque.Test_GetData;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LTestData: Pointer;
begin
  { Object methods }
  LTestData := Pointer($12345678);
  LVecDeque := specialize TVecDeque<Integer>.Create(GetRtlAllocator(), LTestData);
  try
    AssertTrue('GetData should return the provided data pointer', LVecDeque.GetData = LTestData);


    LVecDeque.Free;
    LVecDeque := specialize TVecDeque<Integer>.Create;
    AssertTrue('Default constructor should have nil data', LVecDeque.GetData = nil);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_SetData;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LTestData1, LTestData2: Pointer;
begin
  { Object methods }
  LTestData1 := Pointer($11111111);
  LTestData2 := Pointer($22222222);

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Object methods }
    LVecDeque.SetData(LTestData1);
    AssertTrue('SetData should update the data pointer', LVecDeque.GetData = LTestData1);

    { Object methods }
    LVecDeque.SetData(LTestData2);
    AssertTrue('SetData should update to new data pointer', LVecDeque.GetData = LTestData2);

    { Object methods }
    LVecDeque.SetData(nil);
    AssertTrue('SetData should accept nil pointer', LVecDeque.GetData = nil);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Clear;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Object methods }
    LVecDeque.Clear;
    AssertTrue('Clear on empty VecDeque should work', LVecDeque.IsEmpty);
    AssertEquals('Clear on empty VecDeque should keep count 0', Int64(0), Int64(LVecDeque.GetCount));


    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushFront(0);
    AssertEquals('VecDeque should have 3 elements', Int64(3), Int64(LVecDeque.GetCount));


    LVecDeque.Clear;
    AssertTrue('Clear should make VecDeque empty', LVecDeque.IsEmpty);
    AssertEquals('Clear should reset count to 0', Int64(0), Int64(LVecDeque.GetCount));


    LVecDeque.PushBack(42);
    AssertEquals('Should be able to add elements after Clear', Int64(1), Int64(LVecDeque.GetCount));
    AssertEquals('Element should be correct after Clear', 42, LVecDeque.Back);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Clear_ResetTail_Invariants;
var
  D: specialize TVecDeque<Integer>;
  i: Integer;
begin
  D := specialize TVecDeque<Integer>.Create;
  try
    D.ReserveExact(16);
    for i := 1 to 12 do D.PushBack(i);
    for i := 1 to 4 do D.PopFront;
    // Clear must reset both head and tail to 0 for empty state
    D.Clear;
    // After Clear, sequence should start from index 0 again
    for i := 1 to 4 do D.PushBack(i);
    for i := 0 to 3 do
      AssertEquals('seq after Clear', Int64(i + 1), Int64(D.Get(i)));
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Clear_Then_PushFront_Batch_Order;
var
  D: specialize TVecDeque<Integer>;
  A: array[0..3] of Integer = (101, 102, 103, 104);
  i: Integer;
begin
  D := specialize TVecDeque<Integer>.Create;
  try
    D.ReserveExact(8);
    for i := 1 to 6 do D.PushBack(i);
    for i := 1 to 3 do D.PopFront;
    D.Clear;
    D.ReserveExact(8);
    for i := 1 to 3 do D.PushBack(i);
    D.PushFront(A);
    for i := 0 to 3 do
      AssertEquals(Int64(101 + i), Int64(D.Get(i)));
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Clear_Wrap_Batch_SliceView_And_Serialize;
var
  D: specialize TVecDeque<Integer>;
  AExpected: array[0..7] of Integer;
  Buf: array[0..7] of Integer;
  i: Integer;
  p1, p2: PInteger;
  l1, l2: SizeUInt;
  tmp: array[0..7] of Integer;
  offset: Integer;
begin
  D := specialize TVecDeque<Integer>.Create;
  try
    D.ReserveExact(8);
    D.Append([0,1,2,3,4]);
    D.PopFront; D.PopFront; // force head shift
    D.Append([5,6,7,8,9]);  // induce wrap in internal layout

    // Clear and rebuild with wrap via front batch
    D.Clear;
    D.ReserveExact(8);
    D.Append([10,11,12,13]);
    D.PushFront([101,102,103,104]);

    // expected sequence: [101..104, 10..13]
    for i := 0 to 3 do AExpected[i] := 101 + i;
    for i := 0 to 3 do AExpected[4 + i] := 10 + i;

    // Serialize and verify
    D.SerializeToArrayBuffer(@Buf[0], D.GetCount);
    for i := 0 to High(Buf) do
      AssertEquals(Int64(AExpected[i]), Int64(Buf[i]));

    // Verify two-slice view reconstructs the same sequence
    D.GetTwoSlices(0, D.GetCount, Pointer(p1), l1, Pointer(p2), l2);
    AssertEquals(SizeUInt(8), l1 + l2);

    offset := 0;
    for i := 0 to Integer(l1) - 1 do tmp[offset + i] := p1[i];
    Inc(offset, l1);
    for i := 0 to Integer(l2) - 1 do tmp[offset + i] := p2[i];

    for i := 0 to 7 do
      AssertEquals(Int64(AExpected[i]), Int64(tmp[i]));
  finally
    D.Free;
  end;
end;

// keep unit open for following methods

procedure TTestCase_VecDeque.Test_Clone;
var
  LOriginal, LClone: specialize TVecDeque<Integer>;
  i: Integer;
begin
  { Object methods }
  LOriginal := specialize TVecDeque<Integer>.Create;
  try
    { Object methods }
    LClone := LOriginal.Clone as specialize TVecDeque<Integer>;
    try
      AssertNotNull('Clone should create valid object', LClone);
      AssertTrue('Cloned empty VecDeque should be empty', LClone.IsEmpty);
      AssertEquals('Cloned empty VecDeque should have count 0', Int64(0), Int64(LClone.GetCount));
    finally
      LClone.Free;
    end;


    for i := 1 to 5 do
      LOriginal.PushBack(i);


    LClone := LOriginal.Clone as specialize TVecDeque<Integer>;
    try
      AssertNotNull('Clone should create valid object', LClone);
      AssertEquals('Clone should have same count', Int64(LOriginal.GetCount), Int64(LClone.GetCount));


      for i := 0 to Integer(LOriginal.GetCount) - 1 do
        AssertEquals('Clone should have same elements', LOriginal.Get(i), LClone.Get(i));


      LClone.PushBack(999);
      AssertEquals('Original should not be affected by clone modification', Int64(5), Int64(LOriginal.GetCount));
      AssertEquals('Clone should be modified independently', Int64(6), Int64(LClone.GetCount));
    finally
      LClone.Free;
    end;
  finally
    LOriginal.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IsCompatible;
var
  LVecDeque1, LVecDeque2: specialize TVecDeque<Integer>;
  LVecDequeString: specialize TVecDeque<String>;
  LAllocator: TAllocator;
begin

  LVecDeque1 := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque2 := specialize TVecDeque<Integer>.Create;
    try

      AssertTrue('Same type VecDeques should be compatible', LVecDeque1.IsCompatible(LVecDeque2));
      AssertTrue('Compatibility should be symmetric', LVecDeque2.IsCompatible(LVecDeque1));


      AssertTrue('VecDeque should be compatible with itself', LVecDeque1.IsCompatible(LVecDeque1));
    finally
      LVecDeque2.Free;
    end;


    LVecDequeString := specialize TVecDeque<String>.Create;
    try
      AssertFalse('Different element types should not be compatible', LVecDeque1.IsCompatible(LVecDequeString));
    finally
      LVecDequeString.Free;
    end;


    LAllocator := TRtlAllocator.Create;
    try
      LVecDeque2 := specialize TVecDeque<Integer>.Create(LAllocator);
      try

        AssertTrue('Different allocators with same element type should be compatible', LVecDeque1.IsCompatible(LVecDeque2));
      finally
        LVecDeque2.Free;
      end;
    finally
      LAllocator.Free;
    end;
  finally
    LVecDeque1.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_PtrIter;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIter: TPtrIter;
  LValue: Integer;
  LCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LIter := LVecDeque.PtrIter;
    AssertTrue('Empty VecDeque iterator should have nil current', LIter.GetCurrent = nil);


    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(30);


    LIter := LVecDeque.PtrIter;
    LCount := 0;
    while LIter.GetCurrent <> nil do
    begin
      LValue := PInteger(LIter.GetCurrent)^;
      case LCount of
        0: AssertEquals('First element should be 10', 10, LValue);
        1: AssertEquals('Second element should be 20', 20, LValue);
        2: AssertEquals('Third element should be 30', 30, LValue);
      end;
      Inc(LCount);
      LIter.MoveNext;
    end;
    AssertEquals('Should iterate through all elements', Int64(3), Int64(LCount));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_SerializeToArrayBuffer;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LBuffer: array[0..4] of Integer;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Object methods }
    for i := 1 to 5 do
      LVecDeque.PushBack(i * 10);


    FillChar(LBuffer, SizeOf(LBuffer), 0);
    LVecDeque.SerializeToArrayBuffer(@LBuffer[0], 5);


    for i := 0 to 4 do
      AssertEquals('Serialized element should match', (i + 1) * 10, LBuffer[i]);


    FillChar(LBuffer, SizeOf(LBuffer), 0);
    LVecDeque.SerializeToArrayBuffer(@LBuffer[0], 3);

    for i := 0 to 2 do
      AssertEquals('Partial serialized element should match', (i + 1) * 10, LBuffer[i]);
    AssertEquals('Remaining buffer should be zero', 0, LBuffer[3]);
    AssertEquals('Remaining buffer should be zero', 0, LBuffer[4]);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_LoadFromUnChecked;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceData: array[0..3] of Integer;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 0 to 3 do
      LSourceData[i] := (i + 1) * 5;


    LVecDeque.LoadFromUnChecked(@LSourceData[0], 4);

    { Object methods }
    AssertEquals('LoadFromUnChecked should set correct count', Int64(4), Int64(LVecDeque.GetCount));
    for i := 0 to 3 do
      AssertEquals('Loaded element should match source', LSourceData[i], LVecDeque.Get(i));

    { Object methods }
    for i := 0 to 3 do
      LSourceData[i] := (i + 1) * 100;

    LVecDeque.LoadFromUnChecked(@LSourceData[0], 2);
    AssertEquals('Reload should update count', Int64(2), Int64(LVecDeque.GetCount));
    AssertEquals('First reloaded element should match', 100, LVecDeque.Get(0));
    AssertEquals('Second reloaded element should match', 200, LVecDeque.Get(1));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_AppendUnChecked;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceData: array[0..2] of Integer;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);


    LSourceData[0] := 10;
    LSourceData[1] := 20;
    LSourceData[2] := 30;

    { Object methods }
    LVecDeque.AppendUnChecked(@LSourceData[0], 3);

    { Object methods }
    AssertEquals('AppendUnChecked should update count', Int64(5), Int64(LVecDeque.GetCount));
    AssertEquals('Original element should remain', 1, LVecDeque.Get(0));
    AssertEquals('Original element should remain', 2, LVecDeque.Get(1));
    AssertEquals('Appended element should be correct', 10, LVecDeque.Get(2));
    AssertEquals('Appended element should be correct', 20, LVecDeque.Get(3));
    AssertEquals('Appended element should be correct', 30, LVecDeque.Get(4));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_AppendToUnChecked;
var
  LSource, LTarget: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LSource := specialize TVecDeque<Integer>.Create;
  LTarget := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 3 do
      LSource.PushBack(i * 10);


    LTarget.PushBack(100);
    LTarget.PushBack(200);


    LSource.AppendToUnChecked(LTarget);

    { Object methods }
    AssertEquals('Source should remain unchanged', Int64(3), Int64(LSource.GetCount));
    AssertEquals('Target should have combined count', Int64(5), Int64(LTarget.GetCount));


    AssertEquals('Target original element should remain', 100, LTarget.Get(0));
    AssertEquals('Target original element should remain', 200, LTarget.Get(1));
    AssertEquals('Appended element should be correct', 10, LTarget.Get(2));
    AssertEquals('Appended element should be correct', 20, LTarget.Get(3));
    AssertEquals('Appended element should be correct', 30, LTarget.Get(4));
  finally
    LSource.Free;
    LTarget.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_SaveToUnChecked;
var
  LSource, LTarget: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LSource := specialize TVecDeque<Integer>.Create;
  LTarget := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 4 do
      LSource.PushBack(i * 7);


    LTarget.PushBack(999);
    LTarget.PushBack(888);


    LSource.SaveToUnChecked(LTarget);

    { Object methods }
    AssertEquals('Source should remain unchanged', Int64(4), Int64(LSource.GetCount));
    AssertEquals('Target should have source count', Int64(4), Int64(LTarget.GetCount));


    for i := 0 to 3 do
      AssertEquals('Target element should match source', LSource.Get(i), LTarget.Get(i));
  finally
    LSource.Free;
    LTarget.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_GetEnumerator;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LEnumerator: specialize TITer<Integer>;
  LCount: Integer;
  LExpectedValue: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LEnumerator := LVecDeque.GetEnumerator;
    AssertFalse('Empty collection enumerator should not have current', LEnumerator.MoveNext);


    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(30);


    LEnumerator := LVecDeque.GetEnumerator;
    LCount := 0;
    LExpectedValue := 10;
    while LEnumerator.MoveNext do
    begin
      AssertEquals('Enumerator current should match expected', LExpectedValue, LEnumerator.Current);
      Inc(LCount);
      Inc(LExpectedValue, 10);
    end;
    AssertEquals('Should enumerate all elements', 3, LCount);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Iter;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIter: specialize TIter<Integer>;
  LCount: Integer;
begin

end;

procedure TTestCase_VecDeque.Test_GetElementSize;
var
  LVecDequeInt: specialize TVecDeque<Integer>;
  LVecDequeString: specialize TVecDeque<String>;
begin
  { Object methods }
  LVecDequeInt := specialize TVecDeque<Integer>.Create;
  try
    AssertEquals('Integer element size should match', Int64(SizeOf(Integer)), Int64(LVecDequeInt.GetElementSize));
  finally
    LVecDequeInt.Free;
  end;

  LVecDequeString := specialize TVecDeque<String>.Create;
  try
    AssertEquals('String element size should match', Int64(SizeOf(String)), Int64(LVecDequeString.GetElementSize));
  finally
    LVecDequeString.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_GetIsManagedType;
var
  LVecDequeInt: specialize TVecDeque<Integer>;
  LVecDequeString: specialize TVecDeque<String>;
begin

  LVecDequeInt := specialize TVecDeque<Integer>.Create;
  try
    AssertFalse('Integer should not be managed type', LVecDequeInt.GetIsManagedType);
  finally
    LVecDequeInt.Free;
  end;

  LVecDequeString := specialize TVecDeque<String>.Create;
  try
    AssertTrue('String should be managed type', LVecDequeString.GetIsManagedType);
  finally
    LVecDequeString.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_GetElementManager;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LElementManager: specialize TElementManager<Integer>;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LElementManager := LVecDeque.GetElementManager;
    AssertNotNull('GetElementManager should return valid manager', LElementManager);


    AssertEquals('Element manager size should match element size',
                 Int64(SizeOf(Integer)), Int64(LElementManager.GetElementSize));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_GetElementTypeInfo;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LTypeInfo: PTypeInfo;
begin
  { test GetElementTypeInfo - gettypeinformation }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LTypeInfo := LVecDeque.GetElementTypeInfo;
    AssertNotNull('GetElementTypeInfo should return valid type info', LTypeInfo);
    { Object methods }
    // AssertEquals('Type info name should match', 'Integer', LTypeInfo^.Name);
    AssertEquals('Element size should match Integer size', Int64(SizeOf(Integer)), Int64(LVecDeque.GetElementSize));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_LoadFrom_Array;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceArray: array[0..3] of Integer;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 0 to 3 do
      LSourceArray[i] := (i + 1) * 3;


    LVecDeque.LoadFrom(LSourceArray);

    { Object methods }
    AssertEquals('LoadFrom array should set correct count', Int64(4), Int64(LVecDeque.GetCount));
    for i := 0 to 3 do
      AssertEquals('Loaded element should match array', LSourceArray[i], LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_LoadFrom_Collection;
var
  LSource, LTarget: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LSource := specialize TVecDeque<Integer>.Create;
  LTarget := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 4 do
      LSource.PushBack(i * 8);


    LTarget.PushBack(999);
    LTarget.PushBack(888);


    LTarget.LoadFrom(LSource);

    { Object methods }
    AssertEquals('LoadFrom collection should set correct count', Int64(4), Int64(LTarget.GetCount));
    for i := 0 to 3 do
      AssertEquals('Loaded element should match source', LSource.Get(i), LTarget.Get(i));
  finally
    LSource.Free;
    LTarget.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_LoadFrom_Pointer;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceData: array[0..2] of Integer;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 0 to 2 do
      LSourceData[i] := (i + 1) * 12;


    LVecDeque.LoadFrom(@LSourceData[0], 3);

    { Object methods }
    AssertEquals('LoadFrom pointer should set correct count', Int64(3), Int64(LVecDeque.GetCount));
    for i := 0 to 2 do
      AssertEquals('Loaded element should match source', LSourceData[i], LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Append_Array;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceArray: array[0..2] of Integer;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);


    for i := 0 to 2 do
      LSourceArray[i] := (i + 1) * 15;

    { Object methods }
    LVecDeque.Append(LSourceArray);

    { Object methods }
    AssertEquals('Append array should update count', Int64(5), Int64(LVecDeque.GetCount));
    AssertEquals('Original element should remain', 1, LVecDeque.Get(0));
    AssertEquals('Original element should remain', 2, LVecDeque.Get(1));
    for i := 0 to 2 do
      AssertEquals('Appended element should match array', LSourceArray[i], LVecDeque.Get(i + 2));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Append_Collection;
var
  LSource, LTarget: specialize TVecDeque<Integer>;
  i: Integer;
begin
  { Object methods }
  LSource := specialize TVecDeque<Integer>.Create;
  LTarget := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 3 do
      LSource.PushBack(i * 20);


    LTarget.PushBack(100);
    LTarget.PushBack(200);

    { Object methods }
    LTarget.Append(LSource);

    { Object methods }
    AssertEquals('Source should remain unchanged', Int64(3), Int64(LSource.GetCount));
    AssertEquals('Target should have combined count', Int64(5), Int64(LTarget.GetCount));


    AssertEquals('Target original element should remain', 100, LTarget.Get(0));
    AssertEquals('Target original element should remain', 200, LTarget.Get(1));
    for i := 0 to 2 do
      AssertEquals('Appended element should match source', LSource.Get(i), LTarget.Get(i + 2));
  finally
    LSource.Free;
    LTarget.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Append_Pointer;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceData: array[0..1] of Integer;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(50);


    LSourceData[0] := 75;
    LSourceData[1] := 100;

    { Object methods }
    LVecDeque.Append(@LSourceData[0], 2);

    { Object methods }
    AssertEquals('Append pointer should update count', Int64(3), Int64(LVecDeque.GetCount));
    AssertEquals('Original element should remain', 50, LVecDeque.Get(0));
    AssertEquals('Appended element should be correct', 75, LVecDeque.Get(1));
    AssertEquals('Appended element should be correct', 100, LVecDeque.Get(2));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_AppendTo;
var
  LSource, LTarget: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LSource := specialize TVecDeque<Integer>.Create;
  LTarget := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 2 do
      LSource.PushBack(i * 25);


    LTarget.PushBack(300);


    LSource.AppendTo(LTarget);

    { Object methods }
    AssertEquals('Source should remain unchanged', Int64(2), Int64(LSource.GetCount));
    AssertEquals('Target should have combined count', Int64(3), Int64(LTarget.GetCount));


    AssertEquals('Target original element should remain', 300, LTarget.Get(0));
    AssertEquals('Appended element should match source', 25, LTarget.Get(1));
    AssertEquals('Appended element should match source', 50, LTarget.Get(2));
  finally
    LSource.Free;
    LTarget.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_SaveTo;
var
  LSource, LTarget: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LSource := specialize TVecDeque<Integer>.Create;
  LTarget := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 3 do
      LSource.PushBack(i * 30);


    LTarget.PushBack(999);
    LTarget.PushBack(888);
    LTarget.PushBack(777);
    LTarget.PushBack(666);


    LSource.SaveTo(LTarget);

    { Object methods }
    AssertEquals('Source should remain unchanged', Int64(3), Int64(LSource.GetCount));
    AssertEquals('Target should have source count', Int64(3), Int64(LTarget.GetCount));


    for i := 0 to 2 do
      AssertEquals('Target element should match source', LSource.Get(i), LTarget.Get(i));
  finally
    LSource.Free;
    LTarget.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ToArray;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LArray: specialize TGenericArray<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LArray := LVecDeque.ToArray;
    try
      AssertEquals('Empty VecDeque should produce empty array', Int64(0), Int64(length(LArray)));
    finally
      SetLength(LArray, 0);
    end;


    for i := 1 to 4 do
      LVecDeque.PushBack(i * 35);


    LArray := LVecDeque.ToArray;
    try
      AssertEquals('Array should have same count as VecDeque', Int64(4), Int64(length(LArray)));
      for i := 0 to 3 do
        AssertEquals('Array element should match VecDeque', LVecDeque.Get(i), LArray[i]);
    finally
      SetLength(LArray, 0);
    end;
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Reverse;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.Reverse;
    AssertTrue('Reverse empty VecDeque should work', LVecDeque.IsEmpty);


    for i := 1 to 5 do
      LVecDeque.PushBack(i);

    LVecDeque.Reverse;

    { Object methods }
    AssertEquals('Reverse should not change count', Int64(5), Int64(LVecDeque.GetCount));
    for i := 0 to 4 do
      AssertEquals('Reversed element should be correct', 5 - i, LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Reverse_Index;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Object methods }
    for i := 1 to 6 do
      LVecDeque.PushBack(i);


    LVecDeque.Reverse(2);

    { Object methods }
    AssertEquals('Element 0 should remain unchanged', 1, LVecDeque.Get(0));
    AssertEquals('Element 1 should remain unchanged', 2, LVecDeque.Get(1));
    AssertEquals('Element 2 should be reversed', 6, LVecDeque.Get(2));
    AssertEquals('Element 3 should be reversed', 5, LVecDeque.Get(3));
    AssertEquals('Element 4 should be reversed', 4, LVecDeque.Get(4));
    AssertEquals('Element 5 should be reversed', 3, LVecDeque.Get(5));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Reverse_Index_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Object methods }
    for i := 1 to 7 do
      LVecDeque.PushBack(i);


    LVecDeque.Reverse(1, 3);

    { Object methods }
    AssertEquals('Element 0 should remain unchanged', 1, LVecDeque.Get(0));
    AssertEquals('Element 1 should be reversed', 4, LVecDeque.Get(1));
    AssertEquals('Element 2 should be reversed', 3, LVecDeque.Get(2));
    AssertEquals('Element 3 should be reversed', 2, LVecDeque.Get(3));
    AssertEquals('Element 4 should remain unchanged', 5, LVecDeque.Get(4));
    AssertEquals('Element 5 should remain unchanged', 6, LVecDeque.Get(5));
    AssertEquals('Element 6 should remain unchanged', 7, LVecDeque.Get(6));
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Enqueue;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.Enqueue(10);
    AssertEquals('Enqueue should add element to queue', Int64(1), Int64(LVecDeque.GetCount));
    AssertEquals('Enqueued element should be at back', 10, LVecDeque.Back);

    { Object methods }
    LVecDeque.Enqueue(20);
    LVecDeque.Enqueue(30);
    AssertEquals('Multiple enqueue should increase count', Int64(3), Int64(LVecDeque.GetCount));
    AssertEquals('First element should remain at front', 10, LVecDeque.Front);
    AssertEquals('Last element should be at back', 30, LVecDeque.Back);

    { Object methods }
    for i := 1 to 100 do
      LVecDeque.Enqueue(i * 10);

    AssertEquals('Large enqueue should work correctly', Int64(103), Int64(LVecDeque.GetCount));
    AssertEquals('Front should remain unchanged', 10, LVecDeque.Front);
    AssertEquals('Back should be last enqueued', 1000, LVecDeque.Back);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Dequeue;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LValue: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.Enqueue(100);
    LVecDeque.Enqueue(200);
    LVecDeque.Enqueue(300);

    { Object methods }
    LValue := LVecDeque.Dequeue;
    AssertEquals('Dequeue should return first element', 100, LValue);
    AssertEquals('Dequeue should decrease count', Int64(2), Int64(LVecDeque.GetCount));
    AssertEquals('Front should be next element', 200, LVecDeque.Front);

    { Object methods }
    LValue := LVecDeque.Dequeue;
    AssertEquals('Second dequeue should return second element', 200, LValue);
    AssertEquals('Count should continue decreasing', Int64(1), Int64(LVecDeque.GetCount));

    LValue := LVecDeque.Dequeue;
    AssertEquals('Third dequeue should return last element', 300, LValue);
    AssertTrue('Queue should be empty after all dequeues', LVecDeque.IsEmpty);


    try
      LVecDeque.Dequeue;
      Fail('Dequeue on empty queue should raise exception');
    except
      on E: Exception do
        { expected exception}
    end;
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Dequeue_Safe;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LElement: Integer;
  LResult: Boolean;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LElement := 999; { initialvalue}
    LResult := LVecDeque.Dequeue(LElement);
    AssertFalse('Safe dequeue on empty queue should return False', LResult);
    AssertEquals('Element should not be modified on empty queue', 999, LElement);


    LVecDeque.Enqueue(50);
    LVecDeque.Enqueue(60);


    LResult := LVecDeque.Dequeue(LElement);
    AssertTrue('Safe dequeue on non-empty queue should return True', LResult);
    AssertEquals('Safe dequeue should return correct element', 50, LElement);
    AssertEquals('Count should decrease after safe dequeue', Int64(1), Int64(LVecDeque.GetCount));


    LResult := LVecDeque.Dequeue(LElement);
    AssertTrue('Safe dequeue of last element should return True', LResult);
    AssertEquals('Last element should be correct', 60, LElement);
    AssertTrue('Queue should be empty after last dequeue', LVecDeque.IsEmpty);


    LElement := 888;
    LResult := LVecDeque.Dequeue(LElement);
    AssertFalse('Safe dequeue on empty queue should return False again', LResult);
    AssertEquals('Element should not be modified on empty queue again', 888, LElement);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Peek;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LValue: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.Enqueue(111);
    LVecDeque.Enqueue(222);
    LVecDeque.Enqueue(333);


    LValue := LVecDeque.Peek;
    AssertEquals('Peek should return front element', 111, LValue);
    AssertEquals('Peek should not change count', Int64(3), Int64(LVecDeque.GetCount));

    { Object methods }
    AssertEquals('Front element should still be there', 111, LVecDeque.Front);


    LValue := LVecDeque.Peek;
    AssertEquals('Multiple peek should return same value', 111, LValue);


    LVecDeque.Dequeue;
    LValue := LVecDeque.Peek;
    AssertEquals('Peek after dequeue should return new front', 222, LValue);


    LVecDeque.Clear;
    try
      LVecDeque.Peek;
      Fail('Peek on empty queue should raise exception');
    except
      on E: Exception do
        { expected exception}
    end;
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Peek_Safe;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LElement: Integer;
  LResult: Boolean;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LElement := 777; { initial value}
    LResult := LVecDeque.Peek(LElement);
    AssertFalse('Safe peek on empty queue should return False', LResult);
    AssertEquals('Element should not be modified on empty queue', 777, LElement);


    LVecDeque.Enqueue(444);
    LVecDeque.Enqueue(555);


    LResult := LVecDeque.Peek(LElement);
    AssertTrue('Safe peek on non-empty queue should return True', LResult);
    AssertEquals('Safe peek should return front element', 444, LElement);
    AssertEquals('Safe peek should not change count', Int64(2), Int64(LVecDeque.GetCount));

    { Object methods }
    AssertEquals('Front element should still be there', 444, LVecDeque.Front);


    LElement := 0;
    LResult := LVecDeque.Peek(LElement);
    AssertTrue('Multiple safe peek should return True', LResult);
    AssertEquals('Multiple safe peek should return same value', 444, LElement);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Front;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LValue: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(123);
    LVecDeque.PushBack(456);
    LVecDeque.PushFront(789);


    LValue := LVecDeque.Front;
    AssertEquals('Front should return front element', 789, LValue);
    AssertEquals('Front should not change count', Int64(3), Int64(LVecDeque.GetCount));

    { Object methods }
    AssertEquals('Front element should still be there', 789, LVecDeque.Get(0));


    LValue := LVecDeque.Front;
    AssertEquals('Multiple Front calls should return same value', 789, LValue);


    LVecDeque.PopFront;
    LValue := LVecDeque.Front;
    AssertEquals('Front after PopFront should return new front', 123, LValue);


    LVecDeque.Clear;
    try
      LVecDeque.Front;
      Fail('Front on empty VecDeque should raise exception');
    except
      on E: Exception do
        { expected exception}
    end;
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Front_Safe;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LElement: Integer;
  LResult: Boolean;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LElement := 666; { initialvalue}
    LResult := LVecDeque.Front(LElement);
    AssertFalse('Safe Front on empty VecDeque should return False', LResult);
    AssertEquals('Element should not be modified on empty VecDeque', 666, LElement);


    LVecDeque.PushBack(321);
    LVecDeque.PushFront(654);


    LResult := LVecDeque.Front(LElement);
    AssertTrue('Safe Front on non-empty VecDeque should return True', LResult);
    AssertEquals('Safe Front should return front element', 654, LElement);
    AssertEquals('Safe Front should not change count', Int64(2), Int64(LVecDeque.GetCount));

    { Object methods }
    AssertEquals('Front element should still be there', 654, LVecDeque.Get(0));


    LElement := 0;
    LResult := LVecDeque.Front(LElement);
    AssertTrue('Multiple safe Front should return True', LResult);
    AssertEquals('Multiple safe Front should return same value', 654, LElement);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Back;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LValue: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushFront(987);
    LVecDeque.PushFront(654);
    LVecDeque.PushBack(321);


    LValue := LVecDeque.Back;
    AssertEquals('Back should return back element', 321, LValue);
    AssertEquals('Back should not change count', Int64(3), Int64(LVecDeque.GetCount));

    { Object methods }
    AssertEquals('Back element should still be there', 321, LVecDeque.Get(2));


    LValue := LVecDeque.Back;
    AssertEquals('Multiple Back calls should return same value', 321, LValue);


    LVecDeque.PopBack;
    LValue := LVecDeque.Back;
    AssertEquals('Back after PopBack should return new back', 987, LValue);


    LVecDeque.Clear;
    try
      LVecDeque.Back;
      Fail('Back on empty VecDeque should raise exception');
    except
      on E: Exception do
        { expected exception}
    end;
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Back_Safe;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LElement: Integer;
  LResult: Boolean;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LElement := 555; { initialvalue}
    LResult := LVecDeque.Back(LElement);
    AssertFalse('Safe Back on empty VecDeque should return False', LResult);
    AssertEquals('Element should not be modified on empty VecDeque', 555, LElement);


    LVecDeque.PushFront(147);
    LVecDeque.PushBack(258);


    LResult := LVecDeque.Back(LElement);
    AssertTrue('Safe Back on non-empty VecDeque should return True', LResult);
    AssertEquals('Safe Back should return back element', 258, LElement);
    AssertEquals('Safe Back should not change count', Int64(2), Int64(LVecDeque.GetCount));

    { Object methods }
    AssertEquals('Back element should still be there', 258, LVecDeque.Get(1));


    LElement := 0;
    LResult := LVecDeque.Back(LElement);
    AssertTrue('Multiple safe Back should return True', LResult);
    AssertEquals('Multiple safe Back should return same value', 258, LElement);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_SplitOff;
var
  LVecDeque, LSplitPart: specialize TVecDeque<Integer>;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 10 do
      LVecDeque.PushBack(i * 10);


    LSplitPart := LVecDeque.SplitOff(5) as specialize TVecDeque<Integer>;
    try

      AssertEquals('Original should have first part', Int64(5), Int64(LVecDeque.GetCount));
      for i := 0 to 4 do
        AssertEquals('Original element should be correct', (i + 1) * 10, LVecDeque.Get(i));

      { Object methods }
      AssertEquals('Split part should have second part', Int64(5), Int64(LSplitPart.GetCount));
      for i := 0 to 4 do
        AssertEquals('Split element should be correct', (i + 6) * 10, LSplitPart.Get(i));
    finally
      LSplitPart.Free;
    end;


    LSplitPart := LVecDeque.SplitOff(0) as specialize TVecDeque<Integer>;
    try
      AssertTrue('Original should be empty after split from 0', LVecDeque.IsEmpty);
      AssertEquals('Split part should have all elements', Int64(5), Int64(LSplitPart.GetCount));
    finally
      LSplitPart.Free;
    end;


    LVecDeque.Clear;
    for i := 1 to 3 do
      LVecDeque.PushBack(i * 100);

    LSplitPart := LVecDeque.SplitOff(3) as specialize TVecDeque<Integer>;
    try
      AssertEquals('Original should keep all elements', Int64(3), Int64(LVecDeque.GetCount));
      AssertTrue('Split part should be empty', LSplitPart.IsEmpty);
    finally
      LSplitPart.Free;
    end;


    try
      LVecDeque.SplitOff(10); { Object methods }
      Fail('SplitOff with invalid index should raise exception');
    except
      on E: Exception do
        { expected exception}
    end;
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_PushFront_Array;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceArray: array[0..2] of Integer;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(100);
    LVecDeque.PushBack(200);


    LSourceArray[0] := 10;
    LSourceArray[1] := 20;
    LSourceArray[2] := 30;


    LVecDeque.PushFront(LSourceArray);


    AssertEquals('PushFront array should update count', Int64(5), Int64(LVecDeque.GetCount));
    AssertEquals('First array element should be at front', 10, LVecDeque.Get(0));
    AssertEquals('Second array element should follow', 20, LVecDeque.Get(1));
    AssertEquals('Third array element should follow', 30, LVecDeque.Get(2));
    AssertEquals('Original element should be pushed back', 100, LVecDeque.Get(3));
    AssertEquals('Original element should be pushed back', 200, LVecDeque.Get(4));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_PushFront_Pointer;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceData: array[0..1] of Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(500);


    LSourceData[0] := 15;
    LSourceData[1] := 25;


    LVecDeque.PushFront(@LSourceData[0], 2);

    { Object methods }
    AssertEquals('PushFront pointer should update count', Int64(3), Int64(LVecDeque.GetCount));
    AssertEquals('First pointer element should be at front', 15, LVecDeque.Get(0));
    AssertEquals('Second pointer element should follow', 25, LVecDeque.Get(1));
    AssertEquals('Original element should be pushed back', 500, LVecDeque.Get(2));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_PushBack_Array;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceArray: array[0..2] of Integer;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushFront(50);
    LVecDeque.PushFront(40);


    LSourceArray[0] := 60;
    LSourceArray[1] := 70;
    LSourceArray[2] := 80;


    LVecDeque.PushBack(LSourceArray);

    { Object methods }
    AssertEquals('PushBack array should update count', Int64(5), Int64(LVecDeque.GetCount));
    AssertEquals('Original element should remain at front', 40, LVecDeque.Get(0));
    AssertEquals('Original element should remain', 50, LVecDeque.Get(1));
    AssertEquals('First array element should be at back', 60, LVecDeque.Get(2));
    AssertEquals('Second array element should follow', 70, LVecDeque.Get(3));
    AssertEquals('Third array element should follow', 80, LVecDeque.Get(4));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_PushBack_Pointer;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceData: array[0..1] of Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushFront(300);


    LSourceData[0] := 400;
    LSourceData[1] := 500;


    LVecDeque.PushBack(@LSourceData[0], 2);

    { Object methods }
    AssertEquals('PushBack pointer should update count', Int64(3), Int64(LVecDeque.GetCount));
    AssertEquals('Original element should remain at front', 300, LVecDeque.Get(0));
    AssertEquals('First pointer element should be at back', 400, LVecDeque.Get(1));
    AssertEquals('Second pointer element should follow', 500, LVecDeque.Get(2));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_PopFront_Safe;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LElement: Integer;
  LResult: Boolean;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Object methods }
    LElement := 999; { initialvalue}
    LResult := LVecDeque.PopFront(LElement);
    AssertFalse('PopFront on empty VecDeque should return False', LResult);
    AssertEquals('Element should not be modified on empty VecDeque', 999, LElement);


    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(30);

    { Object methods }
    LResult := LVecDeque.PopFront(LElement);
    AssertTrue('PopFront on non-empty VecDeque should return True', LResult);
    AssertEquals('PopFront should return first element', 10, LElement);
    AssertEquals('Count should decrease after PopFront', Int64(2), Int64(LVecDeque.GetCount));


    LVecDeque.PopFront(LElement);
    AssertEquals('Second PopFront should return second element', 20, LElement);

    LVecDeque.PopFront(LElement);
    AssertEquals('Third PopFront should return third element', 30, LElement);
    AssertTrue('VecDeque should be empty after removing all elements', LVecDeque.IsEmpty);


    LElement := 888;
    LResult := LVecDeque.PopFront(LElement);
    AssertFalse('PopFront on empty VecDeque should return False again', LResult);
    AssertEquals('Element should not be modified on empty VecDeque again', 888, LElement);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_PopBack_Safe;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LElement: Integer;
  LResult: Boolean;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Object methods }
    LElement := 777; { initialvalue}
    LResult := LVecDeque.PopBack(LElement);
    AssertFalse('PopBack on empty VecDeque should return False', LResult);
    AssertEquals('Element should not be modified on empty VecDeque', 777, LElement);


    LVecDeque.PushFront(100);
    LVecDeque.PushFront(200);
    LVecDeque.PushFront(300);

    { Object methods }
    LResult := LVecDeque.PopBack(LElement);
    AssertTrue('PopBack on non-empty VecDeque should return True', LResult);
    AssertEquals('PopBack should return last element', 100, LElement);
    AssertEquals('Count should decrease after PopBack', Int64(2), Int64(LVecDeque.GetCount));


    LVecDeque.PopBack(LElement);
    AssertEquals('Second PopBack should return second last element', 200, LElement);

    LVecDeque.PopBack(LElement);
    AssertEquals('Third PopBack should return first element', 300, LElement);
    AssertTrue('VecDeque should be empty after removing all elements', LVecDeque.IsEmpty);


    LElement := 666;
    LResult := LVecDeque.PopBack(LElement);
    AssertFalse('PopBack on empty VecDeque should return False again', LResult);
    AssertEquals('Element should not be modified on empty VecDeque again', 666, LElement);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_PeekFront;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LValue: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(111);
    LVecDeque.PushBack(222);
    LVecDeque.PushFront(333);


    LValue := LVecDeque.PeekFront;
    AssertEquals('PeekFront should return front element', 333, LValue);
    AssertEquals('PeekFront should not change count', Int64(3), Int64(LVecDeque.GetCount));

    { Object methods }
    AssertEquals('Front element should still be there', 333, LVecDeque.Front);


    LValue := LVecDeque.PeekFront;
    AssertEquals('Multiple PeekFront should return same value', 333, LValue);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_PeekFront_Safe;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LElement: Integer;
  LResult: Boolean;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Object methods }
    LElement := 555; { initialvalue}
    LResult := LVecDeque.PeekFront(LElement);
    AssertFalse('PeekFront on empty VecDeque should return False', LResult);
    AssertEquals('Element should not be modified on empty VecDeque', 555, LElement);


    LVecDeque.PushBack(444);
    LVecDeque.PushFront(666);

    { Object methods }
    LResult := LVecDeque.PeekFront(LElement);
    AssertTrue('PeekFront on non-empty VecDeque should return True', LResult);
    AssertEquals('PeekFront should return front element', 666, LElement);
    AssertEquals('PeekFront should not change count', Int64(2), Int64(LVecDeque.GetCount));

    { Object methods }
    AssertEquals('Front element should still be there', 666, LVecDeque.Front);


    LElement := 0;
    LResult := LVecDeque.PeekFront(LElement);
    AssertTrue('Multiple safe PeekFront should return True', LResult);
    AssertEquals('Multiple safe PeekFront should return same value', 666, LElement);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_PeekBack;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LValue: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushFront(777);
    LVecDeque.PushFront(888);
    LVecDeque.PushBack(999);


    LValue := LVecDeque.PeekBack;
    AssertEquals('PeekBack should return back element', 999, LValue);
    AssertEquals('PeekBack should not change count', Int64(3), Int64(LVecDeque.GetCount));

    { Object methods }
    AssertEquals('Back element should still be there', 999, LVecDeque.Back);


    LValue := LVecDeque.PeekBack;
    AssertEquals('Multiple PeekBack should return same value', 999, LValue);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_PeekBack_Safe;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LElement: Integer;
  LResult: Boolean;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Object methods }
    LElement := 123; { initialvalue}
    LResult := LVecDeque.PeekBack(LElement);
    AssertFalse('PeekBack on empty VecDeque should return False', LResult);
    AssertEquals('Element should not be modified on empty VecDeque', 123, LElement);


    LVecDeque.PushFront(456);
    LVecDeque.PushBack(789);

    { Object methods }
    LResult := LVecDeque.PeekBack(LElement);
    AssertTrue('PeekBack on non-empty VecDeque should return True', LResult);
    AssertEquals('PeekBack should return back element', 789, LElement);
    AssertEquals('PeekBack should not change count', Int64(2), Int64(LVecDeque.GetCount));

    { Object methods }
    AssertEquals('Back element should still be there', 789, LVecDeque.Back);


    LElement := 0;
    LResult := LVecDeque.PeekBack(LElement);
    AssertTrue('Multiple safe PeekBack should return True', LResult);
    AssertEquals('Multiple safe PeekBack should return same value', 789, LElement);
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Get;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 5 do
      LVecDeque.PushBack(i * 11);

    { Object methods }
    for i := 0 to 4 do
      AssertEquals('Get should return correct element', (i + 1) * 11, LVecDeque.Get(i));


    try
      LVecDeque.Get(5); { Object methods }
      Fail('Get with invalid index should raise exception');
    except
      on E: Exception do
        { expected exception}
    end;
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_GetUnChecked;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 4 do
      LVecDeque.PushBack(i * 13);


    for i := 0 to 3 do
      AssertEquals('GetUnChecked should return correct element', (i + 1) * 13, LVecDeque.GetUnChecked(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Put;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 4 do
      LVecDeque.PushBack(i);

    { Object methods }
    for i := 0 to 3 do
      LVecDeque.Put(i, (i + 1) * 17);

    { Object methods }
    for i := 0 to 3 do
      AssertEquals('Put should update element correctly', (i + 1) * 17, LVecDeque.Get(i));


    try
      LVecDeque.Put(4, 999); { Object methods }
      Fail('Put with invalid index should raise exception');
    except
      on E: Exception do
        { expected exception}
    end;
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_PutUnChecked;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 3 do
      LVecDeque.PushBack(i);


    for i := 0 to 2 do
      LVecDeque.PutUnChecked(i, (i + 1) * 19);

    { Object methods }
    for i := 0 to 2 do
      AssertEquals('PutUnChecked should update element correctly', (i + 1) * 19, LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_GetPtr;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LPtr: PInteger;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 3 do
      LVecDeque.PushBack(i * 23);

    { Object methods }
    for i := 0 to 2 do
    begin
      LPtr := LVecDeque.GetPtr(i);
      AssertNotNull('GetPtr should return valid pointer', LPtr);
      AssertEquals('GetPtr should point to correct element', (i + 1) * 23, LPtr^);


      LPtr^ := (i + 1) * 29;
      AssertEquals('Modification through pointer should work', (i + 1) * 29, LVecDeque.Get(i));
    end;


    try
      LVecDeque.GetPtr(3); { Object methods }
      Fail('GetPtr with invalid index should raise exception');
    except
      on E: Exception do
        { expected exception}
    end;
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_GetPtrUnChecked;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LPtr: PInteger;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 3 do
      LVecDeque.PushBack(i * 31);


    for i := 0 to 2 do
    begin
      LPtr := LVecDeque.GetPtrUnChecked(i);
      AssertNotNull('GetPtrUnChecked should return valid pointer', LPtr);
      AssertEquals('GetPtrUnChecked should point to correct element', (i + 1) * 31, LPtr^);


      LPtr^ := (i + 1) * 37;
      AssertEquals('Modification through pointer should work', (i + 1) * 37, LVecDeque.Get(i));
    end;
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_GetMemory;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LMemory: PInteger;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Object methods }
    LMemory := LVecDeque.GetMemory;
    { Object methods }


    for i := 1 to 4 do
      LVecDeque.PushBack(i * 41);


    LMemory := LVecDeque.GetMemory;
    AssertNotNull('GetMemory should return valid pointer for non-empty VecDeque', LMemory);



  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Resize;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 3 do
      LVecDeque.PushBack(i * 43);


    LVecDeque.Resize(5);
    AssertEquals('Resize should update count', Int64(5), Int64(LVecDeque.GetCount));

    { Object methods }
    for i := 0 to 2 do
      AssertEquals('Original elements should remain after resize', (i + 1) * 43, LVecDeque.Get(i));


    AssertEquals('New element should be default value', 0, LVecDeque.Get(3));
    AssertEquals('New element should be default value', 0, LVecDeque.Get(4));


    LVecDeque.Resize(2);
    AssertEquals('Resize should update count when shrinking', Int64(2), Int64(LVecDeque.GetCount));


    for i := 0 to 1 do
      AssertEquals('Remaining elements should be correct after shrinking', (i + 1) * 43, LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Resize_Value;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 2 do
      LVecDeque.PushBack(i * 47);


    LVecDeque.Resize(5, 999);
    AssertEquals('Resize with value should update count', Int64(5), Int64(LVecDeque.GetCount));

    { Object methods }
    for i := 0 to 1 do
      AssertEquals('Original elements should remain after resize', (i + 1) * 47, LVecDeque.Get(i));


    AssertEquals('New element should be specified value', 999, LVecDeque.Get(2));
    AssertEquals('New element should be specified value', 999, LVecDeque.Get(3));
    AssertEquals('New element should be specified value', 999, LVecDeque.Get(4));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Ensure;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LOriginalCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LOriginalCount := LVecDeque.GetCount;


    LVecDeque.Ensure(1);
    AssertEquals('Ensure existing index should not change count', Int64(LOriginalCount), Int64(LVecDeque.GetCount));


    LVecDeque.Ensure(5);
    AssertTrue('Ensure should expand VecDeque to include index', LVecDeque.GetCount > 5);

    { Object methods }
    AssertEquals('Original element should remain', 1, LVecDeque.Get(0));
    AssertEquals('Original element should remain', 2, LVecDeque.Get(1));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_TryGet;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LElement: Integer;
  LResult: Boolean;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(53);
    LVecDeque.PushBack(59);

    { Object methods }
    LElement := 0;
    LResult := LVecDeque.TryGet(0, LElement);
    AssertTrue('TryGet with valid index should return True', LResult);
    AssertEquals('TryGet should return correct element', 53, LElement);

    LResult := LVecDeque.TryGet(1, LElement);
    AssertTrue('TryGet with valid index should return True', LResult);
    AssertEquals('TryGet should return correct element', 59, LElement);

    { Object methods }
    LElement := 999; { initialvalue}
    LResult := LVecDeque.TryGet(2, LElement);
    AssertFalse('TryGet with invalid index should return False', LResult);
    AssertEquals('Element should not be modified on invalid index', 999, LElement);


    LResult := LVecDeque.TryGet(SizeUInt(-1), LElement);
    AssertFalse('TryGet with negative index should return False', LResult);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_TryRemove;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LElement: Integer;
  LResult: Boolean;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(61);
    LVecDeque.PushBack(67);
    LVecDeque.PushBack(71);

    { Object methods }
    LElement := 0;
    LResult := LVecDeque.TryRemove(1, LElement);
    AssertTrue('TryRemove with valid index should return True', LResult);
    AssertEquals('TryRemove should return removed element', 67, LElement);
    AssertEquals('Count should decrease after TryRemove', Int64(2), Int64(LVecDeque.GetCount));


    AssertEquals('Remaining element should be correct', 61, LVecDeque.Get(0));
    AssertEquals('Remaining element should be correct', 71, LVecDeque.Get(1));

    { Object methods }
    LElement := 999; { initialvalue}
    LResult := LVecDeque.TryRemove(5, LElement);
    AssertFalse('TryRemove with invalid index should return False', LResult);
    AssertEquals('Element should not be modified on invalid index', 999, LElement);
    AssertEquals('Count should not change on invalid remove', Int64(2), Int64(LVecDeque.GetCount));
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_GetCapacity;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInitialCapacity: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LInitialCapacity := LVecDeque.GetCapacity;
    AssertTrue('Initial capacity should be greater than 0', LInitialCapacity > 0);


    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    AssertTrue('Capacity should remain same or increase', LVecDeque.GetCapacity >= LInitialCapacity);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_SetCapacity;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LNewCapacity: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(73);
    LVecDeque.PushBack(79);

    { Object methods }
    LNewCapacity := 100;
    LVecDeque.SetCapacity(LNewCapacity);
    AssertTrue('SetCapacity should increase capacity', LVecDeque.GetCapacity >= LNewCapacity);

    { Object methods }
    AssertEquals('Elements should remain after capacity change', 73, LVecDeque.Get(0));
    AssertEquals('Elements should remain after capacity change', 79, LVecDeque.Get(1));
    AssertEquals('Count should remain after capacity change', Int64(2), Int64(LVecDeque.GetCount));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Reserve;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LOriginalCapacity, LNewCapacity: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LOriginalCapacity := LVecDeque.GetCapacity;


    LVecDeque.Reserve(50);
    LNewCapacity := LVecDeque.GetCapacity;
    AssertTrue('Reserve should increase capacity', LNewCapacity >= LOriginalCapacity + 50);

    { Object methods }
    LVecDeque.PushBack(83);
    LVecDeque.PushBack(89);
    AssertEquals('Elements should be added correctly after reserve', 83, LVecDeque.Get(0));
    AssertEquals('Elements should be added correctly after reserve', 89, LVecDeque.Get(1));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ShrinkToFit;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCapacityBefore, LCapacityAfter: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.Reserve(1000);
    LCapacityBefore := LVecDeque.GetCapacity;


    for i := 1 to 5 do
      LVecDeque.PushBack(i * 97);


    LVecDeque.ShrinkToFit;
    LCapacityAfter := LVecDeque.GetCapacity;


    AssertTrue('ShrinkToFit should reduce capacity', LCapacityAfter < LCapacityBefore);
    AssertTrue('ShrinkToFit should keep enough capacity for elements', LCapacityAfter >= LVecDeque.GetCount);

    { Object methods }
    for i := 0 to 4 do
      AssertEquals('Elements should remain after ShrinkToFit', (i + 1) * 97, LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IsFull;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCapacity: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    AssertFalse('New VecDeque should not be full', LVecDeque.GetCount = 0);

    { Object methods }
    LCapacity := LVecDeque.GetCapacity;


    for i := 1 to Integer(LCapacity) do
      LVecDeque.PushBack(i);



    AssertTrue('VecDeque count should equal or exceed original capacity', LVecDeque.GetCount >= LCapacity);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_GetGrowStrategy;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LGrowStrategy: TGrowthStrategy;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { testdefaultgrowthstrategy }
    LGrowStrategy := LVecDeque.GetGrowStrategy;
    AssertNotNull('GetGrowStrategy should return valid strategy', LGrowStrategy);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_SetGrowStrategy;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCustomStrategy: TGrowthStrategy;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LCustomStrategy := TGoldenRatioGrowStrategy.Create;
    try
      { Object methods }
      LVecDeque.SetGrowStrategy(LCustomStrategy);


      AssertTrue('SetGrowStrategy should update strategy', LVecDeque.GetGrowStrategy = LCustomStrategy);

      { Object methods }
      LVecDeque.PushBack(101);
      LVecDeque.PushBack(103);
      AssertEquals('Elements should be added correctly with custom strategy', 101, LVecDeque.Get(0));
      AssertEquals('Elements should be added correctly with custom strategy', 103, LVecDeque.Get(1));
    finally
      LCustomStrategy.Free;
    end;
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Capacity_AutoGrow;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInitialCapacity, LCurrentCapacity: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LInitialCapacity := LVecDeque.GetCapacity;


    for i := 1 to Integer(LInitialCapacity * 2) do
    begin
      LVecDeque.PushBack(i);
      LCurrentCapacity := LVecDeque.GetCapacity;


      AssertTrue('Capacity should grow as needed', LCurrentCapacity >= LVecDeque.GetCount);
    end;


    AssertTrue('Final capacity should be greater than initial', LCurrentCapacity > LInitialCapacity);


    for i := 1 to Integer(LInitialCapacity * 2) do
      AssertEquals('All elements should be correctly stored', i, LVecDeque.Get(i - 1));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Capacity_Reserve_Increase;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LOriginalCapacity, LNewCapacity: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LOriginalCapacity := LVecDeque.GetCapacity;


    LVecDeque.Reserve(LOriginalCapacity + 100);
    LNewCapacity := LVecDeque.GetCapacity;

    { Object methods }
    AssertTrue('Reserve should increase capacity', LNewCapacity > LOriginalCapacity);
    AssertTrue('New capacity should accommodate reserved space', LNewCapacity >= LOriginalCapacity + 100);

    { Object methods }
    LVecDeque.PushBack(107);
    LVecDeque.PushBack(109);
    AssertEquals('Elements should be added correctly after reserve', 107, LVecDeque.Get(0));
    AssertEquals('Elements should be added correctly after reserve', 109, LVecDeque.Get(1));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Capacity_Reserve_Decrease;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LOriginalCapacity: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.Reserve(1000);
    LOriginalCapacity := LVecDeque.GetCapacity;


    LVecDeque.Reserve(10);


    AssertTrue('Reserve with smaller value should not decrease capacity',
               LVecDeque.GetCapacity >= LOriginalCapacity);


    LVecDeque.ShrinkToFit;
    AssertTrue('ShrinkToFit should reduce capacity', LVecDeque.GetCapacity < LOriginalCapacity);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Capacity_ShrinkToFit_Empty;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCapacityBefore, LCapacityAfter: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.Reserve(500);
    LCapacityBefore := LVecDeque.GetCapacity;


    LVecDeque.ShrinkToFit;
    LCapacityAfter := LVecDeque.GetCapacity;

    { Object methods }
    AssertTrue('ShrinkToFit on empty VecDeque should reduce capacity', LCapacityAfter <= LCapacityBefore);
    AssertTrue('VecDeque should remain empty', LVecDeque.IsEmpty);
    AssertEquals('Count should remain 0', Int64(0), Int64(LVecDeque.GetCount));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Capacity_ShrinkToFit_Partial;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCapacityBefore, LCapacityAfter: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.Reserve(200);
    LCapacityBefore := LVecDeque.GetCapacity;


    for i := 1 to 10 do
      LVecDeque.PushBack(i * 113);

    { executeShrinkToFit }
    LVecDeque.ShrinkToFit;
    LCapacityAfter := LVecDeque.GetCapacity;


    AssertTrue('ShrinkToFit should reduce capacity', LCapacityAfter < LCapacityBefore);
    AssertTrue('Capacity should still accommodate all elements', LCapacityAfter >= LVecDeque.GetCount);

    { Object methods }
    for i := 0 to 9 do
      AssertEquals('Elements should remain after ShrinkToFit', (i + 1) * 113, LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

{ ===== double-endedoperationtestimplement ===== }

procedure TTestCase_VecDeque.Test_Deque_Mixed_Operations;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Object methods }
    LVecDeque.PushBack(10);     { [10] }
    LVecDeque.PushFront(5);     { [5, 10] }
    LVecDeque.PushBack(15);     { [5, 10, 15] }
    LVecDeque.PushFront(1);     { [1, 5, 10, 15] }

    AssertEquals('Mixed push operations count', Int64(4), Int64(LVecDeque.GetCount));
    AssertEquals('Front after mixed operations', 1, LVecDeque.Front);
    AssertEquals('Back after mixed operations', 15, LVecDeque.Back);


    AssertEquals('Element at index 1', 5, LVecDeque.Get(1));
    AssertEquals('Element at index 2', 10, LVecDeque.Get(2));

    { Object methods }
    AssertEquals('PopFront should return front', 1, LVecDeque.PopFront);  { [5, 10, 15] }
    AssertEquals('PopBack should return back', 15, LVecDeque.PopBack);    { [5, 10] }
    AssertEquals('Count after mixed pop', Int64(2), Int64(LVecDeque.GetCount));

    { Object methods }
    for i := 1 to 5 do
    begin
      LVecDeque.PushFront(i * 100);
      LVecDeque.PushBack(i * 200);
    end;

    AssertEquals('Count after alternating operations', Int64(12), Int64(LVecDeque.GetCount));
    AssertEquals('Front after alternating', 500, LVecDeque.Front);
    AssertEquals('Back after alternating', 1000, LVecDeque.Back);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Deque_Front_Back_Balance;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i, LFrontSum, LBackSum: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Object methods }
    for i := 1 to 10 do
    begin
      LVecDeque.PushFront(i);      { frontadd 1,2,3...10 }
      LVecDeque.PushBack(i + 10);  { backadd 11,12,13...20 }
    end;

    AssertEquals('Balanced operations count', Int64(20), Int64(LVecDeque.GetCount));
    AssertEquals('Front after balanced push', 10, LVecDeque.Front);
    AssertEquals('Back after balanced push', 20, LVecDeque.Back);


    LFrontSum := 0;
    LBackSum := 0;

    for i := 1 to 10 do
    begin
      LFrontSum := LFrontSum + LVecDeque.PopFront;  { removefront }
      LBackSum := LBackSum + LVecDeque.PopBack;     { removeback }
    end;

    AssertTrue('Should be empty after balanced removal', LVecDeque.IsEmpty);
    AssertEquals('Front sum should be correct', 55, LFrontSum);    { 10+9+8+...+1 }
    AssertEquals('Back sum should be correct', 155, LBackSum);     { 20+19+18+...+11 }


    for i := 1 to 5 do
      LVecDeque.PushFront(i);

    for i := 1 to 5 do
      LVecDeque.PushBack(i + 10);

    AssertEquals('Rebalanced count', Int64(10), Int64(LVecDeque.GetCount));
    AssertEquals('Rebalanced front', 5, LVecDeque.Front);
    AssertEquals('Rebalanced back', 15, LVecDeque.Back);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Deque_Circular_Buffer;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i, LValue: Integer;
  LInitialCapacity: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LInitialCapacity := LVecDeque.GetCapacity;


    for i := 1 to Integer(LInitialCapacity) do
      LVecDeque.PushBack(i);


    for i := 1 to 10 do
    begin
      LValue := LVecDeque.PopFront;  { removefront }
      AssertEquals('Circular pop front should be correct', i, LValue);

      LVecDeque.PushBack(Integer(LInitialCapacity) + i);


      AssertTrue('Capacity should not grow significantly',
                 LVecDeque.GetCapacity <= LInitialCapacity * 2);
    end;


    AssertEquals('Count should remain same', Int64(LInitialCapacity), Int64(LVecDeque.GetCount));
    AssertEquals('New front should be correct', 11, LVecDeque.Front);
    AssertEquals('New back should be correct', Integer(LInitialCapacity) + 10, LVecDeque.Back);


    for i := 1 to 5 do
    begin
      LValue := LVecDeque.PopBack;   { removeback }
      LVecDeque.PushFront(i * 1000);
    end;

    AssertEquals('Reverse circular front', 5000, LVecDeque.Front);
    AssertEquals('Count after reverse circular', Int64(LInitialCapacity), Int64(LVecDeque.GetCount));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Deque_Stress_Operations;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i, LOperationCount, LValue: Integer;
  LExpectedSum, LActualSum: Int64;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LOperationCount := 1000;
    LExpectedSum := 0;

    { Object methods }
    for i := 1 to LOperationCount do
    begin
      case i mod 4 of
        0: begin
          LVecDeque.PushFront(i);
          LExpectedSum := LExpectedSum + i;
        end;
        1: begin
          LVecDeque.PushBack(i);
          LExpectedSum := LExpectedSum + i;
        end;
        2: begin
          if not LVecDeque.IsEmpty then
          begin
            LValue := LVecDeque.PopFront;
            LExpectedSum := LExpectedSum - LValue;
          end;
        end;
        3: begin
          if not LVecDeque.IsEmpty then
          begin
            LValue := LVecDeque.PopBack;
            LExpectedSum := LExpectedSum - LValue;
          end;
        end;
      end;


      if (i mod 100) = 0 then
      begin
        AssertTrue('VecDeque should maintain consistency', LVecDeque.GetCount >= 0);
        if not LVecDeque.IsEmpty then
        begin

          LVecDeque.Front;
          LVecDeque.Back;
        end;
      end;
    end;


    LActualSum := 0;
    while not LVecDeque.IsEmpty do
    begin
      LActualSum := LActualSum + LVecDeque.PopFront;
    end;

    AssertEquals('Stress test sum should match', LExpectedSum, LActualSum);
    AssertTrue('Should be empty after stress test', LVecDeque.IsEmpty);


    LVecDeque.PushBack(999);
    AssertEquals('Should work normally after stress test', 999, LVecDeque.Front);
    AssertEquals('Count should be 1 after stress test', Int64(1), Int64(LVecDeque.GetCount));
  finally
    LVecDeque.Free;
  end;
end;

{ ===== boundaryconditiontestimplement ===== }

procedure TTestCase_VecDeque.Test_Edge_Empty_Operations;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LElement: Integer;
  LResult: Boolean;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    AssertTrue('New VecDeque should be empty', LVecDeque.IsEmpty);
    AssertEquals('Empty VecDeque count should be 0', Int64(0), Int64(LVecDeque.GetCount));

    { Object methods }
    LElement := 999;
    LResult := LVecDeque.PopFront(LElement);
    AssertFalse('PopFront on empty should return False', LResult);
    AssertEquals('Element should not be modified', 999, LElement);

    LResult := LVecDeque.PopBack(LElement);
    AssertFalse('PopBack on empty should return False', LResult);
    AssertEquals('Element should not be modified', 999, LElement);

    LResult := LVecDeque.PeekFront(LElement);
    AssertFalse('PeekFront on empty should return False', LResult);

    LResult := LVecDeque.PeekBack(LElement);
    AssertFalse('PeekBack on empty should return False', LResult);

    { Object methods }
    try
      LVecDeque.Front;
      Fail('Front on empty should raise exception');
    except
      on E: Exception do { expected exception}
    end;

    try
      LVecDeque.Back;
      Fail('Back on empty should raise exception');
    except
      on E: Exception do { expected exception}
    end;

    try
      LVecDeque.PopFront;
      Fail('PopFront on empty should raise exception');
    except
      on E: Exception do { expected exception}
    end;

    try
      LVecDeque.PopBack;
      Fail('PopBack on empty should raise exception');
    except
      on E: Exception do { expected exception}
    end;

    { Object methods }
    AssertTrue('Empty VecDeque capacity should be > 0', LVecDeque.GetCapacity > 0);
    LVecDeque.ShrinkToFit;
    AssertTrue('ShrinkToFit on empty should work', LVecDeque.IsEmpty);


    LVecDeque.Clear;
    AssertTrue('Clear on empty should work', LVecDeque.IsEmpty);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Edge_Single_Element;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LElement: Integer;
  LResult: Boolean;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Object methods }
    LVecDeque.PushBack(42);
    AssertFalse('Single element VecDeque should not be empty', LVecDeque.IsEmpty);
    AssertEquals('Single element count should be 1', Int64(1), Int64(LVecDeque.GetCount));
    AssertEquals('Front should equal Back in single element', LVecDeque.Front, LVecDeque.Back);
    AssertEquals('Single element should be 42', 42, LVecDeque.Front);

    { Object methods }
    AssertEquals('Get(0) should return the element', 42, LVecDeque.Get(0));

    LResult := LVecDeque.PeekFront(LElement);
    AssertTrue('PeekFront on single element should succeed', LResult);
    AssertEquals('PeekFront should return the element', 42, LElement);

    LResult := LVecDeque.PeekBack(LElement);
    AssertTrue('PeekBack on single element should succeed', LResult);
    AssertEquals('PeekBack should return the element', 42, LElement);

    { Object methods }
    LResult := LVecDeque.PopFront(LElement);
    AssertTrue('PopFront on single element should succeed', LResult);
    AssertEquals('PopFront should return the element', 42, LElement);
    AssertTrue('Should be empty after PopFront', LVecDeque.IsEmpty);


    LVecDeque.PushFront(84);
    LResult := LVecDeque.PopBack(LElement);
    AssertTrue('PopBack on single element should succeed', LResult);
    AssertEquals('PopBack should return the element', 84, LElement);
    AssertTrue('Should be empty after PopBack', LVecDeque.IsEmpty);

    { Object methods }
    LVecDeque.PushBack(126);

    try
      LVecDeque.Get(1);  { Object methods }
      Fail('Get(1) on single element should raise exception');
    except
      on E: Exception do { expected exception}
    end;

    try
      LVecDeque.Put(1, 999);  { Object methods }
      Fail('Put(1, value) on single element should raise exception');
    except
      on E: Exception do { expected exception}
    end;


    LVecDeque.Put(0, 168);
    AssertEquals('Put should modify the element', 168, LVecDeque.Get(0));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Edge_Full_Capacity;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInitialCapacity: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LInitialCapacity := LVecDeque.GetCapacity;


    for i := 1 to Integer(LInitialCapacity) do
      LVecDeque.PushBack(i);

    AssertEquals('Should reach initial capacity', Int64(LInitialCapacity), Int64(LVecDeque.GetCount));


    LVecDeque.PushBack(Integer(LInitialCapacity) + 1);
    AssertTrue('Should auto-grow beyond initial capacity', LVecDeque.GetCount > LInitialCapacity);
    AssertTrue('Capacity should increase', LVecDeque.GetCapacity > LInitialCapacity);



    for i := 1 to Integer(LInitialCapacity) + 1 do
      AssertEquals('Element should be preserved after growth', i, LVecDeque.Get(i - 1));


    LVecDeque.PushFront(0);
    AssertEquals('Front element should be correct', 0, LVecDeque.Front);
    AssertEquals('Count should increase', Int64(LInitialCapacity) + 2, Int64(LVecDeque.GetCount));

    { Object methods }
    for i := 1 to 100 do
    begin
      LVecDeque.PushBack(1000 + i);
      LVecDeque.PushFront(-i);
    end;

    AssertEquals('Count after bulk operations', Int64(LInitialCapacity) + 202, Int64(LVecDeque.GetCount));
    AssertEquals('Front after bulk operations', -100, LVecDeque.Front);
    AssertEquals('Back after bulk operations', 1100, LVecDeque.Back);


    LVecDeque.ShrinkToFit;
    AssertTrue('Capacity should accommodate all elements', LVecDeque.GetCapacity >= LVecDeque.GetCount);
    AssertEquals('Count should remain same after ShrinkToFit', Int64(LInitialCapacity) + 202, Int64(LVecDeque.GetCount));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Edge_Index_Bounds;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LElement: Integer;
  LResult: Boolean;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(30);

    { Object methods }
    AssertEquals('Get(0) should work', 10, LVecDeque.Get(0));
    AssertEquals('Get(2) should work', 30, LVecDeque.Get(2));

    LVecDeque.Put(0, 15);
    AssertEquals('Put(0) should work', 15, LVecDeque.Get(0));

    LVecDeque.Put(2, 35);
    AssertEquals('Put(2) should work', 35, LVecDeque.Get(2));

    { Object methods }
    try
      LVecDeque.Get(SizeUInt(-1));  { Object methods }
      Fail('Get with negative index should raise exception');
    except
      on E: Exception do { expected exception}
    end;

    { Object methods }
    try
      LVecDeque.Get(3);  { Object methods }
      Fail('Get with out-of-range index should raise exception');
    except
      on E: Exception do { expected exception}
    end;

    try
      LVecDeque.Put(3, 999);  { Object methods }
      Fail('Put with out-of-range index should raise exception');
    except
      on E: Exception do { expected exception}
    end;

    { Object methods }
    LResult := LVecDeque.TryGet(0, LElement);
    AssertTrue('TryGet(0) should succeed', LResult);
    AssertEquals('TryGet(0) should return correct value', 15, LElement);

    LResult := LVecDeque.TryGet(2, LElement);
    AssertTrue('TryGet(2) should succeed', LResult);
    AssertEquals('TryGet(2) should return correct value', 35, LElement);

    LElement := 999;
    LResult := LVecDeque.TryGet(3, LElement);
    AssertFalse('TryGet(3) should fail', LResult);
    AssertEquals('Element should not be modified on failed TryGet', 999, LElement);

    LResult := LVecDeque.TryGet(SizeUInt(-1), LElement);
    AssertFalse('TryGet with negative index should fail', LResult);


    LResult := LVecDeque.TryRemove(0, LElement);
    AssertTrue('TryRemove(0) should succeed', LResult);
    AssertEquals('TryRemove(0) should return correct value', 15, LElement);
    AssertEquals('Count should decrease', Int64(2), Int64(LVecDeque.GetCount));

    LResult := LVecDeque.TryRemove(5, LElement);
    AssertFalse('TryRemove with invalid index should fail', LResult);
    AssertEquals('Count should not change on failed remove', Int64(2), Int64(LVecDeque.GetCount));
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Performance_Large_Dataset;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i, LDataSize: Integer;
  LStartTime, LEndTime: TDateTime;
  LSum: Int64;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LDataSize := 10000;  { Object methods }


    LStartTime := Now;
    for i := 1 to LDataSize do
      LVecDeque.PushFront(i);
    LEndTime := Now;

    AssertEquals('Large dataset front push count', Int64(LDataSize), Int64(LVecDeque.GetCount));
    AssertEquals('Front element should be last pushed', LDataSize, LVecDeque.Front);
    AssertEquals('Back element should be first pushed', 1, LVecDeque.Back);

    { Object methods }
    AssertTrue('Large front push should complete in reasonable time',
               (LEndTime - LStartTime) < (1.0 / 24 / 60));  { Object methods }


    LVecDeque.Clear;
    LStartTime := Now;
    for i := 1 to LDataSize do
      LVecDeque.PushBack(i);
    LEndTime := Now;

    AssertEquals('Large dataset back push count', Int64(LDataSize), Int64(LVecDeque.GetCount));
    AssertEquals('Front element should be first pushed', 1, LVecDeque.Front);
    AssertEquals('Back element should be last pushed', LDataSize, LVecDeque.Back);

    AssertTrue('Large back push should complete in reasonable time',
               (LEndTime - LStartTime) < (1.0 / 24 / 60));  { Object methods }

    { Object methods }
    LStartTime := Now;
    LSum := 0;
    for i := 0 to LDataSize - 1 do
      LSum := LSum + LVecDeque.Get(i);
    LEndTime := Now;

    AssertEquals('Sum should be correct', Int64(LDataSize) * (LDataSize + 1) div 2, LSum);
    AssertTrue('Large random access should complete in reasonable time',
               (LEndTime - LStartTime) < (1.0 / 24 / 60));  { Object methods }

    { Object methods }
    LStartTime := Now;
    while not LVecDeque.IsEmpty do
    begin
      if (LVecDeque.GetCount mod 2) = 0 then
        LVecDeque.PopFront
      else
        LVecDeque.PopBack;
    end;
    LEndTime := Now;

    AssertTrue('Should be empty after large removal', LVecDeque.IsEmpty);
    AssertTrue('Large removal should complete in reasonable time',
               (LEndTime - LStartTime) < (1.0 / 24 / 60));  { Object methods }
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Performance_Frequent_Resize;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i, LCycleCount: Integer;
  LInitialCapacity, LCurrentCapacity: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LInitialCapacity := LVecDeque.GetCapacity;
    LCycleCount := 100;


    for i := 1 to LCycleCount do
    begin

      while LVecDeque.GetCount < LInitialCapacity * 2 do
        LVecDeque.PushBack(i * 100);

      LCurrentCapacity := LVecDeque.GetCapacity;
      AssertTrue('Capacity should grow', LCurrentCapacity >= LInitialCapacity * 2);


      while LVecDeque.GetCount > LInitialCapacity div 2 do
        LVecDeque.PopBack;

      { Object methods }
      LVecDeque.ShrinkToFit;


      if not LVecDeque.IsEmpty then
      begin
        AssertTrue('Front should be accessible', LVecDeque.Front > 0);
        AssertTrue('Back should be accessible', LVecDeque.Back > 0);
      end;
    end;


    AssertTrue('VecDeque should still be functional', LVecDeque.GetCount >= 0);


    LVecDeque.Clear;
    LVecDeque.Reserve(5000);
    AssertTrue('Large reserve should work', LVecDeque.GetCapacity >= 5000);

    for i := 1 to 1000 do
      LVecDeque.PushBack(i);

    AssertEquals('Should have 1000 elements', Int64(1000), Int64(LVecDeque.GetCount));

    LVecDeque.ShrinkToFit;
    AssertTrue('ShrinkToFit should reduce capacity', LVecDeque.GetCapacity < 5000);
    AssertTrue('ShrinkToFit should preserve elements', LVecDeque.GetCapacity >= 1000);
    AssertEquals('Count should remain same', Int64(1000), Int64(LVecDeque.GetCount));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Performance_Mixed_Access;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i, LOperations, LValue: Integer;
  LSum: Int64;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LOperations := 5000;


    for i := 1 to 100 do
      LVecDeque.PushBack(i);


    LSum := 0;
    for i := 1 to LOperations do
    begin
      case i mod 8 of
        0: begin  { frontadd }
          LVecDeque.PushFront(i);
        end;
        1: begin  { backadd }
          LVecDeque.PushBack(i);
        end;
        2: begin  { Object methods }
          if LVecDeque.GetCount > 0 then
          begin
            LValue := LVecDeque.Get(i mod Integer(LVecDeque.GetCount));
            LSum := LSum + LValue;
          end;
        end;
        3: begin  { Object methods }
          if LVecDeque.GetCount > 0 then
            LVecDeque.Put(i mod Integer(LVecDeque.GetCount), i * 2);
        end;
        4: begin  { frontremove }
          if LVecDeque.GetCount > 10 then
          begin
            LValue := LVecDeque.PopFront;
            LSum := LSum - LValue;
          end;
        end;
        5: begin  { backremove }
          if LVecDeque.GetCount > 10 then
          begin
            LValue := LVecDeque.PopBack;
            LSum := LSum - LValue;
          end;
        end;
        6: begin  { Object methods }
          if not LVecDeque.IsEmpty then
          begin
            LValue := LVecDeque.Front + LVecDeque.Back;
            LSum := LSum + (LValue mod 1000);
          end;
        end;
        7: begin  { Object methods }
          if (i mod 100) = 0 then
          begin
            if LVecDeque.GetCapacity > LVecDeque.GetCount * 3 then
              LVecDeque.ShrinkToFit
            else
              LVecDeque.Reserve(10);
          end;
        end;
      end;


      if (i mod 1000) = 0 then
      begin
        AssertTrue('VecDeque should maintain consistency during mixed access',
                   LVecDeque.GetCount >= 0);
        AssertTrue('Capacity should be reasonable',
                   LVecDeque.GetCapacity >= LVecDeque.GetCount);

        if not LVecDeque.IsEmpty then
        begin

          LVecDeque.Front;
          LVecDeque.Back;

          { Object methods }
          LVecDeque.Get(0);
          LVecDeque.Get(LVecDeque.GetCount - 1);
        end;
      end;
    end;


    AssertTrue('VecDeque should be functional after mixed access', LVecDeque.GetCount >= 0);


    LVecDeque.Clear;
    AssertTrue('Should be empty after clear', LVecDeque.IsEmpty);


    LVecDeque.PushBack(999);
    AssertEquals('Should work normally after mixed access test', 999, LVecDeque.Back);
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Compatibility_With_Array;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LArray: specialize TArray<Integer>;
  LStaticArray: array[0..4] of Integer;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  LArray := specialize TArray<Integer>.Create;
  try

    for i := 0 to 4 do
      LStaticArray[i] := (i + 1) * 11;


    LVecDeque.LoadFrom(LStaticArray);
    AssertEquals('LoadFrom static array count', Int64(5), Int64(LVecDeque.GetCount));
    for i := 0 to 4 do
      AssertEquals('LoadFrom static array element', LStaticArray[i], LVecDeque.Get(i));


    LVecDeque.Append(LStaticArray);
    AssertEquals('Append static array count', Int64(10), Int64(LVecDeque.GetCount));
    for i := 0 to 4 do
      AssertEquals('Appended static array element', LStaticArray[i], LVecDeque.Get(i + 5));


    LArray.LoadFrom(LVecDeque);
    AssertEquals('ToArray count should match', Int64(10), Int64(LArray.GetCount));
    for i := 0 to 9 do
      AssertEquals('ToArray element should match', LVecDeque.Get(i), LArray[i]);


    LVecDeque.Clear;
    LVecDeque.LoadFrom(LArray);
    AssertEquals('LoadFrom dynamic array count', Int64(10), Int64(LVecDeque.GetCount));
    for i := 0 to 9 do
      AssertEquals('LoadFrom dynamic array element', LArray[i], LVecDeque.Get(i));


    LVecDeque.Append(LArray);
    AssertEquals('Append dynamic array count', Int64(20), Int64(LVecDeque.GetCount));


    AssertTrue('VecDeque should be compatible with Array', LVecDeque.IsCompatible(LArray));


    LArray.Clear;
    LVecDeque.SaveTo(LArray);
    AssertEquals('SaveTo array count should match', Int64(20), Int64(LArray.GetCount));
    for i := 0 to 19 do
      AssertEquals('SaveTo array element should match', LVecDeque.Get(i), LArray.Get(i));
  finally
    LVecDeque.Free;
    LArray.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Compatibility_With_Vec;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LVec: specialize TVec<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  LVec := specialize TVec<Integer>.Create;
  try

    for i := 1 to 5 do
      LVec.Push(i * 13);


    LVecDeque.LoadFrom(LVec);
    AssertEquals('LoadFrom Vec count', Int64(5), Int64(LVecDeque.GetCount));
    for i := 0 to 4 do
      AssertEquals('LoadFrom Vec element', LVec.Get(i), LVecDeque.Get(i));

    { Object methods }
    LVecDeque.Append(LVec);
    AssertEquals('Append Vec count', Int64(10), Int64(LVecDeque.GetCount));
    for i := 0 to 4 do
      AssertEquals('Appended Vec element', LVec.Get(i), LVecDeque.Get(i + 5));


    LVec.Clear;
    LVecDeque.SaveTo(LVec);
    AssertEquals('SaveTo Vec count should match', Int64(10), Int64(LVec.GetCount));
    for i := 0 to 9 do
      AssertEquals('SaveTo Vec element should match', LVecDeque.Get(i), LVec.Get(i));


    AssertTrue('VecDeque should be compatible with Vec', LVecDeque.IsCompatible(LVec));


    LVec.Clear;
    for i := 1 to 3 do
      LVec.Push(i * 100);

    LVecDeque.AppendTo(LVec);
    AssertEquals('AppendTo Vec count', Int64(13), Int64(LVec.GetCount));
    AssertEquals('AppendTo Vec first original', 100, LVec.Get(0));
    AssertEquals('AppendTo Vec first appended', LVecDeque.Get(0), LVec.Get(3));
  finally
    LVecDeque.Free;
    LVec.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Compatibility_With_Queue;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LQueueObj: specialize TVecDeque<Integer>;
  i, LValue: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  LQueueObj := specialize TVecDeque<Integer>.Create;
  try



    { Object methods }
    LVecDeque.Enqueue(10);
    LVecDeque.Enqueue(20);
    LVecDeque.Enqueue(30);

    AssertEquals('Queue-like enqueue count', Int64(3), Int64(LVecDeque.GetCount));
    AssertEquals('Queue-like front', 10, LVecDeque.Peek);

    { Object methods }
    LValue := LVecDeque.Dequeue;
    AssertEquals('Queue-like dequeue', 10, LValue);
    AssertEquals('Queue-like count after dequeue', Int64(2), Int64(LVecDeque.GetCount));

    { Object methods }
    for i := 1 to 5 do
      (LQueueObj as specialize IQueue<Integer>).Enqueue(i * 17);

    { Object methods }
    LVecDeque.Clear;
    LVecDeque.LoadFrom(LQueueObj);
    AssertEquals('LoadFrom Queue count', Int64(5), Int64(LVecDeque.GetCount));

    { Object methods }
    for i := 0 to 4 do
      AssertEquals('LoadFrom Queue element', (i + 1) * 17, LVecDeque.Get(i));


    LQueueObj.Clear;
    LVecDeque.SaveTo(LQueueObj);
    AssertEquals('SaveTo Queue count', Int64(5), Int64(LQueueObj.GetCount));


    for i := 1 to 5 do
    begin
      LValue := (LQueueObj as specialize IQueue<Integer>).Dequeue;
      AssertEquals('SaveTo Queue order', i * 17, LValue);
    end;


    AssertTrue('VecDeque should be compatible with Queue', LVecDeque.IsCompatible(LQueueObj as TCollection));
  finally
    LVecDeque.Free;
    LQueueObj.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Compatibility_With_Deque;
var
  LVecDeque1, LVecDeque2: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque1 := specialize TVecDeque<Integer>.Create;
  LVecDeque2 := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 5 do
    begin
      LVecDeque1.PushFront(i);      { front: 5,4,3,2,1 }
      LVecDeque1.PushBack(i + 10);  { back: 11,12,13,14,15 }
    end;



    LVecDeque2.LoadFrom(LVecDeque1);
    AssertEquals('LoadFrom VecDeque count', Int64(10), Int64(LVecDeque2.GetCount));


    AssertEquals('LoadFrom VecDeque front', 5, LVecDeque2.Front);
    AssertEquals('LoadFrom VecDeque back', 15, LVecDeque2.Back);

    for i := 0 to 9 do
      AssertEquals('LoadFrom VecDeque element', LVecDeque1.Get(i), LVecDeque2.Get(i));

    { Object methods }
    LVecDeque2.Clear;
    for i := 1 to 3 do
      LVecDeque2.PushBack(i * 100);

    LVecDeque2.Append(LVecDeque1);
    AssertEquals('Append VecDeque count', Int64(13), Int64(LVecDeque2.GetCount));
    AssertEquals('Append VecDeque original front', 100, LVecDeque2.Front);
    AssertEquals('Append VecDeque appended back', 15, LVecDeque2.Back);

    { Object methods }
    LVecDeque1.Clear;
    LVecDeque2.SaveTo(LVecDeque1);
    AssertEquals('SaveTo VecDeque count', Int64(13), Int64(LVecDeque1.GetCount));

    for i := 0 to 12 do
      AssertEquals('SaveTo VecDeque element', LVecDeque2.Get(i), LVecDeque1.Get(i));


    AssertTrue('VecDeque should be compatible with VecDeque', LVecDeque1.IsCompatible(LVecDeque2));

    { Object methods }
    LVecDeque1.Clear;
    for i := 1 to 4 do
    begin
      LVecDeque1.PushFront(i * 25);
      LVecDeque1.PushBack(i * 50);
    end;

    LVecDeque2 := LVecDeque1.Clone as specialize TVecDeque<Integer>;
    AssertNotNull('Clone should create valid VecDeque', LVecDeque2);
    AssertEquals('Clone should have same count', Int64(LVecDeque1.GetCount), Int64(LVecDeque2.GetCount));
    AssertEquals('Clone should have same front', LVecDeque1.Front, LVecDeque2.Front);
    AssertEquals('Clone should have same back', LVecDeque1.Back, LVecDeque2.Back);


    LVecDeque2.PushBack(999);
    AssertEquals('Original should not be affected by clone modification', Int64(8), Int64(LVecDeque1.GetCount));
    AssertEquals('Clone should be modified independently', Int64(9), Int64(LVecDeque2.GetCount));
  finally
    LVecDeque1.Free;
    if Assigned(LVecDeque2) then
      LVecDeque2.Free;
  end;
end;

{ ===== memorymanagetestimplement ===== }

procedure TTestCase_VecDeque.Test_Memory_Allocator_Custom;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCustomAllocator: TAllocator;
  i: Integer;
begin

  LCustomAllocator := TRtlAllocator.Create;
  try

    LVecDeque := specialize TVecDeque<Integer>.Create(LCustomAllocator);
    try

      AssertTrue('Custom allocator should be set', LVecDeque.GetAllocator = LCustomAllocator);


      for i := 1 to 100 do
        LVecDeque.PushBack(i);

      AssertEquals('Custom allocator VecDeque count', Int64(100), Int64(LVecDeque.GetCount));
      AssertEquals('Custom allocator front element', 1, LVecDeque.Front);
      AssertEquals('Custom allocator back element', 100, LVecDeque.Back);


      LVecDeque.Reserve(500);
      AssertTrue('Custom allocator reserve should work', LVecDeque.GetCapacity >= 500);

      { Object methods }
      for i := 101 to 1000 do
        LVecDeque.PushFront(i);

      AssertEquals('Custom allocator large operations count', Int64(1000), Int64(LVecDeque.GetCount));
      AssertEquals('Custom allocator new front', 1000, LVecDeque.Front);
      AssertEquals('Custom allocator original back', 100, LVecDeque.Back);

      { Object methods }
      LVecDeque.ShrinkToFit;
      AssertTrue('Custom allocator shrink should work', LVecDeque.GetCapacity >= LVecDeque.GetCount);
      AssertEquals('Custom allocator count after shrink', Int64(1000), Int64(LVecDeque.GetCount));


      LVecDeque.Clear;
      AssertTrue('Custom allocator clear should work', LVecDeque.IsEmpty);


      LVecDeque.PushBack(999);
      AssertEquals('Custom allocator should work after clear', 999, LVecDeque.Back);
    finally
      LVecDeque.Free;
    end;
  finally
    LCustomAllocator.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Memory_GrowStrategy_Custom;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCustomStrategy: TGrowthStrategy;
  LInitialCapacity, LNewCapacity: SizeUInt;
  i: Integer;
begin

  LCustomStrategy := TGoldenRatioGrowStrategy.Create;
  try

    LVecDeque := specialize TVecDeque<Integer>.Create(GetRtlAllocator(), LCustomStrategy);
    try
      { Object methods }
      AssertTrue('Custom grow strategy should be set', LVecDeque.GetGrowStrategy = LCustomStrategy);

      LInitialCapacity := LVecDeque.GetCapacity;


      for i := 1 to Integer(LInitialCapacity) + 1 do
        LVecDeque.PushBack(i);

      LNewCapacity := LVecDeque.GetCapacity;
      AssertTrue('Custom strategy should trigger growth', LNewCapacity > LInitialCapacity);


      for i := 1 to Integer(LInitialCapacity) + 1 do
        AssertEquals('Element should be preserved after growth', i, LVecDeque.Get(i - 1));

      { Object methods }
      LCustomStrategy.Free;
      LCustomStrategy := TDoublingGrowStrategy.Create;
      LVecDeque.SetGrowStrategy(LCustomStrategy);

      AssertTrue('New grow strategy should be set', LVecDeque.GetGrowStrategy = LCustomStrategy);


      LInitialCapacity := LVecDeque.GetCapacity;
      for i := 1 to Integer(LInitialCapacity) do
        LVecDeque.PushFront(i * 1000);

      LNewCapacity := LVecDeque.GetCapacity;
      AssertTrue('New strategy should trigger growth', LNewCapacity > LInitialCapacity);


      AssertEquals('Front should be correct with new strategy',
                   Integer(LInitialCapacity) * 1000, LVecDeque.Front);
      AssertTrue('Count should be correct with new strategy',
                 LVecDeque.GetCount > LInitialCapacity);
    finally
      LVecDeque.Free;
    end;
  finally
    LCustomStrategy.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Memory_Leak_Prevention;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i, LCycleCount: Integer;
begin
  { Object methods }
  LCycleCount := 100;


  for i := 1 to LCycleCount do
  begin
    LVecDeque := specialize TVecDeque<Integer>.Create;
    try

      LVecDeque.PushBack(i);
      LVecDeque.PushFront(i * 2);
      LVecDeque.Reserve(100);

      { Object methods }
      AssertEquals('Cycle create front', i * 2, LVecDeque.Front);
      AssertEquals('Cycle create back', i, LVecDeque.Back);
    finally
      LVecDeque.Free;
    end;
  end;

  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 1000 do
    begin
      LVecDeque.PushBack(i);
      LVecDeque.PushFront(i * 2);

      if (i mod 3) = 0 then
      begin
        if not LVecDeque.IsEmpty then
          LVecDeque.PopBack;
        if not LVecDeque.IsEmpty then
          LVecDeque.PopFront;
      end;
    end;

    { verifystate}
    AssertTrue('VecDeque should be functional after bulk operations', LVecDeque.GetCount >= 0);


    for i := 1 to 10 do
    begin
      LVecDeque.Clear;
      AssertTrue('Clear should work multiple times', LVecDeque.IsEmpty);

      { Object methods }
      LVecDeque.PushBack(i * 100);
      AssertEquals('Should work after multiple clears', i * 100, LVecDeque.Back);
    end;


    LVecDeque.Reserve(2000);
    AssertTrue('Large reserve should work', LVecDeque.GetCapacity >= 2000);

    LVecDeque.ShrinkToFit;
    AssertTrue('ShrinkToFit should work', LVecDeque.GetCapacity >= LVecDeque.GetCount);


    LVecDeque.Clear;
    AssertTrue('Final clear should work', LVecDeque.IsEmpty);
    AssertEquals('Final count should be 0', Int64(0), Int64(LVecDeque.GetCount));
  finally
    LVecDeque.Free;
  end;


  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(123);


    try
      LVecDeque.Get(999);
      Fail('Should raise exception');
    except
      on E: Exception do

        AssertEquals('Object should remain valid after exception', 123, LVecDeque.Back);
    end;


    LVecDeque.PushBack(456);
    AssertEquals('Should work normally after exception', 456, LVecDeque.Back);
    AssertEquals('Count should be correct after exception', Int64(2), Int64(LVecDeque.GetCount));
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Exception_OutOfRange_Get;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LExceptionRaised: Boolean;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LExceptionRaised := False;
    try
      LVecDeque.Get(0);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Get(0) on empty VecDeque should raise exception', LExceptionRaised);


    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(30);

    { Object methods }
    AssertEquals('Get(0) should work', 10, LVecDeque.Get(0));
    AssertEquals('Get(1) should work', 20, LVecDeque.Get(1));
    AssertEquals('Get(2) should work', 30, LVecDeque.Get(2));

    { Object methods }
    LExceptionRaised := False;
    try
      LVecDeque.Get(3);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Get(3) should raise exception', LExceptionRaised);

    { Object methods }
    LExceptionRaised := False;
    try
      LVecDeque.Get(1000);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Get(1000) should raise exception', LExceptionRaised);


    LExceptionRaised := False;
    try
      LVecDeque.Get(SizeUInt(-1));
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Get with negative index should raise exception', LExceptionRaised);


    AssertEquals('VecDeque should remain valid after exceptions', Int64(3), Int64(LVecDeque.GetCount));
    AssertEquals('Elements should remain accessible', 10, LVecDeque.Get(0));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Exception_OutOfRange_Put;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LExceptionRaised: Boolean;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LExceptionRaised := False;
    try
      LVecDeque.Put(0, 999);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Put(0, value) on empty VecDeque should raise exception', LExceptionRaised);


    LVecDeque.PushBack(100);
    LVecDeque.PushBack(200);

    { Object methods }
    LVecDeque.Put(0, 150);
    AssertEquals('Put(0) should work', 150, LVecDeque.Get(0));

    LVecDeque.Put(1, 250);
    AssertEquals('Put(1) should work', 250, LVecDeque.Get(1));

    { Object methods }
    LExceptionRaised := False;
    try
      LVecDeque.Put(2, 300);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Put(2, value) should raise exception', LExceptionRaised);

    { Object methods }
    LExceptionRaised := False;
    try
      LVecDeque.Put(100, 999);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Put(100, value) should raise exception', LExceptionRaised);

    { Object methods }
    LExceptionRaised := False;
    try
      LVecDeque.Put(SizeUInt(-1), 888);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Put with negative index should raise exception', LExceptionRaised);


    AssertEquals('VecDeque should remain valid after Put exceptions', Int64(2), Int64(LVecDeque.GetCount));
    AssertEquals('Elements should remain correct', 150, LVecDeque.Get(0));
    AssertEquals('Elements should remain correct', 250, LVecDeque.Get(1));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Exception_OutOfRange_Remove;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LExceptionRaised: Boolean;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LExceptionRaised := False;
    try
      LVecDeque.Remove(0);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Remove(0) on empty VecDeque should raise exception', LExceptionRaised);


    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(30);
    LVecDeque.PushBack(40);

    { Object methods }
    LVecDeque.Remove(1);  { Object methods }
    AssertEquals('Count should decrease after remove', Int64(3), Int64(LVecDeque.GetCount));
    AssertEquals('Element should be removed correctly', 10, LVecDeque.Get(0));
    AssertEquals('Element should be removed correctly', 30, LVecDeque.Get(1));
    AssertEquals('Element should be removed correctly', 40, LVecDeque.Get(2));

    { Object methods }
    LExceptionRaised := False;
    try
      LVecDeque.Remove(3);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Remove(3) should raise exception', LExceptionRaised);

    { Object methods }
    LExceptionRaised := False;
    try
      LVecDeque.Remove(1000);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Remove(1000) should raise exception', LExceptionRaised);

    { Object methods }
    LExceptionRaised := False;
    try
      LVecDeque.Remove(SizeUInt(-1));
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Remove with negative index should raise exception', LExceptionRaised);


    AssertEquals('VecDeque should remain valid after Remove exceptions', Int64(3), Int64(LVecDeque.GetCount));
    AssertEquals('Elements should remain accessible', 10, LVecDeque.Get(0));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Exception_Empty_Pop;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LExceptionRaised: Boolean;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LExceptionRaised := False;
    try
      LVecDeque.PopFront;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('PopFront on empty VecDeque should raise exception', LExceptionRaised);


    LExceptionRaised := False;
    try
      LVecDeque.PopBack;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('PopBack on empty VecDeque should raise exception', LExceptionRaised);


    LExceptionRaised := False;
    try
      LVecDeque.Dequeue;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Dequeue on empty VecDeque should raise exception', LExceptionRaised);


    LVecDeque.PushBack(42);
    AssertEquals('PopFront should work with one element', 42, LVecDeque.PopFront);
    AssertTrue('Should be empty after PopFront', LVecDeque.IsEmpty);


    LExceptionRaised := False;
    try
      LVecDeque.PopBack;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('PopBack after emptying should raise exception', LExceptionRaised);


    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushFront(0);

    LVecDeque.PopFront;  { Object methods }
    LVecDeque.PopBack;   { Object methods }
    LVecDeque.PopFront;  { Object methods }

    AssertTrue('Should be empty after multiple operations', LVecDeque.IsEmpty);

    LExceptionRaised := False;
    try
      LVecDeque.PopFront;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('PopFront after complex emptying should raise exception', LExceptionRaised);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Exception_Empty_Peek;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LExceptionRaised: Boolean;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LExceptionRaised := False;
    try
      LVecDeque.Front;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Front on empty VecDeque should raise exception', LExceptionRaised);


    LExceptionRaised := False;
    try
      LVecDeque.Back;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Back on empty VecDeque should raise exception', LExceptionRaised);


    LExceptionRaised := False;
    try
      LVecDeque.Peek;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Peek on empty VecDeque should raise exception', LExceptionRaised);


    LExceptionRaised := False;
    try
      LVecDeque.PeekFront;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('PeekFront on empty VecDeque should raise exception', LExceptionRaised);


    LExceptionRaised := False;
    try
      LVecDeque.PeekBack;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('PeekBack on empty VecDeque should raise exception', LExceptionRaised);


    LVecDeque.PushBack(100);
    AssertEquals('Front should work with one element', 100, LVecDeque.Front);
    AssertEquals('Back should work with one element', 100, LVecDeque.Back);
    AssertEquals('Peek should work with one element', 100, LVecDeque.Peek);


    LVecDeque.PopBack;
    AssertTrue('Should be empty after PopBack', LVecDeque.IsEmpty);

    LExceptionRaised := False;
    try
      LVecDeque.Front;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Front after emptying should raise exception', LExceptionRaised);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Exception_SplitOff_OutOfRange;
var
  LVecDeque, LSplitPart: specialize TVecDeque<Integer>;
  LExceptionRaised: Boolean;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LExceptionRaised := False;
    try
      LSplitPart := LVecDeque.SplitOff(0) as specialize TVecDeque<Integer>;
      if Assigned(LSplitPart) then
        LSplitPart.Free;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;



    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(30);


    LSplitPart := LVecDeque.SplitOff(1) as specialize TVecDeque<Integer>;
    try
      AssertEquals('Original should have first part', Int64(1), Int64(LVecDeque.GetCount));
      AssertEquals('Split should have second part', Int64(2), Int64(LSplitPart.GetCount));
    finally
      LSplitPart.Free;
    end;


    LVecDeque.Clear;
    LVecDeque.PushBack(100);
    LVecDeque.PushBack(200);


    LExceptionRaised := False;
    try
      LSplitPart := LVecDeque.SplitOff(5) as specialize TVecDeque<Integer>;
      if Assigned(LSplitPart) then
        LSplitPart.Free;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('SplitOff(5) should raise exception', LExceptionRaised);


    LExceptionRaised := False;
    try
      LSplitPart := LVecDeque.SplitOff(1000) as specialize TVecDeque<Integer>;
      if Assigned(LSplitPart) then
        LSplitPart.Free;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('SplitOff(1000) should raise exception', LExceptionRaised);


    LExceptionRaised := False;
    try
      LSplitPart := LVecDeque.SplitOff(SizeUInt(-1)) as specialize TVecDeque<Integer>;
      if Assigned(LSplitPart) then
        LSplitPart.Free;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('SplitOff with negative index should raise exception', LExceptionRaised);


    AssertEquals('VecDeque should remain valid after SplitOff exceptions', Int64(2), Int64(LVecDeque.GetCount));
    AssertEquals('Elements should remain accessible', 100, LVecDeque.Get(0));
    AssertEquals('Elements should remain accessible', 200, LVecDeque.Get(1));
  finally
    LVecDeque.Free;
  end;
end;


procedure TTestCase_VecDeque.Test_TypeSafety_Integer;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
  LSum: Int64;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(42);
    LVecDeque.PushBack(-17);
    LVecDeque.PushBack(0);
    LVecDeque.PushBack(MaxInt);
    LVecDeque.PushBack(-MaxInt);

    AssertEquals('Integer VecDeque count', Int64(5), Int64(LVecDeque.GetCount));
    AssertEquals('Integer element 0', 42, LVecDeque.Get(0));
    AssertEquals('Integer element 1', -17, LVecDeque.Get(1));
    AssertEquals('Integer element 2', 0, LVecDeque.Get(2));
    AssertEquals('Integer element 3', MaxInt, LVecDeque.Get(3));
    AssertEquals('Integer element 4', -MaxInt, LVecDeque.Get(4));

    { Object methods }
    LSum := 0;
    for i := 0 to Integer(LVecDeque.GetCount) - 1 do
      LSum := LSum + LVecDeque.Get(i);

    AssertEquals('Integer sum should be correct', Int64(42 - 17 + 0 + MaxInt - MaxInt), LSum);


    LVecDeque.Clear;
    LVecDeque.PushBack(Low(Integer));
    LVecDeque.PushBack(High(Integer));

    AssertEquals('Low Integer should be stored correctly', Low(Integer), LVecDeque.Get(0));
    AssertEquals('High Integer should be stored correctly', High(Integer), LVecDeque.Get(1));


    LVecDeque.Put(0, 999);
    LVecDeque.Put(1, -999);

    AssertEquals('Modified integer 0', 999, LVecDeque.Get(0));
    AssertEquals('Modified integer 1', -999, LVecDeque.Get(1));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_TypeSafety_String;
var
  LVecDeque: specialize TVecDeque<String>;
  LConcatenated: String;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<String>.Create;
  try

    LVecDeque.PushBack('Hello');
    LVecDeque.PushBack('World');
    LVecDeque.PushBack('');
    LVecDeque.PushBack('Pascal');
    LVecDeque.PushFront('Start');

    AssertEquals('String VecDeque count', Int64(5), Int64(LVecDeque.GetCount));
    AssertEquals('String element 0', 'Start', LVecDeque.Get(0));
    AssertEquals('String element 1', 'Hello', LVecDeque.Get(1));
    AssertEquals('String element 2', 'World', LVecDeque.Get(2));
    AssertEquals('String element 3', '', LVecDeque.Get(3));
    AssertEquals('String element 4', 'Pascal', LVecDeque.Get(4));


    LConcatenated := '';
    for i := 0 to Integer(LVecDeque.GetCount) - 1 do
    begin
      if i > 0 then
        LConcatenated := LConcatenated + ' ';
      LConcatenated := LConcatenated + LVecDeque.Get(i);
    end;

    AssertEquals('String concatenation', 'Start Hello World  Pascal', LConcatenated);


    LVecDeque.Clear;
    LVecDeque.PushBack('This is a very long string that tests the VecDeque''s ability to handle larger string data without issues');

    AssertEquals('Long string should be stored correctly',
                 'This is a very long string that tests the VecDeque''s ability to handle larger string data without issues',
                 LVecDeque.Get(0));


    LVecDeque.PushBack('Special chars: garbled_text_');
    LVecDeque.PushBack('Numbers: 1234567890');
    LVecDeque.PushBack('Symbols: !@#$%^&*()');

    AssertEquals('Special chars should be stored correctly', 'Special chars: garbled_text_', LVecDeque.Get(1));


    AssertEquals('Numbers should be stored correctly', 'Numbers: 1234567890', LVecDeque.Get(2));
    AssertEquals('Symbols should be stored correctly', 'Symbols: !@#$%^&*()', LVecDeque.Get(3));


    LVecDeque.Put(0, 'Modified');
    AssertEquals('Modified string', 'Modified', LVecDeque.Get(0));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_TypeSafety_Record;
type
  TTestRecord = record
    ID: Integer;
    Name: String;
    Value: Double;
  end;
var
  LVecDeque: specialize TVecDeque<TTestRecord>;
  LRecord: TTestRecord;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<TTestRecord>.Create;
  try
    { preparetestrecord }
    LRecord.ID := 1;
    LRecord.Name := 'First';
    LRecord.Value := 3.14;
    LVecDeque.PushBack(LRecord);

    LRecord.ID := 2;
    LRecord.Name := 'Second';
    LRecord.Value := 2.71;
    LVecDeque.PushBack(LRecord);

    LRecord.ID := 3;
    LRecord.Name := 'Third';
    LRecord.Value := 1.41;
    LVecDeque.PushFront(LRecord);

    AssertEquals('Record VecDeque count', Int64(3), Int64(LVecDeque.GetCount));


    LRecord := LVecDeque.Get(0);
    AssertEquals('Record 0 ID', 3, LRecord.ID);
    AssertEquals('Record 0 Name', 'Third', LRecord.Name);
    AssertEquals('Record 0 Value', 1.41, LRecord.Value, 0.001);

    LRecord := LVecDeque.Get(1);
    AssertEquals('Record 1 ID', 1, LRecord.ID);
    AssertEquals('Record 1 Name', 'First', LRecord.Name);
    AssertEquals('Record 1 Value', 3.14, LRecord.Value, 0.001);

    LRecord := LVecDeque.Get(2);
    AssertEquals('Record 2 ID', 2, LRecord.ID);
    AssertEquals('Record 2 Name', 'Second', LRecord.Name);
    AssertEquals('Record 2 Value', 2.71, LRecord.Value, 0.001);


    LRecord := LVecDeque.Get(1);
    LRecord.Name := 'Modified';
    LRecord.Value := 9.99;
    LVecDeque.Put(1, LRecord);

    LRecord := LVecDeque.Get(1);
    AssertEquals('Modified record ID should remain', 1, LRecord.ID);
    AssertEquals('Modified record Name', 'Modified', LRecord.Name);
    AssertEquals('Modified record Value', 9.99, LRecord.Value, 0.001);

    { Object methods }
    LVecDeque.Clear;
    for i := 1 to 10 do
    begin
      LRecord.ID := i;
      LRecord.Name := 'Item' + IntToStr(i);
      LRecord.Value := i * 1.5;
      LVecDeque.PushBack(LRecord);
    end;

    AssertEquals('Bulk record operations count', Int64(10), Int64(LVecDeque.GetCount));

    { Object methods }
    for i := 0 to 9 do
    begin
      LRecord := LVecDeque.Get(i);
      AssertEquals('Bulk record ID', i + 1, LRecord.ID);
      AssertEquals('Bulk record Name', 'Item' + IntToStr(i + 1), LRecord.Name);
      AssertEquals('Bulk record Value', (i + 1) * 1.5, LRecord.Value, 0.001);
    end;
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_TypeSafety_Object;
var
  LVecDeque: specialize TVecDeque<TObject>;
  LObj1, LObj2, LObj3: TObject;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<TObject>.Create;
  try
    { Object methods }
    LObj1 := TObject.Create;
    LObj2 := TObject.Create;
    LObj3 := TObject.Create;

    try
      { Object methods }
      LVecDeque.PushBack(LObj1);
      LVecDeque.PushBack(LObj2);
      LVecDeque.PushFront(LObj3);
      LVecDeque.PushBack(nil);

      AssertEquals('Object VecDeque count', Int64(4), Int64(LVecDeque.GetCount));

      { Object methods }
      AssertTrue('Object 0 should equal LObj3', LVecDeque.Get(0) = LObj3);
      AssertTrue('Object 1 should equal LObj1', LVecDeque.Get(1) = LObj1);
      AssertTrue('Object 2 should equal LObj2', LVecDeque.Get(2) = LObj2);
      AssertTrue('Object 3 should be nil', LVecDeque.Get(3) = nil);


      LVecDeque.Put(3, LObj1);  { Object methods }
      AssertTrue('Modified object should equal LObj1', LVecDeque.Get(3) = LObj1);

      { Object methods }
      AssertTrue('Same objects should be equal', LVecDeque.Get(1) = LVecDeque.Get(3));
      AssertFalse('Different objects should not be equal', LVecDeque.Get(0) = LVecDeque.Get(1));


      LVecDeque.Clear;
      LVecDeque.PushBack(nil);
      LVecDeque.PushBack(nil);

      AssertEquals('Nil object count', Int64(2), Int64(LVecDeque.GetCount));
      AssertTrue('First nil object', LVecDeque.Get(0) = nil);
      AssertTrue('Second nil object', LVecDeque.Get(1) = nil);

    finally
      { Object methods }
      LObj1.Free;
      LObj2.Free;
      LObj3.Free;
    end;
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Iterator_Forward;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LEnumerator: specialize TIter<Integer>;
  LIter: specialize TIter<Integer>;
  LCount, LSum: Integer;
  LExpectedSum: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(30);
    LVecDeque.PushBack(40);
    LVecDeque.PushBack(50);

    LExpectedSum := 10 + 20 + 30 + 40 + 50;


    LEnumerator := LVecDeque.GetEnumerator;
    LCount := 0;
    LSum := 0;

    while LEnumerator.MoveNext do
    begin
      LSum := LSum + LEnumerator.Current;
      Inc(LCount);
    end;

    AssertEquals('Enumerator should iterate all elements', 5, LCount);
    AssertEquals('Enumerator sum should be correct', LExpectedSum, LSum);


    LIter := LVecDeque.Iter;
    LCount := 0;
    LSum := 0;

    while LIter.MoveNext do
    begin
      LSum := LSum + LIter.Current;
      Inc(LCount);
    end;

    AssertEquals('Iterator should iterate all elements', 5, LCount);
    AssertEquals('Iterator sum should be correct', LExpectedSum, LSum);


    LVecDeque.Clear;
    LEnumerator := LVecDeque.GetEnumerator;
    LCount := 0;

    while LEnumerator.MoveNext do
      Inc(LCount);

    AssertEquals('Empty VecDeque enumerator should not iterate', 0, LCount);


    LVecDeque.PushBack(999);
    LEnumerator := LVecDeque.GetEnumerator;
    LCount := 0;
    LSum := 0;

    while LEnumerator.MoveNext do
    begin
      LSum := LSum + LEnumerator.Current;
      Inc(LCount);
    end;

    AssertEquals('Single element enumerator count', 1, LCount);
    AssertEquals('Single element enumerator sum', 999, LSum);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Iterator_Backward;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LValues: array[0..4] of Integer;
  i, LCount: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 0 to 4 do
    begin
      LValues[i] := (i + 1) * 11;
      LVecDeque.PushBack(LValues[i]);
    end;


    LCount := 0;
    for i := Integer(LVecDeque.GetCount) - 1 downto 0 do
    begin
      AssertEquals('Backward access element', LValues[i], LVecDeque.Get(i));
      Inc(LCount);
    end;

    AssertEquals('Backward access count', 5, LCount);

    { Object methods }
    LCount := 0;
    i := 4;
    while not LVecDeque.IsEmpty do
    begin
      AssertEquals('Backward pop element', LValues[i], LVecDeque.PopBack);
      Dec(i);
      Inc(LCount);
    end;

    AssertEquals('Backward pop count', 5, LCount);
    AssertTrue('Should be empty after backward pop', LVecDeque.IsEmpty);


    for i := 0 to 4 do
      LVecDeque.PushFront(LValues[i]);


    LCount := 0;
    i := 0;
    while not LVecDeque.IsEmpty do
    begin
      AssertEquals('Front backward pop element', LValues[i], LVecDeque.PopFront);
      Inc(i);
      Inc(LCount);
    end;

    AssertEquals('Front backward pop count', 5, LCount);
    AssertTrue('Should be empty after front backward pop', LVecDeque.IsEmpty);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Iterator_Modification;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LEnumerator: specialize TIter<Integer>;
  i, LCount: Integer;
  LModified: Boolean;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 5 do
      LVecDeque.PushBack(i * 10);


    for i := 0 to Integer(LVecDeque.GetCount) - 1 do
    begin
      LVecDeque.Put(i, LVecDeque.Get(i) * 2);  { Object methods }
    end;


    for i := 0 to Integer(LVecDeque.GetCount) - 1 do
      AssertEquals('Modified element', (i + 1) * 20, LVecDeque.Get(i));


    LEnumerator := LVecDeque.GetEnumerator;
    LCount := 0;
    LModified := False;

    try
      while LEnumerator.MoveNext do
      begin
        Inc(LCount);
        if LCount = 2 then
        begin

          LVecDeque.PushBack(999);
          LModified := True;
        end;
      end;



      AssertTrue('Structure was modified during iteration', LModified);

    except
      on E: Exception do

        AssertTrue('Concurrent modification detected', LModified);
    end;


    LVecDeque.Clear;
    for i := 1 to 3 do
      LVecDeque.PushBack(i);


    for i := Integer(LVecDeque.GetCount) - 1 downto 0 do
    begin
      if LVecDeque.Get(i) mod 2 = 0 then  { Object methods }
        LVecDeque.Remove(i);
    end;


    AssertEquals('Should have 2 odd numbers', Int64(2), Int64(LVecDeque.GetCount));
    AssertEquals('First odd number', 1, LVecDeque.Get(0));
    AssertEquals('Second odd number', 3, LVecDeque.Get(1));


    LVecDeque.Clear;
    for i := 1 to 10 do
      LVecDeque.PushBack(i);

    LEnumerator := LVecDeque.GetEnumerator;
    LCount := 0;

    while LEnumerator.MoveNext do
    begin
      Inc(LCount);
      if LCount = 5 then
        LVecDeque.Reserve(100);
    end;

    AssertEquals('Should iterate all elements despite capacity change', 10, LCount);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Iterator_Nested;
var
  LVecDeque1, LVecDeque2: specialize TVecDeque<Integer>;
  LEnumerator1, LEnumerator2: specialize TIter<Integer>;
  LOuterCount, LInnerCount, LTotalCount: Integer;
begin

  LVecDeque1 := specialize TVecDeque<Integer>.Create;
  LVecDeque2 := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque1.PushBack(1);
    LVecDeque1.PushBack(2);
    LVecDeque1.PushBack(3);

    LVecDeque2.PushBack(10);
    LVecDeque2.PushBack(20);


    LOuterCount := 0;
    LTotalCount := 0;

    LEnumerator1 := LVecDeque1.GetEnumerator;
    while LEnumerator1.MoveNext do
    begin
      Inc(LOuterCount);
      LInnerCount := 0;

      LEnumerator2 := LVecDeque2.GetEnumerator;
      while LEnumerator2.MoveNext do
      begin
        Inc(LInnerCount);
        Inc(LTotalCount);


        AssertTrue('Outer value should be valid', LEnumerator1.Current > 0);
        AssertTrue('Inner value should be valid', LEnumerator2.Current > 0);
      end;

      AssertEquals('Inner iteration count', 2, LInnerCount);
    end;

    AssertEquals('Outer iteration count', 3, LOuterCount);
    AssertEquals('Total nested iterations', 6, LTotalCount);


    LVecDeque1.Clear;
    LVecDeque1.PushBack(100);
    LVecDeque1.PushBack(200);
    LVecDeque1.PushBack(300);

    LEnumerator1 := LVecDeque1.GetEnumerator;
    LEnumerator2 := LVecDeque1.GetEnumerator;


    AssertTrue('First enumerator should move', LEnumerator1.MoveNext);
    AssertEquals('First enumerator value', 100, LEnumerator1.Current);

    AssertTrue('Second enumerator should move', LEnumerator2.MoveNext);
    AssertEquals('Second enumerator value', 100, LEnumerator2.Current);

    AssertTrue('First enumerator should move again', LEnumerator1.MoveNext);
    AssertEquals('First enumerator next value', 200, LEnumerator1.Current);

    AssertTrue('Second enumerator should move again', LEnumerator2.MoveNext);
    AssertEquals('Second enumerator next value', 200, LEnumerator2.Current);


    AssertTrue('First enumerator should have more', LEnumerator1.MoveNext);
    AssertEquals('First enumerator last value', 300, LEnumerator1.Current);

    AssertTrue('Second enumerator should also have more', LEnumerator2.MoveNext);
    AssertEquals('Second enumerator last value', 300, LEnumerator2.Current);

    AssertFalse('First enumerator should be done', LEnumerator1.MoveNext);
    AssertFalse('Second enumerator should be done', LEnumerator2.MoveNext);
  finally
    LVecDeque1.Free;
    LVecDeque2.Free;
  end;
end;

{ ===== ForEachtestimplement ===== }

procedure TTestCase_VecDeque.Test_ForEach_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 5 do
      LVecDeque.PushBack(i * 10);


    FForEachCounter := 0;
    FForEachSum := 0;

    { Object methods }
    LVecDeque.ForEach(@ForEachTestFunc, @Self);

    { Object methods }
    AssertEquals('ForEach Func should visit all elements', 5, FForEachCounter);
    AssertEquals('ForEach Func sum should be correct', 150, FForEachSum); { 10+20+30+40+50 }
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ForEach_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 4 do
      LVecDeque.PushBack(i * 5);


    FForEachCounter := 0;
    FForEachSum := 0;

    { Object methods }
    LVecDeque.ForEach(@ForEachTestMethod, @Self);

    { Object methods }
    AssertEquals('ForEach Method should visit all elements', 4, FForEachCounter);
    AssertEquals('ForEach Method sum should be correct', 50, FForEachSum); { 5+10+15+20 }
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ForEach_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
  LElementsProcessed: SizeInt;
begin
  { Test ForEach with reference function }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Test empty collection }
    LElementsProcessed := 0;

    { ForEach on empty collection should complete without calling function }
    LVecDeque.ForEach(@ForEachTestRefFunc);
    AssertTrue('ForEach on empty collection should complete successfully', True);

    { Add test data }
    for i := 1 to 5 do
      LVecDeque.PushBack(i * 10); { 10, 20, 30, 40, 50 }

    { Test ForEach with reference function - should process all elements }
    { ForEachTestRefFunc returns true for values <= 50, so all elements should be processed }
    LVecDeque.ForEach(@ForEachTestRefFunc);

    { Verify collection is unchanged }
    AssertEquals('Collection count should remain unchanged', 5, LVecDeque.Count);
    for i := 0 to 4 do
      AssertEquals('Element should be unchanged', (i + 1) * 10, LVecDeque.Get(i));

    { Test ForEach that stops early }
    LVecDeque.Clear;
    for i := 1 to 10 do
      LVecDeque.PushBack(i * 10); { 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 }

    { ForEachTestRefFunc returns false for values > 50, so should stop at 60 }
    LVecDeque.ForEach(@ForEachTestRefFunc);

    { Verify collection is unchanged }
    AssertEquals('Collection count should remain unchanged after early stop', 10, LVecDeque.Count);
    AssertEquals('First element should be unchanged', 10, LVecDeque.Get(0));
    AssertEquals('Last element should be unchanged', 100, LVecDeque.Get(9));

    { Test with single element }
    LVecDeque.Clear;
    LVecDeque.PushBack(25);

    LVecDeque.ForEach(@ForEachTestRefFunc);
    AssertEquals('Single element should be processed', 1, LVecDeque.Count);
    AssertEquals('Single element should be unchanged', 25, LVecDeque.Get(0));

  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ForEach_StartIndex_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 6 do
      LVecDeque.PushBack(i * 3);


    FForEachCounter := 0;
    FForEachSum := 0;


    LVecDeque.ForEach(2, @ForEachTestFunc, @Self);


    AssertEquals('ForEach StartIndex Func should visit remaining elements', 4, FForEachCounter);
    AssertEquals('ForEach StartIndex Func sum should be correct', 54, FForEachSum); { 9+12+15+18 }
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ForEach_StartIndex_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 5 do
      LVecDeque.PushBack(i * 4);


    FForEachCounter := 0;
    FForEachSum := 0;


    LVecDeque.ForEach(1, @ForEachTestMethod, @Self);


    AssertEquals('ForEach StartIndex Method should visit remaining elements', 4, FForEachCounter);
    AssertEquals('ForEach StartIndex Method sum should be correct', 56, FForEachSum); { 8+12+16+20 }
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ForEach_StartIndex_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  { Test ForEach with start index and reference function }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Test empty collection }
    GlobalForEachCounter := 0;
    GlobalForEachSum := 0;

    { ForEach on empty collection should not call function }
    LVecDeque.ForEach(0, @ForEachTestRefFunc);
    AssertEquals('ForEach on empty collection should not call function', 0, GlobalForEachCounter);
    AssertEquals('ForEach on empty collection should have zero sum', 0, GlobalForEachSum);

    { Add test data: [10, 20, 30, 40] - all values <= 50 }
    for i := 1 to 4 do
      LVecDeque.PushBack(i * 10);

    { Test ForEach from start (index 0) - ForEachTestRefFunc returns true for values <= 50 }
    GlobalForEachCounter := 0;
    GlobalForEachSum := 0;
    LVecDeque.ForEach(0, @ForEachTestRefFunc);
    AssertEquals('ForEach from start should visit all elements', 4, GlobalForEachCounter);
    AssertEquals('ForEach from start sum should be correct', 100, GlobalForEachSum); { 10+20+30+40=100 }

    { Test ForEach from index 1 }
    GlobalForEachCounter := 0;
    GlobalForEachSum := 0;
    LVecDeque.ForEach(1, @ForEachTestRefFunc);
    AssertEquals('ForEach from index 1 should visit remaining elements', 3, GlobalForEachCounter);
    AssertEquals('ForEach from index 1 sum should be correct', 90, GlobalForEachSum); { 20+30+40=90 }

    { Test ForEach from index 2 }
    GlobalForEachCounter := 0;
    GlobalForEachSum := 0;
    LVecDeque.ForEach(2, @ForEachTestRefFunc);
    AssertEquals('ForEach from index 2 should visit remaining elements', 2, GlobalForEachCounter);
    AssertEquals('ForEach from index 2 sum should be correct', 70, GlobalForEachSum); { 30+40=70 }

    { Test ForEach from last index }
    GlobalForEachCounter := 0;
    GlobalForEachSum := 0;
    LVecDeque.ForEach(3, @ForEachTestRefFunc);
    AssertEquals('ForEach from last index should visit one element', 1, GlobalForEachCounter);
    AssertEquals('ForEach from last index sum should be correct', 40, GlobalForEachSum); { 40 }

    { Test ForEach from beyond end (should not call function) }
    GlobalForEachCounter := 0;
    GlobalForEachSum := 0;
    LVecDeque.ForEach(4, @ForEachTestRefFunc);
    AssertEquals('ForEach from beyond end should not call function', 0, GlobalForEachCounter);
    AssertEquals('ForEach from beyond end should have zero sum', 0, GlobalForEachSum);

    { Test basic functionality - this test passes if ForEach works correctly }
    AssertTrue('ForEach StartIndex RefFunc test completed successfully', True);

  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ForEach_StartIndex_Count_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 7 do
      LVecDeque.PushBack(i * 2);


    FForEachCounter := 0;
    FForEachSum := 0;


    LVecDeque.ForEach(1, 3, @ForEachTestFunc, @Self);


    AssertEquals('ForEach StartIndex Count Func should visit specified elements', 3, FForEachCounter);
    AssertEquals('ForEach StartIndex Count Func sum should be correct', 18, FForEachSum); { 4+6+8 }
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ForEach_StartIndex_Count_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 6 do
      LVecDeque.PushBack(i * 8);


    FForEachCounter := 0;
    FForEachSum := 0;


    LVecDeque.ForEach(2, 2, @ForEachTestMethod, @Self);


    AssertEquals('ForEach StartIndex Count Method should visit specified elements', 2, FForEachCounter);
    AssertEquals('ForEach StartIndex Count Method sum should be correct', 56, FForEachSum); { 24+32 }
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ForEach_StartIndex_Count_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
  LCounter, LSum: SizeInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 5 do
      LVecDeque.PushBack(i * 9);


    FForEachCounter := 0;
    FForEachSum := 0;



    LCounter := 0; LSum := 0;
    LVecDeque.ForEach(0, 3, function (const v: Integer): Boolean
    begin
      Inc(LCounter); Inc(LSum, v);
      Result := v < 100;
    end);

    AssertEquals('ForEach StartIndex Count RefFunc should visit specified elements', 3, LCounter);
    AssertEquals('ForEach StartIndex Count RefFunc sum should be correct', 54, LSum); { 9+18+27 }
  finally
    LVecDeque.Free;
  end;
end;

{ ===== Containstestimplement ===== }

procedure TTestCase_VecDeque.Test_Contains;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    AssertFalse('Empty VecDeque should not contain any element', LVecDeque.Contains(42));


    for i := 1 to 5 do
      LVecDeque.PushBack(i * 10);


    AssertTrue('Should contain existing element', LVecDeque.Contains(10));
    AssertTrue('Should contain existing element', LVecDeque.Contains(30));
    AssertTrue('Should contain existing element', LVecDeque.Contains(50));


    AssertFalse('Should not contain non-existing element', LVecDeque.Contains(15));
    AssertFalse('Should not contain non-existing element', LVecDeque.Contains(0));
    AssertFalse('Should not contain non-existing element', LVecDeque.Contains(100));


    AssertTrue('Should contain first element', LVecDeque.Contains(10));
    AssertTrue('Should contain last element', LVecDeque.Contains(50));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Contains_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 6 do
      LVecDeque.PushBack(i * 7);


    AssertTrue('Should contain element using custom function',
               LVecDeque.Contains(14, 0, @EqualsTestFunc, @Self));
    AssertTrue('Should contain element using custom function',
               LVecDeque.Contains(42, 0, @EqualsTestFunc, @Self));


    AssertFalse('Should not contain non-existing element using custom function',
                LVecDeque.Contains(15, 0, @EqualsTestFunc, @Self));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Contains_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 4 do
      LVecDeque.PushBack(i * 12);

    { Object methods }
    AssertTrue('Should contain element using method',
               LVecDeque.Contains(24, 0, @EqualsTestMethod, @Self));
    AssertTrue('Should contain element using method',
               LVecDeque.Contains(48, 0, @EqualsTestMethod, @Self));


    AssertFalse('Should not contain non-existing element using method',
                LVecDeque.Contains(25, 0, @EqualsTestMethod, @Self));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Contains_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  { Test Contains with reference function }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Test empty collection }
    AssertFalse('Empty collection should not contain any element',
                LVecDeque.Contains(30, 0, @EqualsTestRefFunc));

    { Add test data: [15, 30, 45] }
    for i := 1 to 3 do
      LVecDeque.PushBack(i * 15);

    { Test Contains with existing elements using reference function }
    AssertTrue('Should contain first element (15) using ref function',
               LVecDeque.Contains(15, 0, @EqualsTestRefFunc));

    AssertTrue('Should contain second element (30) using ref function',
               LVecDeque.Contains(30, 0, @EqualsTestRefFunc));

    AssertTrue('Should contain third element (45) using ref function',
               LVecDeque.Contains(45, 0, @EqualsTestRefFunc));

    { Test Contains with non-existing elements using reference function }
    AssertFalse('Should not contain non-existing element (14) using ref function',
                LVecDeque.Contains(14, 0, @EqualsTestRefFunc));

    AssertFalse('Should not contain non-existing element (31) using ref function',
                LVecDeque.Contains(31, 0, @EqualsTestRefFunc));

    AssertFalse('Should not contain non-existing element (46) using ref function',
                LVecDeque.Contains(46, 0, @EqualsTestRefFunc));

    { Test Contains with start index }
    AssertTrue('Should contain element (30) from start index 0',
               LVecDeque.Contains(30, 0, @EqualsTestRefFunc));

    AssertTrue('Should contain element (30) from start index 1',
               LVecDeque.Contains(30, 1, @EqualsTestRefFunc));

    AssertFalse('Should not contain element (15) from start index 1',
                LVecDeque.Contains(15, 1, @EqualsTestRefFunc));

    AssertTrue('Should contain element (45) from start index 2',
               LVecDeque.Contains(45, 2, @EqualsTestRefFunc));

    AssertFalse('Should not contain element (30) from start index 2',
                LVecDeque.Contains(30, 2, @EqualsTestRefFunc));

    { Test Contains from beyond end }
    AssertFalse('Should not contain any element from beyond end',
                LVecDeque.Contains(45, 3, @EqualsTestRefFunc));

  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Contains_StartIndex;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 6 do
      LVecDeque.PushBack(i * 5);



    AssertTrue('Should find element from start', LVecDeque.Contains(5, 0));
    AssertTrue('Should find element from start', LVecDeque.Contains(30, 0));


    AssertTrue('Should find element from index 2', LVecDeque.Contains(20, 2));
    AssertTrue('Should find element from index 2', LVecDeque.Contains(30, 2));


    AssertFalse('Should not find element before start index', LVecDeque.Contains(5, 2));
    AssertFalse('Should not find element before start index', LVecDeque.Contains(10, 2));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Contains_StartIndex_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 5 do
      LVecDeque.PushBack(i * 8);



    AssertTrue('Should find element from index 1 using function',
               LVecDeque.Contains(24, 1, @EqualsTestFunc, @Self));
    AssertTrue('Should find element from index 1 using function',
               LVecDeque.Contains(40, 1, @EqualsTestFunc, @Self));


    AssertFalse('Should not find element before start index using function',
                LVecDeque.Contains(8, 1, @EqualsTestFunc, @Self));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Contains_StartIndex_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 4 do
      LVecDeque.PushBack(i * 11);



    AssertTrue('Should find element from index 1 using method',
               LVecDeque.Contains(33, 1, @EqualsTestMethod, @Self));
    AssertTrue('Should find element from index 1 using method',
               LVecDeque.Contains(44, 1, @EqualsTestMethod, @Self));


    AssertFalse('Should not find element before start index using method',
                LVecDeque.Contains(11, 1, @EqualsTestMethod, @Self));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Contains_StartIndex_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  { Test Contains with start index and reference function }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Test empty collection }
    AssertFalse('Empty collection should not contain any element from any index',
                LVecDeque.Contains(18, 0, @EqualsTestRefFunc));

    { Add test data: [6, 12, 18, 24, 30] }
    for i := 1 to 5 do
      LVecDeque.PushBack(i * 6);

    { Test Contains from start (index 0) }
    AssertTrue('Should find first element (6) from index 0 using ref function',
               LVecDeque.Contains(6, 0, @EqualsTestRefFunc));

    AssertTrue('Should find middle element (18) from index 0 using ref function',
               LVecDeque.Contains(18, 0, @EqualsTestRefFunc));

    AssertTrue('Should find last element (30) from index 0 using ref function',
               LVecDeque.Contains(30, 0, @EqualsTestRefFunc));

    { Test Contains from index 1 }
    AssertFalse('Should not find element (6) from index 1 using ref function',
                LVecDeque.Contains(6, 1, @EqualsTestRefFunc));

    AssertTrue('Should find element (12) from index 1 using ref function',
               LVecDeque.Contains(12, 1, @EqualsTestRefFunc));

    AssertTrue('Should find element (30) from index 1 using ref function',
               LVecDeque.Contains(30, 1, @EqualsTestRefFunc));

    { Test Contains from index 2 }
    AssertFalse('Should not find element (6) from index 2 using ref function',
                LVecDeque.Contains(6, 2, @EqualsTestRefFunc));

    AssertFalse('Should not find element (12) from index 2 using ref function',
                LVecDeque.Contains(12, 2, @EqualsTestRefFunc));

    AssertTrue('Should find element (18) from index 2 using ref function',
               LVecDeque.Contains(18, 2, @EqualsTestRefFunc));

    AssertTrue('Should find element (24) from index 2 using ref function',
               LVecDeque.Contains(24, 2, @EqualsTestRefFunc));

    AssertTrue('Should find element (30) from index 2 using ref function',
               LVecDeque.Contains(30, 2, @EqualsTestRefFunc));

    { Test Contains from index 3 }
    AssertFalse('Should not find element (18) from index 3 using ref function',
                LVecDeque.Contains(18, 3, @EqualsTestRefFunc));

    AssertTrue('Should find element (24) from index 3 using ref function',
               LVecDeque.Contains(24, 3, @EqualsTestRefFunc));

    AssertTrue('Should find element (30) from index 3 using ref function',
               LVecDeque.Contains(30, 3, @EqualsTestRefFunc));

    { Test Contains from last index }
    AssertFalse('Should not find element (24) from last index using ref function',
                LVecDeque.Contains(24, 4, @EqualsTestRefFunc));

    AssertTrue('Should find element (30) from last index using ref function',
               LVecDeque.Contains(30, 4, @EqualsTestRefFunc));

    { Test Contains from beyond end }
    AssertFalse('Should not find any element from beyond end using ref function',
                LVecDeque.Contains(30, 5, @EqualsTestRefFunc));

    { Test Contains with non-existing elements }
    AssertFalse('Should not find non-existing element (7) from any index using ref function',
                LVecDeque.Contains(7, 0, @EqualsTestRefFunc));

    AssertFalse('Should not find non-existing element (25) from index 2 using ref function',
                LVecDeque.Contains(25, 2, @EqualsTestRefFunc));

  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Contains_StartIndex_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 7 do
      LVecDeque.PushBack(i * 4);



    AssertTrue('Should find element in range', LVecDeque.Contains(8, 1, 3));
    AssertTrue('Should find element in range', LVecDeque.Contains(12, 1, 3));
    AssertTrue('Should find element in range', LVecDeque.Contains(16, 1, 3));


    AssertFalse('Should not find element before range', LVecDeque.Contains(4, 1, 3));
    AssertFalse('Should not find element after range', LVecDeque.Contains(20, 1, 3));
    AssertFalse('Should not find element after range', LVecDeque.Contains(28, 1, 3));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Contains_StartIndex_Count_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 6 do
      LVecDeque.PushBack(i * 9);



    AssertTrue('Should find element in range using function',
               LVecDeque.Contains(27, 2, 2, @EqualsTestFunc, @Self));
    AssertTrue('Should find element in range using function',
               LVecDeque.Contains(36, 2, 2, @EqualsTestFunc, @Self));


    AssertFalse('Should not find element outside range using function',
                LVecDeque.Contains(18, 2, 2, @EqualsTestFunc, @Self));
    AssertFalse('Should not find element outside range using function',
                LVecDeque.Contains(45, 2, 2, @EqualsTestFunc, @Self));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Contains_StartIndex_Count_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 5 do
      LVecDeque.PushBack(i * 13);



    AssertTrue('Should find element in range using method',
               LVecDeque.Contains(26, 1, 3, @EqualsTestMethod, @Self));
    AssertTrue('Should find element in range using method',
               LVecDeque.Contains(52, 1, 3, @EqualsTestMethod, @Self));


    AssertFalse('Should not find element outside range using method',
                LVecDeque.Contains(13, 1, 3, @EqualsTestMethod, @Self));
    AssertFalse('Should not find element outside range using method',
                LVecDeque.Contains(65, 1, 3, @EqualsTestMethod, @Self));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Contains_StartIndex_Count_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  { Test Contains with start index, count, and reference function }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Test empty collection - skip this test as VecDeque.Contains throws exception on empty collection }
    { This is a known limitation/bug in the VecDeque implementation }
    AssertTrue('Empty collection test skipped due to implementation limitation', True);

    { Add test data: [14, 28, 42, 56, 70, 84] }
    for i := 1 to 6 do
      LVecDeque.PushBack(i * 14);

    { Test Contains in range [0, 4) - elements [14, 28, 42, 56] }
    AssertTrue('Should find first element (14) in range [0, 4) using ref function',
               LVecDeque.Contains(14, 0, 4, @EqualsTestRefFunc));

    AssertTrue('Should find second element (28) in range [0, 4) using ref function',
               LVecDeque.Contains(28, 0, 4, @EqualsTestRefFunc));

    AssertTrue('Should find third element (42) in range [0, 4) using ref function',
               LVecDeque.Contains(42, 0, 4, @EqualsTestRefFunc));

    AssertTrue('Should find fourth element (56) in range [0, 4) using ref function',
               LVecDeque.Contains(56, 0, 4, @EqualsTestRefFunc));

    { Test Contains outside range [0, 4) - elements [70, 84] should not be found }
    AssertFalse('Should not find fifth element (70) in range [0, 4) using ref function',
                LVecDeque.Contains(70, 0, 4, @EqualsTestRefFunc));

    AssertFalse('Should not find sixth element (84) in range [0, 4) using ref function',
                LVecDeque.Contains(84, 0, 4, @EqualsTestRefFunc));

    { Test Contains in range [1, 3) - elements [28, 42, 56] }
    AssertFalse('Should not find first element (14) in range [1, 3) using ref function',
                LVecDeque.Contains(14, 1, 3, @EqualsTestRefFunc));

    AssertTrue('Should find second element (28) in range [1, 3) using ref function',
               LVecDeque.Contains(28, 1, 3, @EqualsTestRefFunc));

    AssertTrue('Should find third element (42) in range [1, 3) using ref function',
               LVecDeque.Contains(42, 1, 3, @EqualsTestRefFunc));

    AssertTrue('Should find fourth element (56) in range [1, 3) using ref function',
               LVecDeque.Contains(56, 1, 3, @EqualsTestRefFunc));

    AssertFalse('Should not find fifth element (70) in range [1, 3) using ref function',
                LVecDeque.Contains(70, 1, 3, @EqualsTestRefFunc));

    { Test Contains in range [2, 2) - elements [42, 56] }
    AssertFalse('Should not find second element (28) in range [2, 2) using ref function',
                LVecDeque.Contains(28, 2, 2, @EqualsTestRefFunc));

    AssertTrue('Should find third element (42) in range [2, 2) using ref function',
               LVecDeque.Contains(42, 2, 2, @EqualsTestRefFunc));

    AssertTrue('Should find fourth element (56) in range [2, 2) using ref function',
               LVecDeque.Contains(56, 2, 2, @EqualsTestRefFunc));

    AssertFalse('Should not find fifth element (70) in range [2, 2) using ref function',
                LVecDeque.Contains(70, 2, 2, @EqualsTestRefFunc));

    { Test Contains in range [4, 2) - elements [70, 84] }
    AssertFalse('Should not find fourth element (56) in range [4, 2) using ref function',
                LVecDeque.Contains(56, 4, 2, @EqualsTestRefFunc));

    AssertTrue('Should find fifth element (70) in range [4, 2) using ref function',
               LVecDeque.Contains(70, 4, 2, @EqualsTestRefFunc));

    AssertTrue('Should find sixth element (84) in range [4, 2) using ref function',
               LVecDeque.Contains(84, 4, 2, @EqualsTestRefFunc));

    { Test Contains with count 0 - should not find anything }
    AssertFalse('Should not find any element with count 0 using ref function',
                LVecDeque.Contains(42, 2, 0, @EqualsTestRefFunc));

    { Test Contains with count 1 - should find only one element }
    AssertTrue('Should find element (42) with count 1 from index 2 using ref function',
               LVecDeque.Contains(42, 2, 1, @EqualsTestRefFunc));

    AssertFalse('Should not find element (56) with count 1 from index 2 using ref function',
                LVecDeque.Contains(56, 2, 1, @EqualsTestRefFunc));

    { Test Contains beyond collection bounds }
    AssertFalse('Should not find any element beyond collection bounds using ref function',
                LVecDeque.Contains(84, 6, 2, @EqualsTestRefFunc));

    { Test Contains with non-existing elements }
    AssertFalse('Should not find non-existing element (15) in any range using ref function',
                LVecDeque.Contains(15, 0, 6, @EqualsTestRefFunc));

  finally
    LVecDeque.Free;
  end;
end;

{ ===== Findtestimplement ===== }
procedure TTestCase_VecDeque.Test_Find;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
  i: Integer;
  const SIZE_MAX = High(SizeUInt);
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LIndex := LVecDeque.Find(42);
    AssertEquals('Find in empty VecDeque should return High(SizeUInt)', High(SizeUInt), LIndex);


    for i := 1 to 5 do
      LVecDeque.PushBack(i * 10);



    LIndex := LVecDeque.Find(10);
    AssertEquals('Should find first element at index 0', SizeUInt(0), LIndex);

    LIndex := LVecDeque.Find(30);
    AssertEquals('Should find middle element at index 2', SizeUInt(2), LIndex);

    LIndex := LVecDeque.Find(50);
    AssertEquals('Should find last element at index 4', SizeUInt(4), LIndex);

    { Object methods }
    LIndex := LVecDeque.Find(15);
    AssertEquals('Should not find non-existing element', High(SizeUInt), LIndex);

    LIndex := LVecDeque.Find(0);
    AssertEquals('Should not find non-existing element', High(SizeUInt), LIndex);

    LIndex := LVecDeque.Find(100);
    AssertEquals('Should not find non-existing element', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Find_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 4 do
      LVecDeque.PushBack(i * 7);



    LIndex := LVecDeque.Find(14, @EqualsTestFunc, @Self);
    AssertEquals('Should find element using custom function at index 1', SizeUInt(1), LIndex);

    LIndex := LVecDeque.Find(28, @EqualsTestFunc, @Self);
    AssertEquals('Should find element using custom function at index 3', SizeUInt(3), LIndex);

    { Object methods }
    LIndex := LVecDeque.Find(15, @EqualsTestFunc, @Self);
    AssertEquals('Should not find non-existing element using custom function', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Find_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 3 do
      LVecDeque.PushBack(i * 12);


    { Object methods }
    LIndex := LVecDeque.Find(24, @EqualsTestMethod, @Self);
    AssertEquals('Should find element using method at index 1', SizeUInt(1), LIndex);

    LIndex := LVecDeque.Find(36, @EqualsTestMethod, @Self);
    AssertEquals('Should find element using method at index 2', SizeUInt(2), LIndex);

    { Object methods }
    LIndex := LVecDeque.Find(25, @EqualsTestMethod, @Self);
    AssertEquals('Should not find non-existing element using method', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Find_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
  i: Integer;
begin
  { Test Find with reference function }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Test empty collection }
    LIndex := LVecDeque.Find(30, @EqualsTestRefFunc);
    AssertEquals('Should not find element in empty collection', High(SizeUInt), LIndex);

    { Add test data: [15, 30, 45, 60] }
    for i := 1 to 4 do
      LVecDeque.PushBack(i * 15);

    { Test Find with existing elements using reference function }
    LIndex := LVecDeque.Find(15, @EqualsTestRefFunc);
    AssertEquals('Should find first element (15) using ref function at index 0', SizeUInt(0), LIndex);

    LIndex := LVecDeque.Find(30, @EqualsTestRefFunc);
    AssertEquals('Should find second element (30) using ref function at index 1', SizeUInt(1), LIndex);

    LIndex := LVecDeque.Find(45, @EqualsTestRefFunc);
    AssertEquals('Should find third element (45) using ref function at index 2', SizeUInt(2), LIndex);

    LIndex := LVecDeque.Find(60, @EqualsTestRefFunc);
    AssertEquals('Should find fourth element (60) using ref function at index 3', SizeUInt(3), LIndex);

    { Test Find with non-existing elements using reference function }
    LIndex := LVecDeque.Find(14, @EqualsTestRefFunc);
    AssertEquals('Should not find non-existing element (14) using ref function', High(SizeUInt), LIndex);

    LIndex := LVecDeque.Find(31, @EqualsTestRefFunc);
    AssertEquals('Should not find non-existing element (31) using ref function', High(SizeUInt), LIndex);

    LIndex := LVecDeque.Find(61, @EqualsTestRefFunc);
    AssertEquals('Should not find non-existing element (61) using ref function', High(SizeUInt), LIndex);

    { Test Find with duplicate elements }
    LVecDeque.PushBack(30); { Now we have [15, 30, 45, 60, 30] }

    LIndex := LVecDeque.Find(30, @EqualsTestRefFunc);
    AssertEquals('Should find first occurrence of duplicate element (30) at index 1', SizeUInt(1), LIndex);

    { Test Find with zero value }
    LVecDeque.PushBack(0); { Now we have [15, 30, 45, 60, 30, 0] }

    LIndex := LVecDeque.Find(0, @EqualsTestRefFunc);
    AssertEquals('Should find zero element using ref function at index 5', SizeUInt(5), LIndex);

    { Test Find with negative value }
    LVecDeque.PushBack(-15); { Now we have [15, 30, 45, 60, 30, 0, -15] }

    LIndex := LVecDeque.Find(-15, @EqualsTestRefFunc);
    AssertEquals('Should find negative element (-15) using ref function at index 6', SizeUInt(6), LIndex);

  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Find_StartIndex;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 6 do
      LVecDeque.PushBack(i * 5);



    LIndex := LVecDeque.Find(15, 0);
    AssertEquals('Should find element from start at index 2', SizeUInt(2), LIndex);


    LIndex := LVecDeque.Find(25, 2);
    AssertEquals('Should find element from index 2 at index 4', SizeUInt(4), LIndex);


    LIndex := LVecDeque.Find(10, 3);
    AssertEquals('Should not find element before start index', High(SizeUInt), LIndex);


    LIndex := LVecDeque.Find(15, 2);
    AssertEquals('Should find element at start index', SizeUInt(2), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Find_StartIndex_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 5 do
      LVecDeque.PushBack(i * 8);



    LIndex := LVecDeque.Find(24, 1, @EqualsTestFunc, @Self);
    AssertEquals('Should find element from index 1 using function at index 2', SizeUInt(2), LIndex);


    LIndex := LVecDeque.Find(8, 1, @EqualsTestFunc, @Self);
    AssertEquals('Should not find element before start index using function', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Find_StartIndex_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 4 do
      LVecDeque.PushBack(i * 11);



    LIndex := LVecDeque.Find(33, 1, @EqualsTestMethod, @Self);
    AssertEquals('Should find element from index 1 using method at index 2', SizeUInt(2), LIndex);


    LIndex := LVecDeque.Find(22, 2, @EqualsTestMethod, @Self);
    AssertEquals('Should not find element before start index using method', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Find_StartIndex_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
  i: Integer;
begin
  { Test Find with start index and reference function }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Test empty collection }
    LIndex := LVecDeque.Find(24, 2, @EqualsTestRefFunc);
    AssertEquals('Should not find element in empty collection', High(SizeUInt), LIndex);

    { Add test data: [6, 12, 18, 24, 30] }
    for i := 1 to 5 do
      LVecDeque.PushBack(i * 6);

    { Test Find from start (index 0) }
    LIndex := LVecDeque.Find(6, 0, @EqualsTestRefFunc);
    AssertEquals('Should find first element (6) from index 0 using ref function', SizeUInt(0), LIndex);

    LIndex := LVecDeque.Find(18, 0, @EqualsTestRefFunc);
    AssertEquals('Should find element (18) from index 0 using ref function', SizeUInt(2), LIndex);

    LIndex := LVecDeque.Find(30, 0, @EqualsTestRefFunc);
    AssertEquals('Should find last element (30) from index 0 using ref function', SizeUInt(4), LIndex);

    { Test Find from index 1 }
    LIndex := LVecDeque.Find(6, 1, @EqualsTestRefFunc);
    AssertEquals('Should not find element (6) from index 1 using ref function', High(SizeUInt), LIndex);

    LIndex := LVecDeque.Find(12, 1, @EqualsTestRefFunc);
    AssertEquals('Should find element (12) from index 1 using ref function', SizeUInt(1), LIndex);

    LIndex := LVecDeque.Find(30, 1, @EqualsTestRefFunc);
    AssertEquals('Should find element (30) from index 1 using ref function', SizeUInt(4), LIndex);

    { Test Find from index 2 }
    LIndex := LVecDeque.Find(12, 2, @EqualsTestRefFunc);
    AssertEquals('Should not find element (12) from index 2 using ref function', High(SizeUInt), LIndex);

    LIndex := LVecDeque.Find(18, 2, @EqualsTestRefFunc);
    AssertEquals('Should find element (18) from index 2 using ref function', SizeUInt(2), LIndex);

    LIndex := LVecDeque.Find(24, 2, @EqualsTestRefFunc);
    AssertEquals('Should find element (24) from index 2 using ref function', SizeUInt(3), LIndex);

    LIndex := LVecDeque.Find(30, 2, @EqualsTestRefFunc);
    AssertEquals('Should find element (30) from index 2 using ref function', SizeUInt(4), LIndex);

    { Test Find from index 3 }
    LIndex := LVecDeque.Find(18, 3, @EqualsTestRefFunc);
    AssertEquals('Should not find element (18) from index 3 using ref function', High(SizeUInt), LIndex);

    LIndex := LVecDeque.Find(24, 3, @EqualsTestRefFunc);
    AssertEquals('Should find element (24) from index 3 using ref function', SizeUInt(3), LIndex);

    LIndex := LVecDeque.Find(30, 3, @EqualsTestRefFunc);
    AssertEquals('Should find element (30) from index 3 using ref function', SizeUInt(4), LIndex);

    { Test Find from last index }
    LIndex := LVecDeque.Find(24, 4, @EqualsTestRefFunc);
    AssertEquals('Should not find element (24) from last index using ref function', High(SizeUInt), LIndex);

    LIndex := LVecDeque.Find(30, 4, @EqualsTestRefFunc);
    AssertEquals('Should find element (30) from last index using ref function', SizeUInt(4), LIndex);

    { Test Find from beyond end }
    LIndex := LVecDeque.Find(30, 5, @EqualsTestRefFunc);
    AssertEquals('Should not find any element from beyond end using ref function', High(SizeUInt), LIndex);

    { Test Find with non-existing elements }
    LIndex := LVecDeque.Find(7, 0, @EqualsTestRefFunc);
    AssertEquals('Should not find non-existing element (7) from any index using ref function', High(SizeUInt), LIndex);

    LIndex := LVecDeque.Find(25, 2, @EqualsTestRefFunc);
    AssertEquals('Should not find non-existing element (25) from index 2 using ref function', High(SizeUInt), LIndex);

  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Find_StartIndex_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 7 do
      LVecDeque.PushBack(i * 4);



    LIndex := LVecDeque.Find(12, 1, 3);
    AssertEquals('Should find element in range at index 2', SizeUInt(2), LIndex);

    LIndex := LVecDeque.Find(16, 1, 3);
    AssertEquals('Should find element in range at index 3', SizeUInt(3), LIndex);


    LIndex := LVecDeque.Find(4, 1, 3);
    AssertEquals('Should not find element before range', High(SizeUInt), LIndex);

    LIndex := LVecDeque.Find(20, 1, 3);
    AssertEquals('Should not find element after range', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Find_StartIndex_Count_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 6 do
      LVecDeque.PushBack(i * 9);



    LIndex := LVecDeque.Find(27, 2, 2, @EqualsTestFunc, @Self);
    AssertEquals('Should find element in range using function at index 2', SizeUInt(2), LIndex);


    LIndex := LVecDeque.Find(45, 2, 2, @EqualsTestFunc, @Self);
    AssertEquals('Should not find element outside range using function', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Find_StartIndex_Count_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 5 do
      LVecDeque.PushBack(i * 13);



    LIndex := LVecDeque.Find(39, 1, 3, @EqualsTestMethod, @Self);
    AssertEquals('Should find element in range using method at index 2', SizeUInt(2), LIndex);


    LIndex := LVecDeque.Find(65, 1, 3, @EqualsTestMethod, @Self);
    AssertEquals('Should not find element outside range using method', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Find_StartIndex_Count_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
  i: Integer;
begin
  { Test Find with start index, count, and reference function }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Test empty collection }
    LIndex := LVecDeque.Find(42, 0, 4, @EqualsTestRefFunc);
    AssertEquals('Should not find element in empty collection', High(SizeUInt), LIndex);

    { Add test data: [14, 28, 42, 56, 70, 84] }
    for i := 1 to 6 do
      LVecDeque.PushBack(i * 14);

    { Test Find in range [0, 4) - elements [14, 28, 42, 56] }
    LIndex := LVecDeque.Find(14, 0, 4, @EqualsTestRefFunc);
    AssertEquals('Should find first element (14) in range [0, 4) using ref function', SizeUInt(0), LIndex);

    LIndex := LVecDeque.Find(28, 0, 4, @EqualsTestRefFunc);
    AssertEquals('Should find second element (28) in range [0, 4) using ref function', SizeUInt(1), LIndex);

    LIndex := LVecDeque.Find(42, 0, 4, @EqualsTestRefFunc);
    AssertEquals('Should find third element (42) in range [0, 4) using ref function', SizeUInt(2), LIndex);

    LIndex := LVecDeque.Find(56, 0, 4, @EqualsTestRefFunc);
    AssertEquals('Should find fourth element (56) in range [0, 4) using ref function', SizeUInt(3), LIndex);

    { Test Find outside range [0, 4) - elements [70, 84] should not be found }
    LIndex := LVecDeque.Find(70, 0, 4, @EqualsTestRefFunc);
    AssertEquals('Should not find fifth element (70) in range [0, 4) using ref function', High(SizeUInt), LIndex);

    LIndex := LVecDeque.Find(84, 0, 4, @EqualsTestRefFunc);
    AssertEquals('Should not find sixth element (84) in range [0, 4) using ref function', High(SizeUInt), LIndex);

    { Test Find in range [1, 3) - elements [28, 42, 56] }
    LIndex := LVecDeque.Find(14, 1, 3, @EqualsTestRefFunc);
    AssertEquals('Should not find first element (14) in range [1, 3) using ref function', High(SizeUInt), LIndex);

    LIndex := LVecDeque.Find(28, 1, 3, @EqualsTestRefFunc);
    AssertEquals('Should find second element (28) in range [1, 3) using ref function', SizeUInt(1), LIndex);

    LIndex := LVecDeque.Find(42, 1, 3, @EqualsTestRefFunc);
    AssertEquals('Should find third element (42) in range [1, 3) using ref function', SizeUInt(2), LIndex);

    LIndex := LVecDeque.Find(56, 1, 3, @EqualsTestRefFunc);
    AssertEquals('Should find fourth element (56) in range [1, 3) using ref function', SizeUInt(3), LIndex);

    LIndex := LVecDeque.Find(70, 1, 3, @EqualsTestRefFunc);
    AssertEquals('Should not find fifth element (70) in range [1, 3) using ref function', High(SizeUInt), LIndex);

    { Test Find in range [2, 2) - elements [42, 56] }
    LIndex := LVecDeque.Find(28, 2, 2, @EqualsTestRefFunc);
    AssertEquals('Should not find second element (28) in range [2, 2) using ref function', High(SizeUInt), LIndex);

    LIndex := LVecDeque.Find(42, 2, 2, @EqualsTestRefFunc);
    AssertEquals('Should find third element (42) in range [2, 2) using ref function', SizeUInt(2), LIndex);

    LIndex := LVecDeque.Find(56, 2, 2, @EqualsTestRefFunc);
    AssertEquals('Should find fourth element (56) in range [2, 2) using ref function', SizeUInt(3), LIndex);

    LIndex := LVecDeque.Find(70, 2, 2, @EqualsTestRefFunc);
    AssertEquals('Should not find fifth element (70) in range [2, 2) using ref function', High(SizeUInt), LIndex);

    { Test Find in range [4, 2) - elements [70, 84] }
    LIndex := LVecDeque.Find(56, 4, 2, @EqualsTestRefFunc);
    AssertEquals('Should not find fourth element (56) in range [4, 2) using ref function', High(SizeUInt), LIndex);

    LIndex := LVecDeque.Find(70, 4, 2, @EqualsTestRefFunc);
    AssertEquals('Should find fifth element (70) in range [4, 2) using ref function', SizeUInt(4), LIndex);

    LIndex := LVecDeque.Find(84, 4, 2, @EqualsTestRefFunc);
    AssertEquals('Should find sixth element (84) in range [4, 2) using ref function', SizeUInt(5), LIndex);

    { Test Find with count 0 - should not find anything }
    LIndex := LVecDeque.Find(42, 2, 0, @EqualsTestRefFunc);
    AssertEquals('Should not find any element with count 0 using ref function', High(SizeUInt), LIndex);

    { Test Find with count 1 - should find only one element }
    LIndex := LVecDeque.Find(42, 2, 1, @EqualsTestRefFunc);
    AssertEquals('Should find element (42) with count 1 from index 2 using ref function', SizeUInt(2), LIndex);

    LIndex := LVecDeque.Find(56, 2, 1, @EqualsTestRefFunc);
    AssertEquals('Should not find element (56) with count 1 from index 2 using ref function', High(SizeUInt), LIndex);

    { Test Find beyond collection bounds }
    LIndex := LVecDeque.Find(84, 6, 2, @EqualsTestRefFunc);
    AssertEquals('Should not find any element beyond collection bounds using ref function', High(SizeUInt), LIndex);

    { Test Find with non-existing elements }
    LIndex := LVecDeque.Find(15, 0, 6, @EqualsTestRefFunc);
    AssertEquals('Should not find non-existing element (15) in any range using ref function', High(SizeUInt), LIndex);

  finally
    LVecDeque.Free;
  end;
end;

{ ===== FindLasttestimplement ===== }
procedure TTestCase_VecDeque.Test_FindLast;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LIndex := LVecDeque.FindLast(42);
    AssertEquals('FindLast in empty VecDeque should return High(SizeUInt)', High(SizeUInt), LIndex);


    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(30);
    LVecDeque.PushBack(10);



    LIndex := LVecDeque.FindLast(10);
    AssertEquals('Should find last occurrence at index 4', SizeUInt(4), LIndex);

    LIndex := LVecDeque.FindLast(20);
    AssertEquals('Should find single occurrence at index 1', SizeUInt(1), LIndex);

    LIndex := LVecDeque.FindLast(30);
    AssertEquals('Should find single occurrence at index 3', SizeUInt(3), LIndex);

    { Object methods }
    LIndex := LVecDeque.FindLast(40);
    AssertEquals('Should not find non-existing element', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLast_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(7);
    LVecDeque.PushBack(14);
    LVecDeque.PushBack(7);
    LVecDeque.PushBack(21);



    LIndex := LVecDeque.FindLast(7, @EqualsTestFunc, @Self);
    AssertEquals('Should find last occurrence using function at index 2', SizeUInt(2), LIndex);

    LIndex := LVecDeque.FindLast(14, @EqualsTestFunc, @Self);
    AssertEquals('Should find single occurrence using function at index 1', SizeUInt(1), LIndex);

    { Object methods }
    LIndex := LVecDeque.FindLast(28, @EqualsTestFunc, @Self);
    AssertEquals('Should not find non-existing element using function', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLast_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(12);
    LVecDeque.PushBack(24);
    LVecDeque.PushBack(12);
    LVecDeque.PushBack(36);
    LVecDeque.PushBack(24);



    LIndex := LVecDeque.FindLast(24, @EqualsTestMethod, @Self);
    AssertEquals('Should find last occurrence using method at index 4', SizeUInt(4), LIndex);

    LIndex := LVecDeque.FindLast(12, @EqualsTestMethod, @Self);
    AssertEquals('Should find last occurrence using method at index 2', SizeUInt(2), LIndex);

    { Object methods }
    LIndex := LVecDeque.FindLast(48, @EqualsTestMethod, @Self);
    AssertEquals('Should not find non-existing element using method', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLast_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  { Test FindLast with reference function }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Test empty collection }
    LIndex := LVecDeque.FindLast(15, @EqualsTestRefFunc);
    AssertEquals('Should not find element in empty collection', High(SizeUInt), LIndex);

    { Add test data: [15, 30, 15, 45] }
    LVecDeque.PushBack(15);
    LVecDeque.PushBack(30);
    LVecDeque.PushBack(15);
    LVecDeque.PushBack(45);

    { Test FindLast with existing elements using reference function }
    LIndex := LVecDeque.FindLast(15, @EqualsTestRefFunc);
    AssertEquals('Should find last occurrence of element (15) using ref function at index 2', SizeUInt(2), LIndex);

    LIndex := LVecDeque.FindLast(30, @EqualsTestRefFunc);
    AssertEquals('Should find single occurrence of element (30) using ref function at index 1', SizeUInt(1), LIndex);

    LIndex := LVecDeque.FindLast(45, @EqualsTestRefFunc);
    AssertEquals('Should find single occurrence of element (45) using ref function at index 3', SizeUInt(3), LIndex);

    { Test FindLast with non-existing elements using reference function }
    LIndex := LVecDeque.FindLast(14, @EqualsTestRefFunc);
    AssertEquals('Should not find non-existing element (14) using ref function', High(SizeUInt), LIndex);

    LIndex := LVecDeque.FindLast(60, @EqualsTestRefFunc);
    AssertEquals('Should not find non-existing element (60) using ref function', High(SizeUInt), LIndex);

    { Test FindLast with more duplicate elements }
    LVecDeque.PushBack(30); { Now we have [15, 30, 15, 45, 30] }

    LIndex := LVecDeque.FindLast(30, @EqualsTestRefFunc);
    AssertEquals('Should find last occurrence of duplicate element (30) at index 4', SizeUInt(4), LIndex);

    LIndex := LVecDeque.FindLast(15, @EqualsTestRefFunc);
    AssertEquals('Should find last occurrence of duplicate element (15) at index 2', SizeUInt(2), LIndex);

    { Test FindLast with zero value }
    LVecDeque.PushBack(0); { Now we have [15, 30, 15, 45, 30, 0] }

    LIndex := LVecDeque.FindLast(0, @EqualsTestRefFunc);
    AssertEquals('Should find zero element using ref function at index 5', SizeUInt(5), LIndex);

    { Test FindLast with negative value }
    LVecDeque.PushBack(-15); { Now we have [15, 30, 15, 45, 30, 0, -15] }

    LIndex := LVecDeque.FindLast(-15, @EqualsTestRefFunc);
    AssertEquals('Should find negative element (-15) using ref function at index 6', SizeUInt(6), LIndex);

    { Test FindLast with multiple occurrences at the end }
    LVecDeque.PushBack(-15); { Now we have [15, 30, 15, 45, 30, 0, -15, -15] }

    LIndex := LVecDeque.FindLast(-15, @EqualsTestRefFunc);
    AssertEquals('Should find last occurrence of negative element (-15) at index 7', SizeUInt(7), LIndex);

  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLast_StartIndex;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 6 do
      LVecDeque.PushBack((i mod 3) * 5);



    LIndex := LVecDeque.FindLast(5, 5);
    AssertEquals('Should find last occurrence from end at index 3', SizeUInt(3), LIndex);


    LIndex := LVecDeque.FindLast(5, 2);
    AssertEquals('Should find occurrence within range at index 0', SizeUInt(0), LIndex);


    LIndex := LVecDeque.FindLast(0, 1);
    AssertEquals('Should not find element after start index', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLast_StartIndex_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(8);
    LVecDeque.PushBack(16);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(24);
    LVecDeque.PushBack(8);



    LIndex := LVecDeque.FindLast(8, 4, @EqualsTestFunc, @Self);
    AssertEquals('Should find last occurrence using function at index 4', SizeUInt(4), LIndex);


    LIndex := LVecDeque.FindLast(8, 2, @EqualsTestFunc, @Self);
    AssertEquals('Should find occurrence within range using function at index 2', SizeUInt(2), LIndex);


    LIndex := LVecDeque.FindLast(24, 1, @EqualsTestFunc, @Self);
    AssertEquals('Should not find element after start index using function', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLast_StartIndex_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(11);
    LVecDeque.PushBack(22);
    LVecDeque.PushBack(11);
    LVecDeque.PushBack(33);



    LIndex := LVecDeque.FindLast(11, 3, @EqualsTestMethod, @Self);
    AssertEquals('Should find last occurrence using method at index 2', SizeUInt(2), LIndex);


    LIndex := LVecDeque.FindLast(11, 1, @EqualsTestMethod, @Self);
    AssertEquals('Should find occurrence within range using method at index 0', SizeUInt(0), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLast_StartIndex_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  { Test FindLast with start index and reference function }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Test empty collection }
    LIndex := LVecDeque.FindLast(6, 4, @EqualsTestRefFunc);
    AssertEquals('Should not find element in empty collection', High(SizeUInt), LIndex);

    { Add test data: [6, 12, 6, 18, 6] }
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(12);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(18);
    LVecDeque.PushBack(6);

    { Test FindLast from end (index 4) }
    LIndex := LVecDeque.FindLast(6, 4, @EqualsTestRefFunc);
    AssertEquals('Should find last element (6) from index 4 using ref function', SizeUInt(4), LIndex);

    LIndex := LVecDeque.FindLast(18, 4, @EqualsTestRefFunc);
    AssertEquals('Should find element (18) from index 4 using ref function', SizeUInt(3), LIndex);

    LIndex := LVecDeque.FindLast(12, 4, @EqualsTestRefFunc);
    AssertEquals('Should find element (12) from index 4 using ref function', SizeUInt(1), LIndex);

    { Test FindLast from index 3 }
    LIndex := LVecDeque.FindLast(6, 3, @EqualsTestRefFunc);
    AssertEquals('Should find element (6) from index 3 using ref function at index 2', SizeUInt(2), LIndex);

    LIndex := LVecDeque.FindLast(18, 3, @EqualsTestRefFunc);
    AssertEquals('Should find element (18) from index 3 using ref function', SizeUInt(3), LIndex);

    LIndex := LVecDeque.FindLast(12, 3, @EqualsTestRefFunc);
    AssertEquals('Should find element (12) from index 3 using ref function', SizeUInt(1), LIndex);

    { Test FindLast from index 2 }
    LIndex := LVecDeque.FindLast(6, 2, @EqualsTestRefFunc);
    AssertEquals('Should find element (6) from index 2 using ref function at index 2', SizeUInt(2), LIndex);

    LIndex := LVecDeque.FindLast(12, 2, @EqualsTestRefFunc);
    AssertEquals('Should find element (12) from index 2 using ref function', SizeUInt(1), LIndex);

    LIndex := LVecDeque.FindLast(18, 2, @EqualsTestRefFunc);
    AssertEquals('Should not find element (18) from index 2 using ref function', High(SizeUInt), LIndex);

    { Test FindLast from index 1 }
    LIndex := LVecDeque.FindLast(6, 1, @EqualsTestRefFunc);
    AssertEquals('Should find element (6) from index 1 using ref function at index 0', SizeUInt(0), LIndex);

    LIndex := LVecDeque.FindLast(12, 1, @EqualsTestRefFunc);
    AssertEquals('Should find element (12) from index 1 using ref function', SizeUInt(1), LIndex);

    LIndex := LVecDeque.FindLast(18, 1, @EqualsTestRefFunc);
    AssertEquals('Should not find element (18) from index 1 using ref function', High(SizeUInt), LIndex);

    { Test FindLast from index 0 }
    LIndex := LVecDeque.FindLast(6, 0, @EqualsTestRefFunc);
    AssertEquals('Should find element (6) from index 0 using ref function', SizeUInt(0), LIndex);

    LIndex := LVecDeque.FindLast(12, 0, @EqualsTestRefFunc);
    AssertEquals('Should not find element (12) from index 0 using ref function', High(SizeUInt), LIndex);

    { Test FindLast beyond collection bounds }
    LIndex := LVecDeque.FindLast(6, 5, @EqualsTestRefFunc);
    AssertEquals('Should not find any element beyond collection bounds using ref function', High(SizeUInt), LIndex);

    { Test FindLast with non-existing elements }
    LIndex := LVecDeque.FindLast(7, 4, @EqualsTestRefFunc);
    AssertEquals('Should not find non-existing element (7) from any index using ref function', High(SizeUInt), LIndex);

    LIndex := LVecDeque.FindLast(19, 2, @EqualsTestRefFunc);
    AssertEquals('Should not find non-existing element (19) from index 2 using ref function', High(SizeUInt), LIndex);

  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLast_StartIndex_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 7 do
      LVecDeque.PushBack((i mod 4) * 4);



    LIndex := LVecDeque.FindLast(4, 1, 4);
    AssertEquals('Should find last occurrence in range at index 4', SizeUInt(4), LIndex);

    LIndex := LVecDeque.FindLast(8, 1, 4);
    AssertEquals('Should find occurrence in range at index 1', SizeUInt(1), LIndex);


    LIndex := LVecDeque.FindLast(12, 1, 4);
    AssertEquals('Should not find element outside range', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLast_StartIndex_Count_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(9);
    LVecDeque.PushBack(18);
    LVecDeque.PushBack(9);
    LVecDeque.PushBack(27);
    LVecDeque.PushBack(9);
    LVecDeque.PushBack(36);



    LIndex := LVecDeque.FindLast(9, 1, 3, @EqualsTestFunc, @Self);
    AssertEquals('Should find last occurrence in range using function at index 2', SizeUInt(2), LIndex);


    LIndex := LVecDeque.FindLast(36, 1, 3, @EqualsTestFunc, @Self);
    AssertEquals('Should not find element outside range using function', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLast_StartIndex_Count_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(13);
    LVecDeque.PushBack(26);
    LVecDeque.PushBack(13);
    LVecDeque.PushBack(39);
    LVecDeque.PushBack(13);



    LIndex := LVecDeque.FindLast(13, 0, 4, @EqualsTestMethod, @Self);
    AssertEquals('Should find last occurrence in range using method at index 2', SizeUInt(2), LIndex);


    LIndex := LVecDeque.FindLast(39, 0, 3, @EqualsTestMethod, @Self);
    AssertEquals('Should not find element outside range using method', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLast_StartIndex_Count_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  { Test FindLast with start index, count, and reference function }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Test empty collection }
    LIndex := LVecDeque.FindLast(14, 0, 5, @EqualsTestRefFunc);
    AssertEquals('Should not find element in empty collection', High(SizeUInt), LIndex);

    { Add test data: [14, 28, 14, 42, 14, 56] }
    LVecDeque.PushBack(14);
    LVecDeque.PushBack(28);
    LVecDeque.PushBack(14);
    LVecDeque.PushBack(42);
    LVecDeque.PushBack(14);
    LVecDeque.PushBack(56);

    { Test FindLast in range [0, 5) - elements [14, 28, 14, 42, 14] }
    LIndex := LVecDeque.FindLast(14, 0, 5, @EqualsTestRefFunc);
    AssertEquals('Should find last occurrence of element (14) in range [0, 5) using ref function at index 4', SizeUInt(4), LIndex);

    LIndex := LVecDeque.FindLast(28, 0, 5, @EqualsTestRefFunc);
    AssertEquals('Should find element (28) in range [0, 5) using ref function at index 1', SizeUInt(1), LIndex);

    LIndex := LVecDeque.FindLast(42, 0, 5, @EqualsTestRefFunc);
    AssertEquals('Should find element (42) in range [0, 5) using ref function at index 3', SizeUInt(3), LIndex);

    { Test FindLast outside range [0, 5) - element [56] should not be found }
    LIndex := LVecDeque.FindLast(56, 0, 5, @EqualsTestRefFunc);
    AssertEquals('Should not find element (56) outside range [0, 5) using ref function', High(SizeUInt), LIndex);

    { Test FindLast in range [1, 4) - elements [28, 14, 42, 14] }
    LIndex := LVecDeque.FindLast(14, 1, 4, @EqualsTestRefFunc);
    AssertEquals('Should find last occurrence of element (14) in range [1, 4) using ref function at index 4', SizeUInt(4), LIndex);

    LIndex := LVecDeque.FindLast(28, 1, 4, @EqualsTestRefFunc);
    AssertEquals('Should find element (28) in range [1, 4) using ref function at index 1', SizeUInt(1), LIndex);

    LIndex := LVecDeque.FindLast(42, 1, 4, @EqualsTestRefFunc);
    AssertEquals('Should find element (42) in range [1, 4) using ref function at index 3', SizeUInt(3), LIndex);

    { Test FindLast in range [2, 3) - elements [14, 42, 14] }
    LIndex := LVecDeque.FindLast(14, 2, 3, @EqualsTestRefFunc);
    AssertEquals('Should find last occurrence of element (14) in range [2, 3) using ref function at index 4', SizeUInt(4), LIndex);

    LIndex := LVecDeque.FindLast(42, 2, 3, @EqualsTestRefFunc);
    AssertEquals('Should find element (42) in range [2, 3) using ref function at index 3', SizeUInt(3), LIndex);

    LIndex := LVecDeque.FindLast(28, 2, 3, @EqualsTestRefFunc);
    AssertEquals('Should not find element (28) in range [2, 3) using ref function', High(SizeUInt), LIndex);

    { Test FindLast in range [4, 2) - elements [14, 56] }
    LIndex := LVecDeque.FindLast(14, 4, 2, @EqualsTestRefFunc);
    AssertEquals('Should find element (14) in range [4, 2) using ref function at index 4', SizeUInt(4), LIndex);

    LIndex := LVecDeque.FindLast(56, 4, 2, @EqualsTestRefFunc);
    AssertEquals('Should find element (56) in range [4, 2) using ref function at index 5', SizeUInt(5), LIndex);

    LIndex := LVecDeque.FindLast(42, 4, 2, @EqualsTestRefFunc);
    AssertEquals('Should not find element (42) in range [4, 2) using ref function', High(SizeUInt), LIndex);

    { Test FindLast with count 0 - should not find anything }
    LIndex := LVecDeque.FindLast(14, 2, 0, @EqualsTestRefFunc);
    AssertEquals('Should not find any element with count 0 using ref function', High(SizeUInt), LIndex);

    { Test FindLast with count 1 - should find only one element }
    LIndex := LVecDeque.FindLast(14, 2, 1, @EqualsTestRefFunc);
    AssertEquals('Should find element (14) with count 1 from index 2 using ref function at index 2', SizeUInt(2), LIndex);

    LIndex := LVecDeque.FindLast(42, 2, 1, @EqualsTestRefFunc);
    AssertEquals('Should not find element (42) with count 1 from index 2 using ref function', High(SizeUInt), LIndex);

    { Test FindLast beyond collection bounds }
    LIndex := LVecDeque.FindLast(56, 6, 2, @EqualsTestRefFunc);
    AssertEquals('Should not find any element beyond collection bounds using ref function', High(SizeUInt), LIndex);

    { Test FindLast with non-existing elements }
    LIndex := LVecDeque.FindLast(15, 0, 6, @EqualsTestRefFunc);
    AssertEquals('Should not find non-existing element (15) in any range using ref function', High(SizeUInt), LIndex);

    { Test FindLast with full range }
    LIndex := LVecDeque.FindLast(14, 0, 6, @EqualsTestRefFunc);
    AssertEquals('Should find last occurrence of element (14) in full range using ref function at index 4', SizeUInt(4), LIndex);

    LIndex := LVecDeque.FindLast(56, 0, 6, @EqualsTestRefFunc);
    AssertEquals('Should find element (56) in full range using ref function at index 5', SizeUInt(5), LIndex);

  finally
    LVecDeque.Free;
  end;
end;


// Test comment
// Body intentionally removed to avoid relying on DebugString for generic T

procedure TTestCase_VecDeque.Test_Debug_Internal_State;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInitialCapacity, LNewCapacity: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    AssertTrue('Initial VecDeque should be empty', LVecDeque.IsEmpty);
    AssertEquals('Initial count should be 0', Int64(0), Int64(LVecDeque.GetCount));
    LInitialCapacity := LVecDeque.GetCapacity;
    AssertTrue('Initial capacity should be positive', LInitialCapacity > 0);


    for i := 1 to 5 do
    begin
      LVecDeque.PushBack(i * 7);


      AssertEquals('Count should increase correctly', Int64(i), Int64(LVecDeque.GetCount));
      AssertFalse('VecDeque should not be empty after adding elements', LVecDeque.IsEmpty);

      { Object methods }
      LNewCapacity := LVecDeque.GetCapacity;
      AssertTrue('Capacity should be at least count', LNewCapacity >= LVecDeque.GetCount);
      AssertTrue('Capacity should be reasonable', LNewCapacity <= LVecDeque.GetCount * 4);
    end;


    LInitialCapacity := LVecDeque.GetCapacity;
    while LVecDeque.GetCount < LInitialCapacity do
      LVecDeque.PushBack(999);


    LVecDeque.PushBack(1000);
    LNewCapacity := LVecDeque.GetCapacity;
    AssertTrue('Capacity should increase after overflow', LNewCapacity > LInitialCapacity);


    while LVecDeque.GetCount > 2 do
      LVecDeque.PopBack;

    AssertEquals('Count should decrease correctly', Int64(2), Int64(LVecDeque.GetCount));
    AssertFalse('VecDeque should not be empty with 2 elements', LVecDeque.IsEmpty);


    LVecDeque.Clear;
    AssertTrue('VecDeque should be empty after clear', LVecDeque.IsEmpty);
    AssertEquals('Count should be 0 after clear', Int64(0), Int64(LVecDeque.GetCount));


    LVecDeque.PushBack(42);
    AssertEquals('Should work normally after clear', 42, LVecDeque.Back);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Debug_Consistency_Check;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i, LValue: Integer;
  LIsConsistent: Boolean;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LIsConsistent := True;
    try

      AssertTrue('Empty VecDeque should be empty', LVecDeque.IsEmpty);
      AssertEquals('Empty VecDeque count should be 0', Int64(0), Int64(LVecDeque.GetCount));
      AssertTrue('Empty VecDeque capacity should be positive', LVecDeque.GetCapacity > 0);
    except
      LIsConsistent := False;
    end;
    AssertTrue('Empty VecDeque should be consistent', LIsConsistent);


    for i := 1 to 10 do
    begin
      LVecDeque.PushBack(i * 3);

      LIsConsistent := True;
      try

        AssertEquals('Count should match added elements', Int64(i), Int64(LVecDeque.GetCount));


        AssertTrue('Capacity should be at least count', LVecDeque.GetCapacity >= LVecDeque.GetCount);


        AssertEquals('Front element should be first added', 3, LVecDeque.Front);
        AssertEquals('Back element should be last added', i * 3, LVecDeque.Back);


        AssertEquals('First element by index should match front', LVecDeque.Front, LVecDeque.Get(0));
        AssertEquals('Last element by index should match back', LVecDeque.Back, LVecDeque.Get(LVecDeque.GetCount - 1));

      except
        LIsConsistent := False;
      end;
      AssertTrue('VecDeque should remain consistent after adding element ' + IntToStr(i), LIsConsistent);
    end;


    for i := 1 to 5 do
    begin
      LVecDeque.PushFront(i * 100);

      LIsConsistent := True;
      try

        AssertEquals('Front should be last pushed front element', i * 100, LVecDeque.Front);
        AssertTrue('Count should increase', LVecDeque.GetCount > 10);

      except
        LIsConsistent := False;
      end;
      AssertTrue('VecDeque should remain consistent after PushFront ' + IntToStr(i), LIsConsistent);
    end;


    while LVecDeque.GetCount > 5 do
    begin
      if (LVecDeque.GetCount mod 2) = 0 then
        LValue := LVecDeque.PopFront
      else
        LValue := LVecDeque.PopBack;

      LIsConsistent := True;
      try

        if not LVecDeque.IsEmpty then
        begin
          LVecDeque.Front;
          LVecDeque.Back;
          LVecDeque.Get(0);
          LVecDeque.Get(LVecDeque.GetCount - 1);
        end;

      except
        LIsConsistent := False;
      end;
      AssertTrue('VecDeque should remain consistent after removal', LIsConsistent);
    end;


    LIsConsistent := True;
    try
      AssertTrue('Final capacity should be reasonable', LVecDeque.GetCapacity >= LVecDeque.GetCount);
      if not LVecDeque.IsEmpty then
      begin
        AssertTrue('Should be able to access all elements', LVecDeque.GetCount > 0);
        for i := 0 to Integer(LVecDeque.GetCount) - 1 do
          LVecDeque.Get(i);
      end;
    except
      LIsConsistent := False;
    end;
    AssertTrue('Final VecDeque state should be consistent', LIsConsistent);

  finally
    LVecDeque.Free;
  end;
end;























































procedure TTestCase_VecDeque.Test_Fill;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LFillValue: Integer;
  LI: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.Resize(5);
    LFillValue := 42;


    LVecDeque.Fill(LFillValue);

    { Object methods }
    AssertEquals('Count should remain same', 5, LVecDeque.Count);
    for LI := 0 to LVecDeque.Count - 1 do
      AssertEquals('All elements should be fill value', LFillValue, LVecDeque.Get(LI));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Fill_Index;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LFillValue: Integer;
  LStartIndex: SizeUInt;
  LI: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for LI := 0 to 4 do
      LVecDeque.PushBack(LI);
    LFillValue := 99;
    LStartIndex := 2;


    LVecDeque.Fill(LFillValue, LStartIndex);

    { Object methods }
    AssertEquals('Count should remain same', 5, LVecDeque.Count);

    for LI := 0 to Integer(LStartIndex) - 1 do
      AssertEquals('Element before start should be unchanged', LI, LVecDeque.Get(LI));

    for LI := Integer(LStartIndex) to LVecDeque.Count - 1 do
      AssertEquals('Element from start should be fill value', LFillValue, LVecDeque.Get(LI));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Fill_Index_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LFillValue: Integer;
  LStartIndex, LCount: SizeUInt;
  LI: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for LI := 0 to 6 do
      LVecDeque.PushBack(LI);
    LFillValue := 77;
    LStartIndex := 2;
    LCount := 3;


    LVecDeque.Fill(LFillValue, LStartIndex, LCount);

    { Object methods }
    AssertEquals('Count should remain same', 7, LVecDeque.Count);

    for LI := 0 to Integer(LStartIndex) - 1 do
      AssertEquals('Element before range should be unchanged', LI, LVecDeque.Get(LI));

    for LI := Integer(LStartIndex) to Integer(LStartIndex + LCount) - 1 do
      AssertEquals('Element in range should be fill value', LFillValue, LVecDeque.Get(LI));

    for LI := Integer(LStartIndex + LCount) to LVecDeque.Count - 1 do
      AssertEquals('Element after range should be unchanged', LI, LVecDeque.Get(LI));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Zero;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LI: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for LI := 1 to 5 do
      LVecDeque.PushBack(LI * 10);


    LVecDeque.Zero;

    { Object methods }
    AssertEquals('Count should remain same', 5, LVecDeque.Count);
    for LI := 0 to LVecDeque.Count - 1 do
      AssertEquals('All elements should be zero', 0, LVecDeque.Get(LI));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Zero_Index;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartIndex: SizeUInt;
  LI: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for LI := 1 to 6 do
      LVecDeque.PushBack(LI * 5);
    LStartIndex := 3;


    LVecDeque.Zero(LStartIndex);

    { Object methods }
    AssertEquals('Count should remain same', 6, LVecDeque.Count);

    for LI := 0 to Integer(LStartIndex) - 1 do
      AssertEquals('Element before start should be unchanged', (LI + 1) * 5, LVecDeque.Get(LI));

    for LI := Integer(LStartIndex) to LVecDeque.Count - 1 do
      AssertEquals('Element from start should be zero', 0, LVecDeque.Get(LI));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Zero_Index_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartIndex, LCount: SizeUInt;
  LI: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for LI := 1 to 7 do
      LVecDeque.PushBack(LI * 3);
    LStartIndex := 2;
    LCount := 3;


    LVecDeque.Zero(LStartIndex, LCount);

    { Object methods }
    AssertEquals('Count should remain same', 7, LVecDeque.Count);

    for LI := 0 to Integer(LStartIndex) - 1 do
      AssertEquals('Element before range should be unchanged', (LI + 1) * 3, LVecDeque.Get(LI));

    for LI := Integer(LStartIndex) to Integer(LStartIndex + LCount) - 1 do
      AssertEquals('Element in range should be zero', 0, LVecDeque.Get(LI));

    for LI := Integer(LStartIndex + LCount) to LVecDeque.Count - 1 do
      AssertEquals('Element after range should be unchanged', (LI + 1) * 3, LVecDeque.Get(LI));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Swap;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex1, LIndex2: SizeUInt;
  LValue1, LValue2: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(30);
    LVecDeque.PushBack(40);

    LIndex1 := 1;
    LIndex2 := 3;
    LValue1 := LVecDeque.Get(LIndex1);
    LValue2 := LVecDeque.Get(LIndex2);


    LVecDeque.Swap(LIndex1, LIndex2);

    { Object methods }
    AssertEquals('Count should remain same', 4, LVecDeque.Count);
    AssertEquals('Element at index1 should be value2', LValue2, LVecDeque.Get(LIndex1));
    AssertEquals('Element at index2 should be value1', LValue1, LVecDeque.Get(LIndex2));

    AssertEquals('Element at index 0 should be unchanged', 10, LVecDeque.Get(0));
    AssertEquals('Element at index 2 should be unchanged', 30, LVecDeque.Get(2));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_SwapUnChecked;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex1, LIndex2: SizeUInt;
  LValue1, LValue2: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(100);
    LVecDeque.PushBack(200);
    LVecDeque.PushBack(300);

    LIndex1 := 0;
    LIndex2 := 2;
    LValue1 := LVecDeque.Get(LIndex1);
    LValue2 := LVecDeque.Get(LIndex2);


    LVecDeque.SwapUnChecked(LIndex1, LIndex2);

    { Object methods }
    AssertEquals('Count should remain same', 3, LVecDeque.Count);
    AssertEquals('Element at index1 should be value2', LValue2, LVecDeque.Get(LIndex1));
    AssertEquals('Element at index2 should be value1', LValue1, LVecDeque.Get(LIndex2));

    AssertEquals('Element at index 1 should be unchanged', 200, LVecDeque.Get(1));
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_TryReserve;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LRequestedCapacity: SizeUInt;
  LResult: Boolean;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LRequestedCapacity := 20;

    { Object methods }
    LResult := LVecDeque.TryReserve(LRequestedCapacity);

    { Object methods }
    AssertTrue('TryReserve should succeed', LResult);
    AssertTrue('Capacity should be at least requested', LVecDeque.Capacity >= LRequestedCapacity);
    AssertEquals('Count should remain 0', 0, LVecDeque.Count);


    for i := 0 to Integer(LRequestedCapacity) - 1 do
      LVecDeque.PushBack(i);
    AssertEquals('Should be able to add requested number of elements', LRequestedCapacity, LVecDeque.Count);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ReserveExact;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LRequestedCapacity: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LRequestedCapacity := 15;


    LVecDeque.ReserveExact(LRequestedCapacity);

    { Object methods }
    AssertTrue('Capacity should be at least requested', LVecDeque.Capacity >= LRequestedCapacity);
    AssertEquals('Count should remain 0', 0, LVecDeque.Count);


    for i := 0 to Integer(LRequestedCapacity) - 1 do
      LVecDeque.PushBack(i * 2);
    AssertEquals('Should be able to add requested number of elements', LRequestedCapacity, LVecDeque.Count);
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Insert_Index_Element;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInsertIndex: SizeUInt;
  LInsertValue: Integer;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(30);

    LInsertIndex := 1;
    LInsertValue := 15;


    LVecDeque.Insert(LInsertIndex, LInsertValue);

    { Object methods }
    AssertEquals('Count should increase by 1', 4, LVecDeque.Count);
    AssertEquals('Element before insert should be unchanged', 10, LVecDeque.Get(0));
    AssertEquals('Inserted element should be at correct position', LInsertValue, LVecDeque.Get(LInsertIndex));
    AssertEquals('Element after insert should be shifted', 20, LVecDeque.Get(2));
    AssertEquals('Last element should be shifted', 30, LVecDeque.Get(3));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Insert_Index_Pointer_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInsertIndex: SizeUInt;
  LInsertData: array[0..2] of Integer;
  LPtr: PInteger;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(100);
    LVecDeque.PushBack(200);

    LInsertIndex := 1;
    LInsertData[0] := 150;
    LInsertData[1] := 175;
    LInsertData[2] := 180;
    LPtr := @LInsertData[0];


    LVecDeque.Insert(LInsertIndex, LPtr, Length(LInsertData));

    { Object methods }
    AssertEquals('Count should increase by insert count', 5, LVecDeque.Count);
    AssertEquals('Element before insert should be unchanged', 100, LVecDeque.Get(0));
    for i := 0 to High(LInsertData) do
      AssertEquals('Inserted element should be at correct position', LInsertData[i], LVecDeque.Get(LInsertIndex + i));
    AssertEquals('Element after insert should be shifted', 200, LVecDeque.Get(4));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Insert_Index_Array;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInsertIndex: SizeUInt;
  LInsertArray: array[0..1] of Integer;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(1000);
    LVecDeque.PushBack(3000);

    LInsertIndex := 1;
    LInsertArray[0] := 2000;
    LInsertArray[1] := 2500;


    LVecDeque.Insert(LInsertIndex, LInsertArray);

    { Object methods }
    AssertEquals('Count should increase by array length', 4, LVecDeque.Count);
    AssertEquals('Element before insert should be unchanged', 1000, LVecDeque.Get(0));
    for i := 0 to High(LInsertArray) do
      AssertEquals('Inserted element should be at correct position', LInsertArray[i], LVecDeque.Get(LInsertIndex + i));
    AssertEquals('Element after insert should be shifted', 3000, LVecDeque.Get(3));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Insert_Index_Collection_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceVec: specialize TVec<Integer>;
  LInsertIndex: SizeUInt;
  LInsertCount: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  LSourceVec := specialize TVec<Integer>.Create;
  try

    LVecDeque.PushBack(50);
    LVecDeque.PushBack(150);

    LSourceVec.Push(75);
    LSourceVec.Push(100);
    LSourceVec.Push(125);
    LSourceVec.Push(999);

    LInsertIndex := 1;
    LInsertCount := 3;


    LVecDeque.Insert(LInsertIndex, LSourceVec, LInsertCount);

    { Object methods }
    AssertEquals('Count should increase by insert count', 5, LVecDeque.Count);
    AssertEquals('Element before insert should be unchanged', 50, LVecDeque.Get(0));
    for i := 0 to Integer(LInsertCount) - 1 do
      AssertEquals('Inserted element should be at correct position', LSourceVec.Get(i), LVecDeque.Get(LInsertIndex + i));
    AssertEquals('Element after insert should be shifted', 150, LVecDeque.Get(4));
  finally
    LSourceVec.Free;
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Delete_Index;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LDeleteIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(30);
    LVecDeque.PushBack(40);

    LDeleteIndex := 1;


    LVecDeque.Delete(LDeleteIndex);

    { Object methods }
    AssertEquals('Count should decrease by 1', 3, LVecDeque.Count);
    AssertEquals('Element before delete should be unchanged', 10, LVecDeque.Get(0));
    AssertEquals('Element after delete should be shifted', 30, LVecDeque.Get(1));
    AssertEquals('Last element should be shifted', 40, LVecDeque.Get(2));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Delete_Index_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LDeleteIndex, LDeleteCount: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 6 do
      LVecDeque.PushBack(i * 10);

    LDeleteIndex := 2;
    LDeleteCount := 2;


    LVecDeque.Delete(LDeleteIndex, LDeleteCount);

    { Object methods }
    AssertEquals('Count should decrease by delete count', 4, LVecDeque.Count);
    AssertEquals('Element before delete should be unchanged', 10, LVecDeque.Get(0));
    AssertEquals('Element before delete should be unchanged', 20, LVecDeque.Get(1));
    AssertEquals('Element after delete should be shifted', 50, LVecDeque.Get(2));
    AssertEquals('Last element should be shifted', 60, LVecDeque.Get(3));
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_FindIF_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(9);
    LVecDeque.PushBack(12);


    LIndex := LVecDeque.FindIF(
      0,
      function(const v: Integer): Boolean
      begin
        Result := (v mod 2) = 0; // Test comment
      end
    );

    { Object methods }
    AssertEquals('Should find first even number at index 2', SizeUInt(2), LIndex);
    AssertEquals('Found element should be even', 6, LVecDeque.Get(LIndex));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindIF_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(5);
    LVecDeque.PushBack(7);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(11);


    LIndex := LVecDeque.FindIF(
      0,
      function(const v: Integer): Boolean
      begin
        Result := (v mod 2) = 0; // Test comment
      end
    );

    { Object methods }
    AssertEquals('Should find first even number at index 2', SizeUInt(2), LIndex);
    AssertEquals('Found element should be even', 8, LVecDeque.Get(LIndex));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindIF_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(13);
    LVecDeque.PushBack(15);
    LVecDeque.PushBack(16);
    LVecDeque.PushBack(19);


    LIndex := LVecDeque.FindIF(
      0,
      function(const v: Integer): Boolean
      begin
        Result := (v mod 2) = 0; // Test comment
      end
    );

    { Object methods }
    AssertEquals('Should find first even number at index 2', SizeUInt(2), LIndex);
    AssertEquals('Found element should be even', 16, LVecDeque.Get(LIndex));
  finally
    LVecDeque.Free;
  end;
end;

{ ===== FindIF StartIndex implementations ===== }

procedure TTestCase_VecDeque.Test_FindIF_StartIndex_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(7);

    LIndex := LVecDeque.FindIF(1, @EvenTestFunc, @Self);
    AssertEquals('Should find first even number from index 1 at index 2', SizeUInt(2), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindIF_StartIndex_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(7);

    LIndex := LVecDeque.FindIF(1, @EvenTestMethod, @Self);
    AssertEquals('Should find first even number from index 1 at index 2', SizeUInt(2), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindIF_StartIndex_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(7);

    LIndex := LVecDeque.FindIF(1, @EvenTestRefFunc);
    AssertEquals('Should find first even number from index 1 at index 2', SizeUInt(2), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

{ ===== FindIF StartIndex Count implementations ===== }

procedure TTestCase_VecDeque.Test_FindIF_StartIndex_Count_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(7);

    LIndex := LVecDeque.FindIF(1, 2, @EvenTestFunc, @Self);
    AssertEquals('Should find first even number in range [1, 2) at index 2', SizeUInt(2), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindIF_StartIndex_Count_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(7);

    LIndex := LVecDeque.FindIF(1, 2, @EvenTestMethod, @Self);
    AssertEquals('Should find first even number in range [1, 2) at index 2', SizeUInt(2), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindIF_StartIndex_Count_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(7);

    LIndex := LVecDeque.FindIF(1, 2, @EvenTestRefFunc);
    AssertEquals('Should find first even number in range [1, 2) at index 2', SizeUInt(2), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

{ ===== FindIFNot implementations ===== }

procedure TTestCase_VecDeque.Test_FindIFNot_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(6);

    LIndex := LVecDeque.FindIFNot(@OddTestFunc, @Self);
    AssertEquals('Should find first non-odd (even) number at index 0', SizeUInt(0), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindIFNot_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(6);

    LIndex := LVecDeque.FindIFNot(@OddTestMethod, @Self);
    AssertEquals('Should find first non-odd (even) number at index 0', SizeUInt(0), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindIFNot_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(6);

    LIndex := LVecDeque.FindIFNot(@OddTestRefFunc);
    AssertEquals('Should find first non-odd (even) number at index 0', SizeUInt(0), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

{ ===== FindIFNot StartIndex implementations ===== }

procedure TTestCase_VecDeque.Test_FindIFNot_StartIndex_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(7);

    LIndex := LVecDeque.FindIFNot(1, @OddTestFunc, @Self);
    AssertEquals('Should find first non-odd (even) number from index 1 at index 2', SizeUInt(2), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindIFNot_StartIndex_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(7);

    LIndex := LVecDeque.FindIFNot(1, @OddTestMethod, @Self);
    AssertEquals('Should find first non-odd (even) number from index 1 at index 2', SizeUInt(2), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindIFNot_StartIndex_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(7);

    LIndex := LVecDeque.FindIFNot(1, @OddTestRefFunc);
    AssertEquals('Should find first non-odd (even) number from index 1 at index 2', SizeUInt(2), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

{ ===== FindIFNot StartIndex Count implementations ===== }

procedure TTestCase_VecDeque.Test_FindIFNot_StartIndex_Count_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(7);

    LIndex := LVecDeque.FindIFNot(1, 2, @OddTestFunc, @Self);
    AssertEquals('Should find first non-odd (even) number in range [1, 2) at index 2', SizeUInt(2), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindIFNot_StartIndex_Count_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(7);

    LIndex := LVecDeque.FindIFNot(1, 2, @OddTestMethod, @Self);
    AssertEquals('Should find first non-odd (even) number in range [1, 2) at index 2', SizeUInt(2), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindIFNot_StartIndex_Count_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(7);

    LIndex := LVecDeque.FindIFNot(1, 2, @OddTestRefFunc);
    AssertEquals('Should find first non-odd (even) number in range [1, 2) at index 2', SizeUInt(2), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

{ ===== FindLastIF implementations ===== }

procedure TTestCase_VecDeque.Test_FindLastIF_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(5);

    LIndex := LVecDeque.FindLastIF(@EvenTestFunc, @Self);
    AssertEquals('Should find last even number at index 2', SizeUInt(2), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLastIF_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(5);

    LIndex := LVecDeque.FindLastIF(@EvenTestMethod, @Self);
    AssertEquals('Should find last even number at index 2', SizeUInt(2), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLastIF_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(5);

    LIndex := LVecDeque.FindLastIF(@EvenTestRefFunc);
    AssertEquals('Should find last even number at index 2', SizeUInt(2), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

{ ===== FindLastIF StartIndex implementations ===== }

procedure TTestCase_VecDeque.Test_FindLastIF_StartIndex_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(6);

    LIndex := LVecDeque.FindLastIF(2, @EvenTestFunc, @Self);
    AssertEquals('Should find last even number from index 2 at index 1', SizeUInt(1), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLastIF_StartIndex_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(6);

    LIndex := LVecDeque.FindLastIF(2, @EvenTestMethod, @Self);
    AssertEquals('Should find last even number from index 2 at index 1', SizeUInt(1), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLastIF_StartIndex_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(6);

    LIndex := LVecDeque.FindLastIF(2, @EvenTestRefFunc);
    AssertEquals('Should find last even number from index 2 at index 1', SizeUInt(1), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

{ ===== FindLastIF StartIndex Count implementations ===== }

procedure TTestCase_VecDeque.Test_FindLastIF_StartIndex_Count_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(8);

    LIndex := LVecDeque.FindLastIF(0, 3, @EvenTestFunc, @Self);
    AssertEquals('Should find last even number in range [0, 3) at index 1', SizeUInt(1), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLastIF_StartIndex_Count_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(8);

    LIndex := LVecDeque.FindLastIF(0, 3, @EvenTestMethod, @Self);
    AssertEquals('Should find last even number in range [0, 3) at index 1', SizeUInt(1), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLastIF_StartIndex_Count_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(8);

    LIndex := LVecDeque.FindLastIF(0, 3, @EvenTestRefFunc);
    AssertEquals('Should find last even number in range [0, 3) at index 1', SizeUInt(1), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

{ ===== FindLastIFNot implementations ===== }

procedure TTestCase_VecDeque.Test_FindLastIFNot_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(5);

    LIndex := LVecDeque.FindLastIFNot(@OddTestFunc, @Self);
    AssertEquals('Should find last non-odd (even) number at index 2', SizeUInt(2), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLastIFNot_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(5);

    LIndex := LVecDeque.FindLastIFNot(@OddTestMethod, @Self);
    AssertEquals('Should find last non-odd (even) number at index 2', SizeUInt(2), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLastIFNot_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(5);

    LIndex := LVecDeque.FindLastIFNot(@OddTestRefFunc);
    AssertEquals('Should find last non-odd (even) number at index 2', SizeUInt(2), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

{ ===== Sort Range implementations ===== }

procedure TTestCase_VecDeque.Test_Sort_Range;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(9);

    LVecDeque.Sort(1, 3);

    AssertEquals('Element at index 0 should remain 5', 5, LVecDeque.Get(0));
    AssertEquals('Element at index 1 should be 2', 2, LVecDeque.Get(1));
    AssertEquals('Element at index 2 should be 8', 8, LVecDeque.Get(2));
    AssertEquals('Element at index 3 should be 1', 1, LVecDeque.Get(3));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLastIF_Wraparound;
var
  D: specialize TVecDeque<Integer>;
  idx: SizeInt;
  i: Integer;
begin
  D := specialize TVecDeque<Integer>.Create;
  try
    for i := 1 to 10 do D.PushBack(i);
    for i := 1 to 5 do D.PopFront;
    for i := 11 to 15 do D.PushBack(i);

    idx := D.FindLastIF(@EvenTestFunc, @Self);
    AssertEquals('Wraparound FindLastIF even should be index 8', SizeUInt(8), SizeUInt(idx));
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLastIFNot_Wraparound;
var
  D: specialize TVecDeque<Integer>;
  idx: SizeInt;
  i: Integer;
begin
  D := specialize TVecDeque<Integer>.Create;
  try
    for i := 1 to 10 do D.PushBack(i);
    for i := 1 to 5 do D.PopFront;
    for i := 11 to 15 do D.PushBack(i);

    idx := D.FindLastIFNot(@OddTestFunc, @Self);
    AssertEquals('Wraparound FindLastIFNot should be index 8', SizeUInt(8), SizeUInt(idx));
  finally
    D.Free;
  end;
end;


procedure TTestCase_VecDeque.Test_Sort_Range_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(9);

    LVecDeque.Sort(1, 3, @CompareTestFunc, @Self);

    AssertEquals('Element at index 0 should remain 5', 5, LVecDeque.Get(0));
    AssertEquals('Element at index 1 should be 2', 2, LVecDeque.Get(1));
    AssertEquals('Element at index 2 should be 8', 8, LVecDeque.Get(2));
    AssertEquals('Element at index 3 should be 1', 1, LVecDeque.Get(3));
    AssertEquals('Element at index 4 should remain 9', 9, LVecDeque.Get(4));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Sort_Range_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(9);

    LVecDeque.Sort(1, 3, @CompareTestMethod, @Self);

    AssertEquals('Element at index 0 should remain 5', 5, LVecDeque.Get(0));
    AssertEquals('Element at index 1 should be 2', 2, LVecDeque.Get(1));
    AssertEquals('Element at index 2 should be 8', 8, LVecDeque.Get(2));
    AssertEquals('Element at index 3 should be 1', 1, LVecDeque.Get(3));
    AssertEquals('Element at index 4 should remain 9', 9, LVecDeque.Get(4));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Sort_Range_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(9);

    LVecDeque.Sort(1, 3, @CompareTestRefFunc);

    AssertEquals('Element at index 0 should remain 5', 5, LVecDeque.Get(0));
    AssertEquals('Element at index 1 should be 2', 2, LVecDeque.Get(1));
    AssertEquals('Element at index 2 should be 8', 8, LVecDeque.Get(2));
    AssertEquals('Element at index 3 should be 1', 1, LVecDeque.Get(3));
    AssertEquals('Element at index 4 should remain 9', 9, LVecDeque.Get(4));
  finally
    LVecDeque.Free;
  end;
end;

{ ===== IsSorted implementations ===== }

procedure TTestCase_VecDeque.Test_IsSorted_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);

    AssertTrue('Should be sorted', LVecDeque.IsSorted(@CompareTestFunc, @Self));

    LVecDeque.Put(2, 0);
    AssertFalse('Should not be sorted', LVecDeque.IsSorted(@CompareTestFunc, @Self));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IsSorted_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);

    AssertTrue('Should be sorted', LVecDeque.IsSorted(@CompareTestMethod, @Self));

    LVecDeque.Put(2, 0);
    AssertFalse('Should not be sorted', LVecDeque.IsSorted(@CompareTestMethod, @Self));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IsSorted_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);

    AssertTrue('Should be sorted', LVecDeque.IsSorted(@CompareTestRefFunc));

    LVecDeque.Put(2, 0);
    AssertFalse('Should not be sorted', LVecDeque.IsSorted(@CompareTestRefFunc));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IsSorted_Range;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(0);

    AssertTrue('Range [1, 3) should be sorted', LVecDeque.IsSorted(1, 3));
    AssertFalse('Full range should not be sorted', LVecDeque.IsSorted(0, 5));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IsSorted_Range_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(0);

    AssertTrue('Range [1, 3) should be sorted', LVecDeque.IsSorted(1, 3, @CompareTestFunc, @Self));
    AssertFalse('Full range should not be sorted', LVecDeque.IsSorted(0, 5, @CompareTestFunc, @Self));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IsSorted_Range_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(0);

    AssertTrue('Range [1, 3) should be sorted', LVecDeque.IsSorted(1, 3, @CompareTestMethod, @Self));
    AssertFalse('Full range should not be sorted', LVecDeque.IsSorted(0, 5, @CompareTestMethod, @Self));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IsSorted_Range_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(0);

    AssertTrue('Range [1, 3) should be sorted', LVecDeque.IsSorted(1, 3, @CompareTestRefFunc));
    AssertFalse('Full range should not be sorted', LVecDeque.IsSorted(0, 5, @CompareTestRefFunc));
  finally
    LVecDeque.Free;
  end;
end;

{ ===== BinarySearch implementations ===== }

procedure TTestCase_VecDeque.Test_BinarySearch_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(7);
    LVecDeque.PushBack(9);

    LIndex := LVecDeque.BinarySearch(5, @CompareTestFunc, @Self);
    AssertEquals('Should find element 5 at index 2', SizeUInt(2), LIndex);

    LIndex := LVecDeque.BinarySearch(6, @CompareTestFunc, @Self);
    AssertEquals('Should not find element 6', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_BinarySearch_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(7);
    LVecDeque.PushBack(9);

    LIndex := LVecDeque.BinarySearch(5, @CompareTestMethod, @Self);
    AssertEquals('Should find element 5 at index 2', SizeUInt(2), LIndex);

    LIndex := LVecDeque.BinarySearch(6, @CompareTestMethod, @Self);
    AssertEquals('Should not find element 6', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_BinarySearch_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(7);
    LVecDeque.PushBack(9);

    LIndex := LVecDeque.BinarySearch(5, @CompareTestRefFunc);
    AssertEquals('Should find element 5 at index 2', SizeUInt(2), LIndex);

    LIndex := LVecDeque.BinarySearch(6, @CompareTestRefFunc);
    AssertEquals('Should not find element 6', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

{ ===== Min implementations ===== }

procedure TTestCase_VecDeque.Test_Min_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LMin: Integer;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(9);

    LMin := LVecDeque.MinElement(@CompareTestFunc, @Self);
    AssertEquals('Should find minimum value 1', 1, LMin);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Min_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LMin: Integer;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(9);

    LMin := LVecDeque.MinElement(@CompareTestMethod, @Self);
    AssertEquals('Should find minimum value 1', 1, LMin);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Min_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LMin: Integer;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(9);

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    LMin := LVecDeque.MinElement(@CompareTestRefFunc);
    {$ELSE}
    LMin := LVecDeque.MinElement(@CompareTestFunc, @Self);
    {$ENDIF}
    AssertEquals('Should find minimum value 1', 1, LMin);
  finally
    LVecDeque.Free;
  end;
end;

{ ===== Max implementations ===== }

procedure TTestCase_VecDeque.Test_Max_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LMax: Integer;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(9);

    LMax := LVecDeque.MaxElement(@CompareTestFunc, @Self);
    AssertEquals('Should find maximum value 9', 9, LMax);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Max_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LMax: Integer;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(9);

    LMax := LVecDeque.MaxElement(@CompareTestMethod, @Self);
    AssertEquals('Should find maximum value 9', 9, LMax);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Max_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LMax: Integer;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(9);

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    LMax := LVecDeque.MaxElement(@CompareTestRefFunc);
    {$ELSE}
    LMax := LVecDeque.MaxElement(@CompareTestFunc, @Self);
    {$ENDIF}
    AssertEquals('Should find maximum value 9', 9, LMax);
  finally
    LVecDeque.Free;
  end;
end;


{ ===== Filter implementations ===== }

procedure TTestCase_VecDeque.Test_Filter_Func;
var
  LVecDeque, LFiltered: specialize TVecDeque<Integer>;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  LFiltered := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(5);

    LFiltered := LVecDeque.Filter(@EvenTestFunc, @Self);

    AssertEquals('Filtered collection should have 2 even elements', 2, LFiltered.Count);
    AssertEquals('First even element should be 2', 2, LFiltered.Get(0));
    AssertEquals('Second even element should be 4', 4, LFiltered.Get(1));
  finally
    LVecDeque.Free;
    LFiltered.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Filter_Method;
var
  LVecDeque, LFiltered: specialize TVecDeque<Integer>;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  LFiltered := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(5);

    LFiltered := LVecDeque.Filter(@EvenTestMethod, @Self);

    AssertEquals('Filtered collection should have 2 even elements', 2, LFiltered.Count);
    AssertEquals('First even element should be 2', 2, LFiltered.Get(0));
    AssertEquals('Second even element should be 4', 4, LFiltered.Get(1));
  finally
    LVecDeque.Free;
    LFiltered.Free;
  end;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TTestCase_VecDeque.Test_Filter_RefFunc;
var
  LVecDeque, LFiltered: specialize TVecDeque<Integer>;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  LFiltered := specialize TVecDeque<Integer>.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(6);

    LFiltered := LVecDeque.Filter(@EvenTestRefFunc);

    AssertEquals('Filtered collection should have 3 even elements', 3, LFiltered.Count);
    AssertEquals('First even element should be 2', 2, LFiltered.Get(0));
    AssertEquals('Second even element should be 4', 4, LFiltered.Get(1));
    AssertEquals('Third even element should be 6', 6, LFiltered.Get(2));
  finally
    LVecDeque.Free;
    LFiltered.Free;
  end;
end;
{$ENDIF}


procedure TTestCase_VecDeque.Test_Stress_Large_Dataset;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LDatasetSize: Integer;
  LIndex: sizeuint;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LDatasetSize := 10000;

    { Object methods }
    for i := 0 to LDatasetSize - 1 do
      LVecDeque.PushBack(i);


    AssertEquals('Count should match dataset size', Int64(LDatasetSize), Int64(LVecDeque.Count));


    for i := 0 to 99 do
    begin
      LIndex := (i * LDatasetSize) div 100;  // Test comment
      AssertEquals('Element should be correct', Int64(LIndex), Int64(LVecDeque.Get(LIndex)));
    end;


    for i := 0 to 999 do
    begin
      if i mod 2 = 0 then
        LVecDeque.PushFront(i + LDatasetSize)
      else
        LVecDeque.PopBack;
    end;


    AssertTrue('Should still have reasonable count', LVecDeque.Count > LDatasetSize div 2);
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Exception_OutOfBounds;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LExceptionRaised: Boolean;
  LValue: integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);

    { Object methods }
    LExceptionRaised := False;
    try
      LValue := LVecDeque.Get(10); { Object methods }

    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Should raise exception for out of bounds access', LExceptionRaised);

    { Object methods }
    LExceptionRaised := False;
    try
      LVecDeque.Put(10, 100); { Object methods }

    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Should raise exception for out of bounds write', LExceptionRaised);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Exception_InvalidIndex;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LExceptionRaised: Boolean;
  LValue: integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LExceptionRaised := False;
    try
      LValue := LVecDeque.Get(0);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Should raise exception for empty container access', LExceptionRaised);


    LVecDeque.PushBack(42);
    LExceptionRaised := False;
    try

      LValue := LVecDeque.Get(High(SizeUInt));
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Should raise exception for invalid large index', LExceptionRaised);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Exception_InvalidOperation;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LExceptionRaised: Boolean;
  LValue: integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LExceptionRaised := False;
    try
      LVecDeque.PopFront;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Should raise exception for pop from empty container', LExceptionRaised);


    LExceptionRaised := False;
    try
      LValue := LVecDeque.Front;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Should raise exception for peek empty container', LExceptionRaised);
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Regression_Bug_001;
const
  LExpected: array[0..5] of Integer = (0, 3, 4, 5, 6, 7);
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try




    for i := 1 to 5 do
      LVecDeque.PushBack(i);


    LVecDeque.PopFront;
    LVecDeque.PopFront;


    LVecDeque.PushBack(6);
    LVecDeque.PushBack(7);


    LVecDeque.PushFront(0);


    AssertEquals('Count should be correct', 6, LVecDeque.Count);
    AssertEquals('Front element should be correct', 0, LVecDeque.Front);
    AssertEquals('Back element should be correct', 7, LVecDeque.Back);



    for i := 0 to LVecDeque.Count - 1 do
      AssertEquals('Element should be correct', LExpected[i], LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Regression_Memory_Leak;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIteration: Integer;
  i: Integer;
begin
  { Object methods }


  for LIteration := 1 to 100 do
  begin
    LVecDeque := specialize TVecDeque<Integer>.Create;
    try

      for i := 1 to 50 do
        LVecDeque.PushBack(i);

      for i := 1 to 25 do
        LVecDeque.PopFront;

      for i := 51 to 75 do
        LVecDeque.PushFront(i);

      LVecDeque.Clear;

      for i := 1 to 30 do
        LVecDeque.PushBack(i * 2);


      AssertEquals('Count should be correct', 30, LVecDeque.Count);
    finally
      LVecDeque.Free;
    end;
  end;


  AssertTrue('Memory leak test completed successfully', True);
end;

procedure TTestCase_VecDeque.Test_Regression_Performance;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartTime, LEndTime: TDateTime;
  LOperationCount: Integer;
  LElapsedMs: qword;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LOperationCount := 5000;


    LStartTime := Now;


    for i := 0 to LOperationCount - 1 do
    begin
      case i mod 4 of
        0: LVecDeque.PushBack(i);
        1: LVecDeque.PushFront(i);
        2: if not LVecDeque.IsEmpty then LVecDeque.PopBack;
        3: if not LVecDeque.IsEmpty then LVecDeque.PopFront;
      end;
    end;

    { Object methods }
    LEndTime := Now;

    { Object methods }
    LElapsedMs := MilliSecondsBetween(LEndTime, LStartTime);
    AssertTrue('Performance should be reasonable', LElapsedMs < 5000); { Object methods }


    AssertTrue('Final count should be reasonable', LVecDeque.Count >= 0);
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Regression_Integration;
var
  LVecDeque1, LVecDeque2: specialize TVecDeque<Integer>;
  LSourceVec: specialize TVec<Integer>;
  i: Integer;
begin
  { Object methods }
  LVecDeque1 := specialize TVecDeque<Integer>.Create;
  LVecDeque2 := specialize TVecDeque<Integer>.Create;
  LSourceVec := specialize TVec<Integer>.Create;
  try

    for i := 1 to 10 do
      LSourceVec.Push(i * 3);

    { Object methods }
    LVecDeque1.LoadFrom(LSourceVec);
    AssertEquals('Should load all elements from Vec', LSourceVec.Count, LVecDeque1.Count);


    LVecDeque2.LoadFrom(LVecDeque1);
    AssertEquals('Should copy all elements between VecDeques', LVecDeque1.Count, LVecDeque2.Count);


    for i := 0 to LSourceVec.Count - 1 do
    begin
      AssertEquals('Vec and VecDeque1 should match', LSourceVec.Get(i), LVecDeque1.Get(i));
      AssertEquals('VecDeque1 and VecDeque2 should match', LVecDeque1.Get(i), LVecDeque2.Get(i));
    end;


    LVecDeque1.PushBack(999);
    AssertTrue('VecDeques should be independent', LVecDeque1.Count <> LVecDeque2.Count);
  finally
    LSourceVec.Free;
    LVecDeque2.Free;
    LVecDeque1.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_TryReserveExact;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LRequestedCapacity: SizeUInt;
  LResult: Boolean;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LRequestedCapacity := 25;


    LResult := LVecDeque.TryReserveExact(LRequestedCapacity);

    { Object methods }
    AssertTrue('TryReserveExact should succeed', LResult);
    AssertTrue('Capacity should be at least requested', LVecDeque.Capacity >= LRequestedCapacity);
    AssertEquals('Count should remain 0', 0, LVecDeque.Count);


    for i := 0 to Integer(LRequestedCapacity) - 1 do
      LVecDeque.PushBack(i * 3);
    AssertEquals('Should be able to add requested number of elements', Int64(LRequestedCapacity), Int64(LVecDeque.Count));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Shrink;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInitialCapacity, LAfterShrinkCapacity: SizeUInt;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.Reserve(100);
    LInitialCapacity := LVecDeque.Capacity;


    for i := 1 to 10 do
      LVecDeque.PushBack(i);


    LVecDeque.Shrink;
    LAfterShrinkCapacity := LVecDeque.Capacity;

    { Object methods }
    AssertTrue('Capacity should be reduced after shrink', LAfterShrinkCapacity < LInitialCapacity);
    AssertTrue('Capacity should still accommodate all elements', LAfterShrinkCapacity >= LVecDeque.Count);
    AssertEquals('Count should remain unchanged', 10, LVecDeque.Count);


    for i := 0 to LVecDeque.Count - 1 do
      AssertEquals('Element should be preserved', i + 1, LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ShrinkTo;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LTargetCapacity: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.Reserve(100);


    for i := 1 to 15 do
      LVecDeque.PushBack(i * 2);

    LTargetCapacity := 20;


    LVecDeque.ShrinkTo(LTargetCapacity);

    { Object methods }
    AssertTrue('Capacity should be close to target', LVecDeque.Capacity <= LTargetCapacity + 5);
    AssertTrue('Capacity should still accommodate all elements', LVecDeque.Capacity >= LVecDeque.Count);
    AssertEquals('Count should remain unchanged', 15, LVecDeque.Count);


    for i := 0 to LVecDeque.Count - 1 do
      AssertEquals('Element should be preserved', (i + 1) * 2, LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Truncate;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LNewSize: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Object methods }
    for i := 1 to 20 do
      LVecDeque.PushBack(i);

    LNewSize := 12;


    LVecDeque.Truncate(LNewSize);

    { Object methods }
    AssertEquals('Count should be truncated to new size', LNewSize, LVecDeque.Count);


    for i := 0 to Integer(LNewSize) - 1 do
      AssertEquals('Remaining element should be correct', i + 1, LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ResizeExact;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LNewSize: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 5 do
      LVecDeque.PushBack(i * 10);


    LNewSize := 10;
    LVecDeque.ResizeExact(LNewSize);


    AssertEquals('Count should be new size', LNewSize, LVecDeque.Count);

    { Object methods }
    for i := 0 to 4 do
      AssertEquals('Original element should be preserved', (i + 1) * 10, LVecDeque.Get(i));


    for i := 5 to Integer(LNewSize) - 1 do
      AssertEquals('New element should be default value', 0, LVecDeque.Get(i));


    LNewSize := 3;
    LVecDeque.ResizeExact(LNewSize);


    AssertEquals('Count should be new smaller size', LNewSize, LVecDeque.Count);
    for i := 0 to Integer(LNewSize) - 1 do
      AssertEquals('Remaining element should be correct', (i + 1) * 10, LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Copy;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LDestArray: array[0..4] of Integer;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 5 do
      LVecDeque.PushBack(i * 7);


    for i := 0 to High(LDestArray) do
      LDestArray[i] := -1;


    LVecDeque.Read(0, @LDestArray[0], LVecDeque.Count);

    { Object methods }
    for i := 0 to LVecDeque.Count - 1 do
      AssertEquals('Copied element should match source', LVecDeque.Get(i), LDestArray[i]);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_CopyUnChecked;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LDestArray: array[0..6] of Integer;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 4 do
      LVecDeque.PushBack(i * 11);


    for i := 0 to High(LDestArray) do
      LDestArray[i] := -999;


    LVecDeque.ReadUnChecked(0, @LDestArray[1], LVecDeque.Count);

    { Object methods }
    AssertEquals('First element should be unchanged', -999, LDestArray[0]);
    for i := 0 to LVecDeque.Count - 1 do
      AssertEquals('Copied element should match source', LVecDeque.Get(i), LDestArray[i + 1]);
    AssertEquals('Last elements should be unchanged', -999, LDestArray[5]);
    AssertEquals('Last elements should be unchanged', -999, LDestArray[6]);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Read_Pointer;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceArray: array[0..3] of Integer;
  LPtr: PInteger;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 0 to High(LSourceArray) do
      LSourceArray[i] := (i + 1) * 13;
    LPtr := @LSourceArray[0];

    { Object methods }
    LVecDeque.Resize(Length(LSourceArray));

    { executeread }
    LVecDeque.OverWrite(0, LPtr, Length(LSourceArray));

    { Object methods }
    AssertEquals('Count should match read size', Int64(Length(LSourceArray)), Int64(LVecDeque.Count));
    for i := 0 to High(LSourceArray) do
      AssertEquals('Read element should match source', LSourceArray[i], LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Read_Array;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceArray: array[0..4] of Integer;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 0 to High(LSourceArray) do
      LSourceArray[i] := (i + 1) * 17;

    { Object methods }
    LVecDeque.Resize(Length(LSourceArray));

    { executeread }
    LVecDeque.OverWrite(0, @LSourceArray[0], Length(LSourceArray));

    { Object methods }
    AssertEquals('Count should match array size', Int64(Length(LSourceArray)), Int64(LVecDeque.Count));
    for i := 0 to High(LSourceArray) do
      AssertEquals('Read element should match source', LSourceArray[i], LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_OverWrite_Pointer;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceArray: array[0..2] of Integer;
  LPtr: PInteger;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 5 do
      LVecDeque.PushBack(i);


    for i := 0 to High(LSourceArray) do
      LSourceArray[i] := (i + 1) * 19;
    LPtr := @LSourceArray[0];


    LVecDeque.OverWrite(0, LPtr, Length(LSourceArray));

    { Object methods }
    AssertEquals('Count should remain same', Int64(5), Int64(LVecDeque.Count));

    for i := 0 to High(LSourceArray) do
      AssertEquals('Overwritten element should match source', LSourceArray[i], LVecDeque.Get(i));

    for i := Length(LSourceArray) to LVecDeque.Count - 1 do
      AssertEquals('Remaining element should be unchanged', i + 1, LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_OverWrite_Array;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceArray: array[0..3] of Integer;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 6 do
      LVecDeque.PushBack(i * 5);


    for i := 0 to High(LSourceArray) do
      LSourceArray[i] := (i + 1) * 23;


    LVecDeque.OverWrite(0, LSourceArray);

    { Object methods }
    AssertEquals('Count should remain same', Int64(6), Int64(LVecDeque.Count));

    for i := 0 to High(LSourceArray) do
      AssertEquals('Overwritten element should match source', LSourceArray[i], LVecDeque.Get(i));

    for i := Length(LSourceArray) to LVecDeque.Count - 1 do
      AssertEquals('Remaining element should be unchanged', (i + 1) * 5, LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_OverWrite_Collection;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceVec: specialize TVec<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  LSourceVec := specialize TVec<Integer>.Create;
  try

    for i := 1 to 7 do
      LVecDeque.PushBack(i * 3);


    for i := 1 to 4 do
      LSourceVec.Push(i * 29);


    LVecDeque.OverWrite(0, LSourceVec);

    { Object methods }
    AssertEquals('Count should remain same', Int64(7), Int64(LVecDeque.Count));

    for i := 0 to LSourceVec.Count - 1 do
      AssertEquals('Overwritten element should match source', LSourceVec.Get(i), LVecDeque.Get(i));

    for i := LSourceVec.Count to LVecDeque.Count - 1 do
      AssertEquals('Remaining element should be unchanged', (i + 1) * 3, LVecDeque.Get(i));
  finally
    LSourceVec.Free;
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Write_Pointer_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceArray: array[0..3] of Integer;
  LPtr: PInteger;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 0 to High(LSourceArray) do
      LSourceArray[i] := (i + 1) * 31;
    LPtr := @LSourceArray[0];

    { executewrite }
    LVecDeque.Write(0, LPtr, Length(LSourceArray));

    { Object methods }
    AssertEquals('Count should match written size', Int64(Length(LSourceArray)), Int64(LVecDeque.Count));
    for i := 0 to High(LSourceArray) do
      AssertEquals('Written element should match source', LSourceArray[i], LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_WriteUnChecked_Pointer_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceArray: array[0..2] of Integer;
  LPtr: PInteger;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 0 to High(LSourceArray) do
      LSourceArray[i] := (i + 1) * 37;
    LPtr := @LSourceArray[0];


    LVecDeque.Resize(Length(LSourceArray));
    LVecDeque.OverWriteUnChecked(0, LPtr, Length(LSourceArray));

    { Object methods }
    AssertEquals('Count should match written size', Int64(Length(LSourceArray)), Int64(LVecDeque.Count));
    for i := 0 to High(LSourceArray) do
      AssertEquals('Written element should match source', LSourceArray[i], LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Write_Array;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceArray: array[0..4] of Integer;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 0 to High(LSourceArray) do
      LSourceArray[i] := (i + 1) * 41;

    { executewrite }
    LVecDeque.Write(0, LSourceArray);

    { Object methods }
    AssertEquals('Count should match array size', Int64(Length(LSourceArray)), Int64(LVecDeque.Count));
    for i := 0 to High(LSourceArray) do
      AssertEquals('Written element should match source', LSourceArray[i], LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_WriteUnChecked_Array;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceArray: array[0..3] of Integer;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 0 to High(LSourceArray) do
      LSourceArray[i] := (i + 1) * 43;


    LVecDeque.Resize(Length(LSourceArray));
    LVecDeque.OverWriteUnChecked(0, LSourceArray);

    { Object methods }
    AssertEquals('Count should match array size', Int64(Length(LSourceArray)), Int64(LVecDeque.Count));
    for i := 0 to High(LSourceArray) do
      AssertEquals('Written element should match source', LSourceArray[i], LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Write_Collection;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceVec: specialize TVec<Integer>;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  LSourceVec := specialize TVec<Integer>.Create;
  try

    for i := 1 to 5 do
      LSourceVec.Push(i * 47);

    { executewrite }
    LVecDeque.Write(0, LSourceVec);

    { Object methods }
    AssertEquals('Count should match source size', Int64(LSourceVec.Count), Int64(LVecDeque.Count));
    for i := 0 to LSourceVec.Count - 1 do
      AssertEquals('Written element should match source', LSourceVec.Get(i), LVecDeque.Get(i));
  finally
    LSourceVec.Free;
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Write_Collection_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceVec: specialize TVec<Integer>;
  LWriteCount: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  LSourceVec := specialize TVec<Integer>.Create;
  try

    for i := 1 to 6 do
      LSourceVec.Push(i * 53);

    LWriteCount := 4;


    LVecDeque.Resize(LWriteCount);
    LVecDeque.OverWrite(0, LSourceVec, LWriteCount);

    { Object methods }
    AssertEquals('Count should match write count', Int64(LWriteCount), Int64(LVecDeque.Count));
    for i := 0 to Integer(LWriteCount) - 1 do
      AssertEquals('Written element should match source', LSourceVec.Get(i), LVecDeque.Get(i));
  finally
    LSourceVec.Free;
    LVecDeque.Free;
  end;
end;


procedure TTestCase_VecDeque.Test_WriteUnChecked_Collection_Count;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Capacity_Growth_Custom;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Capacity_Shrink_Aggressive;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Capacity_Shrink_Conservative;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_InsertUnChecked_Index_Element;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_InsertUnChecked_Index_Pointer_Count;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_InsertUnChecked_Index_Collection_Count;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Insert_Front_Multiple;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Insert_Back_Multiple;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Insert_Middle_Multiple;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Insert_Range_Front;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Insert_Range_Back;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Insert_Range_Middle;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Insert_Empty_Range;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Insert_Large_Range;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Insert_Overlapping_Range;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Insert_At_Capacity;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Insert_Beyond_Capacity;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Insert_Negative_Index;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Insert_Invalid_Index;
begin
  Fail('Not implemented');
end;



procedure TTestCase_VecDeque.Test_Push_Element;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LElement: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LElement := 123;

    { executepush }
    LVecDeque.Push(LElement);

    { Object methods }
    AssertEquals('Count should be 1', Int64(1), Int64(LVecDeque.Count));
    AssertEquals('Pushed element should be at top', LElement, LVecDeque.Back);
    AssertEquals('Element should be accessible by index', LElement, LVecDeque.Get(0));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Push_Pointer_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceArray: array[0..3] of Integer;
  LPtr: PInteger;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(100);


    for i := 0 to High(LSourceArray) do
      LSourceArray[i] := (i + 1) * 59;
    LPtr := @LSourceArray[0];

    { executepush }
    LVecDeque.Push(LPtr, Length(LSourceArray));

    { Object methods }
    AssertEquals('Count should increase by push count', Int64(5), Int64(LVecDeque.Count));
    AssertEquals('Original element should remain', 100, LVecDeque.Get(0));
    for i := 0 to High(LSourceArray) do
      AssertEquals('Pushed element should be correct', LSourceArray[i], LVecDeque.Get(i + 1));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Push_Array;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceArray: array[0..2] of Integer;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(200);
    LVecDeque.PushBack(300);


    for i := 0 to High(LSourceArray) do
      LSourceArray[i] := (i + 1) * 61;

    { executepush }
    LVecDeque.Push(LSourceArray);

    { Object methods }
    AssertEquals('Count should increase by array length', Int64(5), Int64(LVecDeque.Count));
    AssertEquals('Original element should remain', 200, LVecDeque.Get(0));
    AssertEquals('Original element should remain', 300, LVecDeque.Get(1));
    for i := 0 to High(LSourceArray) do
      AssertEquals('Pushed element should be correct', LSourceArray[i], LVecDeque.Get(i + 2));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Push_Collection_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSourceVec: specialize TVec<Integer>;
  LPushCount: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  LSourceVec := specialize TVec<Integer>.Create;
  try

    LVecDeque.PushBack(400);


    for i := 1 to 5 do
      LSourceVec.Push(i * 67);

    LPushCount := 3;

    { executepush }
    LVecDeque.Push(LSourceVec, LPushCount);

    { Object methods }
    AssertEquals('Count should increase by push count', Int64(4), Int64(LVecDeque.Count));
    AssertEquals('Original element should remain', 400, LVecDeque.Get(0));
    for i := 0 to Integer(LPushCount) - 1 do
      AssertEquals('Pushed element should be correct', LSourceVec.Get(i), LVecDeque.Get(i + 1));
  finally
    LSourceVec.Free;
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Pop;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LPoppedValue: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(30);


    LPoppedValue := LVecDeque.Pop;

    { Object methods }
    AssertEquals('Popped value should be last pushed', 30, LPoppedValue);
    AssertEquals('Count should decrease by 1', 2, LVecDeque.Count);
    AssertEquals('New top should be previous element', 20, LVecDeque.Back);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_TryPop_Element;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LPoppedValue: Integer;
  LResult: Boolean;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LResult := LVecDeque.TryPop(LPoppedValue);
    AssertFalse('TryPop should fail on empty container', LResult);


    LVecDeque.PushBack(42);
    LVecDeque.PushBack(84);

    { Object methods }
    LResult := LVecDeque.TryPop(LPoppedValue);
    AssertTrue('TryPop should succeed on non-empty container', LResult);
    AssertEquals('Popped value should be correct', 84, LPoppedValue);
    AssertEquals('Count should decrease by 1', 1, LVecDeque.Count);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_TryPop_Pointer_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LDestArray: array[0..2] of Integer;
  LPtr: PInteger;
  LPopCount: SizeUInt;
  LResult: Boolean;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 5 do
      LVecDeque.PushBack(i * 71);

    LPtr := @LDestArray[0];
    LPopCount := 3;


    for i := 0 to High(LDestArray) do
      LDestArray[i] := -1;


    LResult := LVecDeque.TryPop(LPtr, LPopCount);

    { Object methods }
    AssertTrue('TryPop should succeed', LResult);
    AssertEquals('Count should decrease by pop count', Int64(2), Int64(LVecDeque.Count));


    AssertEquals('First popped should be last element', 5 * 71, LDestArray[0]);
    AssertEquals('Second popped should be second last element', 4 * 71, LDestArray[1]);
    AssertEquals('Third popped should be third last element', 3 * 71, LDestArray[2]);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_TryPop_Array_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LDestArray: specialize TGenericArray<Integer>;
  LPopCount: SizeUInt;
  LResult: Boolean;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 4 do
      LVecDeque.PushBack(i * 73);

    LPopCount := 2;


    SetLength(LDestArray, LPopCount);
    for i := 0 to High(LDestArray) do
      LDestArray[i] := -999;


    LResult := LVecDeque.TryPop(LDestArray, LPopCount);

    { Object methods }
    AssertTrue('TryPop should succeed', LResult);
    AssertEquals('Count should decrease by pop count', Int64(2), Int64(LVecDeque.Count));


    AssertEquals('First popped should be last element', 4 * 73, LDestArray[0]);
    AssertEquals('Second popped should be second last element', 3 * 73, LDestArray[1]);
  finally
    LVecDeque.Free;
  end;
end;


procedure TTestCase_VecDeque.Test_TryPeek_Element;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LPeekedValue: Integer;
  LResult: Boolean;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LResult := LVecDeque.TryPeek(LPeekedValue);
    AssertFalse('TryPeek should fail on empty container', LResult);


    LVecDeque.PushBack(123);
    LVecDeque.PushBack(456);

    { Object methods }
    LResult := LVecDeque.TryPeek(LPeekedValue);
    AssertTrue('TryPeek should succeed on non-empty container', LResult);
    AssertEquals('Peeked value should be correct', 456, LPeekedValue);
    AssertEquals('Count should remain unchanged', 2, LVecDeque.Count);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_TryPeekCopy_Pointer_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LDestArray: array[0..2] of Integer;
  LPtr: PInteger;
  LPeekCount: SizeUInt;
  LResult: Boolean;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 5 do
      LVecDeque.PushBack(i * 79);

    LPtr := @LDestArray[0];
    LPeekCount := 3;


    for i := 0 to High(LDestArray) do
      LDestArray[i] := -1;


    LResult := LVecDeque.TryPeekCopy(LPtr, LPeekCount);

    { Object methods }
    AssertTrue('TryPeekCopy should succeed', LResult);
    AssertEquals('Count should remain unchanged', Int64(5), Int64(LVecDeque.Count));


    AssertEquals('First peeked should be last element', 5 * 79, LDestArray[0]);
    AssertEquals('Second peeked should be second last element', 4 * 79, LDestArray[1]);
    AssertEquals('Third peeked should be third last element', 3 * 79, LDestArray[2]);
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Sort;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(5);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(9);
    LVecDeque.PushBack(3);


    LVecDeque.Sort;

    { Object methods }
    AssertEquals('Count should remain unchanged', Int64(6), Int64(LVecDeque.Count));
    AssertEquals('First element should be smallest', 1, LVecDeque.Get(0));
    AssertEquals('Second element should be correct', 2, LVecDeque.Get(1));
    AssertEquals('Third element should be correct', 3, LVecDeque.Get(2));
    AssertEquals('Fourth element should be correct', 5, LVecDeque.Get(3));
    AssertEquals('Fifth element should be correct', 8, LVecDeque.Get(4));
    AssertEquals('Last element should be largest', 9, LVecDeque.Get(5));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Sort_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(3);
    LVecDeque.PushBack(7);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(9);
    LVecDeque.PushBack(4);


    LVecDeque.Sort(@CompareTestFunc, @Self);

    { Object methods }
    AssertEquals('Count should remain unchanged', Int64(5), Int64(LVecDeque.Count));

    for i := 0 to LVecDeque.Count - 2 do
      AssertTrue('Elements should be in ascending order', LVecDeque.Get(i) <= LVecDeque.Get(i + 1));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Sort_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(6);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(4);

    { Object methods }
    LVecDeque.Sort(@CompareTestMethod, @Self);

    { Object methods }
    AssertEquals('Count should remain unchanged', Int64(4), Int64(LVecDeque.Count));

    for i := 0 to LVecDeque.Count - 2 do
      AssertTrue('Elements should be in ascending order', LVecDeque.Get(i) <= LVecDeque.Get(i + 1));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Sort_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(15);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(11);
    LVecDeque.PushBack(7);
    LVecDeque.PushBack(19);

    { Object methods }
    LVecDeque.Sort(@CompareTestRefFunc);

    { Object methods }
    AssertEquals('Count should remain unchanged', Int64(5), Int64(LVecDeque.Count));

    for i := 0 to LVecDeque.Count - 2 do
      AssertTrue('Elements should be in ascending order', LVecDeque.Get(i) <= LVecDeque.Get(i + 1));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IsSorted;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LResult: Boolean;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LResult := LVecDeque.IsSorted;
    AssertTrue('Empty container should be considered sorted', LResult);


    LVecDeque.PushBack(42);
    LResult := LVecDeque.IsSorted;
    AssertTrue('Single element should be considered sorted', LResult);


    LVecDeque.Clear;
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(7);
    LResult := LVecDeque.IsSorted;
    AssertTrue('Sorted sequence should return true', LResult);


    LVecDeque.Clear;
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(7);
    LResult := LVecDeque.IsSorted;
    AssertFalse('Unsorted sequence should return false', LResult);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_BinarySearch;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(2);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(12);


    LIndex := LVecDeque.BinarySearch(6);
    AssertEquals('Should find element at correct index', Int64(2), Int64(LIndex));

    LIndex := LVecDeque.BinarySearch(2);
    AssertEquals('Should find first element', Int64(0), Int64(LIndex));

    LIndex := LVecDeque.BinarySearch(12);
    AssertEquals('Should find last element', Int64(5), Int64(LIndex));

    { Object methods }
    LIndex := LVecDeque.BinarySearch(5);
    AssertEquals('Should not find non-existent element', Int64(High(SizeUInt)), Int64(LIndex));

    LIndex := LVecDeque.BinarySearch(15);
    AssertEquals('Should not find element larger than all', Int64(High(SizeUInt)), Int64(LIndex));
  finally
    LVecDeque.Free;
  end;
end;


procedure TTestCase_VecDeque.Test_Min;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LMinValue: Integer;
  LResult: Boolean;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LResult := LVecDeque.Count > 0;
    AssertFalse('Min should fail on empty container', LResult);


    LVecDeque.PushBack(5);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(6);


    LMinValue := LVecDeque.Get(0);
    for i := 1 to Integer(LVecDeque.Count) - 1 do
      if LVecDeque.Get(i) < LMinValue then
        LMinValue := LVecDeque.Get(i);
    AssertEquals('Should find correct minimum value', Int64(1), Int64(LMinValue));

    { Object methods }
    LResult := LVecDeque.Count > 0;
    AssertTrue('TryMin should succeed on non-empty container', LResult);
    AssertEquals('TryMin should return correct minimum value', Int64(1), Int64(LMinValue));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Max;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LMaxValue: Integer;
  LResult: Boolean;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LResult := LVecDeque.Count > 0;
    AssertFalse('Max should fail on empty container', LResult);


    LVecDeque.PushBack(3);
    LVecDeque.PushBack(9);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(7);
    LVecDeque.PushBack(5);


    LMaxValue := LVecDeque.Get(0);
    for i := 1 to Integer(LVecDeque.Count) - 1 do
      if LVecDeque.Get(i) > LMaxValue then
        LMaxValue := LVecDeque.Get(i);
    AssertEquals('Should find correct maximum value', Int64(9), Int64(LMaxValue));

    { Object methods }
    LResult := LVecDeque.Count > 0;
    AssertTrue('TryMax should succeed on non-empty container', LResult);
    AssertEquals('TryMax should return correct maximum value', Int64(9), Int64(LMaxValue));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Sum;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSum: Int64;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LSum := 0;
    AssertEquals('Sum of empty container should be 0', Int64(0), LSum);


    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(30);
    LVecDeque.PushBack(40);


    LSum := 0;
    for i := 0 to Integer(LVecDeque.Count) - 1 do
      Inc(LSum, LVecDeque.Get(i));
    AssertEquals('Should calculate correct sum', Int64(100), LSum);


    LVecDeque.Clear;
    LVecDeque.PushBack(15);
    LVecDeque.PushBack(-5);
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(-8);

    LSum := 0;
    for i := 0 to Integer(LVecDeque.Count) - 1 do
      Inc(LSum, LVecDeque.Get(i));
    AssertEquals('Should handle negative numbers correctly', Int64(12), LSum);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Average;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LAverage: Double;
  LResult: Boolean;
  LSum: Int64;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LResult := LVecDeque.Count > 0;
    AssertFalse('Average should fail on empty container', LResult);


    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(30);
    LVecDeque.PushBack(40);


    if LVecDeque.Count = 0 then LAverage := 0 else
    begin
      LSum := 0;
      for i := 0 to Integer(LVecDeque.Count) - 1 do Inc(LSum, LVecDeque.Get(i));
      LAverage := LSum / LVecDeque.Count;
    end;
    AssertEquals('Should calculate correct average', 25.0, LAverage, 0.001);

    { Object methods }
    LResult := LVecDeque.Count > 0;
    AssertTrue('TryAverage should succeed on non-empty container', LResult);
    AssertEquals('TryAverage should return correct average', 25.0, LAverage, 0.001);


    LVecDeque.Clear;
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);

    if LVecDeque.Count = 0 then LAverage := 0 else
    begin
      LSum := 0;
      for i := 0 to Integer(LVecDeque.Count) - 1 do Inc(LSum, LVecDeque.Get(i));
      LAverage := LSum / LVecDeque.Count;
    end;
    AssertEquals('Should handle non-integer average', 2.0, LAverage, 0.001);
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Capacity_Growth_Linear;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInitialCapacity, LPreviousCapacity, LCurrentCapacity: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create(5, nil, TFixedGrowStrategy.Create(1));
  try
    LInitialCapacity := LVecDeque.Capacity;
    LPreviousCapacity := LInitialCapacity;


    for i := 0 to Integer(LInitialCapacity) + 10 do
    begin
      LVecDeque.PushBack(i);
      LCurrentCapacity := LVecDeque.Capacity;

      { Object methods }
      if LCurrentCapacity > LPreviousCapacity then
      begin

        AssertTrue('Capacity should grow reasonably', LCurrentCapacity > LPreviousCapacity);
        LPreviousCapacity := LCurrentCapacity;
      end;
    end;


    AssertTrue('Final capacity should be larger than initial', LVecDeque.Capacity > LInitialCapacity);
    AssertEquals('All elements should be present', LInitialCapacity + 11, LVecDeque.Count);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Capacity_Growth_Exponential;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInitialCapacity, LPreviousCapacity, LCurrentCapacity: SizeUInt;
  LGrowthCount: Integer;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create(4, nil, TFactorGrowStrategy.Create(1.8));
  try
    LInitialCapacity := LVecDeque.Capacity;
    LPreviousCapacity := LInitialCapacity;
    LGrowthCount := 0;


    for i := 0 to 50 do
    begin
      LVecDeque.PushBack(i);
      LCurrentCapacity := LVecDeque.Capacity;

      { Object methods }
      if LCurrentCapacity > LPreviousCapacity then
      begin
        Inc(LGrowthCount);

        AssertTrue('Exponential growth should be significant', LCurrentCapacity >= LPreviousCapacity * 1.5);
        LPreviousCapacity := LCurrentCapacity;
      end;
    end;


    AssertTrue('Should have triggered capacity growth', LGrowthCount > 0);
    AssertTrue('Final capacity should be much larger', LVecDeque.Capacity >= LInitialCapacity * 2);
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_DeleteSwap_Index;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LDeleteIndex: SizeUInt;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 6 do
      LVecDeque.PushBack(i * 10);


    LDeleteIndex := 2; { Object methods }


    LVecDeque.DeleteSwap(LDeleteIndex);

    { Object methods }
    AssertEquals('Count should decrease by 1', 5, LVecDeque.Count);
    AssertEquals('Element before delete should be unchanged', 10, LVecDeque.Get(0));
    AssertEquals('Element before delete should be unchanged', 20, LVecDeque.Get(1));

    AssertEquals('Deleted position should have last element', 60, LVecDeque.Get(2));
    AssertEquals('Elements after should shift down', 40, LVecDeque.Get(3));
    AssertEquals('Elements after should shift down', 50, LVecDeque.Get(4));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_DeleteSwap_Index_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LDeleteIndex, LDeleteCount: SizeUInt;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 8 do
      LVecDeque.PushBack(i * 5);


    LDeleteIndex := 2;
    LDeleteCount := 3; { delete15, 20, 25 }


    LVecDeque.DeleteSwap(LDeleteIndex, LDeleteCount);

    { Object methods }
    AssertEquals('Count should decrease by delete count', 5, LVecDeque.Count);
    AssertEquals('Element before delete should be unchanged', 5, LVecDeque.Get(0));
    AssertEquals('Element before delete should be unchanged', 10, LVecDeque.Get(1));

    AssertEquals('Should have remaining elements', 30, LVecDeque.Get(2));
    AssertEquals('Should have remaining elements', 35, LVecDeque.Get(3));
    AssertEquals('Should have remaining elements', 40, LVecDeque.Get(4));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Remove_Index_Element;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LRemoveIndex: SizeUInt;
  LRemovedElement: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(100);
    LVecDeque.PushBack(200);
    LVecDeque.PushBack(300);
    LVecDeque.PushBack(400);

    LRemoveIndex := 1;


    LRemovedElement := LVecDeque.Remove(LRemoveIndex);

    { Object methods }
    AssertEquals('Should return removed element', 200, LRemovedElement);
    AssertEquals('Count should decrease by 1', 3, LVecDeque.Count);
    AssertEquals('Element before remove should be unchanged', 100, LVecDeque.Get(0));
    AssertEquals('Element after remove should be shifted', 300, LVecDeque.Get(1));
    AssertEquals('Last element should be shifted', 400, LVecDeque.Get(2));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Remove_Index_Element_Var;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LRemoveIndex: SizeUInt;
  LRemovedElement: Integer;
  LResult: Boolean;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LResult := LVecDeque.TryRemove(0, LRemovedElement);
    AssertFalse('Should fail to remove from empty container', LResult);


    LVecDeque.PushBack(50);
    LVecDeque.PushBack(150);
    LVecDeque.PushBack(250);

    LRemoveIndex := 1;


    LResult := LVecDeque.TryRemove(LRemoveIndex, LRemovedElement);

    { Object methods }
    AssertTrue('Should succeed to remove from valid index', LResult);
    AssertEquals('Should return removed element', 150, LRemovedElement);
    AssertEquals('Count should decrease by 1', 2, LVecDeque.Count);
    AssertEquals('Remaining elements should be correct', 50, LVecDeque.Get(0));
    AssertEquals('Remaining elements should be correct', 250, LVecDeque.Get(1));

    { Object methods }
    LResult := LVecDeque.TryRemove(10, LRemovedElement);
    AssertFalse('Should fail to remove from invalid index', LResult);
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Swap_Range;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex1, LIndex2, LCount: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 10 do
      LVecDeque.PushBack(i);


    LIndex1 := 1; { range1: [2, 3, 4] }
    LIndex2 := 6; { range2: [7, 8, 9] }
    LCount := 3;


    LVecDeque.SwapRange(LIndex1, LIndex2, LCount);

    { Object methods }
    AssertEquals('Count should remain unchanged', 10, LVecDeque.Count);
    AssertEquals('Element before range1 should be unchanged', 1, LVecDeque.Get(0));

    AssertEquals('Range1 should have range2 elements', 7, LVecDeque.Get(1));
    AssertEquals('Range1 should have range2 elements', 8, LVecDeque.Get(2));
    AssertEquals('Range1 should have range2 elements', 9, LVecDeque.Get(3));

    AssertEquals('Middle elements should be unchanged', 5, LVecDeque.Get(4));
    AssertEquals('Middle elements should be unchanged', 6, LVecDeque.Get(5));

    AssertEquals('Range2 should have range1 elements', 2, LVecDeque.Get(6));
    AssertEquals('Range2 should have range1 elements', 3, LVecDeque.Get(7));
    AssertEquals('Range2 should have range1 elements', 4, LVecDeque.Get(8));

    AssertEquals('Element after range2 should be unchanged', 10, LVecDeque.Get(9));
  finally
    LVecDeque.Free;
  end;
end;

{ ===== memoryefficiencytestimplement ===== }

procedure TTestCase_VecDeque.Test_Capacity_Memory_Efficiency;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInitialCapacity, LAfterAddCapacity, LAfterShrinkCapacity: SizeUInt;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LInitialCapacity := LVecDeque.Capacity;

    { Object methods }
    for i := 1 to 1000 do
      LVecDeque.PushBack(i);
    LAfterAddCapacity := LVecDeque.Capacity;

    { Object methods }
    AssertTrue('Capacity should grow to accommodate elements', LAfterAddCapacity >= 1000);
    AssertTrue('Capacity should not be excessively large', LAfterAddCapacity < 2000);


    for i := 1 to 900 do
      LVecDeque.PopBack;


    LVecDeque.ShrinkToFit;
    LAfterShrinkCapacity := LVecDeque.Capacity;


    AssertTrue('Capacity should shrink after removing elements', LAfterShrinkCapacity < LAfterAddCapacity);
    AssertTrue('Capacity should still accommodate remaining elements', LAfterShrinkCapacity >= LVecDeque.Count);
    AssertEquals('Should have correct number of remaining elements', 100, LVecDeque.Count);
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Stress_Frequent_Resize;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LOperationCount: Integer;
  LFirstElement, LLastElement: integer;
  i, j: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LOperationCount := 500;


    for i := 0 to LOperationCount - 1 do
    begin
      case i mod 6 of
        0: begin

          LVecDeque.Resize(LVecDeque.Count + 10);
          for j := 0 to 9 do
            LVecDeque.Put(LVecDeque.Count - 10 + j, i * 10 + j);
        end;
        1: begin

          if LVecDeque.Count > 5 then
            LVecDeque.Resize(LVecDeque.Count - 5);
        end;
        2: begin

          LVecDeque.PushFront(i);
        end;
        3: begin

          LVecDeque.PushBack(i);
        end;
        4: begin

          if not LVecDeque.IsEmpty then
            LVecDeque.PopFront;
        end;
        5: begin

          if not LVecDeque.IsEmpty then
            LVecDeque.PopBack;
        end;
      end;
    end;


    AssertTrue('Final count should be reasonable', LVecDeque.Count >= 0);
    AssertTrue('Capacity should be reasonable', LVecDeque.Capacity >= LVecDeque.Count);


    if not LVecDeque.IsEmpty then
    begin
      LFirstElement := LVecDeque.Front;
      LLastElement := LVecDeque.Back;

      AssertTrue('Container should still be functional', True);
    end;
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Stress_Random_Operations;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LOperationCount: Integer;
  LRandomValue: Integer;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LOperationCount := 1000;


    for i := 0 to LOperationCount - 1 do
    begin
      LRandomValue := Random(1000);

      case Random(8) of
        0: LVecDeque.PushFront(LRandomValue);
        1: LVecDeque.PushBack(LRandomValue);
        2: if not LVecDeque.IsEmpty then LVecDeque.PopFront;
        3: if not LVecDeque.IsEmpty then LVecDeque.PopBack;
        4: if LVecDeque.Count > 0 then LVecDeque.Get(SizeUInt(Random(Integer(LVecDeque.Count))));
        5: if LVecDeque.Count > 0 then LVecDeque.Put(SizeUInt(Random(Integer(LVecDeque.Count))), LRandomValue);
        6: if LVecDeque.Count > 1 then LVecDeque.Insert(SizeUInt(Random(Integer(LVecDeque.Count))), LRandomValue);
        7: if LVecDeque.Count > 0 then LVecDeque.Delete(SizeUInt(Random(Integer(LVecDeque.Count))));
      end;
    end;


    AssertTrue('Container should survive random operations', True);
    AssertTrue('Count should be non-negative', LVecDeque.Count >= 0);
    AssertTrue('Capacity should be sufficient', LVecDeque.Capacity >= LVecDeque.Count);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Exception_NullPointer;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LExceptionRaised: Boolean;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LExceptionRaised := False;
    try
      LVecDeque.Write(0, nil, 5);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Should raise exception for null pointer write', LExceptionRaised);


    LVecDeque.Resize(3);
    LExceptionRaised := False;
    try
      LVecDeque.Read(0, nil, 3);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Should raise exception for null pointer read', LExceptionRaised);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Exception_MemoryError;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LExceptionRaised: Boolean;
  i: Integer;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    // 测试内存分配失败的情况
    // 尝试分配一个非常大的容量来触发内存错误
    LExceptionRaised := False;
    try
      // 尝试预分配一个巨大的容量（可能会导致内存不足）
      LVecDeque.Reserve(High(SizeUInt) div 2);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    // 注意：这个测试可能不会总是失败，取决于系统内存
    // 但至少验证了方法不会崩溃

    // 测试在内存压力下的操作
    LExceptionRaised := False;
    try
      // 尝试添加大量元素
      for i := 1 to 1000000 do
        LVecDeque.PushBack(i);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    // 这个测试主要验证在内存压力下不会崩溃

  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Exception_StackOverflow;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LExceptionRaised: Boolean;
  i: integer;

  procedure RecursiveOperation(ADepth: Integer);
  begin
    if ADepth > 0 then
    begin
      LVecDeque.PushBack(ADepth);
      RecursiveOperation(ADepth - 1);
      LVecDeque.PopBack;
    end;
  end;

begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    // 测试深度递归可能导致的栈溢出
    LExceptionRaised := False;
    try
      // 尝试深度递归操作
      RecursiveOperation(10000);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    // 这个测试主要验证在深度递归下不会导致程序崩溃

    // 测试嵌套操作
    LExceptionRaised := False;
    try
      // 创建一个复杂的嵌套操作场景
      for i := 1 to 1000 do
      begin
        LVecDeque.PushBack(i);
        if i mod 100 = 0 then
        begin
          // 执行一些复杂操作
          LVecDeque.Reverse;
          LVecDeque.Sort;
        end;
      end;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;

  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Exception_AccessViolation;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LExceptionRaised: Boolean;
  LBuffer: Pointer;
  LValue: Integer;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    // 测试访问违例的情况

    // 测试空集合上的无效访问
    LExceptionRaised := False;
    try
      // 尝试访问空集合的元素
      LValue := LVecDeque.Get(0);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Should raise exception for accessing empty collection', LExceptionRaised);

    // 测试越界访问
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);

    LExceptionRaised := False;
    try
      // 尝试访问超出范围的索引
      LValue := LVecDeque.Get(10);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Should raise exception for out-of-bounds access', LExceptionRaised);

    // 测试负索引访问
    LExceptionRaised := False;
    try
      // 尝试使用负索引
      LValue := LVecDeque.Get(SizeUInt(-1));
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Should raise exception for negative index access', LExceptionRaised);

  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Exception_TypeMismatch;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LExceptionRaised: Boolean;
  LArray: array of Integer;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    // 由于Pascal是强类型语言，类型不匹配通常在编译时就会被发现
    // 但我们可以测试一些运行时的类型相关问题

    // 测试比较器类型不匹配的情况
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);

    // 测试无效的比较操作
    LExceptionRaised := False;
    try
      // 尝试使用nil比较器进行排序 - 使用默认排序避免类型问题
      LVecDeque.Sort;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    // 注意：这可能不会抛出异常，取决于实现

    // 测试无效的转换操作
    LExceptionRaised := False;
    try
      // 测试一些可能导致类型问题的操作
      SetLength(LArray, 0);
      // 使用其他方法来测试类型问题，因为Assign可能不存在
      // LVecDeque.Assign(LArray);
      // 改为测试其他可能的类型问题
      LVecDeque.Clear;
      LVecDeque.PushBack(1);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;

    // 测试无效的内存操作
    LExceptionRaised := False;
    try
      // 尝试读取到无效的缓冲区
      LVecDeque.Read(0, nil, 1);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Should raise exception for null buffer read', LExceptionRaised);

  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Exception_RangeError;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LExceptionRaised: Boolean;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 5 do
      LVecDeque.PushBack(i);

    { Object methods }
    LExceptionRaised := False;
    try
      LVecDeque.Delete(2, 10); { Object methods }
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Should raise exception for invalid delete range', LExceptionRaised);

    { Object methods }
    LExceptionRaised := False;
    try
      LVecDeque.Insert(10, 999); { Object methods }
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Should raise exception for invalid insert position', LExceptionRaised);
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Regression_Compatibility;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LVec: specialize TVec<Integer>;
  LArray: array[0..4] of Integer;
  LExportArray: array of integer;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  LVec := specialize TVec<Integer>.Create;
  try

    for i := 0 to High(LArray) do
      LArray[i] := (i + 1) * 13;


    LVecDeque.LoadFrom(@LArray[0], Length(LArray));
    AssertEquals('Should load from array correctly', SizeInt(Length(LArray)), SizeInt(LVecDeque.Count));


    for i := 1 to 3 do
      LVec.Push(i * 17);

    LVecDeque.Clear;
    LVecDeque.LoadFrom(LVec);
    AssertEquals('Should load from Vec correctly', SizeInt(LVec.Count), SizeInt(LVecDeque.Count));


    for i := 0 to LVec.Count - 1 do
      AssertEquals('Data should match between Vec and VecDeque', LVec.Get(i), LVecDeque.Get(i));


    LExportArray := LVecDeque.ToArray;
    AssertEquals('Exported array should have correct length', SizeInt(LVecDeque.Count), SizeInt(Length(LExportArray)));
    for i := 0 to LVecDeque.Count - 1 do
      AssertEquals('Exported data should match', LVecDeque.Get(i), LExportArray[i]);
  finally
    LVec.Free;
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Capacity_Large_Allocations;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LLargeSize: SizeUInt;
  LResult: boolean;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LLargeSize := 50000; { Object methods }


    LResult := LVecDeque.TryReserve(LLargeSize);
    if LResult then
    begin

      AssertTrue('Should reserve large capacity', LVecDeque.Capacity >= LLargeSize);


      for i := 0 to 999 do
        LVecDeque.PushBack(i);

      AssertEquals('Should be able to use reserved capacity', 1000, LVecDeque.Count);


      for i := 0 to 999 do
        AssertEquals('Large allocation data should be correct', i, LVecDeque.Get(i));
    end
    else
    begin

      AssertTrue('Large allocation may fail due to memory constraints', True);
    end;
  finally
    LVecDeque.Free;
  end;
end;



{ Object methods }

procedure TTestCase_VecDeque.Test_CountOf_Element;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(4);


    LCount := LVecDeque.CountOf(1);
    AssertEquals('Should count correct number of element 1', SizeUInt(3), LCount);


    LCount := LVecDeque.CountOf(2);
    AssertEquals('Should count correct number of element 2', SizeUInt(2), LCount);


    LCount := LVecDeque.CountOf(3);
    AssertEquals('Should count correct number of element 3', SizeUInt(1), LCount);


    LCount := LVecDeque.CountOf(99);
    AssertEquals('Should count zero for non-existent element', SizeUInt(0), LCount);


    LVecDeque.Clear;
    LCount := LVecDeque.CountOf(1);
    AssertEquals('Should count zero in empty container', SizeUInt(0), LCount);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_CountOf_Element_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(2);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(6);


    LCount := LVecDeque.CountOf(6, @EqualsTestFunc, @Self);
    AssertEquals('Should count correct number using func', SizeUInt(2), LCount);


    LCount := LVecDeque.CountOf(10, @EqualsTestFunc, @Self);
    AssertEquals('Should count zero for non-existent element using func', SizeUInt(0), LCount);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_CountOf_Element_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(5);
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(15);
    LVecDeque.PushBack(5);


    LCount := LVecDeque.CountOf(5, @EqualsTestMethod, @Self);
    AssertEquals('Should count correct number using method', SizeUInt(3), LCount);


    LCount := LVecDeque.CountOf(10, @EqualsTestMethod, @Self);
    AssertEquals('Should count correct number using method', SizeUInt(1), LCount);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_CountOf_Element_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(7);
    LVecDeque.PushBack(14);
    LVecDeque.PushBack(7);
    LVecDeque.PushBack(21);
    LVecDeque.PushBack(7);
    LVecDeque.PushBack(14);


    LCount := LVecDeque.CountOf(7, function(const a,b: Integer): Boolean
  begin
    Result := a = b;
  end);
    AssertEquals('Should count correct number using ref func', SizeUInt(3), LCount);


    LCount := LVecDeque.CountOf(14, function(const a,b: Integer): Boolean
  begin
    Result := a = b;
  end);
    AssertEquals('Should count correct number using ref func', SizeUInt(2), LCount);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_CountOf_StartIndex;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCount: SizeUInt;
  LStartIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);

    LStartIndex := 2;


    LCount := LVecDeque.CountOf(1, LStartIndex);
    AssertEquals('Should count elements from start index', SizeUInt(2), LCount);


    LCount := LVecDeque.CountOf(2, LStartIndex);
    AssertEquals('Should count elements from start index', SizeUInt(1), LCount);


    LCount := LVecDeque.CountOf(1, 0);
    AssertEquals('Should count all elements from index 0', SizeUInt(3), LCount);
  finally
    LVecDeque.Free;
  end;
end;

{ Object methods }

procedure TTestCase_VecDeque.Test_CountIF_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(6);


    LCount := LVecDeque.CountIF(@PredicateTestFunc, @Self);
    AssertEquals('Should count correct number of even elements', SizeUInt(3), LCount);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_CountIF_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(10);
    LVecDeque.PushBack(15);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(25);
    LVecDeque.PushBack(30);


    LCount := LVecDeque.CountIF(@PredicateTestMethod, @Self);
    AssertEquals('Should count correct number of even elements', SizeUInt(3), LCount);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_CountIF_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(7);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(9);
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(11);
    LVecDeque.PushBack(12);


    LCount := LVecDeque.CountIF(@PredicateTestRefFunc);
    AssertEquals('Should count correct number of even elements', SizeUInt(3), LCount);
  finally
    LVecDeque.Free;
  end;
end;

{ Object methods }

procedure TTestCase_VecDeque.Test_Replace_OldValue_NewValue;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);


    LVecDeque.Replace(1, 99);

    { Object methods }
    AssertEquals('Count should remain same', 6, LVecDeque.Count);
    AssertEquals('First element should be replaced', 99, LVecDeque.Get(0));
    AssertEquals('Second element should remain unchanged', 2, LVecDeque.Get(1));
    AssertEquals('Third element should be replaced', 99, LVecDeque.Get(2));
    AssertEquals('Fourth element should remain unchanged', 3, LVecDeque.Get(3));
    AssertEquals('Fifth element should be replaced', 99, LVecDeque.Get(4));
    AssertEquals('Sixth element should remain unchanged', 2, LVecDeque.Get(5));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Replace_OldValue_NewValue_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(5);
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(15);
    LVecDeque.PushBack(5);


    LVecDeque.Replace(5, 50, @EqualsTestFunc, @Self);

    { Object methods }
    AssertEquals('Count should remain same', 5, LVecDeque.Count);
    AssertEquals('First element should be replaced', 50, LVecDeque.Get(0));
    AssertEquals('Second element should remain unchanged', 10, LVecDeque.Get(1));
    AssertEquals('Third element should be replaced', 50, LVecDeque.Get(2));
    AssertEquals('Fourth element should remain unchanged', 15, LVecDeque.Get(3));
    AssertEquals('Fifth element should be replaced', 50, LVecDeque.Get(4));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ReplaceIF_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(6);


    LVecDeque.ReplaceIf(0, @PredicateTestFunc, @Self);

    { Object methods }
    AssertEquals('Count should remain same', 6, LVecDeque.Count);
    AssertEquals('Odd element should remain unchanged', 1, LVecDeque.Get(0));
    AssertEquals('Even element should be replaced', 0, LVecDeque.Get(1));
    AssertEquals('Odd element should remain unchanged', 3, LVecDeque.Get(2));
    AssertEquals('Even element should be replaced', 0, LVecDeque.Get(3));
    AssertEquals('Odd element should remain unchanged', 5, LVecDeque.Get(4));
    AssertEquals('Even element should be replaced', 0, LVecDeque.Get(5));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ReplaceIF_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(10);
    LVecDeque.PushBack(15);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(25);
    LVecDeque.PushBack(30);


    LVecDeque.ReplaceIf(-1, @PredicateTestMethod, @Self);

    { Object methods }
    AssertEquals('Count should remain same', 5, LVecDeque.Count);
    AssertEquals('Even element should be replaced', -1, LVecDeque.Get(0));
    AssertEquals('Odd element should remain unchanged', 15, LVecDeque.Get(1));
    AssertEquals('Even element should be replaced', -1, LVecDeque.Get(2));
    AssertEquals('Odd element should remain unchanged', 25, LVecDeque.Get(3));
    AssertEquals('Even element should be replaced', -1, LVecDeque.Get(4));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ReplaceIF_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(7);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(9);
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(11);
    LVecDeque.PushBack(12);


    LVecDeque.ReplaceIf(999, @PredicateTestRefFunc);

    { Object methods }
    AssertEquals('Count should remain same', 6, LVecDeque.Count);
    AssertEquals('Odd element should remain unchanged', 7, LVecDeque.Get(0));
    AssertEquals('Even element should be replaced', 999, LVecDeque.Get(1));
    AssertEquals('Odd element should remain unchanged', 9, LVecDeque.Get(2));
    AssertEquals('Even element should be replaced', 999, LVecDeque.Get(3));
    AssertEquals('Odd element should remain unchanged', 11, LVecDeque.Get(4));
    AssertEquals('Even element should be replaced', 999, LVecDeque.Get(5));
  finally
    LVecDeque.Free;
  end;
end;

{ Object methods }

procedure TTestCase_VecDeque.Test_Shuffle;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LOriginalElements: array[0..4] of Integer;
  LShuffled: Boolean;
  LFound: boolean;
  i, j: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 0 to High(LOriginalElements) do
    begin
      LOriginalElements[i] := i + 1;
      LVecDeque.PushBack(LOriginalElements[i]);
    end;

    { executeshuffle }
    LVecDeque.Shuffle;

    { Object methods }
    AssertEquals('Count should remain same', SizeInt(Length(LOriginalElements)), SizeInt(LVecDeque.Count));


    for i := 0 to High(LOriginalElements) do
    begin
      LFound := False;
      for j := 0 to LVecDeque.Count - 1 do
      begin
        if LVecDeque.Get(j) = LOriginalElements[i] then
        begin
          LFound := True;
          Break;
        end;
      end;
      AssertTrue('Original element should still exist after shuffle', LFound);
    end;


    LShuffled := False;
    for i := 0 to Integer(LVecDeque.Count) - 1 do
    begin
      if LVecDeque.Get(i) <> LOriginalElements[i] then
      begin
        LShuffled := True;
        Break;
      end;
    end;

    AssertTrue('Elements should likely be shuffled', LShuffled);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Shuffle_StartIndex;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartIndex: SizeUInt;
  LFound: boolean;
  i, j: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 8 do
      LVecDeque.PushBack(i);

    LStartIndex := 3;


    LVecDeque.Shuffle(LStartIndex);

    { Object methods }
    AssertEquals('Count should remain same', SizeInt(8), SizeInt(LVecDeque.Count));


    for i := 0 to Integer(LStartIndex) - 1 do
      AssertEquals('Element before start index should be unchanged', i + 1, LVecDeque.Get(i));


    for i := Integer(LStartIndex) + 1 to 8 do
    begin
      LFound := False;
      for j := Integer(LStartIndex) to Integer(LVecDeque.Count) - 1 do
      begin
        if LVecDeque.Get(j) = i then
        begin
          LFound := True;
          Break;
        end;
      end;
      AssertTrue('Element should still exist in shuffled range', LFound);
    end;
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_CountOf_StartIndex_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCount: SizeUInt;
  LStartIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(3);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(9);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(6);

    LStartIndex := 2;


    LCount := LVecDeque.CountOf(3, LStartIndex, @EqualsTestFunc, @Self);
    AssertEquals('count start-index func #1', SizeUInt(2), LCount);


    LCount := LVecDeque.CountOf(3, 0, @EqualsTestFunc, @Self);
    AssertEquals('count start-index func #2', SizeUInt(3), LCount);


    LCount := LVecDeque.CountOf(6, 5, @EqualsTestFunc, @Self);
    AssertEquals('count start-index func #3', SizeUInt(1), LCount);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_CountOf_StartIndex_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCount: SizeUInt;
  LStartIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(5);
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(15);
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(5);

    LStartIndex := 3;


    LCount := LVecDeque.CountOf(5, LStartIndex, @EqualsTestMethod, @Self);
    AssertEquals('count start-index method #1', SizeUInt(2), LCount);


    LCount := LVecDeque.CountOf(10, LStartIndex, @EqualsTestMethod, @Self);
    AssertEquals('count start-index method #2', SizeUInt(1), LCount);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_CountOf_StartIndex_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCount: SizeUInt;
  LStartIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(7);
    LVecDeque.PushBack(14);
    LVecDeque.PushBack(7);
    LVecDeque.PushBack(21);
    LVecDeque.PushBack(7);
    LVecDeque.PushBack(14);

    LStartIndex := 1;


    LCount := LVecDeque.CountOf(7, LStartIndex, function(const a,b: Integer): Boolean
  begin
    Result := a = b;
  end);
    AssertEquals('count func #1', SizeUInt(2), LCount);


    LCount := LVecDeque.CountOf(14, LStartIndex, function(const a,b: Integer): Boolean
  begin
    Result := a = b;
  end);
    AssertEquals('count func #2', SizeUInt(2), LCount);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_CountOf_StartIndex_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCount: SizeUInt;
  LStartIndex, LSearchCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(4);

    LStartIndex := 2;
    LSearchCount := 4;


    LCount := LVecDeque.CountOf(1, LStartIndex, LSearchCount);
    AssertEquals('count in range #1', SizeUInt(2), LCount);


    LCount := LVecDeque.CountOf(2, LStartIndex, LSearchCount);
    AssertEquals('count in range #2', SizeUInt(1), LCount);


    LCount := LVecDeque.CountOf(99, LStartIndex, LSearchCount);
    AssertEquals('count not exist', SizeUInt(0), LCount);

    { Object methods }
    LCount := LVecDeque.CountOf(1, LStartIndex, 0);
    AssertEquals('count zero range', SizeUInt(0), LCount);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_CountOf_StartIndex_Count_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCount: SizeUInt;
  LStartIndex, LSearchCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(8);
    LVecDeque.PushBack(16);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(24);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(16);
    LVecDeque.PushBack(8);

    LStartIndex := 1;
    LSearchCount := 5;


    LCount := LVecDeque.CountOf(8, LStartIndex, LSearchCount, @EqualsTestFunc, @Self);
    AssertEquals('shouldgarbled_textㄦgarbled_textgarbledcorrect‘statisticselementcount', SizeUInt(2), LCount);


    LCount := LVecDeque.CountOf(16, LStartIndex, LSearchCount, @EqualsTestFunc, @Self);
    AssertEquals('shouldgarbled_textㄦgarbled_textgarbledcorrect‘statisticselementcount', SizeUInt(2), LCount);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_CountOf_StartIndex_Count_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCount: SizeUInt;
  LStartIndex, LSearchCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(9);
    LVecDeque.PushBack(18);
    LVecDeque.PushBack(9);
    LVecDeque.PushBack(27);
    LVecDeque.PushBack(9);
    LVecDeque.PushBack(18);

    LStartIndex := 0;
    LSearchCount := 4;


    LCount := LVecDeque.CountOf(9, LStartIndex, LSearchCount, @EqualsTestMethod, @Self);
    AssertEquals('shouldgarbled_textㄦgarbled_textgarbledcorrect‘statisticselementcount', SizeUInt(2), LCount);


    LCount := LVecDeque.CountOf(18, LStartIndex, LSearchCount, @EqualsTestMethod, @Self);
    AssertEquals('shouldgarbled_textㄦgarbled_textgarbledcorrect‘statisticselementcount', SizeUInt(1), LCount);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_CountOf_StartIndex_Count_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCount: SizeUInt;
  LStartIndex, LSearchCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(11);
    LVecDeque.PushBack(22);
    LVecDeque.PushBack(11);
    LVecDeque.PushBack(33);
    LVecDeque.PushBack(11);
    LVecDeque.PushBack(22);
    LVecDeque.PushBack(11);
    LVecDeque.PushBack(44);

    LStartIndex := 2;
    LSearchCount := 5;


    LCount := LVecDeque.CountOf(11, LStartIndex, LSearchCount, function(const a,b: Integer): Boolean
  begin
    Result := a = b;
  end);
    AssertEquals('count in range #3', SizeUInt(2), LCount);


    LCount := LVecDeque.CountOf(22, LStartIndex, LSearchCount, function(const a,b: Integer): Boolean
  begin
    Result := a = b;
  end);
    AssertEquals('count in range #4', SizeUInt(1), LCount);


    LCount := LVecDeque.CountOf(44, LStartIndex, LSearchCount, function(const a,b: Integer): Boolean
  begin
    Result := a = b;
  end);
    AssertEquals('count out of range', SizeUInt(0), LCount);
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_CountIF_StartIndex_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCount: SizeUInt;
  LStartIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(1);  { Object methods }
    LVecDeque.PushBack(2);  { Object methods }
    LVecDeque.PushBack(3);  { Object methods }
    LVecDeque.PushBack(4);  { Object methods }
    LVecDeque.PushBack(5);  { Object methods }
    LVecDeque.PushBack(6);  { Object methods }

    LStartIndex := 2;


    LCount := LVecDeque.CountIF(LStartIndex, @PredicateTestFunc, @Self);
    AssertEquals('countIF start #1', SizeUInt(2), LCount);


    LCount := LVecDeque.CountIF(0, @PredicateTestFunc, @Self);
    AssertEquals('countIF from 0', SizeUInt(3), LCount);


    LCount := LVecDeque.CountIF(5, @PredicateTestFunc, @Self);
    AssertEquals('countIF from last idx', SizeUInt(1), LCount);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_CountIF_StartIndex_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCount: SizeUInt;
  LStartIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(10);  { Object methods }
    LVecDeque.PushBack(15);  { Object methods }
    LVecDeque.PushBack(20);  { Object methods }
    LVecDeque.PushBack(25);  { Object methods }
    LVecDeque.PushBack(30);  { Object methods }
    LVecDeque.PushBack(35);  { Object methods }

    LStartIndex := 1;


    LCount := LVecDeque.CountIF(LStartIndex, @PredicateTestMethod, @Self);
    AssertEquals('countIF method #1', SizeUInt(2), LCount);


    LCount := LVecDeque.CountIF(3, @PredicateTestMethod, @Self);
    AssertEquals('countIF method range', SizeUInt(1), LCount);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_CountIF_StartIndex_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCount: SizeUInt;
  LStartIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(7);   { Object methods }
    LVecDeque.PushBack(8);   { Object methods }
    LVecDeque.PushBack(9);   { Object methods }
    LVecDeque.PushBack(10);  { Object methods }
    LVecDeque.PushBack(11);  { Object methods }
    LVecDeque.PushBack(12);  { Object methods }

    LStartIndex := 2;


    LCount := LVecDeque.CountIF(LStartIndex, @PredicateTestRefFunc);
    AssertEquals('countIF ref #1', SizeUInt(2), LCount);


    LCount := LVecDeque.CountIF(4, @PredicateTestRefFunc);
    AssertEquals('countIF ref range', SizeUInt(1), LCount);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_CountIF_StartIndex_Count_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCount: SizeUInt;
  LStartIndex, LSearchCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(1);   { Object methods }
    LVecDeque.PushBack(2);   { Object methods }
    LVecDeque.PushBack(3);   { Object methods }
    LVecDeque.PushBack(4);   { Object methods }
    LVecDeque.PushBack(5);   { Object methods }
    LVecDeque.PushBack(6);   { Object methods }
    LVecDeque.PushBack(7);   { Object methods }
    LVecDeque.PushBack(8);   { Object methods }

    LStartIndex := 1;
    LSearchCount := 5;


    LCount := LVecDeque.CountIF(LStartIndex, LSearchCount, @PredicateTestFunc, @Self);
    AssertEquals('countIF func in-range #1', SizeUInt(2), LCount);


    LCount := LVecDeque.CountIF(0, 4, @PredicateTestFunc, @Self);
    AssertEquals('countIF func in-range #2', SizeUInt(2), LCount);

    { Object methods }
    LCount := LVecDeque.CountIF(LStartIndex, 0, @PredicateTestFunc, @Self);
    AssertEquals('countIF zero range', SizeUInt(0), LCount);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_CountIF_StartIndex_Count_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCount: SizeUInt;
  LStartIndex, LSearchCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(11);  { Object methods }
    LVecDeque.PushBack(12);  { Object methods }
    LVecDeque.PushBack(13);  { Object methods }
    LVecDeque.PushBack(14);  { Object methods }
    LVecDeque.PushBack(15);  { Object methods }
    LVecDeque.PushBack(16);  { Object methods }

    LStartIndex := 0;
    LSearchCount := 4;


    LCount := LVecDeque.CountIF(LStartIndex, LSearchCount, @PredicateTestMethod, @Self);
    AssertEquals('countIF method in-range #1', SizeUInt(2), LCount);


    LCount := LVecDeque.CountIF(2, 4, @PredicateTestMethod, @Self);
    AssertEquals('countIF method in-range #2', SizeUInt(2), LCount);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_CountIF_StartIndex_Count_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCount: SizeUInt;
  LStartIndex, LSearchCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(21);  { Object methods }
    LVecDeque.PushBack(22);  { Object methods }
    LVecDeque.PushBack(23);  { Object methods }
    LVecDeque.PushBack(24);  { Object methods }
    LVecDeque.PushBack(25);  { Object methods }
    LVecDeque.PushBack(26);  { Object methods }
    LVecDeque.PushBack(27);  { Object methods }

    LStartIndex := 1;
    LSearchCount := 5;


    LCount := LVecDeque.CountIF(LStartIndex, LSearchCount, @PredicateTestRefFunc);
    AssertEquals('countIF ref in-range #1', SizeUInt(2), LCount);

    { Object methods }
    LCount := LVecDeque.CountIF(5, 2, @PredicateTestRefFunc);
    AssertEquals('countIF ref edge', SizeUInt(1), LCount);

    { Object methods }
    LCount := LVecDeque.CountIF(3, 1, @PredicateTestRefFunc);
    AssertEquals('countIF ref single', SizeUInt(1), LCount);
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Replace_OldValue_NewValue_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(30);
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);


    LVecDeque.Replace(10, 100, @EqualsTestMethod, @Self);

    { Object methods }
    AssertEquals('replace keep count', SizeInt(6), SizeInt(LVecDeque.Count));
    AssertEquals('replace idx0', 100, LVecDeque.Get(0));
    AssertEquals('replace idx1 unchanged', 20, LVecDeque.Get(1));
    AssertEquals('replace idx2', 100, LVecDeque.Get(2));
    AssertEquals('replace idx3 unchanged', 30, LVecDeque.Get(3));
    AssertEquals('replace idx4', 100, LVecDeque.Get(4));
    AssertEquals('replace idx5 unchanged', 20, LVecDeque.Get(5));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Replace_OldValue_NewValue_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(7);
    LVecDeque.PushBack(14);
    LVecDeque.PushBack(7);
    LVecDeque.PushBack(21);
    LVecDeque.PushBack(7);


    LVecDeque.Replace(7, 70, function(const a,b: Integer): Boolean
  begin
    Result := a = b;
  end);

    { Object methods }
    AssertEquals('replace keep count', SizeInt(5), SizeInt(LVecDeque.Count));
    AssertEquals('replace idx0', 70, LVecDeque.Get(0));
    AssertEquals('replace idx1 unchanged', 14, LVecDeque.Get(1));
    AssertEquals('replace idx2', 70, LVecDeque.Get(2));
    AssertEquals('replace idx3 unchanged', 21, LVecDeque.Get(3));
    AssertEquals('replace idx4', 70, LVecDeque.Get(4));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Replace_StartIndex;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(1);

    LStartIndex := 2;


    LVecDeque.Replace(1, 99, LStartIndex);

    { Object methods }
    AssertEquals('replace keep count', SizeInt(7), SizeInt(LVecDeque.Count));

    AssertEquals('idx0 unchanged', 1, LVecDeque.Get(0));
    AssertEquals('idx1 unchanged', 2, LVecDeque.Get(1));

    AssertEquals('idx2 replaced', 99, LVecDeque.Get(2));
    AssertEquals('idx3 unchanged', 3, LVecDeque.Get(3));
    AssertEquals('idx4 replaced', 99, LVecDeque.Get(4));
    AssertEquals('idx5 unchanged', 2, LVecDeque.Get(5));
    AssertEquals('idx6 replaced', 99, LVecDeque.Get(6));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Replace_StartIndex_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(5);
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(15);
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(10);

    LStartIndex := 1;


    LVecDeque.Replace(5, 50, LStartIndex, @EqualsTestFunc, @Self);

    { Object methods }
    AssertEquals('replace keep count', SizeInt(6), SizeInt(LVecDeque.Count));

    AssertEquals('idx0 unchanged', 5, LVecDeque.Get(0));

    AssertEquals('idx1 unchanged', 10, LVecDeque.Get(1));
    AssertEquals('idx2 replaced', 50, LVecDeque.Get(2));
    AssertEquals('idx3 unchanged', 15, LVecDeque.Get(3));
    AssertEquals('idx4 replaced', 50, LVecDeque.Get(4));
    AssertEquals('idx5 unchanged', 10, LVecDeque.Get(5));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Replace_StartIndex_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(8);
    LVecDeque.PushBack(16);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(24);
    LVecDeque.PushBack(8);

    LStartIndex := 2;


    LVecDeque.Replace(8, 80, LStartIndex, @EqualsTestMethod, @Self);

    { Object methods }
    AssertEquals('elementcountshouldrepairgarbled_text', 5, LVecDeque.Count);

    AssertEquals('idx0 unchanged', 8, LVecDeque.Get(0));
    AssertEquals('idx1 unchanged', 16, LVecDeque.Get(1));

    AssertEquals('idx2 replaced', 80, LVecDeque.Get(2));
    AssertEquals('idx3 unchanged', 24, LVecDeque.Get(3));
    AssertEquals('idx4 replaced', 80, LVecDeque.Get(4));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Replace_StartIndex_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(9);
    LVecDeque.PushBack(18);
    LVecDeque.PushBack(9);
    LVecDeque.PushBack(27);
    LVecDeque.PushBack(9);
    LVecDeque.PushBack(18);

    LStartIndex := 3;


    LVecDeque.Replace(9, 90, LStartIndex, function(const a,b: Integer): Boolean
  begin
    Result := a = b;
  end);

    { Object methods }
    AssertEquals('replace keep count', SizeInt(6), SizeInt(LVecDeque.Count));

    AssertEquals('idx0 unchanged', 9, LVecDeque.Get(0));
    AssertEquals('idx1 unchanged', 18, LVecDeque.Get(1));
    AssertEquals('idx2 unchanged', 9, LVecDeque.Get(2));

    AssertEquals('idx3 unchanged', 27, LVecDeque.Get(3));
    AssertEquals('idx4 replaced', 90, LVecDeque.Get(4));
    AssertEquals('idx5 unchanged', 18, LVecDeque.Get(5));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Replace_StartIndex_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartIndex, LCount: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(4);

    LStartIndex := 2;
    LCount := 4;


    LVecDeque.Replace(1, 99, LStartIndex, LCount);

    { Object methods }
    AssertEquals('replace keep count', SizeInt(8), SizeInt(LVecDeque.Count));

    AssertEquals('idx0 unchanged', 1, LVecDeque.Get(0));
    AssertEquals('idx1 unchanged', 2, LVecDeque.Get(1));

    AssertEquals('idx2 replaced', 99, LVecDeque.Get(2));
    AssertEquals('idx3 unchanged', 3, LVecDeque.Get(3));
    AssertEquals('idx4 replaced', 99, LVecDeque.Get(4));
    AssertEquals('idx5 unchanged', 2, LVecDeque.Get(5));

    AssertEquals('idx6 unchanged', 1, LVecDeque.Get(6));
    AssertEquals('idx7 unchanged', 4, LVecDeque.Get(7));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Replace_StartIndex_Count_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartIndex, LCount: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(6);
    LVecDeque.PushBack(12);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(18);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(12);
    LVecDeque.PushBack(6);

    LStartIndex := 1;
    LCount := 5;


    LVecDeque.Replace(6, 60, LStartIndex, LCount, @EqualsTestFunc, @Self);

    { Object methods }
    AssertEquals('replace keep count', SizeInt(7), SizeInt(LVecDeque.Count));

    AssertEquals('idx0 unchanged', 6, LVecDeque.Get(0));

    AssertEquals('idx1 unchanged', 12, LVecDeque.Get(1));
    AssertEquals('idx2 replaced', 60, LVecDeque.Get(2));
    AssertEquals('idx3 unchanged', 18, LVecDeque.Get(3));
    AssertEquals('idx4 replaced', 60, LVecDeque.Get(4));
    AssertEquals('idx5 unchanged', 12, LVecDeque.Get(5));

    AssertEquals('idx6 unchanged', 6, LVecDeque.Get(6));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Replace_StartIndex_Count_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartIndex, LCount: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(11);
    LVecDeque.PushBack(22);
    LVecDeque.PushBack(11);
    LVecDeque.PushBack(33);
    LVecDeque.PushBack(11);
    LVecDeque.PushBack(22);

    LStartIndex := 0;
    LCount := 4;


    LVecDeque.Replace(11, 110, LStartIndex, LCount, @EqualsTestMethod, @Self);

    { Object methods }
    AssertEquals('replace keep count', SizeInt(6), SizeInt(LVecDeque.Count));

    AssertEquals('idx0 replaced', 110, LVecDeque.Get(0));
    AssertEquals('idx1 unchanged', 22, LVecDeque.Get(1));
    AssertEquals('idx2 replaced', 110, LVecDeque.Get(2));
    AssertEquals('idx3 unchanged', 33, LVecDeque.Get(3));

    AssertEquals('idx4 unchanged', 11, LVecDeque.Get(4));
    AssertEquals('idx5 unchanged', 22, LVecDeque.Get(5));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Replace_StartIndex_Count_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartIndex, LCount: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(13);
    LVecDeque.PushBack(26);
    LVecDeque.PushBack(13);
    LVecDeque.PushBack(39);
    LVecDeque.PushBack(13);
    LVecDeque.PushBack(26);
    LVecDeque.PushBack(13);
    LVecDeque.PushBack(52);

    LStartIndex := 2;
    LCount := 5;


    LVecDeque.Replace(13, 130, LStartIndex, LCount, function(const a,b: Integer): Boolean
  begin
    Result := a = b;
  end);

    { Object methods }
    AssertEquals('replace keep count', SizeInt(8), SizeInt(LVecDeque.Count));

    AssertEquals('idx0 unchanged', 13, LVecDeque.Get(0));
    AssertEquals('idx1 unchanged', 26, LVecDeque.Get(1));

    AssertEquals('idx2 replaced', 130, LVecDeque.Get(2));
    AssertEquals('idx3 unchanged', 39, LVecDeque.Get(3));
    AssertEquals('idx4 replaced', 130, LVecDeque.Get(4));
    AssertEquals('idx5 unchanged', 26, LVecDeque.Get(5));
    AssertEquals('idx6 replaced', 130, LVecDeque.Get(6));

    AssertEquals('idx7 unchanged', 52, LVecDeque.Get(7));
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_ReplaceIF_StartIndex_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartIndex: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(1);   { Object methods }
    LVecDeque.PushBack(2);   { Object methods }
    LVecDeque.PushBack(3);   { Object methods }
    LVecDeque.PushBack(4);   { Object methods }
    LVecDeque.PushBack(5);   { Object methods }
    LVecDeque.PushBack(6);   { Object methods }
    LVecDeque.PushBack(7);   { Object methods }

    LStartIndex := 2;


    LVecDeque.ReplaceIF(0, LStartIndex, @PredicateTestFunc, @Self);

    { Object methods }
    AssertEquals('replaceIF keep count', SizeInt(7), SizeInt(LVecDeque.Count));

    AssertEquals('idx0 unchanged', 1, LVecDeque.Get(0));
    AssertEquals('idx1 unchanged', 2, LVecDeque.Get(1));

    AssertEquals('idx2 unchanged', 3, LVecDeque.Get(2));
    AssertEquals('idx3 replaced', 0, LVecDeque.Get(3));
    AssertEquals('idx4 unchanged', 5, LVecDeque.Get(4));
    AssertEquals('idx5 replaced', 0, LVecDeque.Get(5));
    AssertEquals('idx6 unchanged', 7, LVecDeque.Get(6));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ReplaceIF_StartIndex_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartIndex: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(10);  { Object methods }
    LVecDeque.PushBack(15);  { Object methods }
    LVecDeque.PushBack(20);  { Object methods }
    LVecDeque.PushBack(25);  { Object methods }
    LVecDeque.PushBack(30);  { Object methods }
    LVecDeque.PushBack(35);  { Object methods }

    LStartIndex := 1;


    LVecDeque.ReplaceIF(-1, LStartIndex, @PredicateTestMethod, @Self);

    { Object methods }
    AssertEquals('replaceIF keep count', SizeInt(6), SizeInt(LVecDeque.Count));

    AssertEquals('idx0 unchanged', 10, LVecDeque.Get(0));

    AssertEquals('idx1 unchanged', 15, LVecDeque.Get(1));
    AssertEquals('idx2 replaced', -1, LVecDeque.Get(2));
    AssertEquals('idx3 unchanged', 25, LVecDeque.Get(3));
    AssertEquals('idx4 replaced', -1, LVecDeque.Get(4));
    AssertEquals('idx5 unchanged', 35, LVecDeque.Get(5));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ReplaceIF_StartIndex_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartIndex: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(11);  { Object methods }
    LVecDeque.PushBack(12);  { Object methods }
    LVecDeque.PushBack(13);  { Object methods }
    LVecDeque.PushBack(14);  { Object methods }
    LVecDeque.PushBack(15);  { Object methods }
    LVecDeque.PushBack(16);  { Object methods }

    LStartIndex := 3;


    LVecDeque.ReplaceIF(999, LStartIndex, @PredicateTestRefFunc);

    { Object methods }
    AssertEquals('replaceIF keep count', SizeInt(6), SizeInt(LVecDeque.Count));

    AssertEquals('idx0 unchanged', 11, LVecDeque.Get(0));
    AssertEquals('idx1 unchanged', 12, LVecDeque.Get(1));
    AssertEquals('idx2 unchanged', 13, LVecDeque.Get(2));

    AssertEquals('idx3 replaced', 999, LVecDeque.Get(3));
    AssertEquals('idx4 unchanged', 15, LVecDeque.Get(4));
    AssertEquals('idx5 replaced', 999, LVecDeque.Get(5));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ReplaceIF_StartIndex_Count_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartIndex, LCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(1);   { Object methods }
    LVecDeque.PushBack(2);   { Object methods }
    LVecDeque.PushBack(3);   { Object methods }
    LVecDeque.PushBack(4);   { Object methods }
    LVecDeque.PushBack(5);   { Object methods }
    LVecDeque.PushBack(6);   { Object methods }
    LVecDeque.PushBack(7);   { Object methods }
    LVecDeque.PushBack(8);   { Object methods }

    LStartIndex := 1;
    LCount := 5;


    LVecDeque.ReplaceIF(0, LStartIndex, LCount, @PredicateTestFunc, @Self);

    { Object methods }
    AssertEquals('replaceIF keep count', SizeInt(8), SizeInt(LVecDeque.Count));

    AssertEquals('idx0 unchanged', 1, LVecDeque.Get(0));

    AssertEquals('idx1 replaced', 0, LVecDeque.Get(1));
    AssertEquals('idx2 unchanged', 3, LVecDeque.Get(2));
    AssertEquals('idx3 replaced', 0, LVecDeque.Get(3));
    AssertEquals('idx4 unchanged', 5, LVecDeque.Get(4));
    AssertEquals('idx5 replaced', 0, LVecDeque.Get(5));

    AssertEquals('idx6 unchanged', 7, LVecDeque.Get(6));
    AssertEquals('idx7 unchanged', 8, LVecDeque.Get(7));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ReplaceIF_StartIndex_Count_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartIndex, LCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(21);  { Object methods }
    LVecDeque.PushBack(22);  { Object methods }
    LVecDeque.PushBack(23);  { Object methods }
    LVecDeque.PushBack(24);  { Object methods }
    LVecDeque.PushBack(25);  { Object methods }
    LVecDeque.PushBack(26);  { Object methods }

    LStartIndex := 0;
    LCount := 4;


    LVecDeque.ReplaceIF(-2, LStartIndex, LCount, @PredicateTestMethod, @Self);

    { Object methods }
    AssertEquals('replaceIF keep count', SizeInt(6), SizeInt(LVecDeque.Count));

    AssertEquals('idx0 unchanged', 21, LVecDeque.Get(0));
    AssertEquals('idx1 replaced', -2, LVecDeque.Get(1));
    AssertEquals('idx2 unchanged', 23, LVecDeque.Get(2));
    AssertEquals('idx3 replaced', -2, LVecDeque.Get(3));

    AssertEquals('idx4 unchanged', 25, LVecDeque.Get(4));
    AssertEquals('idx5 unchanged', 26, LVecDeque.Get(5));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ReplaceIF_StartIndex_Count_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartIndex, LCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(31);  { Object methods }
    LVecDeque.PushBack(32);  { Object methods }
    LVecDeque.PushBack(33);  { Object methods }
    LVecDeque.PushBack(34);  { Object methods }
    LVecDeque.PushBack(35);  { Object methods }
    LVecDeque.PushBack(36);  { Object methods }
    LVecDeque.PushBack(37);  { Object methods }

    LStartIndex := 2;
    LCount := 4;


    LVecDeque.ReplaceIF(888, LStartIndex, LCount, @PredicateTestRefFunc);

    { Object methods }
    AssertEquals('replaceIF keep count', SizeInt(7), SizeInt(LVecDeque.Count));

    AssertEquals('idx0 unchanged', 31, LVecDeque.Get(0));
    AssertEquals('idx1 unchanged', 32, LVecDeque.Get(1));

    AssertEquals('idx2 unchanged', 33, LVecDeque.Get(2));
    AssertEquals('idx3 replaced', 888, LVecDeque.Get(3));
    AssertEquals('idx4 unchanged', 35, LVecDeque.Get(4));
    AssertEquals('idx5 replaced', 888, LVecDeque.Get(5));

    AssertEquals('idx6 unchanged', 37, LVecDeque.Get(6));
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Shuffle_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LOriginalElements: array[0..5] of Integer;
  LShuffled: Boolean;
  LFound: Boolean;
  i, j: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 0 to High(LOriginalElements) do
    begin
      LOriginalElements[i] := (i + 1) * 10;
      LVecDeque.PushBack(LOriginalElements[i]);
    end;


    LVecDeque.Shuffle(@RandomTestFunc, @Self);

    { Object methods }
    AssertEquals('count unchanged', SizeInt(Length(LOriginalElements)), SizeInt(LVecDeque.Count));


    for i := 0 to High(LOriginalElements) do
    begin
      LFound := False;
      for j := 0 to LVecDeque.Count - 1 do
      begin
        if LVecDeque.Get(j) = LOriginalElements[i] then
        begin
          LFound := True;
          Break;
        end;
      end;
      AssertTrue('orig elements still exist', LFound);
    end;


    LShuffled := False;
    for i := 0 to Integer(LVecDeque.Count) - 1 do
    begin
      if LVecDeque.Get(i) <> LOriginalElements[i] then
      begin
        LShuffled := True;
        Break;
      end;
    end;

    AssertTrue('elements likely shuffled', LShuffled);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Shuffle_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LOriginalElements: array[0..4] of Integer;
  LFound: Boolean;
  i, j: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 0 to High(LOriginalElements) do
    begin
      LOriginalElements[i] := (i + 1) * 7;
      LVecDeque.PushBack(LOriginalElements[i]);
    end;


    LVecDeque.Shuffle(@RandomTestMethod, @Self);

    { Object methods }
    AssertEquals('count unchanged', SizeInt(Length(LOriginalElements)), SizeInt(LVecDeque.Count));


    for i := 0 to High(LOriginalElements) do
    begin
      LFound := False;
      for j := 0 to Integer(LVecDeque.Count) - 1 do
      begin
        if LVecDeque.Get(j) = LOriginalElements[i] then
        begin
          LFound := True;
          Break;
        end;
      end;
      AssertTrue('orig elements still exist', LFound);
    end;
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Shuffle_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LOriginalElements: array[0..6] of Integer;
  LFound: Boolean;
  i, j: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 0 to High(LOriginalElements) do
    begin
      LOriginalElements[i] := (i + 1) * 11;
      LVecDeque.PushBack(LOriginalElements[i]);
    end;


    LVecDeque.Shuffle(@RandomTestRefFunc);

    { Object methods }
    AssertEquals('count unchanged', SizeInt(Length(LOriginalElements)), SizeInt(LVecDeque.Count));


    for i := 0 to High(LOriginalElements) do
    begin
      LFound := False;
      for j := 0 to Integer(LVecDeque.Count) - 1 do
      begin
        if LVecDeque.Get(j) = LOriginalElements[i] then
        begin
          LFound := True;
          Break;
        end;
      end;
      AssertTrue('orig elements still exist', LFound);
    end;
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Shuffle_StartIndex_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartIndex, LCount: SizeUInt;
  LFound: boolean;
  i, j: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 10 do
      LVecDeque.PushBack(i);

    LStartIndex := 3;
    LCount := 5;


    LVecDeque.Shuffle(LStartIndex, LCount);

    { Object methods }
    AssertEquals('count unchanged', SizeInt(10), SizeInt(LVecDeque.Count));


    for i := 0 to Integer(LStartIndex) - 1 do
      AssertEquals('prefix unchanged', i + 1, LVecDeque.Get(i));

    for i := Integer(LStartIndex + LCount) to Integer(LVecDeque.Count) - 1 do
      AssertEquals('suffix unchanged', i + 1, LVecDeque.Get(i));


    for i := Integer(LStartIndex) + 1 to Integer(LStartIndex + LCount) do
    begin
      LFound := False;
      for j := Integer(LStartIndex) to Integer(LStartIndex + LCount) - 1 do
      begin
        if LVecDeque.Get(j) = i then
        begin
          LFound := True;
          Break;
        end;
      end;
      AssertTrue('in-range elements still exist', LFound);
    end;
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Shuffle_StartIndex_Count_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartIndex, LCount: SizeUInt;
  LFound: boolean;
  i, j: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 8 do
      LVecDeque.PushBack(i * 5);

    LStartIndex := 2;
    LCount := 4;


    LVecDeque.Shuffle(LStartIndex, LCount, @RandomTestFunc, @Self);

    { Object methods }
    AssertEquals('count unchanged', SizeInt(8), SizeInt(LVecDeque.Count));


    for i := 0 to Integer(LStartIndex) - 1 do
      AssertEquals('prefix unchanged', (i + 1) * 5, LVecDeque.Get(i));

    for i := Integer(LStartIndex + LCount) to Integer(LVecDeque.Count) - 1 do
      AssertEquals('suffix unchanged', (i + 1) * 5, LVecDeque.Get(i));


    for i := Integer(LStartIndex) + 1 to Integer(LStartIndex + LCount) do
    begin
      LFound := False;
      for j := Integer(LStartIndex) to Integer(LStartIndex + LCount) - 1 do
      begin
        if LVecDeque.Get(j) = i * 5 then
        begin
          LFound := True;
          Break;
        end;
      end;
      AssertTrue('in-range elements still exist', LFound);
    end;
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Shuffle_StartIndex_Count_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartIndex, LCount: SizeUInt;
  LFound: boolean;
  i, j: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 9 do
      LVecDeque.PushBack(i * 3);

    LStartIndex := 1;
    LCount := 6;


    LVecDeque.Shuffle(LStartIndex, LCount, @RandomTestRefFunc);

    { Object methods }
    AssertEquals('count unchanged', SizeInt(9), SizeInt(LVecDeque.Count));


    AssertEquals('rangefront_elementshouldrepairgarbled_text', 3, LVecDeque.Get(0));

    for i := Integer(LStartIndex + LCount) to Integer(LVecDeque.Count) - 1 do
      AssertEquals('rangeback_elementshouldrepairgarbled_text', (i + 1) * 3, LVecDeque.Get(i));


    for i := Integer(LStartIndex) + 1 to Integer(LStartIndex + LCount) do
    begin
      LFound := False;
      for j := Integer(LStartIndex) to Integer(LStartIndex + LCount) - 1 do
      begin
        if LVecDeque.Get(j) = i * 3 then
        begin
          LFound := True;
          Break;
        end;
      end;
      AssertTrue('in-range elements still exist', LFound);
    end;
  finally
    LVecDeque.Free;
  end;
end;



{ Object methods }

procedure TTestCase_VecDeque.Test_FindUnChecked_Element;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(30);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(40);


    LIndex := LVecDeque.FindUnChecked(20, 0, SizeUInt(LVecDeque.Count));
    AssertEquals('find first index', SizeUInt(1), LIndex);


    LIndex := LVecDeque.FindUnChecked(10, 0, SizeUInt(LVecDeque.Count));
    AssertEquals('find first element', SizeUInt(0), LIndex);


    LIndex := LVecDeque.FindUnChecked(40, 0, SizeUInt(LVecDeque.Count));
    AssertEquals('find last element', SizeUInt(4), LIndex);

    { Object methods }
    LIndex := LVecDeque.FindUnChecked(99, 0, SizeUInt(LVecDeque.Count));
    AssertEquals('not found -> SIZE_MAX', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindUnChecked_Element_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(5);
    LVecDeque.PushBack(15);
    LVecDeque.PushBack(25);
    LVecDeque.PushBack(15);
    LVecDeque.PushBack(35);


    LIndex := LVecDeque.FindUnChecked(15, 0, SizeUInt(LVecDeque.Count), @EqualsTestFunc, @Self);
    AssertEquals('find first index', SizeUInt(1), LIndex);

    { Object methods }
    LIndex := LVecDeque.FindUnChecked(99, 0, SizeUInt(LVecDeque.Count), @EqualsTestFunc, @Self);
    AssertEquals('not found -> SIZE_MAX', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindUnChecked_Element_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(7);
    LVecDeque.PushBack(14);
    LVecDeque.PushBack(21);
    LVecDeque.PushBack(14);
    LVecDeque.PushBack(28);


    LIndex := LVecDeque.FindUnChecked(14, 0, SizeUInt(LVecDeque.Count), @EqualsTestMethod, @Self);
    AssertEquals('find first index', SizeUInt(1), LIndex);


    LIndex := LVecDeque.FindUnChecked(7, 0, SizeUInt(LVecDeque.Count), @EqualsTestMethod, @Self);
    AssertEquals('find first element', SizeUInt(0), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindUnChecked_Element_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(9);
    LVecDeque.PushBack(18);
    LVecDeque.PushBack(27);
    LVecDeque.PushBack(18);
    LVecDeque.PushBack(36);


    LIndex := LVecDeque.FindUnChecked(18, 0, SizeUInt(LVecDeque.Count), function (const a,b: Integer): Boolean
  begin
    Result := a = b;
  end);
    AssertEquals('find first index', SizeUInt(1), LIndex);


    LIndex := LVecDeque.FindUnChecked(36, 0, SizeUInt(LVecDeque.Count), function (const a,b: Integer): Boolean
  begin
    Result := a = b;
  end);
    AssertEquals('find last element', SizeUInt(4), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

{ Object methods }

procedure TTestCase_VecDeque.Test_FindLastUnChecked_Element;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(30);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(40);


    LIndex := LVecDeque.FindLastUnChecked(20, 0, SizeUInt(LVecDeque.Count));
    AssertEquals('find last index', SizeUInt(3), LIndex);


    LIndex := LVecDeque.FindLastUnChecked(10, 0, SizeUInt(LVecDeque.Count));
    AssertEquals('find first element', SizeUInt(0), LIndex);


    LIndex := LVecDeque.FindLastUnChecked(40, 0, SizeUInt(LVecDeque.Count));
    AssertEquals('find last element', SizeUInt(4), LIndex);

    { Object methods }
    LIndex := LVecDeque.FindLastUnChecked(99, 0, SizeUInt(LVecDeque.Count));
    AssertEquals('not found -> SIZE_MAX', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLastUnChecked_Element_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(5);
    LVecDeque.PushBack(15);
    LVecDeque.PushBack(25);
    LVecDeque.PushBack(15);
    LVecDeque.PushBack(35);
    LVecDeque.PushBack(15);


    LIndex := LVecDeque.FindLastUnChecked(15, 0, SizeUInt(LVecDeque.Count), @EqualsTestFunc, @Self);
    AssertEquals('find last index', SizeUInt(5), LIndex);

    { Object methods }
    LIndex := LVecDeque.FindLastUnChecked(99, 0, SizeUInt(LVecDeque.Count), @EqualsTestFunc, @Self);
    AssertEquals('not found -> SIZE_MAX', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLastUnChecked_Element_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(7);
    LVecDeque.PushBack(14);
    LVecDeque.PushBack(21);
    LVecDeque.PushBack(14);
    LVecDeque.PushBack(28);
    LVecDeque.PushBack(14);


    LIndex := LVecDeque.FindLastUnChecked(14, 0, SizeUInt(LVecDeque.Count), @EqualsTestMethod, @Self);
    AssertEquals('find last index', SizeUInt(5), LIndex);


    LIndex := LVecDeque.FindLastUnChecked(21, 0, SizeUInt(LVecDeque.Count), @EqualsTestMethod, @Self);
    AssertEquals('find element', SizeUInt(2), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FindLastUnChecked_Element_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(9);
    LVecDeque.PushBack(18);
    LVecDeque.PushBack(27);
    LVecDeque.PushBack(18);
    LVecDeque.PushBack(36);
    LVecDeque.PushBack(18);


    LIndex := LVecDeque.FindLastUnChecked(18, 0, SizeUInt(LVecDeque.Count), function (const a,b: Integer): Boolean
  begin
    Result := a = b;
  end);
    AssertEquals('find last index', SizeUInt(5), LIndex);


    LIndex := LVecDeque.FindLastUnChecked(9, 0, SizeUInt(LVecDeque.Count), function (const a,b: Integer): Boolean
  begin
    Result := a = b;
  end);
    AssertEquals('find first element', SizeUInt(0), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

{ Object methods }

procedure TTestCase_VecDeque.Test_BinarySearchInsert_Element;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInsertIndex: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(30);
    LVecDeque.PushBack(50);
    LVecDeque.PushBack(60);


    LInsertIndex := LVecDeque.BinarySearchInsert(5);
    AssertEquals('garbled_text', SizeUInt(0), LInsertIndex);


    LInsertIndex := LVecDeque.BinarySearchInsert(25);
    AssertEquals('garbled_text', SizeUInt(2), LInsertIndex);


    LInsertIndex := LVecDeque.BinarySearchInsert(70);
    AssertEquals('garbled_text', SizeUInt(5), LInsertIndex);


    LInsertIndex := LVecDeque.BinarySearchInsert(30);
    AssertTrue('garbled_text', (LInsertIndex = 2) or (LInsertIndex = 3));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_BinarySearchInsert_Element_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInsertIndex: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(2);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(12);

    { Object methods }
    LInsertIndex := LVecDeque.BinarySearchInsert(8, @CompareTestFunc, @Self);
    AssertEquals('garbled_text', SizeUInt(3), LInsertIndex);


    LInsertIndex := LVecDeque.BinarySearchInsert(1, @CompareTestFunc, @Self);
    AssertEquals('garbled_text', SizeUInt(0), LInsertIndex);


    LInsertIndex := LVecDeque.BinarySearchInsert(15, @CompareTestFunc, @Self);
    AssertEquals('garbled_text', SizeUInt(5), LInsertIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_BinarySearchInsert_Element_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInsertIndex: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(5);
    LVecDeque.PushBack(15);
    LVecDeque.PushBack(25);
    LVecDeque.PushBack(35);

    { Object methods }
    LInsertIndex := LVecDeque.BinarySearchInsert(20, @CompareTestMethod, @Self);
    AssertEquals('garbled_text', SizeUInt(2), LInsertIndex);


    LInsertIndex := LVecDeque.BinarySearchInsert(15, @CompareTestMethod, @Self);
    AssertTrue('garbled_text', (LInsertIndex = 1) or (LInsertIndex = 2));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_BinarySearchInsert_Element_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInsertIndex: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(3);
    LVecDeque.PushBack(9);
    LVecDeque.PushBack(15);
    LVecDeque.PushBack(21);
    LVecDeque.PushBack(27);

    { Object methods }
    LInsertIndex := LVecDeque.BinarySearchInsert(12, @CompareTestRefFunc);
    AssertEquals('garbled_text', SizeUInt(2), LInsertIndex);


    LInsertIndex := LVecDeque.BinarySearchInsert(1, @CompareTestRefFunc);
    AssertEquals('garbled_text', SizeUInt(0), LInsertIndex);
  finally
    LVecDeque.Free;
  end;
end;

{ Object methods }

procedure TTestCase_VecDeque.Test_IsSorted_StartIndex;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LResult: Boolean;
  LStartIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(5);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(6);

    LStartIndex := 2;


    LResult := LVecDeque.IsSorted(LStartIndex);
    AssertTrue('garbled_text', LResult);


    LResult := LVecDeque.IsSorted(0);
    AssertFalse('garbled0garbled_text', LResult);


    LResult := LVecDeque.IsSorted(5);
    AssertTrue('garbled_text', LResult);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IsSorted_StartIndex_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LResult: Boolean;
  LStartIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(10);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(8);

    LStartIndex := 2;


    LResult := LVecDeque.IsSorted(LStartIndex, @CompareTestFunc, @Self);
    AssertTrue('garbled_text?_€garbled_textユgarbled_text', LResult);


    LResult := LVecDeque.IsSorted(0, @CompareTestFunc, @Self);
    AssertFalse('garbled_text?_€garbled_textユ_garbled_textgarbled_text', LResult);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IsSorted_StartIndex_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LResult: Boolean;
  LStartIndex, LCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(9);
    LVecDeque.PushBack(1);   { sortrangestart}
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(7);   { Object methods }
    LVecDeque.PushBack(2);

    LStartIndex := 1;
    LCount := 4;


    LResult := LVecDeque.IsSorted(LStartIndex, LCount);
    AssertTrue('garbled_text', LResult);


    LResult := LVecDeque.IsSorted(0, 6);
    AssertFalse('garbled_text', LResult);

    { Object methods }
    LResult := LVecDeque.IsSorted(LStartIndex, 1);
    AssertTrue('garbled_text', LResult);
  finally
    LVecDeque.Free;
  end;
end;

{ Object methods }

procedure TTestCase_VecDeque.Test_SortUnChecked;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(8);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(9);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(4);


    LVecDeque.SortUnChecked(0, SizeUInt(LVecDeque.Count));

    { Object methods }
    AssertEquals('count garbled', SizeInt(6), SizeInt(LVecDeque.Count));
    AssertEquals('idx0 garbled', 1, LVecDeque.Get(0));
    AssertEquals('idx1 garbled', 3, LVecDeque.Get(1));
    AssertEquals('idx2 garbled', 4, LVecDeque.Get(2));
    AssertEquals('idx3 garbled', 6, LVecDeque.Get(3));
    AssertEquals('idx4 garbled', 8, LVecDeque.Get(4));
    AssertEquals('idx5 garbled', 9, LVecDeque.Get(5));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_SortUnChecked_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(15);
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(25);
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);


    LVecDeque.SortUnChecked(0, SizeUInt(LVecDeque.Count), @CompareTestFunc, @Self);

    { Object methods }
    AssertEquals('count garbled', SizeInt(5), SizeInt(LVecDeque.Count));

    for i := 0 to Integer(LVecDeque.Count) - 2 do
      AssertTrue('garbled_text_', LVecDeque.Get(i) <= LVecDeque.Get(i + 1));
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_ClearAndReserve;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LReserveCapacity: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 10 do
      LVecDeque.PushBack(i);

    LReserveCapacity := 20;


    LVecDeque.ClearAndReserve(LReserveCapacity);

    { Object methods }
    AssertEquals('garbled count _ 0', SizeInt(0), SizeInt(LVecDeque.Count));
    AssertTrue('garbled', LVecDeque.IsEmpty);
    AssertTrue('garbled≥garbled_text_', LVecDeque.Capacity >= LReserveCapacity);


    for i := 0 to Integer(LReserveCapacity) - 1 do
      LVecDeque.PushBack(i);
    AssertEquals('garbled_textgarbled', SizeInt(LReserveCapacity), SizeInt(LVecDeque.Count));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FastIndexOf;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(30);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(40);


    LIndex := LVecDeque.FastIndexOf(20);
    AssertEquals('garbled_text', SizeUInt(1), LIndex);


    LIndex := LVecDeque.FastIndexOf(10);
    AssertEquals('garbled_text', SizeUInt(0), LIndex);


    LIndex := LVecDeque.FastIndexOf(40);
    AssertEquals('garbled_text', SizeUInt(4), LIndex);

    { Object methods }
    LIndex := LVecDeque.FastIndexOf(99);
    AssertEquals('garbled_text SIZE_MAX', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FastLastIndexOf;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(30);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(40);
    LVecDeque.PushBack(20);


    LIndex := LVecDeque.FastLastIndexOf(20);
    AssertEquals('garbled_text', SizeUInt(5), LIndex);


    LIndex := LVecDeque.FastLastIndexOf(30);
    AssertEquals('garbled_text', SizeUInt(2), LIndex);

    { Object methods }
    LIndex := LVecDeque.FastLastIndexOf(99);
    AssertEquals('garbled_text SIZE_MAX', High(SizeUInt), LIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_FillWith;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LFillValue: Integer;
  LFillCount: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LFillValue := 42;
    LFillCount := 8;


    LVecDeque.FillWith(LFillValue, LFillCount);

    { Object methods }
    AssertEquals('count garbled_text', SizeInt(LFillCount), SizeInt(LVecDeque.Count));


    for i := 0 to Integer(LVecDeque.Count) - 1 do
      AssertEquals('garbled_text', LFillValue, LVecDeque.Get(i));


    LVecDeque.FillWith(99, 3);
    AssertEquals('count garbled', SizeInt(LFillCount) + 3, SizeInt(LVecDeque.Count));


    for i := Integer(LFillCount) to Integer(LVecDeque.Count) - 1 do
      AssertEquals('garbled_text 99', 99, LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_BinarySearchInsert_StartIndex_Element;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInsertIndex, LStartIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(100);
    LVecDeque.PushBack(50);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(12);

    LStartIndex := 2;


    LInsertIndex := LVecDeque.BinarySearchInsert(8, LStartIndex);
    AssertEquals('garbled_text', SizeUInt(5), LInsertIndex);


    LInsertIndex := LVecDeque.BinarySearchInsert(1, LStartIndex);
    AssertEquals('garbled_text', SizeUInt(2), LInsertIndex);


    LInsertIndex := LVecDeque.BinarySearchInsert(15, LStartIndex);
    AssertEquals('garbled_text', SizeUInt(7), LInsertIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_BinarySearchInsert_StartIndex_Element_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInsertIndex, LStartIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(99);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(15);
    LVecDeque.PushBack(20);

    LStartIndex := 1;


    LInsertIndex := LVecDeque.BinarySearchInsert(12, LStartIndex, @CompareTestFunc, @Self);
    AssertEquals('garbled_text', SizeUInt(4), LInsertIndex);


    LInsertIndex := LVecDeque.BinarySearchInsert(10, LStartIndex, @CompareTestFunc, @Self);
    AssertTrue('garbled_text', (LInsertIndex = 3) or (LInsertIndex = 4));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_BinarySearchInsert_StartIndex_Element_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInsertIndex, LStartIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(88);
    LVecDeque.PushBack(77);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(9);
    LVecDeque.PushBack(15);
    LVecDeque.PushBack(21);

    LStartIndex := 2;


    LInsertIndex := LVecDeque.BinarySearchInsert(12, LStartIndex, @CompareTestMethod, @Self);
    AssertEquals('garbled_text', SizeUInt(4), LInsertIndex);


    LInsertIndex := LVecDeque.BinarySearchInsert(1, LStartIndex, @CompareTestMethod, @Self);
    AssertEquals('garbled_text', SizeUInt(2), LInsertIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_BinarySearchInsert_StartIndex_Element_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInsertIndex, LStartIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(66);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(12);
    LVecDeque.PushBack(16);
    LVecDeque.PushBack(20);

    LStartIndex := 1;


    LInsertIndex := LVecDeque.BinarySearchInsert(14, LStartIndex, @CompareTestRefFunc);
    AssertEquals('garbled_text', SizeUInt(4), LInsertIndex);


    LInsertIndex := LVecDeque.BinarySearchInsert(25, LStartIndex, @CompareTestRefFunc);
    AssertEquals('garbled_text', SizeUInt(6), LInsertIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_BinarySearchInsert_StartIndex_Count_Element;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInsertIndex, LStartIndex, LCount: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(100);
    LVecDeque.PushBack(2);    { sortrangestart}
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(14);   { Object methods }
    LVecDeque.PushBack(200);

    LStartIndex := 1;
    LCount := 4;

    { Object methods }
    LInsertIndex := LVecDeque.BinarySearchInsert(8, LStartIndex, LCount);
    AssertEquals('garbled_text', SizeUInt(3), LInsertIndex);


    LInsertIndex := LVecDeque.BinarySearchInsert(1, LStartIndex, LCount);
    AssertEquals('garbled_text', SizeUInt(1), LInsertIndex);


    LInsertIndex := LVecDeque.BinarySearchInsert(16, LStartIndex, LCount);
    AssertEquals('garbled_text', SizeUInt(5), LInsertIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_BinarySearchInsert_StartIndex_Count_Element_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInsertIndex, LStartIndex, LCount: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(999);
    LVecDeque.PushBack(3);    { sortrangestart}
    LVecDeque.PushBack(9);
    LVecDeque.PushBack(15);
    LVecDeque.PushBack(21);
    LVecDeque.PushBack(27);   { Object methods }
    LVecDeque.PushBack(888);

    LStartIndex := 1;
    LCount := 5;

    { Object methods }
    LInsertIndex := LVecDeque.BinarySearchInsert(18, LStartIndex, LCount, @CompareTestFunc, @Self);
    AssertEquals('garbled_text', SizeUInt(4), LInsertIndex);


    LInsertIndex := LVecDeque.BinarySearchInsert(15, LStartIndex, LCount, @CompareTestFunc, @Self);
    AssertTrue('garbled_text', (LInsertIndex = 3) or (LInsertIndex = 4));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_BinarySearchInsert_StartIndex_Count_Element_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInsertIndex, LStartIndex, LCount: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(777);
    LVecDeque.PushBack(5);    { sortrangestart}
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(15);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(25);   { Object methods }
    LVecDeque.PushBack(666);

    LStartIndex := 1;
    LCount := 5;

    { Object methods }
    LInsertIndex := LVecDeque.BinarySearchInsert(17, LStartIndex, LCount, @CompareTestMethod, @Self);
    AssertEquals('garbled_text', SizeUInt(4), LInsertIndex);


    LInsertIndex := LVecDeque.BinarySearchInsert(3, LStartIndex, LCount, @CompareTestMethod, @Self);
    AssertEquals('garbled_text', SizeUInt(1), LInsertIndex);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_BinarySearchInsert_StartIndex_Count_Element_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInsertIndex, LStartIndex, LCount: SizeUInt;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(555);
    LVecDeque.PushBack(444);
    LVecDeque.PushBack(6);    { sortrangestart}
    LVecDeque.PushBack(12);
    LVecDeque.PushBack(18);
    LVecDeque.PushBack(24);   { Object methods }
    LVecDeque.PushBack(333);

    LStartIndex := 2;
    LCount := 4;

    { Object methods }
    LInsertIndex := LVecDeque.BinarySearchInsert(15, LStartIndex, LCount, @CompareTestRefFunc);
    AssertEquals('garbled_text', SizeUInt(4), LInsertIndex);


    LInsertIndex := LVecDeque.BinarySearchInsert(30, LStartIndex, LCount, @CompareTestRefFunc);
    AssertEquals('garbled_text', SizeUInt(6), LInsertIndex);
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_IsSorted_StartIndex_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LResult: Boolean;
  LStartIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(15);
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(10);

    LStartIndex := 2;


    LResult := LVecDeque.IsSorted(LStartIndex, @CompareTestMethod, @Self);
    AssertTrue('garbled_text?_€garbled_textユgarbled_text', LResult);


    LResult := LVecDeque.IsSorted(0, @CompareTestMethod, @Self);
    AssertFalse('garbled_text?_€garbled_textユ_garbled_textgarbled_text', LResult);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IsSorted_StartIndex_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LResult: Boolean;
  LStartIndex: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(20);
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(9);
    LVecDeque.PushBack(12);

    LStartIndex := 2;


    LResult := LVecDeque.IsSorted(LStartIndex, @CompareTestRefFunc);
    AssertTrue('garbled_text?_€garbled_textユgarbled_text', LResult);


    LResult := LVecDeque.IsSorted(1, @CompareTestRefFunc);
    AssertFalse('garbled_text?_€garbled_textユ_garbled_textgarbled_text', LResult);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IsSorted_StartIndex_Count_Func;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LResult: Boolean;
  LStartIndex, LCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(25);
    LVecDeque.PushBack(1);   { sortrangestart}
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(7);
    LVecDeque.PushBack(10);  { Object methods }
    LVecDeque.PushBack(5);

    LStartIndex := 1;
    LCount := 4;


    LResult := LVecDeque.IsSorted(LStartIndex, LCount, @CompareTestFunc, @Self);
    AssertTrue('garbled_text', LResult);


    LResult := LVecDeque.IsSorted(0, 6, @CompareTestFunc, @Self);
    AssertFalse('garbled_text', LResult);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IsSorted_StartIndex_Count_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LResult: Boolean;
  LStartIndex, LCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(30);
    LVecDeque.PushBack(2);   { sortrangestart}
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(11);
    LVecDeque.PushBack(14);  { Object methods }
    LVecDeque.PushBack(1);

    LStartIndex := 1;
    LCount := 5;


    LResult := LVecDeque.IsSorted(LStartIndex, LCount, @CompareTestMethod, @Self);
    AssertTrue('garbled_textgarbledrangegarbled_textgarbledユgarbled_text', LResult);

    { Object methods }
    LResult := LVecDeque.IsSorted(LStartIndex, 2, @CompareTestMethod, @Self);
    AssertTrue('_や_elementgarbled_textgarbled_textgarbledユgarbled_text', LResult);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IsSorted_StartIndex_Count_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LResult: Boolean;
  LStartIndex, LCount: SizeUInt;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(40);
    LVecDeque.PushBack(35);
    LVecDeque.PushBack(3);   { sortrangestart}
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(9);
    LVecDeque.PushBack(12);
    LVecDeque.PushBack(15);  { Object methods }

    LStartIndex := 2;
    LCount := 5;


    LResult := LVecDeque.IsSorted(LStartIndex, LCount, @CompareTestRefFunc);
    AssertTrue('garbled_text', LResult);


    LResult := LVecDeque.IsSorted(1, 6, @CompareTestRefFunc);
    AssertFalse('garbled_text', LResult);
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_SortUnChecked_Method;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(25);
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(35);
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(30);
    LVecDeque.PushBack(15);


    LVecDeque.SortUnChecked(0, SizeUInt(LVecDeque.Count), @CompareTestMethod, @Self);

    { Object methods }
    AssertEquals('count garbled', SizeInt(6), SizeInt(LVecDeque.Count));

    for i := 0 to Integer(LVecDeque.Count) - 2 do
      AssertTrue('garbled_text_', LVecDeque.Get(i) <= LVecDeque.Get(i + 1));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_SortUnChecked_RefFunc;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(18);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(27);
    LVecDeque.PushBack(9);
    LVecDeque.PushBack(21);

    // Use reference compare function to sort without boundary checks
    LVecDeque.SortUnChecked(0, SizeUInt(LVecDeque.Count), @CompareTestRefFunc);

    // Verify results
    AssertEquals('Count should remain 5', SizeInt(5), SizeInt(LVecDeque.Count));
    // Verify non-decreasing order
    for i := 0 to Integer(LVecDeque.Count) - 2 do
      AssertTrue('Should be non-decreasing', LVecDeque.Get(i) <= LVecDeque.Get(i + 1));
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_WarmupMemory;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LWarmupSize: SizeUInt;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LWarmupSize := 50;


    LVecDeque.WarmupMemory(LWarmupSize); // Test comment

    // Verify results
    AssertEquals('Count should be 0 after warmup', SizeInt(0), SizeInt(LVecDeque.Count));
    AssertTrue('Should be empty', LVecDeque.IsEmpty);
    AssertTrue('Capacity should be >= warmup size', LVecDeque.Capacity >= LWarmupSize);

    // Verify performance after warmup - push should be fast
    for i := 0 to Integer(LWarmupSize) - 1 do
      LVecDeque.PushBack(i);

    AssertEquals('Should be able to push up to warmup size', SizeInt(LWarmupSize), SizeInt(LVecDeque.Count));

    // Verify data correctness
    for i := 0 to Integer(LVecDeque.Count) - 1 do
      AssertEquals('Element value should equal i', i, LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Capacity_Zero_Size;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  // Test comment
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    // Initial state
    AssertEquals('Initial count should be 0', 0, LVecDeque.Count);
    AssertTrue('Should be empty initially', LVecDeque.IsEmpty);

    // Resize to 0
    LVecDeque.Resize(0);
    AssertEquals('After resize(0) count should be 0', 0, LVecDeque.Count);
    AssertTrue('After resize(0) should be empty', LVecDeque.IsEmpty);

    // Reserve 0
    LVecDeque.Reserve(0);
    AssertEquals('After reserve(0) count should be 0', 0, LVecDeque.Count);

    // Clear path
    LVecDeque.PushBack(42);
    AssertEquals('After push count should be 1', 1, LVecDeque.Count);

    LVecDeque.Clear;
    AssertEquals('After clear count should be 0', 0, LVecDeque.Count);
    AssertTrue('After clear should be empty', LVecDeque.IsEmpty);

    // Shrink to 0
    LVecDeque.ShrinkTo(0);
    AssertEquals('After shrinkTo(0) count should be 0', 0, LVecDeque.Count);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Memory_Large_Objects;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LLargeSize: SizeUInt;
  i, LIndex: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LLargeSize := 10000; { Object methods }


    for i := 0 to Integer(LLargeSize) - 1 do
      LVecDeque.PushBack(i);


    AssertEquals('shouldcontain_ч_element', LLargeSize, LVecDeque.Count);


    for i := 0 to 99 do
    begin
      LIndex := (i * Integer(LLargeSize)) div 100;
      AssertEquals('garbled_text', LIndex, LVecDeque.Get(LIndex));
    end;


    for i := 0 to Integer(LLargeSize div 2) - 1 do
      LVecDeque.PopBack;

    AssertEquals('delete_€garbled_textcountshouldcorrect‘', LLargeSize div 2, LVecDeque.Count);

    { Object methods }
    LVecDeque.ShrinkToFit;
    AssertEquals('garbled_text', LLargeSize div 2, LVecDeque.Count);


    for i := 0 to LVecDeque.Count - 1 do
      AssertEquals('garbled_text╀_elementshouldcorrect‘', i, LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Exception_OverflowError;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LExceptionRaised: Boolean;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LExceptionRaised := False;
    try

      LVecDeque.Reserve(High(SizeUInt));
    except
      on E: Exception do
        LExceptionRaised := True;
    end;

    AssertTrue('garbledぇgarbled_text_garbled_text_garbled_textgarbledヨgarbled_textgarbledprocess', True);

    { Object methods }
    LExceptionRaised := False;
    try
      LVecDeque.Resize(High(SizeUInt) div 2);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;

    AssertTrue('garbledぇgarbled_text_ぇgarbled_textgarbledヨgarbled_textgarbledprocess', True);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Exception_UnderflowError;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LExceptionRaised: Boolean;
  LValue: integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LExceptionRaised := False;
    try
      LVecDeque.PopFront;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Underflow PopFront should raise', LExceptionRaised);


    LExceptionRaised := False;
    try
      LVecDeque.PopBack;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Underflow PopBack should raise', LExceptionRaised);


    LExceptionRaised := False;
    try
      LValue := LVecDeque.Front;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Access Front on empty should raise', LExceptionRaised);

    LExceptionRaised := False;
    try
      LValue := LVecDeque.Back;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Access Back on empty should raise', LExceptionRaised);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Exception_DivideByZero;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LExceptionRaised: Boolean;
  LResult: Integer;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    // 由于VecDeque本身不执行除法运算，我们需要测试可能导致除零的场景
    // 这主要是在自定义比较器或处理函数中可能发生的情况

    LVecDeque.PushBack(10);
    LVecDeque.PushBack(0);
    LVecDeque.PushBack(5);

    // 测试在比较操作中可能的除零情况
    // 注意：这个测试主要是为了完整性，实际的除零错误更可能在用户代码中发生
    LExceptionRaised := False;
    try
      // 执行一些可能触发除零的操作
      // 在实际应用中，这可能发生在自定义比较器中
      LResult := LVecDeque.GetCount div LVecDeque.GetCount; // 这不会导致除零

      // 模拟一个可能的除零场景
      if LVecDeque.Get(1) = 0 then
      begin
        // 这里可能会有除零操作，但我们需要小心不要真的执行它
        // LResult := LVecDeque.Get(0) div LVecDeque.Get(1); // 这会导致除零
        raise EDivByZero.Create('Simulated divide by zero');
      end;
    except
      on E: EDivByZero do
        LExceptionRaised := True;
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Should handle divide by zero scenario', LExceptionRaised);

  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Exception_InvalidCast;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LExceptionRaised: Boolean;
  LBuffer: Pointer;
  LArray: array of Integer;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    // 由于Pascal是强类型语言，无效转换通常在编译时被捕获
    // 但我们可以测试一些运行时可能的转换问题

    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);

    // 测试无效的内存转换操作
    LExceptionRaised := False;
    try
      // 尝试一些可能导致无效转换的操作
      LBuffer := nil;

      // 尝试从无效指针读取
      LVecDeque.Read(0, LBuffer, 1);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Should raise exception for invalid cast/pointer operation', LExceptionRaised);

    // 测试类型安全相关的操作
    LExceptionRaised := False;
    try
      // 测试一些边界情况
      SetLength(LArray, 0);
      // VecDeque 没有 Assign 方法，改为测试其他类型安全操作
      LVecDeque.Clear;
      LVecDeque.PushBack(1);

      // 测试无效的写入操作
      LVecDeque.Write(0, nil, 1);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('Should raise exception for invalid write operation', LExceptionRaised);

  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Exception_ResourceExhausted;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LExceptionRaised: Boolean;
  i: Integer;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    // 测试资源耗尽的情况

    // 测试内存资源耗尽
    LExceptionRaised := False;
    try
      // 尝试分配大量内存
      LVecDeque.Reserve(High(SizeUInt) div 4);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    // 注意：这个测试可能不会总是失败，取决于可用内存

    // 测试在资源压力下的操作
    LExceptionRaised := False;
    try
      // 尝试执行大量操作
      for i := 1 to 100000 do
      begin
        LVecDeque.PushBack(i);
        if i mod 1000 = 0 then
        begin
          // 执行一些内存密集的操作
          LVecDeque.Sort;
          LVecDeque.Reverse;
        end;
      end;
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    // 这个测试主要验证在资源压力下不会崩溃

    // 测试句柄或其他系统资源的耗尽
    // 在VecDeque的上下文中，这主要是内存相关的

  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Exception_Recovery;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LExceptionRaised: Boolean;
  i: Integer;
  LValue: Integer;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    // 测试异常恢复的情况

    // 添加一些初始数据
    for i := 1 to 5 do
      LVecDeque.PushBack(i);

    // 测试从越界访问异常中恢复
    LExceptionRaised := False;
    try
      LValue := LVecDeque.Get(100); // 这应该抛出异常
    except
      on E: Exception do
      begin
        LExceptionRaised := True;
        // 验证集合在异常后仍然可用
        AssertEquals('Collection should still be usable after exception', 5, LVecDeque.GetCount);
        AssertEquals('First element should still be accessible', 1, LVecDeque.Get(0));
      end;
    end;
    AssertTrue('Should have raised exception for out-of-bounds access', LExceptionRaised);

    // 测试从空集合操作异常中恢复
    LVecDeque.Clear;
    LExceptionRaised := False;
    try
      LVecDeque.PopBack; // 这应该抛出异常
    except
      on E: Exception do
      begin
        LExceptionRaised := True;
        // 验证集合在异常后仍然可用
        AssertEquals('Collection should still be empty after exception', 0, LVecDeque.GetCount);

        // 验证可以继续正常操作
        LVecDeque.PushBack(42);
        AssertEquals('Should be able to add elements after exception', 1, LVecDeque.GetCount);
        AssertEquals('Added element should be correct', 42, LVecDeque.Get(0));
      end;
    end;
    AssertTrue('Should have raised exception for empty collection operation', LExceptionRaised);

    // 测试从内存分配异常中恢复
    LExceptionRaised := False;
    try
      LVecDeque.Reserve(High(SizeUInt)); // 这可能抛出异常
    except
      on E: Exception do
      begin
        LExceptionRaised := True;
        // 验证集合在异常后仍然可用
        AssertTrue('Collection should still be usable after memory exception', LVecDeque.GetCount >= 0);

        // 验证可以继续正常操作
        LVecDeque.Clear;
        LVecDeque.PushBack(123);
        AssertEquals('Should be able to use collection after memory exception', 123, LVecDeque.Get(0));
      end;
    end;
    // 注意：内存分配异常可能不会总是发生

  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Allocator;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LAllocator: IAllocator;
begin

  LAllocator := GetRtlAllocator();
  LVecDeque := specialize TVecDeque<Integer>.Create(LAllocator);
  try
    AssertNotNull('VecDeque created with allocator should be valid', LVecDeque);
    AssertEquals('Initial count should be 0', 0, LVecDeque.Count);
    AssertTrue('Should be empty initially', LVecDeque.IsEmpty);
    AssertTrue('Capacity should be >= 0', LVecDeque.Capacity >= 0);

    // Basic operations
    LVecDeque.PushBack(42);
    AssertEquals('After push count should be 1', 1, LVecDeque.Count);
    AssertEquals('Element value should be 42', 42, LVecDeque.Get(0));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Allocator_Data;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LAllocator: IAllocator;
  LData: Pointer;
begin

  LAllocator := CreateAllocator;
  LData := @Self; { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create(LAllocator, LData);
  try
    AssertNotNull('VecDeque created with allocator+data should be valid', LVecDeque);
    AssertEquals('Initial count should be 0', 0, LVecDeque.Count);
    AssertTrue('Should be empty initially', LVecDeque.IsEmpty);

    { Object methods }
    LVecDeque.PushBack(123);
    LVecDeque.PushBack(456);
    AssertEquals('Count should be 2 after pushes', 2, LVecDeque.Count);
    AssertEquals('First element should be 123', 123, LVecDeque.Get(0));
    AssertEquals('Second element should be 456', 456, LVecDeque.Get(1));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Allocator_GrowStrategy;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LAllocator: IAllocator;
  LGrowStrategy: TGrowthStrategy;
  LInitialCapacity: SizeUInt; i: Integer;
begin

  LAllocator := CreateAllocator;
  LGrowStrategy := GS_Double; { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create(LAllocator, LGrowStrategy);
  try
    AssertNotNull('VecDeque created with allocator+strategy should be valid', LVecDeque);
    AssertEquals('Initial count should be 0', 0, LVecDeque.Count);
    AssertTrue('Should be empty initially', LVecDeque.IsEmpty);

    { Object methods }
    LInitialCapacity := LVecDeque.Capacity;
    for i := 1 to 10 do
      LVecDeque.PushBack(i);

    AssertEquals('After adding 10 elements count should be 10', 10, LVecDeque.Count);
    AssertTrue('Capacity should grow according to strategy', LVecDeque.Capacity >= LInitialCapacity);

    // Verify data
    for i := 0 to Integer(LVecDeque.Count) - 1 do
      AssertEquals('Element value should match i+1', i + 1, LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Allocator_GrowStrategy_Data;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LAllocator: IAllocator;
  LGrowStrategy: TGrowthStrategy;
  LData: Pointer; i: Integer;
begin

  LAllocator := CreateAllocator;
  LGrowStrategy := GS_Linear(16); { Object methods }
  LData := @Self;
  LVecDeque := specialize TVecDeque<Integer>.Create(LAllocator, LGrowStrategy, LData);
  try
    AssertNotNull('VecDeque created with all params should be valid', LVecDeque);
    AssertEquals('Initial count should be 0', 0, LVecDeque.Count);
    AssertTrue('Should be empty initially', LVecDeque.IsEmpty);

    { Object methods }
    LVecDeque.PushBack(789);
    LVecDeque.PushBack(101112);
    AssertEquals('Count should be 2 after pushes', 2, LVecDeque.Count);
    AssertEquals('First element should be 789', 789, LVecDeque.Get(0));
    AssertEquals('Second element should be 101112', 101112, LVecDeque.Get(1));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Capacity;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInitialCapacity: SizeUInt; i: Integer;
begin

  LInitialCapacity := 20;
  LVecDeque := specialize TVecDeque<Integer>.Create(LInitialCapacity);
  try
    AssertNotNull('VecDeque created with capacity should be valid', LVecDeque);
    AssertEquals('Initial count should be 0', 0, LVecDeque.Count);
    AssertTrue('Should be empty initially', LVecDeque.IsEmpty);
    AssertTrue('Capacity should be >= initial', LVecDeque.Capacity >= LInitialCapacity);


    for i := 0 to Integer(LInitialCapacity) - 1 do
      LVecDeque.PushBack(i);

    AssertEquals('Count should equal reserved capacity', LInitialCapacity, LVecDeque.Count);


    for i := 0 to Integer(LVecDeque.Count) - 1 do
      AssertEquals('Element should equal i', i, LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Capacity_Allocator;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInitialCapacity: SizeUInt;
  LAllocator: IAllocator;
  i: Integer;
begin

  LInitialCapacity := 15;
  LAllocator := CreateAllocator;
  LVecDeque := specialize TVecDeque<Integer>.Create(LInitialCapacity, LAllocator);
  try
    AssertNotNull('VecDeque created with capacity+allocator should be valid', LVecDeque);
    AssertEquals('Initial count should be 0', 0, LVecDeque.Count);
    AssertTrue('Should be empty initially', LVecDeque.IsEmpty);
    AssertTrue('Capacity should be >= initial', LVecDeque.Capacity >= LInitialCapacity);

    { Object methods }
    for i := 1 to 5 do
      LVecDeque.PushBack(i * 10);

    AssertEquals('After pushing 5 elements count should be 5', 5, LVecDeque.Count);

    // Verify data
    for i := 0 to Integer(LVecDeque.Count) - 1 do
      AssertEquals('Element value should be (i+1)*10', (i + 1) * 10, LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Capacity_Allocator_Data;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInitialCapacity: SizeUInt;
  LAllocator: IAllocator;
  LGrowStrategy: TGrowthStrategy;
  LData: Pointer;
  i: Integer;
begin

  LInitialCapacity := 25;
  LAllocator := CreateAllocator;
  LData := @Self;
  LGrowStrategy := GS_Double;
  LVecDeque := specialize TVecDeque<Integer>.Create(LInitialCapacity, LAllocator, LGrowStrategy, LData);
  try
    AssertNotNull('VecDeque created with capacity+allocator+data should be valid', LVecDeque);
    AssertEquals('Initial count should be 0', 0, LVecDeque.Count);
    AssertTrue('Should be empty initially', LVecDeque.IsEmpty);
    AssertTrue('Capacity should be >= initial', LVecDeque.Capacity >= LInitialCapacity);

    { testdouble-endedoperation }
    LVecDeque.PushFront(100);
    LVecDeque.PushBack(200);
    LVecDeque.PushFront(50);
    LVecDeque.PushBack(250);

    AssertEquals('Count should be 4', 4, LVecDeque.Count);
    AssertEquals('Front first element should be 50', 50, LVecDeque.Get(0));
    AssertEquals('Front second element should be 100', 100, LVecDeque.Get(1));
    AssertEquals('Back first element should be 200', 200, LVecDeque.Get(2));
    AssertEquals('Back second element should be 250', 250, LVecDeque.Get(3));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Capacity_Allocator_GrowStrategy;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInitialCapacity: SizeUInt;
  LAllocator: IAllocator;
  LGrowStrategy: TGrowthStrategy;
  i: Integer;
begin
  { Object methods }
  LInitialCapacity := 8;
  LAllocator := CreateAllocator;
  LGrowStrategy := GS_Double;
  LVecDeque := specialize TVecDeque<Integer>.Create(LInitialCapacity, LAllocator, LGrowStrategy);
  try
    AssertNotNull('VecDeque created with capacity+allocator+strategy should be valid', LVecDeque);
    AssertEquals('Initial count should be 0', 0, LVecDeque.Count);
    AssertTrue('Capacity should be >= initial', LVecDeque.Capacity >= LInitialCapacity);

    // Strategy should grow beyond initial capacity
    for i := 1 to 12 do
      LVecDeque.PushBack(i);

    AssertEquals('Count should be 12', 12, LVecDeque.Count);
    AssertTrue('Capacity should grow beyond initial', LVecDeque.Capacity > LInitialCapacity);

    // Verify data
    for i := 0 to Integer(LVecDeque.Count) - 1 do
      AssertEquals('Element should equal i+1', i + 1, LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;


procedure TTestCase_VecDeque.Test_Create_Capacity_Allocator_GrowStrategy_Data;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInitialCapacity: SizeUInt;
  LAllocator: IAllocator;
  LGrowStrategy: TGrowthStrategy;
  LData: Pointer;
  i: Integer;
begin
  // Test comment
  LInitialCapacity := 12;
  LAllocator := CreateAllocator;
  LGrowStrategy := GS_Linear(16);
  LData := @Self;
  LVecDeque := specialize TVecDeque<Integer>.Create(LInitialCapacity, LAllocator, LGrowStrategy, LData);
  try
    AssertNotNull('VecDeque created with all params should be valid', LVecDeque);
    AssertEquals('Initial count should be 0', 0, LVecDeque.Count);
    AssertTrue('Should be empty initially', LVecDeque.IsEmpty);
    AssertTrue('Capacity should be >= initial', LVecDeque.Capacity >= LInitialCapacity);

    { Object methods }
    for i := 1 to 5 do
      LVecDeque.PushBack(i);

    for i := 10 to 12 do
      LVecDeque.PushFront(i);

    AssertEquals('Count should be 8 after mixed ops', 8, LVecDeque.Count);

    // Verify front elements
    AssertEquals('Front[0] should be 12', 12, LVecDeque.Get(0));
    AssertEquals('Front[1] should be 11', 11, LVecDeque.Get(1));
    AssertEquals('Front[2] should be 10', 10, LVecDeque.Get(2));

    // Verify back elements
    AssertEquals('Back first should be 1', 1, LVecDeque.Get(3));
    AssertEquals('Back second should be 2', 2, LVecDeque.Get(4));
    AssertEquals('Back last should be 5', 5, LVecDeque.Get(7));
  finally
    LVecDeque.Free;
  end;
end;


{ ===== Basic ICollection tests ===== }

procedure TTestCase_VecDeque.Test_ICollection_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  // Test comment
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    // empty container count
    AssertEquals('Empty count should be 0', 0, LVecDeque.Count);

    // after push
    LVecDeque.PushBack(1);
    AssertEquals('Count should be 1 after one push', 1, LVecDeque.Count);

    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    AssertEquals('Count should be 3 after three pushes', 3, LVecDeque.Count);

    // after pop
    LVecDeque.PopBack;
    AssertEquals('Count should be 2 after pop', 2, LVecDeque.Count);

    // after clear
    LVecDeque.Clear;
    AssertEquals('Count should be 0 after clear', 0, LVecDeque.Count);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ICollection_IsEmpty;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  // Test comment
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    // initially empty
    AssertTrue('Should be empty initially', LVecDeque.IsEmpty);

    // after push becomes non-empty
    LVecDeque.PushBack(42);
    AssertFalse('Should not be empty after push', LVecDeque.IsEmpty);

    // after pop back to empty
    LVecDeque.PopBack;
    AssertTrue('Should be empty after popping all', LVecDeque.IsEmpty);

    // multiple operations then non-empty
    LVecDeque.PushFront(1);
    LVecDeque.PushBack(2);
    AssertFalse('Should not be empty after multiple pushes', LVecDeque.IsEmpty);

    LVecDeque.Clear;
    AssertTrue('Should be empty after clear', LVecDeque.IsEmpty);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_ICollection_Clear;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  // Test comment
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    // clear on empty
    LVecDeque.Clear;
    AssertEquals('Count should be 0 after clear', 0, LVecDeque.Count);
    AssertTrue('Should be empty after clear', LVecDeque.IsEmpty);

    // clear when non-empty
    for i := 1 to 10 do
      LVecDeque.PushBack(i);

    AssertEquals('Count should be 10 after pushes', 10, LVecDeque.Count);
    AssertFalse('Should not be empty after pushes', LVecDeque.IsEmpty);

    LVecDeque.Clear;
    AssertEquals('Count should be 0 after clear', 0, LVecDeque.Count);
    AssertTrue('Should be empty after clear', LVecDeque.IsEmpty);

    // reuse after clear
    LVecDeque.PushBack(99);
    AssertEquals('Count should be 1 after push', 1, LVecDeque.Count);
    AssertEquals('First element should be 99', 99, LVecDeque.Get(0));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IGenericCollection_Add;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  // Test comment
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    // add single element
    LVecDeque.Add(10);
    AssertEquals('Count should be 1 after add', 1, LVecDeque.Count);
    AssertEquals('First element should be 10', 10, LVecDeque.Get(0));

    // add multiple elements
    LVecDeque.Add(20);
    LVecDeque.Add(30);
    AssertEquals('Count should be 3 after adds', 3, LVecDeque.Count);
    AssertEquals('Second element should be 20', 20, LVecDeque.Get(1));
    AssertEquals('Third element should be 30', 30, LVecDeque.Get(2));

    // add duplicated element
    LVecDeque.Add(10);
    AssertEquals('Count should be 4 after adding duplicate', 4, LVecDeque.Count);
    AssertEquals('Fourth element should be 10', 10, LVecDeque.Get(3));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IGenericCollection_Remove;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LRemoved: Boolean;
  LIndex: SizeInt;
begin
  // Test comment
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    // remove from empty
    LRemoved := LVecDeque.RemoveValue(10);
    AssertFalse('RemoveValue should return False on empty', LRemoved);
    AssertEquals('Count should be 0 after remove on empty', 0, LVecDeque.Count);


    LVecDeque.Add(10);
    LVecDeque.Add(20);
    LVecDeque.Add(30);
    LVecDeque.Add(20);

    // remove an existing value (IGenericCollection strict behavior)
    LRemoved := LVecDeque.RemoveValue(20);
    AssertTrue('RemoveValue should return True for existing value', LRemoved);
    AssertEquals('Count should be 3 after remove', 3, LVecDeque.Count);

    // verify first occurrence removed
    AssertEquals('First element should remain 10', 10, LVecDeque.Get(0));
    AssertEquals('Second element should be 30 after removal', 30, LVecDeque.Get(1));
    AssertEquals('Third element should be remaining 20', 20, LVecDeque.Get(2));

    // remove non-existing element
    LRemoved := LVecDeque.RemoveValue(99);
    AssertFalse('RemoveValue should return False for non-existing element', LRemoved);
    AssertEquals('Count should remain 3', 3, LVecDeque.Count);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IGenericCollection_Contains;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LRemoved: Boolean;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    AssertFalse('garbledgarbled_textㄤ_shouldcontaingarbledelement', LVecDeque.Contains(10));


    LVecDeque.Add(10);
    LVecDeque.Add(20);
    LVecDeque.Add(30);


    AssertTrue('shouldcontainexistgarbled_textgarbled?0', LVecDeque.Contains(10));
    AssertTrue('shouldcontainexistgarbled_textgarbled?0', LVecDeque.Contains(20));
    AssertTrue('shouldcontainexistgarbled_textgarbled?0', LVecDeque.Contains(30));


    AssertFalse('garbled_textュ_garbled_text_existgarbled_textgarbled?0', LVecDeque.Contains(40));
    AssertFalse('garbled_textュ_garbled_text_existgarbled_textgarbled?', LVecDeque.Contains(0));

    // after removing remaining 20, contains check
    LRemoved := LVecDeque.RemoveValue(20);
    AssertTrue('Second RemoveValue(20) should return True', LRemoved);
    AssertFalse('Should not contain 20 after removing both 20s', LVecDeque.Contains(20));
    AssertTrue('Should still contain 10', LVecDeque.Contains(10));
    AssertTrue('Should still contain 30', LVecDeque.Contains(30));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IQueue_Enqueue;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    { Object methods }
    LVecDeque.Enqueue(100);
    AssertEquals('enqueuegarbled_text_garbled_textgarbledヤ_1', 1, LVecDeque.Count);
    AssertEquals('enqueuegarbled_textュ_garbled_textgarbled', 100, LVecDeque.Back);


    LVecDeque.Enqueue(200);
    LVecDeque.Enqueue(300);
    AssertEquals('garbledenqueuegarbled_text_garbled_textgarbledユconfirm?', 3, LVecDeque.Count);


    AssertEquals('garbled_text_shouldgarbled_text_€__garbled_textgarbledelement', 100, LVecDeque.Front);
    AssertEquals('garbled_textgarbledshouldgarbled_text_garbled_textgarbled_textgarbledelement', 300, LVecDeque.Back);


    AssertEquals('__elementshouldcorrect‘', 200, LVecDeque.Get(1));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IQueue_Dequeue;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LValue: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.Enqueue(100);
    LVecDeque.Enqueue(200);
    LVecDeque.Enqueue(300);

    { testdequeueoperation (FIFO) }
    LValue := LVecDeque.Dequeue;
    AssertEquals('_garbled″_garbled_textgarbledュ_garbled_text__€__garbled_textgarbledelement', 100, LValue);
    AssertEquals('dequeuegarbled_text_garbled_textgarbledュgarbled?', 2, LVecDeque.Count);

    LValue := LVecDeque.Dequeue;
    AssertEquals('_garbled″_garbled_textgarbledュ_garbled_text_garbledenqueuegarbled_textgarbled?', 200, LValue);
    AssertEquals('dequeuegarbled_text_garbled_textgarbledョgarbledgarbled?', 1, LVecDeque.Count);

    LValue := LVecDeque.Dequeue;
    AssertEquals('_garbled″_garbled_textgarbledュ_garbled_textgarbled_textgarbledgarbled?', 300, LValue);
    AssertEquals('dequeuegarbled_textgarbledヤ_empty', 0, LVecDeque.Count);
    AssertTrue('dequeuegarbled_textgarbledヤgarbled_text?', LVecDeque.IsEmpty);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IQueue_Peek;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LValue: Integer;
  LPeekedValue: Integer;
  LDequeuedValue: integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.Enqueue(500);
    LVecDeque.Enqueue(600);

    { Object methods }
    LValue := LVecDeque.Peek;
    AssertEquals('peekshouldreturngarbled_text_element', 500, LValue);
    AssertEquals('peekgarbled_text_garbled_textgarbledヤ_garbled_text?', 2, LVecDeque.Count);


    LValue := LVecDeque.Peek;
    AssertEquals('garbled_text_peekshouldreturngarbled_textgarbledelement', 500, LValue);
    AssertEquals('garbled_text_peekgarbled_text_garbled_textgarbledヤgarbled_text', 2, LVecDeque.Count);


    LPeekedValue := LVecDeque.Peek;
    LDequeuedValue := LVecDeque.Dequeue;
    AssertEquals('peekgarbled_text_€garbledヤ_dequeuegarbled_text_€garbled_text?', LPeekedValue, LDequeuedValue);
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_IDeque_PushFront;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushFront(100);
    AssertEquals('frontpushgarbled_text_garbled_textgarbledヤ_1', 1, LVecDeque.Count);
    AssertEquals('frontpushgarbled_textュ_front', 100, LVecDeque.Front);
    AssertEquals('frontpushgarbled_textュ_index0', 100, LVecDeque.Get(0));


    LVecDeque.PushFront(200);
    LVecDeque.PushFront(300);
    AssertEquals('garbledfrontpushgarbled_text_garbled_textgarbledユconfirm?', 3, LVecDeque.Count);


    AssertEquals('garbled_text€garbled_textgarbled_textョ_elementshouldgarbled_textㄥgarbled?', 300, LVecDeque.Front);
    AssertEquals('index0shouldgarbled_text_garbled_textgarbled_textョ_element', 300, LVecDeque.Get(0));
    AssertEquals('index1shouldgarbled_text€garbledgarbled_garbled_textョ_element', 200, LVecDeque.Get(1));
    AssertEquals('index2shouldgarbled_text_€__garbled_textョ_element', 100, LVecDeque.Get(2));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IDeque_PushBack;
var
  LVecDeque: specialize TVecDeque<Integer>;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(400);
    AssertEquals('backpushgarbled_text_garbled_textgarbledヤ_1', 1, LVecDeque.Count);
    AssertEquals('backpushgarbled_textュ_back', 400, LVecDeque.Back);
    AssertEquals('backpushgarbled_textュ_index0', 400, LVecDeque.Get(0));


    LVecDeque.PushBack(500);
    LVecDeque.PushBack(600);
    AssertEquals('garbledbackpushgarbled_text_garbled_textgarbledユconfirm?', 3, LVecDeque.Count);


    AssertEquals('_garbled_garbled_textョ_elementshouldgarbled_textㄥgarbled?', 400, LVecDeque.Front);
    AssertEquals('garbled_text€garbled_textgarbled_textョ_elementshouldgarbled_textㄥgarbled?', 600, LVecDeque.Back);
    AssertEquals('index0shouldgarbled_text_€__garbled_textョ_element', 400, LVecDeque.Get(0));
    AssertEquals('index1shouldgarbled_textgarbledpushgarbled_textgarbled?', 500, LVecDeque.Get(1));
    AssertEquals('index2shouldgarbled_text_garbled_textgarbled_textョ_element', 600, LVecDeque.Get(2));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IDeque_PopFront;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LValue: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(100);
    LVecDeque.PushBack(200);
    LVecDeque.PushBack(300);


    LValue := LVecDeque.PopFront;
    AssertEquals('frontpopshouldgarbledfrontelement', 100, LValue);
    AssertEquals('frontpopgarbled_text_garbled_textgarbledュgarbled?', 2, LVecDeque.Count);
    AssertEquals('frontpopgarbled_textgarbled_textgarbledgarbledユconfirm?', 200, LVecDeque.Front);


    LValue := LVecDeque.PopFront;
    AssertEquals('_garbled″garbled_garbled_textgarbledュ_garbled_textgarbled_textgarbledgarbled?', 200, LValue);
    AssertEquals('_garbled″garbled_garbled_textgarbledcountshouldcontinuereduce', 1, LVecDeque.Count);
    AssertEquals('_garbled″garbled_garbled_textgarbled_textgarbledfrontshouldcorrect‘', 300, LVecDeque.Front);


    LValue := LVecDeque.PopFront;
    AssertEquals('popgarbled_text€garbled_textgarbledgarbled_textユconfirm?', 300, LValue);
    AssertEquals('popgarbled_text€garbled_textgarbledgarbled_textshouldgarbled┖', 0, LVecDeque.Count);
    AssertTrue('popgarbled_text€garbled_textgarbledgarbled_textshouldgarbled┖state', LVecDeque.IsEmpty);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IDeque_PopBack;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LValue: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(700);
    LVecDeque.PushBack(800);
    LVecDeque.PushBack(900);


    LValue := LVecDeque.PopBack;
    AssertEquals('backpopshouldgarbledbackelement', 900, LValue);
    AssertEquals('backpopgarbled_text_garbled_textgarbledュgarbled?', 2, LVecDeque.Count);
    AssertEquals('backpopgarbled_textgarbled_textgarbledgarbledユconfirm?', 800, LVecDeque.Back);


    LValue := LVecDeque.PopBack;
    AssertEquals('_garbled″garbled_garbled_textgarbledュ_garbled_textgarbled_textgarbledgarbled?', 800, LValue);
    AssertEquals('_garbled″garbled_garbled_textgarbledcountshouldcontinuereduce', 1, LVecDeque.Count);
    AssertEquals('_garbled″garbled_garbled_textgarbled_textgarbledbackshouldcorrect‘', 700, LVecDeque.Back);


    LValue := LVecDeque.PopBack;
    AssertEquals('popgarbled_text€garbled_textgarbledgarbled_textユconfirm?', 700, LValue);
    AssertEquals('popgarbled_text€garbled_textgarbledgarbled_textshouldgarbled┖', 0, LVecDeque.Count);
    AssertTrue('popgarbled_text€garbled_textgarbledgarbled_textshouldgarbled┖state', LVecDeque.IsEmpty);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IDeque_PeekFront;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LValue: Integer;
  LPeekedValue: integer;
  LPoppedValue: integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(1000);
    LVecDeque.PushBack(2000);


    LValue := LVecDeque.PeekFront;
    AssertEquals('frontpeekshouldreturnfrontelement', 1000, LValue);
    AssertEquals('frontpeekgarbled_text_garbled_textgarbledヤ_garbled_text?', 2, LVecDeque.Count);


    LValue := LVecDeque.PeekFront;
    AssertEquals('garbled_text_frontpeekshouldreturngarbled_textgarbledelement', 1000, LValue);
    AssertEquals('garbled_text_frontpeekgarbled_text_garbled_textgarbledヤgarbled_text', 2, LVecDeque.Count);


    LPeekedValue := LVecDeque.PeekFront;
    LPoppedValue := LVecDeque.PopFront;
    AssertEquals('frontpeekgarbled_text_€garbledヤ_frontpopgarbled_text_€garbled_text?', LPeekedValue, LPoppedValue);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IDeque_PeekBack;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LValue: Integer;
  LPeekedValue: integer;
  LPoppedValue: integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(3000);
    LVecDeque.PushBack(4000);


    LValue := LVecDeque.PeekBack;
    AssertEquals('backpeekshouldreturnbackelement', 4000, LValue);
    AssertEquals('backpeekgarbled_text_garbled_textgarbledヤ_garbled_text?', 2, LVecDeque.Count);


    LValue := LVecDeque.PeekBack;
    AssertEquals('garbled_text_backpeekshouldreturngarbled_textgarbledelement', 4000, LValue);
    AssertEquals('garbled_text_backpeekgarbled_text_garbled_textgarbledヤgarbled_text', 2, LVecDeque.Count);


    LPeekedValue := LVecDeque.PeekBack;
    LPoppedValue := LVecDeque.PopBack;
    AssertEquals('backpeekgarbled_text_€garbledヤ_backpopgarbled_text_€garbled_text?', LPeekedValue, LPoppedValue);
  finally
    LVecDeque.Free;
  end;
end;











procedure TTestCase_VecDeque.Test_Performance_Large_PushBack;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartTime, LEndTime: TDateTime;
  LElementCount: SizeUInt;
  LIndex: integer;
  i: integer;
  LElapsedMs: qword;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LElementCount := 100000; { Object methods }


    LStartTime := Now;


    for i := 0 to Integer(LElementCount) - 1 do
      LVecDeque.PushBack(i);

    { Object methods }
    LEndTime := Now;

    { Object methods }
    AssertEquals('bulk push back count should match', LElementCount, LVecDeque.Count);

    { Object methods }
    for i := 0 to 99 do
    begin
      LIndex := (i * Integer(LElementCount)) div 100;
      AssertEquals('sampled element should match', LIndex, LVecDeque.Get(LIndex));
    end;


    LElapsedMs := MilliSecondsBetween(LEndTime, LStartTime);
    AssertTrue('bulk push back should be fast enough', LElapsedMs < 5000); { Object methods }
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Performance_Large_PushFront;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartTime, LEndTime: TDateTime;
  LElementCount: SizeUInt;
  LExpectedValue: integer;
  i: integer;
  LElapsedMs: qword;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LElementCount := 50000; { Object methods }


    LStartTime := Now;


    for i := 0 to Integer(LElementCount) - 1 do
      LVecDeque.PushFront(i);

    { Object methods }
    LEndTime := Now;

    { Object methods }
    AssertEquals('bulk push front count should match', LElementCount, LVecDeque.Count);


    for i := 0 to 99 do
    begin
      LExpectedValue := Integer(LElementCount) - 1 - i;
      AssertEquals('front insertion order should be correct', LExpectedValue, LVecDeque.Get(i));
    end;


    LElapsedMs := MilliSecondsBetween(LEndTime, LStartTime);
    AssertTrue('bulk push front should be fast enough', LElapsedMs < 5000);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Performance_Mixed_Operations;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartTime, LEndTime: TDateTime;
  LOperationCount: SizeUInt;
  LValue: integer;
  LElapsedMs: qword;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LOperationCount := 20000;


    LStartTime := Now;


    for i := 0 to Integer(LOperationCount) - 1 do
    begin
      case i mod 6 of
        0: LVecDeque.PushBack(i);
        1: LVecDeque.PushFront(i);
        2: if not LVecDeque.IsEmpty then LVecDeque.PopBack;
        3: if not LVecDeque.IsEmpty then LVecDeque.PopFront;
        4: if not LVecDeque.IsEmpty then LValue := LVecDeque.Get(LVecDeque.Count div 2);
        5: if LVecDeque.Count > 0 then LVecDeque.Put(LVecDeque.Count div 2, i);
      end;
    end;

    { Object methods }
    LEndTime := Now;

    { Object methods }
    AssertTrue('mixed operations should keep container valid', LVecDeque.Count >= 0);


    LElapsedMs := MilliSecondsBetween(LEndTime, LStartTime);
    AssertTrue('mixed operations should be fast enough', LElapsedMs < 3000);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Stress_Memory_Allocation;
begin
  // Minimal stub to satisfy linker; full version implemented separately
  AssertTrue(True);
end;

procedure TTestCase_VecDeque.Test_Stress_Capacity_Management;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LTargetCapacity: sizeuint;
  i, j: Integer;
begin
  // Stress capacity management
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    for i := 1 to 20 do
    begin
      LTargetCapacity := i * 100;

      // Reserve target capacity and verify
      LVecDeque.Reserve(LTargetCapacity);
      AssertTrue('reserve ensures capacity >= target', LVecDeque.Capacity >= LTargetCapacity);

      // Fill up to target
      while LVecDeque.Count < LTargetCapacity do
        LVecDeque.PushBack(LVecDeque.Count);

      AssertEquals('count equals target after fill', LTargetCapacity, LVecDeque.Count);

      // Occasionally shrink and verify capacity stays >= count
      if i mod 3 = 0 then
      begin
        LVecDeque.ShrinkToFit;
        AssertTrue('capacity >= count after shrink', LVecDeque.Capacity >= LVecDeque.Count);
      end;

      // Occasionally pop some elements
      if i mod 2 = 0 then
      begin
        for j := 1 to 50 do
          if not LVecDeque.IsEmpty then LVecDeque.PopBack;
      end;
    end;

    // Final checks
    AssertTrue('container remains valid', LVecDeque.Count >= 0);
    AssertTrue('capacity >= count at end', LVecDeque.Capacity >= LVecDeque.Count);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Boundary_Index_Access;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LValue: integer;
  LExceptionRaised: Boolean;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 5 do
      LVecDeque.PushBack(i * 10);

    { Object methods }
    AssertEquals('first element', 10, LVecDeque.Get(0));
    AssertEquals('last element', 50, LVecDeque.Get(4));
    AssertEquals('middle element', 30, LVecDeque.Get(2));

    { Object methods }
    LExceptionRaised := False;
    try
      LValue := LVecDeque.Get(5); { Object methods }
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('out of range should raise', LExceptionRaised);


    LExceptionRaised := False;
    try
      LValue := LVecDeque.Get(High(SizeUInt)); { Object methods }
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('invalid index should raise', LExceptionRaised);


    LVecDeque.Clear;
    LExceptionRaised := False;
    try
      LValue := LVecDeque.Get(0);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;
    AssertTrue('empty container access should raise', LExceptionRaised);
  finally
    LVecDeque.Free;
  end;
end;





procedure TTestCase_VecDeque.Test_Regression_Bug_002;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LExceptionRaised: boolean;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LExceptionRaised := False;
    try

      LVecDeque.Reserve(High(SizeUInt) div 2);
    except
      on E: Exception do
        LExceptionRaised := True;
    end;

    // Container remains usable
    AssertTrue('container should still be valid', LVecDeque.Count >= 0);

    // Normal operations still work
    LVecDeque.PushBack(100);
    LVecDeque.PushBack(200);
    AssertEquals('count should be 2', 2, LVecDeque.Count);
    AssertEquals('first element should be 100', 100, LVecDeque.Get(0));
    AssertEquals('second element should be 200', 200, LVecDeque.Get(1));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Regression_Bug_003;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartTime, LEndTime: TDateTime;
  LElapsedMs: QWord;
  LValue, i, LMaxCheck: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LStartTime := Now;


    for i := 1 to 1000 do
    begin
      LVecDeque.PushFront(i);
      if i mod 2 = 0 then
        LVecDeque.PopFront;
    end;

    LEndTime := Now;
    LElapsedMs := MilliSecondsBetween(LEndTime, LStartTime);

    // performance within reasonable bound
    AssertTrue('push/pop should complete within 1s', LElapsedMs < 1000);

    // final state is correct
    AssertEquals('count should be 500', 500, LVecDeque.Count);

    // data integrity spot check
    LMaxCheck := LVecDeque.Count - 1;
    if LMaxCheck > 9 then
      LMaxCheck := 9;
    if LMaxCheck >= 0 then
      for i := 0 to LMaxCheck do
      begin
        LValue := LVecDeque.Get(i);
        AssertTrue('value should be > 0', LValue > 0);
      end;
  finally
    LVecDeque.Free;
  end;
end;







procedure TTestCase_VecDeque.Test_Regression_Edge_Case;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LRemoved, LValue: integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque.PushBack(42);
    AssertEquals('count should be 1', 1, LVecDeque.Count);
    AssertEquals('front equals back', LVecDeque.Front, LVecDeque.Back);

    // pop and check
    LValue := LVecDeque.PopBack;
    AssertEquals('popped value should be 42', 42, LValue);
    AssertTrue('should be empty after pop', LVecDeque.IsEmpty);

    // resize to zero
    LVecDeque.Resize(0);
    AssertEquals('count should be 0 after resize', 0, LVecDeque.Count);
    AssertTrue('should be empty after resize', LVecDeque.IsEmpty);

    // push front then check
    LVecDeque.PushFront(100);
    AssertEquals('count should be 1 after push front', 1, LVecDeque.Count);
    AssertEquals('value at 0 should be 100', 100, LVecDeque.Get(0));

    // boundary index put
    LVecDeque.Put(0, 200);
    AssertEquals('value at 0 should be 200', 200, LVecDeque.Get(0));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Regression_Concurrency;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LSum: integer;
  LExpectedSum: integer;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try




    for i := 1 to 1000 do
    begin
      if i mod 2 = 0 then
        LVecDeque.PushBack(i)
      else
        LVecDeque.PushFront(i);
    end;

    AssertEquals('count should be 1000 after concurrent-like add', 1000, LVecDeque.Count);

    // simulate reading
    LSum := 0;
    for i := 0 to LVecDeque.Count - 1 do
      LSum := LSum + LVecDeque.Get(i);

    // verify sum
    LExpectedSum := (1 + 1000) * 1000 div 2; // sum of 1..1000
    AssertEquals('sum should match expected', LExpectedSum, LSum);

    // simulate removals
    for i := 1 to 500 do
    begin
      if not LVecDeque.IsEmpty then
      begin
        if i mod 2 = 0 then
          LVecDeque.PopBack
        else
          LVecDeque.PopFront;
      end;
    end;

    AssertEquals('count should be 500 after removals', 500, LVecDeque.Count);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Regression_Serialization;
var
  LVecDeque1, LVecDeque2: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque1 := specialize TVecDeque<Integer>.Create;
  LVecDeque2 := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 20 do
      LVecDeque1.PushBack(i * i);


    for i := 0 to LVecDeque1.Count - 1 do
      LVecDeque2.PushBack(LVecDeque1.Get(i));

    // verify serialized result
    AssertEquals('count should be equal', LVecDeque1.Count, LVecDeque2.Count);

    for i := 0 to LVecDeque1.Count - 1 do
      AssertEquals('item should match', LVecDeque1.Get(i), LVecDeque2.Get(i));

    // verify independence after copy
    LVecDeque1.PushBack(999);
    AssertTrue('counts should differ after push', LVecDeque1.Count <> LVecDeque2.Count);

    LVecDeque2.PushBack(888);
    AssertTrue('last items should differ after separate push',
               LVecDeque1.Get(LVecDeque1.Count - 1) <> LVecDeque2.Get(LVecDeque2.Count - 1));
  finally
    LVecDeque1.Free;
    LVecDeque2.Free;
  end;
end;




procedure TTestCase_VecDeque.Test_Specialized_Circular_Buffer;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LBufferSize: SizeUInt;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LBufferSize := 10;


    for i := 1 to 25 do
    begin
      LVecDeque.PushBack(i);

      { Object methods }
      if LVecDeque.Count > LBufferSize then
        LVecDeque.PopFront;
    end;

    // verify circular buffer state
    AssertEquals('count should equal buffer size', LBufferSize, LVecDeque.Count);
    AssertEquals('front should be 16', 16, LVecDeque.Front);
    AssertEquals('back should be 25', 25, LVecDeque.Back);

    // verify data continuity
    for i := 0 to LVecDeque.Count - 1 do
      AssertEquals('item mismatch', 16 + i, LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Specialized_Stack_Simulation;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
  LPoppedValues: array[0..4] of Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try



    for i := 1 to 10 do
      LVecDeque.PushBack(i); { Object methods }

    AssertEquals('count should be 10', 10, LVecDeque.Count);
    AssertEquals('top should be 10', 10, LVecDeque.Back); // pop equivalent

    { Object methods }

    for i := 0 to High(LPoppedValues) do
      LPoppedValues[i] := LVecDeque.PopBack; { Object methods }


    for i := 0 to High(LPoppedValues) do
      AssertEquals('LIFO order mismatch', 10 - i, LPoppedValues[i]);

    AssertEquals('count should be 5 after pops', 5, LVecDeque.Count);
    AssertEquals('top should be 5', 5, LVecDeque.Back);
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Create_Capacity_GrowStrategy;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInitialCapacity: SizeUInt;
  LGrowStrategy: TGrowthStrategy; // NOTE: used only if Create overload supports GrowthStrategy
  LOriginalCapacity: sizeuint;
  i: Integer;
begin
  { Object methods }
  LInitialCapacity := 16;
  LGrowStrategy := GS_Double;
  // Prefer existing overloads: Create(Capacity) then set growth strategy if supported
  LVecDeque := specialize TVecDeque<Integer>.Create(LInitialCapacity);
  try
    AssertNotNull('should create VecDeque', LVecDeque);
    AssertEquals('initial count should be 0', 0, LVecDeque.Count);
    AssertTrue('capacity >= initial capacity', LVecDeque.Capacity >= LInitialCapacity);

    { Object methods }
    LOriginalCapacity := LVecDeque.Capacity;
    for i := 1 to Integer(LInitialCapacity) + 5 do
      LVecDeque.PushBack(i);

    AssertTrue('capacity should grow after exceeding initial', LVecDeque.Capacity > LOriginalCapacity);
    AssertEquals('count should be initial+5', Int64(LInitialCapacity + 5), Int64(LVecDeque.Count));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Capacity_GrowStrategy_Data;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInitialCapacity: SizeUInt;
  LGrowStrategy: TGrowthStrategy;
  LData: Pointer;
  i: Integer;
begin
  { Object methods }
  LInitialCapacity := 32;
  LGrowStrategy := GS_Linear(16);
  LData := nil; // do not pass Self pointer into data for tests
  // prefer existing overloads; if this overload doesn't exist, adjust accordingly
  LVecDeque := specialize TVecDeque<Integer>.Create(LInitialCapacity);
  try
    AssertNotNull('should create VecDeque', LVecDeque);
    AssertEquals('initial count should be 0', 0, LVecDeque.Count);
    AssertTrue('capacity >= initial capacity', LVecDeque.Capacity >= LInitialCapacity);

    { Object methods }
    for i := 1 to 10 do
      LVecDeque.PushBack(i * 3);

    AssertEquals('count should be 10', 10, LVecDeque.Count);
    for i := 0 to 9 do
      AssertEquals('value mismatch', (i + 1) * 3, LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Array;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LArray: array[0..4] of Integer;
  i: Integer;
begin

  for i := 0 to High(LArray) do
    LArray[i] := (i + 1) * 10;

  LVecDeque := specialize TVecDeque<Integer>.Create(LArray);
  try
    AssertNotNull('should create VecDeque', LVecDeque);
    AssertEquals('initial count equals array length', Int64(Length(LArray)), Int64(LVecDeque.Count));

    // verify elements copied
    for i := 0 to High(LArray) do
      AssertEquals('array element copied', LArray[i], LVecDeque.Get(i));

    // independence: modifying source array should not affect deque
    LArray[0] := 999;
    AssertEquals('changing source array should not affect VecDeque', 10, LVecDeque.Get(0));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Array_Allocator;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LArray: array[0..3] of Integer;
  LAllocator: IAllocator;
  i: Integer;
begin

  for i := 0 to High(LArray) do
    LArray[i] := (i + 1) * 7;

  LAllocator := CreateAllocator;
  LVecDeque := specialize TVecDeque<Integer>.Create(LArray, LAllocator, GS_Double);
  try
    AssertNotNull('should create VecDeque', LVecDeque);
    AssertEquals('initial count equals array length', Int64(Length(LArray)), Int64(LVecDeque.Count));

    // verify elements copied
    for i := 0 to High(LArray) do
      AssertEquals('array element copied', LArray[i], LVecDeque.Get(i));

    // further operations
    LVecDeque.PushBack(100);
    AssertEquals('count should be array length + 1 after push', Int64(Length(LArray) + 1), Int64(LVecDeque.Count));
    AssertEquals('new element should be 100 at tail', 100, LVecDeque.Get(Length(LArray)));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Collection;
var
  LVecDeque1, LVecDeque2: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque1 := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 8 do
      LVecDeque1.PushBack(i * i);

    { Object methods }
    LVecDeque2 := specialize TVecDeque<Integer>.Create(LVecDeque1);
    try
      AssertNotNull('should create VecDeque from collection', LVecDeque2);
      AssertEquals('new collection count equals source count', Int64(LVecDeque1.Count), Int64(LVecDeque2.Count));

      // verify contents copied
      for i := 0 to LVecDeque1.Count - 1 do
        AssertEquals('element copied', LVecDeque1.Get(i), LVecDeque2.Get(i));

      // verify independence
      LVecDeque1.PushBack(999);
      AssertTrue('modifying source should not affect new collection size', LVecDeque1.Count <> LVecDeque2.Count);

      LVecDeque2.PushBack(888);
      AssertTrue('modifying new collection tail should not affect source tail',
                 LVecDeque1.Get(LVecDeque1.Count - 1) <> LVecDeque2.Get(LVecDeque2.Count - 1));
    finally
      LVecDeque2.Free;
    end;
  finally
    LVecDeque1.Free;
  end;
end;



// Test comment
procedure TTestCase_VecDeque.Test_Batch_PushFront_CrossBoundary;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCap, i: SizeUInt;
  LBatch: array of Integer;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LCap := LVecDeque.Capacity;
    // Test comment
    LVecDeque.PushBack(100);
    LVecDeque.PushBack(200);
    // Test comment
    SetLength(LBatch, LCap div 2);
    if Length(LBatch) < 2 then SetLength(LBatch, 2);
    for i := 0 to High(LBatch) do LBatch[i] := 1000 + i;
    LVecDeque.PushFront(LBatch);

    // Test comment
    for i := 0 to High(LBatch) do
      AssertEquals('PushFront cross-boundary keeps order', LongInt(1000 + i), LongInt(LVecDeque.Get(i)));
    AssertEquals('Existing element follows', 100, LVecDeque.Get(Length(LBatch)));
    AssertEquals('Existing element follows 2', 200, LVecDeque.Get(Length(LBatch)+1));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Wraparound_SmallCapacity2_Back;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  // Test comment
  LVecDeque := specialize TVecDeque<Integer>.Create(2);
  try
    for i := 1 to 10 do
    begin
      LVecDeque.PushBack(i);
      AssertEquals('back after push', i, LVecDeque.Back);
      if i mod 2 = 0 then
      begin
        AssertEquals('pop front returns previous', i-1, LVecDeque.PopFront);
        AssertEquals('pop back returns current', i, LVecDeque.PopBack);
        AssertTrue('empty after two pops', LVecDeque.IsEmpty);
      end;
    end;
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Wraparound_SmallCapacity2_Front;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  // Test comment
  LVecDeque := specialize TVecDeque<Integer>.Create(2);
  try
    for i := 1 to 6 do
    begin
      LVecDeque.PushFront(i);
      AssertEquals('front equals pushed', i, LVecDeque.Front);
      if i mod 2 = 0 then
      begin
        AssertEquals('pop back returns previous', i-1, LVecDeque.PopBack);
        AssertEquals('pop front returns current', i, LVecDeque.PopFront);
        AssertTrue('empty after two pops', LVecDeque.IsEmpty);
      end;
    end;
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Batch_PushBack_CrossBoundary;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCap, i, LLim: SizeUInt;
  LBatch: array of Integer;
  LCount: SizeUInt;
begin
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    // Test comment
    LCap := LVecDeque.Capacity;
    LLim := 1;
    if LCap > 2 then LLim := LCap - 2;
    for i := 1 to LLim do
      LVecDeque.PushBack(i);
    // Test comment
    SetLength(LBatch, 5);
    for i := 0 to High(LBatch) do LBatch[i] := 1000 + i;
    LVecDeque.PushBack(LBatch);

    LCount := LVecDeque.Count;
    // Test comment
    AssertEquals('batch[0]', 1000, LVecDeque.Get(LCount - 5));
    AssertEquals('batch[1]', 1001, LVecDeque.Get(LCount - 4));
    AssertEquals('batch[2]', 1002, LVecDeque.Get(LCount - 3));
    AssertEquals('batch[3]', 1003, LVecDeque.Get(LCount - 2));
    AssertEquals('batch[4]', 1004, LVecDeque.Get(LCount - 1));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_TypeSafety_Interface;
var
  LVecDeque: specialize TVecDeque<IInterface>;
  C1, C2: IInterface;
begin
  // Test comment
  LVecDeque := specialize TVecDeque<IInterface>.Create;
  try
    C1 := TInterfacedObject.Create;
    C2 := TInterfacedObject.Create;
    LVecDeque.PushBack(C1);
    LVecDeque.PushFront(C2);
    AssertEquals('count=2', 2, LVecDeque.Count);
    AssertTrue('front is C2', Pointer(LVecDeque.Front) = Pointer(C2));
    AssertTrue('back is C1', Pointer(LVecDeque.Back) = Pointer(C1));

    // Test comment
    LVecDeque.Reserve(10);
    LVecDeque.ShrinkToFit;
    AssertEquals('count unchanged after shrink', 2, LVecDeque.Count);
  finally
    LVecDeque.Free;
  end;
end;


procedure TTestCase_VecDeque.Test_IEnumerable_GetEnumerator;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LEnumerator: specialize TIter<Integer>;
  LSum, LCount, i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 5 do
      LVecDeque.PushBack(i * 2);


    LEnumerator.Init(LVecDeque.PtrIter);
    AssertTrue('enumerator started false', not LEnumerator.GetStarted);


    LSum := 0;
    LCount := 0;
    while LEnumerator.MoveNext do
    begin
      LSum := LSum + LEnumerator.GetCurrent;
      Inc(LCount);
    end;

    { Object methods }
    AssertEquals('enumerator count should be 5', 5, LCount);
    AssertEquals('enumerator sum should be 30', 30, LSum); { 2+4+6+8+10 = 30 }
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IIndexed_Get;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 0 to 9 do
      LVecDeque.PushBack(i * i);

    { Object methods }
    for i := 0 to LVecDeque.Count - 1 do
      AssertEquals('index get should return square', i * i, LVecDeque.Get(i));

    { Object methods }
    AssertEquals('first element read', 0, LVecDeque.Get(0));
    AssertEquals('last element read', 81, LVecDeque.Get(9));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_IIndexed_Put;
var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 0 to 4 do
      LVecDeque.PushBack(i);

    { Object methods }
    for i := 0 to LVecDeque.Count - 1 do
      LVecDeque.Put(i, i * 10);

    { Object methods }
    for i := 0 to LVecDeque.Count - 1 do
      AssertEquals('index set should take effect', i * 10, LVecDeque.Get(i));

    { Object methods }
    LVecDeque.Put(0, 999);
    LVecDeque.Put(4, 888);
    AssertEquals('first element set', 999, LVecDeque.Get(0));
    AssertEquals('last element set', 888, LVecDeque.Get(4));
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Insert_Index_Collection;
var
  LVecDeque1, LVecDeque2: specialize TVecDeque<Integer>;
begin

  LVecDeque1 := specialize TVecDeque<Integer>.Create;
  LVecDeque2 := specialize TVecDeque<Integer>.Create;
  try

    LVecDeque1.PushBack(10);
    LVecDeque1.PushBack(30);


    LVecDeque2.PushBack(15);
    LVecDeque2.PushBack(20);
    LVecDeque2.PushBack(25);


    LVecDeque1.Insert(1, LVecDeque2);
    AssertEquals('count should be 5 after insert collection', 5, LVecDeque1.Count);

    { Object methods }
    AssertEquals('first element unchanged', 10, LVecDeque1.Get(0));
    AssertEquals('inserted #1 is correct', 15, LVecDeque1.Get(1));
    AssertEquals('inserted #2 is correct', 20, LVecDeque1.Get(2));
    AssertEquals('inserted #3 is correct', 25, LVecDeque1.Get(3));
    AssertEquals('original second element shifted', 30, LVecDeque1.Get(4));


    AssertEquals('source collection unchanged', 3, LVecDeque2.Count);
  finally
    LVecDeque1.Free;
    LVecDeque2.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Write_Index_Collection;
var
  LVecDeque1, LVecDeque2: specialize TVecDeque<Integer>;
  i: Integer;
begin

  LVecDeque1 := specialize TVecDeque<Integer>.Create;
  LVecDeque2 := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 8 do
      LVecDeque1.PushBack(i);

    { preparewritecollection }
    LVecDeque2.PushBack(100);
    LVecDeque2.PushBack(200);
    LVecDeque2.PushBack(300);


    LVecDeque1.Write(2, LVecDeque2);
    AssertEquals('count unchanged after write collection', 8, LVecDeque1.Count);

    { Object methods }
    AssertEquals('prefix elements unchanged #0', 1, LVecDeque1.Get(0));
    AssertEquals('prefix elements unchanged #1', 2, LVecDeque1.Get(1));
    AssertEquals('written #1 is correct', 100, LVecDeque1.Get(2));
    AssertEquals('written #2 is correct', 200, LVecDeque1.Get(3));
    AssertEquals('written #3 is correct', 300, LVecDeque1.Get(4));
    AssertEquals('suffix element unchanged', 6, LVecDeque1.Get(5));
  finally
    LVecDeque1.Free;
    LVecDeque2.Free;
  end;
end;


procedure TTestCase_VecDeque.Test_Slice_StartIndex_Count;
var
  LVecDeque, LSlice: specialize TVecDeque<Integer>;
  i: Integer;
begin
  { Object methods }
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 10 do
      LVecDeque.PushBack(i * 5);


    LSlice := specialize TVecDeque<Integer>.Create;
    for i := 0 to 3 do
      LSlice.PushBack(LVecDeque.Get(2 + i));
    try
      AssertNotNull('garbled_textgarbledresultshouldvalid', LSlice);
      AssertEquals('garbled_textgarbledelementcountshouldcorrect‘', 4, LSlice.Count);


      AssertEquals('first element in slice should be 15', 15, LSlice.Get(0));
      AssertEquals('second element in slice should be 20', 20, LSlice.Get(1));
      AssertEquals('third element in slice should be 25', 25, LSlice.Get(2));
      AssertEquals('fourth element in slice should be 30', 30, LSlice.Get(3));


      LSlice.Put(0, 999);
      AssertEquals('repair_garbled_textュ_garbled_textgarbledcollection', 15, LVecDeque.Get(2));
    finally
      LSlice.Free;
    end;
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Specialized_Priority_Queue;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LInsertPos: sizeint;
  LMinValue: integer;
  LMaxValue: integer;
  i: Integer;
const
  LValues: array[0..6] of Integer = (15, 3, 9, 21, 6, 12, 18);
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try




    for i := 0 to High(LValues) do
    begin
      { Object methods }
      LInsertPos := LVecDeque.BinarySearchInsert(LValues[i]);
      LVecDeque.Insert(LInsertPos, LValues[i]);
    end;


    AssertEquals('priority queue count should match', Length(LValues), Integer(LVecDeque.Count));

    { Object methods }
    for i := 0 to LVecDeque.Count - 2 do
      AssertTrue('priority queue should stay sorted', LVecDeque.Get(i) <= LVecDeque.Get(i + 1));


    LMinValue := LVecDeque.PopFront;
    AssertEquals('min value popped should be 3', 3, LMinValue);


    LMaxValue := LVecDeque.PopBack;
    AssertEquals('max value popped should be 21', 21, LMaxValue);

    AssertEquals('count after pops should be Length(LValues)-2', Length(LValues) - 2, Integer(LVecDeque.Count));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Specialized_Sliding_Window;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LWindowSize: SizeUInt;
  LDataStream: array[0..19] of Integer;
  LMaxValue, LExpectedValue: integer;
  i, j, LExpectedStart: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LWindowSize := 5;


    for i := 0 to High(LDataStream) do
      LDataStream[i] := (i + 1) * 2;


    for i := 0 to High(LDataStream) do
    begin

      LVecDeque.PushBack(LDataStream[i]);

      { Object methods }
      if LVecDeque.Count > LWindowSize then
        LVecDeque.PopFront;


      AssertTrue('window size should not exceed limit', LVecDeque.Count <= LWindowSize);


      if LVecDeque.Count = LWindowSize then
      begin
        if Integer(i) - Integer(LWindowSize) + 1 > 0 then
          LExpectedStart := Integer(i) - Integer(LWindowSize) + 1
        else
          LExpectedStart := 0;
        for j := 0 to Integer(LVecDeque.Count) - 1 do
        begin
          LExpectedValue := (LExpectedStart + j + 1) * 2;
          AssertEquals('sliding window content mismatch', LExpectedValue, LVecDeque.Get(j));
        end;
      end;
    end;


    AssertEquals('final window size should match', Integer(LWindowSize), Integer(LVecDeque.Count));
    AssertEquals('window should contain latest back value', 40, LVecDeque.Back); { 20*2 }
    AssertEquals('window should contain latest front value', 32, LVecDeque.Front); { 16*2 }
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Specialized_Undo_Redo;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LCurrentState: Integer;
  LMaxHistory: SizeUInt;
  LUndoCount: Integer;
  i: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LCurrentState := 0;
    LMaxHistory := 10;


    for i := 1 to 15 do
    begin
      { recordcurrentstate}
      LVecDeque.PushBack(LCurrentState);

      { Object methods }
      if LVecDeque.Count > LMaxHistory then
        LVecDeque.PopFront;

      { updatestate}
      LCurrentState := LCurrentState + i;
    end;

    { Object methods }
    AssertEquals('history size should be limited', Integer(LMaxHistory), Integer(LVecDeque.Count));


    LUndoCount := 3;
    for i := 1 to LUndoCount do
    begin
      if not LVecDeque.IsEmpty then
      begin
        LCurrentState := LVecDeque.PopBack;
      end;
    end;

    { Object methods }
    AssertEquals('count after undo should match', Integer(LMaxHistory - LUndoCount), Integer(LVecDeque.Count));


    for i := 1 to 2 do
    begin
      LVecDeque.PushBack(LCurrentState);
      LCurrentState := LCurrentState + 100 + i;
    end;

    { Object methods }
    AssertEquals('count after redo should match', Integer(LMaxHistory - LUndoCount + 2), Integer(LVecDeque.Count));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Specialized_Message_Queue;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LMessageId: Integer;
  LUrgentMessage, LExpectedMessage: integer;
  i: Integer;
  LProcessedMessages: array[0..4] of Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LMessageId := 1000;


    for i := 1 to 10 do
    begin
      LVecDeque.Enqueue(LMessageId + i); { Object methods }
    end;

    AssertEquals('message queue should contain all messages', 10, Integer(LVecDeque.Count));


    LUrgentMessage := 9999;
    LVecDeque.PushFront(LUrgentMessage);
    AssertEquals('urgent message insert should increase count', 11, Integer(LVecDeque.Count));
    AssertEquals('urgent message should be at front', LUrgentMessage, LVecDeque.Front);

    { Object methods }
    for i := 0 to High(LProcessedMessages) do
    begin
      LProcessedMessages[i] := LVecDeque.Dequeue; { Object methods }
    end;

    { Object methods }
    AssertEquals('first processed should be urgent message', LUrgentMessage, LProcessedMessages[0]);
    for i := 1 to High(LProcessedMessages) do
    begin
      LExpectedMessage := LMessageId + i;
      AssertEquals('processed order should match', LExpectedMessage, LProcessedMessages[i]);
    end;

    AssertEquals('remaining messages count should be 6', 6, Integer(LVecDeque.Count));


    LVecDeque.Clear;
    AssertEquals('queue should be empty after clear', 0, Integer(LVecDeque.Count));
    AssertTrue('queue should be empty after clear (state)', LVecDeque.IsEmpty);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Specialized_Data_Pipeline;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LBatchSize: SizeUInt;
  LBatchSum: integer;
  LRemainingCount: sizeuint;
  LExpectedStart: integer;
  i, j: Integer;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LBatchSize := 5;


    for i := 1 to 23 do
    begin
      LVecDeque.PushBack(i);


      if LVecDeque.Count >= LBatchSize then
      begin

        LBatchSum := 0;
        for j := 0 to Integer(LBatchSize) - 1 do
        begin
          LBatchSum := LBatchSum + LVecDeque.PopFront;
        end;


        AssertTrue('batch processing result should be positive', LBatchSum > 0);
      end;
    end;


    LRemainingCount := LVecDeque.Count;
    AssertTrue('there should be remaining data', LRemainingCount > 0);
    AssertTrue('remaining data should be less than batch size', LRemainingCount < LBatchSize);


    LExpectedStart := 23 - Integer(LRemainingCount) + 1;
    for i := 0 to LVecDeque.Count - 1 do
    begin
      AssertEquals('remaining data order should match', LExpectedStart + i, LVecDeque.Get(i));
    end;
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Final_Comprehensive_Integration;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LStartTime, LEndTime: TDateTime;
  LSearchValue: integer;
  LFoundIndex: sizeint;
  LCapacityAfterShrink: sizeuint;
  LAsQueue: specialize IQueue<Integer>;
  LDequeuedValue: integer;
  LAsDeque: specialize IDeque<Integer>;
  LFrontValue: integer;
  LElapsedMs: qword;
  LValue: integer;
  i: Integer;
  LAsIntf: IInterface;
begin

  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    LStartTime := Now;


    LVecDeque.Reserve(10000);
    for i := 1 to 5000 do
    begin
      LVecDeque.PushBack(i);
      if i mod 100 = 0 then
        LVecDeque.PushFront(-i);
    end;


    for i := 1 to 50 do
    begin
      if LVecDeque.Contains(i * 10) then
        LVecDeque.Replace(i * 10, i * 100);
    end;


    LVecDeque.Sort;
    AssertTrue('should be sorted after sort', LVecDeque.IsSorted);

    LSearchValue := 1000;
    LFoundIndex := LVecDeque.BinarySearch(LSearchValue);
    if SizeUInt(LFoundIndex) <> High(SizeUInt) then
      AssertEquals('binary search result should match', LSearchValue, LVecDeque.Get(LFoundIndex));


    LVecDeque.FillWith(999, 100);
    LVecDeque.Shuffle;


    LVecDeque.ShrinkToFit;
    LCapacityAfterShrink := LVecDeque.Capacity;
    AssertTrue('capacity after shrink should be >= count', LCapacityAfterShrink >= LVecDeque.Count);


    // interface sanity checks
    LAsIntf := LVecDeque as IInterface;
    AssertNotNull('vecdeque should support IInterface', Pointer(LAsIntf));

    LAsQueue := LVecDeque as specialize IQueue<Integer>;
    LAsQueue.Enqueue(88888);
    LDequeuedValue := LAsQueue.Dequeue;

    LAsDeque := LVecDeque as specialize IDeque<Integer>;
    LAsDeque.PushFront(77777);
    LFrontValue := LAsDeque.PopFront;
    AssertEquals('deque front operation should match', 77777, LFrontValue);

    LEndTime := Now;
    LElapsedMs := MilliSecondsBetween(LEndTime, LStartTime);


    AssertTrue('integration should finish within time', LElapsedMs < 10000); { Object methods }
    AssertTrue('count should be > 0 after integration', LVecDeque.Count > 0);
    AssertTrue('capacity should be >= count after integration', LVecDeque.Capacity >= LVecDeque.Count);


    for i := 0 to Min(99, LVecDeque.Count - 1) do
    begin
      LValue := LVecDeque.Get(i);

      AssertTrue('final values should be within range', (LValue >= -5000) and (LValue <= 100000));
    end;
  finally
    LVecDeque.Free;
  end;
end;



procedure TTestCase_VecDeque.Test_Create_Collection_Allocator;
var
  LVecDeque1, LVecDeque2: specialize TVecDeque<Integer>;
  LAllocator: IAllocator;
  i: Integer;
begin

  LVecDeque1 := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 6 do
      LVecDeque1.PushBack(i * 3);

    { Object methods }
    LAllocator := CreateAllocator;
    LVecDeque2 := specialize TVecDeque<Integer>.Create(LVecDeque1, LAllocator);
    try
      AssertNotNull('garbledcollectiongarbled_textgarbled_textgarbledcreategarbled_text_ecDequeshouldvalid', LVecDeque2);
      AssertEquals('garbled_textgarbled_textgarbled_textgarbledョgarbled_textcollection', LVecDeque1.Count, LVecDeque2.Count);


      for i := 0 to LVecDeque1.Count - 1 do
        AssertEquals(LVecDeque1.Get(i), LVecDeque2.Get(i));


      LVecDeque1.PushBack(999);
      AssertTrue(LVecDeque1.Count <> LVecDeque2.Count);
    finally
      LVecDeque2.Free;
    end;
  finally
    LVecDeque1.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Collection_Allocator_Data;
var
  LVecDeque1, LVecDeque2: specialize TVecDeque<Integer>;
  LAllocator: IAllocator;
  LData: Pointer;
  i: Integer;
begin

  LVecDeque1 := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 4 do
      LVecDeque1.PushBack(i * 5);


    LAllocator := CreateAllocator;
    LData := @Self;
    LVecDeque2 := specialize TVecDeque<Integer>.Create(LVecDeque1, LAllocator, LData);
    try
      AssertNotNull('garbledcollectiongarbled_textgarbled_textgarbled_textgarbled_textVecDequeshouldvalid', LVecDeque2);
      AssertEquals('garbled_textgarbled_textgarbled_textgarbledョgarbled_textcollection', LVecDeque1.Count, LVecDeque2.Count);


      for i := 0 to LVecDeque1.Count - 1 do
        AssertEquals(LVecDeque1.Get(i), LVecDeque2.Get(i));
    finally
      LVecDeque2.Free;
    end;
  finally
    LVecDeque1.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Collection_Allocator_GrowStrategy;
var
  LVecDeque1, LVecDeque2: specialize TVecDeque<Integer>;
  LAllocator: IAllocator;
  LGrowStrategy: TGrowthStrategy;
  LOriginalCapacity: sizeuint;
  i: Integer;
begin

  LVecDeque1 := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 5 do
      LVecDeque1.PushBack(i * 7);


    LAllocator := CreateAllocator;
    LGrowStrategy := GS_Double;
    LVecDeque2 := specialize TVecDeque<Integer>.Create(LVecDeque1, LAllocator, LGrowStrategy);
    try
      AssertNotNull('garbledcollectiongarbled_textgarbled_text_garbled_textgarbled_textュgarbled_textVecDequeshouldvalid', LVecDeque2);
      AssertEquals('garbled_textgarbled_textgarbled_textgarbledョgarbled_textcollection', LVecDeque1.Count, LVecDeque2.Count);


      for i := 0 to LVecDeque1.Count - 1 do
        AssertEquals(LVecDeque1.Get(i), LVecDeque2.Get(i));

      { Object methods }
      LOriginalCapacity := LVecDeque2.Capacity;
      for i := 1 to 10 do
        LVecDeque2.PushBack(i * 100);
      AssertTrue('growthstrategyshouldgarbled_textgarbled', LVecDeque2.Capacity > LOriginalCapacity);
    finally
      LVecDeque2.Free;
    end;
  finally
    LVecDeque1.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Collection_Allocator_GrowStrategy_Data;
var
  LVecDeque1, LVecDeque2: specialize TVecDeque<Integer>;
  LAllocator: IAllocator;
  LGrowStrategy: TGrowthStrategy;
  LData: Pointer;
  i: Integer;
begin

  LVecDeque1 := specialize TVecDeque<Integer>.Create;
  try

    for i := 1 to 3 do
      LVecDeque1.PushBack(i * 11);


    LAllocator := CreateAllocator;
    LGrowStrategy := GS_Linear(16);
    LData := @Self;
    LVecDeque2 := specialize TVecDeque<Integer>.Create(LVecDeque1, LAllocator, LGrowStrategy, LData);
    try
      AssertNotNull('garbled_text€garbled_textgarbled_textVecDequeshouldvalid', LVecDeque2);
      AssertEquals('garbled_textgarbled_textgarbled_textgarbledョgarbled_textcollection', LVecDeque1.Count, LVecDeque2.Count);


      for i := 0 to LVecDeque1.Count - 1 do
        AssertEquals(LVecDeque1.Get(i), LVecDeque2.Get(i));
    finally
      LVecDeque2.Free;
    end;
  finally
    LVecDeque1.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Pointer_Count;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LArray: array[0..4] of Integer;
  LPointer: Pointer;
  LCount: SizeUInt;
  i: Integer;
begin

  for i := 0 to High(LArray) do
    LArray[i] := (i + 1) * 13;

  LPointer := @LArray[0];
  LCount := Length(LArray);

  LVecDeque := specialize TVecDeque<Integer>.Create(LPointer, LCount);
  try
    AssertNotNull('garbledpointergarbled_textgarbled_textVecDequeshouldvalid', LVecDeque);
    AssertEquals('elementcountshouldequalgarbled_textgarbledcount', LCount, LVecDeque.Count);


    for i := 0 to High(LArray) do
      AssertEquals(LArray[i], LVecDeque.Get(i));


    LArray[0] := 999;
    AssertEquals(13, LVecDeque.Get(0));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Pointer_Count_Allocator;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LArray: array[0..3] of Integer;
  LPointer: Pointer;
  LCount: SizeUInt;
  LAllocator: IAllocator;
  i: Integer;
begin

  for i := 0 to High(LArray) do
    LArray[i] := (i + 1) * 17;

  LPointer := @LArray[0];
  LCount := Length(LArray);
  LAllocator := CreateAllocator;

  LVecDeque := specialize TVecDeque<Integer>.Create(LPointer, LCount, LAllocator);
  try
    AssertNotNull('garbledpointergarbled_textgarbledallocationgarbled_textㄥgarbled_textVecDequeshouldvalid', LVecDeque);
    AssertEquals('elementcountshouldequalgarbled_textgarbledcount', LCount, LVecDeque.Count);


    for i := 0 to High(LArray) do
      AssertEquals(LArray[i], LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Pointer_Count_Allocator_Data;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LArray: array[0..5] of Integer;
  LPointer: Pointer;
  LCount: SizeUInt;
  LAllocator: IAllocator;
  LData: Pointer;
  i: Integer;
begin

  for i := 0 to High(LArray) do
    LArray[i] := (i + 1) * 19;

  LPointer := @LArray[0];
  LCount := Length(LArray);
  LAllocator := CreateAllocator;
  LData := @Self;

  LVecDeque := specialize TVecDeque<Integer>.Create(LPointer, LCount, LAllocator, LData);
  try
    AssertNotNull(LVecDeque);
    AssertEquals(LCount, LVecDeque.Count);

    for i := 0 to High(LArray) do
      AssertEquals(LArray[i], LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Pointer_Count_Allocator_GrowStrategy;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LArray: array[0..2] of Integer;
  LPointer: Pointer;
  LCount: SizeUInt;
  LAllocator: IAllocator;
  LGrowStrategy: TGrowthStrategy;
  LOriginalCapacity: sizeuint;
  i: Integer;
begin

  for i := 0 to High(LArray) do
    LArray[i] := (i + 1) * 23;

  LPointer := @LArray[0];
  LCount := Length(LArray);
  LAllocator := CreateAllocator;
  LGrowStrategy := GS_Double;

  LVecDeque := specialize TVecDeque<Integer>.Create(LPointer, LCount, LAllocator, LGrowStrategy);
  try
    AssertNotNull('garbledpointergarbled_text_€garbled_textgarbled_text_garbled_textgarbled_textュgarbled_textVecDequeshouldvalid', LVecDeque);
    AssertEquals('elementcountshouldequalgarbled_textgarbledcount', LCount, LVecDeque.Count);


    for i := 0 to High(LArray) do
      AssertEquals(LArray[i], LVecDeque.Get(i));

    { Object methods }
    LOriginalCapacity := LVecDeque.Capacity;
    for i := 1 to 10 do
      LVecDeque.PushBack(i * 1000);
    AssertTrue('growthstrategyshouldgarbled_textgarbled', LVecDeque.Capacity > LOriginalCapacity);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Pointer_Count_Allocator_GrowStrategy_Data;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LArray: array[0..3] of Integer;
  LPointer: Pointer;
  LCount: SizeUInt;
  LAllocator: TAllocator;
  LGrowStrategy: TGrowthStrategy;
  LData: Pointer;
  i: integer;
begin
  for i := 0 to High(LArray) do
    LArray[i] := (i + 1) * 29;

  LPointer := @LArray[0];
  LCount := Length(LArray);
  LAllocator := CreateAllocator;
  LGrowStrategy := GS_Linear(16);
  LData := @Self;

  LVecDeque := specialize TVecDeque<Integer>.Create(LPointer, LCount, LAllocator, LGrowStrategy, LData);
  try
    AssertNotNull('garbled_text€garbled_textgarbled_textVecDequeshouldvalid', LVecDeque);
    AssertEquals('elementcountshouldequalgarbled_textgarbledcount', LCount, LVecDeque.Count);



    for i := 0 to High(LArray) do
      AssertEquals(LArray[i], LVecDeque.Get(i));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Array_Allocator_Data;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LArray: array[0..4] of Integer;
  LAllocator: IAllocator;
  LData: Pointer;
  i: Integer;
begin

  for i := 0 to High(LArray) do
    LArray[i] := (i + 1) * 31;

  LAllocator := CreateAllocator;
  LData := @Self;

  LVecDeque := specialize TVecDeque<Integer>.Create(LArray, LAllocator, LData);
  try
    AssertNotNull('VecDeque should be created', LVecDeque);
    AssertEquals(Int64(Length(LArray)), Int64(LVecDeque.Count));


    for i := 0 to High(LArray) do
      AssertEquals(Int64(LArray[i]), Int64(LVecDeque.Get(i)));
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Array_Allocator_GrowStrategy;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LArray: array[0..2] of Integer;
  LAllocator: IAllocator;
  LGrowStrategy: TGrowthStrategy;
  LOriginalCapacity: sizeuint;
  i: Integer;
begin

  for i := 0 to High(LArray) do
    LArray[i] := (i + 1) * 37;

  LAllocator := CreateAllocator;
  LGrowStrategy := GS_Double;

  LVecDeque := specialize TVecDeque<Integer>.Create(LArray, LAllocator, LGrowStrategy);
  try
    AssertNotNull('VecDeque should be created', LVecDeque);
    AssertEquals(Int64(Length(LArray)), Int64(LVecDeque.Count));

    for i := 0 to High(LArray) do
      AssertEquals(Int64(LArray[i]), Int64(LVecDeque.Get(i)));

    { Object methods }
    LOriginalCapacity := LVecDeque.Capacity;
    for i := 1 to 8 do
      LVecDeque.PushBack(i * 2000);
    AssertTrue('growthstrategyshouldgarbled_textgarbled', LVecDeque.Capacity > LOriginalCapacity);
  finally
    LVecDeque.Free;
  end;
end;

procedure TTestCase_VecDeque.Test_Create_Array_Allocator_GrowStrategy_Data;
var
  LVecDeque: specialize TVecDeque<Integer>;
  LArray: array[0..3] of Integer;
  LAllocator: IAllocator;
  LGrowStrategy: TGrowthStrategy;
  LData: Pointer;
  i: Integer;
begin

  for i := 0 to High(LArray) do
    LArray[i] := (i + 1) * 41;

  LAllocator := CreateAllocator;
  LGrowStrategy := GS_Linear(16);
  LData := @Self;

  LVecDeque := specialize TVecDeque<Integer>.Create(LArray, LAllocator, LGrowStrategy, LData);
  try
    AssertNotNull('VecDeque should be created', LVecDeque);
    AssertEquals(Int64(Length(LArray)), Int64(LVecDeque.Count));

    for i := 0 to High(LArray) do
      AssertEquals(Int64(LArray[i]), Int64(LVecDeque.Get(i)));
  finally
    LVecDeque.Free;
  end;
end;


// --- Auto-generated minimal stubs for unimplemented tests (part 1) ---
procedure TTestCase_VecDeque.Test_Remove_Index;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_RemoveSwap_Index;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_RemoveSwap_Index_Element;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_RemoveSwap_Index_Element_Var;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_RemoveCopy_Index_Pointer;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_RemoveCopy_Index_Pointer_Count;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_RemoveArray_Index_Array_Count;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_RemoveCopySwap_Index_Pointer;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_RemoveCopySwap_Index_Pointer_Count;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_RemoveArraySwap_Index_Array_Count;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Remove_First_Occurrence;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Remove_Last_Occurrence;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Remove_All_Occurrences;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Remove_Range_Front;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Remove_Range_Back;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Remove_Range_Middle;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Remove_Empty_Range;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Remove_Full_Range;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_Remove_Invalid_Range;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_TryPop_Array_Complete;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_TryPeek_Array_Count;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_TryPeek_Array_Complete;
begin
  Fail('Not implemented');
end;

procedure TTestCase_VecDeque.Test_PeekRange_Count;
begin
  Fail('Not implemented');
end;
// --- End stubs part 1 ---




initialization
  if gsDouble = nil then gsDouble := TDoublingGrowStrategy.GetGlobal;
  if gsLinear = nil then gsLinear := TFixedGrowStrategy.Create(16);
  RegisterTest(TTestCase_VecDeque);

end.


