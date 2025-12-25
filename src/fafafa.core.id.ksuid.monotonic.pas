{
  fafafa.core.id.ksuid.monotonic — KSUID monotonic generator

  - 32-bit timestamp (seconds since KSUID epoch) + 128-bit random
  - Same-second calls increment 128-bit randomness
  - On 128-bit overflow within same second, waits for next second and reseeds
  - Thread-safe via critical section
}

unit fafafa.core.id.ksuid.monotonic;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, DateUtils, SyncObjs,
  fafafa.core.id.ksuid,
  fafafa.core.crypto.random,
  fafafa.core.time,
  fafafa.core.id.time;

type
  IKsuidGenerator = interface
    ['{A2B9C822-3C9F-4BFB-9D6F-0F3F9F9E4F82}']
    function NextRaw: TKsuid160;
    function Next: string;
  end;

function CreateKsuidMonotonic: IKsuidGenerator;

implementation

uses
  fafafa.core.id.rng;  // ✅ 缓冲 RNG 优化

const
  KSUID_EPOCH_UNIX = 1400000000; // 2014-05-13 16:53:20 UTC

type
  TKsuidMonotonic = class(TInterfacedObject, IKsuidGenerator)
  private
    FLock: TCriticalSection;
    FLastSec: Int64;  // Unix seconds
    FLastRand: array[0..15] of Byte; // 128-bit randomness
    procedure Inc128(var R: array of Byte);
    function IsAllZero(const R: array of Byte): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function NextRaw: TKsuid160;
    function Next: string;
  end;

function CreateKsuidMonotonic: IKsuidGenerator;
begin
  Result := TKsuidMonotonic.Create;
end;

constructor TKsuidMonotonic.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FLastSec := -1;
  FillChar(FLastRand[0], SizeOf(FLastRand), 0);
end;

destructor TKsuidMonotonic.Destroy;
begin
  // ✅ P0: 清理敏感随机数据
  FillChar(FLastRand[0], SizeOf(FLastRand), 0);
  FLock.Free;
  inherited Destroy;
end;

procedure TKsuidMonotonic.Inc128(var R: array of Byte);
var
  I: Integer;
  C: Integer;
begin
  C := 1;
  // increment big-endian 128-bit number
  for I := High(R) downto Low(R) do
  begin
    C := Integer(R[I]) + C;
    R[I] := Byte(C and $FF);
    C := C shr 8;
    if C = 0 then Break;
  end;
end;

function TKsuidMonotonic.IsAllZero(const R: array of Byte): Boolean;
var I: Integer;
begin
  for I := Low(R) to High(R) do
    if R[I] <> 0 then Exit(False);
  Result := True;
end;

function TKsuidMonotonic.NextRaw: TKsuid160;
var
  Sec: Int64;
  Rel: UInt32;
  A: TKsuid160;
begin
  FLock.Acquire;
  try
    Sec := NowUnixSeconds;

    if Sec <> FLastSec then
    begin
      // new second -> reseed randomness
      SecureRandomFill(FLastRand[0], 16);
      FLastSec := Sec;
    end
    else
    begin
      // same second -> increment 128-bit randomness
      Inc128(FLastRand);
      // if overflow (wrap to all zeros), wait next second
      if IsAllZero(FLastRand) then
      begin
        repeat
          Sec := NowUnixSeconds;
          SleepFor(TDuration.FromMs(100));
        until Sec > FLastSec;
        FLastSec := Sec;
        SecureRandomFill(FLastRand[0], 16);
      end;
    end;

    // compose KSUID raw (32-bit timestamp + 128-bit randomness)
    if FLastSec < KSUID_EPOCH_UNIX then
      Rel := 0
    else
      Rel := UInt32(FLastSec - KSUID_EPOCH_UNIX);

    A[0] := Byte((Rel shr 24) and $FF);
    A[1] := Byte((Rel shr 16) and $FF);
    A[2] := Byte((Rel shr 8) and $FF);
    A[3] := Byte(Rel and $FF);
    Move(FLastRand[0], A[4], 16);
    Result := A;
  finally
    FLock.Release;
  end;
end;

function TKsuidMonotonic.Next: string;
var R: TKsuid160;
begin
  R := NextRaw;
  KsuidToString(R, Result);
end;

end.
