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
procedure simd_store_si128(var Dest; const Src: TM128);
procedure simd_storeu_si128(var Dest; const Src: TM128);
function simd_loadl_epi64(const Ptr: Pointer): TM128; // Load lower 64-bit integer
procedure simd_storel_epi64(var Dest; const Src: TM128); // Store lower 64-bit integer
procedure simd_maskmoveu_si128(const Src: TM128; const Mask: TM128; var Dest); // Conditional store using mask

// Double Load/Store
function simd_load_pd(const Ptr: Pointer): TM128;
function simd_loadu_pd(const Ptr: Pointer): TM128;
procedure simd_store_pd(var Dest; const Src: TM128);
procedure simd_storeu_pd(var Dest; const Src: TM128);
function simd_loadr_pd(const Ptr: Pointer): TM128; // Load reverse packed double
procedure simd_storer_pd(var Dest; const Src: TM128); // Store reverse packed double
function simd_loadh_pd(const A: TM128; const Ptr: Pointer): TM128; // Load high double
function simd_loadl_pd(const A: TM128; const Ptr: Pointer): TM128; // Load low double
procedure simd_storeh_pd(var Dest; const Src: TM128); // Store high double
procedure simd_storel_pd(var Dest; const Src: TM128); // Store low double
function simd_load_sd(const Ptr: Pointer): TM128; // Load scalar double
procedure simd_store_sd(var Dest; const Src: TM128); // Store scalar double

// Single Load/Store
function simd_load_ps(const Ptr: Pointer): TM128;
function simd_loadu_ps(const Ptr: Pointer): TM128;
procedure simd_store_ps(var Dest; const Src: TM128);
procedure simd_storeu_ps(var Dest; const Src: TM128);

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
function simd_add_epi8(const a, b: TM128): TM128;
function simd_add_epi16(const a, b: TM128): TM128;
function simd_add_epi32(const a, b: TM128): TM128;
function simd_add_epi64(const a, b: TM128): TM128;

// Sub
function simd_sub_epi8(const a, b: TM128): TM128;
function simd_sub_epi16(const a, b: TM128): TM128;
function simd_sub_epi32(const a, b: TM128): TM128;
function simd_sub_epi64(const a, b: TM128): TM128;

// Saturated Add/Sub
function simd_adds_epi8(const a, b: TM128): TM128;   // signed saturated add
function simd_adds_epi16(const a, b: TM128): TM128;
function simd_subs_epi8(const a, b: TM128): TM128;   // signed saturated sub
function simd_subs_epi16(const a, b: TM128): TM128;
function simd_adds_epu8(const a, b: TM128): TM128; // unsigned saturated add 8-bit
function simd_adds_epu16(const a, b: TM128): TM128; // unsigned saturated add 16-bit
function simd_subs_epu8(const a, b: TM128): TM128; // unsigned saturated sub 8-bit
function simd_subs_epu16(const a, b: TM128): TM128; // unsigned saturated sub 16-bit

// Min/Max
function simd_max_epi8(const a, b: TM128): TM128;
function simd_max_epi16(const a, b: TM128): TM128;
function simd_min_epi8(const a, b: TM128): TM128;
function simd_min_epi16(const a, b: TM128): TM128;
function simd_max_epu8(const a, b: TM128): TM128; // Max unsigned 8-bit
function simd_min_epu8(const a, b: TM128): TM128; // Min unsigned 8-bit

// Multiply
function simd_mul_epu32(const a, b: TM128): TM128;   // unsigned 32-bit multiply
function simd_mullo_epi16(const a, b: TM128): TM128; // signed 16-bit multiply low
function simd_mulhi_epi16(const a, b: TM128): TM128; // signed 16-bit multiply high
function simd_mulhi_epu16(const a, b: TM128): TM128; // unsigned 16-bit multiply high
function simd_madd_epi16(const a, b: TM128): TM128; // Multiply and add 16-bit to 32-bit

// Average
function simd_avg_epu8(const a, b: TM128): TM128; // Average unsigned 8-bit
function simd_avg_epu16(const a, b: TM128): TM128; // Average unsigned 16-bit

// SAD
function simd_sad_epu8(const a, b: TM128): TM128; // Sum of absolute differences unsigned 8-bit

// === 4️⃣ Floating-Point Arithmetic ===
// Single Precision
function simd_add_ps(const a, b: TM128): TM128;
function simd_sub_ps(const a, b: TM128): TM128;
function simd_mul_ps(const a, b: TM128): TM128;
function simd_div_ps(const a, b: TM128): TM128;
function simd_sqrt_ps(const a: TM128): TM128;
function simd_min_ps(const a, b: TM128): TM128; // Min single
function simd_max_ps(const a, b: TM128): TM128; // Max single

// Double Precision
function simd_add_pd(const a, b: TM128): TM128;
function simd_sub_pd(const a, b: TM128): TM128;
function simd_mul_pd(const a, b: TM128): TM128;
function simd_div_pd(const a, b: TM128): TM128;
function simd_sqrt_pd(const a: TM128): TM128;
function simd_min_pd(const a, b: TM128): TM128; // Min packed double
function simd_max_pd(const a, b: TM128): TM128; // Max packed double
function simd_add_sd(const a, b: TM128): TM128; // Add scalar double
function simd_sub_sd(const a, b: TM128): TM128; // Sub scalar double
function simd_mul_sd(const a, b: TM128): TM128; // Mul scalar double
function simd_div_sd(const a, b: TM128): TM128; // Div scalar double
function simd_sqrt_sd(const a, b: TM128): TM128; // Sqrt scalar double (a upper pass through)
function simd_min_sd(const a, b: TM128): TM128; // Min scalar double
function simd_max_sd(const a, b: TM128): TM128; // Max scalar double

// === 5️⃣ Logical Operations ===
function simd_and_si128(const a, b: TM128): TM128;
function simd_or_si128(const a, b: TM128): TM128;
function simd_xor_si128(const a, b: TM128): TM128;
function simd_andnot_si128(const a, b: TM128): TM128;  // ~a & b
function simd_and_pd(const a, b: TM128): TM128; // And packed double
function simd_or_pd(const a, b: TM128): TM128; // Or packed double
function simd_xor_pd(const a, b: TM128): TM128; // Xor packed double
function simd_andnot_pd(const a, b: TM128): TM128; // Andnot packed double

// === 6️⃣ Compare / Mask ===
// Integer Compare
function simd_cmpeq_epi8(const a, b: TM128): TM128;
function simd_cmpeq_epi16(const a, b: TM128): TM128;
function simd_cmpeq_epi32(const a, b: TM128): TM128;
function simd_cmpgt_epi8(const a, b: TM128): TM128;
function simd_cmpgt_epi16(const a, b: TM128): TM128;
function simd_cmpgt_epi32(const a, b: TM128): TM128;
function simd_cmplt_epi8(const a, b: TM128): TM128;
function simd_cmplt_epi16(const a, b: TM128): TM128;
function simd_cmplt_epi32(const a, b: TM128): TM128;

// Floating-Point Compare
function simd_cmpeq_pd(const a, b: TM128): TM128;
function simd_cmplt_pd(const a, b: TM128): TM128;
function simd_cmple_pd(const a, b: TM128): TM128;
function simd_cmpgt_pd(const a, b: TM128): TM128;
function simd_cmpge_pd(const a, b: TM128): TM128;
function simd_cmpneq_pd(const a, b: TM128): TM128;
function simd_cmpnlt_pd(const a, b: TM128): TM128; // Not less than packed double
function simd_cmpnle_pd(const a, b: TM128): TM128; // Not less or equal packed double
function simd_cmpngt_pd(const a, b: TM128): TM128; // Not greater than packed double
function simd_cmpnge_pd(const a, b: TM128): TM128; // Not greater or equal packed double
function simd_cmpord_pd(const a, b: TM128): TM128; // Ordered packed double
function simd_cmpunord_pd(const a, b: TM128): TM128; // Unordered packed double
function simd_cmpeq_sd(const a, b: TM128): TM128; // Equal scalar double
function simd_cmplt_sd(const a, b: TM128): TM128; // Less than scalar double
function simd_cmple_sd(const a, b: TM128): TM128; // Less or equal scalar double
function simd_cmpgt_sd(const a, b: TM128): TM128; // Greater than scalar double
function simd_cmpge_sd(const a, b: TM128): TM128; // Greater or equal scalar double
function simd_cmpneq_sd(const a, b: TM128): TM128; // Not equal scalar double
function simd_cmpnlt_sd(const a, b: TM128): TM128; // Not less than scalar double
function simd_cmpnle_sd(const a, b: TM128): TM128; // Not less or equal scalar double
function simd_cmpngt_sd(const a, b: TM128): TM128; // Not greater than scalar double
function simd_cmpnge_sd(const a, b: TM128): TM128; // Not greater or equal scalar double
function simd_cmpord_sd(const a, b: TM128): TM128; // Ordered scalar double
function simd_cmpunord_sd(const a, b: TM128): TM128; // Unordered scalar double
function simd_comieq_sd(const a, b: TM128): Integer; // Scalar ordered equal compare, return int
function simd_comilt_sd(const a, b: TM128): Integer; // Scalar ordered less than compare, return int
function simd_comile_sd(const a, b: TM128): Integer; // Scalar ordered less or equal, return int
function simd_comigt_sd(const a, b: TM128): Integer; // Scalar ordered greater than, return int
function simd_comige_sd(const a, b: TM128): Integer; // Scalar ordered greater or equal, return int
function simd_comineq_sd(const a, b: TM128): Integer; // Scalar ordered not equal, return int
function simd_ucomieq_sd(const a, b: TM128): Integer; // Scalar unordered equal compare, return int
function simd_ucomilt_sd(const a, b: TM128): Integer; // Scalar unordered less than, return int
function simd_ucomile_sd(const a, b: TM128): Integer; // Scalar unordered less or equal, return int
function simd_ucomigt_sd(const a, b: TM128): Integer; // Scalar unordered greater than, return int
function simd_ucomige_sd(const a, b: TM128): Integer; // Scalar unordered greater or equal, return int
function simd_ucomineq_sd(const a, b: TM128): Integer; // Scalar unordered not equal, return int

// Move Mask
function simd_movemask_epi8(const a: TM128): Integer;
function simd_movemask_ps(const a: TM128): Integer;
function simd_movemask_pd(const a: TM128): Integer;

// === 7️⃣ Shuffle / Unpack / Permute ===
// Shuffle
function simd_shuffle_epi32(const a: TM128; imm8: Byte): TM128;
function simd_shuffle_pd(const a, b: TM128; imm8: Byte): TM128;
function simd_shuffle_ps(const a, b: TM128; imm8: Byte): TM128; // Shuffle single
function simd_shufflelo_epi16(const a: TM128; imm8: Byte): TM128; // Shuffle low 16-bit
function simd_shufflehi_epi16(const a: TM128; imm8: Byte): TM128; // Shuffle high 16-bit

// Unpack
function simd_unpacklo_epi8(const a, b: TM128): TM128;
function simd_unpackhi_epi8(const a, b: TM128): TM128;
function simd_unpacklo_epi16(const a, b: TM128): TM128;
function simd_unpackhi_epi16(const a, b: TM128): TM128;
function simd_unpacklo_epi32(const a, b: TM128): TM128;
function simd_unpackhi_epi32(const a, b: TM128): TM128;
function simd_unpacklo_epi64(const a, b: TM128): TM128;
function simd_unpackhi_epi64(const a, b: TM128): TM128;
function simd_unpacklo_pd(const a, b: TM128): TM128;
function simd_unpackhi_pd(const a, b: TM128): TM128;
function simd_unpacklo_ps(const a, b: TM128): TM128; // Unpack low single
function simd_unpackhi_ps(const a, b: TM128): TM128; // Unpack high single

// === 8️⃣ Shift / Rotate (Integers) ===
// Left Shift
function simd_slli_epi16(const a: TM128; imm8: Byte): TM128;
function simd_slli_epi32(const a: TM128; imm8: Byte): TM128;
function simd_slli_epi64(const a: TM128; imm8: Byte): TM128;
function simd_slli_si128(const a: TM128; imm8: Byte): TM128; // Left shift bytes in 128-bit

// Right Shift (Logical)
function simd_srli_epi16(const a: TM128; imm8: Byte): TM128;
function simd_srli_epi32(const a: TM128; imm8: Byte): TM128;
function simd_srli_epi64(const a: TM128; imm8: Byte): TM128;
function simd_srli_si128(const a: TM128; imm8: Byte): TM128; // Right shift bytes in 128-bit

// Right Shift (Arithmetic)
function simd_srai_epi16(const a: TM128; imm8: Byte): TM128;
function simd_srai_epi32(const a: TM128; imm8: Byte): TM128;
function simd_srai_si128(const a: TM128; imm8: Byte): TM128; // Arithmetic right shift bytes (sign extend)

// === 9️⃣ Conversion / Cast ===
// Type Conversion
function simd_cvtepi32_pd(const a: TM128): TM128;
function simd_cvtpd_epi32(const a: TM128): TM128;
function simd_cvtepi32_ps(const a: TM128): TM128;
function simd_cvtps_epi32(const a: TM128): TM128;
function simd_cvtpd_ps(const a: TM128): TM128; // Packed double to packed single
function simd_cvtps_pd(const a: TM128): TM128; // Packed single to packed double
function simd_cvtsd_ss(const a, b: TM128): TM128; // Scalar double to scalar single
function simd_cvtss_sd(const a, b: TM128): TM128; // Scalar single to scalar double
function simd_cvttpd_epi32(const a: TM128): TM128; // Truncate packed double to epi32
function simd_cvttpd_ps(const a: TM128): TM128; // Truncate packed double to single
function simd_cvttps_epi32(const a: TM128): TM128; // Truncate packed single to epi32
function simd_cvtsd_si32(const a: TM128): Integer; // Scalar double to si32
function simd_cvtsd_si64(const a: TM128): Int64; // Scalar double to si64
function simd_cvttsd_si32(const a: TM128): Integer; // Truncate scalar double to si32
function simd_cvttsd_si64(const a: TM128): Int64; // Truncate scalar double to si64

// Scalar Conversion
function simd_cvtsi32_si128(a: Integer): TM128;
function simd_cvtsi64_si128(a: Int64): TM128;
function simd_cvtsi128_si32(const a: TM128): Integer;
function simd_cvtsi128_si64(const a: TM128): Int64;
function simd_cvtsi32_sd(const a: TM128; b: Integer): TM128; // si32 to scalar double
function simd_cvtsi64_sd(const a: TM128; b: Int64): TM128; // si64 to scalar double

// Cast (No Conversion)
function simd_castpd_si128(const a: TM128): TM128;
function simd_castps_si128(const a: TM128): TM128;
function simd_castsi128_pd(const a: TM128): TM128;
function simd_castsi128_ps(const a: TM128): TM128;
function simd_castpd_ps(const a: TM128): TM128; // Cast double to single
function simd_castps_pd(const a: TM128): TM128; // Cast single to double

// === 🔟 Pack / Insert / Extract / Move ===
function simd_packs_epi16(const a, b: TM128): TM128; // Pack signed 16-bit to signed 8-bit with saturation
function simd_packs_epi32(const a, b: TM128): TM128; // Pack signed 32-bit to signed 16-bit with saturation
function simd_packus_epi16(const a, b: TM128): TM128; // Pack signed 16-bit to unsigned 8-bit with saturation
function simd_insert_epi16(const a: TM128; Value: Integer; imm8: Byte): TM128; // Insert 16-bit at position
function simd_extract_epi16(const a: TM128; imm8: Byte): Integer; // Extract 16-bit at position
function simd_move_sd(const a, b: TM128): TM128; // Move scalar double
function simd_move_epi64(const a: TM128): TM128; // Move 64-bit integer

// === 1️⃣1️⃣ Cache Control / Stream / Fence ===
procedure simd_clflush(const Ptr: Pointer); // Cache line flush
procedure simd_lfence; // Load fence
procedure simd_mfence; // Memory fence
procedure simd_pause; // Pause (spin loop hint)
procedure simd_stream_pd(var Dest; const Src: TM128); // Non-temporal store packed double
procedure simd_stream_ps(var Dest; const Src: TM128); // Non-temporal store packed single
procedure simd_stream_si128(var Dest; const Src: TM128); // Non-temporal store 128-bit
procedure simd_stream_si32(var Dest; Value: Integer); // Non-temporal store 32-bit
procedure simd_stream_si64(var Dest; Value: Int64); // Non-temporal store 64-bit

implementation

// === SSE2 Intrinsics 实现 ===
// 目前提供占位实现，后续将添加实际的内联汇编代�?
// === 1️⃣ Load / Store 实现 ===
function simd_load_si128(const Ptr: Pointer): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: 第一个参数在 rcx
    movdqa xmm0, [rcx]
  {$ELSE}
    // Linux/macOS x64 System V ABI: 第一个参数在 rdi
    movdqa xmm0, [rdi]
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    movdqa xmm0, [eax]
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_loadu_si128(const Ptr: Pointer): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: 第一个参数在 rcx
    movdqu xmm0, [rcx]
  {$ELSE}
    // Linux/macOS x64 System V ABI: 第一个参数在 rdi
    movdqu xmm0, [rdi]
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    movdqu xmm0, [eax]
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

procedure simd_store_si128(var Dest; const Src: TM128); {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Dest �?rcx, Src �?rdx
    movdqa xmm0, [rdx]
    movdqa [rcx], xmm0
    {$ELSE}
    // Linux/macOS x64 System V ABI: Dest �?rdi, Src �?rsi
    movdqa xmm0, [rsi]
    movdqa [rdi], xmm0
    {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    mov edx, [esp + 8]    // Src
    movdqa xmm0, [edx]
    movdqa [eax], xmm0
    {$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

procedure simd_storeu_si128(var Dest; const Src: TM128); {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
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
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    mov edx, [esp + 8]    // Src
    movdqu xmm0, [edx]    // 非对齐加载源数据
    movdqu [eax], xmm0    // 非对齐存储到目标
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// Double Load/Store
function simd_load_pd(const Ptr: Pointer): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: 第一个参数在 rcx
    movapd xmm0, [rcx]
  {$ELSE}
    // Linux/macOS x64 System V ABI: 第一个参数在 rdi
    movapd xmm0, [rdi]
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    movapd xmm0, [eax]
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_loadu_pd(const Ptr: Pointer): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: 第一个参数在 rcx
    movupd xmm0, [rcx]
  {$ELSE}
    // Linux/macOS x64 System V ABI: 第一个参数在 rdi
    movupd xmm0, [rdi]
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    movupd xmm0, [eax]
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

procedure simd_store_pd(var Dest; const Src: TM128); {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Dest �?rcx, Src �?rdx
    movapd xmm0, [rdx]
    movapd [rcx], xmm0
    {$ELSE}
    // Linux/macOS x64 System V ABI: Dest �?rdi, Src �?rsi
    movapd xmm0, [rsi]
    movapd [rdi], xmm0
    {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    mov edx, [esp + 8]    // Src
    movapd xmm0, [edx]
    movapd [eax], xmm0
    {$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

procedure simd_storeu_pd(var Dest; const Src: TM128); {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
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
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    mov edx, [esp + 8]    // Src
    movupd xmm0, [edx]    // 非对齐加载源数据
    movupd [eax], xmm0    // 非对齐存储到目标
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// Single Load/Store
function simd_load_ps(const Ptr: Pointer): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: 第一个参数在 rcx
    movaps xmm0, [rcx]
  {$ELSE}
    // Linux/macOS x64 System V ABI: 第一个参数在 rdi
    movaps xmm0, [rdi]
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    movaps xmm0, [eax]
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_loadu_ps(const Ptr: Pointer): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: 第一个参数在 rcx
    movups xmm0, [rcx]
  {$ELSE}
    // Linux/macOS x64 System V ABI: 第一个参数在 rdi
    movups xmm0, [rdi]
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    movups xmm0, [eax]
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

procedure simd_store_ps(var Dest; const Src: TM128); {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Dest �?rcx, Src �?rdx
    movaps xmm0, [rdx]
    movaps [rcx], xmm0
    {$ELSE}
    // Linux/macOS x64 System V ABI: Dest �?rdi, Src �?rsi
    movaps xmm0, [rsi]
    movaps [rdi], xmm0
    {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    mov edx, [esp + 8]    // Src
    movaps xmm0, [edx]
    movaps [eax], xmm0
    {$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

procedure simd_storeu_ps(var Dest; const Src: TM128); {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
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
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    mov edx, [esp + 8]    // Src
    movups xmm0, [edx]    // 非对齐加载源数据
    movups [eax], xmm0    // 非对齐存储到目标
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// === 2️⃣ Set / Zero / Broadcast 实现 ===
function simd_setzero_si128: TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
  // Intel 语法: pxor xmm0, xmm0
  pxor xmm0, xmm0
end;

function simd_setzero_pd: TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
  // Intel 语法: xorpd xmm0, xmm0
  // 双精度浮点数清零
  xorpd xmm0, xmm0
end;

function simd_setzero_ps: TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
  // Intel 语法: xorps xmm0, xmm0
  // 单精度浮点数清零
  xorps xmm0, xmm0
end;

function simd_set1_epi8(Value: ShortInt): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Value �?rcx (�?�?
    movd xmm0, ecx
    punpcklbw xmm0, xmm0
    punpcklwd xmm0, xmm0  // 复制�? 0011 -> 00001111
    pshufd xmm0, xmm0, 0
    {$ELSE}
    // Linux/macOS x64 System V ABI: Value �?rdi (�?�?
    movd xmm0, edi
    punpcklbw xmm0, xmm0
    punpcklwd xmm0, xmm0
    pshufd xmm0, xmm0, 0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    movd xmm0, eax
    punpcklbw xmm0, xmm0
    punpcklwd xmm0, xmm0
    pshufd xmm0, xmm0, 0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_set1_epi16(Value: SmallInt): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Value �?rcx (�?6�?
    movd xmm0, ecx
    punpcklwd xmm0, xmm0
    pshufd xmm0, xmm0, 0
    {$ELSE}
    // Linux/macOS x64 System V ABI: Value �?rdi (�?6�?
    movd xmm0, edi
    punpcklwd xmm0, xmm0
    pshufd xmm0, xmm0, 0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    movd xmm0, eax
    punpcklwd xmm0, xmm0
    pshufd xmm0, xmm0, 0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_set1_epi32(Value: LongInt): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Value �?rcx (�?2�?
    movd xmm0, ecx
    pshufd xmm0, xmm0, 0
  {$ELSE}
    // Linux/macOS x64 System V ABI: Value �?rdi (�?2�?
    movd xmm0, edi
    pshufd xmm0, xmm0, 0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    movd xmm0, eax
    pshufd xmm0, xmm0, 0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_set1_epi64x(Value: Int64): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Value �?rcx (64�?
    movq xmm0, rcx
    punpcklqdq xmm0, xmm0
    {$ELSE}
    // Linux/macOS x64 System V ABI: Value �?rdi (64�?
    movq xmm0, rdi
    punpcklqdq xmm0, xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    // x86 32-bit: Value 在栈�?(8字节)
    movq xmm0, [esp + 4]
    punpcklqdq xmm0, xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_set1_ps(Value: Single): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Value �?xmm0 (单精度浮点参�?
    shufps xmm0, xmm0, 0  // 复制 xmm0[0] 到所有位�?(00000000b = 0)
  {$ELSE}
    // Linux/macOS x64 System V ABI: Value �?xmm0
    shufps xmm0, xmm0, 0
  {$ENDIF}
{$ELSEIF CPUX86}
    movss xmm0, [esp + 4]
    shufps xmm0, xmm0, 0
    {$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_set1_pd(Value: Double): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Value �?xmm0 (双精度浮点参�?
    unpcklpd xmm0, xmm0
    {$ELSE}
    // Linux/macOS x64 System V ABI: Value �?xmm0
    unpcklpd xmm0, xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    // x86 32-bit: Value 在栈�?(8字节)
    movsd xmm0, [esp + 4] // 加载双精度浮点数
    unpcklpd xmm0, xmm0
    {$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// === 复杂 Set 函数实现 ===
// 重复�?Set 函数实现已删除，保留第二个版�?
// === Set 函数实现 ===
function simd_setr_epi32(a, b, c, d: LongInt): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: a在rcx, b在rdx, c在r8, d在r9
    movd xmm0, ecx        // a -> xmm0[31:0]
    movd xmm1, edx        // b -> xmm1[31:0]
    punpckldq xmm0, xmm1  // xmm0 = [b, a, 0, 0]
    movd xmm1, r8d        // c -> xmm1[31:0]
    movd xmm2, r9d        // d -> xmm2[31:0]
    punpckldq xmm1, xmm2  // xmm1 = [d, c, 0, 0]
    punpcklqdq xmm0, xmm1 // xmm0 = [d, c, b, a]
  {$ELSE}
    // Linux/macOS x64 System V ABI: a在rdi, b在rsi, c在rdx, d在rcx
    movd xmm0, edi
    movd xmm1, esi
    punpckldq xmm0, xmm1
    movd xmm1, edx
    movd xmm2, ecx
    punpckldq xmm1, xmm2
    punpcklqdq xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    mov edx, [esp + 8]    // b
    movd xmm0, eax
    movd xmm1, edx
    punpckldq xmm0, xmm1
    mov eax, [esp + 12]   // c
    mov edx, [esp + 16]   // d
    movd xmm1, eax
    movd xmm2, edx
    punpckldq xmm1, xmm2
    punpcklqdq xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_set_epi32(a, b, c, d: LongInt): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: a在rcx, b在rdx, c在r8, d在r9
    // 结果顺序: [a, b, c, d] (高位到低�?
    movd xmm0, r9d        // d -> xmm0[31:0]
    movd xmm1, r8d        // c -> xmm1[31:0]
    punpckldq xmm0, xmm1  // xmm0 = [c, d, 0, 0]
    movd xmm1, edx        // b -> xmm1[31:0]
    movd xmm2, ecx        // a -> xmm2[31:0]
    punpckldq xmm1, xmm2  // xmm1 = [a, b, 0, 0]
    punpcklqdq xmm0, xmm1 // xmm0 = [a, b, c, d]
  {$ELSE}
    // Linux/macOS x64 System V ABI: a在rdi, b在rsi, c在rdx, d在rcx
    movd xmm0, ecx        // d
    movd xmm1, edx        // c
    punpckldq xmm0, xmm1
    movd xmm1, esi        // b
    movd xmm2, edi        // a
    punpckldq xmm1, xmm2
    punpcklqdq xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 16]
    mov edx, [esp + 12]   // c
    movd xmm0, eax
    movd xmm1, edx
    punpckldq xmm0, xmm1
    mov eax, [esp + 8]    // b
    mov edx, [esp + 4]    // a
    movd xmm1, eax
    movd xmm2, edx
    punpckldq xmm1, xmm2
    punpcklqdq xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_setr_pd(a, b: Double): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: a在xmm0, b在xmm1
    unpcklpd xmm0, xmm1   // xmm0 = [b, a] (高位, 低位)
  {$ELSE}
    // Linux/macOS x64 System V ABI: a在xmm0, b在xmm1
    unpcklpd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    movsd xmm0, [esp + 4]
    movsd xmm1, [esp + 12] // b (8字节)
    unpcklpd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_set_epi64x(a, b: Int64): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: a在rcx, b在rdx
    // 结果: [a, b] (�?4�? �?4�?
    movq xmm0, rdx
    movq xmm1, rcx
    punpcklqdq xmm0, xmm1
  {$ELSE}
    // Linux/macOS x64 System V ABI: a在rdi, b在rsi
    movq xmm0, rsi
    movq xmm1, rdi
    punpcklqdq xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    movq xmm0, [esp + 12]
    movq xmm1, [esp + 4]  // a (8字节)
    punpcklqdq xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// === 剩余函数的占位实�?===
// 为了编译通过，这里提供简单的占位实现
// 后续将逐步添加实际的内联汇编代�?
// 关键函数的占位实�?
function simd_add_epi8(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: a �?rcx, b �?rdx
    movdqu xmm0, [rcx]    // 加载 a
    movdqu xmm1, [rdx]    // 加载 b
    paddb xmm0, xmm1
    {$ELSE}
    // Linux/macOS x64 System V ABI: a �?rdi, b �?rsi
    movdqu xmm0, [rdi]    // 加载 a
    movdqu xmm1, [rsi]    // 加载 b
    paddb xmm0, xmm1
    {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    mov edx, [esp + 8]    // b
    movdqu xmm0, [eax]
    movdqu xmm1, [edx]
    paddb xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmpeq_epi8(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    pcmpeqb xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pcmpeqb xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pcmpeqb xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_and_si128(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    pand xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pand xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pand xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// simd_movemask_epi8 实现已移至汇编版�?
// === 3️⃣ Integer Arithmetic 剩余实现 ===
function simd_add_epi16(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: a �?rcx, b �?rdx
    movdqu xmm0, [rcx]    // 加载 a
    movdqu xmm1, [rdx]    // 加载 b
    paddw xmm0, xmm1
    {$ELSE}
    // Linux/macOS x64 System V ABI: a �?rdi, b �?rsi
    movdqu xmm0, [rdi]    // 加载 a
    movdqu xmm1, [rsi]    // 加载 b
    paddw xmm0, xmm1
    {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    mov edx, [esp + 8]    // b
    movdqu xmm0, [eax]
    movdqu xmm1, [edx]
    paddw xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_add_epi32(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: a �?rcx, b �?rdx
    movdqu xmm0, [rcx]    // 加载 a
    movdqu xmm1, [rdx]    // 加载 b
    paddd xmm0, xmm1
    {$ELSE}
    // Linux/macOS x64 System V ABI: a �?rdi, b �?rsi
    movdqu xmm0, [rdi]    // 加载 a
    movdqu xmm1, [rsi]    // 加载 b
    paddd xmm0, xmm1
    {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    mov edx, [esp + 8]    // b
    movdqu xmm0, [eax]
    movdqu xmm1, [edx]
    paddd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_add_epi64(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: a �?rcx, b �?rdx
    movdqu xmm0, [rcx]    // 加载 a
    movdqu xmm1, [rdx]    // 加载 b
    paddq xmm0, xmm1
    {$ELSE}
    // Linux/macOS x64 System V ABI: a �?rdi, b �?rsi
    movdqu xmm0, [rdi]    // 加载 a
    movdqu xmm1, [rsi]    // 加载 b
    paddq xmm0, xmm1
    {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    mov edx, [esp + 8]    // b
    movdqu xmm0, [eax]
    movdqu xmm1, [edx]
    paddq xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_sub_epi8(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: a �?rcx, b �?rdx
    movdqu xmm0, [rcx]    // 加载 a
    movdqu xmm1, [rdx]    // 加载 b
    psubb xmm0, xmm1
    {$ELSE}
    // Linux/macOS x64 System V ABI: a �?rdi, b �?rsi
    movdqu xmm0, [rdi]    // 加载 a
    movdqu xmm1, [rsi]    // 加载 b
    psubb xmm0, xmm1
    {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    mov edx, [esp + 8]    // b
    movdqu xmm0, [eax]
    movdqu xmm1, [edx]
    psubb xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_sub_epi16(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; psubw xmm0, xmm1
  {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; psubw xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; psubw xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_sub_epi32(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; psubd xmm0, xmm1
  {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; psubd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; psubd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_sub_epi64(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]; movdqu xmm1, [rdx]; psubq xmm0, xmm1
  {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; psubq xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; psubq xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_adds_epi8(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    paddsb xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; paddsb xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; paddsb xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_adds_epi16(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    paddsw xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; paddsw xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; paddsw xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_subs_epi8(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    psubsb xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; psubsb xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; psubsb xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_subs_epi16(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    psubsw xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; psubsw xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; psubsw xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_max_epi8(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]    // 加载 a
    movdqu xmm1, [rdx]    // 加载 b
    movdqu xmm2, xmm0     // 复制 a
    pcmpgtb xmm2, xmm1
    pand xmm0, xmm2
    pandn xmm2, xmm1      // 选择 b 中较大的元素
    por xmm0, xmm2        // 合并结果
  {$ELSE}
    movdqu xmm0, [rdi]
    movdqu xmm1, [rsi]
    movdqu xmm2, xmm0
    pcmpgtb xmm2, xmm1
    pand xmm0, xmm2
    pandn xmm2, xmm1
    por xmm0, xmm2
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]
    movdqu xmm0, [eax]; movdqu xmm1, [edx]
    movdqu xmm2, xmm0; pcmpgtb xmm2, xmm1
    pand xmm0, xmm2; pandn xmm2, xmm1; por xmm0, xmm2
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_max_epi16(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    pmaxsw xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pmaxsw xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pmaxsw xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_min_epi8(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]    // 加载 a
    movdqu xmm1, [rdx]    // 加载 b
    movdqu xmm2, xmm1     // 复制 b
    pcmpgtb xmm2, xmm0
    pand xmm0, xmm2
    pandn xmm2, xmm1      // 选择 b 中较小的元素
    por xmm0, xmm2        // 合并结果
  {$ELSE}
    movdqu xmm0, [rdi]
    movdqu xmm1, [rsi]
    movdqu xmm2, xmm1
    pcmpgtb xmm2, xmm0
    pand xmm0, xmm2
    pandn xmm2, xmm1
    por xmm0, xmm2
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]
    movdqu xmm0, [eax]; movdqu xmm1, [edx]
    movdqu xmm2, xmm1; pcmpgtb xmm2, xmm0
    pand xmm0, xmm2; pandn xmm2, xmm1; por xmm0, xmm2
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_min_epi16(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    pminsw xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pminsw xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pminsw xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_mul_epu32(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    pmuludq xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pmuludq xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pmuludq xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_mullo_epi16(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    pmullw xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pmullw xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pmullw xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// === 4️⃣ Floating-Point Arithmetic 实现 ===
function simd_add_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
    addps xmm0, xmm1
  {$ELSE}
    movups xmm0, [rdi]; movups xmm1, [rsi]; addps xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movups xmm0, [eax]; movups xmm1, [edx]; addps xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_sub_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
    subps xmm0, xmm1
  {$ELSE}
    movups xmm0, [rdi]; movups xmm1, [rsi]; subps xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movups xmm0, [eax]; movups xmm1, [edx]; subps xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_mul_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
    mulps xmm0, xmm1
  {$ELSE}
    movups xmm0, [rdi]; movups xmm1, [rsi]; mulps xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movups xmm0, [eax]; movups xmm1, [edx]; mulps xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_div_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
    divps xmm0, xmm1
  {$ELSE}
    movups xmm0, [rdi]; movups xmm1, [rsi]; divps xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movups xmm0, [eax]; movups xmm1, [edx]; divps xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_sqrt_ps(const a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    sqrtps xmm0, xmm0
    {$ELSE}
    movups xmm0, [rdi]; sqrtps xmm0, xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; movups xmm0, [eax]; sqrtps xmm0, xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_add_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movupd xmm1, [rdx]
    addpd xmm0, xmm1
  {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; addpd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; addpd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_sub_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movupd xmm1, [rdx]
    subpd xmm0, xmm1
  {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; subpd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; subpd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_mul_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movupd xmm1, [rdx]
    mulpd xmm0, xmm1
  {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; mulpd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; mulpd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_div_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movupd xmm1, [rdx]
    divpd xmm0, xmm1
  {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; divpd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; divpd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_sqrt_pd(const a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    sqrtpd xmm0, xmm0
    {$ELSE}
    movupd xmm0, [rdi]; sqrtpd xmm0, xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; movupd xmm0, [eax]; sqrtpd xmm0, xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// === 5️⃣ Logical Operations 剩余实现 ===
function simd_or_si128(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    por xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; por xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; por xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_xor_si128(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    pxor xmm0, xmm1
  {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pxor xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pxor xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_andnot_si128(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    pandn xmm0, xmm1
  {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pandn xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pandn xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// === 6️⃣ Compare / Mask 剩余实现 ===
function simd_cmpeq_epi16(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    pcmpeqw xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pcmpeqw xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pcmpeqw xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmpeq_epi32(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    pcmpeqd xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pcmpeqd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pcmpeqd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmpgt_epi8(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    pcmpgtb xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pcmpgtb xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pcmpgtb xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmpgt_epi16(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    pcmpgtw xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pcmpgtw xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pcmpgtw xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmpgt_epi32(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    pcmpgtd xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pcmpgtd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pcmpgtd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// === 否定比较函数实现 ===
function simd_cmpnlt_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movupd xmm1, [rdx]
    cmpnltpd xmm0, xmm1
  {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; cmpnltpd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; cmpnltpd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmpnle_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movupd xmm1, [rdx]
    cmpnlepd xmm0, xmm1
  {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; cmpnlepd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; cmpnlepd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmpngt_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movupd xmm1, [rdx]
    cmppd xmm0, xmm1, 2
  {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; cmppd xmm0, xmm1, 2
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; cmppd xmm0, xmm1, 2
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmpnge_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movupd xmm1, [rdx]
    cmppd xmm0, xmm1, 1
  {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; cmppd xmm0, xmm1, 1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; cmppd xmm0, xmm1, 1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmplt_epi8(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rdx]
    movdqu xmm1, [rcx]
    pcmpgtb xmm0, xmm1
  {$ELSE}
    movdqu xmm0, [rsi]; movdqu xmm1, [rdi]; pcmpgtb xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [edx]; movdqu xmm1, [eax]; pcmpgtb xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmplt_epi16(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rdx]
    movdqu xmm1, [rcx]
    pcmpgtw xmm0, xmm1
  {$ELSE}
    movdqu xmm0, [rsi]; movdqu xmm1, [rdi]; pcmpgtw xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [edx]; movdqu xmm1, [eax]; pcmpgtw xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmplt_epi32(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rdx]
    movdqu xmm1, [rcx]
    pcmpgtd xmm0, xmm1
  {$ELSE}
    movdqu xmm0, [rsi]; movdqu xmm1, [rdi]; pcmpgtd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [edx]; movdqu xmm1, [eax]; pcmpgtd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// === 双精度比较函数实�?===
function simd_cmpeq_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movupd xmm1, [rdx]
    cmpeqpd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; cmpeqpd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; cmpeqpd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmplt_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movupd xmm1, [rdx]
    cmpltpd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; cmpltpd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; cmpltpd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmple_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movupd xmm1, [rdx]
    cmplepd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; cmplepd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; cmplepd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmpgt_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rdx]
    movupd xmm1, [rcx]
    cmpltpd xmm0, xmm1
  {$ELSE}
    movupd xmm0, [rsi]; movupd xmm1, [rdi]; cmpltpd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [edx]; movupd xmm1, [eax]; cmpltpd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmpge_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rdx]
    movupd xmm1, [rcx]
    cmplepd xmm0, xmm1
  {$ELSE}
    movupd xmm0, [rsi]; movupd xmm1, [rdi]; cmplepd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [edx]; movupd xmm1, [eax]; cmplepd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmpneq_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movupd xmm1, [rdx]
    cmpneqpd xmm0, xmm1
  {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; cmpneqpd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; cmpneqpd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// Move Mask 实现已移至汇编版�?
// === 7️⃣ Shuffle / Unpack / Permute 实现 ===
function simd_shuffle_epi32(const a: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]    // 加载 a
    cmp dl, 0; je @imm0
    cmp dl, 1; je @imm1
    cmp dl, 2; je @imm2
    cmp dl, 3; je @imm3
    // 更多立即数值的处理...
    pshufd xmm0, xmm0, $E4
    jmp @done
@imm0: pshufd xmm0, xmm0, $00; jmp @done
@imm1: pshufd xmm0, xmm0, $01; jmp @done
@imm2: pshufd xmm0, xmm0, $02; jmp @done
@imm3: pshufd xmm0, xmm0, $03; jmp @done
@done:
  {$ELSE}
    movdqu xmm0, [rdi]
    cmp sil, 0; je @imm0
    cmp sil, 1; je @imm1
    cmp sil, 2; je @imm2
    cmp sil, 3; je @imm3
    pshufd xmm0, xmm0, $E4
    jmp @done
@imm0: pshufd xmm0, xmm0, $00; jmp @done
@imm1: pshufd xmm0, xmm0, $01; jmp @done
@imm2: pshufd xmm0, xmm0, $02; jmp @done
@imm3: pshufd xmm0, xmm0, $03; jmp @done
@done:
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]
    movdqu xmm0, [eax]
    cmp dl, 0; je @imm0
    cmp dl, 1; je @imm1
    cmp dl, 2; je @imm2
    cmp dl, 3; je @imm3
    pshufd xmm0, xmm0, $E4; jmp @done
@imm0: pshufd xmm0, xmm0, $00; jmp @done
@imm1: pshufd xmm0, xmm0, $01; jmp @done
@imm2: pshufd xmm0, xmm0, $02; jmp @done
@imm3: pshufd xmm0, xmm0, $03; jmp @done
@done:
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_shuffle_pd(const a, b: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]    // 加载 a
    movupd xmm1, [rdx]    // 加载 b
    cmp r8b, 0; je @imm0
    cmp r8b, 1; je @imm1
    cmp r8b, 2; je @imm2
    cmp r8b, 3; je @imm3
    shufpd xmm0, xmm1, 0
    jmp @done
    shufpd xmm0, xmm1, 0
    jmp @done
@imm1: shufpd xmm0, xmm1, 1; jmp @done
@imm2: shufpd xmm0, xmm1, 2; jmp @done
@imm3: shufpd xmm0, xmm1, 3; jmp @done
@done:
  {$ELSE}
    movupd xmm0, [rdi]
    movupd xmm1, [rsi]
    cmp dl, 0; je @imm0
    cmp dl, 1; je @imm1
    cmp dl, 2; je @imm2
    cmp dl, 3; je @imm3
    shufpd xmm0, xmm1, 0; jmp @done
@imm0: shufpd xmm0, xmm1, 0; jmp @done
@imm1: shufpd xmm0, xmm1, 1; jmp @done
@imm2: shufpd xmm0, xmm1, 2; jmp @done
@imm3: shufpd xmm0, xmm1, 3; jmp @done
@done:
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; mov ecx, [esp + 12]
    movupd xmm0, [eax]; movupd xmm1, [edx]
    cmp cl, 0; je @imm0
    cmp cl, 1; je @imm1
    cmp cl, 2; je @imm2
    cmp cl, 3; je @imm3
    shufpd xmm0, xmm1, 0; jmp @done
@imm0: shufpd xmm0, xmm1, 0; jmp @done
@imm1: shufpd xmm0, xmm1, 1; jmp @done
@imm2: shufpd xmm0, xmm1, 2; jmp @done
@imm3: shufpd xmm0, xmm1, 3; jmp @done
@done:
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_shuffle_ps(const a, b: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]    // 加载 a
    movups xmm1, [rdx]    // 加载 b
    // 使用常见�?shuffle 模式
    cmp r8b, $00; je @imm00
    cmp r8b, $44; je @imm44
    cmp r8b, $88; je @imm88
    cmp r8b, $E4; je @immE4
    shufps xmm0, xmm1, $00
    jmp @done
@imm00: shufps xmm0, xmm1, $00; jmp @done
@imm44: shufps xmm0, xmm1, $44; jmp @done
@imm88: shufps xmm0, xmm1, $88; jmp @done
@immE4: shufps xmm0, xmm1, $E4; jmp @done
@done:
  {$ELSE}
    movups xmm0, [rdi]
    movups xmm1, [rsi]
    cmp dl, $00; je @imm00
    cmp dl, $44; je @imm44
    cmp dl, $88; je @imm88
    cmp dl, $E4; je @immE4
    shufps xmm0, xmm1, $00; jmp @done
@imm00: shufps xmm0, xmm1, $00; jmp @done
@imm44: shufps xmm0, xmm1, $44; jmp @done
@imm88: shufps xmm0, xmm1, $88; jmp @done
@immE4: shufps xmm0, xmm1, $E4; jmp @done
@done:
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; mov ecx, [esp + 12]
    movups xmm0, [eax]; movups xmm1, [edx]
    cmp cl, $00; je @imm00
    cmp cl, $44; je @imm44
    cmp cl, $88; je @imm88
    cmp cl, $E4; je @immE4
    shufps xmm0, xmm1, $00; jmp @done
@imm00: shufps xmm0, xmm1, $00; jmp @done
@imm44: shufps xmm0, xmm1, $44; jmp @done
@imm88: shufps xmm0, xmm1, $88; jmp @done
@immE4: shufps xmm0, xmm1, $E4; jmp @done
@done:
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_shufflelo_epi16(const a: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]    // 加载 a
    // 使用常见�?shuffle 模式
    cmp dl, $00; je @imm00
    cmp dl, $44; je @imm44
    cmp dl, $88; je @imm88
    cmp dl, $E4; je @immE4
    pshuflw xmm0, xmm0, $00
    jmp @done
@imm00: pshuflw xmm0, xmm0, $00; jmp @done
@imm44: pshuflw xmm0, xmm0, $44; jmp @done
@imm88: pshuflw xmm0, xmm0, $88; jmp @done
@immE4: pshuflw xmm0, xmm0, $E4; jmp @done
@done:
  {$ELSE}
    movdqu xmm0, [rdi]
    cmp sil, $00; je @imm00
    cmp sil, $44; je @imm44
    cmp sil, $88; je @imm88
    cmp sil, $E4; je @immE4
    pshuflw xmm0, xmm0, $00; jmp @done
@imm00: pshuflw xmm0, xmm0, $00; jmp @done
@imm44: pshuflw xmm0, xmm0, $44; jmp @done
@imm88: pshuflw xmm0, xmm0, $88; jmp @done
@immE4: pshuflw xmm0, xmm0, $E4; jmp @done
@done:
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]
    movdqu xmm0, [eax]
    cmp dl, $00; je @imm00
    cmp dl, $44; je @imm44
    cmp dl, $88; je @imm88
    cmp dl, $E4; je @immE4
    pshuflw xmm0, xmm0, $00; jmp @done
@imm00: pshuflw xmm0, xmm0, $00; jmp @done
@imm44: pshuflw xmm0, xmm0, $44; jmp @done
@imm88: pshuflw xmm0, xmm0, $88; jmp @done
@immE4: pshuflw xmm0, xmm0, $E4; jmp @done
@done:
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_shufflehi_epi16(const a: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]    // 加载 a
    // 使用常见�?shuffle 模式
    cmp dl, $00; je @imm00
    cmp dl, $44; je @imm44
    cmp dl, $88; je @imm88
    cmp dl, $E4; je @immE4
    pshufhw xmm0, xmm0, $00
    jmp @done
@imm00: pshufhw xmm0, xmm0, $00; jmp @done
@imm44: pshufhw xmm0, xmm0, $44; jmp @done
@imm88: pshufhw xmm0, xmm0, $88; jmp @done
@immE4: pshufhw xmm0, xmm0, $E4; jmp @done
@done:
  {$ELSE}
    movdqu xmm0, [rdi]
    cmp sil, $00; je @imm00
    cmp sil, $44; je @imm44
    cmp sil, $88; je @imm88
    cmp sil, $E4; je @immE4
    pshufhw xmm0, xmm0, $00; jmp @done
@imm00: pshufhw xmm0, xmm0, $00; jmp @done
@imm44: pshufhw xmm0, xmm0, $44; jmp @done
@imm88: pshufhw xmm0, xmm0, $88; jmp @done
@immE4: pshufhw xmm0, xmm0, $E4; jmp @done
@done:
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]
    movdqu xmm0, [eax]
    cmp dl, $00; je @imm00
    cmp dl, $44; je @imm44
    cmp dl, $88; je @imm88
    cmp dl, $E4; je @immE4
    pshufhw xmm0, xmm0, $00; jmp @done
@imm00: pshufhw xmm0, xmm0, $00; jmp @done
@imm44: pshufhw xmm0, xmm0, $44; jmp @done
@imm88: pshufhw xmm0, xmm0, $88; jmp @done
@immE4: pshufhw xmm0, xmm0, $E4; jmp @done
@done:
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_unpacklo_epi8(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    punpcklbw xmm0, xmm1
  {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; punpcklbw xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; punpcklbw xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_unpackhi_epi8(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    punpckhbw xmm0, xmm1
  {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; punpckhbw xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; punpckhbw xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_unpacklo_epi16(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    punpcklwd xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; punpcklwd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; punpcklwd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_unpackhi_epi16(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    punpckhwd xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; punpckhwd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; punpckhwd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_unpacklo_epi32(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    punpckldq xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; punpckldq xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; punpckldq xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_unpackhi_epi32(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    punpckhdq xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; punpckhdq xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; punpckhdq xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_unpacklo_epi64(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    punpcklqdq xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; punpcklqdq xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; punpcklqdq xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_unpackhi_epi64(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    punpckhqdq xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; punpckhqdq xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; punpckhqdq xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_unpacklo_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movupd xmm1, [rdx]
    unpcklpd xmm0, xmm1
  {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; unpcklpd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; unpcklpd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_unpackhi_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movupd xmm1, [rdx]
    unpckhpd xmm0, xmm1
  {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; unpckhpd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; unpckhpd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// === 8️⃣ Shift / Rotate 实现 ===
function simd_slli_epi16(const a: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]    // 加载 a
    cmp dl, 16
    jae @zero
    cmp dl, 0
    je @done
    movd xmm1, edx
    psllw xmm0, xmm1
    jmp @done
@zero:
    pxor xmm0, xmm0       // 清零
@done:
  {$ELSE}
    movdqu xmm0, [rdi]
    cmp sil, 16; jae @zero
    cmp sil, 0; je @done
    movd xmm1, esi
    psllw xmm0, xmm1
    jmp @done
@zero:
    pxor xmm0, xmm0
@done:
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]
    movdqu xmm0, [eax]
    cmp dl, 16; jae @zero
    cmp dl, 0; je @done
    movd xmm1, edx; psllw xmm0, xmm1; jmp @done
@zero: pxor xmm0, xmm0
@done:
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_slli_epi32(const a: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    cmp dl, 32
    jae @zero
    cmp dl, 0
    je @done
    movd xmm1, edx
    pslld xmm0, xmm1
    jmp @done
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
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]
    cmp dl, 32; jae @zero
    cmp dl, 0; je @done
    movd xmm1, edx; pslld xmm0, xmm1; jmp @done
@zero: pxor xmm0, xmm0
@done:
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_slli_epi64(const a: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    cmp dl, 64
    jae @zero
    cmp dl, 0
    je @done
    movd xmm1, edx
    psllq xmm0, xmm1
    jmp @done
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
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]
    cmp dl, 64; jae @zero
    cmp dl, 0; je @done
    movd xmm1, edx; psllq xmm0, xmm1; jmp @done
@zero: pxor xmm0, xmm0
@done:
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_srli_epi16(const a: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    cmp dl, 16
    jae @zero
    cmp dl, 0
    je @done
    movd xmm1, edx
    psrlw xmm0, xmm1
    jmp @done
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
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]
    cmp dl, 16; jae @zero
    cmp dl, 0; je @done
    movd xmm1, edx; psrlw xmm0, xmm1; jmp @done
@zero: pxor xmm0, xmm0
@done:
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_srli_epi32(const a: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    cmp dl, 32
    jae @zero
    cmp dl, 0
    je @done
    movd xmm1, edx
    psrld xmm0, xmm1
    jmp @done
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
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]
    cmp dl, 32; jae @zero
    cmp dl, 0; je @done
    movd xmm1, edx; psrld xmm0, xmm1; jmp @done
@zero: pxor xmm0, xmm0
@done:
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_srli_epi64(const a: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    cmp dl, 64
    jae @zero
    cmp dl, 0
    je @done
    movd xmm1, edx
    psrlq xmm0, xmm1
    jmp @done
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
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]
    cmp dl, 64; jae @zero
    cmp dl, 0; je @done
    movd xmm1, edx; psrlq xmm0, xmm1; jmp @done
@zero: pxor xmm0, xmm0
@done:
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_srai_epi16(const a: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    cmp dl, 16
    jae @max
    cmp dl, 0
    je @done
    movd xmm1, edx
    psraw xmm0, xmm1
    jmp @done
@max: psraw xmm0, 15     // 最大移位保持符�?@done:
  {$ELSE}
    movdqu xmm0, [rdi]
    cmp sil, 16; jae @max
    cmp sil, 0; je @done
    movd xmm1, esi; psraw xmm0, xmm1; jmp @done
@max: psraw xmm0, 15
@done:
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]
    cmp dl, 16; jae @max
    cmp dl, 0; je @done
    movd xmm1, edx; psraw xmm0, xmm1; jmp @done
@max: psraw xmm0, 15
@done:
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_srai_epi32(const a: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    cmp dl, 32
    jae @max
    cmp dl, 0
    je @done
    movd xmm1, edx
    psrad xmm0, xmm1
    jmp @done
@max: psrad xmm0, 31     // 最大移位保持符�?@done:
  {$ELSE}
    movdqu xmm0, [rdi]
    cmp sil, 32; jae @max
    cmp sil, 0; je @done
    movd xmm1, esi; psrad xmm0, xmm1; jmp @done
@max: psrad xmm0, 31
@done:
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]
    cmp dl, 32; jae @max
    cmp dl, 0; je @done
    movd xmm1, edx; psrad xmm0, xmm1; jmp @done
@max: psrad xmm0, 31
@done:
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// === 字节级移位函数实�?===
function simd_slli_si128(const a: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]    // 加载 a
    cmp dl, 16
    jae @zero
    cmp dl, 0
    je @done
    pslldq 只接受立即数，需要分支处�?    cmp dl, 1
    je @shift1
    cmp dl, 2; je @shift2
    cmp dl, 4; je @shift4
    cmp dl, 8; je @shift8
    cmp dl, 12; je @shift12
    pslldq xmm0, 16
    jmp @done
@shift1: pslldq xmm0, 1; jmp @done
@shift2: pslldq xmm0, 2; jmp @done
@shift4: pslldq xmm0, 4; jmp @done
@shift8: pslldq xmm0, 8; jmp @done
@shift12: pslldq xmm0, 12; jmp @done
@zero: pxor xmm0, xmm0
@done:
  {$ELSE}
    movdqu xmm0, [rdi]
    cmp sil, 16; jae @zero
    cmp sil, 0; je @done
    cmp sil, 1; je @shift1
    cmp sil, 2; je @shift2
    cmp sil, 4; je @shift4
    cmp sil, 8; je @shift8
    cmp sil, 12; je @shift12
    pslldq xmm0, 16; jmp @done
@shift1: pslldq xmm0, 1; jmp @done
@shift2: pslldq xmm0, 2; jmp @done
@shift4: pslldq xmm0, 4; jmp @done
@shift8: pslldq xmm0, 8; jmp @done
@shift12: pslldq xmm0, 12; jmp @done
@zero: pxor xmm0, xmm0
@done:
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]
    cmp dl, 16; jae @zero
    cmp dl, 0; je @done
    cmp dl, 1; je @shift1
    cmp dl, 2; je @shift2
    cmp dl, 4; je @shift4
    cmp dl, 8; je @shift8
    cmp dl, 12; je @shift12
    pslldq xmm0, 16; jmp @done
@shift1: pslldq xmm0, 1; jmp @done
@shift2: pslldq xmm0, 2; jmp @done
@shift4: pslldq xmm0, 4; jmp @done
@shift8: pslldq xmm0, 8; jmp @done
@shift12: pslldq xmm0, 12; jmp @done
@zero: pxor xmm0, xmm0
@done:
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_srli_si128(const a: TM128; imm8: Byte): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]    // 加载 a
    cmp dl, 16
    jae @zero
    cmp dl, 0
    je @done
    psrldq 只接受立即数，需要分支处�?    cmp dl, 1
    je @shift1
    cmp dl, 2; je @shift2
    cmp dl, 4; je @shift4
    cmp dl, 8; je @shift8
    cmp dl, 12; je @shift12
    psrldq xmm0, 16
    jmp @done
@shift1: psrldq xmm0, 1; jmp @done
@shift2: psrldq xmm0, 2; jmp @done
@shift4: psrldq xmm0, 4; jmp @done
@shift8: psrldq xmm0, 8; jmp @done
@shift12: psrldq xmm0, 12; jmp @done
@zero: pxor xmm0, xmm0
@done:
  {$ELSE}
    movdqu xmm0, [rdi]
    cmp sil, 16; jae @zero
    cmp sil, 0; je @done
    cmp sil, 1; je @shift1
    cmp sil, 2; je @shift2
    cmp sil, 4; je @shift4
    cmp sil, 8; je @shift8
    cmp sil, 12; je @shift12
    psrldq xmm0, 16; jmp @done
@shift1: psrldq xmm0, 1; jmp @done
@shift2: psrldq xmm0, 2; jmp @done
@shift4: psrldq xmm0, 4; jmp @done
@shift8: psrldq xmm0, 8; jmp @done
@shift12: psrldq xmm0, 12; jmp @done
@zero: pxor xmm0, xmm0
@done:
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]
    cmp dl, 16; jae @zero
    cmp dl, 0; je @done
    cmp dl, 1; je @shift1
    cmp dl, 2; je @shift2
    cmp dl, 4; je @shift4
    cmp dl, 8; je @shift8
    cmp dl, 12; je @shift12
    psrldq xmm0, 16; jmp @done
@shift1: psrldq xmm0, 1; jmp @done
@shift2: psrldq xmm0, 2; jmp @done
@shift4: psrldq xmm0, 4; jmp @done
@shift8: psrldq xmm0, 8; jmp @done
@shift12: psrldq xmm0, 12; jmp @done
@zero: pxor xmm0, xmm0
@done:
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// === 9️⃣ Conversion / Cast 实现 ===
function simd_cvtepi32_pd(const a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]    // 加载 a
    cvtdq2pd xmm0, xmm0
    {$ELSE}
    movdqu xmm0, [rdi]
    cvtdq2pd xmm0, xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]    // a
    movdqu xmm0, [eax]
    cvtdq2pd xmm0, xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cvtpd_epi32(const a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]    // 加载 a
    cvtpd2dq xmm0, xmm0
    {$ELSE}
    movupd xmm0, [rdi]
    cvtpd2dq xmm0, xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]    // a
    movupd xmm0, [eax]
    cvtpd2dq xmm0, xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cvtepi32_ps(const a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]    // 加载 a
    cvtdq2ps xmm0, xmm0
    {$ELSE}
    movdqu xmm0, [rdi]
    cvtdq2ps xmm0, xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]    // a
    movdqu xmm0, [eax]
    cvtdq2ps xmm0, xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cvtps_epi32(const a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]    // 加载 a
    cvtps2dq xmm0, xmm0
    {$ELSE}
    movups xmm0, [rdi]
    cvtps2dq xmm0, xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]    // a
    movups xmm0, [eax]
    cvtps2dq xmm0, xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cvtsi32_si128(a: Integer): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movd xmm0, ecx        // 32位整数转128位（�?2位）
  {$ELSE}
    movd xmm0, edi        // Linux/macOS x64
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]    // a
    movd xmm0, eax
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cvtsi64_si128(a: Int64): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movq xmm0, rcx        // 64位整数转128位（�?4位）
  {$ELSE}
    movq xmm0, rdi        // Linux/macOS x64
  {$ENDIF}
{$ELSEIF CPUX86}
    movq xmm0, [esp + 4]  // 64位参数在栈上
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cvtsi128_si32(const a: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]    // 加载 a
    movd eax, xmm0
    {$ELSE}
    movdqu xmm0, [rdi]
    movd eax, xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov edx, [esp + 4]    // a
    movdqu xmm0, [edx]
    movd eax, xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cvtsi128_si64(const a: TM128): Int64; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]    // 加载 a
    movq rax, xmm0
    {$ELSE}
    movdqu xmm0, [rdi]
    movq rax, xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov edx, [esp + 4]    // a
    movdqu xmm0, [edx]
    movq [esp + 8], xmm0
    {$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// === 浮点精度转换函数 ===
function simd_cvtpd_ps(const a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]    // 加载 a
    cvtpd2ps xmm0, xmm0
    {$ELSE}
    movupd xmm0, [rdi]
    cvtpd2ps xmm0, xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]    // a
    movupd xmm0, [eax]
    cvtpd2ps xmm0, xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cvtps_pd(const a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]    // 加载 a
    cvtps2pd xmm0, xmm0
    {$ELSE}
    movups xmm0, [rdi]
    cvtps2pd xmm0, xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]    // a
    movups xmm0, [eax]
    cvtps2pd xmm0, xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// === 截断转换函数 ===
function simd_cvttps_epi32(const a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]    // 加载 a
    cvttps2dq xmm0, xmm0
    {$ELSE}
    movups xmm0, [rdi]
    cvttps2dq xmm0, xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]    // a
    movups xmm0, [eax]
    cvttps2dq xmm0, xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cvttpd_epi32(const a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]    // 加载 a
    cvttpd2dq xmm0, xmm0
    {$ELSE}
    movupd xmm0, [rdi]
    cvttpd2dq xmm0, xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]    // a
    movupd xmm0, [eax]
    cvttpd2dq xmm0, xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// 重复的转换和 Cast 函数实现已删除，保留汇编版本

// === 新添加函数的占位实现 ===

function simd_loadl_epi64(const Ptr: Pointer): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
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
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    pxor xmm0, xmm0
    movq xmm0, [eax]
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

procedure simd_storel_epi64(var Dest; const Src: TM128); {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Dest �?rcx, Src �?rdx
    movq xmm0, [rdx]
    movq [rcx], xmm0
  {$ELSE}
    // Linux/macOS x64 System V ABI: Dest �?rdi, Src �?rsi
    movq xmm0, [rsi]
    movq [rdi], xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    mov edx, [esp + 8]    // Src
    movq xmm0, [edx]
    movq [eax], xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

procedure simd_maskmoveu_si128(const Src: TM128; const Mask: TM128; var Dest); {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Src �?rcx, Mask �?rdx, Dest �?r8
    movdqa xmm0, [rcx]
    movdqa xmm1, [rdx]
    push rdi
    mov rdi, r8
    maskmovdqu xmm0, xmm1
    pop rdi
    {$ELSE}
    // Linux/macOS x64 System V ABI: Src �?rdi, Mask �?rsi, Dest �?rdx
    push rdi              // 保存原始 rdi
    movdqa xmm0, [rdi]
    movdqa xmm1, [rsi]
    mov rdi, rdx
    maskmovdqu xmm0, xmm1
    pop rdi               // 恢复原始 rdi
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    mov edx, [esp + 8]    // Mask
    push edi
    mov edi, [esp + 16]
    movdqa xmm0, [eax]
    movdqa xmm1, [edx]
    maskmovdqu xmm0, xmm1 // 条件存储�?[edi]
    pop edi
    {$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_loadr_pd(const Ptr: Pointer): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: 第一个参数在 rcx
    movupd xmm0, [rcx]     // 加载两个双精度数
    shufpd xmm0, xmm0, 1   // 交换高低�?(01b = 1)
  {$ELSE}
    // Linux/macOS x64 System V ABI: 第一个参数在 rdi
    movupd xmm0, [rdi]     // 加载两个双精度数
    shufpd xmm0, xmm0, 1
    {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    movupd xmm0, [eax]
    shufpd xmm0, xmm0, 1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

procedure simd_storer_pd(var Dest; const Src: TM128); {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Dest �?rcx, Src �?rdx
    movapd xmm0, [rdx]
    shufpd xmm0, xmm0, 1
    movupd [rcx], xmm0
    {$ELSE}
    // Linux/macOS x64 System V ABI: Dest �?rdi, Src �?rsi
    movapd xmm0, [rsi]
    shufpd xmm0, xmm0, 1
    movupd [rdi], xmm0
    {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    mov edx, [esp + 8]     // Src
    movapd xmm0, [edx]
    shufpd xmm0, xmm0, 1
    movupd [eax], xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_loadh_pd(const A: TM128; const Ptr: Pointer): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: A �?rcx, Ptr �?rdx
    movapd xmm0, [rcx]     // 加载 A �?xmm0
    movhpd xmm0, [rdx]
    {$ELSE}
    // Linux/macOS x64 System V ABI: A �?rdi, Ptr �?rsi
    movapd xmm0, [rdi]     // 加载 A �?xmm0
    movhpd xmm0, [rsi]
    {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    mov edx, [esp + 8]     // Ptr
    movapd xmm0, [eax]
    movhpd xmm0, [edx]
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_loadl_pd(const A: TM128; const Ptr: Pointer): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: A �?rcx, Ptr �?rdx
    movapd xmm0, [rcx]     // 加载 A �?xmm0
    movlpd xmm0, [rdx]
    {$ELSE}
    // Linux/macOS x64 System V ABI: A �?rdi, Ptr �?rsi
    movapd xmm0, [rdi]     // 加载 A �?xmm0
    movlpd xmm0, [rsi]
    {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    mov edx, [esp + 8]     // Ptr
    movapd xmm0, [eax]
    movlpd xmm0, [edx]
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

procedure simd_storeh_pd(var Dest; const Src: TM128); {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Dest �?rcx, Src �?rdx
    movapd xmm0, [rdx]
    movhpd [rcx], xmm0
  {$ELSE}
    // Linux/macOS x64 System V ABI: Dest �?rdi, Src �?rsi
    movapd xmm0, [rsi]
    movhpd [rdi], xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    mov edx, [esp + 8]     // Src
    movapd xmm0, [edx]
    movhpd [eax], xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

procedure simd_storel_pd(var Dest; const Src: TM128); {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Dest �?rcx, Src �?rdx
    movapd xmm0, [rdx]
    movlpd [rcx], xmm0
  {$ELSE}
    // Linux/macOS x64 System V ABI: Dest �?rdi, Src �?rsi
    movapd xmm0, [rsi]
    movlpd [rdi], xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    mov edx, [esp + 8]     // Src
    movapd xmm0, [edx]
    movlpd [eax], xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_load_sd(const Ptr: Pointer): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: 第一个参数在 rcx
    movsd xmm0, [rcx]      // 加载标量双精度，高位自动清零
  {$ELSE}
    // Linux/macOS x64 System V ABI: 第一个参数在 rdi
    movsd xmm0, [rdi]      // 加载标量双精度，高位自动清零
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    movsd xmm0, [eax]
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

procedure simd_store_sd(var Dest; const Src: TM128); {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    // Windows x64: Dest �?rcx, Src �?rdx
    movapd xmm0, [rdx]
    movsd [rcx], xmm0
    {$ELSE}
    // Linux/macOS x64 System V ABI: Dest �?rdi, Src �?rsi
    movapd xmm0, [rsi]
    movsd [rdi], xmm0
    {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    mov edx, [esp + 8]     // Src
    movapd xmm0, [edx]
    movsd [eax], xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

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

function simd_adds_epu8(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    paddusb xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; paddusb xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; paddusb xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_adds_epu16(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    paddusw xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; paddusw xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; paddusw xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_subs_epu8(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    psubusb xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; psubusb xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; psubusb xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_subs_epu16(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    psubusw xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; psubusw xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; psubusw xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_mulhi_epi16(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    pmulhw xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pmulhw xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pmulhw xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_mulhi_epu16(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    pmulhuw xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pmulhuw xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pmulhuw xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_madd_epi16(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    pmaddwd xmm0, xmm1
  {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pmaddwd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pmaddwd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_avg_epu8(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    pavgb xmm0, xmm1
  {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pavgb xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pavgb xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_avg_epu16(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    pavgw xmm0, xmm1
  {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pavgw xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pavgw xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_sad_epu8(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    psadbw xmm0, xmm1
  {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; psadbw xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; psadbw xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_min_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
    minps xmm0, xmm1
    {$ELSE}
    movups xmm0, [rdi]; movups xmm1, [rsi]; minps xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movups xmm0, [eax]; movups xmm1, [edx]; minps xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_max_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
    maxps xmm0, xmm1
    {$ELSE}
    movups xmm0, [rdi]; movups xmm1, [rsi]; maxps xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movups xmm0, [eax]; movups xmm1, [edx]; maxps xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_min_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movupd xmm1, [rdx]
    minpd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; minpd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; minpd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_max_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movupd xmm1, [rdx]
    maxpd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; maxpd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; maxpd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_add_sd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movsd xmm1, [rdx]
    addsd xmm0, xmm1
  {$ELSE}
    movupd xmm0, [rdi]; movsd xmm1, [rsi]; addsd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movsd xmm1, [edx]; addsd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_sub_sd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movsd xmm1, [rdx]
    subsd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movsd xmm1, [rsi]; subsd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movsd xmm1, [edx]; subsd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_mul_sd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movsd xmm1, [rdx]
    mulsd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movsd xmm1, [rsi]; mulsd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movsd xmm1, [edx]; mulsd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_div_sd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movsd xmm1, [rdx]
    divsd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movsd xmm1, [rsi]; divsd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movsd xmm1, [edx]; divsd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_sqrt_sd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movsd xmm1, [rdx]
    sqrtsd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movsd xmm1, [rsi]; sqrtsd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movsd xmm1, [edx]; sqrtsd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_min_sd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movsd xmm1, [rdx]
    minsd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movsd xmm1, [rsi]; minsd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movsd xmm1, [edx]; minsd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_max_sd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movsd xmm1, [rdx]
    maxsd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movsd xmm1, [rsi]; maxsd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movsd xmm1, [edx]; maxsd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// === 双精度逻辑运算实现 ===
function simd_and_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movupd xmm1, [rdx]
    andpd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; andpd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; andpd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_or_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movupd xmm1, [rdx]
    orpd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; orpd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; orpd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_xor_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movupd xmm1, [rdx]
    xorpd xmm0, xmm1
  {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; xorpd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; xorpd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_andnot_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movupd xmm1, [rdx]
    andnpd xmm0, xmm1
  {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; andnpd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; andnpd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// 重复的比较函数实现已删除，保留汇编版�?
function simd_cmpord_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movupd xmm1, [rdx]
    cmpordpd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; cmpordpd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; cmpordpd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmpunord_pd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movupd xmm1, [rdx]
    cmpunordpd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movupd xmm1, [rsi]; cmpunordpd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movupd xmm1, [edx]; cmpunordpd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// === 标量双精度比较函数实�?===
function simd_cmpeq_sd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movsd xmm1, [rdx]
    cmpeqsd xmm0, xmm1
  {$ELSE}
    movupd xmm0, [rdi]; movsd xmm1, [rsi]; cmpeqsd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movsd xmm1, [edx]; cmpeqsd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmplt_sd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movsd xmm1, [rdx]
    cmpltsd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movsd xmm1, [rsi]; cmpltsd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movsd xmm1, [edx]; cmpltsd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmple_sd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movsd xmm1, [rdx]
    cmplesd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movsd xmm1, [rsi]; cmplesd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movsd xmm1, [edx]; cmplesd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmpgt_sd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movsd xmm1, [rdx]
    cmpnlesd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movsd xmm1, [rsi]; cmpnlesd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movsd xmm1, [edx]; cmpnlesd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmpge_sd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movsd xmm1, [rdx]
    cmpnltsd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movsd xmm1, [rsi]; cmpnltsd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movsd xmm1, [edx]; cmpnltsd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmpneq_sd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movsd xmm1, [rdx]
    cmpneqsd xmm0, xmm1
  {$ELSE}
    movupd xmm0, [rdi]; movsd xmm1, [rsi]; cmpneqsd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movsd xmm1, [edx]; cmpneqsd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmpnlt_sd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movsd xmm1, [rdx]
    cmpnltsd xmm0, xmm1
  {$ELSE}
    movupd xmm0, [rdi]; movsd xmm1, [rsi]; cmpnltsd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movsd xmm1, [edx]; cmpnltsd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmpnle_sd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movsd xmm1, [rdx]
    cmpnlesd xmm0, xmm1
  {$ELSE}
    movupd xmm0, [rdi]; movsd xmm1, [rsi]; cmpnlesd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movsd xmm1, [edx]; cmpnlesd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmpngt_sd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movsd xmm1, [rdx]
    cmpsd xmm0, xmm1, 2
  {$ELSE}
    movupd xmm0, [rdi]; movsd xmm1, [rsi]; cmpsd xmm0, xmm1, 2
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movsd xmm1, [edx]; cmpsd xmm0, xmm1, 2
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmpnge_sd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movsd xmm1, [rdx]
    cmpsd xmm0, xmm1, 1
  {$ELSE}
    movupd xmm0, [rdi]; movsd xmm1, [rsi]; cmpsd xmm0, xmm1, 1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movsd xmm1, [edx]; cmpsd xmm0, xmm1, 1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmpord_sd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movsd xmm1, [rdx]
    cmpordsd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movsd xmm1, [rsi]; cmpordsd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movsd xmm1, [edx]; cmpordsd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cmpunord_sd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movsd xmm1, [rdx]
    cmpunordsd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movsd xmm1, [rsi]; cmpunordsd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movsd xmm1, [edx]; cmpunordsd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// 有序比较返回整数
function simd_comieq_sd(const a, b: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movsd xmm0, [rcx]
    movsd xmm1, [rdx]
    comisd xmm0, xmm1
    sete al
    movzx eax, al
  {$ELSE}
    movsd xmm0, [rdi]; movsd xmm1, [rsi]; comisd xmm0, xmm1; sete al; movzx eax, al
  {$ENDIF}
{$ELSEIF CPUX86}
    mov edx, [esp + 4]; mov ecx, [esp + 8]; movsd xmm0, [edx]; movsd xmm1, [ecx]; comisd xmm0, xmm1; sete al; movzx eax, al
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_comilt_sd(const a, b: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movsd xmm0, [rcx]
    movsd xmm1, [rdx]
    comisd xmm0, xmm1
    setb al
    movzx eax, al
  {$ELSE}
    movsd xmm0, [rdi]; movsd xmm1, [rsi]; comisd xmm0, xmm1; setb al; movzx eax, al
  {$ENDIF}
{$ELSEIF CPUX86}
    mov edx, [esp + 4]; mov ecx, [esp + 8]; movsd xmm0, [edx]; movsd xmm1, [ecx]; comisd xmm0, xmm1; setb al; movzx eax, al
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_comile_sd(const a, b: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movsd xmm0, [rcx]
    movsd xmm1, [rdx]
    comisd xmm0, xmm1
    setbe al
    movzx eax, al
  {$ELSE}
    movsd xmm0, [rdi]; movsd xmm1, [rsi]; comisd xmm0, xmm1; setbe al; movzx eax, al
  {$ENDIF}
{$ELSEIF CPUX86}
    mov edx, [esp + 4]; mov ecx, [esp + 8]; movsd xmm0, [edx]; movsd xmm1, [ecx]; comisd xmm0, xmm1; setbe al; movzx eax, al
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_comigt_sd(const a, b: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movsd xmm0, [rcx]
    movsd xmm1, [rdx]
    comisd xmm0, xmm1
    seta al
    movzx eax, al
  {$ELSE}
    movsd xmm0, [rdi]; movsd xmm1, [rsi]; comisd xmm0, xmm1; seta al; movzx eax, al
  {$ENDIF}
{$ELSEIF CPUX86}
    mov edx, [esp + 4]; mov ecx, [esp + 8]; movsd xmm0, [edx]; movsd xmm1, [ecx]; comisd xmm0, xmm1; seta al; movzx eax, al
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_comige_sd(const a, b: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movsd xmm0, [rcx]
    movsd xmm1, [rdx]
    comisd xmm0, xmm1
    setae al
    movzx eax, al
  {$ELSE}
    movsd xmm0, [rdi]; movsd xmm1, [rsi]; comisd xmm0, xmm1; setae al; movzx eax, al
  {$ENDIF}
{$ELSEIF CPUX86}
    mov edx, [esp + 4]; mov ecx, [esp + 8]; movsd xmm0, [edx]; movsd xmm1, [ecx]; comisd xmm0, xmm1; setae al; movzx eax, al
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_comineq_sd(const a, b: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movsd xmm0, [rcx]
    movsd xmm1, [rdx]
    comisd xmm0, xmm1
    setne al
    movzx eax, al
    {$ELSE}
    movsd xmm0, [rdi]; movsd xmm1, [rsi]; comisd xmm0, xmm1; setne al; movzx eax, al
  {$ENDIF}
{$ELSEIF CPUX86}
    mov edx, [esp + 4]; mov ecx, [esp + 8]; movsd xmm0, [edx]; movsd xmm1, [ecx]; comisd xmm0, xmm1; setne al; movzx eax, al
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// 无序比较返回整数
function simd_ucomieq_sd(const a, b: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movsd xmm0, [rcx]
    movsd xmm1, [rdx]
    ucomisd xmm0, xmm1
    sete al
    movzx eax, al
  {$ELSE}
    movsd xmm0, [rdi]; movsd xmm1, [rsi]; ucomisd xmm0, xmm1; sete al; movzx eax, al
  {$ENDIF}
{$ELSEIF CPUX86}
    mov edx, [esp + 4]; mov ecx, [esp + 8]; movsd xmm0, [edx]; movsd xmm1, [ecx]; ucomisd xmm0, xmm1; sete al; movzx eax, al
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_ucomilt_sd(const a, b: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movsd xmm0, [rcx]
    movsd xmm1, [rdx]
    ucomisd xmm0, xmm1
    setb al
    movzx eax, al
  {$ELSE}
    movsd xmm0, [rdi]; movsd xmm1, [rsi]; ucomisd xmm0, xmm1; setb al; movzx eax, al
  {$ENDIF}
{$ELSEIF CPUX86}
    mov edx, [esp + 4]; mov ecx, [esp + 8]; movsd xmm0, [edx]; movsd xmm1, [ecx]; ucomisd xmm0, xmm1; setb al; movzx eax, al
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_ucomile_sd(const a, b: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movsd xmm0, [rcx]
    movsd xmm1, [rdx]
    ucomisd xmm0, xmm1
    setbe al
    movzx eax, al
  {$ELSE}
    movsd xmm0, [rdi]; movsd xmm1, [rsi]; ucomisd xmm0, xmm1; setbe al; movzx eax, al
  {$ENDIF}
{$ELSEIF CPUX86}
    mov edx, [esp + 4]; mov ecx, [esp + 8]; movsd xmm0, [edx]; movsd xmm1, [ecx]; ucomisd xmm0, xmm1; setbe al; movzx eax, al
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_ucomigt_sd(const a, b: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movsd xmm0, [rcx]
    movsd xmm1, [rdx]
    ucomisd xmm0, xmm1
    seta al
    movzx eax, al
  {$ELSE}
    movsd xmm0, [rdi]; movsd xmm1, [rsi]; ucomisd xmm0, xmm1; seta al; movzx eax, al
  {$ENDIF}
{$ELSEIF CPUX86}
    mov edx, [esp + 4]; mov ecx, [esp + 8]; movsd xmm0, [edx]; movsd xmm1, [ecx]; ucomisd xmm0, xmm1; seta al; movzx eax, al
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_ucomige_sd(const a, b: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movsd xmm0, [rcx]
    movsd xmm1, [rdx]
    ucomisd xmm0, xmm1
    setae al
    movzx eax, al
  {$ELSE}
    movsd xmm0, [rdi]; movsd xmm1, [rsi]; ucomisd xmm0, xmm1; setae al; movzx eax, al
  {$ENDIF}
{$ELSEIF CPUX86}
    mov edx, [esp + 4]; mov ecx, [esp + 8]; movsd xmm0, [edx]; movsd xmm1, [ecx]; ucomisd xmm0, xmm1; setae al; movzx eax, al
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_ucomineq_sd(const a, b: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movsd xmm0, [rcx]
    movsd xmm1, [rdx]
    ucomisd xmm0, xmm1
    setne al
    movzx eax, al
    {$ELSE}
    movsd xmm0, [rdi]; movsd xmm1, [rsi]; ucomisd xmm0, xmm1; setne al; movzx eax, al
  {$ENDIF}
{$ELSEIF CPUX86}
    mov edx, [esp + 4]; mov ecx, [esp + 8]; movsd xmm0, [edx]; movsd xmm1, [ecx]; ucomisd xmm0, xmm1; setne al; movzx eax, al
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// === 🔟 Pack / Insert / Extract / Move 实现 ===
function simd_packs_epi16(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    packsswb xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; packsswb xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; packsswb xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_packs_epi32(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    packssdw xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; packssdw xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; packssdw xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_packus_epi16(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    packuswb xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; packuswb xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; packuswb xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_insert_epi16(const a: TM128; Value: Integer; imm8: Byte): TM128;
var
  LIndex: Byte;
begin
  Result := a;
  LIndex := imm8 and 7;
  Result.m128i_i16[LIndex] := SmallInt(Value);
end;

function simd_extract_epi16(const a: TM128; imm8: Byte): Integer;
var
  LIndex: Byte;
begin
  LIndex := imm8 and 7;
  Result := a.m128i_u16[LIndex];
end;

function simd_move_sd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]    // 加载 a
    movsd xmm1, [rdx]
    movsd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]
    movsd xmm1, [rsi]
    movsd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]    // a
    mov edx, [esp + 8]    // b
    movupd xmm0, [eax]
    movsd xmm1, [edx]
    movsd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_move_epi64(const a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]    // 加载 a
    movq xmm0, xmm0       // 移动64位，高位清零
  {$ELSE}
    movdqu xmm0, [rdi]
    movq xmm0, xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]    // a
    movdqu xmm0, [eax]
    movq xmm0, xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_movemask_epi8(const a: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]    // 加载 a
    pmovmskb eax, xmm0    // 提取8位符号位掩码
  {$ELSE}
    movdqu xmm0, [rdi]
    pmovmskb eax, xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov edx, [esp + 4]    // a
    movdqu xmm0, [edx]
    pmovmskb eax, xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_movemask_pd(const a: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]    // 加载 a
    movmskpd eax, xmm0    // 提取双精度符号位掩码
  {$ELSE}
    movupd xmm0, [rdi]
    movmskpd eax, xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov edx, [esp + 4]    // a
    movupd xmm0, [edx]
    movmskpd eax, xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_movemask_ps(const a: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]    // 加载 a
    movmskps eax, xmm0    // 提取单精度符号位掩码
  {$ELSE}
    movups xmm0, [rdi]
    movmskps eax, xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov edx, [esp + 4]    // a
    movups xmm0, [edx]
    movmskps eax, xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

// === Cast 函数实现（无转换，仅重新解释�?===
function simd_castpd_si128(const a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]    // 直接复制，无转换
  {$ELSE}
    movupd xmm0, [rdi]
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    movupd xmm0, [eax]
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_castsi128_pd(const a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]    // 直接复制，无转换
  {$ELSE}
    movdqu xmm0, [rdi]
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    movdqu xmm0, [eax]
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_castps_si128(const a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]    // 直接复制，无转换
  {$ELSE}
    movups xmm0, [rdi]
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    movups xmm0, [eax]
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_castsi128_ps(const a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]    // 直接复制，无转换
  {$ELSE}
    movdqu xmm0, [rdi]
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    movdqu xmm0, [eax]
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_castpd_ps(const a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]    // 直接复制，无转换
  {$ELSE}
    movupd xmm0, [rdi]
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    movupd xmm0, [eax]
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_castps_pd(const a: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]    // 直接复制，无转换
  {$ELSE}
    movups xmm0, [rdi]
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]
    movups xmm0, [eax]
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_unpacklo_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
    unpcklps xmm0, xmm1
    {$ELSE}
    movups xmm0, [rdi]; movups xmm1, [rsi]; unpcklps xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movups xmm0, [eax]; movups xmm1, [edx]; unpcklps xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_unpackhi_ps(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rcx]
    movups xmm1, [rdx]
    unpckhps xmm0, xmm1
    {$ELSE}
    movups xmm0, [rdi]; movups xmm1, [rsi]; unpckhps xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movups xmm0, [eax]; movups xmm1, [edx]; unpckhps xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cvtsd_ss(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movsd xmm1, [rdx]
    cvtsd2ss xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movsd xmm1, [rsi]; cvtsd2ss xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movsd xmm1, [edx]; cvtsd2ss xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cvtss_sd(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rcx]
    movss xmm1, [rdx]
    cvtss2sd xmm0, xmm1
    {$ELSE}
    movupd xmm0, [rdi]; movss xmm1, [rsi]; cvtss2sd xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movupd xmm0, [eax]; movss xmm1, [edx]; cvtss2sd xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cvttpd_ps(const a: TM128): TM128;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.m128_f32[0] := Single(Trunc(a.m128d_f64[0]));
  Result.m128_f32[1] := Single(Trunc(a.m128d_f64[1]));
end;

function simd_srai_si128(const a: TM128; imm8: Byte): TM128;
var
  LIndex: Integer;
  LShift: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  LShift := imm8;
  if LShift > 15 then
    Exit;
  for LIndex := 0 to 15 - LShift do
    Result.m128i_u8[LIndex] := a.m128i_u8[LIndex + LShift];
end;

function simd_max_epu8(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    pmaxub xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pmaxub xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pmaxub xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_min_epu8(const a, b: TM128): TM128; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rcx]
    movdqu xmm1, [rdx]
    pminub xmm0, xmm1
    {$ELSE}
    movdqu xmm0, [rdi]; movdqu xmm1, [rsi]; pminub xmm0, xmm1
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]; mov edx, [esp + 8]; movdqu xmm0, [eax]; movdqu xmm1, [edx]; pminub xmm0, xmm1
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cvtsd_si32(const a: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movsd xmm0, [rcx]
    cvtsd2si eax, xmm0
    {$ELSE}
    movsd xmm0, [rdi]; cvtsd2si eax, xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov edx, [esp + 4]; movsd xmm0, [edx]; cvtsd2si eax, xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cvtsd_si64(const a: TM128): Int64; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movsd xmm0, [rcx]
    cvtsd2si rax, xmm0
    {$ELSE}
    movsd xmm0, [rdi]; cvtsd2si rax, xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov edx, [esp + 4]; movsd xmm0, [edx]; cvtsd2si eax, xmm0; mov [esp + 8], eax; xor eax, eax; mov [esp + 12], eax
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cvttsd_si32(const a: TM128): Integer; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movsd xmm0, [rcx]
    cvttsd2si eax, xmm0
    {$ELSE}
    movsd xmm0, [rdi]; cvttsd2si eax, xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov edx, [esp + 4]; movsd xmm0, [edx]; cvttsd2si eax, xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cvttsd_si64(const a: TM128): Int64; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movsd xmm0, [rcx]
    cvttsd2si rax, xmm0
    {$ELSE}
    movsd xmm0, [rdi]; cvttsd2si rax, xmm0
  {$ENDIF}
{$ELSEIF CPUX86}
    mov edx, [esp + 4]; movsd xmm0, [edx]; cvttsd2si eax, xmm0; mov [esp + 8], eax; xor eax, eax; mov [esp + 12], eax
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

function simd_cvtsi32_sd(const a: TM128; b: Integer): TM128;
begin
  Result := a;
  Result.m128d_f64[0] := b;
end;

function simd_cvtsi64_sd(const a: TM128; b: Int64): TM128;
begin
  Result := a;
  Result.m128d_f64[0] := b;
end;

// === 1️⃣1️⃣ Cache Control / Stream / Fence 实现 ===
procedure simd_clflush(const Ptr: Pointer); {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    clflush [rcx]
    {$ELSE}
    clflush [rdi]         // Linux/macOS x64
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]    // Ptr
    clflush [eax]
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

procedure simd_lfence; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
    lfence                // 加载栅栏
end;

procedure simd_mfence; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
    mfence                // 内存栅栏
end;

procedure simd_pause; {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
    pause                 // 暂停指令（自旋循环提示）
end;

procedure simd_stream_pd(var Dest; const Src: TM128); {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movupd xmm0, [rdx]    // 加载 Src
    movntpd [rcx], xmm0   // 非临时存储双精度
  {$ELSE}
    movupd xmm0, [rsi]    // 加载 Src
    movntpd [rdi], xmm0   // 非临时存储双精度
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]    // Dest
    mov edx, [esp + 8]    // Src
    movupd xmm0, [edx]
    movntpd [eax], xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

procedure simd_stream_ps(var Dest; const Src: TM128); {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movups xmm0, [rdx]    // 加载 Src
    movntps [rcx], xmm0   // 非临时存储单精度
  {$ELSE}
    movups xmm0, [rsi]    // 加载 Src
    movntps [rdi], xmm0   // 非临时存储单精度
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]    // Dest
    mov edx, [esp + 8]    // Src
    movups xmm0, [edx]
    movntps [eax], xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

procedure simd_stream_si128(var Dest; const Src: TM128); {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movdqu xmm0, [rdx]    // 加载 Src
    movntdq [rcx], xmm0
    {$ELSE}
    movdqu xmm0, [rsi]    // 加载 Src
    movntdq [rdi], xmm0
    {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]    // Dest
    mov edx, [esp + 8]    // Src
    movdqu xmm0, [edx]
    movntdq [eax], xmm0
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

procedure simd_stream_si32(var Dest; Value: Integer); {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movnti [rcx], edx
    {$ELSE}
    movnti [rdi], esi     // Linux/macOS x64
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]    // Dest
    mov edx, [esp + 8]    // Value
    movnti [eax], edx
{$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

procedure simd_stream_si64(var Dest; Value: Int64); {$IFDEF FPC}assembler; nostackframe;{$ENDIF}
asm
{$IFDEF CPUX86_64}
  {$IFDEF WINDOWS}
    movnti [rcx], rdx
    {$ELSE}
    movnti [rdi], rsi     // Linux/macOS x64
  {$ENDIF}
{$ELSEIF CPUX86}
    mov eax, [esp + 4]    // Dest
    mov edx, [esp + 8]
    mov ecx, [esp + 12]
    movnti [eax], edx
    movnti [eax + 4], ecx
    {$ELSE}
    {$ERROR Unsupported CPU}
{$ENDIF}
end;

end.


