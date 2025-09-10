unit fafafa.core.sync.sem.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.sem.base;

type
  TSem = class(TTryLock, ISem)
  private
    FHandle: THandle;
    FMaxCount: Integer;
    FCurrentCount: Integer;
    FLock: TRTLCriticalSection;
    FName: string;
  protected
    function NowMs: QWord; inline;
  public
    constructor Create(AInitialCount: Integer = 1; AMaxCount: Integer = 1);
    destructor Destroy; override;
    procedure Acquire; override;
    procedure Acquire(ACount: Integer); overload;
    procedure Release; override;
    procedure Release(ACount: Integer); overload;
    function TryAcquire: Boolean; override;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    function TryAcquire(ACount: Integer): Boolean; overload;
    function TryAcquire(ACount: Integer; ATimeoutMs: Cardinal): Boolean; overload;
    function TryRelease: Boolean; overload;
    function TryRelease(ACount: Integer): Boolean; overload;
    function GetAvailableCount: Integer;
    function GetMaxCount: Integer;
    // ISynchronizable
    function GetName: string;
    // ILock
    function LockGuard: ILockGuard;
    // ISem RAII helpers
    function AcquireGuard: ISemGuard; overload;
    function AcquireGuard(ACount: Integer): ISemGuard; overload;
    function TryAcquireGuard: ISemGuard; overload;
    function TryAcquireGuard(ATimeoutMs: Cardinal): ISemGuard; overload;
    function TryAcquireGuard(ACount: Integer): ISemGuard; overload;
    function TryAcquireGuard(ACount: Integer; ATimeoutMs: Cardinal): ISemGuard; overload;
  end;

  TSemGuard = class(TInterfacedObject, ISemGuard)
  private
    FSem: ISem;
    FCount: Integer;
  public
    constructor Create(const ASem: ISem; ACount: Integer);
    destructor Destroy; override;
    function GetCount: Integer;
    procedure Release;  // ILockGuard.Release
  end;

implementation



function TSem.LockGuard: ILockGuard;
begin
  // 统一风格：委派到 AcquireGuard（ISemGuard 继承自 ILockGuard）
  Result := AcquireGuard;
end;

constructor TSemGuard.Create(const ASem: ISem; ACount: Integer);
begin
  inherited Create;
  FSem := ASem;
  FCount := ACount;
end;

destructor TSemGuard.Destroy;
begin
  if Assigned(FSem) and (FCount > 0) then
    FSem.Release(FCount);
  inherited Destroy;
end;

function TSemGuard.GetCount: Integer;
begin
  Result := FCount;
end;

procedure TSemGuard.Release;
begin
  if Assigned(FSem) and (FCount > 0) then
  begin
    FSem.Release(FCount);
    FCount := 0;  // 防止重复释放
  end;
end;

function TSem.AcquireGuard: ISemGuard;
begin
  Acquire(1);
  Result := TSemGuard.Create(Self, 1);
end;

function TSem.AcquireGuard(ACount: Integer): ISemGuard;
begin
  Acquire(ACount);
  Result := TSemGuard.Create(Self, ACount);
end;

function TSem.TryAcquireGuard: ISemGuard;
begin
  if TryAcquire(1) then
    Result := TSemGuard.Create(Self, 1)
  else
    Result := nil;
end;

function TSem.TryAcquireGuard(ATimeoutMs: Cardinal): ISemGuard;
begin
  if TryAcquire(1, ATimeoutMs) then
    Result := TSemGuard.Create(Self, 1)
  else
    Result := nil;
end;

function TSem.TryAcquireGuard(ACount: Integer): ISemGuard;
begin
  if TryAcquire(ACount) then
    Result := TSemGuard.Create(Self, ACount)
  else
    Result := nil;
end;

function TSem.TryAcquireGuard(ACount: Integer; ATimeoutMs: Cardinal): ISemGuard;
begin
  if TryAcquire(ACount, ATimeoutMs) then
    Result := TSemGuard.Create(Self, ACount)
  else
    Result := nil;
end;

function TSem.GetName: string;
begin
  if FName = '' then Result := 'Semaphore' else Result := FName;
end;



function TSem.NowMs: QWord; inline;
begin
  {$IFDEF FPC}
  Result := GetTickCount64;
  {$ELSE}
  Result := Windows.GetTickCount64;
  {$ENDIF}
end;

constructor TSem.Create(AInitialCount: Integer; AMaxCount: Integer);
begin
  inherited Create;
  if AMaxCount <= 0 then raise EInvalidArgument.Create('AMaxCount must be > 0');
  if (AInitialCount < 0) or (AInitialCount > AMaxCount) then
    raise EInvalidArgument.Create('Invalid initial count');
  InitializeCriticalSection(FLock);
  FHandle := CreateSemaphore(nil, AInitialCount, AMaxCount, nil);
  if FHandle = 0 then
  begin
    DeleteCriticalSection(FLock);
    raise ELockError.Create('Failed to create semaphore');
  end;
  FMaxCount := AMaxCount;
  FCurrentCount := AInitialCount;
end;

destructor TSem.Destroy;
begin
  if FHandle <> 0 then CloseHandle(FHandle);
  DeleteCriticalSection(FLock);
  inherited Destroy;
end;

procedure TSem.Acquire;
begin
  Acquire(1);
end;

procedure TSem.Acquire(ACount: Integer);
var
  i, acquired: Integer;
  rc: DWORD;
begin
  if ACount < 0 then raise EInvalidArgument.Create('sem: ACount < 0');
  if ACount = 0 then Exit;
  if ACount > FMaxCount then raise EInvalidArgument.Create('sem: ACount > MaxCount');

  acquired := 0;
  try
    for i := 1 to ACount do
    begin
      rc := WaitForSingleObject(FHandle, INFINITE);
      if rc <> WAIT_OBJECT_0 then
        raise ELockError.Create('sem: failed to acquire semaphore');

      EnterCriticalSection(FLock);
      try
        Dec(FCurrentCount);
      finally
        LeaveCriticalSection(FLock);
      end;
      Inc(acquired);
    end;
  except
    on E: ECore do
    begin
      // 强异常安全：回滚已获取的许可
      if acquired > 0 then
      begin
        ReleaseSemaphore(FHandle, acquired, nil);
        EnterCriticalSection(FLock);
        try
          Inc(FCurrentCount, acquired);
        finally
          LeaveCriticalSection(FLock);
        end;
      end;
      raise;
    end;
  end;
end;

procedure TSem.Release;
begin
  Release(1);
end;

procedure TSem.Release(ACount: Integer);
begin
  if ACount < 0 then raise EInvalidArgument.Create('sem: ACount < 0');
  if ACount = 0 then Exit;
  // 在临界区内先更新本地计数，再释放内核许可，避免采样负值
  EnterCriticalSection(FLock);
  try
    if FCurrentCount + ACount > FMaxCount then
      raise ELockError.Create('sem: count exceeds max');
    Inc(FCurrentCount, ACount);
    if not ReleaseSemaphore(FHandle, ACount, nil) then
    begin
      Dec(FCurrentCount, ACount); // 回滚
      raise ELockError.Create('sem: failed to release semaphore');
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TSem.TryRelease: Boolean;
begin
  Result := TryRelease(1);
end;

function TSem.TryRelease(ACount: Integer): Boolean;
begin
  if ACount < 0 then raise EInvalidArgument.Create('sem: ACount < 0');
  if ACount = 0 then Exit(True);

  // 在单个临界区内完成检查、更新与内核调用，避免采样到不一致
  EnterCriticalSection(FLock);
  try
    if FCurrentCount + ACount > FMaxCount then
      Exit(False);
    Inc(FCurrentCount, ACount);
    if not ReleaseSemaphore(FHandle, ACount, nil) then
    begin
      Dec(FCurrentCount, ACount); // 回滚
      Exit(False);
    end;
    Result := True;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TSem.TryAcquire: Boolean;
begin
  Result := TryAcquire(1, 0);
end;

function TSem.TryAcquire(ATimeoutMs: Cardinal): Boolean;
begin
  Result := TryAcquire(1, ATimeoutMs);
end;

function TSem.TryAcquire(ACount: Integer): Boolean;
begin
  if ACount < 0 then raise EInvalidArgument.Create('sem: ACount < 0');
  if ACount = 0 then Exit(True);
  if ACount > FMaxCount then
  begin
    Exit(False);
  end;
  Result := TryAcquire(ACount, 0);
end;

function TSem.TryAcquire(ACount: Integer; ATimeoutMs: Cardinal): Boolean;
var
  acquired: Integer;
  waitMs: DWORD;
  deadline, now: QWord;
  rc: DWORD;
begin
  if ACount < 0 then raise EInvalidArgument.Create('sem: ACount < 0');
  if ACount = 0 then Exit(True);
  if ACount > FMaxCount then
  begin
    Exit(False);
  end;

  acquired := 0;
  if ATimeoutMs = INFINITE then
    deadline := High(QWord)
  else
    deadline := NowMs + QWord(ATimeoutMs);

  while acquired < ACount do
  begin
    // 对于零超时，使用非阻塞等待
    if ATimeoutMs = 0 then
      waitMs := 0
    else
    begin
      now := NowMs;
      if now >= deadline then
      begin
        // timeout - 安全回滚（直接释放内核信号量，避免 TryRelease 的前置检查导致漏回滚）
        if acquired > 0 then
        begin
          ReleaseSemaphore(FHandle, acquired, nil);
          EnterCriticalSection(FLock);
          try
            Inc(FCurrentCount, acquired);
          finally
            LeaveCriticalSection(FLock);
          end;
        end;
        Exit(False);
      end;
      if deadline = High(QWord) then
        waitMs := INFINITE
      else
        waitMs := DWORD(deadline - now);
    end;

    rc := WaitForSingleObject(FHandle, waitMs);
    if rc = WAIT_OBJECT_0 then
    begin
      Inc(acquired);
      EnterCriticalSection(FLock);
      try
        Dec(FCurrentCount);
      finally
        LeaveCriticalSection(FLock);
      end;
    end
    else if rc = WAIT_TIMEOUT then
    begin
      // 安全回滚（直接释放内核信号量 + 同步本地计数）
      if acquired > 0 then
      begin
        ReleaseSemaphore(FHandle, acquired, nil);
        EnterCriticalSection(FLock);
        try
          Inc(FCurrentCount, acquired);
        finally
          LeaveCriticalSection(FLock);
        end;
      end;
      Exit(False);
    end
    else
    begin
      // 安全回滚：使用 TryRelease 避免异常
      if acquired > 0 then
      begin
        try
          TryRelease(acquired);
        except
          // 忽略回滚异常，保持原始系统错误
        end;
      end;
      raise ELockError.Create('sem: failed to acquire semaphore');
    end;
  end;
  Result := True;
end;

function TSem.GetAvailableCount: Integer;
begin
  EnterCriticalSection(FLock);
  try
    Result := FCurrentCount;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TSem.GetMaxCount: Integer;
begin
  Result := FMaxCount;
end;

end.

