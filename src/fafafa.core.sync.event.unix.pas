unit fafafa.core.sync.event.unix;

{
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│          ______   ______     ______   ______     ______   ______             │
│         /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \            │
│         \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \           │
│          \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\          │
│           \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/          │
│                                                                              │
│                                Studio                                        │
└──────────────────────────────────────────────────────────────────────────────┘

📦 项目：fafafa.core.sync.event - 高性能事件同步原语实现

📖 概述：
  现代化、跨平台的 FreePascal 事件同步原语实现（Unix 平台）。

🔧 特性：
  • 跨平台支持：Windows、Linux、macOS、FreeBSD 等
  • 高性能实现：基于 pthread_mutex + pthread_cond 的高效实现
  • 线程安全：完全线程安全的事件同步机制
  • 双模式支持：自动重置和手动重置事件
  • 超时控制：支持无限等待和带超时的等待
  • 非阻塞检查：TryWait 方法提供非阻塞状态检查
  • 资源管理：自动资源清理，异常安全

⚠️  重要说明：
  本文件为 Unix 平台的具体实现，使用 POSIX 线程库。
  自动重置事件一次信号只唤醒一个等待者，手动重置事件唤醒所有等待者。

🧵 线程安全性：
  所有事件操作都是线程安全的，可以从多个线程同时调用。

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731

}

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  {$IFDEF HAS_CLOCK_GETTIME}cthreads,{$ENDIF}
  fafafa.core.sync.base, fafafa.core.sync.event.base;

const
  ESysEINTR = 4;      // 信号中断
  ESysETIMEDOUT = 110; // 超时

type
  { TEvent
    Unix 平台基于 pthread_mutex + pthread_cond 的事件实现：
    - 自动/手动重置语义在本层通过 FSignaled + 条件变量实现
    - 使用 TryWait 进行非阻塞探测 }
  TEvent = class(TSynchronizable, IEvent)
  private
    FMutex: pthread_mutex_t;
    FCond: pthread_cond_t;
    FSignaled: Boolean;
    FManualReset: Boolean;
  public
    constructor Create(AManualReset: Boolean = False; AInitialState: Boolean = False);
    destructor Destroy; override;

    // IEvent - 基础操作
    procedure SetEvent;
    procedure ResetEvent;
    function WaitFor: TWaitResult; overload;
    function WaitFor(ATimeoutMs: Cardinal): TWaitResult; overload;

    // IEvent - 扩展操作
    function TryWait: Boolean;
    function IsManualReset: Boolean;

  end;

implementation

{ 辅助函数：获取当前时间并添加超时 }
function GetTimeoutTimespec(ATimeoutMs: Cardinal): timespec;
var
  tv: timeval;
begin
  // 获取当前时间
  FpGetTimeOfDay(@tv, nil);

  // 转换为 timespec 并添加超时
  Result.tv_sec := tv.tv_sec + (ATimeoutMs div 1000);
  Result.tv_nsec := (tv.tv_usec * 1000) + ((ATimeoutMs mod 1000) * 1000000);

  // 处理纳秒溢出
  if Result.tv_nsec >= 1000000000 then
  begin
    Inc(Result.tv_sec);
    Dec(Result.tv_nsec, 1000000000);
  end;
end;

{ TEvent }

constructor TEvent.Create(AManualReset: Boolean; AInitialState: Boolean);
begin
  inherited Create;

  if pthread_mutex_init(@FMutex, nil) <> 0 then
    raise ELockError.Create('event: mutex init failed');

  if pthread_cond_init(@FCond, nil) <> 0 then
  begin
    pthread_mutex_destroy(@FMutex);
    raise ELockError.Create('event: cond init failed');
  end;

  FManualReset := AManualReset;
  FSignaled := AInitialState;
end;

destructor TEvent.Destroy;
begin
  pthread_cond_destroy(@FCond);
  pthread_mutex_destroy(@FMutex);
  inherited Destroy;
end;

procedure TEvent.SetEvent;
begin
  if pthread_mutex_lock(@FMutex) <> 0 then
    raise ELockError.Create('event: mutex lock failed');

  try
    if not FSignaled then
    begin
      FSignaled := True;
      if FManualReset then
        pthread_cond_broadcast(@FCond)  // 唤醒所有等待线程
      else
        pthread_cond_signal(@FCond);    // 只唤醒一个等待线程
    end;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

procedure TEvent.ResetEvent;
begin
  if pthread_mutex_lock(@FMutex) <> 0 then
    raise ELockError.Create('event: mutex lock failed');

  try
    FSignaled := False;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TEvent.WaitFor: TWaitResult;
begin
  Result := WaitFor(High(Cardinal));
end;

function TEvent.WaitFor(ATimeoutMs: Cardinal): TWaitResult;
var
  ts: timespec;
  rc: Integer;
begin
  if pthread_mutex_lock(@FMutex) <> 0 then
    Exit(wrError);

  try
    if ATimeoutMs = 0 then
    begin
      if FSignaled then
      begin
        if not FManualReset then
          FSignaled := False;
        Exit(wrSignaled);
      end
      else
        Exit(wrTimeout);
    end
    else if ATimeoutMs = High(Cardinal) then
    begin
      while not FSignaled do
        pthread_cond_wait(@FCond, @FMutex);
      if not FManualReset then
        FSignaled := False;
      Exit(wrSignaled);
    end
    else
    begin
      ts := GetTimeoutTimespec(ATimeoutMs);

      while not FSignaled do
      begin
        rc := pthread_cond_timedwait(@FCond, @FMutex, @ts);
        if rc = ESysETIMEDOUT then
          Exit(wrTimeout)
        else if rc <> 0 then
          Exit(wrError);
      end;
      if not FManualReset then
        FSignaled := False;
      Exit(wrSignaled);
    end;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;



function TEvent.TryWait: Boolean;
begin
  Result := WaitFor(0) = wrSignaled;
end;

function TEvent.IsManualReset: Boolean;
begin
  Result := FManualReset;
end;

end.