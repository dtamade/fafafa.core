unit fafafa.core.mem.pool.slab;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.mem.allocator.base,
  fafafa.core.mem.pool.base,
  fafafa.core.mem.pool.memoryPool,
  fafafa.core.mem.pool.fixedSlab,
  fafafa.core.mem.error;        // EAllocError, TAllocError

type
  // 性能计数器（供测试）
  TSlabPerfCounters = record
    AllocCalls : QWord;
    FreeCalls  : QWord;
    AllocTime  : QWord;
    FreeTime   : QWord;
    PageMerges : QWord;
    MergeTime  : QWord;
    MergedPages: QWord;
  end;

  // 兼容配置
  TSlabConfig = record
    MinShift: SizeUInt;            // 默认 3 (8B)
    EnablePageMerging: Boolean;    // 兼容字段（当前未用）
    MaxAllocSize: SizeUInt;        // 0=不限制（无限扩展）；>0 时限制单次分配
  end;

  {** 无效大小异常（继承自 EAllocError）| Invalid size exception *}
  ESlabPoolInvalidSize = class(EAllocError);
  {** Slab 池损坏异常 | Slab pool corruption exception *}
  ESlabPoolCorruption  = class(EAllocError);


  // Auto-expanding slab pool built atop TFixedSlabPool segments
  TSlabPool = class(TInterfacedObject, IMemoryPool, IAllocator)
  private
    FAllocator: IAllocator;
    FSegments: array of TFixedSlabPool;
    FActive: Integer;
    FInitialCapacity, FMinShift: SizeUInt;
    FAvail: array of Integer; // LIFO of segments likely with free space
    FAvailCount: Integer;     // 实际使用的元素数量（避免每次 SetLength）
    FConfig: TSlabConfig;
    FTotalAllocs: SizeUInt;
    FTotalFrees: SizeUInt;
    FPerf: TSlabPerfCounters;
    // Page -> segment hash map (O(1) owner lookup)
    FPageKeys: array of PtrUInt;  // store key+1; 0 = empty
    FPageVals: array of Integer;  // segment index
    FPageMask: SizeUInt;          // capacity - 1, power of two
    FPageHighShift: SizeUInt;     // 64 - log2(capacity)
    FPageCount: SizeUInt;         // number of occupied entries
  private
    function TryAllocFromSeg(const aIdx: Integer; const aSize: SizeUInt): Pointer; inline;
    function PopAvail(out aIdx: Integer): Boolean; inline;
    procedure PushAvail(const aIdx: Integer); inline;
    function NewSegmentCapacity: SizeUInt; inline;
    function FindOwnerSegment(aPtr: Pointer): Integer; inline; // fallback scan
    function IsOversize(const aSize: SizeUInt): Boolean; inline;
    // page map helpers
    function PageKeyOf(aPtr: Pointer): PtrUInt; inline;
    procedure PageMapInit(aMinCapacity: SizeUInt);
    procedure PageMapClear;
    procedure PageMapGrowIfNeeded(aNeedMore: SizeUInt);
    procedure PageMapInsert(aKey: PtrUInt; aSegIdx: Integer);
    function PageMapLookup(aKey: PtrUInt; out aSegIdx: Integer): Boolean; inline;
    procedure IndexSegmentPages(aSegIdx: Integer);
  public
    constructor Create(aCapacity: SizeUInt; aAllocator: IAllocator = nil; aMinShift: SizeUInt = 3); overload;
    constructor Create(aCapacity: SizeUInt; const aConfig: TSlabConfig; aAllocator: IAllocator = nil); overload;
    destructor Destroy; override;
    // IPool
    function Acquire(out aPtr: Pointer): Boolean;
    function TryAcquire(out aPtr: Pointer): Boolean; inline;
    function AcquireN(out aUnits: array of Pointer; aCount: Integer): Integer;
    procedure Release(aPtr: Pointer);
    procedure ReleaseN(const aUnits: array of Pointer; aCount: Integer);
    procedure Reset;
    // IAllocator aligned allocation
    function AllocAligned(aSize, aAlignment: SizeUInt): Pointer;
    procedure FreeAligned(aPtr: Pointer);
    // IMemoryPool + IAllocator
    // Compatibility helpers for older tests
    function Alloc(aSize: SizeUInt): Pointer; inline;
    procedure Free(aPtr: Pointer); overload; inline;
    function Warmup(aUnitSize: SizeUInt; aMinPages: SizeUInt): SizeUInt;

    function GetMem(aSize: SizeUInt): Pointer;
    function AllocMem(aSize: SizeUInt): Pointer;
    function ReallocMem(aDst: Pointer; aSize: SizeUInt): Pointer;
    procedure FreeMem(aDst: Pointer);
    // 兼容统计
    property TotalAllocs: SizeUInt read FTotalAllocs;
    property TotalFrees : SizeUInt read FTotalFrees;
    // IAllocator capability
    function Traits: TAllocatorTraits;

  end;

function CreateDefaultSlabConfig: TSlabConfig;
function CreateSlabConfigWithPageMerging: TSlabConfig;
implementation

const
  HASH_MIN_CAP = 64;

{$push}
{$Q-}
function MulHash64(x: QWord): QWord; inline;
begin
  Result := x * QWord(11400714819323198485);
end;
{$pop}

function CreateDefaultSlabConfig: TSlabConfig;
begin
  Result.MinShift := 3;
  Result.EnablePageMerging := False;
  Result.MaxAllocSize := 0; // unlimited by default
end;

function CreateSlabConfigWithPageMerging: TSlabConfig;
begin
  Result := CreateDefaultSlabConfig;
  Result.EnablePageMerging := True;
end;

function TSlabPool.IsOversize(const aSize: SizeUInt): Boolean; inline;
begin
  if aSize=0 then Exit(False);
  if FConfig.MaxAllocSize>0 then Exit(aSize>FConfig.MaxAllocSize);
  // 兼容旧测试：若不配置上限，则单次申请不得超过初始容量（可按需调整为 False 以完全无限）
  Exit(aSize > FInitialCapacity);
end;



function TSlabPool.PageKeyOf(aPtr: Pointer): PtrUInt; inline;
begin
  Result := PtrUInt(aPtr) shr TFixedSlabPool(FSegments[0]).PageShift;
end;

procedure TSlabPool.PageMapInit(aMinCapacity: SizeUInt);
var cap, i, m, tmp: SizeUInt;
begin
  cap := HASH_MIN_CAP;
  while cap < aMinCapacity do cap := cap shl 1;
  SetLength(FPageKeys, cap);
  SetLength(FPageVals, cap);
  for i := 0 to cap-1 do begin FPageKeys[i] := 0; FPageVals[i] := -1; end;
  FPageMask := cap-1;
  // compute high-bit shift = 64 - log2(cap)
  m := 0; tmp := cap;
  while tmp > 1 do begin Inc(m); tmp := tmp shr 1; end;
  FPageHighShift := SizeUInt(64 - m);
  FPageCount := 0;
end;

procedure TSlabPool.PageMapClear;
var i: SizeUInt;
begin
  for i := 0 to FPageMask do begin FPageKeys[i] := 0; FPageVals[i] := -1; end;
  FPageCount := 0;
end;

procedure TSlabPool.PageMapGrowIfNeeded(aNeedMore: SizeUInt);
var oldKeys: array of PtrUInt; oldVals: array of Integer; oldCap, i, m, tmp: SizeUInt; key: PtrUInt; val, idx: Integer; h: QWord;
begin
  if (FPageCount + aNeedMore) <= ((FPageMask+1) shr 1) then Exit; // load <= 0.5
  oldCap := FPageMask+1;
  oldKeys := FPageKeys; oldVals := FPageVals;
  SetLength(FPageKeys, oldCap shl 1);
  SetLength(FPageVals, oldCap shl 1);
  FPageMask := (oldCap shl 1) - 1;
  // recompute high shift
  m := 0; tmp := (FPageMask + 1);
  while tmp > 1 do begin Inc(m); tmp := tmp shr 1; end;
  FPageHighShift := SizeUInt(64 - m);
  for i := 0 to FPageMask do begin FPageKeys[i] := 0; FPageVals[i] := -1; end;
  FPageCount := 0;
  for i := 0 to oldCap-1 do begin
    key := oldKeys[i];
    if key <> 0 then begin
      val := oldVals[i];
      // reinsert
      h := MulHash64(key);
      idx := (h shr FPageHighShift) and FPageMask;
      while FPageKeys[idx] <> 0 do idx := (idx + 1) and FPageMask;
      FPageKeys[idx] := key; FPageVals[idx] := val; Inc(FPageCount);
    end;
  end;
end;

procedure TSlabPool.PageMapInsert(aKey: PtrUInt; aSegIdx: Integer);
var idx: SizeUInt; h: QWord;
begin
  if aKey = 0 then aKey := 1; // reserve 0 as empty
  h := MulHash64(aKey);
  idx := (h shr FPageHighShift) and FPageMask;
  while FPageKeys[idx] <> 0 do idx := (idx + 1) and FPageMask;
  FPageKeys[idx] := aKey; FPageVals[idx] := aSegIdx; Inc(FPageCount);
end;

function TSlabPool.PageMapLookup(aKey: PtrUInt; out aSegIdx: Integer): Boolean; inline;
var idx: SizeUInt; h: QWord;
begin
  if aKey = 0 then aKey := 1;
  h := MulHash64(aKey);
  idx := (h shr FPageHighShift) and FPageMask;
  while True do
  begin
    if FPageKeys[idx] = 0 then Exit(False);
    if FPageKeys[idx] = aKey then begin aSegIdx := FPageVals[idx]; Exit(True); end;
    idx := (idx + 1) and FPageMask;
  end;
end;

procedure TSlabPool.IndexSegmentPages(aSegIdx: Integer);
var p, e: PByte; step: SizeUInt; need, cnt: SizeUInt; key: PtrUInt;
begin
  p := FSegments[aSegIdx].RegionStart;
  e := FSegments[aSegIdx].RegionEnd;
  step := SizeUInt(1) shl FSegments[aSegIdx].PageShift;
  if p=nil then Exit;
  // estimate number of pages to grow
  need := (PtrUInt(e) - PtrUInt(p)) shr FSegments[aSegIdx].PageShift;
  if need=0 then Exit;
  PageMapGrowIfNeeded(need);
  cnt := 0;
  while PtrUInt(p) < PtrUInt(e) do
  begin
    key := (PtrUInt(p) shr FSegments[aSegIdx].PageShift);
    PageMapInsert(key, aSegIdx);
    Inc(cnt);
    Inc(PtrUInt(p), step);
  end;
end;

constructor TSlabPool.Create(aCapacity: SizeUInt; aAllocator: IAllocator; aMinShift: SizeUInt);
var S: TFixedSlabPool;
begin
  inherited Create;
  if aAllocator=nil then FAllocator:=fafafa.core.mem.allocator.GetRtlAllocator else FAllocator:=aAllocator;
  if aCapacity=0 then aCapacity:=64*1024;
  if aMinShift=0 then aMinShift:=3;


  FInitialCapacity:=aCapacity; FMinShift:=aMinShift; FActive:=0;
  SetLength(FSegments,1);
  S:=TFixedSlabPool.Create(aCapacity,FAllocator,aMinShift);
  FSegments[0]:=S;
  FAvailCount := 0;  // 显式初始化
  PageMapInit( (aCapacity shr S.PageShift) * 2 );
  IndexSegmentPages(0);
end;

function TSlabPool.Traits: TAllocatorTraits;
begin
  Result.ZeroInitialized := True;   // AllocMem 保证零填充
  Result.ThreadSafe      := False;  // 当前未加锁
  Result.HasMemSize      := True;   // 通过 ChunkSizeOf/MemSizeOf
  Result.SupportsAligned := False;  // 未提供对齐 API
end;

constructor TSlabPool.Create(aCapacity: SizeUInt; const aConfig: TSlabConfig; aAllocator: IAllocator);
begin
  // 忽略 aConfig.EnablePageMerging（兼容字段）
  // MinShift 和 MaxAllocSize 采纳
  FConfig := aConfig;
  if FConfig.MinShift=0 then FConfig.MinShift := 3;
  Create(aCapacity, aAllocator, FConfig.MinShift);
end;

function TSlabPool.Alloc(aSize: SizeUInt): Pointer; inline;
begin
  Result := GetMem(aSize);
end;

procedure TSlabPool.Free(aPtr: Pointer); inline;
begin
  FreeMem(aPtr);
end;





function TSlabPool.Warmup(aUnitSize: SizeUInt; aMinPages: SizeUInt): SizeUInt;
var
  i: SizeUInt;
  perPage, needUnits: SizeUInt;
  tmp: array of Pointer;
begin
  if aUnitSize = 0 then Exit(0);
  perPage := (SizeUInt(1) shl FSegments[0].PageShift) div aUnitSize;
  if perPage = 0 then perPage := 1;
  needUnits := perPage * aMinPages;
  SetLength(tmp, needUnits);
  Result := 0;
  for i := 0 to needUnits-1 do
  begin
    tmp[i] := GetMem(aUnitSize);
    if tmp[i] <> nil then Inc(Result) else Break;
  end;
  for i := 0 to Result-1 do
    FreeMem(tmp[i]);
end;




destructor TSlabPool.Destroy;
var i:Integer;
begin
  for i:=0 to High(FSegments) do if FSegments[i]<>nil then FSegments[i].Free;
  inherited Destroy;
end;

function TSlabPool.TryAllocFromSeg(const aIdx: Integer; const aSize: SizeUInt): Pointer; inline;
begin
  if (aIdx>=0) and (aIdx<=High(FSegments)) and (FSegments[aIdx]<>nil) then Result:=FSegments[aIdx].GetMem(aSize)
  else Result:=nil;
end;

function TSlabPool.PopAvail(out aIdx: Integer): Boolean; inline;
begin
  if FAvailCount = 0 then Exit(False);
  Dec(FAvailCount);
  aIdx := FAvail[FAvailCount];
  Result := True;
end;

procedure TSlabPool.PushAvail(const aIdx: Integer); inline;
var cap: Integer;
begin
  cap := Length(FAvail);
  if FAvailCount >= cap then
  begin
    // 容量倍增策略，最小 8
    if cap < 8 then cap := 8
    else cap := cap * 2;
    SetLength(FAvail, cap);
  end;
  FAvail[FAvailCount] := aIdx;
  Inc(FAvailCount);
end;

function TSlabPool.NewSegmentCapacity: SizeUInt; inline;
var cur:SizeUInt;
begin
  if (FActive>=0) and (FActive<=High(FSegments)) and (FSegments[FActive]<>nil) then cur:=FSegments[FActive].Capacity else cur:=FInitialCapacity;
  if cur< FInitialCapacity then cur:=FInitialCapacity;
  if cur> (High(SizeUInt) shr 1) then Exit(cur);
  Result:=cur shl 1;
end;

function TSlabPool.FindOwnerSegment(aPtr: Pointer): Integer;
var key: PtrUInt; seg: Integer;
begin
  if aPtr=nil then Exit(-1);
  key := PageKeyOf(aPtr);
  if PageMapLookup(key, seg) then Exit(seg) else Exit(-1);
end;

function TSlabPool.Acquire(out aPtr: Pointer): Boolean;
begin aPtr:=GetMem(SizeOf(Pointer)); Result:=aPtr<>nil; end;

procedure TSlabPool.Release(aPtr: Pointer);
begin FreeMem(aPtr); end;

function TSlabPool.GetMem(aSize: SizeUInt): Pointer;
var idx:Integer; p:Pointer;
begin
  if aSize=0 then Exit(nil);
  if IsOversize(aSize) then Exit(nil);
  p:=TryAllocFromSeg(FActive,aSize);
  if p<>nil then begin Inc(FTotalAllocs); Exit(p); end;
  while PopAvail(idx) do begin p:=TryAllocFromSeg(idx,aSize); if p<>nil then begin FActive:=idx; Inc(FTotalAllocs); Exit(p); end; end;
  idx:=Length(FSegments);
  SetLength(FSegments,idx+1);
  FSegments[idx]:=TFixedSlabPool.Create(NewSegmentCapacity,FAllocator,FMinShift);
  IndexSegmentPages(idx);
  FActive:=idx;
  Result:=FSegments[idx].GetMem(aSize);
  if Result<>nil then Inc(FTotalAllocs);
end;

function TSlabPool.AllocMem(aSize: SizeUInt): Pointer;
begin Result:=GetMem(aSize); if Result<>nil then FillChar(Result^,aSize,0); end;

function TSlabPool.ReallocMem(aDst: Pointer; aSize: SizeUInt): Pointer;
var idx:Integer; oldSize, copySize: SizeUInt;
begin
  if aDst=nil then Exit(GetMem(aSize));
  if aSize=0 then begin FreeMem(aDst); Exit(nil); end;
  idx:=FindOwnerSegment(aDst);
  if idx>=0 then
  begin
    Result:=FSegments[idx].ReallocMem(aDst,aSize);
    if Result<>nil then Exit;
    // 跨段：安全拷贝再释放旧指针
    Result := GetMem(aSize);
    if Result=nil then Exit(nil);
    oldSize := FSegments[idx].MemSizeOf(aDst);
    if oldSize > aSize then copySize := aSize else copySize := oldSize;
    if copySize>0 then Move(aDst^, Result^, copySize);
    FSegments[idx].FreeMem(aDst);
    Exit;
  end;
  // ✅ P0-3: 未知归属指针处理 - 可能来自 AllocAligned 的 fallback 路径
  // 必须尝试用 FAllocator 处理，否则会导致内存泄漏
  if FAllocator <> nil then
  begin
    // 使用 fallback allocator 的 ReallocMem
    // 注意：这里无法获取旧大小，依赖 FAllocator 的实现
    Result := FAllocator.ReallocMem(aDst, aSize);
  end
  else
  begin
    // 无 fallback allocator：返回 nil 表示失败，不修改原指针
    // 这比之前的"分配新内存但不拷贝不释放"更安全
    Result := nil;
  end;
end;

procedure TSlabPool.FreeMem(aDst: Pointer);
var idx:Integer;
begin
  if aDst=nil then Exit;
  idx:=FindOwnerSegment(aDst);
  if idx>=0 then
  begin
    FSegments[idx].FreeMem(aDst);
    PushAvail(idx);
    Inc(FTotalFrees);
  end
  else if FAllocator <> nil then
  begin
    // ✅ P0-3: 未知归属指针可能来自 AllocAligned 的 fallback 路径
    // 尝试用 FAllocator.FreeMem 释放
    FAllocator.FreeMem(aDst);
    Inc(FTotalFrees);
  end;
  // 如果没有 FAllocator 且指针不属于任何段，则无法释放（静默忽略）
  // 这可能是调用者的错误，但我们不能崩溃
end;

procedure TSlabPool.Reset;
var i:Integer;
begin
  for i:=0 to High(FSegments) do if FSegments[i]<>nil then FSegments[i].Reset;
  FAvailCount := 0;  // 只重置计数，保留容量
  FActive:=0;
end;

function TSlabPool.TryAcquire(out aPtr: Pointer): Boolean;
begin
  Result := Acquire(aPtr);
end;

function TSlabPool.AcquireN(out aUnits: array of Pointer; aCount: Integer): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to aCount - 1 do
  begin
    if not Acquire(aUnits[i]) then
      Break;
    Inc(Result);
  end;
end;

procedure TSlabPool.ReleaseN(const aUnits: array of Pointer; aCount: Integer);
var
  i: Integer;
begin
  for i := 0 to aCount - 1 do
    Release(aUnits[i]);
end;

function TSlabPool.AllocAligned(aSize, aAlignment: SizeUInt): Pointer;
begin
  // Slab size classes already provide natural alignment based on block size
  if (aAlignment <= 8) or (aAlignment <= aSize) then
    Result := GetMem(aSize)
  else if FAllocator <> nil then
    Result := FAllocator.AllocAligned(aSize, aAlignment)
  else
    Result := nil;
end;

procedure TSlabPool.FreeAligned(aPtr: Pointer);
var
  idx: Integer;
begin
  if aPtr = nil then Exit;
  idx := FindOwnerSegment(aPtr);
  if idx >= 0 then
  begin
    FSegments[idx].FreeMem(aPtr);
    PushAvail(idx);
    Inc(FTotalFrees);
  end
  else if FAllocator <> nil then
    FAllocator.FreeAligned(aPtr);
end;

end.

