# 2026-04-09 L0 Mainline Merge Checklist

> 这是 strict non-SIMD L0 并回主线前的 dated checklist。
> 当前 L0 的长期边界和推进顺序仍以 `docs/ARCHITECTURE_LAYERS.md`、`docs/fafafa.core.l0.foundation.md` 和 `docs/fafafa.core.l0.roadmap.md` 为准；本页只回答“真正合并到主线前，现在该怎么做”。

## 先看结论

当前 L0 worktree 已经具备独立 merge candidate 的形态，但不适合直接在根 `main` 工作树上做最终合并。

原因有三条：

- 根工作树当前是用户脏状态
- 根 `main` 当前相对 `origin/main` 是 `ahead 2, behind 38`
- 当前 L0 分支不只有 strict L0 语义提交，还带着一段 runner / archive / hygiene 提交，需要明确决定是整段合并还是只摘取 strict L0 核心序列
- 用户已经明确要求当前仓库只保留一个 `simd` worktree 和一个 `L0` worktree，所以不要再新增第三个 integration worktree

## 当前执行面

- 当前 L0 worktree：`/home/dtamade/projects/fafafa.core/.claude/worktrees/l0-main-promotion-20260407`
- 当前 integration branch：`l0-mainline-integration-20260409`
- 当前建议保存的源分支 tip：`l0-mainline-closeout-20260409`
- 当前 L0 HEAD：执行本清单前请用 `git rev-parse --short HEAD` 重新确认
- 当前 L0 分叉点：`d5187ea4`（`merge-base HEAD origin/main`）

## 当前验证状态

以下结果已经在当前 integration branch 上 fresh 执行：

Run:

```bash
bash tests/test_windows_lazbuild_bootstrap.sh
bash tests/test_windows_strict_l0_batch_runtime_matrix.sh
bash tests/test_windows_strict_l0_batch_native_matrix_contract.sh
bash tests/test_windows_strict_l0_native_evidence_contract.sh
bash tests/test_windows_strict_l0_native_evidence_gh_contract.sh
bash tests/test_windows_strict_l0_native_evidence_shell_verifier_contract.sh
bash tests/test_windows_strict_l0_native_closeout_3cmd_contract.sh
bash tests/test_windows_strict_l0_native_closeout_stack.sh
bash tests/test_windows_lazbuild_smoke_preflight_contract.sh
STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.span fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation fafafa.core.platform
git diff --check
```

当前结果：

- Windows `lazbuild` bootstrap contract：PASS
- strict L0 Windows `.bat` runtime-only parity matrix：PASS
- strict L0 Windows native `.bat` matrix driver contract：PASS
- strict L0 Windows native evidence collector / verifier / workflow contract：PASS
- strict L0 Windows native evidence GitHub Actions helper contract：PASS
- strict L0 Windows native evidence shell verifier contract：PASS
- strict L0 Windows native closeout 3cmd helper contract：PASS
- strict L0 Windows native closeout stack：PASS
- Windows smoke preflight recovery guidance contract：PASS
- strict L0 聚合 gate：PASS，`11/11`
- `git diff --check`：PASS

另外一条还没有在当前 Linux 环境里变成“通过”的命令是：

```bash
bash tests/test_windows_lazbuild_smoke_preflight.sh
```

当前结果仍然是预期 fail-close：

- `code=31`
- 含义：当前环境没有真实 Windows `lazbuild.exe`
- 这不再说明仓库内缺脚本；它只说明 dedicated Windows host evidence 还没采

## 先决定要带哪些提交

从 `origin/main` 分叉点到当前 `HEAD`，这条分支包含两类提交：

### A. strict L0 核心提交

这是当前最值得保留为单独 merge slice 的序列；相比早先版本，这里已经把最新的 Windows verification / parity 收尾提交也纳入同一条 strict L0 核心线：

- `b4a33c46` `build(l0): restore lazbuild bootstrap helper`
- `99e077c9` `examples(l0): restore strict l0 entrypoints`
- `a9bbbd93` `l0: admit span2 and refresh control plane`
- `a2096a56` `docs(l0): harden current-state control plane`
- `66642e4e` `test(l0): normalize settings include in test entrypoints`
- `5482fd81` `docs(l0): establish stable roadmap and doc stack`
- `1507274f` `docs(l0): normalize roadmap and module navigation`
- `5b149bfb` `docs(l0): capture module gaps and merge readiness`
- `4fc28464` `docs(l0): add mainline merge checklist`
- `e86430c7` `docs(l0): align merge checklist with single-worktree policy`
- `346fcd44` `docs(l0): record integration branch readiness`
- `14cb0eb5` `docs(l0): record windows smoke blocker`
- `5c2c6e40` `build(l0): add windows lazbuild bootstrap`
- `f8e2a09b` `build(l0): clarify windows lazbuild blocker`
- `597cd2d7` `docs(l0): align audit and merge navigation`
- `c145aa37` `docs(l0): refresh worker verification state`
- `743af329` `test(l0): add windows smoke preflight`
- `2bdbd479` `test(l0): print windows smoke recovery guidance`
- `1c09a01a` `test(l0): add strict windows wine smoke`
- `57faf2ef` `test(l0): add windows batch runtime parity smoke`
- `c168fec7` `docs(l0): align readmes with batch parity smoke`
- `c3e7011e` `test(l0): expand windows batch runtime parity matrix`
- `062aa8e4` `docs(l0): document windows runtime verification paths`

其中：

- `a9bbbd93` 之后这一段是 strict L0 当前边界、测试入口、文档和控制面的核心收口
- `b4a33c46` 与 `99e077c9` 是 supporting fix，主要保证 L0 相关构建入口和示例入口不掉链子
- `5c2c6e40` 到 `062aa8e4` 这一段现在也要和前面的核心 slice 一起看，因为它们已经把 Windows runtime parity、preflight 和文档口径锁进了 strict L0 的收尾流程
- 若在真正切 integration branch 前，当前 L0 branch 又新增了 L0-only 提交，保留保存后的 branch tip，并用范围 cherry-pick 一起带走，不要手工漏拣

### B. 更早的 hygiene / archive / runner 提交

更早一段提交从 `42a5ead7` 到 `05c6110a`，主要是：

- archive / report 清理
- root docs 清理
- example / benchmark / runner 修复
- sync / socket sidecar 漂移清理

这批提交不是 strict L0 语义本身，但部分提交会影响主线的仓库 hygiene 和 runner 行为。

当前推荐做法不是直接无脑整段并入，而是先把 A 段当成主 merge candidate，B 段单独审阅后再决定是否一起带。

## 推荐合并形态

当前推荐优先使用“复用当前 L0 worktree，切到临时 integration branch，再 cherry-pick strict L0 核心提交”，而不是直接把当前 L0 branch merge 到用户脏的根 `main`。

推荐顺序：

1. 先在当前 L0 worktree 记录一个分支名，保住当前 `HEAD`
2. 基于最新 `origin/main` 在同一个 L0 worktree 里切出临时 integration branch
3. 先只 replay A 段 strict L0 核心提交
4. 在 integration branch 重新跑 strict L0 聚合 gate
5. 如果一切通过，再决定是否需要把 B 段 hygiene / runner 提交一并补上

这样做的原因很直接：

- 满足“只保留一个 L0 worktree”的要求
- 不会碰用户脏的根 `main`
- 仍然可以把 strict L0 核心提交和更早的 hygiene 提交分开处理

## 推荐执行步骤

Run:

```bash
git fetch origin
git -C .claude/worktrees/l0-main-promotion-20260407 branch l0-mainline-closeout-20260409 HEAD
git -C .claude/worktrees/l0-main-promotion-20260407 switch -C l0-mainline-integration-20260409 origin/main
git -C .claude/worktrees/l0-main-promotion-20260407 cherry-pick b4a33c46^..l0-mainline-closeout-20260409
```

然后在当前 L0 worktree 的 integration branch 上跑：

```bash
STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.span fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation fafafa.core.platform
git diff --check
```

当前状态：

- 上述 integration branch 已建立
- `bash tests/test_windows_lazbuild_bootstrap.sh` 已 fresh 通过
- strict L0 聚合 gate 已 fresh 通过，`11/11`
- `git diff --check` 已通过
- 当前 fresh 的 Windows 模块级 smoke 已补齐到 runtime 层：最小 `wine` smoke、最小 `.bat` smoke 和扩展后的 `.bat` runtime-only parity matrix 都已有结果

## Windows smoke 建议

当前已经有三条 fresh 的 Windows runtime 复核路径；如果要在当前 Linux + `wine` 环境里复核，优先按下面顺序跑：

```bash
bash tests/test_windows_strict_l0_wine_smoke.sh
bash tests/test_windows_strict_l0_batch_runtime_smoke.sh
bash tests/test_windows_strict_l0_batch_runtime_matrix.sh
```

其中：

- `bash tests/test_windows_strict_l0_wine_smoke.sh`
  - 负责最小 Win64 `.exe` runtime smoke
- `bash tests/test_windows_strict_l0_batch_runtime_smoke.sh`
  - 负责最小 `.bat` runner runtime-only smoke，优先覆盖最早暴露差异的 4 个入口
- `bash tests/test_windows_strict_l0_batch_runtime_matrix.sh`
  - 负责扩展后的 `.bat` runner runtime-only parity matrix，覆盖当前 strict L0 的 12 个 batch 入口

三条路径合起来当前覆盖：

- 最小 Win64 `.exe` runtime smoke：`platform`、`atomic`、`mem.allocator.foundation`、`mem allocator-only`
- 最小 `.bat` runtime-only smoke：`platform`、`atomic`、`mem.allocator.foundation`、`mem allocator-only`
- 扩展 `.bat` runtime-only parity matrix：`base`、`contracts`、`bits`、`layout`、`endian`、`span`、`option`、`result`、`platform`、`atomic`、`mem.allocator.foundation`、`mem allocator-only`

如果你还要专门确认 `.bat` runner 路径，再补下面这条 preflight：

```bash
bash tests/test_windows_lazbuild_smoke_preflight.sh
```

如果你已经拿到 dedicated Windows host，并且 `bash tests/test_windows_lazbuild_smoke_preflight.sh` 的结论也不再提示 `code=31/32` 这一类 toolchain blocker，就直接执行：

```bat
tests\test_windows_strict_l0_batch_native_matrix.bat
```

它会：

- 在真实 Windows `cmd` 下先校验 `tools\lazbuild.bat` 是否找到了 `lazbuild.exe`
- 固定覆盖 strict L0 的 12 个 `.bat` 入口
- 明确拒绝 `FAFAFA_SKIP_BUILD=1`
- 把日志写到 `tests\_windows_batch_native_matrix\`

如果你不只是想“终端上看一眼”，而是要把结果收成标准 artifact，再继续执行：

```bat
tests\collect_windows_strict_l0_native_evidence.bat
tests\verify_windows_strict_l0_native_evidence.bat tests\_windows_l0_native_evidence\<batch-id>
```

如果你要走 hosted/manual workflow 入口，则使用：

- `.github/workflows/l0-windows-native-evidence.yml`

详细 runbook 见：

- `docs/plans/2026-04-09-l0-native-windows-matrix-runbook.md`

如果你手里有真实 Windows `lazbuild.exe`，确认 preflight 通过后，再跑：

```bat
tests\fafafa.core.atomic\BuildOrTest.bat test
tests\fafafa.core.platform\BuildOrTest.bat test
tests\fafafa.core.mem.allocator.foundation\BuildOrTest.bat test
tests\fafafa.core.mem\BuildOrTest.bat test
```

原因：

- `atomic` 是最敏感的低层 contract 之一
- `platform` 是这轮新进入 strict L0 的静态表达层
- `mem` / `mem.allocator.foundation` 之前最容易暴露 `.bat` runtime 路径与 shell 路径之间的 runner 差异

当前已知情况：

- `bash tests/test_windows_strict_l0_wine_smoke.sh`
  - 结果：PASS
  - 明细：`platform` `5/5`、`atomic` `86/86`、`mem.allocator.foundation` `6/6`、`mem allocator-only` `13/13`
- `bash tests/test_windows_strict_l0_batch_runtime_smoke.sh`
  - 结果：PASS
  - 明细：`platform`、`atomic`、`mem.allocator.foundation`、`mem allocator-only` 的 `.bat` runtime-only parity 已在 `FAFAFA_SKIP_BUILD=1` 下 fresh 通过
- `bash tests/test_windows_strict_l0_batch_runtime_matrix.sh`
  - 结果：PASS
  - 明细：`base`、`contracts`、`bits`、`layout`、`endian`、`span`、`option`、`result`、`platform`、`atomic`、`mem.allocator.foundation`、`mem allocator-only` 的 `.bat` runtime-only parity 已在 `FAFAFA_SKIP_BUILD=1` 下 fresh 通过
- `bash tests/test_windows_lazbuild_bootstrap.sh`
  - 结果：PASS；`tools/lazbuild.bat` 已存在，且在 `wine cmd /c` 下可进入 bootstrap 逻辑
- `bash tests/test_windows_lazbuild_smoke_preflight.sh`
  - 结果：当前环境预期 FAIL，`code=31`
  - 含义：`wine` 环境里没有可供 `.bat` runner 使用的 Windows `lazbuild.exe`
  - 当前输出会直接给出 `set LAZBUILD_EXE=C:\Lazarus\lazbuild.exe` 这类恢复命令，便于后续同学接手
- `bash tests/test_windows_strict_l0_batch_native_matrix_contract.sh`
  - 结果：PASS；native Windows 12 模块 matrix driver 已在仓库内接好，且在当前 `wine` 环境下会对缺少 `lazbuild.exe` 的情况 fail-close
- `bash tests/test_windows_strict_l0_native_evidence_contract.sh`
  - 结果：PASS；native evidence collector、verifier 和 workflow 入口已接好，且当前 `wine` 环境下 collector 会对缺少 `lazbuild.exe` 的情况 fail-close
- `bash tests/test_windows_strict_l0_native_evidence_gh_contract.sh`
  - 结果：PASS；Linux/macOS 侧的 GH preflight / dispatch-download helper 已接好，并会在 workflow 未注册到 GitHub default branch 时以 `code=22` fail-close
- `bash tests/test_windows_strict_l0_native_evidence_shell_verifier_contract.sh`
  - 结果：PASS；Linux/macOS 侧的 standalone shell verifier 已接好，并锁定了 CRLF 归一化与 expected commit fail-close 语义
- `bash tests/test_windows_strict_l0_native_closeout_3cmd_contract.sh`
  - 结果：PASS；strict L0 Windows native evidence 的复制即跑 helper 已接好，并锁定了 batch-id 替换、GH 主路径、手工 Windows collector/verifier 路径和 shell verifier 提示
- `bash tests/test_windows_strict_l0_native_closeout_stack.sh`
  - 结果：PASS；当前 strict L0 Windows native closeout 本地可验证项已经统一成单入口，并会同时打印当前 GH preflight 状态
- `bash tests/print_windows_strict_l0_native_closeout_3cmd.sh`
  - 当前用途：给 dedicated Windows host / GH helper 接手人打印 today source-of-truth 命令，避免继续从 runbook 手抄
- `tests\test_windows_strict_l0_batch_native_matrix.bat`
  - 当前状态：脚本已就位，但 fresh 的 dedicated Windows host evidence 仍待补齐
- `tests\collect_windows_strict_l0_native_evidence.bat`
  - 当前状态：evidence 包装入口已就位，但 fresh 的 dedicated Windows host artifact 仍待补齐
- `bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh`
  - 当前状态：helper 已能复用 GH workflow run、下载 artifact，并调用 `verify_windows_strict_l0_native_evidence.sh` 在 Linux shell 上校验 evidence 包结构；如果 workflow 尚未注册到 default branch，则当前预期仍是 fail-close
- 额外验证：若把 `LAZBUILD_EXE` 指到 Unix 路径 `Z:\\opt\\fpcupdeluxe\\lazarus\\lazbuild`，当前 wrapper 会以 `code=126` 明确报错：`LAZBUILD_EXE points to a non-Windows executable`
- 失败原因已经从“缺少 `tools\\lazbuild.bat`”收敛为“当前环境没有可供 `.bat` build-path 使用的 Windows `lazbuild.exe`”
- 因此，这一轮已经可以把“最小 Windows runtime smoke”“最小 `.bat` smoke”“扩展 `.bat` runtime-only parity matrix”“native lane script wiring / fail-close contract”“native evidence artifact wiring”以及“via-GitHub-Actions helper wiring”一起记成完成；当前剩下的是 dedicated Windows host 上的 native `.bat` build-path parity 证据仍依赖外部 Windows Lazarus toolchain

## 当前不要做的事

- 不要直接在根 `main` 工作树上 merge 当前 L0 branch
- 不要把 SIMD worktree 的提交混入这次 L0 主线集成
- 不要在没有新 candidate 审查的前提下顺手再把新模块并入 strict L0
- 不要把 `mem.allocator.foundation`、`atomic.compat` 这类 compat / facade surface 再次写成 strict L0 本体

## 合并放行条件

以下条件全部满足，才适合把这条 L0 线继续往主线推进：

- 当前唯一的 L0 worktree 已切到基于最新 `origin/main` 的 integration branch
- strict L0 核心提交 replay 成功
- strict L0 聚合 gate fresh 通过
- `git diff --check` 通过
- 没有把 SIMD owner 的工作混进来
- Windows smoke 至少完成最小路径，或者明确记录为什么本轮暂不做
- 如果目标是这轮就把 Windows `.bat` build-path parity 也一并收口，则必须在 dedicated Windows host fresh 跑过 `tests\test_windows_strict_l0_batch_native_matrix.bat`

## 当前 blocker

当前 blocker 不是 L0 设计本身，而是主线集成条件：

- 根 `main` 工作树是用户脏状态
- 根 `main` 相对 `origin/main` 落后较多
- 当前 branch 上存在一段不完全等于 strict L0 本体的 hygiene / runner 提交，需要明确是否同批带走
- 当前 Linux 环境虽然有 `wine`，也已经有 `tools\\lazbuild.bat` bootstrap、runtime smoke、runtime-only parity 以及 native lane script wiring；剩余差距是 dedicated Windows host 上仍没有 fresh 采到 native `.bat` build-path evidence

## 相关文档

- `docs/fafafa.core.l0.foundation.md`
- `docs/fafafa.core.l0.roadmap.md`
- `docs/audits/2026-04-09-l0-current-state-audit.md`
- `docs/plans/2026-04-09-l0-native-windows-matrix-runbook.md`
- `docs/plans/2026-04-09-l0-kernel-span2-closeout.md`
- `workers/worker1.md`
