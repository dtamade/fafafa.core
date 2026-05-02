unit fafafa.core.simd.intrinsics.x86.sse2;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

// === SSE2 Intrinsics 完整接口 ===
// SSE2 �?x86-64 的基础指令集，所�?x86-64 CPU 都支�?
// 提供 128-bit 向量操作，是最重要的基础指令�?
// 类型 TM128 对应 __m128i / __m128 / __m128d，前缀统一 simd_

uses
  fafafa.core.simd.intrinsics.base;

// === 1️⃣ Load / Store ===
// Integer Load/Store
function simd_load_si128(const Ptr: Pointer): TM128;
function simd_loadu_si128(const Ptr: Pointer): TM128;
procedure simd_store_si128(var Dest; constref Src: TM128);
procedure simd_storeu_si128(var Dest; constref Src: TM128);
function simd_loadl_epi64(const Ptr: Pointer): TM128; // Load lower 64-bit integer
procedure simd_storel_epi64(var Dest; constref Src: TM128); // Store lower 64-bit integer
procedure simd_maskmoveu_si128(constref Src: TM128; constref Mask: TM128; var Dest); // Conditional store using mask

// Double Load/Store
function simd_load_pd(const Ptr: Pointer): TM128;
function simd_loadu_pd(const Ptr: Pointer): TM128;
procedure simd_store_pd(var Dest; constref Src: TM128);
procedure simd_storeu_pd(var Dest; constref Src: TM128);
function simd_loadr_pd(const Ptr: Pointer): TM128; // Load reverse packed double
procedure simd_storer_pd(var Dest; constref Src: TM128); // Store reverse packed double
function simd_loadh_pd(constref A: TM128; const Ptr: Pointer): TM128; // Load high double
function simd_loadl_pd(constref A: TM128; const Ptr: Pointer): TM128; // Load low double
procedure simd_storeh_pd(var Dest; constref Src: TM128); // Store high double
procedure simd_storel_pd(var Dest; constref Src: TM128); // Store low double
function simd_load_sd(const Ptr: Pointer): TM128; // Load scalar double
procedure simd_store_sd(var Dest; constref Src: TM128); // Store scalar double

// Single Load/Store
function simd_load_ps(const Ptr: Pointer): TM128;
function simd_loadu_ps(const Ptr: Pointer): TM128;
procedure simd_store_ps(var Dest; constref Src: TM128);
procedure simd_storeu_ps(var Dest; constref Src: TM128);

// === 2️⃣ Set / Zero / Broadcast ===
// Zero
function simd_setzero_si128: TM128;
function simd_setzero_pd: TM128;
function simd_setzero_ps: TM128;

// Set1 (Broadcast)
function simd_set1_epi8(Value: ShortInt): TM128;
function simd_set1_epi16(Value: SmallInt): TM128;
function simd_set1_epi32(Value: LongInt): TM128;
function simd_set1_epi64x(Value: Int64): TM128;
function simd_set1_ps(Value: Single): TM128;
function simd_set1_pd(Value: Double): TM128;

// Set (Reverse order)
function simd_setr_epi32(a, b, c, d: LongInt): TM128;
function simd_set_epi32(a, b, c, d: LongInt): TM128;
function simd_setr_pd(a, b: Double): TM128;
function simd_set_epi64x(a, b: Int64): TM128;
function simd_set_epi8(a15, a14, a13, a12, a11, a10, a9, a8, a7, a6, a5, a4, a3, a2, a1, a0: ShortInt): TM128; // Set 16 8-bit integers
function simd_setr_epi8(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15: ShortInt): TM128; // Set reverse 16 8-bit integers
function simd_set_epi16(a7, a6, a5, a4, a3, a2, a1, a0: SmallInt): TM128; // Set 8 16-bit integers
function simd_setr_epi16(a0, a1, a2, a3, a4, a5, a6, a7: SmallInt): TM128; // Set reverse 8 16-bit integers
function simd_set_epi64(a, b: Int64): TM128; // Set 2 64-bit integers
function simd_setr_epi64(a, b: Int64): TM128; // Set reverse 2 64-bit integers
function simd_set_pd(a, b: Double): TM128; // Set 2 doubles (high, low)

// === 3️⃣ Integer Arithmetic ===
// Add
function simd_add_epi8(constref a, b: TM128): TM128;
function simd_add_epi16(constref a, b: TM128): TM128;
function simd_add_epi32(constref a, b: TM128): TM128;
function simd_add_epi64(constref a, b: TM128): TM128;

// Sub
function simd_sub_epi8(constref a, b: TM128): TM128;
function simd_sub_epi16(constref a, b: TM128): TM128;
function simd_sub_epi32(constref a, b: TM128): TM128;
function simd_sub_epi64(constref a, b: TM128): TM128;

// Saturated Add/Sub
function simd_adds_epi8(constref a, b: TM128): TM128;   // signed saturated add
function simd_adds_epi16(constref a, b: TM128): TM128;
function simd_subs_epi8(constref a, b: TM128): TM128;   // signed saturated sub
function simd_subs_epi16(constref a, b: TM128): TM128;
function simd_adds_epu8(constref a, b: TM128): TM128; // unsigned saturated add 8-bit
function simd_adds_epu16(constref a, b: TM128): TM128; // unsigned saturated add 16-bit
function simd_subs_epu8(constref a, b: TM128): TM128; // unsigned saturated sub 8-bit
function simd_subs_epu16(constref a, b: TM128): TM128; // unsigned saturated sub 16-bit

// Min/Max
function simd_max_epi8(constref a, b: TM128): TM128;
function simd_max_epi16(constref a, b: TM128): TM128;
function simd_min_epi8(constref a, b: TM128): TM128;
function simd_min_epi16(constref a, b: TM128): TM128;
function simd_max_epu8(constref a, b: TM128): TM128; // Max unsigned 8-bit
function simd_min_epu8(constref a, b: TM128): TM128; // Min unsigned 8-bit

// Multiply
function simd_mul_epu32(constref a, b: TM128): TM128;   // unsigned 32-bit multiply
function simd_mullo_epi16(constref a, b: TM128): TM128; // signed 16-bit multiply low
function simd_mulhi_epi16(constref a, b: TM128): TM128; // signed 16-bit multiply high
function simd_mulhi_epu16(constref a, b: TM128): TM128; // unsigned 16-bit multiply high
function simd_madd_epi16(constref a, b: TM128): TM128; // Multiply and add 16-bit to 32-bit

// Average
function simd_avg_epu8(constref a, b: TM128): TM128; // Average unsigned 8-bit
function simd_avg_epu16(constref a, b: TM128): TM128; // Average unsigned 16-bit

// SAD
function simd_sad_epu8(constref a, b: TM128): TM128; // Sum of absolute differences unsigned 8-bit

// === 4️⃣ Floating-Point Arithmetic ===
// Single Precision
function simd_add_ps(constref a, b: TM128): TM128;
function simd_sub_ps(constref a, b: TM128): TM128;
function simd_mul_ps(constref a, b: TM128): TM128;
function simd_div_ps(constref a, b: TM128): TM128;
function simd_sqrt_ps(constref a: TM128): TM128;
function simd_min_ps(constref a, b: TM128): TM128; // Min single
function simd_max_ps(constref a, b: TM128): TM128; // Max single

// Double Precision
function simd_add_pd(constref a, b: TM128): TM128;
function simd_sub_pd(constref a, b: TM128): TM128;
function simd_mul_pd(constref a, b: TM128): TM128;
function simd_div_pd(constref a, b: TM128): TM128;
function simd_sqrt_pd(constref a: TM128): TM128;
function simd_min_pd(constref a, b: TM128): TM128; // Min packed double
function simd_max_pd(constref a, b: TM128): TM128; // Max packed double
function simd_add_sd(constref a, b: TM128): TM128; // Add scalar double
function simd_sub_sd(constref a, b: TM128): TM128; // Sub scalar double
function simd_mul_sd(constref a, b: TM128): TM128; // Mul scalar double
function simd_div_sd(constref a, b: TM128): TM128; // Div scalar double
function simd_sqrt_sd(constref a, b: TM128): TM128; // Sqrt scalar double (a upper pass through)
function simd_min_sd(constref a, b: TM128): TM128; // Min scalar double
function simd_max_sd(constref a, b: TM128): TM128; // Max scalar double

// === 5️⃣ Logical Operations ===
function simd_and_si128(constref a, b: TM128): TM128;
function simd_or_si128(constref a, b: TM128): TM128;
function simd_xor_si128(constref a, b: TM128): TM128;
function simd_andnot_si128(constref a, b: TM128): TM128;  // ~a & b
function simd_and_pd(constref a, b: TM128): TM128; // And packed double
function simd_or_pd(constref a, b: TM128): TM128; // Or packed double
function simd_xor_pd(constref a, b: TM128): TM128; // Xor packed double
function simd_andnot_pd(constref a, b: TM128): TM128; // Andnot packed double

// === 6️⃣ Compare / Mask ===
// Integer Compare
function simd_cmpeq_epi8(constref a, b: TM128): TM128;
function simd_cmpeq_epi16(constref a, b: TM128): TM128;
function simd_cmpeq_epi32(constref a, b: TM128): TM128;
function simd_cmpgt_epi8(constref a, b: TM128): TM128;
function simd_cmpgt_epi16(constref a, b: TM128): TM128;
function simd_cmpgt_epi32(constref a, b: TM128): TM128;
function simd_cmplt_epi8(constref a, b: TM128): TM128;
function simd_cmplt_epi16(constref a, b: TM128): TM128;
function simd_cmplt_epi32(constref a, b: TM128): TM128;

// Floating-Point Compare
function simd_cmpeq_pd(constref a, b: TM128): TM128;
function simd_cmplt_pd(constref a, b: TM128): TM128;
function simd_cmple_pd(constref a, b: TM128): TM128;
function simd_cmpgt_pd(constref a, b: TM128): TM128;
function simd_cmpge_pd(constref a, b: TM128): TM128;
function simd_cmpneq_pd(constref a, b: TM128): TM128;
function simd_cmpnlt_pd(constref a, b: TM128): TM128; // Not less than packed double
function simd_cmpnle_pd(constref a, b: TM128): TM128; // Not less or equal packed double
function simd_cmpngt_pd(constref a, b: TM128): TM128; // Not greater than packed double
function simd_cmpnge_pd(constref a, b: TM128): TM128; // Not greater or equal packed double
function simd_cmpord_pd(constref a, b: TM128): TM128; // Ordered packed double
function simd_cmpunord_pd(constref a, b: TM128): TM128; // Unordered packed double
function simd_cmpeq_sd(constref a, b: TM128): TM128; // Equal scalar double
function simd_cmplt_sd(constref a, b: TM128): TM128; // Less than scalar double
function simd_cmple_sd(constref a, b: TM128): TM128; // Less or equal scalar double
function simd_cmpgt_sd(constref a, b: TM128): TM128; // Greater than scalar double
function simd_cmpge_sd(constref a, b: TM128): TM128; // Greater or equal scalar double
function simd_cmpneq_sd(constref a, b: TM128): TM128; // Not equal scalar double
function simd_cmpnlt_sd(constref a, b: TM128): TM128; // Not less than scalar double
function simd_cmpnle_sd(constref a, b: TM128): TM128; // Not less or equal scalar double
function simd_cmpngt_sd(constref a, b: TM128): TM128; // Not greater than scalar double
function simd_cmpnge_sd(constref a, b: TM128): TM128; // Not greater or equal scalar double
function simd_cmpord_sd(constref a, b: TM128): TM128; // Ordered scalar double
function simd_cmpunord_sd(constref a, b: TM128): TM128; // Unordered scalar double
function simd_comieq_sd(constref a, b: TM128): Integer; // Scalar ordered equal compare, return int
function simd_comilt_sd(constref a, b: TM128): Integer; // Scalar ordered less than compare, return int
function simd_comile_sd(constref a, b: TM128): Integer; // Scalar ordered less or equal, return int
function simd_comigt_sd(constref a, b: TM128): Integer; // Scalar ordered greater than, return int
function simd_comige_sd(constref a, b: TM128): Integer; // Scalar ordered greater or equal, return int
function simd_comineq_sd(constref a, b: TM128): Integer; // Scalar ordered not equal, return int
function simd_ucomieq_sd(constref a, b: TM128): Integer; // Scalar unordered equal compare, return int
function simd_ucomilt_sd(constref a, b: TM128): Integer; // Scalar unordered less than, return int
function simd_ucomile_sd(constref a, b: TM128): Integer; // Scalar unordered less or equal, return int
function simd_ucomigt_sd(constref a, b: TM128): Integer; // Scalar unordered greater than, return int
function simd_ucomige_sd(constref a, b: TM128): Integer; // Scalar unordered greater or equal, return int
function simd_ucomineq_sd(constref a, b: TM128): Integer; // Scalar unordered not equal, return int

// Move Mask
function simd_movemask_epi8(constref a: TM128): Integer;
function simd_movemask_ps(constref a: TM128): Integer;
function simd_movemask_pd(constref a: TM128): Integer;

// === 7️⃣ Shuffle / Unpack / Permute ===
// Shuffle
function simd_shuffle_epi32(constref a: TM128; imm8: Byte): TM128;
function simd_shuffle_pd(constref a, b: TM128; imm8: Byte): TM128;
function simd_shuffle_ps(constref a, b: TM128; imm8: Byte): TM128; // Shuffle single
function simd_shufflelo_epi16(constref a: TM128; imm8: Byte): TM128; // Shuffle low 16-bit
function simd_shufflehi_epi16(constref a: TM128; imm8: Byte): TM128; // Shuffle high 16-bit

// Unpack
function simd_unpacklo_epi8(constref a, b: TM128): TM128;
function simd_unpackhi_epi8(constref a, b: TM128): TM128;
function simd_unpacklo_epi16(constref a, b: TM128): TM128;
function simd_unpackhi_epi16(constref a, b: TM128): TM128;
function simd_unpacklo_epi32(constref a, b: TM128): TM128;
function simd_unpackhi_epi32(constref a, b: TM128): TM128;
function simd_unpacklo_epi64(constref a, b: TM128): TM128;
function simd_unpackhi_epi64(constref a, b: TM128): TM128;
function simd_unpacklo_pd(constref a, b: TM128): TM128;
function simd_unpackhi_pd(constref a, b: TM128): TM128;
function simd_unpacklo_ps(constref a, b: TM128): TM128; // Unpack low single
function simd_unpackhi_ps(constref a, b: TM128): TM128; // Unpack high single

// === 8️⃣ Shift / Rotate (Integers) ===
// Left Shift
function simd_slli_epi16(constref a: TM128; imm8: Byte): TM128;
function simd_slli_epi32(constref a: TM128; imm8: Byte): TM128;
function simd_slli_epi64(constref a: TM128; imm8: Byte): TM128;
function simd_slli_si128(constref a: TM128; imm8: Byte): TM128; // Left shift bytes in 128-bit

// Right Shift (Logical)
function simd_srli_epi16(constref a: TM128; imm8: Byte): TM128;
function simd_srli_epi32(constref a: TM128; imm8: Byte): TM128;
function simd_srli_epi64(constref a: TM128; imm8: Byte): TM128;
function simd_srli_si128(constref a: TM128; imm8: Byte): TM128; // Right shift bytes in 128-bit

// Right Shift (Arithmetic)
function simd_srai_epi16(constref a: TM128; imm8: Byte): TM128;
function simd_srai_epi32(constref a: TM128; imm8: Byte): TM128;
function simd_srai_si128(constref a: TM128; imm8: Byte): TM128; // Arithmetic right shift bytes (sign extend)

// === 9️⃣ Conversion / Cast ===
// Type Conversion
function simd_cvtepi32_pd(constref a: TM128): TM128;
function simd_cvtpd_epi32(constref a: TM128): TM128;
function simd_cvtepi32_ps(constref a: TM128): TM128;
function simd_cvtps_epi32(constref a: TM128): TM128;
function simd_cvtpd_ps(constref a: TM128): TM128; // Packed double to packed single
function simd_cvtps_pd(constref a: TM128): TM128; // Packed single to packed double
function simd_cvtsd_ss(constref a, b: TM128): TM128; // Scalar double to scalar single
function simd_cvtss_sd(constref a, b: TM128): TM128; // Scalar single to scalar double
function simd_cvttpd_epi32(constref a: TM128): TM128; // Truncate packed double to epi32
function simd_cvttpd_ps(constref a: TM128): TM128; // Truncate packed double to single
function simd_cvttps_epi32(constref a: TM128): TM128; // Truncate packed single to epi32
function simd_cvtsd_si32(constref a: TM128): Integer; // Scalar double to si32
function simd_cvtsd_si64(constref a: TM128): Int64; // Scalar double to si64
function simd_cvttsd_si32(constref a: TM128): Integer; // Truncate scalar double to si32
function simd_cvttsd_si64(constref a: TM128): Int64; // Truncate scalar double to si64

// Scalar Conversion
function simd_cvtsi32_si128(a: Integer): TM128;
function simd_cvtsi64_si128(a: Int64): TM128;
function simd_cvtsi128_si32(constref a: TM128): Integer;
function simd_cvtsi128_si64(constref a: TM128): Int64;
function simd_cvtsi32_sd(constref a: TM128; b: Integer): TM128; // si32 to scalar double
function simd_cvtsi64_sd(constref a: TM128; b: Int64): TM128; // si64 to scalar double

// Cast (No Conversion)
function simd_castpd_si128(constref a: TM128): TM128;
function simd_castps_si128(constref a: TM128): TM128;
function simd_castsi128_pd(constref a: TM128): TM128;
function simd_castsi128_ps(constref a: TM128): TM128;
function simd_castpd_ps(constref a: TM128): TM128; // Cast double to single
function simd_castps_pd(constref a: TM128): TM128; // Cast single to double

// === 🔟 Pack / Insert / Extract / Move ===
function simd_packs_epi16(constref a, b: TM128): TM128; // Pack signed 16-bit to signed 8-bit with saturation
function simd_packs_epi32(constref a, b: TM128): TM128; // Pack signed 32-bit to signed 16-bit with saturation
function simd_packus_epi16(constref a, b: TM128): TM128; // Pack signed 16-bit to unsigned 8-bit with saturation
function simd_insert_epi16(constref a: TM128; Value: Integer; imm8: Byte): TM128; // Insert 16-bit at position
function simd_extract_epi16(constref a: TM128; imm8: Byte): Integer; // Extract 16-bit at position
function simd_move_sd(constref a, b: TM128): TM128; // Move scalar double
function simd_move_epi64(constref a: TM128): TM128; // Move 64-bit integer

// === 1️⃣1️⃣ Cache Control / Stream / Fence ===
procedure simd_clflush(const Ptr: Pointer); // Cache line flush
procedure simd_lfence; // Load fence
procedure simd_mfence; // Memory fence
procedure simd_pause; // Pause (spin loop hint)
procedure simd_stream_pd(var Dest; constref Src: TM128); // Non-temporal store packed double
procedure simd_stream_ps(var Dest; constref Src: TM128); // Non-temporal store packed single
procedure simd_stream_si128(var Dest; constref Src: TM128); // Non-temporal store 128-bit
procedure simd_stream_si32(var Dest; Value: Integer); // Non-temporal store 32-bit
procedure simd_stream_si64(var Dest; Value: Int64); // Non-temporal store 64-bit

implementation

uses
  SysUtils, Math;

procedure EnsureExperimentalIntrinsicsEnabled; inline;
begin
  {$IFNDEF FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS}
  raise ENotSupportedException.Create(
    'fafafa.core.simd.intrinsics.x86.sse2 is experimental placeholder semantics. ' +
    'Define FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS to opt in.'
  );
  {$ENDIF}
end;

function SaturateToI8(aValue: Integer): ShortInt; inline;
begin
  if aValue > High(ShortInt) then
    Exit(High(ShortInt));
  if aValue < Low(ShortInt) then
    Exit(Low(ShortInt));
  Result := ShortInt(aValue);
end;

function SaturateToI16(aValue: Integer): SmallInt; inline;
begin
  if aValue > High(SmallInt) then
    Exit(High(SmallInt));
  if aValue < Low(SmallInt) then
    Exit(Low(SmallInt));
  Result := SmallInt(aValue);
end;

function SaturateToU8(aValue: Integer): Byte; inline;
begin
  if aValue <= 0 then
    Exit(0);
  if aValue >= High(Byte) then
    Exit(High(Byte));
  Result := Byte(aValue);
end;

function SelectMinSingle(aLeft, aRight: Single): Single; inline;
begin
  if IsNan(aLeft) or IsNan(aRight) then
    Exit(aRight);
  if aLeft < aRight then
    Exit(aLeft);
  Result := aRight;
end;

function SelectMaxSingle(aLeft, aRight: Single): Single; inline;
begin
  if IsNan(aLeft) or IsNan(aRight) then
    Exit(aRight);
  if aLeft > aRight then
    Exit(aLeft);
  Result := aRight;
end;

function SelectMinDouble(aLeft, aRight: Double): Double; inline;
begin
  if IsNan(aLeft) or IsNan(aRight) then
    Exit(aRight);
  if aLeft < aRight then
    Exit(aLeft);
  Result := aRight;
end;

function SelectMaxDouble(aLeft, aRight: Double): Double; inline;
begin
  if IsNan(aLeft) or IsNan(aRight) then
    Exit(aRight);
  if aLeft > aRight then
    Exit(aLeft);
  Result := aRight;
end;

function BoolMask64(aValue: Boolean): QWord; inline;
begin
  if aValue then
    Exit(High(QWord));
  Result := 0;
end;

function IsUnorderedDoubleCompare(aLeft, aRight: Double): Boolean; inline;
begin
  Result := IsNan(aLeft) or IsNan(aRight);
end;

function CompareEqOrderedDouble(aLeft, aRight: Double): Boolean; inline;
begin
  Result := (not IsUnorderedDoubleCompare(aLeft, aRight)) and (aLeft = aRight);
end;

function CompareLtOrderedDouble(aLeft, aRight: Double): Boolean; inline;
begin
  Result := (not IsUnorderedDoubleCompare(aLeft, aRight)) and (aLeft < aRight);
end;

function CompareLeOrderedDouble(aLeft, aRight: Double): Boolean; inline;
begin
  Result := (not IsUnorderedDoubleCompare(aLeft, aRight)) and (aLeft <= aRight);
end;

function CompareGtOrderedDouble(aLeft, aRight: Double): Boolean; inline;
begin
  Result := (not IsUnorderedDoubleCompare(aLeft, aRight)) and (aLeft > aRight);
end;

function CompareGeOrderedDouble(aLeft, aRight: Double): Boolean; inline;
begin
  Result := (not IsUnorderedDoubleCompare(aLeft, aRight)) and (aLeft >= aRight);
end;

function CompareNeqDouble(aLeft, aRight: Double): Boolean; inline;
begin
  Result := IsUnorderedDoubleCompare(aLeft, aRight) or (aLeft <> aRight);
end;

function CompareNltDouble(aLeft, aRight: Double): Boolean; inline;
begin
  Result := IsUnorderedDoubleCompare(aLeft, aRight) or (aLeft >= aRight);
end;

function CompareNleDouble(aLeft, aRight: Double): Boolean; inline;
begin
  Result := IsUnorderedDoubleCompare(aLeft, aRight) or (aLeft > aRight);
end;

function MakeScalarCompareResult(const aSource: TM128; aMask: Boolean): TM128; inline;
begin
  Result := aSource;
  Result.m128i_u64[0] := BoolMask64(aMask);
end;

// === SSE2 Intrinsics 实现 ===
// 目前提供占位实现，后续将添加实际的内联汇编代�?
// === 1️⃣ Load / Store 实现 ===
function simd_load_si128(const Ptr: Pointer): TM128;
begin
  Move(PByte(Ptr)^, Result, SizeOf(Result));
end;

function simd_loadu_si128(const Ptr: Pointer): TM128;
begin
  Move(PByte(Ptr)^, Result, SizeOf(Result));
end;

procedure simd_store_si128(var Dest; constref Src: TM128); {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Dest �?rcx, Src �?rdx
    movdqu xmm0, [rdx] // Src 可能只是 constref，不能假定 16-byte 对齐
    movdqa [rcx], xmm0    // 对齐存储到目�?
    {$ELSE}
    // Linux/macOS x64 System V ABI: Dest �?rdi, Src �?rsi
    movdqu xmm0, [rsi] // Src 可能只是 constref，不能假定 16-byte 对齐
    movdqa [rdi], xmm0    // 对齐存储到目�?
    {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    // x86 32-bit: 参数在栈�?
    mov eax, [esp + 4]    // Dest
    mov edx, [esp + 8]    // Src
    movdqu xmm0, [edx] // Src 可能只是 constref，不能假定 16-byte 对齐
    movdqa [eax], xmm0    // 对齐存储到目�?
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

procedure simd_storeu_si128(var Dest; constref Src: TM128); {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Dest �?rcx, Src �?rdx
    movdqu xmm0, [rdx]    // 非对齐加载源数据
    movdqu [rcx], xmm0    // 非对齐存储到目标
  {$ELSE}
    // Linux/macOS x64 System V ABI: Dest �?rdi, Src �?rsi
    movdqu xmm0, [rsi]    // 非对齐加载源数据
    movdqu [rdi], xmm0    // 非对齐存储到目标
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    // x86 32-bit: 参数在栈�?
    mov eax, [esp + 4]    // Dest
    mov edx, [esp + 8]    // Src
    movdqu xmm0, [edx]    // 非对齐加载源数据
    movdqu [eax], xmm0    // 非对齐存储到目标
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

// Double Load/Store
function simd_load_pd(const Ptr: Pointer): TM128;
begin
  Move(PByte(Ptr)^, Result, SizeOf(Result));
end;

function simd_loadu_pd(const Ptr: Pointer): TM128;
begin
  Move(PByte(Ptr)^, Result, SizeOf(Result));
end;

procedure simd_store_pd(var Dest; constref Src: TM128); {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Dest �?rcx, Src �?rdx
    movupd xmm0, [rdx] // Src 可能只是 constref，不能假定 16-byte 对齐
    movapd [rcx], xmm0    // 对齐存储到目�?
    {$ELSE}
    // Linux/macOS x64 System V ABI: Dest �?rdi, Src �?rsi
    movupd xmm0, [rsi] // Src 可能只是 constref，不能假定 16-byte 对齐
    movapd [rdi], xmm0    // 对齐存储到目�?
    {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    // x86 32-bit: 参数在栈�?
    mov eax, [esp + 4]    // Dest
    mov edx, [esp + 8]    // Src
    movupd xmm0, [edx] // Src 可能只是 constref，不能假定 16-byte 对齐
    movapd [eax], xmm0    // 对齐存储到目�?
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

procedure simd_storeu_pd(var Dest; constref Src: TM128); {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Dest �?rcx, Src �?rdx
    movupd xmm0, [rdx]    // 非对齐加载源数据
    movupd [rcx], xmm0    // 非对齐存储到目标
  {$ELSE}
    // Linux/macOS x64 System V ABI: Dest �?rdi, Src �?rsi
    movupd xmm0, [rsi]    // 非对齐加载源数据
    movupd [rdi], xmm0    // 非对齐存储到目标
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    // x86 32-bit: 参数在栈�?
    mov eax, [esp + 4]    // Dest
    mov edx, [esp + 8]    // Src
    movupd xmm0, [edx]    // 非对齐加载源数据
    movupd [eax], xmm0    // 非对齐存储到目标
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

// Single Load/Store
function simd_load_ps(const Ptr: Pointer): TM128;
begin
  Move(PByte(Ptr)^, Result, SizeOf(Result));
end;

function simd_loadu_ps(const Ptr: Pointer): TM128;
begin
  Move(PByte(Ptr)^, Result, SizeOf(Result));
end;

procedure simd_store_ps(var Dest; constref Src: TM128); {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Dest �?rcx, Src �?rdx
    movups xmm0, [rdx] // Src 可能只是 constref，不能假定 16-byte 对齐
    movaps [rcx], xmm0    // 对齐存储到目�?
    {$ELSE}
    // Linux/macOS x64 System V ABI: Dest �?rdi, Src �?rsi
    movups xmm0, [rsi] // Src 可能只是 constref，不能假定 16-byte 对齐
    movaps [rdi], xmm0    // 对齐存储到目�?
    {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    // x86 32-bit: 参数在栈�?
    mov eax, [esp + 4]    // Dest
    mov edx, [esp + 8]    // Src
    movups xmm0, [edx] // Src 可能只是 constref，不能假定 16-byte 对齐
    movaps [eax], xmm0    // 对齐存储到目�?
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

procedure simd_storeu_ps(var Dest; constref Src: TM128); {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Dest �?rcx, Src �?rdx
    movups xmm0, [rdx]    // 非对齐加载源数据
    movups [rcx], xmm0    // 非对齐存储到目标
  {$ELSE}
    // Linux/macOS x64 System V ABI: Dest �?rdi, Src �?rsi
    movups xmm0, [rsi]    // 非对齐加载源数据
    movups [rdi], xmm0    // 非对齐存储到目标
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    // x86 32-bit: 参数在栈�?
    mov eax, [esp + 4]    // Dest
    mov edx, [esp + 8]    // Src
    movups xmm0, [edx]    // 非对齐加载源数据
    movups [eax], xmm0    // 非对齐存储到目标
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

// === 2️⃣ Set / Zero / Broadcast 实现 ===
function simd_setzero_si128: TM128;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function simd_setzero_pd: TM128;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function simd_setzero_ps: TM128;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function simd_set1_epi8(Value: ShortInt): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    Result.m128i_i8[LIndex] := Value;
end;

function simd_set1_epi16(Value: SmallInt): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    Result.m128i_i16[LIndex] := Value;
end;

function simd_set1_epi32(Value: LongInt): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128i_i32[LIndex] := Value;
end;

function simd_set1_epi64x(Value: Int64): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128i_i64[LIndex] := Value;
end;

function simd_set1_ps(Value: Single): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128_f32[LIndex] := Value;
end;

function simd_set1_pd(Value: Double): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128d_f64[LIndex] := Value;
end;

// === 复杂 Set 函数实现 ===
// 重复�?Set 函数实现已删除，保留第二个版�?
// === Set 函数实现 ===
function simd_setr_epi32(a, b, c, d: LongInt): TM128;
begin
  Result.m128i_i32[0] := a;
  Result.m128i_i32[1] := b;
  Result.m128i_i32[2] := c;
  Result.m128i_i32[3] := d;
end;

function simd_set_epi32(a, b, c, d: LongInt): TM128;
begin
  Result.m128i_i32[0] := d;
  Result.m128i_i32[1] := c;
  Result.m128i_i32[2] := b;
  Result.m128i_i32[3] := a;
end;

function simd_setr_pd(a, b: Double): TM128;
begin
  Result.m128d_f64[0] := a;
  Result.m128d_f64[1] := b;
end;

function simd_set_epi64x(a, b: Int64): TM128;
begin
  Result.m128i_i64[0] := b;
  Result.m128i_i64[1] := a;
end;

// === 剩余函数的占位实�?===
// 为了编译通过，这里提供简单的占位实现
// 后续将逐步添加实际的内联汇编代�?
// 关键函数的占位实�?
function simd_add_epi8(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    Result.m128i_u8[LIndex] := Byte((Integer(a.m128i_u8[LIndex]) + Integer(b.m128i_u8[LIndex])) and $FF);
end;

function simd_cmpeq_epi8(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    if a.m128i_u8[LIndex] = b.m128i_u8[LIndex] then
      Result.m128i_u8[LIndex] := $FF
    else
      Result.m128i_u8[LIndex] := $00;
end;

function simd_and_si128(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    Result.m128i_u8[LIndex] := a.m128i_u8[LIndex] and b.m128i_u8[LIndex];
end;

// simd_movemask_epi8 实现已移至汇编版�?
// === 3️⃣ Integer Arithmetic 剩余实现 ===
function simd_add_epi16(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    Result.m128i_u16[LIndex] := Word((DWord(a.m128i_u16[LIndex]) + DWord(b.m128i_u16[LIndex])) and $FFFF);
end;

function simd_add_epi32(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128i_u32[LIndex] := DWord(QWord(a.m128i_u32[LIndex]) + QWord(b.m128i_u32[LIndex]));
end;

function simd_add_epi64(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128i_u64[LIndex] := a.m128i_u64[LIndex] + b.m128i_u64[LIndex];
end;

function simd_sub_epi8(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    Result.m128i_u8[LIndex] := Byte((Integer(a.m128i_u8[LIndex]) - Integer(b.m128i_u8[LIndex])) and $FF);
end;

function simd_sub_epi16(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    Result.m128i_u16[LIndex] := Word((DWord(a.m128i_u16[LIndex]) - DWord(b.m128i_u16[LIndex])) and $FFFF);
end;

function simd_sub_epi32(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128i_u32[LIndex] := DWord(QWord(a.m128i_u32[LIndex]) - QWord(b.m128i_u32[LIndex]));
end;

function simd_sub_epi64(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128i_u64[LIndex] := a.m128i_u64[LIndex] - b.m128i_u64[LIndex];
end;

function simd_adds_epi8(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    Result.m128i_i8[LIndex] := SaturateToI8(Integer(a.m128i_i8[LIndex]) + Integer(b.m128i_i8[LIndex]));
end;

function simd_adds_epi16(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    Result.m128i_i16[LIndex] := SaturateToI16(Integer(a.m128i_i16[LIndex]) + Integer(b.m128i_i16[LIndex]));
end;

function simd_subs_epi8(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    Result.m128i_i8[LIndex] := SaturateToI8(Integer(a.m128i_i8[LIndex]) - Integer(b.m128i_i8[LIndex]));
end;

function simd_subs_epi16(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    Result.m128i_i16[LIndex] := SaturateToI16(Integer(a.m128i_i16[LIndex]) - Integer(b.m128i_i16[LIndex]));
end;

function simd_max_epi8(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    if a.m128i_i8[LIndex] > b.m128i_i8[LIndex] then
      Result.m128i_i8[LIndex] := a.m128i_i8[LIndex]
    else
      Result.m128i_i8[LIndex] := b.m128i_i8[LIndex];
end;

function simd_max_epi16(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    if a.m128i_i16[LIndex] > b.m128i_i16[LIndex] then
      Result.m128i_i16[LIndex] := a.m128i_i16[LIndex]
    else
      Result.m128i_i16[LIndex] := b.m128i_i16[LIndex];
end;

function simd_min_epi8(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    if a.m128i_i8[LIndex] < b.m128i_i8[LIndex] then
      Result.m128i_i8[LIndex] := a.m128i_i8[LIndex]
    else
      Result.m128i_i8[LIndex] := b.m128i_i8[LIndex];
end;

function simd_min_epi16(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    if a.m128i_i16[LIndex] < b.m128i_i16[LIndex] then
      Result.m128i_i16[LIndex] := a.m128i_i16[LIndex]
    else
      Result.m128i_i16[LIndex] := b.m128i_i16[LIndex];
end;

function simd_mul_epu32(constref a, b: TM128): TM128;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.m128i_u64[0] := QWord(a.m128i_u32[0]) * QWord(b.m128i_u32[0]);
  Result.m128i_u64[1] := QWord(a.m128i_u32[2]) * QWord(b.m128i_u32[2]);
end;

function simd_mullo_epi16(constref a, b: TM128): TM128;
var
  LIndex: Integer;
  LProduct: Int64;
begin
  for LIndex := 0 to 7 do
  begin
    LProduct := Int64(a.m128i_i16[LIndex]) * Int64(b.m128i_i16[LIndex]);
    Result.m128i_u16[LIndex] := Word(LProduct and $FFFF);
  end;
end;

// === 4️⃣ Floating-Point Arithmetic 实现 ===
function simd_add_ps(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128_f32[LIndex] := a.m128_f32[LIndex] + b.m128_f32[LIndex];
end;

function simd_sub_ps(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128_f32[LIndex] := a.m128_f32[LIndex] - b.m128_f32[LIndex];
end;

function simd_mul_ps(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128_f32[LIndex] := a.m128_f32[LIndex] * b.m128_f32[LIndex];
end;

function simd_div_ps(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128_f32[LIndex] := a.m128_f32[LIndex] / b.m128_f32[LIndex];
end;

function simd_sqrt_ps(constref a: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128_f32[LIndex] := Sqrt(a.m128_f32[LIndex]);
end;

function simd_add_pd(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128d_f64[LIndex] := a.m128d_f64[LIndex] + b.m128d_f64[LIndex];
end;

function simd_sub_pd(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128d_f64[LIndex] := a.m128d_f64[LIndex] - b.m128d_f64[LIndex];
end;

function simd_mul_pd(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128d_f64[LIndex] := a.m128d_f64[LIndex] * b.m128d_f64[LIndex];
end;

function simd_div_pd(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128d_f64[LIndex] := a.m128d_f64[LIndex] / b.m128d_f64[LIndex];
end;

function simd_sqrt_pd(constref a: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128d_f64[LIndex] := Sqrt(a.m128d_f64[LIndex]);
end;

// === 5️⃣ Logical Operations 剩余实现 ===
function simd_or_si128(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    Result.m128i_u8[LIndex] := a.m128i_u8[LIndex] or b.m128i_u8[LIndex];
end;

function simd_xor_si128(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    Result.m128i_u8[LIndex] := a.m128i_u8[LIndex] xor b.m128i_u8[LIndex];
end;

function simd_andnot_si128(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    Result.m128i_u8[LIndex] := Byte(not a.m128i_u8[LIndex]) and b.m128i_u8[LIndex];
end;

// === 6️⃣ Compare / Mask 剩余实现 ===
function simd_cmpeq_epi16(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    if a.m128i_i16[LIndex] = b.m128i_i16[LIndex] then
      Result.m128i_u16[LIndex] := $FFFF
    else
      Result.m128i_u16[LIndex] := $0000;
end;

function simd_cmpeq_epi32(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    if a.m128i_i32[LIndex] = b.m128i_i32[LIndex] then
      Result.m128i_u32[LIndex] := DWord($FFFFFFFF)
    else
      Result.m128i_u32[LIndex] := DWord($00000000);
end;

function simd_cmpgt_epi8(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    if a.m128i_i8[LIndex] > b.m128i_i8[LIndex] then
      Result.m128i_u8[LIndex] := $FF
    else
      Result.m128i_u8[LIndex] := $00;
end;

function simd_cmpgt_epi16(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    if a.m128i_i16[LIndex] > b.m128i_i16[LIndex] then
      Result.m128i_u16[LIndex] := $FFFF
    else
      Result.m128i_u16[LIndex] := $0000;
end;

function simd_cmpgt_epi32(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    if a.m128i_i32[LIndex] > b.m128i_i32[LIndex] then
      Result.m128i_u32[LIndex] := DWord($FFFFFFFF)
    else
      Result.m128i_u32[LIndex] := DWord($00000000);
end;

// Keep compare ops in Pascal to avoid Win64 TM128 hidden-result ABI hazards.
function simd_cmpnlt_pd(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128i_u64[LIndex] := BoolMask64(CompareNltDouble(a.m128d_f64[LIndex], b.m128d_f64[LIndex]));
end;

function simd_cmpnle_pd(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128i_u64[LIndex] := BoolMask64(CompareNleDouble(a.m128d_f64[LIndex], b.m128d_f64[LIndex]));
end;

function simd_cmpngt_pd(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128i_u64[LIndex] := BoolMask64(CompareLeOrderedDouble(a.m128d_f64[LIndex], b.m128d_f64[LIndex]));
end;

function simd_cmpnge_pd(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128i_u64[LIndex] := BoolMask64(CompareLtOrderedDouble(a.m128d_f64[LIndex], b.m128d_f64[LIndex]));
end;

function simd_cmplt_epi8(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    if a.m128i_i8[LIndex] < b.m128i_i8[LIndex] then
      Result.m128i_u8[LIndex] := $FF
    else
      Result.m128i_u8[LIndex] := $00;
end;

function simd_cmplt_epi16(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    if a.m128i_i16[LIndex] < b.m128i_i16[LIndex] then
      Result.m128i_u16[LIndex] := $FFFF
    else
      Result.m128i_u16[LIndex] := $0000;
end;

function simd_cmplt_epi32(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    if a.m128i_i32[LIndex] < b.m128i_i32[LIndex] then
      Result.m128i_u32[LIndex] := DWord($FFFFFFFF)
    else
      Result.m128i_u32[LIndex] := DWord($00000000);
end;

function simd_cmpeq_pd(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128i_u64[LIndex] := BoolMask64(CompareEqOrderedDouble(a.m128d_f64[LIndex], b.m128d_f64[LIndex]));
end;

function simd_cmplt_pd(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128i_u64[LIndex] := BoolMask64(CompareLtOrderedDouble(a.m128d_f64[LIndex], b.m128d_f64[LIndex]));
end;

function simd_cmple_pd(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128i_u64[LIndex] := BoolMask64(CompareLeOrderedDouble(a.m128d_f64[LIndex], b.m128d_f64[LIndex]));
end;

function simd_cmpgt_pd(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128i_u64[LIndex] := BoolMask64(CompareGtOrderedDouble(a.m128d_f64[LIndex], b.m128d_f64[LIndex]));
end;

function simd_cmpge_pd(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128i_u64[LIndex] := BoolMask64(CompareGeOrderedDouble(a.m128d_f64[LIndex], b.m128d_f64[LIndex]));
end;

function simd_cmpneq_pd(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128i_u64[LIndex] := BoolMask64(CompareNeqDouble(a.m128d_f64[LIndex], b.m128d_f64[LIndex]));
end;

// Move Mask 实现已移至汇编版�?
// === 7️⃣ Shuffle / Unpack / Permute 实现 ===
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

function simd_shuffle_pd(constref a, b: TM128; imm8: Byte): TM128;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.m128d_f64[0] := a.m128d_f64[imm8 and 1];
  Result.m128d_f64[1] := b.m128d_f64[(imm8 shr 1) and 1];
end;

function simd_shuffle_ps(constref a, b: TM128; imm8: Byte): TM128;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.m128_f32[0] := a.m128_f32[imm8 and $3];
  Result.m128_f32[1] := a.m128_f32[(imm8 shr 2) and $3];
  Result.m128_f32[2] := b.m128_f32[(imm8 shr 4) and $3];
  Result.m128_f32[3] := b.m128_f32[(imm8 shr 6) and $3];
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

function simd_unpacklo_epi8(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; punpcklbw xmm0, xmm1  // �?字节解包
  {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; punpcklbw xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; punpcklbw xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_unpackhi_epi8(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; punpckhbw xmm0, xmm1  // �?字节解包
  {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; punpckhbw xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; punpckhbw xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_unpacklo_epi16(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; punpcklwd xmm0, xmm1  // �?�?6位解�?
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; punpcklwd xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; punpcklwd xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_unpackhi_epi16(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; punpckhwd xmm0, xmm1  // �?�?6位解�?
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; punpckhwd xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; punpckhwd xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_unpacklo_epi32(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; punpckldq xmm0, xmm1  // �?�?2位解�?
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; punpckldq xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; punpckldq xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_unpackhi_epi32(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; punpckhdq xmm0, xmm1  // �?�?2位解�?
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; punpckhdq xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; punpckhdq xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_unpacklo_epi64(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; punpcklqdq xmm0, xmm1  // �?4位解�?
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; punpcklqdq xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; punpcklqdq xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_unpackhi_epi64(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; punpckhqdq xmm0, xmm1  // �?4位解�?
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; punpckhqdq xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; punpckhqdq xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_unpacklo_pd(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]; movupd xmm1, [rdx]; unpcklpd xmm0, xmm1  // 低双精度解包
  {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; unpcklpd xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; unpcklpd xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_unpackhi_pd(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]; movupd xmm1, [rdx]; unpckhpd xmm0, xmm1  // 高双精度解包
  {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; unpckhpd xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; unpckhpd xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

// === 8️⃣ Shift / Rotate 实现 ===
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

function simd_slli_epi32(constref a: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    cmp dl, 32; jae @zero // 如果移位 >= 32，结果为 0
    cmp dl, 0; je @done //  如果移位 = 0，不�?
    movd xmm1, edx; pslld xmm0, xmm1; jmp @done
@zero: pxor xmm0, xmm0
@done:
  {$ELSE}
    movdqu xmm0, [rdi]
    cmp sil, 32; jae @zero
    cmp sil, 0; je @done
    movd xmm1, esi; pslld xmm0, xmm1; jmp @done
@zero: pxor xmm0, xmm0
@done:
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]
    cmp dl, 32; jae @zero
    cmp dl, 0; je @done
    movd xmm1, edx; pslld xmm0, xmm1; jmp @done
@zero: pxor xmm0, xmm0
@done:
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_slli_epi64(constref a: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    cmp dl, 64; jae @zero // 如果移位 >= 64，结果为 0
    cmp dl, 0; je @done //  如果移位 = 0，不�?
    movd xmm1, edx; psllq xmm0, xmm1; jmp @done
@zero: pxor xmm0, xmm0
@done:
  {$ELSE}
    movdqu xmm0, [rdi]
    cmp sil, 64; jae @zero
    cmp sil, 0; je @done
    movd xmm1, esi; psllq xmm0, xmm1; jmp @done
@zero: pxor xmm0, xmm0
@done:
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]
    cmp dl, 64; jae @zero
    cmp dl, 0; je @done
    movd xmm1, edx; psllq xmm0, xmm1; jmp @done
@zero: pxor xmm0, xmm0
@done:
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_srli_epi16(constref a: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    cmp dl, 16; jae @zero // 如果移位 >= 16，结果为 0
    cmp dl, 0; je @done //  如果移位 = 0，不�?
    movd xmm1, edx; psrlw xmm0, xmm1; jmp @done
@zero: pxor xmm0, xmm0
@done:
  {$ELSE}
    movdqu xmm0, [rdi]
    cmp sil, 16; jae @zero
    cmp sil, 0; je @done
    movd xmm1, esi; psrlw xmm0, xmm1; jmp @done
@zero: pxor xmm0, xmm0
@done:
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]
    cmp dl, 16; jae @zero
    cmp dl, 0; je @done
    movd xmm1, edx; psrlw xmm0, xmm1; jmp @done
@zero: pxor xmm0, xmm0
@done:
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_srli_epi32(constref a: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    cmp dl, 32; jae @zero // 如果移位 >= 32，结果为 0
    cmp dl, 0; je @done //  如果移位 = 0，不�?
    movd xmm1, edx; psrld xmm0, xmm1; jmp @done
@zero: pxor xmm0, xmm0
@done:
  {$ELSE}
    movdqu xmm0, [rdi]
    cmp sil, 32; jae @zero
    cmp sil, 0; je @done
    movd xmm1, esi; psrld xmm0, xmm1; jmp @done
@zero: pxor xmm0, xmm0
@done:
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]
    cmp dl, 32; jae @zero
    cmp dl, 0; je @done
    movd xmm1, edx; psrld xmm0, xmm1; jmp @done
@zero: pxor xmm0, xmm0
@done:
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_srli_epi64(constref a: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    cmp dl, 64; jae @zero // 如果移位 >= 64，结果为 0
    cmp dl, 0; je @done //  如果移位 = 0，不�?
    movd xmm1, edx; psrlq xmm0, xmm1; jmp @done
@zero: pxor xmm0, xmm0
@done:
  {$ELSE}
    movdqu xmm0, [rdi]
    cmp sil, 64; jae @zero
    cmp sil, 0; je @done
    movd xmm1, esi; psrlq xmm0, xmm1; jmp @done
@zero: pxor xmm0, xmm0
@done:
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]
    cmp dl, 64; jae @zero
    cmp dl, 0; je @done
    movd xmm1, edx; psrlq xmm0, xmm1; jmp @done
@zero: pxor xmm0, xmm0
@done:
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_srai_epi16(constref a: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    cmp dl, 16; jae @max //  如果移位 >= 16，符号扩�?
    cmp dl, 0; je @done //  如果移位 = 0，不�?
    movd xmm1, edx; psraw xmm0, xmm1; jmp @done
@max: psraw xmm0, 15     // 最大移位保持符号
@done:
  {$ELSE}
    movdqu xmm0, [rdi]
    cmp sil, 16; jae @max
    cmp sil, 0; je @done
    movd xmm1, esi; psraw xmm0, xmm1; jmp @done
@max: psraw xmm0, 15
@done:
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]
    cmp dl, 16; jae @max
    cmp dl, 0; je @done
    movd xmm1, edx; psraw xmm0, xmm1; jmp @done
@max: psraw xmm0, 15
@done:
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_srai_epi32(constref a: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    cmp dl, 32; jae @max //  如果移位 >= 32，符号扩�?
    cmp dl, 0; je @done //  如果移位 = 0，不�?
    movd xmm1, edx; psrad xmm0, xmm1; jmp @done
@max: psrad xmm0, 31     // 最大移位保持符号
@done:
  {$ELSE}
    movdqu xmm0, [rdi]
    cmp sil, 32; jae @max
    cmp sil, 0; je @done
    movd xmm1, esi; psrad xmm0, xmm1; jmp @done
@max: psrad xmm0, 31
@done:
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]
    cmp dl, 32; jae @max
    cmp dl, 0; je @done
    movd xmm1, edx; psrad xmm0, xmm1; jmp @done
@max: psrad xmm0, 31
@done:
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

	// === 字节级移位函数实现 ===
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

// === 9️⃣ Conversion / Cast 实现 ===
function simd_cvtepi32_pd(constref a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]    // 加载 a
    cvtdq2pd xmm0, xmm0   // 32位整数转双精度浮�?
    {$ELSE}
    movdqu xmm0, [rdi]
    cvtdq2pd xmm0, xmm0
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]    // a
    movdqu xmm0, [eax]
    cvtdq2pd xmm0, xmm0
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_cvtpd_epi32(constref a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]    // 加载 a
    cvtpd2dq xmm0, xmm0   // 双精度浮点转32位整数（舍入�?
    {$ELSE}
    movupd xmm0, [rdi]
    cvtpd2dq xmm0, xmm0
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]    // a
    movupd xmm0, [eax]
    cvtpd2dq xmm0, xmm0
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_cvtepi32_ps(constref a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]    // 加载 a
    cvtdq2ps xmm0, xmm0   // 32位整数转单精度浮�?
    {$ELSE}
    movdqu xmm0, [rdi]
    cvtdq2ps xmm0, xmm0
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]    // a
    movdqu xmm0, [eax]
    cvtdq2ps xmm0, xmm0
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_cvtps_epi32(constref a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]    // 加载 a
    cvtps2dq xmm0, xmm0   // 单精度浮点转32位整数（舍入�?
    {$ELSE}
    movups xmm0, [rdi]
    cvtps2dq xmm0, xmm0
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]    // a
    movups xmm0, [eax]
    cvtps2dq xmm0, xmm0
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_cvtsi32_si128(a: Integer): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movd xmm0, ecx        // 32位整数转128位（�?2位）
  {$ELSE}
    movd xmm0, edi        // Linux/macOS x64
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]    // a
    movd xmm0, eax
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_cvtsi64_si128(a: Int64): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq xmm0, rcx        // 64位整数转128位（�?4位）
  {$ELSE}
    movq xmm0, rdi        // Linux/macOS x64
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    movq xmm0, [esp + 4]  // 64位参数在栈上
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_cvtsi128_si32(constref a: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]    // 加载 a
    movd eax, xmm0        // 提取�?2�?
    {$ELSE}
    movdqu xmm0, [rdi]
    movd eax, xmm0
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov edx, [esp + 4]    // a
    movdqu xmm0, [edx]
    movd eax, xmm0
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

function simd_cvtsi128_si64(constref a: TM128): Int64; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]    // 加载 a
    movq rax, xmm0        // 提取�?4�?
    {$ELSE}
    movdqu xmm0, [rdi]
    movq rax, xmm0
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov edx, [esp + 4]    // a
    movdqu xmm0, [edx]
    movq [esp + 8], xmm0  // 返回64位值到�?
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

// === 浮点精度转换函数 ===
function simd_cvtpd_ps(constref a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]    // 加载 a
    cvtpd2ps xmm0, xmm0   // 双精度转单精�?
    {$ELSE}
    movupd xmm0, [rdi]
    cvtpd2ps xmm0, xmm0
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]    // a
    movupd xmm0, [eax]
    cvtpd2ps xmm0, xmm0
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_cvtps_pd(constref a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]    // 加载 a
    cvtps2pd xmm0, xmm0   // 单精度转双精�?
    {$ELSE}
    movups xmm0, [rdi]
    cvtps2pd xmm0, xmm0
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]    // a
    movups xmm0, [eax]
    cvtps2pd xmm0, xmm0
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

// === 截断转换函数 ===
function simd_cvttps_epi32(constref a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]    // 加载 a
    cvttps2dq xmm0, xmm0  // 单精度转32位整数（截断�?
    {$ELSE}
    movups xmm0, [rdi]
    cvttps2dq xmm0, xmm0
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]    // a
    movups xmm0, [eax]
    cvttps2dq xmm0, xmm0
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_cvttpd_epi32(constref a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]    // 加载 a
    cvttpd2dq xmm0, xmm0  // 双精度转32位整数（截断�?
    {$ELSE}
    movupd xmm0, [rdi]
    cvttpd2dq xmm0, xmm0
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]    // a
    movupd xmm0, [eax]
    cvttpd2dq xmm0, xmm0
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

// 重复的转换和 Cast 函数实现已删除，保留汇编版本

// === 新添加函数的占位实现 ===

// Load/Store 新函�?
function simd_loadl_epi64(const Ptr: Pointer): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: 第一个参数在 rcx
    pxor xmm0, xmm0
    movq xmm0, [rcx]
  {$ELSE}
    // Linux/macOS x64 System V ABI: 第一个参数在 rdi
    pxor xmm0, xmm0
    movq xmm0, [rdi]
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    // x86 32-bit: 参数在栈�?
    mov eax, [esp + 4]
    pxor xmm0, xmm0
    movq xmm0, [eax]
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

procedure simd_storel_epi64(var Dest; constref Src: TM128); {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Dest �?rcx, Src �?rdx
    movq xmm0, [rdx] //  加载源数据的�?4�?
    movq [rcx], xmm0      // 存储�?4位到目标
  {$ELSE}
    // Linux/macOS x64 System V ABI: Dest �?rdi, Src �?rsi
    movq xmm0, [rsi] //  加载源数据的�?4�?
    movq [rdi], xmm0      // 存储�?4位到目标
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    // x86 32-bit: 参数在栈�?
    mov eax, [esp + 4]    // Dest
    mov edx, [esp + 8]    // Src
    movq xmm0, [edx] //  加载源数据的�?4�?
    movq [eax], xmm0      // 存储�?4位到目标
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

procedure simd_maskmoveu_si128(constref Src: TM128; constref Mask: TM128; var Dest); {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Src �?rcx, Mask �?rdx, Dest �?r8
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    push rdi
    mov rdi, r8
    maskmovdqu xmm0, xmm1
    pop rdi
    {$ELSE}
    // Linux/macOS x64 System V ABI: Src �?rdi, Mask �?rsi, Dest �?rdx
    push rdi
    movdqu xmm0, [rdi]
    movdqu xmm1, [rsi]
    mov rdi, rdx
    maskmovdqu xmm0, xmm1
    pop rdi
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    // x86 32-bit: 参数在栈�?
    mov eax, [esp + 4]
    mov edx, [esp + 8]
    push edi
    mov edi, [esp + 16]
    movdqu xmm0, [eax]
    movdqu xmm1, [edx]
    maskmovdqu xmm0, xmm1
    pop edi
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

function simd_loadr_pd(const Ptr: Pointer): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: 第一个参数在 rcx
    movupd xmm0, [rcx]     // 加载两个双精度数
    shufpd xmm0, xmm0, 1   // 交换高低�?(01b = 1)
  {$ELSE}
    // Linux/macOS x64 System V ABI: 第一个参数在 rdi
    movupd xmm0, [rdi]     // 加载两个双精度数
    shufpd xmm0, xmm0, 1   // 交换高低�?
    {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    // x86 32-bit: 参数在栈�?
    mov eax, [esp + 4]
    movupd xmm0, [eax]
    shufpd xmm0, xmm0, 1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

procedure simd_storer_pd(var Dest; constref Src: TM128); {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Dest �?rcx, Src �?rdx
    movupd xmm0, [rdx]
    shufpd xmm0, xmm0, 1
    movupd [rcx], xmm0
    {$ELSE}
    // Linux/macOS x64 System V ABI: Dest �?rdi, Src �?rsi
    movupd xmm0, [rsi]
    shufpd xmm0, xmm0, 1
    movupd [rdi], xmm0
    {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    // x86 32-bit: 参数在栈�?
    mov eax, [esp + 4]
    mov edx, [esp + 8]
    movupd xmm0, [edx]
    shufpd xmm0, xmm0, 1
    movupd [eax], xmm0
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

function simd_loadh_pd(constref A: TM128; const Ptr: Pointer): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: A �?rcx, Ptr �?rdx
    movupd xmm0, [rcx]
    movhpd xmm0, [rdx]
    {$ELSE}
    // Linux/macOS x64 System V ABI: A �?rdi, Ptr �?rsi
    movupd xmm0, [rdi]
    movhpd xmm0, [rsi]
    {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    // x86 32-bit: 参数在栈�?
    mov eax, [esp + 4]
    mov edx, [esp + 8]
    movupd xmm0, [eax]
    movhpd xmm0, [edx]
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_loadl_pd(constref A: TM128; const Ptr: Pointer): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: A �?rcx, Ptr �?rdx
    movupd xmm0, [rcx]
    movlpd xmm0, [rdx]
    {$ELSE}
    // Linux/macOS x64 System V ABI: A �?rdi, Ptr �?rsi
    movupd xmm0, [rdi]
    movlpd xmm0, [rsi]
    {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    // x86 32-bit: 参数在栈�?
    mov eax, [esp + 4]
    mov edx, [esp + 8]
    movupd xmm0, [eax]
    movlpd xmm0, [edx]
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

procedure simd_storeh_pd(var Dest; constref Src: TM128); {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Dest �?rcx, Src �?rdx
    movupd xmm0, [rdx]
    movhpd [rcx], xmm0
  {$ELSE}
    // Linux/macOS x64 System V ABI: Dest �?rdi, Src �?rsi
    movupd xmm0, [rsi]
    movhpd [rdi], xmm0
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    // x86 32-bit: 参数在栈�?
    mov eax, [esp + 4]
    mov edx, [esp + 8]
    movupd xmm0, [edx]
    movhpd [eax], xmm0
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

procedure simd_storel_pd(var Dest; constref Src: TM128); {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Dest �?rcx, Src �?rdx
    movupd xmm0, [rdx]
    movlpd [rcx], xmm0
  {$ELSE}
    // Linux/macOS x64 System V ABI: Dest �?rdi, Src �?rsi
    movupd xmm0, [rsi]
    movlpd [rdi], xmm0
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    // x86 32-bit: 参数在栈�?
    mov eax, [esp + 4]
    mov edx, [esp + 8]
    movupd xmm0, [edx]
    movlpd [eax], xmm0
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

function simd_load_sd(const Ptr: Pointer): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: 第一个参数在 rcx
    movsd xmm0, [rcx]      // 加载标量双精度，高位自动清零
  {$ELSE}
    // Linux/macOS x64 System V ABI: 第一个参数在 rdi
    movsd xmm0, [rdi]      // 加载标量双精度，高位自动清零
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    // x86 32-bit: 参数在栈�?
    mov eax, [esp + 4]
    movsd xmm0, [eax]
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

procedure simd_store_sd(var Dest; constref Src: TM128); {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Dest �?rcx, Src �?rdx
    movupd xmm0, [rdx]
    movsd [rcx], xmm0
    {$ELSE}
    // Linux/macOS x64 System V ABI: Dest �?rdi, Src �?rsi
    movupd xmm0, [rsi]
    movsd [rdi], xmm0
    {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    // x86 32-bit: 参数在栈�?
    mov eax, [esp + 4]
    mov edx, [esp + 8]
    movupd xmm0, [edx]
    movsd [eax], xmm0
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

// Set 新函�?
function simd_set_epi8(a15, a14, a13, a12, a11, a10, a9, a8, a7, a6, a5, a4, a3, a2, a1, a0: ShortInt): TM128;
begin
  Result.m128i_i8[0] := a0; Result.m128i_i8[1] := a1; Result.m128i_i8[2] := a2; Result.m128i_i8[3] := a3;
  Result.m128i_i8[4] := a4; Result.m128i_i8[5] := a5; Result.m128i_i8[6] := a6; Result.m128i_i8[7] := a7;
  Result.m128i_i8[8] := a8; Result.m128i_i8[9] := a9; Result.m128i_i8[10] := a10; Result.m128i_i8[11] := a11;
  Result.m128i_i8[12] := a12; Result.m128i_i8[13] := a13; Result.m128i_i8[14] := a14; Result.m128i_i8[15] := a15;
end;

function simd_setr_epi8(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15: ShortInt): TM128;
begin
  Result.m128i_i8[0] := a0; Result.m128i_i8[1] := a1; Result.m128i_i8[2] := a2; Result.m128i_i8[3] := a3;
  Result.m128i_i8[4] := a4; Result.m128i_i8[5] := a5; Result.m128i_i8[6] := a6; Result.m128i_i8[7] := a7;
  Result.m128i_i8[8] := a8; Result.m128i_i8[9] := a9; Result.m128i_i8[10] := a10; Result.m128i_i8[11] := a11;
  Result.m128i_i8[12] := a12; Result.m128i_i8[13] := a13; Result.m128i_i8[14] := a14; Result.m128i_i8[15] := a15;
end;

function simd_set_epi16(a7, a6, a5, a4, a3, a2, a1, a0: SmallInt): TM128;
begin
  Result.m128i_i16[0] := a0; Result.m128i_i16[1] := a1; Result.m128i_i16[2] := a2; Result.m128i_i16[3] := a3;
  Result.m128i_i16[4] := a4; Result.m128i_i16[5] := a5; Result.m128i_i16[6] := a6; Result.m128i_i16[7] := a7;
end;

function simd_setr_epi16(a0, a1, a2, a3, a4, a5, a6, a7: SmallInt): TM128;
begin
  Result.m128i_i16[0] := a0; Result.m128i_i16[1] := a1; Result.m128i_i16[2] := a2; Result.m128i_i16[3] := a3;
  Result.m128i_i16[4] := a4; Result.m128i_i16[5] := a5; Result.m128i_i16[6] := a6; Result.m128i_i16[7] := a7;
end;

function simd_set_epi64(a, b: Int64): TM128;
begin
  Result.m128i_i64[0] := b; Result.m128i_i64[1] := a;
end;

function simd_setr_epi64(a, b: Int64): TM128;
begin
  Result.m128i_i64[0] := a; Result.m128i_i64[1] := b;
end;

function simd_set_pd(a, b: Double): TM128;
begin
  Result.m128d_f64[0] := b; Result.m128d_f64[1] := a;
end;

// Integer Arithmetic 新函�?
function simd_adds_epu8(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; paddusb xmm0, xmm1  // 无符�?位饱和加�?
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; paddusb xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; paddusb xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_adds_epu16(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; paddusw xmm0, xmm1  // 无符�?6位饱和加�?
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; paddusw xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; paddusw xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_subs_epu8(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; psubusb xmm0, xmm1  // 无符�?位饱和减�?
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; psubusb xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; psubusb xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_subs_epu16(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; psubusw xmm0, xmm1  // 无符�?6位饱和减�?
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; psubusw xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; psubusw xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_mulhi_epi16(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; pmulhw xmm0, xmm1  // 有符�?6位乘法高位结�?
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pmulhw xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pmulhw xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_mulhi_epu16(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; pmulhuw xmm0, xmm1  // 无符�?6位乘法高位结�?
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pmulhuw xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pmulhuw xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_madd_epi16(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; pmaddwd xmm0, xmm1  // 乘加运算�?6位乘�?相邻结果相加
  {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pmaddwd xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pmaddwd xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_avg_epu8(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; pavgb xmm0, xmm1  // 无符�?位平均�?(a+b+1)/2
  {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pavgb xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pavgb xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_avg_epu16(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; pavgw xmm0, xmm1  // 无符�?6位平均�?(a+b+1)/2
  {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pavgw xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pavgw xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_sad_epu8(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; psadbw xmm0, xmm1  // 绝对差值和�?字节块的SAD
  {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; psadbw xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; psadbw xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

// Keep these TM128-returning ops in Pascal to avoid Win64 hidden-result ABI hazards.
function simd_min_ps(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128_f32[LIndex] := SelectMinSingle(a.m128_f32[LIndex], b.m128_f32[LIndex]);
end;

function simd_max_ps(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128_f32[LIndex] := SelectMaxSingle(a.m128_f32[LIndex], b.m128_f32[LIndex]);
end;

function simd_min_pd(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128d_f64[LIndex] := SelectMinDouble(a.m128d_f64[LIndex], b.m128d_f64[LIndex]);
end;

function simd_max_pd(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128d_f64[LIndex] := SelectMaxDouble(a.m128d_f64[LIndex], b.m128d_f64[LIndex]);
end;

function simd_add_sd(constref a, b: TM128): TM128;
begin
  Result := a;
  Result.m128d_f64[0] := a.m128d_f64[0] + b.m128d_f64[0];
end;

function simd_sub_sd(constref a, b: TM128): TM128;
begin
  Result := a;
  Result.m128d_f64[0] := a.m128d_f64[0] - b.m128d_f64[0];
end;

function simd_mul_sd(constref a, b: TM128): TM128;
begin
  Result := a;
  Result.m128d_f64[0] := a.m128d_f64[0] * b.m128d_f64[0];
end;

function simd_div_sd(constref a, b: TM128): TM128;
begin
  Result := a;
  Result.m128d_f64[0] := a.m128d_f64[0] / b.m128d_f64[0];
end;

function simd_sqrt_sd(constref a, b: TM128): TM128;
begin
  Result := a;
  Result.m128d_f64[0] := Sqrt(b.m128d_f64[0]);
end;

function simd_min_sd(constref a, b: TM128): TM128;
begin
  Result := a;
  Result.m128d_f64[0] := SelectMinDouble(a.m128d_f64[0], b.m128d_f64[0]);
end;

function simd_max_sd(constref a, b: TM128): TM128;
begin
  Result := a;
  Result.m128d_f64[0] := SelectMaxDouble(a.m128d_f64[0], b.m128d_f64[0]);
end;

function simd_and_pd(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    Result.m128i_u8[LIndex] := a.m128i_u8[LIndex] and b.m128i_u8[LIndex];
end;

function simd_or_pd(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    Result.m128i_u8[LIndex] := a.m128i_u8[LIndex] or b.m128i_u8[LIndex];
end;

function simd_xor_pd(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    Result.m128i_u8[LIndex] := a.m128i_u8[LIndex] xor b.m128i_u8[LIndex];
end;

function simd_andnot_pd(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    Result.m128i_u8[LIndex] := Byte(not a.m128i_u8[LIndex]) and b.m128i_u8[LIndex];
end;

function simd_cmpord_pd(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128i_u64[LIndex] := BoolMask64(not IsUnorderedDoubleCompare(a.m128d_f64[LIndex], b.m128d_f64[LIndex]));
end;

function simd_cmpunord_pd(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.m128i_u64[LIndex] := BoolMask64(IsUnorderedDoubleCompare(a.m128d_f64[LIndex], b.m128d_f64[LIndex]));
end;

// === 标量双精度比较函数实�?===
function simd_cmpeq_sd(constref a, b: TM128): TM128;
begin
  Result := MakeScalarCompareResult(a, CompareEqOrderedDouble(a.m128d_f64[0], b.m128d_f64[0]));
end;

function simd_cmplt_sd(constref a, b: TM128): TM128;
begin
  Result := MakeScalarCompareResult(a, CompareLtOrderedDouble(a.m128d_f64[0], b.m128d_f64[0]));
end;

function simd_cmple_sd(constref a, b: TM128): TM128;
begin
  Result := MakeScalarCompareResult(a, CompareLeOrderedDouble(a.m128d_f64[0], b.m128d_f64[0]));
end;

function simd_cmpgt_sd(constref a, b: TM128): TM128;
begin
  Result := MakeScalarCompareResult(a, CompareNleDouble(a.m128d_f64[0], b.m128d_f64[0]));
end;

function simd_cmpge_sd(constref a, b: TM128): TM128;
begin
  Result := MakeScalarCompareResult(a, CompareNltDouble(a.m128d_f64[0], b.m128d_f64[0]));
end;

function simd_cmpneq_sd(constref a, b: TM128): TM128;
begin
  Result := MakeScalarCompareResult(a, CompareNeqDouble(a.m128d_f64[0], b.m128d_f64[0]));
end;

function simd_cmpnlt_sd(constref a, b: TM128): TM128;
begin
  Result := MakeScalarCompareResult(a, CompareNltDouble(a.m128d_f64[0], b.m128d_f64[0]));
end;

function simd_cmpnle_sd(constref a, b: TM128): TM128;
begin
  Result := MakeScalarCompareResult(a, CompareNleDouble(a.m128d_f64[0], b.m128d_f64[0]));
end;

function simd_cmpngt_sd(constref a, b: TM128): TM128;
begin
  Result := MakeScalarCompareResult(a, CompareLeOrderedDouble(a.m128d_f64[0], b.m128d_f64[0]));
end;

function simd_cmpnge_sd(constref a, b: TM128): TM128;
begin
  Result := MakeScalarCompareResult(a, CompareLtOrderedDouble(a.m128d_f64[0], b.m128d_f64[0]));
end;

function simd_cmpord_sd(constref a, b: TM128): TM128;
begin
  Result := MakeScalarCompareResult(a, not IsUnorderedDoubleCompare(a.m128d_f64[0], b.m128d_f64[0]));
end;

function simd_cmpunord_sd(constref a, b: TM128): TM128;
begin
  Result := MakeScalarCompareResult(a, IsUnorderedDoubleCompare(a.m128d_f64[0], b.m128d_f64[0]));
end;

// 标量比较返回整数。这里统一复用现有的 compare 语义辅助函数，
// 避免 COMISD/UCOMISD 在 NaN 场景下把异常/flags 直接泄漏成 ABI 差异。
function simd_comieq_sd(constref a, b: TM128): Integer;
begin
  Result := Ord(CompareEqOrderedDouble(a.m128d_f64[0], b.m128d_f64[0]));
end;

function simd_comilt_sd(constref a, b: TM128): Integer;
begin
  Result := Ord(CompareLtOrderedDouble(a.m128d_f64[0], b.m128d_f64[0]));
end;

function simd_comile_sd(constref a, b: TM128): Integer;
begin
  Result := Ord(CompareLeOrderedDouble(a.m128d_f64[0], b.m128d_f64[0]));
end;

function simd_comigt_sd(constref a, b: TM128): Integer;
begin
  Result := Ord(CompareGtOrderedDouble(a.m128d_f64[0], b.m128d_f64[0]));
end;

function simd_comige_sd(constref a, b: TM128): Integer;
begin
  Result := Ord(CompareGeOrderedDouble(a.m128d_f64[0], b.m128d_f64[0]));
end;

function simd_comineq_sd(constref a, b: TM128): Integer;
begin
  Result := Ord(CompareNeqDouble(a.m128d_f64[0], b.m128d_f64[0]));
end;

function simd_ucomieq_sd(constref a, b: TM128): Integer;
begin
  Result := Ord(CompareEqOrderedDouble(a.m128d_f64[0], b.m128d_f64[0]));
end;

function simd_ucomilt_sd(constref a, b: TM128): Integer;
begin
  Result := Ord(CompareLtOrderedDouble(a.m128d_f64[0], b.m128d_f64[0]));
end;

function simd_ucomile_sd(constref a, b: TM128): Integer;
begin
  Result := Ord(CompareLeOrderedDouble(a.m128d_f64[0], b.m128d_f64[0]));
end;

function simd_ucomigt_sd(constref a, b: TM128): Integer;
begin
  Result := Ord(CompareGtOrderedDouble(a.m128d_f64[0], b.m128d_f64[0]));
end;

function simd_ucomige_sd(constref a, b: TM128): Integer;
begin
  Result := Ord(CompareGeOrderedDouble(a.m128d_f64[0], b.m128d_f64[0]));
end;

function simd_ucomineq_sd(constref a, b: TM128): Integer;
begin
  Result := Ord(CompareNeqDouble(a.m128d_f64[0], b.m128d_f64[0]));
end;

// === 🔟 Pack / Insert / Extract / Move 实现 ===
function simd_packs_epi16(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for LIndex := 0 to 7 do
    Result.m128i_i8[LIndex] := SaturateToI8(a.m128i_i16[LIndex]);
  for LIndex := 0 to 7 do
    Result.m128i_i8[8 + LIndex] := SaturateToI8(b.m128i_i16[LIndex]);
end;

function simd_packs_epi32(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for LIndex := 0 to 3 do
    Result.m128i_i16[LIndex] := SaturateToI16(a.m128i_i32[LIndex]);
  for LIndex := 0 to 3 do
    Result.m128i_i16[4 + LIndex] := SaturateToI16(b.m128i_i32[LIndex]);
end;

function simd_packus_epi16(constref a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for LIndex := 0 to 7 do
    Result.m128i_u8[LIndex] := SaturateToU8(a.m128i_i16[LIndex]);
  for LIndex := 0 to 7 do
    Result.m128i_u8[8 + LIndex] := SaturateToU8(b.m128i_i16[LIndex]);
end;

function simd_insert_epi16(constref a: TM128; Value: Integer; imm8: Byte): TM128;
begin
  Result := a;
  Result.m128i_u16[imm8 and $7] := Word(Value and $FFFF);
end;

function simd_extract_epi16(constref a: TM128; imm8: Byte): Integer;
begin
  Result := Integer(a.m128i_u16[imm8 and $7]);
end;

function simd_move_sd(constref a, b: TM128): TM128;
begin
  Result := a;
  Result.m128d_f64[0] := b.m128d_f64[0];
end;

function simd_move_epi64(constref a: TM128): TM128;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.m128i_u64[0] := a.m128i_u64[0];
end;

function simd_movemask_epi8(constref a: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]    // 加载 a
    pmovmskb eax, xmm0    // 提取8位符号位掩码
  {$ELSE}
    movdqu xmm0, [rdi]
    pmovmskb eax, xmm0
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov edx, [esp + 4]    // a
    movdqu xmm0, [edx]
    pmovmskb eax, xmm0
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

function simd_movemask_pd(constref a: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]    // 加载 a
    movmskpd eax, xmm0    // 提取双精度符号位掩码
  {$ELSE}
    movupd xmm0, [rdi]
    movmskpd eax, xmm0
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov edx, [esp + 4]    // a
    movupd xmm0, [edx]
    movmskpd eax, xmm0
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

function simd_movemask_ps(constref a: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]    // 加载 a
    movmskps eax, xmm0    // 提取单精度符号位掩码
  {$ELSE}
    movups xmm0, [rdi]
    movmskps eax, xmm0
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov edx, [esp + 4]    // a
    movups xmm0, [edx]
    movmskps eax, xmm0
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

// === Cast 函数实现（无转换，仅重新解释）===
function simd_castpd_si128(constref a: TM128): TM128;
begin
  Result := a;
end;

function simd_castsi128_pd(constref a: TM128): TM128;
begin
  Result := a;
end;

function simd_castps_si128(constref a: TM128): TM128;
begin
  Result := a;
end;

function simd_castsi128_ps(constref a: TM128): TM128;
begin
  Result := a;
end;

function simd_castpd_ps(constref a: TM128): TM128;
begin
  Result := a;
end;

function simd_castps_pd(constref a: TM128): TM128;
begin
  Result := a;
end;

function simd_unpacklo_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]; movups xmm1, [rdx]; unpcklps xmm0, xmm1  // 解包低位单精�?
    {$ELSE}
    movups xmm0, [rdi]; movups xmm1, [rsi]; unpcklps xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movups xmm0, [eax]; movups xmm1, [edx]; unpcklps xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_unpackhi_ps(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]; movups xmm1, [rdx]; unpckhps xmm0, xmm1  // 解包高位单精�?
    {$ELSE}
    movups xmm0, [rdi]; movups xmm1, [rsi]; unpckhps xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movups xmm0, [eax]; movups xmm1, [edx]; unpckhps xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_cvtsd_ss(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]; movsd xmm1, [rdx]; cvtsd2ss xmm0, xmm1  // 标量双精度转单精�?
    {$ELSE}
    movupd xmm0, [rdi]; movsd xmm1, [rsi]; cvtsd2ss xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movsd xmm1, [edx]; cvtsd2ss xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_cvtss_sd(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]; movss xmm1, [rdx]; cvtss2sd xmm0, xmm1  // 标量单精度转双精�?
    {$ELSE}
    movupd xmm0, [rdi]; movss xmm1, [rsi]; cvtss2sd xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movss xmm1, [edx]; cvtss2sd xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_cvttpd_ps(constref a: TM128): TM128;
begin
  Result := Default(TM128);
  Result.m128_f32[0] := Single(a.m128d_f64[0]);
  Result.m128_f32[1] := Single(a.m128d_f64[1]);
end;

	function simd_srai_si128(constref a: TM128; imm8: Byte): TM128;
	var
	  LFill: Byte;
	  LIndex: Integer;
	  LShift: Integer;
	begin
	  if (a.m128i_u8[15] and $80) <> 0 then
	    LFill := $FF
	  else
	    LFill := $00;

	  FillChar(Result, SizeOf(Result), LFill);
	  LShift := imm8;
	  if LShift <= 0 then
	    Result := a
	  else if LShift < 16 then
	    for LIndex := 0 to (15 - LShift) do
	      Result.m128i_u8[LIndex] := a.m128i_u8[LIndex + LShift];
	end;

function simd_max_epu8(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; pmaxub xmm0, xmm1  // 无符�?位最大�?
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pmaxub xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pmaxub xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_min_epu8(constref a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; pminub xmm0, xmm1  // 无符�?位最小�?
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pminub xmm0, xmm1
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pminub xmm0, xmm1
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_cvtsd_si32(constref a: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movsd xmm0, [rcx]; cvtsd2si eax, xmm0  // 标量双精度转32位整�?
    {$ELSE}
    movsd xmm0, [rdi]; cvtsd2si eax, xmm0
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov edx, [esp + 4]; movsd xmm0, [edx]; cvtsd2si eax, xmm0
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

function simd_cvtsd_si64(constref a: TM128): Int64; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movsd xmm0, [rcx]; cvtsd2si rax, xmm0  // 标量双精度转64位整�?
    {$ELSE}
    movsd xmm0, [rdi]; cvtsd2si rax, xmm0
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov edx, [esp + 4]; movsd xmm0, [edx]; cvtsd2si eax, xmm0; mov [esp + 8], eax; xor eax, eax; mov [esp + 12], eax
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

function simd_cvttsd_si32(constref a: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movsd xmm0, [rcx]; cvttsd2si eax, xmm0  // 截断标量双精度转32位整�?
    {$ELSE}
    movsd xmm0, [rdi]; cvttsd2si eax, xmm0
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov edx, [esp + 4]; movsd xmm0, [edx]; cvttsd2si eax, xmm0
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

function simd_cvttsd_si64(constref a: TM128): Int64; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movsd xmm0, [rcx]; cvttsd2si rax, xmm0  // 截断标量双精度转64位整�?
    {$ELSE}
    movsd xmm0, [rdi]; cvttsd2si rax, xmm0
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov edx, [esp + 4]; movsd xmm0, [edx]; cvttsd2si eax, xmm0; mov [esp + 8], eax; xor eax, eax; mov [esp + 12], eax
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

function simd_cvtsi32_sd(constref a: TM128; b: Integer): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]; cvtsi2sd xmm0, edx  // 32位整数转标量双精度
    {$ELSE}
    movupd xmm0, [rdi]; cvtsi2sd xmm0, esi
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; cvtsi2sd xmm0, edx
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

function simd_cvtsi64_sd(constref a: TM128; b: Int64): TM128; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]; cvtsi2sd xmm0, rdx  // 64位整数转标量双精度
    {$ELSE}
    movupd xmm0, [rdi]; cvtsi2sd xmm0, rsi
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]; movupd xmm0, [eax]; cvtsi2sd xmm0, qword ptr [esp + 8]
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
{$IFDEF CPUX86_64}
  movq rax, xmm0
  movdqa xmm1, xmm0
  psrldq xmm1, 8
  movq rdx, xmm1
{$ENDIF}
end;

// === 1️⃣1️⃣ Cache Control / Stream / Fence 实现 ===
procedure simd_clflush(const Ptr: Pointer); {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    clflush [rcx]         // 刷新缓存�?
    {$ELSE}
    clflush [rdi]         // Linux/macOS x64
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]    // Ptr
    clflush [eax]
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

procedure simd_lfence; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
    lfence                // 加载栅栏
end;

procedure simd_mfence; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
    mfence                // 内存栅栏
end;

procedure simd_pause; {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
    pause                 // 暂停指令（自旋循环提示）
end;

procedure simd_stream_pd(var Dest; constref Src: TM128); {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rdx]    // 加载 Src
    movntpd [rcx], xmm0   // 非临时存储双精度
  {$ELSE}
    movupd xmm0, [rsi]    // 加载 Src
    movntpd [rdi], xmm0   // 非临时存储双精度
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]    // Dest
    mov edx, [esp + 8]    // Src
    movupd xmm0, [edx]
    movntpd [eax], xmm0
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

procedure simd_stream_ps(var Dest; constref Src: TM128); {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rdx]    // 加载 Src
    movntps [rcx], xmm0   // 非临时存储单精度
  {$ELSE}
    movups xmm0, [rsi]    // 加载 Src
    movntps [rdi], xmm0   // 非临时存储单精度
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]    // Dest
    mov edx, [esp + 8]    // Src
    movups xmm0, [edx]
    movntps [eax], xmm0
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

procedure simd_stream_si128(var Dest; constref Src: TM128); {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rdx]    // 加载 Src
    movntdq [rcx], xmm0   // 非临时存�?28位整�?
    {$ELSE}
    movdqu xmm0, [rsi]    // 加载 Src
    movntdq [rdi], xmm0   // 非临时存�?28位整�?
    {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]    // Dest
    mov edx, [esp + 8]    // Src
    movdqu xmm0, [edx]
    movntdq [eax], xmm0
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

procedure simd_stream_si32(var Dest; Value: Integer); {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movnti [rcx], edx     // 非临时存�?2位整�?
    {$ELSE}
    movnti [rdi], esi     // Linux/macOS x64
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]    // Dest
    mov edx, [esp + 8]    // Value
    movnti [eax], edx
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

procedure simd_stream_si64(var Dest; Value: Int64); {$IFDEF FPC}assembler; nostackframe;
{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movnti [rcx], rdx     // 非临时存�?4位整�?
    {$ELSE}
    movnti [rdi], rsi     // Linux/macOS x64
  {$ENDIF}
{$ELSE}
  {$IFDEF CPUX86}
    mov eax, [esp + 4]    // Dest
    mov edx, [esp + 8] //  �?2�?
    mov ecx, [esp + 12]   // �?2�?    movnti [eax], edx     // 存储�?2�?    movnti [eax + 4], ecx // 存储�?2�?
  {$ELSE}
    {$ERROR Unsupported CPU}
  {$ENDIF}
{$ENDIF}
end;

initialization
  EnsureExperimentalIntrinsicsEnabled;

end.
