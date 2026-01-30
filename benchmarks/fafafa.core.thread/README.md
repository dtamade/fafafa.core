# fafafa.core.thread Benchmarks

## queue_bench.lpr
- 目的：衡量线程池任务队列（TVecDeque）在不同线程数与队列容量下的吞吐
- 参数通过环境变量设置：
  - BENCH_THREADS（默认 4）
  - BENCH_QUEUE_CAP（默认 1024；-1 表示无限）
  - BENCH_TASKS（默认 50000）
  - BENCH_LOOPS（默认 3）

示例：
```
# Windows PowerShell
$env:BENCH_THREADS=4; $env:BENCH_QUEUE_CAP=1024; $env:BENCH_TASKS=80000; $env:BENCH_LOOPS=3; \
  lazbuild benchmarks/fafafa.core.thread/queue_bench.lpr && benchmarks\fafafa.core.thread\queue_bench.exe

# Bash
BENCH_THREADS=4 BENCH_QUEUE_CAP=1024 BENCH_TASKS=80000 BENCH_LOOPS=3 \
  lazbuild benchmarks/fafafa.core.thread/queue_bench.lpr && ./benchmarks/fafafa.core.thread/queue_bench
```

输出：

## 参数矩阵与 CSV 输出
- 额外参数：
  - BENCH_TASK_MS（默认 0）：每个任务的模拟耗时（毫秒）
  - BENCH_CSV：若设置为文件路径，则将当前参数组写入 CSV（字段：timestamp,threads,queue_cap,task_ms,tasks,loops）
- 若需多组参数矩阵，可在外层脚本循环设置环境变量并调用该基准，最终 CSV 可聚合分析

- 每轮 loop 打印 duration(ms) 与 throughput(tps)，用于横向对比

### 批量运行脚本
- Windows PowerShell: benchmarks/fafafa.core.thread/run_matrix.ps1
- Linux/macOS: benchmarks/fafafa.core.thread/run_matrix.sh
- 可在脚本头部修改线程数/队列容量/任务时长矩阵，脚本会构建并多次运行，将参数组附加写入 CSV


