# Sync 模块性能基准测试体系建设计划

## 项目概述

**目标**：为 fafafa.core.sync 模块建立完整的性能基准测试体系，覆盖所有 21 个同步原语，支持跨平台对比和性能回归检测。

**时间规划**：3 周（分 3 批完成）

**负责人**：Claude (Sisyphus)

**批准日期**：2026-01-25

---

## 项目背景

### 现状分析

**已有基准测试**（3个）：
- ✅ `benchmarks/fafafa.core.sync.mutex` - parking_lot Mutex（世界级性能：55-63M ops/sec）
- ✅ `benchmarks/fafafa.core.sync.spin` - 自旋锁
- ✅ `benchmarks/fafafa.core.sync.namedEvent` - 命名事件

**Sync 模块架构**：
- **核心原语**（10个）：Mutex, RWLock, Semaphore, Event, CondVar, Barrier, Once, Latch, WaitGroup, Parker, Spin
- **命名原语**（11个）：所有核心原语的跨进程版本 + SharedCounter
- **特殊实现**：parking_lot Mutex（已达 Rust std::sync 水平）
- **跨平台**：Windows/Unix 双平台完整实现

**现有基准测试框架**：
- ✅ `fafafa.core.benchmark.pas` - Google Benchmark 风格 API
- ✅ `fafafa.core.report.sink.console.pas` - 控制台输出
- ✅ `fafafa.core.report.sink.json.pas` - JSON 格式输出
- ✅ `benchmarks/fafafa.core.atomic/utils/benchmark_utils.pas` - 可复用工具类

### 待完善的部分

1. **覆盖率不足**：只有 3 个原语有基准测试，缺少其他 18 个原语
2. **报告格式单一**：缺少 CSV 格式输出（便于 Excel 分析）
3. **缺少统一框架**：每个基准测试都是独立实现，没有复用代码
4. **缺少 CI 集成**：没有性能回归检测机制

---

## 技术方案

### 总体架构

**采用方案 A：统一基准测试框架**

**核心设计**：
1. **复用现有框架**：`fafafa.core.benchmark.pas`（Google Benchmark 风格）
2. **统一测试模板**：为所有原语创建一致的测试结构
3. **多维度测试**：吞吐量、延迟、并发竞争
4. **统一报告**：Console/JSON/CSV 三种格式

### 统一测试模板结构

```pascal
program fafafa.core.sync.原语名.benchmark;
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  fafafa.core.benchmark,
  fafafa.core.sync.原语名;

// 测试场景 1：单线程吞吐量
procedure Bench_原语名_SingleThread_Throughput;
begin
  // 实现单线程吞吐量测试
end;

// 测试场景 2：多线程竞争
procedure Bench_原语名_MultiThread_Contention;
begin
  // 实现多线程竞争测试
end;

// 测试场景 3：延迟测试
procedure Bench_原语名_Latency;
begin
  // 实现延迟测试
end;

begin
  RegisterBenchmark('原语名/SingleThread', @Bench_原语名_SingleThread_Throughput);
  RegisterBenchmark('原语名/MultiThread', @Bench_原语名_MultiThread_Contention);
  RegisterBenchmark('原语名/Latency', @Bench_原语名_Latency);
  RunBenchmarks;
end.
```

### 报告输出格式

#### Console 输出（已有）
```
Benchmark                    Time        CPU   Iterations
-----------------------------------------------------------
Mutex/SingleThread      15.2 ns    15.2 ns   46000000
Mutex/MultiThread       125 ns     500 ns    1400000
```

#### JSON 输出（已有）
```json
{
  "benchmarks": [
    {
      "name": "Mutex/SingleThread",
      "time_ns": 15.2,
      "cpu_ns": 15.2,
      "iterations": 46000000
    }
  ]
}
```

#### CSV 输出（新增）
```csv
Name,Time(ns),CPU(ns),Iterations
Mutex/SingleThread,15.2,15.2,46000000
Mutex/MultiThread,125,500,1400000
```

### CI 集成方案

#### 性能基线文件
**文件路径**：`benchmarks/baseline.json`

```json
{
  "Mutex/SingleThread": {"time_ns": 15.2, "tolerance": 0.1},
  "RWLock/Read": {"time_ns": 12.5, "tolerance": 0.15}
}
```

#### 回归检测脚本
**文件路径**：`benchmarks/check_regression.sh`

```bash
#!/bin/bash
# 运行基准测试并对比基线
./run_benchmarks.sh --output=current.json
python3 compare_baseline.py baseline.json current.json
```

---

## 实施路线图

### 第 1 批：核心原语基准测试（优先级最高，1 周）

**目标**：建立基准测试框架模板，覆盖最常用的 5 个核心原语

**模块列表**：
1. ✅ `Mutex`（已有，需验证和标准化）
2. 🆕 `RWLock`（读写锁）
3. 🆕 `Semaphore`（信号量）
4. 🆕 `Event`（事件）
5. 🆕 `CondVar`（条件变量）

**交付物**：
- `benchmarks/fafafa.core.sync.rwlock/` - RWLock 基准测试
- `benchmarks/fafafa.core.sync.semaphore/` - Semaphore 基准测试
- `benchmarks/fafafa.core.sync.event/` - Event 基准测试
- `benchmarks/fafafa.core.sync.condvar/` - CondVar 基准测试
- `benchmarks/README.md` - 基准测试框架使用指南
- 统一的测试模板和工具类

**成功标准**：
- [ ] 5 个核心原语基准测试全部通过编译
- [ ] 所有测试可在 Windows/Linux 上运行
- [ ] 生成 Console/JSON/CSV 三种格式报告
- [ ] 文档完整（README + 使用指南）

---

### 第 2 批：高级原语基准测试（1 周）

**目标**：覆盖高级同步原语

**模块列表**：
1. 🆕 `Barrier`（屏障）
2. 🆕 `Once`（一次性执行）
3. 🆕 `Latch`（倒计时门闩）
4. 🆕 `WaitGroup`（等待组）
5. 🆕 `Parker`（线程停靠）

**交付物**：
- 5 个高级原语的基准测试
- 性能对比报告（与 Rust std::sync 对比）

**成功标准**：
- [ ] 5 个高级原语基准测试全部通过
- [ ] 性能对比报告完成（与 Rust std::sync）

---

### 第 3 批：命名原语基准测试（1 周）

**目标**：覆盖所有跨进程命名原语

**模块列表**：
1. 🆕 `namedMutex`
2. 🆕 `namedRWLock`
3. 🆕 `namedSemaphore`
4. 🆕 `namedEvent`
5. 🆕 `namedBarrier`
6. 🆕 `namedCondVar`
7. 🆕 `namedOnce`
8. 🆕 `namedLatch`
9. 🆕 `namedWaitGroup`
10. 🆕 `namedSharedCounter`
11. 🆕 `namedParker`

**交付物**：
- 11 个命名原语的基准测试
- 跨进程通信性能报告
- CI 集成脚本（性能回归检测）

**成功标准**：
- [ ] 11 个命名原语基准测试全部通过
- [ ] CI 集成脚本可用
- [ ] 性能回归检测机制验证通过

---

## 技术实现细节

### 测试场景设计

#### 1. 单线程吞吐量测试
**目标**：测量单线程环境下的操作吞吐量（ops/sec）

**实现要点**：
- 使用高精度计时器（Windows QueryPerformanceCounter / Linux clock_gettime）
- 运行足够多的迭代次数以获得稳定结果
- 计算平均每次操作的时间（ns/op）

#### 2. 多线程竞争测试
**目标**：测量多线程并发环境下的性能

**实现要点**：
- 测试不同线程数（1/2/4/8 线程）
- 模拟真实的竞争场景
- 记录总吞吐量和每线程吞吐量

#### 3. 延迟测试
**目标**：测量操作的延迟分布

**实现要点**：
- 记录每次操作的延迟
- 计算 P50/P95/P99 延迟
- 识别异常值和尾延迟

### 跨平台对比

**对比维度**：
1. **Windows vs Linux**：不同操作系统的性能差异
2. **原生 API vs fafafa.core**：与系统原生实现对比
3. **fafafa.core vs Rust std::sync**：与业界标准对比

### 性能回归检测

**检测流程**：
1. 建立性能基线（baseline.json）
2. 每次 CI 运行基准测试
3. 对比当前结果与基线
4. 如果性能下降超过阈值（如 10%），CI 失败

---

## 风险与挑战

### 技术风险

1. **跨平台差异**
   - **风险**：不同平台的性能特性差异大
   - **缓解**：为每个平台建立独立的基线

2. **测试稳定性**
   - **风险**：性能测试结果可能不稳定
   - **缓解**：多次运行取平均值，设置合理的容差

3. **工作量估算**
   - **风险**：18 个原语的基准测试工作量大
   - **缓解**：使用统一模板，复用代码

### 资源约束

1. **时间约束**：3 周时间紧张
2. **平台约束**：需要多平台测试环境
3. **人力约束**：单人开发

---

## 成功指标

### 量化指标

1. **覆盖率**：21 个原语全部有基准测试（100%）
2. **报告格式**：支持 Console/JSON/CSV 三种格式
3. **跨平台**：Windows/Linux 双平台可运行
4. **CI 集成**：性能回归检测机制可用

### 质量指标

1. **代码质量**：遵循项目编码规范
2. **文档完整**：README + 使用指南 + API 文档
3. **测试稳定**：基准测试结果可重现
4. **性能对比**：与业界标准（Rust std::sync）对比

---

## 下一步行动

### 立即开始（第 1 批）

1. ✅ 创建计划文档（本文档）
2. 🔄 创建 RWLock 基准测试
3. 🔄 创建 Semaphore 基准测试
4. 🔄 创建 Event 基准测试
5. 🔄 创建 CondVar 基准测试
6. 🔄 验证 Mutex 基准测试并标准化
7. 🔄 创建统一的基准测试工具类
8. 🔄 创建 CSV 报告输出器
9. 🔄 编写基准测试框架使用指南
10. 🔄 运行所有基准测试并生成报告

---

## 附录

### 参考资料

1. **现有基准测试**：
   - `benchmarks/fafafa.core.sync.mutex/README.md`
   - `benchmarks/fafafa.core.sync.spin/`
   - `benchmarks/fafafa.core.sync.namedEvent/`

2. **基准测试框架**：
   - `src/fafafa.core.benchmark.pas`
   - `src/fafafa.core.report.sink.console.pas`
   - `src/fafafa.core.report.sink.json.pas`

3. **Sync 模块源码**：
   - `src/fafafa.core.sync.*.pas`

### 相关文档

- `docs/TESTING.md` - 测试规范
- `docs/CI.md` - CI 集成规范
- `AGENTS.md` - 开发规范

---

**文档版本**：v1.0  
**创建日期**：2026-01-25  
**最后更新**：2026-01-25  
**状态**：已批准，进入实施阶段
