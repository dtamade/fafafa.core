unit fafafa.core.sync.waitgroup.unix;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  Unix/Linux 平台 WaitGroup 实现

  实现策略：
  - 原子计数器存储当前等待数量
  - pthread_mutex_t + pthread_cond_t 进行等待/唤醒
  - 当计数变为 0 时广播唤醒所有等待者

  性能特性：
  - Add/Done: 原子操作 + 条件判断
  - Wait: 快速路径检查 + 慢速路径阻塞
  - 低竞争场景几乎无开销
}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.sync.base, fafafa.core.sync.waitgroup.base,
  fafafa.core.time.duration, fafafa.core.sync.timespec;

type
  TWaitGroup = class(TSynchronizable, IWaitGroup)
  private
    FCount: LongInt;                    // 原子计数器
    FMutex: pthread_mutex_t;            // 保护条件变量
    FCond: pthread_cond_t;              // 用于等待/通知
    FLastError: TWaitError;

    procedure CheckNonNegative(ANewCount: LongInt);
  public
    constructor Create;
    destructor Destroy; override;

    // ISynchronizable
    function GetLastError: TWaitError;

    // IWaitGroup
    procedure Add(ADelta: Integer);
    procedure Done;
    procedure Wait;
    function WaitTimeout(ATimeoutMs: Cardinal): Boolean;
    function WaitDuration(const ADuration: TDuration): TWaitResult;
    function GetCount: Integer;
  end;

function MakeWaitGroup: IWaitGroup;

implementation

resourcestring
  rsWaitGroupNegativeCount = 'WaitGroup: negative count';
  rsWaitGroupInitFailed = 'WaitGroup: failed to initialize';

{ TWaitGroup }

constructor TWaitGroup.Create;
begin
  inherited Create;
  FCount := 0;
  FLastError := weNone;

  // 初始化互斥锁
  if pthread_mutex_init(@FMutex, nil) <> 0 then
    raise ELockError.Create(rsWaitGroupInitFailed);

  // 初始化条件变量
  if pthread_cond_init(@FCond, nil) <> 0 then
  begin
    pthread_mutex_destroy(@FMutex);
    raise ELockError.Create(rsWaitGroupInitFailed);
  end;
end;

destructor TWaitGroup.Destroy;
begin
  pthread_cond_destroy(@FCond);
  pthread_mutex_destroy(@FMutex);
  inherited Destroy;
end;

function TWaitGroup.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

procedure TWaitGroup.CheckNonNegative(ANewCount: LongInt);
begin
  if ANewCount < 0 then
    raise EInvalidArgument.Create(rsWaitGroupNegativeCount);
end;

procedure TWaitGroup.Add(ADelta: Integer);
var
  NewCount: LongInt;
begin
  pthread_mutex_lock(@FMutex);
  try
    NewCount := FCount + ADelta;
    CheckNonNegative(NewCount);
    FCount := NewCount;

    // 如果计数变为 0，唤醒所有等待者
    if FCount = 0 then
      pthread_cond_broadcast(@FCond);
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

procedure TWaitGroup.Done;
begin
  Add(-1);
end;

procedure TWaitGroup.Wait;
begin
  pthread_mutex_lock(@FMutex);
  try
    // 等待直到计数为 0
    while FCount > 0 do
      pthread_cond_wait(@FCond, @FMutex);
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TWaitGroup.WaitTimeout(ATimeoutMs: Cardinal): Boolean;
var
  AbsTime: TTimeSpec;
  rc: cint;
begin
  // 快速路径：计数已为 0
  pthread_mutex_lock(@FMutex);
  try
    if FCount = 0 then
      Exit(True);

    // 使用 timespec.pas 共享函数计算绝对超时时间
    AbsTime := TimeoutToTimespec(ATimeoutMs);

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

function TWaitGroup.GetCount: Integer;
begin
  // 原子读取（在 x86/x64 上对齐的 32 位读取是原子的）
  Result := FCount;
end;

function TWaitGroup.WaitDuration(const ADuration: TDuration): TWaitResult;
var
  TimeoutMs: Int64;
begin
  // 将 TDuration 转换为毫秒
  TimeoutMs := ADuration.AsMs;
  if TimeoutMs < 0 then
    TimeoutMs := 0;

  if WaitTimeout(Cardinal(TimeoutMs)) then
    Result := wrSignaled
  else
    Result := wrTimeout;
end;

function MakeWaitGroup: IWaitGroup;
begin
  Result := TWaitGroup.Create;
end;

end.
