unit fafafa.core.sync.barrier.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows, SysUtils,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.barrier.base, fafafa.core.sync.mutex.base,
  fafafa.core.sync.mutex, fafafa.core.sync.spin.base; // for ILock, IConditionVariable via sync.base

type
  TBarrier = class(TInterfacedObject, IBarrier)
  private
    FParticipantCount: Integer;
    {$IFDEF FAFAFA_SYNC_USE_WIN_BARRIER}
    FBarrier: record
      Reserved1, Reserved2: Longint;
      Reserved3: array[0..1] of Pointer;
      Reserved4, Reserved5: Longint;
    end;
    {$ELSE}
    FWaitingCount: Integer;
    FGeneration: Integer;
    FCoordLock: ILock;               // Internal coordination lock
    FCondition: IConditionVariable;  // Internal condition variable
    {$ENDIF}
    FUserLock: ILock;                // ILock interface for users (separate from coordination)
  public
    constructor Create(AParticipantCount: Integer);
    destructor Destroy; override;
    // ILock (forwarded to FUserLock)
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean;
    // IBarrier
    function Wait: Boolean;
    function GetParticipantCount: Integer;
  end;

implementation

{$IFDEF FAFAFA_SYNC_USE_WIN_BARRIER}
// Win32 barrier API declarations (Kernel32)
function InitializeSynchronizationBarrier(var Barrier; TotalThreads, SpinCount: Longint): BOOL; stdcall; external 'kernel32' name 'InitializeSynchronizationBarrier';
function EnterSynchronizationBarrier(var Barrier; dwFlags: DWORD): BOOL; stdcall; external 'kernel32' name 'EnterSynchronizationBarrier';
procedure DeleteSynchronizationBarrier(var Barrier); stdcall; external 'kernel32' name 'DeleteSynchronizationBarrier';
{$ENDIF}

uses
  fafafa.core.sync; // brings TMutex and TConditionVariable from the facade

constructor TBarrier.Create(AParticipantCount: Integer);
begin
  inherited Create;
  if AParticipantCount <= 0 then
    raise EInvalidArgument.Create('Barrier participants must be > 0');
  FParticipantCount := AParticipantCount;
  {$IFDEF FAFAFA_SYNC_USE_WIN_BARRIER}
  if not InitializeSynchronizationBarrier(FBarrier, FParticipantCount, 0) then
    raise ELockError.Create('InitializeSynchronizationBarrier failed');
  {$ELSE}
  FWaitingCount := 0;
  FGeneration := 0;
  // Internal primitives for coordination
  FCoordLock := TMutex.Create;
  FCondition := TConditionVariable.Create;
  {$ENDIF}
  // Separate user-facing lock to satisfy ILock contract without interfering with Wait
  FUserLock := TMutex.Create;
end;

destructor TBarrier.Destroy;
begin
  {$IFDEF FAFAFA_SYNC_USE_WIN_BARRIER}
  DeleteSynchronizationBarrier(FBarrier);
  {$ELSE}
  FCondition := nil;
  FCoordLock := nil;
  {$ENDIF}
  FUserLock := nil;
  inherited Destroy;
end;

function TBarrier.Wait: Boolean;
{$IFNDEF FAFAFA_SYNC_USE_WIN_BARRIER}var myGen: Integer;{$ENDIF}
begin
  {$IFDEF FAFAFA_SYNC_USE_WIN_BARRIER}
  Result := EnterSynchronizationBarrier(FBarrier, 0);
  {$ELSE}
  FCoordLock.Acquire;
  try
    myGen := FGeneration;
    Inc(FWaitingCount);
    if FWaitingCount = FParticipantCount then
    begin
      Inc(FGeneration);
      FWaitingCount := 0;
      FCondition.Broadcast;
      Result := True; // serial thread
      Exit;
    end
    else
    begin
      while (myGen = FGeneration) do
        FCondition.Wait(FCoordLock);
      Result := False; // non-serial
      Exit;
    end;
  finally
    FCoordLock.Release;
  end;
  {$ENDIF}
end;



function TBarrier.GetParticipantCount: Integer;
begin
  Result := FParticipantCount;
end;

// ILock forwarding
procedure TBarrier.Acquire;
begin
  FUserLock.Acquire;
end;

procedure TBarrier.Release;
begin
  FUserLock.Release;
end;

function TBarrier.TryAcquire: Boolean;
begin
  Result := FUserLock.TryAcquire;
end;

end.

