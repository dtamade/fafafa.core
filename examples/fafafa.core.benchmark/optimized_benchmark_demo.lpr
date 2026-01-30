program optimized_benchmark_demo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.benchmark;

{**
 * 🚀 优化的基准测试演示程序
 * 
 * 展示新的优化功能：
 * - 涡轮增压基准测试（自动优化配置）
 * - 智能基准测试（自动分析和建议）
 * - 优化的统计计算
 * - 增强的报告格式
 *}

{**
 * 测试函数：字符串操作
 *}
procedure StringOperationTest(aState: IBenchmarkState);
var
  LStr: string;
  LI: Integer;
begin
  while aState.KeepRunning do
  begin
    LStr := '';
    for LI := 1 to 50 do
      LStr := LStr + 'test';
  end;
end;

{**
 * 测试函数：数学计算
 *}
procedure MathOperationTest(aState: IBenchmarkState);
var
  LI: Integer;
  LResult: Double;
begin
  while aState.KeepRunning do
  begin
    LResult := 0;
    for LI := 1 to 100 do
      LResult := LResult + Sqrt(LI) * Sin(LI);
  end;
end;

{**
 * 测试函数：数组处理
 *}
procedure ArrayProcessingTest(aState: IBenchmarkState);
var
  LArr: array[0..99] of Integer;
  LI, LSum: Integer;
begin
  while aState.KeepRunning do
  begin
    // 初始化
    for LI := 0 to 99 do
      LArr[LI] := Random(1000);
    
    // 处理
    LSum := 0;
    for LI := 0 to 99 do
      LSum := LSum + LArr[LI];
  end;
end;

{**
 * 测试函数：快速操作（用于测试高性能场景）
 *}
procedure FastOperationTest(aState: IBenchmarkState);
var
  LI: Integer;
begin
  while aState.KeepRunning do
  begin
    for LI := 1 to 10 do
      Inc(LI); // 非常快的操作
  end;
end;

{**
 * 测试函数：慢速操作（用于测试低性能场景）
 *}
procedure SlowOperationTest(aState: IBenchmarkState);
var
  LI, LJ: Integer;
  LSum: Integer;
begin
  while aState.KeepRunning do
  begin
    LSum := 0;
    for LI := 1 to 200 do
      for LJ := 1 to 200 do
        LSum := LSum + LI * LJ;
  end;
end;

{**
 * 演示涡轮增压基准测试
 *}
procedure DemoTurboBenchmark;
begin
  WriteLn('🚀 演示：涡轮增压基准测试');
  WriteLn('==========================');
  WriteLn;
  
  turbo_benchmark('性能测试套件', [
    benchmark('字符串操作', @StringOperationTest),
    benchmark('数学计算', @MathOperationTest),
    benchmark('数组处理', @ArrayProcessingTest)
  ]);
  
  WriteLn;
end;

{**
 * 演示智能基准测试
 *}
procedure DemoSmartBenchmark;
begin
  WriteLn('🧠 演示：智能基准测试');
  WriteLn('======================');
  WriteLn;
  
  smart_benchmark([
    benchmark('快速操作', @FastOperationTest),
    benchmark('慢速操作', @SlowOperationTest),
    benchmark('数学计算', @MathOperationTest)
  ]);
  
  WriteLn;
end;

{**
 * 演示优化的统计功能
 *}
procedure DemoOptimizedStatistics;
var
  LResults: TBenchmarkResultArray;
  LStats: TBenchmarkStatistics;
  LI: Integer;
begin
  WriteLn('📊 演示：优化的统计分析');
  WriteLn('========================');
  WriteLn;
  
  // 运行一组测试
  LResults := benchmarks([
    benchmark('字符串操作', @StringOperationTest),
    benchmark('数学计算', @MathOperationTest)
  ]);
  
  // 显示详细统计信息
  for LI := 0 to High(LResults) do
  begin
    LStats := LResults[LI].GetStatistics();
    
    WriteLn(Format('测试: %s', [LResults[LI].Name]));
    WriteLn('─────────────────────');
    WriteLn(Format('• 平均值: %.2f μs', [LStats.Mean / 1000]));
    WriteLn(Format('• 标准差: %.2f μs', [LStats.StdDev / 1000]));
    WriteLn(Format('• 变异系数: %.2f%%', [LStats.CoefficientOfVariation * 100]));
    WriteLn(Format('• 偏度: %.3f', [LStats.Skewness]));
    WriteLn(Format('• 峰度: %.3f', [LStats.Kurtosis]));
    WriteLn(Format('• 四分位距: %.2f μs', [LStats.IQR / 1000]));
    WriteLn(Format('• 异常值数量: %d', [LStats.OutlierCount]));
    WriteLn;
  end;
end;

{**
 * 演示性能对比分析
 *}
procedure DemoPerformanceComparison;
var
  LResults: TBenchmarkResultArray;
  LFastest: IBenchmarkResult;
  LI: Integer;
  LRatio: Double;
begin
  WriteLn('⚡ 演示：性能对比分析');
  WriteLn('======================');
  WriteLn;
  
  LResults := benchmarks('性能对比测试', [
    benchmark('快速操作', @FastOperationTest),
    benchmark('字符串操作', @StringOperationTest),
    benchmark('数学计算', @MathOperationTest),
    benchmark('数组处理', @ArrayProcessingTest),
    benchmark('慢速操作', @SlowOperationTest)
  ]);
  
  // 找出最快的测试
  LFastest := LResults[0];
  for LI := 1 to High(LResults) do
  begin
    if LResults[LI].GetTimePerIteration() < LFastest.GetTimePerIteration() then
      LFastest := LResults[LI];
  end;
  
  WriteLn('🏆 性能排行榜:');
  WriteLn('─────────────');
  
  // 按性能排序显示
  for LI := 0 to High(LResults) do
  begin
    LRatio := LResults[LI].GetTimePerIteration() / LFastest.GetTimePerIteration();
    
    if LResults[LI] = LFastest then
      WriteLn(Format('🥇 %-15s %10.2f μs/op (基准)', [
        LResults[LI].Name, 
        LResults[LI].GetTimePerIteration(buMicroSeconds)
      ]))
    else
      WriteLn(Format('   %-15s %10.2f μs/op (%.1fx)', [
        LResults[LI].Name, 
        LResults[LI].GetTimePerIteration(buMicroSeconds),
        LRatio
      ]));
  end;
  
  WriteLn;
end;

{**
 * 主程序
 *}
begin
  WriteLn('🚀 优化的基准测试框架演示');
  WriteLn('============================');
  WriteLn;
  WriteLn('本演示展示了基准测试框架的最新优化功能：');
  WriteLn('• 涡轮增压基准测试（自动优化配置）');
  WriteLn('• 智能基准测试（自动分析和建议）');
  WriteLn('• 优化的统计计算（偏度、峰度、异常值检测）');
  WriteLn('• 增强的报告格式（美观的表格和图标）');
  WriteLn;
  
  try
    // 演示各种优化功能
    DemoTurboBenchmark;
    DemoSmartBenchmark;
    DemoOptimizedStatistics;
    DemoPerformanceComparison;
    
    WriteLn('🎉 所有演示完成！');
    WriteLn;
    WriteLn('💡 提示：');
    WriteLn('- 使用 turbo_benchmark() 获得自动优化的测试配置');
    WriteLn('- 使用 smart_benchmark() 获得智能分析和建议');
    WriteLn('- 新的统计功能提供更深入的性能洞察');
    WriteLn('- 优化的报告格式让结果更易读');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 发生异常: ', E.ClassName, ' - ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
