{
  fafafa.core.id.ulid.policy — ULID overflow policy support

  - Configurable overflow behavior
  - WrapToZero: Continue with sequence 0 (may break monotonicity)
  - WaitNextMs: Block until next millisecond
  - RaiseError: Throw exception
  - Inspired by Rust ulid crate
}

unit fafafa.core.id.ulid.policy;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, SyncObjs,
  fafafa.core.id.ulid,
  fafafa.core.crypto.random,
  fafafa.core.id.time;

type
  { Overflow policy enumeration }
  TUlidOverflowPolicy = (
    opWrapToZero,      // Reset random to 0 on overflow (breaks strict monotonicity)
    opWaitNextMs,      // Wait for next millisecond (default, safe)
    opRaiseError       // Raise EUlidOverflow exception
  );

  { ULID overflow exception }
  EUlidOverflow = class(Exception);

  { IUlidGenerator - Interface for configurable ULID generation }
  IUlidGenerator = interface
    ['{A7B8C9D0-1E2F-3A4B-5C6D-7E8F9A0B1C2D}']
    function Next: string;
    function NextRaw: TUlid128;
    function GetOverflowPolicy: TUlidOverflowPolicy;
    procedure SetOverflowPolicy(Policy: TUlidOverflowPolicy);
    property OverflowPolicy: TUlidOverflowPolicy read GetOverflowPolicy write SetOverflowPolicy;
  end;

  { TUlidGenerator - Configurable monotonic ULID generator }
  TUlidGenerator = class(TInterfacedObject, IUlidGenerator)
  private
    FLock: TCriticalSection;
    FLastMs: Int64;
    FRandom: array[0..9] of Byte;  // 80-bit random part
    FPolicy: TUlidOverflowPolicy;

    procedure Reseed;
    function IncrementRandom: Boolean;  // Returns False on overflow
  public
    constructor Create(APolicy: TUlidOverflowPolicy = opWaitNextMs);
    destructor Destroy; override;

    function Next: string;
    function NextRaw: TUlid128;
    function NextRawAt(TimestampMs: Int64): TUlid128;

    function GetOverflowPolicy: TUlidOverflowPolicy;
    procedure SetOverflowPolicy(Policy: TUlidOverflowPolicy);
    property OverflowPolicy: TUlidOverflowPolicy read GetOverflowPolicy write SetOverflowPolicy;
  end;

{ Factory function }
function CreateUlidGenerator(APolicy: TUlidOverflowPolicy = opWaitNextMs): IUlidGenerator;

implementation

function CreateUlidGenerator(APolicy: TUlidOverflowPolicy): IUlidGenerator;
begin
  Result := TUlidGenerator.Create(APolicy);
end;

{ TUlidGenerator }

constructor TUlidGenerator.Create(APolicy: TUlidOverflowPolicy);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FLastMs := -1;
  FPolicy := APolicy;
  FillChar(FRandom[0], 10, 0);
end;

destructor TUlidGenerator.Destroy;
begin
  // ✅ P0: 清理敏感随机数据
  FillChar(FRandom[0], SizeOf(FRandom), 0);
  FLock.Free;
  inherited Destroy;
end;

procedure TUlidGenerator.Reseed;
begin
  GetSecureRandom.GetBytes(FRandom, 10);
end;

function TUlidGenerator.IncrementRandom: Boolean;
var
  I: Integer;
  Carry: Integer;
begin
  // Increment 80-bit random part as big-endian integer
  Carry := 1;
  for I := 9 downto 0 do
  begin
    Carry := Carry + FRandom[I];
    FRandom[I] := Byte(Carry and $FF);
    Carry := Carry shr 8;
    if Carry = 0 then Break;
  end;

  // Return True if no overflow, False if wrapped to zero
  Result := (Carry = 0);
end;

function TUlidGenerator.GetOverflowPolicy: TUlidOverflowPolicy;
begin
  Result := FPolicy;
end;

procedure TUlidGenerator.SetOverflowPolicy(Policy: TUlidOverflowPolicy);
begin
  FPolicy := Policy;
end;

function TUlidGenerator.NextRawAt(TimestampMs: Int64): TUlid128;
var
  Overflowed: Boolean;
begin
  FLock.Acquire;
  try
    if TimestampMs > FLastMs then
    begin
      // New millisecond - reseed random
      FLastMs := TimestampMs;
      Reseed;
    end
    else if TimestampMs = FLastMs then
    begin
      // Same millisecond - increment random
      Overflowed := not IncrementRandom;

      if Overflowed then
      begin
        case FPolicy of
          opWrapToZero:
            begin
              // Just continue with wrapped random (breaks monotonicity)
              // FRandom already wrapped to 0
            end;
          opWaitNextMs:
            begin
              // Wait for next millisecond
              repeat
                Sleep(1);
                TimestampMs := NowUnixMs;
              until TimestampMs > FLastMs;
              FLastMs := TimestampMs;
              Reseed;
            end;
          opRaiseError:
            raise EUlidOverflow.Create('ULID random overflow - too many IDs per millisecond');
        end;
      end;
    end
    else
    begin
      // Clock went backwards - advance to last timestamp + 1
      FLastMs := FLastMs + 1;
      TimestampMs := FLastMs;
      Reseed;
    end;

    // Build ULID: 48-bit timestamp + 80-bit random
    // Timestamp (big-endian, 6 bytes)
    Result[0] := Byte((TimestampMs shr 40) and $FF);
    Result[1] := Byte((TimestampMs shr 32) and $FF);
    Result[2] := Byte((TimestampMs shr 24) and $FF);
    Result[3] := Byte((TimestampMs shr 16) and $FF);
    Result[4] := Byte((TimestampMs shr 8) and $FF);
    Result[5] := Byte(TimestampMs and $FF);

    // Random (10 bytes)
    Move(FRandom[0], Result[6], 10);
  finally
    FLock.Release;
  end;
end;

function TUlidGenerator.NextRaw: TUlid128;
begin
  Result := NextRawAt(NowUnixMs);
end;

function TUlidGenerator.Next: string;
begin
  Result := UlidToString(NextRaw);
end;

end.
