# fafafa.core.benchmark v2.0 设计文档

## 🎯 设计目标

基于 Google Benchmark 的设计理念，重新设计 fafafa.core.benchmark 框架，提供更现代化、更强大的基准测试功能。

## 🔄 与 Google Benchmark 的对比

### Google Benchmark 核心特性

```cpp
// Google Benchmark 风格
static void BM_StringCreation(benchmark::State& state) {
  for (auto _ : state)
    std::string empty_string;
}
BENCHMARK(BM_StringCreation);

static void BM_StringCopy(benchmark::State& state) {
  std::string x = "hello";
  for (auto _ : state)
    std::string copy(x);
}
BENCHMARK(BM_StringCopy);
```

### fafafa.core.benchmark v2.0 对应实现

```pascal
// fafafa.core.benchmark v2.0 风格
procedure BM_StringCreation(aState: IBenchmarkState);
var
  LEmptyString: string;
begin
  while aState.KeepRunning do
    LEmptyString := '';
end;

procedure BM_StringCopy(aState: IBenchmarkState);
var
  LX: string;
  LCopy: string;
begin
  LX := 'hello';
  while aState.KeepRunning do
    LCopy := LX;
end;

// 注册和运行
begin
  RegisterBenchmark('StringCreation', @BM_StringCreation);
  RegisterBenchmark('StringCopy', @BM_StringCopy);
  RunAllBenchmarks;
end;
```

## 🏗️ 核心架构设计

### 1. State-based API

**核心接口：IBenchmarkState**

```pascal
IBenchmarkState = interface
  // 核心控制
  function KeepRunning: Boolean;
  procedure SetIterations(aCount: Int64);
  
  // 计时控制
  procedure PauseTiming;
  procedure ResumeTiming;
  
  // 吞吐量测量
  procedure SetBytesProcessed(aBytes: Int64);
  procedure SetItemsProcessed(aItems: Int64);
  
  // 复杂度分析
  procedure SetComplexityN(aN: Int64);
  
  // 自定义指标
  procedure AddCounter(const aName: string; aValue: Double; aUnit: TCounterUnit);
  
  // 状态查询
  function GetIterations: Int64;
  function GetElapsedTime: Double;
end;
```

**设计优势：**
- 框架控制执行流程，自动决定迭代次数
- 支持暂停/恢复计时，排除 setup 代码影响
- 丰富的测量指标支持
- 统一的状态管理

### 2. 测试夹具支持

**IBenchmarkFixture 接口**

```pascal
IBenchmarkFixture = interface
  procedure SetUp(aState: IBenchmarkState);
  procedure TearDown(aState: IBenchmarkState);
end;

// 使用示例
type
  TDatabaseFixture = class(TInterfacedObject, IBenchmarkFixture)
    procedure SetUp(aState: IBenchmarkState);    // 连接数据库
    procedure TearDown(aState: IBenchmarkState); // 清理数据
  end;

RegisterBenchmarkWithFixture('DatabaseQuery', @BM_Query, TDatabaseFixture.Create);
```

### 3. 自动迭代控制

**智能迭代算法：**
1. 初始运行少量迭代估算单次耗时
2. 根据目标运行时间计算所需迭代次数
3. 自动调整以获得稳定的统计结果
4. 支持手动覆盖迭代次数

```pascal
procedure BM_FastOperation(aState: IBenchmarkState);
begin
  while aState.KeepRunning do
  begin
    // 快速操作 - 框架会自动运行更多次
    DoFastOperation();
  end;
end;

procedure BM_SlowOperation(aState: IBenchmarkState);
begin
  while aState.KeepRunning do
  begin
    // 慢速操作 - 框架会自动运行较少次
    DoSlowOperation();
  end;
end;
```

### 4. 丰富的测量指标

**支持的指标类型：**

```pascal
// 时间测量（自动）
aState.GetElapsedTime;

// 吞吐量测量
aState.SetBytesProcessed(1024 * 1024);  // MB/s
aState.SetItemsProcessed(10000);        // items/s

// 自定义计数器
aState.AddCounter('cache_hits', 95.5, cuPercentage);
aState.AddCounter('memory_used', 1024, cuBytes);
aState.AddCounter('operations', 1000, cuItems);

// 复杂度分析
aState.SetComplexityN(inputSize);  // 用于 O(n) 分析
```

### 5. 全局注册机制

**注册 API：**

```pascal
// 基本注册
function RegisterBenchmark(const aName: string; aFunc: TBenchmarkFunction): IBenchmark;

// 带夹具注册
function RegisterBenchmarkWithFixture(const aName: string; aFunc: TBenchmarkFunction; 
  aFixture: IBenchmarkFixture): IBenchmark;

// 批量运行
function RunAllBenchmarks: TBenchmarkResultArray;
function RunAllBenchmarksWithReporter(aReporter: IBenchmarkReporter): TBenchmarkResultArray;
```

## 🔧 高级功能

### 1. 参数化测试（计划中）

```pascal
// 未来版本支持
procedure BM_SortArray(aState: IBenchmarkState);
var
  LSize: Integer;
begin
  LSize := aState.GetParameter('size');
  // 使用不同大小的数组进行测试
end;

// 注册不同参数的测试
RegisterBenchmarkRange('SortArray', @BM_SortArray, 1, 1000000);
```

### 2. 复杂度分析（计划中）

```pascal
procedure BM_LinearSearch(aState: IBenchmarkState);
begin
  aState.SetComplexityN(arraySize);
  while aState.KeepRunning do
  begin
    LinearSearch(array, target);
  end;
end;

// 自动分析算法复杂度：O(n), O(log n), O(n²) 等
```

### 3. 多线程支持（计划中）

```pascal
procedure BM_ParallelSort(aState: IBenchmarkState);
begin
  aState.SetThreads(4);  // 使用 4 个线程
  while aState.KeepRunning do
  begin
    ParallelSort(data);
  end;
end;
```

## 🔄 向后兼容性

### 传统 API 支持

```pascal
// v1.0 风格（继续支持）
function RunLegacyFunction(const aName: string; aFunc: TLegacyBenchmarkFunction; 
  const aConfig: TBenchmarkConfig): IBenchmarkResult;

// 自动转换为新风格
procedure LegacyToNewAdapter(aState: IBenchmarkState);
begin
  aState.SetIterations(config.MeasureIterations);
  while aState.KeepRunning do
    legacyFunction();
end;
```

## 📊 增强的结果分析

### 新的结果接口

```pascal
IBenchmarkResult = interface
  // 基本信息
  function GetName: string;
  function GetIterations: Int64;
  function GetTotalTime: Double;
  
  // 吞吐量指标
  function GetBytesPerSecond: Double;
  function GetItemsPerSecond: Double;
  
  // 自定义计数器
  function GetCounters: TBenchmarkCounterArray;
  
  // 复杂度分析
  function GetComplexityN: Int64;
end;
```

### 丰富的报告格式

```pascal
// 控制台输出示例
Benchmark                Time           CPU    Iterations
BM_StringCreation       15 ns         15 ns      46666667
BM_StringCopy           25 ns         25 ns      28000000
BM_MemoryCopy         1024 bytes/s   1024 MB/s     1000000
BM_CustomCounter      95.5% hits     1000 ops       10000
```

## 🎯 实现计划

### 阶段 1：核心接口（当前）
- ✅ IBenchmarkState 接口设计
- ✅ IBenchmarkFixture 接口设计
- ✅ 新的函数签名定义
- ✅ 注册机制设计

### 阶段 2：基础实现
- [ ] TBenchmarkState 实现
- [ ] 自动迭代控制算法
- [ ] 测试夹具支持
- [ ] 全局注册管理器

### 阶段 3：高级功能
- [ ] 自定义计数器系统
- [ ] 复杂度分析
- [ ] 参数化测试
- [ ] 多线程支持

### 阶段 4：完善和优化
- [ ] 性能优化
- [ ] 内存测量
- [ ] 高级报告格式
- [ ] 文档和示例

## 🔍 与竞品对比

| 特性 | Google Benchmark | fafafa.core.benchmark v2.0 | 优势 |
|------|------------------|----------------------------|------|
| State-based API | ✅ | ✅ | 统一的执行控制 |
| 自动迭代 | ✅ | ✅ | 智能性能测量 |
| 测试夹具 | ✅ | ✅ | Setup/TearDown 支持 |
| 自定义计数器 | ✅ | ✅ | 丰富的指标 |
| 复杂度分析 | ✅ | 🔄 | 算法分析能力 |
| 参数化测试 | ✅ | 🔄 | 批量参数测试 |
| 多线程测试 | ✅ | 🔄 | 并发性能测试 |
| FreePascal 原生 | ❌ | ✅ | 无需外部依赖 |

## 📝 总结

新的 v2.0 设计将 fafafa.core.benchmark 提升到与 Google Benchmark 相当的水平，提供：

1. **现代化 API** - State-based 设计，更强大更灵活
2. **自动化控制** - 智能迭代次数，减少人工配置
3. **丰富功能** - 夹具、计数器、复杂度分析
4. **向后兼容** - 保持现有代码可用
5. **FreePascal 原生** - 无外部依赖，完美集成

这个设计将使 fafafa.core.benchmark 成为 FreePascal 生态中最强大的基准测试框架！
