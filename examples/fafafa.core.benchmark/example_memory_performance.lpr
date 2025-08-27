program example_memory_performance;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.benchmark;

// 测试不同内存分配策略的性能

// 频繁小内存分配
procedure BenchmarkSmallAllocations(aState: IBenchmarkState);
var
  LPtrs: array[0..99] of Pointer;
  LI: Integer;
begin
  while aState.KeepRunning do
  begin
    // 分配 100 个小内存块
    for LI := 0 to High(LPtrs) do
      GetMem(LPtrs[LI], 64); // 64 字节
    
    // 释放内存
    for LI := 0 to High(LPtrs) do
      FreeMem(LPtrs[LI]);
    
    // 设置处理的字节数
    aState.SetBytesProcessed(Length(LPtrs) * 64);
  end;
end;

// 大内存块分配
procedure BenchmarkLargeAllocations(aState: IBenchmarkState);
var
  LPtr: Pointer;
  LSize: Integer;
begin
  LSize := 1024 * 1024; // 1MB
  
  while aState.KeepRunning do
  begin
    // 分配大内存块
    GetMem(LPtr, LSize);
    
    // 简单的内存访问
    FillChar(LPtr^, LSize, $AA);
    
    // 释放内存
    FreeMem(LPtr);
    
    // 设置处理的字节数
    aState.SetBytesProcessed(LSize);
  end;
end;

// 内存复制性能测试
procedure BenchmarkMemoryCopy(aState: IBenchmarkState);
var
  LSrc, LDst: Pointer;
  LSize: Integer;
begin
  LSize := 64 * 1024; // 64KB
  GetMem(LSrc, LSize);
  GetMem(LDst, LSize);
  
  try
    // 初始化源数据
    FillChar(LSrc^, LSize, $55);
    
    while aState.KeepRunning do
    begin
      // 内存复制
      Move(LSrc^, LDst^, LSize);
      
      // 设置处理的字节数
      aState.SetBytesProcessed(LSize);
    end;
    
  finally
    FreeMem(LSrc);
    FreeMem(LDst);
  end;
end;

// 内存填充性能测试
procedure BenchmarkMemoryFill(aState: IBenchmarkState);
var
  LPtr: Pointer;
  LSize: Integer;
begin
  LSize := 128 * 1024; // 128KB
  GetMem(LPtr, LSize);
  
  try
    while aState.KeepRunning do
    begin
      // 内存填充
      FillChar(LPtr^, LSize, $FF);
      
      // 设置处理的字节数
      aState.SetBytesProcessed(LSize);
    end;
    
  finally
    FreeMem(LPtr);
  end;
end;

// 字符串操作内存测试
procedure BenchmarkStringOperations(aState: IBenchmarkState);
var
  LStr: string;
  LI: Integer;
begin
  while aState.KeepRunning do
  begin
    LStr := '';
    
    // 字符串连接
    for LI := 1 to 1000 do
      LStr := LStr + IntToStr(LI);
    
    // 设置处理的字节数
    aState.SetBytesProcessed(Length(LStr));
    
    // 添加自定义计数器
    aState.AddCounter('字符串长度', Length(LStr), cuBytes);
    aState.AddCounter('连接次数', 1000, cuItems);
  end;
end;

// 动态数组操作测试
procedure BenchmarkDynamicArrays(aState: IBenchmarkState);
var
  LArray: array of Integer;
  LI: Integer;
begin
  while aState.KeepRunning do
  begin
    // 动态分配数组
    SetLength(LArray, 10000);
    
    // 填充数据
    for LI := 0 to High(LArray) do
      LArray[LI] := LI;
    
    // 设置处理的字节数和项目数
    aState.SetBytesProcessed(Length(LArray) * SizeOf(Integer));
    aState.SetItemsProcessed(Length(LArray));
    
    // 清理
    SetLength(LArray, 0);
  end;
end;

procedure RunMemoryPerformanceTests;
var
  LSuite: IBenchmarkSuite;
  LReporter: IBenchmarkReporter;
  LResults: TBenchmarkResultArray;
  LConfig: TBenchmarkConfig;
  LI: Integer;
begin
  WriteLn('=== 内存性能测试 ===');
  WriteLn;
  
  // 创建套件和配置
  LSuite := CreateBenchmarkSuite;
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 3;
  LConfig.MeasureIterations := 5;
  LConfig.MinDurationMs := 200;
  LConfig.EnableMemoryMeasurement := True; // 启用内存测量
  
  // 添加内存测试
  LSuite.AddBenchmark(CreateLegacyBenchmark('小内存分配', @BenchmarkSmallAllocations, LConfig));
  LSuite.AddBenchmark(CreateLegacyBenchmark('大内存分配', @BenchmarkLargeAllocations, LConfig));
  LSuite.AddBenchmark(CreateLegacyBenchmark('内存复制', @BenchmarkMemoryCopy, LConfig));
  LSuite.AddBenchmark(CreateLegacyBenchmark('内存填充', @BenchmarkMemoryFill, LConfig));
  LSuite.AddBenchmark(CreateLegacyBenchmark('字符串操作', @BenchmarkStringOperations, LConfig));
  LSuite.AddBenchmark(CreateLegacyBenchmark('动态数组', @BenchmarkDynamicArrays, LConfig));
  
  WriteLn('开始运行 ', LSuite.Count, ' 个内存性能测试...');
  WriteLn;
  
  // 运行所有测试
  LReporter := CreateConsoleReporter;
  LResults := LSuite.RunAllWithReporter(LReporter);
  
  WriteLn;
  WriteLn('=== 内存性能分析 ===');
  
  // 分析内存吞吐量
  WriteLn('内存吞吐量排名:');
  for LI := 0 to High(LResults) do
  begin
    var LThroughputMBps: Double := LResults[LI].GetBytesPerSecond / 1024 / 1024;
    WriteLn('  ', LResults[LI].Name, ': ', Format('%.2f MB/s', [LThroughputMBps]));
  end;
  
  WriteLn;
  WriteLn('操作效率排名:');
  for LI := 0 to High(LResults) do
  begin
    var LTimePerOp: Double := LResults[LI].GetTimePerIteration(buMicroSeconds);
    WriteLn('  ', LResults[LI].Name, ': ', Format('%.2f μs/op', [LTimePerOp]));
  end;
end;

procedure TestMemoryMeasurement;
var
  LRunner: IBenchmarkRunner;
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
  LReporter: IBenchmarkReporter;
begin
  WriteLn;
  WriteLn('=== 内存使用量测试 ===');
  
  LRunner := CreateBenchmarkRunner;
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 3;
  LConfig.EnableMemoryMeasurement := True;
  
  // 测试大内存分配的内存使用情况
  LResult := LRunner.RunFunction('内存使用测试', @BenchmarkLargeAllocations, LConfig);
  
  LReporter := CreateConsoleReporter;
  LReporter.ReportResult(LResult);
  
  WriteLn;
  WriteLn('内存使用分析:');
  WriteLn('  当前内存使用: ', LResult.Statistics.Mean, ' bytes');
  WriteLn('  峰值内存使用: ', LResult.Statistics.Max, ' bytes');
end;

procedure SaveMemoryReport;
var
  LRunner: IBenchmarkRunner;
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
  LJSONReporter: IBenchmarkReporter;
begin
  WriteLn;
  WriteLn('=== 保存内存性能报告 ===');
  
  LRunner := CreateBenchmarkRunner;
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 2;
  LConfig.MeasureIterations := 8;
  LConfig.EnableMemoryMeasurement := True;
  
  // 运行详细的内存复制测试
  LResult := LRunner.RunFunction('内存复制详细测试', @BenchmarkMemoryCopy, LConfig);
  
  // 保存详细报告
  LJSONReporter := CreateJSONReporter('memory_performance.json');
  LJSONReporter.ReportResult(LResult);
  WriteLn('内存性能报告已保存到: memory_performance.json');
end;

begin
  WriteLn('========================================');
  WriteLn('内存性能测试示例');
  WriteLn('========================================');
  WriteLn;
  
  try
    RunMemoryPerformanceTests;
    TestMemoryMeasurement;
    SaveMemoryReport;
    
    WriteLn;
    WriteLn('========================================');
    WriteLn('内存性能测试完成！');
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
