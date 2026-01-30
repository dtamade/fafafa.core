# fafafa.core.mem Examples

本目录存放 mem 模块的示例与演示程序。门面仅包含基础内存操作与分配器，以及基础池（MemPool/StackPool/SlabPool）。不包含 mmap/共享内存、对象池/环形缓冲等跨域/增强内容。

- 如需对象池/环形缓冲等，请直接 uses 对应单元（例如 fafafa.core.mem.objectPool / ringBuffer）。
- 如需内存映射/共享内存，请使用 fs 子域（例如 fafafa.core.fs.mmap）。

示例清单：
- example_mem.lpr：内存操作、分配器、对齐的基础演示
- example_mem_pool_basic.lpr：MemPool/StackPool/SlabPool 的最小用法
- example_mem_pool_config.lpr：SlabPool 自定义配置、预热与统计（含性能计数输出）

- example_mem_integration_runner.lpr：集成/跨域示例 Runner（仅示例使用，不属于单测）

构建与运行：
- Windows：
  - 单个工程：BuildAndRun.bat [debug|release] [run]
  - 批量构建：Build_examples.bat
- Linux：
  - 单个工程：./BuildAndRun.sh [release] [run]  # 默认 Debug
  - 批量构建：./Build_examples.sh

常见问题（FAQ）：
- TMemPool/TSlabPool 定义了 Free(aPtr: Pointer) 方法，为避免与 TObject.Free 同名冲突，建议在销毁实例时使用 Destroy。
- Unix/Linux 共享内存默认使用 `/dev/shm`；若环境限制导致 `shm_open` 失败，可设置 `FAFAFA_SHM_DIR` 指向可写目录（如 `/tmp`），将自动退化为文件映射实现。

迁移说明：
- 原 tests/fafafa.core.mem/examples 下的演示示例已迁移至此目录或 play/ 目录。
- 与性能/压力/人工验证相关的实验性程序建议放在 play/fafafa.core.mem。



双向跨进程环形缓冲区（mappedRingBuffer v2）：
- 示例工程：example_mapped_ringbuffer_bidir.lpr / example_mapped_ringbuffer_bench.lpr
- 用法：
  - Creator 端：example_mapped_ringbuffer_bidir.exe creator <shared-name> [capacity] [elemSize] [msgCount] [batchSize] [sleepUs]
  - Opener 端： example_mapped_ringbuffer_bidir.exe opener  <shared-name> [ignored ignored] [msgCount] [batchSize] [sleepUs]
  - 一键运行：
    - Windows：Run_mapped_ringbuffer_bidir.bat
    - Linux：  ./Run_mapped_ringbuffer_bidir.sh
- 基准：example_mapped_ringbuffer_bench.lpr（自动输出 CSV 到 bench_out/mrb_bidir_bench.csv）
- 说明：
  - capacity 会在内部规范到 2 的幂；双向布局 AB/BA 两套 ring 共享相同容量
  - 建议先启动 Creator 再启动 Opener；两端共享名必须一致
  - 默认发送 Integer（elemSize=4），可自行调整

性能建议（Performance tips）：
- capacity 选 2 的幂，越大越能减少绕回造成的 cache miss
- elemSize 小而定长；如果必须很大，优先批量发送（提高批次、减少往返）
- 在大吞吐场景下，关闭日志输出；建议独立做性能 run 与功能 run
- Windows 上建议使用 Release 模式；Linux 上注意 CPU 频率调节与电源策略的影响

基准运行与解读：
- 运行：
  - 全矩阵：bin/example_mapped_ringbuffer_bench[.exe] [runs] [warmup]
  - 快速模式：bin/example_mapped_ringbuffer_bench[.exe] quick [runs] [warmup]
    - runs：每组参数运行次数（默认 5）
    - warmup：预热次数（默认 1）
- 输出：bench_out/mrb_bidir_bench.csv（总表）与 bench_out/mrb_bidir_bench_e<elem>.csv（按元素大小分表），字段含平均/中位数/标准差与对应 QPS
- 建议：
  - 固定 CPU 频率、关节能、使用 Release；单机对比时保持环境一致
  - 执行多次取中位数/平均更稳健；关注中位数优先
  - 对大元素（elemSize>=16）提高 batchSize 能显著改善 QPS
绘图（gnuplot 模板与批量脚本）：
- 模板：gnuplot_mrb_qps_vs_batch.plt
- 示例命令（按 elem=4 / capacity=65536 / msg=100000 绘制 QPS 中位数 对 batch 的曲线）：
  gnuplot -e "infile='bench_out/mrb_bidir_bench_e4.csv';outfile='bench_out/plot_qps_vs_batch_e4_cap65536_msg100000.png';elem=4;capacity=65536;msg=100000;metric_col=10" gnuplot_mrb_qps_vs_batch.plt
- metric_col：9=qps_avg，10=qps_median（推荐），11=qps_std（近似差值）

批量出图：
- Windows：examples/fafafa.core.mem/bake_plots.bat（依赖已安装 gnuplot）
- Linux：  examples/fafafa.core.mem/bake_plots.sh（依赖已安装 gnuplot）

更多 gnuplot 模板：
- QPS vs capacity：gnuplot_mrb_qps_vs_capacity.plt
  示例：gnuplot -e "infile='bench_out/mrb_bidir_bench_e4.csv';outfile='bench_out/plot_qps_vs_capacity_e4_batch64_msg100000.png';elem=4;batch=64;msg=100000;metric_col=10" gnuplot_mrb_qps_vs_capacity.plt
- QPS vs msg_count：gnuplot_mrb_qps_vs_msg.plt
  示例：gnuplot -e "infile='bench_out/mrb_bidir_bench_e4.csv';outfile='bench_out/plot_qps_vs_msg_e4_cap65536_batch64.png';elem=4;capacity=65536;batch=64;metric_col=10" gnuplot_mrb_qps_vs_msg.plt


