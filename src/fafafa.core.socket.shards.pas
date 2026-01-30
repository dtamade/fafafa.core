unit fafafa.core.socket.shards;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, SyncObjs,
  fafafa.core.socket;

Type
  TShardOpKind = (opRegister, opUnregister, opModify);
  PShardOp = ^TShardOp;
  TShardOp = record
    Kind: TShardOpKind;
    S: ISocket;
    Events: TSocketEvents;
  end;

  IShardSystem = interface
    ['{C8B5E7E0-5B64-4B15-8E39-5F6E1B7D4C2A}']
    procedure Init(ShardCount: Integer);
    procedure Start;
    procedure Stop;
    procedure Assign(const S: ISocket; Events: TSocketEvents = [seRead, seWrite]);
    procedure Migrate(const S: ISocket; NewShard: Integer; NewEvents: TSocketEvents);
    function MetricsJson: string;
  end;

  TShardSystem = class(TInterfacedObject, IShardSystem)
  private
    type
      TShardMetrics = record
        ProcessedOps: QWord;
        ProcessedEvents: QWord;
        LastLoopMs: Integer;
      end;
    type
      TShardThread = class(TThread)
      private
        FOwner: TShardSystem;
        FIdx: Integer;
      protected
        procedure Execute; override;
      public
        constructor Create(aOwner: TShardSystem; aIdx: Integer);
      end;
  private
    FShardCount: Integer;
    FPollers: array of ISocketPoller;
    FThreads: array of TShardThread;
    FQueues: array of TList;            // queue of PShardOp
    FLocks: array of TRTLCriticalSection;
    FMetrics: array of TShardMetrics;
  private
    function ComputeShardIdx(const S: ISocket): Integer;
    procedure PostOp(idx: Integer; const Op: TShardOp);
    procedure DrainQueue(idx: Integer);
  public
    procedure Init(ShardCount: Integer);
    procedure Start;
    procedure Stop;
    procedure Assign(const S: ISocket; Events: TSocketEvents = [seRead, seWrite]);
    procedure Migrate(const S: ISocket; NewShard: Integer; NewEvents: TSocketEvents);
    function MetricsJson: string;
  end;

implementation

{ TShardSystem.TShardThread }

constructor TShardSystem.TShardThread.Create(aOwner: TShardSystem; aIdx: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FOwner := aOwner;
  FIdx := aIdx;
end;

procedure TShardSystem.TShardThread.Execute;
var
  T0: QWord;
  Results: TSocketPollResults;
  I: Integer;
begin
  while not Terminated do
  begin
    T0 := GetTickCount64;

    // 1) Drain queue
    FOwner.DrainQueue(FIdx);

    // 2) Poll events
    if Assigned(FOwner.FPollers[FIdx]) then
    begin
      if FOwner.FPollers[FIdx].Poll(10) > 0 then
      begin
        Results := FOwner.FPollers[FIdx].GetReadyEvents;
        for I := 0 to High(Results) do
          Inc(FOwner.FMetrics[FIdx].ProcessedEvents);
      end;
    end;

    FOwner.FMetrics[FIdx].LastLoopMs := Integer(GetTickCount64 - T0);
  end;
end;

{ TShardSystem }

function TShardSystem.ComputeShardIdx(const S: ISocket): Integer;
begin
  if FShardCount <= 0 then Exit(0);
  Result := PtrUInt(S.Handle) mod FShardCount;
end;

procedure TShardSystem.PostOp(idx: Integer; const Op: TShardOp);
var
  P: PShardOp;
begin
  if (idx < 0) or (idx >= FShardCount) then Exit;
  New(P); P^ := Op;
  EnterCriticalSection(FLocks[idx]);
  try
    FQueues[idx].Add(P);
  finally
    LeaveCriticalSection(FLocks[idx]);
  end;
end;

procedure TShardSystem.DrainQueue(idx: Integer);
var
  Local: TList;
  I: Integer;
  P: PShardOp;
begin
  Local := TList.Create;
  try
    EnterCriticalSection(FLocks[idx]);
    try
      if FQueues[idx].Count > 0 then
      begin
        Local.Assign(FQueues[idx]);
        FQueues[idx].Clear;
      end;
    finally
      LeaveCriticalSection(FLocks[idx]);
    end;

    for I := 0 to Local.Count - 1 do
    begin
      P := PShardOp(Local[I]);
      case P^.Kind of
        opRegister:   if Assigned(FPollers[idx]) then FPollers[idx].RegisterSocket(P^.S, P^.Events);
        opUnregister: if Assigned(FPollers[idx]) then FPollers[idx].UnregisterSocket(P^.S);
        opModify:     if Assigned(FPollers[idx]) then FPollers[idx].ModifyEvents(P^.S, P^.Events);
      end;
      Dispose(P);
      Inc(FMetrics[idx].ProcessedOps);
    end;
  finally
    Local.Free;
  end;
end;

procedure TShardSystem.Init(ShardCount: Integer);
var
  I: Integer;
begin
  FShardCount := ShardCount;
  if FShardCount <= 0 then FShardCount := 1;

  SetLength(FPollers, FShardCount);
  SetLength(FThreads, FShardCount);
  SetLength(FQueues, FShardCount);
  SetLength(FLocks, FShardCount);
  SetLength(FMetrics, FShardCount);

  for I := 0 to FShardCount - 1 do
  begin
    FPollers[I] := CreateDefaultPoller;
    FQueues[I] := TList.Create;
    InitCriticalSection(FLocks[I]);
    FillChar(FMetrics[I], SizeOf(FMetrics[I]), 0);
  end;
end;

procedure TShardSystem.Start;
var
  I: Integer;
begin
  for I := 0 to FShardCount - 1 do
  begin
    if not Assigned(FThreads[I]) then
      FThreads[I] := TShardThread.Create(Self, I);
    FThreads[I].Start;
  end;
end;

procedure TShardSystem.Stop;
var
  I: Integer;
begin
  for I := 0 to FShardCount - 1 do
    if Assigned(FThreads[I]) then
    begin
      FThreads[I].Terminate;
      FThreads[I].WaitFor;
      FreeAndNil(FThreads[I]);
    end;

  for I := 0 to FShardCount - 1 do
  begin
    if Assigned(FQueues[I]) then
    begin
      // 清理残留队列
      while FQueues[I].Count > 0 do
      begin
        Dispose(PShardOp(FQueues[I][FQueues[I].Count - 1]));
        FQueues[I].Delete(FQueues[I].Count - 1);
      end;
      FreeAndNil(FQueues[I]);
    end;
    DoneCriticalSection(FLocks[I]);
    FPollers[I] := nil;
  end;

  SetLength(FPollers, 0);
  SetLength(FThreads, 0);
  SetLength(FQueues, 0);
  SetLength(FLocks, 0);
  SetLength(FMetrics, 0);
end;

procedure TShardSystem.Assign(const S: ISocket; Events: TSocketEvents);
var
  idx: Integer;
  Op: TShardOp;
begin
  if S = nil then Exit;
  idx := ComputeShardIdx(S);
  Op.Kind := opRegister;
  Op.S := S;
  Op.Events := Events;
  PostOp(idx, Op);
end;

procedure TShardSystem.Migrate(const S: ISocket; NewShard: Integer; NewEvents: TSocketEvents);
var
  oldIdx: Integer;
  Op: TShardOp;
begin
  if S = nil then Exit;
  if (NewShard < 0) or (NewShard >= FShardCount) then Exit;
  oldIdx := ComputeShardIdx(S);
  // Unregister from old shard
  Op.Kind := opUnregister; Op.S := S; Op.Events := [];
  PostOp(oldIdx, Op);
  // Register into new shard
  Op.Kind := opRegister; Op.S := S; Op.Events := NewEvents;
  PostOp(NewShard, Op);
end;

function TShardSystem.MetricsJson: string;
var
  I: Integer;
  function IntToStrQW(const V: QWord): string; inline;
  begin
    Result := UIntToStr(V);
  end;
begin
  Result := '[';
  for I := 0 to FShardCount - 1 do
  begin
    if I > 0 then Result := Result + ',';
    Result := Result + '{' +
      '"idx":' + IntToStr(I) + ',' +
      '"processedOps":' + IntToStrQW(FMetrics[I].ProcessedOps) + ',' +
      '"processedEvents":' + IntToStrQW(FMetrics[I].ProcessedEvents) + ',' +
      '"queueLen":' + IntToStr(FQueues[I].Count) + ',' +
      '"lastLoopMs":' + IntToStr(FMetrics[I].LastLoopMs) +
    '}';
  end;
  Result := Result + ']';
end;

end.

