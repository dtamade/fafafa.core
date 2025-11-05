unit fafafa.core.collections.treemap;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.math,
  fafafa.core.mem.utils,
  fafafa.core.mem.allocator,
  fafafa.core.collections.base,
  fafafa.core.collections.elementManager,
  fafafa.core.collections.arr;

type

  {** TMapEntry<K,V> - Key-Value pair record }
  generic TMapEntry<K,V> = record
    Key: K;
    Value: V;
  end;

  {** TKeyValueCallback - Callback for key-value pairs }
  generic TKeyValueCallback<K, V> = procedure(const aEntry: specialize TMapEntry<K, V>; aData: Pointer);

  {**
   * ITreeMap<K,V>
   *
   * @desc 红黑树实现的有序键值对映射
   * @param K 键类型（必须支持比较操作）
   * @param V 值类型
   * @note
   *   - 支持范围查询（GetRange、GetLowerBound、GetUpperBound）
   *   - 支持 floor/ceiling 操作
   *   - O(log n) 插入、删除、查找
   *   - 纯数据管理，无并发安全（职责分离）
   *}
  generic ITreeMap<K, V> = interface(specialize IGenericCollection<specialize TMapEntry<K, V>>)
    ['{A1B2C3D4-E5F6-4789-ABCD-123456789ABC}']

    function GetLowerBound(const aKey: K; out aValue: V): Boolean; overload;
    function GetUpperBound(const aKey: K; out aValue: V): Boolean; overload;
    function GetRange(const aLow, aHigh: K; const aCallback: specialize TKeyValueCallback<K, V>): Boolean;
    function Ceiling(const aKey: K; out aValue: V): Boolean;
    function Floor(const aKey: K; out aValue: V): Boolean;
    function Get(const aKey: K; out aValue: V): Boolean;
    function Put(const aKey: K; const aValue: V): Boolean;
    function Remove(const aKey: K): Boolean;
    function ContainsKey(const aKey: K): Boolean;
    function GetKeyCount: SizeUInt;

    function GetKeys: TCollection;
    function GetValues: TCollection;

    procedure Clear;
  end;

  { TRedBlackTree 节点 }
  generic TRedBlackTreeNode<K, V> = record
    Key: K;
    Value: V;
    Left: Pointer;
    Right: Pointer;
    Parent: Pointer;
    Color: UInt8;  // 0 = Red, 1 = Black
  end;

  generic TRedBlackTree<K, V> = class
  type
    PNode = ^specialize TRedBlackTreeNode<K, V>;
    TNodeArray = array of PNode;
    TMapEntryType = specialize TMapEntry<K, V>;
    TElementManagerType = specialize TElementManager<specialize TMapEntry<K, V>>;

  private
    FRoot: PNode;
    FCount: SizeUInt;
    FAllocator: IAllocator;
    FElementManager: TElementManagerType;
    FCompareMethod: specialize TCompareFunc<K>;

    { 红黑树操作 }
    procedure RotateLeft(aNode: PNode);
    procedure RotateRight(aNode: PNode);
    function InsertNode(const aKey: K; const aValue: V; out aExisted: Boolean): PNode;
    function DeleteNode(const aKey: K): Boolean; deprecated 'Use Remove instead';
    function FindNode(const aKey: K): PNode;
    function GetMinimum(aNode: PNode): PNode;
    function GetMaximum(aNode: PNode): PNode;
    function GetSuccessor(aNode: PNode): PNode;
    function GetPredecessor(aNode: PNode): PNode;
    function GetLowerBoundNode(const aKey: K): PNode;
    function GetUpperBoundNode(const aKey: K): PNode;

    procedure FixInsert(aNode: PNode);
    procedure FixDelete(aNode: PNode);

    procedure Transplant(aU, aV: PNode);
    procedure InOrderTraversal(aNode: PNode; const aCallback: specialize TKeyValueCallback<K, V>);

    function AllocateNode(const aKey: K; const aValue: V): PNode;
    procedure DeallocateNode(aNode: PNode);
    procedure FreeNodeAndChildren(aNode: PNode);

  public
    constructor Create(const aAllocator: IAllocator; const aCompare: specialize TCompareFunc<K>);
    destructor Destroy; override;

    { API }
    function Get(const aKey: K; out aValue: V): Boolean;
    function Put(const aKey: K; const aValue: V): Boolean;
    function Remove(const aKey: K): Boolean;
    function ContainsKey(const aKey: K): Boolean;
    function GetCount: SizeUInt;

    function GetLowerBound(const aKey: K; out aValue: V): Boolean;
    function GetUpperBound(const aKey: K; out aValue: V): Boolean;
    function GetRange(const aLow, aHigh: K; const aCallback: specialize TKeyValueCallback<K, V>): Boolean;
    function Ceiling(const aKey: K; out aValue: V): Boolean;
    function Floor(const aKey: K; out aValue: V): Boolean;

    function GetKeys: TCollection;
    function GetValues: TCollection;

    procedure Clear;
  end;

  {**
   * TTreeMap<K,V>
   *
   * @desc 红黑树实现的有序键值对映射
   * @param K 键类型（必须支持比较操作）
   * @param V 值类型
   *}
  generic TTreeMap<K, V> = class(specialize TGenericCollection<specialize TMapEntry<K, V>>, specialize ITreeMap<K, V>)

  type
    PNode = specialize TRedBlackTreeNode<K, V>;
    PNodeArray = array of PNode;
    TRedBlackTreeType = specialize TRedBlackTree<K, V>;

  private
    FTree: TRedBlackTreeType;

  protected
    function GetCount: SizeUInt; override;

  public
    constructor Create(const aAllocator: IAllocator = nil; const aCompare: specialize TCompareFunc<K> = nil);
    destructor Destroy; override;

    { ITreeMap 接口实现 }
    function GetLowerBound(const aKey: K; out aValue: V): Boolean; overload;
    function GetUpperBound(const aKey: K; out aValue: V): Boolean; overload;
    function GetRange(const aLow, aHigh: K; const aCallback: specialize TKeyValueCallback<K, V>): Boolean;
    function Ceiling(const aKey: K; out aValue: V): Boolean;
    function Floor(const aKey: K; out aValue: V): Boolean;

    function Get(const aKey: K; out aValue: V): Boolean;
    function Put(const aKey: K; const aValue: V): Boolean;
    function Remove(const aKey: K): Boolean;
    function ContainsKey(const aKey: K): Boolean;
    function GetKeyCount: SizeUInt;

    function GetKeys: TCollection;
    function GetValues: TCollection;

    procedure Clear; override;
  end;

implementation

{ TRedBlackTree }

constructor TRedBlackTree.Create(const aAllocator: IAllocator; const aCompare: specialize TCompareFunc<K>);
begin
  inherited Create;
  FRoot := nil;
  FCount := 0;
  FAllocator := aAllocator;
  if FAllocator = nil then
    FAllocator := GetRtlAllocator;

  FElementManager := TElementManagerType.Create(FAllocator);

  if Assigned(aCompare) then
    FCompareMethod := aCompare
  else
    raise EArgumentNil.Create('Compare function cannot be nil');
end;

destructor TRedBlackTree.Destroy;
begin
  Clear;
  FElementManager.Free;
  inherited Destroy;
end;

function TRedBlackTree.AllocateNode(const aKey: K; const aValue: V): PNode;
begin
  Result := FAllocator.AllocMem(SizeOf(Result^));
  Result^.Key := aKey;
  Result^.Value := aValue;
  Result^.Left := nil;
  Result^.Right := nil;
  Result^.Parent := nil;
  Result^.Color := 0;  // Red
end;

procedure TRedBlackTree.DeallocateNode(aNode: PNode);
begin
  if aNode <> nil then
  begin
    { 在释放内存前 Finalize 键值（特别是字符串等引用类型） }
    Finalize(aNode^.Key);
    Finalize(aNode^.Value);
    FAllocator.FreeMem(aNode);
  end;
end;

procedure TRedBlackTree.RotateLeft(aNode: PNode);
var
  LRight: PNode;
begin
  if aNode = nil then Exit;
  LRight := PNode(aNode^.Right);
  aNode^.Right := LRight^.Left;

  if LRight^.Left <> nil then
    PNode(LRight^.Left)^.Parent := aNode;

  LRight^.Parent := aNode^.Parent;

  if aNode^.Parent = nil then
    FRoot := LRight
  else if aNode = PNode(aNode^.Parent)^.Left then
    PNode(aNode^.Parent)^.Left := LRight
  else
    PNode(aNode^.Parent)^.Right := LRight;

  LRight^.Left := aNode;
  aNode^.Parent := LRight;
end;

procedure TRedBlackTree.RotateRight(aNode: PNode);
var
  LLeft: PNode;
begin
  if aNode = nil then Exit;
  LLeft := PNode(aNode^.Left);
  aNode^.Left := LLeft^.Right;

  if LLeft^.Right <> nil then
    PNode(LLeft^.Right)^.Parent := aNode;

  LLeft^.Parent := aNode^.Parent;

  if aNode^.Parent = nil then
    FRoot := LLeft
  else if aNode = PNode(aNode^.Parent)^.Left then
    PNode(aNode^.Parent)^.Left := LLeft
  else
    PNode(aNode^.Parent)^.Right := LLeft;

  LLeft^.Right := aNode;
  aNode^.Parent := LLeft;
end;

procedure TRedBlackTree.FixInsert(aNode: PNode);
var
  LUncle, LGrandparent: PNode;
begin
  // Fix red-black tree properties after insertion
  while (aNode <> FRoot) and (aNode^.Parent <> nil) and (PNode(aNode^.Parent)^.Color = 0) do
  begin
    LGrandparent := PNode(aNode^.Parent)^.Parent;
    if LGrandparent = nil then
      Break;  // Parent has no parent, stop

    if aNode^.Parent = LGrandparent^.Left then
    begin
      LUncle := LGrandparent^.Right;
      if (LUncle <> nil) and (PNode(LUncle)^.Color = 0) then
      begin
        PNode(aNode^.Parent)^.Color := 1;
        PNode(LUncle)^.Color := 1;
        LGrandparent^.Color := 0;
        aNode := LGrandparent;
      end
      else
      begin
        if aNode = PNode(aNode^.Parent)^.Right then
        begin
          aNode := aNode^.Parent;
          RotateLeft(aNode);
        end;
        PNode(aNode^.Parent)^.Color := 1;
        if PNode(aNode^.Parent)^.Parent <> nil then
          PNode(PNode(aNode^.Parent)^.Parent)^.Color := 0;
        if PNode(aNode^.Parent)^.Parent <> nil then
          RotateRight(PNode(aNode^.Parent)^.Parent);
        aNode := FRoot;
      end;
    end
    else
    begin
      LUncle := LGrandparent^.Left;
      if (LUncle <> nil) and (PNode(LUncle)^.Color = 0) then
      begin
        PNode(aNode^.Parent)^.Color := 1;
        PNode(LUncle)^.Color := 1;
        LGrandparent^.Color := 0;
        aNode := LGrandparent;
      end
      else
      begin
        if aNode = PNode(aNode^.Parent)^.Left then
        begin
          aNode := aNode^.Parent;
          RotateRight(aNode);
        end;
        PNode(aNode^.Parent)^.Color := 1;
        if PNode(aNode^.Parent)^.Parent <> nil then
          PNode(PNode(aNode^.Parent)^.Parent)^.Color := 0;
        if PNode(aNode^.Parent)^.Parent <> nil then
          RotateLeft(PNode(aNode^.Parent)^.Parent);
        aNode := FRoot;
      end;
    end;
  end;
  if FRoot <> nil then
    PNode(FRoot)^.Color := 1;
end;

function TRedBlackTree.InsertNode(const aKey: K; const aValue: V; out aExisted: Boolean): PNode;
var
  LCurrent, LParent: PNode;
  LCompareResult: SizeInt;
begin
  LCurrent := FRoot;
  LParent := nil;

  while LCurrent <> nil do
  begin
    LParent := LCurrent;
    LCompareResult := FCompareMethod(aKey, LCurrent^.Key, nil);

    if LCompareResult = 0 then
    begin
      { 键已存在，更新值 }
      LCurrent^.Value := aValue;
      aExisted := True;
      Exit(LCurrent);
    end
    else if LCompareResult < 0 then
      LCurrent := PNode(LCurrent^.Left)
    else
      LCurrent := PNode(LCurrent^.Right);
  end;

  { 创建新节点 }
  Result := AllocateNode(aKey, aValue);
  Result^.Parent := LParent;

  if LParent = nil then
    FRoot := Result
  else if FCompareMethod(aKey, LParent^.Key, nil) < 0 then
    LParent^.Left := Result
  else
    LParent^.Right := Result;

  aExisted := False;
  Inc(FCount);

  { 修复红黑树性质 }
  FixInsert(Result);
end;

procedure TRedBlackTree.Transplant(aU, aV: PNode);
begin
  if aU^.Parent = nil then
    FRoot := aV
  else if aU = PNode(aU^.Parent)^.Left then
    PNode(aU^.Parent)^.Left := aV
  else
    PNode(aU^.Parent)^.Right := aV;

  if aV <> nil then
    aV^.Parent := aU^.Parent;
end;

function TRedBlackTree.GetMinimum(aNode: PNode): PNode;
begin
  Result := aNode;
  while Result^.Left <> nil do
    Result := PNode(Result^.Left);
end;

function TRedBlackTree.GetMaximum(aNode: PNode): PNode;
begin
  Result := aNode;
  while Result^.Right <> nil do
    Result := PNode(Result^.Right);
end;

procedure TRedBlackTree.FixDelete(aNode: PNode);
var
  LSibling: PNode;
begin
  while (aNode <> FRoot) and (aNode^.Color = 1) do
  begin
    if aNode = PNode(aNode^.Parent)^.Left then
    begin
      LSibling := PNode(aNode^.Parent)^.Right;
      if (LSibling <> nil) and (PNode(LSibling)^.Color = 0) then
      begin
        PNode(LSibling)^.Color := 1;
        PNode(aNode^.Parent)^.Color := 0;
        RotateLeft(aNode^.Parent);
        LSibling := PNode(aNode^.Parent)^.Right;
      end;

      if (LSibling <> nil) and
         (PNode(LSibling)^.Left = nil) and (PNode(LSibling)^.Right = nil) then
      begin
        PNode(LSibling)^.Color := 0;
        aNode := aNode^.Parent;
      end
      else if (LSibling <> nil) then
      begin
        if (PNode(LSibling)^.Right = nil) or
           (PNode(PNode(LSibling)^.Right)^.Color = 1) then
        begin
          if PNode(LSibling)^.Left <> nil then
            PNode(PNode(LSibling)^.Left)^.Color := 1;
          PNode(LSibling)^.Color := 0;
          RotateRight(LSibling);
          LSibling := PNode(aNode^.Parent)^.Right;
        end;

        if LSibling <> nil then
        begin
          PNode(LSibling)^.Color := PNode(aNode^.Parent)^.Color;
          PNode(aNode^.Parent)^.Color := 1;
          if PNode(LSibling)^.Right <> nil then
            PNode(PNode(LSibling)^.Right)^.Color := 1;
          RotateLeft(aNode^.Parent);
          aNode := FRoot;
        end;
      end;
    end
    else
    begin
      LSibling := PNode(aNode^.Parent)^.Left;
      if (LSibling <> nil) and (PNode(LSibling)^.Color = 0) then
      begin
        PNode(LSibling)^.Color := 1;
        PNode(aNode^.Parent)^.Color := 0;
        RotateRight(aNode^.Parent);
        LSibling := PNode(aNode^.Parent)^.Left;
      end;

      if (LSibling <> nil) and
         (PNode(LSibling)^.Right = nil) and (PNode(LSibling)^.Left = nil) then
      begin
        PNode(LSibling)^.Color := 0;
        aNode := aNode^.Parent;
      end
      else if (LSibling <> nil) then
      begin
        if (PNode(LSibling)^.Left = nil) or
           (PNode(PNode(LSibling)^.Left)^.Color = 1) then
        begin
          if PNode(LSibling)^.Right <> nil then
            PNode(PNode(LSibling)^.Right)^.Color := 1;
          PNode(LSibling)^.Color := 0;
          RotateLeft(LSibling);
          LSibling := PNode(aNode^.Parent)^.Left;
        end;

        if LSibling <> nil then
        begin
          PNode(LSibling)^.Color := PNode(aNode^.Parent)^.Color;
          PNode(aNode^.Parent)^.Color := 1;
          if PNode(LSibling)^.Left <> nil then
            PNode(PNode(LSibling)^.Left)^.Color := 1;
          RotateRight(aNode^.Parent);
          aNode := FRoot;
        end;
      end;
    end;
  end;

  if aNode <> nil then
    aNode^.Color := 1;
end;

function TRedBlackTree.GetSuccessor(aNode: PNode): PNode;
var
  LTemp: PNode;
begin
  if aNode^.Right <> nil then
  begin
    Result := GetMinimum(PNode(aNode^.Right));
    Exit;
  end;

  LTemp := aNode^.Parent;
  while (LTemp <> nil) and (aNode = PNode(LTemp)^.Right) do
  begin
    aNode := LTemp;
    LTemp := LTemp^.Parent;
  end;
  Result := LTemp;
end;

function TRedBlackTree.GetPredecessor(aNode: PNode): PNode;
var
  LTemp: PNode;
begin
  if aNode^.Left <> nil then
  begin
    Result := GetMaximum(PNode(aNode^.Left));
    Exit;
  end;

  LTemp := aNode^.Parent;
  while (LTemp <> nil) and (aNode = PNode(LTemp)^.Left) do
  begin
    aNode := LTemp;
    LTemp := LTemp^.Parent;
  end;
  Result := LTemp;
end;

function TRedBlackTree.FindNode(const aKey: K): PNode;
var
  LCompareResult: SizeInt;
begin
  Result := FRoot;
  while Result <> nil do
  begin
    LCompareResult := FCompareMethod(aKey, PNode(Result)^.Key, nil);

    if LCompareResult = 0 then
      Exit
    else if LCompareResult < 0 then
      Result := PNode(Result)^.Left
    else
      Result := PNode(Result)^.Right;
  end;
end;

function TRedBlackTree.GetLowerBoundNode(const aKey: K): PNode;
var
  LResult: PNode;
  LCompareResult: SizeInt;
begin
  LResult := nil;
  Result := FRoot;

  while Result <> nil do
  begin
    LCompareResult := FCompareMethod(aKey, PNode(Result)^.Key, nil);

    if LCompareResult <= 0 then
    begin
      LResult := Result;
      Result := PNode(Result)^.Left;
    end
    else
      Result := PNode(Result)^.Right;
  end;

  Result := LResult;
end;

function TRedBlackTree.GetUpperBoundNode(const aKey: K): PNode;
var
  LResult: PNode;
  LCompareResult: SizeInt;
begin
  LResult := nil;
  Result := FRoot;

  while Result <> nil do
  begin
    LCompareResult := FCompareMethod(aKey, PNode(Result)^.Key, nil);

    if LCompareResult < 0 then
    begin
      LResult := Result;
      Result := PNode(Result)^.Left;
    end
    else
      Result := PNode(Result)^.Right;
  end;

  Result := LResult;
end;

{ API 实现 }

function TRedBlackTree.Get(const aKey: K; out aValue: V): Boolean;
var
  LNode: PNode;
begin
  LNode := FindNode(aKey);
  if LNode <> nil then
  begin
    aValue := LNode^.Value;
    Result := True;
  end
  else
    Result := False;
end;

function TRedBlackTree.Put(const aKey: K; const aValue: V): Boolean;
var
  LExisted: Boolean;
  LNode: PNode;
begin
  LNode := InsertNode(aKey, aValue, LExisted);
  Result := LExisted;
end;

function TRedBlackTree.Remove(const aKey: K): Boolean;
var
  LNode, LTemp, LChild: PNode;
  LWasBlack: Boolean;
begin
  LNode := FindNode(aKey);
  if LNode = nil then
  begin
    Result := False;
    Exit;
  end;

  LWasBlack := (LNode^.Color = 1);
  if LNode^.Left = nil then
  begin
    LChild := PNode(LNode^.Right);
    Transplant(LNode, LChild);
    DeallocateNode(LNode);
  end
  else if LNode^.Right = nil then
  begin
    LChild := PNode(LNode^.Left);
    Transplant(LNode, LChild);
    DeallocateNode(LNode);
  end
  else
  begin
    LTemp := GetMinimum(PNode(LNode^.Right));
    LWasBlack := (LTemp^.Color = 1);
    LChild := PNode(LTemp^.Right);
    if LTemp^.Parent = LNode then
    begin
      if LChild <> nil then
        PNode(LChild)^.Parent := LTemp;
    end
    else
    begin
      Transplant(LTemp, LChild);
      LTemp^.Right := LNode^.Right;
      PNode(LTemp^.Right)^.Parent := LTemp;
    end;
    Transplant(LNode, LTemp);
    LTemp^.Left := LNode^.Left;
    PNode(LTemp^.Left)^.Parent := LTemp;
    LTemp^.Color := LNode^.Color;
  end;

  if LWasBlack then
    FixDelete(LChild);

  DeallocateNode(LNode);
  Dec(FCount);
  Result := True;
end;

function TRedBlackTree.DeleteNode(const aKey: K): Boolean;
begin
  Result := Remove(aKey);
end;

procedure TRedBlackTree.InOrderTraversal(aNode: PNode; const aCallback: specialize TKeyValueCallback<K, V>);
var
  LEntry: TMapEntryType;
begin
  if aNode = nil then
    Exit;

  InOrderTraversal(PNode(aNode^.Left), aCallback);

  LEntry.Key := aNode^.Key;
  LEntry.Value := aNode^.Value;
  aCallback(LEntry, nil);

  InOrderTraversal(PNode(aNode^.Right), aCallback);
end;

function TRedBlackTree.ContainsKey(const aKey: K): Boolean;
begin
  Result := FindNode(aKey) <> nil;
end;

function TRedBlackTree.GetCount: SizeUInt;
begin
  Result := FCount;
end;

function TRedBlackTree.GetLowerBound(const aKey: K; out aValue: V): Boolean;
var
  LNode: PNode;
begin
  LNode := GetLowerBoundNode(aKey);
  if LNode <> nil then
  begin
    aValue := LNode^.Value;
    Result := True;
  end
  else
    Result := False;
end;

function TRedBlackTree.GetUpperBound(const aKey: K; out aValue: V): Boolean;
var
  LNode: PNode;
begin
  LNode := GetUpperBoundNode(aKey);
  if LNode <> nil then
  begin
    aValue := LNode^.Value;
    Result := True;
  end
  else
    Result := False;
end;

function TRedBlackTree.GetRange(const aLow, aHigh: K; const aCallback: specialize TKeyValueCallback<K, V>): Boolean;
{**
 * 实现范围查询 (GetRange)
 *
 * 功能：遍历并访问键在 [aLow, aHigh] 范围内的所有节点
 * 方法：中序遍历，只访问范围内的节点
 * 参数：
 *   aLow - 范围下限（包含）
 *   aHigh - 范围上限（包含）
 *   aCallback - 对每个匹配节点调用的回调函数
 * 返回值：
 *   始终返回 True（范围查询不失败）
 *}
var
  LStartNode: PNode;
  LCurrent: PNode;
  LEntry: TMapEntryType;
  LCompareLow, LCompareHigh: SizeInt;
begin
  Result := True;
  if FRoot = nil then Exit;

  { 找到范围内的第一个节点 }
  LStartNode := GetLowerBoundNode(aLow);
  if LStartNode = nil then Exit;  { 没有节点 >= aLow }

  LCurrent := LStartNode;

  { 遍历范围内的节点，直到超出 aHigh }
  while LCurrent <> nil do
  begin
    LCompareHigh := FCompareMethod(aHigh, PNode(LCurrent)^.Key, nil);
    if LCompareHigh < 0 then
      Break;  { 当前节点键 > aHigh，结束 }

    { 调用回调函数 }
    LEntry.Key := LCurrent^.Key;
    LEntry.Value := LCurrent^.Value;
    aCallback(LEntry, nil);

    { 移动到下一个节点（中序遍历的后继）}
    if LCurrent^.Right <> nil then
    begin
      { 右子树的最左节点 }
      LCurrent := PNode(LCurrent)^.Right;
      while LCurrent^.Left <> nil do
        LCurrent := PNode(LCurrent)^.Left;
    end
    else
    begin
      { 向上回溯直到找到未访问的父节点 }
      while (LCurrent^.Parent <> nil) and
            (PNode(LCurrent^.Parent)^.Right = LCurrent) do
        LCurrent := PNode(LCurrent)^.Parent;
      LCurrent := PNode(LCurrent)^.Parent;
    end;
  end;
end;

function TRedBlackTree.Ceiling(const aKey: K; out aValue: V): Boolean;
begin
  Result := GetLowerBound(aKey, aValue);
end;

function TRedBlackTree.Floor(const aKey: K; out aValue: V): Boolean;
var
  LNode: PNode;
  LResult: PNode;
  LCompareResult: SizeInt;
begin
  LNode := FRoot;
  LResult := nil;
  while LNode <> nil do
  begin
    LCompareResult := FCompareMethod(aKey, PNode(LNode)^.Key, nil);

    if LCompareResult < 0 then
    begin
      { 键大于当前节点，可能在左子树 }
      LNode := PNode(LNode)^.Left;
    end
    else
    begin
      { 键小于等于当前节点，记录当前节点，可能在右子树找到更优解 }
      LResult := LNode;
      LNode := PNode(LNode)^.Right;
    end;
  end;

  if LResult <> nil then
  begin
    aValue := LResult^.Value;
    Result := True;
  end
  else
    Result := False;
end;

function TRedBlackTree.GetKeys: TCollection;
{**
 * 获取所有键的集合 (GetKeys)
 *
 * 功能：遍历树并返回包含所有键的集合
 * 方法：递归中序遍历，收集所有键
 * 返回值：
 *   TCollection - 包含所有键的新集合
 *   调用者负责释放返回的集合
 *}
var
  LKeyArray: array of K;
  LCount: SizeUInt;

  { 内部递归遍历收集键 }
  procedure CollectKeys(aNode: PNode);
  begin
    if aNode = nil then Exit;

    CollectKeys(PNode(aNode^.Left));
    LKeyArray[LCount] := aNode^.Key;
    Inc(LCount);
    CollectKeys(PNode(aNode^.Right));
  end;

begin
  if FRoot = nil then
  begin
    { 空树返回空集合 }
    Result := specialize TArray<K>.Create(FAllocator);
    Exit;
  end;

  { 创建新数组并预分配容量 }
  LCount := 0;
  SetLength(LKeyArray, FCount);

  { 递归遍历树并收集键 }
  CollectKeys(FRoot);

  { 调整数组大小到实际元素数量 }
  SetLength(LKeyArray, LCount);

  { 创建集合并加载数据 }
  Result := specialize TArray<K>.Create(Pointer(LKeyArray), LCount, FAllocator);
end;

function TRedBlackTree.GetValues: TCollection;
{**
 * 获取所有值的集合 (GetValues)
 *
 * 功能：遍历树并返回包含所有值的集合
 * 方法：递归中序遍历，收集所有值
 * 返回值：
 *   TCollection - 包含所有值的新集合
 *   调用者负责释放返回的集合
 *}
var
  LValueArray: array of V;
  LCount: SizeUInt;

  { 内部递归遍历收集值 }
  procedure CollectValues(aNode: PNode);
  begin
    if aNode = nil then Exit;

    CollectValues(PNode(aNode^.Left));
    LValueArray[LCount] := aNode^.Value;
    Inc(LCount);
    CollectValues(PNode(aNode^.Right));
  end;

begin
  if FRoot = nil then
  begin
    { 空树返回空集合 }
    Result := specialize TArray<V>.Create(FAllocator);
    Exit;
  end;

  { 创建新数组并预分配容量 }
  LCount := 0;
  SetLength(LValueArray, FCount);

  { 递归遍历树并收集值 }
  CollectValues(FRoot);

  { 调整数组大小到实际元素数量 }
  SetLength(LValueArray, LCount);

  { 创建集合并加载数据 }
  Result := specialize TArray<V>.Create(Pointer(LValueArray), LCount, FAllocator);
end;

procedure TRedBlackTree.FreeNodeAndChildren(aNode: PNode);
begin
  if aNode = nil then Exit;

  { 递归释放左右子树 }
  if aNode^.Left <> nil then
    FreeNodeAndChildren(PNode(aNode^.Left));

  if aNode^.Right <> nil then
    FreeNodeAndChildren(PNode(aNode^.Right));

  { 释放当前节点 }
  DeallocateNode(aNode);
end;

procedure TRedBlackTree.Clear;
begin
  { 递归释放所有节点 }
  if FRoot <> nil then
    FreeNodeAndChildren(FRoot);

  FRoot := nil;
  FCount := 0;
end;

{ TTreeMap }

constructor TTreeMap.Create(const aAllocator: IAllocator; const aCompare: specialize TCompareFunc<K>);
begin
  inherited Create;
  if aAllocator <> nil then
    FAllocator := aAllocator
  else
    FAllocator := GetRtlAllocator;

  FTree := TRedBlackTreeType.Create(FAllocator, aCompare);
end;

destructor TTreeMap.Destroy;
begin
  FTree.Free;
  inherited Destroy;
end;

function TTreeMap.GetCount: SizeUInt;
begin
  Result := FTree.GetCount;
end;

function TTreeMap.GetLowerBound(const aKey: K; out aValue: V): Boolean;
begin
  Result := FTree.GetLowerBound(aKey, aValue);
end;

function TTreeMap.GetUpperBound(const aKey: K; out aValue: V): Boolean;
begin
  Result := FTree.GetUpperBound(aKey, aValue);
end;

function TTreeMap.GetRange(const aLow, aHigh: K; const aCallback: specialize TKeyValueCallback<K, V>): Boolean;
begin
  Result := FTree.GetRange(aLow, aHigh, aCallback);
end;

function TTreeMap.Ceiling(const aKey: K; out aValue: V): Boolean;
begin
  Result := FTree.Ceiling(aKey, aValue);
end;

function TTreeMap.Floor(const aKey: K; out aValue: V): Boolean;
begin
  Result := FTree.Floor(aKey, aValue);
end;

function TTreeMap.Get(const aKey: K; out aValue: V): Boolean;
begin
  Result := FTree.Get(aKey, aValue);
end;

function TTreeMap.Put(const aKey: K; const aValue: V): Boolean;
begin
  Result := FTree.Put(aKey, aValue);
end;

function TTreeMap.Remove(const aKey: K): Boolean;
begin
  Result := FTree.Remove(aKey);
end;

function TTreeMap.ContainsKey(const aKey: K): Boolean;
begin
  Result := FTree.ContainsKey(aKey);
end;

function TTreeMap.GetKeyCount: SizeUInt;
begin
  Result := FTree.GetCount;
end;

function TTreeMap.GetKeys: TCollection;
begin
  Result := FTree.GetKeys;
end;

function TTreeMap.GetValues: TCollection;
begin
  Result := FTree.GetValues;
end;

procedure TTreeMap.Clear;
begin
  FTree.Clear;
end;

end.
