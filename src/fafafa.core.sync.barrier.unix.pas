unit fafafa.core.sync.barrier.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.barrier.base;

type

  TBarrier = class(TSynchronizable, IBarrier)
  private
    FParticipantCount: Integer;
    {$IFDEF FAFAFA_SYNC_USE_POSIX_BARRIER}
    FBarrier: pthread_barrier_t;
    {$ELSE}
    FWaitingCount: Integer;
    FGeneration: Integer;
    FMutex: pthread_mutex_t;
    FCond: pthread_cond_t;
    {$ENDIF}
  public
    constructor Create(AParticipantCount: Integer);
    destructor Destroy; override;

    // IBarrier
    function Wait: Boolean;
    function GetParticipantCount: Integer;
  end;

implementation

constructor TBarrier.Create(AParticipantCount: Integer);
begin
  inherited Create;
  if AParticipantCount <= 0 then
    raise EInvalidArgument.Create('Barrier participants must be > 0');
  FParticipantCount := AParticipantCount;
  {$IFDEF FAFAFA_SYNC_USE_POSIX_BARRIER}
  if pthread_barrier_init(@FBarrier, nil, FParticipantCount) <> 0 then
    raise ELockError.Create('barrier: pthread_barrier_init failed');
  {$ELSE}
  FWaitingCount := 0;
  FGeneration := 0;
  if pthread_mutex_init(@FMutex, nil) <> 0 then
    raise ELockError.Create('barrier: mutex init failed');
  if pthread_cond_init(@FCond, nil) <> 0 then
  begin
    pthread_mutex_destroy(@FMutex);
    raise ELockError.Create('barrier: cond init failed');
  end;
  {$ENDIF}
end;

destructor TBarrier.Destroy;
begin
  {$IFDEF FAFAFA_SYNC_USE_POSIX_BARRIER}
  pthread_barrier_destroy(@FBarrier);
  {$ELSE}
  pthread_cond_destroy(@FCond);
  pthread_mutex_destroy(@FMutex);
  {$ENDIF}
  inherited Destroy;
end;

function TBarrier.Wait: Boolean;
{$IFDEF FAFAFA_SYNC_USE_POSIX_BARRIER}
var rc: Integer;
begin
  rc := pthread_barrier_wait(@FBarrier);
  case rc of
    0: Result := False; // non-serial
    PTHREAD_BARRIER_SERIAL_THREAD: Result := True; // serial
  else
    Result := False;
  end;
end;
{$ELSE}
var
  myGen: Integer;
  rc: Integer;
begin
  // Emulate serial-thread semantics: return True for one thread per phase.
  if pthread_mutex_lock(@FMutex) <> 0 then
  begin
    Exit(False);
  end;
  try
    myGen := FGeneration;
    Inc(FWaitingCount);
    if FWaitingCount = FParticipantCount then
    begin
      Inc(FGeneration);
      FWaitingCount := 0;
      // Wake all waiters and designate current as serial thread
      rc := pthread_cond_broadcast(@FCond);
      Result := True;
      Exit;
    end
    else
    begin
      while (myGen = FGeneration) do
        pthread_cond_wait(@FCond, @FMutex);
      Result := False; // non-serial
      Exit;
    end;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;
{$ENDIF}



function TBarrier.GetParticipantCount: Integer;
begin
  Result := FParticipantCount;
end;



end.

