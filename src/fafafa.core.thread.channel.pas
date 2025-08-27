unit fafafa.core.thread.channel;

{**
 * fafafa.core.thread.channel - 线程间通信通道模块
 *
 * @desc 提供 Rust 启发的线程间通信机制，包括：
 *       - IChannel 接口：通道通信的标准接口
 *       - TChannel 类：高性能的通道实现
 *       - 支持有缓冲和无缓冲通道
 *       - 线程安全的发送和接收操作
 *       - 实现"通过通信来共享内存"的理念
 *
 * @author fafafa.core 开发团队
 * @version 1.0.0
 * @since 2025-08-08
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.sync,
  fafafa.core.thread.debuglog,
  fafafa.core.thread.constants,
  fafafa.core.collections.vecdeque;

type

  {**
   * IChannel
   *
   * @desc 通道接口 - Rust 启发的线程间通信机制
   *       实现"不要通过共享内存来通信，而要通过通信来共享内存"的理念
   *}
  IChannel = interface
    ['{D3E4F5A6-B7C8-9D0E-1F2A-B3C4D5E6F7A8}']

    {**
     * Send
     *
     * @desc 发送数据到通道（可能阻塞）
     *
     * @params
     *    AValue: Pointer 要发送的数据指针
     *
     * @return 发送成功返回 True，通道已关闭返回 False
     *}
    function Send(AValue: Pointer): Boolean;

    {**
     * Recv
     *
     * @desc 从通道接收数据（阻塞直到有数据或通道关闭）
     *
     * @params
     *    AValue: Pointer 输出参数，接收到的数据
     *
     * @return 接收成功返回 True，通道已关闭返回 False
     *}
    function Recv(out AValue: Pointer): Boolean;

    {**
     * TryRecv
     *
     * @desc 尝试从通道接收数据（非阻塞）
     *
     * @params
     *    AValue: Pointer 输出参数，接收到的数据
     *
     * @return 接收成功返回 True，无数据或通道关闭返回 False
     *}
    function TryRecv(out AValue: Pointer): Boolean;

    {**
     * RecvTimeout
     *
     * @desc 在指定时间内从通道接收数据
     *
     * @params
     *    AValue: Pointer 输出参数，接收到的数据
     *    ATimeoutMs: Cardinal 超时时间（毫秒）
     *
     * @return 接收成功返回 True，超时或通道关闭返回 False
     *}
    function RecvTimeout(out AValue: Pointer; ATimeoutMs: Cardinal): Boolean;

    {**
     * SendTimeout
     *
     * @desc 在指定时间内发送数据（容量>0 等待空位；容量=0 等待接收方配对）
     *
     * @params
     *    AValue: Pointer 要发送的数据指针
     *    ATimeoutMs: Cardinal 超时时间（毫秒）
     *
     * @return 发送成功返回 True，超时或通道关闭返回 False
     *}
    function SendTimeout(AValue: Pointer; ATimeoutMs: Cardinal): Boolean;

    {**
     * Close
     *
     * @desc 关闭通道，唤醒所有等待的接收者
     *}
    procedure Close;

    {**
     * IsClosed
     *
     * @desc 检查通道是否已关闭
     *
     * @return 已关闭返回 True，否则返回 False
     *}
    function IsClosed: Boolean;

    // 属性访问器
    property Closed: Boolean read IsClosed;
  end;

  {**
   * TChannel
   *
   * @desc 通道实现类 - Rust 启发的线程间通信
   *       基于队列和事件的高效通信机制
   *}
  TChannel = class(TInterfacedObject, IChannel)
  private
    FQueue: specialize TVecDeque<Pointer>;
    FCapacity: Integer;
    FClosed: Boolean;
    FLock: ILock;
    FDataAvailableEvent: IEvent;
    FSpaceAvailableEvent: IEvent;
    // 等待队列（仅用于容量=0的公平配对）
    FRecvWaiters: specialize TVecDeque<Pointer>;
    FSendWaiters: specialize TVecDeque<Pointer>;

  public
    constructor Create(ACapacity: Integer = 0);
    destructor Destroy; override;

    function Send(AValue: Pointer): Boolean;
    function Recv(out AValue: Pointer): Boolean;
    function TryRecv(out AValue: Pointer): Boolean;
    function RecvTimeout(out AValue: Pointer; ATimeoutMs: Cardinal): Boolean;
    function SendTimeout(AValue: Pointer; ATimeoutMs: Cardinal): Boolean;
    procedure Close;
    function IsClosed: Boolean;
  end;

implementation

type
  PSender = ^TSender;
  TSender = record
    Event: IEvent;
    Value: Pointer;
    Success: PBoolean;
  end;
  PReceiver = ^TReceiver;
  TReceiver = record
    Event: IEvent;
    Value: Pointer;    // 发送方写入的值
    Success: PBoolean; // 配对结果
  end;

{ TChannel }

constructor TChannel.Create(ACapacity: Integer = 0);
begin
  inherited Create;

  // 首先初始化关键字段，确保析构函数安全
  FClosed := False;
  FQueue := nil;
  FLock := nil;
  FDataAvailableEvent := nil;
  FSpaceAvailableEvent := nil;

  if ACapacity < 0 then
    raise EInvalidArgument.Create('通道容量不能为负数');

  FCapacity := ACapacity;
  FQueue := specialize TVecDeque<Pointer>.Create;
  FLock := TMutex.Create;
  FDataAvailableEvent := TEvent.Create(False, False); // AutoReset=True, InitialState=False
  FSpaceAvailableEvent := TEvent.Create(False, False); // AutoReset=True, InitialState=False
  // 初始化等待队列
  FRecvWaiters := specialize TVecDeque<Pointer>.Create;
  FSendWaiters := specialize TVecDeque<Pointer>.Create;
end;

destructor TChannel.Destroy;
begin
  try
    // 只有在完全初始化后才调用 Close
    if Assigned(FLock) and Assigned(FQueue) then
      Close;

    // 清理队列中的数据（注意：这里不释放用户数据，只清理队列）
    if Assigned(FQueue) then
    begin
      FQueue.Clear;
      FreeAndNil(FQueue);
    end;

    if Assigned(FRecvWaiters) then begin FRecvWaiters.Clear; FreeAndNil(FRecvWaiters); end;
    if Assigned(FSendWaiters) then begin FSendWaiters.Clear; FreeAndNil(FSendWaiters); end;

    FLock := nil;
    FDataAvailableEvent := nil;
    FSpaceAvailableEvent := nil;
  except
    // 忽略析构函数中的异常，避免二次异常
  end;

  inherited Destroy;
end;

function TChannel.Send(AValue: Pointer): Boolean;
begin
  Result := SendTimeout(AValue, INFINITE);
end;

function TChannel.SendTimeout(AValue: Pointer; ATimeoutMs: Cardinal): Boolean;
var
  LWaitResult: TWaitResult;
  PS: PSender;
  PR: PReceiver;
  LHaveLock: Boolean;
  Deadline, NowTick: QWord;
  WaitSlice: Cardinal;
  Idx: SizeInt;
begin
  Result := False;
  Deadline := GetTickCount64 + QWord(ATimeoutMs);

  while True do
  begin
    LHaveLock := False;
    FLock.Acquire;
    LHaveLock := True;

    if FClosed then
    begin
      if LHaveLock then begin FLock.Release; LHaveLock := False; end;
      Exit;
    end;

    if (FCapacity > 0) then
    begin
      if (FQueue.GetCount < FCapacity) then
      begin
        FQueue.PushBack(AValue);
        FDataAvailableEvent.SetEvent;
        if LHaveLock then begin FLock.Release; LHaveLock := False; end;
        DebugLog('chan send buffered ok');
        Result := True;
        Exit;
      end;
    end
    else // FCapacity = 0
    begin
      if FRecvWaiters.GetCount > 0 then
      begin
        // 取出最早的接收者进行配对
        PR := PReceiver(FRecvWaiters.Front);
        FRecvWaiters.PopFront;
        PR^.Value := AValue;
        if Assigned(PR^.Success) then
          PR^.Success^ := True;
        // 唤醒接收者（在锁内设置好状态）
        if Assigned(PR^.Event) then PR^.Event.SetEvent;
        if LHaveLock then begin FLock.Release; LHaveLock := False; end;
        DebugLog('chan send unbuffered paired');
        Result := True;
        Exit;
      end
      else
      begin
        // 无接收者等待：将发送者排队
        New(PS);
        PS^.Event := TEvent.Create(False, False);
        PS^.Value := AValue;
        New(PS^.Success);
        PS^.Success^ := False;
        FSendWaiters.PushBack(PS);
        // 释放锁，等待被接收者唤醒或超时
        if LHaveLock then begin FLock.Release; LHaveLock := False; end;
        DebugLog('chan send wait');
        if ATimeoutMs = INFINITE then
          LWaitResult := PS^.Event.WaitFor(INFINITE)
        else begin
          NowTick := GetTickCount64;
          if NowTick >= Deadline then LWaitResult := wrTimeout
          else begin
            // 等待剩余时间的一小片段，便于 close 及时唤醒
            if (Deadline - NowTick) < WaitSliceMs then WaitSlice := Deadline - NowTick else WaitSlice := WaitSliceMs;
            LWaitResult := PS^.Event.WaitFor(WaitSlice);
          end;
        end;
        if LWaitResult = wrSignaled then
          Result := PS^.Success^
        else if LWaitResult = wrTimeout then
          Result := False
        else
          Result := False;
        // 若未被配对且仍在队列，移除
        FLock.Acquire;
        // 线性查找并移除（低频路径，可接受）
        Idx := FSendWaiters.Find(PS);
        if Idx >= 0 then FSendWaiters.Remove(Idx);
        FLock.Release;
        // 清理发送者节点
        Dispose(PS^.Success);
        // PS^.Event 是接口，会自动释放
        Dispose(PS);
        Exit;
      end;
    end;

    // 无法发送（缓冲满）：释放锁，等待空间可用或超时后重试
    if LHaveLock then begin FLock.Release; LHaveLock := False; end;
    if ATimeoutMs = INFINITE then
      LWaitResult := FSpaceAvailableEvent.WaitFor(INFINITE)
    else begin
      NowTick := GetTickCount64;
      if NowTick >= Deadline then Exit(False);
      if (Deadline - NowTick) < WaitSliceMs then WaitSlice := Deadline - NowTick else WaitSlice := WaitSliceMs;
      LWaitResult := FSpaceAvailableEvent.WaitFor(WaitSlice);
      if LWaitResult <> wrSignaled then
      begin
        // 未被空间事件唤醒，可能是超时或关闭；循环将重新评估
        if (ATimeoutMs <> INFINITE) and (GetTickCount64 >= Deadline) then Exit(False);
      end;
    end;
    // 被唤醒或片段等待后重试发送
  end;
end;

function TChannel.Recv(out AValue: Pointer): Boolean;
begin
  Result := RecvTimeout(AValue, INFINITE);
end;

function TChannel.TryRecv(out AValue: Pointer): Boolean;
begin
  Result := RecvTimeout(AValue, 0);
end;

function TChannel.RecvTimeout(out AValue: Pointer; ATimeoutMs: Cardinal): Boolean;
var
  LWaitResult: TWaitResult;
  PR: PReceiver;
  PS: PSender;
  Idx, Idx2: SizeInt;
begin
  Result := False;
  AValue := nil;

  while True do
  begin
    FLock.Acquire;

    // 先尝试耗尽缓冲；若缓冲为空再判断关闭状态
    if FQueue.GetCount > 0 then
    begin
      AValue := FQueue.PopFront;
      // 通知等待发送的线程有空间了
      FSpaceAvailableEvent.SetEvent;
      FLock.Release;
      DebugLog('chan recv buffered ok');
      Exit(True);
    end;

    if FClosed then
    begin
      FLock.Release;
      Exit; // 通道已关闭且无剩余数据
    end;

    if FQueue.GetCount > 0 then
    begin
      AValue := FQueue.PopFront;
      // 通知等待发送的线程有空间了
      FSpaceAvailableEvent.SetEvent;
      FLock.Release;
      DebugLog('chan recv buffered ok');
      Exit(True);
    end;

    if FCapacity = 0 then
    begin
      if FSendWaiters.Count > 0 then
      begin
        // 有发送者等待：直接配对
        PS := PSender(FSendWaiters.Front);
        FSendWaiters.PopFront;
        AValue := PS^.Value;
        // 通知发送者成功
        if Assigned(PS^.Success) then PS^.Success^ := True;
        if Assigned(PS^.Event) then PS^.Event.SetEvent;
        FLock.Release;
        DebugLog('chan recv unbuffered paired');
        Exit(True);
      end
      else
      begin
        // 无发送者等待：将接收者加入等待队列并阻塞等待
        New(PR);
        PR^.Event := TEvent.Create(False, False);
        PR^.Value := nil;
        New(PR^.Success);
        PR^.Success^ := False;
        FRecvWaiters.PushBack(PR);
        // 释放锁后等待被唤醒
        FLock.Release;
        DebugLog('chan recv wait');

        LWaitResult := PR^.Event.WaitFor(ATimeoutMs);

        // 醒来后重新获取锁，确保从等待队列移除/读取结果
        FLock.Acquire;
        if LWaitResult = wrSignaled then
        begin
          // 被配对：从接收者结构读取 Value 输出
          AValue := PR^.Value;
          Result := PR^.Success^;
          Idx := FRecvWaiters.Find(PR);
          if Idx >= 0 then
            FRecvWaiters.Remove(Idx);
        end
        else
        begin
          // 超时：如果仍在队列中则移除
          Idx2 := FRecvWaiters.Find(PR);
          if Idx2 >= 0 then
            FRecvWaiters.Remove(Idx2);
          Result := False;
        end;
        FLock.Release;

        // 清理接收者节点
        Dispose(PR^.Success);
        Dispose(PR);
        Exit;
      end;
    end;

    // 到这里表示：无缓冲以外的情况且队列为空 => 等待数据可用
    FLock.Release;

    if ATimeoutMs = 0 then
      Exit(False); // 非阻塞调用，直接返回

    LWaitResult := FDataAvailableEvent.WaitFor(ATimeoutMs);
    if LWaitResult <> wrSignaled then
      Exit(False); // 超时或错误
    // 被唤醒后，循环重试
  end;
end;

procedure TChannel.Close;
var
  I: Integer;
  PR: PReceiver;
  PS: PSender;
  tmp: Pointer;
  tmp2: Pointer;
begin
  FLock.Acquire;
  try
    FClosed := True;

    // 唤醒所有等待的线程（队列等待和配对等待）
    FDataAvailableEvent.SetEvent;
    FSpaceAvailableEvent.SetEvent;

    // 唤醒所有等待的接收者/发送者（容量=0的配对队列）
    for I := 0 to FRecvWaiters.GetCount - 1 do
    begin

      if FRecvWaiters.TryGet(I, tmp) then
      begin
        PR := PReceiver(tmp);
        if Assigned(PR) then
        begin
          if Assigned(PR^.Success) then PR^.Success^ := False;
          if Assigned(PR^.Event) then PR^.Event.SetEvent;
        end;
      end;
    end;
    for I := 0 to FSendWaiters.GetCount - 1 do
    begin

      if FSendWaiters.TryGet(I, tmp2) then
      begin
        PS := PSender(tmp2);
        if Assigned(PS) then
        begin
          if Assigned(PS^.Success) then PS^.Success^ := False;
          if Assigned(PS^.Event) then PS^.Event.SetEvent;
        end;
      end;
    end;
    FRecvWaiters.Clear;
    FSendWaiters.Clear;
  finally
    FLock.Release;
  end;
end;

function TChannel.IsClosed: Boolean;
begin
  FLock.Acquire;
  try
    Result := FClosed;
  finally
    FLock.Release;
  end;
end;

end.
