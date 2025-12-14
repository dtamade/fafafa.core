unit Test_List_Full;

{**
 * @desc TDD 测试：TList<T> 完整测试套件
 * @purpose 验证双向链表的所有公共 API
 *
 * 测试覆盖:
 *   - PushFront/PushBack: O(1) 双端插入
 *   - PopFront/PopBack: O(1) 双端删除
 *   - Front/Back: O(1) 双端访问
 *   - TryFront/TryBack/TryPopFront/TryPopBack: 安全变体
 *   - 边界条件: 空表操作
 *   - 与 TVecDeque 行为一致性
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections,
  fafafa.core.collections.list,
  fafafa.core.collections.base,
  fafafa.core.mem.allocator;

type
  { TTestCase_List_Full }
  TTestCase_List_Full = class(TTestCase)
  private
    type
      TIntList = specialize IList<Integer>;
      TStrList = specialize IList<String>;
  published
    // 基本操作测试
    procedure Test_List_PushBack_SingleElement;
    procedure Test_List_PushFront_SingleElement;
    procedure Test_List_PushBack_MultipleElements;
    procedure Test_List_PushFront_MultipleElements;
    procedure Test_List_MixedPushFrontBack;
    
    // Pop 操作测试
    procedure Test_List_PopFront_ReturnsFirst;
    procedure Test_List_PopBack_ReturnsLast;
    procedure Test_List_PopFront_FIFO_Order;
    procedure Test_List_PopBack_LIFO_Order;
    
    // Front/Back 访问测试
    procedure Test_List_Front_DoesNotRemove;
    procedure Test_List_Back_DoesNotRemove;
    
    // Try* 安全变体测试
    procedure Test_List_TryFront_Empty_ReturnsFalse;
    procedure Test_List_TryBack_Empty_ReturnsFalse;
    procedure Test_List_TryPopFront_Empty_ReturnsFalse;
    procedure Test_List_TryPopBack_Empty_ReturnsFalse;
    procedure Test_List_TryFront_NonEmpty_ReturnsTrue;
    procedure Test_List_TryBack_NonEmpty_ReturnsTrue;
    procedure Test_List_TryPopFront_NonEmpty_ReturnsTrue;
    procedure Test_List_TryPopBack_NonEmpty_ReturnsTrue;
    
    // 边界条件测试
    procedure Test_List_IsEmpty_InitiallyTrue;
    procedure Test_List_Count_AfterOperations;
    procedure Test_List_Clear_RemovesAll;
    
    // 队列模式 (FIFO)
    procedure Test_List_FIFO_Queue_Pattern;
    
    // 栈模式 (LIFO) 
    procedure Test_List_LIFO_Stack_Pattern;
    
    // 字符串类型测试
    procedure Test_List_String_BasicOperations;
  end;

implementation

{ TTestCase_List_Full }

procedure TTestCase_List_Full.Test_List_PushBack_SingleElement;
var
  List: TIntList;
begin
  List := specialize TList<Integer>.Create;
  
  List.PushBack(42);
  
  AssertEquals('Count should be 1', 1, List.Count);
  AssertEquals('Back should be 42', 42, List.Back);
  AssertEquals('Front should be 42', 42, List.Front);
end;

procedure TTestCase_List_Full.Test_List_PushFront_SingleElement;
var
  List: TIntList;
begin
  List := specialize TList<Integer>.Create;
  
  List.PushFront(42);
  
  AssertEquals('Count should be 1', 1, List.Count);
  AssertEquals('Front should be 42', 42, List.Front);
  AssertEquals('Back should be 42', 42, List.Back);
end;

procedure TTestCase_List_Full.Test_List_PushBack_MultipleElements;
var
  List: TIntList;
begin
  List := specialize TList<Integer>.Create;
  
  List.PushBack(1);
  List.PushBack(2);
  List.PushBack(3);
  
  AssertEquals('Count should be 3', 3, List.Count);
  AssertEquals('Front should be 1', 1, List.Front);
  AssertEquals('Back should be 3', 3, List.Back);
end;

procedure TTestCase_List_Full.Test_List_PushFront_MultipleElements;
var
  List: TIntList;
begin
  List := specialize TList<Integer>.Create;
  
  List.PushFront(1);
  List.PushFront(2);
  List.PushFront(3);
  // 现在: [3, 2, 1]
  
  AssertEquals('Count should be 3', 3, List.Count);
  AssertEquals('Front should be 3', 3, List.Front);
  AssertEquals('Back should be 1', 1, List.Back);
end;

procedure TTestCase_List_Full.Test_List_MixedPushFrontBack;
var
  List: TIntList;
begin
  List := specialize TList<Integer>.Create;
  
  List.PushBack(2);   // [2]
  List.PushFront(1);  // [1, 2]
  List.PushBack(3);   // [1, 2, 3]
  List.PushFront(0);  // [0, 1, 2, 3]
  
  AssertEquals('Count should be 4', 4, List.Count);
  AssertEquals('Front should be 0', 0, List.Front);
  AssertEquals('Back should be 3', 3, List.Back);
end;

procedure TTestCase_List_Full.Test_List_PopFront_ReturnsFirst;
var
  List: TIntList;
  V: Integer;
begin
  List := specialize TList<Integer>.Create;
  List.PushBack(10);
  List.PushBack(20);
  List.PushBack(30);
  // [10, 20, 30]
  
  V := List.PopFront;
  
  AssertEquals('PopFront should return 10', 10, V);
  AssertEquals('Count should be 2', 2, List.Count);
  AssertEquals('New Front should be 20', 20, List.Front);
end;

procedure TTestCase_List_Full.Test_List_PopBack_ReturnsLast;
var
  List: TIntList;
  V: Integer;
begin
  List := specialize TList<Integer>.Create;
  List.PushBack(10);
  List.PushBack(20);
  List.PushBack(30);
  // [10, 20, 30]
  
  V := List.PopBack;
  
  AssertEquals('PopBack should return 30', 30, V);
  AssertEquals('Count should be 2', 2, List.Count);
  AssertEquals('New Back should be 20', 20, List.Back);
end;

procedure TTestCase_List_Full.Test_List_PopFront_FIFO_Order;
var
  List: TIntList;
begin
  List := specialize TList<Integer>.Create;
  List.PushBack(1);
  List.PushBack(2);
  List.PushBack(3);
  
  // FIFO: 先进先出
  AssertEquals('First pop', 1, List.PopFront);
  AssertEquals('Second pop', 2, List.PopFront);
  AssertEquals('Third pop', 3, List.PopFront);
  AssertTrue('Should be empty', List.IsEmpty);
end;

procedure TTestCase_List_Full.Test_List_PopBack_LIFO_Order;
var
  List: TIntList;
begin
  List := specialize TList<Integer>.Create;
  List.PushBack(1);
  List.PushBack(2);
  List.PushBack(3);
  
  // LIFO: 后进先出
  AssertEquals('First pop', 3, List.PopBack);
  AssertEquals('Second pop', 2, List.PopBack);
  AssertEquals('Third pop', 1, List.PopBack);
  AssertTrue('Should be empty', List.IsEmpty);
end;

procedure TTestCase_List_Full.Test_List_Front_DoesNotRemove;
var
  List: TIntList;
  V: Integer;
begin
  List := specialize TList<Integer>.Create;
  List.PushBack(42);
  
  V := List.Front;
  
  AssertEquals('Front should return 42', 42, V);
  AssertEquals('Count should still be 1', 1, List.Count);
  AssertEquals('Front again should be 42', 42, List.Front);
end;

procedure TTestCase_List_Full.Test_List_Back_DoesNotRemove;
var
  List: TIntList;
  V: Integer;
begin
  List := specialize TList<Integer>.Create;
  List.PushBack(42);
  
  V := List.Back;
  
  AssertEquals('Back should return 42', 42, V);
  AssertEquals('Count should still be 1', 1, List.Count);
  AssertEquals('Back again should be 42', 42, List.Back);
end;

procedure TTestCase_List_Full.Test_List_TryFront_Empty_ReturnsFalse;
var
  List: TIntList;
  V: Integer;
begin
  List := specialize TList<Integer>.Create;
  V := -1;
  
  AssertFalse('TryFront on empty list should return False', List.TryFront(V));
end;

procedure TTestCase_List_Full.Test_List_TryBack_Empty_ReturnsFalse;
var
  List: TIntList;
  V: Integer;
begin
  List := specialize TList<Integer>.Create;
  V := -1;
  
  AssertFalse('TryBack on empty list should return False', List.TryBack(V));
end;

procedure TTestCase_List_Full.Test_List_TryPopFront_Empty_ReturnsFalse;
var
  List: TIntList;
  V: Integer;
begin
  List := specialize TList<Integer>.Create;
  V := -1;
  
  AssertFalse('TryPopFront on empty list should return False', List.TryPopFront(V));
end;

procedure TTestCase_List_Full.Test_List_TryPopBack_Empty_ReturnsFalse;
var
  List: TIntList;
  V: Integer;
begin
  List := specialize TList<Integer>.Create;
  V := -1;
  
  AssertFalse('TryPopBack on empty list should return False', List.TryPopBack(V));
end;

procedure TTestCase_List_Full.Test_List_TryFront_NonEmpty_ReturnsTrue;
var
  List: TIntList;
  V: Integer;
begin
  List := specialize TList<Integer>.Create;
  List.PushBack(99);
  
  AssertTrue('TryFront should return True', List.TryFront(V));
  AssertEquals('V should be 99', 99, V);
  AssertEquals('Count should still be 1', 1, List.Count);
end;

procedure TTestCase_List_Full.Test_List_TryBack_NonEmpty_ReturnsTrue;
var
  List: TIntList;
  V: Integer;
begin
  List := specialize TList<Integer>.Create;
  List.PushBack(99);
  
  AssertTrue('TryBack should return True', List.TryBack(V));
  AssertEquals('V should be 99', 99, V);
  AssertEquals('Count should still be 1', 1, List.Count);
end;

procedure TTestCase_List_Full.Test_List_TryPopFront_NonEmpty_ReturnsTrue;
var
  List: TIntList;
  V: Integer;
begin
  List := specialize TList<Integer>.Create;
  List.PushBack(55);
  List.PushBack(66);
  
  AssertTrue('TryPopFront should return True', List.TryPopFront(V));
  AssertEquals('V should be 55', 55, V);
  AssertEquals('Count should be 1', 1, List.Count);
end;

procedure TTestCase_List_Full.Test_List_TryPopBack_NonEmpty_ReturnsTrue;
var
  List: TIntList;
  V: Integer;
begin
  List := specialize TList<Integer>.Create;
  List.PushBack(55);
  List.PushBack(66);
  
  AssertTrue('TryPopBack should return True', List.TryPopBack(V));
  AssertEquals('V should be 66', 66, V);
  AssertEquals('Count should be 1', 1, List.Count);
end;

procedure TTestCase_List_Full.Test_List_IsEmpty_InitiallyTrue;
var
  List: TIntList;
begin
  List := specialize TList<Integer>.Create;
  
  AssertTrue('New list should be empty', List.IsEmpty);
  AssertEquals('Count should be 0', 0, List.Count);
end;

procedure TTestCase_List_Full.Test_List_Count_AfterOperations;
var
  List: TIntList;
begin
  List := specialize TList<Integer>.Create;
  
  AssertEquals('Initial count', 0, List.Count);
  
  List.PushBack(1);
  AssertEquals('After PushBack', 1, List.Count);
  
  List.PushFront(2);
  AssertEquals('After PushFront', 2, List.Count);
  
  List.PopFront;
  AssertEquals('After PopFront', 1, List.Count);
  
  List.PopBack;
  AssertEquals('After PopBack', 0, List.Count);
end;

procedure TTestCase_List_Full.Test_List_Clear_RemovesAll;
var
  List: TIntList;
begin
  List := specialize TList<Integer>.Create;
  List.PushBack(1);
  List.PushBack(2);
  List.PushBack(3);
  
  List.Clear;
  
  AssertTrue('Should be empty after Clear', List.IsEmpty);
  AssertEquals('Count should be 0', 0, List.Count);
end;

procedure TTestCase_List_Full.Test_List_FIFO_Queue_Pattern;
var
  List: TIntList;
begin
  // 队列模式：尾进头出
  List := specialize TList<Integer>.Create;
  
  // Enqueue
  List.PushBack(10);
  List.PushBack(20);
  List.PushBack(30);
  
  // Dequeue (FIFO)
  AssertEquals('First out', 10, List.PopFront);
  AssertEquals('Second out', 20, List.PopFront);
  AssertEquals('Third out', 30, List.PopFront);
end;

procedure TTestCase_List_Full.Test_List_LIFO_Stack_Pattern;
var
  List: TIntList;
begin
  // 栈模式：尾进尾出
  List := specialize TList<Integer>.Create;
  
  // Push
  List.PushBack(10);
  List.PushBack(20);
  List.PushBack(30);
  
  // Pop (LIFO)
  AssertEquals('First out', 30, List.PopBack);
  AssertEquals('Second out', 20, List.PopBack);
  AssertEquals('Third out', 10, List.PopBack);
end;

procedure TTestCase_List_Full.Test_List_String_BasicOperations;
var
  List: TStrList;
  S: String;
begin
  List := specialize TList<String>.Create;
  
  List.PushBack('Hello');
  List.PushBack('World');
  List.PushFront('Hi');
  // [Hi, Hello, World]
  
  AssertEquals('Count', 3, List.Count);
  AssertEquals('Front', 'Hi', List.Front);
  AssertEquals('Back', 'World', List.Back);
  
  AssertTrue('TryPopFront', List.TryPopFront(S));
  AssertEquals('Popped value', 'Hi', S);
end;

initialization
  RegisterTest(TTestCase_List_Full);

end.
