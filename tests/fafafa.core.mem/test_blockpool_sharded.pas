{$CODEPAGE UTF8}
unit test_blockpool_sharded;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.mem.blockpool.sharded,
  fafafa.core.mem.blockpool,
  fafafa.core.mem.error;

type
  TTestCase_ShardedBlockPool = class(TTestCase)
  published
    procedure Test_Create_Basic;
    procedure Test_Concurrent_AcquireRelease;
    procedure Test_Concurrent_AcquireRelease_ThreadCache_StatsOff;
    procedure Test_CrossThread_Release;
    procedure Test_CrossThread_Release_StatsOff;
    procedure Test_CrossThread_Release_ThreadCache_Batched;
    procedure Test_ThreadCache_DoubleFree;
    // Batch 1: 新增 Sharded 版本测试
    procedure Test_BlockPool_Sharded_HighContention_MaintainsConsistency;
  end;

implementation

type
  TWorkerThread = class(TThread)
  private
    FPool: IBlockPool;
    FSharded: TShardedBlockPool;
    FIterations: Integer;
    FError: string;
  protected
    procedure Execute; override;
  public
    constructor Create(aPool: IBlockPool; aIterations: Integer; aSharded: TShardedBlockPool = nil);
    property Error: string read FError;
  end;

  TAcquireThread = class(TThread)
  private
    FPool: IBlockPool;
    FOutPtr: PPointer;
    FError: string;
  protected
    procedure Execute; override;
  public
    constructor Create(aPool: IBlockPool; aOutPtr: PPointer);
    property Error: string read FError;
  end;

constructor TWorkerThread.Create(aPool: IBlockPool; aIterations: Integer; aSharded: TShardedBlockPool);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FPool := aPool;
  FSharded := aSharded;
  FIterations := aIterations;
  FError := '';
end;

constructor TAcquireThread.Create(aPool: IBlockPool; aOutPtr: PPointer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FPool := aPool;
  FOutPtr := aOutPtr;
  FError := '';
end;

procedure TWorkerThread.Execute;
var
  LIdx: Integer;
  LPtr: Pointer;
begin
  try
    for LIdx := 1 to FIterations do
    begin
      LPtr := FPool.Acquire;
      if LPtr = nil then
        raise Exception.Create('Acquire returned nil');
      FPool.Release(LPtr);
      if Terminated then Break;
    end;
    if FSharded <> nil then
      FSharded.FlushThreadCache;
  except
    on E: Exception do
      FError := E.ClassName + ': ' + E.Message;
  end;
end;

procedure TAcquireThread.Execute;
begin
  try
    if FOutPtr <> nil then
    begin
      FOutPtr^ := FPool.Acquire;
      if FOutPtr^ = nil then
        raise Exception.Create('Acquire returned nil');
    end
    else
      raise Exception.Create('OutPtr is nil');
  except
    on E: Exception do
      FError := E.ClassName + ': ' + E.Message;
  end;
end;

procedure TTestCase_ShardedBlockPool.Test_Create_Basic;
var
  LPool: IBlockPool;
  LPtr: Pointer;
begin
  LPool := TShardedBlockPool.Create(32, 64, 4);
  AssertEquals('BlockSize', 32, LPool.BlockSize);
  AssertTrue('Capacity >= 64', LPool.Capacity >= 64);

  LPtr := LPool.Acquire;
  AssertNotNull(LPtr);
  LPool.Release(LPtr);
end;

procedure TTestCase_ShardedBlockPool.Test_Concurrent_AcquireRelease;
var
  LPool: IBlockPool;
  LThreads: array[0..3] of TWorkerThread;
  LIdx: Integer;
begin
  LPool := TShardedBlockPool.Create(64, 64, 4);

  for LIdx := 0 to High(LThreads) do
    LThreads[LIdx] := TWorkerThread.Create(LPool, 500);
  try
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].Start;
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].WaitFor;
    for LIdx := 0 to High(LThreads) do
      AssertEquals('Thread error', '', LThreads[LIdx].Error);
  finally
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].Free;
  end;
end;

procedure TTestCase_ShardedBlockPool.Test_Concurrent_AcquireRelease_ThreadCache_StatsOff;
var
  LConfig: TShardedBlockPoolConfig;
  LShardedObj: TShardedBlockPool;
  LPool: IBlockPool;
  LThreads: array[0..3] of TWorkerThread;
  LIdx: Integer;
begin
  LConfig := TShardedBlockPoolConfig.Default(64, 64, 4);
  LConfig.ThreadCacheCapacity := 64;
  LConfig.ThreadCacheCheckDoubleFree := False;
  LConfig.TrackInUse := False;
  LShardedObj := TShardedBlockPool.Create(LConfig);
  LPool := LShardedObj as IBlockPool;

  for LIdx := 0 to High(LThreads) do
    LThreads[LIdx] := TWorkerThread.Create(LPool, 2000, LShardedObj);
  try
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].Start;
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].WaitFor;
    for LIdx := 0 to High(LThreads) do
      AssertEquals('Thread error', '', LThreads[LIdx].Error);
  finally
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].Free;
  end;
end;

procedure TTestCase_ShardedBlockPool.Test_CrossThread_Release;
var
  LPool: IBlockPool;
  LPtrs: array[0..3] of Pointer;
  LThreads: array[0..3] of TAcquireThread;
  LIdx: Integer;
begin
  LPool := TShardedBlockPool.Create(64, 64, 4);
  for LIdx := 0 to High(LPtrs) do
    LPtrs[LIdx] := nil;

  for LIdx := 0 to High(LThreads) do
    LThreads[LIdx] := TAcquireThread.Create(LPool, @LPtrs[LIdx]);
  try
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].Start;
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].WaitFor;
    for LIdx := 0 to High(LThreads) do
      AssertEquals('Thread error', '', LThreads[LIdx].Error);

    for LIdx := 0 to High(LPtrs) do
      AssertNotNull('Ptr ' + IntToStr(LIdx), LPtrs[LIdx]);

    AssertEquals('InUse after threaded acquires', Length(LPtrs), Integer(LPool.InUse));

    // Release from main thread (may exercise remote-free fast path)
    for LIdx := 0 to High(LPtrs) do
      LPool.Release(LPtrs[LIdx]);

    AssertEquals('InUse after releases', 0, Integer(LPool.InUse));
  finally
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].Free;
  end;
end;

procedure TTestCase_ShardedBlockPool.Test_CrossThread_Release_StatsOff;
var
  LConfig: TShardedBlockPoolConfig;
  LPool: IBlockPool;
  LPtrs: array[0..3] of Pointer;
  LThreads: array[0..3] of TAcquireThread;
  LIdx: Integer;
begin
  LConfig := TShardedBlockPoolConfig.Default(64, 64, 4);
  LConfig.ThreadCacheCapacity := 0;
  LConfig.ThreadCacheCheckDoubleFree := False;
  LConfig.TrackInUse := False;
  LPool := TShardedBlockPool.Create(LConfig);
  for LIdx := 0 to High(LPtrs) do
    LPtrs[LIdx] := nil;

  for LIdx := 0 to High(LThreads) do
    LThreads[LIdx] := TAcquireThread.Create(LPool, @LPtrs[LIdx]);
  try
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].Start;
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].WaitFor;
    for LIdx := 0 to High(LThreads) do
      AssertEquals('Thread error', '', LThreads[LIdx].Error);

    for LIdx := 0 to High(LPtrs) do
      AssertNotNull('Ptr ' + IntToStr(LIdx), LPtrs[LIdx]);

    AssertEquals('InUse after threaded acquires', Length(LPtrs), Integer(LPool.InUse));

    // Release from main thread (may exercise remote-free fast path)
    for LIdx := 0 to High(LPtrs) do
      LPool.Release(LPtrs[LIdx]);

    AssertEquals('InUse after releases', 0, Integer(LPool.InUse));
  finally
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].Free;
  end;
end;

procedure TTestCase_ShardedBlockPool.Test_CrossThread_Release_ThreadCache_Batched;
var
  LConfig: TShardedBlockPoolConfig;
  LShardedObj: TShardedBlockPool;
  LPool: IBlockPool;
  LPtrs: array[0..127] of Pointer;
  LThreads: array[0..127] of TAcquireThread;
  LIdx: Integer;
begin
  LConfig := TShardedBlockPoolConfig.Default(64, 64, 8);
  LConfig.ThreadCacheCapacity := 64;
  LConfig.ThreadCacheCheckDoubleFree := False;
  LConfig.TrackInUse := False;
  LShardedObj := TShardedBlockPool.Create(LConfig);
  LPool := LShardedObj as IBlockPool;
  for LIdx := 0 to High(LPtrs) do
    LPtrs[LIdx] := nil;

  for LIdx := 0 to High(LThreads) do
    LThreads[LIdx] := TAcquireThread.Create(LPool, @LPtrs[LIdx]);
  try
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].Start;
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].WaitFor;
    for LIdx := 0 to High(LThreads) do
      AssertEquals('Thread error', '', LThreads[LIdx].Error);

    for LIdx := 0 to High(LPtrs) do
      AssertNotNull('Ptr ' + IntToStr(LIdx), LPtrs[LIdx]);

    // Release from main thread (exercise remote-free batching)
    for LIdx := 0 to High(LPtrs) do
      LPool.Release(LPtrs[LIdx]);

    // Flush remote buffers to make the frees visible to shards.
    LShardedObj.FlushThreadCache;
    AssertEquals('InUse after releases', 0, Integer(LPool.InUse));
  finally
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].Free;
  end;
end;

procedure TTestCase_ShardedBlockPool.Test_ThreadCache_DoubleFree;
var
  LConfig: TShardedBlockPoolConfig;
  LPool: IBlockPool;
  LPtr: Pointer;
begin
  LConfig := TShardedBlockPoolConfig.Default(64, 64, 4);
  LConfig.ThreadCacheCapacity := 16;
  LPool := TShardedBlockPool.Create(LConfig);

  LPtr := LPool.Acquire;
  AssertNotNull(LPtr);
  LPool.Release(LPtr);

  try
    LPool.Release(LPtr);
    Fail('Expected EAllocError');
  except
    on E: EAllocError do
      AssertEquals('Error=aeDoubleFree', Ord(aeDoubleFree), Ord(E.Error));
  end;
end;

procedure TTestCase_ShardedBlockPool.Test_BlockPool_Sharded_HighContention_MaintainsConsistency;
var
  LConfig: TShardedBlockPoolConfig;
  LPool: IBlockPool;
  LThreads: array[0..15] of TWorkerThread;
  LIdx: Integer;
begin
  // 创建 4 分片的 BlockPool（高竞争：16 线程 vs 4 分片）
  LConfig := TShardedBlockPoolConfig.Default(64, 256, 4);
  LConfig.TrackInUse := True;
  LPool := TShardedBlockPool.Create(LConfig);

  // 创建 16 个工作线程，每个线程执行 50 次迭代
  for LIdx := 0 to High(LThreads) do
    LThreads[LIdx] := TWorkerThread.Create(LPool, 50);
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
    AssertEquals('InUse after all releases', 0, Integer(LPool.InUse));
    AssertTrue('Available > 0', LPool.Available > 0);
  finally
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].Free;
  end;
end;

initialization
  RegisterTest(TTestCase_ShardedBlockPool);

end.
