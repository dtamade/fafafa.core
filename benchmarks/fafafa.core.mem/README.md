# fafafa.core.mem 基准测试

本目录用于验证 `fafafa.core.mem` 的内存池/分配器在不同实现与配置下的吞吐量与扩展性。

## 运行（Linux/macOS）

- 一键：`bash benchmarks/fafafa.core.mem/buildAndRun.sh`
- 自定义线程/迭代次数：
  - `bash benchmarks/fafafa.core.mem/buildAndRun.sh --threads=8 --iters=2000000`

## 运行（Windows）

- `benchmarks\fafafa.core.mem\buildAndRun.bat`
- 传参：
  - `benchmarks\fafafa.core.mem\buildAndRun.bat --threads=8 --iters=2000000`

