# 2026-04-10 L0 Windows CI Enablement Checklist

> 这份清单只回答一件事：在当前只有 Linux x64 执行面的前提下，怎样把 strict L0 的 Windows native evidence lane 通过 GitHub Actions 真正打通。
> 它不是新的长期路线图；L0 的长期边界仍以 `docs/fafafa.core.l0.foundation.md` 和 `docs/fafafa.core.l0.roadmap.md` 为准。

## Status

- 状态：`completed`
- 完成提交：`b8adade0` `fix(l0): use run methods for allocator exception tests`
- 真实 Windows evidence：
  - GitHub Actions run `24224880061`
  - `summary.md`：`Result: PASS`
  - `native matrix`：`12/12`
  - 本地快照：`tests/_windows_l0_native_evidence_gh/L0-20260410-native-gha-r9/`

## Goal

- 先把 `.github/workflows/l0-windows-native-evidence.yml` 注册到 default branch `main`
- 再从 Linux x64 触发 Windows CI 收集 strict L0 native evidence
- 最后把下载回来的 artifact 回填到当前 L0 closeout 面

## Outcome

当前这条 enablement 线已经闭环：

- workflow 已在 default branch 可见，GH preflight 不再停在 `WORKFLOW_NOT_FOUND`
- Linux x64 侧的 dispatch/download helper 已经成功触发并回收 artifact
- 真实 Windows runner 上的 `Collect native evidence` / `Verify native evidence` 已通过
- 当前 strict L0 的 Windows native parity 已从“当前 blocker”降级为“已收证完成项”

## Why this was the blocker

当前仓库内的本地 closeout stack 已经具备：

- Windows native matrix driver contract
- native evidence collector / verifier contract
- GH preflight / dispatch-download helper contract
- shell verifier contract

在这条线打通之前，preflight 可能返回：

- `WORKFLOW_NOT_FOUND`
- `code=22`

这说明当时缺的不是 L0 代码逻辑本身，而是：

- L0 本地脚本已经够了
- workflow 还没有在 default branch 注册，导致 Linux x64 无法直接收真实 Windows evidence

## Required slice

不要再把 `c1b77313^..db4527cb` 当成可直接搬到 `origin/main` 的“最小 slice”。
那四个提交只覆盖了 workflow/helper/verifier 的后半段；如果缺少更早的 lazbuild bootstrap、smoke preflight、batch runtime parity 和 native matrix closeout 依赖，注册到 `main` 后也跑不起来。

当前对 `origin/main` 真正可运行的最小依赖链是：

- `5c2c6e40` `build(l0): add windows lazbuild bootstrap`
- `f8e2a09b` `build(l0): clarify windows lazbuild blocker`
- `743af329` `test(l0): add windows smoke preflight`
- `2bdbd479` `test(l0): print windows smoke recovery guidance`
- `1c09a01a` `test(l0): add strict windows wine smoke`
- `57faf2ef` `test(l0): add windows batch runtime parity smoke`
- `c3e7011e` `test(l0): expand windows batch runtime parity matrix`
- `1ca0af89` `test(l0): wire native windows batch closeout lane`
- `c1b77313` `ci(l0): add windows native evidence collector`
- `dd9b7421` `ci(l0): add github actions native evidence helper`
- `0c7dcc96` `test(l0): avoid exec-bit dependency in gh helper`
- `db4527cb` `test(l0): extract shell verifier for native evidence`

为什么需要这 12 个：

- `5c2c6e40` + `f8e2a09b`：先把 Windows lazbuild bootstrap 和 fail-close blocker 说明补齐，否则 native lane 连工具入口都不稳定
- `743af329` + `2bdbd479` + `1c09a01a`：先具备 smoke preflight 与恢复提示，确保 Linux x64 / wine 侧能在 workflow 前把阻塞讲清楚
- `57faf2ef` + `c3e7011e` + `1ca0af89`：补齐 batch runtime parity 和 native matrix closeout lane；这部分是 Windows workflow 真正调用的本地执行面
- `c1b77313` + `dd9b7421` + `0c7dcc96` + `db4527cb`：最后才是 workflow、collector/verifier、GH preflight/helper 与 shell-side artifact verifier 的闭环

下面两条是可选的 operator UX slice，不是 workflow 注册硬依赖：

- `f8eb351c` `test(l0): add native closeout stack runner`
- `08801ab1` `docs(l0): add native evidence handoff helper`

## Command checklist

### 1. 从 `origin/main` 切出一个 CI-only enablement 分支

Run:

```bash
git fetch origin
git switch -C l0-windows-ci-enablement origin/main
git cherry-pick 5c2c6e40 f8e2a09b 743af329 2bdbd479 1c09a01a 57faf2ef c3e7011e 1ca0af89 c1b77313 dd9b7421 0c7dcc96 db4527cb
```

### 2. 如果你希望把 today helper 一并带到 `main`

Run:

```bash
git cherry-pick f8eb351c 08801ab1
```

### 3. 推分支并发一个只做 workflow registration 的 PR

Run:

```bash
git push origin HEAD:refs/heads/l0-windows-ci-enablement
gh pr create --base main --head l0-windows-ci-enablement --title "ci(l0): register windows native evidence workflow"
```

建议 PR 描述至少写清楚：

- 这次 PR 的目标只是让 `l0-windows-native-evidence.yml` 在 `main` 上可见
- Windows evidence 本身仍要在 PR 合并后，从 Linux x64 侧触发 CI 再采
- 这次 PR 不代表 native parity 已闭环

### 4. PR 合到 `main` 后，从 Linux x64 重新跑 preflight

Run:

```bash
bash tests/preflight_windows_strict_l0_native_evidence_gh.sh
```

通过标准：

- 返回 `rc=0`
- 不再是 `WORKFLOW_NOT_FOUND`

### 5. 从 Linux x64 触发 Windows evidence workflow

Run:

```bash
bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh L0-YYYYMMDD-native
```

如果只想先拿 today source-of-truth 命令，再跑：

```bash
bash tests/print_windows_strict_l0_native_closeout_3cmd.sh L0-YYYYMMDD-native
```

### 6. 下载 artifact 后做 closeout 复核

Run:

```bash
bash tests/test_windows_strict_l0_native_closeout_stack.sh
git diff --check
STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.span fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation fafafa.core.platform
```

## Evidence acceptance

只有同时满足下面几条，Windows native parity 才能记成完成：

- artifact 的 `summary.md` 明确写出 `- Result: PASS`
- `environment.txt` 明确写出 `host_os=Windows_NT`
- `source_revision.txt` 明确写出 `git_commit=` 和 `git_ref_hint=`
- `native_matrix.log` / `evidence.log` 体现 12 个 strict L0 `.bat` 入口的 fresh PASS
- 模块日志没有 `[BUILD] SKIPPED`、`lazbuild not found`、`Test executable not found`

当前实际结果：

- 已满足；见 GitHub Actions run `24224880061`
- `summary.md` 已记录 `Result: PASS`
- `source_revision.txt` 已记录 `git_commit=b8adade028ee2011bb6868dc4b666ec7db71ece1`
- `mem_allocator_foundation.log` 与 `mem_allocator_only.log` 都是 `BUILD/CHECK/TEST/LEAK OK`

## What not to do

- 不要把 workflow 注册 PR 和 strict L0 主线 merge 混成同一件事
- 不要把 SIMD worktree 的工作混入这条 enablement 线
- 不要在 `code=22` 还没消失时假装 GH helper 已经可用
- 不要把“workflow 在 `main` 上可见”误写成“Windows native parity 已完成”

## Fast handoff

如果你只是要把这件事转给下一个同学，直接让他先跑：

```bash
bash tests/print_windows_strict_l0_native_ci_enablement_3cmd.sh
```
