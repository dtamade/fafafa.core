{
  fafafa.core.id.ksuid.ms — High-precision KSUID (4ms resolution)

  - Standard KSUID: 1 second precision, 16 bytes random
  - KsuidMs: 4ms precision (sacrifices 1 byte random for extra time bits)
  - Compatible with standard KSUID format (27 chars base62)
  - Inspired by svix-ksuid crate
}

unit fafafa.core.id.ksuid.ms;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.id.ksuid,
  fafafa.core.crypto.random,
  fafafa.core.id.time;

type
  { TKsuidMs - High-precision KSUID with 4ms resolution }
  TKsuidMs160 = array[0..19] of Byte;  // Same size as standard KSUID

  { Monotonic KsuidMs generator }
  IKsuidMsGenerator = interface
    ['{B8C9D0E1-2F3A-4B5C-6D7E-8F9A0B1C2D3E}']
    function Next: string;
    function NextRaw: TKsuidMs160;
    function TimestampMs: Int64;
  end;

  TKsuidMsGenerator = class(TInterfacedObject, IKsuidMsGenerator)
  private
    FLastMs: Int64;
    FCounter: Byte;       // 8-bit sub-millisecond counter (0-255)
    FRandom: array[0..13] of Byte;  // 112 bits random (14 bytes, reduced from 16)

    procedure Reseed;
  public
    constructor Create;

    function Next: string;
    function NextRaw: TKsuidMs160;
    function NextRawAt(Ms: Int64): TKsuidMs160;
    function TimestampMs: Int64;
  end;

{ Factory functions }
function CreateKsuidMsGenerator: IKsuidMsGenerator;

{ One-shot generation }
function KsuidMsNow: TKsuidMs160;
function KsuidMsNowStr: string;

{ Conversion }
function KsuidMsToString(const K: TKsuidMs160): string;
function KsuidMsFromString(const S: string): TKsuidMs160;

{ Extract timestamp }
function KsuidMs_TimestampMs(const K: TKsuidMs160): Int64;
function KsuidMs_Timestamp(const K: TKsuidMs160): TDateTime;

implementation

uses
  DateUtils;

const
  // KSUID epoch: May 13, 2014 (same as standard KSUID)
  KSUID_EPOCH = 1400000000;

  // Base62 alphabet
  BASE62_ALPHABET = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

function CreateKsuidMsGenerator: IKsuidMsGenerator;
begin
  Result := TKsuidMsGenerator.Create;
end;

{ TKsuidMsGenerator }

constructor TKsuidMsGenerator.Create;
begin
  inherited Create;
  FLastMs := -1;
  FCounter := 0;
  Reseed;
end;

procedure TKsuidMsGenerator.Reseed;
begin
  GetSecureRandom.GetBytes(FRandom, 14);
  FCounter := 0;
end;

function TKsuidMsGenerator.NextRawAt(Ms: Int64): TKsuidMs160;
var
  SecondsSinceEpoch: UInt32;
  SubSecondMs: Word;  // 0-999
begin
  if Ms > FLastMs then
  begin
    FLastMs := Ms;
    Reseed;
  end
  else if Ms = FLastMs then
  begin
    Inc(FCounter);
    if FCounter = 0 then
    begin
      // Counter overflow - wait for next ms
      repeat
        Sleep(1);
        Ms := NowUnixMs;
      until Ms > FLastMs;
      FLastMs := Ms;
      Reseed;
    end;
  end
  else
  begin
    // Clock rollback - advance
    FLastMs := FLastMs + 1;
    Ms := FLastMs;
    Reseed;
  end;

  // Layout:
  // Bytes 0-3: Seconds since KSUID epoch (big-endian, 32 bits)
  // Byte 4: Sub-second counter + high bits of ms fraction
  // Byte 5: Low bits of ms fraction + counter extension
  // Bytes 6-19: Random (14 bytes = 112 bits)

  SecondsSinceEpoch := UInt32((Ms div 1000) - KSUID_EPOCH);
  SubSecondMs := Ms mod 1000;  // 0-999

  // 4 bytes timestamp (seconds)
  Result[0] := Byte((SecondsSinceEpoch shr 24) and $FF);
  Result[1] := Byte((SecondsSinceEpoch shr 16) and $FF);
  Result[2] := Byte((SecondsSinceEpoch shr 8) and $FF);
  Result[3] := Byte(SecondsSinceEpoch and $FF);

  // 2 bytes for ms precision: 10 bits for ms (0-999) + 6 bits padding/counter
  // High byte: ms >> 2 (high 8 bits of 10-bit ms value)
  // Low byte: (ms & 3) << 6 | counter & 0x3F
  Result[4] := Byte(SubSecondMs shr 2);
  Result[5] := Byte(((SubSecondMs and $03) shl 6) or (FCounter and $3F));

  // 14 bytes random
  Move(FRandom[0], Result[6], 14);
end;

function TKsuidMsGenerator.NextRaw: TKsuidMs160;
begin
  Result := NextRawAt(NowUnixMs);
end;

function TKsuidMsGenerator.Next: string;
begin
  Result := KsuidMsToString(NextRaw);
end;

function TKsuidMsGenerator.TimestampMs: Int64;
begin
  Result := FLastMs;
end;

{ Conversion functions }

function KsuidMsToString(const K: TKsuidMs160): string;
var
  I, J: Integer;
  Num: array[0..19] of Byte;
  Quotient, Remainder: Integer;
  Chars: array[0..26] of Char;
  CharIdx: Integer;
begin
  // Copy bytes (KSUID is 20 bytes = 160 bits)
  Move(K[0], Num[0], 20);

  // Convert to base62 (27 characters)
  CharIdx := 26;
  while CharIdx >= 0 do
  begin
    // Divide by 62
    Remainder := 0;
    for I := 0 to 19 do
    begin
      Quotient := (Remainder shl 8) + Num[I];
      Num[I] := Quotient div 62;
      Remainder := Quotient mod 62;
    end;
    Chars[CharIdx] := BASE62_ALPHABET[Remainder + 1];
    Dec(CharIdx);
  end;

  SetString(Result, @Chars[0], 27);
end;

function KsuidMsFromString(const S: string): TKsuidMs160;
var
  I, J: Integer;
  CharVal: Integer;
  Num: array[0..19] of Byte;
  Carry: Integer;
begin
  if Length(S) <> 27 then
    raise Exception.Create('Invalid KSUID string length');

  FillChar(Num[0], 20, 0);

  // Convert from base62
  for I := 1 to 27 do
  begin
    CharVal := Pos(S[I], BASE62_ALPHABET) - 1;
    if CharVal < 0 then
      raise Exception.CreateFmt('Invalid character in KSUID: %s', [S[I]]);

    // Multiply by 62 and add
    Carry := CharVal;
    for J := 19 downto 0 do
    begin
      Carry := Carry + Num[J] * 62;
      Num[J] := Carry and $FF;
      Carry := Carry shr 8;
    end;
  end;

  Move(Num[0], Result[0], 20);
end;

function KsuidMs_TimestampMs(const K: TKsuidMs160): Int64;
var
  Seconds: UInt32;
  SubMs: Word;
begin
  // Extract seconds
  Seconds := (UInt32(K[0]) shl 24) or (UInt32(K[1]) shl 16) or
             (UInt32(K[2]) shl 8) or UInt32(K[3]);

  // Extract sub-second ms (10 bits)
  SubMs := (Word(K[4]) shl 2) or (Word(K[5]) shr 6);

  Result := (Int64(Seconds) + KSUID_EPOCH) * 1000 + SubMs;
end;

function KsuidMs_Timestamp(const K: TKsuidMs160): TDateTime;
var
  Ms: Int64;
begin
  Ms := KsuidMs_TimestampMs(K);
  Result := UnixToDateTime(Ms div 1000, False) + EncodeTime(0, 0, 0, Ms mod 1000);
end;

function KsuidMsNow: TKsuidMs160;
var
  Gen: TKsuidMsGenerator;
begin
  Gen := TKsuidMsGenerator.Create;
  try
    Result := Gen.NextRaw;
  finally
    Gen.Free;
  end;
end;

function KsuidMsNowStr: string;
begin
  Result := KsuidMsToString(KsuidMsNow);
end;

end.
