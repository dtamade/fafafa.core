{$CODEPAGE UTF8}
unit test_arena_growable;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.arena.growable,
  fafafa.core.mem.blockpool.concurrent,
  fafafa.core.mem.blockpool,
  fafafa.core.mem.layout,
  fafafa.core.mem.error;

type
  TTestCase_GrowingArena = class(TTestCase)
  published
    procedure Test_Create_Basic;
    procedure Test_Growth_Alloc;
    procedure Test_LargeAlloc_DoesNotExplodeGrowth;
    procedure Test_SaveMark_Restore_AcrossSegments;
    procedure Test_Alignment;
    procedure Test_Reset;
    procedure Test_RestoreToMark_OutOfRange_Raises;
    procedure Test_Concurrent_Wrappers_Basic;
  end;

implementation

{$PUSH}
{$WARN 4055 OFF} // pointer/ordinal conversions in tests

procedure TTestCase_GrowingArena.Test_Create_Basic;
var
  LArena: IArena;
begin
  LArena := TGrowingArena.Create(128);
  AssertTrue('TotalSize >= initial', LArena.TotalSize >= 128);
  AssertEquals('UsedSize=0', 0, LArena.UsedSize);
  AssertEquals('Remaining=Total', LArena.TotalSize, LArena.RemainingSize);
end;

procedure TTestCase_GrowingArena.Test_Growth_Alloc;
var
  LArena: IArena;
  LResult: TAllocResult;
  LTotal0: SizeUInt;
begin
  LArena := TGrowingArena.Create(128);
  LTotal0 := LArena.TotalSize;

  LResult := LArena.Alloc(TMemLayout.Create(100, 8));
  AssertTrue('Alloc in initial segment ok', LResult.IsOk);
  AssertNotNull('Ptr non-nil', LResult.Ptr);

  LResult := LArena.Alloc(TMemLayout.Create(200, 8));
  AssertTrue('Alloc triggers growth ok', LResult.IsOk);
  AssertNotNull('Ptr non-nil', LResult.Ptr);
  AssertTrue('TotalSize grew', LArena.TotalSize > LTotal0);
  AssertTrue('UsedSize >= old total', LArena.UsedSize >= LTotal0);
end;

procedure TTestCase_GrowingArena.Test_LargeAlloc_DoesNotExplodeGrowth;
var
  LConfig: TGrowingArenaConfig;
  LArena: TGrowingArena;
  LRes: TAllocResult;
  LTotal0: SizeUInt;
  LTotalAfterLarge: SizeUInt;
  LTotalAfterNext: SizeUInt;
  LLargeSize: SizeUInt;
begin
  LConfig := TGrowingArenaConfig.Default(64);
  LConfig.GrowthKind := agkGeometric;
  LConfig.GrowthFactor := 2.0;
  LConfig.KeepSegments := True;

  LArena := TGrowingArena.Create(LConfig);
  try
    LTotal0 := LArena.TotalSize;
    LRes := LArena.Alloc(TMemLayout.Create(32, 8));
    AssertTrue('small alloc ok', LRes.IsOk);

    LLargeSize := 1024 * 1024;
    LRes := LArena.Alloc(TMemLayout.Create(LLargeSize, 16));
    AssertTrue('large alloc ok', LRes.IsOk);

    LTotalAfterLarge := LArena.TotalSize;
    AssertTrue('TotalSize grew after large', LTotalAfterLarge > LTotal0);

    // force another segment allocation using a small request
    LRes := LArena.Alloc(TMemLayout.Create(32, 8));
    AssertTrue('alloc after large ok', LRes.IsOk);

    LTotalAfterNext := LArena.TotalSize;
    AssertTrue('TotalSize grew again', LTotalAfterNext > LTotalAfterLarge);
    AssertTrue('next segment stays small', (LTotalAfterNext - LTotalAfterLarge) <= 4096);
  finally
    LArena.Free;
  end;
end;

procedure TTestCase_GrowingArena.Test_SaveMark_Restore_AcrossSegments;
var
  LArena: IArena;
  LMark: TArenaMarker;
  LUsedBefore: SizeUInt;
  LUsedAfter: SizeUInt;
  LResult: TAllocResult;
begin
  LArena := TGrowingArena.Create(64);

  LResult := LArena.Alloc(TMemLayout.Create(32, 8));
  AssertTrue(LResult.IsOk);
  LMark := LArena.SaveMark;
  AssertTrue('Mark > 0', LMark > 0);

  // force growth
  LResult := LArena.Alloc(TMemLayout.Create(1024, 16));
  AssertTrue(LResult.IsOk);
  LUsedBefore := LArena.UsedSize;
  AssertTrue('Used increased', LUsedBefore > SizeUInt(LMark));

  LArena.RestoreToMark(LMark);
  LUsedAfter := LArena.UsedSize;
  AssertEquals('Used restored to mark', SizeUInt(LMark), LUsedAfter);

  LResult := LArena.Alloc(TMemLayout.Create(16, 8));
  AssertTrue('Alloc after restore ok', LResult.IsOk);
end;

procedure TTestCase_GrowingArena.Test_Alignment;
var
  LArena: IArena;
  LResult: TAllocResult;
begin
  LArena := TGrowingArena.Create(4096);

  LResult := LArena.Alloc(TMemLayout.Create(1, 64));
  AssertTrue(LResult.IsOk);
  AssertEquals('64-byte aligned', 0, PtrUInt(LResult.Ptr) mod 64);
end;

procedure TTestCase_GrowingArena.Test_Reset;
var
  LArena: IArena;
  LResult: TAllocResult;
begin
  LArena := TGrowingArena.Create(128);
  LResult := LArena.Alloc(TMemLayout.Create(64, 8));
  AssertTrue(LResult.IsOk);
  AssertTrue('Used > 0', LArena.UsedSize > 0);
  LArena.Reset;
  AssertEquals('Used=0 after reset', 0, LArena.UsedSize);
end;

procedure TTestCase_GrowingArena.Test_RestoreToMark_OutOfRange_Raises;
var
  LArena: IArena;
begin
  LArena := TGrowingArena.Create(128);
  AssertException(EAllocError, procedure begin LArena.RestoreToMark(TArenaMarker(LArena.TotalSize + 1)); end);
end;

procedure TTestCase_GrowingArena.Test_Concurrent_Wrappers_Basic;
var
  LPool: IBlockPool;
  LPoolC: IBlockPool;
  LArena: IArena;
  LArenaC: IArena;
  LP: Pointer;
  LRes: TAllocResult;
begin
  LPool := TBlockPool.Create(32, 4);
  LPoolC := TBlockPoolConcurrent.Create(LPool);
  LP := LPoolC.Acquire;
  AssertNotNull(LP);
  LPoolC.Release(LP);

  LArena := TGrowingArena.Create(256);
  LArenaC := TArenaConcurrent.Create(LArena);
  LRes := LArenaC.Alloc(TMemLayout.Create(32, 8));
  AssertTrue(LRes.IsOk);
  AssertNotNull(LRes.Ptr);
end;

initialization
  RegisterTest(TTestCase_GrowingArena);

{$POP}

end.
