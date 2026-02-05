unit fafafa.core.simd;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch,
  fafafa.core.simd.cpuinfo,
  fafafa.core.simd.cpuinfo.base,
  fafafa.core.simd.memutils,
  fafafa.core.simd.utils      // ✅ Shuffle, Blend, Convert operations
  {$IFDEF CPUX86_64}  // x86-64 SIMD backends use 64-bit assembly
  , fafafa.core.simd.sse2
  , fafafa.core.simd.sse3      // ✅ SSE3: horizontal ops (HADDPS, HSUBPS)
  , fafafa.core.simd.ssse3     // ✅ SSSE3: byte shuffle (PSHUFB), integer abs (PABS)
  , fafafa.core.simd.sse41     // ✅ SSE4.1: dot product (DPPS), rounding, PMULLD
  , fafafa.core.simd.sse42     // ✅ SSE4.2: CRC32, string ops, PCMPGTQ
  , fafafa.core.simd.avx2
    {$IFDEF SIMD_BACKEND_AVX512}
  , fafafa.core.simd.avx512
    {$ENDIF}
  {$ENDIF}
  {$IFDEF CPUI386}  // i386 SSE2 backend uses 32-bit assembly
  , fafafa.core.simd.sse2.i386
  {$ENDIF}
  {$IFDEF SIMD_ARM_AVAILABLE}
  , fafafa.core.simd.neon
  {$ENDIF}
  {$IFDEF SIMD_RISCV_AVAILABLE}
  , fafafa.core.simd.riscvv
  {$ENDIF}
  ;

{**
  @abstract(Modern SIMD Framework for FreePascal)
  
  This is the main user interface for the SIMD framework, providing:
  @unorderedlist(
    @item(High-level vector types with type safety)
    @item(Automatic backend selection (Scalar/SSE2/AVX2/AVX-512/NEON))
    @item(Zero-overhead dispatch via function pointer tables)
    @item(Rust portable-simd compatible naming conventions)
  )
  
  @bold(Quick Start:)
  @longcode(#
  uses fafafa.core.simd;
  var a, b, c: TVecF32x4;
  begin
    a := VecF32x4Splat(1.5);
    b := VecF32x4Splat(2.0);
    c := VecF32x4Add(a, b);  // SIMD accelerated
  end;
  #)
  
  @seealso(fafafa.core.simd.dispatch)
  @seealso(fafafa.core.simd.base)
*}

// === Re-export Core Types ===
type
  // Vector types (re-exported from types unit)
  TVecF32x4 = fafafa.core.simd.base.TVecF32x4;
  TVecF32x8 = fafafa.core.simd.base.TVecF32x8;
  TVecF64x2 = fafafa.core.simd.base.TVecF64x2;
  TVecF64x4 = fafafa.core.simd.base.TVecF64x4;
  TVecI32x4 = fafafa.core.simd.base.TVecI32x4;
  TVecI32x8 = fafafa.core.simd.base.TVecI32x8;
  TVecI64x2 = fafafa.core.simd.base.TVecI64x2;
  TVecI16x8 = fafafa.core.simd.base.TVecI16x8;
  TVecI8x16 = fafafa.core.simd.base.TVecI8x16;
  TVecU32x4 = fafafa.core.simd.base.TVecU32x4;
  TVecU64x2 = fafafa.core.simd.base.TVecU64x2;
  TVecU16x8 = fafafa.core.simd.base.TVecU16x8;
  TVecU8x16 = fafafa.core.simd.base.TVecU8x16;
  TVecU32x8 = fafafa.core.simd.base.TVecU32x8;
  TVecU64x4 = fafafa.core.simd.base.TVecU64x4;  // ✅ NEW: 用于 SelectF64x4
  TVecI64x4 = fafafa.core.simd.base.TVecI64x4;  // ✅ Task 5.2: 256-bit signed 64-bit integer vector
  TVecF32x16 = fafafa.core.simd.base.TVecF32x16;
  TVecF64x8 = fafafa.core.simd.base.TVecF64x8;
  TVecI32x16 = fafafa.core.simd.base.TVecI32x16;
  
  // Mask types
  TMask2 = fafafa.core.simd.base.TMask2;
  TMask4 = fafafa.core.simd.base.TMask4;
  TMask8 = fafafa.core.simd.base.TMask8;
  TMask16 = fafafa.core.simd.base.TMask16;
  TMask32 = fafafa.core.simd.base.TMask32;
  
  // Backend types
  TSimdBackend = fafafa.core.simd.base.TSimdBackend;
  TSimdBackendInfo = fafafa.core.simd.base.TSimdBackendInfo;
  TCPUInfo = fafafa.core.simd.cpuinfo.base.TCPUInfo;
  TSimdBackendArray = fafafa.core.simd.cpuinfo.TSimdBackendArray;

  // === Rust-Style Short Aliases (portable-simd compatible naming) ===
  // 128-bit float vectors
  f32x4 = TVecF32x4;   // Rust: Simd<f32, 4>
  f64x2 = TVecF64x2;   // Rust: Simd<f64, 2>
  
  // 128-bit signed integer vectors
  i8x16  = TVecI8x16;   // Rust: Simd<i8, 16>
  i16x8  = TVecI16x8;   // Rust: Simd<i16, 8>
  i32x4  = TVecI32x4;   // Rust: Simd<i32, 4>
  i64x2  = TVecI64x2;   // Rust: Simd<i64, 2>
  
  // 128-bit unsigned integer vectors
  u8x16  = TVecU8x16;   // Rust: Simd<u8, 16>
  u16x8  = TVecU16x8;   // Rust: Simd<u16, 8>
  u32x4  = TVecU32x4;   // Rust: Simd<u32, 4>
  u64x2  = TVecU64x2;   // Rust: Simd<u64, 2>
  
  // 256-bit vectors (AVX)
  f32x8  = TVecF32x8;   // Rust: Simd<f32, 8>
  f64x4  = TVecF64x4;   // Rust: Simd<f64, 4>
  i32x8  = TVecI32x8;   // Rust: Simd<i32, 8>
  i64x4  = TVecI64x4;   // Rust: Simd<i64, 4> - ✅ Task 5.2
  u32x8  = TVecU32x8;   // Rust: Simd<u32, 8>
  u64x4  = TVecU64x4;   // Rust: Simd<u64, 4> - ✅ Task 5.2
  
  // 512-bit vectors (AVX-512)
  f32x16 = TVecF32x16;  // Rust: Simd<f32, 16>
  f64x8  = TVecF64x8;   // Rust: Simd<f64, 8>
  i32x16 = TVecI32x16;  // Rust: Simd<i32, 16>

// === High-Level Vector Operations ===

{** @abstract(F32x4 Arithmetic Operations - 4x Single-precision floats) *}

{**
  Element-wise addition of two 4-element float vectors.
  @param(a First operand vector)
  @param(b Second operand vector)
  @returns(Result vector where result[i] = a[i] + b[i])
*}
function VecF32x4Add(const a, b: TVecF32x4): TVecF32x4; inline;

{** Element-wise subtraction. @returns(result[i] = a[i] - b[i]) *}
function VecF32x4Sub(const a, b: TVecF32x4): TVecF32x4; inline;

{** Element-wise multiplication. @returns(result[i] = a[i] * b[i]) *}
function VecF32x4Mul(const a, b: TVecF32x4): TVecF32x4; inline;

{** Element-wise division. @returns(result[i] = a[i] / b[i]) *}
function VecF32x4Div(const a, b: TVecF32x4): TVecF32x4; inline;

{** @abstract(F32x4 Comparison Operations)
  Returns TMask4 where bit i is set if condition holds for element i. *}

{** Equal comparison. @returns(mask[i] = (a[i] == b[i])) *}
function VecF32x4CmpEq(const a, b: TVecF32x4): TMask4; inline;

{** Less-than comparison. @returns(mask[i] = (a[i] < b[i])) *}
function VecF32x4CmpLt(const a, b: TVecF32x4): TMask4; inline;

{** Less-or-equal comparison. @returns(mask[i] = (a[i] <= b[i])) *}
function VecF32x4CmpLe(const a, b: TVecF32x4): TMask4; inline;

{** Greater-than comparison. @returns(mask[i] = (a[i] > b[i])) *}
function VecF32x4CmpGt(const a, b: TVecF32x4): TMask4; inline;

{** Greater-or-equal comparison. @returns(mask[i] = (a[i] >= b[i])) *}
function VecF32x4CmpGe(const a, b: TVecF32x4): TMask4; inline;

{** Not-equal comparison. @returns(mask[i] = (a[i] != b[i])) *}
function VecF32x4CmpNe(const a, b: TVecF32x4): TMask4; inline;

{** @abstract(F32x4 Math Functions) *}

{** Element-wise absolute value. @returns(result[i] = |a[i]|) *}
function VecF32x4Abs(const a: TVecF32x4): TVecF32x4; inline;

{** Element-wise square root. @returns(result[i] = sqrt(a[i])) *}
function VecF32x4Sqrt(const a: TVecF32x4): TVecF32x4; inline;

{** Element-wise minimum. @returns(result[i] = min(a[i], b[i])) *}
function VecF32x4Min(const a, b: TVecF32x4): TVecF32x4; inline;

{** Element-wise maximum. @returns(result[i] = max(a[i], b[i])) *}
function VecF32x4Max(const a, b: TVecF32x4): TVecF32x4; inline;

{** @abstract(F32x4 Extended Math Functions) *}

{**
  Fused multiply-add: a*b + c.
  Uses FMA instruction if available, otherwise emulated.
  @returns(result[i] = a[i] * b[i] + c[i])
*}
function VecF32x4Fma(const a, b, c: TVecF32x4): TVecF32x4; inline;

{** Approximate reciprocal (12-bit precision). @returns(result[i] ≈ 1/a[i]) *}
function VecF32x4Rcp(const a: TVecF32x4): TVecF32x4; inline;

{** Approximate reciprocal square root (12-bit precision). @returns(result[i] ≈ 1/sqrt(a[i])) *}
function VecF32x4Rsqrt(const a: TVecF32x4): TVecF32x4; inline;

{** Floor (round toward -∞). @returns(result[i] = floor(a[i])) *}
function VecF32x4Floor(const a: TVecF32x4): TVecF32x4; inline;

{** Ceiling (round toward +∞). @returns(result[i] = ceil(a[i])) *}
function VecF32x4Ceil(const a: TVecF32x4): TVecF32x4; inline;

{** Round to nearest integer. @returns(result[i] = round(a[i])) *}
function VecF32x4Round(const a: TVecF32x4): TVecF32x4; inline;

{** Truncate toward zero. @returns(result[i] = trunc(a[i])) *}
function VecF32x4Trunc(const a: TVecF32x4): TVecF32x4; inline;

{** Clamp to range. @returns(result[i] = clamp(a[i], minVal[i], maxVal[i])) *}
function VecF32x4Clamp(const a, minVal, maxVal: TVecF32x4): TVecF32x4; inline;

{** @abstract(3D/4D Vector Math - Geometry operations) *}

{** 4-element dot product. @returns(a[0]*b[0] + a[1]*b[1] + a[2]*b[2] + a[3]*b[3]) *}
function VecF32x4Dot(const a, b: TVecF32x4): Single; inline;

{** 3-element dot product (ignores w). @returns(a.x*b.x + a.y*b.y + a.z*b.z) *}
function VecF32x3Dot(const a, b: TVecF32x4): Single; inline;

{** 3D cross product. @returns([a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x, 0]) *}
function VecF32x3Cross(const a, b: TVecF32x4): TVecF32x4; inline;

{** 4-element vector length. @returns(sqrt(dot(a, a))) *}
function VecF32x4Length(const a: TVecF32x4): Single; inline;

{** 3-element vector length (ignores w). @returns(sqrt(x² + y² + z²)) *}
function VecF32x3Length(const a: TVecF32x4): Single; inline;

{** Normalize 4-element vector. @returns(a / length(a)) *}
function VecF32x4Normalize(const a: TVecF32x4): TVecF32x4; inline;

{** Normalize 3-element vector (w=0). @returns([x,y,z,0] / length([x,y,z])) *}
function VecF32x3Normalize(const a: TVecF32x4): TVecF32x4; inline;

{** @abstract(✅ Iteration 6.4: FMA-optimized Dot Product Functions) *}

{** 8-element dot product (256-bit). @returns(sum of a[i]*b[i] for i=0..7) *}
function VecF32x8Dot(const a, b: TVecF32x8): Single; inline;

{** 2-element double-precision dot product. @returns(a[0]*b[0] + a[1]*b[1]) *}
function VecF64x2Dot(const a, b: TVecF64x2): Double; inline;

{** 4-element double-precision dot product (256-bit). @returns(sum of a[i]*b[i] for i=0..3) *}
function VecF64x4Dot(const a, b: TVecF64x4): Double; inline;

{** @abstract(F32x4 Reduction/Horizontal Operations) *}

{** Horizontal sum of all elements. @returns(a[0] + a[1] + a[2] + a[3]) *}
function VecF32x4ReduceAdd(const a: TVecF32x4): Single; inline;

{** Minimum of all elements. @returns(min(a[0], a[1], a[2], a[3])) *}
function VecF32x4ReduceMin(const a: TVecF32x4): Single; inline;

{** Maximum of all elements. @returns(max(a[0], a[1], a[2], a[3])) *}
function VecF32x4ReduceMax(const a: TVecF32x4): Single; inline;

{** Product of all elements. @returns(a[0] * a[1] * a[2] * a[3]) *}
function VecF32x4ReduceMul(const a: TVecF32x4): Single; inline;

{** @abstract(F32x4 Memory Operations) *}

{** Load 4 floats from memory (unaligned). @param(p Pointer to 4 consecutive floats) *}
function VecF32x4Load(p: PSingle): TVecF32x4; inline;

{** Load 4 floats from 16-byte aligned memory (faster). @param(p Must be 16-byte aligned) *}
function VecF32x4LoadAligned(p: PSingle): TVecF32x4; inline;

{** Store 4 floats to memory (unaligned). *}
procedure VecF32x4Store(p: PSingle; const a: TVecF32x4); inline;

{** Store 4 floats to 16-byte aligned memory (faster). @param(p Must be 16-byte aligned) *}
procedure VecF32x4StoreAligned(p: PSingle; const a: TVecF32x4); inline;

{** @abstract(F32x4 Utility Operations) *}

{** Broadcast scalar to all lanes. @returns([value, value, value, value]) *}
function VecF32x4Splat(value: Single): TVecF32x4; inline;

{** Create zero vector. @returns([0, 0, 0, 0]) *}
function VecF32x4Zero: TVecF32x4; inline;

{**
  Select elements based on mask.
  @param(mask Bit mask where bit i selects source for element i)
  @returns(result[i] = mask[i] ? a[i] : b[i])
*}
function VecF32x4Select(const mask: TMask4; const a, b: TVecF32x4): TVecF32x4; inline;

{** Extract single element. @param(index Lane index 0-3) *}
function VecF32x4Extract(const a: TVecF32x4; index: Integer): Single; inline;

{** Insert value at index. @returns(Vector with a[index] replaced by value) *}
function VecF32x4Insert(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4; inline;

// === ✅ Task 5.3: Extract/Insert Lane Operations ===
// These functions provide element-level access to SIMD vectors.
// Extract retrieves a single lane value; Insert creates a new vector with one lane modified.
// Index bounds are clamped to valid range (saturation strategy).

// F64x2 (128-bit, lanes 0-1)
{** Extract single element. @param(index Lane index 0-1) *}
function VecF64x2Extract(const a: TVecF64x2; index: Integer): Double; inline;
{** Insert value at index. @returns(Vector with a[index] replaced by value) *}
function VecF64x2Insert(const a: TVecF64x2; value: Double; index: Integer): TVecF64x2; inline;

// I32x4 (128-bit, lanes 0-3)
{** Extract single element. @param(index Lane index 0-3) *}
function VecI32x4Extract(const a: TVecI32x4; index: Integer): Int32; inline;
{** Insert value at index. @returns(Vector with a[index] replaced by value) *}
function VecI32x4Insert(const a: TVecI32x4; value: Int32; index: Integer): TVecI32x4; inline;

// I64x2 (128-bit, lanes 0-1)
{** Extract single element. @param(index Lane index 0-1) *}
function VecI64x2Extract(const a: TVecI64x2; index: Integer): Int64; inline;
{** Insert value at index. @returns(Vector with a[index] replaced by value) *}
function VecI64x2Insert(const a: TVecI64x2; value: Int64; index: Integer): TVecI64x2; inline;

// F32x8 (256-bit, lanes 0-7)
{** Extract single element. @param(index Lane index 0-7) *}
function VecF32x8Extract(const a: TVecF32x8; index: Integer): Single; inline;
{** Insert value at index. @returns(Vector with a[index] replaced by value) *}
function VecF32x8Insert(const a: TVecF32x8; value: Single; index: Integer): TVecF32x8; inline;

// F64x4 (256-bit, lanes 0-3)
{** Extract single element. @param(index Lane index 0-3) *}
function VecF64x4Extract(const a: TVecF64x4; index: Integer): Double; inline;
{** Insert value at index. @returns(Vector with a[index] replaced by value) *}
function VecF64x4Insert(const a: TVecF64x4; value: Double; index: Integer): TVecF64x4; inline;

// I32x8 (256-bit, lanes 0-7)
{** Extract single element. @param(index Lane index 0-7) *}
function VecI32x8Extract(const a: TVecI32x8; index: Integer): Int32; inline;
{** Insert value at index. @returns(Vector with a[index] replaced by value) *}
function VecI32x8Insert(const a: TVecI32x8; value: Int32; index: Integer): TVecI32x8; inline;

// I64x4 (256-bit, lanes 0-3)
{** Extract single element. @param(index Lane index 0-3) *}
function VecI64x4Extract(const a: TVecI64x4; index: Integer): Int64; inline;
{** Insert value at index. @returns(Vector with a[index] replaced by value) *}
function VecI64x4Insert(const a: TVecI64x4; value: Int64; index: Integer): TVecI64x4; inline;

// F32x16 (512-bit, lanes 0-15)
{** Extract single element. @param(index Lane index 0-15) *}
function VecF32x16Extract(const a: TVecF32x16; index: Integer): Single; inline;
{** Insert value at index. @returns(Vector with a[index] replaced by value) *}
function VecF32x16Insert(const a: TVecF32x16; value: Single; index: Integer): TVecF32x16; inline;

// I32x16 (512-bit, lanes 0-15)
{** Extract single element. @param(index Lane index 0-15) *}
function VecI32x16Extract(const a: TVecI32x16; index: Integer): Int32; inline;
{** Insert value at index. @returns(Vector with a[index] replaced by value) *}
function VecI32x16Insert(const a: TVecI32x16; value: Int32; index: Integer): TVecI32x16; inline;

// === F64x2 Operations (128-bit Double) ===
// ✅ P0.3: 添加缺失的 F64x2 高级 API

// F64x2 arithmetic
function VecF64x2Add(const a, b: TVecF64x2): TVecF64x2; inline;
function VecF64x2Sub(const a, b: TVecF64x2): TVecF64x2; inline;
function VecF64x2Mul(const a, b: TVecF64x2): TVecF64x2; inline;
function VecF64x2Div(const a, b: TVecF64x2): TVecF64x2; inline;

// F64x2 comparison
function VecF64x2CmpEq(const a, b: TVecF64x2): TMask2; inline;
function VecF64x2CmpLt(const a, b: TVecF64x2): TMask2; inline;
function VecF64x2CmpLe(const a, b: TVecF64x2): TMask2; inline;
function VecF64x2CmpGt(const a, b: TVecF64x2): TMask2; inline;
function VecF64x2CmpGe(const a, b: TVecF64x2): TMask2; inline;
function VecF64x2CmpNe(const a, b: TVecF64x2): TMask2; inline;

// F64x2 math functions
function VecF64x2Abs(const a: TVecF64x2): TVecF64x2; inline;
function VecF64x2Sqrt(const a: TVecF64x2): TVecF64x2; inline;
function VecF64x2Min(const a, b: TVecF64x2): TVecF64x2; inline;
function VecF64x2Max(const a, b: TVecF64x2): TVecF64x2; inline;

// F64x2 extended math functions
{** Fused multiply-add: result = a * b + c (single rounding) *}
function VecF64x2Fma(const a, b, c: TVecF64x2): TVecF64x2; inline;

// F64x2 rounding functions
{** Floor: round towards negative infinity *}
function VecF64x2Floor(const a: TVecF64x2): TVecF64x2; inline;
{** Ceil: round towards positive infinity *}
function VecF64x2Ceil(const a: TVecF64x2): TVecF64x2; inline;
{** Round: round to nearest integer (banker's rounding) *}
function VecF64x2Round(const a: TVecF64x2): TVecF64x2; inline;
{** Trunc: round towards zero *}
function VecF64x2Trunc(const a: TVecF64x2): TVecF64x2; inline;

// F64x2 reduction
function VecF64x2ReduceAdd(const a: TVecF64x2): Double; inline;
function VecF64x2ReduceMin(const a: TVecF64x2): Double; inline;
function VecF64x2ReduceMax(const a: TVecF64x2): Double; inline;
function VecF64x2ReduceMul(const a: TVecF64x2): Double; inline;

// ✅ P2-3: F64x2 memory operations
function VecF64x2Load(p: PDouble): TVecF64x2; inline;
procedure VecF64x2Store(p: PDouble; const a: TVecF64x2); inline;

// ✅ P2-3: F64x2 utility operations
function VecF64x2Splat(value: Double): TVecF64x2; inline;
function VecF64x2Zero: TVecF64x2; inline;
function VecF64x2Select(const mask: TMask2; const a, b: TVecF64x2): TVecF64x2; inline;

// ✅ NEW: 缺失的 Select 操作 (条件选择: mask[i] != 0 ? a[i] : b[i])
{** 根据向量掩码选择元素。掩码元素非零时选择 a，否则选择 b *}
function VecI32x4Select(const mask: TVecI32x4; const a, b: TVecI32x4): TVecI32x4; inline;
{** 根据向量掩码选择元素（256-bit）。掩码元素最高位为 1 时选择 a *}
function VecF32x8Select(const mask: TVecU32x8; const a, b: TVecF32x8): TVecF32x8; inline;
{** 根据向量掩码选择元素（256-bit）。掩码元素最高位为 1 时选择 a *}
function VecF64x4Select(const mask: TVecU64x4; const a, b: TVecF64x4): TVecF64x4; inline;

// ✅ P2-2: Mask Operations (条件分支优化)
// TMask2 (2 元素向量的比较结果)
function Mask2All(mask: TMask2): Boolean; inline;    // 全部为 true
function Mask2Any(mask: TMask2): Boolean; inline;    // 至少一个为 true
function Mask2None(mask: TMask2): Boolean; inline;   // 全部为 false
function Mask2PopCount(mask: TMask2): Integer; inline;  // 为 true 的元素数
function Mask2FirstSet(mask: TMask2): Integer; inline;  // 第一个为 true 的索引，-1 if none

// TMask4 (4 元素向量的比较结果)
function Mask4All(mask: TMask4): Boolean; inline;
function Mask4Any(mask: TMask4): Boolean; inline;
function Mask4None(mask: TMask4): Boolean; inline;
function Mask4PopCount(mask: TMask4): Integer; inline;
function Mask4FirstSet(mask: TMask4): Integer; inline;

// TMask8 (8 元素向量的比较结果)
function Mask8All(mask: TMask8): Boolean; inline;
function Mask8Any(mask: TMask8): Boolean; inline;
function Mask8None(mask: TMask8): Boolean; inline;
function Mask8PopCount(mask: TMask8): Integer; inline;
function Mask8FirstSet(mask: TMask8): Integer; inline;

// TMask16 (16 元素向量的比较结果)
function Mask16All(mask: TMask16): Boolean; inline;
function Mask16Any(mask: TMask16): Boolean; inline;
function Mask16None(mask: TMask16): Boolean; inline;
function Mask16PopCount(mask: TMask16): Integer; inline;
function Mask16FirstSet(mask: TMask16): Integer; inline;

// === I32x4 Operations (128-bit Integer) ===
// ✅ P0.3: 添加缺失的 I32x4 高级 API

// I32x4 arithmetic
function VecI32x4Add(const a, b: TVecI32x4): TVecI32x4; inline;
function VecI32x4Sub(const a, b: TVecI32x4): TVecI32x4; inline;
function VecI32x4Mul(const a, b: TVecI32x4): TVecI32x4; inline;

// I32x4 bitwise operations
function VecI32x4And(const a, b: TVecI32x4): TVecI32x4; inline;
function VecI32x4Or(const a, b: TVecI32x4): TVecI32x4; inline;
function VecI32x4Xor(const a, b: TVecI32x4): TVecI32x4; inline;
function VecI32x4Not(const a: TVecI32x4): TVecI32x4; inline;
function VecI32x4AndNot(const a, b: TVecI32x4): TVecI32x4; inline;

// I32x4 shift operations
function VecI32x4ShiftLeft(const a: TVecI32x4; count: Integer): TVecI32x4; inline;
function VecI32x4ShiftRight(const a: TVecI32x4; count: Integer): TVecI32x4; inline;
function VecI32x4ShiftRightArith(const a: TVecI32x4; count: Integer): TVecI32x4; inline;

// I32x4 comparison
function VecI32x4CmpEq(const a, b: TVecI32x4): TMask4; inline;
function VecI32x4CmpLt(const a, b: TVecI32x4): TMask4; inline;
function VecI32x4CmpGt(const a, b: TVecI32x4): TMask4; inline;
function VecI32x4CmpLe(const a, b: TVecI32x4): TMask4; inline;  // ✅ P0-C: 添加缺失 API
function VecI32x4CmpGe(const a, b: TVecI32x4): TMask4; inline;  // ✅ P0-C: 添加缺失 API
function VecI32x4CmpNe(const a, b: TVecI32x4): TMask4; inline;  // ✅ P0-C: 添加缺失 API

// I32x4 min/max
function VecI32x4Min(const a, b: TVecI32x4): TVecI32x4; inline;
function VecI32x4Max(const a, b: TVecI32x4): TVecI32x4; inline;

// === I64x2 Operations (128-bit Integer, 64-bit elements) ===
// ✅ P1.3: 添加 I64x2 高级 API

// I64x2 arithmetic
function VecI64x2Add(const a, b: TVecI64x2): TVecI64x2; inline;
function VecI64x2Sub(const a, b: TVecI64x2): TVecI64x2; inline;

// I64x2 bitwise operations
function VecI64x2And(const a, b: TVecI64x2): TVecI64x2; inline;
function VecI64x2Or(const a, b: TVecI64x2): TVecI64x2; inline;
function VecI64x2Xor(const a, b: TVecI64x2): TVecI64x2; inline;
function VecI64x2Not(const a: TVecI64x2): TVecI64x2; inline;
function VecI64x2AndNot(const a, b: TVecI64x2): TVecI64x2; inline;

// I64x2 shift operations
function VecI64x2ShiftLeft(const a: TVecI64x2; count: Integer): TVecI64x2; inline;
function VecI64x2ShiftRight(const a: TVecI64x2; count: Integer): TVecI64x2; inline;
function VecI64x2ShiftRightArith(const a: TVecI64x2; count: Integer): TVecI64x2; inline;

// I64x2 comparison
function VecI64x2CmpEq(const a, b: TVecI64x2): TMask2; inline;
function VecI64x2CmpLt(const a, b: TVecI64x2): TMask2; inline;
function VecI64x2CmpGt(const a, b: TVecI64x2): TMask2; inline;
function VecI64x2CmpLe(const a, b: TVecI64x2): TMask2; inline;  // ✅ P0-C: 添加缺失 API
function VecI64x2CmpGe(const a, b: TVecI64x2): TMask2; inline;  // ✅ P0-C: 添加缺失 API
function VecI64x2CmpNe(const a, b: TVecI64x2): TMask2; inline;  // ✅ P0-C: 添加缺失 API

// I64x2 min/max
function VecI64x2Min(const a, b: TVecI64x2): TVecI64x2; inline;
function VecI64x2Max(const a, b: TVecI64x2): TVecI64x2; inline;

// === U64x2 Operations (128-bit Unsigned 64-bit Integer) ===
// ✅ P3.3: 添加 U64x2 高级 API

// U64x2 arithmetic
function VecU64x2Add(const a, b: TVecU64x2): TVecU64x2; inline;
function VecU64x2Sub(const a, b: TVecU64x2): TVecU64x2; inline;

// U64x2 bitwise operations
function VecU64x2And(const a, b: TVecU64x2): TVecU64x2; inline;
function VecU64x2Or(const a, b: TVecU64x2): TVecU64x2; inline;
function VecU64x2Xor(const a, b: TVecU64x2): TVecU64x2; inline;
function VecU64x2Not(const a: TVecU64x2): TVecU64x2; inline;
function VecU64x2AndNot(const a, b: TVecU64x2): TVecU64x2; inline;

// U64x2 comparison (unsigned)
function VecU64x2CmpEq(const a, b: TVecU64x2): TMask2; inline;
function VecU64x2CmpLt(const a, b: TVecU64x2): TMask2; inline;
function VecU64x2CmpGt(const a, b: TVecU64x2): TMask2; inline;

// U64x2 min/max (unsigned)
function VecU64x2Min(const a, b: TVecU64x2): TVecU64x2; inline;
function VecU64x2Max(const a, b: TVecU64x2): TVecU64x2; inline;

// === U32x4 Operations (128-bit Unsigned Integer) ===
// ✅ P2.1: 添加 U32x4 高级 API

// U32x4 arithmetic (bit-identical to I32x4, different semantics)
function VecU32x4Add(const a, b: TVecU32x4): TVecU32x4; inline;
function VecU32x4Sub(const a, b: TVecU32x4): TVecU32x4; inline;
function VecU32x4Mul(const a, b: TVecU32x4): TVecU32x4; inline;

// U32x4 bitwise operations
function VecU32x4And(const a, b: TVecU32x4): TVecU32x4; inline;
function VecU32x4Or(const a, b: TVecU32x4): TVecU32x4; inline;
function VecU32x4Xor(const a, b: TVecU32x4): TVecU32x4; inline;
function VecU32x4Not(const a: TVecU32x4): TVecU32x4; inline;
function VecU32x4AndNot(const a, b: TVecU32x4): TVecU32x4; inline;

// U32x4 shift operations
function VecU32x4ShiftLeft(const a: TVecU32x4; count: Integer): TVecU32x4; inline;
function VecU32x4ShiftRight(const a: TVecU32x4; count: Integer): TVecU32x4; inline;

// U32x4 comparison (unsigned)
function VecU32x4CmpEq(const a, b: TVecU32x4): TMask4; inline;
function VecU32x4CmpLt(const a, b: TVecU32x4): TMask4; inline;
function VecU32x4CmpGt(const a, b: TVecU32x4): TMask4; inline;
function VecU32x4CmpLe(const a, b: TVecU32x4): TMask4; inline;
function VecU32x4CmpGe(const a, b: TVecU32x4): TMask4; inline;

// U32x4 min/max (unsigned)
function VecU32x4Min(const a, b: TVecU32x4): TVecU32x4; inline;
function VecU32x4Max(const a, b: TVecU32x4): TVecU32x4; inline;

// === F32x8 Operations (256-bit Float, AVX) ===
// ✅ P0.3: 添加缺失的 F32x8 高级 API

// F32x8 arithmetic
function VecF32x8Add(const a, b: TVecF32x8): TVecF32x8; inline;
function VecF32x8Sub(const a, b: TVecF32x8): TVecF32x8; inline;
function VecF32x8Mul(const a, b: TVecF32x8): TVecF32x8; inline;
function VecF32x8Div(const a, b: TVecF32x8): TVecF32x8; inline;

// F32x8 comparison
function VecF32x8CmpEq(const a, b: TVecF32x8): TMask8; inline;
function VecF32x8CmpLt(const a, b: TVecF32x8): TMask8; inline;
function VecF32x8CmpLe(const a, b: TVecF32x8): TMask8; inline;
function VecF32x8CmpGt(const a, b: TVecF32x8): TMask8; inline;
function VecF32x8CmpGe(const a, b: TVecF32x8): TMask8; inline;
function VecF32x8CmpNe(const a, b: TVecF32x8): TMask8; inline;

// F32x8 math functions
function VecF32x8Abs(const a: TVecF32x8): TVecF32x8; inline;
function VecF32x8Sqrt(const a: TVecF32x8): TVecF32x8; inline;
function VecF32x8Min(const a, b: TVecF32x8): TVecF32x8; inline;
function VecF32x8Max(const a, b: TVecF32x8): TVecF32x8; inline;

// F32x8 reduction
function VecF32x8ReduceAdd(const a: TVecF32x8): Single; inline;
function VecF32x8ReduceMin(const a: TVecF32x8): Single; inline;
function VecF32x8ReduceMax(const a: TVecF32x8): Single; inline;
function VecF32x8ReduceMul(const a: TVecF32x8): Single; inline;

// === I32x8 Operations (256-bit Integer, AVX2) ===
// ✅ P1.1: 添加缺失的 I32x8 高级 API

// I32x8 arithmetic
function VecI32x8Add(const a, b: TVecI32x8): TVecI32x8; inline;
function VecI32x8Sub(const a, b: TVecI32x8): TVecI32x8; inline;
function VecI32x8Mul(const a, b: TVecI32x8): TVecI32x8; inline;

// I32x8 bitwise operations
function VecI32x8And(const a, b: TVecI32x8): TVecI32x8; inline;
function VecI32x8Or(const a, b: TVecI32x8): TVecI32x8; inline;
function VecI32x8Xor(const a, b: TVecI32x8): TVecI32x8; inline;
function VecI32x8Not(const a: TVecI32x8): TVecI32x8; inline;
function VecI32x8AndNot(const a, b: TVecI32x8): TVecI32x8; inline;

// I32x8 shift operations
function VecI32x8ShiftLeft(const a: TVecI32x8; count: Integer): TVecI32x8; inline;
function VecI32x8ShiftRight(const a: TVecI32x8; count: Integer): TVecI32x8; inline;
function VecI32x8ShiftRightArith(const a: TVecI32x8; count: Integer): TVecI32x8; inline;

// I32x8 comparison
function VecI32x8CmpEq(const a, b: TVecI32x8): TMask8; inline;
function VecI32x8CmpLt(const a, b: TVecI32x8): TMask8; inline;
function VecI32x8CmpGt(const a, b: TVecI32x8): TMask8; inline;
function VecI32x8CmpLe(const a, b: TVecI32x8): TMask8; inline;  // ✅ P0-C: 添加缺失 API
function VecI32x8CmpGe(const a, b: TVecI32x8): TMask8; inline;  // ✅ P0-C: 添加缺失 API
function VecI32x8CmpNe(const a, b: TVecI32x8): TMask8; inline;  // ✅ P0-C: 添加缺失 API

// I32x8 min/max
function VecI32x8Min(const a, b: TVecI32x8): TVecI32x8; inline;
function VecI32x8Max(const a, b: TVecI32x8): TVecI32x8; inline;

// === U32x8 Operations (256-bit Unsigned Integer, AVX2) ===
// ✅ P2.1: 添加 U32x8 高级 API

// U32x8 arithmetic
function VecU32x8Add(const a, b: TVecU32x8): TVecU32x8; inline;
function VecU32x8Sub(const a, b: TVecU32x8): TVecU32x8; inline;
function VecU32x8Mul(const a, b: TVecU32x8): TVecU32x8; inline;

// U32x8 bitwise operations
function VecU32x8And(const a, b: TVecU32x8): TVecU32x8; inline;
function VecU32x8Or(const a, b: TVecU32x8): TVecU32x8; inline;
function VecU32x8Xor(const a, b: TVecU32x8): TVecU32x8; inline;
function VecU32x8Not(const a: TVecU32x8): TVecU32x8; inline;
function VecU32x8AndNot(const a, b: TVecU32x8): TVecU32x8; inline;

// U32x8 shift operations
function VecU32x8ShiftLeft(const a: TVecU32x8; count: Integer): TVecU32x8; inline;
function VecU32x8ShiftRight(const a: TVecU32x8; count: Integer): TVecU32x8; inline;

// U32x8 comparison (unsigned)
function VecU32x8CmpEq(const a, b: TVecU32x8): TMask8; inline;
function VecU32x8CmpLt(const a, b: TVecU32x8): TMask8; inline;
function VecU32x8CmpGt(const a, b: TVecU32x8): TMask8; inline;
function VecU32x8CmpLe(const a, b: TVecU32x8): TMask8; inline;
function VecU32x8CmpGe(const a, b: TVecU32x8): TMask8; inline;

// U32x8 min/max (unsigned)
function VecU32x8Min(const a, b: TVecU32x8): TVecU32x8; inline;
function VecU32x8Max(const a, b: TVecU32x8): TVecU32x8; inline;

// === I64x4 Operations (256-bit, 64-bit signed integers) ===
// ✅ Task 5.2: 添加 I64x4 高级 API (AVX2)

// I64x4 arithmetic
function VecI64x4Add(const a, b: TVecI64x4): TVecI64x4; inline;
function VecI64x4Sub(const a, b: TVecI64x4): TVecI64x4; inline;

// I64x4 bitwise operations
function VecI64x4And(const a, b: TVecI64x4): TVecI64x4; inline;
function VecI64x4Or(const a, b: TVecI64x4): TVecI64x4; inline;
function VecI64x4Xor(const a, b: TVecI64x4): TVecI64x4; inline;
function VecI64x4Not(const a: TVecI64x4): TVecI64x4; inline;
function VecI64x4AndNot(const a, b: TVecI64x4): TVecI64x4; inline;

// I64x4 shift operations (logical)
function VecI64x4ShiftLeft(const a: TVecI64x4; count: Integer): TVecI64x4; inline;
function VecI64x4ShiftRight(const a: TVecI64x4; count: Integer): TVecI64x4; inline;

// I64x4 comparison
function VecI64x4CmpEq(const a, b: TVecI64x4): TMask4; inline;
function VecI64x4CmpLt(const a, b: TVecI64x4): TMask4; inline;
function VecI64x4CmpGt(const a, b: TVecI64x4): TMask4; inline;
function VecI64x4CmpLe(const a, b: TVecI64x4): TMask4; inline;
function VecI64x4CmpGe(const a, b: TVecI64x4): TMask4; inline;
function VecI64x4CmpNe(const a, b: TVecI64x4): TMask4; inline;

// I64x4 utility operations
function VecI64x4Load(p: PInt64): TVecI64x4; inline;
procedure VecI64x4Store(p: PInt64; const a: TVecI64x4); inline;
function VecI64x4Splat(value: Int64): TVecI64x4; inline;
function VecI64x4Zero: TVecI64x4; inline;

// === U64x4 Operations (256-bit, 64-bit unsigned integers) ===
// ✅ Task 5.2: 添加 U64x4 高级 API (AVX2)

// U64x4 arithmetic
function VecU64x4Add(const a, b: TVecU64x4): TVecU64x4; inline;
function VecU64x4Sub(const a, b: TVecU64x4): TVecU64x4; inline;

// U64x4 bitwise operations
function VecU64x4And(const a, b: TVecU64x4): TVecU64x4; inline;
function VecU64x4Or(const a, b: TVecU64x4): TVecU64x4; inline;
function VecU64x4Xor(const a, b: TVecU64x4): TVecU64x4; inline;
function VecU64x4Not(const a: TVecU64x4): TVecU64x4; inline;

// U64x4 shift operations (logical)
function VecU64x4ShiftLeft(const a: TVecU64x4; count: Integer): TVecU64x4; inline;
function VecU64x4ShiftRight(const a: TVecU64x4; count: Integer): TVecU64x4; inline;

// U64x4 comparison (unsigned)
function VecU64x4CmpEq(const a, b: TVecU64x4): TMask4; inline;
function VecU64x4CmpLt(const a, b: TVecU64x4): TMask4; inline;
function VecU64x4CmpGt(const a, b: TVecU64x4): TMask4; inline;
function VecU64x4CmpLe(const a, b: TVecU64x4): TMask4; inline;
function VecU64x4CmpGe(const a, b: TVecU64x4): TMask4; inline;
function VecU64x4CmpNe(const a, b: TVecU64x4): TMask4; inline;

// U64x4 utility operations
function VecU64x4Splat(value: UInt64): TVecU64x4; inline;
function VecU64x4Zero: TVecU64x4; inline;

// === I16x8 Operations (128-bit, 16-bit signed integers) ===
// ✅ P2.2: 添加 I16x8 高级 API

// I16x8 arithmetic
function VecI16x8Add(const a, b: TVecI16x8): TVecI16x8; inline;
function VecI16x8Sub(const a, b: TVecI16x8): TVecI16x8; inline;
function VecI16x8Mul(const a, b: TVecI16x8): TVecI16x8; inline;

// I16x8 bitwise operations
function VecI16x8And(const a, b: TVecI16x8): TVecI16x8; inline;
function VecI16x8Or(const a, b: TVecI16x8): TVecI16x8; inline;
function VecI16x8Xor(const a, b: TVecI16x8): TVecI16x8; inline;
function VecI16x8Not(const a: TVecI16x8): TVecI16x8; inline;
function VecI16x8AndNot(const a, b: TVecI16x8): TVecI16x8; inline;

// I16x8 shift operations
function VecI16x8ShiftLeft(const a: TVecI16x8; count: Integer): TVecI16x8; inline;
function VecI16x8ShiftRight(const a: TVecI16x8; count: Integer): TVecI16x8; inline;
function VecI16x8ShiftRightArith(const a: TVecI16x8; count: Integer): TVecI16x8; inline;

// I16x8 comparison
function VecI16x8CmpEq(const a, b: TVecI16x8): TMask8; inline;
function VecI16x8CmpLt(const a, b: TVecI16x8): TMask8; inline;
function VecI16x8CmpGt(const a, b: TVecI16x8): TMask8; inline;

// I16x8 min/max
function VecI16x8Min(const a, b: TVecI16x8): TVecI16x8; inline;
function VecI16x8Max(const a, b: TVecI16x8): TVecI16x8; inline;

// === I8x16 Operations (128-bit, 8-bit signed integers) ===
// ✅ P2.2: 添加 I8x16 高级 API

// I8x16 arithmetic
function VecI8x16Add(const a, b: TVecI8x16): TVecI8x16; inline;
function VecI8x16Sub(const a, b: TVecI8x16): TVecI8x16; inline;

// I8x16 bitwise operations
function VecI8x16And(const a, b: TVecI8x16): TVecI8x16; inline;
function VecI8x16Or(const a, b: TVecI8x16): TVecI8x16; inline;
function VecI8x16Xor(const a, b: TVecI8x16): TVecI8x16; inline;
function VecI8x16Not(const a: TVecI8x16): TVecI8x16; inline;
function VecI8x16AndNot(const a, b: TVecI8x16): TVecI8x16; inline;

// I8x16 comparison
function VecI8x16CmpEq(const a, b: TVecI8x16): TMask16; inline;
function VecI8x16CmpLt(const a, b: TVecI8x16): TMask16; inline;
function VecI8x16CmpGt(const a, b: TVecI8x16): TMask16; inline;

// I8x16 min/max
function VecI8x16Min(const a, b: TVecI8x16): TVecI8x16; inline;
function VecI8x16Max(const a, b: TVecI8x16): TVecI8x16; inline;

// === U8x16 Operations (128-bit, 8-bit unsigned integers) ===
// ✅ P4.1: 添加 U8x16 高级 API

// U8x16 arithmetic
function VecU8x16Add(const a, b: TVecU8x16): TVecU8x16; inline;
function VecU8x16Sub(const a, b: TVecU8x16): TVecU8x16; inline;

// U8x16 bitwise operations
function VecU8x16And(const a, b: TVecU8x16): TVecU8x16; inline;
function VecU8x16Or(const a, b: TVecU8x16): TVecU8x16; inline;
function VecU8x16Xor(const a, b: TVecU8x16): TVecU8x16; inline;
function VecU8x16Not(const a: TVecU8x16): TVecU8x16; inline;
function VecU8x16AndNot(const a, b: TVecU8x16): TVecU8x16; inline;

// U8x16 comparison (unsigned)
function VecU8x16CmpEq(const a, b: TVecU8x16): TMask16; inline;
function VecU8x16CmpLt(const a, b: TVecU8x16): TMask16; inline;
function VecU8x16CmpGt(const a, b: TVecU8x16): TMask16; inline;

// U8x16 min/max (unsigned)
function VecU8x16Min(const a, b: TVecU8x16): TVecU8x16; inline;
function VecU8x16Max(const a, b: TVecU8x16): TVecU8x16; inline;

// === U16x8 Operations (128-bit, 16-bit unsigned integers) ===
// ✅ P4.2: 添加 U16x8 高级 API

// U16x8 arithmetic
function VecU16x8Add(const a, b: TVecU16x8): TVecU16x8; inline;
function VecU16x8Sub(const a, b: TVecU16x8): TVecU16x8; inline;
function VecU16x8Mul(const a, b: TVecU16x8): TVecU16x8; inline;

// U16x8 bitwise operations
function VecU16x8And(const a, b: TVecU16x8): TVecU16x8; inline;
function VecU16x8Or(const a, b: TVecU16x8): TVecU16x8; inline;
function VecU16x8Xor(const a, b: TVecU16x8): TVecU16x8; inline;
function VecU16x8Not(const a: TVecU16x8): TVecU16x8; inline;
function VecU16x8AndNot(const a, b: TVecU16x8): TVecU16x8; inline;

// U16x8 shift operations
function VecU16x8ShiftLeft(const a: TVecU16x8; count: Integer): TVecU16x8; inline;
function VecU16x8ShiftRight(const a: TVecU16x8; count: Integer): TVecU16x8; inline;

// U16x8 comparison (unsigned)
function VecU16x8CmpEq(const a, b: TVecU16x8): TMask8; inline;
function VecU16x8CmpLt(const a, b: TVecU16x8): TMask8; inline;
function VecU16x8CmpGt(const a, b: TVecU16x8): TMask8; inline;

// U16x8 min/max (unsigned)
function VecU16x8Min(const a, b: TVecU16x8): TVecU16x8; inline;
function VecU16x8Max(const a, b: TVecU16x8): TVecU16x8; inline;

// === F64x4 Operations (256-bit Double, AVX) ===
// ✅ P2.3: 添加 F64x4 高级 API

// F64x4 arithmetic
function VecF64x4Add(const a, b: TVecF64x4): TVecF64x4; inline;
function VecF64x4Sub(const a, b: TVecF64x4): TVecF64x4; inline;
function VecF64x4Mul(const a, b: TVecF64x4): TVecF64x4; inline;
function VecF64x4Div(const a, b: TVecF64x4): TVecF64x4; inline;

// F64x4 comparison
function VecF64x4CmpEq(const a, b: TVecF64x4): TMask4; inline;
function VecF64x4CmpLt(const a, b: TVecF64x4): TMask4; inline;
function VecF64x4CmpLe(const a, b: TVecF64x4): TMask4; inline;
function VecF64x4CmpGt(const a, b: TVecF64x4): TMask4; inline;
function VecF64x4CmpGe(const a, b: TVecF64x4): TMask4; inline;
function VecF64x4CmpNe(const a, b: TVecF64x4): TMask4; inline;

// F64x4 math functions
function VecF64x4Abs(const a: TVecF64x4): TVecF64x4; inline;
function VecF64x4Sqrt(const a: TVecF64x4): TVecF64x4; inline;
function VecF64x4Min(const a, b: TVecF64x4): TVecF64x4; inline;
function VecF64x4Max(const a, b: TVecF64x4): TVecF64x4; inline;

// F64x4 reduction
function VecF64x4ReduceAdd(const a: TVecF64x4): Double; inline;
function VecF64x4ReduceMin(const a: TVecF64x4): Double; inline;
function VecF64x4ReduceMax(const a: TVecF64x4): Double; inline;
function VecF64x4ReduceMul(const a: TVecF64x4): Double; inline;

// === F64x8 Operations (512-bit Double, AVX-512) ===
// ✅ P2.3: 添加 F64x8 高级 API

// F64x8 arithmetic
function VecF64x8Add(const a, b: TVecF64x8): TVecF64x8; inline;
function VecF64x8Sub(const a, b: TVecF64x8): TVecF64x8; inline;
function VecF64x8Mul(const a, b: TVecF64x8): TVecF64x8; inline;
function VecF64x8Div(const a, b: TVecF64x8): TVecF64x8; inline;

// F64x8 comparison
function VecF64x8CmpEq(const a, b: TVecF64x8): TMask8; inline;
function VecF64x8CmpLt(const a, b: TVecF64x8): TMask8; inline;
function VecF64x8CmpLe(const a, b: TVecF64x8): TMask8; inline;
function VecF64x8CmpGt(const a, b: TVecF64x8): TMask8; inline;
function VecF64x8CmpGe(const a, b: TVecF64x8): TMask8; inline;
function VecF64x8CmpNe(const a, b: TVecF64x8): TMask8; inline;

// F64x8 math functions
function VecF64x8Abs(const a: TVecF64x8): TVecF64x8; inline;
function VecF64x8Sqrt(const a: TVecF64x8): TVecF64x8; inline;
function VecF64x8Min(const a, b: TVecF64x8): TVecF64x8; inline;
function VecF64x8Max(const a, b: TVecF64x8): TVecF64x8; inline;

// F64x8 reduction
function VecF64x8ReduceAdd(const a: TVecF64x8): Double; inline;
function VecF64x8ReduceMin(const a: TVecF64x8): Double; inline;
function VecF64x8ReduceMax(const a: TVecF64x8): Double; inline;
function VecF64x8ReduceMul(const a: TVecF64x8): Double; inline;

// === F32x16 Operations (512-bit Float, AVX-512) ===
// ✅ P3.2: 添加 F32x16 高级 API

// F32x16 arithmetic
function VecF32x16Add(const a, b: TVecF32x16): TVecF32x16; inline;
function VecF32x16Sub(const a, b: TVecF32x16): TVecF32x16; inline;
function VecF32x16Mul(const a, b: TVecF32x16): TVecF32x16; inline;
function VecF32x16Div(const a, b: TVecF32x16): TVecF32x16; inline;

// F32x16 comparison
function VecF32x16CmpEq_Mask(const a, b: TVecF32x16): TMask16; inline;
function VecF32x16CmpLt_Mask(const a, b: TVecF32x16): TMask16; inline;
function VecF32x16CmpLe_Mask(const a, b: TVecF32x16): TMask16; inline;
function VecF32x16CmpGt_Mask(const a, b: TVecF32x16): TMask16; inline;
function VecF32x16CmpGe_Mask(const a, b: TVecF32x16): TMask16; inline;
function VecF32x16CmpNe_Mask(const a, b: TVecF32x16): TMask16; inline;

// F32x16 math functions
function VecF32x16Abs(const a: TVecF32x16): TVecF32x16; inline;
function VecF32x16Sqrt(const a: TVecF32x16): TVecF32x16; inline;
function VecF32x16Min(const a, b: TVecF32x16): TVecF32x16; inline;
function VecF32x16Max(const a, b: TVecF32x16): TVecF32x16; inline;

// F32x16 reduction
function VecF32x16ReduceAdd(const a: TVecF32x16): Single; inline;
function VecF32x16ReduceMin(const a: TVecF32x16): Single; inline;
function VecF32x16ReduceMax(const a: TVecF32x16): Single; inline;
function VecF32x16ReduceMul(const a: TVecF32x16): Single; inline;

// === I32x16 Operations (512-bit Integer, AVX-512) ===
// ✅ P1.2: 添加 I32x16 高级 API

// I32x16 arithmetic
function VecI32x16Add(const a, b: TVecI32x16): TVecI32x16; inline;
function VecI32x16Sub(const a, b: TVecI32x16): TVecI32x16; inline;
function VecI32x16Mul(const a, b: TVecI32x16): TVecI32x16; inline;

// I32x16 bitwise operations
function VecI32x16And(const a, b: TVecI32x16): TVecI32x16; inline;
function VecI32x16Or(const a, b: TVecI32x16): TVecI32x16; inline;
function VecI32x16Xor(const a, b: TVecI32x16): TVecI32x16; inline;
function VecI32x16Not(const a: TVecI32x16): TVecI32x16; inline;
function VecI32x16AndNot(const a, b: TVecI32x16): TVecI32x16; inline;

// I32x16 shift operations
function VecI32x16ShiftLeft(const a: TVecI32x16; count: Integer): TVecI32x16; inline;
function VecI32x16ShiftRight(const a: TVecI32x16; count: Integer): TVecI32x16; inline;
function VecI32x16ShiftRightArith(const a: TVecI32x16; count: Integer): TVecI32x16; inline;

// I32x16 comparison
function VecI32x16CmpEq(const a, b: TVecI32x16): TMask16; inline;
function VecI32x16CmpLt(const a, b: TVecI32x16): TMask16; inline;
function VecI32x16CmpGt(const a, b: TVecI32x16): TMask16; inline;
function VecI32x16CmpLe(const a, b: TVecI32x16): TMask16; inline;  // ✅ P0-C: 添加缺失 API
function VecI32x16CmpGe(const a, b: TVecI32x16): TMask16; inline;  // ✅ P0-C: 添加缺失 API
function VecI32x16CmpNe(const a, b: TVecI32x16): TMask16; inline;  // ✅ P0-C: 添加缺失 API

// I32x16 min/max
function VecI32x16Min(const a, b: TVecI32x16): TVecI32x16; inline;
function VecI32x16Max(const a, b: TVecI32x16): TVecI32x16; inline;

// === ✅ P2-1: Saturating Arithmetic (音视频处理必需) ===
// 有符号饱和: I8 范围 [-128, 127], I16 范围 [-32768, 32767]
function VecI8x16SatAdd(const a, b: TVecI8x16): TVecI8x16; inline;
function VecI8x16SatSub(const a, b: TVecI8x16): TVecI8x16; inline;
function VecI16x8SatAdd(const a, b: TVecI16x8): TVecI16x8; inline;
function VecI16x8SatSub(const a, b: TVecI16x8): TVecI16x8; inline;
// 无符号饱和: U8 范围 [0, 255], U16 范围 [0, 65535]
function VecU8x16SatAdd(const a, b: TVecU8x16): TVecU8x16; inline;
function VecU8x16SatSub(const a, b: TVecU8x16): TVecU8x16; inline;
function VecU16x8SatAdd(const a, b: TVecU16x8): TVecU16x8; inline;
function VecU16x8SatSub(const a, b: TVecU16x8): TVecU16x8; inline;

// === Framework Information ===

// Get current backend information
function GetCurrentBackend: TSimdBackend;
function GetCurrentBackendInfo: TSimdBackendInfo;

// Get CPU information
function GetCPUInformation: TCPUInfo;

// Get list of available backends
function GetAvailableBackendList: TSimdBackendArray;

// Force a specific backend (for testing)
procedure ForceBackend(backend: TSimdBackend);
procedure ResetBackendSelection;

// === Shuffle/Permute Operations (re-exported from simd.utils) ===

{**
  Shuffle elements within a single F32x4 vector.
  @param(a Source vector)
  @param(imm8 Shuffle control: bits [1:0]=idx0, [3:2]=idx1, [5:4]=idx2, [7:6]=idx3)
  @returns(result[i] = a[idx_i])
  @example MM_SHUFFLE(3,2,1,0) = identity, MM_SHUFFLE(0,0,0,0) = broadcast element 0
*}
function VecF32x4Shuffle(const a: TVecF32x4; imm8: Byte): TVecF32x4; inline;

{** Shuffle I32x4 elements. Same semantics as VecF32x4Shuffle. *}
function VecI32x4Shuffle(const a: TVecI32x4; imm8: Byte): TVecI32x4; inline;

{**
  Shuffle elements from two F32x4 vectors.
  @param(a First source vector)
  @param(b Second source vector)
  @param(imm8 Shuffle control: low 2 elements from a[idx], high 2 elements from b[idx])
  @returns(result[0..1] from a, result[2..3] from b)
*}
function VecF32x4Shuffle2(const a, b: TVecF32x4; imm8: Byte): TVecF32x4; inline;

// === Blend Operations (re-exported from simd.utils) ===

{**
  Blend two F32x4 vectors based on mask.
  @param(a First source vector)
  @param(b Second source vector)
  @param(mask Blend mask: bit i = 0 selects a[i], bit i = 1 selects b[i])
  @returns(result[i] = (mask & (1<<i)) ? b[i] : a[i])
*}
function VecF32x4Blend(const a, b: TVecF32x4; mask: Byte): TVecF32x4; inline;

{** Blend two F64x2 vectors. Bits 0-1 control elements 0-1. *}
function VecF64x2Blend(const a, b: TVecF64x2; mask: Byte): TVecF64x2; inline;

{** Blend two I32x4 vectors. Same semantics as VecF32x4Blend. *}
function VecI32x4Blend(const a, b: TVecI32x4; mask: Byte): TVecI32x4; inline;

// === Type Conversion Operations (re-exported from simd.utils) ===

{**
  Reinterpret F32x4 bits as I32x4 (no conversion, just bit reinterpret).
  @param(a Source vector)
  @returns(Bit-identical reinterpretation as I32x4)
*}
function VecF32x4IntoBits(const a: TVecF32x4): TVecI32x4; inline;

{**
  Reinterpret I32x4 bits as F32x4 (no conversion, just bit reinterpret).
  @param(a Source vector)
  @returns(Bit-identical reinterpretation as F32x4)
*}
function VecI32x4FromBitsF32(const a: TVecI32x4): TVecF32x4; inline;

{**
  Convert I32x4 to F32x4 (integer to float, value conversion).
  @param(a Source integer vector)
  @returns(result[i] = (float)a[i])
*}
function VecI32x4CastToF32x4(const a: TVecI32x4): TVecF32x4; inline;

{**
  Convert F32x4 to I32x4 (float to integer, truncate toward zero).
  @param(a Source float vector)
  @returns(result[i] = (int)trunc(a[i]))
*}
function VecF32x4CastToI32x4(const a: TVecF32x4): TVecI32x4; inline;

// === Memory Utilities (Re-exported) ===

// Aligned memory allocation
function AllocateAligned(size: NativeUInt; alignment: NativeUInt = 32): Pointer;
procedure FreeAligned(ptr: Pointer);

// Alignment checking
function IsPointerAligned(ptr: Pointer; alignment: NativeUInt = 32): Boolean;

implementation

// === High-Level Vector Operations Implementation ===

function VecF32x4Add(const a, b: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.AddF32x4(a, b);
end;

function VecF32x4Sub(const a, b: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.SubF32x4(a, b);
end;

function VecF32x4Mul(const a, b: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.MulF32x4(a, b);
end;

function VecF32x4Div(const a, b: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.DivF32x4(a, b);
end;

function VecF32x4CmpEq(const a, b: TVecF32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.CmpEqF32x4(a, b);
end;

function VecF32x4CmpLt(const a, b: TVecF32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.CmpLtF32x4(a, b);
end;

function VecF32x4CmpLe(const a, b: TVecF32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.CmpLeF32x4(a, b);
end;

function VecF32x4CmpGt(const a, b: TVecF32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.CmpGtF32x4(a, b);
end;

function VecF32x4CmpGe(const a, b: TVecF32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.CmpGeF32x4(a, b);
end;

function VecF32x4CmpNe(const a, b: TVecF32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.CmpNeF32x4(a, b);
end;

function VecF32x4Abs(const a: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.AbsF32x4(a);
end;

function VecF32x4Sqrt(const a: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.SqrtF32x4(a);
end;

function VecF32x4Min(const a, b: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.MinF32x4(a, b);
end;

function VecF32x4Max(const a, b: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.MaxF32x4(a, b);
end;

// === Extended Math Functions ===

function VecF32x4Fma(const a, b, c: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.FmaF32x4(a, b, c);
end;

function VecF32x4Rcp(const a: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.RcpF32x4(a);
end;

function VecF32x4Rsqrt(const a: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.RsqrtF32x4(a);
end;

function VecF32x4Floor(const a: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.FloorF32x4(a);
end;

function VecF32x4Ceil(const a: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.CeilF32x4(a);
end;

function VecF32x4Round(const a: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.RoundF32x4(a);
end;

function VecF32x4Trunc(const a: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.TruncF32x4(a);
end;

function VecF32x4Clamp(const a, minVal, maxVal: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ClampF32x4(a, minVal, maxVal);
end;

// === 3D/4D Vector Math ===

function VecF32x4Dot(const a, b: TVecF32x4): Single;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.DotF32x4(a, b);
end;

function VecF32x3Dot(const a, b: TVecF32x4): Single;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.DotF32x3(a, b);
end;

function VecF32x3Cross(const a, b: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.CrossF32x3(a, b);
end;

function VecF32x4Length(const a: TVecF32x4): Single;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.LengthF32x4(a);
end;

function VecF32x3Length(const a: TVecF32x4): Single;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.LengthF32x3(a);
end;

function VecF32x4Normalize(const a: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.NormalizeF32x4(a);
end;

function VecF32x3Normalize(const a: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.NormalizeF32x3(a);
end;

// ✅ Iteration 6.4: FMA-optimized Dot Product Functions

function VecF32x8Dot(const a, b: TVecF32x8): Single;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.DotF32x8(a, b);
end;

function VecF64x2Dot(const a, b: TVecF64x2): Double;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.DotF64x2(a, b);
end;

function VecF64x4Dot(const a, b: TVecF64x4): Double;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.DotF64x4(a, b);
end;


function VecF32x4ReduceAdd(const a: TVecF32x4): Single;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ReduceAddF32x4(a);
end;

function VecF32x4ReduceMin(const a: TVecF32x4): Single;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ReduceMinF32x4(a);
end;

function VecF32x4ReduceMax(const a: TVecF32x4): Single;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ReduceMaxF32x4(a);
end;

function VecF32x4ReduceMul(const a: TVecF32x4): Single;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ReduceMulF32x4(a);
end;

function VecF32x4Load(p: PSingle): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.LoadF32x4(p);
end;

function VecF32x4LoadAligned(p: PSingle): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.LoadF32x4Aligned(p);
end;

procedure VecF32x4Store(p: PSingle; const a: TVecF32x4);
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  dispatch^.StoreF32x4(p, a);
end;

procedure VecF32x4StoreAligned(p: PSingle; const a: TVecF32x4);
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  dispatch^.StoreF32x4Aligned(p, a);
end;

function VecF32x4Splat(value: Single): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.SplatF32x4(value);
end;

function VecF32x4Zero: TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ZeroF32x4();
end;

function VecF32x4Select(const mask: TMask4; const a, b: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.SelectF32x4(mask, a, b);
end;

function VecF32x4Extract(const a: TVecF32x4; index: Integer): Single;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ExtractF32x4(a, index);
end;

function VecF32x4Insert(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.InsertF32x4(a, value, index);
end;

// === ✅ Task 5.3: Extract/Insert Lane Operations Implementation ===

// F64x2 (128-bit)
function VecF64x2Extract(const a: TVecF64x2; index: Integer): Double;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ExtractF64x2(a, index);
end;

function VecF64x2Insert(const a: TVecF64x2; value: Double; index: Integer): TVecF64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.InsertF64x2(a, value, index);
end;

// I32x4 (128-bit)
function VecI32x4Extract(const a: TVecI32x4; index: Integer): Int32;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ExtractI32x4(a, index);
end;

function VecI32x4Insert(const a: TVecI32x4; value: Int32; index: Integer): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.InsertI32x4(a, value, index);
end;

// I64x2 (128-bit)
function VecI64x2Extract(const a: TVecI64x2; index: Integer): Int64;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ExtractI64x2(a, index);
end;

function VecI64x2Insert(const a: TVecI64x2; value: Int64; index: Integer): TVecI64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.InsertI64x2(a, value, index);
end;

// F32x8 (256-bit)
function VecF32x8Extract(const a: TVecF32x8; index: Integer): Single;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ExtractF32x8(a, index);
end;

function VecF32x8Insert(const a: TVecF32x8; value: Single; index: Integer): TVecF32x8;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.InsertF32x8(a, value, index);
end;

// F64x4 (256-bit)
function VecF64x4Extract(const a: TVecF64x4; index: Integer): Double;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ExtractF64x4(a, index);
end;

function VecF64x4Insert(const a: TVecF64x4; value: Double; index: Integer): TVecF64x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.InsertF64x4(a, value, index);
end;

// I32x8 (256-bit)
function VecI32x8Extract(const a: TVecI32x8; index: Integer): Int32;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ExtractI32x8(a, index);
end;

function VecI32x8Insert(const a: TVecI32x8; value: Int32; index: Integer): TVecI32x8;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.InsertI32x8(a, value, index);
end;

// I64x4 (256-bit)
function VecI64x4Extract(const a: TVecI64x4; index: Integer): Int64;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ExtractI64x4(a, index);
end;

function VecI64x4Insert(const a: TVecI64x4; value: Int64; index: Integer): TVecI64x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.InsertI64x4(a, value, index);
end;

// F32x16 (512-bit)
function VecF32x16Extract(const a: TVecF32x16; index: Integer): Single;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ExtractF32x16(a, index);
end;

function VecF32x16Insert(const a: TVecF32x16; value: Single; index: Integer): TVecF32x16;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.InsertF32x16(a, value, index);
end;

// I32x16 (512-bit)
function VecI32x16Extract(const a: TVecI32x16; index: Integer): Int32;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ExtractI32x16(a, index);
end;

function VecI32x16Insert(const a: TVecI32x16; value: Int32; index: Integer): TVecI32x16;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.InsertI32x16(a, value, index);
end;

// === F64x2 Operations Implementation ===
// ✅ P0.3: F64x2 高级 API 实现

function VecF64x2Add(const a, b: TVecF64x2): TVecF64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AddF64x2) then
    Result := dispatch^.AddF64x2(a, b)
  else
  begin
    Result.d[0] := a.d[0] + b.d[0];
    Result.d[1] := a.d[1] + b.d[1];
  end;
end;

function VecF64x2Sub(const a, b: TVecF64x2): TVecF64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SubF64x2) then
    Result := dispatch^.SubF64x2(a, b)
  else
  begin
    Result.d[0] := a.d[0] - b.d[0];
    Result.d[1] := a.d[1] - b.d[1];
  end;
end;

function VecF64x2Mul(const a, b: TVecF64x2): TVecF64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MulF64x2) then
    Result := dispatch^.MulF64x2(a, b)
  else
  begin
    Result.d[0] := a.d[0] * b.d[0];
    Result.d[1] := a.d[1] * b.d[1];
  end;
end;

function VecF64x2Div(const a, b: TVecF64x2): TVecF64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.DivF64x2) then
    Result := dispatch^.DivF64x2(a, b)
  else
  begin
    Result.d[0] := a.d[0] / b.d[0];
    Result.d[1] := a.d[1] / b.d[1];
  end;
end;

// ✅ P1-E: F64x2 比较操作 - 使用派发表

function VecF64x2CmpEq(const a, b: TVecF64x2): TMask2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpEqF64x2) then
    Result := dispatch^.CmpEqF64x2(a, b)
  else begin
    Result := 0;
    if a.d[0] = b.d[0] then Result := Result or 1;
    if a.d[1] = b.d[1] then Result := Result or 2;
  end;
end;

function VecF64x2CmpLt(const a, b: TVecF64x2): TMask2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLtF64x2) then
    Result := dispatch^.CmpLtF64x2(a, b)
  else begin
    Result := 0;
    if a.d[0] < b.d[0] then Result := Result or 1;
    if a.d[1] < b.d[1] then Result := Result or 2;
  end;
end;

function VecF64x2CmpLe(const a, b: TVecF64x2): TMask2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLeF64x2) then
    Result := dispatch^.CmpLeF64x2(a, b)
  else begin
    Result := 0;
    if a.d[0] <= b.d[0] then Result := Result or 1;
    if a.d[1] <= b.d[1] then Result := Result or 2;
  end;
end;

function VecF64x2CmpGt(const a, b: TVecF64x2): TMask2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGtF64x2) then
    Result := dispatch^.CmpGtF64x2(a, b)
  else begin
    Result := 0;
    if a.d[0] > b.d[0] then Result := Result or 1;
    if a.d[1] > b.d[1] then Result := Result or 2;
  end;
end;

function VecF64x2CmpGe(const a, b: TVecF64x2): TMask2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGeF64x2) then
    Result := dispatch^.CmpGeF64x2(a, b)
  else begin
    Result := 0;
    if a.d[0] >= b.d[0] then Result := Result or 1;
    if a.d[1] >= b.d[1] then Result := Result or 2;
  end;
end;

function VecF64x2CmpNe(const a, b: TVecF64x2): TMask2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpNeF64x2) then
    Result := dispatch^.CmpNeF64x2(a, b)
  else begin
    Result := 0;
    if a.d[0] <> b.d[0] then Result := Result or 1;
    if a.d[1] <> b.d[1] then Result := Result or 2;
  end;
end;

function VecF64x2Abs(const a: TVecF64x2): TVecF64x2;
begin
  Result.d[0] := Abs(a.d[0]);
  Result.d[1] := Abs(a.d[1]);
end;

function VecF64x2Sqrt(const a: TVecF64x2): TVecF64x2;
begin
  Result.d[0] := Sqrt(a.d[0]);
  Result.d[1] := Sqrt(a.d[1]);
end;

function VecF64x2Min(const a, b: TVecF64x2): TVecF64x2;
begin
  if a.d[0] < b.d[0] then Result.d[0] := a.d[0] else Result.d[0] := b.d[0];
  if a.d[1] < b.d[1] then Result.d[1] := a.d[1] else Result.d[1] := b.d[1];
end;

function VecF64x2Max(const a, b: TVecF64x2): TVecF64x2;
begin
  if a.d[0] > b.d[0] then Result.d[0] := a.d[0] else Result.d[0] := b.d[0];
  if a.d[1] > b.d[1] then Result.d[1] := a.d[1] else Result.d[1] := b.d[1];
end;

// === F64x2 Extended Math Functions ===

function VecF64x2Fma(const a, b, c: TVecF64x2): TVecF64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.FmaF64x2(a, b, c);
end;

// === F64x2 Rounding Functions ===

function VecF64x2Floor(const a: TVecF64x2): TVecF64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.FloorF64x2(a);
end;

function VecF64x2Ceil(const a: TVecF64x2): TVecF64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.CeilF64x2(a);
end;

function VecF64x2Round(const a: TVecF64x2): TVecF64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.RoundF64x2(a);
end;

function VecF64x2Trunc(const a: TVecF64x2): TVecF64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.TruncF64x2(a);
end;

function VecF64x2ReduceAdd(const a: TVecF64x2): Double;
begin
  Result := a.d[0] + a.d[1];
end;

function VecF64x2ReduceMin(const a: TVecF64x2): Double;
begin
  if a.d[0] < a.d[1] then Result := a.d[0] else Result := a.d[1];
end;

function VecF64x2ReduceMax(const a: TVecF64x2): Double;
begin
  if a.d[0] > a.d[1] then Result := a.d[0] else Result := a.d[1];
end;

function VecF64x2ReduceMul(const a: TVecF64x2): Double;
begin
  Result := a.d[0] * a.d[1];
end;

// ✅ P2-3: F64x2 memory operations
function VecF64x2Load(p: PDouble): TVecF64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.LoadF64x2) then
    Result := dispatch^.LoadF64x2(p)
  else
  begin
    Result.d[0] := p[0];
    Result.d[1] := p[1];
  end;
end;

procedure VecF64x2Store(p: PDouble; const a: TVecF64x2);
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.StoreF64x2) then
    dispatch^.StoreF64x2(p, a)
  else
  begin
    p[0] := a.d[0];
    p[1] := a.d[1];
  end;
end;

function VecF64x2Splat(value: Double): TVecF64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SplatF64x2) then
    Result := dispatch^.SplatF64x2(value)
  else
  begin
    Result.d[0] := value;
    Result.d[1] := value;
  end;
end;

function VecF64x2Zero: TVecF64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ZeroF64x2) then
    Result := dispatch^.ZeroF64x2()
  else
  begin
    Result.d[0] := 0.0;
    Result.d[1] := 0.0;
  end;
end;

function VecF64x2Select(const mask: TMask2; const a, b: TVecF64x2): TVecF64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SelectF64x2) then
    Result := dispatch^.SelectF64x2(mask, a, b)
  else
  begin
    // 标量回退实现
    if (mask and 1) <> 0 then Result.d[0] := a.d[0] else Result.d[0] := b.d[0];
    if (mask and 2) <> 0 then Result.d[1] := a.d[1] else Result.d[1] := b.d[1];
  end;
end;

// ✅ NEW: 缺失的 Select 操作实现

function VecI32x4Select(const mask: TVecI32x4; const a, b: TVecI32x4): TVecI32x4;
var
  dispatch: PSimdDispatchTable;
  i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SelectI32x4) then
    Result := dispatch^.SelectI32x4(mask, a, b)
  else
  begin
    // 标量回退实现：掩码元素非零时选择 a
    for i := 0 to 3 do
      if mask.i[i] <> 0 then
        Result.i[i] := a.i[i]
      else
        Result.i[i] := b.i[i];
  end;
end;

function VecF32x8Select(const mask: TVecU32x8; const a, b: TVecF32x8): TVecF32x8;
var
  dispatch: PSimdDispatchTable;
  i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SelectF32x8) then
    Result := dispatch^.SelectF32x8(mask, a, b)
  else
  begin
    // 标量回退实现：掩码元素非零时选择 a
    for i := 0 to 7 do
      if mask.u[i] <> 0 then
        Result.f[i] := a.f[i]
      else
        Result.f[i] := b.f[i];
  end;
end;

function VecF64x4Select(const mask: TVecU64x4; const a, b: TVecF64x4): TVecF64x4;
var
  dispatch: PSimdDispatchTable;
  i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SelectF64x4) then
    Result := dispatch^.SelectF64x4(mask, a, b)
  else
  begin
    // 标量回退实现：掩码元素非零时选择 a
    for i := 0 to 3 do
      if mask.u[i] <> 0 then
        Result.d[i] := a.d[i]
      else
        Result.d[i] := b.d[i];
  end;
end;

// ✅ P2-2: Mask Operations Implementation
function Mask2All(mask: TMask2): Boolean;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.Mask2All(mask);
end;

function Mask2Any(mask: TMask2): Boolean;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.Mask2Any(mask);
end;

function Mask2None(mask: TMask2): Boolean;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.Mask2None(mask);
end;

function Mask2PopCount(mask: TMask2): Integer;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.Mask2PopCount(mask);
end;

function Mask2FirstSet(mask: TMask2): Integer;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.Mask2FirstSet(mask);
end;

function Mask4All(mask: TMask4): Boolean;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.Mask4All(mask);
end;

function Mask4Any(mask: TMask4): Boolean;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.Mask4Any(mask);
end;

function Mask4None(mask: TMask4): Boolean;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.Mask4None(mask);
end;

function Mask4PopCount(mask: TMask4): Integer;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.Mask4PopCount(mask);
end;

function Mask4FirstSet(mask: TMask4): Integer;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.Mask4FirstSet(mask);
end;

function Mask8All(mask: TMask8): Boolean;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.Mask8All(mask);
end;

function Mask8Any(mask: TMask8): Boolean;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.Mask8Any(mask);
end;

function Mask8None(mask: TMask8): Boolean;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.Mask8None(mask);
end;

function Mask8PopCount(mask: TMask8): Integer;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.Mask8PopCount(mask);
end;

function Mask8FirstSet(mask: TMask8): Integer;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.Mask8FirstSet(mask);
end;

function Mask16All(mask: TMask16): Boolean;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.Mask16All(mask);
end;

function Mask16Any(mask: TMask16): Boolean;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.Mask16Any(mask);
end;

function Mask16None(mask: TMask16): Boolean;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.Mask16None(mask);
end;

function Mask16PopCount(mask: TMask16): Integer;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.Mask16PopCount(mask);
end;

function Mask16FirstSet(mask: TMask16): Integer;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.Mask16FirstSet(mask);
end;

// === I32x4 Operations Implementation ===
// ✅ P0.3: I32x4 高级 API 实现

function VecI32x4Add(const a, b: TVecI32x4): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AddI32x4) then
    Result := dispatch^.AddI32x4(a, b)
  else
  begin
    Result.i[0] := a.i[0] + b.i[0];
    Result.i[1] := a.i[1] + b.i[1];
    Result.i[2] := a.i[2] + b.i[2];
    Result.i[3] := a.i[3] + b.i[3];
  end;
end;

function VecI32x4Sub(const a, b: TVecI32x4): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SubI32x4) then
    Result := dispatch^.SubI32x4(a, b)
  else
  begin
    Result.i[0] := a.i[0] - b.i[0];
    Result.i[1] := a.i[1] - b.i[1];
    Result.i[2] := a.i[2] - b.i[2];
    Result.i[3] := a.i[3] - b.i[3];
  end;
end;

function VecI32x4Mul(const a, b: TVecI32x4): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MulI32x4) then
    Result := dispatch^.MulI32x4(a, b)
  else
  begin
    Result.i[0] := a.i[0] * b.i[0];
    Result.i[1] := a.i[1] * b.i[1];
    Result.i[2] := a.i[2] * b.i[2];
    Result.i[3] := a.i[3] * b.i[3];
  end;
end;

function VecI32x4And(const a, b: TVecI32x4): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AndI32x4) then
    Result := dispatch^.AndI32x4(a, b)
  else
  begin
    Result.i[0] := a.i[0] and b.i[0];
    Result.i[1] := a.i[1] and b.i[1];
    Result.i[2] := a.i[2] and b.i[2];
    Result.i[3] := a.i[3] and b.i[3];
  end;
end;

function VecI32x4Or(const a, b: TVecI32x4): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.OrI32x4) then
    Result := dispatch^.OrI32x4(a, b)
  else
  begin
    Result.i[0] := a.i[0] or b.i[0];
    Result.i[1] := a.i[1] or b.i[1];
    Result.i[2] := a.i[2] or b.i[2];
    Result.i[3] := a.i[3] or b.i[3];
  end;
end;

function VecI32x4Xor(const a, b: TVecI32x4): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.XorI32x4) then
    Result := dispatch^.XorI32x4(a, b)
  else
  begin
    Result.i[0] := a.i[0] xor b.i[0];
    Result.i[1] := a.i[1] xor b.i[1];
    Result.i[2] := a.i[2] xor b.i[2];
    Result.i[3] := a.i[3] xor b.i[3];
  end;
end;

function VecI32x4Not(const a: TVecI32x4): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.NotI32x4) then
    Result := dispatch^.NotI32x4(a)
  else
  begin
    Result.i[0] := not a.i[0];
    Result.i[1] := not a.i[1];
    Result.i[2] := not a.i[2];
    Result.i[3] := not a.i[3];
  end;
end;

function VecI32x4AndNot(const a, b: TVecI32x4): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AndNotI32x4) then
    Result := dispatch^.AndNotI32x4(a, b)
  else
  begin
    Result.i[0] := (not a.i[0]) and b.i[0];
    Result.i[1] := (not a.i[1]) and b.i[1];
    Result.i[2] := (not a.i[2]) and b.i[2];
    Result.i[3] := (not a.i[3]) and b.i[3];
  end;
end;

function VecI32x4ShiftLeft(const a: TVecI32x4; count: Integer): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftLeftI32x4) then
    Result := dispatch^.ShiftLeftI32x4(a, count)
  else
  begin
    Result.i[0] := a.i[0] shl count;
    Result.i[1] := a.i[1] shl count;
    Result.i[2] := a.i[2] shl count;
    Result.i[3] := a.i[3] shl count;
  end;
end;

function VecI32x4ShiftRight(const a: TVecI32x4; count: Integer): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftRightI32x4) then
    Result := dispatch^.ShiftRightI32x4(a, count)
  else
  begin
    // Logical shift (unsigned)
    Result.i[0] := Int32(UInt32(a.i[0]) shr count);
    Result.i[1] := Int32(UInt32(a.i[1]) shr count);
    Result.i[2] := Int32(UInt32(a.i[2]) shr count);
    Result.i[3] := Int32(UInt32(a.i[3]) shr count);
  end;
end;

function VecI32x4ShiftRightArith(const a: TVecI32x4; count: Integer): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftRightArithI32x4) then
    Result := dispatch^.ShiftRightArithI32x4(a, count)
  else
  begin
    // Arithmetic shift (signed)
    Result.i[0] := SarLongint(a.i[0], count);
    Result.i[1] := SarLongint(a.i[1], count);
    Result.i[2] := SarLongint(a.i[2], count);
    Result.i[3] := SarLongint(a.i[3], count);
  end;
end;

function VecI32x4CmpEq(const a, b: TVecI32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpEqI32x4) then
    Result := dispatch^.CmpEqI32x4(a, b)
  else
  begin
    Result := 0;
    if a.i[0] = b.i[0] then Result := Result or 1;
    if a.i[1] = b.i[1] then Result := Result or 2;
    if a.i[2] = b.i[2] then Result := Result or 4;
    if a.i[3] = b.i[3] then Result := Result or 8;
  end;
end;

function VecI32x4CmpLt(const a, b: TVecI32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLtI32x4) then
    Result := dispatch^.CmpLtI32x4(a, b)
  else
  begin
    Result := 0;
    if a.i[0] < b.i[0] then Result := Result or 1;
    if a.i[1] < b.i[1] then Result := Result or 2;
    if a.i[2] < b.i[2] then Result := Result or 4;
    if a.i[3] < b.i[3] then Result := Result or 8;
  end;
end;

function VecI32x4CmpGt(const a, b: TVecI32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGtI32x4) then
    Result := dispatch^.CmpGtI32x4(a, b)
  else
  begin
    Result := 0;
    if a.i[0] > b.i[0] then Result := Result or 1;
    if a.i[1] > b.i[1] then Result := Result or 2;
    if a.i[2] > b.i[2] then Result := Result or 4;
    if a.i[3] > b.i[3] then Result := Result or 8;
  end;
end;

// ✅ P0-C: 添加 I32x4 缺失比较函数
function VecI32x4CmpLe(const a, b: TVecI32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLeI32x4) then
    Result := dispatch^.CmpLeI32x4(a, b)
  else
  begin
    Result := 0;
    if a.i[0] <= b.i[0] then Result := Result or 1;
    if a.i[1] <= b.i[1] then Result := Result or 2;
    if a.i[2] <= b.i[2] then Result := Result or 4;
    if a.i[3] <= b.i[3] then Result := Result or 8;
  end;
end;

function VecI32x4CmpGe(const a, b: TVecI32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGeI32x4) then
    Result := dispatch^.CmpGeI32x4(a, b)
  else
  begin
    Result := 0;
    if a.i[0] >= b.i[0] then Result := Result or 1;
    if a.i[1] >= b.i[1] then Result := Result or 2;
    if a.i[2] >= b.i[2] then Result := Result or 4;
    if a.i[3] >= b.i[3] then Result := Result or 8;
  end;
end;

function VecI32x4CmpNe(const a, b: TVecI32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpNeI32x4) then
    Result := dispatch^.CmpNeI32x4(a, b)
  else
  begin
    Result := 0;
    if a.i[0] <> b.i[0] then Result := Result or 1;
    if a.i[1] <> b.i[1] then Result := Result or 2;
    if a.i[2] <> b.i[2] then Result := Result or 4;
    if a.i[3] <> b.i[3] then Result := Result or 8;
  end;
end;

function VecI32x4Min(const a, b: TVecI32x4): TVecI32x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MinI32x4) then
    Result := dispatch^.MinI32x4(a, b)
  else
  begin
    for i := 0 to 3 do
      if a.i[i] < b.i[i] then
        Result.i[i] := a.i[i]
      else
        Result.i[i] := b.i[i];
  end;
end;

function VecI32x4Max(const a, b: TVecI32x4): TVecI32x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MaxI32x4) then
    Result := dispatch^.MaxI32x4(a, b)
  else
  begin
    for i := 0 to 3 do
      if a.i[i] > b.i[i] then
        Result.i[i] := a.i[i]
      else
        Result.i[i] := b.i[i];
  end;
end;

// === I64x2 Operations Implementation ===
// ✅ P1.3: I64x2 高级 API 实现

function VecI64x2Add(const a, b: TVecI64x2): TVecI64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AddI64x2) then
    Result := dispatch^.AddI64x2(a, b)
  else
  begin
    Result.i[0] := a.i[0] + b.i[0];
    Result.i[1] := a.i[1] + b.i[1];
  end;
end;

function VecI64x2Sub(const a, b: TVecI64x2): TVecI64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SubI64x2) then
    Result := dispatch^.SubI64x2(a, b)
  else
  begin
    Result.i[0] := a.i[0] - b.i[0];
    Result.i[1] := a.i[1] - b.i[1];
  end;
end;

function VecI64x2And(const a, b: TVecI64x2): TVecI64x2;
begin
  // Bitwise operations - scalar fallback (no dispatch entry)
  Result.i[0] := a.i[0] and b.i[0];
  Result.i[1] := a.i[1] and b.i[1];
end;

function VecI64x2Or(const a, b: TVecI64x2): TVecI64x2;
begin
  Result.i[0] := a.i[0] or b.i[0];
  Result.i[1] := a.i[1] or b.i[1];
end;

function VecI64x2Xor(const a, b: TVecI64x2): TVecI64x2;
begin
  Result.i[0] := a.i[0] xor b.i[0];
  Result.i[1] := a.i[1] xor b.i[1];
end;

function VecI64x2Not(const a: TVecI64x2): TVecI64x2;
begin
  Result.i[0] := not a.i[0];
  Result.i[1] := not a.i[1];
end;

function VecI64x2AndNot(const a, b: TVecI64x2): TVecI64x2;
begin
  // (~a) and b
  Result.i[0] := (not a.i[0]) and b.i[0];
  Result.i[1] := (not a.i[1]) and b.i[1];
end;

// ✅ P5.2: I64x2 完整 API 实现 - 移位/比较/Min/Max

function VecI64x2ShiftLeft(const a: TVecI64x2; count: Integer): TVecI64x2;
begin
  Result.i[0] := a.i[0] shl count;
  Result.i[1] := a.i[1] shl count;
end;

function VecI64x2ShiftRight(const a: TVecI64x2; count: Integer): TVecI64x2;
begin
  // 逻辑右移 (无符号)
  Result.i[0] := Int64(UInt64(a.i[0]) shr count);
  Result.i[1] := Int64(UInt64(a.i[1]) shr count);
end;

function VecI64x2ShiftRightArith(const a: TVecI64x2; count: Integer): TVecI64x2;
begin
  // 算术右移 (保留符号位)
  Result.i[0] := SarInt64(a.i[0], count);
  Result.i[1] := SarInt64(a.i[1], count);
end;

function VecI64x2CmpEq(const a, b: TVecI64x2): TMask2;
begin
  Result := 0;
  if a.i[0] = b.i[0] then Result := Result or 1;
  if a.i[1] = b.i[1] then Result := Result or 2;
end;

function VecI64x2CmpLt(const a, b: TVecI64x2): TMask2;
begin
  Result := 0;
  if a.i[0] < b.i[0] then Result := Result or 1;
  if a.i[1] < b.i[1] then Result := Result or 2;
end;

function VecI64x2CmpGt(const a, b: TVecI64x2): TMask2;
begin
  Result := 0;
  if a.i[0] > b.i[0] then Result := Result or 1;
  if a.i[1] > b.i[1] then Result := Result or 2;
end;

// ✅ P0-C: 添加 I64x2 缺失比较函数
function VecI64x2CmpLe(const a, b: TVecI64x2): TMask2;
begin
  Result := 0;
  if a.i[0] <= b.i[0] then Result := Result or 1;
  if a.i[1] <= b.i[1] then Result := Result or 2;
end;

function VecI64x2CmpGe(const a, b: TVecI64x2): TMask2;
begin
  Result := 0;
  if a.i[0] >= b.i[0] then Result := Result or 1;
  if a.i[1] >= b.i[1] then Result := Result or 2;
end;

function VecI64x2CmpNe(const a, b: TVecI64x2): TMask2;
begin
  Result := 0;
  if a.i[0] <> b.i[0] then Result := Result or 1;
  if a.i[1] <> b.i[1] then Result := Result or 2;
end;

function VecI64x2Min(const a, b: TVecI64x2): TVecI64x2;
begin
  if a.i[0] < b.i[0] then Result.i[0] := a.i[0] else Result.i[0] := b.i[0];
  if a.i[1] < b.i[1] then Result.i[1] := a.i[1] else Result.i[1] := b.i[1];
end;

function VecI64x2Max(const a, b: TVecI64x2): TVecI64x2;
begin
  if a.i[0] > b.i[0] then Result.i[0] := a.i[0] else Result.i[0] := b.i[0];
  if a.i[1] > b.i[1] then Result.i[1] := a.i[1] else Result.i[1] := b.i[1];
end;

// === U64x2 Operations Implementation ===
// ✅ P3.3: U64x2 (128-bit, 2x UInt64) 高级 API 实现

function VecU64x2Add(const a, b: TVecU64x2): TVecU64x2;
begin
  Result.u[0] := a.u[0] + b.u[0];
  Result.u[1] := a.u[1] + b.u[1];
end;

function VecU64x2Sub(const a, b: TVecU64x2): TVecU64x2;
begin
  Result.u[0] := a.u[0] - b.u[0];
  Result.u[1] := a.u[1] - b.u[1];
end;

function VecU64x2And(const a, b: TVecU64x2): TVecU64x2;
begin
  Result.u[0] := a.u[0] and b.u[0];
  Result.u[1] := a.u[1] and b.u[1];
end;

function VecU64x2Or(const a, b: TVecU64x2): TVecU64x2;
begin
  Result.u[0] := a.u[0] or b.u[0];
  Result.u[1] := a.u[1] or b.u[1];
end;

function VecU64x2Xor(const a, b: TVecU64x2): TVecU64x2;
begin
  Result.u[0] := a.u[0] xor b.u[0];
  Result.u[1] := a.u[1] xor b.u[1];
end;

function VecU64x2Not(const a: TVecU64x2): TVecU64x2;
begin
  Result.u[0] := not a.u[0];
  Result.u[1] := not a.u[1];
end;

function VecU64x2AndNot(const a, b: TVecU64x2): TVecU64x2;
begin
  // (~a) and b
  Result.u[0] := (not a.u[0]) and b.u[0];
  Result.u[1] := (not a.u[1]) and b.u[1];
end;

function VecU64x2CmpEq(const a, b: TVecU64x2): TMask2;
begin
  Result := 0;
  if a.u[0] = b.u[0] then Result := Result or 1;
  if a.u[1] = b.u[1] then Result := Result or 2;
end;

function VecU64x2CmpLt(const a, b: TVecU64x2): TMask2;
begin
  Result := 0;
  if a.u[0] < b.u[0] then Result := Result or 1;  // 无符号比较
  if a.u[1] < b.u[1] then Result := Result or 2;
end;

function VecU64x2CmpGt(const a, b: TVecU64x2): TMask2;
begin
  Result := 0;
  if a.u[0] > b.u[0] then Result := Result or 1;  // 无符号比较
  if a.u[1] > b.u[1] then Result := Result or 2;
end;

function VecU64x2Min(const a, b: TVecU64x2): TVecU64x2;
begin
  if a.u[0] < b.u[0] then Result.u[0] := a.u[0] else Result.u[0] := b.u[0];
  if a.u[1] < b.u[1] then Result.u[1] := a.u[1] else Result.u[1] := b.u[1];
end;

function VecU64x2Max(const a, b: TVecU64x2): TVecU64x2;
begin
  if a.u[0] > b.u[0] then Result.u[0] := a.u[0] else Result.u[0] := b.u[0];
  if a.u[1] > b.u[1] then Result.u[1] := a.u[1] else Result.u[1] := b.u[1];
end;

// === U32x4 Operations Implementation ===
// ✅ P2.1: U32x4 (128-bit Unsigned) 高级 API 实现
// ✅ 修改为使用 dispatch table 以获得 SIMD 加速
// 注意: 无符号整数 SIMD 操作在位层面与有符号相同,
//       区别在于比较和 min/max 使用无符号语义

function VecU32x4Add(const a, b: TVecU32x4): TVecU32x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AddU32x4) then
    Result := dispatch^.AddU32x4(a, b)
  else
    for i := 0 to 3 do
      Result.u[i] := a.u[i] + b.u[i];
end;

function VecU32x4Sub(const a, b: TVecU32x4): TVecU32x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SubU32x4) then
    Result := dispatch^.SubU32x4(a, b)
  else
    for i := 0 to 3 do
      Result.u[i] := a.u[i] - b.u[i];
end;

function VecU32x4Mul(const a, b: TVecU32x4): TVecU32x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MulU32x4) then
    Result := dispatch^.MulU32x4(a, b)
  else
    for i := 0 to 3 do
      Result.u[i] := a.u[i] * b.u[i];
end;

function VecU32x4And(const a, b: TVecU32x4): TVecU32x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AndU32x4) then
    Result := dispatch^.AndU32x4(a, b)
  else
    for i := 0 to 3 do
      Result.u[i] := a.u[i] and b.u[i];
end;

function VecU32x4Or(const a, b: TVecU32x4): TVecU32x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.OrU32x4) then
    Result := dispatch^.OrU32x4(a, b)
  else
    for i := 0 to 3 do
      Result.u[i] := a.u[i] or b.u[i];
end;

function VecU32x4Xor(const a, b: TVecU32x4): TVecU32x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.XorU32x4) then
    Result := dispatch^.XorU32x4(a, b)
  else
    for i := 0 to 3 do
      Result.u[i] := a.u[i] xor b.u[i];
end;

function VecU32x4Not(const a: TVecU32x4): TVecU32x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.NotU32x4) then
    Result := dispatch^.NotU32x4(a)
  else
    for i := 0 to 3 do
      Result.u[i] := not a.u[i];
end;

function VecU32x4AndNot(const a, b: TVecU32x4): TVecU32x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AndNotU32x4) then
    Result := dispatch^.AndNotU32x4(a, b)
  else
    for i := 0 to 3 do
      Result.u[i] := (not a.u[i]) and b.u[i];
end;

function VecU32x4ShiftLeft(const a: TVecU32x4; count: Integer): TVecU32x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftLeftU32x4) then
    Result := dispatch^.ShiftLeftU32x4(a, count)
  else
    for i := 0 to 3 do
      Result.u[i] := a.u[i] shl count;
end;

function VecU32x4ShiftRight(const a: TVecU32x4; count: Integer): TVecU32x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftRightU32x4) then
    Result := dispatch^.ShiftRightU32x4(a, count)
  else
    for i := 0 to 3 do
      Result.u[i] := a.u[i] shr count;  // 逻辑右移 (无符号)
end;

function VecU32x4CmpEq(const a, b: TVecU32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpEqU32x4) then
    Result := dispatch^.CmpEqU32x4(a, b)
  else
  begin
    Result := 0;
    if a.u[0] = b.u[0] then Result := Result or 1;
    if a.u[1] = b.u[1] then Result := Result or 2;
    if a.u[2] = b.u[2] then Result := Result or 4;
    if a.u[3] = b.u[3] then Result := Result or 8;
  end;
end;

function VecU32x4CmpLt(const a, b: TVecU32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLtU32x4) then
    Result := dispatch^.CmpLtU32x4(a, b)
  else
  begin
    Result := 0;
    if a.u[0] < b.u[0] then Result := Result or 1;
    if a.u[1] < b.u[1] then Result := Result or 2;
    if a.u[2] < b.u[2] then Result := Result or 4;
    if a.u[3] < b.u[3] then Result := Result or 8;
  end;
end;

function VecU32x4CmpGt(const a, b: TVecU32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGtU32x4) then
    Result := dispatch^.CmpGtU32x4(a, b)
  else
  begin
    Result := 0;
    if a.u[0] > b.u[0] then Result := Result or 1;
    if a.u[1] > b.u[1] then Result := Result or 2;
    if a.u[2] > b.u[2] then Result := Result or 4;
    if a.u[3] > b.u[3] then Result := Result or 8;
  end;
end;

function VecU32x4CmpLe(const a, b: TVecU32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLeU32x4) then
    Result := dispatch^.CmpLeU32x4(a, b)
  else
  begin
    Result := 0;
    if a.u[0] <= b.u[0] then Result := Result or 1;
    if a.u[1] <= b.u[1] then Result := Result or 2;
    if a.u[2] <= b.u[2] then Result := Result or 4;
    if a.u[3] <= b.u[3] then Result := Result or 8;
  end;
end;

function VecU32x4CmpGe(const a, b: TVecU32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGeU32x4) then
    Result := dispatch^.CmpGeU32x4(a, b)
  else
  begin
    Result := 0;
    if a.u[0] >= b.u[0] then Result := Result or 1;
    if a.u[1] >= b.u[1] then Result := Result or 2;
    if a.u[2] >= b.u[2] then Result := Result or 4;
    if a.u[3] >= b.u[3] then Result := Result or 8;
  end;
end;

function VecU32x4Min(const a, b: TVecU32x4): TVecU32x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MinU32x4) then
    Result := dispatch^.MinU32x4(a, b)
  else
    for i := 0 to 3 do
      if a.u[i] < b.u[i] then
        Result.u[i] := a.u[i]
      else
        Result.u[i] := b.u[i];
end;

function VecU32x4Max(const a, b: TVecU32x4): TVecU32x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MaxU32x4) then
    Result := dispatch^.MaxU32x4(a, b)
  else
    for i := 0 to 3 do
      if a.u[i] > b.u[i] then
        Result.u[i] := a.u[i]
      else
        Result.u[i] := b.u[i];
end;

// === F32x8 Operations Implementation ===
// ✅ P0.3: F32x8 (256-bit) 高级 API 实现

function VecF32x8Add(const a, b: TVecF32x8): TVecF32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AddF32x8) then
    Result := dispatch^.AddF32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.f[i] := a.f[i] + b.f[i];
  end;
end;

function VecF32x8Sub(const a, b: TVecF32x8): TVecF32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SubF32x8) then
    Result := dispatch^.SubF32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.f[i] := a.f[i] - b.f[i];
  end;
end;

function VecF32x8Mul(const a, b: TVecF32x8): TVecF32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MulF32x8) then
    Result := dispatch^.MulF32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.f[i] := a.f[i] * b.f[i];
  end;
end;

function VecF32x8Div(const a, b: TVecF32x8): TVecF32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.DivF32x8) then
    Result := dispatch^.DivF32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.f[i] := a.f[i] / b.f[i];
  end;
end;

function VecF32x8CmpEq(const a, b: TVecF32x8): TMask8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpEqF32x8) then
    Result := dispatch^.CmpEqF32x8(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 7 do
      if a.f[i] = b.f[i] then Result := Result or (1 shl i);
  end;
end;

function VecF32x8CmpLt(const a, b: TVecF32x8): TMask8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLtF32x8) then
    Result := dispatch^.CmpLtF32x8(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 7 do
      if a.f[i] < b.f[i] then Result := Result or (1 shl i);
  end;
end;

function VecF32x8CmpLe(const a, b: TVecF32x8): TMask8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLeF32x8) then
    Result := dispatch^.CmpLeF32x8(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 7 do
      if a.f[i] <= b.f[i] then Result := Result or (1 shl i);
  end;
end;

function VecF32x8CmpGt(const a, b: TVecF32x8): TMask8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGtF32x8) then
    Result := dispatch^.CmpGtF32x8(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 7 do
      if a.f[i] > b.f[i] then Result := Result or (1 shl i);
  end;
end;

function VecF32x8CmpGe(const a, b: TVecF32x8): TMask8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGeF32x8) then
    Result := dispatch^.CmpGeF32x8(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 7 do
      if a.f[i] >= b.f[i] then Result := Result or (1 shl i);
  end;
end;

function VecF32x8CmpNe(const a, b: TVecF32x8): TMask8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpNeF32x8) then
    Result := dispatch^.CmpNeF32x8(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 7 do
      if a.f[i] <> b.f[i] then Result := Result or (1 shl i);
  end;
end;

function VecF32x8Abs(const a: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := Abs(a.f[i]);
end;

function VecF32x8Sqrt(const a: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := Sqrt(a.f[i]);
end;

function VecF32x8Min(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.f[i] < b.f[i] then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function VecF32x8Max(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.f[i] > b.f[i] then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function VecF32x8ReduceAdd(const a: TVecF32x8): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 7 do
    Result := Result + a.f[i];
end;

function VecF32x8ReduceMin(const a: TVecF32x8): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 7 do
    if a.f[i] < Result then Result := a.f[i];
end;

function VecF32x8ReduceMax(const a: TVecF32x8): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 7 do
    if a.f[i] > Result then Result := a.f[i];
end;

function VecF32x8ReduceMul(const a: TVecF32x8): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 7 do
    Result := Result * a.f[i];
end;

// === I32x8 Operations Implementation ===
// ✅ P1.1: I32x8 高级 API 实现

function VecI32x8Add(const a, b: TVecI32x8): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AddI32x8) then
    Result := dispatch^.AddI32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := a.i[i] + b.i[i];
  end;
end;

function VecI32x8Sub(const a, b: TVecI32x8): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SubI32x8) then
    Result := dispatch^.SubI32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := a.i[i] - b.i[i];
  end;
end;

function VecI32x8Mul(const a, b: TVecI32x8): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MulI32x8) then
    Result := dispatch^.MulI32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := a.i[i] * b.i[i];
  end;
end;

function VecI32x8And(const a, b: TVecI32x8): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AndI32x8) then
    Result := dispatch^.AndI32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := a.i[i] and b.i[i];
  end;
end;

function VecI32x8Or(const a, b: TVecI32x8): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.OrI32x8) then
    Result := dispatch^.OrI32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := a.i[i] or b.i[i];
  end;
end;

function VecI32x8Xor(const a, b: TVecI32x8): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.XorI32x8) then
    Result := dispatch^.XorI32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := a.i[i] xor b.i[i];
  end;
end;

function VecI32x8Not(const a: TVecI32x8): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.NotI32x8) then
    Result := dispatch^.NotI32x8(a)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := not a.i[i];
  end;
end;

function VecI32x8AndNot(const a, b: TVecI32x8): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AndNotI32x8) then
    Result := dispatch^.AndNotI32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := (not a.i[i]) and b.i[i];
  end;
end;

function VecI32x8ShiftLeft(const a: TVecI32x8; count: Integer): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftLeftI32x8) then
    Result := dispatch^.ShiftLeftI32x8(a, count)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := a.i[i] shl count;
  end;
end;

function VecI32x8ShiftRight(const a: TVecI32x8; count: Integer): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftRightI32x8) then
    Result := dispatch^.ShiftRightI32x8(a, count)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := Int32(UInt32(a.i[i]) shr count);
  end;
end;

function VecI32x8ShiftRightArith(const a: TVecI32x8; count: Integer): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftRightArithI32x8) then
    Result := dispatch^.ShiftRightArithI32x8(a, count)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := SarLongint(a.i[i], count);
  end;
end;

function VecI32x8CmpEq(const a, b: TVecI32x8): TMask8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpEqI32x8) then
    Result := dispatch^.CmpEqI32x8(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 7 do
      if a.i[i] = b.i[i] then Result := Result or (1 shl i);
  end;
end;

function VecI32x8CmpLt(const a, b: TVecI32x8): TMask8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLtI32x8) then
    Result := dispatch^.CmpLtI32x8(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 7 do
      if a.i[i] < b.i[i] then Result := Result or (1 shl i);
  end;
end;

function VecI32x8CmpGt(const a, b: TVecI32x8): TMask8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGtI32x8) then
    Result := dispatch^.CmpGtI32x8(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 7 do
      if a.i[i] > b.i[i] then Result := Result or (1 shl i);
  end;
end;

// ✅ P0-C: 添加 I32x8 缺失比较函数
function VecI32x8CmpLe(const a, b: TVecI32x8): TMask8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLeI32x8) then
    Result := dispatch^.CmpLeI32x8(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 7 do
      if a.i[i] <= b.i[i] then Result := Result or (1 shl i);
  end;
end;

function VecI32x8CmpGe(const a, b: TVecI32x8): TMask8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGeI32x8) then
    Result := dispatch^.CmpGeI32x8(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 7 do
      if a.i[i] >= b.i[i] then Result := Result or (1 shl i);
  end;
end;

function VecI32x8CmpNe(const a, b: TVecI32x8): TMask8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpNeI32x8) then
    Result := dispatch^.CmpNeI32x8(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 7 do
      if a.i[i] <> b.i[i] then Result := Result or (1 shl i);
  end;
end;

function VecI32x8Min(const a, b: TVecI32x8): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MinI32x8) then
    Result := dispatch^.MinI32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      if a.i[i] < b.i[i] then
        Result.i[i] := a.i[i]
      else
        Result.i[i] := b.i[i];
  end;
end;

function VecI32x8Max(const a, b: TVecI32x8): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MaxI32x8) then
    Result := dispatch^.MaxI32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      if a.i[i] > b.i[i] then
        Result.i[i] := a.i[i]
      else
        Result.i[i] := b.i[i];
  end;
end;

// === U32x8 Operations Implementation ===
// ✅ P2.1: U32x8 (256-bit Unsigned) 高级 API 实现

function VecU32x8Add(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] + b.u[i];
end;

function VecU32x8Sub(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] - b.u[i];
end;

function VecU32x8Mul(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] * b.u[i];
end;

function VecU32x8And(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] and b.u[i];
end;

function VecU32x8Or(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] or b.u[i];
end;

function VecU32x8Xor(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] xor b.u[i];
end;

function VecU32x8Not(const a: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := not a.u[i];
end;

function VecU32x8AndNot(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := (not a.u[i]) and b.u[i];
end;

function VecU32x8ShiftLeft(const a: TVecU32x8; count: Integer): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] shl count;
end;

function VecU32x8ShiftRight(const a: TVecU32x8; count: Integer): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] shr count;  // 逻辑右移 (无符号)
end;

function VecU32x8CmpEq(const a, b: TVecU32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] = b.u[i] then Result := Result or (1 shl i);
end;

function VecU32x8CmpLt(const a, b: TVecU32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] < b.u[i] then Result := Result or (1 shl i);
end;

function VecU32x8CmpGt(const a, b: TVecU32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] > b.u[i] then Result := Result or (1 shl i);
end;

function VecU32x8CmpLe(const a, b: TVecU32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] <= b.u[i] then Result := Result or (1 shl i);
end;

function VecU32x8CmpGe(const a, b: TVecU32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] >= b.u[i] then Result := Result or (1 shl i);
end;

function VecU32x8Min(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.u[i] < b.u[i] then
      Result.u[i] := a.u[i]
    else
      Result.u[i] := b.u[i];
end;

function VecU32x8Max(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.u[i] > b.u[i] then
      Result.u[i] := a.u[i]
    else
      Result.u[i] := b.u[i];
end;

// === I64x4 Operations Implementation ===
// ✅ Task 5.2: I64x4 (256-bit, 4x64-bit signed) 高级 API 实现
// 使用 dispatch table 以获得 AVX2 加速

function VecI64x4Add(const a, b: TVecI64x4): TVecI64x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AddI64x4) then
    Result := dispatch^.AddI64x4(a, b)
  else
    for i := 0 to 3 do
      Result.i[i] := a.i[i] + b.i[i];
end;

function VecI64x4Sub(const a, b: TVecI64x4): TVecI64x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SubI64x4) then
    Result := dispatch^.SubI64x4(a, b)
  else
    for i := 0 to 3 do
      Result.i[i] := a.i[i] - b.i[i];
end;

function VecI64x4And(const a, b: TVecI64x4): TVecI64x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AndI64x4) then
    Result := dispatch^.AndI64x4(a, b)
  else
    for i := 0 to 3 do
      Result.i[i] := a.i[i] and b.i[i];
end;

function VecI64x4Or(const a, b: TVecI64x4): TVecI64x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.OrI64x4) then
    Result := dispatch^.OrI64x4(a, b)
  else
    for i := 0 to 3 do
      Result.i[i] := a.i[i] or b.i[i];
end;

function VecI64x4Xor(const a, b: TVecI64x4): TVecI64x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.XorI64x4) then
    Result := dispatch^.XorI64x4(a, b)
  else
    for i := 0 to 3 do
      Result.i[i] := a.i[i] xor b.i[i];
end;

function VecI64x4Not(const a: TVecI64x4): TVecI64x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.NotI64x4) then
    Result := dispatch^.NotI64x4(a)
  else
    for i := 0 to 3 do
      Result.i[i] := not a.i[i];
end;

function VecI64x4AndNot(const a, b: TVecI64x4): TVecI64x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AndNotI64x4) then
    Result := dispatch^.AndNotI64x4(a, b)
  else
    for i := 0 to 3 do
      Result.i[i] := (not a.i[i]) and b.i[i];
end;

function VecI64x4ShiftLeft(const a: TVecI64x4; count: Integer): TVecI64x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftLeftI64x4) then
    Result := dispatch^.ShiftLeftI64x4(a, count)
  else
    for i := 0 to 3 do
      if (count >= 0) and (count < 64) then
        Result.i[i] := a.i[i] shl count
      else
        Result.i[i] := 0;
end;

function VecI64x4ShiftRight(const a: TVecI64x4; count: Integer): TVecI64x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftRightI64x4) then
    Result := dispatch^.ShiftRightI64x4(a, count)
  else
    for i := 0 to 3 do
      if (count >= 0) and (count < 64) then
        Result.i[i] := Int64(UInt64(a.i[i]) shr count)  // logical shift
      else
        Result.i[i] := 0;
end;

function VecI64x4CmpEq(const a, b: TVecI64x4): TMask4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpEqI64x4) then
    Result := dispatch^.CmpEqI64x4(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 3 do
      if a.i[i] = b.i[i] then
        Result := Result or (1 shl i);
  end;
end;

function VecI64x4CmpLt(const a, b: TVecI64x4): TMask4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLtI64x4) then
    Result := dispatch^.CmpLtI64x4(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 3 do
      if a.i[i] < b.i[i] then
        Result := Result or (1 shl i);
  end;
end;

function VecI64x4CmpGt(const a, b: TVecI64x4): TMask4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGtI64x4) then
    Result := dispatch^.CmpGtI64x4(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 3 do
      if a.i[i] > b.i[i] then
        Result := Result or (1 shl i);
  end;
end;

function VecI64x4CmpLe(const a, b: TVecI64x4): TMask4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLeI64x4) then
    Result := dispatch^.CmpLeI64x4(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 3 do
      if a.i[i] <= b.i[i] then
        Result := Result or (1 shl i);
  end;
end;

function VecI64x4CmpGe(const a, b: TVecI64x4): TMask4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGeI64x4) then
    Result := dispatch^.CmpGeI64x4(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 3 do
      if a.i[i] >= b.i[i] then
        Result := Result or (1 shl i);
  end;
end;

function VecI64x4CmpNe(const a, b: TVecI64x4): TMask4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpNeI64x4) then
    Result := dispatch^.CmpNeI64x4(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 3 do
      if a.i[i] <> b.i[i] then
        Result := Result or (1 shl i);
  end;
end;

function VecI64x4Load(p: PInt64): TVecI64x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.LoadI64x4) then
    Result := dispatch^.LoadI64x4(p)
  else
    for i := 0 to 3 do
      Result.i[i] := (p + i)^;
end;

procedure VecI64x4Store(p: PInt64; const a: TVecI64x4);
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.StoreI64x4) then
    dispatch^.StoreI64x4(p, a)
  else
    for i := 0 to 3 do
      (p + i)^ := a.i[i];
end;

function VecI64x4Splat(value: Int64): TVecI64x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SplatI64x4) then
    Result := dispatch^.SplatI64x4(value)
  else
    for i := 0 to 3 do
      Result.i[i] := value;
end;

function VecI64x4Zero: TVecI64x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ZeroI64x4) then
    Result := dispatch^.ZeroI64x4()
  else
    for i := 0 to 3 do
      Result.i[i] := 0;
end;

// === U64x4 Operations Implementation ===
// ✅ Task 5.2: U64x4 (256-bit, 4x64-bit unsigned) 高级 API 实现
// 使用 dispatch table 以获得 AVX2 加速

function VecU64x4Add(const a, b: TVecU64x4): TVecU64x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AddU64x4) then
    Result := dispatch^.AddU64x4(a, b)
  else
    for i := 0 to 3 do
      Result.u[i] := a.u[i] + b.u[i];
end;

function VecU64x4Sub(const a, b: TVecU64x4): TVecU64x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SubU64x4) then
    Result := dispatch^.SubU64x4(a, b)
  else
    for i := 0 to 3 do
      Result.u[i] := a.u[i] - b.u[i];
end;

function VecU64x4And(const a, b: TVecU64x4): TVecU64x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AndU64x4) then
    Result := dispatch^.AndU64x4(a, b)
  else
    for i := 0 to 3 do
      Result.u[i] := a.u[i] and b.u[i];
end;

function VecU64x4Or(const a, b: TVecU64x4): TVecU64x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.OrU64x4) then
    Result := dispatch^.OrU64x4(a, b)
  else
    for i := 0 to 3 do
      Result.u[i] := a.u[i] or b.u[i];
end;

function VecU64x4Xor(const a, b: TVecU64x4): TVecU64x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.XorU64x4) then
    Result := dispatch^.XorU64x4(a, b)
  else
    for i := 0 to 3 do
      Result.u[i] := a.u[i] xor b.u[i];
end;

function VecU64x4Not(const a: TVecU64x4): TVecU64x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.NotU64x4) then
    Result := dispatch^.NotU64x4(a)
  else
    for i := 0 to 3 do
      Result.u[i] := not a.u[i];
end;

function VecU64x4ShiftLeft(const a: TVecU64x4; count: Integer): TVecU64x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftLeftU64x4) then
    Result := dispatch^.ShiftLeftU64x4(a, count)
  else
    for i := 0 to 3 do
      if (count >= 0) and (count < 64) then
        Result.u[i] := a.u[i] shl count
      else
        Result.u[i] := 0;
end;

function VecU64x4ShiftRight(const a: TVecU64x4; count: Integer): TVecU64x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftRightU64x4) then
    Result := dispatch^.ShiftRightU64x4(a, count)
  else
    for i := 0 to 3 do
      if (count >= 0) and (count < 64) then
        Result.u[i] := a.u[i] shr count
      else
        Result.u[i] := 0;
end;

function VecU64x4CmpEq(const a, b: TVecU64x4): TMask4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpEqU64x4) then
    Result := dispatch^.CmpEqU64x4(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 3 do
      if a.u[i] = b.u[i] then
        Result := Result or (1 shl i);
  end;
end;

function VecU64x4CmpLt(const a, b: TVecU64x4): TMask4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLtU64x4) then
    Result := dispatch^.CmpLtU64x4(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 3 do
      if a.u[i] < b.u[i] then
        Result := Result or (1 shl i);
  end;
end;

function VecU64x4CmpGt(const a, b: TVecU64x4): TMask4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGtU64x4) then
    Result := dispatch^.CmpGtU64x4(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 3 do
      if a.u[i] > b.u[i] then
        Result := Result or (1 shl i);
  end;
end;

function VecU64x4CmpLe(const a, b: TVecU64x4): TMask4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLeU64x4) then
    Result := dispatch^.CmpLeU64x4(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 3 do
      if a.u[i] <= b.u[i] then
        Result := Result or (1 shl i);
  end;
end;

function VecU64x4CmpGe(const a, b: TVecU64x4): TMask4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGeU64x4) then
    Result := dispatch^.CmpGeU64x4(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 3 do
      if a.u[i] >= b.u[i] then
        Result := Result or (1 shl i);
  end;
end;

function VecU64x4CmpNe(const a, b: TVecU64x4): TMask4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpNeU64x4) then
    Result := dispatch^.CmpNeU64x4(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 3 do
      if a.u[i] <> b.u[i] then
        Result := Result or (1 shl i);
  end;
end;

function VecU64x4Splat(value: UInt64): TVecU64x4;
var i: Integer;
begin
  // U64x4 Splat 目前没有 dispatch 条目，使用直接实现
  for i := 0 to 3 do
    Result.u[i] := value;
end;

function VecU64x4Zero: TVecU64x4;
var i: Integer;
begin
  // U64x4 Zero 目前没有 dispatch 条目，使用直接实现
  for i := 0 to 3 do
    Result.u[i] := 0;
end;

// === I16x8 Operations Implementation ===
// ✅ P2.2: I16x8 (128-bit, 8x16-bit signed) 高级 API 实现
// ✅ 修改为使用 dispatch table 以获得 SIMD 加速

function VecI16x8Add(const a, b: TVecI16x8): TVecI16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AddI16x8) then
    Result := dispatch^.AddI16x8(a, b)
  else
    for i := 0 to 7 do
      Result.i[i] := a.i[i] + b.i[i];
end;

function VecI16x8Sub(const a, b: TVecI16x8): TVecI16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SubI16x8) then
    Result := dispatch^.SubI16x8(a, b)
  else
    for i := 0 to 7 do
      Result.i[i] := a.i[i] - b.i[i];
end;

function VecI16x8Mul(const a, b: TVecI16x8): TVecI16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MulI16x8) then
    Result := dispatch^.MulI16x8(a, b)
  else
    for i := 0 to 7 do
      Result.i[i] := a.i[i] * b.i[i];
end;

function VecI16x8And(const a, b: TVecI16x8): TVecI16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AndI16x8) then
    Result := dispatch^.AndI16x8(a, b)
  else
    for i := 0 to 7 do
      Result.i[i] := a.i[i] and b.i[i];
end;

function VecI16x8Or(const a, b: TVecI16x8): TVecI16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.OrI16x8) then
    Result := dispatch^.OrI16x8(a, b)
  else
    for i := 0 to 7 do
      Result.i[i] := a.i[i] or b.i[i];
end;

function VecI16x8Xor(const a, b: TVecI16x8): TVecI16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.XorI16x8) then
    Result := dispatch^.XorI16x8(a, b)
  else
    for i := 0 to 7 do
      Result.i[i] := a.i[i] xor b.i[i];
end;

function VecI16x8Not(const a: TVecI16x8): TVecI16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.NotI16x8) then
    Result := dispatch^.NotI16x8(a)
  else
    for i := 0 to 7 do
      Result.i[i] := not a.i[i];
end;

function VecI16x8AndNot(const a, b: TVecI16x8): TVecI16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AndNotI16x8) then
    Result := dispatch^.AndNotI16x8(a, b)
  else
    for i := 0 to 7 do
      Result.i[i] := (not a.i[i]) and b.i[i];
end;

function VecI16x8ShiftLeft(const a: TVecI16x8; count: Integer): TVecI16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftLeftI16x8) then
    Result := dispatch^.ShiftLeftI16x8(a, count)
  else
    for i := 0 to 7 do
      Result.i[i] := a.i[i] shl count;
end;

function VecI16x8ShiftRight(const a: TVecI16x8; count: Integer): TVecI16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftRightI16x8) then
    Result := dispatch^.ShiftRightI16x8(a, count)
  else
    for i := 0 to 7 do
      Result.i[i] := Int16(UInt16(a.i[i]) shr count);  // 逻辑右移
end;

function VecI16x8ShiftRightArith(const a: TVecI16x8; count: Integer): TVecI16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftRightArithI16x8) then
    Result := dispatch^.ShiftRightArithI16x8(a, count)
  else
    for i := 0 to 7 do
      Result.i[i] := SarSmallint(a.i[i], count);  // 算术右移 (保留符号位)
end;

function VecI16x8CmpEq(const a, b: TVecI16x8): TMask8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpEqI16x8) then
    Result := dispatch^.CmpEqI16x8(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 7 do
      if a.i[i] = b.i[i] then Result := Result or (1 shl i);
  end;
end;

function VecI16x8CmpLt(const a, b: TVecI16x8): TMask8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLtI16x8) then
    Result := dispatch^.CmpLtI16x8(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 7 do
      if a.i[i] < b.i[i] then Result := Result or (1 shl i);
  end;
end;

function VecI16x8CmpGt(const a, b: TVecI16x8): TMask8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGtI16x8) then
    Result := dispatch^.CmpGtI16x8(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 7 do
      if a.i[i] > b.i[i] then Result := Result or (1 shl i);
  end;
end;

function VecI16x8Min(const a, b: TVecI16x8): TVecI16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MinI16x8) then
    Result := dispatch^.MinI16x8(a, b)
  else
    for i := 0 to 7 do
      if a.i[i] < b.i[i] then
        Result.i[i] := a.i[i]
      else
        Result.i[i] := b.i[i];
end;

function VecI16x8Max(const a, b: TVecI16x8): TVecI16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MaxI16x8) then
    Result := dispatch^.MaxI16x8(a, b)
  else
    for i := 0 to 7 do
      if a.i[i] > b.i[i] then
        Result.i[i] := a.i[i]
      else
        Result.i[i] := b.i[i];
end;

// === I8x16 Operations Implementation ===
// ✅ P2.2: I8x16 (128-bit, 16x8-bit signed) 高级 API 实现
// ✅ 修改为使用 dispatch table 以获得 SIMD 加速

function VecI8x16Add(const a, b: TVecI8x16): TVecI8x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AddI8x16) then
    Result := dispatch^.AddI8x16(a, b)
  else
    for i := 0 to 15 do
      Result.i[i] := a.i[i] + b.i[i];
end;

function VecI8x16Sub(const a, b: TVecI8x16): TVecI8x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SubI8x16) then
    Result := dispatch^.SubI8x16(a, b)
  else
    for i := 0 to 15 do
      Result.i[i] := a.i[i] - b.i[i];
end;

function VecI8x16And(const a, b: TVecI8x16): TVecI8x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AndI8x16) then
    Result := dispatch^.AndI8x16(a, b)
  else
    for i := 0 to 15 do
      Result.i[i] := a.i[i] and b.i[i];
end;

function VecI8x16Or(const a, b: TVecI8x16): TVecI8x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.OrI8x16) then
    Result := dispatch^.OrI8x16(a, b)
  else
    for i := 0 to 15 do
      Result.i[i] := a.i[i] or b.i[i];
end;

function VecI8x16Xor(const a, b: TVecI8x16): TVecI8x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.XorI8x16) then
    Result := dispatch^.XorI8x16(a, b)
  else
    for i := 0 to 15 do
      Result.i[i] := a.i[i] xor b.i[i];
end;

function VecI8x16Not(const a: TVecI8x16): TVecI8x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.NotI8x16) then
    Result := dispatch^.NotI8x16(a)
  else
    for i := 0 to 15 do
      Result.i[i] := not a.i[i];
end;

function VecI8x16AndNot(const a, b: TVecI8x16): TVecI8x16;
var i: Integer;
begin
  // Note: AndNotI8x16 not in dispatch table, use scalar fallback
  for i := 0 to 15 do
    Result.i[i] := (not a.i[i]) and b.i[i];
end;

function VecI8x16CmpEq(const a, b: TVecI8x16): TMask16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpEqI8x16) then
    Result := dispatch^.CmpEqI8x16(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 15 do
      if a.i[i] = b.i[i] then Result := Result or (1 shl i);
  end;
end;

function VecI8x16CmpLt(const a, b: TVecI8x16): TMask16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLtI8x16) then
    Result := dispatch^.CmpLtI8x16(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 15 do
      if a.i[i] < b.i[i] then Result := Result or (1 shl i);
  end;
end;

function VecI8x16CmpGt(const a, b: TVecI8x16): TMask16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGtI8x16) then
    Result := dispatch^.CmpGtI8x16(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 15 do
      if a.i[i] > b.i[i] then Result := Result or (1 shl i);
  end;
end;

function VecI8x16Min(const a, b: TVecI8x16): TVecI8x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MinI8x16) then
    Result := dispatch^.MinI8x16(a, b)
  else
    for i := 0 to 15 do
      if a.i[i] < b.i[i] then
        Result.i[i] := a.i[i]
      else
        Result.i[i] := b.i[i];
end;

function VecI8x16Max(const a, b: TVecI8x16): TVecI8x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MaxI8x16) then
    Result := dispatch^.MaxI8x16(a, b)
  else
    for i := 0 to 15 do
      if a.i[i] > b.i[i] then
        Result.i[i] := a.i[i]
      else
        Result.i[i] := b.i[i];
end;

// === U8x16 Operations Implementation ===
// ✅ P4.1: U8x16 (128-bit, 16x UInt8) 高级 API 实现
// ✅ 修改为使用 dispatch table 以获得 SIMD 加速

function VecU8x16Add(const a, b: TVecU8x16): TVecU8x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AddU8x16) then
    Result := dispatch^.AddU8x16(a, b)
  else
    for i := 0 to 15 do
      Result.u[i] := a.u[i] + b.u[i];
end;

function VecU8x16Sub(const a, b: TVecU8x16): TVecU8x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SubU8x16) then
    Result := dispatch^.SubU8x16(a, b)
  else
    for i := 0 to 15 do
      Result.u[i] := a.u[i] - b.u[i];
end;

function VecU8x16And(const a, b: TVecU8x16): TVecU8x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AndU8x16) then
    Result := dispatch^.AndU8x16(a, b)
  else
    for i := 0 to 15 do
      Result.u[i] := a.u[i] and b.u[i];
end;

function VecU8x16Or(const a, b: TVecU8x16): TVecU8x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.OrU8x16) then
    Result := dispatch^.OrU8x16(a, b)
  else
    for i := 0 to 15 do
      Result.u[i] := a.u[i] or b.u[i];
end;

function VecU8x16Xor(const a, b: TVecU8x16): TVecU8x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.XorU8x16) then
    Result := dispatch^.XorU8x16(a, b)
  else
    for i := 0 to 15 do
      Result.u[i] := a.u[i] xor b.u[i];
end;

function VecU8x16Not(const a: TVecU8x16): TVecU8x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.NotU8x16) then
    Result := dispatch^.NotU8x16(a)
  else
    for i := 0 to 15 do
      Result.u[i] := not a.u[i];
end;

function VecU8x16AndNot(const a, b: TVecU8x16): TVecU8x16;
var i: Integer;
begin
  // Note: AndNotU8x16 not in dispatch table, use scalar fallback
  for i := 0 to 15 do
    Result.u[i] := (not a.u[i]) and b.u[i];
end;

function VecU8x16CmpEq(const a, b: TVecU8x16): TMask16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpEqU8x16) then
    Result := dispatch^.CmpEqU8x16(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 15 do
      if a.u[i] = b.u[i] then Result := Result or (1 shl i);
  end;
end;

function VecU8x16CmpLt(const a, b: TVecU8x16): TMask16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLtU8x16) then
    Result := dispatch^.CmpLtU8x16(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 15 do
      if a.u[i] < b.u[i] then Result := Result or (1 shl i);  // 无符号比较
  end;
end;

function VecU8x16CmpGt(const a, b: TVecU8x16): TMask16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGtU8x16) then
    Result := dispatch^.CmpGtU8x16(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 15 do
      if a.u[i] > b.u[i] then Result := Result or (1 shl i);  // 无符号比较
  end;
end;

function VecU8x16Min(const a, b: TVecU8x16): TVecU8x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MinU8x16) then
    Result := dispatch^.MinU8x16(a, b)
  else
    for i := 0 to 15 do
      if a.u[i] < b.u[i] then
        Result.u[i] := a.u[i]
      else
        Result.u[i] := b.u[i];
end;

function VecU8x16Max(const a, b: TVecU8x16): TVecU8x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MaxU8x16) then
    Result := dispatch^.MaxU8x16(a, b)
  else
    for i := 0 to 15 do
      if a.u[i] > b.u[i] then
        Result.u[i] := a.u[i]
      else
        Result.u[i] := b.u[i];
end;

// === U16x8 Operations Implementation ===
// ✅ P4.2: U16x8 (128-bit, 8x UInt16) 高级 API 实现
// ✅ 修改为使用 dispatch table 以获得 SIMD 加速

function VecU16x8Add(const a, b: TVecU16x8): TVecU16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AddU16x8) then
    Result := dispatch^.AddU16x8(a, b)
  else
    for i := 0 to 7 do
      Result.u[i] := a.u[i] + b.u[i];
end;

function VecU16x8Sub(const a, b: TVecU16x8): TVecU16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SubU16x8) then
    Result := dispatch^.SubU16x8(a, b)
  else
    for i := 0 to 7 do
      Result.u[i] := a.u[i] - b.u[i];
end;

function VecU16x8Mul(const a, b: TVecU16x8): TVecU16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MulU16x8) then
    Result := dispatch^.MulU16x8(a, b)
  else
    for i := 0 to 7 do
      Result.u[i] := a.u[i] * b.u[i];
end;

function VecU16x8And(const a, b: TVecU16x8): TVecU16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AndU16x8) then
    Result := dispatch^.AndU16x8(a, b)
  else
    for i := 0 to 7 do
      Result.u[i] := a.u[i] and b.u[i];
end;

function VecU16x8Or(const a, b: TVecU16x8): TVecU16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.OrU16x8) then
    Result := dispatch^.OrU16x8(a, b)
  else
    for i := 0 to 7 do
      Result.u[i] := a.u[i] or b.u[i];
end;

function VecU16x8Xor(const a, b: TVecU16x8): TVecU16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.XorU16x8) then
    Result := dispatch^.XorU16x8(a, b)
  else
    for i := 0 to 7 do
      Result.u[i] := a.u[i] xor b.u[i];
end;

function VecU16x8Not(const a: TVecU16x8): TVecU16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.NotU16x8) then
    Result := dispatch^.NotU16x8(a)
  else
    for i := 0 to 7 do
      Result.u[i] := not a.u[i];
end;

function VecU16x8AndNot(const a, b: TVecU16x8): TVecU16x8;
var i: Integer;
begin
  // Note: AndNotU16x8 not in dispatch table, use scalar fallback
  for i := 0 to 7 do
    Result.u[i] := (not a.u[i]) and b.u[i];
end;

function VecU16x8ShiftLeft(const a: TVecU16x8; count: Integer): TVecU16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftLeftU16x8) then
    Result := dispatch^.ShiftLeftU16x8(a, count)
  else
    for i := 0 to 7 do
      Result.u[i] := a.u[i] shl count;
end;

function VecU16x8ShiftRight(const a: TVecU16x8; count: Integer): TVecU16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftRightU16x8) then
    Result := dispatch^.ShiftRightU16x8(a, count)
  else
    for i := 0 to 7 do
      Result.u[i] := a.u[i] shr count;  // 逻辑右移 (无符号)
end;

function VecU16x8CmpEq(const a, b: TVecU16x8): TMask8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpEqU16x8) then
    Result := dispatch^.CmpEqU16x8(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 7 do
      if a.u[i] = b.u[i] then Result := Result or (1 shl i);
  end;
end;

function VecU16x8CmpLt(const a, b: TVecU16x8): TMask8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLtU16x8) then
    Result := dispatch^.CmpLtU16x8(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 7 do
      if a.u[i] < b.u[i] then Result := Result or (1 shl i);  // 无符号比较
  end;
end;

function VecU16x8CmpGt(const a, b: TVecU16x8): TMask8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGtU16x8) then
    Result := dispatch^.CmpGtU16x8(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 7 do
      if a.u[i] > b.u[i] then Result := Result or (1 shl i);  // 无符号比较
  end;
end;

function VecU16x8Min(const a, b: TVecU16x8): TVecU16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MinU16x8) then
    Result := dispatch^.MinU16x8(a, b)
  else
    for i := 0 to 7 do
      if a.u[i] < b.u[i] then
        Result.u[i] := a.u[i]
      else
        Result.u[i] := b.u[i];
end;

function VecU16x8Max(const a, b: TVecU16x8): TVecU16x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MaxU16x8) then
    Result := dispatch^.MaxU16x8(a, b)
  else
    for i := 0 to 7 do
      if a.u[i] > b.u[i] then
        Result.u[i] := a.u[i]
      else
        Result.u[i] := b.u[i];
end;

// === F64x4 Operations Implementation ===
// ✅ P2.3: F64x4 (256-bit, 4x Double) 高级 API 实现

function VecF64x4Add(const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := a.d[i] + b.d[i];
end;

function VecF64x4Sub(const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := a.d[i] - b.d[i];
end;

function VecF64x4Mul(const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := a.d[i] * b.d[i];
end;

function VecF64x4Div(const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := a.d[i] / b.d[i];
end;

function VecF64x4CmpEq(const a, b: TVecF64x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpEqF64x4) then
    Result := dispatch^.CmpEqF64x4(a, b)
  else
  begin
    Result := 0;
    if a.d[0] = b.d[0] then Result := Result or 1;
    if a.d[1] = b.d[1] then Result := Result or 2;
    if a.d[2] = b.d[2] then Result := Result or 4;
    if a.d[3] = b.d[3] then Result := Result or 8;
  end;
end;

function VecF64x4CmpLt(const a, b: TVecF64x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLtF64x4) then
    Result := dispatch^.CmpLtF64x4(a, b)
  else
  begin
    Result := 0;
    if a.d[0] < b.d[0] then Result := Result or 1;
    if a.d[1] < b.d[1] then Result := Result or 2;
    if a.d[2] < b.d[2] then Result := Result or 4;
    if a.d[3] < b.d[3] then Result := Result or 8;
  end;
end;

function VecF64x4CmpLe(const a, b: TVecF64x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLeF64x4) then
    Result := dispatch^.CmpLeF64x4(a, b)
  else
  begin
    Result := 0;
    if a.d[0] <= b.d[0] then Result := Result or 1;
    if a.d[1] <= b.d[1] then Result := Result or 2;
    if a.d[2] <= b.d[2] then Result := Result or 4;
    if a.d[3] <= b.d[3] then Result := Result or 8;
  end;
end;

function VecF64x4CmpGt(const a, b: TVecF64x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGtF64x4) then
    Result := dispatch^.CmpGtF64x4(a, b)
  else
  begin
    Result := 0;
    if a.d[0] > b.d[0] then Result := Result or 1;
    if a.d[1] > b.d[1] then Result := Result or 2;
    if a.d[2] > b.d[2] then Result := Result or 4;
    if a.d[3] > b.d[3] then Result := Result or 8;
  end;
end;

function VecF64x4CmpGe(const a, b: TVecF64x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGeF64x4) then
    Result := dispatch^.CmpGeF64x4(a, b)
  else
  begin
    Result := 0;
    if a.d[0] >= b.d[0] then Result := Result or 1;
    if a.d[1] >= b.d[1] then Result := Result or 2;
    if a.d[2] >= b.d[2] then Result := Result or 4;
    if a.d[3] >= b.d[3] then Result := Result or 8;
  end;
end;

function VecF64x4CmpNe(const a, b: TVecF64x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpNeF64x4) then
    Result := dispatch^.CmpNeF64x4(a, b)
  else
  begin
    Result := 0;
    if a.d[0] <> b.d[0] then Result := Result or 1;
    if a.d[1] <> b.d[1] then Result := Result or 2;
    if a.d[2] <> b.d[2] then Result := Result or 4;
    if a.d[3] <> b.d[3] then Result := Result or 8;
  end;
end;

function VecF64x4Abs(const a: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := Abs(a.d[i]);
end;

function VecF64x4Sqrt(const a: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := Sqrt(a.d[i]);
end;

function VecF64x4Min(const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.d[i] < b.d[i] then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

function VecF64x4Max(const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.d[i] > b.d[i] then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

function VecF64x4ReduceAdd(const a: TVecF64x4): Double;
begin
  Result := a.d[0] + a.d[1] + a.d[2] + a.d[3];
end;

function VecF64x4ReduceMin(const a: TVecF64x4): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 3 do
    if a.d[i] < Result then Result := a.d[i];
end;

function VecF64x4ReduceMax(const a: TVecF64x4): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 3 do
    if a.d[i] > Result then Result := a.d[i];
end;

function VecF64x4ReduceMul(const a: TVecF64x4): Double;
begin
  Result := a.d[0] * a.d[1] * a.d[2] * a.d[3];
end;

// === F64x8 Operations Implementation ===
// ✅ P2.3: F64x8 (512-bit, 8x Double) 高级 API 实现

function VecF64x8Add(const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := a.d[i] + b.d[i];
end;

function VecF64x8Sub(const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := a.d[i] - b.d[i];
end;

function VecF64x8Mul(const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := a.d[i] * b.d[i];
end;

function VecF64x8Div(const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := a.d[i] / b.d[i];
end;

function VecF64x8CmpEq(const a, b: TVecF64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.d[i] = b.d[i] then Result := Result or (1 shl i);
end;

function VecF64x8CmpLt(const a, b: TVecF64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.d[i] < b.d[i] then Result := Result or (1 shl i);
end;

function VecF64x8CmpLe(const a, b: TVecF64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.d[i] <= b.d[i] then Result := Result or (1 shl i);
end;

function VecF64x8CmpGt(const a, b: TVecF64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.d[i] > b.d[i] then Result := Result or (1 shl i);
end;

function VecF64x8CmpGe(const a, b: TVecF64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.d[i] >= b.d[i] then Result := Result or (1 shl i);
end;

function VecF64x8CmpNe(const a, b: TVecF64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.d[i] <> b.d[i] then Result := Result or (1 shl i);
end;

function VecF64x8Abs(const a: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := Abs(a.d[i]);
end;

function VecF64x8Sqrt(const a: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := Sqrt(a.d[i]);
end;

function VecF64x8Min(const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.d[i] < b.d[i] then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

function VecF64x8Max(const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.d[i] > b.d[i] then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

function VecF64x8ReduceAdd(const a: TVecF64x8): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 7 do
    Result := Result + a.d[i];
end;

function VecF64x8ReduceMin(const a: TVecF64x8): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 7 do
    if a.d[i] < Result then Result := a.d[i];
end;

function VecF64x8ReduceMax(const a: TVecF64x8): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 7 do
    if a.d[i] > Result then Result := a.d[i];
end;

function VecF64x8ReduceMul(const a: TVecF64x8): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 7 do
    Result := Result * a.d[i];
end;

// === F32x16 Operations Implementation ===
// ✅ P3.2: F32x16 (512-bit, 16x Single) 高级 API 实现

function VecF32x16Add(const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := a.f[i] + b.f[i];
end;

function VecF32x16Sub(const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := a.f[i] - b.f[i];
end;

function VecF32x16Mul(const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := a.f[i] * b.f[i];
end;

function VecF32x16Div(const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := a.f[i] / b.f[i];
end;

function VecF32x16CmpEq_Mask(const a, b: TVecF32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.f[i] = b.f[i] then Result := Result or (1 shl i);
end;

function VecF32x16CmpLt_Mask(const a, b: TVecF32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.f[i] < b.f[i] then Result := Result or (1 shl i);
end;

function VecF32x16CmpLe_Mask(const a, b: TVecF32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.f[i] <= b.f[i] then Result := Result or (1 shl i);
end;

function VecF32x16CmpGt_Mask(const a, b: TVecF32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.f[i] > b.f[i] then Result := Result or (1 shl i);
end;

function VecF32x16CmpGe_Mask(const a, b: TVecF32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.f[i] >= b.f[i] then Result := Result or (1 shl i);
end;

function VecF32x16CmpNe_Mask(const a, b: TVecF32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.f[i] <> b.f[i] then Result := Result or (1 shl i);
end;

function VecF32x16Abs(const a: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := Abs(a.f[i]);
end;

function VecF32x16Sqrt(const a: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := Sqrt(a.f[i]);
end;

function VecF32x16Min(const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.f[i] < b.f[i] then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function VecF32x16Max(const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.f[i] > b.f[i] then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function VecF32x16ReduceAdd(const a: TVecF32x16): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 15 do
    Result := Result + a.f[i];
end;

function VecF32x16ReduceMin(const a: TVecF32x16): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 15 do
    if a.f[i] < Result then Result := a.f[i];
end;

function VecF32x16ReduceMax(const a: TVecF32x16): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 15 do
    if a.f[i] > Result then Result := a.f[i];
end;

function VecF32x16ReduceMul(const a: TVecF32x16): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 15 do
    Result := Result * a.f[i];
end;

// === I32x16 Operations Implementation ===
// ✅ P1.2: I32x16 高级 API 实现

function VecI32x16Add(const a, b: TVecI32x16): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AddI32x16) then
    Result := dispatch^.AddI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := a.i[i] + b.i[i];
  end;
end;

function VecI32x16Sub(const a, b: TVecI32x16): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SubI32x16) then
    Result := dispatch^.SubI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := a.i[i] - b.i[i];
  end;
end;

function VecI32x16Mul(const a, b: TVecI32x16): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MulI32x16) then
    Result := dispatch^.MulI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := a.i[i] * b.i[i];
  end;
end;

function VecI32x16And(const a, b: TVecI32x16): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AndI32x16) then
    Result := dispatch^.AndI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := a.i[i] and b.i[i];
  end;
end;

function VecI32x16Or(const a, b: TVecI32x16): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.OrI32x16) then
    Result := dispatch^.OrI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := a.i[i] or b.i[i];
  end;
end;

function VecI32x16Xor(const a, b: TVecI32x16): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.XorI32x16) then
    Result := dispatch^.XorI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := a.i[i] xor b.i[i];
  end;
end;

function VecI32x16Not(const a: TVecI32x16): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.NotI32x16) then
    Result := dispatch^.NotI32x16(a)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := not a.i[i];
  end;
end;

function VecI32x16AndNot(const a, b: TVecI32x16): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AndNotI32x16) then
    Result := dispatch^.AndNotI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := (not a.i[i]) and b.i[i];
  end;
end;

function VecI32x16ShiftLeft(const a: TVecI32x16; count: Integer): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftLeftI32x16) then
    Result := dispatch^.ShiftLeftI32x16(a, count)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := a.i[i] shl count;
  end;
end;

function VecI32x16ShiftRight(const a: TVecI32x16; count: Integer): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftRightI32x16) then
    Result := dispatch^.ShiftRightI32x16(a, count)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := Int32(UInt32(a.i[i]) shr count);
  end;
end;

function VecI32x16ShiftRightArith(const a: TVecI32x16; count: Integer): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftRightArithI32x16) then
    Result := dispatch^.ShiftRightArithI32x16(a, count)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := SarLongint(a.i[i], count);
  end;
end;

function VecI32x16CmpEq(const a, b: TVecI32x16): TMask16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpEqI32x16) then
    Result := dispatch^.CmpEqI32x16(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 15 do
      if a.i[i] = b.i[i] then Result := Result or (1 shl i);
  end;
end;

function VecI32x16CmpLt(const a, b: TVecI32x16): TMask16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLtI32x16) then
    Result := dispatch^.CmpLtI32x16(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 15 do
      if a.i[i] < b.i[i] then Result := Result or (1 shl i);
  end;
end;

function VecI32x16CmpGt(const a, b: TVecI32x16): TMask16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGtI32x16) then
    Result := dispatch^.CmpGtI32x16(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 15 do
      if a.i[i] > b.i[i] then Result := Result or (1 shl i);
  end;
end;

// ✅ P0-C: 添加 I32x16 缺失比较函数
function VecI32x16CmpLe(const a, b: TVecI32x16): TMask16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLeI32x16) then
    Result := dispatch^.CmpLeI32x16(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 15 do
      if a.i[i] <= b.i[i] then Result := Result or (1 shl i);
  end;
end;

function VecI32x16CmpGe(const a, b: TVecI32x16): TMask16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGeI32x16) then
    Result := dispatch^.CmpGeI32x16(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 15 do
      if a.i[i] >= b.i[i] then Result := Result or (1 shl i);
  end;
end;

function VecI32x16CmpNe(const a, b: TVecI32x16): TMask16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpNeI32x16) then
    Result := dispatch^.CmpNeI32x16(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 15 do
      if a.i[i] <> b.i[i] then Result := Result or (1 shl i);
  end;
end;

function VecI32x16Min(const a, b: TVecI32x16): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MinI32x16) then
    Result := dispatch^.MinI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      if a.i[i] < b.i[i] then
        Result.i[i] := a.i[i]
      else
        Result.i[i] := b.i[i];
  end;
end;

function VecI32x16Max(const a, b: TVecI32x16): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MaxI32x16) then
    Result := dispatch^.MaxI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      if a.i[i] > b.i[i] then
        Result.i[i] := a.i[i]
      else
        Result.i[i] := b.i[i];
  end;
end;

// === ✅ P2-1: Saturating Arithmetic Implementation ===
// 饱和算术：结果被钳制到类型范围，而不是溢出回绕

function VecI8x16SatAdd(const a, b: TVecI8x16): TVecI8x16;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.I8x16SatAdd(a, b);
end;

function VecI8x16SatSub(const a, b: TVecI8x16): TVecI8x16;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.I8x16SatSub(a, b);
end;

function VecI16x8SatAdd(const a, b: TVecI16x8): TVecI16x8;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.I16x8SatAdd(a, b);
end;

function VecI16x8SatSub(const a, b: TVecI16x8): TVecI16x8;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.I16x8SatSub(a, b);
end;

function VecU8x16SatAdd(const a, b: TVecU8x16): TVecU8x16;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.U8x16SatAdd(a, b);
end;

function VecU8x16SatSub(const a, b: TVecU8x16): TVecU8x16;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.U8x16SatSub(a, b);
end;

function VecU16x8SatAdd(const a, b: TVecU16x8): TVecU16x8;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.U16x8SatAdd(a, b);
end;

function VecU16x8SatSub(const a, b: TVecU16x8): TVecU16x8;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.U16x8SatSub(a, b);
end;

// === Shuffle/Permute Operations (wrappers for simd.utils) ===

function VecF32x4Shuffle(const a: TVecF32x4; imm8: Byte): TVecF32x4;
begin
  Result := fafafa.core.simd.utils.VecF32x4Shuffle(a, imm8);
end;

function VecI32x4Shuffle(const a: TVecI32x4; imm8: Byte): TVecI32x4;
begin
  Result := fafafa.core.simd.utils.VecI32x4Shuffle(a, imm8);
end;

function VecF32x4Shuffle2(const a, b: TVecF32x4; imm8: Byte): TVecF32x4;
begin
  Result := fafafa.core.simd.utils.VecF32x4Shuffle2(a, b, imm8);
end;

// === Blend Operations (wrappers for simd.utils) ===

function VecF32x4Blend(const a, b: TVecF32x4; mask: Byte): TVecF32x4;
begin
  Result := fafafa.core.simd.utils.VecF32x4Blend(a, b, mask);
end;

function VecF64x2Blend(const a, b: TVecF64x2; mask: Byte): TVecF64x2;
begin
  Result := fafafa.core.simd.utils.VecF64x2Blend(a, b, mask);
end;

function VecI32x4Blend(const a, b: TVecI32x4; mask: Byte): TVecI32x4;
begin
  Result := fafafa.core.simd.utils.VecI32x4Blend(a, b, mask);
end;

// === Type Conversion Operations (wrappers for simd.utils) ===

function VecF32x4IntoBits(const a: TVecF32x4): TVecI32x4;
begin
  Result := fafafa.core.simd.utils.VecF32x4IntoBits(a);
end;

function VecI32x4FromBitsF32(const a: TVecI32x4): TVecF32x4;
begin
  Result := fafafa.core.simd.utils.VecI32x4FromBitsF32(a);
end;

function VecI32x4CastToF32x4(const a: TVecI32x4): TVecF32x4;
begin
  Result := fafafa.core.simd.utils.VecI32x4CastToF32x4(a);
end;

function VecF32x4CastToI32x4(const a: TVecF32x4): TVecI32x4;
begin
  Result := fafafa.core.simd.utils.VecF32x4CastToI32x4(a);
end;

// === Framework Information ===

function GetCurrentBackend: TSimdBackend;
begin
  Result := GetActiveBackend;
end;

function GetCurrentBackendInfo: TSimdBackendInfo;
begin
  Result := GetBackendInfo(GetActiveBackend);
end;

function GetCPUInformation: TCPUInfo;
begin
  Result := GetCPUInfo;
end;

function GetAvailableBackendList: TSimdBackendArray;
begin
  Result := GetAvailableBackends;
end;

procedure ForceBackend(backend: TSimdBackend);
begin
  SetActiveBackend(backend);
end;

procedure ResetBackendSelection;
begin
  ResetToAutomaticBackend;
end;

// === Memory Utilities ===

function AllocateAligned(size: NativeUInt; alignment: NativeUInt): Pointer;
begin
  Result := AlignedAlloc(size, alignment);
end;

procedure FreeAligned(ptr: Pointer);
begin
  AlignedFree(ptr);
end;

function IsPointerAligned(ptr: Pointer; alignment: NativeUInt): Boolean;
begin
  Result := fafafa.core.simd.memutils.IsAligned(ptr, alignment);
end;

end.


