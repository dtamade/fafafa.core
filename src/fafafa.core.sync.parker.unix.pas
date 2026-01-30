unit fafafa.core.sync.parker.unix;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  Unix/Linux 平台 Parker 实现

  实现策略：
  - 布尔 permit 标志表示许可状态
  - pthread_mutex_t + pthread_cond_t 进行等待/唤醒
  - Unpark 设置 permit 并 signal
  - Park 检查并消费 permit，或等待

  性能特性：
  - 无许可时快速路径检查
  - 低开销的 permit 机制
}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.sync.base, fafafa.core.sync.parker.base,
  fafafa.core.time.duration;

const
  CLOCK_REALTIME = 0;

function clock_gettime(clk_id: cint; tp: PTimeSpec): cint; cdecl; external 'rt';

type
  TParker = class(TSynchronizable, IParker)
  private
    FPermit: Boolean;                   // 许可标志
    FMutex: pthread_mutex_t;
    FCond: pthread_cond_t;
    FLastError: TWaitError;
  public
    constructor Create;
    destructor Destroy; override;

    // ISynchronizable
    function GetLastError: TWaitError;

    // IParker
    procedure Park;
    function ParkTimeout(ATimeoutMs: Cardinal): Boolean;
    function ParkDuration(const ADuration: TDuration): TWaitResult;
    procedure Unpark;
  end;

function MakeParker: IParker;

implementation

resourcestring
  rsParkerInitFailed = 'Parker: failed to initialize';

{ TParker }

constructor TParker.Create;
begin
  inherited Create;
  FPermit := False;
  FLastError := weNone;

  if pthread_mutex_init(@FMutex, nil) <> 0 then
    raise ELockError.Create(rsParkerInitFailed);

  if pthread_cond_init(@FCond, nil) <> 0 then
  begin
    pthread_mutex_destroy(@FMutex);
    raise ELockError.Create(rsParkerInitFailed);
  end;
end;

destructor TParker.Destroy;
begin
  pthread_cond_destroy(@FCond);
  pthread_mutex_destroy(@FMutex);
  inherited Destroy;
end;

function TParker.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

procedure TParker.Park;
begin
  pthread_mutex_lock(@FMutex);
  try
    // 如果有许可，消费并返回
    if FPermit then
    begin
      FPermit := False;
      Exit;
    end;

    // 等待许可
    while not FPermit do
      pthread_cond_wait(@FCond, @FMutex);

    // 消费许可
    FPermit := False;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TParker.ParkTimeout(ATimeoutMs: Cardinal): Boolean;
var
  AbsTime: TTimeSpec;
  CurrentTime: TTimeSpec;
  NanoSecs: Int64;
  rc: cint;
begin
  pthread_mutex_lock(@FMutex);
  try
    // 如果有许可，消费并返回
    if FPermit then
    begin
      FPermit := False;
      Exit(True);
    end;

    // 计算绝对超时时间
    clock_gettime(CLOCK_REALTIME, @CurrentTime);
    NanoSecs := Int64(CurrentTime.tv_nsec) + Int64(ATimeoutMs) * 1000000;
    AbsTime.tv_sec := CurrentTime.tv_sec + NanoSecs div 1000000000;
    AbsTime.tv_nsec := NanoSecs mod 1000000000;

    // 等待许可或超时
    while not FPermit do
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

    // 消费许可
    FPermit := False;
    Result := True;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TParker.ParkDuration(const ADuration: TDuration): TWaitResult;
var
  TimeoutMs: Int64;
begin
  // 将 TDuration 转换为毫秒
  TimeoutMs := ADuration.AsMs;
  if TimeoutMs < 0 then
    TimeoutMs := 0;

  if ParkTimeout(Cardinal(TimeoutMs)) then
    Result := wrSignaled
  else
    Result := wrTimeout;
end;

procedure TParker.Unpark;
begin
  pthread_mutex_lock(@FMutex);
  try
    // 设置许可（多次 unpark 只存储一个许可）
    FPermit := True;
    // 唤醒等待的线程
    pthread_cond_signal(@FCond);
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function MakeParker: IParker;
begin
  Result := TParker.Create;
end;

end.
