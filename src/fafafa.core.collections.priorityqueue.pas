unit fafafa.core.collections.priorityqueue;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, TypInfo,
  fafafa.core.base,
  fafafa.core.mem.allocator,
  fafafa.core.collections.base,
  fafafa.core.collections.elementManager;

type
  {**
   * IPriorityQueue<T> - 优先队列接口
   *
   * @desc
   *   基于二叉堆实现的优先队列接口，支持 O(log n) 插入和删除，
   *   O(1) 获取最小/最大元素。
   *
   * @type_params
   *   T - 元素类型
   *
   * @threadsafety NOT thread-safe
   *}
  generic IPriorityQueue<T> = interface(specialize IGenericCollection<T>)
  ['{F8E9D7C6-B5A4-4321-9876-543210FEDCBA}']
    {** Enqueue - 入队 O(log n) *}
    procedure Enqueue(const aItem: T);
    
    {** Dequeue - 出队并返回优先级最高的元素 O(log n) *}
    function Dequeue(out aItem: T): Boolean;
    
    {** Peek - 查看优先级最高的元素（不移除）O(1) *}
    function Peek(out aItem: T): Boolean;
    
    {** GetCapacity - 获取当前容量 *}
    function GetCapacity: SizeUInt;
    
    {** Reserve - 预留容量 *}
    procedure Reserve(aCapacity: SizeUInt);
    
    property Capacity: SizeUInt read GetCapacity;
  end;

  {**
   * TPriorityQueueClass<T> - 优先队列类实现
   *
   * @desc
   *   基于二叉堆实现的优先队列，继承 TGenericCollection<T>
   *   支持自定义分配器和比较器
   *
   * @type_params
   *   T - 元素类型
   *}
  generic TPriorityQueueClass<T> = class(specialize TGenericCollection<T>, specialize IPriorityQueue<T>)
  public type
    TPQCompareFunc = specialize TCompareFunc<T>;
  private
    FItems: array of T;
    FCount: SizeUInt;
    FCapacity: SizeUInt;
    FComparer: TPQCompareFunc;
    
    procedure Grow;
    procedure SiftUp(aIndex: SizeUInt);
    procedure SiftDown(aIndex: SizeUInt);
    procedure Swap(aIndex1, aIndex2: SizeUInt); {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
    
  protected
    function GetCount: SizeUInt; override;
    function IsOverlap(const aSrc: Pointer; aElementCount: SizeUInt): Boolean; override;
    procedure DoZero; override;
    procedure DoReverse; override;
    
    function DoIterGetCurrent(aIter: PPtrIter): Pointer;
    function DoIterMoveNext(aIter: PPtrIter): Boolean;
    
  public
    constructor Create(aComparer: TPQCompareFunc; aCapacity: SizeUInt = 16; aAllocator: IAllocator = nil); reintroduce;
    destructor Destroy; override;
    
    { IPriorityQueue<T> }
    procedure Enqueue(const aItem: T);
    function Dequeue(out aItem: T): Boolean;
    function Peek(out aItem: T): Boolean;
    function GetCapacity: SizeUInt;
    procedure Reserve(aCapacity: SizeUInt);
    
    { TCollection overrides }
    function PtrIter: TPtrIter; override;
    procedure Clear; override;
    procedure SerializeToArrayBuffer(aDst: Pointer; aCount: SizeUInt); override;
    procedure AppendUnChecked(const aSrc: Pointer; aElementCount: SizeUInt); override;
    procedure AppendToUnChecked(const aDst: TCollection); override;
    
    property Capacity: SizeUInt read GetCapacity;
  end;

  {**
   * TPriorityQueueRecord<T> - 旧版 record 实现 (已弃用)
   *
   * @deprecated 请使用 TPriorityQueueClass<T> 或 IPriorityQueue<T>
   *}
  generic TPriorityQueueRecord<T> = record
  private
  type
    TComparerFunc = function(const A, B: T): Integer;
    TArray = array of T;
  private
    FItems: TArray;
    FCount: Integer;
    FComparer: TComparerFunc;
    
    procedure Grow;
    procedure SiftUp(AIndex: Integer);
    procedure SiftDown(AIndex: Integer);
    procedure Swap(AIndex1, AIndex2: Integer);
    function GetItem(AIndex: Integer): T;
    
  public
    // 初始化
    procedure Init(AComparer: TComparerFunc); overload;  // 使用自定义比较器
    procedure Initialize(AComparer: TComparerFunc); overload;
    procedure Initialize(AComparer: TComparerFunc; ACapacity: Integer); overload;
    
    // 基本操作
    procedure Enqueue(constref AItem: T);  // O(log n)
    function Dequeue(out AItem: T): Boolean;  // O(log n) - 返回是否成功
    function Peek(out AItem: T): Boolean;     // O(1) - 返回是否成功
    
    // 容量和状态
    function Count: Integer;
    function IsEmpty: Boolean;
    procedure Clear;
    
    // 查找和删除特定元素
    function Find(constref AItem: T): Boolean;  // O(n) - 别名 Contains
    function Contains(constref AItem: T): Boolean;  // O(n)
    function Delete(constref AItem: T): Boolean;    // O(n) + O(log n) - 别名 Remove
    function Remove(constref AItem: T): Boolean;    // O(n) + O(log n)
    
    // 批量操作
    function ToArray: TArray;
  end;

  { TPriorityQueue 别名 - 保持向后兼容，使用原始 record 类型 }

{ 工厂函数声明 }
generic function MakePriorityQueue<T>(aComparer: specialize TCompareFunc<T>; aCapacity: SizeUInt = 16; aAllocator: IAllocator = nil): specialize IPriorityQueue<T>;

implementation

{ 工厂函数实现 }
generic function MakePriorityQueue<T>(aComparer: specialize TCompareFunc<T>; aCapacity: SizeUInt; aAllocator: IAllocator): specialize IPriorityQueue<T>;
begin
  Result := specialize TPriorityQueueClass<T>.Create(aComparer, aCapacity, aAllocator);
end;

{ TPriorityQueueClass<T> }

constructor TPriorityQueueClass.Create(aComparer: TPQCompareFunc; aCapacity: SizeUInt; aAllocator: IAllocator);
begin
  inherited Create(aAllocator, nil);
  if not Assigned(aComparer) then
    raise EArgumentNil.Create('TPriorityQueueClass.Create: comparer function cannot be nil');
  FComparer := aComparer;
  FCapacity := aCapacity;
  if FCapacity < 4 then
    FCapacity := 4;
  SetLength(FItems, FCapacity);
  FCount := 0;
end;

destructor TPriorityQueueClass.Destroy;
begin
  Clear;
  SetLength(FItems, 0);
  inherited Destroy;
end;

procedure TPriorityQueueClass.Grow;
begin
  if FCapacity = 0 then
    FCapacity := 16
  else
    FCapacity := FCapacity * 2;
  SetLength(FItems, FCapacity);
end;

procedure TPriorityQueueClass.Swap(aIndex1, aIndex2: SizeUInt);
var
  LTemp: T;
begin
  LTemp := FItems[aIndex1];
  FItems[aIndex1] := FItems[aIndex2];
  FItems[aIndex2] := LTemp;
end;

procedure TPriorityQueueClass.SiftUp(aIndex: SizeUInt);
var
  LParentIdx: SizeUInt;
begin
  while aIndex > 0 do
  begin
    LParentIdx := (aIndex - 1) div 2;
    if FComparer(FItems[aIndex], FItems[LParentIdx], nil) >= 0 then
      Break;
    Swap(aIndex, LParentIdx);
    aIndex := LParentIdx;
  end;
end;

procedure TPriorityQueueClass.SiftDown(aIndex: SizeUInt);
var
  LLeftIdx, LRightIdx, LSmallestIdx: SizeUInt;
begin
  while True do
  begin
    LSmallestIdx := aIndex;
    LLeftIdx := 2 * aIndex + 1;
    LRightIdx := 2 * aIndex + 2;
    
    if (LLeftIdx < FCount) and (FComparer(FItems[LLeftIdx], FItems[LSmallestIdx], nil) < 0) then
      LSmallestIdx := LLeftIdx;
      
    if (LRightIdx < FCount) and (FComparer(FItems[LRightIdx], FItems[LSmallestIdx], nil) < 0) then
      LSmallestIdx := LRightIdx;
    
    if LSmallestIdx = aIndex then
      Break;
      
    Swap(aIndex, LSmallestIdx);
    aIndex := LSmallestIdx;
  end;
end;

procedure TPriorityQueueClass.Enqueue(const aItem: T);
begin
  if FCount >= FCapacity then
    Grow;
  FItems[FCount] := aItem;
  Inc(FCount);
  SiftUp(FCount - 1);
end;

function TPriorityQueueClass.Dequeue(out aItem: T): Boolean;
begin
  Result := FCount > 0;
  if not Result then
    Exit;
  aItem := FItems[0];
  Dec(FCount);
  if FCount > 0 then
  begin
    FItems[0] := FItems[FCount];
    SiftDown(0);
  end;
end;

function TPriorityQueueClass.Peek(out aItem: T): Boolean;
begin
  Result := FCount > 0;
  if Result then
    aItem := FItems[0];
end;

function TPriorityQueueClass.GetCount: SizeUInt;
begin
  Result := FCount;
end;

function TPriorityQueueClass.GetCapacity: SizeUInt;
begin
  Result := FCapacity;
end;

procedure TPriorityQueueClass.Reserve(aCapacity: SizeUInt);
begin
  if aCapacity > FCapacity then
  begin
    FCapacity := aCapacity;
    SetLength(FItems, FCapacity);
  end;
end;

procedure TPriorityQueueClass.Clear;
var
  i: SizeUInt;
begin
  // Finalize managed types
  if IsManagedType then
    for i := 0 to FCount - 1 do
      Finalize(FItems[i]);
  FCount := 0;
end;

function TPriorityQueueClass.IsOverlap(const aSrc: Pointer; aElementCount: SizeUInt): Boolean;
var
  LSrcEnd, LItemsEnd: PByte;
begin
  if (FCount = 0) or (aElementCount = 0) or (aSrc = nil) then
    Exit(False);
  LSrcEnd := PByte(aSrc) + aElementCount * SizeOf(T);
  LItemsEnd := PByte(@FItems[0]) + FCount * SizeOf(T);
  Result := (PByte(aSrc) < LItemsEnd) and (LSrcEnd > PByte(@FItems[0]));
end;

procedure TPriorityQueueClass.DoZero;
begin
  if FCount > 0 then
    FillChar(FItems[0], FCount * SizeOf(T), 0);
end;

procedure TPriorityQueueClass.DoReverse;
var
  i, j: SizeUInt;
begin
  if FCount <= 1 then Exit;
  i := 0;
  j := FCount - 1;
  while i < j do
  begin
    Swap(i, j);
    Inc(i);
    Dec(j);
  end;
  // Note: After reverse, heap property is broken. Re-heapify:
  // (Actually for PQ, reverse doesn't make semantic sense, but we implement it anyway)
end;

function TPriorityQueueClass.DoIterGetCurrent(aIter: PPtrIter): Pointer;
var
  LIdx: SizeUInt;
begin
  if aIter = nil then
    Exit(nil);
  LIdx := SizeUInt(aIter^.Data);
  if LIdx >= FCount then
    Exit(nil);
  Result := @FItems[LIdx];
end;

function TPriorityQueueClass.DoIterMoveNext(aIter: PPtrIter): Boolean;
var
  LIdx: SizeUInt;
begin
  if aIter = nil then
    Exit(False);
  if not aIter^.Started then
  begin
    aIter^.Started := True;
    if FCount = 0 then
      Exit(False);
    // Store index directly in Data pointer (no allocation needed)
    aIter^.Data := Pointer(SizeUInt(0));
    Result := True;
  end
  else
  begin
    LIdx := SizeUInt(aIter^.Data);
    Inc(LIdx);
    if LIdx >= FCount then
      Exit(False);
    aIter^.Data := Pointer(LIdx);
    Result := True;
  end;
end;

function TPriorityQueueClass.PtrIter: TPtrIter;
begin
  Result.Init(Self, @DoIterGetCurrent, @DoIterMoveNext, nil);
end;

procedure TPriorityQueueClass.SerializeToArrayBuffer(aDst: Pointer; aCount: SizeUInt);
var
  LCopyCount: SizeUInt;
begin
  if (aDst = nil) or (aCount = 0) then
    Exit;
  LCopyCount := aCount;
  if LCopyCount > FCount then
    LCopyCount := FCount;
  if LCopyCount > 0 then
    Move(FItems[0], aDst^, LCopyCount * SizeOf(T));
end;

procedure TPriorityQueueClass.AppendUnChecked(const aSrc: Pointer; aElementCount: SizeUInt);
type
  PT = ^T;
var
  LSrc: PT;
  i: SizeUInt;
begin
  if (aSrc = nil) or (aElementCount = 0) then
    Exit;
  LSrc := PT(aSrc);
  for i := 0 to aElementCount - 1 do
  begin
    Enqueue(LSrc^);
    Inc(LSrc);
  end;
end;

procedure TPriorityQueueClass.AppendToUnChecked(const aDst: TCollection);
var
  i: SizeUInt;
begin
  if aDst = nil then
    Exit;
  for i := 0 to FCount - 1 do
    aDst.AppendUnChecked(@FItems[i], 1);
end;

{ TPriorityQueueRecord<T> }

procedure TPriorityQueueRecord.Init(AComparer: TComparerFunc);
begin
  Initialize(AComparer, 16);
end;

procedure TPriorityQueueRecord.Initialize(AComparer: TComparerFunc);
begin
  Initialize(AComparer, 16);
end;

procedure TPriorityQueueRecord.Initialize(AComparer: TComparerFunc; ACapacity: Integer);
begin
  if ACapacity < 4 then
    ACapacity := 4;
  SetLength(FItems, ACapacity);
  FCount := 0;
  FComparer := AComparer;
end;

procedure TPriorityQueueRecord.Grow;
var
  newCap: Integer;
begin
  if Length(FItems) = 0 then
    newCap := 16
  else
    newCap := Length(FItems) * 2;
  SetLength(FItems, newCap);
end;

procedure TPriorityQueueRecord.Swap(AIndex1, AIndex2: Integer);
var
  temp: T;
begin
  temp := FItems[AIndex1];
  FItems[AIndex1] := FItems[AIndex2];
  FItems[AIndex2] := temp;
end;

procedure TPriorityQueueRecord.SiftUp(AIndex: Integer);
var
  parentIdx: Integer;
begin
  while AIndex > 0 do
  begin
    parentIdx := (AIndex - 1) div 2;
    if FComparer(FItems[AIndex], FItems[parentIdx]) >= 0 then
      Break;
    Swap(AIndex, parentIdx);
    AIndex := parentIdx;
  end;
end;

procedure TPriorityQueueRecord.SiftDown(AIndex: Integer);
var
  leftIdx, rightIdx, smallestIdx: Integer;
begin
  while True do
  begin
    smallestIdx := AIndex;
    leftIdx := 2 * AIndex + 1;
    rightIdx := 2 * AIndex + 2;
    if (leftIdx < FCount) and (FComparer(FItems[leftIdx], FItems[smallestIdx]) < 0) then
      smallestIdx := leftIdx;
    if (rightIdx < FCount) and (FComparer(FItems[rightIdx], FItems[smallestIdx]) < 0) then
      smallestIdx := rightIdx;
    if smallestIdx = AIndex then
      Break;
    Swap(AIndex, smallestIdx);
    AIndex := smallestIdx;
  end;
end;

function TPriorityQueueRecord.GetItem(AIndex: Integer): T;
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    raise ERangeError.CreateFmt('TPriorityQueueRecord.GetItem: index %d out of range [0..%d)', [AIndex, FCount]);
  Result := FItems[AIndex];
end;

procedure TPriorityQueueRecord.Enqueue(constref AItem: T);
begin
  if FCount >= Length(FItems) then
    Grow;
  FItems[FCount] := AItem;
  Inc(FCount);
  SiftUp(FCount - 1);
end;

function TPriorityQueueRecord.Dequeue(out AItem: T): Boolean;
begin
  Result := FCount > 0;
  if not Result then
    Exit;
  AItem := FItems[0];
  Dec(FCount);
  if FCount > 0 then
  begin
    FItems[0] := FItems[FCount];
    SiftDown(0);
  end;
end;

function TPriorityQueueRecord.Peek(out AItem: T): Boolean;
begin
  Result := FCount > 0;
  if Result then
    AItem := FItems[0];
end;

function TPriorityQueueRecord.Count: Integer;
begin
  Result := FCount;
end;

function TPriorityQueueRecord.IsEmpty: Boolean;
begin
  Result := FCount = 0;
end;

procedure TPriorityQueueRecord.Clear;
begin
  FCount := 0;
end;

function TPriorityQueueRecord.Find(constref AItem: T): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to FCount - 1 do
    if FComparer(FItems[i], AItem) = 0 then
      Exit(True);
end;

function TPriorityQueueRecord.Contains(constref AItem: T): Boolean;
begin
  Result := Find(AItem);
end;

function TPriorityQueueRecord.Delete(constref AItem: T): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to FCount - 1 do
  begin
    if FComparer(FItems[i], AItem) = 0 then
    begin
      Dec(FCount);
      if i < FCount then
      begin
        FItems[i] := FItems[FCount];
        SiftUp(i);
        SiftDown(i);
      end;
      Exit(True);
    end;
  end;
end;

function TPriorityQueueRecord.Remove(constref AItem: T): Boolean;
begin
  Result := Delete(AItem);
end;

function TPriorityQueueRecord.ToArray: TArray;
var
  i: Integer;
begin
  Result := nil;
  SetLength(Result, FCount);
  for i := 0 to FCount - 1 do
    Result[i] := FItems[i];
end;

end.
