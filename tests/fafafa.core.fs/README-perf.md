# fafafa.core.fs 性能基准（按需/夜间）

本目录提供文件系统模块的性能基准程序与脚本，默认不作为合并门槛，仅在需要时手动运行，或在夜间/专门回归任务中运行。

## 组成

- perf 程序：
  - `perf_fs_bench.lpr`
  - `perf_resolve_bench.lpr`
  - `perf_walk_bench.lpr`
- Windows 入口：
  - `BuildOrRunPerf.bat`
  - `ArchivePerfResult.bat`
- Linux/macOS 入口：
  - `BuildOrRunPerf.sh`
  - `BuildOrRunResolvePerf.sh`
  - `BuildOrRunPerfAll.sh`
  - `ArchivePerfResult.sh`

## 默认场景

- `perf_fs_bench`：
  - 顺序：64MB 文件，128KB 块，报告 MB/s
  - 随机：64MB 文件上 4KB 随机偏移读取 5000 次，报告 ops/s
- `resolve`：
  - 默认根目录：`tests/fafafa.core.fs/walk_bench_root`
  - 默认迭代数：`1000`
- `walk`：
  - 默认参数：`root=tests/fafafa.core.fs/walk_bench_root depth=3 fanout=4 files=2`

## 用法

### 基础 fs benchmark

- Windows：

```bat
tests\fafafa.core.fs\BuildOrRunPerf.bat [path] [fileMB] [seqKB] [rndKB] [samples]
```

- Linux/macOS：

```bash
bash tests/fafafa.core.fs/BuildOrRunPerf.sh [path] [fileMB] [seqKB] [rndKB] [samples]
```

参数说明（均为可选）：

- `path`：临时文件路径，默认 `fs_bench.tmp`
- `fileMB`：基准文件大小，默认 `64`
- `seqKB`：顺序读写块大小，默认 `128`
- `rndKB`：随机读块大小，默认 `4`
- `samples`：随机读样本数，默认 `5000`

### Linux/macOS 的统一 shell 入口

```bash
bash tests/fafafa.core.fs/BuildOrRunPerf.sh buildonly
bash tests/fafafa.core.fs/BuildOrRunPerf.sh resolve [root] [iters]
bash tests/fafafa.core.fs/BuildOrRunPerf.sh walk [root] [depth] [fanout] [files]
bash tests/fafafa.core.fs/BuildOrRunPerf.sh all [root] [iters] [depth] [fanout] [files]
```

兼容 wrapper 仍保留在 Linux/macOS：

```bash
bash tests/fafafa.core.fs/BuildOrRunResolvePerf.sh [root] [iters]
bash tests/fafafa.core.fs/BuildOrRunPerfAll.sh [root] [iters] [depth] [fanout] [files]
```

说明：

- Windows 侧继续以 `BuildOrRunPerf.bat` 为统一入口。
- Linux/macOS 侧继续保留 `BuildOrRunResolvePerf.sh` / `BuildOrRunPerfAll.sh` 作为薄 wrapper，避免历史调用链断掉。

## 结果归档与产物

- 基础 benchmark 归档：
  - Windows：`ArchivePerfResult.bat [path] [fileMB] [seqKB] [rndKB] [samples]`
  - Linux/macOS：`ArchivePerfResult.sh [path] [fileMB] [seqKB] [rndKB] [samples]`
  - 产物：
    - `tests/fafafa.core.fs/performance-data/perf_YYYY-MM-DD_HH-MM-SS.txt`
    - `tests/fafafa.core.fs/performance-data/latest.txt`
- resolve：
  - `tests/fafafa.core.fs/performance-data/perf_resolve_latest.txt`
  - `tests/fafafa.core.fs/performance-data/perf_resolve_YYYY-MM-DD_HH-MM-SS.txt`
- walk：
  - `tests/fafafa.core.fs/performance-data/perf_walk_latest.txt`
- resolve + walk 汇总：
  - `tests/fafafa.core.fs/performance-data/perf_all_latest.txt`
- 可选基线：
  - `baseline.txt`
  - `perf_resolve_baseline.txt`
  - `perf_walk_baseline.txt`

## 快速操作清单

1. Resolve 专项
   - Windows：`tests\fafafa.core.fs\BuildOrRunPerf.bat resolve [root] [iters]`
   - Linux/macOS：`bash tests/fafafa.core.fs/BuildOrRunResolvePerf.sh [root] [iters]`
   - 查看：`tests/fafafa.core.fs/performance-data/perf_resolve_latest.txt`
2. Walk 专项
   - Windows：`tests\fafafa.core.fs\BuildOrRunWalkPerf.bat`
   - Linux/macOS：`bash tests/fafafa.core.fs/BuildOrRunPerf.sh walk [root] [depth] [fanout] [files]`
   - 查看：`tests/fafafa.core.fs/performance-data/perf_walk_latest.txt`
3. 汇总
   - Windows：`tests\fafafa.core.fs\BuildOrRunPerf.bat all [root] [iters]`
   - Linux/macOS：`bash tests/fafafa.core.fs/BuildOrRunPerfAll.sh [root] [iters] [depth] [fanout] [files]`
   - 查看：`tests/fafafa.core.fs/performance-data/perf_all_latest.txt`
4. 基础 fs benchmark 归档
   - Windows：`tests\fafafa.core.fs\ArchivePerfResult.bat`
   - Linux/macOS：`bash tests/fafafa.core.fs/ArchivePerfResult.sh`

## 结果对比

### 基础 benchmark

- Windows：
  - `tests\fafafa.core.fs\Compare-Perf.bat [baseline] [latest]`
  - 或：
    - `powershell -NoProfile -ExecutionPolicy Bypass -File tests/fafafa.core.fs/Compare-Perf.ps1 -BaselinePath tests/fafafa.core.fs/performance-data/baseline.txt -LatestPath tests/fafafa.core.fs/performance-data/latest.txt`

### Resolve / Walk

- Windows：
  - Resolve：`tests\fafafa.core.fs\tools\Compare-Resolve-Perf.bat`
  - Walk：`tests\fafafa.core.fs\tools\Compare-Walk-Perf.bat`
- Linux/macOS：
  - 当前 shell 侧只负责稳定产物与归档，不在 `.sh` wrapper 里内建阈值比较
  - 如需阈值比较，直接对 `perf_resolve_latest.txt` / `perf_walk_latest.txt` 做离线 diff 或复用 PowerShell 工具

## ResolvePathEx vs canonicalize（最佳实践）

- `TouchDisk=False`（默认推荐）
  - 仅做规范化 + 绝对化，不触盘；快、无 I/O 干扰
  - 适用：构建路径、UI 展示、日志输出、快速相对转绝对
- `TouchDisk=True`
  - 触盘解析真实路径（类似 canonicalize），会跟随符号链接/设备特性；慢、受 I/O 影响
  - 适用：确需最终物理路径、跨卷/链接一致性判断、对比硬链接目标等
- 建议
  - 热路径下使用 `TouchDisk=False`
  - 仅在必要处切换 `True`
  - 可按目录做短期缓存，减少重复 realpath

## 运行频率建议

- 功能/边界测试：每次提交/PR 必跑（见 `BuildOrTest.bat` / `BuildOrTest.sh`）
- 性能基准：按需/夜间运行；不作为合并门槛
- 建议将关键平台（Windows / Linux x64）各保存一份 baseline，并按月或按关键变更比对趋势

## 注意事项

- 运行前确保有足够磁盘空间
- 大样本 / 大文件会显著拉长时间
- 结果受磁盘缓存、文件系统、索引服务、防病毒等因素影响，建议多次运行取均值
- 当前 strict L0 tail 的 shell/runner hygiene contract 固定入口：
  - `bash tests/test_active_shell_runners.sh`
  - `bash tests/test_fs_perf_shell_scripts.sh`
