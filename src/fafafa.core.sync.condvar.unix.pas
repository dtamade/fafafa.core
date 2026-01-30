unit fafafa.core.sync.condvar.unix;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.sync.base, fafafa.core.sync.mutex.base,
  fafafa.core.sync.condvar.base, fafafa.core.sync.timespec;

type
  TCondVar = class(TSynchronizable, ICondVar)
  private
    FCond: pthread_cond_t;
    FLastError: TWaitError;
  public
    constructor Create;
    destructor Destroy; override;
    // ISynchronizable
    function GetLastError: TWaitError;
    // ICondVar
    procedure Wait(const ALock: ILock); overload;
    function Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean; overload;
    function WaitFor(const ALock: ILock; ATimeoutMs: Cardinal): TCondVarWaitResult;
    procedure Signal;
    procedure Broadcast;
  end;

implementation

function MapErrToWaitError(rc: LongInt): TWaitError;
begin
  case rc of
    ESysEDEADLK: Result := weDeadlock;
    ESysEINVAL:  Result := weInvalidHandle;
    ESysEAGAIN:  Result := weResourceExhausted;
    ESysEPERM:   Result := weAccessDenied;
  else
    Result := weSystemError;
  end;
end;


{ TCondVar }

constructor TCondVar.Create;
var
  Attr: pthread_condattr_t;
begin
  inherited Create;
  FLastError := weNone;

  if pthread_condattr_init(@Attr) <> 0 then
  begin
    FLastError := weSystemError;
    raise ELockError.Create('Failed to initialize condvar attributes');
  end;

  {$IFDEF HAS_CLOCK_MONOTONIC}
  // Prefer MONOTONIC if available
  pthread_condattr_setclock(@Attr, CLOCK_MONOTONIC);
  {$ENDIF}

  if pthread_cond_init(@FCond, @Attr) <> 0 then
  begin
    pthread_condattr_destroy(@Attr);
    FLastError := weSystemError;
    raise ELockError.Create('Failed to initialize condition variable');
  end;

  pthread_condattr_destroy(@Attr);
end;

destructor TCondVar.Destroy;
begin
  pthread_cond_destroy(@FCond);
  inherited Destroy;
end;

procedure TCondVar.Wait(const ALock: ILock);
var
  M: IMutex;
  PMutex: Ppthread_mutex_t;
  RC: Integer;
begin
  if ALock = nil then
    raise EArgumentNilException.Create('Lock cannot be nil');
  try
    if not Supports(ALock, IMutex, M) then
      raise ENotSupportedException.Create('Not supported: CondVar.Wait requires IMutex');
    PMutex := Ppthread_mutex_t(M.GetHandle);
  except
    on E: EAccessViolation do
      raise ENotSupportedException.Create('Not supported: CondVar.Wait requires IMutex');
  end;
  if PMutex = nil then
    raise ELockError.Create('CondVar: mutex handle is nil');
  RC := pthread_cond_wait(@FCond, PMutex);
  if RC <> 0 then
  begin
    FLastError := MapErrToWaitError(RC);
    raise ELockError.Create('pthread_cond_wait failed');
  end
  else
    FLastError := weNone;
end;



function TCondVar.Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean;
var
  M: IMutex;
  PMutex: Ppthread_mutex_t;
  TS: timespec;
  RC: Integer;
begin
  if ALock = nil then
    raise EArgumentNilException.Create('Lock cannot be nil');
  if not Supports(ALock, IMutex, M) then
    raise ENotSupportedException.Create('Not supported: CondVar.Wait requires IMutex');

  PMutex := Ppthread_mutex_t(M.GetHandle);
  if PMutex = nil then
  begin
    FLastError := weInvalidHandle;
    Exit(False);
  end;

  if ATimeoutMs = 0 then
    Exit(False);

  // 使用 timespec.pas 共享函数计算超时
  // 注意: 必须与 pthread_condattr_setclock 设置的时钟一致
  {$IFDEF HAS_CLOCK_MONOTONIC}
  TS := TimeoutToMonotonicTimespec(ATimeoutMs);
  {$ELSE}
  TS := TimeoutToTimespec(ATimeoutMs);
  {$ENDIF}

  RC := pthread_cond_timedwait(@FCond, PMutex, @TS);
  if RC = 0 then
  begin
    FLastError := weNone;
    Exit(True)
  end
  else if RC = ESysETIMEDOUT then
  begin
    FLastError := weTimeout;
    Exit(False)
  end
  else
  begin
    FLastError := MapErrToWaitError(RC);
    raise ELockError.Create('pthread_cond_timedwait failed');
  end;

end;

function TCondVar.WaitFor(const ALock: ILock; ATimeoutMs: Cardinal): TCondVarWaitResult;
begin
  // Delegate to existing Wait implementation
  if Wait(ALock, ATimeoutMs) then
    Result := TCondVarWaitResult.Signaled
  else
    Result := TCondVarWaitResult.Timeout;
end;

procedure TCondVar.Signal;
begin
  if pthread_cond_signal(@FCond) <> 0 then
  begin
    FLastError := weSystemError;
    raise ELockError.Create('Failed to signal condition variable');
  end
  else
    FLastError := weNone;
end;

procedure TCondVar.Broadcast;
begin
  if pthread_cond_broadcast(@FCond) <> 0 then
  begin
    FLastError := weSystemError;
    raise ELockError.Create('Failed to broadcast condition variable');
  end
  else
    FLastError := weNone;
end;



function TCondVar.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

end.

