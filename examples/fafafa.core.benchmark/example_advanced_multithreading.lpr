program example_advanced_multithreading;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes, Generics.Collections,
  fafafa.core.base,
  fafafa.core.benchmark;

// 高级多线程基准测试示例

// 生产者-消费者模式测试
type
  TProducerConsumerTest = class
  private
    FQueue: TThreadedQueue<Integer>;
    FProducedCount: Integer;
    FConsumedCount: Integer;
    FTargetCount: Integer;
    
  public
    constructor Create(aQueueSize, aTargetCount: Integer);
    destructor Destroy; override;
    
    procedure ProducerWork(aState: IBenchmarkState; aThreadIndex: Integer);
    procedure ConsumerWork(aState: IBenchmarkState; aThreadIndex: Integer);
    procedure MixedWork(aState: IBenchmarkState; aThreadIndex: Integer);
    
    property ProducedCount: Integer read FProducedCount;
    property ConsumedCount: Integer read FConsumedCount;
  end;

constructor TProducerConsumerTest.Create(aQueueSize, aTargetCount: Integer);
begin
  inherited Create;
  FQueue := TThreadedQueue<Integer>.Create(aQueueSize);
  FProducedCount := 0;
  FConsumedCount := 0;
  FTargetCount := aTargetCount;
end;

destructor TProducerConsumerTest.Destroy;
begin
  FQueue.Free;
  inherited Destroy;
end;

procedure TProducerConsumerTest.ProducerWork(aState: IBenchmarkState; aThreadIndex: Integer);
var
  LI: Integer;
  LItemsPerThread: Integer;
begin
  LItemsPerThread := FTargetCount div 4; // 假设4个生产者线程
  
  for LI := 1 to LItemsPerThread do
  begin
    FQueue.PushItem(aThreadIndex * 1000 + LI);
    InterlockedIncrement(FProducedCount);
  end;
end;

procedure TProducerConsumerTest.ConsumerWork(aState: IBenchmarkState; aThreadIndex: Integer);
var
  LItem: Integer;
  LConsumed: Integer;
begin
  LConsumed := 0;
  
  // 消费者持续工作直到达到目标
  while FConsumedCount < FTargetCount do
  begin
    if FQueue.PopItem(LItem) = wrSignaled then
    begin
      InterlockedIncrement(FConsumedCount);
      Inc(LConsumed);
      
      // 模拟处理时间
      Sleep(0);
    end
    else
    begin
      // 队列为空，短暂等待
      Sleep(1);
    end;
  end;
end;

procedure TProducerConsumerTest.MixedWork(aState: IBenchmarkState; aThreadIndex: Integer);
var
  LI: Integer;
  LItem: Integer;
begin
  if aThreadIndex mod 2 = 0 then
  begin
    // 偶数线程作为生产者
    for LI := 1 to 250 do
    begin
      FQueue.PushItem(aThreadIndex * 1000 + LI);
      InterlockedIncrement(FProducedCount);
    end;
  end
  else
  begin
    // 奇数线程作为消费者
    while FConsumedCount < FTargetCount do
    begin
      if FQueue.PopItem(LItem) = wrSignaled then
      begin
        InterlockedIncrement(FConsumedCount);
        Sleep(0); // 模拟处理
      end
      else
        Sleep(1);
    end;
  end;
end;

// 并行计算测试
procedure ParallelMatrixMultiply(aState: IBenchmarkState; aThreadIndex: Integer);
const
  MATRIX_SIZE = 100;
var
  LMatrixA, LMatrixB, LResult: array[0..MATRIX_SIZE-1, 0..MATRIX_SIZE-1] of Double;
  LI, LJ, LK: Integer;
  LStartRow, LEndRow: Integer;
  LThreadCount: Integer;
begin
  LThreadCount := 4; // 假设4个线程
  
  // 初始化矩阵
  for LI := 0 to MATRIX_SIZE - 1 do
    for LJ := 0 to MATRIX_SIZE - 1 do
    begin
      LMatrixA[LI, LJ] := Random;
      LMatrixB[LI, LJ] := Random;
      LResult[LI, LJ] := 0;
    end;
  
  // 计算每个线程负责的行范围
  LStartRow := (MATRIX_SIZE * aThreadIndex) div LThreadCount;
  LEndRow := (MATRIX_SIZE * (aThreadIndex + 1)) div LThreadCount - 1;
  
  // 并行矩阵乘法
  for LI := LStartRow to LEndRow do
    for LJ := 0 to MATRIX_SIZE - 1 do
      for LK := 0 to MATRIX_SIZE - 1 do
        LResult[LI, LJ] := LResult[LI, LJ] + LMatrixA[LI, LK] * LMatrixB[LK, LJ];
end;

// 并行排序测试
procedure ParallelQuickSort(aState: IBenchmarkState; aThreadIndex: Integer);
const
  ARRAY_SIZE = 10000;
var
  LArray: array[0..ARRAY_SIZE-1] of Integer;
  LI: Integer;
  LStartIdx, LEndIdx: Integer;
  LThreadCount: Integer;
  
  procedure QuickSort(var aArray: array of Integer; aLow, aHigh: Integer);
  var
    LI, LJ, LPivot, LTemp: Integer;
  begin
    if aLow < aHigh then
    begin
      LPivot := aArray[aHigh];
      LI := aLow - 1;
      
      for LJ := aLow to aHigh - 1 do
        if aArray[LJ] <= LPivot then
        begin
          Inc(LI);
          LTemp := aArray[LI];
          aArray[LI] := aArray[LJ];
          aArray[LJ] := LTemp;
        end;
      
      LTemp := aArray[LI + 1];
      aArray[LI + 1] := aArray[aHigh];
      aArray[aHigh] := LTemp;
      
      QuickSort(aArray, aLow, LI);
      QuickSort(aArray, LI + 2, aHigh);
    end;
  end;
  
begin
  LThreadCount := 4;
  
  // 初始化数组
  for LI := 0 to ARRAY_SIZE - 1 do
    LArray[LI] := Random(100000);
  
  // 计算每个线程负责的范围
  LStartIdx := (ARRAY_SIZE * aThreadIndex) div LThreadCount;
  LEndIdx := (ARRAY_SIZE * (aThreadIndex + 1)) div LThreadCount - 1;
  
  // 并行排序（注意：这是简化版本，实际并行排序更复杂）
  QuickSort(LArray, LStartIdx, LEndIdx);
end;

// 缓存友好性测试
procedure CacheFriendlyAccess(aState: IBenchmarkState; aThreadIndex: Integer);
const
  ARRAY_SIZE = 1000000;
var
  LArray: array[0..ARRAY_SIZE-1] of Integer;
  LI: Integer;
  LSum: Integer;
  LStartIdx, LEndIdx: Integer;
  LThreadCount: Integer;
begin
  LThreadCount := 4;
  
  // 初始化数组
  for LI := 0 to ARRAY_SIZE - 1 do
    LArray[LI] := LI;
  
  // 计算每个线程的范围（连续访问，缓存友好）
  LStartIdx := (ARRAY_SIZE * aThreadIndex) div LThreadCount;
  LEndIdx := (ARRAY_SIZE * (aThreadIndex + 1)) div LThreadCount - 1;
  
  LSum := 0;
  for LI := LStartIdx to LEndIdx do
    LSum := LSum + LArray[LI];
end;

procedure CacheUnfriendlyAccess(aState: IBenchmarkState; aThreadIndex: Integer);
const
  ARRAY_SIZE = 1000000;
var
  LArray: array[0..ARRAY_SIZE-1] of Integer;
  LI: Integer;
  LSum: Integer;
  LStride: Integer;
begin
  // 初始化数组
  for LI := 0 to ARRAY_SIZE - 1 do
    LArray[LI] := LI;
  
  // 跨步访问（缓存不友好）
  LStride := 4; // 4个线程
  LSum := 0;
  
  LI := aThreadIndex;
  while LI < ARRAY_SIZE do
  begin
    LSum := LSum + LArray[LI];
    Inc(LI, LStride);
  end;
end;

procedure RunProducerConsumerTest;
var
  LTest: TProducerConsumerTest;
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
begin
  WriteLn('=== 生产者-消费者模式测试 ===');
  WriteLn;
  
  LTest := TProducerConsumerTest.Create(1000, 2000);
  try
    LConfig := CreateDefaultBenchmarkConfig;
    LConfig.WarmupIterations := 1;
    LConfig.MeasureIterations := 3;
    
    WriteLn('运行混合生产者-消费者测试...');
    LResult := RunMultiThreadBenchmark('生产者消费者', @LTest.MixedWork, 4, LConfig);
    
    WriteLn('结果: ', Format('%.2f μs/op', [LResult.GetTimePerIteration(buMicroSeconds)]));
    WriteLn('生产数量: ', LTest.ProducedCount);
    WriteLn('消费数量: ', LTest.ConsumedCount);
    WriteLn('吞吐量: ', Format('%.0f items/s', [LResult.GetThroughput()]));
    
  finally
    LTest.Free;
  end;
end;

procedure RunParallelComputationTest;
var
  LResult1, LResult2: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
begin
  WriteLn;
  WriteLn('=== 并行计算测试 ===');
  WriteLn;
  
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 3;
  
  WriteLn('运行并行矩阵乘法测试...');
  LResult1 := RunMultiThreadBenchmark('并行矩阵乘法', @ParallelMatrixMultiply, 4, LConfig);
  WriteLn('矩阵乘法: ', Format('%.2f ms/op', [LResult1.GetTimePerIteration(buMilliSeconds)]));
  
  WriteLn('运行并行排序测试...');
  LResult2 := RunMultiThreadBenchmark('并行快速排序', @ParallelQuickSort, 4, LConfig);
  WriteLn('并行排序: ', Format('%.2f ms/op', [LResult2.GetTimePerIteration(buMilliSeconds)]));
end;

procedure RunCacheLocalityTest;
var
  LResult1, LResult2: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
begin
  WriteLn;
  WriteLn('=== 缓存局部性测试 ===');
  WriteLn;
  
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 2;
  LConfig.MeasureIterations := 5;
  
  WriteLn('运行缓存友好访问测试...');
  LResult1 := RunMultiThreadBenchmark('缓存友好访问', @CacheFriendlyAccess, 4, LConfig);
  WriteLn('缓存友好: ', Format('%.2f μs/op', [LResult1.GetTimePerIteration(buMicroSeconds)]));
  
  WriteLn('运行缓存不友好访问测试...');
  LResult2 := RunMultiThreadBenchmark('缓存不友好访问', @CacheUnfriendlyAccess, 4, LConfig);
  WriteLn('缓存不友好: ', Format('%.2f μs/op', [LResult2.GetTimePerIteration(buMicroSeconds)]));
  
  var LPerformanceRatio := LResult2.GetTimePerIteration() / LResult1.GetTimePerIteration();
  WriteLn('性能差异: ', Format('%.2fx', [LPerformanceRatio]));
  
  if LPerformanceRatio > 1.5 then
    WriteLn('✅ 缓存局部性对性能有显著影响')
  else
    WriteLn('⚠️ 缓存局部性影响不明显，可能需要更大的数据集');
end;

procedure RunScalabilityAnalysis;
var
  LThreadCounts: array[0..4] of Integer = (1, 2, 4, 8, 16);
  LResults: array[0..4] of IBenchmarkResult;
  LConfig: TBenchmarkConfig;
  LI: Integer;
begin
  WriteLn;
  WriteLn('=== 可扩展性分析 ===');
  WriteLn;
  
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 3;
  
  WriteLn('测试不同线程数量的矩阵乘法性能...');
  WriteLn;
  
  for LI := 0 to High(LThreadCounts) do
  begin
    WriteLn('测试 ', LThreadCounts[LI], ' 个线程...');
    LResults[LI] := RunMultiThreadBenchmark('矩阵乘法-' + IntToStr(LThreadCounts[LI]) + '线程', 
                                           @ParallelMatrixMultiply, LThreadCounts[LI], LConfig);
    WriteLn('  时间: ', Format('%.2f ms/op', [LResults[LI].GetTimePerIteration(buMilliSeconds)]));
  end;
  
  WriteLn;
  WriteLn('可扩展性分析:');
  var LBaseTime := LResults[0].GetTimePerIteration();
  for LI := 1 to High(LResults) do
  begin
    var LSpeedup := LBaseTime / LResults[LI].GetTimePerIteration();
    var LEfficiency := LSpeedup / LThreadCounts[LI] * 100;
    var LIdealSpeedup := Min(LThreadCounts[LI], 4.0); // 假设4核CPU
    var LScalability := LSpeedup / LIdealSpeedup * 100;
    
    WriteLn('  ', LThreadCounts[LI], ' 线程:');
    WriteLn('    加速比: ', Format('%.2fx', [LSpeedup]));
    WriteLn('    效率: ', Format('%.1f%%', [LEfficiency]));
    WriteLn('    可扩展性: ', Format('%.1f%%', [LScalability]));
  end;
end;

begin
  WriteLn('========================================');
  WriteLn('高级多线程基准测试示例');
  WriteLn('========================================');
  WriteLn;
  
  Randomize;
  
  try
    RunProducerConsumerTest;
    RunParallelComputationTest;
    RunCacheLocalityTest;
    RunScalabilityAnalysis;
    
    WriteLn;
    WriteLn('========================================');
    WriteLn('高级多线程测试完成！');
    WriteLn('========================================');
    
  except
    on E: Exception do
    begin
      WriteLn('示例运行出错: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
