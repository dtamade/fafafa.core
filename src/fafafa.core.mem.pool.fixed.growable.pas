unit fafafa.core.mem.pool.fixed.growable;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.mem.pool.base,     // IPool (decoupled)
  fafafa.core.mem.allocator;     // IAllocator + GetRtlAllocator

type
  EGrowingFixedPoolError = class(Exception);
  EGrowingFixedPoolInvalidPointer = class(EGrowingFixedPoolError);
  EGrowingFixedPoolDoubleFree = class(EGrowingFixedPoolError);

  TGrowthKind = (gkGeometric, gkLinear);

  TGrowingFixedPoolConfig = record
    BlockSize: SizeUInt;
    InitialCapacity: SizeUInt;
    GrowthKind: TGrowthKind;
    GrowthFactor: Double;  // for Geometric (>= 1.1)
    GrowthStep: SizeUInt;  // for Linear
    MaxCapacity: SizeUInt; // 0 = unlimited
    ZeroOnInit: Boolean;
    Allocator: IAllocator;
  end;

  { TGrowingFixedPool }
  TGrowingFixedPool = class(TInterfacedObject, IPool)
  private
    type
      PArena = ^TArena;
      TArena = record
        Base: Pointer;
        Blocks: SizeUInt; // number of blocks in this arena
        Size: SizeUInt;   // bytes = Blocks * BlockSize
      end;
  private
    FBlockSize: SizeUInt;
    FTotalCapacity: SizeUInt;
    FAllocatedCount: SizeUInt;

    FArenas: array of TArena;
    FArenaCount: SizeUInt;

    FFreeStack: array of Pointer;
    FFreeTop: SizeUInt;

    FAllocator: IAllocator;

    FConfig: TGrowingFixedPoolConfig;

    procedure PushFree(APtr: Pointer); inline;
    function PopFree(out APtr: Pointer): Boolean; inline;
    procedure AddArena(ABlocks: SizeUInt);
    function NextGrowthSize: SizeUInt;
    function FindArena(APtr: Pointer; out AIndex: SizeInt): Boolean;
    function PointerBelongsToArena(APtr: Pointer; const A: TArena): Boolean; inline;
  public
    constructor Create(const C: TGrowingFixedPoolConfig);
    destructor Destroy; override;

    // IPool
    function Acquire(out AUnit: Pointer): Boolean; inline;
    function TryAcquire(out APtr: Pointer): Boolean; inline;
    function AcquireN(out aPtrs: array of Pointer; aCount: Integer): Integer;
    procedure Release(AUnit: Pointer); inline;
    procedure ReleaseN(const aPtrs: array of Pointer; aCount: Integer);
    procedure Reset; inline;

    // 管理
    function ShrinkTo(AMinCapacity: SizeUInt): SizeUInt; // returns freed blocks

    // Props
    property BlockSize: SizeUInt read FBlockSize;
    property TotalCapacity: SizeUInt read FTotalCapacity;
    property AllocatedCount: SizeUInt read FAllocatedCount;
    property ArenaCount: SizeUInt read FArenaCount;
    function FreeCount: SizeUInt; inline;
  end;

implementation

function CmpPtr(L, R: Pointer): Integer; inline;
begin
  if L = R then Exit(0);
  if PtrUInt(L) < PtrUInt(R) then Exit(-1) else Exit(1);
end;

function TGrowingFixedPool.PointerBelongsToArena(APtr: Pointer; const A: TArena): Boolean;
begin
  Result := (PtrUInt(APtr) >= PtrUInt(A.Base)) and (PtrUInt(APtr) < PtrUInt(A.Base) + PtrUInt(A.Size));
end;


{ TGrowingFixedPool }

constructor TGrowingFixedPool.Create(const C: TGrowingFixedPoolConfig);
var
  InitCap: SizeUInt;
begin
  inherited Create;
  if (C.BlockSize = 0) then
    raise EGrowingFixedPoolError.Create('Block size cannot be zero');
  // 强制 2 的幂：启用位运算路径，提高释放/校验效率
  if (C.BlockSize and (C.BlockSize - 1)) <> 0 then
    raise EGrowingFixedPoolError.Create('Block size must be power of two');
  if (SizeOf(Pointer) <> 0) and ((C.BlockSize mod SizeOf(Pointer)) <> 0) then
    raise EGrowingFixedPoolError.Create('Block size must be a multiple of pointer size');

  FConfig := C;
  FBlockSize := C.BlockSize;
  if C.Allocator = nil then
    FAllocator := fafafa.core.mem.allocator.GetRtlAllocator
  else
    FAllocator := C.Allocator;

  SetLength(FArenas, 0);
  FArenaCount := 0;
  SetLength(FFreeStack, 0);
  FFreeTop := 0;
  FTotalCapacity := 0;
  FAllocatedCount := 0;

  // initial arena
  InitCap := C.InitialCapacity;
  if InitCap = 0 then InitCap := 64;
  AddArena(InitCap);
end;

procedure TGrowingFixedPool.AddArena(ABlocks: SizeUInt);
var
  Bytes: SizeUInt;
  Arena: TArena;
  I: SizeUInt;
  NewTop: SizeUInt;
  NewLen: SizeUInt;
  BasePtr: PByte;
begin
  if (ABlocks = 0) then Exit;
  if (FConfig.MaxCapacity <> 0) and (FTotalCapacity + ABlocks > FConfig.MaxCapacity) then
    ABlocks := FConfig.MaxCapacity - FTotalCapacity;
  if ABlocks = 0 then Exit;

  Bytes := ABlocks * FBlockSize;
  if (FBlockSize <> 0) and ((Bytes div FBlockSize) <> ABlocks) then
    raise EGrowingFixedPoolError.Create('Total size overflow');

  Arena.Base := FAllocator.GetMem(Bytes);
  if Arena.Base = nil then
    raise EGrowingFixedPoolError.Create('Failed to allocate arena');
  Arena.Blocks := ABlocks;
  Arena.Size := Bytes;

  if FConfig.ZeroOnInit then
    FillChar(Arena.Base^, Arena.Size, 0);

  // append arena
  SetLength(FArenas, FArenaCount + 1);
  FArenas[FArenaCount] := Arena;
  Inc(FArenaCount);

  // grow free stack space and push all blocks
  NewLen := FFreeTop + ABlocks;
  if Length(FFreeStack) < NewLen then
    SetLength(FFreeStack, NewLen);

  BasePtr := PByte(Arena.Base);
  NewTop := FFreeTop;
  for I := 0 to ABlocks - 1 do
  begin
    FFreeStack[NewTop] := Pointer(BasePtr + I * FBlockSize);
    Inc(NewTop);
  end;
  FFreeTop := NewTop;

  Inc(FTotalCapacity, ABlocks);

  // keep arenas sorted by Base for binary search in Release
  // naive insertion sort (M is small typically)
  if FArenaCount > 1 then
  begin
    I := FArenaCount - 1;
    while (I > 0) and (PtrUInt(FArenas[I-1].Base) > PtrUInt(FArenas[I].Base)) do
    begin
      Arena := FArenas[I-1];
      FArenas[I-1] := FArenas[I];
      FArenas[I] := Arena;
      Dec(I);
    end;
  end;
end;

function TGrowingFixedPool.NextGrowthSize: SizeUInt;
begin
  case FConfig.GrowthKind of
    gkLinear:
      if FConfig.GrowthStep <> 0 then Exit(FConfig.GrowthStep) else Exit(64);
  else
    if FTotalCapacity = 0 then Exit(64)
    else Exit(FTotalCapacity); // double capacity per AddArena call
  end;
end;

function TGrowingFixedPool.FindArena(APtr: Pointer; out AIndex: SizeInt): Boolean;
var
  L, R, M: SizeInt;
  P: PtrUInt;
  BaseU, EndU: PtrUInt;
begin
  Result := False;
  AIndex := -1;
  if FArenaCount = 0 then Exit;
  L := 0; R := FArenaCount - 1;
  P := PtrUInt(APtr);
  while L <= R do
  begin
    M := (L + R) shr 1;
    BaseU := PtrUInt(FArenas[M].Base);
    EndU := BaseU + PtrUInt(FArenas[M].Size);
    if (P >= BaseU) and (P < EndU) then
    begin
      AIndex := M;
      Exit(True);
    end
    else if P < BaseU then
      R := M - 1
    else
      L := M + 1;
  end;
end;

procedure TGrowingFixedPool.PushFree(APtr: Pointer);
begin
  if FFreeTop >= SizeUInt(Length(FFreeStack)) then
  begin
    if SizeUInt(Length(FFreeStack)) < (FFreeTop + 1) then
      SetLength(FFreeStack, (FFreeTop + 1) * 2)
    else
      SetLength(FFreeStack, FFreeTop + 1);
  end;
  FFreeStack[FFreeTop] := APtr;
  Inc(FFreeTop);
end;

function TGrowingFixedPool.PopFree(out APtr: Pointer): Boolean;
begin
  if FFreeTop = 0 then Exit(False);
  Dec(FFreeTop);
  APtr := FFreeStack[FFreeTop];
  Result := True;
end;

function TGrowingFixedPool.Acquire(out AUnit: Pointer): Boolean;
begin
  if not PopFree(AUnit) then
  begin
    AddArena(NextGrowthSize);
    Result := PopFree(AUnit);
  end
  else
    Result := True;
  if Result then Inc(FAllocatedCount);
end;

procedure TGrowingFixedPool.Release(AUnit: Pointer);
var
  Idx: SizeInt;
  Arena: TArena;
  Diff: SizeUInt;
  Offset: SizeUInt;
begin
  if AUnit = nil then Exit;
  if not FindArena(AUnit, Idx) then
    raise EGrowingFixedPoolInvalidPointer.Create('Pointer does not belong to this pool');
  Arena := FArenas[Idx];
  Diff := SizeUInt(PByte(AUnit) - PByte(Arena.Base));
  if (Diff >= Arena.Size) then
    raise EGrowingFixedPoolInvalidPointer.Create('Pointer out of range');
  // 位对齐检查（FBlockSize 为 2 的幂）
  if (Diff and (FBlockSize - 1)) <> 0 then
    raise EGrowingFixedPoolInvalidPointer.Create('Pointer is not aligned to block size');

  // NOTE: 双重释放检测在 growable 版本默认不持久记录（可在 DEBUG 启用 bitset）
  // 这里先直接 push 回 free stack，保持 O(1)
  PushFree(AUnit);
  Dec(FAllocatedCount);
end;

procedure TGrowingFixedPool.Reset;
var
  I, J: SizeUInt;
  BasePtr: PByte;
begin
  // 重建自由栈
  FFreeTop := 0;
  SetLength(FFreeStack, FTotalCapacity);
  for I := 0 to FArenaCount - 1 do
  begin
    BasePtr := PByte(FArenas[I].Base);
    for J := 0 to FArenas[I].Blocks - 1 do
    begin
      FFreeStack[FFreeTop] := Pointer(BasePtr + J * FBlockSize);
      Inc(FFreeTop);
    end;
  end;
  FAllocatedCount := 0;
end;

function TGrowingFixedPool.FreeCount: SizeUInt;
begin
  Result := FTotalCapacity - FAllocatedCount;
end;

function TGrowingFixedPool.ShrinkTo(AMinCapacity: SizeUInt): SizeUInt;
var
  Keep: SizeUInt;
  I: SizeInt;
  Removed: SizeUInt;
  A: TArena;
  K: SizeUInt;
  J: SizeInt;
  P: Pointer;
begin
  Result := 0;
  if FArenaCount = 0 then Exit;
  if AMinCapacity < FAllocatedCount then
    Keep := FAllocatedCount
  else
    Keep := AMinCapacity;

  I := FArenaCount - 1;
  while (I >= 0) and (FTotalCapacity > Keep) do
  begin
    A := FArenas[I];
    if (FTotalCapacity - A.Blocks) < Keep then Break;

    // 统计并移除自由栈中属于该 Arena 的空闲块
    Removed := 0;
    J := FFreeTop - 1;
    while (J >= 0) and (Removed < A.Blocks) do
    begin
      P := FFreeStack[J];
      if PointerBelongsToArena(P, A) then
      begin
        // swap-remove at J with top-1; do not decrement J, re-examine swapped element
        FFreeStack[J] := FFreeStack[FFreeTop - 1];
        Dec(FFreeTop);
        Inc(Removed);
        Continue;
      end;
      Dec(J);
    end;

    if Removed = A.Blocks then
    begin
      FAllocator.FreeMem(A.Base);
      Dec(FTotalCapacity, A.Blocks);
      // 删除该 Arena
      for K := I to FArenaCount - 2 do
        FArenas[K] := FArenas[K + 1];
      Dec(FArenaCount);
      SetLength(FArenas, FArenaCount);
      Inc(Result, A.Blocks);
    end
    else
      Break;

    Dec(I);
  end;
end;

destructor TGrowingFixedPool.Destroy;
var
  I: SizeInt;
begin
  for I := 0 to FArenaCount - 1 do
    if FArenas[I].Base <> nil then
      FAllocator.FreeMem(FArenas[I].Base);
  SetLength(FArenas, 0);
  SetLength(FFreeStack, 0);
  inherited Destroy;
end;

function TGrowingFixedPool.TryAcquire(out APtr: Pointer): Boolean;
begin
  Result := Acquire(APtr);
end;

function TGrowingFixedPool.AcquireN(out aPtrs: array of Pointer; aCount: Integer): Integer;
var
  I: Integer;
  P: Pointer;
begin
  Result := 0;
  for I := 0 to aCount - 1 do
  begin
    if I > High(aPtrs) then
      Break;
    if Acquire(P) then
    begin
      aPtrs[I] := P;
      Inc(Result);
    end
    else
      Break;
  end;
end;

procedure TGrowingFixedPool.ReleaseN(const aPtrs: array of Pointer; aCount: Integer);
var
  I: Integer;
begin
  for I := 0 to aCount - 1 do
  begin
    if I > High(aPtrs) then
      Break;
    Release(aPtrs[I]);
  end;
end;


end.


