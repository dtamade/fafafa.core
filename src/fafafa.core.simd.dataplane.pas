unit fafafa.core.simd.dataplane;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch;

type
  PSimdDataPlane = ^TSimdDataPlane;
  TSimdDataPlane = record
    NextOwned: PSimdDataPlane;
    Dispatch: PSimdDispatchTable;
    ActiveBackend: TSimdBackend;
    ActiveDispatchable: Boolean;
    VecF32x4AddPtr: Pointer;
    VecI16x32AddPtr: Pointer;
    VecU32x16MulPtr: Pointer;
    VecU64x8AddPtr: Pointer;
    VecU8x64MaxPtr: Pointer;
    MemEqualPtr: Pointer;
    MemFindBytePtr: Pointer;
    MemDiffRangePtr: Pointer;
    SumBytesPtr: Pointer;
    CountBytePtr: Pointer;
    BitsetPopCountPtr: Pointer;
    Utf8ValidatePtr: Pointer;
    AsciiIEqualPtr: Pointer;
    BytesIndexOfPtr: Pointer;
    MemCopyPtr: Pointer;
    MemSetPtr: Pointer;
    ToLowerAsciiPtr: Pointer;
    ToUpperAsciiPtr: Pointer;
    MemReversePtr: Pointer;
    MinMaxBytesPtr: Pointer;
  end;

function GetCurrentSimdDataPlane: PSimdDataPlane; inline;
function GetCurrentSimdDataPlaneDispatch: PSimdDispatchTable; inline;
procedure RebindSimdDataPlane;
procedure SetSimdDataPlaneInvalidateTestDelayMs(aDelayMs: LongInt);

implementation

uses
  SysUtils,
  fafafa.core.atomic,
  fafafa.core.simd.cpuinfo;

var
  g_SimdDataPlanePtr: Pointer = nil;
  g_SimdDataPlaneTargetDispatchPtr: Pointer = nil;
  g_SimdDataPlaneOwnedHead: PSimdDataPlane = nil;
  g_SimdDataPlaneRebindLock: TRTLCriticalSection;
  g_SimdDataPlaneInvalidateTestDelayMs: LongInt = 0;

function FindOwnedSimdDataPlane(aDispatch: PSimdDispatchTable): PSimdDataPlane;
begin
  Result := g_SimdDataPlaneOwnedHead;
  while Result <> nil do
  begin
    if Result^.Dispatch = aDispatch then
      Exit;
    Result := Result^.NextOwned;
  end;
end;

function CreateSimdDataPlane: PSimdDataPlane;
begin
  New(Result);
  FillChar(Result^, SizeOf(Result^), 0);
  Result^.NextOwned := g_SimdDataPlaneOwnedHead;
  g_SimdDataPlaneOwnedHead := Result;
end;

procedure SetSimdDataPlaneInvalidateTestDelayMs(aDelayMs: LongInt);
begin
  if aDelayMs < 0 then
    aDelayMs := 0;
  InterlockedExchange(g_SimdDataPlaneInvalidateTestDelayMs, aDelayMs);
end;

function GetSimdDataPlaneInvalidateTestDelayMs: LongInt; inline;
begin
  Result := InterlockedCompareExchange(g_SimdDataPlaneInvalidateTestDelayMs, 0, 0);
end;

procedure InitializeSimdDataPlaneForDispatch(aDataPlane: PSimdDataPlane;
  aDispatch: PSimdDispatchTable);
begin
  aDataPlane^.Dispatch := aDispatch;
  aDataPlane^.ActiveBackend := aDispatch^.Backend;
  aDataPlane^.ActiveDispatchable := aDispatch^.BackendInfo.Available and
    fafafa.core.simd.cpuinfo.IsBackendSupportedOnCPU(aDispatch^.Backend);

  aDataPlane^.VecF32x4AddPtr := Pointer(aDispatch^.AddF32x4);
  aDataPlane^.VecI16x32AddPtr := Pointer(aDispatch^.AddI16x32);
  aDataPlane^.VecU32x16MulPtr := Pointer(aDispatch^.MulU32x16);
  aDataPlane^.VecU64x8AddPtr := Pointer(aDispatch^.AddU64x8);
  aDataPlane^.VecU8x64MaxPtr := Pointer(aDispatch^.MaxU8x64);

  aDataPlane^.MemEqualPtr := Pointer(aDispatch^.MemEqual);
  aDataPlane^.MemFindBytePtr := Pointer(aDispatch^.MemFindByte);
  aDataPlane^.MemDiffRangePtr := Pointer(aDispatch^.MemDiffRange);
  aDataPlane^.SumBytesPtr := Pointer(aDispatch^.SumBytes);
  aDataPlane^.CountBytePtr := Pointer(aDispatch^.CountByte);
  aDataPlane^.BitsetPopCountPtr := Pointer(aDispatch^.BitsetPopCount);
  aDataPlane^.Utf8ValidatePtr := Pointer(aDispatch^.Utf8Validate);
  aDataPlane^.AsciiIEqualPtr := Pointer(aDispatch^.AsciiIEqual);
  aDataPlane^.BytesIndexOfPtr := Pointer(aDispatch^.BytesIndexOf);
  aDataPlane^.MemCopyPtr := Pointer(aDispatch^.MemCopy);
  aDataPlane^.MemSetPtr := Pointer(aDispatch^.MemSet);
  aDataPlane^.ToLowerAsciiPtr := Pointer(aDispatch^.ToLowerAscii);
  aDataPlane^.ToUpperAsciiPtr := Pointer(aDispatch^.ToUpperAscii);
  aDataPlane^.MemReversePtr := Pointer(aDispatch^.MemReverse);
  aDataPlane^.MinMaxBytesPtr := Pointer(aDispatch^.MinMaxBytes);
end;

function GetCurrentSimdDataPlane: PSimdDataPlane; inline;
var
  LCurrent: PSimdDataPlane;
  LTargetDispatch: PSimdDispatchTable;
begin
  LCurrent := PSimdDataPlane(atomic_load(g_SimdDataPlanePtr, mo_acquire));
  LTargetDispatch := GetDispatchTable;
  if (LCurrent = nil) or
     ((LTargetDispatch <> nil) and (LCurrent^.Dispatch <> LTargetDispatch)) then
  begin
    RebindSimdDataPlane;
    Result := PSimdDataPlane(atomic_load(g_SimdDataPlanePtr, mo_acquire));
    if (Result = nil) and (LCurrent <> nil) then
      Result := LCurrent;
    Exit;
  end;
  Result := LCurrent;
end;

function GetCurrentSimdDataPlaneDispatch: PSimdDispatchTable; inline;
var
  LDataPlane: PSimdDataPlane;
begin
  LDataPlane := GetCurrentSimdDataPlane;
  if LDataPlane <> nil then
    Result := LDataPlane^.Dispatch
  else
    Result := nil;
end;

procedure RebindSimdDataPlane;
var
  LDispatch: PSimdDispatchTable;
  LCurrent: PSimdDataPlane;
  LDataPlane: PSimdDataPlane;
begin
  EnterCriticalSection(g_SimdDataPlaneRebindLock);
  try
    LDispatch := GetDispatchTable;
    if LDispatch = nil then
      Exit;

    LCurrent := PSimdDataPlane(atomic_load(g_SimdDataPlanePtr, mo_acquire));
    if (LCurrent <> nil) and (LCurrent^.Dispatch = LDispatch) then
    begin
      atomic_store(g_SimdDataPlaneTargetDispatchPtr, Pointer(LDispatch), mo_release);
      Exit;
    end;

    LDataPlane := FindOwnedSimdDataPlane(LDispatch);
    if LDataPlane = nil then
    begin
      LDataPlane := CreateSimdDataPlane;
      InitializeSimdDataPlaneForDispatch(LDataPlane, LDispatch);
    end;

    atomic_store(g_SimdDataPlanePtr, Pointer(LDataPlane), mo_release);
    atomic_store(g_SimdDataPlaneTargetDispatchPtr, Pointer(LDispatch), mo_release);
  finally
    LeaveCriticalSection(g_SimdDataPlaneRebindLock);
  end;
end;

procedure InvalidateSimdDataPlane;
var
  LDelayMs: LongInt;
begin
  LDelayMs := GetSimdDataPlaneInvalidateTestDelayMs;
  if LDelayMs > 0 then
    Sleep(LDelayMs);

  // Keep the last published data-plane snapshot alive until readers observe
  // that dispatch published a different snapshot pointer, then refresh once.
  atomic_store(g_SimdDataPlaneTargetDispatchPtr, Pointer(GetDispatchTable), mo_release);
end;

procedure FinalizeSimdDataPlane;
var
  LDataPlane: PSimdDataPlane;
  LNext: PSimdDataPlane;
begin
  EnterCriticalSection(g_SimdDataPlaneRebindLock);
  try
    atomic_store(g_SimdDataPlanePtr, nil, mo_release);
    atomic_store(g_SimdDataPlaneTargetDispatchPtr, nil, mo_release);
    LDataPlane := g_SimdDataPlaneOwnedHead;
    g_SimdDataPlaneOwnedHead := nil;
  finally
    LeaveCriticalSection(g_SimdDataPlaneRebindLock);
  end;

  while LDataPlane <> nil do
  begin
    LNext := LDataPlane^.NextOwned;
    Dispose(LDataPlane);
    LDataPlane := LNext;
  end;
end;

initialization
  {$IFDEF SIMD_INIT_TRACE}
  WriteLn(StdErr, '[INIT-TRACE] simd.dataplane:init:start');
  Flush(StdErr);
  {$ENDIF}
  g_SimdDataPlaneRebindLock := Default(TRTLCriticalSection);
  InitCriticalSection(g_SimdDataPlaneRebindLock);
  {$IFDEF SIMD_INIT_TRACE}
  WriteLn(StdErr, '[INIT-TRACE] simd.dataplane:init:after-lock');
  Flush(StdErr);
  {$ENDIF}
  AddDispatchChangedHook(@InvalidateSimdDataPlane);
  {$IFDEF SIMD_INIT_TRACE}
  WriteLn(StdErr, '[INIT-TRACE] simd.dataplane:init:after-hook');
  Flush(StdErr);
  {$ENDIF}
  RebindSimdDataPlane;
  {$IFDEF SIMD_INIT_TRACE}
  WriteLn(StdErr, '[INIT-TRACE] simd.dataplane:init:after-rebind');
  Flush(StdErr);
  {$ENDIF}

finalization
  RemoveDispatchChangedHook(@InvalidateSimdDataPlane);
  FinalizeSimdDataPlane;
  InterlockedExchange(g_SimdDataPlaneInvalidateTestDelayMs, 0);
  DoneCriticalSection(g_SimdDataPlaneRebindLock);

end.
