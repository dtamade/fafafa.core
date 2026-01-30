program example_enhanced_features;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.benchmark;

// 演示增强功能的示例程序

// 快速操作
procedure FastOperation(aState: IBenchmarkState);
var
  LI: Integer;
  LSum: Integer;
begin
  while aState.KeepRunning do
  begin
    LSum := 0;
    for LI := 1 to 10 do
      LSum := LSum + LI;
    aState.SetItemsProcessed(10);
  end;
end;

// 中等速度操作
procedure MediumOperation(aState: IBenchmarkState);
var
  LI, LJ: Integer;
  LSum: Integer;
begin
  while aState.KeepRunning do
  begin
    LSum := 0;
    for LI := 1 to 100 do
      for LJ := 1 to 10 do
        LSum := LSum + LI * LJ;
    aState.SetItemsProcessed(1000);
  end;
end;

// 慢速操作
procedure SlowOperation(aState: IBenchmarkState);
var
  LI, LJ, LK: Integer;
  LSum: Integer;
begin
  while aState.KeepRunning do
  begin
    LSum := 0;
    for LI := 1 to 50 do
      for LJ := 1 to 50 do
        for LK := 1 to 10 do
          LSum := LSum + LI * LJ * LK;
    aState.SetItemsProcessed(25000);
  end;
end;

// 参数化测试函数
procedure ParameterizedSortTest(aState: IBenchmarkState; const aParameters: array of Variant);
var
  LArray: array of Integer;
  LSize: Integer;
  LI, LJ, LTemp: Integer;
begin
  if Length(aParameters) = 0 then
    raise EArgumentError.Create('需要数组大小参数');
  
  LSize := aParameters[0];
  SetLength(LArray, LSize);
  
  while aState.KeepRunning do
  begin
    aState.PauseTiming;
    // 初始化数组
    for LI := 0 to LSize - 1 do
      LArray[LI] := Random(10000);
    aState.ResumeTiming;
    
    // 冒泡排序
    for LI := 0 to LSize - 2 do
      for LJ := 0 to LSize - LI - 2 do
        if LArray[LJ] > LArray[LJ + 1] then
        begin
          LTemp := LArray[LJ];
          LArray[LJ] := LArray[LJ + 1];
          LArray[LJ + 1] := LTemp;
        end;
    
    aState.SetItemsProcessed(LSize);
  end;
end;

procedure DemonstrateSmartConfigRecommendation;
var
  LRecommendations: array[0..2] of TBenchmarkRecommendation;
  LOperations: array[0..2] of TBenchmarkFunction = (@FastOperation, @MediumOperation, @SlowOperation);
  LNames: array[0..2] of string = ('快速操作', '中等操作', '慢速操作');
  LI: Integer;
begin
  WriteLn('=== 智能配置推荐演示 ===');
  WriteLn;
  
  for LI := 0 to 2 do
  begin
    WriteLn(LI + 1, '. ', LNames[LI], ':');
    
    LRecommendations[LI] := RecommendConfig(LOperations[LI]);
    
    WriteLn('   推荐置信度: ', Format('%.1f%%', [LRecommendations[LI].Confidence * 100]));
    WriteLn('   推荐理由: ', LRecommendations[LI].Reasoning);
    WriteLn('   推荐配置:');
    WriteLn('     预热次数: ', LRecommendations[LI].RecommendedConfig.WarmupIterations);
    WriteLn('     测量次数: ', LRecommendations[LI].RecommendedConfig.MeasureIterations);
    WriteLn('     最小时间: ', LRecommendations[LI].RecommendedConfig.MinDurationMs, ' ms');
    WriteLn;
  end;
end;

procedure DemonstrateStatisticalAnalysis;
var
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
  LLowerBound, LUpperBound: Double;
begin
  WriteLn('=== 统计分析演示 ===');
  WriteLn;
  
  // 使用较多的迭代次数来获得更好的统计数据
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 3;
  LConfig.MeasureIterations := 20; // 增加迭代次数
  
  LResult := RunFunction('统计分析测试', @MediumOperation, LConfig);
  
  WriteLn('基本统计信息:');
  WriteLn('  平均时间: ', Format('%.2f μs/op', [LResult.GetTimePerIteration(buMicroSeconds)]));
  WriteLn('  标准差: ', Format('%.2f μs', [LResult.Statistics.StdDev / 1000]));
  WriteLn('  最小值: ', Format('%.2f μs', [LResult.Statistics.Min / 1000]));
  WriteLn('  最大值: ', Format('%.2f μs', [LResult.Statistics.Max / 1000]));
  WriteLn('  样本数: ', LResult.Statistics.SampleCount);
  WriteLn;
  
  WriteLn('百分位数分析:');
  WriteLn('  P25: ', Format('%.2f μs', [LResult.GetPercentile(25) / 1000]));
  WriteLn('  P50 (中位数): ', Format('%.2f μs', [LResult.GetPercentile(50) / 1000]));
  WriteLn('  P75: ', Format('%.2f μs', [LResult.GetPercentile(75) / 1000]));
  WriteLn('  P90: ', Format('%.2f μs', [LResult.GetPercentile(90) / 1000]));
  WriteLn('  P95: ', Format('%.2f μs', [LResult.GetPercentile(95) / 1000]));
  WriteLn('  P99: ', Format('%.2f μs', [LResult.GetPercentile(99) / 1000]));
  WriteLn;
  
  WriteLn('置信区间:');
  LResult.GetConfidenceInterval(0.95, LLowerBound, LUpperBound);
  WriteLn('  95% 置信区间: [', Format('%.2f', [LLowerBound / 1000]), ', ', 
          Format('%.2f', [LUpperBound / 1000]), '] μs');
  
  LResult.GetConfidenceInterval(0.99, LLowerBound, LUpperBound);
  WriteLn('  99% 置信区间: [', Format('%.2f', [LLowerBound / 1000]), ', ', 
          Format('%.2f', [LUpperBound / 1000]), '] μs');
  WriteLn;
end;

procedure DemonstrateBaselineComparison;
var
  LBaselineResult, LCurrentResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
  LBaseline: TBenchmarkBaseline;
  LComparison: Double;
begin
  WriteLn('=== 基线对比演示 ===');
  WriteLn;
  
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 2;
  LConfig.MeasureIterations := 5;
  
  // 建立基线
  WriteLn('1. 建立性能基线...');
  LBaselineResult := RunFunction('基线测试', @MediumOperation, LConfig);
  
  LBaseline := CreateBaseline('中等操作基线', 
                             LBaselineResult.GetTimePerIteration(), 
                             0.1, // 10% 容忍度
                             '中等复杂度操作的性能基线');
  
  WriteLn('   基线时间: ', Format('%.2f μs/op', [LBaseline.BaselineTime / 1000]));
  WriteLn('   容忍度: ', Format('%.1f%%', [LBaseline.Tolerance * 100]));
  WriteLn('   描述: ', LBaseline.Description);
  WriteLn;
  
  // 模拟不同的性能情况
  WriteLn('2. 性能对比测试...');
  
  // 正常情况
  LCurrentResult := RunFunction('当前测试', @MediumOperation, LConfig);
  LComparison := LCurrentResult.CompareWithBaseline(LBaseline);
  
  WriteLn('   当前测试结果:');
  WriteLn('     时间: ', Format('%.2f μs/op', [LCurrentResult.GetTimePerIteration(buMicroSeconds)]));
  WriteLn('     与基线对比: ', Format('%.2f%%', [LComparison * 100]), 
          IIF(LComparison > 0, ' (比基线慢)', ' (比基线快)'));
  
  if LCurrentResult.IsRegressionFrom(LBaseline) then
    WriteLn('     状态: ⚠️ 性能回归！')
  else
    WriteLn('     状态: ✅ 性能正常');
  WriteLn;
  
  // 结果直接对比
  WriteLn('3. 结果直接对比:');
  var LDirectComparison := CompareResults(LBaselineResult, LCurrentResult);
  WriteLn('   相对性能差异: ', Format('%.2f%%', [LDirectComparison * 100]));
  
  if Abs(LDirectComparison) < 0.02 then
    WriteLn('   结论: 📊 性能基本一致')
  else if LDirectComparison > 0 then
    WriteLn('   结论: 📈 当前测试比基线快')
  else
    WriteLn('   结论: 📉 当前测试比基线慢');
  WriteLn;
end;

procedure DemonstrateParameterizedTesting;
var
  LTestCases: TParameterizedTestCases;
  LI: Integer;
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
begin
  WriteLn('=== 参数化测试演示 ===');
  WriteLn;
  
  // 创建参数化测试用例
  SetLength(LTestCases, 4);
  LTestCases[0] := CreateParameterizedTestCase('小数组排序', [100]);
  LTestCases[1] := CreateParameterizedTestCase('中数组排序', [500]);
  LTestCases[2] := CreateParameterizedTestCase('大数组排序', [1000]);
  LTestCases[3] := CreateParameterizedTestCase('超大数组排序', [2000]);
  
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 3;
  
  WriteLn('运行参数化排序测试:');
  WriteLn;
  
  for LI := 0 to High(LTestCases) do
  begin
    WriteLn('测试 ', LI + 1, ': ', LTestCases[LI].Name);
    WriteLn('  参数: 数组大小 = ', Integer(LTestCases[LI].Parameters[0]));
    
    // 注意：这里需要一个包装函数来调用参数化测试
    // 由于当前实现的限制，我们暂时跳过实际执行
    WriteLn('  状态: 参数化测试框架演示（实际执行需要包装函数）');
    WriteLn;
  end;
  
  WriteLn('参数化测试用例创建成功！');
  WriteLn('提示: 完整的参数化测试需要额外的包装机制。');
  WriteLn;
end;

procedure DemonstratePerformanceRegression;
var
  LGoodResult, LBadResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
  LBaseline: TBenchmarkBaseline;
begin
  WriteLn('=== 性能回归检测演示 ===');
  WriteLn;
  
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 2;
  LConfig.MeasureIterations := 5;
  
  // 建立"好"的基线
  WriteLn('1. 建立快速操作基线...');
  LGoodResult := RunFunction('快速基线', @FastOperation, LConfig);
  
  LBaseline := CreateBaseline('快速操作基线', 
                             LGoodResult.GetTimePerIteration(), 
                             0.05, // 5% 严格容忍度
                             '快速操作的严格性能基线');
  
  WriteLn('   基线时间: ', Format('%.2f ns/op', [LBaseline.BaselineTime]));
  WriteLn('   严格容忍度: ', Format('%.1f%%', [LBaseline.Tolerance * 100]));
  WriteLn;
  
  // 测试"坏"的性能（使用慢速操作模拟回归）
  WriteLn('2. 检测性能回归...');
  LBadResult := RunFunction('可能回归的测试', @MediumOperation, LConfig);
  
  var LComparison := LBadResult.CompareWithBaseline(LBaseline);
  WriteLn('   当前测试时间: ', Format('%.2f μs/op', [LBadResult.GetTimePerIteration(buMicroSeconds)]));
  WriteLn('   与基线对比: ', Format('%.1f%%', [LComparison * 100]), ' 差异');
  
  if LBadResult.IsRegressionFrom(LBaseline) then
  begin
    WriteLn('   🚨 检测到严重性能回归！');
    WriteLn('   建议: 检查代码变更，优化性能瓶颈');
  end
  else
  begin
    WriteLn('   ✅ 性能在可接受范围内');
  end;
  WriteLn;
end;

begin
  WriteLn('========================================');
  WriteLn('fafafa.core.benchmark 增强功能演示');
  WriteLn('========================================');
  WriteLn;
  
  Randomize;
  
  try
    DemonstrateSmartConfigRecommendation;
    DemonstrateStatisticalAnalysis;
    DemonstrateBaselineComparison;
    DemonstrateParameterizedTesting;
    DemonstratePerformanceRegression;
    
    WriteLn('========================================');
    WriteLn('增强功能演示完成！');
    WriteLn('========================================');
    WriteLn;
    WriteLn('新增功能总结:');
    WriteLn('✅ 智能配置推荐 - 根据操作复杂度自动推荐最佳配置');
    WriteLn('✅ 统计分析增强 - 百分位数、置信区间等高级统计');
    WriteLn('✅ 性能基线对比 - 与历史基线对比，检测性能回归');
    WriteLn('✅ 结果直接对比 - 快速比较两个测试结果');
    WriteLn('✅ 参数化测试支持 - 支持参数化测试用例定义');
    
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
