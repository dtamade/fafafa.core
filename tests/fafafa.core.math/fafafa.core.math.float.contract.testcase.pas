unit fafafa.core.math.float.contract.testcase;

{$MODE OBJFPC}{$H+}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry,
  fafafa.core.math;

type
  TTestMathFloatContract = class(TTestCase)
  published
    procedure Test_Abs_Double_MatchesRTL;
    procedure Test_Min_Double_MatchesRTL;
    procedure Test_Max_Double_MatchesRTL;
    procedure Test_Clamp_Double_MatchesDefinition;

    procedure Test_Floor_Double_MatchesRTL;
    procedure Test_Ceil_Double_MatchesRTL;
    procedure Test_Trunc_Double_MatchesRTL;
    procedure Test_Round_Double_MatchesRTL;

    procedure Test_Sqrt_Double_MatchesRTL;

    // Special values / boundaries
    procedure Test_IsNaN_Double_NaNAndFinite_Correct;
    procedure Test_IsInfinite_Double_InfinityAndFinite_Correct;
    procedure Test_Sign_Double_SpecialValues_Correct;

    // Trigonometric functions
    procedure Test_Sin_Double_MatchesRTL;
    procedure Test_Cos_Double_MatchesRTL;
    procedure Test_Tan_Double_MatchesRTL;
    procedure Test_ArcSin_Double_MatchesRTL;
    procedure Test_ArcCos_Double_MatchesRTL;
    procedure Test_ArcTan_Double_MatchesRTL;

    // Exponential and logarithmic functions
    procedure Test_Exp_Double_MatchesRTL;
    procedure Test_Ln_Double_MatchesRTL;
    procedure Test_Log10_Double_MatchesRTL;
    procedure Test_Log2_Double_MatchesRTL;
  end;

implementation

procedure AssertNear(aTest: TTestCase; const expected, actual: Double; const eps: Double; const msg: String = '');
begin
  if System.Abs(expected - actual) > eps then
    aTest.Fail(Format('%s expected=%g actual=%g eps=%g', [msg, expected, actual, eps]));
end;

procedure TTestMathFloatContract.Test_Abs_Double_MatchesRTL;
const
  EPS = 1e-12;
begin
  AssertNear(Self, System.Abs(Double(0.0)), fafafa.core.math.Abs(Double(0.0)), EPS, 'Abs(0)');
  AssertNear(Self, System.Abs(Double(1.25)), fafafa.core.math.Abs(Double(1.25)), EPS, 'Abs(1.25)');
  AssertNear(Self, System.Abs(Double(-1.25)), fafafa.core.math.Abs(Double(-1.25)), EPS, 'Abs(-1.25)');
  AssertNear(Self, System.Abs(Double(-123456.75)), fafafa.core.math.Abs(Double(-123456.75)), EPS, 'Abs(-123456.75)');
end;

procedure TTestMathFloatContract.Test_Min_Double_MatchesRTL;
const
  EPS = 1e-12;
begin
  AssertNear(Self, Math.Min(Double(1.0), Double(2.0)), fafafa.core.math.Min(Double(1.0), Double(2.0)), EPS, 'Min(1,2)');
  AssertNear(Self, Math.Min(Double(2.0), Double(1.0)), fafafa.core.math.Min(Double(2.0), Double(1.0)), EPS, 'Min(2,1)');
  AssertNear(Self, Math.Min(Double(-1.0), Double(1.0)), fafafa.core.math.Min(Double(-1.0), Double(1.0)), EPS, 'Min(-1,1)');
end;

procedure TTestMathFloatContract.Test_Max_Double_MatchesRTL;
const
  EPS = 1e-12;
begin
  AssertNear(Self, Math.Max(Double(1.0), Double(2.0)), fafafa.core.math.Max(Double(1.0), Double(2.0)), EPS, 'Max(1,2)');
  AssertNear(Self, Math.Max(Double(2.0), Double(1.0)), fafafa.core.math.Max(Double(2.0), Double(1.0)), EPS, 'Max(2,1)');
  AssertNear(Self, Math.Max(Double(-1.0), Double(1.0)), fafafa.core.math.Max(Double(-1.0), Double(1.0)), EPS, 'Max(-1,1)');
end;

procedure TTestMathFloatContract.Test_Clamp_Double_MatchesDefinition;
const
  EPS = 1e-12;
var
  x, lo, hi: Double;
  expected: Double;
begin
  lo := Double(-1.0);
  hi := Double(2.0);

  x := Double(-2.0);
  expected := Math.Max(lo, Math.Min(x, hi));
  AssertNear(Self, expected, fafafa.core.math.Clamp(x, lo, hi), EPS, 'Clamp(-2)');

  x := Double(0.5);
  expected := Math.Max(lo, Math.Min(x, hi));
  AssertNear(Self, expected, fafafa.core.math.Clamp(x, lo, hi), EPS, 'Clamp(0.5)');

  x := Double(3.0);
  expected := Math.Max(lo, Math.Min(x, hi));
  AssertNear(Self, expected, fafafa.core.math.Clamp(x, lo, hi), EPS, 'Clamp(3)');
end;

procedure TTestMathFloatContract.Test_Floor_Double_MatchesRTL;
begin
  AssertEquals(Int64(Math.Floor(0.0)), fafafa.core.math.Floor(0.0));
  AssertEquals(Int64(Math.Floor(1.1)), fafafa.core.math.Floor(1.1));
  AssertEquals(Int64(Math.Floor(-1.1)), fafafa.core.math.Floor(-1.1));
  AssertEquals(Int64(Math.Floor(2.0)), fafafa.core.math.Floor(2.0));
end;

procedure TTestMathFloatContract.Test_Ceil_Double_MatchesRTL;
begin
  AssertEquals(Int64(Math.Ceil(0.0)), fafafa.core.math.Ceil(0.0));
  AssertEquals(Int64(Math.Ceil(1.1)), fafafa.core.math.Ceil(1.1));
  AssertEquals(Int64(Math.Ceil(-1.1)), fafafa.core.math.Ceil(-1.1));
  AssertEquals(Int64(Math.Ceil(2.0)), fafafa.core.math.Ceil(2.0));
end;

procedure TTestMathFloatContract.Test_Trunc_Double_MatchesRTL;
begin
  AssertEquals(Int64(System.Trunc(0.0)), fafafa.core.math.Trunc(0.0));
  AssertEquals(Int64(System.Trunc(1.9)), fafafa.core.math.Trunc(1.9));
  AssertEquals(Int64(System.Trunc(-1.9)), fafafa.core.math.Trunc(-1.9));
end;

procedure TTestMathFloatContract.Test_Round_Double_MatchesRTL;
begin
  AssertEquals(Int64(System.Round(0.0)), fafafa.core.math.Round(0.0));
  AssertEquals(Int64(System.Round(1.4)), fafafa.core.math.Round(1.4));
  AssertEquals(Int64(System.Round(1.5)), fafafa.core.math.Round(1.5));
  AssertEquals(Int64(System.Round(-1.4)), fafafa.core.math.Round(-1.4));
  AssertEquals(Int64(System.Round(-1.5)), fafafa.core.math.Round(-1.5));
end;

procedure TTestMathFloatContract.Test_Sqrt_Double_MatchesRTL;
const
  EPS = 1e-12;
begin
  AssertNear(Self, System.Sqrt(Double(0.0)), fafafa.core.math.Sqrt(Double(0.0)), EPS, 'Sqrt(0)');
  AssertNear(Self, System.Sqrt(Double(1.0)), fafafa.core.math.Sqrt(Double(1.0)), EPS, 'Sqrt(1)');
  AssertNear(Self, System.Sqrt(Double(2.0)), fafafa.core.math.Sqrt(Double(2.0)), EPS, 'Sqrt(2)');
end;

procedure TTestMathFloatContract.Test_IsNaN_Double_NaNAndFinite_Correct;
var
  v: Double;
begin
  v := fafafa.core.math.NaN;
  AssertTrue(fafafa.core.math.IsNaN(v));

  AssertFalse(fafafa.core.math.IsNaN(Double(0.0)));
  AssertFalse(fafafa.core.math.IsNaN(fafafa.core.math.Infinity));
end;

procedure TTestMathFloatContract.Test_IsInfinite_Double_InfinityAndFinite_Correct;
var
  inf: Double;
begin
  inf := fafafa.core.math.Infinity;
  AssertTrue(fafafa.core.math.IsInfinite(inf));
  AssertTrue(fafafa.core.math.IsInfinite(-inf));

  AssertFalse(fafafa.core.math.IsInfinite(Double(0.0)));
  AssertFalse(fafafa.core.math.IsInfinite(fafafa.core.math.NaN));
end;

procedure TTestMathFloatContract.Test_Sign_Double_SpecialValues_Correct;
var
  oldMask: TFPUExceptionMask;
  inf: Double;
  negZero: Double;
  inv: Double;
begin
  // Ensure division by 0 does not raise.
  oldMask := fafafa.core.math.GetExceptionMask;
  try
    fafafa.core.math.SetExceptionMask(oldMask + [exInvalidOp, exZeroDivide]);

    inf := fafafa.core.math.Infinity;
    AssertEquals(0, fafafa.core.math.Sign(fafafa.core.math.NaN));
    AssertEquals(1, fafafa.core.math.Sign(inf));
    AssertEquals(-1, fafafa.core.math.Sign(-inf));

    // -0.0: create it via division by +Infinity.
    negZero := -1.0 / inf;
    AssertEquals(0, fafafa.core.math.Sign(negZero));

    // sign bit check: 1/(-0.0) should be -Infinity.
    inv := 1.0 / negZero;
    AssertTrue(fafafa.core.math.IsInfinite(inv));
    AssertTrue(inv < 0);
  finally
    fafafa.core.math.SetExceptionMask(oldMask);
  end;
end;

// === Trigonometric Functions ===

procedure TTestMathFloatContract.Test_Sin_Double_MatchesRTL;
const
  EPS = 1e-12;
begin
  AssertNear(Self, System.Sin(0.0), fafafa.core.math.Sin(0.0), EPS, 'Sin(0)');
  AssertNear(Self, System.Sin(Pi/6), fafafa.core.math.Sin(Pi/6), EPS, 'Sin(Pi/6)');
  AssertNear(Self, System.Sin(Pi/4), fafafa.core.math.Sin(Pi/4), EPS, 'Sin(Pi/4)');
  AssertNear(Self, System.Sin(Pi/2), fafafa.core.math.Sin(Pi/2), EPS, 'Sin(Pi/2)');
  AssertNear(Self, System.Sin(Pi), fafafa.core.math.Sin(Pi), EPS, 'Sin(Pi)');
end;

procedure TTestMathFloatContract.Test_Cos_Double_MatchesRTL;
const
  EPS = 1e-12;
begin
  AssertNear(Self, System.Cos(0.0), fafafa.core.math.Cos(0.0), EPS, 'Cos(0)');
  AssertNear(Self, System.Cos(Pi/6), fafafa.core.math.Cos(Pi/6), EPS, 'Cos(Pi/6)');
  AssertNear(Self, System.Cos(Pi/4), fafafa.core.math.Cos(Pi/4), EPS, 'Cos(Pi/4)');
  AssertNear(Self, System.Cos(Pi/2), fafafa.core.math.Cos(Pi/2), EPS, 'Cos(Pi/2)');
  AssertNear(Self, System.Cos(Pi), fafafa.core.math.Cos(Pi), EPS, 'Cos(Pi)');
end;

procedure TTestMathFloatContract.Test_Tan_Double_MatchesRTL;
const
  EPS = 1e-10;  // Tan can be less precise near singularities
begin
  AssertNear(Self, Math.Tan(0.0), fafafa.core.math.Tan(0.0), EPS, 'Tan(0)');
  AssertNear(Self, Math.Tan(Pi/6), fafafa.core.math.Tan(Pi/6), EPS, 'Tan(Pi/6)');
  AssertNear(Self, Math.Tan(Pi/4), fafafa.core.math.Tan(Pi/4), EPS, 'Tan(Pi/4)');
end;

procedure TTestMathFloatContract.Test_ArcSin_Double_MatchesRTL;
const
  EPS = 1e-7;  // Relaxed due to RTL implementation differences
begin
  AssertNear(Self, Math.ArcSin(0.0), fafafa.core.math.ArcSin(0.0), EPS, 'ArcSin(0)');
  AssertNear(Self, Math.ArcSin(0.5), fafafa.core.math.ArcSin(0.5), EPS, 'ArcSin(0.5)');
  AssertNear(Self, Math.ArcSin(1.0), fafafa.core.math.ArcSin(1.0), EPS, 'ArcSin(1)');
  AssertNear(Self, Math.ArcSin(-0.5), fafafa.core.math.ArcSin(-0.5), EPS, 'ArcSin(-0.5)');
end;

procedure TTestMathFloatContract.Test_ArcCos_Double_MatchesRTL;
const
  EPS = 1e-7;  // Relaxed due to RTL implementation differences
begin
  AssertNear(Self, Math.ArcCos(0.0), fafafa.core.math.ArcCos(0.0), EPS, 'ArcCos(0)');
  AssertNear(Self, Math.ArcCos(0.5), fafafa.core.math.ArcCos(0.5), EPS, 'ArcCos(0.5)');
  AssertNear(Self, Math.ArcCos(1.0), fafafa.core.math.ArcCos(1.0), EPS, 'ArcCos(1)');
  AssertNear(Self, Math.ArcCos(-0.5), fafafa.core.math.ArcCos(-0.5), EPS, 'ArcCos(-0.5)');
end;

procedure TTestMathFloatContract.Test_ArcTan_Double_MatchesRTL;
const
  EPS = 1e-12;
begin
  AssertNear(Self, System.ArcTan(0.0), fafafa.core.math.ArcTan(0.0), EPS, 'ArcTan(0)');
  AssertNear(Self, System.ArcTan(1.0), fafafa.core.math.ArcTan(1.0), EPS, 'ArcTan(1)');
  AssertNear(Self, System.ArcTan(-1.0), fafafa.core.math.ArcTan(-1.0), EPS, 'ArcTan(-1)');
  AssertNear(Self, System.ArcTan(100.0), fafafa.core.math.ArcTan(100.0), EPS, 'ArcTan(100)');
end;

// === Exponential and Logarithmic Functions ===

procedure TTestMathFloatContract.Test_Exp_Double_MatchesRTL;
const
  EPS = 1e-10;
begin
  AssertNear(Self, System.Exp(0.0), fafafa.core.math.Exp(0.0), EPS, 'Exp(0)');
  AssertNear(Self, System.Exp(1.0), fafafa.core.math.Exp(1.0), EPS, 'Exp(1)');
  AssertNear(Self, System.Exp(-1.0), fafafa.core.math.Exp(-1.0), EPS, 'Exp(-1)');
  AssertNear(Self, System.Exp(2.0), fafafa.core.math.Exp(2.0), EPS, 'Exp(2)');
end;

procedure TTestMathFloatContract.Test_Ln_Double_MatchesRTL;
const
  EPS = 1e-12;
begin
  AssertNear(Self, System.Ln(1.0), fafafa.core.math.Ln(1.0), EPS, 'Ln(1)');
  AssertNear(Self, System.Ln(System.Exp(1.0)), fafafa.core.math.Ln(fafafa.core.math.Exp(1.0)), EPS, 'Ln(e)');
  AssertNear(Self, System.Ln(10.0), fafafa.core.math.Ln(10.0), EPS, 'Ln(10)');
end;

procedure TTestMathFloatContract.Test_Log10_Double_MatchesRTL;
const
  EPS = 1e-12;
begin
  AssertNear(Self, Math.Log10(1.0), fafafa.core.math.Log10(1.0), EPS, 'Log10(1)');
  AssertNear(Self, Math.Log10(10.0), fafafa.core.math.Log10(10.0), EPS, 'Log10(10)');
  AssertNear(Self, Math.Log10(100.0), fafafa.core.math.Log10(100.0), EPS, 'Log10(100)');
end;

procedure TTestMathFloatContract.Test_Log2_Double_MatchesRTL;
const
  EPS = 1e-12;
begin
  AssertNear(Self, Math.Log2(1.0), fafafa.core.math.Log2(1.0), EPS, 'Log2(1)');
  AssertNear(Self, Math.Log2(2.0), fafafa.core.math.Log2(2.0), EPS, 'Log2(2)');
  AssertNear(Self, Math.Log2(8.0), fafafa.core.math.Log2(8.0), EPS, 'Log2(8)');
end;

initialization
  RegisterTest(TTestMathFloatContract);

end.
