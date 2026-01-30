program example_monitoring;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.benchmark;

// 性能监控和自动化测试演示

// 快速算法
procedure FastAlgorithm(aState: IBenchmarkState);
var
  LSum: Integer;
  LI: Integer;
begin
  while aState.KeepRunning do
  begin
    LSum := 0;
    for LI := 1 to 100 do
      LSum := LSum + LI;
    aState.SetItemsProcessed(100);
  end;
end;

// 慢速算法
procedure SlowAlgorithm(aState: IBenchmarkState);
var
  LSum: Integer;
  LI, LJ: Integer;
begin
  while aState.KeepRunning do
  begin
    LSum := 0;
    for LI := 1 to 100 do
      for LJ := 1 to 50 do
        LSum := LSum + LI * LJ;
    aState.SetItemsProcessed(5000);
  end;
end;

// 不稳定算法（性能会变化）
procedure UnstableAlgorithm(aState: IBenchmarkState);
var
  LSum: Integer;
  LI: Integer;
  LDelay: Integer;
begin
  while aState.KeepRunning do
  begin
    LSum := 0;
    
    // 随机延迟模拟性能不稳定
    LDelay := Random(1000);
    for LI := 1 to 100 + LDelay do
      LSum := LSum + LI;
    
    aState.SetItemsProcessed(100 + LDelay);
  end;
end;

procedure DemonstrateBasicMonitoring;
var
  LMonitor: IBenchmarkMonitor;
begin
  WriteLn('=== 基础性能监控演示 ===');
  WriteLn;
  
  // 创建监控器
  LMonitor := CreateBenchmarkMonitor;
  
  // 设置性能阈值
  LMonitor.SetThreshold('快速算法', 50000);   // 50μs 阈值
  LMonitor.SetThreshold('慢速算法', 500000);  // 500μs 阈值
  
  WriteLn('设置了性能阈值:');
  WriteLn('  快速算法: 50μs');
  WriteLn('  慢速算法: 500μs');
  WriteLn;
  
  // 运行监控测试
  monitored_benchmark('性能监控测试', [
    benchmark('快速算法', @FastAlgorithm),
    benchmark('慢速算法', @SlowAlgorithm),
    benchmark('不稳定算法', @UnstableAlgorithm)
  ], LMonitor);
  
  // 显示所有警报
  var LAlerts := LMonitor.GetAlerts;
  if Length(LAlerts) > 0 then
  begin
    WriteLn('📊 监控总结:');
    WriteLn('  总警报数: ', Length(LAlerts));
    for var LAlert in LAlerts do
      WriteLn('  - ', LAlert.Message);
  end
  else
    WriteLn('✅ 所有测试都在性能阈值内');
  
  WriteLn;
end;

procedure DemonstrateRegressionTesting;
begin
  WriteLn('=== 回归测试演示 ===');
  WriteLn;
  
  WriteLn('第一次运行 - 建立基线:');
  var LResult1 := regression_test([
    benchmark('算法A', @FastAlgorithm),
    benchmark('算法B', @SlowAlgorithm)
  ], 'regression_baseline.txt');
  
  WriteLn('基线建立结果: ', IIF(LResult1, '成功', '失败'));
  WriteLn;
  
  WriteLn('第二次运行 - 检查回归:');
  var LResult2 := regression_test([
    benchmark('算法A', @FastAlgorithm),
    benchmark('算法B', @UnstableAlgorithm)  // 用不稳定算法模拟回归
  ], 'regression_baseline.txt');
  
  WriteLn('回归检测结果: ', IIF(LResult2, '无回归', '检测到回归'));
  WriteLn;
end;

procedure DemonstrateContinuousIntegration;
begin
  WriteLn('=== 持续集成演示 ===');
  WriteLn;
  
  WriteLn('模拟 CI/CD 流水线中的性能测试...');
  WriteLn;
  
  // 模拟正常情况
  WriteLn('场景1: 正常性能');
  var LResult1 := continuous_benchmark([
    benchmark('核心算法', @FastAlgorithm),
    benchmark('辅助算法', @SlowAlgorithm)
  ], 'ci_config.json');
  
  WriteLn('CI 测试结果: ', IIF(LResult1, '✅ 通过 - 可以部署', '❌ 失败 - 阻止部署'));
  WriteLn;
  
  // 模拟性能回归情况
  WriteLn('场景2: 性能回归');
  var LResult2 := continuous_benchmark([
    benchmark('核心算法', @UnstableAlgorithm),  // 用不稳定算法模拟回归
    benchmark('辅助算法', @SlowAlgorithm)
  ], 'ci_config.json');
  
  WriteLn('CI 测试结果: ', IIF(LResult2, '✅ 通过 - 可以部署', '❌ 失败 - 阻止部署'));
  WriteLn;
end;

procedure DemonstrateAdvancedMonitoring;
var
  LMonitor: IBenchmarkMonitor;
  LResults: TBenchmarkResultArray;
  LAlerts: TPerformanceAlertArray;
begin
  WriteLn('=== 高级监控功能演示 ===');
  WriteLn;
  
  LMonitor := CreateBenchmarkMonitor;
  
  // 设置更严格的阈值
  LMonitor.SetThreshold('快速算法', 10000);        // 10μs 严格阈值
  LMonitor.SetRegressionThreshold('快速算法', 0.05); // 5% 回归阈值
  
  WriteLn('设置严格监控参数:');
  WriteLn('  性能阈值: 10μs');
  WriteLn('  回归阈值: 5%');
  WriteLn;
  
  // 运行测试
  LResults := benchmarks([
    benchmark('快速算法', @FastAlgorithm)
  ]);
  
  // 手动检查性能
  for var LResult in LResults do
  begin
    LAlerts := LMonitor.CheckPerformance(LResult);
    if Length(LAlerts) > 0 then
    begin
      WriteLn('🚨 性能警报:');
      for var LAlert in LAlerts do
        WriteLn('  ', LAlert.Message);
    end
    else
      WriteLn('✅ 性能正常: ', LResult.Name);
  end;
  
  WriteLn;
  
  // 保存结果
  LMonitor.SaveResults(LResults, 'monitoring_results.txt');
  WriteLn('结果已保存到: monitoring_results.txt');
  WriteLn;
end;

procedure ShowMonitoringFeatures;
begin
  WriteLn('🔍 性能监控功能总览');
  WriteLn('====================');
  WriteLn;
  WriteLn('✅ 已实现的功能:');
  WriteLn('  • 性能阈值监控 - 超过阈值自动警报');
  WriteLn('  • 回归检测 - 与历史基线对比');
  WriteLn('  • 自动化测试 - 适合 CI/CD 集成');
  WriteLn('  • 结果持久化 - 保存和加载测试结果');
  WriteLn('  • 警报系统 - 多级别警报和消息');
  WriteLn('  • 监控报告 - 详细的监控信息');
  WriteLn;
  WriteLn('🎯 使用场景:');
  WriteLn('  • 持续集成/持续部署 (CI/CD)');
  WriteLn('  • 性能回归检测');
  WriteLn('  • 自动化质量保证');
  WriteLn('  • 长期性能趋势监控');
  WriteLn('  • 团队协作和性能标准');
  WriteLn;
  WriteLn('📝 API 接口:');
  WriteLn('  monitored_benchmark()     - 带监控的测试');
  WriteLn('  regression_test()         - 回归测试');
  WriteLn('  continuous_benchmark()    - 持续集成测试');
  WriteLn('  CreateBenchmarkMonitor()  - 创建监控器');
  WriteLn;
end;

begin
  WriteLn('========================================');
  WriteLn('性能监控和自动化测试演示');
  WriteLn('========================================');
  WriteLn;
  
  Randomize;
  
  try
    ShowMonitoringFeatures;
    DemonstrateBasicMonitoring;
    DemonstrateRegressionTesting;
    DemonstrateContinuousIntegration;
    DemonstrateAdvancedMonitoring;
    
    WriteLn('========================================');
    WriteLn('监控演示完成！');
    WriteLn('========================================');
    WriteLn;
    WriteLn('生成的文件:');
    WriteLn('  • regression_baseline.txt - 回归测试基线');
    WriteLn('  • ci_benchmark_history.json - CI 历史数据');
    WriteLn('  • monitoring_results.txt - 监控结果');
    WriteLn;
    WriteLn('这些功能让基准测试框架具备了企业级的');
    WriteLn('自动化监控和质量保证能力！');
    
  except
    on E: Exception do
    begin
      WriteLn('演示运行出错: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
