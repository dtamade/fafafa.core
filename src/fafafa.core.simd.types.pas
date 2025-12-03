unit fafafa.core.simd.types;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  // 仅用于类型别名导出（避免在此单元重复实现 CPUInfo 结构�?
  fafafa.core.simd.cpuinfo.base;

// =============================================================
// 说明
// - 本单元为“过�?兼容层”，提供 SIMD 基础类型与枚举�?
// - 后续推荐直接使用 fafafa.core.simd.base 中的统一入口�?
// - 请逐步�?uses 中的 fafafa.core.simd.types 替换�?fafafa.core.simd.base�?
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

  // 128-bit 无符号向量 (Phase 1.1)
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

  // 256-bit 无符号向量 (Phase 1.1)
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

// === 掩码类型（位掩码�?===
type
  TMask2  = type Byte;   // �?2 位有�?
  TMask4  = type Byte;   // �?4 位有�?
  TMask8  = type Byte;   // �?8 位有�?
  TMask16 = type Word;   // �?16 位有�?
  TMask32 = type DWord;  // �?32 位有�?

// === 运算符重载 (Phase 1.2) ===
// TVecF32x4 运算符
operator + (const a, b: TVecF32x4): TVecF32x4; inline;
operator - (const a, b: TVecF32x4): TVecF32x4; inline;
operator * (const a, b: TVecF32x4): TVecF32x4; inline;
operator / (const a, b: TVecF32x4): TVecF32x4; inline;
operator - (const a: TVecF32x4): TVecF32x4; inline;
operator * (const a: TVecF32x4; s: Single): TVecF32x4; inline;
operator * (s: Single; const a: TVecF32x4): TVecF32x4; inline;
operator / (const a: TVecF32x4; s: Single): TVecF32x4; inline;

// TVecF64x2 运算符
operator + (const a, b: TVecF64x2): TVecF64x2; inline;
operator - (const a, b: TVecF64x2): TVecF64x2; inline;
operator * (const a, b: TVecF64x2): TVecF64x2; inline;
operator / (const a, b: TVecF64x2): TVecF64x2; inline;
operator - (const a: TVecF64x2): TVecF64x2; inline;

// TVecI32x4 运算符
operator + (const a, b: TVecI32x4): TVecI32x4; inline;
operator - (const a, b: TVecI32x4): TVecI32x4; inline;
operator - (const a: TVecI32x4): TVecI32x4; inline;

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

// === 后端与能�?===
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
    scMaskedOps
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

// === 常量：便捷掩�?===
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

// === �?CPUInfo 相关的类型别名（来源�?cpuinfo.base�?===
type
  TX86Features  = fafafa.core.simd.cpuinfo.base.TX86Features;
  TARMFeatures  = fafafa.core.simd.cpuinfo.base.TARMFeatures;
  TRISCVFeatures= fafafa.core.simd.cpuinfo.base.TRISCVFeatures;
  TX86CacheInfo = fafafa.core.simd.cpuinfo.base.TX86CacheInfo;
  TCPUInfo      = fafafa.core.simd.cpuinfo.base.TCPUInfo;

implementation

// === TVecF32x4 运算符实现 ===

operator + (const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] + b.f[i];
end;

operator - (const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] - b.f[i];
end;

operator * (const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] * b.f[i];
end;

operator / (const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] / b.f[i];
end;

operator - (const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := -a.f[i];
end;

operator * (const a: TVecF32x4; s: Single): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] * s;
end;

operator * (s: Single; const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := s * a.f[i];
end;

operator / (const a: TVecF32x4; s: Single): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] / s;
end;

// === TVecF64x2 运算符实现 ===

operator + (const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] + b.d[i];
end;

operator - (const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] - b.d[i];
end;

operator * (const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] * b.d[i];
end;

operator / (const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] / b.d[i];
end;

operator - (const a: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := -a.d[i];
end;

// === TVecI32x4 运算符实现 ===

operator + (const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] + b.i[i];
end;

operator - (const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] - b.i[i];
end;

operator - (const a: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := -a.i[i];
end;

end.
