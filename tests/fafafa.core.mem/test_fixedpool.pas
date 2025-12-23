{$CODEPAGE UTF8}
unit test_fixedpool;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.mem.pool.base,
  fafafa.core.mem.pool.fixed;

type
  TTestCase_FixedPool = class(TTestCase)
  published
    // 基本功能测试
    procedure Test_Create_Basic;
    procedure Test_Create_WithAlignment;
    procedure Test_Create_InvalidBlockSize;
    procedure Test_Create_InvalidCapacity;

    // 分配与释放测试
    procedure Test_Alloc_Basic;
    procedure Test_Alloc_TillFull;
    procedure Test_Alloc_Reuse;
    procedure Test_TryAlloc;
    procedure Test_Release_Nil;

    // 边界与错误测试
    procedure Test_Release_InvalidPointer;
    procedure Test_Release_DoubleFree;
    procedure Test_Owns;

    // 批量操作测试
    procedure Test_AcquireN;
    procedure Test_ReleaseN;
    procedure Test_Reset;

    // 统计测试
    procedure Test_Statistics;

    // IPool 接口测试
    procedure Test_IPool_Interface;
  end;

implementation

procedure TTestCase_FixedPool.Test_Create_Basic;
var
  Pool: TFixedPool;
begin
  Pool := TFixedPool.Create(64, 10);
  try
    AssertEquals('BlockSize', 64, Pool.BlockSize);
    AssertEquals('Capacity', 10, Pool.Capacity);
    AssertEquals('AllocatedCount initial', 0, Pool.AllocatedCount);
    AssertEquals('Available initial', 10, Pool.Available);
    AssertTrue('Alignment >= 16', Pool.Alignment >= 16);
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_FixedPool.Test_Create_WithAlignment;
var
  Pool: TFixedPool;
begin
  Pool := TFixedPool.Create(128, 5, 64);
  try
    AssertEquals('BlockSize', 128, Pool.BlockSize);
    AssertEquals('Alignment', 64, Pool.Alignment);
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_FixedPool.Test_Create_InvalidBlockSize;
begin
  AssertException(EMemFixedPoolError,
    procedure begin TFixedPool.Create(0, 10).Free; end);
end;

procedure TTestCase_FixedPool.Test_Create_InvalidCapacity;
begin
  AssertException(EMemFixedPoolError,
    procedure begin TFixedPool.Create(64, 0).Free; end);
  AssertException(EMemFixedPoolError,
    procedure begin TFixedPool.Create(64, -1).Free; end);
end;

procedure TTestCase_FixedPool.Test_Alloc_Basic;
var
  Pool: TFixedPool;
  P: Pointer;
begin
  Pool := TFixedPool.Create(64, 10);
  try
    P := Pool.Alloc;
    AssertTrue('Alloc returns non-nil', P <> nil);
    AssertEquals('AllocatedCount after alloc', 1, Pool.AllocatedCount);
    AssertEquals('Available after alloc', 9, Pool.Available);

    // 检查对齐
    AssertEquals('Pointer alignment', 0, PtrUInt(P) mod Pool.Alignment);

    Pool.ReleasePtr(P);
    AssertEquals('AllocatedCount after release', 0, Pool.AllocatedCount);
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_FixedPool.Test_Alloc_TillFull;
var
  Pool: TFixedPool;
  Ptrs: array[0..9] of Pointer;
  I: Integer;
  P: Pointer;
begin
  Pool := TFixedPool.Create(64, 10);
  try
    // 分配所有块
    for I := 0 to 9 do
    begin
      Ptrs[I] := Pool.Alloc;
      AssertTrue('Alloc ' + IntToStr(I), Ptrs[I] <> nil);
    end;

    AssertEquals('Pool full', 0, Pool.Available);

    // 再分配应返回 nil
    P := Pool.Alloc;
    AssertTrue('Alloc when full returns nil', P = nil);

    // 释放所有
    for I := 0 to 9 do
      Pool.ReleasePtr(Ptrs[I]);

    AssertEquals('All released', 10, Pool.Available);
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_FixedPool.Test_Alloc_Reuse;
var
  Pool: TFixedPool;
  P1, P2: Pointer;
begin
  Pool := TFixedPool.Create(64, 2);
  try
    P1 := Pool.Alloc;
    Pool.ReleasePtr(P1);
    P2 := Pool.Alloc;

    // 释放后再分配应该重用同一块内存
    AssertEquals('Memory reuse', PtrUInt(P1), PtrUInt(P2));

    Pool.ReleasePtr(P2);
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_FixedPool.Test_TryAlloc;
var
  Pool: TFixedPool;
  P: Pointer;
  OK: Boolean;
begin
  Pool := TFixedPool.Create(64, 1);
  try
    OK := Pool.TryAlloc(P);
    AssertTrue('First TryAlloc succeeds', OK);
    AssertTrue('First TryAlloc non-nil', P <> nil);

    OK := Pool.TryAlloc(P);
    AssertFalse('Second TryAlloc fails (pool full)', OK);

    Pool.Reset;
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_FixedPool.Test_Release_Nil;
var
  Pool: TFixedPool;
begin
  Pool := TFixedPool.Create(64, 10);
  try
    // Release(nil) 应该是 no-op，不抛异常
    Pool.ReleasePtr(nil);
    AssertEquals('Release nil is no-op', 0, Pool.AllocatedCount);
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_FixedPool.Test_Release_InvalidPointer;
var
  Pool: TFixedPool;
  InvalidPtr: Pointer;
begin
  Pool := TFixedPool.Create(64, 10);
  try
    GetMem(InvalidPtr, 64);
    try
      AssertException(EMemFixedPoolInvalidPointer,
        procedure begin Pool.ReleasePtr(InvalidPtr); end);
    finally
      FreeMem(InvalidPtr);
    end;
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_FixedPool.Test_Release_DoubleFree;
var
  Pool: TFixedPool;
  P: Pointer;
begin
  Pool := TFixedPool.Create(64, 10);
  try
    P := Pool.Alloc;
    Pool.ReleasePtr(P);

    AssertException(EMemFixedPoolDoubleFree,
      procedure begin Pool.ReleasePtr(P); end);
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_FixedPool.Test_Owns;
var
  Pool: TFixedPool;
  P, External: Pointer;
begin
  Pool := TFixedPool.Create(64, 10);
  try
    P := Pool.Alloc;
    AssertTrue('Owns allocated pointer', Pool.Owns(P));

    GetMem(External, 64);
    try
      AssertFalse('Does not own external pointer', Pool.Owns(External));
    finally
      FreeMem(External);
    end;

    AssertFalse('Does not own nil', Pool.Owns(nil));

    Pool.ReleasePtr(P);
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_FixedPool.Test_AcquireN;
var
  Pool: TFixedPool;
  Ptrs: array[0..9] of Pointer;
  Count: Integer;
begin
  Pool := TFixedPool.Create(64, 10);
  try
    Count := Pool.AcquireN(Ptrs, 5);
    AssertEquals('AcquireN returns count', 5, Count);
    AssertEquals('AllocatedCount', 5, Pool.AllocatedCount);

    Pool.ReleaseN(Ptrs, 5);
    AssertEquals('After ReleaseN', 0, Pool.AllocatedCount);
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_FixedPool.Test_ReleaseN;
var
  Pool: TFixedPool;
  Ptrs: array[0..2] of Pointer;
  I: Integer;
begin
  Pool := TFixedPool.Create(64, 10);
  try
    for I := 0 to 2 do
      Ptrs[I] := Pool.Alloc;

    AssertEquals('Before ReleaseN', 3, Pool.AllocatedCount);

    Pool.ReleaseN(Ptrs, 3);
    AssertEquals('After ReleaseN', 0, Pool.AllocatedCount);
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_FixedPool.Test_Reset;
var
  Pool: TFixedPool;
  P: Pointer;
begin
  Pool := TFixedPool.Create(64, 10);
  try
    P := Pool.Alloc;
    P := Pool.Alloc;
    P := Pool.Alloc;
    AssertEquals('Before reset', 3, Pool.AllocatedCount);

    Pool.Reset;
    AssertEquals('After reset AllocatedCount', 0, Pool.AllocatedCount);
    AssertEquals('After reset Available', 10, Pool.Available);
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_FixedPool.Test_Statistics;
var
  Pool: TFixedPool;
  P: Pointer;
begin
  Pool := TFixedPool.Create(64, 10);
  try
    AssertEquals('Initial TotalAllocCalls', 0, Pool.TotalAllocCalls);
    AssertEquals('Initial TotalFreeCalls', 0, Pool.TotalFreeCalls);
    AssertEquals('Initial PeakAllocated', 0, Pool.PeakAllocated);

    P := Pool.Alloc;
    AssertEquals('After alloc TotalAllocCalls', 1, Pool.TotalAllocCalls);
    AssertEquals('PeakAllocated', 1, Pool.PeakAllocated);

    Pool.ReleasePtr(P);
    AssertEquals('After release TotalFreeCalls', 1, Pool.TotalFreeCalls);
    AssertEquals('PeakAllocated unchanged', 1, Pool.PeakAllocated);
  finally
    Pool.Free;
  end;
end;

procedure TTestCase_FixedPool.Test_IPool_Interface;
var
  Pool: IPool;
  P: Pointer;
  OK: Boolean;
begin
  Pool := TFixedPool.Create(64, 10);

  OK := Pool.Acquire(P);
  AssertTrue('IPool.Acquire succeeds', OK);
  AssertTrue('IPool.Acquire non-nil', P <> nil);

  Pool.Release(P);
  // IPool 是接口，会自动释放
end;

initialization
  RegisterTest(TTestCase_FixedPool);

end.
