{

```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.math.array_

## Abstract 摘要

Batch array mathematical operations.
Provides scalar baseline implementations; future SIMD versions can be dispatched.
批量数组数学运算，提供标量基线实现；将来可通过 dispatch 切换到 SIMD 版本。

## Declaration 声明

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

unit fafafa.core.math.array_;

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

{$POP}

end.
