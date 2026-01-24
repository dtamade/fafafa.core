# Sync 模块性能基准测试框架使用指南

## 概述

本指南介绍如何使用 fafafa.core.sync 模块的性能基准测试框架。该框架提供了统一的基准测试工具和报告生成功能，支持跨平台性能对比和 CI 集成。

## 快速开始

### 运行现有基准测试

**Windows**:
```cmd
cd benchmarks\fafafa.core.sync.rwlock
lazbuild -B fafafa.core.sync.rwlock.benchmark.lpi
bin\fafafa.core.sync.rwlock.benchmark.exe
```

**Linux/macOS**:
```bash
cd benchmarks/fafafa.core.sync.rwlock
lazbuild -B fafafa.core.sync.rwlock.benchmark.lpi
./bin/fafafa.core.sync.rwlock.benchmark
```

### 可用的基准测试

**第 1 批：核心原语**（已完成）
- `fafafa.core.sync.mutex` - Mutex 性能测试（parking_lot 实现）
- `fafafa.core.sync.rwlock` - RWLock 性能测试
- `fafafa.core.sync.semaphore` - Semaphore 性能测试
- `fafafa.core.sync.event` - Event 性能测试
- `fafafa.core.sync.condvar` - CondVar 性能测试

## 基准测试框架架构

### 核心组件

1. **高精度计时器**
   - Windows: `QueryPerformanceCounter`
   - Linux/macOS: `clock_gettime(CLOCK_MONOTONIC)`
   - 精度：纳秒级

2. **统一工具类**
   - 位置：`benchmarks/utils/fafafa.core.benchmark.utils.pas`
   - 功能：
     - 高精度计时
     - 结果格式化输出
     - CSV/JSON 报告生成

3. **测试结果结构**
   ```pascal
   TBenchmarkResult = record
     TestName: string;        // 测试名称
     ThreadCount: Integer;    // 线程数
     Operations: Int64;       // 操作次数
     ElapsedNs: Int64;       // 耗时（纳秒）
     OpsPerSecond: Double;   // 吞吐量（ops/sec）
     AvgLatencyNs: Double;   // 平均延迟（ns/op）
   end;
   ```

## 创建新的基准测试

### 步骤 1：创建目录结构

```bash
mkdir -p benchmarks/fafafa.core.sync.原语名
cd benchmarks/fafafa.core.sync.原语名
```

### 步骤 2：编写基准测试程序

**模板结构**:
```pascal
program 原语名Benchmark;
{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  fafafa.core.sync.base,
  fafafa.core.sync.原语名;

{$IFNDEF WINDOWS}
const
  CLOCK_MONOTONIC = 1;

type
  TTimeSpec = record
    tv_sec: Int64;
    tv_nsec: Int64;
  end;
  PTimeSpec = ^TTimeSpec;

function clock_gettime(clk_id: Integer; tp: PTimeSpec): Integer; cdecl; external 'c';
{$ENDIF}

type
  THighResTime = record
    {$IFDEF WINDOWS}
    Value: Int64;
    {$ELSE}
    Sec: Int64;
    NSec: Int64;
    {$ENDIF}
  end;

  TBenchmarkResult = record
    TestName: string;
    ThreadCount: Integer;
    Operations: Int64;
    ElapsedNs: Int64;
    OpsPerSecond: Double;
    AvgLatencyNs: Double;
  end;

{$IFDEF WINDOWS}
var
  Frequency: Int64;
{$ENDIF}

function GetHighResTime: THighResTime;
{$IFNDEF WINDOWS}
var
  ts: TTimeSpec;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  QueryPerformanceCounter(Result.Value);
  {$ELSE}
  clock_gettime(CLOCK_MONOTONIC, @ts);
  Result.Sec := ts.tv_sec;
  Result.NSec := ts.tv_nsec;
  {$ENDIF}
end;

function CalcElapsedNs(const AStart, AEnd: THighResTime): Int64;
begin
  {$IFDEF WINDOWS}
  Result := ((AEnd.Value - AStart.Value) * 1000000000) div Frequency;
  {$ELSE}
  Result := (AEnd.Sec - AStart.Sec) * 1000000000 + (AEnd.NSec - AStart.NSec);
  {$ENDIF}
end;

// 实现你的基准测试逻辑...

begin
  {$IFDEF WINDOWS}
  QueryPerformanceFrequency(Frequency);
  {$ENDIF}
  
  try
    RunAllBenchmarks;
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
```

### 步骤 3：设计测试场景

**推荐的测试场景**:

1. **单线程吞吐量测试**
   - 目标：测量单线程环境下的操作吞吐量
   - 线程数：1
   - 持续时间：1-2 秒

2. **多线程竞争测试**
   - 目标：测量多线程并发环境下的性能
   - 线程数：1, 2, 4, 8
   - 持续时间：1-2 秒

3. **延迟测试**
   - 目标：测量操作的延迟分布
   - 记录：P50, P95, P99 延迟

### 步骤 4：创建项目文件

**Lazarus 项目文件 (.lpi)**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CONFIG>
  <ProjectOptions>
    <General>
      <Flags>
        <MainUnitHasCreateFormStatements Value="False"/>
        <MainUnitHasTitleStatement Value="False"/>
        <MainUnitHasScaledStatement Value="False"/>
      </Flags>
      <SessionStorage Value="InProjectDir"/>
      <Title Value="原语名Benchmark"/>
    </General>
    <BuildModes>
      <Item Name="Default" Default="True"/>
    </BuildModes>
    <PublishOptions>
      <Version Value="2"/>
      <UseFileFilters Value="True"/>
    </PublishOptions>
    <RunParams>
      <FormatVersion Value="2"/>
    </RunParams>
    <Units>
      <Unit>
        <Filename Value="fafafa.core.sync.原语名.benchmark.lpr"/>
        <IsPartOfProject Value="True"/>
      </Unit>
    </Units>
  </ProjectOptions>
  <CompilerOptions>
    <Version Value="11"/>
    <Target>
      <Filename Value="bin/fafafa.core.sync.原语名.benchmark"/>
    </Target>
    <SearchPaths>
      <IncludeFiles Value="$(ProjOutDir);../../src"/>
      <OtherUnitFiles Value="../../src;../utils"/>
      <UnitOutputDirectory Value="lib/$(TargetCPU)-$(TargetOS)"/>
    </SearchPaths>
    <CodeGeneration>
      <Optimizations>
        <OptimizationLevel Value="3"/>
      </Optimizations>
    </CodeGeneration>
  </CompilerOptions>
</CONFIG>
```

## 报告生成

### Console 输出（默认）

**格式**:
```
================================================================================
原语名 Performance Benchmark
================================================================================

--- 测试场景 1 ---
TestName/Scenario                         1 threads:    1000000 ops in  100.000 ms |   10000000 ops/sec |   100.00 ns/op
TestName/Scenario                         2 threads:    2000000 ops in  100.000 ms |   20000000 ops/sec |    50.00 ns/op

================================================================================
Benchmark Complete
================================================================================
```

### CSV 报告

**生成方法**:
```pascal
uses
  fafafa.core.benchmark.utils;

var
  LResults: TBenchmarkResults;
begin
  // 运行基准测试并收集结果
  SetLength(LResults, 测试数量);
  // ... 填充结果 ...
  
  // 保存为 CSV
  SaveResultsToCSV(LResults, 'benchmark_results.csv');
end;
```

**CSV 格式**:
```csv
TestName,ThreadCount,Operations,ElapsedMs,OpsPerSecond,AvgLatencyNs
Mutex/SingleThread,1,46000000,1000.000,46000000,21.74
Mutex/MultiThread,4,12000000,1000.000,12000000,83.33
```

### JSON 报告

**生成方法**:
```pascal
uses
  fafafa.core.benchmark.utils;

var
  LResults: TBenchmarkResults;
begin
  // 运行基准测试并收集结果
  SetLength(LResults, 测试数量);
  // ... 填充结果 ...
  
  // 保存为 JSON
  SaveResultsToJSON(LResults, 'benchmark_results.json');
end;
```

**JSON 格式**:
```json
{
  "benchmarks": [
    {
      "name": "Mutex/SingleThread",
      "thread_count": 1,
      "operations": 46000000,
      "elapsed_ms": 1000.000,
      "ops_per_second": 46000000,
      "avg_latency_ns": 21.74
    }
  ]
}
```

## 性能对比

### 与原生 API 对比

**示例**（Mutex vs CRITICAL_SECTION）:
```pascal
// 测试 fafafa.core Mutex
LResult1 := RunBenchmark('fafafa.core.Mutex', ...);

// 测试 Windows CRITICAL_SECTION
LResult2 := RunBenchmark('CRITICAL_SECTION', ...);

// 对比
WriteLn(Format('fafafa.core.Mutex: %.0f ops/sec', [LResult1.OpsPerSecond]));
WriteLn(Format('CRITICAL_SECTION: %.0f ops/sec', [LResult2.OpsPerSecond]));
WriteLn(Format('Ratio: %.2fx', [LResult1.OpsPerSecond / LResult2.OpsPerSecond]));
```

### 跨平台对比

**方法**:
1. 在 Windows 上运行基准测试并保存 CSV
2. 在 Linux 上运行相同基准测试并保存 CSV
3. 使用 Excel 或脚本对比结果

## CI 集成

### 性能回归检测

**步骤 1：建立性能基线**
```bash
# 运行基准测试并保存结果
./benchmark > baseline.json
```

**步骤 2：在 CI 中运行基准测试**
```bash
# 运行基准测试
./benchmark > current.json

# 对比基线
python3 compare_baseline.py baseline.json current.json
```

**步骤 3：检测回归**
```python
# compare_baseline.py
import json
import sys

def compare(baseline, current):
    for test in baseline['benchmarks']:
        name = test['name']
        baseline_ops = test['ops_per_second']
        
        current_test = next((t for t in current['benchmarks'] if t['name'] == name), None)
        if not current_test:
            continue
            
        current_ops = current_test['ops_per_second']
        ratio = current_ops / baseline_ops
        
        if ratio < 0.9:  # 性能下降超过 10%
            print(f'REGRESSION: {name} - {ratio:.2%} of baseline')
            return 1
    
    return 0

if __name__ == '__main__':
    with open(sys.argv[1]) as f:
        baseline = json.load(f)
    with open(sys.argv[2]) as f:
        current = json.load(f)
    
    sys.exit(compare(baseline, current))
```

## 最佳实践

### 1. 测试持续时间

- **推荐**：1-2 秒
- **原因**：足够长以获得稳定结果，足够短以快速迭代

### 2. 线程数选择

- **推荐**：1, 2, 4, 8
- **原因**：覆盖单线程到多核并发场景

### 3. 预热

```pascal
// 预热：运行 100ms 让 CPU 缓存预热
for i := 1 to 1000000 do
begin
  // 执行操作
end;

// 正式测试
LStartTime := GetHighResTime;
// ...
```

### 4. 避免干扰

- 关闭其他应用程序
- 禁用 CPU 频率调节
- 多次运行取平均值

### 5. 结果验证

- 检查操作次数是否合理
- 检查延迟是否在预期范围
- 对比不同平台的结果

## 故障排查

### 问题：编译错误

**解决方法**:
1. 检查 `uses` 子句是否包含所有必需单元
2. 检查项目文件的搜索路径配置
3. 确保 `fafafa.core.settings.inc` 被正确包含

### 问题：性能结果不稳定

**解决方法**:
1. 增加测试持续时间
2. 多次运行取平均值
3. 检查系统负载

### 问题：跨平台结果差异大

**解决方法**:
1. 检查编译优化级别是否一致
2. 检查操作系统版本和配置
3. 考虑平台特定的实现差异

## 参考资料

- **现有基准测试**：
  - `benchmarks/fafafa.core.sync.mutex/` - parking_lot Mutex 实现
  - `benchmarks/fafafa.core.sync.rwlock/` - RWLock 实现
  - `benchmarks/fafafa.core.sync.semaphore/` - Semaphore 实现

- **工具类**：
  - `benchmarks/utils/fafafa.core.benchmark.utils.pas`

- **文档**：
  - `.claude/plan/sync-benchmark-framework.md` - 完整实施计划

## 贡献指南

如果您想为基准测试框架做出贡献：

1. 遵循现有的代码风格和结构
2. 为新的基准测试编写文档
3. 确保跨平台兼容性
4. 提供性能对比数据

---

**版本**：v1.0  
**创建日期**：2026-01-25  
**最后更新**：2026-01-25
