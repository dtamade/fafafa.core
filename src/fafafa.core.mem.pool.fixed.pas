unit fafafa.core.mem.pool.fixed;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.mem.pool.base,    // IPool (decoupled from facade)
  fafafa.core.mem.allocator;     // IAllocator + GetRtlAllocator

// 说明：
// - 固定块内存池（Fixed-size Pool），支持逐块分配/归还
// - 当前版本：
//   * Free(nil) = no-op（统一语义）
//   * Reset 重建自由栈，避免后续分配退化扫描
//   * 释放与分配均为 O(1)（自由栈 + 索引快速定位）
//   * 默认对齐：Alignment = max(SizeOf(Pointer), 16)；BlockSize 必须是 Alignment 的倍数
//   * 线程安全：当前实现不内置并发控制，需要外部同步；或采用后续线程本地/并发变体

type
  EMemFixedPoolError = class(Exception);
  EMemFixedPoolInvalidPointer = class(EMemFixedPoolError);
  EMemFixedPoolDoubleFree = class(EMemFixedPoolError);

  TFixedPoolConfig = record
    BlockSize: SizeUInt;
    Capacity: Integer;
    Alignment: SizeUInt;    // 新增：对齐（默认 max(pointer,16)）
    ZeroOnAlloc: Boolean;   // 分配后清零（可选，默认 False）
    Allocator: IAllocator;
  end;

  { TFixedPool }
  TFixedPool = class(TInterfacedObject, IPool)
  private
    FBlockSize: SizeUInt;
    FCapacity: Integer;
    FAllocatedCount: Integer;
    FBuffer: Pointer;            // 对齐后的可用起始地址（Arena 内部）
    FTotalSize: SizeUInt;        // 总大小 = BlockSize * Capacity
    FFreeStack: array of Integer;// 可用块索引栈
    FFreeTop: Integer;           // 栈顶（可用元素个数）
    FIsFree: array of Boolean;   // 双重释放检测
    FAllocator: IAllocator;
    FZeroOnAlloc: Boolean;       // 每次分配是否清零
    // 对齐与原始缓冲
    FAlignment: SizeUInt;        // 实际使用的对齐（默认为 max(pointer,16)）
    FRawBuffer: Pointer;         // 原始分配指针，用于释放
    // 统计
    FPeakAllocated: Integer;
    FTotalAllocCalls: QWord;
    FTotalFreeCalls: QWord;
  private
    procedure PushFreeIndex(AIndex: Integer); inline;
    function PopFreeIndex(out AIndex: Integer): Boolean; inline;
    procedure RebuildFreeStack; inline;
    function GetAvailable: Integer; inline;
  public
    // 构造/析构
    constructor Create(ABlockSize: SizeUInt; ACapacity: Integer; AAllocator: IAllocator = nil); overload;
    constructor Create(ABlockSize: SizeUInt; ACapacity: Integer; AAlignment: SizeUInt; AAllocator: IAllocator = nil); overload;
    constructor Create(const AConfig: TFixedPoolConfig); overload;
    destructor Destroy; override;
  public
    // 固定块 API
    function Alloc: Pointer; inline;
    function TryAlloc(out APtr: Pointer): Boolean; inline;
    procedure ReleasePtr(APtr: Pointer); inline;
    procedure Reset; inline;
    procedure GetArenaRange(out Base: Pointer; out Size: SizeUInt); inline;

    // IPool（统一对外最小接口）
    function Acquire(out AUnit: Pointer): Boolean; inline;
    function TryAcquire(out AUnit: Pointer): Boolean; inline; // alias
    function AcquireN(out AUnits: array of Pointer; aCount: Integer): Integer; inline;
    procedure Release(AUnit: Pointer); inline;
    procedure ReleaseN(const AUnits: array of Pointer; aCount: Integer); inline;

    // 辅助：判断指针是否属于本池（不检查对齐与双重释放，仅范围）
    function Owns(APtr: Pointer): Boolean; inline;

    // 只读属性
    property BlockSize: SizeUInt read FBlockSize;
    property Capacity: Integer read FCapacity;
    property AllocatedCount: Integer read FAllocatedCount;
    property Alignment: SizeUInt read FAlignment;
    property Available: Integer read GetAvailable;
    property PeakAllocated: Integer read FPeakAllocated;
    property TotalAllocCalls: QWord read FTotalAllocCalls;
    property TotalFreeCalls: QWord read FTotalFreeCalls;
  end;

implementation

{ TFixedPool }

procedure TFixedPool.PushFreeIndex(AIndex: Integer);
begin
  FFreeStack[FFreeTop] := AIndex;
  Inc(FFreeTop);
end;

function TFixedPool.PopFreeIndex(out AIndex: Integer): Boolean;
begin
  if FFreeTop > 0 then
  begin
    Dec(FFreeTop);
    AIndex := FFreeStack[FFreeTop];
    Exit(True);
  end;
  Result := False;
end;

procedure TFixedPool.RebuildFreeStack;
var
  I: Integer;
begin
  FFreeTop := 0;
  for I := 0 to FCapacity - 1 do
  begin
    FIsFree[I] := True;
    PushFreeIndex(I);
  end;
  FAllocatedCount := 0;
end;

constructor TFixedPool.Create(ABlockSize: SizeUInt; ACapacity: Integer; AAllocator: IAllocator);
begin
  Create(ABlockSize, ACapacity, 0{use default}, AAllocator);
end;

constructor TFixedPool.Create(ABlockSize: SizeUInt; ACapacity: Integer; AAlignment: SizeUInt; AAllocator: IAllocator);
var
  LOverflowCheck: SizeUInt;
  LRaw: Pointer;
  LAlign, LMask: SizeUInt;
  LAddr, LAligned: PtrUInt;
begin
  inherited Create;
  if ABlockSize = 0 then
    raise EMemFixedPoolError.Create('Block size cannot be zero');
  if (SizeOf(Pointer) <> 0) and ((ABlockSize mod SizeOf(Pointer)) <> 0) then
    raise EMemFixedPoolError.Create('Block size must be a multiple of pointer size');
  if ACapacity <= 0 then
    raise EMemFixedPoolError.Create('Capacity must be positive');

  FBlockSize := ABlockSize;
  FCapacity := ACapacity;
  FAllocatedCount := 0;
  FPeakAllocated := 0;
  FTotalAllocCalls := 0;
  FTotalFreeCalls := 0;

  if AAllocator = nil then
    FAllocator := fafafa.core.mem.allocator.GetRtlAllocator
  else
    FAllocator := AAllocator;

  // Alignment: 默认 max(pointer,16)；必须为 2 的幂
  if AAlignment = 0 then
  begin
    if SizeOf(Pointer) >= 16 then FAlignment := SizeOf(Pointer) else FAlignment := 16;
  end
  else
    FAlignment := AAlignment;
  if (FAlignment and (FAlignment-1)) <> 0 then
    raise EMemFixedPoolError.Create('Alignment must be power of two');
  if (FBlockSize mod FAlignment) <> 0 then
    raise EMemFixedPoolError.Create('Block size must be a multiple of alignment');

  // 计算总大小并检查溢出
  FTotalSize := FBlockSize * SizeUInt(FCapacity);
  if (FBlockSize <> 0) then
  begin
    LOverflowCheck := FTotalSize div FBlockSize;
    if LOverflowCheck <> SizeUInt(FCapacity) then
      raise EMemFixedPoolError.Create('Total size overflow');
  end;

  // 分配连续 Arena（对齐）
  // 如果分配器不提供对齐接口，则 over-allocate 并手动对齐
  LRaw := FAllocator.GetMem(FTotalSize + (FAlignment - 1));
  if LRaw = nil then
    raise EMemFixedPoolError.Create('Failed to allocate arena buffer');
  FRawBuffer := LRaw;
  LAddr := PtrUInt(LRaw);
  LMask := FAlignment - 1;
  LAligned := (LAddr + LMask) and not LMask;
  FBuffer := Pointer(LAligned);

  SetLength(FFreeStack, FCapacity);
  SetLength(FIsFree, FCapacity);
  FFreeTop := 0;

  RebuildFreeStack;
end;

constructor TFixedPool.Create(const AConfig: TFixedPoolConfig);
begin
  Create(AConfig.BlockSize, AConfig.Capacity, AConfig.Alignment, AConfig.Allocator);
  FZeroOnAlloc := AConfig.ZeroOnAlloc;
  if AConfig.ZeroOnAlloc and (FBuffer <> nil) and (FTotalSize > 0) then
    FillChar(FBuffer^, FTotalSize, 0);
end;

destructor TFixedPool.Destroy;
begin
  {$IFDEF FAF_MEM_DEBUG}
  if FAllocatedCount <> 0 then
    raise EMemFixedPoolError.CreateFmt('Memory leak: %d blocks not freed', [FAllocatedCount]);
  {$ENDIF}
  if FRawBuffer <> nil then
    FAllocator.FreeMem(FRawBuffer)
  else if FBuffer <> nil then
    FAllocator.FreeMem(FBuffer);
  FBuffer := nil;
  FRawBuffer := nil;
  SetLength(FFreeStack, 0);
  SetLength(FIsFree, 0);
  inherited Destroy;
end;



function TFixedPool.Alloc: Pointer;
var
  LIdx: Integer;
  LPtr: Pointer;
begin
  Result := nil;
  if not PopFreeIndex(LIdx) then Exit(nil);
  if not FIsFree[LIdx] then Exit(nil); // 不应发生
  FIsFree[LIdx] := False;
  Inc(FAllocatedCount);

  LPtr := Pointer(PByte(FBuffer) + SizeUInt(LIdx) * FBlockSize);
  if FZeroOnAlloc and (FBlockSize > 0) then
    FillChar(LPtr^, FBlockSize, 0);
  if FAllocatedCount > FPeakAllocated then
    FPeakAllocated := FAllocatedCount;
  Inc(FTotalAllocCalls);
  Result := LPtr;
end;

function TFixedPool.TryAlloc(out APtr: Pointer): Boolean;
begin
  APtr := Alloc;
  Result := APtr <> nil;
end;

function TFixedPool.Owns(APtr: Pointer): Boolean;
begin
  Result := (APtr <> nil) and (APtr >= FBuffer) and (APtr < Pointer(PByte(FBuffer) + FTotalSize));
end;

function TFixedPool.GetAvailable: Integer;
begin
  Result := FCapacity - FAllocatedCount;
end;

procedure TFixedPool.GetArenaRange(out Base: Pointer; out Size: SizeUInt);
begin
  Base := FBuffer;
  Size := FTotalSize;
end;


procedure TFixedPool.ReleasePtr(APtr: Pointer);
var
  LDiff, LIdxU: SizeUInt;
  LIdx: Integer;
begin
  if APtr = nil then Exit; // Free(nil) = no-op
  if (FBuffer = nil) or (FTotalSize = 0) then
    raise EMemFixedPoolInvalidPointer.Create('Pool is not initialized');

  // 边界检查：必须在 [FBuffer, FBuffer + FTotalSize) 范围内
  if (APtr < FBuffer) or (APtr >= Pointer(PByte(FBuffer) + FTotalSize)) then
    raise EMemFixedPoolInvalidPointer.Create('Pointer does not belong to this pool');

  // 计算与校验对齐
  LDiff := SizeUInt(PByte(APtr) - PByte(FBuffer));
  if (FBlockSize = 0) or ((LDiff mod FBlockSize) <> 0) then
    raise EMemFixedPoolInvalidPointer.Create('Pointer is not aligned to block size');

  LIdxU := LDiff div FBlockSize;
  if LIdxU >= SizeUInt(FCapacity) then
    raise EMemFixedPoolInvalidPointer.Create('Pointer index out of range');

  LIdx := Integer(LIdxU);
  if FIsFree[LIdx] then
    raise EMemFixedPoolDoubleFree.Create('Double free detected');

  {$IFDEF FAF_MEM_DEBUG}
  // 污化已释放内存，提升 UAF 暴露率
  FillChar(PByte(FBuffer)[SizeUInt(LIdx)*FBlockSize], FBlockSize, $A5);
  {$ENDIF}
  FIsFree[LIdx] := True;
  Dec(FAllocatedCount);
  Inc(FTotalFreeCalls);
  PushFreeIndex(LIdx);
end;

procedure TFixedPool.Reset;
begin
  RebuildFreeStack;
end;

function TFixedPool.Acquire(out AUnit: Pointer): Boolean;
begin
  AUnit := Alloc;
  Result := AUnit <> nil;
end;

function TFixedPool.TryAcquire(out AUnit: Pointer): Boolean;
begin
  AUnit := Alloc;
  Result := AUnit <> nil;
end;

function TFixedPool.AcquireN(out AUnits: array of Pointer; aCount: Integer): Integer;
var i: Integer; p: Pointer;
begin
  Result := 0;
  for i := 0 to aCount-1 do begin
    p := Alloc;
    if p = nil then Exit;
    AUnits[i] := p;
    Inc(Result);
  end;
end;

procedure TFixedPool.Release(AUnit: Pointer);
begin
  ReleasePtr(AUnit);
end;

procedure TFixedPool.ReleaseN(const AUnits: array of Pointer; aCount: Integer);
var i: Integer;
begin
  for i := 0 to aCount-1 do
    ReleasePtr(AUnits[i]);
end;

end.

