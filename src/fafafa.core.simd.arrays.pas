{

```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.simd.array

## Abstract

SIMD-accelerated array operations for floating-point data.
Provides high-level array APIs that automatically dispatch to the best available
SIMD backend (Scalar/SSE2/AVX2/AVX-512/NEON).

SIMD 加速的浮点数组操作。
提供高级数组 API，自动派发到最佳可用 SIMD 后端。

## Declaration

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

unit fafafa.core.simd.arrays;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

// ============================================================================
// Reduction Operations - F64 (Double)
// ============================================================================

{**
 * SimdArraySumF64
 *
 * @desc
 *   Sum all elements in a Double array using SIMD acceleration.
 *   使用 SIMD 加速求 Double 数组所有元素之和。
 *
 * @param aSrc - Pointer to source array
 * @param aCount - Number of elements
 * @returns Sum of all elements
 *}
function SimdArraySumF64(aSrc: PDouble; aCount: SizeUInt): Double;

{**
 * SimdArraySumKahanF64
 *
 * @desc
 *   Sum all elements using Kahan compensated summation for higher accuracy.
 *   使用 Kahan 补偿求和算法，提供更高精度的求和结果。
 *
 * @param aSrc - Pointer to source array
 * @param aCount - Number of elements
 * @returns Sum with reduced rounding error
 *}
function SimdArraySumKahanF64(aSrc: PDouble; aCount: SizeUInt): Double;

{**
 * SimdArrayMinF64
 *
 * @desc
 *   Find minimum value in a Double array.
 *   求 Double 数组的最小值。
 *
 * @param aSrc - Pointer to source array
 * @param aCount - Number of elements
 * @returns Minimum value (+Inf for empty array)
 *}
function SimdArrayMinF64(aSrc: PDouble; aCount: SizeUInt): Double;

{**
 * SimdArrayMaxF64
 *
 * @desc
 *   Find maximum value in a Double array.
 *   求 Double 数组的最大值。
 *
 * @param aSrc - Pointer to source array
 * @param aCount - Number of elements
 * @returns Maximum value (-Inf for empty array)
 *}
function SimdArrayMaxF64(aSrc: PDouble; aCount: SizeUInt): Double;

{**
 * SimdArrayMinMaxF64
 *
 * @desc
 *   Find both minimum and maximum in one pass.
 *   一次遍历同时求最小值和最大值。
 *
 * @param aSrc - Pointer to source array
 * @param aCount - Number of elements
 * @param aMin - [out] Minimum value
 * @param aMax - [out] Maximum value
 *}
procedure SimdArrayMinMaxF64(aSrc: PDouble; aCount: SizeUInt; out aMin, aMax: Double);

{**
 * SimdArrayMeanF64
 *
 * @desc
 *   Calculate arithmetic mean of a Double array.
 *   求 Double 数组的算术平均值。
 *
 * @param aSrc - Pointer to source array
 * @param aCount - Number of elements
 * @returns Mean value (0 for empty array)
 *}
function SimdArrayMeanF64(aSrc: PDouble; aCount: SizeUInt): Double;

{**
 * SimdArrayVarianceF64
 *
 * @desc
 *   Calculate sample variance (Bessel's correction: N-1 denominator).
 *   计算样本方差（使用 N-1 作为分母）。
 *
 * @param aSrc - Pointer to source array
 * @param aCount - Number of elements
 * @returns Sample variance (0 for count <= 1)
 *}
function SimdArrayVarianceF64(aSrc: PDouble; aCount: SizeUInt): Double;

{**
 * SimdArrayPopulationVarianceF64
 *
 * @desc
 *   Calculate population variance (N denominator).
 *   计算总体方差（使用 N 作为分母）。
 *
 * @param aSrc - Pointer to source array
 * @param aCount - Number of elements
 * @returns Population variance (0 for empty array)
 *}
function SimdArrayPopulationVarianceF64(aSrc: PDouble; aCount: SizeUInt): Double;

{**
 * SimdArrayStdDevF64
 *
 * @desc
 *   Calculate sample standard deviation.
 *   计算样本标准差。
 *
 * @param aSrc - Pointer to source array
 * @param aCount - Number of elements
 * @returns Sample standard deviation
 *}
function SimdArrayStdDevF64(aSrc: PDouble; aCount: SizeUInt): Double;

{**
 * SimdArrayPopulationStdDevF64
 *
 * @desc
 *   Calculate population standard deviation.
 *   计算总体标准差。
 *
 * @param aSrc - Pointer to source array
 * @param aCount - Number of elements
 * @returns Population standard deviation
 *}
function SimdArrayPopulationStdDevF64(aSrc: PDouble; aCount: SizeUInt): Double;

{**
 * SimdArrayDotProductF64
 *
 * @desc
 *   Calculate dot product of two Double arrays.
 *   计算两个 Double 数组的点积。
 *
 * @param aSrc1 - Pointer to first array
 * @param aSrc2 - Pointer to second array
 * @param aCount - Number of elements
 * @returns Dot product (sum of element-wise products)
 *}
function SimdArrayDotProductF64(aSrc1, aSrc2: PDouble; aCount: SizeUInt): Double;

{**
 * SimdArrayL2NormF64
 *
 * @desc
 *   Calculate L2 norm (Euclidean length) of a Double array.
 *   计算 Double 数组的 L2 范数（欧几里得长度）。
 *
 * @param aSrc - Pointer to source array
 * @param aCount - Number of elements
 * @returns L2 norm (sqrt of sum of squares)
 *}
function SimdArrayL2NormF64(aSrc: PDouble; aCount: SizeUInt): Double;

// ============================================================================
// Reduction Operations - F32 (Single)
// ============================================================================

function SimdArraySumF32(aSrc: PSingle; aCount: SizeUInt): Single;
function SimdArraySumKahanF32(aSrc: PSingle; aCount: SizeUInt): Single;
function SimdArrayMinF32(aSrc: PSingle; aCount: SizeUInt): Single;
function SimdArrayMaxF32(aSrc: PSingle; aCount: SizeUInt): Single;
procedure SimdArrayMinMaxF32(aSrc: PSingle; aCount: SizeUInt; out aMin, aMax: Single);
function SimdArrayMeanF32(aSrc: PSingle; aCount: SizeUInt): Single;
function SimdArrayVarianceF32(aSrc: PSingle; aCount: SizeUInt): Single;
function SimdArrayPopulationVarianceF32(aSrc: PSingle; aCount: SizeUInt): Single;
function SimdArrayStdDevF32(aSrc: PSingle; aCount: SizeUInt): Single;
function SimdArrayPopulationStdDevF32(aSrc: PSingle; aCount: SizeUInt): Single;
function SimdArrayDotProductF32(aSrc1, aSrc2: PSingle; aCount: SizeUInt): Single;
function SimdArrayL2NormF32(aSrc: PSingle; aCount: SizeUInt): Single;

// ============================================================================
// Element-wise Operations - F64 (Double)
// ============================================================================

{**
 * SimdArrayScaleF64
 *
 * @desc
 *   Multiply all elements by a scalar factor.
 *   将所有元素乘以一个标量因子。
 *
 * @param aSrc - Pointer to source array
 * @param aDst - Pointer to destination array (can be same as aSrc for in-place)
 * @param aCount - Number of elements
 * @param aFactor - Scalar factor to multiply
 *}
procedure SimdArrayScaleF64(aSrc, aDst: PDouble; aCount: SizeUInt; aFactor: Double);

{**
 * SimdArrayAbsF64
 *
 * @desc
 *   Take absolute value of all elements.
 *   对所有元素取绝对值。
 *
 * @param aSrc - Pointer to source array
 * @param aDst - Pointer to destination array (can be same as aSrc for in-place)
 * @param aCount - Number of elements
 *}
procedure SimdArrayAbsF64(aSrc, aDst: PDouble; aCount: SizeUInt);

{**
 * SimdArrayAddF64
 *
 * @desc
 *   Add a scalar value to all elements.
 *   对所有元素加上一个标量值。
 *
 * @param aSrc - Pointer to source array
 * @param aDst - Pointer to destination array (can be same as aSrc for in-place)
 * @param aCount - Number of elements
 * @param aValue - Scalar value to add
 *}
procedure SimdArrayAddF64(aSrc, aDst: PDouble; aCount: SizeUInt; aValue: Double);

{**
 * SimdArrayAddArrayF64
 *
 * @desc
 *   Add two arrays element-wise.
 *   两个数组逐元素相加。
 *
 * @param aSrc1 - Pointer to first source array
 * @param aSrc2 - Pointer to second source array
 * @param aDst - Pointer to destination array
 * @param aCount - Number of elements
 *}
procedure SimdArrayAddArrayF64(aSrc1, aSrc2, aDst: PDouble; aCount: SizeUInt);

// ============================================================================
// Element-wise Operations - F32 (Single)
// ============================================================================

procedure SimdArrayScaleF32(aSrc, aDst: PSingle; aCount: SizeUInt; aFactor: Single);
procedure SimdArrayAbsF32(aSrc, aDst: PSingle; aCount: SizeUInt);
procedure SimdArrayAddF32(aSrc, aDst: PSingle; aCount: SizeUInt; aValue: Single);
procedure SimdArrayAddArrayF32(aSrc1, aSrc2, aDst: PSingle; aCount: SizeUInt);

implementation

uses
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch,
  fafafa.core.simd;

const
  // IEEE-754 special values for infinity (avoiding Math unit dependency)
  // IEEE-754 无穷常量（避免 Math 单元依赖）
  PosInfinityF64: Double = 1.0 / 0.0;
  NegInfinityF64: Double = -1.0 / 0.0;
  PosInfinityF32: Single = 1.0 / 0.0;
  NegInfinityF32: Single = -1.0 / 0.0;

// ============================================================================
// F64 Reduction Operations - Scalar Reference Implementation
// (Will be replaced by SIMD-optimized versions via dispatch)
// ============================================================================

function SimdArraySumF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  i: SizeUInt;
  vec: TVecF64x4;
  acc: TVecF64x4;
  dispatch: PSimdDispatchTable;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(0.0);

  dispatch := GetDispatchTable;
  Result := 0.0;

  // Use AVX2 (4 doubles per vector) if available
  if aCount >= 4 then
  begin
    // Initialize accumulator to zero
    acc.d[0] := 0.0; acc.d[1] := 0.0; acc.d[2] := 0.0; acc.d[3] := 0.0;

    // Process 4 doubles at a time
    while aCount >= 4 do
    begin
      vec.d[0] := aSrc[0];
      vec.d[1] := aSrc[1];
      vec.d[2] := aSrc[2];
      vec.d[3] := aSrc[3];
      acc := dispatch^.AddF64x4(acc, vec);
      Inc(aSrc, 4);
      Dec(aCount, 4);
    end;

    // Reduce accumulator to single value
    Result := acc.d[0] + acc.d[1] + acc.d[2] + acc.d[3];
  end;

  // Handle remaining elements
  for i := 0 to aCount - 1 do
    Result := Result + aSrc[i];
end;

function SimdArraySumKahanF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  i: SizeUInt;
  sum, c, y, t: Double;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(0.0);

  sum := 0.0;
  c := 0.0;  // Compensation for lost low-order bits

  for i := 0 to aCount - 1 do
  begin
    y := aSrc[i] - c;       // Compensate for previous error
    t := sum + y;           // Alas, sum is big, y small, so low-order digits of y are lost
    c := (t - sum) - y;     // (t - sum) recovers the high-order part of y; subtracting y recovers -(low part of y)
    sum := t;               // Algebraically, c should always be zero. Beware overly-aggressive optimizing compilers!
  end;

  Result := sum;
end;

function SimdArrayMinF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  i: SizeUInt;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(PosInfinityF64);

  // Scalar implementation (F64 Min/Max not in dispatch table yet)
  Result := aSrc[0];
  for i := 1 to aCount - 1 do
    if aSrc[i] < Result then
      Result := aSrc[i];
end;

function SimdArrayMaxF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  i: SizeUInt;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(NegInfinityF64);

  // Scalar implementation (F64 Min/Max not in dispatch table yet)
  Result := aSrc[0];
  for i := 1 to aCount - 1 do
    if aSrc[i] > Result then
      Result := aSrc[i];
end;

procedure SimdArrayMinMaxF64(aSrc: PDouble; aCount: SizeUInt; out aMin, aMax: Double);
var
  i: SizeUInt;
begin
  if (aSrc = nil) or (aCount = 0) then
  begin
    aMin := PosInfinityF64;
    aMax := NegInfinityF64;
    Exit;
  end;

  // Scalar implementation (F64 Min/Max not in dispatch table yet)
  aMin := aSrc[0];
  aMax := aSrc[0];
  for i := 1 to aCount - 1 do
  begin
    if aSrc[i] < aMin then aMin := aSrc[i];
    if aSrc[i] > aMax then aMax := aSrc[i];
  end;
end;

function SimdArrayMeanF64(aSrc: PDouble; aCount: SizeUInt): Double;
begin
  if aCount = 0 then
    Exit(0.0);
  Result := SimdArraySumF64(aSrc, aCount) / aCount;
end;

// ✅ Welford 在线算法 - 单次遍历，更好的数值稳定性
function SimdArrayVarianceF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  i: SizeUInt;
  mean, m2, delta, delta2: Double;
begin
  if (aSrc = nil) or (aCount <= 1) then
    Exit(0.0);

  mean := 0.0;
  m2 := 0.0;

  for i := 0 to aCount - 1 do
  begin
    delta := aSrc[i] - mean;
    mean := mean + delta / Double(i + 1);
    delta2 := aSrc[i] - mean;
    m2 := m2 + delta * delta2;
  end;

  Result := m2 / (aCount - 1);  // Sample variance (Bessel's correction)
end;

// ✅ Welford 在线算法 - 单次遍历，更好的数值稳定性
function SimdArrayPopulationVarianceF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  i: SizeUInt;
  mean, m2, delta, delta2: Double;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(0.0);

  mean := 0.0;
  m2 := 0.0;

  for i := 0 to aCount - 1 do
  begin
    delta := aSrc[i] - mean;
    mean := mean + delta / Double(i + 1);
    delta2 := aSrc[i] - mean;
    m2 := m2 + delta * delta2;
  end;

  Result := m2 / aCount;  // Population variance
end;

function SimdArrayStdDevF64(aSrc: PDouble; aCount: SizeUInt): Double;
begin
  Result := System.Sqrt(SimdArrayVarianceF64(aSrc, aCount));
end;

function SimdArrayPopulationStdDevF64(aSrc: PDouble; aCount: SizeUInt): Double;
begin
  Result := System.Sqrt(SimdArrayPopulationVarianceF64(aSrc, aCount));
end;

function SimdArrayDotProductF64(aSrc1, aSrc2: PDouble; aCount: SizeUInt): Double;
var
  i: SizeUInt;
  vec1, vec2, prod, acc: TVecF64x4;
  dispatch: PSimdDispatchTable;
begin
  if (aSrc1 = nil) or (aSrc2 = nil) or (aCount = 0) then
    Exit(0.0);

  dispatch := GetDispatchTable;
  Result := 0.0;

  // Use AVX2 (4 doubles per vector) if available
  if aCount >= 4 then
  begin
    // Initialize accumulator to zero
    acc.d[0] := 0.0; acc.d[1] := 0.0; acc.d[2] := 0.0; acc.d[3] := 0.0;

    // Process 4 doubles at a time
    while aCount >= 4 do
    begin
      vec1.d[0] := aSrc1[0]; vec1.d[1] := aSrc1[1]; vec1.d[2] := aSrc1[2]; vec1.d[3] := aSrc1[3];
      vec2.d[0] := aSrc2[0]; vec2.d[1] := aSrc2[1]; vec2.d[2] := aSrc2[2]; vec2.d[3] := aSrc2[3];
      prod := dispatch^.MulF64x4(vec1, vec2);
      acc := dispatch^.AddF64x4(acc, prod);
      Inc(aSrc1, 4);
      Inc(aSrc2, 4);
      Dec(aCount, 4);
    end;

    // Reduce accumulator to single value
    Result := acc.d[0] + acc.d[1] + acc.d[2] + acc.d[3];
  end;

  // Handle remaining elements
  for i := 0 to aCount - 1 do
    Result := Result + aSrc1[i] * aSrc2[i];
end;

function SimdArrayL2NormF64(aSrc: PDouble; aCount: SizeUInt): Double;
begin
  Result := System.Sqrt(SimdArrayDotProductF64(aSrc, aSrc, aCount));
end;

// ============================================================================
// F32 Reduction Operations
// ============================================================================

function SimdArraySumF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  i: SizeUInt;
  vec, acc: TVecF32x8;
  dispatch: PSimdDispatchTable;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(0.0);

  dispatch := GetDispatchTable;
  Result := 0.0;

  // Use AVX2 (8 singles per vector) if available
  if aCount >= 8 then
  begin
    // Initialize accumulator to zero
    for i := 0 to 7 do acc.f[i] := 0.0;

    // Process 8 singles at a time
    while aCount >= 8 do
    begin
      for i := 0 to 7 do vec.f[i] := aSrc[i];
      acc := dispatch^.AddF32x8(acc, vec);
      Inc(aSrc, 8);
      Dec(aCount, 8);
    end;

    // Reduce accumulator to single value
    for i := 0 to 7 do Result := Result + acc.f[i];
  end;

  // Handle remaining elements
  for i := 0 to aCount - 1 do
    Result := Result + aSrc[i];
end;

function SimdArraySumKahanF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  i: SizeUInt;
  sum, c, y, t: Single;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(0.0);

  sum := 0.0;
  c := 0.0;

  for i := 0 to aCount - 1 do
  begin
    y := aSrc[i] - c;
    t := sum + y;
    c := (t - sum) - y;
    sum := t;
  end;

  Result := sum;
end;

function SimdArrayMinF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  i: SizeUInt;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(PosInfinityF32);

  Result := aSrc[0];
  for i := 1 to aCount - 1 do
    if aSrc[i] < Result then
      Result := aSrc[i];
end;

function SimdArrayMaxF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  i: SizeUInt;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(NegInfinityF32);

  Result := aSrc[0];
  for i := 1 to aCount - 1 do
    if aSrc[i] > Result then
      Result := aSrc[i];
end;

procedure SimdArrayMinMaxF32(aSrc: PSingle; aCount: SizeUInt; out aMin, aMax: Single);
var
  i: SizeUInt;
begin
  if (aSrc = nil) or (aCount = 0) then
  begin
    aMin := PosInfinityF32;
    aMax := NegInfinityF32;
    Exit;
  end;

  aMin := aSrc[0];
  aMax := aSrc[0];
  for i := 1 to aCount - 1 do
  begin
    if aSrc[i] < aMin then aMin := aSrc[i];
    if aSrc[i] > aMax then aMax := aSrc[i];
  end;
end;

function SimdArrayMeanF32(aSrc: PSingle; aCount: SizeUInt): Single;
begin
  if aCount = 0 then
    Exit(0.0);
  Result := SimdArraySumF32(aSrc, aCount) / aCount;
end;

// ✅ Welford 在线算法 - 单次遍历，更好的数值稳定性
function SimdArrayVarianceF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  i: SizeUInt;
  mean, m2, delta, delta2: Single;
begin
  if (aSrc = nil) or (aCount <= 1) then
    Exit(0.0);

  mean := 0.0;
  m2 := 0.0;

  for i := 0 to aCount - 1 do
  begin
    delta := aSrc[i] - mean;
    mean := mean + delta / Single(i + 1);
    delta2 := aSrc[i] - mean;
    m2 := m2 + delta * delta2;
  end;

  Result := m2 / (aCount - 1);  // Sample variance (Bessel's correction)
end;

// ✅ Welford 在线算法 - 单次遍历，更好的数值稳定性
function SimdArrayPopulationVarianceF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  i: SizeUInt;
  mean, m2, delta, delta2: Single;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(0.0);

  mean := 0.0;
  m2 := 0.0;

  for i := 0 to aCount - 1 do
  begin
    delta := aSrc[i] - mean;
    mean := mean + delta / Single(i + 1);
    delta2 := aSrc[i] - mean;
    m2 := m2 + delta * delta2;
  end;

  Result := m2 / aCount;  // Population variance
end;

function SimdArrayStdDevF32(aSrc: PSingle; aCount: SizeUInt): Single;
begin
  Result := System.Sqrt(SimdArrayVarianceF32(aSrc, aCount));
end;

function SimdArrayPopulationStdDevF32(aSrc: PSingle; aCount: SizeUInt): Single;
begin
  Result := System.Sqrt(SimdArrayPopulationVarianceF32(aSrc, aCount));
end;

function SimdArrayDotProductF32(aSrc1, aSrc2: PSingle; aCount: SizeUInt): Single;
var
  i: SizeUInt;
  vec1, vec2, prod, acc: TVecF32x8;
  dispatch: PSimdDispatchTable;
begin
  if (aSrc1 = nil) or (aSrc2 = nil) or (aCount = 0) then
    Exit(0.0);

  dispatch := GetDispatchTable;
  Result := 0.0;

  // ✅ Use AVX2 (8 singles per vector) - consistent with F64 version
  if aCount >= 8 then
  begin
    // Initialize accumulator to zero
    for i := 0 to 7 do acc.f[i] := 0.0;

    // Process 8 singles at a time using SIMD multiply-add
    while aCount >= 8 do
    begin
      for i := 0 to 7 do vec1.f[i] := aSrc1[i];
      for i := 0 to 7 do vec2.f[i] := aSrc2[i];
      prod := dispatch^.MulF32x8(vec1, vec2);
      acc := dispatch^.AddF32x8(acc, prod);
      Inc(aSrc1, 8);
      Inc(aSrc2, 8);
      Dec(aCount, 8);
    end;

    // Reduce accumulator to single value
    for i := 0 to 7 do Result := Result + acc.f[i];
  end;

  // Handle remaining elements
  for i := 0 to aCount - 1 do
    Result := Result + aSrc1[i] * aSrc2[i];
end;

function SimdArrayL2NormF32(aSrc: PSingle; aCount: SizeUInt): Single;
begin
  Result := System.Sqrt(SimdArrayDotProductF32(aSrc, aSrc, aCount));
end;

// ============================================================================
// F64 Element-wise Operations
// ============================================================================

procedure SimdArrayScaleF64(aSrc, aDst: PDouble; aCount: SizeUInt; aFactor: Double);
var
  i: SizeUInt;
  vecSrc, vecFactor, vecDst: TVecF64x4;
  dispatch: PSimdDispatchTable;
begin
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  dispatch := GetDispatchTable;

  // Splat factor to all vector lanes
  vecFactor.d[0] := aFactor; vecFactor.d[1] := aFactor;
  vecFactor.d[2] := aFactor; vecFactor.d[3] := aFactor;

  // Process 4 doubles at a time
  while aCount >= 4 do
  begin
    vecSrc.d[0] := aSrc[0]; vecSrc.d[1] := aSrc[1];
    vecSrc.d[2] := aSrc[2]; vecSrc.d[3] := aSrc[3];
    vecDst := dispatch^.MulF64x4(vecSrc, vecFactor);
    aDst[0] := vecDst.d[0]; aDst[1] := vecDst.d[1];
    aDst[2] := vecDst.d[2]; aDst[3] := vecDst.d[3];
    Inc(aSrc, 4);
    Inc(aDst, 4);
    Dec(aCount, 4);
  end;

  // Handle remaining elements
  for i := 0 to aCount - 1 do
    aDst[i] := aSrc[i] * aFactor;
end;

procedure SimdArrayAbsF64(aSrc, aDst: PDouble; aCount: SizeUInt);
var
  i: SizeUInt;
begin
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  for i := 0 to aCount - 1 do
    aDst[i] := System.Abs(aSrc[i]);
end;

procedure SimdArrayAddF64(aSrc, aDst: PDouble; aCount: SizeUInt; aValue: Double);
var
  i: SizeUInt;
  vecSrc, vecValue, vecDst: TVecF64x4;
  dispatch: PSimdDispatchTable;
begin
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  dispatch := GetDispatchTable;

  // Splat value to all vector lanes
  vecValue.d[0] := aValue; vecValue.d[1] := aValue;
  vecValue.d[2] := aValue; vecValue.d[3] := aValue;

  // Process 4 doubles at a time
  while aCount >= 4 do
  begin
    vecSrc.d[0] := aSrc[0]; vecSrc.d[1] := aSrc[1];
    vecSrc.d[2] := aSrc[2]; vecSrc.d[3] := aSrc[3];
    vecDst := dispatch^.AddF64x4(vecSrc, vecValue);
    aDst[0] := vecDst.d[0]; aDst[1] := vecDst.d[1];
    aDst[2] := vecDst.d[2]; aDst[3] := vecDst.d[3];
    Inc(aSrc, 4);
    Inc(aDst, 4);
    Dec(aCount, 4);
  end;

  // Handle remaining elements
  for i := 0 to aCount - 1 do
    aDst[i] := aSrc[i] + aValue;
end;

procedure SimdArrayAddArrayF64(aSrc1, aSrc2, aDst: PDouble; aCount: SizeUInt);
var
  i: SizeUInt;
  vec1, vec2, vecDst: TVecF64x4;
  dispatch: PSimdDispatchTable;
begin
  if (aSrc1 = nil) or (aSrc2 = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  dispatch := GetDispatchTable;

  // Process 4 doubles at a time
  while aCount >= 4 do
  begin
    vec1.d[0] := aSrc1[0]; vec1.d[1] := aSrc1[1]; vec1.d[2] := aSrc1[2]; vec1.d[3] := aSrc1[3];
    vec2.d[0] := aSrc2[0]; vec2.d[1] := aSrc2[1]; vec2.d[2] := aSrc2[2]; vec2.d[3] := aSrc2[3];
    vecDst := dispatch^.AddF64x4(vec1, vec2);
    aDst[0] := vecDst.d[0]; aDst[1] := vecDst.d[1]; aDst[2] := vecDst.d[2]; aDst[3] := vecDst.d[3];
    Inc(aSrc1, 4);
    Inc(aSrc2, 4);
    Inc(aDst, 4);
    Dec(aCount, 4);
  end;

  // Handle remaining elements
  for i := 0 to aCount - 1 do
    aDst[i] := aSrc1[i] + aSrc2[i];
end;

// ============================================================================
// F32 Element-wise Operations
// ============================================================================

procedure SimdArrayScaleF32(aSrc, aDst: PSingle; aCount: SizeUInt; aFactor: Single);
var
  i: SizeUInt;
  vecSrc, vecFactor, vecDst: TVecF32x8;
  dispatch: PSimdDispatchTable;
begin
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  dispatch := GetDispatchTable;

  // ✅ Splat factor to all vector lanes - consistent with F64 version
  for i := 0 to 7 do vecFactor.f[i] := aFactor;

  // Process 8 singles at a time using SIMD
  while aCount >= 8 do
  begin
    for i := 0 to 7 do vecSrc.f[i] := aSrc[i];
    vecDst := dispatch^.MulF32x8(vecSrc, vecFactor);
    for i := 0 to 7 do aDst[i] := vecDst.f[i];
    Inc(aSrc, 8);
    Inc(aDst, 8);
    Dec(aCount, 8);
  end;

  // Handle remaining elements
  for i := 0 to aCount - 1 do
    aDst[i] := aSrc[i] * aFactor;
end;

procedure SimdArrayAbsF32(aSrc, aDst: PSingle; aCount: SizeUInt);
var
  i: SizeUInt;
begin
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  for i := 0 to aCount - 1 do
    aDst[i] := System.Abs(aSrc[i]);
end;

procedure SimdArrayAddF32(aSrc, aDst: PSingle; aCount: SizeUInt; aValue: Single);
var
  i: SizeUInt;
  vecSrc, vecValue, vecDst: TVecF32x8;
  dispatch: PSimdDispatchTable;
begin
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  dispatch := GetDispatchTable;

  // ✅ Splat value to all vector lanes - consistent with F64 version
  for i := 0 to 7 do vecValue.f[i] := aValue;

  // Process 8 singles at a time using SIMD
  while aCount >= 8 do
  begin
    for i := 0 to 7 do vecSrc.f[i] := aSrc[i];
    vecDst := dispatch^.AddF32x8(vecSrc, vecValue);
    for i := 0 to 7 do aDst[i] := vecDst.f[i];
    Inc(aSrc, 8);
    Inc(aDst, 8);
    Dec(aCount, 8);
  end;

  // Handle remaining elements
  for i := 0 to aCount - 1 do
    aDst[i] := aSrc[i] + aValue;
end;

procedure SimdArrayAddArrayF32(aSrc1, aSrc2, aDst: PSingle; aCount: SizeUInt);
var
  i: SizeUInt;
  vec1, vec2, vecDst: TVecF32x8;
  dispatch: PSimdDispatchTable;
begin
  if (aSrc1 = nil) or (aSrc2 = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  dispatch := GetDispatchTable;

  // ✅ Process 8 singles at a time using SIMD - consistent with F64 version
  while aCount >= 8 do
  begin
    for i := 0 to 7 do vec1.f[i] := aSrc1[i];
    for i := 0 to 7 do vec2.f[i] := aSrc2[i];
    vecDst := dispatch^.AddF32x8(vec1, vec2);
    for i := 0 to 7 do aDst[i] := vecDst.f[i];
    Inc(aSrc1, 8);
    Inc(aSrc2, 8);
    Inc(aDst, 8);
    Dec(aCount, 8);
  end;

  // Handle remaining elements
  for i := 0 to aCount - 1 do
    aDst[i] := aSrc1[i] + aSrc2[i];
end;

end.
