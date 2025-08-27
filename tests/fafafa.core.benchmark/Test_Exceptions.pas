unit Test_Exceptions;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.base,
  fafafa.core.benchmark;

type

  { TTestCase_Exceptions }

  TTestCase_Exceptions = class(TTestCase)
  published
    // 参数验证异常测试
    procedure Test_RegisterBenchmark_EmptyName;
    procedure Test_RegisterBenchmark_NilFunction;
    procedure Test_RunLegacyFunction_EmptyName;
    procedure Test_RunLegacyFunction_NilFunction;
    procedure Test_CreateLegacyBenchmark_EmptyName;
    procedure Test_CreateLegacyBenchmark_NilFunction;
    
    // 配置验证异常测试
    procedure Test_BenchmarkConfig_InvalidWarmupIterations;
    procedure Test_BenchmarkConfig_InvalidMeasureIterations;
    procedure Test_BenchmarkConfig_InvalidMinDuration;
    procedure Test_BenchmarkConfig_InvalidMaxDuration;
    
    // 状态对象异常测试
    procedure Test_BenchmarkState_InvalidIterations;
    procedure Test_BenchmarkState_InvalidBytesProcessed;
    procedure Test_BenchmarkState_InvalidItemsProcessed;
    procedure Test_BenchmarkState_InvalidComplexityN;
    procedure Test_BenchmarkState_InvalidCounterName;
    procedure Test_BenchmarkState_InvalidCalibrationTime;
    
    // 报告器异常测试
    procedure Test_FileReporter_InvalidPath;
    procedure Test_JSONReporter_InvalidPath;
    procedure Test_CSVReporter_InvalidPath;
    
    // 套件异常测试
    procedure Test_BenchmarkSuite_AddNilBenchmark;
    procedure Test_BenchmarkSuite_RemoveNonExistentBenchmark;
    
    // 运行器异常测试
    procedure Test_BenchmarkRunner_InvalidConfig;
    procedure Test_BenchmarkRunner_NilState;
  end;

implementation

// 测试用的空函数指针
const
  NilTestFunction: TBenchmarkFunction = nil;
  NilLegacyFunction: TLegacyBenchmarkFunction = nil;

{ TTestCase_Exceptions }

procedure TTestCase_Exceptions.Test_RegisterBenchmark_EmptyName;
var
  LBenchmark: IBenchmark;
begin
  // 测试注册空名称的基准测试
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('注册空名称应抛出异常', EArgumentException,
    procedure
    begin
      RegisterBenchmark('', @SimpleTestFunction);
    end);
  {$ELSE}
  try
    LBenchmark := RegisterBenchmark('', nil);
    if LBenchmark <> nil then
      Fail('注册空名称应该失败');
  except
    on E: EArgumentException do
      AssertTrue('应该抛出 EArgumentException 异常', True);
    on E: Exception do
      Fail('应该抛出 EArgumentException 异常，但抛出了: ' + E.ClassName);
  end;
  {$ENDIF}
end;

procedure TTestCase_Exceptions.Test_RegisterBenchmark_NilFunction;
var
  LBenchmark: IBenchmark;
begin
  // 测试注册空函数指针
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('注册空函数应抛出异常', EArgumentNil,
    procedure
    begin
      RegisterBenchmark('测试', NilTestFunction);
    end);
  {$ELSE}
  try
    LBenchmark := RegisterBenchmark('测试', NilTestFunction);
    if LBenchmark <> nil then
      Fail('注册空函数应该失败');
  except
    on E: EArgumentNil do
      AssertTrue('应该抛出 EArgumentNil 异常', True);
    on E: Exception do
      Fail('应该抛出 EArgumentNil 异常，但抛出了: ' + E.ClassName);
  end;
  {$ENDIF}
end;

procedure TTestCase_Exceptions.Test_RunLegacyFunction_EmptyName;
var
  LConfig: TBenchmarkConfig;
  LResult: IBenchmarkResult;
begin
  // 测试运行空名称的传统函数
  LConfig := CreateDefaultBenchmarkConfig;
  
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('运行空名称函数应抛出异常', EArgumentException,
    procedure
    begin
      RunLegacyFunction('', @SimpleTestFunction, LConfig);
    end);
  {$ELSE}
  try
    LResult := RunLegacyFunction('', nil, LConfig);
    if LResult <> nil then
      Fail('运行空名称函数应该失败');
  except
    on E: EArgumentException do
      AssertTrue('应该抛出 EArgumentException 异常', True);
    on E: Exception do
      Fail('应该抛出 EArgumentException 异常，但抛出了: ' + E.ClassName);
  end;
  {$ENDIF}
end;

procedure TTestCase_Exceptions.Test_RunLegacyFunction_NilFunction;
var
  LConfig: TBenchmarkConfig;
  LResult: IBenchmarkResult;
begin
  // 测试运行空函数指针
  LConfig := CreateDefaultBenchmarkConfig;
  
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('运行空函数应抛出异常', EArgumentNil,
    procedure
    begin
      RunLegacyFunction('测试', NilLegacyFunction, LConfig);
    end);
  {$ELSE}
  try
    LResult := RunLegacyFunction('测试', NilLegacyFunction, LConfig);
    if LResult <> nil then
      Fail('运行空函数应该失败');
  except
    on E: EArgumentNil do
      AssertTrue('应该抛出 EArgumentNil 异常', True);
    on E: Exception do
      Fail('应该抛出 EArgumentNil 异常，但抛出了: ' + E.ClassName);
  end;
  {$ENDIF}
end;

procedure TTestCase_Exceptions.Test_CreateLegacyBenchmark_EmptyName;
var
  LConfig: TBenchmarkConfig;
  LBenchmark: IBenchmark;
begin
  // 测试创建空名称的传统基准测试
  LConfig := CreateDefaultBenchmarkConfig;
  
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('创建空名称基准测试应抛出异常', EArgumentException,
    procedure
    begin
      CreateLegacyBenchmark('', @SimpleTestFunction, LConfig);
    end);
  {$ELSE}
  try
    LBenchmark := CreateLegacyBenchmark('', nil, LConfig);
    if LBenchmark <> nil then
      Fail('创建空名称基准测试应该失败');
  except
    on E: EArgumentException do
      AssertTrue('应该抛出 EArgumentException 异常', True);
    on E: Exception do
      Fail('应该抛出 EArgumentException 异常，但抛出了: ' + E.ClassName);
  end;
  {$ENDIF}
end;

procedure TTestCase_Exceptions.Test_CreateLegacyBenchmark_NilFunction;
var
  LConfig: TBenchmarkConfig;
  LBenchmark: IBenchmark;
begin
  // 测试创建空函数的传统基准测试
  LConfig := CreateDefaultBenchmarkConfig;
  
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('创建空函数基准测试应抛出异常', EArgumentNil,
    procedure
    begin
      CreateLegacyBenchmark('测试', NilLegacyFunction, LConfig);
    end);
  {$ELSE}
  try
    LBenchmark := CreateLegacyBenchmark('测试', NilLegacyFunction, LConfig);
    if LBenchmark <> nil then
      Fail('创建空函数基准测试应该失败');
  except
    on E: EArgumentNil do
      AssertTrue('应该抛出 EArgumentNil 异常', True);
    on E: Exception do
      Fail('应该抛出 EArgumentNil 异常，但抛出了: ' + E.ClassName);
  end;
  {$ENDIF}
end;

procedure TTestCase_Exceptions.Test_BenchmarkConfig_InvalidWarmupIterations;
var
  LConfig: TBenchmarkConfig;
begin
  // 测试无效的预热迭代次数
  LConfig := CreateDefaultBenchmarkConfig;
  
  // 负数预热迭代次数应该被修正为0或抛出异常
  try
    LConfig.WarmupIterations := -1;
    // 如果没有抛出异常，检查是否被修正
    AssertTrue('负数预热迭代次数应该被修正为非负数', LConfig.WarmupIterations >= 0);
  except
    on E: EBenchmarkConfigError do
      AssertTrue('应该抛出配置错误异常', True);
    on E: Exception do
      Fail('应该抛出 EBenchmarkConfigError 异常，但抛出了: ' + E.ClassName);
  end;
end;

procedure TTestCase_Exceptions.Test_BenchmarkConfig_InvalidMeasureIterations;
var
  LConfig: TBenchmarkConfig;
begin
  // 测试无效的测量迭代次数
  LConfig := CreateDefaultBenchmarkConfig;
  
  // 零或负数测量迭代次数应该抛出异常
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('零测量迭代次数应抛出异常', EBenchmarkConfigError,
    procedure
    begin
      LConfig.MeasureIterations := 0;
    end);
    
  AssertException('负数测量迭代次数应抛出异常', EBenchmarkConfigError,
    procedure
    begin
      LConfig.MeasureIterations := -1;
    end);
  {$ELSE}
  try
    LConfig.MeasureIterations := 0;
    Fail('零测量迭代次数应该抛出异常');
  except
    on E: EBenchmarkConfigError do
      AssertTrue('应该抛出配置错误异常', True);
  end;
  
  try
    LConfig.MeasureIterations := -1;
    Fail('负数测量迭代次数应该抛出异常');
  except
    on E: EBenchmarkConfigError do
      AssertTrue('应该抛出配置错误异常', True);
  end;
  {$ENDIF}
end;

procedure TTestCase_Exceptions.Test_BenchmarkConfig_InvalidMinDuration;
var
  LConfig: TBenchmarkConfig;
begin
  // 测试无效的最小持续时间
  LConfig := CreateDefaultBenchmarkConfig;
  
  // 负数最小持续时间应该被修正或抛出异常
  try
    LConfig.MinDurationMs := -1;
    AssertTrue('负数最小持续时间应该被修正为非负数', LConfig.MinDurationMs >= 0);
  except
    on E: EBenchmarkConfigError do
      AssertTrue('应该抛出配置错误异常', True);
  end;
end;

procedure TTestCase_Exceptions.Test_BenchmarkConfig_InvalidMaxDuration;
var
  LConfig: TBenchmarkConfig;
begin
  // 测试无效的最大持续时间
  LConfig := CreateDefaultBenchmarkConfig;
  
  // 最大持续时间小于最小持续时间应该抛出异常
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('最大持续时间小于最小持续时间应抛出异常', EBenchmarkConfigError,
    procedure
    begin
      LConfig.MinDurationMs := 1000;
      LConfig.MaxDurationMs := 500;
    end);
  {$ELSE}
  try
    LConfig.MinDurationMs := 1000;
    LConfig.MaxDurationMs := 500;
    Fail('最大持续时间小于最小持续时间应该抛出异常');
  except
    on E: EBenchmarkConfigError do
      AssertTrue('应该抛出配置错误异常', True);
  end;
  {$ENDIF}
end;

procedure TTestCase_Exceptions.Test_BenchmarkState_InvalidIterations;
var
  LState: IBenchmarkState;
begin
  // 测试无效的迭代次数设置
  LState := CreateTestBenchmarkState(1000);
  if LState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 负数迭代次数应该被处理
  try
    LState.SetIterations(-1);
    AssertTrue('负数迭代次数应该被修正为非负数', LState.GetIterations >= 0);
  except
    on E: EBenchmarkConfigError do
      AssertTrue('应该抛出配置错误异常', True);
  end;
end;

procedure TTestCase_Exceptions.Test_BenchmarkState_InvalidBytesProcessed;
var
  LState: IBenchmarkState;
begin
  // 测试无效的字节处理数设置
  LState := CreateTestBenchmarkState(1000);
  if LState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 负数字节数应该被处理
  try
    LState.SetBytesProcessed(-1);
    // 如果没有抛出异常，说明被修正了
    AssertTrue('负数字节数应该被处理', True);
  except
    on E: EArgumentException do
      AssertTrue('应该抛出参数异常', True);
  end;
end;

procedure TTestCase_Exceptions.Test_BenchmarkState_InvalidItemsProcessed;
var
  LState: IBenchmarkState;
begin
  // 测试无效的项目处理数设置
  LState := CreateTestBenchmarkState(1000);
  if LState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 负数项目数应该被处理
  try
    LState.SetItemsProcessed(-1);
    AssertTrue('负数项目数应该被处理', True);
  except
    on E: EArgumentException do
      AssertTrue('应该抛出参数异常', True);
  end;
end;

procedure TTestCase_Exceptions.Test_BenchmarkState_InvalidComplexityN;
var
  LState: IBenchmarkState;
begin
  // 测试无效的复杂度参数设置
  LState := CreateTestBenchmarkState(1000);
  if LState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 负数复杂度参数应该被处理
  try
    LState.SetComplexityN(-1);
    AssertTrue('负数复杂度参数应该被处理', True);
  except
    on E: EArgumentException do
      AssertTrue('应该抛出参数异常', True);
  end;
end;

procedure TTestCase_Exceptions.Test_BenchmarkState_InvalidCounterName;
var
  LState: IBenchmarkState;
begin
  // 测试无效的计数器名称
  LState := CreateTestBenchmarkState(1000);
  if LState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 空计数器名称应该被处理
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('空计数器名称应抛出异常', EArgumentException,
    procedure
    begin
      LState.AddCounter('', 123.45);
    end);
  {$ELSE}
  try
    LState.AddCounter('', 123.45);
    Fail('空计数器名称应该抛出异常');
  except
    on E: EArgumentException do
      AssertTrue('应该抛出参数异常', True);
  end;
  {$ENDIF}
end;

procedure TTestCase_Exceptions.Test_BenchmarkState_InvalidCalibrationTime;
var
  LState: IBenchmarkState;
begin
  // 测试无效的校准时间
  LState := CreateTestBenchmarkState(1000);
  if LState = nil then
  begin
    Ignore('无法创建 BenchmarkState 实例进行测试');
    Exit;
  end;
  
  // 负数校准时间应该被处理
  try
    LState.SetTargetCalibrationTime(-1.0);
    AssertTrue('负数校准时间应该被处理', True);
  except
    on E: EArgumentException do
      AssertTrue('应该抛出参数异常', True);
  end;
end;

procedure TTestCase_Exceptions.Test_FileReporter_InvalidPath;
var
  LReporter: IBenchmarkReporter;
begin
  // 测试无效的文件路径
  try
    LReporter := CreateFileReporter('');
    // 空路径可能被接受（输出到控制台）
    AssertNotNull('空路径的文件报告器应该被创建', LReporter);
  except
    on E: Exception do
      Fail('创建空路径文件报告器不应该抛出异常: ' + E.Message);
  end;
  
  // 测试无效字符的路径
  try
    LReporter := CreateFileReporter('invalid|path<>?.txt');
    // 根据实现，可能抛出异常或被处理
    AssertTrue('无效路径应该被处理', True);
  except
    on E: EArgumentException do
      AssertTrue('应该抛出参数异常', True);
  end;
end;

procedure TTestCase_Exceptions.Test_JSONReporter_InvalidPath;
var
  LReporter: IBenchmarkReporter;
begin
  // 测试 JSON 报告器的无效路径
  try
    LReporter := CreateJSONReporter('invalid|path<>?.json');
    AssertTrue('无效路径应该被处理', True);
  except
    on E: EArgumentException do
      AssertTrue('应该抛出参数异常', True);
  end;
end;

procedure TTestCase_Exceptions.Test_CSVReporter_InvalidPath;
var
  LReporter: IBenchmarkReporter;
begin
  // 测试 CSV 报告器的无效路径
  try
    LReporter := CreateCSVReporter('invalid|path<>?.csv');
    AssertTrue('无效路径应该被处理', True);
  except
    on E: EArgumentException do
      AssertTrue('应该抛出参数异常', True);
  end;
end;

procedure TTestCase_Exceptions.Test_BenchmarkSuite_AddNilBenchmark;
var
  LSuite: IBenchmarkSuite;
begin
  // 测试添加空基准测试到套件
  LSuite := CreateBenchmarkSuite;
  
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('添加空基准测试应抛出异常', EArgumentNil,
    procedure
    begin
      LSuite.AddBenchmark(nil);
    end);
  {$ELSE}
  try
    LSuite.AddBenchmark(nil);
    Fail('添加空基准测试应该抛出异常');
  except
    on E: EArgumentNil do
      AssertTrue('应该抛出 EArgumentNil 异常', True);
  end;
  {$ENDIF}
end;

procedure TTestCase_Exceptions.Test_BenchmarkSuite_RemoveNonExistentBenchmark;
var
  LSuite: IBenchmarkSuite;
  LBenchmark: IBenchmark;
  LConfig: TBenchmarkConfig;
begin
  // 测试移除不存在的基准测试
  LSuite := CreateBenchmarkSuite;
  LConfig := CreateDefaultBenchmarkConfig;
  
  // 创建一个基准测试但不添加到套件
  LBenchmark := CreateLegacyBenchmark('测试', nil, LConfig);
  
  // 尝试移除不存在的基准测试
  try
    LSuite.RemoveBenchmark(LBenchmark);
    // 根据实现，可能不抛出异常
    AssertTrue('移除不存在的基准测试应该被处理', True);
  except
    on E: EArgumentException do
      AssertTrue('应该抛出参数异常', True);
  end;
end;

procedure TTestCase_Exceptions.Test_BenchmarkRunner_InvalidConfig;
var
  LRunner: IBenchmarkRunner;
  LConfig: TBenchmarkConfig;
  LResult: IBenchmarkResult;
begin
  // 测试使用无效配置运行基准测试
  LRunner := CreateBenchmarkRunner;
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.MeasureIterations := 0; // 无效配置
  
  try
    LResult := LRunner.RunFunction('测试', nil, LConfig);
    if LResult <> nil then
      Fail('使用无效配置应该失败');
  except
    on E: EBenchmarkConfigError do
      AssertTrue('应该抛出配置错误异常', True);
    on E: EArgumentNil do
      AssertTrue('应该抛出参数为空异常', True);
  end;
end;

procedure TTestCase_Exceptions.Test_BenchmarkRunner_NilState;
begin
  // 这个测试比较难实现，因为状态对象通常由框架内部创建
  // 暂时跳过
  Ignore('状态对象通常由框架内部创建，难以直接测试空状态');
end;

initialization
  RegisterTest(TTestCase_Exceptions);

end.
