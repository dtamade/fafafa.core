unit Test_ForwardList_Full;

{**
 * @desc TDD 测试：ForwardList 完整测试套件
 * @purpose 验证 IForwardList 单向链表操作
 *
 * 测试内容:
 *   - PushFront/PopFront 基本操作
 *   - Front 访问
 *   - InsertAfter/EraseAfter 操作
 *   - 边界条件测试
 *   - 内存安全测试
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections,
  fafafa.core.collections.forwardList,
  fafafa.core.collections.base,
  fafafa.core.mem.allocator;

type
  { TTestCase_ForwardList_Full }
  TTestCase_ForwardList_Full = class(TTestCase)
  private
    type
      TIntForwardList = specialize IForwardList<Integer>;
      TStrForwardList = specialize IForwardList<string>;
  published
    // 基本操作测试
    procedure Test_ForwardList_PushFront_SingleElement;
    procedure Test_ForwardList_PushFront_MultipleElements;
    procedure Test_ForwardList_PopFront_ReturnsElement;
    procedure Test_ForwardList_Front_DoesNotRemove;
    procedure Test_ForwardList_LIFO_Order;
    
    // 边界条件测试
    procedure Test_ForwardList_IsEmpty_InitiallyTrue;
    procedure Test_ForwardList_TryPopFront_Empty_ReturnsFalse;
    procedure Test_ForwardList_TryFront_Empty_ReturnsFalse;
    procedure Test_ForwardList_Clear_RemovesAll;
    procedure Test_ForwardList_Count_AfterOperations;
    
    // 迭代器测试
    procedure Test_ForwardList_Iterator_TraversesAll;
    procedure Test_ForwardList_InsertAfter_InsertsCorrectly;
    procedure Test_ForwardList_EraseAfter_RemovesNext;
    
    // 托管类型测试 (string)
    procedure Test_ForwardList_String_NoLeak;
  end;

implementation

{ TTestCase_ForwardList_Full }

procedure TTestCase_ForwardList_Full.Test_ForwardList_PushFront_SingleElement;
var
  List: TIntForwardList;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  List := specialize MakeForwardList<Integer>;
  {$ELSE}
  List := specialize TForwardList<Integer>.Create;
  {$ENDIF}
  
  List.PushFront(42);
  
  AssertEquals('Count 应为 1', 1, List.GetCount);
  AssertEquals('Front 应为 42', 42, List.Front);
end;

procedure TTestCase_ForwardList_Full.Test_ForwardList_PushFront_MultipleElements;
var
  List: TIntForwardList;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  List := specialize MakeForwardList<Integer>;
  {$ELSE}
  List := specialize TForwardList<Integer>.Create;
  {$ENDIF}
  
  List.PushFront(1);
  List.PushFront(2);
  List.PushFront(3);
  
  AssertEquals('Count 应为 3', 3, List.GetCount);
  // PushFront 是 LIFO，最后 Push 的在最前面
  AssertEquals('Front 应为 3', 3, List.Front);
end;

procedure TTestCase_ForwardList_Full.Test_ForwardList_PopFront_ReturnsElement;
var
  List: TIntForwardList;
  V: Integer;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  List := specialize MakeForwardList<Integer>;
  {$ELSE}
  List := specialize TForwardList<Integer>.Create;
  {$ENDIF}
  
  List.PushFront(100);
  V := List.PopFront;
  
  AssertEquals('PopFront 应返回 100', 100, V);
  AssertTrue('PopFront 后应为空', List.IsEmpty);
end;

procedure TTestCase_ForwardList_Full.Test_ForwardList_Front_DoesNotRemove;
var
  List: TIntForwardList;
  V: Integer;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  List := specialize MakeForwardList<Integer>;
  {$ELSE}
  List := specialize TForwardList<Integer>.Create;
  {$ENDIF}
  
  List.PushFront(55);
  V := List.Front;
  
  AssertEquals('Front 应返回 55', 55, V);
  AssertEquals('Front 后 Count 应仍为 1', 1, List.GetCount);
end;

procedure TTestCase_ForwardList_Full.Test_ForwardList_LIFO_Order;
var
  List: TIntForwardList;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  List := specialize MakeForwardList<Integer>;
  {$ELSE}
  List := specialize TForwardList<Integer>.Create;
  {$ENDIF}
  
  // Push 顺序: 1, 2, 3
  List.PushFront(1);
  List.PushFront(2);
  List.PushFront(3);
  
  // Pop 顺序应为: 3, 2, 1 (LIFO)
  AssertEquals('第一个 Pop', 3, List.PopFront);
  AssertEquals('第二个 Pop', 2, List.PopFront);
  AssertEquals('第三个 Pop', 1, List.PopFront);
end;

procedure TTestCase_ForwardList_Full.Test_ForwardList_IsEmpty_InitiallyTrue;
var
  List: TIntForwardList;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  List := specialize MakeForwardList<Integer>;
  {$ELSE}
  List := specialize TForwardList<Integer>.Create;
  {$ENDIF}
  
  AssertTrue('新链表应为空', List.IsEmpty);
end;

procedure TTestCase_ForwardList_Full.Test_ForwardList_TryPopFront_Empty_ReturnsFalse;
var
  List: TIntForwardList;
  V: Integer;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  List := specialize MakeForwardList<Integer>;
  {$ELSE}
  List := specialize TForwardList<Integer>.Create;
  {$ENDIF}
  
  AssertFalse('空链表 TryPopFront 应返回 False', List.TryPopFront(V));
end;

procedure TTestCase_ForwardList_Full.Test_ForwardList_TryFront_Empty_ReturnsFalse;
var
  List: TIntForwardList;
  V: Integer;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  List := specialize MakeForwardList<Integer>;
  {$ELSE}
  List := specialize TForwardList<Integer>.Create;
  {$ENDIF}
  
  AssertFalse('空链表 TryFront 应返回 False', List.TryFront(V));
end;

procedure TTestCase_ForwardList_Full.Test_ForwardList_Clear_RemovesAll;
var
  List: TIntForwardList;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  List := specialize MakeForwardList<Integer>;
  {$ELSE}
  List := specialize TForwardList<Integer>.Create;
  {$ENDIF}
  
  List.PushFront(1);
  List.PushFront(2);
  List.PushFront(3);
  
  List.Clear;
  
  AssertTrue('Clear 后应为空', List.IsEmpty);
  AssertEquals('Clear 后 Count 为 0', 0, List.GetCount);
end;

procedure TTestCase_ForwardList_Full.Test_ForwardList_Count_AfterOperations;
var
  List: TIntForwardList;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  List := specialize MakeForwardList<Integer>;
  {$ELSE}
  List := specialize TForwardList<Integer>.Create;
  {$ENDIF}
  
  AssertEquals('初始 Count', 0, List.GetCount);
  
  List.PushFront(1);
  AssertEquals('PushFront 后 Count', 1, List.GetCount);
  
  List.PushFront(2);
  AssertEquals('再 PushFront 后 Count', 2, List.GetCount);
  
  List.PopFront;
  AssertEquals('PopFront 后 Count', 1, List.GetCount);
end;

procedure TTestCase_ForwardList_Full.Test_ForwardList_Iterator_TraversesAll;
var
  List: TIntForwardList;
  LIter: specialize TIter<Integer>;
  LSum: Integer;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  List := specialize MakeForwardList<Integer>;
  {$ELSE}
  List := specialize TForwardList<Integer>.Create;
  {$ENDIF}
  
  // Push 1, 2, 3 -> 链表顺序: 3, 2, 1
  List.PushFront(1);
  List.PushFront(2);
  List.PushFront(3);
  
  LSum := 0;
  LIter := List.Iter;
  while LIter.MoveNext do
    LSum := LSum + LIter.Current;
  
  AssertEquals('迭代求和应为 6', 6, LSum);
end;

procedure TTestCase_ForwardList_Full.Test_ForwardList_InsertAfter_InsertsCorrectly;
var
  List: TIntForwardList;
  LIter: specialize TIter<Integer>;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  List := specialize MakeForwardList<Integer>;
  {$ELSE}
  List := specialize TForwardList<Integer>.Create;
  {$ENDIF}
  
  List.PushFront(1);  // 链表: [1]
  
  LIter := List.Iter;
  LIter.MoveNext;     // 指向 1
  
  List.InsertAfter(LIter, 2);  // 在 1 后插入 2 -> [1, 2]
  
  AssertEquals('Count 应为 2', 2, List.GetCount);
  AssertEquals('Front 仍为 1', 1, List.Front);
end;

procedure TTestCase_ForwardList_Full.Test_ForwardList_EraseAfter_RemovesNext;
var
  List: TIntForwardList;
  LIter: specialize TIter<Integer>;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  List := specialize MakeForwardList<Integer>;
  {$ELSE}
  List := specialize TForwardList<Integer>.Create;
  {$ENDIF}
  
  List.PushFront(1);
  List.PushFront(2);
  List.PushFront(3);  // 链表: [3, 2, 1]
  
  LIter := List.Iter;
  LIter.MoveNext;     // 指向 3
  
  List.EraseAfter(LIter);  // 删除 3 后面的 2 -> [3, 1]
  
  AssertEquals('Count 应为 2', 2, List.GetCount);
  AssertEquals('Front 仍为 3', 3, List.Front);
  
  // 验证: Pop 3, 应该得到 1
  List.PopFront;
  AssertEquals('第二个元素应为 1', 1, List.Front);
end;

procedure TTestCase_ForwardList_Full.Test_ForwardList_String_NoLeak;
var
  List: TStrForwardList;
  S: string;
begin
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  List := specialize MakeForwardList<string>;
  {$ELSE}
  List := specialize TForwardList<string>.Create;
  {$ENDIF}
  
  List.PushFront('Hello');
  List.PushFront('World');
  List.PushFront('Test');
  
  AssertEquals('Count 应为 3', 3, List.GetCount);
  
  S := List.PopFront;
  AssertEquals('应为 Test', 'Test', S);
  
  List.Clear;
  AssertTrue('Clear 后应为空', List.IsEmpty);
  
  // 测试通过且 HeapTrc 报告 0 泄漏即证明无内存泄漏
end;

initialization
  RegisterTest(TTestCase_ForwardList_Full);

end.
