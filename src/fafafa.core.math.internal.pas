{

```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.math.internal

## Abstract 摘要

Internal helper procedures for fafafa.core.math module.
Provides core algorithms (Kahan summation, MinMax update) to eliminate code duplication.
fafafa.core.math 模块的内部辅助过程，提供核心算法以消除代码重复。

## Declaration 声明

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.

## Note 注意

This unit is for internal use only. Do not import directly.
此单元仅供内部使用，请勿直接导入。
}

unit fafafa.core.math.internal;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

// ============================================================================
// Kahan Summation Core
// Implements compensated summation to reduce floating-point rounding errors.
// 实现补偿求和以减少浮点舍入误差。
// ============================================================================

{**
 * KahanAccumulateF64
 *
 * @desc
 *   Performs one step of Kahan compensated summation (Double precision).
 *   执行一步 Kahan 补偿求和（双精度）。
 *
 * @param aSum
 *   The running sum (in/out). / 累加和（输入/输出）。
 *
 * @param aComp
 *   The compensation value (in/out). / 补偿值（输入/输出）。
 *
 * @param aValue
 *   The value to add. / 要添加的值。
 *
 * @note
 *   Kahan algorithm reduces rounding errors from O(n*epsilon) to O(epsilon).
 *   Kahan 算法将舍入误差从 O(n*epsilon) 降低到 O(epsilon)。
 *}
procedure KahanAccumulateF64(var aSum, aComp: Double; aValue: Double); {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * KahanAccumulateF32
 *
 * @desc
 *   Performs one step of Kahan compensated summation (Single precision).
 *   执行一步 Kahan 补偿求和（单精度）。
 *}
procedure KahanAccumulateF32(var aSum, aComp: Single; aValue: Single); {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// ============================================================================
// MinMax Update Core
// Updates running minimum and maximum values.
// 更新运行中的最小值和最大值。
// ============================================================================

{**
 * MinMaxUpdateF64
 *
 * @desc
 *   Updates running min/max with a new value (Double precision).
 *   使用新值更新运行中的最小/最大值（双精度）。
 *
 * @param aValue
 *   The new value to compare. / 要比较的新值。
 *
 * @param aMin
 *   The running minimum (in/out). / 运行中的最小值（输入/输出）。
 *
 * @param aMax
 *   The running maximum (in/out). / 运行中的最大值（输入/输出）。
 *}
procedure MinMaxUpdateF64(aValue: Double; var aMin, aMax: Double); {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * MinMaxUpdateF32
 *
 * @desc
 *   Updates running min/max with a new value (Single precision).
 *   使用新值更新运行中的最小/最大值（单精度）。
 *}
procedure MinMaxUpdateF32(aValue: Single; var aMin, aMax: Single); {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// ============================================================================
// Sum of Squared Differences Core
// Used for variance and standard deviation calculations.
// 用于方差和标准差计算。
// ============================================================================

{**
 * SumSquaredDiffsF64
 *
 * @desc
 *   Computes sum of squared differences from mean (Double precision).
 *   计算与均值的平方差之和（双精度）。
 *
 * @param aSrc
 *   Pointer to source array. / 源数组指针。
 *
 * @param aCount
 *   Number of elements. / 元素数量。
 *
 * @param aMean
 *   The mean value. / 均值。
 *
 * @returns
 *   Sum of (x[i] - mean)^2 for all elements.
 *}
function SumSquaredDiffsF64(aSrc: PDouble; aCount: SizeUInt; aMean: Double): Double;

{**
 * SumSquaredDiffsF32
 *
 * @desc
 *   Computes sum of squared differences from mean (Single precision).
 *   计算与均值的平方差之和（单精度）。
 *}
function SumSquaredDiffsF32(aSrc: PSingle; aCount: SizeUInt; aMean: Single): Single;

// ============================================================================
// IEEE 754 Bit Manipulation Helpers
// Helpers for NaN/Inf detection and creation.
// NaN/Inf 检测和创建的辅助函数。
// ============================================================================

const
  // F64 special value bit patterns (use QWord cast to avoid range check warnings)
  kF64_PosInfBits: QWord = QWord($7FF0000000000000);
  kF64_NegInfBits: QWord = QWord($FFF0000000000000);
  kF64_QNaNBits: QWord   = QWord($7FF8000000000000);

  // F32 special value bit patterns
  kF32_PosInfBits: UInt32 = UInt32($7F800000);
  kF32_NegInfBits: UInt32 = UInt32($FF800000);
  kF32_QNaNBits: UInt32   = UInt32($7FC00000);

{**
 * F64FromBits
 *
 * @desc
 *   Reinterpret QWord bits as Double.
 *   将 QWord 位重新解释为 Double。
 *}
function F64FromBits(aBits: QWord): Double; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * F32FromBits
 *
 * @desc
 *   Reinterpret UInt32 bits as Single.
 *   将 UInt32 位重新解释为 Single。
 *}
function F32FromBits(aBits: UInt32): Single; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * IsNaNF64
 *
 * @desc
 *   Check if Double is NaN (any bit pattern).
 *   检查 Double 是否为 NaN（任意位模式）。
 *}
function IsNaNF64(aValue: Double): Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * IsNaNF32
 *
 * @desc
 *   Check if Single is NaN (any bit pattern).
 *   检查 Single 是否为 NaN（任意位模式）。
 *}
function IsNaNF32(aValue: Single): Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

implementation

// Disable range/overflow checks for performance
{$PUSH}
{$R-}
{$Q-}

// ============================================================================
// Kahan Summation Implementation
// ============================================================================

procedure KahanAccumulateF64(var aSum, aComp: Double; aValue: Double);
var
  y, t: Double;
begin
  // Kahan compensated summation algorithm:
  // 1. Subtract the compensation from the value
  // 2. Add to the running sum
  // 3. Update compensation = (new sum - old sum) - corrected value
  y := aValue - aComp;
  t := aSum + y;
  aComp := (t - aSum) - y;
  aSum := t;
end;

procedure KahanAccumulateF32(var aSum, aComp: Single; aValue: Single);
var
  y, t: Single;
begin
  y := aValue - aComp;
  t := aSum + y;
  aComp := (t - aSum) - y;
  aSum := t;
end;

// ============================================================================
// MinMax Update Implementation
// ============================================================================

procedure MinMaxUpdateF64(aValue: Double; var aMin, aMax: Double);
begin
  if aValue < aMin then
    aMin := aValue;
  if aValue > aMax then
    aMax := aValue;
end;

procedure MinMaxUpdateF32(aValue: Single; var aMin, aMax: Single);
begin
  if aValue < aMin then
    aMin := aValue;
  if aValue > aMax then
    aMax := aValue;
end;

// ============================================================================
// Sum of Squared Differences Implementation
// ============================================================================

function SumSquaredDiffsF64(aSrc: PDouble; aCount: SizeUInt; aMean: Double): Double;
var
  i: SizeUInt;
  diff: Double;
begin
  Result := 0.0;
  if (aSrc = nil) or (aCount = 0) then
    Exit;

  for i := 0 to aCount - 1 do
  begin
    diff := aSrc[i] - aMean;
    Result := Result + (diff * diff);
  end;
end;

function SumSquaredDiffsF32(aSrc: PSingle; aCount: SizeUInt; aMean: Single): Single;
var
  i: SizeUInt;
  diff: Single;
begin
  Result := 0.0;
  if (aSrc = nil) or (aCount = 0) then
    Exit;

  for i := 0 to aCount - 1 do
  begin
    diff := aSrc[i] - aMean;
    Result := Result + (diff * diff);
  end;
end;

// ============================================================================
// IEEE 754 Bit Manipulation Implementation
// ============================================================================

function F64FromBits(aBits: QWord): Double;
begin
  Move(aBits, Result, SizeOf(Double));
end;

function F32FromBits(aBits: UInt32): Single;
begin
  Move(aBits, Result, SizeOf(Single));
end;

function IsNaNF64(aValue: Double): Boolean;
var
  bits: UInt64;
begin
  Move(aValue, bits, SizeOf(Double));
  // NaN: exponent all 1s, fraction non-zero
  Result := ((bits and $7FF0000000000000) = $7FF0000000000000) and
            ((bits and $000FFFFFFFFFFFFF) <> 0);
end;

function IsNaNF32(aValue: Single): Boolean;
var
  bits: UInt32;
begin
  Move(aValue, bits, SizeOf(Single));
  // NaN: exponent all 1s, fraction non-zero
  Result := ((bits and $7F800000) = $7F800000) and
            ((bits and $007FFFFF) <> 0);
end;

{$POP}

end.
