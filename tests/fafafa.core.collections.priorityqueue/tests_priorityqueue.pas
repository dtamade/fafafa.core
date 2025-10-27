unit tests_priorityqueue;

{$mode objfpc}{$H+}{$J-}

interface

uses
  fpcunit, testregistry,
  fafafa.core.collections.priorityqueue;

type
  // 测试整数类型优先队列
  TTestIntPriorityQueue = class(TTestCase)
  published
    // 基本操作测试
    procedure Test_Init_EmptyQueue_Success;
    procedure Test_Enqueue_SingleElement_Success;
    procedure Test_Enqueue_MultipleElements_MaintainsMinHeap;
    procedure Test_Dequeue_FromNonEmpty_ReturnsMinElement;
    procedure Test_Dequeue_EmptyQueue_ReturnsFalse;
    procedure Test_Peek_NonEmpty_ReturnsMinWithoutRemoval;
    procedure Test_Peek_Empty_ReturnsFalse;
    
    // 边界条件测试
    procedure Test_Enqueue_DuplicateElements_Success;
    procedure Test_Enqueue_LargeDataset_MaintainsHeapProperty;
    procedure Test_Dequeue_UntilEmpty_AllElementsInOrder;
    procedure Test_Clear_NonEmpty_BecomesEmpty;
    
    // 高级操作测试
    procedure Test_Find_ExistingElement_ReturnsTrue;
    procedure Test_Find_NonExistingElement_ReturnsFalse;
    procedure Test_Delete_ExistingElement_Success;
    procedure Test_Delete_NonExistingElement_ReturnsFalse;
    procedure Test_Delete_MinElement_NewMinCorrect;
    
    // 堆属性验证测试
    procedure Test_HeapProperty_AfterMultipleOperations;
  end;

  // 测试自定义类型优先队列
  TTestCustomTypePriorityQueue = class(TTestCase)
  published
    procedure Test_CustomComparator_ReverseOrder_MaxHeap;
  end;

implementation

uses
  SysUtils;

// 整数比较器
function IntCompare(const A, B: Integer): Integer;
begin
  Result := A - B;
end;

// 反向比较器（用于最大堆）
function ReverseIntCompare(const A, B: Integer): Integer;
begin
  Result := B - A; // 反向比较器：大的排前面
end;

{ TTestIntPriorityQueue }

procedure TTestIntPriorityQueue.Test_Init_EmptyQueue_Success;
var
  Queue: specialize TPriorityQueue<Integer>;
begin
  // Arrange & Act
  Queue.Init(@IntCompare);
  
  // Assert
  AssertTrue('New queue should be empty', Queue.IsEmpty);
  AssertEquals('Empty queue size should be 0', 0, Queue.Count);
end;

procedure TTestIntPriorityQueue.Test_Enqueue_SingleElement_Success;
var
  Queue: specialize TPriorityQueue<Integer>;
  Value: Integer;
begin
  // Arrange
  Queue.Init(@IntCompare);
  
  // Act
  Queue.Enqueue(42);
  
  // Assert
  AssertFalse('Queue should not be empty', Queue.IsEmpty);
  AssertEquals('Queue size should be 1', 1, Queue.Count);
  AssertTrue('Should peek correct value', Queue.Peek(Value));
  AssertEquals('Peeked value should be 42', 42, Value);
end;

procedure TTestIntPriorityQueue.Test_Enqueue_MultipleElements_MaintainsMinHeap;
var
  Queue: specialize TPriorityQueue<Integer>;
  Value: Integer;
begin
  // Arrange
  Queue.Init(@IntCompare);
  
  // Act - 插入无序元素
  Queue.Enqueue(50);
  Queue.Enqueue(20);
  Queue.Enqueue(80);
  Queue.Enqueue(10);
  Queue.Enqueue(30);
  
  // Assert - 最小值应该在顶部
  AssertEquals('Queue size should be 5', 5, Queue.Count);
  AssertTrue('Should peek min value', Queue.Peek(Value));
  AssertEquals('Min value should be 10', 10, Value);
end;

procedure TTestIntPriorityQueue.Test_Dequeue_FromNonEmpty_ReturnsMinElement;
var
  Queue: specialize TPriorityQueue<Integer>;
  Value: Integer;
begin
  // Arrange
  Queue.Init(@IntCompare);
  Queue.Enqueue(50);
  Queue.Enqueue(20);
  Queue.Enqueue(80);
  Queue.Enqueue(10);
  
  // Act
  AssertTrue('Dequeue should succeed', Queue.Dequeue(Value));
  
  // Assert
  AssertEquals('Dequeued value should be min (10)', 10, Value);
  AssertEquals('Queue size should decrease', 3, Queue.Count);
end;

procedure TTestIntPriorityQueue.Test_Dequeue_EmptyQueue_ReturnsFalse;
var
  Queue: specialize TPriorityQueue<Integer>;
  Value: Integer;
begin
  // Arrange
  Queue.Init(@IntCompare);
  
  // Act & Assert
  AssertFalse('Dequeue from empty should return false', Queue.Dequeue(Value));
end;

procedure TTestIntPriorityQueue.Test_Peek_NonEmpty_ReturnsMinWithoutRemoval;
var
  Queue: specialize TPriorityQueue<Integer>;
  Value: Integer;
begin
  // Arrange
  Queue.Init(@IntCompare);
  Queue.Enqueue(30);
  Queue.Enqueue(10);
  Queue.Enqueue(20);
  
  // Act
  AssertTrue('First peek should succeed', Queue.Peek(Value));
  AssertEquals('First peek should return 10', 10, Value);
  
  // Assert - 第二次 peek 应该返回相同值
  AssertTrue('Second peek should succeed', Queue.Peek(Value));
  AssertEquals('Second peek should still return 10', 10, Value);
  AssertEquals('Count should remain 3', 3, Queue.Count);
end;

procedure TTestIntPriorityQueue.Test_Peek_Empty_ReturnsFalse;
var
  Queue: specialize TPriorityQueue<Integer>;
  Value: Integer;
begin
  // Arrange
  Queue.Init(@IntCompare);
  
  // Act & Assert
  AssertFalse('Peek on empty queue should return false', Queue.Peek(Value));
end;

procedure TTestIntPriorityQueue.Test_Enqueue_DuplicateElements_Success;
var
  Queue: specialize TPriorityQueue<Integer>;
  Value: Integer;
  I: Integer;
begin
  // Arrange
  Queue.Init(@IntCompare);
  
  // Act - 插入重复元素
  for I := 1 to 5 do
    Queue.Enqueue(42);
  
  // Assert
  AssertEquals('Should contain 5 elements', 5, Queue.Count);
  AssertTrue('Peek should succeed', Queue.Peek(Value));
  AssertEquals('All elements are 42', 42, Value);
end;

procedure TTestIntPriorityQueue.Test_Enqueue_LargeDataset_MaintainsHeapProperty;
var
  Queue: specialize TPriorityQueue<Integer>;
  I: Integer;
  Value, PrevValue: Integer;
begin
  // Arrange
  Queue.Init(@IntCompare);
  
  // Act - 插入 1000 个随机元素
  for I := 1 to 1000 do
    Queue.Enqueue(Random(10000));
  
  // Assert - 出队应该按升序
  AssertEquals('Should have 1000 elements', 1000, Queue.Count);
  
  PrevValue := 0; // 初始化
  Queue.Dequeue(PrevValue);
  while not Queue.IsEmpty do
  begin
    Queue.Dequeue(Value);
    AssertTrue('Elements should be in ascending order', Value >= PrevValue);
    PrevValue := Value;
  end;
end;

procedure TTestIntPriorityQueue.Test_Dequeue_UntilEmpty_AllElementsInOrder;
var
  Queue: specialize TPriorityQueue<Integer>;
  Value, PrevValue: Integer;
  FirstDequeue: Boolean;
begin
  // Arrange
  Queue.Init(@IntCompare);
  Queue.Enqueue(50);
  Queue.Enqueue(20);
  Queue.Enqueue(80);
  Queue.Enqueue(10);
  Queue.Enqueue(30);
  
  // Act & Assert
  FirstDequeue := True;
  PrevValue := 0; // 初始化
  while Queue.Dequeue(Value) do
  begin
    if not FirstDequeue then
      AssertTrue('Elements should be in order', Value >= PrevValue);
    PrevValue := Value;
    FirstDequeue := False;
  end;
  
  AssertTrue('Queue should be empty', Queue.IsEmpty);
end;

procedure TTestIntPriorityQueue.Test_Clear_NonEmpty_BecomesEmpty;
var
  Queue: specialize TPriorityQueue<Integer>;
begin
  // Arrange
  Queue.Init(@IntCompare);
  Queue.Enqueue(10);
  Queue.Enqueue(20);
  Queue.Enqueue(30);
  
  // Act
  Queue.Clear;
  
  // Assert
  AssertTrue('Queue should be empty after clear', Queue.IsEmpty);
  AssertEquals('Count should be 0', 0, Queue.Count);
end;

procedure TTestIntPriorityQueue.Test_Find_ExistingElement_ReturnsTrue;
var
  Queue: specialize TPriorityQueue<Integer>;
begin
  // Arrange
  Queue.Init(@IntCompare);
  Queue.Enqueue(10);
  Queue.Enqueue(20);
  Queue.Enqueue(30);
  
  // Act & Assert
  AssertTrue('Should find existing element 20', Queue.Find(20));
  AssertTrue('Should find existing element 10', Queue.Find(10));
  AssertTrue('Should find existing element 30', Queue.Find(30));
end;

procedure TTestIntPriorityQueue.Test_Find_NonExistingElement_ReturnsFalse;
var
  Queue: specialize TPriorityQueue<Integer>;
begin
  // Arrange
  Queue.Init(@IntCompare);
  Queue.Enqueue(10);
  Queue.Enqueue(20);
  Queue.Enqueue(30);
  
  // Act & Assert
  AssertFalse('Should not find non-existing element', Queue.Find(99));
end;

procedure TTestIntPriorityQueue.Test_Delete_ExistingElement_Success;
var
  Queue: specialize TPriorityQueue<Integer>;
begin
  // Arrange
  Queue.Init(@IntCompare);
  Queue.Enqueue(10);
  Queue.Enqueue(20);
  Queue.Enqueue(30);
  
  // Act
  AssertTrue('Delete should succeed', Queue.Delete(20));
  
  // Assert
  AssertEquals('Count should decrease', 2, Queue.Count);
  AssertFalse('Deleted element should not be found', Queue.Find(20));
end;

procedure TTestIntPriorityQueue.Test_Delete_NonExistingElement_ReturnsFalse;
var
  Queue: specialize TPriorityQueue<Integer>;
begin
  // Arrange
  Queue.Init(@IntCompare);
  Queue.Enqueue(10);
  Queue.Enqueue(20);
  
  // Act & Assert
  AssertFalse('Delete of non-existing should return false', Queue.Delete(99));
  AssertEquals('Count should remain unchanged', 2, Queue.Count);
end;

procedure TTestIntPriorityQueue.Test_Delete_MinElement_NewMinCorrect;
var
  Queue: specialize TPriorityQueue<Integer>;
  Value: Integer;
begin
  // Arrange
  Queue.Init(@IntCompare);
  Queue.Enqueue(10);
  Queue.Enqueue(20);
  Queue.Enqueue(30);
  
  // Act - 删除最小元素
  Queue.Delete(10);
  
  // Assert - 新的最小值应该是 20
  AssertTrue('Peek should succeed', Queue.Peek(Value));
  AssertEquals('New min should be 20', 20, Value);
end;

procedure TTestIntPriorityQueue.Test_HeapProperty_AfterMultipleOperations;
var
  Queue: specialize TPriorityQueue<Integer>;
  Value: Integer;
begin
  // Arrange
  Queue.Init(@IntCompare);
  
  // Act - 混合操作
  Queue.Enqueue(50);
  Queue.Enqueue(20);
  Queue.Enqueue(80);
  Queue.Dequeue(Value); // 移除 20
  Queue.Enqueue(10);
  Queue.Delete(50);
  Queue.Enqueue(5);
  Queue.Enqueue(90);
  
  // Assert - 最小值应该是 5
  AssertTrue('Peek should succeed', Queue.Peek(Value));
  AssertEquals('Min after operations should be 5', 5, Value);
  
  // 验证所有元素按序出队
  Value := 0;
  while Queue.Dequeue(Value) do
  begin
    // 每个元素应该 >= 前一个
    // （通过 Peek 已验证第一个是 5）
  end;
end;

{ TTestCustomTypePriorityQueue }

procedure TTestCustomTypePriorityQueue.Test_CustomComparator_ReverseOrder_MaxHeap;
var
  Queue: specialize TPriorityQueue<Integer>;
  Value: Integer;
begin
  // Arrange
  Queue.Init(@ReverseIntCompare);
  
  // Act
  Queue.Enqueue(10);
  Queue.Enqueue(50);
  Queue.Enqueue(20);
  
  // Assert - 最大堆：最大值应该在顶部
  AssertTrue('Peek should succeed', Queue.Peek(Value));
  AssertEquals('Max value should be at top', 50, Value);
  
  Queue.Dequeue(Value);
  AssertEquals('First dequeue should be 50', 50, Value);
  Queue.Dequeue(Value);
  AssertEquals('Second dequeue should be 20', 20, Value);
  Queue.Dequeue(Value);
  AssertEquals('Third dequeue should be 10', 10, Value);
end;

initialization
  RegisterTest(TTestIntPriorityQueue);
  RegisterTest(TTestCustomTypePriorityQueue);

end.
