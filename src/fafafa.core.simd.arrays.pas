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
  LIndex: SizeUInt;
  LVec: TVecF64x4;
  LDispatch: PSimdDispatchTable;
  LHasReduceAddF64x4: Boolean;
  LHasLoadF64x4: Boolean;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(0.0);

  LDispatch := GetDispatchTable;
  LHasReduceAddF64x4 := Assigned(LDispatch^.ReduceAddF64x4);
  LHasLoadF64x4 := Assigned(LDispatch^.LoadF64x4);
  Result := 0.0;

  while aCount >= 4 do
  begin
    if LHasLoadF64x4 then
      LVec := LDispatch^.LoadF64x4(aSrc)
    else
    begin
      LVec.d[0] := aSrc[0];
      LVec.d[1] := aSrc[1];
      LVec.d[2] := aSrc[2];
      LVec.d[3] := aSrc[3];
    end;

    if LHasReduceAddF64x4 then
      Result := Result + LDispatch^.ReduceAddF64x4(LVec)
    else
      Result := Result + LVec.d[0] + LVec.d[1] + LVec.d[2] + LVec.d[3];

    Inc(aSrc, 4);
    Dec(aCount, 4);
  end;

  if aCount > 0 then
    for LIndex := 0 to aCount - 1 do
      Result := Result + aSrc[LIndex];
end;

function SimdArraySumKahanF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  LIndex: SizeUInt;
  LVec: TVecF64x4;
  LDispatch: PSimdDispatchTable;
  LHasLoadF64x4: Boolean;
  LHasReduceAddF64x4: Boolean;
  LSum, LC, LY, LT: Double;
  LBlockSum: Double;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(0.0);

  LDispatch := GetDispatchTable;
  LHasLoadF64x4 := Assigned(LDispatch^.LoadF64x4);
  LHasReduceAddF64x4 := Assigned(LDispatch^.ReduceAddF64x4);

  LSum := 0.0;
  LC := 0.0;

  while aCount >= 4 do
  begin
    if LHasLoadF64x4 then
      LVec := LDispatch^.LoadF64x4(aSrc)
    else
    begin
      LVec.d[0] := aSrc[0];
      LVec.d[1] := aSrc[1];
      LVec.d[2] := aSrc[2];
      LVec.d[3] := aSrc[3];
    end;

    if LHasReduceAddF64x4 then
      LBlockSum := LDispatch^.ReduceAddF64x4(LVec)
    else
      LBlockSum := LVec.d[0] + LVec.d[1] + LVec.d[2] + LVec.d[3];

    LY := LBlockSum - LC;
    LT := LSum + LY;
    LC := (LT - LSum) - LY;
    LSum := LT;

    Inc(aSrc, 4);
    Dec(aCount, 4);
  end;

  if aCount > 0 then
    for LIndex := 0 to aCount - 1 do
    begin
      LY := aSrc[LIndex] - LC;
      LT := LSum + LY;
      LC := (LT - LSum) - LY;
      LSum := LT;
    end;

  Result := LSum;
end;

function SimdArrayMinF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  LIndex: SizeUInt;
  LVec, LVecMin: TVecF64x4;
  LDispatch: PSimdDispatchTable;
  LCanVectorize: Boolean;
  LChunkMin: Double;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(PosInfinityF64);

  LDispatch := GetDispatchTable;
  LCanVectorize := Assigned(LDispatch^.LoadF64x4)
    and Assigned(LDispatch^.MinF64x4)
    and Assigned(LDispatch^.ReduceMinF64x4);

  Result := aSrc[0];
  Inc(aSrc);
  Dec(aCount);

  if LCanVectorize and (aCount >= 4) then
  begin
    LVecMin := LDispatch^.LoadF64x4(aSrc);
    Inc(aSrc, 4);
    Dec(aCount, 4);

    while aCount >= 4 do
    begin
      LVec := LDispatch^.LoadF64x4(aSrc);
      LVecMin := LDispatch^.MinF64x4(LVecMin, LVec);
      Inc(aSrc, 4);
      Dec(aCount, 4);
    end;

    LChunkMin := LDispatch^.ReduceMinF64x4(LVecMin);
    if LChunkMin < Result then
      Result := LChunkMin;
  end;

  if aCount > 0 then
    for LIndex := 0 to aCount - 1 do
      if aSrc[LIndex] < Result then
        Result := aSrc[LIndex];
end;

function SimdArrayMaxF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  LIndex: SizeUInt;
  LVec, LVecMax: TVecF64x4;
  LDispatch: PSimdDispatchTable;
  LCanVectorize: Boolean;
  LChunkMax: Double;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(NegInfinityF64);

  LDispatch := GetDispatchTable;
  LCanVectorize := Assigned(LDispatch^.LoadF64x4)
    and Assigned(LDispatch^.MaxF64x4)
    and Assigned(LDispatch^.ReduceMaxF64x4);

  Result := aSrc[0];
  Inc(aSrc);
  Dec(aCount);

  if LCanVectorize and (aCount >= 4) then
  begin
    LVecMax := LDispatch^.LoadF64x4(aSrc);
    Inc(aSrc, 4);
    Dec(aCount, 4);

    while aCount >= 4 do
    begin
      LVec := LDispatch^.LoadF64x4(aSrc);
      LVecMax := LDispatch^.MaxF64x4(LVecMax, LVec);
      Inc(aSrc, 4);
      Dec(aCount, 4);
    end;

    LChunkMax := LDispatch^.ReduceMaxF64x4(LVecMax);
    if LChunkMax > Result then
      Result := LChunkMax;
  end;

  if aCount > 0 then
    for LIndex := 0 to aCount - 1 do
      if aSrc[LIndex] > Result then
        Result := aSrc[LIndex];
end;

procedure SimdArrayMinMaxF64(aSrc: PDouble; aCount: SizeUInt; out aMin, aMax: Double);
var
  LIndex: SizeUInt;
  LVec, LVecMin, LVecMax: TVecF64x4;
  LDispatch: PSimdDispatchTable;
  LCanVectorize: Boolean;
  LChunkMin, LChunkMax: Double;
begin
  if (aSrc = nil) or (aCount = 0) then
  begin
    aMin := PosInfinityF64;
    aMax := NegInfinityF64;
    Exit;
  end;

  LDispatch := GetDispatchTable;
  LCanVectorize := Assigned(LDispatch^.LoadF64x4)
    and Assigned(LDispatch^.MinF64x4)
    and Assigned(LDispatch^.MaxF64x4)
    and Assigned(LDispatch^.ReduceMinF64x4)
    and Assigned(LDispatch^.ReduceMaxF64x4);

  aMin := aSrc[0];
  aMax := aSrc[0];
  Inc(aSrc);
  Dec(aCount);

  if LCanVectorize and (aCount >= 4) then
  begin
    LVec := LDispatch^.LoadF64x4(aSrc);
    LVecMin := LVec;
    LVecMax := LVec;
    Inc(aSrc, 4);
    Dec(aCount, 4);

    while aCount >= 4 do
    begin
      LVec := LDispatch^.LoadF64x4(aSrc);
      LVecMin := LDispatch^.MinF64x4(LVecMin, LVec);
      LVecMax := LDispatch^.MaxF64x4(LVecMax, LVec);
      Inc(aSrc, 4);
      Dec(aCount, 4);
    end;

    LChunkMin := LDispatch^.ReduceMinF64x4(LVecMin);
    LChunkMax := LDispatch^.ReduceMaxF64x4(LVecMax);
    if LChunkMin < aMin then
      aMin := LChunkMin;
    if LChunkMax > aMax then
      aMax := LChunkMax;
  end;

  if aCount > 0 then
    for LIndex := 0 to aCount - 1 do
    begin
      if aSrc[LIndex] < aMin then
        aMin := aSrc[LIndex];
      if aSrc[LIndex] > aMax then
        aMax := aSrc[LIndex];
    end;
end;

function SimdArrayMeanF64(aSrc: PDouble; aCount: SizeUInt): Double;
begin
  if aCount = 0 then
    Exit(0.0);
  Result := SimdArraySumF64(aSrc, aCount) / aCount;
end;

function SimdArrayCenteredSumSqF64(aSrc: PDouble; aCount: SizeUInt; aMean: Double): Double;
var
  LIndex: SizeUInt;
  LVec, LMeanVec, LDiff, LSquare: TVecF64x4;
  LDispatch: PSimdDispatchTable;
  LCanVectorize: Boolean;
  LHasReduceAddF64x4: Boolean;
  LDelta: Double;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(0.0);

  LDispatch := GetDispatchTable;
  LCanVectorize := Assigned(LDispatch^.LoadF64x4)
    and Assigned(LDispatch^.SubF64x4)
    and Assigned(LDispatch^.MulF64x4);
  LHasReduceAddF64x4 := Assigned(LDispatch^.ReduceAddF64x4);
  Result := 0.0;

  if LCanVectorize then
  begin
    if Assigned(LDispatch^.SplatF64x4) then
      LMeanVec := LDispatch^.SplatF64x4(aMean)
    else
    begin
      LMeanVec.d[0] := aMean;
      LMeanVec.d[1] := aMean;
      LMeanVec.d[2] := aMean;
      LMeanVec.d[3] := aMean;
    end;

    while aCount >= 4 do
    begin
      LVec := LDispatch^.LoadF64x4(aSrc);
      LDiff := LDispatch^.SubF64x4(LVec, LMeanVec);
      LSquare := LDispatch^.MulF64x4(LDiff, LDiff);

      if LHasReduceAddF64x4 then
        Result := Result + LDispatch^.ReduceAddF64x4(LSquare)
      else
        Result := Result + LSquare.d[0] + LSquare.d[1] + LSquare.d[2] + LSquare.d[3];

      Inc(aSrc, 4);
      Dec(aCount, 4);
    end;
  end;

  if aCount > 0 then
    for LIndex := 0 to aCount - 1 do
    begin
      LDelta := aSrc[LIndex] - aMean;
      Result := Result + LDelta * LDelta;
    end;
end;


function SimdArrayVarianceF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  LMean: Double;
  LSumSq: Double;
begin
  if (aSrc = nil) or (aCount <= 1) then
    Exit(0.0);

  LMean := SimdArrayMeanF64(aSrc, aCount);
  LSumSq := SimdArrayCenteredSumSqF64(aSrc, aCount, LMean);
  Result := LSumSq / (aCount - 1);
end;

function SimdArrayPopulationVarianceF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  LMean: Double;
  LSumSq: Double;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(0.0);

  LMean := SimdArrayMeanF64(aSrc, aCount);
  LSumSq := SimdArrayCenteredSumSqF64(aSrc, aCount, LMean);
  Result := LSumSq / aCount;
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
  LIndex: SizeUInt;
  LVec1, LVec2, LProd: TVecF64x4;
  LDispatch: PSimdDispatchTable;
  LHasDotF64x4: Boolean;
  LHasLoadF64x4: Boolean;
begin
  if (aSrc1 = nil) or (aSrc2 = nil) or (aCount = 0) then
    Exit(0.0);

  LDispatch := GetDispatchTable;
  LHasDotF64x4 := Assigned(LDispatch^.DotF64x4);
  LHasLoadF64x4 := Assigned(LDispatch^.LoadF64x4);
  Result := 0.0;

  while aCount >= 4 do
  begin
    if LHasLoadF64x4 then
    begin
      LVec1 := LDispatch^.LoadF64x4(aSrc1);
      LVec2 := LDispatch^.LoadF64x4(aSrc2);
    end
    else
    begin
      LVec1.d[0] := aSrc1[0]; LVec1.d[1] := aSrc1[1]; LVec1.d[2] := aSrc1[2]; LVec1.d[3] := aSrc1[3];
      LVec2.d[0] := aSrc2[0]; LVec2.d[1] := aSrc2[1]; LVec2.d[2] := aSrc2[2]; LVec2.d[3] := aSrc2[3];
    end;

    if LHasDotF64x4 then
      Result := Result + LDispatch^.DotF64x4(LVec1, LVec2)
    else
    begin
      LProd := LDispatch^.MulF64x4(LVec1, LVec2);
      Result := Result + LProd.d[0] + LProd.d[1] + LProd.d[2] + LProd.d[3];
    end;

    Inc(aSrc1, 4);
    Inc(aSrc2, 4);
    Dec(aCount, 4);
  end;

  if aCount > 0 then
    for LIndex := 0 to aCount - 1 do
      Result := Result + aSrc1[LIndex] * aSrc2[LIndex];
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
  LIndex: SizeUInt;
  LVec: TVecF32x8;
  LDispatch: PSimdDispatchTable;
  LHasReduceAddF32x8: Boolean;
  LHasLoadF32x8: Boolean;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(0.0);

  LDispatch := GetDispatchTable;
  LHasReduceAddF32x8 := Assigned(LDispatch^.ReduceAddF32x8);
  LHasLoadF32x8 := Assigned(LDispatch^.LoadF32x8);
  Result := 0.0;

  while aCount >= 8 do
  begin
    if LHasLoadF32x8 then
      LVec := LDispatch^.LoadF32x8(aSrc)
    else
    begin
      for LIndex := 0 to 7 do
        LVec.f[LIndex] := aSrc[LIndex];
    end;

    if LHasReduceAddF32x8 then
      Result := Result + LDispatch^.ReduceAddF32x8(LVec)
    else
      Result := Result
        + LVec.f[0] + LVec.f[1] + LVec.f[2] + LVec.f[3]
        + LVec.f[4] + LVec.f[5] + LVec.f[6] + LVec.f[7];

    Inc(aSrc, 8);
    Dec(aCount, 8);
  end;

  if aCount > 0 then
    for LIndex := 0 to aCount - 1 do
      Result := Result + aSrc[LIndex];
end;

function SimdArraySumKahanF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  LIndex: SizeUInt;
  LVec: TVecF32x8;
  LDispatch: PSimdDispatchTable;
  LHasLoadF32x8: Boolean;
  LHasReduceAddF32x8: Boolean;
  LSum, LC, LY, LT: Single;
  LBlockSum: Single;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(0.0);

  LDispatch := GetDispatchTable;
  LHasLoadF32x8 := Assigned(LDispatch^.LoadF32x8);
  LHasReduceAddF32x8 := Assigned(LDispatch^.ReduceAddF32x8);

  LSum := 0.0;
  LC := 0.0;

  while aCount >= 8 do
  begin
    if LHasLoadF32x8 then
      LVec := LDispatch^.LoadF32x8(aSrc)
    else
    begin
      for LIndex := 0 to 7 do
        LVec.f[LIndex] := aSrc[LIndex];
    end;

    if LHasReduceAddF32x8 then
      LBlockSum := LDispatch^.ReduceAddF32x8(LVec)
    else
      LBlockSum :=
        LVec.f[0] + LVec.f[1] + LVec.f[2] + LVec.f[3]
        + LVec.f[4] + LVec.f[5] + LVec.f[6] + LVec.f[7];

    LY := LBlockSum - LC;
    LT := LSum + LY;
    LC := (LT - LSum) - LY;
    LSum := LT;

    Inc(aSrc, 8);
    Dec(aCount, 8);
  end;

  if aCount > 0 then
    for LIndex := 0 to aCount - 1 do
    begin
      LY := aSrc[LIndex] - LC;
      LT := LSum + LY;
      LC := (LT - LSum) - LY;
      LSum := LT;
    end;

  Result := LSum;
end;

function SimdArrayMinF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  LIndex: SizeUInt;
  LVec, LVecMin: TVecF32x8;
  LDispatch: PSimdDispatchTable;
  LCanVectorize: Boolean;
  LChunkMin: Single;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(PosInfinityF32);

  LDispatch := GetDispatchTable;
  LCanVectorize := Assigned(LDispatch^.LoadF32x8)
    and Assigned(LDispatch^.MinF32x8)
    and Assigned(LDispatch^.ReduceMinF32x8);

  Result := aSrc[0];
  Inc(aSrc);
  Dec(aCount);

  if LCanVectorize and (aCount >= 8) then
  begin
    LVecMin := LDispatch^.LoadF32x8(aSrc);
    Inc(aSrc, 8);
    Dec(aCount, 8);

    while aCount >= 8 do
    begin
      LVec := LDispatch^.LoadF32x8(aSrc);
      LVecMin := LDispatch^.MinF32x8(LVecMin, LVec);
      Inc(aSrc, 8);
      Dec(aCount, 8);
    end;

    LChunkMin := LDispatch^.ReduceMinF32x8(LVecMin);
    if LChunkMin < Result then
      Result := LChunkMin;
  end;

  if aCount > 0 then
    for LIndex := 0 to aCount - 1 do
      if aSrc[LIndex] < Result then
        Result := aSrc[LIndex];
end;

function SimdArrayMaxF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  LIndex: SizeUInt;
  LVec, LVecMax: TVecF32x8;
  LDispatch: PSimdDispatchTable;
  LCanVectorize: Boolean;
  LChunkMax: Single;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(NegInfinityF32);

  LDispatch := GetDispatchTable;
  LCanVectorize := Assigned(LDispatch^.LoadF32x8)
    and Assigned(LDispatch^.MaxF32x8)
    and Assigned(LDispatch^.ReduceMaxF32x8);

  Result := aSrc[0];
  Inc(aSrc);
  Dec(aCount);

  if LCanVectorize and (aCount >= 8) then
  begin
    LVecMax := LDispatch^.LoadF32x8(aSrc);
    Inc(aSrc, 8);
    Dec(aCount, 8);

    while aCount >= 8 do
    begin
      LVec := LDispatch^.LoadF32x8(aSrc);
      LVecMax := LDispatch^.MaxF32x8(LVecMax, LVec);
      Inc(aSrc, 8);
      Dec(aCount, 8);
    end;

    LChunkMax := LDispatch^.ReduceMaxF32x8(LVecMax);
    if LChunkMax > Result then
      Result := LChunkMax;
  end;

  if aCount > 0 then
    for LIndex := 0 to aCount - 1 do
      if aSrc[LIndex] > Result then
        Result := aSrc[LIndex];
end;

procedure SimdArrayMinMaxF32(aSrc: PSingle; aCount: SizeUInt; out aMin, aMax: Single);
var
  LIndex: SizeUInt;
  LVec, LVecMin, LVecMax: TVecF32x8;
  LDispatch: PSimdDispatchTable;
  LCanVectorize: Boolean;
  LChunkMin, LChunkMax: Single;
begin
  if (aSrc = nil) or (aCount = 0) then
  begin
    aMin := PosInfinityF32;
    aMax := NegInfinityF32;
    Exit;
  end;

  LDispatch := GetDispatchTable;
  LCanVectorize := Assigned(LDispatch^.LoadF32x8)
    and Assigned(LDispatch^.MinF32x8)
    and Assigned(LDispatch^.MaxF32x8)
    and Assigned(LDispatch^.ReduceMinF32x8)
    and Assigned(LDispatch^.ReduceMaxF32x8);

  aMin := aSrc[0];
  aMax := aSrc[0];
  Inc(aSrc);
  Dec(aCount);

  if LCanVectorize and (aCount >= 8) then
  begin
    LVec := LDispatch^.LoadF32x8(aSrc);
    LVecMin := LVec;
    LVecMax := LVec;
    Inc(aSrc, 8);
    Dec(aCount, 8);

    while aCount >= 8 do
    begin
      LVec := LDispatch^.LoadF32x8(aSrc);
      LVecMin := LDispatch^.MinF32x8(LVecMin, LVec);
      LVecMax := LDispatch^.MaxF32x8(LVecMax, LVec);
      Inc(aSrc, 8);
      Dec(aCount, 8);
    end;

    LChunkMin := LDispatch^.ReduceMinF32x8(LVecMin);
    LChunkMax := LDispatch^.ReduceMaxF32x8(LVecMax);
    if LChunkMin < aMin then
      aMin := LChunkMin;
    if LChunkMax > aMax then
      aMax := LChunkMax;
  end;

  if aCount > 0 then
    for LIndex := 0 to aCount - 1 do
    begin
      if aSrc[LIndex] < aMin then
        aMin := aSrc[LIndex];
      if aSrc[LIndex] > aMax then
        aMax := aSrc[LIndex];
    end;
end;

function SimdArrayMeanF32(aSrc: PSingle; aCount: SizeUInt): Single;
begin
  if aCount = 0 then
    Exit(0.0);
  Result := SimdArraySumF32(aSrc, aCount) / aCount;
end;

function SimdArrayCenteredSumSqF32(aSrc: PSingle; aCount: SizeUInt; aMean: Single): Single;
var
  LIndex: SizeUInt;
  LVec, LMeanVec, LDiff, LSquare: TVecF32x8;
  LDispatch: PSimdDispatchTable;
  LCanVectorize: Boolean;
  LHasReduceAddF32x8: Boolean;
  LDelta: Single;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(0.0);

  LDispatch := GetDispatchTable;
  LCanVectorize := Assigned(LDispatch^.LoadF32x8)
    and Assigned(LDispatch^.SubF32x8)
    and Assigned(LDispatch^.MulF32x8);
  LHasReduceAddF32x8 := Assigned(LDispatch^.ReduceAddF32x8);
  Result := 0.0;

  if LCanVectorize then
  begin
    if Assigned(LDispatch^.SplatF32x8) then
      LMeanVec := LDispatch^.SplatF32x8(aMean)
    else
      for LIndex := 0 to 7 do
        LMeanVec.f[LIndex] := aMean;

    while aCount >= 8 do
    begin
      LVec := LDispatch^.LoadF32x8(aSrc);
      LDiff := LDispatch^.SubF32x8(LVec, LMeanVec);
      LSquare := LDispatch^.MulF32x8(LDiff, LDiff);

      if LHasReduceAddF32x8 then
        Result := Result + LDispatch^.ReduceAddF32x8(LSquare)
      else
        Result := Result
          + LSquare.f[0] + LSquare.f[1] + LSquare.f[2] + LSquare.f[3]
          + LSquare.f[4] + LSquare.f[5] + LSquare.f[6] + LSquare.f[7];

      Inc(aSrc, 8);
      Dec(aCount, 8);
    end;
  end;

  if aCount > 0 then
    for LIndex := 0 to aCount - 1 do
    begin
      LDelta := aSrc[LIndex] - aMean;
      Result := Result + LDelta * LDelta;
    end;
end;


function SimdArrayVarianceF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  LMean: Single;
  LSumSq: Single;
begin
  if (aSrc = nil) or (aCount <= 1) then
    Exit(0.0);

  LMean := SimdArrayMeanF32(aSrc, aCount);
  LSumSq := SimdArrayCenteredSumSqF32(aSrc, aCount, LMean);
  Result := LSumSq / (aCount - 1);
end;

function SimdArrayPopulationVarianceF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  LMean: Single;
  LSumSq: Single;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(0.0);

  LMean := SimdArrayMeanF32(aSrc, aCount);
  LSumSq := SimdArrayCenteredSumSqF32(aSrc, aCount, LMean);
  Result := LSumSq / aCount;
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
  LIndex: SizeUInt;
  LVec1, LVec2, LProd: TVecF32x8;
  LDispatch: PSimdDispatchTable;
  LHasDotF32x8: Boolean;
  LHasLoadF32x8: Boolean;
begin
  if (aSrc1 = nil) or (aSrc2 = nil) or (aCount = 0) then
    Exit(0.0);

  LDispatch := GetDispatchTable;
  LHasDotF32x8 := Assigned(LDispatch^.DotF32x8);
  LHasLoadF32x8 := Assigned(LDispatch^.LoadF32x8);
  Result := 0.0;

  while aCount >= 8 do
  begin
    if LHasLoadF32x8 then
    begin
      LVec1 := LDispatch^.LoadF32x8(aSrc1);
      LVec2 := LDispatch^.LoadF32x8(aSrc2);
    end
    else
    begin
      for LIndex := 0 to 7 do
      begin
        LVec1.f[LIndex] := aSrc1[LIndex];
        LVec2.f[LIndex] := aSrc2[LIndex];
      end;
    end;

    if LHasDotF32x8 then
      Result := Result + LDispatch^.DotF32x8(LVec1, LVec2)
    else
    begin
      LProd := LDispatch^.MulF32x8(LVec1, LVec2);
      Result := Result
        + LProd.f[0] + LProd.f[1] + LProd.f[2] + LProd.f[3]
        + LProd.f[4] + LProd.f[5] + LProd.f[6] + LProd.f[7];
    end;

    Inc(aSrc1, 8);
    Inc(aSrc2, 8);
    Dec(aCount, 8);
  end;

  if aCount > 0 then
    for LIndex := 0 to aCount - 1 do
      Result := Result + aSrc1[LIndex] * aSrc2[LIndex];
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
  LIndex: SizeUInt;
  LVecSrc, LVecFactor, LVecDst: TVecF64x4;
  LDispatch: PSimdDispatchTable;
  LCanVectorize: Boolean;
begin
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  LDispatch := GetDispatchTable;
  LCanVectorize := Assigned(LDispatch^.LoadF64x4)
    and Assigned(LDispatch^.StoreF64x4)
    and Assigned(LDispatch^.SplatF64x4)
    and Assigned(LDispatch^.MulF64x4);

  if LCanVectorize then
  begin
    LVecFactor := LDispatch^.SplatF64x4(aFactor);

    while aCount >= 4 do
    begin
      LVecSrc := LDispatch^.LoadF64x4(aSrc);
      LVecDst := LDispatch^.MulF64x4(LVecSrc, LVecFactor);
      LDispatch^.StoreF64x4(aDst, LVecDst);
      Inc(aSrc, 4);
      Inc(aDst, 4);
      Dec(aCount, 4);
    end;
  end;

  if aCount > 0 then
    for LIndex := 0 to aCount - 1 do
      aDst[LIndex] := aSrc[LIndex] * aFactor;
end;

procedure SimdArrayAbsF64(aSrc, aDst: PDouble; aCount: SizeUInt);
var
  LIndex: SizeUInt;
  LVecSrc, LVecDst: TVecF64x4;
  LDispatch: PSimdDispatchTable;
  LCanVectorize: Boolean;
begin
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  LDispatch := GetDispatchTable;
  LCanVectorize := Assigned(LDispatch^.LoadF64x4)
    and Assigned(LDispatch^.StoreF64x4)
    and Assigned(LDispatch^.AbsF64x4);

  if LCanVectorize then
  begin
    while aCount >= 4 do
    begin
      LVecSrc := LDispatch^.LoadF64x4(aSrc);
      LVecDst := LDispatch^.AbsF64x4(LVecSrc);
      LDispatch^.StoreF64x4(aDst, LVecDst);
      Inc(aSrc, 4);
      Inc(aDst, 4);
      Dec(aCount, 4);
    end;
  end;

  if aCount > 0 then
    for LIndex := 0 to aCount - 1 do
      aDst[LIndex] := System.Abs(aSrc[LIndex]);
end;

procedure SimdArrayAddF64(aSrc, aDst: PDouble; aCount: SizeUInt; aValue: Double);
var
  LIndex: SizeUInt;
  LVecSrc, LVecValue, LVecDst: TVecF64x4;
  LDispatch: PSimdDispatchTable;
  LCanVectorize: Boolean;
begin
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  LDispatch := GetDispatchTable;
  LCanVectorize := Assigned(LDispatch^.LoadF64x4)
    and Assigned(LDispatch^.StoreF64x4)
    and Assigned(LDispatch^.SplatF64x4)
    and Assigned(LDispatch^.AddF64x4);

  if LCanVectorize then
  begin
    LVecValue := LDispatch^.SplatF64x4(aValue);

    while aCount >= 4 do
    begin
      LVecSrc := LDispatch^.LoadF64x4(aSrc);
      LVecDst := LDispatch^.AddF64x4(LVecSrc, LVecValue);
      LDispatch^.StoreF64x4(aDst, LVecDst);
      Inc(aSrc, 4);
      Inc(aDst, 4);
      Dec(aCount, 4);
    end;
  end;

  if aCount > 0 then
    for LIndex := 0 to aCount - 1 do
      aDst[LIndex] := aSrc[LIndex] + aValue;
end;

procedure SimdArrayAddArrayF64(aSrc1, aSrc2, aDst: PDouble; aCount: SizeUInt);
var
  LIndex: SizeUInt;
  LVec1, LVec2, LVecDst: TVecF64x4;
  LDispatch: PSimdDispatchTable;
  LCanVectorize: Boolean;
begin
  if (aSrc1 = nil) or (aSrc2 = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  LDispatch := GetDispatchTable;
  LCanVectorize := Assigned(LDispatch^.LoadF64x4)
    and Assigned(LDispatch^.StoreF64x4)
    and Assigned(LDispatch^.AddF64x4);

  if LCanVectorize then
  begin
    while aCount >= 4 do
    begin
      LVec1 := LDispatch^.LoadF64x4(aSrc1);
      LVec2 := LDispatch^.LoadF64x4(aSrc2);
      LVecDst := LDispatch^.AddF64x4(LVec1, LVec2);
      LDispatch^.StoreF64x4(aDst, LVecDst);
      Inc(aSrc1, 4);
      Inc(aSrc2, 4);
      Inc(aDst, 4);
      Dec(aCount, 4);
    end;
  end;

  if aCount > 0 then
    for LIndex := 0 to aCount - 1 do
      aDst[LIndex] := aSrc1[LIndex] + aSrc2[LIndex];
end;

// ============================================================================
// F32 Element-wise Operations
// ============================================================================

procedure SimdArrayScaleF32(aSrc, aDst: PSingle; aCount: SizeUInt; aFactor: Single);
var
  LIndex: SizeUInt;
  LVecSrc, LVecFactor, LVecDst: TVecF32x8;
  LDispatch: PSimdDispatchTable;
  LCanVectorize: Boolean;
begin
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  LDispatch := GetDispatchTable;
  LCanVectorize := Assigned(LDispatch^.LoadF32x8)
    and Assigned(LDispatch^.StoreF32x8)
    and Assigned(LDispatch^.SplatF32x8)
    and Assigned(LDispatch^.MulF32x8);

  if LCanVectorize then
  begin
    LVecFactor := LDispatch^.SplatF32x8(aFactor);

    while aCount >= 8 do
    begin
      LVecSrc := LDispatch^.LoadF32x8(aSrc);
      LVecDst := LDispatch^.MulF32x8(LVecSrc, LVecFactor);
      LDispatch^.StoreF32x8(aDst, LVecDst);
      Inc(aSrc, 8);
      Inc(aDst, 8);
      Dec(aCount, 8);
    end;
  end;

  if aCount > 0 then
    for LIndex := 0 to aCount - 1 do
      aDst[LIndex] := aSrc[LIndex] * aFactor;
end;

procedure SimdArrayAbsF32(aSrc, aDst: PSingle; aCount: SizeUInt);
var
  LIndex: SizeUInt;
  LVecSrc, LVecDst: TVecF32x8;
  LDispatch: PSimdDispatchTable;
  LCanVectorize: Boolean;
begin
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  LDispatch := GetDispatchTable;
  LCanVectorize := Assigned(LDispatch^.LoadF32x8)
    and Assigned(LDispatch^.StoreF32x8)
    and Assigned(LDispatch^.AbsF32x8);

  if LCanVectorize then
  begin
    while aCount >= 8 do
    begin
      LVecSrc := LDispatch^.LoadF32x8(aSrc);
      LVecDst := LDispatch^.AbsF32x8(LVecSrc);
      LDispatch^.StoreF32x8(aDst, LVecDst);
      Inc(aSrc, 8);
      Inc(aDst, 8);
      Dec(aCount, 8);
    end;
  end;

  if aCount > 0 then
    for LIndex := 0 to aCount - 1 do
      aDst[LIndex] := System.Abs(aSrc[LIndex]);
end;

procedure SimdArrayAddF32(aSrc, aDst: PSingle; aCount: SizeUInt; aValue: Single);
var
  LIndex: SizeUInt;
  LVecSrc, LVecValue, LVecDst: TVecF32x8;
  LDispatch: PSimdDispatchTable;
  LCanVectorize: Boolean;
begin
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  LDispatch := GetDispatchTable;
  LCanVectorize := Assigned(LDispatch^.LoadF32x8)
    and Assigned(LDispatch^.StoreF32x8)
    and Assigned(LDispatch^.SplatF32x8)
    and Assigned(LDispatch^.AddF32x8);

  if LCanVectorize then
  begin
    LVecValue := LDispatch^.SplatF32x8(aValue);

    while aCount >= 8 do
    begin
      LVecSrc := LDispatch^.LoadF32x8(aSrc);
      LVecDst := LDispatch^.AddF32x8(LVecSrc, LVecValue);
      LDispatch^.StoreF32x8(aDst, LVecDst);
      Inc(aSrc, 8);
      Inc(aDst, 8);
      Dec(aCount, 8);
    end;
  end;

  if aCount > 0 then
    for LIndex := 0 to aCount - 1 do
      aDst[LIndex] := aSrc[LIndex] + aValue;
end;

procedure SimdArrayAddArrayF32(aSrc1, aSrc2, aDst: PSingle; aCount: SizeUInt);
var
  LIndex: SizeUInt;
  LVec1, LVec2, LVecDst: TVecF32x8;
  LDispatch: PSimdDispatchTable;
  LCanVectorize: Boolean;
begin
  if (aSrc1 = nil) or (aSrc2 = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  LDispatch := GetDispatchTable;
  LCanVectorize := Assigned(LDispatch^.LoadF32x8)
    and Assigned(LDispatch^.StoreF32x8)
    and Assigned(LDispatch^.AddF32x8);

  if LCanVectorize then
  begin
    while aCount >= 8 do
    begin
      LVec1 := LDispatch^.LoadF32x8(aSrc1);
      LVec2 := LDispatch^.LoadF32x8(aSrc2);
      LVecDst := LDispatch^.AddF32x8(LVec1, LVec2);
      LDispatch^.StoreF32x8(aDst, LVecDst);
      Inc(aSrc1, 8);
      Inc(aSrc2, 8);
      Inc(aDst, 8);
      Dec(aCount, 8);
    end;
  end;

  if aCount > 0 then
    for LIndex := 0 to aCount - 1 do
      aDst[LIndex] := aSrc1[LIndex] + aSrc2[LIndex];
end;

end.
