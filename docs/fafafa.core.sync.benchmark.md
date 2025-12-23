# fafafa.core.sync 基准测试报告

## 概述

本文档记录 `fafafa.core.sync` 模块的性能基准测试结果，特别是 pthread_mutex 与 futex 实现的对比。

## 测试环境

- **平台**: Linux x86_64
- **编译器**: Free Pascal 3.3.1
- **优化级别**: -O3 (最高优化)
- **迭代次数**: 10,000,000 (1000 万次)
- **预热次数**: 100,000
- **线程数**: 4

## 基准测试结果

### pthread_mutex vs futex 对比

```
================================================================================
                            Benchmark Results
================================================================================

Scenario                                         ns/op       M ops/sec    Speedup
---------------------------------------------------------------------------------
Single Thread (pthread)                          23.18           43.14          -
Single Thread (futex)                            27.42           36.47      0.85x

Rapid Acquire/Release (pthread)                  25.70           38.91          -
Rapid Acquire/Release (futex)                    27.57           36.27      0.93x

4 Threads Low Contention (pthread)              130.09            7.69          -
4 Threads Low Contention (futex)                330.30            3.03      0.39x

4 Threads High Contention (pthread)             300.21            3.33          -
4 Threads High Contention (futex)               450.30            2.22      0.67x

SpinLock Single Thread                           13.64           73.32          -
SpinLock 4 Threads                              100.07            9.99          -
================================================================================
```

### 分析

| 场景 | 获胜者 | 性能差距 |
|------|--------|----------|
| 单线程无竞争 | pthread | 18% 更快 |
| 单线程快速获取 | pthread | 7% 更快 |
| 4 线程低竞争 | pthread | 154% 更快 |
| 4 线程高竞争 | pthread | 50% 更快 |

### 结论

**pthread_mutex 在所有场景下都优于直接使用 futex**

原因分析：
1. **glibc 优化**: Linux 的 `pthread_mutex` 底层也使用 futex，但 glibc 经过多年优化
2. **自适应锁**: glibc 实现了自适应自旋策略
3. **缓存友好**: glibc 的数据结构对缓存更友好

### 建议

1. **默认使用 MakeMutex()** - 在 Linux 上会自动选择最优实现
2. **SpinLock 最快** - 单线程场景下 SpinLock 性能最佳 (13.64 ns/op)
3. **避免高竞争** - 多线程高竞争场景性能下降明显

## 同步原语性能概览

| 原语 | 单线程 ns/op | 4线程 ns/op | 适用场景 |
|------|-------------|-------------|----------|
| **SpinLock** | 13.64 | 100.07 | 短临界区 (< 100 指令) |
| **Mutex (pthread)** | 23.18 | 130.09 | 通用场景 |
| **Mutex (futex)** | 27.42 | 330.30 | 自定义需求 |

## 三段式等待策略

所有 `ITryLock` 实现都支持三段式等待策略，可通过 `ITryLockTuning` 接口配置：

```pascal
// 获取可调参数
var
  Tuning: ITryLockTuning;
begin
  Tuning := M as ITryLockTuning;

  // Phase 1: 紧密自旋 (默认 2000 次)
  Tuning.TightSpin := 2000;

  // Phase 2: 退避自旋 (默认 50 次)
  Tuning.BackOffSpin := 50;
  Tuning.BackOffYieldIntervalSpin := 8191;  // 每 8192 次 yield

  // Phase 3: 阻塞等待 (默认 1000 次)
  Tuning.BlockSpin := 1000;
  Tuning.BlockSleepIntervalMs := 1;  // 指数退避: 1ms → 32ms
end;
```

## 运行基准测试

```bash
# 编译
/home/dtamade/freePascal/lazarus/lazbuild \
  tests/fafafa.core.sync.benchmark/benchmark_mutex_impl.lpi \
  --build-mode=Release

# 运行
./tests/fafafa.core.sync.benchmark/bin/benchmark_mutex_impl
```

## 版本历史

- **2025-12-24**: 首次发布，pthread vs futex 对比测试
