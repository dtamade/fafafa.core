unit fafafa.core.simd.runtime;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.base,
  fafafa.core.simd.cpuinfo,
  fafafa.core.simd.dispatch;

// Runtime/control-plane view of SIMD backend state.
// CPU capability-only queries stay in fafafa.core.simd.cpuinfo.

type
  TSimdRuntimeSnapshot = record
    CurrentBackend: TSimdBackend;
    CurrentBackendInfo: TSimdBackendInfo;
    RegisteredBackends: TSimdBackendArray;
    DispatchableBackends: TSimdBackendArray;
    BestDispatchableBackend: TSimdBackend;
  end;

// Canonical runtime/control-plane snapshot getter.
function GetCurrentRuntimeSnapshot: TSimdRuntimeSnapshot;

// Compatibility alias kept for older call sites.
function GetCurrentSimdRuntimeSnapshot: TSimdRuntimeSnapshot;

// Returns the currently published backend.
function GetCurrentBackend: TSimdBackend;

// Returns metadata for the currently published backend snapshot.
function GetCurrentBackendInfo: TSimdBackendInfo;

// Returns True when the backend has been registered into this binary.
function IsBackendRegisteredInBinary(aBackend: TSimdBackend): Boolean;

// Enumerates every backend currently registered in this binary.
function GetRegisteredBackendList: TSimdBackendArray;

// Enumerates backends that are both registered and dispatchable now.
function GetDispatchableBackendList: TSimdBackendArray;

// Compatibility alias for dispatchable backends.
function GetAvailableBackendList: TSimdBackendArray;

// Returns the best dispatchable backend in the current runtime state.
function GetBestDispatchableBackend: TSimdBackend;

// Control-plane setter that reports whether the requested backend became active.
function TrySetCurrentBackend(aBackend: TSimdBackend): Boolean;

// Control-plane setter with legacy scalar fallback semantics.
procedure SetCurrentBackend(aBackend: TSimdBackend);

// Returns runtime backend selection to automatic mode.
procedure ResetCurrentBackendSelection;

implementation

uses
  fafafa.core.atomic;

type
  TSimdRuntimePublishedState = record
    Dispatch: PSimdDispatchTable;
    Generation: LongInt;
    PublicationGeneration: LongInt;
    Snapshot: TSimdRuntimeSnapshot;
    RegisteredFlags: array[TSimdBackend] of Boolean;
    Valid: Boolean;
  end;

var
  g_SimdRuntimeState: TSimdRuntimePublishedState;
  g_SimdRuntimeTargetDispatchPtr: Pointer = nil;
  g_SimdRuntimeTargetGeneration: LongInt = 0;
  g_SimdRuntimeRebindLock: TRTLCriticalSection;

procedure InitializeSimdRuntimePublishedState(out aState: TSimdRuntimePublishedState);
begin
  aState := Default(TSimdRuntimePublishedState);
  aState.Dispatch := nil;
  aState.Generation := 0;
  aState.PublicationGeneration := 0;
  aState.Snapshot.CurrentBackend := sbScalar;
  aState.Snapshot.BestDispatchableBackend := sbScalar;
  aState.Valid := False;
end;

procedure ClearSimdRuntimePublishedState(var aState: TSimdRuntimePublishedState);
begin
  aState.Dispatch := nil;
  aState.Generation := 0;
  aState.PublicationGeneration := 0;
  aState.Snapshot.CurrentBackend := sbScalar;
  aState.Snapshot.CurrentBackendInfo := Default(TSimdBackendInfo);
  aState.Snapshot.RegisteredBackends := nil;
  aState.Snapshot.DispatchableBackends := nil;
  aState.Snapshot.BestDispatchableBackend := sbScalar;
  FillChar(aState.RegisteredFlags, SizeOf(aState.RegisteredFlags), 0);
  aState.Valid := False;
end;

procedure BuildDefaultRuntimeSnapshot(out aSnapshot: TSimdRuntimeSnapshot);
begin
  aSnapshot.CurrentBackend := sbScalar;
  aSnapshot.CurrentBackendInfo := GetBackendInfo(sbScalar);
  aSnapshot.RegisteredBackends := nil;
  aSnapshot.DispatchableBackends := nil;
  aSnapshot.BestDispatchableBackend := sbScalar;
end;

function BuildCurrentBackendInfoFromDispatch(aDispatch: PSimdDispatchTable): TSimdBackendInfo;
var
  LCanonicalInfo: TSimdBackendInfo;
  LBackend: TSimdBackend;
begin
  if aDispatch <> nil then
  begin
    Result := aDispatch^.BackendInfo;
    Result.Backend := aDispatch^.Backend;
    if (Result.Name = '') or (Result.Description = '') then
    begin
      LCanonicalInfo := GetBackendInfo(aDispatch^.Backend);
      if Result.Name = '' then
        Result.Name := LCanonicalInfo.Name;
      if Result.Description = '' then
        Result.Description := LCanonicalInfo.Description;
    end;
    Exit;
  end;

  LBackend := GetActiveBackend;
  Result := GetBackendInfo(LBackend);
end;

procedure BuildRegisteredBackendState(var aState: TSimdRuntimePublishedState);
var
  LBackend: TSimdBackend;
  LCount: Integer;
begin
  FillChar(aState.RegisteredFlags, SizeOf(aState.RegisteredFlags), 0);
  SetLength(aState.Snapshot.RegisteredBackends,
    Ord(High(TSimdBackend)) - Ord(Low(TSimdBackend)) + 1);
  LCount := 0;
  for LBackend := Low(TSimdBackend) to High(TSimdBackend) do
    if IsBackendRegistered(LBackend) then
    begin
      aState.RegisteredFlags[LBackend] := True;
      aState.Snapshot.RegisteredBackends[LCount] := LBackend;
      Inc(LCount);
    end;
  SetLength(aState.Snapshot.RegisteredBackends, LCount);
end;

procedure BuildSimdRuntimePublishedState(out aState: TSimdRuntimePublishedState);
var
  LDispatch: PSimdDispatchTable;
begin
  InitializeSimdRuntimePublishedState(aState);
  LDispatch := GetDispatchTable;
  aState.Dispatch := LDispatch;
  if LDispatch <> nil then
    aState.Snapshot.CurrentBackend := LDispatch^.Backend
  else
    aState.Snapshot.CurrentBackend := GetActiveBackend;
  aState.Snapshot.CurrentBackendInfo := BuildCurrentBackendInfoFromDispatch(LDispatch);
  BuildRegisteredBackendState(aState);
  aState.Snapshot.DispatchableBackends := GetDispatchableBackends;
  aState.Snapshot.BestDispatchableBackend := fafafa.core.simd.dispatch.GetBestDispatchableBackend;
  aState.Valid := True;
end;

function GetCurrentSimdRuntimeTargetDispatch: PSimdDispatchTable; inline;
begin
  Result := GetDispatchTable;
end;

function GetCurrentSimdRuntimeTargetGeneration: LongInt; inline;
begin
  Result := atomic_load(g_SimdRuntimeTargetGeneration, mo_acquire);
end;

function GetCurrentSimdRuntimePublicationGeneration: LongInt; inline;
begin
  Result := GetDispatchPublicationGeneration;
end;

function GetCurrentSimdRuntimePublicationWriterCount: LongInt; inline;
begin
  Result := GetDispatchPublicationActiveWriterCount;
end;

function DispatchPublicationStateIsStable(aGeneration: LongInt;
  aWriterCount: LongInt): Boolean; inline;
begin
  Result := (aWriterCount = 0) and ((aGeneration and 1) = 0);
end;

function RuntimeStateMatchesTarget(const aState: TSimdRuntimePublishedState;
  aTargetDispatch: PSimdDispatchTable; aTargetGeneration,
  aTargetPublicationGeneration: LongInt): Boolean; inline;
begin
  Result := aState.Valid and
    (aState.Dispatch = aTargetDispatch) and
    (aState.Generation = aTargetGeneration) and
    (aState.PublicationGeneration = aTargetPublicationGeneration);
end;

procedure InvalidateSimdRuntimeState;
begin
  // Runtime snapshot is control-plane facing and returned by value, so it can
  // use a single cached state instead of process-lifetime published snapshots.
  atomic_store(g_SimdRuntimeTargetDispatchPtr, Pointer(GetDispatchTable), mo_release);
  atomic_fetch_add(g_SimdRuntimeTargetGeneration, 1, mo_acq_rel);
  EnterCriticalSection(g_SimdRuntimeRebindLock);
  try
    g_SimdRuntimeState.Valid := False;
  finally
    LeaveCriticalSection(g_SimdRuntimeRebindLock);
  end;
end;

function GetCurrentRuntimeSnapshot: TSimdRuntimeSnapshot;
var
  LBuiltState: TSimdRuntimePublishedState;
  LTargetDispatch: PSimdDispatchTable;
  LTargetGeneration: LongInt;
  LTargetPublicationGeneration: LongInt;
  LTargetPublicationWriterCount: LongInt;
  LBuildTargetDispatch: PSimdDispatchTable;
  LBuildTargetGeneration: LongInt;
  LBuildTargetPublicationGeneration: LongInt;
  LBuildTargetPublicationWriterCount: LongInt;
  LRetry: Boolean;
begin
  repeat
    EnterCriticalSection(g_SimdRuntimeRebindLock);
    try
      LTargetGeneration := GetCurrentSimdRuntimeTargetGeneration;
      LTargetPublicationGeneration := GetCurrentSimdRuntimePublicationGeneration;
      LTargetPublicationWriterCount := GetCurrentSimdRuntimePublicationWriterCount;
      LTargetDispatch := GetCurrentSimdRuntimeTargetDispatch;
      if DispatchPublicationStateIsStable(LTargetPublicationGeneration,
           LTargetPublicationWriterCount) and
         RuntimeStateMatchesTarget(g_SimdRuntimeState, LTargetDispatch,
           LTargetGeneration,
           LTargetPublicationGeneration) then
      begin
        Result := g_SimdRuntimeState.Snapshot;
        Exit;
      end;
    finally
      LeaveCriticalSection(g_SimdRuntimeRebindLock);
    end;

    LBuildTargetDispatch := LTargetDispatch;
    LBuildTargetGeneration := LTargetGeneration;
    LBuildTargetPublicationGeneration := LTargetPublicationGeneration;
    LBuildTargetPublicationWriterCount := LTargetPublicationWriterCount;
    if not DispatchPublicationStateIsStable(LBuildTargetPublicationGeneration,
         LBuildTargetPublicationWriterCount) then
    begin
      LRetry := True;
      ThreadSwitch;
      Continue;
    end;
    BuildSimdRuntimePublishedState(LBuiltState);

    LRetry := False;
    EnterCriticalSection(g_SimdRuntimeRebindLock);
    try
      LTargetGeneration := GetCurrentSimdRuntimeTargetGeneration;
      LTargetPublicationGeneration := GetCurrentSimdRuntimePublicationGeneration;
      LTargetPublicationWriterCount := GetCurrentSimdRuntimePublicationWriterCount;
      LTargetDispatch := GetCurrentSimdRuntimeTargetDispatch;
      if LBuildTargetDispatch <> LTargetDispatch then
        LRetry := True
      else
      if LBuildTargetGeneration <> LTargetGeneration then
        LRetry := True
      else
      if LBuildTargetPublicationGeneration <> LTargetPublicationGeneration then
        LRetry := True
      else
      if LBuildTargetPublicationWriterCount <> LTargetPublicationWriterCount then
        LRetry := True
      else
      if not DispatchPublicationStateIsStable(LTargetPublicationGeneration,
           LTargetPublicationWriterCount) then
        LRetry := True
      else
      begin
        LBuiltState.Generation := LTargetGeneration;
        LBuiltState.PublicationGeneration := LTargetPublicationGeneration;
        g_SimdRuntimeState := LBuiltState;
        Result := g_SimdRuntimeState.Snapshot;
        Exit;
      end;
    finally
      LeaveCriticalSection(g_SimdRuntimeRebindLock);
    end;
  until not LRetry;

  BuildDefaultRuntimeSnapshot(Result);
end;

function GetCurrentSimdRuntimeSnapshot: TSimdRuntimeSnapshot;
begin
  Result := GetCurrentRuntimeSnapshot;
end;

function GetCurrentBackend: TSimdBackend;
begin
  Result := GetCurrentRuntimeSnapshot.CurrentBackend;
end;

function GetCurrentBackendInfo: TSimdBackendInfo;
begin
  Result := GetCurrentRuntimeSnapshot.CurrentBackendInfo;
end;

function IsBackendRegisteredInBinary(aBackend: TSimdBackend): Boolean;
begin
  EnterCriticalSection(g_SimdRuntimeRebindLock);
  try
    if g_SimdRuntimeState.Valid then
    begin
      Result := g_SimdRuntimeState.RegisteredFlags[aBackend];
      Exit;
    end;
  finally
    LeaveCriticalSection(g_SimdRuntimeRebindLock);
  end;

  GetCurrentRuntimeSnapshot;

  EnterCriticalSection(g_SimdRuntimeRebindLock);
  try
    if g_SimdRuntimeState.Valid then
      Result := g_SimdRuntimeState.RegisteredFlags[aBackend]
    else
      Result := IsBackendRegistered(aBackend);
  finally
    LeaveCriticalSection(g_SimdRuntimeRebindLock);
  end;
end;

function GetRegisteredBackendList: TSimdBackendArray;
begin
  Result := GetCurrentRuntimeSnapshot.RegisteredBackends;
end;

function GetDispatchableBackendList: TSimdBackendArray;
begin
  Result := GetCurrentRuntimeSnapshot.DispatchableBackends;
end;

function GetAvailableBackendList: TSimdBackendArray;
begin
  Result := GetDispatchableBackendList;
end;

function GetBestDispatchableBackend: TSimdBackend;
begin
  Result := GetCurrentRuntimeSnapshot.BestDispatchableBackend;
end;

function TrySetCurrentBackend(aBackend: TSimdBackend): Boolean;
begin
  Result := TrySetActiveBackend(aBackend);
end;

procedure SetCurrentBackend(aBackend: TSimdBackend);
begin
  SetActiveBackend(aBackend);
end;

procedure ResetCurrentBackendSelection;
begin
  ResetToAutomaticBackend;
end;

procedure FinalizeSimdRuntimePublishedState;
begin
  EnterCriticalSection(g_SimdRuntimeRebindLock);
  try
    ClearSimdRuntimePublishedState(g_SimdRuntimeState);
  finally
    LeaveCriticalSection(g_SimdRuntimeRebindLock);
  end;
end;

initialization
  {$IFDEF SIMD_INIT_TRACE}
  WriteLn(StdErr, '[INIT-TRACE] simd.runtime:init:start');
  Flush(StdErr);
  {$ENDIF}
  InitCriticalSection(g_SimdRuntimeRebindLock);
  {$IFDEF SIMD_INIT_TRACE}
  WriteLn(StdErr, '[INIT-TRACE] simd.runtime:init:after-lock');
  Flush(StdErr);
  {$ENDIF}
  InitializeSimdRuntimePublishedState(g_SimdRuntimeState);
  {$IFDEF SIMD_INIT_TRACE}
  WriteLn(StdErr, '[INIT-TRACE] simd.runtime:init:after-published-state');
  Flush(StdErr);
  {$ENDIF}
  atomic_store(g_SimdRuntimeTargetDispatchPtr, nil, mo_release);
  atomic_store(g_SimdRuntimeTargetGeneration, 0, mo_release);
  AddDispatchChangedHook(@InvalidateSimdRuntimeState);
  {$IFDEF SIMD_INIT_TRACE}
  WriteLn(StdErr, '[INIT-TRACE] simd.runtime:init:after-hook');
  Flush(StdErr);
  {$ENDIF}
  GetCurrentRuntimeSnapshot;
  {$IFDEF SIMD_INIT_TRACE}
  WriteLn(StdErr, '[INIT-TRACE] simd.runtime:init:after-snapshot');
  Flush(StdErr);
  {$ENDIF}

finalization
  RemoveDispatchChangedHook(@InvalidateSimdRuntimeState);
  FinalizeSimdRuntimePublishedState;
  atomic_store(g_SimdRuntimeTargetDispatchPtr, nil, mo_release);
  atomic_store(g_SimdRuntimeTargetGeneration, 0, mo_release);
  DoneCriticalSection(g_SimdRuntimeRebindLock);

end.
