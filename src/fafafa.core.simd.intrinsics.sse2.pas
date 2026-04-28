unit fafafa.core.simd.intrinsics.sse2;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  === fafafa.core.simd.intrinsics.sse2 ===
  SSE2 (Streaming SIMD Extensions 2) 指令集支�?
  SSE2 �?Intel �?2001 年引入的 128-bit SIMD 指令集扩�?  是所�?x86-64 处理器的基础指令集，提供完整的整数和双精度浮点支�?
  特性：
  - 128-bit 向量寄存�?(xmm0-xmm15)
  - 整数运算 (8/16/32/64-bit)
  - 双精度浮点运�?(2x64-bit)
  - 单精度浮点运�?(4x32-bit)
  - 打包/解包操作
  - 移位和逻辑操作

  兼容性：所�?x86-64 处理器都支持，是最重要的基础指令�?}

interface

uses
  fafafa.core.simd.intrinsics.base;

{
  Experimental status (2026-02-17):
  - This unit currently mixes valid helpers with many placeholder bodies.
  - It is intentionally excluded from default SIMD facade/gate entry paths.
  - Keep for incremental bring-up only; do not treat as production semantic source.
}

// === SSE2 整数函数 ===
// Load/Store
function simd_load_si128(const Ptr: Pointer): TM128;
function simd_loadu_si128(const Ptr: Pointer): TM128;
procedure simd_store_si128(var Dest; constref Src: TM128);
procedure simd_storeu_si128(var Dest; constref Src: TM128);

// Set/Zero
function simd_setzero_si128: TM128;
function simd_set1_epi32(Value: LongInt): TM128;
function simd_set1_epi16(Value: SmallInt): TM128;
function simd_set1_epi8(Value: ShortInt): TM128;
function simd_set_epi32(e3, e2, e1, e0: LongInt): TM128;
function simd_set_epi16(e7, e6, e5, e4, e3, e2, e1, e0: SmallInt): TM128;

// Arithmetic
function simd_add_epi32(constref a, b: TM128): TM128;
function simd_add_epi16(constref a, b: TM128): TM128;
function simd_add_epi8(constref a, b: TM128): TM128;
function simd_add_epi64(constref a, b: TM128): TM128;
function simd_sub_epi32(constref a, b: TM128): TM128;
function simd_sub_epi16(constref a, b: TM128): TM128;
function simd_sub_epi8(constref a, b: TM128): TM128;
function simd_sub_epi64(constref a, b: TM128): TM128;

// Saturated Arithmetic
function simd_adds_epi16(constref a, b: TM128): TM128;
function simd_adds_epi8(constref a, b: TM128): TM128;
function simd_adds_epu16(constref a, b: TM128): TM128;
function simd_adds_epu8(constref a, b: TM128): TM128;
function simd_subs_epi16(constref a, b: TM128): TM128;
function simd_subs_epi8(constref a, b: TM128): TM128;
function simd_subs_epu16(constref a, b: TM128): TM128;
function simd_subs_epu8(constref a, b: TM128): TM128;

// Multiply
function simd_mullo_epi16(constref a, b: TM128): TM128;
function simd_mulhi_epi16(constref a, b: TM128): TM128;
function simd_mulhi_epu16(constref a, b: TM128): TM128;
function simd_mul_epu32(constref a, b: TM128): TM128;

// Logical
function simd_and_si128(constref a, b: TM128): TM128;
function simd_andnot_si128(constref a, b: TM128): TM128;
function simd_or_si128(constref a, b: TM128): TM128;
function simd_xor_si128(constref a, b: TM128): TM128;

// Compare
function simd_cmpeq_epi32(constref a, b: TM128): TM128;
function simd_cmpeq_epi16(constref a, b: TM128): TM128;
function simd_cmpeq_epi8(constref a, b: TM128): TM128;
function simd_cmpgt_epi32(constref a, b: TM128): TM128;
function simd_cmpgt_epi16(constref a, b: TM128): TM128;
function simd_cmpgt_epi8(constref a, b: TM128): TM128;
function simd_cmplt_epi32(constref a, b: TM128): TM128;
function simd_cmplt_epi16(constref a, b: TM128): TM128;
function simd_cmplt_epi8(constref a, b: TM128): TM128;

// Shift
function simd_slli_epi32(constref a: TM128; imm8: Byte): TM128;
function simd_slli_epi16(constref a: TM128; imm8: Byte): TM128;
function simd_slli_epi64(constref a: TM128; imm8: Byte): TM128;
function simd_slli_si128(constref a: TM128; imm8: Byte): TM128;
function simd_srli_epi32(constref a: TM128; imm8: Byte): TM128;
function simd_srli_epi16(constref a: TM128; imm8: Byte): TM128;
function simd_srli_epi64(constref a: TM128; imm8: Byte): TM128;
function simd_srli_si128(constref a: TM128; imm8: Byte): TM128;
function simd_srai_epi32(constref a: TM128; imm8: Byte): TM128;
function simd_srai_epi16(constref a: TM128; imm8: Byte): TM128;

// Variable Shift
function simd_sll_epi32(constref a, count: TM128): TM128;
function simd_sll_epi16(constref a, count: TM128): TM128;
function simd_sll_epi64(constref a, count: TM128): TM128;
function simd_srl_epi32(constref a, count: TM128): TM128;
function simd_srl_epi16(constref a, count: TM128): TM128;
function simd_srl_epi64(constref a, count: TM128): TM128;
function simd_sra_epi32(constref a, count: TM128): TM128;
function simd_sra_epi16(constref a, count: TM128): TM128;

// Pack/Unpack
function simd_packs_epi32(constref a, b: TM128): TM128;
function simd_packs_epi16(constref a, b: TM128): TM128;
function simd_packus_epi16(constref a, b: TM128): TM128;
function simd_unpackhi_epi32(constref a, b: TM128): TM128;
function simd_unpackhi_epi16(constref a, b: TM128): TM128;
function simd_unpackhi_epi8(constref a, b: TM128): TM128;
function simd_unpackhi_epi64(constref a, b: TM128): TM128;
function simd_unpacklo_epi32(constref a, b: TM128): TM128;
function simd_unpacklo_epi16(constref a, b: TM128): TM128;
function simd_unpacklo_epi8(constref a, b: TM128): TM128;
function simd_unpacklo_epi64(constref a, b: TM128): TM128;

// Min/Max
function simd_max_epi16(constref a, b: TM128): TM128;
function simd_max_epu8(constref a, b: TM128): TM128;
function simd_min_epi16(constref a, b: TM128): TM128;
function simd_min_epu8(constref a, b: TM128): TM128;

// Shuffle
function simd_shuffle_epi32(constref a: TM128; imm8: Byte): TM128;
function simd_shufflehi_epi16(constref a: TM128; imm8: Byte): TM128;
function simd_shufflelo_epi16(constref a: TM128; imm8: Byte): TM128;

// Move
function simd_move_epi64(constref a: TM128): TM128;
function simd_movemask_epi8(constref a: TM128): Integer;

// Insert/Extract
function simd_insert_epi16(constref a: TM128; Value: Integer; imm8: Byte): TM128;
function simd_extract_epi16(constref a: TM128; imm8: Byte): Integer;

// === SSE2 双精度浮点函�?===
// Load/Store
function simd_load_pd(const Ptr: Pointer): TM128;
function simd_loadu_pd(const Ptr: Pointer): TM128;
function simd_load_sd(const Ptr: Pointer): TM128;
function simd_load1_pd(const Ptr: Pointer): TM128;
procedure simd_store_pd(var Dest; constref Src: TM128);
procedure simd_storeu_pd(var Dest; constref Src: TM128);
procedure simd_store_sd(var Dest; constref Src: TM128);
procedure simd_store1_pd(var Dest; constref Src: TM128);

// Set/Zero
function simd_setzero_pd: TM128;
function simd_set1_pd(Value: Double): TM128;
function simd_set_pd(e1, e0: Double): TM128;
function simd_set_sd(Value: Double): TM128;
function simd_setr_pd(e0, e1: Double): TM128;

// Arithmetic
function simd_add_pd(constref a, b: TM128): TM128;
function simd_add_sd(constref a, b: TM128): TM128;
function simd_sub_pd(constref a, b: TM128): TM128;
function simd_sub_sd(constref a, b: TM128): TM128;
function simd_mul_pd(constref a, b: TM128): TM128;
function simd_mul_sd(constref a, b: TM128): TM128;
function simd_div_pd(constref a, b: TM128): TM128;
function simd_div_sd(constref a, b: TM128): TM128;

// Math Functions
function simd_sqrt_pd(constref a: TM128): TM128;
function simd_sqrt_sd(constref a: TM128): TM128;

// Min/Max
function simd_min_pd(constref a, b: TM128): TM128;
function simd_min_sd(constref a, b: TM128): TM128;
function simd_max_pd(constref a, b: TM128): TM128;
function simd_max_sd(constref a, b: TM128): TM128;

// Logical
function simd_and_pd(constref a, b: TM128): TM128;
function simd_andnot_pd(constref a, b: TM128): TM128;
function simd_or_pd(constref a, b: TM128): TM128;
function simd_xor_pd(constref a, b: TM128): TM128;

// Compare
function simd_cmpeq_pd(constref a, b: TM128): TM128;
function simd_cmpeq_sd(constref a, b: TM128): TM128;
function simd_cmplt_pd(constref a, b: TM128): TM128;
function simd_cmplt_sd(constref a, b: TM128): TM128;
function simd_cmple_pd(constref a, b: TM128): TM128;
function simd_cmple_sd(constref a, b: TM128): TM128;
function simd_cmpgt_pd(constref a, b: TM128): TM128;
function simd_cmpgt_sd(constref a, b: TM128): TM128;
function simd_cmpge_pd(constref a, b: TM128): TM128;
function simd_cmpge_sd(constref a, b: TM128): TM128;
function simd_cmpneq_pd(constref a, b: TM128): TM128;
function simd_cmpneq_sd(constref a, b: TM128): TM128;

// Shuffle/Unpack
function simd_shuffle_pd(constref a, b: TM128; imm8: Byte): TM128;
function simd_unpackhi_pd(constref a, b: TM128): TM128;
function simd_unpacklo_pd(constref a, b: TM128): TM128;

// Move
function simd_move_sd(constref a, b: TM128): TM128;
function simd_movemask_pd(constref a: TM128): Integer;

// Convert
function simd_cvtsi2sd(constref a: TM128; Value: LongInt): TM128;
function simd_cvtsd2si(constref a: TM128): LongInt;
function simd_cvttsd2si(constref a: TM128): LongInt;
function simd_cvtps2pd(constref a: TM128): TM128;
function simd_cvtpd2ps(constref a: TM128): TM128;
function simd_cvtss2sd(constref a, b: TM128): TM128;
function simd_cvtsd2ss(constref a, b: TM128): TM128;
function simd_cvtdq2pd(constref a: TM128): TM128;
function simd_cvtpd2dq(constref a: TM128): TM128;
function simd_cvttps2dq(constref a: TM128): TM128;
function simd_cvtps2dq(constref a: TM128): TM128;
function simd_cvtdq2ps(constref a: TM128): TM128;

// Cache Control
procedure simd_lfence;
procedure simd_mfence;
procedure simd_pause;
procedure simd_clflush(const Ptr: Pointer);

implementation

uses
  SysUtils,
  Math;  // RTL Math 单元 (Sqrt)

procedure EnsureExperimentalIntrinsicsEnabled; inline;
begin
  {$IFNDEF FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS}
  raise ENotSupportedException.Create(
    'fafafa.core.simd.intrinsics.sse2 is experimental placeholder semantics. ' +
    'Define FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS to opt in.'
  );
  {$ENDIF}
end;

// This experimental facade currently uses the scalar fallback path on every
// architecture. The previous x86 include hook referenced a missing file and
// prevented the unit from compiling in opt-in experimental builds at all.
//
// Keep the runtime guard above so default entry paths still reject it.
// === 基础函数实现 (Pascal 版本) ===

function simd_load_si128(const Ptr: Pointer): TM128;
begin
  Result := PTM128(Ptr)^;
end;

function simd_loadu_si128(const Ptr: Pointer): TM128;
begin
  Result := PTM128(Ptr)^;
end;

procedure simd_store_si128(var Dest; constref Src: TM128);
begin
  PTM128(@Dest)^ := Src;
end;

procedure simd_storeu_si128(var Dest; constref Src: TM128);
begin
  PTM128(@Dest)^ := Src;
end;

function simd_setzero_si128: TM128;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function simd_set1_epi32(Value: LongInt): TM128;
begin
  Result.m128i_i32[0] := Value;
  Result.m128i_i32[1] := Value;
  Result.m128i_i32[2] := Value;
  Result.m128i_i32[3] := Value;
end;

function simd_set1_epi16(Value: SmallInt): TM128;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.m128i_i16[i] := Value;
end;

function simd_set1_epi8(Value: ShortInt): TM128;
var
  i: Integer;
begin
  for i := 0 to 15 do
    Result.m128i_i8[i] := Value;
end;

function simd_set_epi32(e3, e2, e1, e0: LongInt): TM128;
begin
  Result.m128i_i32[0] := e0;
  Result.m128i_i32[1] := e1;
  Result.m128i_i32[2] := e2;
  Result.m128i_i32[3] := e3;
end;

function simd_set_epi16(e7, e6, e5, e4, e3, e2, e1, e0: SmallInt): TM128;
begin
  Result.m128i_i16[0] := e0;
  Result.m128i_i16[1] := e1;
  Result.m128i_i16[2] := e2;
  Result.m128i_i16[3] := e3;
  Result.m128i_i16[4] := e4;
  Result.m128i_i16[5] := e5;
  Result.m128i_i16[6] := e6;
  Result.m128i_i16[7] := e7;
end;

function simd_add_epi32(constref a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_i32[i] := a.m128i_i32[i] + b.m128i_i32[i];
end;

function simd_add_epi16(constref a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.m128i_i16[i] := a.m128i_i16[i] + b.m128i_i16[i];
end;

function simd_add_epi8(constref a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 15 do
    Result.m128i_i8[i] := a.m128i_i8[i] + b.m128i_i8[i];
end;

function simd_add_epi64(constref a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    Result.m128i_i64[i] := a.m128i_i64[i] + b.m128i_i64[i];
end;

function simd_sub_epi32(constref a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_i32[i] := a.m128i_i32[i] - b.m128i_i32[i];
end;

function simd_sub_epi16(constref a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.m128i_i16[i] := a.m128i_i16[i] - b.m128i_i16[i];
end;

function simd_sub_epi8(constref a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 15 do
    Result.m128i_i8[i] := a.m128i_i8[i] - b.m128i_i8[i];
end;

function simd_sub_epi64(constref a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    Result.m128i_i64[i] := a.m128i_i64[i] - b.m128i_i64[i];
end;

// 其他函数的实现将在后续添�?..
// 这里只提供基础框架，完整实现需要更多代�?
function simd_and_si128(constref a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_u32[i] := a.m128i_u32[i] and b.m128i_u32[i];
end;

function simd_andnot_si128(constref a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_u32[i] := (not a.m128i_u32[i]) and b.m128i_u32[i];
end;

function simd_or_si128(constref a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_u32[i] := a.m128i_u32[i] or b.m128i_u32[i];
end;

function simd_xor_si128(constref a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_u32[i] := a.m128i_u32[i] xor b.m128i_u32[i];
end;

function simd_cmpeq_epi32(constref a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128i_i32[i] = b.m128i_i32[i] then
      Result.m128i_u32[i] := $FFFFFFFF
    else
      Result.m128i_u32[i] := $00000000;
end;

function simd_cmpeq_epi16(constref a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 7 do
    if a.m128i_i16[i] = b.m128i_i16[i] then
      Result.m128i_u16[i] := $FFFF
    else
      Result.m128i_u16[i] := $0000;
end;

function simd_cmpeq_epi8(constref a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 15 do
    if a.m128i_i8[i] = b.m128i_i8[i] then
      Result.m128i_u8[i] := $FF
    else
      Result.m128i_u8[i] := $00;
end;

function simd_cmpgt_epi32(constref a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128i_i32[i] > b.m128i_i32[i] then
      Result.m128i_u32[i] := $FFFFFFFF
    else
      Result.m128i_u32[i] := $00000000;
end;

function simd_cmpgt_epi16(constref a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 7 do
    if a.m128i_i16[i] > b.m128i_i16[i] then
      Result.m128i_u16[i] := $FFFF
    else
      Result.m128i_u16[i] := $0000;
end;

function simd_cmpgt_epi8(constref a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 15 do
    if a.m128i_i8[i] > b.m128i_i8[i] then
      Result.m128i_u8[i] := $FF
    else
      Result.m128i_u8[i] := $00;
end;

function simd_cmplt_epi32(constref a, b: TM128): TM128;
begin
  Result := simd_cmpgt_epi32(b, a);
end;

function simd_cmplt_epi16(constref a, b: TM128): TM128;
begin
  Result := simd_cmpgt_epi16(b, a);
end;

function simd_cmplt_epi8(constref a, b: TM128): TM128;
begin
  Result := simd_cmpgt_epi8(b, a);
end;

// 移位操作的简化实�?
function simd_slli_epi32(constref a: TM128; imm8: Byte): TM128;
var
  i: Integer;
begin
  if imm8 >= 32 then
  begin
    FillChar(Result, SizeOf(Result), 0);
  end
  else
  begin
    for i := 0 to 3 do
      Result.m128i_u32[i] := a.m128i_u32[i] shl imm8;
  end;
end;

function simd_srli_epi32(constref a: TM128; imm8: Byte): TM128;
var
  i: Integer;
begin
  if imm8 >= 32 then
  begin
    FillChar(Result, SizeOf(Result), 0);
  end
  else
  begin
    for i := 0 to 3 do
      Result.m128i_u32[i] := a.m128i_u32[i] shr imm8;
  end;
end;

function simd_srai_epi32(constref a: TM128; imm8: Byte): TM128;
var
  i: Integer;
  shift_count: Byte;
  value: LongInt;
begin
  shift_count := imm8;
  if shift_count >= 32 then
    shift_count := 31;

  for i := 0 to 3 do
  begin
    value := a.m128i_i32[i];
    if shift_count = 0 then
      Result.m128i_i32[i] := value
    else if value >= 0 then
      Result.m128i_i32[i] := value shr shift_count
    else
      Result.m128i_i32[i] := (value shr shift_count) or ((-1) shl (32 - shift_count));
  end;
end;

// 双精度浮点函数的基础实现
function simd_setzero_pd: TM128;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function simd_set1_pd(Value: Double): TM128;
begin
  Result.m128d_f64[0] := Value;
  Result.m128d_f64[1] := Value;
end;

function simd_add_pd(constref a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    Result.m128d_f64[i] := a.m128d_f64[i] + b.m128d_f64[i];
end;

function simd_sub_pd(constref a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    Result.m128d_f64[i] := a.m128d_f64[i] - b.m128d_f64[i];
end;

function simd_mul_pd(constref a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    Result.m128d_f64[i] := a.m128d_f64[i] * b.m128d_f64[i];
end;

function simd_div_pd(constref a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    Result.m128d_f64[i] := a.m128d_f64[i] / b.m128d_f64[i];
end;

// 其他函数的占位符实现...
// 完整实现需要更多代码，这里只提供基础框架

// 占位符实�?
function simd_adds_epi16(constref a, b: TM128): TM128; begin Result := simd_add_epi16(a, b); end;
function simd_adds_epi8(constref a, b: TM128): TM128; begin Result := simd_add_epi8(a, b); end;
function simd_adds_epu16(constref a, b: TM128): TM128; begin Result := simd_add_epi16(a, b); end;
function simd_adds_epu8(constref a, b: TM128): TM128; begin Result := simd_add_epi8(a, b); end;
function simd_subs_epi16(constref a, b: TM128): TM128; begin Result := simd_sub_epi16(a, b); end;
function simd_subs_epi8(constref a, b: TM128): TM128; begin Result := simd_sub_epi8(a, b); end;
function simd_subs_epu16(constref a, b: TM128): TM128; begin Result := simd_sub_epi16(a, b); end;
function simd_subs_epu8(constref a, b: TM128): TM128; begin Result := simd_sub_epi8(a, b); end;

function simd_mullo_epi16(constref a, b: TM128): TM128;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.m128i_i16[i] := a.m128i_i16[i] * b.m128i_i16[i];
end;

function simd_mulhi_epi16(constref a, b: TM128): TM128;
var i: Integer; temp: LongInt;
begin
  for i := 0 to 7 do
  begin
    temp := LongInt(a.m128i_i16[i]) * LongInt(b.m128i_i16[i]);
    Result.m128i_i16[i] := SmallInt(temp shr 16);
  end;
end;

function simd_mulhi_epu16(constref a, b: TM128): TM128;
var i: Integer; temp: Cardinal;
begin
  for i := 0 to 7 do
  begin
    temp := Cardinal(a.m128i_u16[i]) * Cardinal(b.m128i_u16[i]);
    Result.m128i_u16[i] := UInt16(temp shr 16);
  end;
end;

function simd_mul_epu32(constref a, b: TM128): TM128;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.m128i_u64[i] := UInt64(a.m128i_u32[i * 2]) * UInt64(b.m128i_u32[i * 2]);
end;

// 其他复杂函数的占位符实现
function simd_slli_epi16(constref a: TM128; imm8: Byte): TM128;
var
  LIndex: Integer;
  LShift: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  LShift := imm8;
  if LShift < 16 then
    for LIndex := 0 to 7 do
      Result.m128i_u16[LIndex] := Word((DWord(a.m128i_u16[LIndex]) shl LShift) and $FFFF);
end;

function simd_slli_epi64(constref a: TM128; imm8: Byte): TM128;
var
  LIndex: Integer;
  LShift: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  LShift := imm8;
  if LShift < 64 then
    for LIndex := 0 to 1 do
      Result.m128i_u64[LIndex] := a.m128i_u64[LIndex] shl LShift;
end;

function simd_slli_si128(constref a: TM128; imm8: Byte): TM128;
var
  LIndex: Integer;
  LShift: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  LShift := imm8;
  if LShift <= 0 then
    Result := a
  else if LShift < 16 then
    for LIndex := LShift to 15 do
      Result.m128i_u8[LIndex] := a.m128i_u8[LIndex - LShift];
end;

function simd_srli_epi16(constref a: TM128; imm8: Byte): TM128;
var
  LIndex: Integer;
  LShift: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  LShift := imm8;
  if LShift < 16 then
    for LIndex := 0 to 7 do
      Result.m128i_u16[LIndex] := a.m128i_u16[LIndex] shr LShift;
end;

function simd_srli_epi64(constref a: TM128; imm8: Byte): TM128;
var
  LIndex: Integer;
  LShift: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  LShift := imm8;
  if LShift < 64 then
    for LIndex := 0 to 1 do
      Result.m128i_u64[LIndex] := a.m128i_u64[LIndex] shr LShift;
end;

function simd_srli_si128(constref a: TM128; imm8: Byte): TM128;
var
  LIndex: Integer;
  LShift: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  LShift := imm8;
  if LShift <= 0 then
    Result := a
  else if LShift < 16 then
    for LIndex := 0 to (15 - LShift) do
      Result.m128i_u8[LIndex] := a.m128i_u8[LIndex + LShift];
end;

function ArithmeticShiftRight16(aValue: SmallInt; aShift: Integer): SmallInt; inline;
var
  LBits: Word;
  LMask: Word;
begin
  if aShift <= 0 then
    Exit(aValue);

  if aShift >= 16 then
    aShift := 15;

  LBits := Word(aValue);
  if aValue >= 0 then
    Exit(SmallInt(LBits shr aShift));

  LMask := Word($FFFF shl (16 - aShift));
  Result := SmallInt((LBits shr aShift) or LMask);
end;

function simd_srai_epi16(constref a: TM128; imm8: Byte): TM128;
var
  LIndex: Integer;
  LShift: Integer;
begin
  LShift := imm8;
  if LShift >= 16 then
    LShift := 15;

  for LIndex := 0 to 7 do
    Result.m128i_i16[LIndex] := ArithmeticShiftRight16(a.m128i_i16[LIndex], LShift);
end;

function simd_sll_epi32(constref a, count: TM128): TM128; begin Result := a; end;
function simd_sll_epi16(constref a, count: TM128): TM128; begin Result := a; end;
function simd_sll_epi64(constref a, count: TM128): TM128; begin Result := a; end;
function simd_srl_epi32(constref a, count: TM128): TM128; begin Result := a; end;
function simd_srl_epi16(constref a, count: TM128): TM128; begin Result := a; end;
function simd_srl_epi64(constref a, count: TM128): TM128; begin Result := a; end;
function simd_sra_epi32(constref a, count: TM128): TM128; begin Result := a; end;
function simd_sra_epi16(constref a, count: TM128): TM128; begin Result := a; end;

function simd_packs_epi32(constref a, b: TM128): TM128; begin Result := a; end;
function simd_packs_epi16(constref a, b: TM128): TM128; begin Result := a; end;
function simd_packus_epi16(constref a, b: TM128): TM128; begin Result := a; end;
function simd_unpackhi_epi32(constref a, b: TM128): TM128; begin Result := a; end;
function simd_unpackhi_epi16(constref a, b: TM128): TM128; begin Result := a; end;
function simd_unpackhi_epi8(constref a, b: TM128): TM128; begin Result := a; end;
function simd_unpackhi_epi64(constref a, b: TM128): TM128; begin Result := a; end;
function simd_unpacklo_epi32(constref a, b: TM128): TM128; begin Result := a; end;
function simd_unpacklo_epi16(constref a, b: TM128): TM128; begin Result := a; end;
function simd_unpacklo_epi8(constref a, b: TM128): TM128; begin Result := a; end;
function simd_unpacklo_epi64(constref a, b: TM128): TM128; begin Result := a; end;

function simd_max_epi16(constref a, b: TM128): TM128;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.m128i_i16[i] > b.m128i_i16[i] then
      Result.m128i_i16[i] := a.m128i_i16[i]
    else
      Result.m128i_i16[i] := b.m128i_i16[i];
end;

function simd_max_epu8(constref a, b: TM128): TM128;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.m128i_u8[i] > b.m128i_u8[i] then
      Result.m128i_u8[i] := a.m128i_u8[i]
    else
      Result.m128i_u8[i] := b.m128i_u8[i];
end;

function simd_min_epi16(constref a, b: TM128): TM128;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.m128i_i16[i] < b.m128i_i16[i] then
      Result.m128i_i16[i] := a.m128i_i16[i]
    else
      Result.m128i_i16[i] := b.m128i_i16[i];
end;

function simd_min_epu8(constref a, b: TM128): TM128;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.m128i_u8[i] < b.m128i_u8[i] then
      Result.m128i_u8[i] := a.m128i_u8[i]
    else
      Result.m128i_u8[i] := b.m128i_u8[i];
end;

function simd_shuffle_epi32(constref a: TM128; imm8: Byte): TM128;
var
  LDest: Integer;
  LSrc: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for LDest := 0 to 3 do
  begin
    LSrc := (imm8 shr (LDest * 2)) and $3;
    Result.m128i_u32[LDest] := a.m128i_u32[LSrc];
  end;
end;
function simd_shufflehi_epi16(constref a: TM128; imm8: Byte): TM128;
var
  LDest: Integer;
  LSrc: Integer;
begin
  Result := a;
  for LDest := 0 to 3 do
  begin
    LSrc := 4 + ((imm8 shr (LDest * 2)) and $3);
    Result.m128i_u16[4 + LDest] := a.m128i_u16[LSrc];
  end;
end;

function simd_shufflelo_epi16(constref a: TM128; imm8: Byte): TM128;
var
  LDest: Integer;
  LSrc: Integer;
begin
  Result := a;
  for LDest := 0 to 3 do
  begin
    LSrc := (imm8 shr (LDest * 2)) and $3;
    Result.m128i_u16[LDest] := a.m128i_u16[LSrc];
  end;
end;

function simd_move_epi64(constref a: TM128): TM128;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.m128i_u64[0] := a.m128i_u64[0];
end;

function simd_movemask_epi8(constref a: TM128): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to 15 do
    if (a.m128i_u8[LIndex] and $80) <> 0 then
      Result := Result or (1 shl LIndex);
end;

function simd_insert_epi16(constref a: TM128; Value: Integer; imm8: Byte): TM128;
begin
  Result := a;
  Result.m128i_u16[imm8 and $7] := Word(Value and $FFFF);
end;

function simd_extract_epi16(constref a: TM128; imm8: Byte): Integer;
begin
  Result := a.m128i_u16[imm8 and $7];
end;

// 双精度浮点函数的占位符实�?
function simd_load_pd(const Ptr: Pointer): TM128; begin Result := PTM128(Ptr)^; end;
function simd_loadu_pd(const Ptr: Pointer): TM128; begin Result := PTM128(Ptr)^; end;
function simd_load_sd(const Ptr: Pointer): TM128; begin FillChar(Result, SizeOf(Result), 0); Result.m128d_f64[0] := PDouble(Ptr)^; end;
function simd_load1_pd(const Ptr: Pointer): TM128; begin Result := simd_set1_pd(PDouble(Ptr)^); end;
procedure simd_store_pd(var Dest; constref Src: TM128); begin PTM128(@Dest)^ := Src; end;
procedure simd_storeu_pd(var Dest; constref Src: TM128); begin PTM128(@Dest)^ := Src; end;
procedure simd_store_sd(var Dest; constref Src: TM128); begin PDouble(@Dest)^ := Src.m128d_f64[0]; end;
procedure simd_store1_pd(var Dest; constref Src: TM128); begin simd_store_pd(Dest, simd_set1_pd(Src.m128d_f64[0])); end;

function simd_set_pd(e1, e0: Double): TM128; begin Result.m128d_f64[0] := e0; Result.m128d_f64[1] := e1; end;
function simd_set_sd(Value: Double): TM128; begin FillChar(Result, SizeOf(Result), 0); Result.m128d_f64[0] := Value; end;
function simd_setr_pd(e0, e1: Double): TM128; begin Result.m128d_f64[0] := e0; Result.m128d_f64[1] := e1; end;

function simd_add_sd(constref a, b: TM128): TM128; begin Result := a; Result.m128d_f64[0] := a.m128d_f64[0] + b.m128d_f64[0]; end;
function simd_sub_sd(constref a, b: TM128): TM128; begin Result := a; Result.m128d_f64[0] := a.m128d_f64[0] - b.m128d_f64[0]; end;
function simd_mul_sd(constref a, b: TM128): TM128; begin Result := a; Result.m128d_f64[0] := a.m128d_f64[0] * b.m128d_f64[0]; end;
function simd_div_sd(constref a, b: TM128): TM128; begin Result := a; Result.m128d_f64[0] := a.m128d_f64[0] / b.m128d_f64[0]; end;

function simd_sqrt_pd(constref a: TM128): TM128; var i: Integer; begin for i := 0 to 1 do Result.m128d_f64[i] := Sqrt(a.m128d_f64[i]); end;
function simd_sqrt_sd(constref a: TM128): TM128; begin Result := a; Result.m128d_f64[0] := Sqrt(a.m128d_f64[0]); end;

function simd_min_pd(constref a, b: TM128): TM128; var i: Integer; begin for i := 0 to 1 do if a.m128d_f64[i] < b.m128d_f64[i] then Result.m128d_f64[i] := a.m128d_f64[i] else Result.m128d_f64[i] := b.m128d_f64[i]; end;
function simd_min_sd(constref a, b: TM128): TM128; begin Result := a; if a.m128d_f64[0] < b.m128d_f64[0] then Result.m128d_f64[0] := a.m128d_f64[0] else Result.m128d_f64[0] := b.m128d_f64[0]; end;
function simd_max_pd(constref a, b: TM128): TM128; var i: Integer; begin for i := 0 to 1 do if a.m128d_f64[i] > b.m128d_f64[i] then Result.m128d_f64[i] := a.m128d_f64[i] else Result.m128d_f64[i] := b.m128d_f64[i]; end;
function simd_max_sd(constref a, b: TM128): TM128; begin Result := a; if a.m128d_f64[0] > b.m128d_f64[0] then Result.m128d_f64[0] := a.m128d_f64[0] else Result.m128d_f64[0] := b.m128d_f64[0]; end;

function simd_and_pd(constref a, b: TM128): TM128; begin Result := simd_and_si128(a, b); end;
function simd_andnot_pd(constref a, b: TM128): TM128; begin Result := simd_andnot_si128(a, b); end;
function simd_or_pd(constref a, b: TM128): TM128; begin Result := simd_or_si128(a, b); end;
function simd_xor_pd(constref a, b: TM128): TM128; begin Result := simd_xor_si128(a, b); end;

// 其他复杂函数的占位符实现
function simd_cmpeq_pd(constref a, b: TM128): TM128; begin Result := a; end;
function simd_cmpeq_sd(constref a, b: TM128): TM128; begin Result := a; end;
function simd_cmplt_pd(constref a, b: TM128): TM128; begin Result := a; end;
function simd_cmplt_sd(constref a, b: TM128): TM128; begin Result := a; end;
function simd_cmple_pd(constref a, b: TM128): TM128; begin Result := a; end;
function simd_cmple_sd(constref a, b: TM128): TM128; begin Result := a; end;
function simd_cmpgt_pd(constref a, b: TM128): TM128; begin Result := a; end;
function simd_cmpgt_sd(constref a, b: TM128): TM128; begin Result := a; end;
function simd_cmpge_pd(constref a, b: TM128): TM128; begin Result := a; end;
function simd_cmpge_sd(constref a, b: TM128): TM128; begin Result := a; end;
function simd_cmpneq_pd(constref a, b: TM128): TM128; begin Result := a; end;
function simd_cmpneq_sd(constref a, b: TM128): TM128; begin Result := a; end;

function simd_shuffle_pd(constref a, b: TM128; imm8: Byte): TM128; begin Result := a; end;
function simd_unpackhi_pd(constref a, b: TM128): TM128; begin Result := a; end;
function simd_unpacklo_pd(constref a, b: TM128): TM128; begin Result := a; end;

function simd_move_sd(constref a, b: TM128): TM128; begin Result := a; end;
function simd_movemask_pd(constref a: TM128): Integer; begin Result := 0; end;

function simd_cvtsi2sd(constref a: TM128; Value: LongInt): TM128; begin Result := a; end;
function simd_cvtsd2si(constref a: TM128): LongInt; begin Result := 0; end;
function simd_cvttsd2si(constref a: TM128): LongInt; begin Result := 0; end;
function simd_cvtps2pd(constref a: TM128): TM128; begin Result := a; end;
function simd_cvtpd2ps(constref a: TM128): TM128; begin Result := a; end;
function simd_cvtss2sd(constref a, b: TM128): TM128; begin Result := a; end;
function simd_cvtsd2ss(constref a, b: TM128): TM128; begin Result := a; end;
function simd_cvtdq2pd(constref a: TM128): TM128; begin Result := a; end;
function simd_cvtpd2dq(constref a: TM128): TM128; begin Result := a; end;
function simd_cvttps2dq(constref a: TM128): TM128; begin Result := a; end;
function simd_cvtps2dq(constref a: TM128): TM128; begin Result := a; end;
function simd_cvtdq2ps(constref a: TM128): TM128; begin Result := a; end;

procedure simd_lfence; begin end;
procedure simd_mfence; begin end;
procedure simd_pause; begin end;
procedure simd_clflush(const Ptr: Pointer); begin end;

initialization
  EnsureExperimentalIntrinsicsEnabled;

end.

