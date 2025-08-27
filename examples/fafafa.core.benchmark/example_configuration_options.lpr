program example_configuration_options;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.benchmark;

// 测试基准测试框架的各种配置选项

// 简单的测试函数
procedure SimpleTestFunction(aState: IBenchmarkState);
var
  LI: Integer;
  LSum: Integer;
begin
  LSum := 0;
  while aState.KeepRunning do
  begin
    for LI := 1 to 1000 do
      LSum := LSum + LI;
    
    aState.SetItemsProcessed(1000);
  end;
end;

// 传统测试函数
procedure LegacyTestFunction;
var
  LI: Integer;
  LSum: Integer;
begin
  LSum := 0;
  for LI := 1 to 10000 do
    LSum := LSum + LI * LI;
end;

procedure TestWarmupIterations;
var
  LRunner: IBenchmarkRunner;
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
  LReporter: IBenchmarkReporter;
begin
  WriteLn('=== 测试预热迭代次数的影响 ===');
  WriteLn;
  
  LRunner := CreateBenchmarkRunner;
  LReporter := CreateConsoleReporter;
  
  // 测试不同的预热迭代次数
  var LWarmupCounts: array[0..3] of Integer = (0, 1, 3, 5);
  var LI: Integer;
  
  for LI := 0 to High(LWarmupCounts) do
  begin
    LConfig := CreateDefaultBenchmarkConfig;
    LConfig.WarmupIterations := LWarmupCounts[LI];
    LConfig.MeasureIterations := 5;
    LConfig.MinDurationMs := 200;
    
    WriteLn('预热迭代次数: ', LWarmupCounts[LI]);
    LResult := LRunner.RunFunction('预热测试', @SimpleTestFunction, LConfig);
    
    WriteLn('  平均时间: ', Format('%.2f ns/op', [LResult.GetTimePerIteration()]));
    WriteLn('  标准差: ', Format('%.2f ns', [LResult.Statistics.StdDev]));
    WriteLn('  变异系数: ', Format('%.2f%%', [LResult.Statistics.StdDev / LResult.Statistics.Mean * 100]));
    WriteLn;
  end;
end;

procedure TestMeasureIterations;
var
  LRunner: IBenchmarkRunner;
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
  LReporter: IBenchmarkReporter;
begin
  WriteLn('=== 测试测量迭代次数的影响 ===');
  WriteLn;
  
  LRunner := CreateBenchmarkRunner;
  LReporter := CreateConsoleReporter;
  
  // 测试不同的测量迭代次数
  var LMeasureCounts: array[0..3] of Integer = (3, 5, 10, 20);
  var LI: Integer;
  
  for LI := 0 to High(LMeasureCounts) do
  begin
    LConfig := CreateDefaultBenchmarkConfig;
    LConfig.WarmupIterations := 2;
    LConfig.MeasureIterations := LMeasureCounts[LI];
    LConfig.MinDurationMs := 100;
    
    WriteLn('测量迭代次数: ', LMeasureCounts[LI]);
    LResult := LRunner.RunFunction('测量测试', @SimpleTestFunction, LConfig);
    
    WriteLn('  平均时间: ', Format('%.2f ns/op', [LResult.GetTimePerIteration()]));
    WriteLn('  标准差: ', Format('%.2f ns', [LResult.Statistics.StdDev]));
    WriteLn('  样本数量: ', LResult.Statistics.SampleCount);
    WriteLn('  置信区间: [', Format('%.2f', [LResult.Statistics.Min]), ', ', 
            Format('%.2f', [LResult.Statistics.Max]), '] ns');
    WriteLn;
  end;
end;

procedure TestDurationSettings;
var
  LRunner: IBenchmarkRunner;
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
  LReporter: IBenchmarkReporter;
begin
  WriteLn('=== 测试持续时间设置的影响 ===');
  WriteLn;
  
  LRunner := CreateBenchmarkRunner;
  LReporter := CreateConsoleReporter;
  
  // 测试不同的最小持续时间
  var LDurations: array[0..3] of Integer = (50, 100, 500, 1000);
  var LI: Integer;
  
  for LI := 0 to High(LDurations) do
  begin
    LConfig := CreateDefaultBenchmarkConfig;
    LConfig.WarmupIterations := 2;
    LConfig.MeasureIterations := 5;
    LConfig.MinDurationMs := LDurations[LI];
    LConfig.MaxDurationMs := LDurations[LI] * 10;
    
    WriteLn('最小持续时间: ', LDurations[LI], ' ms');
    
    var LStartTime := GetTickCount64;
    LResult := LRunner.RunFunction('持续时间测试', @SimpleTestFunction, LConfig);
    var LActualDuration := GetTickCount64 - LStartTime;
    
    WriteLn('  实际运行时间: ', LActualDuration, ' ms');
    WriteLn('  总迭代次数: ', LResult.Iterations);
    WriteLn('  平均时间: ', Format('%.2f ns/op', [LResult.GetTimePerIteration()]));
    WriteLn('  吞吐量: ', Format('%.0f ops/s', [LResult.GetThroughput()]));
    WriteLn;
  end;
end;

procedure TestTimeUnits;
var
  LRunner: IBenchmarkRunner;
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
begin
  WriteLn('=== 测试不同时间单位 ===');
  WriteLn;
  
  LRunner := CreateBenchmarkRunner;
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 2;
  LConfig.MeasureIterations := 5;
  
  // 运行一次测试
  LResult := LRunner.RunFunction('时间单位测试', @SimpleTestFunction, LConfig);
  
  WriteLn('同一结果的不同时间单位表示:');
  WriteLn('  纳秒: ', Format('%.2f ns/op', [LResult.GetTimePerIteration(buNanoSeconds)]));
  WriteLn('  微秒: ', Format('%.2f μs/op', [LResult.GetTimePerIteration(buMicroSeconds)]));
  WriteLn('  毫秒: ', Format('%.2f ms/op', [LResult.GetTimePerIteration(buMilliSeconds)]));
  WriteLn('  秒: ', Format('%.6f s/op', [LResult.GetTimePerIteration(buSeconds)]));
  WriteLn;
end;

procedure TestBenchmarkModes;
var
  LRunner: IBenchmarkRunner;
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
  LReporter: IBenchmarkReporter;
begin
  WriteLn('=== 测试不同基准测试模式 ===');
  WriteLn;
  
  LRunner := CreateBenchmarkRunner;
  LReporter := CreateConsoleReporter;
  
  // 测试时间模式
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.Mode := bmTime;
  LConfig.WarmupIterations := 2;
  LConfig.MeasureIterations := 5;
  
  WriteLn('时间模式 (bmTime):');
  LResult := LRunner.RunFunction('时间模式测试', @SimpleTestFunction, LConfig);
  LReporter.ReportResult(LResult);
  WriteLn;
  
  // 测试迭代模式
  LConfig.Mode := bmIterations;
  LConfig.MeasureIterations := 1000; // 固定迭代次数
  
  WriteLn('迭代模式 (bmIterations):');
  LResult := LRunner.RunFunction('迭代模式测试', @SimpleTestFunction, LConfig);
  LReporter.ReportResult(LResult);
  WriteLn;
end;

procedure TestMemoryMeasurement;
var
  LRunner: IBenchmarkRunner;
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
  LReporter: IBenchmarkReporter;
begin
  WriteLn('=== 测试内存测量功能 ===');
  WriteLn;
  
  LRunner := CreateBenchmarkRunner;
  LReporter := CreateConsoleReporter;
  
  // 不启用内存测量
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.EnableMemoryMeasurement := False;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 3;
  
  WriteLn('不启用内存测量:');
  LResult := LRunner.RunFunction('无内存测量', @SimpleTestFunction, LConfig);
  LReporter.ReportResult(LResult);
  WriteLn;
  
  // 启用内存测量
  LConfig.EnableMemoryMeasurement := True;
  
  WriteLn('启用内存测量:');
  LResult := LRunner.RunFunction('有内存测量', @SimpleTestFunction, LConfig);
  LReporter.ReportResult(LResult);
  WriteLn;
end;

procedure TestLegacyAPIConfiguration;
var
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
  LReporter: IBenchmarkReporter;
begin
  WriteLn('=== 测试传统 API 配置选项 ===');
  WriteLn;
  
  LReporter := CreateConsoleReporter;
  
  // 测试不同配置的传统 API
  var LConfigs: array[0..2] of string = ('快速配置', '标准配置', '精确配置');
  var LI: Integer;
  
  for LI := 0 to High(LConfigs) do
  begin
    LConfig := CreateDefaultBenchmarkConfig;
    
    case LI of
      0: begin // 快速配置
        LConfig.WarmupIterations := 1;
        LConfig.MeasureIterations := 3;
        LConfig.MinDurationMs := 50;
      end;
      1: begin // 标准配置
        LConfig.WarmupIterations := 3;
        LConfig.MeasureIterations := 5;
        LConfig.MinDurationMs := 200;
      end;
      2: begin // 精确配置
        LConfig.WarmupIterations := 5;
        LConfig.MeasureIterations := 10;
        LConfig.MinDurationMs := 500;
      end;
    end;
    
    WriteLn(LConfigs[LI], ':');
    WriteLn('  预热: ', LConfig.WarmupIterations, ', 测量: ', LConfig.MeasureIterations, 
            ', 最小时间: ', LConfig.MinDurationMs, 'ms');
    
    LResult := RunLegacyFunction('传统API-' + LConfigs[LI], @LegacyTestFunction, LConfig);
    
    WriteLn('  结果: ', Format('%.2f ns/op', [LResult.GetTimePerIteration()]));
    WriteLn('  标准差: ', Format('%.2f ns', [LResult.Statistics.StdDev]));
    WriteLn;
  end;
end;

procedure SaveConfigurationReport;
var
  LRunner: IBenchmarkRunner;
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
  LJSONReporter: IBenchmarkReporter;
begin
  WriteLn('=== 保存配置测试报告 ===');
  
  LRunner := CreateBenchmarkRunner;
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 3;
  LConfig.MeasureIterations := 10;
  LConfig.EnableMemoryMeasurement := True;
  
  LResult := LRunner.RunFunction('配置测试完整报告', @SimpleTestFunction, LConfig);
  
  LJSONReporter := CreateJSONReporter('configuration_test.json');
  LJSONReporter.ReportResult(LResult);
  WriteLn('配置测试报告已保存到: configuration_test.json');
end;

begin
  WriteLn('========================================');
  WriteLn('基准测试配置选项验证示例');
  WriteLn('========================================');
  WriteLn;
  
  try
    TestWarmupIterations;
    TestMeasureIterations;
    TestDurationSettings;
    TestTimeUnits;
    TestBenchmarkModes;
    TestMemoryMeasurement;
    TestLegacyAPIConfiguration;
    SaveConfigurationReport;
    
    WriteLn;
    WriteLn('========================================');
    WriteLn('配置选项验证完成！');
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
