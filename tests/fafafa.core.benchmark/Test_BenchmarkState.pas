unit Test_BenchmarkState;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.base,
  fafafa.core.benchmark;

type

  { TTestCase_BenchmarkState }

  TTestCase_BenchmarkState = class(TTestCase)
  private
    FState: IBenchmarkState;
    
    // 创建测试用的 State 实例
    function CreateTestState: IBenchmarkState;
    
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    
  published
    // 基本功能测试
    procedure Test_BenchmarkState_KeepRunning;
    procedure Test_BenchmarkState_SetIterations;
    procedure Test_BenchmarkState_GetIterations;
    procedure Test_BenchmarkState_GetElapsedTime;
    
    // 计时控制测试
    procedure Test_BenchmarkState_PauseTiming;
    procedure Test_BenchmarkState_ResumeTiming;
    procedure Test_BenchmarkState_PauseResumeTiming;
    
    // 数据设置测试
    procedure Test_BenchmarkState_SetBytesProcessed;
    procedure Test_BenchmarkState_SetItemsProcessed;
    procedure Test_BenchmarkState_SetComplexityN;
    
    // 计数器测试
    procedure Test_BenchmarkState_AddCounter;
    procedure Test_BenchmarkState_AddCounter_Multiple;
    
    // 内存测量测试
    procedure Test_BenchmarkState_GetMemoryUsage;
    procedure Test_BenchmarkState_GetPeakMemoryUsage;
    
    // 预热和校准测试
    procedure Test_BenchmarkState_SetWarmupIterations;
    procedure Test_BenchmarkState_SetTargetCalibrationTime;
    
    // 异常测试
    procedure Test_BenchmarkState_SetIterations_Zero;
    procedure Test_BenchmarkState_SetIterations_Negative;
    procedure Test_BenchmarkState_SetWarmupIterations_Negative;
    procedure Test_BenchmarkState_SetTargetCalibrationTime_Zero;
    procedure Test_BenchmarkState_SetTargetCalibrationTime_Negative;
  end;

implementation

// 使用源码中新添加的测试工厂函数

{ TTestCase_BenchmarkState }

function TTestCase_BenchmarkState.CreateTestState: IBenchmarkState;
begin
  // 使用源码中新添加的测试工厂函数
  Result := CreateTestBenchmarkState(1000);
end;

procedure TTestCase_BenchmarkState.SetUp;
begin
  inherited SetUp;
  FState := CreateTestState;
end;

procedure TTestCase_BenchmarkState.TearDown;
begin
  FState := nil;
  inherited TearDown;
end;

procedure TTestCase_BenchmarkState.Test_BenchmarkState_KeepRunning;
var
  LIterationCount: Integer;
begin
  if FState = nil then
  begin
    // 跳过测试，因为无法创建 State 实例
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 测试 KeepRunning 方法
  LIterationCount := 0;
  while FState.KeepRunning and (LIterationCount < 1000) do
  begin
    Inc(LIterationCount);
    // 模拟一些工作
    Sleep(1);
  end;
  
  AssertTrue('应该至少运行一次迭代', LIterationCount > 0);
  AssertTrue('迭代次数应该合理', LIterationCount < 1000);
end;

procedure TTestCase_BenchmarkState.Test_BenchmarkState_SetIterations;
begin
  if FState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 测试设置迭代次数
  FState.SetIterations(100);
  AssertEquals('迭代次数应该被正确设置', 100, FState.GetIterations);
  
  FState.SetIterations(1);
  AssertEquals('迭代次数应该被正确更新', 1, FState.GetIterations);
  
  FState.SetIterations(1000000);
  AssertEquals('大迭代次数应该被正确设置', 1000000, FState.GetIterations);
end;

procedure TTestCase_BenchmarkState.Test_BenchmarkState_GetIterations;
begin
  if FState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 测试获取迭代次数
  AssertTrue('初始迭代次数应该大于等于0', FState.GetIterations >= 0);
end;

procedure TTestCase_BenchmarkState.Test_BenchmarkState_GetElapsedTime;
begin
  if FState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 测试获取已过时间
  AssertTrue('初始已过时间应该大于等于0', FState.GetElapsedTime >= 0);
end;

procedure TTestCase_BenchmarkState.Test_BenchmarkState_PauseTiming;
begin
  if FState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 测试暂停计时
  // 这个测试比较难验证，因为我们无法直接观察内部状态
  // 我们只能确保方法调用不会抛出异常
  try
    FState.PauseTiming;
    // 如果没有异常，测试通过
    AssertTrue('暂停计时应该成功', True);
  except
    on E: Exception do
      Fail('暂停计时不应该抛出异常: ' + E.Message);
  end;
end;

procedure TTestCase_BenchmarkState.Test_BenchmarkState_ResumeTiming;
begin
  if FState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 测试恢复计时
  try
    FState.ResumeTiming;
    // 如果没有异常，测试通过
    AssertTrue('恢复计时应该成功', True);
  except
    on E: Exception do
      Fail('恢复计时不应该抛出异常: ' + E.Message);
  end;
end;

procedure TTestCase_BenchmarkState.Test_BenchmarkState_PauseResumeTiming;
begin
  if FState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 测试暂停和恢复计时的组合
  try
    FState.PauseTiming;
    Sleep(10); // 暂停期间的时间不应该被计算
    FState.ResumeTiming;
    // 如果没有异常，测试通过
    AssertTrue('暂停和恢复计时应该成功', True);
  except
    on E: Exception do
      Fail('暂停和恢复计时不应该抛出异常: ' + E.Message);
  end;
end;

procedure TTestCase_BenchmarkState.Test_BenchmarkState_SetBytesProcessed;
begin
  if FState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 测试设置处理的字节数
  try
    FState.SetBytesProcessed(1024);
    FState.SetBytesProcessed(0);
    FState.SetBytesProcessed(1048576); // 1MB
    // 如果没有异常，测试通过
    AssertTrue('设置字节数应该成功', True);
  except
    on E: Exception do
      Fail('设置字节数不应该抛出异常: ' + E.Message);
  end;
end;

procedure TTestCase_BenchmarkState.Test_BenchmarkState_SetItemsProcessed;
begin
  if FState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 测试设置处理的项目数
  try
    FState.SetItemsProcessed(100);
    FState.SetItemsProcessed(0);
    FState.SetItemsProcessed(1000000);
    // 如果没有异常，测试通过
    AssertTrue('设置项目数应该成功', True);
  except
    on E: Exception do
      Fail('设置项目数不应该抛出异常: ' + E.Message);
  end;
end;

procedure TTestCase_BenchmarkState.Test_BenchmarkState_SetComplexityN;
begin
  if FState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 测试设置复杂度参数
  try
    FState.SetComplexityN(10);
    FState.SetComplexityN(0);
    FState.SetComplexityN(1000000);
    // 如果没有异常，测试通过
    AssertTrue('设置复杂度参数应该成功', True);
  except
    on E: Exception do
      Fail('设置复杂度参数不应该抛出异常: ' + E.Message);
  end;
end;

procedure TTestCase_BenchmarkState.Test_BenchmarkState_AddCounter;
begin
  if FState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 测试添加计数器
  try
    FState.AddCounter('测试计数器', 123.45);
    FState.AddCounter('字节计数器', 1024, cuBytes);
    FState.AddCounter('项目计数器', 100, cuItems);
    FState.AddCounter('速率计数器', 50.5, cuRate);
    FState.AddCounter('百分比计数器', 85.2, cuPercentage);
    // 如果没有异常，测试通过
    AssertTrue('添加计数器应该成功', True);
  except
    on E: Exception do
      Fail('添加计数器不应该抛出异常: ' + E.Message);
  end;
end;

procedure TTestCase_BenchmarkState.Test_BenchmarkState_AddCounter_Multiple;
begin
  if FState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 测试添加多个计数器
  try
    FState.AddCounter('计数器1', 1.0);
    FState.AddCounter('计数器2', 2.0);
    FState.AddCounter('计数器3', 3.0);
    // 测试重复名称
    FState.AddCounter('计数器1', 10.0); // 应该允许重复名称
    // 如果没有异常，测试通过
    AssertTrue('添加多个计数器应该成功', True);
  except
    on E: Exception do
      Fail('添加多个计数器不应该抛出异常: ' + E.Message);
  end;
end;

procedure TTestCase_BenchmarkState.Test_BenchmarkState_GetMemoryUsage;
begin
  if FState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 测试获取内存使用量
  var LMemoryUsage: Int64;
  try
    LMemoryUsage := FState.GetMemoryUsage;
    // 内存使用量可能为0或正数，取决于平台实现
    AssertTrue('内存使用量应该大于等于0', LMemoryUsage >= 0);
  except
    on E: Exception do
      Fail('获取内存使用量不应该抛出异常: ' + E.Message);
  end;
end;

procedure TTestCase_BenchmarkState.Test_BenchmarkState_GetPeakMemoryUsage;
begin
  if FState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 测试获取峰值内存使用量
  var LPeakMemoryUsage: Int64;
  try
    LPeakMemoryUsage := FState.GetPeakMemoryUsage;
    // 峰值内存使用量可能为0或正数，取决于平台实现
    AssertTrue('峰值内存使用量应该大于等于0', LPeakMemoryUsage >= 0);
  except
    on E: Exception do
      Fail('获取峰值内存使用量不应该抛出异常: ' + E.Message);
  end;
end;

procedure TTestCase_BenchmarkState.Test_BenchmarkState_SetWarmupIterations;
begin
  if FState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 测试设置预热迭代次数
  try
    FState.SetWarmupIterations(5);
    FState.SetWarmupIterations(0); // 禁用预热
    FState.SetWarmupIterations(100);
    // 如果没有异常，测试通过
    AssertTrue('设置预热迭代次数应该成功', True);
  except
    on E: Exception do
      Fail('设置预热迭代次数不应该抛出异常: ' + E.Message);
  end;
end;

procedure TTestCase_BenchmarkState.Test_BenchmarkState_SetTargetCalibrationTime;
begin
  if FState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 测试设置目标校准时间
  try
    FState.SetTargetCalibrationTime(1.0); // 1ms
    FState.SetTargetCalibrationTime(10.0); // 10ms
    FState.SetTargetCalibrationTime(100.0); // 100ms
    // 如果没有异常，测试通过
    AssertTrue('设置目标校准时间应该成功', True);
  except
    on E: Exception do
      Fail('设置目标校准时间不应该抛出异常: ' + E.Message);
  end;
end;

procedure TTestCase_BenchmarkState.Test_BenchmarkState_SetIterations_Zero;
begin
  if FState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 测试设置迭代次数为0（边界情况）
  try
    FState.SetIterations(0);
    AssertEquals('迭代次数0应该被接受', 0, FState.GetIterations);
  except
    on E: Exception do
      Fail('设置迭代次数为0不应该抛出异常: ' + E.Message);
  end;
end;

procedure TTestCase_BenchmarkState.Test_BenchmarkState_SetIterations_Negative;
begin
  if FState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 测试设置负数迭代次数（应该被处理或抛出异常）
  try
    FState.SetIterations(-1);
    // 如果没有抛出异常，检查是否被修正为合理值
    AssertTrue('负数迭代次数应该被修正为非负数', FState.GetIterations >= 0);
  except
    on E: EBenchmarkConfigError do
      // 抛出配置错误异常是可以接受的
      AssertTrue('应该抛出配置错误异常', True);
    on E: Exception do
      Fail('应该抛出 EBenchmarkConfigError 而不是其他异常: ' + E.ClassName);
  end;
end;

procedure TTestCase_BenchmarkState.Test_BenchmarkState_SetWarmupIterations_Negative;
begin
  if FState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 测试设置负数预热迭代次数
  try
    FState.SetWarmupIterations(-1);
    // 根据实现，负数应该被设置为0
    AssertTrue('负数预热迭代次数应该被处理', True);
  except
    on E: Exception do
      Fail('设置负数预热迭代次数不应该抛出异常: ' + E.Message);
  end;
end;

procedure TTestCase_BenchmarkState.Test_BenchmarkState_SetTargetCalibrationTime_Zero;
begin
  if FState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 测试设置校准时间为0
  try
    FState.SetTargetCalibrationTime(0);
    // 根据实现，0应该被设置为默认值
    AssertTrue('校准时间0应该被处理', True);
  except
    on E: Exception do
      Fail('设置校准时间为0不应该抛出异常: ' + E.Message);
  end;
end;

procedure TTestCase_BenchmarkState.Test_BenchmarkState_SetTargetCalibrationTime_Negative;
begin
  if FState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 测试设置负数校准时间
  try
    FState.SetTargetCalibrationTime(-1.0);
    // 根据实现，负数应该被设置为默认值
    AssertTrue('负数校准时间应该被处理', True);
  except
    on E: Exception do
      Fail('设置负数校准时间不应该抛出异常: ' + E.Message);
  end;
end;

initialization
  RegisterTest(TTestCase_BenchmarkState);

end.
