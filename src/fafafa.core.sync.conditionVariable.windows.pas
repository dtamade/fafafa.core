unit fafafa.core.sync.conditionVariable.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows, SysUtils,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.mutex.base,
  fafafa.core.sync.semaphore.base, fafafa.core.sync.conditionVariable.base;

type
  TConditionVariable = class(TInterfacedObject, IConditionVariable)
  private
    {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
    FCond: CONDITION_VARIABLE;
    {$ELSE}
    FWaitSemaphore: ISemaphore;
    FWaitingCount: Integer;
    FPendingCount: Integer; // 记录未被消费的 Signal，避免丢唤醒
    FLock: ILock;
    FSignalEvent: IEvent;
    FStateCS: TRTLCriticalSection; // 保护 FWaitingCount/FPendingCount 状态
    {$ENDIF}
    FInternalCS: TRTLCriticalSection; // for ILock semantics on the condvar object itself
    FLastError: TWaitError;
  public
    constructor Create;
    destructor Destroy; override;
    // ILock
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean; overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    // ISynchronizable
    function GetLastError: TWaitError;
    // Condvar ops
    procedure Wait(const ALock: ILock); overload;
    function Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean; overload;
    procedure Wait(const AMutex: IMutex); overload;
    function Wait(const AMutex: IMutex; ATimeoutMs: Cardinal): Boolean; overload;
    procedure Signal;
    procedure Broadcast;
  end;

implementation

{ TConditionVariable }

constructor TConditionVariable.Create;
begin
  inherited Create;
  InitializeCriticalSection(FInternalCS);
  FLastError := weNone;
  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  InitializeConditionVariable(FCond);
  {$ELSE}
  // 兼容路径：使用信号量/事件与内部自旋锁组合
  FWaitSemaphore := nil; // 延迟创建
  FWaitingCount := 0;
  FPendingCount := 0;
  FLock := nil;
  FSignalEvent := nil;
  InitializeCriticalSection(FStateCS);
  {$ENDIF}
end;

destructor TConditionVariable.Destroy;
begin
  {$IFNDEF FAFAFA_SYNC_USE_CONDVAR}
  FWaitSemaphore := nil;
  FLock := nil;
  FSignalEvent := nil;
  DeleteCriticalSection(FStateCS);
  {$ENDIF}
  DeleteCriticalSection(FInternalCS);
  inherited Destroy;
end;

procedure TConditionVariable.Wait(const ALock: ILock);
var
  M: IMutex;
  PS: PSRWLOCK;
{$IFNDEF FAFAFA_SYNC_USE_CONDVAR}
  ok: Boolean;
{$ENDIF}
begin
  if ALock = nil then
    raise EArgumentNilException.Create('Lock cannot be nil');

  if not Supports(ALock, IMutex, M) then
    raise ENotSupportedException.Create('Windows ConditionVariable requires IMutex');

  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  // 与 SRWLOCK（IMutex）配合
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
  // 兼容路径：带待处理信号计数，避免丢唤醒
  EnterCriticalSection(FStateCS);
  try
    if FPendingCount > 0 then
    begin
      Dec(FPendingCount);
      FLastError := weNone;
      Exit;
    end;
    InterlockedIncrement(FWaitingCount);
  finally
    LeaveCriticalSection(FStateCS);
  end;

  ALock.Release;
  try
    if FWaitSemaphore = nil then FWaitSemaphore := CreateSemaphore(0, MaxInt);
    FWaitSemaphore.Acquire;
  finally
    ALock.Acquire;
    InterlockedDecrement(FWaitingCount);
  end;
  {$ENDIF}
end;

procedure TConditionVariable.Wait(const AMutex: IMutex);
begin
  if AMutex = nil then
    raise EArgumentNilException.Create('Mutex cannot be nil');
  Wait(ILock(AMutex));
end;

function TConditionVariable.Wait(const AMutex: IMutex; ATimeoutMs: Cardinal): Boolean;
begin
  if AMutex = nil then
    raise EArgumentNilException.Create('Mutex cannot be nil');
  Result := Wait(ILock(AMutex), ATimeoutMs);
end;

function TConditionVariable.Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean;
var
  M: IMutex;
  PS: PSRWLOCK;
  ok: BOOL;
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
  // 兼容路径：带待处理信号计数，避免丢唤醒
  EnterCriticalSection(FStateCS);
  try
    if FPendingCount > 0 then
    begin
      Dec(FPendingCount);
      FLastError := weNone;
      Exit(True);
    end;
    InterlockedIncrement(FWaitingCount);
  finally
    LeaveCriticalSection(FStateCS);
  end;

  ALock.Release;
  try
    if FWaitSemaphore = nil then FWaitSemaphore := CreateSemaphore(0, MaxInt);
    if ATimeoutMs = INFINITE then
      FWaitSemaphore.Acquire
    else
      Result := FWaitSemaphore.TryAcquire(ATimeoutMs);
  finally
    ALock.Acquire;
    InterlockedDecrement(FWaitingCount);
  end;
  {$ENDIF}
end;

// ILock methods for the condition variable object
procedure TConditionVariable.Acquire;
begin
  EnterCriticalSection(FInternalCS);
end;

procedure TConditionVariable.Release;
begin
  LeaveCriticalSection(FInternalCS);
end;

function TConditionVariable.TryAcquire: Boolean;
begin
  Result := TryEnterCriticalSection(FInternalCS);
  if Result then FLastError := weNone;
end;

function TConditionVariable.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var startTick: QWord;
begin
  if ATimeoutMs = 0 then Exit(TryAcquire);
  startTick := GetTickCount64;
  repeat
    if TryAcquire then Exit(True);
    if GetTickCount64 - startTick >= ATimeoutMs then Exit(False);
    Sleep(0);
  until False;
end;

function TConditionVariable.GetLastError: TWaitError;
begin
  Result := FLastError;
end;



procedure TConditionVariable.Signal;
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
      Inc(FPendingCount); // 无 waiter，记录一次待处理信号
  finally
    LeaveCriticalSection(FStateCS);
  end;
  {$ENDIF}
end;

procedure TConditionVariable.Broadcast;
begin
  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  WakeAllConditionVariable(@FCond);
  {$ELSE}
  EnterCriticalSection(FStateCS);
  try
    if (FWaitSemaphore <> nil) and (FWaitingCount > 0) then
      FWaitSemaphore.Release(FWaitingCount)
    else
      Inc(FPendingCount, FWaitingCount); // 若无 waiter，记录待处理次数（此处=0，保持一致接口）
  finally
    LeaveCriticalSection(FStateCS);
  end;
  {$ENDIF}
end;

end.

