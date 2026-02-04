unit fafafa.core.sync.watch;

{$mode objfpc}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  TWatch<T> - 监视通道（单生产者多消费者值广播）

  参照 Rust tokio::sync::watch 设计：
  - 只保存最新值，新订阅者立即看到当前值
  - 发送者更新值，所有接收者被通知
  - 接收者可以等待值变化
  - 与 broadcast 不同，不保留历史，只关注最新状态

  使用示例：
    var
      W: TWatchInt;
      Rx1, Rx2: TWatchInt.PReceiver;
      Val: Integer;
    begin
      W.Init(0);  // 初始值 0
      Rx1 := W.Subscribe;
      Rx2 := W.Subscribe;

      W.Send(42);

      if W.HasChanged(Rx1) then
      begin
        Val := W.Borrow(Rx1);
        WriteLn('Rx1 new value: ', Val);
      end;

      W.Unsubscribe(Rx1);
      W.Unsubscribe(Rx2);
      W.Done;
    end;

  适用场景：
  - 配置值监视
  - 状态变更通知
  - 心跳/健康检查
  - 全局标志传播
}

interface

uses
  SysUtils, Classes,
  {$IFDEF UNIX}
  BaseUnix, Unix, UnixType, pthreads,
  {$ENDIF}
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  fafafa.core.atomic;

{$IFDEF UNIX}
const
  WATCH_CLOCK_REALTIME = 0;

function watch_clock_gettime(clk_id: cint; tp: PTimeSpec): cint; cdecl; external 'rt' name 'clock_gettime';
{$ENDIF}

type

  { TWatch<T> - 监视通道发送者 }

  generic TWatch<T> = record
  public type
    PT = ^T;

    { TReceiverState - 接收者状态 }
    TReceiverState = record
      Version: Int64;       // 上次看到的版本
      Active: Boolean;
    end;
    PReceiver = ^TReceiverState;

  private
    FValue: T;
    FVersion: Int64;        // 值的版本号
    {$IFDEF UNIX}
    FMutex: pthread_mutex_t;
    FCond: pthread_cond_t;
    {$ENDIF}
    {$IFDEF WINDOWS}
    FCS: TRTLCriticalSection;
    FCondVar: TRTLConditionVariable;
    {$ENDIF}
    FClosed: Int32;
    FInitialized: Boolean;

    procedure Lock; inline;
    procedure Unlock; inline;
    procedure NotifyAll; inline;
    procedure WaitCond; inline;
    function WaitCondTimeout(ATimeoutMs: Cardinal): Boolean; inline;
  public
    {** 初始化监视通道
        @param AInitialValue 初始值 *}
    procedure Init(const AInitialValue: T);

    {** 释放资源 *}
    procedure Done;

    {** 创建新的接收者 *}
    function Subscribe: PReceiver;

    {** 取消订阅 *}
    procedure Unsubscribe(AReceiver: PReceiver);

    {** 发送新值（更新值并通知所有接收者） *}
    procedure Send(const AValue: T);

    {** 借用当前值（标记为已读）
        @return 当前值 *}
    function Borrow(AReceiver: PReceiver): T;

    {** 检查值是否已变化（自上次 Borrow 以来） *}
    function HasChanged(AReceiver: PReceiver): Boolean;

    {** 等待值变化 *}
    procedure WaitForChange(AReceiver: PReceiver);

    {** 等待值变化（带超时）
        @return True 如果值已变化，False 如果超时 *}
    function WaitForChangeTimeout(AReceiver: PReceiver; ATimeoutMs: Cardinal): Boolean;

    {** 获取当前值（不改变接收者状态） *}
    function Get: T;

    {** 关闭通道 *}
    procedure Close;

    {** 检查是否已关闭 *}
    function IsClosed: Boolean;

    {** 获取当前版本号 *}
    function GetVersion: Int64;
  end;

  { 常用类型特化 }
  TWatchInt = specialize TWatch<Integer>;
  TWatchStr = specialize TWatch<string>;
  TWatchPtr = specialize TWatch<Pointer>;
  TWatchBool = specialize TWatch<Boolean>;

implementation

{ TWatch<T> }

procedure TWatch.Lock;
begin
  {$IFDEF UNIX}
  pthread_mutex_lock(@FMutex);
  {$ENDIF}
  {$IFDEF WINDOWS}
  EnterCriticalSection(FCS);
  {$ENDIF}
end;

procedure TWatch.Unlock;
begin
  {$IFDEF UNIX}
  pthread_mutex_unlock(@FMutex);
  {$ENDIF}
  {$IFDEF WINDOWS}
  LeaveCriticalSection(FCS);
  {$ENDIF}
end;

procedure TWatch.NotifyAll;
begin
  {$IFDEF UNIX}
  pthread_cond_broadcast(@FCond);
  {$ENDIF}
  {$IFDEF WINDOWS}
  WakeAllConditionVariable(FCondVar);
  {$ENDIF}
end;

procedure TWatch.WaitCond;
begin
  {$IFDEF UNIX}
  pthread_cond_wait(@FCond, @FMutex);
  {$ENDIF}
  {$IFDEF WINDOWS}
  SleepConditionVariableCS(FCondVar, FCS, INFINITE);
  {$ENDIF}
end;

function TWatch.WaitCondTimeout(ATimeoutMs: Cardinal): Boolean;
{$IFDEF UNIX}
var
  AbsTime: timespec;
  Now: timespec;
  Rc: Integer;
{$ENDIF}
begin
  {$IFDEF UNIX}
  watch_clock_gettime(WATCH_CLOCK_REALTIME, @Now);
  AbsTime.tv_sec := Now.tv_sec + (ATimeoutMs div 1000);
  AbsTime.tv_nsec := Now.tv_nsec + ((ATimeoutMs mod 1000) * 1000000);
  if AbsTime.tv_nsec >= 1000000000 then
  begin
    Inc(AbsTime.tv_sec);
    Dec(AbsTime.tv_nsec, 1000000000);
  end;
  Rc := pthread_cond_timedwait(@FCond, @FMutex, @AbsTime);
  Result := Rc <> ESysETIMEDOUT;
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := SleepConditionVariableCS(FCondVar, FCS, ATimeoutMs);
  {$ENDIF}
end;

procedure TWatch.Init(const AInitialValue: T);
begin
  if FInitialized then
    Exit;

  FValue := AInitialValue;
  FVersion := 1;  // 从 1 开始，0 表示未初始化
  FClosed := 0;
  FInitialized := True;

  {$IFDEF UNIX}
  if pthread_mutex_init(@FMutex, nil) <> 0 then
    raise Exception.Create('Watch: failed to initialize mutex');
  if pthread_cond_init(@FCond, nil) <> 0 then
  begin
    pthread_mutex_destroy(@FMutex);
    raise Exception.Create('Watch: failed to initialize condition');
  end;
  {$ENDIF}
  {$IFDEF WINDOWS}
  InitializeCriticalSection(FCS);
  InitializeConditionVariable(FCondVar);
  {$ENDIF}
end;

procedure TWatch.Done;
begin
  if not FInitialized then
    Exit;

  Close;

  {$IFDEF UNIX}
  pthread_cond_destroy(@FCond);
  pthread_mutex_destroy(@FMutex);
  {$ENDIF}
  {$IFDEF WINDOWS}
  DeleteCriticalSection(FCS);
  {$ENDIF}

  FInitialized := False;
end;

function TWatch.Subscribe: PReceiver;
begin
  New(Result);
  Lock;
  try
    Result^.Version := FVersion;  // 初始化为当前版本（第一次 Borrow 不会触发变化）
    Result^.Active := True;
  finally
    Unlock;
  end;
end;

procedure TWatch.Unsubscribe(AReceiver: PReceiver);
begin
  if AReceiver <> nil then
  begin
    AReceiver^.Active := False;
    Dispose(AReceiver);
  end;
end;

procedure TWatch.Send(const AValue: T);
begin
  if FClosed <> 0 then
    raise Exception.Create('Cannot send on closed watch channel');

  Lock;
  try
    FValue := AValue;
    Inc(FVersion);
    NotifyAll;
  finally
    Unlock;
  end;
end;

function TWatch.Borrow(AReceiver: PReceiver): T;
begin
  if (AReceiver = nil) or (not AReceiver^.Active) then
    raise Exception.Create('Invalid receiver');

  Lock;
  try
    Result := FValue;
    AReceiver^.Version := FVersion;  // 标记为已读
  finally
    Unlock;
  end;
end;

function TWatch.HasChanged(AReceiver: PReceiver): Boolean;
begin
  if (AReceiver = nil) or (not AReceiver^.Active) then
    Exit(False);

  Lock;
  try
    Result := AReceiver^.Version < FVersion;
  finally
    Unlock;
  end;
end;

procedure TWatch.WaitForChange(AReceiver: PReceiver);
begin
  if (AReceiver = nil) or (not AReceiver^.Active) then
    raise Exception.Create('Invalid receiver');

  Lock;
  try
    while (AReceiver^.Version >= FVersion) and (FClosed = 0) do
      WaitCond;

    if FClosed <> 0 then
      raise Exception.Create('Watch channel closed');
  finally
    Unlock;
  end;
end;

function TWatch.WaitForChangeTimeout(AReceiver: PReceiver; ATimeoutMs: Cardinal): Boolean;
begin
  Result := False;
  if (AReceiver = nil) or (not AReceiver^.Active) then
    Exit;

  Lock;
  try
    while (AReceiver^.Version >= FVersion) and (FClosed = 0) do
    begin
      if not WaitCondTimeout(ATimeoutMs) then
        Exit(False);
    end;

    Result := AReceiver^.Version < FVersion;
  finally
    Unlock;
  end;
end;

function TWatch.Get: T;
begin
  Lock;
  try
    Result := FValue;
  finally
    Unlock;
  end;
end;

procedure TWatch.Close;
begin
  if atomic_exchange(FClosed, 1, mo_acq_rel) = 0 then
  begin
    Lock;
    try
      NotifyAll;
    finally
      Unlock;
    end;
  end;
end;

function TWatch.IsClosed: Boolean;
begin
  Result := atomic_load(FClosed, mo_acquire) <> 0;
end;

function TWatch.GetVersion: Int64;
begin
  Result := atomic_load(FVersion, mo_acquire);
end;

end.
