{$IFDEF WINDOWS}

{$IFDEF FAFAFA_SYNC_USE_CONDVAR}
procedure InitializeConditionVariable(out Cond: CONDITION_VARIABLE); stdcall; external 'kernel32' name 'InitializeConditionVariable';
function SleepConditionVariableCS(Cond: PCONDITION_VARIABLE; CriticalSection: Pointer; dwMilliseconds: DWORD): BOOL; stdcall; external 'kernel32' name 'SleepConditionVariableCS';
function SleepConditionVariableSRW(Cond: PCONDITION_VARIABLE; SRWLock: Pointer; dwMilliseconds: DWORD; Flags: ULONG): BOOL; stdcall; external 'kernel32' name 'SleepConditionVariableSRW';
procedure WakeConditionVariable(Cond: PCONDITION_VARIABLE); stdcall; external 'kernel32' name 'WakeConditionVariable';
procedure WakeAllConditionVariable(Cond: PCONDITION_VARIABLE); stdcall; external 'kernel32' name 'WakeAllConditionVariable';
{$ENDIF}

{$IFDEF FAFAFA_SYNC_USE_SRWLOCK}
procedure InitializeSRWLock(out SRWLock: SRWLOCK); stdcall; external 'kernel32' name 'InitializeSRWLock';
procedure AcquireSRWLockExclusive(var SRWLock: SRWLOCK); stdcall; external 'kernel32' name 'AcquireSRWLockExclusive';
procedure ReleaseSRWLockExclusive(var SRWLock: SRWLOCK); stdcall; external 'kernel32' name 'ReleaseSRWLockExclusive';
procedure AcquireSRWLockShared(var SRWLock: SRWLOCK); stdcall; external 'kernel32' name 'AcquireSRWLockShared';
procedure ReleaseSRWLockShared(var SRWLock: SRWLOCK); stdcall; external 'kernel32' name 'ReleaseSRWLockShared';
function TryAcquireSRWLockExclusive(var SRWLock: SRWLOCK): BOOL; stdcall; external 'kernel32' name 'TryAcquireSRWLockExclusive';
function TryAcquireSRWLockShared(var SRWLock: SRWLOCK): BOOL; stdcall; external 'kernel32' name 'TryAcquireSRWLockShared';
{$ENDIF}

{$ENDIF}

{$IFDEF FAFAFA_SYNC_USE_CONDVAR}
function TMutex.GetCriticalSectionPtr: Pointer;
begin
  Result := @FCS;
end;
{$ENDIF}




// ===== TMutex (Windows) =====
procedure TMutex.Acquire;
var
  LCurrentThread: TThreadID;
begin
  LCurrentThread := GetCurrentThreadId;
  if (FOwnerThread = LCurrentThread) and (FLockCount > 0) then begin Inc(FLockCount); Exit; end;
  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  EnterCriticalSection(FCS);
  FOwnerThread := LCurrentThread; FLockCount := 1; FState := lsLocked;
  {$ELSE}
  case WaitForSingleObject(FHandle, INFINITE) of
    WAIT_OBJECT_0: begin FOwnerThread := LCurrentThread; FLockCount := 1; FState := lsLocked; end;
    WAIT_ABANDONED: begin FState := lsAbandoned; raise EAbandonedMutexError.Create('Mutex was abandoned'); end;
    WAIT_FAILED: raise ELockError.CreateFmt('Failed to acquire mutex: %d', [GetLastError]);
  else raise ELockError.Create('Unexpected wait result'); end;
  {$ENDIF}
end;

procedure TMutex.Release;
var LCurrentThread: TThreadID;
begin
  LCurrentThread := GetCurrentThreadId;
  if FLockCount <= 0 then raise ELockError.Create('Mutex is not locked');
  if FOwnerThread <> LCurrentThread then raise ELockError.Create('Cannot release mutex from different thread');
  Dec(FLockCount); if FLockCount > 0 then Exit;
  FOwnerThread := 0; FState := lsUnlocked;
  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  LeaveCriticalSection(FCS);
  {$ELSE}
  if not ReleaseMutex(FHandle) then raise ELockError.CreateFmt('Failed to release mutex: %d', [GetLastError]);
  {$ENDIF}
end;

function TMutex.TryAcquire: Boolean;
var LCurrentThread: TThreadID;
begin
  LCurrentThread := GetCurrentThreadId;
  if (FOwnerThread = LCurrentThread) and (FLockCount > 0) then begin Inc(FLockCount); Exit(True); end;
  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  if TryEnterCriticalSection(FCS) then begin FOwnerThread := LCurrentThread; FLockCount := 1; FState := lsLocked; Exit(True); end else Exit(False);
  {$ELSE}
  case WaitForSingleObject(FHandle, 0) of
    WAIT_OBJECT_0: begin FOwnerThread := LCurrentThread; FLockCount := 1; FState := lsLocked; Result := True; end;
    WAIT_TIMEOUT: Result := False;
    WAIT_ABANDONED: begin FState := lsAbandoned; raise EAbandonedMutexError.Create('Mutex was abandoned'); end;
  else raise ELockError.CreateFmt('Failed to try acquire mutex: %d', [GetLastError]); end;
  {$ENDIF}
end;

function TMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  LCurrentThread: TThreadID;
  start: QWord;
begin
  LCurrentThread := GetCurrentThreadId;
  if (FOwnerThread = LCurrentThread) and (FLockCount > 0) then begin Inc(FLockCount); Exit(True); end;
  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  if ATimeoutMs = 0 then begin if TryEnterCriticalSection(FCS) then begin FOwnerThread := LCurrentThread; FLockCount := 1; FState := lsLocked; Exit(True); end else Exit(False); end;
  start := GetTickCount64;
  repeat
    if TryEnterCriticalSection(FCS) then begin FOwnerThread := LCurrentThread; FLockCount := 1; FState := lsLocked; Exit(True); end;
    if GetTickCount64 - start >= ATimeoutMs then Exit(False);
    Sleep(1);
  until False;
  {$ELSE}
  case WaitForSingleObject(FHandle, ATimeoutMs) of
    WAIT_OBJECT_0: begin FOwnerThread := LCurrentThread; FLockCount := 1; FState := lsLocked; Result := True; end;
    WAIT_TIMEOUT: Result := False;
    WAIT_ABANDONED: begin FState := lsAbandoned; raise EAbandonedMutexError.Create('Mutex was abandoned'); end;
    WAIT_FAILED: raise ELockError.CreateFmt('Failed to try acquire mutex (timeout): %d', [GetLastError]);
  else raise ELockError.Create('Unexpected wait result'); end;
  {$ENDIF}
end;


// ===== TConditionVariable (Windows) =====
constructor TConditionVariable.Create;
begin
  inherited Create;
  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  InitializeConditionVariable(FCond);
  {$ELSE}
  FWaitSemaphore := TSemaphore.Create(0, MaxInt);
  FWaitingCount := 0;
  FLock := TMutex.Create;
  FSignalEvent := TEvent.Create(False, False);
  {$ENDIF}
end;

destructor TConditionVariable.Destroy;
begin
  {$IFNDEF FAFAFA_SYNC_USE_CONDVAR}
  FWaitSemaphore := nil; FLock := nil; FSignalEvent := nil;
  {$ENDIF}
  inherited Destroy;
end;

procedure TConditionVariable.Wait(const ALock: ILock);
{$IFDEF FAFAFA_SYNC_USE_CONDVAR}
var csProv: IWinCSProvider; srwProv: IWinSRWProvider; pcs, psrw: Pointer;{$ENDIF}
begin
  if ALock = nil then raise EArgumentNilException.Create('Lock cannot be nil');
  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  if Supports(ALock, IWinCSProvider, csProv) then begin pcs := csProv.GetCriticalSectionPtr; if pcs = nil then raise ENotSupportedException.Create('CondVar requires valid CriticalSection'); SleepConditionVariableCS(@FCond, PRTLCriticalSection(pcs), INFINITE); end
  else if Supports(ALock, IWinSRWProvider, srwProv) then begin psrw := srwProv.GetSRWLockPtr; if psrw = nil then raise ENotSupportedException.Create('CondVar requires valid SRW'); SleepConditionVariableSRW(@FCond, psrw, INFINITE, 0); end
  else raise ENotSupportedException.Create('Windows ConditionVariable requires IWinCSProvider or IWinSRWProvider');
  {$ELSE}
  FLock.Acquire; try Inc(FWaitingCount); finally FLock.Release; end;
  ALock.Release; try FWaitSemaphore.Acquire; finally ALock.Acquire; FLock.Acquire; try Dec(FWaitingCount); finally FLock.Release; end; end;
  {$ENDIF}
end;

function TConditionVariable.Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean;
{$IFDEF FAFAFA_SYNC_USE_CONDVAR}
var csProv: IWinCSProvider; srwProv: IWinSRWProvider; pcs, psrw: Pointer; timeout: DWORD; ok: BOOL;{$ENDIF}
begin
  if ALock = nil then raise EArgumentNilException.Create('Lock cannot be nil');
  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  if ATimeoutMs = 0 then Exit(False); timeout := ATimeoutMs;
  if Supports(ALock, IWinCSProvider, csProv) then begin pcs := csProv.GetCriticalSectionPtr; if pcs = nil then Exit(False); ok := SleepConditionVariableCS(@FCond, PRTLCriticalSection(pcs), timeout); Result := ok; end
  else if Supports(ALock, IWinSRWProvider, srwProv) then begin psrw := srwProv.GetSRWLockPtr; if psrw = nil then Exit(False); ok := SleepConditionVariableSRW(@FCond, psrw, timeout, 0); Result := ok; end
  else raise ENotSupportedException.Create('Windows ConditionVariable requires IWinCSProvider or IWinSRWProvider');
  {$ELSE}
  FLock.Acquire; try Inc(FWaitingCount); finally FLock.Release; end;
  ALock.Release; try Result := FWaitSemaphore.TryAcquire(ATimeoutMs); finally ALock.Acquire; FLock.Acquire; try Dec(FWaitingCount); finally FLock.Release; end; end;
  {$ENDIF}
end;

procedure TConditionVariable.Signal;
begin
  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  WakeConditionVariable(@FCond);
  {$ELSE}
  FLock.Acquire; try if FWaitingCount > 0 then FWaitSemaphore.Release; finally FLock.Release; end;
  {$ENDIF}
end;

procedure TConditionVariable.Broadcast;
var LWaitingCount: Integer;
begin
  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  WakeAllConditionVariable(@FCond);
  {$ELSE}
  FLock.Acquire; try LWaitingCount := FWaitingCount; if LWaitingCount > 0 then FWaitSemaphore.Release(LWaitingCount); finally FLock.Release; end;
  {$ENDIF}
end;

// ===== TReadWriteLock (Windows) =====
constructor TReadWriteLock.Create;
begin
  inherited Create; FReaderCount := 0; FWriterWaiting := False; FWriterActive := False;
  {$IFDEF FAFAFA_SYNC_USE_SRWLOCK}
  InitializeSRWLock(FSRW); FReaderCountAtomic := 0; FWriterActiveAtomic := 0;
  {$ELSE}
  InitializeCriticalSection(FRWLock); FReadEvent := CreateEvent(nil, True, True, nil); FWriteEvent := CreateEvent(nil, False, True, nil);
  if (FReadEvent = 0) or (FWriteEvent = 0) then raise ELockError.Create('Failed to create read-write lock events');
  {$ENDIF}
end;

destructor TReadWriteLock.Destroy;
begin
  {$IFDEF FAFAFA_SYNC_USE_SRWLOCK}
  // SRW: nothing
  {$ELSE}
  if FReadEvent <> 0 then CloseHandle(FReadEvent); if FWriteEvent <> 0 then CloseHandle(FWriteEvent); DeleteCriticalSection(FRWLock);
  {$ENDIF}
  inherited Destroy;
end;

procedure TReadWriteLock.AcquireRead;
begin
  {$IFDEF FAFAFA_SYNC_USE_SRWLOCK}
  AcquireSRWLockShared(FSRW); InterlockedIncrement(FReaderCountAtomic);
  {$ELSE}
  EnterCriticalSection(FRWLock); try
    while FWriterActive or FWriterWaiting do begin LeaveCriticalSection(FRWLock); WaitForSingleObject(FReadEvent, INFINITE); EnterCriticalSection(FRWLock); end;
    Inc(FReaderCount); if FReaderCount = 1 then ResetEvent(FWriteEvent);
  finally LeaveCriticalSection(FRWLock); end;
  {$ENDIF}
end;

procedure TReadWriteLock.ReleaseRead;
begin
  {$IFDEF FAFAFA_SYNC_USE_SRWLOCK}
  var prev: LONG;
  begin
    // 检查是否存在可释放的读锁（避免在未持有时调用导致外部异常）
    prev := InterlockedCompareExchange(FReaderCountAtomic, FReaderCountAtomic, FReaderCountAtomic);
    if prev <= 0 then
      raise ELockError.Create('No read lock to release');
    InterlockedDecrement(FReaderCountAtomic);
    ReleaseSRWLockShared(FSRW);
  end;
  {$ELSE}
  EnterCriticalSection(FRWLock); try
    if FReaderCount <= 0 then raise ELockError.Create('No read lock to release');
    Dec(FReaderCount); if FReaderCount = 0 then SetEvent(FWriteEvent);
  finally LeaveCriticalSection(FRWLock); end;
  {$ENDIF}
end;

procedure TReadWriteLock.AcquireWrite;
begin
  {$IFDEF FAFAFA_SYNC_USE_SRWLOCK}
  AcquireSRWLockExclusive(FSRW); InterlockedExchange(FWriterActiveAtomic, 1);
  {$ELSE}
  EnterCriticalSection(FRWLock); try
    FWriterWaiting := True; ResetEvent(FReadEvent);
    while FReaderCount > 0 do begin LeaveCriticalSection(FRWLock); WaitForSingleObject(FWriteEvent, INFINITE); EnterCriticalSection(FRWLock); end;
    FWriterActive := True; FWriterWaiting := False;
  finally LeaveCriticalSection(FRWLock); end;
  {$ENDIF}
end;

procedure TReadWriteLock.ReleaseWrite;
begin
  {$IFDEF FAFAFA_SYNC_USE_SRWLOCK}
  var prev: LONG;
  begin
    // 未持有写锁时，不应调用 Release（避免 OS 抛出外部异常）
    prev := InterlockedCompareExchange(FWriterActiveAtomic, FWriterActiveAtomic, FWriterActiveAtomic);
    if prev = 0 then
      raise ELockError.Create('No write lock to release');
    InterlockedExchange(FWriterActiveAtomic, 0);
    ReleaseSRWLockExclusive(FSRW);
  end;
  {$ELSE}
  EnterCriticalSection(FRWLock); try
    if not FWriterActive then raise ELockError.Create('No write lock to release');
    FWriterActive := False; SetEvent(FReadEvent); SetEvent(FWriteEvent);
  finally LeaveCriticalSection(FRWLock); end;
  {$ENDIF}
end;

function TReadWriteLock.TryAcquireRead: Boolean;
begin
  {$IFDEF FAFAFA_SYNC_USE_SRWLOCK}
  Result := TryAcquireSRWLockShared(FSRW); if Result then InterlockedIncrement(FReaderCountAtomic);
  {$ELSE}
  EnterCriticalSection(FRWLock); try if FWriterActive or FWriterWaiting then Exit(False); Inc(FReaderCount); if FReaderCount = 1 then ResetEvent(FWriteEvent); Result := True; finally LeaveCriticalSection(FRWLock); end;
  {$ENDIF}
end;

function TReadWriteLock.TryAcquireRead(ATimeoutMs: Cardinal): Boolean;
var LStartTime, LElapsed: QWord;
begin
  LStartTime := GetTickCount64;
  repeat
    {$IFDEF FAFAFA_SYNC_USE_SRWLOCK}
    if TryAcquireSRWLockShared(FSRW) then begin InterlockedIncrement(FReaderCountAtomic); Exit(True); end;
    {$ELSE}
    EnterCriticalSection(FRWLock); try if not (FWriterActive or FWriterWaiting) then begin Inc(FReaderCount); if FReaderCount = 1 then ResetEvent(FWriteEvent); Exit(True); end; finally LeaveCriticalSection(FRWLock); end;
    {$ENDIF}
    LElapsed := GetTickCount64 - LStartTime; if LElapsed >= ATimeoutMs then Break; Sleep(1);
  until False;
  Result := False;
end;

function TReadWriteLock.TryAcquireWrite: Boolean;
begin
  {$IFDEF FAFAFA_SYNC_USE_SRWLOCK}
  Result := TryAcquireSRWLockExclusive(FSRW); if Result then InterlockedExchange(FWriterActiveAtomic, 1);
  {$ELSE}
  EnterCriticalSection(FRWLock); try if (FReaderCount > 0) or FWriterActive then Exit(False); FWriterActive := True; ResetEvent(FReadEvent); Result := True; finally LeaveCriticalSection(FRWLock); end;
  {$ENDIF}
end;

function TReadWriteLock.TryAcquireWrite(ATimeoutMs: Cardinal): Boolean;
var LStartTime, LElapsed: QWord;
begin
  LStartTime := GetTickCount64;
  repeat
    {$IFDEF FAFAFA_SYNC_USE_SRWLOCK}
    if TryAcquireSRWLockExclusive(FSRW) then begin InterlockedExchange(FWriterActiveAtomic, 1); Exit(True); end;
    {$ELSE}
    EnterCriticalSection(FRWLock); try if (FReaderCount = 0) and not FWriterActive then begin FWriterActive := True; ResetEvent(FReadEvent); Exit(True); end; finally LeaveCriticalSection(FRWLock); end;
    {$ENDIF}
    LElapsed := GetTickCount64 - LStartTime; if LElapsed >= ATimeoutMs then Break; Sleep(1);
  until False;
  Result := False;
end;

function TReadWriteLock.GetReaderCount: Integer;
begin
  {$IFDEF FAFAFA_SYNC_USE_SRWLOCK} Result := FReaderCountAtomic; {$ELSE} Result := FReaderCount; {$ENDIF}
end;

function TReadWriteLock.IsWriteLocked: Boolean;
begin
  {$IFDEF FAFAFA_SYNC_USE_SRWLOCK} Result := FWriterActiveAtomic <> 0; {$ELSE} Result := FWriterActive; {$ENDIF}
end;
