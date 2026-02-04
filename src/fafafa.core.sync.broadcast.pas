unit fafafa.core.sync.broadcast;

{$mode objfpc}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  TBroadcast<T> - 广播通道（多消费者发布-订阅）

  参照 Rust tokio::sync::broadcast 设计：
  - 发送者发送消息，所有接收者都能收到
  - 支持多个接收者同时订阅
  - 使用环形缓冲区存储历史消息
  - 新订阅者可以选择从最新消息开始或从头开始

  使用示例：
    var
      BC: TBroadcastInt;
      Rx1, Rx2: TBroadcastInt.PReceiver;
      Msg: Integer;
    begin
      BC.Init(16);  // 缓冲区容量 16
      Rx1 := BC.Subscribe;
      Rx2 := BC.Subscribe;

      BC.Send(42);

      if BC.TryRecvFrom(Rx1, Msg) then WriteLn('Rx1: ', Msg);
      if BC.TryRecvFrom(Rx2, Msg) then WriteLn('Rx2: ', Msg);

      BC.Unsubscribe(Rx1);
      BC.Unsubscribe(Rx2);
      BC.Done;
    end;

  适用场景：
  - 事件总线
  - 配置变更通知
  - 日志分发
  - 实时数据推送
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
  CLOCK_REALTIME = 0;

function clock_gettime(clk_id: cint; tp: PTimeSpec): cint; cdecl; external 'rt';
{$ENDIF}

type

  { TBroadcast<T> - 广播发送者 }

  generic TBroadcast<T> = record
  public type
    PT = ^T;

    { TReceiverState - 接收者状态（分配在堆上） }
    TReceiverState = record
      ReadPos: Int64;       // 本接收者的读取位置
      Active: Boolean;      // 是否活跃
    end;
    PReceiver = ^TReceiverState;

  private
    FBuffer: array of T;
    FCapacity: Integer;
    FHead: Int64;          // 最旧消息的位置
    FTail: Int64;          // 下一个写入位置
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
    {** 初始化广播通道
        @param ACapacity 缓冲区容量（历史消息数） *}
    procedure Init(ACapacity: Integer = 16);

    {** 释放资源 *}
    procedure Done;

    {** 创建新的接收者
        @param AFromLatest 是否从最新消息开始（默认 True）
        @return 接收者句柄（需要调用 Unsubscribe 释放） *}
    function Subscribe(AFromLatest: Boolean = True): PReceiver;

    {** 取消订阅并释放接收者 *}
    procedure Unsubscribe(AReceiver: PReceiver);

    {** 尝试从接收者接收消息（非阻塞）
        @return 如果有新消息返回 True *}
    function TryRecvFrom(AReceiver: PReceiver; out AValue: T): Boolean;

    {** 从接收者接收消息（阻塞）*}
    function RecvFrom(AReceiver: PReceiver): T;

    {** 带超时从接收者接收
        @return 如果成功接收返回 True *}
    function RecvFromTimeout(AReceiver: PReceiver; ATimeoutMs: Cardinal; out AValue: T): Boolean;

    {** 检查接收者是否有待接收的消息 *}
    function HasPending(AReceiver: PReceiver): Boolean;

    {** 获取接收者滞后的消息数 *}
    function GetLag(AReceiver: PReceiver): Int64;

    {** 发送消息给所有接收者 *}
    procedure Send(const AValue: T);

    {** 关闭通道（所有接收者将收到关闭信号） *}
    procedure Close;

    {** 检查通道是否已关闭 *}
    function IsClosed: Boolean;

    {** 获取当前缓冲区中的消息数 *}
    function GetBufferedCount: Integer;

    {** 获取容量 *}
    property Capacity: Integer read FCapacity;
  end;

  { 常用类型特化 }
  TBroadcastInt = specialize TBroadcast<Integer>;
  TBroadcastStr = specialize TBroadcast<string>;
  TBroadcastPtr = specialize TBroadcast<Pointer>;

implementation

{ TBroadcast<T> }

procedure TBroadcast.Lock;
begin
  {$IFDEF UNIX}
  pthread_mutex_lock(@FMutex);
  {$ENDIF}
  {$IFDEF WINDOWS}
  EnterCriticalSection(FCS);
  {$ENDIF}
end;

procedure TBroadcast.Unlock;
begin
  {$IFDEF UNIX}
  pthread_mutex_unlock(@FMutex);
  {$ENDIF}
  {$IFDEF WINDOWS}
  LeaveCriticalSection(FCS);
  {$ENDIF}
end;

procedure TBroadcast.NotifyAll;
begin
  {$IFDEF UNIX}
  pthread_cond_broadcast(@FCond);
  {$ENDIF}
  {$IFDEF WINDOWS}
  WakeAllConditionVariable(FCondVar);
  {$ENDIF}
end;

procedure TBroadcast.WaitCond;
begin
  {$IFDEF UNIX}
  pthread_cond_wait(@FCond, @FMutex);
  {$ENDIF}
  {$IFDEF WINDOWS}
  SleepConditionVariableCS(FCondVar, FCS, INFINITE);
  {$ENDIF}
end;

function TBroadcast.WaitCondTimeout(ATimeoutMs: Cardinal): Boolean;
{$IFDEF UNIX}
var
  AbsTime: timespec;
  Now: timespec;
  Rc: Integer;
{$ENDIF}
begin
  {$IFDEF UNIX}
  clock_gettime(CLOCK_REALTIME, @Now);
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

procedure TBroadcast.Init(ACapacity: Integer);
begin
  if FInitialized then
    Exit;

  if ACapacity < 1 then
    ACapacity := 16;

  FCapacity := ACapacity;
  SetLength(FBuffer, ACapacity);
  FHead := 0;
  FTail := 0;
  FClosed := 0;
  FInitialized := True;

  {$IFDEF UNIX}
  if pthread_mutex_init(@FMutex, nil) <> 0 then
    raise Exception.Create('Broadcast: failed to initialize mutex');
  if pthread_cond_init(@FCond, nil) <> 0 then
  begin
    pthread_mutex_destroy(@FMutex);
    raise Exception.Create('Broadcast: failed to initialize condition');
  end;
  {$ENDIF}
  {$IFDEF WINDOWS}
  InitializeCriticalSection(FCS);
  InitializeConditionVariable(FCondVar);
  {$ENDIF}
end;

procedure TBroadcast.Done;
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

  SetLength(FBuffer, 0);
  FInitialized := False;
end;

function TBroadcast.Subscribe(AFromLatest: Boolean): PReceiver;
begin
  New(Result);
  Lock;
  try
    if AFromLatest then
      Result^.ReadPos := FTail
    else
      Result^.ReadPos := FHead;
    Result^.Active := True;
  finally
    Unlock;
  end;
end;

procedure TBroadcast.Unsubscribe(AReceiver: PReceiver);
begin
  if AReceiver <> nil then
  begin
    AReceiver^.Active := False;
    Dispose(AReceiver);
  end;
end;

function TBroadcast.TryRecvFrom(AReceiver: PReceiver; out AValue: T): Boolean;
var
  Idx: Integer;
begin
  Result := False;
  if (AReceiver = nil) or (not AReceiver^.Active) then
    Exit;

  Lock;
  try
    // 如果读取位置落后于 head，说明有消息被覆盖，跳到 head
    if AReceiver^.ReadPos < FHead then
      AReceiver^.ReadPos := FHead;

    if AReceiver^.ReadPos < FTail then
    begin
      Idx := Integer(AReceiver^.ReadPos mod FCapacity);
      AValue := FBuffer[Idx];
      Inc(AReceiver^.ReadPos);
      Result := True;
    end;
  finally
    Unlock;
  end;
end;

function TBroadcast.RecvFrom(AReceiver: PReceiver): T;
var
  Idx: Integer;
begin
  if (AReceiver = nil) or (not AReceiver^.Active) then
    raise Exception.Create('Invalid receiver');

  Lock;
  try
    while True do
    begin
      // 检查关闭
      if FClosed <> 0 then
        raise Exception.Create('Broadcast channel closed');

      if AReceiver^.ReadPos < FHead then
        AReceiver^.ReadPos := FHead;

      if AReceiver^.ReadPos < FTail then
      begin
        Idx := Integer(AReceiver^.ReadPos mod FCapacity);
        Result := FBuffer[Idx];
        Inc(AReceiver^.ReadPos);
        Exit;
      end;

      // 等待新消息
      WaitCond;
    end;
  finally
    Unlock;
  end;
end;

function TBroadcast.RecvFromTimeout(AReceiver: PReceiver; ATimeoutMs: Cardinal; out AValue: T): Boolean;
var
  Idx: Integer;
begin
  Result := False;
  if (AReceiver = nil) or (not AReceiver^.Active) then
    Exit;

  Lock;
  try
    while True do
    begin
      if FClosed <> 0 then
        Exit(False);

      if AReceiver^.ReadPos < FHead then
        AReceiver^.ReadPos := FHead;

      if AReceiver^.ReadPos < FTail then
      begin
        Idx := Integer(AReceiver^.ReadPos mod FCapacity);
        AValue := FBuffer[Idx];
        Inc(AReceiver^.ReadPos);
        Exit(True);
      end;

      if not WaitCondTimeout(ATimeoutMs) then
        Exit(False);
    end;
  finally
    Unlock;
  end;
end;

function TBroadcast.HasPending(AReceiver: PReceiver): Boolean;
begin
  if (AReceiver = nil) or (not AReceiver^.Active) then
    Exit(False);

  Lock;
  try
    if AReceiver^.ReadPos < FHead then
      AReceiver^.ReadPos := FHead;
    Result := AReceiver^.ReadPos < FTail;
  finally
    Unlock;
  end;
end;

function TBroadcast.GetLag(AReceiver: PReceiver): Int64;
begin
  if (AReceiver = nil) or (not AReceiver^.Active) then
    Exit(0);

  Lock;
  try
    Result := FTail - AReceiver^.ReadPos;
    if Result < 0 then
      Result := 0;
  finally
    Unlock;
  end;
end;

procedure TBroadcast.Send(const AValue: T);
var
  Idx: Integer;
begin
  if FClosed <> 0 then
    raise Exception.Create('Cannot send on closed broadcast channel');

  Lock;
  try
    Idx := Integer(FTail mod FCapacity);
    FBuffer[Idx] := AValue;
    Inc(FTail);

    // 如果缓冲区满了，推进 head
    if FTail - FHead > FCapacity then
      FHead := FTail - FCapacity;

    NotifyAll;
  finally
    Unlock;
  end;
end;

procedure TBroadcast.Close;
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

function TBroadcast.IsClosed: Boolean;
begin
  Result := atomic_load(FClosed, mo_acquire) <> 0;
end;

function TBroadcast.GetBufferedCount: Integer;
begin
  Lock;
  try
    Result := Integer(FTail - FHead);
    if Result < 0 then
      Result := 0;
  finally
    Unlock;
  end;
end;

end.
