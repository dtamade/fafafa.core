unit fafafa.core.math.testcase;

{$MODE OBJFPC}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.math;

type
  TTestMath = class(TTestCase)
  published
    // === IsAddOverflow SizeUInt ===
    procedure Test_IsAddOverflow_SizeUInt_NoOverflow_ReturnsFalse;
    procedure Test_IsAddOverflow_SizeUInt_Overflow_ReturnsTrue;
    procedure Test_IsAddOverflow_SizeUInt_BoundaryNoOverflow_ReturnsFalse;
    procedure Test_IsAddOverflow_SizeUInt_BoundaryOverflow_ReturnsTrue;
    procedure Test_IsAddOverflow_SizeUInt_ZeroValues_ReturnsFalse;
    procedure Test_IsAddOverflow_SizeUInt_MaxPlusZero_ReturnsFalse;
    procedure Test_IsAddOverflow_SizeUInt_MaxPlusOne_ReturnsTrue;

    // === IsAddOverflow UInt32 ===
    procedure Test_IsAddOverflow_UInt32_NoOverflow_ReturnsFalse;
    procedure Test_IsAddOverflow_UInt32_Overflow_ReturnsTrue;
    procedure Test_IsAddOverflow_UInt32_BoundaryNoOverflow_ReturnsFalse;
    procedure Test_IsAddOverflow_UInt32_BoundaryOverflow_ReturnsTrue;
    procedure Test_IsAddOverflow_UInt32_ZeroValues_ReturnsFalse;

    // === IsSubUnderflow SizeUInt ===
    procedure Test_IsSubUnderflow_SizeUInt_NoUnderflow_ReturnsFalse;
    procedure Test_IsSubUnderflow_SizeUInt_Underflow_ReturnsTrue;
    procedure Test_IsSubUnderflow_SizeUInt_Equal_ReturnsFalse;
    procedure Test_IsSubUnderflow_SizeUInt_Zero_ReturnsFalse;

    // === IsSubUnderflow UInt32 ===
    procedure Test_IsSubUnderflow_UInt32_NoUnderflow_ReturnsFalse;
    procedure Test_IsSubUnderflow_UInt32_Underflow_ReturnsTrue;
    procedure Test_IsSubUnderflow_UInt32_Equal_ReturnsFalse;

    // === IsMulOverflow SizeUInt ===
    procedure Test_IsMulOverflow_SizeUInt_NoOverflow_ReturnsFalse;
    procedure Test_IsMulOverflow_SizeUInt_Overflow_ReturnsTrue;
    procedure Test_IsMulOverflow_SizeUInt_Zero_ReturnsFalse;
    procedure Test_IsMulOverflow_SizeUInt_One_ReturnsFalse;
    procedure Test_IsMulOverflow_SizeUInt_Boundary_Success;

    // === IsMulOverflow UInt32 ===
    procedure Test_IsMulOverflow_UInt32_NoOverflow_ReturnsFalse;
    procedure Test_IsMulOverflow_UInt32_Overflow_ReturnsTrue;
    procedure Test_IsMulOverflow_UInt32_Zero_ReturnsFalse;

    // === SaturatingAdd SizeUInt ===
    procedure Test_SaturatingAdd_SizeUInt_Normal_ReturnsSum;
    procedure Test_SaturatingAdd_SizeUInt_Overflow_ReturnsMax;
    procedure Test_SaturatingAdd_SizeUInt_MaxPlusOne_ReturnsMax;

    // === SaturatingAdd UInt32 ===
    procedure Test_SaturatingAdd_UInt32_Normal_ReturnsSum;
    procedure Test_SaturatingAdd_UInt32_Overflow_ReturnsMax;

    // === SaturatingSub SizeUInt ===
    procedure Test_SaturatingSub_SizeUInt_Normal_ReturnsDiff;
    procedure Test_SaturatingSub_SizeUInt_Underflow_ReturnsZero;

    // === SaturatingSub UInt32 ===
    procedure Test_SaturatingSub_UInt32_Normal_ReturnsDiff;
    procedure Test_SaturatingSub_UInt32_Underflow_ReturnsZero;

    // === SaturatingMul SizeUInt ===
    procedure Test_SaturatingMul_SizeUInt_Normal_ReturnsProduct;
    procedure Test_SaturatingMul_SizeUInt_Overflow_ReturnsMax;
    procedure Test_SaturatingMul_SizeUInt_Zero_ReturnsZero;

    // === SaturatingMul UInt32 ===
    procedure Test_SaturatingMul_UInt32_Normal_ReturnsProduct;
    procedure Test_SaturatingMul_UInt32_Overflow_ReturnsMax;

    // === Min/Max helpers ===
    procedure Test_Min_SizeUInt_Basic_ReturnsSmaller;
    procedure Test_Max_SizeUInt_Basic_ReturnsLarger;
    procedure Test_Min_Int64_Basic_ReturnsSmaller;
    procedure Test_Max_Int64_Basic_ReturnsLarger;
  end;

implementation

// === IsAddOverflow SizeUInt ===

procedure TTestMath.Test_IsAddOverflow_SizeUInt_NoOverflow_ReturnsFalse;
begin
  AssertFalse(IsAddOverflow(SizeUInt(10), SizeUInt(20)));
  AssertFalse(IsAddOverflow(SizeUInt(100), SizeUInt(200)));
end;

procedure TTestMath.Test_IsAddOverflow_SizeUInt_Overflow_ReturnsTrue;
begin
  AssertTrue(IsAddOverflow(MAX_SIZE_UINT, SizeUInt(1)));
  AssertTrue(IsAddOverflow(MAX_SIZE_UINT - 10, SizeUInt(20)));
end;

procedure TTestMath.Test_IsAddOverflow_SizeUInt_BoundaryNoOverflow_ReturnsFalse;
var
  HalfMax: SizeUInt;
begin
  AssertFalse(IsAddOverflow(MAX_SIZE_UINT - 1, SizeUInt(1)));
  HalfMax := MAX_SIZE_UINT div 2;
  AssertFalse(IsAddOverflow(HalfMax, HalfMax));
end;

procedure TTestMath.Test_IsAddOverflow_SizeUInt_BoundaryOverflow_ReturnsTrue;
var
  HalfMaxPlus1: SizeUInt;
begin
  AssertTrue(IsAddOverflow(MAX_SIZE_UINT, SizeUInt(1)));
  HalfMaxPlus1 := MAX_SIZE_UINT div 2 + 1;
  AssertTrue(IsAddOverflow(HalfMaxPlus1, HalfMaxPlus1));
end;

procedure TTestMath.Test_IsAddOverflow_SizeUInt_ZeroValues_ReturnsFalse;
begin
  AssertFalse(IsAddOverflow(SizeUInt(0), SizeUInt(0)));
  AssertFalse(IsAddOverflow(SizeUInt(0), SizeUInt(100)));
  AssertFalse(IsAddOverflow(SizeUInt(100), SizeUInt(0)));
end;

procedure TTestMath.Test_IsAddOverflow_SizeUInt_MaxPlusZero_ReturnsFalse;
begin
  AssertFalse(IsAddOverflow(MAX_SIZE_UINT, SizeUInt(0)));
  AssertFalse(IsAddOverflow(SizeUInt(0), MAX_SIZE_UINT));
end;

procedure TTestMath.Test_IsAddOverflow_SizeUInt_MaxPlusOne_ReturnsTrue;
begin
  AssertTrue(IsAddOverflow(MAX_SIZE_UINT, SizeUInt(1)));
  AssertTrue(IsAddOverflow(SizeUInt(1), MAX_SIZE_UINT));
end;

// === IsAddOverflow UInt32 ===

procedure TTestMath.Test_IsAddOverflow_UInt32_NoOverflow_ReturnsFalse;
begin
  AssertFalse(IsAddOverflow(UInt32(10), UInt32(20)));
  AssertFalse(IsAddOverflow(UInt32(100), UInt32(200)));
end;

procedure TTestMath.Test_IsAddOverflow_UInt32_Overflow_ReturnsTrue;
begin
  AssertTrue(IsAddOverflow(MAX_UINT32, UInt32(1)));
  AssertTrue(IsAddOverflow(MAX_UINT32 - 10, UInt32(20)));
end;

procedure TTestMath.Test_IsAddOverflow_UInt32_BoundaryNoOverflow_ReturnsFalse;
var
  HalfMax: UInt32;
begin
  AssertFalse(IsAddOverflow(MAX_UINT32 - 1, UInt32(1)));
  HalfMax := MAX_UINT32 div 2;
  AssertFalse(IsAddOverflow(HalfMax, HalfMax));
end;

procedure TTestMath.Test_IsAddOverflow_UInt32_BoundaryOverflow_ReturnsTrue;
var
  HalfMaxPlus1: UInt32;
begin
  AssertTrue(IsAddOverflow(MAX_UINT32, UInt32(1)));
  HalfMaxPlus1 := MAX_UINT32 div 2 + 1;
  AssertTrue(IsAddOverflow(HalfMaxPlus1, HalfMaxPlus1));
end;

procedure TTestMath.Test_IsAddOverflow_UInt32_ZeroValues_ReturnsFalse;
begin
  AssertFalse(IsAddOverflow(UInt32(0), UInt32(0)));
  AssertFalse(IsAddOverflow(UInt32(0), UInt32(100)));
  AssertFalse(IsAddOverflow(UInt32(100), UInt32(0)));
end;

// === IsSubUnderflow SizeUInt ===

procedure TTestMath.Test_IsSubUnderflow_SizeUInt_NoUnderflow_ReturnsFalse;
begin
  AssertFalse(IsSubUnderflow(SizeUInt(100), SizeUInt(50)));
  AssertFalse(IsSubUnderflow(MAX_SIZE_UINT, SizeUInt(1)));
end;

procedure TTestMath.Test_IsSubUnderflow_SizeUInt_Underflow_ReturnsTrue;
begin
  AssertTrue(IsSubUnderflow(SizeUInt(50), SizeUInt(100)));
  AssertTrue(IsSubUnderflow(SizeUInt(0), SizeUInt(1)));
end;

procedure TTestMath.Test_IsSubUnderflow_SizeUInt_Equal_ReturnsFalse;
begin
  AssertFalse(IsSubUnderflow(SizeUInt(100), SizeUInt(100)));
  AssertFalse(IsSubUnderflow(MAX_SIZE_UINT, MAX_SIZE_UINT));
end;

procedure TTestMath.Test_IsSubUnderflow_SizeUInt_Zero_ReturnsFalse;
begin
  AssertFalse(IsSubUnderflow(SizeUInt(100), SizeUInt(0)));
  AssertFalse(IsSubUnderflow(MAX_SIZE_UINT, SizeUInt(0)));
end;

// === IsSubUnderflow UInt32 ===

procedure TTestMath.Test_IsSubUnderflow_UInt32_NoUnderflow_ReturnsFalse;
begin
  AssertFalse(IsSubUnderflow(UInt32(100), UInt32(50)));
  AssertFalse(IsSubUnderflow(MAX_UINT32, UInt32(1)));
end;

procedure TTestMath.Test_IsSubUnderflow_UInt32_Underflow_ReturnsTrue;
begin
  AssertTrue(IsSubUnderflow(UInt32(50), UInt32(100)));
  AssertTrue(IsSubUnderflow(UInt32(0), UInt32(1)));
end;

procedure TTestMath.Test_IsSubUnderflow_UInt32_Equal_ReturnsFalse;
begin
  AssertFalse(IsSubUnderflow(UInt32(100), UInt32(100)));
  AssertFalse(IsSubUnderflow(UInt32(0), UInt32(0)));
end;

// === IsMulOverflow SizeUInt ===

procedure TTestMath.Test_IsMulOverflow_SizeUInt_NoOverflow_ReturnsFalse;
begin
  AssertFalse(IsMulOverflow(SizeUInt(100), SizeUInt(200)));
end;

procedure TTestMath.Test_IsMulOverflow_SizeUInt_Overflow_ReturnsTrue;
begin
  AssertTrue(IsMulOverflow(MAX_SIZE_UINT, SizeUInt(2)));
end;

procedure TTestMath.Test_IsMulOverflow_SizeUInt_Zero_ReturnsFalse;
begin
  AssertFalse(IsMulOverflow(SizeUInt(0), MAX_SIZE_UINT));
  AssertFalse(IsMulOverflow(MAX_SIZE_UINT, SizeUInt(0)));
end;

procedure TTestMath.Test_IsMulOverflow_SizeUInt_One_ReturnsFalse;
begin
  AssertFalse(IsMulOverflow(SizeUInt(1), MAX_SIZE_UINT));
  AssertFalse(IsMulOverflow(MAX_SIZE_UINT, SizeUInt(1)));
end;

procedure TTestMath.Test_IsMulOverflow_SizeUInt_Boundary_Success;
begin
  AssertFalse(IsMulOverflow(SizeUInt(65535), SizeUInt(65535)));
end;

// === IsMulOverflow UInt32 ===

procedure TTestMath.Test_IsMulOverflow_UInt32_NoOverflow_ReturnsFalse;
begin
  AssertFalse(IsMulOverflow(UInt32(100), UInt32(200)));
end;

procedure TTestMath.Test_IsMulOverflow_UInt32_Overflow_ReturnsTrue;
begin
  AssertTrue(IsMulOverflow(MAX_UINT32, UInt32(2)));
  AssertTrue(IsMulOverflow(UInt32(70000), UInt32(70000)));
end;

procedure TTestMath.Test_IsMulOverflow_UInt32_Zero_ReturnsFalse;
begin
  AssertFalse(IsMulOverflow(UInt32(0), MAX_UINT32));
  AssertFalse(IsMulOverflow(MAX_UINT32, UInt32(0)));
end;

// === SaturatingAdd ===

procedure TTestMath.Test_SaturatingAdd_SizeUInt_Normal_ReturnsSum;
begin
  AssertEquals(SizeUInt(150), SaturatingAdd(SizeUInt(100), SizeUInt(50)));
end;

procedure TTestMath.Test_SaturatingAdd_SizeUInt_Overflow_ReturnsMax;
var
  V: SizeUInt;
begin
  V := MAX_SIZE_UINT;
  AssertEquals(MAX_SIZE_UINT, SaturatingAdd(V, V));
end;

procedure TTestMath.Test_SaturatingAdd_SizeUInt_MaxPlusOne_ReturnsMax;
var
  V: SizeUInt;
begin
  V := MAX_SIZE_UINT;
  AssertEquals(MAX_SIZE_UINT, SaturatingAdd(V, SizeUInt(1)));
end;

procedure TTestMath.Test_SaturatingAdd_UInt32_Normal_ReturnsSum;
begin
  AssertEquals(UInt32(150), SaturatingAdd(UInt32(100), UInt32(50)));
end;

procedure TTestMath.Test_SaturatingAdd_UInt32_Overflow_ReturnsMax;
var
  V: UInt32;
begin
  V := MAX_UINT32;
  AssertEquals(MAX_UINT32, SaturatingAdd(V, V));
end;

// === SaturatingSub ===

procedure TTestMath.Test_SaturatingSub_SizeUInt_Normal_ReturnsDiff;
begin
  AssertEquals(SizeUInt(50), SaturatingSub(SizeUInt(100), SizeUInt(50)));
end;

procedure TTestMath.Test_SaturatingSub_SizeUInt_Underflow_ReturnsZero;
var
  Z: SizeUInt;
begin
  Z := 0;
  AssertEquals(SizeUInt(0), SaturatingSub(Z, MAX_SIZE_UINT));
end;

procedure TTestMath.Test_SaturatingSub_UInt32_Normal_ReturnsDiff;
begin
  AssertEquals(UInt32(50), SaturatingSub(UInt32(100), UInt32(50)));
end;

procedure TTestMath.Test_SaturatingSub_UInt32_Underflow_ReturnsZero;
var
  Z: UInt32;
begin
  Z := 0;
  AssertEquals(UInt32(0), SaturatingSub(Z, UInt32(1)));
end;

// === SaturatingMul ===

procedure TTestMath.Test_SaturatingMul_SizeUInt_Normal_ReturnsProduct;
begin
  AssertEquals(SizeUInt(5000), SaturatingMul(SizeUInt(100), SizeUInt(50)));
end;

procedure TTestMath.Test_SaturatingMul_SizeUInt_Overflow_ReturnsMax;
var
  V: SizeUInt;
begin
  V := MAX_SIZE_UINT;
  AssertEquals(MAX_SIZE_UINT, SaturatingMul(V, V));
end;

procedure TTestMath.Test_SaturatingMul_SizeUInt_Zero_ReturnsZero;
begin
  AssertEquals(SizeUInt(0), SaturatingMul(SizeUInt(0), MAX_SIZE_UINT));
end;

procedure TTestMath.Test_SaturatingMul_UInt32_Normal_ReturnsProduct;
begin
  AssertEquals(UInt32(5000), SaturatingMul(UInt32(100), UInt32(50)));
end;

procedure TTestMath.Test_SaturatingMul_UInt32_Overflow_ReturnsMax;
var
  V: UInt32;
begin
  V := MAX_UINT32;
  AssertEquals(MAX_UINT32, SaturatingMul(V, UInt32(2)));
end;

// === Min/Max helpers ===

procedure TTestMath.Test_Min_SizeUInt_Basic_ReturnsSmaller;
begin
  AssertEquals(SizeUInt(1), Min(SizeUInt(1), SizeUInt(2)));
  AssertEquals(SizeUInt(0), Min(MAX_SIZE_UINT, SizeUInt(0)));
end;

procedure TTestMath.Test_Max_SizeUInt_Basic_ReturnsLarger;
begin
  AssertEquals(SizeUInt(2), Max(SizeUInt(1), SizeUInt(2)));
  AssertEquals(MAX_SIZE_UINT, Max(MAX_SIZE_UINT, SizeUInt(0)));
end;

procedure TTestMath.Test_Min_Int64_Basic_ReturnsSmaller;
begin
  AssertEquals(Int64(-5), Min(Int64(-5), Int64(1)));
  AssertEquals(Low(Int64), Min(Low(Int64), Int64(0)));
end;

procedure TTestMath.Test_Max_Int64_Basic_ReturnsLarger;
begin
  AssertEquals(Int64(1), Max(Int64(-5), Int64(1)));
  AssertEquals(High(Int64), Max(Low(Int64), High(Int64)));
end;

initialization
  RegisterTest(TTestMath);

end.
