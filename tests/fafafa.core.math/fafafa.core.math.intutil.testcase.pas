unit fafafa.core.math.intutil.testcase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.math;

type
  TTestMathIntUtil = class(TTestCase)
  published
    // DivRoundUp 测试
    procedure Test_DivRoundUp_ExactDivision_ReturnsQuotient;
    procedure Test_DivRoundUp_WithRemainder_RoundsUp;
    procedure Test_DivRoundUp_ZeroDividend_ReturnsZero;
    procedure Test_DivRoundUp_OneDivisor_ReturnsDividend;
    procedure Test_DivRoundUp_LargeValues_NoOverflow;

    // IsPowerOfTwo 测试
    procedure Test_IsPowerOfTwo_PowersOfTwo_ReturnsTrue;
    procedure Test_IsPowerOfTwo_NonPowersOfTwo_ReturnsFalse;
    procedure Test_IsPowerOfTwo_Zero_ReturnsFalse;
    procedure Test_IsPowerOfTwo_One_ReturnsTrue;

    // NextPowerOfTwo 测试
    procedure Test_NextPowerOfTwo_PowerOfTwo_ReturnsSame;
    procedure Test_NextPowerOfTwo_BetweenPowers_ReturnsNext;
    procedure Test_NextPowerOfTwo_Zero_ReturnsOne;
    procedure Test_NextPowerOfTwo_One_ReturnsOne;

    // AlignUp 测试
    procedure Test_AlignUp_AlreadyAligned_ReturnsSame;
    procedure Test_AlignUp_NotAligned_RoundsUp;
    procedure Test_AlignUp_Zero_ReturnsZero;
    procedure Test_AlignUp_CommonAlignments_Correct;

    // AlignDown 测试
    procedure Test_AlignDown_AlreadyAligned_ReturnsSame;
    procedure Test_AlignDown_NotAligned_RoundsDown;
    procedure Test_AlignDown_Zero_ReturnsZero;
    procedure Test_AlignDown_CommonAlignments_Correct;

    // IsAligned 测试
    procedure Test_IsAligned_Aligned_ReturnsTrue;
    procedure Test_IsAligned_NotAligned_ReturnsFalse;
    procedure Test_IsAligned_Zero_ReturnsTrue;
  end;

implementation

{ TTestMathIntUtil }

// === DivRoundUp ===

procedure TTestMathIntUtil.Test_DivRoundUp_ExactDivision_ReturnsQuotient;
begin
  AssertEquals(5, DivRoundUp(10, 2));
  AssertEquals(4, DivRoundUp(12, 3));
  AssertEquals(1, DivRoundUp(8, 8));
end;

procedure TTestMathIntUtil.Test_DivRoundUp_WithRemainder_RoundsUp;
begin
  AssertEquals(4, DivRoundUp(10, 3));  // 10/3 = 3.33... -> 4
  AssertEquals(3, DivRoundUp(7, 3));   // 7/3 = 2.33... -> 3
  AssertEquals(2, DivRoundUp(9, 8));   // 9/8 = 1.125 -> 2
end;

procedure TTestMathIntUtil.Test_DivRoundUp_ZeroDividend_ReturnsZero;
begin
  AssertEquals(0, DivRoundUp(0, 5));
  AssertEquals(0, DivRoundUp(0, 1));
end;

procedure TTestMathIntUtil.Test_DivRoundUp_OneDivisor_ReturnsDividend;
begin
  AssertEquals(10, DivRoundUp(10, 1));
  AssertEquals(1, DivRoundUp(1, 1));
  AssertEquals(0, DivRoundUp(0, 1));
end;

procedure TTestMathIntUtil.Test_DivRoundUp_LargeValues_NoOverflow;
var
  LargeVal: SizeUInt;
begin
  LargeVal := High(SizeUInt) - 100;
  // 应该不溢出
  AssertTrue(DivRoundUp(LargeVal, 2) >= LargeVal div 2);
end;

// === IsPowerOfTwo ===

procedure TTestMathIntUtil.Test_IsPowerOfTwo_PowersOfTwo_ReturnsTrue;
begin
  AssertTrue(IsPowerOfTwo(1));
  AssertTrue(IsPowerOfTwo(2));
  AssertTrue(IsPowerOfTwo(4));
  AssertTrue(IsPowerOfTwo(8));
  AssertTrue(IsPowerOfTwo(16));
  AssertTrue(IsPowerOfTwo(32));
  AssertTrue(IsPowerOfTwo(64));
  AssertTrue(IsPowerOfTwo(128));
  AssertTrue(IsPowerOfTwo(256));
  AssertTrue(IsPowerOfTwo(1024));
  AssertTrue(IsPowerOfTwo(4096));
end;

procedure TTestMathIntUtil.Test_IsPowerOfTwo_NonPowersOfTwo_ReturnsFalse;
begin
  AssertFalse(IsPowerOfTwo(3));
  AssertFalse(IsPowerOfTwo(5));
  AssertFalse(IsPowerOfTwo(6));
  AssertFalse(IsPowerOfTwo(7));
  AssertFalse(IsPowerOfTwo(9));
  AssertFalse(IsPowerOfTwo(10));
  AssertFalse(IsPowerOfTwo(15));
  AssertFalse(IsPowerOfTwo(100));
  AssertFalse(IsPowerOfTwo(1000));
end;

procedure TTestMathIntUtil.Test_IsPowerOfTwo_Zero_ReturnsFalse;
begin
  AssertFalse(IsPowerOfTwo(0));
end;

procedure TTestMathIntUtil.Test_IsPowerOfTwo_One_ReturnsTrue;
begin
  AssertTrue(IsPowerOfTwo(1));  // 2^0 = 1
end;

// === NextPowerOfTwo ===

procedure TTestMathIntUtil.Test_NextPowerOfTwo_PowerOfTwo_ReturnsSame;
begin
  AssertEquals(SizeUInt(1), NextPowerOfTwo(1));
  AssertEquals(SizeUInt(2), NextPowerOfTwo(2));
  AssertEquals(SizeUInt(4), NextPowerOfTwo(4));
  AssertEquals(SizeUInt(8), NextPowerOfTwo(8));
  AssertEquals(SizeUInt(1024), NextPowerOfTwo(1024));
end;

procedure TTestMathIntUtil.Test_NextPowerOfTwo_BetweenPowers_ReturnsNext;
begin
  AssertEquals(SizeUInt(4), NextPowerOfTwo(3));
  AssertEquals(SizeUInt(8), NextPowerOfTwo(5));
  AssertEquals(SizeUInt(8), NextPowerOfTwo(6));
  AssertEquals(SizeUInt(8), NextPowerOfTwo(7));
  AssertEquals(SizeUInt(16), NextPowerOfTwo(9));
  AssertEquals(SizeUInt(16), NextPowerOfTwo(15));
  AssertEquals(SizeUInt(128), NextPowerOfTwo(100));
end;

procedure TTestMathIntUtil.Test_NextPowerOfTwo_Zero_ReturnsOne;
begin
  AssertEquals(SizeUInt(1), NextPowerOfTwo(0));
end;

procedure TTestMathIntUtil.Test_NextPowerOfTwo_One_ReturnsOne;
begin
  AssertEquals(SizeUInt(1), NextPowerOfTwo(1));
end;

// === AlignUp ===

procedure TTestMathIntUtil.Test_AlignUp_AlreadyAligned_ReturnsSame;
begin
  AssertEquals(SizeUInt(16), AlignUp(16, 8));
  AssertEquals(SizeUInt(32), AlignUp(32, 16));
  AssertEquals(SizeUInt(64), AlignUp(64, 64));
end;

procedure TTestMathIntUtil.Test_AlignUp_NotAligned_RoundsUp;
begin
  AssertEquals(SizeUInt(16), AlignUp(10, 8));
  AssertEquals(SizeUInt(16), AlignUp(15, 8));
  AssertEquals(SizeUInt(8), AlignUp(1, 8));
  AssertEquals(SizeUInt(32), AlignUp(17, 16));
end;

procedure TTestMathIntUtil.Test_AlignUp_Zero_ReturnsZero;
begin
  AssertEquals(SizeUInt(0), AlignUp(0, 8));
  AssertEquals(SizeUInt(0), AlignUp(0, 16));
end;

procedure TTestMathIntUtil.Test_AlignUp_CommonAlignments_Correct;
begin
  // 4字节对齐
  AssertEquals(SizeUInt(4), AlignUp(1, 4));
  AssertEquals(SizeUInt(4), AlignUp(3, 4));
  AssertEquals(SizeUInt(4), AlignUp(4, 4));
  AssertEquals(SizeUInt(8), AlignUp(5, 4));

  // 8字节对齐
  AssertEquals(SizeUInt(8), AlignUp(1, 8));
  AssertEquals(SizeUInt(8), AlignUp(7, 8));
  AssertEquals(SizeUInt(8), AlignUp(8, 8));
  AssertEquals(SizeUInt(16), AlignUp(9, 8));

  // 页对齐 (4096)
  AssertEquals(SizeUInt(4096), AlignUp(1, 4096));
  AssertEquals(SizeUInt(4096), AlignUp(4095, 4096));
  AssertEquals(SizeUInt(4096), AlignUp(4096, 4096));
  AssertEquals(SizeUInt(8192), AlignUp(4097, 4096));
end;

// === AlignDown ===

procedure TTestMathIntUtil.Test_AlignDown_AlreadyAligned_ReturnsSame;
begin
  AssertEquals(SizeUInt(16), AlignDown(16, 8));
  AssertEquals(SizeUInt(32), AlignDown(32, 16));
  AssertEquals(SizeUInt(64), AlignDown(64, 64));
end;

procedure TTestMathIntUtil.Test_AlignDown_NotAligned_RoundsDown;
begin
  AssertEquals(SizeUInt(8), AlignDown(10, 8));
  AssertEquals(SizeUInt(8), AlignDown(15, 8));
  AssertEquals(SizeUInt(0), AlignDown(7, 8));
  AssertEquals(SizeUInt(16), AlignDown(31, 16));
end;

procedure TTestMathIntUtil.Test_AlignDown_Zero_ReturnsZero;
begin
  AssertEquals(SizeUInt(0), AlignDown(0, 8));
  AssertEquals(SizeUInt(0), AlignDown(0, 16));
end;

procedure TTestMathIntUtil.Test_AlignDown_CommonAlignments_Correct;
begin
  // 4字节对齐
  AssertEquals(SizeUInt(0), AlignDown(3, 4));
  AssertEquals(SizeUInt(4), AlignDown(4, 4));
  AssertEquals(SizeUInt(4), AlignDown(7, 4));

  // 8字节对齐
  AssertEquals(SizeUInt(0), AlignDown(7, 8));
  AssertEquals(SizeUInt(8), AlignDown(8, 8));
  AssertEquals(SizeUInt(8), AlignDown(15, 8));

  // 页对齐 (4096)
  AssertEquals(SizeUInt(0), AlignDown(4095, 4096));
  AssertEquals(SizeUInt(4096), AlignDown(4096, 4096));
  AssertEquals(SizeUInt(4096), AlignDown(8191, 4096));
end;

// === IsAligned ===

procedure TTestMathIntUtil.Test_IsAligned_Aligned_ReturnsTrue;
begin
  AssertTrue(IsAligned(8, 8));
  AssertTrue(IsAligned(16, 8));
  AssertTrue(IsAligned(32, 16));
  AssertTrue(IsAligned(4096, 4096));
end;

procedure TTestMathIntUtil.Test_IsAligned_NotAligned_ReturnsFalse;
begin
  AssertFalse(IsAligned(1, 8));
  AssertFalse(IsAligned(7, 8));
  AssertFalse(IsAligned(9, 8));
  AssertFalse(IsAligned(15, 16));
end;

procedure TTestMathIntUtil.Test_IsAligned_Zero_ReturnsTrue;
begin
  AssertTrue(IsAligned(0, 8));
  AssertTrue(IsAligned(0, 16));
  AssertTrue(IsAligned(0, 4096));
end;

initialization
  RegisterTest(TTestMathIntUtil);

end.
