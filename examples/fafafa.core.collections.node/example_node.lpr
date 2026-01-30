program example_node;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.mem.allocator,
  fafafa.core.collections.node;

type
  // 定义具体的节点类型
  TIntSingleNode = specialize TSingleLinkedNode<Integer>;
  TIntDoubleNode = specialize TDoubleLinkedNode<Integer>;
  TIntTreeNode = specialize TTreeNode<Integer>;
  TStringTreeNode = specialize TTreeNode<String>;

  // 定义节点管理器类型
  TIntNodeManager = specialize TNodeManager<Integer>;
  TStringNodeManager = specialize TNodeManager<String>;

procedure DemoSingleLinkedNodes;
var
  LAllocator: IAllocator;
  LNodeManager: TIntNodeManager;
  LNode1, LNode2, LNode3: ^TIntSingleNode;
  LCurrent: ^TIntSingleNode;
begin
  WriteLn('=== Single Linked Nodes Demo ===');

  LAllocator := GetRtlAllocator;
  LNodeManager := TIntNodeManager.Create(LAllocator);
  try
    // 创建节点
    LNode1 := LNodeManager.CreateSingleNode(100);
    LNode2 := LNodeManager.CreateSingleNode(200);
    LNode3 := LNodeManager.CreateSingleNode(300);

    WriteLn('Created 3 nodes with data: 100, 200, 300');

    // 连接节点形成链表
    LNode1^.SetNext(LNode2);
    LNode2^.SetNext(LNode3);

    WriteLn('Linked nodes together');

    // 遍历链表
    Write('Traversing list: ');
    LCurrent := LNode1;
    while LCurrent <> nil do
    begin
      Write(LCurrent^.Data, ' ');
      LCurrent := Pointer(LCurrent^.GetNext);
    end;
    WriteLn('');

    // 清理
    LNodeManager.DestroySingleNode(LNode1);
    LNodeManager.DestroySingleNode(LNode2);
    LNodeManager.DestroySingleNode(LNode3);

    WriteLn('Cleaned up all nodes');

  finally
    LNodeManager.Free;
  end;

  WriteLn('');
end;

procedure DemoDoubleLinkedNodes;
var
  LAllocator: IAllocator;
  LNodeManager: TIntNodeManager;
  LNode1, LNode2, LNode3: ^TIntDoubleNode;
  LCurrent: ^TIntDoubleNode;
begin
  WriteLn('=== Double Linked Nodes Demo ===');

  LAllocator := GetRtlAllocator;
  LNodeManager := TIntNodeManager.Create(LAllocator);
  try
    // 创建节点
    LNode1 := LNodeManager.CreateDoubleNode(1000);
    LNode2 := LNodeManager.CreateDoubleNode(2000);
    LNode3 := LNodeManager.CreateDoubleNode(3000);

    WriteLn('Created 3 double nodes with data: 1000, 2000, 3000');

    // 连接节点形成双向链表
    LNode1^.SetNext(LNode2);
    LNode2^.SetPrev(LNode1);
    LNode2^.SetNext(LNode3);
    LNode3^.SetPrev(LNode2);

    WriteLn('Linked nodes bidirectionally');

    // 正向遍历
    Write('Forward traversal: ');
    LCurrent := LNode1;
    while LCurrent <> nil do
    begin
      Write(LCurrent^.Data, ' ');
      LCurrent := Pointer(LCurrent^.GetNext);
    end;
    WriteLn('');

    // 反向遍历
    Write('Backward traversal: ');
    LCurrent := LNode3;
    while LCurrent <> nil do
    begin
      Write(LCurrent^.Data, ' ');
      LCurrent := Pointer(LCurrent^.GetPrev);
    end;
    WriteLn('');

    // 测试 Unlink 操作
    WriteLn('Unlinking middle node...');
    LNode2^.Unlink;

    Write('After unlink - Forward traversal: ');
    LCurrent := LNode1;
    while LCurrent <> nil do
    begin
      Write(LCurrent^.Data, ' ');
      LCurrent := Pointer(LCurrent^.GetNext);
    end;
    WriteLn('');

    // 清理
    LNodeManager.DestroyDoubleNode(LNode1);
    LNodeManager.DestroyDoubleNode(LNode2);
    LNodeManager.DestroyDoubleNode(LNode3);

    WriteLn('Cleaned up all nodes');

  finally
    LNodeManager.Free;
  end;

  WriteLn('');
end;

procedure DemoTreeNodes;
var
  LAllocator: IAllocator;
  LNodeManager: TStringNodeManager;
  LRoot, LChild1, LChild2, LGrandChild: ^TStringTreeNode;
begin
  WriteLn('=== Tree Nodes Demo ===');

  LAllocator := GetRtlAllocator;
  LNodeManager := TStringNodeManager.Create(LAllocator);
  try
    // 创建树节点
    LRoot := LNodeManager.CreateTreeNode('Root');
    LChild1 := LNodeManager.CreateTreeNode('Child1', LRoot);
    LChild2 := LNodeManager.CreateTreeNode('Child2', LRoot);
    LGrandChild := LNodeManager.CreateTreeNode('GrandChild', LChild1);

    WriteLn('Created tree structure:');
    WriteLn('  Root');
    WriteLn('  ├── Child1');
    WriteLn('  │   └── GrandChild');
    WriteLn('  └── Child2');

    // 设置树结构
    LRoot^.SetFirstChild(LChild1);
    LChild1^.SetNextSibling(LChild2);
    LChild1^.SetFirstChild(LGrandChild);

    // 测试节点属性
    WriteLn('Node properties:');
    WriteLn('  Root is root: ', LRoot^.IsRoot);
    WriteLn('  Root is leaf: ', LRoot^.IsLeaf);
    WriteLn('  Root has children: ', LRoot^.HasChildren);
    WriteLn('  Child1 is root: ', LChild1^.IsRoot);
    WriteLn('  Child1 is leaf: ', LChild1^.IsLeaf);
    WriteLn('  Child1 has siblings: ', LChild1^.HasSiblings);
    WriteLn('  GrandChild is leaf: ', LGrandChild^.IsLeaf);

    // 清理
    LNodeManager.DestroyTreeNode(LRoot);
    LNodeManager.DestroyTreeNode(LChild1);
    LNodeManager.DestroyTreeNode(LChild2);
    LNodeManager.DestroyTreeNode(LGrandChild);

    WriteLn('Cleaned up all tree nodes');

  finally
    LNodeManager.Free;
  end;

  WriteLn('');
end;

procedure DemoDirectNodeUsage;
var
  LNode1, LNode2: TIntSingleNode;
  LDoubleNode: TIntDoubleNode;
  LTreeNode: TIntTreeNode;
begin
  WriteLn('=== Direct Node Usage Demo ===');

  // 直接使用节点 record，无需内存管理器
  LNode1.Init(42);
  LNode2.Init(84);

  WriteLn('Initialized nodes with data: ', LNode1.Data, ', ', LNode2.Data);

  // 连接节点
  LNode1.SetNext(@LNode2);

  WriteLn('Node1 has next: ', LNode1.HasNext);
  WriteLn('Node2 has next: ', LNode2.HasNext);

  // 双向节点
  LDoubleNode.Init(999);
  WriteLn('Double node data: ', LDoubleNode.Data);
  WriteLn('Double node has prev: ', LDoubleNode.HasPrev);
  WriteLn('Double node has next: ', LDoubleNode.HasNext);

  // 树节点
  LTreeNode.Init(777);
  WriteLn('Tree node data: ', LTreeNode.Data);
  WriteLn('Tree node is root: ', LTreeNode.IsRoot);
  WriteLn('Tree node is leaf: ', LTreeNode.IsLeaf);

  // 清理
  LNode1.Clear;
  LNode2.Clear;
  LDoubleNode.Clear;
  LTreeNode.Clear;

  WriteLn('Cleared all nodes');
  WriteLn('');
end;

begin
  WriteLn('fafafa.core.collections.node Example');
  WriteLn('====================================');
  WriteLn('');

  try
    DemoDirectNodeUsage;
    DemoSingleLinkedNodes;
    DemoDoubleLinkedNodes;
    DemoTreeNodes;

    WriteLn('All demos completed successfully!');

  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      ExitCode := 1;
    end;
  end;

  WriteLn('Press Enter to exit...');
  ReadLn;
end.
