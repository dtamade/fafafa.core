{
  fafafa.core.id.snowflake — Snowflake 64-bit ID generator (41/10/12)

  - Layout: [41-bit timestamp(ms since epoch)] [10-bit workerId] [12-bit sequence]
  - Default epoch: 1288834974657 (Twitter)
  - Thread-safe generation with per-ms sequence and wait-on-backward policy
}

unit fafafa.core.id.snowflake;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, DateUtils, SyncObjs,
  fafafa.core.time,
  fafafa.core.id.time;

type
  TSnowflakeID = QWord; // 64-bit

  // Specialized exceptions
  ESnowflakeError = class(Exception);
  ESnowflakeClockRollback = class(ESnowflakeError);
  ESnowflakeInvalidConfig = class(ESnowflakeError);

  TSnowflakeBackwardPolicy = (sbWait, sbThrow);

  TSnowflakeConfig = record
    EpochMs: Int64;
    WorkerId: Word;
    BackwardPolicy: TSnowflakeBackwardPolicy;
  end;

  ISnowflakeGenerator = interface
    ['{8F2F2B21-2E81-4CF6-ABAF-CC78A5F5EAF3}']
    // ✅ P1: 统一方法命名 - NextRaw 返回原始类型
    function NextRaw: TSnowflakeID;
    function Next: string;
    // 向后兼容
    function NextID: TSnowflakeID; deprecated 'Use NextRaw instead';
    function GetWorkerId: Word;
    function GetEpochMs: Int64;
    property WorkerId: Word read GetWorkerId;
    property EpochMs: Int64 read GetEpochMs;
  end;

  // ✅ P1: 向后兼容别名
  ISnowflake = ISnowflakeGenerator;

function CreateSnowflake(AWorkerId: Word = 0; AEpochMs: Int64 = 1288834974657): ISnowflake;
function CreateSnowflakeEx(const Config: TSnowflakeConfig): ISnowflake;

function Snowflake_TimestampMs(AId: TSnowflakeID; AEpochMs: Int64 = 1288834974657): Int64;
function Snowflake_WorkerId(AId: TSnowflakeID): Word;
function Snowflake_Sequence(AId: TSnowflakeID): Word;

implementation

const
  TIMESTAMP_BITS = 41;
  WORKER_BITS    = 10;
  SEQUENCE_BITS  = 12;

  WORKER_MAX     = (1 shl WORKER_BITS) - 1;   // 1023
  SEQUENCE_MAX   = (1 shl SEQUENCE_BITS) - 1; // 4095

  WORKER_SHIFT   = SEQUENCE_BITS;
  TIMESTAMP_SHIFT= SEQUENCE_BITS + WORKER_BITS;

// Use shared time helper from fafafa.core.id.time

function Snowflake_TimestampMs(AId: TSnowflakeID; AEpochMs: Int64): Int64;
begin
  Result := Int64(AId shr TIMESTAMP_SHIFT) + AEpochMs;
end;

function Snowflake_WorkerId(AId: TSnowflakeID): Word;
begin
  Result := Word((AId shr WORKER_SHIFT) and WORKER_MAX);
end;

function Snowflake_Sequence(AId: TSnowflakeID): Word;
begin
  Result := Word(AId and SEQUENCE_MAX);
end;

type
  TSnowflake = class(TInterfacedObject, ISnowflakeGenerator)
  private
    FWorkerId: Word;
    FEpochMs: Int64;
    FPolicy: TSnowflakeBackwardPolicy;
    FLock: TCriticalSection;
    FLastMs: Int64;
    FSeq: Word;
  public
    constructor Create(AWorkerId: Word; AEpochMs: Int64; APolicy: TSnowflakeBackwardPolicy);
    destructor Destroy; override;
    function NextRaw: TSnowflakeID;
    function Next: string;
    function NextID: TSnowflakeID;
    function GetWorkerId: Word;
    function GetEpochMs: Int64;
  end;

function CreateSnowflake(AWorkerId: Word; AEpochMs: Int64): ISnowflake;
begin
  if AWorkerId > WORKER_MAX then
    raise ESnowflakeInvalidConfig.CreateFmt('workerId out of range (0..%d): %d', [WORKER_MAX, AWorkerId]);
  Result := TSnowflake.Create(AWorkerId, AEpochMs, sbWait);
end;

function CreateSnowflakeEx(const Config: TSnowflakeConfig): ISnowflake;
begin
  if Config.WorkerId > WORKER_MAX then
    raise ESnowflakeInvalidConfig.CreateFmt('workerId out of range (0..%d): %d', [WORKER_MAX, Config.WorkerId]);
  Result := TSnowflake.Create(Config.WorkerId, Config.EpochMs, Config.BackwardPolicy);
end;

constructor TSnowflake.Create(AWorkerId: Word; AEpochMs: Int64; APolicy: TSnowflakeBackwardPolicy);
begin
  inherited Create;
  FWorkerId := AWorkerId;
  FEpochMs := AEpochMs;
  FPolicy := APolicy;
  FLock := TCriticalSection.Create;
  FLastMs := -1;
  FSeq := 0;
end;

destructor TSnowflake.Destroy;
begin
  FLock.Free;
  inherited Destroy;
end;

function TSnowflake.GetWorkerId: Word;
begin
  Result := FWorkerId;
end;

function TSnowflake.GetEpochMs: Int64;
begin
  Result := FEpochMs;
end;

function TSnowflake.NextID: TSnowflakeID;
begin
  Result := NextRaw;
end;

// ✅ P1: 新增 Next 方法返回字符串
function TSnowflake.Next: string;
begin
  Result := IntToStr(NextRaw);
end;

function TSnowflake.NextRaw: TSnowflakeID;
var
  LMs: Int64;
  LSeq: Word;
  LId: TSnowflakeID;
begin
  FLock.Acquire;
  try
    LMs := NowUnixMs;
    if LMs < FLastMs then
    begin
      if FPolicy = sbThrow then
        raise ESnowflakeClockRollback.CreateFmt('clock moved backwards: now=%d last=%d', [LMs, FLastMs]);
      // wait-on-backward: cooperative wait until time catches up
      repeat
        LMs := NowUnixMs;
        // yield a little to avoid hot spinning under long rollback
        SleepFor(TDuration.FromMs(1));
      until LMs >= FLastMs;
    end;

    if LMs = FLastMs then
    begin
      if FSeq = SEQUENCE_MAX then
      begin
        // overflow within same ms -> wait next ms (cooperative)
        repeat
          LMs := NowUnixMs;
          SleepFor(TDuration.FromMs(1));
        until LMs > FLastMs;
        // advance last ms to the new millisecond explicitly for clarity
        FLastMs := LMs;
        FSeq := 0;
      end
      else
        Inc(FSeq);
    end
    else
    begin
      FSeq := 0;
      FLastMs := LMs;
    end;

    LSeq := FSeq;
    LId := (TSnowflakeID(LMs - FEpochMs) shl TIMESTAMP_SHIFT)
           or (TSnowflakeID(FWorkerId) shl WORKER_SHIFT)
           or TSnowflakeID(LSeq);
    Result := LId;
  finally
    FLock.Release;
  end;
end;

end.

