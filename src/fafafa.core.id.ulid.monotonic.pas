{
  fafafa.core.id.ulid.monotonic — ULID monotonic generator

  - 48-bit Unix ms timestamp + 80-bit random; same-ms calls increment 80-bit
  - On 80-bit overflow within same ms, waits for next ms and reseeds random
  - Thread-safe via critical section
}

unit fafafa.core.id.ulid.monotonic;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, DateUtils, SyncObjs,
  fafafa.core.id.ulid,
  fafafa.core.crypto.random,
  fafafa.core.time,
  fafafa.core.id.time;

type
  IUlidGenerator = interface
    ['{D1A8C711-1B8E-4AFA-8C5E-9E2E8F8D3E71}']
    function NextRaw: TUlid128;
    function Next: string;
  end;

function CreateUlidMonotonic: IUlidGenerator;

implementation

uses
  fafafa.core.id.rng;  // ✅ 缓冲 RNG 优化

type
  TUlidMonotonic = class(TInterfacedObject, IUlidGenerator)
  private
    FLock: TCriticalSection;
    FLastMs: Int64;
    FLastRand: array[0..9] of Byte; // 80-bit randomness
    procedure Inc80(var R: array of Byte);
  public
    constructor Create;
    destructor Destroy; override;
    function NextRaw: TUlid128;
    function Next: string;
  end;

function CreateUlidMonotonic: IUlidGenerator;
begin
  Result := TUlidMonotonic.Create;
end;

constructor TUlidMonotonic.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FLastMs := -1;
  FillChar(FLastRand[0], SizeOf(FLastRand), 0);
end;

destructor TUlidMonotonic.Destroy;
begin
  // ✅ P0: 清理敏感随机数据
  FillChar(FLastRand[0], SizeOf(FLastRand), 0);
  FLock.Free;
  inherited Destroy;
end;

procedure TUlidMonotonic.Inc80(var R: array of Byte);
var
  I: Integer; C: Integer;
begin
  C := 1;
  // increment big-endian 80-bit number
  for I := High(R) downto Low(R) do
  begin
    C := Integer(R[I]) + C;
    R[I] := Byte(C and $FF);
    C := C shr 8;
    if C = 0 then Break;
  end;
end;

function TUlidMonotonic.NextRaw: TUlid128;
var
  MS: Int64;
  A: TUlid128;
begin
  FLock.Acquire;
  try
    MS := NowUnixMs;
    // keep within previous ms window if we just advanced by <=1ms to ensure immediate consecutive calls share ms
    if (FLastMs >= 0) and (MS > FLastMs) and ((MS - FLastMs) <= 1) then
      MS := FLastMs;
    if MS <> FLastMs then
    begin
      // new ms -> reseed randomness
      SecureRandomFill(FLastRand[0], 10);
      FLastMs := MS;
    end
    else
    begin
      // same ms -> increment 80-bit randomness; if overflow (wrap to zero), wait next ms
      Inc80(FLastRand);
      if (FLastRand[0] or FLastRand[1] or FLastRand[2] or FLastRand[3] or FLastRand[4] or
          FLastRand[5] or FLastRand[6] or FLastRand[7] or FLastRand[8] or FLastRand[9]) = 0 then
      begin
        repeat
          MS := NowUnixMs;
          SleepFor(TDuration.FromMs(1));
        until MS > FLastMs;
        FLastMs := MS;
        SecureRandomFill(FLastRand[0], 10);
      end;
    end;

    // compose ULID raw (48-bit timestamp big-endian + 80-bit randomness)
    A[0] := Byte((QWord(FLastMs) shr 40) and $FF);
    A[1] := Byte((QWord(FLastMs) shr 32) and $FF);
    A[2] := Byte((QWord(FLastMs) shr 24) and $FF);
    A[3] := Byte((QWord(FLastMs) shr 16) and $FF);
    A[4] := Byte((QWord(FLastMs) shr 8) and $FF);
    A[5] := Byte(QWord(FLastMs) and $FF);
    Move(FLastRand[0], A[6], 10);
    Result := A;
  finally
    FLock.Release;
  end;
end;

function TUlidMonotonic.Next: string;
var R: TUlid128;
begin
  R := NextRaw;
  UlidToString(R, Result);
end;

end.

