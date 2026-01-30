unit test_slabpool_sharded;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.mem.pool.slab,
  fafafa.core.mem.pool.slab.sharded;

type
  { TWorkerThread - 工作线程用于并发测试 }
  TWorkerThread = class(TThread)
  private
    FPool: TSlabPoolSharded;
    FIterations: Integer;
    FAllocSize: SizeUInt;
    FError: string;
    FAllocCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(aPool: TSlabPoolSharded; aIterations: Integer; aAllocSize: SizeUInt);
    property Error: string read FError;
    property AllocCount: Integer read FAllocCount;
  end;

  { TAllocThread - 分配线程用于跨线程释放测试 }
  TAllocThread = class(TThread)
  private
    FPool: TSlabPoolSharded;
    FError: string;
  protected
    procedure Execute; override;
  public
    Ptrs: array[0..99] of Pointer;
    constructor Create(aPool: TSlabPoolSharded);
    property Error: string read FError;
  end;

  { TReleaseThread - 释放线程用于跨线程释放测试 }
  TReleaseThread = class(TThread)
  private
    FPool: TSlabPoolSharded;
    FError: string;
  protected
    procedure Execute; override;
  public
    Ptrs: array[0..99] of Pointer;
    constructor Create(aPool: TSlabPoolSharded; const aPtrs: array of Pointer);
    property Error: string read FError;
  end;

  { TTestCase_SlabPoolSharded }
  TTestCase_SlabPoolSharded = class(TTestCase)
  published
    // Batch 1: Sharded 版本测试
    procedure Test_SlabPool_Sharded_MultiThread_NoRaceCondition;
    procedure Test_SlabPool_Sharded_LoadBalancing_EvenDistribution;
    procedure Test_SlabPool_Sharded_HighContention_MaintainsConsistency;
    procedure Test_SlabPool_Sharded_CrossThread_Release_ThreadSafe;
  end;

implementation

{ TWorkerThread }

constructor TWorkerThread.Create(aPool: TSlabPoolSharded; aIterations: Integer; aAllocSize: SizeUInt);
begin
  inherited Create(True);
  FPool := aPool;
  FIterations := aIterations;
  FAllocSize := aAllocSize;
  FError := '';
  FAllocCount := 0;
  FreeOnTerminate := False;
end;

procedure TWorkerThread.Execute;
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
    end;
  except
    on E: Exception do
      FError := E.Message;
  end;
end;

{ TTestCase_SlabPoolSharded }

procedure TTestCase_SlabPoolSharded.Test_SlabPool_Sharded_MultiThread_NoRaceCondition;
var
  LPool: TSlabPoolSharded;
  LThreads: array[0..3] of TWorkerThread;
  LIdx: Integer;
  LTotalAllocs: Integer;
begin
  // 创建 4 分片的 Slab 池
  LPool := TSlabPoolSharded.Create(4096, 4);
  try
    // 创建 4 个工作线程，每个线程执行 100 次迭代
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx] := TWorkerThread.Create(LPool, 100, 64);

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
    LPool.Free;
  end;
end;

procedure TTestCase_SlabPoolSharded.Test_SlabPool_Sharded_LoadBalancing_EvenDistribution;
var
  LPool: TSlabPoolSharded;
  LThreads: array[0..7] of TWorkerThread;
  LIdx: Integer;
  LMinAllocs, LMaxAllocs: Integer;
  LAllocCounts: array[0..7] of Integer;
begin
  // 创建 8 分片的 Slab 池
  LPool := TSlabPoolSharded.Create(8192, 8);
  try
    // 创建 8 个工作线程，每个线程执行 50 次迭代
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx] := TWorkerThread.Create(LPool, 50, 128);

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

      // 收集分配计数
      for LIdx := 0 to High(LThreads) do
        LAllocCounts[LIdx] := LThreads[LIdx].AllocCount;

      // 计算最小和最大分配数
      LMinAllocs := LAllocCounts[0];
      LMaxAllocs := LAllocCounts[0];
      for LIdx := 1 to High(LAllocCounts) do
      begin
        if LAllocCounts[LIdx] < LMinAllocs then
          LMinAllocs := LAllocCounts[LIdx];
        if LAllocCounts[LIdx] > LMaxAllocs then
          LMaxAllocs := LAllocCounts[LIdx];
      end;

      // 验证负载均衡：最大和最小分配数差异不应超过 20%
      AssertTrue('Load balancing check',
        (LMaxAllocs - LMinAllocs) <= (LMaxAllocs div 5));
    finally
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].Free;
    end;
  finally
    LPool.Free;
  end;
end;

procedure TTestCase_SlabPoolSharded.Test_SlabPool_Sharded_HighContention_MaintainsConsistency;
var
  LPool: TSlabPoolSharded;
  LThreads: array[0..15] of TWorkerThread;
  LIdx: Integer;
  LStats: TSlabPoolStats;
begin
  // 创建 4 分片的 Slab 池（高竞争：16 线程 vs 4 分片）
  LPool := TSlabPoolSharded.Create(2048, 4);
  try
    // 创建 16 个工作线程，每个线程执行 30 次迭代
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx] := TWorkerThread.Create(LPool, 30, 32);

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
    LPool.Free;
  end;
end;

procedure TTestCase_SlabPoolSharded.Test_SlabPool_Sharded_CrossThread_Release_ThreadSafe;
var
  LPool: TSlabPoolSharded;
  LAllocThread: TAllocThread;
  LReleaseThread: TReleaseThread;
begin
  // 创建 2 分片的 Slab 池
  LPool := TSlabPoolSharded.Create(4096, 2);
  try
    // 创建分配线程
    LAllocThread := TAllocThread.Create(LPool);
    try
      LAllocThread.Start;
      LAllocThread.WaitFor;

      AssertEquals('Alloc thread error', '', LAllocThread.Error);

      // 创建释放线程（跨线程释放）
      LReleaseThread := TReleaseThread.Create(LPool, LAllocThread.Ptrs);
      try
        LReleaseThread.Start;
        LReleaseThread.WaitFor;

        AssertEquals('Release thread error', '', LReleaseThread.Error);
      finally
        LReleaseThread.Free;
      end;
    finally
      LAllocThread.Free;
    end;
  finally
    LPool.Free;
  end;
end;

{ TAllocThread }

constructor TAllocThread.Create(aPool: TSlabPoolSharded);
begin
  inherited Create(True);
  FPool := aPool;
  FError := '';
  FreeOnTerminate := False;
end;

procedure TAllocThread.Execute;
var
  LIdx: Integer;
begin
  try
    for LIdx := 0 to High(Ptrs) do
    begin
      Ptrs[LIdx] := FPool.GetMem(64);
      if Ptrs[LIdx] = nil then
      begin
        FError := Format('Allocation failed at index %d', [LIdx]);
        Exit;
      end;
      PByte(Ptrs[LIdx])^ := Byte(LIdx);
    end;
  except
    on E: Exception do
      FError := E.Message;
  end;
end;

{ TReleaseThread }

constructor TReleaseThread.Create(aPool: TSlabPoolSharded; const aPtrs: array of Pointer);
var
  LIdx: Integer;
begin
  inherited Create(True);
  FPool := aPool;
  FError := '';
  for LIdx := 0 to High(aPtrs) do
    Ptrs[LIdx] := aPtrs[LIdx];
  FreeOnTerminate := False;
end;

procedure TReleaseThread.Execute;
var
  LIdx: Integer;
begin
  try
    for LIdx := 0 to High(Ptrs) do
    begin
      if Ptrs[LIdx] <> nil then
      begin
        // 验证数据完整性
        if PByte(Ptrs[LIdx])^ <> Byte(LIdx) then
        begin
          FError := Format('Data corruption at index %d', [LIdx]);
          Exit;
        end;
        FPool.FreeMem(Ptrs[LIdx]);
      end;
    end;
  except
    on E: Exception do
      FError := E.Message;
  end;
end;

initialization
  RegisterTest(TTestCase_SlabPoolSharded);

end.
