unit fafafa.core.sync.condvar.windows;

{$I fafafa.core.settings.inc}
{$UNDEF FAFAFA_SYNC_USE_CONDVAR}  // Fallback to portable implementation when WinAPI condvar types are unavailable

interface

uses
  Windows, SysUtils,
  fafafa.core.base,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex.base,
  fafafa.core.sync.sem.base,
  fafafa.core.sync.sem,
  fafafa.core.sync.event.base,
  fafafa.core.sync.event,
  fafafa.core.sync.mutex,
  fafafa.core.atomic,
  fafafa.core.sync.condvar.base;

type
  TCondVar = class(TSynchronizable, ICondVar)
  private
    {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
    FCond: CONDITION_VARIABLE;
    {$ELSE}
    FWaitSemaphore: ISem;
    FWaitingCount: Integer;
    FPendingCount: Integer; // 记录未被消费�?Signal，避免丢唤醒
    FLock: ILock;
    FSignalEvent: IEvent;
    FStateCS: TRTLCriticalSection; // 保护 FWaitingCount/FPendingCount 状�?
    {$ENDIF}
    FLastError: TWaitError;
  public
    constructor Create;
    destructor Destroy; override;
    // ISynchronizable
    function GetLastError: TWaitError;
    // ILock（委托给内部互斥�?
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean; overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    function LockGuard: ILockGuard;
    // ICondVar
    procedure Wait(const ALock: ILock); overload;
    function Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean; overload;
    procedure Signal;
    procedure Broadcast;
  end;

implementation

{ TCondVar }

constructor TCondVar.Create;
begin
  inherited Create;
  FLastError := weNone;
  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  InitializeConditionVariable(FCond);
  {$ELSE}
  // 兼容路径：使用信号量/事件与内部自旋锁组合
  FWaitSemaphore := nil; // 延迟创建
  FWaitingCount := 0;
  FPendingCount := 0;
  FLock := MakeMutex;
  FSignalEvent := nil;
  InitializeCriticalSection(FStateCS);
  {$ENDIF}
end;

destructor TCondVar.Destroy;
begin
  {$IFNDEF FAFAFA_SYNC_USE_CONDVAR}
  FWaitSemaphore := nil;
  FLock := nil;
  FSignalEvent := nil;
  DeleteCriticalSection(FStateCS);
  {$ENDIF}
  inherited Destroy;
end;

procedure TCondVar.Wait(const ALock: ILock);
var
  M: IMutex;
  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  PS: PSRWLOCK;
  {$ENDIF}
  {$IFNDEF FAFAFA_SYNC_USE_CONDVAR}
  ok: Boolean;
  {$ENDIF}
begin
  if ALock = nil then
    raise EArgumentNilException.Create('Lock cannot be nil');

  if not Supports(ALock, IMutex, M) then
    raise ENotSupportedException.Create('Windows CondVar requires IMutex');

  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  // �?SRWLOCK（IMutex）配�?
  PS := PSRWLOCK(M.GetHandle);
  if PS = nil then raise ENotSupportedException.Create('CondVar requires IMutex/SRWLOCK');
  if not SleepConditionVariableSRW(@FCond, PS, INFINITE, 0) then
  begin
    case GetLastError of
      ERROR_INVALID_HANDLE: FLastError := weInvalidHandle;
      ERROR_ACCESS_DENIED:  FLastError := weAccessDenied;
    else FLastError := weSystemError;
    end;
    raise ELockError.Create('SleepConditionVariableSRW failed');
  end
  else
    FLastError := weNone;
  {$ELSE}
  // 兼容路径：带待处理信号计数，避免丢唤�?
  EnterCriticalSection(FStateCS);
  try
    if FPendingCount > 0 then
    begin
      Dec(FPendingCount);
      FLastError := weNone;
      Exit;
    end;
    atomic_increment(FWaitingCount);
  finally
    LeaveCriticalSection(FStateCS);
  end;

  ALock.Release;
  try
    if FWaitSemaphore = nil then FWaitSemaphore := MakeSem(0, MaxInt);
    FWaitSemaphore.Acquire;
  finally
    ALock.Acquire;
    atomic_decrement(FWaitingCount);
  end;
  {$ENDIF}
end;



function TCondVar.Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean;
var
  M: IMutex;
  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  PS: PSRWLOCK;
  ok: BOOL;
  {$ENDIF}
begin
  if ALock = nil then
    raise EArgumentNilException.Create('Lock cannot be nil');

  if not Supports(ALock, IMutex, M) then
    Exit(False);

  if ATimeoutMs = 0 then Exit(False);

  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  PS := PSRWLOCK(M.GetHandle);
  if PS = nil then Exit(False);
  ok := SleepConditionVariableSRW(@FCond, PS, ATimeoutMs, 0);
  if not ok then
  begin
    case GetLastError of
      ERROR_TIMEOUT:
      begin
        FLastError := weTimeout;
        Exit(False);
      end;
      ERROR_INVALID_HANDLE: FLastError := weInvalidHandle;
      ERROR_ACCESS_DENIED:  FLastError := weAccessDenied;
    else FLastError := weSystemError;
    end;
    raise ELockError.Create('SleepConditionVariableSRW timed wait failed');
  end
  else
  begin
    FLastError := weNone;
    Exit(True);
  end;
  {$ELSE}
  // 兼容路径：带待处理信号计数，避免丢唤�?
  EnterCriticalSection(FStateCS);
  try
    if FPendingCount > 0 then
    begin
      Dec(FPendingCount);
      FLastError := weNone;
      Exit(True);
    end;
    atomic_increment(FWaitingCount);
  finally
    LeaveCriticalSection(FStateCS);
  end;

  ALock.Release;
  try
    if FWaitSemaphore = nil then FWaitSemaphore := MakeSem(0, MaxInt);
    if ATimeoutMs = INFINITE then
      FWaitSemaphore.Acquire
    else
      Result := FWaitSemaphore.TryAcquire(ATimeoutMs);
  finally
    ALock.Acquire;
    atomic_decrement(FWaitingCount);
  end;
  {$ENDIF}
end;



function TCondVar.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

// ILock 委托实现
procedure TCondVar.Acquire;
begin
  if Assigned(FLock) then FLock.Acquire;
end;

procedure TCondVar.Release;
begin
  if Assigned(FLock) then FLock.Release;
end;

function TCondVar.TryAcquire: Boolean;
var
  TL: ITryLock;
begin
  if Assigned(FLock) then
  begin
    if Supports(FLock, ITryLock, TL) then
      Exit(TL.TryAcquire);
  end;
  Result := False;
end;

function TCondVar.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  TL: ITryLock;
begin
  if Assigned(FLock) then
  begin
    if Supports(FLock, ITryLock, TL) then
      Exit(TL.TryAcquire(ATimeoutMs));
  end;
  Result := False;
end;

function TCondVar.LockGuard: ILockGuard;
begin
  if Assigned(FLock) then Exit(FLock.LockGuard);
  Result := nil;
end;



procedure TCondVar.Signal;
begin
  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  WakeConditionVariable(@FCond);
  {$ELSE}
  EnterCriticalSection(FStateCS);
  try
    if FWaitingCount > 0 then
    begin
      if FWaitSemaphore <> nil then FWaitSemaphore.Release;
    end
    else
      Inc(FPendingCount); // �?waiter，记录一次待处理信号
  finally
    LeaveCriticalSection(FStateCS);
  end;
  {$ENDIF}
end;

procedure TCondVar.Broadcast;
begin
  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  WakeAllConditionVariable(@FCond);
  {$ELSE}
  EnterCriticalSection(FStateCS);
  try
    if (FWaitSemaphore <> nil) and (FWaitingCount > 0) then
      FWaitSemaphore.Release(FWaitingCount)
    else
      Inc(FPendingCount, FWaitingCount); // 若无 waiter，记录待处理次数（此�?0，保持一致接口）
  finally
    LeaveCriticalSection(FStateCS);
  end;
  {$ENDIF}
end;

end.

