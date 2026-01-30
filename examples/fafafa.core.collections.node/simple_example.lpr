program simple_example;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.node;

type
  TIntSingleNode = specialize TSingleLinkedNode<Integer>;
  TIntDoubleNode = specialize TDoubleLinkedNode<Integer>;
  TStringTreeNode = specialize TTreeNode<String>;

procedure DemoBasicNodeUsage;
var
  LNode1, LNode2, LNode3: TIntSingleNode;
  LCurrent: ^TIntSingleNode;
begin
  WriteLn('=== Basic Node Usage ===');
  
  // 初始化节点
  LNode1.Init(100);
  LNode2.Init(200);
  LNode3.Init(300);
  
  WriteLn('Initialized 3 nodes: 100, 200, 300');
  
  // 连接节点
  LNode1.SetNext(@LNode2);
  LNode2.SetNext(@LNode3);
  
  WriteLn('Connected nodes in sequence');
  
  // 遍历节点
  Write('Node sequence: ');
  LCurrent := @LNode1;
  while LCurrent <> nil do
  begin
    Write(LCurrent^.Data, ' ');
    LCurrent := Pointer(LCurrent^.GetNext);
  end;
  WriteLn('');
  
  // 测试节点属性
  WriteLn('Node1 has next: ', LNode1.HasNext);
  WriteLn('Node3 has next: ', LNode3.HasNext);
  
  WriteLn('');
end;

procedure DemoDoubleLinkedNode;
var
  LNode1, LNode2: TIntDoubleNode;
begin
  WriteLn('=== Double Linked Node ===');
  
  // 初始化节点
  LNode1.Init(1000);
  LNode2.Init(2000);
  
  WriteLn('Initialized 2 double nodes: 1000, 2000');
  
  // 双向连接
  LNode1.SetNext(@LNode2);
  LNode2.SetPrev(@LNode1);
  
  WriteLn('Connected nodes bidirectionally');
  
  // 测试双向连接
  WriteLn('Node1 has next: ', LNode1.HasNext);
  WriteLn('Node1 has prev: ', LNode1.HasPrev);
  WriteLn('Node2 has next: ', LNode2.HasNext);
  WriteLn('Node2 has prev: ', LNode2.HasPrev);
  
  WriteLn('');
end;

procedure DemoTreeNode;
var
  LRoot, LChild1, LChild2: TStringTreeNode;
begin
  WriteLn('=== Tree Node ===');
  
  // 初始化节点
  LRoot.Init('Root');
  LChild1.Init('Child1');
  LChild2.Init('Child2');
  
  WriteLn('Initialized tree nodes: Root, Child1, Child2');
  
  // 设置树结构
  LChild1.SetParent(@LRoot);
  LChild2.SetParent(@LRoot);
  LRoot.SetFirstChild(@LChild1);
  LChild1.SetNextSibling(@LChild2);
  
  WriteLn('Set up tree structure');
  
  // 测试树属性
  WriteLn('Root is root: ', LRoot.IsRoot);
  WriteLn('Root is leaf: ', LRoot.IsLeaf);
  WriteLn('Root has children: ', LRoot.HasChildren);
  WriteLn('Child1 is root: ', LChild1.IsRoot);
  WriteLn('Child1 is leaf: ', LChild1.IsLeaf);
  WriteLn('Child1 has siblings: ', LChild1.HasSiblings);
  
  WriteLn('');
end;

begin
  WriteLn('Simple Node Example');
  WriteLn('===================');
  WriteLn('');
  
  try
    DemoBasicNodeUsage;
    DemoDoubleLinkedNode;
    DemoTreeNode;
    
    WriteLn('All demos completed successfully!');
    
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
