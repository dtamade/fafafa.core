program example_algorithm_comparison;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.benchmark;

// 测试不同排序算法的性能对比

// 冒泡排序
procedure BenchmarkBubbleSort(aState: IBenchmarkState);
var
  LArray: array[0..999] of Integer;
  LI, LJ, LTemp: Integer;
begin
  // 初始化数组
  for LI := 0 to High(LArray) do
    LArray[LI] := Random(10000);
    
  while aState.KeepRunning do
  begin
    // 冒泡排序算法
    for LI := 0 to High(LArray) - 1 do
      for LJ := 0 to High(LArray) - LI - 1 do
        if LArray[LJ] > LArray[LJ + 1] then
        begin
          LTemp := LArray[LJ];
          LArray[LJ] := LArray[LJ + 1];
          LArray[LJ + 1] := LTemp;
        end;
    
    // 设置处理的项目数
    aState.SetItemsProcessed(Length(LArray));
  end;
end;

// 快速排序
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

procedure BenchmarkQuickSort(aState: IBenchmarkState);
var
  LArray: array[0..999] of Integer;
  LI: Integer;
begin
  while aState.KeepRunning do
  begin
    // 暂停计时进行数组初始化
    aState.PauseTiming;
    for LI := 0 to High(LArray) do
      LArray[LI] := Random(10000);
    aState.ResumeTiming;
    
    // 快速排序算法
    QuickSort(LArray, 0, High(LArray));
    
    // 设置处理的项目数
    aState.SetItemsProcessed(Length(LArray));
  end;
end;

// 选择排序
procedure BenchmarkSelectionSort(aState: IBenchmarkState);
var
  LArray: array[0..999] of Integer;
  LI, LJ, LMinIdx, LTemp: Integer;
begin
  // 初始化数组
  for LI := 0 to High(LArray) do
    LArray[LI] := Random(10000);
    
  while aState.KeepRunning do
  begin
    // 选择排序算法
    for LI := 0 to High(LArray) - 1 do
    begin
      LMinIdx := LI;
      for LJ := LI + 1 to High(LArray) do
        if LArray[LJ] < LArray[LMinIdx] then
          LMinIdx := LJ;
      
      if LMinIdx <> LI then
      begin
        LTemp := LArray[LI];
        LArray[LI] := LArray[LMinIdx];
        LArray[LMinIdx] := LTemp;
      end;
    end;
    
    // 设置处理的项目数
    aState.SetItemsProcessed(Length(LArray));
  end;
end;

// 插入排序
procedure BenchmarkInsertionSort(aState: IBenchmarkState);
var
  LArray: array[0..999] of Integer;
  LI, LJ, LKey: Integer;
begin
  // 初始化数组
  for LI := 0 to High(LArray) do
    LArray[LI] := Random(10000);
    
  while aState.KeepRunning do
  begin
    // 插入排序算法
    for LI := 1 to High(LArray) do
    begin
      LKey := LArray[LI];
      LJ := LI - 1;
      
      while (LJ >= 0) and (LArray[LJ] > LKey) do
      begin
        LArray[LJ + 1] := LArray[LJ];
        Dec(LJ);
      end;
      
      LArray[LJ + 1] := LKey;
    end;
    
    // 设置处理的项目数
    aState.SetItemsProcessed(Length(LArray));
  end;
end;

procedure RunAlgorithmComparison;
var
  LSuite: IBenchmarkSuite;
  LReporter: IBenchmarkReporter;
  LResults: TBenchmarkResultArray;
  LConfig: TBenchmarkConfig;
  LI: Integer;
begin
  WriteLn('=== 排序算法性能对比 ===');
  WriteLn('数组大小: 1000 个整数');
  WriteLn;
  
  // 创建套件和配置
  LSuite := CreateBenchmarkSuite;
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 2;
  LConfig.MeasureIterations := 5;
  LConfig.MinDurationMs := 500;
  
  // 添加不同的排序算法
  LSuite.AddBenchmark(CreateLegacyBenchmark('冒泡排序', @BenchmarkBubbleSort, LConfig));
  LSuite.AddBenchmark(CreateLegacyBenchmark('快速排序', @BenchmarkQuickSort, LConfig));
  LSuite.AddBenchmark(CreateLegacyBenchmark('选择排序', @BenchmarkSelectionSort, LConfig));
  LSuite.AddBenchmark(CreateLegacyBenchmark('插入排序', @BenchmarkInsertionSort, LConfig));
  
  WriteLn('开始运行 ', LSuite.Count, ' 个排序算法基准测试...');
  WriteLn;
  
  // 运行所有测试
  LReporter := CreateConsoleReporter;
  LResults := LSuite.RunAllWithReporter(LReporter);
  
  WriteLn;
  WriteLn('=== 性能对比总结 ===');
  
  // 找出最快的算法
  var LFastestIdx: Integer := 0;
  var LFastestTime: Double := LResults[0].GetTimePerIteration();
  
  for LI := 1 to High(LResults) do
    if LResults[LI].GetTimePerIteration() < LFastestTime then
    begin
      LFastestIdx := LI;
      LFastestTime := LResults[LI].GetTimePerIteration();
    end;
  
  WriteLn('最快算法: ', LResults[LFastestIdx].Name);
  WriteLn('最快时间: ', Format('%.2f ns/op', [LFastestTime]));
  WriteLn;
  
  // 显示相对性能
  WriteLn('相对性能 (以最快算法为基准):');
  for LI := 0 to High(LResults) do
  begin
    var LRelativeSpeed: Double := LResults[LI].GetTimePerIteration() / LFastestTime;
    WriteLn('  ', LResults[LI].Name, ': ', Format('%.2fx', [LRelativeSpeed]));
  end;
  
  WriteLn;
  WriteLn('吞吐量对比 (items/sec):');
  for LI := 0 to High(LResults) do
    WriteLn('  ', LResults[LI].Name, ': ', Format('%.0f items/sec', [LResults[LI].GetItemsPerSecond]));
end;

procedure SaveDetailedReport;
var
  LRunner: IBenchmarkRunner;
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
  LJSONReporter: IBenchmarkReporter;
  LCSVReporter: IBenchmarkReporter;
begin
  WriteLn;
  WriteLn('=== 保存详细报告 ===');
  
  LRunner := CreateBenchmarkRunner;
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 3;
  LConfig.MeasureIterations := 10;
  
  // 运行快速排序的详细测试
  LResult := LRunner.RunFunction('快速排序详细测试', @BenchmarkQuickSort, LConfig);
  
  // 保存 JSON 报告
  LJSONReporter := CreateJSONReporter('algorithm_comparison.json');
  LJSONReporter.ReportResult(LResult);
  WriteLn('JSON 报告已保存到: algorithm_comparison.json');
  
  // 保存 CSV 报告
  LCSVReporter := CreateCSVReporter('algorithm_comparison.csv');
  LCSVReporter.ReportResult(LResult);
  WriteLn('CSV 报告已保存到: algorithm_comparison.csv');
end;

begin
  WriteLn('========================================');
  WriteLn('算法性能对比示例');
  WriteLn('========================================');
  WriteLn;
  
  // 初始化随机数种子
  Randomize;
  
  try
    RunAlgorithmComparison;
    SaveDetailedReport;
    
    WriteLn;
    WriteLn('========================================');
    WriteLn('示例完成！');
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
