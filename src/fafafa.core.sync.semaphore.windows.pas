unit fafafa.core.sync.semaphore.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.semaphore.base;

type
  TSemaphore = class(TInterfacedObject, ISemaphore)
  private
    FHandle: THandle;
    FMaxCount: Integer;
    FCurrentCount: Integer;
    FLock: TRTLCriticalSection;
  protected
    function NowMs: QWord; inline;
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
  end;

implementation

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
    raise ELockError.Create('Failed to create semaphore');
  end;
  FMaxCount := AMaxCount;
  FCurrentCount := AInitialCount;
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
  if ACount <= 0 then Exit;
  for i := 1 to ACount do
  begin
    rc := WaitForSingleObject(FHandle, INFINITE);
    if rc <> WAIT_OBJECT_0 then
      raise ELockError.Create('Failed to acquire semaphore');
    EnterCriticalSection(FLock);
    try
      Dec(FCurrentCount);
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
  if ACount <= 0 then Exit;
  EnterCriticalSection(FLock);
  try
    if (FCurrentCount + ACount) > FMaxCount then
      raise ELockError.Create('Semaphore count would exceed maximum');
  finally
    LeaveCriticalSection(FLock);
  end;
  if not ReleaseSemaphore(FHandle, ACount, @prev) then
    raise ELockError.Create('Failed to release semaphore');
  EnterCriticalSection(FLock);
  try
    FCurrentCount := prev + ACount;
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
  Result := TryAcquire(ACount, 0);
end;

function TSemaphore.TryAcquire(ACount: Integer; ATimeoutMs: Cardinal): Boolean;
var
  acquired: Integer;
  waitMs: DWORD;
  deadline, now: QWord;
  rc: DWORD;
begin
  if ACount <= 0 then Exit(True);
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
      Exit(False);
    end
    else
    begin
      if acquired > 0 then Release(acquired);
      raise ELockError.Create('Failed to acquire semaphore');
    end;
  end;
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

