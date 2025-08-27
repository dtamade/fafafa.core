unit fafafa.core.benchmark.simple;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes,
  SysUtils,
  fafafa.core.base,
  fafafa.core.tick;

{ 🚀 简化的基准测试框架 - 专注于核心功能 }

type

  {**
   * TBenchmarkFunction
   *
   * @desc 基准测试函数类型
   *}
  TBenchmarkFunction = procedure;

  {**
   * TBenchmarkMethod
   *
   * @desc 基准测试方法类型
   *}
  TBenchmarkMethod = procedure of object;

  {**
   * TBenchmarkConfig
   *
   * @desc 基准测试配置
   *}
  TBenchmarkConfig = record
    WarmupIterations: Integer;      // 预热迭代次数
    MeasureIterations: Integer;     // 测量迭代次数
    MinDurationMs: Integer;         // 最小运行时间（毫秒）
  end;

  {**
   * TBenchmarkStatistics
   *
   * @desc 基准测试统计数据
   *}
  TBenchmarkStatistics = record
    Mean: Double;           // 平均值（纳秒）
    StdDev: Double;         // 标准差
    Min: Double;            // 最小值
    Max: Double;            // 最大值
    Median: Double;         // 中位数
    SampleCount: Integer;   // 样本数量
  end;

  {**
   * IBenchmarkResult
   *
   * @desc 基准测试结果接口
   *}
  IBenchmarkResult = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    
    function GetName: string;
    function GetIterations: Int64;
    function GetTotalTime: Double;
    function GetStatistics: TBenchmarkStatistics;
    function GetTimePerIteration: Double;
    function GetThroughput: Double;
    
    property Name: string read GetName;
    property Iterations: Int64 read GetIterations;
    property TotalTime: Double read GetTotalTime;
    property Statistics: TBenchmarkStatistics read GetStatistics;
  end;

  {**
   * TQuickBenchmark
   *
   * @desc 快手基准测试定义
   *}
  TQuickBenchmark = record
    Name: string;
    Func: TBenchmarkFunction;
    Method: TBenchmarkMethod;
    Config: TBenchmarkConfig;
  end;

  {**
   * TBenchmarkResultArray
   *
   * @desc 基准测试结果数组
   *}
  TBenchmarkResultArray = array of IBenchmarkResult;

{ 工厂函数 }

{**
 * CreateDefaultBenchmarkConfig
 *
 * @desc 创建默认的基准测试配置
 *}
function CreateDefaultBenchmarkConfig: TBenchmarkConfig;

{**
 * benchmark
 *
 * @desc 创建快手基准测试定义
 *}
function benchmark(const aName: string; aFunc: TBenchmarkFunction): TQuickBenchmark; overload;
function benchmark(const aName: string; aMethod: TBenchmarkMethod): TQuickBenchmark; overload;
function benchmark(const aName: string; aFunc: TBenchmarkFunction; const aConfig: TBenchmarkConfig): TQuickBenchmark; overload;

{**
 * benchmarks
 *
 * @desc 运行一组基准测试
 *}
function benchmarks(const aTests: array of TQuickBenchmark): TBenchmarkResultArray;

{**
 * quick_benchmark
 *
 * @desc 快手基准测试 - 运行并显示结果
 *}
procedure quick_benchmark(const aTests: array of TQuickBenchmark); overload;
procedure quick_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;

{**
 * turbo_benchmark
 *
 * @desc 🚀 涡轮增压基准测试 - 自动优化配置
 *}
procedure turbo_benchmark(const aTests: array of TQuickBenchmark); overload;
procedure turbo_benchmark(const aTitle: string; const aTests: array of TQuickBenchmark); overload;

implementation

type

  {**
   * TBenchmarkResult
   *
   * @desc 基准测试结果实现类
   *}
  TBenchmarkResult = class(TInterfacedObject, IBenchmarkResult)
  private
    FName: string;
    FIterations: Int64;
    FTotalTime: Double;
    FStatistics: TBenchmarkStatistics;
    FSamples: array of Double;
    
  public
    constructor Create(const aName: string; aIterations: Int64; aTotalTime: Double; const aSamples: array of Double);
    
    function GetName: string;
    function GetIterations: Int64;
    function GetTotalTime: Double;
    function GetStatistics: TBenchmarkStatistics;
    function GetTimePerIteration: Double;
    function GetThroughput: Double;
  end;

{ TBenchmarkResult }

constructor TBenchmarkResult.Create(const aName: string; aIterations: Int64; aTotalTime: Double; const aSamples: array of Double);
var
  LI: Integer;
  LSum: Double;
  LSorted: array of Double;
begin
  inherited Create;
  FName := aName;
  FIterations := aIterations;
  FTotalTime := aTotalTime;
  
  // 复制样本数据
  SetLength(FSamples, Length(aSamples));
  for LI := 0 to High(aSamples) do
    FSamples[LI] := aSamples[LI];
  
  // 计算统计数据
  if Length(aSamples) > 0 then
  begin
    FStatistics.SampleCount := Length(aSamples);
    
    // 计算平均值
    LSum := 0;
    FStatistics.Min := aSamples[0];
    FStatistics.Max := aSamples[0];
    
    for LI := 0 to High(aSamples) do
    begin
      LSum := LSum + aSamples[LI];
      if aSamples[LI] < FStatistics.Min then
        FStatistics.Min := aSamples[LI];
      if aSamples[LI] > FStatistics.Max then
        FStatistics.Max := aSamples[LI];
    end;
    
    FStatistics.Mean := LSum / Length(aSamples);
    
    // 计算标准差
    LSum := 0;
    for LI := 0 to High(aSamples) do
      LSum := LSum + Sqr(aSamples[LI] - FStatistics.Mean);
    FStatistics.StdDev := Sqrt(LSum / (Length(aSamples) - 1));
    
    // 计算中位数（简单排序）
    SetLength(LSorted, Length(aSamples));
    for LI := 0 to High(aSamples) do
      LSorted[LI] := aSamples[LI];
    
    // 冒泡排序
    for LI := 0 to High(LSorted) - 1 do
      for var LJ := LI + 1 to High(LSorted) do
        if LSorted[LI] > LSorted[LJ] then
        begin
          var LTemp := LSorted[LI];
          LSorted[LI] := LSorted[LJ];
          LSorted[LJ] := LTemp;
        end;
    
    FStatistics.Median := LSorted[Length(LSorted) div 2];
  end;
end;

function TBenchmarkResult.GetName: string;
begin
  Result := FName;
end;

function TBenchmarkResult.GetIterations: Int64;
begin
  Result := FIterations;
end;

function TBenchmarkResult.GetTotalTime: Double;
begin
  Result := FTotalTime;
end;

function TBenchmarkResult.GetStatistics: TBenchmarkStatistics;
begin
  Result := FStatistics;
end;

function TBenchmarkResult.GetTimePerIteration: Double;
begin
  if FIterations > 0 then
    Result := FTotalTime / FIterations
  else
    Result := 0;
end;

function TBenchmarkResult.GetThroughput: Double;
var
  LTimePerIteration: Double;
begin
  LTimePerIteration := GetTimePerIteration();
  if LTimePerIteration > 0 then
    Result := 1000000000.0 / LTimePerIteration  // 转换为每秒操作数
  else
    Result := 0;
end;

{ 工厂函数实现 }

function CreateDefaultBenchmarkConfig: TBenchmarkConfig;
begin
  Result.WarmupIterations := 3;
  Result.MeasureIterations := 10;
  Result.MinDurationMs := 100;
end;

function benchmark(const aName: string; aFunc: TBenchmarkFunction): TQuickBenchmark;
begin
  Result.Name := aName;
  Result.Func := aFunc;
  Result.Method := nil;
  Result.Config := CreateDefaultBenchmarkConfig;
end;

function benchmark(const aName: string; aMethod: TBenchmarkMethod): TQuickBenchmark;
begin
  Result.Name := aName;
  Result.Func := nil;
  Result.Method := aMethod;
  Result.Config := CreateDefaultBenchmarkConfig;
end;

function benchmark(const aName: string; aFunc: TBenchmarkFunction; const aConfig: TBenchmarkConfig): TQuickBenchmark;
begin
  Result.Name := aName;
  Result.Func := aFunc;
  Result.Method := nil;
  Result.Config := aConfig;
end;

end.
