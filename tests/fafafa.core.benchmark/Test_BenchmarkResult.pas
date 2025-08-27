unit Test_BenchmarkResult;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.base,
  fafafa.core.benchmark;

type

  { TTestCase_BenchmarkResult }

  TTestCase_BenchmarkResult = class(TTestCase)
  private
    FResult: IBenchmarkResult;
    
    // 创建测试用的结果实例
    function CreateTestResult: IBenchmarkResult;
    
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    
  published
    // 基本属性测试
    procedure Test_BenchmarkResult_GetName;
    procedure Test_BenchmarkResult_GetIterations;
    procedure Test_BenchmarkResult_GetTotalTime;
    procedure Test_BenchmarkResult_GetConfig;
    procedure Test_BenchmarkResult_GetStatistics;
    
    // 计算方法测试
    procedure Test_BenchmarkResult_GetTimePerIteration;
    procedure Test_BenchmarkResult_GetTimePerIteration_Units;
    procedure Test_BenchmarkResult_GetThroughput;
    procedure Test_BenchmarkResult_GetBytesPerSecond;
    procedure Test_BenchmarkResult_GetItemsPerSecond;
    
    // 高级功能测试
    procedure Test_BenchmarkResult_GetCounters;
    procedure Test_BenchmarkResult_GetSamples;
    procedure Test_BenchmarkResult_HasStatistics;
    procedure Test_BenchmarkResult_GetComplexityN;
    
    // 异常测试
    procedure Test_BenchmarkResult_GetTimePerIteration_ZeroIterations;
    procedure Test_BenchmarkResult_GetThroughput_ZeroTime;
  end;

implementation

// 测试用的简单函数
procedure SimpleTestFunction;
var
  LI: Integer;
  LSum: Integer;
begin
  LSum := 0;
  for LI := 1 to 1000 do
    LSum := LSum + LI;
end;

{ TTestCase_BenchmarkResult }

function TTestCase_BenchmarkResult.CreateTestResult: IBenchmarkResult;
var
  LConfig: TBenchmarkConfig;
begin
  // 通过运行一个简单的传统基准测试来创建结果
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 3;
  
  Result := RunLegacyFunction('测试结果', @SimpleTestFunction, LConfig);
end;

procedure TTestCase_BenchmarkResult.SetUp;
begin
  inherited SetUp;
  FResult := CreateTestResult;
end;

procedure TTestCase_BenchmarkResult.TearDown;
begin
  FResult := nil;
  inherited TearDown;
end;

procedure TTestCase_BenchmarkResult.Test_BenchmarkResult_GetName;
begin
  AssertNotNull('结果对象不应为空', FResult);
  AssertEquals('结果名称应正确', '测试结果', FResult.GetName);
  AssertEquals('Name 属性应正确', '测试结果', FResult.Name);
end;

procedure TTestCase_BenchmarkResult.Test_BenchmarkResult_GetIterations;
begin
  AssertNotNull('结果对象不应为空', FResult);
  AssertTrue('迭代次数应大于0', FResult.GetIterations > 0);
  AssertTrue('Iterations 属性应大于0', FResult.Iterations > 0);
  AssertEquals('GetIterations 和 Iterations 应相等', FResult.GetIterations, FResult.Iterations);
end;

procedure TTestCase_BenchmarkResult.Test_BenchmarkResult_GetTotalTime;
begin
  AssertNotNull('结果对象不应为空', FResult);
  AssertTrue('总时间应大于0', FResult.GetTotalTime > 0);
  AssertTrue('TotalTime 属性应大于0', FResult.TotalTime > 0);
  AssertEquals('GetTotalTime 和 TotalTime 应相等', FResult.GetTotalTime, FResult.TotalTime, 0.001);
end;

procedure TTestCase_BenchmarkResult.Test_BenchmarkResult_GetConfig;
var
  LConfig: TBenchmarkConfig;
begin
  AssertNotNull('结果对象不应为空', FResult);
  
  LConfig := FResult.GetConfig;
  AssertTrue('配置的预热迭代次数应合理', LConfig.WarmupIterations >= 0);
  AssertTrue('配置的测量迭代次数应大于0', LConfig.MeasureIterations > 0);
  
  // 测试 Config 属性
  LConfig := FResult.Config;
  AssertTrue('Config 属性的预热迭代次数应合理', LConfig.WarmupIterations >= 0);
  AssertTrue('Config 属性的测量迭代次数应大于0', LConfig.MeasureIterations > 0);
end;

procedure TTestCase_BenchmarkResult.Test_BenchmarkResult_GetStatistics;
var
  LStats: TBenchmarkStatistics;
begin
  AssertNotNull('结果对象不应为空', FResult);
  
  LStats := FResult.GetStatistics;
  AssertTrue('统计数据的样本数量应大于0', LStats.SampleCount > 0);
  AssertTrue('统计数据的平均值应大于0', LStats.Mean > 0);
  AssertTrue('统计数据的最小值应大于0', LStats.Min > 0);
  AssertTrue('统计数据的最大值应大于0', LStats.Max > 0);
  AssertTrue('最大值应大于等于最小值', LStats.Max >= LStats.Min);
  AssertTrue('标准差应大于等于0', LStats.StdDev >= 0);
  
  // 测试 Statistics 属性
  LStats := FResult.Statistics;
  AssertTrue('Statistics 属性的样本数量应大于0', LStats.SampleCount > 0);
  AssertTrue('Statistics 属性的平均值应大于0', LStats.Mean > 0);
end;

procedure TTestCase_BenchmarkResult.Test_BenchmarkResult_GetTimePerIteration;
var
  LTimePerIter: Double;
begin
  AssertNotNull('结果对象不应为空', FResult);
  
  LTimePerIter := FResult.GetTimePerIteration();
  AssertTrue('每次迭代时间应大于0', LTimePerIter > 0);
  
  // 验证计算是否正确
  AssertEquals('每次迭代时间应等于总时间除以迭代次数', 
    FResult.TotalTime / FResult.Iterations, LTimePerIter, 0.001);
end;

procedure TTestCase_BenchmarkResult.Test_BenchmarkResult_GetTimePerIteration_Units;
var
  LTimeNS, LTimeUS, LTimeMS, LTimeS: Double;
begin
  AssertNotNull('结果对象不应为空', FResult);
  
  LTimeNS := FResult.GetTimePerIteration(buNanoSeconds);
  LTimeUS := FResult.GetTimePerIteration(buMicroSeconds);
  LTimeMS := FResult.GetTimePerIteration(buMilliSeconds);
  LTimeS := FResult.GetTimePerIteration(buSeconds);
  
  AssertTrue('纳秒时间应大于0', LTimeNS > 0);
  AssertTrue('微秒时间应大于0', LTimeUS > 0);
  AssertTrue('毫秒时间应大于0', LTimeMS > 0);
  AssertTrue('秒时间应大于0', LTimeS > 0);
  
  // 验证单位转换
  AssertEquals('微秒应等于纳秒除以1000', LTimeNS / 1000, LTimeUS, 0.001);
  AssertEquals('毫秒应等于微秒除以1000', LTimeUS / 1000, LTimeMS, 0.001);
  AssertEquals('秒应等于毫秒除以1000', LTimeMS / 1000, LTimeS, 0.001);
end;

procedure TTestCase_BenchmarkResult.Test_BenchmarkResult_GetThroughput;
var
  LThroughput: Double;
begin
  AssertNotNull('结果对象不应为空', FResult);
  
  LThroughput := FResult.GetThroughput;
  AssertTrue('吞吐量应大于0', LThroughput > 0);
  
  // 验证计算是否正确（每秒迭代次数）
  AssertEquals('吞吐量应等于迭代次数乘以10^9除以总时间', 
    (FResult.Iterations * 1000000000.0) / FResult.TotalTime, LThroughput, 0.001);
end;

procedure TTestCase_BenchmarkResult.Test_BenchmarkResult_GetBytesPerSecond;
var
  LBytesPerSec: Double;
begin
  AssertNotNull('结果对象不应为空', FResult);
  
  LBytesPerSec := FResult.GetBytesPerSecond;
  // 对于传统结果，字节吞吐量应该为0（不支持）
  AssertEquals('传统结果的字节吞吐量应为0', 0.0, LBytesPerSec, 0.001);
  
  // 测试 BytesPerSecond 属性
  AssertEquals('BytesPerSecond 属性应为0', 0.0, FResult.BytesPerSecond, 0.001);
end;

procedure TTestCase_BenchmarkResult.Test_BenchmarkResult_GetItemsPerSecond;
var
  LItemsPerSec: Double;
begin
  AssertNotNull('结果对象不应为空', FResult);
  
  LItemsPerSec := FResult.GetItemsPerSecond;
  // 对于传统结果，项目吞吐量应该为0（不支持）
  AssertEquals('传统结果的项目吞吐量应为0', 0.0, LItemsPerSec, 0.001);
  
  // 测试 ItemsPerSecond 属性
  AssertEquals('ItemsPerSecond 属性应为0', 0.0, FResult.ItemsPerSecond, 0.001);
end;

procedure TTestCase_BenchmarkResult.Test_BenchmarkResult_GetCounters;
var
  LCounters: TBenchmarkCounterArray;
begin
  AssertNotNull('结果对象不应为空', FResult);
  
  LCounters := FResult.GetCounters;
  // 对于传统结果，计数器数组应该为空
  AssertEquals('传统结果的计数器数组应为空', 0, Length(LCounters));
  
  // 测试 Counters 属性
  LCounters := FResult.Counters;
  AssertEquals('Counters 属性应为空', 0, Length(LCounters));
end;

procedure TTestCase_BenchmarkResult.Test_BenchmarkResult_GetSamples;
var
  LSamples: TBenchmarkSampleArray;
begin
  AssertNotNull('结果对象不应为空', FResult);
  
  LSamples := FResult.GetSamples;
  AssertTrue('样本数组应不为空', Length(LSamples) > 0);
  
  // 验证样本数据
  var LI: Integer;
  for LI := 0 to High(LSamples) do
    AssertTrue('样本值应大于0', LSamples[LI] > 0);
end;

procedure TTestCase_BenchmarkResult.Test_BenchmarkResult_HasStatistics;
begin
  AssertNotNull('结果对象不应为空', FResult);
  
  AssertTrue('结果应该有统计数据', FResult.HasStatistics);
end;

procedure TTestCase_BenchmarkResult.Test_BenchmarkResult_GetComplexityN;
var
  LComplexityN: Int64;
begin
  AssertNotNull('结果对象不应为空', FResult);
  
  LComplexityN := FResult.GetComplexityN;
  // 对于传统结果，复杂度参数应该为0（不支持）
  AssertEquals('传统结果的复杂度参数应为0', 0, LComplexityN);
  
  // 测试 ComplexityN 属性
  AssertEquals('ComplexityN 属性应为0', 0, FResult.ComplexityN);
end;

procedure TTestCase_BenchmarkResult.Test_BenchmarkResult_GetTimePerIteration_ZeroIterations;
begin
  // 这个测试比较难实现，因为我们无法轻易创建迭代次数为0的结果
  // 我们需要通过其他方式测试这种异常情况
  // 暂时跳过这个测试
  Ignore('无法轻易创建迭代次数为0的结果进行测试');
end;

procedure TTestCase_BenchmarkResult.Test_BenchmarkResult_GetThroughput_ZeroTime;
begin
  // 这个测试比较难实现，因为我们无法轻易创建总时间为0的结果
  // 我们需要通过其他方式测试这种异常情况
  // 暂时跳过这个测试
  Ignore('无法轻易创建总时间为0的结果进行测试');
end;

initialization
  RegisterTest(TTestCase_BenchmarkResult);

end.
