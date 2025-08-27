{
  fafafa.core.id.v7.monotonic — UUID v7 monotonic generator

  - 48-bit Unix ms timestamp + 12-bit rand_a + 62-bit rand_b (RFC 9562)
  - Same-ms calls increment rand_a (12-bit). On overflow, waits for next ms and reseeds.
  - Thread-safe via critical section. Randomness via fafafa.core.crypto.random.
}

unit fafafa.core.id.v7.monotonic;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, SyncObjs,
  fafafa.core.id,            // TUuid128, UuidToString
  fafafa.core.crypto.random, // GetSecureRandom
  fafafa.core.time,          // TDuration, SleepFor
  fafafa.core.id.time;       // NowUnixMs

type
  IUuidV7Generator = interface
    ['{6C1B4A2D-3A9B-4E79-8C0B-9E5E2B0C3F1D}']
    function NextRaw: TUuid128;
    function Next: string;
    // Batch APIs: fill preallocated array or allocate new
    procedure NextRawN(var OutArr: array of TUuid128);
  end;

  TUuidV7BackwardPolicy = (bpWait, bpThrow);
  TUuidV7Options = record
    WaitSleepMs: Integer;          // 0 = spin, >0 = SleepFor(ms) in waits
    BackwardPolicy: TUuidV7BackwardPolicy; // default bpWait
  end;

  EUuidClockRollback = class(Exception);

function CreateUuidV7Monotonic: IUuidV7Generator;
function CreateUuidV7MonotonicEx(const Opts: TUuidV7Options): IUuidV7Generator;

implementation

procedure SecureRandomFill(var Buf; Count: SizeInt);
begin
  GetSecureRandom.GetBytes(Buf, Count);
end;

type
  TUuidV7Monotonic = class(TInterfacedObject, IUuidV7Generator)
  private
    FLock: TCriticalSection;
    FLastMs: Int64;
    FOpts: TUuidV7Options;
    // Random bytes for fields 6..15 (10 bytes). We mutate rand_a (12-bit) within [0] low nibble and [1].
    FLastRand: array[0..9] of Byte;
    procedure SeedForMs(const Ms: Int64);
    function IncRandAOrOverflow: Boolean; // True if overflowed beyond 0xFFF
  public
    constructor Create; overload;
    constructor Create(const Opts: TUuidV7Options); overload;
    destructor Destroy; override;
    function NextRaw: TUuid128;
    function Next: string;
    procedure NextRawN(var OutArr: array of TUuid128);
  end;

function CreateUuidV7Monotonic: IUuidV7Generator;
begin
  Result := TUuidV7Monotonic.Create;
end;

function CreateUuidV7MonotonicEx(const Opts: TUuidV7Options): IUuidV7Generator;
begin
  Result := TUuidV7Monotonic.Create(Opts);
end;

constructor TUuidV7Monotonic.Create;
var Def: TUuidV7Options;
begin
  Def.WaitSleepMs := 1; // default cooperative 1ms sleep
  Def.BackwardPolicy := bpWait;
  Create(Def);
end;

constructor TUuidV7Monotonic.Create(const Opts: TUuidV7Options);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FLastMs := -1;
  FOpts := Opts;
  FillChar(FLastRand, SizeOf(FLastRand), 0);
end;

destructor TUuidV7Monotonic.Destroy;
begin
  FLock.Free;
  inherited Destroy;
end;

procedure TUuidV7Monotonic.SeedForMs(const Ms: Int64);
begin
  FLastMs := Ms;
  SecureRandomFill(FLastRand[0], Length(FLastRand));
  // Clear version nibble space in [0] high nibble (we only keep low nibble for rand_a high 4 bits)
  FLastRand[0] := FLastRand[0] and $0F;
end;

function TUuidV7Monotonic.IncRandAOrOverflow: Boolean;
var
  RA: Integer; // 12-bit
begin
  // rand_a spread: [0] low nibble (high 4 bits of rand_a), [1] full 8 bits (low 8 bits)
  RA := ((FLastRand[0] and $0F) shl 8) or FLastRand[1];
  if RA = $0FFF then
  begin
    Result := True; // overflow
    Exit;
  end;
  Inc(RA);
  // Write back
  FLastRand[0] := (FLastRand[0] and $F0) or Byte((RA shr 8) and $0F);
  FLastRand[1] := Byte(RA and $FF);
  Result := False;
end;

function TUuidV7Monotonic.NextRaw: TUuid128;
var
  Ms: Int64;
  A: TUuid128;
begin
  FLock.Acquire;
  try
    Ms := NowUnixMs;
    // Handle clock going backwards: wait until time catches up (simple policy)
    while (FLastMs >= 0) and (Ms < FLastMs) do
    begin
      if FOpts.BackwardPolicy = bpThrow then
        raise EUuidClockRollback.Create('UUIDv7 clock rollback detected');
      Ms := NowUnixMs;
      if FOpts.WaitSleepMs > 0 then SleepFor(TDuration.FromMs(FOpts.WaitSleepMs));
    end;

    if Ms <> FLastMs then
    begin
      SeedForMs(Ms);
    end
    else
    begin
      if IncRandAOrOverflow then
      begin
        // Wait for next ms, then reseed
        repeat
          Ms := NowUnixMs;
          if FOpts.WaitSleepMs > 0 then SleepFor(TDuration.FromMs(FOpts.WaitSleepMs));
        until Ms > FLastMs;
        SeedForMs(Ms);
      end;
    end;

    // Compose UUID v7
    // Timestamp 48-bit big-endian
    A[0] := Byte((QWord(FLastMs) shr 40) and $FF);
    A[1] := Byte((QWord(FLastMs) shr 32) and $FF);
    A[2] := Byte((QWord(FLastMs) shr 24) and $FF);
    A[3] := Byte((QWord(FLastMs) shr 16) and $FF);
    A[4] := Byte((QWord(FLastMs) shr 8) and $FF);
    A[5] := Byte(QWord(FLastMs) and $FF);

    // Copy 10 random bytes for fields 6..15, then set version/variant bits
    Move(FLastRand[0], A[6], 10);

    // Set version (7) in byte 6 high nibble
    A[6] := (A[6] and $0F) or $70;
    // Set variant (RFC 4122: 10b) in byte 8 high bits
  A[8] := (A[8] and $3F) or $80;

    Result := A;
  finally
    FLock.Release;
  end;
end;

function TUuidV7Monotonic.Next: string;
begin
  UuidToString(NextRaw, Result);
end;

procedure TUuidV7Monotonic.NextRawN(var OutArr: array of TUuid128);
var i: SizeInt;
begin
  // Avoid holding the internal lock across the entire batch; NextRaw is safe
  for i := 0 to High(OutArr) do
    OutArr[i] := NextRaw;
end;

end.

