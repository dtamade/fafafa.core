{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

program test_treemap_minimal;

uses
  SysUtils,
  fafafa.core.mem.allocator;

type
  { 最小化的红黑树节点 - 直接复制自 treemap.pas }
  TMinimalNode = record
    Key: Integer;
    Value: string;
    Left: Pointer;
    Right: Pointer;
    Parent: Pointer;
    Color: UInt8;  // 0 = Red, 1 = Black
  end;
  PMinimalNode = ^TMinimalNode;

  { 最小化的红黑树实现 - 只测试FixInsert逻辑 }
  TMinimalRBTree = class
  private
    FRoot: PMinimalNode;
    FCount: SizeUInt;
    FAllocator: IAllocator;

    procedure RotateLeft(aNode: PMinimalNode);
    procedure RotateRight(aNode: PMinimalNode);
    function AllocateNode(const aKey: Integer; const aValue: string): PMinimalNode;
    procedure DeallocateNode(aNode: PMinimalNode);
    procedure FixInsert(aNode: PMinimalNode);
    function InsertNode(const aKey: Integer; const aValue: string): PMinimalNode;
    procedure FreeAllNodes(aNode: PMinimalNode);

  public
    constructor Create;
    destructor Destroy; override;
    procedure Put(const aKey: Integer; const aValue: string);
    procedure Clear;
    function GetCount: SizeUInt;
  end;

constructor TMinimalRBTree.Create;
begin
  inherited Create;
  FRoot := nil;
  FCount := 0;
  FAllocator := GetRtlAllocator;
end;

destructor TMinimalRBTree.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TMinimalRBTree.AllocateNode(const aKey: Integer; const aValue: string): PMinimalNode;
begin
  Result := FAllocator.AllocMem(SizeOf(Result^));
  Result^.Key := aKey;
  Result^.Value := aValue;
  Result^.Left := nil;
  Result^.Right := nil;
  Result^.Parent := nil;
  Result^.Color := 0;  // Red
end;

procedure TMinimalRBTree.DeallocateNode(aNode: PMinimalNode);
begin
  if aNode <> nil then
  begin
    Finalize(aNode^.Value);
    FAllocator.FreeMem(aNode);
  end;
end;

procedure TMinimalRBTree.RotateLeft(aNode: PMinimalNode);
var
  LRight: PMinimalNode;
begin
  if aNode = nil then Exit;
  LRight := PMinimalNode(aNode^.Right);
  aNode^.Right := LRight^.Left;

  if LRight^.Left <> nil then
    PMinimalNode(LRight^.Left)^.Parent := aNode;

  LRight^.Parent := aNode^.Parent;

  if aNode^.Parent = nil then
    FRoot := LRight
  else if aNode = PMinimalNode(aNode^.Parent)^.Left then
    PMinimalNode(aNode^.Parent)^.Left := LRight
  else
    PMinimalNode(aNode^.Parent)^.Right := LRight;

  LRight^.Left := aNode;
  aNode^.Parent := LRight;
end;

procedure TMinimalRBTree.RotateRight(aNode: PMinimalNode);
var
  LLeft: PMinimalNode;
begin
  if aNode = nil then Exit;
  LLeft := PMinimalNode(aNode^.Left);
  aNode^.Left := LLeft^.Right;

  if LLeft^.Right <> nil then
    PMinimalNode(LLeft^.Right)^.Parent := aNode;

  LLeft^.Parent := aNode^.Parent;

  if aNode^.Parent = nil then
    FRoot := LLeft
  else if aNode = PMinimalNode(aNode^.Parent)^.Left then
    PMinimalNode(aNode^.Parent)^.Left := LLeft
  else
    PMinimalNode(aNode^.Parent)^.Right := LLeft;

  LLeft^.Right := aNode;
  aNode^.Parent := LLeft;
end;

procedure TMinimalRBTree.FixInsert(aNode: PMinimalNode);
var
  LUncle, LGrandparent: PMinimalNode;
begin
  { 这是修复后的版本 - 包含 nil 保护 }
  while (aNode <> FRoot) and (aNode^.Parent <> nil) and (PMinimalNode(aNode^.Parent)^.Color = 0) do
  begin
    { ✅ 预取祖父节点并检查 nil }
    LGrandparent := PMinimalNode(aNode^.Parent)^.Parent;
    if LGrandparent = nil then
      Break;  // 父节点没有父节点，停止

    if aNode^.Parent = LGrandparent^.Left then
    begin
      LUncle := LGrandparent^.Right;
      if (LUncle <> nil) and (PMinimalNode(LUncle)^.Color = 0) then
      begin
        PMinimalNode(aNode^.Parent)^.Color := 1;
        PMinimalNode(LUncle)^.Color := 1;
        LGrandparent^.Color := 0;
        aNode := LGrandparent;
      end
      else
      begin
        if aNode = PMinimalNode(aNode^.Parent)^.Right then
        begin
          aNode := aNode^.Parent;
          RotateLeft(aNode);
        end;
        PMinimalNode(aNode^.Parent)^.Color := 1;
        { ✅ 检查后访问祖父节点 }
        if PMinimalNode(aNode^.Parent)^.Parent <> nil then
          PMinimalNode(PMinimalNode(aNode^.Parent)^.Parent)^.Color := 0;
        if PMinimalNode(aNode^.Parent)^.Parent <> nil then
          RotateRight(PMinimalNode(aNode^.Parent)^.Parent);
        aNode := FRoot;
      end;
    end
    else
    begin
      LUncle := LGrandparent^.Left;
      if (LUncle <> nil) and (PMinimalNode(LUncle)^.Color = 0) then
      begin
        PMinimalNode(aNode^.Parent)^.Color := 1;
        PMinimalNode(LUncle)^.Color := 1;
        LGrandparent^.Color := 0;
        aNode := LGrandparent;
      end
      else
      begin
        if aNode = PMinimalNode(aNode^.Parent)^.Left then
        begin
          aNode := aNode^.Parent;
          RotateRight(aNode);
        end;
        PMinimalNode(aNode^.Parent)^.Color := 1;
        { ✅ 检查后访问祖父节点 }
        if PMinimalNode(aNode^.Parent)^.Parent <> nil then
          PMinimalNode(PMinimalNode(aNode^.Parent)^.Parent)^.Color := 0;
        if PMinimalNode(aNode^.Parent)^.Parent <> nil then
          RotateLeft(PMinimalNode(aNode^.Parent)^.Parent);
        aNode := FRoot;
      end;
    end;
  end;
  if FRoot <> nil then
    PMinimalNode(FRoot)^.Color := 1;
end;

function TMinimalRBTree.InsertNode(const aKey: Integer; const aValue: string): PMinimalNode;
var
  LCurrent, LParent: PMinimalNode;
begin
  LCurrent := FRoot;
  LParent := nil;

  { 查找插入位置 }
  while LCurrent <> nil do
  begin
    LParent := LCurrent;
    if aKey < LCurrent^.Key then
      LCurrent := PMinimalNode(LCurrent^.Left)
    else if aKey > LCurrent^.Key then
      LCurrent := PMinimalNode(LCurrent^.Right)
    else
    begin
      { 键已存在，更新值 }
      LCurrent^.Value := aValue;
      Exit(LCurrent);
    end;
  end;

  { 创建新节点 }
  Result := AllocateNode(aKey, aValue);
  Result^.Parent := LParent;

  if LParent = nil then
    FRoot := Result
  else if aKey < LParent^.Key then
    LParent^.Left := Result
  else
    LParent^.Right := Result;

  Inc(FCount);

  { 修复红黑树性质 }
  FixInsert(Result);
end;

procedure TMinimalRBTree.Put(const aKey: Integer; const aValue: string);
begin
  InsertNode(aKey, aValue);
end;

procedure TMinimalRBTree.FreeAllNodes(aNode: PMinimalNode);
begin
  if aNode = nil then Exit;
  FreeAllNodes(PMinimalNode(aNode^.Left));
  FreeAllNodes(PMinimalNode(aNode^.Right));
  DeallocateNode(aNode);
end;

procedure TMinimalRBTree.Clear;
begin
  if FRoot <> nil then
    FreeAllNodes(FRoot);
  FRoot := nil;
  FCount := 0;
end;

function TMinimalRBTree.GetCount: SizeUInt;
begin
  Result := FCount;
end;

procedure Test1_BasicInsert;
var
  Tree: TMinimalRBTree;
begin
  WriteLn('======================================');
  WriteLn('TreeMap Minimal Test - FixInsert Verification');
  WriteLn('======================================');
  WriteLn('[Test 1] Basic insertion (triggers FixInsert)');

  Tree := TMinimalRBTree.Create;
  try
    { 第一次插入 - Root }
    Tree.Put(10, 'ten');
    WriteLn('  Pass: First insertion (root)');

    { 第二次插入 - 左子节点 }
    Tree.Put(5, 'five');
    WriteLn('  Pass: Second insertion (left child)');

    { 第三次插入 - 触发 FixInsert 中的祖父节点访问 }
    Tree.Put(15, 'fifteen');
    WriteLn('  Pass: Third insertion (triggers grandparent access)');

    { 第四次插入 - 更复杂的情况 }
    Tree.Put(3, 'three');
    WriteLn('  Pass: Fourth insertion');

    { 第五次插入 - 触发旋转 }
    Tree.Put(7, 'seven');
    WriteLn('  Pass: Fifth insertion (triggers rotation)');

    WriteLn('  ✅ Count = ', Tree.GetCount);
  finally
    Tree.Free;
  end;
end;

procedure Test2_StressTest;
var
  Tree: TMinimalRBTree;
  I: Integer;
begin
  WriteLn('[Test 2] Stress test (100 insertions)');

  Tree := TMinimalRBTree.Create;
  try
    for I := 1 to 100 do
      Tree.Put(I, IntToStr(I));

    WriteLn('  ✅ Count = ', Tree.GetCount);
  finally
    Tree.Free;
  end;
end;

procedure Test3_Clear;
var
  Tree: TMinimalRBTree;
begin
  WriteLn('[Test 3] Clear operation');

  Tree := TMinimalRBTree.Create;
  try
    Tree.Put(1, 'one');
    Tree.Put(2, 'two');
    Tree.Put(3, 'three');
    Tree.Clear;

    WriteLn('  ✅ Count after clear = ', Tree.GetCount);
  finally
    Tree.Free;
  end;
end;

begin
  Test1_BasicInsert;
  Test2_StressTest;
  Test3_Clear;

  WriteLn('======================================');
  WriteLn('All tests passed!');
  WriteLn('======================================');
  WriteLn('Waiting for HeapTrc report...');
end.
