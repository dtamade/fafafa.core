{
  fafafa.core.id.snowflake.lockfree — Lock-free Snowflake ID generator

  - Uses AtomicU64 + CAS for thread-safe generation without locks
  - Packs state into single 64-bit value for atomic operations
  - Configurable clock rollback policy
  - Inspired by Rust snowflake_me crate
}

unit fafafa.core.id.snowflake.lockfree;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.id.snowflake,
  fafafa.core.id.time;

type
  { Clock rollback handling policy }
  TClockRollbackPolicy = (
    crpSpinWait,    // Spin-wait until clock catches up (default)
    crpRaiseError,  // Raise ESnowflakeClockRollback exception
    crpUseLastTime  // Use last known timestamp (may cause duplicates if persistent)
  );

  { TLockFreeSnowflake - High-performance lock-free Snowflake generator }
  TLockFreeSnowflake = class(TInterfacedObject, ISnowflakeGenerator)
  private
    // Packed state: [unused:1][timestamp:41][sequence:12][padding:10]
    // We use a different packing for CAS efficiency
    // Actually: [timestamp_delta:42][sequence:12][reserved:10]
    FState: QWord;  // Atomic state
    FWorkerId: Word;
    FEpochMs: Int64;
    FClockPolicy: TClockRollbackPolicy;
    FMaxSpinIterations: Integer;

    function AtomicCAS(var Target: QWord; Expected, NewValue: QWord): Boolean; inline;
    function AtomicLoad(var Target: QWord): QWord; inline;
    procedure AtomicStore(var Target: QWord; Value: QWord); inline;

    function ExtractTimestamp(State: QWord): Int64; inline;
    function ExtractSequence(State: QWord): Word; inline;
    function PackState(TimestampDelta: Int64; Sequence: Word): QWord; inline;
  public
    constructor Create(AWorkerId: Word; AEpochMs: Int64 = 1288834974657);

    { ISnowflakeGenerator interface }
    function NextRaw: TSnowflakeID;
    function Next: string;
    function NextID: TSnowflakeID;  // 向后兼容
    function GetWorkerId: Word;
    function GetEpochMs: Int64;

    { Configuration }
    property ClockPolicy: TClockRollbackPolicy read FClockPolicy write FClockPolicy;
    property MaxSpinIterations: Integer read FMaxSpinIterations write FMaxSpinIterations;
  end;

  { ILockFreeSnowflake - Extended interface with configuration }
  ILockFreeSnowflake = interface(ISnowflake)
    ['{C9B8D723-5E4F-4A2B-8C3D-7F6E5A8B9D02}']
    procedure SetClockPolicy(Policy: TClockRollbackPolicy);
    function GetClockPolicy: TClockRollbackPolicy;
    property ClockPolicy: TClockRollbackPolicy read GetClockPolicy write SetClockPolicy;
  end;

{ Factory function }
function CreateLockFreeSnowflake(AWorkerId: Word; AEpochMs: Int64 = 1288834974657): ISnowflake;

implementation

const
  SEQUENCE_BITS = 12;
  SEQUENCE_MASK = (1 shl SEQUENCE_BITS) - 1;  // 4095
  TIMESTAMP_SHIFT = SEQUENCE_BITS;
  MAX_TIMESTAMP_DELTA = Int64(1) shl 41 - 1;  // ~69 years

function CreateLockFreeSnowflake(AWorkerId: Word; AEpochMs: Int64): ISnowflake;
begin
  Result := TLockFreeSnowflake.Create(AWorkerId, AEpochMs);
end;

{ TLockFreeSnowflake }

constructor TLockFreeSnowflake.Create(AWorkerId: Word; AEpochMs: Int64);
begin
  inherited Create;
  FWorkerId := AWorkerId and $3FF;  // 10 bits max
  FEpochMs := AEpochMs;
  FState := 0;
  FClockPolicy := crpSpinWait;
  FMaxSpinIterations := 1000000;  // ~1 second at typical CPU speeds
end;

function TLockFreeSnowflake.AtomicCAS(var Target: QWord; Expected, NewValue: QWord): Boolean;
begin
  {$IFDEF CPUX86_64}
  Result := InterlockedCompareExchange64(Target, NewValue, Expected) = Expected;
  {$ELSE}
  // Fallback for other platforms - use InterlockedCompareExchange
  Result := InterlockedCompareExchange64(Target, NewValue, Expected) = Expected;
  {$ENDIF}
end;

function TLockFreeSnowflake.AtomicLoad(var Target: QWord): QWord;
begin
  {$IFDEF CPUX86_64}
  Result := InterlockedCompareExchange64(Target, 0, 0);
  {$ELSE}
  Result := InterlockedCompareExchange64(Target, 0, 0);
  {$ENDIF}
end;

procedure TLockFreeSnowflake.AtomicStore(var Target: QWord; Value: QWord);
begin
  InterlockedExchange64(Target, Value);
end;

function TLockFreeSnowflake.ExtractTimestamp(State: QWord): Int64;
begin
  Result := Int64(State shr TIMESTAMP_SHIFT);
end;

function TLockFreeSnowflake.ExtractSequence(State: QWord): Word;
begin
  Result := Word(State and SEQUENCE_MASK);
end;

function TLockFreeSnowflake.PackState(TimestampDelta: Int64; Sequence: Word): QWord;
begin
  Result := (QWord(TimestampDelta) shl TIMESTAMP_SHIFT) or QWord(Sequence and SEQUENCE_MASK);
end;

// ✅ P1: NextRaw 作为主实现
function TLockFreeSnowflake.NextRaw: TSnowflakeID;
var
  CurrentMs, TimestampDelta, LastTimestamp: Int64;
  OldState, NewState: QWord;
  Seq: Word;
  SpinCount: Integer;
  Success: Boolean;
begin
  SpinCount := 0;

  repeat
    CurrentMs := NowUnixMs;
    TimestampDelta := CurrentMs - FEpochMs;

    // Validate timestamp range
    if TimestampDelta < 0 then
      raise ESnowflakeClockRollback.Create('Clock is before epoch');
    if TimestampDelta > MAX_TIMESTAMP_DELTA then
      raise ESnowflakeInvalidConfig.Create('Timestamp overflow - epoch too old');

    OldState := AtomicLoad(FState);
    LastTimestamp := ExtractTimestamp(OldState);

    if TimestampDelta > LastTimestamp then
    begin
      // New millisecond - reset sequence to 0
      NewState := PackState(TimestampDelta, 0);
      Seq := 0;
    end
    else if TimestampDelta = LastTimestamp then
    begin
      // Same millisecond - increment sequence
      Seq := ExtractSequence(OldState) + 1;
      if Seq > SEQUENCE_MASK then
      begin
        // Sequence overflow - must wait for next millisecond
        Inc(SpinCount);
        if SpinCount > FMaxSpinIterations then
          raise ESnowflakeError.Create('Sequence overflow - too many IDs per millisecond');
        // Yield CPU briefly
        {$IFDEF WINDOWS}
        Sleep(0);
        {$ELSE}
        ThreadSwitch;
        {$ENDIF}
        Continue;  // Retry with new timestamp
      end;
      NewState := PackState(TimestampDelta, Seq);
    end
    else
    begin
      // Clock went backwards
      case FClockPolicy of
        crpSpinWait:
          begin
            Inc(SpinCount);
            if SpinCount > FMaxSpinIterations then
              raise ESnowflakeClockRollback.CreateFmt(
                'Clock rollback detected: current=%d, last=%d',
                [TimestampDelta + FEpochMs, LastTimestamp + FEpochMs]);
            // Wait for clock to catch up
            {$IFDEF WINDOWS}
            Sleep(1);
            {$ELSE}
            Sleep(1);
            {$ENDIF}
            Continue;
          end;
        crpRaiseError:
          raise ESnowflakeClockRollback.CreateFmt(
            'Clock rollback detected: current=%d, last=%d',
            [TimestampDelta + FEpochMs, LastTimestamp + FEpochMs]);
        crpUseLastTime:
          begin
            // Use last timestamp but increment sequence
            TimestampDelta := LastTimestamp;
            Seq := ExtractSequence(OldState) + 1;
            if Seq > SEQUENCE_MASK then
            begin
              // Force advance timestamp
              Inc(TimestampDelta);
              Seq := 0;
            end;
            NewState := PackState(TimestampDelta, Seq);
          end;
      end;
    end;

    // Try to update state atomically
    Success := AtomicCAS(FState, OldState, NewState);

    if not Success then
    begin
      // Another thread updated state - retry
      Inc(SpinCount);
      if SpinCount > FMaxSpinIterations then
        raise ESnowflakeError.Create('CAS contention timeout');
    end;
  until Success;

  // Build final Snowflake ID
  // Layout: [timestamp:41][worker:10][sequence:12] = 63 bits (sign bit = 0)
  Result :=
    ((TimestampDelta and $1FFFFFFFFFF) shl 22) or  // 41 bits timestamp
    (QWord(FWorkerId and $3FF) shl 12) or           // 10 bits worker
    (Seq and $FFF);                                  // 12 bits sequence
end;

// ✅ P1: Next 返回字符串表示
function TLockFreeSnowflake.Next: string;
begin
  Result := IntToStr(NextRaw);
end;

// ✅ P1: NextID 向后兼容，调用 NextRaw
function TLockFreeSnowflake.NextID: TSnowflakeID;
begin
  Result := NextRaw;
end;

function TLockFreeSnowflake.GetWorkerId: Word;
begin
  Result := FWorkerId;
end;

function TLockFreeSnowflake.GetEpochMs: Int64;
begin
  Result := FEpochMs;
end;

end.
