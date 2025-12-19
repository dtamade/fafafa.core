unit fafafa.core.simd.types;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.math,
  fafafa.core.simd.cpuinfo.base,
  fafafa.core.simd.base;

// =============================================================
// 说明
// - 本单元为“过渡兼容层”，提供 SIMD 基础类型与枚举。
// - 核心类型定义位于 fafafa.core.simd.base。
// - 本单元保留用于：
//   1. 向后兼容（Re-export types）
//   2. 提供运算符重载和辅助函数
// =============================================================

// === 向量数据类型（Alias to base）===
type
  TVecF32x4 = fafafa.core.simd.base.TVecF32x4;
  TVecF64x2 = fafafa.core.simd.base.TVecF64x2;
  TVecI32x4 = fafafa.core.simd.base.TVecI32x4;
  TVecI64x2 = fafafa.core.simd.base.TVecI64x2;
  TVecI16x8 = fafafa.core.simd.base.TVecI16x8;
  TVecI8x16 = fafafa.core.simd.base.TVecI8x16;

  TVecU32x4 = fafafa.core.simd.base.TVecU32x4;
  TVecU64x2 = fafafa.core.simd.base.TVecU64x2;
  TVecU16x8 = fafafa.core.simd.base.TVecU16x8;
  TVecU8x16 = fafafa.core.simd.base.TVecU8x16;

  TVecF32x8 = fafafa.core.simd.base.TVecF32x8;
  TVecF64x4 = fafafa.core.simd.base.TVecF64x4;
  TVecI32x8 = fafafa.core.simd.base.TVecI32x8;
  TVecI16x16= fafafa.core.simd.base.TVecI16x16;
  TVecI8x32 = fafafa.core.simd.base.TVecI8x32;

  TVecU32x8 = fafafa.core.simd.base.TVecU32x8;
  TVecU64x4 = fafafa.core.simd.base.TVecU64x4;
  TVecU16x16= fafafa.core.simd.base.TVecU16x16;
  TVecU8x32 = fafafa.core.simd.base.TVecU8x32;

  TVecF32x16= fafafa.core.simd.base.TVecF32x16;
  TVecF64x8 = fafafa.core.simd.base.TVecF64x8;
  TVecI32x16= fafafa.core.simd.base.TVecI32x16;
  TVecI64x8 = fafafa.core.simd.base.TVecI64x8;
  TVecI16x32= fafafa.core.simd.base.TVecI16x32;
  TVecI8x64 = fafafa.core.simd.base.TVecI8x64;

  TVecU32x16= fafafa.core.simd.base.TVecU32x16;
  TVecU64x8 = fafafa.core.simd.base.TVecU64x8;
  TVecU8x64 = fafafa.core.simd.base.TVecU8x64;

// === 位掩码类型（Alias）===
type
  TMask2  = fafafa.core.simd.base.TMask2;
  TMask4  = fafafa.core.simd.base.TMask4;
  TMask8  = fafafa.core.simd.base.TMask8;
  TMask16 = fafafa.core.simd.base.TMask16;
  TMask32 = fafafa.core.simd.base.TMask32;
  TMask64 = fafafa.core.simd.base.TMask64;

// === 向量掩码类型（Alias）===
type
  TMaskF32x4 = fafafa.core.simd.base.TMaskF32x4;
  TMaskF64x2 = fafafa.core.simd.base.TMaskF64x2;
  TMaskI32x4 = fafafa.core.simd.base.TMaskI32x4;
  TMaskI64x2 = fafafa.core.simd.base.TMaskI64x2;
  TMaskF32x16= fafafa.core.simd.base.TMaskF32x16;
  TMaskI32x16= fafafa.core.simd.base.TMaskI32x16;
  TMaskF64x8 = fafafa.core.simd.base.TMaskF64x8;

// === 元素类型枚举（Alias）===
type
  TSimdElementType = fafafa.core.simd.base.TSimdElementType;

// === 后端与能力（Alias）===
type
  TSimdBackend      = fafafa.core.simd.base.TSimdBackend;
  TSimdCapability   = fafafa.core.simd.base.TSimdCapability;
  TSimdCapabilities = fafafa.core.simd.base.TSimdCapabilities;
  TSimdCapabilitySet= fafafa.core.simd.base.TSimdCapabilitySet;
  TSimdBackendInfo  = fafafa.core.simd.base.TSimdBackendInfo;

// === 常量：便捷掩码（Redeclare as aliases is tricky in Pascal, define directly）===
const
  MASK2_ALL_SET   : TMask2  = $03;
  MASK4_ALL_SET   : TMask4  = $0F;
  MASK8_ALL_SET   : TMask8  = $FF;
  MASK16_ALL_SET  : TMask16 = $FFFF;
  MASK32_ALL_SET  : TMask32 = $FFFFFFFF;

  MASK2_NONE_SET  : TMask2  = $00;
  MASK4_NONE_SET  : TMask4  = $00;
  MASK8_NONE_SET  : TMask8  = $00;
  MASK16_NONE_SET : TMask16 = $0000;
  MASK32_NONE_SET : TMask32 = $00000000;

// === 向量掩码构造函数 ===
function MaskF32x4AllTrue: TMaskF32x4; inline;
function MaskF32x4AllFalse: TMaskF32x4; inline;
function MaskF32x4Set(m0, m1, m2, m3: Boolean): TMaskF32x4; inline;
function MaskF32x4Test(const m: TMaskF32x4; index: Integer): Boolean; inline;
function MaskF32x4ToBitmask(const m: TMaskF32x4): TMask4; inline;
function MaskF32x4Any(const m: TMaskF32x4): Boolean; inline;
function MaskF32x4All(const m: TMaskF32x4): Boolean; inline;
function MaskF32x4None(const m: TMaskF32x4): Boolean; inline;
function MaskF32x4Select(const m: TMaskF32x4; const a, b: TVecF32x4): TVecF32x4; inline;

function MaskF64x2AllTrue: TMaskF64x2; inline;
function MaskF64x2AllFalse: TMaskF64x2; inline;
function MaskF64x2ToBitmask(const m: TMaskF64x2): TMask2; inline;

function MaskI32x4AllTrue: TMaskI32x4; inline;
function MaskI32x4AllFalse: TMaskI32x4; inline;
function MaskI32x4ToBitmask(const m: TMaskI32x4): TMask4; inline;

// 512-bit 掩码函数 (AVX-512)
function MaskF32x16AllTrue: TMaskF32x16; inline;
function MaskF32x16AllFalse: TMaskF32x16; inline;
function MaskF32x16ToBitmask(const m: TMaskF32x16): TMask16; inline;
function MaskF32x16Any(const m: TMaskF32x16): Boolean; inline;
function MaskF32x16All(const m: TMaskF32x16): Boolean; inline;
function MaskF32x16None(const m: TMaskF32x16): Boolean; inline;
function MaskF32x16FromBitmask(bm: TMask16): TMaskF32x16; inline;
function MaskF32x16Select(const m: TMaskF32x16; const a, b: TVecF32x16): TVecF32x16; inline;

// 512-bit 向量比较函数 (Phase 4)
function VecF32x16CmpEq(const a, b: TVecF32x16): TMaskF32x16; inline;
function VecF32x16CmpNe(const a, b: TVecF32x16): TMaskF32x16; inline;
function VecF32x16CmpLt(const a, b: TVecF32x16): TMaskF32x16; inline;
function VecF32x16CmpLe(const a, b: TVecF32x16): TMaskF32x16; inline;
function VecF32x16CmpGt(const a, b: TVecF32x16): TMaskF32x16; inline;
function VecF32x16CmpGe(const a, b: TVecF32x16): TMaskF32x16; inline;

function VecI32x16CmpEq(const a, b: TVecI32x16): TMaskI32x16; inline;
function VecI32x16CmpLt(const a, b: TVecI32x16): TMaskI32x16; inline;
function VecI32x16CmpGt(const a, b: TVecI32x16): TMaskI32x16; inline;

// 512-bit 掩码逻辑运算符
operator and (const a, b: TMaskF32x16): TMaskF32x16; inline;
operator or (const a, b: TMaskF32x16): TMaskF32x16; inline;
operator xor (const a, b: TMaskF32x16): TMaskF32x16; inline;
operator not (const a: TMaskF32x16): TMaskF32x16; inline;

// TMaskF32x4 逻辑运算符
operator and (const a, b: TMaskF32x4): TMaskF32x4; inline;
operator or (const a, b: TMaskF32x4): TMaskF32x4; inline;
operator xor (const a, b: TMaskF32x4): TMaskF32x4; inline;
operator not (const a: TMaskF32x4): TMaskF32x4; inline;

// === 类型转换函数 (Phase 1.4) ===
// IntoBits / FromBits - 位模式重新解释（不改变位）
function VecF32x4IntoBits(const a: TVecF32x4): TVecI32x4; inline;
function VecI32x4FromBitsF32(const a: TVecI32x4): TVecF32x4; inline;
function VecF64x2IntoBits(const a: TVecF64x2): TVecI64x2; inline;
function VecI64x2FromBitsF64(const a: TVecI64x2): TVecF64x2; inline;

// Cast - 元素级别转换（数值转换）
function VecF32x4CastToI32x4(const a: TVecF32x4): TVecI32x4; inline;
function VecI32x4CastToF32x4(const a: TVecI32x4): TVecF32x4; inline;
function VecF64x2CastToI64x2(const a: TVecF64x2): TVecI64x2; inline;
function VecI64x2CastToF64x2(const a: TVecI64x2): TVecF64x2; inline;

// Widen - 扩展宽度
function VecI16x8WidenLoI32x4(const a: TVecI16x8): TVecI32x4; inline;
function VecI16x8WidenHiI32x4(const a: TVecI16x8): TVecI32x4; inline;

// Narrow - 缩小宽度（截断）
function VecI32x4NarrowToI16x8(const a, b: TVecI32x4): TVecI16x8; inline;

// 精度转换 F32 <-> F64
function VecF32x4ToF64x2Lo(const a: TVecF32x4): TVecF64x2; inline;
function VecF64x2ToF32x4(const a, b: TVecF64x2): TVecF32x4; inline;

// === Shuffle/Swizzle 函数 (Phase 2) ===
// Shuffle - 根据索引重排元素
// imm8 格式: 每 2 bit 选择一个源元素索引 (0-3)
// 例如: _MM_SHUFFLE(3,2,1,0) = 0xE4 表示不变
//       _MM_SHUFFLE(0,0,0,0) = 0x00 表示广播元素 0
function VecF32x4Shuffle(const a: TVecF32x4; imm8: Byte): TVecF32x4; inline;
function VecI32x4Shuffle(const a: TVecI32x4; imm8: Byte): TVecI32x4; inline;

// Shuffle2 - 从两个向量中选择元素
// 低 2 元素来自 a, 高 2 元素来自 b
function VecF32x4Shuffle2(const a, b: TVecF32x4; imm8: Byte): TVecF32x4; inline;

// Blend - 根据掩码混合两个向量
// mask bit=0 选择 a, bit=1 选择 b
function VecF32x4Blend(const a, b: TVecF32x4; mask: Byte): TVecF32x4; inline;
function VecF64x2Blend(const a, b: TVecF64x2; mask: Byte): TVecF64x2; inline;
function VecI32x4Blend(const a, b: TVecI32x4; mask: Byte): TVecI32x4; inline;

// Interleave - 交织两个向量的元素
// UnpackLo: [a0, b0, a1, b1]
// UnpackHi: [a2, b2, a3, b3]
function VecF32x4UnpackLo(const a, b: TVecF32x4): TVecF32x4; inline;
function VecF32x4UnpackHi(const a, b: TVecF32x4): TVecF32x4; inline;
function VecI32x4UnpackLo(const a, b: TVecI32x4): TVecI32x4; inline;
function VecI32x4UnpackHi(const a, b: TVecI32x4): TVecI32x4; inline;

// Broadcast - 将单个元素广播到所有位置
function VecF32x4Broadcast(const a: TVecF32x4; index: Integer): TVecF32x4; inline;
function VecI32x4Broadcast(const a: TVecI32x4; index: Integer): TVecI32x4; inline;

// Reverse - 反转元素顺序
function VecF32x4Reverse(const a: TVecF32x4): TVecF32x4; inline;
function VecI32x4Reverse(const a: TVecI32x4): TVecI32x4; inline;

// Rotate - 循环旋转元素 (左移 n 个元素)
function VecF32x4RotateLeft(const a: TVecF32x4; n: Integer): TVecF32x4; inline;
function VecI32x4RotateLeft(const a: TVecI32x4; n: Integer): TVecI32x4; inline;

// Insert/Extract - 插入和提取单个元素
function VecF32x4Insert(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4; inline;
function VecI32x4Insert(const a: TVecI32x4; value: Int32; index: Integer): TVecI32x4; inline;
function VecF32x4Extract(const a: TVecF32x4; index: Integer): Single; inline;
function VecI32x4Extract(const a: TVecI32x4; index: Integer): Int32; inline;

// 辅助宏: 生成 shuffle 立即数
// MM_SHUFFLE(d, c, b, a) = (d << 6) | (c << 4) | (b << 2) | a
function MM_SHUFFLE(d, c, b, a: Byte): Byte; inline;

// === Gather/Scatter 函数 (Phase 2.2) ===
// Gather - 从不连续内存位置收集数据到向量
// base: 基地址指针
// indices: 索引向量，每个元素是相对于 base 的元素偏移量
// 返回: 从 base[indices[i]] 收集的值组成的向量
function VecF32x4Gather(base: PSingle; const indices: TVecI32x4): TVecF32x4; inline;
function VecI32x4Gather(base: PInt32; const indices: TVecI32x4): TVecI32x4; inline;

// Scatter - 将向量数据分散到不连续内存位置
// base: 基地址指针
// indices: 索引向量，每个元素是相对于 base 的元素偏移量
// values: 要写入的值
// 效果: base[indices[i]] := values[i]
procedure VecF32x4Scatter(base: PSingle; const indices: TVecI32x4; const values: TVecF32x4); inline;
procedure VecI32x4Scatter(base: PInt32; const indices: TVecI32x4; const values: TVecI32x4); inline;

// === SIMD 数学函数 (Phase 4) ===
// 三角函数
function VecF32x4Sin(const a: TVecF32x4): TVecF32x4; inline;
function VecF32x4Cos(const a: TVecF32x4): TVecF32x4; inline;
procedure VecF32x4SinCos(const a: TVecF32x4; out sinResult, cosResult: TVecF32x4);
function VecF32x4Tan(const a: TVecF32x4): TVecF32x4; inline;

// 指数/对数函数
function VecF32x4Exp(const a: TVecF32x4): TVecF32x4; inline;
function VecF32x4Exp2(const a: TVecF32x4): TVecF32x4; inline;
function VecF32x4Log(const a: TVecF32x4): TVecF32x4; inline;
function VecF32x4Log2(const a: TVecF32x4): TVecF32x4; inline;
function VecF32x4Log10(const a: TVecF32x4): TVecF32x4; inline;
function VecF32x4Pow(const base, exponent: TVecF32x4): TVecF32x4; inline;

// 反三角函数
function VecF32x4Asin(const a: TVecF32x4): TVecF32x4; inline;
function VecF32x4Acos(const a: TVecF32x4): TVecF32x4; inline;
function VecF32x4Atan(const a: TVecF32x4): TVecF32x4; inline;
function VecF32x4Atan2(const y, x: TVecF32x4): TVecF32x4; inline;

// === 高级算法 (Phase 5) ===
// 排序网络 - SIMD 友好的小数组排序
function SortNet4I32(const a: TVecI32x4; ascending: Boolean = True): TVecI32x4;
function SortNet4F32(const a: TVecF32x4; ascending: Boolean = True): TVecF32x4;
function SortNet8I32(const a: TVecI32x8; ascending: Boolean = True): TVecI32x8;

// 前缀和 (Prefix Sum / Scan)
function PrefixSumI32x4(const a: TVecI32x4; inclusive: Boolean = True): TVecI32x4;
function PrefixSumF32x4(const a: TVecF32x4; inclusive: Boolean = True): TVecF32x4;
procedure PrefixSumArrayI32(src, dst: PInt32; count: SizeUInt);
procedure PrefixSumArrayF32(src, dst: PSingle; count: SizeUInt);

// 向量化字符串搜索
function StrFindChar(p: Pointer; len: SizeUInt; ch: Byte): PtrInt;

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

// === 256-bit 向量运算符 (Phase 2) ===
// TVecF32x8 运算符
operator + (const a, b: TVecF32x8): TVecF32x8; inline;
operator - (const a, b: TVecF32x8): TVecF32x8; inline;
operator * (const a, b: TVecF32x8): TVecF32x8; inline;
operator / (const a, b: TVecF32x8): TVecF32x8; inline;
operator - (const a: TVecF32x8): TVecF32x8; inline;

// TVecF64x4 运算符
operator + (const a, b: TVecF64x4): TVecF64x4; inline;
operator - (const a, b: TVecF64x4): TVecF64x4; inline;
operator * (const a, b: TVecF64x4): TVecF64x4; inline;
operator / (const a, b: TVecF64x4): TVecF64x4; inline;
operator - (const a: TVecF64x4): TVecF64x4; inline;

// TVecI32x8 运算符
operator + (const a, b: TVecI32x8): TVecI32x8; inline;
operator - (const a, b: TVecI32x8): TVecI32x8; inline;
operator - (const a: TVecI32x8): TVecI32x8; inline;

// === 512-bit 向量运算符 (AVX-512) ===
// TVecF32x16 运算符
operator + (const a, b: TVecF32x16): TVecF32x16; inline;
operator - (const a, b: TVecF32x16): TVecF32x16; inline;
operator * (const a, b: TVecF32x16): TVecF32x16; inline;
operator / (const a, b: TVecF32x16): TVecF32x16; inline;
operator - (const a: TVecF32x16): TVecF32x16; inline;

// TVecF64x8 运算符
operator + (const a, b: TVecF64x8): TVecF64x8; inline;
operator - (const a, b: TVecF64x8): TVecF64x8; inline;
operator * (const a, b: TVecF64x8): TVecF64x8; inline;
operator / (const a, b: TVecF64x8): TVecF64x8; inline;
operator - (const a: TVecF64x8): TVecF64x8; inline;

// TVecI32x16 运算符
operator + (const a, b: TVecI32x16): TVecI32x16; inline;
operator - (const a, b: TVecI32x16): TVecI32x16; inline;
operator - (const a: TVecI32x16): TVecI32x16; inline;

// Duplicate identifiers removed (they were already defined via aliases above or in leftover code?)
// No, the error says duplicate identifier "TSimdElementType" at 330
// Let's remove the duplicate definitions that are still present later in the file.

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

// === Shuffle/Swizzle 实现 (Phase 2, Scalar 参考) ===
function MM_SHUFFLE(d, c, b, a: Byte): Byte; inline;
begin
  Result := (d shl 6) or (c shl 4) or (b shl 2) or a;
end;

function _pick4(const idx: Byte; const a: TVecF32x4): TVecF32x4;
var sel: array[0..3] of Byte;
begin
  sel[0] := idx and $3;
  sel[1] := (idx shr 2) and $3;
  sel[2] := (idx shr 4) and $3;
  sel[3] := (idx shr 6) and $3;
  Result.f[0] := a.f[sel[0]];
  Result.f[1] := a.f[sel[1]];
  Result.f[2] := a.f[sel[2]];
  Result.f[3] := a.f[sel[3]];
end;

function _pick4i(const idx: Byte; const a: TVecI32x4): TVecI32x4;
var sel: array[0..3] of Byte;
begin
  sel[0] := idx and $3;
  sel[1] := (idx shr 2) and $3;
  sel[2] := (idx shr 4) and $3;
  sel[3] := (idx shr 6) and $3;
  Result.i[0] := a.i[sel[0]];
  Result.i[1] := a.i[sel[1]];
  Result.i[2] := a.i[sel[2]];
  Result.i[3] := a.i[sel[3]];
end;

function VecF32x4Shuffle(const a: TVecF32x4; imm8: Byte): TVecF32x4;
begin
  Result := _pick4(imm8, a);
end;

function VecI32x4Shuffle(const a: TVecI32x4; imm8: Byte): TVecI32x4;
begin
  Result := _pick4i(imm8, a);
end;

function VecF32x4Shuffle2(const a, b: TVecF32x4; imm8: Byte): TVecF32x4;
var sel: array[0..3] of Byte;
    src: array[0..3] of Single;
begin
  // 低 2 来自 a, 高 2 来自 b
  sel[0] := imm8 and $3;
  sel[1] := (imm8 shr 2) and $3;
  sel[2] := (imm8 shr 4) and $3;
  sel[3] := (imm8 shr 6) and $3;
  src[0] := a.f[sel[0]];
  src[1] := a.f[sel[1]];
  src[2] := b.f[sel[2]];
  src[3] := b.f[sel[3]];
  Result.f[0] := src[0];
  Result.f[1] := src[1];
  Result.f[2] := src[2];
  Result.f[3] := src[3];
end;

function VecF32x4Blend(const a, b: TVecF32x4; mask: Byte): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if ((mask shr i) and 1) <> 0 then
      Result.f[i] := b.f[i]
    else
      Result.f[i] := a.f[i];
end;

function VecF64x2Blend(const a, b: TVecF64x2; mask: Byte): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    if ((mask shr i) and 1) <> 0 then
      Result.d[i] := b.d[i]
    else
      Result.d[i] := a.d[i];
end;

function VecI32x4Blend(const a, b: TVecI32x4; mask: Byte): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if ((mask shr i) and 1) <> 0 then
      Result.i[i] := b.i[i]
    else
      Result.i[i] := a.i[i];
end;

function VecF32x4UnpackLo(const a, b: TVecF32x4): TVecF32x4;
begin
  Result.f[0] := a.f[0]; Result.f[1] := b.f[0];
  Result.f[2] := a.f[1]; Result.f[3] := b.f[1];
end;

function VecF32x4UnpackHi(const a, b: TVecF32x4): TVecF32x4;
begin
  Result.f[0] := a.f[2]; Result.f[1] := b.f[2];
  Result.f[2] := a.f[3]; Result.f[3] := b.f[3];
end;

function VecI32x4UnpackLo(const a, b: TVecI32x4): TVecI32x4;
begin
  Result.i[0] := a.i[0]; Result.i[1] := b.i[0];
  Result.i[2] := a.i[1]; Result.i[3] := b.i[1];
end;

function VecI32x4UnpackHi(const a, b: TVecI32x4): TVecI32x4;
begin
  Result.i[0] := a.i[2]; Result.i[1] := b.i[2];
  Result.i[2] := a.i[3]; Result.i[3] := b.i[3];
end;

function VecF32x4Broadcast(const a: TVecF32x4; index: Integer): TVecF32x4;
var v: Single;
begin
  v := a.f[index and 3];
  Result.f[0] := v; Result.f[1] := v; Result.f[2] := v; Result.f[3] := v;
end;

function VecI32x4Broadcast(const a: TVecI32x4; index: Integer): TVecI32x4;
var v: Int32;
begin
  v := a.i[index and 3];
  Result.i[0] := v; Result.i[1] := v; Result.i[2] := v; Result.i[3] := v;
end;

function VecF32x4Reverse(const a: TVecF32x4): TVecF32x4;
begin
  Result.f[0] := a.f[3];
  Result.f[1] := a.f[2];
  Result.f[2] := a.f[1];
  Result.f[3] := a.f[0];
end;

function VecI32x4Reverse(const a: TVecI32x4): TVecI32x4;
begin
  Result.i[0] := a.i[3];
  Result.i[1] := a.i[2];
  Result.i[2] := a.i[1];
  Result.i[3] := a.i[0];
end;

function VecF32x4RotateLeft(const a: TVecF32x4; n: Integer): TVecF32x4;
var k: Integer;
begin
  k := (n and 3);
  Result.f[0] := a.f[(0 + k) and 3];
  Result.f[1] := a.f[(1 + k) and 3];
  Result.f[2] := a.f[(2 + k) and 3];
  Result.f[3] := a.f[(3 + k) and 3];
end;

function VecI32x4RotateLeft(const a: TVecI32x4; n: Integer): TVecI32x4;
var k: Integer;
begin
  k := (n and 3);
  Result.i[0] := a.i[(0 + k) and 3];
  Result.i[1] := a.i[(1 + k) and 3];
  Result.i[2] := a.i[(2 + k) and 3];
  Result.i[3] := a.i[(3 + k) and 3];
end;

function VecF32x4Insert(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4;
begin
  Result := a;
  Result.f[index and 3] := value;
end;

function VecI32x4Insert(const a: TVecI32x4; value: Int32; index: Integer): TVecI32x4;
begin
  Result := a;
  Result.i[index and 3] := value;
end;

function VecF32x4Extract(const a: TVecF32x4; index: Integer): Single;
begin
  Result := a.f[index and 3];
end;

function VecI32x4Extract(const a: TVecI32x4; index: Integer): Int32;
begin
  Result := a.i[index and 3];
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
// Note: Integer SIMD operations should wrap around on overflow (like hardware)

{$PUSH}{$R-}{$Q-}  // Disable range/overflow checks for wraparound semantics
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
{$POP}

// === TVecF32x8 运算符实现 (256-bit) ===

operator + (const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := a.f[i] + b.f[i];
end;

operator - (const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := a.f[i] - b.f[i];
end;

operator * (const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := a.f[i] * b.f[i];
end;

operator / (const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := a.f[i] / b.f[i];
end;

operator - (const a: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := -a.f[i];
end;

// === TVecF64x4 运算符实现 (256-bit) ===

operator + (const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := a.d[i] + b.d[i];
end;

operator - (const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := a.d[i] - b.d[i];
end;

operator * (const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := a.d[i] * b.d[i];
end;

operator / (const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := a.d[i] / b.d[i];
end;

operator - (const a: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := -a.d[i];
end;

// === TVecI32x8 运算符实现 (256-bit) ===

operator + (const a, b: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] + b.i[i];
end;

operator - (const a, b: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] - b.i[i];
end;

operator - (const a: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := -a.i[i];
end;

// === TVecF32x16 运算符实现 (512-bit AVX-512) ===

operator + (const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := a.f[i] + b.f[i];
end;

operator - (const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := a.f[i] - b.f[i];
end;

operator * (const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := a.f[i] * b.f[i];
end;

operator / (const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := a.f[i] / b.f[i];
end;

operator - (const a: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := -a.f[i];
end;

// === TVecF64x8 运算符实现 (512-bit AVX-512) ===

operator + (const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := a.d[i] + b.d[i];
end;

operator - (const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := a.d[i] - b.d[i];
end;

operator * (const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := a.d[i] * b.d[i];
end;

operator / (const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := a.d[i] / b.d[i];
end;

operator - (const a: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := -a.d[i];
end;

// === TVecI32x16 运算符实现 (512-bit AVX-512) ===

operator + (const a, b: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] + b.i[i];
end;

operator - (const a, b: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] - b.i[i];
end;

operator - (const a: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := -a.i[i];
end;

// === TMaskF32x4 函数实现 ===

function MaskF32x4AllTrue: TMaskF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.m[i] := $FFFFFFFF;
end;

function MaskF32x4AllFalse: TMaskF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.m[i] := 0;
end;

function MaskF32x4Set(m0, m1, m2, m3: Boolean): TMaskF32x4;
begin
  if m0 then Result.m[0] := $FFFFFFFF else Result.m[0] := 0;
  if m1 then Result.m[1] := $FFFFFFFF else Result.m[1] := 0;
  if m2 then Result.m[2] := $FFFFFFFF else Result.m[2] := 0;
  if m3 then Result.m[3] := $FFFFFFFF else Result.m[3] := 0;
end;

function MaskF32x4Test(const m: TMaskF32x4; index: Integer): Boolean;
begin
  Result := m.m[index] <> 0;
end;

function MaskF32x4ToBitmask(const m: TMaskF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if m.m[i] <> 0 then
      Result := Result or (1 shl i);
end;

function MaskF32x4Any(const m: TMaskF32x4): Boolean;
begin
  Result := (m.m[0] or m.m[1] or m.m[2] or m.m[3]) <> 0;
end;

function MaskF32x4All(const m: TMaskF32x4): Boolean;
begin
  Result := (m.m[0] and m.m[1] and m.m[2] and m.m[3]) = $FFFFFFFF;
end;

function MaskF32x4None(const m: TMaskF32x4): Boolean;
begin
  Result := (m.m[0] or m.m[1] or m.m[2] or m.m[3]) = 0;
end;

function MaskF32x4Select(const m: TMaskF32x4; const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if m.m[i] <> 0 then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

// === TMaskF64x2 函数实现 ===

function MaskF64x2AllTrue: TMaskF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.m[i] := High(UInt64);
end;

function MaskF64x2AllFalse: TMaskF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.m[i] := 0;
end;

function MaskF64x2ToBitmask(const m: TMaskF64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if m.m[i] <> 0 then
      Result := Result or (1 shl i);
end;

// === TMaskI32x4 函数实现 ===

function MaskI32x4AllTrue: TMaskI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.m[i] := $FFFFFFFF;
end;

function MaskI32x4AllFalse: TMaskI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.m[i] := 0;
end;

function MaskI32x4ToBitmask(const m: TMaskI32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if m.m[i] <> 0 then
      Result := Result or (1 shl i);
end;

// === TMaskF32x16 函数实现 (AVX-512) ===

function MaskF32x16AllTrue: TMaskF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.m[i] := $FFFFFFFF;
  Result.bits := $FFFF;
end;

function MaskF32x16AllFalse: TMaskF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.m[i] := 0;
  Result.bits := 0;
end;

function MaskF32x16ToBitmask(const m: TMaskF32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if m.m[i] <> 0 then
      Result := Result or (1 shl i);
end;

function MaskF32x16Any(const m: TMaskF32x16): Boolean;
var i: Integer;
begin
  for i := 0 to 15 do
    if m.m[i] <> 0 then
      Exit(True);
  Result := False;
end;

function MaskF32x16All(const m: TMaskF32x16): Boolean;
var i: Integer;
begin
  for i := 0 to 15 do
    if m.m[i] <> $FFFFFFFF then
      Exit(False);
  Result := True;
end;

function MaskF32x16None(const m: TMaskF32x16): Boolean;
var i: Integer;
begin
  for i := 0 to 15 do
    if m.m[i] <> 0 then
      Exit(False);
  Result := True;
end;

function MaskF32x16FromBitmask(bm: TMask16): TMaskF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if (bm and (1 shl i)) <> 0 then
      Result.m[i] := $FFFFFFFF
    else
      Result.m[i] := 0;
  Result.bits := bm;
end;

function MaskF32x16Select(const m: TMaskF32x16; const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if m.m[i] <> 0 then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

// === 512-bit 向量比较函数实现 (Phase 4) ===

function VecF32x16CmpEq(const a, b: TVecF32x16): TMaskF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.f[i] = b.f[i] then
      Result.m[i] := $FFFFFFFF
    else
      Result.m[i] := 0;
  Result.bits := MaskF32x16ToBitmask(Result);
end;

function VecF32x16CmpNe(const a, b: TVecF32x16): TMaskF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.f[i] <> b.f[i] then
      Result.m[i] := $FFFFFFFF
    else
      Result.m[i] := 0;
  Result.bits := MaskF32x16ToBitmask(Result);
end;

function VecF32x16CmpLt(const a, b: TVecF32x16): TMaskF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.f[i] < b.f[i] then
      Result.m[i] := $FFFFFFFF
    else
      Result.m[i] := 0;
  Result.bits := MaskF32x16ToBitmask(Result);
end;

function VecF32x16CmpLe(const a, b: TVecF32x16): TMaskF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.f[i] <= b.f[i] then
      Result.m[i] := $FFFFFFFF
    else
      Result.m[i] := 0;
  Result.bits := MaskF32x16ToBitmask(Result);
end;

function VecF32x16CmpGt(const a, b: TVecF32x16): TMaskF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.f[i] > b.f[i] then
      Result.m[i] := $FFFFFFFF
    else
      Result.m[i] := 0;
  Result.bits := MaskF32x16ToBitmask(Result);
end;

function VecF32x16CmpGe(const a, b: TVecF32x16): TMaskF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.f[i] >= b.f[i] then
      Result.m[i] := $FFFFFFFF
    else
      Result.m[i] := 0;
  Result.bits := MaskF32x16ToBitmask(Result);
end;

function VecI32x16CmpEq(const a, b: TVecI32x16): TMaskI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.i[i] = b.i[i] then
      Result.m[i] := $FFFFFFFF
    else
      Result.m[i] := 0;
  Result.bits := 0;
  for i := 0 to 15 do
    if Result.m[i] <> 0 then
      Result.bits := Result.bits or (1 shl i);
end;

function VecI32x16CmpLt(const a, b: TVecI32x16): TMaskI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.i[i] < b.i[i] then
      Result.m[i] := $FFFFFFFF
    else
      Result.m[i] := 0;
  Result.bits := 0;
  for i := 0 to 15 do
    if Result.m[i] <> 0 then
      Result.bits := Result.bits or (1 shl i);
end;

function VecI32x16CmpGt(const a, b: TVecI32x16): TMaskI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.i[i] > b.i[i] then
      Result.m[i] := $FFFFFFFF
    else
      Result.m[i] := 0;
  Result.bits := 0;
  for i := 0 to 15 do
    if Result.m[i] <> 0 then
      Result.bits := Result.bits or (1 shl i);
end;

// === TMaskF32x16 逻辑运算符实现 ===

operator and (const a, b: TMaskF32x16): TMaskF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.m[i] := a.m[i] and b.m[i];
  Result.bits := a.bits and b.bits;
end;

operator or (const a, b: TMaskF32x16): TMaskF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.m[i] := a.m[i] or b.m[i];
  Result.bits := a.bits or b.bits;
end;

operator xor (const a, b: TMaskF32x16): TMaskF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.m[i] := a.m[i] xor b.m[i];
  Result.bits := a.bits xor b.bits;
end;

operator not (const a: TMaskF32x16): TMaskF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.m[i] := not a.m[i];
  Result.bits := not a.bits;
end;

// === TMaskF32x4 逻辑运算符实现 ===

operator and (const a, b: TMaskF32x4): TMaskF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.m[i] := a.m[i] and b.m[i];
end;

operator or (const a, b: TMaskF32x4): TMaskF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.m[i] := a.m[i] or b.m[i];
end;

operator xor (const a, b: TMaskF32x4): TMaskF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.m[i] := a.m[i] xor b.m[i];
end;

operator not (const a: TMaskF32x4): TMaskF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.m[i] := not a.m[i];
end;

// === 类型转换函数实现 (Phase 1.4) ===

// IntoBits / FromBits - 位模式重新解释
function VecF32x4IntoBits(const a: TVecF32x4): TVecI32x4;
begin
  // Bit reinterpretation (same 16 bytes, different view)
  Result.raw := a.raw;
end;

function VecI32x4FromBitsF32(const a: TVecI32x4): TVecF32x4;
begin
  // Bit reinterpretation (same 16 bytes, different view)
  Result.raw := a.raw;
end;

function VecF64x2IntoBits(const a: TVecF64x2): TVecI64x2;
begin
  // Bit reinterpretation (same 16 bytes, different view)
  Result.raw := a.raw;
end;

function VecI64x2FromBitsF64(const a: TVecI64x2): TVecF64x2;
begin
  // Bit reinterpretation (same 16 bytes, different view)
  Result.raw := a.raw;
end;

// Cast - 元素级别转换（数值转换）
function VecF32x4CastToI32x4(const a: TVecF32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := Trunc(a.f[i]);
end;

function VecI32x4CastToF32x4(const a: TVecI32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.i[i];
end;

function VecF64x2CastToI64x2(const a: TVecF64x2): TVecI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.i[i] := Trunc(a.d[i]);
end;

function VecI64x2CastToF64x2(const a: TVecI64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.i[i];
end;

// Widen - 扩展宽度（符号扩展）
function VecI16x8WidenLoI32x4(const a: TVecI16x8): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i];  // 低 4 个元素，Int16 自动符号扩展到 Int32
end;

function VecI16x8WidenHiI32x4(const a: TVecI16x8): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i + 4];  // 高 4 个元素
end;

// Narrow - 缩小宽度（截断到 Int16 范围）
function VecI32x4NarrowToI16x8(const a, b: TVecI32x4): TVecI16x8;
var i: Integer;
begin
  // a -> 低 4 元素, b -> 高 4 元素
  for i := 0 to 3 do
    Result.i[i] := Int16(a.i[i]);  // 截断
  for i := 0 to 3 do
    Result.i[i + 4] := Int16(b.i[i]);
end;

// 精度转换 F32 <-> F64
function VecF32x4ToF64x2Lo(const a: TVecF32x4): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.f[i];  // 取低 2 个 F32 扩展到 F64
end;

function VecF64x2ToF32x4(const a, b: TVecF64x2): TVecF32x4;
var i: Integer;
begin
  // a -> 低 2 元素, b -> 高 2 元素
  for i := 0 to 1 do
    Result.f[i] := Single(a.d[i]);
  for i := 0 to 1 do
    Result.f[i + 2] := Single(b.d[i]);
end;

// === SIMD 数学函数实现 (Phase 4) ===
// 使用标量 Math 单元提供参考实现

function VecF32x4Sin(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Sin(a.f[i]);
end;

function VecF32x4Cos(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Cos(a.f[i]);
end;

procedure VecF32x4SinCos(const a: TVecF32x4; out sinResult, cosResult: TVecF32x4);
var i: Integer;
begin
  for i := 0 to 3 do
  begin
    sinResult.f[i] := Sin(a.f[i]);
    cosResult.f[i] := Cos(a.f[i]);
  end;
end;

function VecF32x4Tan(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Tan(a.f[i]);
end;

function VecF32x4Exp(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Exp(a.f[i]);
end;

function VecF32x4Exp2(const a: TVecF32x4): TVecF32x4;
const LN2 = 0.6931471805599453;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Exp(a.f[i] * LN2);
end;

function VecF32x4Log(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Ln(a.f[i]);
end;

function VecF32x4Log2(const a: TVecF32x4): TVecF32x4;
const INV_LN2 = 1.4426950408889634;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Ln(a.f[i]) * INV_LN2;
end;

function VecF32x4Log10(const a: TVecF32x4): TVecF32x4;
const INV_LN10 = 0.4342944819032518;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Ln(a.f[i]) * INV_LN10;
end;

function VecF32x4Pow(const base, exponent: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if base.f[i] > 0 then
      Result.f[i] := Exp(exponent.f[i] * Ln(base.f[i]))
    else if base.f[i] = 0 then
      Result.f[i] := 0
    else
      Result.f[i] := 0/0;  // NaN for negative base
end;

function VecF32x4Asin(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := ArcSin(a.f[i]);
end;

function VecF32x4Acos(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := ArcCos(a.f[i]);
end;

function VecF32x4Atan(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := ArcTan(a.f[i]);
end;

function VecF32x4Atan2(const y, x: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := ArcTan2(y.f[i], x.f[i]);
end;

// === 高级算法实现 (Phase 5) ===

// 排序网络 - 4 元素排序 (Batcher's odd-even mergesort)
// 使用 5 次比较交换操作
function SortNet4I32(const a: TVecI32x4; ascending: Boolean): TVecI32x4;
var
  tmp: Int32;
begin
  Result := a;
  if ascending then
  begin
    // 比较交换对: (0,1), (2,3), (0,2), (1,3), (1,2)
    if Result.i[0] > Result.i[1] then begin tmp := Result.i[0]; Result.i[0] := Result.i[1]; Result.i[1] := tmp; end;
    if Result.i[2] > Result.i[3] then begin tmp := Result.i[2]; Result.i[2] := Result.i[3]; Result.i[3] := tmp; end;
    if Result.i[0] > Result.i[2] then begin tmp := Result.i[0]; Result.i[0] := Result.i[2]; Result.i[2] := tmp; end;
    if Result.i[1] > Result.i[3] then begin tmp := Result.i[1]; Result.i[1] := Result.i[3]; Result.i[3] := tmp; end;
    if Result.i[1] > Result.i[2] then begin tmp := Result.i[1]; Result.i[1] := Result.i[2]; Result.i[2] := tmp; end;
  end
  else
  begin
    // 降序
    if Result.i[0] < Result.i[1] then begin tmp := Result.i[0]; Result.i[0] := Result.i[1]; Result.i[1] := tmp; end;
    if Result.i[2] < Result.i[3] then begin tmp := Result.i[2]; Result.i[2] := Result.i[3]; Result.i[3] := tmp; end;
    if Result.i[0] < Result.i[2] then begin tmp := Result.i[0]; Result.i[0] := Result.i[2]; Result.i[2] := tmp; end;
    if Result.i[1] < Result.i[3] then begin tmp := Result.i[1]; Result.i[1] := Result.i[3]; Result.i[3] := tmp; end;
    if Result.i[1] < Result.i[2] then begin tmp := Result.i[1]; Result.i[1] := Result.i[2]; Result.i[2] := tmp; end;
  end;
end;

function SortNet4F32(const a: TVecF32x4; ascending: Boolean): TVecF32x4;
var
  tmp: Single;
begin
  Result := a;
  if ascending then
  begin
    if Result.f[0] > Result.f[1] then begin tmp := Result.f[0]; Result.f[0] := Result.f[1]; Result.f[1] := tmp; end;
    if Result.f[2] > Result.f[3] then begin tmp := Result.f[2]; Result.f[2] := Result.f[3]; Result.f[3] := tmp; end;
    if Result.f[0] > Result.f[2] then begin tmp := Result.f[0]; Result.f[0] := Result.f[2]; Result.f[2] := tmp; end;
    if Result.f[1] > Result.f[3] then begin tmp := Result.f[1]; Result.f[1] := Result.f[3]; Result.f[3] := tmp; end;
    if Result.f[1] > Result.f[2] then begin tmp := Result.f[1]; Result.f[1] := Result.f[2]; Result.f[2] := tmp; end;
  end
  else
  begin
    if Result.f[0] < Result.f[1] then begin tmp := Result.f[0]; Result.f[0] := Result.f[1]; Result.f[1] := tmp; end;
    if Result.f[2] < Result.f[3] then begin tmp := Result.f[2]; Result.f[2] := Result.f[3]; Result.f[3] := tmp; end;
    if Result.f[0] < Result.f[2] then begin tmp := Result.f[0]; Result.f[0] := Result.f[2]; Result.f[2] := tmp; end;
    if Result.f[1] < Result.f[3] then begin tmp := Result.f[1]; Result.f[1] := Result.f[3]; Result.f[3] := tmp; end;
    if Result.f[1] < Result.f[2] then begin tmp := Result.f[1]; Result.f[1] := Result.f[2]; Result.f[2] := tmp; end;
  end;
end;

function SortNet8I32(const a: TVecI32x8; ascending: Boolean): TVecI32x8;
var
  tmp: Int32;
  i, j: Integer;
begin
  Result := a;
  // 简化实现：先排序两个 4 元素组，然后合并
  // 先对 lo 和 hi 分别排序
  Result.lo := SortNet4I32(Result.lo, ascending);
  Result.hi := SortNet4I32(Result.hi, ascending);
  
  // 合并两个有序数组 (双调合并)
  if ascending then
  begin
    // 比较交换跨 lo/hi 的元素
    for i := 0 to 3 do
    begin
      if Result.i[i] > Result.i[i + 4] then
      begin
        tmp := Result.i[i]; Result.i[i] := Result.i[i + 4]; Result.i[i + 4] := tmp;
      end;
    end;
    // 继续排序两半
    for i := 1 to 3 do
      for j := i downto 1 do
        if Result.i[j-1] > Result.i[j] then
        begin
          tmp := Result.i[j-1]; Result.i[j-1] := Result.i[j]; Result.i[j] := tmp;
        end;
    for i := 5 to 7 do
      for j := i downto 5 do
        if Result.i[j-1] > Result.i[j] then
        begin
          tmp := Result.i[j-1]; Result.i[j-1] := Result.i[j]; Result.i[j] := tmp;
        end;
    // 最后一遍合并
    for i := 1 to 6 do
      for j := i downto 1 do
        if Result.i[j-1] > Result.i[j] then
        begin
          tmp := Result.i[j-1]; Result.i[j-1] := Result.i[j]; Result.i[j] := tmp;
        end;
  end
  else
  begin
    for i := 0 to 3 do
    begin
      if Result.i[i] < Result.i[i + 4] then
      begin
        tmp := Result.i[i]; Result.i[i] := Result.i[i + 4]; Result.i[i + 4] := tmp;
      end;
    end;
    for i := 1 to 6 do
      for j := i downto 1 do
        if Result.i[j-1] < Result.i[j] then
        begin
          tmp := Result.i[j-1]; Result.i[j-1] := Result.i[j]; Result.i[j] := tmp;
        end;
  end;
end;

// 前缀和 - 4 元素向量
{$PUSH}{$R-}{$Q-}  // Disable overflow checks for wraparound semantics
function PrefixSumI32x4(const a: TVecI32x4; inclusive: Boolean): TVecI32x4;
begin
  if inclusive then
  begin
    // inclusive: [a0, a0+a1, a0+a1+a2, a0+a1+a2+a3]
    Result.i[0] := a.i[0];
    Result.i[1] := a.i[0] + a.i[1];
    Result.i[2] := a.i[0] + a.i[1] + a.i[2];
    Result.i[3] := a.i[0] + a.i[1] + a.i[2] + a.i[3];
  end
  else
  begin
    // exclusive: [0, a0, a0+a1, a0+a1+a2]
    Result.i[0] := 0;
    Result.i[1] := a.i[0];
    Result.i[2] := a.i[0] + a.i[1];
    Result.i[3] := a.i[0] + a.i[1] + a.i[2];
  end;
end;
{$POP}

function PrefixSumF32x4(const a: TVecF32x4; inclusive: Boolean): TVecF32x4;
begin
  if inclusive then
  begin
    Result.f[0] := a.f[0];
    Result.f[1] := a.f[0] + a.f[1];
    Result.f[2] := a.f[0] + a.f[1] + a.f[2];
    Result.f[3] := a.f[0] + a.f[1] + a.f[2] + a.f[3];
  end
  else
  begin
    Result.f[0] := 0;
    Result.f[1] := a.f[0];
    Result.f[2] := a.f[0] + a.f[1];
    Result.f[3] := a.f[0] + a.f[1] + a.f[2];
  end;
end;

procedure PrefixSumArrayI32(src, dst: PInt32; count: SizeUInt);
var
  i: SizeUInt;
  sum: Int32;
begin
  if count = 0 then Exit;
  sum := 0;
  for i := 0 to count - 1 do
  begin
    sum := sum + src[i];
    dst[i] := sum;
  end;
end;

procedure PrefixSumArrayF32(src, dst: PSingle; count: SizeUInt);
var
  i: SizeUInt;
  sum: Single;
begin
  if count = 0 then Exit;
  sum := 0;
  for i := 0 to count - 1 do
  begin
    sum := sum + src[i];
    dst[i] := sum;
  end;
end;

// 向量化字符串搜索 - 查找单个字符
function StrFindChar(p: Pointer; len: SizeUInt; ch: Byte): PtrInt;
var
  i: SizeUInt;
  pb: PByte;
begin
  if (p = nil) or (len = 0) then
    Exit(-1);
  
  pb := PByte(p);
  for i := 0 to len - 1 do
  begin
    if pb[i] = ch then
      Exit(i);
  end;
  
  Result := -1;
end;

// === Gather/Scatter 实现 ===
function VecF32x4Gather(base: PSingle; const indices: TVecI32x4): TVecF32x4;
begin
  Result.f[0] := base[indices.i[0]];
  Result.f[1] := base[indices.i[1]];
  Result.f[2] := base[indices.i[2]];
  Result.f[3] := base[indices.i[3]];
end;

function VecI32x4Gather(base: PInt32; const indices: TVecI32x4): TVecI32x4;
begin
  Result.i[0] := base[indices.i[0]];
  Result.i[1] := base[indices.i[1]];
  Result.i[2] := base[indices.i[2]];
  Result.i[3] := base[indices.i[3]];
end;

procedure VecF32x4Scatter(base: PSingle; const indices: TVecI32x4; const values: TVecF32x4);
begin
  base[indices.i[0]] := values.f[0];
  base[indices.i[1]] := values.f[1];
  base[indices.i[2]] := values.f[2];
  base[indices.i[3]] := values.f[3];
end;

procedure VecI32x4Scatter(base: PInt32; const indices: TVecI32x4; const values: TVecI32x4);
begin
  base[indices.i[0]] := values.i[0];
  base[indices.i[1]] := values.i[1];
  base[indices.i[2]] := values.i[2];
  base[indices.i[3]] := values.i[3];
end;

end.
