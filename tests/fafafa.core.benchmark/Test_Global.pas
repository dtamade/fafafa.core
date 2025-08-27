unit Test_Global;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.base,
  fafafa.core.benchmark;

type

  { TTestCase_Global }

  TTestCase_Global = class(TTestCase)
  published
    // 全局函数测试
    procedure Test_IIF;
    procedure Test_CreateDefaultBenchmarkConfig;
    procedure Test_CreateBenchmarkRunner;
    procedure Test_CreateBenchmarkSuite;
    procedure Test_CreateConsoleReporter;
    procedure Test_CreateFileReporter;
    procedure Test_CreateJSONReporter;
    procedure Test_CreateCSVReporter;
    
    // 全局注册机制测试
    procedure Test_RegisterBenchmark;
    procedure Test_RegisterBenchmarkMethod;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure Test_RegisterBenchmarkProc;
    {$ENDIF}
    procedure Test_RegisterBenchmarkWithFixture;
    procedure Test_RunAllBenchmarks;
    procedure Test_RunAllBenchmarksWithReporter;
    procedure Test_ClearAllBenchmarks;
    
    // 传统 API 测试
    procedure Test_RunLegacyFunction;
    procedure Test_RunLegacyMethod;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure Test_RunLegacyProc;
    {$ENDIF}
    procedure Test_CreateLegacyBenchmark;
    
    // 异常测试
    procedure Test_RegisterBenchmark_NilFunction;
    procedure Test_RunLegacyFunction_NilFunction;
  end;

implementation

// 测试用的简单函数
procedure SimpleTestFunction(aState: IBenchmarkState);
var
  LI: Integer;
  LSum: Integer;
begin
  LSum := 0;
  while aState.KeepRunning do
  begin
    for LI := 1 to 100 do
      LSum := LSum + LI;
  end;
end;

// 传统测试函数
procedure LegacyTestFunction;
var
  LI: Integer;
  LSum: Integer;
begin
  LSum := 0;
  for LI := 1 to 1000 do
    LSum := LSum + LI;
end;

// 测试用的方法类
type
  TTestMethods = class
  public
    procedure TestMethod(aState: IBenchmarkState);
    procedure LegacyTestMethod;
  end;

procedure TTestMethods.TestMethod(aState: IBenchmarkState);
var
  LI: Integer;
  LSum: Integer;
begin
  LSum := 0;
  while aState.KeepRunning do
  begin
    for LI := 1 to 50 do
      LSum := LSum + LI;
  end;
end;

procedure TTestMethods.LegacyTestMethod;
var
  LI: Integer;
  LSum: Integer;
begin
  LSum := 0;
  for LI := 1 to 500 do
    LSum := LSum + LI;
end;

// 测试用的夹具
type
  TTestFixture = class(TInterfacedObject, IBenchmarkFixture)
  public
    procedure SetUp(aState: IBenchmarkState);
    procedure TearDown(aState: IBenchmarkState);
  end;

procedure TTestFixture.SetUp(aState: IBenchmarkState);
begin
  // 设置代码
end;

procedure TTestFixture.TearDown(aState: IBenchmarkState);
begin
  // 清理代码
end;

{ TTestCase_Global }

procedure TTestCase_Global.Test_IIF;
begin
  // 测试 IIF 函数
  AssertEquals('true', IIF(True, 'true', 'false'));
  AssertEquals('false', IIF(False, 'true', 'false'));
  AssertEquals('', IIF(True, '', 'not empty'));
  AssertEquals('not empty', IIF(False, '', 'not empty'));
end;

procedure TTestCase_Global.Test_CreateDefaultBenchmarkConfig;
var
  LConfig: TBenchmarkConfig;
begin
  // 测试创建默认配置
  LConfig := CreateDefaultBenchmarkConfig;
  
  AssertEquals('默认模式应为 bmTime', Ord(bmTime), Ord(LConfig.Mode));
  AssertTrue('预热迭代次数应大于0', LConfig.WarmupIterations > 0);
  AssertTrue('测量迭代次数应大于0', LConfig.MeasureIterations > 0);
  AssertTrue('最小持续时间应大于0', LConfig.MinDurationMs > 0);
  AssertTrue('最大持续时间应大于最小持续时间', LConfig.MaxDurationMs > LConfig.MinDurationMs);
  AssertEquals('默认时间单位应为纳秒', Ord(buNanoSeconds), Ord(LConfig.TimeUnit));
  AssertFalse('默认不启用内存测量', LConfig.EnableMemoryMeasurement);
end;

procedure TTestCase_Global.Test_CreateBenchmarkRunner;
var
  LRunner: IBenchmarkRunner;
begin
  // 测试创建基准测试运行器
  LRunner := CreateBenchmarkRunner;
  AssertNotNull('运行器不应为空', LRunner);
end;

procedure TTestCase_Global.Test_CreateBenchmarkSuite;
var
  LSuite: IBenchmarkSuite;
begin
  // 测试创建基准测试套件
  LSuite := CreateBenchmarkSuite;
  AssertNotNull('套件不应为空', LSuite);
  AssertEquals('初始套件应为空', 0, LSuite.Count);
end;

procedure TTestCase_Global.Test_CreateConsoleReporter;
var
  LReporter: IBenchmarkReporter;
begin
  // 测试创建控制台报告器
  LReporter := CreateConsoleReporter;
  AssertNotNull('控制台报告器不应为空', LReporter);
end;

procedure TTestCase_Global.Test_CreateFileReporter;
var
  LReporter: IBenchmarkReporter;
  LFileName: string;
begin
  // 测试创建文件报告器
  LFileName := 'test_report.txt';
  LReporter := CreateFileReporter(LFileName);
  AssertNotNull('文件报告器不应为空', LReporter);
end;

procedure TTestCase_Global.Test_CreateJSONReporter;
var
  LReporter: IBenchmarkReporter;
begin
  // 测试创建 JSON 报告器
  LReporter := CreateJSONReporter('test_report.json');
  AssertNotNull('JSON 报告器不应为空', LReporter);
  
  // 测试无文件名的情况
  LReporter := CreateJSONReporter('');
  AssertNotNull('无文件名的 JSON 报告器不应为空', LReporter);
end;

procedure TTestCase_Global.Test_CreateCSVReporter;
var
  LReporter: IBenchmarkReporter;
begin
  // 测试创建 CSV 报告器
  LReporter := CreateCSVReporter('test_report.csv');
  AssertNotNull('CSV 报告器不应为空', LReporter);
  
  // 测试无文件名的情况
  LReporter := CreateCSVReporter('');
  AssertNotNull('无文件名的 CSV 报告器不应为空', LReporter);
end;

procedure TTestCase_Global.Test_RegisterBenchmark;
var
  LBenchmark: IBenchmark;
  LInitialCount: Integer;
begin
  // 清空之前的注册
  ClearAllBenchmarks;
  LInitialCount := 0;
  
  // 测试注册基准测试
  LBenchmark := RegisterBenchmark('测试基准', @SimpleTestFunction);
  AssertNotNull('注册的基准测试不应为空', LBenchmark);
  AssertEquals('基准测试名称应正确', '测试基准', LBenchmark.Name);
end;

procedure TTestCase_Global.Test_RegisterBenchmarkMethod;
var
  LBenchmark: IBenchmark;
  LTestObj: TTestMethods;
begin
  // 清空之前的注册
  ClearAllBenchmarks;
  
  LTestObj := TTestMethods.Create;
  try
    // 测试注册基准测试方法
    LBenchmark := RegisterBenchmarkMethod('测试方法基准', @LTestObj.TestMethod);
    AssertNotNull('注册的基准测试方法不应为空', LBenchmark);
    AssertEquals('基准测试方法名称应正确', '测试方法基准', LBenchmark.Name);
  finally
    LTestObj.Free;
  end;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TTestCase_Global.Test_RegisterBenchmarkProc;
var
  LBenchmark: IBenchmark;
begin
  // 清空之前的注册
  ClearAllBenchmarks;
  
  // 测试注册匿名过程基准测试
  LBenchmark := RegisterBenchmarkProc('测试过程基准',
    procedure(aState: IBenchmarkState)
    var
      LI: Integer;
      LSum: Integer;
    begin
      LSum := 0;
      while aState.KeepRunning do
      begin
        for LI := 1 to 10 do
          LSum := LSum + LI;
      end;
    end);
  
  AssertNotNull('注册的基准测试过程不应为空', LBenchmark);
  AssertEquals('基准测试过程名称应正确', '测试过程基准', LBenchmark.Name);
end;
{$ENDIF}

procedure TTestCase_Global.Test_RegisterBenchmarkWithFixture;
var
  LBenchmark: IBenchmark;
  LFixture: IBenchmarkFixture;
begin
  // 清空之前的注册
  ClearAllBenchmarks;
  
  LFixture := TTestFixture.Create;
  
  // 测试注册带夹具的基准测试
  LBenchmark := RegisterBenchmarkWithFixture('测试夹具基准', @SimpleTestFunction, LFixture);
  AssertNotNull('注册的夹具基准测试不应为空', LBenchmark);
  AssertEquals('夹具基准测试名称应正确', '测试夹具基准', LBenchmark.Name);
end;

procedure TTestCase_Global.Test_RunAllBenchmarks;
var
  LResults: TBenchmarkResultArray;
begin
  // 清空并注册一些基准测试
  ClearAllBenchmarks;
  RegisterBenchmark('测试1', @SimpleTestFunction);
  RegisterBenchmark('测试2', @SimpleTestFunction);
  
  // 运行所有基准测试
  LResults := RunAllBenchmarks;
  AssertEquals('应该有2个结果', 2, Length(LResults));
  
  AssertNotNull('第一个结果不应为空', LResults[0]);
  AssertNotNull('第二个结果不应为空', LResults[1]);
end;

procedure TTestCase_Global.Test_RunAllBenchmarksWithReporter;
var
  LResults: TBenchmarkResultArray;
  LReporter: IBenchmarkReporter;
begin
  // 清空并注册一些基准测试
  ClearAllBenchmarks;
  RegisterBenchmark('测试1', @SimpleTestFunction);
  
  LReporter := CreateConsoleReporter;
  
  // 运行所有基准测试并使用报告器
  LResults := RunAllBenchmarksWithReporter(LReporter);
  AssertEquals('应该有1个结果', 1, Length(LResults));
  AssertNotNull('结果不应为空', LResults[0]);
end;

procedure TTestCase_Global.Test_ClearAllBenchmarks;
var
  LResults: TBenchmarkResultArray;
begin
  // 注册一些基准测试
  RegisterBenchmark('测试1', @SimpleTestFunction);
  RegisterBenchmark('测试2', @SimpleTestFunction);
  
  // 清空所有基准测试
  ClearAllBenchmarks;
  
  // 验证已清空
  LResults := RunAllBenchmarks;
  AssertEquals('清空后应该没有结果', 0, Length(LResults));
end;

procedure TTestCase_Global.Test_RunLegacyFunction;
var
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
begin
  // 测试运行传统函数
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 2;
  
  LResult := RunLegacyFunction('传统函数测试', @LegacyTestFunction, LConfig);
  
  AssertNotNull('传统函数结果不应为空', LResult);
  AssertEquals('传统函数名称应正确', '传统函数测试', LResult.Name);
  AssertTrue('传统函数迭代次数应大于0', LResult.Iterations > 0);
  AssertTrue('传统函数总时间应大于0', LResult.TotalTime > 0);
end;

procedure TTestCase_Global.Test_RunLegacyMethod;
var
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
  LTestObj: TTestMethods;
begin
  // 测试运行传统方法
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 2;
  
  LTestObj := TTestMethods.Create;
  try
    LResult := RunLegacyMethod('传统方法测试', @LTestObj.LegacyTestMethod, LConfig);
    
    AssertNotNull('传统方法结果不应为空', LResult);
    AssertEquals('传统方法名称应正确', '传统方法测试', LResult.Name);
    AssertTrue('传统方法迭代次数应大于0', LResult.Iterations > 0);
    AssertTrue('传统方法总时间应大于0', LResult.TotalTime > 0);
  finally
    LTestObj.Free;
  end;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TTestCase_Global.Test_RunLegacyProc;
var
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
begin
  // 测试运行传统匿名过程
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 2;
  
  LResult := RunLegacyProc('传统过程测试',
    procedure
    var
      LI: Integer;
      LSum: Integer;
    begin
      LSum := 0;
      for LI := 1 to 100 do
        LSum := LSum + LI;
    end, LConfig);
  
  AssertNotNull('传统过程结果不应为空', LResult);
  AssertEquals('传统过程名称应正确', '传统过程测试', LResult.Name);
  AssertTrue('传统过程迭代次数应大于0', LResult.Iterations > 0);
  AssertTrue('传统过程总时间应大于0', LResult.TotalTime > 0);
end;
{$ENDIF}

procedure TTestCase_Global.Test_CreateLegacyBenchmark;
var
  LBenchmark: IBenchmark;
  LConfig: TBenchmarkConfig;
begin
  // 测试创建传统基准测试
  LConfig := CreateDefaultBenchmarkConfig;
  
  LBenchmark := CreateLegacyBenchmark('传统基准测试', @LegacyTestFunction, LConfig);
  
  AssertNotNull('传统基准测试不应为空', LBenchmark);
  AssertEquals('传统基准测试名称应正确', '传统基准测试', LBenchmark.Name);
end;

procedure TTestCase_Global.Test_RegisterBenchmark_NilFunction;
begin
  // 测试注册空函数应抛出异常
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('注册空函数应抛出异常', EArgumentNil,
    procedure
    begin
      RegisterBenchmark('空函数测试', nil);
    end);
  {$ELSE}
  // 在不支持匿名函数的情况下，直接测试
  try
    RegisterBenchmark('空函数测试', nil);
    Fail('注册空函数应该抛出异常');
  except
    on E: EArgumentNil do
      // 期望的异常，测试通过
      AssertTrue('应该抛出 EArgumentNil 异常', True);
    on E: Exception do
      Fail('应该抛出 EArgumentNil 异常，但抛出了: ' + E.ClassName);
  end;
  {$ENDIF}
end;

procedure TTestCase_Global.Test_RunLegacyFunction_NilFunction;
var
  LConfig: TBenchmarkConfig;
begin
  // 测试运行空传统函数应抛出异常
  LConfig := CreateDefaultBenchmarkConfig;

  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('运行空传统函数应抛出异常', EArgumentNil,
    procedure
    begin
      RunLegacyFunction('空函数测试', nil, LConfig);
    end);
  {$ELSE}
  // 在不支持匿名函数的情况下，直接测试
  try
    RunLegacyFunction('空函数测试', nil, LConfig);
    Fail('运行空传统函数应该抛出异常');
  except
    on E: EArgumentNil do
      // 期望的异常，测试通过
      AssertTrue('应该抛出 EArgumentNil 异常', True);
    on E: Exception do
      Fail('应该抛出 EArgumentNil 异常，但抛出了: ' + E.ClassName);
  end;
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_Global);

end.
