unit fafafa.core.simd.sse2;

{$mode objfpc}
{$I fafafa.core.settings.inc}
{$asmmode intel}

interface

uses
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch,
  fafafa.core.simd.backend.priority;

// === SSE2 Backend Implementation ===
// Provides SIMD-accelerated operations using x86-64 SSE2 instructions.
// This backend is available on all x86-64 processors.

// Register the SSE2 backend
procedure RegisterSSE2Backend;

// === SSE2 门面函数声明 ===

// 内存操作函数
function MemEqual_SSE2(a, b: Pointer; len: SizeUInt): LongBool;
function MemFindByte_SSE2(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
procedure MemCopy_SSE2(src, dst: Pointer; len: SizeUInt);
procedure MemSet_SSE2(dst: Pointer; len: SizeUInt; value: Byte);

// 统计函数
function SumBytes_SSE2(p: Pointer; len: SizeUInt): UInt64;
function CountByte_SSE2(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;

// ✅ P2-1: 饱和算术（SSE2 PADDS/PSUBS 指令加速）
function SSE2I8x16SatAdd(const a, b: TVecI8x16): TVecI8x16;
function SSE2I8x16SatSub(const a, b: TVecI8x16): TVecI8x16;
function SSE2I16x8SatAdd(const a, b: TVecI16x8): TVecI16x8;
function SSE2I16x8SatSub(const a, b: TVecI16x8): TVecI16x8;
function SSE2U8x16SatAdd(const a, b: TVecU8x16): TVecU8x16;
function SSE2U8x16SatSub(const a, b: TVecU8x16): TVecU8x16;
function SSE2U16x8SatAdd(const a, b: TVecU16x8): TVecU16x8;
function SSE2U16x8SatSub(const a, b: TVecU16x8): TVecU16x8;

// ✅ I16x8 操作（SSE2 PADDW/PSUBW/PMULLW 等指令）
function SSE2AddI16x8(const a, b: TVecI16x8): TVecI16x8;
function SSE2SubI16x8(const a, b: TVecI16x8): TVecI16x8;
function SSE2MulI16x8(const a, b: TVecI16x8): TVecI16x8;
function SSE2AndI16x8(const a, b: TVecI16x8): TVecI16x8;
function SSE2OrI16x8(const a, b: TVecI16x8): TVecI16x8;
function SSE2XorI16x8(const a, b: TVecI16x8): TVecI16x8;
function SSE2NotI16x8(const a: TVecI16x8): TVecI16x8;
function SSE2AndNotI16x8(const a, b: TVecI16x8): TVecI16x8;
function SSE2ShiftLeftI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
function SSE2ShiftRightI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
function SSE2ShiftRightArithI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
function SSE2CmpEqI16x8(const a, b: TVecI16x8): TMask8;
function SSE2CmpLtI16x8(const a, b: TVecI16x8): TMask8;
function SSE2CmpGtI16x8(const a, b: TVecI16x8): TMask8;
function SSE2CmpLeI16x8(const a, b: TVecI16x8): TMask8;  // ✅ NEW
function SSE2CmpGeI16x8(const a, b: TVecI16x8): TMask8;  // ✅ NEW
function SSE2CmpNeI16x8(const a, b: TVecI16x8): TMask8;  // ✅ NEW
function SSE2MinI16x8(const a, b: TVecI16x8): TVecI16x8;
function SSE2MaxI16x8(const a, b: TVecI16x8): TVecI16x8;

// ✅ I8x16 操作（SSE2 PADDB/PSUBB 等指令）
function SSE2AddI8x16(const a, b: TVecI8x16): TVecI8x16;
function SSE2SubI8x16(const a, b: TVecI8x16): TVecI8x16;
function SSE2AndI8x16(const a, b: TVecI8x16): TVecI8x16;
function SSE2OrI8x16(const a, b: TVecI8x16): TVecI8x16;
function SSE2XorI8x16(const a, b: TVecI8x16): TVecI8x16;
function SSE2NotI8x16(const a: TVecI8x16): TVecI8x16;
function SSE2AndNotI8x16(const a, b: TVecI8x16): TVecI8x16;
function SSE2CmpEqI8x16(const a, b: TVecI8x16): TMask16;
function SSE2CmpLtI8x16(const a, b: TVecI8x16): TMask16;
function SSE2CmpGtI8x16(const a, b: TVecI8x16): TMask16;
function SSE2CmpLeI8x16(const a, b: TVecI8x16): TMask16;  // ✅ NEW
function SSE2CmpGeI8x16(const a, b: TVecI8x16): TMask16;  // ✅ NEW
function SSE2CmpNeI8x16(const a, b: TVecI8x16): TMask16;  // ✅ NEW
function SSE2MinI8x16(const a, b: TVecI8x16): TVecI8x16;
function SSE2MaxI8x16(const a, b: TVecI8x16): TVecI8x16;

// ✅ U32x4 操作
function SSE2AddU32x4(const a, b: TVecU32x4): TVecU32x4;
function SSE2SubU32x4(const a, b: TVecU32x4): TVecU32x4;
function SSE2MulU32x4(const a, b: TVecU32x4): TVecU32x4;
function SSE2AndU32x4(const a, b: TVecU32x4): TVecU32x4;
function SSE2OrU32x4(const a, b: TVecU32x4): TVecU32x4;
function SSE2XorU32x4(const a, b: TVecU32x4): TVecU32x4;
function SSE2NotU32x4(const a: TVecU32x4): TVecU32x4;
function SSE2AndNotU32x4(const a, b: TVecU32x4): TVecU32x4;
function SSE2ShiftLeftU32x4(const a: TVecU32x4; count: Integer): TVecU32x4;
function SSE2ShiftRightU32x4(const a: TVecU32x4; count: Integer): TVecU32x4;
function SSE2CmpEqU32x4(const a, b: TVecU32x4): TMask4;
function SSE2CmpLtU32x4(const a, b: TVecU32x4): TMask4;
function SSE2CmpGtU32x4(const a, b: TVecU32x4): TMask4;
function SSE2CmpLeU32x4(const a, b: TVecU32x4): TMask4;
function SSE2CmpGeU32x4(const a, b: TVecU32x4): TMask4;
function SSE2CmpNeU32x4(const a, b: TVecU32x4): TMask4;
function SSE2MinU32x4(const a, b: TVecU32x4): TVecU32x4;
function SSE2MaxU32x4(const a, b: TVecU32x4): TVecU32x4;

// ✅ U16x8 操作
function SSE2AddU16x8(const a, b: TVecU16x8): TVecU16x8;
function SSE2SubU16x8(const a, b: TVecU16x8): TVecU16x8;
function SSE2MulU16x8(const a, b: TVecU16x8): TVecU16x8;
function SSE2AndU16x8(const a, b: TVecU16x8): TVecU16x8;
function SSE2OrU16x8(const a, b: TVecU16x8): TVecU16x8;
function SSE2XorU16x8(const a, b: TVecU16x8): TVecU16x8;
function SSE2NotU16x8(const a: TVecU16x8): TVecU16x8;
function SSE2AndNotU16x8(const a, b: TVecU16x8): TVecU16x8;
function SSE2ShiftLeftU16x8(const a: TVecU16x8; count: Integer): TVecU16x8;
function SSE2ShiftRightU16x8(const a: TVecU16x8; count: Integer): TVecU16x8;
function SSE2CmpEqU16x8(const a, b: TVecU16x8): TMask8;
function SSE2CmpLtU16x8(const a, b: TVecU16x8): TMask8;
function SSE2CmpGtU16x8(const a, b: TVecU16x8): TMask8;
function SSE2CmpLeU16x8(const a, b: TVecU16x8): TMask8;  // ✅ NEW
function SSE2CmpGeU16x8(const a, b: TVecU16x8): TMask8;  // ✅ NEW
function SSE2CmpNeU16x8(const a, b: TVecU16x8): TMask8;  // ✅ NEW
function SSE2MinU16x8(const a, b: TVecU16x8): TVecU16x8;
function SSE2MaxU16x8(const a, b: TVecU16x8): TVecU16x8;

// ✅ U8x16 操作
function SSE2AddU8x16(const a, b: TVecU8x16): TVecU8x16;
function SSE2SubU8x16(const a, b: TVecU8x16): TVecU8x16;
function SSE2AndU8x16(const a, b: TVecU8x16): TVecU8x16;
function SSE2OrU8x16(const a, b: TVecU8x16): TVecU8x16;
function SSE2XorU8x16(const a, b: TVecU8x16): TVecU8x16;
function SSE2NotU8x16(const a: TVecU8x16): TVecU8x16;
function SSE2AndNotU8x16(const a, b: TVecU8x16): TVecU8x16;
function SSE2CmpEqU8x16(const a, b: TVecU8x16): TMask16;
function SSE2CmpLtU8x16(const a, b: TVecU8x16): TMask16;
function SSE2CmpGtU8x16(const a, b: TVecU8x16): TMask16;
function SSE2CmpLeU8x16(const a, b: TVecU8x16): TMask16;  // ✅ NEW
function SSE2CmpGeU8x16(const a, b: TVecU8x16): TMask16;  // ✅ NEW
function SSE2CmpNeU8x16(const a, b: TVecU8x16): TMask16;  // ✅ NEW
function SSE2MinU8x16(const a, b: TVecU8x16): TVecU8x16;
function SSE2MaxU8x16(const a, b: TVecU8x16): TVecU8x16;

// ✅ I64x2 比较操作（SSE2 模拟 - 无原生 64 位比较指令）
// SSE2 没有 PCMPGTQ 指令（SSE4.2+），使用 32 位比较组合模拟
function SSE2CmpEqI64x2(const a, b: TVecI64x2): TMask2;
function SSE2CmpNeI64x2(const a, b: TVecI64x2): TMask2;
function SSE2CmpGtI64x2(const a, b: TVecI64x2): TMask2;
function SSE2CmpLtI64x2(const a, b: TVecI64x2): TMask2;
function SSE2CmpGeI64x2(const a, b: TVecI64x2): TMask2;
function SSE2CmpLeI64x2(const a, b: TVecI64x2): TMask2;

// ============================================================================
// ✅ 512-bit 向量的 SSE2 渐进降级实现 (2026-02-05)
// 策略: 使用 2×256-bit 操作 (利用已有的 F32x8/F64x4/I32x8)
// ============================================================================

// === F32x16 操作 (16×Float32) ===
function SSE2AddF32x16(const a, b: TVecF32x16): TVecF32x16;
function SSE2SubF32x16(const a, b: TVecF32x16): TVecF32x16;
function SSE2MulF32x16(const a, b: TVecF32x16): TVecF32x16;
function SSE2DivF32x16(const a, b: TVecF32x16): TVecF32x16;
function SSE2AbsF32x16(const a: TVecF32x16): TVecF32x16;
function SSE2SqrtF32x16(const a: TVecF32x16): TVecF32x16;
function SSE2MinF32x16(const a, b: TVecF32x16): TVecF32x16;
function SSE2MaxF32x16(const a, b: TVecF32x16): TVecF32x16;
function SSE2FmaF32x16(const a, b, c: TVecF32x16): TVecF32x16;
function SSE2FloorF32x16(const a: TVecF32x16): TVecF32x16;
function SSE2CeilF32x16(const a: TVecF32x16): TVecF32x16;
function SSE2RoundF32x16(const a: TVecF32x16): TVecF32x16;
function SSE2TruncF32x16(const a: TVecF32x16): TVecF32x16;
function SSE2ClampF32x16(const a, minVal, maxVal: TVecF32x16): TVecF32x16;
function SSE2ReduceAddF32x16(const a: TVecF32x16): Single;
function SSE2ReduceMinF32x16(const a: TVecF32x16): Single;
function SSE2ReduceMaxF32x16(const a: TVecF32x16): Single;
function SSE2ReduceMulF32x16(const a: TVecF32x16): Single;
function SSE2LoadF32x16(p: PSingle): TVecF32x16;
procedure SSE2StoreF32x16(p: PSingle; const a: TVecF32x16);
function SSE2SplatF32x16(value: Single): TVecF32x16;
function SSE2ZeroF32x16: TVecF32x16;
function SSE2CmpEqF32x16(const a, b: TVecF32x16): TMask16;
function SSE2CmpLtF32x16(const a, b: TVecF32x16): TMask16;
function SSE2CmpLeF32x16(const a, b: TVecF32x16): TMask16;
function SSE2CmpGtF32x16(const a, b: TVecF32x16): TMask16;
function SSE2CmpGeF32x16(const a, b: TVecF32x16): TMask16;
function SSE2CmpNeF32x16(const a, b: TVecF32x16): TMask16;
function SSE2SelectF32x16(const mask: TMask16; const a, b: TVecF32x16): TVecF32x16;

// === F64x8 操作 (8×Float64) ===
function SSE2AddF64x8(const a, b: TVecF64x8): TVecF64x8;
function SSE2SubF64x8(const a, b: TVecF64x8): TVecF64x8;
function SSE2MulF64x8(const a, b: TVecF64x8): TVecF64x8;
function SSE2DivF64x8(const a, b: TVecF64x8): TVecF64x8;
function SSE2AbsF64x8(const a: TVecF64x8): TVecF64x8;
function SSE2SqrtF64x8(const a: TVecF64x8): TVecF64x8;
function SSE2MinF64x8(const a, b: TVecF64x8): TVecF64x8;
function SSE2MaxF64x8(const a, b: TVecF64x8): TVecF64x8;
function SSE2FmaF64x8(const a, b, c: TVecF64x8): TVecF64x8;
function SSE2FloorF64x8(const a: TVecF64x8): TVecF64x8;
function SSE2CeilF64x8(const a: TVecF64x8): TVecF64x8;
function SSE2RoundF64x8(const a: TVecF64x8): TVecF64x8;
function SSE2TruncF64x8(const a: TVecF64x8): TVecF64x8;
function SSE2ClampF64x8(const a, minVal, maxVal: TVecF64x8): TVecF64x8;
function SSE2ReduceAddF64x8(const a: TVecF64x8): Double;
function SSE2ReduceMinF64x8(const a: TVecF64x8): Double;
function SSE2ReduceMaxF64x8(const a: TVecF64x8): Double;
function SSE2ReduceMulF64x8(const a: TVecF64x8): Double;
function SSE2LoadF64x8(p: PDouble): TVecF64x8;
procedure SSE2StoreF64x8(p: PDouble; const a: TVecF64x8);
function SSE2SplatF64x8(value: Double): TVecF64x8;
function SSE2ZeroF64x8: TVecF64x8;
function SSE2CmpEqF64x8(const a, b: TVecF64x8): TMask8;
function SSE2CmpLtF64x8(const a, b: TVecF64x8): TMask8;
function SSE2CmpLeF64x8(const a, b: TVecF64x8): TMask8;
function SSE2CmpGtF64x8(const a, b: TVecF64x8): TMask8;
function SSE2CmpGeF64x8(const a, b: TVecF64x8): TMask8;
function SSE2CmpNeF64x8(const a, b: TVecF64x8): TMask8;
function SSE2SelectF64x8(const mask: TMask8; const a, b: TVecF64x8): TVecF64x8;

// ✅ NEW: 缺失的 Select 操作 (条件选择: mask[i] != 0 ? a[i] : b[i])
function SSE2SelectI32x4(const mask: TVecI32x4; const a, b: TVecI32x4): TVecI32x4;
function SSE2SelectF32x8(const mask: TVecU32x8; const a, b: TVecF32x8): TVecF32x8;
function SSE2SelectF64x4(const mask: TVecU64x4; const a, b: TVecF64x4): TVecF64x4;

// === I32x16 操作 (16×Int32) ===
function SSE2AddI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2SubI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2MulI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2AndI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2OrI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2XorI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2NotI32x16(const a: TVecI32x16): TVecI32x16;
function SSE2AndNotI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2ShiftLeftI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
function SSE2ShiftRightI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
function SSE2ShiftRightArithI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
function SSE2CmpEqI32x16(const a, b: TVecI32x16): TMask16;
function SSE2CmpLtI32x16(const a, b: TVecI32x16): TMask16;
function SSE2CmpGtI32x16(const a, b: TVecI32x16): TMask16;
function SSE2CmpLeI32x16(const a, b: TVecI32x16): TMask16;
function SSE2CmpGeI32x16(const a, b: TVecI32x16): TMask16;
function SSE2CmpNeI32x16(const a, b: TVecI32x16): TMask16;
function SSE2MinI32x16(const a, b: TVecI32x16): TVecI32x16;
function SSE2MaxI32x16(const a, b: TVecI32x16): TVecI32x16;

// ============================================================================
// ✅ NEW: I64x4 操作 (256-bit AVX2 仿真，使用 2×I64x2)
// ============================================================================
function SSE2AddI64x4(const a, b: TVecI64x4): TVecI64x4;
function SSE2SubI64x4(const a, b: TVecI64x4): TVecI64x4;
function SSE2AndI64x4(const a, b: TVecI64x4): TVecI64x4;
function SSE2OrI64x4(const a, b: TVecI64x4): TVecI64x4;
function SSE2XorI64x4(const a, b: TVecI64x4): TVecI64x4;
function SSE2NotI64x4(const a: TVecI64x4): TVecI64x4;
function SSE2AndNotI64x4(const a, b: TVecI64x4): TVecI64x4;
function SSE2ShiftLeftI64x4(const a: TVecI64x4; count: Integer): TVecI64x4;
function SSE2ShiftRightI64x4(const a: TVecI64x4; count: Integer): TVecI64x4;
function SSE2CmpEqI64x4(const a, b: TVecI64x4): TMask4;
function SSE2CmpLtI64x4(const a, b: TVecI64x4): TMask4;
function SSE2CmpGtI64x4(const a, b: TVecI64x4): TMask4;
function SSE2CmpLeI64x4(const a, b: TVecI64x4): TMask4;
function SSE2CmpGeI64x4(const a, b: TVecI64x4): TMask4;
function SSE2CmpNeI64x4(const a, b: TVecI64x4): TMask4;
function SSE2LoadI64x4(p: PInt64): TVecI64x4;
procedure SSE2StoreI64x4(p: PInt64; const a: TVecI64x4);
function SSE2SplatI64x4(value: Int64): TVecI64x4;
function SSE2ZeroI64x4: TVecI64x4;

// ============================================================================
// ✅ NEW: U32x8 操作 (256-bit AVX2 仿真，使用 2×U32x4)
// ============================================================================
function SSE2AddU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2SubU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2MulU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2AndU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2OrU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2XorU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2NotU32x8(const a: TVecU32x8): TVecU32x8;
function SSE2AndNotU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2ShiftLeftU32x8(const a: TVecU32x8; count: Integer): TVecU32x8;
function SSE2ShiftRightU32x8(const a: TVecU32x8; count: Integer): TVecU32x8;
function SSE2CmpEqU32x8(const a, b: TVecU32x8): TMask8;
function SSE2CmpLtU32x8(const a, b: TVecU32x8): TMask8;
function SSE2CmpGtU32x8(const a, b: TVecU32x8): TMask8;
function SSE2CmpLeU32x8(const a, b: TVecU32x8): TMask8;
function SSE2CmpGeU32x8(const a, b: TVecU32x8): TMask8;
function SSE2CmpNeU32x8(const a, b: TVecU32x8): TMask8;
function SSE2MinU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2MaxU32x8(const a, b: TVecU32x8): TVecU32x8;
function SSE2SplatU32x8(value: UInt32): TVecU32x8;

// ============================================================================
// ✅ NEW: U64x4 操作 (256-bit AVX2 仿真，使用 2×U64x2)
// ============================================================================
function SSE2AddU64x4(const a, b: TVecU64x4): TVecU64x4;
function SSE2SubU64x4(const a, b: TVecU64x4): TVecU64x4;
function SSE2AndU64x4(const a, b: TVecU64x4): TVecU64x4;
function SSE2OrU64x4(const a, b: TVecU64x4): TVecU64x4;
function SSE2XorU64x4(const a, b: TVecU64x4): TVecU64x4;
function SSE2NotU64x4(const a: TVecU64x4): TVecU64x4;
function SSE2ShiftLeftU64x4(const a: TVecU64x4; count: Integer): TVecU64x4;
function SSE2ShiftRightU64x4(const a: TVecU64x4; count: Integer): TVecU64x4;
function SSE2CmpEqU64x4(const a, b: TVecU64x4): TMask4;
function SSE2CmpLtU64x4(const a, b: TVecU64x4): TMask4;
function SSE2CmpGtU64x4(const a, b: TVecU64x4): TMask4;
function SSE2CmpLeU64x4(const a, b: TVecU64x4): TMask4;
function SSE2CmpGeU64x4(const a, b: TVecU64x4): TMask4;
function SSE2CmpNeU64x4(const a, b: TVecU64x4): TMask4;

// ============================================================================
// ✅ NEW: I64x8 操作 (512-bit AVX-512 仿真，使用 4×I64x2 或 2×I64x4)
// ============================================================================
function SSE2AddI64x8(const a, b: TVecI64x8): TVecI64x8;
function SSE2SubI64x8(const a, b: TVecI64x8): TVecI64x8;
function SSE2AndI64x8(const a, b: TVecI64x8): TVecI64x8;
function SSE2OrI64x8(const a, b: TVecI64x8): TVecI64x8;
function SSE2XorI64x8(const a, b: TVecI64x8): TVecI64x8;
function SSE2NotI64x8(const a: TVecI64x8): TVecI64x8;
function SSE2ShiftLeftI64x8(const a: TVecI64x8; count: Integer): TVecI64x8;
function SSE2ShiftRightI64x8(const a: TVecI64x8; count: Integer): TVecI64x8;
function SSE2CmpEqI64x8(const a, b: TVecI64x8): TMask8;
function SSE2CmpLtI64x8(const a, b: TVecI64x8): TMask8;
function SSE2CmpGtI64x8(const a, b: TVecI64x8): TMask8;
function SSE2CmpLeI64x8(const a, b: TVecI64x8): TMask8;
function SSE2CmpGeI64x8(const a, b: TVecI64x8): TMask8;
function SSE2CmpNeI64x8(const a, b: TVecI64x8): TMask8;
function SSE2LoadI64x8(p: PInt64): TVecI64x8;
procedure SSE2StoreI64x8(p: PInt64; const a: TVecI64x8);
function SSE2SplatI64x8(value: Int64): TVecI64x8;
function SSE2ZeroI64x8: TVecI64x8;

// ============================================================================
// ✅ NEW: Extract/Insert 操作 (通过数组索引实现)
// ============================================================================
// F64x2
function SSE2ExtractF64x2(const a: TVecF64x2; index: Integer): Double;
function SSE2InsertF64x2(const a: TVecF64x2; value: Double; index: Integer): TVecF64x2;
// I32x4
function SSE2ExtractI32x4(const a: TVecI32x4; index: Integer): Int32;
function SSE2InsertI32x4(const a: TVecI32x4; value: Int32; index: Integer): TVecI32x4;
// I64x2
function SSE2ExtractI64x2(const a: TVecI64x2; index: Integer): Int64;
function SSE2InsertI64x2(const a: TVecI64x2; value: Int64; index: Integer): TVecI64x2;
// F32x8
function SSE2ExtractF32x8(const a: TVecF32x8; index: Integer): Single;
function SSE2InsertF32x8(const a: TVecF32x8; value: Single; index: Integer): TVecF32x8;
// F64x4
function SSE2ExtractF64x4(const a: TVecF64x4; index: Integer): Double;
function SSE2InsertF64x4(const a: TVecF64x4; value: Double; index: Integer): TVecF64x4;
// I32x8
function SSE2ExtractI32x8(const a: TVecI32x8; index: Integer): Int32;
function SSE2InsertI32x8(const a: TVecI32x8; value: Int32; index: Integer): TVecI32x8;
// I64x4
function SSE2ExtractI64x4(const a: TVecI64x4; index: Integer): Int64;
function SSE2InsertI64x4(const a: TVecI64x4; value: Int64; index: Integer): TVecI64x4;
// F32x16
function SSE2ExtractF32x16(const a: TVecF32x16; index: Integer): Single;
function SSE2InsertF32x16(const a: TVecF32x16; value: Single; index: Integer): TVecF32x16;
// I32x16
function SSE2ExtractI32x16(const a: TVecI32x16; index: Integer): Int32;
function SSE2InsertI32x16(const a: TVecI32x16; value: Int32; index: Integer): TVecI32x16;

// ============================================================================
// ✅ NEW: Facade 函数 (高级内存和文本操作)
// ============================================================================
function MemDiffRange_SSE2(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
procedure MemReverse_SSE2(p: Pointer; len: SizeUInt);
procedure ToLowerAscii_SSE2(p: Pointer; len: SizeUInt);
procedure ToUpperAscii_SSE2(p: Pointer; len: SizeUInt);
function AsciiIEqual_SSE2(a, b: Pointer; len: SizeUInt): Boolean;
function BytesIndexOf_SSE2(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;
function Utf8Validate_SSE2(p: Pointer; len: SizeUInt): Boolean;

implementation

uses
  SysUtils,
  Math,  // RTL Math 单元
  fafafa.core.simd.cpuinfo;

// === SSE2 Arithmetic Operations ===
// Note: FPC x86-64 calling convention:
//   - First 6 integer/pointer args: RDI, RSI, RDX, RCX, R8, R9
//   - Float args: XMM0-XMM7
//   - Result pointer for large structs: hidden first arg in RDI
//   - For const record params, pointer is passed

function SSE2AddF32x4(const a, b: TVecF32x4): TVecF32x4;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    addps  xmm0, xmm1
    movups [rcx], xmm0
  end;
end;

function SSE2SubF32x4(const a, b: TVecF32x4): TVecF32x4;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    subps  xmm0, xmm1
    movups [rcx], xmm0
  end;
end;

function SSE2MulF32x4(const a, b: TVecF32x4): TVecF32x4;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    mulps  xmm0, xmm1
    movups [rcx], xmm0
  end;
end;

function SSE2DivF32x4(const a, b: TVecF32x4): TVecF32x4;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    divps  xmm0, xmm1
    movups [rcx], xmm0
  end;
end;

function SSE2AddF64x2(const a, b: TVecF64x2): TVecF64x2;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    addpd  xmm0, xmm1
    movupd [rcx], xmm0
  end;
end;

function SSE2SubF64x2(const a, b: TVecF64x2): TVecF64x2;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    subpd  xmm0, xmm1
    movupd [rcx], xmm0
  end;
end;

function SSE2MulF64x2(const a, b: TVecF64x2): TVecF64x2;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    mulpd  xmm0, xmm1
    movupd [rcx], xmm0
  end;
end;

function SSE2DivF64x2(const a, b: TVecF64x2): TVecF64x2;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    divpd  xmm0, xmm1
    movupd [rcx], xmm0
  end;
end;

// ============================================================================
// F64x2 Math Operations (SSE2)
// ============================================================================

function SSE2SqrtF64x2(const a: TVecF64x2): TVecF64x2;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movupd xmm0, [rax]
    sqrtpd xmm0, xmm0
    movupd [rcx], xmm0
  end;
end;

function SSE2MinF64x2(const a, b: TVecF64x2): TVecF64x2;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    minpd  xmm0, xmm1
    movupd [rcx], xmm0
  end;
end;

function SSE2MaxF64x2(const a, b: TVecF64x2): TVecF64x2;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    maxpd  xmm0, xmm1
    movupd [rcx], xmm0
  end;
end;

function SSE2AbsF64x2(const a: TVecF64x2): TVecF64x2;
var
  pa, pr: Pointer;
const
  SignMask: array[0..1] of UInt64 = ($7FFFFFFFFFFFFFFF, $7FFFFFFFFFFFFFFF);
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rip + SignMask]
    andpd  xmm0, xmm1
    movupd [rcx], xmm0
  end;
end;

// ============================================================================
// F64x2 Comparison Operations (SSE2)
// ============================================================================

function SSE2CmpEqF64x2(const a, b: TVecF64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    cmpeqpd xmm0, xmm1
    movmskpd eax, xmm0
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

function SSE2CmpLtF64x2(const a, b: TVecF64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    cmpltpd xmm0, xmm1
    movmskpd eax, xmm0
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

function SSE2CmpLeF64x2(const a, b: TVecF64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    cmplepd xmm0, xmm1
    movmskpd eax, xmm0
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

function SSE2CmpGtF64x2(const a, b: TVecF64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // GT: a > b is same as b < a
  asm
    mov    rax, pa
    mov    rdx, pb
    movupd xmm0, [rdx]  // load b
    movupd xmm1, [rax]  // load a
    cmpltpd xmm0, xmm1  // b < a
    movmskpd eax, xmm0
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

function SSE2CmpGeF64x2(const a, b: TVecF64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // GE: a >= b is same as b <= a
  asm
    mov    rax, pa
    mov    rdx, pb
    movupd xmm0, [rdx]  // load b
    movupd xmm1, [rax]  // load a
    cmplepd xmm0, xmm1  // b <= a
    movmskpd eax, xmm0
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

function SSE2CmpNeF64x2(const a, b: TVecF64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    cmpneqpd xmm0, xmm1
    movmskpd eax, xmm0
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

// ============================================================================
// F64x2 Utility Operations (SSE2)
// ============================================================================

function SSE2LoadF64x2(p: PDouble): TVecF64x2;
var
  pr: Pointer;
begin
  pr := @Result;
  asm
    mov    rax, p
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd [rcx], xmm0
  end;
end;

function SSE2SplatF64x2(value: Double): TVecF64x2;
var
  pr: Pointer;
begin
  pr := @Result;
  asm
    movlpd xmm0, value
    unpcklpd xmm0, xmm0  // duplicate to both lanes
    mov    rcx, pr
    movupd [rcx], xmm0
  end;
end;

function SSE2ZeroF64x2: TVecF64x2;
var
  pr: Pointer;
begin
  pr := @Result;
  asm
    mov    rcx, pr
    xorpd  xmm0, xmm0
    movupd [rcx], xmm0
  end;
end;

procedure SSE2StoreF64x2(p: PDouble; const v: TVecF64x2);
var
  pv: Pointer;
begin
  pv := @v;
  asm
    mov    rax, pv
    mov    rcx, p
    movupd xmm0, [rax]
    movupd [rcx], xmm0
  end;
end;

// ============================================================================
// I32x4 Bitwise Operations (SSE2)
// ============================================================================

function SSE2AndI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pand   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2OrI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    por    xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2XorI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2NotI32x4(const a: TVecI32x4): TVecI32x4;
var
  pa, pr: Pointer;
const
  AllOnes: array[0..3] of UInt32 = ($FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF);
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rip + AllOnes]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndNotI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // PANDN: dest = (NOT a) AND b
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pandn  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

// ============================================================================
// I32x4 Shift Operations (SSE2)
// ============================================================================

function SSE2ShiftLeftI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    pslld  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftRightI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  // Logical right shift (unsigned)
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psrld  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftRightArithI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  // Arithmetic right shift (signed, preserves sign bit)
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psrad  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

// ============================================================================
// I32x4 Comparison Operations (SSE2)
// ============================================================================

function SSE2CmpEqI32x4(const a, b: TVecI32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pcmpeqd xmm0, xmm1
    movmskps eax, xmm0
    mov    mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpGtI32x4(const a, b: TVecI32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pcmpgtd xmm0, xmm1
    movmskps eax, xmm0
    mov    mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpLtI32x4(const a, b: TVecI32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // LT: a < b is same as b > a
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rdx]  // load b
    movdqu xmm1, [rax]  // load a
    pcmpgtd xmm0, xmm1  // b > a
    movmskps eax, xmm0
    mov    mask, eax
  end;
  Result := TMask4(mask);
end;

// SSE2 does not have LE/GE/NE directly, but we can derive them
function SSE2CmpLeI32x4(const a, b: TVecI32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // LE: a <= b is same as NOT(a > b)
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pcmpgtd xmm0, xmm1      // a > b
    pcmpeqd xmm2, xmm2      // all ones
    pxor   xmm0, xmm2       // NOT(a > b)
    movmskps eax, xmm0
    mov    mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpGeI32x4(const a, b: TVecI32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // GE: a >= b is same as NOT(a < b) = NOT(b > a)
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rdx]      // load b
    movdqu xmm1, [rax]      // load a
    pcmpgtd xmm0, xmm1      // b > a
    pcmpeqd xmm2, xmm2      // all ones
    pxor   xmm0, xmm2       // NOT(b > a)
    movmskps eax, xmm0
    mov    mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpNeI32x4(const a, b: TVecI32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // NE: NOT(a == b)
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pcmpeqd xmm0, xmm1      // a == b
    pcmpeqd xmm2, xmm2      // all ones
    pxor   xmm0, xmm2       // NOT(a == b)
    movmskps eax, xmm0
    mov    mask, eax
  end;
  Result := TMask4(mask);
end;

// ============================================================================
// I32x4 Min/Max Operations (SSE2 emulation - no native instruction)
// Note: SSE4.1 has PMINSD/PMAXSD, but SSE2 needs emulation
// ============================================================================

function SSE2MinI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // min(a,b) = (a < b) ? a : b = blend(b, a, a < b)
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqa xmm2, xmm1       // copy b
    pcmpgtd xmm2, xmm0      // b > a (i.e., a < b)
    // mask in xmm2: all 1s where a < b
    movdqa xmm3, xmm0       // copy a
    pand   xmm3, xmm2       // a & mask
    pandn  xmm2, xmm1       // b & ~mask
    por    xmm3, xmm2       // combine
    movdqu [rcx], xmm3
  end;
end;

function SSE2MaxI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // max(a,b) = (a > b) ? a : b = blend(b, a, a > b)
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqa xmm2, xmm0       // copy a
    pcmpgtd xmm2, xmm1      // a > b
    // mask in xmm2: all 1s where a > b
    movdqa xmm3, xmm0       // copy a
    pand   xmm3, xmm2       // a & mask
    pandn  xmm2, xmm1       // b & ~mask
    por    xmm3, xmm2       // combine
    movdqu [rcx], xmm3
  end;
end;

function SSE2AddI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    paddd  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2SubI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    psubd  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

// Note: SSE2 has no direct SIMD multiply for 32-bit integers
// We need to use SSE4.1's pmulld or simulate with pmuludq
// For now, use scalar fallback
function SSE2MulI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] * b.i[i];
end;

// ============================================================================
// I16x8 Operations (SSE2)
// ============================================================================

function SSE2AddI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    paddw  xmm0, xmm1    // 16-bit integer add
    movdqu [rcx], xmm0
  end;
end;

function SSE2SubI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    psubw  xmm0, xmm1    // 16-bit integer sub
    movdqu [rcx], xmm0
  end;
end;

function SSE2MulI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pmullw xmm0, xmm1    // 16-bit integer multiply (low part)
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pand   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2OrI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    por    xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2XorI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2NotI16x8(const a: TVecI16x8): TVecI16x8;
var
  pa, pr: Pointer;
const
  AllOnes: array[0..7] of UInt16 = ($FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF);
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rip + AllOnes]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndNotI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pandn  xmm0, xmm1    // (NOT a) AND b
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftLeftI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psllw  xmm0, xmm1    // 16-bit logical shift left
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftRightI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psrlw  xmm0, xmm1    // 16-bit logical shift right
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftRightArithI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psraw  xmm0, xmm1    // 16-bit arithmetic shift right
    movdqu [rcx], xmm0
  end;
end;

function SSE2CmpEqI16x8(const a, b: TVecI16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqw  xmm0, xmm1    // 16-bit compare equal
    pmovmskb eax, xmm0     // extract mask
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpLtI16x8(const a, b: TVecI16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtw  xmm1, xmm0    // b > a (i.e., a < b)
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpGtI16x8(const a, b: TVecI16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtw  xmm0, xmm1    // a > b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

// ✅ NEW: CmpLe/CmpGe/CmpNe for I16x8 using NOT + base comparison
function SSE2CmpLeI16x8(const a, b: TVecI16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // LE: a <= b is same as NOT(a > b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtw  xmm0, xmm1    // a > b
    pcmpeqw  xmm2, xmm2    // all ones
    pxor     xmm0, xmm2    // NOT(a > b) = a <= b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpGeI16x8(const a, b: TVecI16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // GE: a >= b is same as NOT(a < b) = NOT(b > a)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtw  xmm1, xmm0    // b > a (i.e., a < b)
    pcmpeqw  xmm2, xmm2    // all ones
    pxor     xmm1, xmm2    // NOT(a < b) = a >= b
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpNeI16x8(const a, b: TVecI16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // NE: a != b is same as NOT(a == b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqw  xmm0, xmm1    // a == b
    pcmpeqw  xmm2, xmm2    // all ones
    pxor     xmm0, xmm2    // NOT(a == b) = a != b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2MinI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pminsw xmm0, xmm1    // SSE2 has PMINSW for signed 16-bit
    movdqu [rcx], xmm0
  end;
end;

function SSE2MaxI16x8(const a, b: TVecI16x8): TVecI16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pmaxsw xmm0, xmm1    // SSE2 has PMAXSW for signed 16-bit
    movdqu [rcx], xmm0
  end;
end;

// ============================================================================
// I8x16 Operations (SSE2)
// ============================================================================

function SSE2AddI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    paddb  xmm0, xmm1    // 8-bit integer add
    movdqu [rcx], xmm0
  end;
end;

function SSE2SubI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    psubb  xmm0, xmm1    // 8-bit integer sub
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pand   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2OrI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    por    xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2XorI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2NotI8x16(const a: TVecI8x16): TVecI8x16;
var
  pa, pr: Pointer;
const
  AllOnes: array[0..15] of Byte = ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
                                    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF);
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rip + AllOnes]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndNotI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pandn  xmm0, xmm1    // (NOT a) AND b
    movdqu [rcx], xmm0
  end;
end;

function SSE2CmpEqI8x16(const a, b: TVecI8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqb  xmm0, xmm1    // 8-bit compare equal
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpLtI8x16(const a, b: TVecI8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtb  xmm1, xmm0    // b > a (i.e., a < b)
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpGtI8x16(const a, b: TVecI8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtb  xmm0, xmm1    // a > b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

// ✅ NEW: CmpLe/CmpGe/CmpNe for I8x16 using NOT + base comparison
function SSE2CmpLeI8x16(const a, b: TVecI8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // LE: a <= b is same as NOT(a > b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtb  xmm0, xmm1    // a > b
    pcmpeqb  xmm2, xmm2    // all ones
    pxor     xmm0, xmm2    // NOT(a > b) = a <= b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpGeI8x16(const a, b: TVecI8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // GE: a >= b is same as NOT(a < b) = NOT(b > a)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtb  xmm1, xmm0    // b > a (i.e., a < b)
    pcmpeqb  xmm2, xmm2    // all ones
    pxor     xmm1, xmm2    // NOT(a < b) = a >= b
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpNeI8x16(const a, b: TVecI8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // NE: a != b is same as NOT(a == b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqb  xmm0, xmm1    // a == b
    pcmpeqb  xmm2, xmm2    // all ones
    pxor     xmm0, xmm2    // NOT(a == b) = a != b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2MinI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // SSE2 doesn't have PMINSB (SSE4.1), so we emulate with compare+blend
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqa xmm2, xmm1       // copy b
    pcmpgtb xmm2, xmm0      // b > a (i.e., a < b)
    movdqa xmm3, xmm0       // copy a
    pand   xmm3, xmm2       // a & mask
    pandn  xmm2, xmm1       // b & ~mask
    por    xmm3, xmm2       // combine
    movdqu [rcx], xmm3
  end;
end;

function SSE2MaxI8x16(const a, b: TVecI8x16): TVecI8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // SSE2 doesn't have PMAXSB (SSE4.1), so we emulate with compare+blend
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqa xmm2, xmm0       // copy a
    pcmpgtb xmm2, xmm1      // a > b
    movdqa xmm3, xmm0       // copy a
    pand   xmm3, xmm2       // a & mask
    pandn  xmm2, xmm1       // b & ~mask
    por    xmm3, xmm2       // combine
    movdqu [rcx], xmm3
  end;
end;

// ============================================================================
// U32x4 Operations (SSE2)
// ============================================================================

function SSE2AddU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    paddd  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2SubU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    psubd  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2MulU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // ✅ SSE2 32位乘法模拟 (无 PMULLD)
  // 使用 pmuludq + psrldq + pshufd + punpckldq 标准方法
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr

    movdqu xmm0, [rax]       // a
    movdqu xmm1, [rdx]       // b
    movdqa xmm2, xmm0        // 备份 a
    movdqa xmm3, xmm1        // 备份 b

    // 第1步: 计算 a0*b0, a2*b2
    pmuludq xmm0, xmm1       // xmm0 = [a2*b2(64bit), a0*b0(64bit)]

    // 第2步: 计算 a1*b1, a3*b3 (右移4字节取奇数元素)
    psrldq  xmm2, 4          // xmm2 = [0, a3, a2, a1]
    psrldq  xmm3, 4          // xmm3 = [0, b3, b2, b1]
    pmuludq xmm2, xmm3       // xmm2 = [a3*b3(64bit), a1*b1(64bit)]

    // 第3步: Shuffle 提取低32位乘积
    pshufd xmm0, xmm0, $08   // xmm0 = [a0*b0_L, a0*b0_L, a2*b2_L, a0*b0_L]
    pshufd xmm2, xmm2, $08   // xmm2 = [a1*b1_L, a1*b1_L, a3*b3_L, a1*b1_L]

    // 第4步: Unpack 交织结果
    punpckldq xmm0, xmm2     // xmm0 = [a1*b1_L, a0*b0_L, a3*b3_L, a2*b2_L]? 顺序检查!

    movdqu [rcx], xmm0
  end;
end;

function SSE2AndU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pand   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2OrU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    por    xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2XorU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2NotU32x4(const a: TVecU32x4): TVecU32x4;
var
  pa, pr: Pointer;
const
  AllOnes: array[0..3] of UInt32 = ($FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF);
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rip + AllOnes]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndNotU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pandn  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftLeftU32x4(const a: TVecU32x4; count: Integer): TVecU32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    pslld  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftRightU32x4(const a: TVecU32x4; count: Integer): TVecU32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psrld  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2CmpEqU32x4(const a, b: TVecU32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqd  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpLtU32x4(const a, b: TVecU32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..3] of UInt32 = ($80000000, $80000000, $80000000, $80000000);
begin
  pa := @a;
  pb := @b;
  // Unsigned compare: flip sign bit to use signed comparison
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtd  xmm1, xmm0       // signed(b) > signed(a)
    movmskps eax, xmm1
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpGtU32x4(const a, b: TVecU32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..3] of UInt32 = ($80000000, $80000000, $80000000, $80000000);
begin
  pa := @a;
  pb := @b;
  // Unsigned compare: flip sign bit to use signed comparison
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtd  xmm0, xmm1       // signed(a) > signed(b)
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

// CmpLeU32x4: a <= b = NOT(a > b)
function SSE2CmpLeU32x4(const a, b: TVecU32x4): TMask4;
begin
  Result := TMask4((not Byte(SSE2CmpGtU32x4(a, b))) and $F);
end;

// CmpGeU32x4: a >= b = NOT(a < b)
function SSE2CmpGeU32x4(const a, b: TVecU32x4): TMask4;
begin
  Result := TMask4((not Byte(SSE2CmpLtU32x4(a, b))) and $F);
end;

// CmpNeU32x4: a != b = NOT(a == b)
function SSE2CmpNeU32x4(const a, b: TVecU32x4): TMask4;
begin
  Result := TMask4((not Byte(SSE2CmpEqU32x4(a, b))) and $F);
end;

function SSE2MinU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
const
  SignFlip: array[0..3] of UInt32 = ($80000000, $80000000, $80000000, $80000000);
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // Unsigned min: flip sign bit to use signed comparison
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqu xmm4, [rip + SignFlip]
    movdqa xmm2, xmm0
    movdqa xmm3, xmm1
    pxor   xmm2, xmm4       // flip sign of a
    pxor   xmm3, xmm4       // flip sign of b
    pcmpgtd xmm3, xmm2      // signed(b) > signed(a)
    movdqa xmm5, xmm0       // copy a
    pand   xmm5, xmm3       // a & mask
    pandn  xmm3, xmm1       // b & ~mask
    por    xmm5, xmm3       // combine
    movdqu [rcx], xmm5
  end;
end;

function SSE2MaxU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
const
  SignFlip: array[0..3] of UInt32 = ($80000000, $80000000, $80000000, $80000000);
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // Unsigned max: flip sign bit to use signed comparison
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqu xmm4, [rip + SignFlip]
    movdqa xmm2, xmm0
    movdqa xmm3, xmm1
    pxor   xmm2, xmm4       // flip sign of a
    pxor   xmm3, xmm4       // flip sign of b
    pcmpgtd xmm2, xmm3      // signed(a) > signed(b)
    movdqa xmm5, xmm0       // copy a
    pand   xmm5, xmm2       // a & mask
    pandn  xmm2, xmm1       // b & ~mask
    por    xmm5, xmm2       // combine
    movdqu [rcx], xmm5
  end;
end;

// ============================================================================
// U16x8 Operations (SSE2)
// ============================================================================

function SSE2AddU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    paddw  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2SubU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    psubw  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2MulU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pmullw xmm0, xmm1    // Works for unsigned too (low 16 bits)
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pand   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2OrU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    por    xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2XorU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2NotU16x8(const a: TVecU16x8): TVecU16x8;
var
  pa, pr: Pointer;
const
  AllOnes: array[0..7] of UInt16 = ($FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF);
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rip + AllOnes]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndNotU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pandn  xmm0, xmm1       // xmm0 = (~a) & b
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftLeftU16x8(const a: TVecU16x8; count: Integer): TVecU16x8;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psllw  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2ShiftRightU16x8(const a: TVecU16x8; count: Integer): TVecU16x8;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movd   xmm1, edx
    psrlw  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2CmpEqU16x8(const a, b: TVecU16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqw  xmm0, xmm1
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpLtU16x8(const a, b: TVecU16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..7] of UInt16 = ($8000, $8000, $8000, $8000, $8000, $8000, $8000, $8000);
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtw  xmm1, xmm0       // signed(b) > signed(a)
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpGtU16x8(const a, b: TVecU16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..7] of UInt16 = ($8000, $8000, $8000, $8000, $8000, $8000, $8000, $8000);
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtw  xmm0, xmm1       // signed(a) > signed(b)
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

// ✅ NEW: CmpLe/CmpGe/CmpNe for U16x8 using NOT + base comparison
function SSE2CmpLeU16x8(const a, b: TVecU16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..7] of UInt16 = ($8000, $8000, $8000, $8000, $8000, $8000, $8000, $8000);
begin
  pa := @a;
  pb := @b;
  // LE: a <= b is same as NOT(a > b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtw  xmm0, xmm1       // signed(a) > signed(b) = unsigned(a) > unsigned(b)
    pcmpeqw  xmm2, xmm2       // all ones
    pxor     xmm0, xmm2       // NOT(a > b) = a <= b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpGeU16x8(const a, b: TVecU16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..7] of UInt16 = ($8000, $8000, $8000, $8000, $8000, $8000, $8000, $8000);
begin
  pa := @a;
  pb := @b;
  // GE: a >= b is same as NOT(a < b) = NOT(b > a)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtw  xmm1, xmm0       // signed(b) > signed(a) = unsigned(a) < unsigned(b)
    pcmpeqw  xmm2, xmm2       // all ones
    pxor     xmm1, xmm2       // NOT(a < b) = a >= b
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2CmpNeU16x8(const a, b: TVecU16x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // NE: a != b is same as NOT(a == b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqw  xmm0, xmm1    // a == b
    pcmpeqw  xmm2, xmm2    // all ones
    pxor     xmm0, xmm2    // NOT(a == b) = a != b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask8(mask);
end;

function SSE2MinU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
const
  SignFlip: array[0..7] of UInt16 = ($8000, $8000, $8000, $8000, $8000, $8000, $8000, $8000);
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // Unsigned min: flip sign bit to use signed comparison
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqu xmm4, [rip + SignFlip]
    movdqa xmm2, xmm0
    movdqa xmm3, xmm1
    pxor   xmm2, xmm4       // flip sign of a
    pxor   xmm3, xmm4       // flip sign of b
    pcmpgtw xmm3, xmm2      // signed(b) > signed(a)
    movdqa xmm5, xmm0       // copy a
    pand   xmm5, xmm3       // a & mask
    pandn  xmm3, xmm1       // b & ~mask
    por    xmm5, xmm3       // combine
    movdqu [rcx], xmm5
  end;
end;

function SSE2MaxU16x8(const a, b: TVecU16x8): TVecU16x8;
var
  pa, pb, pr: Pointer;
const
  SignFlip: array[0..7] of UInt16 = ($8000, $8000, $8000, $8000, $8000, $8000, $8000, $8000);
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // Unsigned max: flip sign bit to use signed comparison
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]      // a
    movdqu xmm1, [rdx]      // b
    movdqu xmm4, [rip + SignFlip]
    movdqa xmm2, xmm0
    movdqa xmm3, xmm1
    pxor   xmm2, xmm4       // flip sign of a
    pxor   xmm3, xmm4       // flip sign of b
    pcmpgtw xmm2, xmm3      // signed(a) > signed(b)
    movdqa xmm5, xmm0       // copy a
    pand   xmm5, xmm2       // a & mask
    pandn  xmm2, xmm1       // b & ~mask
    por    xmm5, xmm2       // combine
    movdqu [rcx], xmm5
  end;
end;

// ============================================================================
// U8x16 Operations (SSE2)
// ============================================================================

function SSE2AddU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    paddb  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2SubU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    psubb  xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pand   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2OrU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    por    xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2XorU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2NotU8x16(const a: TVecU8x16): TVecU8x16;
var
  pa, pr: Pointer;
const
  AllOnes: array[0..15] of Byte = ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
                                    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF);
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rip + AllOnes]
    pxor   xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

function SSE2AndNotU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pandn  xmm0, xmm1       // xmm0 = (~a) & b
    movdqu [rcx], xmm0
  end;
end;

function SSE2CmpEqU8x16(const a, b: TVecU8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqb  xmm0, xmm1
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpLtU8x16(const a, b: TVecU8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..15] of Byte = ($80, $80, $80, $80, $80, $80, $80, $80,
                                     $80, $80, $80, $80, $80, $80, $80, $80);
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtb  xmm1, xmm0       // signed(b) > signed(a)
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpGtU8x16(const a, b: TVecU8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..15] of Byte = ($80, $80, $80, $80, $80, $80, $80, $80,
                                     $80, $80, $80, $80, $80, $80, $80, $80);
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtb  xmm0, xmm1       // signed(a) > signed(b)
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

// ✅ NEW: CmpLe/CmpGe/CmpNe for U8x16 using NOT + base comparison
function SSE2CmpLeU8x16(const a, b: TVecU8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..15] of Byte = ($80, $80, $80, $80, $80, $80, $80, $80,
                                     $80, $80, $80, $80, $80, $80, $80, $80);
begin
  pa := @a;
  pb := @b;
  // LE: a <= b is same as NOT(a > b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtb  xmm0, xmm1       // signed(a) > signed(b) = unsigned(a) > unsigned(b)
    pcmpeqb  xmm2, xmm2       // all ones
    pxor     xmm0, xmm2       // NOT(a > b) = a <= b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpGeU8x16(const a, b: TVecU8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
const
  SignFlip: array[0..15] of Byte = ($80, $80, $80, $80, $80, $80, $80, $80,
                                     $80, $80, $80, $80, $80, $80, $80, $80);
begin
  pa := @a;
  pb := @b;
  // GE: a >= b is same as NOT(a < b) = NOT(b > a)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    movdqu   xmm4, [rip + SignFlip]
    pxor     xmm0, xmm4       // flip sign of a
    pxor     xmm1, xmm4       // flip sign of b
    pcmpgtb  xmm1, xmm0       // signed(b) > signed(a) = unsigned(a) < unsigned(b)
    pcmpeqb  xmm2, xmm2       // all ones
    pxor     xmm1, xmm2       // NOT(a < b) = a >= b
    pmovmskb eax, xmm1
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2CmpNeU8x16(const a, b: TVecU8x16): TMask16;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  // NE: a != b is same as NOT(a == b)
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqb  xmm0, xmm1    // a == b
    pcmpeqb  xmm2, xmm2    // all ones
    pxor     xmm0, xmm2    // NOT(a == b) = a != b
    pmovmskb eax, xmm0
    mov      mask, eax
  end;
  Result := TMask16(mask);
end;

function SSE2MinU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pminub xmm0, xmm1    // SSE2 has PMINUB for unsigned 8-bit
    movdqu [rcx], xmm0
  end;
end;

function SSE2MaxU8x16(const a, b: TVecU8x16): TVecU8x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pmaxub xmm0, xmm1    // SSE2 has PMAXUB for unsigned 8-bit
    movdqu [rcx], xmm0
  end;
end;

// === SSE2 Comparison Operations ===

function SSE2CmpEqF32x4(const a, b: TVecF32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpeqps  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpLtF32x4(const a, b: TVecF32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpltps  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpLeF32x4(const a, b: TVecF32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpleps  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpGtF32x4(const a, b: TVecF32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  // GT: swap operands and use LT
  pa := @a;
  pb := @b;
  asm
    mov      rax, pb
    mov      rdx, pa
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpltps  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpGeF32x4(const a, b: TVecF32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  // GE: swap operands and use LE
  pa := @a;
  pb := @b;
  asm
    mov      rax, pb
    mov      rdx, pa
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpleps  xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

function SSE2CmpNeF32x4(const a, b: TVecF32x4): TMask4;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpneqps xmm0, xmm1
    movmskps eax, xmm0
    mov      mask, eax
  end;
  Result := TMask4(mask);
end;

// === SSE2 Math Functions ===

function SSE2AbsF32x4(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  asm
    mov     rax, pa
    mov     rdx, pr
    movups  xmm0, [rax]
    pcmpeqd xmm1, xmm1       // all 1s
    psrld   xmm1, 1          // shift right to get 0x7FFFFFFF
    andps   xmm0, xmm1
    movups  [rdx], xmm0
  end;
end;

function SSE2SqrtF32x4(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  asm
    mov    rax, pa
    mov    rdx, pr
    movups xmm0, [rax]
    sqrtps xmm0, xmm0
    movups [rdx], xmm0
  end;
end;

function SSE2MinF32x4(const a, b: TVecF32x4): TVecF32x4;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    minps  xmm0, xmm1
    movups [rcx], xmm0
  end;
end;

function SSE2MaxF32x4(const a, b: TVecF32x4): TVecF32x4;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    maxps  xmm0, xmm1
    movups [rcx], xmm0
  end;
end;

// === SSE2 Reduction Operations ===

function SSE2ReduceAddF32x4(const a: TVecF32x4): Single;
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov     rax, pa
    movups  xmm0, [rax]
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $4E
    addps   xmm0, xmm1
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $B1
    addss   xmm0, xmm1
    movss   [result], xmm0
  end;
end;

function SSE2ReduceMinF32x4(const a: TVecF32x4): Single;
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov     rax, pa
    movups  xmm0, [rax]
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $4E
    minps   xmm0, xmm1
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $B1
    minss   xmm0, xmm1
    movss   [result], xmm0
  end;
end;

function SSE2ReduceMaxF32x4(const a: TVecF32x4): Single;
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov     rax, pa
    movups  xmm0, [rax]
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $4E
    maxps   xmm0, xmm1
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $B1
    maxss   xmm0, xmm1
    movss   [result], xmm0
  end;
end;

function SSE2ReduceMulF32x4(const a: TVecF32x4): Single;
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov     rax, pa
    movups  xmm0, [rax]
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $4E
    mulps   xmm0, xmm1
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $B1
    mulss   xmm0, xmm1
    movss   [result], xmm0
  end;
end;

// === SSE2 Memory Operations ===

function SSE2LoadF32x4(p: PSingle): TVecF32x4;
var
  pr: Pointer;
begin
  // ✅ Safety check: Assert for nil pointer
  Assert(p <> nil, 'SSE2LoadF32x4: pointer is nil');
  pr := @Result;
  asm
    mov    rax, p
    mov    rdx, pr
    movups xmm0, [rax]
    movups [rdx], xmm0
  end;
end;

function SSE2LoadF32x4Aligned(p: PSingle): TVecF32x4;
var
  pr: Pointer;
begin
  // ✅ Safety check: Assert for nil pointer and 16-byte alignment
  Assert(p <> nil, 'SSE2LoadF32x4Aligned: pointer is nil');
  {$PUSH}{$WARN 4055 OFF}
  Assert((PtrUInt(p) and $F) = 0, 'SSE2LoadF32x4Aligned: Pointer must be 16-byte aligned');
  {$POP}
  pr := @Result;
  asm
    mov    rax, p
    mov    rdx, pr
    movaps xmm0, [rax]
    movups [rdx], xmm0
  end;
end;

procedure SSE2StoreF32x4(p: PSingle; const a: TVecF32x4);
var
  pa: Pointer;
begin
  // ✅ Safety check: Assert for nil pointer
  Assert(p <> nil, 'SSE2StoreF32x4: pointer is nil');
  pa := @a;
  asm
    mov    rax, p
    mov    rdx, pa
    movups xmm0, [rdx]
    movups [rax], xmm0
  end;
end;

procedure SSE2StoreF32x4Aligned(p: PSingle; const a: TVecF32x4);
var
  pa: Pointer;
begin
  // ✅ Safety check: Assert for nil pointer and 16-byte alignment
  Assert(p <> nil, 'SSE2StoreF32x4Aligned: pointer is nil');
  {$PUSH}{$WARN 4055 OFF}
  Assert((PtrUInt(p) and $F) = 0, 'SSE2StoreF32x4Aligned: Pointer must be 16-byte aligned');
  {$POP}
  pa := @a;
  asm
    mov    rax, p
    mov    rdx, pa
    movups xmm0, [rdx]
    movaps [rax], xmm0
  end;
end;

// === SSE2 Utility Operations ===

function SSE2SplatF32x4(value: Single): TVecF32x4;
var
  pr: Pointer;
begin
  pr := @Result;
  asm
    mov    rax, pr
    movss  xmm0, value
    shufps xmm0, xmm0, 0
    movups [rax], xmm0
  end;
end;

function SSE2ZeroF32x4: TVecF32x4;
var
  pr: Pointer;
begin
  pr := @Result;
  asm
    mov    rax, pr
    xorps  xmm0, xmm0
    movups [rax], xmm0
  end;
end;

function SSE2SelectF32x4(const mask: TMask4; const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if (mask and (1 shl i)) <> 0 then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function SSE2ExtractF32x4(const a: TVecF32x4; index: Integer): Single;
var
  safeIndex: Integer;
begin
  // ✅ Safety check: use saturation strategy for index bounds (per project spec)
  safeIndex := index;
  if safeIndex < 0 then safeIndex := 0
  else if safeIndex > 3 then safeIndex := 3;
  Result := a.f[safeIndex];
end;

function SSE2InsertF32x4(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4;
var
  safeIndex: Integer;
begin
  // ✅ Safety check: use saturation strategy for index bounds (per project spec)
  safeIndex := index;
  if safeIndex < 0 then safeIndex := 0
  else if safeIndex > 3 then safeIndex := 3;
  Result := a;
  Result.f[safeIndex] := value;
end;

// === F32x8 Operations (simulate with 2x F32x4) ===

// ✅ SIMD Quality Iteration 4.4: 2×128-bit SSE2 ASM 实现
function SSE2AddF32x8(const a, b: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    // Load 2×128-bit
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rdx]
    movups xmm3, [rdx+16]
    // Add
    addps  xmm0, xmm2
    addps  xmm1, xmm3
    // Store
    movups [rcx], xmm0
    movups [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2AddF32x4(a.lo, b.lo);
  Result.hi := SSE2AddF32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2SubF32x8(const a, b: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rdx]
    movups xmm3, [rdx+16]
    subps  xmm0, xmm2
    subps  xmm1, xmm3
    movups [rcx], xmm0
    movups [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2SubF32x4(a.lo, b.lo);
  Result.hi := SSE2SubF32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2MulF32x8(const a, b: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rdx]
    movups xmm3, [rdx+16]
    mulps  xmm0, xmm2
    mulps  xmm1, xmm3
    movups [rcx], xmm0
    movups [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2MulF32x4(a.lo, b.lo);
  Result.hi := SSE2MulF32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2DivF32x8(const a, b: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rdx]
    movups xmm3, [rdx+16]
    divps  xmm0, xmm2
    divps  xmm1, xmm3
    movups [rcx], xmm0
    movups [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2DivF32x4(a.lo, b.lo);
  Result.hi := SSE2DivF32x4(a.hi, b.hi);
{$ENDIF}
end;

// === F32x8 Comparison Operations (direct 2×128-bit ASM) ===
// ✅ Converted from recursive calls to eliminate function call overhead

function SSE2CmpEqF32x8(const a, b: TVecF32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    // Compare lo (first 128 bits)
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpeqps  xmm0, xmm1      // a.lo == b.lo
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      lo_mask, eax
    // Compare hi (second 128 bits)
    movups   xmm0, [rax+16]
    movups   xmm1, [rdx+16]
    cmpeqps  xmm0, xmm1      // a.hi == b.hi
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

function SSE2CmpLtF32x8(const a, b: TVecF32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    // Compare lo (first 128 bits)
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpltps  xmm0, xmm1      // a.lo < b.lo
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      lo_mask, eax
    // Compare hi (second 128 bits)
    movups   xmm0, [rax+16]
    movups   xmm1, [rdx+16]
    cmpltps  xmm0, xmm1      // a.hi < b.hi
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

function SSE2CmpLeF32x8(const a, b: TVecF32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    // Compare lo (first 128 bits)
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpleps  xmm0, xmm1      // a.lo <= b.lo
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      lo_mask, eax
    // Compare hi (second 128 bits)
    movups   xmm0, [rax+16]
    movups   xmm1, [rdx+16]
    cmpleps  xmm0, xmm1      // a.hi <= b.hi
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

function SSE2CmpGtF32x8(const a, b: TVecF32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  // GT: swap operands and use LT
  pa := @a;
  pb := @b;
  asm
    mov      rax, pb
    mov      rdx, pa
    // Compare lo (first 128 bits) - swapped operands
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpltps  xmm0, xmm1      // b.lo < a.lo => a.lo > b.lo
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      lo_mask, eax
    // Compare hi (second 128 bits) - swapped operands
    movups   xmm0, [rax+16]
    movups   xmm1, [rdx+16]
    cmpltps  xmm0, xmm1      // b.hi < a.hi => a.hi > b.hi
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

function SSE2CmpGeF32x8(const a, b: TVecF32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  // GE: swap operands and use LE
  pa := @a;
  pb := @b;
  asm
    mov      rax, pb
    mov      rdx, pa
    // Compare lo (first 128 bits) - swapped operands
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpleps  xmm0, xmm1      // b.lo <= a.lo => a.lo >= b.lo
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      lo_mask, eax
    // Compare hi (second 128 bits) - swapped operands
    movups   xmm0, [rax+16]
    movups   xmm1, [rdx+16]
    cmpleps  xmm0, xmm1      // b.hi <= a.hi => a.hi >= b.hi
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

function SSE2CmpNeF32x8(const a, b: TVecF32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    // Compare lo (first 128 bits)
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpneqps xmm0, xmm1      // a.lo != b.lo
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      lo_mask, eax
    // Compare hi (second 128 bits)
    movups   xmm0, [rax+16]
    movups   xmm1, [rdx+16]
    cmpneqps xmm0, xmm1      // a.hi != b.hi
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

// === SSE2 Memory Functions ===

function MemEqual_SSE2(a, b: Pointer; len: SizeUInt): LongBool;
var
  pa, pb: PByte;
  i: SizeUInt;
  maskA, maskB: Integer;
begin
  {$PUSH}{$Q-}{$R-}  // Disable overflow/range checks for SIMD loop
  if len = 0 then
  begin
    Result := True;
    Exit;
  end;

  if (a = nil) or (b = nil) then
  begin
    Result := (a = b);
    Exit;
  end;

  pa := PByte(a);
  pb := PByte(b);
  i := 0;

  // Process 16 bytes at a time using SSE2
  while i + 16 <= len do
  begin
    asm
      mov   rax, pa
      mov   rdx, pb
      add   rax, i
      add   rdx, i
      movdqu xmm0, [rax]
      movdqu xmm1, [rdx]
      pcmpeqb xmm0, xmm1
      pmovmskb eax, xmm0
      mov   maskA, eax
    end;

    if maskA <> $FFFF then
    begin
      Result := False;
      Exit;
    end;

    Inc(i, 16);
  end;

  // Handle remaining bytes
  while i < len do
  begin
    if pa[i] <> pb[i] then
    begin
      Result := False;
      Exit;
    end;
    Inc(i);
  end;

  Result := True;
  {$POP}
end;

function MemFindByte_SSE2(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
var
  pb: PByte;
  i: SizeUInt;
  mask: Integer;
  bitPos: Integer;
begin
  if (len = 0) or (p = nil) then
  begin
    Result := -1;
    Exit;
  end;

  pb := PByte(p);
  i := 0;

  // Process 16 bytes at a time using SSE2
  while i + 16 <= len do
  begin
    asm
      mov      rax, pb
      add      rax, i
      movzx    edx, value
      movd     xmm1, edx
      punpcklbw xmm1, xmm1
      pshuflw  xmm1, xmm1, 0
      punpcklqdq xmm1, xmm1  // Broadcast value to all 16 bytes
      movdqu   xmm0, [rax]
      pcmpeqb  xmm0, xmm1
      pmovmskb eax, xmm0
      mov      mask, eax
    end;

    if mask <> 0 then
    begin
      // Find first set bit
      asm
        bsf eax, mask
        mov bitPos, eax
      end;
      Result := PtrInt(i) + bitPos;
      Exit;
    end;

    Inc(i, 16);
  end;

  // Handle remaining bytes
  while i < len do
  begin
    if pb[i] = value then
    begin
      Result := PtrInt(i);
      Exit;
    end;
    Inc(i);
  end;

  Result := -1;
end;

procedure MemCopy_SSE2(src, dst: Pointer; len: SizeUInt); assembler; nostackframe;
asm
  {$IFDEF UNIX}
  // RDI = src, RSI = dst, RDX = len
  test rdx, rdx
  jz @done
  test rdi, rdi
  jz @done
  test rsi, rsi
  jz @done
  cmp rdi, rsi
  je @done

  xor rcx, rcx           // i = 0

@loop16:
  lea rax, [rcx + 16]
  cmp rax, rdx
  ja @remainder
  movdqu xmm0, [rdi + rcx]
  movdqu [rsi + rcx], xmm0
  add rcx, 16
  jmp @loop16

@remainder:
  cmp rcx, rdx
  jae @done
  mov al, [rdi + rcx]
  mov [rsi + rcx], al
  inc rcx
  jmp @remainder

@done:
  {$ELSE}
  // Windows x64: RCX = src, RDX = dst, R8 = len
  test r8, r8
  jz @done
  test rcx, rcx
  jz @done
  test rdx, rdx
  jz @done
  cmp rcx, rdx
  je @done

  xor r9, r9            // i = 0

@loop16:
  lea rax, [r9 + 16]
  cmp rax, r8
  ja @remainder
  movdqu xmm0, [rcx + r9]
  movdqu [rdx + r9], xmm0
  add r9, 16
  jmp @loop16

@remainder:
  cmp r9, r8
  jae @done
  mov al, [rcx + r9]
  mov [rdx + r9], al
  inc r9
  jmp @remainder

@done:
  {$ENDIF}
end;

procedure MemSet_SSE2(dst: Pointer; len: SizeUInt; value: Byte); assembler; nostackframe;
asm
  {$IFDEF UNIX}
  // RDI = dst, RSI = len, RDX = value
  test rsi, rsi
  jz @done
  test rdi, rdi
  jz @done

  // Broadcast value to all 16 bytes
  movd xmm0, edx
  punpcklbw xmm0, xmm0
  pshuflw xmm0, xmm0, 0
  punpcklqdq xmm0, xmm0

  xor rcx, rcx           // i = 0

@loop16:
  lea rax, [rcx + 16]
  cmp rax, rsi
  ja @remainder
  movdqu [rdi + rcx], xmm0
  add rcx, 16
  jmp @loop16

@remainder:
  cmp rcx, rsi
  jae @done
  mov [rdi + rcx], dl
  inc rcx
  jmp @remainder

@done:
  {$ELSE}
  // Windows x64: RCX = dst, RDX = len, R8 = value
  test rdx, rdx
  jz @done
  test rcx, rcx
  jz @done

  // Broadcast value to all 16 bytes
  movzx r8d, r8b
  movd xmm0, r8d
  punpcklbw xmm0, xmm0
  pshuflw xmm0, xmm0, 0
  punpcklqdq xmm0, xmm0

  xor r9, r9             // i = 0
  mov al, r8b

@loop16:
  lea rax, [r9 + 16]
  cmp rax, rdx
  ja @remainder
  movdqu [rcx + r9], xmm0
  add r9, 16
  jmp @loop16

@remainder:
  cmp r9, rdx
  jae @done
  mov [rcx + r9], al
  inc r9
  jmp @remainder

@done:
  {$ENDIF}
end;

function SumBytes_SSE2(p: Pointer; len: SizeUInt): UInt64;
var
  pb: PByte;
  i: SizeUInt;
  sum0, sum1, sum2, sum3: UInt32;
begin
  {$PUSH}{$Q-}{$R-}  // Disable overflow/range checks for SIMD loop
  if (len = 0) or (p = nil) then
  begin
    Result := 0;
    Exit;
  end;

  pb := PByte(p);
  i := 0;
  sum0 := 0;
  sum1 := 0;
  sum2 := 0;
  sum3 := 0;

  // Process 16 bytes at a time using SSE2
  // Use psadbw (sum of absolute differences) with zero to sum bytes
  while i + 16 <= len do
  begin
    asm
      mov      rax, pb
      add      rax, i
      movdqu   xmm0, [rax]
      pxor     xmm1, xmm1      // Zero register
      psadbw   xmm0, xmm1      // Sum bytes: result in low 16 bits of each 64-bit lane
      movd     eax, xmm0       // Get lower 64-bit sum
      add      sum0, eax
      psrldq   xmm0, 8         // Shift right 8 bytes
      movd     eax, xmm0       // Get upper 64-bit sum
      add      sum1, eax
    end;
    Inc(i, 16);
  end;

  // Handle remaining bytes
  while i < len do
  begin
    Inc(sum2, pb[i]);
    Inc(i);
  end;

  Result := UInt64(sum0) + UInt64(sum1) + UInt64(sum2) + UInt64(sum3);
  {$POP}
end;

function CountByte_SSE2(p: Pointer; len: SizeUInt; value: Byte): SizeUInt; assembler; nostackframe;
// SysV: RDI = p, RSI = len, RDX = value
// Win64: RCX = p, RDX = len, R8 = value
// Use SWAR popcount for 16-bit mask
asm
  {$IFDEF UNIX}
  xor rax, rax           // count = 0
  test rsi, rsi
  jz @done
  test rdi, rdi
  jz @done

  // Broadcast value to all 16 bytes in xmm1
  movzx edx, dl
  movd xmm1, edx
  punpcklbw xmm1, xmm1
  pshuflw xmm1, xmm1, 0
  punpcklqdq xmm1, xmm1

  xor rcx, rcx           // i = 0

@loop16:
  lea r8, [rcx + 16]
  cmp r8, rsi
  ja @remainder
  movdqu xmm0, [rdi + rcx]
  pcmpeqb xmm0, xmm1
  pmovmskb r8d, xmm0
  // Popcount using SWAR
  mov r9d, r8d
  shr r9d, 1
  and r9d, $5555
  sub r8d, r9d
  mov r9d, r8d
  shr r9d, 2
  and r8d, $3333
  and r9d, $3333
  add r8d, r9d
  mov r9d, r8d
  shr r9d, 4
  add r8d, r9d
  and r8d, $0F0F
  mov r9d, r8d
  shr r9d, 8
  add r8d, r9d
  and r8d, $FF
  add rax, r8
  add rcx, 16
  jmp @loop16

@remainder:
  cmp rcx, rsi
  jae @done
  movzx r8d, byte ptr [rdi + rcx]
  cmp r8d, edx
  jne @skip
  inc rax
@skip:
  inc rcx
  jmp @remainder

@done:
  {$ELSE}
  xor rax, rax           // count = 0
  test rdx, rdx
  jz @done
  test rcx, rcx
  jz @done

  // Broadcast value to all 16 bytes in xmm1
  movzx r8d, r8b
  movd xmm1, r8d
  punpcklbw xmm1, xmm1
  pshuflw xmm1, xmm1, 0
  punpcklqdq xmm1, xmm1

  xor r9, r9             // i = 0

@loop16:
  lea r10, [r9 + 16]
  cmp r10, rdx
  ja @remainder
  movdqu xmm0, [rcx + r9]
  pcmpeqb xmm0, xmm1
  pmovmskb r10d, xmm0
  // Popcount using SWAR
  mov r11d, r10d
  shr r11d, 1
  and r11d, $5555
  sub r10d, r11d
  mov r11d, r10d
  shr r11d, 2
  and r10d, $3333
  and r11d, $3333
  add r10d, r11d
  mov r11d, r10d
  shr r11d, 4
  add r10d, r11d
  and r10d, $0F0F
  mov r11d, r10d
  shr r11d, 8
  add r10d, r11d
  and r10d, $FF
  add rax, r10
  add r9, 16
  jmp @loop16

@remainder:
  cmp r9, rdx
  jae @done
  movzx r10d, byte ptr [rcx + r9]
  cmp r10d, r8d
  jne @skip
  inc rax
@skip:
  inc r9
  jmp @remainder

@done:
  {$ENDIF}
end;

// === Extended Math Functions ===

// FMA emulation: a*b + c (SSE2 has no native FMA)
function SSE2FmaF32x4(const a, b, c: TVecF32x4): TVecF32x4;
var
  pa, pb, pc, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pc := @c;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pc
    mov    r8, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    movups xmm2, [rcx]
    mulps  xmm0, xmm1
    addps  xmm0, xmm2
    movups [r8], xmm0
  end;
end;

// Reciprocal approximation (1/x)
function SSE2RcpF32x4(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movups xmm0, [rax]
    rcpps  xmm0, xmm0     // Approximate reciprocal (12-bit precision)
    movups [rcx], xmm0
  end;
end;

// Reciprocal square root approximation (1/sqrt(x))
function SSE2RsqrtF32x4(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movups xmm0, [rax]
    rsqrtps xmm0, xmm0    // Approximate rsqrt (12-bit precision)
    movups [rcx], xmm0
  end;
end;

// Floor/Ceil/Round/Trunc: Use SSE4.1 roundps if available, otherwise scalar fallback
// SSE4.1 roundps immediate values:
//   0 = Round to nearest (even)
//   1 = Round toward negative infinity (floor)
//   2 = Round toward positive infinity (ceil) 
//   3 = Round toward zero (truncate)

var
  g_HasSSE41: Boolean = False;
  g_SSE41CheckState: LongInt = 0; // 0=未检查, 1=检查中, 2=已完成

// ✅ Thread-safe SSE4.1 detection using atomic operations
procedure CheckSSE41;
var
  oldState: LongInt;
begin
  // 快速路径: 已完成检查
  if g_SSE41CheckState = 2 then Exit;

  oldState := InterlockedCompareExchange(g_SSE41CheckState, 1, 0);
  if oldState = 0 then
  begin
    // 我们是第一个检查者
    g_HasSSE41 := HasSSE41;
    WriteBarrier;
    InterlockedExchange(g_SSE41CheckState, 2);
  end
  else if oldState = 1 then
  begin
    // 另一个线程正在检查，自旋等待
    while g_SSE41CheckState <> 2 do
    begin
      ReadBarrier;
      ThreadSwitch;
    end;
  end;
  // oldState = 2: 已完成，直接返回
end;

function SSE2FloorF32x4(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
  i: Integer;
begin
  CheckSSE41;
  if g_HasSSE41 then
  begin
    pa := @a;
    pr := @Result;
    asm
      mov    rax, pa
      mov    rcx, pr
      movups xmm0, [rax]
      // roundps xmm0, xmm0, 1  (floor)
      db $66, $0F, $3A, $08, $C0, $01
      movups [rcx], xmm0
    end;
  end
  else
  begin
    for i := 0 to 3 do
      Result.f[i] := Int(a.f[i]);
    // Adjust for negative numbers
    for i := 0 to 3 do
      if (a.f[i] < 0) and (Result.f[i] <> a.f[i]) then
        Result.f[i] := Result.f[i] - 1.0;
  end;
end;

function SSE2CeilF32x4(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
  i: Integer;
begin
  CheckSSE41;
  if g_HasSSE41 then
  begin
    pa := @a;
    pr := @Result;
    asm
      mov    rax, pa
      mov    rcx, pr
      movups xmm0, [rax]
      // roundps xmm0, xmm0, 2  (ceil)
      db $66, $0F, $3A, $08, $C0, $02
      movups [rcx], xmm0
    end;
  end
  else
  begin
    for i := 0 to 3 do
      Result.f[i] := Int(a.f[i]);
    // Adjust for positive numbers
    for i := 0 to 3 do
      if (a.f[i] > 0) and (Result.f[i] <> a.f[i]) then
        Result.f[i] := Result.f[i] + 1.0;
  end;
end;

function SSE2RoundF32x4(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
  i: Integer;
begin
  CheckSSE41;
  if g_HasSSE41 then
  begin
    pa := @a;
    pr := @Result;
    asm
      mov    rax, pa
      mov    rcx, pr
      movups xmm0, [rax]
      // roundps xmm0, xmm0, 0  (round to nearest even)
      db $66, $0F, $3A, $08, $C0, $00
      movups [rcx], xmm0
    end;
  end
  else
  begin
    for i := 0 to 3 do
      Result.f[i] := Round(a.f[i]);
  end;
end;

function SSE2TruncF32x4(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
  i: Integer;
begin
  CheckSSE41;
  if g_HasSSE41 then
  begin
    pa := @a;
    pr := @Result;
    asm
      mov    rax, pa
      mov    rcx, pr
      movups xmm0, [rax]
      // roundps xmm0, xmm0, 3  (truncate)
      db $66, $0F, $3A, $08, $C0, $03
      movups [rcx], xmm0
    end;
  end
  else
  begin
    for i := 0 to 3 do
      Result.f[i] := Int(a.f[i]);
  end;
end;

// Clamp using SSE2 min/max
function SSE2ClampF32x4(const a, minVal, maxVal: TVecF32x4): TVecF32x4;
var
  pa, pMin, pMax, pr: Pointer;
begin
  pa := @a;
  pMin := @minVal;
  pMax := @maxVal;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pMin
    mov    rcx, pMax
    mov    r8, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    movups xmm2, [rcx]
    maxps  xmm0, xmm1     // max(a, minVal)
    minps  xmm0, xmm2     // min(result, maxVal)
    movups [r8], xmm0
  end;
end;

// === Vector Math Functions ===

// Dot product (4 elements)
function SSE2DotF32x4(const a, b: TVecF32x4): Single;
var
  pa, pb: Pointer;
begin
  pa := @a;
  pb := @b;
  asm
    mov     rax, pa
    mov     rdx, pb
    movups  xmm0, [rax]
    movups  xmm1, [rdx]
    mulps   xmm0, xmm1     // Element-wise multiply
    // Horizontal add: [a*b, c*d, e*f, g*h] -> sum
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $4E // Swap high/low pairs
    addps   xmm0, xmm1
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $B1 // Swap adjacent
    addss   xmm0, xmm1
    movss   [result], xmm0
  end;
end;

// Dot product (3 elements, ignore w)
function SSE2DotF32x3(const a, b: TVecF32x4): Single;
var
  t: TVecF32x4;
  pa, pb: Pointer;
begin
  pa := @a;
  pb := @b;
  asm
    mov     rax, pa
    mov     rdx, pb
    movups  xmm0, [rax]
    movups  xmm1, [rdx]
    mulps   xmm0, xmm1
    // Zero the w component before summing
    xorps   xmm1, xmm1
    movss   xmm1, xmm0     // xmm1 = [x, 0, 0, 0]
    shufps  xmm0, xmm0, $E9 // xmm0 = [y, z, z, w]
    addss   xmm1, xmm0     // x + y
    shufps  xmm0, xmm0, $E9
    addss   xmm1, xmm0     // x + y + z
    movss   [result], xmm1
  end;
end;

// Cross product (3D)
function SSE2CrossF32x3(const a, b: TVecF32x4): TVecF32x4;
var
  pa, pb, pr: Pointer;
begin
  // Cross = (a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x, 0)
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov     rax, pa
    mov     rdx, pb
    mov     rcx, pr
    movups  xmm0, [rax]        // a = [x, y, z, w]
    movups  xmm1, [rdx]        // b = [x, y, z, w]
    
    // Shuffle a: [y, z, x, w]
    movaps  xmm2, xmm0
    shufps  xmm2, xmm2, $C9    // 11 00 10 01 -> y,z,x,w
    
    // Shuffle b: [z, x, y, w]
    movaps  xmm3, xmm1
    shufps  xmm3, xmm3, $D2    // 11 01 00 10 -> z,x,y,w
    
    mulps   xmm2, xmm3         // [a.y*b.z, a.z*b.x, a.x*b.y, ...]
    
    // Shuffle a: [z, x, y, w]
    movaps  xmm4, xmm0
    shufps  xmm4, xmm4, $D2
    
    // Shuffle b: [y, z, x, w]
    movaps  xmm5, xmm1
    shufps  xmm5, xmm5, $C9
    
    mulps   xmm4, xmm5         // [a.z*b.y, a.x*b.z, a.y*b.x, ...]
    
    subps   xmm2, xmm4         // Subtract to get [x', y', z', w']
    
    movups  [rcx], xmm2
  end;
  Result.f[3] := 0.0; // Ensure w=0
end;

// Vector length (4 elements)
function SSE2LengthF32x4(const a: TVecF32x4): Single;
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov     rax, pa
    movups  xmm0, [rax]
    mulps   xmm0, xmm0      // Square each element
    // Horizontal add
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $4E
    addps   xmm0, xmm1
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $B1
    addss   xmm0, xmm1
    sqrtss  xmm0, xmm0      // Square root
    movss   [result], xmm0
  end;
end;

// Vector length (3 elements)
function SSE2LengthF32x3(const a: TVecF32x4): Single;
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov     rax, pa
    movups  xmm0, [rax]
    // Zero w before squaring
    pcmpeqd xmm1, xmm1
    psrldq  xmm1, 4          // Shift right to create mask [FF,FF,FF,00]
    andps   xmm0, xmm1       // Zero w
    mulps   xmm0, xmm0
    // Horizontal add
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $4E
    addps   xmm0, xmm1
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $B1
    addss   xmm0, xmm1
    sqrtss  xmm0, xmm0
    movss   [result], xmm0
  end;
end;

// Normalize vector (4 elements)
function SSE2NormalizeF32x4(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
  len: Single;
begin
  len := SSE2LengthF32x4(a);
  if len > 0 then
  begin
    pa := @a;
    pr := @Result;
    asm
      mov     rax, pa
      mov     rcx, pr
      movups  xmm0, [rax]
      movss   xmm1, len
      shufps  xmm1, xmm1, 0   // Broadcast length
      divps   xmm0, xmm1      // Divide each element by length
      movups  [rcx], xmm0
    end;
  end
  else
    Result := a;
end;

// Normalize vector (3 elements, w=0)
function SSE2NormalizeF32x3(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
  len: Single;
begin
  len := SSE2LengthF32x3(a);
  if len > 0 then
  begin
    pa := @a;
    pr := @Result;
    asm
      mov     rax, pa
      mov     rcx, pr
      movups  xmm0, [rax]
      movss   xmm1, len
      shufps  xmm1, xmm1, 0
      divps   xmm0, xmm1
      movups  [rcx], xmm0
    end;
    Result.f[3] := 0.0;
  end
  else
  begin
    Result := a;
    Result.f[3] := 0.0;
  end;
end;

// ✅ F32x8 扩展函数 (2026-02-05) - 使用 2x F32x4 仿真

function SSE2FmaF32x8(const a, b, c: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var pa, pb, pc, pr: Pointer;
begin
  pa := @a; pb := @b; pc := @c; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    r8,  pc
    mov    rcx, pr
    // Load a
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    // Load b
    movups xmm2, [rdx]
    movups xmm3, [rdx+16]
    // Multiply a * b
    mulps  xmm0, xmm2
    mulps  xmm1, xmm3
    // Load c
    movups xmm4, [r8]
    movups xmm5, [r8+16]
    // Add c
    addps  xmm0, xmm4
    addps  xmm1, xmm5
    // Store
    movups [rcx], xmm0
    movups [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2FmaF32x4(a.lo, b.lo, c.lo);
  Result.hi := SSE2FmaF32x4(a.hi, b.hi, c.hi);
{$ENDIF}
end;

// ✅ SIMD Quality Iteration 6.3: F32x8 舍入操作 SSE2 ASM 实现
function SSE2FloorF32x8(const a: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var
  pa, pr: Pointer;
const
  OneSingle: array[0..3] of Single = (1.0, 1.0, 1.0, 1.0);
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr

    // 加载低 4 个 float
    movups xmm0, [rax]
    // 加载高 4 个 float
    movups xmm4, [rax+16]

    // === 处理低 4 个元素 (xmm0) ===
    // 保存原值
    movaps xmm1, xmm0
    // 截断转整数
    cvttps2dq xmm0, xmm0
    // 转回浮点
    cvtdq2ps xmm0, xmm0
    // 比较: 原值 < 截断值？
    movaps xmm2, xmm1
    cmpltps xmm2, xmm0
    // 加载 1.0
    movups xmm3, [rip + OneSingle]
    // 掩码 & 1.0
    andps  xmm2, xmm3
    // 减去修正值
    subps  xmm0, xmm2

    // === 处理高 4 个元素 (xmm4) ===
    // 保存原值
    movaps xmm5, xmm4
    // 截断转整数
    cvttps2dq xmm4, xmm4
    // 转回浮点
    cvtdq2ps xmm4, xmm4
    // 比较: 原值 < 截断值？
    movaps xmm6, xmm5
    cmpltps xmm6, xmm4
    // 掩码 & 1.0
    andps  xmm6, xmm3
    // 减去修正值
    subps  xmm4, xmm6

    // 保存结果
    movups [rcx], xmm0
    movups [rcx+16], xmm4
  end;
{$ELSE}
begin
  Result.lo := SSE2FloorF32x4(a.lo);
  Result.hi := SSE2FloorF32x4(a.hi);
{$ENDIF}
end;

function SSE2CeilF32x8(const a: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var
  pa, pr: Pointer;
const
  OneSingle: array[0..3] of Single = (1.0, 1.0, 1.0, 1.0);
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr

    // 加载低 4 个 float
    movups xmm0, [rax]
    // 加载高 4 个 float
    movups xmm4, [rax+16]

    // === 处理低 4 个元素 (xmm0) ===
    // 保存原值
    movaps xmm1, xmm0
    // 截断转整数
    cvttps2dq xmm0, xmm0
    // 转回浮点
    cvtdq2ps xmm0, xmm0
    // 比较: 截断值 < 原值？
    cmpltps xmm0, xmm1
    // 加载 1.0
    movups xmm3, [rip + OneSingle]
    // 掩码 & 1.0
    andps  xmm0, xmm3
    // 重新加载截断值
    movaps xmm2, xmm1
    cvttps2dq xmm2, xmm2
    cvtdq2ps xmm2, xmm2
    // 加上修正值
    addps  xmm0, xmm2

    // === 处理高 4 个元素 (xmm4) ===
    // 保存原值
    movaps xmm5, xmm4
    // 截断转整数
    cvttps2dq xmm4, xmm4
    // 转回浮点
    cvtdq2ps xmm4, xmm4
    // 比较: 截断值 < 原值？
    cmpltps xmm4, xmm5
    // 掩码 & 1.0
    andps  xmm4, xmm3
    // 重新加载截断值
    movaps xmm6, xmm5
    cvttps2dq xmm6, xmm6
    cvtdq2ps xmm6, xmm6
    // 加上修正值
    addps  xmm4, xmm6

    // 保存结果
    movups [rcx], xmm0
    movups [rcx+16], xmm4
  end;
{$ELSE}
begin
  Result.lo := SSE2CeilF32x4(a.lo);
  Result.hi := SSE2CeilF32x4(a.hi);
{$ENDIF}
end;

function SSE2RoundF32x8(const a: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var
  pa, pr: Pointer;
const
  HalfSingle: array[0..3] of Single = (0.5, 0.5, 0.5, 0.5);
  OneSingle: array[0..3] of Single = (1.0, 1.0, 1.0, 1.0);
  SignMaskPS: array[0..3] of UInt32 = ($80000000, $80000000, $80000000, $80000000);
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr

    // 加载低 4 个 float
    movups xmm0, [rax]
    // 加载高 4 个 float
    movups xmm4, [rax+16]

    // === 处理低 4 个元素 (xmm0) ===
    // 保存原值
    movaps xmm1, xmm0
    // 提取符号
    movups xmm2, [rip + SignMaskPS]
    movaps xmm3, xmm1
    andps  xmm3, xmm2  // xmm3 = sign
    // 取绝对值
    andnps xmm2, xmm1  // xmm2 = abs(x)
    // 加 0.5
    movups xmm1, [rip + HalfSingle]
    addps  xmm2, xmm1
    // 截断
    cvttps2dq xmm2, xmm2
    cvtdq2ps xmm2, xmm2
    // 恢复符号
    orps   xmm2, xmm3
    movaps xmm0, xmm2

    // === 处理高 4 个元素 (xmm4) ===
    // 保存原值
    movaps xmm5, xmm4
    // 提取符号
    movups xmm6, [rip + SignMaskPS]
    movaps xmm7, xmm5
    andps  xmm7, xmm6  // xmm7 = sign
    // 取绝对值
    andnps xmm6, xmm5  // xmm6 = abs(x)
    // 加 0.5
    addps  xmm6, xmm1  // 复用 HalfSingle
    // 截断
    cvttps2dq xmm6, xmm6
    cvtdq2ps xmm6, xmm6
    // 恢复符号
    orps   xmm6, xmm7
    movaps xmm4, xmm6

    // 保存结果
    movups [rcx], xmm0
    movups [rcx+16], xmm4
  end;
{$ELSE}
begin
  Result.lo := SSE2RoundF32x4(a.lo);
  Result.hi := SSE2RoundF32x4(a.hi);
{$ENDIF}
end;

function SSE2TruncF32x8(const a: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var
  pa, pr: Pointer;
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr

    // 加载低 4 个 float
    movups xmm0, [rax]
    // 加载高 4 个 float
    movups xmm1, [rax+16]

    // 截断低 4 个元素
    cvttps2dq xmm0, xmm0
    cvtdq2ps xmm0, xmm0

    // 截断高 4 个元素
    cvttps2dq xmm1, xmm1
    cvtdq2ps xmm1, xmm1

    // 保存结果
    movups [rcx], xmm0
    movups [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2TruncF32x4(a.lo);
  Result.hi := SSE2TruncF32x4(a.hi);
{$ENDIF}
end;

function SSE2AbsF32x8(const a: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var pa, pr: Pointer;
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    // Create sign mask (0x7FFFFFFF)
    pcmpeqd xmm2, xmm2       // all 1s
    psrld   xmm2, 1           // clear sign bit
    movaps  xmm3, xmm2
    // Clear sign bits
    andps   xmm0, xmm2
    andps   xmm1, xmm3
    movups  [rcx], xmm0
    movups  [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2AbsF32x4(a.lo);
  Result.hi := SSE2AbsF32x4(a.hi);
{$ENDIF}
end;

function SSE2SqrtF32x8(const a: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var pa, pr: Pointer;
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    sqrtps xmm0, xmm0
    sqrtps xmm1, xmm1
    movups [rcx], xmm0
    movups [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2SqrtF32x4(a.lo);
  Result.hi := SSE2SqrtF32x4(a.hi);
{$ENDIF}
end;

function SSE2MinF32x8(const a, b: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rdx]
    movups xmm3, [rdx+16]
    minps  xmm0, xmm2
    minps  xmm1, xmm3
    movups [rcx], xmm0
    movups [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2MinF32x4(a.lo, b.lo);
  Result.hi := SSE2MinF32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2MaxF32x8(const a, b: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rdx]
    movups xmm3, [rdx+16]
    maxps  xmm0, xmm2
    maxps  xmm1, xmm3
    movups [rcx], xmm0
    movups [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2MaxF32x4(a.lo, b.lo);
  Result.hi := SSE2MaxF32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2ClampF32x8(const a, minVal, maxVal: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var pa, pmin, pmax, pr: Pointer;
begin
  pa := @a; pmin := @minVal; pmax := @maxVal; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pmin
    mov    r8,  pmax
    mov    rcx, pr
    // Load a
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    // Load minVal
    movups xmm2, [rdx]
    movups xmm3, [rdx+16]
    // Max with minVal
    maxps  xmm0, xmm2
    maxps  xmm1, xmm3
    // Load maxVal
    movups xmm4, [r8]
    movups xmm5, [r8+16]
    // Min with maxVal
    minps  xmm0, xmm4
    minps  xmm1, xmm5
    // Store
    movups [rcx], xmm0
    movups [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2ClampF32x4(a.lo, minVal.lo, maxVal.lo);
  Result.hi := SSE2ClampF32x4(a.hi, minVal.hi, maxVal.hi);
{$ENDIF}
end;

function SSE2ReduceAddF32x8(const a: TVecF32x8): Single;
{$IFDEF CPUX64}
var pa: Pointer; res: Single;
begin
  pa := @a;
  asm
    mov    rax, pa
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    // Merge lo + hi
    addps  xmm0, xmm1
    // Horizontal add (SSE3 style, but we use SSE2 shuffles)
    movaps xmm1, xmm0
    shufps xmm1, xmm1, $4E      // swap high/low 64-bit
    addps  xmm0, xmm1
    movaps xmm1, xmm0
    shufps xmm1, xmm1, $B1      // swap adjacent pairs
    addps  xmm0, xmm1
    movss  res, xmm0
  end;
  Result := res;
{$ELSE}
begin
  Result := SSE2ReduceAddF32x4(a.lo) + SSE2ReduceAddF32x4(a.hi);
{$ENDIF}
end;

function SSE2ReduceMinF32x8(const a: TVecF32x8): Single;
{$IFDEF CPUX64}
var pa: Pointer; res: Single;
begin
  pa := @a;
  asm
    mov    rax, pa
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    // Merge lo + hi with min
    minps  xmm0, xmm1
    // Horizontal min
    movaps xmm1, xmm0
    shufps xmm1, xmm1, $4E
    minps  xmm0, xmm1
    movaps xmm1, xmm0
    shufps xmm1, xmm1, $B1
    minps  xmm0, xmm1
    movss  res, xmm0
  end;
  Result := res;
{$ELSE}
var
  lo, hi: Single;
begin
  lo := SSE2ReduceMinF32x4(a.lo);
  hi := SSE2ReduceMinF32x4(a.hi);
  if lo < hi then Result := lo else Result := hi;
{$ENDIF}
end;

function SSE2ReduceMaxF32x8(const a: TVecF32x8): Single;
{$IFDEF CPUX64}
var pa: Pointer; res: Single;
begin
  pa := @a;
  asm
    mov    rax, pa
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    // Merge lo + hi with max
    maxps  xmm0, xmm1
    // Horizontal max
    movaps xmm1, xmm0
    shufps xmm1, xmm1, $4E
    maxps  xmm0, xmm1
    movaps xmm1, xmm0
    shufps xmm1, xmm1, $B1
    maxps  xmm0, xmm1
    movss  res, xmm0
  end;
  Result := res;
{$ELSE}
var
  lo, hi: Single;
begin
  lo := SSE2ReduceMaxF32x4(a.lo);
  hi := SSE2ReduceMaxF32x4(a.hi);
  if lo > hi then Result := lo else Result := hi;
{$ENDIF}
end;

function SSE2ReduceMulF32x8(const a: TVecF32x8): Single;
{$IFDEF CPUX64}
var pa: Pointer; res: Single;
begin
  pa := @a;
  asm
    mov    rax, pa
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    // Merge lo * hi
    mulps  xmm0, xmm1
    // Horizontal mul
    movaps xmm1, xmm0
    shufps xmm1, xmm1, $4E
    mulps  xmm0, xmm1
    movaps xmm1, xmm0
    shufps xmm1, xmm1, $B1
    mulps  xmm0, xmm1
    movss  res, xmm0
  end;
  Result := res;
{$ELSE}
begin
  Result := SSE2ReduceMulF32x4(a.lo) * SSE2ReduceMulF32x4(a.hi);
{$ENDIF}
end;

function SSE2LoadF32x8(p: PSingle): TVecF32x8;
begin
  Result.lo := SSE2LoadF32x4(p);
  Result.hi := SSE2LoadF32x4(p + 4);
end;

procedure SSE2StoreF32x8(p: PSingle; const a: TVecF32x8);
begin
  SSE2StoreF32x4(p, a.lo);
  SSE2StoreF32x4(p + 4, a.hi);
end;

function SSE2SplatF32x8(value: Single): TVecF32x8;
begin
  Result.lo := SSE2SplatF32x4(value);
  Result.hi := SSE2SplatF32x4(value);
end;

function SSE2ZeroF32x8: TVecF32x8;
begin
  Result.lo := SSE2ZeroF32x4;
  Result.hi := SSE2ZeroF32x4;
end;

// === Additional Facade Functions with SSE2 ===

// MinMax with SSE2
procedure MinMaxBytes_SSE2(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte);
var
  pb: PByte;
  i: SizeUInt;
  minAcc, maxAcc: Integer;
begin
  if (len = 0) or (p = nil) then
  begin
    minVal := 0;
    maxVal := 0;
    Exit;
  end;

  pb := PByte(p);
  i := 0;
  minAcc := 255;
  maxAcc := 0;

  // Process 16 bytes at a time
  while i + 16 <= len do
  begin
    asm
      mov     rax, pb
      add     rax, i
      movdqu  xmm0, [rax]
      
      // Get min
      movdqa  xmm1, xmm0
      psrlw   xmm1, 8
      pminub  xmm0, xmm1
      movdqa  xmm1, xmm0
      psrld   xmm1, 16
      pminub  xmm0, xmm1
      movdqa  xmm1, xmm0
      psrlq   xmm1, 32
      pminub  xmm0, xmm1
      movdqa  xmm1, xmm0
      psrldq  xmm1, 8
      pminub  xmm0, xmm1
      movd    eax, xmm0
      and     eax, $FF
      cmp     eax, minAcc
      jge     @skipmin
      mov     minAcc, eax
    @skipmin:
      
      // Get max
      mov     rax, pb
      add     rax, i
      movdqu  xmm0, [rax]
      movdqa  xmm1, xmm0
      psrlw   xmm1, 8
      pmaxub  xmm0, xmm1
      movdqa  xmm1, xmm0
      psrld   xmm1, 16
      pmaxub  xmm0, xmm1
      movdqa  xmm1, xmm0
      psrlq   xmm1, 32
      pmaxub  xmm0, xmm1
      movdqa  xmm1, xmm0
      psrldq  xmm1, 8
      pmaxub  xmm0, xmm1
      movd    eax, xmm0
      and     eax, $FF
      cmp     eax, maxAcc
      jle     @skipmax
      mov     maxAcc, eax
    @skipmax:
    end;
    Inc(i, 16);
  end;

  // Handle remaining bytes
  while i < len do
  begin
    if pb[i] < minAcc then
      minAcc := pb[i];
    if pb[i] > maxAcc then
      maxAcc := pb[i];
    Inc(i);
  end;

  minVal := Byte(minAcc);
  maxVal := Byte(maxAcc);
end;

// Popcount with SSE2 (using lookup table)
function BitsetPopCount_SSE2(p: Pointer; len: SizeUInt): SizeUInt;
var
  pb: PByte;
  i: SizeUInt;
  count: SizeUInt;
  b: Byte;
const
  PopCountTable: array[0..15] of Byte = (
    0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4
  );
begin
  if (len = 0) or (p = nil) then
  begin
    Result := 0;
    Exit;
  end;

  pb := PByte(p);
  count := 0;
  i := 0;

  // Use SWAR technique for bulk processing
  while i + 8 <= len do
  begin
    asm
      mov     rax, pb
      add     rax, i
      mov     rdx, [rax]      // Load 8 bytes
      
      // SWAR popcount
      mov     rcx, rdx
      shr     rcx, 1
      mov     r8, $5555555555555555
      and     rcx, r8
      sub     rdx, rcx
      
      mov     rcx, rdx
      shr     rcx, 2
      mov     r8, $3333333333333333
      and     rdx, r8
      and     rcx, r8
      add     rdx, rcx
      
      mov     rcx, rdx
      shr     rcx, 4
      add     rdx, rcx
      mov     r8, $0F0F0F0F0F0F0F0F
      and     rdx, r8
      
      mov     r8, $0101010101010101
      imul    rdx, r8
      shr     rdx, 56
      
      add     count, rdx
    end;
    Inc(i, 8);
  end;

  // Handle remaining bytes
  while i < len do
  begin
    b := pb[i];
    Inc(count, PopCountTable[b and $0F] + PopCountTable[b shr 4]);
    Inc(i);
  end;

  Result := count;
end;

// === ✅ P2-1: Saturating Arithmetic (SSE2 硬件加速) ===
// SSE2 提供专门的饱和算术指令，比标量实现快 8-16x

// I8x16 有符号饱和加法 (PADDSB)
function SSE2I8x16SatAdd(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  // x86-64 SysV ABI: a -> RDI, b -> RSI, Result -> RAX
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  paddsb xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  // Windows x64: a -> RCX, b -> RDX, Result -> RAX
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  paddsb xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// I8x16 有符号饱和减法 (PSUBSB)
function SSE2I8x16SatSub(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  psubsb xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  psubsb xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// I16x8 有符号饱和加法 (PADDSW)
function SSE2I16x8SatAdd(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  paddsw xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  paddsw xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// I16x8 有符号饱和减法 (PSUBSW)
function SSE2I16x8SatSub(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  psubsw xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  psubsw xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// U8x16 无符号饱和加法 (PADDUSB)
function SSE2U8x16SatAdd(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  paddusb xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  paddusb xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// U8x16 无符号饱和减法 (PSUBUSB)
function SSE2U8x16SatSub(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  psubusb xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  psubusb xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// U16x8 无符号饱和加法 (PADDUSW)
function SSE2U16x8SatAdd(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  paddusw xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  paddusw xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// U16x8 无符号饱和减法 (PSUBUSW)
function SSE2U16x8SatSub(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  psubusw xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  psubusw xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// === ✅ P3: I64x2 Arithmetic and Bitwise Operations (SSE2) ===
// SSE2 提供 paddq/psubq 用于 64-bit 整数运算

// I64x2 加法 (PADDQ)
function SSE2AddI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  paddq  xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  paddq  xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// I64x2 减法 (PSUBQ)
function SSE2SubI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  psubq  xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  psubq  xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// I64x2 位与 (PAND)
function SSE2AndI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  pand   xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  pand   xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// I64x2 位或 (POR)
function SSE2OrI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  por    xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  por    xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// I64x2 位异或 (PXOR)
function SSE2XorI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  pxor   xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  pxor   xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// I64x2 位非 (PXOR with all 1s)
function SSE2NotI64x2(const a: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu  xmm0, [rdi]
  pcmpeqd xmm1, xmm1      // all 1s
  pxor    xmm0, xmm1      // NOT = XOR with all 1s
  movdqu  [rax], xmm0
  {$ELSE}
  movdqu  xmm0, [rcx]
  pcmpeqd xmm1, xmm1
  pxor    xmm0, xmm1
  movdqu  [rax], xmm0
  {$ENDIF}
end;

// === ✅ I64x2 Comparison Operations (SSE2 emulation) ===
// SSE2 没有原生 64 位整数比较指令（PCMPEQQ 是 SSE4.1）
// 使用两个 32 位比较 + AND/OR 逻辑实现

// CmpEqI64x2: 使用两个 32 位比较 + AND
// 比较高 32 位和低 32 位是否都相等
// pcmpeqd xmm0, xmm1  // 32位比较
// pshufd xmm2, xmm0, 0xB1  // 交换每个 64 位元素内的高低 32 位
// pand xmm0, xmm2  // 两部分都相等才算相等
function SSE2CmpEqI64x2(const a, b: TVecI64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pcmpeqd xmm0, xmm1       // 32 位元素比较: [a0L==b0L, a0H==b0H, a1L==b1L, a1H==b1H]
    pshufd  xmm2, xmm0, $B1  // 交换高低 32 位: [a0H==b0H, a0L==b0L, a1H==b1H, a1L==b1L]
    pand    xmm0, xmm2       // 每个 64 位元素：高低都相等才为真
    movmskpd eax, xmm0       // 提取每个 64 位元素的符号位（位 63）
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

// CmpNeI64x2: NOT(CmpEq)
function SSE2CmpNeI64x2(const a, b: TVecI64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pcmpeqd xmm0, xmm1       // 32 位比较
    pshufd  xmm2, xmm0, $B1  // 交换高低 32 位
    pand    xmm0, xmm2       // AND
    pcmpeqd xmm3, xmm3       // 全 1
    pxor    xmm0, xmm3       // NOT
    movmskpd eax, xmm0
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

// CmpGtI64x2: 64 位有符号大于比较（SSE2 模拟）
// 算法: (a_high > b_high) || (a_high == b_high && a_low > b_low)
// 注意: 高 32 位使用有符号比较，低 32 位使用无符号比较
function SSE2CmpGtI64x2(const a, b: TVecI64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rax]         // xmm0 = a = [a0L, a0H, a1L, a1H]
    movdqu xmm1, [rdx]         // xmm1 = b = [b0L, b0H, b1L, b1H]

    // Step 1: 计算 a_high > b_high (有符号 32 位比较)
    movdqa xmm2, xmm0
    pcmpgtd xmm2, xmm1         // xmm2 = [a0L>b0L?, a0H>b0H?, a1L>b1L?, a1H>b1H?]
    pshufd xmm3, xmm2, $F5     // xmm3 = [a0H>b0H?, a0H>b0H?, a1H>b1H?, a1H>b1H?] ($F5 = 11_11_01_01)

    // Step 2: 计算 a_high == b_high
    movdqa xmm4, xmm0
    pcmpeqd xmm4, xmm1         // xmm4 = [a0L==b0L?, a0H==b0H?, a1L==b1L?, a1H==b1H?]
    pshufd xmm5, xmm4, $F5     // xmm5 = [a0H==b0H?, a0H==b0H?, a1H==b1H?, a1H==b1H?]

    // Step 3: 计算 a_low > b_low (无符号比较)
    // 无符号比较技巧: 翻转符号位后用有符号比较
    // a_low >u b_low  <=>  (a_low ^ 0x80000000) >s (b_low ^ 0x80000000)
    movdqa xmm6, xmm0
    movdqa xmm7, xmm1
    // 准备 0x80000000 常量
    pcmpeqd xmm4, xmm4         // 全 1
    psrld   xmm4, 31           // 每个 dword = 1
    pslld   xmm4, 31           // 每个 dword = 0x80000000
    pxor    xmm6, xmm4         // 翻转 a 的符号位
    pxor    xmm7, xmm4         // 翻转 b 的符号位
    pcmpgtd xmm6, xmm7         // 无符号比较结果
    pshufd  xmm6, xmm6, $A0    // 只保留低 32 位结果 [a0L>b0L?, 0, a1L>b1L?, 0] ($A0 = 10_10_00_00)

    // Step 4: 组合结果
    // result = (a_high > b_high) || ((a_high == b_high) && (a_low > b_low))
    pand   xmm5, xmm6          // (a_high == b_high) && (a_low > b_low)
    por    xmm3, xmm5          // 最终结果

    // Step 5: 提取每个 64 位元素的最高位
    movmskpd eax, xmm3
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

// CmpLtI64x2: a < b = b > a
function SSE2CmpLtI64x2(const a, b: TVecI64x2): TMask2;
begin
  Result := SSE2CmpGtI64x2(b, a);
end;

// CmpGeI64x2: a >= b = NOT(a < b) = NOT(b > a)
function SSE2CmpGeI64x2(const a, b: TVecI64x2): TMask2;
begin
  Result := TMask2((not Byte(SSE2CmpGtI64x2(b, a))) and 3);
end;

// CmpLeI64x2: a <= b = NOT(a > b)
function SSE2CmpLeI64x2(const a, b: TVecI64x2): TMask2;
begin
  Result := TMask2((not Byte(SSE2CmpGtI64x2(a, b))) and 3);
end;

// === ✅ P1: Mask Operations SIMD Implementation ===
// 使用 bsf (bit scan forward) 和 SWAR popcount 加速
// Mask 类型是小整数（TMask2/4/8/16），可以用标量指令优化

// --- TMask2 Operations (2 bits) ---
function SSE2Mask2All(mask: TMask2): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  and   edi, 3        // 只保留低 2 位
  cmp   edi, 3        // 检查是否都为 1
  sete  al            // 设置结果
  {$ELSE}
  and   ecx, 3
  cmp   ecx, 3
  sete  al
  {$ENDIF}
end;

function SSE2Mask2Any(mask: TMask2): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  edi, 3        // 测试低 2 位
  setne al            // 任何位设置则为 true
  {$ELSE}
  test  ecx, 3
  setne al
  {$ENDIF}
end;

function SSE2Mask2None(mask: TMask2): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  edi, 3
  sete  al            // 没有位设置则为 true
  {$ELSE}
  test  ecx, 3
  sete  al
  {$ENDIF}
end;

function SSE2Mask2PopCount(mask: TMask2): Integer; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  and   edi, 3        // 只保留低 2 位
  mov   eax, edi
  shr   eax, 1        // 第二位移到位 0
  and   eax, 1        // 取第二位
  and   edi, 1        // 取第一位
  add   eax, edi      // 相加
  {$ELSE}
  and   ecx, 3
  mov   eax, ecx
  shr   eax, 1
  and   eax, 1
  and   ecx, 1
  add   eax, ecx
  {$ENDIF}
end;

function SSE2Mask2FirstSet(mask: TMask2): Integer; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  and   edi, 3        // 只保留低 2 位
  bsf   eax, edi      // 找第一个设置的位
  jnz   @done
  mov   eax, -1       // 没有设置的位
@done:
  {$ELSE}
  and   ecx, 3
  bsf   eax, ecx
  jnz   @done
  mov   eax, -1
@done:
  {$ENDIF}
end;

// --- TMask4 Operations (4 bits) ---
function SSE2Mask4All(mask: TMask4): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  and   edi, 15       // 只保留低 4 位
  cmp   edi, 15
  sete  al
  {$ELSE}
  and   ecx, 15
  cmp   ecx, 15
  sete  al
  {$ENDIF}
end;

function SSE2Mask4Any(mask: TMask4): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  edi, 15
  setne al
  {$ELSE}
  test  ecx, 15
  setne al
  {$ENDIF}
end;

function SSE2Mask4None(mask: TMask4): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  edi, 15
  sete  al
  {$ELSE}
  test  ecx, 15
  sete  al
  {$ENDIF}
end;

function SSE2Mask4PopCount(mask: TMask4): Integer; assembler; nostackframe;
// SWAR popcount for 4 bits
asm
  {$IFDEF UNIX}
  and   edi, 15
  mov   eax, edi
  shr   eax, 1
  and   eax, $5       // 0101 pattern
  sub   edi, eax
  mov   eax, edi
  shr   eax, 2
  and   edi, $3       // 0011 pattern
  and   eax, $3
  add   eax, edi
  {$ELSE}
  and   ecx, 15
  mov   eax, ecx
  shr   eax, 1
  and   eax, $5
  sub   ecx, eax
  mov   eax, ecx
  shr   eax, 2
  and   ecx, $3
  and   eax, $3
  add   eax, ecx
  {$ENDIF}
end;

function SSE2Mask4FirstSet(mask: TMask4): Integer; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  and   edi, 15
  bsf   eax, edi
  jnz   @done
  mov   eax, -1
@done:
  {$ELSE}
  and   ecx, 15
  bsf   eax, ecx
  jnz   @done
  mov   eax, -1
@done:
  {$ENDIF}
end;

// --- TMask8 Operations (8 bits) ---
function SSE2Mask8All(mask: TMask8): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  cmp   dil, $FF
  sete  al
  {$ELSE}
  cmp   cl, $FF
  sete  al
  {$ENDIF}
end;

function SSE2Mask8Any(mask: TMask8): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  dil, dil
  setne al
  {$ELSE}
  test  cl, cl
  setne al
  {$ENDIF}
end;

function SSE2Mask8None(mask: TMask8): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  dil, dil
  sete  al
  {$ELSE}
  test  cl, cl
  sete  al
  {$ENDIF}
end;

function SSE2Mask8PopCount(mask: TMask8): Integer; assembler; nostackframe;
// SWAR popcount for 8 bits
asm
  {$IFDEF UNIX}
  movzx eax, dil
  mov   edx, eax
  shr   edx, 1
  and   edx, $55
  sub   eax, edx
  mov   edx, eax
  shr   edx, 2
  and   eax, $33
  and   edx, $33
  add   eax, edx
  mov   edx, eax
  shr   edx, 4
  add   eax, edx
  and   eax, $0F
  {$ELSE}
  movzx eax, cl
  mov   edx, eax
  shr   edx, 1
  and   edx, $55
  sub   eax, edx
  mov   edx, eax
  shr   edx, 2
  and   eax, $33
  and   edx, $33
  add   eax, edx
  mov   edx, eax
  shr   edx, 4
  add   eax, edx
  and   eax, $0F
  {$ENDIF}
end;

function SSE2Mask8FirstSet(mask: TMask8): Integer; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movzx edi, dil
  bsf   eax, edi
  jnz   @done
  mov   eax, -1
@done:
  {$ELSE}
  movzx ecx, cl
  bsf   eax, ecx
  jnz   @done
  mov   eax, -1
@done:
  {$ENDIF}
end;

// --- TMask16 Operations (16 bits) ---
function SSE2Mask16All(mask: TMask16): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  cmp   di, $FFFF
  sete  al
  {$ELSE}
  cmp   cx, $FFFF
  sete  al
  {$ENDIF}
end;

function SSE2Mask16Any(mask: TMask16): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  di, di
  setne al
  {$ELSE}
  test  cx, cx
  setne al
  {$ENDIF}
end;

function SSE2Mask16None(mask: TMask16): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  di, di
  sete  al
  {$ELSE}
  test  cx, cx
  sete  al
  {$ENDIF}
end;

function SSE2Mask16PopCount(mask: TMask16): Integer; assembler; nostackframe;
// SWAR popcount for 16 bits
asm
  {$IFDEF UNIX}
  movzx eax, di
  mov   edx, eax
  shr   edx, 1
  and   edx, $5555
  sub   eax, edx
  mov   edx, eax
  shr   edx, 2
  and   eax, $3333
  and   edx, $3333
  add   eax, edx
  mov   edx, eax
  shr   edx, 4
  add   eax, edx
  and   eax, $0F0F
  mov   edx, eax
  shr   edx, 8
  add   eax, edx
  and   eax, $FF
  {$ELSE}
  movzx eax, cx
  mov   edx, eax
  shr   edx, 1
  and   edx, $5555
  sub   eax, edx
  mov   edx, eax
  shr   edx, 2
  and   eax, $3333
  and   edx, $3333
  add   eax, edx
  mov   edx, eax
  shr   edx, 4
  add   eax, edx
  and   eax, $0F0F
  mov   edx, eax
  shr   edx, 8
  add   eax, edx
  and   eax, $FF
  {$ENDIF}
end;

function SSE2Mask16FirstSet(mask: TMask16): Integer; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movzx edi, di
  bsf   eax, edi
  jnz   @done
  mov   eax, -1
@done:
  {$ELSE}
  movzx ecx, cx
  bsf   eax, ecx
  jnz   @done
  mov   eax, -1
@done:
  {$ENDIF}
end;

// === ✅ P4: SelectF64x2 SIMD Implementation ===
// 使用 andpd/andnpd/orpd 实现手动混合 (blendvpd 需要 SSE4.1)
// mask 位 0 控制元素 0，位 1 控制元素 1
// 位为 1 时选择 a，位为 0 时选择 b
function SSE2SelectF64x2(const mask: TMask2; const a, b: TVecF64x2): TVecF64x2;
var
  pa, pb, pm, pr: Pointer;
  expandedMask: TVecI64x2;
begin
  // 将 mask 扩展为 64-bit 掉码
  if (mask and 1) <> 0 then expandedMask.i[0] := Int64(-1) else expandedMask.i[0] := 0;
  if (mask and 2) <> 0 then expandedMask.i[1] := Int64(-1) else expandedMask.i[1] := 0;

  pa := @a;
  pb := @b;
  pm := @expandedMask;
  pr := @Result;

  // result = (a AND mask) OR (b AND NOT mask)
  asm
    mov   rax, pa
    mov   rdx, pb
    mov   rcx, pm
    mov   r8, pr

    movupd xmm0, [rax]     // a
    movupd xmm1, [rdx]     // b
    movdqu xmm2, [rcx]     // mask (expanded to 128-bit)

    andpd  xmm0, xmm2      // a AND mask
    andnpd xmm2, xmm1      // b AND (NOT mask)  (andnpd: ~src1 AND src2)
    orpd   xmm0, xmm2      // combine

    movupd [r8], xmm0
  end;
end;

// ✅ F64x2 扩展函数 (2026-02-05) - 用于构建 F64x4 分解实现

function SSE2FloorF64x2(const a: TVecF64x2): TVecF64x2;
begin
  // SSE2 没有 ROUNDPD，使用标量 Floor
  Result.d[0] := Floor(a.d[0]);
  Result.d[1] := Floor(a.d[1]);
end;

function SSE2CeilF64x2(const a: TVecF64x2): TVecF64x2;
begin
  Result.d[0] := Ceil(a.d[0]);
  Result.d[1] := Ceil(a.d[1]);
end;

function SSE2RoundF64x2(const a: TVecF64x2): TVecF64x2;
begin
  Result.d[0] := Round(a.d[0]);
  Result.d[1] := Round(a.d[1]);
end;

function SSE2TruncF64x2(const a: TVecF64x2): TVecF64x2;
begin
  Result.d[0] := Trunc(a.d[0]);
  Result.d[1] := Trunc(a.d[1]);
end;

function SSE2FmaF64x2(const a, b, c: TVecF64x2): TVecF64x2;
begin
  // FMA: a * b + c，SSE2 没有 FMA 指令，用乘加分离
  Result.d[0] := a.d[0] * b.d[0] + c.d[0];
  Result.d[1] := a.d[1] * b.d[1] + c.d[1];
end;

function SSE2ClampF64x2(const a, minVal, maxVal: TVecF64x2): TVecF64x2;
begin
  Result := SSE2MaxF64x2(SSE2MinF64x2(a, maxVal), minVal);
end;

function SSE2ReduceAddF64x2(const a: TVecF64x2): Double;
begin
  Result := a.d[0] + a.d[1];
end;

function SSE2ReduceMinF64x2(const a: TVecF64x2): Double;
begin
  if a.d[0] < a.d[1] then Result := a.d[0] else Result := a.d[1];
end;

function SSE2ReduceMaxF64x2(const a: TVecF64x2): Double;
begin
  if a.d[0] > a.d[1] then Result := a.d[0] else Result := a.d[1];
end;

function SSE2ReduceMulF64x2(const a: TVecF64x2): Double;
begin
  Result := a.d[0] * a.d[1];
end;

// ✅ F64x4 分解实现 (2026-02-05) - 使用 2x F64x2

// ✅ SIMD Quality Iteration 4.4: F64x4 2×128-bit SSE2 ASM 实现
function SSE2AddF64x4(const a, b: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rdx]
    movupd xmm3, [rdx+16]
    addpd  xmm0, xmm2
    addpd  xmm1, xmm3
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2AddF64x2(a.lo, b.lo);
  Result.hi := SSE2AddF64x2(a.hi, b.hi);
{$ENDIF}
end;

function SSE2SubF64x4(const a, b: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rdx]
    movupd xmm3, [rdx+16]
    subpd  xmm0, xmm2
    subpd  xmm1, xmm3
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2SubF64x2(a.lo, b.lo);
  Result.hi := SSE2SubF64x2(a.hi, b.hi);
{$ENDIF}
end;

function SSE2MulF64x4(const a, b: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rdx]
    movupd xmm3, [rdx+16]
    mulpd  xmm0, xmm2
    mulpd  xmm1, xmm3
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2MulF64x2(a.lo, b.lo);
  Result.hi := SSE2MulF64x2(a.hi, b.hi);
{$ENDIF}
end;

function SSE2DivF64x4(const a, b: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rdx]
    movupd xmm3, [rdx+16]
    divpd  xmm0, xmm2
    divpd  xmm1, xmm3
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2DivF64x2(a.lo, b.lo);
  Result.hi := SSE2DivF64x2(a.hi, b.hi);
{$ENDIF}
end;

function SSE2FmaF64x4(const a, b, c: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var pa, pb, pc, pr: Pointer;
begin
  pa := @a; pb := @b; pc := @c; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    r8,  pc
    mov    rcx, pr
    // Load a
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    // Load b
    movupd xmm2, [rdx]
    movupd xmm3, [rdx+16]
    // Multiply a * b
    mulpd  xmm0, xmm2
    mulpd  xmm1, xmm3
    // Load c
    movupd xmm4, [r8]
    movupd xmm5, [r8+16]
    // Add c
    addpd  xmm0, xmm4
    addpd  xmm1, xmm5
    // Store
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2FmaF64x2(a.lo, b.lo, c.lo);
  Result.hi := SSE2FmaF64x2(a.hi, b.hi, c.hi);
{$ENDIF}
end;

// Reciprocal: 1.0 / a
function SSE2RcpF64x4(const a: TVecF64x4): TVecF64x4;
var
  one: TVecF64x2;
begin
  one := SSE2SplatF64x2(1.0);
  Result.lo := SSE2DivF64x2(one, a.lo);
  Result.hi := SSE2DivF64x2(one, a.hi);
end;

// ✅ SIMD Quality Iteration 6.3: F64x4 舍入操作 SSE2 ASM 实现
function SSE2FloorF64x4(const a: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var
  pa, pr: Pointer;
const
  OneDouble: array[0..1] of Double = (1.0, 1.0);
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr

    // 加载低 2 个 double
    movupd xmm0, [rax]
    // 加载高 2 个 double
    movupd xmm4, [rax+16]

    // === 处理低 2 个元素 (xmm0) ===
    // 保存原值
    movapd xmm1, xmm0
    // 截断转整数 (SSE2 cvttpd2dq 转换 2 个 double 到 2 个 int32)
    cvttpd2dq xmm0, xmm0
    // 转回浮点 (cvtdq2pd 将 2 个 int32 转为 2 个 double)
    cvtdq2pd xmm0, xmm0
    // 比较: 原值 < 截断值？
    movapd xmm2, xmm1
    cmpltpd xmm2, xmm0
    // 加载 1.0
    movupd xmm3, [rip + OneDouble]
    // 掩码 & 1.0
    andpd  xmm2, xmm3
    // 减去修正值
    subpd  xmm0, xmm2

    // === 处理高 2 个元素 (xmm4) ===
    // 保存原值
    movapd xmm5, xmm4
    // 截断转整数
    cvttpd2dq xmm4, xmm4
    // 转回浮点
    cvtdq2pd xmm4, xmm4
    // 比较: 原值 < 截断值？
    movapd xmm6, xmm5
    cmpltpd xmm6, xmm4
    // 掩码 & 1.0
    andpd  xmm6, xmm3
    // 减去修正值
    subpd  xmm4, xmm6

    // 保存结果
    movupd [rcx], xmm0
    movupd [rcx+16], xmm4
  end;
{$ELSE}
begin
  Result.lo := SSE2FloorF64x2(a.lo);
  Result.hi := SSE2FloorF64x2(a.hi);
{$ENDIF}
end;

function SSE2CeilF64x4(const a: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var
  pa, pr: Pointer;
const
  OneDouble: array[0..1] of Double = (1.0, 1.0);
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr

    // 加载低 2 个 double
    movupd xmm0, [rax]
    // 加载高 2 个 double
    movupd xmm4, [rax+16]

    // === 处理低 2 个元素 (xmm0) ===
    // 保存原值
    movapd xmm1, xmm0
    // 截断转整数
    cvttpd2dq xmm0, xmm0
    // 转回浮点
    cvtdq2pd xmm0, xmm0
    // 比较: 截断值 < 原值？
    cmpltpd xmm0, xmm1
    // 加载 1.0
    movupd xmm3, [rip + OneDouble]
    // 掩码 & 1.0
    andpd  xmm0, xmm3
    // 重新加载截断值
    movapd xmm2, xmm1
    cvttpd2dq xmm2, xmm2
    cvtdq2pd xmm2, xmm2
    // 加上修正值
    addpd  xmm0, xmm2

    // === 处理高 2 个元素 (xmm4) ===
    // 保存原值
    movapd xmm5, xmm4
    // 截断转整数
    cvttpd2dq xmm4, xmm4
    // 转回浮点
    cvtdq2pd xmm4, xmm4
    // 比较: 截断值 < 原值？
    cmpltpd xmm4, xmm5
    // 掩码 & 1.0
    andpd  xmm4, xmm3
    // 重新加载截断值
    movapd xmm6, xmm5
    cvttpd2dq xmm6, xmm6
    cvtdq2pd xmm6, xmm6
    // 加上修正值
    addpd  xmm4, xmm6

    // 保存结果
    movupd [rcx], xmm0
    movupd [rcx+16], xmm4
  end;
{$ELSE}
begin
  Result.lo := SSE2CeilF64x2(a.lo);
  Result.hi := SSE2CeilF64x2(a.hi);
{$ENDIF}
end;

function SSE2RoundF64x4(const a: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var
  pa, pr: Pointer;
const
  HalfDouble: array[0..1] of Double = (0.5, 0.5);
  SignMaskPD: array[0..3] of UInt32 = ($00000000, $80000000, $00000000, $80000000);
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr

    // 加载低 2 个 double
    movupd xmm0, [rax]
    // 加载高 2 个 double
    movupd xmm4, [rax+16]

    // === 处理低 2 个元素 (xmm0) ===
    // 保存原值
    movapd xmm1, xmm0
    // 提取符号
    movupd xmm2, [rip + SignMaskPD]
    movapd xmm3, xmm1
    andpd  xmm3, xmm2  // xmm3 = sign
    // 取绝对值
    andnpd xmm2, xmm1  // xmm2 = abs(x)
    // 加 0.5
    movupd xmm1, [rip + HalfDouble]
    addpd  xmm2, xmm1
    // 截断
    cvttpd2dq xmm2, xmm2
    cvtdq2pd xmm2, xmm2
    // 恢复符号
    orpd   xmm2, xmm3
    movapd xmm0, xmm2

    // === 处理高 2 个元素 (xmm4) ===
    // 保存原值
    movapd xmm5, xmm4
    // 提取符号
    movupd xmm6, [rip + SignMaskPD]
    movapd xmm7, xmm5
    andpd  xmm7, xmm6  // xmm7 = sign
    // 取绝对值
    andnpd xmm6, xmm5  // xmm6 = abs(x)
    // 加 0.5
    addpd  xmm6, xmm1  // 复用 HalfDouble
    // 截断
    cvttpd2dq xmm6, xmm6
    cvtdq2pd xmm6, xmm6
    // 恢复符号
    orpd   xmm6, xmm7
    movapd xmm4, xmm6

    // 保存结果
    movupd [rcx], xmm0
    movupd [rcx+16], xmm4
  end;
{$ELSE}
begin
  Result.lo := SSE2RoundF64x2(a.lo);
  Result.hi := SSE2RoundF64x2(a.hi);
{$ENDIF}
end;

function SSE2TruncF64x4(const a: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var
  pa, pr: Pointer;
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr

    // 加载低 2 个 double
    movupd xmm0, [rax]
    // 加载高 2 个 double
    movupd xmm1, [rax+16]

    // 截断低 2 个元素
    cvttpd2dq xmm0, xmm0
    cvtdq2pd xmm0, xmm0

    // 截断高 2 个元素
    cvttpd2dq xmm1, xmm1
    cvtdq2pd xmm1, xmm1

    // 保存结果
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2TruncF64x2(a.lo);
  Result.hi := SSE2TruncF64x2(a.hi);
{$ENDIF}
end;

function SSE2AbsF64x4(const a: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var pa, pr: Pointer;
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    // Create sign mask for double (0x7FFFFFFFFFFFFFFF)
    pcmpeqd xmm2, xmm2       // all 1s
    psrlq   xmm2, 1          // clear sign bit (64-bit)
    movapd  xmm3, xmm2
    // Clear sign bits
    andpd   xmm0, xmm2
    andpd   xmm1, xmm3
    movupd  [rcx], xmm0
    movupd  [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2AbsF64x2(a.lo);
  Result.hi := SSE2AbsF64x2(a.hi);
{$ENDIF}
end;

function SSE2SqrtF64x4(const a: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var pa, pr: Pointer;
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    sqrtpd xmm0, xmm0
    sqrtpd xmm1, xmm1
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2SqrtF64x2(a.lo);
  Result.hi := SSE2SqrtF64x2(a.hi);
{$ENDIF}
end;

function SSE2MinF64x4(const a, b: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rdx]
    movupd xmm3, [rdx+16]
    minpd  xmm0, xmm2
    minpd  xmm1, xmm3
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2MinF64x2(a.lo, b.lo);
  Result.hi := SSE2MinF64x2(a.hi, b.hi);
{$ENDIF}
end;

function SSE2MaxF64x4(const a, b: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rdx]
    movupd xmm3, [rdx+16]
    maxpd  xmm0, xmm2
    maxpd  xmm1, xmm3
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2MaxF64x2(a.lo, b.lo);
  Result.hi := SSE2MaxF64x2(a.hi, b.hi);
{$ENDIF}
end;

function SSE2ClampF64x4(const a, minVal, maxVal: TVecF64x4): TVecF64x4;
{$IFDEF CPUX64}
var pa, pmin, pmax, pr: Pointer;
begin
  pa := @a; pmin := @minVal; pmax := @maxVal; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pmin
    mov    r8,  pmax
    mov    rcx, pr
    // Load a
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    // Load minVal
    movupd xmm2, [rdx]
    movupd xmm3, [rdx+16]
    // Max with minVal
    maxpd  xmm0, xmm2
    maxpd  xmm1, xmm3
    // Load maxVal
    movupd xmm4, [r8]
    movupd xmm5, [r8+16]
    // Min with maxVal
    minpd  xmm0, xmm4
    minpd  xmm1, xmm5
    // Store
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2ClampF64x2(a.lo, minVal.lo, maxVal.lo);
  Result.hi := SSE2ClampF64x2(a.hi, minVal.hi, maxVal.hi);
{$ENDIF}
end;

function SSE2ReduceAddF64x4(const a: TVecF64x4): Double;
{$IFDEF CPUX64}
var pa: Pointer; res: Double;
begin
  pa := @a;
  asm
    mov    rax, pa
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    // Merge lo + hi
    addpd  xmm0, xmm1
    // Horizontal add for 2 doubles
    movapd xmm1, xmm0
    shufpd xmm1, xmm1, 1      // swap high/low double
    addpd  xmm0, xmm1
    movlpd res, xmm0
  end;
  Result := res;
{$ELSE}
begin
  Result := SSE2ReduceAddF64x2(a.lo) + SSE2ReduceAddF64x2(a.hi);
{$ENDIF}
end;

function SSE2ReduceMinF64x4(const a: TVecF64x4): Double;
{$IFDEF CPUX64}
var pa: Pointer; res: Double;
begin
  pa := @a;
  asm
    mov    rax, pa
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    // Merge with min
    minpd  xmm0, xmm1
    // Horizontal min
    movapd xmm1, xmm0
    shufpd xmm1, xmm1, 1
    minpd  xmm0, xmm1
    movlpd res, xmm0
  end;
  Result := res;
{$ELSE}
var
  lo, hi: Double;
begin
  lo := SSE2ReduceMinF64x2(a.lo);
  hi := SSE2ReduceMinF64x2(a.hi);
  if lo < hi then Result := lo else Result := hi;
{$ENDIF}
end;

function SSE2ReduceMaxF64x4(const a: TVecF64x4): Double;
{$IFDEF CPUX64}
var pa: Pointer; res: Double;
begin
  pa := @a;
  asm
    mov    rax, pa
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    // Merge with max
    maxpd  xmm0, xmm1
    // Horizontal max
    movapd xmm1, xmm0
    shufpd xmm1, xmm1, 1
    maxpd  xmm0, xmm1
    movlpd res, xmm0
  end;
  Result := res;
{$ELSE}
var
  lo, hi: Double;
begin
  lo := SSE2ReduceMaxF64x2(a.lo);
  hi := SSE2ReduceMaxF64x2(a.hi);
  if lo > hi then Result := lo else Result := hi;
{$ENDIF}
end;

function SSE2ReduceMulF64x4(const a: TVecF64x4): Double;
{$IFDEF CPUX64}
var pa: Pointer; res: Double;
begin
  pa := @a;
  asm
    mov    rax, pa
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    // Merge with mul
    mulpd  xmm0, xmm1
    // Horizontal mul
    movapd xmm1, xmm0
    shufpd xmm1, xmm1, 1
    mulpd  xmm0, xmm1
    movlpd res, xmm0
  end;
  Result := res;
{$ELSE}
begin
  Result := SSE2ReduceMulF64x2(a.lo) * SSE2ReduceMulF64x2(a.hi);
{$ENDIF}
end;

function SSE2LoadF64x4(p: PDouble): TVecF64x4;
begin
  Result.lo := SSE2LoadF64x2(p);
  Result.hi := SSE2LoadF64x2(p + 2);
end;

procedure SSE2StoreF64x4(p: PDouble; const a: TVecF64x4);
begin
  SSE2StoreF64x2(p, a.lo);
  SSE2StoreF64x2(p + 2, a.hi);
end;

function SSE2SplatF64x4(value: Double): TVecF64x4;
begin
  Result.lo := SSE2SplatF64x2(value);
  Result.hi := SSE2SplatF64x2(value);
end;

function SSE2ZeroF64x4: TVecF64x4;
begin
  Result.lo := SSE2ZeroF64x2;
  Result.hi := SSE2ZeroF64x2;
end;

// ✅ F64x4 Comparison Operations (2×128-bit SSE2 ASM) - 2026-02-05

function SSE2CmpEqF64x4(const a, b: TVecF64x4): TMask4;
{$IFDEF CPUX64}
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    // 加载并比较 lo (2×double)
    movupd   xmm0, [rax]
    movupd   xmm1, [rdx]
    cmpeqpd  xmm0, xmm1      // 比较 a.lo == b.lo
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      lo_mask, eax
    // 加载并比较 hi (2×double)
    movupd   xmm0, [rax+16]
    movupd   xmm1, [rdx+16]
    cmpeqpd  xmm0, xmm1      // 比较 a.hi == b.hi
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      hi_mask, eax
  end;
  Result := TMask4(lo_mask or (hi_mask shl 2));
{$ELSE}
begin
  Result := TMask4(Byte(SSE2CmpEqF64x2(a.lo, b.lo)) or (Byte(SSE2CmpEqF64x2(a.hi, b.hi)) shl 2));
{$ENDIF}
end;

function SSE2CmpLtF64x4(const a, b: TVecF64x4): TMask4;
{$IFDEF CPUX64}
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    // 加载并比较 lo (2×double)
    movupd   xmm0, [rax]
    movupd   xmm1, [rdx]
    cmpltpd  xmm0, xmm1      // 比较 a.lo < b.lo
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      lo_mask, eax
    // 加载并比较 hi (2×double)
    movupd   xmm0, [rax+16]
    movupd   xmm1, [rdx+16]
    cmpltpd  xmm0, xmm1      // 比较 a.hi < b.hi
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      hi_mask, eax
  end;
  Result := TMask4(lo_mask or (hi_mask shl 2));
{$ELSE}
begin
  Result := TMask4(Byte(SSE2CmpLtF64x2(a.lo, b.lo)) or (Byte(SSE2CmpLtF64x2(a.hi, b.hi)) shl 2));
{$ENDIF}
end;

function SSE2CmpLeF64x4(const a, b: TVecF64x4): TMask4;
{$IFDEF CPUX64}
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    // 加载并比较 lo (2×double)
    movupd   xmm0, [rax]
    movupd   xmm1, [rdx]
    cmplepd  xmm0, xmm1      // 比较 a.lo <= b.lo
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      lo_mask, eax
    // 加载并比较 hi (2×double)
    movupd   xmm0, [rax+16]
    movupd   xmm1, [rdx+16]
    cmplepd  xmm0, xmm1      // 比较 a.hi <= b.hi
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      hi_mask, eax
  end;
  Result := TMask4(lo_mask or (hi_mask shl 2));
{$ELSE}
begin
  Result := TMask4(Byte(SSE2CmpLeF64x2(a.lo, b.lo)) or (Byte(SSE2CmpLeF64x2(a.hi, b.hi)) shl 2));
{$ENDIF}
end;

function SSE2CmpGtF64x4(const a, b: TVecF64x4): TMask4;
{$IFDEF CPUX64}
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  // GT: a > b is same as b < a
  asm
    mov      rax, pa
    mov      rdx, pb
    // 加载并比较 lo (2×double)
    movupd   xmm0, [rdx]     // load b.lo
    movupd   xmm1, [rax]     // load a.lo
    cmpltpd  xmm0, xmm1      // 比较 b.lo < a.lo
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      lo_mask, eax
    // 加载并比较 hi (2×double)
    movupd   xmm0, [rdx+16]  // load b.hi
    movupd   xmm1, [rax+16]  // load a.hi
    cmpltpd  xmm0, xmm1      // 比较 b.hi < a.hi
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      hi_mask, eax
  end;
  Result := TMask4(lo_mask or (hi_mask shl 2));
{$ELSE}
begin
  Result := TMask4(Byte(SSE2CmpGtF64x2(a.lo, b.lo)) or (Byte(SSE2CmpGtF64x2(a.hi, b.hi)) shl 2));
{$ENDIF}
end;

function SSE2CmpGeF64x4(const a, b: TVecF64x4): TMask4;
{$IFDEF CPUX64}
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  // GE: a >= b is same as b <= a
  asm
    mov      rax, pa
    mov      rdx, pb
    // 加载并比较 lo (2×double)
    movupd   xmm0, [rdx]     // load b.lo
    movupd   xmm1, [rax]     // load a.lo
    cmplepd  xmm0, xmm1      // 比较 b.lo <= a.lo
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      lo_mask, eax
    // 加载并比较 hi (2×double)
    movupd   xmm0, [rdx+16]  // load b.hi
    movupd   xmm1, [rax+16]  // load a.hi
    cmplepd  xmm0, xmm1      // 比较 b.hi <= a.hi
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      hi_mask, eax
  end;
  Result := TMask4(lo_mask or (hi_mask shl 2));
{$ELSE}
begin
  Result := TMask4(Byte(SSE2CmpGeF64x2(a.lo, b.lo)) or (Byte(SSE2CmpGeF64x2(a.hi, b.hi)) shl 2));
{$ENDIF}
end;

function SSE2CmpNeF64x4(const a, b: TVecF64x4): TMask4;
{$IFDEF CPUX64}
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    // 加载并比较 lo (2×double)
    movupd   xmm0, [rax]
    movupd   xmm1, [rdx]
    cmpneqpd xmm0, xmm1      // 比较 a.lo != b.lo
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      lo_mask, eax
    // 加载并比较 hi (2×double)
    movupd   xmm0, [rax+16]
    movupd   xmm1, [rdx+16]
    cmpneqpd xmm0, xmm1      // 比较 a.hi != b.hi
    movmskpd eax, xmm0       // 提取掩码到 eax (2-bit)
    mov      hi_mask, eax
  end;
  Result := TMask4(lo_mask or (hi_mask shl 2));
{$ELSE}
begin
  Result := TMask4(Byte(SSE2CmpNeF64x2(a.lo, b.lo)) or (Byte(SSE2CmpNeF64x2(a.hi, b.hi)) shl 2));
{$ENDIF}
end;

// ✅ I32x8 分解实现 (2026-02-05) - 使用 2x I32x4

// ✅ SIMD Quality Iteration 4.4: I32x8 2×128-bit SSE2 ASM 实现
function SSE2AddI32x8(const a, b: TVecI32x8): TVecI32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rax+16]
    movdqu xmm2, [rdx]
    movdqu xmm3, [rdx+16]
    paddd  xmm0, xmm2
    paddd  xmm1, xmm3
    movdqu [rcx], xmm0
    movdqu [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2AddI32x4(a.lo, b.lo);
  Result.hi := SSE2AddI32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2SubI32x8(const a, b: TVecI32x8): TVecI32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rax+16]
    movdqu xmm2, [rdx]
    movdqu xmm3, [rdx+16]
    psubd  xmm0, xmm2
    psubd  xmm1, xmm3
    movdqu [rcx], xmm0
    movdqu [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2SubI32x4(a.lo, b.lo);
  Result.hi := SSE2SubI32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2MulI32x8(const a, b: TVecI32x8): TVecI32x8;
begin
  Result.lo := SSE2MulI32x4(a.lo, b.lo);
  Result.hi := SSE2MulI32x4(a.hi, b.hi);
end;

function SSE2AndI32x8(const a, b: TVecI32x8): TVecI32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rax+16]
    movdqu xmm2, [rdx]
    movdqu xmm3, [rdx+16]
    pand   xmm0, xmm2
    pand   xmm1, xmm3
    movdqu [rcx], xmm0
    movdqu [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2AndI32x4(a.lo, b.lo);
  Result.hi := SSE2AndI32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2OrI32x8(const a, b: TVecI32x8): TVecI32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rax+16]
    movdqu xmm2, [rdx]
    movdqu xmm3, [rdx+16]
    por    xmm0, xmm2
    por    xmm1, xmm3
    movdqu [rcx], xmm0
    movdqu [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2OrI32x4(a.lo, b.lo);
  Result.hi := SSE2OrI32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2XorI32x8(const a, b: TVecI32x8): TVecI32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rax+16]
    movdqu xmm2, [rdx]
    movdqu xmm3, [rdx+16]
    pxor   xmm0, xmm2
    pxor   xmm1, xmm3
    movdqu [rcx], xmm0
    movdqu [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2XorI32x4(a.lo, b.lo);
  Result.hi := SSE2XorI32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2NotI32x8(const a: TVecI32x8): TVecI32x8;
{$IFDEF CPUX64}
var pa, pr: Pointer;
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rax+16]
    // Create all 1s
    pcmpeqd xmm2, xmm2
    movdqa  xmm3, xmm2
    // XOR with all 1s = NOT
    pxor    xmm0, xmm2
    pxor    xmm1, xmm3
    movdqu  [rcx], xmm0
    movdqu  [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2NotI32x4(a.lo);
  Result.hi := SSE2NotI32x4(a.hi);
{$ENDIF}
end;

function SSE2AndNotI32x8(const a, b: TVecI32x8): TVecI32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rax+16]
    movdqu xmm2, [rdx]
    movdqu xmm3, [rdx+16]
    pandn  xmm0, xmm2
    pandn  xmm1, xmm3
    movdqu [rcx], xmm0
    movdqu [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2AndNotI32x4(a.lo, b.lo);
  Result.hi := SSE2AndNotI32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2ShiftLeftI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
{$IFDEF CPUX64}
var pa, pr: Pointer;
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movdqu xmm1, [rax+16]
    movd   xmm2, edx
    pslld  xmm0, xmm2
    pslld  xmm1, xmm2
    movdqu [rcx], xmm0
    movdqu [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2ShiftLeftI32x4(a.lo, count);
  Result.hi := SSE2ShiftLeftI32x4(a.hi, count);
{$ENDIF}
end;

function SSE2ShiftRightI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
{$IFDEF CPUX64}
var pa, pr: Pointer;
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movdqu xmm1, [rax+16]
    movd   xmm2, edx
    psrld  xmm0, xmm2
    psrld  xmm1, xmm2
    movdqu [rcx], xmm0
    movdqu [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2ShiftRightI32x4(a.lo, count);
  Result.hi := SSE2ShiftRightI32x4(a.hi, count);
{$ENDIF}
end;

function SSE2ShiftRightArithI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
{$IFDEF CPUX64}
var pa, pr: Pointer;
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movdqu xmm1, [rax+16]
    movd   xmm2, edx
    psrad  xmm0, xmm2      // 算术右移（保留符号位）
    psrad  xmm1, xmm2
    movdqu [rcx], xmm0
    movdqu [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2ShiftRightArithI32x4(a.lo, count);
  Result.hi := SSE2ShiftRightArithI32x4(a.hi, count);
{$ENDIF}
end;

function SSE2CmpEqI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    // Compare lo (4×int32)
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqd  xmm0, xmm1     // a.lo == b.lo
    movmskps eax, xmm0      // Extract 4-bit mask
    mov      lo_mask, eax
    // Compare hi (4×int32)
    movdqu   xmm0, [rax+16]
    movdqu   xmm1, [rdx+16]
    pcmpeqd  xmm0, xmm1     // a.hi == b.hi
    movmskps eax, xmm0      // Extract 4-bit mask
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

function SSE2CmpLtI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  // LT: a < b is same as b > a
  asm
    mov      rax, pa
    mov      rdx, pb
    // Compare lo (4×int32)
    movdqu   xmm0, [rdx]      // load b.lo
    movdqu   xmm1, [rax]      // load a.lo
    pcmpgtd  xmm0, xmm1       // b.lo > a.lo
    movmskps eax, xmm0
    mov      lo_mask, eax
    // Compare hi (4×int32)
    movdqu   xmm0, [rdx+16]   // load b.hi
    movdqu   xmm1, [rax+16]   // load a.hi
    pcmpgtd  xmm0, xmm1       // b.hi > a.hi
    movmskps eax, xmm0
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

function SSE2CmpGtI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    // Compare lo (4×int32)
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtd  xmm0, xmm1       // a.lo > b.lo
    movmskps eax, xmm0
    mov      lo_mask, eax
    // Compare hi (4×int32)
    movdqu   xmm0, [rax+16]
    movdqu   xmm1, [rdx+16]
    pcmpgtd  xmm0, xmm1       // a.hi > b.hi
    movmskps eax, xmm0
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

function SSE2CmpLeI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  // LE: a <= b is same as NOT(a > b)
  asm
    mov      rax, pa
    mov      rdx, pb
    // Compare lo (4×int32)
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtd  xmm0, xmm1       // a.lo > b.lo
    pcmpeqd  xmm2, xmm2       // all ones
    pxor     xmm0, xmm2       // NOT(a.lo > b.lo)
    movmskps eax, xmm0
    mov      lo_mask, eax
    // Compare hi (4×int32)
    movdqu   xmm0, [rax+16]
    movdqu   xmm1, [rdx+16]
    pcmpgtd  xmm0, xmm1       // a.hi > b.hi
    pcmpeqd  xmm2, xmm2       // all ones
    pxor     xmm0, xmm2       // NOT(a.hi > b.hi)
    movmskps eax, xmm0
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

function SSE2CmpGeI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  // GE: a >= b is same as NOT(b > a)
  asm
    mov      rax, pa
    mov      rdx, pb
    // Compare lo (4×int32)
    movdqu   xmm0, [rdx]      // load b.lo
    movdqu   xmm1, [rax]      // load a.lo
    pcmpgtd  xmm0, xmm1       // b.lo > a.lo
    pcmpeqd  xmm2, xmm2       // all ones
    pxor     xmm0, xmm2       // NOT(b.lo > a.lo)
    movmskps eax, xmm0
    mov      lo_mask, eax
    // Compare hi (4×int32)
    movdqu   xmm0, [rdx+16]   // load b.hi
    movdqu   xmm1, [rax+16]   // load a.hi
    pcmpgtd  xmm0, xmm1       // b.hi > a.hi
    pcmpeqd  xmm2, xmm2       // all ones
    pxor     xmm0, xmm2       // NOT(b.hi > a.hi)
    movmskps eax, xmm0
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

function SSE2CmpNeI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  // NE: NOT(a == b)
  asm
    mov      rax, pa
    mov      rdx, pb
    // Compare lo (4×int32)
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqd  xmm0, xmm1       // a.lo == b.lo
    pcmpeqd  xmm2, xmm2       // all ones
    pxor     xmm0, xmm2       // NOT(a.lo == b.lo)
    movmskps eax, xmm0
    mov      lo_mask, eax
    // Compare hi (4×int32)
    movdqu   xmm0, [rax+16]
    movdqu   xmm1, [rdx+16]
    pcmpeqd  xmm0, xmm1       // a.hi == b.hi
    pcmpeqd  xmm2, xmm2       // all ones
    pxor     xmm0, xmm2       // NOT(a.hi == b.hi)
    movmskps eax, xmm0
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

function SSE2MinI32x8(const a, b: TVecI32x8): TVecI32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  // min(a,b) = (a < b) ? a : b = blend(b, a, a < b)
  // Process 2×128-bit using pcmpgtd + pand/pandn/por
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    // First 128-bit (lo)
    movdqu xmm0, [rax]      // a.lo
    movdqu xmm1, [rdx]      // b.lo
    movdqa xmm2, xmm1       // copy b.lo
    pcmpgtd xmm2, xmm0      // b.lo > a.lo (i.e., a.lo < b.lo)
    movdqa xmm3, xmm0       // copy a.lo
    pand   xmm3, xmm2       // a.lo & mask
    pandn  xmm2, xmm1       // b.lo & ~mask
    por    xmm3, xmm2       // combine
    movdqu [rcx], xmm3
    // Second 128-bit (hi)
    movdqu xmm0, [rax+16]   // a.hi
    movdqu xmm1, [rdx+16]   // b.hi
    movdqa xmm2, xmm1       // copy b.hi
    pcmpgtd xmm2, xmm0      // b.hi > a.hi
    movdqa xmm3, xmm0       // copy a.hi
    pand   xmm3, xmm2       // a.hi & mask
    pandn  xmm2, xmm1       // b.hi & ~mask
    por    xmm3, xmm2       // combine
    movdqu [rcx+16], xmm3
  end;
{$ELSE}
begin
  Result.lo := SSE2MinI32x4(a.lo, b.lo);
  Result.hi := SSE2MinI32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2MaxI32x8(const a, b: TVecI32x8): TVecI32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  // max(a,b) = (a > b) ? a : b = blend(b, a, a > b)
  // Process 2×128-bit using pcmpgtd + pand/pandn/por
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    // First 128-bit (lo)
    movdqu xmm0, [rax]      // a.lo
    movdqu xmm1, [rdx]      // b.lo
    movdqa xmm2, xmm0       // copy a.lo
    pcmpgtd xmm2, xmm1      // a.lo > b.lo
    movdqa xmm3, xmm0       // copy a.lo
    pand   xmm3, xmm2       // a.lo & mask
    pandn  xmm2, xmm1       // b.lo & ~mask
    por    xmm3, xmm2       // combine
    movdqu [rcx], xmm3
    // Second 128-bit (hi)
    movdqu xmm0, [rax+16]   // a.hi
    movdqu xmm1, [rdx+16]   // b.hi
    movdqa xmm2, xmm0       // copy a.hi
    pcmpgtd xmm2, xmm1      // a.hi > b.hi
    movdqa xmm3, xmm0       // copy a.hi
    pand   xmm3, xmm2       // a.hi & mask
    pandn  xmm2, xmm1       // b.hi & ~mask
    por    xmm3, xmm2       // combine
    movdqu [rcx+16], xmm3
  end;
{$ELSE}
begin
  Result.lo := SSE2MaxI32x4(a.lo, b.lo);
  Result.hi := SSE2MaxI32x4(a.hi, b.hi);
{$ENDIF}
end;

// ============================================================================
// ✅ 512-bit 向量的 SSE2 渐进降级实现 (2026-02-05)
// 策略: 使用 2×256-bit 操作 (利用已有的 F32x8/F64x4/I32x8)
// ============================================================================

// === F32x16 操作 (16×Float32) - 使用 2×F32x8 ===

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (Add)
function SSE2AddF32x16(const a, b: TVecF32x16): TVecF32x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    // Load 4 chunks of 128-bit from a
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rax+32]
    movups xmm3, [rax+48]
    // Load 4 chunks of 128-bit from b
    movups xmm4, [rdx]
    movups xmm5, [rdx+16]
    movups xmm6, [rdx+32]
    movups xmm7, [rdx+48]
    // Add
    addps  xmm0, xmm4
    addps  xmm1, xmm5
    addps  xmm2, xmm6
    addps  xmm3, xmm7
    // Store result
    movups [rcx], xmm0
    movups [rcx+16], xmm1
    movups [rcx+32], xmm2
    movups [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (Sub)
function SSE2SubF32x16(const a, b: TVecF32x16): TVecF32x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rax+32]
    movups xmm3, [rax+48]
    movups xmm4, [rdx]
    movups xmm5, [rdx+16]
    movups xmm6, [rdx+32]
    movups xmm7, [rdx+48]
    // Subtract
    subps  xmm0, xmm4
    subps  xmm1, xmm5
    subps  xmm2, xmm6
    subps  xmm3, xmm7
    movups [rcx], xmm0
    movups [rcx+16], xmm1
    movups [rcx+32], xmm2
    movups [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (Mul)
function SSE2MulF32x16(const a, b: TVecF32x16): TVecF32x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rax+32]
    movups xmm3, [rax+48]
    movups xmm4, [rdx]
    movups xmm5, [rdx+16]
    movups xmm6, [rdx+32]
    movups xmm7, [rdx+48]
    // Multiply
    mulps  xmm0, xmm4
    mulps  xmm1, xmm5
    mulps  xmm2, xmm6
    mulps  xmm3, xmm7
    movups [rcx], xmm0
    movups [rcx+16], xmm1
    movups [rcx+32], xmm2
    movups [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (Div)
function SSE2DivF32x16(const a, b: TVecF32x16): TVecF32x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rax+32]
    movups xmm3, [rax+48]
    movups xmm4, [rdx]
    movups xmm5, [rdx+16]
    movups xmm6, [rdx+32]
    movups xmm7, [rdx+48]
    // Divide
    divps  xmm0, xmm4
    divps  xmm1, xmm5
    divps  xmm2, xmm6
    divps  xmm3, xmm7
    movups [rcx], xmm0
    movups [rcx+16], xmm1
    movups [rcx+32], xmm2
    movups [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (Abs)
function SSE2AbsF32x16(const a: TVecF32x16): TVecF32x16;
const
  AbsMask: array[0..3] of UInt32 = ($7FFFFFFF, $7FFFFFFF, $7FFFFFFF, $7FFFFFFF);
var
  pa, pr, pmask: Pointer;
begin
  pa := @a;
  pr := @Result;
  pmask := @AbsMask;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    rdx, pmask
    // Load abs mask (clears sign bit)
    movups xmm4, [rdx]
    // Load 4 chunks
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rax+32]
    movups xmm3, [rax+48]
    // Apply abs mask (bitwise AND)
    andps  xmm0, xmm4
    andps  xmm1, xmm4
    andps  xmm2, xmm4
    andps  xmm3, xmm4
    // Store result
    movups [rcx], xmm0
    movups [rcx+16], xmm1
    movups [rcx+32], xmm2
    movups [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (Sqrt)
function SSE2SqrtF32x16(const a: TVecF32x16): TVecF32x16;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rax+32]
    movups xmm3, [rax+48]
    // Square root
    sqrtps xmm0, xmm0
    sqrtps xmm1, xmm1
    sqrtps xmm2, xmm2
    sqrtps xmm3, xmm3
    movups [rcx], xmm0
    movups [rcx+16], xmm1
    movups [rcx+32], xmm2
    movups [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (Min)
function SSE2MinF32x16(const a, b: TVecF32x16): TVecF32x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rax+32]
    movups xmm3, [rax+48]
    movups xmm4, [rdx]
    movups xmm5, [rdx+16]
    movups xmm6, [rdx+32]
    movups xmm7, [rdx+48]
    // Min
    minps  xmm0, xmm4
    minps  xmm1, xmm5
    minps  xmm2, xmm6
    minps  xmm3, xmm7
    movups [rcx], xmm0
    movups [rcx+16], xmm1
    movups [rcx+32], xmm2
    movups [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (Max)
function SSE2MaxF32x16(const a, b: TVecF32x16): TVecF32x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rax+32]
    movups xmm3, [rax+48]
    movups xmm4, [rdx]
    movups xmm5, [rdx+16]
    movups xmm6, [rdx+32]
    movups xmm7, [rdx+48]
    // Max
    maxps  xmm0, xmm4
    maxps  xmm1, xmm5
    maxps  xmm2, xmm6
    maxps  xmm3, xmm7
    movups [rcx], xmm0
    movups [rcx+16], xmm1
    movups [rcx+32], xmm2
    movups [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (FMA: a*b+c)
function SSE2FmaF32x16(const a, b, c: TVecF32x16): TVecF32x16;
var
  pa, pb, pc, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pc := @c;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    r8,  pc
    mov    rcx, pr
    // Load a (4×128-bit)
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rax+32]
    movups xmm3, [rax+48]
    // Load b (4×128-bit)
    movups xmm4, [rdx]
    movups xmm5, [rdx+16]
    movups xmm6, [rdx+32]
    movups xmm7, [rdx+48]
    // Multiply a * b
    mulps  xmm0, xmm4
    mulps  xmm1, xmm5
    mulps  xmm2, xmm6
    mulps  xmm3, xmm7
    // Load c (4×128-bit)
    movups xmm4, [r8]
    movups xmm5, [r8+16]
    movups xmm6, [r8+32]
    movups xmm7, [r8+48]
    // Add c
    addps  xmm0, xmm4
    addps  xmm1, xmm5
    addps  xmm2, xmm6
    addps  xmm3, xmm7
    // Store result
    movups [rcx], xmm0
    movups [rcx+16], xmm1
    movups [rcx+32], xmm2
    movups [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (Floor)
function SSE2FloorF32x16(const a: TVecF32x16): TVecF32x16;
const
  OneSingle: array[0..3] of Single = (1.0, 1.0, 1.0, 1.0);
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    // Load 1.0 constant
    movups xmm15, [rip + OneSingle]

    // === 处理第 1 块 (xmm0) ===
    movups xmm0, [rax]
    movaps xmm1, xmm0        // 保存原值
    cvttps2dq xmm0, xmm0     // 截断转整数
    cvtdq2ps xmm0, xmm0      // 转回浮点
    movaps xmm2, xmm1
    cmpltps xmm2, xmm0       // 原值 < 截断值？
    andps  xmm2, xmm15       // 掩码 & 1.0
    subps  xmm0, xmm2        // 减去修正值

    // === 处理第 2 块 (xmm4) ===
    movups xmm4, [rax+16]
    movaps xmm5, xmm4
    cvttps2dq xmm4, xmm4
    cvtdq2ps xmm4, xmm4
    movaps xmm6, xmm5
    cmpltps xmm6, xmm4
    andps  xmm6, xmm15
    subps  xmm4, xmm6

    // === 处理第 3 块 (xmm8) ===
    movups xmm8, [rax+32]
    movaps xmm9, xmm8
    cvttps2dq xmm8, xmm8
    cvtdq2ps xmm8, xmm8
    movaps xmm10, xmm9
    cmpltps xmm10, xmm8
    andps  xmm10, xmm15
    subps  xmm8, xmm10

    // === 处理第 4 块 (xmm12) ===
    movups xmm12, [rax+48]
    movaps xmm13, xmm12
    cvttps2dq xmm12, xmm12
    cvtdq2ps xmm12, xmm12
    movaps xmm14, xmm13
    cmpltps xmm14, xmm12
    andps  xmm14, xmm15
    subps  xmm12, xmm14

    // Store results
    movups [rcx], xmm0
    movups [rcx+16], xmm4
    movups [rcx+32], xmm8
    movups [rcx+48], xmm12
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (Ceil)
function SSE2CeilF32x16(const a: TVecF32x16): TVecF32x16;
const
  OneSingle: array[0..3] of Single = (1.0, 1.0, 1.0, 1.0);
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    // Load 1.0 constant
    movups xmm15, [rip + OneSingle]

    // === 处理第 1 块 (xmm0) ===
    movups xmm0, [rax]
    movaps xmm1, xmm0        // 保存原值
    cvttps2dq xmm0, xmm0     // 截断转整数
    cvtdq2ps xmm0, xmm0      // 转回浮点
    cmpltps xmm0, xmm1       // 截断值 < 原值？
    andps  xmm0, xmm15       // 掩码 & 1.0
    movaps xmm2, xmm1
    cvttps2dq xmm2, xmm2     // 重新计算截断值
    cvtdq2ps xmm2, xmm2
    addps  xmm0, xmm2        // 加上修正值

    // === 处理第 2 块 (xmm4) ===
    movups xmm4, [rax+16]
    movaps xmm5, xmm4
    cvttps2dq xmm4, xmm4
    cvtdq2ps xmm4, xmm4
    cmpltps xmm4, xmm5
    andps  xmm4, xmm15
    movaps xmm6, xmm5
    cvttps2dq xmm6, xmm6
    cvtdq2ps xmm6, xmm6
    addps  xmm4, xmm6

    // === 处理第 3 块 (xmm8) ===
    movups xmm8, [rax+32]
    movaps xmm9, xmm8
    cvttps2dq xmm8, xmm8
    cvtdq2ps xmm8, xmm8
    cmpltps xmm8, xmm9
    andps  xmm8, xmm15
    movaps xmm10, xmm9
    cvttps2dq xmm10, xmm10
    cvtdq2ps xmm10, xmm10
    addps  xmm8, xmm10

    // === 处理第 4 块 (xmm12) ===
    movups xmm12, [rax+48]
    movaps xmm13, xmm12
    cvttps2dq xmm12, xmm12
    cvtdq2ps xmm12, xmm12
    cmpltps xmm12, xmm13
    andps  xmm12, xmm15
    movaps xmm14, xmm13
    cvttps2dq xmm14, xmm14
    cvtdq2ps xmm14, xmm14
    addps  xmm12, xmm14

    // Store results
    movups [rcx], xmm0
    movups [rcx+16], xmm4
    movups [rcx+32], xmm8
    movups [rcx+48], xmm12
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (Round)
function SSE2RoundF32x16(const a: TVecF32x16): TVecF32x16;
const
  HalfSingle: array[0..3] of Single = (0.5, 0.5, 0.5, 0.5);
  SignMaskPS: array[0..3] of UInt32 = ($80000000, $80000000, $80000000, $80000000);
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    // Load constants
    movups xmm14, [rip + HalfSingle]
    movups xmm15, [rip + SignMaskPS]

    // === 处理第 1 块 (xmm0) ===
    movups xmm0, [rax]
    movaps xmm1, xmm0
    movaps xmm2, xmm15
    movaps xmm3, xmm1
    andps  xmm3, xmm2        // 提取符号
    andnps xmm2, xmm1        // 取绝对值
    addps  xmm2, xmm14       // 加 0.5
    cvttps2dq xmm2, xmm2     // 截断
    cvtdq2ps xmm2, xmm2
    orps   xmm2, xmm3        // 恢复符号
    movaps xmm0, xmm2

    // === 处理第 2 块 (xmm4) ===
    movups xmm4, [rax+16]
    movaps xmm5, xmm4
    movaps xmm6, xmm15
    movaps xmm7, xmm5
    andps  xmm7, xmm6
    andnps xmm6, xmm5
    addps  xmm6, xmm14
    cvttps2dq xmm6, xmm6
    cvtdq2ps xmm6, xmm6
    orps   xmm6, xmm7
    movaps xmm4, xmm6

    // === 处理第 3 块 (xmm8) ===
    movups xmm8, [rax+32]
    movaps xmm9, xmm8
    movaps xmm10, xmm15
    movaps xmm11, xmm9
    andps  xmm11, xmm10
    andnps xmm10, xmm9
    addps  xmm10, xmm14
    cvttps2dq xmm10, xmm10
    cvtdq2ps xmm10, xmm10
    orps   xmm10, xmm11
    movaps xmm8, xmm10

    // === 处理第 4 块 (xmm12) ===
    movups xmm12, [rax+48]
    movaps xmm13, xmm12
    movaps xmm1, xmm15       // 重用 xmm1 作为临时寄存器
    movaps xmm2, xmm13
    andps  xmm2, xmm1
    andnps xmm1, xmm13
    addps  xmm1, xmm14
    cvttps2dq xmm1, xmm1
    cvtdq2ps xmm1, xmm1
    orps   xmm1, xmm2
    movaps xmm12, xmm1

    // Store results
    movups [rcx], xmm0
    movups [rcx+16], xmm4
    movups [rcx+32], xmm8
    movups [rcx+48], xmm12
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (Trunc: 截断到整数)
function SSE2TruncF32x16(const a: TVecF32x16): TVecF32x16;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    // Load and truncate 4 chunks
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rax+32]
    movups xmm3, [rax+48]
    // Truncate to integer and convert back
    cvttps2dq xmm0, xmm0
    cvttps2dq xmm1, xmm1
    cvttps2dq xmm2, xmm2
    cvttps2dq xmm3, xmm3
    cvtdq2ps xmm0, xmm0
    cvtdq2ps xmm1, xmm1
    cvtdq2ps xmm2, xmm2
    cvtdq2ps xmm3, xmm3
    // Store results
    movups [rcx], xmm0
    movups [rcx+16], xmm1
    movups [rcx+32], xmm2
    movups [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (Clamp: 限制在 [minVal, maxVal] 范围)
function SSE2ClampF32x16(const a, minVal, maxVal: TVecF32x16): TVecF32x16;
var
  pa, pmin, pmax, pr: Pointer;
begin
  pa := @a;
  pmin := @minVal;
  pmax := @maxVal;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pmin
    mov    r8,  pmax
    mov    rcx, pr
    // Load a (4×128-bit)
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rax+32]
    movups xmm3, [rax+48]
    // Load minVal (4×128-bit)
    movups xmm4, [rdx]
    movups xmm5, [rdx+16]
    movups xmm6, [rdx+32]
    movups xmm7, [rdx+48]
    // Max with minVal
    maxps  xmm0, xmm4
    maxps  xmm1, xmm5
    maxps  xmm2, xmm6
    maxps  xmm3, xmm7
    // Load maxVal (4×128-bit)
    movups xmm4, [r8]
    movups xmm5, [r8+16]
    movups xmm6, [r8+32]
    movups xmm7, [r8+48]
    // Min with maxVal
    minps  xmm0, xmm4
    minps  xmm1, xmm5
    minps  xmm2, xmm6
    minps  xmm3, xmm7
    // Store results
    movups [rcx], xmm0
    movups [rcx+16], xmm1
    movups [rcx+32], xmm2
    movups [rcx+48], xmm3
  end;
end;

function SSE2ReduceAddF32x16(const a: TVecF32x16): Single;
begin
  Result := SSE2ReduceAddF32x8(a.lo) + SSE2ReduceAddF32x8(a.hi);
end;

function SSE2ReduceMinF32x16(const a: TVecF32x16): Single;
var
  minLo, minHi: Single;
begin
  minLo := SSE2ReduceMinF32x8(a.lo);
  minHi := SSE2ReduceMinF32x8(a.hi);
  if minLo < minHi then
    Result := minLo
  else
    Result := minHi;
end;

function SSE2ReduceMaxF32x16(const a: TVecF32x16): Single;
var
  maxLo, maxHi: Single;
begin
  maxLo := SSE2ReduceMaxF32x8(a.lo);
  maxHi := SSE2ReduceMaxF32x8(a.hi);
  if maxLo > maxHi then
    Result := maxLo
  else
    Result := maxHi;
end;

function SSE2ReduceMulF32x16(const a: TVecF32x16): Single;
begin
  Result := SSE2ReduceMulF32x8(a.lo) * SSE2ReduceMulF32x8(a.hi);
end;

function SSE2LoadF32x16(p: PSingle): TVecF32x16;
begin
  Result.lo := SSE2LoadF32x8(p);
  Result.hi := SSE2LoadF32x8(p + 8);
end;

procedure SSE2StoreF32x16(p: PSingle; const a: TVecF32x16);
begin
  SSE2StoreF32x8(p, a.lo);
  SSE2StoreF32x8(p + 8, a.hi);
end;

function SSE2SplatF32x16(value: Single): TVecF32x16;
begin
  Result.lo := SSE2SplatF32x8(value);
  Result.hi := SSE2SplatF32x8(value);
end;

function SSE2ZeroF32x16: TVecF32x16;
begin
  Result.lo := SSE2ZeroF32x8;
  Result.hi := SSE2ZeroF32x8;
end;

function SSE2CmpEqF32x16(const a, b: TVecF32x16): TMask16;
var
  i: Integer;
  mask: Word;
begin
  mask := 0;
  for i := 0 to 15 do
  begin
    if a.f[i] = b.f[i] then
      mask := mask or (1 shl i);
  end;
  Result := mask;
end;

function SSE2CmpLtF32x16(const a, b: TVecF32x16): TMask16;
var
  i: Integer;
  mask: Word;
begin
  mask := 0;
  for i := 0 to 15 do
  begin
    if a.f[i] < b.f[i] then
      mask := mask or (1 shl i);
  end;
  Result := mask;
end;

function SSE2CmpLeF32x16(const a, b: TVecF32x16): TMask16;
var
  i: Integer;
  mask: Word;
begin
  mask := 0;
  for i := 0 to 15 do
  begin
    if a.f[i] <= b.f[i] then
      mask := mask or (1 shl i);
  end;
  Result := mask;
end;

function SSE2CmpGtF32x16(const a, b: TVecF32x16): TMask16;
var
  i: Integer;
  mask: Word;
begin
  mask := 0;
  for i := 0 to 15 do
  begin
    if a.f[i] > b.f[i] then
      mask := mask or (1 shl i);
  end;
  Result := mask;
end;

function SSE2CmpGeF32x16(const a, b: TVecF32x16): TMask16;
var
  i: Integer;
  mask: Word;
begin
  mask := 0;
  for i := 0 to 15 do
  begin
    if a.f[i] >= b.f[i] then
      mask := mask or (1 shl i);
  end;
  Result := mask;
end;

function SSE2CmpNeF32x16(const a, b: TVecF32x16): TMask16;
var
  i: Integer;
  mask: Word;
begin
  mask := 0;
  for i := 0 to 15 do
  begin
    if a.f[i] <> b.f[i] then
      mask := mask or (1 shl i);
  end;
  Result := mask;
end;

function SSE2SelectF32x16(const mask: TMask16; const a, b: TVecF32x16): TVecF32x16;
var
  i: Integer;
begin
  for i := 0 to 15 do
  begin
    if (mask and (1 shl i)) <> 0 then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
  end;
end;

// === F64x8 操作 (8×Float64) - 使用 2×F64x4 ===

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (F64x8 Add)
function SSE2AddF64x8(const a, b: TVecF64x8): TVecF64x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    // Load 4 chunks of 128-bit from a (each holds 2 doubles)
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rax+32]
    movupd xmm3, [rax+48]
    // Load 4 chunks of 128-bit from b
    movupd xmm4, [rdx]
    movupd xmm5, [rdx+16]
    movupd xmm6, [rdx+32]
    movupd xmm7, [rdx+48]
    // Add (packed double)
    addpd  xmm0, xmm4
    addpd  xmm1, xmm5
    addpd  xmm2, xmm6
    addpd  xmm3, xmm7
    // Store result
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
    movupd [rcx+32], xmm2
    movupd [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (F64x8 Sub)
function SSE2SubF64x8(const a, b: TVecF64x8): TVecF64x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rax+32]
    movupd xmm3, [rax+48]
    movupd xmm4, [rdx]
    movupd xmm5, [rdx+16]
    movupd xmm6, [rdx+32]
    movupd xmm7, [rdx+48]
    // Subtract
    subpd  xmm0, xmm4
    subpd  xmm1, xmm5
    subpd  xmm2, xmm6
    subpd  xmm3, xmm7
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
    movupd [rcx+32], xmm2
    movupd [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (F64x8 Mul)
function SSE2MulF64x8(const a, b: TVecF64x8): TVecF64x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rax+32]
    movupd xmm3, [rax+48]
    movupd xmm4, [rdx]
    movupd xmm5, [rdx+16]
    movupd xmm6, [rdx+32]
    movupd xmm7, [rdx+48]
    // Multiply
    mulpd  xmm0, xmm4
    mulpd  xmm1, xmm5
    mulpd  xmm2, xmm6
    mulpd  xmm3, xmm7
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
    movupd [rcx+32], xmm2
    movupd [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (F64x8 Div)
function SSE2DivF64x8(const a, b: TVecF64x8): TVecF64x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rax+32]
    movupd xmm3, [rax+48]
    movupd xmm4, [rdx]
    movupd xmm5, [rdx+16]
    movupd xmm6, [rdx+32]
    movupd xmm7, [rdx+48]
    // Divide
    divpd  xmm0, xmm4
    divpd  xmm1, xmm5
    divpd  xmm2, xmm6
    divpd  xmm3, xmm7
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
    movupd [rcx+32], xmm2
    movupd [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (F64x8 Abs)
function SSE2AbsF64x8(const a: TVecF64x8): TVecF64x8;
const
  AbsMask: array[0..1] of UInt64 = ($7FFFFFFFFFFFFFFF, $7FFFFFFFFFFFFFFF);
var
  pa, pr, pmask: Pointer;
begin
  pa := @a;
  pr := @Result;
  pmask := @AbsMask;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    rdx, pmask
    // Load abs mask (clears sign bit for double)
    movupd xmm4, [rdx]
    // Load 4 chunks
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rax+32]
    movupd xmm3, [rax+48]
    // Apply abs mask (bitwise AND)
    andpd  xmm0, xmm4
    andpd  xmm1, xmm4
    andpd  xmm2, xmm4
    andpd  xmm3, xmm4
    // Store result
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
    movupd [rcx+32], xmm2
    movupd [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (F64x8 Sqrt)
function SSE2SqrtF64x8(const a: TVecF64x8): TVecF64x8;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rax+32]
    movupd xmm3, [rax+48]
    // Square root
    sqrtpd xmm0, xmm0
    sqrtpd xmm1, xmm1
    sqrtpd xmm2, xmm2
    sqrtpd xmm3, xmm3
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
    movupd [rcx+32], xmm2
    movupd [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (F64x8 Min)
function SSE2MinF64x8(const a, b: TVecF64x8): TVecF64x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rax+32]
    movupd xmm3, [rax+48]
    movupd xmm4, [rdx]
    movupd xmm5, [rdx+16]
    movupd xmm6, [rdx+32]
    movupd xmm7, [rdx+48]
    // Min
    minpd  xmm0, xmm4
    minpd  xmm1, xmm5
    minpd  xmm2, xmm6
    minpd  xmm3, xmm7
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
    movupd [rcx+32], xmm2
    movupd [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (F64x8 Max)
function SSE2MaxF64x8(const a, b: TVecF64x8): TVecF64x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rax+32]
    movupd xmm3, [rax+48]
    movupd xmm4, [rdx]
    movupd xmm5, [rdx+16]
    movupd xmm6, [rdx+32]
    movupd xmm7, [rdx+48]
    // Max
    maxpd  xmm0, xmm4
    maxpd  xmm1, xmm5
    maxpd  xmm2, xmm6
    maxpd  xmm3, xmm7
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
    movupd [rcx+32], xmm2
    movupd [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (F64x8 FMA: a*b+c)
function SSE2FmaF64x8(const a, b, c: TVecF64x8): TVecF64x8;
var
  pa, pb, pc, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pc := @c;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    r8,  pc
    mov    rcx, pr
    // Load a (4×128-bit, each holds 2 doubles)
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rax+32]
    movupd xmm3, [rax+48]
    // Load b (4×128-bit)
    movupd xmm4, [rdx]
    movupd xmm5, [rdx+16]
    movupd xmm6, [rdx+32]
    movupd xmm7, [rdx+48]
    // Multiply a * b
    mulpd  xmm0, xmm4
    mulpd  xmm1, xmm5
    mulpd  xmm2, xmm6
    mulpd  xmm3, xmm7
    // Load c (4×128-bit)
    movupd xmm4, [r8]
    movupd xmm5, [r8+16]
    movupd xmm6, [r8+32]
    movupd xmm7, [r8+48]
    // Add c
    addpd  xmm0, xmm4
    addpd  xmm1, xmm5
    addpd  xmm2, xmm6
    addpd  xmm3, xmm7
    // Store results
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
    movupd [rcx+32], xmm2
    movupd [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (F64x8 Floor)
function SSE2FloorF64x8(const a: TVecF64x8): TVecF64x8;
const
  OneDouble: array[0..1] of Double = (1.0, 1.0);
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    // Load 1.0 constant
    movupd xmm15, [rip + OneDouble]

    // === 处理第 1 块 (xmm0) ===
    movupd xmm0, [rax]
    movapd xmm1, xmm0        // 保存原值
    cvttpd2dq xmm0, xmm0     // 截断转整数
    cvtdq2pd xmm0, xmm0      // 转回浮点
    movapd xmm2, xmm1
    cmpltpd xmm2, xmm0       // 原值 < 截断值？
    andpd  xmm2, xmm15       // 掩码 & 1.0
    subpd  xmm0, xmm2        // 减去修正值

    // === 处理第 2 块 (xmm4) ===
    movupd xmm4, [rax+16]
    movapd xmm5, xmm4
    cvttpd2dq xmm4, xmm4
    cvtdq2pd xmm4, xmm4
    movapd xmm6, xmm5
    cmpltpd xmm6, xmm4
    andpd  xmm6, xmm15
    subpd  xmm4, xmm6

    // === 处理第 3 块 (xmm8) ===
    movupd xmm8, [rax+32]
    movapd xmm9, xmm8
    cvttpd2dq xmm8, xmm8
    cvtdq2pd xmm8, xmm8
    movapd xmm10, xmm9
    cmpltpd xmm10, xmm8
    andpd  xmm10, xmm15
    subpd  xmm8, xmm10

    // === 处理第 4 块 (xmm12) ===
    movupd xmm12, [rax+48]
    movapd xmm13, xmm12
    cvttpd2dq xmm12, xmm12
    cvtdq2pd xmm12, xmm12
    movapd xmm14, xmm13
    cmpltpd xmm14, xmm12
    andpd  xmm14, xmm15
    subpd  xmm12, xmm14

    // Store results
    movupd [rcx], xmm0
    movupd [rcx+16], xmm4
    movupd [rcx+32], xmm8
    movupd [rcx+48], xmm12
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (F64x8 Ceil)
function SSE2CeilF64x8(const a: TVecF64x8): TVecF64x8;
const
  OneDouble: array[0..1] of Double = (1.0, 1.0);
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    // Load 1.0 constant
    movupd xmm15, [rip + OneDouble]

    // === 处理第 1 块 (xmm0) ===
    movupd xmm0, [rax]
    movapd xmm1, xmm0        // 保存原值
    cvttpd2dq xmm0, xmm0     // 截断转整数
    cvtdq2pd xmm0, xmm0      // 转回浮点
    cmpltpd xmm0, xmm1       // 截断值 < 原值？
    andpd  xmm0, xmm15       // 掩码 & 1.0
    movapd xmm2, xmm1
    cvttpd2dq xmm2, xmm2     // 重新计算截断值
    cvtdq2pd xmm2, xmm2
    addpd  xmm0, xmm2        // 加上修正值

    // === 处理第 2 块 (xmm4) ===
    movupd xmm4, [rax+16]
    movapd xmm5, xmm4
    cvttpd2dq xmm4, xmm4
    cvtdq2pd xmm4, xmm4
    cmpltpd xmm4, xmm5
    andpd  xmm4, xmm15
    movapd xmm6, xmm5
    cvttpd2dq xmm6, xmm6
    cvtdq2pd xmm6, xmm6
    addpd  xmm4, xmm6

    // === 处理第 3 块 (xmm8) ===
    movupd xmm8, [rax+32]
    movapd xmm9, xmm8
    cvttpd2dq xmm8, xmm8
    cvtdq2pd xmm8, xmm8
    cmpltpd xmm8, xmm9
    andpd  xmm8, xmm15
    movapd xmm10, xmm9
    cvttpd2dq xmm10, xmm10
    cvtdq2pd xmm10, xmm10
    addpd  xmm8, xmm10

    // === 处理第 4 块 (xmm12) ===
    movupd xmm12, [rax+48]
    movapd xmm13, xmm12
    cvttpd2dq xmm12, xmm12
    cvtdq2pd xmm12, xmm12
    cmpltpd xmm12, xmm13
    andpd  xmm12, xmm15
    movapd xmm14, xmm13
    cvttpd2dq xmm14, xmm14
    cvtdq2pd xmm14, xmm14
    addpd  xmm12, xmm14

    // Store results
    movupd [rcx], xmm0
    movupd [rcx+16], xmm4
    movupd [rcx+32], xmm8
    movupd [rcx+48], xmm12
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (F64x8 Round: 四舍五入)
function SSE2RoundF64x8(const a: TVecF64x8): TVecF64x8;
const
  HalfDouble: array[0..1] of Double = (0.5, 0.5);
  SignMaskPD: array[0..3] of UInt32 = ($00000000, $80000000, $00000000, $80000000);
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    // Load constants
    movupd xmm14, [rip + HalfDouble]
    movupd xmm15, [rip + SignMaskPD]

    // === 处理第 1 块 (xmm0) ===
    movupd xmm0, [rax]
    movapd xmm1, xmm0
    movapd xmm2, xmm15
    movapd xmm3, xmm1
    andpd  xmm3, xmm2      // xmm3 = sign
    andnpd xmm2, xmm1      // xmm2 = abs(x)
    addpd  xmm2, xmm14     // abs(x) + 0.5
    cvttpd2dq xmm2, xmm2
    cvtdq2pd xmm2, xmm2
    orpd   xmm2, xmm3      // 恢复符号
    movapd xmm0, xmm2

    // === 处理第 2 块 (xmm4) ===
    movupd xmm4, [rax+16]
    movapd xmm5, xmm4
    movapd xmm6, xmm15
    movapd xmm7, xmm5
    andpd  xmm7, xmm6
    andnpd xmm6, xmm5
    addpd  xmm6, xmm14
    cvttpd2dq xmm6, xmm6
    cvtdq2pd xmm6, xmm6
    orpd   xmm6, xmm7
    movapd xmm4, xmm6

    // === 处理第 3 块 (xmm8) ===
    movupd xmm8, [rax+32]
    movapd xmm9, xmm8
    movapd xmm10, xmm15
    movapd xmm11, xmm9
    andpd  xmm11, xmm10
    andnpd xmm10, xmm9
    addpd  xmm10, xmm14
    cvttpd2dq xmm10, xmm10
    cvtdq2pd xmm10, xmm10
    orpd   xmm10, xmm11
    movapd xmm8, xmm10

    // === 处理第 4 块 (xmm12) ===
    movupd xmm12, [rax+48]
    movapd xmm13, xmm12
    movapd xmm1, xmm15
    movapd xmm3, xmm13
    andpd  xmm3, xmm1
    andnpd xmm1, xmm13
    addpd  xmm1, xmm14
    cvttpd2dq xmm1, xmm1
    cvtdq2pd xmm1, xmm1
    orpd   xmm1, xmm3
    movapd xmm12, xmm1

    // Store results
    movupd [rcx], xmm0
    movupd [rcx+16], xmm4
    movupd [rcx+32], xmm8
    movupd [rcx+48], xmm12
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (F64x8 Trunc: 截断到整数)
function SSE2TruncF64x8(const a: TVecF64x8): TVecF64x8;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    // Load and truncate 4 chunks
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rax+32]
    movupd xmm3, [rax+48]
    // Truncate to integer and convert back
    cvttpd2dq xmm0, xmm0
    cvttpd2dq xmm1, xmm1
    cvttpd2dq xmm2, xmm2
    cvttpd2dq xmm3, xmm3
    cvtdq2pd xmm0, xmm0
    cvtdq2pd xmm1, xmm1
    cvtdq2pd xmm2, xmm2
    cvtdq2pd xmm3, xmm3
    // Store results
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
    movupd [rcx+32], xmm2
    movupd [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.3: 4×128-bit SSE2 ASM 实现 (F64x8 Clamp: 限制在 [minVal, maxVal] 范围)
function SSE2ClampF64x8(const a, minVal, maxVal: TVecF64x8): TVecF64x8;
var
  pa, pmin, pmax, pr: Pointer;
begin
  pa := @a;
  pmin := @minVal;
  pmax := @maxVal;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pmin
    mov    r8,  pmax
    mov    rcx, pr
    // Load a (4×128-bit)
    movupd xmm0, [rax]
    movupd xmm1, [rax+16]
    movupd xmm2, [rax+32]
    movupd xmm3, [rax+48]
    // Load minVal (4×128-bit)
    movupd xmm4, [rdx]
    movupd xmm5, [rdx+16]
    movupd xmm6, [rdx+32]
    movupd xmm7, [rdx+48]
    // Max with minVal
    maxpd  xmm0, xmm4
    maxpd  xmm1, xmm5
    maxpd  xmm2, xmm6
    maxpd  xmm3, xmm7
    // Load maxVal (4×128-bit)
    movupd xmm4, [r8]
    movupd xmm5, [r8+16]
    movupd xmm6, [r8+32]
    movupd xmm7, [r8+48]
    // Min with maxVal
    minpd  xmm0, xmm4
    minpd  xmm1, xmm5
    minpd  xmm2, xmm6
    minpd  xmm3, xmm7
    // Store results
    movupd [rcx], xmm0
    movupd [rcx+16], xmm1
    movupd [rcx+32], xmm2
    movupd [rcx+48], xmm3
  end;
end;

function SSE2ReduceAddF64x8(const a: TVecF64x8): Double;
begin
  Result := SSE2ReduceAddF64x4(a.lo) + SSE2ReduceAddF64x4(a.hi);
end;

function SSE2ReduceMinF64x8(const a: TVecF64x8): Double;
var
  minLo, minHi: Double;
begin
  minLo := SSE2ReduceMinF64x4(a.lo);
  minHi := SSE2ReduceMinF64x4(a.hi);
  if minLo < minHi then
    Result := minLo
  else
    Result := minHi;
end;

function SSE2ReduceMaxF64x8(const a: TVecF64x8): Double;
var
  maxLo, maxHi: Double;
begin
  maxLo := SSE2ReduceMaxF64x4(a.lo);
  maxHi := SSE2ReduceMaxF64x4(a.hi);
  if maxLo > maxHi then
    Result := maxLo
  else
    Result := maxHi;
end;

function SSE2ReduceMulF64x8(const a: TVecF64x8): Double;
begin
  Result := SSE2ReduceMulF64x4(a.lo) * SSE2ReduceMulF64x4(a.hi);
end;

function SSE2LoadF64x8(p: PDouble): TVecF64x8;
begin
  Result.lo := SSE2LoadF64x4(p);
  Result.hi := SSE2LoadF64x4(p + 4);
end;

procedure SSE2StoreF64x8(p: PDouble; const a: TVecF64x8);
begin
  SSE2StoreF64x4(p, a.lo);
  SSE2StoreF64x4(p + 4, a.hi);
end;

function SSE2SplatF64x8(value: Double): TVecF64x8;
begin
  Result.lo := SSE2SplatF64x4(value);
  Result.hi := SSE2SplatF64x4(value);
end;

function SSE2ZeroF64x8: TVecF64x8;
begin
  Result.lo := SSE2ZeroF64x4;
  Result.hi := SSE2ZeroF64x4;
end;

function SSE2CmpEqF64x8(const a, b: TVecF64x8): TMask8;
var
  i: Integer;
  mask: Byte;
begin
  mask := 0;
  for i := 0 to 7 do
  begin
    if a.d[i] = b.d[i] then
      mask := mask or (1 shl i);
  end;
  Result := mask;
end;

function SSE2CmpLtF64x8(const a, b: TVecF64x8): TMask8;
var
  i: Integer;
  mask: Byte;
begin
  mask := 0;
  for i := 0 to 7 do
  begin
    if a.d[i] < b.d[i] then
      mask := mask or (1 shl i);
  end;
  Result := mask;
end;

function SSE2CmpLeF64x8(const a, b: TVecF64x8): TMask8;
var
  i: Integer;
  mask: Byte;
begin
  mask := 0;
  for i := 0 to 7 do
  begin
    if a.d[i] <= b.d[i] then
      mask := mask or (1 shl i);
  end;
  Result := mask;
end;

function SSE2CmpGtF64x8(const a, b: TVecF64x8): TMask8;
var
  i: Integer;
  mask: Byte;
begin
  mask := 0;
  for i := 0 to 7 do
  begin
    if a.d[i] > b.d[i] then
      mask := mask or (1 shl i);
  end;
  Result := mask;
end;

function SSE2CmpGeF64x8(const a, b: TVecF64x8): TMask8;
var
  i: Integer;
  mask: Byte;
begin
  mask := 0;
  for i := 0 to 7 do
  begin
    if a.d[i] >= b.d[i] then
      mask := mask or (1 shl i);
  end;
  Result := mask;
end;

function SSE2CmpNeF64x8(const a, b: TVecF64x8): TMask8;
var
  i: Integer;
  mask: Byte;
begin
  mask := 0;
  for i := 0 to 7 do
  begin
    if a.d[i] <> b.d[i] then
      mask := mask or (1 shl i);
  end;
  Result := mask;
end;

function SSE2SelectF64x8(const mask: TMask8; const a, b: TVecF64x8): TVecF64x8;
var
  i: Integer;
begin
  for i := 0 to 7 do
  begin
    if (mask and (1 shl i)) <> 0 then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
  end;
end;

// ✅ NEW: 缺失的 Select 操作实现
// SelectI32x4: 使用 PAND + PANDN + POR 实现
// Result = (a AND mask) OR (b AND NOT mask)
function SSE2SelectI32x4(const mask: TVecI32x4; const a, b: TVecI32x4): TVecI32x4;
var
  pMask, pA, pB, pR: Pointer;
begin
  pMask := @mask;
  pA := @a;
  pB := @b;
  pR := @Result;
  asm
    mov    rax, pMask
    mov    rdx, pA
    mov    rcx, pB
    mov    r8,  pR

    movdqu xmm2, [rax]      // xmm2 = mask
    movdqu xmm0, [rdx]      // xmm0 = a
    movdqu xmm1, [rcx]      // xmm1 = b

    // Result = (a AND mask) OR (b AND NOT mask)
    pand   xmm0, xmm2       // xmm0 = a AND mask
    pandn  xmm2, xmm1       // xmm2 = (NOT mask) AND b
    por    xmm0, xmm2       // xmm0 = combine

    movdqu [r8], xmm0       // store result
  end;
end;

// SelectF32x8: 使用 2×128-bit SSE2 操作
function SSE2SelectF32x8(const mask: TVecU32x8; const a, b: TVecF32x8): TVecF32x8;
var
  pMaskLo, pMaskHi, pALo, pAHi, pBLo, pBHi, pRLo, pRHi: Pointer;
begin
  pMaskLo := @mask.lo;
  pMaskHi := @mask.hi;
  pALo := @a.lo;
  pAHi := @a.hi;
  pBLo := @b.lo;
  pBHi := @b.hi;
  pRLo := @Result.lo;
  pRHi := @Result.hi;

  // Low 128-bits
  asm
    mov    rax, pMaskLo
    mov    rdx, pALo
    mov    rcx, pBLo
    mov    r8,  pRLo

    movdqu xmm2, [rax]      // xmm2 = mask.lo
    movups xmm0, [rdx]      // xmm0 = a.lo
    movups xmm1, [rcx]      // xmm1 = b.lo

    // 使用整数逻辑指令处理浮点数据
    pand   xmm0, xmm2       // xmm0 = a.lo AND mask.lo
    pandn  xmm2, xmm1       // xmm2 = (NOT mask.lo) AND b.lo
    por    xmm0, xmm2       // combine

    movups [r8], xmm0       // store result.lo
  end;

  // High 128-bits
  asm
    mov    rax, pMaskHi
    mov    rdx, pAHi
    mov    rcx, pBHi
    mov    r8,  pRHi

    movdqu xmm2, [rax]      // xmm2 = mask.hi
    movups xmm0, [rdx]      // xmm0 = a.hi
    movups xmm1, [rcx]      // xmm1 = b.hi

    pand   xmm0, xmm2       // xmm0 = a.hi AND mask.hi
    pandn  xmm2, xmm1       // xmm2 = (NOT mask.hi) AND b.hi
    por    xmm0, xmm2       // combine

    movups [r8], xmm0       // store result.hi
  end;
end;

// SelectF64x4: 使用 2×128-bit SSE2 操作
function SSE2SelectF64x4(const mask: TVecU64x4; const a, b: TVecF64x4): TVecF64x4;
var
  pMaskLo, pMaskHi, pALo, pAHi, pBLo, pBHi, pRLo, pRHi: Pointer;
begin
  pMaskLo := @mask.lo;
  pMaskHi := @mask.hi;
  pALo := @a.lo;
  pAHi := @a.hi;
  pBLo := @b.lo;
  pBHi := @b.hi;
  pRLo := @Result.lo;
  pRHi := @Result.hi;

  // Low 128-bits
  asm
    mov    rax, pMaskLo
    mov    rdx, pALo
    mov    rcx, pBLo
    mov    r8,  pRLo

    movdqu xmm2, [rax]      // xmm2 = mask.lo
    movupd xmm0, [rdx]      // xmm0 = a.lo
    movupd xmm1, [rcx]      // xmm1 = b.lo

    // 使用整数逻辑指令处理浮点数据
    pand   xmm0, xmm2       // xmm0 = a.lo AND mask.lo
    pandn  xmm2, xmm1       // xmm2 = (NOT mask.lo) AND b.lo
    por    xmm0, xmm2       // combine

    movupd [r8], xmm0       // store result.lo
  end;

  // High 128-bits
  asm
    mov    rax, pMaskHi
    mov    rdx, pAHi
    mov    rcx, pBHi
    mov    r8,  pRHi

    movdqu xmm2, [rax]      // xmm2 = mask.hi
    movupd xmm0, [rdx]      // xmm0 = a.hi
    movupd xmm1, [rcx]      // xmm1 = b.hi

    pand   xmm0, xmm2       // xmm0 = a.hi AND mask.hi
    pandn  xmm2, xmm1       // xmm2 = (NOT mask.hi) AND b.hi
    por    xmm0, xmm2       // combine

    movupd [r8], xmm0       // store result.hi
  end;
end;

// === I32x16 操作 (16×Int32) - 使用 2×I32x8 ===

// ✅ ITERATION-4.4: 4×128-bit SSE2 ASM 实现 (I32x16 Add)
function SSE2AddI32x16(const a, b: TVecI32x16): TVecI32x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov     rax, pa
    mov     rdx, pb
    mov     rcx, pr
    // Load 4×128-bit from a
    movdqu  xmm0, [rax]
    movdqu  xmm1, [rax+16]
    movdqu  xmm2, [rax+32]
    movdqu  xmm3, [rax+48]
    // Load 4×128-bit from b
    movdqu  xmm4, [rdx]
    movdqu  xmm5, [rdx+16]
    movdqu  xmm6, [rdx+32]
    movdqu  xmm7, [rdx+48]
    // Add (packed dword)
    paddd   xmm0, xmm4
    paddd   xmm1, xmm5
    paddd   xmm2, xmm6
    paddd   xmm3, xmm7
    // Store result
    movdqu  [rcx], xmm0
    movdqu  [rcx+16], xmm1
    movdqu  [rcx+32], xmm2
    movdqu  [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.4: 4×128-bit SSE2 ASM 实现 (I32x16 Sub)
function SSE2SubI32x16(const a, b: TVecI32x16): TVecI32x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov     rax, pa
    mov     rdx, pb
    mov     rcx, pr
    movdqu  xmm0, [rax]
    movdqu  xmm1, [rax+16]
    movdqu  xmm2, [rax+32]
    movdqu  xmm3, [rax+48]
    movdqu  xmm4, [rdx]
    movdqu  xmm5, [rdx+16]
    movdqu  xmm6, [rdx+32]
    movdqu  xmm7, [rdx+48]
    // Subtract (packed dword)
    psubd   xmm0, xmm4
    psubd   xmm1, xmm5
    psubd   xmm2, xmm6
    psubd   xmm3, xmm7
    movdqu  [rcx], xmm0
    movdqu  [rcx+16], xmm1
    movdqu  [rcx+32], xmm2
    movdqu  [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.4: 4×128-bit SSE2 ASM 实现 (I32x16 Mul - 使用标量回退，因为 SSE2 无 pmulld)
function SSE2MulI32x16(const a, b: TVecI32x16): TVecI32x16;
var
  i: Integer;
begin
  // SSE2 没有 32-bit 整数乘法，使用标量循环
  for i := 0 to 15 do
    Result.i[i] := a.i[i] * b.i[i];
end;

// ✅ ITERATION-4.4: 4×128-bit SSE2 ASM 实现 (I32x16 And)
function SSE2AndI32x16(const a, b: TVecI32x16): TVecI32x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov     rax, pa
    mov     rdx, pb
    mov     rcx, pr
    movdqu  xmm0, [rax]
    movdqu  xmm1, [rax+16]
    movdqu  xmm2, [rax+32]
    movdqu  xmm3, [rax+48]
    movdqu  xmm4, [rdx]
    movdqu  xmm5, [rdx+16]
    movdqu  xmm6, [rdx+32]
    movdqu  xmm7, [rdx+48]
    // Bitwise AND
    pand    xmm0, xmm4
    pand    xmm1, xmm5
    pand    xmm2, xmm6
    pand    xmm3, xmm7
    movdqu  [rcx], xmm0
    movdqu  [rcx+16], xmm1
    movdqu  [rcx+32], xmm2
    movdqu  [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.4: 4×128-bit SSE2 ASM 实现 (I32x16 Or)
function SSE2OrI32x16(const a, b: TVecI32x16): TVecI32x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov     rax, pa
    mov     rdx, pb
    mov     rcx, pr
    movdqu  xmm0, [rax]
    movdqu  xmm1, [rax+16]
    movdqu  xmm2, [rax+32]
    movdqu  xmm3, [rax+48]
    movdqu  xmm4, [rdx]
    movdqu  xmm5, [rdx+16]
    movdqu  xmm6, [rdx+32]
    movdqu  xmm7, [rdx+48]
    // Bitwise OR
    por     xmm0, xmm4
    por     xmm1, xmm5
    por     xmm2, xmm6
    por     xmm3, xmm7
    movdqu  [rcx], xmm0
    movdqu  [rcx+16], xmm1
    movdqu  [rcx+32], xmm2
    movdqu  [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.4: 4×128-bit SSE2 ASM 实现 (I32x16 Xor)
function SSE2XorI32x16(const a, b: TVecI32x16): TVecI32x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov     rax, pa
    mov     rdx, pb
    mov     rcx, pr
    movdqu  xmm0, [rax]
    movdqu  xmm1, [rax+16]
    movdqu  xmm2, [rax+32]
    movdqu  xmm3, [rax+48]
    movdqu  xmm4, [rdx]
    movdqu  xmm5, [rdx+16]
    movdqu  xmm6, [rdx+32]
    movdqu  xmm7, [rdx+48]
    // Bitwise XOR
    pxor    xmm0, xmm4
    pxor    xmm1, xmm5
    pxor    xmm2, xmm6
    pxor    xmm3, xmm7
    movdqu  [rcx], xmm0
    movdqu  [rcx+16], xmm1
    movdqu  [rcx+32], xmm2
    movdqu  [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.4: 4×128-bit SSE2 ASM 实现 (I32x16 Not)
function SSE2NotI32x16(const a: TVecI32x16): TVecI32x16;
var
  pa, pr: Pointer;
const
  AllOnes: array[0..15] of UInt32 = (
    $FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF,
    $FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF,
    $FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF,
    $FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF
  );
begin
  pa := @a;
  pr := @Result;
  asm
    mov     rax, pa
    mov     rcx, pr
    lea     rdx, [rip + AllOnes]
    // Load 4×128-bit from a
    movdqu  xmm0, [rax]
    movdqu  xmm1, [rax+16]
    movdqu  xmm2, [rax+32]
    movdqu  xmm3, [rax+48]
    // Load 4×128-bit all-ones
    movdqu  xmm4, [rdx]
    movdqu  xmm5, [rdx+16]
    movdqu  xmm6, [rdx+32]
    movdqu  xmm7, [rdx+48]
    // XOR with all-ones = NOT
    pxor    xmm0, xmm4
    pxor    xmm1, xmm5
    pxor    xmm2, xmm6
    pxor    xmm3, xmm7
    movdqu  [rcx], xmm0
    movdqu  [rcx+16], xmm1
    movdqu  [rcx+32], xmm2
    movdqu  [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.4: 4×128-bit SSE2 ASM 实现 (I32x16 AndNot)
function SSE2AndNotI32x16(const a, b: TVecI32x16): TVecI32x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // PANDN: dest = (NOT a) AND b
  asm
    mov     rax, pa
    mov     rdx, pb
    mov     rcx, pr
    movdqu  xmm0, [rax]
    movdqu  xmm1, [rax+16]
    movdqu  xmm2, [rax+32]
    movdqu  xmm3, [rax+48]
    movdqu  xmm4, [rdx]
    movdqu  xmm5, [rdx+16]
    movdqu  xmm6, [rdx+32]
    movdqu  xmm7, [rdx+48]
    // AndNot: (NOT a) AND b
    pandn   xmm0, xmm4
    pandn   xmm1, xmm5
    pandn   xmm2, xmm6
    pandn   xmm3, xmm7
    movdqu  [rcx], xmm0
    movdqu  [rcx+16], xmm1
    movdqu  [rcx+32], xmm2
    movdqu  [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.4: 4×128-bit SSE2 ASM 实现 (I32x16 ShiftLeft)
function SSE2ShiftLeftI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov     rax, pa
    mov     rcx, pr
    mov     edx, count
    movd    xmm7, edx       // Load shift count
    // Load 4×128-bit from a
    movdqu  xmm0, [rax]
    movdqu  xmm1, [rax+16]
    movdqu  xmm2, [rax+32]
    movdqu  xmm3, [rax+48]
    // Shift left
    pslld   xmm0, xmm7
    pslld   xmm1, xmm7
    pslld   xmm2, xmm7
    pslld   xmm3, xmm7
    // Store result
    movdqu  [rcx], xmm0
    movdqu  [rcx+16], xmm1
    movdqu  [rcx+32], xmm2
    movdqu  [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.4: 4×128-bit SSE2 ASM 实现 (I32x16 ShiftRight - logical)
function SSE2ShiftRightI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  // Logical right shift (unsigned)
  asm
    mov     rax, pa
    mov     rcx, pr
    mov     edx, count
    movd    xmm7, edx       // Load shift count
    movdqu  xmm0, [rax]
    movdqu  xmm1, [rax+16]
    movdqu  xmm2, [rax+32]
    movdqu  xmm3, [rax+48]
    // Logical shift right
    psrld   xmm0, xmm7
    psrld   xmm1, xmm7
    psrld   xmm2, xmm7
    psrld   xmm3, xmm7
    movdqu  [rcx], xmm0
    movdqu  [rcx+16], xmm1
    movdqu  [rcx+32], xmm2
    movdqu  [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.4: 4×128-bit SSE2 ASM 实现 (I32x16 ShiftRightArith - arithmetic)
function SSE2ShiftRightArithI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  // Arithmetic right shift (signed, preserves sign bit)
  asm
    mov     rax, pa
    mov     rcx, pr
    mov     edx, count
    movd    xmm7, edx       // Load shift count
    movdqu  xmm0, [rax]
    movdqu  xmm1, [rax+16]
    movdqu  xmm2, [rax+32]
    movdqu  xmm3, [rax+48]
    // Arithmetic shift right
    psrad   xmm0, xmm7
    psrad   xmm1, xmm7
    psrad   xmm2, xmm7
    psrad   xmm3, xmm7
    movdqu  [rcx], xmm0
    movdqu  [rcx+16], xmm1
    movdqu  [rcx+32], xmm2
    movdqu  [rcx+48], xmm3
  end;
end;

function SSE2CmpEqI32x16(const a, b: TVecI32x16): TMask16;
begin
  Result := (SSE2CmpEqI32x8(a.lo, b.lo) and $FF) or ((SSE2CmpEqI32x8(a.hi, b.hi) and $FF) shl 8);
end;

function SSE2CmpLtI32x16(const a, b: TVecI32x16): TMask16;
begin
  Result := (SSE2CmpLtI32x8(a.lo, b.lo) and $FF) or ((SSE2CmpLtI32x8(a.hi, b.hi) and $FF) shl 8);
end;

function SSE2CmpGtI32x16(const a, b: TVecI32x16): TMask16;
begin
  Result := (SSE2CmpGtI32x8(a.lo, b.lo) and $FF) or ((SSE2CmpGtI32x8(a.hi, b.hi) and $FF) shl 8);
end;

function SSE2CmpLeI32x16(const a, b: TVecI32x16): TMask16;
begin
  Result := (SSE2CmpLeI32x8(a.lo, b.lo) and $FF) or ((SSE2CmpLeI32x8(a.hi, b.hi) and $FF) shl 8);
end;

function SSE2CmpGeI32x16(const a, b: TVecI32x16): TMask16;
begin
  Result := (SSE2CmpGeI32x8(a.lo, b.lo) and $FF) or ((SSE2CmpGeI32x8(a.hi, b.hi) and $FF) shl 8);
end;

function SSE2CmpNeI32x16(const a, b: TVecI32x16): TMask16;
begin
  Result := (SSE2CmpNeI32x8(a.lo, b.lo) and $FF) or ((SSE2CmpNeI32x8(a.hi, b.hi) and $FF) shl 8);
end;

// ✅ ITERATION-4.4: 4×128-bit SSE2 ASM 实现 (I32x16 Min - emulated)
function SSE2MinI32x16(const a, b: TVecI32x16): TVecI32x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // min(a,b) = (a < b) ? a : b = blend(b, a, a < b)
  asm
    mov     rax, pa
    mov     rdx, pb
    mov     rcx, pr

    // Process first 128-bit chunk
    movdqu  xmm0, [rax]         // a0
    movdqu  xmm4, [rdx]         // b0
    movdqa  xmm8, xmm4          // copy b0
    pcmpgtd xmm8, xmm0          // b0 > a0 (i.e., a0 < b0)
    movdqa  xmm9, xmm0          // copy a0
    pand    xmm9, xmm8          // a0 & mask
    pandn   xmm8, xmm4          // b0 & ~mask
    por     xmm9, xmm8          // combine
    movdqu  [rcx], xmm9

    // Process second 128-bit chunk
    movdqu  xmm1, [rax+16]
    movdqu  xmm5, [rdx+16]
    movdqa  xmm8, xmm5
    pcmpgtd xmm8, xmm1
    movdqa  xmm9, xmm1
    pand    xmm9, xmm8
    pandn   xmm8, xmm5
    por     xmm9, xmm8
    movdqu  [rcx+16], xmm9

    // Process third 128-bit chunk
    movdqu  xmm2, [rax+32]
    movdqu  xmm6, [rdx+32]
    movdqa  xmm8, xmm6
    pcmpgtd xmm8, xmm2
    movdqa  xmm9, xmm2
    pand    xmm9, xmm8
    pandn   xmm8, xmm6
    por     xmm9, xmm8
    movdqu  [rcx+32], xmm9

    // Process fourth 128-bit chunk
    movdqu  xmm3, [rax+48]
    movdqu  xmm7, [rdx+48]
    movdqa  xmm8, xmm7
    pcmpgtd xmm8, xmm3
    movdqa  xmm9, xmm3
    pand    xmm9, xmm8
    pandn   xmm8, xmm7
    por     xmm9, xmm8
    movdqu  [rcx+48], xmm9
  end;
end;

// ✅ ITERATION-4.4: 4×128-bit SSE2 ASM 实现 (I32x16 Max - emulated)
function SSE2MaxI32x16(const a, b: TVecI32x16): TVecI32x16;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  // max(a,b) = (a > b) ? a : b = blend(b, a, a > b)
  asm
    mov     rax, pa
    mov     rdx, pb
    mov     rcx, pr

    // Process first 128-bit chunk
    movdqu  xmm0, [rax]         // a0
    movdqu  xmm4, [rdx]         // b0
    movdqa  xmm8, xmm0          // copy a0
    pcmpgtd xmm8, xmm4          // a0 > b0
    movdqa  xmm9, xmm0          // copy a0
    pand    xmm9, xmm8          // a0 & mask
    pandn   xmm8, xmm4          // b0 & ~mask
    por     xmm9, xmm8          // combine
    movdqu  [rcx], xmm9

    // Process second 128-bit chunk
    movdqu  xmm1, [rax+16]
    movdqu  xmm5, [rdx+16]
    movdqa  xmm8, xmm1
    pcmpgtd xmm8, xmm5
    movdqa  xmm9, xmm1
    pand    xmm9, xmm8
    pandn   xmm8, xmm5
    por     xmm9, xmm8
    movdqu  [rcx+16], xmm9

    // Process third 128-bit chunk
    movdqu  xmm2, [rax+32]
    movdqu  xmm6, [rdx+32]
    movdqa  xmm8, xmm2
    pcmpgtd xmm8, xmm6
    movdqa  xmm9, xmm2
    pand    xmm9, xmm8
    pandn   xmm8, xmm6
    por     xmm9, xmm8
    movdqu  [rcx+32], xmm9

    // Process fourth 128-bit chunk
    movdqu  xmm3, [rax+48]
    movdqu  xmm7, [rdx+48]
    movdqa  xmm8, xmm3
    pcmpgtd xmm8, xmm7
    movdqa  xmm9, xmm3
    pand    xmm9, xmm8
    pandn   xmm8, xmm7
    por     xmm9, xmm8
    movdqu  [rcx+48], xmm9
  end;
end;

// ============================================================================
// ✅ NEW: I64x4 操作实现 (256-bit，使用 2×I64x2 仿真)
// ============================================================================

function SSE2AddI64x4(const a, b: TVecI64x4): TVecI64x4;
begin
  Result.lo := SSE2AddI64x2(a.lo, b.lo);
  Result.hi := SSE2AddI64x2(a.hi, b.hi);
end;

function SSE2SubI64x4(const a, b: TVecI64x4): TVecI64x4;
begin
  Result.lo := SSE2SubI64x2(a.lo, b.lo);
  Result.hi := SSE2SubI64x2(a.hi, b.hi);
end;

function SSE2AndI64x4(const a, b: TVecI64x4): TVecI64x4;
begin
  Result.lo := SSE2AndI64x2(a.lo, b.lo);
  Result.hi := SSE2AndI64x2(a.hi, b.hi);
end;

function SSE2OrI64x4(const a, b: TVecI64x4): TVecI64x4;
begin
  Result.lo := SSE2OrI64x2(a.lo, b.lo);
  Result.hi := SSE2OrI64x2(a.hi, b.hi);
end;

function SSE2XorI64x4(const a, b: TVecI64x4): TVecI64x4;
begin
  Result.lo := SSE2XorI64x2(a.lo, b.lo);
  Result.hi := SSE2XorI64x2(a.hi, b.hi);
end;

function SSE2NotI64x4(const a: TVecI64x4): TVecI64x4;
begin
  Result.lo := SSE2NotI64x2(a.lo);
  Result.hi := SSE2NotI64x2(a.hi);
end;

function SSE2AndNotI64x4(const a, b: TVecI64x4): TVecI64x4;
begin
  // AndNot = (NOT a) AND b
  Result.lo.i[0] := (not a.lo.i[0]) and b.lo.i[0];
  Result.lo.i[1] := (not a.lo.i[1]) and b.lo.i[1];
  Result.hi.i[0] := (not a.hi.i[0]) and b.hi.i[0];
  Result.hi.i[1] := (not a.hi.i[1]) and b.hi.i[1];
end;

function SSE2ShiftLeftI64x4(const a: TVecI64x4; count: Integer): TVecI64x4;
{$IFDEF CPUX64}
var pa, pr: Pointer;
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movdqu xmm1, [rax+16]
    movd   xmm2, edx
    psllq  xmm0, xmm2      // 64-bit 逻辑左移
    psllq  xmm1, xmm2
    movdqu [rcx], xmm0
    movdqu [rcx+16], xmm1
  end;
{$ELSE}
begin
  if count >= 64 then
  begin
    Result.i[0] := 0;
    Result.i[1] := 0;
    Result.i[2] := 0;
    Result.i[3] := 0;
  end
  else if count > 0 then
  begin
    Result.i[0] := a.i[0] shl count;
    Result.i[1] := a.i[1] shl count;
    Result.i[2] := a.i[2] shl count;
    Result.i[3] := a.i[3] shl count;
  end
  else
    Result := a;
{$ENDIF}
end;

function SSE2ShiftRightI64x4(const a: TVecI64x4; count: Integer): TVecI64x4;
{$IFDEF CPUX64}
var pa, pr: Pointer;
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    mov    edx, count
    movdqu xmm0, [rax]
    movdqu xmm1, [rax+16]
    movd   xmm2, edx
    psrlq  xmm0, xmm2      // 64-bit 逻辑右移
    psrlq  xmm1, xmm2
    movdqu [rcx], xmm0
    movdqu [rcx+16], xmm1
  end;
{$ELSE}
begin
  // Logical shift right (unsigned semantics)
  if count >= 64 then
  begin
    Result.i[0] := 0;
    Result.i[1] := 0;
    Result.i[2] := 0;
    Result.i[3] := 0;
  end
  else if count > 0 then
  begin
    Result.i[0] := Int64(UInt64(a.i[0]) shr count);
    Result.i[1] := Int64(UInt64(a.i[1]) shr count);
    Result.i[2] := Int64(UInt64(a.i[2]) shr count);
    Result.i[3] := Int64(UInt64(a.i[3]) shr count);
  end
  else
    Result := a;
{$ENDIF}
end;

function SSE2CmpEqI64x4(const a, b: TVecI64x4): TMask4;
var
  mLo, mHi: TMask2;
begin
  mLo := SSE2CmpEqI64x2(a.lo, b.lo);
  mHi := SSE2CmpEqI64x2(a.hi, b.hi);
  Result := (mLo and $3) or ((mHi and $3) shl 2);
end;

function SSE2CmpLtI64x4(const a, b: TVecI64x4): TMask4;
var
  mLo, mHi: TMask2;
begin
  mLo := SSE2CmpLtI64x2(a.lo, b.lo);
  mHi := SSE2CmpLtI64x2(a.hi, b.hi);
  Result := (mLo and $3) or ((mHi and $3) shl 2);
end;

function SSE2CmpGtI64x4(const a, b: TVecI64x4): TMask4;
var
  mLo, mHi: TMask2;
begin
  mLo := SSE2CmpGtI64x2(a.lo, b.lo);
  mHi := SSE2CmpGtI64x2(a.hi, b.hi);
  Result := (mLo and $3) or ((mHi and $3) shl 2);
end;

function SSE2CmpLeI64x4(const a, b: TVecI64x4): TMask4;
var
  mLo, mHi: TMask2;
begin
  mLo := SSE2CmpLeI64x2(a.lo, b.lo);
  mHi := SSE2CmpLeI64x2(a.hi, b.hi);
  Result := (mLo and $3) or ((mHi and $3) shl 2);
end;

function SSE2CmpGeI64x4(const a, b: TVecI64x4): TMask4;
var
  mLo, mHi: TMask2;
begin
  mLo := SSE2CmpGeI64x2(a.lo, b.lo);
  mHi := SSE2CmpGeI64x2(a.hi, b.hi);
  Result := (mLo and $3) or ((mHi and $3) shl 2);
end;

function SSE2CmpNeI64x4(const a, b: TVecI64x4): TMask4;
var
  mLo, mHi: TMask2;
begin
  mLo := SSE2CmpNeI64x2(a.lo, b.lo);
  mHi := SSE2CmpNeI64x2(a.hi, b.hi);
  Result := (mLo and $3) or ((mHi and $3) shl 2);
end;

function SSE2LoadI64x4(p: PInt64): TVecI64x4;
begin
  Result.i[0] := p[0];
  Result.i[1] := p[1];
  Result.i[2] := p[2];
  Result.i[3] := p[3];
end;

procedure SSE2StoreI64x4(p: PInt64; const a: TVecI64x4);
begin
  p[0] := a.i[0];
  p[1] := a.i[1];
  p[2] := a.i[2];
  p[3] := a.i[3];
end;

function SSE2SplatI64x4(value: Int64): TVecI64x4;
begin
  Result.i[0] := value;
  Result.i[1] := value;
  Result.i[2] := value;
  Result.i[3] := value;
end;

function SSE2ZeroI64x4: TVecI64x4;
begin
  Result.i[0] := 0;
  Result.i[1] := 0;
  Result.i[2] := 0;
  Result.i[3] := 0;
end;

// ============================================================================
// ✅ NEW: U32x8 操作实现 (256-bit，使用 2×U32x4 仿真)
// ============================================================================

function SSE2AddU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result.lo := SSE2AddU32x4(a.lo, b.lo);
  Result.hi := SSE2AddU32x4(a.hi, b.hi);
end;

function SSE2SubU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result.lo := SSE2SubU32x4(a.lo, b.lo);
  Result.hi := SSE2SubU32x4(a.hi, b.hi);
end;

function SSE2MulU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result.lo := SSE2MulU32x4(a.lo, b.lo);
  Result.hi := SSE2MulU32x4(a.hi, b.hi);
end;

function SSE2AndU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result.lo := SSE2AndU32x4(a.lo, b.lo);
  Result.hi := SSE2AndU32x4(a.hi, b.hi);
end;

function SSE2OrU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result.lo := SSE2OrU32x4(a.lo, b.lo);
  Result.hi := SSE2OrU32x4(a.hi, b.hi);
end;

function SSE2XorU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result.lo := SSE2XorU32x4(a.lo, b.lo);
  Result.hi := SSE2XorU32x4(a.hi, b.hi);
end;

function SSE2NotU32x8(const a: TVecU32x8): TVecU32x8;
begin
  Result.lo := SSE2NotU32x4(a.lo);
  Result.hi := SSE2NotU32x4(a.hi);
end;

function SSE2AndNotU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result.lo := SSE2AndNotU32x4(a.lo, b.lo);
  Result.hi := SSE2AndNotU32x4(a.hi, b.hi);
end;

function SSE2ShiftLeftU32x8(const a: TVecU32x8; count: Integer): TVecU32x8;
begin
  Result.lo := SSE2ShiftLeftU32x4(a.lo, count);
  Result.hi := SSE2ShiftLeftU32x4(a.hi, count);
end;

function SSE2ShiftRightU32x8(const a: TVecU32x8; count: Integer): TVecU32x8;
begin
  Result.lo := SSE2ShiftRightU32x4(a.lo, count);
  Result.hi := SSE2ShiftRightU32x4(a.hi, count);
end;

function SSE2CmpEqU32x8(const a, b: TVecU32x8): TMask8;
var
  mLo, mHi: TMask4;
begin
  mLo := SSE2CmpEqU32x4(a.lo, b.lo);
  mHi := SSE2CmpEqU32x4(a.hi, b.hi);
  Result := (mLo and $F) or ((mHi and $F) shl 4);
end;

function SSE2CmpLtU32x8(const a, b: TVecU32x8): TMask8;
var
  mLo, mHi: TMask4;
begin
  mLo := SSE2CmpLtU32x4(a.lo, b.lo);
  mHi := SSE2CmpLtU32x4(a.hi, b.hi);
  Result := (mLo and $F) or ((mHi and $F) shl 4);
end;

function SSE2CmpGtU32x8(const a, b: TVecU32x8): TMask8;
var
  mLo, mHi: TMask4;
begin
  mLo := SSE2CmpGtU32x4(a.lo, b.lo);
  mHi := SSE2CmpGtU32x4(a.hi, b.hi);
  Result := (mLo and $F) or ((mHi and $F) shl 4);
end;

function SSE2CmpLeU32x8(const a, b: TVecU32x8): TMask8;
var
  mLo, mHi: TMask4;
begin
  mLo := SSE2CmpLeU32x4(a.lo, b.lo);
  mHi := SSE2CmpLeU32x4(a.hi, b.hi);
  Result := (mLo and $F) or ((mHi and $F) shl 4);
end;

function SSE2CmpGeU32x8(const a, b: TVecU32x8): TMask8;
var
  mLo, mHi: TMask4;
begin
  mLo := SSE2CmpGeU32x4(a.lo, b.lo);
  mHi := SSE2CmpGeU32x4(a.hi, b.hi);
  Result := (mLo and $F) or ((mHi and $F) shl 4);
end;

function SSE2CmpNeU32x8(const a, b: TVecU32x8): TMask8;
var
  mLo, mHi: TMask4;
begin
  mLo := SSE2CmpNeU32x4(a.lo, b.lo);
  mHi := SSE2CmpNeU32x4(a.hi, b.hi);
  Result := (mLo and $F) or ((mHi and $F) shl 4);
end;

function SSE2MinU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result.lo := SSE2MinU32x4(a.lo, b.lo);
  Result.hi := SSE2MinU32x4(a.hi, b.hi);
end;

function SSE2MaxU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result.lo := SSE2MaxU32x4(a.lo, b.lo);
  Result.hi := SSE2MaxU32x4(a.hi, b.hi);
end;

function SSE2SplatU32x8(value: UInt32): TVecU32x8;
begin
  Result.u[0] := value;
  Result.u[1] := value;
  Result.u[2] := value;
  Result.u[3] := value;
  Result.u[4] := value;
  Result.u[5] := value;
  Result.u[6] := value;
  Result.u[7] := value;
end;

// ============================================================================
// ✅ NEW: U64x4 操作实现 (256-bit，使用 2×U64x2 仿真)
// ============================================================================

function SSE2AddU64x4(const a, b: TVecU64x4): TVecU64x4;
begin
  // U64 加法与 I64 相同（位级操作）
  Result.u[0] := a.u[0] + b.u[0];
  Result.u[1] := a.u[1] + b.u[1];
  Result.u[2] := a.u[2] + b.u[2];
  Result.u[3] := a.u[3] + b.u[3];
end;

function SSE2SubU64x4(const a, b: TVecU64x4): TVecU64x4;
begin
  Result.u[0] := a.u[0] - b.u[0];
  Result.u[1] := a.u[1] - b.u[1];
  Result.u[2] := a.u[2] - b.u[2];
  Result.u[3] := a.u[3] - b.u[3];
end;

function SSE2AndU64x4(const a, b: TVecU64x4): TVecU64x4;
begin
  Result.u[0] := a.u[0] and b.u[0];
  Result.u[1] := a.u[1] and b.u[1];
  Result.u[2] := a.u[2] and b.u[2];
  Result.u[3] := a.u[3] and b.u[3];
end;

function SSE2OrU64x4(const a, b: TVecU64x4): TVecU64x4;
begin
  Result.u[0] := a.u[0] or b.u[0];
  Result.u[1] := a.u[1] or b.u[1];
  Result.u[2] := a.u[2] or b.u[2];
  Result.u[3] := a.u[3] or b.u[3];
end;

function SSE2XorU64x4(const a, b: TVecU64x4): TVecU64x4;
begin
  Result.u[0] := a.u[0] xor b.u[0];
  Result.u[1] := a.u[1] xor b.u[1];
  Result.u[2] := a.u[2] xor b.u[2];
  Result.u[3] := a.u[3] xor b.u[3];
end;

function SSE2NotU64x4(const a: TVecU64x4): TVecU64x4;
begin
  Result.u[0] := not a.u[0];
  Result.u[1] := not a.u[1];
  Result.u[2] := not a.u[2];
  Result.u[3] := not a.u[3];
end;

function SSE2ShiftLeftU64x4(const a: TVecU64x4; count: Integer): TVecU64x4;
begin
  if count >= 64 then
  begin
    Result.u[0] := 0;
    Result.u[1] := 0;
    Result.u[2] := 0;
    Result.u[3] := 0;
  end
  else if count > 0 then
  begin
    Result.u[0] := a.u[0] shl count;
    Result.u[1] := a.u[1] shl count;
    Result.u[2] := a.u[2] shl count;
    Result.u[3] := a.u[3] shl count;
  end
  else
    Result := a;
end;

function SSE2ShiftRightU64x4(const a: TVecU64x4; count: Integer): TVecU64x4;
begin
  if count >= 64 then
  begin
    Result.u[0] := 0;
    Result.u[1] := 0;
    Result.u[2] := 0;
    Result.u[3] := 0;
  end
  else if count > 0 then
  begin
    Result.u[0] := a.u[0] shr count;
    Result.u[1] := a.u[1] shr count;
    Result.u[2] := a.u[2] shr count;
    Result.u[3] := a.u[3] shr count;
  end
  else
    Result := a;
end;

function SSE2CmpEqU64x4(const a, b: TVecU64x4): TMask4;
begin
  Result := 0;
  if a.u[0] = b.u[0] then Result := Result or 1;
  if a.u[1] = b.u[1] then Result := Result or 2;
  if a.u[2] = b.u[2] then Result := Result or 4;
  if a.u[3] = b.u[3] then Result := Result or 8;
end;

function SSE2CmpLtU64x4(const a, b: TVecU64x4): TMask4;
begin
  Result := 0;
  if a.u[0] < b.u[0] then Result := Result or 1;
  if a.u[1] < b.u[1] then Result := Result or 2;
  if a.u[2] < b.u[2] then Result := Result or 4;
  if a.u[3] < b.u[3] then Result := Result or 8;
end;

function SSE2CmpGtU64x4(const a, b: TVecU64x4): TMask4;
begin
  Result := 0;
  if a.u[0] > b.u[0] then Result := Result or 1;
  if a.u[1] > b.u[1] then Result := Result or 2;
  if a.u[2] > b.u[2] then Result := Result or 4;
  if a.u[3] > b.u[3] then Result := Result or 8;
end;

function SSE2CmpLeU64x4(const a, b: TVecU64x4): TMask4;
begin
  Result := 0;
  if a.u[0] <= b.u[0] then Result := Result or 1;
  if a.u[1] <= b.u[1] then Result := Result or 2;
  if a.u[2] <= b.u[2] then Result := Result or 4;
  if a.u[3] <= b.u[3] then Result := Result or 8;
end;

function SSE2CmpGeU64x4(const a, b: TVecU64x4): TMask4;
begin
  Result := 0;
  if a.u[0] >= b.u[0] then Result := Result or 1;
  if a.u[1] >= b.u[1] then Result := Result or 2;
  if a.u[2] >= b.u[2] then Result := Result or 4;
  if a.u[3] >= b.u[3] then Result := Result or 8;
end;

function SSE2CmpNeU64x4(const a, b: TVecU64x4): TMask4;
begin
  Result := 0;
  if a.u[0] <> b.u[0] then Result := Result or 1;
  if a.u[1] <> b.u[1] then Result := Result or 2;
  if a.u[2] <> b.u[2] then Result := Result or 4;
  if a.u[3] <> b.u[3] then Result := Result or 8;
end;

// ============================================================================
// ✅ NEW: I64x8 操作实现 (512-bit，使用 2×I64x4 仿真)
// ============================================================================

// ✅ ITERATION-4.4: 4×128-bit SSE2 ASM 实现 (I64x8 Add)
function SSE2AddI64x8(const a, b: TVecI64x8): TVecI64x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov     rax, pa
    mov     rdx, pb
    mov     rcx, pr
    // Load 4×128-bit from a (each holds 2 qwords)
    movdqu  xmm0, [rax]
    movdqu  xmm1, [rax+16]
    movdqu  xmm2, [rax+32]
    movdqu  xmm3, [rax+48]
    // Load 4×128-bit from b
    movdqu  xmm4, [rdx]
    movdqu  xmm5, [rdx+16]
    movdqu  xmm6, [rdx+32]
    movdqu  xmm7, [rdx+48]
    // Add (packed qword)
    paddq   xmm0, xmm4
    paddq   xmm1, xmm5
    paddq   xmm2, xmm6
    paddq   xmm3, xmm7
    // Store result
    movdqu  [rcx], xmm0
    movdqu  [rcx+16], xmm1
    movdqu  [rcx+32], xmm2
    movdqu  [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.4: 4×128-bit SSE2 ASM 实现 (I64x8 Sub)
function SSE2SubI64x8(const a, b: TVecI64x8): TVecI64x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov     rax, pa
    mov     rdx, pb
    mov     rcx, pr
    movdqu  xmm0, [rax]
    movdqu  xmm1, [rax+16]
    movdqu  xmm2, [rax+32]
    movdqu  xmm3, [rax+48]
    movdqu  xmm4, [rdx]
    movdqu  xmm5, [rdx+16]
    movdqu  xmm6, [rdx+32]
    movdqu  xmm7, [rdx+48]
    // Subtract (packed qword)
    psubq   xmm0, xmm4
    psubq   xmm1, xmm5
    psubq   xmm2, xmm6
    psubq   xmm3, xmm7
    movdqu  [rcx], xmm0
    movdqu  [rcx+16], xmm1
    movdqu  [rcx+32], xmm2
    movdqu  [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.4: 4×128-bit SSE2 ASM 实现 (I64x8 And)
function SSE2AndI64x8(const a, b: TVecI64x8): TVecI64x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov     rax, pa
    mov     rdx, pb
    mov     rcx, pr
    movdqu  xmm0, [rax]
    movdqu  xmm1, [rax+16]
    movdqu  xmm2, [rax+32]
    movdqu  xmm3, [rax+48]
    movdqu  xmm4, [rdx]
    movdqu  xmm5, [rdx+16]
    movdqu  xmm6, [rdx+32]
    movdqu  xmm7, [rdx+48]
    // Bitwise AND
    pand    xmm0, xmm4
    pand    xmm1, xmm5
    pand    xmm2, xmm6
    pand    xmm3, xmm7
    movdqu  [rcx], xmm0
    movdqu  [rcx+16], xmm1
    movdqu  [rcx+32], xmm2
    movdqu  [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.4: 4×128-bit SSE2 ASM 实现 (I64x8 Or)
function SSE2OrI64x8(const a, b: TVecI64x8): TVecI64x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov     rax, pa
    mov     rdx, pb
    mov     rcx, pr
    movdqu  xmm0, [rax]
    movdqu  xmm1, [rax+16]
    movdqu  xmm2, [rax+32]
    movdqu  xmm3, [rax+48]
    movdqu  xmm4, [rdx]
    movdqu  xmm5, [rdx+16]
    movdqu  xmm6, [rdx+32]
    movdqu  xmm7, [rdx+48]
    // Bitwise OR
    por     xmm0, xmm4
    por     xmm1, xmm5
    por     xmm2, xmm6
    por     xmm3, xmm7
    movdqu  [rcx], xmm0
    movdqu  [rcx+16], xmm1
    movdqu  [rcx+32], xmm2
    movdqu  [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.4: 4×128-bit SSE2 ASM 实现 (I64x8 Xor)
function SSE2XorI64x8(const a, b: TVecI64x8): TVecI64x8;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov     rax, pa
    mov     rdx, pb
    mov     rcx, pr
    movdqu  xmm0, [rax]
    movdqu  xmm1, [rax+16]
    movdqu  xmm2, [rax+32]
    movdqu  xmm3, [rax+48]
    movdqu  xmm4, [rdx]
    movdqu  xmm5, [rdx+16]
    movdqu  xmm6, [rdx+32]
    movdqu  xmm7, [rdx+48]
    // Bitwise XOR
    pxor    xmm0, xmm4
    pxor    xmm1, xmm5
    pxor    xmm2, xmm6
    pxor    xmm3, xmm7
    movdqu  [rcx], xmm0
    movdqu  [rcx+16], xmm1
    movdqu  [rcx+32], xmm2
    movdqu  [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.4: 4×128-bit SSE2 ASM 实现 (I64x8 Not)
function SSE2NotI64x8(const a: TVecI64x8): TVecI64x8;
var
  pa, pr: Pointer;
const
  AllOnes: array[0..7] of UInt64 = (
    UInt64($FFFFFFFFFFFFFFFF), UInt64($FFFFFFFFFFFFFFFF),
    UInt64($FFFFFFFFFFFFFFFF), UInt64($FFFFFFFFFFFFFFFF),
    UInt64($FFFFFFFFFFFFFFFF), UInt64($FFFFFFFFFFFFFFFF),
    UInt64($FFFFFFFFFFFFFFFF), UInt64($FFFFFFFFFFFFFFFF)
  );
begin
  pa := @a;
  pr := @Result;
  asm
    mov     rax, pa
    mov     rcx, pr
    lea     rdx, [rip + AllOnes]
    // Load 4×128-bit from a
    movdqu  xmm0, [rax]
    movdqu  xmm1, [rax+16]
    movdqu  xmm2, [rax+32]
    movdqu  xmm3, [rax+48]
    // Load 4×128-bit all-ones
    movdqu  xmm4, [rdx]
    movdqu  xmm5, [rdx+16]
    movdqu  xmm6, [rdx+32]
    movdqu  xmm7, [rdx+48]
    // XOR with all-ones = NOT
    pxor    xmm0, xmm4
    pxor    xmm1, xmm5
    pxor    xmm2, xmm6
    pxor    xmm3, xmm7
    movdqu  [rcx], xmm0
    movdqu  [rcx+16], xmm1
    movdqu  [rcx+32], xmm2
    movdqu  [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.4: 4×128-bit SSE2 ASM 实现 (I64x8 ShiftLeft)
function SSE2ShiftLeftI64x8(const a: TVecI64x8; count: Integer): TVecI64x8;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov     rax, pa
    mov     rcx, pr
    mov     edx, count
    movd    xmm7, edx       // Load shift count
    // Load 4×128-bit from a (each holds 2 qwords)
    movdqu  xmm0, [rax]
    movdqu  xmm1, [rax+16]
    movdqu  xmm2, [rax+32]
    movdqu  xmm3, [rax+48]
    // Shift left
    psllq   xmm0, xmm7
    psllq   xmm1, xmm7
    psllq   xmm2, xmm7
    psllq   xmm3, xmm7
    // Store result
    movdqu  [rcx], xmm0
    movdqu  [rcx+16], xmm1
    movdqu  [rcx+32], xmm2
    movdqu  [rcx+48], xmm3
  end;
end;

// ✅ ITERATION-4.4: 4×128-bit SSE2 ASM 实现 (I64x8 ShiftRight - logical)
function SSE2ShiftRightI64x8(const a: TVecI64x8; count: Integer): TVecI64x8;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  // Logical right shift (unsigned)
  asm
    mov     rax, pa
    mov     rcx, pr
    mov     edx, count
    movd    xmm7, edx       // Load shift count
    movdqu  xmm0, [rax]
    movdqu  xmm1, [rax+16]
    movdqu  xmm2, [rax+32]
    movdqu  xmm3, [rax+48]
    // Logical shift right
    psrlq   xmm0, xmm7
    psrlq   xmm1, xmm7
    psrlq   xmm2, xmm7
    psrlq   xmm3, xmm7
    movdqu  [rcx], xmm0
    movdqu  [rcx+16], xmm1
    movdqu  [rcx+32], xmm2
    movdqu  [rcx+48], xmm3
  end;
end;

function SSE2CmpEqI64x8(const a, b: TVecI64x8): TMask8;
var
  mLo, mHi: TMask4;
begin
  mLo := SSE2CmpEqI64x4(a.lo, b.lo);
  mHi := SSE2CmpEqI64x4(a.hi, b.hi);
  Result := (mLo and $F) or ((mHi and $F) shl 4);
end;

function SSE2CmpLtI64x8(const a, b: TVecI64x8): TMask8;
var
  mLo, mHi: TMask4;
begin
  mLo := SSE2CmpLtI64x4(a.lo, b.lo);
  mHi := SSE2CmpLtI64x4(a.hi, b.hi);
  Result := (mLo and $F) or ((mHi and $F) shl 4);
end;

function SSE2CmpGtI64x8(const a, b: TVecI64x8): TMask8;
var
  mLo, mHi: TMask4;
begin
  mLo := SSE2CmpGtI64x4(a.lo, b.lo);
  mHi := SSE2CmpGtI64x4(a.hi, b.hi);
  Result := (mLo and $F) or ((mHi and $F) shl 4);
end;

function SSE2CmpLeI64x8(const a, b: TVecI64x8): TMask8;
var
  mLo, mHi: TMask4;
begin
  mLo := SSE2CmpLeI64x4(a.lo, b.lo);
  mHi := SSE2CmpLeI64x4(a.hi, b.hi);
  Result := (mLo and $F) or ((mHi and $F) shl 4);
end;

function SSE2CmpGeI64x8(const a, b: TVecI64x8): TMask8;
var
  mLo, mHi: TMask4;
begin
  mLo := SSE2CmpGeI64x4(a.lo, b.lo);
  mHi := SSE2CmpGeI64x4(a.hi, b.hi);
  Result := (mLo and $F) or ((mHi and $F) shl 4);
end;

function SSE2CmpNeI64x8(const a, b: TVecI64x8): TMask8;
var
  mLo, mHi: TMask4;
begin
  mLo := SSE2CmpNeI64x4(a.lo, b.lo);
  mHi := SSE2CmpNeI64x4(a.hi, b.hi);
  Result := (mLo and $F) or ((mHi and $F) shl 4);
end;

function SSE2LoadI64x8(p: PInt64): TVecI64x8;
begin
  Result.i[0] := p[0];
  Result.i[1] := p[1];
  Result.i[2] := p[2];
  Result.i[3] := p[3];
  Result.i[4] := p[4];
  Result.i[5] := p[5];
  Result.i[6] := p[6];
  Result.i[7] := p[7];
end;

procedure SSE2StoreI64x8(p: PInt64; const a: TVecI64x8);
begin
  p[0] := a.i[0];
  p[1] := a.i[1];
  p[2] := a.i[2];
  p[3] := a.i[3];
  p[4] := a.i[4];
  p[5] := a.i[5];
  p[6] := a.i[6];
  p[7] := a.i[7];
end;

function SSE2SplatI64x8(value: Int64): TVecI64x8;
begin
  Result.i[0] := value;
  Result.i[1] := value;
  Result.i[2] := value;
  Result.i[3] := value;
  Result.i[4] := value;
  Result.i[5] := value;
  Result.i[6] := value;
  Result.i[7] := value;
end;

function SSE2ZeroI64x8: TVecI64x8;
begin
  Result.i[0] := 0;
  Result.i[1] := 0;
  Result.i[2] := 0;
  Result.i[3] := 0;
  Result.i[4] := 0;
  Result.i[5] := 0;
  Result.i[6] := 0;
  Result.i[7] := 0;
end;

// ============================================================================
// ✅ NEW: Extract/Insert 操作实现
// ============================================================================

function SSE2ExtractF64x2(const a: TVecF64x2; index: Integer): Double;
begin
  Result := a.d[index and 1];
end;

function SSE2InsertF64x2(const a: TVecF64x2; value: Double; index: Integer): TVecF64x2;
begin
  Result := a;
  Result.d[index and 1] := value;
end;

function SSE2ExtractI32x4(const a: TVecI32x4; index: Integer): Int32;
begin
  Result := a.i[index and 3];
end;

function SSE2InsertI32x4(const a: TVecI32x4; value: Int32; index: Integer): TVecI32x4;
begin
  Result := a;
  Result.i[index and 3] := value;
end;

function SSE2ExtractI64x2(const a: TVecI64x2; index: Integer): Int64;
begin
  Result := a.i[index and 1];
end;

function SSE2InsertI64x2(const a: TVecI64x2; value: Int64; index: Integer): TVecI64x2;
begin
  Result := a;
  Result.i[index and 1] := value;
end;

function SSE2ExtractF32x8(const a: TVecF32x8; index: Integer): Single;
begin
  Result := a.f[index and 7];
end;

function SSE2InsertF32x8(const a: TVecF32x8; value: Single; index: Integer): TVecF32x8;
begin
  Result := a;
  Result.f[index and 7] := value;
end;

function SSE2ExtractF64x4(const a: TVecF64x4; index: Integer): Double;
begin
  Result := a.d[index and 3];
end;

function SSE2InsertF64x4(const a: TVecF64x4; value: Double; index: Integer): TVecF64x4;
begin
  Result := a;
  Result.d[index and 3] := value;
end;

function SSE2ExtractI32x8(const a: TVecI32x8; index: Integer): Int32;
begin
  Result := a.i[index and 7];
end;

function SSE2InsertI32x8(const a: TVecI32x8; value: Int32; index: Integer): TVecI32x8;
begin
  Result := a;
  Result.i[index and 7] := value;
end;

function SSE2ExtractI64x4(const a: TVecI64x4; index: Integer): Int64;
begin
  Result := a.i[index and 3];
end;

function SSE2InsertI64x4(const a: TVecI64x4; value: Int64; index: Integer): TVecI64x4;
begin
  Result := a;
  Result.i[index and 3] := value;
end;

function SSE2ExtractF32x16(const a: TVecF32x16; index: Integer): Single;
begin
  Result := a.f[index and 15];
end;

function SSE2InsertF32x16(const a: TVecF32x16; value: Single; index: Integer): TVecF32x16;
begin
  Result := a;
  Result.f[index and 15] := value;
end;

function SSE2ExtractI32x16(const a: TVecI32x16; index: Integer): Int32;
begin
  Result := a.i[index and 15];
end;

function SSE2InsertI32x16(const a: TVecI32x16; value: Int32; index: Integer): TVecI32x16;
begin
  Result := a;
  Result.i[index and 15] := value;
end;

// ============================================================================
// ✅ NEW: Facade 函数实现 (高级内存和文本操作)
// ============================================================================

function MemDiffRange_SSE2(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
var
  i: SizeUInt;
  pA, pB: PByte;
begin
  // 简单标量实现 (可后续优化为 SIMD)
  pA := PByte(a);
  pB := PByte(b);
  firstDiff := 0;
  lastDiff := 0;
  Result := False;

  // 找第一个不同位置
  for i := 0 to len - 1 do
  begin
    if pA[i] <> pB[i] then
    begin
      firstDiff := i;
      Result := True;
      Break;
    end;
  end;

  if not Result then
    Exit;

  // 找最后一个不同位置
  lastDiff := firstDiff;
  for i := len - 1 downto firstDiff + 1 do
  begin
    if pA[i] <> pB[i] then
    begin
      lastDiff := i;
      Break;
    end;
  end;
end;

procedure MemReverse_SSE2(p: Pointer; len: SizeUInt);
var
  pB: PByte;
  i, j: SizeUInt;
  tmp: Byte;
begin
  pB := PByte(p);
  i := 0;
  j := len - 1;
  while i < j do
  begin
    tmp := pB[i];
    pB[i] := pB[j];
    pB[j] := tmp;
    Inc(i);
    Dec(j);
  end;
end;

procedure ToLowerAscii_SSE2(p: Pointer; len: SizeUInt);
var
  pB: PByte;
  i: SizeUInt;
  c: Byte;
begin
  pB := PByte(p);
  for i := 0 to len - 1 do
  begin
    c := pB[i];
    if (c >= Ord('A')) and (c <= Ord('Z')) then
      pB[i] := c + 32;
  end;
end;

procedure ToUpperAscii_SSE2(p: Pointer; len: SizeUInt);
var
  pB: PByte;
  i: SizeUInt;
  c: Byte;
begin
  pB := PByte(p);
  for i := 0 to len - 1 do
  begin
    c := pB[i];
    if (c >= Ord('a')) and (c <= Ord('z')) then
      pB[i] := c - 32;
  end;
end;

function AsciiIEqual_SSE2(a, b: Pointer; len: SizeUInt): Boolean;
var
  pA, pB: PByte;
  i: SizeUInt;
  cA, cB: Byte;
begin
  pA := PByte(a);
  pB := PByte(b);
  for i := 0 to len - 1 do
  begin
    cA := pA[i];
    cB := pB[i];
    // 转换为小写后比较
    if (cA >= Ord('A')) and (cA <= Ord('Z')) then
      cA := cA + 32;
    if (cB >= Ord('A')) and (cB <= Ord('Z')) then
      cB := cB + 32;
    if cA <> cB then
      Exit(False);
  end;
  Result := True;
end;

function BytesIndexOf_SSE2(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;
var
  pHay, pNeedle: PByte;
  i, j: SizeUInt;
  firstByte: Byte;
  found: Boolean;
begin
  if (needleLen = 0) or (needleLen > haystackLen) then
    Exit(-1);

  pHay := PByte(haystack);
  pNeedle := PByte(needle);
  firstByte := pNeedle[0];

  for i := 0 to haystackLen - needleLen do
  begin
    if pHay[i] = firstByte then
    begin
      found := True;
      for j := 1 to needleLen - 1 do
      begin
        if pHay[i + j] <> pNeedle[j] then
        begin
          found := False;
          Break;
        end;
      end;
      if found then
        Exit(i);
    end;
  end;
  Result := -1;
end;

function Utf8Validate_SSE2(p: Pointer; len: SizeUInt): Boolean;
var
  pB: PByte;
  i: SizeUInt;
  b: Byte;
begin
  // 简单的 UTF-8 验证 (可后续优化为 SIMD)
  pB := PByte(p);
  i := 0;
  while i < len do
  begin
    b := pB[i];
    if b < $80 then
    begin
      // ASCII: 单字节
      Inc(i);
    end
    else if (b and $E0) = $C0 then
    begin
      // 2 字节序列
      if i + 1 >= len then Exit(False);
      if (pB[i + 1] and $C0) <> $80 then Exit(False);
      Inc(i, 2);
    end
    else if (b and $F0) = $E0 then
    begin
      // 3 字节序列
      if i + 2 >= len then Exit(False);
      if (pB[i + 1] and $C0) <> $80 then Exit(False);
      if (pB[i + 2] and $C0) <> $80 then Exit(False);
      Inc(i, 3);
    end
    else if (b and $F8) = $F0 then
    begin
      // 4 字节序列
      if i + 3 >= len then Exit(False);
      if (pB[i + 1] and $C0) <> $80 then Exit(False);
      if (pB[i + 2] and $C0) <> $80 then Exit(False);
      if (pB[i + 3] and $C0) <> $80 then Exit(False);
      Inc(i, 4);
    end
    else
    begin
      // 无效的 UTF-8 首字节
      Exit(False);
    end;
  end;
  Result := True;
end;

// === Backend Registration ===

procedure RegisterSSE2Backend;
var
  dispatchTable: TSimdDispatchTable;
begin
  // Only register if SSE2 is available
  if not HasSSE2 then
    Exit;

  // Fill with base scalar implementations (provides fallback for all operations)
  dispatchTable := Default(TSimdDispatchTable);
  FillBaseDispatchTable(dispatchTable);

  // Set backend info
  dispatchTable.Backend := sbSSE2;
  with dispatchTable.BackendInfo do
  begin
    Backend := sbSSE2;
    Name := 'SSE2';
    Description := 'x86-64 SSE2 SIMD implementation';
    Capabilities := [scBasicArithmetic, scComparison, scMathFunctions, scReduction,
                     scLoadStore];
    if IsVectorAsmEnabled then
      Include(Capabilities, scShuffle);
    if IsVectorAsmEnabled then
      Include(Capabilities, scIntegerOps);
    Available := IsVectorAsmEnabled;
    Priority := GetSimdBackendPriorityValue(sbSSE2);
  end;

  // Vector-related operations default to Scalar reference implementations.

  if IsVectorAsmEnabled then
  begin
    // Override with SSE2 arithmetic operations
    dispatchTable.AddF32x4 := @SSE2AddF32x4;
    dispatchTable.SubF32x4 := @SSE2SubF32x4;
    dispatchTable.MulF32x4 := @SSE2MulF32x4;
    dispatchTable.DivF32x4 := @SSE2DivF32x4;

    dispatchTable.AddF32x8 := @SSE2AddF32x8;
    dispatchTable.SubF32x8 := @SSE2SubF32x8;
    dispatchTable.MulF32x8 := @SSE2MulF32x8;
    dispatchTable.DivF32x8 := @SSE2DivF32x8;

    // ✅ F32x8 扩展函数 (2026-02-05)
    dispatchTable.FmaF32x8 := @SSE2FmaF32x8;
    dispatchTable.FloorF32x8 := @SSE2FloorF32x8;
    dispatchTable.CeilF32x8 := @SSE2CeilF32x8;
    dispatchTable.RoundF32x8 := @SSE2RoundF32x8;
    dispatchTable.TruncF32x8 := @SSE2TruncF32x8;
    dispatchTable.AbsF32x8 := @SSE2AbsF32x8;
    dispatchTable.SqrtF32x8 := @SSE2SqrtF32x8;
    dispatchTable.MinF32x8 := @SSE2MinF32x8;
    dispatchTable.MaxF32x8 := @SSE2MaxF32x8;
    dispatchTable.ClampF32x8 := @SSE2ClampF32x8;
    dispatchTable.ReduceAddF32x8 := @SSE2ReduceAddF32x8;
    dispatchTable.ReduceMinF32x8 := @SSE2ReduceMinF32x8;
    dispatchTable.ReduceMaxF32x8 := @SSE2ReduceMaxF32x8;
    dispatchTable.ReduceMulF32x8 := @SSE2ReduceMulF32x8;
    dispatchTable.LoadF32x8 := @SSE2LoadF32x8;
    dispatchTable.StoreF32x8 := @SSE2StoreF32x8;
    dispatchTable.SplatF32x8 := @SSE2SplatF32x8;
    dispatchTable.ZeroF32x8 := @SSE2ZeroF32x8;

    // ✅ F32x8 comparison operations (2x F32x4)
    dispatchTable.CmpEqF32x8 := @SSE2CmpEqF32x8;
    dispatchTable.CmpLtF32x8 := @SSE2CmpLtF32x8;
    dispatchTable.CmpLeF32x8 := @SSE2CmpLeF32x8;
    dispatchTable.CmpGtF32x8 := @SSE2CmpGtF32x8;
    dispatchTable.CmpGeF32x8 := @SSE2CmpGeF32x8;
    dispatchTable.CmpNeF32x8 := @SSE2CmpNeF32x8;

    dispatchTable.AddF64x2 := @SSE2AddF64x2;
    dispatchTable.SubF64x2 := @SSE2SubF64x2;
    dispatchTable.MulF64x2 := @SSE2MulF64x2;
    dispatchTable.DivF64x2 := @SSE2DivF64x2;

    // ✅ F64x2 math operations (new)
    dispatchTable.SqrtF64x2 := @SSE2SqrtF64x2;
    dispatchTable.MinF64x2 := @SSE2MinF64x2;
    dispatchTable.MaxF64x2 := @SSE2MaxF64x2;
    dispatchTable.AbsF64x2 := @SSE2AbsF64x2;

    // ✅ F64x2 comparison operations (new)
    dispatchTable.CmpEqF64x2 := @SSE2CmpEqF64x2;
    dispatchTable.CmpLtF64x2 := @SSE2CmpLtF64x2;
    dispatchTable.CmpLeF64x2 := @SSE2CmpLeF64x2;
    dispatchTable.CmpGtF64x2 := @SSE2CmpGtF64x2;
    dispatchTable.CmpGeF64x2 := @SSE2CmpGeF64x2;
    dispatchTable.CmpNeF64x2 := @SSE2CmpNeF64x2;

    // ✅ F64x2 utility operations (new)
    dispatchTable.LoadF64x2 := @SSE2LoadF64x2;
    dispatchTable.StoreF64x2 := @SSE2StoreF64x2;
    dispatchTable.SplatF64x2 := @SSE2SplatF64x2;
    dispatchTable.ZeroF64x2 := @SSE2ZeroF64x2;

    // ✅ F64x2 扩展函数 (2026-02-05)
    dispatchTable.FloorF64x2 := @SSE2FloorF64x2;
    dispatchTable.CeilF64x2 := @SSE2CeilF64x2;
    dispatchTable.RoundF64x2 := @SSE2RoundF64x2;
    dispatchTable.TruncF64x2 := @SSE2TruncF64x2;
    dispatchTable.FmaF64x2 := @SSE2FmaF64x2;
    dispatchTable.ClampF64x2 := @SSE2ClampF64x2;
    dispatchTable.ReduceAddF64x2 := @SSE2ReduceAddF64x2;
    dispatchTable.ReduceMinF64x2 := @SSE2ReduceMinF64x2;
    dispatchTable.ReduceMaxF64x2 := @SSE2ReduceMaxF64x2;
    dispatchTable.ReduceMulF64x2 := @SSE2ReduceMulF64x2;

    // ✅ F64x4 分解实现 (2026-02-05) - 使用 2x F64x2
    dispatchTable.AddF64x4 := @SSE2AddF64x4;
    dispatchTable.SubF64x4 := @SSE2SubF64x4;
    dispatchTable.MulF64x4 := @SSE2MulF64x4;
    dispatchTable.DivF64x4 := @SSE2DivF64x4;
    dispatchTable.FmaF64x4 := @SSE2FmaF64x4;
    dispatchTable.RcpF64x4 := @SSE2RcpF64x4;
    dispatchTable.FloorF64x4 := @SSE2FloorF64x4;
    dispatchTable.CeilF64x4 := @SSE2CeilF64x4;
    dispatchTable.RoundF64x4 := @SSE2RoundF64x4;
    dispatchTable.TruncF64x4 := @SSE2TruncF64x4;
    dispatchTable.AbsF64x4 := @SSE2AbsF64x4;
    dispatchTable.SqrtF64x4 := @SSE2SqrtF64x4;
    dispatchTable.MinF64x4 := @SSE2MinF64x4;
    dispatchTable.MaxF64x4 := @SSE2MaxF64x4;
    dispatchTable.ClampF64x4 := @SSE2ClampF64x4;
    dispatchTable.ReduceAddF64x4 := @SSE2ReduceAddF64x4;
    dispatchTable.ReduceMinF64x4 := @SSE2ReduceMinF64x4;
    dispatchTable.ReduceMaxF64x4 := @SSE2ReduceMaxF64x4;
    dispatchTable.ReduceMulF64x4 := @SSE2ReduceMulF64x4;
    dispatchTable.LoadF64x4 := @SSE2LoadF64x4;
    dispatchTable.StoreF64x4 := @SSE2StoreF64x4;
    dispatchTable.SplatF64x4 := @SSE2SplatF64x4;
    dispatchTable.ZeroF64x4 := @SSE2ZeroF64x4;

    // ✅ F64x4 comparison operations (2x F64x2)
    dispatchTable.CmpEqF64x4 := @SSE2CmpEqF64x4;
    dispatchTable.CmpLtF64x4 := @SSE2CmpLtF64x4;
    dispatchTable.CmpLeF64x4 := @SSE2CmpLeF64x4;
    dispatchTable.CmpGtF64x4 := @SSE2CmpGtF64x4;
    dispatchTable.CmpGeF64x4 := @SSE2CmpGeF64x4;
    dispatchTable.CmpNeF64x4 := @SSE2CmpNeF64x4;

    dispatchTable.AddI32x4 := @SSE2AddI32x4;
    dispatchTable.SubI32x4 := @SSE2SubI32x4;
    dispatchTable.MulI32x4 := @SSE2MulI32x4;

    // ✅ I32x4 bitwise operations (new)
    dispatchTable.AndI32x4 := @SSE2AndI32x4;
    dispatchTable.OrI32x4 := @SSE2OrI32x4;
    dispatchTable.XorI32x4 := @SSE2XorI32x4;
    dispatchTable.NotI32x4 := @SSE2NotI32x4;
    dispatchTable.AndNotI32x4 := @SSE2AndNotI32x4;

    // ✅ I32x4 shift operations (new)
    dispatchTable.ShiftLeftI32x4 := @SSE2ShiftLeftI32x4;
    dispatchTable.ShiftRightI32x4 := @SSE2ShiftRightI32x4;
    dispatchTable.ShiftRightArithI32x4 := @SSE2ShiftRightArithI32x4;

    // ✅ I32x4 comparison operations (new)
    dispatchTable.CmpEqI32x4 := @SSE2CmpEqI32x4;
    dispatchTable.CmpLtI32x4 := @SSE2CmpLtI32x4;
    dispatchTable.CmpGtI32x4 := @SSE2CmpGtI32x4;
    dispatchTable.CmpLeI32x4 := @SSE2CmpLeI32x4;
    dispatchTable.CmpGeI32x4 := @SSE2CmpGeI32x4;
    dispatchTable.CmpNeI32x4 := @SSE2CmpNeI32x4;

    // ✅ I32x4 min/max operations (new)
    dispatchTable.MinI32x4 := @SSE2MinI32x4;
    dispatchTable.MaxI32x4 := @SSE2MaxI32x4;

    // ✅ I32x8 分解实现 (2026-02-05) - 使用 2x I32x4
    dispatchTable.AddI32x8 := @SSE2AddI32x8;
    dispatchTable.SubI32x8 := @SSE2SubI32x8;
    dispatchTable.MulI32x8 := @SSE2MulI32x8;
    dispatchTable.AndI32x8 := @SSE2AndI32x8;
    dispatchTable.OrI32x8 := @SSE2OrI32x8;
    dispatchTable.XorI32x8 := @SSE2XorI32x8;
    dispatchTable.NotI32x8 := @SSE2NotI32x8;
    dispatchTable.AndNotI32x8 := @SSE2AndNotI32x8;
    dispatchTable.ShiftLeftI32x8 := @SSE2ShiftLeftI32x8;
    dispatchTable.ShiftRightI32x8 := @SSE2ShiftRightI32x8;
    dispatchTable.ShiftRightArithI32x8 := @SSE2ShiftRightArithI32x8;
    dispatchTable.CmpEqI32x8 := @SSE2CmpEqI32x8;
    dispatchTable.CmpLtI32x8 := @SSE2CmpLtI32x8;
    dispatchTable.CmpGtI32x8 := @SSE2CmpGtI32x8;
    dispatchTable.CmpLeI32x8 := @SSE2CmpLeI32x8;
    dispatchTable.CmpGeI32x8 := @SSE2CmpGeI32x8;
    dispatchTable.CmpNeI32x8 := @SSE2CmpNeI32x8;
    dispatchTable.MinI32x8 := @SSE2MinI32x8;
    dispatchTable.MaxI32x8 := @SSE2MaxI32x8;

    // ✅ 512-bit 向量的 SSE2 渐进降级实现 (2026-02-05)

    // F32x16 (16×Float32)
    dispatchTable.AddF32x16 := @SSE2AddF32x16;
    dispatchTable.SubF32x16 := @SSE2SubF32x16;
    dispatchTable.MulF32x16 := @SSE2MulF32x16;
    dispatchTable.DivF32x16 := @SSE2DivF32x16;
    dispatchTable.AbsF32x16 := @SSE2AbsF32x16;
    dispatchTable.SqrtF32x16 := @SSE2SqrtF32x16;
    dispatchTable.MinF32x16 := @SSE2MinF32x16;
    dispatchTable.MaxF32x16 := @SSE2MaxF32x16;
    dispatchTable.FmaF32x16 := @SSE2FmaF32x16;
    dispatchTable.FloorF32x16 := @SSE2FloorF32x16;
    dispatchTable.CeilF32x16 := @SSE2CeilF32x16;
    dispatchTable.RoundF32x16 := @SSE2RoundF32x16;
    dispatchTable.TruncF32x16 := @SSE2TruncF32x16;
    dispatchTable.ClampF32x16 := @SSE2ClampF32x16;
    dispatchTable.ReduceAddF32x16 := @SSE2ReduceAddF32x16;
    dispatchTable.ReduceMinF32x16 := @SSE2ReduceMinF32x16;
    dispatchTable.ReduceMaxF32x16 := @SSE2ReduceMaxF32x16;
    dispatchTable.ReduceMulF32x16 := @SSE2ReduceMulF32x16;
    dispatchTable.LoadF32x16 := @SSE2LoadF32x16;
    dispatchTable.StoreF32x16 := @SSE2StoreF32x16;
    dispatchTable.SplatF32x16 := @SSE2SplatF32x16;
    dispatchTable.ZeroF32x16 := @SSE2ZeroF32x16;
    dispatchTable.CmpEqF32x16 := @SSE2CmpEqF32x16;
    dispatchTable.CmpLtF32x16 := @SSE2CmpLtF32x16;
    dispatchTable.CmpLeF32x16 := @SSE2CmpLeF32x16;
    dispatchTable.CmpGtF32x16 := @SSE2CmpGtF32x16;
    dispatchTable.CmpGeF32x16 := @SSE2CmpGeF32x16;
    dispatchTable.CmpNeF32x16 := @SSE2CmpNeF32x16;
    dispatchTable.SelectF32x16 := @SSE2SelectF32x16;

    // F64x8 (8×Float64)
    dispatchTable.AddF64x8 := @SSE2AddF64x8;
    dispatchTable.SubF64x8 := @SSE2SubF64x8;
    dispatchTable.MulF64x8 := @SSE2MulF64x8;
    dispatchTable.DivF64x8 := @SSE2DivF64x8;
    dispatchTable.AbsF64x8 := @SSE2AbsF64x8;
    dispatchTable.SqrtF64x8 := @SSE2SqrtF64x8;
    dispatchTable.MinF64x8 := @SSE2MinF64x8;
    dispatchTable.MaxF64x8 := @SSE2MaxF64x8;
    dispatchTable.FmaF64x8 := @SSE2FmaF64x8;
    dispatchTable.FloorF64x8 := @SSE2FloorF64x8;
    dispatchTable.CeilF64x8 := @SSE2CeilF64x8;
    dispatchTable.RoundF64x8 := @SSE2RoundF64x8;
    dispatchTable.TruncF64x8 := @SSE2TruncF64x8;
    dispatchTable.ClampF64x8 := @SSE2ClampF64x8;
    dispatchTable.ReduceAddF64x8 := @SSE2ReduceAddF64x8;
    dispatchTable.ReduceMinF64x8 := @SSE2ReduceMinF64x8;
    dispatchTable.ReduceMaxF64x8 := @SSE2ReduceMaxF64x8;
    dispatchTable.ReduceMulF64x8 := @SSE2ReduceMulF64x8;
    dispatchTable.LoadF64x8 := @SSE2LoadF64x8;
    dispatchTable.StoreF64x8 := @SSE2StoreF64x8;
    dispatchTable.SplatF64x8 := @SSE2SplatF64x8;
    dispatchTable.ZeroF64x8 := @SSE2ZeroF64x8;
    dispatchTable.CmpEqF64x8 := @SSE2CmpEqF64x8;
    dispatchTable.CmpLtF64x8 := @SSE2CmpLtF64x8;
    dispatchTable.CmpLeF64x8 := @SSE2CmpLeF64x8;
    dispatchTable.CmpGtF64x8 := @SSE2CmpGtF64x8;
    dispatchTable.CmpGeF64x8 := @SSE2CmpGeF64x8;
    dispatchTable.CmpNeF64x8 := @SSE2CmpNeF64x8;
    dispatchTable.SelectF64x8 := @SSE2SelectF64x8;

    // I32x16 (16×Int32)
    dispatchTable.AddI32x16 := @SSE2AddI32x16;
    dispatchTable.SubI32x16 := @SSE2SubI32x16;
    dispatchTable.MulI32x16 := @SSE2MulI32x16;
    dispatchTable.AndI32x16 := @SSE2AndI32x16;
    dispatchTable.OrI32x16 := @SSE2OrI32x16;
    dispatchTable.XorI32x16 := @SSE2XorI32x16;
    dispatchTable.NotI32x16 := @SSE2NotI32x16;
    dispatchTable.AndNotI32x16 := @SSE2AndNotI32x16;
    dispatchTable.ShiftLeftI32x16 := @SSE2ShiftLeftI32x16;
    dispatchTable.ShiftRightI32x16 := @SSE2ShiftRightI32x16;
    dispatchTable.ShiftRightArithI32x16 := @SSE2ShiftRightArithI32x16;
    dispatchTable.CmpEqI32x16 := @SSE2CmpEqI32x16;
    dispatchTable.CmpLtI32x16 := @SSE2CmpLtI32x16;
    dispatchTable.CmpGtI32x16 := @SSE2CmpGtI32x16;
    dispatchTable.CmpLeI32x16 := @SSE2CmpLeI32x16;
    dispatchTable.CmpGeI32x16 := @SSE2CmpGeI32x16;
    dispatchTable.CmpNeI32x16 := @SSE2CmpNeI32x16;
    dispatchTable.MinI32x16 := @SSE2MinI32x16;
    dispatchTable.MaxI32x16 := @SSE2MaxI32x16;

    // ✅ P3: I64x2 arithmetic and bitwise
    dispatchTable.AddI64x2 := @SSE2AddI64x2;
    dispatchTable.SubI64x2 := @SSE2SubI64x2;
    dispatchTable.AndI64x2 := @SSE2AndI64x2;
    dispatchTable.OrI64x2 := @SSE2OrI64x2;
    dispatchTable.XorI64x2 := @SSE2XorI64x2;
    dispatchTable.NotI64x2 := @SSE2NotI64x2;

    // ✅ I64x2 comparison operations (SSE2 emulation)
    // SSE2 没有原生 64 位整数比较指令（PCMPGTQ 是 SSE4.2）
    // 使用 32 位比较的组合逻辑来模拟 64 位比较
    dispatchTable.CmpEqI64x2 := @SSE2CmpEqI64x2;
    dispatchTable.CmpNeI64x2 := @SSE2CmpNeI64x2;
    dispatchTable.CmpGtI64x2 := @SSE2CmpGtI64x2;
    dispatchTable.CmpLtI64x2 := @SSE2CmpLtI64x2;
    dispatchTable.CmpGeI64x2 := @SSE2CmpGeI64x2;
    dispatchTable.CmpLeI64x2 := @SSE2CmpLeI64x2;

    // Override with SSE2 comparison operations
    dispatchTable.CmpEqF32x4 := @SSE2CmpEqF32x4;
    dispatchTable.CmpLtF32x4 := @SSE2CmpLtF32x4;
    dispatchTable.CmpLeF32x4 := @SSE2CmpLeF32x4;
    dispatchTable.CmpGtF32x4 := @SSE2CmpGtF32x4;
    dispatchTable.CmpGeF32x4 := @SSE2CmpGeF32x4;
    dispatchTable.CmpNeF32x4 := @SSE2CmpNeF32x4;

    // Override with SSE2 math functions
    dispatchTable.AbsF32x4 := @SSE2AbsF32x4;
    dispatchTable.SqrtF32x4 := @SSE2SqrtF32x4;
    dispatchTable.MinF32x4 := @SSE2MinF32x4;
    dispatchTable.MaxF32x4 := @SSE2MaxF32x4;

    // Override with SSE2 extended math functions
    dispatchTable.FmaF32x4 := @SSE2FmaF32x4;
    dispatchTable.RcpF32x4 := @SSE2RcpF32x4;
    dispatchTable.RsqrtF32x4 := @SSE2RsqrtF32x4;
    dispatchTable.FloorF32x4 := @SSE2FloorF32x4;
    dispatchTable.CeilF32x4 := @SSE2CeilF32x4;
    dispatchTable.RoundF32x4 := @SSE2RoundF32x4;
    dispatchTable.TruncF32x4 := @SSE2TruncF32x4;
    dispatchTable.ClampF32x4 := @SSE2ClampF32x4;

    // Override with SSE2 vector math functions
    dispatchTable.DotF32x4 := @SSE2DotF32x4;
    dispatchTable.DotF32x3 := @SSE2DotF32x3;
    dispatchTable.CrossF32x3 := @SSE2CrossF32x3;
    dispatchTable.LengthF32x4 := @SSE2LengthF32x4;
    dispatchTable.LengthF32x3 := @SSE2LengthF32x3;
    dispatchTable.NormalizeF32x4 := @SSE2NormalizeF32x4;
    dispatchTable.NormalizeF32x3 := @SSE2NormalizeF32x3;

    // Override with SSE2 reduction operations
    dispatchTable.ReduceAddF32x4 := @SSE2ReduceAddF32x4;
    dispatchTable.ReduceMinF32x4 := @SSE2ReduceMinF32x4;
    dispatchTable.ReduceMaxF32x4 := @SSE2ReduceMaxF32x4;
    dispatchTable.ReduceMulF32x4 := @SSE2ReduceMulF32x4;

    // Override with SSE2 memory operations
    dispatchTable.LoadF32x4 := @SSE2LoadF32x4;
    dispatchTable.LoadF32x4Aligned := @SSE2LoadF32x4Aligned;
    dispatchTable.StoreF32x4 := @SSE2StoreF32x4;
    dispatchTable.StoreF32x4Aligned := @SSE2StoreF32x4Aligned;

    // Override with SSE2 utility operations
    dispatchTable.SplatF32x4 := @SSE2SplatF32x4;
    dispatchTable.ZeroF32x4 := @SSE2ZeroF32x4;
    dispatchTable.SelectF32x4 := @SSE2SelectF32x4;
    dispatchTable.ExtractF32x4 := @SSE2ExtractF32x4;
    dispatchTable.InsertF32x4 := @SSE2InsertF32x4;

    // ✅ P4: SelectF64x2
    dispatchTable.SelectF64x2 := @SSE2SelectF64x2;

    // ✅ NEW: 缺失的 Select 操作
    dispatchTable.SelectI32x4 := @SSE2SelectI32x4;
    dispatchTable.SelectF32x8 := @SSE2SelectF32x8;
    dispatchTable.SelectF64x4 := @SSE2SelectF64x4;
  end;
  // else: keep scalar implementations from FillBaseDispatchTable

  // Override facade functions with SSE2-accelerated versions
  dispatchTable.MemEqual := @MemEqual_SSE2;
  dispatchTable.MemFindByte := @MemFindByte_SSE2;
  dispatchTable.SumBytes := @SumBytes_SSE2;
  dispatchTable.CountByte := @CountByte_SSE2;
  dispatchTable.MinMaxBytes := @MinMaxBytes_SSE2;
  dispatchTable.BitsetPopCount := @BitsetPopCount_SSE2;
  // ✅ Register SSE2 memory operations
  dispatchTable.MemCopy := @MemCopy_SSE2;
  dispatchTable.MemSet := @MemSet_SSE2;
  // Note: MemDiffRange, MemReverse, Utf8Validate keep scalar implementations

  // ✅ P2-1: Override with SSE2 saturating arithmetic (always enabled, stable ops)
  dispatchTable.I8x16SatAdd := @SSE2I8x16SatAdd;
  dispatchTable.I8x16SatSub := @SSE2I8x16SatSub;
  dispatchTable.I16x8SatAdd := @SSE2I16x8SatAdd;
  dispatchTable.I16x8SatSub := @SSE2I16x8SatSub;
  dispatchTable.U8x16SatAdd := @SSE2U8x16SatAdd;
  dispatchTable.U8x16SatSub := @SSE2U8x16SatSub;
  dispatchTable.U16x8SatAdd := @SSE2U16x8SatAdd;
  dispatchTable.U16x8SatSub := @SSE2U16x8SatSub;

  // ✅ I16x8 operations (SSE2)
  dispatchTable.AddI16x8 := @SSE2AddI16x8;
  dispatchTable.SubI16x8 := @SSE2SubI16x8;
  dispatchTable.MulI16x8 := @SSE2MulI16x8;
  dispatchTable.AndI16x8 := @SSE2AndI16x8;
  dispatchTable.OrI16x8 := @SSE2OrI16x8;
  dispatchTable.XorI16x8 := @SSE2XorI16x8;
  dispatchTable.NotI16x8 := @SSE2NotI16x8;
  dispatchTable.AndNotI16x8 := @SSE2AndNotI16x8;
  dispatchTable.ShiftLeftI16x8 := @SSE2ShiftLeftI16x8;
  dispatchTable.ShiftRightI16x8 := @SSE2ShiftRightI16x8;
  dispatchTable.ShiftRightArithI16x8 := @SSE2ShiftRightArithI16x8;
  dispatchTable.CmpEqI16x8 := @SSE2CmpEqI16x8;
  dispatchTable.CmpLtI16x8 := @SSE2CmpLtI16x8;
  dispatchTable.CmpGtI16x8 := @SSE2CmpGtI16x8;
  dispatchTable.CmpLeI16x8 := @SSE2CmpLeI16x8;  // ✅ NEW
  dispatchTable.CmpGeI16x8 := @SSE2CmpGeI16x8;  // ✅ NEW
  dispatchTable.CmpNeI16x8 := @SSE2CmpNeI16x8;  // ✅ NEW
  dispatchTable.MinI16x8 := @SSE2MinI16x8;
  dispatchTable.MaxI16x8 := @SSE2MaxI16x8;

  // ✅ I8x16 operations (SSE2)
  dispatchTable.AddI8x16 := @SSE2AddI8x16;
  dispatchTable.SubI8x16 := @SSE2SubI8x16;
  dispatchTable.AndI8x16 := @SSE2AndI8x16;
  dispatchTable.OrI8x16 := @SSE2OrI8x16;
  dispatchTable.XorI8x16 := @SSE2XorI8x16;
  dispatchTable.NotI8x16 := @SSE2NotI8x16;
  dispatchTable.CmpEqI8x16 := @SSE2CmpEqI8x16;
  dispatchTable.CmpLtI8x16 := @SSE2CmpLtI8x16;
  dispatchTable.CmpGtI8x16 := @SSE2CmpGtI8x16;
  dispatchTable.CmpLeI8x16 := @SSE2CmpLeI8x16;  // ✅ NEW
  dispatchTable.CmpGeI8x16 := @SSE2CmpGeI8x16;  // ✅ NEW
  dispatchTable.CmpNeI8x16 := @SSE2CmpNeI8x16;  // ✅ NEW
  dispatchTable.MinI8x16 := @SSE2MinI8x16;
  dispatchTable.MaxI8x16 := @SSE2MaxI8x16;

  // ✅ U32x4 operations (SSE2)
  dispatchTable.AddU32x4 := @SSE2AddU32x4;
  dispatchTable.SubU32x4 := @SSE2SubU32x4;
  dispatchTable.MulU32x4 := @SSE2MulU32x4;
  dispatchTable.AndU32x4 := @SSE2AndU32x4;
  dispatchTable.OrU32x4 := @SSE2OrU32x4;
  dispatchTable.XorU32x4 := @SSE2XorU32x4;
  dispatchTable.NotU32x4 := @SSE2NotU32x4;
  dispatchTable.AndNotU32x4 := @SSE2AndNotU32x4;
  dispatchTable.ShiftLeftU32x4 := @SSE2ShiftLeftU32x4;
  dispatchTable.ShiftRightU32x4 := @SSE2ShiftRightU32x4;
  dispatchTable.CmpEqU32x4 := @SSE2CmpEqU32x4;
  dispatchTable.CmpLtU32x4 := @SSE2CmpLtU32x4;
  dispatchTable.CmpGtU32x4 := @SSE2CmpGtU32x4;
  dispatchTable.CmpLeU32x4 := @SSE2CmpLeU32x4;
  dispatchTable.CmpGeU32x4 := @SSE2CmpGeU32x4;
  // Note: CmpNeU32x4 not in dispatch table
  dispatchTable.MinU32x4 := @SSE2MinU32x4;
  dispatchTable.MaxU32x4 := @SSE2MaxU32x4;

  // ✅ U16x8 operations (SSE2)
  dispatchTable.AddU16x8 := @SSE2AddU16x8;
  dispatchTable.SubU16x8 := @SSE2SubU16x8;
  dispatchTable.MulU16x8 := @SSE2MulU16x8;
  dispatchTable.AndU16x8 := @SSE2AndU16x8;
  dispatchTable.OrU16x8 := @SSE2OrU16x8;
  dispatchTable.XorU16x8 := @SSE2XorU16x8;
  dispatchTable.NotU16x8 := @SSE2NotU16x8;
  dispatchTable.ShiftLeftU16x8 := @SSE2ShiftLeftU16x8;
  dispatchTable.ShiftRightU16x8 := @SSE2ShiftRightU16x8;
  dispatchTable.CmpEqU16x8 := @SSE2CmpEqU16x8;
  dispatchTable.CmpLtU16x8 := @SSE2CmpLtU16x8;
  dispatchTable.CmpGtU16x8 := @SSE2CmpGtU16x8;
  dispatchTable.CmpLeU16x8 := @SSE2CmpLeU16x8;  // ✅ NEW
  dispatchTable.CmpGeU16x8 := @SSE2CmpGeU16x8;  // ✅ NEW
  dispatchTable.CmpNeU16x8 := @SSE2CmpNeU16x8;  // ✅ NEW
  dispatchTable.MinU16x8 := @SSE2MinU16x8;
  dispatchTable.MaxU16x8 := @SSE2MaxU16x8;

  // ✅ U8x16 operations (SSE2)
  dispatchTable.AddU8x16 := @SSE2AddU8x16;
  dispatchTable.SubU8x16 := @SSE2SubU8x16;
  dispatchTable.AndU8x16 := @SSE2AndU8x16;
  dispatchTable.OrU8x16 := @SSE2OrU8x16;
  dispatchTable.XorU8x16 := @SSE2XorU8x16;
  dispatchTable.NotU8x16 := @SSE2NotU8x16;
  dispatchTable.CmpEqU8x16 := @SSE2CmpEqU8x16;
  dispatchTable.CmpLtU8x16 := @SSE2CmpLtU8x16;
  dispatchTable.CmpGtU8x16 := @SSE2CmpGtU8x16;
  dispatchTable.CmpLeU8x16 := @SSE2CmpLeU8x16;  // ✅ NEW
  dispatchTable.CmpGeU8x16 := @SSE2CmpGeU8x16;  // ✅ NEW
  dispatchTable.CmpNeU8x16 := @SSE2CmpNeU8x16;  // ✅ NEW
  dispatchTable.MinU8x16 := @SSE2MinU8x16;
  dispatchTable.MaxU8x16 := @SSE2MaxU8x16;

  // ============================================================================
  // ✅ NEW: I64x4 操作注册 (256-bit，使用 2×I64x2 仿真)
  // ============================================================================
  dispatchTable.AddI64x4 := @SSE2AddI64x4;
  dispatchTable.SubI64x4 := @SSE2SubI64x4;
  dispatchTable.AndI64x4 := @SSE2AndI64x4;
  dispatchTable.OrI64x4 := @SSE2OrI64x4;
  dispatchTable.XorI64x4 := @SSE2XorI64x4;
  dispatchTable.NotI64x4 := @SSE2NotI64x4;
  dispatchTable.AndNotI64x4 := @SSE2AndNotI64x4;
  dispatchTable.ShiftLeftI64x4 := @SSE2ShiftLeftI64x4;
  dispatchTable.ShiftRightI64x4 := @SSE2ShiftRightI64x4;
  dispatchTable.CmpEqI64x4 := @SSE2CmpEqI64x4;
  dispatchTable.CmpLtI64x4 := @SSE2CmpLtI64x4;
  dispatchTable.CmpGtI64x4 := @SSE2CmpGtI64x4;
  dispatchTable.CmpLeI64x4 := @SSE2CmpLeI64x4;
  dispatchTable.CmpGeI64x4 := @SSE2CmpGeI64x4;
  dispatchTable.CmpNeI64x4 := @SSE2CmpNeI64x4;
  dispatchTable.LoadI64x4 := @SSE2LoadI64x4;
  dispatchTable.StoreI64x4 := @SSE2StoreI64x4;
  dispatchTable.SplatI64x4 := @SSE2SplatI64x4;
  dispatchTable.ZeroI64x4 := @SSE2ZeroI64x4;

  // ============================================================================
  // ✅ NEW: U32x8 操作注册 (256-bit，使用 2×U32x4 仿真)
  // ============================================================================
  dispatchTable.AddU32x8 := @SSE2AddU32x8;
  dispatchTable.SubU32x8 := @SSE2SubU32x8;
  dispatchTable.MulU32x8 := @SSE2MulU32x8;
  dispatchTable.AndU32x8 := @SSE2AndU32x8;
  dispatchTable.OrU32x8 := @SSE2OrU32x8;
  dispatchTable.XorU32x8 := @SSE2XorU32x8;
  dispatchTable.NotU32x8 := @SSE2NotU32x8;
  dispatchTable.AndNotU32x8 := @SSE2AndNotU32x8;
  dispatchTable.ShiftLeftU32x8 := @SSE2ShiftLeftU32x8;
  dispatchTable.ShiftRightU32x8 := @SSE2ShiftRightU32x8;
  dispatchTable.CmpEqU32x8 := @SSE2CmpEqU32x8;
  dispatchTable.CmpLtU32x8 := @SSE2CmpLtU32x8;
  dispatchTable.CmpGtU32x8 := @SSE2CmpGtU32x8;
  dispatchTable.CmpLeU32x8 := @SSE2CmpLeU32x8;
  dispatchTable.CmpGeU32x8 := @SSE2CmpGeU32x8;
  dispatchTable.CmpNeU32x8 := @SSE2CmpNeU32x8;
  dispatchTable.MinU32x8 := @SSE2MinU32x8;
  dispatchTable.MaxU32x8 := @SSE2MaxU32x8;

  // ============================================================================
  // ✅ NEW: U64x4 操作注册 (256-bit，使用纯标量仿真)
  // ============================================================================
  dispatchTable.AddU64x4 := @SSE2AddU64x4;
  dispatchTable.SubU64x4 := @SSE2SubU64x4;
  dispatchTable.AndU64x4 := @SSE2AndU64x4;
  dispatchTable.OrU64x4 := @SSE2OrU64x4;
  dispatchTable.XorU64x4 := @SSE2XorU64x4;
  dispatchTable.NotU64x4 := @SSE2NotU64x4;
  dispatchTable.ShiftLeftU64x4 := @SSE2ShiftLeftU64x4;
  dispatchTable.ShiftRightU64x4 := @SSE2ShiftRightU64x4;
  dispatchTable.CmpEqU64x4 := @SSE2CmpEqU64x4;
  dispatchTable.CmpLtU64x4 := @SSE2CmpLtU64x4;
  dispatchTable.CmpGtU64x4 := @SSE2CmpGtU64x4;
  dispatchTable.CmpLeU64x4 := @SSE2CmpLeU64x4;
  dispatchTable.CmpGeU64x4 := @SSE2CmpGeU64x4;
  dispatchTable.CmpNeU64x4 := @SSE2CmpNeU64x4;

  // ============================================================================
  // ✅ NEW: I64x8 操作注册 (512-bit，使用 2×I64x4 仿真)
  // ============================================================================
  dispatchTable.AddI64x8 := @SSE2AddI64x8;
  dispatchTable.SubI64x8 := @SSE2SubI64x8;
  dispatchTable.AndI64x8 := @SSE2AndI64x8;
  dispatchTable.OrI64x8 := @SSE2OrI64x8;
  dispatchTable.XorI64x8 := @SSE2XorI64x8;
  dispatchTable.NotI64x8 := @SSE2NotI64x8;
  dispatchTable.CmpEqI64x8 := @SSE2CmpEqI64x8;
  dispatchTable.CmpLtI64x8 := @SSE2CmpLtI64x8;
  dispatchTable.CmpGtI64x8 := @SSE2CmpGtI64x8;
  dispatchTable.CmpLeI64x8 := @SSE2CmpLeI64x8;
  dispatchTable.CmpGeI64x8 := @SSE2CmpGeI64x8;
  dispatchTable.CmpNeI64x8 := @SSE2CmpNeI64x8;

  // ============================================================================
  // ✅ NEW: Extract/Insert 操作注册
  // ============================================================================
  dispatchTable.ExtractF64x2 := @SSE2ExtractF64x2;
  dispatchTable.InsertF64x2 := @SSE2InsertF64x2;
  dispatchTable.ExtractI32x4 := @SSE2ExtractI32x4;
  dispatchTable.InsertI32x4 := @SSE2InsertI32x4;
  dispatchTable.ExtractI64x2 := @SSE2ExtractI64x2;
  dispatchTable.InsertI64x2 := @SSE2InsertI64x2;
  dispatchTable.ExtractF32x8 := @SSE2ExtractF32x8;
  dispatchTable.InsertF32x8 := @SSE2InsertF32x8;
  dispatchTable.ExtractF64x4 := @SSE2ExtractF64x4;
  dispatchTable.InsertF64x4 := @SSE2InsertF64x4;
  dispatchTable.ExtractI32x8 := @SSE2ExtractI32x8;
  dispatchTable.InsertI32x8 := @SSE2InsertI32x8;
  dispatchTable.ExtractI64x4 := @SSE2ExtractI64x4;
  dispatchTable.InsertI64x4 := @SSE2InsertI64x4;
  dispatchTable.ExtractF32x16 := @SSE2ExtractF32x16;
  dispatchTable.InsertF32x16 := @SSE2InsertF32x16;
  dispatchTable.ExtractI32x16 := @SSE2ExtractI32x16;
  dispatchTable.InsertI32x16 := @SSE2InsertI32x16;

  // ============================================================================
  // ✅ NEW: Facade 函数注册
  // ============================================================================
  dispatchTable.MemDiffRange := @MemDiffRange_SSE2;
  dispatchTable.MemReverse := @MemReverse_SSE2;
  dispatchTable.ToLowerAscii := @ToLowerAscii_SSE2;
  dispatchTable.ToUpperAscii := @ToUpperAscii_SSE2;
  dispatchTable.AsciiIEqual := @AsciiIEqual_SSE2;
  dispatchTable.BytesIndexOf := @BytesIndexOf_SSE2;
  dispatchTable.Utf8Validate := @Utf8Validate_SSE2;

  // ✅ P1: Mask operations (bsf + SWAR popcount, always enabled)
  dispatchTable.Mask2All := @SSE2Mask2All;
  dispatchTable.Mask2Any := @SSE2Mask2Any;
  dispatchTable.Mask2None := @SSE2Mask2None;
  dispatchTable.Mask2PopCount := @SSE2Mask2PopCount;
  dispatchTable.Mask2FirstSet := @SSE2Mask2FirstSet;
  dispatchTable.Mask4All := @SSE2Mask4All;
  dispatchTable.Mask4Any := @SSE2Mask4Any;
  dispatchTable.Mask4None := @SSE2Mask4None;
  dispatchTable.Mask4PopCount := @SSE2Mask4PopCount;
  dispatchTable.Mask4FirstSet := @SSE2Mask4FirstSet;
  dispatchTable.Mask8All := @SSE2Mask8All;
  dispatchTable.Mask8Any := @SSE2Mask8Any;
  dispatchTable.Mask8None := @SSE2Mask8None;
  dispatchTable.Mask8PopCount := @SSE2Mask8PopCount;
  dispatchTable.Mask8FirstSet := @SSE2Mask8FirstSet;
  dispatchTable.Mask16All := @SSE2Mask16All;
  dispatchTable.Mask16Any := @SSE2Mask16Any;
  dispatchTable.Mask16None := @SSE2Mask16None;
  dispatchTable.Mask16PopCount := @SSE2Mask16PopCount;
  dispatchTable.Mask16FirstSet := @SSE2Mask16FirstSet;

  // Register the backend
  RegisterBackend(sbSSE2, dispatchTable);
end;

initialization
  RegisterSSE2Backend;
  // ✅ P1-D: Register rebuilder callback for VectorAsmEnabled changes
  RegisterBackendRebuilder(sbSSE2, @RegisterSSE2Backend);

end.
