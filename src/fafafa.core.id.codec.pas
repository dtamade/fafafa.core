{
  fafafa.core.id.codec — ID encoders (Base64URL, Base58 for ULID/KSUID)

  - Base64URL (no padding) for UUID (16 bytes -> 22 chars)
  - Base58 (Bitcoin alphabet) for ULID (16 bytes) / KSUID (20 bytes)
}

unit fafafa.core.id.codec;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.id,
  fafafa.core.id.ulid,
  fafafa.core.id.ksuid;

{ UUID <-> Base64URL (no padding) }
function UuidToBase64Url(const A: TUuid128): string;
function TryParseUuidBase64Url(const S: string; out A: TUuid128): Boolean;
function TryParseUuidBase64UrlStrict(const S: string; out A: TUuid128): Boolean;
// Zero-allocation format
procedure UuidToBase64UrlChars(const A: TUuid128; Dest: PChar); inline; // 22 chars

{ ULID/KSUID <-> Base58 (Bitcoin alphabet) }
function UlidToBase58(const A: TUlid128): string;
function TryParseUlidBase58(const S: string; out A: TUlid128): Boolean;
function TryParseUlidBase58Strict(const S: string; out A: TUlid128): Boolean;
function KsuidToBase58(const A: TKsuid160): string;
function TryParseKsuidBase58(const S: string; out A: TKsuid160): Boolean;
function TryParseKsuidBase58Strict(const S: string; out A: TKsuid160): Boolean;

implementation

const
  B64URL: PChar = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
  B58: PChar = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

function UuidToBase64Url(const A: TUuid128): string;
var
  i: Integer;
  x: LongWord;
  p: PChar;
begin
  // 16 bytes -> 22 chars (no padding)
  SetLength(Result, 22);
  p := PChar(Result);
  // process 15 bytes in 5 blocks of 3 -> 20 chars, then last 1 byte -> 2 chars
  for i := 0 to 4 do
  begin
    x := (LongWord(A[i*3]) shl 16) or (LongWord(A[i*3+1]) shl 8) or LongWord(A[i*3+2]);
    p^ := B64URL[(x shr 18) and $3F]; Inc(p);
    p^ := B64URL[(x shr 12) and $3F]; Inc(p);
    p^ := B64URL[(x shr 6) and $3F]; Inc(p);
    p^ := B64URL[x and $3F]; Inc(p);
  end;
  // last byte (index 15)
  x := LongWord(A[15]);
  p^ := B64URL[(x shr 2) and $3F]; Inc(p);
  p^ := B64URL[(x and 3) shl 4]; Inc(p);
end;

procedure UuidToBase64UrlChars(const A: TUuid128; Dest: PChar); inline;
var
  i: Integer; x: LongWord; p: PChar;
begin
  p := Dest;
  for i := 0 to 4 do
  begin
    x := (LongWord(A[i*3]) shl 16) or (LongWord(A[i*3+1]) shl 8) or LongWord(A[i*3+2]);
    p^ := B64URL[(x shr 18) and $3F]; Inc(p);
    p^ := B64URL[(x shr 12) and $3F]; Inc(p);
    p^ := B64URL[(x shr 6) and $3F]; Inc(p);
    p^ := B64URL[x and $3F]; Inc(p);
  end;
  x := LongWord(A[15]);
  p^ := B64URL[(x shr 2) and $3F]; Inc(p);
  p^ := B64URL[(x and 3) shl 4];
end;

  p^ := B64URL[(x and 3) shl 4]; Inc(p);
end;

function B64UrlVal(C: Char): Integer; inline;
var k: Integer;
begin
  for k := 0 to 63 do if B64URL[k] = C then Exit(k);
  Result := -1;
end;

function TryParseUuidBase64Url(const S: string; out A: TUuid128): Boolean;
var
  T: string;
  i, val, idx, outIndex: Integer;
begin
  // accept 22-char form (no padding) or 24 with '=='
  if (Length(S) = 24) and (S[23] = '=') and (S[24] = '=') then
    T := Copy(S, 1, 22)
  else
    T := S;
  if Length(T) <> 22 then Exit(False);
  // decode
  FillChar(A, SizeOf(A), 0);
  outIndex := 0;
  // decode first 20 chars -> 15 bytes
  i := 1;
  while (i <= 20) do
  begin
    idx := B64UrlVal(T[i]); if idx < 0 then Exit(False); val := idx shl 18; Inc(i);
    idx := B64UrlVal(T[i]); if idx < 0 then Exit(False); val := val or (idx shl 12); Inc(i);
    idx := B64UrlVal(T[i]); if idx < 0 then Exit(False); val := val or (idx shl 6); Inc(i);
    idx := B64UrlVal(T[i]); if idx < 0 then Exit(False); val := val or idx; Inc(i);
    A[outIndex] := Byte((val shr 16) and $FF); Inc(outIndex);
    A[outIndex] := Byte((val shr 8) and $FF); Inc(outIndex);
    A[outIndex] := Byte(val and $FF); Inc(outIndex);
  end;
  // last 2 chars -> 1 byte
  idx := B64UrlVal(T[21]); if idx < 0 then Exit(False);
  val := idx shl 2;
  idx := B64UrlVal(T[22]); if idx < 0 then Exit(False);
  val := val or (idx shr 4);
  if outIndex <> 15 then Exit(False);
  A[outIndex] := Byte(val and $FF);
  Result := True;
end;

function TryParseUuidBase64UrlStrict(const S: string; out A: TUuid128): Boolean;
var
  T: string;
  i, val, idx, outIndex: Integer;
begin
  // accept 22-char form (no padding) or 24 with '==' only
  if (Length(S) = 24) and (S[23] = '=') and (S[24] = '=') then
    T := Copy(S, 1, 22)
  else
    T := S;
  if Length(T) <> 22 then Exit(False);
  FillChar(A, SizeOf(A), 0);
  outIndex := 0;
  // first 20 chars -> 15 bytes (same as relaxed)
  i := 1;
  while (i <= 20) do
  begin
    idx := B64UrlVal(T[i]); if idx < 0 then Exit(False); val := idx shl 18; Inc(i);
    idx := B64UrlVal(T[i]); if idx < 0 then Exit(False); val := val or (idx shl 12); Inc(i);
    idx := B64UrlVal(T[i]); if idx < 0 then Exit(False); val := val or (idx shl 6); Inc(i);
    idx := B64UrlVal(T[i]); if idx < 0 then Exit(False); val := val or idx; Inc(i);
    A[outIndex] := Byte((val shr 16) and $FF); Inc(outIndex);
    A[outIndex] := Byte((val shr 8) and $FF); Inc(outIndex);
    A[outIndex] := Byte(val and $FF); Inc(outIndex);
  end;
  // last 2 chars -> 1 byte; enforce that last char contributes only high 4 bits
  idx := B64UrlVal(T[21]); if idx < 0 then Exit(False);
  val := idx shl 2;
  idx := B64UrlVal(T[22]); if idx < 0 then Exit(False);
  // last char's low 4 bits must be zero (since 16 bytes -> 128 bits -> last 2 chars carry 8+? bits)
  if (idx and $0F) <> 0 then Exit(False);
  val := val or (idx shr 4);
  if outIndex <> 15 then Exit(False);
  A[outIndex] := Byte(val and $FF);
  Result := True;
end;

procedure BigDivModBase(var Bytes: array of Byte; Len: Integer; Base: Integer; out Remainder: Integer);
var
  k: Integer; cur: Integer;
begin
  cur := 0;
  for k := 0 to Len-1 do
  begin
    cur := (cur shl 8) or Bytes[k];
    Bytes[k] := Byte(cur div Base);
    cur := cur mod Base;
  end;
  Remainder := cur;
end;

procedure BigMulAddBase(var Bytes: array of Byte; Len, Base, Digit: Integer);
var
  k, cur: Integer;
begin
  cur := Digit;
  for k := Len-1 downto 0 do
  begin
    cur := Bytes[k] * Base + cur;
    Bytes[k] := cur and $FF;
    cur := cur shr 8;
  end;
end;

function Base58EncodeBytes(const Buf; Len: Integer): string;
var
  tmp: array[0..255] of Byte;
  i, zeros, n, rem: Integer;
  digits: array[0..511] of Byte; // enough for typical sizes
begin
  if (Len < 0) or (Len > 256) then Exit('');
  Move(Buf, tmp[0], Len);
  zeros := 0;
  while (zeros < Len) and (tmp[zeros] = 0) do Inc(zeros);
  n := 0;
  while zeros < Len do
  begin
    BigDivModBase(tmp, Len, 58, rem);
    digits[n] := rem; Inc(n);
    while (zeros < Len) and (tmp[zeros] = 0) do Inc(zeros);
  end;
  // compose string: leading '1's for zeros, then digits reversed
  SetLength(Result, zeros + n);
  for i := 1 to zeros do Result[i] := B58[0];
  for i := 0 to n-1 do Result[zeros + i + 1] := B58[ digits[n-1-i] ];
end;

function Base58DecodeToFixed(const S: string; out OutBuf; WantLen: Integer): Boolean;
var
  i, zeros, val, len: Integer;
  tmp: array[0..255] of Byte;
  function B58Val(C: Char; out V: Integer): Boolean; inline;
  var k: Integer;
  begin
    for k := 0 to 57 do if B58[k] = C then begin V := k; Exit(True); end;
    V := -1; Result := False;
  end;
begin
  if (WantLen < 1) or (WantLen > 256) then Exit(False);
  FillChar(tmp[0], WantLen, 0);
  len := WantLen;
  zeros := 0;
  while (zeros < Length(S)) and (S[zeros+1] = B58[0]) do Inc(zeros);
  for i := zeros+1 to Length(S) do
  begin
    if not B58Val(S[i], val) then Exit(False);
    BigMulAddBase(tmp, len, 58, val);
  end;
  // tmp now has the decoded big-endian value truncated to 'len' bytes; handle leading zeros
  // Reconstruct full array: count leading zero bytes implied by '1's
  // But since we fixed len, we just write tmp to output
  Move(tmp[0], OutBuf, WantLen);
  Result := True;
end;

function UlidToBase58(const A: TUlid128): string;
begin
  Result := Base58EncodeBytes(A, SizeOf(A));
end;

function TryParseUlidBase58(const S: string; out A: TUlid128): Boolean;
begin
  Result := Base58DecodeToFixed(S, A, SizeOf(A));
end;

function TryParseUlidBase58Strict(const S: string; out A: TUlid128): Boolean;
var i: Integer; c: Char;
begin
  Result := False;
  if (Length(S) < 22) or (Length(S) > 23) then Exit;
  for i := 1 to Length(S) do begin c := S[i]; if Pos(c, string(B58)) = 0 then Exit; end;
  Result := TryParseUlidBase58(S, A);
end;

function TryParseKsuidBase58Strict(const S: string; out A: TKsuid160): Boolean;
var i: Integer; c: Char;
begin
  Result := False;
  if Length(S) <> 27 then Exit;
  for i := 1 to Length(S) do begin c := S[i]; if Pos(c, string(B58)) = 0 then Exit; end;
  Result := TryParseKsuidBase58(S, A);
end;

function KsuidToBase58(const A: TKsuid160): string;
begin
  Result := Base58EncodeBytes(A, SizeOf(A));

function TryParseUlidBase58Strict(const S: string; out A: TUlid128): Boolean;
var i: Integer; c: Char;
begin
  Result := False;
  // 128-bit ULID encoded in base58 的长度通常为 22 或 23，严格模式固定要求 22..23 之间并校验字符集
  if (Length(S) < 22) or (Length(S) > 23) then Exit;
  for i := 1 to Length(S) do begin c := S[i]; if Pos(c, string(B58)) = 0 then Exit; end;
  Result := TryParseUlidBase58(S, A);
end;

function TryParseKsuidBase58Strict(const S: string; out A: TKsuid160): Boolean;
var i: Integer; c: Char;
begin
  Result := False;
  // 160-bit KSUID 在 base58 下通常为 27 字符
  if Length(S) <> 27 then Exit;
  for i := 1 to Length(S) do begin c := S[i]; if Pos(c, string(B58)) = 0 then Exit; end;
  Result := TryParseKsuidBase58(S, A);
end;

end;

function TryParseKsuidBase58(const S: string; out A: TKsuid160): Boolean;
begin
  Result := Base58DecodeToFixed(S, A, SizeOf(A));
end;

end.

