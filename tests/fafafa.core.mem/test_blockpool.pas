{$CODEPAGE UTF8}
unit test_blockpool;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.blockpool,
  fafafa.core.mem.layout,
  fafafa.core.mem.error;

type
  TTestCase_BlockPool = class(TTestCase)
  published
    procedure Test_Create_Basic;
    procedure Test_Create_InvalidArgs;
    procedure Test_Acquire_Release_Basic;
    procedure Test_Exhaustion_TryAcquire;
    procedure Test_Release_InvalidPointer_Raises;
    procedure Test_Release_MisalignedPointer_Raises;
    procedure Test_DoubleFree_Raises;
    procedure Test_Reset_InvalidatesOldPointer;
    procedure Test_GetRange_Owns;
  end;

  TTestCase_Arena = class(TTestCase)
  published
    procedure Test_Create_InvalidSize;
    procedure Test_Alloc_InvalidLayout_ReturnsErr;
    procedure Test_Alloc_Alignment;
    procedure Test_Alloc_Exhaustion;
    procedure Test_SaveMark_Restore;
    procedure Test_AllocZeroed;
    procedure Test_RestoreToMark_OutOfRange_Raises;
  end;

implementation

{$PUSH}
{$WARN 4055 OFF} // pointer/ordinal conversions in tests

procedure TTestCase_BlockPool.Test_Create_Basic;
var
  LPool: IBlockPool;
begin
  LPool := TBlockPool.Create(64, 10);
  AssertEquals('BlockSize', 64, LPool.BlockSize);
  AssertEquals('Capacity', 10, LPool.Capacity);
  AssertEquals('Available', 10, LPool.Available);
  AssertEquals('InUse', 0, LPool.InUse);
end;

procedure TTestCase_BlockPool.Test_Create_InvalidArgs;
begin
  AssertException(EAllocError, procedure begin TBlockPool.Create(0, 1).Free; end);
  AssertException(EAllocError, procedure begin TBlockPool.Create(8, 0).Free; end);
  AssertException(EAllocError, procedure begin TBlockPool.Create(8, 1, 3).Free; end);
end;

procedure TTestCase_BlockPool.Test_Acquire_Release_Basic;
var
  LPool: IBlockPool;
  LP1, LP2: Pointer;
begin
  LPool := TBlockPool.Create(64, 4);

  LP1 := LPool.Acquire;
  AssertNotNull('Acquire 1', LP1);
  AssertEquals('Available after 1', 3, LPool.Available);
  AssertEquals('InUse after 1', 1, LPool.InUse);
  AssertEquals('Default alignment (>=16)', 0, PtrUInt(LP1) mod DEFAULT_ALIGNMENT);

  LPool.Release(LP1);
  AssertEquals('Available after release', 4, LPool.Available);

  // LIFO reuse
  LP2 := LPool.Acquire;
  AssertNotNull('Re-acquire', LP2);
  AssertEquals('Reuse same ptr', PtrUInt(LP1), PtrUInt(LP2));
  LPool.Release(LP2);
end;

procedure TTestCase_BlockPool.Test_Exhaustion_TryAcquire;
var
  LPool: IBlockPool;
  LPtrs: array[0..9] of Pointer;
  LIdx: Integer;
  LP: Pointer;
begin
  LPool := TBlockPool.Create(32, 10);

  for LIdx := 0 to High(LPtrs) do
  begin
    LPtrs[LIdx] := LPool.Acquire;
    AssertNotNull('Acquire ' + IntToStr(LIdx), LPtrs[LIdx]);
  end;
  AssertEquals('Available exhausted', 0, LPool.Available);

  LP := LPool.Acquire;
  AssertNull('Acquire when exhausted returns nil', LP);

  LP := Pointer(PtrUInt(1));
  AssertFalse('TryAcquire returns False when exhausted', LPool.TryAcquire(LP));
  AssertNull('TryAcquire sets out ptr to nil', LP);

  for LIdx := 0 to High(LPtrs) do
    LPool.Release(LPtrs[LIdx]);
end;

procedure TTestCase_BlockPool.Test_Release_InvalidPointer_Raises;
var
  LPool: IBlockPool;
  LBad: Pointer;
begin
  LPool := TBlockPool.Create(32, 4);
  GetMem(LBad, 32);
  try
    try
      LPool.Release(LBad);
      Fail('Expected EAllocError');
    except
      on E: EAllocError do
        AssertEquals('Error=aeInvalidPointer', Ord(aeInvalidPointer), Ord(E.Error));
    end;
  finally
    FreeMem(LBad);
  end;
end;

procedure TTestCase_BlockPool.Test_Release_MisalignedPointer_Raises;
var
  LPool: IBlockPool;
  LP: Pointer;
begin
  LPool := TBlockPool.Create(32, 4);
  LP := LPool.Acquire;
  AssertNotNull(LP);
  try
    try
      LPool.Release(Pointer(PtrUInt(LP) + 1));
      Fail('Expected EAllocError');
    except
      on E: EAllocError do
        AssertEquals('Error=aeInvalidPointer', Ord(aeInvalidPointer), Ord(E.Error));
    end;
  finally
    LPool.Release(LP);
  end;
end;

procedure TTestCase_BlockPool.Test_DoubleFree_Raises;
var
  LPool: IBlockPool;
  LP: Pointer;
begin
  LPool := TBlockPool.Create(32, 4);
  LP := LPool.Acquire;
  AssertNotNull(LP);
  LPool.Release(LP);
  try
    LPool.Release(LP);
    Fail('Expected double free');
  except
    on E: EAllocError do
      AssertEquals('Error=aeDoubleFree', Ord(aeDoubleFree), Ord(E.Error));
  end;
end;

procedure TTestCase_BlockPool.Test_Reset_InvalidatesOldPointer;
var
  LPool: IBlockPool;
  LP: Pointer;
begin
  LPool := TBlockPool.Create(32, 4);
  LP := LPool.Acquire;
  AssertNotNull(LP);
  LPool.Reset;
  try
    LPool.Release(LP);
    Fail('Expected release-after-reset to fail');
  except
    on E: EAllocError do
      AssertEquals('Error=aeDoubleFree', Ord(aeDoubleFree), Ord(E.Error));
  end;
end;

procedure TTestCase_BlockPool.Test_GetRange_Owns;
var
  LPool: TBlockPool;
  LBase: Pointer;
  LSize: SizeUInt;
  LP: Pointer;
begin
  LPool := TBlockPool.Create(64, 4);
  try
    LPool.GetRange(LBase, LSize);
    AssertNotNull('Range base', LBase);
    AssertEquals('Range size', SizeUInt(64 * 4), LSize);

    LP := LPool.Acquire;
    try
      AssertTrue('Owns allocated ptr', LPool.Owns(LP));
      AssertTrue('Owns base', LPool.Owns(LBase));
      AssertFalse('Owns end', LPool.Owns(Pointer(PtrUInt(LBase) + PtrUInt(LSize))));
      if PtrUInt(LBase) > 0 then
        AssertFalse('Owns before base', LPool.Owns(Pointer(PtrUInt(LBase) - 1)));
    finally
      LPool.Release(LP);
    end;
  finally
    LPool.Free;
  end;
end;

procedure TTestCase_Arena.Test_Create_InvalidSize;
begin
  AssertException(EAllocError, procedure begin TArena.Create(0).Free; end);
end;

procedure TTestCase_Arena.Test_Alloc_InvalidLayout_ReturnsErr;
var
  LArena: IArena;
  LBad: TMemLayout;
  LResult: TAllocResult;
begin
  LArena := TArena.Create(256);
  AssertFalse('TryCreate should fail for huge alignment',
    TMemLayout.TryCreate(1, High(SizeUInt), LBad));
  LResult := LArena.Alloc(LBad);
  AssertTrue('Alloc returns Err', LResult.IsErr);
  AssertEquals('Error=aeInvalidLayout', Ord(aeInvalidLayout), Ord(LResult.Error));
end;

procedure TTestCase_Arena.Test_Alloc_Alignment;
var
  LArena: IArena;
  LResult: TAllocResult;
begin
  LArena := TArena.Create(4096);
  LResult := LArena.Alloc(TMemLayout.Create(100, 16));
  AssertTrue(LResult.IsOk);
  AssertEquals('16-byte aligned', 0, PtrUInt(LResult.Ptr) mod 16);

  LResult := LArena.Alloc(TMemLayout.Create(200, 64));
  AssertTrue(LResult.IsOk);
  AssertEquals('64-byte aligned', 0, PtrUInt(LResult.Ptr) mod 64);
end;

procedure TTestCase_Arena.Test_Alloc_Exhaustion;
var
  LArena: IArena;
  LResult: TAllocResult;
begin
  LArena := TArena.Create(128);
  LResult := LArena.Alloc(TMemLayout.Create(120, 8));
  AssertTrue(LResult.IsOk);

  LResult := LArena.Alloc(TMemLayout.Create(16, 8));
  AssertTrue(LResult.IsErr);
  AssertEquals('Error=aeOutOfMemory', Ord(aeOutOfMemory), Ord(LResult.Error));
end;

procedure TTestCase_Arena.Test_SaveMark_Restore;
var
  LArena: IArena;
  LResult: TAllocResult;
  LMark: TArenaMarker;
  LUsedBefore: SizeUInt;
begin
  LArena := TArena.Create(512);

  LResult := LArena.Alloc(TMemLayout.Create(64, 8));
  AssertTrue(LResult.IsOk);

  LMark := LArena.SaveMark;
  AssertTrue('Mark > 0', LMark > 0);

  LResult := LArena.Alloc(TMemLayout.Create(128, 8));
  AssertTrue(LResult.IsOk);
  LUsedBefore := LArena.UsedSize;

  LArena.RestoreToMark(LMark);
  AssertTrue('Used reduced after restore', LArena.UsedSize < LUsedBefore);

  LResult := LArena.Alloc(TMemLayout.Create(16, 8));
  AssertTrue(LResult.IsOk);
end;

procedure TTestCase_Arena.Test_AllocZeroed;
var
  LArena: IArena;
  LResult: TAllocResult;
  LIdx: Integer;
  LAllZero: Boolean;
begin
  LArena := TArena.Create(256);
  LResult := LArena.AllocZeroed(TMemLayout.Create(64, 8));
  AssertTrue(LResult.IsOk);
  AssertNotNull(LResult.Ptr);

  LAllZero := True;
  for LIdx := 0 to 63 do
    if PByte(LResult.Ptr)[LIdx] <> 0 then
    begin
      LAllZero := False;
      Break;
    end;
  AssertTrue('All bytes are zero', LAllZero);
end;

procedure TTestCase_Arena.Test_RestoreToMark_OutOfRange_Raises;
var
  LArena: IArena;
begin
  LArena := TArena.Create(256);
  AssertException(EAllocError,
    procedure begin LArena.RestoreToMark(TArenaMarker(LArena.TotalSize + 1)); end);
end;

initialization
  RegisterTest(TTestCase_BlockPool);
  RegisterTest(TTestCase_Arena);

{$POP}

end.
