program example_batch_testing;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.benchmark;

// 批量测试和报告生成示例

// 不同的排序算法实现
procedure BubbleSort(aState: IBenchmarkState);
var
  LArray: array[0..999] of Integer;
  LI, LJ, LTemp: Integer;
begin
  while aState.KeepRunning do
  begin
    aState.PauseTiming;
    // 初始化数组
    for LI := 0 to 999 do
      LArray[LI] := Random(10000);
    aState.ResumeTiming;
    
    // 冒泡排序
    for LI := 0 to 998 do
      for LJ := 0 to 998 - LI do
        if LArray[LJ] > LArray[LJ + 1] then
        begin
          LTemp := LArray[LJ];
          LArray[LJ] := LArray[LJ + 1];
          LArray[LJ + 1] := LTemp;
        end;
    
    aState.SetItemsProcessed(1000);
  end;
end;

procedure SelectionSort(aState: IBenchmarkState);
var
  LArray: array[0..999] of Integer;
  LI, LJ, LMinIdx, LTemp: Integer;
begin
  while aState.KeepRunning do
  begin
    aState.PauseTiming;
    // 初始化数组
    for LI := 0 to 999 do
      LArray[LI] := Random(10000);
    aState.ResumeTiming;
    
    // 选择排序
    for LI := 0 to 998 do
    begin
      LMinIdx := LI;
      for LJ := LI + 1 to 999 do
        if LArray[LJ] < LArray[LMinIdx] then
          LMinIdx := LJ;
      
      if LMinIdx <> LI then
      begin
        LTemp := LArray[LI];
        LArray[LI] := LArray[LMinIdx];
        LArray[LMinIdx] := LTemp;
      end;
    end;
    
    aState.SetItemsProcessed(1000);
  end;
end;

procedure InsertionSort(aState: IBenchmarkState);
var
  LArray: array[0..999] of Integer;
  LI, LJ, LKey: Integer;
begin
  while aState.KeepRunning do
  begin
    aState.PauseTiming;
    // 初始化数组
    for LI := 0 to 999 do
      LArray[LI] := Random(10000);
    aState.ResumeTiming;
    
    // 插入排序
    for LI := 1 to 999 do
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
    
    aState.SetItemsProcessed(1000);
  end;
end;

procedure QuickSort(aState: IBenchmarkState);
var
  LArray: array[0..999] of Integer;
  LI: Integer;
  
  procedure QSort(var aArray: array of Integer; aLow, aHigh: Integer);
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
      
      QSort(aArray, aLow, LI);
      QSort(aArray, LI + 2, aHigh);
    end;
  end;
  
begin
  while aState.KeepRunning do
  begin
    aState.PauseTiming;
    // 初始化数组
    for LI := 0 to 999 do
      LArray[LI] := Random(10000);
    aState.ResumeTiming;
    
    // 快速排序
    QSort(LArray, 0, 999);
    
    aState.SetItemsProcessed(1000);
  end;
end;

procedure DemonstrateBatchComparison;
var
  LFunctions: array[0..3] of TBenchmarkFunction;
  LNames: array[0..3] of string;
  LComparisons: array of TBenchmarkComparison;
  LConfig: TBenchmarkConfig;
  LI: Integer;
begin
  WriteLn('=== 批量对比测试演示 ===');
  WriteLn;
  
  // 设置测试函数和名称
  LFunctions[0] := @BubbleSort;
  LFunctions[1] := @SelectionSort;
  LFunctions[2] := @InsertionSort;
  LFunctions[3] := @QuickSort;
  
  LNames[0] := '冒泡排序';
  LNames[1] := '选择排序';
  LNames[2] := '插入排序';
  LNames[3] := '快速排序';
  
  // 配置测试参数
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 3;
  LConfig.MinDurationMs := 100;
  
  WriteLn('运行批量对比测试...');
  WriteLn('测试配置: 预热 ', LConfig.WarmupIterations, ' 次, 测量 ', LConfig.MeasureIterations, ' 次');
  WriteLn;
  
  // 运行批量对比
  LComparisons := RunBatchComparison(LFunctions, LNames, LConfig);
  
  WriteLn('对比结果:');
  WriteLn('========================================');
  
  for LI := 0 to High(LComparisons) do
  begin
    WriteLn('对比 ', LI + 1, ': ', LComparisons[LI].Name1, ' vs ', LComparisons[LI].Name2);
    WriteLn('  结论: ', LComparisons[LI].Conclusion);
    WriteLn('  相对差异: ', Format('%.2f%%', [LComparisons[LI].RelativeDifference * 100]));
    WriteLn('  显著性: ', Format('%.2f', [LComparisons[LI].Significance]));
    WriteLn('  ', LComparisons[LI].Name1, ' 时间: ', 
            Format('%.2f ms/op', [LComparisons[LI].Result1.GetTimePerIteration(buMilliSeconds)]));
    WriteLn('  ', LComparisons[LI].Name2, ' 时间: ', 
            Format('%.2f ms/op', [LComparisons[LI].Result2.GetTimePerIteration(buMilliSeconds)]));
    WriteLn;
  end;
end;

procedure DemonstrateSuiteReporting;
var
  LSuite: IBenchmarkSuite;
  LReport: TBenchmarkReport;
  LConfig: TBenchmarkConfig;
begin
  WriteLn('=== 套件报告生成演示 ===');
  WriteLn;
  
  // 创建测试套件
  LSuite := CreateBenchmarkSuite;
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 3;
  
  // 添加测试
  LSuite.AddBenchmark(CreateBenchmark('冒泡排序', @BubbleSort, LConfig));
  LSuite.AddBenchmark(CreateBenchmark('选择排序', @SelectionSort, LConfig));
  LSuite.AddBenchmark(CreateBenchmark('插入排序', @InsertionSort, LConfig));
  LSuite.AddBenchmark(CreateBenchmark('快速排序', @QuickSort, LConfig));
  
  WriteLn('生成综合报告...');
  
  // 生成报告
  LReport := LSuite.GenerateReport('排序算法性能对比报告');
  
  WriteLn('报告信息:');
  WriteLn('  标题: ', LReport.Title);
  WriteLn('  生成时间: ', DateTimeToStr(LReport.GeneratedAt));
  WriteLn('  摘要: ', LReport.Summary);
  WriteLn('  测试数量: ', Length(LReport.Results));
  WriteLn('  对比数量: ', Length(LReport.Comparisons));
  WriteLn;
  
  // 显示详细结果
  WriteLn('详细测试结果:');
  WriteLn('----------------------------------------');
  for var LI := 0 to High(LReport.Results) do
  begin
    WriteLn('测试 ', LI + 1, ': ', LReport.Results[LI].Name);
    WriteLn('  平均时间: ', Format('%.2f ms/op', [LReport.Results[LI].GetTimePerIteration(buMilliSeconds)]));
    WriteLn('  吞吐量: ', Format('%.0f ops/s', [LReport.Results[LI].GetThroughput()]));
    WriteLn('  迭代次数: ', LReport.Results[LI].Iterations);
  end;
  WriteLn;
  
  // 显示对比结果
  if Length(LReport.Comparisons) > 0 then
  begin
    WriteLn('性能对比结果:');
    WriteLn('----------------------------------------');
    for var LI := 0 to High(LReport.Comparisons) do
    begin
      WriteLn('对比 ', LI + 1, ': ', LReport.Comparisons[LI].Conclusion);
      WriteLn('  相对差异: ', Format('%.1f%%', [LReport.Comparisons[LI].RelativeDifference * 100]));
    end;
    WriteLn;
  end;
  
  // 显示建议
  if Length(LReport.Recommendations) > 0 then
  begin
    WriteLn('优化建议:');
    WriteLn('----------------------------------------');
    for var LI := 0 to High(LReport.Recommendations) do
      WriteLn('  • ', LReport.Recommendations[LI]);
    WriteLn;
  end;
  
  // 生成 HTML 报告
  WriteLn('生成 HTML 报告...');
  GenerateHTMLReport(LReport, 'sorting_algorithms_report.html');
  WriteLn('HTML 报告已保存到: sorting_algorithms_report.html');
  WriteLn;
end;

procedure DemonstrateTrendAnalysis;
var
  LSuite: IBenchmarkSuite;
  LTrend: TBenchmarkTrend;
  LHistoricalData: array[0..0] of TBenchmarkTrend;
  LResults: TBenchmarkResultArray;
  LConfig: TBenchmarkConfig;
begin
  WriteLn('=== 趋势分析演示 ===');
  WriteLn;
  
  // 创建模拟的历史数据
  LTrend.TestName := '快速排序';
  SetLength(LTrend.Timestamps, 3);
  SetLength(LTrend.Values, 3);
  
  LTrend.Timestamps[0] := Now - 2;  // 2天前
  LTrend.Timestamps[1] := Now - 1;  // 1天前
  LTrend.Timestamps[2] := Now;      // 今天
  
  LTrend.Values[0] := 1500000;  // 1.5ms (纳秒)
  LTrend.Values[1] := 1600000;  // 1.6ms
  LTrend.Values[2] := 1700000;  // 1.7ms
  
  LTrend.TrendDirection := 1;   // 上升趋势（性能下降）
  LTrend.TrendStrength := 0.8;  // 强趋势
  
  LHistoricalData[0] := LTrend;
  
  WriteLn('模拟历史数据:');
  WriteLn('  测试名称: ', LTrend.TestName);
  WriteLn('  历史数据点: ', Length(LTrend.Values));
  WriteLn('  趋势方向: ', IIF(LTrend.TrendDirection > 0, '上升(性能下降)', 
                              IIF(LTrend.TrendDirection < 0, '下降(性能提升)', '稳定')));
  WriteLn('  趋势强度: ', Format('%.1f', [LTrend.TrendStrength]));
  WriteLn;
  
  // 保存趋势数据
  WriteLn('保存趋势数据到文件...');
  SaveTrendData(LTrend, 'quicksort_trend.txt');
  WriteLn('趋势数据已保存到: quicksort_trend.txt');
  WriteLn;
  
  // 加载趋势数据验证
  WriteLn('验证趋势数据加载...');
  var LLoadedTrend := LoadTrendData('quicksort_trend.txt');
  WriteLn('  加载的测试名称: ', LLoadedTrend.TestName);
  WriteLn('  加载的数据点: ', Length(LLoadedTrend.Values));
  WriteLn;
  
  // 创建测试套件并运行趋势分析
  LSuite := CreateBenchmarkSuite;
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 2;
  
  LSuite.AddBenchmark(CreateBenchmark('快速排序', @QuickSort, LConfig));
  
  WriteLn('运行趋势分析...');
  LResults := LSuite.RunWithTrendAnalysis(LHistoricalData);
  
  WriteLn('当前测试结果:');
  if Length(LResults) > 0 then
  begin
    WriteLn('  当前时间: ', Format('%.2f ms/op', [LResults[0].GetTimePerIteration(buMilliSeconds)]));
    WriteLn('  历史对比: 基于历史数据进行了趋势分析');
  end;
  WriteLn;
end;

begin
  WriteLn('========================================');
  WriteLn('批量测试和报告生成示例');
  WriteLn('========================================');
  WriteLn;
  
  Randomize;
  
  try
    DemonstrateBatchComparison;
    DemonstrateSuiteReporting;
    DemonstrateTrendAnalysis;
    
    WriteLn('========================================');
    WriteLn('批量测试演示完成！');
    WriteLn('========================================');
    WriteLn;
    WriteLn('生成的文件:');
    WriteLn('  • sorting_algorithms_report.html - HTML 格式的详细报告');
    WriteLn('  • quicksort_trend.txt - 趋势数据文件');
    WriteLn;
    WriteLn('新功能总结:');
    WriteLn('✅ 批量对比测试 - 一次性对比多个算法的性能');
    WriteLn('✅ 综合报告生成 - 自动生成包含对比和建议的报告');
    WriteLn('✅ HTML 报告导出 - 生成美观的 HTML 格式报告');
    WriteLn('✅ 趋势数据管理 - 保存和加载历史性能数据');
    WriteLn('✅ 趋势分析 - 基于历史数据分析性能变化');
    
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
