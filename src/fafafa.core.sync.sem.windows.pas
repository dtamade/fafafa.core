unit fafafa.core.sync.sem.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.sem.base;

type
  TSemaphore = class(TInterfacedObject, ISem)
  private
    FHandle: THandle;
    FMaxCount: Integer;
    FCurrentCount: Integer;
    FLock: TRTLCriticalSection;
    FName: string;
    FLastError: TWaitError;
    FData: Pointer;
  protected
    function NowMs: QWord; inline;
    // ISynchronizable
    function GetData: Pointer;
    procedure SetData(aData: Pointer);
  public
    constructor Create(AInitialCount: Integer = 1; AMaxCount: Integer = 1);
    destructor Destroy; override;
    procedure Acquire; overload;
    procedure Acquire(ACount: Integer); overload;
    procedure Release; overload;
    procedure Release(ACount: Integer); overload;
    function TryAcquire: Boolean; overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    function TryAcquire(ACount: Integer): Boolean; overload;
    function TryAcquire(ACount: Integer; ATimeoutMs: Cardinal): Boolean; overload;
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

function TSemaphore.GetData: Pointer;
begin
  Result := FData;
end;

procedure TSemaphore.SetData(aData: Pointer);
begin
  FData := aData;
end;

function TSemaphore.LockGuard: ILockGuard;
begin
  Acquire;
  Result := MakeLockGuardFromAcquired(Self as ILock);
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

function TSemaphore.AcquireGuard: ISemGuard;
begin
  Acquire(1);
  Result := TSemGuard.Create(Self, 1);
end;

function TSemaphore.AcquireGuard(ACount: Integer): ISemGuard;
begin
  Acquire(ACount);
  Result := TSemGuard.Create(Self, ACount);
end;

function TSemaphore.TryAcquireGuard: ISemGuard;
begin
  if TryAcquire(1) then
    Result := TSemGuard.Create(Self, 1)
  else
    Result := nil;
end;

function TSemaphore.TryAcquireGuard(ATimeoutMs: Cardinal): ISemGuard;
begin
  if TryAcquire(1, ATimeoutMs) then
    Result := TSemGuard.Create(Self, 1)
  else
    Result := nil;
end;

function TSemaphore.TryAcquireGuard(ACount: Integer): ISemGuard;
begin
  if TryAcquire(ACount) then
    Result := TSemGuard.Create(Self, ACount)
  else
    Result := nil;
end;

function TSemaphore.TryAcquireGuard(ACount: Integer; ATimeoutMs: Cardinal): ISemGuard;
begin
  if TryAcquire(ACount, ATimeoutMs) then
    Result := TSemGuard.Create(Self, ACount)
  else
    Result := nil;
end;

function TSemaphore.GetName: string;
begin
  if FName = '' then Result := 'Semaphore' else Result := FName;
end;

function TSemaphore.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

function TSemaphore.NowMs: QWord; inline;
begin
  {$IFDEF FPC}
  Result := GetTickCount64;
  {$ELSE}
  Result := Windows.GetTickCount64;
  {$ENDIF}
end;

constructor TSemaphore.Create(AInitialCount: Integer; AMaxCount: Integer);
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
    FLastError := weSystemError;
    raise ELockError.Create('Failed to create semaphore');
  end;
  FMaxCount := AMaxCount;
  FCurrentCount := AInitialCount;
  FLastError := weNone;
end;

destructor TSemaphore.Destroy;
begin
  if FHandle <> 0 then CloseHandle(FHandle);
  DeleteCriticalSection(FLock);
  inherited Destroy;
end;

procedure TSemaphore.Acquire;
begin
  Acquire(1);
end;

procedure TSemaphore.Acquire(ACount: Integer);
var
  i: Integer;
  rc: DWORD;
begin
  if ACount < 0 then raise EInvalidArgument.Create('sem: ACount < 0');
  if ACount = 0 then Exit;
  if ACount > FMaxCount then raise EInvalidArgument.Create('sem: ACount > MaxCount');
  for i := 1 to ACount do
  begin
    rc := WaitForSingleObject(FHandle, INFINITE);
    if rc <> WAIT_OBJECT_0 then
    begin
      FLastError := weSystemError;
      raise ELockError.Create('sem: failed to acquire semaphore');
    end;
    EnterCriticalSection(FLock);
    try
      Dec(FCurrentCount);
      FLastError := weNone;
    finally
      LeaveCriticalSection(FLock);
    end;
  end;
end;

procedure TSemaphore.Release;
begin
  Release(1);
end;

procedure TSemaphore.Release(ACount: Integer);
var
  prev: LongInt;
begin
  if ACount < 0 then raise EInvalidArgument.Create('sem: ACount < 0');
  if ACount = 0 then Exit;
  if not ReleaseSemaphore(FHandle, ACount, @prev) then
  begin
    FLastError := weSystemError;
    raise ELockError.Create('sem: failed to release semaphore');
  end;
  EnterCriticalSection(FLock);
  try
    FCurrentCount := prev + ACount;
    FLastError := weNone;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TSemaphore.TryAcquire: Boolean;
begin
  Result := TryAcquire(1, 0);
end;

function TSemaphore.TryAcquire(ATimeoutMs: Cardinal): Boolean;
begin
  Result := TryAcquire(1, ATimeoutMs);
end;

function TSemaphore.TryAcquire(ACount: Integer): Boolean;
begin
  if ACount < 0 then raise EInvalidArgument.Create('sem: ACount < 0');
  if ACount = 0 then Exit(True);
  if ACount > FMaxCount then
  begin
    FLastError := weResourceExhausted;
    Exit(False);
  end;
  Result := TryAcquire(ACount, 0);
end;

function TSemaphore.TryAcquire(ACount: Integer; ATimeoutMs: Cardinal): Boolean;
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
    FLastError := weResourceExhausted;
    Exit(False);
  end;
  acquired := 0;
  if ATimeoutMs = INFINITE then
    deadline := High(QWord)
  else
    deadline := NowMs + QWord(ATimeoutMs);

  while acquired < ACount do
  begin
    now := NowMs;
    if now >= deadline then
    begin
      // timeout
      if acquired > 0 then Release(acquired); // rollback
      FLastError := weTimeout;
      Exit(False);
    end;
    if deadline = High(QWord) then
      waitMs := INFINITE
    else
      waitMs := DWORD(deadline - now);

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
      if acquired > 0 then Release(acquired);
      FLastError := weTimeout;
      Exit(False);
    end
    else
    begin
      if acquired > 0 then Release(acquired);
      FLastError := weSystemError;
      raise ELockError.Create('sem: failed to acquire semaphore');
    end;
  end;
  FLastError := weNone;
  Result := True;
end;

function TSemaphore.GetAvailableCount: Integer;
begin
  EnterCriticalSection(FLock);
  try
    Result := FCurrentCount;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TSemaphore.GetMaxCount: Integer;
begin
  Result := FMaxCount;
end;

end.

