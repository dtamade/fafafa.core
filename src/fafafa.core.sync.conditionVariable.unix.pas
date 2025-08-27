unit fafafa.core.sync.conditionVariable.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.mutex.base,
  fafafa.core.sync.conditionVariable.base;

type
  TConditionVariable = class(TInterfacedObject, IConditionVariable)
  private
    FCond: pthread_cond_t;
    FInternalMutex: pthread_mutex_t; // for ILock semantics on the condvar object itself
  public
    constructor Create;
    destructor Destroy; override;
    // ILock
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean;
    // Condvar ops
    procedure Wait(const ALock: ILock); overload;
    function Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean; overload;
    procedure Signal;
    procedure Broadcast;
  end;

implementation

{ TConditionVariable }

constructor TConditionVariable.Create;
var
  Attr: pthread_condattr_t;
begin
  inherited Create;
  // init internal mutex for ILock semantics
  if pthread_mutex_init(@FInternalMutex, nil) <> 0 then
    raise ELockError.Create('Failed to initialize condvar internal mutex');

  if pthread_condattr_init(@Attr) <> 0 then
  begin
    pthread_mutex_destroy(@FInternalMutex);
    raise ELockError.Create('Failed to initialize condvar attributes');
  end;
  {$IFDEF HAS_CLOCK_MONOTONIC}
  // Prefer MONOTONIC if available
  pthread_condattr_setclock(@Attr, CLOCK_MONOTONIC);
  {$ENDIF}
  if pthread_cond_init(@FCond, @Attr) <> 0 then
  begin
    pthread_condattr_destroy(@Attr);
    pthread_mutex_destroy(@FInternalMutex);
    raise ELockError.Create('Failed to initialize condition variable');
  end;
  pthread_condattr_destroy(@Attr);
end;

Destructor TConditionVariable.Destroy;
begin
  pthread_cond_destroy(@FCond);
  pthread_mutex_destroy(@FInternalMutex);
  inherited Destroy;
end;

procedure TConditionVariable.Wait(const ALock: ILock);
var
  M: IMutex;
  PMutex: Ppthread_mutex_t;
  RC: Integer;
begin
  if ALock = nil then
    raise EArgumentNilException.Create('Lock cannot be nil');
  if not Supports(ALock, IMutex, M) then
    raise ENotSupportedException.Create('ConditionVariable.Wait requires IMutex');
  PMutex := Ppthread_mutex_t(M.GetHandle);
  if PMutex = nil then
    raise ELockError.Create('ConditionVariable: mutex handle is nil');
  RC := pthread_cond_wait(@FCond, PMutex);
  if RC <> 0 then
    raise ELockError.Create('pthread_cond_wait failed');
end;

function TConditionVariable.Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean;
var
  M: IMutex;
  PMutex: Ppthread_mutex_t;
  TS: timespec;
  RC: Integer;
  {$IFDEF HAS_CLOCK_MONOTONIC}
  NowTS: timespec;
  {$ELSE}
  TV: TTimeVal;
  {$ENDIF}
begin
  if ALock = nil then
    raise EArgumentNilException.Create('Lock cannot be nil');
  if not Supports(ALock, IMutex, M) then
    Exit(False);
  PMutex := Ppthread_mutex_t(M.GetHandle);
  if PMutex = nil then Exit(False);

  if ATimeoutMs = 0 then
    Exit(False);

  {$IFDEF HAS_CLOCK_MONOTONIC}
  clock_gettime(CLOCK_MONOTONIC, @NowTS);
  TS.tv_sec := NowTS.tv_sec + (ATimeoutMs div 1000);
  TS.tv_nsec := NowTS.tv_nsec + Int64(ATimeoutMs mod 1000) * 1000000;
  if TS.tv_nsec >= 1000000000 then
  begin
    Inc(TS.tv_sec);
    Dec(TS.tv_nsec, 1000000000);
  end;
  {$ELSE}
  if fpgettimeofday(@TV, nil) <> 0 then Exit(False);
  TS.tv_sec := TV.tv_sec + (ATimeoutMs div 1000);
  TS.tv_nsec := (TV.tv_usec * 1000) + Int64(ATimeoutMs mod 1000) * 1000000;
  if TS.tv_nsec >= 1000000000 then
  begin
    Inc(TS.tv_sec);
    Dec(TS.tv_nsec, 1000000000);
  end;
  {$ENDIF}

  RC := pthread_cond_timedwait(@FCond, PMutex, @TS);
  if RC = 0 then Exit(True)
  else if RC = ETIMEDOUT then Exit(False)
  else raise ELockError.Create('pthread_cond_timedwait failed');
end;

procedure TConditionVariable.Signal;
begin
  if pthread_cond_signal(@FCond) <> 0 then
    raise ELockError.Create('Failed to signal condition variable');
end;

procedure TConditionVariable.Broadcast;
begin
  if pthread_cond_broadcast(@FCond) <> 0 then
    raise ELockError.Create('Failed to broadcast condition variable');
end;

// ILock methods for the condition variable object
procedure TConditionVariable.Acquire;
begin
  if pthread_mutex_lock(@FInternalMutex) <> 0 then
    raise ELockError.Create('Failed to acquire condvar internal mutex');
end;

procedure TConditionVariable.Release;
begin
  if pthread_mutex_unlock(@FInternalMutex) <> 0 then
    raise ELockError.Create('Failed to release condvar internal mutex');
end;

function TConditionVariable.TryAcquire: Boolean;
begin
  Result := pthread_mutex_trylock(@FInternalMutex) = 0;
  if Result then
    pthread_mutex_unlock(@FInternalMutex);
end;


end.

