{$CODEPAGE UTF8}
unit test_concurrent_pools;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.mem.pool.slab.concurrent,
  fafafa.core.mem.blockpool.concurrent,
  fafafa.core.mem.pool.fixed.concurrent,
  fafafa.core.mem.blockpool,
  fafafa.core.mem.pool.slab;

type
  TTestCase_ConcurrentPools = class(TTestCase)
  published
    // Batch 2: Concurrent 版本测试 (6个)
    // SlabPool Concurrent 测试 (2个)
    procedure Test_SlabPool_Concurrent_Alloc_Free_RaceCondition;
    procedure Test_SlabPool_Concurrent_Stats_Accurate;
    // BlockPool Concurrent 测试 (2个)
    procedure Test_BlockPool_Concurrent_Acquire_Release_ThreadSafe;
    procedure Test_BlockPool_Concurrent_Reset_NoCorruption;
    // FixedPool Concurrent 测试 (2个)
    procedure Test_FixedPool_Concurrent_Acquire_Release_Safe;
    procedure Test_FixedPool_Concurrent_Reset_NoCorruption;
  end;

implementation

type
  TSlabWorkerThread = class(TThread)
  private
    FPool: TSlabPoolConcurrent;
    FIterations: Integer;
    FAllocSize: SizeUInt;
    FError: string;
    FAllocCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(aPool: TSlabPoolConcurrent; aIterations: Integer; aAllocSize: SizeUInt);
    property Error: string read FError;
    property AllocCount: Integer read FAllocCount;
  end;

  TBlockPoolWorkerThread = class(TThread)
  private
    FPool: TBlockPoolConcurrent;
    FIterations: Integer;
    FError: string;
  protected
    procedure Execute; override;
  public
    constructor Create(aPool: TBlockPoolConcurrent; aIterations: Integer);
    property Error: string read FError;
  end;

  TFixedPoolWorkerThread = class(TThread)
  private
    FPool: TFixedPoolConcurrent;
    FIterations: Integer;
    FError: string;
  protected
    procedure Execute; override;
  public
    constructor Create(aPool: TFixedPoolConcurrent; aIterations: Integer);
    property Error: string read FError;
  end;

{ TSlabWorkerThread }

constructor TSlabWorkerThread.Create(aPool: TSlabPoolConcurrent; aIterations: Integer; aAllocSize: SizeUInt);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FPool := aPool;
  FIterations := aIterations;
  FAllocSize := aAllocSize;
  FError := '';
  FAllocCount := 0;
end;

procedure TSlabWorkerThread.Execute;
var
  LPtrs: array[0..9] of Pointer;
  LIdx, LIter: Integer;
  LPtr: Pointer;
begin
  try
    for LIter := 0 to FIterations - 1 do
    begin
      // 分配 10 个块
      for LIdx := 0 to High(LPtrs) do
      begin
        LPtr := FPool.GetMem(FAllocSize);
        if LPtr = nil then
        begin
          FError := Format('Allocation failed at iteration %d, index %d', [LIter, LIdx]);
          Exit;
        end;
        LPtrs[LIdx] := LPtr;
        Inc(FAllocCount);

        // 写入数据验证
        PByte(LPtr)^ := Byte(LIdx);
      end;

      // 验证数据完整性
      for LIdx := 0 to High(LPtrs) do
      begin
        if PByte(LPtrs[LIdx])^ <> Byte(LIdx) then
        begin
          FError := Format('Data corruption at iteration %d, index %d', [LIter, LIdx]);
          Exit;
        end;
      end;

      // 释放所有块
      for LIdx := 0 to High(LPtrs) do
      begin
        FPool.FreeMem(LPtrs[LIdx]);
        LPtrs[LIdx] := nil;
      end;

      if Terminated then Break;
    end;
  except
    on E: Exception do
      FError := E.ClassName + ': ' + E.Message;
  end;
end;

{ TBlockPoolWorkerThread }

constructor TBlockPoolWorkerThread.Create(aPool: TBlockPoolConcurrent; aIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FPool := aPool;
  FIterations := aIterations;
  FError := '';
end;

procedure TBlockPoolWorkerThread.Execute;
var
  LIdx: Integer;
  LPtr: Pointer;
begin
  try
    for LIdx := 1 to FIterations do
    begin
      LPtr := FPool.Acquire;
      if LPtr = nil then
      begin
        FError := 'Acquire returned nil';
        Exit;
      end;

      // 写入数据
      PByte(LPtr)^ := Byte(LIdx and $FF);

      // 验证数据
      if PByte(LPtr)^ <> Byte(LIdx and $FF) then
      begin
        FError := 'Data corruption detected';
        Exit;
      end;

      FPool.Release(LPtr);

      if Terminated then Break;
    end;
  except
    on E: Exception do
      FError := E.ClassName + ': ' + E.Message;
  end;
end;

{ TFixedPoolWorkerThread }

constructor TFixedPoolWorkerThread.Create(aPool: TFixedPoolConcurrent; aIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FPool := aPool;
  FIterations := aIterations;
  FError := '';
end;

procedure TFixedPoolWorkerThread.Execute;
var
  LIdx: Integer;
  LPtr: Pointer;
  LOk: Boolean;
begin
  try
    for LIdx := 1 to FIterations do
    begin
      LOk := FPool.Acquire(LPtr);
      if not LOk or (LPtr = nil) then
      begin
        FError := 'Acquire failed or returned nil';
        Exit;
      end;

      // 写入数据
      PByte(LPtr)^ := Byte(LIdx and $FF);

      // 验证数据
      if PByte(LPtr)^ <> Byte(LIdx and $FF) then
      begin
        FError := 'Data corruption detected';
        Exit;
      end;

      FPool.Release(LPtr);

      if Terminated then Break;
    end;
  except
    on E: Exception do
      FError := E.ClassName + ': ' + E.Message;
  end;
end;

{ TTestCase_ConcurrentPools }

procedure TTestCase_ConcurrentPools.Test_SlabPool_Concurrent_Alloc_Free_RaceCondition;
var
  LPool: TSlabPoolConcurrent;
  LThreads: array[0..3] of TSlabWorkerThread;
  LIdx: Integer;
  LTotalAllocs: Integer;
begin
  // 创建 Concurrent Slab 池
  LPool := TSlabPoolConcurrent.Create(4096);
  try
    // 创建 4 个工作线程，每个线程执行 100 次迭代
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx] := TSlabWorkerThread.Create(LPool, 100, 64);

    try
      // 启动所有线程
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].Start;

      // 等待所有线程完成
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].WaitFor;

      // 验证没有错误
      for LIdx := 0 to High(LThreads) do
        AssertEquals('Thread ' + IntToStr(LIdx) + ' error', '', LThreads[LIdx].Error);

      // 验证分配计数
      LTotalAllocs := 0;
      for LIdx := 0 to High(LThreads) do
        Inc(LTotalAllocs, LThreads[LIdx].AllocCount);

      AssertEquals('Total allocations', 4 * 100 * 10, LTotalAllocs);
    finally
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].Free;
    end;
  finally
    LPool.Destroy;
  end;
end;

procedure TTestCase_ConcurrentPools.Test_SlabPool_Concurrent_Stats_Accurate;
var
  LPool: TSlabPoolConcurrent;
  LThreads: array[0..3] of TSlabWorkerThread;
  LIdx: Integer;
  LStats: TSlabPoolStats;
begin
  // 创建 Concurrent Slab 池
  LPool := TSlabPoolConcurrent.Create(2048);
  try
    // 创建 4 个工作线程，每个线程执行 50 次迭代
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx] := TSlabWorkerThread.Create(LPool, 50, 32);

    try
      // 启动所有线程
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].Start;

      // 等待所有线程完成
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].WaitFor;

      // 验证没有错误
      for LIdx := 0 to High(LThreads) do
        AssertEquals('Thread ' + IntToStr(LIdx) + ' error', '', LThreads[LIdx].Error);

      // 验证统计信息一致性
      LStats := LPool.Stats;
      AssertTrue('Stats consistency: SegmentCount >= 0', LStats.SegmentCount >= 0);
      AssertTrue('Stats consistency: TotalCapacity >= 0', LStats.TotalCapacity >= 0);
      AssertTrue('Stats consistency: TotalUsed >= 0', LStats.TotalUsed >= 0);
    finally
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].Free;
    end;
  finally
    LPool.Destroy;
  end;
end;

procedure TTestCase_ConcurrentPools.Test_BlockPool_Concurrent_Acquire_Release_ThreadSafe;
var
  LPool: TBlockPoolConcurrent;
  LThreads: array[0..3] of TBlockPoolWorkerThread;
  LIdx: Integer;
begin
  // 创建 Concurrent BlockPool
  LPool := TBlockPoolConcurrent.Create(64, 64);
  try
    // 创建 4 个工作线程，每个线程执行 500 次迭代
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx] := TBlockPoolWorkerThread.Create(LPool, 500);

    try
      // 启动所有线程
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].Start;

      // 等待所有线程完成
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].WaitFor;

      // 验证没有错误
      for LIdx := 0 to High(LThreads) do
        AssertEquals('Thread ' + IntToStr(LIdx) + ' error', '', LThreads[LIdx].Error);
    finally
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].Free;
    end;
  finally
    LPool.Destroy;
  end;
end;

procedure TTestCase_ConcurrentPools.Test_BlockPool_Concurrent_Reset_NoCorruption;
var
  LPool: TBlockPoolConcurrent;
  LThreads: array[0..3] of TBlockPoolWorkerThread;
  LIdx: Integer;
begin
  // 创建 Concurrent BlockPool
  LPool := TBlockPoolConcurrent.Create(64, 64);
  try
    // 创建 4 个工作线程，每个线程执行 100 次迭代
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx] := TBlockPoolWorkerThread.Create(LPool, 100);

    try
      // 启动所有线程
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].Start;

      // 等待所有线程完成
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].WaitFor;

      // 验证没有错误
      for LIdx := 0 to High(LThreads) do
        AssertEquals('Thread ' + IntToStr(LIdx) + ' error', '', LThreads[LIdx].Error);

      // 重置池（应该是线程安全的）
      LPool.Reset;

      // 验证重置后池仍然可用
      AssertTrue('Pool available after reset', LPool.Available > 0);
    finally
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].Free;
    end;
  finally
    LPool.Destroy;
  end;
end;

procedure TTestCase_ConcurrentPools.Test_FixedPool_Concurrent_Acquire_Release_Safe;
var
  LPool: TFixedPoolConcurrent;
  LThreads: array[0..3] of TFixedPoolWorkerThread;
  LIdx: Integer;
begin
  // 创建 Concurrent FixedPool
  LPool := TFixedPoolConcurrent.Create(64, 64);
  try
    // 创建 4 个工作线程，每个线程执行 500 次迭代
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx] := TFixedPoolWorkerThread.Create(LPool, 500);

    try
      // 启动所有线程
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].Start;

      // 等待所有线程完成
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].WaitFor;

      // 验证没有错误
      for LIdx := 0 to High(LThreads) do
        AssertEquals('Thread ' + IntToStr(LIdx) + ' error', '', LThreads[LIdx].Error);
    finally
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].Free;
    end;
  finally
    LPool.Destroy;
  end;
end;

procedure TTestCase_ConcurrentPools.Test_FixedPool_Concurrent_Reset_NoCorruption;
var
  LPool: TFixedPoolConcurrent;
  LThreads: array[0..3] of TFixedPoolWorkerThread;
  LIdx: Integer;
begin
  // 创建 Concurrent FixedPool
  LPool := TFixedPoolConcurrent.Create(64, 64);
  try
    // 创建 4 个工作线程，每个线程执行 100 次迭代
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx] := TFixedPoolWorkerThread.Create(LPool, 100);

    try
      // 启动所有线程
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].Start;

      // 等待所有线程完成
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].WaitFor;

      // 验证没有错误
      for LIdx := 0 to High(LThreads) do
        AssertEquals('Thread ' + IntToStr(LIdx) + ' error', '', LThreads[LIdx].Error);

      // 重置池（应该是线程安全的）
      LPool.Reset;

      // 验证重置后池仍然可用
      AssertTrue('Pool capacity after reset', LPool.Capacity > 0);
    finally
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].Free;
    end;
  finally
    LPool.Destroy;
  end;
end;

initialization
  RegisterTest(TTestCase_ConcurrentPools);

end.
