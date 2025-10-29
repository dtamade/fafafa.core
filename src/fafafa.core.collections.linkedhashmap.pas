unit fafafa.core.collections.linkedhashmap;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.mem.allocator,
  fafafa.core.collections.base,
  fafafa.core.collections.hashmap;

type
  {**
   * TPair<K,V>
   *
   * @desc Key-value pair for iteration
   *}
  generic TPair<K,V> = record
    Key: K;
    Value: V;
  end;

  {**
   * ILinkedHashMap<K,V>
   *
   * @desc Hash map that maintains insertion order
   * @param K Key type
   * @param V Value type
   * @note Combines O(1) hash lookups with predictable iteration order
   *}
  generic ILinkedHashMap<K,V> = interface(specialize IHashMap<K,V>)
  ['{8F9A2B3C-4D5E-6F7A-8B9C-0D1E2F3A4B5C}']
    {**
     * First
     *
     * @desc Returns the first inserted key-value pair
     * @return TPair<K,V> The first pair
     * @raises Exception if map is empty
     *}
    function First: specialize TPair<K,V>;

    {**
     * Last
     *
     * @desc Returns the last inserted key-value pair
     * @return TPair<K,V> The last pair
     * @raises Exception if map is empty
     *}
    function Last: specialize TPair<K,V>;

    {**
     * TryGetFirst
     *
     * @desc Safely attempts to get the first pair
     * @param aPair Output parameter for the first pair
     * @return Boolean True if map is not empty
     *}
    function TryGetFirst(out aPair: specialize TPair<K,V>): Boolean;

    {**
     * TryGetLast
     *
     * @desc Safely attempts to get the last pair
     * @param aPair Output parameter for the last pair
     * @return Boolean True if map is not empty
     *}
    function TryGetLast(out aPair: specialize TPair<K,V>): Boolean;
  end;

  {**
   * TLinkedNode<K>
   *
   * @desc Internal doubly-linked list node for maintaining order
   *}
  generic TLinkedNode<K> = record
    Key: K;
    Prev: Pointer;  // Points to previous TLinkedNode<K>
    Next: Pointer;  // Points to next TLinkedNode<K>
  end;

  {**
   * TLinkedHashMap<K,V>
   *
   * @desc Implementation of ILinkedHashMap using HashMap + doubly-linked list
   * @param K Key type
   * @param V Value type
   *}
  generic TLinkedHashMap<K,V> = class(specialize TGenericCollection<specialize TMapEntry<K,V>>, specialize ILinkedHashMap<K,V>)
  private
    type
      TNode = specialize TLinkedNode<K>;
      PNode = ^TNode;
      TInternalMap = specialize THashMap<K,V>;
      TNodeMap = specialize THashMap<K, PNode>;
      TPairType = specialize TPair<K,V>;
      TEntryType = specialize TMapEntry<K,V>;

    var
      FMap: TInternalMap;        // Stores key -> value
      FNodeMap: TNodeMap;        // Stores key -> linked node pointer
      FHead: PNode;              // Head of doubly-linked list
      FTail: PNode;              // Tail of doubly-linked list

    procedure LinkNode(aNode: PNode);
    procedure UnlinkNode(aNode: PNode);
    function AllocateNode(const aKey: K): PNode;
    procedure FreeNode(aNode: PNode);

  public
    constructor Create; overload;
    constructor Create(aAllocator: IAllocator); overload;
    constructor Create(aCapacity: SizeUInt); overload;
    constructor Create(aCapacity: SizeUInt; aAllocator: IAllocator); overload;
    destructor Destroy; override;

    // IHashMap<K,V> interface
    function TryGetValue(const aKey: K; out aValue: V): Boolean;
    function ContainsKey(const aKey: K): Boolean;
    function Add(const aKey: K; const aValue: V): Boolean;
    function AddOrAssign(const aKey: K; const aValue: V): Boolean;
    function Remove(const aKey: K): Boolean;
    procedure Clear;
    function GetCapacity: SizeUInt;
    function GetLoadFactor: Single;
    procedure Reserve(aCapacity: SizeUInt);

    // ICollection interface
    function GetCount: SizeUInt;
    function IsEmpty: Boolean;
    function PtrIter: TPtrIter;

    // ILinkedHashMap<K,V> specific
    function First: TPairType;
    function Last: TPairType;
    function TryGetFirst(out aPair: TPairType): Boolean;
    function TryGetLast(out aPair: TPairType): Boolean;

    // Serialization (override from base)
    procedure SerializeToArrayBuffer(aDst: Pointer; aCount: SizeUInt); override;

    // Abstract methods from base classes
    function IsOverlap(const aSrc: Pointer; aElementCount: SizeUInt): Boolean; override;
    procedure AppendUnChecked(const aSrc: Pointer; aElementCount: SizeUInt); override;
    procedure AppendToUnChecked(const aDst: TCollection); override;
    procedure DoZero; override;
    procedure DoReverse; override;

    property Count: SizeUInt read GetCount;
    property Capacity: SizeUInt read GetCapacity;
    property LoadFactor: Single read GetLoadFactor;
  end;

implementation

{ TLinkedHashMap<K,V> }

constructor TLinkedHashMap.Create;
begin
  Create(0, nil);
end;

constructor TLinkedHashMap.Create(aAllocator: IAllocator);
begin
  Create(0, aAllocator);
end;

constructor TLinkedHashMap.Create(aCapacity: SizeUInt);
begin
  Create(aCapacity, nil);
end;

constructor TLinkedHashMap.Create(aCapacity: SizeUInt; aAllocator: IAllocator);
begin
  inherited Create(aAllocator);

  FMap := TInternalMap.Create(aCapacity, nil, nil, Self.FAllocator);
  FNodeMap := TNodeMap.Create(aCapacity, nil, nil, Self.FAllocator);
  FHead := nil;
  FTail := nil;
end;

destructor TLinkedHashMap.Destroy;
begin
  Clear;
  FMap.Free;
  FNodeMap.Free;
  inherited;
end;

function TLinkedHashMap.AllocateNode(const aKey: K): PNode;
begin
  Result := PNode(Self.FAllocator.GetMem(SizeOf(TNode)));
  Initialize(Result^);  // Initialize managed fields
  Result^.Key := aKey;
  Result^.Prev := nil;
  Result^.Next := nil;
end;

procedure TLinkedHashMap.FreeNode(aNode: PNode);
begin
  if aNode <> nil then
  begin
    Finalize(aNode^);  // Finalize managed fields
    Self.FAllocator.FreeMem(aNode);
  end;
end;

procedure TLinkedHashMap.LinkNode(aNode: PNode);
begin
  if FHead = nil then
  begin
    // First node
    FHead := aNode;
    FTail := aNode;
    aNode^.Prev := nil;
    aNode^.Next := nil;
  end
  else
  begin
    // Append to tail
    aNode^.Prev := FTail;
    aNode^.Next := nil;
    FTail^.Next := aNode;
    FTail := aNode;
  end;
end;

procedure TLinkedHashMap.UnlinkNode(aNode: PNode);
var
  LPrev, LNext: PNode;
begin
  LPrev := PNode(aNode^.Prev);
  LNext := PNode(aNode^.Next);

  if LPrev <> nil then
    LPrev^.Next := LNext
  else
    FHead := LNext;

  if LNext <> nil then
    LNext^.Prev := LPrev
  else
    FTail := LPrev;
end;

function TLinkedHashMap.TryGetValue(const aKey: K; out aValue: V): Boolean;
begin
  Result := FMap.TryGetValue(aKey, aValue);
end;

function TLinkedHashMap.ContainsKey(const aKey: K): Boolean;
begin
  Result := FMap.ContainsKey(aKey);
end;

function TLinkedHashMap.Add(const aKey: K; const aValue: V): Boolean;
var
  LNode: PNode;
begin
  // Only add if key doesn't exist
  if FMap.ContainsKey(aKey) then
    Exit(False);

  // Add to hash map
  FMap.Add(aKey, aValue);

  // Create and link node
  LNode := AllocateNode(aKey);
  LinkNode(LNode);
  FNodeMap.Add(aKey, LNode);

  Result := True;
end;

function TLinkedHashMap.AddOrAssign(const aKey: K; const aValue: V): Boolean;
var
  LNode: PNode;
begin
  // Check if key exists
  Result := not FMap.ContainsKey(aKey);

  if Result then
  begin
    // New key - add to hash map and create linked node
    FMap.Add(aKey, aValue);
    LNode := AllocateNode(aKey);
    LinkNode(LNode);
    FNodeMap.Add(aKey, LNode);
  end
  else
  begin
    // Existing key - just update value, don't change order
    FMap.AddOrAssign(aKey, aValue);
  end;
end;

function TLinkedHashMap.Remove(const aKey: K): Boolean;
var
  LNode: PNode;
begin
  Result := FNodeMap.TryGetValue(aKey, LNode);
  if not Result then
    Exit;

  // Remove from linked list
  UnlinkNode(LNode);

  // Remove from maps
  FNodeMap.Remove(aKey);
  FMap.Remove(aKey);

  // Free node
  FreeNode(LNode);
end;

procedure TLinkedHashMap.Clear;
var
  LCurrent, LNext: PNode;
begin
  // Free all nodes
  LCurrent := FHead;
  while LCurrent <> nil do
  begin
    LNext := PNode(LCurrent^.Next);
    FreeNode(LCurrent);
    LCurrent := LNext;
  end;

  FHead := nil;
  FTail := nil;
  FMap.Clear;
  FNodeMap.Clear;
end;

function TLinkedHashMap.GetCapacity: SizeUInt;
begin
  Result := FMap.GetCapacity;
end;

function TLinkedHashMap.GetLoadFactor: Single;
begin
  Result := FMap.GetLoadFactor;
end;

procedure TLinkedHashMap.Reserve(aCapacity: SizeUInt);
begin
  FMap.Reserve(aCapacity);
  FNodeMap.Reserve(aCapacity);
end;

function TLinkedHashMap.GetCount: SizeUInt;
begin
  Result := FMap.GetCount;
end;

function TLinkedHashMap.IsEmpty: Boolean;
begin
  Result := FMap.IsEmpty;
end;

function TLinkedHashMap.First: TPairType;
begin
  if FHead = nil then
    raise Exception.Create('LinkedHashMap is empty');

  Result.Key := FHead^.Key;
  if not FMap.TryGetValue(FHead^.Key, Result.Value) then
    raise Exception.Create('Inconsistent state: key in list but not in map');
end;

function TLinkedHashMap.Last: TPairType;
begin
  if FTail = nil then
    raise Exception.Create('LinkedHashMap is empty');

  Result.Key := FTail^.Key;
  if not FMap.TryGetValue(FTail^.Key, Result.Value) then
    raise Exception.Create('Inconsistent state: key in list but not in map');
end;

function TLinkedHashMap.TryGetFirst(out aPair: TPairType): Boolean;
begin
  Result := FHead <> nil;
  if Result then
  begin
    aPair.Key := FHead^.Key;
    FMap.TryGetValue(FHead^.Key, aPair.Value);
  end;
end;

function TLinkedHashMap.TryGetLast(out aPair: TPairType): Boolean;
begin
  Result := FTail <> nil;
  if Result then
  begin
    aPair.Key := FTail^.Key;
    FMap.TryGetValue(FTail^.Key, aPair.Value);
  end;
end;

function TLinkedHashMap.PtrIter: TPtrIter;
begin
  // LinkedHashMap uses a doubly-linked list structure, not suitable for pointer iteration
  // Callers should use enumerator/iteration methods instead
  FillChar(Result, SizeOf(TPtrIter), 0);
end;

procedure TLinkedHashMap.SerializeToArrayBuffer(aDst: Pointer; aCount: SizeUInt);
var
  LCurrent: PNode;
  LEntries: ^TEntryType;
  i: SizeUInt;
begin
  if (aDst = nil) or (aCount = 0) then
    Exit;

  LEntries := aDst;
  i := 0;
  LCurrent := FHead;
  while (LCurrent <> nil) and (i < aCount) do
  begin
    LEntries[i].Key := LCurrent^.Key;
    FMap.TryGetValue(LCurrent^.Key, LEntries[i].Value);
    Inc(i);
    LCurrent := PNode(LCurrent^.Next);
  end;
end;

function TLinkedHashMap.IsOverlap(const aSrc: Pointer; aElementCount: SizeUInt): Boolean;
begin
  // LinkedHashMap doesn't use contiguous memory, so no overlap possible
  Result := False;
end;

procedure TLinkedHashMap.AppendUnChecked(const aSrc: Pointer; aElementCount: SizeUInt);
var
  i: SizeUInt;
  LEntries: ^TEntryType;
begin
  if (aSrc = nil) or (aElementCount = 0) then
    Exit;

  LEntries := aSrc;
  for i := 0 to aElementCount - 1 do
  begin
    AddOrAssign(LEntries[i].Key, LEntries[i].Value);
    Inc(LEntries);
  end;
end;

procedure TLinkedHashMap.AppendToUnChecked(const aDst: TCollection);
var
  LCurrent: PNode;
  LDstMap: TLinkedHashMap;
  LValue: V;
begin
  if aDst = nil then
    Exit;

  if aDst is TLinkedHashMap then
  begin
    LDstMap := TLinkedHashMap(aDst);
    LCurrent := FHead;
    while LCurrent <> nil do
    begin
      if FMap.TryGetValue(LCurrent^.Key, LValue) then
        LDstMap.AddOrAssign(LCurrent^.Key, LValue);
      LCurrent := PNode(LCurrent^.Next);
    end;
  end
  else
    raise EInvalidOperation.Create('Cannot append LinkedHashMap to incompatible container type');
end;

procedure TLinkedHashMap.DoZero;
var
  LCurrent: PNode;
  LZeroValue: V;
begin
  // Zero all values while preserving keys and order
  FillChar(LZeroValue, SizeOf(V), 0);
  
  LCurrent := FHead;
  while LCurrent <> nil do
  begin
    FMap.AddOrAssign(LCurrent^.Key, LZeroValue);
    LCurrent := PNode(LCurrent^.Next);
  end;
end;

procedure TLinkedHashMap.DoReverse;
var
  LCurrent, LNext: PNode;
begin
  // Reverse the linked list order
  LCurrent := FHead;
  FHead := FTail;
  FTail := LCurrent;

  while LCurrent <> nil do
  begin
    LNext := PNode(LCurrent^.Next);
    LCurrent^.Next := LCurrent^.Prev;
    LCurrent^.Prev := LNext;
    LCurrent := LNext;
  end;
end;

end.


