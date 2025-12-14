unit fafafa.core.simd.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

// =============================================================
// 说明
// - 本单元是 SIMD 子系统的基础单元，包含所有公共类型、枚举、常量和接口定义。
// - 所有其他 SIMD 单元都应引用此单元。
// =============================================================

// === 向量数据类型（record + variant 部分）===
type
  // 128-bit 有符号向量
  TVecF32x4 = record
    case Integer of
      0: (f: array[0..3] of Single);
      1: (raw: array[0..15] of Byte);
  end;

  TVecF64x2 = record
    case Integer of
      0: (d: array[0..1] of Double);
      1: (raw: array[0..15] of Byte);
  end;

  TVecI32x4 = record
    case Integer of
      0: (i: array[0..3] of Int32);
      1: (raw: array[0..15] of Byte);
  end;

  TVecI64x2 = record
    case Integer of
      0: (i: array[0..1] of Int64);
      1: (raw: array[0..15] of Byte);
  end;

  TVecI16x8 = record
    case Integer of
      0: (i: array[0..7] of Int16);
      1: (raw: array[0..15] of Byte);
  end;

  TVecI8x16 = record
    case Integer of
      0: (i: array[0..15] of Int8);
      1: (raw: array[0..15] of Byte);
  end;

  // 128-bit 无符号向量
  TVecU32x4 = record
    case Integer of
      0: (u: array[0..3] of UInt32);
      1: (raw: array[0..15] of Byte);
  end;

  TVecU64x2 = record
    case Integer of
      0: (u: array[0..1] of UInt64);
      1: (raw: array[0..15] of Byte);
  end;

  TVecU16x8 = record
    case Integer of
      0: (u: array[0..7] of UInt16);
      1: (raw: array[0..15] of Byte);
  end;

  TVecU8x16 = record
    case Integer of
      0: (u: array[0..15] of UInt8);
      1: (raw: array[0..15] of Byte);
  end;

  // 256-bit
  TVecF32x8 = record
    case Integer of
      0: (f: array[0..7] of Single);
      1: (lo, hi: TVecF32x4);
      2: (raw: array[0..31] of Byte);
  end;

  TVecF64x4 = record
    case Integer of
      0: (d: array[0..3] of Double);
      1: (lo, hi: TVecF64x2);
      2: (raw: array[0..31] of Byte);
  end;

  TVecI32x8 = record
    case Integer of
      0: (i: array[0..7] of Int32);
      1: (lo, hi: TVecI32x4);
      2: (raw: array[0..31] of Byte);
  end;

  TVecI16x16 = record
    case Integer of
      0: (i: array[0..15] of Int16);
      1: (lo, hi: TVecI16x8);
      2: (raw: array[0..31] of Byte);
  end;

  TVecI8x32 = record
    case Integer of
      0: (i: array[0..31] of Int8);
      1: (lo, hi: TVecI8x16);
      2: (raw: array[0..31] of Byte);
  end;

  // 256-bit 无符号向量
  TVecU32x8 = record
    case Integer of
      0: (u: array[0..7] of UInt32);
      1: (lo, hi: TVecU32x4);
      2: (raw: array[0..31] of Byte);
  end;

  TVecU64x4 = record
    case Integer of
      0: (u: array[0..3] of UInt64);
      1: (lo, hi: TVecU64x2);
      2: (raw: array[0..31] of Byte);
  end;

  TVecU16x16 = record
    case Integer of
      0: (u: array[0..15] of UInt16);
      1: (lo, hi: TVecU16x8);
      2: (raw: array[0..31] of Byte);
  end;

  TVecU8x32 = record
    case Integer of
      0: (u: array[0..31] of UInt8);
      1: (lo, hi: TVecU8x16);
      2: (raw: array[0..31] of Byte);
  end;

  // 512-bit 向量类型
  TVecF32x16 = record
    case Integer of
      0: (f: array[0..15] of Single);
      1: (lo, hi: TVecF32x8);
      2: (raw: array[0..63] of Byte);
  end;

  TVecF64x8 = record
    case Integer of
      0: (d: array[0..7] of Double);
      1: (lo, hi: TVecF64x4);
      2: (raw: array[0..63] of Byte);
  end;

  TVecI32x16 = record
    case Integer of
      0: (i: array[0..15] of Int32);
      1: (lo, hi: TVecI32x8);
      2: (raw: array[0..63] of Byte);
  end;

  TVecI64x8 = record
    case Integer of
      0: (i: array[0..7] of Int64);
      1: (lo, hi: TVecI64x2);
      2: (raw: array[0..63] of Byte);
  end;

  TVecI16x32 = record
    case Integer of
      0: (i: array[0..31] of Int16);
      1: (lo, hi: TVecI16x16);
      2: (raw: array[0..63] of Byte);
  end;

  TVecI8x64 = record
    case Integer of
      0: (i: array[0..63] of Int8);
      1: (lo, hi: TVecI8x32);
      2: (raw: array[0..63] of Byte);
  end;

  // 512-bit 无符号向量
  TVecU32x16 = record
    case Integer of
      0: (u: array[0..15] of UInt32);
      1: (lo, hi: TVecU32x8);
      2: (raw: array[0..63] of Byte);
  end;

  TVecU64x8 = record
    case Integer of
      0: (u: array[0..7] of UInt64);
      1: (lo, hi: TVecU64x4);
      2: (raw: array[0..63] of Byte);
  end;

  TVecU8x64 = record
    case Integer of
      0: (u: array[0..63] of UInt8);
      1: (lo, hi: TVecU8x32);
      2: (raw: array[0..63] of Byte);
  end;

// === 位掩码类型 ===
type
  TMask2  = type Byte;   // 仅 2 位有效
  TMask4  = type Byte;   // 仅 4 位有效
  TMask8  = type Byte;   // 仅 8 位有效
  TMask16 = type Word;   // 仅 16 位有效
  TMask32 = type DWord;  // 仅 32 位有效
  TMask64 = type QWord;  // 64 位有效

// === 向量掩码类型 ===
type
  // 128-bit F32x4 掩码
  TMaskF32x4 = record
    case Integer of
      0: (m: array[0..3] of UInt32);      // 每个元素 0 或 $FFFFFFFF
      1: (raw: array[0..15] of Byte);
  end;

  // 128-bit F64x2 掩码
  TMaskF64x2 = record
    case Integer of
      0: (m: array[0..1] of UInt64);      // 每个元素 0 或 $FFFFFFFFFFFFFFFF
      1: (raw: array[0..15] of Byte);
  end;

  // 128-bit I32x4 掩码
  TMaskI32x4 = record
    case Integer of
      0: (m: array[0..3] of UInt32);      // 每个元素 0 或 $FFFFFFFF
      1: (raw: array[0..15] of Byte);
  end;

  // 128-bit I64x2 掩码
  TMaskI64x2 = record
    case Integer of
      0: (m: array[0..1] of UInt64);
      1: (raw: array[0..15] of Byte);
  end;

  // 512-bit F32x16 掩码
  // Note: bits 作为独立字段，不与 m 数组重叠
  TMaskF32x16 = record
    m: array[0..15] of UInt32;     // 每个元素 0 或 $FFFFFFFF
    bits: UInt16;                   // AVX-512 k 寄存器位模式
  end;

  // 512-bit I32x16 掩码
  TMaskI32x16 = record
    m: array[0..15] of UInt32;
    bits: UInt16;
  end;

  // 512-bit F64x8 掩码
  TMaskF64x8 = record
    m: array[0..7] of UInt64;
    bits: UInt8;                    // AVX-512 k 寄存器 8 位
  end;

// === 元素类型枚举 ===
type
  TSimdElementType = (
    setFloat32,
    setFloat64,
    setInt8,
    setInt16,
    setInt32,
    setInt64,
    setUInt8,
    setUInt16,
    setUInt32,
    setUInt64
  );

// === 后端与能力 ===
type
  TSimdBackend = (
    sbScalar,
    sbSSE2,
    sbAVX2,
    sbAVX512,
    sbNEON,
    sbRISCVV
  );

  TSimdCapability = (
    scBasicArithmetic,
    scComparison,
    scMathFunctions,
    scReduction,
    scShuffle,
    scFMA,
    scFastMath,
    scIntegerOps,
    scLoadStore,
    scGather,
    scMaskedOps,
    sc512BitOps
  );
  TSimdCapabilities  = set of TSimdCapability;
  TSimdCapabilitySet = TSimdCapabilities; // 别名

  TSimdBackendInfo = record
    Backend: TSimdBackend;
    Name: string;
    Description: string;
    Capabilities: TSimdCapabilities;
    Available: Boolean;
    Priority: Integer;
  end;

// === 常量：便捷掩码 ===
const
  MASK2_ALL_SET  : TMask2  = $03;
  MASK4_ALL_SET  : TMask4  = $0F;
  MASK8_ALL_SET  : TMask8  = $FF;
  MASK16_ALL_SET : TMask16 = $FFFF;
  MASK32_ALL_SET : TMask32 = $FFFFFFFF;

  MASK2_NONE_SET  : TMask2  = $00;
  MASK4_NONE_SET  : TMask4  = $00;
  MASK8_NONE_SET  : TMask8  = $00;
  MASK16_NONE_SET : TMask16 = $0000;
  MASK32_NONE_SET : TMask32 = $00000000;

implementation

end.


