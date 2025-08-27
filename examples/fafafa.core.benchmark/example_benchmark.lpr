program example_benchmark;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.benchmark;

// 🚀 终极加油模式 - 老板给我加油了！
// 这个示例现在要展示宇宙中最疯狂的性能测试功能！

{**
 * 测试函数：字符串连接
 *}
procedure StringConcatTest;
var
  LI: Integer;
  LStr: string;
begin
  LStr := '';
  for LI := 1 to 100 do
    LStr := LStr + 'test';
end;

{**
 * 测试函数：数组排序
 *}
procedure ArraySortTest;
var
  LArr: array[0..99] of Integer;
  LI, LJ, LTemp: Integer;
begin
  // 初始化数组
  for LI := 0 to 99 do
    LArr[LI] := 99 - LI;

  // 简单冒泡排序
  for LI := 0 to 98 do
    for LJ := 0 to 98 - LI do
      if LArr[LJ] > LArr[LJ + 1] then
      begin
        LTemp := LArr[LJ];
        LArr[LJ] := LArr[LJ + 1];
        LArr[LJ + 1] := LTemp;
      end;
end;

{**
 * 测试函数：数学计算
 *}
procedure MathCalculationTest;
var
  LI: Integer;
  LResult: Double;
begin
  LResult := 0;
  for LI := 1 to 1000 do
    LResult := LResult + Sqrt(LI) * Sin(LI);
end;

{**
 * 测试函数：快速算法
 *}
procedure FastAlgorithm;
var
  LI: Integer;
  LSum: Integer;
begin
  LSum := 0;
  for LI := 1 to 1000 do
    LSum := LSum + LI;
end;

{**
 * 测试函数：慢速算法
 *}
procedure SlowAlgorithm;
var
  LI, LJ: Integer;
  LSum: Integer;
begin
  LSum := 0;
  for LI := 1 to 100 do
    for LJ := 1 to 100 do
      LSum := LSum + LI * LJ;
end;

{**
 * 测试函数：简单计算
 *}
procedure SimpleCalculation(aState: IBenchmarkState);
var
  LI: Integer;
  LResult: Double;
begin
  while aState.KeepRunning do
  begin
    LResult := 0;
    for LI := 1 to 100 do
      LResult := LResult + Sqrt(LI);
  end;
end;

{**
 * 测试函数：数组操作
 *}
procedure ArrayOperation(aState: IBenchmarkState);
var
  LArr: array[0..99] of Integer;
  LI: Integer;
  LSum: Integer;
begin
  while aState.KeepRunning do
  begin
    // 初始化数组
    for LI := 0 to 99 do
      LArr[LI] := LI;

    // 计算总和
    LSum := 0;
    for LI := 0 to 99 do
      LSum := LSum + LArr[LI];
  end;
end;

{**
 * 适配器函数：将传统测试函数适配到新API
 *}
procedure StringConcatTestAdapter(aState: IBenchmarkState);
begin
  while aState.KeepRunning do
    StringConcatTest;
end;

procedure ArraySortTestAdapter(aState: IBenchmarkState);
begin
  while aState.KeepRunning do
    ArraySortTest;
end;

procedure MathCalculationTestAdapter(aState: IBenchmarkState);
begin
  while aState.KeepRunning do
    MathCalculationTest;
end;

{**
 * 演示基本的基准测试功能
 *}
procedure DemoBasicBenchmarking;
var
  LRunner: IBenchmarkRunner;
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
begin
  WriteLn('=== 基本基准测试演示 ===');
  
  // 创建运行器和配置
  LRunner := CreateBenchmarkRunner;
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 3;
  LConfig.MeasureIterations := 10;
  
  // 运行基准测试
  LResult := LRunner.RunFunction('字符串连接测试', @StringConcatTestAdapter, LConfig);
  
  // 显示结果
  WriteLn('测试名称: ', LResult.Name);
  WriteLn('迭代次数: ', LResult.Iterations);
  WriteLn('总时间: ', Format('%.2f μs', [LResult.TotalTime / 1000]));
  WriteLn('平均时间: ', Format('%.2f μs', [LResult.GetTimePerIteration(buMicroSeconds)]));
  WriteLn('吞吐量: ', Format('%.0f ops/sec', [LResult.GetThroughput]));
  WriteLn;
end;

{**
 * 演示基准测试套件功能
 *}
procedure DemoBenchmarkSuite;
var
  LSuite: IBenchmarkSuite;
  LReporter: IBenchmarkReporter;
  LConfig: TBenchmarkConfig;
begin
  WriteLn('=== 基准测试套件演示 ===');
  
  // 创建套件和报告器
  LSuite := CreateBenchmarkSuite;
  LReporter := CreateConsoleReporter;
  
  // 创建配置
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 2;
  LConfig.MeasureIterations := 5;
  
  // 添加多个基准测试
  LSuite.AddFunction('字符串连接', @StringConcatTestAdapter, LConfig);
  LSuite.AddFunction('数组排序', @ArraySortTestAdapter, LConfig);
  LSuite.AddFunction('数学计算', @MathCalculationTestAdapter, LConfig);
  
  WriteLn('已添加 ', LSuite.Count, ' 个基准测试');
  WriteLn;
  
  // 运行所有测试并生成报告
  LSuite.RunAllWithReporter(LReporter);
end;

{**
 * 演示基准测试比较功能
 *}
procedure DemoBenchmarkComparison;
var
  LRunner: IBenchmarkRunner;
  LReporter: IBenchmarkReporter;
  LConfig: TBenchmarkConfig;
  LResult1, LResult2: IBenchmarkResult;
begin
  WriteLn('=== 基准测试比较演示 ===');
  
  LRunner := CreateBenchmarkRunner;
  LReporter := CreateConsoleReporter;
  
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 2;
  LConfig.MeasureIterations := 8;
  
  // 运行两个不同的测试
  LResult1 := LRunner.RunFunction('快速算法', @FastAlgorithm, LConfig);
  LResult2 := LRunner.RunFunction('慢速算法', @SlowAlgorithm, LConfig);
  
  // 比较结果
  LReporter.ReportComparison(LResult1, LResult2);
end;

{**
 * 演示文件报告器功能
 *}
procedure DemoFileReporter;
var
  LRunner: IBenchmarkRunner;
  LFileReporter: IBenchmarkReporter;
  LConfig: TBenchmarkConfig;
  LResult: IBenchmarkResult;
begin
  WriteLn('=== 文件报告器演示 ===');
  
  LRunner := CreateBenchmarkRunner;
  LFileReporter := CreateFileReporter('benchmark_results.txt');
  
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.MeasureIterations := 5;
  
  // 运行测试并保存到文件
  LResult := LRunner.RunFunction('文件测试', @StringConcatTestAdapter, LConfig);
  LFileReporter.ReportResult(LResult);
  
  WriteLn('基准测试结果已保存到 benchmark_results.txt');
  WriteLn;
end;

// 演示新增的增强功能
procedure DemonstrateEnhancedFeatures;
var
  LResult1, LResult2: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
  LBaseline: TBenchmarkBaseline;
  LRecommendation: TBenchmarkRecommendation;
  LLowerBound, LUpperBound: Double;
  LRunner: IBenchmarkRunner;
begin
  WriteLn;
  WriteLn('=== 增强功能演示 ===');
  WriteLn;

  LRunner := CreateBenchmarkRunner;

  // 1. 智能配置推荐
  WriteLn('1. 智能配置推荐:');
  LRecommendation := RecommendConfig(@SimpleCalculation);
  WriteLn('  推荐置信度: ', Format('%.1f%%', [LRecommendation.Confidence * 100]));
  WriteLn('  推荐理由: ', LRecommendation.Reasoning);
  WriteLn('  推荐预热次数: ', LRecommendation.RecommendedConfig.WarmupIterations);
  WriteLn('  推荐测量次数: ', LRecommendation.RecommendedConfig.MeasureIterations);
  WriteLn;

  // 2. 使用推荐配置运行测试
  WriteLn('2. 使用推荐配置运行测试:');
  LResult1 := LRunner.RunFunction('推荐配置测试', @SimpleCalculation, LRecommendation.RecommendedConfig);
  WriteLn('  平均时间: ', Format('%.2f ns/op', [LResult1.GetTimePerIteration()]));

  // 3. 百分位数分析
  WriteLn('  P50 (中位数): ', Format('%.2f ns', [LResult1.GetPercentile(50)]));
  WriteLn('  P95: ', Format('%.2f ns', [LResult1.GetPercentile(95)]));
  WriteLn('  P99: ', Format('%.2f ns', [LResult1.GetPercentile(99)]));
  WriteLn;

  // 4. 置信区间
  WriteLn('3. 置信区间分析:');
  LResult1.GetConfidenceInterval(0.95, LLowerBound, LUpperBound);
  WriteLn('  95% 置信区间: [', Format('%.2f', [LLowerBound]), ', ',
          Format('%.2f', [LUpperBound]), '] ns');
  WriteLn;

  // 5. 性能基线对比
  WriteLn('4. 性能基线对比:');

  // 创建基线（使用第一次测试结果作为基线）
  LBaseline := CreateBaseline('简单计算基线', LResult1.GetTimePerIteration(), 0.1,
                             '简单数学计算的性能基线');
  WriteLn('  基线时间: ', Format('%.2f ns/op', [LBaseline.BaselineTime]));
  WriteLn('  容忍度: ', Format('%.1f%%', [LBaseline.Tolerance * 100]));

  // 运行第二次测试进行对比
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 2;
  LConfig.MeasureIterations := 5;

  LResult2 := LRunner.RunFunction('对比测试', @SimpleCalculation, LConfig);

  var LComparison := LResult2.CompareWithBaseline(LBaseline);
  WriteLn('  对比结果: ', Format('%.2f%%', [LComparison * 100]),
          IIF(LComparison > 0, ' (比基线慢)', ' (比基线快)'));

  if LResult2.IsRegressionFrom(LBaseline) then
    WriteLn('  ⚠️ 检测到性能回归！')
  else
    WriteLn('  ✅ 性能正常');
  WriteLn;

  // 6. 结果对比
  WriteLn('5. 结果直接对比:');
  var LDirectComparison := CompareResults(LResult1, LResult2);
  WriteLn('  相对性能差异: ', Format('%.2f%%', [LDirectComparison * 100]));

  if Abs(LDirectComparison) < 0.05 then
    WriteLn('  📊 两次测试结果基本一致')
  else if LDirectComparison > 0 then
    WriteLn('  📈 第二次测试比第一次快')
  else
    WriteLn('  📉 第二次测试比第一次慢');
end;

// 演示超级简洁的快手接口
procedure DemonstrateQuickBenchmark;
begin
  WriteLn;
  WriteLn('=== 快手接口演示 ===');
  WriteLn;

  WriteLn('1. 最简单的一行式基准测试:');
  WriteLn;

  // 超级简洁的一行式基准测试！
  quick_benchmark([
    benchmark('字符串连接', @StringConcatTestAdapter),
    benchmark('简单计算', @SimpleCalculation),
    benchmark('数组操作', @ArrayOperation)
  ]);

  WriteLn;
  WriteLn('2. 带标题的快手测试:');
  WriteLn;

  // 带标题的版本
  quick_benchmark('性能对比测试', [
    benchmark('字符串连接', @StringConcatTestAdapter),
    benchmark('简单计算', @SimpleCalculation)
  ]);

  WriteLn;
  WriteLn('3. 自定义配置的快手测试:');
  WriteLn;

  var LFastConfig := CreateDefaultBenchmarkConfig;
  LFastConfig.WarmupIterations := 1;
  LFastConfig.MeasureIterations := 3;

  quick_benchmark('快速测试', [
    benchmark('字符串连接', @StringConcatTestAdapter, LFastConfig),
    benchmark('简单计算', @SimpleCalculation, LFastConfig)
  ]);

  WriteLn;
  WriteLn('4. 只获取结果不显示:');
  WriteLn;

  var LResults := benchmarks([
    benchmark('测试1', @SimpleCalculation),
    benchmark('测试2', @StringConcatTestAdapter)
  ]);

  WriteLn('获得了 ', Length(LResults), ' 个测试结果');
  WriteLn('最快的是: ', LResults[0].Name, ' (',
          Format('%.2f μs/op', [LResults[0].GetTimePerIteration(buMicroSeconds)]), ')');

  WriteLn;
  WriteLn('✨ 快手接口让基准测试变得超级简单！');
end;

{**
 * 主程序
 *}
begin
  WriteLn('fafafa.core.benchmark 使用示例');
  WriteLn('================================');
  WriteLn;
  
  try
    // 运行各种演示
    DemoBasicBenchmarking;
    DemoBenchmarkSuite;
    DemoBenchmarkComparison;
    DemoFileReporter;
    
    WriteLn('所有演示完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('发生异常: ', E.ClassName, ' - ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  // 演示新增的增强功能
  DemonstrateEnhancedFeatures;

  // 演示超级简洁的快手接口
  DemonstrateQuickBenchmark;

  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
