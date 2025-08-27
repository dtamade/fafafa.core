# fafafa.core.benchmark

现代化的 FreePascal 基准测试框架，提供精确的性能测量和统计分析功能。

## 🎯 设计目标

- **精确测量**: 基于高精度时间测量，提供纳秒级精度
- **统计分析**: 自动计算平均值、标准差、百分位数等统计指标
- **易于使用**: 简洁的 API 设计，支持函数、方法和匿名过程
- **灵活报告**: 支持控制台和文件输出，可自定义报告格式
- **套件管理**: 支持批量运行多个基准测试
- **现代设计**: 借鉴 Rust Criterion、Go testing.B 等现代基准测试库

## 🚀 快速开始

### 基本用法

```pascal
uses fafafa.core.benchmark;

var
  LRunner: IBenchmarkRunner;
  LResult: IBenchmarkResult;
  LConfig: TBenchmarkConfig;
begin
  // 创建运行器和配置
  LRunner := CreateBenchmarkRunner;
  LConfig := CreateDefaultBenchmarkConfig;

  // 运行基准测试
  LResult := LRunner.RunFunction('测试名称', @TestFunction, LConfig);

  // 查看结果
  WriteLn('平均时间: ', LResult.GetTimePerIteration(buMicroSeconds):0:2, ' μs');
  WriteLn('吞吐量: ', LResult.GetThroughput:0:0, ' ops/sec');
end;
```

### 使用测试套件

```pascal
var
  LSuite: IBenchmarkSuite;
  LReporter: IBenchmarkReporter;
  LConfig: TBenchmarkConfig;
begin
  LSuite := CreateBenchmarkSuite;
  LReporter := CreateConsoleReporter;
  LConfig := CreateDefaultBenchmarkConfig;

  // 添加多个测试
  LSuite.AddFunction('算法A', @AlgorithmA, LConfig);
  LSuite.AddFunction('算法B', @AlgorithmB, LConfig);

  // 运行所有测试并生成报告
  LSuite.RunAllWithReporter(LReporter);
end;
```

## 📊 核心接口

### IBenchmarkRunner - 基准测试运行器

负责执行基准测试并收集结果的核心接口。

```pascal
IBenchmarkRunner = interface
  function RunFunction(const aName: string; aFunc: TBenchmarkFunction;
    const aConfig: TBenchmarkConfig): IBenchmarkResult;
  function RunMethod(const aName: string; aMethod: TBenchmarkMethod;
    const aConfig: TBenchmarkConfig): IBenchmarkResult;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  function RunProc(const aName: string; aProc: TBenchmarkProc;
    const aConfig: TBenchmarkConfig): IBenchmarkResult;
  {$ENDIF}
end;
```

### IBenchmarkResult - 测试结果

存储和提供基准测试执行结果的接口。

```pascal
IBenchmarkResult = interface
  function GetName: string;
  function GetIterations: Integer;
  function GetTotalTime: Double;
  function GetStatistics: TBenchmarkStatistics;
  function GetTimePerIteration(aUnit: TBenchmarkUnit = buNanoSeconds): Double;
  function GetThroughput: Double;
end;
```

### IBenchmarkSuite - 测试套件

管理多个基准测试的集合。

```pascal
IBenchmarkSuite = interface
  procedure AddFunction(const aName: string; aFunc: TBenchmarkFunction;
    const aConfig: TBenchmarkConfig);
  function RunAll: TBenchmarkResultArray;
  function RunAllWithReporter(aReporter: IBenchmarkReporter): TBenchmarkResultArray;
  function GetCount: Integer;
end;
```

### IBenchmarkReporter - 报告器

负责格式化和输出测试结果。

```pascal
IBenchmarkReporter = interface
  procedure ReportResult(aResult: IBenchmarkResult);
  procedure ReportResults(const aResults: array of IBenchmarkResult);
  procedure ReportComparison(aBaseline, aCurrent: IBenchmarkResult);
end;
```

## ⚙️ 配置选项

### TBenchmarkConfig

```pascal
TBenchmarkConfig = record
  Mode: TBenchmarkMode;           // 运行模式
  WarmupIterations: Integer;      // 预热迭代次数
  MeasureIterations: Integer;     // 测量迭代次数
  MinDurationMs: Integer;         // 最小运行时间（毫秒）
  MaxDurationMs: Integer;         // 最大运行时间（毫秒）
  TimeUnit: TBenchmarkUnit;       // 时间单位
  EnableMemoryMeasurement: Boolean; // 是否启用内存测量
end;
```

### 默认配置

```pascal
function CreateDefaultBenchmarkConfig: TBenchmarkConfig;
// 返回：
// - Mode: bmTime
// - WarmupIterations: 3
// - MeasureIterations: 10
// - MinDurationMs: 1000 (1秒)
// - MaxDurationMs: 10000 (10秒)
// - TimeUnit: buNanoSeconds
// - EnableMemoryMeasurement: False
```

## 📈 统计数据

### TBenchmarkStatistics

```pascal
TBenchmarkStatistics = record
  Mean: Double;           // 平均值
  StdDev: Double;         // 标准差
  Min: Double;            // 最小值
  Max: Double;            // 最大值
  Median: Double;         // 中位数
  P95: Double;            // 95百分位数
  P99: Double;            // 99百分位数
  SampleCount: Integer;   // 样本数量
end;
```

## 🛠️ 工厂函数

```pascal
// 创建基准测试运行器
function CreateBenchmarkRunner: IBenchmarkRunner;

// 创建基准测试套件
function CreateBenchmarkSuite: IBenchmarkSuite;

// 创建控制台报告器
function CreateConsoleReporter: IBenchmarkReporter;

// 创建文件报告器
function CreateFileReporter(const aFileName: string): IBenchmarkReporter;

// 创建默认配置
function CreateDefaultBenchmarkConfig: TBenchmarkConfig;

// 创建多线程配置
function CreateMultiThreadConfig(aThreadCount: Integer;
                                aWorkPerThread: Integer = 0;
                                aSyncThreads: Boolean = True): TMultiThreadConfig;

// 运行多线程基准测试
function RunMultiThreadBenchmark(const aName: string;
                                aFunc: TMultiThreadBenchmarkFunction;
                                aThreadCount: Integer): IBenchmarkResult;
```

## ⚡ 快手接口（Bench / MeasureNs / Compare）

- 一行跑并输出：

```pascal

## Sink（可选验证路径）

为保持默认行为稳定，Sink 报告器通过环境变量按需启用，仅用于本地或专项验证。默认仍使用既有 Reporter（Console/JSON/CSV/JUnit）。

- FAFAFA_BENCH_USE_SINK_CONSOLE=1
  - 启用 sink 版控制台报告（统一输出风格，便于与测试侧对齐）
- FAFAFA_BENCH_USE_SINK_JSON=1
  - 已位等：该开关现在转发到内置 JSON Reporter，输出 schema 与字段格式与默认 JSON 完全一致，可安全启用。

注意
- Sink 开关未设置时，行为完全保持不变
- 所有时间戳统一为 UTC Z（RFC3339）以保证确定性
- 建议将输出路径（--outfile=...）显式传入，避免隐式文件覆盖

Bench('parse', @ParseFunc);
```

- 一行测（返回 ns/op，不输出）：

```pascal
WriteLn('ns/op=', MeasureNs(@ParseFunc):0:2);
```

- 一行比（lower is better）：

```pascal
Compare('v1','v2', @FooV1, @FooV2);
```

- 指定配置运行：

```pascal
var C: TBenchmarkConfig := CreateDefaultBenchmarkConfig;
C.MeasureIterations := 5;
BenchWithConfig('parse.config', @ParseFunc, C);
```

- 单位显示（默认 UTF-8）：

```pascal
// 方式一：全局切换单位显示为 ASCII
SetUnitDisplayMode(udAscii);

// 方式二：仅报告器强制 ASCII（不影响全局）
var Reporter := CreateConsoleReporterAsciiOnly;
Reporter.ReportResults(benchmarks([
  benchmark('foo', @Foo)
]));
```

## 🎨 使用示例

- 完整可运行示例位于 examples/fafafa.core.benchmark 下：
  - example_analyzed：analyzed_benchmark + Reporter 输出
  - example_predictive：predictive_benchmark + Reporter 输出
  - example_adaptive：adaptive_benchmark + Reporter 输出
  - example_realtime：realtime_benchmark + quick_benchmark 输出
  - example_ultimate：ultimate_benchmark 组合演示
  - example_ai：ai_benchmark 组合演示
  - example_file_reporter：使用 CreateFileReporter 将结果写入文件

Windows 运行：进入对应目录执行 buildOrRun.bat

### 比较不同算法

## 📄 JSON/CSV 字段说明（导出契约）

- JSON（CreateJSONReporter）
  - 顶层数组字段：benchmarks: IBenchmarkResult[]，total_benchmarks: number
  - IBenchmarkResult 对象字段：
    - name: string
    - iterations: number
    - total_time_ns: number
    - time_per_iteration_ns: number
    - throughput_per_sec: number
    - statistics: { mean, stddev, min, max, median, p95, p99, coefficient_of_variation, sample_count } （均为 number）
    - bytes_per_second: number
    - items_per_second: number
    - complexity_n: number
    - counters: { [name: string]: number }
  - 说明：数值均为小数点 6 位；时间单位为纳秒；throughput 为每秒操作数

- CSV（CreateCSVReporter）
  - Header（首行固定且始终包含 SchemaVersion 最末列）：
    - Name,Iterations,TotalTime(ns),TimePerIteration(ns),Throughput(ops/sec),
      Mean(ns),StdDev(ns),Min(ns),Max(ns),Median(ns),P95(ns),P99(ns),
      CoefficientOfVariation,SampleCount,BytesPerSecond,ItemsPerSecond,ComplexityN,SchemaVersion
  - 每行对应一个 benchmark；时间均为 ns，throughput 为 ops/sec；数据行同样固定包含末列 SchemaVersion（由 SetFormat 中 schema 指定）
- 兼容性：CSV 第一行永远为 Header（无论 schema_in_column 是否开启）；所有数值小数点统一为 '.'（与本地化无关）。JSON 字符串与 CSV 文本字段按转义规则输出（JSON: \" 与 \\；CSV: " → "" 并包裹双引号）。
- 版本策略：
  - schema_version 为导出契约的版本号，遇到破坏性变更（字段删除/重命名、语义或单位改变）必须递增；新增字段/列为兼容性变更可不变更 schema。
  - 消费端应按 schema_version 做兼容处理：未知字段/列忽略；无法解析时回退。
  - 建议在 CI 中对 JSON/CSV 输出做 schema_version 断言，避免契约漂移。





小贴士：自定义格式参数（SetFormat）
- JSON：schema=<n>;decimals=<n>
- CSV：schema=<n>;decimals=<n>;sep=<char|tab|\t>
示例：
```pascal
var J := CreateJSONReporter('out.json');
J.SetFormat('schema=2;decimals=4');
var C := CreateCSVReporter('out.csv');
C.SetFormat('schema=2;decimals=3;sep=;');
```
- CSV 还支持：schema_in_column=true|false（默认 false）。注意：当前实现为了契约稳定，Header 与数据行始终包含末列 SchemaVersion；schema_in_column 仅作为兼容保留配置，不改变列结构（可在未来版本废弃）。
示例（制表符分隔）：
```pascal
var CTab := CreateCSVReporter('out_tab.csv');
CTab.SetFormat('schema=2;decimals=2;sep=tab;schema_in_column=false');
```


```pascal
procedure CompareAlgorithms;
var
  LRunner: IBenchmarkRunner;
  LReporter: IBenchmarkReporter;
  LConfig: TBenchmarkConfig;
  LResult1, LResult2: IBenchmarkResult;
begin
  LRunner := CreateBenchmarkRunner;
  LReporter := CreateConsoleReporter;
  LConfig := CreateDefaultBenchmarkConfig;

  // 测试两种算法
  LResult1 := LRunner.RunFunction('冒泡排序', @BubbleSort, LConfig);
  LResult2 := LRunner.RunFunction('快速排序', @QuickSort, LConfig);

  // 比较结果
  LReporter.ReportComparison(LResult1, LResult2);
end;
```

### 保存结果到文件

```pascal
procedure SaveResultsToFile;
var
  LSuite: IBenchmarkSuite;
  LFileReporter: IBenchmarkReporter;
  LConfig: TBenchmarkConfig;
begin
  LSuite := CreateBenchmarkSuite;
  LFileReporter := CreateFileReporter('performance_results.txt');
  LConfig := CreateDefaultBenchmarkConfig;

  LSuite.AddFunction('测试1', @Test1, LConfig);
  LSuite.AddFunction('测试2', @Test2, LConfig);

  // 运行并保存到文件
  LSuite.RunAllWithReporter(LFileReporter);
end;
```

### 多线程性能测试

```pascal
// 定义多线程测试函数
procedure MultiThreadWork(aState: IBenchmarkState; aThreadIndex: Integer);
var
  LI: Integer;
  LSum: Integer;
begin
  LSum := 0;
  // 每个线程做1000次计算
  for LI := 1 to 1000 do
    LSum := LSum + LI + aThreadIndex;
end;

// 单线程版本用于对比
procedure SingleThreadWork(aState: IBenchmarkState);
var
  LI, LJ: Integer;
  LSum: Integer;
begin
  while aState.KeepRunning do
  begin
    LSum := 0;
    // 模拟4个线程的总工作量
    for LJ := 0 to 3 do
      for LI := 1 to 1000 do
        LSum := LSum + LI + LJ;
    aState.SetItemsProcessed(4000);
  end;
end;

procedure CompareThreadPerformance;
var
  LConfig: TBenchmarkConfig;
  LResult1, LResult2: IBenchmarkResult;
begin
  LConfig := CreateDefaultBenchmarkConfig;

  // 单线程测试
  LResult1 := RunLegacyFunction('单线程', @SingleThreadWork, LConfig);
  WriteLn('单线程: ', Format('%.2f μs/op', [LResult1.GetTimePerIteration(buMicroSeconds)]));

  // 多线程测试
  LResult2 := RunMultiThreadBenchmark('4线程', @MultiThreadWork, 4, LConfig);
  WriteLn('多线程: ', Format('%.2f μs/op', [LResult2.GetTimePerIteration(buMicroSeconds)]));

  // 计算加速比
  var LSpeedup := LResult1.GetTimePerIteration() / LResult2.GetTimePerIteration();
  WriteLn('加速比: ', Format('%.2fx', [LSpeedup]));
end;
```

## ⚡ 快手接口 - 一行式基准测试

### 超级简洁的使用方式

框架提供了超级简洁的快手接口，让基准测试变得像写 Hello World 一样简单：

```pascal
// 🚀 一行代码搞定多个基准测试！
quick_benchmark([
  benchmark('算法A', @FunctionA),
  benchmark('算法B', @FunctionB),
  benchmark('算法C', @FunctionC)
]);
```

### 快手接口语法

#### 1. 创建测试定义
```pascal
// 基础版本
var LTest := benchmark('测试名称', @TestFunction);

// 带配置版本
var LConfig := CreateDefaultBenchmarkConfig;
LConfig.MeasureIterations := 5;
var LTest := benchmark('测试名称', @TestFunction, LConfig);

// 方法版本
var LTest := benchmark('测试名称', @MyObject.TestMethod);
```

#### 2. 运行测试
```pascal
// 只运行，不显示（返回结果）
var LResults := benchmarks([
  benchmark('测试1', @Func1),
  benchmark('测试2', @Func2)
]);

// 带标题运行
var LResults := benchmarks('我的测试套件', [
  benchmark('测试1', @Func1),
  benchmark('测试2', @Func2)
]);

// 运行并自动显示结果
quick_benchmark([
  benchmark('测试1', @Func1),
  benchmark('测试2', @Func2)
]);

// 带标题显示
quick_benchmark('性能对比', [
  benchmark('测试1', @Func1),
  benchmark('测试2', @Func2)
]);
```

### 实际使用示例

```pascal
program MyBenchmark;
uses fafafa.core.benchmark;

procedure StringConcat(aState: IBenchmarkState);
begin
  while aState.KeepRunning do
  begin
    var LStr := '';
    for var LI := 1 to 100 do
      LStr := LStr + 'x';
  end;
end;

procedure MathCalc(aState: IBenchmarkState);
begin
  while aState.KeepRunning do
  begin
    var LSum := 0.0;
    for var LI := 1 to 1000 do
      LSum := LSum + Sqrt(LI);
  end;
end;

begin
  // 就这么简单！
  quick_benchmark('算法对比', [
    benchmark('字符串连接', @StringConcat),
    benchmark('数学计算', @MathCalc)
  ]);
end.
```

### 快手接口的优势

✅ **极简语法** - 一行代码搞定多个测试
✅ **自动对比** - 自动显示性能对比和最快算法
✅ **灵活配置** - 支持自定义测试配置
✅ **结果获取** - 可以只获取结果不显示
✅ **零学习成本** - 语法直观，立即上手

## 🚀 增强功能

### 统计分析增强

框架现在提供了更丰富的统计分析功能：

```pascal
var
  LResult: IBenchmarkResult;
  LLowerBound, LUpperBound: Double;
begin
  LResult := RunFunction('测试', @MyFunction, CreateDefaultBenchmarkConfig);

  // 百分位数分析
  WriteLn('P50 (中位数): ', LResult.GetPercentile(50));
  WriteLn('P95: ', LResult.GetPercentile(95));
  WriteLn('P99: ', LResult.GetPercentile(99));

  // 置信区间
  LResult.GetConfidenceInterval(0.95, LLowerBound, LUpperBound);
  WriteLn('95% 置信区间: [', LLowerBound, ', ', LUpperBound, ']');
end;
```

### 性能基线对比

支持与历史基线进行对比，检测性能回归：

```pascal
var
  LBaseline: TBenchmarkBaseline;
  LResult: IBenchmarkResult;
begin
  // 创建基线
  LBaseline := CreateBaseline('我的基线', 1000.0, 0.1, '性能基线描述');

  // 运行测试并对比
  LResult := RunFunction('当前测试', @MyFunction, CreateDefaultBenchmarkConfig);

  // 检查是否有性能回归
  if LResult.IsRegressionFrom(LBaseline) then
    WriteLn('检测到性能回归！')
  else
    WriteLn('性能正常');

  // 获取具体的对比结果
  var LComparison := LResult.CompareWithBaseline(LBaseline);
  WriteLn('相对差异: ', Format('%.2f%%', [LComparison * 100]));
end;
```

### 智能配置推荐

框架可以根据测试函数的特征自动推荐最佳配置：

```pascal
var
  LRecommendation: TBenchmarkRecommendation;
begin
  LRecommendation := RecommendConfig(@MyFunction);

  WriteLn('推荐置信度: ', LRecommendation.Confidence);
  WriteLn('推荐理由: ', LRecommendation.Reasoning);

  // 使用推荐的配置
  var LResult := RunFunction('测试', @MyFunction, LRecommendation.RecommendedConfig);
end;
```

### 结果直接对比

快速比较两个测试结果：

```pascal
var
  LResult1, LResult2: IBenchmarkResult;
  LComparison: Double;
begin
  LResult1 := RunFunction('测试1', @Function1, CreateDefaultBenchmarkConfig);
  LResult2 := RunFunction('测试2', @Function2, CreateDefaultBenchmarkConfig);

  LComparison := CompareResults(LResult1, LResult2);
  WriteLn('性能差异: ', Format('%.2f%%', [LComparison * 100]));
end;
```

## 🔧 最佳实践

1. **预热重要性**: 始终使用适当的预热迭代次数，避免 JIT 编译等因素影响
2. **样本数量**: 使用足够的测量迭代次数获得可靠的统计数据
3. **环境一致性**: 在相同的环境条件下进行基准测试
4. **代码隔离**: 确保测试代码不会相互影响
5. **结果分析**: 关注平均值、标准差和百分位数，而不仅仅是单次结果

## 🚨 注意事项

1. **编译器优化**: 确保在 Release 模式下进行性能测试
2. **系统负载**: 避免在高负载系统上运行基准测试
3. **内存分配**: 注意测试代码中的内存分配对性能的影响
4. **时间精度**: 基准测试基于系统时钟，精度受操作系统限制

---

## 🧪 可选扩展测试

- 为保持主线稳定，某些“额外验证/路径交互”类测试默认不执行，可通过环境变量显式开启：
  - Windows（PowerShell）：`$env:RUN_EXTRA_REPORTER_TESTS=1; .\tests\fafafa.core.benchmark\buildOrTest.bat build-and-run`
  - Windows（cmd）：`set RUN_EXTRA_REPORTER_TESTS=1 && tests\fafafa.core.benchmark\buildOrTest.bat build-and-run`
- 当前包含：
  - Reporter-CSV自定义分隔符（TAB）：验证 CSV 报告器在 sep=tab 路径下的文件输出与列数一致
- 默认关闭这些测试，确保 CI 100% 通过；需要时在本地或专项流水线开启


**版本**: 1.0
**最后更新**: 2025年8月6日
**维护者**: fafafaStudio
