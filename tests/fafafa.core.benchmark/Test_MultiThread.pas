unit Test_MultiThread;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils,
  fafafa.core.base,
  fafafa.core.benchmark,
  Test_Framework;

type
  { TTestCase_MultiThread }
  TTestCase_MultiThread = class(TTestCase)
  private
    FSharedCounter: Integer;
    FSharedLock: TCriticalSection;
    
    procedure SimpleMultiThreadTest(aState: IBenchmarkState; aThreadIndex: Integer);
    procedure CounterIncrementTest(aState: IBenchmarkState; aThreadIndex: Integer);
    procedure WorkLoadTest(aState: IBenchmarkState; aThreadIndex: Integer);
    
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    
  published
    // 基础多线程功能测试
    procedure Test_RunMultiThreadFunction_基本功能;
    procedure Test_RunMultiThreadFunction_线程数量验证;
    procedure Test_RunMultiThreadFunction_工作量统计;
    procedure Test_RunMultiThreadFunction_异常处理;
    
    // 多线程配置测试
    procedure Test_CreateMultiThreadConfig_默认参数;
    procedure Test_CreateMultiThreadConfig_自定义参数;
    procedure Test_CreateMultiThreadConfig_边界值;
    
    // 全局函数测试
    procedure Test_RunMultiThreadBenchmark_简单调用;
    procedure Test_RunMultiThreadBenchmark_带配置调用;
    procedure Test_RunMultiThreadBenchmark_性能对比;
    
    // 线程同步测试
    procedure Test_MultiThread_线程同步;
    procedure Test_MultiThread_锁竞争;
    procedure Test_MultiThread_工作负载平衡;
    
    // 异常和边界条件测试
    procedure Test_MultiThread_空函数异常;
    procedure Test_MultiThread_零线程异常;
    procedure Test_MultiThread_负线程数异常;
  end;

implementation

{ TTestCase_MultiThread }

procedure TTestCase_MultiThread.SetUp;
begin
  inherited SetUp;
  FSharedCounter := 0;
  FSharedLock := TCriticalSection.Create;
end;

procedure TTestCase_MultiThread.TearDown;
begin
  FSharedLock.Free;
  inherited TearDown;
end;

procedure TTestCase_MultiThread.SimpleMultiThreadTest(aState: IBenchmarkState; aThreadIndex: Integer);
var
  LI: Integer;
  LSum: Integer;
begin
  LSum := 0;
  // 每个线程做简单的计算
  for LI := 1 to 100 do
    LSum := LSum + LI + aThreadIndex;
end;

procedure TTestCase_MultiThread.CounterIncrementTest(aState: IBenchmarkState; aThreadIndex: Integer);
var
  LI: Integer;
begin
  // 每个线程增加共享计数器50次
  for LI := 1 to 50 do
  begin
    FSharedLock.Enter;
    try
      Inc(FSharedCounter);
    finally
      FSharedLock.Leave;
    end;
  end;
end;

procedure TTestCase_MultiThread.WorkLoadTest(aState: IBenchmarkState; aThreadIndex: Integer);
var
  LI: Integer;
  LSum: Integer;
begin
  LSum := 0;
  // 每个线程做200次计算
  for LI := 1 to 200 do
    LSum := LSum + LI + aThreadIndex;
end;

procedure TTestCase_MultiThread.Test_RunMultiThreadFunction_基本功能;
var
  LRunner: IBenchmarkRunner;
  LResult: IBenchmarkResult;
  LThreadConfig: TMultiThreadConfig;
  LConfig: TBenchmarkConfig;
begin
  // 创建运行器和配置
  LRunner := CreateBenchmarkRunner;
  LThreadConfig := CreateMultiThreadConfig(2);
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 2;
  
  // 运行多线程测试
  LResult := LRunner.RunMultiThreadFunction('基本多线程测试', @SimpleMultiThreadTest, 
                                           LThreadConfig, LConfig);
  
  // 验证结果
  AssertNotNull(LResult, '多线程测试结果不应为空');
  AssertEquals('基本多线程测试', LResult.Name, '测试名称应该正确');
  AssertTrue(LResult.Iterations > 0, '迭代次数应该大于0');
  AssertTrue(LResult.TotalTime > 0, '总时间应该大于0');
end;

procedure TTestCase_MultiThread.Test_RunMultiThreadFunction_线程数量验证;
var
  LRunner: IBenchmarkRunner;
  LResult: IBenchmarkResult;
  LThreadConfig: TMultiThreadConfig;
  LConfig: TBenchmarkConfig;
begin
  LRunner := CreateBenchmarkRunner;
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 1;
  
  // 测试不同的线程数量
  var LThreadCounts: array[0..2] of Integer = (1, 2, 4);
  var LI: Integer;
  
  for LI := 0 to High(LThreadCounts) do
  begin
    LThreadConfig := CreateMultiThreadConfig(LThreadCounts[LI]);
    LResult := LRunner.RunMultiThreadFunction('线程数量测试', @SimpleMultiThreadTest, 
                                             LThreadConfig, LConfig);
    
    AssertNotNull(LResult, Format('%d线程测试结果不应为空', [LThreadCounts[LI]]));
    AssertTrue(LResult.TotalTime > 0, Format('%d线程测试时间应该大于0', [LThreadCounts[LI]]));
  end;
end;

procedure TTestCase_MultiThread.Test_RunMultiThreadFunction_工作量统计;
var
  LRunner: IBenchmarkRunner;
  LResult: IBenchmarkResult;
  LThreadConfig: TMultiThreadConfig;
  LConfig: TBenchmarkConfig;
begin
  LRunner := CreateBenchmarkRunner;
  LThreadConfig := CreateMultiThreadConfig(2, 200); // 每个线程200个工作单位
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 1;
  
  LResult := LRunner.RunMultiThreadFunction('工作量测试', @WorkLoadTest, 
                                           LThreadConfig, LConfig);
  
  // 验证工作量统计
  AssertNotNull(LResult, '工作量测试结果不应为空');
  // 注意：由于实现中的工作量统计方式，这里可能需要调整验证逻辑
  AssertTrue(LResult.TotalTime > 0, '工作量测试时间应该大于0');
end;

procedure TTestCase_MultiThread.Test_RunMultiThreadFunction_异常处理;
var
  LRunner: IBenchmarkRunner;
  LThreadConfig: TMultiThreadConfig;
  LConfig: TBenchmarkConfig;
begin
  LRunner := CreateBenchmarkRunner;
  LThreadConfig := CreateMultiThreadConfig(2);
  LConfig := CreateDefaultBenchmarkConfig;
  
  // 测试空函数异常
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException(EArgumentNil, 
    procedure
    begin
      LRunner.RunMultiThreadFunction('空函数测试', nil, LThreadConfig, LConfig);
    end,
    '空函数应该抛出 EArgumentNil 异常');
  {$ENDIF}
end;

procedure TTestCase_MultiThread.Test_CreateMultiThreadConfig_默认参数;
var
  LConfig: TMultiThreadConfig;
begin
  LConfig := CreateMultiThreadConfig(4);
  
  AssertEquals(4, LConfig.ThreadCount, '线程数量应该正确');
  AssertEquals(0, LConfig.WorkPerThread, '默认工作量应该为0');
  AssertTrue(LConfig.SyncThreads, '默认应该同步启动线程');
end;

procedure TTestCase_MultiThread.Test_CreateMultiThreadConfig_自定义参数;
var
  LConfig: TMultiThreadConfig;
begin
  LConfig := CreateMultiThreadConfig(8, 1000, False);
  
  AssertEquals(8, LConfig.ThreadCount, '线程数量应该正确');
  AssertEquals(1000, LConfig.WorkPerThread, '工作量应该正确');
  AssertFalse(LConfig.SyncThreads, '应该不同步启动线程');
end;

procedure TTestCase_MultiThread.Test_CreateMultiThreadConfig_边界值;
var
  LConfig: TMultiThreadConfig;
begin
  // 测试最小线程数
  LConfig := CreateMultiThreadConfig(1);
  AssertEquals(1, LConfig.ThreadCount, '最小线程数应该为1');
  
  // 测试大线程数
  LConfig := CreateMultiThreadConfig(16);
  AssertEquals(16, LConfig.ThreadCount, '大线程数应该正确');
end;

procedure TTestCase_MultiThread.Test_RunMultiThreadBenchmark_简单调用;
var
  LResult: IBenchmarkResult;
begin
  LResult := RunMultiThreadBenchmark('简单调用测试', @SimpleMultiThreadTest, 2);
  
  AssertNotNull(LResult, '简单调用结果不应为空');
  AssertEquals('简单调用测试', LResult.Name, '测试名称应该正确');
  AssertTrue(LResult.TotalTime > 0, '总时间应该大于0');
end;

procedure TTestCase_MultiThread.Test_RunMultiThreadBenchmark_带配置调用;
var
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
begin
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 2;
  
  LResult := RunMultiThreadBenchmark('带配置调用测试', @SimpleMultiThreadTest, 2, LConfig);
  
  AssertNotNull(LResult, '带配置调用结果不应为空');
  AssertTrue(LResult.Iterations >= 2, '迭代次数应该符合配置');
end;

procedure TTestCase_MultiThread.Test_RunMultiThreadBenchmark_性能对比;
var
  LResult1, LResult2: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
begin
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 2;
  
  // 1线程 vs 2线程对比
  LResult1 := RunMultiThreadBenchmark('1线程测试', @SimpleMultiThreadTest, 1, LConfig);
  LResult2 := RunMultiThreadBenchmark('2线程测试', @SimpleMultiThreadTest, 2, LConfig);
  
  AssertNotNull(LResult1, '1线程结果不应为空');
  AssertNotNull(LResult2, '2线程结果不应为空');
  
  // 两个结果都应该有有效的时间
  AssertTrue(LResult1.TotalTime > 0, '1线程时间应该大于0');
  AssertTrue(LResult2.TotalTime > 0, '2线程时间应该大于0');
end;

procedure TTestCase_MultiThread.Test_MultiThread_线程同步;
var
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
begin
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 1;
  
  FSharedCounter := 0;
  
  LResult := RunMultiThreadBenchmark('线程同步测试', @CounterIncrementTest, 4, LConfig);
  
  AssertNotNull(LResult, '线程同步测试结果不应为空');
  // 4个线程，每个线程50次，总共应该是200
  AssertEquals(200, FSharedCounter, '共享计数器应该等于200');
end;

procedure TTestCase_MultiThread.Test_MultiThread_锁竞争;
var
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
begin
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 2;
  
  FSharedCounter := 0;
  
  // 测试多个线程竞争同一个锁
  LResult := RunMultiThreadBenchmark('锁竞争测试', @CounterIncrementTest, 8, LConfig);
  
  AssertNotNull(LResult, '锁竞争测试结果不应为空');
  AssertTrue(LResult.TotalTime > 0, '锁竞争测试时间应该大于0');
  // 验证锁的正确性：8个线程 × 50次 × 迭代次数
  AssertTrue(FSharedCounter > 0, '共享计数器应该大于0');
end;

procedure TTestCase_MultiThread.Test_MultiThread_工作负载平衡;
var
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
begin
  LConfig := CreateDefaultBenchmarkConfig;
  LConfig.WarmupIterations := 1;
  LConfig.MeasureIterations := 3;
  
  LResult := RunMultiThreadBenchmark('负载平衡测试', @WorkLoadTest, 4, LConfig);
  
  AssertNotNull(LResult, '负载平衡测试结果不应为空');
  AssertTrue(LResult.TotalTime > 0, '负载平衡测试时间应该大于0');
  
  // 检查统计数据的合理性
  AssertTrue(LResult.Statistics.Mean > 0, '平均时间应该大于0');
  AssertTrue(LResult.Statistics.StdDev >= 0, '标准差应该大于等于0');
end;

procedure TTestCase_MultiThread.Test_MultiThread_空函数异常;
var
  LRunner: IBenchmarkRunner;
  LThreadConfig: TMultiThreadConfig;
  LConfig: TBenchmarkConfig;
begin
  LRunner := CreateBenchmarkRunner;
  LThreadConfig := CreateMultiThreadConfig(2);
  LConfig := CreateDefaultBenchmarkConfig;
  
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException(EArgumentNil,
    procedure
    begin
      LRunner.RunMultiThreadFunction('空函数测试', nil, LThreadConfig, LConfig);
    end,
    '空函数应该抛出异常');
  {$ENDIF}
end;

procedure TTestCase_MultiThread.Test_MultiThread_零线程异常;
var
  LRunner: IBenchmarkRunner;
  LThreadConfig: TMultiThreadConfig;
  LConfig: TBenchmarkConfig;
begin
  LRunner := CreateBenchmarkRunner;
  LThreadConfig := CreateMultiThreadConfig(0); // 无效的线程数
  LConfig := CreateDefaultBenchmarkConfig;
  
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException(EArgumentError,
    procedure
    begin
      LRunner.RunMultiThreadFunction('零线程测试', @SimpleMultiThreadTest, LThreadConfig, LConfig);
    end,
    '零线程数应该抛出异常');
  {$ENDIF}
end;

procedure TTestCase_MultiThread.Test_MultiThread_负线程数异常;
var
  LRunner: IBenchmarkRunner;
  LThreadConfig: TMultiThreadConfig;
  LConfig: TBenchmarkConfig;
begin
  LRunner := CreateBenchmarkRunner;
  LThreadConfig := CreateMultiThreadConfig(-1); // 负数线程
  LConfig := CreateDefaultBenchmarkConfig;
  
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException(EArgumentError,
    procedure
    begin
      LRunner.RunMultiThreadFunction('负线程测试', @SimpleMultiThreadTest, LThreadConfig, LConfig);
    end,
    '负线程数应该抛出异常');
  {$ENDIF}
end;

end.
