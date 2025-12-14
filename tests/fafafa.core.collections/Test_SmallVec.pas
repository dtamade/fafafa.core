unit Test_SmallVec;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections.smallvec;

type
  { TSmallVec 小容量栈优化测试 }
  TTestSmallVec = class(TTestCase)
  published
    // 基本功能测试
    procedure Test_SmallVec_Init_IsEmpty;
    procedure Test_SmallVec_Push_SingleElement;
    procedure Test_SmallVec_Push_MultipleElements_WithinCapacity;
    procedure Test_SmallVec_Push_ExceedsInlineCapacity_SpillsToHeap;
    procedure Test_SmallVec_Pop_ReturnsLastElement;
    procedure Test_SmallVec_Pop_Empty_ReturnsFalse;
    
    // 索引访问测试
    procedure Test_SmallVec_Get_ValidIndex;
    procedure Test_SmallVec_Put_ValidIndex;
    procedure Test_SmallVec_GetPtr_ValidIndex;
    
    // 容量和状态测试
    procedure Test_SmallVec_Count_ReflectsElements;
    procedure Test_SmallVec_Capacity_ReturnsInlineCapacityWhenSmall;
    procedure Test_SmallVec_IsInline_TrueWhenSmall;
    procedure Test_SmallVec_IsInline_FalseAfterSpill;
    
    // Clear 测试
    procedure Test_SmallVec_Clear_ResetsCount;
    procedure Test_SmallVec_Clear_AfterSpill_ResetsToInline;
    
    // 迭代测试
    procedure Test_SmallVec_ForIn_Works;
    
    // 边界测试
    procedure Test_SmallVec_LargeInlineCapacity_Works;
    
    // ToArray 测试
    procedure Test_SmallVec_ToArray_ReturnsCorrectData;
  end;

implementation

type
  // 默认 inline 容量为 8 的 SmallVec<Integer>
  TSmallIntVec = specialize TSmallVec<Integer, 8>;
  // 大 inline 容量的 SmallVec
  TLargeInlineVec = specialize TSmallVec<Integer, 32>;

{ TTestSmallVec }

procedure TTestSmallVec.Test_SmallVec_Init_IsEmpty;
var
  V: TSmallIntVec;
begin
  V.Init;
  try
    AssertTrue('Should be empty after init', V.IsEmpty);
    AssertEquals('Count should be 0', 0, V.Count);
    AssertTrue('Should be inline when empty', V.IsInline);
  finally
    V.Done;
  end;
end;

procedure TTestSmallVec.Test_SmallVec_Push_SingleElement;
var
  V: TSmallIntVec;
begin
  V.Init;
  try
    V.Push(42);
    AssertFalse('Should not be empty', V.IsEmpty);
    AssertEquals('Count should be 1', 1, V.Count);
    AssertEquals('First element', 42, V.Get(0));
  finally
    V.Done;
  end;
end;

procedure TTestSmallVec.Test_SmallVec_Push_MultipleElements_WithinCapacity;
var
  V: TSmallIntVec;
  i: Integer;
begin
  V.Init;
  try
    // Push 8 elements (within inline capacity)
    for i := 1 to 8 do
      V.Push(i * 10);
    
    AssertEquals('Count should be 8', 8, V.Count);
    AssertTrue('Should still be inline', V.IsInline);
    
    // Verify all elements
    for i := 0 to 7 do
      AssertEquals('Element ' + IntToStr(i), (i + 1) * 10, V.Get(i));
  finally
    V.Done;
  end;
end;

procedure TTestSmallVec.Test_SmallVec_Push_ExceedsInlineCapacity_SpillsToHeap;
var
  V: TSmallIntVec;
  i: Integer;
begin
  V.Init;
  try
    // Push 9 elements (exceeds inline capacity of 8)
    for i := 1 to 9 do
      V.Push(i * 10);
    
    AssertEquals('Count should be 9', 9, V.Count);
    AssertFalse('Should have spilled to heap', V.IsInline);
    
    // Verify all elements are still correct after spill
    for i := 0 to 8 do
      AssertEquals('Element ' + IntToStr(i), (i + 1) * 10, V.Get(i));
  finally
    V.Done;
  end;
end;

procedure TTestSmallVec.Test_SmallVec_Pop_ReturnsLastElement;
var
  V: TSmallIntVec;
  Value: Integer;
begin
  V.Init;
  try
    V.Push(10);
    V.Push(20);
    V.Push(30);
    
    AssertTrue('Pop should succeed', V.Pop(Value));
    AssertEquals('Popped value', 30, Value);
    AssertEquals('Count after pop', 2, V.Count);
    
    AssertTrue('Pop should succeed', V.Pop(Value));
    AssertEquals('Popped value', 20, Value);
    AssertEquals('Count after pop', 1, V.Count);
  finally
    V.Done;
  end;
end;

procedure TTestSmallVec.Test_SmallVec_Pop_Empty_ReturnsFalse;
var
  V: TSmallIntVec;
  Value: Integer;
begin
  V.Init;
  try
    AssertFalse('Pop on empty should return false', V.Pop(Value));
  finally
    V.Done;
  end;
end;

procedure TTestSmallVec.Test_SmallVec_Get_ValidIndex;
var
  V: TSmallIntVec;
begin
  V.Init;
  try
    V.Push(100);
    V.Push(200);
    V.Push(300);
    
    AssertEquals('Get(0)', 100, V.Get(0));
    AssertEquals('Get(1)', 200, V.Get(1));
    AssertEquals('Get(2)', 300, V.Get(2));
  finally
    V.Done;
  end;
end;

procedure TTestSmallVec.Test_SmallVec_Put_ValidIndex;
var
  V: TSmallIntVec;
begin
  V.Init;
  try
    V.Push(100);
    V.Push(200);
    V.Push(300);
    
    V.Put(1, 999);
    
    AssertEquals('Get(0) unchanged', 100, V.Get(0));
    AssertEquals('Get(1) modified', 999, V.Get(1));
    AssertEquals('Get(2) unchanged', 300, V.Get(2));
  finally
    V.Done;
  end;
end;

procedure TTestSmallVec.Test_SmallVec_GetPtr_ValidIndex;
var
  V: TSmallIntVec;
  P: PInteger;
begin
  V.Init;
  try
    V.Push(42);
    P := V.GetPtr(0);
    
    AssertTrue('Pointer should not be nil', P <> nil);
    AssertEquals('Value via pointer', 42, P^);
    
    // Modify via pointer
    P^ := 99;
    AssertEquals('Value after modification', 99, V.Get(0));
  finally
    V.Done;
  end;
end;

procedure TTestSmallVec.Test_SmallVec_Count_ReflectsElements;
var
  V: TSmallIntVec;
begin
  V.Init;
  try
    AssertEquals('Count=0', 0, V.Count);
    V.Push(1);
    AssertEquals('Count=1', 1, V.Count);
    V.Push(2);
    AssertEquals('Count=2', 2, V.Count);
    V.Push(3);
    AssertEquals('Count=3', 3, V.Count);
  finally
    V.Done;
  end;
end;

procedure TTestSmallVec.Test_SmallVec_Capacity_ReturnsInlineCapacityWhenSmall;
var
  V: TSmallIntVec;
begin
  V.Init;
  try
    // When inline, capacity should be at least the inline capacity
    AssertTrue('Capacity >= 8', V.Capacity >= 8);
    
    V.Push(1);
    V.Push(2);
    AssertTrue('Capacity still >= 8', V.Capacity >= 8);
  finally
    V.Done;
  end;
end;

procedure TTestSmallVec.Test_SmallVec_IsInline_TrueWhenSmall;
var
  V: TSmallIntVec;
  i: Integer;
begin
  V.Init;
  try
    AssertTrue('Empty should be inline', V.IsInline);
    
    for i := 1 to 8 do
    begin
      V.Push(i);
      AssertTrue('Should be inline with ' + IntToStr(i) + ' elements', V.IsInline);
    end;
  finally
    V.Done;
  end;
end;

procedure TTestSmallVec.Test_SmallVec_IsInline_FalseAfterSpill;
var
  V: TSmallIntVec;
  i: Integer;
begin
  V.Init;
  try
    for i := 1 to 9 do
      V.Push(i);
    
    AssertFalse('Should not be inline after spill', V.IsInline);
  finally
    V.Done;
  end;
end;

procedure TTestSmallVec.Test_SmallVec_Clear_ResetsCount;
var
  V: TSmallIntVec;
begin
  V.Init;
  try
    V.Push(1);
    V.Push(2);
    V.Push(3);
    
    V.Clear;
    
    AssertEquals('Count after clear', 0, V.Count);
    AssertTrue('Should be empty', V.IsEmpty);
    AssertTrue('Should be inline after clear', V.IsInline);
  finally
    V.Done;
  end;
end;

procedure TTestSmallVec.Test_SmallVec_Clear_AfterSpill_ResetsToInline;
var
  V: TSmallIntVec;
  i: Integer;
begin
  V.Init;
  try
    // Spill to heap
    for i := 1 to 20 do
      V.Push(i);
    
    AssertFalse('Should have spilled', V.IsInline);
    
    V.Clear;
    
    AssertEquals('Count after clear', 0, V.Count);
    AssertTrue('Should be inline after clear', V.IsInline);
  finally
    V.Done;
  end;
end;

procedure TTestSmallVec.Test_SmallVec_ForIn_Works;
var
  V: TSmallIntVec;
  Sum, Item: Integer;
begin
  V.Init;
  try
    V.Push(1);
    V.Push(2);
    V.Push(3);
    V.Push(4);
    
    Sum := 0;
    for Item in V do
      Sum := Sum + Item;
    
    AssertEquals('Sum should be 10', 10, Sum);
  finally
    V.Done;
  end;
end;

procedure TTestSmallVec.Test_SmallVec_LargeInlineCapacity_Works;
var
  V: TLargeInlineVec;
  i: Integer;
begin
  V.Init;
  try
    // Push 32 elements (within large inline capacity)
    for i := 1 to 32 do
      V.Push(i);
    
    AssertEquals('Count should be 32', 32, V.Count);
    AssertTrue('Should still be inline', V.IsInline);
    
    // Push one more to trigger spill
    V.Push(33);
    AssertFalse('Should have spilled', V.IsInline);
    AssertEquals('Count should be 33', 33, V.Count);
  finally
    V.Done;
  end;
end;

procedure TTestSmallVec.Test_SmallVec_ToArray_ReturnsCorrectData;
var
  V: TSmallIntVec;
  Arr: array of Integer;
begin
  V.Init;
  try
    V.Push(10);
    V.Push(20);
    V.Push(30);
    
    Arr := V.ToArray;
    
    AssertEquals('Array length', 3, Length(Arr));
    AssertEquals('Arr[0]', 10, Arr[0]);
    AssertEquals('Arr[1]', 20, Arr[1]);
    AssertEquals('Arr[2]', 30, Arr[2]);
  finally
    V.Done;
  end;
end;

initialization
  RegisterTest(TTestSmallVec);

end.
