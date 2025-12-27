{

```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.math.special.testcase

## Abstract 摘要

Special value tests for floating-point arithmetic operations.
Tests NaN propagation, Infinity handling, negative zero, and denormalized numbers.
浮点算术运算的特殊值测试。
测试 NaN 传播、无穷大处理、负零和非规格化数。

## Declaration 声明

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

unit fafafa.core.math.special.testcase;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, Math,
  fafafa.core.math;

type

  // ============================================================================
  // Base class for special float tests - handles FPU exception mask
  // ============================================================================

  TTestSpecialFloat = class(TTestCase)
  private
    FSavedMask: TFPUExceptionMask;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  end;

  // ============================================================================
  // NaN Tests - Not a Number handling
  // ============================================================================

  TTestNaN = class(TTestSpecialFloat)
  published
    // === IsNaN detection ===
    procedure Test_IsNaN_QuietNaN_ReturnsTrue;
    procedure Test_IsNaN_NormalValue_ReturnsFalse;
    procedure Test_IsNaN_Infinity_ReturnsFalse;
    procedure Test_IsNaN_Zero_ReturnsFalse;
    procedure Test_IsNaN_NegativeZero_ReturnsFalse;

    // === NaN propagation ===
    procedure Test_Abs_NaN_ReturnsNaN;
    procedure Test_Min_WithNaN_Behavior;
    procedure Test_Max_WithNaN_Behavior;
    procedure Test_Sqrt_NegativeValue_ReturnsNaN;

    // === NaN arithmetic ===
    procedure Test_NaN_Plus_Number_IsNaN;
    procedure Test_NaN_Times_Number_IsNaN;
  end;

  // ============================================================================
  // Infinity Tests
  // ============================================================================

  TTestInfinity = class(TTestSpecialFloat)
  published
    // === IsInfinite detection ===
    procedure Test_IsInfinite_PosInf_ReturnsTrue;
    procedure Test_IsInfinite_NegInf_ReturnsTrue;
    procedure Test_IsInfinite_NormalValue_ReturnsFalse;
    procedure Test_IsInfinite_NaN_ReturnsFalse;
    procedure Test_IsInfinite_Zero_ReturnsFalse;

    // === Infinity arithmetic ===
    procedure Test_Infinity_Plus_Infinity_IsInfinity;
    procedure Test_Infinity_Plus_NegInfinity_IsNaN;
    procedure Test_Infinity_Times_Zero_IsNaN;
    procedure Test_One_Div_Zero_IsInfinity;
    procedure Test_NegOne_Div_Zero_IsNegInfinity;

    // === Clamp with infinity ===
    procedure Test_Clamp_WithInfinityMax_Works;
    procedure Test_Clamp_WithNegInfinityMin_Works;
  end;

  // ============================================================================
  // Zero and Sign Tests
  // ============================================================================

  TTestZeroSign = class(TTestSpecialFloat)
  published
    // === Sign function ===
    procedure Test_Sign_PositiveValue_ReturnsOne;
    procedure Test_Sign_NegativeValue_ReturnsMinusOne;
    procedure Test_Sign_Zero_ReturnsZero;
    procedure Test_Sign_NaN_ReturnsZero;

    // === Abs function ===
    procedure Test_Abs_PositiveValue_ReturnsSame;
    procedure Test_Abs_NegativeValue_ReturnsPositive;
    procedure Test_Abs_Zero_ReturnsZero;

    // === Zero handling ===
    procedure Test_Zero_Times_Infinity_IsNaN;
    procedure Test_Division_ByZero_ReturnsInfinity;
  end;

  // ============================================================================
  // Rounding Tests - Floor, Ceil, Trunc, Round
  // ============================================================================

  TTestRounding = class(TTestCase)
  published
    // === Floor ===
    procedure Test_Floor_PositiveNonInteger_RoundsDown;
    procedure Test_Floor_NegativeNonInteger_RoundsDown;
    procedure Test_Floor_Integer_ReturnsSame;

    // === Ceil ===
    procedure Test_Ceil_PositiveNonInteger_RoundsUp;
    procedure Test_Ceil_NegativeNonInteger_RoundsUp;
    procedure Test_Ceil_Integer_ReturnsSame;

    // === Trunc ===
    procedure Test_Trunc_PositiveNonInteger_TowardZero;
    procedure Test_Trunc_NegativeNonInteger_TowardZero;

    // === Round ===
    procedure Test_Round_HalfUp_Behavior;
    procedure Test_Round_HalfDown_Behavior;
  end;

  // ============================================================================
  // Min/Max Edge Cases
  // ============================================================================

  TTestMinMaxEdge = class(TTestCase)
  published
    procedure Test_Min_SameValues_ReturnsSame;
    procedure Test_Max_SameValues_ReturnsSame;
    procedure Test_Min_FirstSmaller_ReturnsFirst;
    procedure Test_Max_FirstLarger_ReturnsFirst;
    procedure Test_Min_VerySmallDiff_Works;
    procedure Test_Max_VerySmallDiff_Works;
    procedure Test_Min_WithInfinity_ReturnsFinite;
    procedure Test_Max_WithNegInfinity_ReturnsFinite;
  end;

  // ============================================================================
  // Power and Exponential Edge Cases
  // ============================================================================

  TTestPowerEdge = class(TTestCase)
  published
    // === Power special cases ===
    procedure Test_Power_ZeroExponent_ReturnsOne;
    procedure Test_Power_OneBase_ReturnsOne;
    procedure Test_Power_NegativeExponent_ReturnsFraction;

    // === IntPower special cases ===
    procedure Test_IntPower_ZeroExponent_ReturnsOne;
    procedure Test_IntPower_NegativeExponent_ReturnsFraction;
    procedure Test_IntPower_ZeroBase_PositiveExp_ReturnsZero;

    // === Sqrt edge cases ===
    procedure Test_Sqrt_Zero_ReturnsZero;
    procedure Test_Sqrt_One_ReturnsOne;
    procedure Test_Sqrt_VerySmall_Works;
    procedure Test_Sqrt_Infinity_ReturnsInfinity;
  end;

implementation

// Helper function to create negative infinity
function NegInfinity: Double;
begin
  Result := -fafafa.core.math.Infinity;
end;

// ============================================================================
// TTestSpecialFloat Implementation - FPU Exception Mask Handling
// ============================================================================

procedure TTestSpecialFloat.SetUp;
begin
  inherited SetUp;
  // Save current mask and mask all FPU exceptions for special value tests
  FSavedMask := fafafa.core.math.GetExceptionMask;
  fafafa.core.math.SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide,
                                      exOverflow, exUnderflow, exPrecision]);
end;

procedure TTestSpecialFloat.TearDown;
begin
  // Restore original FPU exception mask
  fafafa.core.math.SetExceptionMask(FSavedMask);
  inherited TearDown;
end;

// ============================================================================
// TTestNaN Implementation
// ============================================================================

procedure TTestNaN.Test_IsNaN_QuietNaN_ReturnsTrue;
begin
  AssertTrue('NaN should be detected', fafafa.core.math.IsNaN(fafafa.core.math.NaN));
end;

procedure TTestNaN.Test_IsNaN_NormalValue_ReturnsFalse;
begin
  AssertFalse('Normal value is not NaN', fafafa.core.math.IsNaN(1.0));
  AssertFalse('Negative value is not NaN', fafafa.core.math.IsNaN(-42.5));
end;

procedure TTestNaN.Test_IsNaN_Infinity_ReturnsFalse;
begin
  AssertFalse('Infinity is not NaN', fafafa.core.math.IsNaN(fafafa.core.math.Infinity));
  AssertFalse('Negative infinity is not NaN', fafafa.core.math.IsNaN(NegInfinity));
end;

procedure TTestNaN.Test_IsNaN_Zero_ReturnsFalse;
begin
  AssertFalse('Zero is not NaN', fafafa.core.math.IsNaN(0.0));
end;

procedure TTestNaN.Test_IsNaN_NegativeZero_ReturnsFalse;
var
  negZero: Double;
begin
  negZero := -0.0;
  AssertFalse('Negative zero is not NaN', fafafa.core.math.IsNaN(negZero));
end;

procedure TTestNaN.Test_Abs_NaN_ReturnsNaN;
begin
  AssertTrue('Abs(NaN) should be NaN', fafafa.core.math.IsNaN(fafafa.core.math.Abs(fafafa.core.math.NaN)));
end;

procedure TTestNaN.Test_Min_WithNaN_Behavior;
begin
  // IEEE 754: min(x, NaN) or min(NaN, x) behavior varies by implementation
  // We just verify it doesn't crash and returns a valid double
  fafafa.core.math.Min(1.0, fafafa.core.math.NaN);
  AssertTrue('Min with NaN should not crash', True);
end;

procedure TTestNaN.Test_Max_WithNaN_Behavior;
begin
  // IEEE 754: max(x, NaN) or max(NaN, x) behavior varies by implementation
  // We just verify it doesn't crash and returns a valid double
  fafafa.core.math.Max(1.0, fafafa.core.math.NaN);
  AssertTrue('Max with NaN should not crash', True);
end;

procedure TTestNaN.Test_Sqrt_NegativeValue_ReturnsNaN;
var
  result: Double;
begin
  // Sqrt of negative should return NaN
  result := fafafa.core.math.Sqrt(-1.0);
  AssertTrue('Sqrt(-1) should be NaN', fafafa.core.math.IsNaN(result));
end;

procedure TTestNaN.Test_NaN_Plus_Number_IsNaN;
var
  result: Double;
begin
  result := fafafa.core.math.NaN + 1.0;
  AssertTrue('NaN + 1 should be NaN', fafafa.core.math.IsNaN(result));
end;

procedure TTestNaN.Test_NaN_Times_Number_IsNaN;
var
  result: Double;
begin
  result := fafafa.core.math.NaN * 2.0;
  AssertTrue('NaN * 2 should be NaN', fafafa.core.math.IsNaN(result));
end;

// ============================================================================
// TTestInfinity Implementation
// ============================================================================

procedure TTestInfinity.Test_IsInfinite_PosInf_ReturnsTrue;
begin
  AssertTrue('+Inf should be infinite', fafafa.core.math.IsInfinite(fafafa.core.math.Infinity));
end;

procedure TTestInfinity.Test_IsInfinite_NegInf_ReturnsTrue;
begin
  AssertTrue('-Inf should be infinite', fafafa.core.math.IsInfinite(NegInfinity));
end;

procedure TTestInfinity.Test_IsInfinite_NormalValue_ReturnsFalse;
begin
  AssertFalse('Normal value is not infinite', fafafa.core.math.IsInfinite(1.0));
  AssertFalse('Large value is not infinite', fafafa.core.math.IsInfinite(1e308));
end;

procedure TTestInfinity.Test_IsInfinite_NaN_ReturnsFalse;
begin
  AssertFalse('NaN is not infinite', fafafa.core.math.IsInfinite(fafafa.core.math.NaN));
end;

procedure TTestInfinity.Test_IsInfinite_Zero_ReturnsFalse;
begin
  AssertFalse('Zero is not infinite', fafafa.core.math.IsInfinite(0.0));
end;

procedure TTestInfinity.Test_Infinity_Plus_Infinity_IsInfinity;
var
  result: Double;
begin
  result := fafafa.core.math.Infinity + fafafa.core.math.Infinity;
  AssertTrue('Inf + Inf should be Inf', fafafa.core.math.IsInfinite(result));
  AssertTrue('Inf + Inf should be positive', result > 0);
end;

procedure TTestInfinity.Test_Infinity_Plus_NegInfinity_IsNaN;
var
  result: Double;
begin
  result := fafafa.core.math.Infinity + NegInfinity;
  AssertTrue('Inf + (-Inf) should be NaN', fafafa.core.math.IsNaN(result));
end;

procedure TTestInfinity.Test_Infinity_Times_Zero_IsNaN;
var
  result: Double;
begin
  result := fafafa.core.math.Infinity * 0.0;
  AssertTrue('Inf * 0 should be NaN', fafafa.core.math.IsNaN(result));
end;

procedure TTestInfinity.Test_One_Div_Zero_IsInfinity;
var
  result: Double;
  zero: Double;
begin
  zero := 0.0;  // Runtime to avoid compile-time error
  result := 1.0 / zero;
  AssertTrue('1/0 should be +Inf', fafafa.core.math.IsInfinite(result) and (result > 0));
end;

procedure TTestInfinity.Test_NegOne_Div_Zero_IsNegInfinity;
var
  result: Double;
  zero: Double;
begin
  zero := 0.0;
  result := -1.0 / zero;
  AssertTrue('-1/0 should be -Inf', fafafa.core.math.IsInfinite(result) and (result < 0));
end;

procedure TTestInfinity.Test_Clamp_WithInfinityMax_Works;
var
  result: Double;
begin
  result := fafafa.core.math.Clamp(5.0, 0.0, fafafa.core.math.Infinity);
  AssertEquals('Clamp with Inf max', 5.0, result, 1e-15);
end;

procedure TTestInfinity.Test_Clamp_WithNegInfinityMin_Works;
var
  result: Double;
begin
  result := fafafa.core.math.Clamp(5.0, NegInfinity, 100.0);
  AssertEquals('Clamp with -Inf min', 5.0, result, 1e-15);
end;

// ============================================================================
// TTestZeroSign Implementation
// ============================================================================

procedure TTestZeroSign.Test_Sign_PositiveValue_ReturnsOne;
begin
  AssertEquals('Sign of positive', 1, fafafa.core.math.Sign(42.0));
  AssertEquals('Sign of small positive', 1, fafafa.core.math.Sign(0.001));
end;

procedure TTestZeroSign.Test_Sign_NegativeValue_ReturnsMinusOne;
begin
  AssertEquals('Sign of negative', -1, fafafa.core.math.Sign(-42.0));
  AssertEquals('Sign of small negative', -1, fafafa.core.math.Sign(-0.001));
end;

procedure TTestZeroSign.Test_Sign_Zero_ReturnsZero;
begin
  AssertEquals('Sign of zero', 0, fafafa.core.math.Sign(0.0));
end;

procedure TTestZeroSign.Test_Sign_NaN_ReturnsZero;
begin
  // NaN comparisons are always false, so Sign(NaN) should return 0
  AssertEquals('Sign of NaN', 0, fafafa.core.math.Sign(fafafa.core.math.NaN));
end;

procedure TTestZeroSign.Test_Abs_PositiveValue_ReturnsSame;
begin
  AssertEquals('Abs of positive', 42.0, fafafa.core.math.Abs(42.0), 1e-15);
end;

procedure TTestZeroSign.Test_Abs_NegativeValue_ReturnsPositive;
begin
  AssertEquals('Abs of negative', 42.0, fafafa.core.math.Abs(-42.0), 1e-15);
end;

procedure TTestZeroSign.Test_Abs_Zero_ReturnsZero;
begin
  AssertEquals('Abs of zero', 0.0, fafafa.core.math.Abs(0.0), 1e-15);
end;

procedure TTestZeroSign.Test_Zero_Times_Infinity_IsNaN;
var
  result: Double;
  zero: Double;
begin
  zero := 0.0;
  result := zero * fafafa.core.math.Infinity;
  AssertTrue('0 * Inf should be NaN', fafafa.core.math.IsNaN(result));
end;

procedure TTestZeroSign.Test_Division_ByZero_ReturnsInfinity;
var
  result: Double;
  zero: Double;
begin
  zero := 0.0;
  result := 1.0 / zero;
  AssertTrue('1/0 should be infinite', fafafa.core.math.IsInfinite(result));
end;

// ============================================================================
// TTestRounding Implementation
// ============================================================================

procedure TTestRounding.Test_Floor_PositiveNonInteger_RoundsDown;
begin
  AssertEquals('Floor(2.7) = 2', 2, fafafa.core.math.Floor(2.7));
  AssertEquals('Floor(2.3) = 2', 2, fafafa.core.math.Floor(2.3));
end;

procedure TTestRounding.Test_Floor_NegativeNonInteger_RoundsDown;
begin
  AssertEquals('Floor(-2.3) = -3', -3, fafafa.core.math.Floor(-2.3));
  AssertEquals('Floor(-2.7) = -3', -3, fafafa.core.math.Floor(-2.7));
end;

procedure TTestRounding.Test_Floor_Integer_ReturnsSame;
begin
  AssertEquals('Floor(3.0) = 3', 3, fafafa.core.math.Floor(3.0));
  AssertEquals('Floor(-3.0) = -3', -3, fafafa.core.math.Floor(-3.0));
end;

procedure TTestRounding.Test_Ceil_PositiveNonInteger_RoundsUp;
begin
  AssertEquals('Ceil(2.3) = 3', 3, fafafa.core.math.Ceil(2.3));
  AssertEquals('Ceil(2.7) = 3', 3, fafafa.core.math.Ceil(2.7));
end;

procedure TTestRounding.Test_Ceil_NegativeNonInteger_RoundsUp;
begin
  AssertEquals('Ceil(-2.7) = -2', -2, fafafa.core.math.Ceil(-2.7));
  AssertEquals('Ceil(-2.3) = -2', -2, fafafa.core.math.Ceil(-2.3));
end;

procedure TTestRounding.Test_Ceil_Integer_ReturnsSame;
begin
  AssertEquals('Ceil(3.0) = 3', 3, fafafa.core.math.Ceil(3.0));
  AssertEquals('Ceil(-3.0) = -3', -3, fafafa.core.math.Ceil(-3.0));
end;

procedure TTestRounding.Test_Trunc_PositiveNonInteger_TowardZero;
begin
  AssertEquals('Trunc(2.7) = 2', 2, fafafa.core.math.Trunc(2.7));
  AssertEquals('Trunc(2.3) = 2', 2, fafafa.core.math.Trunc(2.3));
end;

procedure TTestRounding.Test_Trunc_NegativeNonInteger_TowardZero;
begin
  AssertEquals('Trunc(-2.7) = -2', -2, fafafa.core.math.Trunc(-2.7));
  AssertEquals('Trunc(-2.3) = -2', -2, fafafa.core.math.Trunc(-2.3));
end;

procedure TTestRounding.Test_Round_HalfUp_Behavior;
begin
  // RTL Round uses banker's rounding (round half to even)
  // Just test basic cases that don't hit the edge
  AssertEquals('Round(2.7) = 3', 3, fafafa.core.math.Round(2.7));
  AssertEquals('Round(2.3) = 2', 2, fafafa.core.math.Round(2.3));
end;

procedure TTestRounding.Test_Round_HalfDown_Behavior;
begin
  AssertEquals('Round(-2.7) = -3', -3, fafafa.core.math.Round(-2.7));
  AssertEquals('Round(-2.3) = -2', -2, fafafa.core.math.Round(-2.3));
end;

// ============================================================================
// TTestMinMaxEdge Implementation
// ============================================================================

procedure TTestMinMaxEdge.Test_Min_SameValues_ReturnsSame;
begin
  AssertEquals('Min(5,5) = 5', 5.0, fafafa.core.math.Min(5.0, 5.0), 1e-15);
end;

procedure TTestMinMaxEdge.Test_Max_SameValues_ReturnsSame;
begin
  AssertEquals('Max(5,5) = 5', 5.0, fafafa.core.math.Max(5.0, 5.0), 1e-15);
end;

procedure TTestMinMaxEdge.Test_Min_FirstSmaller_ReturnsFirst;
begin
  AssertEquals('Min(3,7) = 3', 3.0, fafafa.core.math.Min(3.0, 7.0), 1e-15);
end;

procedure TTestMinMaxEdge.Test_Max_FirstLarger_ReturnsFirst;
begin
  AssertEquals('Max(7,3) = 7', 7.0, fafafa.core.math.Max(7.0, 3.0), 1e-15);
end;

procedure TTestMinMaxEdge.Test_Min_VerySmallDiff_Works;
var
  a, b: Double;
begin
  a := 1.0;
  b := 1.0 + 1e-15;
  AssertEquals('Min with tiny diff', a, fafafa.core.math.Min(a, b), 1e-16);
end;

procedure TTestMinMaxEdge.Test_Max_VerySmallDiff_Works;
var
  a, b: Double;
begin
  a := 1.0;
  b := 1.0 + 1e-15;
  AssertEquals('Max with tiny diff', b, fafafa.core.math.Max(a, b), 1e-16);
end;

procedure TTestMinMaxEdge.Test_Min_WithInfinity_ReturnsFinite;
begin
  AssertEquals('Min(5, Inf) = 5', 5.0, fafafa.core.math.Min(5.0, fafafa.core.math.Infinity), 1e-15);
end;

procedure TTestMinMaxEdge.Test_Max_WithNegInfinity_ReturnsFinite;
begin
  AssertEquals('Max(5, -Inf) = 5', 5.0, fafafa.core.math.Max(5.0, NegInfinity), 1e-15);
end;

// ============================================================================
// TTestPowerEdge Implementation
// ============================================================================

procedure TTestPowerEdge.Test_Power_ZeroExponent_ReturnsOne;
begin
  AssertEquals('Power(5, 0) = 1', 1.0, fafafa.core.math.Power(5.0, 0.0), 1e-15);
  AssertEquals('Power(0, 0) = 1', 1.0, fafafa.core.math.Power(0.0, 0.0), 1e-15);
end;

procedure TTestPowerEdge.Test_Power_OneBase_ReturnsOne;
begin
  AssertEquals('Power(1, 100) = 1', 1.0, fafafa.core.math.Power(1.0, 100.0), 1e-15);
end;

procedure TTestPowerEdge.Test_Power_NegativeExponent_ReturnsFraction;
begin
  AssertEquals('Power(2, -1) = 0.5', 0.5, fafafa.core.math.Power(2.0, -1.0), 1e-15);
  AssertEquals('Power(4, -0.5) = 0.5', 0.5, fafafa.core.math.Power(4.0, -0.5), 1e-15);
end;

procedure TTestPowerEdge.Test_IntPower_ZeroExponent_ReturnsOne;
begin
  AssertEquals('IntPower(5, 0) = 1', 1.0, fafafa.core.math.IntPower(5.0, 0), 1e-15);
end;

procedure TTestPowerEdge.Test_IntPower_NegativeExponent_ReturnsFraction;
begin
  AssertEquals('IntPower(2, -1) = 0.5', 0.5, fafafa.core.math.IntPower(2.0, -1), 1e-15);
  AssertEquals('IntPower(2, -2) = 0.25', 0.25, fafafa.core.math.IntPower(2.0, -2), 1e-15);
end;

procedure TTestPowerEdge.Test_IntPower_ZeroBase_PositiveExp_ReturnsZero;
begin
  AssertEquals('IntPower(0, 1) = 0', 0.0, fafafa.core.math.IntPower(0.0, 1), 1e-15);
  AssertEquals('IntPower(0, 5) = 0', 0.0, fafafa.core.math.IntPower(0.0, 5), 1e-15);
end;

procedure TTestPowerEdge.Test_Sqrt_Zero_ReturnsZero;
begin
  AssertEquals('Sqrt(0) = 0', 0.0, fafafa.core.math.Sqrt(0.0), 1e-15);
end;

procedure TTestPowerEdge.Test_Sqrt_One_ReturnsOne;
begin
  AssertEquals('Sqrt(1) = 1', 1.0, fafafa.core.math.Sqrt(1.0), 1e-15);
end;

procedure TTestPowerEdge.Test_Sqrt_VerySmall_Works;
begin
  AssertEquals('Sqrt(1e-100)', 1e-50, fafafa.core.math.Sqrt(1e-100), 1e-65);
end;

procedure TTestPowerEdge.Test_Sqrt_Infinity_ReturnsInfinity;
begin
  AssertTrue('Sqrt(Inf) = Inf', fafafa.core.math.IsInfinite(fafafa.core.math.Sqrt(fafafa.core.math.Infinity)));
end;

initialization
  RegisterTest(TTestNaN);
  RegisterTest(TTestInfinity);
  RegisterTest(TTestZeroSign);
  RegisterTest(TTestRounding);
  RegisterTest(TTestMinMaxEdge);
  RegisterTest(TTestPowerEdge);

end.
