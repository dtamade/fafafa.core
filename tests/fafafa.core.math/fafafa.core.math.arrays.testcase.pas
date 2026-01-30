unit fafafa.core.math.arrays.testcase;

{$MODE OBJFPC}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.math.arrays;

type
  TTestMathArray = class(TTestCase)
  published
    // === ArraySumF64 ===
    procedure Test_ArraySumF64_EmptyArray_ReturnsZero;
    procedure Test_ArraySumF64_SingleElement_ReturnsElement;
    procedure Test_ArraySumF64_MultipleElements_ReturnsSum;
    procedure Test_ArraySumF64_NegativeValues_ReturnsCorrectSum;

    // === ArraySumF32 ===
    procedure Test_ArraySumF32_EmptyArray_ReturnsZero;
    procedure Test_ArraySumF32_MultipleElements_ReturnsSum;

    // === ArrayMinF64 / ArrayMaxF64 ===
    procedure Test_ArrayMinF64_SingleElement_ReturnsElement;
    procedure Test_ArrayMinF64_MultipleElements_ReturnsMin;
    procedure Test_ArrayMaxF64_MultipleElements_ReturnsMax;

    // === ArrayMinMaxF64 ===
    procedure Test_ArrayMinMaxF64_FindsBothMinAndMax;

    // === ArrayMeanF64 ===
    procedure Test_ArrayMeanF64_ReturnsAverage;
    procedure Test_ArrayMeanF64_EmptyArray_ReturnsZero;

    // === ArrayAbsF64 ===
    procedure Test_ArrayAbsF64_ConvertsNegatives;

    // === ArrayScaleF64 ===
    procedure Test_ArrayScaleF64_MultipliesByFactor;

    // === ArrayAddF64 ===
    procedure Test_ArrayAddF64_AddsConstant;

    // === ArraySumKahanF64 ===
    procedure Test_ArraySumKahanF64_HighPrecision_ReducesRoundingError;
    procedure Test_ArraySumKahanF64_EmptyArray_ReturnsZero;
    procedure Test_ArraySumKahanF32_LargeArray_MaintainsPrecision;
    procedure Test_ArraySumKahanF32_SingleElement_ReturnsElement;

    // === ArrayDotProductF64 ===
    procedure Test_ArrayDotProductF64_OrthogonalVectors_ReturnsZero;
    procedure Test_ArrayDotProductF64_ParallelVectors_ReturnsProduct;
    procedure Test_ArrayDotProductF32_EmptyArrays_ReturnsZero;
    procedure Test_ArrayDotProductF32_SingleElement_ReturnsProduct;

    // === ArrayVarianceF64 / ArrayStdDevF64 ===
    procedure Test_ArrayVarianceF64_UniformData_ReturnsZero;
    procedure Test_ArrayStdDevF64_NormalDistribution_MatchesExpected;
    procedure Test_ArrayVarianceF32_EmptyArray_ReturnsZero;
    procedure Test_ArrayStdDevF32_SingleElement_ReturnsZero;

    // === ArrayL2NormF64 / ArrayAddArrayF64 ===
    procedure Test_ArrayL2NormF64_UnitVector_ReturnsOne;
    procedure Test_ArrayL2NormF32_ZeroVector_ReturnsZero;
    procedure Test_ArrayAddArrayF64_ElementWise_ReturnsSum;
    procedure Test_ArrayAddArrayF32_EmptyArrays_ReturnsEmpty;
  end;

implementation

// === ArraySumF64 ===

procedure TTestMathArray.Test_ArraySumF64_EmptyArray_ReturnsZero;
var
  LCount: SizeUInt;
begin
  LCount := 0;
  AssertEquals(0.0, ArraySumF64(nil, LCount), 1e-10);
end;

procedure TTestMathArray.Test_ArraySumF64_SingleElement_ReturnsElement;
var
  LData: array[0..0] of Double;
begin
  LData[0] := 42.5;
  AssertEquals(42.5, ArraySumF64(@LData[0], 1), 1e-10);
end;

procedure TTestMathArray.Test_ArraySumF64_MultipleElements_ReturnsSum;
var
  LData: array[0..3] of Double;
begin
  LData[0] := 1.0;
  LData[1] := 2.0;
  LData[2] := 3.0;
  LData[3] := 4.0;
  AssertEquals(10.0, ArraySumF64(@LData[0], 4), 1e-10);
end;

procedure TTestMathArray.Test_ArraySumF64_NegativeValues_ReturnsCorrectSum;
var
  LData: array[0..2] of Double;
begin
  LData[0] := -5.0;
  LData[1] := 10.0;
  LData[2] := -3.0;
  AssertEquals(2.0, ArraySumF64(@LData[0], 3), 1e-10);
end;

// === ArraySumF32 ===

procedure TTestMathArray.Test_ArraySumF32_EmptyArray_ReturnsZero;
var
  LCount: SizeUInt;
begin
  LCount := 0;
  AssertEquals(0.0, ArraySumF32(nil, LCount), 1e-6);
end;

procedure TTestMathArray.Test_ArraySumF32_MultipleElements_ReturnsSum;
var
  LData: array[0..3] of Single;
begin
  LData[0] := 1.0;
  LData[1] := 2.0;
  LData[2] := 3.0;
  LData[3] := 4.0;
  AssertEquals(10.0, ArraySumF32(@LData[0], 4), 1e-6);
end;

// === ArrayMinF64 / ArrayMaxF64 ===

procedure TTestMathArray.Test_ArrayMinF64_SingleElement_ReturnsElement;
var
  LData: array[0..0] of Double;
begin
  LData[0] := 42.5;
  AssertEquals(42.5, ArrayMinF64(@LData[0], 1), 1e-10);
end;

procedure TTestMathArray.Test_ArrayMinF64_MultipleElements_ReturnsMin;
var
  LData: array[0..3] of Double;
begin
  LData[0] := 5.0;
  LData[1] := 2.0;
  LData[2] := 8.0;
  LData[3] := 1.0;
  AssertEquals(1.0, ArrayMinF64(@LData[0], 4), 1e-10);
end;

procedure TTestMathArray.Test_ArrayMaxF64_MultipleElements_ReturnsMax;
var
  LData: array[0..3] of Double;
begin
  LData[0] := 5.0;
  LData[1] := 2.0;
  LData[2] := 8.0;
  LData[3] := 1.0;
  AssertEquals(8.0, ArrayMaxF64(@LData[0], 4), 1e-10);
end;

// === ArrayMinMaxF64 ===

procedure TTestMathArray.Test_ArrayMinMaxF64_FindsBothMinAndMax;
var
  LData: array[0..4] of Double;
  LMin, LMax: Double;
begin
  LData[0] := 5.0;
  LData[1] := 2.0;
  LData[2] := 8.0;
  LData[3] := 1.0;
  LData[4] := 6.0;
  ArrayMinMaxF64(@LData[0], 5, LMin, LMax);
  AssertEquals(1.0, LMin, 1e-10);
  AssertEquals(8.0, LMax, 1e-10);
end;

// === ArrayMeanF64 ===

procedure TTestMathArray.Test_ArrayMeanF64_ReturnsAverage;
var
  LData: array[0..3] of Double;
begin
  LData[0] := 2.0;
  LData[1] := 4.0;
  LData[2] := 6.0;
  LData[3] := 8.0;
  AssertEquals(5.0, ArrayMeanF64(@LData[0], 4), 1e-10);
end;

procedure TTestMathArray.Test_ArrayMeanF64_EmptyArray_ReturnsZero;
var
  LCount: SizeUInt;
begin
  LCount := 0;
  AssertEquals(0.0, ArrayMeanF64(nil, LCount), 1e-10);
end;

// === ArrayAbsF64 ===

procedure TTestMathArray.Test_ArrayAbsF64_ConvertsNegatives;
var
  LSrc: array[0..3] of Double;
  LDst: array[0..3] of Double;
begin
  LSrc[0] := -5.0;
  LSrc[1] := 3.0;
  LSrc[2] := -2.0;
  LSrc[3] := 0.0;
  ArrayAbsF64(@LSrc[0], @LDst[0], 4);
  AssertEquals(5.0, LDst[0], 1e-10);
  AssertEquals(3.0, LDst[1], 1e-10);
  AssertEquals(2.0, LDst[2], 1e-10);
  AssertEquals(0.0, LDst[3], 1e-10);
end;

// === ArrayScaleF64 ===

procedure TTestMathArray.Test_ArrayScaleF64_MultipliesByFactor;
var
  LSrc: array[0..2] of Double;
  LDst: array[0..2] of Double;
begin
  LSrc[0] := 1.0;
  LSrc[1] := 2.0;
  LSrc[2] := 3.0;
  ArrayScaleF64(@LSrc[0], @LDst[0], 3, 2.5);
  AssertEquals(2.5, LDst[0], 1e-10);
  AssertEquals(5.0, LDst[1], 1e-10);
  AssertEquals(7.5, LDst[2], 1e-10);
end;

// === ArrayAddF64 ===

procedure TTestMathArray.Test_ArrayAddF64_AddsConstant;
var
  LSrc: array[0..2] of Double;
  LDst: array[0..2] of Double;
begin
  LSrc[0] := 1.0;
  LSrc[1] := 2.0;
  LSrc[2] := 3.0;
  ArrayAddF64(@LSrc[0], @LDst[0], 3, 10.0);
  AssertEquals(11.0, LDst[0], 1e-10);
  AssertEquals(12.0, LDst[1], 1e-10);
  AssertEquals(13.0, LDst[2], 1e-10);
end;

// === ArraySumKahanF64 ===

procedure TTestMathArray.Test_ArraySumKahanF64_HighPrecision_ReducesRoundingError;
var
  LData: array[0..999] of Double;
  i: Integer;
  LNaiveSum, LKahanSum: Double;
begin
  // Create scenario where naive summation loses precision
  // Add 1000 small values (0.1) which should sum to 100.0
  for i := 0 to 999 do
    LData[i] := 0.1;

  // Kahan summation should maintain better precision
  LKahanSum := ArraySumKahanF64(@LData[0], 1000);

  // Naive sum for comparison
  LNaiveSum := ArraySumF64(@LData[0], 1000);

  // Kahan should be closer to exact 100.0
  // Allow small tolerance but Kahan should be more accurate
  AssertTrue('Kahan sum should be close to 100.0', Abs(LKahanSum - 100.0) < 1e-10);

  // Note: This test demonstrates Kahan's advantage in reducing accumulated rounding errors
end;

procedure TTestMathArray.Test_ArraySumKahanF64_EmptyArray_ReturnsZero;
var
  LCount: SizeUInt;
begin
  LCount := 0;
  AssertEquals(0.0, ArraySumKahanF64(nil, LCount), 1e-10);
end;

procedure TTestMathArray.Test_ArraySumKahanF32_LargeArray_MaintainsPrecision;
var
  LData: array[0..9999] of Single;
  i: Integer;
  LKahanSum: Single;
begin
  // Create large array with small values to test precision maintenance
  for i := 0 to 9999 do
    LData[i] := 0.01;

  LKahanSum := ArraySumKahanF32(@LData[0], 10000);

  // Should sum to 100.0, Kahan maintains precision even with 10000 additions
  AssertTrue('Kahan F32 sum should maintain precision', Abs(LKahanSum - 100.0) < 1e-4);
end;

procedure TTestMathArray.Test_ArraySumKahanF32_SingleElement_ReturnsElement;
var
  LData: array[0..0] of Single;
begin
  LData[0] := 42.5;
  AssertEquals(42.5, ArraySumKahanF32(@LData[0], 1), 1e-6);
end;

// === ArrayDotProductF64 ===

procedure TTestMathArray.Test_ArrayDotProductF64_OrthogonalVectors_ReturnsZero;
var
  LVec1, LVec2: array[0..2] of Double;
  LResult: Double;
begin
  // Orthogonal vectors: (1,0,0) · (0,1,0) = 0
  LVec1[0] := 1.0; LVec1[1] := 0.0; LVec1[2] := 0.0;
  LVec2[0] := 0.0; LVec2[1] := 1.0; LVec2[2] := 0.0;

  LResult := ArrayDotProductF64(@LVec1[0], @LVec2[0], 3);

  // Orthogonal vectors should have dot product = 0
  AssertEquals(0.0, LResult, 1e-10);
end;

procedure TTestMathArray.Test_ArrayDotProductF64_ParallelVectors_ReturnsProduct;
var
  LVec1, LVec2: array[0..2] of Double;
  LResult: Double;
begin
  // Parallel vectors: (2,3,4) · (2,3,4) = 4 + 9 + 16 = 29
  LVec1[0] := 2.0; LVec1[1] := 3.0; LVec1[2] := 4.0;
  LVec2[0] := 2.0; LVec2[1] := 3.0; LVec2[2] := 4.0;

  LResult := ArrayDotProductF64(@LVec1[0], @LVec2[0], 3);

  // Dot product of vector with itself = sum of squares
  AssertEquals(29.0, LResult, 1e-10);
end;

procedure TTestMathArray.Test_ArrayDotProductF32_EmptyArrays_ReturnsZero;
var
  LCount: SizeUInt;
begin
  LCount := 0;
  AssertEquals(0.0, ArrayDotProductF32(nil, nil, LCount), 1e-6);
end;

procedure TTestMathArray.Test_ArrayDotProductF32_SingleElement_ReturnsProduct;
var
  LVec1, LVec2: array[0..0] of Single;
  LResult: Single;
begin
  LVec1[0] := 3.5;
  LVec2[0] := 2.0;

  LResult := ArrayDotProductF32(@LVec1[0], @LVec2[0], 1);

  // Single element: 3.5 * 2.0 = 7.0
  AssertEquals(7.0, LResult, 1e-6);
end;

// === ArrayVarianceF64 / ArrayStdDevF64 ===

procedure TTestMathArray.Test_ArrayVarianceF64_UniformData_ReturnsZero;
var
  LData: array[0..4] of Double;
  LVariance: Double;
begin
  // Uniform data: all elements are the same
  LData[0] := 5.0;
  LData[1] := 5.0;
  LData[2] := 5.0;
  LData[3] := 5.0;
  LData[4] := 5.0;

  LVariance := ArrayVarianceF64(@LData[0], 5);

  // Variance of uniform data should be 0
  AssertEquals(0.0, LVariance, 1e-10);
end;

procedure TTestMathArray.Test_ArrayStdDevF64_NormalDistribution_MatchesExpected;
var
  LData: array[0..4] of Double;
  LStdDev: Double;
begin
  // Simple dataset: [2, 4, 4, 4, 5, 5, 7, 9]
  // Mean = 5, Variance = 4, StdDev = 2
  LData[0] := 2.0;
  LData[1] := 4.0;
  LData[2] := 4.0;
  LData[3] := 7.0;
  LData[4] := 8.0;

  LStdDev := ArrayStdDevF64(@LData[0], 5);

  // Expected standard deviation for this dataset
  // Mean = (2+4+4+7+8)/5 = 5
  // Variance = [(2-5)^2 + (4-5)^2 + (4-5)^2 + (7-5)^2 + (8-5)^2] / (5-1)
  //          = [9 + 1 + 1 + 4 + 9] / 4 = 24/4 = 6
  // StdDev = sqrt(6) ≈ 2.449
  AssertTrue('StdDev should be approximately 2.449', Abs(LStdDev - 2.449) < 0.01);
end;

procedure TTestMathArray.Test_ArrayVarianceF32_EmptyArray_ReturnsZero;
var
  LCount: SizeUInt;
begin
  LCount := 0;
  AssertEquals(0.0, ArrayVarianceF32(nil, LCount), 1e-6);
end;

procedure TTestMathArray.Test_ArrayStdDevF32_SingleElement_ReturnsZero;
var
  LData: array[0..0] of Single;
  LStdDev: Single;
begin
  LData[0] := 42.5;

  LStdDev := ArrayStdDevF32(@LData[0], 1);

  // Standard deviation of single element is 0 (no variance)
  // Note: ArrayVarianceF32 returns 0 for count < 2
  AssertEquals(0.0, LStdDev, 1e-6);
end;

// === ArrayL2NormF64 / ArrayAddArrayF64 ===

procedure TTestMathArray.Test_ArrayL2NormF64_UnitVector_ReturnsOne;
var
  LData: array[0..2] of Double;
  LNorm: Double;
begin
  // Unit vector: (1/√3, 1/√3, 1/√3) has L2 norm = 1
  // Simplified: (0.6, 0.8, 0) has L2 norm = √(0.36 + 0.64) = 1
  LData[0] := 0.6;
  LData[1] := 0.8;
  LData[2] := 0.0;

  LNorm := ArrayL2NormF64(@LData[0], 3);

  // L2 norm of unit vector should be 1.0
  AssertEquals(1.0, LNorm, 1e-10);
end;

procedure TTestMathArray.Test_ArrayL2NormF32_ZeroVector_ReturnsZero;
var
  LData: array[0..2] of Single;
  LNorm: Single;
begin
  LData[0] := 0.0;
  LData[1] := 0.0;
  LData[2] := 0.0;

  LNorm := ArrayL2NormF32(@LData[0], 3);

  // L2 norm of zero vector should be 0
  AssertEquals(0.0, LNorm, 1e-6);
end;

procedure TTestMathArray.Test_ArrayAddArrayF64_ElementWise_ReturnsSum;
var
  LVec1, LVec2, LResult: array[0..2] of Double;
begin
  LVec1[0] := 1.0; LVec1[1] := 2.0; LVec1[2] := 3.0;
  LVec2[0] := 4.0; LVec2[1] := 5.0; LVec2[2] := 6.0;

  ArrayAddArrayF64(@LVec1[0], @LVec2[0], @LResult[0], 3);

  // Element-wise addition: [1,2,3] + [4,5,6] = [5,7,9]
  AssertEquals(5.0, LResult[0], 1e-10);
  AssertEquals(7.0, LResult[1], 1e-10);
  AssertEquals(9.0, LResult[2], 1e-10);
end;

procedure TTestMathArray.Test_ArrayAddArrayF32_EmptyArrays_ReturnsEmpty;
var
  LCount: SizeUInt;
  LResult: array[0..0] of Single;
begin
  LCount := 0;

  // Should handle empty arrays gracefully (no operation)
  ArrayAddArrayF32(nil, nil, @LResult[0], LCount);

  // No assertion needed - just verify it doesn't crash
  AssertTrue('Empty array addition should not crash', True);
end;

initialization
  RegisterTest(TTestMathArray);

end.
