{

```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.math.arrays

## Abstract 摘要

Batch array mathematical operations.
Provides scalar baseline implementations; future SIMD versions can be dispatched.
批量数组数学运算，提供标量基线实现；将来可通过 dispatch 切换到 SIMD 版本。

## Declaration 声明

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

unit fafafa.core.math.arrays;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

// ============================================================================
// Reduction Operations (返回单一值)
// ============================================================================

{**
 * ArraySumF64
 *
 * @desc
 *   Sum all elements in a Double array.
 *   求 Double 数组所有元素之和。
 *}
function ArraySumF64(aSrc: PDouble; aCount: SizeUInt): Double; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * ArraySumF32
 *
 * @desc
 *   Sum all elements in a Single array.
 *   求 Single 数组所有元素之和。
 *}
function ArraySumF32(aSrc: PSingle; aCount: SizeUInt): Single; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * ArrayMinF64
 *
 * @desc
 *   Find minimum value in a Double array.
 *   求 Double 数组的最小值。
 *
 * @note
 *   Returns +Inf for empty array (aCount = 0).
 *}
function ArrayMinF64(aSrc: PDouble; aCount: SizeUInt): Double; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * ArrayMaxF64
 *
 * @desc
 *   Find maximum value in a Double array.
 *   求 Double 数组的最大值。
 *
 * @note
 *   Returns -Inf for empty array (aCount = 0).
 *}
function ArrayMaxF64(aSrc: PDouble; aCount: SizeUInt): Double; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * ArrayMinMaxF64
 *
 * @desc
 *   Find both minimum and maximum in one pass.
 *   一次遍历同时求最小值和最大值。
 *}
procedure ArrayMinMaxF64(aSrc: PDouble; aCount: SizeUInt; out aMin, aMax: Double);

{**
 * ArrayMeanF64
 *
 * @desc
 *   Calculate arithmetic mean of a Double array.
 *   求 Double 数组的算术平均值。
 *
 * @note
 *   Returns 0 for empty array.
 *}
function ArrayMeanF64(aSrc: PDouble; aCount: SizeUInt): Double; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// ============================================================================
// Element-wise Operations (逐元素操作，输出到目标数组)
// ============================================================================

{**
 * ArrayAbsF64
 *
 * @desc
 *   Compute absolute value for each element.
 *   对每个元素求绝对值。
 *
 * @note
 *   aSrc and aDst may overlap (in-place operation allowed).
 *}
procedure ArrayAbsF64(aSrc, aDst: PDouble; aCount: SizeUInt);

{**
 * ArrayScaleF64
 *
 * @desc
 *   Multiply each element by a scalar factor.
 *   将每个元素乘以标量因子。
 *
 * @note
 *   aSrc and aDst may overlap.
 *}
procedure ArrayScaleF64(aSrc, aDst: PDouble; aCount: SizeUInt; aFactor: Double);

{**
 * ArrayAddF64
 *
 * @desc
 *   Add a constant to each element.
 *   为每个元素加上常数。
 *
 * @note
 *   aSrc and aDst may overlap.
 *}
procedure ArrayAddF64(aSrc, aDst: PDouble; aCount: SizeUInt; aValue: Double);

// ============================================================================
// Advanced F64 Functions (Kahan, Variance, StdDev, DotProduct, L2Norm)
// ============================================================================

function ArraySumKahanF64(aSrc: PDouble; aCount: SizeUInt): Double;
function ArrayDotProductF64(aSrc1, aSrc2: PDouble; aCount: SizeUInt): Double;
function ArrayVarianceF64(aSrc: PDouble; aCount: SizeUInt): Double;
function ArrayPopulationVarianceF64(aSrc: PDouble; aCount: SizeUInt): Double;
function ArrayStdDevF64(aSrc: PDouble; aCount: SizeUInt): Double;
function ArrayPopulationStdDevF64(aSrc: PDouble; aCount: SizeUInt): Double;
function ArrayL2NormF64(aSrc: PDouble; aCount: SizeUInt): Double;
procedure ArrayAddArrayF64(aSrc1, aSrc2, aDst: PDouble; aCount: SizeUInt);

// ============================================================================
// F32 Functions (Single precision)
// ============================================================================

function ArraySumKahanF32(aSrc: PSingle; aCount: SizeUInt): Single;
function ArrayMinF32(aSrc: PSingle; aCount: SizeUInt): Single;
function ArrayMaxF32(aSrc: PSingle; aCount: SizeUInt): Single;
procedure ArrayMinMaxF32(aSrc: PSingle; aCount: SizeUInt; out aMin, aMax: Single);
function ArrayMeanF32(aSrc: PSingle; aCount: SizeUInt): Single;
function ArrayVarianceF32(aSrc: PSingle; aCount: SizeUInt): Single;
function ArrayPopulationVarianceF32(aSrc: PSingle; aCount: SizeUInt): Single;
function ArrayStdDevF32(aSrc: PSingle; aCount: SizeUInt): Single;
function ArrayPopulationStdDevF32(aSrc: PSingle; aCount: SizeUInt): Single;
function ArrayDotProductF32(aSrc1, aSrc2: PSingle; aCount: SizeUInt): Single;
function ArrayL2NormF32(aSrc: PSingle; aCount: SizeUInt): Single;
procedure ArrayScaleF32(aSrc, aDst: PSingle; aCount: SizeUInt; aFactor: Single);
procedure ArrayAbsF32(aSrc, aDst: PSingle; aCount: SizeUInt);
procedure ArrayAddF32(aSrc, aDst: PSingle; aCount: SizeUInt; aValue: Single);
procedure ArrayAddArrayF32(aSrc1, aSrc2, aDst: PSingle; aCount: SizeUInt);

implementation

uses
  Math;  // For Infinity

// ============================================================================
// Reduction Operations Implementation
// ============================================================================

// 禁用范围检查，因为循环使用 0 to aCount-1 模式
{$PUSH}
{$R-}
{$Q-}

function ArraySumF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  i: SizeUInt;
begin
  Result := 0.0;
  if (aSrc = nil) or (aCount = 0) then
    Exit;

  for i := 0 to aCount - 1 do
    Result := Result + aSrc[i];
end;

function ArraySumF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  i: SizeUInt;
begin
  Result := 0.0;
  if (aSrc = nil) or (aCount = 0) then
    Exit;

  for i := 0 to aCount - 1 do
    Result := Result + aSrc[i];
end;

function ArrayMinF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  i: SizeUInt;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(Infinity);

  Result := aSrc[0];
  for i := 1 to aCount - 1 do
    if aSrc[i] < Result then
      Result := aSrc[i];
end;

function ArrayMaxF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  i: SizeUInt;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(NegInfinity);

  Result := aSrc[0];
  for i := 1 to aCount - 1 do
    if aSrc[i] > Result then
      Result := aSrc[i];
end;

procedure ArrayMinMaxF64(aSrc: PDouble; aCount: SizeUInt; out aMin, aMax: Double);
var
  i: SizeUInt;
begin
  if (aSrc = nil) or (aCount = 0) then
  begin
    aMin := Infinity;
    aMax := NegInfinity;
    Exit;
  end;

  aMin := aSrc[0];
  aMax := aSrc[0];
  for i := 1 to aCount - 1 do
  begin
    if aSrc[i] < aMin then
      aMin := aSrc[i];
    if aSrc[i] > aMax then
      aMax := aSrc[i];
  end;
end;

function ArrayMeanF64(aSrc: PDouble; aCount: SizeUInt): Double;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(0.0);

  Result := ArraySumF64(aSrc, aCount) / aCount;
end;

// ============================================================================
// Element-wise Operations Implementation
// ============================================================================

procedure ArrayAbsF64(aSrc, aDst: PDouble; aCount: SizeUInt);
var
  i: SizeUInt;
begin
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  for i := 0 to aCount - 1 do
    if aSrc[i] < 0 then
      aDst[i] := -aSrc[i]
    else
      aDst[i] := aSrc[i];
end;

procedure ArrayScaleF64(aSrc, aDst: PDouble; aCount: SizeUInt; aFactor: Double);
var
  i: SizeUInt;
begin
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  for i := 0 to aCount - 1 do
    aDst[i] := aSrc[i] * aFactor;
end;

procedure ArrayAddF64(aSrc, aDst: PDouble; aCount: SizeUInt; aValue: Double);
var
  i: SizeUInt;
begin
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  for i := 0 to aCount - 1 do
    aDst[i] := aSrc[i] + aValue;
end;

// ============================================================================
// Advanced F64 Functions Implementation
// ============================================================================

function ArraySumKahanF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  i: SizeUInt;
  c, y, t: Double;
begin
  Result := 0.0;
  c := 0.0;
  if (aSrc = nil) or (aCount = 0) then
    Exit;

  for i := 0 to aCount - 1 do
  begin
    y := aSrc[i] - c;
    t := Result + y;
    c := (t - Result) - y;
    Result := t;
  end;
end;

function ArrayDotProductF64(aSrc1, aSrc2: PDouble; aCount: SizeUInt): Double;
var
  i: SizeUInt;
  c, y, t: Double;
begin
  Result := 0.0;
  c := 0.0;
  if (aSrc1 = nil) or (aSrc2 = nil) or (aCount = 0) then
    Exit;

  for i := 0 to aCount - 1 do
  begin
    y := (aSrc1[i] * aSrc2[i]) - c;
    t := Result + y;
    c := (t - Result) - y;
    Result := t;
  end;
end;

function ArrayVarianceF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  i: SizeUInt;
  mean, sum: Double;
begin
  Result := 0.0;
  if (aSrc = nil) or (aCount < 2) then
    Exit;

  mean := ArrayMeanF64(aSrc, aCount);
  sum := 0.0;
  for i := 0 to aCount - 1 do
    sum := sum + Sqr(aSrc[i] - mean);
  Result := sum / (aCount - 1);
end;

function ArrayPopulationVarianceF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  i: SizeUInt;
  mean, sum: Double;
begin
  Result := 0.0;
  if (aSrc = nil) or (aCount = 0) then
    Exit;

  mean := ArrayMeanF64(aSrc, aCount);
  sum := 0.0;
  for i := 0 to aCount - 1 do
    sum := sum + Sqr(aSrc[i] - mean);
  Result := sum / aCount;
end;

function ArrayStdDevF64(aSrc: PDouble; aCount: SizeUInt): Double;
begin
  Result := Sqrt(ArrayVarianceF64(aSrc, aCount));
end;

function ArrayPopulationStdDevF64(aSrc: PDouble; aCount: SizeUInt): Double;
begin
  Result := Sqrt(ArrayPopulationVarianceF64(aSrc, aCount));
end;

function ArrayL2NormF64(aSrc: PDouble; aCount: SizeUInt): Double;
var
  i: SizeUInt;
  sum: Double;
begin
  Result := 0.0;
  if (aSrc = nil) or (aCount = 0) then
    Exit;

  sum := 0.0;
  for i := 0 to aCount - 1 do
    sum := sum + Sqr(aSrc[i]);
  Result := Sqrt(sum);
end;

procedure ArrayAddArrayF64(aSrc1, aSrc2, aDst: PDouble; aCount: SizeUInt);
var
  i: SizeUInt;
begin
  if (aSrc1 = nil) or (aSrc2 = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  for i := 0 to aCount - 1 do
    aDst[i] := aSrc1[i] + aSrc2[i];
end;

// ============================================================================
// F32 Functions Implementation
// ============================================================================

function ArraySumKahanF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  i: SizeUInt;
  c, y, t: Single;
begin
  Result := 0.0;
  c := 0.0;
  if (aSrc = nil) or (aCount = 0) then
    Exit;

  for i := 0 to aCount - 1 do
  begin
    y := aSrc[i] - c;
    t := Result + y;
    c := (t - Result) - y;
    Result := t;
  end;
end;

function ArrayMinF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  i: SizeUInt;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(Infinity);

  Result := aSrc[0];
  for i := 1 to aCount - 1 do
    if aSrc[i] < Result then
      Result := aSrc[i];
end;

function ArrayMaxF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  i: SizeUInt;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(NegInfinity);

  Result := aSrc[0];
  for i := 1 to aCount - 1 do
    if aSrc[i] > Result then
      Result := aSrc[i];
end;

procedure ArrayMinMaxF32(aSrc: PSingle; aCount: SizeUInt; out aMin, aMax: Single);
var
  i: SizeUInt;
begin
  if (aSrc = nil) or (aCount = 0) then
  begin
    aMin := Infinity;
    aMax := NegInfinity;
    Exit;
  end;

  aMin := aSrc[0];
  aMax := aSrc[0];
  for i := 1 to aCount - 1 do
  begin
    if aSrc[i] < aMin then
      aMin := aSrc[i];
    if aSrc[i] > aMax then
      aMax := aSrc[i];
  end;
end;

function ArrayMeanF32(aSrc: PSingle; aCount: SizeUInt): Single;
begin
  if (aSrc = nil) or (aCount = 0) then
    Exit(0.0);

  Result := ArraySumF32(aSrc, aCount) / aCount;
end;

function ArrayVarianceF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  i: SizeUInt;
  mean, sum: Single;
begin
  Result := 0.0;
  if (aSrc = nil) or (aCount < 2) then
    Exit;

  mean := ArrayMeanF32(aSrc, aCount);
  sum := 0.0;
  for i := 0 to aCount - 1 do
    sum := sum + Sqr(aSrc[i] - mean);
  Result := sum / (aCount - 1);
end;

function ArrayPopulationVarianceF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  i: SizeUInt;
  mean, sum: Single;
begin
  Result := 0.0;
  if (aSrc = nil) or (aCount = 0) then
    Exit;

  mean := ArrayMeanF32(aSrc, aCount);
  sum := 0.0;
  for i := 0 to aCount - 1 do
    sum := sum + Sqr(aSrc[i] - mean);
  Result := sum / aCount;
end;

function ArrayStdDevF32(aSrc: PSingle; aCount: SizeUInt): Single;
begin
  Result := Sqrt(ArrayVarianceF32(aSrc, aCount));
end;

function ArrayPopulationStdDevF32(aSrc: PSingle; aCount: SizeUInt): Single;
begin
  Result := Sqrt(ArrayPopulationVarianceF32(aSrc, aCount));
end;

function ArrayDotProductF32(aSrc1, aSrc2: PSingle; aCount: SizeUInt): Single;
var
  i: SizeUInt;
  c, y, t: Single;
begin
  Result := 0.0;
  c := 0.0;
  if (aSrc1 = nil) or (aSrc2 = nil) or (aCount = 0) then
    Exit;

  for i := 0 to aCount - 1 do
  begin
    y := (aSrc1[i] * aSrc2[i]) - c;
    t := Result + y;
    c := (t - Result) - y;
    Result := t;
  end;
end;

function ArrayL2NormF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  i: SizeUInt;
  sum: Single;
begin
  Result := 0.0;
  if (aSrc = nil) or (aCount = 0) then
    Exit;

  sum := 0.0;
  for i := 0 to aCount - 1 do
    sum := sum + Sqr(aSrc[i]);
  Result := Sqrt(sum);
end;

procedure ArrayScaleF32(aSrc, aDst: PSingle; aCount: SizeUInt; aFactor: Single);
var
  i: SizeUInt;
begin
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  for i := 0 to aCount - 1 do
    aDst[i] := aSrc[i] * aFactor;
end;

procedure ArrayAbsF32(aSrc, aDst: PSingle; aCount: SizeUInt);
var
  i: SizeUInt;
begin
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  for i := 0 to aCount - 1 do
    if aSrc[i] < 0 then
      aDst[i] := -aSrc[i]
    else
      aDst[i] := aSrc[i];
end;

procedure ArrayAddF32(aSrc, aDst: PSingle; aCount: SizeUInt; aValue: Single);
var
  i: SizeUInt;
begin
  if (aSrc = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  for i := 0 to aCount - 1 do
    aDst[i] := aSrc[i] + aValue;
end;

procedure ArrayAddArrayF32(aSrc1, aSrc2, aDst: PSingle; aCount: SizeUInt);
var
  i: SizeUInt;
begin
  if (aSrc1 = nil) or (aSrc2 = nil) or (aDst = nil) or (aCount = 0) then
    Exit;

  for i := 0 to aCount - 1 do
    aDst[i] := aSrc1[i] + aSrc2[i];
end;

{$POP}

end.
