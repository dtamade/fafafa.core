# 多线程基准测试使用指南

## 🎯 概述

`fafafa.core.benchmark` 框架现在支持多线程基准测试，可以测量并发操作的性能，对比单线程与多线程的效率差异。

## 🚀 基本用法

### 1. 定义多线程测试函数

```pascal
procedure MyMultiThreadTest(aState: IBenchmarkState; aThreadIndex: Integer);
var
  LI: Integer;
  LSum: Integer;
begin
  LSum := 0;
  
  // 每个线程做1000次计算
  for LI := 1 to 1000 do
    LSum := LSum + LI + aThreadIndex;
  
  // 可以根据线程索引做不同的工作
  if aThreadIndex = 0 then
    WriteLn('主线程完成工作');
end;
```

### 2. 运行多线程测试

```pascal
// 最简单的方式
var LResult := RunMultiThreadBenchmark('我的多线程测试', @MyMultiThreadTest, 4);
WriteLn('4线程性能: ', Format('%.2f μs/op', [LResult.GetTimePerIteration(buMicroSeconds)]));

// 使用自定义配置
var LConfig := CreateDefaultBenchmarkConfig;
LConfig.WarmupIterations := 3;
LConfig.MeasureIterations := 8;

var LResult := RunMultiThreadBenchmark('详细测试', @MyMultiThreadTest, 4, LConfig);
```

### 3. 高级配置

```pascal
var LRunner := CreateBenchmarkRunner;
var LThreadConfig := CreateMultiThreadConfig(
  4,      // 线程数量
  1000,   // 每个线程的工作量
  True    // 同步启动所有线程
);
var LConfig := CreateDefaultBenchmarkConfig;

var LResult := LRunner.RunMultiThreadFunction('高级测试', @MyMultiThreadTest, 
                                             LThreadConfig, LConfig);
```

## 📊 典型使用场景

### 1. 单线程 vs 多线程性能对比

```pascal
// 单线程版本
procedure SingleThreadWork(aState: IBenchmarkState);
var LI: Integer; LSum: Integer;
begin
  while aState.KeepRunning do
  begin
    LSum := 0;
    for LI := 1 to 4000 do // 总工作量
      LSum := LSum + LI;
    aState.SetItemsProcessed(4000);
  end;
end;

// 多线程版本
procedure MultiThreadWork(aState: IBenchmarkState; aThreadIndex: Integer);
var LI: Integer; LSum: Integer;
begin
  LSum := 0;
  for LI := 1 to 1000 do // 每个线程1000，4个线程总共4000
    LSum := LSum + LI + aThreadIndex;
end;

// 对比测试
var LResult1 := RunLegacyFunction('单线程', @SingleThreadWork, LConfig);
var LResult2 := RunMultiThreadBenchmark('多线程', @MultiThreadWork, 4, LConfig);

var LSpeedup := LResult1.GetTimePerIteration() / LResult2.GetTimePerIteration();
WriteLn('加速比: ', Format('%.2fx', [LSpeedup]));
```

### 2. 锁竞争测试

```pascal
var GSharedCounter: Integer;
var GSharedLock: TCriticalSection;

procedure TestLockContention(aState: IBenchmarkState; aThreadIndex: Integer);
var LI: Integer;
begin
  for LI := 1 to 250 do // 每个线程250次，4个线程总共1000次
  begin
    GSharedLock.Enter;
    try
      Inc(GSharedCounter);
    finally
      GSharedLock.Leave;
    end;
  end;
end;

// 使用
GSharedCounter := 0;
GSharedLock := TCriticalSection.Create;
try
  var LResult := RunMultiThreadBenchmark('锁竞争测试', @TestLockContention, 4);
  WriteLn('锁竞争性能: ', Format('%.2f μs/op', [LResult.GetTimePerIteration(buMicroSeconds)]));
  WriteLn('最终计数: ', GSharedCounter); // 应该是1000
finally
  GSharedLock.Free;
end;
```

### 3. 可扩展性测试

```pascal
procedure TestScalability;
var
  LThreadCounts: array[0..3] of Integer = (1, 2, 4, 8);
  LResults: array[0..3] of IBenchmarkResult;
  LI: Integer;
begin
  for LI := 0 to High(LThreadCounts) do
  begin
    LResults[LI] := RunMultiThreadBenchmark('测试-' + IntToStr(LThreadCounts[LI]) + '线程', 
                                           @MyMultiThreadTest, LThreadCounts[LI]);
    WriteLn(LThreadCounts[LI], ' 线程: ', 
            Format('%.2f μs/op', [LResults[LI].GetTimePerIteration(buMicroSeconds)]));
  end;
  
  // 分析可扩展性
  var LBaseTime := LResults[0].GetTimePerIteration();
  for LI := 1 to High(LResults) do
  begin
    var LSpeedup := LBaseTime / LResults[LI].GetTimePerIteration();
    var LEfficiency := LSpeedup / LThreadCounts[LI] * 100;
    WriteLn(LThreadCounts[LI], ' 线程效率: ', Format('%.1f%%', [LEfficiency]));
  end;
end;
```

## 🔧 配置选项

### TMultiThreadConfig 参数

- **ThreadCount**: 线程数量（必须 > 0）
- **WorkPerThread**: 每个线程的工作量（可选，用于统计）
- **SyncThreads**: 是否同步启动所有线程（推荐 True）

### 便捷函数

```pascal
// 创建多线程配置
var LConfig := CreateMultiThreadConfig(4, 1000, True);

// 简单运行（使用默认配置）
var LResult := RunMultiThreadBenchmark('测试', @MyTest, 4);

// 带自定义配置运行
var LBenchConfig := CreateDefaultBenchmarkConfig;
var LResult := RunMultiThreadBenchmark('测试', @MyTest, 4, LBenchConfig);
```

## ⚠️ 注意事项

### 1. 线程安全
- 确保测试函数中的操作是线程安全的
- 使用适当的同步机制（锁、原子操作等）
- 避免竞争条件

### 2. 工作量平衡
- 确保每个线程的工作量相似
- 避免某些线程过早完成而影响测量

### 3. 资源管理
- 测试前初始化共享资源
- 测试后正确清理资源
- 注意内存泄漏

### 4. 测量精度
- 多线程测试的变异性通常更大
- 建议增加测量迭代次数
- 使用预热来稳定性能

## 📈 结果解读

### 性能指标
- **时间/操作**: 完成一次完整多线程操作的时间
- **吞吐量**: 每秒完成的操作数
- **加速比**: 相对于单线程的性能提升倍数
- **效率**: 加速比除以线程数的百分比

### 理想情况
- **线性加速**: 4线程应该有接近4倍的性能提升
- **高效率**: 效率应该接近100%
- **低变异性**: 多次测量结果应该稳定

### 常见问题
- **加速比 < 线程数**: 可能存在锁竞争或负载不均衡
- **效率 < 50%**: 线程开销过大或任务不适合并行化
- **高变异性**: 系统负载不稳定或测试设计有问题

## 🎯 最佳实践

1. **先测单线程**: 建立性能基线
2. **逐步增加线程**: 找到最优线程数
3. **测量多次**: 确保结果稳定
4. **分析瓶颈**: 识别性能限制因素
5. **文档记录**: 记录测试环境和结果

---

**示例程序**: `example_multithreaded_benchmark.lpr`  
**完整文档**: `fafafa.core.benchmark.md`
