unit fafafa.core.logging.sinks.async;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.sync,
  fafafa.core.thread,
  fafafa.core.logging.interfaces;

type
  // 避免与 fafafa.core.io.async.TDropPolicy 冲突
  TLogDropPolicy = (ldpDropNew, ldpDropOld, ldpBlock);

  { 异步日志 Sink：有界队列 + 后台线程，将 ILogRecord 转发给内层 ILogSink }
  TAsyncLogSink = class(TInterfacedObject, ILogSink, ILogSinkStats)
  private
    FInner: ILogSink;
    FLock: ILock;
    FNotEmpty: ISem;
    FNotFull: ISem;
    FCapacity: Integer;
    FBatchSize: Integer;
    FDropPolicy: TLogDropPolicy;
    FBuf: array of ILogRecord;
    FHead, FTail, FCount: Integer;
    FStopping: Boolean;
    FWorker: IFuture;
    // Stats
    FEnqueued, FDequeued, FDroppedNew, FDroppedOld, FWaitAttempts, FMaxQ: QWord;
  private
    procedure Enqueue(const R: ILogRecord);
    function Dequeue(out R: ILogRecord): Boolean;
    procedure WorkerLoop;
    class function WorkerEntry(AData: Pointer): Boolean; static;
  public
    constructor Create(const AInner: ILogSink; ACapacity: Integer = 1024; ABatchSize: Integer = 64; ADrop: TLogDropPolicy = ldpDropNew);
    destructor Destroy; override;
    procedure Write(const R: ILogRecord);
    procedure Flush;
    // ILogSinkStats
    function GetStats: TLogSinkStats;
  end;

implementation

{ TAsyncLogSink }
constructor TAsyncLogSink.Create(const AInner: ILogSink; ACapacity: Integer; ABatchSize: Integer; ADrop: TLogDropPolicy);
begin
  inherited Create;
  if AInner = nil then raise EArgumentNilException.Create('inner sink');
  if ACapacity < 1 then ACapacity := 1;
  if ABatchSize < 1 then ABatchSize := 1;
  FInner := AInner;
  FCapacity := ACapacity;
  FBatchSize := ABatchSize;
  FDropPolicy := ADrop;
  SetLength(FBuf, FCapacity);
  FHead := 0; FTail := 0; FCount := 0;
  FLock := TMutex.Create;
  FNotEmpty := MakeSem(0, MaxInt);
  FNotFull := MakeSem(ACapacity, ACapacity);
  FStopping := False;
  FWorker := SpawnBlocking(@TAsyncLogSink.WorkerEntry, Pointer(Self));
  FEnqueued := 0; FDequeued := 0; FDroppedNew := 0; FDroppedOld := 0; FWaitAttempts := 0; FMaxQ := 0;
end;

destructor TAsyncLogSink.Destroy;
begin
  // 请求停止
  FLock.Acquire;
  try
    FStopping := True;
  finally
    FLock.Release;
  end;
  // 唤醒消费者（如在等待非空）；避免对 NotFull 进行额外 Release 以防超过最大计数
  // 说明：
  // - 生产者在 Enqueue 时 Acquire(NotFull)，消费者在 Dequeue 时 Release(NotFull)
  // - 析构阶段如果额外 Release(NotFull)，可能超过创建时的最大计数（=容量），触发 ELockError
  // - 因此只需唤醒等待非空的消费者线程（Release NotEmpty），让其自然消费并回收 NotFull
  FNotEmpty.Release;
  if Assigned(FWorker) then FWorker.WaitFor(3000);
  // 冲刷剩余
  Flush;
  inherited Destroy;
end;

procedure TAsyncLogSink.Enqueue(const R: ILogRecord);
var
  NextTail: Integer;
  Dropped: ILogRecord;
begin
  FLock.Acquire;
  try
    if FCount < FCapacity then
    begin
      // 占用一个可用空间（与消费者释放对称）
      FNotFull.Acquire;
      FBuf[FTail] := R;
      NextTail := FTail + 1;
      if NextTail >= FCapacity then NextTail := 0;
      FTail := NextTail;
      Inc(FCount);
      if QWord(FCount) > FMaxQ then FMaxQ := QWord(FCount);
      Inc(FEnqueued);
      FNotEmpty.Release;
      Exit;
    end;
    // 满了
    case FDropPolicy of
      ldpDropNew:
        begin
          Inc(FDroppedNew);
        end;
      ldpDropOld:
        begin
          if FCount > 0 then
          begin
            // 丢弃头部最老记录（等价于一次消费），释放一个可用空间
            Dropped := FBuf[FHead];
            FBuf[FHead] := nil;
            Inc(FDroppedOld);
            Inc(FHead);
            if FHead >= FCapacity then FHead := 0;
            Dec(FCount);
            // 不调整 FNotFull，保持可用空间不变（仍为0）
            FBuf[FTail] := R;
            NextTail := FTail + 1;
            if NextTail >= FCapacity then NextTail := 0;
            FTail := NextTail;
            Inc(FCount);
            FNotEmpty.Release;
          end;
        end;
      ldpBlock:
        begin
          // 释放锁等待可用空间（避免忙等），等待期间由消费者释放 FNotFull
          FLock.Release;
          FNotFull.Acquire; // 阻塞直至有空间
          FLock.Acquire;
          try
            if FStopping then Exit;
            // 放入当前
            FBuf[FTail] := R;
            NextTail := FTail + 1;
            if NextTail >= FCapacity then NextTail := 0;
            FTail := NextTail;
            // 注意：在满->等待->写入的路径中，不改变 FCount（保持恒等），可将“丢弃旧”或“消费释放”带来的空位占用掉
            // 但就接口一致性而言，这里仍执行 Inc(FCount) 与消费者对应的 Release(FNotFull) 完整对称
            Inc(FCount);
            FNotEmpty.Release;
            Inc(FWaitAttempts); // 记录一次等待
          finally
            FLock.Release;
          end;
        end;
    end;
  finally
    FLock.Release;
  end;
end;

function TAsyncLogSink.Dequeue(out R: ILogRecord): Boolean;
begin
  Result := False;
  R := nil;
  FLock.Acquire;
  try
    if FCount > 0 then
    begin
      R := FBuf[FHead];
      FBuf[FHead] := nil;
      Inc(FHead);
      if FHead >= FCapacity then FHead := 0;
      Dec(FCount);
      Inc(FDequeued);
      Result := True;
    end;
  finally
    FLock.Release;
  end;
end;

procedure TAsyncLogSink.WorkerLoop;
var
  I, N: Integer;
  Rec: ILogRecord;
begin
  while True do
  begin
    if not FNotEmpty.TryAcquire(50) then
    begin
      if FStopping then Break;
      Continue;
    end;

    N := FBatchSize;
    for I := 1 to N do
    begin
      if not Dequeue(Rec) then Break;
      if (FInner <> nil) and (Rec <> nil) then
        FInner.Write(Rec);
      // 每消费一条，释放一个可用空间
      FNotFull.Release;
    end;
    if FInner <> nil then FInner.Flush;

    if FStopping then
    begin
      // 清空剩余
      while Dequeue(Rec) do
        if (FInner <> nil) and (Rec <> nil) then FInner.Write(Rec);
      if FInner <> nil then FInner.Flush;
      Break;
    end;
  end;
end;

class function TAsyncLogSink.WorkerEntry(AData: Pointer): Boolean;
begin
  if AData = nil then Exit(False);
  TAsyncLogSink(AData).WorkerLoop;
  Result := True;
end;

procedure TAsyncLogSink.Write(const R: ILogRecord);
begin
  if FStopping or (R = nil) then Exit;
  Enqueue(R);
end;

procedure TAsyncLogSink.Flush;
var
  Rec: ILogRecord;
begin
  // 主动冲刷队列
  while Dequeue(Rec) do
    if (FInner <> nil) and (Rec <> nil) then FInner.Write(Rec);
  if FInner <> nil then FInner.Flush;
  // 更新峰值（安全估计）：在 Flush 后读取当前 FCount 作为可能峰值校准
  FLock.Acquire; try if QWord(FCount) > FMaxQ then FMaxQ := QWord(FCount); finally FLock.Release; end;
end;

function TAsyncLogSink.GetStats: TLogSinkStats;
begin
  FLock.Acquire;
  try
    Result.Enqueued := FEnqueued;
    Result.Dequeued := FDequeued;
    Result.DroppedNew := FDroppedNew;
    Result.DroppedOld := FDroppedOld;
    Result.WaitAttempts := FWaitAttempts;
    Result.MaxQueueSize := FMaxQ;
  finally
    FLock.Release;
  end;
end;

end.

