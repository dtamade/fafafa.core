{$CODEPAGE UTF8}
unit test_blockpool_growable;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.blockpool.growable,
  fafafa.core.mem.blockpool,
  fafafa.core.mem.error;

type
  TTestCase_GrowingBlockPool = class(TTestCase)
  published
    procedure Test_Create_Basic;
    procedure Test_Growth_Acquire;
    procedure Test_Alignment;
    procedure Test_Release_InvalidPointer_Raises;
    procedure Test_DoubleFree_Raises;
    procedure Test_Reset_InvalidatesOldPointer;
  end;

implementation

{$PUSH}
{$WARN 4055 OFF} // pointer/ordinal conversions in tests

procedure TTestCase_GrowingBlockPool.Test_Create_Basic;
var
  LPool: IBlockPool;
begin
  LPool := TGrowingBlockPool.Create(64, 8);
  AssertEquals('BlockSize', 64, LPool.BlockSize);
  AssertTrue('Capacity >= initial', LPool.Capacity >= 8);
  AssertEquals('InUse', 0, LPool.InUse);
  AssertEquals('Available', LPool.Capacity, LPool.Available);
end;

procedure TTestCase_GrowingBlockPool.Test_Growth_Acquire;
var
  LPool: IBlockPool;
  LPtrs: array[0..31] of Pointer;
  LIdx: Integer;
begin
  LPool := TGrowingBlockPool.Create(32, 2);
  for LIdx := 0 to High(LPtrs) do
  begin
    LPtrs[LIdx] := LPool.Acquire;
    AssertNotNull('Acquire ' + IntToStr(LIdx), LPtrs[LIdx]);
  end;
  AssertTrue('Capacity grew', LPool.Capacity >= SizeUInt(Length(LPtrs)));
  AssertEquals('InUse count', SizeUInt(Length(LPtrs)), LPool.InUse);
  AssertEquals('Available = cap - inuse', LPool.Capacity - LPool.InUse, LPool.Available);

  for LIdx := 0 to High(LPtrs) do
    LPool.Release(LPtrs[LIdx]);
  AssertEquals('InUse after release all', 0, LPool.InUse);
end;

procedure TTestCase_GrowingBlockPool.Test_Alignment;
var
  LPool: IBlockPool;
  LPtr: Pointer;
begin
  LPool := TGrowingBlockPool.Create(64, 4, 64);
  LPtr := LPool.Acquire;
  AssertNotNull(LPtr);
  try
    AssertEquals('64-byte aligned', 0, PtrUInt(LPtr) mod 64);
  finally
    LPool.Release(LPtr);
  end;
end;

procedure TTestCase_GrowingBlockPool.Test_Release_InvalidPointer_Raises;
var
  LPool: IBlockPool;
  LBad: Pointer;
begin
  LPool := TGrowingBlockPool.Create(32, 4);
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

procedure TTestCase_GrowingBlockPool.Test_DoubleFree_Raises;
var
  LPool: IBlockPool;
  LPtr: Pointer;
begin
  LPool := TGrowingBlockPool.Create(32, 4);
  LPtr := LPool.Acquire;
  AssertNotNull(LPtr);
  LPool.Release(LPtr);
  try
    LPool.Release(LPtr);
    Fail('Expected double free');
  except
    on E: EAllocError do
      AssertEquals('Error=aeDoubleFree', Ord(aeDoubleFree), Ord(E.Error));
  end;
end;

procedure TTestCase_GrowingBlockPool.Test_Reset_InvalidatesOldPointer;
var
  LPool: IBlockPool;
  LPtr: Pointer;
begin
  LPool := TGrowingBlockPool.Create(32, 4);
  LPtr := LPool.Acquire;
  AssertNotNull(LPtr);
  LPool.Reset;
  try
    LPool.Release(LPtr);
    Fail('Expected release-after-reset to fail');
  except
    on E: EAllocError do
      AssertEquals('Error=aeDoubleFree', Ord(aeDoubleFree), Ord(E.Error));
  end;
end;

initialization
  RegisterTest(TTestCase_GrowingBlockPool);

{$POP}

end.
