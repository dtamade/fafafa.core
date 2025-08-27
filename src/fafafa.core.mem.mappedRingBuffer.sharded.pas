unit fafafa.core.mem.mappedRingBuffer.sharded;
{$mode objfpc}{$H+}

interface
uses
  SysUtils, Classes, SyncObjs, fafafa.core.mem.mappedRingBuffer;

type
  // 简单分片封装：将并发生产/消费分散到多条底层 ring
  TMappedRingBufferSharded = class
  private
    FShards: array of TMappedRingBuffer;
    FShardCount: Integer;
    FBaseName: string;
    FPushIdx: Integer;
    FPopIdx: Integer;
    FInit: Boolean;
    FCSel: TRTLCriticalSection;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function CreateShared(const BaseName: string; ShardCount: Integer; Capacity: UInt64; ElemSize: UInt32): Boolean;
    function OpenShared(const BaseName: string; ShardCount: Integer): Boolean;
    procedure Close;
    function Push(Data: Pointer): Boolean; overload;   // 轮询选择分片
    function Pop(Data: Pointer): Boolean; overload;
    function TryPush(Data: Pointer; MaxTries: Integer = 0): Boolean;
    function TryPop(Data: Pointer; MaxTries: Integer = 0): Boolean;
    property ShardCount: Integer read FShardCount;
  end;

implementation

constructor TMappedRingBufferSharded.Create;
begin
  inherited Create;
  FShardCount := 0;
  FBaseName := '';
  FPushIdx := 0;
  FPopIdx := 0;
  FInit := False;
  InitCriticalSection(FCSel);
end;

destructor TMappedRingBufferSharded.Destroy;
begin
  Close;
  DoneCriticalSection(FCSel);
  inherited Destroy;
end;

procedure TMappedRingBufferSharded.Close;
var
  i: Integer;
begin
  for i := 0 to High(FShards) do
  begin
    if FShards[i] <> nil then FShards[i].Free;
    FShards[i] := nil;
  end;
  SetLength(FShards, 0);
  FShardCount := 0;
  FInit := False;
end;

function TMappedRingBufferSharded.CreateShared(const BaseName: string; ShardCount: Integer; Capacity: UInt64; ElemSize: UInt32): Boolean;
var
  i: Integer;
  nm: string;
begin
  Close;
  Result := False;
  if ShardCount <= 0 then Exit;
  FBaseName := BaseName;
  FShardCount := ShardCount;
  SetLength(FShards, ShardCount);
  for i := 0 to ShardCount-1 do
  begin
    FShards[i] := TMappedRingBuffer.Create;
    nm := Format('%s_sh%0.2d', [BaseName, i]);
    if not FShards[i].CreateShared(nm, Capacity, ElemSize) then Exit;
  end;
  FInit := True;
  Result := True;
end;

function TMappedRingBufferSharded.OpenShared(const BaseName: string; ShardCount: Integer): Boolean;
var
  i: Integer;
  nm: string;
begin
  Close;
  Result := False;
  if ShardCount <= 0 then Exit;
  FBaseName := BaseName;
  FShardCount := ShardCount;
  SetLength(FShards, ShardCount);
  for i := 0 to ShardCount-1 do
  begin
    FShards[i] := TMappedRingBuffer.Create;
    nm := Format('%s_sh%0.2d', [BaseName, i]);
    if not FShards[i].OpenShared(nm) then Exit;
  end;
  FInit := True;
  Result := True;
end;

function TMappedRingBufferSharded.Push(Data: Pointer): Boolean;
var
  i, start: Integer;
begin
  if not FInit then Exit(False);
  EnterCriticalSection(FCSel);
  try
    start := FPushIdx;
    FPushIdx := (FPushIdx + 1) mod FShardCount;
  finally
    LeaveCriticalSection(FCSel);
  end;
  for i := 0 to FShardCount-1 do
  begin
    if FShards[(start + i) mod FShardCount].Push(Data) then Exit(True);
  end;
  Result := False;
end;

function TMappedRingBufferSharded.Pop(Data: Pointer): Boolean;
var
  i, start: Integer;
begin
  if not FInit then Exit(False);
  EnterCriticalSection(FCSel);
  try
    start := FPopIdx;
    FPopIdx := (FPopIdx + 1) mod FShardCount;
  finally
    LeaveCriticalSection(FCSel);
  end;
  for i := 0 to FShardCount-1 do
  begin
    if FShards[(start + i) mod FShardCount].Pop(Data) then Exit(True);
  end;
  Result := False;
end;

function TMappedRingBufferSharded.TryPush(Data: Pointer; MaxTries: Integer): Boolean;
var
  tries: Integer;
begin
  if MaxTries <= 0 then MaxTries := FShardCount;
  for tries := 1 to MaxTries do
    if Push(Data) then Exit(True);
  Result := False;
end;

function TMappedRingBufferSharded.TryPop(Data: Pointer; MaxTries: Integer): Boolean;
var
  tries: Integer;
begin
  if MaxTries <= 0 then MaxTries := FShardCount;
  for tries := 1 to MaxTries do
    if Pop(Data) then Exit(True);
  Result := False;
end;

end.

