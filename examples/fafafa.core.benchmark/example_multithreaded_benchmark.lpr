program example_multithreaded_benchmark;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.benchmark;

// 全局共享资源用于测试
var
  GSharedCounter: Integer;
  GSharedLock: TCriticalSection;
  GSharedList: TThreadList;

// 简单的多线程计算测试
procedure TestMultiThreadComputation(aState: IBenchmarkState; aThreadIndex: Integer);
var
  LI: Integer;
  LSum: Integer;
begin
  LSum := 0;
  
  // 每个线程做1000次计算
  for LI := 1 to 1000 do
    LSum := LSum + LI + aThreadIndex;
  
  // 可以根据线程索引做不同的工作
  if aThreadIndex = 0 then
  begin
    // 主线程可以做一些特殊工作
    for LI := 1 to 100 do
      LSum := LSum + LI * LI;
  end;
end;

// 单线程版本用于对比
procedure SingleThreadComputation(aState: IBenchmarkState);
var
  LI, LJ: Integer;
  LSum: Integer;
begin
  while aState.KeepRunning do
  begin
    LSum := 0;
    
    // 模拟4个线程的总工作量
    for LJ := 0 to 3 do
    begin
      for LI := 1 to 1000 do
        LSum := LSum + LI + LJ;
    end;
    
    // 主线程的额外工作
    for LI := 1 to 100 do
      LSum := LSum + LI * LI;
    
    aState.SetItemsProcessed(4000 + 100); // 总工作量
  end;
end;

// 测试锁竞争
procedure TestLockContention(aState: IBenchmarkState; aThreadIndex: Integer);
var
  LI: Integer;
begin
  for LI := 1 to 250 do // 每个线程250次，4个线程总共1000次
  begin
    GSharedLock.Enter;
    try
      Inc(GSharedCounter);
    finally
      GSharedLock.Leave;
    end;
  end;
end;

// 测试线程安全列表操作
procedure TestThreadSafeList(aState: IBenchmarkState; aThreadIndex: Integer);
var
  LI: Integer;
begin
  for LI := 1 to 500 do // 每个线程500次操作
  begin
    with GSharedList.LockList do
    try
      Add(Pointer(PtrInt(aThreadIndex * 1000 + LI)));
    finally
      GSharedList.UnlockList;
    end;
  end;
end;

// 测试读写分离
procedure TestReadWriteOperations(aState: IBenchmarkState; aThreadIndex: Integer);
var
  LI: Integer;
  LValue: Pointer;
begin
  if aThreadIndex mod 2 = 0 then
  begin
    // 偶数线程做写操作
    for LI := 1 to 200 do
    begin
      with GSharedList.LockList do
      try
        Add(Pointer(PtrInt(aThreadIndex * 1000 + LI)));
      finally
        GSharedList.UnlockList;
      end;
    end;
  end
  else
  begin
    // 奇数线程做读操作
    for LI := 1 to 800 do
    begin
      with GSharedList.LockList do
      try
        if Count > 0 then
          LValue := Items[Random(Count)];
      finally
        GSharedList.UnlockList;
      end;
    end;
  end;
end;

procedure RunBasicMultiThreadTest;
var
  LResult1, LResult2: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
begin
  WriteLn('=== 基础多线程性能对比 ===');
  WriteLn;
  
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 2;
  LConfig.MeasureIterations := 5;
  
  // 单线程测试
  WriteLn('运行单线程测试...');
  LResult1 := RunLegacyFunction('单线程计算', @SingleThreadComputation, LConfig);
  WriteLn('单线程结果: ', Format('%.2f μs/op', [LResult1.GetTimePerIteration(buMicroSeconds)]));
  WriteLn('单线程吞吐量: ', Format('%.0f ops/s', [LResult1.GetThroughput()]));
  WriteLn;
  
  // 多线程测试
  WriteLn('运行4线程测试...');
  LResult2 := RunMultiThreadBenchmark('4线程计算', @TestMultiThreadComputation, 4, LConfig);
  WriteLn('多线程结果: ', Format('%.2f μs/op', [LResult2.GetTimePerIteration(buMicroSeconds)]));
  WriteLn('多线程吞吐量: ', Format('%.0f ops/s', [LResult2.GetThroughput()]));
  WriteLn;
  
  // 计算加速比
  var LSpeedup := LResult1.GetTimePerIteration() / LResult2.GetTimePerIteration();
  WriteLn('性能提升: ', Format('%.2fx', [LSpeedup]));
  
  if LSpeedup > 1.0 then
    WriteLn('✅ 多线程确实提升了性能')
  else
    WriteLn('⚠️ 多线程没有带来性能提升，可能是任务太简单或线程开销过大');
end;

procedure RunLockContentionTest;
var
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
begin
  WriteLn;
  WriteLn('=== 锁竞争测试 ===');
  WriteLn;
  
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 3;
  
  // 重置共享计数器
  GSharedCounter := 0;
  
  WriteLn('运行锁竞争测试（4个线程竞争同一个锁）...');
  LResult := RunMultiThreadBenchmark('锁竞争测试', @TestLockContention, 4, LConfig);
  
  WriteLn('锁竞争结果: ', Format('%.2f μs/op', [LResult.GetTimePerIteration(buMicroSeconds)]));
  WriteLn('最终计数器值: ', GSharedCounter);
  WriteLn('预期值: 1000 (4线程 × 250次)');
  
  if GSharedCounter = 1000 then
    WriteLn('✅ 锁同步工作正常')
  else
    WriteLn('❌ 锁同步出现问题');
end;

procedure RunThreadSafeListTest;
var
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
begin
  WriteLn;
  WriteLn('=== 线程安全列表测试 ===');
  WriteLn;
  
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 3;
  
  // 清空列表
  GSharedList.Clear;
  
  WriteLn('运行线程安全列表测试（4个线程同时添加元素）...');
  LResult := RunMultiThreadBenchmark('线程安全列表', @TestThreadSafeList, 4, LConfig);
  
  WriteLn('列表操作结果: ', Format('%.2f μs/op', [LResult.GetTimePerIteration(buMicroSeconds)]));
  
  var LFinalCount: Integer;
  with GSharedList.LockList do
  try
    LFinalCount := Count;
  finally
    GSharedList.UnlockList;
  end;
  
  WriteLn('最终列表大小: ', LFinalCount);
  WriteLn('预期大小: 2000 (4线程 × 500次)');
  
  if LFinalCount = 2000 then
    WriteLn('✅ 线程安全列表工作正常')
  else
    WriteLn('❌ 线程安全列表出现问题');
end;

procedure RunReadWriteTest;
var
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
begin
  WriteLn;
  WriteLn('=== 读写分离测试 ===');
  WriteLn;
  
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 3;
  
  // 清空列表
  GSharedList.Clear;
  
  WriteLn('运行读写分离测试（2个写线程，2个读线程）...');
  LResult := RunMultiThreadBenchmark('读写分离', @TestReadWriteOperations, 4, LConfig);
  
  WriteLn('读写操作结果: ', Format('%.2f μs/op', [LResult.GetTimePerIteration(buMicroSeconds)]));
  
  var LFinalCount: Integer;
  with GSharedList.LockList do
  try
    LFinalCount := Count;
  finally
    GSharedList.UnlockList;
  end;
  
  WriteLn('最终列表大小: ', LFinalCount);
  WriteLn('预期大小: 400 (2个写线程 × 200次)');
end;

procedure RunScalabilityTest;
var
  LThreadCounts: array[0..3] of Integer = (1, 2, 4, 8);
  LResults: array[0..3] of IBenchmarkResult;
  LConfig: TBenchmarkConfig;
  LI: Integer;
begin
  WriteLn;
  WriteLn('=== 可扩展性测试 ===');
  WriteLn;
  
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 3;
  
  WriteLn('测试不同线程数量的性能表现...');
  WriteLn;
  
  for LI := 0 to High(LThreadCounts) do
  begin
    WriteLn('测试 ', LThreadCounts[LI], ' 个线程...');
    LResults[LI] := RunMultiThreadBenchmark('计算-' + IntToStr(LThreadCounts[LI]) + '线程', 
                                           @TestMultiThreadComputation, LThreadCounts[LI], LConfig);
    WriteLn('  时间: ', Format('%.2f μs/op', [LResults[LI].GetTimePerIteration(buMicroSeconds)]));
    WriteLn('  吞吐量: ', Format('%.0f ops/s', [LResults[LI].GetThroughput()]));
  end;
  
  WriteLn;
  WriteLn('可扩展性分析:');
  var LBaseTime := LResults[0].GetTimePerIteration();
  for LI := 1 to High(LResults) do
  begin
    var LSpeedup := LBaseTime / LResults[LI].GetTimePerIteration();
    var LEfficiency := LSpeedup / LThreadCounts[LI] * 100;
    WriteLn('  ', LThreadCounts[LI], ' 线程: 加速比 ', Format('%.2fx', [LSpeedup]), 
            ', 效率 ', Format('%.1f%%', [LEfficiency]));
  end;
end;

begin
  WriteLn('========================================');
  WriteLn('多线程基准测试示例');
  WriteLn('========================================');
  WriteLn;
  
  // 初始化全局资源
  GSharedCounter := 0;
  GSharedLock := TCriticalSection.Create;
  GSharedList := TThreadList.Create;
  Randomize;
  
  try
    RunBasicMultiThreadTest;
    RunLockContentionTest;
    RunThreadSafeListTest;
    RunReadWriteTest;
    RunScalabilityTest;
    
    WriteLn;
    WriteLn('========================================');
    WriteLn('多线程基准测试完成！');
    WriteLn('========================================');
    
  except
    on E: Exception do
    begin
      WriteLn('示例运行出错: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  // 清理资源
  GSharedLock.Free;
  GSharedList.Free;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
