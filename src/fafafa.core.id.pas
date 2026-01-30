{
  fafafa.core.id — Modern ID generation (UUID v4/v7)

  - Cross‑platform, dependency‑light
  - RFC 9562 compliant UUID v4 (random) and v7 (time‑ordered)
  - Uses fafafa.core.crypto.random for CSPRNG

  Notes
  - v7 is recommended for DB primary keys due to index locality and natural ordering
  - v4 is recommended when unguessability is a priority (security‑adjacent contexts)
}

unit fafafa.core.id;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, DateUtils,
  fafafa.core.crypto.random,
  fafafa.core.time,
  fafafa.core.id.time;

type
  TUuid128 = array[0..15] of Byte;


  TUuid128Array = array of TUuid128;

  { Batch generation }
  function UuidV4_RawN(Count: SizeInt): TUuid128Array;
  procedure UuidV4_FillRawN(var OutArr: TUuid128Array); overload;
  procedure UuidV4_FillRawN(var OutArr: array of TUuid128); overload;
  function UuidV7_RawN(Count: SizeInt): TUuid128Array;
  procedure UuidV7_FillRawN(var OutArr: TUuid128Array); overload;
  procedure UuidV7_FillRawN(var OutArr: array of TUuid128); overload;
  { Batch text (zero/low allocation) }
  procedure UuidV4_FillTextN(var Dest: array of PChar); overload;
  procedure UuidV4_FillTextStringsN(var Dest: array of string); overload;
  procedure UuidV7_FillTextN(var Dest: array of PChar); overload;
  procedure UuidV7_FillTextStringsN(var Dest: array of string); overload;
  { Batch text NoDash }
  procedure UuidV4_FillTextNoDashN(var Dest: array of PChar); overload;
  procedure UuidV4_FillTextNoDashStringsN(var Dest: array of string); overload;
  procedure UuidV7_FillTextNoDashN(var Dest: array of PChar); overload;
  procedure UuidV7_FillTextNoDashStringsN(var Dest: array of string); overload;

{**
 * UuidV4_Raw - 生成 UUID v4 原始字节
 *
 * @return 16 字节随机 UUID (RFC 9562)
 * @note 使用 CSPRNG 生成，适合安全场景
 *}
function UuidV4_Raw: TUuid128;

{**
 * UuidV4 - 生成 UUID v4 字符串
 *
 * @return 36 字符标准格式 (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
 * @example "550e8400-e29b-41d4-a716-446655440000"
 *}
function UuidV4: string; overload;
  { Batch text Base64URL }
  procedure UuidV4_FillBase64UrlN(var Dest: array of PChar); overload;
  procedure UuidV4_FillBase64UrlStringsN(var Dest: array of string); overload;
  procedure UuidV7_FillBase64UrlN(var Dest: array of PChar); overload;
  procedure UuidV7_FillBase64UrlStringsN(var Dest: array of string); overload;

procedure UuidV4(out AOut: string); overload;

{**
 * UuidV7_Raw - 生成 UUID v7 原始字节
 *
 * @param ATimestampMs Unix 毫秒时间戳
 * @return 16 字节时间排序 UUID (RFC 9562)
 * @note 推荐用于数据库主键 (索引友好)
 *}
function UuidV7_Raw(ATimestampMs: Int64): TUuid128; overload;

{**
 * UuidV7_Raw - 使用当前时间生成 UUID v7
 *
 * @return 16 字节时间排序 UUID
 *}
function UuidV7_Raw: TUuid128; overload;

{**
 * UuidV7 - 生成 UUID v7 字符串
 *
 * @return 36 字符标准格式
 * @example "01919d1c-4d7e-7000-8000-000000000000"
 *}
function UuidV7: string; overload;
procedure UuidV7(out AOut: string); overload;

{**
 * UuidToString - UUID 转字符串
 *
 * @param A 16 字节 UUID
 * @return 36 字符标准格式
 *}
function UuidToString(const A: TUuid128): string;
procedure UuidToString(const A: TUuid128; out S: string);
function UuidToStringNoDash(const A: TUuid128): string;

{ Zero-allocation formatters }
{**
 * UuidToChars - 零拷贝格式化到缓冲区
 *
 * @param A UUID 字节数组
 * @param Dest 目标缓冲区 (至少 36 字节)
 *}
procedure UuidToChars(const A: TUuid128; Dest: PChar); inline;
procedure UuidToCharsNoDash(const A: TUuid128; Dest: PChar); inline;

  { Append (no allocation if capacity pre-reserved) }
  procedure UuidAppend(const A: TUuid128; var S: string); inline;

{**
 * TryParseUuid - 解析 UUID 字符串
 *
 * @param S 36 字符 UUID 字符串
 * @param A 输出 UUID 字节数组
 * @return True 解析成功
 * @note 接受大小写混合
 *}
function TryParseUuid(const S: string; out A: TUuid128): Boolean;
{ Relaxed parse: accepts 36-char dashed or 32 hex digits without dashes }
function TryParseUuidRelaxed(const S: string; out A: TUuid128): Boolean;
function TryParseUuidNoDash(const S: string; out A: TUuid128): Boolean;
{ Helpers }
function UuidVersion(const A: TUuid128): Integer; inline;
function UuidVariantRFC4122(const A: TUuid128): Boolean; inline;
function IsUuidV4(const S: string): Boolean; inline;
function IsUuidV7(const S: string): Boolean; inline;

{ Extract v7 unix epoch milliseconds (returns -1 if not v7/invalid) }
function UuidV7_TimestampMs(const S: string): Int64;

function UuidV7_TimestampMsRelaxed(const S: string): Int64;
implementation

uses
  fafafa.core.id.codec,
  fafafa.core.id.internal,  // ✅ 共享 HexCharToNibble
  fafafa.core.id.rng;  // ✅ 使用缓冲 RNG 优化性能 (提供 SecureRandomFill)


function UuidV4_RawN(Count: SizeInt): TUuid128Array;
var
  i: SizeInt;
  totalBytes: SizeInt;
begin
  if Count <= 0 then Exit(nil);
  SetLength(Result, Count);
  // bulk fill random then set version/variant bits
  totalBytes := Count * SizeOf(TUuid128);
  SecureRandomFill(Result[0], totalBytes);
  for i := 0 to Count-1 do
  begin
    Result[i][6] := (Result[i][6] and $0F) or $40; // v4
    Result[i][8] := (Result[i][8] and $3F) or $80; // RFC4122 variant
  end;
end;

procedure UuidV4_FillRawN(var OutArr: TUuid128Array);
var
  i, n: SizeInt;
  totalBytes: SizeInt;
begin
  n := Length(OutArr);
  if n <= 0 then Exit;
  totalBytes := n * SizeOf(TUuid128);
  SecureRandomFill(OutArr[0], totalBytes);
  for i := 0 to n-1 do
  begin
    OutArr[i][6] := (OutArr[i][6] and $0F) or $40;
    OutArr[i][8] := (OutArr[i][8] and $3F) or $80;
  end;
end;

procedure UuidV4_FillRawN(var OutArr: array of TUuid128);
var
  i, n: SizeInt;
  totalBytes: SizeInt;
begin
  n := High(OutArr) + 1;
  if n <= 0 then Exit;
  totalBytes := n * SizeOf(TUuid128);
  SecureRandomFill(OutArr[0], totalBytes);
  for i := 0 to n-1 do
  begin
    OutArr[i][6] := (OutArr[i][6] and $0F) or $40;
    OutArr[i][8] := (OutArr[i][8] and $3F) or $80;
  end;
end;

procedure UuidV7_FillRawN(var OutArr: array of TUuid128);
var
  i, n: SizeInt;
  ts: Int64;
  totalBytes: SizeInt;
begin
  n := High(OutArr) + 1;
  if n <= 0 then Exit;
  totalBytes := n * SizeOf(TUuid128);
  SecureRandomFill(OutArr[0], totalBytes);
  // ✅ 优化: 获取一次时间戳，用于整个批量 (参考 Rust uuid7-rs 策略)
  // 批量生成使用相同毫秒时间戳，随机部分保证唯一性
  ts := NowUnixMs;
  for i := 0 to n-1 do
  begin
    OutArr[i][0] := Byte((QWord(ts) shr 40) and $FF);
    OutArr[i][1] := Byte((QWord(ts) shr 32) and $FF);
    OutArr[i][2] := Byte((QWord(ts) shr 24) and $FF);
    OutArr[i][3] := Byte((QWord(ts) shr 16) and $FF);
    OutArr[i][4] := Byte((QWord(ts) shr 8) and $FF);
    OutArr[i][5] := Byte(QWord(ts) and $FF);
    OutArr[i][6] := (OutArr[i][6] and $0F) or $70;
    OutArr[i][8] := (OutArr[i][8] and $3F) or $80;
  end;
end;

function UuidV7_RawN(Count: SizeInt): TUuid128Array;
var
  i: SizeInt;
  ts: Int64;
  totalBytes: SizeInt;
begin
  if Count <= 0 then Exit(nil);
  SetLength(Result, Count);
  // fill random in bulk first
  totalBytes := Count * SizeOf(TUuid128);
  SecureRandomFill(Result[0], totalBytes);
  // ✅ 优化: 获取一次时间戳，用于整个批量 (参考 Rust uuid7-rs 策略)
  // 批量生成使用相同毫秒时间戳，随机部分保证唯一性
  ts := NowUnixMs;
  // apply timestamps + version/variant
  for i := 0 to Count-1 do
  begin
    Result[i][0] := Byte((QWord(ts) shr 40) and $FF);
    Result[i][1] := Byte((QWord(ts) shr 32) and $FF);
    Result[i][2] := Byte((QWord(ts) shr 24) and $FF);
    Result[i][3] := Byte((QWord(ts) shr 16) and $FF);
    Result[i][4] := Byte((QWord(ts) shr 8) and $FF);
    Result[i][5] := Byte(QWord(ts) and $FF);
    Result[i][6] := (Result[i][6] and $0F) or $70;
    Result[i][8] := (Result[i][8] and $3F) or $80;
  end;
end;

procedure UuidV7_FillRawN(var OutArr: TUuid128Array);
var
  i, n: SizeInt;
  ts: Int64;
  totalBytes: SizeInt;
begin
  n := Length(OutArr);
  if n <= 0 then Exit;
  totalBytes := n * SizeOf(TUuid128);
  SecureRandomFill(OutArr[0], totalBytes);
  // ✅ 优化: 获取一次时间戳，用于整个批量 (参考 Rust uuid7-rs 策略)
  ts := NowUnixMs;
  for i := 0 to n-1 do
  begin
    OutArr[i][0] := Byte((QWord(ts) shr 40) and $FF);
    OutArr[i][1] := Byte((QWord(ts) shr 32) and $FF);
    OutArr[i][2] := Byte((QWord(ts) shr 24) and $FF);
    OutArr[i][3] := Byte((QWord(ts) shr 16) and $FF);
    OutArr[i][4] := Byte((QWord(ts) shr 8) and $FF);
    OutArr[i][5] := Byte(QWord(ts) and $FF);
    OutArr[i][6] := (OutArr[i][6] and $0F) or $70;
    OutArr[i][8] := (OutArr[i][8] and $3F) or $80;
  end;
end;

const
  HEX_CHARS: array[0..15] of Char = ('0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f');

// Use shared time helper from fafafa.core.id.time
// SecureRandomFill 已统一到 fafafa.core.id.rng.pas

function UuidVersion(const A: TUuid128): Integer; inline;
begin
  Result := (A[6] shr 4) and $0F;
end;

function UuidVariantRFC4122(const A: TUuid128): Boolean; inline;
begin
  Result := (A[8] and $C0) = $80; // 10b
end;

function IsUuidV4(const S: string): Boolean; inline;
var A: TUuid128;
begin
  if not TryParseUuidRelaxed(S, A) then Exit(False);
  Result := (UuidVersion(A) = 4) and UuidVariantRFC4122(A);
end;

function IsUuidV7(const S: string): Boolean; inline;
var A: TUuid128;
begin
  if not TryParseUuidRelaxed(S, A) then Exit(False);
  Result := (UuidVersion(A) = 7) and UuidVariantRFC4122(A);
end;
procedure ApplyUuidVariantRFC4122(var B: TUuid128); inline;
begin
  // Set the two most significant bits of clock_seq_hi_and_reserved to 10
  B[8] := (B[8] and $3F) or $80;
end;

function UuidToString(const A: TUuid128): string;
begin
  SetLength(Result, 36);
  UuidToChars(A, PChar(Result));
end;

procedure UuidToChars(const A: TUuid128; Dest: PChar); inline;
var
  I: Integer;
  P: PChar;
begin
  P := Dest;
  // 8-4-4-4-12 groups over A[0..15]
  for I := 0 to 3 do begin P^ := HEX_CHARS[(A[I] shr 4) and $0F]; Inc(P); P^ := HEX_CHARS[A[I] and $0F]; Inc(P); end; P^ := '-'; Inc(P);
  for I := 4 to 5 do begin P^ := HEX_CHARS[(A[I] shr 4) and $0F]; Inc(P); P^ := HEX_CHARS[A[I] and $0F]; Inc(P); end; P^ := '-'; Inc(P);
  for I := 6 to 7 do begin P^ := HEX_CHARS[(A[I] shr 4) and $0F]; Inc(P); P^ := HEX_CHARS[A[I] and $0F]; Inc(P); end; P^ := '-'; Inc(P);
  for I := 8 to 9 do begin P^ := HEX_CHARS[(A[I] shr 4) and $0F]; Inc(P); P^ := HEX_CHARS[A[I] and $0F]; Inc(P); end; P^ := '-'; Inc(P);
  for I := 10 to 15 do begin P^ := HEX_CHARS[(A[I] shr 4) and $0F]; Inc(P); P^ := HEX_CHARS[A[I] and $0F]; Inc(P); end;
end;

procedure UuidToString(const A: TUuid128; out S: string);
begin
  SetLength(S, 36);
  UuidToChars(A, PChar(S));
end;

procedure UuidAppend(const A: TUuid128; var S: string); inline;
var L: SizeInt; P: PChar;
begin
  L := Length(S);
  SetLength(S, L + 36);
  P := PChar(S);
  Inc(P, L);
  UuidToChars(A, P);
end;

function UuidToStringNoDash(const A: TUuid128): string;
var
  I: Integer;
  P: PChar;
begin
  SetLength(Result, 32);
  P := PChar(Result);
  for I := 0 to 15 do begin P^ := HEX_CHARS[(A[I] shr 4) and $0F]; Inc(P); P^ := HEX_CHARS[A[I] and $0F]; Inc(P); end;
end;

procedure UuidToCharsNoDash(const A: TUuid128; Dest: PChar); inline;
var
  I: Integer;
  P: PChar;
begin
  P := Dest;
  for I := 0 to 15 do begin P^ := HEX_CHARS[(A[I] shr 4) and $0F]; Inc(P); P^ := HEX_CHARS[A[I] and $0F]; Inc(P); end;
end;

procedure UuidV4_FillTextN(var Dest: array of PChar);
var i, n: SizeInt; R: TUuid128;
begin
  n := High(Dest) + 1; if n <= 0 then Exit;
  for i := 0 to n-1 do begin R := UuidV4_Raw; UuidToChars(R, Dest[i]); end;
end;

procedure UuidV4_FillTextStringsN(var Dest: array of string);
var i, n: SizeInt;
begin
  n := High(Dest) + 1; if n <= 0 then Exit;
  for i := 0 to n-1 do Dest[i] := UuidV4;
end;

procedure UuidV7_FillTextN(var Dest: array of PChar);
var i, n: SizeInt; R: TUuid128;
begin
  n := High(Dest) + 1; if n <= 0 then Exit;
  for i := 0 to n-1 do begin R := UuidV7_Raw; UuidToChars(R, Dest[i]); end;
end;

procedure UuidV7_FillTextStringsN(var Dest: array of string);
var i, n: SizeInt;
begin
  n := High(Dest) + 1; if n <= 0 then Exit;
  for i := 0 to n-1 do Dest[i] := UuidV7;
end;

procedure UuidV4_FillTextNoDashN(var Dest: array of PChar);
var i, n: SizeInt; R: TUuid128;
begin
  n := High(Dest) + 1; if n <= 0 then Exit;
  for i := 0 to n-1 do begin R := UuidV4_Raw; UuidToCharsNoDash(R, Dest[i]); end;
end;

procedure UuidV4_FillTextNoDashStringsN(var Dest: array of string);
var i, n: SizeInt; S: string;
begin
  n := High(Dest) + 1; if n <= 0 then Exit;
  for i := 0 to n-1 do begin S := UuidToStringNoDash(UuidV4_Raw); Dest[i] := S; end;
end;

procedure UuidV7_FillTextNoDashN(var Dest: array of PChar);
var i, n: SizeInt; R: TUuid128;
begin
  n := High(Dest) + 1; if n <= 0 then Exit;
  for i := 0 to n-1 do begin R := UuidV7_Raw; UuidToCharsNoDash(R, Dest[i]); end;
end;

procedure UuidV7_FillTextNoDashStringsN(var Dest: array of string);
var i, n: SizeInt; S: string;
begin
  n := High(Dest) + 1; if n <= 0 then Exit;
  for i := 0 to n-1 do begin S := UuidToStringNoDash(UuidV7_Raw); Dest[i] := S; end;
end;

procedure UuidV4_FillBase64UrlN(var Dest: array of PChar);
var i, n: SizeInt; R: TUuid128;
begin
  n := High(Dest) + 1; if n <= 0 then Exit;
  for i := 0 to n-1 do begin R := UuidV4_Raw; UuidToBase64UrlChars(R, Dest[i]); end;
end;

procedure UuidV4_FillBase64UrlStringsN(var Dest: array of string);
var i, n: SizeInt; R: TUuid128;
begin
  n := High(Dest) + 1; if n <= 0 then Exit;
  for i := 0 to n-1 do begin R := UuidV4_Raw; SetLength(Dest[i], 22); UuidToBase64UrlChars(R, PChar(Dest[i])); end;
end;

procedure UuidV7_FillBase64UrlN(var Dest: array of PChar);
var i, n: SizeInt; R: TUuid128;
begin
  n := High(Dest) + 1; if n <= 0 then Exit;
  for i := 0 to n-1 do begin R := UuidV7_Raw; UuidToBase64UrlChars(R, Dest[i]); end;
end;

procedure UuidV7_FillBase64UrlStringsN(var Dest: array of string);
var i, n: SizeInt; R: TUuid128;
begin
  n := High(Dest) + 1; if n <= 0 then Exit;
  for i := 0 to n-1 do begin R := UuidV7_Raw; SetLength(Dest[i], 22); UuidToBase64UrlChars(R, PChar(Dest[i])); end;
end;

// ✅ P1: 使用 fafafa.core.id.internal.HexCharToNibble (替代本地 HexVal)

function TryParseUuid(const S: string; out A: TUuid128): Boolean;
var
  I, J, K: Integer; V1, V2: Byte; HexOnly: array[0..31] of Char;
begin
  Result := False;
  if Length(S) <> 36 then Exit;
  // Hyphen positions: 9,14,19,24 (1-based)
  if not ((S[9] = '-') and (S[14] = '-') and (S[19] = '-') and (S[24] = '-')) then Exit;
  // Collect 32 hex chars
  J := 0;
  for I := 1 to 36 do
  begin
    if (I = 9) or (I = 14) or (I = 19) or (I = 24) then Continue;
    if J > 31 then Exit; // overflow
    if not ((S[I] in ['0'..'9','a'..'f','A'..'F'])) then Exit;
    HexOnly[J] := S[I];
    Inc(J);
  end;
  if J <> 32 then Exit;
  // Parse pairs
  K := 0;
  for I := 0 to 15 do
  begin
    if (not HexCharToNibble(HexOnly[I*2], V1)) or (not HexCharToNibble(HexOnly[I*2+1], V2)) then Exit;
    A[K] := (V1 shl 4) or V2;
    Inc(K);
  end;
  Result := True;
end;

function TryParseUuidRelaxed(const S: string; out A: TUuid128): Boolean;
var
  I, K: Integer; V1, V2: Byte; C: Char; HexOnly: array[0..31] of Char;
begin
  // Accept standard dashed form
  if Length(S) = 36 then
    Exit(TryParseUuid(S, A));
  // Accept 32 hex chars (no dashes)
  if Length(S) = 32 then
  begin
    for I := 1 to 32 do
    begin
      C := S[I];
      if not (C in ['0'..'9','a'..'f','A'..'F']) then Exit(False);
      HexOnly[I-1] := C;
    end;
    K := 0;
    for I := 0 to 15 do
    begin
      if (not HexCharToNibble(HexOnly[I*2], V1)) or (not HexCharToNibble(HexOnly[I*2+1], V2)) then Exit(False);
      A[K] := (V1 shl 4) or V2; Inc(K);
    end;
    Exit(True);
  end;
  Result := False;
end;

function TryParseUuidNoDash(const S: string; out A: TUuid128): Boolean;
begin
  if Length(S) <> 32 then Exit(False);
  Result := TryParseUuidRelaxed(S, A);
end;

function UuidV4_Raw: TUuid128;
begin
  SecureRandomFill(Result, SizeOf(Result));
  // version 4 (random): set high nibble of byte 6 to 0100
  Result[6] := (Result[6] and $0F) or $40;
  ApplyUuidVariantRFC4122(Result);
end;

function UuidV4: string;
begin
  UuidToString(UuidV4_Raw, Result);
end;

procedure UuidV4(out AOut: string);
begin
  AOut := UuidV4;
end;

function UuidV7_Raw(ATimestampMs: Int64): TUuid128;
var
  TS: QWord;
begin
  // Fill timestamp (first 48 bits, big-endian)
  TS := QWord(ATimestampMs);
  Result[0] := Byte((TS shr 40) and $FF);
  Result[1] := Byte((TS shr 32) and $FF);
  Result[2] := Byte((TS shr 24) and $FF);
  Result[3] := Byte((TS shr 16) and $FF);
  Result[4] := Byte((TS shr 8) and $FF);
  Result[5] := Byte(TS and $FF);
  // Random for the remaining 10 bytes
  SecureRandomFill(Result[6], 10);
  // version 7 (time-ordered): set high nibble of byte 6 to 0111
  Result[6] := (Result[6] and $0F) or $70;
  ApplyUuidVariantRFC4122(Result);
end;

function UuidV7_Raw: TUuid128;
begin
  Result := UuidV7_Raw(NowUnixMs);
end;

function UuidV7: string;
begin
  UuidToString(UuidV7_Raw, Result);
end;

procedure UuidV7(out AOut: string);
begin
  AOut := UuidV7;
end;

function UuidV7_TimestampMs(const S: string): Int64;
var
  B: TUuid128;
begin
  if not TryParseUuid(S, B) then Exit(-1);
  // Check version nibble == 7 and RFC4122 variant (10b)
  if ((B[6] shr 4) and $0F) <> 7 then Exit(-1);
  if (B[8] and $C0) <> $80 then Exit(-1);
  Result :=
    (Int64(B[0]) shl 40) or
    (Int64(B[1]) shl 32) or
    (Int64(B[2]) shl 24) or
    (Int64(B[3]) shl 16) or
    (Int64(B[4]) shl 8) or
     Int64(B[5]);
end;

function UuidV7_TimestampMsRelaxed(const S: string): Int64;
var
  B: TUuid128;
begin
  if not TryParseUuidRelaxed(S, B) then Exit(-1);
  if ((B[6] shr 4) and $0F) <> 7 then Exit(-1);
  if (B[8] and $C0) <> $80 then Exit(-1);
  Result :=
    (Int64(B[0]) shl 40) or
    (Int64(B[1]) shl 32) or
    (Int64(B[2]) shl 24) or
    (Int64(B[3]) shl 16) or
    (Int64(B[4]) shl 8) or
     Int64(B[5]);
end;

end.

