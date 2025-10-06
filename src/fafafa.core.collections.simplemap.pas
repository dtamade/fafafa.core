unit fafafa.core.collections.simplemap;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils;

type
  // 哈希和相等回调
  generic THashFunc<K> = function (const AKey: K): UInt32;
  generic TEqualsFunc<K> = function (const L, R: K): Boolean;
  
  // 简单 HashMap 实现
  generic TSimpleHashMap<K, V> = class
  public
    type
      TState = (bsEmpty, bsOccupied, bsTombstone);
      TBucket = record
        State: Byte;
        Hash: UInt32;
        Key: K;
        Value: V;
      end;
      THash = specialize THashFunc<K>;
      TEquals = specialize TEqualsFunc<K>;
  private
    FBuckets: array of TBucket;
    FMask: SizeUInt;
    FCapacity: SizeUInt;
    FCount: SizeUInt;
    FUsed: SizeUInt;
    FMaxLoad: SizeUInt;
    FHash: THash;
    FEquals: TEquals;
    
    function NextPow2(x: SizeUInt): SizeUInt; inline;
    procedure RecalcMaxLoad; inline;
    procedure InitCapacity(aCapacity: SizeUInt);
    procedure Rehash(aNewCapacity: SizeUInt);
    function KeyHash(const AKey: K): UInt32;
    function KeysEqual(const L, R: K): Boolean; inline;
    function FindIndex(const AKey: K; AHash: UInt32; out AIndex: SizeUInt): Boolean;
  public
    constructor Create(aCapacity: SizeUInt = 0; aHash: THash = nil; aEquals: TEquals = nil);
    destructor Destroy; override;
    
    procedure Clear;
    function GetCount: SizeUInt; inline;
    function GetCapacity: SizeUInt; inline;
    function GetLoadFactor: Single;
    procedure Reserve(aCapacity: SizeUInt);
    
    function TryGetValue(const AKey: K; out AValue: V): Boolean;
    function ContainsKey(const AKey: K): Boolean;
    function Add(const AKey: K; const AValue: V): Boolean;
    function AddOrAssign(const AKey: K; const AValue: V): Boolean;
    function Remove(const AKey: K): Boolean;
    
    property Count: SizeUInt read FCount;
    property Capacity: SizeUInt read FCapacity;
    property LoadFactor: Single read GetLoadFactor;
  end;

const
  DEFAULT_MAX_LOAD_FACTOR = 0.86;

// 通用哈希函数
function HashMix32(x: UInt32): UInt32; inline;
function HashOfUInt32(x: UInt32): UInt32; inline;
function HashOfUInt64(x: QWord): UInt32; inline;
function HashOfAnsiString(const s: AnsiString): UInt32;

implementation

function HashMix32(x: UInt32): UInt32;
begin
  x := (x xor (x shr 16)) * $7feb352d;
  x := (x xor (x shr 15)) * $846ca68b;
  x := x xor (x shr 16);
  Result := x;
end;

function HashOfUInt32(x: UInt32): UInt32;
begin
  Result := HashMix32(x);
end;

function HashOfUInt64(x: QWord): UInt32;
var lo, hi: UInt32;
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
    h := (h xor Ord(s[i])) * 16777619;
  Result := HashMix32(h);
end;

{ TSimpleHashMap }

constructor TSimpleHashMap.Create(aCapacity: SizeUInt; aHash: THash; aEquals: TEquals);
begin
  inherited Create;
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

destructor TSimpleHashMap.Destroy;
begin
  Clear;
  SetLength(FBuckets, 0);
  inherited;
end;

function TSimpleHashMap.NextPow2(x: SizeUInt): SizeUInt;
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

procedure TSimpleHashMap.RecalcMaxLoad;
begin
  FMaxLoad := Trunc(FCapacity * DEFAULT_MAX_LOAD_FACTOR);
  if FMaxLoad >= FCapacity then
    FMaxLoad := FCapacity - 1;
end;

procedure TSimpleHashMap.InitCapacity(aCapacity: SizeUInt);
var i: SizeUInt;
begin
  if aCapacity < 4 then aCapacity := 4;
  aCapacity := NextPow2(aCapacity);
  SetLength(FBuckets, aCapacity);
  FCapacity := aCapacity;
  FMask := aCapacity - 1;
  FCount := 0;
  FUsed := 0;
  for i := 0 to aCapacity - 1 do
    FBuckets[i].State := Ord(bsEmpty);
  RecalcMaxLoad;
end;

procedure TSimpleHashMap.Rehash(aNewCapacity: SizeUInt);
var
  oldBuckets: array of TBucket;
  oldCap, i, idx: SizeUInt;
  b: TBucket;
begin
  oldBuckets := FBuckets;
  oldCap := FCapacity;
  InitCapacity(aNewCapacity);
  
  for i := 0 to oldCap - 1 do
  begin
    b := oldBuckets[i];
    if b.State = Ord(bsOccupied) then
    begin
      idx := b.Hash and FMask;
      while FBuckets[idx].State = Ord(bsOccupied) do
        idx := (idx + 1) and FMask;
      
      FBuckets[idx].State := Ord(bsOccupied);
      FBuckets[idx].Hash := b.Hash;
      FBuckets[idx].Key := b.Key;
      FBuckets[idx].Value := b.Value;
      Inc(FCount);
      Inc(FUsed);
    end;
  end;
end;

function TSimpleHashMap.KeyHash(const AKey: K): UInt32;
var
  p: Pointer;
begin
  if Assigned(FHash) then
    Exit(FHash(AKey));
  
  // 默认哈希：简单类型
  p := @AKey;
  case SizeOf(K) of
    1: Exit(HashOfUInt32(PByte(p)^));
    2: Exit(HashOfUInt32(PWord(p)^));
    4: Exit(HashOfUInt32(PUInt32(p)^));
    8: Exit(HashOfUInt64(PQWord(p)^));
  else
    raise Exception.Create('SimpleHashMap: please provide hash function');
  end;
end;

function TSimpleHashMap.KeysEqual(const L, R: K): Boolean;
begin
  if Assigned(FEquals) then
    Exit(FEquals(L, R));
  Result := CompareByte(L, R, SizeOf(K)) = 0;
end;

function TSimpleHashMap.FindIndex(const AKey: K; AHash: UInt32; out AIndex: SizeUInt): Boolean;
var idx, start: SizeUInt;
begin
  if FCapacity = 0 then
  begin
    AIndex := 0;
    Exit(False);
  end;
  
  idx := AHash and FMask;
  start := idx;
  
  while True do
  begin
    case FBuckets[idx].State of
      Ord(bsEmpty):
      begin
        AIndex := idx;
        Exit(False);
      end;
      Ord(bsOccupied):
      begin
        if (FBuckets[idx].Hash = AHash) and KeysEqual(FBuckets[idx].Key, AKey) then
        begin
          AIndex := idx;
          Exit(True);
        end;
      end;
    end;
    
    idx := (idx + 1) and FMask;
    if idx = start then
    begin
      AIndex := idx;
      Exit(False);
    end;
  end;
end;

procedure TSimpleHashMap.Clear;
var i: SizeUInt;
begin
  if FCapacity = 0 then Exit;
  
  for i := 0 to FCapacity - 1 do
  begin
    if FBuckets[i].State = Ord(bsOccupied) then
    begin
      Finalize(FBuckets[i].Key);
      Finalize(FBuckets[i].Value);
    end;
    FBuckets[i].State := Ord(bsEmpty);
    FBuckets[i].Hash := 0;
  end;
  
  FCount := 0;
  FUsed := 0;
end;

function TSimpleHashMap.GetCount: SizeUInt;
begin
  Result := FCount;
end;

function TSimpleHashMap.GetCapacity: SizeUInt;
begin
  Result := FCapacity;
end;

function TSimpleHashMap.GetLoadFactor: Single;
begin
  if FCapacity = 0 then
    Exit(0.0);
  Result := FCount / FCapacity;
end;

procedure TSimpleHashMap.Reserve(aCapacity: SizeUInt);
begin
  if aCapacity <= FCapacity then Exit;
  if FCapacity = 0 then
    InitCapacity(aCapacity)
  else
    Rehash(NextPow2(aCapacity));
end;

function TSimpleHashMap.TryGetValue(const AKey: K; out AValue: V): Boolean;
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

function TSimpleHashMap.ContainsKey(const AKey: K): Boolean;
var dummy: V;
begin
  Result := TryGetValue(AKey, dummy);
end;

function TSimpleHashMap.Add(const AKey: K; const AValue: V): Boolean;
var
  h: UInt32;
  idx, firstTomb, start: SizeUInt;
  st: Byte;
begin
  if FCapacity = 0 then
    InitCapacity(4);
  if FUsed >= FMaxLoad then
    Rehash(FCapacity shl 1);
  
  h := KeyHash(AKey);
  idx := h and FMask;
  start := idx;
  firstTomb := SizeUInt(-1);
  
  while True do
  begin
    st := FBuckets[idx].State;
    
    if st = Ord(bsEmpty) then
    begin
      if firstTomb <> SizeUInt(-1) then
        idx := firstTomb;
      
      FBuckets[idx].State := Ord(bsOccupied);
      FBuckets[idx].Hash := h;
      FBuckets[idx].Key := AKey;
      FBuckets[idx].Value := AValue;
      Inc(FCount);
      Inc(FUsed);
      Exit(True);
    end
    else if st = Ord(bsTombstone) then
    begin
      if firstTomb = SizeUInt(-1) then
        firstTomb := idx;
    end
    else // Occupied
    begin
      if (FBuckets[idx].Hash = h) and KeysEqual(FBuckets[idx].Key, AKey) then
        Exit(False);
    end;
    
    idx := (idx + 1) and FMask;
    if idx = start then
      raise Exception.Create('HashMap is full');
  end;
end;

function TSimpleHashMap.AddOrAssign(const AKey: K; const AValue: V): Boolean;
var
  h: UInt32;
  idx, firstTomb, start: SizeUInt;
  st: Byte;
begin
  if FCapacity = 0 then
    InitCapacity(4);
  if FUsed >= FMaxLoad then
    Rehash(FCapacity shl 1);
  
  h := KeyHash(AKey);
  idx := h and FMask;
  start := idx;
  firstTomb := SizeUInt(-1);
  
  while True do
  begin
    st := FBuckets[idx].State;
    
    if st = Ord(bsEmpty) then
    begin
      if firstTomb <> SizeUInt(-1) then
        idx := firstTomb;
      
      FBuckets[idx].State := Ord(bsOccupied);
      FBuckets[idx].Hash := h;
      FBuckets[idx].Key := AKey;
      FBuckets[idx].Value := AValue;
      Inc(FCount);
      Inc(FUsed);
      Exit(True);
    end
    else if st = Ord(bsTombstone) then
    begin
      if firstTomb = SizeUInt(-1) then
        firstTomb := idx;
    end
    else // Occupied
    begin
      if (FBuckets[idx].Hash = h) and KeysEqual(FBuckets[idx].Key, AKey) then
      begin
        Finalize(FBuckets[idx].Value);
        FBuckets[idx].Value := AValue;
        Exit(False);
      end;
    end;
    
    idx := (idx + 1) and FMask;
    if idx = start then
      raise Exception.Create('HashMap is full');
  end;
end;

function TSimpleHashMap.Remove(const AKey: K): Boolean;
var idx: SizeUInt; h: UInt32;
begin
  if FCapacity = 0 then Exit(False);
  
  h := KeyHash(AKey);
  if not FindIndex(AKey, h, idx) then Exit(False);
  
  Finalize(FBuckets[idx].Key);
  Finalize(FBuckets[idx].Value);
  FBuckets[idx].State := Ord(bsTombstone);
  FBuckets[idx].Hash := 0;
  Dec(FCount);
  Result := True;
end;

end.
