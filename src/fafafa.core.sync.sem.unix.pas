unit fafafa.core.sync.sem.unix;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.sync.base, fafafa.core.sync.sem.base;

{$IFDEF HAS_CLOCK_GETTIME}
// POSIX 时钟函数声明
function clock_gettime(clk_id: cint; tp: PTimeSpec): cint; cdecl; external 'rt';

const
  CLOCK_MONOTONIC = 1;  // 单调时钟
{$ENDIF}

type
  TSemaphore = class(TTryLock, ISem)
  private
    FMutex: pthread_mutex_t;
    FCond: pthread_cond_t;
    FCount: Integer;
    FMaxCount: Integer;
    FName: string;
  public
    constructor Create(AInitialCount: Integer = 1; AMaxCount: Integer = 1); reintroduce;
    destructor Destroy; override;
    procedure Acquire; reintroduce; overload;
    procedure Acquire(ACount: Integer); overload;
    procedure Release; reintroduce; overload;
    procedure Release(ACount: Integer); overload;
    function TryAcquire: Boolean; reintroduce; overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; reintroduce; overload;
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
    FReleased: Boolean;
  public
    constructor Create(const ASem: ISem; ACount: Integer);
    destructor Destroy; override;
    function GetCount: Integer;
    function IsLocked: Boolean;  // IGuard.IsLocked
    procedure Release;  // ILockGuard.Release
  end;

implementation

{ TSemaphore }

function TSemaphore.GetName: string;
begin
  if FName = '' then Result := 'Semaphore' else Result := FName;
end;



constructor TSemaphore.Create(AInitialCount: Integer; AMaxCount: Integer);
begin
  inherited Create;
  if AMaxCount <= 0 then raise EInvalidArgument.Create('AMaxCount must be > 0');
  if (AInitialCount < 0) or (AInitialCount > AMaxCount) then
    raise EInvalidArgument.Create('Invalid initial count');
  if pthread_mutex_init(@FMutex, nil) <> 0 then
  begin
    raise ELockError.Create('sem: mutex init failed');
  end;
  if pthread_cond_init(@FCond, nil) <> 0 then
  begin
    pthread_mutex_destroy(@FMutex);
    raise ELockError.Create('sem: cond init failed');
  end;
  FMaxCount := AMaxCount;
  FCount := AInitialCount;
end;

destructor TSemaphore.Destroy;
begin
  pthread_cond_destroy(@FCond);
  pthread_mutex_destroy(@FMutex);
  inherited Destroy;
end;

procedure TSemaphore.Acquire;
begin
  Acquire(1);
end;

procedure TSemaphore.Acquire(ACount: Integer);
begin
  if ACount < 0 then raise EInvalidArgument.Create('sem: ACount < 0');
  if ACount = 0 then Exit;
  if ACount > FMaxCount then raise EInvalidArgument.Create('sem: ACount > MaxCount');
  if pthread_mutex_lock(@FMutex) <> 0 then
  begin
    raise ELockError.Create('sem: lock failed');
  end;
  try
    while FCount < ACount do
      pthread_cond_wait(@FCond, @FMutex);
    Dec(FCount, ACount);

  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

procedure TSemaphore.Release;
begin
  Release(1);
end;

procedure TSemaphore.Release(ACount: Integer);
var
  i: Integer;
begin
  if ACount < 0 then raise EInvalidArgument.Create('sem: ACount < 0');
  if ACount = 0 then Exit;
  if pthread_mutex_lock(@FMutex) <> 0 then
  begin
    raise ELockError.Create('sem: lock failed');
  end;
  try
    for i := 1 to ACount do
    begin
      if FCount < FMaxCount then
      begin
        Inc(FCount);
        pthread_cond_signal(@FCond);
      end
      else
      begin
        raise ELockError.Create('sem: count exceeds max');
      end;
    end;

  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TSemaphore.TryRelease: Boolean;
begin
  Result := TryRelease(1);
end;

function TSemaphore.TryRelease(ACount: Integer): Boolean;
begin
  if ACount < 0 then raise EInvalidArgument.Create('sem: ACount < 0');
  if ACount = 0 then Exit(True);

  if pthread_mutex_lock(@FMutex) <> 0 then
  begin
    Exit(False);
  end;

  try
    // 检查是否会超出最大�?
    if FCount + ACount > FMaxCount then
    begin
      Exit(False);
    end;

    // 执行释放
    Inc(FCount, ACount);

    // 通知等待的线�?
    if pthread_cond_broadcast(@FCond) <> 0 then
    begin
      Exit(False);
    end;

    Result := True;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TSemaphore.TryAcquire: Boolean;
begin
  Result := TryAcquire(1);
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
    Exit(False);
  end;
  Result := TryAcquire(ACount, 0);
end;

function TSemaphore.TryAcquire(ACount: Integer; ATimeoutMs: Cardinal): Boolean;
var
  {$IFDEF HAS_CLOCK_GETTIME}
  nowTs: timespec;
  {$ELSE}
  tv: TTimeVal;
  {$ENDIF}
  ts: timespec;
  rc: Integer;
begin
  if ACount < 0 then raise EInvalidArgument.Create('sem: ACount < 0');
  if ACount = 0 then Exit(True);
  if ACount > FMaxCount then
  begin
    Exit(False);
  end;
  if pthread_mutex_lock(@FMutex) <> 0 then
  begin
    raise ELockError.Create('sem: lock failed');
  end;
  try
    if ATimeoutMs = 0 then
    begin
      if FCount >= ACount then
      begin
        Dec(FCount, ACount);

        Exit(True);
      end
      else
      begin
        // zero-timeout immediate failure: resource currently unavailable (no wait)

        Exit(False);
      end;
    end
    else
    begin
      // 使用单调时钟计算超时，避免系统时间调整的影响
      {$IFDEF HAS_CLOCK_GETTIME}
      if clock_gettime(CLOCK_MONOTONIC, @nowTs) <> 0 then
      begin

        Exit(False);
      end;
      ts.tv_sec := nowTs.tv_sec + (ATimeoutMs div 1000);
      ts.tv_nsec := nowTs.tv_nsec + Int64(ATimeoutMs mod 1000) * 1000000;
      if ts.tv_nsec >= 1000000000 then
      begin
        Inc(ts.tv_sec);
        Dec(ts.tv_nsec, 1000000000);
      end;
      {$ELSE}
      // 回退�?gettimeofday（在不支�?CLOCK_MONOTONIC 的系统上�?
      if fpgettimeofday(@tv, nil) <> 0 then
      begin

        Exit(False);
      end;
      ts.tv_sec := tv.tv_sec + (ATimeoutMs div 1000);
      ts.tv_nsec := (tv.tv_usec * 1000) + (ATimeoutMs mod 1000) * 1000000;
      if ts.tv_nsec >= 1000000000 then
      begin
        Inc(ts.tv_sec, ts.tv_nsec div 1000000000);
        ts.tv_nsec := ts.tv_nsec mod 1000000000;
      end;
      {$ENDIF}

      while FCount < ACount do
      begin
        rc := pthread_cond_timedwait(@FCond, @FMutex, @ts);
        if rc = ESysETIMEDOUT then
        begin
          // waited until deadline: real timeout

          Exit(False);
        end
        else if rc = ESysEINTR then
        begin
          // interrupted by signal: continue waiting until condition or timeout
          continue;
        end
        else if rc <> 0 then
        begin

          Exit(False);
        end;
      end;
      Dec(FCount, ACount);

      Exit(True);
    end;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TSemaphore.GetAvailableCount: Integer;
begin
  if pthread_mutex_lock(@FMutex) <> 0 then
    raise ELockError.Create('sem: lock failed');
  try
    Result := FCount;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TSemaphore.GetMaxCount: Integer;
begin
  if pthread_mutex_lock(@FMutex) <> 0 then
    raise ELockError.Create('sem: lock failed');
  try
    Result := FMaxCount;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;



function TSemaphore.LockGuard: ILockGuard;
begin
  Result := AcquireGuard;
end;

{ TSemGuard }

constructor TSemGuard.Create(const ASem: ISem; ACount: Integer);
begin
  inherited Create;
  FSem := ASem;
  FCount := ACount;
  FReleased := False;
end;

destructor TSemGuard.Destroy;
begin
  if (not FReleased) and Assigned(FSem) and (FCount > 0) then
    FSem.Release(FCount);
  inherited Destroy;
end;

function TSemGuard.GetCount: Integer;
begin
  Result := FCount;
end;

function TSemGuard.IsLocked: Boolean;
begin
  Result := (not FReleased) and Assigned(FSem) and (FCount > 0);
end;

procedure TSemGuard.Release;
begin
  if (not FReleased) and Assigned(FSem) and (FCount > 0) then
  begin
    FSem.Release(FCount);
    FReleased := True;
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

end.

