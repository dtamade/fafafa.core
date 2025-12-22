{
  fafafa.core.id.ulid — ULID generator and codec (Crockford Base32)

  - ULID layout: 48-bit Unix ms timestamp (big-endian) + 80-bit randomness
  - Text form: 26 uppercase chars, Crockford Base32 (no I,L,O,U)
  - Cross‑platform CSPRNG via fafafa.core.crypto.random

  Notes
  - This is the basic (non‑monotonic) variant. A monotonic generator can be added later.
}

unit fafafa.core.id.ulid;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, DateUtils,
  fafafa.core.crypto.random,
  fafafa.core.time,
  fafafa.core.id.time;

type
  TUlid128 = array[0..15] of Byte;

{ Generation }
function UlidNow_Raw: TUlid128; overload;
function Ulid_Raw(ATimestampMs: Int64): TUlid128; overload;
function Ulid: string; overload;
procedure Ulid(out AOut: string); overload;

{ Codec }
procedure UlidToChars(const A: TUlid128; Dest: PChar); inline;
procedure UlidAppend(const A: TUlid128; var S: string); inline;
procedure UlidToString(const A: TUlid128; out S: string);
function UlidToString(const A: TUlid128): string;
function TryParseUlid(const S: string; out A: TUlid128): Boolean;
function TryParseUlidStrict(const S: string; out A: TUlid128): Boolean;
function Ulid_TimestampMs(const S: string): Int64; // -1 if invalid

{ Batch text helpers }
procedure UlidFillTextN(var Dest: array of PChar);
procedure UlidFillTextStringsN(var Dest: array of string);

implementation

const
  // Crockford Base32 alphabet (upper‑case, no I,L,O,U)
  ULID_ALPHABET: PChar = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

// Use shared time helper from fafafa.core.id.time

procedure SecureRandomFill(var Buf; Count: SizeInt);
begin
  GetSecureRandom.GetBytes(Buf, Count);
end;

function FindBase32Val(C: Char; out V: Byte): Boolean; inline;
var
  U: Char;
  I: Integer;
begin
  // normalize to upper
  if (C >= 'a') and (C <= 'z') then
    U := Chr(Ord(C) - Ord('a') + Ord('A'))
  else
    U := C;
  // tolerant mapping for ambiguous letters per Crockford (optional):
  if U = 'O' then U := '0';
  if U = 'I' then U := '1';
  if U = 'L' then U := '1';
  // find index
  for I := 0 to 31 do
    if ULID_ALPHABET[I] = U then
    begin
      V := I; Exit(True);
    end;
  V := 0; Result := False;
end;

procedure PutBase32Char(Index: Byte; var P: PChar); inline;
begin
  P^ := ULID_ALPHABET[Index]; Inc(P);
end;

procedure UlidToChars(const A: TUlid128; Dest: PChar); inline;
var
  TS: QWord;
  I: Integer;
  P: PChar;
  Rand: array[0..9] of Byte;
begin
  P := Dest;
  // timestamp (48-bit big-endian)
  TS := (QWord(A[0]) shl 40) or (QWord(A[1]) shl 32) or (QWord(A[2]) shl 24) or
        (QWord(A[3]) shl 16) or (QWord(A[4]) shl 8) or QWord(A[5]);
  // first 10 chars: most-significant-first base32 digits
  for I := 9 downto 0 do
  begin
    P[I] := ULID_ALPHABET[TS mod 32];
    TS := TS div 32;
  end;
  Inc(P, 10);
  // random 80 bits A[6..15] -> 16 chars, 5 bits each
  Move(A[6], Rand[0], 10);
  // unpack 80 bits as 16 groups of 5 bits (big-endian)
  // indexes are arranged to avoid per-bit loops
  // group 0..15
  P^ := ULID_ALPHABET[(Rand[0] shr 3) and $1F]; Inc(P);
  P^ := ULID_ALPHABET[((Rand[0] shl 2) or (Rand[1] shr 6)) and $1F]; Inc(P);
  P^ := ULID_ALPHABET[(Rand[1] shr 1) and $1F]; Inc(P);
  P^ := ULID_ALPHABET[((Rand[1] shl 4) or (Rand[2] shr 4)) and $1F]; Inc(P);
  P^ := ULID_ALPHABET[((Rand[2] shl 1) or (Rand[3] shr 7)) and $1F]; Inc(P);
  P^ := ULID_ALPHABET[(Rand[3] shr 2) and $1F]; Inc(P);
  P^ := ULID_ALPHABET[((Rand[3] shl 3) or (Rand[4] shr 5)) and $1F]; Inc(P);
  P^ := ULID_ALPHABET[(Rand[4]) and $1F]; Inc(P);
  P^ := ULID_ALPHABET[(Rand[5] shr 3) and $1F]; Inc(P);
  P^ := ULID_ALPHABET[((Rand[5] shl 2) or (Rand[6] shr 6)) and $1F]; Inc(P);
  P^ := ULID_ALPHABET[(Rand[6] shr 1) and $1F]; Inc(P);
  P^ := ULID_ALPHABET[((Rand[6] shl 4) or (Rand[7] shr 4)) and $1F]; Inc(P);
  P^ := ULID_ALPHABET[((Rand[7] shl 1) or (Rand[8] shr 7)) and $1F]; Inc(P);
  P^ := ULID_ALPHABET[(Rand[8] shr 2) and $1F]; Inc(P);
  P^ := ULID_ALPHABET[((Rand[8] shl 3) or (Rand[9] shr 5)) and $1F]; Inc(P);
  P^ := ULID_ALPHABET[(Rand[9]) and $1F]; Inc(P);
end;

procedure UlidToString(const A: TUlid128; out S: string);
begin
  SetLength(S, 26);
  UlidToChars(A, PChar(S));
end;

function UlidToString(const A: TUlid128): string;
begin
  UlidToString(A, Result);
end;

procedure UlidAppend(const A: TUlid128; var S: string); inline;
var L: SizeInt; P: PChar;
begin
  L := Length(S);
  SetLength(S, L + 26);
  P := PChar(S);
  Inc(P, L);
  UlidToChars(A, P);
end;

function TryParseUlid(const S: string; out A: TUlid128): Boolean;
var
  I: Integer;
  TS: QWord;
  V: Byte;
  RandBytes: array[0..9] of Byte;
  procedure WriteBit(Bytes: PByte; BitIndex, TotalBits, BitValue: Integer);
  var
    ByteIndex, BitInByte: Integer;
  begin
    if (BitIndex < 0) or (BitIndex >= TotalBits) then Exit;
    ByteIndex := BitIndex div 8;
    BitInByte := 7 - (BitIndex mod 8);
    if BitValue <> 0 then
      Bytes[ByteIndex] := Bytes[ByteIndex] or (1 shl BitInByte)
    else
      Bytes[ByteIndex] := Bytes[ByteIndex] and not (1 shl BitInByte);
  end;
begin
  Result := False;
  if Length(S) <> 26 then Exit;

  // parse timestamp (10 chars -> 48-bit)
  TS := 0;
  for I := 1 to 10 do
  begin
    if not FindBase32Val(S[I], V) then Exit;
    TS := TS * 32 + V;
  end;
  A[0] := Byte((TS shr 40) and $FF);
  A[1] := Byte((TS shr 32) and $FF);
  A[2] := Byte((TS shr 24) and $FF);
  A[3] := Byte((TS shr 16) and $FF);
  A[4] := Byte((TS shr 8) and $FF);
  A[5] := Byte(TS and $FF);

  // parse random (16 chars -> 80 bits)
  FillChar(RandBytes[0], SizeOf(RandBytes), 0);
  for I := 0 to 15 do
  begin
    if not FindBase32Val(S[11 + I], V) then Exit;
    // write 5 bits at offset I*5
    WriteBit(@RandBytes[0], I*5 + 0, 80, (V shr 4) and 1);
    WriteBit(@RandBytes[0], I*5 + 1, 80, (V shr 3) and 1);
    WriteBit(@RandBytes[0], I*5 + 2, 80, (V shr 2) and 1);
    WriteBit(@RandBytes[0], I*5 + 3, 80, (V shr 1) and 1);
    WriteBit(@RandBytes[0], I*5 + 4, 80, (V shr 0) and 1);
  end;
  Move(RandBytes[0], A[6], 10);

  Result := True;
end;

function Ulid_TimestampMs(const S: string): Int64;
var
  I: Integer; V: Byte; TS: QWord;
begin
  if Length(S) <> 26 then Exit(-1);
  TS := 0;
  for I := 1 to 10 do
  begin
    if not FindBase32Val(S[I], V) then Exit(-1);
    TS := TS * 32 + V;
  end;
  Result := Int64(TS);
end;

function TryParseUlidStrict(const S: string; out A: TUlid128): Boolean;
var I: Integer; U: Char;
begin
  Result := False;
  if Length(S) <> 26 then Exit;
  for I := 1 to 26 do
  begin
    U := S[I];
    if (U >= 'a') and (U <= 'z') then U := Chr(Ord(U) - Ord('a') + Ord('A'));
    // reject O/I/L/U per strict Crockford
    if (U = 'O') or (U = 'I') or (U = 'L') or (U = 'U') then Exit(False);
    // must be in alphabet
    if Pos(U, string(ULID_ALPHABET)) = 0 then Exit(False);
  end;
  // reuse tolerant parser for actual decoding after strict precheck
  Result := TryParseUlid(S, A);
end;

procedure UlidFillTextN(var Dest: array of PChar);
var i, n: SizeInt; R: TUlid128;
begin
  n := High(Dest) + 1; if n <= 0 then Exit;
  for i := 0 to n-1 do begin R := UlidNow_Raw; UlidToChars(R, Dest[i]); end;
end;

procedure UlidFillTextStringsN(var Dest: array of string);
var i, n: SizeInt; S: string;
begin
  n := High(Dest) + 1; if n <= 0 then Exit;
  for i := 0 to n-1 do begin S := Ulid; Dest[i] := S; end;
end;

function Ulid_Raw(ATimestampMs: Int64): TUlid128;
var
  TS: QWord;
begin
  TS := QWord(ATimestampMs);
  Result[0] := Byte((TS shr 40) and $FF);
  Result[1] := Byte((TS shr 32) and $FF);
  Result[2] := Byte((TS shr 24) and $FF);
  Result[3] := Byte((TS shr 16) and $FF);
  Result[4] := Byte((TS shr 8) and $FF);
  Result[5] := Byte(TS and $FF);
  SecureRandomFill(Result[6], 10);
end;

function UlidNow_Raw: TUlid128;
begin
  Result := Ulid_Raw(NowUnixMs);
end;

function Ulid: string;
begin
  UlidToString(UlidNow_Raw, Result);
end;

procedure Ulid(out AOut: string);
begin
  AOut := Ulid;
end;

end.

