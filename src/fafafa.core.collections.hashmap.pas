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
  // 键哈希与相等回调（先放在本单元，后续如需复用再抽离）
  generic THashFunc<K>  = function (const AKey: K): UInt32;
  generic TEqualsFunc<K> = function (const L, R: K): Boolean;

  // Map 的元素项（用于与 IGenericCollection 对齐迭代协议）
  generic TMapEntry<K,V> = record
    Key: K;
    Value: V;
  end;

  // HashMap 接口（开放寻址实现为主；HashSet 将复用 HashMap）
  generic IHashMap<K,V> = interface(specialize IGenericCollection<specialize TMapEntry<K,V>>)
  ['{3C7B7B5B-4A29-46F0-9B13-9E5AC2D32E1F}']
    // 基本查询/修改
    function TryGetValue(const AKey: K; out AValue: V): Boolean;
    function ContainsKey(const AKey: K): Boolean;
    function Add(const AKey: K; const AValue: V): Boolean;           // 仅新增，存在返回 False
    function AddOrAssign(const AKey: K; const AValue: V): Boolean;    // 存在则覆盖，返回是否为新增
    function Remove(const AKey: K): Boolean;
    procedure Clear;

    // 容量/装载因子
    function GetCapacity: SizeUInt;
    function GetLoadFactor: Single;
    procedure Reserve(aCapacity: SizeUInt);

    property Capacity: SizeUInt read GetCapacity;
    property LoadFactor: Single read GetLoadFactor;
  end;
// Common hash helpers (callers can pass these as aHash)
function HashMix32(x: UInt32): UInt32;
function HashOfPointer(p: Pointer): UInt32;
function HashOfUInt32(x: UInt32): UInt32;
function HashOfUInt64(x: QWord): UInt32;
function HashOfAnsiString(const s: AnsiString): UInt32;
function HashOfUnicodeString(const s: UnicodeString): UInt32;


  // HashSet：语义为包含关系，基于 HashMap<K,Byte> 的薄封装
  generic IHashSet<K> = interface(specialize IGenericCollection<K>)
  ['{4E6B9CD0-2D7E-4E7D-A7A7-7B0E9D6ABF1A}']
    function Add(const AKey: K): Boolean;
    function Contains(const AKey: K): Boolean;
    function Remove(const AKey: K): Boolean;
    procedure Clear;

    function GetCapacity: SizeUInt;
    procedure Reserve(aCapacity: SizeUInt);
    property Capacity: SizeUInt read GetCapacity;
  end;
type
  // 最小占位实现骨架（后续填充开放寻址引擎）
  generic THashMap<K,V> = class(specialize TGenericCollection<specialize TMapEntry<K,V>>, specialize IHashMap<K,V>)
  public
    type
      TEntry = specialize TMapEntry<K,V>;
      THash = specialize THashFunc<K>;
      TEquals = specialize TEqualsFunc<K>;
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
    procedure RecalcMaxLoad;
    procedure Rehash(aNewCapacity: SizeUInt);
    function  NextPow2(x: SizeUInt): SizeUInt;
    function  KeyHash(const AKey: K): UInt32;
    function  KeysEqual(const L, R: K): Boolean; inline;
    function  FindIndex(const AKey: K; AHash: UInt32; out AIndex: SizeUInt): Boolean;
  public
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
    FMap: specialize THashMap<K, Byte>;
  public
    constructor Create(aCapacity: SizeUInt = 0; aHash: specialize THashFunc<K> = nil; aEquals: specialize TEqualsFunc<K> = nil; aAllocator: IAllocator = nil);
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
    h := (h xor Ord(s[i])) * 16777619; // FNV-1a 简化版，后续可用 xxhash
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

    function Contains(const AKey: K): Boolean;
    function Remove(const AKey: K): Boolean;
  end;

implementation

const
  DEFAULT_MAX_LOAD_FACTOR = 0.86; // used/capacity threshold

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
var p: PtrUInt;
begin
  if Assigned(FHash) then Exit(FHash(AKey));
  // 默认分派：指针/整数/枚举 -> 混洗；字符串 -> FNV-1a+混洗；其他 -> 不支持
  {$IF FPC_FULLVERSION >= 30000}
  if system.IsManagedType(K) then
  begin
    // 仅支持 string 的默认哈希，其它托管类型需用户提供
    {$if declared(UnicodeString)}
    if TypeInfo(K) = TypeInfo(UnicodeString) then Exit(HashOfUnicodeString(UnicodeString(AKey)));
    {$endif}
    {$if declared(AnsiString)}
    if TypeInfo(K) = TypeInfo(AnsiString) then Exit(HashOfAnsiString(AnsiString(AKey)));
    {$endif}
    raise ENotSupported.Create('HashMap: please provide hasher for this managed key type');
  end;
  {$ENDIF}
  case SizeOf(K) of
    1,2,4: Exit(HashOfUInt32(UInt32(PtrUInt(AKey))));
    8:     Exit(HashOfUInt64(QWord(PtrUInt(AKey))));
  else
    // 非托管复杂类型，默认不支持
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
  // Finalize managed fields then mark tombstone
  Finalize(FBuckets[idx].Key);
  Finalize(FBuckets[idx].Value);
  FBuckets[idx].State := Ord(bsTombstone);
  FBuckets[idx].Hash := 0;
  Dec(FCount);
  Result := True;
end;

{ THashSet<K> }

constructor THashSet.Create(aCapacity: SizeUInt; aHash: specialize THashFunc<K>; aEquals: specialize TEqualsFunc<K>; aAllocator: IAllocator);
begin
  inherited Create(aAllocator);
  FMap := specialize THashMap<K, Byte>.Create(aCapacity, aHash, aEquals, aAllocator);
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

function THashSet.Add(const AKey: K): Boolean;
begin
  Result := FMap.Add(AKey, 1);
end;

function THashSet.Contains(const AKey: K): Boolean;
begin
  Result := FMap.ContainsKey(AKey);
end;

function THashSet.Remove(const AKey: K): Boolean;
begin
  Result := FMap.Remove(AKey);
end;


