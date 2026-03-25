unit fafafa.core.bits.testcase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.bits;

type
  TTestCoreBits = class(TTestCase)
  published
    procedure Test_DivRoundUp_KeepsCeilingSemantics;
    procedure Test_IsPowerOfTwo_RejectsZeroAndMixedValues;
    procedure Test_NextPowerOfTwo_CoversZeroPowerAndGap;
    procedure Test_AlignHelpers_RoundAsExpected;
    procedure Test_IsAligned_MatchesAlignmentMask;
  end;

implementation

procedure TTestCoreBits.Test_DivRoundUp_KeepsCeilingSemantics;
begin
  AssertEquals(SizeUInt(0), DivRoundUp(0, 8));
  AssertEquals(SizeUInt(4), DivRoundUp(10, 3));
  AssertEquals(SizeUInt(8), DivRoundUp(57, 8));
end;

procedure TTestCoreBits.Test_IsPowerOfTwo_RejectsZeroAndMixedValues;
begin
  AssertFalse(IsPowerOfTwo(0));
  AssertTrue(IsPowerOfTwo(1));
  AssertTrue(IsPowerOfTwo(1024));
  AssertFalse(IsPowerOfTwo(3));
  AssertFalse(IsPowerOfTwo(1000));
end;

procedure TTestCoreBits.Test_NextPowerOfTwo_CoversZeroPowerAndGap;
begin
  AssertEquals(SizeUInt(1), NextPowerOfTwo(0));
  AssertEquals(SizeUInt(1), NextPowerOfTwo(1));
  AssertEquals(SizeUInt(8), NextPowerOfTwo(5));
  AssertEquals(SizeUInt(128), NextPowerOfTwo(100));
end;

procedure TTestCoreBits.Test_AlignHelpers_RoundAsExpected;
begin
  AssertEquals(SizeUInt(0), AlignUp(0, 8));
  AssertEquals(SizeUInt(16), AlignUp(9, 8));
  AssertEquals(SizeUInt(8), AlignDown(9, 8));
  AssertEquals(SizeUInt(4096), AlignUp(4095, 4096));
end;

procedure TTestCoreBits.Test_IsAligned_MatchesAlignmentMask;
begin
  AssertTrue(IsAligned(0, 8));
  AssertTrue(IsAligned(16, 8));
  AssertFalse(IsAligned(18, 8));
end;

initialization
  RegisterTest(TTestCoreBits);

end.
