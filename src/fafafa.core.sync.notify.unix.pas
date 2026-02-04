unit fafafa.core.sync.notify.unix;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  INotify Unix 实现

  使用 pthread_cond_t + pthread_mutex_t 实现：
  - 等待队列管理使用 FIFO 原则
  - NotifyOne 使用 pthread_cond_signal
  - NotifyAll 使用 pthread_cond_broadcast

  线程安全保证：
  - 所有操作都在互斥锁保护下进行
  - waiter count 原子更新
}

interface

{$IFDEF UNIX}

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.sync.base,
  fafafa.core.sync.notify.base,
  fafafa.core.time.duration,
  fafafa.core.atomic;

const
  CLOCK_REALTIME = 0;

function clock_gettime(clk_id: cint; tp: PTimeSpec): cint; cdecl; external 'rt';

type

  { TNotifyUnix }

  TNotifyUnix = class(TInterfacedObject, INotify, ISynchronizable)
  private
    FMutex: pthread_mutex_t;
    FCond: pthread_cond_t;
    FWaiterCount: Int32;
    FGeneration: Int64;  // 用于区分不同的通知周期
    FData: Pointer;      // 用户数据（ISynchronizable 要求）
  public
    constructor Create;
    destructor Destroy; override;

    { INotify }
    procedure Wait;
    function WaitTimeout(ATimeoutMs: Cardinal): Boolean;
    function WaitDuration(const ADuration: TDuration): TWaitResult;
    procedure NotifyOne;
    procedure NotifyAll;
    function GetWaiterCount: Integer;

    { ISynchronizable }
    function GetData: Pointer;
    procedure SetData(AData: Pointer);
  end;

function MakeNotifyUnix: INotify;

{$ENDIF}

implementation

{$IFDEF UNIX}

{ Helper functions }

function TimeSpecFromMs(AMs: Cardinal): timespec;
var
  Now: timespec;
begin
  clock_gettime(CLOCK_REALTIME, @Now);
  Result.tv_sec := Now.tv_sec + (AMs div 1000);
  Result.tv_nsec := Now.tv_nsec + ((AMs mod 1000) * 1000000);
  // 处理纳秒溢出
  if Result.tv_nsec >= 1000000000 then
  begin
    Inc(Result.tv_sec);
    Dec(Result.tv_nsec, 1000000000);
  end;
end;

{ TNotifyUnix }

constructor TNotifyUnix.Create;
begin
  inherited Create;
  FWaiterCount := 0;
  FGeneration := 0;
  FData := nil;

  if pthread_mutex_init(@FMutex, nil) <> 0 then
    raise ELockError.Create('Notify: failed to initialize mutex');

  if pthread_cond_init(@FCond, nil) <> 0 then
  begin
    pthread_mutex_destroy(@FMutex);
    raise ELockError.Create('Notify: failed to initialize condition variable');
  end;
end;

destructor TNotifyUnix.Destroy;
begin
  pthread_cond_destroy(@FCond);
  pthread_mutex_destroy(@FMutex);
  inherited Destroy;
end;

procedure TNotifyUnix.Wait;
var
  MyGeneration: Int64;
begin
  pthread_mutex_lock(@FMutex);
  try
    // 记录当前代数，用于检测是否被通知
    MyGeneration := FGeneration;
    atomic_fetch_add(FWaiterCount, 1, mo_relaxed);

    // 等待直到代数变化（即收到通知）
    while MyGeneration = FGeneration do
      pthread_cond_wait(@FCond, @FMutex);

    atomic_fetch_sub(FWaiterCount, 1, mo_relaxed);
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TNotifyUnix.WaitTimeout(ATimeoutMs: Cardinal): Boolean;
var
  MyGeneration: Int64;
  AbsTime: timespec;
  Rc: Integer;
begin
  // 0 超时立即返回
  if ATimeoutMs = 0 then
    Exit(False);

  AbsTime := TimeSpecFromMs(ATimeoutMs);

  pthread_mutex_lock(@FMutex);
  try
    MyGeneration := FGeneration;
    atomic_fetch_add(FWaiterCount, 1, mo_relaxed);

    Result := True;
    while MyGeneration = FGeneration do
    begin
      Rc := pthread_cond_timedwait(@FCond, @FMutex, @AbsTime);
      if Rc = ESysETIMEDOUT then
      begin
        Result := False;
        Break;
      end;
    end;

    atomic_fetch_sub(FWaiterCount, 1, mo_relaxed);
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TNotifyUnix.WaitDuration(const ADuration: TDuration): TWaitResult;
var
  TimeoutMs: Int64;
begin
  TimeoutMs := ADuration.AsMs;

  // 负数或零立即返回超时
  if TimeoutMs <= 0 then
    Exit(wrTimeout);

  // 防止溢出
  if TimeoutMs > High(Cardinal) then
    TimeoutMs := High(Cardinal);

  if WaitTimeout(Cardinal(TimeoutMs)) then
    Result := wrSignaled
  else
    Result := wrTimeout;
end;

procedure TNotifyUnix.NotifyOne;
begin
  pthread_mutex_lock(@FMutex);
  try
    // 增加代数，让一个等待者检测到变化
    Inc(FGeneration);
    pthread_cond_signal(@FCond);
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

procedure TNotifyUnix.NotifyAll;
begin
  pthread_mutex_lock(@FMutex);
  try
    // 增加代数，让所有等待者检测到变化
    Inc(FGeneration);
    pthread_cond_broadcast(@FCond);
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TNotifyUnix.GetWaiterCount: Integer;
begin
  Result := atomic_load(FWaiterCount, mo_relaxed);
end;

function TNotifyUnix.GetData: Pointer;
begin
  Result := FData;
end;

procedure TNotifyUnix.SetData(AData: Pointer);
begin
  FData := AData;
end;

function MakeNotifyUnix: INotify;
begin
  Result := TNotifyUnix.Create;
end;

{$ENDIF}

end.
