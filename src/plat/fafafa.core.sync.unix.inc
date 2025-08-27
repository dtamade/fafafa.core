{$IFDEF UNIX}
// 目前 Unix 平台外部符号由 pthreads 单元提供，无需额外 external
{$ENDIF}

// ===== TMutex (Unix) =====
function TMutex.GetPThreadMutexPtr: Ppthread_mutex_t;
begin
  Result := @FMutex;
end;

procedure TMutex.Acquire;
var
  LCurrentThread: TThreadID;
begin
  LCurrentThread := GetCurrentThreadId;
  if (FOwnerThread = LCurrentThread) and (FLockCount > 0) then begin Inc(FLockCount); Exit; end;
  if pthread_mutex_lock(@FMutex) = 0 then
  begin
    FOwnerThread := LCurrentThread;
    FLockCount := 1;
    FState := lsLocked;
  end
  else
    raise ELockError.Create('Failed to acquire mutex');
end;

procedure TMutex.Release;
var LCurrentThread: TThreadID;
begin
  LCurrentThread := GetCurrentThreadId;
  if FLockCount <= 0 then raise ELockError.Create('Mutex is not locked');
  if FOwnerThread <> LCurrentThread then raise ELockError.Create('Cannot release mutex from different thread');
  Dec(FLockCount); if FLockCount > 0 then Exit;
  FOwnerThread := 0; FState := lsUnlocked;
  if pthread_mutex_unlock(@FMutex) <> 0 then
    raise ELockError.Create('Failed to release mutex');
end;

function TMutex.TryAcquire: Boolean;
var LCurrentThread: TThreadID;
begin
  LCurrentThread := GetCurrentThreadId;
  if (FOwnerThread = LCurrentThread) and (FLockCount > 0) then begin Inc(FLockCount); Exit(True); end;
  case pthread_mutex_trylock(@FMutex) of
    0:
    begin
      FOwnerThread := LCurrentThread;
      FLockCount := 1;
      FState := lsLocked;
      Exit(True);
    end;
    EBUSY: Exit(False);
  else
    raise ELockError.Create('Failed to try acquire mutex');
  end;
end;

function TMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  LCurrentThread: TThreadID;
  tv: TTimeVal;
  ts: timespec;
  rc: Integer;
begin
  LCurrentThread := GetCurrentThreadId;
  if (FOwnerThread = LCurrentThread) and (FLockCount > 0) then begin Inc(FLockCount); Exit(True); end;
  if fpgettimeofday(@tv, nil) <> 0 then
    raise ELockError.Create('gettimeofday failed in TryAcquire(timeout)');
  ts.tv_sec := tv.tv_sec + (ATimeoutMs div 1000);
  ts.tv_nsec := (tv.tv_usec * 1000) + (ATimeoutMs mod 1000) * 1000000;
  if ts.tv_nsec >= 1000000000 then
  begin
    Inc(ts.tv_sec, ts.tv_nsec div 1000000000);
    ts.tv_nsec := ts.tv_nsec mod 1000000000;
  end;
  rc := pthread_mutex_timedlock(@FMutex, @ts);
  case rc of
    0:
    begin
      FOwnerThread := LCurrentThread;
      FLockCount := 1;
      FState := lsLocked;
      Exit(True);
    end;
    ETIMEDOUT, EBUSY: Exit(False);
  else
    raise ELockError.Create('Failed to acquire mutex with timeout');
  end;
end;




// ===== TConditionVariable (Unix) =====
constructor TConditionVariable.Create;
var attr: pthread_condattr_t;
begin
  inherited Create;
  if pthread_condattr_init(@attr) <> 0 then raise ELockError.Create('Failed to init cond attr');
  if pthread_condattr_setclock(@attr, CLOCK_MONOTONIC) <> 0 then begin pthread_condattr_destroy(@attr); raise ELockError.Create('Failed to set cond clock MONOTONIC'); end;
  if pthread_cond_init(@FCond, @attr) <> 0 then begin pthread_condattr_destroy(@attr); raise ELockError.Create('Failed to create condition variable'); end;
  pthread_condattr_destroy(@attr);
end;

destructor TConditionVariable.Destroy;
begin
  pthread_cond_destroy(@FCond);
  inherited Destroy;
end;

procedure TConditionVariable.Wait(const ALock: ILock);
var LProvider: IUnixMutexProvider; pmutex: Ppthread_mutex_t; rc: Integer;
begin
  if not Supports(ALock, IUnixMutexProvider, LProvider) then begin ALock.Release; try Sleep(1) else finally ALock.Acquire; end; Exit; end;
  pmutex := LProvider.GetPThreadMutexPtr; if pmutex = nil then raise ELockError.Create('ConditionVariable: mutex provider returned nil');
  ALock.Release; try rc := pthread_cond_wait(@FCond, pmutex); if rc <> 0 then raise ELockError.Create('pthread_cond_wait failed'); finally ALock.Acquire; end;
end;

function TConditionVariable.Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean;
var LProvider: IUnixMutexProvider; pmutex: Ppthread_mutex_t; nowts, ts: timespec; rc: Integer; remaining: Cardinal;
begin
  if not Supports(ALock, IUnixMutexProvider, LProvider) then begin if ATimeoutMs = 0 then Exit(False); remaining := ATimeoutMs; ALock.Release; try while remaining > 0 do begin if remaining >= 10 then begin Sleep(10); Dec(remaining, 10); end else begin Sleep(remaining); remaining := 0; end; end; Result := False; finally ALock.Acquire; end; Exit; end;
  if clock_gettime(CLOCK_MONOTONIC, @nowts) <> 0 then Exit(False);
  ts := nowts; Inc(ts.tv_sec, ATimeoutMs div 1000); Inc(ts.tv_nsec, (ATimeoutMs mod 1000) * 1000000);
  if ts.tv_nsec >= 1000000000 then begin Inc(ts.tv_sec, ts.tv_nsec div 1000000000); ts.tv_nsec := ts.tv_nsec mod 1000000000; end;
  pmutex := LProvider.GetPThreadMutexPtr; if pmutex = nil then Exit(False);
  ALock.Release; try rc := pthread_cond_timedwait(@FCond, pmutex, @ts); if rc = 0 then Exit(True) else if rc = ETIMEDOUT then Exit(False) else Exit(False); finally ALock.Acquire; end;
end;

procedure TConditionVariable.Signal;
begin
  if pthread_cond_signal(@FCond) <> 0 then raise ELockError.Create('Failed to signal condition variable');
end;

procedure TConditionVariable.Broadcast;
begin
  if pthread_cond_broadcast(@FCond) <> 0 then raise ELockError.Create('Failed to broadcast condition variable');
end;

// ===== TReadWriteLock (Unix) =====
constructor TReadWriteLock.Create;
begin
  inherited Create; FReaderCount := 0; FWriterWaiting := False; FWriterActive := False;
  if pthread_rwlock_init(@FRWLock, nil) <> 0 then raise ELockError.Create('Failed to create read-write lock');
end;

destructor TReadWriteLock.Destroy;
begin
  pthread_rwlock_destroy(@FRWLock);
  inherited Destroy;
end;

procedure TReadWriteLock.AcquireRead;
begin
  if pthread_rwlock_rdlock(@FRWLock) <> 0 then raise ELockError.Create('Failed to acquire read lock');
  InterlockedIncrement(FReaderCount);
end;

procedure TReadWriteLock.ReleaseRead;
begin
  InterlockedDecrement(FReaderCount);
  if pthread_rwlock_unlock(@FRWLock) <> 0 then raise ELockError.Create('Failed to release read lock');
end;

procedure TReadWriteLock.AcquireWrite;
begin
  if pthread_rwlock_wrlock(@FRWLock) <> 0 then raise ELockError.Create('Failed to acquire write lock');
  FWriterActive := True;
end;

procedure TReadWriteLock.ReleaseWrite;
begin
  FWriterActive := False;
  if pthread_rwlock_unlock(@FRWLock) <> 0 then raise ELockError.Create('Failed to release write lock');
end;

function TReadWriteLock.TryAcquireRead: Boolean;
begin
  case pthread_rwlock_tryrdlock(@FRWLock) of
    0: begin InterlockedIncrement(FReaderCount); Exit(True); end;
    EBUSY: Exit(False);
  else raise ELockError.Create('Failed to try acquire read lock'); end;
end;

function TReadWriteLock.TryAcquireRead(ATimeoutMs: Cardinal): Boolean;
var LStart, LElapsed: QWord;
begin
  LStart := GetTickCount64;
  repeat
    case pthread_rwlock_tryrdlock(@FRWLock) of
      0: begin InterlockedIncrement(FReaderCount); Exit(True); end;
      EBUSY: ;
    else raise ELockError.Create('Failed to try acquire read lock'); end;
    LElapsed := GetTickCount64 - LStart; if LElapsed >= ATimeoutMs then Break; Sleep(1);
  until False;
  Result := False;
end;

function TReadWriteLock.TryAcquireWrite: Boolean;
begin
  case pthread_rwlock_trywrlock(@FRWLock) of
    0: begin FWriterActive := True; Exit(True); end;
    EBUSY: Exit(False);
  else raise ELockError.Create('Failed to try acquire write lock'); end;
end;

function TReadWriteLock.TryAcquireWrite(ATimeoutMs: Cardinal): Boolean;
var LStart, LElapsed: QWord;
begin
  LStart := GetTickCount64;
  repeat
    case pthread_rwlock_trywrlock(@FRWLock) of
      0: begin FWriterActive := True; Exit(True); end;
      EBUSY: ;
    else raise ELockError.Create('Failed to try acquire write lock'); end;
    LElapsed := GetTickCount64 - LStart; if LElapsed >= ATimeoutMs then Break; Sleep(1);
  until False;
  Result := False;
end;

function TReadWriteLock.GetReaderCount: Integer;
begin
  Result := FReaderCount;
end;

function TReadWriteLock.IsWriteLocked: Boolean;
begin
  Result := FWriterActive;
end;
