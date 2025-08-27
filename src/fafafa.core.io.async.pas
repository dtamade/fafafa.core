unit fafafa.core.io.async;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.sync,
  fafafa.core.thread,
  fafafa.core.io;

type
  TDropPolicy = (dpDropNew, dpDropOld, dpBlock);

  { 异步文本输出：有界队列 + 后台线程批量写入 }
  TAsyncTextSink = class(TInterfacedObject, ITextSink)
  private
    FInner: ITextSink;
    FLock: ILock;
    FNotEmpty: ISemaphore;
    FCapacity: Integer;
    FBatchSize: Integer;
    FDropPolicy: TDropPolicy;
    FBuf: array of string;
    FHead, FTail, FCount: Integer;
    FStopping: Boolean;
    FWorker: IFuture;
  private
    procedure Enqueue(const S: string);
    function Dequeue(var OutS: string): Boolean;
    procedure WorkerLoop; // 实例方法
    class function WorkerEntry(AData: Pointer): Boolean; static; // 线程池入口
  public
    constructor Create(const AInner: ITextSink; ACapacity: Integer = 1024; ABatchSize: Integer = 64; ADrop: TDropPolicy = dpDropNew);
    destructor Destroy; override;
    procedure WriteLine(const S: string);
    procedure Flush;
  end;

implementation

{ TAsyncTextSink }
constructor TAsyncTextSink.Create(const AInner: ITextSink; ACapacity: Integer; ABatchSize: Integer; ADrop: TDropPolicy);
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
  FNotEmpty := TSemaphore.Create(0, MaxInt);
  FStopping := False;
  // 提交后台工作线程
  FWorker := SpawnBlocking(@TAsyncTextSink.WorkerEntry, Pointer(Self));
end;

destructor TAsyncTextSink.Destroy;
begin
  // 请求停止
  FLock.Acquire;
  try
    FStopping := True;
  finally
    FLock.Release;
  end;
  // 唤醒消费者以便尽快退出
  FNotEmpty.Release;
  // 等待工作线程结束（有限时）；若 IFuture 不可用，则略过
  if Assigned(FWorker) then FWorker.WaitFor(3000);
  // 最后尽力冲刷剩余
  Flush;
  inherited Destroy;
end;

procedure TAsyncTextSink.Enqueue(const S: string);
var
  NextTail: Integer;
  Dropped: string;
begin
  FLock.Acquire;
  try
    if FCount < FCapacity then
    begin
      FBuf[FTail] := S;
      NextTail := FTail + 1;
      if NextTail >= FCapacity then NextTail := 0;
      FTail := NextTail;
      Inc(FCount);
      FNotEmpty.Release;
      Exit;
    end;
    // 满了
    case FDropPolicy of
      dpDropNew:
        ; // 丢弃新消息，静默
      dpDropOld:
        begin
          // 覆盖最老一条
          if FCount > 0 then
          begin
            // 丢弃头部
            Dropped := FBuf[FHead];
            FBuf[FHead] := '';
            Inc(FHead);
            if FHead >= FCapacity then FHead := 0;
            Dec(FCount);
            // 再 enqueue 一次（空间足够）
            FBuf[FTail] := S;
            NextTail := FTail + 1;
            if NextTail >= FCapacity then NextTail := 0;
            FTail := NextTail;
            Inc(FCount);
            FNotEmpty.Release;
          end;
        end;
      dpBlock:
        begin
          // 简单阻塞：自旋等待直到有空位（带小睡避免忙等）
          while FCount >= FCapacity do
          begin
            FLock.Release;
            Sleep(1);
            FLock.Acquire;
            if FStopping then Exit; // 退出
          end;
          // 此时有空位
          FBuf[FTail] := S;
          NextTail := FTail + 1;
          if NextTail >= FCapacity then NextTail := 0;
          FTail := NextTail;
          Inc(FCount);
          FNotEmpty.Release;
        end;
    end;
  finally
    FLock.Release;
  end;
end;

function TAsyncTextSink.Dequeue(var OutS: string): Boolean;
begin
  Result := False;
  FLock.Acquire;
  try
    if FCount > 0 then
    begin
      OutS := FBuf[FHead];
      FBuf[FHead] := '';
      Inc(FHead);
      if FHead >= FCapacity then FHead := 0;
      Dec(FCount);
      Result := True;
    end;
  finally
    FLock.Release;
  end;
end;

procedure TAsyncTextSink.WorkerLoop;
var
  I, N: Integer;
  Line: string;
begin
  // 循环直到停止且队列清空
  while True do
  begin
    // 等待有数据或停止
    if not FNotEmpty.TryAcquire(50) then
    begin
      if FStopping then Break;
      Continue;
    end;

    // 批量处理
    N := FBatchSize;
    for I := 1 to N do
    begin
      if not Dequeue(Line) then Break;
      FInner.WriteLine(Line);
    end;
    FInner.Flush;

    if FStopping then
    begin
      // 清空剩余
      while Dequeue(Line) do FInner.WriteLine(Line);
      FInner.Flush;
      Break;
    end;
  end;
end;

class function TAsyncTextSink.WorkerEntry(AData: Pointer): Boolean;
begin
  if AData = nil then Exit(False);
  TAsyncTextSink(AData).WorkerLoop;
  Result := True;
end;


procedure TAsyncTextSink.WriteLine(const S: string);
begin
  if FStopping then Exit;
  Enqueue(S);
end;

procedure TAsyncTextSink.Flush;
var
  Line: string;
begin
  // 主动冲刷：将队列内容尽力写出
  while Dequeue(Line) do
    FInner.WriteLine(Line);
  FInner.Flush;
end;

end.

