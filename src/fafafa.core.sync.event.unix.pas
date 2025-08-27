unit fafafa.core.sync.event.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  {$IFDEF HAS_CLOCK_GETTIME}cthreads,{$ENDIF}
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.event.base;

type
  { TEvent
    Unix 平台基于 pthread_mutex + pthread_cond 的事件实现：
    - 自动/手动重置语义在本层通过 FSignaled + 条件变量实现
    - 为对齐 Windows 语义：
        * 手动重置：IsSignaled 非破坏式返回 FSignaled
        * 自动重置：IsSignaled 固定返回 False（请使用 WaitFor(0) 探测） }
  TEvent = class(TInterfacedObject, IEvent)
  private
    FMutex: pthread_mutex_t;
    FCond: pthread_cond_t;
    FSignaled: Boolean;
    FManualReset: Boolean;
  public
    constructor Create(AManualReset: Boolean = False; AInitialState: Boolean = False);
    destructor Destroy; override;
    // IEvent
    procedure SetEvent;
    procedure ResetEvent;
    function WaitFor: TWaitResult; overload;
    function WaitFor(ATimeoutMs: Cardinal): TWaitResult; overload;
    function IsSignaled: Boolean;
    // ILock
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean;
  end;

implementation

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
    raise ELockError.Create('event: lock failed');
  try
    FSignaled := True;
    if FManualReset then
      pthread_cond_broadcast(@FCond)
    else
      pthread_cond_signal(@FCond);
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

procedure TEvent.ResetEvent;
begin
  if pthread_mutex_lock(@FMutex) <> 0 then
    raise ELockError.Create('event: lock failed');
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
  tv: TTimeVal;
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
      // 暂时回退到 gettimeofday (REALTIME) - CLOCK_MONOTONIC 需要额外配置
      if fpgettimeofday(@tv, nil) <> 0 then
        Exit(wrError);
      ts.tv_sec := tv.tv_sec + (ATimeoutMs div 1000);
      ts.tv_nsec := (tv.tv_usec * 1000) + (ATimeoutMs mod 1000) * 1000000;
      if ts.tv_nsec >= 1000000000 then
      begin
        Inc(ts.tv_sec, ts.tv_nsec div 1000000000);
        ts.tv_nsec := ts.tv_nsec mod 1000000000;
      end;
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

function TEvent.IsSignaled: Boolean;
begin
  if pthread_mutex_lock(@FMutex) <> 0 then
    Exit(False);
  try
    if FManualReset then
      Result := FSignaled
    else
      Result := False; // 与 Windows 语义对齐：自动重置不提供非破坏式 IsSignaled
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

procedure TEvent.Acquire;
begin
  if WaitFor(High(Cardinal)) <> wrSignaled then
    raise ELockError.Create('Event acquire (wait) failed');
end;

procedure TEvent.Release;
begin
  // Event 不是互斥量，Release 不应改变状态；使用 ResetEvent 控制手动重置
end;

function TEvent.TryAcquire: Boolean;
begin
  Result := WaitFor(0) = wrSignaled;
end;

end.

