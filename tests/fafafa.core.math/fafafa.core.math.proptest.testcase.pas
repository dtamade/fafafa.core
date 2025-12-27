{

```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.math.proptest.testcase

## Abstract 摘要

Property-based tests for mathematical operations.
Tests algebraic properties: commutativity, associativity, identity, round-trip.
数学运算的属性测试。
测试代数属性：交换律、结合律、恒等律、往返测试。

## Declaration 声明

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

unit fafafa.core.math.proptest.testcase;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

// Disable range/overflow checks - we're testing wrapping behavior
{$PUSH}
{$R-}
{$Q-}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, Math,
  fafafa.core.base,
  fafafa.core.math.base,
  fafafa.core.math;

type

  // ============================================================================
  // Base class for property tests with random value generation
  // ============================================================================

  TTestPropertyBase = class(TTestCase)
  private
    FSavedMask: TFPUExceptionMask;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    // Random value generators
    function RandomU32: UInt32;
    function RandomI32: Int32;
    function RandomU64: UInt64;
    function RandomI64: Int64;
    function RandomDouble: Double;
  end;

  // ============================================================================
  // Commutativity Tests - a op b = b op a
  // ============================================================================

  TTestCommutativity = class(TTestPropertyBase)
  published
    // Unsigned addition
    procedure Test_AddU32_Commutative_100Iterations;
    procedure Test_AddU64_Commutative_100Iterations;

    // Signed addition
    procedure Test_AddI32_Commutative_100Iterations;
    procedure Test_AddI64_Commutative_100Iterations;

    // Multiplication
    procedure Test_MulU32_Commutative_100Iterations;
    procedure Test_MulI32_Commutative_100Iterations;

    // Min/Max
    procedure Test_MinDouble_Commutative_100Iterations;
    procedure Test_MaxDouble_Commutative_100Iterations;

    // Saturating operations
    procedure Test_SaturatingAddU32_Commutative_100Iterations;
    procedure Test_SaturatingMulU32_Commutative_100Iterations;
  end;

  // ============================================================================
  // Identity Tests - a op identity = a
  // ============================================================================

  TTestIdentity = class(TTestPropertyBase)
  published
    // Additive identity (0)
    procedure Test_AddU32_ZeroIdentity_100Iterations;
    procedure Test_AddI32_ZeroIdentity_100Iterations;
    procedure Test_SubU32_ZeroIdentity_100Iterations;

    // Multiplicative identity (1)
    procedure Test_MulU32_OneIdentity_100Iterations;
    procedure Test_MulI32_OneIdentity_100Iterations;
    procedure Test_DivU32_OneIdentity_100Iterations;

    // Power identity
    procedure Test_Power_ZeroExponent_ReturnsOne_100Iterations;
    procedure Test_Power_OneExponent_ReturnsSame_100Iterations;

    // Abs identity for positive
    procedure Test_Abs_PositiveValue_ReturnsSame_100Iterations;
  end;

  // ============================================================================
  // Inverse Tests - a op inverse(a) = identity
  // ============================================================================

  TTestInverse = class(TTestPropertyBase)
  published
    // Subtraction as additive inverse
    procedure Test_SubI32_Self_ReturnsZero_100Iterations;
    procedure Test_SubU32_Self_ReturnsZero_100Iterations;

    // Division as multiplicative inverse (for non-zero)
    procedure Test_DivU32_Self_ReturnsOne_100Iterations;
    procedure Test_DivI32_Self_ReturnsOne_100Iterations;

    // Double negation
    procedure Test_NegI32_DoubleNeg_ReturnsSame_100Iterations;
    procedure Test_Abs_DoubleAbs_ReturnsSame_100Iterations;
  end;

  // ============================================================================
  // Round-Trip Tests - f(f^-1(x)) = x
  // ============================================================================

  TTestRoundTrip = class(TTestPropertyBase)
  published
    // Trigonometric round-trips (within domain)
    procedure Test_ArcSin_Sin_RoundTrip_100Iterations;
    procedure Test_ArcCos_Cos_RoundTrip_100Iterations;
    procedure Test_ArcTan_Tan_RoundTrip_100Iterations;

    // Exponential/Log round-trips
    procedure Test_Ln_Exp_RoundTrip_100Iterations;
    procedure Test_Log10_Exp10_RoundTrip_100Iterations;
    procedure Test_Log2_Exp2_RoundTrip_100Iterations;

    // Sqrt/Sqr round-trip (for positive)
    procedure Test_Sqrt_Sqr_RoundTrip_100Iterations;

    // Degree/Radian conversions
    procedure Test_DegToRad_RadToDeg_RoundTrip_100Iterations;
  end;

  // ============================================================================
  // Checked vs Wrapping Consistency Tests
  // ============================================================================

  TTestCheckedWrappingConsistency = class(TTestPropertyBase)
  published
    // When checked succeeds, result equals wrapping result
    procedure Test_AddU32_CheckedEqualsWrapping_WhenNoOverflow;
    procedure Test_SubU32_CheckedEqualsWrapping_WhenNoUnderflow;
    procedure Test_MulU32_CheckedEqualsWrapping_WhenNoOverflow;

    procedure Test_AddI32_CheckedEqualsWrapping_WhenNoOverflow;
    procedure Test_SubI32_CheckedEqualsWrapping_WhenNoUnderflow;
    procedure Test_MulI32_CheckedEqualsWrapping_WhenNoOverflow;
  end;

  // ============================================================================
  // Saturating vs Checked Consistency Tests
  // ============================================================================

  TTestSaturatingConsistency = class(TTestPropertyBase)
  published
    // When checked succeeds, saturating equals checked
    procedure Test_AddU32_SaturatingEqualsChecked_WhenNoOverflow;
    procedure Test_SubU32_SaturatingEqualsChecked_WhenNoUnderflow;
    procedure Test_MulU32_SaturatingEqualsChecked_WhenNoOverflow;

    // When checked fails, saturating returns boundary
    procedure Test_AddU32_SaturatingReturnsMax_OnOverflow;
    procedure Test_SubU32_SaturatingReturnsZero_OnUnderflow;
  end;

implementation

const
  PROPERTY_TEST_ITERATIONS = 100;

// ============================================================================
// TTestPropertyBase Implementation
// ============================================================================

procedure TTestPropertyBase.SetUp;
begin
  inherited SetUp;
  // Mask FPU exceptions for clean testing
  FSavedMask := fafafa.core.math.GetExceptionMask;
  fafafa.core.math.SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide,
                                      exOverflow, exUnderflow, exPrecision]);
  // Initialize random seed for reproducibility in test runs
  RandSeed := 42;
end;

procedure TTestPropertyBase.TearDown;
begin
  fafafa.core.math.SetExceptionMask(FSavedMask);
  inherited TearDown;
end;

function TTestPropertyBase.RandomU32: UInt32;
begin
  // Generate random UInt32 across full range
  Result := UInt32(Random(65536)) shl 16 or UInt32(Random(65536));
end;

function TTestPropertyBase.RandomI32: Int32;
begin
  // Generate random Int32 across full range
  Result := Int32(RandomU32);
end;

function TTestPropertyBase.RandomU64: UInt64;
begin
  // Generate random UInt64 across full range
  Result := UInt64(RandomU32) shl 32 or UInt64(RandomU32);
end;

function TTestPropertyBase.RandomI64: Int64;
begin
  // Generate random Int64 across full range
  Result := Int64(RandomU64);
end;

function TTestPropertyBase.RandomDouble: Double;
begin
  // Generate random double in reasonable range [-1e6, 1e6]
  Result := (Random - 0.5) * 2e6;
end;

// ============================================================================
// TTestCommutativity Implementation
// ============================================================================

procedure TTestCommutativity.Test_AddU32_Commutative_100Iterations;
var
  i: Integer;
  a, b: UInt32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := RandomU32;
    b := RandomU32;
    AssertEquals('WrappingAddU32 should be commutative',
      WrappingAddU32(a, b), WrappingAddU32(b, a));
  end;
end;

procedure TTestCommutativity.Test_AddU64_Commutative_100Iterations;
var
  i: Integer;
  a, b: UInt64;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := RandomU64;
    b := RandomU64;
    AssertEquals('WrappingAddU64 should be commutative',
      WrappingAddU64(a, b), WrappingAddU64(b, a));
  end;
end;

procedure TTestCommutativity.Test_AddI32_Commutative_100Iterations;
var
  i: Integer;
  a, b: Int32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := RandomI32;
    b := RandomI32;
    AssertEquals('WrappingAddI32 should be commutative',
      WrappingAddI32(a, b), WrappingAddI32(b, a));
  end;
end;

procedure TTestCommutativity.Test_AddI64_Commutative_100Iterations;
var
  i: Integer;
  a, b: Int64;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := RandomI64;
    b := RandomI64;
    AssertEquals('WrappingAddI64 should be commutative',
      WrappingAddI64(a, b), WrappingAddI64(b, a));
  end;
end;

procedure TTestCommutativity.Test_MulU32_Commutative_100Iterations;
var
  i: Integer;
  a, b: UInt32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := RandomU32;
    b := RandomU32;
    AssertEquals('WrappingMulU32 should be commutative',
      WrappingMulU32(a, b), WrappingMulU32(b, a));
  end;
end;

procedure TTestCommutativity.Test_MulI32_Commutative_100Iterations;
var
  i: Integer;
  a, b: Int32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := RandomI32;
    b := RandomI32;
    AssertEquals('WrappingMulI32 should be commutative',
      WrappingMulI32(a, b), WrappingMulI32(b, a));
  end;
end;

procedure TTestCommutativity.Test_MinDouble_Commutative_100Iterations;
var
  i: Integer;
  a, b: Double;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := RandomDouble;
    b := RandomDouble;
    AssertEquals('Min should be commutative', fafafa.core.math.Min(a, b), fafafa.core.math.Min(b, a), 1e-15);
  end;
end;

procedure TTestCommutativity.Test_MaxDouble_Commutative_100Iterations;
var
  i: Integer;
  a, b: Double;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := RandomDouble;
    b := RandomDouble;
    AssertEquals('Max should be commutative', fafafa.core.math.Max(a, b), fafafa.core.math.Max(b, a), 1e-15);
  end;
end;

procedure TTestCommutativity.Test_SaturatingAddU32_Commutative_100Iterations;
var
  i: Integer;
  a, b: UInt32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := RandomU32;
    b := RandomU32;
    AssertEquals('SaturatingAdd should be commutative',
      SaturatingAdd(a, b), SaturatingAdd(b, a));
  end;
end;

procedure TTestCommutativity.Test_SaturatingMulU32_Commutative_100Iterations;
var
  i: Integer;
  a, b: UInt32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := RandomU32;
    b := RandomU32;
    AssertEquals('SaturatingMul should be commutative',
      SaturatingMul(a, b), SaturatingMul(b, a));
  end;
end;

// ============================================================================
// TTestIdentity Implementation
// ============================================================================

procedure TTestIdentity.Test_AddU32_ZeroIdentity_100Iterations;
var
  i: Integer;
  a: UInt32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := RandomU32;
    AssertEquals('a + 0 should equal a', a, WrappingAddU32(a, 0));
    AssertEquals('0 + a should equal a', a, WrappingAddU32(0, a));
  end;
end;

procedure TTestIdentity.Test_AddI32_ZeroIdentity_100Iterations;
var
  i: Integer;
  a: Int32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := RandomI32;
    AssertEquals('a + 0 should equal a', a, WrappingAddI32(a, 0));
    AssertEquals('0 + a should equal a', a, WrappingAddI32(0, a));
  end;
end;

procedure TTestIdentity.Test_SubU32_ZeroIdentity_100Iterations;
var
  i: Integer;
  a: UInt32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := RandomU32;
    AssertEquals('a - 0 should equal a', a, WrappingSubU32(a, 0));
  end;
end;

procedure TTestIdentity.Test_MulU32_OneIdentity_100Iterations;
var
  i: Integer;
  a: UInt32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := RandomU32;
    AssertEquals('a * 1 should equal a', a, WrappingMulU32(a, 1));
    AssertEquals('1 * a should equal a', a, WrappingMulU32(1, a));
  end;
end;

procedure TTestIdentity.Test_MulI32_OneIdentity_100Iterations;
var
  i: Integer;
  a: Int32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := RandomI32;
    AssertEquals('a * 1 should equal a', a, WrappingMulI32(a, 1));
    AssertEquals('1 * a should equal a', a, WrappingMulI32(1, a));
  end;
end;

procedure TTestIdentity.Test_DivU32_OneIdentity_100Iterations;
var
  i: Integer;
  a: UInt32;
  result: TOptionalU32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := RandomU32;
    result := CheckedDivU32(a, 1);
    AssertTrue('a / 1 should succeed', result.Valid);
    AssertEquals('a / 1 should equal a', a, result.Value);
  end;
end;

procedure TTestIdentity.Test_Power_ZeroExponent_ReturnsOne_100Iterations;
var
  i: Integer;
  base: Double;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    base := RandomDouble;
    // Avoid 0^0 which is conventionally 1 but mathematically undefined
    if fafafa.core.math.Abs(base) > 1e-10 then
      AssertEquals('x^0 should equal 1', 1.0, fafafa.core.math.Power(base, 0.0), 1e-15);
  end;
end;

procedure TTestIdentity.Test_Power_OneExponent_ReturnsSame_100Iterations;
var
  i: Integer;
  base: Double;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    base := fafafa.core.math.Abs(RandomDouble) + 0.001; // Positive to avoid complex numbers
    AssertEquals('x^1 should equal x', base, fafafa.core.math.Power(base, 1.0), base * 1e-10);
  end;
end;

procedure TTestIdentity.Test_Abs_PositiveValue_ReturnsSame_100Iterations;
var
  i: Integer;
  a: Double;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := fafafa.core.math.Abs(RandomDouble);
    AssertEquals('Abs of positive should be same', a, fafafa.core.math.Abs(a), 1e-15);
  end;
end;

// ============================================================================
// TTestInverse Implementation
// ============================================================================

procedure TTestInverse.Test_SubI32_Self_ReturnsZero_100Iterations;
var
  i: Integer;
  a: Int32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := RandomI32;
    AssertEquals('a - a should equal 0', 0, WrappingSubI32(a, a));
  end;
end;

procedure TTestInverse.Test_SubU32_Self_ReturnsZero_100Iterations;
var
  i: Integer;
  a: UInt32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := RandomU32;
    AssertEquals('a - a should equal 0', UInt32(0), WrappingSubU32(a, a));
  end;
end;

procedure TTestInverse.Test_DivU32_Self_ReturnsOne_100Iterations;
var
  i: Integer;
  a: UInt32;
  result: TOptionalU32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := RandomU32;
    if a <> 0 then
    begin
      result := CheckedDivU32(a, a);
      AssertTrue('a / a should succeed', result.Valid);
      AssertEquals('a / a should equal 1', UInt32(1), result.Value);
    end;
  end;
end;

procedure TTestInverse.Test_DivI32_Self_ReturnsOne_100Iterations;
var
  i: Integer;
  a: Int32;
  result: TOptionalI32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := RandomI32;
    if a <> 0 then
    begin
      result := CheckedDivI32(a, a);
      AssertTrue('a / a should succeed', result.Valid);
      AssertEquals('a / a should equal 1', 1, result.Value);
    end;
  end;
end;

procedure TTestInverse.Test_NegI32_DoubleNeg_ReturnsSame_100Iterations;
var
  i: Integer;
  a: Int32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := RandomI32;
    // Skip MIN_INT32 which overflows on negation
    if a <> MIN_INT32 then
      AssertEquals('-(-a) should equal a', a, WrappingNegI32(WrappingNegI32(a)));
  end;
end;

procedure TTestInverse.Test_Abs_DoubleAbs_ReturnsSame_100Iterations;
var
  i: Integer;
  a: Double;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    a := RandomDouble;
    AssertEquals('Abs(Abs(a)) should equal Abs(a)',
      fafafa.core.math.Abs(a), fafafa.core.math.Abs(fafafa.core.math.Abs(a)), 1e-15);
  end;
end;

// ============================================================================
// TTestRoundTrip Implementation
// ============================================================================

procedure TTestRoundTrip.Test_ArcSin_Sin_RoundTrip_100Iterations;
var
  i: Integer;
  x, y: Double;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    // ArcSin domain: [-1, 1], range: [-PI/2, PI/2]
    x := (Random * 2 - 1) * 0.99; // Avoid exact -1/1 for numerical stability
    y := fafafa.core.math.ArcSin(x);
    AssertEquals('Sin(ArcSin(x)) should equal x', x, fafafa.core.math.Sin(y), 1e-10);
  end;
end;

procedure TTestRoundTrip.Test_ArcCos_Cos_RoundTrip_100Iterations;
var
  i: Integer;
  x, y: Double;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    // ArcCos domain: [-1, 1], range: [0, PI]
    x := (Random * 2 - 1) * 0.99;
    y := fafafa.core.math.ArcCos(x);
    AssertEquals('Cos(ArcCos(x)) should equal x', x, fafafa.core.math.Cos(y), 1e-10);
  end;
end;

procedure TTestRoundTrip.Test_ArcTan_Tan_RoundTrip_100Iterations;
var
  i: Integer;
  x, y: Double;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    // Use reasonable range to avoid tan instability near PI/2
    x := (Random * 2 - 1) * 10;
    y := fafafa.core.math.ArcTan(x);
    AssertEquals('Tan(ArcTan(x)) should equal x', x, fafafa.core.math.Tan(y), fafafa.core.math.Abs(x) * 1e-10 + 1e-10);
  end;
end;

procedure TTestRoundTrip.Test_Ln_Exp_RoundTrip_100Iterations;
var
  i: Integer;
  x, y: Double;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    // Ln domain: (0, +inf)
    x := Random * 100 + 0.01;
    y := fafafa.core.math.Ln(x);
    AssertEquals('Exp(Ln(x)) should equal x', x, fafafa.core.math.Exp(y), x * 1e-10);
  end;
end;

procedure TTestRoundTrip.Test_Log10_Exp10_RoundTrip_100Iterations;
var
  i: Integer;
  x, y: Double;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    x := Random * 100 + 0.01;
    y := fafafa.core.math.Log10(x);
    // Exp10 = Power(10, y)
    AssertEquals('10^Log10(x) should equal x', x, fafafa.core.math.Power(10.0, y), x * 1e-10);
  end;
end;

procedure TTestRoundTrip.Test_Log2_Exp2_RoundTrip_100Iterations;
var
  i: Integer;
  x, y: Double;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    x := Random * 100 + 0.01;
    y := fafafa.core.math.Log2(x);
    // Exp2 = Power(2, y)
    AssertEquals('2^Log2(x) should equal x', x, fafafa.core.math.Power(2.0, y), x * 1e-10);
  end;
end;

procedure TTestRoundTrip.Test_Sqrt_Sqr_RoundTrip_100Iterations;
var
  i: Integer;
  x, y: Double;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    // Sqrt domain: [0, +inf)
    x := Random * 1000;
    y := fafafa.core.math.Sqrt(x);
    AssertEquals('Sqr(Sqrt(x)) should equal x', x, fafafa.core.math.Sqr(y), x * 1e-10 + 1e-10);
  end;
end;

procedure TTestRoundTrip.Test_DegToRad_RadToDeg_RoundTrip_100Iterations;
var
  i: Integer;
  deg, rad: Double;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    deg := (Random - 0.5) * 720; // -360 to 360 degrees
    rad := fafafa.core.math.DegToRad(deg);
    AssertEquals('RadToDeg(DegToRad(x)) should equal x', deg, fafafa.core.math.RadToDeg(rad), fafafa.core.math.Abs(deg) * 1e-10 + 1e-10);
  end;
end;

// ============================================================================
// TTestCheckedWrappingConsistency Implementation
// ============================================================================

procedure TTestCheckedWrappingConsistency.Test_AddU32_CheckedEqualsWrapping_WhenNoOverflow;
var
  i: Integer;
  a, b: UInt32;
  checked: TOptionalU32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    // Generate values that won't overflow
    a := UInt32(Random(1000000));
    b := UInt32(Random(1000000));
    checked := CheckedAddU32(a, b);
    AssertTrue('Should not overflow', checked.Valid);
    AssertEquals('Checked should equal wrapping', checked.Value, WrappingAddU32(a, b));
  end;
end;

procedure TTestCheckedWrappingConsistency.Test_SubU32_CheckedEqualsWrapping_WhenNoUnderflow;
var
  i: Integer;
  a, b: UInt32;
  checked: TOptionalU32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    // Generate values where a >= b
    a := RandomU32;
    b := UInt32(Random(Integer(a mod 1000000) + 1));
    if b > a then b := a;
    checked := CheckedSubU32(a, b);
    AssertTrue('Should not underflow', checked.Valid);
    AssertEquals('Checked should equal wrapping', checked.Value, WrappingSubU32(a, b));
  end;
end;

procedure TTestCheckedWrappingConsistency.Test_MulU32_CheckedEqualsWrapping_WhenNoOverflow;
var
  i: Integer;
  a, b: UInt32;
  checked: TOptionalU32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    // Generate small values that won't overflow
    a := UInt32(Random(10000));
    b := UInt32(Random(10000));
    checked := CheckedMulU32(a, b);
    AssertTrue('Should not overflow', checked.Valid);
    AssertEquals('Checked should equal wrapping', checked.Value, WrappingMulU32(a, b));
  end;
end;

procedure TTestCheckedWrappingConsistency.Test_AddI32_CheckedEqualsWrapping_WhenNoOverflow;
var
  i: Integer;
  a, b: Int32;
  checked: TOptionalI32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    // Generate small values that won't overflow
    a := Random(1000000) - 500000;
    b := Random(1000000) - 500000;
    checked := CheckedAddI32(a, b);
    AssertTrue('Should not overflow', checked.Valid);
    AssertEquals('Checked should equal wrapping', checked.Value, WrappingAddI32(a, b));
  end;
end;

procedure TTestCheckedWrappingConsistency.Test_SubI32_CheckedEqualsWrapping_WhenNoUnderflow;
var
  i: Integer;
  a, b: Int32;
  checked: TOptionalI32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    // Generate small values that won't underflow
    a := Random(1000000) - 500000;
    b := Random(1000000) - 500000;
    checked := CheckedSubI32(a, b);
    AssertTrue('Should not underflow', checked.Valid);
    AssertEquals('Checked should equal wrapping', checked.Value, WrappingSubI32(a, b));
  end;
end;

procedure TTestCheckedWrappingConsistency.Test_MulI32_CheckedEqualsWrapping_WhenNoOverflow;
var
  i: Integer;
  a, b: Int32;
  checked: TOptionalI32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    // Generate small values that won't overflow
    a := Random(10000) - 5000;
    b := Random(10000) - 5000;
    checked := CheckedMulI32(a, b);
    AssertTrue('Should not overflow', checked.Valid);
    AssertEquals('Checked should equal wrapping', checked.Value, WrappingMulI32(a, b));
  end;
end;

// ============================================================================
// TTestSaturatingConsistency Implementation
// ============================================================================

procedure TTestSaturatingConsistency.Test_AddU32_SaturatingEqualsChecked_WhenNoOverflow;
var
  i: Integer;
  a, b: UInt32;
  checked: TOptionalU32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    // Generate values that won't overflow
    a := UInt32(Random(1000000));
    b := UInt32(Random(1000000));
    checked := CheckedAddU32(a, b);
    AssertTrue('Should not overflow', checked.Valid);
    AssertEquals('Saturating should equal checked', checked.Value, SaturatingAdd(a, b));
  end;
end;

procedure TTestSaturatingConsistency.Test_SubU32_SaturatingEqualsChecked_WhenNoUnderflow;
var
  i: Integer;
  a, b: UInt32;
  checked: TOptionalU32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    // Generate values where a >= b
    a := RandomU32;
    b := UInt32(Random(Integer(a mod 1000000) + 1));
    if b > a then b := a;
    checked := CheckedSubU32(a, b);
    AssertTrue('Should not underflow', checked.Valid);
    AssertEquals('Saturating should equal checked', checked.Value, SaturatingSub(a, b));
  end;
end;

procedure TTestSaturatingConsistency.Test_MulU32_SaturatingEqualsChecked_WhenNoOverflow;
var
  i: Integer;
  a, b: UInt32;
  checked: TOptionalU32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    // Generate small values that won't overflow
    a := UInt32(Random(10000));
    b := UInt32(Random(10000));
    checked := CheckedMulU32(a, b);
    AssertTrue('Should not overflow', checked.Valid);
    AssertEquals('Saturating should equal checked', checked.Value, SaturatingMul(a, b));
  end;
end;

procedure TTestSaturatingConsistency.Test_AddU32_SaturatingReturnsMax_OnOverflow;
var
  i: Integer;
  a, b: UInt32;
  checked: TOptionalU32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    // Generate values that will overflow
    a := MAX_UINT32 - UInt32(Random(1000));
    b := UInt32(Random(1000000)) + 2000;
    checked := CheckedAddU32(a, b);
    if not checked.Valid then
      AssertEquals('Saturating should return MAX on overflow', MAX_UINT32, SaturatingAdd(a, b));
  end;
end;

procedure TTestSaturatingConsistency.Test_SubU32_SaturatingReturnsZero_OnUnderflow;
var
  i: Integer;
  a, b: UInt32;
  checked: TOptionalU32;
begin
  for i := 1 to PROPERTY_TEST_ITERATIONS do
  begin
    // Generate values where b > a
    a := UInt32(Random(1000));
    b := UInt32(Random(1000000)) + 2000;
    checked := CheckedSubU32(a, b);
    if not checked.Valid then
      AssertEquals('Saturating should return 0 on underflow', UInt32(0), SaturatingSub(a, b));
  end;
end;

initialization
  RegisterTest(TTestCommutativity);
  RegisterTest(TTestIdentity);
  RegisterTest(TTestInverse);
  RegisterTest(TTestRoundTrip);
  RegisterTest(TTestCheckedWrappingConsistency);
  RegisterTest(TTestSaturatingConsistency);

{$POP}

end.
