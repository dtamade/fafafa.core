unit fafafa.core.sync.barrier.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{------------------------------------------------------------------------------
  Windows Barrier implementation notes

  Macros (see src/fafafa.core.settings.inc):
  - FAFAFA_SYNC_USE_WIN_BARRIER (default ON on Windows)
      Use native SynchronizationBarrier APIs. Wait returns TRUE for the leader
      (serial) thread and FALSE for others. Both outcomes are success; we set
      FLastError := weNone for both.
  - FAFAFA_SYNC_WIN_RUNTIME_FALLBACK (default OFF)
      When defined together with FAFAFA_SYNC_USE_WIN_BARRIER, the unit resolves
      the three APIs at runtime via GetProcAddress. If not available, it falls
      back to an internal condvar+generation implementation.

  Build-time combinations:
  - Only FAFAFA_SYNC_USE_WIN_BARRIER defined:
      Always use native; missing APIs cause an exception during construction.
  - Both FAFAFA_SYNC_USE_WIN_BARRIER and FAFAFA_SYNC_WIN_RUNTIME_FALLBACK defined:
      Prefer native; if unavailable at runtime, transparently fallback.
  - Neither defined:
      Always use fallback (condvar+generation).

  Notes:
  - TSynchronizationBarrier is declared with {$packrecords c} and treated as an
    opaque C-layout storage. We never access its fields directly.
  - IConditionVariable and TMutex are only referenced/used in fallback builds
    or when runtime fallback is active.


------------------------------------------------------------------------------}


interface

uses
  Windows, SysUtils,
  fafafa.core.base,
  fafafa.core.sync.base,
  fafafa.core.sync.barrier.base
  {$IFDEF FAFAFA_SYNC_WIN_RUNTIME_FALLBACK}
  , fafafa.core.sync.conditionVariable.base
  {$ENDIF}
  ;

{$push}
{$packrecords c}
type
  TSynchronizationBarrier = record
    Reserved1, Reserved2: LongWord;        // DWORD
    Reserved3: array[0..1] of PtrUInt;     // ULONG_PTR
    Reserved4, Reserved5: LongWord;        // DWORD
  end;
{$pop}

type
  TBarrier = class(TInterfacedObject, IBarrier)
  private
    FParticipantCount: Integer;
    {$IFDEF FAFAFA_SYNC_USE_WIN_BARRIER}
      FBarrier: TSynchronizationBarrier;
      {$IFDEF FAFAFA_SYNC_WIN_RUNTIME_FALLBACK}
        FWaitingCount: Integer;
        FGeneration: Integer;
        FCoordLock: ILock;               // Internal coordination lock
        FCondition: IConditionVariable;  // Internal condition variable
        FUseNative: Boolean;             // runtime switch
      {$ENDIF}
    {$ELSE}
      // Fallback coordination state (condvar + generation):
      FWaitingCount: Integer;
      FGeneration: Integer;
      FCoordLock: ILock;
      FCondition: IConditionVariable;
    {$ENDIF}
    FLastError: TWaitError;
  public
    constructor Create(AParticipantCount: Integer);
    destructor Destroy; override;
    // ISynchronizable
    function GetLastError: TWaitError;
    // IBarrier
    function Wait: Boolean;
    function GetParticipantCount: Integer;
  end;

implementation

{$IFDEF FAFAFA_SYNC_USE_WIN_BARRIER}
type
  TInitSyncBarrier = function(var Barrier; TotalThreads, SpinCount: Longint): BOOL; stdcall;
  TEnterSyncBarrier = function(var Barrier; dwFlags: DWORD): BOOL; stdcall;
  TDeleteSyncBarrier = procedure(var Barrier); stdcall;

var
  _InitializeSynchronizationBarrier: TInitSyncBarrier = nil;
  _EnterSynchronizationBarrier: TEnterSyncBarrier = nil;
  _DeleteSynchronizationBarrier: TDeleteSyncBarrier = nil;

function ResolveWinBarrierAPIs: Boolean;
var h: HMODULE;
begin
  h := GetModuleHandle('kernel32.dll');
  if h = 0 then Exit(False);
  Pointer(_InitializeSynchronizationBarrier) := GetProcAddress(h, 'InitializeSynchronizationBarrier');
  Pointer(_EnterSynchronizationBarrier) := GetProcAddress(h, 'EnterSynchronizationBarrier');
  Pointer(_DeleteSynchronizationBarrier) := GetProcAddress(h, 'DeleteSynchronizationBarrier');
  Result := Assigned(_InitializeSynchronizationBarrier) and Assigned(_EnterSynchronizationBarrier) and Assigned(_DeleteSynchronizationBarrier);
end;
{$ENDIF}

// Implementation dependencies
{$IF (not Defined(FAFAFA_SYNC_USE_WIN_BARRIER)) or Defined(FAFAFA_SYNC_WIN_RUNTIME_FALLBACK)}
uses
  fafafa.core.sync.mutex,
  fafafa.core.sync.conditionVariable;
{$ENDIF}

constructor TBarrier.Create(AParticipantCount: Integer);
begin
  inherited Create;
  if AParticipantCount <= 0 then
    raise EInvalidArgument.Create('Barrier participants must be > 0');
  FParticipantCount := AParticipantCount;
  {$IFDEF FAFAFA_SYNC_USE_WIN_BARRIER}
    {$IFDEF FAFAFA_SYNC_WIN_RUNTIME_FALLBACK}
      FUseNative := False;
      if ResolveWinBarrierAPIs then
      begin
        if _InitializeSynchronizationBarrier(FBarrier, FParticipantCount, FAFAFA_SYNC_WIN_BARRIER_SPIN) then
          FUseNative := True;
      end;
      if not FUseNative then
      begin
        FWaitingCount := 0;
        FGeneration := 0;
        // Internal primitives for coordination
        FCoordLock := TMutex.Create;
        FCondition := TConditionVariable.Create;
      end;
    {$ELSE}
      if not ResolveWinBarrierAPIs then
        raise ELockError.Create('Windows SynchronizationBarrier APIs are not available');
      if not _InitializeSynchronizationBarrier(FBarrier, FParticipantCount, FAFAFA_SYNC_WIN_BARRIER_SPIN) then
        raise ELockError.Create('InitializeSynchronizationBarrier failed');
    {$ENDIF}
  {$ELSE}
    // Pure fallback build (no native barrier compiled in)
    FWaitingCount := 0;
    FGeneration := 0;
    FCoordLock := TMutex.Create;
    FCondition := TConditionVariable.Create;
  {$ENDIF}
  FLastError := weNone;
end;

destructor TBarrier.Destroy;
begin
  {$IFDEF FAFAFA_SYNC_USE_WIN_BARRIER}
    {$IFDEF FAFAFA_SYNC_WIN_RUNTIME_FALLBACK}
      if FUseNative then
        _DeleteSynchronizationBarrier(FBarrier)
      else
      begin
        FCondition := nil;
        FCoordLock := nil;
      end;
    {$ELSE}
      _DeleteSynchronizationBarrier(FBarrier);
    {$ENDIF}
  {$ELSE}
    FCondition := nil;
    FCoordLock := nil;
  {$ENDIF}
  inherited Destroy;
end;

function TBarrier.Wait: Boolean;
var myGen: Integer;
begin
  {$IFDEF FAFAFA_SYNC_USE_WIN_BARRIER}
    {$IFDEF FAFAFA_SYNC_WIN_RUNTIME_FALLBACK}
      if FUseNative then
      begin
        Result := _EnterSynchronizationBarrier(FBarrier, 0);
        FLastError := weNone;
        Exit;
      end;
    {$ELSE}
      Result := _EnterSynchronizationBarrier(FBarrier, 0);
      FLastError := weNone;
      Exit;
    {$ENDIF}
  {$ENDIF}

  // Fallback path (compiled when native disabled or runtime-fallback active and native unavailable)
  FCoordLock.Acquire;
  try
    myGen := FGeneration;
    Inc(FWaitingCount);
    if FWaitingCount = FParticipantCount then
    begin
      Inc(FGeneration);
      FWaitingCount := 0;
      FCondition.Broadcast;
      FLastError := weNone;
      Result := True; // serial thread
      Exit;
    end
    else
    begin
      while (myGen = FGeneration) do
        FCondition.Wait(FCoordLock);
      FLastError := weNone;
      Result := False; // non-serial
      Exit;
    end;
  finally
    FCoordLock.Release;
  end;
end;



function TBarrier.GetParticipantCount: Integer;
begin
  Result := FParticipantCount;
end;

function TBarrier.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

end.

