{$CODEPAGE UTF8}
unit Test_fafafa_core_collections_node;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.base,
  fafafa.core.mem.allocator,
  fafafa.core.collections.node;

type

  { TTestCase_NodeBase - 节点基类测试 }
  TTestCase_NodeBase = class(TTestCase)
  private
    FAllocator: TAllocator;
    
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    
  published
    procedure Test_NodeBase_Create;
    procedure Test_NodeBase_Create_WithData;
    procedure Test_NodeBase_Create_NilAllocator;
    procedure Test_NodeBase_GetData;
    procedure Test_NodeBase_SetData;
    procedure Test_NodeBase_GetAllocator;
  end;

  { TTestCase_SingleLinkedNode - 单向链接节点测试 }
  TTestCase_SingleLinkedNode = class(TTestCase)
  private
    FAllocator: TAllocator;
    
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    
  published
    procedure Test_SingleLinkedNode_Create;
    procedure Test_SingleLinkedNode_Create_WithData;
    procedure Test_SingleLinkedNode_Create_WithNext;
    procedure Test_SingleLinkedNode_GetNext;
    procedure Test_SingleLinkedNode_SetNext;
    procedure Test_SingleLinkedNode_HasNext;
    procedure Test_SingleLinkedNode_InsertAfter;
    procedure Test_SingleLinkedNode_InsertAfter_NilNode;
    procedure Test_SingleLinkedNode_RemoveNext;
    procedure Test_SingleLinkedNode_Clone;
  end;

  { TTestCase_DoubleLinkedNode - 双向链接节点测试 }
  TTestCase_DoubleLinkedNode = class(TTestCase)
  private
    FAllocator: TAllocator;
    
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    
  published
    procedure Test_DoubleLinkedNode_Create;
    procedure Test_DoubleLinkedNode_Create_WithData;
    procedure Test_DoubleLinkedNode_Create_WithPrevNext;
    procedure Test_DoubleLinkedNode_GetPrev;
    procedure Test_DoubleLinkedNode_SetPrev;
    procedure Test_DoubleLinkedNode_HasPrev;
    procedure Test_DoubleLinkedNode_InsertBefore;
    procedure Test_DoubleLinkedNode_InsertBefore_NilNode;
    procedure Test_DoubleLinkedNode_RemovePrev;
    procedure Test_DoubleLinkedNode_Unlink;
    procedure Test_DoubleLinkedNode_Clone;
  end;

  { TTestCase_TreeNode - 树节点测试 }
  TTestCase_TreeNode = class(TTestCase)
  private
    FAllocator: TAllocator;
    
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    
  published
    procedure Test_TreeNode_Create;
    procedure Test_TreeNode_Create_WithData;
    procedure Test_TreeNode_Create_WithParent;
    procedure Test_TreeNode_GetParent;
    procedure Test_TreeNode_SetParent;
    procedure Test_TreeNode_GetChildCount;
    procedure Test_TreeNode_AddChild;
    procedure Test_TreeNode_AddChild_NilChild;
    procedure Test_TreeNode_GetChild;
    procedure Test_TreeNode_GetChild_OutOfRange;
    procedure Test_TreeNode_RemoveChild;
    procedure Test_TreeNode_RemoveChild_NotFound;
    procedure Test_TreeNode_IsRoot;
    procedure Test_TreeNode_IsLeaf;
    procedure Test_TreeNode_GetDepth;
    procedure Test_TreeNode_Clone;
  end;

implementation

type
  // 测试用的具体类型
  TIntegerNode = specialize TSingleLinkedNode<Integer>;
  TIntegerDoubleNode = specialize TDoubleLinkedNode<Integer>;
  TIntegerTreeNode = specialize TTreeNode<Integer>;
  
  IIntegerNode = specialize INode<Integer>;
  IIntegerSingleLinkedNode = specialize ISingleLinkedNode<Integer>;
  IIntegerDoubleLinkedNode = specialize IDoubleLinkedNode<Integer>;
  IIntegerTreeNode = specialize ITreeNode<Integer>;

{ TTestCase_NodeBase }

procedure TTestCase_NodeBase.SetUp;
begin
  FAllocator := GetDefaultAllocator;
end;

procedure TTestCase_NodeBase.TearDown;
begin
  // 不需要释放 FAllocator，它是全局单例
end;

procedure TTestCase_NodeBase.Test_NodeBase_Create;
var
  LNode: TIntegerNode;
begin
  LNode := TIntegerNode.Create(FAllocator);
  try
    AssertNotNull('节点应该创建成功', LNode);
    AssertSame('分配器应该正确设置', FAllocator, LNode.Allocator);
    AssertEquals('初始数据应该为0', 0, LNode.Data);
  finally
    LNode.Free;
  end;
end;

procedure TTestCase_NodeBase.Test_NodeBase_Create_WithData;
var
  LNode: TIntegerNode;
  LExpectedData: Integer;
begin
  LExpectedData := 42;
  LNode := TIntegerNode.Create(LExpectedData, FAllocator);
  try
    AssertNotNull('节点应该创建成功', LNode);
    AssertSame('分配器应该正确设置', FAllocator, LNode.Allocator);
    AssertEquals('数据应该正确设置', LExpectedData, LNode.Data);
  finally
    LNode.Free;
  end;
end;

procedure TTestCase_NodeBase.Test_NodeBase_Create_NilAllocator;
begin
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('创建节点时传入nil分配器应该抛出异常', EArgumentNil, 
    procedure begin
      TIntegerNode.Create(nil);
    end);
  {$ELSE}
  try
    TIntegerNode.Create(nil);
    Fail('创建节点时传入nil分配器应该抛出异常');
  except
    on E: EArgumentNil do
      ; // 期望的异常
    else
      Fail('应该抛出EArgumentNil异常');
  end;
  {$ENDIF}
end;

procedure TTestCase_NodeBase.Test_NodeBase_GetData;
var
  LNode: TIntegerNode;
  LExpectedData: Integer;
begin
  LExpectedData := 123;
  LNode := TIntegerNode.Create(LExpectedData, FAllocator);
  try
    AssertEquals('GetData应该返回正确的数据', LExpectedData, LNode.GetData);
  finally
    LNode.Free;
  end;
end;

procedure TTestCase_NodeBase.Test_NodeBase_SetData;
var
  LNode: TIntegerNode;
  LNewData: Integer;
begin
  LNode := TIntegerNode.Create(FAllocator);
  try
    LNewData := 456;
    LNode.SetData(LNewData);
    AssertEquals('SetData应该正确设置数据', LNewData, LNode.Data);
  finally
    LNode.Free;
  end;
end;

procedure TTestCase_NodeBase.Test_NodeBase_GetAllocator;
var
  LNode: TIntegerNode;
begin
  LNode := TIntegerNode.Create(FAllocator);
  try
    AssertSame('GetAllocator应该返回正确的分配器', FAllocator, LNode.GetAllocator);
  finally
    LNode.Free;
  end;
end;

{ TTestCase_SingleLinkedNode }

procedure TTestCase_SingleLinkedNode.SetUp;
begin
  FAllocator := GetDefaultAllocator;
end;

procedure TTestCase_SingleLinkedNode.TearDown;
begin
  // 不需要释放 FAllocator，它是全局单例
end;

procedure TTestCase_SingleLinkedNode.Test_SingleLinkedNode_Create;
var
  LNode: TIntegerNode;
begin
  LNode := TIntegerNode.Create(FAllocator);
  try
    AssertNotNull('节点应该创建成功', LNode);
    AssertNull('初始Next应该为nil', LNode.Next);
    AssertFalse('初始HasNext应该为False', LNode.HasNext);
  finally
    LNode.Free;
  end;
end;

procedure TTestCase_SingleLinkedNode.Test_SingleLinkedNode_Create_WithData;
var
  LNode: TIntegerNode;
  LExpectedData: Integer;
begin
  LExpectedData := 789;
  LNode := TIntegerNode.Create(LExpectedData, FAllocator);
  try
    AssertNotNull('节点应该创建成功', LNode);
    AssertEquals('数据应该正确设置', LExpectedData, LNode.Data);
    AssertNull('初始Next应该为nil', LNode.Next);
  finally
    LNode.Free;
  end;
end;

procedure TTestCase_SingleLinkedNode.Test_SingleLinkedNode_Create_WithNext;
var
  LNode1, LNode2: TIntegerNode;
begin
  LNode2 := TIntegerNode.Create(200, FAllocator);
  try
    LNode1 := TIntegerNode.Create(100, LNode2, FAllocator);
    try
      AssertNotNull('节点应该创建成功', LNode1);
      AssertEquals('数据应该正确设置', 100, LNode1.Data);
      AssertSame('Next应该正确设置', LNode2, LNode1.Next);
      AssertTrue('HasNext应该为True', LNode1.HasNext);
    finally
      LNode1.Free;
    end;
  finally
    LNode2.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_NodeBase);
  RegisterTest(TTestCase_SingleLinkedNode);
  RegisterTest(TTestCase_DoubleLinkedNode);
  RegisterTest(TTestCase_TreeNode);

end.
