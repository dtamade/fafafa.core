unit fafafa.core.sync.latch.unix;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  Unix/Linux 平台 CountDownLatch 实现

  实现策略：
  - 原子计数器存储当前计数
  - pthread_mutex_t + pthread_cond_t 进行等待/唤醒
  - 当计数变为 0 时广播唤醒所有等待者
  - 与 WaitGroup 不同，计数只能减少不能增加
}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.sync.base, fafafa.core.sync.latch.base,
  fafafa.core.time.duration;

const
  CLOCK_REALTIME = 0;

function clock_gettime(clk_id: cint; tp: PTimeSpec): cint; cdecl; external 'rt';

type
  TLatch = class(TSynchronizable, ILatch)
  private
    FCount: LongInt;
    FMutex: pthread_mutex_t;
    FCond: pthread_cond_t;
    FLastError: TWaitError;
  public
    constructor Create(ACount: Integer);
    destructor Destroy; override;

    // ISynchronizable
    function GetLastError: TWaitError;

    // ILatch
    procedure CountDown;
    procedure Await;
    function AwaitTimeout(ATimeoutMs: Cardinal): Boolean;
    function AwaitDuration(const ADuration: TDuration): TWaitResult;
    function GetCount: Integer;
  end;

function MakeLatch(ACount: Integer): ILatch;

implementation

resourcestring
  rsLatchNegativeCount = 'Latch: initial count cannot be negative';
  rsLatchInitFailed = 'Latch: failed to initialize';

{ TLatch }

constructor TLatch.Create(ACount: Integer);
begin
  inherited Create;

  if ACount < 0 then
    raise EInvalidArgument.Create(rsLatchNegativeCount);

  FCount := ACount;
  FLastError := weNone;

  // 初始化互斥锁
  if pthread_mutex_init(@FMutex, nil) <> 0 then
    raise ELockError.Create(rsLatchInitFailed);

  // 初始化条件变量
  if pthread_cond_init(@FCond, nil) <> 0 then
  begin
    pthread_mutex_destroy(@FMutex);
    raise ELockError.Create(rsLatchInitFailed);
  end;
end;

destructor TLatch.Destroy;
begin
  pthread_cond_destroy(@FCond);
  pthread_mutex_destroy(@FMutex);
  inherited Destroy;
end;

function TLatch.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

procedure TLatch.CountDown;
begin
  pthread_mutex_lock(@FMutex);
  try
    // 只有计数大于 0 时才减少
    if FCount > 0 then
    begin
      Dec(FCount);
      // 如果计数变为 0，唤醒所有等待者
      if FCount = 0 then
        pthread_cond_broadcast(@FCond);
    end;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

procedure TLatch.Await;
begin
  pthread_mutex_lock(@FMutex);
  try
    while FCount > 0 do
      pthread_cond_wait(@FCond, @FMutex);
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TLatch.AwaitTimeout(ATimeoutMs: Cardinal): Boolean;
var
  AbsTime: TTimeSpec;
  CurrentTime: TTimeSpec;
  NanoSecs: Int64;
  rc: cint;
begin
  pthread_mutex_lock(@FMutex);
  try
    // 快速路径：计数已为 0
    if FCount = 0 then
      Exit(True);

    // 计算绝对超时时间
    clock_gettime(CLOCK_REALTIME, @CurrentTime);
    NanoSecs := Int64(CurrentTime.tv_nsec) + Int64(ATimeoutMs) * 1000000;
    AbsTime.tv_sec := CurrentTime.tv_sec + NanoSecs div 1000000000;
    AbsTime.tv_nsec := NanoSecs mod 1000000000;

    // 等待直到计数为 0 或超时
    while FCount > 0 do
    begin
      rc := pthread_cond_timedwait(@FCond, @FMutex, @AbsTime);
      if rc = ESysETIMEDOUT then
      begin
        FLastError := weTimeout;
        Exit(False);
      end
      else if rc <> 0 then
      begin
        FLastError := weSystemError;
        Exit(False);
      end;
    end;

    Result := True;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TLatch.GetCount: Integer;
begin
  Result := FCount;
end;

function TLatch.AwaitDuration(const ADuration: TDuration): TWaitResult;
var
  TimeoutMs: Int64;
begin
  // 将 TDuration 转换为毫秒
  TimeoutMs := ADuration.AsMs;
  if TimeoutMs < 0 then
    TimeoutMs := 0;

  if AwaitTimeout(Cardinal(TimeoutMs)) then
    Result := wrSignaled
  else
    Result := wrTimeout;
end;

function MakeLatch(ACount: Integer): ILatch;
begin
  Result := TLatch.Create(ACount);
end;

end.
