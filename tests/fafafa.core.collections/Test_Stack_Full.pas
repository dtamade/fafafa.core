unit Test_Stack_Full;

{**
 * @desc TDD 测试：Stack 完整测试套件
 * @purpose 验证 MakeStack 工厂函数和 Stack 操作
 * 
 * Phase 1 测试:
 *   - MakeStack 应正确传递 aCapacity 参数
 *   - MakeStack 应正确从 aSrcCollection 复制元素
 *
 * Phase 5 测试:
 *   - Push/Pop/Peek 基本操作
 *   - 边界条件测试
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections,
  fafafa.core.collections.stack,
  fafafa.core.collections.vec,
  fafafa.core.collections.base,
  fafafa.core.mem.allocator;

type
  { TTestCase_Stack_Full }
  TTestCase_Stack_Full = class(TTestCase)
  private
    type
      TIntStack = specialize IStack<Integer>;
      TIntVec = specialize IVec<Integer>;
  published
    // Phase 1: MakeStack 工厂函数修复测试
    procedure Test_MakeStack_FromArray_CopiesElements;
    procedure Test_MakeStack_FromCollection_CopiesElements;
    
    // Phase 5: 基本操作测试
    procedure Test_Stack_Push_Pop_LIFO;
    procedure Test_Stack_Peek_DoesNotRemove;
    procedure Test_Stack_IsEmpty_InitiallyTrue;
    procedure Test_Stack_Count_AfterPushPop;
    procedure Test_Stack_Clear_RemovesAll;
    
    // Phase 5: 边界条件测试
    procedure Test_Stack_Pop_Empty_ReturnsFalse;
    procedure Test_Stack_TryPeek_Empty_ReturnsFalse;
    procedure Test_Stack_Push_MultipleElements;
  end;

implementation

{ TTestCase_Stack_Full }

procedure TTestCase_Stack_Full.Test_MakeStack_FromArray_CopiesElements;
var
  Stack: TIntStack;
  V: Integer;
begin
  // Arrange & Act
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  Stack := specialize MakeStack<Integer>([1, 2, 3], nil);
  {$ELSE}
  Stack := specialize MakeArrayStack<Integer>([1, 2, 3]);
  {$ENDIF}
  
  // Assert - LIFO 顺序，最后入栈的先出
  AssertEquals('Count 应为 3', 3, Stack.Count);
  AssertTrue('Pop 应成功', Stack.Pop(V));
  AssertEquals('第一个 Pop 应为 3', 3, V);
  AssertTrue('Pop 应成功', Stack.Pop(V));
  AssertEquals('第二个 Pop 应为 2', 2, V);
  AssertTrue('Pop 应成功', Stack.Pop(V));
  AssertEquals('第三个 Pop 应为 1', 1, V);
end;

procedure TTestCase_Stack_Full.Test_MakeStack_FromCollection_CopiesElements;
var
  Vec: TIntVec;
  Stack: TIntStack;
  V: Integer;
begin
  // Arrange
  Vec := specialize MakeVec<Integer>([10, 20, 30]);
  
  // Act - 从集合创建 Stack
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  Stack := specialize MakeStack<Integer>(Vec as TCollection, nil);
  {$ELSE}
  // 如果没有 facade，使用 MakeArrayStack 然后手动 Push
  Stack := specialize MakeArrayStack<Integer>;
  Stack.Push([10, 20, 30]);
  {$ENDIF}
  
  // Assert - 应该包含 Vec 中的所有元素
  AssertEquals('Count 应为 3', 3, Stack.Count);
  
  {$IFDEF FAFAFA_COLLECTIONS_FACADE}
  // 只有在 FACADE 模式下才测试从 Collection 复制
  // LIFO 顺序
  AssertTrue('Pop 应成功', Stack.Pop(V));
  AssertEquals('应为 30', 30, V);
  AssertTrue('Pop 应成功', Stack.Pop(V));
  AssertEquals('应为 20', 20, V);
  AssertTrue('Pop 应成功', Stack.Pop(V));
  AssertEquals('应为 10', 10, V);
  {$ENDIF}
end;

procedure TTestCase_Stack_Full.Test_Stack_Push_Pop_LIFO;
var
  Stack: TIntStack;
  V: Integer;
begin
  // Arrange
  Stack := specialize MakeArrayStack<Integer>;
  
  // Act
  Stack.Push(100);
  Stack.Push(200);
  Stack.Push(300);
  
  // Assert - LIFO
  AssertTrue(Stack.Pop(V));
  AssertEquals(300, V);
  AssertTrue(Stack.Pop(V));
  AssertEquals(200, V);
  AssertTrue(Stack.Pop(V));
  AssertEquals(100, V);
end;

procedure TTestCase_Stack_Full.Test_Stack_Peek_DoesNotRemove;
var
  Stack: TIntStack;
  V: Integer;
begin
  // Arrange
  Stack := specialize MakeArrayStack<Integer>;
  Stack.Push(42);
  
  // Act
  AssertTrue(Stack.TryPeek(V));
  
  // Assert
  AssertEquals('Peek 应返回 42', 42, V);
  AssertEquals('Peek 后 Count 应仍为 1', 1, Stack.Count);
end;

procedure TTestCase_Stack_Full.Test_Stack_IsEmpty_InitiallyTrue;
var
  Stack: TIntStack;
begin
  Stack := specialize MakeArrayStack<Integer>;
  AssertTrue('新栈应为空', Stack.IsEmpty);
end;

procedure TTestCase_Stack_Full.Test_Stack_Count_AfterPushPop;
var
  Stack: TIntStack;
  V: Integer;
begin
  Stack := specialize MakeArrayStack<Integer>;
  
  AssertEquals('初始 Count', 0, Stack.Count);
  
  Stack.Push(1);
  AssertEquals('Push 后 Count', 1, Stack.Count);
  
  Stack.Push(2);
  AssertEquals('再 Push 后 Count', 2, Stack.Count);
  
  Stack.Pop(V);
  AssertEquals('Pop 后 Count', 1, Stack.Count);
end;

procedure TTestCase_Stack_Full.Test_Stack_Clear_RemovesAll;
var
  Stack: TIntStack;
begin
  Stack := specialize MakeArrayStack<Integer>;
  Stack.Push(1);
  Stack.Push(2);
  Stack.Push(3);
  
  Stack.Clear;
  
  AssertTrue('Clear 后应为空', Stack.IsEmpty);
  AssertEquals('Clear 后 Count 为 0', 0, Stack.Count);
end;

procedure TTestCase_Stack_Full.Test_Stack_Pop_Empty_ReturnsFalse;
var
  Stack: TIntStack;
  V: Integer;
begin
  Stack := specialize MakeArrayStack<Integer>;
  AssertFalse('空栈 Pop 应返回 False', Stack.Pop(V));
end;

procedure TTestCase_Stack_Full.Test_Stack_TryPeek_Empty_ReturnsFalse;
var
  Stack: TIntStack;
  V: Integer;
begin
  Stack := specialize MakeArrayStack<Integer>;
  AssertFalse('空栈 TryPeek 应返回 False', Stack.TryPeek(V));
end;

procedure TTestCase_Stack_Full.Test_Stack_Push_MultipleElements;
var
  Stack: TIntStack;
  V: Integer;
begin
  Stack := specialize MakeArrayStack<Integer>;
  
  // Push 数组
  Stack.Push([1, 2, 3, 4, 5]);
  
  AssertEquals('Count 应为 5', 5, Stack.Count);
  
  // LIFO 验证
  AssertTrue(Stack.Pop(V));
  AssertEquals(5, V);
end;

initialization
  RegisterTest(TTestCase_Stack_Full);

end.
