unit fafafa.core.math.array_.testcase;

{$MODE OBJFPC}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.math.array_;

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

initialization
  RegisterTest(TTestMathArray);

end.
