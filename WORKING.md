# 当前工作状态

## 最后更新

- 时间：2026-01-20
- 当前阶段：Layer 1（`atomic` + `sync.*`）审查 → 任务规划 → 逐模块推进
- 工作方式：主线单 Agent 顺序推进（允许在同一会话内用子任务/子代理并行处理扫描/脚本/文档等子工作；最终合并与决策由主 Agent 统一完成）

## Layer 1 审查摘要（2026-01-20）

### 范围与规模（当前仓库）

- `src/`：Layer1 源码 `106` 个 `.pas`（atomic + sync.*）
- `tests/`：Layer1 测试目录 `46` 个（`tests/fafafa.core.atomic*` + `tests/fafafa.core.sync*`）
- `examples/`：Layer1 示例目录 `13` 个
- `benchmarks/`：Layer1 基准目录 `4` 个（atomic / mutex / namedEvent / spin）
- `docs/`：Layer1 文档文件 `31` 个（`docs/fafafa.core.atomic*` + `docs/fafafa.core.sync*`）

### 关键风险（必须先解决）

**P0：回归不可信 / 漏测 / 自动化阻塞**

- `src/` 存在 `127` 个 `*.o/*.ppu`：违反“源码目录必须保持清洁”（见 `docs/standards/ENGINEERING_STANDARDS.md`）
- Linux/macOS：`tests/run_all_tests.sh` 只发现 `BuildOrTest.sh/BuildAndTest.sh`，而 Layer1 的 sync 子模块测试目录大面积缺 `BuildOrTest.sh`（当前只有 `tests/fafafa.core.atomic` 与 `tests/fafafa.core.sync` 有稳定入口）
- Windows：多处 `BuildOrTest.bat` 含 `pause`，会导致 `tests/run_all_tests.bat` 挂死（例如 `tests/fafafa.core.atomic/BuildOrTest.bat`）
- `tests/fafafa.core.sync.barrier/buildOrTest.sh` 使用 `|| true` 吞掉测试失败（即使补齐发现规则也会假绿）
- `tests/fafafa.core.sync/fafafa.core.sync.mutex.parkinglot/`（嵌套测试目录）与 `tests/fafafa.core.sync.mutex.parkinglot/` 重复，可能被递归发现导致重复执行/冲突
- 多处脚本/工具存在交互阻塞（例如 `clean.sh`、`benchmarks/fafafa.core.atomic/buildAndRun.sh`）

**P1：工程规范不一致（会持续制造返工）**

- Layer1 examples 缺 `BuildOrRun.sh`（当前没有任何目录同时具备 `BuildOrRun.sh` + `BuildOrRun.bat`；多数只有 `.bat` 或缺脚本）（见 `docs/standards/ENGINEERING_STANDARDS.md`）
- `examples/fafafa.core.sync.namedBarrier/` 当前可执行文件直接落在目录根（非 `bin/`），且缺 `lib/<cpu-os>/` 输出配置：需要按工程规范修正
- Layer1 examples 中缺 `.lpi`/工程化入口的目录（需补齐 `.lpi` 或统一脚本入口）：atomic、rwlock、namedMutex、namedSemaphore、namedCondvar
- `examples/fafafa.core.sync.condvar/` 虽有多个子目录 `.lpi`，但顶层缺统一入口脚本且存在零散 `buildOrTest.bat`（命名与用途不匹配）：需要统一为 `BuildOrRun.*`
- Layer1 tests 中缺 `.lpi` 的目录：`16` 个（需要补齐或合并归档）

### 已确认“接口审查项已落地”的点（抽样核对）

- atomic：`atomic_thread_fence/atomic_signal_fence`、CAS 单内存序重载、`atomic_flag`、`atomic_is_lock_free_*` 已在 `src/fafafa.core.atomic.pas` 存在且 `tests/fafafa.core.atomic` 有覆盖
- sync.base：`ILock.TryLockFor` 与 `IGuard.Unlock` 已在 `src/fafafa.core.sync.base.pas` 存在

> 接口审查的来源与详细列表：`docs/layer1/LAYER1_INTERFACE_REVIEW_REPORT.md`

## Layer 1 总体目标（Definition of Done）

- `src/` 中 `*.o/*.ppu` 数量为 `0`
- Linux/macOS：Layer1（atomic + sync.*）测试可被 `tests/run_all_tests.sh` 发现并完整运行，返回码可信（不吞失败、不交互阻塞）
- Windows：`tests/run_all_tests.bat` 可无交互运行（默认不 `pause`，或在 CI 环境自动跳过 `pause`）
- Layer1 examples：每个目录都有 `BuildOrRun.sh` + `BuildOrRun.bat`，且示例项目输出到 `bin/`、中间文件到 `lib/<cpu-os>/`
- Layer1 benchmarks：脚本默认无交互，可产出可复现结果（保存到各自 `results/`）
- 关键语义文档齐全（内存序、虚假唤醒、命名原语权限/命名空间、清理语义等）

## 执行规范（给 Claude Code，用来“防粗心”）

### 硬规则（违反就会返工）

1. **一次只做一个 Task ID**：做到“能编译/能跑/返回码可信”再切下一个。
2. **默认无交互**：脚本不得 `pause/read/ReadLn` 阻塞；若需要交互，必须用显式开关变量（例如 `FAFAFA_INTERACTIVE=1`）才允许。
3. **禁止吞失败**：脚本不得使用 `|| true` 掩盖失败；失败必须反映到退出码（否则 run_all_tests 会假绿）。
4. **输出目录铁律**：所有 `.lpi` 必须输出到 `bin/`（可执行）+ `lib/$(TargetCPU)-$(TargetOS)/`（中间文件），禁止产物落在目录根或 `src/`。
5. **禁止提交构建产物**：`*.o/*.ppu/*.compiled/*.dbg/*.lps/*.rsj`、可执行文件、静态库等都不得出现在 Git 版本控制中。
6. **脚本命名必须精确**：
   - Linux/macOS：只会被 `tests/run_all_tests.sh` 发现的文件名是 `BuildOrTest.sh` 或 `BuildAndTest.sh`（大小写敏感）。
   - Windows：`tests/run_all_tests.bat` 递归执行 `BuildOrTest.bat` 或 `BuildAndTest.bat`（大小写不敏感，但仍建议统一为 `BuildOrTest.bat`）。

### run_all_tests 的真实行为（必须按这个写脚本）

- `tests/run_all_tests.sh`：递归查找所有 `BuildOrTest.sh` / `BuildAndTest.sh`，并以 `bash ./BuildOrTest.sh test` 方式执行（参数来自 `RUN_ACTION`，默认 `test`）。
- `tests/run_all_tests.bat`：递归查找所有 `BuildOrTest.bat` / `BuildAndTest.bat` 并执行。
- 结论：
  - **如果脚本不接受第一个参数也没问题**（会忽略），但建议支持 `check/test` 两种动作。
  - **存在嵌套模块目录会导致重复执行**（递归发现），所以要清理重复/嵌套目录或调整发现策略。

### 统一任务完成检查（每个 Task ID 完成必须做）

- `git diff --name-only`：确认只改了任务范围内的文件
- Linux/macOS：`bash tests/run_all_tests.sh <module>`（至少跑被你改动的模块）
- Windows：确认 `BuildOrTest.bat` 默认不会 `pause` 阻塞（除非显式开关）
- `find src -name '*.o' -o -name '*.ppu' | wc -l`：必须为 `0`

### 快速现状扫描命令（执行 Gate0 前先跑一次）

Linux/macOS（bash）：

```bash
# 1) src 是否被污染
find src -name '*.o' -o -name '*.ppu' | wc -l

# 2) Layer1 tests: 哪些目录缺 BuildOrTest.sh（但有 *.lpi）
find tests -maxdepth 1 -type d \( -name 'fafafa.core.atomic*' -o -name 'fafafa.core.sync*' \) -print | sort | \
while read -r d; do
  has_lpi="$(find "$d" -maxdepth 1 -name '*.lpi' -print -quit)"
  if [ -n "$has_lpi" ] && [ ! -f "$d/BuildOrTest.sh" ] && [ ! -f "$d/BuildAndTest.sh" ]; then
    echo "$d"
  fi
done

# 3) Layer1 tests: 哪些脚本吞失败/交互
rg -n "\\|\\|\\s*true\\b" tests/fafafa.core.atomic* tests/fafafa.core.sync* --glob '*.sh' || true
rg -n "^\\s*(read\\b|pause\\b)" tests/fafafa.core.atomic* tests/fafafa.core.sync* --glob '*.{sh,bat}' || true
```

Windows（PowerShell）：

```powershell
# 1) src 是否被污染
Get-ChildItem -Recurse -Path src -Include *.o,*.ppu | Measure-Object | % Count

# 2) Layer1 tests: pause 阻塞点（只扫 bat）
Select-String -Path tests\\fafafa.core.atomic*\\*.bat, tests\\fafafa.core.sync*\\*.bat -Pattern '^\s*pause\b' -ErrorAction SilentlyContinue
```

### 现状快照（2026-01-20 实扫，用于“对照改动”）

#### Layer1 tests：入口脚本覆盖（按目录）

说明：
- `✅`=存在且可被 run_all_tests 发现（Linux 需要 `BuildOrTest.sh`）
- `改名`=存在但大小写不对（Linux 会漏扫），需要改为标准文件名
- `新增`=目录里已有 `.lpi` 或 `.lpr`，但缺标准入口脚本

| tests 目录 | `.lpi` | `BuildOrTest.sh` | `BuildOrTest.bat` | 下一步动作 |
|---|---:|---:|---:|---|
| `tests/fafafa.core.atomic/` | ✅ | ✅ | ✅ | 去 `pause`（L1-G0-04） |
| `tests/fafafa.core.sync/` | ✅ | ✅ | ✅ | 去 `pause`（L1-G0-04） |
| `tests/fafafa.core.sync.barrier/` | ✅ | 改名 + 去 `|| true` | 改名 | L1-G0-03 + L1-G0-02 |
| `tests/fafafa.core.sync.benchmark/` | ✅ | 新增 | 新增 | L1-G0-02（主 `.lpi` 默认只 build/check） |
| `tests/fafafa.core.sync.builder/` | ✅ | 新增 | 新增 | L1-G0-02 + 修 `.lpi` Target 输出（L1-G0-07） |
| `tests/fafafa.core.sync.builder.extended/` | ✅ | 新增 | 新增 | L1-G0-02 + 修 `.lpi` Target 输出（L1-G0-07） |
| `tests/fafafa.core.sync.condvar/` | ✅ | 新增 | 新增 | L1-G0-02 |
| `tests/fafafa.core.sync.convenience/` | ✅ | 新增 | 新增 | L1-G0-02 + 修 `.lpi` Target 输出（L1-G0-07） |
| `tests/fafafa.core.sync.event/` | ✅ | 新增 | 改名 | L1-G0-02（优先跑单元测试，不跑 crossprocess） |
| `tests/fafafa.core.sync.facade/` | ✅ | 新增 | 新增 | L1-G0-02 + 修 `.lpi` Target 输出（L1-G0-07） |
| `tests/fafafa.core.sync.guard/` | ❌ | 新增 | 新增 | 先补 `.lpi` + 清理已提交可执行文件（L1-G0-05 + L1-G0-07） |
| `tests/fafafa.core.sync.latch/` | ❌ | 新增 | 新增 | 先补 `.lpi` + 清理已提交可执行文件（L1-G0-05 + L1-G0-07） |
| `tests/fafafa.core.sync.lazylock/` | ❌ | 新增 | 新增 | 先补 `.lpi` + 清理已提交可执行文件（L1-G0-05 + L1-G0-07） |
| `tests/fafafa.core.sync.modern_api/` | ✅ | 新增 | 新增 | L1-G0-02 + 修 `.lpi` Target 输出（L1-G0-07） |
| `tests/fafafa.core.sync.mutex/` | ❌ | 新增 | 新增 | 先补 `.lpi`（或并入其他测试）+ 清理已提交可执行文件（L1-G0-05 + L1-G0-07） |
| `tests/fafafa.core.sync.mutex.futex/` | ❌ | 新增 | 新增 | 同上（L1-G0-05 + L1-G0-07） |
| `tests/fafafa.core.sync.mutex.guard/` | ❌ | 新增 | 新增 | 同上（L1-G0-05 + L1-G0-07） |
| `tests/fafafa.core.sync.mutex.guard.raii/` | ✅ | 新增 | 新增 | L1-G0-02 + 修 `.lpi` Target 输出（L1-G0-07） |
| `tests/fafafa.core.sync.mutex.parkinglot/` | ✅ | 改名 | 改名 | L1-G0-02（只改名即可） |
| `tests/fafafa.core.sync.mutex.poison/` | ✅ | 新增 | 新增 | L1-G0-02 + 修 `.lpi` Target 输出（L1-G0-07） |
| `tests/fafafa.core.sync.named/` | ✅ | 新增 | 新增 | L1-G0-02（不要跑崩溃恢复类用例，需显式开关） |
| `tests/fafafa.core.sync.namedBarrier/` | ✅ | 新增 | 改名 | L1-G0-02（默认只跑主测试） |
| `tests/fafafa.core.sync.namedCondvar/` | ✅ | 新增 | 改名 | L1-G0-02（默认不跑 stress/crossprocess） |
| `tests/fafafa.core.sync.namedEvent/` | ✅ | 新增 | 改名 | L1-G0-02（默认不跑 producer/consumer 两进程） |
| `tests/fafafa.core.sync.namedLatch/` | ❌ | 新增 | 新增 | 先补 `.lpi`（L1-G0-05） |
| `tests/fafafa.core.sync.namedMutex/` | ✅ | 新增 | 改名 | L1-G0-02 |
| `tests/fafafa.core.sync.namedOnce/` | ❌ | 新增 | 新增 | 先补 `.lpi`（L1-G0-05） |
| `tests/fafafa.core.sync.namedRWLock/` | ✅ | 新增 | 改名 | L1-G0-02（debug_shm/verify_shm 默认不跑） |
| `tests/fafafa.core.sync.namedSemaphore/` | ✅ | 新增 | 改名 | L1-G0-02 |
| `tests/fafafa.core.sync.namedSharedCounter/` | ❌ | 新增 | 新增 | 先补 `.lpi`（L1-G0-05） |
| `tests/fafafa.core.sync.namedWaitGroup/` | ❌ | 新增 | 新增 | 先补 `.lpi`（L1-G0-05） |
| `tests/fafafa.core.sync.once/` | ✅ | 新增 | 改名 | L1-G0-02（benchmark 默认不跑） |
| `tests/fafafa.core.sync.once.verify/` | ✅ | 新增 | 新增 | L1-G0-02（verify 用例要确保无交互） |
| `tests/fafafa.core.sync.oncelock/` | ❌ | 新增 | 新增 | 先补 `.lpi` + 清理已提交可执行文件（L1-G0-05 + L1-G0-07） |
| `tests/fafafa.core.sync.parker/` | ❌ | 新增 | 新增 | 先补 `.lpi` + 清理已提交可执行文件（L1-G0-05 + L1-G0-07） |
| `tests/fafafa.core.sync.recMutex/` | ✅ | 新增 | 改名 | L1-G0-02（simple_test 默认不跑） |
| `tests/fafafa.core.sync.rwlock/` | ✅ | 新增 | 改名 | L1-G0-02（目录里有大量已提交可执行文件，优先清理） |
| `tests/fafafa.core.sync.rwlock.downgrade/` | ✅ | 新增 | 新增 | L1-G0-02 |
| `tests/fafafa.core.sync.rwlock.guard/` | ❌ | 新增 | 新增 | 先补 `.lpi` + 清理已提交可执行文件（L1-G0-05 + L1-G0-07） |
| `tests/fafafa.core.sync.rwlock.guard.raii/` | ✅ | 新增 | 新增 | L1-G0-02 + 修 `.lpi` Target 输出（L1-G0-07） |
| `tests/fafafa.core.sync.rwlock.maxreaders/` | ❌ | 新增 | 新增 | 先补 `.lpi` + 清理已提交可执行文件（L1-G0-05 + L1-G0-07） |
| `tests/fafafa.core.sync.rwlock.poison/` | ✅ | 新增 | 新增 | L1-G0-02 |
| `tests/fafafa.core.sync.sem/` | ✅ | 新增 | 改名 | L1-G0-02（默认跑 `...sem.test.lpi`，其他 runner 需显式开关） |
| `tests/fafafa.core.sync.spin/` | ✅ | 新增 | 改名 | L1-G0-02 |
| `tests/fafafa.core.sync.timeout/` | ❌ | 新增 | 新增 | 先补 `.lpi`（L1-G0-05） |
| `tests/fafafa.core.sync.waitgroup/` | ❌ | 新增 | 新增 | 先补 `.lpi` + 清理已提交可执行文件（L1-G0-05 + L1-G0-07） |

> 注意：上表“新增/改名”仅描述入口脚本现状，仍需配合 `L1-G0-07` 修 `.lpi` 输出与清理已提交产物，否则会继续污染目录。

#### Layer1 examples：入口脚本覆盖（按目录）

| examples 目录 | `.lpi`（任意层级） | `BuildOrRun.sh` | `BuildOrRun.bat` | 下一步动作 |
|---|---:|---:|---:|---|
| `examples/fafafa.core.atomic/` | ✅（仅 `.lpr`） | 新增 | 新增 | 先补 `.lpi`（可按每个 `.lpr` 生成），并提供统一脚本入口 |
| `examples/fafafa.core.sync/` | ✅ | 新增 | ✅ | 补 `BuildOrRun.sh` + 修 `.lpi` Target 输出（L1-S-00 + L1-G0-07） |
| `examples/fafafa.core.sync.condvar/` | ✅（子目录） | 新增 | 新增 | 提供顶层 `BuildOrRun.*` 统一入口；把子目录 `buildOrTest.bat` 改为示例脚本或弃用 |
| `examples/fafafa.core.sync.event/` | ✅ | 新增 | 新增 | 补齐 `BuildOrRun.*`（默认只运行无交互示例） |
| `examples/fafafa.core.sync.mutex/` | ✅ | 新增 | 新增 | 补齐 `BuildOrRun.*` |
| `examples/fafafa.core.sync.namedBarrier/` | ✅ | 新增 | ✅ | 修 `.lpi` Target 输出 + 移除已提交可执行文件 + 补 `BuildOrRun.sh` |
| `examples/fafafa.core.sync.namedCondvar/` | ✅（仅 `.pas`） | 新增 | 新增 | 先把 `.pas` 做成可运行 `.lpi/.lpr`（或补 runner），再补 `BuildOrRun.*` |
| `examples/fafafa.core.sync.namedEvent/` | ✅ | 新增（已有 `BuildAndRun.sh`） | 新增（已有 `BuildAndRun.bat`） | 统一为 `BuildOrRun.*` + 清理已提交可执行文件 + 修 `.lpi` Target 输出 |
| `examples/fafafa.core.sync.namedMutex/` | ✅（仅 `.lpr`） | 新增 | 新增 | 先补 `.lpi`（crossprocess 示例默认不自动运行） |
| `examples/fafafa.core.sync.namedRWLock/` | ✅ | 新增 | 新增 | 补齐 `BuildOrRun.*` |
| `examples/fafafa.core.sync.namedSemaphore/` | ✅（仅 `.lpr`） | 新增 | 新增 | 先补 `.lpi`（crossprocess 示例默认不自动运行） |
| `examples/fafafa.core.sync.rwlock/` | ✅（仅 `.lpr`） | 新增 | 新增 | 先补 `.lpi`，再补 `BuildOrRun.*` |
| `examples/fafafa.core.sync.spin/` | ✅ | 新增 | 新增 | 补齐 `BuildOrRun.*` |

#### `.lpi` 输出异常清单（必须修复）

tests（Target 输出不在 `bin/` 或 UnitOutputDirectory 不规范）：
- `tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.test.lpi`
- `tests/fafafa.core.sync.builder/fafafa.core.sync.builder.test.lpi`
- `tests/fafafa.core.sync.builder.extended/fafafa.core.sync.builder.extended.test.lpi`
- `tests/fafafa.core.sync.convenience/fafafa.core.sync.convenience.test.lpi`
- `tests/fafafa.core.sync.facade/fafafa.core.sync.facade.test.lpi`
- `tests/fafafa.core.sync.modern_api/fafafa.core.sync.modern_api.test.lpi`
- `tests/fafafa.core.sync.mutex.guard.raii/fafafa.core.sync.mutex.guard.raii.test.lpi`
- `tests/fafafa.core.sync.mutex.poison/fafafa.core.sync.mutex.poison.test.lpi`
- `tests/fafafa.core.sync.namedEvent/crossprocess_test_consumer.lpi`
- `tests/fafafa.core.sync.namedEvent/crossprocess_test_producer.lpi`
- `tests/fafafa.core.sync.namedEvent/diagnostic_test.lpi`
- `tests/fafafa.core.sync.namedRWLock/debug_shm.lpi`
- `tests/fafafa.core.sync.namedRWLock/verify_shm.lpi`
- `tests/fafafa.core.sync.recMutex/simple_test.lpi`
- `tests/fafafa.core.sync.rwlock.guard.raii/fafafa.core.sync.rwlock.guard.raii.test.lpi`

examples（Target 输出不在 `bin/`）：
- `examples/fafafa.core.sync/example_autolock.lpi`
- `examples/fafafa.core.sync/example_condvar.lpi`
- `examples/fafafa.core.sync/example_condvar_broadcast.lpi`
- `examples/fafafa.core.sync/example_rwlock.lpi`
- `examples/fafafa.core.sync/example_sem.lpi`
- `examples/fafafa.core.sync/example_smoketest.lpi`
- `examples/fafafa.core.sync/example_sync.lpi`
- `examples/fafafa.core.sync.condvar/barrier/example_multi_thread_coordination.lpi`
- `examples/fafafa.core.sync.condvar/cond_vs_event/example_cond_vs_event.lpi`
- `examples/fafafa.core.sync.condvar/mpmc_queue/example_mpmc_queue.lpi`
- `examples/fafafa.core.sync.condvar/producer_consumer/example_producer_consumer.lpi`
- `examples/fafafa.core.sync.condvar/robust_wait/example_robust_wait.lpi`
- `examples/fafafa.core.sync.condvar/timeout/example_timeout.lpi`
- `examples/fafafa.core.sync.condvar/wait_notify/example_wait_notify.lpi`
- `examples/fafafa.core.sync.namedBarrier/example_basic_usage.lpi`
- `examples/fafafa.core.sync.namedBarrier/example_cross_process.lpi`
- `examples/fafafa.core.sync.namedEvent/example_basic_usage.lpi`

benchmarks（UnitOutputDirectory 不规范或 Target 输出不在 `bin/`）：
- `benchmarks/fafafa.core.atomic/bench_clean_comparison.lpi`
- `benchmarks/fafafa.core.sync.namedEvent/benchmark_performance.lpi`
- `benchmarks/fafafa.core.sync.namedEvent/crossprocess_test.lpi`
- `benchmarks/fafafa.core.sync.namedEvent/stress_test.lpi`

### 脚本与工程模板（复制粘贴，减少 Claude 写错）

#### `BuildOrTest.sh`（tests 模块推荐模板）

> 目标：能被 `tests/run_all_tests.sh` 发现；默认 `test` 时跑测试，`check` 时只编译；退出码可信；不吞失败。

```bash
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

ACTION="${1:-test}" # run_all_tests.sh 默认传 test；也允许 check
PROJECT_LPI="${PROJECT_LPI:-<REPLACE_ME>.lpi}"
TEST_BIN="${TEST_BIN:-bin/<REPLACE_ME>}"

LAZBUILD_BIN="${LAZBUILD:-lazbuild}"

if ! command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
  echo "[ERROR] lazbuild not found in PATH" >&2
  exit 1
fi

# Deterministic outputs (iron rule)
rm -rf ./bin
rm -rf ./lib/*-*/
mkdir -p ./bin ./lib

echo "[BUILD] ${LAZBUILD_BIN} --build-mode=Debug ${PROJECT_LPI}"
"${LAZBUILD_BIN}" --build-mode=Debug "${PROJECT_LPI}"

if [[ "${ACTION}" == "test" || "${ACTION}" == "run" ]]; then
  echo "[RUN] ${TEST_BIN}"
  if [[ -x "${TEST_BIN}" ]]; then
    "${TEST_BIN}" --all --format=plain
  elif [[ -x "${TEST_BIN}.exe" ]]; then
    "${TEST_BIN}.exe" --all --format=plain
  else
    echo "[ERROR] test executable not found: ${TEST_BIN}[.exe]" >&2
    exit 100
  fi
else
  echo "[INFO] build-only mode (${ACTION})"
fi
```

#### `BuildOrTest.bat`（tests 模块推荐模板）

> 目标：能被 `tests/run_all_tests.bat` 发现；默认不 `pause`；退出码可信。

```bat
@echo off
setlocal
cd /d "%~dp0"

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=test"

echo [BUILD] lazbuild --build-mode=Debug *.lpi
lazbuild --build-mode=Debug *.lpi
if errorlevel 1 exit /b 1

if /I "%ACTION%"=="test" (
  for %%f in (bin\*.exe) do (
    echo [RUN] %%f
    "%%f" --all --format=plain
    if errorlevel 1 exit /b 1
  )
)

if "%FAFAFA_INTERACTIVE%"=="1" pause
exit /b 0
```

#### `BuildOrRun.sh`（examples 模块推荐模板）

> 注意：含 cross-process 示例的目录，默认只 `build`，不要默认 `run all`（会挂死/等待另一进程）。

```bash
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

ACTION="${1:-build}" # build|run
TARGET="${2:-all}"   # all|<one>

LAZBUILD_BIN="${LAZBUILD:-lazbuild}"

if ! command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
  echo "[ERROR] lazbuild not found in PATH" >&2
  exit 1
fi

rm -rf ./bin
rm -rf ./lib/*-*/
mkdir -p ./bin ./lib

build_one() {
  local lpi="$1"
  echo "[BUILD] ${LAZBUILD_BIN} --build-mode=Debug ${lpi}"
  "${LAZBUILD_BIN}" --build-mode=Debug "${lpi}"
}

run_one() {
  local exe="$1"
  echo "[RUN] ${exe}"
  "${exe}"
}

case "${TARGET}" in
  all)
    for lpi in ./*.lpi; do
      [ -f "${lpi}" ] || continue
      build_one "${lpi}"
    done
    ;;
  *)
    build_one "${TARGET}.lpi"
    ;;
esac

if [[ "${ACTION}" == "run" ]]; then
  # 默认只运行 bin 下可执行文件；跨进程示例请用 TARGET 指定
  for exe in ./bin/*; do
    [ -x "${exe}" ] || continue
    run_one "${exe}"
  done
fi
```

#### `.lpi` 输出配置片段（必须对齐）

```xml
<Target>
  <Filename Value="bin/<name>"/>
</Target>
<SearchPaths>
  <UnitOutputDirectory Value="lib/$(TargetCPU)-$(TargetOS)"/>
</SearchPaths>
```

### 默认执行矩阵（必须明确，避免 Claude 误跑 stress/crossprocess）

#### tests：每个目录默认跑哪个 `.lpi`

| tests 目录 | 默认 build/run 的主工程 | 备注（默认不跑） |
|---|---|---|
| `tests/fafafa.core.atomic/` | `tests_atomic.lpi` | - |
| `tests/fafafa.core.sync/` | `tests_sync.lpi` | `test_sync_leak.lpi`（按需） |
| `tests/fafafa.core.sync.barrier/` | `fafafa.core.sync.barrier.test.lpi` | - |
| `tests/fafafa.core.sync.benchmark/` | `fafafa.core.sync.benchmark.lpi`（建议 build-only） | `benchmark_*_impl.lpi`（按需） |
| `tests/fafafa.core.sync.builder/` | `fafafa.core.sync.builder.test.lpi` | - |
| `tests/fafafa.core.sync.builder.extended/` | `fafafa.core.sync.builder.extended.test.lpi` | - |
| `tests/fafafa.core.sync.condvar/` | `fafafa.core.sync.condvar.test.lpi` | - |
| `tests/fafafa.core.sync.convenience/` | `fafafa.core.sync.convenience.test.lpi` | - |
| `tests/fafafa.core.sync.event/` | `fafafa.core.sync.event.test.lpi` | - |
| `tests/fafafa.core.sync.facade/` | `fafafa.core.sync.facade.test.lpi` | - |
| `tests/fafafa.core.sync.modern_api/` | `fafafa.core.sync.modern_api.test.lpi` | - |
| `tests/fafafa.core.sync.mutex.guard.raii/` | `fafafa.core.sync.mutex.guard.raii.test.lpi` | - |
| `tests/fafafa.core.sync.mutex.parkinglot/` | `fafafa.core.sync.mutex.parkinglot.test.lpi` | - |
| `tests/fafafa.core.sync.mutex.poison/` | `fafafa.core.sync.mutex.poison.test.lpi` | - |
| `tests/fafafa.core.sync.named/` | `tests_named_boundary.lpi` | crash/robust 场景需显式开关 |
| `tests/fafafa.core.sync.namedBarrier/` | `fafafa.core.sync.namedBarrier.test.lpi` | `*.test.en.lpi`、`*.result.test.lpi`（按需） |
| `tests/fafafa.core.sync.namedCondvar/` | `fafafa.core.sync.namedCondvar.test.lpi` | `stress_test.lpi`、crossprocess 相关（按需） |
| `tests/fafafa.core.sync.namedEvent/` | `fafafa.core.sync.namedEvent.test.lpi` | `crossprocess_*`、`diagnostic_test.lpi`（按需） |
| `tests/fafafa.core.sync.namedMutex/` | `fafafa.core.sync.namedMutex.test.lpi` | - |
| `tests/fafafa.core.sync.namedRWLock/` | `fafafa.core.sync.namedRWLock.test.lpi` | `debug_shm.lpi`、`verify_shm.lpi`（按需） |
| `tests/fafafa.core.sync.namedSemaphore/` | `fafafa.core.sync.namedSemaphore.test.lpi` | - |
| `tests/fafafa.core.sync.once/` | `fafafa.core.sync.once.test.lpi` | `benchmark_once.lpi`（按需） |
| `tests/fafafa.core.sync.once.verify/` | `once_verify.lpi` | - |
| `tests/fafafa.core.sync.recMutex/` | `fafafa.core.sync.recMutex.test.lpi` | `simple_test.lpi`（按需） |
| `tests/fafafa.core.sync.rwlock/` | `fafafa.core.sync.rwlock.test.lpi` | `benchmark_rwlock.lpi`、debug_*（按需） |
| `tests/fafafa.core.sync.rwlock.downgrade/` | `fafafa.core.sync.rwlock.downgrade.test.lpi` | - |
| `tests/fafafa.core.sync.rwlock.guard.raii/` | `fafafa.core.sync.rwlock.guard.raii.test.lpi` | - |
| `tests/fafafa.core.sync.rwlock.poison/` | `fafafa.core.sync.rwlock.poison.test.lpi` | - |
| `tests/fafafa.core.sync.sem/` | `fafafa.core.sync.sem.test.lpi` | `*.benchmark.lpi`、runner/diagnostic（按需） |
| `tests/fafafa.core.sync.spin/` | `fafafa.core.sync.spin.test.lpi` | - |

> 说明：缺 `.lpi` 的目录先走 `L1-G0-05` 补齐，再把它加入上表。

#### examples：默认运行策略（避免 cross-process 卡死）

| examples 目录 | 默认行为 | 安全默认运行项（建议） | 需要显式运行的项 |
|---|---|---|---|
| `examples/fafafa.core.atomic/` | build only（先工程化） | - | 多线程示例（按需） |
| `examples/fafafa.core.sync/` | build all | `example_smoketest` | 其他按需 |
| `examples/fafafa.core.sync.condvar/` | build only | - | 选择子目录工程显式运行 |
| `examples/fafafa.core.sync.event/` | build all + run 1 | `example_basic_usage` | producer_consumer（按需） |
| `examples/fafafa.core.sync.mutex/` | build all + run 1 | `example_basic_usage` | advanced_patterns（按需） |
| `examples/fafafa.core.sync.namedCondvar/` | build only（先工程化） | - | （待补齐可运行工程） |
| `examples/fafafa.core.sync.spin/` | build all + run 1 | `example_basic_usage` | use_cases（按需） |
| `examples/fafafa.core.sync.namedBarrier/` | build all + run 1 | `example_basic_usage` | `example_cross_process`（需要两个进程） |
| `examples/fafafa.core.sync.namedEvent/` | build all + run 1 | `example_basic_usage` | （如后续补 crossprocess，则显式运行） |
| `examples/fafafa.core.sync.namedMutex/` | build only | - | crossprocess 示例（需要两个进程） |
| `examples/fafafa.core.sync.namedRWLock/` | build all + run 1 | `example_basic_usage` | - |
| `examples/fafafa.core.sync.namedSemaphore/` | build only | - | crossprocess 示例（需要两个进程） |
| `examples/fafafa.core.sync.rwlock/` | build only（先工程化） | - | performance 示例（按需） |

## Layer 1 开发任务清单（单 Agent，按 Gate 顺序执行）

### Gate 0：让工程与回归链“可信”（P0）

**L1-G0-00：生成"现状清单"（必须先做）**
- 目标：让后续改动可验证、可复盘；避免"计划与现实不一致"
- 输出：把关键扫描结果直接回写到本文件（本节下面即可），包括：
  - `src` 的 `*.o/*.ppu` 数量与路径样例
  - Layer1 tests/examples/benchmarks 的 `.lpi` 输出异常列表
  - Layer1 tests 缺 `BuildOrTest.sh` 的目录列表（按"改名/新增"分类）

#### 现状清单扫描结果（2026-01-21）

**1. src/ 目录产物污染情况**
- 数量：`0` 个 .o/.ppu 文件
- 状态：✅ **已清洁**（与 WORKING.md 记录的 127 个不符，说明已被清理）
- 结论：L1-G0-01 任务可能已完成或不需要执行

**2. Layer1 tests 缺 BuildOrTest.bat 的目录（有 .sh 但缺 .bat）**
共 20 个目录需要补齐 BuildOrTest.bat：
- tests/fafafa.core.sync.benchmark
- tests/fafafa.core.sync.builder
- tests/fafafa.core.sync.builder.extended
- tests/fafafa.core.sync.condvar
- tests/fafafa.core.sync.convenience
- tests/fafafa.core.sync.event
- tests/fafafa.core.sync.facade
- tests/fafafa.core.sync.modern_api
- tests/fafafa.core.sync.mutex.guard.raii
- tests/fafafa.core.sync.mutex.parkinglot
- tests/fafafa.core.sync.mutex.poison
- tests/fafafa.core.sync.named
- tests/fafafa.core.sync.namedBarrier
- tests/fafafa.core.sync.namedCondvar
- tests/fafafa.core.sync.namedEvent
- tests/fafafa.core.sync.namedMutex
- tests/fafafa.core.sync.namedRWLock
- tests/fafafa.core.sync.namedSemaphore
- tests/fafafa.core.sync.once.verify
- tests/fafafa.core.sync.rwlock

**3. Layer1 examples 缺 BuildOrRun 脚本的目录**
共 2 个目录需要补齐：
- examples/fafafa.core.sync.namedRWLock（缺 .sh 和 .bat）
- examples/fafafa.core.sync.spin（缺 .sh 和 .bat）

**4. 已被 Git 跟踪的构建产物（需清理）**
共 9 个 .rsj 文件：
- tests/fafafa.core.sync.builder/fafafa.core.sync.once.unix.rsj
- tests/fafafa.core.sync.latch/fafafa.core.sync.latch.unix.rsj
- tests/fafafa.core.sync.named/fafafa.core.sync.latch.unix.rsj
- tests/fafafa.core.sync.named/fafafa.core.sync.once.unix.rsj
- tests/fafafa.core.sync.named/fafafa.core.sync.parker.unix.rsj
- tests/fafafa.core.sync.named/fafafa.core.sync.waitgroup.unix.rsj
- tests/fafafa.core.sync.once/fafafa.core.sync.once.unix.rsj
- tests/fafafa.core.sync.parker/fafafa.core.sync.parker.unix.rsj
- tests/fafafa.core.sync.waitgroup/fafafa.core.sync.waitgroup.unix.rsj

**5. .lpi 输出目录异常（不在 bin/ 的文件）**
tests 目录约 20 个 .lpi 文件输出异常（见上表第 193-210 行）
examples 目录约 20 个 .lpi 文件输出异常（见上表第 212-229 行）

**6. 脚本交互/吞失败问题**
- 吞失败（|| true）：tests/fafafa.core.atomic/VerifyMultiArchDocker.sh（7 处，但这是 Docker 验证脚本，可能是合理的）
- pause 阻塞：tests/fafafa.core.sync/BuildOrTest.bat（已有条件判断，只在非 test/run 模式下 pause）
- 其他 pause：tests/fafafa.core.sync.sem/ 下的辅助脚本（test_minimal.bat、debug_build.bat 等）

**7. 嵌套/重复目录问题**
- tests/fafafa.core.sync.benchmark 目录本身是一个测试目录（不是嵌套问题）

**结论与建议**：
1. ✅ L1-G0-01（清理 src/ 产物）可跳过，已清洁
2. ⚠️ L1-G0-02 需要补齐 20 个 BuildOrTest.bat 文件
3. ⚠️ L1-G0-07 需要清理 9 个 .rsj 文件并修正约 40 个 .lpi 输出配置
4. ⚠️ L1-N-02 需要补齐 2 个示例目录的 BuildOrRun 脚本
5. ✅ L1-G0-04（pause 问题）大部分已解决，只需处理辅助脚本

**L1-G0-01：清理并阻止 `src/` 产物回流**
- 现状：`src/` 有 `*.o/*.ppu`（127 个）
- 工作（强制步骤）：
  1. **确认哪些是 tracked**：`git ls-files src | rg -n \"\\.(o|ppu)$\"`（期望为空）
  2. **列出污染路径**：`find src -name '*.o' -o -name '*.ppu' | sort`
  3. **清理 untracked 产物**：删除这些文件（不要动源码）
  4. **定位根因**：
     - 搜索脚本里是否有 `-FU`/`-FE` 指向 `src/`：`rg -n \"-FU.*src|-FE.*src\" -S tests examples benchmarks tools scripts src || true`
     - 搜索 `.lpi` 是否把 `UnitOutputDirectory` 或 `Target/Filename` 指向了 `src/`：`rg -n \"UnitOutputDirectory\\s+Value=\\\"src|<Filename\\s+Value=\\\"src\" -S . || true`
  5. **验证**：`find src -name '*.o' -o -name '*.ppu' | wc -l` 必须为 `0`

**L1-G0-02：补齐 Layer1 tests 的 Linux 入口脚本（`BuildOrTest.sh`）**
- 目标：`tests/run_all_tests.sh` 能发现并跑完 Layer1 sync 测试
- 方式：优先“就地补齐 wrapper”，用 `lazbuild -B <*.lpi>` 构建并运行输出的测试可执行文件；若目录已存在 `buildOrTest.sh`（小写），直接改名为 `BuildOrTest.sh` 并修正脚本行为
- 关键点：
  - `BuildOrTest.sh` 必须支持 `check/test`（至少支持 `test`），且 **退出码可信**。
  - 若目录内有多份 `.lpi`（含 stress/crossprocess/diagnostic），默认只跑“稳定且无交互”的主测试；扩展测试用显式开关控制。
- 需要补齐 `BuildOrTest.sh`（已有 `.lpi` 但缺脚本的目录）：
  - `tests/fafafa.core.sync.benchmark`
  - `tests/fafafa.core.sync.builder`
  - `tests/fafafa.core.sync.builder.extended`
  - `tests/fafafa.core.sync.condvar`
  - `tests/fafafa.core.sync.convenience`
  - `tests/fafafa.core.sync.event`
  - `tests/fafafa.core.sync.facade`
  - `tests/fafafa.core.sync.modern_api`
  - `tests/fafafa.core.sync.mutex.guard.raii`
  - `tests/fafafa.core.sync.mutex.parkinglot`
  - `tests/fafafa.core.sync.mutex.poison`
  - `tests/fafafa.core.sync.named`
  - `tests/fafafa.core.sync.namedBarrier`
  - `tests/fafafa.core.sync.namedCondvar`
  - `tests/fafafa.core.sync.namedEvent`
  - `tests/fafafa.core.sync.namedMutex`
  - `tests/fafafa.core.sync.namedRWLock`
  - `tests/fafafa.core.sync.namedSemaphore`
  - `tests/fafafa.core.sync.once`
  - `tests/fafafa.core.sync.once.verify`
  - `tests/fafafa.core.sync.recMutex`
  - `tests/fafafa.core.sync.rwlock`
  - `tests/fafafa.core.sync.rwlock.downgrade`
  - `tests/fafafa.core.sync.rwlock.guard.raii`
  - `tests/fafafa.core.sync.rwlock.poison`
  - `tests/fafafa.core.sync.sem`
  - `tests/fafafa.core.sync.spin`

**L1-G0-03：修正“会假绿”的测试脚本**
- `tests/fafafa.core.sync.barrier/buildOrTest.sh`：移除 `|| true`，并改为 `BuildOrTest.sh`（同目录 `buildOrTest.bat` 也应统一为 `BuildOrTest.bat`）

**L1-G0-04：让 Windows 回归可无交互运行**
- 目标：`tests/run_all_tests.bat` 在 CI/自动化下不被 `pause` 卡住
- 做法：为包含 `pause` 的 Layer1 runner 增加条件（例如检测 `CI`/`FAFAFA_CI` 环境变量），或移除末尾 `pause`
- 已发现含 `pause` 的 runner（需处理）：
  - `tests/fafafa.core.atomic/BuildOrTest.bat`
  - `tests/fafafa.core.sync/BuildOrTest.bat`
  - `tests/fafafa.core.sync.namedBarrier/buildOrTest.bat`
  - `tests/fafafa.core.sync.namedCondvar/buildOrTest.bat`
  - `tests/fafafa.core.sync.namedMutex/buildOrTest.bat`
  - `tests/fafafa.core.sync.namedRWLock/buildOrTest.bat`
  - `tests/fafafa.core.sync.namedSemaphore/buildOrTest.bat`
  - `tests/fafafa.core.sync.recMutex/buildOrTest.bat`
  - `tests/fafafa.core.sync.rwlock/buildOrTest.bat`
- 推荐改法（默认不 pause）：
  - 删除 `pause`
  - 或仅在显式开关下 pause：`if "%FAFAFA_INTERACTIVE%"=="1" pause`

**L1-G0-05：补齐 Layer1 tests 中缺 `.lpi` 的目录（或合并归档）**
- 目录（当前无 `.lpi`）：  
  `tests/fafafa.core.sync.guard`、`tests/fafafa.core.sync.latch`、`tests/fafafa.core.sync.lazylock`、`tests/fafafa.core.sync.mutex`、`tests/fafafa.core.sync.mutex.futex`、`tests/fafafa.core.sync.mutex.guard`、`tests/fafafa.core.sync.namedLatch`、`tests/fafafa.core.sync.namedOnce`、`tests/fafafa.core.sync.namedSharedCounter`、`tests/fafafa.core.sync.namedWaitGroup`、`tests/fafafa.core.sync.oncelock`、`tests/fafafa.core.sync.parker`、`tests/fafafa.core.sync.rwlock.guard`、`tests/fafafa.core.sync.rwlock.maxreaders`、`tests/fafafa.core.sync.timeout`、`tests/fafafa.core.sync.waitgroup`
- 选择其一：
  - A) 为每个目录补齐 `*.test.lpi` + `BuildOrTest.*`
  - B) 将测试合并到已有测试目录（例如 `tests/fafafa.core.sync.rwlock` 等），并删除/归档空壳目录
- 建议（更稳）：**优先 A**（补齐 `.lpi` + 脚本），因为 B 需要理解测试组织与发现逻辑，Claude 容易合并错位置。

**L1-G0-06：清理 Layer1 测试目录“重复/嵌套模块”**
- 目标：让 `tests/run_all_tests.*` 发现路径稳定、避免同一模块被多次执行
- 现状：`tests/fafafa.core.sync/fafafa.core.sync.mutex.parkinglot/` 与顶层模块目录重复
- 工作：决定保留顶层 `tests/fafafa.core.sync.mutex.parkinglot/`，并移除/归档嵌套目录（或明确它是集成测试的一部分并调整发现规则）

**L1-G0-07：对齐 Layer1 的 `.lpi` 输出目录，并清理已提交构建产物**
- 目标：所有 Layer1 tests/examples/benchmarks 的 `.lpi` 都输出到 `bin/`，中间文件输出到 `lib/$(TargetCPU)-$(TargetOS)/`（不污染 `src/`，也不把可执行文件落在目录根）
- 现状：`examples/fafafa.core.sync.namedBarrier/` 存在“目录根可执行文件”（不应提交，也不应作为输出路径）
- 工作（强制步骤）：
  1. **找出 Layer1 下已被 Git 跟踪的产物**（必须清掉）：
     - `git ls-files | rg -n \"^(tests|examples|benchmarks)/(fafafa\\.core\\.(atomic|sync))\" | rg -n \"\\.(o|ppu|compiled|dbg|lps|rsj|a)$\"`
     - 同时留意：目录根的无扩展名/`.test` 可执行文件（例如 `fafafa.core.sync.latch.test`）
  2. **逐个确认是否为源码**：
     - `.lps/.compiled/.dbg/.rsj/.o/.ppu/.a` 一律视为产物 → `git rm`
     - `.res`：先确认是否被 `{$R *.res}` 引用；未引用的可以删除，但不要盲删
  3. **修 `.lpi`**：
     - `<Target><Filename Value=\"bin/<name>\"/></Target>`
     - `<SearchPaths><UnitOutputDirectory Value=\"lib/$(TargetCPU)-$(TargetOS)\"/></SearchPaths>`
  4. **验证**：构建后产物只出现在 `bin/` 与 `lib/<cpu-os>/`，目录根保持干净

**L1-G0-08：全面扫描并消除脚本的交互/吞失败**
- 范围：`tests/`、`examples/`、`benchmarks/` 的 `*.sh/*.bat`
- 要求：默认无交互（避免 `pause/read`），禁止 `|| true` 吞失败；必要时用环境变量显式开启交互模式

**L1-G0-09：补齐 `.gitignore`（防止产物回流）**
- 目标：清理完已提交产物后，确保常见产物不会再次被加入版本控制
- 建议至少覆盖：
  - Lazarus 会话：`*.lps`
  - 资源/中间输出：`*.rsj`（如存在）
  - 其他平台产物（按需）：`*.a`
- 验证：清理后重新构建/运行测试，`git status --porcelain` 不应出现这些产物

### Gate 1：Atomic 模块（P1）

**L1-A-01：性能基线与脚本无交互**
- 让 `benchmarks/fafafa.core.atomic/buildAndRun.*` 默认不 `read/pause`，并固定输出到 `benchmarks/fafafa.core.atomic/results/`
- 跑 3 次取中位数，记录 Load/Store 等关键指标到 `workings/`（避免在根目录落日志）

**L1-A-02：示例工程化**
- 为 `examples/fafafa.core.atomic` 补齐 `.lpi`（可拆为多个 example 项目或一个合集项目）
- 补齐 `BuildOrRun.sh` + `BuildOrRun.bat`，并按工程规范输出到 `bin/`、`lib/<cpu-os>/`

### Gate 2：Sync 模块（P1）

**L1-S-00：Sync 示例总目录脚本补齐**
- `examples/fafafa.core.sync`：补齐 `BuildOrRun.sh`，并对齐所有示例 `.lpi` 的输出目录（`bin/` + `lib/$(TargetCPU)-$(TargetOS)/`）

**L1-S-01：先把 sync 核心原语跑进回归链**
- 优先顺序建议：`mutex` → `rwlock` → `condvar` → `sem` → `barrier` → `event` → `spin` → `once/oncelock/lazylock` → 其他
- 目标：每个原语至少有一个稳定的 `BuildOrTest.sh` 跑通（能被 `tests/run_all_tests.sh` 发现）

**L1-S-02：Mutex / ParkingLot**
- 确认 Poison 语义与测试覆盖
- `tests/fafafa.core.sync.mutex.parkinglot`：脚本命名统一为 `BuildOrTest.*` 并纳入回归
- 跑 `benchmarks/fafafa.core.sync.mutex`，输出结果固定落 `results/`

**L1-S-03：RWLock**
- 对齐公平性选项与文档（`docs/fafafa.core.sync.rwlock.md` / `docs/fafafa.core.sync.rwlock.IMPLEMENTATION_SUMMARY.md`）
- 清理/修正 tests 目录内遗留可执行文件，保证产物落 `bin/`

**L1-S-04：CondVar**
- 文档补齐“虚假唤醒（spurious wakeup）”与正确用法示例
- 示例目录 `examples/fafafa.core.sync.condvar` 补齐 `.lpi` 与 `BuildOrRun.*`

**L1-S-05：Semaphore（sem）**
- 补齐/接入 `tests/fafafa.core.sync.sem` 的 `BuildOrTest.sh`，确保能被 `run_all_tests.sh` 发现并正确返回失败码
- 复核 `docs/fafafa.core.sync.sem.md` 与测试行为一致（超时/计数边界/异常路径）

**L1-S-06：Barrier**
- `tests/fafafa.core.sync.barrier`：脚本命名统一 + 不吞失败（Gate0 已列，但这里要在跑进回归后复核压力测试/HeapTrc）
- 复核“可重用/代际（generation）”语义与文档一致（`src/fafafa.core.sync.barrier.base.pas`）

**L1-S-07：Event**
- `tests/fafafa.core.sync.event`：补齐 `BuildOrTest.sh`（当前只有 `build.sh`）
- `examples/fafafa.core.sync.event`：补齐 `BuildOrRun.sh` + `BuildOrRun.bat`

**L1-S-08：Spin**
- 接入 `tests/fafafa.core.sync.spin` 的 `BuildOrTest.sh`
- 评估是否需要“可配置自旋次数/退避策略”公开选项（若不做，至少补齐文档说明内部策略）
- 跑 `benchmarks/fafafa.core.sync.spin`（固定输出到 `results/`）

**L1-S-09：Once / OnceLock / LazyLock**
- 接入 `tests/fafafa.core.sync.once`、`tests/fafafa.core.sync.oncelock`、`tests/fafafa.core.sync.lazylock`（其中后两者目前缺 `.lpi`：先补齐或合并）
- 复核 Poison/错误传播语义与文档一致（避免“吞异常/沉默失败”）

**L1-S-10：Latch / WaitGroup**
- `tests/fafafa.core.sync.latch`、`tests/fafafa.core.sync.waitgroup`：补齐 `.lpi` + `BuildOrTest.*`（或合并到已有测试目录）
- 复核超时、重复使用、边界条件（count=0 / 多次 Done / 过量 Done）并补齐文档

**L1-S-11：Parker / Timeout**
- `tests/fafafa.core.sync.parker`、`tests/fafafa.core.sync.timeout`：补齐 `.lpi` + `BuildOrTest.*`（或合并归档）
- 明确“平台差异/精度/假唤醒/时钟来源”在文档中的约束

**L1-S-12：recMutex / Guard（RAII）**
- `tests/fafafa.core.sync.recMutex`、`tests/fafafa.core.sync.guard`：补齐/标准化 Linux 入口脚本与工程输出目录
- 在文档中补齐“RAII 守卫的正确释放姿势 + 避免交叉释放/重复释放”的示例

### Gate 3：Sync.named（P2）

**L1-N-01：命名原语的 Unix 权限/命名空间/清理语义文档**
- 覆盖：NamedMutex / NamedRWLock / NamedSemaphore / NamedEvent / NamedBarrier / NamedCondVar 等
- 目标：把“可移植性限制、权限模型、命名冲突策略、资源回收”写清楚，并在对应 doc 中可检索

**L1-N-02：示例一键构建补齐**
- 缺 `BuildOrRun.*` 的目录（需补齐）：
  - `examples/fafafa.core.sync.namedBarrier`
  - `examples/fafafa.core.sync.event`
  - `examples/fafafa.core.sync.mutex`
  - `examples/fafafa.core.sync.namedCondvar`
  - `examples/fafafa.core.sync.namedEvent`
  - `examples/fafafa.core.sync.namedMutex`
  - `examples/fafafa.core.sync.namedRWLock`
  - `examples/fafafa.core.sync.namedSemaphore`
  - `examples/fafafa.core.sync.rwlock`
  - `examples/fafafa.core.sync.spin`

**L1-N-03：命名原语测试接入回归链**
- 为 `tests/fafafa.core.sync.named*` 相关目录补齐 `BuildOrTest.sh`（优先走 `lazbuild -B *.lpi`）
- 在 Linux 上确保能被 `tests/run_all_tests.sh` 发现并可一键回归

### Gate 4：最终集成回归（P0）

**L1-F-01：Layer1 过滤回归**
- Linux/macOS：`STOP_ON_FAIL=1 bash tests/run_all_tests.sh <layer1-modules...>`
- Windows：`set STOP_ON_FAIL=1 && tests\\run_all_tests.bat <layer1-modules...>`

**L1-F-02：全量回归（发布前）**
- Linux/macOS：`bash tests/run_all_tests.sh`
- Windows：`tests\\run_all_tests.bat`

## 进行中的任务（Ready → Doing → Done）

- Ready：从 `L1-G0-00` 开始（先让“现状清单”与回归链可信）
