unit test_mem_utils;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.mem.utils;

type

  { TTestCase_mem_utils }

  TTestCase_mem_utils = class(TTestCase)
  published
    procedure Test_IsOverlap;
    procedure Test_IsOverlapUnChecked;
    procedure Test_IsOverlap_2;
    procedure Test_IsOverlapUnChecked_2;
    procedure Test_Copy;
    procedure Test_CopyUnChecked;
    procedure Test_CopyNonOverlap;
    procedure Test_CopyNonOverlapUnChecked;
    procedure Test_Fill;
    procedure Test_Fill8;
    procedure Test_Fill16;
    procedure Test_Fill32;
    procedure Test_Fill64;
    procedure Test_Zero;
    procedure Test_Compare;
    procedure Test_Compare8;
    procedure Test_Compare16;
    procedure Test_Compare32;
    procedure Test_Equal;
    procedure Test_IsAligned;
    procedure Test_AlignUp;
    procedure Test_AlignUpUnChecked;
    procedure Test_AlignDown;
    procedure Test_IsPowerOfTwo;
    procedure Test_Unchecked_Aliases_Smoke;

    procedure Test_AlignAndCopy_Exceptions;

  end;

implementation

procedure TTestCase_mem_utils.Test_IsOverlap;
var
  LMem: Pointer;
  LPtr1, LPtr2, LPtr3: Pointer;
begin
  LMem       := GetMem(100); // Allocate a 100-byte block for testing
  try
    LPtr1 := LMem;
    LPtr2 := PByte(LMem) + 10;
    LPtr3 := PByte(LMem) + 30;

    // Case 1: No overlap
    AssertFalse('Case 1.1: No overlap, block1 before block2', IsOverlap(LPtr1, SizeUInt(10), LPtr2, SizeUInt(20)));
    AssertFalse('Case 1.2: No overlap, block2 before block1', IsOverlap(LPtr2, SizeUInt(20), LPtr1, SizeUInt(10)));

    // Case 2: Touching boundaries (not overlapping)
    AssertFalse('Case 2.1: Touching boundaries, block1 ends where block2 begins', IsOverlap(LPtr1, SizeUInt(10), LPtr2, SizeUInt(20)));
    AssertFalse('Case 2.2: Touching boundaries, block2 ends where block1 begins', IsOverlap(LPtr2, SizeUInt(20), LPtr1, SizeUInt(10)));

    // Case 3: Partial overlap
    AssertTrue('Case 3.1: Partial overlap, block1 overlaps beginning of block2', IsOverlap(LPtr1, SizeUInt(15), LPtr2, SizeUInt(20)));
    AssertTrue('Case 3.2: Partial overlap, block2 overlaps beginning of block1', IsOverlap(LPtr2, SizeUInt(20), LPtr1, SizeUInt(15)));
    AssertTrue('Case 3.3: Partial overlap, block1 overlaps end of block2', IsOverlap(LPtr2, SizeUInt(15), LPtr1, SizeUInt(20)));
    AssertTrue('Case 3.4: Partial overlap, block2 overlaps end of block1', IsOverlap(LPtr1, SizeUInt(20), LPtr2, SizeUInt(15)));

    // Case 4: Complete overlap (one block inside another)
    AssertTrue('Case 4.1: Complete overlap, block2 is inside block1', IsOverlap(LPtr1, SizeUInt(30), LPtr2, SizeUInt(10)));
    AssertTrue('Case 4.2: Complete overlap, block1 is inside block2', IsOverlap(LPtr2, SizeUInt(10), LPtr1, SizeUInt(30)));

    // Case 5: Identical blocks
    AssertTrue('Case 5.1: Identical blocks', IsOverlap(LPtr1, SizeUInt(10), LPtr1, SizeUInt(10)));

    // Case 6: Overlap with a third block
    AssertTrue('Case 6.1: Overlap with a third block', IsOverlap(LPtr1, SizeUInt(25), LPtr2, SizeUInt(10)));
    AssertFalse('Case 6.2: No overlap with a third block', IsOverlap(LPtr1, SizeUInt(5), LPtr3, SizeUInt(10)));

    // Case 7: Edge cases with zero size
    AssertFalse('Case 7.1: Zero-size block1 should not overlap', IsOverlap(LPtr1, SizeUInt(0), LPtr2, SizeUInt(10)));
    AssertFalse('Case 7.2: Zero-size block2 should not overlap', IsOverlap(LPtr1, SizeUInt(10), LPtr2, SizeUInt(0)));
    AssertFalse('Case 7.3: Two zero-size blocks at the same address are not considered overlapping', IsOverlap(LPtr1, SizeUInt(0), LPtr1, SizeUInt(0)));

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    { 异常测试: aSize1 导致地址计算溢出 }
    AssertException(
      'Exception expected for aSize1 causing address calculation to overflow',
      EOutOfRange,
      procedure
      begin
        IsOverlap(LPtr1, High(PtrUInt), LPtr2, 10);
      end);

    { 异常测试: aSize2 导致地址计算溢出 }
    AssertException(
      'Exception expected for aSize2 causing address calculation to overflow',
      EOutOfRange,
      procedure
      begin
        IsOverlap(LPtr1, 10, LPtr2, High(PtrUInt));
      end);
    {$ENDIF}

  finally
    FreeMem(LMem);
  end;
end;

procedure TTestCase_mem_utils.Test_Copy;
var
  LMem1:      Pointer;
  LMem2:      Pointer;
  LP:         PByte;
  i:          Integer;
begin
  LMem1 := GetMem(4);
  LMem2 := GetMem(4);
  try
    LP    := PByte(LMem1);
    LP[0] := 0;
    LP[1] := 1;
    LP[2] := 2;
    LP[3] := 3;

  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    { 异常测试: aSrc = nil }
    AssertException(
      'exception should be raised: ENil',
      EArgumentNil,
      procedure
      begin
        Copy(nil, LMem2, 4);
      end);

    { 异常测试: aDst = nil }
    AssertException(
      'exception should be raised: EArgumentNil',
      EArgumentNil,
      procedure
      begin
        Copy(LMem1, nil, 4);
      end);
  {$ENDIF}
  finally
    FreeMem(LMem1);
    FreeMem(LMem2);
  end;

  { 基础测试 }
  LMem1 := GetMem(4);
  LMem2 := GetMem(4);
  try
    LP := PByte(LMem1);
    LP[0] := 0;
    LP[1] := 1;
    LP[2] := 2;
    LP[3] := 3;
    LP := PByte(LMem2);
    LP[0] := 4;
    LP[1] := 5;
    LP[2] := 6;
    LP[3] := 7;

    Copy(LMem1, LMem2, 4);
    AssertEquals(PByte(LMem2)[0], 0);
    AssertEquals(PByte(LMem2)[1], 1);
    AssertEquals(PByte(LMem2)[2], 2);
    AssertEquals(PByte(LMem2)[3], 3);

    { 空操作原则测试: aSize = 0 }
    Copy(LMem1, LMem2, 0);
    AssertEquals(PByte(LMem2)[0], 0);
    AssertEquals(PByte(LMem2)[1], 1);
    AssertEquals(PByte(LMem2)[2], 2);
    AssertEquals(PByte(LMem2)[3], 3);

    { 正向重叠测试 }

    LP := PByte(LMem1);
    LP[0] := 1;
    LP[1] := 2;
    LP[2] := 3;
    LP[3] := 4;
    Copy(LMem1, @LP[1], 2);

    AssertEquals(PByte(LMem1)[0], 1);
    AssertEquals(PByte(LMem1)[1], 1);
    AssertEquals(PByte(LMem1)[2], 2);
    AssertEquals(PByte(LMem1)[3], 4);

    { 反向重叠测试 }

    LP := PByte(LMem1);
    LP[0] := 1;
    LP[1] := 2;
    LP[2] := 3;
    LP[3] := 4;

    Copy(@LP[2], PByte(LMem1) + 1, 2);
    AssertEquals(PByte(LMem1)[0], 1);
    AssertEquals(PByte(LMem1)[1], 3);
    AssertEquals(PByte(LMem1)[2], 4);
    AssertEquals(PByte(LMem1)[3], 4);
  finally
    FreeMem(LMem1);
    FreeMem(LMem2);
  end;

  { 大块内存测试 }

  LMem1 := GetMem(256);
  PByte(LMem1)[0] := 1;
  PByte(LMem1)[1] := 2;
  PByte(LMem1)[2] := 3;
  PByte(LMem1)[3] := 4;

  LMem2 := GetMem(256);
  try
    for i := 0 to 255 do
      PByte(LMem1)[i] := i;

    LP := PByte(LMem1);
    Copy(LMem1, LMem2, 256);
    LP := PByte(LMem2);

    for i := 0 to 255 do
      AssertEquals(PByte(LMem2)[i], i);

  finally
    FreeMem(LMem1);
    FreeMem(LMem2);
  end;
end;

procedure TTestCase_mem_utils.Test_CopyUnChecked;
var
  LMem1, LMem2: Pointer;
  LP: PByte;
  i: Integer;
begin
  { 基本测试 }

  LMem1 := GetMem(4);
  LMem2 := GetMem(4);
  try
    LP := PByte(LMem1);
    LP[0] := 0;
    LP[1] := 1;
    LP[2] := 2;
    LP[3] := 3;

    LP := PByte(LMem2);
    LP[0] := 4;
    LP[1] := 5;
    LP[2] := 6;
    LP[3] := 7;

    CopyUnChecked(LMem1, LMem2, 4);

    AssertEquals(LP[0], 0);
    AssertEquals(LP[1], 1);
    AssertEquals(LP[2], 2);
    AssertEquals(LP[3], 3);

    { 正向重叠测试 }

    LP := PByte(LMem1);
    LP[0] := 1;
    LP[1] := 2;
    LP[2] := 3;
    LP[3] := 4;
    CopyUnChecked(LMem1, @LP[1], 2);

    AssertEquals(PByte(LMem1)[0], 1);
    AssertEquals(PByte(LMem1)[1], 1);
    AssertEquals(PByte(LMem1)[2], 2);
    AssertEquals(PByte(LMem1)[3], 4);

    { 反向重叠测试 }

    LP := PByte(LMem1);
    LP[0] := 1;
    LP[1] := 2;
    LP[2] := 3;
    LP[3] := 4;

    CopyUnChecked(@LP[2], PByte(LMem1) + 1, 2);
    AssertEquals(PByte(LMem1)[0], 1);
    AssertEquals(PByte(LMem1)[1], 3);
    AssertEquals(PByte(LMem1)[2], 4);
    AssertEquals(PByte(LMem1)[3], 4);
  finally
    FreeMem(LMem1);
    FreeMem(LMem2);
  end;

  { 大块内存测试 }

  LMem1 := GetMem(256);
  LMem2 := GetMem(256);
  try
    PByte(LMem1)[0] := 1;
    PByte(LMem1)[1] := 2;
    PByte(LMem1)[2] := 3;
    PByte(LMem1)[3] := 4;

    for i := 0 to 255 do
      PByte(LMem1)[i] := i;

    CopyUnChecked(LMem1, LMem2, 256);

    for i := 0 to 255 do
      AssertEquals(PByte(LMem2)[i], i);

  finally
    FreeMem(LMem1);
    FreeMem(LMem2);
  end;
end;

procedure TTestCase_mem_utils.Test_CopyNonOverlap;
var
  LMem1:      Pointer;
  LMem2:      Pointer;
  LP:         PByte;
  i:          Integer;
begin
  LMem1      := GetMem(4);
  LMem2      := GetMem(4);
  try
    LP    := PByte(LMem1);
    LP[0] := 0;
    LP[1] := 1;
    LP[2] := 2;
    LP[3] := 3;

  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    { 异常测试: aSrc = nil }
    AssertException(
      'exception should be raised: EArgumentNil',
      EArgumentNil,
      procedure
      begin
        CopyNonOverlap(nil, LMem2, 4);
      end);

    { 异常测试: aDst = nil }
    AssertException(
      'exception should be raised: EArgumentNil',
      EArgumentNil,
      procedure
      begin
        CopyNonOverlap(LMem1, nil, 4);
      end);

  {$ENDIF}
  finally
    FreeMem(LMem1);
    FreeMem(LMem2);
  end;

  { 基础测试 }

  LMem1 := GetMem(4);
  LMem2 := GetMem(4);
  try
    LP := PByte(LMem1);
    LP[0] := 0;
    LP[1] := 1;
    LP[2] := 2;
    LP[3] := 3;
    LP := PByte(LMem2);
    LP[0] := 4;
    LP[1] := 5;
    LP[2] := 6;
    LP[3] := 7;

    CopyNonOverlap(LMem1, LMem2, 4);
    AssertEquals(PByte(LMem2)[0], 0);
    AssertEquals(PByte(LMem2)[1], 1);
    AssertEquals(PByte(LMem2)[2], 2);
    AssertEquals(PByte(LMem2)[3], 3);

    { 空操作原则测试: aSize = 0 }
    CopyNonOverlap(LMem1, LMem2, 0);
    AssertEquals(PByte(LMem2)[0], 0);
    AssertEquals(PByte(LMem2)[1], 1);
    AssertEquals(PByte(LMem2)[2], 2);
    AssertEquals(PByte(LMem2)[3], 3);

  finally
    FreeMem(LMem1);
    FreeMem(LMem2);
  end;

  { 大块内存测试 }

  LMem1 := GetMem(256);
  PByte(LMem1)[0] := 1;
  PByte(LMem1)[1] := 2;
  PByte(LMem1)[2] := 3;
  PByte(LMem1)[3] := 4;

  LMem2 := GetMem(256);
  try
    for i := 0 to 255 do
      PByte(LMem1)[i] := i;

    CopyNonOverlap(LMem1, LMem2, 256);

    for i := 0 to 255 do
      AssertEquals(PByte(LMem2)[i], i);

  finally
    FreeMem(LMem1);
    FreeMem(LMem2);
  end;
end;

procedure TTestCase_mem_utils.Test_CopyNonOverlapUnChecked;
var
  LMem1, LMem2: Pointer;
  LP: PByte;
  i: Integer;
begin
  { 基本测试 }

  LMem1 := GetMem(4);
  LMem2 := GetMem(4);
  try
    LP := PByte(LMem1);
    LP[0] := 0;
    LP[1] := 1;
    LP[2] := 2;
    LP[3] := 3;

    LP := PByte(LMem2);
    LP[0] := 4;
    LP[1] := 5;
    LP[2] := 6;
    LP[3] := 7;

    CopyNonOverlapUnChecked(LMem1, LMem2, 4);

    AssertEquals(LP[0], 0);
    AssertEquals(LP[1], 1);
    AssertEquals(LP[2], 2);
    AssertEquals(LP[3], 3);

  finally
    FreeMem(LMem1);
    FreeMem(LMem2);
  end;

  { 大块内存测试 }

  LMem1 := GetMem(256);
  LMem2 := GetMem(256);
  try
    PByte(LMem1)[0] := 1;
    PByte(LMem1)[1] := 2;
    PByte(LMem1)[2] := 3;
    PByte(LMem1)[3] := 4;

    for i := 0 to 255 do
      PByte(LMem1)[i] := i;

    CopyNonOverlapUnChecked(LMem1, LMem2, 256);

    for i := 0 to 255 do
      AssertEquals(PByte(LMem2)[i], i);

  finally
    FreeMem(LMem1);
    FreeMem(LMem2);
  end;
end;

procedure TTestCase_mem_utils.Test_Fill;
var
  LMem: Pointer;
begin
  LMem := GetMem(4);
  try
    AssertNotNull('Memory should be allocated successfully', LMem);

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    { 异常测试: aDst = nil }
    AssertException(
      'exception should be raised: EArgumentNil',
      EArgumentNil,
      procedure
      begin
        Fill(nil, 4, 0);
      end);
    {$ENDIF}

    Fill(LMem, 4, 0);
    AssertTrue(PByte(LMem)[0] = 0);
    AssertTrue(PByte(LMem)[1] = 0);
    AssertTrue(PByte(LMem)[2] = 0);
    AssertTrue(PByte(LMem)[3] = 0);

    Fill(LMem, 4, 1);
    AssertTrue(PByte(LMem)[0] = 1);
    AssertTrue(PByte(LMem)[1] = 1);
    AssertTrue(PByte(LMem)[2] = 1);
    AssertTrue(PByte(LMem)[3] = 1);

    { 空操作原则测试: aCount = 0 }
    Fill(LMem, 0, 0);
    AssertTrue(PByte(LMem)[0] = 1);
    AssertTrue(PByte(LMem)[1] = 1);
    AssertTrue(PByte(LMem)[2] = 1);
    AssertTrue(PByte(LMem)[3] = 1);

  finally
    FreeMem(LMem);
  end;
end;

procedure TTestCase_mem_utils.Test_Fill8;
var
  LMem: Pointer;
begin
  LMem := GetMem(4);
  try
    AssertNotNull('Memory should be allocated successfully', LMem);

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    { 异常测试: aDst = nil }
    AssertException(
      'exception should be raised: EArgumentNil',
      EArgumentNil,
      procedure
      begin
        Fill8(nil, 4, 0);
      end);
    {$ENDIF}

    Fill8(LMem, 4, 0);
    AssertTrue(PByte(LMem)[0] = 0);
    AssertTrue(PByte(LMem)[1] = 0);
    AssertTrue(PByte(LMem)[2] = 0);
    AssertTrue(PByte(LMem)[3] = 0);

    Fill8(LMem, 4, 1);
    AssertTrue(PByte(LMem)[0] = 1);
    AssertTrue(PByte(LMem)[1] = 1);
    AssertTrue(PByte(LMem)[2] = 1);
    AssertTrue(PByte(LMem)[3] = 1);

    { 空操作原则测试: aCount = 0 }
    Fill8(LMem, 0, 0);
    AssertTrue(PByte(LMem)[0] = 1);
    AssertTrue(PByte(LMem)[1] = 1);
    AssertTrue(PByte(LMem)[2] = 1);
    AssertTrue(PByte(LMem)[3] = 1);

  finally
    FreeMem(LMem);
  end;
end;
procedure TTestCase_mem_utils.Test_Fill16;
var
  LMem:       Pointer;
begin
  LMem := GetMem(8);
  try
    AssertNotNull('Memory should be allocated successfully', LMem);

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    { 异常测试: aDst = nil }
    AssertException(
      'exception should be raised: EArgumentNil',
      EArgumentNil,
      procedure
      begin
        Fill16(nil, 4, 0);
      end);
    {$ENDIF}

    Fill16(LMem, 4, 0);
    AssertTrue(PWord(LMem)[0] = 0);
    AssertTrue(PWord(LMem)[1] = 0);
    AssertTrue(PWord(LMem)[2] = 0);
    AssertTrue(PWord(LMem)[3] = 0);

    Fill16(LMem, 4, 65535);
    AssertTrue(PWord(LMem)[0] = 65535);
    AssertTrue(PWord(LMem)[1] = 65535);
    AssertTrue(PWord(LMem)[2] = 65535);
    AssertTrue(PWord(LMem)[3] = 65535);

    { 空操作原则测试: aCount = 0 }
    Fill16(LMem, 0, 0);
    AssertTrue(PWord(LMem)[0] = 65535);
    AssertTrue(PWord(LMem)[1] = 65535);
    AssertTrue(PWord(LMem)[2] = 65535);
    AssertTrue(PWord(LMem)[3] = 65535);

  finally
    FreeMem(LMem);
  end;
end;

procedure TTestCase_mem_utils.Test_Fill32;
var
  LMem:       Pointer;
begin
  LMem := GetMem(16);
  try
    AssertNotNull('Memory should be allocated successfully', LMem);

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    { 异常测试: aDst = nil }
    AssertException(
      'exception should be raised: EArgumentNil',
      EArgumentNil,
      procedure
      begin
        Fill32(nil, 4, 0);
      end);
    {$ENDIF}

    Fill32(LMem, 4, 0);
    AssertTrue(PLongWord(LMem)[0] = 0);
    AssertTrue(PLongWord(LMem)[1] = 0);
    AssertTrue(PLongWord(LMem)[2] = 0);
    AssertTrue(PLongWord(LMem)[3] = 0);

    Fill32(LMem, 4, 4294967295);
    AssertTrue(PLongWord(LMem)[0] = 4294967295);
    AssertTrue(PLongWord(LMem)[1] = 4294967295);
    AssertTrue(PLongWord(LMem)[2] = 4294967295);
    AssertTrue(PLongWord(LMem)[3] = 4294967295);

    { 空操作原则测试: aCount = 0 }
    Fill32(LMem, 0, 0);
    AssertTrue(PLongWord(LMem)[0] = 4294967295);
    AssertTrue(PLongWord(LMem)[1] = 4294967295);
    AssertTrue(PLongWord(LMem)[2] = 4294967295);
    AssertTrue(PLongWord(LMem)[3] = 4294967295);
  finally
    FreeMem(LMem);
  end;
end;

procedure TTestCase_mem_utils.Test_Fill64;
var
  LMem:       Pointer;
begin
  LMem := GetMem(32);
  try
    AssertNotNull('Memory should be allocated successfully', LMem);

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    { 异常测试: aDst = nil }
    AssertException(
      'exception should be raised: EArgumentNil',
      EArgumentNil,
      procedure
      begin
        Fill64(nil, 4, 0);
      end);
    {$ENDIF}

    Fill64(LMem, 4, 0);
    AssertTrue(PInt64(LMem)[0] = 0);
    AssertTrue(PInt64(LMem)[1] = 0);
    AssertTrue(PInt64(LMem)[2] = 0);
    AssertTrue(PInt64(LMem)[3] = 0);

    Fill64(LMem, 4, 9223372036854775807);
    AssertTrue(PInt64(LMem)[0] = 9223372036854775807);
    AssertTrue(PInt64(LMem)[1] = 9223372036854775807);
    AssertTrue(PInt64(LMem)[2] = 9223372036854775807);
    AssertTrue(PInt64(LMem)[3] = 9223372036854775807);

    { 空操作原则测试: aCount = 0 }
    Fill64(LMem, 0, 0);
    AssertTrue(PInt64(LMem)[0] = 9223372036854775807);
    AssertTrue(PInt64(LMem)[1] = 9223372036854775807);
    AssertTrue(PInt64(LMem)[2] = 9223372036854775807);
    AssertTrue(PInt64(LMem)[3] = 9223372036854775807);
  finally
    FreeMem(LMem);
  end;
end;

procedure TTestCase_mem_utils.Test_Zero;
var
  LMem:       Pointer;
begin
  LMem := GetMem(4);
  try
    AssertNotNull('Memory should be allocated successfully', LMem);

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    { 异常测试: aDst = nil }
    AssertException(
      'exception should be raised: EArgumentNil',
      EArgumentNil,
      procedure
      begin
        Zero(nil, 4);
      end);
    {$ENDIF}

    Zero(LMem, 4);
    AssertTrue(PByte(LMem)[0] = 0);
    AssertTrue(PByte(LMem)[1] = 0);
    AssertTrue(PByte(LMem)[2] = 0);
    AssertTrue(PByte(LMem)[3] = 0);

    PByte(LMem)[0] := 1;
    PByte(LMem)[1] := 2;
    PByte(LMem)[2] := 3;
    PByte(LMem)[3] := 4;

    Zero(LMem, 4);
    AssertTrue(PByte(LMem)[0] = 0);
    AssertTrue(PByte(LMem)[1] = 0);
    AssertTrue(PByte(LMem)[2] = 0);
    AssertTrue(PByte(LMem)[3] = 0);

    { 空操作原则测试: aCount = 0 }
    FillChar(LMem^, 4, 1);
    Zero(LMem, 0);
    AssertTrue(PByte(LMem)[0] = 1);
    AssertTrue(PByte(LMem)[1] = 1);
    AssertTrue(PByte(LMem)[2] = 1);
    AssertTrue(PByte(LMem)[3] = 1);
  finally
    FreeMem(LMem);
  end;
end;

procedure TTestCase_mem_utils.Test_Compare;
var
  LMem1, LMem2: Pointer;
begin
  LMem1 := GetMem(256);
  LMem2 := GetMem(256);
  try
    FillChar(LMem1^, 256, 1);
    FillChar(LMem2^, 256, 1);
    AssertEquals('Compare should return 0 for equal blocks', 0, Compare(LMem1, LMem2, 256));

    PByte(LMem2)[100] := 2;
    AssertTrue('Compare should return negative for less < greater', Compare(LMem1, LMem2, 256) < 0);

    PByte(LMem1)[100] := 3;
    AssertTrue('Compare should return positive for greater > less', Compare(LMem1, LMem2, 256) > 0);

    // 空操作原则测试: aCount = 0
    AssertEquals('Compare with aCount = 0 should return 0', 0, Compare(LMem1, LMem2, 0));
  finally
    FreeMem(LMem1);
    FreeMem(LMem2);
  end;
end;

procedure TTestCase_mem_utils.Test_Compare8;
var
  LU8Arr1, LU8Arr2: array of UInt8;
begin
  Initialize(LU8Arr1);
  Initialize(LU8Arr2);
  SetLength(LU8Arr1, 256);
  SetLength(LU8Arr2, 256);
  try
    FillByte(LU8Arr1[0], Length(LU8Arr1), 1);
    FillByte(LU8Arr2[0], Length(LU8Arr2), 1);
    AssertEquals('Compare8 should return 0 for equal blocks', 0, Compare8(@LU8Arr1[0], @LU8Arr2[0], 256));

    LU8Arr2[100] := 2;
    AssertTrue('Compare8 should return negative for less < greater', Compare8(@LU8Arr1[0], @LU8Arr2[0], 256) < 0);

    LU8Arr1[100] := 3;
    AssertTrue('Compare8 should return positive for greater > less', Compare8(@LU8Arr1[0], @LU8Arr2[0], 256) > 0);

    // 空操作原则测试: aCount = 0
    AssertEquals('Compare8 with aCount = 0 should return 0', 0, Compare8(@LU8Arr1[0], @LU8Arr2[0], 0));
  finally
    SetLength(LU8Arr1, 0);
    SetLength(LU8Arr2, 0);
  end;
end;

procedure TTestCase_mem_utils.Test_Compare16;
var
  LU16Arr1, LU16Arr2: array of UInt16;
begin
  Initialize(LU16Arr1);
  Initialize(LU16Arr2);
  SetLength(LU16Arr1, 128);
  SetLength(LU16Arr2, 128);
  try
    FillWord(LU16Arr1[0], Length(LU16Arr1), High(Word));
    FillWord(LU16Arr2[0], Length(LU16Arr2), High(Word));
    AssertEquals('Compare16 should return 0 for equal blocks', 0, Compare16(@LU16Arr1[0], @LU16Arr2[0], 128));

    LU16Arr2[50] := 2;
    AssertTrue('Compare16 should return negative for less < greater', Compare16(@LU16Arr2[0], @LU16Arr1[0], 128) < 0);

    LU16Arr1[50] := 3;
    AssertTrue('Compare16 should return positive for greater > less', Compare16(@LU16Arr1[0], @LU16Arr2[0], 128) > 0);

    // 空操作原则测试: aCount = 0
    AssertEquals('Compare16 with aCount = 0 should return 0', 0, Compare16(@LU16Arr1[0], @LU16Arr2[0], 0));
  finally
    SetLength(LU16Arr1, 0);
    SetLength(LU16Arr2, 0);
  end;
end;

procedure TTestCase_mem_utils.Test_Compare32;
var
  LU32Arr1, LU32Arr2: array of UInt32;
begin
  Initialize(LU32Arr1);
  Initialize(LU32Arr2);
  SetLength(LU32Arr1, 64);
  SetLength(LU32Arr2, 64);
  try
    FillDWord(LU32Arr1[0], Length(LU32Arr1), High(DWord));
    FillDWord(LU32Arr2[0], Length(LU32Arr2), High(DWord));
    AssertEquals('Compare32 should return 0 for equal blocks', 0, Compare32(@LU32Arr1[0], @LU32Arr2[0], 64));

    LU32Arr2[25] := 2;
    AssertTrue('Compare32 should return negative for less < greater', Compare32(@LU32Arr2[0], @LU32Arr1[0], 64) < 0);

    LU32Arr1[25] := 3;
    AssertTrue('Compare32 should return positive for greater > less', Compare32(@LU32Arr1[0], @LU32Arr2[0], 64) > 0);

    // 空操作原则测试: aCount = 0
    AssertEquals('Compare32 with aCount = 0 should return 0', 0, Compare32(@LU32Arr1[0], @LU32Arr2[0], 0));
  finally
    SetLength(LU32Arr1, 0);
    SetLength(LU32Arr2, 0);
  end;
end;

procedure TTestCase_mem_utils.Test_Equal;
var
  LMem1, LMem2: Pointer;
begin
  LMem1 := GetMem(256);
  LMem2 := GetMem(256);
  try
    FillChar(LMem1^, 256, 1);
    FillChar(LMem2^, 256, 1);
    AssertTrue('Equal should return true for equal blocks', Equal(LMem1, LMem2, 256));

    PByte(LMem2)[100] := 2;
    AssertFalse('Equal should return false for non-equal blocks', Equal(LMem1, LMem2, 256));

    // 空操作原则测试: aSize = 0
    AssertTrue('Equal with aSize = 0 should return true', Equal(LMem1, LMem2, 0));
  finally
    FreeMem(LMem1);
    FreeMem(LMem2);
  end;
end;

procedure TTestCase_mem_utils.Test_IsAligned;
begin
  AssertTrue('Pointer 1000 should be aligned to 8', IsAligned(Pointer(1000), 8));
  AssertFalse('Pointer 1001 should not be aligned to 8', IsAligned(Pointer(1001), 8));
  AssertTrue('Pointer 1024 should be aligned to default', IsAligned(Pointer(1024)));
end;

procedure TTestCase_mem_utils.Test_AlignUp;
begin
  AssertTrue('AlignUp(1001, 8) should be 1008', Pointer(1008) = AlignUp(Pointer(1001), 8));
  AssertTrue('AlignUp(1000, 8) should be 1000', Pointer(1000) = AlignUp(Pointer(1000), 8));
end;

procedure TTestCase_mem_utils.Test_IsOverlapUnChecked;
var
  LMem: Pointer;
  LPtr1, LPtr2, LPtr3: Pointer;
begin
  LMem       := GetMem(100); // Allocate a 100-byte block for testing
  try
    LPtr1 := LMem;
    LPtr2 := PByte(LMem) + 10;
    LPtr3 := PByte(LMem) + 30;

    // Case 1: No overlap
    AssertFalse('Case 1.1: No overlap, block1 before block2', IsOverlapUnChecked(LPtr1, SizeUInt(10), LPtr2, SizeUInt(20)));
    AssertFalse('Case 1.2: No overlap, block2 before block1', IsOverlapUnChecked(LPtr2, SizeUInt(20), LPtr1, SizeUInt(10)));

    // Case 2: Touching boundaries (not overlapping)
    AssertFalse('Case 2.1: Touching boundaries, block1 ends where block2 begins', IsOverlapUnChecked(LPtr1, SizeUInt(10), LPtr2, SizeUInt(20)));
    AssertFalse('Case 2.2: Touching boundaries, block2 ends where block1 begins', IsOverlapUnChecked(LPtr2, SizeUInt(20), LPtr1, SizeUInt(10)));

    // Case 3: Partial overlap
    AssertTrue('Case 3.1: Partial overlap, block1 overlaps beginning of block2', IsOverlapUnChecked(LPtr1, SizeUInt(15), LPtr2, SizeUInt(20)));
    AssertTrue('Case 3.2: Partial overlap, block2 overlaps beginning of block1', IsOverlapUnChecked(LPtr2, SizeUInt(20), LPtr1, SizeUInt(15)));
    AssertTrue('Case 3.3: Partial overlap, block1 overlaps end of block2', IsOverlapUnChecked(LPtr2, SizeUInt(15), LPtr1, SizeUInt(20)));
    AssertTrue('Case 3.4: Partial overlap, block2 overlaps end of block1', IsOverlapUnChecked(LPtr1, SizeUInt(20), LPtr2, SizeUInt(15)));

    // Case 4: Complete overlap (one block inside another)
    AssertTrue('Case 4.1: Complete overlap, block2 is inside block1', IsOverlapUnChecked(LPtr1, SizeUInt(30), LPtr2, SizeUInt(10)));
    AssertTrue('Case 4.2: Complete overlap, block1 is inside block2', IsOverlapUnChecked(LPtr2, SizeUInt(10), LPtr1, SizeUInt(30)));

    // Case 5: Identical blocks
    AssertTrue('Case 5.1: Identical blocks', IsOverlapUnChecked(LPtr1, SizeUInt(10), LPtr1, SizeUInt(10)));

    // Case 6: Overlap with a third block
    AssertTrue('Case 6.1: Overlap with a third block', IsOverlapUnChecked(LPtr1, SizeUInt(25), LPtr2, SizeUInt(10)));
    AssertFalse('Case 6.2: No overlap with a third block', IsOverlapUnChecked(LPtr1, SizeUInt(5), LPtr3, SizeUInt(10)));

    // Case 7: Edge cases with zero size
    AssertFalse('Case 7.1: Zero-size block1 should not overlap', IsOverlapUnChecked(LPtr1, SizeUInt(0), LPtr2, SizeUInt(10)));
    AssertFalse('Case 7.2: Zero-size block2 should not overlap', IsOverlapUnChecked(LPtr1, SizeUInt(10), LPtr2, SizeUInt(0)));
    AssertFalse('Case 7.3: Two zero-size blocks at the same address are not considered overlapping', IsOverlapUnChecked(LPtr1, SizeUInt(0), LPtr1, SizeUInt(0)));

  finally
    FreeMem(LMem);
  end;
end;

procedure TTestCase_mem_utils.Test_IsOverlap_2;
var
  LMem: Pointer;
  LPtr1, LPtr2: Pointer;
begin
  LMem := GetMem(100); // Allocate a 100-byte block for testing
  try
    LPtr1 := LMem;
    LPtr2 := PByte(LMem) + 50; // Place LPtr2 in the middle of LMem

    // Case 1: No overlap
    AssertFalse('Case 1: No overlap, block1 before block2', IsOverlap(LPtr1, LPtr2, 10));
    AssertFalse('Case 2: No overlap, block2 before block1', IsOverlap(LPtr2, LPtr1, 10));

    // Case 3: Partial overlap
    AssertTrue('Case 3: Partial overlap, block1 overlaps beginning of block2', IsOverlap(LPtr1, LPtr2, 60));
    AssertTrue('Case 4: Partial overlap, block2 overlaps beginning of block1', IsOverlap(LPtr2, LPtr1, 60));

    // Case 5: Complete overlap (one block inside another)
    AssertTrue('Case 5: Complete overlap, block2 is inside block1', IsOverlap(LPtr1, LPtr2, 100));
    AssertTrue('Case 6: Complete overlap, block1 is inside block2', IsOverlap(LPtr2, LPtr1, 100));

    // Case 7: Edge cases with zero size
    AssertFalse('Case 7: Zero-size block1 should not overlap', IsOverlap(LPtr1, LPtr2, 0));
    AssertFalse('Case 8: Zero-size block2 should not overlap', IsOverlap(LPtr1, LPtr2, 0));
    AssertFalse('Case 9: Two zero-size blocks at the same address are not considered overlapping', IsOverlap(LPtr1, LPtr1, 0));

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    { 异常测试: aSize 导致地址计算溢出 }
    AssertException(
      'Exception expected for aSize causing address calculation to overflow',
      EOutOfRange,
      procedure
      begin
        IsOverlap(LPtr1, LPtr2, High(PtrUInt));
      end);
    {$ENDIF}
  finally
    FreeMem(LMem);
  end;
end;

procedure TTestCase_mem_utils.Test_IsOverlapUnChecked_2;
var
  LMem: Pointer;
  LPtr1, LPtr2: Pointer;
begin
  LMem := GetMem(100); // Allocate a 100-byte block for testing
  try
    LPtr1 := LMem;
    LPtr2 := PByte(LMem) + 50; // Place LPtr2 in the middle of LMem

    // Case 1: No overlap
    AssertFalse('Case 1: No overlap, block1 before block2', IsOverlapUnChecked(LPtr1, LPtr2, 10));
    AssertFalse('Case 2: No overlap, block2 before block1', IsOverlapUnChecked(LPtr2, LPtr1, 10));

    // Case 3: Partial overlap
    AssertTrue('Case 3: Partial overlap, block1 overlaps beginning of block2', IsOverlapUnChecked(LPtr1, LPtr2, 60));
    AssertTrue('Case 4: Partial overlap, block2 overlaps beginning of block1', IsOverlapUnChecked(LPtr2, LPtr1, 60));

    // Case 5: Complete overlap (one block inside another)
    AssertTrue('Case 5: Complete overlap, block2 is inside block1', IsOverlapUnChecked(LPtr1, LPtr2, 100));
    AssertTrue('Case 6: Complete overlap, block1 is inside block2', IsOverlapUnChecked(LPtr2, LPtr1, 100));

    // Case 7: Edge cases with zero size
    AssertFalse('Case 7: Zero-size block1 should not overlap', IsOverlapUnChecked(LPtr1, LPtr2, 0));
    AssertFalse('Case 8: Zero-size block2 should not overlap', IsOverlapUnChecked(LPtr1, LPtr2, 0));
    AssertFalse('Case 9: Two zero-size blocks at the same address are not considered overlapping', IsOverlapUnChecked(LPtr1, LPtr1, 0));
  finally
    FreeMem(LMem);
  end;
end;

procedure TTestCase_mem_utils.Test_AlignUpUnChecked;
begin
  AssertTrue('AlignUpUnChecked(1001, 8) should be 1008', Pointer(1008) = AlignUpUnChecked(Pointer(1001), 8));
  AssertTrue('AlignUpUnChecked(1000, 8) should be 1000', Pointer(1000) = AlignUpUnChecked(Pointer(1000), 8));
  AssertTrue('AlignUpUnChecked(0, 8) should be 0', Pointer(0) = AlignUpUnChecked(Pointer(0), 8));
  AssertTrue('AlignUpUnChecked(1, 1) should be 1', Pointer(1) = AlignUpUnChecked(Pointer(1), 1));
  AssertTrue('AlignUpUnChecked(1, 2) should be 2', Pointer(2) = AlignUpUnChecked(Pointer(1), 2));
  AssertTrue('AlignUpUnChecked(1, 4) should be 4', Pointer(4) = AlignUpUnChecked(Pointer(1), 4));
  AssertTrue('AlignUpUnChecked(1, 16) should be 16', Pointer(16) = AlignUpUnChecked(Pointer(1), 16));
  AssertTrue('AlignUpUnChecked(15, 16) should be 16', Pointer(16) = AlignUpUnChecked(Pointer(15), 16));
  AssertTrue('AlignUpUnChecked(16, 16) should be 16', Pointer(16) = AlignUpUnChecked(Pointer(16), 16));
end;

procedure TTestCase_mem_utils.Test_AlignDown;
begin
  AssertTrue('AlignDown(1009, 8) should be 1008', Pointer(1008) = AlignDown(Pointer(1009), 8));
  AssertTrue('AlignDown(1000, 8) should be 1000', Pointer(1000) = AlignDown(Pointer(1000), 8));
  AssertTrue('AlignDownUnChecked(15, 8) should be 8', Pointer(8) = AlignDownUnChecked(Pointer(15), 8));
end;

procedure TTestCase_mem_utils.Test_AlignAndCopy_Exceptions;
begin
  // 非 2 的幂对齐：应抛 EInvalidArgument
  AssertException(EInvalidArgument, procedure begin AlignUp(Pointer(1), 3); end);

  // 超大 SizeBytes 导致溢出：IsOverlap/Copy 等在 utils 中已有断言覆盖
  // 这里补充 Copy 的溢出路径（仅在非 CRT 后端下有上限判断）
  {$IFNDEF FAFAFA_CORE_CRT_MEMMOVE}
  AssertException(EOutOfRange, procedure
  var P1, P2: Pointer; begin
    GetMem(P1, 16); GetMem(P2, 16);
    try
      Copy(P1, P2, MAX_SIZE_INT + 1);
    finally
      FreeMem(P1); FreeMem(P2);
    end;
  end);
  {$ENDIF}
end;

procedure TTestCase_mem_utils.Test_IsPowerOfTwo;
begin
  AssertTrue(IsPowerOfTwo(1));
  AssertTrue(IsPowerOfTwo(2));
  AssertTrue(IsPowerOfTwo(16));
  AssertFalse(IsPowerOfTwo(0));
  AssertFalse(IsPowerOfTwo(3));
  AssertFalse(IsPowerOfTwo(18));
end;

procedure TTestCase_mem_utils.Test_Unchecked_Aliases_Smoke;
var
  LMem1, LMem2: Pointer;
begin
  LMem1 := GetMem(8);
  LMem2 := GetMem(8);
  try
    // CopyUnchecked alias
    CopyUnchecked(LMem1, LMem2, 0);
    // Overlap alias
    AssertFalse(IsOverlapUnchecked(LMem1, 0, LMem2, 0));
    // AlignUpUnchecked alias
    AssertTrue(AlignUpUnchecked(Pointer(1), 2) = Pointer(2));
  finally
    FreeMem(LMem1);
    FreeMem(LMem2);
  end;
end;



initialization
  RegisterTest(TTestCase_mem_utils);
end.
