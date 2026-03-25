unit fafafa.core.layout.testcase;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.layout;

type
  TTestCoreLayout = class(TTestCase)
  published
    procedure Test_TryNextPowerOfTwo_HandlesBasicAndOverflowCases;
    procedure Test_TMemLayout_Create_NormalizesAlignment;
    procedure Test_TMemLayout_AlignedSize_Extend_And_Pad;
    procedure Test_TMemLayout_Empty_And_DefaultAlign;
    procedure Test_TAllocCaps_SupportsLayout_RespectsAlignmentCaps;
  end;

implementation

procedure TTestCoreLayout.Test_TryNextPowerOfTwo_HandlesBasicAndOverflowCases;
var
  LResult: SizeUInt;
begin
  AssertTrue(TryNextPowerOfTwo(0, LResult));
  AssertEquals(SizeUInt(1), LResult);
  AssertTrue(TryNextPowerOfTwo(5, LResult));
  AssertEquals(SizeUInt(8), LResult);
  {$IFDEF CPU64}
  AssertFalse(TryNextPowerOfTwo((SizeUInt(1) shl 63) + 1, LResult));
  {$ELSE}
  AssertFalse(TryNextPowerOfTwo((SizeUInt(1) shl 31) + 1, LResult));
  {$ENDIF}
end;

procedure TTestCoreLayout.Test_TMemLayout_Create_NormalizesAlignment;
var
  LLayout: TMemLayout;
begin
  LLayout := TMemLayout.Create(100, 0);
  AssertEquals(SizeUInt(MEM_DEFAULT_ALIGN), LLayout.Align);

  LLayout := TMemLayout.Create(100, 5);
  AssertEquals(SizeUInt(8), LLayout.Align);
  AssertTrue(LLayout.IsValid);
end;

procedure TTestCoreLayout.Test_TMemLayout_AlignedSize_Extend_And_Pad;
var
  LLeft: TMemLayout;
  LRight: TMemLayout;
  LCombined: TMemLayout;
  LPadded: TMemLayout;
begin
  LLeft := TMemLayout.Create(3, 1);
  LRight := TMemLayout.Create(4, 4);
  LCombined := LLeft.Extend(LRight);
  AssertEquals(SizeUInt(8), LCombined.Size);
  AssertEquals(SizeUInt(4), LCombined.Align);

  LPadded := TMemLayout.Create(10, 4).Pad(16);
  AssertEquals(SizeUInt(16), LPadded.Size);
  AssertEquals(SizeUInt(16), LPadded.Align);
end;

procedure TTestCoreLayout.Test_TMemLayout_Empty_And_DefaultAlign;
var
  LLayout: TMemLayout;
begin
  LLayout := TMemLayout.Empty;
  AssertEquals(SizeUInt(0), LLayout.Size);
  AssertEquals(SizeUInt(1), LLayout.Align);
  AssertEquals(SizeUInt(MEM_DEFAULT_ALIGN), TMemLayout.DefaultAlign);
end;

procedure TTestCoreLayout.Test_TAllocCaps_SupportsLayout_RespectsAlignmentCaps;
var
  LCaps: TAllocCaps;
begin
  LCaps := TAllocCaps.ForSystemHeap;
  AssertTrue(LCaps.SupportsLayout(TMemLayout.Create(64, MEM_DEFAULT_ALIGN)));
  AssertFalse(LCaps.SupportsLayout(TMemLayout.Create(64, MEM_CACHE_LINE_SIZE)));
end;

initialization
  RegisterTest(TTestCoreLayout);

end.
