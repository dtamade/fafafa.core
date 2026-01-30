unit Test_Queue_Full;

{**
 * @desc TDD 测试：Queue 完整测试套件
 * @purpose 验证 IQueue 队列操作 (FIFO)
 *
 * 测试内容:
 *   - Push/Pop 基本操作
 *   - Peek 访问
 *   - FIFO 顺序验证
 *   - 边界条件测试
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
  { TTestCase_Queue_Full }
  TTestCase_Queue_Full = class(TTestCase)
  private
    type
      TIntQueue = specialize IQueue<Integer>;
      TStrQueue = specialize IQueue<string>;
  published
    // 基本操作测试
    procedure Test_Queue_Push_SingleElement;
    procedure Test_Queue_Push_MultipleElements;
    procedure Test_Queue_Pop_ReturnsElement;
    procedure Test_Queue_Peek_DoesNotRemove;
    procedure Test_Queue_FIFO_Order;
    
    // 边界条件测试
    procedure Test_Queue_IsEmpty_InitiallyTrue;
    procedure Test_Queue_Pop_Empty_ReturnsFalse;
    procedure Test_Queue_TryPeek_Empty_ReturnsFalse;
    procedure Test_Queue_Clear_RemovesAll;
    procedure Test_Queue_Count_AfterOperations;
    
    // Peek 语义测试 (FIFO: Peek 应返回 Front)
    procedure Test_Queue_Peek_ReturnsFront_NotBack;
    
    // 批量操作测试
    procedure Test_Queue_Push_Array;
    
    // 托管类型测试
    procedure Test_Queue_String_NoLeak;
  end;

implementation

{ TTestCase_Queue_Full }

procedure TTestCase_Queue_Full.Test_Queue_Push_SingleElement;
var
  Queue: TIntQueue;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  Queue := specialize MakeQueue<Integer>;
  {$ELSE}
  Queue := specialize TVecDeque<Integer>.Create;
  {$ENDIF}
  
  Queue.Push(42);
  
  AssertEquals('Count 应为 1', 1, Queue.Count);
  AssertEquals('Peek 应为 42', 42, Queue.Peek);
end;

procedure TTestCase_Queue_Full.Test_Queue_Push_MultipleElements;
var
  Queue: TIntQueue;
  V: Integer;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  Queue := specialize MakeQueue<Integer>;
  {$ELSE}
  Queue := specialize TVecDeque<Integer>.Create;
  {$ENDIF}
  
  Queue.Push(1);
  Queue.Push(2);
  Queue.Push(3);
  
  AssertEquals('Count 应为 3', 3, Queue.Count);
  // 验证 FIFO 顺序: Pop 应该从 Front 取
  AssertTrue(Queue.Pop(V));
  AssertEquals('第一个 Pop 应为 1 (FIFO)', 1, V);
end;

procedure TTestCase_Queue_Full.Test_Queue_Pop_ReturnsElement;
var
  Queue: TIntQueue;
  V: Integer;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  Queue := specialize MakeQueue<Integer>;
  {$ELSE}
  Queue := specialize TVecDeque<Integer>.Create;
  {$ENDIF}
  
  Queue.Push(100);
  AssertTrue('Pop 应成功', Queue.Pop(V));
  
  AssertEquals('Pop 应返回 100', 100, V);
  AssertTrue('Pop 后应为空', Queue.IsEmpty);
end;

procedure TTestCase_Queue_Full.Test_Queue_Peek_DoesNotRemove;
var
  Queue: TIntQueue;
  V: Integer;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  Queue := specialize MakeQueue<Integer>;
  {$ELSE}
  Queue := specialize TVecDeque<Integer>.Create;
  {$ENDIF}
  
  Queue.Push(55);
  AssertTrue('TryPeek 应成功', Queue.TryPeek(V));
  
  AssertEquals('Peek 应返回 55', 55, V);
  AssertEquals('Peek 后 Count 应仍为 1', 1, Queue.Count);
end;

procedure TTestCase_Queue_Full.Test_Queue_FIFO_Order;
var
  Queue: TIntQueue;
  V: Integer;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  Queue := specialize MakeQueue<Integer>;
  {$ELSE}
  Queue := specialize TVecDeque<Integer>.Create;
  {$ENDIF}
  
  // Push 顺序: 1, 2, 3
  Queue.Push(1);
  Queue.Push(2);
  Queue.Push(3);
  
  // Pop 顺序应为: 1, 2, 3 (FIFO)
  AssertTrue(Queue.Pop(V));
  AssertEquals('第一个 Pop 应为 1', 1, V);
  AssertTrue(Queue.Pop(V));
  AssertEquals('第二个 Pop 应为 2', 2, V);
  AssertTrue(Queue.Pop(V));
  AssertEquals('第三个 Pop 应为 3', 3, V);
end;

procedure TTestCase_Queue_Full.Test_Queue_IsEmpty_InitiallyTrue;
var
  Queue: TIntQueue;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  Queue := specialize MakeQueue<Integer>;
  {$ELSE}
  Queue := specialize TVecDeque<Integer>.Create;
  {$ENDIF}
  
  AssertTrue('新队列应为空', Queue.IsEmpty);
end;

procedure TTestCase_Queue_Full.Test_Queue_Pop_Empty_ReturnsFalse;
var
  Queue: TIntQueue;
  V: Integer;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  Queue := specialize MakeQueue<Integer>;
  {$ELSE}
  Queue := specialize TVecDeque<Integer>.Create;
  {$ENDIF}
  
  AssertFalse('空队列 Pop 应返回 False', Queue.Pop(V));
end;

procedure TTestCase_Queue_Full.Test_Queue_TryPeek_Empty_ReturnsFalse;
var
  Queue: TIntQueue;
  V: Integer;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  Queue := specialize MakeQueue<Integer>;
  {$ELSE}
  Queue := specialize TVecDeque<Integer>.Create;
  {$ENDIF}
  
  AssertFalse('空队列 TryPeek 应返回 False', Queue.TryPeek(V));
end;

procedure TTestCase_Queue_Full.Test_Queue_Clear_RemovesAll;
var
  Queue: TIntQueue;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  Queue := specialize MakeQueue<Integer>;
  {$ELSE}
  Queue := specialize TVecDeque<Integer>.Create;
  {$ENDIF}
  
  Queue.Push(1);
  Queue.Push(2);
  Queue.Push(3);
  
  Queue.Clear;
  
  AssertTrue('Clear 后应为空', Queue.IsEmpty);
  AssertEquals('Clear 后 Count 为 0', 0, Queue.Count);
end;

procedure TTestCase_Queue_Full.Test_Queue_Count_AfterOperations;
var
  Queue: TIntQueue;
  V: Integer;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  Queue := specialize MakeQueue<Integer>;
  {$ELSE}
  Queue := specialize TVecDeque<Integer>.Create;
  {$ENDIF}
  
  AssertEquals('初始 Count', 0, Queue.Count);
  
  Queue.Push(1);
  AssertEquals('Push 后 Count', 1, Queue.Count);
  
  Queue.Push(2);
  AssertEquals('再 Push 后 Count', 2, Queue.Count);
  
  Queue.Pop(V);
  AssertEquals('Pop 后 Count', 1, Queue.Count);
end;

procedure TTestCase_Queue_Full.Test_Queue_Peek_ReturnsFront_NotBack;
var
  Queue: TIntQueue;
  V: Integer;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  Queue := specialize MakeQueue<Integer>;
  {$ELSE}
  Queue := specialize TVecDeque<Integer>.Create;
  {$ENDIF}
  
  // Push 顺序: 1, 2, 3
  Queue.Push(1);
  Queue.Push(2);
  Queue.Push(3);
  
  // FIFO 语义: Peek 应返回第一个 Push 的元素 (Front)
  AssertTrue('TryPeek 应成功', Queue.TryPeek(V));
  AssertEquals('Peek 应返回 1 (Front, FIFO)', 1, V);
  
  // Peek 后 Count 不变
  AssertEquals('Peek 后 Count 应仍为 3', 3, Queue.Count);
  
  // Pop 应返回同样的元素
  AssertTrue(Queue.Pop(V));
  AssertEquals('Pop 应返回与 Peek 相同的元素', 1, V);
end;

procedure TTestCase_Queue_Full.Test_Queue_Push_Array;
var
  Queue: TIntQueue;
  V: Integer;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  Queue := specialize MakeQueue<Integer>;
  {$ELSE}
  Queue := specialize TVecDeque<Integer>.Create;
  {$ENDIF}
  
  Queue.Push([10, 20, 30, 40, 50]);
  
  AssertEquals('Count 应为 5', 5, Queue.Count);
  
  // FIFO: 第一个 Push 的先出
  AssertTrue(Queue.Pop(V));
  AssertEquals('第一个应为 10', 10, V);
end;

procedure TTestCase_Queue_Full.Test_Queue_String_NoLeak;
var
  Queue: TStrQueue;
  S: string;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  Queue := specialize MakeQueue<string>;
  {$ELSE}
  Queue := specialize TVecDeque<string>.Create;
  {$ENDIF}
  
  Queue.Push('First');
  Queue.Push('Second');
  Queue.Push('Third');
  
  AssertEquals('Count 应为 3', 3, Queue.Count);
  
  AssertTrue(Queue.Pop(S));
  AssertEquals('应为 First (FIFO)', 'First', S);
  
  Queue.Clear;
  AssertTrue('Clear 后应为空', Queue.IsEmpty);
end;

initialization
  RegisterTest(TTestCase_Queue_Full);

end.
