unit fafafa.core.simd.intrinsics.sse42;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  === fafafa.core.simd.intrinsics.sse42 ===
  SSE4.2 (Streaming SIMD Extensions 4.2) 指令集支�?  
  SSE4.2 �?Intel �?2008 年引入的 SIMD 指令集扩�?  主要增加了字符串处理�?CRC32 计算指令
  
  特性：
  - 字符串比较指�?(PCMPESTRI, PCMPESTRM, PCMPISTRI, PCMPISTRM)
  - CRC32 计算指令
  - 64位比较指�?(PCMPGTQ)
  
  兼容性：大部分现�?x86/x64 处理器都支持
}

interface

uses
  fafafa.core.simd.intrinsics.base;

// === SSE4.2 字符串比较指�?===
// Explicit Length String Compare
function sse42_cmpestrm(const a: TM128; la: Integer; const b: TM128; lb: Integer; imm8: Byte): TM128;
function sse42_cmpestri(const a: TM128; la: Integer; const b: TM128; lb: Integer; imm8: Byte): Integer;
function sse42_cmpestrc(const a: TM128; la: Integer; const b: TM128; lb: Integer; imm8: Byte): Boolean;
function sse42_cmpestro(const a: TM128; la: Integer; const b: TM128; lb: Integer; imm8: Byte): Boolean;
function sse42_cmpestrs(const a: TM128; la: Integer; const b: TM128; lb: Integer; imm8: Byte): Boolean;
function sse42_cmpestrz(const a: TM128; la: Integer; const b: TM128; lb: Integer; imm8: Byte): Boolean;

// Implicit Length String Compare
function sse42_cmpistrm(const a, b: TM128; imm8: Byte): TM128;
function sse42_cmpistri(const a, b: TM128; imm8: Byte): Integer;
function sse42_cmpistrc(const a, b: TM128; imm8: Byte): Boolean;
function sse42_cmpistro(const a, b: TM128; imm8: Byte): Boolean;
function sse42_cmpistrs(const a, b: TM128; imm8: Byte): Boolean;
function sse42_cmpistrz(const a, b: TM128; imm8: Byte): Boolean;

// === SSE4.2 64位比�?===
function sse42_cmpgt_epi64(const a, b: TM128): TM128;

// === SSE4.2 CRC32 指令 ===
function sse42_crc32_u8(crc: Cardinal; data: Byte): Cardinal;
function sse42_crc32_u16(crc: Cardinal; data: Word): Cardinal;
function sse42_crc32_u32(crc: Cardinal; data: Cardinal): Cardinal;
function sse42_crc32_u64(crc: UInt64; data: UInt64): UInt64;

implementation

uses
  SysUtils;

const
  SSE42_EQUAL_ANY_UBYTE = 0;
  CRC32C_REFLECTED_POLY = $82F63B78;

procedure EnsureExperimentalIntrinsicsEnabled; inline;
begin
  {$IFNDEF FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS}
  raise ENotSupportedException.Create(
    'fafafa.core.simd.intrinsics.sse42 is experimental fallback semantics. ' +
    'Define FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS to opt in.'
  );
  {$ENDIF}
end;

procedure RequireEqualAnyUByteControls(aImm8: Byte); inline;
begin
  if aImm8 <> SSE42_EQUAL_ANY_UBYTE then
    raise ENotSupportedException.Create(
      'fafafa.core.simd.intrinsics.sse42 string fallback supports only ' +
      'unsigned-byte equal-any positive bit-mask semantics.'
    );
end;

function ClampStringLength(aLength: Integer): Integer; inline;
begin
  Result := Abs(aLength);
  if Result > 16 then
    Result := 16;
end;

function ImplicitByteLength(const aValue: TM128): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    if aValue.m128i_u8[LIndex] = 0 then
      Exit(LIndex);
  Result := 16;
end;

function EqualAnyByteMask(const a: TM128; aLengthA: Integer; const b: TM128; aLengthB: Integer): Word;
var
  LAIndex: Integer;
  LBIndex: Integer;
  LMatched: Boolean;
begin
  Result := 0;
  for LAIndex := 0 to aLengthA - 1 do
  begin
    LMatched := False;
    for LBIndex := 0 to aLengthB - 1 do
      if a.m128i_u8[LAIndex] = b.m128i_u8[LBIndex] then
      begin
        LMatched := True;
        Break;
      end;
    if LMatched then
      Result := Result or (1 shl LAIndex);
  end;
end;

function MaskToM128(aMask: Word): TM128; inline;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.m128i_u16[0] := aMask;
end;

function FirstMaskIndex(aMask: Word): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    if (aMask and (1 shl LIndex)) <> 0 then
      Exit(LIndex);
  Result := 16;
end;

function ExplicitEqualAnyMask(const a: TM128; la: Integer; const b: TM128; lb: Integer; imm8: Byte): Word;
begin
  RequireEqualAnyUByteControls(imm8);
  Result := EqualAnyByteMask(a, ClampStringLength(la), b, ClampStringLength(lb));
end;

function ImplicitEqualAnyMask(const a, b: TM128; imm8: Byte): Word;
begin
  RequireEqualAnyUByteControls(imm8);
  Result := EqualAnyByteMask(a, ImplicitByteLength(a), b, ImplicitByteLength(b));
end;

// === 字符串比较指令的 fallback 子集 ===
function sse42_cmpestrm(const a: TM128; la: Integer; const b: TM128; lb: Integer; imm8: Byte): TM128;
begin
  Result := MaskToM128(ExplicitEqualAnyMask(a, la, b, lb, imm8));
end;

function sse42_cmpestri(const a: TM128; la: Integer; const b: TM128; lb: Integer; imm8: Byte): Integer;
begin
  Result := FirstMaskIndex(ExplicitEqualAnyMask(a, la, b, lb, imm8));
end;

function sse42_cmpestrc(const a: TM128; la: Integer; const b: TM128; lb: Integer; imm8: Byte): Boolean;
begin
  Result := ExplicitEqualAnyMask(a, la, b, lb, imm8) <> 0;
end;

function sse42_cmpestro(const a: TM128; la: Integer; const b: TM128; lb: Integer; imm8: Byte): Boolean;
begin
  Result := (ExplicitEqualAnyMask(a, la, b, lb, imm8) and 1) <> 0;
end;

function sse42_cmpestrs(const a: TM128; la: Integer; const b: TM128; lb: Integer; imm8: Byte): Boolean;
begin
  RequireEqualAnyUByteControls(imm8);
  Result := ClampStringLength(la) < 16;
end;

function sse42_cmpestrz(const a: TM128; la: Integer; const b: TM128; lb: Integer; imm8: Byte): Boolean;
begin
  RequireEqualAnyUByteControls(imm8);
  Result := ClampStringLength(lb) < 16;
end;

function sse42_cmpistrm(const a, b: TM128; imm8: Byte): TM128;
begin
  Result := MaskToM128(ImplicitEqualAnyMask(a, b, imm8));
end;

function sse42_cmpistri(const a, b: TM128; imm8: Byte): Integer;
begin
  Result := FirstMaskIndex(ImplicitEqualAnyMask(a, b, imm8));
end;

function sse42_cmpistrc(const a, b: TM128; imm8: Byte): Boolean;
begin
  Result := ImplicitEqualAnyMask(a, b, imm8) <> 0;
end;

function sse42_cmpistro(const a, b: TM128; imm8: Byte): Boolean;
begin
  Result := (ImplicitEqualAnyMask(a, b, imm8) and 1) <> 0;
end;

function sse42_cmpistrs(const a, b: TM128; imm8: Byte): Boolean;
begin
  RequireEqualAnyUByteControls(imm8);
  Result := ImplicitByteLength(a) < 16;
end;

function sse42_cmpistrz(const a, b: TM128; imm8: Byte): Boolean;
begin
  RequireEqualAnyUByteControls(imm8);
  Result := ImplicitByteLength(b) < 16;
end;

// === 64位比较实�?===
function sse42_cmpgt_epi64(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    if a.m128i_i64[i] > b.m128i_i64[i] then
      Result.m128i_u64[i] := $FFFFFFFFFFFFFFFF
    else
      Result.m128i_u64[i] := $0000000000000000;
end;

// === CRC32 指令的简化实�?===
function sse42_crc32_u8(crc: Cardinal; data: Byte): Cardinal;
var
  LBit: Integer;
begin
  Result := crc xor data;
  for LBit := 0 to 7 do
  begin
    if (Result and 1) <> 0 then
      Result := (Result shr 1) xor CRC32C_REFLECTED_POLY
    else
      Result := Result shr 1;
  end;
end;

function sse42_crc32_u16(crc: Cardinal; data: Word): Cardinal;
begin
  Result := sse42_crc32_u8(crc, Byte(data));
  Result := sse42_crc32_u8(Result, Byte(data shr 8));
end;

function sse42_crc32_u32(crc: Cardinal; data: Cardinal): Cardinal;
begin
  Result := sse42_crc32_u8(crc, Byte(data));
  Result := sse42_crc32_u8(Result, Byte(data shr 8));
  Result := sse42_crc32_u8(Result, Byte(data shr 16));
  Result := sse42_crc32_u8(Result, Byte(data shr 24));
end;

function sse42_crc32_u64(crc: UInt64; data: UInt64): UInt64;
begin
  Result := sse42_crc32_u32(Cardinal(crc), Cardinal(data));
  Result := QWord(sse42_crc32_u32(Cardinal(Result), Cardinal(data shr 32)));
end;

initialization
  EnsureExperimentalIntrinsicsEnabled;

end.


