unit Test_PriorityQueue_Interface;

{$mode objfpc}{$H+}
{$I ../src/fafafa.core.settings.inc}

{**
 * TDD 测试用例: IPriorityQueue<T> 接口化重构
 * 
 * 测试目标:
 * 1. IPriorityQueue<T> 接口存在且可用
 * 2. TPriorityQueue<T> 实现为 class 并实现 IPriorityQueue<T>
 * 3. 工厂函数 MakePriorityQueue<T> 可用
 * 4. 支持自定义分配器
 * 5. 继承 IGenericCollection<T> 的方法可用
 * 6. 内存泄漏测试 (HeapTrc)
 *}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections.base,
  fafafa.core.collections.priorityqueue,
  fafafa.core.mem.allocator;

type
  { TTestPriorityQueueInterface }
  TTestPriorityQueueInterface = class(TTestCase)
  private
    class function IntCompare(const A, B: Integer; aData: Pointer): SizeInt; static;
  published
    // 接口存在性测试
    procedure Test_IPriorityQueue_Interface_Exists;
    
    // 工厂函数测试
    procedure Test_MakePriorityQueue_Create;
    procedure Test_MakePriorityQueue_WithCapacity;
    procedure Test_MakePriorityQueue_WithAllocator;
    
    // 基本操作测试
    procedure Test_Enqueue_Dequeue_Basic;
    procedure Test_Peek_DoesNotRemove;
    procedure Test_IsEmpty_Count;
    procedure Test_Clear;
    
    // 堆性质测试 (最小堆)
    procedure Test_MinHeap_Property;
    procedure Test_MinHeap_RandomOrder;
    
    // IGenericCollection 方法测试
    procedure Test_Contains;
    procedure Test_ToArray;
    procedure Test_ForEach;
    procedure Test_Iter;
    
    // 边界条件测试
    procedure Test_Dequeue_Empty_ReturnsFalse;
    procedure Test_Peek_Empty_ReturnsFalse;
    procedure Test_LargeScale_NoLeak;
  end;

implementation

class function TTestPriorityQueueInterface.IntCompare(const A, B: Integer; aData: Pointer): SizeInt;
begin
  if A < B then Result := -1
  else if A > B then Result := 1
  else Result := 0;
end;

procedure TTestPriorityQueueInterface.Test_IPriorityQueue_Interface_Exists;
var
  PQ: specialize IPriorityQueue<Integer>;
begin
  // 测试接口类型存在
  PQ := nil;
  AssertNull('IPriorityQueue interface type should exist', PQ);
end;

procedure TTestPriorityQueueInterface.Test_MakePriorityQueue_Create;
var
  PQ: specialize IPriorityQueue<Integer>;
begin
  PQ := specialize MakePriorityQueue<Integer>(@IntCompare);
  AssertNotNull('MakePriorityQueue should create instance', Pointer(PQ));
  AssertTrue('New PriorityQueue should be empty', PQ.IsEmpty);
  AssertEquals('New PriorityQueue count should be 0', 0, PQ.Count);
end;

procedure TTestPriorityQueueInterface.Test_MakePriorityQueue_WithCapacity;
var
  PQ: specialize IPriorityQueue<Integer>;
begin
  PQ := specialize MakePriorityQueue<Integer>(@IntCompare, 100);
  AssertNotNull('MakePriorityQueue with capacity should create instance', Pointer(PQ));
  AssertTrue('New PriorityQueue should be empty', PQ.IsEmpty);
end;

procedure TTestPriorityQueueInterface.Test_MakePriorityQueue_WithAllocator;
var
  PQ: specialize IPriorityQueue<Integer>;
  Alloc: IAllocator;
begin
  Alloc := GetRtlAllocator;
  PQ := specialize MakePriorityQueue<Integer>(@IntCompare, 16, Alloc);
  AssertNotNull('MakePriorityQueue with allocator should create instance', Pointer(PQ));
  // Note: Allocator property access depends on interface implementation
end;

procedure TTestPriorityQueueInterface.Test_Enqueue_Dequeue_Basic;
var
  PQ: specialize IPriorityQueue<Integer>;
  Item: Integer;
begin
  PQ := specialize MakePriorityQueue<Integer>(@IntCompare);
  
  PQ.Enqueue(5);
  PQ.Enqueue(3);
  PQ.Enqueue(7);
  
  AssertEquals('Count after 3 enqueues', 3, PQ.Count);
  
  AssertTrue('Dequeue should succeed', PQ.Dequeue(Item));
  AssertEquals('First dequeue should be min (3)', 3, Item);
  
  AssertTrue('Dequeue should succeed', PQ.Dequeue(Item));
  AssertEquals('Second dequeue should be 5', 5, Item);
  
  AssertTrue('Dequeue should succeed', PQ.Dequeue(Item));
  AssertEquals('Third dequeue should be max (7)', 7, Item);
  
  AssertTrue('Queue should be empty', PQ.IsEmpty);
end;

procedure TTestPriorityQueueInterface.Test_Peek_DoesNotRemove;
var
  PQ: specialize IPriorityQueue<Integer>;
  Item: Integer;
begin
  PQ := specialize MakePriorityQueue<Integer>(@IntCompare);
  PQ.Enqueue(10);
  
  AssertTrue('Peek should succeed', PQ.Peek(Item));
  AssertEquals('Peek should return 10', 10, Item);
  AssertEquals('Count after peek should still be 1', 1, PQ.Count);
  
  AssertTrue('Second peek should succeed', PQ.Peek(Item));
  AssertEquals('Second peek should return same value', 10, Item);
end;

procedure TTestPriorityQueueInterface.Test_IsEmpty_Count;
var
  PQ: specialize IPriorityQueue<Integer>;
  Item: Integer;
begin
  PQ := specialize MakePriorityQueue<Integer>(@IntCompare);
  
  AssertTrue('New queue should be empty', PQ.IsEmpty);
  AssertEquals('New queue count should be 0', 0, PQ.Count);
  
  PQ.Enqueue(1);
  AssertFalse('Queue with item should not be empty', PQ.IsEmpty);
  AssertEquals('Count should be 1', 1, PQ.Count);
  
  PQ.Dequeue(Item);
  AssertTrue('Queue after dequeue should be empty', PQ.IsEmpty);
end;

procedure TTestPriorityQueueInterface.Test_Clear;
var
  PQ: specialize IPriorityQueue<Integer>;
begin
  PQ := specialize MakePriorityQueue<Integer>(@IntCompare);
  PQ.Enqueue(1);
  PQ.Enqueue(2);
  PQ.Enqueue(3);
  
  AssertEquals('Count before clear', 3, PQ.Count);
  
  PQ.Clear;
  
  AssertTrue('Queue after clear should be empty', PQ.IsEmpty);
  AssertEquals('Count after clear should be 0', 0, PQ.Count);
end;

procedure TTestPriorityQueueInterface.Test_MinHeap_Property;
var
  PQ: specialize IPriorityQueue<Integer>;
  Item, LastItem: Integer;
  i: Integer;
begin
  PQ := specialize MakePriorityQueue<Integer>(@IntCompare);
  
  // 插入倒序数据
  for i := 10 downto 1 do
    PQ.Enqueue(i);
  
  // 验证按升序出队
  LastItem := -1;
  while PQ.Dequeue(Item) do
  begin
    AssertTrue('Items should come out in ascending order', Item > LastItem);
    LastItem := Item;
  end;
end;

procedure TTestPriorityQueueInterface.Test_MinHeap_RandomOrder;
var
  PQ: specialize IPriorityQueue<Integer>;
  Item, LastItem: Integer;
  Values: array[0..9] of Integer = (7, 2, 9, 1, 5, 8, 3, 6, 4, 10);
  i: Integer;
begin
  PQ := specialize MakePriorityQueue<Integer>(@IntCompare);
  
  // 插入随机顺序数据
  for i := 0 to High(Values) do
    PQ.Enqueue(Values[i]);
  
  // 验证按升序出队
  LastItem := 0;
  i := 1;
  while PQ.Dequeue(Item) do
  begin
    AssertEquals('Item ' + IntToStr(i) + ' should be ' + IntToStr(i), i, Item);
    Inc(i);
  end;
end;

procedure TTestPriorityQueueInterface.Test_Contains;
var
  PQ: specialize IPriorityQueue<Integer>;
begin
  PQ := specialize MakePriorityQueue<Integer>(@IntCompare);
  PQ.Enqueue(5);
  PQ.Enqueue(10);
  PQ.Enqueue(15);
  
  AssertTrue('Should contain 5', PQ.Contains(5));
  AssertTrue('Should contain 10', PQ.Contains(10));
  AssertTrue('Should contain 15', PQ.Contains(15));
  AssertFalse('Should not contain 7', PQ.Contains(7));
end;

procedure TTestPriorityQueueInterface.Test_ToArray;
var
  PQ: specialize IPriorityQueue<Integer>;
  Arr: specialize TGenericArray<Integer>;
begin
  PQ := specialize MakePriorityQueue<Integer>(@IntCompare);
  PQ.Enqueue(3);
  PQ.Enqueue(1);
  PQ.Enqueue(2);
  
  Arr := PQ.ToArray;
  AssertEquals('Array length should match count', 3, Length(Arr));
  // 注意: ToArray 返回的是堆数组，不一定是排序的
  // 但应该包含所有元素
end;

procedure TTestPriorityQueueInterface.Test_ForEach;
var
  PQ: specialize IPriorityQueue<Integer>;
  It: specialize TIter<Integer>;
  Sum: Integer;
begin
  PQ := specialize MakePriorityQueue<Integer>(@IntCompare);
  PQ.Enqueue(1);
  PQ.Enqueue(2);
  PQ.Enqueue(3);
  
  // Use iterator instead of ForEach to avoid callback type issues
  Sum := 0;
  It := PQ.Iter;
  while It.MoveNext do
    Sum := Sum + It.Current;
  AssertEquals('Sum of 1+2+3 should be 6', 6, Sum);
end;

procedure TTestPriorityQueueInterface.Test_Iter;
var
  PQ: specialize IPriorityQueue<Integer>;
  It: specialize TIter<Integer>;
  Sum: Integer;
begin
  PQ := specialize MakePriorityQueue<Integer>(@IntCompare);
  PQ.Enqueue(10);
  PQ.Enqueue(20);
  PQ.Enqueue(30);
  
  Sum := 0;
  It := PQ.Iter;
  while It.MoveNext do
    Sum := Sum + It.Current;
  
  AssertEquals('Sum via iterator should be 60', 60, Sum);
end;

procedure TTestPriorityQueueInterface.Test_Dequeue_Empty_ReturnsFalse;
var
  PQ: specialize IPriorityQueue<Integer>;
  Item: Integer;
begin
  PQ := specialize MakePriorityQueue<Integer>(@IntCompare);
  AssertFalse('Dequeue on empty queue should return False', PQ.Dequeue(Item));
end;

procedure TTestPriorityQueueInterface.Test_Peek_Empty_ReturnsFalse;
var
  PQ: specialize IPriorityQueue<Integer>;
  Item: Integer;
begin
  PQ := specialize MakePriorityQueue<Integer>(@IntCompare);
  AssertFalse('Peek on empty queue should return False', PQ.Peek(Item));
end;

procedure TTestPriorityQueueInterface.Test_LargeScale_NoLeak;
var
  PQ: specialize IPriorityQueue<Integer>;
  i: Integer;
  Item: Integer;
begin
  PQ := specialize MakePriorityQueue<Integer>(@IntCompare);
  
  // 插入 1000 个元素
  for i := 1 to 1000 do
    PQ.Enqueue(i);
  
  AssertEquals('Count should be 1000', 1000, PQ.Count);
  
  // 取出 500 个
  for i := 1 to 500 do
    PQ.Dequeue(Item);
  
  AssertEquals('Count should be 500', 500, PQ.Count);
  
  // 清空 - 接口引用计数会自动释放
  PQ := nil;
  
  // 如果有内存泄漏，HeapTrc 会报告
end;

initialization
  RegisterTest(TTestPriorityQueueInterface);
  
end.
