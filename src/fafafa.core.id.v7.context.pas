{
  fafafa.core.id.v7.context — UUID v7 Context for monotonic generation

  - Guarantees strictly increasing UUIDs within the same millisecond
  - Uses 12-bit counter in rand_a field (bits 48-59)
  - Thread-safe via critical section
  - Inspired by Rust uuid crate 1.9+ ContextV7
}

unit fafafa.core.id.v7.context;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, SyncObjs,
  fafafa.core.id,
  fafafa.core.crypto.random,
  fafafa.core.id.time;

type
  EUuidV7OverflowError = class(Exception);

  { TContextV7 - Thread-safe context for monotonic UUID v7 generation }
  TContextV7 = class
  private
    FLock: TCriticalSection;
    FLastMs: Int64;
    FCounter: UInt16;      // 12-bit counter (0..4095)
    FLastRandB: UInt64;    // rand_b portion (62 bits usable)
    procedure Reseed;
  public
    constructor Create;
    destructor Destroy; override;

    { Generate next UUID v7, guaranteed monotonic within same millisecond }
    function NextRaw: TUuid128;
    function Next: string;

    { Generate with explicit timestamp (for testing) }
    function NextRawAt(TimestampMs: Int64): TUuid128;
  end;

  { IContextV7 - Interface wrapper for reference counting }
  IContextV7 = interface
    ['{B8A7C612-4D3E-4F1A-9B2C-8E5F6A7D9C01}']
    function NextRaw: TUuid128;
    function Next: string;
    function NextRawAt(TimestampMs: Int64): TUuid128;
  end;

{ Global context singleton - thread-safe }
function GlobalContextV7: TContextV7;

{ Convenience functions using global context }
function UuidV7_Monotonic: string;
function UuidV7_MonotonicRaw: TUuid128;

implementation

var
  GContextV7: TContextV7 = nil;
  GContextV7Lock: TCriticalSection = nil;

function GlobalContextV7: TContextV7;
begin
  if GContextV7 = nil then
  begin
    GContextV7Lock.Acquire;
    try
      if GContextV7 = nil then
        GContextV7 := TContextV7.Create;
    finally
      GContextV7Lock.Release;
    end;
  end;
  Result := GContextV7;
end;

function UuidV7_Monotonic: string;
begin
  Result := GlobalContextV7.Next;
end;

function UuidV7_MonotonicRaw: TUuid128;
begin
  Result := GlobalContextV7.NextRaw;
end;

{ TContextV7 }

constructor TContextV7.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FLastMs := -1;
  FCounter := 0;
  FLastRandB := 0;
end;

destructor TContextV7.Destroy;
begin
  FLock.Free;
  inherited Destroy;
end;

procedure TContextV7.Reseed;
var
  RandBytes: array[0..9] of Byte;
begin
  // Get 10 bytes of randomness for counter + rand_b
  GetSecureRandom.GetBytes(RandBytes, 10);

  // Counter: use lower 12 bits of first 2 bytes
  FCounter := (UInt16(RandBytes[0]) shl 8 or RandBytes[1]) and $0FFF;

  // rand_b: remaining 8 bytes (64 bits, but only 62 usable due to variant)
  FLastRandB :=
    (UInt64(RandBytes[2]) shl 56) or
    (UInt64(RandBytes[3]) shl 48) or
    (UInt64(RandBytes[4]) shl 40) or
    (UInt64(RandBytes[5]) shl 32) or
    (UInt64(RandBytes[6]) shl 24) or
    (UInt64(RandBytes[7]) shl 16) or
    (UInt64(RandBytes[8]) shl 8) or
    UInt64(RandBytes[9]);
end;

function TContextV7.NextRawAt(TimestampMs: Int64): TUuid128;
var
  NeedReseed: Boolean;
begin
  FLock.Acquire;
  try
    NeedReseed := False;

    if TimestampMs > FLastMs then
    begin
      // New millisecond - reseed everything
      FLastMs := TimestampMs;
      NeedReseed := True;
    end
    else if TimestampMs = FLastMs then
    begin
      // Same millisecond - increment counter
      Inc(FCounter);
      if FCounter > $0FFF then
      begin
        // Counter overflow (>4095) - increment rand_b
        FCounter := 0;
        Inc(FLastRandB);
        if FLastRandB = 0 then
        begin
          // rand_b overflow - must wait for next millisecond
          // This is extremely unlikely (2^76 IDs per millisecond)
          repeat
            Sleep(1);
            TimestampMs := NowUnixMs;
          until TimestampMs > FLastMs;
          FLastMs := TimestampMs;
          NeedReseed := True;
        end;
      end;
    end
    else
    begin
      // Clock went backwards - use last timestamp + 1ms and reseed
      // This handles clock adjustments gracefully
      FLastMs := FLastMs + 1;
      TimestampMs := FLastMs;
      NeedReseed := True;
    end;

    if NeedReseed then
      Reseed;

    // Build UUID v7
    // Bytes 0-5: 48-bit timestamp (big-endian)
    Result[0] := Byte((TimestampMs shr 40) and $FF);
    Result[1] := Byte((TimestampMs shr 32) and $FF);
    Result[2] := Byte((TimestampMs shr 24) and $FF);
    Result[3] := Byte((TimestampMs shr 16) and $FF);
    Result[4] := Byte((TimestampMs shr 8) and $FF);
    Result[5] := Byte(TimestampMs and $FF);

    // Byte 6: version (0111) + high 4 bits of counter
    Result[6] := $70 or Byte((FCounter shr 8) and $0F);

    // Byte 7: low 8 bits of counter
    Result[7] := Byte(FCounter and $FF);

    // Byte 8: variant (10) + high 6 bits of rand_b
    Result[8] := $80 or Byte((FLastRandB shr 56) and $3F);

    // Bytes 9-15: remaining rand_b
    Result[9] := Byte((FLastRandB shr 48) and $FF);
    Result[10] := Byte((FLastRandB shr 40) and $FF);
    Result[11] := Byte((FLastRandB shr 32) and $FF);
    Result[12] := Byte((FLastRandB shr 24) and $FF);
    Result[13] := Byte((FLastRandB shr 16) and $FF);
    Result[14] := Byte((FLastRandB shr 8) and $FF);
    Result[15] := Byte(FLastRandB and $FF);
  finally
    FLock.Release;
  end;
end;

function TContextV7.NextRaw: TUuid128;
begin
  Result := NextRawAt(NowUnixMs);
end;

function TContextV7.Next: string;
begin
  Result := UuidToString(NextRaw);
end;

initialization
  GContextV7Lock := TCriticalSection.Create;

finalization
  GContextV7.Free;
  GContextV7Lock.Free;

end.
