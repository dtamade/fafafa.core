## 测试执行指南（Windows bat / Linux/macOS sh）

本仓库的各子模块在 tests/ 目录下提供独立的测试脚本。为提高可见性与一致性，新增了统一的“全仓测试”脚本，分别适配 Windows 与 Linux/macOS：

- Windows（批处理）：tests/run_all_tests.bat
- Linux/macOS（Shell）：tests/run_all_tests.sh

它们会递归扫描子模块测试脚本并执行，输出各模块日志与最终汇总。

从本轮开始，`run_all_tests.{sh,bat}` 在真正执行模块测试前，还会先做一次 `src/` 源码树 hygiene preflight：

- Linux/macOS：`bash tests/check_repo_hygiene.sh`
- Windows：`tests\check_repo_hygiene.bat`

如果 `src/` 下残留 `.o`、`.ppu`、`.bak` 一类编译/备份产物，统一入口会先失败，避免把生成物噪音带进后续审查和搜索。

---

### 先决条件

- Windows：
  - 安装并能通过命令行调用的 Lazarus/FPC（lazbuild/fpc 在 PATH 上，或通过 tests/tools/lazbuild.bat 间接调用）
  - 适配的目标工具链（x86_64-win64 等），与项目各 tests/\*.lpi 配置一致
- Linux/macOS：
  - 可执行的 sh/bash 环境
  - 对应平台的 FPC/Lazarus 工具链（若运行依赖 .sh 的子模块）

提示：部分测试运行时间较长或涉及 I/O，请在本地机器先用“关键模块”快速回归，再做全量。

---

### strict L0 的 Windows runtime 复核

如果你当前关心的是 strict non-SIMD L0 在 Windows 路径上的复核，不要直接从“原生 `.bat` 构建完全对称”这个前提出发。当前仓库已经分成四条不同的复核链路：

- 最小 Win64 `.exe` runtime smoke
  - Linux/macOS：`bash tests/test_windows_strict_l0_wine_smoke.sh`
- 最小 `.bat` runtime-only smoke
  - Linux/macOS：`bash tests/test_windows_strict_l0_batch_runtime_smoke.sh`
- 扩展 `.bat` runtime-only parity matrix
  - Linux/macOS：`bash tests/test_windows_strict_l0_batch_runtime_matrix.sh`
- native Windows `.bat` build-path parity matrix
  - Windows：`tests\test_windows_strict_l0_batch_native_matrix.bat`

当前建议顺序：

1. 先跑 `bash tests/test_windows_strict_l0_wine_smoke.sh`
2. 再跑 `bash tests/test_windows_strict_l0_batch_runtime_smoke.sh`
3. 最后跑 `bash tests/test_windows_strict_l0_batch_runtime_matrix.sh`
4. 如果要补齐最终 Windows build-path 证据，再到专用 Windows 主机执行 `tests\test_windows_strict_l0_batch_native_matrix.bat`

这三条链路解决的是不同问题：

- `wine_smoke`
  - 确认最小 strict L0 Win64 `.exe` 能交叉构建并在 `wine` 下运行
- `batch_runtime_smoke`
  - 确认最早暴露差异的 4 个 `.bat` 入口在 `FAFAFA_SKIP_BUILD=1` 下能跳过构建并消费预构建 `.exe`
- `batch_runtime_matrix`
  - 确认当前 strict L0 的 12 个 `.bat` 入口都已经具备同样的 runtime-only parity
- `batch_native_matrix`
  - 确认同一组 12 个 `.bat` 入口在真实 Windows `lazbuild.exe` 条件下完成 native build + native test，而不是 runtime-only skip-build

当前 matrix 覆盖：

- `base`
- `contracts`
- `bits`
- `layout`
- `endian`
- `span`
- `option`
- `result`
- `platform`
- `atomic`
- `mem.allocator.foundation`
- `mem allocator-only`

如果你还要确认为什么 native Windows `.bat` build-path 还没有记成完成，再补下面这条 preflight：

- Linux/macOS：`bash tests/test_windows_lazbuild_smoke_preflight.sh`

这条 preflight 的意义不是让当前环境“变绿”，而是把缺少真实 Windows `lazbuild.exe` 的情况收敛成固定失败码和明确恢复命令。也就是说：

- 当前仓库已经完成 Windows runtime smoke 和 `.bat` runtime-only parity
- 当前还没有完成的，是 native Windows `lazbuild.exe` 条件下的 `.bat` build-path parity

如果你已经切到专用 Windows 主机，请直接参考：

- `docs/plans/2026-04-09-l0-native-windows-matrix-runbook.md`

这条 native lane 的约束很严格：

- 它固定覆盖当前 strict L0 的 12 个 `.bat` 入口
- 它不会设置 `FAFAFA_SKIP_BUILD=1`
- 它会先校验 `tools\lazbuild.bat` 是否找到了真实 Windows `lazbuild.exe`
- 只有这条 lane 在真实 Windows 主机 fresh 通过之后，native `.bat` build-path parity 才能记成完成

---

### 快速回归（建议每次提交前）

仅运行常用关键模块，并在第一个失败处停止：

- Windows（推荐）：
  - 在仓库根目录执行：
    - `set STOP_ON_FAIL=1 && tests\run_all_tests.bat fafafa.core.collections`
    - （更快，仅 Vec/VecDeque）：`set STOP_ON_FAIL=1 && tests\run_all_tests.bat fafafa.core.collections.vec fafafa.core.collections.vecdeque`

- Linux/macOS（推荐）：
  - 在仓库根目录执行：
    - `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.collections`
    - （更快，仅 Vec/VecDeque）：`STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.collections.vec fafafa.core.collections.vecdeque`

说明：

- 参数为“模块名”，由 `tests/` 下的**相对目录路径**推导：路径分隔符（`/` 或 `\`）会被转换为 `.`
  - 例：`tests/fafafa.core.json` → `fafafa.core.json`
  - 例：`tests/fafafa.core.collections/vec` → `fafafa.core.collections.vec`
- 过滤兼容：仍支持传入叶子目录名（如 `vec`），以及前缀组过滤（如 `fafafa.core.collections` 会命中 `fafafa.core.collections.*`）
- 环境变量 STOP_ON_FAIL=1 代表“失败即停”，便于快速定位第一个失败点

---

### 全量回归（每日/版本发布前）

- Windows：`tests\run_all_tests.bat`
- Linux/macOS：`bash tests/run_all_tests.sh`

不传参时，脚本会递归扫描并尝试执行所有符合规范的测试脚本：

- Windows：`BuildOrTest.bat` / `BuildAndTest.bat`
- Linux/macOS：`BuildOrTest.sh` / `BuildAndTest.sh`

建议在 CI 或夜间任务中执行全量回归，便于收敛问题。

---

### 输出位置与返回码

- 汇总文件：
  - Windows：`tests/run_all_tests_summary.txt`
  - Linux/macOS：`tests/run_all_tests_summary_sh.txt`
- 日志目录：
  - Windows：`tests/_run_all_logs/*.log`
  - Linux/macOS：`tests/_run_all_logs_sh/*.log`
- 返回码：
  - 0：所有选中模块执行成功
  - 1：存在失败模块（或 STOP_ON_FAIL 触发提前结束）
  - 2：传入了过滤参数，但 0 命中（用于避免“假绿”）

在控制台看不到明细时，请优先查看上述日志与汇总文件。

---

### 过滤与失败即停

- 仅运行指定模块（示例为 4 个关键模块）：
  - Windows：`tests\run_all_tests.bat fafafa.core.collections.vec fafafa.core.collections.vecdeque`
  - Linux/macOS：`bash tests/run_all_tests.sh fafafa.core.collections.vec fafafa.core.collections.vecdeque`
- 失败即停：
  - Windows：`set STOP_ON_FAIL=1 && tests\run_all_tests.bat ...`
  - Linux/macOS：`STOP_ON_FAIL=1 bash tests/run_all_tests.sh ...`

---

### 常见问题（FAQ）

1. 控制台没有输出，但返回码为 0/非 0，如何查看详情？

- 查看汇总与日志：
  - Windows：`tests/run_all_tests_summary.txt`、`tests/_run_all_logs/*.log`
  - Linux/macOS：`tests/run_all_tests_summary_sh.txt`、`tests/_run_all_logs_sh/*.log`

2. 某些测试依赖 lazbuild 路径或工具链，构建失败？

- 确保 Lazarus/FPC 安装完备，并在 PATH 上；或按 tests/\*/BuildOrTest.bat 脚本内的工具路径调整
- 优先在本地先跑单一模块进行定位，例如：
  - `tests\fafafa.core.collections.arr\BuildOrTest.bat`

3. 跑全量太慢？

- 提交前仅跑关键模块（如 `fafafa.core.collections.vec` / `fafafa.core.collections.vecdeque`）
- 夜间/CI 跑全量，或分组并行（在 CI 编排层面并发多个 run_all_tests.sh/bat，分别过滤不同模块）

4. 是否有“测试规范命名”？

- 子模块测试脚本建议采用以下之一：`BuildOrTest.bat` / `BuildAndTest.bat`（Windows），`BuildOrTest.sh` / `BuildAndTest.sh`（Linux/macOS）
- 统一脚本会自动发现并执行上述命名脚本

5. `run_all_tests` 一开始就失败，并提示 `src` hygiene？

- 先直接运行：
  - Linux/macOS：`bash tests/check_repo_hygiene.sh`
  - Windows：`tests\check_repo_hygiene.bat`
- 如果输出列出了 `src/` 下的 `.o` / `.ppu` / `.bak`，先清理这些生成物，再重新执行 `run_all_tests`

---

### 建议的团队约定

- 每次提交前：关键模块 + 失败即停
- 每晚或合入前：全量回归
- 失败模块：提交日志到评审或 CI 附件，提升可复现性
- 新增测试：按规范命名子模块脚本，确保被统一脚本识别

---

### 典型命令速查

- Windows：
  - 关键模块（失败即停）：
    - `set STOP_ON_FAIL=1 && tests\run_all_tests.bat fafafa.core.collections`
  - 全量：
    - `tests\run_all_tests.bat`

- Linux/macOS：
  - 关键模块（失败即停）：
    - `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.collections`
  - 全量：
    - `bash tests/run_all_tests.sh`
