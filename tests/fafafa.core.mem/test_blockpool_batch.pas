{$CODEPAGE UTF8}
unit test_blockpool_batch;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.blockpool,
  fafafa.core.mem.blockpool.growable,
  fafafa.core.mem.blockpool.sharded;

type
  TTestCase_BlockPoolBatch = class(TTestCase)
  published
    procedure Test_BlockPool_AcquireN_ReleaseN;
    procedure Test_GrowingBlockPool_AcquireN_ReleaseN;
    procedure Test_ShardedBlockPool_AcquireN_ReleaseN;
  end;

implementation

procedure TTestCase_BlockPoolBatch.Test_BlockPool_AcquireN_ReleaseN;
var
  LPool: IBlockPoolBatch;
  LPtrs: array[0..15] of Pointer;
  LCount: Integer;
  LIdx: Integer;
begin
  LPool := TBlockPool.Create(32, Length(LPtrs)) as IBlockPoolBatch;

  LCount := LPool.AcquireN(LPtrs, Length(LPtrs));
  AssertEquals('AcquireN count', Length(LPtrs), LCount);
  AssertEquals('InUse', SizeUInt(LCount), LPool.InUse);
  for LIdx := 0 to LCount - 1 do
    AssertNotNull('Ptr ' + IntToStr(LIdx), LPtrs[LIdx]);

  LPool.ReleaseN(LPtrs, LCount);
  AssertEquals('InUse after ReleaseN', 0, LPool.InUse);
  AssertEquals('Available restored', LPool.Capacity, LPool.Available);
end;

procedure TTestCase_BlockPoolBatch.Test_GrowingBlockPool_AcquireN_ReleaseN;
var
  LPool: IBlockPoolBatch;
  LPtrs: array[0..31] of Pointer;
  LCount: Integer;
  LIdx: Integer;
begin
  LPool := TGrowingBlockPool.Create(32, 2) as IBlockPoolBatch;

  LCount := LPool.AcquireN(LPtrs, Length(LPtrs));
  AssertEquals('AcquireN count', Length(LPtrs), LCount);
  AssertEquals('InUse', SizeUInt(LCount), LPool.InUse);
  AssertTrue('Capacity grew', LPool.Capacity >= SizeUInt(LCount));
  for LIdx := 0 to LCount - 1 do
    AssertNotNull('Ptr ' + IntToStr(LIdx), LPtrs[LIdx]);

  LPool.ReleaseN(LPtrs, LCount);
  AssertEquals('InUse after ReleaseN', 0, LPool.InUse);
end;

procedure TTestCase_BlockPoolBatch.Test_ShardedBlockPool_AcquireN_ReleaseN;
var
  LPool: IBlockPoolBatch;
  LPtrs: array[0..31] of Pointer;
  LCount: Integer;
  LIdx: Integer;
begin
  LPool := TShardedBlockPool.Create(64, 8, 4) as IBlockPoolBatch;

  LCount := LPool.AcquireN(LPtrs, Length(LPtrs));
  AssertEquals('AcquireN count', Length(LPtrs), LCount);
  AssertEquals('InUse', SizeUInt(LCount), LPool.InUse);
  AssertTrue('Capacity grew', LPool.Capacity >= SizeUInt(LCount));
  for LIdx := 0 to LCount - 1 do
    AssertNotNull('Ptr ' + IntToStr(LIdx), LPtrs[LIdx]);

  LPool.ReleaseN(LPtrs, LCount);
  AssertEquals('InUse after ReleaseN', 0, LPool.InUse);
end;

initialization
  RegisterTest(TTestCase_BlockPoolBatch);

end.

