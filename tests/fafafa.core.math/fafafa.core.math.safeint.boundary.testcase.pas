{

```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.math.safeint.boundary.testcase

## Abstract 摘要

Comprehensive boundary value tests for safe integer arithmetic operations.
Tests all edge cases: 0, 1, MAX-1, MAX, MIN (for signed), and overflow boundaries.
安全整数算术运算的全面边界值测试。
测试所有边界情况：0、1、MAX-1、MAX、MIN（有符号）和溢出边界。

## Declaration 声明

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

unit fafafa.core.math.safeint.boundary.testcase;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

// Disable range/overflow checks - we're testing overflow behavior
{$PUSH}
{$R-}
{$Q-}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.math.base,
  fafafa.core.math.safeint;

type

  // ============================================================================
  // Checked Operations Tests - UInt32
  // ============================================================================

  TTestCheckedU32 = class(TTestCase)
  published
    // === CheckedAddU32 ===
    procedure Test_CheckedAddU32_Zero_Zero_ReturnsSome;
    procedure Test_CheckedAddU32_One_Zero_ReturnsSome;
    procedure Test_CheckedAddU32_Max_Zero_ReturnsSome;
    procedure Test_CheckedAddU32_Max_One_ReturnsNone;
    procedure Test_CheckedAddU32_Max_Max_ReturnsNone;
    procedure Test_CheckedAddU32_HalfMax_HalfMax_ReturnsSome;
    procedure Test_CheckedAddU32_Commutative;

    // === CheckedSubU32 ===
    procedure Test_CheckedSubU32_Zero_Zero_ReturnsSome;
    procedure Test_CheckedSubU32_One_Zero_ReturnsSome;
    procedure Test_CheckedSubU32_Zero_One_ReturnsNone;
    procedure Test_CheckedSubU32_Max_Max_ReturnsSome;
    procedure Test_CheckedSubU32_Max_One_ReturnsSome;

    // === CheckedMulU32 ===
    procedure Test_CheckedMulU32_Zero_Any_ReturnsSome;
    procedure Test_CheckedMulU32_One_Max_ReturnsSome;
    procedure Test_CheckedMulU32_Two_HalfMax_ReturnsSome;
    procedure Test_CheckedMulU32_Two_HalfMaxPlusOne_ReturnsNone;
    procedure Test_CheckedMulU32_Max_Two_ReturnsNone;

    // === CheckedDivU32 ===
    procedure Test_CheckedDivU32_Any_Zero_ReturnsNone;
    procedure Test_CheckedDivU32_Zero_Any_ReturnsSome;
    procedure Test_CheckedDivU32_Max_One_ReturnsSome;
    procedure Test_CheckedDivU32_Max_Max_ReturnsSome;
  end;

  // ============================================================================
  // Checked Operations Tests - Int32
  // ============================================================================

  TTestCheckedI32 = class(TTestCase)
  published
    // === CheckedAddI32 ===
    procedure Test_CheckedAddI32_MaxInt_One_ReturnsNone;
    procedure Test_CheckedAddI32_MinInt_MinusOne_ReturnsNone;
    procedure Test_CheckedAddI32_MaxInt_Zero_ReturnsSome;
    procedure Test_CheckedAddI32_MinInt_Zero_ReturnsSome;
    procedure Test_CheckedAddI32_MaxInt_MinInt_ReturnsSome;

    // === CheckedSubI32 ===
    procedure Test_CheckedSubI32_MinInt_One_ReturnsNone;
    procedure Test_CheckedSubI32_MaxInt_MinusOne_ReturnsNone;
    procedure Test_CheckedSubI32_MinInt_MinInt_ReturnsSome;
    procedure Test_CheckedSubI32_MaxInt_MaxInt_ReturnsSome;

    // === CheckedMulI32 ===
    procedure Test_CheckedMulI32_MaxInt_Two_ReturnsNone;
    procedure Test_CheckedMulI32_MinInt_Two_ReturnsNone;
    procedure Test_CheckedMulI32_MinInt_MinusOne_ReturnsNone;

    // === CheckedNegI32 ===
    procedure Test_CheckedNegI32_MinInt_ReturnsNone;
    procedure Test_CheckedNegI32_MaxInt_ReturnsSome;
    procedure Test_CheckedNegI32_Zero_ReturnsSome;
    procedure Test_CheckedNegI32_One_ReturnsSome;
    procedure Test_CheckedNegI32_MinusOne_ReturnsSome;

    // === CheckedDivI32 ===
    procedure Test_CheckedDivI32_MinInt_MinusOne_ReturnsNone;
    procedure Test_CheckedDivI32_Any_Zero_ReturnsNone;
    procedure Test_CheckedDivI32_Zero_Any_ReturnsSome;
  end;

  // ============================================================================
  // Overflowing Operations Tests - UInt32
  // ============================================================================

  TTestOverflowingU32 = class(TTestCase)
  published
    // === OverflowingAddU32 ===
    procedure Test_OverflowingAddU32_Max_One_Wraps;
    procedure Test_OverflowingAddU32_Max_Max_Wraps;
    procedure Test_OverflowingAddU32_NoOverflow_FlagFalse;

    // === OverflowingSubU32 ===
    procedure Test_OverflowingSubU32_Zero_One_Wraps;
    procedure Test_OverflowingSubU32_Zero_Max_Wraps;
    procedure Test_OverflowingSubU32_NoUnderflow_FlagFalse;

    // === OverflowingMulU32 ===
    procedure Test_OverflowingMulU32_Max_Two_Wraps;
    procedure Test_OverflowingMulU32_NoOverflow_FlagFalse;
  end;

  // ============================================================================
  // Overflowing Operations Tests - Int32
  // ============================================================================

  TTestOverflowingI32 = class(TTestCase)
  published
    // === OverflowingAddI32 ===
    procedure Test_OverflowingAddI32_MaxInt_One_Wraps;
    procedure Test_OverflowingAddI32_MinInt_MinusOne_Wraps;

    // === OverflowingSubI32 ===
    procedure Test_OverflowingSubI32_MinInt_One_Wraps;
    procedure Test_OverflowingSubI32_MaxInt_MinusOne_Wraps;

    // === OverflowingNegI32 ===
    procedure Test_OverflowingNegI32_MinInt_Wraps;
    procedure Test_OverflowingNegI32_Zero_NoOverflow;
  end;

  // ============================================================================
  // Wrapping Operations Tests - UInt32
  // ============================================================================

  TTestWrappingU32 = class(TTestCase)
  published
    procedure Test_WrappingAddU32_Max_One_ReturnsZero;
    procedure Test_WrappingAddU32_Max_Max_ReturnsExpected;
    procedure Test_WrappingSubU32_Zero_One_ReturnsMax;
    procedure Test_WrappingMulU32_Max_Two_ReturnsExpected;
  end;

  // ============================================================================
  // Wrapping Operations Tests - Int32
  // ============================================================================

  TTestWrappingI32 = class(TTestCase)
  published
    procedure Test_WrappingAddI32_MaxInt_One_ReturnsMinInt;
    procedure Test_WrappingSubI32_MinInt_One_ReturnsMaxInt;
    procedure Test_WrappingNegI32_MinInt_ReturnsMinInt;
  end;

  // ============================================================================
  // Saturating Operations Tests
  // ============================================================================

  TTestSaturating = class(TTestCase)
  published
    // === UInt32 ===
    procedure Test_SaturatingAddU32_Max_One_ReturnsMax;
    procedure Test_SaturatingAddU32_Max_Max_ReturnsMax;
    procedure Test_SaturatingSubU32_Zero_One_ReturnsZero;
    procedure Test_SaturatingSubU32_Zero_Max_ReturnsZero;
    procedure Test_SaturatingMulU32_Max_Two_ReturnsMax;

    // === Int32 ===
    procedure Test_SaturatingAddI32_MaxInt_One_ReturnsMaxInt;
    procedure Test_SaturatingAddI32_MinInt_MinusOne_ReturnsMinInt;
    procedure Test_SaturatingSubI32_MinInt_One_ReturnsMinInt;
    procedure Test_SaturatingMulI32_MaxInt_Two_ReturnsMaxInt;
    procedure Test_SaturatingMulI32_MinInt_Two_ReturnsMinInt;
  end;

  // ============================================================================
  // UInt64 / Int64 Tests
  // ============================================================================

  TTestCheckedU64 = class(TTestCase)
  published
    procedure Test_CheckedAddU64_Max_One_ReturnsNone;
    procedure Test_CheckedSubU64_Zero_One_ReturnsNone;
    procedure Test_CheckedMulU64_Max_Two_ReturnsNone;
    procedure Test_CheckedDivU64_Any_Zero_ReturnsNone;
  end;

  TTestCheckedI64 = class(TTestCase)
  published
    procedure Test_CheckedAddI64_MaxInt_One_ReturnsNone;
    procedure Test_CheckedNegI64_MinInt_ReturnsNone;
    procedure Test_CheckedDivI64_MinInt_MinusOne_ReturnsNone;
  end;

implementation

// ============================================================================
// TTestCheckedU32 Implementation
// ============================================================================

procedure TTestCheckedU32.Test_CheckedAddU32_Zero_Zero_ReturnsSome;
var
  result: TOptionalU32;
begin
  result := CheckedAddU32(0, 0);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be 0', 0, result.Value);
end;

procedure TTestCheckedU32.Test_CheckedAddU32_One_Zero_ReturnsSome;
var
  result: TOptionalU32;
begin
  result := CheckedAddU32(1, 0);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be 1', 1, result.Value);
end;

procedure TTestCheckedU32.Test_CheckedAddU32_Max_Zero_ReturnsSome;
var
  result: TOptionalU32;
begin
  result := CheckedAddU32(MAX_UINT32, 0);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be MAX', MAX_UINT32, result.Value);
end;

procedure TTestCheckedU32.Test_CheckedAddU32_Max_One_ReturnsNone;
var
  result: TOptionalU32;
begin
  result := CheckedAddU32(MAX_UINT32, 1);
  AssertFalse('Should overflow (None)', result.Valid);
end;

procedure TTestCheckedU32.Test_CheckedAddU32_Max_Max_ReturnsNone;
var
  result: TOptionalU32;
begin
  result := CheckedAddU32(MAX_UINT32, MAX_UINT32);
  AssertFalse('Should overflow (None)', result.Valid);
end;

procedure TTestCheckedU32.Test_CheckedAddU32_HalfMax_HalfMax_ReturnsSome;
var
  result: TOptionalU32;
  half: UInt32;
begin
  half := MAX_UINT32 div 2;
  result := CheckedAddU32(half, half);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be MAX-1', MAX_UINT32 - 1, result.Value);
end;

procedure TTestCheckedU32.Test_CheckedAddU32_Commutative;
var
  r1, r2: TOptionalU32;
begin
  r1 := CheckedAddU32(100, 200);
  r2 := CheckedAddU32(200, 100);
  AssertEquals('Should be commutative', r1.Value, r2.Value);
end;

procedure TTestCheckedU32.Test_CheckedSubU32_Zero_Zero_ReturnsSome;
var
  result: TOptionalU32;
begin
  result := CheckedSubU32(0, 0);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be 0', 0, result.Value);
end;

procedure TTestCheckedU32.Test_CheckedSubU32_One_Zero_ReturnsSome;
var
  result: TOptionalU32;
begin
  result := CheckedSubU32(1, 0);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be 1', 1, result.Value);
end;

procedure TTestCheckedU32.Test_CheckedSubU32_Zero_One_ReturnsNone;
var
  result: TOptionalU32;
begin
  result := CheckedSubU32(0, 1);
  AssertFalse('Should underflow (None)', result.Valid);
end;

procedure TTestCheckedU32.Test_CheckedSubU32_Max_Max_ReturnsSome;
var
  result: TOptionalU32;
begin
  result := CheckedSubU32(MAX_UINT32, MAX_UINT32);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be 0', 0, result.Value);
end;

procedure TTestCheckedU32.Test_CheckedSubU32_Max_One_ReturnsSome;
var
  result: TOptionalU32;
begin
  result := CheckedSubU32(MAX_UINT32, 1);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be MAX-1', MAX_UINT32 - 1, result.Value);
end;

procedure TTestCheckedU32.Test_CheckedMulU32_Zero_Any_ReturnsSome;
var
  result: TOptionalU32;
begin
  result := CheckedMulU32(0, MAX_UINT32);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be 0', 0, result.Value);
end;

procedure TTestCheckedU32.Test_CheckedMulU32_One_Max_ReturnsSome;
var
  result: TOptionalU32;
begin
  result := CheckedMulU32(1, MAX_UINT32);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be MAX', MAX_UINT32, result.Value);
end;

procedure TTestCheckedU32.Test_CheckedMulU32_Two_HalfMax_ReturnsSome;
var
  result: TOptionalU32;
  half: UInt32;
begin
  half := MAX_UINT32 div 2;
  result := CheckedMulU32(2, half);
  AssertTrue('Should be valid', result.Valid);
  // 2 * (MAX/2) = MAX - 1 (due to integer division truncation)
  AssertEquals('Value should be MAX-1', MAX_UINT32 - 1, result.Value);
end;

procedure TTestCheckedU32.Test_CheckedMulU32_Two_HalfMaxPlusOne_ReturnsNone;
var
  result: TOptionalU32;
  halfPlus: UInt32;
begin
  halfPlus := (MAX_UINT32 div 2) + 1;
  result := CheckedMulU32(2, halfPlus);
  AssertFalse('Should overflow (None)', result.Valid);
end;

procedure TTestCheckedU32.Test_CheckedMulU32_Max_Two_ReturnsNone;
var
  result: TOptionalU32;
begin
  result := CheckedMulU32(MAX_UINT32, 2);
  AssertFalse('Should overflow (None)', result.Valid);
end;

procedure TTestCheckedU32.Test_CheckedDivU32_Any_Zero_ReturnsNone;
var
  result: TOptionalU32;
begin
  result := CheckedDivU32(100, 0);
  AssertFalse('Division by zero should return None', result.Valid);
end;

procedure TTestCheckedU32.Test_CheckedDivU32_Zero_Any_ReturnsSome;
var
  result: TOptionalU32;
begin
  result := CheckedDivU32(0, 100);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be 0', 0, result.Value);
end;

procedure TTestCheckedU32.Test_CheckedDivU32_Max_One_ReturnsSome;
var
  result: TOptionalU32;
begin
  result := CheckedDivU32(MAX_UINT32, 1);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be MAX', MAX_UINT32, result.Value);
end;

procedure TTestCheckedU32.Test_CheckedDivU32_Max_Max_ReturnsSome;
var
  result: TOptionalU32;
begin
  result := CheckedDivU32(MAX_UINT32, MAX_UINT32);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be 1', 1, result.Value);
end;

// ============================================================================
// TTestCheckedI32 Implementation
// ============================================================================

procedure TTestCheckedI32.Test_CheckedAddI32_MaxInt_One_ReturnsNone;
var
  result: TOptionalI32;
begin
  result := CheckedAddI32(MAX_INT32, 1);
  AssertFalse('Should overflow (None)', result.Valid);
end;

procedure TTestCheckedI32.Test_CheckedAddI32_MinInt_MinusOne_ReturnsNone;
var
  result: TOptionalI32;
begin
  result := CheckedAddI32(MIN_INT32, -1);
  AssertFalse('Should underflow (None)', result.Valid);
end;

procedure TTestCheckedI32.Test_CheckedAddI32_MaxInt_Zero_ReturnsSome;
var
  result: TOptionalI32;
begin
  result := CheckedAddI32(MAX_INT32, 0);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be MAX_INT32', MAX_INT32, result.Value);
end;

procedure TTestCheckedI32.Test_CheckedAddI32_MinInt_Zero_ReturnsSome;
var
  result: TOptionalI32;
begin
  result := CheckedAddI32(MIN_INT32, 0);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be MIN_INT32', MIN_INT32, result.Value);
end;

procedure TTestCheckedI32.Test_CheckedAddI32_MaxInt_MinInt_ReturnsSome;
var
  result: TOptionalI32;
begin
  result := CheckedAddI32(MAX_INT32, MIN_INT32);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be -1', -1, result.Value);
end;

procedure TTestCheckedI32.Test_CheckedSubI32_MinInt_One_ReturnsNone;
var
  result: TOptionalI32;
begin
  result := CheckedSubI32(MIN_INT32, 1);
  AssertFalse('Should underflow (None)', result.Valid);
end;

procedure TTestCheckedI32.Test_CheckedSubI32_MaxInt_MinusOne_ReturnsNone;
var
  result: TOptionalI32;
begin
  result := CheckedSubI32(MAX_INT32, -1);
  AssertFalse('Should overflow (None)', result.Valid);
end;

procedure TTestCheckedI32.Test_CheckedSubI32_MinInt_MinInt_ReturnsSome;
var
  result: TOptionalI32;
begin
  result := CheckedSubI32(MIN_INT32, MIN_INT32);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be 0', 0, result.Value);
end;

procedure TTestCheckedI32.Test_CheckedSubI32_MaxInt_MaxInt_ReturnsSome;
var
  result: TOptionalI32;
begin
  result := CheckedSubI32(MAX_INT32, MAX_INT32);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be 0', 0, result.Value);
end;

procedure TTestCheckedI32.Test_CheckedMulI32_MaxInt_Two_ReturnsNone;
var
  result: TOptionalI32;
begin
  result := CheckedMulI32(MAX_INT32, 2);
  AssertFalse('Should overflow (None)', result.Valid);
end;

procedure TTestCheckedI32.Test_CheckedMulI32_MinInt_Two_ReturnsNone;
var
  result: TOptionalI32;
begin
  result := CheckedMulI32(MIN_INT32, 2);
  AssertFalse('Should underflow (None)', result.Valid);
end;

procedure TTestCheckedI32.Test_CheckedMulI32_MinInt_MinusOne_ReturnsNone;
var
  result: TOptionalI32;
begin
  // MIN_INT32 * -1 would give MAX_INT32 + 1, which overflows
  result := CheckedMulI32(MIN_INT32, -1);
  AssertFalse('Should overflow (None)', result.Valid);
end;

procedure TTestCheckedI32.Test_CheckedNegI32_MinInt_ReturnsNone;
var
  result: TOptionalI32;
begin
  // -MIN_INT32 overflows (no positive representation)
  result := CheckedNegI32(MIN_INT32);
  AssertFalse('Negating MIN_INT32 should return None', result.Valid);
end;

procedure TTestCheckedI32.Test_CheckedNegI32_MaxInt_ReturnsSome;
var
  result: TOptionalI32;
begin
  result := CheckedNegI32(MAX_INT32);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be -(MAX_INT32)', -MAX_INT32, result.Value);
end;

procedure TTestCheckedI32.Test_CheckedNegI32_Zero_ReturnsSome;
var
  result: TOptionalI32;
begin
  result := CheckedNegI32(0);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be 0', 0, result.Value);
end;

procedure TTestCheckedI32.Test_CheckedNegI32_One_ReturnsSome;
var
  result: TOptionalI32;
begin
  result := CheckedNegI32(1);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be -1', -1, result.Value);
end;

procedure TTestCheckedI32.Test_CheckedNegI32_MinusOne_ReturnsSome;
var
  result: TOptionalI32;
begin
  result := CheckedNegI32(-1);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be 1', 1, result.Value);
end;

procedure TTestCheckedI32.Test_CheckedDivI32_MinInt_MinusOne_ReturnsNone;
var
  result: TOptionalI32;
begin
  // MIN_INT32 / -1 would give MAX_INT32 + 1, which overflows
  result := CheckedDivI32(MIN_INT32, -1);
  AssertFalse('MIN_INT32 / -1 should return None', result.Valid);
end;

procedure TTestCheckedI32.Test_CheckedDivI32_Any_Zero_ReturnsNone;
var
  result: TOptionalI32;
begin
  result := CheckedDivI32(100, 0);
  AssertFalse('Division by zero should return None', result.Valid);
end;

procedure TTestCheckedI32.Test_CheckedDivI32_Zero_Any_ReturnsSome;
var
  result: TOptionalI32;
begin
  result := CheckedDivI32(0, 100);
  AssertTrue('Should be valid', result.Valid);
  AssertEquals('Value should be 0', 0, result.Value);
end;

// ============================================================================
// TTestOverflowingU32 Implementation
// ============================================================================

procedure TTestOverflowingU32.Test_OverflowingAddU32_Max_One_Wraps;
var
  result: TOverflowU32;
begin
  result := OverflowingAddU32(MAX_UINT32, 1);
  AssertTrue('Should indicate overflow', result.Overflowed);
  AssertEquals('Should wrap to 0', 0, result.Value);
end;

procedure TTestOverflowingU32.Test_OverflowingAddU32_Max_Max_Wraps;
var
  result: TOverflowU32;
begin
  result := OverflowingAddU32(MAX_UINT32, MAX_UINT32);
  AssertTrue('Should indicate overflow', result.Overflowed);
  // MAX + MAX = 2*MAX = 2^32 - 2 wraps to MAX - 1
  AssertEquals('Should wrap to MAX-1', MAX_UINT32 - 1, result.Value);
end;

procedure TTestOverflowingU32.Test_OverflowingAddU32_NoOverflow_FlagFalse;
var
  result: TOverflowU32;
begin
  result := OverflowingAddU32(100, 200);
  AssertFalse('Should not indicate overflow', result.Overflowed);
  AssertEquals('Value should be 300', 300, result.Value);
end;

procedure TTestOverflowingU32.Test_OverflowingSubU32_Zero_One_Wraps;
var
  result: TOverflowU32;
begin
  result := OverflowingSubU32(0, 1);
  AssertTrue('Should indicate underflow', result.Overflowed);
  AssertEquals('Should wrap to MAX', MAX_UINT32, result.Value);
end;

procedure TTestOverflowingU32.Test_OverflowingSubU32_Zero_Max_Wraps;
var
  result: TOverflowU32;
begin
  result := OverflowingSubU32(0, MAX_UINT32);
  AssertTrue('Should indicate underflow', result.Overflowed);
  AssertEquals('Should wrap to 1', 1, result.Value);
end;

procedure TTestOverflowingU32.Test_OverflowingSubU32_NoUnderflow_FlagFalse;
var
  result: TOverflowU32;
begin
  result := OverflowingSubU32(200, 100);
  AssertFalse('Should not indicate underflow', result.Overflowed);
  AssertEquals('Value should be 100', 100, result.Value);
end;

procedure TTestOverflowingU32.Test_OverflowingMulU32_Max_Two_Wraps;
var
  result: TOverflowU32;
begin
  result := OverflowingMulU32(MAX_UINT32, 2);
  AssertTrue('Should indicate overflow', result.Overflowed);
  // MAX * 2 = 2^32 - 2 wraps to MAX - 1
  AssertEquals('Should wrap correctly', MAX_UINT32 - 1, result.Value);
end;

procedure TTestOverflowingU32.Test_OverflowingMulU32_NoOverflow_FlagFalse;
var
  result: TOverflowU32;
begin
  result := OverflowingMulU32(100, 100);
  AssertFalse('Should not indicate overflow', result.Overflowed);
  AssertEquals('Value should be 10000', 10000, result.Value);
end;

// ============================================================================
// TTestOverflowingI32 Implementation
// ============================================================================

procedure TTestOverflowingI32.Test_OverflowingAddI32_MaxInt_One_Wraps;
var
  result: TOverflowI32;
begin
  result := OverflowingAddI32(MAX_INT32, 1);
  AssertTrue('Should indicate overflow', result.Overflowed);
  AssertEquals('Should wrap to MIN_INT32', MIN_INT32, result.Value);
end;

procedure TTestOverflowingI32.Test_OverflowingAddI32_MinInt_MinusOne_Wraps;
var
  result: TOverflowI32;
begin
  result := OverflowingAddI32(MIN_INT32, -1);
  AssertTrue('Should indicate underflow', result.Overflowed);
  AssertEquals('Should wrap to MAX_INT32', MAX_INT32, result.Value);
end;

procedure TTestOverflowingI32.Test_OverflowingSubI32_MinInt_One_Wraps;
var
  result: TOverflowI32;
begin
  result := OverflowingSubI32(MIN_INT32, 1);
  AssertTrue('Should indicate underflow', result.Overflowed);
  AssertEquals('Should wrap to MAX_INT32', MAX_INT32, result.Value);
end;

procedure TTestOverflowingI32.Test_OverflowingSubI32_MaxInt_MinusOne_Wraps;
var
  result: TOverflowI32;
begin
  result := OverflowingSubI32(MAX_INT32, -1);
  AssertTrue('Should indicate overflow', result.Overflowed);
  AssertEquals('Should wrap to MIN_INT32', MIN_INT32, result.Value);
end;

procedure TTestOverflowingI32.Test_OverflowingNegI32_MinInt_Wraps;
var
  result: TOverflowI32;
begin
  result := OverflowingNegI32(MIN_INT32);
  AssertTrue('Should indicate overflow', result.Overflowed);
  // -MIN_INT32 wraps back to MIN_INT32 in 2's complement
  AssertEquals('Should wrap to MIN_INT32', MIN_INT32, result.Value);
end;

procedure TTestOverflowingI32.Test_OverflowingNegI32_Zero_NoOverflow;
var
  result: TOverflowI32;
begin
  result := OverflowingNegI32(0);
  AssertFalse('Should not indicate overflow', result.Overflowed);
  AssertEquals('Value should be 0', 0, result.Value);
end;

// ============================================================================
// TTestWrappingU32 Implementation
// ============================================================================

procedure TTestWrappingU32.Test_WrappingAddU32_Max_One_ReturnsZero;
begin
  AssertEquals('MAX + 1 should wrap to 0', 0, WrappingAddU32(MAX_UINT32, 1));
end;

procedure TTestWrappingU32.Test_WrappingAddU32_Max_Max_ReturnsExpected;
begin
  AssertEquals('MAX + MAX should wrap to MAX-1', MAX_UINT32 - 1, WrappingAddU32(MAX_UINT32, MAX_UINT32));
end;

procedure TTestWrappingU32.Test_WrappingSubU32_Zero_One_ReturnsMax;
begin
  AssertEquals('0 - 1 should wrap to MAX', MAX_UINT32, WrappingSubU32(0, 1));
end;

procedure TTestWrappingU32.Test_WrappingMulU32_Max_Two_ReturnsExpected;
begin
  AssertEquals('MAX * 2 should wrap to MAX-1', MAX_UINT32 - 1, WrappingMulU32(MAX_UINT32, 2));
end;

// ============================================================================
// TTestWrappingI32 Implementation
// ============================================================================

procedure TTestWrappingI32.Test_WrappingAddI32_MaxInt_One_ReturnsMinInt;
begin
  AssertEquals('MAX_INT + 1 should wrap to MIN_INT', MIN_INT32, WrappingAddI32(MAX_INT32, 1));
end;

procedure TTestWrappingI32.Test_WrappingSubI32_MinInt_One_ReturnsMaxInt;
begin
  AssertEquals('MIN_INT - 1 should wrap to MAX_INT', MAX_INT32, WrappingSubI32(MIN_INT32, 1));
end;

procedure TTestWrappingI32.Test_WrappingNegI32_MinInt_ReturnsMinInt;
begin
  // In 2's complement, -MIN_INT wraps back to MIN_INT
  AssertEquals('-MIN_INT should wrap to MIN_INT', MIN_INT32, WrappingNegI32(MIN_INT32));
end;

// ============================================================================
// TTestSaturating Implementation
// ============================================================================

procedure TTestSaturating.Test_SaturatingAddU32_Max_One_ReturnsMax;
begin
  AssertEquals('MAX + 1 should saturate to MAX', MAX_UINT32, SaturatingAdd(UInt32(MAX_UINT32), UInt32(1)));
end;

procedure TTestSaturating.Test_SaturatingAddU32_Max_Max_ReturnsMax;
begin
  AssertEquals('MAX + MAX should saturate to MAX', MAX_UINT32, SaturatingAdd(UInt32(MAX_UINT32), UInt32(MAX_UINT32)));
end;

procedure TTestSaturating.Test_SaturatingSubU32_Zero_One_ReturnsZero;
begin
  AssertEquals('0 - 1 should saturate to 0', UInt32(0), SaturatingAdd(UInt32(0), UInt32(0)));
  AssertEquals('0 - 1 should saturate to 0', UInt32(0), SaturatingSub(UInt32(0), UInt32(1)));
end;

procedure TTestSaturating.Test_SaturatingSubU32_Zero_Max_ReturnsZero;
begin
  AssertEquals('0 - MAX should saturate to 0', UInt32(0), SaturatingSub(UInt32(0), UInt32(MAX_UINT32)));
end;

procedure TTestSaturating.Test_SaturatingMulU32_Max_Two_ReturnsMax;
begin
  AssertEquals('MAX * 2 should saturate to MAX', MAX_UINT32, SaturatingMul(UInt32(MAX_UINT32), UInt32(2)));
end;

procedure TTestSaturating.Test_SaturatingAddI32_MaxInt_One_ReturnsMaxInt;
begin
  AssertEquals('MAX_INT + 1 should saturate to MAX_INT', MAX_INT32, SaturatingAdd(Int32(MAX_INT32), Int32(1)));
end;

procedure TTestSaturating.Test_SaturatingAddI32_MinInt_MinusOne_ReturnsMinInt;
begin
  AssertEquals('MIN_INT + (-1) should saturate to MIN_INT', MIN_INT32, SaturatingAdd(Int32(MIN_INT32), Int32(-1)));
end;

procedure TTestSaturating.Test_SaturatingSubI32_MinInt_One_ReturnsMinInt;
begin
  AssertEquals('MIN_INT - 1 should saturate to MIN_INT', MIN_INT32, SaturatingSub(Int32(MIN_INT32), Int32(1)));
end;

procedure TTestSaturating.Test_SaturatingMulI32_MaxInt_Two_ReturnsMaxInt;
begin
  AssertEquals('MAX_INT * 2 should saturate to MAX_INT', MAX_INT32, SaturatingMul(Int32(MAX_INT32), Int32(2)));
end;

procedure TTestSaturating.Test_SaturatingMulI32_MinInt_Two_ReturnsMinInt;
begin
  AssertEquals('MIN_INT * 2 should saturate to MIN_INT', MIN_INT32, SaturatingMul(Int32(MIN_INT32), Int32(2)));
end;

// ============================================================================
// TTestCheckedU64 Implementation
// ============================================================================

procedure TTestCheckedU64.Test_CheckedAddU64_Max_One_ReturnsNone;
var
  result: TOptionalU64;
  a, b: UInt64;
begin
  a := MAX_UINT64;
  b := 1;
  result := CheckedAddU64(a, b);
  AssertFalse('Should overflow (None)', result.Valid);
end;

procedure TTestCheckedU64.Test_CheckedSubU64_Zero_One_ReturnsNone;
var
  result: TOptionalU64;
  a, b: UInt64;
begin
  a := 0;
  b := 1;
  result := CheckedSubU64(a, b);
  AssertFalse('Should underflow (None)', result.Valid);
end;

procedure TTestCheckedU64.Test_CheckedMulU64_Max_Two_ReturnsNone;
var
  result: TOptionalU64;
  a, b: UInt64;
begin
  a := MAX_UINT64;
  b := 2;
  result := CheckedMulU64(a, b);
  AssertFalse('Should overflow (None)', result.Valid);
end;

procedure TTestCheckedU64.Test_CheckedDivU64_Any_Zero_ReturnsNone;
var
  result: TOptionalU64;
  a, b: UInt64;
begin
  a := 100;
  b := 0;
  result := CheckedDivU64(a, b);
  AssertFalse('Division by zero should return None', result.Valid);
end;

// ============================================================================
// TTestCheckedI64 Implementation
// ============================================================================

procedure TTestCheckedI64.Test_CheckedAddI64_MaxInt_One_ReturnsNone;
var
  result: TOptionalI64;
begin
  result := CheckedAddI64(MAX_INT64, 1);
  AssertFalse('Should overflow (None)', result.Valid);
end;

procedure TTestCheckedI64.Test_CheckedNegI64_MinInt_ReturnsNone;
var
  result: TOptionalI64;
begin
  result := CheckedNegI64(MIN_INT64);
  AssertFalse('Negating MIN_INT64 should return None', result.Valid);
end;

procedure TTestCheckedI64.Test_CheckedDivI64_MinInt_MinusOne_ReturnsNone;
var
  result: TOptionalI64;
begin
  result := CheckedDivI64(MIN_INT64, -1);
  AssertFalse('MIN_INT64 / -1 should return None', result.Valid);
end;

initialization
  RegisterTest(TTestCheckedU32);
  RegisterTest(TTestCheckedI32);
  RegisterTest(TTestOverflowingU32);
  RegisterTest(TTestOverflowingI32);
  RegisterTest(TTestWrappingU32);
  RegisterTest(TTestWrappingI32);
  RegisterTest(TTestSaturating);
  RegisterTest(TTestCheckedU64);
  RegisterTest(TTestCheckedI64);

{$POP}

end.
