# 2026-04-09 L0 Current State Audit

## Summary

- 当前 strict non-SIMD L0 的权威边界仍以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准。
- 当前 strict non-SIMD L0 的稳定路线图现在固定为 `docs/fafafa.core.l0.roadmap.md`。
- `fafafa.core.span` 现在正式承载最小只读单段 `span` 与双段 `span2` contract。
- 当前 L0 执行面已经切到当前唯一的 L0 worktree 上的 `l0-mainline-integration-20260409` 分支；如需重放/重建 integration branch，应先把当前 `HEAD` 保存成 `l0-mainline-closeout-20260409` 这一类源分支 tip。
- 原先混入该 worktree 的 sync/fs/socket runner sidecar 已安全转移到临时 branch `l0-sidecar-handoff-20260409`，不再阻塞 strict L0 继续推进。
- 当前没有新的获批 L0 准入候选；“还缺什么”主要是 merge hygiene、跨平台验证一致性和 compat surface 继续收口，而不是再加模块。

## Current L0 Surface

- 基础语义：`settings.inc`、`base`、`contracts`、`option`、`result`
- 视图表达：`span`、`span2`
- 原始数据语义：`bits`、`platform`、`layout`、`endian`
- 内存模型：`atomic.core`、`atomic.base`、`atomic`、`atomic.compat`
- 分配契约：`mem.allocator.base`

## Current Module Map

| 组           | 当前模块                                                                                     | 当前判断                                                                                   |
| ------------ | -------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| 基础语义     | `fafafa.core.base` / `fafafa.core.contracts` / `fafafa.core.option*` / `fafafa.core.result*` | 已稳定，职责清楚，当前重点不是扩 API，而是继续收紧 compat 叙述                             |
| 视图表达     | `fafafa.core.span`                                                                           | 已稳定承载最小 `span` / `span2` 只读 contract，不再等同于 collections `SliceView`          |
| 原始数据语义 | `fafafa.core.bits` / `fafafa.core.platform` / `fafafa.core.layout` / `fafafa.core.endian`    | 已形成独立 L0 组，source-of-truth 和测试入口已收口                                         |
| 内存模型     | `fafafa.core.atomic.core` / `base` / `atomic` / `compat`                                     | 代码面可用，当前主要改进空间在 compat surface 标识和长期波动证据保留                       |
| 分配契约     | `fafafa.core.mem.allocator.base`                                                             | contract 边界清楚；`foundation` 与具体 backend 已明确退回 mem 域低层 facade / backend 语义 |

## What Is Not Missing

如果问题是“L0 还缺少哪些显然应该补进来的模块”，当前答案是：没有。

当前没有任何主题同时满足下面几条：

- 只依赖 RTL 和已确认的 L0 单元
- 不是容器、服务、runtime dispatch、registry 或 policy
- 能被多个上层模块自然复用
- API 面足够小，且长期稳定

所以，L0 现在不缺“下一个应该立刻并入的模块”。继续硬塞新主题，只会重新制造控制面漂移。

## What Is Still Missing

L0 当前真正还缺的是硬化项，而不是模块数：

### 1. Merge hygiene is still a process task

- 当前 L0 worktree 已整理干净，但根 `main` 工作树仍然是用户脏状态。
- 这意味着 L0 本身已经可以作为独立 merge candidate 准备审阅，但实际并回主线前仍需要一个明确的集成窗口。

### 2. Windows `.bat` runner parity is not symmetric yet

- 当前 fresh gate 是在 Linux/macOS shell 路径上完成的。
- 仓库内的 Windows bootstrap 已补齐，并且 `bash tests/test_windows_lazbuild_bootstrap.sh` 已 fresh 通过。
- 当前环境已经能通过 `bash tests/test_windows_strict_l0_wine_smoke.sh` 完成 strict L0 的最小 Windows runtime smoke：`platform`、`atomic`、`mem.allocator.foundation`、`mem allocator-only` 都能先交叉构建成 Win64 `.exe`，再在 `wine` 下运行通过。
- 当前环境现在还可以通过 `bash tests/test_windows_strict_l0_batch_runtime_smoke.sh` 完成最小 `.bat` runner runtime-only smoke：`platform`、`atomic`、`mem.allocator.foundation`、`mem allocator-only` 这 4 个入口会在 `FAFAFA_SKIP_BUILD=1` 下跳过构建、直接消费预构建 Win64 `.exe`，并在 `wine cmd /c` 下运行通过。
- 当前环境还可以通过 `bash tests/test_windows_strict_l0_batch_runtime_matrix.sh` 完成扩展后的 `.bat` runner runtime-only parity matrix：`base`、`contracts`、`bits`、`layout`、`endian`、`span`、`option`、`result`，以及前面的 `platform`、`atomic`、`mem.allocator.foundation`、`mem allocator-only` 现在都能在 `FAFAFA_SKIP_BUILD=1` 下 fresh 通过。
- 仓库内现在还提供 `bash tests/test_windows_lazbuild_smoke_preflight.sh` 作为 Windows `.bat` smoke 前置检查；它会把 `wine` 环境下缺少真实 Windows `lazbuild.exe` 的情况收敛成固定失败码，并直接打印 `LAZBUILD_EXE` 的恢复示例。
- 仓库内现在也已经提供 dedicated Windows host lane：
  - `tests\test_windows_strict_l0_batch_native_matrix.bat`
  - 它会固定覆盖 12 个 strict L0 `.bat` 入口，并明确拒绝 `FAFAFA_SKIP_BUILD=1`
- 仓库内也已经把这条 lane 的 evidence 包装与 hosted/manual workflow 入口接好：
  - `tests\collect_windows_strict_l0_native_evidence.bat`
  - `tests\verify_windows_strict_l0_native_evidence.bat`
  - `.github/workflows/l0-windows-native-evidence.yml`
- 仓库内现在还提供 Linux/macOS 侧的 GH preflight / helper：
  - `bash tests/preflight_windows_strict_l0_native_evidence_gh.sh`
  - `bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh`
  - `bash tests/verify_windows_strict_l0_native_evidence.sh`
  - 它们负责 fail-close 检查 workflow 是否已在 default branch 注册、以及在 artifact 下载后做 shell 侧 contract 校验
- 当前环境还能用 `bash tests/test_windows_strict_l0_batch_native_matrix_contract.sh` 锁死这条 native lane 的脚本 contract 和 fail-close 语义。
- 当前环境还能用 `bash tests/test_windows_strict_l0_native_evidence_contract.sh` 锁死 collector / verifier / workflow 这层 contract 和 fail-close 语义。
- 当前环境还能用 `bash tests/test_windows_strict_l0_native_evidence_gh_contract.sh` 锁死 GH helper 这层 dispatch/download/fail-close contract。
- 当前环境还能用 `bash tests/test_windows_strict_l0_native_evidence_shell_verifier_contract.sh` 锁死 Linux shell verifier 的 artifact contract 与 CRLF 容错语义。
- 当前若 `bash tests/preflight_windows_strict_l0_native_evidence_gh.sh` 返回 `code=22`，表示 workflow 还没有注册到 GitHub default branch；这是当前预期 fail-close，不等于 native parity 已补齐。
- 当前仍然不对称的是 `.bat` build-path 本身；它依旧缺少 fresh 的 dedicated-Windows execution evidence，所以还不能把 native batch build parity 记成完成。
- 因此，Windows runtime smoke、`.bat` runtime-only parity、native lane wiring 和 via-GitHub-Actions helper wiring 已不再是当前 L0 的 blocker；剩下的 confidence gap 只在真实 Windows toolchain 下的 batch build-path parity 证据。

### 3. Compat surface still needs continued discipline

- `atomic.compat` 仍然存在，必须继续被标成 legacy bridge，而不是 today 推荐入口。
- `result` 侧的兼容 API 仍需继续保持“能用但不鼓励扩散”的文档口径。
- `mem.allocator.foundation` 虽然已经退回 mem 域 facade，但后续文档和测试入口仍要持续防止它重新被误读成 strict L0 本体。

### 4. Verification evidence should stay reproducible

- 当前 gate 已通过，但后续若出现新的聚合波动，尤其是 `atomic`，要优先保留失败日志和 testcase 顺序。
- L0 不需要“感觉上稳定”；L0 需要的是能重复拿出证据的稳定性。

## Current Findings

### 1. span2 is now small enough for L0

- 新增的是 read-only segmented view contract，不是 container API。
- 依赖面保持在 RTL + `fafafa.core.base`。
- `collections.slice` 继续保留 Layer 1 的 container `SliceView` 语义。

### 2. atomic/result/mem allocator boundary needed wording cleanup more than code churn

- `atomic.compat` 继续存在，但只能被视作 legacy bridge。
- `AndResult` / `OrResult` 继续存在，但只能被视作 deprecated compatibility API。
- `mem.allocator.foundation` 继续是 mem 域 low-level facade，不回退成 strict L0 source-of-truth。

### 3. Control-plane drift was real

- `workers/worker1.md` 在本轮之前仍携带过多 tail-cleanup / non-L0 historical noise。
- `docs/INDEX.md` 之前曾把 `2026-04-07` rescue 文档当作当前 follow-up 入口；现在已改为稳定的 `foundation + roadmap + audit` 三件套。
- dated closeout 现在只保留批次执行语境，不再继续承担长期路线图职责。

### 4. Quality has room to improve, but it is no longer architecture confusion

当前剩下的提升空间主要是 hygiene 和一致性，不再是“L0 到底是什么”的架构级混乱：

- 继续压缩 compat surface 的误读空间
- 继续减少 mem 测试脚本在不同平台上的行为分叉
- 继续让模块文档、测试 README、worker 控制面和 audit 同步更新
- 保持新候选只能走 candidate-driven admission，而不是靠 dated closeout 偷渡

## Merge Readiness

如果问题是“L0 当前能不能作为一个独立工作面准备合并审阅”，当前答案是：可以。

当前满足：

- 边界已经固定在 `foundation + roadmap + audit`
- strict L0 模块文档和测试 README 已按统一口径收口
- 当前 worktree 已从 sidecar 污染中分离
- 基于 `origin/main` 的 integration branch 已建立
- fresh strict L0 聚合 gate 通过

当前还不应跳过的事情：

- 不要直接在用户脏的根 `main` 工作树上做最终合并动作
- 当前最小 Windows runtime smoke 与 `.bat` runtime-only parity 都已补齐；如果要再给主线更高置信度，剩下的是补真实 Windows `lazbuild.exe` 下的 batch build-path parity
- 在没有新候选审查之前，不要再把更多模块并入 strict L0
- 具体执行单见 `docs/plans/2026-04-09-l0-mainline-merge-checklist.md`，并继续遵守“只保留一个 L0 worktree”的约束

## Verification Snapshot

- `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.span fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation fafafa.core.platform`
- 上述聚合 gate 当前 fresh 结果：PASS，`11/11`
- `git diff --check`：PASS
- 当前执行分支：`l0-mainline-integration-20260409`
- `bash tests/test_windows_lazbuild_bootstrap.sh`
- 结果：PASS；`tools/lazbuild.bat` 已存在，且 `wine cmd /c` 可调用到 bootstrap
- `bash tests/test_windows_strict_l0_wine_smoke.sh`
- 结果：PASS；`platform` `5/5`、`atomic` `86/86`、`mem.allocator.foundation` `6/6`、`mem allocator-only` `13/13`
- `bash tests/test_windows_strict_l0_batch_runtime_smoke.sh`
- 结果：PASS；`platform`、`atomic`、`mem.allocator.foundation`、`mem allocator-only` 的 `.bat` runtime-only parity 已在 `FAFAFA_SKIP_BUILD=1` 下 fresh 通过
- `bash tests/test_windows_strict_l0_batch_runtime_matrix.sh`
- 结果：PASS；`base`、`contracts`、`bits`、`layout`、`endian`、`span`、`option`、`result`、`platform`、`atomic`、`mem.allocator.foundation`、`mem allocator-only` 的 `.bat` runtime-only parity 已在 `FAFAFA_SKIP_BUILD=1` 下 fresh 通过
- `bash tests/test_windows_strict_l0_batch_native_matrix_contract.sh`
- 结果：PASS；native Windows 12 模块 matrix driver 已在仓库内接好，并在当前 `wine` 环境下证明了缺少 `lazbuild.exe` 时会 fail-close
- `bash tests/test_windows_strict_l0_native_evidence_contract.sh`
- 结果：PASS；native evidence collector / verifier / workflow 已在仓库内接好，并在当前 `wine` 环境下证明了缺少 `lazbuild.exe` 时 collector 会 fail-close
- `bash tests/test_windows_lazbuild_smoke_preflight.sh`
- 结果：当前环境预期 FAIL，`code=31`；原因是 `wine` 路径下没有可供 `.bat` runner 使用的 Windows `lazbuild.exe`，但输出已经包含 `set LAZBUILD_EXE=...` 和下一步命令
- `tests\test_windows_strict_l0_batch_native_matrix.bat`
- 结果：脚本已具备 dedicated Windows host 执行条件，但当前仓库内还没有 fresh native host pass 证据
- `tests\collect_windows_strict_l0_native_evidence.bat`
- 结果：collector / artifact 目录格式已具备 dedicated Windows host 执行条件，但当前仓库内还没有 fresh native host artifact
- `wine cmd /c "set LAZBUILD_EXE=Z:\\opt\\fpcupdeluxe\\lazarus\\lazbuild && ... && BuildOrTest.bat build"`
- 结果：wrapper 明确以 `code=126` 报错：`LAZBUILD_EXE points to a non-Windows executable`

## Remaining Risks

- 根 `main` 工作树仍然是用户脏状态，不应拿来直接承载 L0 收口。
- 临时 branch `l0-sidecar-handoff-20260409` 只是 sidecar 交接面，不应再并回当前 L0 实施面。
- SIMD 仍由 SIMD owner 负责；L0 这里只处理边界和非 SIMD contract。
- Windows `.bat` 路径与 shell / cross-build 路径仍不完全对称；当前已补齐 runtime-only parity、native lane wiring 和 evidence artifact wiring，但 native batch build-path parity 还没有 dedicated Windows host pass evidence。
- 当前 Linux 环境虽然有 `wine`，且仓库内已经补齐 `tools/lazbuild.bat` bootstrap 与 `tests\test_windows_strict_l0_batch_native_matrix.bat`，但仍没有 Windows `lazbuild.exe`；因此剩余缺口仍先卡在外部 toolchain 环境层，而不是卡在 strict L0 模块逻辑。
- `atomic` 早先只出现过一次未复现的聚合波动；当前没有足够证据支持生产代码修复，若后续再次出现应优先保留失败日志并锁定具体 testcase 顺序。
