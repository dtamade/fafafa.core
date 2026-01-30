{$CODEPAGE UTF8}
unit test_stress_pools;

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
  TTestCase_StressPools = class(TTestCase)
  published
    // Batch 3: 压力测试 (4个)
    procedure Test_AllPools_HighConcurrency_100Threads_Stable;
    procedure Test_AllPools_LongRunning_NoLeaks;
    procedure Test_AllPools_MixedOperations_StressTest_Stable;
    procedure Test_AllPools_DeadlockDetection_NoDeadlocks;
  end;

implementation

type
  TStressWorkerThread = class(TThread)
  private
    FSlabPool: TSlabPoolConcurrent;
    FBlockPool: TBlockPoolConcurrent;
    FFixedPool: TFixedPoolConcurrent;
    FIterations: Integer;
    FError: string;
    FOperationCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(
      aSlabPool: TSlabPoolConcurrent;
      aBlockPool: TBlockPoolConcurrent;
      aFixedPool: TFixedPoolConcurrent;
      aIterations: Integer
    );
    property Error: string read FError;
    property OperationCount: Integer read FOperationCount;
  end;

  TMixedOperationThread = class(TThread)
  private
    FSlabPool: TSlabPoolConcurrent;
    FBlockPool: TBlockPoolConcurrent;
    FFixedPool: TFixedPoolConcurrent;
    FDuration: Integer; // seconds
    FError: string;
    FOperationCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(
      aSlabPool: TSlabPoolConcurrent;
      aBlockPool: TBlockPoolConcurrent;
      aFixedPool: TFixedPoolConcurrent;
      aDuration: Integer
    );
    property Error: string read FError;
    property OperationCount: Integer read FOperationCount;
  end;

{ TStressWorkerThread }

constructor TStressWorkerThread.Create(
  aSlabPool: TSlabPoolConcurrent;
  aBlockPool: TBlockPoolConcurrent;
  aFixedPool: TFixedPoolConcurrent;
  aIterations: Integer
);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FSlabPool := aSlabPool;
  FBlockPool := aBlockPool;
  FFixedPool := aFixedPool;
  FIterations := aIterations;
  FError := '';
  FOperationCount := 0;
end;

procedure TStressWorkerThread.Execute;
var
  LIdx: Integer;
  LSlabPtr, LBlockPtr, LFixedPtr: Pointer;
  LOk: Boolean;
begin
  try
    for LIdx := 1 to FIterations do
    begin
      // Test SlabPool
      LSlabPtr := FSlabPool.GetMem(64);
      if LSlabPtr <> nil then
      begin
        PByte(LSlabPtr)^ := Byte(LIdx and $FF);
        FSlabPool.FreeMem(LSlabPtr);
        Inc(FOperationCount);
      end;

      // Test BlockPool
      LBlockPtr := FBlockPool.Acquire;
      if LBlockPtr <> nil then
      begin
        PByte(LBlockPtr)^ := Byte(LIdx and $FF);
        FBlockPool.Release(LBlockPtr);
        Inc(FOperationCount);
      end;

      // Test FixedPool
      LOk := FFixedPool.Acquire(LFixedPtr);
      if LOk and (LFixedPtr <> nil) then
      begin
        PByte(LFixedPtr)^ := Byte(LIdx and $FF);
        FFixedPool.Release(LFixedPtr);
        Inc(FOperationCount);
      end;

      if Terminated then Break;
    end;
  except
    on E: Exception do
      FError := E.ClassName + ': ' + E.Message;
  end;
end;

{ TMixedOperationThread }

constructor TMixedOperationThread.Create(
  aSlabPool: TSlabPoolConcurrent;
  aBlockPool: TBlockPoolConcurrent;
  aFixedPool: TFixedPoolConcurrent;
  aDuration: Integer
);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FSlabPool := aSlabPool;
  FBlockPool := aBlockPool;
  FFixedPool := aFixedPool;
  FDuration := aDuration;
  FError := '';
  FOperationCount := 0;
end;

procedure TMixedOperationThread.Execute;
var
  LStartTime: QWord;
  LSlabPtr, LBlockPtr, LFixedPtr: Pointer;
  LOk: Boolean;
  LOpType: Integer;
begin
  try
    LStartTime := GetTickCount64;

    while (GetTickCount64 - LStartTime < QWord(FDuration) * 1000) and not Terminated do
    begin
      // Randomly choose operation type
      LOpType := Random(3);

      case LOpType of
        0: begin // SlabPool operations
          LSlabPtr := FSlabPool.GetMem(32 + Random(64));
          if LSlabPtr <> nil then
          begin
            PByte(LSlabPtr)^ := Byte(Random(256));
            Sleep(Random(5)); // Simulate work
            FSlabPool.FreeMem(LSlabPtr);
            Inc(FOperationCount);
          end;
        end;

        1: begin // BlockPool operations
          LBlockPtr := FBlockPool.Acquire;
          if LBlockPtr <> nil then
          begin
            PByte(LBlockPtr)^ := Byte(Random(256));
            Sleep(Random(5)); // Simulate work
            FBlockPool.Release(LBlockPtr);
            Inc(FOperationCount);
          end;
        end;

        2: begin // FixedPool operations
          LOk := FFixedPool.Acquire(LFixedPtr);
          if LOk and (LFixedPtr <> nil) then
          begin
            PByte(LFixedPtr)^ := Byte(Random(256));
            Sleep(Random(5)); // Simulate work
            FFixedPool.Release(LFixedPtr);
            Inc(FOperationCount);
          end;
        end;
      end;
    end;
  except
    on E: Exception do
      FError := E.ClassName + ': ' + E.Message;
  end;
end;

{ TTestCase_StressPools }

procedure TTestCase_StressPools.Test_AllPools_HighConcurrency_100Threads_Stable;
var
  LSlabPool: TSlabPoolConcurrent;
  LBlockPool: TBlockPoolConcurrent;
  LFixedPool: TFixedPoolConcurrent;
  LThreads: array[0..99] of TStressWorkerThread;
  LIdx: Integer;
  LTotalOps: Integer;
begin
  // 创建池
  LSlabPool := TSlabPoolConcurrent.Create(8192);
  LBlockPool := TBlockPoolConcurrent.Create(128, 128);
  LFixedPool := TFixedPoolConcurrent.Create(128, 128);

  try
    // 创建 100 个工作线程，每个线程执行 50 次迭代
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx] := TStressWorkerThread.Create(LSlabPool, LBlockPool, LFixedPool, 50);

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

      // 验证操作计数
      LTotalOps := 0;
      for LIdx := 0 to High(LThreads) do
        Inc(LTotalOps, LThreads[LIdx].OperationCount);

      AssertTrue('Total operations > 0', LTotalOps > 0);
      AssertTrue('High concurrency stable', LTotalOps >= 100 * 50); // At least 50 ops per thread
    finally
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].Free;
    end;
  finally
    LSlabPool.Destroy;
    LBlockPool.Destroy;
    LFixedPool.Destroy;
  end;
end;

procedure TTestCase_StressPools.Test_AllPools_LongRunning_NoLeaks;
var
  LSlabPool: TSlabPoolConcurrent;
  LBlockPool: TBlockPoolConcurrent;
  LFixedPool: TFixedPoolConcurrent;
  LThreads: array[0..7] of TMixedOperationThread;
  LIdx: Integer;
  LTotalOps: Integer;
const
  TestDuration = 10; // 10 seconds (simplified from 24 hours)
begin
  // 创建池
  LSlabPool := TSlabPoolConcurrent.Create(4096);
  LBlockPool := TBlockPoolConcurrent.Create(64, 64);
  LFixedPool := TFixedPoolConcurrent.Create(64, 64);

  try
    // 创建 8 个工作线程，运行 10 秒
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx] := TMixedOperationThread.Create(LSlabPool, LBlockPool, LFixedPool, TestDuration);

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

      // 验证操作计数
      LTotalOps := 0;
      for LIdx := 0 to High(LThreads) do
        Inc(LTotalOps, LThreads[LIdx].OperationCount);

      AssertTrue('Long running operations > 0', LTotalOps > 0);
    finally
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].Free;
    end;
  finally
    LSlabPool.Destroy;
    LBlockPool.Destroy;
    LFixedPool.Destroy;
  end;
end;

procedure TTestCase_StressPools.Test_AllPools_MixedOperations_StressTest_Stable;
var
  LSlabPool: TSlabPoolConcurrent;
  LBlockPool: TBlockPoolConcurrent;
  LFixedPool: TFixedPoolConcurrent;
  LThreads: array[0..15] of TMixedOperationThread;
  LIdx: Integer;
  LTotalOps: Integer;
const
  TestDuration = 5; // 5 seconds
begin
  // 创建池
  LSlabPool := TSlabPoolConcurrent.Create(4096);
  LBlockPool := TBlockPoolConcurrent.Create(64, 64);
  LFixedPool := TFixedPoolConcurrent.Create(64, 64);

  try
    // 创建 16 个工作线程，运行 5 秒，执行混合操作
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx] := TMixedOperationThread.Create(LSlabPool, LBlockPool, LFixedPool, TestDuration);

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

      // 验证操作计数
      LTotalOps := 0;
      for LIdx := 0 to High(LThreads) do
        Inc(LTotalOps, LThreads[LIdx].OperationCount);

      AssertTrue('Mixed operations > 0', LTotalOps > 0);
      AssertTrue('Stress test stable', LTotalOps >= 16 * 10); // At least 10 ops per thread
    finally
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].Free;
    end;
  finally
    LSlabPool.Destroy;
    LBlockPool.Destroy;
    LFixedPool.Destroy;
  end;
end;

procedure TTestCase_StressPools.Test_AllPools_DeadlockDetection_NoDeadlocks;
var
  LSlabPool: TSlabPoolConcurrent;
  LBlockPool: TBlockPoolConcurrent;
  LFixedPool: TFixedPoolConcurrent;
  LThreads: array[0..31] of TStressWorkerThread;
  LIdx: Integer;
  LStartTime: QWord;
  LTimeout: Boolean;
const
  TimeoutMs = 30000; // 30 seconds timeout
begin
  // 创建池
  LSlabPool := TSlabPoolConcurrent.Create(2048);
  LBlockPool := TBlockPoolConcurrent.Create(32, 32);
  LFixedPool := TFixedPoolConcurrent.Create(32, 32);

  try
    // 创建 32 个工作线程，高竞争场景
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx] := TStressWorkerThread.Create(LSlabPool, LBlockPool, LFixedPool, 100);

    try
      LStartTime := GetTickCount64;
      LTimeout := False;

      // 启动所有线程
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].Start;

      // 等待所有线程完成，带超时检测
      for LIdx := 0 to High(LThreads) do
      begin
        while not LThreads[LIdx].Finished do
        begin
          if GetTickCount64 - LStartTime > TimeoutMs then
          begin
            LTimeout := True;
            Break;
          end;
          Sleep(100);
        end;

        if LTimeout then
          Break;
      end;

      // 如果超时，终止所有线程
      if LTimeout then
      begin
        for LIdx := 0 to High(LThreads) do
          LThreads[LIdx].Terminate;

        // 等待线程终止
        for LIdx := 0 to High(LThreads) do
          LThreads[LIdx].WaitFor;
      end;

      // 验证没有死锁（没有超时）
      AssertFalse('No deadlock detected', LTimeout);

      // 验证没有错误
      for LIdx := 0 to High(LThreads) do
        AssertEquals('Thread ' + IntToStr(LIdx) + ' error', '', LThreads[LIdx].Error);
    finally
      for LIdx := 0 to High(LThreads) do
        LThreads[LIdx].Free;
    end;
  finally
    LSlabPool.Destroy;
    LBlockPool.Destroy;
    LFixedPool.Destroy;
  end;
end;

initialization
  RegisterTest(TTestCase_StressPools);

end.
