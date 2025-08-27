unit fafafa.core.sync.barrier.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.barrier.base;

type
  TBarrier = class(TInterfacedObject, IBarrier)
  private
    FParticipantCount: Integer;
    FWaitingCount: Integer;
    FGeneration: Integer;
    FMutex: pthread_mutex_t;
    FCond: pthread_cond_t;
    // Separate user-facing lock to satisfy ILock without interfering coordination
    FUserMutex: pthread_mutex_t;
  public
    constructor Create(AParticipantCount: Integer);
    destructor Destroy; override;
    // ILock
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean;
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
  FWaitingCount := 0;
  FGeneration := 0;
  if pthread_mutex_init(@FMutex, nil) <> 0 then
    raise ELockError.Create('barrier: mutex init failed');
  if pthread_cond_init(@FCond, nil) <> 0 then
  begin
    pthread_mutex_destroy(@FMutex);
    raise ELockError.Create('barrier: cond init failed');
  end;
  if pthread_mutex_init(@FUserMutex, nil) <> 0 then
  begin
    pthread_cond_destroy(@FCond);
    pthread_mutex_destroy(@FMutex);
    raise ELockError.Create('barrier: user mutex init failed');
  end;
end;

destructor TBarrier.Destroy;
begin
  pthread_cond_destroy(@FCond);
  pthread_mutex_destroy(@FMutex);
  pthread_mutex_destroy(@FUserMutex);
  inherited Destroy;
end;

function TBarrier.Wait: Boolean;
var
  myGen: Integer;
  rc: Integer;
begin
  // Emulate serial-thread semantics: return True for one thread per phase.
  if pthread_mutex_lock(@FMutex) <> 0 then Exit(False);
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



function TBarrier.GetParticipantCount: Integer;
begin
  Result := FParticipantCount;
end;

// ILock
procedure TBarrier.Acquire;
begin
  if pthread_mutex_lock(@FUserMutex) <> 0 then
    raise ELockError.Create('barrier user lock acquire failed');
end;

procedure TBarrier.Release;
begin
  if pthread_mutex_unlock(@FUserMutex) <> 0 then
    raise ELockError.Create('barrier user lock release failed');
end;

function TBarrier.TryAcquire: Boolean;
begin
  Result := pthread_mutex_trylock(@FUserMutex) = 0;
end;

function TBarrier.GetWaitingCount: Integer;
begin
  Result := FWaitingCount;
end;

end.

