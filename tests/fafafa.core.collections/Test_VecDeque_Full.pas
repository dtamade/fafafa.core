unit Test_VecDeque_Full;

{**
 * @desc TDD 测试：TVecDeque<T> 完整测试套件
 * @purpose 验证双端队列的核心 API
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections,
  fafafa.core.collections.queue,
  fafafa.core.collections.vecdeque,
  fafafa.core.collections.base,
  fafafa.core.mem.allocator;

type
  TTestCase_VecDeque_Full = class(TTestCase)
  private
    type
      TIntQueue = specialize IQueue<Integer>;
      TIntDeque = specialize TVecDeque<Integer>;
  published
    // 基本操作测试
    procedure Test_VecDeque_PushBack_SingleElement;
    procedure Test_VecDeque_PushFront_SingleElement;
    procedure Test_VecDeque_MixedPushFrontBack;
    procedure Test_VecDeque_PopFront_FIFO_Order;
    procedure Test_VecDeque_PopBack_LIFO_Order;
    
    // 随机访问测试
    procedure Test_VecDeque_Get_ReturnsCorrectElement;
    procedure Test_VecDeque_Put_ModifiesElement;
    procedure Test_VecDeque_Indexer_ReadWrite;
    
    // 批量操作测试
    procedure Test_VecDeque_PushBack_Array;
    procedure Test_VecDeque_LoadFromArray;
    
    // 容量管理测试
    procedure Test_VecDeque_Reserve_IncreasesCapacity;
    procedure Test_VecDeque_Truncate_ReducesCount;
    procedure Test_VecDeque_Truncate_Back_ReturnsCorrectElement;
    
    // 其他测试
    procedure Test_VecDeque_Swap_Elements;
    procedure Test_VecDeque_IsEmpty_InitiallyTrue;
    procedure Test_VecDeque_Clear_RemovesAll;
    procedure Test_VecDeque_LargeDataSet;
    procedure Test_VecDeque_FIFO_Queue_Pattern;
  end;

implementation

{ TTestCase_VecDeque_Full }

procedure TTestCase_VecDeque_Full.Test_VecDeque_PushBack_SingleElement;
var
  Q: TIntQueue;
begin
  Q := TIntDeque.Create;
  Q.Push(42);
  
  AssertEquals('Count should be 1', 1, Q.Count);
  AssertEquals('Peek should be 42', 42, Q.Peek);
end;

procedure TTestCase_VecDeque_Full.Test_VecDeque_PushFront_SingleElement;
var
  D: TIntDeque;
begin
  D := TIntDeque.Create;
  try
    D.PushFront(42);
    
    AssertEquals('Count should be 1', 1, D.Count);
    AssertEquals('Front should be 42', 42, D.Front);
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Full.Test_VecDeque_MixedPushFrontBack;
var
  D: TIntDeque;
begin
  D := TIntDeque.Create;
  try
    D.PushBack(2);   // [2]
    D.PushFront(1);  // [1, 2]
    D.PushBack(3);   // [1, 2, 3]
    D.PushFront(0);  // [0, 1, 2, 3]
    
    AssertEquals('Count should be 4', 4, D.Count);
    AssertEquals('Front should be 0', 0, D.Front);
    AssertEquals('Back should be 3', 3, D.Back);
    AssertEquals('Element at 1', 1, D.Get(1));
    AssertEquals('Element at 2', 2, D.Get(2));
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Full.Test_VecDeque_PopFront_FIFO_Order;
var
  D: TIntDeque;
begin
  D := TIntDeque.Create;
  try
    D.PushBack(1);
    D.PushBack(2);
    D.PushBack(3);
    
    AssertEquals('First pop', 1, D.PopFront);
    AssertEquals('Second pop', 2, D.PopFront);
    AssertEquals('Third pop', 3, D.PopFront);
    AssertTrue('Should be empty', D.IsEmpty);
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Full.Test_VecDeque_PopBack_LIFO_Order;
var
  D: TIntDeque;
begin
  D := TIntDeque.Create;
  try
    D.PushBack(1);
    D.PushBack(2);
    D.PushBack(3);
    
    AssertEquals('First pop', 3, D.PopBack);
    AssertEquals('Second pop', 2, D.PopBack);
    AssertEquals('Third pop', 1, D.PopBack);
    AssertTrue('Should be empty', D.IsEmpty);
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Full.Test_VecDeque_Get_ReturnsCorrectElement;
var
  D: TIntDeque;
begin
  D := TIntDeque.Create;
  try
    D.PushBack(10);
    D.PushBack(20);
    D.PushBack(30);
    
    AssertEquals('Get(0)', 10, D.Get(0));
    AssertEquals('Get(1)', 20, D.Get(1));
    AssertEquals('Get(2)', 30, D.Get(2));
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Full.Test_VecDeque_Put_ModifiesElement;
var
  D: TIntDeque;
begin
  D := TIntDeque.Create;
  try
    D.PushBack(10);
    D.PushBack(20);
    D.PushBack(30);
    
    D.Put(1, 999);
    
    AssertEquals('Get(1) after Put', 999, D.Get(1));
    AssertEquals('Get(0) unchanged', 10, D.Get(0));
    AssertEquals('Get(2) unchanged', 30, D.Get(2));
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Full.Test_VecDeque_Indexer_ReadWrite;
var
  D: TIntDeque;
begin
  D := TIntDeque.Create;
  try
    D.PushBack(10);
    D.PushBack(20);
    
    AssertEquals('Read [0]', 10, D.Get(0));
    AssertEquals('Read [1]', 20, D.Get(1));
    
    D.Put(0, 100);
    AssertEquals('After write [0]', 100, D.Get(0));
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Full.Test_VecDeque_PushBack_Array;
var
  D: TIntDeque;
begin
  D := TIntDeque.Create;
  try
    D.PushBack([10, 20, 30]);
    
    AssertEquals('Count', 3, D.Count);
    AssertEquals('Element 0', 10, D.Get(0));
    AssertEquals('Element 1', 20, D.Get(1));
    AssertEquals('Element 2', 30, D.Get(2));
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Full.Test_VecDeque_LoadFromArray;
var
  D: TIntDeque;
begin
  D := TIntDeque.Create;
  try
    D.PushBack(999);
    D.LoadFromArray([1, 2, 3, 4, 5]);
    
    AssertEquals('Count after LoadFromArray', 5, D.Count);
    AssertEquals('Element 0', 1, D.Get(0));
    AssertEquals('Element 4', 5, D.Get(4));
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Full.Test_VecDeque_Reserve_IncreasesCapacity;
var
  D: TIntDeque;
  OldCap: SizeUInt;
begin
  D := TIntDeque.Create;
  try
    D.PushBack(1);
    OldCap := D.Capacity;
    
    D.Reserve(1000);
    
    AssertTrue('Capacity should increase', D.Capacity >= OldCap + 1000);
    AssertEquals('Count unchanged', 1, D.Count);
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Full.Test_VecDeque_Truncate_ReducesCount;
var
  D: TIntDeque;
begin
  D := TIntDeque.Create;
  try
    D.PushBack([1, 2, 3, 4, 5]);
    D.Truncate(3);
    
    AssertEquals('Count after Truncate', 3, D.Count);
    // 注意：使用 Get(Count-1) 验证最后一个有效元素
    AssertEquals('Last element after Truncate', 3, D.Get(D.Count - 1));
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Full.Test_VecDeque_Truncate_Back_ReturnsCorrectElement;
var
  D: TIntDeque;
begin
  // 回归测试：Truncate 后 Back() 应返回正确的最后一个元素
  D := TIntDeque.Create;
  try
    D.PushBack([1, 2, 3, 4, 5]);
    D.Truncate(3);
    
    // Back() 应该返回 Truncate 后的最后一个元素
    AssertEquals('Back after Truncate should be 3', 3, D.Back);
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Full.Test_VecDeque_Swap_Elements;
var
  D: TIntDeque;
begin
  D := TIntDeque.Create;
  try
    D.PushBack([10, 20, 30]);
    D.Swap(0, 2);
    
    AssertEquals('Element 0 after swap', 30, D.Get(0));
    AssertEquals('Element 2 after swap', 10, D.Get(2));
    AssertEquals('Element 1 unchanged', 20, D.Get(1));
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Full.Test_VecDeque_IsEmpty_InitiallyTrue;
var
  D: TIntDeque;
begin
  D := TIntDeque.Create;
  try
    AssertTrue('New deque should be empty', D.IsEmpty);
    AssertEquals('Count should be 0', 0, D.Count);
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Full.Test_VecDeque_Clear_RemovesAll;
var
  D: TIntDeque;
begin
  D := TIntDeque.Create;
  try
    D.PushBack([1, 2, 3]);
    D.Clear;
    
    AssertTrue('Should be empty after Clear', D.IsEmpty);
    AssertEquals('Count should be 0', 0, D.Count);
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Full.Test_VecDeque_LargeDataSet;
var
  D: TIntDeque;
  I: Integer;
begin
  D := TIntDeque.Create;
  try
    for I := 0 to 9999 do
      D.PushBack(I);
    
    AssertEquals('Count', 10000, D.Count);
    AssertEquals('Front', 0, D.Front);
    AssertEquals('Back', 9999, D.Back);
    AssertEquals('Middle element', 5000, D.Get(5000));
    
    for I := 0 to 2499 do
    begin
      D.PopFront;
      D.PopBack;
    end;
    
    AssertEquals('Count after pops', 5000, D.Count);
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Full.Test_VecDeque_FIFO_Queue_Pattern;
var
  Q: TIntQueue;
  V: Integer;
begin
  Q := TIntDeque.Create;
  
  Q.Push(10);
  Q.Push(20);
  Q.Push(30);
  
  AssertTrue(Q.Pop(V));
  AssertEquals('First out', 10, V);
  AssertTrue(Q.Pop(V));
  AssertEquals('Second out', 20, V);
  AssertTrue(Q.Pop(V));
  AssertEquals('Third out', 30, V);
end;

initialization
  RegisterTest(TTestCase_VecDeque_Full);

end.
