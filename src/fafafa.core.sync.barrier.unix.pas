unit fafafa.core.sync.barrier.unix;

{
  Unix/Linux 平台屏障同步实现

  特性：
  - 优先使用 pthread_barrier_t 系统实现 (可�?
  - 默认使用 mutex + condition variable fallback 实现
  - �?Unix 系统兼容�?(Linux, macOS, FreeBSD �?
  - 支持编译时配置选择实现方式

  配置宏：
  - FAFAFA_SYNC_USE_POSIX_BARRIER: 启用 pthread_barrier_t 原生支持

  实现策略�?
  - 默认关闭原生 POSIX barrier 以确保最大兼容�?
  - fallback 实现使用 generation 计数器避免虚假唤�?
  - 正确实现串行线程语义 (一个线程返�?True)
}

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Unix, UnixType, pthreads,
  fafafa.core.sync.base, fafafa.core.sync.barrier.base;

type
  TBarrier = class(TSynchronizable, IBarrier)
  private
    FParticipantCount: Integer;
    {$IFDEF FAFAFA_SYNC_USE_POSIX_BARRIER}
    FBarrier: pthread_barrier_t;
    FGeneration: Cardinal;  // Track generation even for POSIX barrier
    {$ELSE}
    FWaitingCount: Integer;
    FGeneration: Cardinal;  // Changed from Integer to Cardinal for consistency
    FMutex: pthread_mutex_t;
    FCond: pthread_cond_t;
    {$ENDIF}
  public
    constructor Create(AParticipantCount: Integer);
    destructor Destroy; override;

    // IBarrier
    function Wait: Boolean;
    function WaitEx: TBarrierWaitResult;
    function GetParticipantCount: Integer;
  end;

{**
 * MakeBarrier - 创建 Unix 平台屏障实例
 *
 * @param AParticipantCount 参与线程数量
 * @return 屏障接口实例
 *}
function MakeBarrier(AParticipantCount: Integer): IBarrier;

implementation

{ TBarrier }

constructor TBarrier.Create(AParticipantCount: Integer);
begin
  inherited Create;
  if AParticipantCount <= 0 then
    raise EInvalidArgument.Create('Barrier participants must be > 0');
  FParticipantCount := AParticipantCount;
  FGeneration := 0;  // Initialize generation for both implementations
  {$IFDEF FAFAFA_SYNC_USE_POSIX_BARRIER}
  if pthread_barrier_init(@FBarrier, nil, FParticipantCount) <> 0 then
    raise ELockError.Create('barrier: pthread_barrier_init failed');
  {$ELSE}
  FWaitingCount := 0;
  if pthread_mutex_init(@FMutex, nil) <> 0 then
    raise ELockError.Create('barrier: mutex init failed');
  if pthread_cond_init(@FCond, nil) <> 0 then
  begin
    pthread_mutex_destroy(@FMutex);
    raise ELockError.Create('barrier: cond init failed');
  end;
  {$ENDIF}
end;

destructor TBarrier.Destroy;
begin
  {$IFDEF FAFAFA_SYNC_USE_POSIX_BARRIER}
  pthread_barrier_destroy(@FBarrier);
  {$ELSE}
  pthread_cond_destroy(@FCond);
  pthread_mutex_destroy(@FMutex);
  {$ENDIF}
  inherited Destroy;
end;

function TBarrier.Wait: Boolean;
{$IFDEF FAFAFA_SYNC_USE_POSIX_BARRIER}
var rc: Integer;
begin
  rc := pthread_barrier_wait(@FBarrier);
  case rc of
    0: Result := False; // non-serial
    PTHREAD_BARRIER_SERIAL_THREAD:
      begin
        Inc(FGeneration);  // Track generation for WaitEx support
        Result := True;    // serial
      end;
  else
    Result := False;
  end;
end;
{$ELSE}
var
  myGen: Cardinal;
begin
  // Emulate serial-thread semantics: return True for one thread per phase.
  if pthread_mutex_lock(@FMutex) <> 0 then
  begin
    Exit(False);
  end;
  try
    myGen := FGeneration;
    Inc(FWaitingCount);
    if FWaitingCount = FParticipantCount then
    begin
      Inc(FGeneration);
      FWaitingCount := 0;
      // Wake all waiters and designate current as serial thread
      pthread_cond_broadcast(@FCond);
      Result := True;
      Exit;
    end
    else
    begin
      while (myGen = FGeneration) do
        pthread_cond_wait(@FCond, @FMutex);
      Result := False; // non-serial
      Exit;
    end;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;
{$ENDIF}

function TBarrier.WaitEx: TBarrierWaitResult;
{$IFDEF FAFAFA_SYNC_USE_POSIX_BARRIER}
var
  rc: Integer;
  gen: Cardinal;
begin
  rc := pthread_barrier_wait(@FBarrier);
  case rc of
    0:
      begin
        gen := FGeneration;  // Read current generation
        Result := TBarrierWaitResult.Follower(gen);
      end;
    PTHREAD_BARRIER_SERIAL_THREAD:
      begin
        Inc(FGeneration);    // Increment generation
        gen := FGeneration;
        Result := TBarrierWaitResult.Leader(gen);
      end;
  else
    gen := FGeneration;
    Result := TBarrierWaitResult.Follower(gen);
  end;
end;
{$ELSE}
var
  myGen: Cardinal;
  resultGen: Cardinal;
begin
  // Emulate serial-thread semantics: return True for one thread per phase.
  if pthread_mutex_lock(@FMutex) <> 0 then
  begin
    Result := TBarrierWaitResult.Follower(FGeneration);
    Exit;
  end;
  try
    myGen := FGeneration;
    Inc(FWaitingCount);
    if FWaitingCount = FParticipantCount then
    begin
      Inc(FGeneration);
      FWaitingCount := 0;
      resultGen := FGeneration;
      // Wake all waiters and designate current as serial thread
      pthread_cond_broadcast(@FCond);
      Result := TBarrierWaitResult.Leader(resultGen);
    end
    else
    begin
      while (myGen = FGeneration) do
        pthread_cond_wait(@FCond, @FMutex);
      resultGen := FGeneration;
      Result := TBarrierWaitResult.Follower(resultGen);
    end;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;
{$ENDIF}

function TBarrier.GetParticipantCount: Integer;
begin
  Result := FParticipantCount;
end;

function MakeBarrier(AParticipantCount: Integer): IBarrier;
begin
  Result := TBarrier.Create(AParticipantCount);
end;

end.

