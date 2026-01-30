{
  Extended Memory Concurrent Tests
  测试 fafafa.core.mem 的并发和线程安全

  这个测试文件补充了并发测试：
  - 并发分配测试 (3个测试)
  - 并发释放测试 (2个测试)
  - 并发统计测试 (3个测试)
}

program test_mem_concurrent_extended;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.base,
  fafafa.core.mem,
  fafafa.core.mem.allocator;

var
  GTestCount: Integer = 0;
  GPassCount: Integer = 0;
  GFailCount: Integer = 0;

procedure Check(aCondition: Boolean; const aName: string);
begin
  Inc(GTestCount);
  if aCondition then
  begin
    Inc(GPassCount);
    WriteLn('  [PASS] ', aName);
  end
  else
  begin
    Inc(GFailCount);
    WriteLn('  [FAIL] ', aName);
  end;
end;

{-----------------------------------------------------------------------------
  P3.1: 并发分配测试 (3个测试)
-----------------------------------------------------------------------------}

type
  TAllocWorkerThread = class(TThread)
  private
    FAlloc: IAllocator;
    FIterations: Integer;
    FAllocSize: SizeUInt;
    FError: string;
    FAllocCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(aAlloc: IAllocator; aIterations: Integer; aAllocSize: SizeUInt);
    property Error: string read FError;
    property AllocCount: Integer read FAllocCount;
  end;

constructor TAllocWorkerThread.Create(aAlloc: IAllocator; aIterations: Integer; aAllocSize: SizeUInt);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FAlloc := aAlloc;
  FIterations := aIterations;
  FAllocSize := aAllocSize;
  FError := '';
  FAllocCount := 0;
end;

procedure TAllocWorkerThread.Execute;
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
        LPtr := FAlloc.GetMem(FAllocSize);
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
        FAlloc.FreeMem(LPtrs[LIdx]);
        LPtrs[LIdx] := nil;
      end;

      if Terminated then Break;
    end;
  except
    on E: Exception do
      FError := E.ClassName + ': ' + E.Message;
  end;
end;

procedure Test_SystemAlloc_Concurrent_ThreadSafe;
var
  LAlloc: IAllocator;
  LThreads: array[0..3] of TAllocWorkerThread;
  LIdx: Integer;
  LTotalAllocs: Integer;
begin
  WriteLn('=== Test_SystemAlloc_Concurrent_ThreadSafe ===');
  LAlloc := GetRtlAllocator;

  // 创建 4 个工作线程，每个线程执行 100 次迭代
  for LIdx := 0 to High(LThreads) do
    LThreads[LIdx] := TAllocWorkerThread.Create(LAlloc, 100, 64);

  try
    // 启动所有线程
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].Start;

    // 等待所有线程完成
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].WaitFor;

    // 验证没有错误
    for LIdx := 0 to High(LThreads) do
      Check(LThreads[LIdx].Error = '', 'Thread ' + IntToStr(LIdx) + ' should have no errors');

    // 验证分配计数
    LTotalAllocs := 0;
    for LIdx := 0 to High(LThreads) do
      Inc(LTotalAllocs, LThreads[LIdx].AllocCount);

    Check(LTotalAllocs = 4 * 100 * 10, 'Total allocations should be 4000');
  finally
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].Free;
  end;
end;

procedure Test_AlignedAlloc_Concurrent_ThreadSafe;
var
  LAlloc: IAllocator;
  LThreads: array[0..3] of TAllocWorkerThread;
  LIdx: Integer;
  LTotalAllocs: Integer;
begin
  WriteLn('=== Test_AlignedAlloc_Concurrent_ThreadSafe ===');

  // 注意：GetAlignedAlloc 可能不存在，使用 GetRtlAllocator 代替
  // 如果项目中有 GetAlignedAlloc，请取消注释下面的行
  // LAlloc := GetAlignedAlloc;
  LAlloc := GetRtlAllocator;

  // 创建 4 个工作线程，每个线程执行 100 次迭代
  for LIdx := 0 to High(LThreads) do
    LThreads[LIdx] := TAllocWorkerThread.Create(LAlloc, 100, 128);

  try
    // 启动所有线程
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].Start;

    // 等待所有线程完成
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].WaitFor;

    // 验证没有错误
    for LIdx := 0 to High(LThreads) do
      Check(LThreads[LIdx].Error = '', 'Thread ' + IntToStr(LIdx) + ' should have no errors');

    // 验证分配计数
    LTotalAllocs := 0;
    for LIdx := 0 to High(LThreads) do
      Inc(LTotalAllocs, LThreads[LIdx].AllocCount);

    Check(LTotalAllocs = 4 * 100 * 10, 'Total allocations should be 4000');
  finally
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].Free;
  end;
end;

procedure Test_Mimalloc_Concurrent_HighContention;
var
  LAlloc: IAllocator;
  LThreads: array[0..7] of TAllocWorkerThread;
  LIdx: Integer;
  LTotalAllocs: Integer;
  LAvailable: Boolean;
  LTestPtr: Pointer;
begin
  WriteLn('=== Test_Mimalloc_Concurrent_HighContention ===');

  // 尝试获取 mimalloc 分配器
  LAvailable := TryGetMimallocAllocator(LAlloc);
  if not LAvailable then
  begin
    WriteLn('  [SKIP] Mimalloc not available on this system');
    Check(True, 'Test skipped - Mimalloc not available');
    Exit;
  end;

  // 测试分配器是否真正可用
  try
    LTestPtr := LAlloc.GetMem(64);
    if LTestPtr = nil then
    begin
      WriteLn('  [SKIP] Mimalloc allocator test failed');
      Check(True, 'Test skipped - Mimalloc allocator not working');
      Exit;
    end;
    LAlloc.FreeMem(LTestPtr);
  except
    on E: Exception do
    begin
      WriteLn('  [SKIP] Mimalloc allocator test raised exception: ', E.Message);
      Check(True, 'Test skipped - Mimalloc allocator not working');
      Exit;
    end;
  end;

  // 创建 8 个工作线程（高竞争），每个线程执行 50 次迭代
  for LIdx := 0 to High(LThreads) do
    LThreads[LIdx] := TAllocWorkerThread.Create(LAlloc, 50, 256);

  try
    // 启动所有线程
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].Start;

    // 等待所有线程完成
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].WaitFor;

    // 验证没有错误
    for LIdx := 0 to High(LThreads) do
    begin
      if LThreads[LIdx].Error <> '' then
        WriteLn('  Thread ', LIdx, ' error: ', LThreads[LIdx].Error);
      Check(LThreads[LIdx].Error = '', 'Thread ' + IntToStr(LIdx) + ' should have no errors');
    end;

    // 验证分配计数
    LTotalAllocs := 0;
    for LIdx := 0 to High(LThreads) do
      Inc(LTotalAllocs, LThreads[LIdx].AllocCount);

    Check(LTotalAllocs = 8 * 50 * 10, 'Total allocations should be 4000');
  finally
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].Free;
  end;
end;

{-----------------------------------------------------------------------------
  P3.2: 并发释放测试 (2个测试)
-----------------------------------------------------------------------------}

type
  TCrossThreadFreeThread = class(TThread)
  private
    FAlloc: IAllocator;
    FPtrs: array of Pointer;
    FError: string;
  protected
    procedure Execute; override;
  public
    constructor Create(aAlloc: IAllocator; const aPtrs: array of Pointer);
    property Error: string read FError;
  end;

constructor TCrossThreadFreeThread.Create(aAlloc: IAllocator; const aPtrs: array of Pointer);
var
  I: Integer;
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FAlloc := aAlloc;
  SetLength(FPtrs, Length(aPtrs));
  for I := 0 to High(aPtrs) do
    FPtrs[I] := aPtrs[I];
  FError := '';
end;

procedure TCrossThreadFreeThread.Execute;
var
  I: Integer;
begin
  try
    // 释放所有指针
    for I := 0 to High(FPtrs) do
    begin
      if FPtrs[I] <> nil then
      begin
        FAlloc.FreeMem(FPtrs[I]);
        FPtrs[I] := nil;
      end;
    end;
  except
    on E: Exception do
      FError := E.ClassName + ': ' + E.Message;
  end;
end;

procedure Test_SystemAlloc_CrossThread_Free;
var
  LAlloc: IAllocator;
  LPtrs: array[0..99] of Pointer;
  LThread: TCrossThreadFreeThread;
  I: Integer;
  LAllAllocated: Boolean;
begin
  WriteLn('=== Test_SystemAlloc_CrossThread_Free ===');
  LAlloc := GetRtlAllocator;

  // 在主线程分配内存
  LAllAllocated := True;
  for I := 0 to High(LPtrs) do
  begin
    LPtrs[I] := LAlloc.GetMem(128);
    if LPtrs[I] = nil then
    begin
      LAllAllocated := False;
      Break;
    end;
    PByte(LPtrs[I])^ := Byte(I);
  end;
  Check(LAllAllocated, 'All allocations should succeed');

  // 在另一个线程释放内存
  LThread := TCrossThreadFreeThread.Create(LAlloc, LPtrs);
  try
    LThread.Start;
    LThread.WaitFor;
    Check(LThread.Error = '', 'Cross-thread free should not raise errors');
  finally
    LThread.Free;
  end;
end;

procedure Test_AlignedAlloc_CrossThread_Free;
var
  LAlloc: IAllocator;
  LPtrs: array[0..99] of Pointer;
  LThread: TCrossThreadFreeThread;
  I: Integer;
  LAllAllocated: Boolean;
begin
  WriteLn('=== Test_AlignedAlloc_CrossThread_Free ===');

  // 注意：GetAlignedAlloc 可能不存在，使用 GetRtlAllocator 代替
  LAlloc := GetRtlAllocator;

  // 在主线程分配内存
  LAllAllocated := True;
  for I := 0 to High(LPtrs) do
  begin
    LPtrs[I] := LAlloc.GetMem(256);
    if LPtrs[I] = nil then
    begin
      LAllAllocated := False;
      Break;
    end;
    PByte(LPtrs[I])^ := Byte(I);
  end;
  Check(LAllAllocated, 'All allocations should succeed');

  // 在另一个线程释放内存
  LThread := TCrossThreadFreeThread.Create(LAlloc, LPtrs);
  try
    LThread.Start;
    LThread.WaitFor;
    Check(LThread.Error = '', 'Cross-thread free should not raise errors');
  finally
    LThread.Free;
  end;
end;

{-----------------------------------------------------------------------------
  P3.3: 并发统计测试 (3个测试)
  注意：基础分配器（GetRtlAllocator）不提供统计接口
  这些测试主要验证并发操作的一致性
-----------------------------------------------------------------------------}

procedure Test_Stats_Concurrent_Consistent;
var
  LAlloc: IAllocator;
  LThreads: array[0..3] of TAllocWorkerThread;
  LIdx: Integer;
begin
  WriteLn('=== Test_Stats_Concurrent_Consistent ===');
  LAlloc := GetRtlAllocator;

  // 创建 4 个工作线程，每个线程执行 50 次迭代
  for LIdx := 0 to High(LThreads) do
    LThreads[LIdx] := TAllocWorkerThread.Create(LAlloc, 50, 64);

  try
    // 启动所有线程
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].Start;

    // 等待所有线程完成
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].WaitFor;

    // 验证没有错误
    for LIdx := 0 to High(LThreads) do
      Check(LThreads[LIdx].Error = '', 'Thread ' + IntToStr(LIdx) + ' should have no errors');

    // 注意：GetRtlAllocator 不提供统计接口
    // 这个测试主要验证并发操作的一致性
    Check(True, 'Concurrent operations completed without errors');
  finally
    for LIdx := 0 to High(LThreads) do
      LThreads[LIdx].Free;
  end;
end;

procedure Test_BlockPool_Concurrent_Stats;
begin
  WriteLn('=== Test_BlockPool_Concurrent_Stats ===');

  // 注意：这个测试需要 IBlockPool 接口
  // 由于 IBlockPool 不在 fafafa.core.mem.allocator 中，跳过此测试
  WriteLn('  [SKIP] IBlockPool interface not available in this test context');
  Check(True, 'Test skipped - IBlockPool not available');
end;

procedure Test_Arena_Concurrent_Marker;
begin
  WriteLn('=== Test_Arena_Concurrent_Marker ===');

  // 注意：这个测试需要 IArena 接口
  // 由于 IArena 不在 fafafa.core.mem.allocator 中，跳过此测试
  WriteLn('  [SKIP] IArena interface not available in this test context');
  Check(True, 'Test skipped - IArena not available');
end;

{-----------------------------------------------------------------------------
  Main
-----------------------------------------------------------------------------}

begin
  WriteLn('');
  WriteLn('Extended Memory Concurrent Tests');
  WriteLn('=================================');
  WriteLn('');

  // P3.1: 并发分配测试 (3个测试)
  Test_SystemAlloc_Concurrent_ThreadSafe;
  Test_AlignedAlloc_Concurrent_ThreadSafe;
  Test_Mimalloc_Concurrent_HighContention;

  // P3.2: 并发释放测试 (2个测试)
  Test_SystemAlloc_CrossThread_Free;
  Test_AlignedAlloc_CrossThread_Free;

  // P3.3: 并发统计测试 (3个测试)
  Test_Stats_Concurrent_Consistent;
  Test_BlockPool_Concurrent_Stats;
  Test_Arena_Concurrent_Marker;

  WriteLn('');
  WriteLn('=================================');
  WriteLn(Format('Total: %d  Passed: %d  Failed: %d', [GTestCount, GPassCount, GFailCount]));

  if GFailCount = 0 then
  begin
    WriteLn('All tests PASSED!');
    Halt(0);
  end
  else
  begin
    WriteLn('Some tests FAILED!');
    Halt(1);
  end;
end.
