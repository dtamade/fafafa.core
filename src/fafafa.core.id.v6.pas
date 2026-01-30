{
  fafafa.core.id.v6 — UUID v6 (Time-ordered, reordered v1)

  - RFC 9562 compliant UUID version 6
  - Time-sortable (better than v1 for database indexes)
  - 60-bit timestamp (100ns since 1582-10-15)
  - 14-bit clock sequence + 48-bit node
}

unit fafafa.core.id.v6;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, DateUtils,
  fafafa.core.id,
  fafafa.core.crypto.random;

type
  { UUID v6 generation options }
  TUuidV6Options = record
    Node: array[0..5] of Byte;    // 48-bit node ID (MAC or random)
    ClockSeq: Word;               // 14-bit clock sequence
    UseRandomNode: Boolean;       // Use random node instead of specified
  end;

{ UUID v6 generation }
function UuidV6: TUuid128;
function UuidV6(const Options: TUuidV6Options): TUuid128;
function UuidV6_WithTimestamp(Timestamp100ns: Int64): TUuid128;

{ String versions }
function UuidV6Str: string;

{ Extract timestamp from UUID v6 }
function UuidV6_Timestamp(const U: TUuid128): TDateTime;
function UuidV6_Timestamp100ns(const U: TUuid128): Int64;

{ Check if UUID is v6 }
function IsUuidV6(const U: TUuid128): Boolean;

{ Default options }
function DefaultUuidV6Options: TUuidV6Options;

implementation

const
  // Gregorian calendar epoch: October 15, 1582
  // Difference from Unix epoch (Jan 1, 1970) in 100ns intervals
  GREGORIAN_UNIX_DIFF = Int64(122192928000000000);

var
  GClockSeq: Word = 0;
  GNode: array[0..5] of Byte;
  GInitialized: Boolean = False;

procedure InitializeDefaults;
var
  RandBytes: array[0..7] of Byte;
begin
  if GInitialized then Exit;

  // Initialize random clock sequence and node
  GetSecureRandom.GetBytes(RandBytes, 8);

  GClockSeq := (Word(RandBytes[0]) shl 8 or RandBytes[1]) and $3FFF;

  // Set multicast bit in node to indicate random node (RFC requirement)
  GNode[0] := RandBytes[2] or $01;  // Set multicast bit
  GNode[1] := RandBytes[3];
  GNode[2] := RandBytes[4];
  GNode[3] := RandBytes[5];
  GNode[4] := RandBytes[6];
  GNode[5] := RandBytes[7];

  GInitialized := True;
end;

function DefaultUuidV6Options: TUuidV6Options;
begin
  InitializeDefaults;
  Result.Node := GNode;
  Result.ClockSeq := GClockSeq;
  Result.UseRandomNode := True;
end;

function GetTimestamp100ns: Int64;
var
  NowDT: TDateTime;
  UnixMs: Int64;
begin
  NowDT := Now;
  UnixMs := DateTimeToUnix(NowDT, False) * 1000 + MilliSecondOf(NowDT);
  // Convert to 100ns intervals and add Gregorian offset
  Result := UnixMs * 10000 + GREGORIAN_UNIX_DIFF;
end;

function UuidV6_WithTimestamp(Timestamp100ns: Int64): TUuid128;
var
  ClockSeq: Word;
  Node: array[0..5] of Byte;
begin
  InitializeDefaults;
  ClockSeq := GClockSeq;
  Node := GNode;

  // UUID v6 layout (reordered v1):
  // time_high (32 bits) | time_mid (16 bits) | version (4 bits) | time_low (12 bits) |
  // variant (2 bits) | clock_seq (14 bits) | node (48 bits)

  // Bytes 0-3: time_high (bits 28-59 of timestamp)
  Result[0] := Byte((Timestamp100ns shr 52) and $FF);
  Result[1] := Byte((Timestamp100ns shr 44) and $FF);
  Result[2] := Byte((Timestamp100ns shr 36) and $FF);
  Result[3] := Byte((Timestamp100ns shr 28) and $FF);

  // Bytes 4-5: time_mid (bits 12-27 of timestamp)
  Result[4] := Byte((Timestamp100ns shr 20) and $FF);
  Result[5] := Byte((Timestamp100ns shr 12) and $FF);

  // Byte 6: version (0110) + time_low high nibble (bits 8-11 of timestamp)
  Result[6] := $60 or Byte((Timestamp100ns shr 8) and $0F);

  // Byte 7: time_low low byte (bits 0-7 of timestamp)
  Result[7] := Byte(Timestamp100ns and $FF);

  // Byte 8: variant (10) + clock_seq high 6 bits
  Result[8] := $80 or Byte((ClockSeq shr 8) and $3F);

  // Byte 9: clock_seq low 8 bits
  Result[9] := Byte(ClockSeq and $FF);

  // Bytes 10-15: node (48 bits)
  Result[10] := Node[0];
  Result[11] := Node[1];
  Result[12] := Node[2];
  Result[13] := Node[3];
  Result[14] := Node[4];
  Result[15] := Node[5];
end;

function UuidV6: TUuid128;
begin
  Result := UuidV6_WithTimestamp(GetTimestamp100ns);
end;

function UuidV6(const Options: TUuidV6Options): TUuid128;
var
  Timestamp100ns: Int64;
  RandBytes: array[0..5] of Byte;
  Node: array[0..5] of Byte;
begin
  Timestamp100ns := GetTimestamp100ns;

  if Options.UseRandomNode then
  begin
    GetSecureRandom.GetBytes(RandBytes, 6);
    Node[0] := RandBytes[0] or $01;  // Set multicast bit
    Node[1] := RandBytes[1];
    Node[2] := RandBytes[2];
    Node[3] := RandBytes[3];
    Node[4] := RandBytes[4];
    Node[5] := RandBytes[5];
  end
  else
    Node := Options.Node;

  // Build UUID v6
  Result[0] := Byte((Timestamp100ns shr 52) and $FF);
  Result[1] := Byte((Timestamp100ns shr 44) and $FF);
  Result[2] := Byte((Timestamp100ns shr 36) and $FF);
  Result[3] := Byte((Timestamp100ns shr 28) and $FF);
  Result[4] := Byte((Timestamp100ns shr 20) and $FF);
  Result[5] := Byte((Timestamp100ns shr 12) and $FF);
  Result[6] := $60 or Byte((Timestamp100ns shr 8) and $0F);
  Result[7] := Byte(Timestamp100ns and $FF);
  Result[8] := $80 or Byte((Options.ClockSeq shr 8) and $3F);
  Result[9] := Byte(Options.ClockSeq and $FF);
  Result[10] := Node[0];
  Result[11] := Node[1];
  Result[12] := Node[2];
  Result[13] := Node[3];
  Result[14] := Node[4];
  Result[15] := Node[5];
end;

function UuidV6Str: string;
begin
  Result := UuidToString(UuidV6);
end;

function UuidV6_Timestamp100ns(const U: TUuid128): Int64;
begin
  // Extract 60-bit timestamp from UUID v6 layout
  Result :=
    (Int64(U[0]) shl 52) or
    (Int64(U[1]) shl 44) or
    (Int64(U[2]) shl 36) or
    (Int64(U[3]) shl 28) or
    (Int64(U[4]) shl 20) or
    (Int64(U[5]) shl 12) or
    (Int64(U[6] and $0F) shl 8) or
    Int64(U[7]);
end;

function UuidV6_Timestamp(const U: TUuid128): TDateTime;
var
  Timestamp100ns: Int64;
  UnixMs: Int64;
begin
  Timestamp100ns := UuidV6_Timestamp100ns(U);
  // Convert from Gregorian 100ns to Unix milliseconds
  UnixMs := (Timestamp100ns - GREGORIAN_UNIX_DIFF) div 10000;
  Result := UnixToDateTime(UnixMs div 1000, False) +
            EncodeTime(0, 0, 0, UnixMs mod 1000);
end;

function IsUuidV6(const U: TUuid128): Boolean;
begin
  // Check version = 6 (0110 in high nibble of byte 6)
  // Check variant = RFC 4122 (10 in high 2 bits of byte 8)
  Result := ((U[6] shr 4) = 6) and ((U[8] shr 6) = 2);
end;

end.
