unit benchmark_utils;

{**
 * fafafa.core.atomic 基准测试工具函数
 *
 * @desc 提供基准测试所需的通用工具函数和辅助类型
 * @author fafafa.core team
 * @version 1.0.0
 * @since 2025-08-31
 *}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Classes, fafafa.core.benchmark, fafafa.core.atomic;

type
  {**
   * 基准测试配置
   *}
  TAtomicBenchConfig = record
    TestName: string;
    Iterations: Int64;
    WarmupIterations: Integer;
    ThreadCount: Integer;
    EnableMemoryOrder: Boolean;
    MemoryOrder: memory_order;
    
    class function Default: TAtomicBenchConfig; static;
    class function SingleThread(const AName: string): TAtomicBenchConfig; static;
    class function MultiThread(const AName: string; AThreads: Integer): TAtomicBenchConfig; static;
  end;

  {**
   * 基准测试结果统计
   *}
  TAtomicBenchResult = record
    TestName: string;
    OpsPerSecond: Double;
    AvgTimeNs: Double;
    MinTimeNs: Double;
    MaxTimeNs: Double;
    StdDevNs: Double;
    ThreadCount: Integer;
    TotalIterations: Int64;
    
    procedure Clear;
    function ToString: string;
  end;

  {**
   * 基准测试结果数组
   *}
  TAtomicBenchResultArray = array of TAtomicBenchResult;

  {**
   * 基准测试比较器
   *}
  TAtomicBenchComparator = class
  private
    FResults: TAtomicBenchResultArray;
  public
    procedure AddResult(const AResult: TAtomicBenchResult);
    procedure Clear;
    function Compare(const ABaseline, ATarget: string): Double; // 返回性能比率
    procedure PrintComparison(const ABaseline, ATarget: string);
    procedure PrintAllResults;
    procedure SaveToJSON(const AFileName: string);
    procedure SaveToCSV(const AFileName: string);
  end;

{**
 * 创建默认基准测试配置
 *}
function CreateAtomicBenchConfig(const AName: string; 
  AIterations: Int64 = 1000000; AThreads: Integer = 1): TAtomicBenchConfig;

{**
 * 运行单个基准测试
 *}
function RunAtomicBenchmark(const AConfig: TAtomicBenchConfig; 
  ABenchFunc: TBenchmarkFunction): TAtomicBenchResult;

{**
 * 运行基准测试并与基线对比
 *}
procedure RunAndCompare(const ATestName: string; 
  ABaselineFunc, ATargetFunc: TBenchmarkFunction;
  AIterations: Int64 = 1000000);

{**
 * 创建基准测试比较器
 *}
function CreateBenchComparator: TAtomicBenchComparator;

{**
 * 格式化性能数字
 *}
function FormatPerformance(AValue: Double; const AUnit: string = 'ops/sec'): string;

{**
 * 格式化时间
 *}
function FormatTime(ATimeNs: Double): string;

{**
 * 计算性能提升百分比
 *}
function CalculateImprovement(ABaseline, ATarget: Double): Double;

implementation

uses
  Math, fpjson, jsonparser;

{ TAtomicBenchConfig }

class function TAtomicBenchConfig.Default: TAtomicBenchConfig;
begin
  Result.TestName := 'DefaultTest';
  Result.Iterations := 1000000;
  Result.WarmupIterations := 1000;
  Result.ThreadCount := 1;
  Result.EnableMemoryOrder := True;
  Result.MemoryOrder := memory_order_seq_cst;
end;

class function TAtomicBenchConfig.SingleThread(const AName: string): TAtomicBenchConfig;
begin
  Result := Default;
  Result.TestName := AName;
  Result.ThreadCount := 1;
end;

class function TAtomicBenchConfig.MultiThread(const AName: string; AThreads: Integer): TAtomicBenchConfig;
begin
  Result := Default;
  Result.TestName := AName;
  Result.ThreadCount := AThreads;
end;

{ TAtomicBenchResult }

procedure TAtomicBenchResult.Clear;
begin
  TestName := '';
  OpsPerSecond := 0;
  AvgTimeNs := 0;
  MinTimeNs := 0;
  MaxTimeNs := 0;
  StdDevNs := 0;
  ThreadCount := 0;
  TotalIterations := 0;
end;

function TAtomicBenchResult.ToString: string;
begin
  Result := Format('%s: %s, %s avg, %d threads', [
    TestName,
    FormatPerformance(OpsPerSecond),
    FormatTime(AvgTimeNs),
    ThreadCount
  ]);
end;

{ TAtomicBenchComparator }

procedure TAtomicBenchComparator.AddResult(const AResult: TAtomicBenchResult);
begin
  SetLength(FResults, Length(FResults) + 1);
  FResults[High(FResults)] := AResult;
end;

procedure TAtomicBenchComparator.Clear;
begin
  SetLength(FResults, 0);
end;

function TAtomicBenchComparator.Compare(const ABaseline, ATarget: string): Double;
var
  BaselineOps, TargetOps: Double;
  I: Integer;
begin
  Result := 0;
  BaselineOps := 0;
  TargetOps := 0;
  
  for I := 0 to High(FResults) do
  begin
    if FResults[I].TestName = ABaseline then
      BaselineOps := FResults[I].OpsPerSecond
    else if FResults[I].TestName = ATarget then
      TargetOps := FResults[I].OpsPerSecond;
  end;
  
  if BaselineOps > 0 then
    Result := TargetOps / BaselineOps;
end;

procedure TAtomicBenchComparator.PrintComparison(const ABaseline, ATarget: string);
var
  Ratio: Double;
  Improvement: Double;
begin
  Ratio := Compare(ABaseline, ATarget);
  if Ratio > 0 then
  begin
    Improvement := (Ratio - 1) * 100;
    WriteLn(Format('%s vs %s: %.2fx (%.1f%% %s)', [
      ATarget, ABaseline, Ratio, Abs(Improvement),
      IfThen(Improvement >= 0, 'faster', 'slower')
    ]));
  end
  else
    WriteLn(Format('%s vs %s: 无法比较', [ATarget, ABaseline]));
end;

procedure TAtomicBenchComparator.PrintAllResults;
var
  I: Integer;
begin
  WriteLn('=== 基准测试结果 ===');
  for I := 0 to High(FResults) do
    WriteLn(FResults[I].ToString);
  WriteLn;
end;

procedure TAtomicBenchComparator.SaveToJSON(const AFileName: string);
var
  JSONArray: TJSONArray;
  JSONObj: TJSONObject;
  I: Integer;
  FileStream: TFileStream;
  JSONStr: string;
begin
  JSONArray := TJSONArray.Create;
  try
    for I := 0 to High(FResults) do
    begin
      JSONObj := TJSONObject.Create;
      JSONObj.Add('test_name', FResults[I].TestName);
      JSONObj.Add('ops_per_second', FResults[I].OpsPerSecond);
      JSONObj.Add('avg_time_ns', FResults[I].AvgTimeNs);
      JSONObj.Add('min_time_ns', FResults[I].MinTimeNs);
      JSONObj.Add('max_time_ns', FResults[I].MaxTimeNs);
      JSONObj.Add('std_dev_ns', FResults[I].StdDevNs);
      JSONObj.Add('thread_count', FResults[I].ThreadCount);
      JSONObj.Add('total_iterations', Int64(FResults[I].TotalIterations));
      JSONArray.Add(JSONObj);
    end;
    
    JSONStr := JSONArray.FormatJSON;
    FileStream := TFileStream.Create(AFileName, fmCreate);
    try
      FileStream.WriteBuffer(JSONStr[1], Length(JSONStr));
    finally
      FileStream.Free;
    end;
  finally
    JSONArray.Free;
  end;
end;

procedure TAtomicBenchComparator.SaveToCSV(const AFileName: string);
var
  CSV: TStringList;
  I: Integer;
begin
  CSV := TStringList.Create;
  try
    CSV.Add('TestName,OpsPerSecond,AvgTimeNs,MinTimeNs,MaxTimeNs,StdDevNs,ThreadCount,TotalIterations');
    for I := 0 to High(FResults) do
    begin
      CSV.Add(Format('%s,%.2f,%.2f,%.2f,%.2f,%.2f,%d,%d', [
        FResults[I].TestName,
        FResults[I].OpsPerSecond,
        FResults[I].AvgTimeNs,
        FResults[I].MinTimeNs,
        FResults[I].MaxTimeNs,
        FResults[I].StdDevNs,
        FResults[I].ThreadCount,
        FResults[I].TotalIterations
      ]));
    end;
    CSV.SaveToFile(AFileName);
  finally
    CSV.Free;
  end;
end;

{ 全局函数实现 }

function CreateAtomicBenchConfig(const AName: string; AIterations: Int64; AThreads: Integer): TAtomicBenchConfig;
begin
  Result := TAtomicBenchConfig.Default;
  Result.TestName := AName;
  Result.Iterations := AIterations;
  Result.ThreadCount := AThreads;
end;

function RunAtomicBenchmark(const AConfig: TAtomicBenchConfig; ABenchFunc: TBenchmarkFunction): TAtomicBenchResult;
var
  Runner: IBenchmarkRunner;
  BenchConfig: TBenchmarkConfig;
  BenchResult: IBenchmarkResult;
  Stats: TBenchmarkStatistics;
begin
  Result.Clear;
  Result.TestName := AConfig.TestName;
  Result.ThreadCount := AConfig.ThreadCount;
  
  Runner := CreateBenchmarkRunner;
  BenchConfig := CreateDefaultBenchmarkConfig;
  BenchConfig.MeasureIterations := AConfig.Iterations;
  BenchConfig.WarmupIterations := AConfig.WarmupIterations;
  
  BenchResult := Runner.RunFunction(AConfig.TestName, ABenchFunc, BenchConfig);
  
  Result.TotalIterations := BenchResult.GetIterations;
  Result.AvgTimeNs := BenchResult.GetTimePerIteration(buNanoSeconds);
  Result.OpsPerSecond := BenchResult.GetThroughput;
  
  if BenchResult.HasStatistics then
  begin
    Stats := BenchResult.GetStatistics;
    Result.MinTimeNs := Stats.MinTime;
    Result.MaxTimeNs := Stats.MaxTime;
    Result.StdDevNs := Stats.StdDev;
  end;
end;

procedure RunAndCompare(const ATestName: string; ABaselineFunc, ATargetFunc: TBenchmarkFunction; AIterations: Int64);
var
  Comparator: TAtomicBenchComparator;
  Config: TAtomicBenchConfig;
  BaselineResult, TargetResult: TAtomicBenchResult;
begin
  Comparator := CreateBenchComparator;
  try
    Config := CreateAtomicBenchConfig(ATestName + '_Baseline', AIterations);
    BaselineResult := RunAtomicBenchmark(Config, ABaselineFunc);
    Comparator.AddResult(BaselineResult);
    
    Config := CreateAtomicBenchConfig(ATestName + '_Target', AIterations);
    TargetResult := RunAtomicBenchmark(Config, ATargetFunc);
    Comparator.AddResult(TargetResult);
    
    Comparator.PrintAllResults;
    Comparator.PrintComparison(BaselineResult.TestName, TargetResult.TestName);
  finally
    Comparator.Free;
  end;
end;

function CreateBenchComparator: TAtomicBenchComparator;
begin
  Result := TAtomicBenchComparator.Create;
end;

function FormatPerformance(AValue: Double; const AUnit: string): string;
begin
  if AValue >= 1e9 then
    Result := Format('%.2f G%s', [AValue / 1e9, AUnit])
  else if AValue >= 1e6 then
    Result := Format('%.2f M%s', [AValue / 1e6, AUnit])
  else if AValue >= 1e3 then
    Result := Format('%.2f K%s', [AValue / 1e3, AUnit])
  else
    Result := Format('%.2f %s', [AValue, AUnit]);
end;

function FormatTime(ATimeNs: Double): string;
begin
  if ATimeNs >= 1e9 then
    Result := Format('%.2f s', [ATimeNs / 1e9])
  else if ATimeNs >= 1e6 then
    Result := Format('%.2f ms', [ATimeNs / 1e6])
  else if ATimeNs >= 1e3 then
    Result := Format('%.2f μs', [ATimeNs / 1e3])
  else
    Result := Format('%.2f ns', [ATimeNs]);
end;

function CalculateImprovement(ABaseline, ATarget: Double): Double;
begin
  if ABaseline > 0 then
    Result := ((ATarget - ABaseline) / ABaseline) * 100
  else
    Result := 0;
end;

end.
