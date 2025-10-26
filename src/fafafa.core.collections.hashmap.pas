unit fafafa.core.collections.hashmap;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, TypInfo,
  fafafa.core.base,
  fafafa.core.mem.allocator,
  fafafa.core.collections.base;

type
  {**
   * TKeyHashFunc<K>
   *
   * @desc Hash function for key type K
   * @param AKey The key to hash
   * @return UInt32 hash value
   *}
  generic TKeyHashFunc<K>  = function (const AKey: K): UInt32;

  {**
   * TKeyEqualsFunc<K>
   *
   * @desc Equality comparison function for key type K
   * @param L Left operand
   * @param R Right operand
   * @return Boolean True if L equals R
   *}
  generic TKeyEqualsFunc<K> = function (const L, R: K): Boolean;

  {**
   * TMapEntry<K,V>
   *
   * @desc Key-value pair for HashMap elements
   * @param K Key type
   * @param V Value type
   *}
  generic TMapEntry<K,V> = record
    Key: K;
    Value: V;
  end;

  {**
   * IHashMap<K,V>
   *
   * @desc Hash map interface with open addressing implementation
   * @param K Key type
   * @param V Value type
   * @note HashSet reuses this implementation
   *}
  generic IHashMap<K,V> = interface(specialize IGenericCollection<specialize TMapEntry<K,V>>)
  ['{3C7B7B5B-4A29-46F0-9B13-9E5AC2D32E1F}']
    {**
     * TryGetValue
     *
     * @desc Attempts to retrieve a value for the given key
     * @param AKey The key to look up
     * @param AValue Output parameter for the value if found
     * @return Boolean True if the key exists, False otherwise
     *}
    function TryGetValue(const AKey: K; out AValue: V): Boolean;

    {**
     * ContainsKey
     *
     * @desc Checks if a key exists in the hash map
     * @param AKey The key to check
     * @return Boolean True if the key exists
     *}
    function ContainsKey(const AKey: K): Boolean;

    {**
     * Add
     *
     * @desc Adds a new key-value pair (only if key doesn't exist)
     * @param AKey The key to add
     * @param AValue The value to add
     * @return Boolean True if added, False if key already exists
     *}
    function Add(const AKey: K; const AValue: V): Boolean;

    {**
     * AddOrAssign
     *
     * @desc Adds a new key-value pair or assigns new value if key exists
     * @param AKey The key
     * @param AValue The value
     * @return Boolean True if this was a new key, False if key was updated
     *}
    function AddOrAssign(const AKey: K; const AValue: V): Boolean;

    {**
     * Remove
     *
     * @desc Removes a key-value pair if it exists
     * @param AKey The key to remove
     * @return Boolean True if removed, False if key not found
     *}
    function Remove(const AKey: K): Boolean;

    {**
     * Clear
     *
     * @desc Removes all elements from the hash map
     *}
    procedure Clear;

    {**
     * GetCapacity
     *
     * @desc Returns the current capacity of the hash map
     * @return SizeUInt The number of buckets allocated
     *}
    function GetCapacity: SizeUInt;

    {**
     * GetLoadFactor
     *
     * @desc Returns the current load factor (count / capacity)
     * @return Single The load factor
     *}
    function GetLoadFactor: Single;

    {**
     * Reserve
     *
     * @desc Pre-allocates space for the specified number of elements
     * @param aCapacity Minimum capacity to reserve
     *}
    procedure Reserve(aCapacity: SizeUInt);

    {**
     * Capacity
     *
     * @desc Property accessor for GetCapacity
     * @return SizeUInt Current capacity
     *}
    property Capacity: SizeUInt read GetCapacity;

    {**
     * LoadFactor
     *
     * @desc Property accessor for GetLoadFactor
     * @return Single Current load factor
     *}
    property LoadFactor: Single read GetLoadFactor;
  end;

const
  DEFAULT_MAX_LOAD_FACTOR = 0.86;

// Common hash helpers (callers can pass these as aHash)

{**
 * HashMix32
 *
 * @desc Mixes a 32-bit hash value for better distribution
 * @param x Input hash value
 * @return UInt32 Mixed hash value
 *}
function HashMix32(x: UInt32): UInt32;

{**
 * HashOfPointer
 *
 * @desc Hash function for Pointer type
 * @param p Pointer to hash
 * @return UInt32 Hash value
 *}
function HashOfPointer(p: Pointer): UInt32;

{**
 * HashOfUInt32
 *
 * @desc Hash function for UInt32 type
 * @param x Value to hash
 * @return UInt32 Hash value
 *}
function HashOfUInt32(x: UInt32): UInt32;

{**
 * HashOfUInt64
 *
 * @desc Hash function for UInt64 type
 * @param x Value to hash
 * @return UInt32 Hash value
 *}
function HashOfUInt64(x: QWord): UInt32;

{**
 * HashOfAnsiString
 *
 * @desc Hash function for AnsiString type
 * @param s String to hash
 * @return UInt32 Hash value
 *}
function HashOfAnsiString(const s: AnsiString): UInt32;

{**
 * HashOfUnicodeString
 *
 * @desc Hash function for UnicodeString type
 * @param s String to hash
 * @return UInt32 Hash value
 *}
function HashOfUnicodeString(const s: UnicodeString): UInt32;

type
  {**
   * IHashSet<K>
   *
   * @desc Hash set interface for membership testing
   * @param K Element type
   * @note Implemented as a thin wrapper over HashMap<K,Byte>
   *}
  generic IHashSet<K> = interface(specialize IGenericCollection<K>)
  ['{4E6B9CD0-2D7E-4E7D-A7A7-7B0E9D6ABF1A}']
    {**
     * Add
     *
     * @desc Adds an element to the set (no duplicates)
     * @param AKey Element to add
     * @return Boolean True if added, False if already exists
     *}
    function Add(const AKey: K): Boolean;

    {**
     * Contains
     *
     * @desc Checks if an element is in the set
     * @param AKey Element to check
     * @return Boolean True if element exists
     *}
    function Contains(const AKey: K): Boolean;

    {**
     * Remove
     *
     * @desc Removes an element from the set
     * @param AKey Element to remove
     * @return Boolean True if removed, False if not found
     *}
    function Remove(const AKey: K): Boolean;

    {**
     * Clear
     *
     * @desc Removes all elements from the set
     *}
    procedure Clear;

    {**
     * GetCapacity
     *
     * @desc Returns the current capacity
     * @return SizeUInt Capacity value
     *}
    function GetCapacity: SizeUInt;

    {**
     * Reserve
     *
     * @desc Pre-allocates space for the specified number of elements
     * @param aCapacity Minimum capacity to reserve
     *}
    procedure Reserve(aCapacity: SizeUInt);

    {**
     * Capacity
     *
     * @desc Property accessor for GetCapacity
     * @return SizeUInt Current capacity
     *}
    property Capacity: SizeUInt read GetCapacity;
  end;
  {**
   * @desc 开放寻址哈希映射实现
   *
   * 基于开放寻址的 THashMap<K,V> 实现：
   * - 支持动态扩容和重新哈希
   * - 使用墓碑标记处理删除
   * - 线性探测解决冲突
   * - 自动负载因子管理
   *}
  generic THashMap<K,V> = class(specialize TGenericCollection<specialize TMapEntry<K,V>>, specialize IHashMap<K,V>)
  public
    type
      TEntry = specialize TMapEntry<K,V>;
      THash = specialize TKeyHashFunc<K>;
      TEquals = specialize TKeyEqualsFunc<K>;
      TState = (bsEmpty, bsOccupied, bsTombstone);
      TBucket = record
        State: Byte; // 0=Empty,1=Occupied,2=Tombstone
        Hash: UInt32;
        Key: K;
        Value: V;
      end;
  private
    FBuckets: array of TBucket;
    FMask: SizeUInt;
    FCapacity: SizeUInt;
    FCount: SizeUInt;    // occupied count
    FUsed: SizeUInt;     // occupied + tombstone
    FMaxLoad: SizeUInt;  // threshold for rehash by used
    FHash: THash;
    FEquals: TEquals;
  private
    procedure InitCapacity(aCapacity: SizeUInt);
    procedure RecalcMaxLoad; inline;
    procedure Rehash(aNewCapacity: SizeUInt);
    function  NextPow2(x: SizeUInt): SizeUInt; inline;
    function  KeyHash(const AKey: K): UInt32;
    function  KeysEqual(const L, R: K): Boolean; inline;
    function  FindIndex(const AKey: K; AHash: UInt32; out AIndex: SizeUInt): Boolean;
  protected
    // TCollection 抽象方法实现
    function IsOverlap(const aSrc: Pointer; aElementCount: SizeUInt): Boolean; override;
    procedure SerializeToArrayBuffer(aDst: Pointer; aCount: SizeUInt); override;
    procedure AppendUnChecked(const aSrc: Pointer; aElementCount: SizeUInt); override;
    procedure AppendToUnChecked(const aDst: TCollection); override;
    // TGenericCollection 抽象方法实现
    procedure DoZero(); override;
    procedure DoReverse; override;
  public
    function PtrIter: TPtrIter; override;
    constructor Create(aCapacity: SizeUInt = 0; aHash: THash = nil; aEquals: TEquals = nil; aAllocator: IAllocator = nil);
    destructor Destroy; override;
    procedure Clear; override;
    function GetCount: SizeUInt; override;
    function GetCapacity: SizeUInt;
    function GetLoadFactor: Single;
    procedure Reserve(aCapacity: SizeUInt);

    // IGenericCollection（迭代先返回空实现，后续补充）
    function GetEnumerator: specialize TIter<TEntry>;
    function Iter: specialize TIter<TEntry>;
    function GetElementSize: SizeUInt; inline;

    // 基本操作
    function TryGetValue(const AKey: K; out AValue: V): Boolean;
    function ContainsKey(const AKey: K): Boolean;
    function Add(const AKey: K; const AValue: V): Boolean;
    function AddOrAssign(const AKey: K; const AValue: V): Boolean;
    function Remove(const AKey: K): Boolean;
  end;

  generic THashSet<K> = class(specialize TGenericCollection<K>, specialize IHashSet<K>)
  private
    type
      TInternalMap = specialize THashMap<K, Byte>;
    var
      FMap: TInternalMap;
  protected
    // TCollection 抽象方法实现
    function IsOverlap(const aSrc: Pointer; aElementCount: SizeUInt): Boolean; override;
    procedure SerializeToArrayBuffer(aDst: Pointer; aCount: SizeUInt); override;
    procedure AppendUnChecked(const aSrc: Pointer; aElementCount: SizeUInt); override;
    procedure AppendToUnChecked(const aDst: TCollection); override;
    // TGenericCollection 抽象方法实现
    procedure DoZero(); override;
    procedure DoReverse; override;
  public
    function PtrIter: TPtrIter; override;
    constructor Create(aCapacity: SizeUInt = 0; aHash: specialize TKeyHashFunc<K> = nil; aEquals: specialize TKeyEqualsFunc<K> = nil; aAllocator: IAllocator = nil);
    destructor Destroy; override;
    procedure Clear; override;
    function GetCount: SizeUInt; override;
    function GetCapacity: SizeUInt;
    procedure Reserve(aCapacity: SizeUInt);

    // IGenericCollection
    function GetEnumerator: specialize TIter<K>;
    function Iter: specialize TIter<K>;
    function GetElementSize: SizeUInt; inline;

    // 基本操作
    function Add(const AKey: K): Boolean;
    function Contains(const AKey: K): Boolean; overload;
    function Contains(const AKey: K; aEquals: specialize TEqualsFunc<K>; aData: Pointer): Boolean; overload;
    function Contains(const AKey: K; aEquals: specialize TEqualsMethod<K>; aData: Pointer): Boolean; overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    function Contains(const AKey: K; aEquals: specialize TEqualsRefFunc<K>): Boolean; overload;
    {$ENDIF}
    function Remove(const AKey: K): Boolean;
  end;

implementation

{ Hash helper functions }

function HashMix32(x: UInt32): UInt32;
begin
  x := (x xor (x shr 16)) * $7feb352d;
  x := (x xor (x shr 15)) * $846ca68b;
  x := x xor (x shr 16);
  Result := x;
end;

function HashOfPointer(p: Pointer): UInt32;
begin
  Result := HashMix32(UInt32(PtrUInt(p)));
end;

function HashOfUInt32(x: UInt32): UInt32;
begin
  Result := HashMix32(x);
end;

function HashOfUInt64(x: QWord): UInt32;
var lo,hi: UInt32;
begin
  lo := UInt32(x and $FFFFFFFF);
  hi := UInt32(x shr 32);
  Result := HashMix32(lo xor (hi * $9E3779B1));
end;

function HashOfAnsiString(const s: AnsiString): UInt32;
var i: SizeInt; h: UInt32;
begin
  h := 2166136261;
  for i := 1 to Length(s) do
    h := (h xor Ord(s[i])) * 16777619; // FNV-1a 简化版
  Result := HashMix32(h);
end;

function HashOfUnicodeString(const s: UnicodeString): UInt32;
var i: SizeInt; h: UInt32;
begin
  h := 2166136261;
  for i := 1 to Length(s) do
    h := (h xor Ord(s[i])) * 16777619;
  Result := HashMix32(h);
end;

{ THashMap<K,V> }

constructor THashMap.Create(aCapacity: SizeUInt; aHash: THash; aEquals: TEquals; aAllocator: IAllocator);
begin
  inherited Create(aAllocator);
  FHash := aHash;
  FEquals := aEquals;
  FCapacity := 0;
  FMask := 0;
  FCount := 0;
  FUsed := 0;
  SetLength(FBuckets, 0);
  if aCapacity > 0 then
    InitCapacity(aCapacity);
end;

function THashMap.NextPow2(x: SizeUInt): SizeUInt;
begin
  if x <= 1 then Exit(1);
  Dec(x);
  x := x or (x shr 1);
  x := x or (x shr 2);
  x := x or (x shr 4);
  x := x or (x shr 8);
  x := x or (x shr 16);
  {$IF SizeOf(SizeUInt) = 8}
  x := x or (x shr 32);
  {$ENDIF}
  Inc(x);
  Result := x;
end;

procedure THashMap.RecalcMaxLoad;
begin
  FMaxLoad := Trunc(FCapacity * DEFAULT_MAX_LOAD_FACTOR);
  if FMaxLoad >= FCapacity then
    FMaxLoad := FCapacity - 1;
end;

procedure THashMap.InitCapacity(aCapacity: SizeUInt);
var i: SizeUInt;
begin
  if aCapacity < 4 then aCapacity := 4;
  aCapacity := NextPow2(aCapacity);
  SetLength(FBuckets, aCapacity);
  FCapacity := aCapacity;
  FMask := aCapacity - 1;
  FCount := 0; FUsed := 0;
  for i := 0 to aCapacity-1 do FBuckets[i].State := Ord(bsEmpty);
  RecalcMaxLoad;
end;

procedure THashMap.Rehash(aNewCapacity: SizeUInt);
var oldBuckets: array of TBucket; oldCap, i: SizeUInt; b: TBucket; idx: SizeUInt;
begin
  oldBuckets := FBuckets; oldCap := FCapacity;
  InitCapacity(aNewCapacity);
  // 重新插入占用项
  for i := 0 to oldCap-1 do
  begin
    b := oldBuckets[i];
    if b.State = Ord(bsOccupied) then
    begin
      idx := b.Hash and FMask;
      while (FBuckets[idx].State = Ord(bsOccupied)) do
        idx := (idx + 1) and FMask;
      FBuckets[idx].State := Ord(bsOccupied);

      FBuckets[idx].Hash := b.Hash;
      FBuckets[idx].Key := b.Key;
      FBuckets[idx].Value := b.Value;
      Inc(FCount); Inc(FUsed);
    end;
  end;
end;

function THashMap.KeyHash(const AKey: K): UInt32;
var p: Pointer;
begin
  if Assigned(FHash) then Exit(FHash(AKey));
  // 默认分派：指针/整数/枚举 -> 混洗
  // 对于复杂类型（包括字符串），必须提供自定义哈希函数
  p := @AKey;
  case SizeOf(K) of
    1: Exit(HashOfUInt32(PByte(p)^));
    2: Exit(HashOfUInt32(PWord(p)^));
    4: Exit(HashOfUInt32(PUInt32(p)^));
    8: Exit(HashOfUInt64(PQWord(p)^));
  else
    // 复杂类型，需要自定义哈希
    raise ENotSupported.Create('HashMap: please provide hasher for this key type');
  end;
end;

function THashMap.KeysEqual(const L, R: K): Boolean;
begin
  if Assigned(FEquals) then Exit(FEquals(L, R));
  // 默认使用“=”语义
  Result := L = R;
end;

function THashMap.FindIndex(const AKey: K; AHash: UInt32; out AIndex: SizeUInt): Boolean;
var idx: SizeUInt; start: SizeUInt;
begin
  if FCapacity = 0 then begin AIndex := 0; Exit(False); end;
  idx := AHash and FMask; start := idx;
  while True do
  begin
    case FBuckets[idx].State of
      Ord(bsEmpty): begin AIndex := idx; Exit(False); end;
      Ord(bsOccupied):
        if (FBuckets[idx].Hash = AHash) and KeysEqual(FBuckets[idx].Key, AKey) then
        begin AIndex := idx; Exit(True); end;
      Ord(bsTombstone): ;
    end;
    idx := (idx + 1) and FMask;
    if idx = start then begin AIndex := idx; Exit(False); end;
  end;
end;

procedure THashMap.Clear;
var i: SizeUInt;
begin
  if FCapacity = 0 then Exit;
  for i := 0 to FCapacity-1 do
  begin
    if FBuckets[i].State = Ord(bsOccupied) then
    begin
      Finalize(FBuckets[i].Key);
      Finalize(FBuckets[i].Value);
    end;
    FBuckets[i].State := Ord(bsEmpty);
    FBuckets[i].Hash := 0;
    // Key/Value 已经 Finalize；保持为已清空状态
  end;
  FCount := 0;
  FUsed := 0;
end;

function THashMap.GetCount: SizeUInt;
begin
  Result := FCount;
end;

function THashMap.GetCapacity: SizeUInt;
begin


  Result := FCapacity;
end;

function THashMap.GetLoadFactor: Single;
begin
  if FCapacity = 0 then Exit(0.0);
  Result := FCount / FCapacity;
end;

procedure THashMap.DoZero();
var i: SizeUInt; defaultValue: V;
begin
  // CRITICAL FIX: Properly finalize and reinitialize values to avoid memory corruption
  // Old code used FillChar which bypasses reference counting and causes leaks/crashes
  if FCapacity = 0 then Exit;
  
  // Initialize a default zero value properly
  FillChar(defaultValue, SizeOf(V), 0);
  
  for i := 0 to FCapacity-1 do
  begin
    if FBuckets[i].State = Ord(bsOccupied) then
    begin
      // Finalize old value to release resources
      Finalize(FBuckets[i].Value);
      // Assign fresh zero value
      FBuckets[i].Value := defaultValue;
    end;
  end;
end;

procedure THashMap.DoReverse;
begin
  // HashMap 没有固定的顺序，Reverse 操作无实际意义，保持空实现
  // 这是为了满足基类抽象方法的要求
end;

function THashMap.IsOverlap(const aSrc: Pointer; aElementCount: SizeUInt): Boolean;
begin
  // HashMap 不使用连续内存，不会与外部指针重叠
  Result := False;
end;

function THashMap.PtrIter: TPtrIter;
var ptrIterResult: TPtrIter;
begin
  // 创建一个空的指针迭代器
  // HashMap 是基于哈希表的，不适合使用指针迭代器
  // 调用者应该使用 GetEnumerator / Iter 方法
  FillChar(ptrIterResult, SizeOf(TPtrIter), 0);
  Result := ptrIterResult;
end;

procedure THashMap.SerializeToArrayBuffer(aDst: Pointer; aCount: SizeUInt);
var
  i, cnt: SizeUInt;
  pEntry: ^TEntry;
begin
  // 将 HashMap 中的键值对序列化到数组缓冲区
  if (aDst = nil) or (aCount = 0) or (FCount = 0) then Exit;
  
  pEntry := aDst;
  cnt := 0;
  for i := 0 to FCapacity - 1 do
  begin
    if FBuckets[i].State = Ord(bsOccupied) then
    begin
      if cnt >= aCount then Break;
      pEntry^.Key := FBuckets[i].Key;
      pEntry^.Value := FBuckets[i].Value;
      Inc(pEntry);
      Inc(cnt);
    end;
  end;
end;

procedure THashMap.AppendUnChecked(const aSrc: Pointer; aElementCount: SizeUInt);
var
  i: SizeUInt;
  pEntry: ^TEntry;
begin
  // 从数组缓冲区追加键值对
  if (aSrc = nil) or (aElementCount = 0) then Exit;
  
  pEntry := aSrc;
  for i := 0 to aElementCount - 1 do
  begin
    AddOrAssign(pEntry^.Key, pEntry^.Value);
    Inc(pEntry);
  end;
end;

procedure THashMap.AppendToUnChecked(const aDst: TCollection);
var
  i: SizeUInt;
  dstMap: specialize THashMap<K, V>;
begin
  // 将当前 HashMap 的所有元素追加到目标容器
  if aDst = nil then Exit;
  
  // 如果目标也是同类型的 HashMap，可以直接调用 AddOrAssign
  if aDst is specialize THashMap<K, V> then
  begin
    dstMap := specialize THashMap<K, V>(aDst);
    for i := 0 to FCapacity - 1 do
    begin
      if FBuckets[i].State = Ord(bsOccupied) then
        dstMap.AddOrAssign(FBuckets[i].Key, FBuckets[i].Value);
    end;
  end
  else
  begin
    // 对于其他类型的容器，我们无法直接支持
    // 因为 THashMap<K,V> 的元素类型是 TEntry<K,V>，而不是单个类型
    raise EInvalidOperation.Create('Cannot append HashMap to incompatible container type');
  end;
end;

procedure THashMap.Reserve(aCapacity: SizeUInt);
begin
  if aCapacity <= FCapacity then Exit;
  if FCapacity = 0 then InitCapacity(aCapacity)
  else Rehash(NextPow2(aCapacity));
end;

destructor THashMap.Destroy;
begin
  Clear;
  SetLength(FBuckets, 0);
  inherited;
end;

function THashMap.GetEnumerator: specialize TIter<TEntry>;
begin
  Result := inherited GetEnumerator;
end;

function THashMap.Iter: specialize TIter<TEntry>;
begin
  Result := inherited Iter;
end;

function THashMap.GetElementSize: SizeUInt;
begin
  Result := SizeOf(TEntry);
end;

function THashMap.TryGetValue(const AKey: K; out AValue: V): Boolean;
var idx: SizeUInt; h: UInt32;
begin
  if FCapacity = 0 then Exit(False);
  h := KeyHash(AKey);
  if FindIndex(AKey, h, idx) then
  begin
    AValue := FBuckets[idx].Value;
    Exit(True);
  end;
  Result := False;
end;

function THashMap.ContainsKey(const AKey: K): Boolean;
var dummy: V;
begin
  Result := TryGetValue(AKey, dummy);
end;

function THashMap.Add(const AKey: K; const AValue: V): Boolean;
var h: UInt32; idx, firstTomb: SizeUInt; start: SizeUInt; st: Byte;
begin
  if FCapacity = 0 then InitCapacity(4);
  if FUsed >= FMaxLoad then Rehash(FCapacity shl 1);
  h := KeyHash(AKey);
  idx := h and FMask; start := idx; firstTomb := SizeUInt(-1);
  while True do
  begin
    st := FBuckets[idx].State;
    if st = Ord(bsEmpty) then
    begin
      if firstTomb <> SizeUInt(-1) then idx := firstTomb;
      FBuckets[idx].State := Ord(bsOccupied);
      FBuckets[idx].Hash := h;
      FBuckets[idx].Key := AKey;
      FBuckets[idx].Value := AValue;
      Inc(FCount); Inc(FUsed);
      Exit(True);
    end
    else if st = Ord(bsTombstone) then
    begin
      if firstTomb = SizeUInt(-1) then firstTomb := idx;
    end
    else // occupied
    begin
      if (FBuckets[idx].Hash = h) and KeysEqual(FBuckets[idx].Key, AKey) then
        Exit(False);
    end;
    idx := (idx + 1) and FMask;
    if idx = start then
      raise EInvalidOperation.Create('HashMap is full');
  end;
end;

function THashMap.AddOrAssign(const AKey: K; const AValue: V): Boolean;
var h: UInt32; idx, firstTomb: SizeUInt; start: SizeUInt; st: Byte;
begin
  if FCapacity = 0 then InitCapacity(4);
  if FUsed >= FMaxLoad then Rehash(FCapacity shl 1);
  h := KeyHash(AKey);
  idx := h and FMask; start := idx; firstTomb := SizeUInt(-1);
  while True do
  begin
    st := FBuckets[idx].State;
    if st = Ord(bsEmpty) then
    begin
      if firstTomb <> SizeUInt(-1) then idx := firstTomb;
      FBuckets[idx].State := Ord(bsOccupied);
      FBuckets[idx].Hash := h;
      FBuckets[idx].Key := AKey;
      FBuckets[idx].Value := AValue;
      Inc(FCount); Inc(FUsed);
      Exit(True);
    end
    else if st = Ord(bsTombstone) then
    begin
      if firstTomb = SizeUInt(-1) then firstTomb := idx;
    end
    else // occupied
    begin
      if (FBuckets[idx].Hash = h) and KeysEqual(FBuckets[idx].Key, AKey) then
      begin
        // 覆盖旧值（先 Finalize 再赋值，避免泄漏）
        Finalize(FBuckets[idx].Value);
        FBuckets[idx].Value := AValue;
        Exit(False);
      end;
    end;
    idx := (idx + 1) and FMask;
    if idx = start then
      raise EInvalidOperation.Create('HashMap is full');
  end;
end;

function THashMap.Remove(const AKey: K): Boolean;
var idx: SizeUInt; h: UInt32;
begin
  if FCapacity = 0 then Exit(False);
  h := KeyHash(AKey);
  if not FindIndex(AKey, h, idx) then Exit(False);
  // CRITICAL FIX: Finalize then re-initialize to ensure clean state
  // Prevents dangling references and undefined behavior
  Finalize(FBuckets[idx].Key);
  Finalize(FBuckets[idx].Value);
  Initialize(FBuckets[idx].Key);
  Initialize(FBuckets[idx].Value);
  FBuckets[idx].State := Ord(bsTombstone);
  FBuckets[idx].Hash := 0;
  Dec(FCount);
  Result := True;
end;

{ THashSet<K> }

constructor THashSet.Create(aCapacity: SizeUInt; aHash: specialize TKeyHashFunc<K>; aEquals: specialize TKeyEqualsFunc<K>; aAllocator: IAllocator);
begin
  inherited Create(aAllocator);
  FMap := TInternalMap.Create(aCapacity, aHash, aEquals, aAllocator);
end;

destructor THashSet.Destroy;
begin
  FMap.Free;
  inherited;
end;

procedure THashSet.Clear;
begin
  FMap.Clear;
end;

function THashSet.GetCount: SizeUInt;
begin
  Result := FMap.GetCount;
end;

function THashSet.GetCapacity: SizeUInt;
begin
  Result := FMap.GetCapacity;
end;

procedure THashSet.Reserve(aCapacity: SizeUInt);
begin
  FMap.Reserve(aCapacity);
end;

function THashSet.GetEnumerator: specialize TIter<K>;
begin
  Result := inherited GetEnumerator;
end;

function THashSet.Iter: specialize TIter<K>;
begin
  Result := inherited Iter;
end;

function THashSet.GetElementSize: SizeUInt;
begin
  Result := SizeOf(K);
end;

procedure THashSet.DoZero();
begin
  // HashSet 的 Zero 操作委托给底层 HashMap
  FMap.DoZero();
end;

procedure THashSet.DoReverse;
begin
  // HashSet 没有固定的顺序，Reverse 操作无实际意义
  // 委托给底层 HashMap（也是空实现）
  FMap.DoReverse;
end;

function THashSet.IsOverlap(const aSrc: Pointer; aElementCount: SizeUInt): Boolean;
begin
  Result := FMap.IsOverlap(aSrc, aElementCount);
end;

function THashSet.PtrIter: TPtrIter;
begin
  Result := FMap.PtrIter;
end;

procedure THashSet.SerializeToArrayBuffer(aDst: Pointer; aCount: SizeUInt);
{**
 * 将 HashSet 中的元素序列化到数组缓冲区
 *
 * HashSet 内部使用 FMap: THashMap<K, Byte> 存储键值对
 * 其中 Byte 类型充当占位符（值不重要）
 * 需要从 FMap 中提取所有键并写入缓冲区
 *
 * @param aDst 目标缓冲区指针
 * @param aCount 期望写入的元素数量（通常为 FCount）
 *}
var
  I, LCopied: SizeUInt;
  LKey: K;
  PDst: PK;
begin
  if (aDst = nil) or (aCount = 0) or (FCount = 0) then Exit;

  PDst := aDst;
  LCopied := 0;

  // 遍历内部 HashMap 的所有桶
  for I := 0 to FMap.FCapacity - 1 do
  begin
    if FMap.FBuckets[I].State = Ord(bsOccupied) then
    begin
      if LCopied >= aCount then Break;

      // 从 TEntry<K, Byte> 中提取键
      LKey := FMap.FBuckets[I].Key;
      PDst^ := LKey;

      Inc(PDst);
      Inc(LCopied);
    end;
  end;
end;

procedure THashSet.AppendUnChecked(const aSrc: Pointer; aElementCount: SizeUInt);
var
  i: SizeUInt;
  pKey: ^K;
begin
  // 从数组缓冲区追加元素
  if (aSrc = nil) or (aElementCount = 0) then Exit;
  
  pKey := aSrc;
  for i := 0 to aElementCount - 1 do
  begin
    Add(pKey^);
    Inc(pKey);
  end;
end;

procedure THashSet.AppendToUnChecked(const aDst: TCollection);
var
  i: SizeUInt;
  dstSet: specialize THashSet<K>;
  mapIter: specialize TIter<specialize TMapEntry<K, Byte>>;
  entry: specialize TMapEntry<K, Byte>;
begin
  // 将当前 HashSet 的所有元素追加到目标容器
  if aDst = nil then Exit;
  
  // 如果目标也是同类型的 HashSet
  if aDst is specialize THashSet<K> then
  begin
    dstSet := specialize THashSet<K>(aDst);
    // 迭代 FMap 获取所有 Key
    mapIter := FMap.Iter;
    while mapIter.MoveNext do
    begin
      entry := mapIter.Current;
      dstSet.Add(entry.Key);
    end;
  end
  else
  begin
    // 对于其他类型，我们无法直接支持
    raise EInvalidOperation.Create('Cannot append HashSet to incompatible container type');
  end;
end;

function THashSet.Add(const AKey: K): Boolean;
begin
  Result := FMap.Add(AKey, 1);
end;

function THashSet.Contains(const AKey: K): Boolean;
begin
  Result := FMap.ContainsKey(AKey);
end;

function THashSet.Contains(const AKey: K; aEquals: specialize TEqualsFunc<K>; aData: Pointer): Boolean;
begin
  // Delegate to base class generic algorithm which iterates and checks with custom equals
  Result := inherited Contains(AKey, aEquals, aData);
end;

function THashSet.Contains(const AKey: K; aEquals: specialize TEqualsMethod<K>; aData: Pointer): Boolean;
begin
  Result := inherited Contains(AKey, aEquals, aData);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function THashSet.Contains(const AKey: K; aEquals: specialize TEqualsRefFunc<K>): Boolean;
begin
  Result := inherited Contains(AKey, aEquals);
end;
{$ENDIF}

function THashSet.Remove(const AKey: K): Boolean;
begin
  Result := FMap.Remove(AKey);
end;

end.

