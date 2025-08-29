unit fafafa.core.sync.semaphore.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.semaphore.base;

type
  TSemaphore = class(TInterfacedObject, ISemaphore)
  private
    FMutex: pthread_mutex_t;
    FCond: pthread_cond_t;
    FCount: Integer;
    FMaxCount: Integer;
    FName: string;
    FLastError: TWaitError;
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
    function GetLastError: TWaitError;
  end;

implementation

{ TSemaphore }

function TSemaphore.GetName: string;
begin
  if FName = '' then Result := 'Semaphore' else Result := FName;
end;

function TSemaphore.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

constructor TSemaphore.Create(AInitialCount: Integer; AMaxCount: Integer);
begin
  inherited Create;
  if AMaxCount <= 0 then raise EInvalidArgument.Create('AMaxCount must be > 0');
  if (AInitialCount < 0) or (AInitialCount > AMaxCount) then
    raise EInvalidArgument.Create('Invalid initial count');
  if pthread_mutex_init(@FMutex, nil) <> 0 then
  begin
    FLastError := weSystemError;
    raise ELockError.Create('sem: mutex init failed');
  end;
  if pthread_cond_init(@FCond, nil) <> 0 then
  begin
    pthread_mutex_destroy(@FMutex);
    FLastError := weSystemError;
    raise ELockError.Create('sem: cond init failed');
  end;
  FMaxCount := AMaxCount;
  FCount := AInitialCount;
  FLastError := weNone;
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
    FLastError := weSystemError;
    raise ELockError.Create('sem: lock failed');
  end;
  try
    while FCount < ACount do
      pthread_cond_wait(@FCond, @FMutex);
    Dec(FCount, ACount);
    FLastError := weNone;
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
    FLastError := weSystemError;
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
        FLastError := weSystemError;
        raise ELockError.Create('sem: count exceeds max');
      end;
    end;
    FLastError := weNone;
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
    FLastError := weResourceExhausted;
    Exit(False);
  end;
  Result := TryAcquire(ACount, 0);
end;

function TSemaphore.TryAcquire(ACount: Integer; ATimeoutMs: Cardinal): Boolean;
var
  tv: TTimeVal;
  ts: timespec;
  rc: Integer;
begin
  if ACount < 0 then raise EInvalidArgument.Create('sem: ACount < 0');
  if ACount = 0 then Exit(True);
  if ACount > FMaxCount then
  begin
    FLastError := weResourceExhausted;
    Exit(False);
  end;
  if pthread_mutex_lock(@FMutex) <> 0 then
  begin
    FLastError := weSystemError;
    raise ELockError.Create('sem: lock failed');
  end;
  try
    if ATimeoutMs = 0 then
    begin
      if FCount >= ACount then
      begin
        Dec(FCount, ACount);
        FLastError := weNone;
        Exit(True);
      end
      else
      begin
        // zero-timeout immediate failure: resource currently unavailable (no wait)
        FLastError := weResourceExhausted;
        Exit(False);
      end;
    end
    else
    begin
      if fpgettimeofday(@tv, nil) <> 0 then
      begin
        FLastError := weSystemError;
        Exit(False);
      end;
      ts.tv_sec := tv.tv_sec + (ATimeoutMs div 1000);
      ts.tv_nsec := (tv.tv_usec * 1000) + (ATimeoutMs mod 1000) * 1000000;
      if ts.tv_nsec >= 1000000000 then
      begin
        Inc(ts.tv_sec, ts.tv_nsec div 1000000000);
        ts.tv_nsec := ts.tv_nsec mod 1000000000;
      end;
      while FCount < ACount do
      begin
        rc := pthread_cond_timedwait(@FCond, @FMutex, @ts);
        if rc = ESysETIMEDOUT then
        begin
          // waited until deadline: real timeout
          FLastError := weTimeout;
          Exit(False);
        end
        else if rc = ESysEINTR then
        begin
          // interrupted by signal: continue waiting until condition or timeout
          continue;
        end
        else if rc <> 0 then
        begin
          FLastError := weSystemError;
          Exit(False);
        end;
      end;
      Dec(FCount, ACount);
      FLastError := weNone;
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

end.

