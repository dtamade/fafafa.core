# fafafa.core.fs 性能基准（按需/夜间）

本目录提供文件系统模块的性能基准程序与脚本，默认不作为合并门槛，仅在需要时手动运行，或在夜间/专门回归任务中运行。

## 组成
- perf 程序：`perf_fs_bench.lpr`
- 一键脚本（Windows）：`BuildOrRunPerf.bat`

## 默认场景
- 顺序：64MB 文件，128KB 块，报告 MB/s
- 随机：64MB 文件上 4KB 随机偏移读取 5000 次，报告 ops/s
- 产物在 `bin/`，临时文件默认 `fs_bench.tmp`

## 用法

- 一键构建并运行（Windows）
  ```bat
  tests\fafafa.core.fs\BuildOrRunPerf.bat [path] [fileMB] [seqKB] [rndKB] [samples]
  ```
- 一键构建并运行（Linux）

> 统一入口：建议使用 BuildOrRunPerf.bat 子命令。
> 兼容脚本 BuildOrRunResolvePerf.bat / BuildOrRunPerfAll.bat 已移除，请改用：
> - Resolve：BuildOrRunPerf.bat resolve [root] [iters]
> - Walk：BuildOrRunPerf.bat walk
> - 汇总：BuildOrRunPerf.bat all [root] [iters]

  ```bash
  tests/fafafa.core.fs/BuildOrRunPerf.sh [path] [fileMB] [seqKB] [rndKB] [samples]
  ```

参数说明（均为可选）：
- `path`：临时文件路径（默认 `fs_bench.tmp`）
- `fileMB`：基准文件大小（默认 `64`）
- `seqKB`：顺序读写块大小（默认 `128`）
- `rndKB`：随机读块大小（默认 `4`）
- `samples`：随机读样本数（默认 `5000`）

示例：
```bat
rem 默认参数（Windows）
BuildOrRunPerf.bat

rem 自定义 256MB 文件、256KB 顺序块、8KB 随机块、10000 次随机读（Windows）
BuildOrRunPerf.bat d:\temp\fs_bench.tmp 256 256 8 10000
```

```bash
# 默认参数（Linux）
tests/fafafa.core.fs/BuildOrRunPerf.sh

# 自定义 256MB 文件、256KB 顺序块、8KB 随机块、10000 次随机读（Linux）
tests/fafafa.core.fs/BuildOrRunPerf.sh /tmp/fs_bench.tmp 256 256 8 10000
```

## 结果归档与基线对比

- Windows：`ArchivePerfResult.bat [path] [fileMB] [seqKB] [rndKB] [samples]`
- Linux：`ArchivePerfResult.sh [path] [fileMB] [seqKB] [rndKB] [samples]`
- 产物目录：`tests/fafafa.core.fs/performance-data/`
  - `perf_YYYY-MM-DD_HH-MM-SS.txt`：本次运行日志
  - `latest.txt`：最新运行日志（覆盖）
  - `baseline.txt`：可选，作为对比基线


### 快速对比（Windows）
- 运行：`tests\\fafafa.core.fs\\Compare-Perf.bat [baseline] [latest]`
  - 省略参数时默认：`tests\\fafafa.core.fs\\performance-data\\baseline.txt` 与 `latest.txt`
- 或直接 PowerShell：
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tests/fafafa.core.fs/Compare-Perf.ps1 -BaselinePath tests/fafafa.core.fs/performance-data/baseline.txt -LatestPath tests/fafafa.core.fs/performance-data/latest.txt`
- 输出示例：`结果: 写入=持平; 读取=高; 随机读=低`

建议做法：
- 通常只保存“关键参数”的 baseline（例如默认参数），避免文件过多
- 对比输出关注三行：Sequential write/read、Random read
- 真正评估要多次运行看均值/方差，避免偶发抖动

## 运行频率建议
- 功能/边界测试：每次提交/PR 必跑（见 BuildOrTest.bat）
- 性能基准：按需/夜间运行；不作为合并门槛
  - 建议将关键平台（Windows/Unix）各保存一份“基线”并按月比对趋势
  - 开关对比（可选）：
    - Unix：在 `src/fafafa.core.settings.inc` 启用 `{$DEFINE FS_USE_PREAD}`
    - Windows：`{$DEFINE FS_USE_OVERLAPPED}` 目前仅为句柄标志预研，读写仍同步


## ResolvePathEx vs canonicalize（最佳实践）
- TouchDisk=False（默认推荐）：
  - 仅做规范化 + 绝对化，不触盘；快、无 I/O 干扰
  - 适用：构建路径、UI 展示、日志输出、快速相对转绝对
- TouchDisk=True：
  - 触盘解析真实路径（类似 canonicalize），会跟随符号链接/设备特性；慢、受 I/O 影响
  - 适用：确需最终物理路径、跨卷/链接一致性判断、对比硬链接目标等
- 建议：
  - 热路径下使用 TouchDisk=False；仅在必要处切换 True，并可做目录级短期缓存

### 快速对比脚本
- Windows: tests\fafafa.core.fs\BuildOrRunResolvePerf.bat [root] [iters]
  - 输出: tests\fafafa.core.fs\performance-data\perf_resolve_*.txt 与 perf_resolve_latest.txt
- Linux/macOS: tests/fafafa.core.fs/BuildOrRunResolvePerf.sh [root] [iters]

### Resolve 性能基线对比（新增）
- 批处理：tests\\fafafa.core.fs\\tools\\Compare-Resolve-Perf.bat
  - 用法：
    - `powershell -NoProfile -ExecutionPolicy Bypass -File tests/fafafa.core.fs/Compare-Resolve-Perf.ps1 -BaselinePath tests/fafafa.core.fs/performance-data/perf_resolve_baseline.txt -LatestPath tests/fafafa.core.fs/performance-data/perf_resolve_latest.txt -MaxRegressionPct 25`
  - 说明：从 perf_resolve_bench 写入的 `CSV,ResolvePathEx,...` 行中提取 TouchDisk=False/True 的耗时，按阈值给出 OK/REGRESSION
- Windows 集成：BuildOrRunPerf.bat resolve/all 在存在 `perf_resolve_baseline.txt` 时会自动对比并输出 [WARN]（不影响退出码）



## 快速操作清单（纯批处理）
1) Resolve 专项
   - 运行：tests\\fafafa.core.fs\\BuildOrRunPerf.bat resolve [root] [iters]
   - 查看：tests\\fafafa.core.fs\\performance-data\\perf_resolve_latest.txt
   - 对比：自动对比 perf_resolve_baseline.txt（存在时），或手动运行 tests\\fafafa.core.fs\\tools\\Compare-Resolve-Perf.bat
2) Walk 专项
   - 运行：tests\\fafafa.core.fs\\BuildOrRunWalkPerf.bat
   - 查看：tests\\fafafa.core.fs\\performance-data\\perf_walk_latest.txt
   - 对比：自动对比 perf_walk_baseline.txt（存在时），或手动运行 tests\\fafafa.core.fs\\tools\\Compare-Walk-Perf.bat
3) 汇总（推荐）
   - 运行：tests\\fafafa.core.fs\\BuildOrRunPerf.bat all [root] [iters]
   - 输出：tests\\fafafa.core.fs\\performance-data\\perf_all_latest.txt（包含 CSV 摘要）
4) 更新基线（当认可当前为新基线时）
   - 将 perf_resolve_latest.txt 覆盖到 perf_resolve_baseline.txt
   - 将 perf_walk_latest.txt 覆盖到 perf_walk_baseline.txt


## 注意事项
- 运行前确保有足够磁盘空间（文件大小受 `fileMB` 控制）
- 大样本/大文件会延长时间，日常建议用默认参数进行快速评估
- 结果受磁盘/缓存/防病毒等因素影响，建议多次取均值



## 一键汇总运行
- Windows: tests\\fafafa.core.fs\\BuildOrRunPerf.bat all [root] [iters]
- Linux/macOS: tests/fafafa.core.fs/BuildOrRunPerfAll.sh [root] [iters]
- 输出：tests/fafafa.core.fs/performance-data/perf_all_latest.txt
  - 包含 Resolve 与 Walk 的可读输出与 CSV 摘要
